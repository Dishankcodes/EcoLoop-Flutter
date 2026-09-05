import 'package:flutter/material.dart';

import '../../../app_theme/app_colors.dart';
import '../../../app_theme/app_text_styles.dart';
import 'marketplace.dart';
import 'payment.dart';

class Checkout extends StatefulWidget {
  /// Preferred way:
  /// Pass the complete cart here.
  final List<Map<String, dynamic>>? items;

  /// Kept for compatibility with ProductDetails / old Cart flow.
  final Map<String, dynamic>? product;

  /// Quantity used when [product] is supplied.
  final int quantity;

  /// Optional coupon values.
  final String? initialCouponCode;
  final double initialCouponDiscount;

  /// Optional Eco Point discount.
  final double initialEcoPointDiscount;

  const Checkout({
    super.key,
    this.items,
    this.product,
    this.quantity = 1,
    this.initialCouponCode,
    this.initialCouponDiscount = 0,
    this.initialEcoPointDiscount = 0,
  });

  @override
  State<Checkout> createState() => _CheckoutState();
}

class _CheckoutState extends State<Checkout> {
  // ===========================================================================
  // CHECKOUT ITEMS
  // ===========================================================================

  final List<Map<String, dynamic>> _items = [];

  // ===========================================================================
  // ADDRESS
  // ===========================================================================

  final List<Map<String, dynamic>> _addresses = [
    {
      'id': 'home',
      'label': 'Home',
      'name': 'Dishank',
      'phone': '+91 98765 43210',
      'address': '123, Green Avenue',
      'area': 'Satellite',
      'city': 'Ahmedabad',
      'state': 'Gujarat',
      'pincode': '380015',
      'isDefault': true,
    },
    {
      'id': 'work',
      'label': 'Work',
      'name': 'Dishank',
      'phone': '+91 98765 43210',
      'address': 'EcoLoop Workspace',
      'area': 'Navrangpura',
      'city': 'Ahmedabad',
      'state': 'Gujarat',
      'pincode': '380009',
      'isDefault': false,
    },
  ];

  String _selectedAddressId = 'home';

  // ===========================================================================
  // DELIVERY
  // ===========================================================================

  String _selectedDelivery = 'standard';

  // ===========================================================================
  // COUPON
  // ===========================================================================

  String? _couponCode;
  double _couponDiscount = 0;

  // ===========================================================================
  // ECO POINTS
  // ===========================================================================

  final int _ecoPoints = 120;
  bool _useEcoPoints = false;

  // ===========================================================================
  // UI STATE
  // ===========================================================================

  bool _isProcessing = false;

  // ===========================================================================
  // INIT
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    _loadItems();

    _couponCode = widget.initialCouponCode;
    _couponDiscount = widget.initialCouponDiscount;
  }

  void _loadItems() {
    if (widget.items != null && widget.items!.isNotEmpty) {
      for (final item in widget.items!) {
        _items.add(_normalizeItem(item));
      }
      return;
    }

    if (widget.product != null) {
      final item = Map<String, dynamic>.from(widget.product!);

      item['quantity'] = widget.quantity;

      _items.add(_normalizeItem(item));
    }
  }

  Map<String, dynamic> _normalizeItem(Map<String, dynamic> item) {
    final copy = Map<String, dynamic>.from(item);

    copy['productId'] =
        copy['productId'] ??
        copy['id'] ??
        DateTime.now().microsecondsSinceEpoch.toString();

    copy['title'] = copy['title'] ?? copy['name'] ?? 'EcoLoop Product';

    copy['price'] = _toDouble(copy['price']);

    copy['quantity'] = _toInt(copy['quantity'], fallback: 1);

    copy['availableQuantity'] = _toInt(
      copy['availableQuantity'] ?? copy['stock'] ?? 10,
      fallback: 10,
    );

    if (_toInt(copy['quantity'], fallback: 1) < 1) {
      copy['quantity'] = 1;
    }

    return copy;
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.round();
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }

    return fallback;
  }

  double _toDouble(dynamic value) {
    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value.replaceAll(',', '')) ?? 0;
    }

    return 0;
  }

  String _formatPrice(double value) {
    return '₹${_formatIndianNumber(value.round())}';
  }

  String _formatIndianNumber(int number) {
    final value = number.toString();

    if (value.length <= 3) {
      return value;
    }

    final lastThree = value.substring(value.length - 3);
    var remaining = value.substring(0, value.length - 3);

    final parts = <String>[];

    while (remaining.length > 2) {
      parts.insert(0, remaining.substring(remaining.length - 2));

      remaining = remaining.substring(0, remaining.length - 2);
    }

    if (remaining.isNotEmpty) {
      parts.insert(0, remaining);
    }

    return '${parts.join(',')},$lastThree';
  }

  String _productImage(Map<String, dynamic> item) {
    final image = item['image'];

    if (image is String && image.trim().isNotEmpty) {
      return image;
    }

    final imageUrl = item['imageUrl'];

    if (imageUrl is String && imageUrl.trim().isNotEmpty) {
      return imageUrl;
    }

    final imageUrls = item['imageUrls'];

    if (imageUrls is List && imageUrls.isNotEmpty) {
      return imageUrls.first.toString();
    }

    final images = item['images'];

    if (images is List && images.isNotEmpty) {
      return images.first.toString();
    }

    return '';
  }

  String _sellerName(Map<String, dynamic> item) {
    return (item['seller'] ?? item['sellerName'] ?? 'EcoLoop Seller')
        .toString();
  }

  String _condition(Map<String, dynamic> item) {
    return (item['condition'] ?? 'Used').toString();
  }

  String _category(Map<String, dynamic> item) {
    return (item['category'] ?? 'Recycled').toString();
  }

  // ===========================================================================
  // TOTALS
  // ===========================================================================

  int get _totalQuantity {
    var total = 0;

    for (final item in _items) {
      total += _toInt(item['quantity'], fallback: 1);
    }

    return total;
  }

  double get _subtotal {
    var total = 0.0;

    for (final item in _items) {
      final price = _toDouble(item['price']);

      final quantity = _toInt(item['quantity'], fallback: 1);

      total += price * quantity;
    }

    return total;
  }

  double get _deliveryFee {
    if (_selectedDelivery == 'free') {
      return 0;
    }

    if (_selectedDelivery == 'express') {
      return 99;
    }

    if (_subtotal >= 999) {
      return 0;
    }

    return 49;
  }

  double get _ecoPointDiscount {
    if (!_useEcoPoints || _ecoPoints <= 0) {
      return 0;
    }

    final discount = _ecoPoints / 10;

    final maximum = _subtotal - _couponDiscount;

    if (maximum <= 0) {
      return 0;
    }

    return discount > maximum ? maximum : discount;
  }

  double get _grandTotal {
    final total =
        _subtotal - _couponDiscount - _ecoPointDiscount + _deliveryFee;

    return total < 0 ? 0 : total;
  }

  double get _totalSavings {
    return _couponDiscount + _ecoPointDiscount;
  }

  // ===========================================================================
  // SELECTED ADDRESS
  // ===========================================================================

  Map<String, dynamic>? get _selectedAddress {
    for (final address in _addresses) {
      if (address['id'] == _selectedAddressId) {
        return address;
      }
    }

    return null;
  }

  // ===========================================================================
  // ADDRESS SELECTOR
  // ===========================================================================

  void _openAddressSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _sheetHandle(),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Select Delivery Address',
                            style: AppTextStyles.title,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            _openAddAddress();
                          },
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Add New'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            ..._addresses.map((address) {
                              final selected =
                                  address['id'] == _selectedAddressId;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildAddressOption(
                                  address,
                                  selected,
                                  () {
                                    setSheetState(() {
                                      _selectedAddressId = address['id']
                                          .toString();
                                    });

                                    setState(() {});

                                    Navigator.pop(sheetContext);
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAddressOption(
    Map<String, dynamic> address,
    bool selected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: selected ? AppColors.light : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey.shade200,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected ? AppColors.surface : AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                address['label'] == 'Work'
                    ? Icons.work_outline_rounded
                    : Icons.home_outlined,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        address['label'].toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (address['isDefault'] == true) ...[
                        const SizedBox(width: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Text(
                            'Default',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 5),

                  Text(
                    address['name'].toString(),
                    style: AppTextStyles.body.copyWith(fontSize: 13),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    '${address['address']}, '
                    '${address['area']}, '
                    '${address['city']}, '
                    '${address['state']} - '
                    '${address['pincode']}',
                    style: AppTextStyles.caption.copyWith(height: 1.45),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    address['phone'].toString(),
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? AppColors.primary : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // ADD ADDRESS
  // ===========================================================================

  void _openAddAddress() {
    final nameController = TextEditingController();

    final phoneController = TextEditingController();

    final addressController = TextEditingController();

    final areaController = TextEditingController();

    final cityController = TextEditingController();

    final stateController = TextEditingController();

    final pincodeController = TextEditingController();

    String selectedLabel = 'Home';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sheetHandle(),

                    const SizedBox(height: 18),

                    Text('Add New Address', style: AppTextStyles.title),

                    const SizedBox(height: 5),

                    Text(
                      'Enter the address where your '
                      'EcoLoop order should be delivered.',
                      style: AppTextStyles.body,
                    ),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        _addressLabelChip(
                          label: 'Home',
                          icon: Icons.home_outlined,
                          selected: selectedLabel == 'Home',
                          onTap: () {
                            setSheetState(() {
                              selectedLabel = 'Home';
                            });
                          },
                        ),
                        const SizedBox(width: 10),
                        _addressLabelChip(
                          label: 'Work',
                          icon: Icons.work_outline_rounded,
                          selected: selectedLabel == 'Work',
                          onTap: () {
                            setSheetState(() {
                              selectedLabel = 'Work';
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    _textField(
                      controller: nameController,
                      label: 'Full Name',
                      icon: Icons.person_outline_rounded,
                    ),

                    const SizedBox(height: 10),

                    _textField(
                      controller: phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 10),

                    _textField(
                      controller: addressController,
                      label: 'House / Building / Street',
                      icon: Icons.location_on_outlined,
                    ),

                    const SizedBox(height: 10),

                    _textField(
                      controller: areaController,
                      label: 'Area / Locality',
                      icon: Icons.map_outlined,
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: _textField(
                            controller: cityController,
                            label: 'City',
                            icon: Icons.location_city_outlined,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _textField(
                            controller: stateController,
                            label: 'State',
                            icon: Icons.map_outlined,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    _textField(
                      controller: pincodeController,
                      label: 'Pincode',
                      icon: Icons.pin_drop_outlined,
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          if (nameController.text.trim().isEmpty ||
                              phoneController.text.trim().isEmpty ||
                              addressController.text.trim().isEmpty ||
                              cityController.text.trim().isEmpty ||
                              stateController.text.trim().isEmpty ||
                              pincodeController.text.trim().isEmpty) {
                            _showMessage(
                              'Please fill all required '
                              'address fields.',
                            );
                            return;
                          }

                          final newId =
                              'address_${DateTime.now().millisecondsSinceEpoch}';

                          setState(() {
                            _addresses.add({
                              'id': newId,
                              'label': selectedLabel,
                              'name': nameController.text.trim(),
                              'phone': phoneController.text.trim(),
                              'address': addressController.text.trim(),
                              'area': areaController.text.trim(),
                              'city': cityController.text.trim(),
                              'state': stateController.text.trim(),
                              'pincode': pincodeController.text.trim(),
                              'isDefault': false,
                            });

                            _selectedAddressId = newId;
                          });

                          Navigator.pop(sheetContext);

                          _showMessage('Address added successfully.');
                        },
                        child: const Text('Save Address'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _addressLabelChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.light : AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.grey.shade200,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
      ),
    );
  }

  // ===========================================================================
  // DELIVERY
  // ===========================================================================

  void _openDeliveryOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sheetHandle(),

                const SizedBox(height: 18),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Delivery Options', style: AppTextStyles.title),
                ),

                const SizedBox(height: 12),

                _deliveryOption(
                  sheetContext,
                  id: 'standard',
                  title: 'Standard Delivery',
                  subtitle: 'Delivery in 3–5 business days',
                  price: _subtotal >= 999 ? 'FREE' : '₹49',
                  icon: Icons.local_shipping_outlined,
                ),

                const SizedBox(height: 10),

                _deliveryOption(
                  sheetContext,
                  id: 'express',
                  title: 'Express Delivery',
                  subtitle: 'Delivery in 1–2 business days',
                  price: '₹99',
                  icon: Icons.speed_outlined,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _deliveryOption(
    BuildContext sheetContext, {
    required String id,
    required String title,
    required String subtitle,
    required String price,
    required IconData icon,
  }) {
    final selected = _selectedDelivery == id;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedDelivery = id;
        });

        Navigator.pop(sheetContext);
      },
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.light : AppColors.surface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: selected ? AppColors.surface : AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),

            Text(
              price,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: price == 'FREE'
                    ? AppColors.success
                    : AppColors.textPrimary,
              ),
            ),

            const SizedBox(width: 8),

            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? AppColors.primary : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // COUPONS
  // ===========================================================================

  void _openCoupons() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sheetHandle(),

                const SizedBox(height: 18),

                Row(
                  children: [
                    const Icon(
                      Icons.local_offer_outlined,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 9),
                    Text('Apply Coupon', style: AppTextStyles.title),
                  ],
                ),

                const SizedBox(height: 15),

                _checkoutCouponTile(
                  sheetContext,
                  code: 'ECO100',
                  title: '₹100 OFF',
                  subtitle: 'On orders above ₹1,499',
                  minimumOrder: 1499,
                  discount: 100,
                ),

                const SizedBox(height: 10),

                _checkoutCouponTile(
                  sheetContext,
                  code: 'FIRSTLOOP',
                  title: '10% OFF',
                  subtitle: 'On orders above ₹500',
                  minimumOrder: 500,
                  percentage: 0.10,
                ),

                const SizedBox(height: 10),

                _checkoutCouponTile(
                  sheetContext,
                  code: 'RECYCLE20',
                  title: '₹20 OFF',
                  subtitle: 'On orders above ₹499',
                  minimumOrder: 499,
                  discount: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _checkoutCouponTile(
    BuildContext sheetContext, {
    required String code,
    required String title,
    required String subtitle,
    required double minimumOrder,
    double? discount,
    double? percentage,
  }) {
    final applied = _couponCode == code;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: applied ? AppColors.primary : Colors.grey.shade200,
        ),
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
              Icons.confirmation_num_outlined,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      code,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),

          TextButton(
            onPressed: () {
              if (_subtotal < minimumOrder) {
                _showMessage(
                  'Minimum order is '
                  '${_formatPrice(minimumOrder)}.',
                );
                return;
              }

              var calculated = 0.0;

              if (discount != null) {
                calculated = discount;
              } else if (percentage != null) {
                calculated = _subtotal * percentage;
              }

              setState(() {
                _couponCode = code;
                _couponDiscount = calculated;
              });

              Navigator.pop(sheetContext);

              _showMessage('$code applied successfully.');
            },
            child: Text(applied ? 'Applied' : 'Apply'),
          ),
        ],
      ),
    );
  }

  void _removeCoupon() {
    setState(() {
      _couponCode = null;
      _couponDiscount = 0;
    });

    _showMessage('Coupon removed.');
  }

  // ===========================================================================
  // ECO POINTS
  // ===========================================================================

  void _toggleEcoPoints() {
    if (_ecoPoints <= 0) {
      _showMessage('You do not have enough Eco Points.');
      return;
    }

    setState(() {
      _useEcoPoints = !_useEcoPoints;
    });
  }

  // ===========================================================================
  // ITEM QUANTITY
  // ===========================================================================

  void _increaseItemQuantity(int index) {
    if (index < 0 || index >= _items.length) {
      return;
    }

    final item = _items[index];

    final current = _toInt(item['quantity'], fallback: 1);

    final available = _toInt(item['availableQuantity'], fallback: 10);

    if (current >= available) {
      _showMessage(
        'Only $available item'
        '${available == 1 ? '' : 's'} available.',
      );
      return;
    }

    setState(() {
      item['quantity'] = current + 1;
    });
  }

  void _decreaseItemQuantity(int index) {
    if (index < 0 || index >= _items.length) {
      return;
    }

    final current = _toInt(_items[index]['quantity'], fallback: 1);

    if (current <= 1) {
      _removeItem(index);
      return;
    }

    setState(() {
      _items[index]['quantity'] = current - 1;
    });
  }

  void _removeItem(int index) {
    if (index < 0 || index >= _items.length) {
      return;
    }

    final title = _items[index]['title'].toString();

    setState(() {
      _items.removeAt(index);
    });

    if (_items.isNotEmpty) {
      _showMessage('$title removed from checkout.');
    } else {
      _showMessage('All items removed from checkout.');
    }
  }

  // ===========================================================================
  // EDIT ITEM
  // ===========================================================================

  void _editCheckoutItem(int index) {
    if (index < 0 || index >= _items.length) {
      return;
    }

    final item = _items[index];

    final currentQuantity = _toInt(item['quantity'], fallback: 1);

    final available = _toInt(item['availableQuantity'], fallback: 10);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        var selectedQuantity = currentQuantity;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final price = _toDouble(item['price']);

            final total = price * selectedQuantity;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sheetHandle(),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        _productImageWidget(_productImage(item), 62, 62),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'].toString(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_formatPrice(price)} each',
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Quantity',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '$available available',
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),

                        _quantityControl(
                          quantity: selectedQuantity,
                          onMinus: selectedQuantity > 1
                              ? () {
                                  setSheetState(() {
                                    selectedQuantity--;
                                  });
                                }
                              : null,
                          onPlus: selectedQuantity < available
                              ? () {
                                  setSheetState(() {
                                    selectedQuantity++;
                                  });
                                }
                              : null,
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Item total',
                              style: AppTextStyles.body,
                            ),
                          ),
                          Text(
                            _formatPrice(total),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(sheetContext);
                              _removeItem(index);
                            },
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                            ),
                            label: const Text('Remove'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: BorderSide(
                                color: AppColors.error.withOpacity(0.35),
                              ),
                              minimumSize: const Size.fromHeight(50),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _items[index]['quantity'] = selectedQuantity;
                              });

                              Navigator.pop(sheetContext);

                              _showMessage('Item updated successfully.');
                            },
                            child: const Text('Update Item'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _quantityControl({
    required int quantity,
    VoidCallback? onMinus,
    VoidCallback? onPlus,
  }) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.75)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _quantityButton(icon: Icons.remove_rounded, onPressed: onMinus),

          SizedBox(
            width: 32,
            child: Center(
              child: Text(
                '$quantity',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),

          _quantityButton(icon: Icons.add_rounded, onPressed: onPlus),
        ],
      ),
    );
  }

  Widget _quantityButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 32,
        height: 38,
        child: Icon(
          icon,
          size: 17,
          color: onPressed == null ? Colors.grey.shade400 : AppColors.primary,
        ),
      ),
    );
  }

  // ===========================================================================
  // ADD PRODUCT TO CHECKOUT
  // ===========================================================================

  void _addProductToCheckout(Map<String, dynamic> product) {
    final productId = product['productId'] ?? product['id'];

    final existingIndex = _items.indexWhere(
      (item) => item['productId'].toString() == productId.toString(),
    );

    if (existingIndex != -1) {
      final current = _toInt(_items[existingIndex]['quantity'], fallback: 1);

      final available = _toInt(
        _items[existingIndex]['availableQuantity'],
        fallback: 10,
      );

      if (current >= available) {
        _showMessage(
          'Maximum available quantity '
          'already added.',
        );
        return;
      }

      setState(() {
        _items[existingIndex]['quantity'] = current + 1;
      });

      _showMessage('Quantity updated.');

      return;
    }

    final newItem = _normalizeItem({...product, 'quantity': 1});

    setState(() {
      _items.add(newItem);
    });

    _showMessage('${newItem['title']} added to checkout.');
  }

  // ===========================================================================
  // MORE PRODUCTS
  // ===========================================================================

  final List<Map<String, dynamic>> _moreItems = [
    {
      'id': 'checkout_more_1',
      'title': 'Wooden Chair',
      'price': 1200,
      'seller': 'Amit',
      'condition': 'Used',
      'category': 'Furniture',
      'location': 'Vadodara',
      'availableQuantity': 4,
      'image': '',
    },
    {
      'id': 'checkout_more_2',
      'title': 'Bottle Lamp',
      'price': 899,
      'seller': 'Priya',
      'condition': 'Upcycled',
      'category': 'Decor',
      'location': 'Surat',
      'availableQuantity': 5,
      'image': '',
    },
    {
      'id': 'checkout_more_3',
      'title': 'Craft Wood Pieces',
      'price': 450,
      'seller': 'EcoCraft',
      'condition': 'Recycled',
      'category': 'Materials',
      'location': 'Ahmedabad',
      'availableQuantity': 10,
      'image': '',
    },
    {
      'id': 'checkout_more_4',
      'title': 'Denim Material Bundle',
      'price': 700,
      'seller': 'Mira',
      'condition': 'Used',
      'category': 'Fashion',
      'location': 'Mumbai',
      'availableQuantity': 6,
      'image': '',
    },
  ];

  void _openAddMoreItems() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.72,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  _sheetHandle(),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Add more items', style: AppTextStyles.title),
                            const SizedBox(height: 3),
                            Text(
                              'Pick another item '
                              'for this order',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),

                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Expanded(
                    child: ListView.separated(
                      itemCount: _moreItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final product = _moreItems[index];

                        final productId = product['id'].toString();

                        final existingIndex = _items.indexWhere(
                          (item) => item['productId'].toString() == productId,
                        );

                        final alreadyAdded = existingIndex != -1;

                        final existingQuantity = alreadyAdded
                            ? _toInt(
                                _items[existingIndex]['quantity'],
                                fallback: 1,
                              )
                            : 0;

                        return _buildAddMoreProductTile(
                          product,
                          alreadyAdded,
                          existingQuantity,
                          onAdd: () {
                            _addProductToCheckout(product);
                            setState(() {});
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const Marketplace(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.storefront_outlined),
                      label: const Text('Browse Marketplace'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddMoreProductTile(
    Map<String, dynamic> product,
    bool alreadyAdded,
    int existingQuantity, {
    required VoidCallback onAdd,
  }) {
    final price = _toDouble(product['price']);

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          _productImageWidget(_productImage(product), 68, 68),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product['title'].toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  '${_category(product)} • '
                  '${_condition(product)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),

                const SizedBox(height: 5),

                Text(
                  _formatPrice(price),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (alreadyAdded)
                Text(
                  'Qty $existingQuantity',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),

              const SizedBox(height: 5),

              SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: onAdd,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    alreadyAdded ? 'Add +1' : 'Add',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // PRODUCT SECTION
  // ===========================================================================

  Widget _buildProductSection() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionIcon(Icons.shopping_bag_outlined),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Summary',
                      style: AppTextStyles.title.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Review and edit your items',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),

              Text(
                '$_totalQuantity item'
                '${_totalQuantity == 1 ? '' : 's'}',
                style: AppTextStyles.caption,
              ),
            ],
          ),

          const SizedBox(height: 12),

          ...List.generate(_items.length, (index) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == _items.length - 1 ? 0 : 12,
              ),
              child: _buildCheckoutProduct(_items[index], index),
            );
          }),

          const SizedBox(height: 13),

          InkWell(
            onTap: _openAddMoreItems,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.light,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.accent.withOpacity(0.8)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.add_rounded, color: AppColors.primary, size: 22),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Add more items',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutProduct(Map<String, dynamic> item, int index) {
    final image = _productImage(item);

    final title = item['title'].toString();

    final price = _toDouble(item['price']);

    final quantity = _toInt(item['quantity'], fallback: 1);

    final available = _toInt(item['availableQuantity'], fallback: 10);

    final total = price * quantity;

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _productImageWidget(image, 82, 82),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      '${_category(item)} • '
                      '${_condition(item)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption,
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Sold by '
                      '${_sellerName(item)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption,
                    ),

                    const SizedBox(height: 7),

                    Row(
                      children: [
                        Text(
                          _formatPrice(price),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('each', style: AppTextStyles.caption),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Text(
                _formatPrice(total),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 11),

          Row(
            children: [
              const Text(
                'Qty',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(width: 6),

              _quantityControl(
                quantity: quantity,
                onMinus: () => _decreaseItemQuantity(index),
                onPlus: quantity < available
                    ? () => _increaseItemQuantity(index)
                    : null,
              ),

              const SizedBox(width: 6),

              Expanded(
                child: Text(
                  '$available left',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(fontSize: 10),
                ),
              ),

              IconButton(
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
                onPressed: () => _editCheckoutItem(index),
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                tooltip: 'Edit',
              ),

              const SizedBox(width: 4),

              IconButton(
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
                onPressed: () => _removeItem(index),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: AppColors.error,
                ),
                tooltip: 'Remove',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // COUPON SECTION
  // ===========================================================================

  Widget _buildCouponSection() {
    final applied = _couponCode != null;

    return _sectionCard(
      child: Column(
        children: [
          Row(
            children: [
              _sectionIcon(Icons.local_offer_outlined),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      applied ? 'Coupon Applied' : 'Apply Coupon',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      applied
                          ? '$_couponCode • You saved '
                                '${_formatPrice(_couponDiscount)}'
                          : 'Save more on your '
                                'EcoLoop order',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),

              TextButton(
                onPressed: applied ? _removeCoupon : _openCoupons,
                child: Text(
                  applied ? 'Remove' : 'Apply',
                  style: TextStyle(
                    color: applied ? AppColors.error : AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          if (!applied) ...[
            const SizedBox(height: 10),

            InkWell(
              onTap: _openCoupons,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.confirmation_num_outlined,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: Text(
                        'View all available coupons',
                        style: AppTextStyles.body.copyWith(fontSize: 12),
                      ),
                    ),

                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // ECO POINTS SECTION
  // ===========================================================================

  Widget _buildEcoPointsSection() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withOpacity(0.7)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.eco_rounded, color: AppColors.primary),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Use Eco Points',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$_ecoPoints points available'
                  '${_ecoPointDiscount > 0 ? ' • Save ${_formatPrice(_ecoPointDiscount)}' : ''}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),

          Switch.adaptive(
            value: _useEcoPoints,
            activeColor: AppColors.primary,
            onChanged: (_) {
              _toggleEcoPoints();
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // PRICE DETAILS
  // ===========================================================================

  Widget _buildPriceDetails() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price Details',
            style: AppTextStyles.title.copyWith(fontSize: 18),
          ),

          const SizedBox(height: 15),

          _priceRow(
            'Price ($_totalQuantity item'
            '${_totalQuantity == 1 ? '' : 's'})',
            _formatPrice(_subtotal),
          ),

          if (_couponDiscount > 0) ...[
            const SizedBox(height: 10),
            _priceRow(
              'Coupon Discount',
              '- ${_formatPrice(_couponDiscount)}',
              valueColor: AppColors.success,
            ),
          ],

          if (_ecoPointDiscount > 0) ...[
            const SizedBox(height: 10),
            _priceRow(
              'Eco Points',
              '- ${_formatPrice(_ecoPointDiscount)}',
              valueColor: AppColors.success,
            ),
          ],

          const SizedBox(height: 10),

          _priceRow(
            'Delivery Fee',
            _deliveryFee == 0 ? 'FREE' : _formatPrice(_deliveryFee),
            valueColor: _deliveryFee == 0 ? AppColors.success : null,
          ),

          const SizedBox(height: 14),

          Divider(color: Colors.grey.shade200),

          const SizedBox(height: 13),

          _priceRow(
            'Total Amount',
            _formatPrice(_grandTotal),
            bold: true,
            valueSize: 18,
          ),

          if (_totalSavings > 0) ...[
            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'You saved '
                '${_formatPrice(_totalSavings)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _priceRow(
    String label,
    String value, {
    Color? valueColor,
    bool bold = false,
    double valueSize = 13,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: bold ? 14 : 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              color: bold ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),

        Text(
          value,
          style: TextStyle(
            fontSize: valueSize,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // TRUST SECTION
  // ===========================================================================

  Widget _buildTrustSection() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _trustRow(
            Icons.verified_user_outlined,
            'Secure Checkout',
            'Your checkout information is protected.',
          ),

          const SizedBox(height: 12),

          _trustRow(
            Icons.eco_outlined,
            'EcoLoop Impact',
            'Your purchase helps reuse useful products.',
          ),

          const SizedBox(height: 12),

          _trustRow(
            Icons.support_agent_outlined,
            'Need Help?',
            'EcoLoop support is available if something goes wrong.',
          ),
        ],
      ),
    );
  }

  Widget _trustRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 21, color: AppColors.primary),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: AppTextStyles.caption),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // CONTINUE TO PAYMENT
  // ===========================================================================

  void _continueToPayment() {
    if (_items.isEmpty) {
      _showMessage('There are no products to checkout.');
      return;
    }

    if (_selectedAddress == null) {
      _showMessage('Please select a delivery address.');
      return;
    }

    final deliveryLabel = _selectedDelivery == 'express'
        ? 'Express Delivery'
        : 'Standard Delivery';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Payment(
          totalAmount: _grandTotal,
          items: List<Map<String, dynamic>>.from(_items),
          address: _selectedAddress,
          deliveryMethod: deliveryLabel,
          savings: _totalSavings,
        ),
      ),
    );
  }

  // ===========================================================================
  // MESSAGE
  // ===========================================================================

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Checkout', style: AppTextStyles.title.copyWith(fontSize: 19)),
            Text(
              '$_totalQuantity item'
              '${_totalQuantity == 1 ? '' : 's'}',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
      body: _items.isEmpty ? _buildEmptyCheckout() : _buildCheckoutBody(),
    );
  }

  // ===========================================================================
  // EMPTY CHECKOUT
  // ===========================================================================

  Widget _buildEmptyCheckout() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: const BoxDecoration(
                  color: AppColors.light,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shopping_cart_outlined,
                  size: 52,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 22),

              Text(
                'Nothing to checkout',
                style: AppTextStyles.heading.copyWith(fontSize: 23),
              ),

              const SizedBox(height: 8),

              Text(
                'Add a product to your cart '
                'before continuing to checkout.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body,
              ),

              const SizedBox(height: 22),

              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Back to Shopping'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // CHECKOUT BODY
  // ===========================================================================

  Widget _buildCheckoutBody() {
    return SafeArea(
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 160),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStepIndicator(),

                const SizedBox(height: 14),

                _buildAddressSection(),

                const SizedBox(height: 14),

                _buildDeliverySection(),

                const SizedBox(height: 14),

                _buildProductSection(),

                const SizedBox(height: 14),

                _buildCouponSection(),

                const SizedBox(height: 14),

                _buildEcoPointsSection(),

                const SizedBox(height: 14),

                _buildPriceDetails(),

                const SizedBox(height: 16),

                _buildTrustSection(),
              ],
            ),
          ),

          _buildBottomBar(),
        ],
      ),
    );
  }

  // ===========================================================================
  // STEP INDICATOR
  // ===========================================================================

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          _checkoutStep(number: '1', title: 'Address', active: true),

          _stepLine(),

          _checkoutStep(number: '2', title: 'Delivery', active: true),

          _stepLine(),

          _checkoutStep(number: '3', title: 'Payment', active: false),
        ],
      ),
    );
  }

  Widget _checkoutStep({
    required String number,
    required String title,
    required bool active,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: active ? AppColors.primary : AppColors.background,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: active ? Colors.white : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),

          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: active ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepLine() {
    return Container(
      width: 28,
      height: 1,
      margin: const EdgeInsets.only(bottom: 20),
      color: Colors.grey.shade300,
    );
  }

  // ===========================================================================
  // ADDRESS SECTION
  // ===========================================================================

  Widget _buildAddressSection() {
    final address = _selectedAddress;

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionIcon(Icons.location_on_outlined),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  'Delivery Address',
                  style: AppTextStyles.title.copyWith(fontSize: 18),
                ),
              ),

              TextButton(
                onPressed: _openAddressSelector,
                child: const Text('Change'),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (address == null)
            _buildNoAddress()
          else
            _buildSelectedAddress(address),
        ],
      ),
    );
  }

  Widget _buildSelectedAddress(Map<String, dynamic> address) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              address['label'] == 'Work'
                  ? Icons.work_outline_rounded
                  : Icons.home_outlined,
              size: 19,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      address['label'].toString(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(width: 7),

                    if (address['isDefault'] == true)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.light,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Default',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 5),

                Text(
                  address['name'].toString(),
                  style: AppTextStyles.body.copyWith(fontSize: 12),
                ),

                const SizedBox(height: 3),

                Text(
                  '${address['address']}, '
                  '${address['area']}, '
                  '${address['city']}, '
                  '${address['state']} - '
                  '${address['pincode']}',
                  style: AppTextStyles.caption.copyWith(height: 1.4),
                ),

                const SizedBox(height: 3),

                Text(address['phone'].toString(), style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoAddress() {
    return InkWell(
      onTap: _openAddressSelector,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.light,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Row(
          children: [
            Icon(Icons.add_location_alt_outlined, color: AppColors.primary),

            SizedBox(width: 10),

            Expanded(
              child: Text(
                'Add a delivery address',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            Icon(Icons.chevron_right_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // DELIVERY SECTION
  // ===========================================================================

  Widget _buildDeliverySection() {
    final isFree = _deliveryFee == 0;

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionIcon(Icons.local_shipping_outlined),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  'Delivery',
                  style: AppTextStyles.title.copyWith(fontSize: 18),
                ),
              ),

              TextButton(
                onPressed: _openDeliveryOptions,
                child: const Text('Change'),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.light,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.local_shipping_outlined,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedDelivery == 'express'
                            ? 'Express Delivery'
                            : 'Standard Delivery',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _selectedDelivery == 'express'
                            ? '1–2 business days'
                            : '3–5 business days',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),

                Text(
                  isFree ? 'FREE' : _formatPrice(_deliveryFee),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isFree ? AppColors.success : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // BOTTOM BAR
  // ===========================================================================

  Widget _buildBottomBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 18,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Total', style: AppTextStyles.caption),

                    const SizedBox(height: 2),

                    Text(
                      _formatPrice(_grandTotal),
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    if (_totalSavings > 0)
                      Text(
                        'Saved '
                        '${_formatPrice(_totalSavings)}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _continueToPayment,
                    child: _isProcessing
                        ? const SizedBox(
                            width: 21,
                            height: 21,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Continue to Payment'),
                                SizedBox(width: 6),
                                Icon(Icons.arrow_forward_rounded, size: 18),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // COMMON UI
  // ===========================================================================

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  Widget _sectionIcon(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 20, color: AppColors.primary),
    );
  }

  Widget _sheetHandle() {
    return Center(
      child: Container(
        width: 42,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  // ===========================================================================
  // IMAGE HANDLING
  // ===========================================================================

  Widget _productImageWidget(String image, double width, double height) {
    if (image.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Image.network(
          image,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return _imagePlaceholder(width, height);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }

            return _imagePlaceholder(width, height, loading: true);
          },
        ),
      );
    }

    return _imagePlaceholder(width, height);
  }

  Widget _imagePlaceholder(
    double width,
    double height, {
    bool loading = false,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : const Icon(
                Icons.image_outlined,
                size: 31,
                color: AppColors.secondary,
              ),
      ),
    );
  }
}
