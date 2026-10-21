import 'package:flutter/material.dart';

import '../../app_theme/user/app_colors.dart';
import 'ai_chat_screen.dart';
import 'faq.dart';

class HelpSupport extends StatelessWidget {
  const HelpSupport({super.key});

  static const String _supportEmail = 'ecoloopp2026@gmail.com';

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  void _openFaq(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FAQ()));
  }

  void _openAiChat(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AiChatScreen()));
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
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          _buildHeader(),
          _buildAiSupport(context),
          _buildQuickHelp(context),
          _buildTopics(),
          _buildContact(context),
          _buildSafety(),
        ],
      ),
    );
  }

  Widget _buildHeader() => Container(
    width: double.infinity,
    color: AppColors.surface,
    padding: const EdgeInsets.fromLTRB(20, 6, 20, 22),
    child: Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(17),
      ),
      child: const Row(
        children: [
          Icon(Icons.support_agent_rounded, color: AppColors.primary, size: 32),
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
                SizedBox(height: 5),
                Text(
                  'Get help with your account, products, orders, donations and custom services.',
                  style: TextStyle(
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
    ),
  );

  Widget _buildAiSupport(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 15, 18, 7),
    child: Material(
      color: AppColors.light,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openAiChat(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chat with EcoLoop AI',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Ask questions and get guidance around EcoLoop.',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _buildQuickHelp(BuildContext context) => _section(
    title: 'Quick Help',
    subtitle: 'Find an answer or get in touch.',
    child: Row(
      children: [
        Expanded(
          child: _quickCard(
            Icons.quiz_outlined,
            'FAQs',
            'Browse common questions',
            () => _openFaq(context),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: _quickCard(
            Icons.email_outlined,
            'Contact us',
            'Email EcoLoop support',
            () => _showMessage(context, 'Contact us at $_supportEmail'),
          ),
        ),
      ],
    ),
  );

  Widget _quickCard(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) => Material(
    color: AppColors.background,
    borderRadius: BorderRadius.circular(15),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.accent.withValues(alpha: .7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.light,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: AppColors.primary, size: 21),
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
                fontSize: 10.5,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Text(
                  'Open',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
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
          ],
        ),
      ),
    ),
  );

  Widget _buildTopics() => _section(
    title: 'Support Topics',
    subtitle: 'Choose the topic closest to your question.',
    child: Column(
      children: [
        _topic(
          Icons.shopping_bag_outlined,
          'Buying and orders',
          'Checkout, order status and delivery information.',
        ),
        _topic(
          Icons.sell_outlined,
          'Selling and listings',
          'Creating products, images, categories, prices and quantities.',
        ),
        _topic(
          Icons.volunteer_activism_outlined,
          'Donations and pickups',
          'Donation requests, pickup availability and donation status.',
        ),
        _topic(
          Icons.palette_outlined,
          'ReMakers and custom services',
          'Creator profiles, portfolios and custom-project requests.',
        ),
        _topic(
          Icons.star_outline_rounded,
          'Reviews and wishlist',
          'Saved products and feedback based on genuine experiences.',
        ),
        _topic(
          Icons.person_outline_rounded,
          'Account and privacy',
          'Profile details, sign-in problems and privacy questions.',
        ),
      ],
    ),
  );

  Widget _topic(IconData icon, String title, String description) => Padding(
    padding: const EdgeInsets.only(bottom: 17),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.light,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
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
  );

  Widget _buildContact(BuildContext context) => _section(
    title: 'Contact EcoLoop',
    subtitle: 'For issues that need personal assistance.',
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
            Icons.mail_outline_rounded,
            color: AppColors.primary,
            size: 27,
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
            'Describe the issue and include the relevant order or product reference when applicable. Do not include your password or OTP.',
            style: TextStyle(
              fontSize: 11,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 11),
          const SelectableText(
            _supportEmail,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () =>
                _showMessage(context, 'Email address: $_supportEmail'),
            icon: const Icon(Icons.info_outline_rounded, size: 17),
            label: const Text('View contact information'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Formal grievance contact details and response timelines are pending confirmation.',
            style: TextStyle(
              fontSize: 10.5,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildSafety() => _section(
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
              'Never share your password, OTP or sensitive financial information with another user. Verify product details before ordering, keep transaction information accurate, and use customer information only for its intended purpose.',
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

  Widget _section({
    required String title,
    String? subtitle,
    required Widget child,
  }) => Container(
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
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: 15),
        child,
      ],
    ),
  );
}
