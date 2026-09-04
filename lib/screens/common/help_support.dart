import 'package:flutter/material.dart';

import '../../app_theme/app_colors.dart';

class HelpSupport extends StatelessWidget {
  const HelpSupport({super.key});

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
        padding: const EdgeInsets.only(bottom: 30),
        child: Column(
          children: [
            _buildHeader(),
            _buildQuickHelp(),
            _buildTopics(),
            _buildContact(),
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
                    'Find answers or contact the EcoLoop support team.',
                    style: TextStyle(
                      fontSize: 11,
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

  Widget _buildQuickHelp() {
    return _section(
      title: 'Quick Help',
      child: Row(
        children: [
          Expanded(
            child: _quickCard(
              Icons.help_outline_rounded,
              'FAQ',
              'Common questions',
              () {
                _message('FAQ page is already available.');
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _quickCard(
              Icons.report_problem_outlined,
              'Report',
              'Report an issue',
              () {
                _message('Report flow will be connected later.');
              },
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
          border: Border.all(color: AppColors.accent.withOpacity(0.35)),
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
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopics() {
    return _section(
      title: 'Support Topics',
      child: Column(
        children: [
          _topic(
            Icons.shopping_bag_outlined,
            'Buying an Item',
            'Questions about purchases and orders.',
          ),
          _topic(
            Icons.sell_outlined,
            'Selling an Item',
            'Help with listings, buyers and sales.',
          ),
          _topic(
            Icons.volunteer_activism_outlined,
            'Donating an Item',
            'Questions about donations and pickup.',
          ),
          _topic(
            Icons.local_shipping_outlined,
            'Delivery & Orders',
            'Get help with your order and delivery.',
          ),
          _topic(
            Icons.account_circle_outlined,
            'Account & Profile',
            'Manage your account and preferences.',
          ),
          _topic(
            Icons.security_outlined,
            'Safety & Privacy',
            'Learn about staying safe on EcoLoop.',
          ),
        ],
      ),
    );
  }

  Widget _topic(IconData icon, String title, String subtitle) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 3),
      leading: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: AppColors.light,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primary, size: 21),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: AppColors.textSecondary,
      ),
      onTap: () {
        _message('$title support will be connected later.');
      },
    );
  }

  Widget _buildContact() {
    return _section(
      title: 'Contact EcoLoop',
      child: Column(
        children: [
          _contactTile(
            Icons.email_outlined,
            'Email Support',
            'support@ecoloop.example',
            () {
              _message('Email support will be connected later.');
            },
          ),
          const SizedBox(height: 9),
          _contactTile(
            Icons.chat_bubble_outline_rounded,
            'Live Chat',
            'Chat with our support team',
            () {
              _message('Live chat will be connected later.');
            },
          ),
        ],
      ),
    );
  }

  Widget _contactTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: AppColors.textSecondary,
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.light.withOpacity(0.65),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.shield_outlined, color: AppColors.primary, size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Never share your password, OTP or sensitive financial '
                'information with another user. If something feels suspicious, '
                'report it to EcoLoop support.',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.5,
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

  void _message(String message) {
    // UI-only for now.
  }
}
