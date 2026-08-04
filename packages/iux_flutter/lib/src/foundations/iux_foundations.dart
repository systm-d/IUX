import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

/// A limited spacing scale for grouping related interface content.
abstract final class IuxSpacing {
  /// The smallest step. Separates parts of one object, such as an icon from
  /// the label it belongs to.
  static const double xxs = 4;

  /// Separates items that read as one group.
  static const double xs = 8;

  /// Separates a label from the control it names.
  static const double sm = 12;

  /// The default gap between distinct pieces of content.
  static const double md = 16;

  /// Separates groups from each other.
  static const double lg = 24;

  /// Separates sections of a page.
  static const double xl = 32;

  /// The largest step. Separates a page's regions.
  static const double xxl = 48;
}

/// Minimum interactive dimensions; visual content may be smaller.
abstract final class IuxTouchTarget {
  /// The floor no interactive element may go below, in logical pixels.
  ///
  /// 48 is the Android accessibility minimum and satisfies WCAG 2.2 SC 2.5.8.
  /// It is a floor rather than a recommendation: spacing between adjacent
  /// targets is a separate concern, held by `IuxTargetSpacing`.
  static const double minimum = 48;

  /// The size a comfortable touch-target preference asks for.
  ///
  /// Requested by the user or the application; never smaller than [minimum].
  static const double comfortable = 56;
}

/// Density changes spacing without reducing the minimum interactive target.
enum IuxDensity {
  /// Tighter spacing, for screens showing many items at once.
  compact,

  /// The default.
  standard,

  /// Looser spacing, for screens read at a distance or with difficulty.
  comfortable,
}

/// Semantic levels of rounding, resolved by a future theme.
enum IuxShape {
  /// Square corners.
  none,

  /// A small radius.
  subtle,

  /// The default.
  medium,

  /// A large radius.
  prominent,

  /// Fully rounded ends.
  full,
}

/// Structural levels of elevation, resolved by a future theme.
enum IuxElevation {
  /// In the page's own plane.
  none,

  /// Lifted off the page, such as a card.
  raised,

  /// Above the page and blocking it, such as a dialog or a sheet.
  modal,

  /// Above everything and short-lived, such as a transient message.
  transient,
}

/// Semantic text roles without selecting a font family.
enum IuxTypographyRole {
  /// The largest role, for a single statement that identifies a screen.
  display,

  /// A screen or section heading.
  headline,

  /// The name of a group or of an object.
  title,

  /// Running prose.
  body,

  /// The text inside or beside a control.
  label,

  /// Secondary text that qualifies something else, such as help or an error.
  supporting,
}

/// Preference for non-essential interface movement.
///
/// [reduced] and [none] are separate on purpose. Reduced motion keeps the
/// transitions that answer "what just happened" while shortening or
/// simplifying them; no motion removes even those, because for a user with a
/// vestibular disorder an essential animation is still an animation.
enum IuxMotionPreference {
  /// Defer to the platform preference, read from `MediaQuery`.
  system,

  /// Full motion, regardless of the platform preference.
  standard,

  /// Essential transitions only, shortened.
  reduced,

  /// No motion. State changes are instant.
  none,
}

/// Contrast preference expressed as an interface condition, not a diagnosis.
enum IuxContrast {
  /// The theme's measured contrast, which already meets WCAG 2.2 AA.
  standard,

  /// Reinforced contrast, selectively rather than uniformly: content,
  /// identifying borders and focus gain separation, decorative separators do
  /// not.
  high,
}

/// Requested interactive target size.
enum IuxTouchTargetPreference {
  /// [IuxTouchTarget.minimum].
  standard,

  /// [IuxTouchTarget.comfortable].
  comfortable,
}

/// Preference for the amount of non-essential visual activity.
///
/// This is a comfort setting, not a clinical one. It reduces decoration,
/// saturation and concurrent change; it must never reduce legibility, and it
/// must not be presented as an accommodation for any particular condition.
enum IuxVisualStimulation {
  /// The default amount of decoration and concurrent change.
  standard,

  /// Less decoration, flatter elevation and no decorative motion. Colours,
  /// contrast and text sizes are unchanged.
  reduced,
}

/// Visible focus geometry; color is provided by semantic tokens.
///
/// Geometry and colour are separated so a high contrast preference can thicken
/// the ring without redefining what focus means.
@immutable
final class IuxFocusStyle {
  /// Creates a focus geometry. The width must be positive: a zero-width ring
  /// is an invisible focus indicator, which is a defect rather than a style.
  const IuxFocusStyle({this.width = 2, this.gap = 2})
      : assert(width > 0, 'A focus ring must be visible.'),
        assert(gap >= 0);

  /// Thickness of the focus ring, in logical pixels.
  final double width;

  /// Space between the element and its focus ring, in logical pixels.
  final double gap;

  /// Linearly interpolates between two focus geometries.
  static IuxFocusStyle lerp(IuxFocusStyle a, IuxFocusStyle b, double t) =>
      IuxFocusStyle(
        width: IuxInterpolation.lerp(a.width, b.width, t),
        gap: IuxInterpolation.lerp(a.gap, b.gap, t),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxFocusStyle && other.width == width && other.gap == gap;

  @override
  int get hashCode => Object.hash(width, gap);
}

/// Interpolation helpers used by IUX theme extensions.
abstract final class IuxInterpolation {
  /// Interpolates between two doubles without a nullable result.
  ///
  /// `dart:ui` exposes a top-level `lerpDouble` that returns a nullable value
  /// even for non-null inputs. Namespacing here avoids both the null
  /// assertions and an ambiguous import for anyone using `material.dart` and
  /// `iux_flutter.dart` together.
  static double lerp(double a, double b, double t) => a + (b - a) * t;
}

/// Independent preferences that influence accessible IUX resolution.
///
/// Every preference is orthogonal: any combination is valid, and none implies
/// another. High contrast does not force reduced motion, comfortable density
/// does not force larger targets.
///
/// A profile describes a *condition of use*, never a person. There is
/// deliberately no constructor naming a diagnosis or a population — a user who
/// wants less motion asks for less motion, and IUX does not infer why.
@immutable
final class IuxAccessibilityProfile {
  /// Creates a profile. Every preference defaults to its neutral value.
  const IuxAccessibilityProfile({
    this.contrast = IuxContrast.standard,
    this.motion = IuxMotionPreference.system,
    this.density = IuxDensity.standard,
    this.touchTarget = IuxTouchTargetPreference.standard,
    this.visualStimulation = IuxVisualStimulation.standard,
  });

  /// A profile that follows the platform and applies no override.
  const IuxAccessibilityProfile.standard() : this();

  /// A profile favouring reach and legibility over information density.
  const IuxAccessibilityProfile.comfortable()
      : this(
          density: IuxDensity.comfortable,
          touchTarget: IuxTouchTargetPreference.comfortable,
        );

  /// A profile that keeps only the motion that carries meaning.
  const IuxAccessibilityProfile.reducedMotion()
      : this(
          motion: IuxMotionPreference.reduced,
          visualStimulation: IuxVisualStimulation.reduced,
        );

  /// Requested contrast level.
  final IuxContrast contrast;

  /// Requested amount of interface movement.
  final IuxMotionPreference motion;

  /// Requested information density.
  final IuxDensity density;

  /// Requested interactive target size.
  final IuxTouchTargetPreference touchTarget;

  /// Requested amount of non-essential visual activity.
  final IuxVisualStimulation visualStimulation;

  /// Returns a copy with the given preferences replaced.
  IuxAccessibilityProfile copyWith({
    IuxContrast? contrast,
    IuxMotionPreference? motion,
    IuxDensity? density,
    IuxTouchTargetPreference? touchTarget,
    IuxVisualStimulation? visualStimulation,
  }) =>
      IuxAccessibilityProfile(
        contrast: contrast ?? this.contrast,
        motion: motion ?? this.motion,
        density: density ?? this.density,
        touchTarget: touchTarget ?? this.touchTarget,
        visualStimulation: visualStimulation ?? this.visualStimulation,
      );

  /// The smallest interactive dimension this profile permits.
  ///
  /// Density never enters this calculation: a compact layout tightens spacing,
  /// it does not shrink what a finger must hit.
  double get minimumTouchTarget =>
      touchTarget == IuxTouchTargetPreference.comfortable
          ? IuxTouchTarget.comfortable
          : IuxTouchTarget.minimum;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxAccessibilityProfile &&
          other.contrast == contrast &&
          other.motion == motion &&
          other.density == density &&
          other.touchTarget == touchTarget &&
          other.visualStimulation == visualStimulation;

  @override
  int get hashCode =>
      Object.hash(contrast, motion, density, touchTarget, visualStimulation);
}

/// Pure helpers for density-aware values.
abstract final class IuxDensityResolver {
  /// Scales a spacing [value] for [density].
  ///
  /// Spacing only. Interactive dimensions are never passed through here: the
  /// touch-target floor does not move with density.
  static double spacing(double value, IuxDensity density) => switch (density) {
        IuxDensity.compact => value * .875,
        IuxDensity.standard => value,
        IuxDensity.comfortable => value * 1.125,
      };
}

/// Motion durations used only to express interaction roles.
abstract final class IuxMotionDuration {
  /// No animation. The change is applied on the next frame.
  static const instant = Duration.zero;

  /// A small in-place change, such as a press.
  static const short = Duration(milliseconds: 100);

  /// The default.
  static const standard = Duration(milliseconds: 200);

  /// A large or full-screen transition.
  static const long = Duration(milliseconds: 300);
}

/// Curves that correspond to state changes rather than a brand identity.
abstract final class IuxMotionCurve {
  /// For something arriving: fast at first, settling at the end.
  static const enter = Curves.easeOutCubic;

  /// For something leaving: slow at first, then away.
  static const exit = Curves.easeInCubic;

  /// For something already on screen changing, where both ends are visible.
  static const change = Curves.easeInOutCubic;
}
