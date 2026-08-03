import 'package:flutter/material.dart';

import '../foundations/iux_foundations.dart';
import '../themes/extensions/iux_motion_theme.dart';
import 'iux_accessibility.dart';

/// What an animation is for, which is what decides whether it survives.
enum IuxMotionRole {
  /// Movement that answers a question: what changed, where did it go, what
  /// should I look at. Shortened when the user asks for less, removed only
  /// under [IuxMotionPreference.none].
  essential,

  /// Movement that makes the interface feel responsive without carrying
  /// information. Removed as soon as the user asks for less.
  decorative,
}

/// The decision a component must apply to one animation.
@immutable
final class IuxMotionDecision {
  /// Creates a decision.
  const IuxMotionDecision({required this.duration, required this.curve});

  /// How long the animation may run. [Duration.zero] means do not animate.
  final Duration duration;

  /// The easing to apply.
  final Curve curve;

  /// Whether the component should skip animating entirely.
  bool get isInstant => duration == Duration.zero;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxMotionDecision &&
          other.duration == duration &&
          other.curve == curve;

  @override
  int get hashCode => Object.hash(duration, curve);
}

/// Decides whether an animation runs, and for how long.
///
/// A component states what an animation is *for* and gets an answer. It never
/// reads `MediaQuery`, never branches on a preference, and never decides on
/// its own whether a user's request applies to it — which is how reduced
/// motion normally ends up honoured in some places and forgotten in others.
///
/// ```dart
/// final decision = IuxMotionPolicy.resolve(
///   context,
///   role: IuxMotionRole.essential,
///   scale: IuxMotionScale.standard,
/// );
/// AnimatedOpacity(duration: decision.duration, curve: decision.curve, ...)
/// ```
abstract final class IuxMotionPolicy {
  /// Resolves the decision for one animation at [context].
  static IuxMotionDecision resolve(
    BuildContext context, {
    required IuxMotionRole role,
    IuxMotionScale scale = IuxMotionScale.standard,
  }) {
    final IuxAccessibility accessibility = IuxAccessibility.of(context);
    final IuxMotionTheme theme = _themeOf(context);

    if (accessibility.suppressesAllMotion) {
      return const IuxMotionDecision(
        duration: Duration.zero,
        curve: Curves.linear,
      );
    }

    if (role == IuxMotionRole.decorative &&
        !accessibility.allowsNonEssentialMotion) {
      return const IuxMotionDecision(
        duration: Duration.zero,
        curve: Curves.linear,
      );
    }

    // Essential motion survives a reduced preference, but the theme has
    // already shortened its durations, so nothing extra is applied here.
    return IuxMotionDecision(
      duration: switch (scale) {
        IuxMotionScale.short => theme.short,
        IuxMotionScale.standard => theme.standard,
        IuxMotionScale.long => theme.long,
      },
      curve: switch (scale) {
        IuxMotionScale.short => theme.change,
        IuxMotionScale.standard => theme.change,
        IuxMotionScale.long => theme.enter,
      },
    );
  }

  /// Whether decorative movement is permitted at [context].
  static bool allowsDecoration(BuildContext context) =>
      IuxAccessibility.of(context).allowsNonEssentialMotion;

  static IuxMotionTheme _themeOf(BuildContext context) =>
      Theme.of(context).extension<IuxMotionTheme>() ??
      const IuxMotionTheme(
        instant: Duration.zero,
        short: IuxMotionDuration.short,
        standard: IuxMotionDuration.standard,
        long: IuxMotionDuration.long,
        enter: IuxMotionCurve.enter,
        exit: IuxMotionCurve.exit,
        change: IuxMotionCurve.change,
        allowsNonEssentialMotion: true,
        respectsPlatformPreference: true,
      );
}

/// How far an animation travels, expressed as intent rather than milliseconds.
enum IuxMotionScale {
  /// A small in-place change, such as a press.
  short,

  /// The default.
  standard,

  /// A large or full-screen transition.
  long,
}
