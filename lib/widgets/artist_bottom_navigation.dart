import 'package:flutter/material.dart';

import '../app_theme/artist/artist_colors.dart';

class ArtistBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onAddProduct;

  const ArtistBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
    required this.onAddProduct,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        border: Border(
          top: BorderSide(color: ArtistColors.accent.withOpacity(0.35)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              // HOME / DASHBOARD
              _navItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                index: 0,
              ),

              // MARKETPLACE
              _navItem(
                icon: Icons.storefront_outlined,
                activeIcon: Icons.storefront_rounded,
                label: 'Marketplace',
                index: 1,
              ),

              // ADD PRODUCT
              _addButton(),

              // SELLING ORDERS
              _navItem(
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long_rounded,
                label: 'Orders',
                index: 2,
              ),

              // PROFILE
              _navItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                index: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // NAVIGATION ITEM

  Widget _navItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final bool isSelected = currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => onItemSelected(index),
        splashColor: ArtistColors.accent.withOpacity(0.15),
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 22,
              color: isSelected
                  ? ArtistColors.primary
                  : ArtistColors.textSecondary,
            ),

            const SizedBox(height: 3),

            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? ArtistColors.primary
                    : ArtistColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ADD PRODUCT BUTTON

  Widget _addButton() {
    return Expanded(
      child: Center(
        child: GestureDetector(
          onTap: onAddProduct,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: ArtistColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ArtistColors.primary.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}
