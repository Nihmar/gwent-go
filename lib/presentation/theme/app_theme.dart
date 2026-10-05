import 'package:flutter/material.dart';

import 'gwent_colors.dart';

/// Material 3 dark theme for Gwent Go.
///
/// The seed is the mockup gold; surface roles are overridden with the warm
/// charcoal tones used by the design so the default `fromSeed` palette does not
/// wash out the Gwent look.
abstract final class AppTheme {
  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: GwentColors.primary,
      onPrimary: GwentColors.onPrimary,
      primaryContainer: GwentColors.goldDeep,
      onPrimaryContainer: GwentColors.parchment,
      secondary: GwentColors.onSecondaryContainer,
      onSecondary: GwentColors.secondaryContainer,
      secondaryContainer: GwentColors.secondaryContainer,
      onSecondaryContainer: GwentColors.onSecondaryContainer,
      tertiary: GwentColors.tertiary,
      onTertiary: GwentColors.surfaceLowest,
      error: GwentColors.error,
      onError: GwentColors.surfaceLowest,
      surface: GwentColors.background,
      onSurface: GwentColors.onSurface,
      surfaceContainerLowest: GwentColors.surfaceLowest,
      surfaceContainerLow: GwentColors.surfaceLow,
      surfaceContainer: GwentColors.surfaceLow,
      surfaceContainerHigh: GwentColors.surfaceHigh,
      surfaceContainerHighest: GwentColors.surfaceHighest,
      onSurfaceVariant: GwentColors.onSurfaceVariant,
      outline: GwentColors.outline,
      outlineVariant: GwentColors.outlineVariant,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: GwentColors.parchment,
      onInverseSurface: GwentColors.surfaceLowest,
      inversePrimary: GwentColors.goldDeep,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: GwentColors.background,
      splashFactory: InkSparkle.splashFactory,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: GwentColors.surfaceLow,
        foregroundColor: GwentColors.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          color: GwentColors.goldBright,
          fontWeight: FontWeight.w600,
          letterSpacing: 4,
        ),
      ),
      cardTheme: CardThemeData(
        color: GwentColors.surfaceLow,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: GwentColors.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: GwentColors.outlineVariant,
        thickness: 0.6,
        space: 1,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Colors.transparent,
        side: BorderSide(color: GwentColors.outline.withValues(alpha: 0.7)),
        labelStyle: const TextStyle(
          color: GwentColors.onSurfaceVariant,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: GwentColors.primary,
          foregroundColor: GwentColors.onPrimary,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.2),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: GwentColors.primary),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          side: WidgetStatePropertyAll(
            BorderSide(color: GwentColors.outline.withValues(alpha: 0.9)),
          ),
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: GwentColors.surfaceLow,
        indicatorColor: GwentColors.secondaryContainer,
        selectedIconTheme: const IconThemeData(color: GwentColors.onSecondaryContainer),
        unselectedIconTheme: const IconThemeData(color: GwentColors.onSurfaceVariant),
        selectedLabelTextStyle: const TextStyle(color: GwentColors.onSecondaryContainer),
        unselectedLabelTextStyle: const TextStyle(color: GwentColors.onSurfaceVariant),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: GwentColors.surfaceHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  /// Display style used for the wordmark and hero titles.
  static TextStyle displayStyle(BuildContext context, {double size = 40}) =>
      TextStyle(
        fontFamily: 'serif',
        fontSize: size,
        height: 1,
        letterSpacing: size * 0.1,
        color: GwentColors.goldBright,
        shadows: const [
          Shadow(color: Colors.black87, blurRadius: 16, offset: Offset(0, 3)),
        ],
      );
}
