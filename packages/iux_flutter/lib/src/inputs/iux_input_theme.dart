import 'package:flutter/material.dart';

import '../foundations/iux_foundations.dart';
import '../semantics/iux_semantic_colors.dart';
import '../themes/extensions/iux_geometry_theme.dart';
import '../themes/extensions/iux_typography_theme.dart';
import '../themes/iux_theme_configuration.dart';
import 'iux_input_descriptor.dart';
import 'iux_input_model.dart';

/// How a field separates itself from the page.
///
/// Two values, and both of them draw a full outline. A single bottom rule
/// leaves three of the four edges of the control undefined, so the user has to
/// guess where it starts, how wide it is and where it is safe to tap — which
/// is the perceivability of the control boundary that WCAG 2.2 SC 1.4.11 is
/// about.
enum IuxInputVariant {
  /// An outline on the page background.
  ///
  /// The default. Its boundary is a border held to 3:1 by the theme rather
  /// than a fill that measures roughly 1.1:1 against the page in light
  /// conditions.
  outlined,

  /// An outline over a filled container.
  ///
  /// Useful in a dense form, where the fill groups a value with its label
  /// faster than an outline does. It reinforces the outline; it never replaces
  /// it.
  filled,
}

/// The single visual state a field resolves to.
///
/// Focus is deliberately absent. A focus indicator must be visible whatever
/// else is true — including on a field that is showing an error — so it cannot
/// be one value in a list where one wins. It is carried separately by
/// [IuxInputTokens.focused] and drawn additively by the runtime.
///
/// There is no `pressed`. A field is not activated by a press; a tap places
/// the caret, and the state that follows is focus.
///
/// There is no `empty`. An empty field is a field at rest, not a state of its
/// own: whether the label floats above the value or sits inside it is a
/// rendering decision, and it changes no colour, no border and no metric.
enum IuxInputState {
  /// Resting and editable.
  enabled,

  /// A pointer is resting on it.
  hovered,

  /// Readable and focusable, but not editable.
  readOnly,

  /// Not applicable, and out of the focus order.
  disabled,

  /// A check on the current value is running.
  validating,

  /// The value was checked and accepted.
  valid,

  /// The value was checked and rejected.
  invalid,
}

/// Everything needed to paint a field, and nothing about how to paint it.
///
/// An input widget reads this. It never reaches for a semantic role itself, so
/// the mapping from a descriptor to an appearance exists in one place and
/// cannot drift between the text field, the checkbox and whatever comes next.
@immutable
final class IuxInputTokens {
  /// Creates a resolved appearance.
  const IuxInputTokens({
    required this.state,
    required this.background,
    required this.border,
    required this.borderWidth,
    required this.radius,
    required this.padding,
    required this.minimumSize,
    required this.gap,
    required this.labelStyle,
    required this.valueStyle,
    required this.placeholderStyle,
    required this.helpStyle,
    required this.messageStyle,
    required this.focused,
  });

  /// The state these tokens were resolved for.
  final IuxInputState state;

  /// The container colour.
  final Color background;

  /// The outline colour.
  final Color border;

  /// The outline width.
  ///
  /// Thicker for [IuxInputState.invalid] than for any other state, so the
  /// error survives a monochrome rendering, a colour-vision deficiency and a
  /// screenshot printed in grey.
  final double borderWidth;

  /// The corner radius.
  ///
  /// [double.infinity] means fully rounded; the widget resolves it against its
  /// own height, which the theme cannot know.
  final double radius;

  /// Padding inside the container.
  final EdgeInsets padding;

  /// The smallest permitted interactive dimension.
  final double minimumSize;

  /// Space between the field and the text above or below it.
  final double gap;

  /// The style of the field's visible name.
  final TextStyle labelStyle;

  /// The style of the value the user typed.
  final TextStyle valueStyle;

  /// The style of the placeholder shown while the field is empty.
  ///
  /// Held to the same contrast minimum as real content. A placeholder is text
  /// the user has to read in order to know what to type, so de-emphasising it
  /// below the readable threshold defeats its only purpose.
  final TextStyle placeholderStyle;

  /// The style of the persistent instruction.
  final TextStyle helpStyle;

  /// The style of the validation message.
  ///
  /// Meaningful only when the descriptor carries one. It is coloured by
  /// status, which reinforces the message — it never replaces it.
  final TextStyle messageStyle;

  /// Whether the focus ring must be drawn.
  ///
  /// Independent of [state] on purpose. A field showing an error is exactly
  /// the field a keyboard user is about to correct, so losing the focus ring
  /// there loses their place at the worst moment.
  final bool focused;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxInputTokens &&
          other.state == state &&
          other.background == background &&
          other.border == border &&
          other.borderWidth == borderWidth &&
          other.radius == radius &&
          other.padding == padding &&
          other.minimumSize == minimumSize &&
          other.gap == gap &&
          other.labelStyle == labelStyle &&
          other.valueStyle == valueStyle &&
          other.placeholderStyle == placeholderStyle &&
          other.helpStyle == helpStyle &&
          other.messageStyle == messageStyle &&
          other.focused == focused;

  @override
  int get hashCode => Object.hashAll(<Object>[
        state,
        background,
        border,
        borderWidth,
        radius,
        padding,
        minimumSize,
        gap,
        labelStyle,
        valueStyle,
        placeholderStyle,
        helpStyle,
        messageStyle,
        focused,
      ]);
}

/// Tunables an application may adjust for every field at once.
///
/// Deliberately small. Anything that would let a call site pick a colour, a
/// border width or a duration is absent, and will stay absent: an API that
/// accepts a colour has already lost the contrast guarantee, because the theme
/// can no longer be held responsible for something a call site overrode.
@immutable
final class IuxInputTheme extends ThemeExtension<IuxInputTheme> {
  /// Creates an input theme.
  const IuxInputTheme({
    this.variant = IuxInputVariant.outlined,
    this.shape = IuxShape.medium,
  });

  /// The variant used when a call site does not name one.
  final IuxInputVariant variant;

  /// The corner treatment.
  ///
  /// Reuses the foundation shape scale rather than defining an input-specific
  /// one. A rounding level means the same thing on a card, a button and a
  /// field, and a second enum for it would only allow them to disagree.
  final IuxShape shape;

  /// Resolves the input theme installed on the ambient theme.
  ///
  /// Falls back to defaults rather than throwing: a field with no explicit
  /// input theme should still render correctly.
  static IuxInputTheme of(BuildContext context) =>
      Theme.of(context).extension<IuxInputTheme>() ?? const IuxInputTheme();

  @override
  IuxInputTheme copyWith({IuxInputVariant? variant, IuxShape? shape}) =>
      IuxInputTheme(
        variant: variant ?? this.variant,
        shape: shape ?? this.shape,
      );

  @override
  IuxInputTheme lerp(covariant ThemeExtension<IuxInputTheme>? other, double t) {
    if (other is! IuxInputTheme) return this;
    // Both fields are categorical. A half-applied variant is not a variant,
    // and a radius interpolated between two named levels belongs to neither.
    return IuxInputTheme(
      variant: t < 0.5 ? variant : other.variant,
      shape: t < 0.5 ? shape : other.shape,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxInputTheme &&
          other.variant == variant &&
          other.shape == shape;

  @override
  int get hashCode => Object.hash(variant, shape);
}

/// Resolves a descriptor and its interaction into a single visual state.
///
/// The precedence is fixed here so two components cannot disagree about what a
/// hovered read-only field looks like.
abstract final class IuxInputStateResolver {
  /// The state to render.
  ///
  /// Precedence, highest first:
  ///
  /// 1. `disabled` — nothing else matters if the field does not apply;
  /// 2. `invalid`, `validating`, `valid` — what the user has to act on. These
  ///    are mutually exclusive, so their relative order never arises;
  /// 3. `readOnly` — already carried by the absence of a caret and by
  ///    semantics, so it yields to a validation result rather than hiding one;
  /// 4. `hovered`;
  /// 5. `enabled`.
  ///
  /// Focus is not in this list. It must stay visible in every one of these
  /// states, so it is reported separately.
  static IuxInputState resolve(
    IuxInputDescriptor input, {
    bool hovered = false,
  }) {
    if (input.availability == IuxInputAvailability.disabled) {
      return IuxInputState.disabled;
    }
    switch (input.validation.status) {
      case IuxInputValidationStatus.invalid:
        return IuxInputState.invalid;
      case IuxInputValidationStatus.validating:
        return IuxInputState.validating;
      case IuxInputValidationStatus.valid:
        return IuxInputState.valid;
      case IuxInputValidationStatus.notValidated:
        break;
    }
    if (input.availability == IuxInputAvailability.readOnly) {
      return IuxInputState.readOnly;
    }
    if (hovered) return IuxInputState.hovered;
    return IuxInputState.enabled;
  }
}

/// Resolves the complete appearance of a field.
///
/// The only entry point an input widget needs.
///
/// ```dart
/// final tokens = IuxInputResolver.resolve(context, descriptor, focused: true);
/// ```
abstract final class IuxInputResolver {
  /// Resolves [input] into paintable tokens.
  ///
  /// The colours are resolved against [IuxSurfaceColors.base]. A field placed
  /// on a raised or overlay surface inherits that assumption, and a theme that
  /// moves those surfaces apart has to re-measure — the same limitation the
  /// button resolver carries.
  static IuxInputTokens resolve(
    BuildContext context,
    IuxInputDescriptor input, {
    IuxInputVariant? variant,
    bool hovered = false,
    bool focused = false,
  }) {
    assert(
      !(input.availability == IuxInputAvailability.disabled &&
          input.validation.isInvalid),
      'A disabled field cannot be corrected, so an error shown on one is a '
      'dead end: the user is told something is wrong and given no way to fix '
      'it. Clear the validation while the field is unavailable, or keep the '
      'field enabled so the error can be acted on.',
    );

    final IuxInputTheme theme = IuxInputTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme typography = IuxTypographyTheme.of(context);

    final IuxInputVariant resolvedVariant = variant ?? theme.variant;
    final IuxInputState state =
        IuxInputStateResolver.resolve(input, hovered: hovered);
    final bool inactive = state == IuxInputState.disabled;

    // An invalid field keeps its ordinary fill. Tinting the container red
    // would put the error in the one channel a user with a colour-vision
    // deficiency cannot read, and would drag the contrast of the value the
    // user is trying to fix down with it.
    final Color background = switch (state) {
      IuxInputState.disabled => colors.surface.disabled,
      IuxInputState.readOnly => colors.surface.subtle,
      IuxInputState.hovered => colors.state.hovered,
      _ => resolvedVariant == IuxInputVariant.filled
          ? colors.surface.interactive
          : colors.surface.base,
    };

    final Color border = switch (state) {
      IuxInputState.disabled => colors.border.disabled,
      IuxInputState.invalid => colors.border.error,
      IuxInputState.valid => colors.feedback.success.border,
      IuxInputState.readOnly => colors.border.standard,
      IuxInputState.hovered => colors.border.strong,
      IuxInputState.validating ||
      IuxInputState.enabled =>
        colors.border.interactive,
    };

    // Content colours. Disabled content keeps 3:1 rather than taking the WCAG
    // exemption: a field the user cannot fill is still a field they have to
    // read in order to understand the form.
    final Color valueColor =
        inactive ? colors.content.disabled : colors.content.primary;

    // The placeholder is held at `content.secondary`, not `content.tertiary`.
    // Tertiary measures 4.45:1 on the filled surface in light conditions,
    // below the 4.5:1 minimum, and a placeholder nobody can read is an
    // instruction nobody gets.
    final Color supportingColor =
        inactive ? colors.content.disabled : colors.content.secondary;

    final Color messageColor = switch (state) {
      IuxInputState.disabled => colors.content.disabled,
      IuxInputState.invalid => colors.feedback.error.content,
      IuxInputState.valid => colors.feedback.success.content,
      _ => colors.content.secondary,
    };

    return IuxInputTokens(
      state: state,
      background: background,
      border: border,
      // Thicker when invalid, so the error is not carried by hue alone.
      borderWidth: state == IuxInputState.invalid
          ? geometry.strongBorderWidth
          : geometry.borderWidth,
      radius: geometry.radius(theme.shape),
      padding: EdgeInsets.symmetric(
        horizontal: geometry.spacingSm,
        vertical: geometry.spacingXs,
      ),
      minimumSize: geometry.minimumTouchTarget,
      gap: geometry.spacingXxs,
      labelStyle: typography.label.copyWith(color: supportingColor),
      valueStyle: typography.body.copyWith(color: valueColor),
      placeholderStyle: typography.body.copyWith(color: supportingColor),
      helpStyle: typography.supporting.copyWith(color: supportingColor),
      messageStyle: typography.supporting.copyWith(color: messageColor),
      focused: focused,
    );
  }
}

/// Extends a theme configuration with input defaults.
extension IuxInputThemeConfiguration on IuxThemeConfiguration {
  /// The input theme a configuration implies.
  ///
  /// Fields take no configuration of their own today; the hook exists so a
  /// later mission can vary defaults by condition without changing call sites.
  IuxInputTheme get inputTheme => const IuxInputTheme();
}
