import 'package:flutter/material.dart';

import '../../foundations/iux_foundations.dart';
import '../iux_theme_configuration.dart';

/// Resolved motion durations and curves.
///
/// Motion in IUX answers a question — what just happened, where did that go,
/// what should I look at. A duration that answers no question is decoration,
/// and decoration is what a reduced-motion preference removes first.
///
/// The theme resolves the *requested* preference. It cannot read
/// `MediaQuery.disableAnimations`, because a theme is built statically, before
/// any context exists. Reconciling the platform preference with the requested
/// one is the widget layer's job, delivered by IUX-005 and IUX-006. Until
/// then, [IuxMotionPreference.system] resolves as standard motion, and
/// [respectsPlatformPreference] records that the decision is still pending.
@immutable
final class IuxMotionTheme extends ThemeExtension<IuxMotionTheme> {
  /// Creates a resolved motion set.
  const IuxMotionTheme({
    required this.instant,
    required this.short,
    required this.standard,
    required this.long,
    required this.enter,
    required this.exit,
    required this.change,
    required this.allowsNonEssentialMotion,
    required this.respectsPlatformPreference,
  });

  /// Resolves motion for a configuration.
  factory IuxMotionTheme.resolve(IuxThemeConfiguration configuration) {
    final IuxMotionPreference motion = configuration.motion;
    final bool reduced = motion == IuxMotionPreference.reduced;
    final bool none = motion == IuxMotionPreference.none;

    // Reduced motion shortens; no motion removes. A state change still
    // happens in both cases — it is the travel that is cut, never the
    // feedback that something occurred.
    Duration scale(Duration value) {
      if (none) return Duration.zero;
      if (reduced) {
        return Duration(microseconds: (value.inMicroseconds * 0.5).round());
      }
      return value;
    }

    return IuxMotionTheme(
      instant: Duration.zero,
      short: scale(IuxMotionDuration.short),
      standard: scale(IuxMotionDuration.standard),
      long: scale(IuxMotionDuration.long),
      // Reduced motion also means simpler easing: an emphasised curve draws
      // attention to the movement itself, which is the opposite of the intent.
      enter: reduced || none ? Curves.linear : IuxMotionCurve.enter,
      exit: reduced || none ? Curves.linear : IuxMotionCurve.exit,
      change: reduced || none ? Curves.linear : IuxMotionCurve.change,
      allowsNonEssentialMotion: !reduced &&
          !none &&
          configuration.visualStimulation == IuxVisualStimulation.standard,
      respectsPlatformPreference: motion == IuxMotionPreference.system,
    );
  }

  /// No duration. Used when motion is disabled.
  final Duration instant;

  /// A brief state change, such as a press.
  final Duration short;

  /// The default transition duration.
  final Duration standard;

  /// A transition covering a large distance or a full screen.
  final Duration long;

  /// Easing for an element appearing.
  final Curve enter;

  /// Easing for an element leaving.
  final Curve exit;

  /// Easing for an element changing in place.
  final Curve change;

  /// Whether motion that carries no information is permitted.
  ///
  /// A component must check this before animating anything decorative. Motion
  /// that answers a question stays, and uses [short] or [standard], which are
  /// already shortened when the user asked for less.
  final bool allowsNonEssentialMotion;

  /// Whether the platform preference still has to be consulted at runtime.
  ///
  /// True when the configuration asked for [IuxMotionPreference.system]. The
  /// theme could not resolve it, so a widget must.
  final bool respectsPlatformPreference;

  /// Resolves the motion theme installed on the ambient theme.
  static IuxMotionTheme of(BuildContext context) =>
      Theme.of(context).extension<IuxMotionTheme>() ??
      (throw FlutterError(
        'No IuxMotionTheme found. Install an IUX theme on your MaterialApp, '
        'for example theme: IuxTheme.light().',
      ));

  @override
  IuxMotionTheme copyWith({
    Duration? instant,
    Duration? short,
    Duration? standard,
    Duration? long,
    Curve? enter,
    Curve? exit,
    Curve? change,
    bool? allowsNonEssentialMotion,
    bool? respectsPlatformPreference,
  }) =>
      IuxMotionTheme(
        instant: instant ?? this.instant,
        short: short ?? this.short,
        standard: standard ?? this.standard,
        long: long ?? this.long,
        enter: enter ?? this.enter,
        exit: exit ?? this.exit,
        change: change ?? this.change,
        allowsNonEssentialMotion:
            allowsNonEssentialMotion ?? this.allowsNonEssentialMotion,
        respectsPlatformPreference:
            respectsPlatformPreference ?? this.respectsPlatformPreference,
      );

  @override
  IuxMotionTheme lerp(
    covariant ThemeExtension<IuxMotionTheme>? other,
    double t,
  ) {
    if (other is! IuxMotionTheme) return this;
    Duration lerpDuration(Duration a, Duration b) => Duration(
          microseconds:
              (a.inMicroseconds + (b.inMicroseconds - a.inMicroseconds) * t)
                  .round(),
        );
    // Curves and the two flags switch at the halfway point rather than
    // blending: there is no meaningful value between "decoration allowed" and
    // "decoration forbidden", and a half-applied permission is worse than
    // either end.
    final bool second = t >= 0.5;
    return IuxMotionTheme(
      instant: Duration.zero,
      short: lerpDuration(short, other.short),
      standard: lerpDuration(standard, other.standard),
      long: lerpDuration(long, other.long),
      enter: second ? other.enter : enter,
      exit: second ? other.exit : exit,
      change: second ? other.change : change,
      allowsNonEssentialMotion:
          second ? other.allowsNonEssentialMotion : allowsNonEssentialMotion,
      respectsPlatformPreference: second
          ? other.respectsPlatformPreference
          : respectsPlatformPreference,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxMotionTheme &&
          other.instant == instant &&
          other.short == short &&
          other.standard == standard &&
          other.long == long &&
          other.enter == enter &&
          other.exit == exit &&
          other.change == change &&
          other.allowsNonEssentialMotion == allowsNonEssentialMotion &&
          other.respectsPlatformPreference == respectsPlatformPreference;

  @override
  int get hashCode => Object.hash(
        instant,
        short,
        standard,
        long,
        enter,
        exit,
        change,
        allowsNonEssentialMotion,
        respectsPlatformPreference,
      );
}
