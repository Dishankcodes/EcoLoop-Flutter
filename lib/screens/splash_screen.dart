import 'dart:async';

import 'package:flutter/material.dart';

import '../app_theme/app_text_styles.dart';
import '../shared_preferences_util.dart';
import 'artist/artist_dashboard.dart';
import 'onboarding_screens/onboarding1.dart';
import 'user/user_main.dart';
import 'welcome_screen.dart';

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
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(
      begin: 0.90,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    Timer(const Duration(seconds: 3), _checkLoginStatus);
  }

  void _checkLoginStatus() {
    if (!mounted) return;

    final bool isFirstTime = Prefs.getBool('isFirstTime', defaultValue: true);
    final bool isLoggedIn = Prefs.getBool('isLoggedIn', defaultValue: false);
    final String userRole = Prefs.getString('userRole', defaultValue: 'user');

    if (isFirstTime) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    } else if (isLoggedIn) {
      if (userRole == 'artist') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ArtistDashboard()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const UserMain()),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    }
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
            Align(
              alignment: Alignment.bottomCenter,
              child: Image.asset(
                "assets/images/splash_bottom.png",
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            SafeArea(
              child: Center(
                child: Transform.translate(
                  offset: const Offset(0, -15),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            "assets/logo/ecoloop_logo.png",
                            width: (MediaQuery.of(context).size.width * 0.48)
                                .clamp(175.0, 230.0),
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 20),
                          Text("EcoLoop", style: AppTextStyles.heading),
                          const SizedBox(height: 12),
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
            ),
          ],
        ),
      ),
    );
  }
}
