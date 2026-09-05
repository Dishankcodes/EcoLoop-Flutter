import 'package:flutter/material.dart';

import '../../app_theme/app_colors.dart';

class SellingOrderDetails extends StatefulWidget {
  final Map<String, dynamic> order;

  const SellingOrderDetails({super.key, required this.order});

  @override
  State<SellingOrderDetails> createState() => _SellingOrderDetailsState();
}

class _SellingOrderDetailsState extends State<SellingOrderDetails> {
  late String _status;

  @override
  void initState() {
    super.initState();

    _status = widget.order['status']?.toString() ?? 'New Order';
  }

  // ============================================================
  // DATA
  // ============================================================

  String get productName =>
      widget.order['product']?.toString() ?? 'Wooden Study Table';

  String get price => widget.order['price']?.toString() ?? '₹2,500';

  String get orderId => widget.order['orderId']?.toString() ?? '#ECO-ORD-10021';

  String get orderDate => widget.order['date']?.toString() ?? '01 Sep 2026';

  // Supports both old and new map structures.
  String get buyerName =>
      widget.order['buyerName']?.toString() ??
      widget.order['buyer']?.toString() ??
      'Rahul Sharma';

  String get quantity => widget.order['quantity']?.toString() ?? '1';

  String get payment => widget.order['payment']?.toString() ?? 'Paid';

  String get deliveryMethod =>
      widget.order['deliveryMethod']?.toString() ?? 'EcoLoop Delivery';

  IconData get productIcon =>
      widget.order['icon'] as IconData? ?? Icons.inventory_2_outlined;

  bool get isCompleted => _status == 'Completed';

  bool get isCancelled => _status == 'Cancelled';

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: isCompleted || isCancelled ? 30 : 105),
        child: Column(
          children: [
            _buildSaleHeader(),

            if (isCancelled) _buildCancelledBanner(),

            if (!isCancelled) _buildStatusSection(),

            _buildProductSection(),

            _buildBuyerSection(),

            _buildDeliverySection(),

            _buildEarningsSection(),

            _buildOrderInformation(),

            _buildSellerProtection(),

            if (isCompleted) _buildCompletedMessage(),

            _buildHelpSection(),
          ],
        ),
      ),
      bottomNavigationBar: isCompleted || isCancelled
          ? null
          : _buildBottomBar(),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

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
        'Sale Details',
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

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildSaleHeader() {
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
              Icons.storefront_outlined,
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
                  'Sale received',
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

  // ============================================================
  // CANCELLED
  // ============================================================

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
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cancel_outlined, color: AppColors.error, size: 23),
          SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sale Cancelled',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'This sale is no longer active.',
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
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  Widget _buildStatusSection() {
    return _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Sale Status',
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
            icon: Icons.shopping_bag_rounded,
            title: 'Order Received',
            subtitle: 'Someone purchased your item',
            completed: _isStepCompleted(1),
            active: _status == 'New Order',
          ),

          _timelineItem(
            icon: Icons.inventory_2_rounded,
            title: 'Preparing Item',
            subtitle: 'Get the item ready for delivery',
            completed: _isStepCompleted(2),
            active: _status == 'Processing',
          ),

          _timelineItem(
            icon: Icons.local_shipping_rounded,
            title: 'Shipped',
            subtitle: 'Item has been handed over for delivery',
            completed: _isStepCompleted(3),
            active: _status == 'Shipped',
          ),

          _timelineItem(
            icon: Icons.check_circle_rounded,
            title: 'Sale Completed',
            subtitle: 'Buyer received the item',
            completed: _isStepCompleted(4),
            active: _status == 'Completed',
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
                    'Shipment tracking will be available '
                    'here once delivery tracking is connected.',
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

  bool _isStepCompleted(int step) {
    switch (_status) {
      case 'New Order':
        return step <= 1;

      case 'Processing':
        return step <= 2;

      case 'Shipped':
        return step <= 3;

      case 'Completed':
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

  Widget _statusChip() {
    Color color;

    switch (_status) {
      case 'Completed':
        color = AppColors.success;
        break;

      case 'Shipped':
        color = AppColors.primary;
        break;

      case 'Processing':
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

  // ============================================================
  // PRODUCT
  // ============================================================

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
                        'Quantity sold: $quantity',
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

  // ============================================================
  // BUYER
  // ============================================================

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
                  color: AppColors.light,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      buyerName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'EcoLoop Buyer',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              OutlinedButton.icon(
                onPressed: _contactBuyer,
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 15),
                label: const Text('Contact'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
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

          _contactRow(Icons.phone_outlined, 'Phone', '+91 98XXXXXX45'),

          const SizedBox(height: 11),

          _contactRow(Icons.email_outlined, 'Email', 'buyer@example.com'),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 9),
        Text(
          title,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DELIVERY
  // ============================================================

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
                        'Ship to buyer',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Buyer delivery address',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Delivery address will be shown '
                        'here for the seller.',
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

          _detailRow(Icons.payments_outlined, 'Payment', payment),
        ],
      ),
    );
  }

  // ============================================================
  // EARNINGS
  // ============================================================

  Widget _buildEarningsSection() {
    return _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'Earnings Summary',
            Icons.account_balance_wallet_outlined,
          ),

          const SizedBox(height: 18),

          _moneyRow('Item price', price),

          _moneyRow('EcoLoop service fee', '- ₹50'),

          _moneyRow('Delivery charges', 'Paid by buyer'),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 5),
            child: Divider(),
          ),

          _moneyRow('You will receive', '₹1,150', bold: true),

          const SizedBox(height: 6),

          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 15,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Earnings will be credited after '
                    'the order is completed.',
                    style: TextStyle(
                      fontSize: 10,
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

  Widget _moneyRow(String title, String value, {bool bold = false}) {
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

  // ============================================================
  // ORDER INFORMATION
  // ============================================================

  Widget _buildOrderInformation() {
    return _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Order Information', Icons.info_outline_rounded),

          const SizedBox(height: 18),

          _informationRow('Order ID', orderId),

          _informationRow('Order date', orderDate),

          _informationRow('Payment', payment),

          _informationRow('Status', _status, isLast: true),
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

  // ============================================================
  // SELLER PROTECTION
  // ============================================================

  Widget _buildSellerProtection() {
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
            Icon(
              Icons.verified_user_outlined,
              color: AppColors.primary,
              size: 24,
            ),
            SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EcoLoop Seller Protection',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Keep your order information and '
                    'shipment details updated for a smooth sale.',
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

  // ============================================================
  // COMPLETED MESSAGE
  // ============================================================

  Widget _buildCompletedMessage() {
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
              Icons.account_balance_wallet_outlined,
              color: AppColors.success,
              size: 23,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Sale completed successfully. '
                'Your earnings will be credited according '
                'to EcoLoop payout terms.',
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

  // ============================================================
  // HELP
  // ============================================================

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
                          'Get help with this sale',
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

  // ============================================================
  // BOTTOM ACTIONS
  // ============================================================

  Widget _buildBottomBar() {
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
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _contactBuyer,
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 17),
                label: const Text('Contact Buyer'),
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

            Expanded(
              child: ElevatedButton.icon(
                onPressed: _updateStatus,
                icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                label: Text(_nextActionLabel()),
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

  String _nextActionLabel() {
    switch (_status) {
      case 'New Order':
        return 'Start Processing';

      case 'Processing':
        return 'Mark as Shipped';

      case 'Shipped':
        return 'Complete Sale';

      default:
        return 'Update Status';
    }
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  void _updateStatus() {
    switch (_status) {
      case 'New Order':
        setState(() {
          _status = 'Processing';
        });

        _showMessage('Order moved to Processing.');
        break;

      case 'Processing':
        setState(() {
          _status = 'Shipped';
        });

        _showMessage('Order marked as Shipped.');
        break;

      case 'Shipped':
        setState(() {
          _status = 'Completed';
        });

        _showMessage('Sale marked as Completed.');
        break;
    }
  }

  void _contactBuyer() {
    _showMessage('Buyer messaging will be connected later.');
  }

  // ============================================================
  // MORE OPTIONS
  // ============================================================

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

  // ============================================================
  // COMMON
  // ============================================================

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

  Widget _section({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      color: AppColors.surface,
      child: child,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}
