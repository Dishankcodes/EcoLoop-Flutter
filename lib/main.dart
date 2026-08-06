import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

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
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
