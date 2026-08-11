import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Heading (used in splash / big titles)
  static final TextStyle heading = GoogleFonts.poppins(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 0.2,
  );


  // Section Titles
  static final TextStyle title = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Body text
  static final TextStyle body = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // Small / caption text
  static final TextStyle caption = GoogleFonts.poppins(
    fontSize: 12,
    color: AppColors.textSecondary.withOpacity(0.8),
  );

  // Input hint text
  static final TextStyle hint = GoogleFonts.poppins(
    fontSize: 14,
    color: AppColors.textSecondary.withOpacity(0.6),
  );

  // Button text
  static final TextStyle button = GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.3,
  );
}