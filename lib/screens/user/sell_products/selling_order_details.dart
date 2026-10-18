import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../services/ecoloop_api.dart';
import 'selling_order_status.dart';

class SellingOrderDetails extends StatefulWidget {
  final Map<String, dynamic> order;

  const SellingOrderDetails({super.key, required this.order});

  @override
  State<SellingOrderDetails> createState() => _SellingOrderDetailsState();
}

class _SellingOrderDetailsState extends State<SellingOrderDetails> {
  late Map<String, dynamic> _order;
  bool _loading = false;
  bool _cancelling = false;
  bool _refundExpected = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _order = Map<String, dynamic>.from(widget.order);
    _refundExpected = _isPaid('${_order['paymentStatus'] ?? ''}');
  }

  int get _id =>
      int.tryParse('${_order['orderId'] ?? _order['id'] ?? ''}') ?? 0;

  double _num(dynamic value) => double.tryParse('${value ?? 0}') ?? 0;

  String _pretty(String value) => value
      .replaceAll('_', ' ')
      .split(' ')
      .where((p) => p.isNotEmpty)
      .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
      .join(' ');

  String get _status => _pretty('${_order['status'] ?? 'new_order'}');

  String get _product =>
      '${_order['productName'] ?? _order['product'] ?? 'Product #${_order['productId'] ?? '—'}'}';

  String get _buyer =>
      '${_order['buyerName'] ?? _order['buyer'] ?? (_order['buyerId'] == null ? 'Buyer details unavailable' : 'Buyer #${_order['buyerId']}')}';

  String get _normalizedStatus => '${_order['status'] ?? 'new_order'}'
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[ -]+'), '_');

  bool get _terminal =>
      ['delivered', 'completed', 'cancelled'].contains(_normalizedStatus);

  // A seller can cancel only while the order is Pending, Confirmed, or Packed.
  bool get _canCancel =>
      !_cancelling &&
      !_loading &&
      const {
        'new_order',
        'pending',
        'confirmed',
        'packed',
      }.contains(_normalizedStatus);

  bool _isPaid(String value) => const {
    'paid',
    'completed',
    'success',
    'successful',
    'captured',
  }.contains(value.trim().toLowerCase());

  double get _subtotal => _num(
    _order['subtotal'] ??
        _order['totalAmount'] ??
        _order['priceValue'] ??
        _order['price'],
  );

  double get _platformFee => _num(_order['platformFee']);

  double get _tax => _num(_order['taxAmount']);

  double get _delivery => _num(_order['deliveryCharge']);

  double get _sellerDeliveryCost => _num(
    _order['sellerDeliveryCost'] ??
        _order['sellerCourierCost'] ??
        _order['deliveryCostToSeller'],
  );

  String get _deliveryResponsibility {
    final raw =
        '${_order['deliveryResponsibility'] ?? _order['deliveryService'] ?? _order['productDeliveryMethod'] ?? _order['deliveryType'] ?? ''}'
            .trim()
            .toLowerCase()
            .replaceAll('_', ' ')
            .replaceAll('-', ' ');
    if (raw.contains('free delivery') ||
        raw == 'seller' ||
        raw.contains('self'))
      return 'Free Delivery (seller-managed)';
    if (raw.contains('ecoloop') || raw.contains('managed'))
      return 'EcoLoop-Managed Delivery';
    return raw.isEmpty ? 'Not recorded' : _pretty(raw);
  }

  double get _net => _subtotal - _sellerDeliveryCost;

  String _money(dynamic amount) => '₹${_num(amount).toStringAsFixed(2)}';

  /// Turns the saved shippingAddress value into a readable address.
  /// The API may return a JSON string or an already-decoded map, so handle
  /// both without requiring any backend changes.
  String _formatShippingAddress(dynamic raw) {
    if (raw == null) return 'Shipping address is not available.';

    dynamic value = raw;
    if (value is String) {
      final text = value.trim();
      if (text.isEmpty || text.toLowerCase() == 'null') {
        return 'Shipping address is not available.';
      }
      // Older order records store the address object as JSON text.
      if ((text.startsWith('{') && text.endsWith('}')) ||
          (text.startsWith('[') && text.endsWith(']'))) {
        try {
          value = jsonDecode(text);
        } catch (_) {
          return text;
        }
      } else {
        // If this is already a human-readable address, tidy its separators.
        return text
            .replaceAll(RegExp(r'\s*,\s*'), ', ')
            .replaceAll(RegExp(r'(,\s*){2,}'), ', ')
            .replaceAll(RegExp(r'^,\s*|,\s*$'), '');
      }
    }

    if (value is Map) {
      final address = Map<String, dynamic>.from(value);
      String pick(List<String> keys) {
        for (final key in keys) {
          final candidate = address[key];
          if (candidate == null) continue;
          final text = '$candidate'.trim();
          if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
        }
        return '';
      }

      final label = pick(['label', 'addressLabel']);
      final name = pick(['name', 'recipientName', 'fullName']);
      final phone = pick(['phone', 'mobile', 'phoneNumber']);
      final line = pick(['addressLine', 'address', 'street', 'line1']);
      final line2 = pick(['addressLine2', 'line2']);
      final area = pick(['area', 'locality', 'landmark']);
      final city = pick(['city', 'cityName']);
      final state = pick(['state', 'stateName']);
      final pincode = pick([
        'pincode',
        'pinCode',
        'postalCode',
        'zipCode',
        'zip',
      ]);

      final parts = <String>[
        if (label.isNotEmpty) label,
        if (name.isNotEmpty && name.toLowerCase() != label.toLowerCase()) name,
        if (phone.isNotEmpty) phone,
        if (line.isNotEmpty) line,
        if (line2.isNotEmpty) line2,
        if (area.isNotEmpty) area,
        if (city.isNotEmpty) city,
        if (state.isNotEmpty) state,
        if (pincode.isNotEmpty) pincode,
      ];
      final uniqueParts = <String>[];
      for (final part in parts) {
        final cleaned = part.replaceAll(RegExp(r'\s+'), ' ').trim();
        if (cleaned.isNotEmpty &&
            (uniqueParts.isEmpty ||
                uniqueParts.last.toLowerCase() != cleaned.toLowerCase())) {
          uniqueParts.add(cleaned);
        }
      }
      return uniqueParts.isEmpty
          ? 'Shipping address is not available.'
          : uniqueParts.join(', ');
    }

    if (value is List) {
      return value
          .map((item) => '$item'.trim())
          .where((item) => item.isNotEmpty && item.toLowerCase() != 'null')
          .join(', ');
    }

    return '$value';
  }

  String _formatOrderDate(dynamic raw) {
    final value = '${raw ?? ''}'.trim();
    if (value.isEmpty || value.toLowerCase() == 'null') {
      return 'Date unavailable';
    }

    // Apps Script stores timestamps as IST: yyyy-MM-dd HH:mm:ss.
    // Parse this format as wall-clock IST and do not shift it by device timezone.
    final ist = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2})(?::(\d{2}))?$',
    ).firstMatch(value);
    if (ist != null) {
      final dt = DateTime(
        int.parse(ist.group(1)!),
        int.parse(ist.group(2)!),
        int.parse(ist.group(3)!),
        int.parse(ist.group(4)!),
        int.parse(ist.group(5)!),
        int.parse(ist.group(6) ?? '0'),
      );
      return _formatDateTime(dt);
    }

    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    // Explicit timezone timestamps are converted to the device's local timezone;
    // date-only/naive values are displayed as entered.
    final hasTimezone = RegExp(
      r'(Z|[+-]\d{2}:?\d{2})$',
      caseSensitive: false,
    ).hasMatch(value);
    return _formatDateTime(hasTimezone ? parsed.toLocal() : parsed);
  }

  String _formatDateTime(DateTime date) {
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
    final hour24 = date.hour;
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} '
        '${date.year}, ${hour12.toString().padLeft(2, '0')}:$minute $period';
  }

  Future<void> _cancelOrder() async {
    if (!_canCancel || _id <= 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel this order?'),
        content: const Text(
          'Are you sure you want to cancel this sale? The buyer will be notified. '
          'Orders can only be cancelled before they move beyond Packed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep Order'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() {
      _cancelling = true;
      _error = null;
    });

    try {
      final result = await EcoLoopApi.instance.post(
        '/selling/orders/$_id/status',
        <String, dynamic>{'status': 'cancelled'},
      );

      if (!mounted) return;
      if (result is Map) {
        final response = Map<String, dynamic>.from(result);
        final nestedOrder = response['order'];
        if (nestedOrder is Map) {
          _order = {..._order, ...Map<String, dynamic>.from(nestedOrder)};
        } else {
          _order = {..._order, ...response};
        }
      }
      _order['status'] = 'cancelled';
      _refundExpected =
          _isPaid('${_order['paymentStatus'] ?? ''}') ||
          _refundExpected ||
          '${_order['paymentStatus'] ?? ''}'.toLowerCase() == 'refund_required';

      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Order cancelled successfully. The buyer will be notified.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _error ?? 'Could not cancel this order. Please try again.',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  void _contactEcoLoop() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Contact EcoLoop'),
        content: Text(
          'For help with the cancellation or refund, contact EcoLoop support '
          'through the official support channel in the app.\n\nOrder ID: #$_id\n'
          'If payment was completed, refunds generally take 5–7 days after processing. '
          'If the refund has not arrived after 7 days, contact support and include this order ID.',
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

  Future<void> _refresh() async {
    if (_id <= 0) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await EcoLoopApi.instance.get('/orders/$_id');
      if (result is Map)
        _order = {..._order, ...Map<String, dynamic>.from(result)};
    } catch (e) {
      if (mounted) _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = '${_order['productImage'] ?? ''}'.trim();
    final date = _formatOrderDate(_order['createdAt'] ?? _order['date']);
    final statusColor = _status == 'Delivered' || _status == 'Completed'
        ? AppColors.success
        : _status == 'Cancelled'
        ? AppColors.error
        : AppColors.primary;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Sale Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 25),
                  children: [
                    Container(
                      color: AppColors.surface,
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
                      child: Row(
                        children: [
                          Container(
                            height: 58,
                            width: 58,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: AppColors.light,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: image.isNotEmpty
                                ? Image.network(
                                    image,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.storefront_outlined,
                                      color: AppColors.primary,
                                      size: 28,
                                    ),
                                  )
                                : const Icon(
                                    Icons.storefront_outlined,
                                    color: AppColors.primary,
                                    size: 28,
                                  ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Sale received',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  date,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Buyer: $_buyer',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'ORDER ID',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: AppColors.textSecondary,
                                  letterSpacing: .5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '#$_id',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    if (_loading) const LinearProgressIndicator(minHeight: 2),
                    if (_normalizedStatus == 'cancelled')
                      _section('Order Cancelled', Icons.cancel_outlined, [
                        const Text(
                          'This order has been cancelled and the buyer will be notified.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (_refundExpected) ...[
                          const SizedBox(height: 10),
                          const Text(
                            'If the buyer has already paid, the refund may take 5–7 days after processing. If it has not arrived after 7 days, contact EcoLoop support.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: _contactEcoLoop,
                            icon: const Icon(Icons.support_agent_rounded),
                            label: const Text('Contact EcoLoop'),
                          ),
                        ],
                      ]),
                    _section('Sale Status', Icons.local_shipping_outlined, [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _status,
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: statusColor,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      ..._timeline(),
                      const SizedBox(height: 5),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.light.withOpacity(.65),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Keep the order status updated so the buyer can follow delivery progress.',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  height: 1.4,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]),
                    _section('Item Sold', Icons.inventory_2_outlined, [
                      Row(
                        children: [
                          Container(
                            height: 76,
                            width: 76,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: AppColors.light,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: image.isNotEmpty
                                ? Image.network(
                                    image,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.inventory_2_outlined,
                                      size: 34,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : const Icon(
                                    Icons.inventory_2_outlined,
                                    size: 34,
                                    color: AppColors.primary,
                                  ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _product,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Quantity: ${_order['quantity'] ?? 1}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  _money(_subtotal),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _info(
                        'Product ID',
                        '${_order['productId'] ?? 'Not provided'}',
                      ),
                      _info(
                        'Seller type',
                        _pretty('${_order['sellerType'] ?? 'user'}'),
                      ),
                    ]),
                    _section(
                      'Earnings Breakdown',
                      Icons.account_balance_wallet_outlined,
                      [
                        _moneyRow('Product subtotal', _money(_subtotal)),
                        _moneyRow(
                          'Platform fee (paid by buyer)',
                          _money(_platformFee),
                        ),
                        _moneyRow(
                          'Seller-paid delivery cost',
                          _money(_sellerDeliveryCost),
                        ),
                        _moneyRow(
                          'Estimated seller net',
                          _money(_net),
                          strong: true,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Platform fee and GST are buyer-side charges, not deducted from seller earnings. Only a recorded seller-paid delivery cost is deducted here.',
                          style: TextStyle(
                            fontSize: 10.5,
                            height: 1.45,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _info('Tax amount', _money(_tax)),
                        _info(
                          'Delivery responsibility',
                          _deliveryResponsibility,
                        ),
                        _info('Buyer delivery charge', _money(_delivery)),
                      ],
                    ),
                    _section(
                      'Buyer Information',
                      Icons.person_outline_rounded,
                      [
                        _info('Buyer', _buyer),
                        _info(
                          'Buyer ID',
                          '${_order['buyerId'] ?? 'Not provided'}',
                        ),
                        _info(
                          'Payment',
                          _pretty('${_order['paymentStatus'] ?? 'unknown'}'),
                        ),
                      ],
                    ),
                    _section('Delivery Details', Icons.location_on_outlined, [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.light.withOpacity(.45),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _formatShippingAddress(
                                  _order['shippingAddress'],
                                ),
                                softWrap: true,
                                style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.55,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _info(
                        'Delivery method',
                        '${_order['deliveryMethod'] ?? 'EcoLoop delivery'}',
                      ),
                    ]),
                  ],
                ),
              ),
            ),
            if (!_terminal)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.06),
                      blurRadius: 15,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_canCancel)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _cancelling ? null : _cancelOrder,
                            icon: _cancelling
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.cancel_outlined),
                            label: Text(
                              _cancelling ? 'Cancelling…' : 'Cancel Order',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                            ),
                          ),
                        ),
                      if (_canCancel) const SizedBox(height: 9),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _loading || _cancelling || _id <= 0
                              ? null
                              : () async {
                                  final changed = await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          SellingOrderStatus(order: _order),
                                    ),
                                  );
                                  if (changed == true) {
                                    await _refresh();
                                    if (mounted) Navigator.pop(context, true);
                                  }
                                },
                          icon: const Icon(Icons.update_rounded),
                          label: const Text('Update Order Status'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _timeline() {
    const steps = [
      ['new_order', 'Order Received', Icons.shopping_bag_outlined],
      ['confirmed', 'Order Confirmed', Icons.check_circle_outline_rounded],
      ['packed', 'Item Packed', Icons.inventory_2_outlined],
      ['shipped', 'Shipped', Icons.local_shipping_outlined],
      ['out_for_delivery', 'Out for Delivery', Icons.delivery_dining_outlined],
      ['delivered', 'Delivered', Icons.home_outlined],
    ];
    final current = '${_order['status'] ?? 'new_order'}'
        .toLowerCase()
        .replaceAll(' ', '_');
    final index = steps.indexWhere((s) => s[0] == current);
    if (current == 'cancelled')
      return [
        const Text('Order cancelled', style: TextStyle(color: AppColors.error)),
      ];
    return List.generate(steps.length, (i) {
      final done = i <= (index < 0 ? 0 : index);
      return Padding(
        padding: const EdgeInsets.only(bottom: 13),
        child: Row(
          children: [
            Container(
              height: 28,
              width: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? AppColors.light : AppColors.background,
                border: Border.all(
                  color: done ? AppColors.success : AppColors.accent,
                ),
              ),
              child: Icon(
                done ? Icons.check_rounded : steps[i][2] as IconData,
                size: 15,
                color: done ? AppColors.success : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                steps[i][1] as String,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: done ? FontWeight.w700 : FontWeight.w500,
                  color: done ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ),
            if (i == index)
              const Text(
                'CURRENT',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _section(String title, IconData icon, List<Widget> children) =>
      Container(
        margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.accent.withOpacity(.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            ...children,
          ],
        ),
      );

  Widget _info(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 108,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
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

  Widget _moneyRow(String label, String value, {bool strong = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
                  color: strong
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: strong ? AppColors.success : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      );
}
