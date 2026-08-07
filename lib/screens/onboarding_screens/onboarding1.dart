import 'package:flutter/material.dart';
import '../../app_theme/app_colors.dart';
import '../../app_theme/app_text_styles.dart';
import '../../screens/onboarding_screens/onboarding2.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 60),

            Image.asset(
              'assets/logo/ecoloop_logo.png',
              height: 300,
            ),

            const SizedBox(height: 40),

            Text(
              "Welcome to EcoLoop",
              style: AppTextStyles.heading,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 10),

            Text(
              "Turn waste into creativity. Connect with artists and build a sustainable future.",
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OnboardingScreen2(),
                  ),
                );
              },
              child: const Text("Next"),
            ),

            const SizedBox(height: 20),

            TextButton(
              onPressed: () {
                // TODO: Navigate to Login Screen
              },
              child: const Text("Skip"),
            ),
          ],
        ),
      ),
    );
  }
}