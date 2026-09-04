import 'package:flutter/material.dart';

import '../../app_theme/app_colors.dart';
import '../../app_theme/app_text_styles.dart';

class Checkout extends StatefulWidget {
  const Checkout({super.key, required this.product, this.quantity = 1});

  final Map<String, dynamic> product;
  final int quantity;

  @override
  State<Checkout> createState() => _CheckoutState();
}

class _CheckoutState extends State<Checkout> {
  // ============================================================
  // ADDRESS
  // ============================================================

  String _selectedAddress = 'home';

  final Map<String, Map<String, String>> _addresses = {
    'home': {
      'name': 'Dishank Prajapati',
      'phone': '+91 98765 43210',
      'address': 'B-204, Green Residency, Near Science City',
      'city': 'Ahmedabad',
      'state': 'Gujarat',
      'pincode': '380060',
    },
    'work': {
      'name': 'Dishank Prajapati',
      'phone': '+91 98765 43210',
      'address': 'Tech Park Road, Satellite Area',
      'city': 'Ahmedabad',
      'state': 'Gujarat',
      'pincode': '380015',
    },
  };

  // ============================================================
  // COUPON
  // ============================================================

  final TextEditingController _couponController = TextEditingController();

  bool _couponApplied = false;

  // ============================================================
  // CALCULATIONS
  // ============================================================

  int get quantity {
    final available =
        (widget.product['availableQuantity'] as num?)?.toInt() ?? 1;

    final requested = widget.quantity;

    if (requested < 1) {
      return 1;
    }

    return requested > available ? available : requested;
  }

  int get unitPrice {
    return (widget.product['price'] as num?)?.toInt() ?? 0;
  }

  int get subtotal {
    return unitPrice * quantity;
  }

  int get deliveryCharge {
    // Free delivery for orders of ₹999 or more.
    return subtotal >= 999 ? 0 : 49;
  }

  int get discount {
    return _couponApplied ? 100 : 0;
  }

  int get total {
    final calculated = subtotal + deliveryCharge - discount;

    return calculated < 0 ? 0 : calculated;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
        ),
        title: Text(
          'Checkout',
          style: AppTextStyles.title.copyWith(fontSize: 20),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // ======================================================
          // CHECKOUT CONTENT
          // ======================================================
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProgress(),

                  const SizedBox(height: 18),

                  _buildSectionTitle(
                    'Delivery Address',
                    icon: Icons.location_on_outlined,
                  ),

                  const SizedBox(height: 10),

                  _buildAddressCard(),

                  const SizedBox(height: 24),

                  _buildSectionTitle(
                    'Order Summary',
                    icon: Icons.shopping_bag_outlined,
                  ),

                  const SizedBox(height: 10),

                  _buildProductCard(),

                  const SizedBox(height: 24),

                  _buildSectionTitle(
                    'Delivery',
                    icon: Icons.local_shipping_outlined,
                  ),

                  const SizedBox(height: 10),

                  _buildDeliveryCard(),

                  const SizedBox(height: 24),

                  _buildSectionTitle(
                    'Apply Coupon',
                    icon: Icons.local_offer_outlined,
                  ),

                  const SizedBox(height: 10),

                  _buildCouponCard(),

                  const SizedBox(height: 24),

                  _buildSectionTitle(
                    'Price Details',
                    icon: Icons.receipt_long_outlined,
                  ),

                  const SizedBox(height: 10),

                  _buildPriceDetails(),

                  const SizedBox(height: 18),

                  _buildTrustInformation(),
                ],
              ),
            ),
          ),

          // ======================================================
          // BOTTOM TOTAL BAR
          // ======================================================
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ============================================================
  // PROGRESS
  // ============================================================

  Widget _buildProgress() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.accent.withOpacity(0.45)),
      ),
      child: Row(
        children: [
          _ProgressStep(number: '1', title: 'Checkout', active: true),
          _progressLine(),
          _ProgressStep(number: '2', title: 'Payment', active: false),
          _progressLine(),
          _ProgressStep(number: '3', title: 'Done', active: false),
        ],
      ),
    );
  }

  Widget _progressLine() {
    return Expanded(
      child: Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: AppColors.accent.withOpacity(0.7),
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(String title, {required IconData icon}) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.light,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 17, color: AppColors.primary),
        ),
        const SizedBox(width: 9),
        Text(title, style: AppTextStyles.title.copyWith(fontSize: 16)),
      ],
    );
  }

  // ============================================================
  // ADDRESS CARD
  // ============================================================

  Widget _buildAddressCard() {
    final address = _addresses[_selectedAddress]!;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.accent.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ------------------------------------------------------
          // ADDRESS TYPE
          // ------------------------------------------------------
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.light,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _selectedAddress == 'home'
                          ? Icons.home_outlined
                          : Icons.work_outline_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _selectedAddress == 'home' ? 'Home' : 'Work',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              TextButton(
                onPressed: _showAddressOptions,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Change',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ------------------------------------------------------
          // NAME
          // ------------------------------------------------------
          Text(
            address['name']!,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 4),

          // ------------------------------------------------------
          // PHONE
          // ------------------------------------------------------
          Text(address['phone']!, style: AppTextStyles.caption),

          const SizedBox(height: 6),

          // ------------------------------------------------------
          // ADDRESS
          // ------------------------------------------------------
          Text(
            '${address['address']!}, '
            '${address['city']!}, '
            '${address['state']!} - '
            '${address['pincode']!}',
            style: AppTextStyles.body.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ADDRESS OPTIONS
  // ============================================================

  void _showAddressOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSheetHandle(),

                const SizedBox(height: 18),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Select Delivery Address',
                    style: AppTextStyles.title,
                  ),
                ),

                const SizedBox(height: 12),

                ..._addresses.entries.map((entry) {
                  final selected = _selectedAddress == entry.key;

                  final address = entry.value;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAddress = entry.key;
                      });

                      Navigator.pop(sheetContext);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.light : AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.accent.withOpacity(0.45),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            entry.key == 'home'
                                ? Icons.home_outlined
                                : Icons.work_outline_rounded,
                            color: AppColors.primary,
                          ),

                          const SizedBox(width: 11),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.key == 'home' ? 'Home' : 'Work',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),

                                const SizedBox(height: 3),

                                Text(
                                  '${address['address']}, '
                                  '${address['city']} - '
                                  '${address['pincode']}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                          ),

                          Icon(
                            selected
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 5),

                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _showAddAddressMessage();
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add New Address'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddAddressMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Address management will be connected next.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // PRODUCT CARD
  // ============================================================

  Widget _buildProductCard() {
    final product = widget.product;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.accent.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ------------------------------------------------------
          // IMAGE
          // ------------------------------------------------------
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 92,
              height: 92,
              child: Image.network(
                product['image'].toString(),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.light,
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: AppColors.secondary,
                      size: 30,
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(width: 12),

          // ------------------------------------------------------
          // DETAILS
          // ------------------------------------------------------
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product['title'].toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                Row(
                  children: [
                    _smallTag(product['condition'].toString()),
                    const SizedBox(width: 5),
                    _smallTag(product['category'].toString()),
                  ],
                ),

                const SizedBox(height: 9),

                Text(
                  '₹$unitPrice',
                  style: AppTextStyles.title.copyWith(fontSize: 17),
                ),

                const SizedBox(height: 7),

                Row(
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                      size: 13,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Sold by ${product['seller']}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SMALL TAG
  // ============================================================

  Widget _smallTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  // ============================================================
  // DELIVERY CARD
  // ============================================================

  Widget _buildDeliveryCard() {
    final isFree = deliveryCharge == 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withOpacity(0.45)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_shipping_outlined,
              color: AppColors.primary,
              size: 22,
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Standard Delivery',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Estimated delivery in 3–5 business days',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),

          Text(
            isFree ? 'FREE' : '₹$deliveryCharge',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isFree ? AppColors.success : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COUPON CARD
  // ============================================================

  Widget _buildCouponCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.accent.withOpacity(0.45)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_offer_outlined,
                size: 19,
                color: AppColors.primary,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: TextField(
                  controller: _couponController,
                  enabled: !_couponApplied,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    hintText: 'Enter coupon code',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              if (_couponApplied)
                IconButton(
                  tooltip: 'Remove coupon',
                  onPressed: () {
                    setState(() {
                      _couponApplied = false;
                      _couponController.clear();
                    });
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.error,
                  ),
                )
              else
                TextButton(
                  onPressed: _applyCoupon,
                  child: const Text(
                    'Apply',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),

          if (_couponApplied)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 28, top: 2),
                child: Text(
                  'Coupon applied • ₹100 saved',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // APPLY COUPON
  // ============================================================

  void _applyCoupon() {
    final code = _couponController.text.trim().toUpperCase();

    if (code.isEmpty) {
      _showMessage('Please enter a coupon code.');
      return;
    }

    // ------------------------------------------------------------
    // UI-only demo coupon.
    // ------------------------------------------------------------

    if (code == 'ECO100') {
      setState(() {
        _couponApplied = true;
      });

      _showMessage('Coupon ECO100 applied.');
    } else {
      _showMessage('Invalid coupon code.');
    }
  }

  // ============================================================
  // PRICE DETAILS
  // ============================================================

  Widget _buildPriceDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.accent.withOpacity(0.45)),
      ),
      child: Column(
        children: [
          _priceRow(
            'Price ($quantity item${quantity > 1 ? 's' : ''})',
            '₹$subtotal',
          ),

          const SizedBox(height: 10),

          _priceRow(
            'Delivery',
            deliveryCharge == 0 ? 'FREE' : '₹$deliveryCharge',
            valueColor: deliveryCharge == 0
                ? AppColors.success
                : AppColors.textPrimary,
          ),

          if (_couponApplied) ...[
            const SizedBox(height: 10),

            _priceRow(
              'Coupon Discount',
              '-₹$discount',
              valueColor: AppColors.success,
            ),
          ],

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 13),
            child: Divider(height: 1, color: AppColors.accent),
          ),

          _priceRow('Total Amount', '₹$total', isTotal: true),
        ],
      ),
    );
  }

  Widget _priceRow(
    String label,
    String value, {
    Color? valueColor,
    bool isTotal = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: isTotal
                ? const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  )
                : AppTextStyles.body.copyWith(fontSize: 12),
          ),
        ),

        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 17 : 12,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
            color:
                valueColor ??
                (isTotal ? AppColors.primary : AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TRUST INFORMATION
  // ============================================================

  Widget _buildTrustInformation() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.accent.withOpacity(0.6)),
      ),
      child: Column(
        children: [
          _trustRow(
            Icons.verified_user_outlined,
            'Secure checkout',
            'Your payment details are protected.',
          ),

          const SizedBox(height: 11),

          _trustRow(
            Icons.replay_outlined,
            'Easy order support',
            'Get help with your EcoLoop order.',
          ),

          const SizedBox(height: 11),

          _trustRow(
            Icons.eco_outlined,
            'Buy sustainably',
            'Every reused item helps reduce waste.',
          ),
        ],
      ),
    );
  }

  Widget _trustRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: AppTextStyles.caption.copyWith(fontSize: 9),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BOTTOM BAR
  // ============================================================

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // ------------------------------------------------------
            // TOTAL
            // ------------------------------------------------------
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Total', style: AppTextStyles.caption),

                  const SizedBox(height: 2),

                  Text(
                    '₹$total',
                    style: AppTextStyles.title.copyWith(fontSize: 19),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 15),

            // ------------------------------------------------------
            // CONTINUE
            // ------------------------------------------------------
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _continueToPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue to Payment',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 7),
                      Icon(Icons.arrow_forward_rounded, size: 17),
                    ],
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
  // CONTINUE TO PAYMENT
  // ============================================================

  void _continueToPayment() {
    // ------------------------------------------------------------
    // Payment screen will be implemented in the next step.
    // ------------------------------------------------------------

    _showMessage('Payment screen will be connected next.');
  }

  // ============================================================
  // SHEET HANDLE
  // ============================================================

  Widget _buildSheetHandle() {
    return Center(
      child: Container(
        width: 42,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

// =================================================================
// PROGRESS STEP
// =================================================================

class _ProgressStep extends StatelessWidget {
  const _ProgressStep({
    required this.number,
    required this.title,
    required this.active,
  });

  final String number;
  final String title;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 25,
          height: 25,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.light,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),

        const SizedBox(height: 4),

        Text(
          title,
          style: TextStyle(
            fontSize: 8,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
