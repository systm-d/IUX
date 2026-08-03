import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// WCAG 2.x contrast measurement, available to tests only.
///
/// This deliberately lives under `test/` rather than in `lib/`. Measuring
/// contrast at runtime would invite components to correct their own colors,
/// which is exactly the responsibility a theme must hold: a component that
/// repairs a bad palette hides the fact that the palette is bad.
abstract final class ContrastMetric {
  /// The minimum ratio for body text, per WCAG 2.2 SC 1.4.3 (level AA).
  static const double normalText = 4.5;

  /// The minimum ratio for large text, per WCAG 2.2 SC 1.4.3 (level AA).
  ///
  /// Large text means at least 18pt, or 14pt bold.
  static const double largeText = 3.0;

  /// The minimum ratio for interface components and meaningful graphics,
  /// per WCAG 2.2 SC 1.4.11.
  static const double nonText = 3.0;

  /// Returns the relative luminance of [color], per the WCAG definition.
  ///
  /// The color must be fully opaque: a translucent color has no luminance of
  /// its own, only one relative to whatever happens to be behind it.
  static double relativeLuminance(Color color) {
    assert(
      color.a == 1.0,
      'Contrast is undefined for a translucent color. Composite it over its '
      'background first.',
    );
    return 0.2126 * _linearize(color.r) +
        0.7152 * _linearize(color.g) +
        0.0722 * _linearize(color.b);
  }

  /// Returns the contrast ratio between two opaque colors, from 1 to 21.
  ///
  /// The result is symmetric: argument order does not matter.
  static double ratio(Color a, Color b) {
    final double la = relativeLuminance(a);
    final double lb = relativeLuminance(b);
    final double lighter = math.max(la, lb);
    final double darker = math.min(la, lb);
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Whether [foreground] on [background] reaches [threshold].
  static bool meets(Color foreground, Color background, double threshold) =>
      ratio(foreground, background) >= threshold;

  static double _linearize(double channel) => channel <= 0.03928
      ? channel / 12.92
      : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
}
