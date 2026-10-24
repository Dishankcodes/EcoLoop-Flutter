import 'package:ecoloop/services/ecoloop_api.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:upi_payment_plugin/model/upi_app_model.dart';
import 'package:upi_payment_plugin/upi_payment_plugin.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../app_theme/user/app_text_styles.dart';
import '../../../widgets/cart_popup_user.dart';
import 'order_success.dart';

/// Screen managing checkout payment method selection, card/UPI input fields, and payment confirmation.

class Payment extends StatefulWidget {
  const Payment({
    super.key,

    required this.totalAmount,

    this.items,

    this.address,

    this.deliveryMethod = 'Standard Delivery',

    this.savings = 0,
    this.couponCode,
    this.clearCartAfterSuccess = false,
    this.existingOrder,
  });

  final double totalAmount;

  final List<Map<String, dynamic>>? items;

  final Map<String, dynamic>? address;

  final String deliveryMethod;

  final double savings;
  final String? couponCode;
  final bool clearCartAfterSuccess;

  /// When set, this screen pays an existing unpaid order instead of creating a new order.
  final Map<String, dynamic>? existingOrder;

  bool get isExistingOrderPayment => existingOrder != null;

  @override
  State<Payment> createState() => _PaymentState();
}

class _PaymentState extends State<Payment> {
  late final Razorpay _razorpay;
  String _selectedMethod = 'cod';
  List<Map<String, dynamic>> _pendingOrders = <Map<String, dynamic>>[];
  List<int> _pendingPaymentIds = <int>[];
  String? _gatewayOrderId;
  bool _gatewayCallbackHandled = false;

  String? _selectedUpiApp;

  String? _selectedBank;

  bool _isProcessing = false;
  String _checkoutRequestId = DateTime.now().microsecondsSinceEpoch.toString();
  bool _razorpayCheckoutLaunched = false;

  final TextEditingController _upiController = TextEditingController();

  final TextEditingController _cardNumberController = TextEditingController();

  final TextEditingController _cardNameController = TextEditingController();

  final TextEditingController _expiryController = TextEditingController();

  final TextEditingController _cvvController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleRazorpaySuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleRazorpayError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _upiController.dispose();

    _cardNumberController.dispose();

    _cardNameController.dispose();

    _expiryController.dispose();

    _cvvController.dispose();

    super.dispose();
  }

  /// Formats price values for quick action button labels.

  String _formatPrice(double value) {
    return '₹${value.round()}';
  }

  /// Formats currency values into Indian numbering system layout with commas.

  String _formatIndianPrice(double value) {
    final number = value.round().toString();

    if (number.length <= 3) {
      return '₹$number';
    }

    final lastThree = number.substring(number.length - 3);

    var remaining = number.substring(0, number.length - 3);

    final parts = <String>[];

    while (remaining.length > 2) {
      parts.insert(0, remaining.substring(remaining.length - 2));

      remaining = remaining.substring(0, remaining.length - 2);
    }

    if (remaining.isNotEmpty) {
      parts.insert(0, remaining);
    }

    return '₹${parts.join(',')},$lastThree';
  }

  /// Extracts image URL from various map key formats in product items.

  String _productImage(Map<String, dynamic> item) {
    final image = item['image'];

    if (image is String && image.trim().isNotEmpty) {
      return image;
    }

    final imageUrl = item['imageUrl'];

    if (imageUrl is String && imageUrl.trim().isNotEmpty) {
      return imageUrl;
    }

    final imageUrls = item['imageUrls'];

    if (imageUrls is List && imageUrls.isNotEmpty) {
      return imageUrls.first.toString();
    }

    final images = item['images'];

    if (images is List && images.isNotEmpty) {
      return images.first.toString();
    }

    return '';
  }

  /// Extracts product title string safely from item map.

  String _productTitle(Map<String, dynamic> item) {
    return (item['title'] ?? item['name'] ?? 'EcoLoop Product').toString();
  }

  /// Extracts product quantity safely as an integer.

  int _productQuantity(Map<String, dynamic> item) {
    final quantity = item['quantity'];

    if (quantity is int) {
      return quantity;
    }

    if (quantity is num) {
      return quantity.toInt();
    }

    return int.tryParse(quantity?.toString() ?? '') ?? 1;
  }

  /// Updates active payment mode selection.
  void _selectMethod(String method) {
    if (method != 'cod' && method != 'razorpay' && method != 'upi') return;
    setState(() {
      _selectedMethod = method;
      _selectedUpiApp = null;
    });
  }

  Map<String, dynamic> _asMap(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  dynamic _responseData(dynamic response) {
    final root = _asMap(response);
    return root['data'] is Map ? root['data'] : root;
  }

  Future<Map<String, dynamic>> _createOrderBatch(
    List<Map<String, dynamic>> normalizedItems,
    String paymentMethod,
  ) async {
    final response = await EcoLoopApi.instance.post('/orders/batch', {
      'items': normalizedItems,
      'shippingAddress': widget.address,
      'paymentMethod': paymentMethod,
      'deliveryMethod': 'standard',
      if (widget.couponCode != null && widget.couponCode!.isNotEmpty)
        'couponCode': widget.couponCode,
      'clearCartAfterSuccess': widget.clearCartAfterSuccess,
      'requestId': '${_checkoutRequestId}_$paymentMethod',
    });
    final root = _asMap(response);
    if (root['success'] == false) {
      throw Exception(
        root['message'] ?? root['error'] ?? 'Order was rejected.',
      );
    }
    final data = _asMap(_responseData(response));
    final rawOrders = data['orders'];
    if (rawOrders is! List || rawOrders.isEmpty) {
      throw Exception('The backend did not confirm the order batch.');
    }
    final orders = rawOrders
        .whereType<Map>()
        .map((order) => Map<String, dynamic>.from(order))
        .toList();
    final requestedQuantity = normalizedItems.fold<int>(
      0,
      (sum, item) => sum + (item['quantity'] as int),
    );
    final returnedQuantity = data['itemCount'] is num
        ? (data['itemCount'] as num).toInt()
        : orders.fold<int>(0, (sum, order) => sum + _productQuantity(order));
    if (returnedQuantity != requestedQuantity) {
      throw Exception(
        'The backend returned an incomplete order confirmation. Check Order History before retrying.',
      );
    }
    data['orders'] = orders;
    return data;
  }

  List<int> _readPaymentIds(dynamic rawPayments) {
    if (rawPayments is! List) return <int>[];
    return rawPayments
        .whereType<Map>()
        .map((payment) {
          final map = Map<String, dynamic>.from(payment);
          return int.tryParse('${map['paymentId'] ?? map['id'] ?? ''}') ?? 0;
        })
        .where((id) => id > 0)
        .toList();
  }

  Future<void> _payNow() async {
    if (_isProcessing) return;

    // Match the Artist-side UPI flow: open the installed UPI app chooser
    // directly, without creating an order or Razorpay payment record.
    if (_selectedMethod == 'upi') {
      await _chooseAndLaunchUpiApp();
      return;
    }

    // Existing orders must never pass through checkout's order-batch creation.
    if (widget.isExistingOrderPayment) {
      await _payExistingOrder();
      return;
    }

    // UPI is processed through Razorpay Checkout so payment can be verified
    // server-side; opening an arbitrary UPI app is not proof of payment.
    final items = widget.items ?? const <Map<String, dynamic>>[];
    if (items.isEmpty) {
      _showMessage('No items to order.');
      return;
    }
    if (widget.address == null || widget.address!.isEmpty) {
      _showMessage('Delivery address is missing. Return to checkout.');
      return;
    }

    final normalizedItems = <Map<String, dynamic>>[];
    for (final item in items) {
      final id = (item['productId'] ?? item['product_id'] ?? item['id'] ?? '')
          .toString();
      final quantity = _productQuantity(item);
      final numericId = int.tryParse(id);
      if (numericId == null || numericId <= 0 || quantity < 1) {
        _showMessage('A cart item has an invalid product ID or quantity.');
        return;
      }
      normalizedItems.add({'productId': numericId, 'quantity': quantity});
    }

    // Paint the loading state before starting network work so the tap feels immediate.
    setState(() => _isProcessing = true);
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    try {
      final isOnlinePayment =
          _selectedMethod == 'razorpay' || _selectedMethod == 'upi';
      final paymentMethod = isOnlinePayment ? 'razorpay' : 'cod';
      final data = await _createOrderBatch(normalizedItems, paymentMethod);
      final orders = (data['orders'] as List).cast<Map<String, dynamic>>();
      final totalRaw = data['totalAmount'];
      final total = totalRaw is num
          ? totalRaw.toDouble()
          : double.tryParse('$totalRaw') ?? widget.totalAmount;
      final orderIds = orders
          .map((order) => '${order['orderId'] ?? ''}')
          .where((id) => id.isNotEmpty && id != 'null')
          .join(', ');
      if (orderIds.isEmpty) {
        throw Exception(
          'The server did not return order IDs. Check Order History before retrying.',
        );
      }

      if (paymentMethod == 'cod') {
        if (widget.clearCartAfterSuccess) {
          CartPopup.clear();
        }
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OrderSuccess(
              orderId: orderIds,
              totalAmount: total,
              itemCount: data['itemCount'] is num
                  ? (data['itemCount'] as num).toInt()
                  : normalizedItems.fold<int>(
                      0,
                      (sum, item) => sum + (item['quantity'] as int),
                    ),
              paymentMethod: 'Cash on Delivery',
              address: widget.address,
              deliveryMethod: widget.deliveryMethod,
            ),
          ),
        );
        return;
      }

      _pendingOrders = orders;
      final paymentIds = _readPaymentIds(data['payments']);
      if (paymentIds.isEmpty) {
        throw Exception('The backend did not return payment IDs for Razorpay.');
      }
      _pendingPaymentIds = paymentIds;
      _gatewayCallbackHandled = false;
      _razorpayCheckoutLaunched = false;

      final gatewayResponse = await EcoLoopApi.instance.post(
        '/payments/razorpay/create-order',
        {'paymentIds': paymentIds},
      );
      final gateway = _asMap(_responseData(gatewayResponse));
      final keyId = '${gateway['keyId'] ?? ''}'.trim();
      _gatewayOrderId = '${gateway['razorpayOrderId'] ?? ''}'.trim();
      final amount = gateway['amount'];
      if (keyId.isEmpty ||
          (_gatewayOrderId ?? '').isEmpty ||
          amount is! num ||
          amount <= 0) {
        throw Exception('Razorpay did not return a valid checkout order.');
      }
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _razorpay.open({
        'key': keyId,
        'order_id': _gatewayOrderId,
        'amount': amount.toInt(),
        'currency': '${gateway['currency'] ?? 'INR'}',
        'name': 'EcoLoop',
        'description': 'EcoLoop marketplace order',
        'theme': {'color': '#2A4D3A'},
        if (_selectedMethod == 'upi') 'method': 'upi',
        'retry': {'enabled': true, 'max_count': 2},
      });
      _razorpayCheckoutLaunched = true;
    } catch (error) {
      if ((_selectedMethod == 'razorpay' || _selectedMethod == 'upi') &&
          _pendingOrders.isNotEmpty &&
          !_razorpayCheckoutLaunched) {
        await _cancelPendingOrders(resetAttempt: true);
      }
      if (mounted) {
        _showMessage(
          'Could not start payment: ${error.toString().replaceFirst('Exception: ', '')}',
        );
      }
    } finally {
      if (mounted && _isProcessing) setState(() => _isProcessing = false);
    }
  }

  Future<void> _payExistingOrder() async {
    final order = widget.existingOrder!;
    final orderId = int.tryParse('${order['orderId'] ?? order['id'] ?? ''}');
    if (orderId == null || orderId <= 0) {
      _showMessage(
        'This order has an invalid ID. Refresh My Orders and try again.',
      );
      return;
    }

    final paymentStatus = '${order['paymentStatus'] ?? ''}'
        .trim()
        .toLowerCase();
    if (const {
      'paid',
      'completed',
      'success',
      'successful',
      'captured',
    }.contains(paymentStatus)) {
      _showMessage(
        'This order is already paid. Refresh My Orders to see the latest status.',
      );
      return;
    }

    if (_selectedMethod == 'cod') {
      _showMessage(
        'This order is already placed. Cash on Delivery will be collected when it arrives; no extra order is needed.',
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      // Reuse an existing unpaid Razorpay payment for this order when possible.
      // The backend also enforces this idempotently for concurrent/repeated taps.
      final dynamic paymentsResponse = await EcoLoopApi.instance.get(
        '/payments',
      );
      final dynamic rawPayments = paymentsResponse is Map
          ? (paymentsResponse['payments'] ??
                paymentsResponse['data'] ??
                paymentsResponse['items'] ??
                paymentsResponse['results'] ??
                const <dynamic>[])
          : paymentsResponse;
      int? paymentId;
      if (rawPayments is List) {
        for (final rawPayment in rawPayments) {
          if (rawPayment is! Map) continue;
          final payment = Map<String, dynamic>.from(rawPayment);
          final paymentOrderId = int.tryParse(
            '${payment['orderId'] ?? payment['order_id'] ?? ''}',
          );
          final status = '${payment['status'] ?? ''}'.trim().toLowerCase();
          final method = '${payment['method'] ?? ''}'.trim().toLowerCase();
          final gateway = '${payment['gateway'] ?? ''}'.trim().toLowerCase();
          if (paymentOrderId == orderId &&
              method == 'razorpay' &&
              (status == 'pending' || status == 'unpaid') &&
              (gateway.isEmpty || gateway.contains('razorpay'))) {
            paymentId = int.tryParse(
              '${payment['paymentId'] ?? payment['id'] ?? ''}',
            );
            if (paymentId != null && paymentId > 0) break;
            paymentId = null;
          }
        }
      }
      if (paymentId == null) {
        final createdResponse = await EcoLoopApi.instance.post(
          '/payments/create',
          {'orderId': orderId, 'method': 'razorpay'},
        );
        final created = _asMap(_responseData(createdResponse));
        paymentId = int.tryParse(
          '${created['paymentId'] ?? created['id'] ?? ''}',
        );
      }
      if (paymentId == null || paymentId <= 0) {
        throw Exception(
          'The server did not return a valid payment record for this order.',
        );
      }
      final reusablePaymentId = paymentId;

      _pendingOrders = <Map<String, dynamic>>[order];
      _pendingPaymentIds = <int>[reusablePaymentId];
      _gatewayCallbackHandled = false;
      _razorpayCheckoutLaunched = false;

      final gatewayResponse = await EcoLoopApi.instance.post(
        '/payments/razorpay/create-order',
        {'paymentIds': _pendingPaymentIds},
      );
      final gateway = _asMap(_responseData(gatewayResponse));
      final keyId = '${gateway['keyId'] ?? ''}'.trim();
      _gatewayOrderId = '${gateway['razorpayOrderId'] ?? ''}'.trim();
      final amount = gateway['amount'];
      if (keyId.isEmpty ||
          (_gatewayOrderId ?? '').isEmpty ||
          amount is! num ||
          amount <= 0) {
        throw Exception('Razorpay did not return a valid checkout order.');
      }

      if (!mounted) return;
      setState(() => _isProcessing = false);
      _razorpay.open({
        'key': keyId,
        'order_id': _gatewayOrderId,
        'amount': amount.toInt(),
        'currency': '${gateway['currency'] ?? 'INR'}',
        'name': 'EcoLoop',
        'description': 'Payment for order #$orderId',
        'theme': {'color': '#2A4D3A'},
        if (_selectedMethod == 'upi') 'method': 'upi',
        'retry': {'enabled': true, 'max_count': 2},
      });
      _razorpayCheckoutLaunched = true;
    } catch (error) {
      if (mounted) {
        _showMessage(
          'Could not start payment: ${error.toString().replaceFirst('Exception: ', '')}',
        );
      }
    } finally {
      if (mounted && _isProcessing) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleRazorpaySuccess(PaymentSuccessResponse response) async {
    if (_gatewayCallbackHandled) return;
    _gatewayCallbackHandled = true;
    final gatewayOrderId = (response.orderId?.trim().isNotEmpty ?? false)
        ? response.orderId!.trim()
        : (_gatewayOrderId ?? '');
    final paymentId = response.paymentId?.trim() ?? '';
    final signature = response.signature?.trim() ?? '';
    if (gatewayOrderId.isEmpty ||
        paymentId.isEmpty ||
        signature.isEmpty ||
        _pendingPaymentIds.isEmpty) {
      if (mounted) {
        _showMessage(
          'Payment response was incomplete. Do not retry immediately; check Order History first.',
        );
      }
      return;
    }
    if (mounted) setState(() => _isProcessing = true);
    try {
      final result = await EcoLoopApi.instance
          .post('/payments/razorpay/verify', {
            'paymentId': _pendingPaymentIds.first,
            'razorpayOrderId': gatewayOrderId,
            'razorpayPaymentId': paymentId,
            'razorpaySignature': signature,
          });
      final verified = _asMap(_responseData(result));
      if (verified['verified'] != true ||
          '${verified['status']}'.toLowerCase() != 'paid') {
        throw Exception(
          'The server has not confirmed this payment yet. Check Order History before retrying.',
        );
      }
      final confirmedIds = verified['orderIds'] is List
          ? (verified['orderIds'] as List).map((id) => '$id').join(', ')
          : _pendingOrders
                .map((order) => '${order['orderId'] ?? ''}')
                .where((id) => id != 'null' && id.isNotEmpty)
                .join(', ');
      final total = _pendingOrders.fold<double>(0, (sum, order) {
        final value = order['totalAmount'];
        return sum +
            (value is num ? value.toDouble() : double.tryParse('$value') ?? 0);
      });
      final count = _pendingOrders.fold<int>(
        0,
        (sum, order) => sum + _productQuantity(order),
      );
      if (widget.clearCartAfterSuccess) {
        CartPopup.clear();
      }
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderSuccess(
            orderId: confirmedIds,
            totalAmount: total > 0 ? total : widget.totalAmount,
            itemCount: count,
            paymentMethod: 'Razorpay',
            address: widget.address,
            deliveryMethod: widget.deliveryMethod,
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        _showMessage(
          'Payment was submitted but verification is not confirmed. Do not pay again yet; check Order History or contact support.',
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleRazorpayError(PaymentFailureResponse response) async {
    if (_gatewayCallbackHandled) return;
    _gatewayCallbackHandled = true;
    if (mounted) setState(() => _isProcessing = true);
    await _cancelPendingOrders(resetAttempt: true);
    if (mounted) {
      _showMessage(
        'Payment was not completed. If an order still appears pending, check Order History before trying again.',
      );
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _cancelPendingOrders({required bool resetAttempt}) async {
    // A retry failure must never cancel the existing order being paid.
    if (widget.isExistingOrderPayment) {
      if (resetAttempt) {
        _pendingOrders = <Map<String, dynamic>>[];
        _pendingPaymentIds = <int>[];
        _gatewayOrderId = null;
        _gatewayCallbackHandled = false;
        _razorpayCheckoutLaunched = false;
        _checkoutRequestId = DateTime.now().microsecondsSinceEpoch.toString();
      }
      return;
    }

    final unresolvedOrders = <Map<String, dynamic>>[];
    final orderIds = _pendingOrders
        .map(
          (order) => int.tryParse('${order['orderId'] ?? order['id'] ?? ''}'),
        )
        .whereType<int>()
        .toSet();

    await Future.wait(
      orderIds.map((id) async {
        try {
          final dynamic response = await EcoLoopApi.instance.post(
            '/orders/$id/cancel',
            <String, dynamic>{},
          );
          final root = _asMap(response);
          final data = _asMap(_responseData(response));
          final successFlag = root.containsKey('success')
              ? root['success']
              : data['success'];
          final status = '${data['status'] ?? root['status'] ?? ''}'
              .trim()
              .toLowerCase()
              .replaceAll('_', ' ');
          final confirmed =
              successFlag != false &&
              (status == 'cancelled' || status == 'canceled');
          if (!confirmed) {
            unresolvedOrders.add(
              _pendingOrders.firstWhere(
                (order) =>
                    int.tryParse('${order['orderId'] ?? order['id'] ?? ''}') ==
                    id,
                orElse: () => <String, dynamic>{'orderId': id},
              ),
            );
          }
        } catch (_) {
          unresolvedOrders.add(
            _pendingOrders.firstWhere(
              (order) =>
                  int.tryParse('${order['orderId'] ?? order['id'] ?? ''}') ==
                  id,
              orElse: () => <String, dynamic>{'orderId': id},
            ),
          );
        }
      }),
    );

    if (resetAttempt) {
      _pendingOrders = unresolvedOrders;
      // Keep unresolved IDs visible to this state; don't claim cancellation worked.
      if (unresolvedOrders.isEmpty) {
        _pendingPaymentIds = <int>[];
        _gatewayOrderId = null;
        _gatewayCallbackHandled = false;
        _razorpayCheckoutLaunched = false;
        _checkoutRequestId = DateTime.now().microsecondsSinceEpoch.toString();
      }
    }
    if (unresolvedOrders.isNotEmpty && mounted) {
      _showMessage(
        'Payment was not completed. We could not confirm cancellation for ${unresolvedOrders.length} order(s). Refresh My Orders before retrying.',
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      _showMessage(
        'External wallet selected: ${response.walletName ?? 'wallet'}. Complete the payment in the opened flow.',
      );
    }
  }

  /// Displays a floating snackbar feedback message.

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),

        behavior: SnackBarBehavior.floating,

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,

        elevation: 0,

        title: Text('Payment', style: AppTextStyles.title),

        centerTitle: false,
      ),

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),

                padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    _buildSecureBanner(),

                    const SizedBox(height: 18),

                    _buildOrderSummary(),

                    const SizedBox(height: 20),

                    Text(
                      'Choose payment method',

                      style: AppTextStyles.title.copyWith(fontSize: 17),
                    ),

                    const SizedBox(height: 10),

                    _buildPaymentMethods(),

                    const SizedBox(height: 20),

                    _buildPaymentDetails(),

                    const SizedBox(height: 20),

                    _buildSecurityCard(),
                  ],
                ),
              ),
            ),

            _buildBottomPaymentBar(),
          ],
        ),
      ),
    );
  }

  /// Security badge banner header.

  Widget _buildSecureBanner() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.light, AppColors.surface]),

        borderRadius: BorderRadius.circular(17),

        border: Border.all(color: AppColors.accent.withValues(alpha: 0.6)),
      ),

      child: Row(
        children: [
          Container(
            width: 44,

            height: 44,

            decoration: const BoxDecoration(
              color: AppColors.surface,

              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.lock_outline_rounded,

              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  'Secure payment',

                  style: TextStyle(
                    color: AppColors.textPrimary,

                    fontSize: 14,

                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  'Your payment information is protected.',

                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),

          const Icon(
            Icons.verified_rounded,

            color: AppColors.success,

            size: 21,
          ),
        ],
      ),
    );
  }

  /// Summary section showing checkout order line items and total amount payable.

  Widget _buildOrderSummary() {
    final items = widget.items ?? [];

    if (items.isEmpty) {
      return _sectionCard(
        child: Row(
          children: [
            _sectionIcon(Icons.shopping_bag_outlined),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                'Your EcoLoop order',

                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,

                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            Text(
              _formatIndianPrice(widget.totalAmount),

              style: AppTextStyles.body.copyWith(
                color: AppColors.primary,

                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    return _sectionCard(
      child: Column(
        children: [
          Row(
            children: [
              _sectionIcon(Icons.shopping_bag_outlined),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  'Order summary',

                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,

                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              Text(
                '${items.length} item${items.length == 1 ? '' : 's'}',

                style: AppTextStyles.caption,
              ),
            ],
          ),

          const SizedBox(height: 14),

          ...items.take(3).map((item) => _buildMiniProduct(item)),

          if (items.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 7),

              child: Align(
                alignment: Alignment.centerLeft,

                child: Text(
                  '+ ${items.length - 3} more item${items.length - 3 == 1 ? '' : 's'}',

                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,

                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 12),

          const Divider(height: 1),

          const SizedBox(height: 12),

          Row(
            children: [
              Text(
                'Total payable',

                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w700,

                  color: AppColors.textPrimary,
                ),
              ),

              const Spacer(),

              Text(
                _formatIndianPrice(widget.totalAmount),

                style: AppTextStyles.title.copyWith(fontSize: 17),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Helper widget rendering individual product item row inside summary card.

  Widget _buildMiniProduct(Map<String, dynamic> item) {
    final image = _productImage(item);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),

      child: Row(
        children: [
          Container(
            width: 48,

            height: 48,

            decoration: BoxDecoration(
              color: AppColors.light,

              borderRadius: BorderRadius.circular(11),
            ),

            clipBehavior: Clip.antiAlias,

            child: image.isNotEmpty
                ? Image.network(
                    image,

                    fit: BoxFit.cover,

                    errorBuilder: (_, _, _) {
                      return const Icon(
                        Icons.eco_outlined,

                        color: AppColors.primary,
                      );
                    },
                  )
                : const Icon(Icons.eco_outlined, color: AppColors.primary),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  _productTitle(item),

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontSize: 13,

                    fontWeight: FontWeight.w600,

                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  'Qty: ${_productQuantity(item)}',

                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),

          Text(
            _formatIndianPrice(
              _toDouble(item['price']) * _productQuantity(item),
            ),

            style: const TextStyle(
              fontSize: 13,

              fontWeight: FontWeight.w700,

              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// List options for supported payment modes.

  Widget _buildPaymentMethods() {
    return Column(
      children: [
        _paymentMethodTile(
          value: 'upi',
          icon: Icons.qr_code_2_rounded,
          title: 'UPI',
          subtitle: 'Google Pay, PhonePe, Paytm and other UPI apps',
        ),
        const SizedBox(height: 9),
        _paymentMethodTile(
          value: 'razorpay',
          icon: Icons.account_balance_wallet_outlined,
          title: 'Cards, Netbanking & Wallets',
          subtitle: 'Secure online payment with Razorpay',
        ),
        const SizedBox(height: 9),
        _paymentMethodTile(
          value: 'cod',
          icon: Icons.local_shipping_outlined,
          title: 'Cash on Delivery',
          subtitle: 'Pay when your order arrives',
        ),
      ],
    );
  }

  /// Selectable tile option for payment methods list.

  Widget _paymentMethodTile({
    required String value,

    required IconData icon,

    required String title,

    required String subtitle,
  }) {
    final selected = _selectedMethod == value;

    return InkWell(
      onTap: () => _selectMethod(value),

      borderRadius: BorderRadius.circular(17),

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),

        padding: const EdgeInsets.all(15),

        decoration: BoxDecoration(
          color: selected ? AppColors.light : AppColors.surface,

          borderRadius: BorderRadius.circular(17),

          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey.shade200,

            width: selected ? 1.4 : 1,
          ),
        ),

        child: Row(
          children: [
            Container(
              width: 43,

              height: 43,

              decoration: BoxDecoration(
                color: selected ? AppColors.surface : AppColors.background,

                borderRadius: BorderRadius.circular(12),
              ),

              child: Icon(icon, color: AppColors.primary, size: 21),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    title,

                    style: const TextStyle(
                      fontSize: 14,

                      fontWeight: FontWeight.w700,

                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),

            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,

              color: selected ? AppColors.primary : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  /// Returns active input fields matching selected payment mode.

  Widget _buildPaymentDetails() {
    switch (_selectedMethod) {
      case 'upi':
        return _sectionCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.qr_code_2_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Choose your UPI app to open it with the payment details. This test-mode UPI flow does not confirm or record an EcoLoop payment.',
                  style: AppTextStyles.body,
                ),
              ),
            ],
          ),
        );

      case 'card':
        return _buildCardSection();

      case 'netbanking':
        return _buildNetBankingSection();

      case 'wallet':
        return _buildWalletSection();

      case 'razorpay':
        return _sectionCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'You will securely choose UPI, card, net banking or an available wallet in Razorpay Checkout. EcoLoop confirms your order only after server-side payment verification.',
                  style: AppTextStyles.body,
                ),
              ),
            ],
          ),
        );

      case 'cod':
        return _buildCodSection();

      default:
        return const SizedBox.shrink();
    }
  }

  /// Shows the installed UPI apps and launches the selected app, matching
  /// the Artist-side checkout behaviour. This is app-launch/test mode only.
  Future<void> _chooseAndLaunchUpiApp() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    try {
      final apps = await UpiPaymentPlugin().getUpiApps();
      if (!mounted) return;

      if (apps.isEmpty) {
        _showMessage('No supported UPI apps were found on this device.');
        return;
      }

      final selectedApp = await showModalBottomSheet<UpiAppModel>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Choose a UPI app',
                  style: AppTextStyles.title.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 5),
                Text(
                  'Select the app you want to open.',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 12),
                ...apps.map(
                  (app) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.light,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(
                      app.appName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(sheetContext).pop(app),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      if (selectedApp == null || !mounted) return;

      // Keep the same test UPI details as the Artist-side flow.
      // Replace this VPA with EcoLoop's verified merchant UPI ID before launch.
      await UpiPaymentPlugin.initiateUPIPayment(
        payeeUpiId: 'dishankprajapati@ptyes',
        payeeName: 'EcoLoop',
        amount: widget.totalAmount,
        transactionId: 'ECO${DateTime.now().millisecondsSinceEpoch}',
        transactionNote: 'EcoLoop order payment test',
        merchantCode: '0000',
        link: '',
        transactionRefId: 'ELREF${DateTime.now().millisecondsSinceEpoch}',
        packageName: selectedApp.packageName,
        secretKey: '',
      );

      if (mounted) {
        _showMessage(
          'UPI app opened in test mode. This does not confirm or record an EcoLoop payment.',
        );
      }
    } catch (error) {
      if (mounted) {
        _showMessage(
          'Could not open the UPI app: ${error.toString().replaceFirst('Exception: ', '')}',
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// Card credentials form section.

  Widget _buildCardSection() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            'Enter card details',

            style: AppTextStyles.body.copyWith(
              color: AppColors.textPrimary,

              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 13),

          TextField(
            controller: _cardNumberController,

            keyboardType: TextInputType.number,

            maxLength: 19,

            decoration: const InputDecoration(
              labelText: 'Card Number',

              hintText: '1234 5678 9012 3456',

              prefixIcon: Icon(Icons.credit_card_outlined),

              counterText: '',
            ),
          ),

          const SizedBox(height: 10),

          TextField(
            controller: _cardNameController,

            textCapitalization: TextCapitalization.words,

            decoration: const InputDecoration(
              labelText: 'Name on Card',

              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _expiryController,

                  keyboardType: TextInputType.number,

                  maxLength: 5,

                  decoration: const InputDecoration(
                    labelText: 'Expiry',

                    hintText: 'MM/YY',

                    counterText: '',
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: TextField(
                  controller: _cvvController,

                  keyboardType: TextInputType.number,

                  obscureText: true,

                  maxLength: 3,

                  decoration: const InputDecoration(
                    labelText: 'CVV',

                    hintText: '•••',

                    counterText: '',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              const Icon(
                Icons.lock_outline_rounded,

                size: 16,

                color: AppColors.success,
              ),

              const SizedBox(width: 6),

              Text(
                'Your card details are encrypted',

                style: AppTextStyles.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Netbanking bank selection grid.

  Widget _buildNetBankingSection() {
    final banks = [
      'HDFC Bank',

      'State Bank of India',

      'ICICI Bank',

      'Axis Bank',

      'Kotak Mahindra Bank',

      'Other Bank',
    ];

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            'Select your bank',

            style: AppTextStyles.body.copyWith(
              color: AppColors.textPrimary,

              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 9,

            runSpacing: 9,

            children: banks.map((bank) {
              final selected = _selectedBank == bank;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedBank = bank;
                  });
                },

                borderRadius: BorderRadius.circular(12),

                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,

                    vertical: 11,
                  ),

                  decoration: BoxDecoration(
                    color: selected ? AppColors.light : AppColors.background,

                    borderRadius: BorderRadius.circular(12),

                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : Colors.grey.shade200,
                    ),
                  ),

                  child: Text(
                    bank,

                    style: TextStyle(
                      fontSize: 11,

                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,

                      color: selected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Digital wallet provider list.

  Widget _buildWalletSection() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            'Choose wallet',

            style: AppTextStyles.body.copyWith(
              color: AppColors.textPrimary,

              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 12),

          _walletOption('Paytm Wallet', Icons.account_balance_wallet_outlined),

          const SizedBox(height: 9),

          _walletOption('Amazon Pay', Icons.shopping_bag_outlined),

          const SizedBox(height: 9),

          _walletOption('Other Wallet', Icons.wallet_outlined),
        ],
      ),
    );
  }

  /// Option item for wallet provider list.

  Widget _walletOption(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: AppColors.background,

        borderRadius: BorderRadius.circular(13),

        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Row(
        children: [
          Container(
            width: 38,

            height: 38,

            decoration: BoxDecoration(
              color: AppColors.light,

              borderRadius: BorderRadius.circular(10),
            ),

            child: Icon(icon, color: AppColors.primary, size: 19),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Text(
              title,

              style: const TextStyle(
                fontSize: 13,

                fontWeight: FontWeight.w600,

                color: AppColors.textPrimary,
              ),
            ),
          ),

          const Icon(
            Icons.chevron_right_rounded,

            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  /// Information card for Cash on Delivery option.

  Widget _buildCodSection() {
    return _sectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Container(
            width: 45,

            height: 45,

            decoration: BoxDecoration(
              color: AppColors.light,

              borderRadius: BorderRadius.circular(13),
            ),

            child: const Icon(
              Icons.local_shipping_outlined,

              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  'Cash on Delivery',

                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,

                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Pay using cash when your EcoLoop order is delivered.',

                  style: AppTextStyles.caption.copyWith(height: 1.45),
                ),

                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,

                    vertical: 7,
                  ),

                  decoration: BoxDecoration(
                    color: AppColors.light,

                    borderRadius: BorderRadius.circular(9),
                  ),

                  child: const Text(
                    'No online payment required',

                    style: TextStyle(
                      fontSize: 10,

                      fontWeight: FontWeight.w600,

                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Card highlighting transaction security features and guarantees.

  Widget _buildSecurityCard() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: AppColors.surface,

        borderRadius: BorderRadius.circular(17),

        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_user_outlined,

                color: AppColors.primary,

                size: 22,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  'Safe & secure checkout',

                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,

                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _securityPoint(
            Icons.lock_outline_rounded,

            'Secure payment processing',
          ),

          _securityPoint(
            Icons.privacy_tip_outlined,

            'Your payment details stay protected',
          ),

          _securityPoint(
            Icons.support_agent_outlined,

            'EcoLoop support available for orders',
          ),
        ],
      ),
    );
  }

  /// Helper row widget for safety points inside the security card.

  Widget _securityPoint(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),

      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.secondary),

          const SizedBox(width: 8),

          Expanded(child: Text(text, style: AppTextStyles.caption)),
        ],
      ),
    );
  }

  /// Fixed bottom navigation bar with live total payable amount and action trigger.

  Widget _buildBottomPaymentBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),

      decoration: BoxDecoration(
        color: AppColors.surface,

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),

            blurRadius: 15,

            offset: const Offset(0, -4),
          ),
        ],
      ),

      child: SafeArea(
        top: false,

        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              mainAxisSize: MainAxisSize.min,

              children: [
                Text(
                  'TOTAL',

                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,

                    letterSpacing: 0.6,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  _formatIndianPrice(widget.totalAmount),

                  style: AppTextStyles.title.copyWith(fontSize: 19),
                ),
              ],
            ),

            const SizedBox(width: 16),

            Expanded(
              child: SizedBox(
                height: 52,

                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _payNow,

                  child: _isProcessing
                      ? const SizedBox(
                          width: 22,

                          height: 22,

                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,

                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,

                          children: [
                            Text(
                              _selectedMethod == 'cod'
                                  ? 'Place Order'
                                  : _selectedMethod == 'upi'
                                  ? 'Choose UPI App'
                                  : 'Pay ${_formatPrice(widget.totalAmount)}',
                            ),

                            const SizedBox(width: 5),

                            const Icon(Icons.arrow_forward_rounded, size: 19),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Container box wrapper used for primary screen section cards.

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: AppColors.surface,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: Colors.grey.shade200),
      ),

      child: child,
    );
  }

  /// Leading icon box for summary headers.

  Widget _sectionIcon(IconData icon) {
    return Container(
      width: 40,

      height: 40,

      decoration: BoxDecoration(
        color: AppColors.light,

        borderRadius: BorderRadius.circular(12),
      ),

      child: Icon(icon, size: 20, color: AppColors.primary),
    );
  }

  /// Utility function safely parsing dynamic price values to double.

  double _toDouble(dynamic value) {
    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value.replaceAll(',', '')) ?? 0;
    }

    return 0;
  }
}
