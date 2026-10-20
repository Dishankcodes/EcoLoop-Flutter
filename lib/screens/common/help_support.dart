import 'package:flutter/material.dart';

import '../../app_theme/user/app_colors.dart';

class HelpSupport extends StatelessWidget {
  const HelpSupport({super.key});

  static const String _supportEmail = 'ecoloopp2026@gmail.com';

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text(
          'Help & Support',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 30),
        child: Column(
          children: [
            _buildHeader(),
            _buildQuickHelp(context),
            _buildTopics(),
            _buildContact(context),
            _buildSafety(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 22),
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: AppColors.light,
          borderRadius: BorderRadius.circular(17),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.support_agent_rounded,
              color: AppColors.primary,
              size: 31,
            ),
            SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How can we help?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Find answers about your account, products, orders '
                    'and donations, or contact EcoLoop by email.',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.5,
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

  Widget _buildQuickHelp(BuildContext context) {
    return _section(
      title: 'Quick Help',
      child: Row(
        children: [
          Expanded(
            child: _quickCard(
              Icons.help_outline_rounded,
              'FAQ',
              'Common questions',
              () => _showMessage(
                context,
                'Open Frequently Asked Questions from the app menu.',
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _quickCard(
              Icons.report_problem_outlined,
              'Report',
              'Report an issue',
              () => _showMessage(
                context,
                'In-app reporting is not confirmed as connected. '
                'Please email $_supportEmail with the issue details.',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickCard(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 37,
              width: 37,
              decoration: BoxDecoration(
                color: AppColors.light,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(height: 11),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopics() {
    const topics = <Map<String, dynamic>>[
      {
        'icon': Icons.shopping_bag_outlined,
        'title': 'Buying and orders',
        'description':
            'Order status, buying orders, checkout details and delivery '
            'information.',
      },
      {
        'icon': Icons.sell_outlined,
        'title': 'Selling and listings',
        'description':
            'Adding products, editing listings, images, categories, '
            'prices and quantities.',
      },
      {
        'icon': Icons.volunteer_activism_outlined,
        'title': 'Donations and pickups',
        'description':
            'Donation requests, eligibility, pickup availability and '
            'donation status.',
      },
      {
        'icon': Icons.palette_outlined,
        'title': 'ReMakers and custom services',
        'description':
            'ReMaker profiles, portfolios and custom-service requests.',
      },
      {
        'icon': Icons.star_outline_rounded,
        'title': 'Reviews and wishlist',
        'description':
            'Reviews based on genuine experiences and products saved '
            'for later.',
      },
      {
        'icon': Icons.person_outline_rounded,
        'title': 'Account and privacy',
        'description':
            'Profile details, account access, privacy questions and '
            'account-closure requests.',
      },
    ];

    return _section(
      title: 'Support Topics',
      child: Column(
        children: topics.map((topic) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: AppColors.light,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    topic['icon'] as IconData,
                    color: AppColors.primary,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic['title'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        topic['description'] as String,
                        style: const TextStyle(
                          fontSize: 10.5,
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
        }).toList(),
      ),
    );
  }

  Widget _buildContact(BuildContext context) {
    return _section(
      title: 'Contact EcoLoop',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.light,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.email_outlined,
              color: AppColors.primary,
              size: 26,
            ),
            const SizedBox(height: 10),
            const Text(
              'Email Support',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Describe your issue and include the relevant order or '
              'product reference, if applicable.',
              style: TextStyle(
                fontSize: 11,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            const SelectableText(
              _supportEmail,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Formal grievance officer details and response timelines '
              'are Pending confirmation.',
              style: TextStyle(
                fontSize: 10,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () =>
                  _showMessage(context, 'Email address: $_supportEmail'),
              icon: const Icon(Icons.info_outline_rounded, size: 17),
              label: const Text('View Contact Information'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafety() {
    return _section(
      title: 'Stay Safe on EcoLoop',
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.light,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.shield_outlined, color: AppColors.primary, size: 25),
            SizedBox(width: 11),
            Expanded(
              child: Text(
                'Never share your password, OTP or sensitive financial '
                'information with another user. Verify product details '
                'before ordering, keep transaction information accurate, '
                'and use customer information only for its intended purpose.',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.55,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(20),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }
}
