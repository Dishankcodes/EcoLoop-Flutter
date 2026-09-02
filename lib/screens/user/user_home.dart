import 'package:flutter/material.dart';

import '../../app_theme/app_colors.dart';
import '../../app_theme/app_text_styles.dart';
import '../../widgets/user_more_menu.dart';
import 'add_product.dart';
import 'donate_item.dart';
import 'marketplace.dart';
import 'product_details.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  // ============================================================
  // SEARCH
  // ============================================================

  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  // ============================================================
  // CATEGORIES
  // ============================================================

  final List<Map<String, dynamic>> _categories = [
    {'title': 'Furniture', 'icon': Icons.chair_outlined},
    {'title': 'Decor', 'icon': Icons.home_work_outlined},
    {'title': 'Electronics', 'icon': Icons.devices_other_outlined},
    {'title': 'Materials', 'icon': Icons.layers_outlined},
    {'title': 'Fashion', 'icon': Icons.checkroom_outlined},
    {'title': 'Books', 'icon': Icons.menu_book_outlined},
  ];

  // ============================================================
  // RECOMMENDED PRODUCTS
  // ============================================================

  final List<Map<String, dynamic>> _products = [
    {
      'id': 1,
      'title': 'Reclaimed Wood Table',
      'price': 2500,
      'seller': 'Rahul',
      'condition': 'Used',
      'category': 'Furniture',
      'location': 'Ahmedabad, Gujarat',
      'views': 182,
      'wishlistCount': 21,
      'availableQuantity': 1,
      'description':
          'Beautiful reclaimed wooden table in good usable condition. '
          'Perfect for study rooms, workspaces or creative projects.',
      'image':
          'https://images.unsplash.com/photo-1533090481720-856c6e3c1fdc'
          '?auto=format&fit=crop&w=1000&q=85',
      'images': [
        'https://images.unsplash.com/photo-1533090481720-856c6e3c1fdc'
            '?auto=format&fit=crop&w=1200&q=85',
      ],
    },
    {
      'id': 2,
      'title': 'Recycled Bottle Lamp',
      'price': 899,
      'seller': 'Creative Studio',
      'condition': 'Upcycled',
      'category': 'Decor',
      'location': 'Vadodara, Gujarat',
      'views': 126,
      'wishlistCount': 18,
      'availableQuantity': 2,
      'description':
          'Creative decorative lamp made from recycled glass bottles. '
          'A great addition to an eco-friendly home.',
      'image':
          'https://images.unsplash.com/photo-1507473885765-e6ed057f782c'
          '?auto=format&fit=crop&w=1000&q=85',
      'images': [
        'https://images.unsplash.com/photo-1507473885765-e6ed057f782c'
            '?auto=format&fit=crop&w=1200&q=85',
      ],
    },
    {
      'id': 3,
      'title': 'Wooden Pallet Sofa',
      'price': 4200,
      'seller': 'Eco Artist',
      'condition': 'Upcycled',
      'category': 'Furniture',
      'location': 'Surat, Gujarat',
      'views': 241,
      'wishlistCount': 32,
      'availableQuantity': 1,
      'description':
          'Handcrafted sofa made using reclaimed wooden pallets. '
          'Strong, unique and ideal for sustainable interiors.',
      'image':
          'https://images.unsplash.com/photo-1555041469-a586c61ea9bc'
          '?auto=format&fit=crop&w=1000&q=85',
      'images': [
        'https://images.unsplash.com/photo-1555041469-a586c61ea9bc'
            '?auto=format&fit=crop&w=1200&q=85',
      ],
    },
    {
      'id': 4,
      'title': 'Recycled Glass Decor',
      'price': 650,
      'seller': 'Priya',
      'condition': 'Recycled',
      'category': 'Decor',
      'location': 'Ahmedabad, Gujarat',
      'views': 97,
      'wishlistCount': 13,
      'availableQuantity': 4,
      'description':
          'Handmade decorative piece created from recycled glass. '
          'Perfect for shelves, tables and creative spaces.',
      'image':
          'https://images.unsplash.com/photo-1577083552431-6e5fd01988b5'
          '?auto=format&fit=crop&w=1000&q=85',
      'images': [
        'https://images.unsplash.com/photo-1577083552431-6e5fd01988b5'
            '?auto=format&fit=crop&w=1200&q=85',
      ],
    },
  ];

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ======================================================
            // HEADER
            // ======================================================
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              sliver: SliverToBoxAdapter(child: _buildHeader()),
            ),

            // ======================================================
            // GREETING
            // ======================================================
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              sliver: SliverToBoxAdapter(child: _buildGreeting()),
            ),

            // ======================================================
            // SEARCH
            // ======================================================
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              sliver: SliverToBoxAdapter(child: _buildSearchBar()),
            ),

            // ======================================================
            // QUICK ACTIONS
            // ======================================================
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              sliver: SliverToBoxAdapter(child: _buildQuickActions()),
            ),

            // ======================================================
            // EXPLORE CATEGORIES HEADER
            // ======================================================
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 25, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _buildSectionHeader(
                  'Explore Categories',
                  onTap: () {
                    _openMarketplace();
                  },
                ),
              ),
            ),

            // ======================================================
            // CATEGORIES
            // ======================================================
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: SliverToBoxAdapter(child: _buildCategories()),
            ),

            // ======================================================
            // SELL BANNER
            // ======================================================
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 25, 20, 0),
              sliver: SliverToBoxAdapter(child: _buildSellBanner()),
            ),

            // ======================================================
            // DONATE BANNER
            // ======================================================
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: SliverToBoxAdapter(child: _buildDonateBanner()),
            ),

            // ======================================================
            // RECOMMENDED HEADER
            // ======================================================
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 27, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _buildSectionHeader(
                  'Recommended For You',
                  onTap: () {
                    _openMarketplace();
                  },
                ),
              ),
            ),

            // ======================================================
            // RECOMMENDED PRODUCTS
            // ======================================================
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 35),
              sliver: SliverToBoxAdapter(child: _buildProducts()),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Row(
      children: [
        // --------------------------------------------------------
        // ECOLOOP LOGO
        // --------------------------------------------------------
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Center(
            child: Text(
              'E',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        // --------------------------------------------------------
        // ECOLOOP NAME
        // --------------------------------------------------------
        Text('EcoLoop', style: AppTextStyles.title.copyWith(fontSize: 19)),

        const Spacer(),

        // --------------------------------------------------------
        // MORE MENU
        // --------------------------------------------------------
        const UserMoreMenu(),
      ],
    );
  }

  // ============================================================
  // GREETING
  // ============================================================

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello there 👋',
          style: AppTextStyles.heading.copyWith(fontSize: 24),
        ),

        const SizedBox(height: 5),

        Text('Give unused things a new life.', style: AppTextStyles.body),
      ],
    );
  }

  // ============================================================
  // SEARCH BAR
  // ============================================================

  Widget _buildSearchBar() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.accent.withOpacity(0.55)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,

        // --------------------------------------------------------
        // SEARCH SUBMIT
        // --------------------------------------------------------
        onSubmitted: (value) {
          final query = value.trim();

          _openMarketplace(search: query.isEmpty ? null : query);
        },

        // --------------------------------------------------------
        // LIVE TEXT
        // --------------------------------------------------------
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },

        decoration: InputDecoration(
          hintText: 'Search products, materials...',
          hintStyle: AppTextStyles.hint,

          // ------------------------------------------------------
          // SEARCH ICON
          // ------------------------------------------------------
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.primary,
          ),

          // ------------------------------------------------------
          // CLEAR / OPEN MARKETPLACE
          // ------------------------------------------------------
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  tooltip: 'Clear search',
                  onPressed: () {
                    _searchController.clear();

                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 19,
                    color: AppColors.textSecondary,
                  ),
                )
              : IconButton(
                  tooltip: 'Search marketplace',
                  onPressed: () {
                    final query = _searchController.text.trim();

                    _openMarketplace(search: query.isEmpty ? null : query);
                  },
                  icon: const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.primary,
                  ),
                ),

          border: InputBorder.none,

          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  // ============================================================
  // QUICK ACTIONS
  // ============================================================

  Widget _buildQuickActions() {
    return Row(
      children: [
        // --------------------------------------------------------
        // SELL
        // --------------------------------------------------------
        Expanded(
          child: _QuickAction(
            icon: Icons.add_box_outlined,
            title: 'Sell Item',
            subtitle: 'List unused items',
            onTap: _openAddProduct,
          ),
        ),

        const SizedBox(width: 12),

        // --------------------------------------------------------
        // DONATE
        // --------------------------------------------------------
        Expanded(
          child: _QuickAction(
            icon: Icons.volunteer_activism_outlined,
            title: 'Donate',
            subtitle: 'Give items away',
            onTap: _openDonate,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _buildSectionHeader(String title, {VoidCallback? onTap}) {
    return Row(
      children: [
        Text(title, style: AppTextStyles.title.copyWith(fontSize: 17)),

        const Spacer(),

        if (onTap != null)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Row(
                children: [
                  Text(
                    'See all',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(width: 3),

                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // CATEGORIES
  // ============================================================

  Widget _buildCategories() {
    return SizedBox(
      height: 105,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        separatorBuilder: (_, __) {
          return const SizedBox(width: 10);
        },
        itemBuilder: (context, index) {
          final category = _categories[index];

          final String title = category['title'] as String;

          final IconData icon = category['icon'] as IconData;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              _openMarketplace(category: title);
            },
            child: Container(
              width: 88,
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.accent.withOpacity(0.55)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.018),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ------------------------------------------------
                  // CATEGORY ICON
                  // ------------------------------------------------
                  Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      color: AppColors.light,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, size: 23, color: AppColors.primary),
                  ),

                  const SizedBox(height: 7),

                  // ------------------------------------------------
                  // CATEGORY NAME
                  // ------------------------------------------------
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // SELL BANNER
  // ============================================================

  Widget _buildSellBanner() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openAddProduct,
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: AppColors.light,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.accent),
        ),
        child: Row(
          children: [
            // ------------------------------------------------------
            // ICON
            // ------------------------------------------------------
            Container(
              width: 49,
              height: 49,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.recycling_rounded,
                color: AppColors.primary,
                size: 28,
              ),
            ),

            const SizedBox(width: 12),

            // ------------------------------------------------------
            // TEXT
            // ------------------------------------------------------
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Have something unused?',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    'Sell it and give it a new life.',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // ------------------------------------------------------
            // SELL BUTTON
            // ------------------------------------------------------
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Sell',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  SizedBox(width: 3),

                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 13,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DONATE BANNER
  // ============================================================

  Widget _buildDonateBanner() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openDonate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.accent.withOpacity(0.55)),
        ),
        child: Row(
          children: [
            // ------------------------------------------------------
            // ICON
            // ------------------------------------------------------
            Container(
              width: 47,
              height: 47,
              decoration: BoxDecoration(
                color: AppColors.light,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.volunteer_activism_outlined,
                color: AppColors.primary,
                size: 25,
              ),
            ),

            const SizedBox(width: 11),

            // ------------------------------------------------------
            // TEXT
            // ------------------------------------------------------
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Want to give instead?',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    'Donate unused items to the community.',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),

            // ------------------------------------------------------
            // ARROW
            // ------------------------------------------------------
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // RECOMMENDED PRODUCTS
  // ============================================================

  Widget _buildProducts() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
        childAspectRatio: 0.68,
      ),
      itemBuilder: (context, index) {
        final product = _products[index];

        return _HomeProductCard(
          product: product,
          onTap: () {
            _openProduct(product);
          },
        );
      },
    );
  }

  // ============================================================
  // OPEN MARKETPLACE
  // ============================================================

  void _openMarketplace({String? search, String? category}) {
    // ------------------------------------------------------------
    // Clean empty values so Marketplace doesn't receive
    // empty search/category strings.
    // ------------------------------------------------------------

    final cleanSearch = search?.trim().isEmpty == true ? null : search?.trim();

    final cleanCategory = category?.trim().isEmpty == true
        ? null
        : category?.trim();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Marketplace(
          initialSearch: cleanSearch,
          initialCategory: cleanCategory,
        ),
      ),
    );
  }

  // ============================================================
  // OPEN ADD PRODUCT
  // ============================================================

  void _openAddProduct() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AddProduct()));
  }

  // ============================================================
  // OPEN DONATE
  // ============================================================

  void _openDonate() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const DonateItem()));
  }

  // ============================================================
  // OPEN PRODUCT DETAILS
  // ============================================================

  void _openProduct(Map<String, dynamic> product) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ProductDetails(product: product)));
  }
}

// =================================================================
// QUICK ACTION
// =================================================================

class _QuickAction extends StatelessWidget {
  const _QuickAction({
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.accent.withOpacity(0.45)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.018),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // ------------------------------------------------------
            // ICON
            // ------------------------------------------------------
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.light,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: AppColors.primary, size: 21),
            ),

            const SizedBox(width: 9),

            // ------------------------------------------------------
            // TEXT
            // ------------------------------------------------------
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(fontSize: 8.5),
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

// =================================================================
// HOME PRODUCT CARD
// =================================================================

class _HomeProductCard extends StatelessWidget {
  const _HomeProductCard({required this.product, required this.onTap});

  final Map<String, dynamic> product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final int price = (product['price'] as num).toInt();

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
              blurRadius: 9,
              offset: const Offset(0, 4),
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
                  // ------------------------------------------------
                  // PRODUCT IMAGE
                  // ------------------------------------------------
                  Positioned.fill(
                    child: Image.network(
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
                              size: 35,
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
            // PRODUCT DETAILS
            // ======================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ------------------------------------------------
                  // TITLE
                  // ------------------------------------------------
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

                  // ------------------------------------------------
                  // PRICE
                  // ------------------------------------------------
                  Text(
                    '₹$price',
                    style: AppTextStyles.title.copyWith(fontSize: 16),
                  ),

                  const SizedBox(height: 4),

                  // ------------------------------------------------
                  // SELLER
                  // ------------------------------------------------
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        size: 11,
                        color: AppColors.textSecondary,
                      ),

                      const SizedBox(width: 3),

                      Expanded(
                        child: Text(
                          product['seller'].toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(fontSize: 9),
                        ),
                      ),

                      const SizedBox(width: 3),

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
