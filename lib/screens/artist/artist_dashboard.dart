import 'package:flutter/material.dart';

import '../../app_theme/app_colors.dart';
import '../../app_theme/app_text_styles.dart';

class ArtistDashboard extends StatelessWidget {
  const ArtistDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text("EcoLoop", style: AppTextStyles.heading),
      ),
      body: Center(
        child: Text(
          "Welcome to your Dashboard!",
          style: AppTextStyles.heading,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
