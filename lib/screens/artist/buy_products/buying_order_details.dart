import 'dart:convert';

import 'package:ecoloop/services/ecoloop_api.dart';
import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import 'buying_order_track.dart';

class BuyingOrderDetails extends StatefulWidget {
  final Map<String, dynamic> order;

  const BuyingOrderDetails({super.key, required this.order});

  @override
  State<BuyingOrderDetails> createState() => _BuyingOrderDetailsState();
}

class _BuyingOrderDetailsState extends State<BuyingOrderDetails> {
  late String _status;
  late Map<String, dynamic> _order;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();

    _order = Map<String, dynamic>.from(widget.order);
    _status = (_order['status'] ?? _order['orderStatus'] ?? 'pending')
        .toString();
    _refreshOrder(showErrors: false);
  }

  // GETTERS

  String get productName {
    final value =
        _order['productTitle'] ?? _order['productName'] ?? _order['product'];
    return value?.toString().trim().isNotEmpty == true
        ? value.toString()
        : 'Product details unavailable';
  }

  String get orderId {
    return _order['orderId']?.toString() ?? _order['id']?.toString() ?? '—';
  }

  String get orderDate {
    return _formatDate(_order['createdAt']);
  }

  String get sellerName {
    final value = _order['sellerName'] ?? _order['seller'];
    return value?.toString().trim().isNotEmpty == true
        ? value.toString()
        : 'Seller details unavailable';
  }

  String get quantity {
    return _order['quantity']?.toString() ?? '—';
  }

  double get unitPrice {
    return _amountValue(_order['unitPrice']);
  }

  double get totalAmount {
    return _amountValue(_order['totalAmount']);
  }

  String get paymentStatus {
    return _order['paymentStatus']?.toString() ?? 'pending';
  }

  String get shippingAddress {
    final raw = _order['shippingAddress'] ?? _order['address'];
    if (raw == null || raw.toString().trim().isEmpty) return 'Address not available';
    dynamic value = raw;
    if (raw is String) {
      try { value = jsonDecode(raw); } catch (_) { return raw.trim(); }
    }
    if (value is Map) {
      final parts = <String>[
        value['name'], value['addressLine'], value['area'], value['city'],
        value['state'], value['pincode'],
      ].map((part) => (part ?? '').toString().trim())
       .where((part) => part.isNotEmpty).toList();
      return parts.isEmpty ? 'Address not available' : parts.toSet().join(', ');
    }
    return value.toString();
  }

  IconData get productIcon {
    return _order['icon'] is IconData
        ? _order['icon'] as IconData
        : Icons.inventory_2_outlined;
  }

  bool get isCancelled {
    return _status.toLowerCase() == 'cancelled';
  }

  bool get isDelivered {
    return _status.toLowerCase() == 'delivered';
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtistColors.background,

      appBar: _buildAppBar(),

      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: isCancelled ? 30 : 105),
        child: Column(
          children: [
            _buildOrderHeader(),

            if (isCancelled) _buildCancelledBanner(),

            if (!isCancelled) _buildStatusSection(),

            _buildProductSection(),

            _buildSellerSection(),

            _buildDeliverySection(),

            _buildPaymentSection(),

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

  // APP BAR

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: ArtistColors.surface,
      foregroundColor: ArtistColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,

      leading: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(Icons.arrow_back_rounded),
      ),

      title: Text(
        'Order Details',
        style: ArtistTextStyles.title.copyWith(fontSize: 18),
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

  // ORDER HEADER

  Widget _buildOrderHeader() {
    return Container(
      width: double.infinity,
      color: ArtistColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: ArtistColors.light,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: ArtistColors.primary,
              size: 26,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order placed',
                  style: ArtistTextStyles.small.copyWith(fontSize: 10.5),
                ),

                const SizedBox(height: 4),

                Text(
                  orderDate,
                  style: ArtistTextStyles.bodyMedium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Order ID',
                style: ArtistTextStyles.small.copyWith(fontSize: 10),
              ),

              const SizedBox(height: 4),

              Text(
                '#$orderId',
                style: ArtistTextStyles.bodyMedium.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: ArtistColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // CANCELLED BANNER

  Widget _buildCancelledBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ArtistColors.error.withOpacity(0.07),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: ArtistColors.error.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.cancel_outlined,
            color: ArtistColors.error,
            size: 23,
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Cancelled',
                  style: ArtistTextStyles.bodyMedium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: ArtistColors.error,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'This order is no longer active.',
                  style: ArtistTextStyles.body.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ORDER STATUS

  Widget _buildStatusSection() {
    return _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Order Status',
                  style: ArtistTextStyles.title.copyWith(fontSize: 19),
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
            active: _status.toLowerCase() == 'confirmed',
          ),

          _timelineItem(
            icon: Icons.inventory_2_rounded,
            title: 'Item Packed',
            subtitle: 'Seller has packed your item',
            completed: _isStepCompleted(2),
            active: _status.toLowerCase() == 'packed',
          ),

          _timelineItem(
            icon: Icons.local_shipping_rounded,
            title: 'Shipped',
            subtitle: 'Your item is on the way',
            completed: _isStepCompleted(3),
            active: _status.toLowerCase() == 'shipped',
          ),

          _timelineItem(
            icon: Icons.home_rounded,
            title: 'Out for Delivery',
            subtitle: 'Your item is on its way to you',
            completed: _isStepCompleted(4),
            active: _status.toLowerCase() == 'out_for_delivery',
          ),

          _timelineItem(
            icon: Icons.check_circle_outline_rounded,
            title: 'Delivered',
            subtitle: 'Item delivered successfully',
            completed: _isStepCompleted(5),
            active: _status.toLowerCase() == 'delivered',
            isLast: true,
          ),

          const SizedBox(height: 5),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ArtistColors.light.withOpacity(0.65),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.local_shipping_outlined,
                  size: 18,
                  color: ArtistColors.primary,
                ),

                const SizedBox(width: 9),

                Expanded(
                  child: Text(
                    'Detailed carrier tracking is not provided by the current order API.',
                    style: ArtistTextStyles.body.copyWith(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isStepCompleted(int step) {
    switch (_status.toLowerCase()) {
      case 'confirmed':
        return step <= 1;

      case 'packed':
        return step <= 2;

      case 'shipped':
        return step <= 3;

      case 'out_for_delivery':
        return step <= 4;

      case 'delivered':
        return true;

      default:
        return false;
    }
  }

  Widget _timelineItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool completed,
    required bool active,
    bool isLast = false,
  }) {
    final color = completed
        ? ArtistColors.success
        : active
        ? ArtistColors.primary
        : ArtistColors.border;

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
                      ? ArtistColors.success.withOpacity(0.38)
                      : ArtistColors.border,
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
                  style: ArtistTextStyles.bodyMedium.copyWith(
                    fontSize: 14,
                    fontWeight: active || completed
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: active || completed
                        ? ArtistColors.textPrimary
                        : ArtistColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  subtitle,
                  style: ArtistTextStyles.small.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // STATUS CHIP

  Widget _statusChip() {
    final color = _statusColor(_status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _displayStatus(_status),
        style: ArtistTextStyles.small.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  // PRODUCT

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
              color: ArtistColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ArtistColors.border),
            ),
            child: Row(
              children: [
                Container(
                  height: 78,
                  width: 78,
                  decoration: BoxDecoration(
                    color: ArtistColors.light,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child:
                      (_order['productImage'] ?? _order['imageUrl'] ?? '')
                          .toString()
                          .trim()
                          .isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.network(
                            (_order['productImage'] ?? _order['imageUrl'])
                                .toString(),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              productIcon,
                              size: 38,
                              color: ArtistColors.primary,
                            ),
                          ),
                        )
                      : Icon(
                          productIcon,
                          size: 38,
                          color: ArtistColors.primary,
                        ),
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
                        style: ArtistTextStyles.bodyMedium.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 7),

                      Text(
                        'Quantity: $quantity',
                        style: ArtistTextStyles.small.copyWith(fontSize: 11),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        _formatCurrency(totalAmount),
                        style: ArtistTextStyles.bodyMedium.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: ArtistColors.primary,
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

  // SELLER

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
                  color: ArtistColors.light,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: ArtistColors.primary,
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
                      style: ArtistTextStyles.bodyMedium.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: ArtistColors.warning,
                        ),

                        const SizedBox(width: 3),

                        Text(
                          (_order['sellerType']?.toString() ?? '')
                                      .toLowerCase() ==
                                  'artist'
                              ? 'Artist seller'
                              : 'Seller',
                          style: ArtistTextStyles.small.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              OutlinedButton(
                onPressed: () {
                  _showMessage(
                    'Seller contact details are not available for this order.',
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: ArtistColors.primary,
                  side: const BorderSide(color: ArtistColors.primary),
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: Text(
                  'Contact',
                  style: ArtistTextStyles.bodyMedium.copyWith(
                    fontSize: 11,
                    color: ArtistColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // DELIVERY

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
              color: ArtistColors.light.withOpacity(0.60),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: ArtistColors.primary,
                  size: 22,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Deliver to',
                        style: ArtistTextStyles.small.copyWith(fontSize: 10),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'Your Delivery Address',
                        style: ArtistTextStyles.bodyMedium.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        shippingAddress,
                        style: ArtistTextStyles.body.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          _detailRow(
            Icons.local_shipping_outlined,
            'Delivery speed',
            (_order['deliveryMethod'] ?? 'standard').toString().toLowerCase().contains('express')
                ? 'Express'
                : 'Standard',
          ),

          const SizedBox(height: 12),

          _detailRow(
            Icons.storefront_outlined,
            'Delivery responsibility',
            (_order['deliveryResponsibility'] ?? '').toString().trim().isEmpty
                ? 'Not recorded for this order'
                : _order['deliveryResponsibility'].toString().replaceAll('_', ' '),
          ),

          const SizedBox(height: 12),

          _detailRow(
            Icons.event_outlined,
            'Expected',
            isDelivered
                ? 'Delivered successfully'
                : (_order['expectedDelivery'] ??
                          _order['estimatedDelivery'] ??
                          'Not provided by seller')
                      .toString(),
          ),
        ],
      ),
    );
  }

  // PAYMENT

  Widget _buildPaymentSection() {
    return _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Payment Summary', Icons.receipt_long_outlined),

          const SizedBox(height: 18),

          _billRow(
            'Item subtotal',
            _formatCurrency(
              _amountValue(_order['subtotal']) > 0
                  ? _amountValue(_order['subtotal'])
                  : totalAmount,
            ),
          ),

          _billRow(
            'Platform fee',
            _formatCurrency(_amountValue(_order['platformFee'])),
          ),

          _billRow(
            'GST on platform fee',
            _formatCurrency(_amountValue(_order['taxAmount'])),
          ),

          if (_amountValue(_order['couponDiscount']) > 0)
            _billRow(
              'Coupon discount',
              '−${_formatCurrency(_amountValue(_order['couponDiscount']))}',
            ),

          _billRow(
            'Delivery charges',
            _formatCurrency(_amountValue(_order['deliveryCharge'])),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 5),
            child: Divider(color: ArtistColors.border),
          ),

          _billRow('Order total', _formatCurrency(totalAmount), bold: true),

          const SizedBox(height: 5),

          Row(
            children: [
              const Icon(
                Icons.verified_outlined,
                size: 15,
                color: ArtistColors.success,
              ),

              const SizedBox(width: 5),

              Text(
                _formatPaymentStatus(paymentStatus),
                style: ArtistTextStyles.small.copyWith(
                  fontSize: 11,
                  color: ArtistColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _billRow(String title, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: ArtistTextStyles.body.copyWith(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),

          Text(
            value,
            style: ArtistTextStyles.bodyMedium.copyWith(
              fontSize: bold ? 16 : 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: bold ? ArtistColors.primary : ArtistColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ORDER INFORMATION

  Widget _buildOrderInformation() {
    return _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Order Information', Icons.info_outline_rounded),

          const SizedBox(height: 18),

          _informationRow('Order ID', '#$orderId'),

          _informationRow('Order placed', orderDate),

          _informationRow('Product ID', _order['productId']?.toString() ?? '-'),

          _informationRow('Payment', _formatPaymentStatus(paymentStatus)),

          _informationRow('Status', _displayStatus(_status), isLast: true),
        ],
      ),
    );
  }

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
              style: ArtistTextStyles.small.copyWith(fontSize: 12),
            ),
          ),

          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: ArtistTextStyles.bodyMedium.copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ECOLOOP PROTECTION

  Widget _buildEcoLoopProtection() {
    return _section(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: ArtistColors.light,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ArtistColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.eco_rounded,
              color: ArtistColors.primary,
              size: 24,
            ),

            const SizedBox(width: 11),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EcoLoop Purchase Protection',
                    style: ArtistTextStyles.bodyMedium.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    'Your purchase is protected through the EcoLoop order process.',
                    style: ArtistTextStyles.body.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // DELIVERED MESSAGE

  Widget _buildDeliveredMessage() {
    return _section(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: ArtistColors.light,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: ArtistColors.success,
              size: 23,
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Text(
                'Your order was delivered successfully. We hope you enjoy your item!',
                style: ArtistTextStyles.body.copyWith(fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // HELP

  Widget _buildHelpSection() {
    return _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Need Help?', Icons.support_agent_outlined),

          const SizedBox(height: 13),

          InkWell(
            onTap: () {
              _showMessage(
                'Please use the support option in your account settings.',
              );
            },
            borderRadius: BorderRadius.circular(15),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: ArtistColors.light,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.support_agent_rounded,
                    color: ArtistColors.primary,
                  ),

                  const SizedBox(width: 11),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contact EcoLoop Support',
                          style: ArtistTextStyles.bodyMedium.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          'Get help with your order',
                          style: ArtistTextStyles.small.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: ArtistColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // BOTTOM BAR

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
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
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isDelivered ? _buyAgain : _cancelOrder,
                icon: Icon(
                  isDelivered ? Icons.refresh_rounded : Icons.cancel_outlined,
                  size: 17,
                ),
                label: Text(isDelivered ? 'Buy Again' : 'Cancel Order'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDelivered
                      ? ArtistColors.primary
                      : ArtistColors.error,
                  side: BorderSide(
                    color: isDelivered
                        ? ArtistColors.primary
                        : ArtistColors.error,
                  ),
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: ElevatedButton.icon(
                onPressed: _trackOrder,
                icon: const Icon(Icons.local_shipping_outlined, size: 17),
                label: const Text('Track Order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ArtistColors.primary,
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

  // MORE OPTIONS

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ArtistColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ArtistColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 18),

                _moreOption(
                  icon: Icons.receipt_long_outlined,
                  title: 'Order Receipt',
                  onTap: () {
                    Navigator.pop(context);

                    _showMessage(
                      'A downloadable receipt is not available from the current backend response.',
                    );
                  },
                ),

                _moreOption(
                  icon: Icons.share_outlined,
                  title: 'Share Order',
                  onTap: () {
                    Navigator.pop(context);

                    _showMessage('Order ID: $orderId');
                  },
                ),

                _moreOption(
                  icon: Icons.help_outline_rounded,
                  title: 'Get Help',
                  onTap: () {
                    Navigator.pop(context);

                    _showMessage(
                      'Please use the support option in your account settings.',
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _moreOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 2),
      onTap: onTap,
      leading: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: ArtistColors.light,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: ArtistColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: ArtistTextStyles.bodyMedium.copyWith(fontSize: 13),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: ArtistColors.textSecondary,
      ),
    );
  }

  // TRACK ORDER

  void _trackOrder() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OrderTracking(order: _order)),
    );
  }

  // CANCEL ORDER

  Future<void> _refreshOrder({bool showErrors = true}) async {
    final id = _order['orderId'] ?? _order['id'];
    if (id == null || id.toString().trim().isEmpty) return;
    if (mounted) setState(() => _isRefreshing = true);
    try {
      final response = await EcoLoopApi.instance.get(
        '/orders/${Uri.encodeComponent(id.toString())}',
      );
      final dynamic payload = response is Map
          ? (response['order'] ?? response['data'] ?? response)
          : response;
      if (payload is Map) {
        final fresh = Map<String, dynamic>.from(payload);
        if (mounted) {
          setState(() {
            _order = {..._order, ...fresh};
            _status = (_order['status'] ?? _order['orderStatus'] ?? _status)
                .toString();
          });
        }
      }
    } catch (error) {
      if (showErrors && mounted) {
        _showMessage(
          'Could not refresh order: ${error.toString().replaceFirst('Exception: ', '')}',
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _cancelOrder() async {
    if ([
      'shipped',
      'out_for_delivery',
      'delivered',
      'cancelled',
    ].contains(_status.toLowerCase())) {
      _showMessage('This order can no longer be cancelled.');
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ArtistColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Cancel Order?',
          style: ArtistTextStyles.title.copyWith(fontSize: 19),
        ),
        content: Text(
          'Are you sure you want to cancel this order?',
          style: ArtistTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Keep Order', style: ArtistTextStyles.bodyMedium),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final id = _order['orderId'] ?? _order['id'];
              if (id == null) {
                _showMessage('Order ID is missing. Cannot cancel this order.');
                return;
              }
              try {
                final response = await EcoLoopApi.instance.post(
                  '/orders/$id/cancel',
                  {},
                );
                if (response is Map) {
                  final dynamic payload =
                      response['order'] ?? response['data'] ?? response;
                  if (payload is Map)
                    _order = {..._order, ...Map<String, dynamic>.from(payload)};
                }
                await _refreshOrder(showErrors: false);
                if (mounted) {
                  setState(
                    () => _status =
                        (_order['status'] ??
                                _order['orderStatus'] ??
                                'cancelled')
                            .toString(),
                  );
                  _showMessage('Order cancellation confirmed by the server.');
                }
              } catch (error) {
                _showMessage(
                  'Cancellation failed: ${error.toString().replaceFirst('Exception: ', '')}',
                );
              }
            },
            child: Text(
              'Cancel Order',
              style: ArtistTextStyles.bodyMedium.copyWith(
                color: ArtistColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // BUY AGAIN

  void _buyAgain() {
    _showMessage(
      'Open the marketplace to check whether this item is available again.',
    );
  }

  // COMMON SECTION

  Widget _section({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(20),
      color: ArtistColors.surface,
      child: child,
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: ArtistColors.primary, size: 21),

        const SizedBox(width: 8),

        Text(title, style: ArtistTextStyles.title.copyWith(fontSize: 17)),
      ],
    );
  }

  Widget _detailRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: ArtistColors.textSecondary),

        const SizedBox(width: 10),

        Expanded(
          child: Text(
            title,
            style: ArtistTextStyles.small.copyWith(fontSize: 11),
          ),
        ),

        Text(
          value,
          textAlign: TextAlign.right,
          style: ArtistTextStyles.bodyMedium.copyWith(fontSize: 12),
        ),
      ],
    );
  }

  // HELPERS

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return ArtistColors.warning;

      case 'confirmed':
        return ArtistColors.info;

      case 'packed':
        return ArtistColors.primary;

      case 'shipped':
        return ArtistColors.info;

      case 'out_for_delivery':
        return ArtistColors.accent;

      case 'delivered':
        return ArtistColors.success;

      case 'cancelled':
        return ArtistColors.error;

      default:
        return ArtistColors.textSecondary;
    }
  }

  String _displayStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';

      case 'confirmed':
        return 'Confirmed';

      case 'packed':
        return 'Packed';

      case 'shipped':
        return 'Shipped';

      case 'out_for_delivery':
        return 'Out for Delivery';

      case 'delivered':
        return 'Delivered';

      case 'cancelled':
        return 'Cancelled';

      default:
        return status;
    }
  }

  String _formatPaymentStatus(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'Paid Online';

      case 'pending':
        return 'Payment Pending';

      case 'refunded':
        return 'Refunded';

      case 'failed':
        return 'Payment Failed';

      default:
        return status.isEmpty ? 'Payment Pending' : status;
    }
  }

  double _amountValue(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatCurrency(double amount) {
    if (amount == amount.roundToDouble()) {
      return '₹${amount.toInt()}';
    }

    return '₹${amount.toStringAsFixed(2)}';
  }

  String _formatDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');

    if (date == null) {
      return value?.toString() ?? '-';
    }

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

    return '${date.day} '
        '${months[date.month - 1]} '
        '${date.year}';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: ArtistTextStyles.bodyMedium.copyWith(
            color: Colors.white,
            fontSize: 12.5,
          ),
        ),
        backgroundColor: ArtistColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

