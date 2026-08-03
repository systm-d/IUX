import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// The complete color contract of one action intent, across its states.
///
/// Grouping the states of a single intent keeps a component from assembling an
/// action appearance out of unrelated roles, and makes an incoherent
/// combination impossible to express.
///
/// Interaction states do not merely lighten or darken: in light conditions an
/// action deepens as it is engaged, in dark conditions it brightens. Both
/// directions preserve the contrast of [foreground].
@immutable
final class IuxActionColors {
  /// Creates the immutable color contract of one action intent.
  const IuxActionColors({
    required this.foreground,
    required this.background,
    required this.border,
    required this.hoveredBackground,
    required this.pressedBackground,
    required this.disabledForeground,
    required this.disabledBackground,
  });

  /// The label and icon color, targeting 4.5:1 against every background state.
  final Color foreground;

  /// The resting background.
  final Color background;

  /// The outline, targeting 3:1 against the surface behind the action.
  final Color border;

  /// The background while a pointer rests on the action.
  ///
  /// Hover is unavailable on touch-only devices and must never be the sole
  /// carrier of information.
  final Color hoveredBackground;

  /// The background while the action is being activated.
  final Color pressedBackground;

  /// The label color when the action is unavailable.
  final Color disabledForeground;

  /// The background when the action is unavailable.
  final Color disabledBackground;

  /// Returns a copy with the given roles replaced.
  IuxActionColors copyWith({
    Color? foreground,
    Color? background,
    Color? border,
    Color? hoveredBackground,
    Color? pressedBackground,
    Color? disabledForeground,
    Color? disabledBackground,
  }) =>
      IuxActionColors(
        foreground: foreground ?? this.foreground,
        background: background ?? this.background,
        border: border ?? this.border,
        hoveredBackground: hoveredBackground ?? this.hoveredBackground,
        pressedBackground: pressedBackground ?? this.pressedBackground,
        disabledForeground: disabledForeground ?? this.disabledForeground,
        disabledBackground: disabledBackground ?? this.disabledBackground,
      );

  /// Linearly interpolates between two action color contracts.
  static IuxActionColors lerp(
    IuxActionColors a,
    IuxActionColors b,
    double t,
  ) =>
      IuxActionColors(
        foreground: Color.lerp(a.foreground, b.foreground, t)!,
        background: Color.lerp(a.background, b.background, t)!,
        border: Color.lerp(a.border, b.border, t)!,
        hoveredBackground:
            Color.lerp(a.hoveredBackground, b.hoveredBackground, t)!,
        pressedBackground:
            Color.lerp(a.pressedBackground, b.pressedBackground, t)!,
        disabledForeground:
            Color.lerp(a.disabledForeground, b.disabledForeground, t)!,
        disabledBackground:
            Color.lerp(a.disabledBackground, b.disabledBackground, t)!,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxActionColors &&
          other.foreground == foreground &&
          other.background == background &&
          other.border == border &&
          other.hoveredBackground == hoveredBackground &&
          other.pressedBackground == pressedBackground &&
          other.disabledForeground == disabledForeground &&
          other.disabledBackground == disabledBackground;

  @override
  int get hashCode => Object.hash(
        foreground,
        background,
        border,
        hoveredBackground,
        pressedBackground,
        disabledForeground,
        disabledBackground,
      );
}

/// The action intents an interface can express.
///
/// A component receives an intent and resolves its colors from the theme. It
/// never receives a color, so an action cannot look primary while behaving
/// destructively.
@immutable
final class IuxActionColorSet {
  /// Creates an immutable set of action intents.
  const IuxActionColorSet({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.destructive,
  });

  /// The single most important action of a view.
  final IuxActionColors primary;

  /// A supporting action of comparable legitimacy but lower priority.
  final IuxActionColors secondary;

  /// A low-emphasis action, typically without a filled background.
  final IuxActionColors tertiary;

  /// An action that destroys or irreversibly alters user data.
  ///
  /// Its distinctness must never rely on color alone: wording, confirmation
  /// and semantics carry the consequence.
  final IuxActionColors destructive;

  /// Returns a copy with the given intents replaced.
  IuxActionColorSet copyWith({
    IuxActionColors? primary,
    IuxActionColors? secondary,
    IuxActionColors? tertiary,
    IuxActionColors? destructive,
  }) =>
      IuxActionColorSet(
        primary: primary ?? this.primary,
        secondary: secondary ?? this.secondary,
        tertiary: tertiary ?? this.tertiary,
        destructive: destructive ?? this.destructive,
      );

  /// Linearly interpolates between two action intent sets.
  static IuxActionColorSet lerp(
    IuxActionColorSet a,
    IuxActionColorSet b,
    double t,
  ) =>
      IuxActionColorSet(
        primary: IuxActionColors.lerp(a.primary, b.primary, t),
        secondary: IuxActionColors.lerp(a.secondary, b.secondary, t),
        tertiary: IuxActionColors.lerp(a.tertiary, b.tertiary, t),
        destructive: IuxActionColors.lerp(a.destructive, b.destructive, t),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxActionColorSet &&
          other.primary == primary &&
          other.secondary == secondary &&
          other.tertiary == tertiary &&
          other.destructive == destructive;

  @override
  int get hashCode => Object.hash(primary, secondary, tertiary, destructive);
}
