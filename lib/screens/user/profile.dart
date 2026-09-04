import 'package:ecoloop/screens/user/donation_history.dart';
import 'package:flutter/material.dart';

import '../../app_theme/app_colors.dart';
import '../../app_theme/app_text_styles.dart';
import '../../shared_preferences_util.dart';
import '../../widgets/user_more_menu.dart';
import '../welcome_screen.dart';
import 'donate_item.dart';
import 'edit_profile.dart';
import 'my_listings.dart';
import 'notifications.dart';
import 'orders.dart';
import 'settings.dart';
import 'wishlist.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Profile', style: AppTextStyles.title),
        actions: const [UserMoreMenu(), SizedBox(width: 8)],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        child: Column(
          children: [
            _buildProfileHeader(context),
            const SizedBox(height: 24),

            _buildAccountSection(context),

            const SizedBox(height: 22),

            _buildSettingsSection(context),

            const SizedBox(height: 22),

            _buildLogoutButton(context),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // PROFILE HEADER
  // ----------------------------------------------------------

  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withOpacity(0.45)),
      ),
      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: AppColors.light,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accent, width: 2),
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 42,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'Dishank Prajapati',
            style: AppTextStyles.title.copyWith(fontSize: 19),
          ),

          const SizedBox(height: 4),

          Text('user@ecoloop.com', style: AppTextStyles.caption),

          const SizedBox(height: 14),

          OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfile()),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
            ),
            child: const Text(
              'Edit Profile',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // ACCOUNT
  // ----------------------------------------------------------

  Widget _buildAccountSection(BuildContext context) {
    return _ProfileSection(
      title: 'My Account',
      children: [
        _ProfileTile(
          icon: Icons.inventory_2_outlined,
          title: 'My Listings',
          subtitle: 'Manage products you are selling',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyListings()),
            );
          },
        ),

        _ProfileTile(
          icon: Icons.receipt_long_outlined,
          title: 'My Orders',
          subtitle: 'View your purchases',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Orders()),
            );
          },
        ),

        _ProfileTile(
          icon: Icons.favorite_border_rounded,
          title: 'Wishlist',
          subtitle: 'Products you saved',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Wishlist()),
            );
          },
        ),

        _ProfileTile(
          icon: Icons.volunteer_activism_outlined,
          title: 'Donate an Item',
          subtitle: 'Give your unused item a new life',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DonateItem()),
            );
          },
        ),

        _ProfileTile(
          icon: Icons.receipt_long_outlined,
          title: 'Donation History',
          subtitle: 'View your donated items and pickups',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DonationHistory()),
            );
          },
        ),
        _ProfileTile(
          icon: Icons.redeem_outlined,
          title: 'Rewards',
          subtitle: 'Check and claimed your rewards',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DonateItem()),
            );
          },
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // SETTINGS
  // ----------------------------------------------------------

  Widget _buildSettingsSection(BuildContext context) {
    return _ProfileSection(
      title: 'Preferences',
      children: [
        _ProfileTile(
          icon: Icons.settings_outlined,
          title: 'Settings',
          subtitle: 'App preferences and account settings',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Settings()),
            );
          },
        ),

        _ProfileTile(
          icon: Icons.notifications_none_rounded,
          title: 'Notifications',
          subtitle: 'Manage your notifications',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Notifications()),
            );
          },
        ),

        _ProfileTile(
          icon: Icons.help_outline_rounded,
          title: 'Help & Support',
          subtitle: 'Get help with EcoLoop',
          onTap: () {
            _showComingSoon(context, 'Help & Support');
          },
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // LOGOUT
  // ----------------------------------------------------------

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          _showLogoutDialog(context);
        },
        icon: const Icon(
          Icons.logout_rounded,
          size: 19,
          color: AppColors.error,
        ),
        label: const Text(
          'Logout',
          style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: AppColors.error.withOpacity(0.35)),
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // HELPERS
  // ----------------------------------------------------------

  void _showComingSoon(BuildContext context, String page) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$page will be implemented next.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Close dialog first
                Navigator.pop(dialogContext);

                // Clear login/session data
                await Prefs.setBool('isLoggedIn', false);
                await Prefs.setString('authToken', '');
                await Prefs.setString('userRole', '');
                await Prefs.setString('userEmail', '');
                await Prefs.setString('userName', '');

                if (!context.mounted) return;

                // Go back to Welcome screen and remove
                // all logged-in screens from navigation stack.
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  (route) => false,
                );
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================
// PROFILE SECTION
// ============================================================

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 3, bottom: 9),
          child: Text(title, style: AppTextStyles.title.copyWith(fontSize: 16)),
        ),

        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.accent.withOpacity(0.45)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}


class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.light,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 21, color: AppColors.primary),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              size: 21,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
