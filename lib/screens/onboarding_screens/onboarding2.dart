import 'package:flutter/material.dart';

import '../../widgets/onboarding_widget.dart';
import 'onboarding1.dart';
import '../welcome_screen.dart';

class OnboardingScreen2 extends StatelessWidget {
  const OnboardingScreen2({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingWidget(
      image: "assets/logo/onboarding2.png",
      title: "Small Actions.\nBig Impact.",
      description:
          "Together, we can build a greener tomorrow through simple everyday sustainable choices.",
      currentPage: 1,
      showBackButton: true,

      onBack: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      },

      onNext: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
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
