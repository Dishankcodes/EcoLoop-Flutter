import 'package:flutter/material.dart';

import '../app_theme/app_colors.dart';

class UserMoreMenu extends StatelessWidget {
  const UserMoreMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: AppColors.textPrimary),
      tooltip: 'More',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (value) {
        switch (value) {
          case 'wishlist':
            _showComingSoon(context, 'Wishlist');
            break;

          case 'notifications':
            _showComingSoon(context, 'Notifications');
            break;

          case 'messages':
            _showComingSoon(context, 'Messages');
            break;
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem<String>(
          value: 'wishlist',
          child: Row(
            children: [
              Icon(Icons.favorite_border_rounded, color: AppColors.primary),
              SizedBox(width: 12),
              Text('Wishlist'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'notifications',
          child: Row(
            children: [
              Icon(Icons.notifications_none_rounded, color: AppColors.primary),
              SizedBox(width: 12),
              Text('Notifications'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'messages',
          child: Row(
            children: [
              Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary),
              SizedBox(width: 12),
              Text('Messages'),
            ],
          ),
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature will be implemented soon.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
