import 'dart:async';

import 'package:flutter/material.dart';

import '../app_theme/user/app_colors.dart';
import '../app_theme/user/app_text_styles.dart';
import '../screens/user/buy_products/cart.dart';

class CartPopup {
  CartPopup._();

  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context, {
    required List<Map<String, dynamic>> items,
  }) {
    if (items.isEmpty) {
      return;
    }

    _removeCurrent();

    final overlay = Overlay.maybeOf(context);

    if (overlay == null) {
      return;
    }

    final entry = OverlayEntry(
      builder: (_) {
        return _CartPopupOverlay(
          items: items,
          onClose: _removeCurrent,
          onViewCart: () {
            _removeCurrent();

            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => Cart(initialItems: items)),
            );
          },
          onCheckout: () {
            _removeCurrent();

            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => Cart(initialItems: items)),
            );
          },
        );
      },
    );

    _currentEntry = entry;

    overlay.insert(entry);
  }

  static void _removeCurrent() {
    _currentEntry?.remove();
    _currentEntry = null;
  }

  static void dismiss() {
    _removeCurrent();
  }
}

class _CartPopupOverlay extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final VoidCallback onClose;
  final VoidCallback onViewCart;
  final VoidCallback onCheckout;

  const _CartPopupOverlay({
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

    _entranceController.forward();

    _moveTimer = Timer(const Duration(seconds: 5), _moveToBottom);
  }

  @override
  void dispose() {
    _moveTimer?.cancel();
    _entranceController.dispose();
    super.dispose();
  }

  void _moveToBottom() {
    if (!mounted) {
      return;
    }

    setState(() {
      _isAtBottom = true;
    });
  }

  Map<String, dynamic> get product {
    return widget.items.first;
  }

  String get title {
    return product['title']?.toString() ?? 'Product';
  }

  int get quantity {
    final value = product['quantity'];

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '1') ?? 1;
  }

  int get price {
    final value = product['price'];

    if (value is num) {
      return value.toInt();
    }

    return _extractPrice(value?.toString() ?? '0');
  }

  int get total {
    return price * quantity;
  }

  String get image {
    final singleImage = product['image']?.toString();

    if (singleImage != null && singleImage.isNotEmpty) {
      return singleImage;
    }

    final images = product['images'];

    if (images is List && images.isNotEmpty) {
      return images.first.toString();
    }

    return '';
  }

  int get totalItems {
    int total = 0;

    for (final item in widget.items) {
      final value = item['quantity'];

      if (value is num) {
        total += value.toInt();
      } else {
        total += int.tryParse(value?.toString() ?? '1') ?? 1;
      }
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
              _isAtBottom ? bottomInset + 78 : 12,
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
            totalItems == 1 ? '1 item in cart' : '$totalItems items in cart',
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

  int _extractPrice(String value) {
    final cleaned = value.replaceAll('₹', '').replaceAll(',', '').trim();

    return int.tryParse(cleaned) ?? 0;
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
