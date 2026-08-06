import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'app_theme/app_theme.dart';


void main() {
  runApp(const EcoLoopApp());
}

class EcoLoopApp extends StatelessWidget {
  const EcoLoopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoLoop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
