import 'package:flutter/material.dart';

import '../../foundations/iux_foundations.dart';
import '../iux_theme_configuration.dart';

/// The conditions a theme was resolved for.
///
/// This extension answers "what was asked of this theme", which the other
/// extensions cannot: once colours are resolved, nothing in them records
/// whether high contrast was requested or merely happened to be dark.
///
/// Components read it to make behavioural decisions — whether to add a
/// non-colour indicator, whether to announce a change — as opposed to visual
/// ones, which the other extensions already carry.
@immutable
final class IuxAccessibilityTheme
    extends ThemeExtension<IuxAccessibilityTheme> {
  /// Creates a record of resolved conditions.
  const IuxAccessibilityTheme({
    required this.profile,
    required this.brightness,
  });

  /// Records the conditions of a configuration.
  factory IuxAccessibilityTheme.resolve(
    IuxThemeConfiguration configuration,
  ) =>
      IuxAccessibilityTheme(
        profile: configuration.profile,
        brightness: configuration.brightness,
      );

  /// The preferences this theme was resolved for.
  final IuxAccessibilityProfile profile;

  /// The brightness this theme was resolved for.
  final Brightness brightness;

  /// Whether contrast was explicitly reinforced.
  bool get isHighContrast => profile.contrast == IuxContrast.high;

  /// Whether the user asked for less movement.
  bool get prefersReducedMotion =>
      profile.motion == IuxMotionPreference.reduced ||
      profile.motion == IuxMotionPreference.none;

  /// Whether the user asked for less non-essential visual activity.
  bool get prefersReducedStimulation =>
      profile.visualStimulation == IuxVisualStimulation.reduced;

  /// The smallest interactive dimension this theme permits.
  double get minimumTouchTarget => profile.minimumTouchTarget;

  /// Resolves the accessibility record installed on the ambient theme.
  static IuxAccessibilityTheme of(BuildContext context) =>
      Theme.of(context).extension<IuxAccessibilityTheme>() ??
      (throw FlutterError(
        'No IuxAccessibilityTheme found. Install an IUX theme on your '
        'MaterialApp, for example theme: IuxTheme.light().',
      ));

  @override
  IuxAccessibilityTheme copyWith({
    IuxAccessibilityProfile? profile,
    Brightness? brightness,
  }) =>
      IuxAccessibilityTheme(
        profile: profile ?? this.profile,
        brightness: brightness ?? this.brightness,
      );

  @override
  IuxAccessibilityTheme lerp(
    covariant ThemeExtension<IuxAccessibilityTheme>? other,
    double t,
  ) {
    // Preferences are categorical. There is no state between "high contrast"
    // and "standard contrast", and inventing one would let a component read a
    // condition that was never requested.
    if (other is! IuxAccessibilityTheme) return this;
    return t < 0.5 ? this : other;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxAccessibilityTheme &&
          other.profile == profile &&
          other.brightness == brightness;

  @override
  int get hashCode => Object.hash(profile, brightness);
}
