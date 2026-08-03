import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Colors for text, icons and other content rendered on a surface.
///
/// Roles express how important a piece of content is, not how it should look.
/// Emphasis decreases from [primary] to [tertiary]; contrast decreases with it.
/// Never use a lower-emphasis role to de-emphasise information the user needs
/// in order to act.
@immutable
final class IuxContentColors {
  /// Creates an immutable set of content roles.
  const IuxContentColors({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.disabled,
    required this.inverse,
    required this.onAction,
    required this.link,
  });

  /// Essential content: body text, headings, meaningful icons.
  ///
  /// Targets a 4.5:1 ratio against every surface it may appear on.
  final Color primary;

  /// Supporting content that qualifies primary content.
  ///
  /// Targets 4.5:1. Do not use it for information required to complete a task.
  final Color secondary;

  /// Incidental content such as timestamps or counters.
  ///
  /// Targets 4.5:1 so it stays readable, despite its lower visual weight.
  final Color tertiary;

  /// Content belonging to an inactive control.
  ///
  /// Targets 3:1 against the base and disabled surfaces. Disabled state must
  /// also be conveyed without color, through semantics and interaction.
  final Color disabled;

  /// Content rendered on [IuxSurfaceColors.inverse].
  final Color inverse;

  /// Content rendered on an action background, such as a button label.
  final Color onAction;

  /// Content that navigates or opens a resource.
  ///
  /// Color alone must not identify a link: pair it with an underline, an icon
  /// or an explicit affordance.
  final Color link;

  /// Returns a copy with the given roles replaced.
  IuxContentColors copyWith({
    Color? primary,
    Color? secondary,
    Color? tertiary,
    Color? disabled,
    Color? inverse,
    Color? onAction,
    Color? link,
  }) =>
      IuxContentColors(
        primary: primary ?? this.primary,
        secondary: secondary ?? this.secondary,
        tertiary: tertiary ?? this.tertiary,
        disabled: disabled ?? this.disabled,
        inverse: inverse ?? this.inverse,
        onAction: onAction ?? this.onAction,
        link: link ?? this.link,
      );

  /// Linearly interpolates between two content role sets.
  static IuxContentColors lerp(
    IuxContentColors a,
    IuxContentColors b,
    double t,
  ) =>
      IuxContentColors(
        primary: Color.lerp(a.primary, b.primary, t)!,
        secondary: Color.lerp(a.secondary, b.secondary, t)!,
        tertiary: Color.lerp(a.tertiary, b.tertiary, t)!,
        disabled: Color.lerp(a.disabled, b.disabled, t)!,
        inverse: Color.lerp(a.inverse, b.inverse, t)!,
        onAction: Color.lerp(a.onAction, b.onAction, t)!,
        link: Color.lerp(a.link, b.link, t)!,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxContentColors &&
          other.primary == primary &&
          other.secondary == secondary &&
          other.tertiary == tertiary &&
          other.disabled == disabled &&
          other.inverse == inverse &&
          other.onAction == onAction &&
          other.link == link;

  @override
  int get hashCode => Object.hash(
        primary,
        secondary,
        tertiary,
        disabled,
        inverse,
        onAction,
        link,
      );
}
