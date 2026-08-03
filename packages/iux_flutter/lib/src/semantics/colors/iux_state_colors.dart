import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Interaction states that apply to any element, whatever its intent.
///
/// States scoped to a single action intent — hovered, pressed and disabled
/// backgrounds — belong to [IuxActionColors] instead, so an action never
/// assembles its appearance from two competing sources.
///
/// Two deliberate omissions:
///
/// - `disabled` has no entry here. Inactive elements use the dedicated
///   `disabled` roles of the content, surface and border groups rather than an
///   opacity applied to an active color, because an opacity over an unknown
///   background produces an unpredictable contrast ratio.
/// - `loading` has no color. A pending operation is communicated through
///   progress semantics and an accessible announcement, never through a hue.
@immutable
final class IuxStateColors {
  /// Creates an immutable set of transverse state roles.
  const IuxStateColors({
    required this.focus,
    required this.selected,
    required this.hovered,
    required this.pressed,
    required this.dragged,
  });

  /// The keyboard focus indicator.
  ///
  /// Targets 3:1 against adjacent surfaces. It must remain distinguishable
  /// from [selected]: focus says "where the keyboard is", selection says
  /// "what the user chose", and conflating them makes a list unusable with a
  /// keyboard or a screen reader.
  final Color focus;

  /// The indication that an element is chosen.
  ///
  /// Must be paired with a non-color signal such as a checkmark or the
  /// `selected` semantics flag.
  final Color selected;

  /// A tint applied while a pointer rests on an element.
  ///
  /// Unavailable on touch-only devices, so it may only reinforce information
  /// that is already available elsewhere.
  final Color hovered;

  /// A tint applied while an element is being activated.
  final Color pressed;

  /// A tint applied while an element is being moved.
  final Color dragged;

  /// Returns a copy with the given roles replaced.
  IuxStateColors copyWith({
    Color? focus,
    Color? selected,
    Color? hovered,
    Color? pressed,
    Color? dragged,
  }) =>
      IuxStateColors(
        focus: focus ?? this.focus,
        selected: selected ?? this.selected,
        hovered: hovered ?? this.hovered,
        pressed: pressed ?? this.pressed,
        dragged: dragged ?? this.dragged,
      );

  /// Linearly interpolates between two state role sets.
  static IuxStateColors lerp(
    IuxStateColors a,
    IuxStateColors b,
    double t,
  ) =>
      IuxStateColors(
        focus: Color.lerp(a.focus, b.focus, t)!,
        selected: Color.lerp(a.selected, b.selected, t)!,
        hovered: Color.lerp(a.hovered, b.hovered, t)!,
        pressed: Color.lerp(a.pressed, b.pressed, t)!,
        dragged: Color.lerp(a.dragged, b.dragged, t)!,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxStateColors &&
          other.focus == focus &&
          other.selected == selected &&
          other.hovered == hovered &&
          other.pressed == pressed &&
          other.dragged == dragged;

  @override
  int get hashCode => Object.hash(focus, selected, hovered, pressed, dragged);
}
