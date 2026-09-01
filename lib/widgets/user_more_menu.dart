import 'package:ecoloop/screens/user/settings.dart';
import 'package:flutter/material.dart';

import '../app_theme/app_colors.dart';
import '../screens/user/donate_item.dart';

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


          case "donate":
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DonateItem()),
            );
            break;

          case "settings":
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Settings()),
            );
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
          value: "donate",
          child: Row(
            children: [
              Icon(Icons.volunteer_activism_outlined, color: AppColors.primary),
              SizedBox(width: 12),
              Text("Donate an Item"),
            ],
          ),
        ),

        PopupMenuItem<String>(
          value: "settings",
          child: Row(
            children: [
              Icon(Icons.settings_outlined, color: AppColors.primary),
              SizedBox(width: 12),
              Text("Settings"),
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
