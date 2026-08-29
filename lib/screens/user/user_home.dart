import 'package:flutter/material.dart';

import '../../app_theme/app_colors.dart';
import '../../app_theme/app_text_styles.dart';
import '../../widgets/user_more_menu.dart';

class UserHome extends StatelessWidget {
  const UserHome({super.key});

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
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            sliver: SliverToBoxAdapter(child: _buildGreeting()),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            sliver: SliverToBoxAdapter(child: _buildSearchBar()),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _buildSectionTitle('Explore Categories'),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            sliver: SliverToBoxAdapter(child: _buildCategories()),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            sliver: SliverToBoxAdapter(child: _buildSellBanner()),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _buildSectionTitle('Recommended For You'),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
            sliver: SliverToBoxAdapter(child: _buildProducts()),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text(
              'E',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text('EcoLoop', style: AppTextStyles.title.copyWith(fontSize: 19)),
        const Spacer(),
        const UserMoreMenu(),
      ],
    );
  }

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello there 👋',
          style: AppTextStyles.heading.copyWith(fontSize: 23),
        ),
        const SizedBox(height: 4),
        Text('Give unused things a new life.', style: AppTextStyles.body),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withOpacity(0.55)),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search products...',
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.primary,
          ),
          hintStyle: AppTextStyles.hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTextStyles.title.copyWith(fontSize: 17));
  }

  Widget _buildCategories() {
    final categories = [
      {'title': 'Furniture', 'icon': Icons.chair_outlined},
      {'title': 'Decor', 'icon': Icons.home_work_outlined},
      {'title': 'Electronics', 'icon': Icons.devices_other_outlined},
      {'title': 'Materials', 'icon': Icons.layers_outlined},
    ];

    return SizedBox(
      height: 105,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return Container(
            width: 88,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.accent.withOpacity(0.55)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  categories[index]['icon'] as IconData,
                  size: 25,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 7),
                Text(
                  categories[index]['title'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSellBanner() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.accent),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.recycling_rounded,
              color: AppColors.primary,
              size: 27,
            ),
          ),
          const SizedBox(width: 12),
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
          const Text(
            'Sell',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProducts() {
    final products = [
      {
        'title': 'Reclaimed Wood Table',
        'price': '₹2,500',
        'seller': 'Rahul',
        'condition': 'Used',
      },
      {
        'title': 'Recycled Bottle Lamp',
        'price': '₹899',
        'seller': 'Creative Studio',
        'condition': 'Upcycled',
      },
      {
        'title': 'Wooden Pallet Sofa',
        'price': '₹4,200',
        'seller': 'Eco Artist',
        'condition': 'Upcycled',
      },
      {
        'title': 'Recycled Glass Decor',
        'price': '₹650',
        'seller': 'Priya',
        'condition': 'Recycled',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, index) {
        final product = products[index];

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.accent.withOpacity(0.45)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.light,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.image_outlined,
                    size: 38,
                    color: AppColors.secondary,
                  ),
                ),
              ),
              const SizedBox(height: 9),
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
                style: AppTextStyles.title.copyWith(fontSize: 15),
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
        );
      },
    );
  }
}
