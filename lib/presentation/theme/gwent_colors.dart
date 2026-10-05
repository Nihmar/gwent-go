import 'package:flutter/material.dart';

/// Colours sampled from the UI mockup (`mockups/css/theme.css`).
///
/// Translating the mockup palette directly keeps the widget-based board close
/// to the design without depending on any raster board image.
abstract final class GwentColors {
  static const primary = Color(0xFFE7C27D);
  static const onPrimary = Color(0xFF3B2A00);
  static const secondaryContainer = Color(0xFF4F4533);
  static const onSecondaryContainer = Color(0xFFF5E2CB);
  static const tertiary = Color(0xFFA9D4E8);
  static const error = Color(0xFFFFB4AB);

  static const background = Color(0xFF14110D);
  static const surfaceLowest = Color(0xFF0E0C09);
  static const surfaceLow = Color(0xFF1D1915);
  static const surfaceHigh = Color(0xFF2C2620);
  static const surfaceHighest = Color(0xFF372F28);
  static const onSurface = Color(0xFFE9E2D6);
  static const onSurfaceVariant = Color(0xFFCFC4B0);
  static const outline = Color(0xFF988E7C);
  static const outlineVariant = Color(0xFF4C453A);

  static const gold = Color(0xFFD9A93F);
  static const goldBright = Color(0xFFF2CE79);
  static const goldDeep = Color(0xFF8A6A20);
  static const parchment = Color(0xFFEADFC8);
  static const feltA = Color(0xFF241F19);
  static const feltB = Color(0xFF171310);

  /// Gradient used behind every screen, mirroring `.board-bg`.
  static const boardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [feltA, feltB],
  );

  static const goldGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [goldBright, gold],
  );

  /// Glow colour used when an ability affects a card.
  static Color abilityEffect(String ability) => switch (ability) {
    'scorch' ||
    'scorch_c' ||
    'scorch_r' ||
    'scorch_s' => const Color(0xFFFF7043),
    'medic' => const Color(0xFF81C784),
    'muster' => const Color(0xFFFFD54F),
    'spy' => const Color(0xFF64B5F6),
    'decoy' => const Color(0xFF4DB6AC),
    'avenger' || 'avenger_kambi' => const Color(0xFFBA68C8),
    'berserker' || 'mardroeme' => const Color(0xFFA1887F),
    _ => primary,
  };
}
