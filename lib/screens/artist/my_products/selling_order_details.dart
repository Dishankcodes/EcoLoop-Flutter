import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import 'selling_order_status.dart';

class SellingOrderDetails extends StatefulWidget {
  final Map<String, dynamic> order;

  const SellingOrderDetails({super.key, required this.order});

  @override
  State<SellingOrderDetails> createState() => _SellingOrderDetailsState();
}

class _SellingOrderDetailsState extends State<SellingOrderDetails> {
  // ==========================================================
  // DATA
  // ==========================================================

  String get productName {
    return widget.order['productTitle']?.toString() ??
        widget.order['product']?.toString() ??
        'Product';
  }

  String get orderId {
    return widget.order['orderId']?.toString() ?? '-';
  }

  String get orderDate {
    return widget.order['createdAt']?.toString() ?? '-';
  }

  String get updatedDate {
    return widget.order['updatedAt']?.toString() ?? '-';
  }

  String get buyerId {
    return widget.order['buyerId']?.toString() ?? '-';
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
    final value = widget.order['shippingAddress']?.toString();

    if (value == null || value.trim().isEmpty) {
      return 'Delivery address';
    }

    return value;
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

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtistColors.background,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
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

            if (!isCancelled) _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // APP BAR
  // ==========================================================

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

  // ==========================================================
  // SALE HEADER
  // ==========================================================

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

  // ==========================================================
  // CANCELLED
  // ==========================================================

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

  // ==========================================================
  // STATUS SECTION
  // ==========================================================

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
              color: ArtistColors.light.withOpacity(0.65),
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

  // ==========================================================
  // STATUS STEP
  // ==========================================================

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
                  color: color.withOpacity(0.10),
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
                      ? ArtistColors.success.withOpacity(0.38)
                      : ArtistColors.accent.withOpacity(0.55),
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
                          color: ArtistColors.primary.withOpacity(0.09),
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

  // ==========================================================
  // STATUS CHIP
  // ==========================================================

  Widget _statusChip() {
    final Color color = _statusColor(currentStatus);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
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

  // ==========================================================
  // PRODUCT
  // ==========================================================

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
                Container(
                  height: 78,
                  width: 78,
                  decoration: BoxDecoration(
                    color: ArtistColors.light,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
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

  // ==========================================================
  // BUYER
  // ==========================================================

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
                child: const Icon(
                  Icons.person_rounded,
                  color: ArtistColors.primary,
                  size: 28,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buyer #$buyerId',
                      style: ArtistTextStyles.bodyMedium.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'EcoLoop Buyer',
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

          const SizedBox(height: 18),

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

  // ==========================================================
  // DELIVERY
  // ==========================================================

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
            'Delivery',
            'EcoLoop Delivery',
          ),

          const SizedBox(height: 12),

          _detailRow(Icons.payments_outlined, 'Payment', payment),
        ],
      ),
    );
  }

  // ==========================================================
  // EARNINGS
  // ==========================================================

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

  // ==========================================================
  // ORDER INFORMATION
  // ==========================================================

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

  // ==========================================================
  // SELLER PROTECTION
  // ==========================================================

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

  // ==========================================================
  // COMPLETED
  // ==========================================================

  Widget _buildCompletedMessage() {
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
              Icons.account_balance_wallet_outlined,
              color: ArtistColors.success,
              size: 23,
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Text(
                'Sale completed successfully. '
                'Your earnings will be credited according '
                'to EcoLoop payout terms.',
                style: ArtistTextStyles.small.copyWith(
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // HELP
  // ==========================================================

  Widget _buildHelpSection() {
    return _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Need Help?', Icons.support_agent_outlined),

          const SizedBox(height: 13),

          InkWell(
            onTap: () {
              _showMessage('Seller support will be connected later.');
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

  // ==========================================================
  // BOTTOM BAR
  // ==========================================================

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

  // ==========================================================
  // OPEN STATUS PAGE
  // ==========================================================

  void _openStatusPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SellingOrderStatus(order: widget.order),
      ),
    ).then((_) {
      if (!mounted) return;

      setState(() {});
    });
  }

  // ==========================================================
  // CONTACT BUYER
  // ==========================================================

  void _contactBuyer() {
    _showMessage('Buyer messaging will be connected later.');
  }

  // ==========================================================
  // MORE OPTIONS
  // ==========================================================

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

  // ==========================================================
  // COMMON SECTION TITLE
  // ==========================================================

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

  // ==========================================================
  // DETAIL ROW
  // ==========================================================

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

  // ==========================================================
  // SECTION CONTAINER
  // ==========================================================

  Widget _section({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      color: ArtistColors.surface,
      child: child,
    );
  }

  // ==========================================================
  // HELPERS
  // ==========================================================

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatCurrency(double value) {
    return '₹${value.toStringAsFixed(0)}';
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
