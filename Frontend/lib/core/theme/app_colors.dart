import 'package:flutter/material.dart';

/// Brand-only colors. Everything else (surfaces, text, borders, etc.)
/// comes from `Theme.of(context).colorScheme.*` via AppTheme.light / AppTheme.dark.
class AppColors {
  static const Color primary = Color(0xFF182541);
  static const Color secondary = Color(0xFFEC6725);
  static const Color greyText = Color(0xFF9E9E9E);
  static const Color strokeLight = Color(0xFFE0E0E0);

  // Semantic status colors — fixed meaning regardless of theme.
  // Use colorScheme.errorContainer for theme-adaptive backgrounds instead.
  static const Color successColor     = Color(0xFF1E7A1E);
  static const Color successContainer = Color(0xFFDCF5DC);
  static const Color errorColor       = Color(0xFFC0392B);
  static const Color errorBorder      = Color(0xFFEF2828);
  static const Color errorContainer   = Color(0xFFFDE8E8);
}
