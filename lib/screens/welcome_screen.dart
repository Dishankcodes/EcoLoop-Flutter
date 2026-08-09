import 'package:flutter/material.dart';

import '../../app_theme/app_colors.dart';
import '../../app_theme/app_text_styles.dart';

import 'user/login.dart';
import 'user/register.dart';
import 'artist/artist_intro.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight;
            final screenWidth = constraints.maxWidth;
            final logoSize = (screenHeight * 0.24).clamp(170.0, 220.0);
            final horizontalPadding = screenWidth < 360 ? 20.0 : 24.0;
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),

              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,

                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 16,
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,

                      children: [
                        SizedBox(height: screenHeight < 700 ? 8 : 20),

                        Image.asset(
                          "assets/logo/ecoloop_logo.png",
                          width: logoSize,
                          height: logoSize,
                          fit: BoxFit.contain,
                        ),

                        SizedBox(height: screenHeight < 700 ? 12 : 18),

                        Text(
                          "EcoLoop",
                          style: AppTextStyles.heading.copyWith(
                            fontSize: screenWidth < 360 ? 24 : 26,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          "Small Actions.\nBig Impact.",
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body,
                        ),

                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const UserLogin(title: "User Login"),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,

                              minimumSize: Size.zero,
                              padding: EdgeInsets.zero,

                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              "Login",
                              style: AppTextStyles.button.copyWith(
                                fontSize: screenWidth < 360 ? 16 : 18,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterPage(
                                    title: "Create Account",
                                  ),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              minimumSize: Size.zero,
                              padding: EdgeInsets.zero,

                              side: const BorderSide(
                                color: Colors.black,
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              "Create Account",
                              style: AppTextStyles.title.copyWith(
                                fontSize: screenWidth < 360 ? 17 : 18,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: screenHeight < 700 ? 28 : 38),
                        Text(
                          "Become an Artist",
                          textAlign: TextAlign.center,
                          style: AppTextStyles.title.copyWith(
                            fontSize: screenWidth < 360 ? 18 : 20,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Discover your creativity",
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary.withOpacity(0.65),
                            fontSize: screenWidth < 360 ? 14 : 15,
                          ),
                        ),

                        const SizedBox(height: 10),

                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ArtistIntro(),
                              ),
                            );
                          },

                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.arrow_forward, size: 20),
                          label: Text(
                            "Get Started",
                            style: AppTextStyles.body.copyWith(
                              fontSize: screenWidth < 360 ? 15 : 16,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight < 700 ? 8 : 12),
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
  }
}
