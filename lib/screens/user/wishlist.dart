import 'package:flutter/material.dart';

import '../../app_theme/app_colors.dart';
import '../../app_theme/app_text_styles.dart';
import 'product_details.dart';

class Wishlist extends StatefulWidget {
  const Wishlist({super.key});

  @override
  State<Wishlist> createState() => _WishlistState();
}

class _WishlistState extends State<Wishlist> {
  final TextEditingController _searchController = TextEditingController();

  String searchQuery = '';

  final List<Map<String, dynamic>> _wishlistItems = [
    {
      'id': 1,
      'title': 'Wooden Study Table',
      'price': 2500,
      'condition': 'Good',
      'seller': 'Eco Seller',
      'category': 'Furniture',
      'location': 'Ahmedabad, Gujarat',
      'views': 126,
      'wishlistCount': 14,
      'availableQuantity': 1,
      'description':
          'A sturdy pre-owned wooden study table in good condition. '
          'Perfect for study, work or creative projects.',
      'image':
          'https://images.unsplash.com/photo-1518455027359-f3f8164ba6b0'
          '?auto=format&fit=crop&w=900&q=85',
      'images': [
        'https://images.unsplash.com/photo-1518455027359-f3f8164ba6b0'
            '?auto=format&fit=crop&w=1200&q=85',
      ],
    },
    {
      'id': 2,
      'title': 'Vintage Desk Lamp',
      'price': 850,
      'condition': 'Like New',
      'seller': 'Green Finds',
      'category': 'Decor',
      'location': 'Vadodara, Gujarat',
      'views': 89,
      'wishlistCount': 9,
      'availableQuantity': 1,
      'description':
          'Vintage style desk lamp in excellent condition. '
          'Ideal for study tables, workspaces and home decor.',
      'image':
          'https://images.unsplash.com/photo-1507473885765-e6ed057f782c'
          '?auto=format&fit=crop&w=900&q=85',
      'images': [
        'https://images.unsplash.com/photo-1507473885765-e6ed057f782c'
            '?auto=format&fit=crop&w=1200&q=85',
      ],
    },
    {
      'id': 3,
      'title': 'Recycled Storage Basket',
      'price': 450,
      'condition': 'Good',
      'seller': 'ReCraft Studio',
      'category': 'Decor',
      'location': 'Surat, Gujarat',
      'views': 74,
      'wishlistCount': 12,
      'availableQuantity': 2,
      'description':
          'Reusable storage basket made using recycled materials. '
          'Useful for organizing everyday household items.',
      'image':
          'https://images.unsplash.com/photo-1586023492125-27b2c045efd7'
          '?auto=format&fit=crop&w=900&q=85',
      'images': [
        'https://images.unsplash.com/photo-1586023492125-27b2c045efd7'
            '?auto=format&fit=crop&w=1200&q=85',
      ],
    },
    {
      'id': 4,
      'title': 'Glass Bottle Collection',
      'price': 300,
      'condition': 'Used',
      'seller': 'Eco Seller',
      'category': 'Materials',
      'location': 'Ahmedabad, Gujarat',
      'views': 61,
      'wishlistCount': 7,
      'availableQuantity': 6,
      'description':
          'Collection of reusable glass bottles suitable for '
          'DIY projects, decoration, crafts and upcycling.',
      'image':
          'https://images.unsplash.com/photo-1602143407151-7111542de6e8'
          '?auto=format&fit=crop&w=900&q=85',
      'images': [
        'https://images.unsplash.com/photo-1602143407151-7111542de6e8'
            '?auto=format&fit=crop&w=1200&q=85',
      ],
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredItems {
    if (searchQuery.trim().isEmpty) {
      return _wishlistItems;
    }

    final query = searchQuery.toLowerCase().trim();

    return _wishlistItems.where((product) {
      final title = product['title'].toString().toLowerCase();
      final category = product['category'].toString().toLowerCase();
      final seller = product['seller'].toString().toLowerCase();

      return title.contains(query) ||
          category.contains(query) ||
          seller.contains(query);
    }).toList();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,

        title: Text(
          'Wishlist',
          style: AppTextStyles.title.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),

        actions: [
          if (_wishlistItems.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) {
                if (value == 'clear') {
                  _confirmClearWishlist();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep_outlined, color: AppColors.error),
                      SizedBox(width: 12),
                      Text('Clear Wishlist'),
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

  // ============================================================
  // HEADER
  // ============================================================

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
                  'Saved for later',
                  style: AppTextStyles.title.copyWith(fontSize: 17),
                ),
                const SizedBox(height: 3),
                Text(
                  'Keep your favourite finds in one place.',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),

          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.favorite_rounded,
              size: 22,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.accent.withOpacity(0.55)),
        ),
        child: TextField(
          controller: _searchController,

          onChanged: (value) {
            setState(() {
              searchQuery = value;
            });
          },

          decoration: InputDecoration(
            hintText: 'Search saved items...',
            hintStyle: AppTextStyles.hint,

            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.primary,
            ),

            suffixIcon: searchQuery.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();

                      setState(() {
                        searchQuery = '';
                      });
                    },
                    icon: const Icon(Icons.close_rounded, size: 19),
                  )
                : null,

            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // RESULT INFO
  // ============================================================

  Widget _buildResultInfo() {
    final count = _filteredItems.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: [
          Text(
            '$count ${count == 1 ? 'saved item' : 'saved items'}',
            style: AppTextStyles.caption,
          ),

          const Spacer(),

          if (searchQuery.isNotEmpty)
            Text(
              'Search results',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // GRID
  // ============================================================

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
        childAspectRatio: 0.64,
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

  // ============================================================
  // OPEN PRODUCT
  // ============================================================

  void _openProductDetails(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetails(product: product)),
    );
  }

  // ============================================================
  // REMOVE PRODUCT
  // ============================================================

  void _removeProduct(Map<String, dynamic> product) {
    final originalIndex = _wishlistItems.indexOf(product);

    if (originalIndex == -1) return;

    setState(() {
      _wishlistItems.remove(product);
    });

    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['title']} removed from wishlist.'),
        behavior: SnackBarBehavior.floating,

        action: SnackBarAction(
          label: 'UNDO',
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

  // ============================================================
  // CLEAR WISHLIST
  // ============================================================

  void _confirmClearWishlist() {
    showDialog(
      context: context,

      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),

          icon: Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: AppColors.light,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.error,
            ),
          ),

          title: const Text('Clear Wishlist?', textAlign: TextAlign.center),

          content: const Text(
            'All your saved products will be removed from the wishlist.',
            textAlign: TextAlign.center,
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                setState(() {
                  _wishlistItems.clear();
                });

                _showMessage('Wishlist cleared.');
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // NO SEARCH RESULT
  // ============================================================

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
              decoration: const BoxDecoration(
                color: AppColors.light,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 37,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 18),

            Text('No saved items found', style: AppTextStyles.title),

            const SizedBox(height: 7),

            Text(
              'Try searching with another product name, category or seller.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),

            const SizedBox(height: 18),

            OutlinedButton.icon(
              onPressed: () {
                _searchController.clear();

                setState(() {
                  searchQuery = '';
                });
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Clear Search'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY WISHLIST
  // ============================================================

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
                color: AppColors.light,
                borderRadius: BorderRadius.circular(32),
              ),

              child: const Icon(
                Icons.favorite_border_rounded,
                size: 50,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 23),

            Text(
              'Your wishlist is empty',
              textAlign: TextAlign.center,
              style: AppTextStyles.title.copyWith(fontSize: 20),
            ),

            const SizedBox(height: 9),

            Text(
              'Save products you like while exploring EcoLoop. '
              'You can come back and view them anytime.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: 220,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.storefront_outlined),
                label: const Text('Explore Marketplace'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

// =================================================================
// WISHLIST PRODUCT CARD
// =================================================================

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
    final int price = (product['price'] as num).toInt();

    return GestureDetector(
      onTap: onTap,

      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,

          borderRadius: BorderRadius.circular(17),

          border: Border.all(color: AppColors.accent.withOpacity(0.42)),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 9,
              offset: const Offset(0, 4),
            ),
          ],
        ),

        clipBehavior: Clip.antiAlias,

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =================================================
            // IMAGE
            // =================================================
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      product['image'],
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

                  // ------------------------------------------------
                  // CONDITION
                  // ------------------------------------------------
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
                        product['condition'],
                        style: const TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),

                  // ------------------------------------------------
                  // REMOVE WISHLIST
                  // ------------------------------------------------
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
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ------------------------------------------------
                  // CATEGORY
                  // ------------------------------------------------
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
                        product['category'],
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

            // =================================================
            // DETAILS
            // =================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['title'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,

                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    '₹$price',
                    style: AppTextStyles.title.copyWith(fontSize: 17),
                  ),

                  const SizedBox(height: 5),

                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),

                      const SizedBox(width: 3),

                      Expanded(
                        child: Text(
                          product['seller'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,

                          style: AppTextStyles.caption.copyWith(fontSize: 9.5),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

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
                          product['location'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,

                          style: AppTextStyles.caption.copyWith(fontSize: 8.5),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    height: 32,

                    child: OutlinedButton(
                      onPressed: onTap,

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
