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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ------------------------------------------------
              // TOP BAR
              // ------------------------------------------------
              SizedBox(
                height: 48,
                width: double.infinity,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: showBackButton
                      ? IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new),
                          onPressed: onBack,
                        )
                      : const SizedBox.shrink(),
                ),
              ),

              const SizedBox(height: 15),

              // ------------------------------------------------
              // ILLUSTRATION
              // ------------------------------------------------
              SizedBox(
                width: double.infinity,
                child: Image.asset(image, height: 300, fit: BoxFit.contain),
              ),

              const SizedBox(height: 35),

              // ------------------------------------------------
              // TITLE
              // ------------------------------------------------
              SizedBox(
                width: double.infinity,
                child: Text(
                  title,
                  style: AppTextStyles.heading,
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 12),

              // ------------------------------------------------
              // DESCRIPTION
              // ------------------------------------------------
              SizedBox(
                width: double.infinity,
                child: Text(
                  description,
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 35),

              // ------------------------------------------------
              // PAGE INDICATOR
              // ------------------------------------------------
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

              // ------------------------------------------------
              // BOTTOM BUTTONS
              // ------------------------------------------------
              Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: onSkip,
                        child: const Text(
                          "Skip",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
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
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
