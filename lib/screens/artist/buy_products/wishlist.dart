import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import '../buy_products/product_details.dart';

class Wishlist extends StatefulWidget {
  const Wishlist({super.key});

  @override
  State<Wishlist> createState() => _WishlistState();
}

class _WishlistState extends State<Wishlist> {
  final TextEditingController _searchController = TextEditingController();

  String searchQuery = '';

  // ==========================================================
  // DEMO WISHLIST PRODUCTS
  // ==========================================================

  final List<Map<String, dynamic>> _wishlistItems = [
    {
      'productId': 'W001',
      'title': 'Reclaimed Wood Study Table',
      'price': 2500,
      'condition': 'Good',
      'seller': 'Green Crafts Studio',
      'category': 'Furniture',
      'location': 'Ahmedabad, Gujarat',
      'views': 184,
      'wishlistCount': 26,
      'availableQuantity': 2,
      'status': 'active',
      'description':
          'Beautiful reclaimed wooden study table created from reusable materials. '
          'Perfect for studios, workspaces and creative corners.',
      'image':
          'https://images.unsplash.com/photo-1518455027359-f3f8164ba6b0'
          '?auto=format&fit=crop&w=900&q=85',
      'images': [
        'https://images.unsplash.com/photo-1518455027359-f3f8164ba6b0'
            '?auto=format&fit=crop&w=1200&q=85',
      ],
    },
    {
      'productId': 'W002',
      'title': 'Upcycled Glass Vase',
      'price': 850,
      'condition': 'Like New',
      'seller': 'ReCraft Studio',
      'category': 'Home & Decor',
      'location': 'Vadodara, Gujarat',
      'views': 126,
      'wishlistCount': 18,
      'availableQuantity': 4,
      'status': 'active',
      'description':
          'Decorative vase made using recycled glass materials. '
          'A simple sustainable addition to a creative studio or home.',
      'image':
          'https://images.unsplash.com/photo-1612196808214-b8e1d6145a8c'
          '?auto=format&fit=crop&w=900&q=85',
      'images': [
        'https://images.unsplash.com/photo-1612196808214-b8e1d6145a8c'
            '?auto=format&fit=crop&w=1200&q=85',
      ],
    },
    {
      'productId': 'W003',
      'title': 'Recycled Fabric Tote Bag',
      'price': 550,
      'condition': 'New',
      'seller': 'Eco Handmade',
      'category': 'Fashion',
      'location': 'Surat, Gujarat',
      'views': 221,
      'wishlistCount': 31,
      'availableQuantity': 8,
      'status': 'active',
      'description':
          'Eco-friendly tote bag created using recycled fabric. '
          'Lightweight, reusable and suitable for everyday use.',
      'image':
          'https://images.unsplash.com/photo-1590874103328-eac38a683ce7'
          '?auto=format&fit=crop&w=900&q=85',
      'images': [
        'https://images.unsplash.com/photo-1590874103328-eac38a683ce7'
            '?auto=format&fit=crop&w=1200&q=85',
      ],
    },
    {
      'productId': 'W004',
      'title': 'Reclaimed Wood Wall Decor',
      'price': 1200,
      'condition': 'Upcycled',
      'seller': 'ArtCycle Studio',
      'category': 'Decor',
      'location': 'Ahmedabad, Gujarat',
      'views': 96,
      'wishlistCount': 15,
      'availableQuantity': 3,
      'status': 'active',
      'description':
          'Handmade wall decoration created from reclaimed wooden pieces. '
          'Designed for sustainable and creative interiors.',
      'image':
          'https://images.unsplash.com/photo-1549490349-8643362247b5'
          '?auto=format&fit=crop&w=900&q=85',
      'images': [
        'https://images.unsplash.com/photo-1549490349-8643362247b5'
            '?auto=format&fit=crop&w=1200&q=85',
      ],
    },
    {
      'productId': 'W005',
      'title': 'Handmade Recycled Lamp',
      'price': 1450,
      'condition': 'Like New',
      'seller': 'Creative Earth',
      'category': 'Lighting',
      'location': 'Rajkot, Gujarat',
      'views': 143,
      'wishlistCount': 23,
      'availableQuantity': 5,
      'status': 'active',
      'description':
          'Unique decorative lamp made from reused and recycled materials. '
          'Ideal for sustainable interiors and creative workspaces.',
      'image':
          'https://images.unsplash.com/photo-1507473885765-e6ed057f782c'
          '?auto=format&fit=crop&w=900&q=85',
      'images': [
        'https://images.unsplash.com/photo-1507473885765-e6ed057f782c'
            '?auto=format&fit=crop&w=1200&q=85',
      ],
    },
    {
      'productId': 'W006',
      'title': 'Recycled Storage Basket',
      'price': 450,
      'condition': 'Good',
      'seller': 'Green Makers',
      'category': 'Storage',
      'location': 'Gandhinagar, Gujarat',
      'views': 78,
      'wishlistCount': 11,
      'availableQuantity': 6,
      'status': 'active',
      'description':
          'Reusable storage basket made from recycled materials. '
          'Useful for organizing supplies, materials and everyday items.',
      'image':
          'https://images.unsplash.com/photo-1586023492125-27b2c045efd7'
          '?auto=format&fit=crop&w=900&q=85',
      'images': [
        'https://images.unsplash.com/photo-1586023492125-27b2c045efd7'
            '?auto=format&fit=crop&w=1200&q=85',
      ],
    },
  ];

  // ==========================================================
  // FILTERED ITEMS
  // ==========================================================

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

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

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

      body: _wishlistItems.isEmpty
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

  // ==========================================================
  // HEADER
  // ==========================================================

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

  // ==========================================================
  // SEARCH
  // ==========================================================

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

  // ==========================================================
  // RESULT INFO
  // ==========================================================

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

  // ==========================================================
  // GRID
  // ==========================================================

  Widget _buildGrid() {
    final items = _filteredItems;

    return GridView.builder(
      physics: const BouncingScrollPhysics(),

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
    );
  }

  // ==========================================================
  // OPEN PRODUCT DETAILS
  // ==========================================================

  void _openProductDetails(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetails(product: product)),
    );
  }

  // ==========================================================
  // REMOVE PRODUCT
  // ==========================================================

  void _removeProduct(Map<String, dynamic> product) {
    final originalIndex = _wishlistItems.indexOf(product);

    if (originalIndex == -1) return;

    setState(() {
      _wishlistItems.remove(product);
    });

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '${product['title']} removed from wishlist.',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),

          behavior: SnackBarBehavior.floating,

          backgroundColor: ArtistColors.accent,

          margin: const EdgeInsets.all(16),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),

          action: SnackBarAction(
            label: 'UNDO',
            textColor: Colors.white,
            onPressed: () {
              setState(() {
                final index = originalIndex <= _wishlistItems.length
                    ? originalIndex
                    : _wishlistItems.length;

                _wishlistItems.insert(index, product);
              });
            },
          ),
        ),
      );
  }

  // ==========================================================
  // CLEAR WISHLIST
  // ==========================================================

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

                setState(() {
                  _wishlistItems.clear();
                });

                _showMessage('Wishlist cleared.');
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

  // ==========================================================
  // NO SEARCH RESULT
  // ==========================================================

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

  // ==========================================================
  // EMPTY WISHLIST
  // ==========================================================

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

  // ==========================================================
  // MESSAGE
  // ==========================================================

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

// ==========================================================
// WISHLIST PRODUCT CARD
// ==========================================================

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
    final int price = (product['price'] as num?)?.toInt() ?? 0;

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
            // ==================================================
            // IMAGE
            // ==================================================
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

                  // ==================================================
                  // CONDITION
                  // ==================================================
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

                  // ==================================================
                  // REMOVE
                  // ==================================================
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

                  // ==================================================
                  // CATEGORY
                  // ==================================================
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

            // ==================================================
            // DETAILS
            // ==================================================
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
