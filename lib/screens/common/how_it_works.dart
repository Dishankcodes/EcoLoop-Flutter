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
                'Buy Products',
                'Find useful products and give them a new life.',
              ),
              const SizedBox(height: 14),
              _buildStep(
                number: '01',
                icon: Icons.search_rounded,
                title: 'Explore Products',
                description:
                    'Browse marketplace listings from users and ReMakers. '
                    'Explore available products and categories.',
              ),
              _buildConnector(),
              _buildStep(
                number: '02',
                icon: Icons.visibility_outlined,
                title: 'View Product Details',
                description:
                    'Check the product images, description, price, condition, '
                    'seller information and availability before ordering.',
              ),
              _buildConnector(),
              _buildStep(
                number: '03',
                icon: Icons.shopping_cart_outlined,
                title: 'Checkout',
                description:
                    'Review the order details, quantity, delivery information '
                    'and price summary before confirming your order.',
              ),
              _buildConnector(),
              _buildStep(
                number: '04',
                icon: Icons.local_shipping_outlined,
                title: 'Follow Your Order',
                description:
                    'Open Orders and Buying Orders to view available order '
                    'status, tracking and delivery information.',
              ),

              const SizedBox(height: 30),

              _buildSectionTitle(
                'Sell Your Items',
                'List items you are authorised to sell.',
              ),
              const SizedBox(height: 14),
              _buildStep(
                number: '05',
                icon: Icons.add_box_outlined,
                title: 'Create a Listing',
                description:
                    'Open Add Product, add photos, enter the product name '
                    'and description, choose the category, set the price '
                    'and enter the available quantity.',
              ),
              _buildConnector(),
              _buildStep(
                number: '06',
                icon: Icons.storefront_outlined,
                title: 'Publish and Manage',
                description:
                    'Publish your listing and manage it through My Listings. '
                    'Keep product information, prices and stock accurate.',
              ),
              _buildConnector(),
              _buildStep(
                number: '07',
                icon: Icons.inventory_2_outlined,
                title: 'Manage Selling Orders',
                description:
                    'Review incoming orders and use the available order '
                    'status actions to reflect actual progress.',
              ),

              const SizedBox(height: 30),

              _buildSectionTitle(
                'Donate Items',
                'Help useful items find another purpose.',
              ),
              const SizedBox(height: 14),
              _buildStep(
                number: '08',
                icon: Icons.volunteer_activism_outlined,
                title: 'Submit a Donation',
                description:
                    'Open the donation feature, provide the requested item '
                    'details and photos, and submit the donation request.',
              ),
              _buildConnector(),
              _buildStep(
                number: '09',
                icon: Icons.local_shipping_outlined,
                title: 'Check Donation Status',
                description:
                    'Follow the status shown for your request. Acceptance, '
                    'pickup availability, timing and rewards depend on '
                    'eligibility and the actual service offered.',
              ),

              const SizedBox(height: 30),

              _buildSectionTitle(
                'Explore Custom Services',
                'Connect your project requirements with ReMakers.',
              ),
              const SizedBox(height: 14),
              _buildStep(
                number: '10',
                icon: Icons.design_services_outlined,
                title: 'Submit Your Requirements',
                description:
                    'Where custom services are available, describe your '
                    'project, budget and expected outcome. Add reference '
                    'images only if you have permission to share them.',
              ),
              _buildConnector(),
              _buildStep(
                number: '11',
                icon: Icons.handshake_outlined,
                title: 'Review ReMaker Proposals',
                description:
                    'Review the proposals available for your request. '
                    'Before accepting, clarify scope, price, timeline, '
                    'revisions and delivery or collection arrangements.',
              ),
              _buildConnector(),
              _buildStep(
                number: '12',
                icon: Icons.check_circle_outline_rounded,
                title: 'Confirm Completion',
                description:
                    'Use the available request and acceptance actions to '
                    'record progress. Keep any agreement about completion, '
                    'ownership and disputes clear with the ReMaker.',
              ),

              const SizedBox(height: 30),

              _buildSectionTitle(
                'Make the Most of EcoLoop',
                'Use the features available in your account.',
              ),
              const SizedBox(height: 14),
              _buildFeatureCard(
                icon: Icons.star_outline_rounded,
                title: 'Write Reviews',
                description:
                    'Share honest feedback about a genuine purchase or '
                    'experience when the review option is available.',
              ),
              const SizedBox(height: 12),
              _buildFeatureCard(
                icon: Icons.favorite_border_rounded,
                title: 'Save Products',
                description:
                    'Add products to your wishlist so you can find them '
                    'again later.',
              ),
              const SizedBox(height: 12),
              _buildFeatureCard(
                icon: Icons.palette_outlined,
                title: 'Discover ReMakers',
                description:
                    'Explore public profiles, products and portfolio '
                    'work from creators in the EcoLoop community.',
              ),
              const SizedBox(height: 12),
              _buildFeatureCard(
                icon: Icons.eco_outlined,
                title: 'Track Your Eco Impact',
                description:
                    'View the Eco Impact information displayed in your '
                    'account. Figures depend on the available recorded data.',
              ),

              const SizedBox(height: 28),
              _buildBottomCard(),
              const SizedBox(height: 15),
              Center(
                child: Text(
                  'Support: ecoloopp2026@gmail.com',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                    height: 1.5,
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
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

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
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnector() {
    return Container(
      margin: const EdgeInsets.only(left: 24),
      height: 16,
      width: 1.5,
      color: AppColors.accent,
    );
  }

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
        crossAxisAlignment: CrossAxisAlignment.start,
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
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
              'Every reused, sold or donated item can help keep useful '
              'materials in circulation and support a more sustainable '
              'community.',
              style: AppTextStyles.body.copyWith(
                color: Colors.white,
                fontSize: 11.5,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
