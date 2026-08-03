import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Backgrounds that establish interface hierarchy.
///
/// Surfaces separate levels through color contrast, so hierarchy survives when
/// shadows are unavailable, invisible in dark conditions, or removed by a
/// reduced visual stimulation preference. A component must never rely on a
/// shadow alone to express its level.
@immutable
final class IuxSurfaceColors {
  /// Creates an immutable set of surface roles.
  const IuxSurfaceColors({
    required this.base,
    required this.subtle,
    required this.raised,
    required this.overlay,
    required this.interactive,
    required this.selected,
    required this.disabled,
    required this.inverse,
  });

  /// The background of a screen.
  final Color base;

  /// A recessed grouping surface used to associate related content.
  final Color subtle;

  /// A surface presented above [base], such as a card.
  final Color raised;

  /// A surface presented above the page, such as a dialog or sheet.
  final Color overlay;

  /// The resting background of an interactive area.
  final Color interactive;

  /// The background of a selected element.
  ///
  /// Selection must also be conveyed without color, and must stay visually
  /// distinct from focus.
  final Color selected;

  /// The background of an inactive control.
  final Color disabled;

  /// A surface whose content uses [IuxContentColors.inverse].
  final Color inverse;

  /// Returns a copy with the given roles replaced.
  IuxSurfaceColors copyWith({
    Color? base,
    Color? subtle,
    Color? raised,
    Color? overlay,
    Color? interactive,
    Color? selected,
    Color? disabled,
    Color? inverse,
  }) =>
      IuxSurfaceColors(
        base: base ?? this.base,
        subtle: subtle ?? this.subtle,
        raised: raised ?? this.raised,
        overlay: overlay ?? this.overlay,
        interactive: interactive ?? this.interactive,
        selected: selected ?? this.selected,
        disabled: disabled ?? this.disabled,
        inverse: inverse ?? this.inverse,
      );

  /// Linearly interpolates between two surface role sets.
  static IuxSurfaceColors lerp(
    IuxSurfaceColors a,
    IuxSurfaceColors b,
    double t,
  ) =>
      IuxSurfaceColors(
        base: Color.lerp(a.base, b.base, t)!,
        subtle: Color.lerp(a.subtle, b.subtle, t)!,
        raised: Color.lerp(a.raised, b.raised, t)!,
        overlay: Color.lerp(a.overlay, b.overlay, t)!,
        interactive: Color.lerp(a.interactive, b.interactive, t)!,
        selected: Color.lerp(a.selected, b.selected, t)!,
        disabled: Color.lerp(a.disabled, b.disabled, t)!,
        inverse: Color.lerp(a.inverse, b.inverse, t)!,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxSurfaceColors &&
          other.base == base &&
          other.subtle == subtle &&
          other.raised == raised &&
          other.overlay == overlay &&
          other.interactive == interactive &&
          other.selected == selected &&
          other.disabled == disabled &&
          other.inverse == inverse;

  @override
  int get hashCode => Object.hash(
        base,
        subtle,
        raised,
        overlay,
        interactive,
        selected,
        disabled,
        inverse,
      );
}
