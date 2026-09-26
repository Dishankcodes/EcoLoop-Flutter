import 'package:flutter/material.dart';

import '../app_theme/artist/artist_colors.dart';
import '../app_theme/artist/artist_text_styles.dart';
import '../screens/artist/profile/contact_us.dart';
import '../screens/artist/profile/settings.dart';
import '../screens/artist/sell_products/product_analytics.dart';
import '../screens/welcome_screen.dart';
import '../shared_preferences_util.dart';

class ArtistMoreMenu extends StatelessWidget {
  const ArtistMoreMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_vert_rounded,
        color: ArtistColors.textPrimary,
      ),
      tooltip: 'More',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),

      onSelected: (value) {
        switch (value) {
          case 'analytics':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProductAnalytics()),
            );
            break;

          case 'settings':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ArtistSettings()),
            );
            break;

          case 'contact':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ContactUs()),
            );
            break;

          case 'logout':
            _showLogoutDialog(context);
            break;
        }
      },

      itemBuilder: (context) => const [
        PopupMenuItem<String>(
          value: 'analytics',
          child: Row(
            children: [
              Icon(Icons.analytics_outlined, color: ArtistColors.primary),
              SizedBox(width: 12),
              Text('Product Analytics'),
            ],
          ),
        ),

        PopupMenuItem<String>(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings_outlined, color: ArtistColors.primary),
              SizedBox(width: 12),
              Text('Settings'),
            ],
          ),
        ),

        PopupMenuItem<String>(
          value: 'contact',
          child: Row(
            children: [
              Icon(Icons.contact_support_outlined, color: ArtistColors.primary),
              SizedBox(width: 12),
              Text('Contact Us'),
            ],
          ),
        ),

        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, color: ArtistColors.error),
              SizedBox(width: 12),
              Text('Logout'),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // LOGOUT DIALOG
  // ---------------------------------------------------------------------------

  static void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: ArtistColors.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),

          title: Text(
            'Logout',
            style: ArtistTextStyles.title.copyWith(fontSize: 20),
          ),

          content: Text(
            'Are you sure you want to logout?',
            style: ArtistTextStyles.body,
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(
                'Cancel',
                style: ArtistTextStyles.bodyMedium.copyWith(
                  color: ArtistColors.textSecondary,
                ),
              ),
            ),

            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                await Prefs.setBool('isLoggedIn', false);

                await Prefs.setString('authToken', '');

                await Prefs.setString('userRole', '');

                await Prefs.setString('userEmail', '');

                await Prefs.setString('userName', '');

                if (!context.mounted) {
                  return;
                }

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  (route) => false,
                );
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: ArtistColors.error,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),

              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
