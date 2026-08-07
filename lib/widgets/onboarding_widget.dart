import 'package:flutter/material.dart';

import '../app_theme/app_colors.dart';
import '../app_theme/app_text_styles.dart';

class OnboardingWidget extends StatelessWidget {
  final String image;
  final String title;
  final String description;

  final bool showBackButton;
  final int currentPage;

  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback? onBack;

  const OnboardingWidget({
    super.key,
    required this.image,
    required this.title,
    required this.description,
    required this.currentPage,
    required this.onNext,
    required this.onSkip,
    this.onBack,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                /// Top Bar
                Align(
                  alignment: Alignment.centerLeft,
                  child: showBackButton
                      ? IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new),
                          onPressed: onBack,
                        )
                      : const SizedBox(height: 48),
                ),

                const SizedBox(height: 15),

                /// Illustration
                Image.asset(image, height: 300, fit: BoxFit.contain),

                const SizedBox(height: 35),

                /// Title
                Text(
                  title,
                  style: AppTextStyles.heading,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                /// Description
                Text(
                  description,
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 35),

                /// Page Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: 8,
                      width: 8,
                      decoration: BoxDecoration(
                        color: currentPage == 0
                            ? AppColors.primary
                            : Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                    ),

                    const SizedBox(width: 8),

                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: 8,
                      width: 8,
                      decoration: BoxDecoration(
                        color: currentPage == 1
                            ? AppColors.primary
                            : Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 45),

                /// Bottom Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: onSkip,
                      child: const Text("Skip", style: TextStyle(fontSize: 16)),
                    ),

                    ElevatedButton(
                      onPressed: onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Next",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
