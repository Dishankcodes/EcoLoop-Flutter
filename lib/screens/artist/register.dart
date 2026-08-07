import 'package:flutter/material.dart';
import '../../app_theme/app_colors.dart';
import '../../app_theme/app_text_styles.dart';

class ArtistRegistrationScreen extends StatelessWidget {
  const ArtistRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Artist Registration"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            // 🌿 Profile Upload
            Center(
              child: Stack(
                children: [
                  Container(
                    height: 90,
                    width: 90,
                    decoration: BoxDecoration(
                      color: AppColors.light,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.grey,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            Text(
              "Tell us about yourself",
              style: AppTextStyles.title,
            ),

            const SizedBox(height: 20),

            _buildField("Artist Name"),
            _buildField("Skills (e.g. Painting, Upcycling)"),
            _buildField("City"),
            _buildField("Portfolio Description", maxLines: 3),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () {},
              child: const Text("Next"),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String hint, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
        ),
      ),
    );
  }
}