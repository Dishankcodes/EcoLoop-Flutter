import 'package:flutter/material.dart';

import '../../app_theme/app_colors.dart';
import '../../app_theme/app_text_styles.dart';
import '../../widgets/user_more_menu.dart';

class Marketplace extends StatefulWidget {
  const Marketplace({super.key});

  @override
  State<Marketplace> createState() => _MarketplaceState();
}

class _MarketplaceState extends State<Marketplace> {
  int selectedCategory = 0;

  final List<String> categories = [
    'All',
    'Furniture',
    'Decor',
    'Electronics',
    'Materials',
  ];

  final List<Map<String, String>> products = [
    {
      'title': 'Reclaimed Wood Chair',
      'price': '₹1,299',
      'seller': 'Creative Studio',
      'condition': 'Upcycled',
    },
    {
      'title': 'Wooden Side Table',
      'price': '₹1,800',
      'seller': 'Rahul',
      'condition': 'Used',
    },
    {
      'title': 'Vintage Bottle Lamp',
      'price': '₹899',
      'seller': 'Eco Artist',
      'condition': 'Recycled',
    },
    {
      'title': 'Pallet Sofa',
      'price': '₹4,200',
      'seller': 'Green Crafts',
      'condition': 'Upcycled',
    },
    {
      'title': 'Recycled Glass Set',
      'price': '₹650',
      'seller': 'Priya',
      'condition': 'Recycled',
    },
    {
      'title': 'Old Wooden Cabinet',
      'price': '₹2,200',
      'seller': 'Amit',
      'condition': 'Used',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            sliver: SliverToBoxAdapter(child: _buildHeader()),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            sliver: SliverToBoxAdapter(child: _buildSearch()),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 17, 20, 0),
            sliver: SliverToBoxAdapter(child: _buildCategories()),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 15, 20, 0),
            sliver: SliverToBoxAdapter(child: _buildFilterRow()),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate((context, index) {
                final product = products[index];

                return _productCard(product);
              }, childCount: products.length),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 14,
                childAspectRatio: 0.76,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          'Marketplace',
          style: AppTextStyles.heading.copyWith(fontSize: 22),
        ),
        const Spacer(),
        const UserMoreMenu(),
      ],
    );
  }

  Widget _buildSearch() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withOpacity(0.55)),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search products...',
          hintStyle: AppTextStyles.hint,
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.primary,
          ),
          suffixIcon: const Icon(
            Icons.tune_rounded,
            color: AppColors.textSecondary,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final bool selected = selectedCategory == index;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedCategory = index;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.accent,
                ),
              ),
              child: Text(
                categories[index],
                style: TextStyle(
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

  Widget _buildFilterRow() {
    return Row(
      children: [
        Expanded(child: _filterButton(Icons.tune_rounded, 'Filters')),
        const SizedBox(width: 10),
        Expanded(child: _filterButton(Icons.swap_vert_rounded, 'Sort')),
      ],
    );
  }

  Widget _filterButton(IconData icon, String text) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.accent.withOpacity(0.55)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 17, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _productCard(Map<String, String> product) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withOpacity(0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.light,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: const Icon(
                    Icons.image_outlined,
                    size: 42,
                    color: AppColors.secondary,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 31,
                    height: 31,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_border_rounded,
                      size: 17,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(11, 9, 11, 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['title']!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  product['price']!,
                  style: AppTextStyles.title.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  '${product['seller']} • ${product['condition']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(fontSize: 9.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
