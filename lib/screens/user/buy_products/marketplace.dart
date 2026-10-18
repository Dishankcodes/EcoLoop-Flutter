import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../app_theme/user/app_text_styles.dart';
import '../../../services/ecoloop_api.dart';
import '../../../widgets/user_more_menu.dart';
import 'artist_profile.dart';
import 'product_details.dart';
import 'seller_profile.dart';
import 'wishlist.dart';

class Marketplace extends StatefulWidget {
  const Marketplace({
    super.key,
    this.initialSearch,
    this.initialCategory,
    this.returnToCheckoutOnSelect = false,
  });

  final String? initialSearch;
  final String? initialCategory;

  /// When launched from checkout, selecting a product returns it to that same checkout route.
  final bool returnToCheckoutOnSelect;

  @override
  State<Marketplace> createState() => _MarketplaceState();
}

class _MarketplaceState extends State<Marketplace> {
  // STATE

  String selectedCategory = 'All';

  String searchQuery = '';
  String selectedCondition = 'All';
  String selectedSort = 'Newest First';

  RangeValues priceRange = const RangeValues(0, 10000);

  final TextEditingController _searchController = TextEditingController();

  List<String> _backendCategories = [];

  List<String> get categories => ['All', ..._backendCategories];

  List<String> get conditions {
    final values =
        products
            .map((product) => (product['condition'] ?? '').toString().trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return ['All', ...values];
  }

  double get _maximumProductPrice {
    final maximum = products.fold<double>(0, (current, product) {
      final value = product['price'];
      final price = value is num
          ? value.toDouble()
          : double.tryParse((value ?? '').toString()) ?? 0;
      return price > current ? price : current;
    });
    return maximum <= 0 ? 100 : maximum;
  }

  // Live products loaded from the EcoLoop backend.
  final EcoLoopApi _api = EcoLoopApi.instance;
  bool _loadingProducts = true;
  String? _productsError;
  List<Map<String, dynamic>> products = [];

  // IDs are loaded from the authenticated account's own listings and wishlist.
  String? _currentAccountId;
  String _currentAccountType = 'user';
  final Set<String> _ownProductIds = <String>{};
  final Set<String> _wishlistProductIds = <String>{};
  final Set<String> _wishlistBusyIds = <String>{};

  // INIT

  @override
  void initState() {
    super.initState();
    _loadProducts();

    searchQuery = widget.initialSearch ?? '';

    _searchController.text = searchQuery;

    if (widget.initialCategory != null &&
        categories.contains(widget.initialCategory)) {
      selectedCategory = widget.initialCategory!;
    }
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return <String, dynamic>{};
  }

  List<dynamic> _extractRows(dynamic response, List<String> keys) {
    if (response is List) return response;
    final root = _asMap(response);
    final rawData = root['data'];
    if (rawData is List) return rawData;
    final data = _asMap(rawData);
    for (final key in keys) {
      final value = root[key] ?? data[key];
      if (value is List) return value;
    }
    if (data.isNotEmpty && data.values.first is List) {
      return data.values.first as List<dynamic>;
    }
    return <dynamic>[];
  }

  String _idOf(Map<String, dynamic> row) {
    final nested = _asMap(row['product']);
    final value =
        row['productId'] ??
        row['product_id'] ??
        row['id'] ??
        nested['productId'] ??
        nested['product_id'] ??
        nested['id'];
    return value?.toString().trim() ?? '';
  }

  Future<void> _loadAccountAndWishlist() async {
    // These are separate optional requests so a failure in either one does not
    // prevent the public marketplace from loading.
    try {
      final response = _asMap(await _api.get('/auth/me'));
      final data = _asMap(response['data']);
      final account = _asMap(
        response['account'] ??
            response['user'] ??
            response['artist'] ??
            data['account'] ??
            data['user'] ??
            data['artist'] ??
            data,
      );
      final id =
          account['accountId'] ??
          account['userId'] ??
          account['artistId'] ??
          account['id'];
      final type =
          (account['accountType'] ??
                  account['ownerType'] ??
                  account['role'] ??
                  response['accountType'] ??
                  data['accountType'] ??
                  'user')
              .toString()
              .trim()
              .toLowerCase();
      if (id != null && id.toString().trim().isNotEmpty && mounted) {
        setState(() {
          _currentAccountId = id.toString().trim();
          _currentAccountType =
              <String>{
                'artist',
                'remaker',
                're-maker',
                're_maker',
              }.contains(type)
              ? 'artist'
              : 'user';
        });
      }
    } catch (_) {
      // /my/products below remains the primary owner-filter source.
    }

    try {
      final rows = _extractRows(await _api.get('/my/products'), [
        'products',
        'items',
        'data',
        'results',
      ]);
      final ids = rows
          .map(_asMap)
          .map(_idOf)
          .where((id) => id.isNotEmpty)
          .toSet();
      if (mounted) {
        setState(() {
          _ownProductIds
            ..clear()
            ..addAll(ids);
          // If the public products request finished first, remove owned
          // listings as soon as the account's own-product IDs arrive.
          products.removeWhere(_isOwnProduct);
        });
      }
    } catch (_) {
      // Some deployments may not expose /my/products. We still filter by
      // sellerId and account type below.
    }

    try {
      final rows = _extractRows(await _api.get('/wishlist'), [
        'wishlist',
        'items',
        'products',
        'results',
        'data',
      ]);
      final ids = rows
          .map(_asMap)
          .map(_idOf)
          .where((id) => id.isNotEmpty)
          .toSet();
      if (mounted) {
        setState(() {
          _wishlistProductIds
            ..clear()
            ..addAll(ids);
        });
      }
    } catch (_) {
      // Keep browsing available if wishlist data cannot be loaded.
    }
  }

  bool _isOwnProduct(Map<String, dynamic> product) {
    final id = _idOf(product);
    if (id.isNotEmpty && _ownProductIds.contains(id)) return true;

    final sellerId = (product['sellerId'] ?? product['seller_id'] ?? '')
        .toString()
        .trim();
    if (sellerId.isEmpty || _currentAccountId == null) return false;
    if (sellerId != _currentAccountId) return false;

    final sellerType =
        (product['sellerType'] ??
                product['seller_type'] ??
                product['sellerRole'] ??
                product['seller_role'] ??
                'user')
            .toString()
            .trim()
            .toLowerCase();
    final isArtist = <String>{
      'artist',
      'remaker',
      're-maker',
      're_maker',
    }.contains(sellerType);
    return isArtist == (_currentAccountType == 'artist');
  }

  Future<bool> _toggleWishlist(Map<String, dynamic> product) async {
    final id = _idOf(product);
    if (id.isEmpty || _wishlistBusyIds.contains(id)) return false;

    final wasSaved = _wishlistProductIds.contains(id);
    setState(() => _wishlistBusyIds.add(id));
    try {
      if (wasSaved) {
        await _api.delete('/wishlist/$id');
        if (mounted) setState(() => _wishlistProductIds.remove(id));
      } else {
        final numericId = int.tryParse(id);
        if (numericId == null) {
          throw Exception('This product has an invalid ID.');
        }
        await _api.post('/wishlist', <String, dynamic>{'productId': numericId});
        if (mounted) setState(() => _wishlistProductIds.add(id));
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                wasSaved ? 'Removed from wishlist' : 'Added to wishlist',
              ),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(milliseconds: 900),
            ),
          );
      }
      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                'Wishlist update failed: ${error.toString().replaceFirst('Exception: ', '')}',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
      return false;
    } finally {
      if (mounted) setState(() => _wishlistBusyIds.remove(id));
    }
  }

  Future<void> _loadProducts() async {
    // The public catalogue is the critical request. Identity, own-listings,
    // and wishlist are optional and must never hold the marketplace spinner.
    unawaited(_loadAccountAndWishlist());
    if (mounted) {
      setState(() {
        _loadingProducts = true;
        _productsError = null;
      });
    }
    try {
      final results = await Future.wait<dynamic>([
        _api.get('/products'),
        _api.get('/categories'),
      ]);
      final categoryRows = _extractRows(results[1], [
        'categories',
        'items',
        'data',
      ]);
      final categoryMap = <String, String>{};
      final backendCategoryNames = <String>{};
      for (final raw in categoryRows) {
        final row = _asMap(raw);
        final id = (row['categoryId'] ?? row['category_id'] ?? row['id'] ?? '')
            .toString();
        final name = (row['name'] ?? row['categoryName'] ?? row['title'] ?? '')
            .toString()
            .trim();
        if (id.isNotEmpty && name.isNotEmpty) categoryMap[id] = name;
        if (name.isNotEmpty) backendCategoryNames.add(name);
      }
      final rows = _extractRows(results[0], ['products', 'items', 'data']);
      final mapped = <Map<String, dynamic>>[];
      for (final raw in rows) {
        final row = _asMap(raw);
        final id = row['productId'] ?? row['product_id'] ?? row['id'];
        final status = (row['status'] ?? '').toString().toLowerCase();
        final quantity =
            row['availableQuantity'] ??
            row['available_quantity'] ??
            row['quantity'] ??
            0;
        if (id == null ||
            (status.isNotEmpty &&
                status != 'published' &&
                status != 'active') ||
            (quantity is num && quantity <= 0)) {
          continue;
        }
        final rawImages =
            row['imageUrls'] ?? row['images'] ?? row['image_urls'];
        final images = rawImages is List
            ? rawImages
                  .map((item) => item.toString())
                  .where((item) => item.trim().isNotEmpty)
                  .toList()
            : <String>[];
        final image = (row['image'] ?? (images.isNotEmpty ? images.first : ''))
            .toString();
        final categoryId = (row['categoryId'] ?? row['category_id'] ?? '')
            .toString();
        final sellerType = (row['sellerType'] ?? row['seller_type'] ?? 'user')
            .toString()
            .toLowerCase();
        final sellerName =
            (row['sellerName'] ?? row['seller'] ?? row['artistName'] ?? '')
                .toString();
        final city = (row['sellerCity'] ?? row['city'] ?? '').toString();
        final state = (row['sellerState'] ?? row['state'] ?? '').toString();
        mapped.add(<String, dynamic>{
          ...row,
          'id': id,
          'productId': id,
          'sellerId': row['sellerId'] ?? row['seller_id'],
          'sellerType': sellerType,
          'title': (row['title'] ?? row['productName'] ?? '').toString(),
          'price': row['price'] ?? row['unitPrice'] ?? 0,
          'condition': (row['condition'] ?? '').toString(),
          'category':
              row['category'] ??
              row['categoryName'] ??
              categoryMap[categoryId] ??
              '',
          'seller': sellerName,
          'sellerName': sellerName,
          'location': [
            city,
            state,
          ].where((part) => part.trim().isNotEmpty).join(', '),
          'views': row['views'] ?? 0,
          'wishlistCount': row['wishlistCount'] ?? 0,
          'availableQuantity': quantity,
          'description': row['description'] ?? '',
          'image': image,
          'images': images.isNotEmpty
              ? images
              : (image.isNotEmpty ? <String>[image] : <String>[]),
          'createdAt': row['createdAt'] ?? row['created_at'],
        });
      }
      // Exclude this signed-in account's own listings from marketplace results.
      mapped.removeWhere(_isOwnProduct);

      mapped.sort((a, b) {
        final aDate =
            DateTime.tryParse((a['createdAt'] ?? '').toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bDate =
            DateTime.tryParse((b['createdAt'] ?? '').toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      if (!mounted) return;
      setState(() {
        products = mapped;
        _backendCategories = backendCategoryNames.toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        if (widget.initialCategory != null &&
            _backendCategories.contains(widget.initialCategory)) {
          selectedCategory = widget.initialCategory!;
        }
        for (final product in mapped) {
          final category = (product['category'] ?? '').toString().trim();
          if (category.isNotEmpty && !_backendCategories.contains(category)) {
            _backendCategories.add(category);
          }
        }
        final maximumPrice = mapped.fold<double>(0, (current, product) {
          final raw = product['price'];
          final value = raw is num
              ? raw.toDouble()
              : double.tryParse((raw ?? '').toString()) ?? 0;
          return value > current ? value : current;
        });
        final safeMaximum = maximumPrice > 0 ? maximumPrice : 100;
        priceRange = RangeValues(
          priceRange.start.clamp(0.0, safeMaximum).toDouble(),
          priceRange.end.clamp(0.0, safeMaximum).toDouble(),
        );
        _loadingProducts = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _productsError = error
            .toString()
            .replaceFirst('Exception: ', '')
            .replaceFirst('DioException [bad response]: ', '');
        _loadingProducts = false;
      });
    }
  }

  // DISPOSE

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // FILTERED PRODUCTS

  List<Map<String, dynamic>> get filteredProducts {
    List<Map<String, dynamic>> result = List<Map<String, dynamic>>.from(
      products,
    );

    // CATEGORY

    if (selectedCategory != 'All') {
      result = result
          .where((product) => product['category'] == selectedCategory)
          .toList();
    }

    // SEARCH

    if (searchQuery.trim().isNotEmpty) {
      final query = searchQuery.toLowerCase().trim();

      result = result.where((product) {
        final title = product['title'].toString().toLowerCase();
        final category = product['category'].toString().toLowerCase();
        final seller = product['seller'].toString().toLowerCase();
        final description = product['description'].toString().toLowerCase();
        final location = product['location'].toString().toLowerCase();

        return title.contains(query) ||
            category.contains(query) ||
            seller.contains(query) ||
            description.contains(query) ||
            location.contains(query);
      }).toList();
    }

    // CONDITION

    if (selectedCondition != 'All') {
      result = result
          .where((product) => product['condition'] == selectedCondition)
          .toList();
    }

    // PRICE

    result = result.where((product) {
      final rawPrice = product['price'];
      final price = rawPrice is num
          ? rawPrice.toDouble()
          : double.tryParse((rawPrice ?? '').toString()) ?? 0;
      return price >= priceRange.start && price <= priceRange.end;
    }).toList();

    // SORT

    if (selectedSort == 'Price: Low to High') {
      result.sort((a, b) => (a['price'] as num).compareTo(b['price'] as num));
    } else if (selectedSort == 'Price: High to Low') {
      result.sort((a, b) => (b['price'] as num).compareTo(a['price'] as num));
    } else if (selectedSort == 'Popular') {
      result.sort((a, b) => (b['views'] as num).compareTo(a['views'] as num));
    }

    return result;
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildCategories(),
            _buildFilterRow(),
            Expanded(child: _buildProductGrid()),
          ],
        ),
      ),
    );
  }

  // HEADER

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Marketplace',
                style: AppTextStyles.heading.copyWith(fontSize: 23),
              ),
              const SizedBox(height: 2),
              Text(
                'Give useful things another life',
                style: AppTextStyles.caption,
              ),
            ],
          ),

          const Spacer(),

          // WISHLIST SHORTCUT
          IconButton(
            tooltip: 'Wishlist',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const Wishlist()),
              );
            },
            icon: const Icon(
              Icons.favorite_border_rounded,
              color: AppColors.primary,
            ),
          ),

          // MORE MENU
          const UserMoreMenu(),
        ],
      ),
    );
  }

  // SEARCH BAR

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.55)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              searchQuery = value;
            });
          },
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search furniture, decor, materials...',
            hintStyle: AppTextStyles.hint,

            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.primary,
            ),

            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();

                      setState(() {
                        searchQuery = '';
                      });
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 19,
                      color: AppColors.textSecondary,
                    ),
                  )
                : IconButton(
                    onPressed: _showFilterSheet,
                    icon: const Icon(
                      Icons.tune_rounded,
                      color: AppColors.primary,
                    ),
                  ),

            border: InputBorder.none,

            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  // CATEGORIES

  Widget _buildCategories() {
    return SizedBox(
      height: 57,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = selectedCategory == category;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedCategory = category;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selected
                      ? AppColors.primary
                      : AppColors.accent.withValues(alpha: 0.7),
                ),
              ),
              child: Text(
                category,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // FILTER ROW

  Widget _buildFilterRow() {
    final count = filteredProducts.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          Text(
            '$count ${count == 1 ? 'product' : 'products'}',
            style: AppTextStyles.caption,
          ),

          const Spacer(),

          // ACTIVE CATEGORY
          if (selectedCategory != 'All')
            _activeFilterChip(selectedCategory, () {
              setState(() {
                selectedCategory = 'All';
              });
            }),

          if (selectedCategory != 'All') const SizedBox(width: 6),

          // ACTIVE CONDITION
          if (selectedCondition != 'All')
            _activeFilterChip(selectedCondition, () {
              setState(() {
                selectedCondition = 'All';
              });
            }),

          if (selectedCondition != 'All') const SizedBox(width: 6),

          // FILTER
          _smallActionButton(
            icon: Icons.tune_rounded,
            text: 'Filter',
            onTap: _showFilterSheet,
          ),

          const SizedBox(width: 7),

          // SORT
          _smallActionButton(
            icon: Icons.swap_vert_rounded,
            text: 'Sort',
            onTap: _showSortSheet,
          ),
        ],
      ),
    );
  }

  // ACTIVE FILTER CHIP

  Widget _activeFilterChip(String text, VoidCallback onRemove) {
    return GestureDetector(
      onTap: onRemove,
      child: Container(
        height: 32,
        padding: const EdgeInsets.only(left: 9, right: 6),
        decoration: BoxDecoration(
          color: AppColors.light,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.close_rounded, size: 14, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  // SMALL ACTION BUTTON

  Widget _smallActionButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.55)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              text,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // PRODUCT GRID

  Widget _buildProductGrid() {
    final items = filteredProducts;

    if (_loadingProducts) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_productsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 42,
                color: AppColors.primary,
              ),
              const SizedBox(height: 12),
              const Text('Could not load marketplace products.'),
              const SizedBox(height: 8),
              Text(
                _productsError!,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _loadProducts,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (items.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
        childAspectRatio: 0.64,
      ),
      itemBuilder: (context, index) {
        final product = items[index];
        final productId = _idOf(product);
        return _ProductCard(
          key: ValueKey('marketplace-product-$productId'),
          product: product,
          isWishlisted: _wishlistProductIds.contains(productId),
          wishlistBusy: _wishlistBusyIds.contains(productId),
          onWishlistTap: () => _toggleWishlist(product),
          onTap: () {
            _openProductDetails(product);
          },
          onSellerTap: (product) {
            _openSellerProfile(product);
          },
        );
      },
    );
  }

  // SELLER / ARTIST PROFILE NAVIGATION

  String _sellerType(Map<String, dynamic> product) {
    final value =
        product['sellerType'] ??
        product['seller_type'] ??
        product['sellerRole'] ??
        product['seller_role'] ??
        product['role'] ??
        'user';

    return value.toString().trim().toLowerCase();
  }

  bool _isArtistSeller(Map<String, dynamic> product) {
    final type = _sellerType(product);

    return type == 'artist' ||
        type == 'remaker' ||
        type == 're_maker' ||
        type == 're-maker';
  }

  Map<String, dynamic> _profileDataForSeller(Map<String, dynamic> product) {
    final artist = _isArtistSeller(product);

    return {
      ...product,
      'id': product['sellerId'] ?? product['id'],
      'sellerId': product['sellerId'] ?? product['id'],
      if (artist)
        'artistId': product['sellerId'] ?? product['artistId'] ?? product['id'],
      if (!artist)
        'userId': product['sellerId'] ?? product['userId'] ?? product['id'],
      'name': product['seller'] ?? '',
      'artistName': product['seller'],
      'username': product['username'],
      'location': product['location'] ?? '',
      'sellerType': artist ? 'artist' : 'user',
      'role': artist ? 'artist' : 'user',
    };
  }

  void _openSellerProfile(Map<String, dynamic> product) {
    final profileData = _profileDataForSeller(product);

    if (_isArtistSeller(product)) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ArtistProfile(artist: profileData)),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SellerProfile(seller: profileData)),
    );
  }

  // PRODUCT DETAILS

  Future<void> _openProductDetails(Map<String, dynamic> product) async {
    if (_isOwnProduct(product)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot purchase your own listing.')),
      );
      return;
    }
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetails(
          product: product,
          returnToCheckoutOnSelect: widget.returnToCheckoutOnSelect,
        ),
      ),
    );
    if (!mounted || !widget.returnToCheckoutOnSelect || result == null) return;
    Navigator.pop(context, result);
  }

  // EMPTY STATE

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.light,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 36,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 17),

            Text('No products found', style: AppTextStyles.title),

            const SizedBox(height: 6),

            Text(
              'Try another search, category or filter.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),

            const SizedBox(height: 16),

            OutlinedButton(
              onPressed: _resetFilters,
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      ),
    );
  }

  // FILTER SHEET

  void _showFilterSheet() {
    RangeValues temporaryPrice = priceRange;

    String temporaryCondition = selectedCondition;
    String temporaryCategory = selectedCategory;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 25),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // HANDLE
                      Center(
                        child: Container(
                          height: 4,
                          width: 42,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // TITLE
                      Row(
                        children: [
                          Text('Filter Products', style: AppTextStyles.title),

                          const Spacer(),

                          TextButton(
                            onPressed: () {
                              setSheetState(() {
                                temporaryCategory = 'All';
                                temporaryCondition = 'All';
                                temporaryPrice = RangeValues(
                                  0,
                                  _maximumProductPrice,
                                );
                              });
                            },
                            child: const Text('Reset'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // CATEGORY
                      const Text(
                        'Category',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: categories.map((category) {
                          final selected = temporaryCategory == category;

                          return ChoiceChip(
                            label: Text(category),
                            selected: selected,
                            onSelected: (_) {
                              setSheetState(() {
                                temporaryCategory = category;
                              });
                            },
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              fontSize: 10,
                              color: selected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 22),

                      // CONDITION
                      const Text(
                        'Condition',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: conditions.map((condition) {
                          final selected = temporaryCondition == condition;

                          return ChoiceChip(
                            label: Text(condition),
                            selected: selected,
                            onSelected: (_) {
                              setSheetState(() {
                                temporaryCondition = condition;
                              });
                            },
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              fontSize: 10,
                              color: selected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 22),

                      // PRICE
                      const Text(
                        'Price Range',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Row(
                        children: [
                          Text(
                            '₹${temporaryPrice.start.round()}',
                            style: AppTextStyles.caption,
                          ),

                          const Spacer(),

                          Text(
                            '₹${temporaryPrice.end.round()}',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),

                      RangeSlider(
                        values: temporaryPrice,
                        min: 0,
                        max: 10000,
                        divisions: 20,
                        activeColor: AppColors.primary,
                        onChanged: (values) {
                          setSheetState(() {
                            temporaryPrice = values;
                          });
                        },
                      ),

                      const SizedBox(height: 15),

                      // APPLY
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedCategory = temporaryCategory;

                              selectedCondition = temporaryCondition;

                              priceRange = temporaryPrice;
                            });

                            Navigator.pop(sheetContext);
                          },
                          child: const Text('Apply Filters'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // SORT SHEET

  void _showSortSheet() {
    final options = [
      'Newest First',
      'Price: Low to High',
      'Price: High to Low',
      'Popular',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HANDLE
                Center(
                  child: Container(
                    height: 4,
                    width: 42,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Text('Sort Products', style: AppTextStyles.title),

                const SizedBox(height: 10),

                ...options.map((option) {
                  final selected = selectedSort == option;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,

                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.light,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _sortIcon(option),
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),

                    title: Text(
                      option,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),

                    trailing: selected
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                          )
                        : const Icon(
                            Icons.radio_button_unchecked,
                            color: AppColors.textSecondary,
                          ),

                    onTap: () {
                      setState(() {
                        selectedSort = option;
                      });

                      Navigator.pop(sheetContext);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // SORT ICON

  IconData _sortIcon(String option) {
    switch (option) {
      case 'Price: Low to High':
        return Icons.arrow_upward_rounded;

      case 'Price: High to Low':
        return Icons.arrow_downward_rounded;

      case 'Popular':
        return Icons.trending_up_rounded;

      default:
        return Icons.access_time_rounded;
    }
  }

  // RESET FILTERS

  void _resetFilters() {
    _searchController.clear();

    setState(() {
      searchQuery = '';
      selectedCategory = 'All';
      selectedCondition = 'All';
      selectedSort = 'Newest First';
      priceRange = RangeValues(0.0, _maximumProductPrice);
    });
  }
}

// PRODUCT CARD

class _ProductCard extends StatefulWidget {
  const _ProductCard({
    super.key,
    required this.product,
    required this.isWishlisted,
    required this.wishlistBusy,
    required this.onWishlistTap,
    required this.onTap,
    required this.onSellerTap,
  });

  final Map<String, dynamic> product;
  final bool isWishlisted;
  final bool wishlistBusy;
  final Future<bool> Function() onWishlistTap;
  final VoidCallback onTap;
  final ValueChanged<Map<String, dynamic>> onSellerTap;

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  late bool isWishlisted;
  bool _wishlistTapBusy = false;

  @override
  void initState() {
    super.initState();
    isWishlisted = widget.isWishlisted;
  }

  @override
  void didUpdateWidget(covariant _ProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isWishlisted != widget.isWishlisted) {
      isWishlisted = widget.isWishlisted;
    }
  }

  Future<void> _toggleWishlist() async {
    if (_wishlistTapBusy || widget.wishlistBusy) return;
    setState(() => _wishlistTapBusy = true);
    final previous = isWishlisted;
    setState(() => isWishlisted = !previous);
    final success = await widget.onWishlistTap();
    if (mounted) {
      setState(() {
        if (!success) isWishlisted = previous;
        _wishlistTapBusy = false;
      });
    }
  }

  String _sellerType(Map<String, dynamic> product) {
    final value =
        product['sellerType'] ??
        product['seller_type'] ??
        product['sellerRole'] ??
        product['seller_role'] ??
        product['role'] ??
        'user';

    return value.toString().trim().toLowerCase();
  }

  bool _isArtistSeller(Map<String, dynamic> product) {
    final type = _sellerType(product);

    return type == 'artist' ||
        type == 'remaker' ||
        type == 're_maker' ||
        type == 're-maker';
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    final rawPrice = product['price'];
    final int price = rawPrice is num
        ? rawPrice.round()
        : (double.tryParse((rawPrice ?? '').toString()) ?? 0).round();

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.42)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 9,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: (product['image'] ?? '').toString().trim().isEmpty
                        ? Container(
                            color: AppColors.light,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.image_outlined,
                              size: 40,
                              color: AppColors.secondary,
                            ),
                          )
                        : Image.network(
                            product['image'].toString(),
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) {
                                return child;
                              }

                              return Container(
                                color: AppColors.light,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppColors.light,
                                child: const Center(
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 40,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  // CONDITION
                  Positioned(
                    left: 9,
                    top: 9,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        (product['condition'] ?? '').toString().isEmpty
                            ? 'Condition unavailable'
                            : product['condition'].toString(),
                        style: const TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),

                  // WISHLIST
                  Positioned(
                    right: 9,
                    top: 9,
                    child: GestureDetector(
                      onTap: _toggleWishlist,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.94),
                          shape: BoxShape.circle,
                        ),
                        child: (widget.wishlistBusy || _wishlistTapBusy)
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              )
                            : Icon(
                                isWishlisted
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 18,
                                color: isWishlisted
                                    ? AppColors.error
                                    : AppColors.textPrimary,
                              ),
                      ),
                    ),
                  ),

                  // CATEGORY
                  Positioned(
                    left: 9,
                    bottom: 9,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        (product['category'] ?? '').toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // PRODUCT INFO
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TITLE
                  Text(
                    (product['title'] ?? '').toString().isEmpty
                        ? 'Untitled product'
                        : product['title'].toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // PRICE
                  Text(
                    '₹${price.toStringAsFixed(0)}',
                    style: AppTextStyles.title.copyWith(fontSize: 17),
                  ),

                  const SizedBox(height: 5),

                  // SELLER / ARTIST
                  InkWell(
                    onTap: () => widget.onSellerTap(product),
                    borderRadius: BorderRadius.circular(7),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Icon(
                            _isArtistSeller(product)
                                ? Icons.brush_outlined
                                : Icons.person_outline_rounded,
                            size: 12,
                            color: AppColors.primary,
                          ),

                          const SizedBox(width: 3),

                          Expanded(
                            child: Text(
                              (product['seller'] ?? '').toString().isEmpty
                                  ? 'Seller details unavailable'
                                  : product['seller'].toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 9.5,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 9,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // LOCATION
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 11,
                        color: AppColors.textSecondary,
                      ),

                      const SizedBox(width: 3),

                      Expanded(
                        child: Text(
                          (product['location'] ?? '').toString().isEmpty
                              ? 'Location unavailable'
                              : product['location'].toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(fontSize: 8.5),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // VIEW PRODUCT
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: OutlinedButton(
                      onPressed: widget.onTap,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: const Text(
                        'View Product',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
