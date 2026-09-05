import 'dart:async';

import 'package:flutter/material.dart';

import '../app_theme/app_colors.dart';
import '../app_theme/app_text_styles.dart';
import '../screens/user/buy_products/cart.dart';
import '../screens/user/buy_products/checkout.dart';

class CartPopup {
  CartPopup._();

  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;
  static GlobalKey<_CartPopupOverlayState>? _overlayKey;

  static void show(
    BuildContext context, {
    required List<Map<String, dynamic>> items,
  }) {
    if (items.isEmpty) return;

    _removeCurrentImmediate();

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    _overlayKey = GlobalKey<_CartPopupOverlayState>();

    final entry = OverlayEntry(
      builder: (overlayContext) {
        return _CartPopupOverlay(
          key: _overlayKey,
          items: items,
          onClose: dismiss,
          onViewCart: () {
            dismiss();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => Cart(initialItems: items)),
            );
          },
          onCheckout: () {
            dismiss();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => Checkout(items: items)),
            );
          },
        );
      },
    );

    _currentEntry = entry;
    overlay.insert(entry);

    _dismissTimer = Timer(const Duration(seconds: 5), () {
      dismiss();
    });
  }

  static void dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;

    if (_overlayKey?.currentState != null) {
      _overlayKey!.currentState!.dismissWithAnimation(() {
        _removeCurrentImmediate();
      });
    } else {
      _removeCurrentImmediate();
    }
  }

  static void _removeCurrentImmediate() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _currentEntry?.remove();
    _currentEntry = null;
    _overlayKey = null;
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
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isExitingDown = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  void dismissWithAnimation(VoidCallback onComplete) {
    if (_isExitingDown) return;

    setState(() {
      _isExitingDown = true;
      _slideAnimation =
          Tween<Offset>(begin: Offset.zero, end: const Offset(0, 2.5)).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeInCubic,
            ),
          );
    });

    _animationController.reverse().then((_) {
      onComplete();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Map<String, dynamic> get product => widget.items.last;

  String get title => product['title']?.toString() ?? 'Product';

  int get quantity {
    final value = product['quantity'];
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '1') ?? 1;
  }

  int get price {
    final value = product['price'];
    if (value is num) return value.toInt();
    return _extractPrice(value?.toString() ?? '0');
  }

  int get total => price * quantity;

  String get image {
    final singleImage = product['image']?.toString();
    if (singleImage != null && singleImage.isNotEmpty) return singleImage;

    final images = product['images'];
    if (images is List && images.isNotEmpty) return images.first.toString();

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
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 12,
      right: 12,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Material(
            color: Colors.transparent,
            child: _buildCard(context),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
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
        const Expanded(
          child: Text(
            'Added to Cart',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        GestureDetector(
          onTap: widget.onClose,
          child: Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.close_rounded,
              size: 16,
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
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
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
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
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
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
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
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.textSecondary,
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
