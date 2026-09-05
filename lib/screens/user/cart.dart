import 'package:flutter/material.dart';

import '../../app_theme/app_colors.dart';
import '../../app_theme/app_text_styles.dart';
import 'checkout.dart';

class Cart extends StatefulWidget {
  /// Items passed from ProductDetails / CartPopup.
  ///
  /// Each item is expected to contain values such as:
  /// productId, title, price, image, quantity, availableQuantity,
  /// seller, condition, category, etc.
  final List<Map<String, dynamic>>? initialItems;

  const Cart({super.key, this.initialItems});

  @override
  State<Cart> createState() => _CartState();
}

class _CartState extends State<Cart> {
  final List<Map<String, dynamic>> _cartItems = [];
  final List<Map<String, dynamic>> _savedForLater = [];

  String? _appliedCoupon;
  double _couponDiscount = 0;

  bool _useEcoPoints = false;

  // UI-only points for now.
  // This will come from GET /rewards later.
  int _ecoPoints = 120;

  @override
  void initState() {
    super.initState();
    _loadInitialItems();
  }

  // ---------------------------------------------------------------------------
  // INITIAL DATA
  // ---------------------------------------------------------------------------

  void _loadInitialItems() {
    final incoming = widget.initialItems ?? [];

    for (final item in incoming) {
      _addOrMergeItem(item);
    }

    // Demo cart data is intentionally NOT added automatically.
    // The cart remains empty until a product is added.
  }

  void _addOrMergeItem(Map<String, dynamic> incoming) {
    final normalized = _normalizeItem(incoming);

    final productId = normalized['productId'].toString();

    final existingIndex = _cartItems.indexWhere(
      (item) => item['productId'].toString() == productId,
    );

    if (existingIndex == -1) {
      _cartItems.add(normalized);
    } else {
      final existing = _cartItems[existingIndex];

      final currentQty = _toInt(existing['quantity'], fallback: 1);
      final incomingQty = _toInt(normalized['quantity'], fallback: 1);
      final maxQty = _availableQuantity(existing);

      existing['quantity'] = _safeQuantity(currentQty + incomingQty, maxQty);
    }
  }

  Map<String, dynamic> _normalizeItem(Map<String, dynamic> item) {
    final copy = Map<String, dynamic>.from(item);

    final productId =
        copy['productId'] ??
        copy['id'] ??
        DateTime.now().microsecondsSinceEpoch.toString();

    final title = copy['title'] ?? copy['name'] ?? 'EcoLoop Product';

    final price = _toDouble(copy['price']);

    final availableQuantity = _toInt(
      copy['availableQuantity'] ?? copy['stock'] ?? copy['quantity'] ?? 10,
      fallback: 10,
    );

    final quantity = _safeQuantity(
      _toInt(copy['quantity'], fallback: 1),
      availableQuantity <= 0 ? 1 : availableQuantity,
    );

    copy['productId'] = productId;
    copy['title'] = title;
    copy['price'] = price;
    copy['quantity'] = quantity;
    copy['availableQuantity'] = availableQuantity <= 0 ? 1 : availableQuantity;

    return copy;
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;

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
    if (value is double) return value;

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

  int _availableQuantity(Map<String, dynamic> item) {
    final available = _toInt(item['availableQuantity'], fallback: 1);

    return available <= 0 ? 1 : available;
  }

  int _safeQuantity(int quantity, int maxQuantity) {
    if (quantity < 1) return 1;

    if (quantity > maxQuantity) {
      return maxQuantity;
    }

    return quantity;
  }

  String _formatPrice(double value) {
    final rounded = value.round();
    return '₹${_formatIndianNumber(rounded)}';
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
    return (item['seller'] ??
            item['sellerName'] ??
            item['sellerUsername'] ??
            'EcoLoop Seller')
        .toString();
  }

  String _condition(Map<String, dynamic> item) {
    return (item['condition'] ?? 'Used').toString();
  }

  String _category(Map<String, dynamic> item) {
    return (item['category'] ?? 'Recycled').toString();
  }

  // ---------------------------------------------------------------------------
  // CALCULATIONS
  // ---------------------------------------------------------------------------

  int get _totalItems {
    int total = 0;

    for (final item in _cartItems) {
      total += _toInt(item['quantity'], fallback: 1);
    }

    return total;
  }

  double get _subtotal {
    double total = 0;

    for (final item in _cartItems) {
      final price = _toDouble(item['price']);
      final quantity = _toInt(item['quantity'], fallback: 1);

      total += price * quantity;
    }

    return total;
  }

  double get _deliveryFee {
    if (_cartItems.isEmpty) {
      return 0;
    }

    // EcoLoop free delivery above ₹999.
    if (_subtotal >= 999) {
      return 0;
    }

    return 49;
  }

  double get _ecoPointDiscount {
    if (!_useEcoPoints) {
      return 0;
    }

    if (_ecoPoints <= 0) {
      return 0;
    }

    // 10 points = ₹1.
    final possibleDiscount = _ecoPoints / 10;

    return possibleDiscount > _subtotal ? _subtotal : possibleDiscount;
  }

  double get _total {
    final value =
        _subtotal - _couponDiscount - _ecoPointDiscount + _deliveryFee;

    return value < 0 ? 0 : value;
  }

  // ---------------------------------------------------------------------------
  // QUANTITY
  // ---------------------------------------------------------------------------

  void _increaseQuantity(int index) {
    if (index < 0 || index >= _cartItems.length) {
      return;
    }

    final item = _cartItems[index];

    final current = _toInt(item['quantity'], fallback: 1);

    final max = _availableQuantity(item);

    if (current >= max) {
      _showMessage('Only $max item${max == 1 ? '' : 's'} available.');
      return;
    }

    setState(() {
      item['quantity'] = current + 1;
    });
  }

  void _decreaseQuantity(int index) {
    if (index < 0 || index >= _cartItems.length) {
      return;
    }

    final item = _cartItems[index];

    final current = _toInt(item['quantity'], fallback: 1);

    if (current <= 1) {
      _confirmRemove(index);
      return;
    }

    setState(() {
      item['quantity'] = current - 1;
    });
  }

  // ---------------------------------------------------------------------------
  // REMOVE
  // ---------------------------------------------------------------------------

  void _confirmRemove(int index) {
    if (index < 0 || index >= _cartItems.length) {
      return;
    }

    final item = _cartItems[index];

    final title = item['title'].toString();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 22),
                const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                  size: 34,
                ),
                const SizedBox(height: 12),
                Text('Remove from cart?', style: AppTextStyles.title),
                const SizedBox(height: 8),
                Text(
                  '"$title" will be removed from your cart.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                        },
                        child: const Text('Keep Item'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _removeItem(index);
                        },
                        child: const Text('Remove'),
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
  }

  void _removeItem(int index) {
    if (index < 0 || index >= _cartItems.length) {
      return;
    }

    final item = _cartItems[index];

    setState(() {
      _cartItems.removeAt(index);
    });

    _recalculateDiscount();

    _showMessage('${item['title']} removed from cart.');
  }

  // ---------------------------------------------------------------------------
  // SAVE FOR LATER
  // ---------------------------------------------------------------------------

  void _saveForLater(int index) {
    if (index < 0 || index >= _cartItems.length) {
      return;
    }

    final item = Map<String, dynamic>.from(_cartItems[index]);

    setState(() {
      _savedForLater.add(item);
      _cartItems.removeAt(index);
    });

    _recalculateDiscount();

    _showMessage('Item saved for later.');
  }

  void _moveBackToCart(int index) {
    if (index < 0 || index >= _savedForLater.length) {
      return;
    }

    final item = Map<String, dynamic>.from(_savedForLater[index]);

    setState(() {
      _savedForLater.removeAt(index);
      _addOrMergeItem(item);
    });

    _showMessage('Item moved back to cart.');
  }

  // ---------------------------------------------------------------------------
  // CLEAR CART
  // ---------------------------------------------------------------------------

  void _clearCart() {
    if (_cartItems.isEmpty) {
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 22),
                const Icon(
                  Icons.remove_shopping_cart_outlined,
                  size: 36,
                  color: AppColors.error,
                ),
                const SizedBox(height: 12),
                Text('Clear your cart?', style: AppTextStyles.title),
                const SizedBox(height: 8),
                Text(
                  'All items currently in your cart will be removed.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                        },
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                        onPressed: () {
                          Navigator.pop(sheetContext);

                          setState(() {
                            _cartItems.clear();
                            _appliedCoupon = null;
                            _couponDiscount = 0;
                            _useEcoPoints = false;
                          });
                        },
                        child: const Text('Clear Cart'),
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
  }

  // ---------------------------------------------------------------------------
  // COUPONS
  // ---------------------------------------------------------------------------

  void _openCoupons() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.light,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.local_offer_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Available Coupons',
                        style: AppTextStyles.title,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _couponTile(
                  sheetContext,
                  code: 'ECO100',
                  title: 'Save ₹100',
                  subtitle: 'Get ₹100 off on orders above ₹1,499',
                  minimumOrder: 1499,
                  discount: 100,
                ),
                const SizedBox(height: 10),
                _couponTile(
                  sheetContext,
                  code: 'FIRSTLOOP',
                  title: '10% OFF',
                  subtitle: '10% off on your first EcoLoop order',
                  minimumOrder: 500,
                  discountPercent: 0.10,
                ),
                const SizedBox(height: 10),
                _couponTile(
                  sheetContext,
                  code: 'RECYCLE20',
                  title: 'Save ₹20',
                  subtitle: 'Flat ₹20 off on orders above ₹499',
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

  Widget _couponTile(
    BuildContext sheetContext, {
    required String code,
    required String title,
    required String subtitle,
    required double minimumOrder,
    double? discount,
    double? discountPercent,
  }) {
    final alreadyApplied = _appliedCoupon == code;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: alreadyApplied ? AppColors.primary : Colors.grey.shade200,
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.light,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        code,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              if (_subtotal < minimumOrder) {
                _showMessage(
                  'Minimum order value is ${_formatPrice(minimumOrder)}.',
                );
                return;
              }

              double calculatedDiscount = 0;

              if (discount != null) {
                calculatedDiscount = discount;
              } else if (discountPercent != null) {
                calculatedDiscount = _subtotal * discountPercent;
              }

              if (calculatedDiscount > _subtotal) {
                calculatedDiscount = _subtotal;
              }

              setState(() {
                _appliedCoupon = code;
                _couponDiscount = calculatedDiscount;
              });

              Navigator.pop(sheetContext);

              _showMessage('$code applied successfully.');
            },
            child: Text(
              alreadyApplied ? 'Applied' : 'Apply',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _removeCoupon() {
    setState(() {
      _appliedCoupon = null;
      _couponDiscount = 0;
    });

    _showMessage('Coupon removed.');
  }

  void _recalculateDiscount() {
    if (_appliedCoupon == null) {
      return;
    }

    if (_appliedCoupon == 'ECO100') {
      if (_subtotal < 1499) {
        _appliedCoupon = null;
        _couponDiscount = 0;
      } else {
        _couponDiscount = 100;
      }
    }

    if (_appliedCoupon == 'FIRSTLOOP') {
      if (_subtotal < 500) {
        _appliedCoupon = null;
        _couponDiscount = 0;
      } else {
        _couponDiscount = _subtotal * 0.10;
      }
    }

    if (_appliedCoupon == 'RECYCLE20') {
      if (_subtotal < 499) {
        _appliedCoupon = null;
        _couponDiscount = 0;
      } else {
        _couponDiscount = 20;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // ECO POINTS
  // ---------------------------------------------------------------------------

  void _toggleEcoPoints() {
    if (_ecoPoints <= 0) {
      _showMessage('You do not have enough Eco Points.');
      return;
    }

    setState(() {
      _useEcoPoints = !_useEcoPoints;
    });
  }

  // ---------------------------------------------------------------------------
  // CHECKOUT
  // ---------------------------------------------------------------------------

  void _proceedToCheckout() {
    if (_cartItems.isEmpty) {
      _showMessage('Your cart is empty.');
      return;
    }

    /*
     * Current Checkout in your project still accepts:
     *
     * Checkout(
     *   product: product,
     *   quantity: quantity,
     * )
     *
     * We therefore pass the first cart item here for the current UI flow.
     *
     * When we update checkout.dart next, it will accept the complete
     * cart list so multiple products can be checked out together.
     */

    final firstItem = Map<String, dynamic>.from(_cartItems.first);

    final quantity = _toInt(firstItem['quantity'], fallback: 1);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Checkout(product: firstItem, quantity: quantity),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MESSAGE
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final hasItems = _cartItems.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
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
            Text('My Cart', style: AppTextStyles.title.copyWith(fontSize: 19)),
            if (hasItems)
              Text(
                '$_totalItems item${_totalItems == 1 ? '' : 's'}',
                style: AppTextStyles.caption,
              ),
          ],
        ),
        actions: [
          if (hasItems)
            IconButton(
              tooltip: 'Clear cart',
              onPressed: _clearCart,
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
          const SizedBox(width: 6),
        ],
      ),
      body: hasItems ? _buildCartContent() : _buildEmptyCart(),
    );
  }

  // ---------------------------------------------------------------------------
  // EMPTY CART
  // ---------------------------------------------------------------------------

  Widget _buildEmptyCart() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 36, 20, 30),
        child: Column(
          children: [
            const SizedBox(height: 25),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.light,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 58,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your cart is empty',
              style: AppTextStyles.heading.copyWith(fontSize: 23),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Looks like you haven’t added anything yet.\n'
              'Explore the marketplace and find something useful.',
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.storefront_outlined),
                label: const Text('Continue Shopping'),
              ),
            ),
            const SizedBox(height: 30),
            _buildEcoMessage(),
            const SizedBox(height: 30),
            _buildSavedForLaterSection(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CART CONTENT
  // ---------------------------------------------------------------------------

  Widget _buildCartContent() {
    return SafeArea(
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFreeDeliveryBanner(),
                const SizedBox(height: 14),
                _buildCartItemsSection(),
                const SizedBox(height: 16),
                _buildCouponCard(),
                const SizedBox(height: 16),
                _buildEcoPointsCard(),
                const SizedBox(height: 16),
                _buildPriceDetails(),
                const SizedBox(height: 18),
                _buildEcoMessage(),
                const SizedBox(height: 22),
                _buildSavedForLaterSection(),
                const SizedBox(height: 24),
                _buildSimilarProducts(),
              ],
            ),
          ),
          _buildBottomCheckoutBar(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FREE DELIVERY BANNER
  // ---------------------------------------------------------------------------

  Widget _buildFreeDeliveryBanner() {
    final remaining = 999 - _subtotal;
    final hasFreeDelivery = _subtotal >= 999;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withOpacity(0.7)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              hasFreeDelivery
                  ? Icons.local_shipping_rounded
                  : Icons.local_shipping_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasFreeDelivery
                      ? 'You unlocked FREE delivery!'
                      : 'Free delivery on orders above ₹999',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hasFreeDelivery
                      ? 'Your order qualifies for free delivery.'
                      : 'Add ${_formatPrice(remaining)} more to unlock it.',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CART ITEMS
  // ---------------------------------------------------------------------------

  Widget _buildCartItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Items in your cart',
              style: AppTextStyles.title.copyWith(fontSize: 18),
            ),
            const Spacer(),
            Text(
              '$_totalItems item${_totalItems == 1 ? '' : 's'}',
              style: AppTextStyles.caption,
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...List.generate(
          _cartItems.length,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildCartItemCard(_cartItems[index], index),
          ),
        ),
      ],
    );
  }

  Widget _buildCartItemCard(Map<String, dynamic> item, int index) {
    final image = _productImage(item);
    final title = item['title'].toString();
    final price = _toDouble(item['price']);
    final quantity = _toInt(item['quantity'], fallback: 1);

    final maxQuantity = _availableQuantity(item);
    final lineTotal = price * quantity;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductImage(image, width: 96, height: 96, radius: 14),
              const SizedBox(width: 12),
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
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _category(item),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: AppColors.textSecondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _condition(item),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Sold by ${_sellerName(item)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatPrice(price),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  _confirmRemove(index);
                },
                icon: const Icon(Icons.close_rounded, size: 20),
                color: AppColors.textSecondary,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('Quantity', style: AppTextStyles.caption),
              const SizedBox(width: 10),
              _buildQuantitySelector(
                quantity: quantity,
                maxQuantity: maxQuantity,
                onDecrease: () {
                  _decreaseQuantity(index);
                },
                onIncrease: () {
                  _increaseQuantity(index);
                },
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Item total', style: AppTextStyles.caption),
                  const SizedBox(height: 2),
                  Text(
                    _formatPrice(lineTotal),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  _saveForLater(index);
                },
                icon: const Icon(Icons.bookmark_border_rounded, size: 18),
                label: const Text('Save for later'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 38),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const Spacer(),
              if (maxQuantity > 1)
                Text('$maxQuantity available', style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // QUANTITY SELECTOR
  // ---------------------------------------------------------------------------

  Widget _buildQuantitySelector({
    required int quantity,
    required int maxQuantity,
    required VoidCallback onDecrease,
    required VoidCallback onIncrease,
  }) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _quantityButton(icon: Icons.remove_rounded, onPressed: onDecrease),
          SizedBox(
            width: 32,
            child: Center(
              child: Text(
                '$quantity',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          _quantityButton(
            icon: Icons.add_rounded,
            onPressed: quantity >= maxQuantity ? null : onIncrease,
          ),
        ],
      ),
    );
  }

  Widget _quantityButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: 34,
      height: 36,
      child: IconButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        iconSize: 17,
        splashRadius: 18,
        icon: Icon(icon),
        color: onPressed == null ? Colors.grey.shade400 : AppColors.primary,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // COUPON CARD
  // ---------------------------------------------------------------------------

  Widget _buildCouponCard() {
    final hasCoupon = _appliedCoupon != null;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.light,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_offer_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasCoupon ? 'Coupon applied' : 'Have a coupon?',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasCoupon
                          ? '$_appliedCoupon • ${_formatPrice(_couponDiscount)} saved'
                          : 'Apply an offer and save more',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              if (hasCoupon)
                TextButton(
                  onPressed: _removeCoupon,
                  child: const Text(
                    'Remove',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                TextButton(
                  onPressed: _openCoupons,
                  child: const Text(
                    'View',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          if (!hasCoupon) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _openCoupons,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 11,
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
                      size: 19,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'View available coupons',
                        style: AppTextStyles.body.copyWith(fontSize: 13),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
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

  // ---------------------------------------------------------------------------
  // ECO POINTS
  // ---------------------------------------------------------------------------

  Widget _buildEcoPointsCard() {
    final discount = _ecoPointDiscount;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withOpacity(0.8)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.eco_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
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
                  '${discount > 0 ? ' • Save ${_formatPrice(discount)}' : ''}',
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

  // ---------------------------------------------------------------------------
  // PRICE DETAILS
  // ---------------------------------------------------------------------------

  Widget _buildPriceDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price Details',
            style: AppTextStyles.title.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 15),
          _priceRow(
            'Price ($_totalItems item${_totalItems == 1 ? '' : 's'})',
            _formatPrice(_subtotal),
          ),
          if (_couponDiscount > 0) ...[
            const SizedBox(height: 10),
            _priceRow(
              'Coupon discount',
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
            'Delivery',
            _deliveryFee == 0 ? 'FREE' : _formatPrice(_deliveryFee),
            valueColor: _deliveryFee == 0
                ? AppColors.success
                : AppColors.textPrimary,
          ),
          const SizedBox(height: 14),
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 13),
          _priceRow(
            'Total Amount',
            _formatPrice(_total),
            bold: true,
            valueSize: 17,
          ),
          if (_couponDiscount + _ecoPointDiscount > 0) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'You saved ${_formatPrice(_couponDiscount + _ecoPointDiscount)}',
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
    double valueSize = 14,
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

  // ---------------------------------------------------------------------------
  // ECO MESSAGE
  // ---------------------------------------------------------------------------

  Widget _buildEcoMessage() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.eco_outlined, color: AppColors.primary, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your purchase helps the planet',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Every reused item keeps useful materials away from waste and gives them another life.',
                  style: AppTextStyles.caption.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SAVED FOR LATER
  // ---------------------------------------------------------------------------

  Widget _buildSavedForLaterSection() {
    if (_savedForLater.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Saved for later',
              style: AppTextStyles.title.copyWith(fontSize: 18),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.light,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_savedForLater.length}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...List.generate(
          _savedForLater.length,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildSavedItem(_savedForLater[index], index),
          ),
        ),
      ],
    );
  }

  Widget _buildSavedItem(Map<String, dynamic> item, int index) {
    final image = _productImage(item);
    final title = item['title'].toString();
    final price = _toDouble(item['price']);

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          _buildProductImage(image, width: 70, height: 70, radius: 12),
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
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
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
          TextButton(
            onPressed: () {
              _moveBackToCart(index);
            },
            child: const Text(
              'Move to Cart',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SIMILAR PRODUCTS
  // ---------------------------------------------------------------------------

  Widget _buildSimilarProducts() {
    final products = [
      {
        'productId': 'cart_sim_1',
        'title': 'Recycled Glass Decor',
        'price': 650,
        'category': 'Decor',
        'condition': 'Recycled',
        'seller': 'Neha',
        'image': '',
      },
      {
        'productId': 'cart_sim_2',
        'title': 'Craft Wood Pieces',
        'price': 450,
        'category': 'Materials',
        'condition': 'Recycled',
        'seller': 'EcoCraft',
        'image': '',
      },
      {
        'productId': 'cart_sim_3',
        'title': 'Upcycled Bottle Lamp',
        'price': 899,
        'category': 'Decor',
        'condition': 'Upcycled',
        'seller': 'Priya',
        'image': '',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'You may also like',
          style: AppTextStyles.title.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 5),
        Text('More useful finds from EcoLoop', style: AppTextStyles.caption),
        const SizedBox(height: 12),
        SizedBox(
          height: 230,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return _buildSimilarProductCard(products[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSimilarProductCard(Map<String, dynamic> product) {
    final image = _productImage(product);
    final title = product['title'].toString();
    final price = _toDouble(product['price']);

    return Container(
      width: 175,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProductImage(image, width: 175, height: 125, radius: 0),
          Padding(
            padding: const EdgeInsets.fromLTRB(11, 9, 11, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
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
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PRODUCT IMAGE
  // ---------------------------------------------------------------------------

  Widget _buildProductImage(
    String image, {
    required double width,
    required double height,
    required double radius,
  }) {
    if (image.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.network(
          image,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return _imagePlaceholder(width, height, radius);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }

            return _imagePlaceholder(width, height, radius, loading: true);
          },
        ),
      );
    }

    return _imagePlaceholder(width, height, radius);
  }

  Widget _imagePlaceholder(
    double width,
    double height,
    double radius, {
    bool loading = false,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(radius),
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
                size: 34,
                color: AppColors.secondary,
              ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BOTTOM CHECKOUT BAR
  // ---------------------------------------------------------------------------

  Widget _buildBottomCheckoutBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                      _formatPrice(_total),
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (_deliveryFee == 0)
                      const Text(
                        'Free delivery',
                        style: TextStyle(
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
                    onPressed: _proceedToCheckout,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Proceed to Checkout'),
                        const SizedBox(width: 7),
                        const Icon(Icons.arrow_forward_rounded, size: 19),
                      ],
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
}
