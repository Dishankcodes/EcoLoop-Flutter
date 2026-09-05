import 'package:flutter/material.dart';

import '../app_theme/app_colors.dart';
import '../screens/user/buy_products/cart.dart';

class FloatingCartBar extends StatelessWidget {
  final List<Map<String, dynamic>> items;

  const FloatingCartBar({super.key, this.items = const []});

  @override
  Widget build(BuildContext context) {
    final hasItems = items.isNotEmpty;

    int totalItems = 0;
    double totalPrice = 0;

    for (final item in items) {
      final qty = (item['quantity'] as num? ?? 1).toInt();
      final price = (item['price'] as num? ?? 0).toDouble();
      totalItems += qty;
      totalPrice += price * qty;
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      left: 16,
      right: 16,
      bottom: hasItems ? MediaQuery.of(context).padding.bottom + 12 : -100,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: hasItems ? 1.0 : 0.0,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(16),
          color: AppColors.primary,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => Cart(initialItems: items)),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$totalItems ${totalItems == 1 ? 'item' : 'items'} in cart',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '₹${totalPrice.toInt()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'View Cart',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
