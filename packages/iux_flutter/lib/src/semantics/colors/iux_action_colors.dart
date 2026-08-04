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
    required this.hoveredBackground,
    required this.pressedBackground,
    required this.disabledForeground,
    required this.disabledBackground,
  });

  /// The label and icon color, targeting 4.5:1 against every background state.
  ///
  /// It is also the outline of an unfilled variant, which is why it is
  /// measured against the *page* as well: an outline has to reach 3:1 under
  /// WCAG 2.2 SC 1.4.11, and 4.5:1 clears that.
  final Color foreground;

  /// The resting background.
  ///
  /// For an intent the layer models unfilled — [IuxActionColorSet.secondary]
  /// and [IuxActionColorSet.tertiary] — this is the page surface, and that is
  /// a statement rather than a placeholder: those intents have no fill, and
  /// `IuxButtonResolver` refuses to draw them filled.
  final Color background;

  // There is no `border`. One existed until IUX-039, was documented as "the
  // outline, targeting 3:1 against the surface behind the action", and was
  // painted by nothing: the only variant that read it was `filled`, whose
  // outline width is zero except when disabled — and the disabled palette
  // overrides the colour with `border.disabled` anyway. It was also the only
  // unmeasured colour in this file, which is how two of the four shipped
  // profiles came to set it to the page surface itself, i.e. to an invisible
  // outline, without any test noticing.
  //
  // It did do one thing, and the thing was harmful: it was the sole difference
  // between the secondary and tertiary role definitions, so reading this file
  // suggested the two intents were distinct while every pixel they produced was
  // identical. Wiring it up instead was refused. An outline that must clear
  // 3:1 on the page while the label it encloses clears 4.5:1 has one sensible
  // value — the label's — and a knob with one correct setting is a knob that
  // will eventually be set wrongly (PROJECT_PROMPT §19, §20).

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
    Color? hoveredBackground,
    Color? pressedBackground,
    Color? disabledForeground,
    Color? disabledBackground,
  }) =>
      IuxActionColors(
        foreground: foreground ?? this.foreground,
        background: background ?? this.background,
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
          other.hoveredBackground == hoveredBackground &&
          other.pressedBackground == pressedBackground &&
          other.disabledForeground == disabledForeground &&
          other.disabledBackground == disabledBackground;

  @override
  int get hashCode => Object.hash(
        foreground,
        background,
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
  ///
  /// Unfilled: its accent lives in [IuxActionColors.foreground] and its
  /// [IuxActionColors.background] is the page.
  final IuxActionColors secondary;

  /// An action that leads away from the task rather than through it.
  ///
  /// Unfilled like [secondary], and the one intent drawn *without* the accent:
  /// its foreground is a neutral that clears 4.5:1 on every background it can
  /// appear on, in all four shipped profiles. It is quieter by hue, never by
  /// contrast — reducing contrast to express low emphasis is the failure WCAG
  /// 2.2 SC 1.4.3 exists to catch, and it would fail exactly the reader who
  /// most needs the label.
  ///
  /// This is what makes the intent legible on screen at all. Until IUX-039 it
  /// differed from [secondary] by a single token nothing painted.
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
