import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import '../../../services/ecoloop_api.dart';
import '../../../shared_preferences_util.dart';
import '../../../widgets/artist_more_menu.dart';
import '../../common/artist/contact_us.dart';
import '../../welcome_screen.dart';
import '../buy_products/buying_orders.dart';
import '../buy_products/cart.dart';
import '../buy_products/wishlist.dart';
import '../my_products/add_product.dart';
import '../my_products/my_product.dart';
import '../my_products/product_analytics.dart';
import '../my_products/selling_orders.dart';
import '../portfolio/portfolio.dart';
import '../reviews/review_history.dart';
import 'aboutyou.dart';
import 'address_list.dart';
import 'edit_profile.dart';
import 'followers.dart';
import 'following_list.dart';
import 'notification.dart';
import 'settings.dart';

/// Artist profile backed by the live Apps Script / Google Sheets API.
/// Profile details come from GET /profile and business numbers from
/// GET /artist/analytics. No demonstration numbers or fallback identity are used.
class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final EcoLoopApi _api = EcoLoopApi.instance;

  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  Map<String, dynamic> _profile = {};
  Map<String, dynamic> _analytics = {};
  int _followingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return <String, dynamic>{};
  }

  int _int(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  double _double(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString()) ?? 0;
  }

  String _value(dynamic value, {String fallback = ''}) {
    final text = (value ?? '').toString().trim();
    return text.isEmpty ? fallback : text;
  }

  Future<void> _loadProfile({bool refresh = false}) async {
    if (!mounted) return;
    setState(() {
      if (refresh) {
        _refreshing = true;
      } else {
        _loading = true;
      }
      _error = null;
    });

    try {
      final profileResponse = await _api.get('/profile');
      final profile = _asMap(profileResponse);
      if (profile.isEmpty) {
        throw const EcoLoopApiException(
          'The backend returned an empty artist profile.',
        );
      }

      // The photo uploader stores the newly uploaded URL in local preferences.
      // Some Apps Script deployments return a stale/blank profilePhotoUrl for
      // a moment after upload, so retain the latest uploaded URL for display.
      final savedPhotoUrl = _value(await Prefs.getString('profilePhotoUrl'));
      final backendPhotoUrl = _value(profile['profilePhotoUrl']);
      final photoToDisplay = savedPhotoUrl.isNotEmpty
          ? savedPhotoUrl
          : backendPhotoUrl;
      if (photoToDisplay.isNotEmpty) {
        profile['profilePhotoUrl'] = photoToDisplay;
      }

      Map<String, dynamic> analytics = {};
      String? analyticsError;
      try {
        analytics = _asMap(await _api.get('/artist/analytics'));
      } catch (e) {
        analyticsError =
            'Profile loaded, but live analytics could not be loaded: '
            '${e.toString().replaceFirst('Exception: ', '')}';
      }

      int followingCount = _followingCount;
      try {
        final followingResponse = _asMap(await _api.get('/my/following'));
        final followingRows =
            followingResponse['artists'] ??
            followingResponse['following'] ??
            followingResponse['data'];
        if (followingRows is List) {
          followingCount = followingRows.length;
        }
      } catch (_) {
        // Keep the last successfully loaded following count if this request fails.
      }

      if (!mounted) return;
      setState(() {
        _profile = profile;
        _analytics = analytics;
        _followingCount = followingCount;
        _loading = false;
        _refreshing = false;
        _error = analyticsError;
      });

      // Keep lightweight session display values in sync; the Sheet remains
      // the source of truth and is fetched again whenever this page opens.
      final name = _value(profile['userName']);
      final email = _value(profile['email']);
      final photo = _value(profile['profilePhotoUrl']);
      if (name.isNotEmpty) await Prefs.setString('userName', name);
      if (email.isNotEmpty) await Prefs.setString('userEmail', email);
      if (photo.isNotEmpty) await Prefs.setString('profilePhotoUrl', photo);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _refreshing = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String get _artistName => _value(_profile['userName'], fallback: 'Artist');

  String get _email => _value(_profile['email']);

  String get _phone => _value(_profile['phone']);

  String get _bio => _value(_profile['bio']);

  String get _city => _value(_profile['city']);

  String get _state => _value(_profile['state']);

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

  String get _photoUrl => _value(_profile['profilePhotoUrl']);

  String get _location {
    final parts = [_city, _state].where((part) => part.isNotEmpty).toList();
    return parts.isEmpty ? 'Location not added' : parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtistColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: ArtistColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text('Profile', style: ArtistTextStyles.title),
        actions: const [ArtistMoreMenu(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: ArtistColors.primary),
              )
            : RefreshIndicator(
                color: ArtistColors.primary,
                onRefresh: () => _loadProfile(refresh: true),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_error != null) ...[
                        _ErrorBanner(
                          message: _error!,
                          onRetry: () => _loadProfile(refresh: true),
                        ),
                        const SizedBox(height: 12),
                      ],
                      _buildProfileHeader(context),
                      const SizedBox(height: 16),
                      _buildFollowCards(context),
                      const SizedBox(height: 18),
                      if (_refreshing)
                        const LinearProgressIndicator(
                          minHeight: 2,
                          color: ArtistColors.primary,
                        ),
                      const SizedBox(height: 12),
                      _buildQuickStats(context),
                      const SizedBox(height: 24),
                      _buildMyAccountSection(context),
                      const SizedBox(height: 22),
                      _buildProductsSection(context),
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
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final experience = _value(_profile['experience']);
    final skills = _value(_profile['skills']);
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
            clipBehavior: Clip.antiAlias,
            child: _photoUrl.isNotEmpty
                ? Image.network(
                    _displayableProfilePhotoUrl(_photoUrl),
                    key: ValueKey<String>(
                      _displayableProfilePhotoUrl(_photoUrl),
                    ),
                    fit: BoxFit.cover,
                    frameBuilder:
                        (context, child, frame, wasSynchronouslyLoaded) {
                          if (wasSynchronouslyLoaded || frame != null)
                            return child;
                          return const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.person_rounded,
                      size: 48,
                      color: ArtistColors.primary,
                    ),
                  )
                : const Icon(
                    Icons.person_rounded,
                    size: 48,
                    color: ArtistColors.primary,
                  ),
          ),
          const SizedBox(height: 13),
          Text(
            _artistName,
            textAlign: TextAlign.center,
            style: ArtistTextStyles.title.copyWith(
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (_email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _email,
              textAlign: TextAlign.center,
              style: ArtistTextStyles.caption,
            ),
          ],
          const SizedBox(height: 6),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 15,
                color: ArtistColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  _location,
                  textAlign: TextAlign.center,
                  style: ArtistTextStyles.caption,
                ),
              ),
            ],
          ),
          if (experience.isNotEmpty || skills.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 7,
              runSpacing: 7,
              children: [
                if (experience.isNotEmpty)
                  _InfoChip(
                    icon: Icons.workspace_premium_outlined,
                    label: '$experience experience',
                  ),
                if (skills.isNotEmpty)
                  _InfoChip(icon: Icons.auto_awesome_outlined, label: skills),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final changed = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfile()),
                  );
                  if (changed == true && mounted) {
                    final savedPhotoUrl = _value(
                      await Prefs.getString('profilePhotoUrl'),
                    );
                    if (savedPhotoUrl.isNotEmpty) {
                      setState(() {
                        _profile = <String, dynamic>{
                          ..._profile,
                          'profilePhotoUrl': savedPhotoUrl,
                        };
                      });
                    }
                    await _loadProfile(refresh: true);
                  }
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
                  backgroundColor: ArtistColors.surface,
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
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Portfolio()),
                  );
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
                  backgroundColor: ArtistColors.surface,
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
          if (_bio.isNotEmpty) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _bio,
                textAlign: TextAlign.start,
                style: ArtistTextStyles.body.copyWith(
                  color: ArtistColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFollowCards(BuildContext context) {
    final followers = _int(_analytics['followers']);

    return Row(
      children: [
        Expanded(
          child: _FollowCountCard(
            icon: Icons.people_alt_outlined,
            label: 'Followers',
            count: followers,
            subtitle: 'People following you',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Followers()),
            ).then((_) => _loadProfile(refresh: true)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _FollowCountCard(
            icon: Icons.person_add_alt_1_rounded,
            label: 'Following',
            count: _followingCount,
            subtitle: 'Artists you follow',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FollowingList()),
            ).then((_) => _loadProfile(refresh: true)),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    final products = _int(_analytics['totalProducts']);
    final orders = _int(_analytics['totalOrders']);
    final rating = _double(_analytics['averageRating']);

    final stats = <Widget>[
      _QuickStatCard(
        icon: Icons.inventory_2_outlined,
        value: products.toString(),
        label: 'Products',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyProducts()),
        ),
      ),
      _QuickStatCard(
        icon: Icons.shopping_bag_outlined,
        value: orders.toString(),
        label: 'Orders',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SellingOrders()),
        ),
      ),
      _QuickStatCard(
        icon: Icons.star_outline_rounded,
        value: rating.toStringAsFixed(1),
        label: 'Rating',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReviewHistory()),
        ),
      ),
    ];

    // Use a responsive grid instead of forcing four cards into one narrow row.
    // This prevents tight constraints and text clipping on smaller phones.
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width - 36;
        final columns = availableWidth >= 520 ? 4 : 2;
        final spacing = 8.0;
        final cardWidth = (availableWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: stats
              .map((stat) => SizedBox(width: cardWidth, child: stat))
              .toList(),
        );
      },
    );
  }

  String _compactCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  Widget _buildMyAccountSection(BuildContext context) {
    return _ProfileSection(
      title: 'My Account',
      children: [
        _ProfileTile(
          icon: Icons.person_outline_rounded,
          title: 'About You',
          subtitle: 'Tell buyers about yourself and your creative journey',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AboutYou()),
          ),
        ),
        const _ProfileDivider(),
        _ProfileTile(
          icon: Icons.collections_outlined,
          title: 'Portfolio',
          subtitle: 'Showcase your creative work',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const Portfolio()),
          ),
        ),
        const _ProfileDivider(),
        _ProfileTile(
          icon: Icons.shopping_bag_outlined,
          title: 'My Orders',
          subtitle: 'View and track your purchases',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BuyingOrders()),
          ),
        ),
        const _ProfileDivider(),
        _ProfileTile(
          icon: Icons.shopping_cart_outlined,
          title: 'My Cart',
          subtitle: 'View products added to your shopping cart',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const Cart()),
          ),
        ),
        const _ProfileDivider(),
        _ProfileTile(
          icon: Icons.rate_review_outlined,
          title: 'Review History',
          subtitle: 'View product and seller reviews',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReviewHistory()),
          ),
        ),
        const _ProfileDivider(),
        _ProfileTile(
          icon: Icons.inventory_2_outlined,
          title: 'My Products',
          subtitle: 'View and manage your listings',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyProducts()),
          ),
        ),
        const _ProfileDivider(),
        _ProfileTile(
          icon: Icons.location_on_outlined,
          title: 'My Addresses',
          subtitle: 'Manage your saved addresses',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddressList()),
          ),
        ),
      ],
    );
  }

  Widget _buildProductsSection(BuildContext context) {
    return _ProfileSection(
      title: 'Products',
      children: [
        _ProfileTile(
          icon: Icons.inventory_2_outlined,
          title: 'My Products',
          subtitle: 'View and manage your listed products',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyProducts()),
          ),
        ),
        const _ProfileDivider(),
        _ProfileTile(
          icon: Icons.add_business_outlined,
          title: 'Add Product',
          subtitle: 'Create a new product listing',
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddProduct()),
            );
            if (mounted) _loadProfile(refresh: true);
          },
        ),
        const _ProfileDivider(),
        _ProfileTile(
          icon: Icons.analytics_outlined,
          title: 'Product Analytics',
          subtitle: 'Track views, sales and product performance',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProductAnalytics()),
          ),
        ),
        const _ProfileDivider(),
        _ProfileTile(
          icon: Icons.favorite_border_rounded,
          title: 'Wishlist',
          subtitle: 'View products you saved',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const Wishlist()),
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessSection(BuildContext context) {
    return _ProfileSection(
      title: 'Business',
      children: [
        _ProfileTile(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Earnings',
          subtitle:
              '₹${_double(_analytics['revenue']).toStringAsFixed(2)} recorded revenue',
          onTap: () => _showComingSoon(context, 'Earnings'),
        ),
        const _ProfileDivider(),
        _ProfileTile(
          icon: Icons.people_outline_rounded,
          title: 'Followers',
          subtitle:
              '${_int(_analytics['followers'])} people follow your artist profile',
          trailing: _buildBadge(_compactCount(_int(_analytics['followers']))),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const Followers()),
          ),
        ),
        const _ProfileDivider(),
        _ProfileTile(
          icon: Icons.collections_outlined,
          title: 'Portfolio',
          subtitle: 'Showcase your creative work',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const Portfolio()),
          ),
        ),
      ],
    );
  }

  Widget _buildPreferencesSection(BuildContext context) {
    return _ProfileSection(
      title: 'Preferences & Support',
      children: [
        _ProfileTile(
          icon: Icons.settings_outlined,
          title: 'Settings',
          subtitle: 'App preferences and account settings',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const Settings()),
          ),
        ),
        const _ProfileDivider(),
        _ProfileTile(
          icon: Icons.notifications_none_rounded,
          title: 'Notifications',
          subtitle: 'View your latest notifications',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const Notifications()),
          ),
        ),
        const _ProfileDivider(),
        _ProfileTile(
          icon: Icons.contact_support_outlined,
          title: 'Contact Us',
          subtitle: 'Get help or contact EcoLoop support',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ContactUs()),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showLogoutDialog(context),
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
          backgroundColor: ArtistColors.surface,
          side: BorderSide(color: ArtistColors.error.withOpacity(0.35)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
    );
  }

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

  void _showComingSoon(BuildContext context, String page) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '$page is not connected to a dedicated screen yet.',
            style: ArtistTextStyles.bodyMedium.copyWith(
              color: Colors.white,
              fontSize: 13,
            ),
          ),
          backgroundColor: ArtistColors.accent,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ArtistColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
            onPressed: () => Navigator.pop(dialogContext),
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
              try {
                await _api.post('/auth/logout', {});
              } catch (_) {
                // Clear local session even if the network is unavailable.
              }
              await Prefs.setBool('isLoggedIn', false);
              await Prefs.setString('authToken', '');
              await Prefs.setString('artistToken', '');
              await Prefs.setString('userRole', '');
              await Prefs.setString('userEmail', '');
              await Prefs.setString('userName', '');
              await Prefs.setString('profilePhotoUrl', '');
              if (!context.mounted) return;
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
            child: Text(
              'Logout',
              style: ArtistTextStyles.button.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ArtistColors.error.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ArtistColors.error.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, color: ArtistColors.error),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: ArtistTextStyles.caption.copyWith(
                color: ArtistColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            color: ArtistColors.primary,
            tooltip: 'Retry',
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 270),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: ArtistColors.light.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: ArtistColors.primary),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: ArtistTextStyles.small.copyWith(
                color: ArtistColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: ArtistColors.primary.withOpacity(0.06),
        highlightColor: ArtistColors.primary.withOpacity(0.03),
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
                        color: ArtistColors.textPrimary,
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
      ),
    );
  }
}

class _ProfileDivider extends StatelessWidget {
  const _ProfileDivider();

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

class _FollowCountCard extends StatelessWidget {
  const _FollowCountCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ArtistColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 116),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ArtistColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: ArtistColors.light,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(icon, color: ArtistColors.primary, size: 19),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_outward_rounded,
                    size: 16,
                    color: ArtistColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    count.toString(),
                    style: ArtistTextStyles.title.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      label,
                      style: ArtistTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ArtistTextStyles.small.copyWith(
                  color: ArtistColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
        splashColor: ArtistColors.primary.withOpacity(0.06),
        highlightColor: ArtistColors.primary.withOpacity(0.03),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 12),
          decoration: BoxDecoration(
            color: ArtistColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ArtistColors.border),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: ArtistColors.primary),
              const SizedBox(height: 5),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: ArtistTextStyles.title.copyWith(fontSize: 16),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ArtistTextStyles.small.copyWith(fontSize: 9.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
