import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Colors for outlines, dividers and focus indication.
///
/// A border role carries no thickness: geometry belongs to the foundations, so
/// the same role can be drawn thicker under a high contrast preference without
/// changing its meaning.
///
/// The role named `borderDefault` in the IUX specification is exposed here as
/// [standard], because `default` is a reserved Dart word.
@immutable
final class IuxBorderColors {
  /// Creates an immutable set of border roles.
  const IuxBorderColors({
    required this.standard,
    required this.subtle,
    required this.strong,
    required this.interactive,
    required this.focus,
    required this.selected,
    required this.disabled,
    required this.error,
  });

  /// The outline of a control whose boundary identifies it.
  ///
  /// Targets 3:1 against the surface behind it.
  final Color standard;

  /// A decorative separator that groups content.
  ///
  /// Exempt from the 3:1 minimum because removing it must not prevent any
  /// task. Never use it to delimit an interactive control.
  final Color subtle;

  /// An outline that must remain visible under adverse conditions.
  final Color strong;

  /// The resting outline of an interactive control.
  final Color interactive;

  /// The keyboard focus indicator.
  ///
  /// Must stay distinct from [selected] and from any error indication, and
  /// must never be removed without an equally visible replacement.
  final Color focus;

  /// The outline of a selected element.
  final Color selected;

  /// The outline of an inactive control.
  final Color disabled;

  /// The outline of a control holding an invalid value.
  ///
  /// Always accompanied by a message: color alone must not report an error.
  final Color error;

  /// Returns a copy with the given roles replaced.
  IuxBorderColors copyWith({
    Color? standard,
    Color? subtle,
    Color? strong,
    Color? interactive,
    Color? focus,
    Color? selected,
    Color? disabled,
    Color? error,
  }) =>
      IuxBorderColors(
        standard: standard ?? this.standard,
        subtle: subtle ?? this.subtle,
        strong: strong ?? this.strong,
        interactive: interactive ?? this.interactive,
        focus: focus ?? this.focus,
        selected: selected ?? this.selected,
        disabled: disabled ?? this.disabled,
        error: error ?? this.error,
      );

  /// Linearly interpolates between two border role sets.
  static IuxBorderColors lerp(
    IuxBorderColors a,
    IuxBorderColors b,
    double t,
  ) =>
      IuxBorderColors(
        standard: Color.lerp(a.standard, b.standard, t)!,
        subtle: Color.lerp(a.subtle, b.subtle, t)!,
        strong: Color.lerp(a.strong, b.strong, t)!,
        interactive: Color.lerp(a.interactive, b.interactive, t)!,
        focus: Color.lerp(a.focus, b.focus, t)!,
        selected: Color.lerp(a.selected, b.selected, t)!,
        disabled: Color.lerp(a.disabled, b.disabled, t)!,
        error: Color.lerp(a.error, b.error, t)!,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxBorderColors &&
          other.standard == standard &&
          other.subtle == subtle &&
          other.strong == strong &&
          other.interactive == interactive &&
          other.focus == focus &&
          other.selected == selected &&
          other.disabled == disabled &&
          other.error == error;

  @override
  int get hashCode => Object.hash(
        standard,
        subtle,
        strong,
        interactive,
        focus,
        selected,
        disabled,
        error,
      );
}
