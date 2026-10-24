import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import '../../../services/ecoloop_api.dart';
import '../buy_products/seller_profile.dart';
import '../profile/artist_profile.dart';
import 'selling_order_status.dart';

class SellingOrderDetails extends StatefulWidget {
  final Map<String, dynamic> order;

  const SellingOrderDetails({super.key, required this.order});

  @override
  State<SellingOrderDetails> createState() => _SellingOrderDetailsState();
}

class _SellingOrderDetailsState extends State<SellingOrderDetails> {
  // DATA

  String get productName {
    return widget.order['productTitle']?.toString() ??
        widget.order['productName']?.toString() ??
        widget.order['product']?.toString() ??
        'Product';
  }

  String get orderId {
    return widget.order['orderId']?.toString() ?? '-';
  }

  String get orderDate {
    return _formatSheetDateTime(widget.order['createdAt']);
  }

  String get updatedDate {
    return _formatSheetDateTime(widget.order['updatedAt']);
  }

  String get buyerId {
    final name = (widget.order['buyerName'] ?? '').toString().trim();
    if (name.isNotEmpty) {
      return name;
    }
    final id = (widget.order['buyerId'] ?? '').toString().trim();
    return id.isEmpty ? '-' : id;
  }

  String get buyerName {
    final value =
        (widget.order['buyerName'] ??
                widget.order['buyerFullName'] ??
                widget.order['customerName'] ??
                widget.order['name'] ??
                '')
            .toString()
            .trim();
    return value.isEmpty ? 'EcoLoop Buyer' : value;
  }

  String get buyerEmail {
    return (widget.order['buyerEmail'] ??
            widget.order['buyer_email'] ??
            widget.order['customerEmail'] ??
            widget.order['email'] ??
            '')
        .toString()
        .trim();
  }

  String get buyerPhone {
    return (widget.order['buyerPhone'] ??
            widget.order['buyerMobile'] ??
            widget.order['customerPhone'] ??
            widget.order['phone'] ??
            '')
        .toString()
        .trim();
  }

  String get buyerImage {
    return (widget.order['buyerProfileImage'] ??
            widget.order['buyerPhoto'] ??
            widget.order['buyerAvatar'] ??
            widget.order['buyerImage'] ??
            '')
        .toString()
        .trim();
  }

  String get productImage {
    final raw =
        widget.order['productImageUrl'] ??
        widget.order['productImage'] ??
        widget.order['imageUrl'] ??
        widget.order['image'] ??
        widget.order['imageUrls'] ??
        widget.order['images'];
    if (raw is List) {
      for (final item in raw) {
        final url = item.toString().trim();
        if (url.startsWith('https://') || url.startsWith('http://')) return url;
      }
    }
    if (raw is String) {
      final value = raw.trim();
      if (value.startsWith('https://') || value.startsWith('http://')) {
        return value;
      }
      if (value.startsWith('[') && value.endsWith(']')) {
        try {
          final decoded = jsonDecode(value);
          if (decoded is List) {
            for (final item in decoded) {
              final url = item.toString().trim();
              if (url.startsWith('https://') || url.startsWith('http://')) {
                return url;
              }
            }
          }
        } catch (_) {}
      }
      final first = value
          .split(',')
          .first
          .trim()
          .replaceAll('"', '')
          .replaceAll("'", '');
      if (first.startsWith('https://') || first.startsWith('http://')) {
        return first;
      }
    }
    return '';
  }

  String get quantity {
    return widget.order['quantity']?.toString() ?? '0';
  }

  double get unitPriceValue {
    return _toDouble(widget.order['unitPrice']);
  }

  double get totalAmountValue {
    return _toDouble(widget.order['totalAmount']);
  }

  String get unitPrice {
    return _formatCurrency(unitPriceValue);
  }

  String get totalAmount {
    return _formatCurrency(totalAmountValue);
  }

  String get shippingAddress {
    final raw = widget.order['shippingAddress'] ?? widget.order['address'];
    if (raw == null || raw.toString().trim().isEmpty) {
      return 'Delivery address unavailable';
    }
    dynamic value = raw;
    if (raw is String) {
      try {
        value = jsonDecode(raw);
      } catch (_) {
        return raw.trim();
      }
    }
    if (value is Map) {
      final parts =
          <String>[
                value['name'],
                value['addressLine'],
                value['area'],
                value['city'],
                value['state'],
                value['pincode'],
              ]
              .map((part) => (part ?? '').toString().trim())
              .where((part) => part.isNotEmpty)
              .toList();
      return parts.isEmpty
          ? 'Delivery address unavailable'
          : parts.toSet().join(', ');
    }
    return value.toString();
  }

  String get paymentStatus {
    return widget.order['paymentStatus']?.toString() ?? 'pending';
  }

  String get payment {
    return _formatStatus(paymentStatus);
  }

  String get currentStatus {
    return widget.order['status']?.toString() ?? 'pending';
  }

  bool get isCancelled {
    return currentStatus.toLowerCase() == 'cancelled';
  }

  bool get isDelivered {
    return currentStatus.toLowerCase() == 'delivered';
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtistColors.background,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RepaintBoundary(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    bottom: isCancelled || isDelivered ? 30 : 20,
                  ),
                  child: Column(
                    children: [
                      _buildSaleHeader(),
                      if (isCancelled) _buildCancelledBanner(),
                      _buildStatusSection(),
                      _buildProductSection(),
                      _buildBuyerSection(),
                      _buildDeliverySection(),
                      _buildEarningsSection(),
                      _buildOrderInformation(),
                      _buildSellerProtection(),
                      if (isDelivered) _buildCompletedMessage(),
                      _buildHelpSection(),
                    ],
                  ),
                ),
              ),
            ),
            if (!isCancelled) _buildBottomBar(),
          ],
        ),
      ),
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
        'Sale Details',
        style: ArtistTextStyles.title.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
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

  // SALE HEADER

  Widget _buildSaleHeader() {
    return Container(
      width: double.infinity,
      color: ArtistColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
      child: Row(
        children: [
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: ArtistColors.light,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.storefront_outlined,
              color: ArtistColors.primary,
              size: 27,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sale received',
                  style: ArtistTextStyles.small.copyWith(fontSize: 11),
                ),

                const SizedBox(height: 4),

                Text(
                  orderDate,
                  style: ArtistTextStyles.bodyMedium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  'Buyer #$buyerId',
                  style: ArtistTextStyles.small.copyWith(fontSize: 10.5),
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

  // CANCELLED

  Widget _buildCancelledBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ArtistColors.error.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: ArtistColors.error.withValues(alpha: 0.18)),
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
                  'Sale Cancelled',
                  style: ArtistTextStyles.bodyMedium.copyWith(
                    fontSize: 14,
                    color: ArtistColors.error,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'This sale is no longer active.',
                  style: ArtistTextStyles.small.copyWith(
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // STATUS SECTION

  Widget _buildStatusSection() {
    return _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Sale Status',
                  style: ArtistTextStyles.title.copyWith(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              _statusChip(),
            ],
          ),

          const SizedBox(height: 23),

          _timelineItem(
            icon: Icons.shopping_bag_rounded,
            title: 'Order Received',
            subtitle: 'Someone purchased your item',
            completed: _isStepCompleted(0),
            active: currentStatus == 'pending',
          ),

          _timelineItem(
            icon: Icons.check_circle_outline_rounded,
            title: 'Order Confirmed',
            subtitle: 'You confirmed the buyer\'s order',
            completed: _isStepCompleted(1),
            active: currentStatus == 'confirmed',
          ),

          _timelineItem(
            icon: Icons.inventory_2_rounded,
            title: 'Item Packed',
            subtitle: 'Get the item ready for delivery',
            completed: _isStepCompleted(2),
            active: currentStatus == 'packed',
          ),

          _timelineItem(
            icon: Icons.local_shipping_rounded,
            title: 'Shipped',
            subtitle: 'Item has been handed over for delivery',
            completed: _isStepCompleted(3),
            active: currentStatus == 'shipped',
          ),

          _timelineItem(
            icon: Icons.delivery_dining_rounded,
            title: 'Out for Delivery',
            subtitle: 'Package is on its way to the buyer',
            completed: _isStepCompleted(4),
            active: currentStatus == 'out_for_delivery',
          ),

          _timelineItem(
            icon: Icons.check_circle_rounded,
            title: 'Delivered',
            subtitle: 'Buyer received the item',
            completed: _isStepCompleted(5),
            active: isDelivered,
            isLast: true,
          ),

          const SizedBox(height: 7),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ArtistColors.light.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: ArtistColors.primary,
                ),

                const SizedBox(width: 9),

                Expanded(
                  child: Text(
                    'Keep the order status updated so '
                    'the buyer can follow the progress '
                    'of their purchase.',
                    style: ArtistTextStyles.small.copyWith(
                      fontSize: 10.5,
                      height: 1.4,
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

  // STATUS STEP

  bool _isStepCompleted(int step) {
    final index = _statusIndex(currentStatus);

    return index >= step;
  }

  int _statusIndex(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 0;

      case 'confirmed':
        return 1;

      case 'packed':
        return 2;

      case 'shipped':
        return 3;

      case 'out_for_delivery':
        return 4;

      case 'delivered':
        return 5;

      default:
        return 0;
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
    final Color color = active
        ? ArtistColors.primary
        : completed
        ? ArtistColors.success
        : ArtistColors.accent;

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
                  color: color.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                  border: active
                      ? Border.all(color: ArtistColors.primary, width: 1.5)
                      : null,
                ),
                child: Icon(
                  active
                      ? Icons.radio_button_checked_rounded
                      : completed
                      ? Icons.check_rounded
                      : icon,
                  size: 17,
                  color: color,
                ),
              ),

              if (!isLast)
                Container(
                  height: 37,
                  width: 2,
                  color: completed
                      ? ArtistColors.success.withValues(alpha: 0.38)
                      : ArtistColors.accent.withValues(alpha: 0.55),
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: ArtistTextStyles.bodyMedium.copyWith(
                          fontSize: 13.5,
                          fontWeight: active || completed
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: active || completed
                              ? ArtistColors.textPrimary
                              : ArtistColors.textSecondary,
                        ),
                      ),
                    ),

                    if (active)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: ArtistColors.primary.withValues(alpha: 0.09),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'CURRENT',
                          style: ArtistTextStyles.small.copyWith(
                            fontSize: 7,
                            fontWeight: FontWeight.w800,
                            color: ArtistColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 3),

                Text(
                  subtitle,
                  style: ArtistTextStyles.small.copyWith(fontSize: 10.5),
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
    final Color color = _statusColor(currentStatus);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 6,
            width: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),

          const SizedBox(width: 5),

          Text(
            _formatStatus(currentStatus),
            style: ArtistTextStyles.small.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return ArtistColors.success;

      case 'shipped':
      case 'out_for_delivery':
        return ArtistColors.primary;

      case 'packed':
        return ArtistColors.warning;

      case 'confirmed':
        return ArtistColors.info;

      case 'cancelled':
        return ArtistColors.error;

      case 'pending':
      default:
        return ArtistColors.primary;
    }
  }

  // PRODUCT

  Widget _buildProductSection() {
    return _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Item Sold', Icons.inventory_2_outlined),

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
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: SizedBox(
                    height: 78,
                    width: 78,
                    child: productImage.isEmpty
                        ? Container(
                            color: ArtistColors.light,
                            child: const Icon(
                              Icons.inventory_2_outlined,
                              size: 34,
                              color: ArtistColors.primary,
                            ),
                          )
                        : Image.network(
                            productImage,
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.low,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: ArtistColors.light,
                                  child: const Icon(
                                    Icons.broken_image_outlined,
                                    size: 32,
                                    color: ArtistColors.primary,
                                  ),
                                ),
                          ),
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
                        'Quantity sold: $quantity',
                        style: ArtistTextStyles.small.copyWith(fontSize: 11),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        unitPrice,
                        style: ArtistTextStyles.title.copyWith(
                          fontSize: 17,
                          color: ArtistColors.primary,
                          fontWeight: FontWeight.w800,
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

  // BUYER

  Widget _buildBuyerSection() {
    return _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Purchased By', Icons.person_outline_rounded),

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
                clipBehavior: Clip.antiAlias,
                child: buyerImage.isEmpty
                    ? const Icon(
                        Icons.person_rounded,
                        color: ArtistColors.primary,
                        size: 28,
                      )
                    : Image.network(
                        buyerImage,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.person_rounded,
                              color: ArtistColors.primary,
                              size: 28,
                            ),
                      ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      buyerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ArtistTextStyles.bodyMedium.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      buyerEmail.isNotEmpty
                          ? buyerEmail
                          : 'EcoLoop Buyer · #$buyerId',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ArtistTextStyles.small.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),

              OutlinedButton.icon(
                onPressed: _contactBuyer,
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 15),
                label: const Text('Contact'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ArtistColors.primary,
                  side: const BorderSide(color: ArtistColors.primary),
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openBuyerProfile,
              icon: const Icon(Icons.storefront_outlined, size: 18),
              label: Text(
                _isArtistBuyer ? 'View Artist Profile' : 'View Seller Profile',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ArtistColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: ArtistTextStyles.button.copyWith(fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 15),
          _contactRow(Icons.person_outline_rounded, 'Buyer ID', '#$buyerId'),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: ArtistColors.primary),

        const SizedBox(width: 9),

        Text(title, style: ArtistTextStyles.small.copyWith(fontSize: 11)),

        const Spacer(),

        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: ArtistTextStyles.bodyMedium.copyWith(fontSize: 11),
          ),
        ),
      ],
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
              color: ArtistColors.light.withValues(alpha: 0.60),
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
                        'Ship to buyer',
                        style: ArtistTextStyles.small.copyWith(fontSize: 10),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        shippingAddress,
                        style: ArtistTextStyles.bodyMedium.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'Buyer delivery address',
                        style: ArtistTextStyles.small.copyWith(
                          fontSize: 11,
                          height: 1.4,
                        ),
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
            ('${widget.order['deliveryMethod'] ?? 'standard'}')
                    .toLowerCase()
                    .contains('express')
                ? 'Express'
                : 'Standard',
          ),

          const SizedBox(height: 12),

          _detailRow(Icons.payments_outlined, 'Payment', payment),
        ],
      ),
    );
  }

  // EARNINGS

  Widget _buildEarningsSection() {
    final double serviceFee = totalAmountValue * 0.02;

    final double receiveAmount = totalAmountValue - serviceFee;

    return _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'Earnings Summary',
            Icons.account_balance_wallet_outlined,
          ),

          const SizedBox(height: 18),

          _moneyRow('Order value', totalAmount),

          _moneyRow('EcoLoop service fee', '- ${_formatCurrency(serviceFee)}'),

          _moneyRow('Delivery charges', 'Paid by buyer'),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Divider(color: ArtistColors.border),
          ),

          _moneyRow(
            'You will receive',
            _formatCurrency(receiveAmount),
            bold: true,
          ),

          const SizedBox(height: 6),

          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: ArtistColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 15,
                  color: ArtistColors.textSecondary,
                ),

                const SizedBox(width: 6),

                Expanded(
                  child: Text(
                    'Earnings will be credited after '
                    'the order is completed.',
                    style: ArtistTextStyles.small.copyWith(
                      fontSize: 10,
                      height: 1.4,
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

  Widget _moneyRow(String title, String value, {bool bold = false}) {
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

          _informationRow('Order date', orderDate),

          _informationRow('Last updated', updatedDate),

          _informationRow('Quantity', quantity),

          _informationRow('Unit price', unitPrice),

          _informationRow('Total amount', totalAmount),

          _informationRow('Payment', payment),

          _informationRow('Status', _formatStatus(currentStatus), isLast: true),
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
            width: 120,
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

  // SELLER PROTECTION

  Widget _buildSellerProtection() {
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
              Icons.verified_user_outlined,
              color: ArtistColors.primary,
              size: 24,
            ),

            const SizedBox(width: 11),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EcoLoop Seller Protection',
                    style: ArtistTextStyles.bodyMedium.copyWith(fontSize: 13),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    'Keep your order information and '
                    'shipment details updated for a '
                    'smooth and transparent sale.',
                    style: ArtistTextStyles.small.copyWith(
                      fontSize: 11,
                      height: 1.45,
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

  // COMPLETED

  Widget _buildCompletedMessage() {
    return _section(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: ArtistColors.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: ArtistColors.success.withValues(alpha: 0.24),
          ),
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
                'Sale completed successfully!',
                style: ArtistTextStyles.bodyMedium.copyWith(
                  fontSize: 13,
                  height: 1.5,
                  fontWeight: FontWeight.w700,
                  color: ArtistColors.success,
                ),
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
            onTap: _showSupportContact,
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
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          'Get help with this sale',
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
            color: Colors.black.withValues(alpha: 0.08),
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
                onPressed: _contactBuyer,
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 17),
                label: const Text('Contact Buyer'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ArtistColors.primary,
                  side: const BorderSide(color: ArtistColors.primary),
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                  textStyle: ArtistTextStyles.bodyMedium.copyWith(fontSize: 11),
                ),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: ElevatedButton.icon(
                onPressed: _openStatusPage,
                icon: const Icon(Icons.sync_alt_rounded, size: 17),
                label: const Text('Update Status'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ArtistColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                  textStyle: ArtistTextStyles.button.copyWith(fontSize: 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // OPEN STATUS PAGE

  void _openStatusPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SellingOrderStatus(order: widget.order),
      ),
    ).then((_) {
      if (!mounted) {
        return;
      }

      setState(() {});
    });
  }

  // CONTACT BUYER

  Future<Map<String, dynamic>> _loadFreshOrderContact() async {
    final merged = Map<String, dynamic>.from(widget.order);
    final hasEmail =
        (merged['buyerEmail'] ??
                merged['buyer_email'] ??
                merged['customerEmail'] ??
                merged['email'] ??
                '')
            .toString()
            .trim()
            .isNotEmpty;
    final hasPhone =
        (merged['buyerPhone'] ??
                merged['buyerMobile'] ??
                merged['customerPhone'] ??
                merged['phone'] ??
                '')
            .toString()
            .trim()
            .isNotEmpty;
    if (hasEmail && hasPhone) {
      return merged;
    }

    // Order details are returned from Code.gs using the buyer's actual Users or
    // Artists sheet row. This avoids inventing or hardcoding contact details.
    try {
      final result = await EcoLoopApi.instance.get('/orders/$orderId');
      if (result is Map) {
        merged.addAll(Map<String, dynamic>.from(result));
      }
    } catch (_) {
      // Keep the order data already on screen if this optional refresh fails.
    }
    return merged;
  }

  Future<void> _contactBuyer() async {
    final contact = await _loadFreshOrderContact();
    if (!mounted) return;
    String first(List<String> keys) {
      for (final key in keys) {
        final value = contact[key]?.toString().trim() ?? '';
        if (value.isNotEmpty) {
          return value;
        }
      }
      return '';
    }

    final email = first([
      'buyerEmail',
      'buyer_email',
      'customerEmail',
      'email',
    ]);
    final phone = first([
      'buyerPhone',
      'buyerMobile',
      'customerPhone',
      'phone',
    ]);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ArtistColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          'Contact Buyer',
          style: ArtistTextStyles.title.copyWith(
            color: ArtistColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              buyerName,
              style: ArtistTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (email.isNotEmpty) ...[
              Text(
                'Email address',
                style: ArtistTextStyles.small.copyWith(
                  color: ArtistColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                email,
                style: ArtistTextStyles.bodyMedium.copyWith(
                  color: ArtistColors.primary,
                ),
              ),
            ] else
              Text(
                'Buyer email is not available in the order response. Check that Code.gs returns buyerEmail from the Users/Artists sheet.',
                style: ArtistTextStyles.body.copyWith(
                  color: ArtistColors.textSecondary,
                ),
              ),
            if (phone.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Phone',
                style: ArtistTextStyles.small.copyWith(
                  color: ArtistColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(phone, style: ArtistTextStyles.bodyMedium),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Close', style: TextStyle(color: ArtistColors.primary)),
          ),
        ],
      ),
    );
  }

  /// The profile button in the "Purchased By" section belongs to the BUYER.
  /// Do not use the order's sellerType here: this order may have been sold by
  /// an artist while the buyer is an ordinary EcoLoop user.
  bool get _isArtistBuyer {
    final rawType =
        (widget.order['buyerType'] ??
                widget.order['buyer_type'] ??
                widget.order['buyerRole'] ??
                widget.order['buyer_role'] ??
                widget.order['buyerAccountType'] ??
                widget.order['buyer_account_type'] ??
                '')
            .toString()
            .trim()
            .toLowerCase()
            .replaceAll(RegExp(r'[\\s-]+'), '_');

    return const {'artist', 'remaker', 're_maker'}.contains(rawType);
  }

  String get _buyerProfileId {
    // buyerId is the Users.userId for a regular buyer. Only use artist-specific
    // ID fields when the order explicitly identifies the buyer as an artist.
    final dynamic rawId = _isArtistBuyer
        ? (widget.order['buyerArtistId'] ??
              widget.order['buyer_artist_id'] ??
              widget.order['artistBuyerId'] ??
              widget.order['artist_buyer_id'] ??
              widget.order['buyerId'] ??
              widget.order['buyer_id'])
        : (widget.order['buyerUserId'] ??
              widget.order['buyer_user_id'] ??
              widget.order['buyerId'] ??
              widget.order['buyer_id'] ??
              widget.order['customerId'] ??
              widget.order['customer_id']);

    return (rawId ?? '').toString().trim();
  }

  Future<void> _openBuyerProfile() async {
    final isArtist = _isArtistBuyer;
    final profileId = _buyerProfileId;

    if (profileId.isEmpty ||
        profileId == '0' ||
        profileId == '-' ||
        profileId.toLowerCase() == 'null') {
      _showMessage(
        isArtist
            ? 'Artist profile is unavailable because the buyer artist ID is missing.'
            : 'Seller profile is unavailable because the buyer user ID is missing.',
      );
      return;
    }

    final profileType = isArtist ? 'artist' : 'user';

    try {
      final result = await EcoLoopApi.instance.get(
        '/public/seller/$profileType/$profileId/profile',
      );
      if (!mounted) {
        return;
      }

      final root = result is Map
          ? Map<String, dynamic>.from(result)
          : <String, dynamic>{};
      final profileValue = root['seller'];
      final profile = profileValue is Map
          ? Map<String, dynamic>.from(profileValue)
          : root;

      if (profile.isEmpty) {
        _showMessage(
          isArtist
              ? 'Artist profile was not returned by the backend.'
              : 'Seller profile was not returned by the backend.',
        );
        return;
      }

      if (isArtist) {
        await Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => ArtistProfile(artist: profile)),
        );
      } else {
        await Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => SellerProfile(seller: profile)),
        );
      }
    } catch (error) {
      if (mounted) {
        _showMessage(
          'Could not open ${isArtist ? 'artist' : 'seller'} profile: '
          '${error.toString().replaceFirst('Exception: ', '')}',
        );
      }
    }
  }

  void _showSupportContact() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ArtistColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          'EcoLoop Support',
          style: ArtistTextStyles.title.copyWith(
            color: ArtistColors.textPrimary,
          ),
        ),
        content: Text(
          'Need help with sale #$orderId? Please contact EcoLoop support '
          'through the support channel provided in the app. Keep your order '
          'ID ready so the team can assist you.',
          style: ArtistTextStyles.body.copyWith(height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Close', style: TextStyle(color: ArtistColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ArtistColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _bottomSheetOption(
                icon: Icons.receipt_long_outlined,
                title: 'Sale Receipt',
                onTap: () {
                  Navigator.pop(sheetContext);

                  _showMessage('Sale receipt will be available later.');
                },
              ),

              _bottomSheetOption(
                icon: Icons.share_outlined,
                title: 'Share Sale',
                onTap: () {
                  Navigator.pop(sheetContext);

                  _showMessage('Sale sharing will be connected later.');
                },
              ),

              _bottomSheetOption(
                icon: Icons.help_outline_rounded,
                title: 'Get Help',
                onTap: () {
                  Navigator.pop(sheetContext);

                  _showMessage('Seller support will be connected later.');
                },
              ),

              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

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
          color: ArtistColors.light,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: ArtistColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: ArtistTextStyles.bodyMedium.copyWith(fontSize: 14),
      ),
      onTap: onTap,
    );
  }

  // COMMON SECTION TITLE

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: ArtistColors.primary),

        const SizedBox(width: 8),

        Text(
          title,
          style: ArtistTextStyles.title.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // DETAIL ROW

  Widget _detailRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 19, color: ArtistColors.primary),

        const SizedBox(width: 10),

        Text(title, style: ArtistTextStyles.small.copyWith(fontSize: 12)),

        const Spacer(),

        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: ArtistTextStyles.bodyMedium.copyWith(fontSize: 12),
          ),
        ),
      ],
    );
  }

  // SECTION CONTAINER

  Widget _section({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      color: ArtistColors.surface,
      child: child,
    );
  }

  // HELPERS

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatCurrency(double value) {
    return '₹${value.toStringAsFixed(0)}';
  }

  /// Formats timestamps returned from Google Sheets as readable Indian time.
  /// ISO values ending in Z are UTC and are converted to Asia/Kolkata (UTC+5:30).
  /// Sheet values already stored as 'yyyy-MM-dd HH:mm:ss' are treated as IST.
  String _formatSheetDateTime(dynamic value) {
    final raw = (value ?? '').toString().trim();
    if (raw.isEmpty || raw == '-') {
      return '-';
    }

    DateTime? parsed;
    final sheetFormat = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2})(?::(\d{2}))?$',
    ).firstMatch(raw);

    if (sheetFormat != null) {
      // Apps Script's yyyy-MM-dd HH:mm:ss format is already in IST.
      parsed = DateTime(
        int.parse(sheetFormat.group(1)!),
        int.parse(sheetFormat.group(2)!),
        int.parse(sheetFormat.group(3)!),
        int.parse(sheetFormat.group(4)!),
        int.parse(sheetFormat.group(5)!),
        int.parse(sheetFormat.group(6) ?? '0'),
      );
    } else {
      parsed = DateTime.tryParse(raw);
      if (parsed != null) {
        if (RegExp(
          r'(Z|[+-]\d{2}:?\d{2})$',
          caseSensitive: false,
        ).hasMatch(raw)) {
          // Normalize explicit timezone timestamps to UTC, then apply IST.
          parsed = parsed.toUtc().add(const Duration(hours: 5, minutes: 30));
        }
      }
    }

    if (parsed == null) {
      return raw;
    }

    const months = <String>[
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
    final day = parsed.day.toString().padLeft(2, '0');
    final hour12 = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
    final minute = parsed.minute.toString().padLeft(2, '0');
    final period = parsed.hour >= 12 ? 'PM' : 'AM';
    final time = '$hour12:$minute $period';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(parsed.year, parsed.month, parsed.day);
    final difference = today.difference(dateOnly).inDays;

    if (difference == 0) {
      return 'Today, $time';
    }
    if (difference == 1) {
      return 'Yesterday, $time';
    }

    return '$day ${months[parsed.month - 1]} ${parsed.year}, $time';
  }

  String _formatStatus(String value) {
    if (value.trim().isEmpty) {
      return '-';
    }

    return value
        .split('_')
        .map(
          (word) => word.isEmpty
              ? ''
              : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join(' ');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: ArtistColors.textPrimary,
        ),
      );
  }
}
