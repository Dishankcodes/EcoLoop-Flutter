import 'package:flutter/material.dart';
import '../app_theme/app_colors.dart';
import '../app_theme/app_text_styles.dart';

class CartPopup extends StatelessWidget {
  final int itemCount;
  final VoidCallback onViewCart;
  final VoidCallback onClose;

  const CartPopup({
    super.key,
    required this.itemCount,
    required this.onViewCart,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    if (itemCount <= 0) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 20,
      right: 20,
      bottom: 82,
      child: Material(
        color: Colors.transparent,
        child: Container(
          height: 62,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 8),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shopping_bag_rounded,
                  color: Colors.white,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: onViewCart,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'View Cart',
                        style: AppTextStyles.body.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white.withOpacity(0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: onViewCart,
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: Icon(
                  Icons.close_rounded,
                  color: Colors.white.withOpacity(0.7),
                  size: 20,
                ),
              ),
              const SizedBox(width: 5),
            ],
          ),
        ),
      ),
    );
  }
}
