import 'package:flutter/material.dart';

import '../../shared_preferences_util.dart';
import '../../widgets/onboarding_widget.dart';
import '../welcome_screen.dart';
import 'onboarding1.dart';

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
      onNext: () async {
        await Prefs.setBool('isFirstTime', false);

        if (!context.mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
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
