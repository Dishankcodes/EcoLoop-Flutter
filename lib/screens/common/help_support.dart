import 'package:flutter/material.dart';

import '../../app_theme/app_colors.dart';
import '../../app_theme/app_text_styles.dart';
import '../../widgets/back_button.dart';
import 'faq.dart';

class HelpSupport extends StatelessWidget {
  const HelpSupport({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppBackButton(),

              const SizedBox(height: 20),

              Center(
                child: Text(
                  "Help & Support",
                  style: AppTextStyles.heading,
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 10),

              Center(
                child: Text(
                  "We're here to help you use EcoLoop.",
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 30),

              _supportCard(
                icon: Icons.help_outline,
                title: "Frequently Asked Questions",
                description:
                    "Find quick answers to common questions about accounts, "
                    "items, orders, artists, and EcoLoop features.",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FAQPage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),

              _supportCard(
                icon: Icons.report_problem_outlined,
                title: "Report a Problem",
                description:
                    "If you experience an issue while using EcoLoop, "
                    "you can report it to our support team.",
                onTap: () {
                  _showMessage(
                    context,
                    "Problem reporting will be available soon.",
                  );
                },
              ),

              const SizedBox(height: 14),

              _supportCard(
                icon: Icons.shopping_bag_outlined,
                title: "Order Support",
                description:
                    "Need help with an order, delivery, tracking, or "
                    "another marketplace-related issue?",
                onTap: () {
                  _showMessage(
                    context,
                    "Order support will be available soon.",
                  );
                },
              ),

              const SizedBox(height: 14),

              _supportCard(
                icon: Icons.person_outline,
                title: "Account Support",
                description:
                    "Get assistance with your account, login, registration, "
                    "profile, or account settings.",
                onTap: () {
                  _showMessage(
                    context,
                    "Account support will be available soon.",
                  );
                },
              ),

              const SizedBox(height: 30),

              _sectionTitle("Before contacting support"),

              const SizedBox(height: 12),

              _bullet("Check the FAQ section for quick answers."),
              _bullet("Make sure your application is updated."),
              _bullet("Clearly describe the issue you are experiencing."),
              _bullet(
                "Include relevant order or account information when required.",
              ),

              const SizedBox(height: 30),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.support_agent,
                      size: 40,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Need more help?",
                      style: AppTextStyles.title.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Our support features will be expanded as EcoLoop continues to grow.",
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(height: 1.5),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _supportCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: AppTextStyles.caption.copyWith(height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: AppTextStyles.body.copyWith(height: 1.4)),
          ),
        ],
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class FAQPagePlaceholder extends StatelessWidget {
  const FAQPagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: const Center(child: Text("FAQ")),
    );
  }
}
