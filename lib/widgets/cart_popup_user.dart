import 'dart:async';

import 'package:flutter/material.dart';

import '../app_theme/user/app_colors.dart';
import '../app_theme/user/app_text_styles.dart';
import '../screens/user/buy_products/cart.dart';
import '../screens/user/buy_products/checkout.dart';

class CartPopup {
  CartPopup._();

  static OverlayEntry? _currentEntry;

  static NavigatorState? _navigatorState;

  static bool _navigationInProgress = false;

  static final List<Map<String, dynamic>> _cartItems = [];

  static List<Map<String, dynamic>> get items {
    return _cartItems.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  static bool get isEmpty => _cartItems.isEmpty;

  static int get totalItems {
    var total = 0;

    for (final item in _cartItems) {
      total += _toInt(item['quantity'], fallback: 1);
    }

    return total;
  }

  static double get totalAmount {
    var total = 0.0;

    for (final item in _cartItems) {
      final price = _toDouble(item['price']);
      final quantity = _toInt(item['quantity'], fallback: 1);

      total += price * quantity;
    }

    return total;
  }

  static void addItem(
    BuildContext context, {
    required Map<String, dynamic> item,
  }) {
    final normalized = _normalizeItem(item);
    final productId = normalized['productId'].toString();

    final existingIndex = _cartItems.indexWhere(
      (cartItem) => cartItem['productId'].toString() == productId,
    );

    if (existingIndex == -1) {
      _cartItems.add(normalized);
    } else {
      final existing = _cartItems[existingIndex];

      final currentQuantity = _toInt(existing['quantity'], fallback: 1);

      final incomingQuantity = _toInt(normalized['quantity'], fallback: 1);

      final availableQuantity = _toInt(
        existing['availableQuantity'],
        fallback: 10,
      );

      existing['quantity'] = _safeQuantity(
        currentQuantity + incomingQuantity,
        availableQuantity,
      );
    }

    _showOrUpdate(context);
  }

  static void show(
    BuildContext context, {
    required List<Map<String, dynamic>> items,
  }) {
    if (items.isEmpty) {
      return;
    }

    for (final item in items) {
      _addWithoutShowing(item);
    }

    _showOrUpdate(context);
  }

  static void _addWithoutShowing(Map<String, dynamic> item) {
    final normalized = _normalizeItem(item);
    final productId = normalized['productId'].toString();

    final existingIndex = _cartItems.indexWhere(
      (cartItem) => cartItem['productId'].toString() == productId,
    );

    if (existingIndex == -1) {
      _cartItems.add(normalized);
      return;
    }

    final existing = _cartItems[existingIndex];

    final currentQuantity = _toInt(existing['quantity'], fallback: 1);

    final incomingQuantity = _toInt(normalized['quantity'], fallback: 1);

    final availableQuantity = _toInt(
      existing['availableQuantity'],
      fallback: 10,
    );

    existing['quantity'] = _safeQuantity(
      currentQuantity + incomingQuantity,
      availableQuantity,
    );
  }

  static void _showOrUpdate(BuildContext context) {
    if (_cartItems.isEmpty) {
      return;
    }

    final navigator = Navigator.maybeOf(context, rootNavigator: true);

    if (navigator == null || !navigator.mounted) {
      return;
    }

    _showOrUpdateWithNavigator(navigator);
  }

  static void _showOrUpdateWithNavigator(NavigatorState navigator) {
    if (_cartItems.isEmpty) {
      return;
    }

    if (!navigator.mounted) {
      return;
    }

    final overlay = navigator.overlay;

    if (overlay == null) {
      return;
    }

    _navigatorState = navigator;

    if (_currentEntry != null) {
      _currentEntry!.markNeedsBuild();
      return;
    }

    _navigationInProgress = false;

    final entry = OverlayEntry(
      builder: (_) {
        return _CartPopupOverlay(
          key: _popupKey,
          items: items,
          onClose: dismiss,
          onViewCart: _openCart,
          onCheckout: _openCheckout,
        );
      },
    );

    _currentEntry = entry;

    overlay.insert(entry);
  }

  static final GlobalKey<_CartPopupOverlayState> _popupKey =
      GlobalKey<_CartPopupOverlayState>();

  static void _openCart() {
    if (_navigationInProgress) {
      return;
    }

    final navigator = _navigatorState;

    if (navigator == null || !navigator.mounted) {
      return;
    }

    final cartItems = items;

    if (cartItems.isEmpty) {
      return;
    }

    _navigationInProgress = true;

    dismiss();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!navigator.mounted) {
        _navigationInProgress = false;
        return;
      }

      navigator
          .push(
            MaterialPageRoute(builder: (_) => Cart(initialItems: cartItems)),
          )
          .whenComplete(() {
            _navigationInProgress = false;
          });
    });
  }

  static void _openCheckout() {
    if (_navigationInProgress) {
      return;
    }

    final navigator = _navigatorState;

    if (navigator == null || !navigator.mounted) {
      return;
    }

    final cartItems = items;

    if (cartItems.isEmpty) {
      return;
    }

    _navigationInProgress = true;

    dismiss();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!navigator.mounted) {
        _navigationInProgress = false;
        return;
      }

      navigator
          .push(MaterialPageRoute(builder: (_) => Checkout(items: cartItems)))
          .whenComplete(() {
            _navigationInProgress = false;
          });
    });
  }

  static void dismiss() {
    final entry = _currentEntry;

    _currentEntry = null;

    if (entry != null) {
      entry.remove();
    }
  }

  static void clear() {
    _cartItems.clear();
    dismiss();

    _navigatorState = null;
    _navigationInProgress = false;
  }

  static void removeItem(String productId) {
    _cartItems.removeWhere(
      (item) => item['productId'].toString() == productId.toString(),
    );

    if (_cartItems.isEmpty) {
      dismiss();
    } else {
      _currentEntry?.markNeedsBuild();
    }
  }

  static void updateQuantity(String productId, int quantity) {
    final index = _cartItems.indexWhere(
      (item) => item['productId'].toString() == productId.toString(),
    );

    if (index == -1) {
      return;
    }

    final item = _cartItems[index];

    final availableQuantity = _toInt(item['availableQuantity'], fallback: 10);

    item['quantity'] = _safeQuantity(quantity, availableQuantity);

    _currentEntry?.markNeedsBuild();
  }

  static Map<String, dynamic> _normalizeItem(Map<String, dynamic> item) {
    final copy = Map<String, dynamic>.from(item);

    final productId =
        copy['productId'] ??
        copy['id'] ??
        'product_${DateTime.now().microsecondsSinceEpoch}';

    final title = copy['title'] ?? copy['name'] ?? 'EcoLoop Product';

    final price = _toDouble(copy['price']);

    final availableQuantity = _toInt(
      copy['availableQuantity'] ?? copy['stock'] ?? 10,
      fallback: 10,
    );

    final quantity = _safeQuantity(
      _toInt(copy['quantity'], fallback: 1),
      availableQuantity <= 0 ? 1 : availableQuantity,
    );

    copy['productId'] = productId;
    copy['id'] = productId;
    copy['title'] = title;
    copy['price'] = price;
    copy['quantity'] = quantity;
    copy['availableQuantity'] = availableQuantity <= 0 ? 1 : availableQuantity;

    return copy;
  }

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      final cleaned = value.replaceAll('₹', '').replaceAll(',', '').trim();

      return int.tryParse(cleaned) ?? fallback;
    }

    return fallback;
  }

  static double _toDouble(dynamic value) {
    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      final cleaned = value.replaceAll('₹', '').replaceAll(',', '').trim();

      return double.tryParse(cleaned) ?? 0;
    }

    return 0;
  }

  static int _safeQuantity(int quantity, int maximum) {
    if (quantity < 1) {
      return 1;
    }

    if (maximum > 0 && quantity > maximum) {
      return maximum;
    }

    return quantity;
  }
}

class _CartPopupOverlay extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final VoidCallback onClose;
  final VoidCallback onViewCart;
  final VoidCallback onCheckout;

  const _CartPopupOverlay({
    super.key,
    required this.items,
    required this.onClose,
    required this.onViewCart,
    required this.onCheckout,
  });

  @override
  State<_CartPopupOverlay> createState() => _CartPopupOverlayState();
}

class _CartPopupOverlayState extends State<_CartPopupOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;

  late final Animation<double> _fadeAnimation;

  late final Animation<Offset> _entranceSlideAnimation;

  Timer? _moveTimer;

  bool _isAtBottom = false;

  String _lastProductKey = '';

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );

    _entranceSlideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.12), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutCubic,
          ),
        );

    _lastProductKey = _productKey(widget.items);

    _entranceController.forward();

    _startMoveTimer();
  }

  @override
  void didUpdateWidget(covariant _CartPopupOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newProductKey = _productKey(widget.items);

    if (newProductKey != _lastProductKey) {
      _lastProductKey = newProductKey;

      _resetPopupPosition();
    }
  }

  void _startMoveTimer() {
    _moveTimer?.cancel();

    _moveTimer = Timer(const Duration(seconds: 3), _moveToBottom);
  }

  void _resetPopupPosition() {
    if (!mounted) {
      return;
    }

    setState(() {
      _isAtBottom = false;
    });

    _entranceController
      ..reset()
      ..forward();

    _startMoveTimer();
  }

  void _moveToBottom() {
    if (!mounted) {
      return;
    }

    setState(() {
      _isAtBottom = true;
    });
  }

  String _productKey(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return '';
    }

    final last = items.last;

    return [
      last['productId']?.toString() ?? '',
      last['quantity']?.toString() ?? '',
      items.length.toString(),
    ].join('|');
  }

  @override
  void dispose() {
    _moveTimer?.cancel();
    _entranceController.dispose();
    super.dispose();
  }

  Map<String, dynamic> get product {
    if (widget.items.isEmpty) {
      return {};
    }

    return widget.items.last;
  }

  String get title {
    return product['title']?.toString() ?? 'Product';
  }

  int get quantity {
    return _toInt(product['quantity'], fallback: 1);
  }

  int get price {
    return _toInt(product['price'], fallback: 0);
  }

  int get total {
    return price * quantity;
  }

  String get image {
    final singleImage = product['image']?.toString();

    if (singleImage != null && singleImage.isNotEmpty) {
      return singleImage;
    }

    final imageUrl = product['imageUrl']?.toString();

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return imageUrl;
    }

    final images = product['images'];

    if (images is List && images.isNotEmpty) {
      return images.first.toString();
    }

    return '';
  }

  int get itemCount {
    var total = 0;

    for (final item in widget.items) {
      total += _toInt(item['quantity'], fallback: 1);
    }

    return total;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Positioned.fill(
      child: SafeArea(
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOutCubic,
          alignment: _isAtBottom ? Alignment.bottomCenter : Alignment.topCenter,
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOutCubic,
            padding: EdgeInsets.fromLTRB(
              12,
              8,
              12,
              _isAtBottom ? bottomInset + 82 : 12,
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _entranceSlideAnimation,
                child: Material(color: Colors.transparent, child: _buildCard()),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withOpacity(0.55)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTopRow(),
            const SizedBox(height: 10),
            _buildProductRow(),
            const SizedBox(height: 12),
            _buildBottomRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopRow() {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: AppColors.light,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 17,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            'Added to Cart',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onClose,
          child: Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.close_rounded,
              size: 17,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductRow() {
    return Row(
      children: [
        _buildProductImage(),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Text('Qty $quantity', style: AppTextStyles.caption),
                  const SizedBox(width: 8),
                  Container(
                    width: 3,
                    height: 3,
                    decoration: const BoxDecoration(
                      color: AppColors.textSecondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '₹${_formatPrice(price)}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '₹${_formatPrice(total)}',
          style: AppTextStyles.body.copyWith(
            color: AppColors.primary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildProductImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 55,
        height: 55,
        color: AppColors.light,
        child: image.isNotEmpty
            ? Image.network(
                image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.image_outlined,
                    color: AppColors.primary,
                    size: 23,
                  );
                },
              )
            : const Icon(
                Icons.image_outlined,
                color: AppColors.primary,
                size: 23,
              ),
      ),
    );
  }

  Widget _buildBottomRow() {
    return Row(
      children: [
        Expanded(
          child: Text(
            itemCount == 1 ? '1 item in cart' : '$itemCount items in cart',
            style: AppTextStyles.caption.copyWith(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: widget.onViewCart,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'View Cart',
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 7),
        ElevatedButton(
          onPressed: widget.onCheckout,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Checkout',
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      final cleaned = value.replaceAll('₹', '').replaceAll(',', '').trim();

      return int.tryParse(cleaned) ?? fallback;
    }

    return fallback;
  }

  String _formatPrice(int value) {
    final valueString = value.toString();

    if (valueString.length <= 3) {
      return valueString;
    }

    final chars = valueString.split('');
    final buffer = StringBuffer();

    for (int i = 0; i < chars.length; i++) {
      buffer.write(chars[i]);

      final position = chars.length - i;

      if (position > 1 && position % 3 == 1) {
        buffer.write(',');
      }
    }

    return buffer.toString();
  }
}
