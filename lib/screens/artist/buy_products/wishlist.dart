import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import '../../../services/ecoloop_api.dart';
import '../buy_products/product_details.dart';

class Wishlist extends StatefulWidget {
  const Wishlist({super.key});

  @override
  State<Wishlist> createState() => _WishlistState();
}

class _WishlistState extends State<Wishlist> {
  final TextEditingController _searchController = TextEditingController();

  String searchQuery = '';

  // Wishlist items are loaded from the authenticated backend.
  final List<Map<String, dynamic>> _wishlistItems = [];
  bool _isLoading = true;
  bool _hasLoadError = false;
  String _loadError = '';
  final Set<int> _removingProductIds = <int>{};

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  int _toInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  double _toDouble(dynamic value, [double fallback = 0]) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  String _text(dynamic value, [String fallback = '']) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty || text.toLowerCase() == 'null' ? fallback : text;
  }

  Future<void> _loadWishlist() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasLoadError = false;
        _loadError = '';
      });
    }
    try {
      final results = await Future.wait<dynamic>([
        EcoLoopApi.instance.get('/wishlist'),
        EcoLoopApi.instance.get('/categories'),
      ]);
      final rawWishlist = results[0];
      final rawCategories = results[1];
      final categories = <int, String>{};
      if (rawCategories is List) {
        for (final item in rawCategories) {
          if (item is Map) {
            categories[_toInt(item['categoryId'] ?? item['id'])] = _text(
              item['name'] ?? item['categoryName'],
              'Other',
            );
          }
        }
      }
      final loaded = <Map<String, dynamic>>[];
      if (rawWishlist is List) {
        for (final entry in rawWishlist) {
          if (entry is! Map) continue;
          final product = Map<String, dynamic>.from(entry);
          final id = _toInt(product['productId'] ?? product['id']);
          if (id <= 0) continue;
          final imageValues = product['imageUrls'] ?? product['images'];
          final images = <String>[];
          if (imageValues is List) {
            for (final value in imageValues) {
              final url = _text(value);
              if (url.startsWith('http')) images.add(url);
            }
          } else {
            final single = _text(product['imageUrl'] ?? product['image']);
            if (single.startsWith('http')) images.add(single);
          }
          final city = _text(product['sellerCity'] ?? product['city']);
          final state = _text(product['sellerState'] ?? product['state']);
          final location = [
            city,
            state,
          ].where((part) => part.isNotEmpty).toSet().join(', ');
          final categoryId = _toInt(product['categoryId']);
          product['productId'] = id;
          product['price'] = _toDouble(product['price']);
          product['quantity'] = _toInt(product['quantity']);
          product['availableQuantity'] = _toInt(product['availableQuantity']);
          product['views'] = _toInt(product['views']);
          product['wishlistCount'] = _toInt(product['wishlistCount']);
          product['title'] = _text(product['title'], 'Untitled product');
          product['description'] = _text(product['description']);
          product['condition'] = _text(product['condition'], 'Not specified');
          product['seller'] = _text(
            product['sellerName'] ?? product['seller'],
            'EcoLoop seller',
          );
          product['category'] = _text(
            product['categoryName'],
            categories[categoryId] ?? 'Other',
          );
          product['location'] = location.isEmpty
              ? 'Location not provided'
              : location;
          product['images'] = images;
          product['image'] = images.isNotEmpty ? images.first : '';
          loaded.add(product);
        }
      } else {
        throw const EcoLoopApiException('Wishlist response was not a list.');
      }
      if (!mounted) return;
      setState(() {
        _wishlistItems
          ..clear()
          ..addAll(loaded);
        _isLoading = false;
        _hasLoadError = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasLoadError = true;
        _loadError = error is EcoLoopApiException
            ? error.message
            : 'Could not load your wishlist. Please check your connection and try again.';
      });
    }
  }

  // FILTERED ITEMS

  List<Map<String, dynamic>> get _filteredItems {
    if (searchQuery.trim().isEmpty) {
      return _wishlistItems;
    }

    final query = searchQuery.toLowerCase().trim();

    return _wishlistItems.where((product) {
      final title = product['title'].toString().toLowerCase();

      final category = product['category'].toString().toLowerCase();

      final seller = product['seller'].toString().toLowerCase();

      final condition = product['condition'].toString().toLowerCase();

      return title.contains(query) ||
          category.contains(query) ||
          seller.contains(query) ||
          condition.contains(query);
    }).toList();
  }

  // DISPOSE

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtistColors.background,

      // APP BAR
      appBar: AppBar(
        backgroundColor: ArtistColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: ArtistColors.textPrimary,

        title: Text(
          'Wishlist',
          style: ArtistTextStyles.title.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),

        actions: [
          if (_wishlistItems.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              color: ArtistColors.surface,
              onSelected: (value) {
                if (value == 'clear') {
                  _confirmClearWishlist();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'clear',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.delete_sweep_outlined,
                        color: ArtistColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text('Clear Wishlist', style: ArtistTextStyles.body),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),

      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: ArtistColors.primary),
            )
          : _hasLoadError
          ? _buildLoadError()
          : _wishlistItems.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                _buildHeader(),

                _buildSearch(),

                _buildResultInfo(),

                Expanded(
                  child: _filteredItems.isEmpty
                      ? _buildNoSearchResult()
                      : _buildGrid(),
                ),
              ],
            ),
    );
  }

  // HEADER

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saved Products',
                  style: ArtistTextStyles.title.copyWith(fontSize: 17),
                ),

                const SizedBox(height: 3),

                Text(
                  'Keep products you love in one place.',
                  style: ArtistTextStyles.caption,
                ),
              ],
            ),
          ),

          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ArtistColors.light,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.favorite_rounded,
              size: 22,
              color: ArtistColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // SEARCH

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: ArtistColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ArtistColors.border),
        ),
        child: TextField(
          controller: _searchController,

          onChanged: (value) {
            setState(() {
              searchQuery = value;
            });
          },

          style: ArtistTextStyles.body.copyWith(fontSize: 13),

          decoration: InputDecoration(
            hintText: 'Search saved products...',
            hintStyle: ArtistTextStyles.caption.copyWith(
              color: ArtistColors.textMuted,
            ),

            prefixIcon: const Icon(
              Icons.search_rounded,
              color: ArtistColors.primary,
            ),

            suffixIcon: searchQuery.isNotEmpty
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
                      color: ArtistColors.textSecondary,
                    ),
                  )
                : null,

            border: InputBorder.none,

            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  // RESULT INFO

  Widget _buildResultInfo() {
    final count = _filteredItems.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: [
          Text(
            '$count ${count == 1 ? 'saved product' : 'saved products'}',
            style: ArtistTextStyles.caption,
          ),

          const Spacer(),

          if (searchQuery.isNotEmpty)
            Text(
              'Search results',
              style: ArtistTextStyles.caption.copyWith(
                color: ArtistColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  // GRID

  Widget _buildGrid() {
    final items = _filteredItems;

    return RefreshIndicator(
      onRefresh: _loadWishlist,
      color: ArtistColors.primary,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),

        padding: const EdgeInsets.fromLTRB(20, 5, 20, 30),

        itemCount: items.length,

        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 14,
          childAspectRatio: 0.61,
        ),

        itemBuilder: (context, index) {
          final product = items[index];

          return _WishlistProductCard(
            product: product,

            onTap: () {
              _openProductDetails(product);
            },

            onRemove: () {
              _removeProduct(product);
            },
          );
        },
      ),
    );
  }

  // OPEN PRODUCT DETAILS

  void _openProductDetails(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetails(product: product)),
    );
  }

  // Remove from the server first; only update the UI after success.
  Future<void> _removeProduct(Map<String, dynamic> product) async {
    final id = _toInt(product['productId']);
    if (id <= 0 || _removingProductIds.contains(id)) return;
    setState(() => _removingProductIds.add(id));
    try {
      await EcoLoopApi.instance.delete('/wishlist/$id');
      if (!mounted) return;
      setState(() {
        _wishlistItems.removeWhere((item) => _toInt(item['productId']) == id);
        _removingProductIds.remove(id);
      });
      _showMessage(
        '${_text(product['title'], 'Product')} removed from wishlist.',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _removingProductIds.remove(id));
      _showMessage(
        error is EcoLoopApiException
            ? error.message
            : 'Could not remove this product. Please try again.',
      );
    }
  }

  // CLEAR WISHLIST

  void _confirmClearWishlist() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: ArtistColors.surface,
          surfaceTintColor: Colors.transparent,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),

          icon: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: ArtistColors.light,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              color: ArtistColors.error,
              size: 27,
            ),
          ),

          title: Text(
            'Clear Wishlist?',
            textAlign: TextAlign.center,
            style: ArtistTextStyles.title.copyWith(fontSize: 19),
          ),

          content: Text(
            'All your saved products will be removed from the wishlist.',
            textAlign: TextAlign.center,
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
              onPressed: () {
                Navigator.pop(dialogContext);

                _clearWishlist();
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: ArtistColors.error,
                foregroundColor: Colors.white,
                elevation: 0,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),

              child: const Text(
                'Clear',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearWishlist() async {
    final ids = _wishlistItems
        .map((item) => _toInt(item['productId']))
        .where((id) => id > 0)
        .toList();
    try {
      for (final id in ids) {
        await EcoLoopApi.instance.delete('/wishlist/$id');
      }
      if (!mounted) return;
      setState(() => _wishlistItems.clear());
      _showMessage('Wishlist cleared.');
    } catch (error) {
      if (!mounted) return;
      await _loadWishlist();
      if (mounted) {
        _showMessage(
          error is EcoLoopApiException
              ? error.message
              : 'Some products could not be removed. Wishlist refreshed.',
        );
      }
    }
  }

  Widget _buildLoadError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: ArtistColors.textSecondary,
            ),
            const SizedBox(height: 14),
            Text(
              'Could not load wishlist',
              style: ArtistTextStyles.title.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              _loadError,
              textAlign: TextAlign.center,
              style: ArtistTextStyles.body,
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _loadWishlist,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ArtistColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // NO SEARCH RESULT

  Widget _buildNoSearchResult() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(35),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: ArtistColors.light,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 37,
                color: ArtistColors.primary,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              'No saved products found',
              style: ArtistTextStyles.title.copyWith(fontSize: 18),
            ),

            const SizedBox(height: 7),

            Text(
              'Try searching with another product name, '
              'category, seller or condition.',
              textAlign: TextAlign.center,
              style: ArtistTextStyles.body,
            ),

            const SizedBox(height: 18),

            OutlinedButton.icon(
              onPressed: () {
                _searchController.clear();

                setState(() {
                  searchQuery = '';
                });
              },

              icon: const Icon(Icons.refresh_rounded, size: 18),

              label: const Text('Clear Search'),

              style: OutlinedButton.styleFrom(
                foregroundColor: ArtistColors.primary,
                side: const BorderSide(color: ArtistColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // EMPTY WISHLIST

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(35),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 105,
              height: 105,
              decoration: BoxDecoration(
                color: ArtistColors.light,
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 50,
                color: ArtistColors.primary,
              ),
            ),

            const SizedBox(height: 23),

            Text(
              'Your wishlist is empty',
              textAlign: TextAlign.center,
              style: ArtistTextStyles.title.copyWith(fontSize: 20),
            ),

            const SizedBox(height: 9),

            Text(
              'Save products you like while exploring '
              'the marketplace. You can come back and '
              'view them anytime.',
              textAlign: TextAlign.center,
              style: ArtistTextStyles.body,
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: 220,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },

                icon: const Icon(Icons.storefront_outlined, size: 18),

                label: const Text('Explore Marketplace'),

                style: ElevatedButton.styleFrom(
                  backgroundColor: ArtistColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,

                  padding: const EdgeInsets.symmetric(vertical: 12),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // MESSAGE

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: ArtistColors.accent,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
      );
  }
}

// WISHLIST PRODUCT CARD

class _WishlistProductCard extends StatelessWidget {
  const _WishlistProductCard({
    required this.product,
    required this.onTap,
    required this.onRemove,
  });

  final Map<String, dynamic> product;

  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final int price = product['price'] is num
        ? (product['price'] as num).round()
        : int.tryParse(product['price']?.toString() ?? '') ?? 0;

    final String image = product['image']?.toString() ?? '';

    return GestureDetector(
      onTap: onTap,

      child: Container(
        decoration: BoxDecoration(
          color: ArtistColors.surface,

          borderRadius: BorderRadius.circular(17),

          border: Border.all(color: ArtistColors.border),

          boxShadow: [
            BoxShadow(
              color: ArtistColors.primary.withOpacity(0.045),
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
                    child: Image.network(
                      image,
                      fit: BoxFit.cover,

                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        }

                        return Container(
                          color: ArtistColors.light,
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ArtistColors.primary,
                            ),
                          ),
                        );
                      },

                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: ArtistColors.light,
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 40,
                              color: ArtistColors.secondary,
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
                        color: Colors.white.withOpacity(0.94),
                        borderRadius: BorderRadius.circular(7),
                      ),

                      child: Text(
                        product['condition']?.toString() ?? 'Used',

                        style: const TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: ArtistColors.primary,
                        ),
                      ),
                    ),
                  ),

                  // REMOVE
                  Positioned(
                    right: 9,
                    top: 9,
                    child: Material(
                      color: Colors.white.withOpacity(0.94),
                      shape: const CircleBorder(),

                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onRemove,

                        child: const Padding(
                          padding: EdgeInsets.all(8),

                          child: Icon(
                            Icons.favorite_rounded,
                            size: 18,
                            color: ArtistColors.error,
                          ),
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
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(6),
                      ),

                      child: Text(
                        product['category']?.toString() ?? 'Product',

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

            // DETAILS
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['title']?.toString() ?? 'Untitled Product',

                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,

                    style: ArtistTextStyles.body.copyWith(
                      color: ArtistColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    '₹$price',

                    style: ArtistTextStyles.title.copyWith(
                      fontSize: 17,
                      color: ArtistColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 5),

                  // SELLER
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        size: 12,
                        color: ArtistColors.textSecondary,
                      ),

                      const SizedBox(width: 3),

                      Expanded(
                        child: Text(
                          product['seller']?.toString() ?? 'Artist',

                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,

                          style: ArtistTextStyles.caption.copyWith(
                            fontSize: 9.5,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // LOCATION
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 11,
                        color: ArtistColors.textSecondary,
                      ),

                      const SizedBox(width: 3),

                      Expanded(
                        child: Text(
                          product['location']?.toString() ?? 'Gujarat',

                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,

                          style: ArtistTextStyles.caption.copyWith(
                            fontSize: 8.5,
                          ),
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
                      onPressed: onTap,

                      style: OutlinedButton.styleFrom(
                        foregroundColor: ArtistColors.primary,

                        side: const BorderSide(color: ArtistColors.primary),

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
