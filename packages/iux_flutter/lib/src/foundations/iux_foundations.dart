import 'package:flutter/animation.dart';

/// A limited spacing scale for grouping related interface content.
abstract final class IuxSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Minimum interactive dimensions; visual content may be smaller.
abstract final class IuxTouchTarget {
  static const double minimum = 48;
  static const double comfortable = 56;
}

/// Density changes spacing without reducing the minimum interactive target.
enum IuxDensity { compact, standard, comfortable }

/// Semantic levels of rounding, resolved by a future theme.
enum IuxShape { none, subtle, medium, prominent, full }

/// Structural levels of elevation, resolved by a future theme.
enum IuxElevation { none, raised, modal, transient }

/// Semantic text roles without selecting a font family.
enum IuxTypographyRole { display, headline, title, body, label, supporting }

/// Preference for non-essential interface movement.
enum IuxMotionPreference { system, reduced, none }

/// Contrast preference expressed as an interface condition, not a diagnosis.
enum IuxContrast { standard, high }

/// Requested interactive target size.
enum IuxTouchTargetPreference { standard, comfortable }

/// Visible focus geometry; color is provided by semantic tokens.
final class IuxFocusStyle {
  const IuxFocusStyle({this.width = 2, this.gap = 2})
      : assert(width > 0),
        assert(gap >= 0);

  final double width;
  final double gap;
}

/// Independent preferences that influence accessible IUX resolution.
final class IuxAccessibilityProfile {
  const IuxAccessibilityProfile({
    this.contrast = IuxContrast.standard,
    this.motion = IuxMotionPreference.system,
    this.density = IuxDensity.standard,
    this.touchTarget = IuxTouchTargetPreference.standard,
  });

  final IuxContrast contrast;
  final IuxMotionPreference motion;
  final IuxDensity density;
  final IuxTouchTargetPreference touchTarget;

  IuxAccessibilityProfile copyWith({
    IuxContrast? contrast,
    IuxMotionPreference? motion,
    IuxDensity? density,
    IuxTouchTargetPreference? touchTarget,
  }) =>
      IuxAccessibilityProfile(
        contrast: contrast ?? this.contrast,
        motion: motion ?? this.motion,
        density: density ?? this.density,
        touchTarget: touchTarget ?? this.touchTarget,
      );

  double get minimumTouchTarget =>
      touchTarget == IuxTouchTargetPreference.comfortable
          ? IuxTouchTarget.comfortable
          : IuxTouchTarget.minimum;
}

/// Pure helpers for density-aware values.
abstract final class IuxDensityResolver {
  static double spacing(double value, IuxDensity density) => switch (density) {
        IuxDensity.compact => value * .875,
        IuxDensity.standard => value,
        IuxDensity.comfortable => value * 1.125,
      };
}

/// Motion durations used only to express interaction roles.
abstract final class IuxMotionDuration {
  static const instant = Duration.zero;
  static const short = Duration(milliseconds: 100);
  static const standard = Duration(milliseconds: 200);
  static const long = Duration(milliseconds: 300);
}

/// Curves that correspond to state changes rather than a brand identity.
abstract final class IuxMotionCurve {
  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;
  static const change = Curves.easeInOutCubic;
}
