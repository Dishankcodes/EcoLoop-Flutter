import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'artist_colors.dart';

class ArtistTextStyles {
  static var navigation;

  static TextStyle? price;

  ArtistTextStyles._();

  // ============================================================
  // HEADING
  // Used for splash / large page titles
  // ============================================================

  static TextStyle get heading => GoogleFonts.poppins(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: ArtistColors.textPrimary,
    letterSpacing: 0.2,
  );

  // ============================================================
  // SECTION TITLES
  // ============================================================

  static TextStyle get title => GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: ArtistColors.textPrimary,
  );

  // ============================================================
  // BODY TEXT
  // ============================================================

  static TextStyle get body => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: ArtistColors.textSecondary,
    height: 1.5,
  );

  // ============================================================
  // SMALL / CAPTION TEXT
  // ============================================================

  static TextStyle get caption => GoogleFonts.poppins(
    fontSize: 12,
    color: ArtistColors.textSecondary.withOpacity(0.8),
  );

  // ============================================================
  // INPUT HINT TEXT
  // ============================================================

  static TextStyle get hint => GoogleFonts.poppins(
    fontSize: 14,
    color: ArtistColors.textSecondary.withOpacity(0.6),
  );

  // ============================================================
  // BUTTON TEXT
  // ============================================================

  static TextStyle get button => GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.3,
  );

  // ============================================================
  // EXTRA STYLES
  //
  // These are useful for Artist pages while still following
  // exactly the same Poppins typography system.
  // ============================================================

  static TextStyle get label => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: ArtistColors.textPrimary,
  );

  static TextStyle get bodyMedium => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: ArtistColors.textPrimary,
    height: 1.5,
  );

  static TextStyle get small => GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: ArtistColors.textMuted,
  );
}
