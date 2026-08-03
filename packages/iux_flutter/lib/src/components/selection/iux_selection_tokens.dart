import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../accessibility/iux_accessibility.dart';
import '../../inputs/iux_input_descriptor.dart';
import '../../inputs/iux_input_model.dart';
import '../../inputs/iux_input_theme.dart';
import '../../motion/iux_motion_policy.dart';
import '../../motion/iux_motion_role.dart';
import '../../semantics/iux_semantic_colors.dart';
import '../../themes/extensions/iux_geometry_theme.dart';
import '../../themes/extensions/iux_typography_theme.dart';

/// How wide a switch track is, relative to the height of an indicator.
///
/// Twice the height is the narrowest ratio at which the thumb visibly travels.
/// Below it the two positions differ by a few pixels and the control stops
/// answering the only question it exists to answer — which way is it set.
const double _trackLengthRatio = 2;

/// How large the switch thumb is, relative to the track height.
///
/// Under one, so the track stays visible around the thumb. A thumb filling its
/// track leaves no groove to read the position against.
const double _thumbRatio = 0.75;

/// How large the mark inside a checkbox or on a thumb is, relative to the box.
///
/// The mark is the non-colour carrier of the state, so it is deliberately
/// large: a tick occupying a third of its box disappears at arm's length and
/// on a screen the user is already struggling with.
const double _markRatio = 0.75;

/// How large the dot inside a chosen radio is, relative to the ring.
const double _dotRatio = 0.5;

/// Everything needed to paint a selection control, and nothing about how.
///
/// The checkbox, the switch and the radio read the same tokens. That is the
/// point: three controls resolving their own colours is how a library ends up
/// with a checkbox whose "on" colour is not the switch's "on" colour, and a
/// user who has to learn each control separately.
@immutable
final class IuxSelectionTokens {
  /// Creates a resolved appearance.
  const IuxSelectionTokens({
    required this.state,
    required this.indicatorSize,
    required this.markSize,
    required this.dotSize,
    required this.trackLength,
    required this.thumbSize,
    required this.borderColor,
    required this.borderWidth,
    required this.checkboxRadius,
    required this.selectedFill,
    required this.markColor,
    required this.trackFill,
    required this.rowHighlight,
    required this.gap,
    required this.lineExtent,
    required this.labelStyle,
    required this.groupStyle,
    required this.helpStyle,
    required this.messageStyle,
    required this.motion,
  });

  /// The state these tokens were resolved for.
  ///
  /// Reused from the input model rather than redefined, so "invalid" means the
  /// same thing on a checkbox as it does on a text field.
  final IuxInputState state;

  /// The side of the box, the diameter of the ring, the height of the track.
  ///
  /// Scaled with the user's text setting. A user who enlarged their text told
  /// you that the default size was not legible, and a checkbox frozen at 24
  /// logical pixels is the one element on the form that ignored them.
  final double indicatorSize;

  /// The side of the tick or dash inside a checkbox.
  final double markSize;

  /// The diameter of the dot inside a chosen radio.
  final double dotSize;

  /// The width of a switch track.
  final double trackLength;

  /// The diameter of a switch thumb.
  final double thumbSize;

  /// The outline of an unchosen indicator, and of any indicator in error.
  final Color borderColor;

  /// The outline width.
  ///
  /// The strong width at every state. A hairline around a 24-pixel box is the
  /// first thing to disappear on a low-contrast screen, and the box is the
  /// whole control.
  final double borderWidth;

  /// The corner radius of a checkbox.
  ///
  /// Not themeable, and that is deliberate. Shape is what tells a checkbox
  /// from a radio at a glance — square means "any number of these", round
  /// means "one of these". An application allowed to round its checkboxes
  /// fully would ship a form where the two are indistinguishable and the user
  /// cannot predict what tapping a second one does.
  final double checkboxRadius;

  /// The fill of a chosen indicator, and of a switch track that is on.
  final Color selectedFill;

  /// The tick, the dash, and the thumb of a switch that is on.
  ///
  /// Measured against [selectedFill], which is the surface it sits on.
  final Color markColor;

  /// The fill of a switch track that is off.
  final Color trackFill;

  /// A tint over the whole row while it is hovered or pressed, or null.
  ///
  /// Null at rest rather than a transparent colour: nothing is painted, so
  /// the control inherits whatever surface it was placed on instead of
  /// covering it with an assumption.
  final Color? rowHighlight;

  /// Space between the indicator and the label.
  final double gap;

  /// The height the indicator is centred within, beside the first line.
  ///
  /// A control whose label wraps to three lines keeps its box beside the first
  /// line, where the eye starts. Centring the box against the whole block
  /// leaves it floating opposite the middle of a sentence.
  final double lineExtent;

  /// The style of the control's own label.
  final TextStyle labelStyle;

  /// The style of the name given to a group of controls.
  ///
  /// A heading weight rather than running text: a group name that looks like
  /// one of its own options is a group name the eye skips, and the options
  /// then arrive with nothing to attach them to.
  final TextStyle groupStyle;

  /// The style of the persistent explanation under a label.
  final TextStyle helpStyle;

  /// The style of a validation message.
  ///
  /// Coloured by status, which reinforces the message; it never replaces it.
  final TextStyle messageStyle;

  /// Whether and how the indicator may animate between two states.
  final IuxResolvedMotion motion;

  /// The outline to draw, given whether the control is chosen.
  ///
  /// A chosen indicator normally outlines itself in its own fill, so it reads
  /// as one solid mark rather than a filled box wearing a second ring. An
  /// invalid one keeps the error outline: the error is the more urgent of the
  /// two facts, and it is the one the user has to act on.
  Color outlineFor({required bool selected}) =>
      selected && state != IuxInputState.invalid ? selectedFill : borderColor;

  /// The fill to paint, given whether the control is chosen, or null.
  Color? fillFor({required bool selected}) => selected ? selectedFill : null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxSelectionTokens &&
          other.state == state &&
          other.indicatorSize == indicatorSize &&
          other.markSize == markSize &&
          other.dotSize == dotSize &&
          other.trackLength == trackLength &&
          other.thumbSize == thumbSize &&
          other.borderColor == borderColor &&
          other.borderWidth == borderWidth &&
          other.checkboxRadius == checkboxRadius &&
          other.selectedFill == selectedFill &&
          other.markColor == markColor &&
          other.trackFill == trackFill &&
          other.rowHighlight == rowHighlight &&
          other.gap == gap &&
          other.lineExtent == lineExtent &&
          other.labelStyle == labelStyle &&
          other.groupStyle == groupStyle &&
          other.helpStyle == helpStyle &&
          other.messageStyle == messageStyle &&
          other.motion == motion;

  @override
  int get hashCode => Object.hashAll(<Object?>[
        state,
        indicatorSize,
        markSize,
        dotSize,
        trackLength,
        thumbSize,
        borderColor,
        borderWidth,
        checkboxRadius,
        selectedFill,
        markColor,
        trackFill,
        rowHighlight,
        gap,
        lineExtent,
        labelStyle,
        groupStyle,
        helpStyle,
        messageStyle,
        motion,
      ]);
}

/// Resolves the complete appearance of a selection control.
///
/// There is no `IuxSelectionTheme`. Every decision a selection control makes
/// is already carried by the semantic palette, the geometry and the typography
/// an application configures once — and the one decision that is *not*
/// themeable, the shape that distinguishes a checkbox from a radio, must not
/// become themeable. An extension would only have created a place to break it.
abstract final class IuxSelectionResolver {
  /// Resolves [input] into paintable tokens.
  ///
  /// Colours are resolved against [IuxSurfaceColors.base], the same assumption
  /// the button and input resolvers make. A control placed on a raised or
  /// overlay surface inherits it, and a theme that moves those surfaces apart
  /// has to re-measure.
  static IuxSelectionTokens resolve(
    BuildContext context,
    IuxInputDescriptor input, {
    bool hovered = false,
    bool pressed = false,
  }) {
    assert(
      !(input.availability == IuxInputAvailability.disabled &&
          input.validation.isInvalid),
      'A disabled control cannot be corrected, so an error shown on one is a '
      'dead end: the user is told something is wrong and given no way to fix '
      'it. Clear the validation while the control is unavailable, or keep it '
      'enabled so the error can be acted on.',
    );

    final IuxAccessibility accessibility = IuxAccessibility.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme typography = IuxTypographyTheme.of(context);

    final IuxInputState state =
        IuxInputStateResolver.resolve(input, hovered: hovered);
    final bool inactive = state == IuxInputState.disabled;

    final double indicatorSize = accessibility.scaleText(geometry.spacingLg);

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

    // Content colours. Disabled content keeps its own role rather than an
    // opacity: an opacity over an unknown surface produces a contrast ratio
    // nobody has measured.
    final Color labelColor =
        inactive ? colors.content.disabled : colors.content.primary;
    final Color supportingColor =
        inactive ? colors.content.disabled : colors.content.secondary;

    final Color messageColor = switch (state) {
      IuxInputState.disabled => colors.content.disabled,
      IuxInputState.invalid => colors.feedback.error.content,
      IuxInputState.valid => colors.feedback.success.content,
      _ => colors.content.secondary,
    };

    return IuxSelectionTokens(
      state: state,
      indicatorSize: indicatorSize,
      markSize: indicatorSize * _markRatio,
      dotSize: indicatorSize * _dotRatio,
      trackLength: indicatorSize * _trackLengthRatio,
      thumbSize: indicatorSize * _thumbRatio,
      borderColor: border,
      // Always the strong width, and the same width in error. A field can
      // thicken its outline to signal a rejected value because a field is
      // wide; on a 24-pixel box the difference between two widths is a pixel
      // nobody perceives. The non-colour carrier of an error here is the
      // message, which IuxInputValidation.invalid already makes mandatory.
      borderWidth: geometry.strongBorderWidth,
      checkboxRadius: geometry.radiusSubtle,
      selectedFill:
          inactive ? colors.surface.disabled : colors.action.primary.background,
      markColor: inactive ? colors.content.disabled : colors.content.onAction,
      trackFill: inactive ? colors.surface.disabled : colors.surface.subtle,
      // Only an editable control reacts to a pointer. Highlighting a row that
      // cannot change promises an interaction that will not happen.
      rowHighlight: input.isEditable
          ? (pressed
              ? colors.state.pressed
              : hovered
                  ? colors.state.hovered
                  : null)
          : null,
      gap: geometry.spacingSm,
      lineExtent: math.max(
        indicatorSize,
        accessibility.scaleText(typography.body.fontSize ?? indicatorSize) *
            (typography.body.height ?? 1),
      ),
      labelStyle: typography.body.copyWith(color: labelColor),
      groupStyle: typography.label.copyWith(color: labelColor),
      helpStyle: typography.supporting.copyWith(color: supportingColor),
      messageStyle: typography.supporting.copyWith(color: messageColor),
      // A state change, at the short scale. The tick appearing answers "what
      // just changed"; under a reduced preference it is shortened, and under
      // no motion it is removed — the tick is still there, it simply arrives
      // instantly, so nothing the animation carried is lost.
      motion: IuxMotionPolicy.resolve(
        context,
        role: IuxMotionRole.stateChange,
        scale: IuxMotionScale.short,
      ),
    );
  }
}
