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
  List<Map<String, dynamic>> _similarProducts = [];
  bool _similarProductsLoading = false;
  String? _similarProductsError;

  String? _appliedCoupon;
  double _couponDiscount = 0;

  final EcoLoopApi _api = EcoLoopApi.instance;
  bool _cartLoading = true;
  bool _cartBusy = false;
  String? _cartError;

  @override
  void initState() {
    super.initState();
    // The account-scoped backend cart is authoritative. Do not merge the
    // popup's initial snapshot again: /cart already contains that item and
    // merging it here would silently double the quantity.
    // These requests are independent. Start them together so the cart screen
    // does not wait for the cart request to finish before loading suggestions.
    _loadCart();
    _loadSimilarProducts();
  }

  // PERSISTENT CART

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _extractCartRows(dynamic response) {
    if (response is List) {
      return response.whereType<Map>().map(_asMap).toList();
    }
    final root = _asMap(response);
    final data = root['data'];
    if (data is List) return data.whereType<Map>().map(_asMap).toList();
    if (data is Map) {
      for (final key in ['items', 'cart', 'products', 'results']) {
        final rows = data[key];
        if (rows is List) return rows.whereType<Map>().map(_asMap).toList();
      }
    }
    for (final key in ['items', 'cart', 'products', 'results']) {
      final rows = root[key];
      if (rows is List) return rows.whereType<Map>().map(_asMap).toList();
    }
    return <Map<String, dynamic>>[];
  }

  Future<void> _loadCart({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() {
        // Keep the existing cart visible during refreshes.
        _cartLoading = _cartItems.isEmpty;
        _cartError = null;
      });
    }
    try {
      final response = await _api.get('/cart');
      final rows = _extractCartRows(response);
      final active = <Map<String, dynamic>>[];
      for (final row in rows) {
        final item = _normalizeItem(row);
        active.add(item);
      }
      if (!mounted) return;
      setState(() {
        _cartItems
          ..clear()
          ..addAll(active);
        _cartLoading = false;
        _cartError = null;
      });
      _syncGlobalCart();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _cartLoading = false;
        // Do not replace a usable, already-loaded cart with an error screen.
        _cartError = _cartItems.isEmpty ? error.toString() : null;
      });
      // Keep any already-visible items if refresh fails, but do not pretend
      // that a backend mutation succeeded.
      if (_cartItems.isEmpty && (widget.initialItems?.isNotEmpty ?? false)) {
        setState(() {
          for (final item in widget.initialItems!) {
            _addOrMergeItem(item);
          }
        });
        _syncGlobalCart();
      }
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
      final rawProducts = response is List
          ? response
          : response is Map && response['products'] is List
          ? response['products'] as List
          : response is Map && response['data'] is List
          ? response['data'] as List
          : const <dynamic>[];
      if (rawProducts.isEmpty && response is! List && response is! Map) {
        throw const EcoLoopApiException(
          'The products response has an unexpected format.',
        );
      }

      final products = rawProducts
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
      products.removeWhere((product) {
        final id = (product['productId'] ?? product['id'] ?? '').toString();
        return id.isEmpty || cartIds.contains(id);
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
        _similarProducts = products.take(4).toList();
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
        copy['productId'] ?? copy['product_id'] ?? copy['id'] ?? '';
    final title =
        copy['title'] ??
        copy['productName'] ??
        copy['product_name'] ??
        copy['name'] ??
        'EcoLoop Product';
    final price = _toDouble(
      copy['price'] ?? copy['unitPrice'] ?? copy['unit_price'],
    );
    final availableQuantity = _toInt(
      copy['availableQuantity'] ??
          copy['available_quantity'] ??
          copy['stock'] ??
          copy['quantityAvailable'] ??
          0,
      fallback: 0,
    );
    final requestedQuantity = _toInt(copy['quantity'], fallback: 1);
    final quantity = availableQuantity > 0
        ? _safeQuantity(requestedQuantity, availableQuantity)
        : (requestedQuantity < 1 ? 1 : requestedQuantity);

    copy['productId'] = productId.toString();
    copy['id'] = copy['id'] ?? productId;
    copy['title'] = title;
    copy['price'] = price;
    copy['quantity'] = quantity;
    copy['availableQuantity'] = availableQuantity;
    copy['image'] ??=
        copy['imageUrl'] ??
        copy['image_url'] ??
        copy['thumbnail'] ??
        ((copy['imageUrls'] is List && (copy['imageUrls'] as List).isNotEmpty)
            ? (copy['imageUrls'] as List).first
            : null) ??
        ((copy['images'] is List && (copy['images'] as List).isNotEmpty)
            ? (copy['images'] as List).first
            : null);
    copy['seller'] ??=
        copy['sellerName'] ??
        copy['sellerUsername'] ??
        copy['userName'] ??
        'EcoLoop Seller';
    copy['category'] ??= copy['categoryName'] ?? 'Recycled';

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

    if (maxQuantity > 0 && quantity > maxQuantity) {
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
    for (final key in [
      'image',
      'imageUrl',
      'image_url',
      'thumbnail',
      'primaryImage',
      'primary_image',
    ]) {
      final value = item[key];
      if (value is String && value.trim().startsWith('http'))
        return value.trim();
    }
    for (final key in ['imageUrls', 'image_urls', 'images']) {
      final value = item[key];
      if (value is List) {
        for (final entry in value) {
          final url = entry.toString().trim();
          if (url.startsWith('http')) return url;
        }
      } else if (value is String && value.trim().isNotEmpty) {
        final match = RegExp(r'https?://[^\s,\]"}]+').firstMatch(value.trim());
        if (match != null) return match.group(0)!;
      }
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

  // Delivery is calculated authoritatively in checkout after the selected
  // address and each seller's city are known. Do not invent a cart-level fee.
  double get _deliveryFee => 0;

  // Coupons are not discounted locally unless the backend validates them.
  // Keep the visible coupon entry point, but never show a fake discount.
  double get _total => (_subtotal - _couponDiscount + _deliveryFee)
      .clamp(0, double.infinity)
      .toDouble();

  void _recalculateCartCoupon() {
    final code = _appliedCoupon;
    if (code == null) return;
    final minimum = switch (code) {
      'RECYCLE20' => 499.0,
      'LOOP50' => 999.0,
      'ECO100' => 1599.0,
      _ => double.infinity,
    };
    if (_subtotal < minimum) {
      _appliedCoupon = null;
      _couponDiscount = 0;
      _showMessage(
        'Coupon removed because the cart no longer meets its minimum subtotal.',
      );
      return;
    }
    _couponDiscount = switch (code) {
      'RECYCLE20' => 20.0,
      'LOOP50' => 50.0,
      'ECO100' => 100.0,
      _ => 0.0,
    }.clamp(0, _subtotal).toDouble();
  }

  // QUANTITY

  Future<void> _setQuantity(int index, int quantity) async {
    if (_cartBusy || index < 0 || index >= _cartItems.length) return;
    final item = _cartItems[index];
    final productId = (item['productId'] ?? item['id'] ?? '').toString();
    if (productId.isEmpty || int.tryParse(productId) == null) {
      _showMessage(
        'This product has an invalid ID. Refresh the cart and try again.',
      );
      return;
    }
    final max = _availableQuantity(item);
    if (max > 0 && quantity > max) {
      _showMessage('Only $max item${max == 1 ? '' : 's'} available.');
      return;
    }
    setState(() => _cartBusy = true);
    try {
      await _api.put('/cart/$productId', <String, dynamic>{
        'quantity': quantity,
      });
      if (!mounted) return;
      setState(() {
        item['quantity'] = quantity;
        _recalculateCartCoupon();
      });
      _syncGlobalCart();
    } catch (error) {
      _showMessage(_friendlyError(error));
      await _loadCart(showLoader: false);
    } finally {
      if (mounted) setState(() => _cartBusy = false);
    }
  }

  Future<void> _increaseQuantity(int index) async {
    if (index < 0 || index >= _cartItems.length) return;
    final item = _cartItems[index];
    final current = _toInt(item['quantity'], fallback: 1);
    final max = _availableQuantity(item);
    if (max <= 0) {
      _showMessage(
        'This item is unavailable. Refresh the cart to check stock.',
      );
      return;
    }
    if (current >= max) {
      _showMessage('Only $max item${max == 1 ? '' : 's'} available.');
      return;
    }
    await _setQuantity(index, current + 1);
  }

  Future<void> _decreaseQuantity(int index) async {
    if (index < 0 || index >= _cartItems.length) return;
    final current = _toInt(_cartItems[index]['quantity'], fallback: 1);
    if (current <= 1) {
      _confirmRemove(index);
      return;
    }
    await _setQuantity(index, current - 1);
  }

  String _friendlyError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    return message.isEmpty
        ? 'Unable to update your cart. Please try again.'
        : message;
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

  Future<void> _removeItem(int index) async {
    if (_cartBusy || index < 0 || index >= _cartItems.length) return;
    final item = _cartItems[index];
    final productId = (item['productId'] ?? item['id'] ?? '').toString();
    if (productId.isEmpty || int.tryParse(productId) == null) {
      _showMessage(
        'This product has an invalid ID. Refresh the cart and try again.',
      );
      return;
    }
    setState(() => _cartBusy = true);
    try {
      await _api.delete('/cart/$productId');
      if (!mounted) return;
      setState(() {
        _cartItems.removeWhere(
          (row) => (row['productId'] ?? row['id']).toString() == productId,
        );
        _recalculateCartCoupon();
      });
      _syncGlobalCart();
      _showMessage('${item['title']} removed from cart.');
    } catch (error) {
      _showMessage(_friendlyError(error));
      await _loadCart(showLoader: false);
    } finally {
      if (mounted) setState(() => _cartBusy = false);
    }
  }

  // CLEAR CART

  void _clearCart() {
    if (_cartItems.isEmpty || _cartBusy) {
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
                          _clearCartOnServer();
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

  Future<void> _clearCartOnServer() async {
    if (_cartBusy || _cartItems.isEmpty) return;
    setState(() => _cartBusy = true);
    try {
      await _api.post('/cart/clear', <String, dynamic>{});
      if (!mounted) return;
      setState(() {
        _cartItems.clear();
        _appliedCoupon = null;
        _couponDiscount = 0;
      });
      _syncGlobalCart();
      _showMessage('Cart cleared.');
    } catch (error) {
      _showMessage(_friendlyError(error));
      await _loadCart(showLoader: false);
    } finally {
      if (mounted) setState(() => _cartBusy = false);
    }
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
                  code: 'RECYCLE20',
                  title: 'Save ₹20',
                  subtitle: '₹20 off on orders of ₹499 or more',
                  minimumOrder: 499,
                  discount: 20,
                ),
                const SizedBox(height: 10),
                _couponTile(
                  sheetContext,
                  code: 'LOOP50',
                  title: 'Save ₹50',
                  subtitle: '₹50 off on orders of ₹999 or more',
                  minimumOrder: 999,
                  discount: 50,
                ),
                const SizedBox(height: 10),
                _couponTile(
                  sheetContext,
                  code: 'ECO100',
                  title: 'Save ₹100',
                  subtitle: '₹100 off on orders of ₹1,599 or more',
                  minimumOrder: 1599,
                  discount: 100,
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
                if (_subtotal < minimumOrder) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Add ${_formatPrice(minimumOrder - _subtotal)} more to use this coupon',
                    style: ArtistTextStyles.caption,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: alreadyApplied
                ? null
                : () {
                    if (_subtotal < minimumOrder) {
                      _showMessage(
                        'Add ${_formatPrice(minimumOrder - _subtotal)} more to use $code.',
                      );
                      return;
                    }
                    setState(() {
                      _appliedCoupon = code;
                      _couponDiscount = (discount ?? 0)
                          .clamp(0, _subtotal)
                          .toDouble();
                    });
                    Navigator.pop(sheetContext);
                    _showMessage(
                      '$code applied. You save ${_formatPrice(_couponDiscount)}.',
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
        builder: (_) => Checkout(
          items: List<Map<String, dynamic>>.from(_cartItems),
          initialCouponCode: _appliedCoupon,
          initialCouponDiscount: _couponDiscount,
        ),
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
          if (_cartItems.isNotEmpty)
            IconButton(
              tooltip: 'Clear cart',
              onPressed: _clearCart,
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
          const SizedBox(width: 6),
        ],
      ),
      body: _cartLoading
          ? const Center(
              child: CircularProgressIndicator(color: ArtistColors.primary),
            )
          : _cartError != null && _cartItems.isEmpty
          ? _buildCartError()
          : hasItems
          ? _buildCartContent()
          : _buildEmptyCart(),
    );
  }

  // EMPTY CART

  Widget _buildCartError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 42,
              color: ArtistColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text('Could not load your cart', style: ArtistTextStyles.title),
            const SizedBox(height: 8),
            Text(
              _friendlyError(Exception(_cartError ?? 'Please try again.')),
              textAlign: TextAlign.center,
              style: ArtistTextStyles.body,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _loadCart(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

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
                _buildDeliveryNote(),
                const SizedBox(height: 14),
                _buildCartItemsSection(),
                const SizedBox(height: 16),
                _buildCouponCard(),
                const SizedBox(height: 16),
                _buildPriceDetails(),
                const SizedBox(height: 18),
                _buildEcoMessage(),
                const SizedBox(height: 22),
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

  // Delivery is determined at checkout from the selected address and seller city.
  Widget _buildDeliveryNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ArtistColors.light,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ArtistColors.accent.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_shipping_outlined,
            color: ArtistColors.primary,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivery charges calculated at checkout',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ArtistColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Standard delivery is ₹40 per seller when the seller is in a different city. Final charges depend on your address.',
                  style: ArtistTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ECO POINTS

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
            'Calculated at checkout',
            valueColor: ArtistColors.textSecondary,
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

  // SIMILAR PRODUCTS

  Widget _buildSimilarProducts() {
    final cartIds = _cartItems
        .map((item) => item['productId'].toString())
        .toSet();
    final products = _similarProducts
        .where((product) {
          final id = (product['productId'] ?? product['id'] ?? '').toString();
          return id.isNotEmpty && !cartIds.contains(id);
        })
        .take(4)
        .toList();

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
            separatorBuilder: (_, _) => const SizedBox(width: 12),
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
          errorBuilder: (context, error, stackTrace) {
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
    Widget totalSummary() {
      return Column(
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
          const Text(
            'Delivery at checkout',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: ArtistColors.textSecondary,
            ),
          ),
        ],
      );
    }

    Widget checkoutButton() {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _cartBusy ? null : _proceedToCheckout,
          style: ElevatedButton.styleFrom(
            backgroundColor: ArtistColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: ArtistColors.primary.withValues(
              alpha: 0.55,
            ),
            disabledForegroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            textStyle: ArtistTextStyles.button.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  'Proceed to Checkout',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(width: 7),
              Icon(Icons.arrow_forward_rounded, size: 18),
            ],
          ),
        ),
      );
    }

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
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 18,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 340) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    totalSummary(),
                    const SizedBox(height: 10),
                    checkoutButton(),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: totalSummary()),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: checkoutButton()),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
