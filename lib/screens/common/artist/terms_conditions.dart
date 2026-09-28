import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';

class ArtistTermsConditions extends StatelessWidget {
  const ArtistTermsConditions({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtistColors.background,

      appBar: AppBar(
        backgroundColor: ArtistColors.surface,
        foregroundColor: ArtistColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Terms & Conditions',
          style: ArtistTextStyles.title.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: ArtistColors.textPrimary,
          ),
        ),
      ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 35),
        child: Column(
          children: [
            _buildIntro(),

            _section(
              '1. About EcoLoop',
              'EcoLoop is a community marketplace that allows users '
                  'and artists to list, discover, purchase and donate items. '
                  'EcoLoop provides the platform and related services '
                  'but does not own every item listed by users or artists.',
            ),

            _section(
              '2. Artist Accounts',
              'Artists are responsible for providing accurate account '
                  'and profile information and keeping their login credentials '
                  'secure. Artists are responsible for activity performed '
                  'through their account.',
            ),

            _section(
              '3. Artist Profiles',
              'Artists should provide accurate information about their '
                  'profile, including name, bio, skills and location. '
                  'Profile information should represent the artist accurately '
                  'and should not contain misleading information.',
            ),

            _section(
              '4. Product Listings',
              'Artists must provide accurate information about products, '
                  'including product images, condition, category, description, '
                  'stock and price. Products must not contain prohibited, '
                  'illegal or misleading items.',
            ),

            _section(
              '5. Buying & Selling',
              'Artists may sell products through the marketplace and may '
                  'also purchase products from users or other artists. '
                  'Sellers are responsible for ensuring that listed products '
                  'match their descriptions.',
            ),

            _section(
              '6. Product Management',
              'Artists are responsible for keeping their product information '
                  'accurate and up to date. Artists may edit available product '
                  'information and manage their listings through My Products.',
            ),

            _section(
              '7. Orders',
              'When a customer purchases an artist product, the order may '
                  'appear in the artist Selling Orders section. Artists are '
                  'responsible for reviewing order information and managing '
                  'the available order status updates.',
            ),

            _section(
              '8. Payments & Earnings',
              'Payment functionality may be provided through supported '
                  'payment providers. Payment processing, refunds, earnings '
                  'and transaction handling may be subject to additional terms '
                  'and applicable platform policies.',
            ),

            _section(
              '9. Reviews & Ratings',
              'Customers may provide reviews and ratings for purchased '
                  'products. Artists should not manipulate, abuse or misuse '
                  'the review and rating system.',
            ),

            _section(
              '10. Followers & Community',
              'Users may follow artist profiles and interact with the artist '
                  'community. Artists must communicate respectfully and must '
                  'not use the platform for harassment, abuse or misleading activity.',
            ),

            _section(
              '11. Prohibited Activity',
              'Artists must not use EcoLoop for illegal activity, fraud, '
                  'harassment, abuse, misleading listings, unauthorized '
                  'transactions or activities that may harm other users.',
            ),

            _section(
              '12. User Safety',
              'Artists should use caution when communicating with customers '
                  'and other members. Do not share passwords, OTPs or sensitive '
                  'financial information with other users.',
            ),

            _section(
              '13. Listing Removal',
              'EcoLoop may remove or restrict products or listings that violate '
                  'platform rules, applicable laws or community standards.',
            ),

            _section(
              '14. Orders & Cancellations',
              'Orders are subject to product availability and applicable '
                  'cancellation policies. Cancellation options may vary '
                  'depending on the current order status.',
            ),

            _section(
              '15. Platform Availability',
              'EcoLoop may occasionally experience maintenance, updates '
                  'or temporary service interruptions. Features may also '
                  'change as the platform evolves.',
            ),

            _section(
              '16. Changes to These Terms',
              'EcoLoop may update these terms from time to time. '
                  'Continued use of the platform after an update may '
                  'constitute acceptance of the revised terms.',
            ),

            _section(
              '17. Contact',
              'If you have questions about these terms, please contact '
                  'EcoLoop through the Help & Support section of the application.',
            ),

            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // INTRO
  // ===========================================================================

  Widget _buildIntro() {
    return Container(
      width: double.infinity,
      color: ArtistColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ArtistColors.surfaceSoft,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.description_outlined,
              color: ArtistColors.primary,
              size: 24,
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Please read these terms carefully.',
                    style: ArtistTextStyles.body.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: ArtistColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'These terms describe the basic rules for using EcoLoop as an artist.',
                    style: ArtistTextStyles.body.copyWith(
                      fontSize: 10,
                      height: 1.4,
                      color: ArtistColors.textSecondary,
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

  // ===========================================================================
  // SECTION
  // ===========================================================================

  Widget _section(String title, String content) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      color: ArtistColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: ArtistTextStyles.title.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: ArtistColors.textPrimary,
            ),
          ),

          const SizedBox(height: 9),

          Text(
            content,
            style: ArtistTextStyles.body.copyWith(
              fontSize: 11,
              height: 1.6,
              color: ArtistColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // FOOTER
  // ===========================================================================

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        children: [
          const Icon(Icons.eco_outlined, color: ArtistColors.primary, size: 25),

          const SizedBox(height: 7),

          Text(
            'EcoLoop',
            style: ArtistTextStyles.body.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: ArtistColors.primary,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            'Give unused things a new life.',
            style: ArtistTextStyles.body.copyWith(
              fontSize: 10,
              color: ArtistColors.textSecondary,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            'Last updated: September 2026',
            style: ArtistTextStyles.body.copyWith(
              fontSize: 9,
              color: ArtistColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
