import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static final ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFF2A3A5E),
    onPrimaryContainer: Colors.white,
    secondary: AppColors.secondary,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFFFD4BF),
    onSecondaryContainer: Color(0xFF3A1800),
    tertiary: AppColors.secondary,
    onTertiary: Colors.white,
    error: Color(0xFFB3261E),
    onError: Colors.white,
    surface: Color(0xFFFFFFFF),
    onSurface: AppColors.primary,
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF9F9F9),
    surfaceContainer: Color(0xFFF5F5F5),
    surfaceContainerHigh: Color(0xFFEFEFEF),
    surfaceContainerHighest: Color(0xFFE6E6E6),
    onSurfaceVariant: Color(0xFF828282),
    outline: Color(0xFFE6E6E6),
    outlineVariant: Color(0xFFDADADA),
    shadow: Colors.black,
    scrim: Colors.black54,
    inverseSurface: Color(0xFF121212),
    onInverseSurface: Colors.white,
  );

  static final ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF8FA4D4),
    onPrimary: Color(0xFF0A1226),
    primaryContainer: Color(0xFF2A3A5E),
    onPrimaryContainer: Colors.white,
    secondary: AppColors.secondary,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFF5A2A0F),
    onSecondaryContainer: Color(0xFFFFD4BF),
    tertiary: Color(0xFFFF8A50),
    onTertiary: Colors.white,
    error: Color(0xFFF2B8B5),
    onError: Color(0xFF601410),
    surface: Color(0xFF121212),
    onSurface: Color(0xFFF5F5F5),
    surfaceContainerLowest: Color(0xFF0A0A0A),
    surfaceContainerLow: Color(0xFF181818),
    surfaceContainer: Color(0xFF1E1E1E),
    surfaceContainerHigh: Color(0xFF262626),
    surfaceContainerHighest: Color(0xFF2E2E2E),
    onSurfaceVariant: Color(0xFFB0B0B0),
    outline: Color(0xFF3A3A3A),
    outlineVariant: Color(0xFF2A2A2A),
    shadow: Colors.black,
    scrim: Colors.black87,
    inverseSurface: Color(0xFFF5F5F5),
    onInverseSurface: Color(0xFF121212),
  );

  static ThemeData get light => _build(_lightScheme);
  static ThemeData get dark => _build(_darkScheme);

  static ThemeData _build(ColorScheme scheme) {
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: scheme.onSurface),
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outline,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer,
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(color: scheme.onSurface),
        displayMedium: TextStyle(color: scheme.onSurface),
        displaySmall: TextStyle(color: scheme.onSurface),
        headlineLarge: TextStyle(color: scheme.onSurface),
        headlineMedium: TextStyle(color: scheme.onSurface),
        headlineSmall: TextStyle(color: scheme.onSurface),
        titleLarge: TextStyle(color: scheme.onSurface),
        titleMedium: TextStyle(color: scheme.onSurface),
        titleSmall: TextStyle(color: scheme.onSurface),
        bodyLarge: TextStyle(color: scheme.onSurface),
        bodyMedium: TextStyle(color: scheme.onSurface),
        bodySmall: TextStyle(color: scheme.onSurfaceVariant),
        labelLarge: TextStyle(color: scheme.onSurface),
        labelMedium: TextStyle(color: scheme.onSurfaceVariant),
        labelSmall: TextStyle(color: scheme.onSurfaceVariant),
      ),
      iconTheme: IconThemeData(color: scheme.onSurface),
    );
  }
}
