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
/// in a list where one wins. It is carried separately by
/// [IuxButtonTokens.focused] and drawn additively by the runtime.
enum IuxButtonState {
  /// Resting and available.
  enabled,

  /// Unavailable.
  disabled,

  /// A pointer is resting on it.
  hovered,

  /// Being activated.
  pressed,

  /// Its operation is running.
  loading,

  /// Its operation finished successfully.
  success,

  /// Its operation failed.
  error,
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
    required this.elevation,
    required this.iconSize,
    required this.iconGap,
    required this.textStyle,
    required this.focused,
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

  /// Shadow depth. Zero under a reduced visual stimulation preference.
  final double elevation;

  /// Icon edge length.
  final double iconSize;

  /// Space between an icon and a label.
  final double iconGap;

  /// The label style, already carrying [foreground].
  final TextStyle textStyle;

  /// Whether the focus ring must be drawn.
  ///
  /// Independent of [state] on purpose: focus must remain visible while
  /// pressed, while loading and while showing a result. A design where
  /// pressing hides the focus ring is a design a keyboard user loses their
  /// place in.
  final bool focused;

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
          other.elevation == elevation &&
          other.iconSize == iconSize &&
          other.iconGap == iconGap &&
          other.textStyle == textStyle &&
          other.focused == focused;

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
        elevation,
        iconSize,
        iconGap,
        textStyle,
        focused,
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
    this.variant = IuxButtonVariant.filled,
    this.shape = IuxButtonShape.medium,
    this.elevateFilled = false,
    this.iconSize = 20,
  });

  /// The variant used when a call site does not name one.
  final IuxButtonVariant variant;

  /// The corner treatment.
  final IuxButtonShape shape;

  /// Whether a filled button casts a shadow.
  ///
  /// Off by default. A filled button is already separated from its background
  /// by colour, and the shadow disappears entirely under a reduced visual
  /// stimulation preference — so relying on it would mean the button reads
  /// differently for users who asked for a calmer interface.
  final bool elevateFilled;

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
    IuxButtonVariant? variant,
    IuxButtonShape? shape,
    bool? elevateFilled,
    double? iconSize,
  }) =>
      IuxButtonTheme(
        variant: variant ?? this.variant,
        shape: shape ?? this.shape,
        elevateFilled: elevateFilled ?? this.elevateFilled,
        iconSize: iconSize ?? this.iconSize,
      );

  @override
  IuxButtonTheme lerp(
    covariant ThemeExtension<IuxButtonTheme>? other,
    double t,
  ) {
    if (other is! IuxButtonTheme) return this;
    return IuxButtonTheme(
      // Variant and shape are categorical; a half-applied variant is not a
      // variant.
      variant: t < 0.5 ? variant : other.variant,
      shape: t < 0.5 ? shape : other.shape,
      elevateFilled: t < 0.5 ? elevateFilled : other.elevateFilled,
      iconSize: iconSize + (other.iconSize - iconSize) * t,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxButtonTheme &&
          other.variant == variant &&
          other.shape == shape &&
          other.elevateFilled == elevateFilled &&
          other.iconSize == iconSize;

  @override
  int get hashCode => Object.hash(variant, shape, elevateFilled, iconSize);
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
  /// 2. `loading` — the operation is what the user is waiting on;
  /// 3. `pressed` — activation feedback must never be swallowed, otherwise
  ///    the user cannot tell their tap registered;
  /// 4. `error`, then `success` — a result outranks a pointer position;
  /// 5. `hovered`;
  /// 6. `enabled`.
  ///
  /// Focus is not in this list. It must stay visible in every one of these
  /// states, so it is reported separately.
  static IuxButtonState resolve(
    IuxActionDescriptor action, {
    bool hovered = false,
    bool pressed = false,
  }) {
    if (action.availability == IuxActionAvailability.disabled) {
      return IuxButtonState.disabled;
    }
    if (action.operation == IuxActionOperation.inProgress) {
      return IuxButtonState.loading;
    }
    if (pressed) return IuxButtonState.pressed;
    if (action.operation == IuxActionOperation.failed) {
      return IuxButtonState.error;
    }
    if (action.operation == IuxActionOperation.succeeded) {
      return IuxButtonState.success;
    }
    if (hovered) return IuxButtonState.hovered;
    return IuxButtonState.enabled;
  }
}

/// Resolves the complete appearance of a button.
///
/// The only entry point a button widget needs.
abstract final class IuxButtonResolver {
  /// Resolves [action] into paintable tokens.
  static IuxButtonTokens resolve(
    BuildContext context,
    IuxActionDescriptor action, {
    IuxButtonVariant? variant,
    bool hovered = false,
    bool pressed = false,
    bool focused = false,
    bool hasLabel = true,
  }) {
    final IuxButtonTheme theme = IuxButtonTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme typography = IuxTypographyTheme.of(context);

    final IuxButtonVariant resolvedVariant = variant ?? theme.variant;
    assert(
      !(resolvedVariant == IuxButtonVariant.tonal &&
          action.intent == IuxActionIntent.destructive),
      'A destructive action must not use the tonal variant. Tonal is the '
      'lowest-emphasis container, and it carries intent through its border '
      'rather than its fill — which is not enough separation for an action '
      'that destroys data. Use filled or outlined.',
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
      elevation: _elevation(resolvedVariant, state, theme, geometry),
      iconSize: theme.iconSize,
      iconGap: geometry.spacingXs,
      textStyle: typography.label.copyWith(color: palette.foreground),
      focused: focused,
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
    // text on the page background.
    //
    // The semantic layer already models secondary and tertiary as unfilled:
    // their `background` *is* the page surface and their accent lives in
    // `foreground`. Primary and destructive are filled, so theirs is in
    // `background`. Assuming one of the two universally produced a white
    // label on a white surface, which the contrast test caught.
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
      IuxButtonVariant.filled => _Palette(
          background: engaged(action.background),
          foreground: action.foreground,
          border: action.border,
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

  static double _elevation(
    IuxButtonVariant variant,
    IuxButtonState state,
    IuxButtonTheme theme,
    IuxGeometryTheme geometry,
  ) {
    if (!theme.elevateFilled) return 0;
    if (variant != IuxButtonVariant.filled) return 0;
    if (state == IuxButtonState.disabled) return 0;
    return geometry.elevationRaised;
  }
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
