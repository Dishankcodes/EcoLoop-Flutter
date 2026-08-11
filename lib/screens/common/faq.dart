import 'package:flutter/material.dart';

import '../../app_theme/app_colors.dart';
import '../../app_theme/app_text_styles.dart';
import '../../widgets/back_button.dart';

class FAQPage extends StatelessWidget {
  const FAQPage({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {
        "question": "What is EcoLoop?",
        "answer":
            "EcoLoop is a platform that encourages reuse and sustainable choices by allowing users to buy, sell, donate, and exchange reusable items while connecting them with artists who can transform materials into creative products.",
      },
      {
        "question": "What can I do as a user?",
        "answer":
            "Users can explore items, buy products, sell reusable items, donate items, exchange items, create wishlists, follow artists, track orders, and manage their profile and listings.",
      },
      {
        "question": "Who is an artist on EcoLoop?",
        "answer":
            "An artist is a creative individual who can use reusable materials to create or transform products and offer those products through the EcoLoop marketplace.",
      },
      {
        "question": "Can I become an artist?",
        "answer":
            "Yes. Users who want to showcase their creativity can create an artist account and use the artist features provided by EcoLoop.",
      },
      {
        "question": "Can I sell my items?",
        "answer":
            "Yes. Users can upload reusable items and create listings so that other members of the EcoLoop community can discover them.",
      },
      {
        "question": "Can I donate an item?",
        "answer":
            "Yes. EcoLoop provides a donation option for users who want to give reusable items instead of selling them.",
      },
      {
        "question": "Can I follow an artist?",
        "answer":
            "Yes. Users can follow artists to keep up with their products and creative work.",
      },
      {
        "question": "Can I track my order?",
        "answer":
            "Yes. Order tracking allows users to view the progress of their orders after placing a purchase.",
      },
      {
        "question": "Does EcoLoop support custom orders?",
        "answer":
            "Artists can receive custom order requests, allowing users to request products based on their requirements.",
      },
      {
        "question": "How does EcoLoop promote sustainability?",
        "answer":
            "EcoLoop promotes sustainability by encouraging reuse, donation, exchange, creative transformation, and longer product lifecycles.",
      },
      {
        "question": "Is my information safe?",
        "answer":
            "EcoLoop is designed with user privacy and responsible handling of account information in mind. Actual security and data protection policies will depend on the implemented backend and security system.",
      },
      {
        "question": "Can I change my account settings?",
        "answer":
            "Yes. Users and artists can access settings to manage available account and application preferences.",
      },
    ];

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
                  "Frequently Asked Questions",
                  style: AppTextStyles.heading,
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 10),

              Center(
                child: Text(
                  "Find answers to common questions about EcoLoop.",
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 30),

              ...faqs.map(
                (faq) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      iconColor: AppColors.primary,
                      collapsedIconColor: AppColors.textSecondary,
                      title: Text(
                        faq["question"]!,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            faq["answer"]!,
                            style: AppTextStyles.caption.copyWith(height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
