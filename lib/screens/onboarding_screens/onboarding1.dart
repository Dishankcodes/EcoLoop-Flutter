import 'package:flutter/material.dart';

import '../../widgets/onboarding_widget.dart';
import 'onboarding2.dart';
import '../welcome_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingWidget(
      image: "assets/logo/onboarding1.png",
      title: "Buy, Sell, Donate\n& Exchange",
      description:
          "Give pre-loved items a new life by buying, selling, donating, or exchanging with the EcoLoop community.",
      currentPage: 0,
      showBackButton: false,
      onNext: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingScreen2()),
        );
      },

      onSkip: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        );
      },
    );
  }
}
