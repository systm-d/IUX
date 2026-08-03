import 'package:flutter/material.dart';

import '../accessibility/iux_accessibility.dart';
import '../foundations/iux_foundations.dart';
import '../themes/extensions/iux_motion_theme.dart';
import 'iux_motion_role.dart';

/// How far an animation travels, expressed as intent rather than milliseconds.
enum IuxMotionScale {
  /// A small in-place change, such as a press.
  short,

  /// The default.
  standard,

  /// A large or full-screen transition.
  long,
}

/// The answer to "may I animate this, and how".
@immutable
final class IuxResolvedMotion {
  /// Creates a resolved motion.
  const IuxResolvedMotion({
    required this.role,
    required this.duration,
    required this.curve,
    required this.behavior,
  });

  /// The role that was asked about.
  final IuxMotionRole role;

  /// How long the animation may run. [Duration.zero] means do not animate.
  final Duration duration;

  /// The easing to apply.
  final Curve curve;

  /// What was decided, and why the duration is what it is.
  final IuxReducedMotionBehavior behavior;

  /// Whether the component should animate at all.
  bool get isAnimated => duration > Duration.zero;

  /// Whether the component must express the change without movement.
  ///
  /// When true, the state change still has to be perceivable — through
  /// content, a live region, focus, or a static indicator. Removing the
  /// animation must never remove the information it carried.
  bool get requiresStaticAlternative => !isAnimated;

  /// Whether travel and size changes must be replaced by a fade.
  ///
  /// The animation still runs; only its form changes.
  bool get prefersFade => behavior == IuxReducedMotionBehavior.simplify;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxResolvedMotion &&
          other.role == role &&
          other.duration == duration &&
          other.curve == curve &&
          other.behavior == behavior;

  @override
  int get hashCode => Object.hash(role, duration, curve, behavior);

  @override
  String toString() => 'IuxResolvedMotion(${role.name}, ${behavior.name}, '
      '${duration.inMilliseconds}ms)';
}

/// Decides whether an animation runs, for how long, and in what form.
///
/// ```dart
/// final motion = IuxMotionPolicy.resolve(
///   context,
///   role: IuxMotionRole.reveal,
/// );
///
/// if (motion.prefersFade) {
///   return FadeTransition(...);
/// }
/// return SizeTransition(...);
/// ```
///
/// A component states intent and applies the answer. It never reads
/// `MediaQuery`, never branches on a preference, and never decides on its own
/// whether a user's request applies to it — which is how reduced motion
/// normally ends up honoured in nine components out of ten.
abstract final class IuxMotionPolicy {
  /// Resolves the motion for one animation at [context].
  static IuxResolvedMotion resolve(
    BuildContext context, {
    required IuxMotionRole role,
    IuxMotionScale scale = IuxMotionScale.standard,
  }) {
    final IuxAccessibility accessibility = IuxAccessibility.of(context);
    final IuxMotionTheme theme = _themeOf(context);

    final IuxReducedMotionBehavior behavior = _behaviorFor(role, accessibility);

    if (behavior == IuxReducedMotionBehavior.remove) {
      return IuxResolvedMotion(
        role: role,
        duration: Duration.zero,
        curve: Curves.linear,
        behavior: behavior,
      );
    }

    // The theme has already shortened its durations for a reduced preference,
    // so nothing extra is applied here: shortening twice would produce a
    // transition too fast to read.
    return IuxResolvedMotion(
      role: role,
      duration: switch (scale) {
        IuxMotionScale.short => theme.short,
        IuxMotionScale.standard => theme.standard,
        IuxMotionScale.long => theme.long,
      },
      curve: switch (role) {
        IuxMotionRole.enter || IuxMotionRole.reveal => theme.enter,
        IuxMotionRole.exit || IuxMotionRole.conceal => theme.exit,
        _ => theme.change,
      },
      behavior: behavior,
    );
  }

  /// Whether decorative movement is permitted at [context].
  static bool allowsDecoration(BuildContext context) =>
      IuxAccessibility.of(context).allowsNonEssentialMotion;

  static IuxReducedMotionBehavior _behaviorFor(
    IuxMotionRole role,
    IuxAccessibility accessibility,
  ) {
    if (accessibility.suppressesAllMotion) {
      // Nothing is exempt. For a user with a vestibular disorder an essential
      // animation is still an animation; progress then has to be reported
      // statically, which is what requiresStaticAlternative signals.
      return IuxReducedMotionBehavior.remove;
    }
    if (!role.isEssential && !accessibility.allowsNonEssentialMotion) {
      return IuxReducedMotionBehavior.remove;
    }
    if (accessibility.motion == IuxMotionPreference.reduced ||
        !accessibility.allowsNonEssentialMotion) {
      return role.reducedBehavior;
    }
    return IuxReducedMotionBehavior.preserve;
  }

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
