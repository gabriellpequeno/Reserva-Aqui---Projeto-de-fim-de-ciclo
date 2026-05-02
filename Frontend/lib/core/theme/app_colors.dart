import 'package:flutter/material.dart';

/// Brand colors first — everything else (surfaces, text, borders) should come
/// from `Theme.of(context).colorScheme.*` via AppTheme.light / AppTheme.dark.
///
/// The legacy tokens below (`backgroundLight`, `greyText`, `strokeLight`, `bgSecondary`)
/// are kept for backwards-compat with pages that came from the main merge
/// (admin_*, edit_room_page). They are pinned to the light-theme values and do
/// NOT adapt to dark mode. Follow-up: migrate those pages to `colorScheme.*`.
class AppColors {
  // Brand
  static const Color primary = Color(0xFF182541);
  static const Color secondary = Color(0xFFEC6725);

  // Legacy (light-only) — to be removed as pages get migrated
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color greyText = Color(0xFF828282);
  static const Color strokeLight = Color(0xFFE6E6E6);
  static const Color bgSecondary = Color(0xFFF5F5F5);
}
