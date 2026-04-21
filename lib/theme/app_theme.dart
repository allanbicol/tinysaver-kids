import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── MD3 Tonal Color Tokens ────────────────────────────────────────────────────
class AppColors {
  // Primary — Sunray Gold
  static const Color primaryDark      = Color(0xFF705D00);
  static const Color primary          = Color(0xFFFFD93D);
  static const Color primaryContainer = Color(0xFFFFECAA);
  static const Color onPrimary        = Color(0xFF3C3000);

  // Secondary — Sky Horizon
  static const Color secondaryDark      = Color(0xFF00658B);
  static const Color secondary          = Color(0xFF6CCBFF);
  static const Color secondaryContainer = Color(0xFFCCE8FF);
  static const Color onSecondary        = Color(0xFF003548);

  // Tertiary — Soft Green (growth + trust)
  static const Color tertiaryDark      = Color(0xFF2E7D4F);
  static const Color tertiary          = Color(0xFF8BD4A0);
  static const Color tertiaryContainer = Color(0xFFD8F2E0);
  static const Color onTertiary        = Color(0xFF0F3B1E);

  // Pig blush — kept pink even though tertiary is green (pigs are pink!)
  static const Color pigBlush          = Color(0xFF9B3F5A);

  // Surfaces — MD3 hierarchy (sky → ground → card → nested)
  static const Color surface              = Color(0xFFFAFAF7);
  static const Color surfaceContainerLow  = Color(0xFFF0EBE1);
  static const Color surfaceContainer     = Color(0xFFEAE4DA);
  static const Color surfaceContainerHigh = Color(0xFFE3DDD3);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);

  // Text & outline
  static const Color onSurface        = Color(0xFF1C1B1F);
  static const Color onSurfaceVariant = Color(0xFF49454F);
  static const Color outline          = Color(0xFF79747E);
  static const Color outlineVariant   = Color(0xFFCAC4D0);

  // Semantic
  static const Color success = Color(0xFF386A20);
  static const Color danger  = Color(0xFFBA1A1A);
  static const Color dangerContainer = Color(0xFFFFDAD6);

  // Coin
  static const Color coinGold   = Color(0xFFFFD93D);
  static const Color coinDark   = Color(0xFF705D00);

  // ── Gradients ───────────────────────────────────────────────────────────────

  // CTA: jewel-like 135° gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFE566), Color(0xFFE6C235)],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6CCBFF), Color(0xFF4DB8F0)],
  );

  static const LinearGradient tertiaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8BD4A0), Color(0xFF6EC085)],
  );

  static const LinearGradient balanceCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0086B8), Color(0xFF00658B)],
  );
}

// ── Theme ─────────────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData get theme {
    final base = GoogleFonts.plusJakartaSansTextTheme();
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.primaryDark,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.secondaryDark,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiaryContainer: AppColors.tertiaryDark,
        error: AppColors.danger,
        onError: Colors.white,
        errorContainer: AppColors.dangerContainer,
        onErrorContainer: AppColors.danger,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
        surfaceContainerLow: AppColors.surfaceContainerLow,
        surfaceContainer: AppColors.surfaceContainer,
        surfaceContainerHigh: AppColors.surfaceContainerHigh,
        surfaceContainerLowest: AppColors.surfaceContainerLowest,
      ),
      scaffoldBackgroundColor: AppColors.surfaceContainerLow,
      textTheme: base.copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 56, fontWeight: FontWeight.w800, color: AppColors.onSurface, height: 1.1),
        displayMedium: GoogleFonts.plusJakartaSans(
          fontSize: 40, fontWeight: FontWeight.w700, color: AppColors.primaryDark, height: 1.15),
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.onSurface),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.onSurface),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.onSurface),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.onSurface),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.onSurface, height: 1.6),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.onSurfaceVariant),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        labelMedium: GoogleFonts.plusJakartaSans(
          fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5,
          color: AppColors.onSurfaceVariant),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primaryDark, size: 24);
          }
          return const IconThemeData(color: AppColors.onSurfaceVariant, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final base = GoogleFonts.plusJakartaSans(
            fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5);
          if (states.contains(WidgetState.selected)) {
            return base.copyWith(color: AppColors.primaryDark);
          }
          return base.copyWith(color: AppColors.onSurfaceVariant);
        }),
        elevation: 0,
        height: 72,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: AppColors.primaryDark,
          elevation: 0,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.onSurfaceVariant,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15, fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: const StadiumBorder(),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 22, fontWeight: FontWeight.w800,
          color: AppColors.onSurface),
        contentTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 15, fontWeight: FontWeight.w500,
          color: AppColors.onSurfaceVariant, height: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(
            color: AppColors.secondaryDark,
            width: 2,
          ),
        ),
        // Keep label dark regardless of focus state (avoid default yellow primary)
        labelStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.onSurfaceVariant, fontSize: 15,
          fontWeight: FontWeight.w500),
        floatingLabelStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.secondaryDark, fontSize: 14,
          fontWeight: FontWeight.w700),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.outline, fontSize: 15),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      // Dark cursor instead of bright-yellow primary
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.onSurface,
        selectionColor: AppColors.secondaryContainer,
        selectionHandleColor: AppColors.secondaryDark,
      ),
    );
  }
}
