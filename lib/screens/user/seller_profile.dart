import 'package:flutter/material.dart';

import '../../app_theme/app_colors.dart';
import '../../app_theme/app_text_styles.dart';
import 'product_details.dart';

class SellerProfile extends StatefulWidget {
  const SellerProfile({super.key, required this.seller});

  final Map<String, dynamic> seller;

  @override
  State<SellerProfile> createState() => _SellerProfileState();
}

class _SellerProfileState extends State<SellerProfile> {
  bool _isFollowing = false;

  // ============================================================
  // SELLER LISTINGS
  // ============================================================

  late final List<Map<String, dynamic>> _listings;

  @override
  void initState() {
    super.initState();

    _listings = [
      {
        'id': 101,
        'title': 'Wooden Study Table',
        'price': 2500,
        'seller': widget.seller['name'] ?? 'Rahul',
        'condition': 'Used',
        'category': 'Furniture',
        'location': widget.seller['location'] ?? 'Ahmedabad, Gujarat',
        'views': 182,
        'wishlistCount': 21,
        'availableQuantity': 1,
        'description':
            'Solid wooden study table in good condition. '
            'Suitable for home offices, study rooms and creative spaces.',
        'image':
            'https://images.unsplash.com/photo-1533090481720-856c6e3c1fdc'
            '?auto=format&fit=crop&w=1000&q=85',
        'images': [
          'https://images.unsplash.com/photo-1533090481720-856c6e3c1fdc'
              '?auto=format&fit=crop&w=1200&q=85',
        ],
      },
      {
        'id': 102,
        'title': 'Wooden Side Chair',
        'price': 1200,
        'seller': widget.seller['name'] ?? 'Rahul',
        'condition': 'Good',
        'category': 'Furniture',
        'location': widget.seller['location'] ?? 'Ahmedabad, Gujarat',
        'views': 94,
        'wishlistCount': 12,
        'availableQuantity': 2,
        'description':
            'Comfortable wooden chair that can be reused at home, '
            'in a workspace or for creative projects.',
        'image':
            'https://images.unsplash.com/photo-1503602642458-232111445657'
            '?auto=format&fit=crop&w=1000&q=85',
        'images': [
          'https://images.unsplash.com/photo-1503602642458-232111445657'
              '?auto=format&fit=crop&w=1200&q=85',
        ],
      },
      {
        'id': 103,
        'title': 'Reclaimed Wood Pieces',
        'price': 450,
        'seller': widget.seller['name'] ?? 'Rahul',
        'condition': 'Recycled',
        'category': 'Materials',
        'location': widget.seller['location'] ?? 'Ahmedabad, Gujarat',
        'views': 71,
        'wishlistCount': 8,
        'availableQuantity': 5,
        'description':
            'Collection of reclaimed wood pieces for DIY, '
            'crafting and upcycling projects.',
        'image':
            'https://images.unsplash.com/photo-1519710164239-da123dc03ef4'
            '?auto=format&fit=crop&w=1000&q=85',
        'images': [
          'https://images.unsplash.com/photo-1519710164239-da123dc03ef4'
              '?auto=format&fit=crop&w=1200&q=85',
        ],
      },
      {
        'id': 104,
        'title': 'Vintage Storage Cabinet',
        'price': 2200,
        'seller': widget.seller['name'] ?? 'Rahul',
        'condition': 'Used',
        'category': 'Furniture',
        'location': widget.seller['location'] ?? 'Ahmedabad, Gujarat',
        'views': 143,
        'wishlistCount': 16,
        'availableQuantity': 1,
        'description':
            'Vintage storage cabinet with plenty of room for '
            'books, decor and household items.',
        'image':
            'https://images.unsplash.com/photo-1558997519-83ea9252edf8'
            '?auto=format&fit=crop&w=1000&q=85',
        'images': [
          'https://images.unsplash.com/photo-1558997519-83ea9252edf8'
              '?auto=format&fit=crop&w=1200&q=85',
        ],
      },
    ];
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final sellerName = widget.seller['name']?.toString() ?? 'Rahul';

    final location =
        widget.seller['location']?.toString() ?? 'Ahmedabad, Gujarat';

    final rating = widget.seller['rating']?.toString() ?? '4.8';

    final reviews = widget.seller['reviews']?.toString() ?? '42';

    final listings = widget.seller['listings']?.toString() ?? '127';

    final sold = widget.seller['sold']?.toString() ?? '42';

    final positive = widget.seller['positive']?.toString() ?? '98%';

    return Scaffold(
      backgroundColor: AppColors.background,

      // ==========================================================
      // APP BAR
      // ==========================================================
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,

        leading: IconButton(
          tooltip: 'Back',
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
        ),

        title: Text(
          'Seller Profile',
          style: AppTextStyles.title.copyWith(fontSize: 20),
        ),

        actions: [
          IconButton(
            tooltip: 'More',
            onPressed: _showMoreOptions,
            icon: const Icon(
              Icons.more_vert_rounded,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),

      // ==========================================================
      // BODY
      // ==========================================================
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 5, 20, 35),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --------------------------------------------------
              // SELLER HEADER
              // --------------------------------------------------
              _buildSellerHeader(
                sellerName: sellerName,
                location: location,
                rating: rating,
                reviews: reviews,
              ),

              const SizedBox(height: 18),

              // --------------------------------------------------
              // FOLLOW / CONTACT
              // --------------------------------------------------
              _buildActionButtons(),

              const SizedBox(height: 22),

              // --------------------------------------------------
              // STATS
              // --------------------------------------------------
              _buildStats(listings: listings, sold: sold, positive: positive),

              const SizedBox(height: 24),

              // --------------------------------------------------
              // ABOUT SELLER
              // --------------------------------------------------
              _buildAboutSeller(),

              const SizedBox(height: 25),

              // --------------------------------------------------
              // LISTINGS HEADER
              // --------------------------------------------------
              _buildListingsHeader(),

              const SizedBox(height: 12),

              // --------------------------------------------------
              // PRODUCT GRID
              // --------------------------------------------------
              _buildListings(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SELLER HEADER
  // ============================================================

  Widget _buildSellerHeader({
    required String sellerName,
    required String location,
    required String rating,
    required String reviews,
  }) {
    return Center(
      child: Column(
        children: [
          // ------------------------------------------------------
          // AVATAR
          // ------------------------------------------------------
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 94,
                height: 94,
                decoration: BoxDecoration(
                  color: AppColors.light,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accent, width: 3),
                ),
                child: Center(
                  child: Text(
                    sellerName.isNotEmpty ? sellerName[0].toUpperCase() : 'R',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              // --------------------------------------------------
              // VERIFIED BADGE
              // --------------------------------------------------
              Positioned(
                right: 1,
                bottom: 3,
                child: Container(
                  width: 29,
                  height: 29,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 3),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ------------------------------------------------------
          // NAME
          // ------------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                sellerName,
                style: AppTextStyles.title.copyWith(fontSize: 20),
              ),

              const SizedBox(width: 5),

              const Icon(
                Icons.verified_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ],
          ),

          const SizedBox(height: 5),

          // ------------------------------------------------------
          // RATING
          // ------------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 17),

              const SizedBox(width: 4),

              Text(
                rating,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(width: 3),

              Text('($reviews reviews)', style: AppTextStyles.caption),
            ],
          ),

          const SizedBox(height: 5),

          // ------------------------------------------------------
          // LOCATION
          // ------------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: AppColors.textSecondary,
                size: 14,
              ),

              const SizedBox(width: 3),

              Text(location, style: AppTextStyles.caption),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            'Member since January 2025',
            style: AppTextStyles.caption.copyWith(fontSize: 9),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTION BUTTONS
  // ============================================================

  Widget _buildActionButtons() {
    return Row(
      children: [
        // --------------------------------------------------------
        // FOLLOW
        // --------------------------------------------------------
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _isFollowing = !_isFollowing;
              });

              _showMessage(
                _isFollowing
                    ? 'You are now following this seller.'
                    : 'Seller removed from following.',
              );
            },
            icon: Icon(
              _isFollowing
                  ? Icons.check_rounded
                  : Icons.person_add_alt_1_outlined,
              size: 17,
            ),
            label: Text(_isFollowing ? 'Following' : 'Follow'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              minimumSize: const Size(0, 46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        // --------------------------------------------------------
        // CONTACT
        // --------------------------------------------------------
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _contactSeller,
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 17),
            label: const Text('Contact Seller'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(0, 46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATS
  // ============================================================

  Widget _buildStats({
    required String listings,
    required String sold,
    required String positive,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.accent.withOpacity(0.45)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _statItem(
              value: listings,
              label: 'Listings',
              icon: Icons.inventory_2_outlined,
            ),
          ),

          _statDivider(),

          Expanded(
            child: _statItem(
              value: sold,
              label: 'Sold',
              icon: Icons.shopping_bag_outlined,
            ),
          ),

          _statDivider(),

          Expanded(
            child: _statItem(
              value: positive,
              label: 'Positive',
              icon: Icons.thumb_up_alt_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),

        const SizedBox(height: 5),

        Text(value, style: AppTextStyles.title.copyWith(fontSize: 17)),

        const SizedBox(height: 2),

        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 9)),
      ],
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1,
      height: 42,
      color: AppColors.accent.withOpacity(0.55),
    );
  }

  // ============================================================
  // ABOUT SELLER
  // ============================================================

  Widget _buildAboutSeller() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('About Seller', style: AppTextStyles.title.copyWith(fontSize: 16)),

        const SizedBox(height: 10),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.accent.withOpacity(0.45)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'I believe useful things should not be '
                'thrown away. I enjoy giving furniture, '
                'materials and household items a second life.',
                style: AppTextStyles.body.copyWith(fontSize: 12, height: 1.55),
              ),

              const SizedBox(height: 13),

              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  _interestTag('♻️ Sustainability'),
                  _interestTag('🪵 Upcycling'),
                  _interestTag('🎨 DIY'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _interestTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 9,
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================================
  // LISTINGS HEADER
  // ============================================================

  Widget _buildListingsHeader() {
    return Row(
      children: [
        Text(
          'Active Listings',
          style: AppTextStyles.title.copyWith(fontSize: 16),
        ),

        const SizedBox(width: 7),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.light,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '${_listings.length}',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        const Spacer(),

        Text(
          'Newest',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(width: 3),

        const Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 16,
          color: AppColors.primary,
        ),
      ],
    );
  }

  // ============================================================
  // LISTINGS
  // ============================================================

  Widget _buildListings() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _listings.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
        childAspectRatio: 0.67,
      ),
      itemBuilder: (context, index) {
        final product = _listings[index];

        return _SellerProductCard(
          product: product,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetails(product: product),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // CONTACT SELLER
  // ============================================================

  void _contactSeller() {
    _showMessage('Chat with seller will be connected later.');
  }

  // ============================================================
  // MORE OPTIONS
  // ============================================================

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 18),

                _sellerOption(
                  icon: Icons.flag_outlined,
                  title: 'Report Seller',
                  destructive: true,
                  onTap: () {
                    Navigator.pop(sheetContext);

                    _showMessage('Report seller option selected.');
                  },
                ),

                const SizedBox(height: 9),

                _sellerOption(
                  icon: Icons.block_outlined,
                  title: 'Block Seller',
                  destructive: true,
                  onTap: () {
                    Navigator.pop(sheetContext);

                    _showMessage('Block seller option selected.');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sellerOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(13),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: destructive
              ? AppColors.error.withOpacity(0.05)
              : AppColors.background,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: destructive
                ? AppColors.error.withOpacity(0.2)
                : AppColors.accent.withOpacity(0.4),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: destructive ? AppColors.error : AppColors.primary,
            ),

            const SizedBox(width: 10),

            Text(
              title,
              style: TextStyle(
                color: destructive ? AppColors.error : AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),

            const Spacer(),

            Icon(
              Icons.chevron_right_rounded,
              size: 19,
              color: destructive ? AppColors.error : AppColors.textSecondary,
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
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

// =================================================================
// SELLER PRODUCT CARD
// =================================================================

class _SellerProductCard extends StatelessWidget {
  const _SellerProductCard({required this.product, required this.onTap});

  final Map<String, dynamic> product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final price = (product['price'] as num).toInt();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: AppColors.accent.withOpacity(0.42)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ======================================================
            // IMAGE
            // ======================================================
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      product['image'].toString(),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.light,
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 32,
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
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        product['condition'].toString(),
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),

                  // ------------------------------------------------
                  // CATEGORY
                  // ------------------------------------------------
                  Positioned(
                    bottom: 8,
                    left: 8,
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
                        product['category'].toString(),
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

            // ======================================================
            // DETAILS
            // ======================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['title'].toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    '₹$price',
                    style: AppTextStyles.title.copyWith(fontSize: 16),
                  ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      const Icon(
                        Icons.visibility_outlined,
                        size: 11,
                        color: AppColors.textSecondary,
                      ),

                      const SizedBox(width: 3),

                      Text(
                        '${product['views']} views',
                        style: AppTextStyles.caption.copyWith(fontSize: 9),
                      ),

                      const Spacer(),

                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 12,
                        color: AppColors.primary,
                      ),
                    ],
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
