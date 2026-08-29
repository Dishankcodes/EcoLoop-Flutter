import 'package:flutter/material.dart';

import '../../shared_preferences_util.dart';
import '../../widgets/onboarding_widget.dart';
import '../welcome_screen.dart';
import 'onboarding2.dart';

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
      onSkip: () async {
        await Prefs.setBool('isFirstTime', false);

        if (!context.mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        );
      },
    );
  }
}
