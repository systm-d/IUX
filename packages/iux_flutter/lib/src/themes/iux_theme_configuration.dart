import 'package:flutter/foundation.dart';

import '../foundations/iux_foundations.dart';

/// What a theme was asked for, before anything is resolved.
///
/// This is the input to the theme engine, and it is deliberately separate from
/// the output. A configuration is a request — "dark, high contrast,
/// comfortable" — while a resolved theme is the set of concrete values that
/// request produced. Keeping them apart means a configuration can be stored,
/// compared and passed around without carrying a `ThemeData`, and it makes it
/// obvious which values a developer chose versus which values IUX derived.
///
/// A configuration is independent of `BuildContext`. It cannot read
/// `MediaQuery`, and it does not try: platform preferences are applied by the
/// widget layer, not baked into a static theme. See
/// `docs/accessibility/theme-preferences.md`.
@immutable
final class IuxThemeConfiguration {
  /// Creates a theme request.
  const IuxThemeConfiguration({
    this.brightness = Brightness.light,
    this.profile = const IuxAccessibilityProfile(),
    this.typography = const IuxTypographyConfiguration(),
  });

  /// Whether the interface is rendered on a light or dark base.
  final Brightness brightness;

  /// The accessibility preferences to apply.
  final IuxAccessibilityProfile profile;

  /// How type is resolved. Defaults to the platform font.
  final IuxTypographyConfiguration typography;

  /// Shorthand for the requested contrast level.
  IuxContrast get contrast => profile.contrast;

  /// Shorthand for the requested density.
  IuxDensity get density => profile.density;

  /// Shorthand for the requested motion preference.
  IuxMotionPreference get motion => profile.motion;

  /// Shorthand for the requested target size.
  IuxTouchTargetPreference get touchTarget => profile.touchTarget;

  /// Shorthand for the requested visual stimulation level.
  IuxVisualStimulation get visualStimulation => profile.visualStimulation;

  /// Returns a copy with the given values replaced.
  IuxThemeConfiguration copyWith({
    Brightness? brightness,
    IuxAccessibilityProfile? profile,
    IuxTypographyConfiguration? typography,
  }) =>
      IuxThemeConfiguration(
        brightness: brightness ?? this.brightness,
        profile: profile ?? this.profile,
        typography: typography ?? this.typography,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxThemeConfiguration &&
          other.brightness == brightness &&
          other.profile == profile &&
          other.typography == typography;

  @override
  int get hashCode => Object.hash(brightness, profile, typography);

  @override
  String toString() => 'IuxThemeConfiguration(${brightness.name}, '
      'contrast: ${contrast.name}, density: ${density.name}, '
      'motion: ${motion.name}, touchTarget: ${touchTarget.name}, '
      'visualStimulation: ${visualStimulation.name})';
}

/// How type is resolved for a theme.
///
/// The only customisation offered is the font family. Sizes, weights and line
/// heights stay under IUX control, because they are what the readability and
/// text-scaling guarantees rest on — a theme that let an application set an
/// 11pt body style would be offering a way to break its own contract.
@immutable
final class IuxTypographyConfiguration {
  /// Creates a typography request. With no family, the platform font is used.
  const IuxTypographyConfiguration({
    this.fontFamily,
    this.fontFamilyFallback,
  });

  /// The font family to apply to every role, or null for the platform font.
  final String? fontFamily;

  /// Families to fall back to, in order, when a glyph is missing.
  ///
  /// Worth setting for applications serving scripts the primary family does
  /// not cover, so a missing glyph degrades to a readable one rather than to
  /// a placeholder box.
  final List<String>? fontFamilyFallback;

  /// Returns a copy with the given values replaced.
  IuxTypographyConfiguration copyWith({
    String? fontFamily,
    List<String>? fontFamilyFallback,
  }) =>
      IuxTypographyConfiguration(
        fontFamily: fontFamily ?? this.fontFamily,
        fontFamilyFallback: fontFamilyFallback ?? this.fontFamilyFallback,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxTypographyConfiguration &&
          other.fontFamily == fontFamily &&
          listEquals(other.fontFamilyFallback, fontFamilyFallback);

  @override
  int get hashCode => Object.hash(
        fontFamily,
        fontFamilyFallback == null ? null : Object.hashAll(fontFamilyFallback!),
      );
}
