import 'package:flutter/material.dart';

class ArtistColors {
  ArtistColors._();

  // Primary Palette
  static const Color primary = Color(0xFFA6533C); // Terracotta - Main brand color
  static const Color secondary = Color(0xFFD98B73); // Burnt Peach - Secondary brand color
  static const Color accent = Color(0xFF7F3F32); // Deep Terracotta - Dark accent
  static const Color light = Color(0xFFE8B5A3); // Soft Peach - Light accent background

  // Backgrounds
  static const Color background = Color(0xFFF6F0E7); // Linen - Main app background
  static const Color surface = Color(0xFFFFFDF9); // Warm White - Cards / inputs / surfaces
  static const Color surfaceSoft = Color(0xFFEEE5DA); // Sand - Secondary surfaces

  // Text
  static const Color textPrimary = Color(0xFF292522); // Dark Brown - Main text
  static const Color textSecondary = Color(0xFF756C64); // Warm Gray - Secondary text
  static const Color textMuted = Color(0xFF9A9189); // Soft Warm Gray - Muted / placeholder text

// Borders
  static const Color border = Color(0xFFDED2C5); // Beige Gray

  // Status Colors

  static const Color success = Color(0xFF68745A); // Muted Olive - Success only
  static const Color error = Color(0xFFC0392B); // Actual Red - Errors / destructive actions only
  static const Color warning = Color(0xFFC49A52); // Ochre - Warnings
  static const Color info = Color(0xFF66838A); // Muted Blue - Informational states
}