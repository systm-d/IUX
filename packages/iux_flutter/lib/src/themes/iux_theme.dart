import 'package:flutter/material.dart';

import '../foundations/iux_foundations.dart';
import '../semantics/iux_semantic_colors.dart';
import 'iux_resolved_theme.dart';
import 'iux_theme_configuration.dart';

/// The entry point to the IUX theme engine.
///
/// The common case is one line:
///
/// ```dart
/// MaterialApp(
///   theme: IuxTheme.light(),
///   darkTheme: IuxTheme.dark(),
///   themeMode: ThemeMode.system,
/// )
/// ```
///
/// Preferences combine freely, and every combination is valid:
///
/// ```dart
/// IuxTheme.dark(
///   profile: const IuxAccessibilityProfile(
///     contrast: IuxContrast.high,
///     density: IuxDensity.comfortable,
///     motion: IuxMotionPreference.reduced,
///   ),
/// )
/// ```
///
/// There is deliberately no `highContrastLight()` or `highContrastDark()`
/// constructor. Four preferences with two to four values each would need
/// dozens of named constructors, and a combination that nobody thought to name
/// would be unreachable — which is how "high contrast" ends up meaning "high
/// contrast, but only in light mode".
abstract final class IuxTheme {
  /// A theme for light conditions.
  static ThemeData light({
    IuxAccessibilityProfile profile = const IuxAccessibilityProfile(),
    IuxTypographyConfiguration typography = const IuxTypographyConfiguration(),
  }) =>
      fromConfiguration(
        IuxThemeConfiguration(
          profile: profile,
          typography: typography,
        ),
      );

  /// A theme for dark conditions.
  static ThemeData dark({
    IuxAccessibilityProfile profile = const IuxAccessibilityProfile(),
    IuxTypographyConfiguration typography = const IuxTypographyConfiguration(),
  }) =>
      fromConfiguration(
        IuxThemeConfiguration(
          brightness: Brightness.dark,
          profile: profile,
          typography: typography,
        ),
      );

  /// Builds a Material theme from a full configuration.
  static ThemeData fromConfiguration(IuxThemeConfiguration configuration) =>
      resolve(configuration).material;

  /// Resolves a configuration without building a `ThemeData`.
  ///
  /// Useful for inspecting or testing resolved values directly.
  static IuxResolvedTheme resolve(IuxThemeConfiguration configuration) =>
      IuxResolvedTheme.resolve(configuration);

  /// Builds a theme whose semantic colours are supplied by the caller.
  ///
  /// This is how a brand applies its own palette without touching components:
  /// the roles change, everything reading them keeps working. The caller
  /// becomes responsible for the contrast contracts, which IUX can no longer
  /// guarantee. See `docs/themes/brand-theme-guidelines.md`.
  static ThemeData withSemanticColors(
    IuxThemeConfiguration configuration,
    IuxSemanticColors colors,
  ) =>
      resolve(configuration).copyWith(colors: colors).material;
}
