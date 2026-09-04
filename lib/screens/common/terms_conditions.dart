import 'package:flutter/material.dart';

import '../../app_theme/app_colors.dart';

class TermsConditions extends StatelessWidget {
  const TermsConditions({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 35),
        child: Column(
          children: [
            _buildIntro(),
            _section(
              '1. About EcoLoop',
              'EcoLoop is a community marketplace that allows users '
                  'to list, discover, purchase and donate items. '
                  'EcoLoop provides the platform and related services '
                  'but does not own every item listed by users.',
            ),
            _section(
              '2. User Accounts',
              'Users are responsible for providing accurate account '
                  'information and keeping their login credentials secure. '
                  'You are responsible for activity performed through your account.',
            ),
            _section(
              '3. Listings',
              'Users must provide accurate information about products, '
                  'including condition, category, description and price. '
                  'Listings must not contain prohibited, illegal or misleading items.',
            ),
            _section(
              '4. Buying & Selling',
              'Buyers should review product information carefully before '
                  'placing an order. Sellers are responsible for ensuring '
                  'that listed items match their descriptions.',
            ),
            _section(
              '5. Payments',
              'Payment functionality may be provided through supported '
                  'payment providers. Payment processing, refunds and '
                  'transaction handling may be subject to additional terms.',
            ),
            _section(
              '6. Donations',
              'Users may submit eligible items for donation. Pickup and '
                  'reward eligibility may depend on location, item condition '
                  'and EcoLoop donation policies.',
            ),
            _section(
              '7. Prohibited Activity',
              'Users must not use EcoLoop for illegal activity, fraud, '
                  'harassment, abuse, misleading listings, unauthorized '
                  'transactions or activities that may harm other users.',
            ),
            _section(
              '8. User Safety',
              'Users should use caution when communicating with other '
                  'members. Do not share passwords, OTPs or sensitive '
                  'financial information with other users.',
            ),
            _section(
              '9. Listing Removal',
              'EcoLoop may remove or restrict listings that violate '
                  'platform rules, applicable laws or community standards.',
            ),
            _section(
              '10. Orders & Cancellations',
              'Orders are subject to availability and applicable '
                  'cancellation policies. Cancellation options may vary '
                  'depending on the current order status.',
            ),
            _section(
              '11. Platform Availability',
              'EcoLoop may occasionally experience maintenance, updates '
                  'or temporary service interruptions. Features may also '
                  'change as the platform evolves.',
            ),
            _section(
              '12. Changes to These Terms',
              'EcoLoop may update these terms from time to time. '
                  'Continued use of the platform after an update may '
                  'constitute acceptance of the revised terms.',
            ),
            _section(
              '13. Contact',
              'If you have questions about these terms, please contact '
                  'EcoLoop through the Help & Support section of the application.',
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.light,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.description_outlined,
              color: AppColors.primary,
              size: 24,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Please read these terms carefully.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'These terms describe the basic rules for using EcoLoop.',
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.4,
                      color: AppColors.textSecondary,
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

  Widget _section(String title, String content) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            content,
            style: const TextStyle(
              fontSize: 11,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        children: [
          Icon(Icons.eco_outlined, color: AppColors.primary, size: 25),
          SizedBox(height: 7),
          Text(
            'EcoLoop',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 3),
          Text(
            'Give unused things a new life.',
            style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
          SizedBox(height: 5),
          Text(
            'Last updated: September 2026',
            style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
