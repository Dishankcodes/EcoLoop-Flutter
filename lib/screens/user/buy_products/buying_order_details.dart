import 'package:ecoloop/services/ecoloop_api.dart';
import 'package:flutter/material.dart';

import '../../../app_theme/user/app_colors.dart';
import '../reviews/write_review.dart';
import '../reviews/write_seller_review.dart';
import 'order_tracking.dart';

/// Screen displaying comprehensive details and status tracking for a purchased order.
class BuyingOrderDetails extends StatefulWidget {
  final Map<String, dynamic> order;

  const BuyingOrderDetails({super.key, required this.order});

  @override
  State<BuyingOrderDetails> createState() => _BuyingOrderDetailsState();
}

class _BuyingOrderDetailsState extends State<BuyingOrderDetails> {
  late String _status;
  bool _productReviewSubmitted = false;
  bool _sellerReviewSubmitted = false;
  bool _checkingReviewStatus = true;
  bool _cancellingOrder = false;
  bool _refundExpected = false;

  @override
  void initState() {
    super.initState();
    _status = widget.order['status']?.toString() ?? 'Status unavailable';
    _refundExpected = _isPaidPaymentStatus(
      widget.order['paymentStatus'] ?? widget.order['payment'],
    );
    _loadExistingReviewStatus();
  }

  String get productName =>
      (widget.order['productName'] ??
              widget.order['productTitle'] ??
              widget.order['product'] ??
              widget.order['title'] ??
              'Product details unavailable')
          .toString();

  String get price {
    final value =
        widget.order['price'] ??
        widget.order['unitPrice'] ??
        widget.order['totalAmount'];
    if (value == null) return 'Price unavailable';
    if (value.toString().trim().startsWith('₹')) return value.toString();
    final amount = value is num ? value : num.tryParse('$value');
    return amount == null ? 'Price unavailable' : '₹${amount.round()}';
  }

  String get orderId {
    final value =
        widget.order['displayOrderId'] ??
        widget.order['orderId'] ??
        widget.order['id'];
    return value == null ? 'Order ID unavailable' : value.toString();
  }

  String get orderDate {
    final value =
        widget.order['createdAt'] ??
        widget.order['created_at'] ??
        widget.order['date'];
    if (value == null || value.toString().trim().isEmpty)
      return 'Date unavailable';
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();
    final date = parsed.toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  String get sellerName =>
      (widget.order['sellerName'] ??
              widget.order['seller'] ??
              'Seller details unavailable')
          .toString();

  String get quantity =>
      widget.order['quantity']?.toString() ?? 'Quantity unavailable';

  String get payment =>
      widget.order['payment']?.toString() ??
      widget.order['paymentStatus']?.toString() ??
      'Payment status unavailable';

  bool get isPaymentPending {
    final value = (widget.order['paymentStatus'] ?? widget.order['payment'])
        ?.toString()
        .trim()
        .toLowerCase()
        .replaceAll('_', ' ');
    return value == 'pending' ||
        value == 'unpaid' ||
        value == 'failed' ||
        value == 'payment pending';
  }

  String get deliveryMethod =>
      widget.order['deliveryMethod']?.toString() ?? 'EcoLoop Delivery';

  String get expectedDate {
    final value =
        widget.order['expectedDelivery'] ?? widget.order['expected_delivery'];
    return value == null || value.toString().trim().isEmpty
        ? 'Not available'
        : value.toString();
  }

  IconData get productIcon {
    // Orders arrive from the API as JSON, so `icon` may be a String.
    // Never cast an API value directly to IconData.
    final dynamic value = widget.order['icon'];
    if (value is IconData) return value;

    // Keep a stable fallback for API-backed orders that have no local icon.
    switch (value?.toString().trim().toLowerCase()) {
      case 'chair':
      case 'chair_outlined':
        return Icons.chair_outlined;
      case 'book':
      case 'menu_book':
        return Icons.menu_book_outlined;
      case 'clothing':
      case 'checkroom':
        return Icons.checkroom_outlined;
      case 'electronics':
      case 'devices':
        return Icons.devices_outlined;
      default:
        return Icons.inventory_2_outlined;
    }
  }

  bool get isCancelled => _normalizedOrderStatus == 'cancelled';

  bool get isDelivered => _normalizedOrderStatus == 'delivered';

  /// Cancellation is allowed only through Packed. The backend validates this too.
  bool get _canCancelOrder =>
      const {'pending', 'confirmed', 'packed'}.contains(_normalizedOrderStatus);

  bool _isPaidPaymentStatus(dynamic raw) {
    final value = (raw ?? '')
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ');
    return const {
      'paid',
      'completed',
      'success',
      'successful',
      'captured',
      'cod paid',
      'refund required',
      'refunded',
    }.contains(value);
  }

  String get _normalizedOrderStatus =>
      _status.trim().toLowerCase().replaceAll('_', ' ');

  bool get _paymentPaid {
    final value =
        (widget.order['paymentStatus'] ?? widget.order['payment'] ?? '')
            .toString()
            .trim()
            .toLowerCase()
            .replaceAll('_', ' ');
    return const {
      'paid',
      'completed',
      'success',
      'successful',
      'captured',
      'cod paid',
    }.contains(value);
  }

  bool get _canReview => _normalizedOrderStatus == 'delivered' && _paymentPaid;

  int _safeId(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;

  int _reviewId(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('${value ?? ''}') ?? 0;

  String _reviewText(dynamic value) =>
      (value ?? '').toString().trim().toLowerCase().replaceAll('_', ' ');

  Future<bool> _loadExistingReviewStatus({bool showError = false}) async {
    if (mounted) setState(() => _checkingReviewStatus = true);
    try {
      final dynamic response = await EcoLoopApi.instance.get('/my/reviews');
      dynamic rows = response;
      if (response is Map) {
        rows =
            response['reviews'] ??
            response['data'] ??
            response['items'] ??
            response['results'] ??
            response['result'] ??
            const <dynamic>[];
      }
      final reviews = rows is List ? rows : const <dynamic>[];
      final productId = _safeId(widget.order['productId']);
      final sellerId = _safeId(widget.order['sellerId']);
      final sellerType = _reviewText(widget.order['sellerType'] ?? 'user');
      var productReviewed = false;
      var sellerReviewed = false;

      for (final item in reviews) {
        if (item is! Map) continue;
        final review = Map<String, dynamic>.from(item);
        final status = _reviewText(review['status']);
        if (status.isNotEmpty && status != 'active') continue;
        final type = _reviewText(review['reviewType'] ?? review['type']);
        final reviewedProductId = _reviewId(review['productId']);
        final reviewedArtistId = _reviewId(review['artistId']);
        final reviewedSellerId = _reviewId(review['sellerId']);
        final reviewedSellerType = _reviewText(review['sellerType']);

        if (productId > 0 &&
            reviewedProductId == productId &&
            (type == 'product' || type.isEmpty)) {
          productReviewed = true;
        }

        if (sellerId <= 0 || reviewedProductId > 0) continue;
        if (sellerType == 'artist' || sellerType == 'remaker') {
          if (reviewedArtistId == sellerId ||
              (reviewedSellerId == sellerId &&
                  reviewedSellerType == 'artist') ||
              (reviewedSellerId == sellerId &&
                  type == 'seller' &&
                  reviewedSellerType.isEmpty)) {
            sellerReviewed = true;
          }
        } else if (reviewedSellerId == sellerId &&
            (reviewedSellerType.isEmpty || reviewedSellerType == 'user') &&
            (type == 'seller' || type.isEmpty)) {
          sellerReviewed = true;
        }
      }

      if (!mounted) return true;
      setState(() {
        _productReviewSubmitted = productReviewed;
        _sellerReviewSubmitted = sellerReviewed;
        _checkingReviewStatus = false;
      });
      return true;
    } catch (_) {
      if (!mounted) return false;
      setState(() => _checkingReviewStatus = false);
      if (showError) {
        _showMessage(
          'Could not verify your review status. Please check your connection and try again.',
        );
      }
      return false;
    }
  }

  Widget _buildReviewActions() {
    final productId = _safeId(widget.order['productId']);
    final sellerId = _safeId(widget.order['sellerId']);
    final sellerType = (widget.order['sellerType'] ?? 'user')
        .toString()
        .toLowerCase();
    final orderNumericId = _safeId(widget.order['orderId']);
    return _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Share Your Experience', Icons.rate_review_outlined),
          const SizedBox(height: 6),
          const Text(
            'Your payment is marked as paid. Tell others about the product and your seller.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed:
                  !_checkingReviewStatus &&
                      productId > 0 &&
                      orderNumericId > 0 &&
                      !_productReviewSubmitted
                  ? () => _writeReview(
                      title: 'Review product',
                      endpoint: '/reviews/product',
                      payloadIds: {
                        'productId': productId,
                        'orderId': orderNumericId,
                      },
                    )
                  : null,
              icon: const Icon(Icons.inventory_2_outlined),
              label: Text(
                _checkingReviewStatus
                    ? 'Checking review status…'
                    : _productReviewSubmitted
                    ? 'Product Reviewed'
                    : 'Write Product Review',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                minimumSize: const Size.fromHeight(46),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  !_checkingReviewStatus &&
                      sellerId > 0 &&
                      orderNumericId > 0 &&
                      !_sellerReviewSubmitted
                  ? () => _writeReview(
                      title: sellerType == 'artist' || sellerType == 'remaker'
                          ? 'Review ReMaker'
                          : 'Review seller',
                      endpoint:
                          sellerType == 'artist' || sellerType == 'remaker'
                          ? '/reviews/artist'
                          : '/reviews/seller',
                      payloadIds:
                          sellerType == 'artist' || sellerType == 'remaker'
                          ? {'artistId': sellerId, 'orderId': orderNumericId}
                          : {
                              'sellerId': sellerId,
                              'sellerType': 'user',
                              'orderId': orderNumericId,
                            },
                    )
                  : null,
              icon: const Icon(Icons.storefront_outlined),
              label: Text(
                _checkingReviewStatus
                    ? 'Checking review status…'
                    : _sellerReviewSubmitted
                    ? (sellerType == 'artist' || sellerType == 'remaker'
                          ? 'Artist Reviewed'
                          : 'Seller Reviewed')
                    : (sellerType == 'artist' || sellerType == 'remaker'
                          ? 'Write Artist Review'
                          : 'Write Seller Review'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(46),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _writeReview({
    required String title,
    required String endpoint,
    required Map<String, dynamic> payloadIds,
  }) async {
    final verified = await _loadExistingReviewStatus(showError: true);
    if (!verified || !mounted) return;

    if (endpoint == '/reviews/product' && _productReviewSubmitted) {
      _showMessage('You have already reviewed this product.');
      return;
    }
    if ((endpoint == '/reviews/artist' || endpoint == '/reviews/seller') &&
        _sellerReviewSubmitted) {
      _showMessage('You have already reviewed this seller/artist.');
      return;
    }

    final productId = _safeId(widget.order['productId']);
    final orderNumericId = _safeId(widget.order['orderId']);
    if (orderNumericId <= 0) {
      _showMessage('Order information is missing. Please reopen this order.');
      return;
    }

    if (endpoint == '/reviews/product') {
      if (productId <= 0) {
        _showMessage('Product information is missing for this order.');
        return;
      }
      final product = <String, dynamic>{
        ...widget.order,
        'productId': productId,
        'id': productId,
        'title': productName,
        'name': productName,
        'imageUrls':
            widget.order['imageUrls'] ?? widget.order['productImageUrls'],
        'imageUrl': widget.order['productImageUrl'] ?? widget.order['imageUrl'],
      };
      final submitted = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              WriteReview(product: product, orderId: orderNumericId.toString()),
        ),
      );
      if (submitted == true && mounted) {
        setState(() => _productReviewSubmitted = true);
        await _loadExistingReviewStatus();
        _showMessage('Product review submitted successfully.');
      }
      return;
    }

    final sellerId = _safeId(widget.order['sellerId']);
    if (sellerId <= 0) {
      _showMessage('Seller information is missing for this order.');
      return;
    }

    final sellerType = (widget.order['sellerType'] ?? 'user')
        .toString()
        .trim()
        .toLowerCase();
    final submitted = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (_) => WriteSellerReview(
          sellerName: sellerName,
          sellerImage:
              (widget.order['sellerImage'] ??
                      widget.order['sellerPhotoUrl'] ??
                      widget.order['profilePhotoUrl'])
                  ?.toString(),
          sellerId: sellerId.toString(),
          sellerType: sellerType,
          orderId: orderNumericId.toString(),
        ),
      ),
    );
    if (submitted != null && mounted) {
      setState(() => _sellerReviewSubmitted = true);
      await _loadExistingReviewStatus();
      _showMessage('Seller/artist review submitted successfully.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: isCancelled ? 30 : 100),
        child: Column(
          children: [
            _buildOrderHeader(),
            if (isCancelled) _buildCancelledBanner(),
            if (!isCancelled) _buildStatusSection(),
            _buildProductSection(),
            _buildSellerSection(),
            if (_canReview) _buildReviewActions(),
            _buildDeliverySection(),
            _buildPaymentSection(),
            if (isPaymentPending) _buildPendingPaymentCard(),
            _buildOrderInformation(),
            _buildEcoLoopProtection(),
            if (isDelivered) _buildDeliveredMessage(),
            _buildHelpSection(),
          ],
        ),
      ),
      bottomNavigationBar: isCancelled ? null : _buildBottomBar(),
    );
  }

  /// AppBar with title and overflow options menu.
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      title: const Text(
        'Order Details',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: _showMoreOptions,
          icon: const Icon(Icons.more_vert_rounded),
        ),
      ],
    );
  }

  /// Top summary card displaying order placement date and order ID.
  Widget _buildOrderHeader() {
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order placed',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  orderDate,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Order ID',
                style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                orderId,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Banner shown after cancellation, including refund guidance when applicable.
  Widget _buildCancelledBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.07),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.error.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.cancel_outlined, color: AppColors.error, size: 23),
              SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Cancelled by You',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'You cancelled this order. It is no longer active.',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_refundExpected) ...[
            const SizedBox(height: 13),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Your payment refund should arrive within 5–7 days. If you have not received it after 7 days, contact EcoLoop about the payment issue.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _contactEcoLoop,
                icon: const Icon(Icons.support_agent_rounded),
                label: const Text('Contact EcoLoop'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  minimumSize: const Size.fromHeight(44),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Step-by-step order progress timeline.
  Widget _buildStatusSection() {
    return _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Order Status',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _statusChip(),
            ],
          ),
          const SizedBox(height: 23),
          _timelineItem(
            icon: Icons.check_circle_rounded,
            title: 'Order Confirmed',
            subtitle: 'Your order has been confirmed',
            completed: _isStepCompleted(1),
            active: _status == 'Confirmed',
          ),
          _timelineItem(
            icon: Icons.inventory_2_rounded,
            title: 'Item Packed',
            subtitle: 'Seller has packed your item',
            completed: _isStepCompleted(2),
            active: _status == 'Packed',
          ),
          _timelineItem(
            icon: Icons.local_shipping_rounded,
            title: 'Shipped',
            subtitle: 'Your item is on the way',
            completed: _isStepCompleted(3),
            active: _status == 'Shipped',
          ),
          _timelineItem(
            icon: Icons.home_rounded,
            title: 'Delivered',
            subtitle: 'Item delivered successfully',
            completed: _isStepCompleted(4),
            active: _status == 'Delivered',
            isLast: true,
          ),
          const SizedBox(height: 5),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.light.withOpacity(0.65),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.local_shipping_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Detailed delivery tracking will be available here.',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.4,
                      color: AppColors.textSecondary,
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

  /// Helper to determine whether a given timeline step index is completed.
  bool _isStepCompleted(int step) {
    switch (_status) {
      case 'Confirmed':
        return step <= 1;
      case 'Packed':
        return step <= 2;
      case 'Shipped':
        return step <= 3;
      case 'Delivered':
        return true;
      default:
        return false;
    }
  }

  /// Individual item rendered in the order status timeline.
  Widget _timelineItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool completed,
    required bool active,
    bool isLast = false,
  }) {
    final color = completed
        ? AppColors.success
        : active
        ? AppColors.primary
        : AppColors.accent;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 32,
          child: Column(
            children: [
              Container(
                height: 30,
                width: 30,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 17, color: color),
              ),
              if (!isLast)
                Container(
                  height: 37,
                  width: 2,
                  color: completed
                      ? AppColors.success.withOpacity(0.38)
                      : AppColors.accent.withOpacity(0.55),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: active || completed
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: active || completed
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Status pill badge indicating current order state.
  Widget _statusChip() {
    Color color;

    switch (_status) {
      case 'Delivered':
        color = AppColors.success;
        break;
      case 'Shipped':
        color = AppColors.primary;
        break;
      case 'Packed':
        color = Colors.orange;
        break;
      default:
        color = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  /// Product summary card containing image/icon, name, quantity, and price.
  Widget _buildProductSection() {
    return _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Item Details', Icons.shopping_bag_outlined),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accent.withOpacity(0.35)),
            ),
            child: Row(
              children: [
                Container(
                  height: 78,
                  width: 78,
                  decoration: BoxDecoration(
                    color: AppColors.light,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(productIcon, size: 38, color: AppColors.primary),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        'Quantity: $quantity',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        price,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Seller profile information and contact trigger.
  Widget _buildSellerSection() {
    return _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Seller', Icons.person_outline_rounded),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: const BoxDecoration(
                  color: AppColors.light,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.primary,
                  size: 27,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sellerName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: Colors.orange,
                        ),
                        SizedBox(width: 3),
                        Text(
                          '4.8  •  Verified Seller',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () {
                  _showMessage('Seller contact will be connected later.');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: const Text(
                  'Contact',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Shipping address and delivery timeline information.
  Widget _buildDeliverySection() {
    return _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Delivery Details', Icons.local_shipping_outlined),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.light.withOpacity(0.60),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Deliver to',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Dishank Prajapati',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '28/4 Jagdish Apartment, Viratnagar Canal Road',
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.4,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          _detailRow(Icons.local_shipping_outlined, 'Delivery', deliveryMethod),
          const SizedBox(height: 12),
          _detailRow(
            Icons.event_outlined,
            'Expected',
            isDelivered ? 'Delivered successfully' : expectedDate,
          ),
        ],
      ),
    );
  }

  /// Payment breakdown including item cost, charges, and payment mode.
  Widget _buildPaymentSection() {
    return _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Payment Summary', Icons.receipt_long_outlined),
          const SizedBox(height: 18),
          _billRow('Item total', price),
          _billRow('EcoLoop handling charge', '₹20'),
          _billRow('Delivery charges', 'FREE'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 5),
            child: Divider(),
          ),
          _billRow('Total Paid', price, bold: true),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(
                Icons.verified_outlined,
                size: 15,
                color: AppColors.success,
              ),
              const SizedBox(width: 5),
              Text(
                payment,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Helper widget for displaying individual line items in payment summary.
  Widget _billRow(String title, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 16 : 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: bold ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// Key metadata table covering IDs, dates, and current order state.
  Widget _buildOrderInformation() {
    return _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Order Information', Icons.info_outline_rounded),
          const SizedBox(height: 18),
          _informationRow('Order ID', orderId),
          _informationRow('Order placed', orderDate),
          _informationRow('Payment', payment),
          _informationRow('Status', _status, isLast: true),
        ],
      ),
    );
  }

  /// Helper widget for rendering a metadata field in order information.
  Widget _informationRow(String title, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Card highlighting EcoLoop purchase protection policy.
  Widget _buildEcoLoopProtection() {
    return _section(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.light,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accent.withOpacity(0.45)),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.eco_rounded, color: AppColors.primary, size: 24),
            SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EcoLoop Purchase Protection',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Your purchase is protected through the EcoLoop order process.',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.45,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Confirmation banner shown when the item status is Delivered.
  Widget _buildDeliveredMessage() {
    return _section(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.light,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 23,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Your order was delivered successfully. We hope you enjoy your item! 🌱',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Customer support tile for order-related queries.
  Widget _buildHelpSection() {
    return _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Need Help?', Icons.support_agent_outlined),
          const SizedBox(height: 13),
          InkWell(
            onTap: () {
              _contactEcoLoop();
            },
            borderRadius: BorderRadius.circular(15),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.light,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Row(
                children: [
                  Icon(Icons.support_agent_rounded, color: AppColors.primary),
                  SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contact EcoLoop Support',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Get help with your order',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingPaymentCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD580)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Color(0xFF946200)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Payment is pending',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF795500),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          const Text(
            'This order has not been marked as paid. Complete payment only after a payment gateway is connected.',
            style: TextStyle(height: 1.4, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showPaymentNotReady,
              icon: const Icon(Icons.payment_rounded),
              label: const Text('Complete Payment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentNotReady() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Online payment is not connected'),
        content: const Text(
          'Your order is pending payment, but the current backend has no order-specific payment initiation or payment verification endpoint. The existing payment page places a new Cash on Delivery order, so opening it here could create a duplicate order. No payment has been taken and this order will remain pending until a real gateway flow is integrated.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  /// Bottom action bar: cancellation is available only until Packed.
  Widget _buildBottomBar() {
    final bool showCancel = _canCancelOrder && !isCancelled;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (showCancel) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _cancellingOrder ? null : _cancelOrder,
                  icon: _cancellingOrder
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cancel_outlined, size: 17),
                  label: Text(
                    _cancellingOrder ? 'Cancelling…' : 'Cancel Order',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ] else if (isDelivered) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _buyAgain,
                  icon: const Icon(Icons.refresh_rounded, size: 17),
                  label: const Text('Buy Again'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _trackOrder,
                icon: const Icon(Icons.local_shipping_outlined, size: 17),
                label: const Text('Track Order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Navigates to the live order tracking view.
  void _trackOrder() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OrderTracking(order: widget.order)),
    );
  }

  /// Confirms with the buyer, then cancels the order through the authenticated API.
  Future<void> _cancelOrder() async {
    if (!_canCancelOrder || isCancelled || _cancellingOrder) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Cancel Order?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          _isPaidPaymentStatus(
                widget.order['paymentStatus'] ?? widget.order['payment'],
              )
              ? 'Are you sure you want to cancel this order? Your payment refund should arrive within 5–7 days. If it has not arrived after 7 days, contact EcoLoop.'
              : 'Are you sure you want to cancel this order? This action cannot be undone.',
          style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep Order'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Yes, Cancel Order',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final id = _safeId(widget.order['orderId'] ?? widget.order['id']);
    if (id <= 0) {
      _showMessage(
        'Could not cancel this order because its order ID is missing.',
      );
      return;
    }

    setState(() => _cancellingOrder = true);
    try {
      final dynamic response = await EcoLoopApi.instance.post(
        '/orders/$id/cancel',
        <String, dynamic>{},
      );
      if (!mounted) return;

      final Map<String, dynamic> result = response is Map
          ? Map<String, dynamic>.from(response)
          : <String, dynamic>{};

      final returnedStatus = (result['status'] ?? 'cancelled').toString();
      final returnedPaymentStatus = (result['paymentStatus'] ?? '')
          .toString()
          .trim()
          .toLowerCase();

      setState(() {
        _status = returnedStatus;
        _refundExpected =
            _refundExpected ||
            _isPaidPaymentStatus(
              widget.order['paymentStatus'] ?? widget.order['payment'],
            ) ||
            returnedPaymentStatus == 'refund_required';
        _cancellingOrder = false;
      });

      _showMessage('Order cancelled by you.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _cancellingOrder = false);
      _showMessage(
        'Could not cancel this order. It may have already moved beyond Packed. Please refresh your orders and try again.',
      );
    }
  }

  /// Shows payment-support guidance without inventing an email or phone number.
  void _contactEcoLoop() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Contact EcoLoop'),
        content: Text(
          'If your refund has not arrived after 7 days, contact EcoLoop support and provide order ID $orderId. Please use the official EcoLoop support contact provided by the app or its administrator.',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Action placeholder for repeating a purchase on a delivered item.
  void _buyAgain() {
    _showMessage('Buy Again will be connected to the product flow later.');
  }

  /// Opens the bottom sheet menu with additional order options.
  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _bottomSheetOption(
                icon: Icons.share_outlined,
                title: 'Share Order',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showMessage('Order sharing will be connected later.');
                },
              ),
              _bottomSheetOption(
                icon: Icons.receipt_long_outlined,
                title: 'View Invoice',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showMessage('Invoice will be available later.');
                },
              ),
              _bottomSheetOption(
                icon: Icons.help_outline_rounded,
                title: 'Get Help',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _contactEcoLoop();
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  /// Option tile rendered within the options bottom sheet.
  Widget _bottomSheetOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 22),
      leading: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: AppColors.light,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      onTap: onTap,
    );
  }

  /// Title row widget used across section cards.
  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  /// Detail line item with title and right-aligned value.
  Widget _detailRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 19, color: AppColors.primary),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  /// Card container wrapping individual order detail sections.
  Widget _section({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      color: AppColors.surface,
      child: child,
    );
  }

  /// Displays a floating snackbar feedback message.
  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}
