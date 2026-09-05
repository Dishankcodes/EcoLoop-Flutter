import 'package:flutter/material.dart';

import '../../../app_theme/app_colors.dart';

class OrderTracking extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderTracking({super.key, required this.order});

  @override
  State<OrderTracking> createState() => _OrderTrackingState();
}

class _OrderTrackingState extends State<OrderTracking> {
  // ============================================================
  // DATA
  // ============================================================

  String get productName =>
      widget.order['product']?.toString() ?? 'Wooden Study Table';

  String get orderId => widget.order['orderId']?.toString() ?? '#ECO-ORD-10021';

  String get orderDate => widget.order['date']?.toString() ?? '01 Sep 2026';

  String get price => widget.order['price']?.toString() ?? '₹2,500';

  String get quantity => widget.order['quantity']?.toString() ?? '1';

  String get currentStatus => widget.order['status']?.toString() ?? 'Shipped';

  IconData get productIcon =>
      widget.order['icon'] as IconData? ?? Icons.inventory_2_outlined;

  String get expectedDelivery =>
      widget.order['expectedDelivery']?.toString() ?? '03 Sep 2026';

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 30),
        child: Column(
          children: [
            _buildTrackingHeader(),
            _buildCurrentStatus(),
            _buildTrackingTimeline(),
            _buildProductCard(),
            _buildDeliveryCard(),
            _buildOrderInformation(),
            _buildHelpCard(),
          ],
        ),
      ),
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
        'Track Order',
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
  // TRACKING HEADER
  // ============================================================

  Widget _buildTrackingHeader() {
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
      child: Column(
        children: [
          Container(
            height: 76,
            width: 76,
            decoration: BoxDecoration(
              color: AppColors.light,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.accent.withOpacity(0.55),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.local_shipping_rounded,
              size: 37,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 14),

          const Text(
            'Your order is on the way',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Order $orderId',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 15),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 7,
                  width: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  currentStatus,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
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
  // CURRENT STATUS
  // ============================================================

  Widget _buildCurrentStatus() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.accent.withOpacity(0.45)),
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.primary,
              size: 25,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimated delivery',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '03 September 2026',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.calendar_today_outlined,
            size: 19,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TRACKING TIMELINE
  // ============================================================

  Widget _buildTrackingTimeline() {
    return _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tracking Updates',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 21),

          _buildTimelineItem(
            icon: Icons.shopping_bag_rounded,
            title: 'Order Placed',
            subtitle: 'Your order was successfully placed',
            date: orderDate,
            completed: true,
          ),

          _buildTimelineItem(
            icon: Icons.verified_rounded,
            title: 'Order Confirmed',
            subtitle: 'Seller confirmed your order',
            date: '01 Sep • 10:30 AM',
            completed: true,
          ),

          _buildTimelineItem(
            icon: Icons.inventory_2_rounded,
            title: 'Item Packed',
            subtitle: 'Seller packed your item',
            date: '01 Sep • 04:15 PM',
            completed: true,
          ),

          _buildTimelineItem(
            icon: Icons.local_shipping_rounded,
            title: 'Shipped',
            subtitle: 'Your package is on the way',
            date: '02 Sep • 09:20 AM',
            completed: _isStatusAtLeast('Shipped'),
            active: currentStatus == 'Shipped',
          ),

          _buildTimelineItem(
            icon: Icons.delivery_dining_rounded,
            title: 'Out for Delivery',
            subtitle: 'Package will reach you soon',
            date: 'Expected on delivery day',
            completed: _isStatusAtLeast('Out for Delivery'),
            active: currentStatus == 'Out for Delivery',
          ),

          _buildTimelineItem(
            icon: Icons.home_rounded,
            title: 'Delivered',
            subtitle: 'Package delivered successfully',
            date: 'Awaiting delivery',
            completed: currentStatus == 'Delivered',
            active: currentStatus == 'Delivered',
            isLast: true,
          ),
        ],
      ),
    );
  }

  bool _isStatusAtLeast(String status) {
    const statuses = [
      'Confirmed',
      'Packed',
      'Shipped',
      'Out for Delivery',
      'Delivered',
    ];

    final currentIndex = statuses.indexOf(currentStatus);
    final targetIndex = statuses.indexOf(status);

    if (currentIndex == -1 || targetIndex == -1) {
      return false;
    }

    return currentIndex >= targetIndex;
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String date,
    required bool completed,
    bool active = false,
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
          width: 34,
          child: Column(
            children: [
              Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.11),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.20)),
                ),
                child: Icon(icon, size: 17, color: color),
              ),

              if (!isLast)
                Container(
                  width: 2,
                  height: 47,
                  margin: const EdgeInsets.only(top: 2),
                  color: completed
                      ? AppColors.success.withOpacity(0.35)
                      : AppColors.accent.withOpacity(0.55),
                ),
            ],
          ),
        ),

        const SizedBox(width: 13),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: completed || active
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: completed || active
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),

                          if (active) ...[
                            const SizedBox(width: 7),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.09),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'CURRENT',
                                style: TextStyle(
                                  fontSize: 7,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 4),

                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 10.5,
                          height: 1.4,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Text(
                  date,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: completed ? FontWeight.w600 : FontWeight.w400,
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

  // ============================================================
  // PRODUCT CARD
  // ============================================================

  Widget _buildProductCard() {
    return _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Your Item', Icons.shopping_bag_outlined),

          const SizedBox(height: 15),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accent.withOpacity(0.30)),
            ),
            child: Row(
              children: [
                Container(
                  height: 72,
                  width: 72,
                  decoration: BoxDecoration(
                    color: AppColors.light,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(productIcon, size: 35, color: AppColors.primary),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'Quantity: $quantity',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        price,
                        style: const TextStyle(
                          fontSize: 15,
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
  // DELIVERY CARD
  // ============================================================

  Widget _buildDeliveryCard() {
    return _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Delivery Address', Icons.location_on_outlined),

          const SizedBox(height: 15),

          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.light.withOpacity(0.60),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 38,
                  width: 38,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.home_outlined,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(width: 10),

                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Home',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      SizedBox(height: 5),

                      Text(
                        'Dishank Prajapati',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      SizedBox(height: 3),

                      Text(
                        '28/4 Jagdish Apartment, '
                        'Viratnagar Canal Road, Ahmedabad',
                        style: TextStyle(
                          fontSize: 10.5,
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

          const SizedBox(height: 15),

          Row(
            children: [
              const Icon(
                Icons.local_shipping_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'EcoLoop Standard Delivery',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                expectedDelivery,
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
  // ORDER INFORMATION
  // ============================================================

  Widget _buildOrderInformation() {
    return _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Order Information', Icons.receipt_long_outlined),

          const SizedBox(height: 18),

          _infoRow('Order ID', orderId),

          _infoRow('Order Date', orderDate),

          _infoRow('Quantity', quantity),

          _infoRow('Total Paid', price),

          _infoRow('Current Status', currentStatus, isLast: true),
        ],
      ),
    );
  }

  Widget _infoRow(String title, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 13),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 11.5,
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
  // HELP
  // ============================================================

  Widget _buildHelpCard() {
    return _section(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.light,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accent.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                color: AppColors.primary,
                size: 23,
              ),
            ),

            const SizedBox(width: 11),

            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Need help with your order?',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Our support team is here to help.',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            IconButton(
              onPressed: () {
                _showMessage('Order support will be connected later.');
              },
              icon: const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.primary,
                size: 19,
              ),
            ),
          ],
        ),
      ),
    );
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
              _sheetOption(
                icon: Icons.share_outlined,
                title: 'Share Tracking',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showMessage('Sharing will be connected later.');
                },
              ),
              _sheetOption(
                icon: Icons.receipt_long_outlined,
                title: 'View Order Details',
                onTap: () {
                  Navigator.pop(sheetContext);
                },
              ),
              _sheetOption(
                icon: Icons.help_outline_rounded,
                title: 'Get Help',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showMessage('Support will be connected later.');
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _sheetOption({
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

  Widget _section({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      color: AppColors.surface,
      child: child,
    );
  }

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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}
