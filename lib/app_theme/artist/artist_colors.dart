import 'package:flutter/material.dart';

class ArtistColors {
  ArtistColors._();

  // Primary Palette
  static const Color primary = Color(0xFF832035); // Maroon
  static const Color secondary = Color(0xFF08271F); // Deep Forest Green
  static const Color accent = Color(0xFFC1C8C4); // Soft Sage
  static const Color light = Color(0xFFF0F1EF); // Light accent background

  // Backgrounds
  static const Color background = Color(0xFFFAF9F7); // Warm Ivory
  static const Color surface =
      Colors.white; // Cards / input fields / elevated surfaces
  static const Color surfaceSoft = Color(0xFFF4F1EF); // Soft secondary surface

  // Text
  static const Color textPrimary = Color(0xFF211C1C); // Main text
  static const Color textSecondary = Color(0xFF4F4848); // Secondary text
  static const Color textMuted = Color(0xFF756D6D); // Muted text

  // Borders
  static const Color border = Color(0xFFE5E1DF);

  // Status Colors
  static const Color success = Color(0xFF2F6B4F);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFF9A6A24);
  static const Color info = Color(0xFF496B70);
}
