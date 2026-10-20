import 'package:flutter/material.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../app_theme/user/app_text_styles.dart';
import '../../../services/ecoloop_api.dart';
import '../../../shared_preferences_util.dart';
import '../../../widgets/cart_popup_user.dart';
import '../../../widgets/user_more_menu.dart';
import '../../common/help_support.dart';
import '../../welcome_screen.dart';
import '../buy_products/cart.dart';
import '../buy_products/orders.dart';
import '../buy_products/wishlist.dart';
import '../donations/donate_item.dart';
import '../donations/donation_history.dart';
import '../reviews/review_history.dart';
import '../sell_products/my_listings.dart';
import '../sell_products/selling_orders.dart';
import 'address_list.dart';
import 'eco_impact.dart';
import 'edit_profile.dart';
import 'following_list.dart';
import 'all_artist.dart';
import 'notifications.dart';
import 'rewards.dart';
import 'sellers_earning.dart';
import 'settings.dart';
import 'custom_service.dart';
import 'custom_service_history.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  Map<String, dynamic>? _account;
  bool _loadingProfile = true;
  String? _profileError;
  int _orderCount = 0;
  int _listingCount = 0;
  int _wishlistCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadProfileCounts();
  }

  Future<void> _loadProfile() async {
    try {
      final result = await EcoLoopApi.instance.get('/auth/me');
      if (!mounted) return;
      setState(() {
        _account = result is Map
            ? Map<String, dynamic>.from(result)
            : <String, dynamic>{};
        _loadingProfile = false;
        _profileError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingProfile = false;
        _profileError = error.toString();
      });
    }
  }

  List<Map<String, dynamic>> _countRows(dynamic value) {
    if (value is List)
      return value
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    if (value is Map) {
      final data = value['data'];
      if (data is List)
        return data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      for (final key in [
        'orders',
        'products',
        'items',
        'results',
        'wishlist',
      ]) {
        final rows = value[key] ?? (data is Map ? data[key] : null);
        if (rows is List)
          return rows
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
      }
    }
    return [];
  }

  Future<void> _loadProfileCounts() async {
    final api = EcoLoopApi.instance;
    try {
      final results = await Future.wait([
        api.get('/orders'),
        api.get('/my/products'),
        api.get('/wishlist'),
      ]);
      if (!mounted) return;
      final orders = _countRows(results[0]);
      final listings = _countRows(results[1]);
      final wishlist = _countRows(results[2]);
      setState(() {
        _orderCount = orders.length;
        _listingCount = listings
            .where(
              (p) => ![
            'deleted',
            'removed',
          ].contains((p['status'] ?? '').toString().toLowerCase()),
        )
            .length;
        _wishlistCount = wishlist.length;
      });
    } catch (_) {
      // Keep last known counts; retry when the profile is reopened/refreshed.
    }
  }

  String get _displayName {
    final account = _account ?? const <String, dynamic>{};
    final artistName = (account['userName'] ?? '').toString().trim();
    if (artistName.isNotEmpty) return artistName;
    final first = (account['firstName'] ?? '').toString().trim();
    final last = (account['lastName'] ?? '').toString().trim();
    final full = '$first $last'.trim();
    return full.isNotEmpty ? full : 'Your profile';
  }

  String get _email => (_account?['email'] ?? '').toString();

  /// Converts Google Drive viewer/share URLs into an image URL Flutter can request.
  /// The Apps Script backend also stores direct-view URLs; this handles legacy rows.
  String _displayableProfilePhotoUrl(String rawUrl) {
    final url = rawUrl.trim();
    if (url.isEmpty) return '';
    final match =
        RegExp(
          r'(?:drive\.google\.com|docs\.google\.com)/(?:file/d/|open\?id=|uc\?[^#]*?id=)([A-Za-z0-9_-]+)',
          caseSensitive: false,
        ).firstMatch(url) ??
            RegExp(r'[?&]id=([A-Za-z0-9_-]+)').firstMatch(url);
    if (match != null &&
        (url.contains('drive.google.com') || url.contains('docs.google.com'))) {
      return 'https://drive.google.com/uc?export=view&id=${match.group(1)}';
    }
    return url;
  }

  String get _photoUrl =>
      (_account?['profilePhotoUrl'] ?? '').toString().trim();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text('Profile', style: AppTextStyles.title),
        actions: const [UserMoreMenu(), SizedBox(width: 8)],
      ),
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
              _buildAccountSection(context),
              const SizedBox(height: 22),
              _buildCustomServiceSection(context),
              const SizedBox(height: 22),
              _buildSellingSection(context),
              const SizedBox(height: 22),
              _buildDonationSection(context),
              const SizedBox(height: 22),
              _buildPreferencesSection(context),
              const SizedBox(height: 22),
              _buildLogoutButton(context),
              const SizedBox(height: 14),

              Center(
                child: Text(
                  'EcoLoop • Give Things a New Life',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary.withOpacity(0.65),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // PROFILE HEADER

  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withOpacity(0.45)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.light,
                  border: Border.all(color: AppColors.accent, width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: _loadingProfile
                    ? const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
                    : (_photoUrl.isNotEmpty
                    ? Image.network(
                  _displayableProfilePhotoUrl(_photoUrl),
                  key: ValueKey<String>(
                    _displayableProfilePhotoUrl(_photoUrl),
                  ),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.person_rounded,
                    size: 46,
                    color: AppColors.primary,
                  ),
                )
                    : const Icon(
                  Icons.person_rounded,
                  size: 46,
                  color: AppColors.primary,
                )),
              ),
            ],
          ),

          const SizedBox(height: 13),

          Text(
            _loadingProfile ? 'Loading profile…' : _displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            _loadingProfile ? '' : _email,
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
          if (_profileError != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry loading profile'),
            ),
          ],

          const SizedBox(height: 5),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.eco_outlined,
                size: 15,
                color: AppColors.success,
              ),

              const SizedBox(width: 4),

              Text(
                'EcoLoop Member',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          SizedBox(
            height: 42,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfile()),
                ).then((_) {
                  _loadProfile();
                  _loadProfileCounts();
                });
              },
              icon: const Icon(Icons.edit_outlined, size: 17),
              label: const Text(
                'Edit Profile',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // QUICK STATS

  Widget _buildQuickStats(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickStatCard(
            icon: Icons.shopping_bag_outlined,
            value: _orderCount.toString(),
            label: 'Orders',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const Orders()),
              );
            },
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _QuickStatCard(
            icon: Icons.inventory_2_outlined,
            value: _listingCount.toString(),
            label: 'Listings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyListings()),
              );
            },
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _QuickStatCard(
            icon: Icons.favorite_border_rounded,
            value: _wishlistCount.toString(),
            label: 'Wishlist',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const Wishlist()),
              );
            },
          ),
        ),
      ],
    );
  }

  // MY ACCOUNT

  Widget _buildAccountSection(BuildContext context) {
    return _ProfileSection(
      title: 'My Account',
      children: [
        // CART
        _ProfileTile(
          icon: Icons.shopping_cart_outlined,
          title: 'My Cart',
          subtitle: CartPopup.isEmpty
              ? 'Your cart is empty'
              : '${CartPopup.totalItems} ${CartPopup.totalItems == 1 ? 'item' : 'items'} saved for checkout',
          trailing: _buildBadge(CartPopup.totalItems.toString()),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Cart(initialItems: CartPopup.items),
              ),
            );
          },
        ),
        _ProfileDivider(),

        // ORDERS
        _ProfileTile(
          icon: Icons.receipt_long_outlined,
          title: 'My Orders',
          subtitle: 'Track products you purchased',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Orders()),
            );
          },
        ),

        _ProfileDivider(),

        // REVIEW HISTORY
        _ProfileTile(
          icon: Icons.rate_review_outlined,
          title: 'Review History',
          subtitle: 'View and manage your product and seller reviews',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReviewHistory()),
            );
          },
        ),

        _ProfileDivider(),

        // WISHLIST

        // WISHLIST
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

        _ProfileDivider(),

        // MY LISTINGS
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

        _ProfileDivider(),

        // ADDRESSES
        _ProfileTile(
          icon: Icons.location_on_outlined,
          title: 'My Addresses',
          subtitle: 'Manage your delivery addresses',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddressList()),
            );
          },
        ),
      ],
    );
  }

  // CUSTOM SERVICE

  Widget _buildCustomServiceSection(BuildContext context) {
    return _ProfileSection(
      title: 'Custom Service',
      children: [
        // CREATE A CUSTOM SERVICE REQUEST
        _ProfileTile(
          icon: Icons.design_services_outlined,
          title: 'Custom Service',
          subtitle: 'Request a made-to-order project from a ReMaker',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CustomService()),
            );
          },
        ),
        _ProfileDivider(),

        // CUSTOM SERVICE REQUEST HISTORY
        _ProfileTile(
          icon: Icons.history_rounded,
          title: 'Custom Service History',
          subtitle: 'Track your requests and artist replies',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CustomServiceHistory()),
            );
          },
        ),
        _ProfileDivider(),

        // DISCOVER ALL ECLOOP ARTISTS
        _ProfileTile(
          icon: Icons.diversity_3_outlined,
          title: 'See All EcoLoop Artists',
          subtitle: 'Discover ReMakers, search and follow artists',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AllArtist()),
            );
          },
        ),
        _ProfileDivider(),

        // FOLLOWING ARTISTS / REMAKERS
        _ProfileTile(
          icon: Icons.person_add_alt_1_outlined,
          title: 'My Following',
          subtitle: 'Artists and ReMakers you follow',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FollowingList()),
            );
          },
        ),
      ],
    );
  }

  // SELLING

  Widget _buildSellingSection(BuildContext context) {
    return _ProfileSection(
      title: 'Selling',
      children: [
        // MY LISTINGS
        _ProfileTile(
          icon: Icons.sell_outlined,
          title: 'My Listings',
          subtitle: 'Add, edit and manage your products',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyListings()),
            );
          },
        ),

        _ProfileDivider(),

        // SELLING ORDERS
        _ProfileTile(
          icon: Icons.local_shipping_outlined,
          title: 'Selling Orders',
          subtitle: 'Orders received from your buyers',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SellingOrders()),
            );
          },
        ),

        _ProfileDivider(),

        // SELLING EARNINGS
        _ProfileTile(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Selling Earnings',
          subtitle: 'View your sales and earnings',
          trailing: const Icon(
            Icons.chevron_right_rounded,
            size: 21,
            color: AppColors.textSecondary,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SellersEarning()),
            );
          },
        ),
      ],
    );
  }

  // DONATIONS & REWARDS

  Widget _buildDonationSection(BuildContext context) {
    return _ProfileSection(
      title: 'Donations & Rewards',
      children: [
        // DONATE
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

        _ProfileDivider(),

        // DONATION HISTORY
        _ProfileTile(
          icon: Icons.history_rounded,
          title: 'Donation History',
          subtitle: 'View donated items and pickup status',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DonationHistory()),
            );
          },
        ),

        _ProfileDivider(),

        // REWARDS
        _ProfileTile(
          icon: Icons.redeem_outlined,
          title: 'Rewards',
          subtitle: 'View your Eco Points and rewards',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Rewards()),
            );
          },
        ),

        _ProfileDivider(),

        // ECO IMPACT
        _ProfileTile(
          icon: Icons.eco_outlined,
          title: 'Eco Impact',
          subtitle: 'See how much waste you helped reduce',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EcoImpact()),
            );
          },
        ),
      ],
    );
  }

  // PREFERENCES & SUPPORT

  Widget _buildPreferencesSection(BuildContext context) {
    return _ProfileSection(
      title: 'Preferences & Support',
      children: [
        // SETTINGS
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

        _ProfileDivider(),

        // NOTIFICATIONS
        _ProfileTile(
          icon: Icons.notifications_none_rounded,
          title: 'Notifications',
          subtitle: 'View your latest notifications',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Notifications()),
            );
          },
        ),

        _ProfileDivider(),

        // HELP & SUPPORT
        _ProfileTile(
          icon: Icons.help_outline_rounded,
          title: 'Help & Support',
          subtitle: 'Get help with EcoLoop',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HelpSupport()),
            );
          },
        ),
      ],
    );
  }

  // LOGOUT

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
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
    );
  }

  // BADGE

  Widget _buildBadge(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // LOGOUT DIALOG

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'Logout',
            style: AppTextStyles.title.copyWith(fontSize: 20),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: AppTextStyles.body,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
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
                backgroundColor: AppColors.error,
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

// PROFILE SECTION

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

// PROFILE TILE

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

            const SizedBox(width: 8),

            trailing ??
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

// PROFILE DIVIDER

class _ProfileDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 69),
      child: Divider(
        height: 1,
        thickness: 0.7,
        color: AppColors.accent.withOpacity(0.25),
      ),
    );
  }
}

// QUICK STAT CARD

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
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.accent.withOpacity(0.4)),
          ),
          child: Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.light,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),

              const SizedBox(height: 7),

              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 1),

              Text(label, style: AppTextStyles.caption),
            ],
          ),
        ),
      ),
    );
  }
}
