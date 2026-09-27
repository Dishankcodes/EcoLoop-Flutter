import 'package:flutter/material.dart';

import '../app_theme/artist/artist_colors.dart';
import '../app_theme/artist/artist_text_styles.dart';
import '../screens/artist/buy_products/wishlist.dart';
import '../screens/artist/profile/contact_us.dart';
import '../screens/artist/profile/notification.dart';
import '../screens/artist/profile/settings.dart';
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
      color: ArtistColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: ArtistColors.border),
      ),
      onSelected: (value) {
        switch (value) {
          case 'wishlist':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Wishlist()),
            );
            break;

          case 'notifications':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Notifications()),
            );
            break;

          case 'contact':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ContactUs()),
            );
            break;

          case 'settings':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Settings()),
            );
            break;

          case 'logout':
            _showLogoutDialog(context);
            break;
        }
      },
      itemBuilder: (context) => [
        // Wishlist option
        PopupMenuItem<String>(
          value: 'wishlist',
          height: 48,
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: ArtistColors.light,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.favorite_border_rounded,
                  color: ArtistColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Wishlist',
                style: ArtistTextStyles.bodyMedium.copyWith(
                  color: ArtistColors.textPrimary,
                ),
              ),
            ],
          ),
        ),

        // Notifications option
        PopupMenuItem<String>(
          value: 'notifications',
          height: 48,
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: ArtistColors.light,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: ArtistColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Notifications',
                style: ArtistTextStyles.bodyMedium.copyWith(
                  color: ArtistColors.textPrimary,
                ),
              ),
            ],
          ),
        ),

        const PopupMenuDivider(height: 8),

        // Contact us option
        PopupMenuItem<String>(
          value: 'contact',
          height: 48,
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: ArtistColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.contact_support_outlined,
                  color: ArtistColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Contact Us',
                style: ArtistTextStyles.bodyMedium.copyWith(
                  color: ArtistColors.textPrimary,
                ),
              ),
            ],
          ),
        ),

        // Settings option
        PopupMenuItem<String>(
          value: 'settings',
          height: 48,
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: ArtistColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.settings_outlined,
                  color: ArtistColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Settings',
                style: ArtistTextStyles.bodyMedium.copyWith(
                  color: ArtistColors.textPrimary,
                ),
              ),
            ],
          ),
        ),

        const PopupMenuDivider(height: 8),

        // Logout option
        PopupMenuItem<String>(
          value: 'logout',
          height: 48,
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: ArtistColors.error.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: ArtistColors.error,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Logout',
                style: ArtistTextStyles.bodyMedium.copyWith(
                  color: ArtistColors.error,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Shows confirmation dialog before logging out
  static void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: ArtistColors.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: ArtistColors.error.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: ArtistColors.error,
              size: 27,
            ),
          ),
          title: Text(
            'Logout',
            textAlign: TextAlign.center,
            style: ArtistTextStyles.title.copyWith(
              fontSize: 20,
              color: ArtistColors.textPrimary,
            ),
          ),
          content: Text(
            'Are you sure you want to logout from your Artist account?',
            textAlign: TextAlign.center,
            style: ArtistTextStyles.body,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
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
            const SizedBox(width: 6),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                // Clears session state in shared preferences
                await Prefs.setBool('isLoggedIn', false);
                await Prefs.setString('authToken', '');
                await Prefs.setString('userRole', '');
                await Prefs.setString('userEmail', '');
                await Prefs.setString('userName', '');

                if (!context.mounted) return;

                // Returns user to welcome screen
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 11,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }
}
