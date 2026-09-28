import 'package:flutter/material.dart';

import '../../app_theme/user/app_colors.dart';
import '../../app_theme/user/app_text_styles.dart';

class UserHowItWorks extends StatelessWidget {
  const UserHowItWorks({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        title: Text(
          'How It Works',
          style: AppTextStyles.title.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 35),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),

              const SizedBox(height: 24),

              _buildSectionTitle(
                'Buy Sustainable Products',
                'Find useful products and give them a new life.',
              ),

              const SizedBox(height: 14),

              _buildStep(
                number: '01',
                icon: Icons.search_rounded,
                title: 'Explore Products',
                description:
                    'Browse the EcoLoop marketplace and explore products '
                    'made from recycled, reused and upcycled materials.',
              ),

              _buildConnector(),

              _buildStep(
                number: '02',
                icon: Icons.visibility_outlined,
                title: 'View Product Details',
                description:
                    'Check product images, price, condition, category, '
                    'seller information, location and availability before buying.',
              ),

              _buildConnector(),

              _buildStep(
                number: '03',
                icon: Icons.shopping_cart_outlined,
                title: 'Add to Cart & Checkout',
                description:
                    'Choose the product you want, add it to your cart and '
                    'complete the checkout and payment process.',
              ),

              _buildConnector(),

              _buildStep(
                number: '04',
                icon: Icons.local_shipping_outlined,
                title: 'Track Your Order',
                description:
                    'After placing your order, use order tracking to follow '
                    'its progress until it reaches you.',
              ),

              const SizedBox(height: 30),

              _buildSectionTitle(
                'Give Your Items a New Life',
                'EcoLoop also lets you sell or donate unused items.',
              ),

              const SizedBox(height: 14),

              _buildStep(
                number: '05',
                icon: Icons.sell_outlined,
                title: 'Sell an Item',
                description:
                    'Create a listing by adding your product information, '
                    'category, price, stock, description and images.',
              ),

              _buildConnector(),

              _buildStep(
                number: '06',
                icon: Icons.volunteer_activism_outlined,
                title: 'Donate an Item',
                description:
                    'Choose an item you want to give away and create a '
                    'donation listing so it can find a new owner.',
              ),

              _buildConnector(),

              _buildStep(
                number: '07',
                icon: Icons.receipt_long_outlined,
                title: 'Manage Your Orders',
                description:
                    'View your purchases, selling orders and order details '
                    'from your account.',
              ),

              const SizedBox(height: 30),

              _buildSectionTitle(
                'Share Your Experience',
                'Your feedback helps the EcoLoop community.',
              ),

              const SizedBox(height: 14),

              _buildFeatureCard(
                icon: Icons.star_outline_rounded,
                title: 'Write Reviews',
                description:
                    'After purchasing a product, share your rating and '
                    'experience to help other users make informed decisions.',
              ),

              const SizedBox(height: 12),

              _buildFeatureCard(
                icon: Icons.favorite_border_rounded,
                title: 'Save Products',
                description:
                    'Add products to your wishlist so you can easily find '
                    'them again later.',
              ),

              const SizedBox(height: 12),

              _buildFeatureCard(
                icon: Icons.eco_outlined,
                title: 'Track Your Eco Impact',
                description:
                    'Use your Eco Impact section to see your contribution '
                    'towards reuse and sustainable living.',
              ),

              const SizedBox(height: 28),

              _buildBottomCard(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 31),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to EcoLoop',
                  style: AppTextStyles.title.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'Buy, sell, donate and give unused things a new life.',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 11.5,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION TITLE
  // ---------------------------------------------------------------------------

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.title.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          subtitle,
          style: AppTextStyles.body.copyWith(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP CARD
  // ---------------------------------------------------------------------------

  Widget _buildStep({
    required String number,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 49,
                height: 49,
                decoration: BoxDecoration(
                  color: AppColors.light,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  description,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CONNECTOR
  // ---------------------------------------------------------------------------

  Widget _buildConnector() {
    return Container(
      margin: const EdgeInsets.only(left: 24),
      height: 16,
      width: 1.5,
      color: AppColors.accent,
    );
  }

  // ---------------------------------------------------------------------------
  // FEATURE CARD
  // ---------------------------------------------------------------------------

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  description,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BOTTOM ECO CARD
  // ---------------------------------------------------------------------------

  Widget _buildBottomCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.recycling_rounded, color: Colors.white, size: 28),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              'Every reused, recycled, sold or donated item can help reduce waste and support a more sustainable community.',
              style: AppTextStyles.body.copyWith(
                color: Colors.white,
                fontSize: 11.5,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
