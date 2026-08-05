import 'package:flutter/material.dart';

import '../../actions/iux_action_descriptor.dart';
import '../../actions/iux_action_model.dart';
import '../../semantics/colors/iux_action_colors.dart';
import '../../semantics/iux_semantic_colors.dart';
import '../iux_theme_configuration.dart';
import 'iux_geometry_theme.dart';
import 'iux_typography_theme.dart';

/// How much visual weight a button carries.
///
/// The variant is emphasis; the action's intent is meaning. They are set
/// separately because the same action can be prominent on one screen and
/// discreet on another without changing what it does.
enum IuxButtonVariant {
  /// A solid fill. The most prominent.
  ///
  /// Only [IuxActionIntent.primary] and [IuxActionIntent.destructive] have a
  /// fill to draw. Asking for one on the other two intents is refused rather
  /// than approximated: see [IuxButtonResolver].
  filled,

  /// An outline on the page background.
  outlined,

  /// A soft container. The lowest-emphasis variant that still reads as a
  /// button.
  ///
  /// Not available for a destructive action: see [IuxButtonTokens].
  tonal,

  /// Label only, no container.
  text,

  /// A square target carrying an icon and no label.
  icon,
}

/// The single visual state a button resolves to.
///
/// Focus is deliberately absent. A focus indicator must be visible whatever
/// else is true — including while pressed or loading — so it cannot be a value
/// in a list where one wins. It is drawn additively by [IuxFocusable], outside
/// the container, and never resolved here.
///
/// The operation is absent too, and for the reason that removed three members
/// from this enum across two missions. `success` and `error` went at IUX-038,
/// `loading` at IUX-040; all three were computed, documented with a precedence,
/// and byte-identical to [enabled] in every token, on all four colour profiles,
/// in all seventeen legal intent/variant pairs — 68 cells measured, 68
/// collisions. A lifecycle painted on the container would be a colour and
/// nothing else, which the component standard refuses for exactly the user it
/// fails.
///
/// Being inert was never the cost. All three sat *above* [pressed] or [hovered]
/// in the resolver's precedence, so the rung that showed nothing swallowed the
/// feedback the rungs beneath it existed to give: a settled button stopped
/// answering the pointer before IUX-038, and a running one that genuinely
/// accepted a second tap did the same until IUX-040. Ranking above something
/// requires having something to say.
///
/// A lifecycle belongs in wording — see `IuxAsyncActionButton`, which swaps the
/// label for the caller's busy word and shows the failure message the operation
/// supplied.
enum IuxButtonState {
  /// Resting and available.
  ///
  /// Also the state of a control whose action is running: what says it is
  /// running is the word the caller supplies, never this.
  enabled,

  /// Unavailable.
  disabled,

  /// A pointer is resting on it, and a tap would run something.
  hovered,

  /// Being activated.
  pressed,
}

/// Everything needed to paint a button, and nothing about how to paint it.
///
/// A button widget reads this. It never reaches for a semantic role itself,
/// so the mapping from action to appearance exists in one place and cannot
/// drift between the button, the icon button and the future async button.
@immutable
final class IuxButtonTokens {
  /// Creates a resolved appearance.
  const IuxButtonTokens({
    required this.state,
    required this.background,
    required this.foreground,
    required this.border,
    required this.borderWidth,
    required this.radius,
    required this.padding,
    required this.minimumSize,
    required this.iconSize,
    required this.iconGap,
    required this.textStyle,
  });

  /// The state these tokens were resolved for.
  final IuxButtonState state;

  /// The container colour.
  final Color background;

  /// The label and icon colour.
  final Color foreground;

  /// The outline colour.
  final Color border;

  /// The outline width. Zero means no outline.
  final double borderWidth;

  /// The corner radius.
  final double radius;

  /// Padding inside the container.
  final EdgeInsets padding;

  /// The smallest permitted interactive dimension.
  final double minimumSize;

  /// Icon edge length.
  final double iconSize;

  /// Space between an icon and a label.
  final double iconGap;

  /// The label style, already carrying [foreground].
  final TextStyle textStyle;

  // There is no `focused` field, and adding one would be a regression rather
  // than a feature. These tokens are resolved in `build`, above the
  // `IuxFocusable` that owns the focus state, so feeding one back in would mean
  // tracking focus twice. And a token-driven ring could only be painted by the
  // container's own decoration — *inside* the control, covering the content it
  // identifies, which is the failure WCAG 2.2 SC 2.4.11 was added for and the
  // reason `IuxFocusRing` draws outside. One channel, and it is the correct
  // one. (IUX-BUTTON-DEAD-001.)

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxButtonTokens &&
          other.state == state &&
          other.background == background &&
          other.foreground == foreground &&
          other.border == border &&
          other.borderWidth == borderWidth &&
          other.radius == radius &&
          other.padding == padding &&
          other.minimumSize == minimumSize &&
          other.iconSize == iconSize &&
          other.iconGap == iconGap &&
          other.textStyle == textStyle;

  @override
  int get hashCode => Object.hashAll(<Object>[
        state,
        background,
        foreground,
        border,
        borderWidth,
        radius,
        padding,
        minimumSize,
        iconSize,
        iconGap,
        textStyle,
      ]);
}

/// Tunables an application may adjust for every button at once.
///
/// One extension rather than a field-per-resolver family. These values are
/// read together every time a button is built, and separating them would
/// produce extensions that are never independently useful.
@immutable
final class IuxButtonTheme extends ThemeExtension<IuxButtonTheme> {
  /// Creates a button theme.
  const IuxButtonTheme({
    this.shape = IuxButtonShape.medium,
    this.iconSize = 20,
  });

  // There is no `variant`. One existed until IUX-039 and held the variant used
  // when a call site named none — a single constant, `filled`, for all four
  // intents. Two of them have no fill, so the most ordinary button in the
  // package resolved to a container that was exactly the page it sat on. The
  // default now comes from the action, through
  // `IuxButtonResolver.defaultVariantFor`, which is the only place that can
  // know which containers an intent actually owns.
  //
  // Keeping it as an application-wide override was refused. It would have had
  // to be ignored for secondary and tertiary to stay legal, which is the same
  // silent discard this mission removed one line further down; and nothing in
  // `lib/`, `test/` or `apps/` ever set it to anything but the default.

  /// The corner treatment.
  final IuxButtonShape shape;

  // There is no `elevateFilled`, and no elevation in the resolved tokens.
  // One existed until IUX-038 and no widget ever read it: setting it produced
  // a byte-identical decoration while the resolver reported a shadow it had
  // computed, which is worse than a missing switch because it looks like it
  // works. Wiring it up instead was refused. PROJECT_PROMPT §20 names
  // `elevation:` as the archetype of a parameter a button should not take;
  // `IuxSurface`, `IuxCard`, `IuxContentGroup` and `IuxAppBar` all rest
  // hierarchy on colour and resolve elevation to zero; and a shadow vanishes
  // under a reduced visual stimulation preference, so any separation resting
  // on it is separation some users never receive. A filled button is already
  // distinguished from its background by a contrast-measured fill.

  /// Icon edge length, in logical pixels before text scaling.
  final double iconSize;

  /// Resolves the button theme installed on the ambient theme.
  ///
  /// Falls back to defaults rather than throwing: a button with no explicit
  /// theme should still render correctly.
  static IuxButtonTheme of(BuildContext context) =>
      Theme.of(context).extension<IuxButtonTheme>() ?? const IuxButtonTheme();

  @override
  IuxButtonTheme copyWith({
    IuxButtonShape? shape,
    double? iconSize,
  }) =>
      IuxButtonTheme(
        shape: shape ?? this.shape,
        iconSize: iconSize ?? this.iconSize,
      );

  @override
  IuxButtonTheme lerp(
    covariant ThemeExtension<IuxButtonTheme>? other,
    double t,
  ) {
    if (other is! IuxButtonTheme) return this;
    return IuxButtonTheme(
      // Shape is categorical; a half-applied corner treatment is not one.
      shape: t < 0.5 ? shape : other.shape,
      iconSize: iconSize + (other.iconSize - iconSize) * t,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxButtonTheme &&
          other.shape == shape &&
          other.iconSize == iconSize;

  @override
  int get hashCode => Object.hash(shape, iconSize);
}

/// Corner treatments a button may take.
enum IuxButtonShape {
  /// Square corners.
  none,

  /// A small radius.
  subtle,

  /// The default.
  medium,

  /// A large radius.
  prominent,

  /// Fully rounded ends.
  full,
}

/// Resolves an action and its interaction into a single visual state.
///
/// The precedence is fixed here so two components cannot disagree about what a
/// pressed-while-loading button looks like.
abstract final class IuxButtonStateResolver {
  /// The state to render.
  ///
  /// Precedence, highest first:
  ///
  /// 1. `disabled` — nothing else matters if it cannot be used;
  /// 2. `pressed` — activation feedback must never be swallowed, otherwise
  ///    the user cannot tell their tap registered;
  /// 3. `hovered`;
  /// 4. `enabled`.
  ///
  /// **Engagement feedback is offered exactly when engaging would run
  /// something.** [IuxActionDescriptor.isActivatable] is the same question the
  /// tap action and the gesture handlers ask, so the container cannot come to
  /// promise a tap the policy will decline. It answers *no* in two cases, and
  /// they resolve differently on purpose: an unavailable action is `disabled`,
  /// because the user is owed the state the control is actually in; an action
  /// that is merely running is `enabled`, because it *is* enabled — it is
  /// working. What withholds the hover tint there is not a busy palette but the
  /// absence of anything to promise.
  ///
  /// The operation is not a rung, and it was one until IUX-040. `loading` sat
  /// second and resolved to the resting palette, so a running action whose
  /// repeat policy accepts a second tap answered neither the pointer nor the
  /// finger — the same shape as the `error` and `success` rungs IUX-038 removed
  /// on the same grounds. Ranking above something requires having something to
  /// say. What a running action has to say is a word, and only
  /// `IuxAsyncActionButton` has one to show.
  ///
  /// Focus is not in this list either, but for the opposite reason: it must
  /// stay visible in every one of these states, so it cannot be a value where
  /// one wins. `IuxFocusable` draws it outside the container.
  static IuxButtonState resolve(
    IuxActionDescriptor action, {
    bool hovered = false,
    bool pressed = false,
  }) {
    if (action.availability == IuxActionAvailability.disabled) {
      return IuxButtonState.disabled;
    }
    if (action.isActivatable) {
      if (pressed) return IuxButtonState.pressed;
      if (hovered) return IuxButtonState.hovered;
    }
    return IuxButtonState.enabled;
  }
}

/// Resolves the complete appearance of a button.
///
/// The only entry point a button widget needs.
abstract final class IuxButtonResolver {
  /// The variant an action is drawn with when no call site names one.
  ///
  /// Two axes, and each answers a different question. The intent says which
  /// containers are *available*: [IuxActionIntent.primary] and
  /// [IuxActionIntent.destructive] own a fill, the other two do not, so their
  /// ladders start one rung lower. [IuxActionDescriptor.importance] then
  /// chooses a rung.
  ///
  /// | | primary, destructive | secondary, tertiary |
  /// |---|---|---|
  /// | high | filled | outlined |
  /// | medium | outlined | tonal |
  /// | low | text | text |
  ///
  /// This replaced a single `IuxButtonTheme.variant` constant that defaulted
  /// to `filled` for everything. That default was wrong for half the intents
  /// and silently so: a plain `IuxActionDescriptor` is secondary, so the most
  /// ordinary button in the package resolved to a fill that equalled the page
  /// and an outline of width zero — a label floating on the background. One
  /// value cannot be the right default for four intents, and the honest way to
  /// say that is to let the action answer.
  ///
  /// Deriving a default is not the same failure as discarding a request. A
  /// call site that names `variant:` always gets it, or an assertion saying
  /// why it cannot have it.
  static IuxButtonVariant defaultVariantFor(IuxActionDescriptor action) =>
      switch ((action.intent, action.importance)) {
        (
          IuxActionIntent.primary || IuxActionIntent.destructive,
          IuxActionImportance.high
        ) =>
          IuxButtonVariant.filled,
        (
          IuxActionIntent.primary || IuxActionIntent.destructive,
          IuxActionImportance.medium
        ) =>
          IuxButtonVariant.outlined,
        (
          IuxActionIntent.secondary || IuxActionIntent.tertiary,
          IuxActionImportance.high
        ) =>
          IuxButtonVariant.outlined,
        (
          IuxActionIntent.secondary || IuxActionIntent.tertiary,
          IuxActionImportance.medium
        ) =>
          IuxButtonVariant.tonal,
        (_, IuxActionImportance.low) => IuxButtonVariant.text,
      };

  /// Resolves [action] into paintable tokens.
  static IuxButtonTokens resolve(
    BuildContext context,
    IuxActionDescriptor action, {
    IuxButtonVariant? variant,
    bool hovered = false,
    bool pressed = false,
    bool hasLabel = true,
  }) {
    final IuxButtonTheme theme = IuxButtonTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme typography = IuxTypographyTheme.of(context);

    final IuxButtonVariant resolvedVariant =
        variant ?? defaultVariantFor(action);
    assert(
      !(resolvedVariant == IuxButtonVariant.tonal &&
          action.intent == IuxActionIntent.destructive),
      'A destructive action must not use the tonal variant. Tonal is the '
      'lowest-emphasis container, and it carries intent through its border '
      'rather than its fill — which is not enough separation for an action '
      'that destroys data. Use filled or outlined.',
    );
    assert(
      !(resolvedVariant == IuxButtonVariant.filled &&
          (action.intent == IuxActionIntent.secondary ||
              action.intent == IuxActionIntent.tertiary)),
      'A secondary or tertiary action has no fill to draw. The semantic layer '
      'models both as unfilled: their background *is* the page surface, and '
      'their accent lives in the foreground. Asking for filled therefore '
      'painted the page over the page and produced a control with no '
      'container at all — measured byte-identical to the text variant, which '
      'is a button a user cannot identify as one (WCAG 2.2 SC 1.4.11). It was '
      'accepted and discarded in silence until IUX-039. Inventing a fill for '
      'these intents was refused rather than deferred: one filled action per '
      'group is what makes the primary readable as the primary, and a second '
      'fill takes that away from every screen at once. Use outlined, tonal or '
      'text — or, if this really is the dominant action here, say so with '
      'IuxActionIntent.primary.',
    );

    final IuxActionColors actionColors = switch (action.intent) {
      IuxActionIntent.primary => colors.action.primary,
      IuxActionIntent.secondary => colors.action.secondary,
      IuxActionIntent.tertiary => colors.action.tertiary,
      IuxActionIntent.destructive => colors.action.destructive,
    };

    final IuxButtonState state = IuxButtonStateResolver.resolve(
      action,
      hovered: hovered,
      pressed: pressed,
    );

    final _Palette palette = _resolveColors(
      variant: resolvedVariant,
      state: state,
      intent: action.intent,
      action: actionColors,
      colors: colors,
    );

    final double radius = switch (theme.shape) {
      IuxButtonShape.none => 0,
      IuxButtonShape.subtle => geometry.radiusSubtle,
      IuxButtonShape.medium => geometry.radiusMedium,
      IuxButtonShape.prominent => geometry.radiusProminent,
      // Resolved against the button's own height by the widget.
      IuxButtonShape.full => double.infinity,
    };

    final bool square = resolvedVariant == IuxButtonVariant.icon || !hasLabel;

    return IuxButtonTokens(
      state: state,
      background: palette.background,
      foreground: palette.foreground,
      border: palette.border,
      borderWidth: _borderWidth(resolvedVariant, state, geometry),
      radius: radius,
      padding: square
          ? EdgeInsets.all(geometry.spacingXs)
          : EdgeInsets.symmetric(
              horizontal: geometry.spacingMd,
              vertical: geometry.spacingXs,
            ),
      minimumSize: geometry.minimumTouchTarget,
      iconSize: theme.iconSize,
      iconGap: geometry.spacingXs,
      textStyle: typography.label.copyWith(color: palette.foreground),
    );
  }

  static _Palette _resolveColors({
    required IuxButtonVariant variant,
    required IuxButtonState state,
    required IuxActionIntent intent,
    required IuxActionColors action,
    required IuxSemanticColors colors,
  }) {
    if (state == IuxButtonState.disabled) {
      return _Palette(
        background: variant == IuxButtonVariant.filled
            ? action.disabledBackground
            : colors.surface.base,
        foreground: action.disabledForeground,
        border: colors.border.disabled,
      );
    }

    // Which role carries the intent's accent — the colour that must read as
    // text on the page background, and that also draws the outline of every
    // unfilled variant.
    //
    // The semantic layer already models secondary and tertiary as unfilled:
    // their `background` *is* the page surface and their accent lives in
    // `foreground`. Primary and destructive are filled, so theirs is in
    // `background`. Assuming one of the two universally produced a white
    // label on a white surface, which the contrast test caught.
    //
    // This is the one colour that separates one intent from another once the
    // container is decided, which is why `IuxActionColors` no longer carries a
    // separate `border`: an outline that disagreed with the label it encloses
    // would be a second intent signal to keep in step, and the one time the
    // two disagreed — tertiary's outline set to the page surface itself —
    // nothing painted it and nothing measured it.
    //
    // A brand theme that fills secondary must revisit this. Every
    // variant/intent/state pair is measured, so it fails loudly rather than
    // shipping an invisible control.
    final Color accent = switch (intent) {
      IuxActionIntent.primary ||
      IuxActionIntent.destructive =>
        action.background,
      IuxActionIntent.secondary ||
      IuxActionIntent.tertiary =>
        action.foreground,
    };

    // The engaged background for a variant that has a fill of its own.
    Color engaged(Color resting) => switch (state) {
          IuxButtonState.pressed => action.pressedBackground,
          IuxButtonState.hovered => action.hoveredBackground,
          _ => resting,
        };

    // The engaged background for a variant that has none: a tint over the
    // page, never the intent's fill, which would turn an outlined button into
    // a filled one on hover.
    Color tinted(Color resting) => switch (state) {
          IuxButtonState.pressed => colors.state.pressed,
          IuxButtonState.hovered => colors.state.hovered,
          _ => resting,
        };

    return switch (variant) {
      // A filled button draws no outline (`_borderWidth` returns zero), so its
      // border is the fill: a token nothing paints must not carry a colour
      // nobody chose, or the next reader will believe it is painted.
      IuxButtonVariant.filled => _Palette(
          background: engaged(action.background),
          foreground: action.foreground,
          border: engaged(action.background),
        ),
      IuxButtonVariant.outlined => _Palette(
          background: tinted(colors.surface.base),
          foreground: accent,
          border: accent,
        ),
      // Tonal carries intent through its border, not its fill. The semantic
      // layer has no per-intent container role, and inventing one here would
      // ship a colour pair nobody measured. surface.selected with
      // content.primary is already verified on all four profiles.
      IuxButtonVariant.tonal => _Palette(
          background: tinted(colors.surface.selected),
          foreground: colors.content.primary,
          border: accent,
        ),
      IuxButtonVariant.text || IuxButtonVariant.icon => _Palette(
          background: tinted(colors.surface.base),
          foreground: accent,
          border: colors.surface.base,
        ),
    };
  }

  static double _borderWidth(
    IuxButtonVariant variant,
    IuxButtonState state,
    IuxGeometryTheme geometry,
  ) =>
      switch (variant) {
        IuxButtonVariant.outlined ||
        IuxButtonVariant.tonal =>
          geometry.borderWidth,
        // A filled button needs no outline to be identifiable, except when it
        // is disabled, where the fill is close to the surface behind it.
        IuxButtonVariant.filled =>
          state == IuxButtonState.disabled ? geometry.borderWidth : 0,
        IuxButtonVariant.text || IuxButtonVariant.icon => 0,
      };
}

@immutable
final class _Palette {
  const _Palette({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;
}

/// Extends a theme configuration with button defaults.
extension IuxButtonThemeConfiguration on IuxThemeConfiguration {
  /// The button theme a configuration implies.
  ///
  /// Buttons take no configuration of their own today; the hook exists so a
  /// later mission can vary defaults by condition without changing call sites.
  IuxButtonTheme get buttonTheme => const IuxButtonTheme();
}
