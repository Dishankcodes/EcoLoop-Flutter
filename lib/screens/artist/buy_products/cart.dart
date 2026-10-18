import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import '../../../services/ecoloop_api.dart';
import '../../../widgets/cart_popup_artist.dart';
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
  List<Map<String, dynamic>> _similarProducts = [];
  bool _similarProductsLoading = false;
  String? _similarProductsError;

  String? _appliedCoupon;
  double _couponDiscount = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialItems();
    _syncGlobalCart();
    _loadSimilarProducts();
  }

  // INITIAL DATA

  void _loadInitialItems() {
    final incoming = widget.initialItems ?? [];

    for (final item in incoming) {
      _addOrMergeItem(item);
    }
  }

  void _syncGlobalCart() {
    CartPopup.replaceItems(_cartItems);
  }

  Future<void> _loadSimilarProducts() async {
    if (mounted) {
      setState(() {
        _similarProductsLoading = true;
        _similarProductsError = null;
      });
    }

    try {
      final response = await EcoLoopApi.instance.get('/products');
      if (response is! List) {
        throw const EcoLoopApiException(
          'The products response has an unexpected format.',
        );
      }

      final products = response
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .where((item) {
            final status = (item['status'] ?? 'published')
                .toString()
                .toLowerCase();
            final available = _toInt(
              item['availableQuantity'] ?? item['quantity'],
              fallback: 0,
            );
            return status == 'published' && available > 0;
          })
          .toList();

      final cartIds = _cartItems
          .map((item) => item['productId'].toString())
          .toSet();
      final savedIds = _savedForLater
          .map((item) => item['productId'].toString())
          .toSet();

      products.removeWhere((product) {
        final id = (product['productId'] ?? product['id'] ?? '').toString();
        return id.isEmpty || cartIds.contains(id) || savedIds.contains(id);
      });

      final categoryId = _cartItems.isNotEmpty
          ? _toInt(_cartItems.first['categoryId'], fallback: -1)
          : -1;

      if (categoryId > 0) {
        products.sort((a, b) {
          final aMatch = _toInt(a['categoryId'], fallback: -1) == categoryId;
          final bMatch = _toInt(b['categoryId'], fallback: -1) == categoryId;
          if (aMatch == bMatch) return 0;
          return aMatch ? -1 : 1;
        });
      }

      if (!mounted) return;
      setState(() {
        _similarProducts = products.take(10).toList();
        _similarProductsLoading = false;
        _similarProductsError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _similarProducts = [];
        _similarProductsLoading = false;
        _similarProductsError = error.toString();
      });
    }
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

    final title =
        copy['title'] ??
        copy['productName'] ??
        copy['name'] ??
        'EcoLoop Product';

    final price = _toDouble(copy['price']);

    final availableQuantity = _toInt(
      copy['availableQuantity'] ?? copy['stock'] ?? copy['quantity'] ?? 0,
      fallback: 0,
    );

    final quantity = _safeQuantity(
      _toInt(copy['quantity'], fallback: 1),
      availableQuantity <= 0 ? 1 : availableQuantity,
    );

    copy['productId'] = productId;
    copy['title'] = title;
    copy['price'] = price;
    copy['quantity'] = quantity;
    copy['availableQuantity'] = availableQuantity;

    return copy;
  }

  // HELPERS

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
    final available = _toInt(item['availableQuantity'], fallback: 0);

    return available < 0 ? 0 : available;
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

  // CALCULATIONS

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

    if (_subtotal >= 999) {
      return 0;
    }

    return 49;
  }

  // Coupons are not discounted locally unless the backend validates them.
  // Keep the visible coupon entry point, but never show a fake discount.
  double get _total => _subtotal + _deliveryFee;

  // QUANTITY

  void _increaseQuantity(int index) {
    if (index < 0 || index >= _cartItems.length) {
      return;
    }

    final item = _cartItems[index];

    final current = _toInt(item['quantity'], fallback: 1);

    final max = _availableQuantity(item);

    if (max <= 0) {
      _showMessage('Stock must be refreshed before changing this quantity.');
      return;
    }

    if (current >= max) {
      _showMessage('Only $max item${max == 1 ? '' : 's'} available.');
      return;
    }

    setState(() {
      item['quantity'] = current + 1;
    });
    _syncGlobalCart();
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
    _syncGlobalCart();
  }

  // REMOVE

  void _confirmRemove(int index) {
    if (index < 0 || index >= _cartItems.length) {
      return;
    }

    final item = _cartItems[index];

    final title = item['title'].toString();

    showModalBottomSheet(
      context: context,
      backgroundColor: ArtistColors.surface,
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
                  color: ArtistColors.error,
                  size: 34,
                ),
                const SizedBox(height: 12),
                Text('Remove from cart?', style: ArtistTextStyles.title),
                const SizedBox(height: 8),
                Text(
                  '"$title" will be removed from your cart.',
                  textAlign: TextAlign.center,
                  style: ArtistTextStyles.body,
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
                          backgroundColor: ArtistColors.error,
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
    _syncGlobalCart();

    _showMessage('${item['title']} removed from cart.');
  }

  // SAVE FOR LATER

  void _saveForLater(int index) {
    if (index < 0 || index >= _cartItems.length) {
      return;
    }

    final item = Map<String, dynamic>.from(_cartItems[index]);

    setState(() {
      _savedForLater.add(item);
      _cartItems.removeAt(index);
    });
    _syncGlobalCart();

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
    _syncGlobalCart();

    _showMessage('Item moved back to cart.');
  }

  // CLEAR CART

  void _clearCart() {
    if (_cartItems.isEmpty) {
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: ArtistColors.surface,
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
                  color: ArtistColors.error,
                ),
                const SizedBox(height: 12),
                Text('Clear your cart?', style: ArtistTextStyles.title),
                const SizedBox(height: 8),
                Text(
                  'All items currently in your cart will be removed.',
                  textAlign: TextAlign.center,
                  style: ArtistTextStyles.body,
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
                          backgroundColor: ArtistColors.error,
                        ),
                        onPressed: () {
                          Navigator.pop(sheetContext);

                          setState(() {
                            _cartItems.clear();
                            _appliedCoupon = null;
                            _couponDiscount = 0;
                          });
                          CartPopup.clear();
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

  // COUPONS

  void _openCoupons() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ArtistColors.surface,
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
                        color: ArtistColors.light,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.local_offer_outlined,
                        color: ArtistColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Available Coupons',
                        style: ArtistTextStyles.title,
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
        color: ArtistColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: alreadyApplied ? ArtistColors.primary : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: ArtistColors.light,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.confirmation_num_outlined,
              color: ArtistColors.primary,
            ),
          ),
          const SizedBox(width: 12),
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
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: ArtistColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: ArtistColors.light,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        code,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: ArtistColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: ArtistTextStyles.caption),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              Navigator.pop(sheetContext);
              _showMessage(
                'Coupon redemption is not connected yet. No discount has been applied.',
              );
            },
            child: Text(
              alreadyApplied ? 'Applied' : 'Apply',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: ArtistColors.primary,
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

  // CHECKOUT

  void _proceedToCheckout() {
    if (_cartItems.isEmpty) {
      _showMessage('Your cart is empty.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            Checkout(items: List<Map<String, dynamic>>.from(_cartItems)),
      ),
    );
  }

  // MESSAGE

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

  // BUILD

  @override
  Widget build(BuildContext context) {
    final hasItems = _cartItems.isNotEmpty;

    return Scaffold(
      backgroundColor: ArtistColors.background,
      appBar: AppBar(
        backgroundColor: ArtistColors.surface,
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
            Text(
              'My Cart',
              style: ArtistTextStyles.title.copyWith(fontSize: 19),
            ),
            if (hasItems)
              Text(
                '$_totalItems item${_totalItems == 1 ? '' : 's'}',
                style: ArtistTextStyles.caption,
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

  // EMPTY CART

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
              decoration: const BoxDecoration(
                color: ArtistColors.light,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 58,
                color: ArtistColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your cart is empty',
              style: ArtistTextStyles.heading.copyWith(fontSize: 23),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Looks like you haven’t added anything yet.\n'
              'Explore the marketplace and find something useful.',
              style: ArtistTextStyles.body,
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: ArtistColors.primary,
                  foregroundColor: Colors.white,
                  textStyle: ArtistTextStyles.button,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
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

  // CART CONTENT

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

  // FREE DELIVERY BANNER

  Widget _buildFreeDeliveryBanner() {
    final remaining = 999 - _subtotal;
    final hasFreeDelivery = _subtotal >= 999;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ArtistColors.light,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ArtistColors.accent.withOpacity(0.7)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: ArtistColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              hasFreeDelivery
                  ? Icons.local_shipping_rounded
                  : Icons.local_shipping_outlined,
              color: ArtistColors.primary,
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
                    color: ArtistColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hasFreeDelivery
                      ? 'Your order qualifies for free delivery.'
                      : 'Add ${_formatPrice(remaining)} more to unlock it.',
                  style: ArtistTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // CART ITEMS

  Widget _buildCartItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Items in your cart',
              style: ArtistTextStyles.title.copyWith(fontSize: 18),
            ),
            const Spacer(),
            Text(
              '$_totalItems item${_totalItems == 1 ? '' : 's'}',
              style: ArtistTextStyles.caption,
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
        color: ArtistColors.surface,
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
                        color: ArtistColors.textPrimary,
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
                            style: ArtistTextStyles.caption,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: ArtistColors.textSecondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _condition(item),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ArtistTextStyles.caption,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Sold by ${_sellerName(item)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ArtistTextStyles.caption,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatPrice(price),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: ArtistColors.textPrimary,
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
                color: ArtistColors.textSecondary,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                'Qty',
                style: TextStyle(
                  fontSize: 12,
                  color: ArtistColors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
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
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Item total',
                      style: ArtistTextStyles.caption.copyWith(fontSize: 10),
                    ),
                    Text(
                      _formatPrice(lineTotal),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: ArtistColors.textPrimary,
                      ),
                    ),
                  ],
                ),
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
                icon: const Icon(Icons.bookmark_border_rounded, size: 16),
                label: const Text(
                  'Save for later',
                  style: TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const Spacer(),
              if (maxQuantity > 1)
                Text(
                  '$maxQuantity available',
                  style: ArtistTextStyles.caption.copyWith(fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // QUANTITY SELECTOR

  Widget _buildQuantitySelector({
    required int quantity,
    required int maxQuantity,
    required VoidCallback onDecrease,
    required VoidCallback onIncrease,
  }) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: ArtistColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _quantityButton(icon: Icons.remove_rounded, onPressed: onDecrease),
          SizedBox(
            width: 28,
            child: Center(
              child: Text(
                '$quantity',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: ArtistColors.textPrimary,
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
      width: 28,
      height: 34,
      child: IconButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        iconSize: 15,
        splashRadius: 16,
        icon: Icon(icon),
        color: onPressed == null ? Colors.grey.shade400 : ArtistColors.primary,
      ),
    );
  }

  // COUPON CARD

  Widget _buildCouponCard() {
    final hasCoupon = _appliedCoupon != null;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
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
                  color: ArtistColors.light,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_offer_outlined,
                  color: ArtistColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasCoupon ? 'Coupon selected' : 'Have a coupon?',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ArtistColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasCoupon
                          ? '$_appliedCoupon • validation pending'
                          : 'View available offers',
                      style: ArtistTextStyles.caption,
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
                      color: ArtistColors.error,
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
                      color: ArtistColors.primary,
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
                  color: ArtistColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.confirmation_num_outlined,
                      size: 19,
                      color: ArtistColors.textSecondary,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'View available coupons',
                        style: ArtistTextStyles.body.copyWith(fontSize: 13),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: ArtistColors.textSecondary,
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

  // ECO POINTS

  // PRICE DETAILS

  Widget _buildPriceDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price Details',
            style: ArtistTextStyles.title.copyWith(fontSize: 18),
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
              valueColor: ArtistColors.success,
            ),
          ],
          const SizedBox(height: 10),
          _priceRow(
            'Delivery',
            _deliveryFee == 0 ? 'FREE' : _formatPrice(_deliveryFee),
            valueColor: _deliveryFee == 0
                ? ArtistColors.success
                : ArtistColors.textPrimary,
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
              color: bold
                  ? ArtistColors.textPrimary
                  : ArtistColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: valueSize,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: valueColor ?? ArtistColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // ECO MESSAGE

  Widget _buildEcoMessage() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ArtistColors.light,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.eco_outlined, color: ArtistColors.primary, size: 24),
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
                    color: ArtistColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Every reused item keeps useful materials away from waste and gives them another life.',
                  style: ArtistTextStyles.caption.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // SAVED FOR LATER

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
              style: ArtistTextStyles.title.copyWith(fontSize: 18),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: ArtistColors.light,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_savedForLater.length}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: ArtistColors.primary,
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
        color: ArtistColors.surface,
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
                    color: ArtistColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _formatPrice(price),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: ArtistColors.textPrimary,
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

  // SIMILAR PRODUCTS

  Widget _buildSimilarProducts() {
    final cartIds = _cartItems
        .map((item) => item['productId'].toString())
        .toSet();
    final savedIds = _savedForLater
        .map((item) => item['productId'].toString())
        .toSet();
    final products = _similarProducts.where((product) {
      final id = (product['productId'] ?? product['id'] ?? '').toString();
      return id.isNotEmpty && !cartIds.contains(id) && !savedIds.contains(id);
    }).toList();

    if (_similarProductsLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You may also like',
            style: ArtistTextStyles.title.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 5),
          Text(
            'More useful finds from EcoLoop',
            style: ArtistTextStyles.caption,
          ),
          const SizedBox(height: 16),
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: ArtistColors.primary),
            ),
          ),
        ],
      );
    }

    if (_similarProductsError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You may also like',
            style: ArtistTextStyles.title.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 5),
          Text(
            'More useful finds from EcoLoop',
            style: ArtistTextStyles.caption,
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ArtistColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  color: ArtistColors.textSecondary,
                  size: 28,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Could not load recommendations.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ArtistColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _loadSimilarProducts,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (products.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'You may also like',
          style: ArtistTextStyles.title.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 5),
        Text('More useful finds from EcoLoop', style: ArtistTextStyles.caption),
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
    final title = (product['title'] ?? product['name'] ?? 'EcoLoop Product')
        .toString();
    final price = _toDouble(product['price']);

    return Container(
      width: 175,
      decoration: BoxDecoration(
        color: ArtistColors.surface,
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
                    color: ArtistColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _formatPrice(price),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: ArtistColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // PRODUCT IMAGE

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
        color: ArtistColors.light,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: ArtistColors.primary,
                ),
              )
            : const Icon(
                Icons.image_outlined,
                size: 34,
                color: ArtistColors.secondary,
              ),
      ),
    );
  }

  // BOTTOM CHECKOUT BAR

  Widget _buildBottomCheckoutBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: ArtistColors.surface,
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
                    Text('Total', style: ArtistTextStyles.caption),
                    const SizedBox(height: 2),
                    Text(
                      _formatPrice(_total),
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: ArtistColors.textPrimary,
                      ),
                    ),
                    if (_deliveryFee == 0)
                      const Text(
                        'Free delivery',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: ArtistColors.success,
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
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Proceed to Checkout'),
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
}
