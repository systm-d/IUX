import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../accessibility/iux_accessibility.dart';
import '../../foundations/iux_foundations.dart';
import '../../motion/iux_motion_policy.dart';
import '../../motion/iux_motion_role.dart';
import '../../semantics/iux_semantic_colors.dart';
import '../../themes/extensions/iux_geometry_theme.dart';
import '../../themes/extensions/iux_typography_theme.dart';

/// How much progress must accumulate before a screen reader is told again.
///
/// Ten points. A live region makes TalkBack speak a whole phrase every time
/// its text changes, so announcing every percent would produce a hundred
/// interruptions during one upload. The user would not turn the progress bar
/// off — they would turn the screen reader off, and lose everything else with
/// it.
///
/// The eye is not throttled: the visible value updates on every frame the
/// caller supplies. Only the ear is, because only the ear is serialised.
const double kIuxProgressAnnouncementStep = 0.1;

/// How many transition durations one indeterminate traversal lasts.
///
/// The motion scale is calibrated for a single state change — 300ms at its
/// longest. A segment crossing the whole track in 300ms reads as a flicker,
/// not as work being done, so the traversal is a multiple of it. At the
/// standard scale this lands near 1.8s, the range Material and iOS
/// independently settled on.
const int _traversalFactor = 6;

/// Everything needed to paint a progress indicator, and nothing about how.
///
/// Both the determinate and the indeterminate indicator read this, so the two
/// cannot drift into different thicknesses or different accents — which is the
/// usual way a library ends up with a loading bar that does not look like its
/// own progress bar.
@immutable
final class IuxProgressTokens {
  /// Creates a resolved appearance.
  const IuxProgressTokens({
    required this.thickness,
    required this.radius,
    required this.track,
    required this.fill,
    required this.labelStyle,
    required this.valueStyle,
    required this.motion,
    required this.traversal,
  });

  /// The height of the bar, in logical pixels.
  final double thickness;

  /// The corner radius of the bar.
  final double radius;

  /// The colour of the part not yet covered.
  final Color track;

  /// The colour of the part covered, and of the indeterminate segment.
  ///
  /// This is the only colour that carries information, so it is the one held
  /// to WCAG 2.2 SC 1.4.11 against both [track] and the page behind it.
  final Color fill;

  /// The style of the line describing what is happening.
  final TextStyle labelStyle;

  /// The style of the line stating how far it has got.
  final TextStyle valueStyle;

  /// Whether and how the determinate fill may travel between two values.
  ///
  /// [IuxResolvedMotion.requiresStaticAlternative] is the field that matters:
  /// when it is true the indicator has to state its progress without moving at
  /// all.
  final IuxResolvedMotion motion;

  /// How long one indeterminate traversal lasts, or zero when motion is off.
  final Duration traversal;

  /// Whether an indicator may move at this context.
  bool get isAnimated => motion.isAnimated;

  /// Whether progress must be reported without any movement.
  bool get requiresStaticAlternative => motion.requiresStaticAlternative;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxProgressTokens &&
          other.thickness == thickness &&
          other.radius == radius &&
          other.track == track &&
          other.fill == fill &&
          other.labelStyle == labelStyle &&
          other.valueStyle == valueStyle &&
          other.motion == motion &&
          other.traversal == traversal;

  @override
  int get hashCode => Object.hash(
        thickness,
        radius,
        track,
        fill,
        labelStyle,
        valueStyle,
        motion,
        traversal,
      );
}

/// Resolves the complete appearance of a progress indicator.
///
/// There is no `IuxProgressTheme`, and deliberately so: a progress indicator
/// has no decision an application could usefully vary that is not already
/// carried by geometry, typography and the semantic palette. Adding an
/// extension would have created a fourth place where a thickness could be set
/// and a fourth place where it could disagree with the others.
abstract final class IuxProgressResolver {
  /// Resolves the tokens in force at [context].
  static IuxProgressTokens resolve(BuildContext context) {
    final IuxAccessibility accessibility = IuxAccessibility.of(context);
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme typography = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);

    // High contrast thickens the bar for the same reason it thickens an
    // outline: the shape has to survive a screen the user is already
    // struggling to read. Text scaling thickens it too — someone who enlarged
    // their text has told you that four logical pixels are not enough, and a
    // progress bar that ignores that is legible for everyone except the
    // person who asked.
    final double base = math.max(
      geometry.spacingXxs,
      geometry.strongBorderWidth * 2,
    );
    final double thickness = accessibility.scaleText(base);

    // A single resolve would be enough for the fill tween. The traversal needs
    // the long scale, because it crosses the whole width rather than nudging
    // one value into another.
    final IuxResolvedMotion change = IuxMotionPolicy.resolve(
      context,
      role: IuxMotionRole.progress,
    );
    final IuxResolvedMotion sweep = IuxMotionPolicy.resolve(
      context,
      role: IuxMotionRole.progress,
      scale: IuxMotionScale.long,
    );

    return IuxProgressTokens(
      thickness: thickness,
      // A pill, derived from the height rather than from a radius token: a
      // fixed radius on a bar this thin produces a rectangle at one text scale
      // and a lozenge at another.
      radius: thickness / 2,
      track: colors.surface.subtle,
      fill: colors.action.primary.background,
      labelStyle: typography.body.copyWith(color: colors.content.primary),
      // The value is not supporting content. It is the answer to the only
      // question the user is asking, so it gets a content role that is
      // measured against the surface, not a de-emphasised one.
      valueStyle: typography.label.copyWith(color: colors.content.primary),
      motion: change,
      traversal: sweep.isAnimated ? _traversal(sweep) : Duration.zero,
    );
  }

  /// How long one crossing of the track lasts.
  ///
  /// A reduced-motion preference halves every transition, which is right for a
  /// transition and wrong for a loop: halving a cycle doubles how often the
  /// segment sweeps past, so the user who asked for less movement receives
  /// twice as much of it. The traversal therefore never drops below the
  /// standard baseline.
  static Duration _traversal(IuxResolvedMotion sweep) {
    final Duration requested = sweep.duration * _traversalFactor;
    final Duration floor = IuxMotionDuration.long * _traversalFactor;
    return requested < floor ? floor : requested;
  }
}

/// Decides when a screen reader hears the value again.
///
/// Separated from the widget so the rule can be read, tested and argued with
/// on its own. The widget applies it; it does not own it.
abstract final class IuxProgressAnnouncementPolicy {
  /// Whether the value moved far enough to be worth interrupting for.
  ///
  /// [announced] is the value in force the last time the user was told,
  /// [current] the value now, and [phaseChanged] whether the caller replaced
  /// the description of what is happening.
  ///
  /// A phase change always announces: "Uploading photos" becoming "Processing"
  /// is new information regardless of the number beside it. Reaching the end
  /// always announces too, because the last five percent are exactly the ones
  /// a user is waiting on and a milestone step would swallow them.
  static bool shouldAnnounce({
    required double announced,
    required double current,
    required bool phaseChanged,
  }) {
    if (phaseChanged) return true;
    if (current >= 1 && announced < 1) return true;
    // The slack is not tuning, it is arithmetic: 0.6 - 0.5 evaluates to
    // 0.09999999999999998 in binary floating point. Without it, the milestone
    // a caller most obviously reaches — a round tenth — would be the one
    // milestone that never announced.
    return (current - announced).abs() >=
        kIuxProgressAnnouncementStep - _floatingPointSlack;
  }

  static const double _floatingPointSlack = 1e-9;
}
