import 'package:flutter/material.dart';

import '../../app_theme/app_colors.dart';
import '../../app_theme/app_text_styles.dart';
import '../../widgets/back_button.dart';

class AboutEcoLoop extends StatelessWidget {
  const AboutEcoLoop({super.key});

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
                  "About EcoLoop",
                  style: AppTextStyles.heading,
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 10),

              Center(
                child: Text(
                  "Small Actions. Big Impact.",
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 30),

              _sectionTitle("What is EcoLoop?"),

              const SizedBox(height: 10),

              _bodyText(
                "EcoLoop is a sustainability-focused platform designed to give "
                "pre-loved and reusable items a new purpose. It provides a "
                "community where users can buy, sell, donate, and exchange "
                "items instead of simply throwing them away.",
              ),

              const SizedBox(height: 24),

              _sectionTitle("Our Purpose"),

              const SizedBox(height: 10),

              _bodyText(
                "The purpose of EcoLoop is to encourage people to make "
                "sustainable choices in their everyday lives. By extending "
                "the useful life of products and connecting users with "
                "creative artists, EcoLoop helps reduce unnecessary disposal "
                "and promotes reuse.",
              ),

              const SizedBox(height: 24),

              _sectionTitle("Connecting Users and Artists"),

              const SizedBox(height: 10),

              _bodyText(
                "EcoLoop brings users and artists together in one platform. "
                "Users can provide reusable items, while artists can use "
                "their creativity and skills to transform materials into "
                "new and valuable products.",
              ),

              const SizedBox(height: 24),

              _sectionTitle("Why the Name EcoLoop?"),

              const SizedBox(height: 10),

              _bodyText(
                "The word 'Eco' represents sustainability and responsible "
                "use of resources. 'Loop' represents keeping products and "
                "materials in use for longer instead of allowing them to "
                "become unnecessary waste. Together, EcoLoop represents the "
                "idea of creating a continuous cycle of reuse.",
              ),

              const SizedBox(height: 24),

              _sectionTitle("Our Tagline"),

              const SizedBox(height: 10),

              _infoCard(
                icon: Icons.eco_outlined,
                title: "Small Actions. Big Impact.",
                description:
                    "EcoLoop believes that small sustainable choices made "
                    "by individuals can create a meaningful collective impact "
                    "on the environment and society.",
              ),

              const SizedBox(height: 24),

              _sectionTitle("Our Vision"),

              const SizedBox(height: 10),

              _bodyText(
                "To build a community where reuse, creativity, and "
                "sustainability become a natural part of everyday life.",
              ),

              const SizedBox(height: 24),

              _sectionTitle("Our Mission"),

              const SizedBox(height: 10),

              _bodyText(
                "EcoLoop aims to encourage responsible consumption, support "
                "creative reuse, connect users with artists, and provide a "
                "platform that makes sustainable participation simple and "
                "accessible.",
              ),

              const SizedBox(height: 35),

              Center(
                child: Text(
                  "EcoLoop",
                  style: AppTextStyles.title.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 5),

              Center(
                child: Text(
                  "Small Actions. Big Impact.",
                  style: AppTextStyles.caption,
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.title.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _bodyText(String text) {
    return Text(
      text,
      style: AppTextStyles.body.copyWith(
        height: 1.6,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: AppTextStyles.caption.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
