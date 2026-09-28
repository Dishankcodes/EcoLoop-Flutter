import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';

class ArtistHowItWorks extends StatelessWidget {
  const ArtistHowItWorks({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtistColors.background,

      appBar: AppBar(
        backgroundColor: ArtistColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: ArtistColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),

        title: Text(
          'How It Works',
          style: ArtistTextStyles.title.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: ArtistColors.textPrimary,
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

              const SizedBox(height: 26),

              _buildSectionTitle(
                'Start Your Artist Journey',
                'Create, list and manage your products on EcoLoop.',
              ),

              const SizedBox(height: 14),

              _buildStep(
                number: '01',
                icon: Icons.person_outline_rounded,
                title: 'Create Your Artist Profile',
                description:
                    'Complete your artist profile with your information, '
                    'address and other details so customers can learn more about you.',
              ),

              _buildConnector(),

              _buildStep(
                number: '02',
                icon: Icons.add_box_outlined,
                title: 'Add Your Products',
                description:
                    'Create product listings by adding photos, product name, '
                    'category, price, stock quantity and description.',
              ),

              _buildConnector(),

              _buildStep(
                number: '03',
                icon: Icons.storefront_outlined,
                title: 'Publish Your Products',
                description:
                    'Your listed products can appear in the marketplace where '
                    'users can discover and purchase your work.',
              ),

              _buildConnector(),

              _buildStep(
                number: '04',
                icon: Icons.inventory_2_outlined,
                title: 'Manage Your Products',
                description:
                    'View your products, update product information, manage '
                    'stock and check product performance and analytics.',
              ),

              const SizedBox(height: 30),

              _buildSectionTitle(
                'Manage Your Sales',
                'Keep track of orders from customers.',
              ),

              const SizedBox(height: 14),

              _buildStep(
                number: '05',
                icon: Icons.shopping_bag_outlined,
                title: 'Receive Customer Orders',
                description:
                    'When a user purchases your product, you can view the '
                    'order details and customer information from your artist account.',
              ),

              _buildConnector(),

              _buildStep(
                number: '06',
                icon: Icons.fact_check_outlined,
                title: 'Manage Order Status',
                description:
                    'Update and manage the progress of your selling orders '
                    'through the available order status screens.',
              ),

              _buildConnector(),

              _buildStep(
                number: '07',
                icon: Icons.local_shipping_outlined,
                title: 'Complete the Order',
                description:
                    'Follow the order process until the product is successfully '
                    'delivered to the customer.',
              ),

              const SizedBox(height: 30),

              _buildSectionTitle(
                'Grow Your Artist Profile',
                'Use EcoLoop tools to understand and improve your store.',
              ),

              const SizedBox(height: 14),

              _buildFeatureCard(
                icon: Icons.analytics_outlined,
                title: 'Product Analytics',
                description:
                    'Check product views, wishlist activity and other available '
                    'product performance information.',
              ),

              const SizedBox(height: 12),

              _buildFeatureCard(
                icon: Icons.people_outline_rounded,
                title: 'Followers',
                description:
                    'See users who follow your artist profile and build your '
                    'community around your work.',
              ),

              const SizedBox(height: 12),

              _buildFeatureCard(
                icon: Icons.star_outline_rounded,
                title: 'Customer Reviews',
                description:
                    'Check reviews and ratings given by users to understand '
                    'their experience with your products.',
              ),

              const SizedBox(height: 12),

              _buildFeatureCard(
                icon: Icons.workspace_premium_outlined,
                title: 'Artist Certification',
                description:
                    'Use the certification section to manage your artist '
                    'certificate information and strengthen your profile.',
              ),

              const SizedBox(height: 12),

              _buildFeatureCard(
                icon: Icons.shopping_cart_outlined,
                title: 'Buy Products & Materials',
                description:
                    'Artists can also explore the marketplace and purchase '
                    'products or materials available on EcoLoop.',
              ),

              const SizedBox(height: 28),

              _buildBottomCard(),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // HEADER
  // ===========================================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ArtistColors.primary, ArtistColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        borderRadius: BorderRadius.circular(21),

        boxShadow: [
          BoxShadow(
            color: ArtistColors.primary.withValues(alpha: 0.20),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,

            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(17),
            ),

            child: const Icon(
              Icons.palette_outlined,
              color: Colors.white,
              size: 31,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome, Artist',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  'Create, sell and grow your sustainable products on EcoLoop.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11.5,
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

  // ===========================================================================
  // SECTION TITLE
  // ===========================================================================

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: ArtistTextStyles.title.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: ArtistColors.textPrimary,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          subtitle,
          style: ArtistTextStyles.body.copyWith(
            fontSize: 11,
            color: ArtistColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // STEP CARD
  // ===========================================================================

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
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(17),

        border: Border.all(color: ArtistColors.border),

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
                  color: ArtistColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(14),
                ),

                child: Icon(icon, color: ArtistColors.primary, size: 24),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),

                decoration: BoxDecoration(
                  color: ArtistColors.primary,
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
                  style: ArtistTextStyles.body.copyWith(
                    color: ArtistColors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  description,
                  style: ArtistTextStyles.body.copyWith(
                    color: ArtistColors.textSecondary,
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

  // ===========================================================================
  // CONNECTOR
  // ===========================================================================

  Widget _buildConnector() {
    return Container(
      margin: const EdgeInsets.only(left: 24),
      height: 16,
      width: 1.5,
      color: ArtistColors.border,
    );
  }

  // ===========================================================================
  // FEATURE CARD
  // ===========================================================================

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: ArtistColors.border),
      ),

      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,

            decoration: BoxDecoration(
              color: ArtistColors.surfaceSoft,
              borderRadius: BorderRadius.circular(13),
            ),

            child: Icon(icon, color: ArtistColors.primary, size: 22),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ArtistTextStyles.body.copyWith(
                    color: ArtistColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  description,
                  style: ArtistTextStyles.body.copyWith(
                    color: ArtistColors.textSecondary,
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

  // ===========================================================================
  // BOTTOM CARD
  // ===========================================================================

  Widget _buildBottomCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: ArtistColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: ArtistColors.border),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.auto_awesome_outlined,
            color: ArtistColors.primary,
            size: 27,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              'Build your artist profile, showcase your work, connect with customers and contribute to a more sustainable marketplace.',
              style: ArtistTextStyles.body.copyWith(
                color: ArtistColors.textSecondary,
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
