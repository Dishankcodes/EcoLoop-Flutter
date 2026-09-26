import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import '../../../shared_preferences_util.dart';
import '../../../widgets/artist_more_menu.dart';
import '../../welcome_screen.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtistColors.background,

      // ==========================================================
      // APP BAR
      // ==========================================================
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: ArtistColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text('Profile', style: ArtistTextStyles.title),
        actions: const [ArtistMoreMenu(), SizedBox(width: 8)],
      ),

      // ==========================================================
      // BODY
      // ==========================================================
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(context),

              const SizedBox(height: 18),

              _buildQuickStats(context),

              const SizedBox(height: 24),

              _buildArtistInformation(context),

              const SizedBox(height: 22),

              _buildProductsSection(context),

              const SizedBox(height: 22),

              _buildOrdersSection(context),

              const SizedBox(height: 22),

              _buildBusinessSection(context),

              const SizedBox(height: 22),

              _buildPreferencesSection(context),

              const SizedBox(height: 22),

              _buildLogoutButton(context),

              const SizedBox(height: 14),

              Center(
                child: Text(
                  'EcoLoop • Give Things a New Life',
                  style: ArtistTextStyles.caption.copyWith(
                    color: ArtistColors.textSecondary.withOpacity(0.65),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // PROFILE HEADER
  // ==========================================================

  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ArtistColors.border),
        boxShadow: [
          BoxShadow(
            color: ArtistColors.primary.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // ------------------------------------------------------
          // PROFILE IMAGE
          // ------------------------------------------------------
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ArtistColors.light,
              border: Border.all(
                color: ArtistColors.primary.withOpacity(0.35),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 48,
              color: ArtistColors.primary,
            ),
          ),

          const SizedBox(height: 13),

          // ------------------------------------------------------
          // NAME
          // ------------------------------------------------------
          Text(
            'Creative Studio',
            textAlign: TextAlign.center,
            style: ArtistTextStyles.title.copyWith(
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 4),

          Text('artist@ecoloop.com', style: ArtistTextStyles.caption),

          const SizedBox(height: 6),

          // ------------------------------------------------------
          // ARTIST BADGE
          // ------------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.palette_outlined,
                size: 16,
                color: ArtistColors.primary,
              ),

              const SizedBox(width: 5),

              Text(
                'EcoLoop ReMaker',
                style: ArtistTextStyles.caption.copyWith(
                  color: ArtistColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ------------------------------------------------------
          // LOCATION
          // ------------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 15,
                color: ArtistColors.textSecondary,
              ),

              const SizedBox(width: 4),

              Text('Ahmedabad, Gujarat', style: ArtistTextStyles.caption),
            ],
          ),

          const SizedBox(height: 16),

          // ------------------------------------------------------
          // ACTION BUTTONS
          // ------------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  _showComingSoon(context, 'Edit Profile');
                },
                icon: const Icon(Icons.edit_outlined, size: 17),
                label: Text(
                  'Edit Profile',
                  style: ArtistTextStyles.bodyMedium.copyWith(
                    fontSize: 13,
                    color: ArtistColors.primary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ArtistColors.primary,
                  side: const BorderSide(color: ArtistColors.primary),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              OutlinedButton.icon(
                onPressed: () {
                  _showComingSoon(context, 'View Portfolio');
                },
                icon: const Icon(Icons.collections_outlined, size: 17),
                label: Text(
                  'Portfolio',
                  style: ArtistTextStyles.bodyMedium.copyWith(
                    fontSize: 13,
                    color: ArtistColors.textSecondary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ArtistColors.textSecondary,
                  side: const BorderSide(color: ArtistColors.border),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // QUICK STATS
  // ==========================================================

  Widget _buildQuickStats(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickStatCard(
            icon: Icons.inventory_2_outlined,
            value: '12',
            label: 'Products',
            onTap: () {
              _showComingSoon(context, 'My Products');
            },
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _QuickStatCard(
            icon: Icons.shopping_bag_outlined,
            value: '18',
            label: 'Orders',
            onTap: () {
              _showComingSoon(context, 'Orders');
            },
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _QuickStatCard(
            icon: Icons.star_outline_rounded,
            value: '4.8',
            label: 'Rating',
            onTap: () {
              _showComingSoon(context, 'Reviews');
            },
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _QuickStatCard(
            icon: Icons.people_outline_rounded,
            value: '2.4K',
            label: 'Followers',
            onTap: () {
              _showComingSoon(context, 'Followers');
            },
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // ARTIST INFORMATION
  // ==========================================================

  Widget _buildArtistInformation(BuildContext context) {
    return _ProfileSection(
      title: 'Artist Information',
      children: [
        // ------------------------------------------------------
        // BIO
        // ------------------------------------------------------
        _ProfileTile(
          icon: Icons.person_outline_rounded,
          title: 'About',
          subtitle:
              'Creating sustainable products through creative reuse and upcycling.',
          onTap: () {
            _showComingSoon(context, 'Artist Bio');
          },
        ),

        _ProfileDivider(),

        // ------------------------------------------------------
        // SKILLS
        // ------------------------------------------------------
        _ProfileTile(
          icon: Icons.handyman_outlined,
          title: 'Skills',
          subtitle: 'Woodwork • Upcycling • Home Decor',
          onTap: () {
            _showComingSoon(context, 'Artist Skills');
          },
        ),

        _ProfileDivider(),

        // ------------------------------------------------------
        // EXPERIENCE
        // ------------------------------------------------------
        _ProfileTile(
          icon: Icons.workspace_premium_outlined,
          title: 'Experience',
          subtitle: '3+ years of creative making',
          onTap: () {
            _showComingSoon(context, 'Artist Experience');
          },
        ),

        _ProfileDivider(),

        // ------------------------------------------------------
        // LOCATION
        // ------------------------------------------------------
        _ProfileTile(
          icon: Icons.location_on_outlined,
          title: 'Location',
          subtitle: 'Ahmedabad, Gujarat',
          onTap: () {
            _showComingSoon(context, 'Location');
          },
        ),
      ],
    );
  }

  // ==========================================================
  // PRODUCTS SECTION
  // ==========================================================

  Widget _buildProductsSection(BuildContext context) {
    return _ProfileSection(
      title: 'Products',
      children: [
        // ------------------------------------------------------
        // MY PRODUCTS
        // ------------------------------------------------------
        _ProfileTile(
          icon: Icons.inventory_2_outlined,
          title: 'My Products',
          subtitle: 'View and manage your listed products',
          onTap: () {
            _showComingSoon(context, 'My Products');
          },
        ),

        _ProfileDivider(),

        // ------------------------------------------------------
        // ADD PRODUCT
        // ------------------------------------------------------
        _ProfileTile(
          icon: Icons.add_business_outlined,
          title: 'Add Product',
          subtitle: 'Create a new product listing',
          onTap: () {
            _showComingSoon(context, 'Add Product');
          },
        ),

        _ProfileDivider(),

        // ------------------------------------------------------
        // PRODUCT ANALYTICS
        // ------------------------------------------------------
        _ProfileTile(
          icon: Icons.analytics_outlined,
          title: 'Product Analytics',
          subtitle: 'Track views, sales and product performance',
          onTap: () {
            _showComingSoon(context, 'Product Analytics');
          },
        ),
      ],
    );
  }

  // ==========================================================
  // ORDERS SECTION
  // ==========================================================

  Widget _buildOrdersSection(BuildContext context) {
    return _ProfileSection(
      title: 'Orders',
      children: [
        // ------------------------------------------------------
        // SELLING ORDERS
        // ------------------------------------------------------
        _ProfileTile(
          icon: Icons.receipt_long_outlined,
          title: 'Selling Orders',
          subtitle: 'Orders received from your buyers',
          onTap: () {
            _showComingSoon(context, 'Selling Orders');
          },
        ),

        _ProfileDivider(),

        // ------------------------------------------------------
        // PENDING ORDERS
        // ------------------------------------------------------
        _ProfileTile(
          icon: Icons.pending_actions_outlined,
          title: 'Pending Orders',
          subtitle: 'Orders waiting for your action',
          trailing: _buildBadge('6'),
          onTap: () {
            _showComingSoon(context, 'Pending Orders');
          },
        ),

        _ProfileDivider(),

        // ------------------------------------------------------
        // REVIEWS
        // ------------------------------------------------------
        _ProfileTile(
          icon: Icons.rate_review_outlined,
          title: 'Reviews',
          subtitle: 'View reviews from your customers',
          onTap: () {
            _showComingSoon(context, 'Reviews');
          },
        ),
      ],
    );
  }

  // ==========================================================
  // BUSINESS SECTION
  // ==========================================================

  Widget _buildBusinessSection(BuildContext context) {
    return _ProfileSection(
      title: 'Business',
      children: [
        // ------------------------------------------------------
        // EARNINGS
        // ------------------------------------------------------
        _ProfileTile(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Earnings',
          subtitle: 'View your sales and earnings',
          onTap: () {
            _showComingSoon(context, 'Earnings');
          },
        ),

        _ProfileDivider(),

        // ------------------------------------------------------
        // FOLLOWERS
        // ------------------------------------------------------
        _ProfileTile(
          icon: Icons.people_outline_rounded,
          title: 'Followers',
          subtitle: 'People following your artist profile',
          trailing: _buildBadge('2.4K'),
          onTap: () {
            _showComingSoon(context, 'Followers');
          },
        ),

        _ProfileDivider(),

        // ------------------------------------------------------
        // PORTFOLIO
        // ------------------------------------------------------
        _ProfileTile(
          icon: Icons.collections_outlined,
          title: 'Portfolio',
          subtitle: 'Showcase your creative work',
          onTap: () {
            _showComingSoon(context, 'Portfolio');
          },
        ),

        _ProfileDivider(),

        // ------------------------------------------------------
        // CERTIFICATION
        // ------------------------------------------------------
        _ProfileTile(
          icon: Icons.verified_outlined,
          title: 'Certification',
          subtitle: 'View your artist certification',
          onTap: () {
            _showComingSoon(context, 'Certification');
          },
        ),
      ],
    );
  }

  // ==========================================================
  // PREFERENCES & SUPPORT
  // ==========================================================

  Widget _buildPreferencesSection(BuildContext context) {
    return _ProfileSection(
      title: 'Preferences & Support',
      children: [
        // ------------------------------------------------------
        // SETTINGS
        // ------------------------------------------------------
        _ProfileTile(
          icon: Icons.settings_outlined,
          title: 'Settings',
          subtitle: 'App preferences and account settings',
          onTap: () {
            _showComingSoon(context, 'Settings');
          },
        ),

        _ProfileDivider(),

        // ------------------------------------------------------
        // NOTIFICATIONS
        // ------------------------------------------------------
        _ProfileTile(
          icon: Icons.notifications_none_rounded,
          title: 'Notifications',
          subtitle: 'View your latest notifications',
          onTap: () {
            _showComingSoon(context, 'Notifications');
          },
        ),

        _ProfileDivider(),

        // ------------------------------------------------------
        // CONTACT US
        // ------------------------------------------------------
        _ProfileTile(
          icon: Icons.contact_support_outlined,
          title: 'Contact Us',
          subtitle: 'Get help or contact EcoLoop support',
          onTap: () {
            _showComingSoon(context, 'Contact Us');
          },
        ),
      ],
    );
  }

  // ==========================================================
  // LOGOUT BUTTON
  // ==========================================================

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
          color: ArtistColors.error,
        ),
        label: Text(
          'Logout',
          style: ArtistTextStyles.bodyMedium.copyWith(
            color: ArtistColors.error,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: ArtistColors.error,
          side: BorderSide(color: ArtistColors.error.withOpacity(0.35)),
          backgroundColor: ArtistColors.surface,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // BADGE
  // ==========================================================

  Widget _buildBadge(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ArtistColors.light,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        value,
        style: ArtistTextStyles.small.copyWith(
          color: ArtistColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ==========================================================
  // COMING SOON
  // ==========================================================

  void _showComingSoon(BuildContext context, String page) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$page will be connected next.',
          style: ArtistTextStyles.bodyMedium.copyWith(color: Colors.white),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ==========================================================
  // LOGOUT DIALOG
  // ==========================================================

  void _showLogoutDialog(BuildContext context) {
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
          child: Text(
            title,
            style: ArtistTextStyles.title.copyWith(fontSize: 16),
          ),
        ),

        Container(
          decoration: BoxDecoration(
            color: ArtistColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ArtistColors.border),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

// ============================================================
// PROFILE TILE
// ============================================================

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

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
                color: ArtistColors.light,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 21, color: ArtistColors.primary),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: ArtistTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: ArtistTextStyles.caption,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            trailing ??
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 21,
                  color: ArtistColors.textSecondary,
                ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// PROFILE DIVIDER
// ============================================================

class _ProfileDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 69),
      child: Divider(
        height: 1,
        thickness: 0.7,
        color: ArtistColors.border.withOpacity(0.7),
      ),
    );
  }
}

// ============================================================
// QUICK STAT CARD
// ============================================================

class _QuickStatCard extends StatelessWidget {
  const _QuickStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 12),
          decoration: BoxDecoration(
            color: ArtistColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ArtistColors.border),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: ArtistColors.primary),

              const SizedBox(height: 5),

              Text(value, style: ArtistTextStyles.title.copyWith(fontSize: 17)),

              const SizedBox(height: 1),

              Text(
                label,
                style: ArtistTextStyles.small.copyWith(fontSize: 9.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
