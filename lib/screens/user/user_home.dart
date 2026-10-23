import 'package:ecoloop/services/ecoloop_api.dart';
import 'package:ecoloop/services/profile_snapshot.dart';
import 'package:flutter/material.dart';

import '../../app_theme/user/app_text_styles.dart';
import '../../shared_preferences_util.dart';
import '../../widgets/user_more_menu.dart';
import 'buy_products/marketplace.dart';
import 'buy_products/product_details.dart';
import 'donations/donate_item.dart';
import 'sell_products/add_product.dart';

// Five-minute in-memory cache for public discovery data only. Account-specific
// data (profile, rewards and impact) is refreshed separately and never stored here.
class _UserHomeDiscoveryCache {
  _UserHomeDiscoveryCache({
    required this.categories,
    required this.products,
    required this.savedAt,
  });

  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> products;
  final DateTime savedAt;

  bool get isFresh =>
      DateTime.now().difference(savedAt) < const Duration(minutes: 5);
}

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  static _UserHomeDiscoveryCache? _discoveryCache;
  int _loadGeneration = 0;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _categories = [];
  Map<String, dynamic> _profile = {};
  Map<String, dynamic> _impact = {};
  Map<String, dynamic> _rewards = {};

  bool _loading = true;
  bool _refreshing = false;
  bool _productsError = false;
  bool _categoriesError = false;
  String? _errorMessage;
  String _searchQuery = '';

  static const Color _deepGreen = Color(0xFF183D2C);
  static const Color _forest = Color(0xFF2A4D3A);
  static const Color _sage = Color(0xFFDCE8DC);
  static const Color _cream = Color(0xFFF7F5EE);
  static const Color _muted = Color(0xFF748078);

  @override
  void initState() {
    super.initState();
    ProfileSnapshot.account.addListener(_onSharedProfileChanged);
    final cachedProfile = ProfileSnapshot.account.value;
    if (cachedProfile != null && cachedProfile.isNotEmpty) {
      _profile = Map<String, dynamic>.from(cachedProfile);
    } else {
      // Paint the greeting from local preferences immediately. Do not wait
      // for the network profile request just to display the user's name.
      final savedName = Prefs.getString('userName').trim();
      final savedEmail = Prefs.getString('userEmail').trim();
      final savedPhoto = Prefs.getString('profilePhotoUrl').trim();
      if (savedName.isNotEmpty ||
          savedEmail.isNotEmpty ||
          savedPhoto.isNotEmpty) {
        final nameParts = savedName.split(RegExp(r'\s+'));
        _profile = <String, dynamic>{
          if (nameParts.isNotEmpty && nameParts.first.isNotEmpty)
            'firstName': nameParts.first,
          if (nameParts.length > 1) 'lastName': nameParts.skip(1).join(' '),
          if (savedName.isNotEmpty) 'name': savedName,
          if (savedEmail.isNotEmpty) 'email': savedEmail,
          if (savedPhoto.isNotEmpty) 'profilePhotoUrl': savedPhoto,
        };
      }
    }
    _loadDashboard();
  }

  void _onSharedProfileChanged() {
    final updated = ProfileSnapshot.account.value;
    if (!mounted || updated == null || updated.isEmpty) return;
    setState(() {
      _profile = <String, dynamic>{..._profile, ...updated};
    });
  }

  @override
  void dispose() {
    ProfileSnapshot.account.removeListener(_onSharedProfileChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard({bool refresh = false}) async {
    final generation = ++_loadGeneration;
    final cached = _discoveryCache;

    // Repaint cached marketplace data immediately on a warm visit. Fresh data
    // is then requested in the background without blocking the existing UI.
    if (!refresh && cached != null && cached.isFresh) {
      setState(() {
        _categories = cached.categories
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _products = cached.products
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _categoriesError = false;
        _productsError = false;
        _loading = false;
        _refreshing = false;
        _errorMessage = null;
      });
    } else if (_products.isEmpty && _categories.isEmpty) {
      setState(() {
        _loading = true;
        _refreshing = refresh;
      });
    } else {
      setState(() => _refreshing = refresh);
    }

    // Start all five endpoints together. Secondary account data is applied as
    // soon as it arrives and cannot delay marketplace content rendering.
    _loadSecondaryDashboard(generation);

    final primaryResults = await Future.wait<dynamic>([
      _safeGet('/categories'),
      _safeGet('/products'),
    ]);

    if (!mounted || generation != _loadGeneration) return;

    final categoryResult = primaryResults[0];
    final productResult = primaryResults[1];
    var nextCategories = _categories;
    var nextProducts = _products;
    var categoriesSucceeded = false;
    var productsSucceeded = false;

    if (categoryResult is List) {
      nextCategories = categoryResult
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where(
            (e) =>
                (e['status'] ?? 'active').toString().toLowerCase() == 'active',
          )
          .toList(growable: false);
      categoriesSucceeded = true;
    }

    if (productResult is List) {
      // Normalize after assigning categories so fallback category labels are
      // resolved against the latest category data.
      _categories = nextCategories;
      nextProducts = productResult
          .whereType<Map>()
          .map(_normalizeProduct)
          .where(
            (p) =>
                (p['status'] ?? 'published').toString().toLowerCase() ==
                'published',
          )
          .where(
            (p) =>
                (p['availableQuantity'] == null ||
                _number(p['availableQuantity']) > 0),
          )
          .toList(growable: false);
      productsSucceeded = true;
    }

    setState(() {
      if (categoriesSucceeded) {
        _categories = nextCategories;
        _categoriesError = false;
      } else if (_categories.isEmpty) {
        _categoriesError = true;
      }

      if (productsSucceeded) {
        _products = nextProducts;
        _productsError = false;
      } else if (_products.isEmpty) {
        _productsError = true;
      }

      _errorMessage = _productsError && _categoriesError
          ? 'We could not load marketplace data. Check your connection and try again.'
          : null;
      _loading = false;
      _refreshing = false;
    });

    // Save only public marketplace discovery data, never private account data.
    // Keep the last good result if one endpoint temporarily fails.
    if (categoriesSucceeded || productsSucceeded) {
      _discoveryCache = _UserHomeDiscoveryCache(
        categories: _categories
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: false),
        products: _products
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: false),
        savedAt: DateTime.now(),
      );
    }
  }

  Future<void> _loadSecondaryDashboard(int generation) async {
    final profileRevisionAtStart = ProfileSnapshot.revision;
    final results = await Future.wait<dynamic>([
      _safeGet('/auth/me'),
      _safeGet('/eco-impact'),
      _safeGet('/rewards'),
    ]);

    if (!mounted || generation != _loadGeneration) return;

    final profileResult = results[0];
    final impactResult = results[1];
    final rewardResult = results[2];
    Map<String, dynamic>? loadedProfile;

    setState(() {
      if (profileResult is Map &&
          profileRevisionAtStart == ProfileSnapshot.revision) {
        loadedProfile = Map<String, dynamic>.from(profileResult);
        _profile = <String, dynamic>{..._profile, ...loadedProfile!};
      }
      if (impactResult is Map) {
        _impact = Map<String, dynamic>.from(impactResult);
      }
      if (rewardResult is Map) {
        _rewards = Map<String, dynamic>.from(rewardResult);
      }
    });

    // Notify other screens only after setState has completed.
    if (loadedProfile != null) {
      ProfileSnapshot.publish(loadedProfile!);
    }
  }

  Future<dynamic> _safeGet(String path) async {
    try {
      return await EcoLoopApi.instance.get(path);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _normalizeProduct(Map raw) {
    final product = Map<String, dynamic>.from(raw);
    final rawImages = product['imageUrls'];
    final images = rawImages is List
        ? rawImages
              .map((e) => e.toString())
              .where((e) => e.trim().isNotEmpty)
              .toList()
        : <String>[];
    final city = (product['sellerCity'] ?? product['city'] ?? '')
        .toString()
        .trim();
    final state = (product['sellerState'] ?? product['state'] ?? '')
        .toString()
        .trim();
    final location = [city, state].where((e) => e.isNotEmpty).join(', ');
    return {
      ...product,
      'id': product['productId'] ?? product['id'],
      'seller': product['sellerName'] ?? 'EcoLoop Member',
      'category':
          product['categoryName'] ?? _categoryName(product['categoryId']),
      'location': location,
      'image': images.isNotEmpty ? images.first : '',
      'images': images,
      'price': product['price'] ?? 0,
      'condition': product['condition'] ?? 'Not specified',
      'availableQuantity': product['availableQuantity'] ?? product['quantity'],
    };
  }

  String _categoryName(dynamic id) {
    for (final category in _categories) {
      if (category['categoryId'].toString() == id.toString()) {
        return (category['name'] ?? 'Category').toString();
      }
    }
    return 'Marketplace';
  }

  int _number(dynamic value) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _decimal(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String get _firstName {
    final first = (_profile['firstName'] ?? '').toString().trim();
    if (first.isNotEmpty) return first;
    final full = (_profile['name'] ?? _profile['userName'] ?? '')
        .toString()
        .trim();
    if (full.isNotEmpty) return full.split(RegExp(r'\s+')).first;
    return 'there';
  }

  String get _profileImage =>
      (_profile['profilePhotoUrl'] ?? '').toString().trim();

  int get _ecoPoints {
    final fromRewards = _rewards['totalPoints'];
    if (fromRewards != null) return _number(fromRewards);
    return _number(_impact['ecoPoints']);
  }

  String _normalizedIdentity(dynamic value) =>
      (value ?? '').toString().trim().toLowerCase();

  bool _isOwnProduct(Map<String, dynamic> product) {
    // The dashboard is a discovery preview, so never recommend the signed-in
    // user's own listing. The marketplace itself remains unchanged.
    final profileId =
        _profile['userId'] ??
        _profile['user_id'] ??
        _profile['id'] ??
        _profile['idUser'];
    final profileEmail = _normalizedIdentity(
      _profile['email'] ?? _profile['gmail'] ?? _profile['userEmail'],
    );

    final productSellerId =
        product['sellerId'] ??
        product['seller_id'] ??
        product['userId'] ??
        product['user_id'] ??
        product['ownerId'] ??
        product['owner_id'];
    final productSellerEmail = _normalizedIdentity(
      product['sellerEmail'] ??
          product['seller_email'] ??
          product['userEmail'] ??
          product['ownerEmail'],
    );

    final hasProfileId =
        profileId != null && profileId.toString().trim().isNotEmpty;
    final hasSellerId =
        productSellerId != null && productSellerId.toString().trim().isNotEmpty;
    if (hasProfileId &&
        hasSellerId &&
        profileId.toString().trim() == productSellerId.toString().trim()) {
      return true;
    }
    return profileEmail.isNotEmpty &&
        productSellerEmail.isNotEmpty &&
        profileEmail == productSellerEmail;
  }

  List<Map<String, dynamic>> get _visibleProducts {
    final query = _searchQuery.trim().toLowerCase();
    final otherSellersProducts = _products.where(
      (product) => !_isOwnProduct(product),
    );
    final matchingProducts = query.isEmpty
        ? otherSellersProducts
        : otherSellersProducts.where((product) {
            return [
              'title',
              'description',
              'category',
              'condition',
              'seller',
            ].any(
              (key) =>
                  (product[key] ?? '').toString().toLowerCase().contains(query),
            );
          });

    // Keep the home dashboard compact: show at most four available listings.
    // The See all action still opens the full marketplace.
    return matchingProducts.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: RefreshIndicator(
          color: _forest,
          onRefresh: () => _loadDashboard(refresh: true),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(child: _buildTopBar()),
              SliverToBoxAdapter(child: _buildWelcomeHero()),
              SliverToBoxAdapter(child: _buildSearch()),
              SliverToBoxAdapter(child: _buildQuickActions()),
              SliverToBoxAdapter(child: _buildImpactStrip()),
              SliverToBoxAdapter(child: _buildCategoriesSection()),
              SliverToBoxAdapter(child: _buildMarketplaceHeading()),
              SliverToBoxAdapter(child: _buildProductSection()),
              SliverToBoxAdapter(child: _buildCircularCallout()),
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 4),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_deepGreen, _forest],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: _deepGreen.withOpacity(.18),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 27),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EcoLoop',
                  style: AppTextStyles.title.copyWith(
                    fontSize: 20,
                    color: _deepGreen,
                    letterSpacing: -.5,
                  ),
                ),
                const SizedBox(height: 1),
                const Text(
                  'A better life for every item',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: _muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _sage),
            ),
            child: IconButton(
              tooltip: 'Refresh dashboard',
              onPressed: () => _loadDashboard(refresh: true),
              icon: const Icon(Icons.refresh_rounded, color: _forest, size: 20),
            ),
          ),
          const SizedBox(width: 5),
          const UserMoreMenu(),
        ],
      ),
    );
  }

  Widget _buildWelcomeHero() {
    final greeting = DateTime.now().hour < 12
        ? 'Good morning'
        : DateTime.now().hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(21, 22, 18, 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_deepGreen, Color(0xFF315D42), _forest],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(27),
          boxShadow: [
            BoxShadow(
              color: _deepGreen.withOpacity(.17),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -22,
              top: -27,
              child: Container(
                width: 145,
                height: 145,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(.08),
                    width: 25,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 9,
              bottom: -35,
              child: Icon(
                Icons.eco_rounded,
                size: 118,
                color: Colors.white.withOpacity(.055),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.12),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(.12),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.spa_outlined,
                            color: Color(0xFFD8E9C8),
                            size: 13,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'LIVE SUSTAINABLY',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              letterSpacing: 1.05,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (_profileImage.isNotEmpty)
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white24,
                        backgroundImage: NetworkImage(_profileImage),
                      )
                    else
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white.withOpacity(.14),
                        child: Text(
                          _firstName == 'there'
                              ? 'E'
                              : _firstName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 21),
                Text(
                  '$greeting,',
                  style: TextStyle(
                    color: Colors.white.withOpacity(.78),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _firstName == 'there'
                      ? 'Welcome to EcoLoop'
                      : '$_firstName 👋',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.8,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 270),
                  child: Text(
                    'Discover pre-loved finds and give useful things a second life.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(.78),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 19),
                Row(
                  children: [
                    _heroAction(
                      'Explore items',
                      Icons.arrow_forward_rounded,
                      () => _openMarketplace(),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.stars_rounded,
                            size: 16,
                            color: Color(0xFFE8D99D),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '$_ecoPoints pts',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroAction(String label, IconData icon, VoidCallback onTap) {
    return Material(
      color: const Color(0xFFE5EEDC),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: _deepGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 7),
              Icon(icon, size: 15, color: _deepGreen),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 19, 20, 0),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0xFFE2E8DE)),
          boxShadow: [
            BoxShadow(
              color: _deepGreen.withOpacity(.035),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          onSubmitted: (value) => _openMarketplace(
            search: value.trim().isEmpty ? null : value.trim(),
          ),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: _forest,
              size: 23,
            ),
            hintText: 'Search furniture, decor, books...',
            hintStyle: const TextStyle(color: Color(0xFF9AA39B), fontSize: 12),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                      color: _muted,
                      size: 19,
                    ),
                  )
                : IconButton(
                    onPressed: () => _openMarketplace(
                      search: _searchController.text.trim().isEmpty
                          ? null
                          : _searchController.text.trim(),
                    ),
                    icon: const Icon(
                      Icons.tune_rounded,
                      color: _forest,
                      size: 20,
                    ),
                  ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 17),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _actionTile(
              icon: Icons.add_box_rounded,
              title: 'Sell an item',
              subtitle: 'List something useful',
              tint: const Color(0xFFE4EDE0),
              onTap: _openAddProduct,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: _actionTile(
              icon: Icons.volunteer_activism_rounded,
              title: 'Donate',
              subtitle: 'Pass it forward',
              tint: const Color(0xFFF2E8D9),
              onTap: _openDonate,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color tint,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8ECE5)),
          ),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: _forest, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _deepGreen,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: _muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImpactStrip() {
    final reused = _number(_impact['itemsReused']);
    final donated = _number(_impact['itemsDonated']);
    final co2 = _decimal(_impact['co2Saved']);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(15, 15, 15, 14),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF0E6),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: const Color(0xFFDCE6D8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.energy_savings_leaf_rounded,
                  size: 18,
                  color: _forest,
                ),
                const SizedBox(width: 7),
                const Expanded(
                  child: Text(
                    'Your positive impact',
                    style: TextStyle(
                      fontSize: 13,
                      color: _deepGreen,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  'FROM YOUR ACTIVITY',
                  style: TextStyle(
                    fontSize: 8,
                    letterSpacing: .7,
                    color: _forest.withOpacity(.72),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                Expanded(
                  child: _impactMetric(
                    Icons.recycling_rounded,
                    '$reused',
                    'Items reused',
                  ),
                ),
                _verticalDivider(),
                Expanded(
                  child: _impactMetric(
                    Icons.volunteer_activism_rounded,
                    '$donated',
                    'Donated',
                  ),
                ),
                _verticalDivider(),
                Expanded(
                  child: _impactMetric(
                    Icons.cloud_done_rounded,
                    '${co2.toStringAsFixed(co2.truncateToDouble() == co2 ? 0 : 1)} kg',
                    'CO₂ saved',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _impactMetric(IconData icon, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: _forest),
        const SizedBox(height: 7),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 17,
            color: _deepGreen,
            fontWeight: FontWeight.w800,
            letterSpacing: -.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 9,
            color: _muted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _verticalDivider() => Container(
    height: 49,
    width: 1,
    margin: const EdgeInsets.symmetric(horizontal: 9),
    color: const Color(0xFFD4DFD0),
  );

  Widget _buildCategoriesSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 26),
      child: Column(
        children: [
          _sectionHeader(
            'Explore categories',
            'Find your next useful thing',
            onSeeAll: _openMarketplace,
          ),
          const SizedBox(height: 13),
          if (_loading && _categories.isEmpty)
            const SizedBox(
              height: 86,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _forest,
                ),
              ),
            )
          else if (_categoriesError && _categories.isEmpty)
            _inlineRetry(
              'Categories could not be loaded.',
              () => _loadDashboard(refresh: true),
            )
          else if (_categories.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Text(
                'Categories will appear here when they are available.',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
            )
          else
            SizedBox(
              height: 105,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final name = (category['name'] ?? 'Category').toString();
                  final icon = _iconForCategory(name);
                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(17),
                    child: InkWell(
                      onTap: () => _openMarketplace(category: name),
                      borderRadius: BorderRadius.circular(17),
                      child: Container(
                        width: 91,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(color: const Color(0xFFE6EBE2)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 45,
                              height: 43,
                              decoration: BoxDecoration(
                                color: _sage.withOpacity(.7),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Icon(icon, color: _forest, size: 23),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                color: _deepGreen,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  IconData _iconForCategory(String value) {
    final name = value.toLowerCase();
    if (name.contains('furniture')) return Icons.chair_alt_rounded;
    if (name.contains('decor')) return Icons.weekend_rounded;
    if (name.contains('electronic')) return Icons.devices_other_rounded;
    if (name.contains('material')) return Icons.layers_rounded;
    if (name.contains('fashion') || name.contains('cloth'))
      return Icons.checkroom_rounded;
    if (name.contains('book')) return Icons.menu_book_rounded;
    if (name.contains('kitchen')) return Icons.kitchen_rounded;
    if (name.contains('toy')) return Icons.toys_rounded;
    return Icons.category_rounded;
  }

  Widget _buildMarketplaceHeading() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
    child: _sectionHeader(
      _searchQuery.trim().isEmpty ? 'Fresh finds for you' : 'Matching items',
      _searchQuery.trim().isEmpty
          ? 'Recently listed on EcoLoop'
          : 'From available listings',
      onSeeAll: () => _openMarketplace(
        search: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
      ),
    ),
  );

  Widget _sectionHeader(
    String title,
    String subtitle, {
    VoidCallback? onSeeAll,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.title.copyWith(
                    fontSize: 18,
                    color: _deepGreen,
                    letterSpacing: -.35,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: _muted, fontSize: 10.5),
                ),
              ],
            ),
          ),
          if (onSeeAll != null)
            InkWell(
              onTap: onSeeAll,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                child: Row(
                  children: [
                    Text(
                      'See all',
                      style: TextStyle(
                        color: _forest,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 3),
                    Icon(Icons.arrow_forward_rounded, size: 14, color: _forest),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductSection() {
    if (_loading && _products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(30),
        child: Center(
          child: CircularProgressIndicator(color: _forest, strokeWidth: 2),
        ),
      );
    }
    if (_productsError && _products.isEmpty) {
      return _inlineRetry(
        'We could not load listings from the marketplace.',
        () => _loadDashboard(refresh: true),
      );
    }
    final products = _visibleProducts;
    if (products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE7ECE4)),
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: _sage,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: _forest,
                  size: 27,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _searchQuery.isEmpty
                    ? 'Your next find is on its way'
                    : 'No items match your search',
                style: const TextStyle(
                  color: _deepGreen,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _searchQuery.isEmpty
                    ? 'There are no available listings right now. Check back soon.'
                    : 'Try another name or browse all marketplace items.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
              if (_searchQuery.isNotEmpty)
                TextButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: const Text('Clear search'),
                ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: products.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 13,
          childAspectRatio: .64,
        ),
        itemBuilder: (context, index) => _ProductCard(
          product: products[index],
          onTap: () => _openProduct(products[index]),
        ),
      ),
    );
  }

  Widget _inlineRetry(String message, VoidCallback onRetry) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE6EBE2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, color: _muted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularCallout() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF0E9DA),
          borderRadius: BorderRadius.circular(21),
          border: Border.all(color: const Color(0xFFE9DFC9)),
        ),
        child: Row(
          children: [
            Container(
              width: 47,
              height: 47,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.8),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.recycling_rounded,
                color: _forest,
                size: 25,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Make room for a little good.',
                    style: TextStyle(
                      color: _deepGreen,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sell what you no longer need, or donate it to someone who does.',
                    style: TextStyle(
                      color: _deepGreen.withOpacity(.72),
                      fontSize: 10.5,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              onPressed: _openDonate,
              tooltip: 'Donate an item',
              icon: const Icon(Icons.arrow_forward_rounded, color: _forest),
            ),
          ],
        ),
      ),
    );
  }

  void _openMarketplace({String? search, String? category}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            Marketplace(initialSearch: search, initialCategory: category),
      ),
    );
  }

  void _openAddProduct() => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const AddProduct()));

  void _openDonate() => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const DonateItem()));

  void _openProduct(Map<String, dynamic> product) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ProductDetails(product: product)));
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onTap});

  final Map<String, dynamic> product;
  final VoidCallback onTap;

  static const Color _deepGreen = Color(0xFF183D2C);
  static const Color _forest = Color(0xFF2A4D3A);
  static const Color _muted = Color(0xFF748078);

  @override
  Widget build(BuildContext context) {
    final priceValue = product['price'];
    final price = priceValue is num
        ? priceValue
        : num.tryParse(priceValue?.toString() ?? '') ?? 0;
    final image = (product['image'] ?? '').toString().trim();
    final title = (product['title'] ?? 'Untitled item').toString();
    final category = (product['category'] ?? 'Marketplace').toString();
    final condition = (product['condition'] ?? 'Not specified').toString();
    final seller = (product['seller'] ?? 'EcoLoop Member').toString();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: const Color(0xFFE5EAE2)),
            boxShadow: [
              BoxShadow(
                color: _deepGreen.withOpacity(.035),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (image.isNotEmpty)
                      Image.network(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imagePlaceholder(),
                      )
                    else
                      _imagePlaceholder(),
                    Positioned(
                      top: 9,
                      left: 9,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.94),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          condition,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _forest,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 9,
                      left: 9,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _deepGreen.withOpacity(.82),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _deepGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '₹${price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _forest,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.4,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline_rounded,
                          size: 13,
                          color: _muted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            seller,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_outward_rounded,
                          size: 13,
                          color: _forest,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
    color: const Color(0xFFEAF0E6),
    child: const Center(
      child: Icon(Icons.image_outlined, color: _forest, size: 34),
    ),
  );
}
