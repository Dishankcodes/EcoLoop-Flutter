import 'dart:async';

import 'package:flutter/material.dart';

import '../app_theme/app_colors.dart';
import '../app_theme/app_text_styles.dart';
import 'onboarding_screens/onboarding1.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(
      begin: 0.90,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    Timer(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,

        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,

            colors: [Color(0xffFCFEFC), Color(0xffF2FBF2), Color(0xffE8F8E8)],
          ),
        ),

        child: Stack(
          children: [
            /// Bottom Illustration
            Align(
              alignment: Alignment.bottomCenter,

              child: Image.asset(
                "assets/images/splash_bottom.png",

                width: double.infinity,

                fit: BoxFit.cover,
              ),
            ),

            /// Center Content
            SafeArea(
              child: Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,

                  child: ScaleTransition(
                    scale: _scaleAnimation,

                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [
                        /// Logo
                        Image.asset(
                          "assets/logo/ecoloop_logo.png",
                          height: 120,
                        ),

                        const SizedBox(height: 30),

                        /// App Name
                        Text("EcoLoop", style: AppTextStyles.heading),

                        const SizedBox(height: 12),

                        /// Tagline
                        Text(
                          "Small Actions.\nBig Impact.",
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
