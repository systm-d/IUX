import 'package:flutter/material.dart';

import '../semantics/iux_semantic_colors.dart';
import 'extensions/iux_accessibility_theme.dart';
import 'extensions/iux_geometry_theme.dart';
import 'extensions/iux_motion_theme.dart';
import 'extensions/iux_typography_theme.dart';
import 'iux_color_palettes.dart';
import 'iux_color_scheme_mapping.dart';
import 'iux_theme_configuration.dart';

/// Everything a configuration resolved to.
///
/// A configuration says what was asked for; this says what came out. Keeping
/// the two apart means the resolved values can be inspected and tested without
/// building a `ThemeData`, and it makes clear which values IUX derived rather
/// than which a developer chose.
///
/// Use [material] to hand the result to a `MaterialApp`.
@immutable
final class IuxResolvedTheme {
  /// Creates a resolved theme from already-resolved parts.
  const IuxResolvedTheme({
    required this.configuration,
    required this.colors,
    required this.typography,
    required this.geometry,
    required this.motion,
    required this.accessibility,
  });

  /// Resolves a configuration into concrete values.
  factory IuxResolvedTheme.resolve(IuxThemeConfiguration configuration) {
    return IuxResolvedTheme(
      configuration: configuration,
      colors: IuxColorPalettes.resolve(
        configuration.brightness,
        configuration.contrast,
      ),
      typography: IuxTypographyTheme.resolve(configuration),
      geometry: IuxGeometryTheme.resolve(configuration),
      motion: IuxMotionTheme.resolve(configuration),
      accessibility: IuxAccessibilityTheme.resolve(configuration),
    );
  }

  /// The request this theme came from.
  final IuxThemeConfiguration configuration;

  /// Resolved semantic colours.
  final IuxSemanticColors colors;

  /// Resolved type styles.
  final IuxTypographyTheme typography;

  /// Resolved spacing, sizing, shape, elevation and focus geometry.
  final IuxGeometryTheme geometry;

  /// Resolved motion durations and curves.
  final IuxMotionTheme motion;

  /// The conditions this theme was resolved for.
  final IuxAccessibilityTheme accessibility;

  /// Every IUX extension, ready to install on a `ThemeData`.
  List<ThemeExtension<dynamic>> get extensions => <ThemeExtension<dynamic>>[
        colors,
        typography,
        geometry,
        motion,
        accessibility,
      ];

  /// The Material theme carrying these values.
  ///
  /// Material component themes are configured only where a gap would be
  /// visible today. Styling buttons, chips, cards or navigation here would
  /// pre-empt the missions that own those components.
  ThemeData get material {
    final ColorScheme scheme = IuxColorSchemeMapping.resolve(
      colors,
      configuration.brightness,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: configuration.brightness,
      colorScheme: scheme,
      textTheme: typography.toTextTheme(),
      scaffoldBackgroundColor: colors.surface.base,
      canvasColor: colors.surface.base,
      focusColor: colors.state.focus,
      hoverColor: colors.state.hovered,
      disabledColor: colors.content.disabled,
      extensions: extensions,
      dividerTheme: DividerThemeData(
        color: colors.border.subtle,
        thickness: geometry.borderWidth,
        space: geometry.spacingMd,
      ),
      iconTheme: IconThemeData(color: colors.content.primary),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface.subtle,
        foregroundColor: colors.content.primary,
        // Zero rather than an elevation: the app bar separates from content
        // through surface contrast, which survives dark conditions and a
        // reduced stimulation preference.
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: typography.title.copyWith(
          color: colors.content.primary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface.interactive,
        border: OutlineInputBorder(
          borderSide: BorderSide(
            color: colors.border.standard,
            width: geometry.borderWidth,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: colors.border.standard,
            width: geometry.borderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: colors.border.focus,
            width: geometry.focus.width,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: colors.border.error,
            width: geometry.strongBorderWidth,
          ),
        ),
        labelStyle: typography.label.copyWith(color: colors.content.secondary),
        helperStyle:
            typography.supporting.copyWith(color: colors.content.secondary),
        errorStyle: typography.supporting
            .copyWith(color: colors.feedback.error.content),
      ),
      // Material's default page transitions are decorative on Android. When
      // the user asked for less motion, remove them rather than shorten them.
      pageTransitionsTheme: motion.allowsNonEssentialMotion
          ? const PageTransitionsTheme()
          : const PageTransitionsTheme(
              builders: <TargetPlatform, PageTransitionsBuilder>{
                TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
              },
            ),
    );
  }

  /// Returns a copy with the given parts replaced.
  IuxResolvedTheme copyWith({
    IuxThemeConfiguration? configuration,
    IuxSemanticColors? colors,
    IuxTypographyTheme? typography,
    IuxGeometryTheme? geometry,
    IuxMotionTheme? motion,
    IuxAccessibilityTheme? accessibility,
  }) =>
      IuxResolvedTheme(
        configuration: configuration ?? this.configuration,
        colors: colors ?? this.colors,
        typography: typography ?? this.typography,
        geometry: geometry ?? this.geometry,
        motion: motion ?? this.motion,
        accessibility: accessibility ?? this.accessibility,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxResolvedTheme &&
          other.configuration == configuration &&
          other.colors == colors &&
          other.typography == typography &&
          other.geometry == geometry &&
          other.motion == motion &&
          other.accessibility == accessibility;

  @override
  int get hashCode => Object.hash(
        configuration,
        colors,
        typography,
        geometry,
        motion,
        accessibility,
      );
}
