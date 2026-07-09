import 'package:flutter/material.dart';

class AppTheme {
  // Canvas (scaffold background)
  static const Color darkCanvas   = Color(0xFF161618);
  static const Color lightCanvas  = Color(0xFFFAFAF8);

  // Surface (cards, sheets)
  static const Color darkSurface  = Color(0xFF242426);
  static const Color lightSurface = Color(0xFFF0EEE8);

  // Primary text
  static const Color textDark  = Color(0xFFF5F5F0);
  static const Color textLight = Color(0xFF1A1A1A);

  // Muted / secondary text
  static const Color mutedDark  = Color(0xFF48484A);
  static const Color mutedLight = Color(0xFFAEAAA2);

  // Semantic
  static const Color semanticGreen  = Color(0xFF34C759);
  static const Color semanticYellow = Color(0xFFFFFC42);
  static const Color semanticRed    = Color(0xFFFF453A);

  // Legacy aliases — kept for backwards compatibility with existing screens
  static const Color brandRed     = semanticRed;
  static const Color success      = semanticGreen;
  static const Color warning      = semanticYellow;
  static const Color info         = Color(0xFF48484A);
  static const Color accentPurple = Color(0xFF48484A);

  static const double radius = 12;

  static ThemeData get darkTheme {
    final cs = ColorScheme.fromSeed(
      seedColor: const Color(0xFF3A3A3C),
      brightness: Brightness.dark,
    ).copyWith(
      surface: darkSurface,
      onSurface: textDark,
      onSurfaceVariant: mutedDark,
      primary: textDark,
      onPrimary: darkCanvas,
      outline: const Color(0xFF3A3A3C),
      outlineVariant: const Color(0xFF2C2C2E),
      error: semanticRed,
      onError: darkCanvas,
    );

    return _buildTheme(
      colorScheme: cs,
      scaffoldBackground: darkCanvas,
      cardColor: darkSurface,
      dividerColor: const Color(0xFF3A3A3C),
      onSurface: textDark,
      muted: mutedDark,
      buttonBg: const Color(0xFFF5F5F0),
      buttonFg: const Color(0xFF161618),
    );
  }

  static ThemeData get lightTheme {
    final cs = ColorScheme.fromSeed(
      seedColor: const Color(0xFFAEAAA2),
      brightness: Brightness.light,
    ).copyWith(
      surface: lightSurface,
      onSurface: textLight,
      onSurfaceVariant: mutedLight,
      primary: textLight,
      onPrimary: lightCanvas,
      outline: const Color(0xFFD4D0C8),
      outlineVariant: const Color(0xFFE8E6DF),
      error: semanticRed,
      onError: lightCanvas,
    );

    return _buildTheme(
      colorScheme: cs,
      scaffoldBackground: lightCanvas,
      cardColor: lightSurface,
      dividerColor: const Color(0xFFD4D0C8),
      onSurface: textLight,
      muted: mutedLight,
      buttonBg: const Color(0xFF1A1A1A),
      buttonFg: const Color(0xFFFAFAF8),
    );
  }

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Color scaffoldBackground,
    required Color cardColor,
    required Color dividerColor,
    required Color onSurface,
    required Color muted,
    required Color buttonBg,
    required Color buttonFg,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackground,
      cardColor: cardColor,
      dividerColor: dividerColor,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackground,
        foregroundColor: onSurface,
        centerTitle: false,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: dividerColor),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonBg,
          foregroundColor: buttonFg,
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          side: BorderSide(color: dividerColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scaffoldBackground,
        selectedItemColor: onSurface,
        unselectedItemColor: muted,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
