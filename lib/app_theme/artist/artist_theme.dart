import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'artist_colors.dart';

class ArtistTheme {
  ArtistTheme._();

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    // Colors
    scaffoldBackgroundColor: ArtistColors.background,
    primaryColor: ArtistColors.primary,
    colorScheme: ColorScheme.light(
      primary: ArtistColors.primary,
      secondary: ArtistColors.secondary,
      surface: ArtistColors.surface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: ArtistColors.textPrimary,
      error: ArtistColors.error,
      onError: Colors.white,
    ),
    // Global Font
    textTheme: GoogleFonts.poppinsTextTheme(),
    // App Bar
    appBarTheme: AppBarTheme(
      backgroundColor: ArtistColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(color: ArtistColors.textPrimary),
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: ArtistColors.textPrimary,
      ),
    ),
    // Elevated Button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ArtistColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    // Outlined Button
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ArtistColors.primary,
        backgroundColor: Colors.transparent,
        minimumSize: const Size(double.infinity, 52),
        side: const BorderSide(color: ArtistColors.primary, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    // Text Button
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ArtistColors.primary,
        textStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    // Input Fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ArtistColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: GoogleFonts.poppins(
        fontSize: 14,
        color: ArtistColors.textSecondary.withOpacity(0.6),
      ),
      labelStyle: GoogleFonts.poppins(
        fontSize: 14,
        color: ArtistColors.textSecondary,
      ),
      floatingLabelStyle: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: ArtistColors.primary,
      ),
      prefixIconColor: ArtistColors.textSecondary,
      suffixIconColor: ArtistColors.textSecondary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ArtistColors.border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: ArtistColors.primary.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ArtistColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ArtistColors.error, width: 1.5),
      ),
    ),
    // Card
    cardTheme: CardThemeData(
      color: ArtistColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: ArtistColors.border, width: 1),
      ),
    ),
    // Divider
    dividerTheme: const DividerThemeData(
      color: ArtistColors.border,
      thickness: 1,
      space: 1,
    ),
    // Bottom Navigation
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: ArtistColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      height: 72,
      indicatorColor: ArtistColors.secondary,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: states.contains(WidgetState.selected)
              ? Colors.white
              : ArtistColors.textMuted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        return IconThemeData(
          size: 24,
          color: states.contains(WidgetState.selected)
              ? ArtistColors.accent
              : ArtistColors.textMuted,
        );
      }),
    ),
    // Floating Action Button
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: ArtistColors.primary,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
    ),
    // Chip
    chipTheme: ChipThemeData(
      backgroundColor: ArtistColors.surfaceSoft,
      selectedColor: ArtistColors.secondary,
      disabledColor: ArtistColors.surfaceSoft,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      labelStyle: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: ArtistColors.textPrimary,
      ),
      secondaryLabelStyle: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      side: const BorderSide(color: ArtistColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    // Dialog
    dialogTheme: DialogThemeData(
      backgroundColor: ArtistColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: ArtistColors.textPrimary,
      ),
      contentTextStyle: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: ArtistColors.textSecondary,
        height: 1.5,
      ),
    ),
    // Bottom Sheet
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: ArtistColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      showDragHandle: true,
    ),
  );
}
