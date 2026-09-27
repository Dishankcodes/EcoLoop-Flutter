import 'package:ecoloop/screens/artist/buy_products/buying_orders.dart';
import 'package:ecoloop/screens/artist/buy_products/marketplace.dart';
import 'package:ecoloop/screens/artist/profile/profile.dart';
import 'package:ecoloop/widgets/artist_bottom_navigation.dart';
import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import '../artist_dashboard.dart';
import '../my_products/add_product.dart';
import '../my_products/selling_orders.dart';

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

  int _currentIndex = 0;

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

  // ---------------------------------------------------------------------------
  // NAVIGATION
  // ---------------------------------------------------------------------------

  void _goToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const ArtistHome()),
      (route) => false,
    );
  }

  void _goToBuyingOrders() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const BuyingOrders()),
    );
  }

  void _continueShopping() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const Marketplace()),
    );
  }

  void _onNavigationSelected(int index) {
    if (index == 0) {
      _goToHome();
      return;
    }

    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Marketplace()),
      );
      return;
    }

    if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SellingOrders()),
      );
      return;
    }

    if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Profile()),
      );
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  void _onAddProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddProduct()),
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtistColors.background,
      body: SafeArea(
        bottom: false,
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
      bottomNavigationBar: ArtistBottomNavigation(
        currentIndex: _currentIndex,
        onItemSelected: _onNavigationSelected,
        onAddProduct: _onAddProduct,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TOP BAR
  // ---------------------------------------------------------------------------

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 18, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: _goToHome,
            icon: const Icon(Icons.close_rounded),
            color: ArtistColors.textPrimary,
            tooltip: 'Go to Home',
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Text(
              'Order Confirmation',
              style: ArtistTextStyles.title.copyWith(fontSize: 20),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: ArtistColors.light,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.eco_outlined,
                  size: 15,
                  color: ArtistColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'EcoLoop',
                  style: ArtistTextStyles.small.copyWith(
                    color: ArtistColors.primary,
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

  // ---------------------------------------------------------------------------
  // SUCCESS ANIMATION
  // ---------------------------------------------------------------------------

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
              color: ArtistColors.light.withValues(alpha: 0.55),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 122,
            height: 122,
            decoration: BoxDecoration(
              color: ArtistColors.light,
              shape: BoxShape.circle,
              border: Border.all(color: ArtistColors.accent, width: 2),
            ),
          ),
          Container(
            width: 92,
            height: 92,
            decoration: const BoxDecoration(
              color: ArtistColors.primary,
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
    return Icon(icon, color: ArtistColors.secondary, size: size);
  }

  // ---------------------------------------------------------------------------
  // SUCCESS MESSAGE
  // ---------------------------------------------------------------------------

  Widget _buildSuccessMessage() {
    return Column(
      children: [
        Text(
          'Order Placed Successfully!',
          style: ArtistTextStyles.heading.copyWith(fontSize: 25),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 9),
        Text(
          'Thank you for choosing EcoLoop. Your order is on its way to becoming a part of a more sustainable cycle.',
          style: ArtistTextStyles.body.copyWith(fontSize: 13.5, height: 1.55),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 13),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: ArtistColors.light,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: ArtistColors.success,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Order confirmed',
                style: ArtistTextStyles.small.copyWith(
                  color: ArtistColors.primary,
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

  // ---------------------------------------------------------------------------
  // ORDER CARD
  // ---------------------------------------------------------------------------

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
                  style: ArtistTextStyles.title.copyWith(fontSize: 17),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: ArtistColors.border),
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
            valueColor: ArtistColors.primary,
            valueBold: true,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DELIVERY CARD
  // ---------------------------------------------------------------------------

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
                  style: ArtistTextStyles.title.copyWith(fontSize: 17),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: ArtistColors.border),
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
        Icon(icon, color: ArtistColors.secondary, size: 19),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: ArtistTextStyles.caption.copyWith(fontSize: 11),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: ArtistTextStyles.body.copyWith(
                  color: ArtistColors.textPrimary,
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

  // ---------------------------------------------------------------------------
  // ECO MESSAGE
  // ---------------------------------------------------------------------------

  Widget _buildEcoMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ArtistColors.light,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ArtistColors.accent.withValues(alpha: 0.6)),
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
              color: ArtistColors.primary,
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
                  style: ArtistTextStyles.body.copyWith(
                    color: ArtistColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'By reusing products, you are helping reduce waste and giving useful items a second life.',
                  style: ArtistTextStyles.caption.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ACTION BUTTONS
  // ---------------------------------------------------------------------------

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _goToBuyingOrders,
            style: ElevatedButton.styleFrom(
              backgroundColor: ArtistColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  size: 19,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  'View Order',
                  style: ArtistTextStyles.button.copyWith(fontSize: 15),
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
              foregroundColor: ArtistColors.primary,
              side: const BorderSide(color: ArtistColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.shopping_bag_outlined,
                  size: 19,
                  color: ArtistColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Continue Shopping',
                  style: ArtistTextStyles.bodyMedium.copyWith(
                    color: ArtistColors.primary,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // COMMON SECTION CARD
  // ---------------------------------------------------------------------------

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ArtistColors.border),
      ),
      child: child,
    );
  }

  // ---------------------------------------------------------------------------
  // ICON BOX
  // ---------------------------------------------------------------------------

  Widget _iconBox(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: ArtistColors.light,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: ArtistColors.primary, size: 21),
    );
  }

  // ---------------------------------------------------------------------------
  // INFO ROW
  // ---------------------------------------------------------------------------

  Widget _infoRow(
    String title,
    String value, {
    Color? valueColor,
    bool valueBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: ArtistTextStyles.body.copyWith(fontSize: 13)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: ArtistTextStyles.body.copyWith(
              color: valueColor ?? ArtistColors.textPrimary,
              fontSize: 13,
              fontWeight: valueBold ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
