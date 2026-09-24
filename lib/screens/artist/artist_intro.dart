import 'package:flutter/material.dart';

import '../../app_theme/artist/artist_colors.dart';
import '../../app_theme/artist/artist_text_styles.dart';
import '../../app_theme/artist/artist_theme.dart';
import '../../widgets/back_button.dart';
import 'auth/login.dart';

class ArtistIntro extends StatelessWidget {
  const ArtistIntro({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ArtistTheme.lightTheme,
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: ArtistColors.background,
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenHeight = constraints.maxHeight;
                  final screenWidth = constraints.maxWidth;
                  final horizontalPadding = screenWidth < 360 ? 18.0 : 20.0;
                  final illustrationHeight = (screenHeight * 0.30).clamp(
                    210.0,
                    270.0,
                  );

                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Back Button
                              const SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: AppBackButton(),
                              ),
                              const SizedBox(height: 8),

                              // Title
                              Text(
                                'Become an Artist',
                                style: ArtistTextStyles.heading.copyWith(
                                  fontSize: screenWidth < 360 ? 24 : 26,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),

                              // Subtitle
                              Text(
                                'Showcase your creativity\n'
                                'and sell your upcycled products.',
                                style: ArtistTextStyles.body,
                                textAlign: TextAlign.center,
                              ),

                              // Illustration
                              SizedBox(
                                height: illustrationHeight,
                                width: double.infinity,
                                child: Image.asset(
                                  'assets/logo/artist_set_3.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Features
                              _buildFeature(
                                icon: Icons.person_outline,
                                text: 'Build your profile',
                              ),
                              const SizedBox(height: 12),
                              _buildFeature(
                                icon: Icons.image_outlined,
                                text: 'Showcase your work',
                              ),
                              const SizedBox(height: 12),
                              _buildFeature(
                                icon: Icons.sell_outlined,
                                text: 'Sell & earn',
                              ),
                              const SizedBox(height: 12),
                              _buildFeature(
                                icon: Icons.bar_chart_outlined,
                                text: 'Track your earnings',
                              ),
                              const SizedBox(height: 12),
                              _buildFeature(
                                icon: Icons.star_outline,
                                text: 'Get customer reviews',
                              ),
                              const Spacer(),

                              // Get Started Button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const ArtistLogin(
                                          title: 'Artist Login',
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ArtistColors.primary,
                                    foregroundColor: Colors.white,
                                    minimumSize: Size.zero,
                                    padding: EdgeInsets.zero,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Get Started',
                                    style: ArtistTextStyles.button.copyWith(
                                      fontSize: screenWidth < 360 ? 15 : 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  // Feature Item
  Widget _buildFeature({required IconData icon, required String text}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ArtistColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 22, color: ArtistColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: ArtistTextStyles.body.copyWith(
                fontSize: 15,
                color: ArtistColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
