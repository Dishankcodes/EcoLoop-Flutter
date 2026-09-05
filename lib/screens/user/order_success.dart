import 'package:flutter/material.dart';

import '../../app_theme/app_colors.dart';
import '../../app_theme/app_text_styles.dart';

class OrderSuccess extends StatefulWidget {
  final String? orderId;
  final double totalAmount;
  final int itemCount;
  final String? paymentMethod;
  final Map<String, dynamic>? address;
  final String deliveryMethod;
  final String estimatedDelivery;

  const OrderSuccess({
    super.key,
    this.orderId,
    this.totalAmount = 0,
    this.itemCount = 1,
    this.paymentMethod,
    this.address,
    this.deliveryMethod = 'Standard Delivery',
    this.estimatedDelivery = '5 - 7 business days',
  });

  @override
  State<OrderSuccess> createState() => _OrderSuccessState();
}

class _OrderSuccessState extends State<OrderSuccess>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String get _displayOrderId {
    if (widget.orderId != null && widget.orderId!.trim().isNotEmpty) {
      return widget.orderId!;
    }

    return 'ECO-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
  }

  String _formatPrice(double value) {
    return '₹${value.round()}';
  }

  String _addressText() {
    final address = widget.address;

    if (address == null || address.isEmpty) {
      return 'Your saved delivery address';
    }

    final parts = <String>[];

    void addValue(dynamic value) {
      if (value == null) return;

      final text = value.toString().trim();

      if (text.isNotEmpty) {
        parts.add(text);
      }
    }

    addValue(address['name']);
    addValue(address['address']);
    addValue(address['addressLine']);
    addValue(address['area']);
    addValue(address['city']);
    addValue(address['state']);
    addValue(address['pincode']);
    addValue(address['postalCode']);

    if (parts.isEmpty) {
      return 'Your saved delivery address';
    }

    return parts.join(', ');
  }

  void _continueShopping() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _viewOrder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order details page will be connected next.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildSuccessAnimation(),
                      const SizedBox(height: 24),
                      _buildSuccessMessage(),
                      const SizedBox(height: 22),
                      _buildOrderCard(),
                      const SizedBox(height: 14),
                      _buildDeliveryCard(),
                      const SizedBox(height: 14),
                      _buildEcoMessage(),
                      const SizedBox(height: 24),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 18, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.close_rounded),
            color: AppColors.textPrimary,
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Text(
              'Order Confirmation',
              style: AppTextStyles.title.copyWith(fontSize: 20),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.eco_outlined, size: 15, color: AppColors.primary),
                SizedBox(width: 4),
                Text(
                  'EcoLoop',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessAnimation() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 156,
            height: 156,
            decoration: BoxDecoration(
              color: AppColors.light.withOpacity(0.55),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 122,
            height: 122,
            decoration: BoxDecoration(
              color: AppColors.light,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accent, width: 2),
            ),
          ),
          Container(
            width: 92,
            height: 92,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 55,
            ),
          ),
          Positioned(
            top: 12,
            right: 25,
            child: _sparkle(Icons.auto_awesome, 22),
          ),
          Positioned(
            bottom: 16,
            left: 24,
            child: _sparkle(Icons.eco_outlined, 20),
          ),
          Positioned(top: 48, left: 6, child: _sparkle(Icons.star_rounded, 15)),
        ],
      ),
    );
  }

  Widget _sparkle(IconData icon, double size) {
    return Icon(icon, color: AppColors.secondary, size: size);
  }

  Widget _buildSuccessMessage() {
    return Column(
      children: [
        Text(
          'Order Placed Successfully!',
          style: AppTextStyles.heading.copyWith(fontSize: 25),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 9),
        Text(
          'Thank you for choosing EcoLoop. Your order is on its way to becoming a part of a more sustainable cycle.',
          style: AppTextStyles.body.copyWith(fontSize: 13.5, height: 1.55),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 13),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.light,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.success,
                size: 16,
              ),
              SizedBox(width: 6),
              Text(
                'Order confirmed',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard() {
    return _sectionCard(
      child: Column(
        children: [
          Row(
            children: [
              _iconBox(Icons.receipt_long_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Order Details',
                  style: AppTextStyles.title.copyWith(fontSize: 17),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 14),
          _infoRow('Order ID', _displayOrderId, valueBold: true),
          const SizedBox(height: 11),
          _infoRow(
            'Items',
            '${widget.itemCount} item${widget.itemCount == 1 ? '' : 's'}',
          ),
          const SizedBox(height: 11),
          _infoRow('Payment', widget.paymentMethod ?? 'Payment completed'),
          const SizedBox(height: 11),
          _infoRow(
            'Total Amount',
            _formatPrice(widget.totalAmount),
            valueColor: AppColors.primary,
            valueBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard() {
    return _sectionCard(
      child: Column(
        children: [
          Row(
            children: [
              _iconBox(Icons.local_shipping_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Delivery Details',
                  style: AppTextStyles.title.copyWith(fontSize: 17),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 14),
          _deliveryRow(
            Icons.calendar_today_outlined,
            'Estimated Delivery',
            widget.estimatedDelivery,
          ),
          const SizedBox(height: 13),
          _deliveryRow(
            Icons.local_shipping_outlined,
            'Delivery Method',
            widget.deliveryMethod,
          ),
          const SizedBox(height: 13),
          _deliveryRow(
            Icons.location_on_outlined,
            'Delivering To',
            _addressText(),
          ),
        ],
      ),
    );
  }

  Widget _deliveryRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.secondary, size: 19),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.caption.copyWith(fontSize: 11)),
              const SizedBox(height: 3),
              Text(
                value,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEcoMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withOpacity(0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.eco_rounded,
              color: AppColors.primary,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You made an eco-friendly choice!',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'By reusing products, you are helping reduce waste and giving useful items a second life.',
                  style: AppTextStyles.caption.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _viewOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined, size: 19),
                SizedBox(width: 8),
                Text(
                  'View Order',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 11),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: _continueShopping,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag_outlined, size: 19),
                SizedBox(width: 8),
                Text(
                  'Continue Shopping',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  Widget _iconBox(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: AppColors.primary, size: 21),
    );
  }

  Widget _infoRow(
    String title,
    String value, {
    Color? valueColor,
    bool valueBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.body.copyWith(fontSize: 13)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTextStyles.body.copyWith(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: 13,
              fontWeight: valueBold ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
