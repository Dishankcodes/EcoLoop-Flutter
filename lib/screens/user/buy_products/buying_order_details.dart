import 'package:flutter/material.dart';

import '../../../app_theme/app_colors.dart';
import 'order_tracking.dart';

class BuyingOrderDetails extends StatefulWidget {
  final Map<String, dynamic> order;

  const BuyingOrderDetails({super.key, required this.order});

  @override
  State<BuyingOrderDetails> createState() => _BuyingOrderDetailsState();
}

class _BuyingOrderDetailsState extends State<BuyingOrderDetails> {
  late String _status;

  @override
  void initState() {
    super.initState();

    _status = widget.order['status']?.toString() ?? 'Confirmed';
  }

  // ============================================================
  // DATA
  // ============================================================

  String get productName =>
      widget.order['product']?.toString() ?? 'Wooden Study Table';

  String get price => widget.order['price']?.toString() ?? '₹2,500';

  String get orderId => widget.order['orderId']?.toString() ?? '#ECO-ORD-10021';

  String get orderDate => widget.order['date']?.toString() ?? '01 Sep 2026';

  String get sellerName =>
      widget.order['seller']?.toString() ??
      widget.order['sellerName']?.toString() ??
      'Rahul Sharma';

  String get quantity => widget.order['quantity']?.toString() ?? '1';

  String get payment => widget.order['payment']?.toString() ?? 'Paid Online';

  String get deliveryMethod =>
      widget.order['deliveryMethod']?.toString() ?? 'EcoLoop Delivery';

  String get expectedDate =>
      widget.order['expectedDelivery']?.toString() ?? '03 Sep 2026';

  IconData get productIcon =>
      widget.order['icon'] as IconData? ?? Icons.inventory_2_outlined;

  bool get isCancelled => _status == 'Cancelled';

  bool get isDelivered => _status == 'Delivered';

  // ============================================================
  // BUILD
  // ============================================================

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

  // ============================================================
  // ORDER HEADER
  // ============================================================

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

  // ============================================================
  // CANCELLED BANNER
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
                  'Order Cancelled',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'This order is no longer active.',
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

  // ============================================================
  // PRODUCT
  // ============================================================

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

  // ============================================================
  // SELLER
  // ============================================================

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
                        '28/4 Jagdish Apartment, '
                        'Viratnagar Canal Road',
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

  // ============================================================
  // PAYMENT / BILL
  // ============================================================

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

          _informationRow('Order placed', orderDate),

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

  // ============================================================
  // ECOLOOP PROTECTION
  // ============================================================

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
                    'Your purchase is protected through '
                    'the EcoLoop order process.',
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
  // DELIVERED MESSAGE
  // ============================================================

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
                'Your order was delivered successfully. '
                'We hope you enjoy your item! 🌱',
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
              _showMessage('Order support will be connected later.');
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

  // ============================================================
  // BOTTOM BAR
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
                onPressed: isDelivered ? _buyAgain : _cancelOrder,
                icon: Icon(
                  isDelivered ? Icons.refresh_rounded : Icons.cancel_outlined,
                  size: 17,
                ),
                label: Text(isDelivered ? 'Buy Again' : 'Cancel Order'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDelivered
                      ? AppColors.primary
                      : AppColors.error,
                  side: BorderSide(
                    color: isDelivered ? AppColors.primary : AppColors.error,
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

  // ============================================================
  // ACTIONS
  // ============================================================

  void _trackOrder() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OrderTracking(order: widget.order)),
    );
  }

  void _cancelOrder() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Cancel Order?',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: const Text(
            'Are you sure you want to cancel this order?',
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Keep Order'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                setState(() {
                  _status = 'Cancelled';
                });

                _showMessage('Order cancelled.');
              },
              child: const Text(
                'Cancel Order',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _buyAgain() {
    _showMessage('Buy Again will be connected to the product flow later.');
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
                  _showMessage('Order support will be connected later.');
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
