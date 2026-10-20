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
        foregroundColor: ArtistColors.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        title: Text(
          'How It Works',
          style: ArtistTextStyles.title.copyWith(
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
              _header(),
              const SizedBox(height: 26),
              _sectionTitle(
                'Set Up Your ReMaker Profile',
                'Introduce yourself and showcase your skills.',
              ),
              const SizedBox(height: 14),
              _step(
                number: '01',
                icon: Icons.person_outline_rounded,
                title: 'Complete Your Profile',
                description:
                    'Add your profile information, bio, skills and the '
                    'details you want customers to see. Public profile '
                    'information may be visible to other users.',
              ),
              _connector(),
              _step(
                number: '02',
                icon: Icons.collections_bookmark_outlined,
                title: 'Showcase Your Portfolio',
                description:
                    'Add project stories, before-and-after images, reused '
                    'materials and transformation details. Only upload '
                    'content you have permission to share.',
              ),
              _connector(),
              _step(
                number: '03',
                icon: Icons.workspace_premium_outlined,
                title: 'Manage Certificates',
                description:
                    'Use the certificate features available in your account '
                    'to submit or manage certificate information. Approval '
                    'and public display depend on the actual review process.',
              ),
              const SizedBox(height: 28),
              _sectionTitle(
                'List and Sell Products',
                'Create accurate listings and manage your stock.',
              ),
              const SizedBox(height: 14),
              _step(
                number: '04',
                icon: Icons.add_box_outlined,
                title: 'Add Your Products',
                description:
                    'Provide product photos, name, category, price, stock '
                    'quantity, condition and description where requested.',
              ),
              _connector(),
              _step(
                number: '05',
                icon: Icons.storefront_outlined,
                title: 'Publish Your Listing',
                description:
                    'Published listings can appear in the marketplace for '
                    'customers to discover. Keep prices, descriptions and '
                    'availability up to date.',
              ),
              _connector(),
              _step(
                number: '06',
                icon: Icons.inventory_2_outlined,
                title: 'Manage Your Products',
                description:
                    'Use My Products to review your listings and make '
                    'changes through the editing options available in '
                    'your account.',
              ),
              const SizedBox(height: 28),
              _sectionTitle(
                'Manage Customer Orders',
                'Follow the order workflow shown in the app.',
              ),
              const SizedBox(height: 14),
              _step(
                number: '07',
                icon: Icons.shopping_bag_outlined,
                title: 'Review New Orders',
                description:
                    'Open Selling Orders to view order information. Use '
                    'customer contact and delivery information only for '
                    'the relevant transaction.',
              ),
              _connector(),
              _step(
                number: '08',
                icon: Icons.fact_check_outlined,
                title: 'Update Order Progress',
                description:
                    'Use the available order-status actions and make sure '
                    'the selected status accurately reflects the real '
                    'progress of the order.',
              ),
              _connector(),
              _step(
                number: '09',
                icon: Icons.local_shipping_outlined,
                title: 'Complete Fulfilment',
                description:
                    'Follow the agreed delivery or collection arrangement. '
                    'Current payment arrangements are COD and/or offline; '
                    'online payment gateway processing is not active.',
              ),
              const SizedBox(height: 28),
              _sectionTitle(
                'Grow Your ReMaker Community',
                'Use the available profile and engagement features.',
              ),
              const SizedBox(height: 14),
              _feature(
                Icons.analytics_outlined,
                'Analytics',
                'Review the product or account statistics displayed in '
                    'your dashboard. Figures may depend on available data.',
              ),
              const SizedBox(height: 12),
              _feature(
                Icons.people_outline_rounded,
                'Followers',
                'View available follower information and connect with '
                    'people interested in your public profile.',
              ),
              const SizedBox(height: 12),
              _feature(
                Icons.star_outline_rounded,
                'Customer Reviews',
                'Review feedback displayed for your products or profile. '
                    'Reviews should be genuine and must not be manipulated.',
              ),
              const SizedBox(height: 12),
              _feature(
                Icons.shopping_cart_outlined,
                'Buy Products and Materials',
                'ReMakers can also browse the marketplace and purchase '
                    'available products from other participating sellers.',
              ),
              const SizedBox(height: 28),
              _sectionTitle(
                'Custom Services',
                'Discuss project requirements clearly before beginning work.',
              ),
              const SizedBox(height: 14),
              _step(
                number: '10',
                icon: Icons.design_services_outlined,
                title: 'Review a Project Request',
                description:
                    'Where custom-service requests are available, review '
                    'the customer’s brief, budget and reference materials.',
              ),
              _connector(),
              _step(
                number: '11',
                icon: Icons.handshake_outlined,
                title: 'Submit a Proposal',
                description:
                    'Clearly state the proposed scope, price, deliverables, '
                    'timeline, revisions and delivery or collection plan.',
              ),
              _connector(),
              _step(
                number: '12',
                icon: Icons.check_circle_outline_rounded,
                title: 'Complete the Agreed Work',
                description:
                    'Follow the agreed project requirements and use the '
                    'available status and acceptance actions. Refund, '
                    'cancellation and ownership rules require separate '
                    'confirmation where not already agreed.',
              ),
              const SizedBox(height: 26),
              _supportCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
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
            color: ArtistColors.primary.withValues(alpha: 0.16),
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
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.auto_awesome_outlined,
              color: Colors.white,
              size: 29,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your ReMaker Journey',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Create, list, connect and give useful materials a new life.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.5,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: ArtistTextStyles.title.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: ArtistTextStyles.caption.copyWith(height: 1.5)),
      ],
    );
  }

  Widget _step({
    required String number,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: ArtistColors.surfaceSoft,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: ArtistColors.primary, size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: ArtistColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        number,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        title,
                        style: ArtistTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  description,
                  style: ArtistTextStyles.body.copyWith(
                    fontSize: 12,
                    height: 1.55,
                    color: ArtistColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _connector() {
    return Padding(
      padding: const EdgeInsets.only(left: 36, top: 5, bottom: 5),
      child: Container(width: 2, height: 15, color: ArtistColors.border),
    );
  }

  Widget _feature(IconData icon, String title, String description) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: ArtistColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ArtistTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: ArtistTextStyles.body.copyWith(
                    fontSize: 12,
                    height: 1.55,
                    color: ArtistColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _supportCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.support_agent_rounded,
            color: ArtistColors.primary,
            size: 30,
          ),
          const SizedBox(height: 10),
          Text(
            'Need Help?',
            style: ArtistTextStyles.title.copyWith(fontSize: 17),
          ),
          const SizedBox(height: 6),
          Text(
            'For questions about your ReMaker account, products, orders or '
            'custom-service requests, contact EcoLoop support.',
            textAlign: TextAlign.center,
            style: ArtistTextStyles.body.copyWith(
              fontSize: 12,
              height: 1.55,
              color: ArtistColors.textSecondary,
            ),
          ),
          const SizedBox(height: 9),
          const SelectableText(
            'ecoloopp2026@gmail.com',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ArtistColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
