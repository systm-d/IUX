import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../accessibility/iux_accessibility.dart';
import '../../layout/iux_spacing_primitives.dart';
import '../../motion/iux_motion_policy.dart';
import '../../motion/iux_motion_role.dart';
import '../../semantics/iux_semantic_colors.dart';
import '../../themes/extensions/iux_geometry_theme.dart';
import '../../themes/extensions/iux_typography_theme.dart';

/// How the horizontal space is split between a row's text and its value.
///
/// Two thirds to the text, one third to the value. The ratio is not a taste
/// judgement: the title is the only thing that identifies the item, so it is
/// the part that keeps the space, and the value is the part that wraps. A
/// layout that lets a long value squeeze the title produces rows the user
/// cannot tell apart.
const int _textFlex = 2;

/// The complement of [_textFlex].
const int _valueFlex = 1;

/// Everything needed to lay out and paint a list row, and nothing about how.
///
/// Resolved in one place so the three forms of a row — plain, tappable,
/// selectable — cannot end up with different padding, different minimum
/// heights or different type. A list in which the selectable rows are two
/// pixels taller than the plain ones is a list that reads as broken, and it is
/// the kind of drift that only a shared resolver prevents.
@immutable
final class IuxListItemTokens {
  /// Creates a resolved row appearance.
  const IuxListItemTokens({
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.gap,
    required this.textGap,
    required this.actionSpacing,
    required this.minHeight,
    required this.lineExtent,
    required this.background,
    required this.overlayColor,
    required this.overlayOpacity,
    required this.focusRadius,
    required this.focusReservation,
    required this.titleStyle,
    required this.subtitleStyle,
    required this.valueStyle,
    required this.stacksTrailingText,
    required this.motion,
  });

  /// The padding between the row's content and the edges of its target.
  ///
  /// Inside the interactive region, deliberately. Padding applied outside it
  /// would make the row look larger than the area that responds, and the user
  /// would discover the difference by tapping somewhere that does nothing.
  final double horizontalPadding;

  /// The padding above and below the content.
  final double verticalPadding;

  /// The space between the leading element, the text and the value.
  final double gap;

  /// The space between the title, the subtitle and a stacked value.
  final double textGap;

  /// The separation between the row's own target and a trailing control's.
  ///
  /// Never below [kIuxMinimumTargetSpacing]. Two targets that share an edge
  /// produce mis-taps however large they are, because a finger landing near
  /// the seam has no margin for error — and on a list row the two outcomes are
  /// "open this item" and "delete this item".
  final double actionSpacing;

  /// The smallest height the interactive region may take.
  final double minHeight;

  /// The height the leading element is centred within.
  ///
  /// A title that wraps to three lines keeps its icon beside the first one,
  /// where reading starts. Centring against the whole block would leave the
  /// icon floating opposite the middle of a sentence.
  final double lineExtent;

  /// The background of a chosen row, or null when it is not chosen.
  ///
  /// Null rather than a transparent colour, so an unchosen row inherits
  /// whatever surface it was placed on instead of covering it with an
  /// assumption. Never the only signal that a row is chosen: the tick is.
  final Color? background;

  /// The tint painted over the row while it is pressed or hovered.
  final Color overlayColor;

  /// How much of [overlayColor] is visible: one while reacting, zero at rest.
  ///
  /// Expressed as an opacity rather than a nullable colour so the transition
  /// animates. The colour itself never fades between two hues, which would
  /// read as a second state nobody defined.
  final double overlayOpacity;

  /// The corner radius of the focus indicator.
  final double focusRadius;

  /// The gap the focus indicator occupies, drawn or not.
  ///
  /// Reserved on every row, including the ones that can never take focus.
  /// Focus must not move the layout when it appears, so an interactive row
  /// holds the space permanently — and a list mixing interactive and plain
  /// rows would otherwise have two row heights for no reason the user can see.
  final double focusReservation;

  /// The style of the row's primary text.
  final TextStyle titleStyle;

  /// The style of the supporting line under the title.
  final TextStyle subtitleStyle;

  /// The style of the value the row reports.
  ///
  /// A label weight rather than the supporting style, so a value and a
  /// subtitle stay distinguishable once enlarged text stacks them one above
  /// the other.
  final TextStyle valueStyle;

  /// Whether the value belongs under the text rather than beside it.
  ///
  /// True once text is enlarged enough that a horizontal split stops fitting.
  /// Shrinking instead is what produces the clipped amounts users report as
  /// "the app ignores my text size".
  final bool stacksTrailingText;

  /// Whether and how the row may animate between two states.
  final IuxResolvedMotion motion;

  /// The flex given to the text column when the value sits beside it.
  int get textFlex => _textFlex;

  /// The flex given to the value when it sits beside the text.
  int get valueFlex => _valueFlex;

  /// The padding to apply, given whether a trailing control follows the row.
  ///
  /// The end padding shrinks to [gap] when a control follows, because the
  /// remaining separation is then owned by [actionSpacing] — which is the
  /// value that has a floor under it.
  EdgeInsetsDirectional paddingFor({required bool hasTrailingAction}) =>
      EdgeInsetsDirectional.fromSTEB(
        horizontalPadding,
        verticalPadding,
        hasTrailingAction ? gap : horizontalPadding,
        verticalPadding,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxListItemTokens &&
          other.horizontalPadding == horizontalPadding &&
          other.verticalPadding == verticalPadding &&
          other.gap == gap &&
          other.textGap == textGap &&
          other.actionSpacing == actionSpacing &&
          other.minHeight == minHeight &&
          other.lineExtent == lineExtent &&
          other.background == background &&
          other.overlayColor == overlayColor &&
          other.overlayOpacity == overlayOpacity &&
          other.focusRadius == focusRadius &&
          other.focusReservation == focusReservation &&
          other.titleStyle == titleStyle &&
          other.subtitleStyle == subtitleStyle &&
          other.valueStyle == valueStyle &&
          other.stacksTrailingText == stacksTrailingText &&
          other.motion == motion;

  @override
  int get hashCode => Object.hashAll(<Object?>[
        horizontalPadding,
        verticalPadding,
        gap,
        textGap,
        actionSpacing,
        minHeight,
        lineExtent,
        background,
        overlayColor,
        overlayOpacity,
        focusRadius,
        focusReservation,
        titleStyle,
        subtitleStyle,
        valueStyle,
        stacksTrailingText,
        motion,
      ]);
}

/// Resolves the complete appearance of a list row.
///
/// There is no `IuxListTheme`, for the same reason there is no selection
/// theme: every decision a row makes is already carried by the semantic
/// palette, the geometry and the typography an application configures once. An
/// extension would only have created a place to break the contrast guarantee
/// and the target floor, which are the two things a dense list must not lose.
abstract final class IuxListItemResolver {
  /// Resolves the appearance of a row in the given interaction state.
  static IuxListItemTokens resolve(
    BuildContext context, {
    bool selected = false,
    bool pressed = false,
    bool hovered = false,
  }) {
    final IuxAccessibility accessibility = IuxAccessibility.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme typography = IuxTypographyTheme.of(context);

    return IuxListItemTokens(
      horizontalPadding: geometry.spacingMd,
      verticalPadding: geometry.spacingSm,
      gap: geometry.spacingSm,
      textGap: geometry.spacingXxs,
      actionSpacing: math.max(geometry.spacingSm, kIuxMinimumTargetSpacing),
      // Read from the runtime rather than measured here, so a row and a button
      // cannot end up disagreeing about how large a target has to be. Density
      // tightens the space between rows; it never shrinks what a finger hits.
      minHeight: accessibility.minimumTouchTarget,
      lineExtent: accessibility
              .scaleText(typography.body.fontSize ?? geometry.spacingLg) *
          (typography.body.height ?? 1),
      background: selected ? colors.surface.selected : null,
      // Pressed wins over hovered: a pointer that is pressing is also
      // hovering, and reporting the weaker of the two would leave a press with
      // no feedback at all.
      overlayColor: pressed ? colors.state.pressed : colors.state.hovered,
      overlayOpacity: pressed || hovered ? 1 : 0,
      // The subtle radius, not the medium one. A row is a slice of a group
      // rather than an object of its own, and a heavily rounded focus ring on
      // a full-width row reads as a button the user has never seen before.
      focusRadius: geometry.radiusSubtle,
      focusReservation: geometry.focus.width + geometry.focus.gap,
      titleStyle: typography.body.copyWith(color: colors.content.primary),
      subtitleStyle:
          typography.supporting.copyWith(color: colors.content.secondary),
      valueStyle: typography.label.copyWith(color: colors.content.secondary),
      stacksTrailingText: accessibility.prefersStackedLayout,
      // A state change, at the short scale. The tint appearing answers "what
      // just changed"; a reduced preference shortens it and no motion removes
      // it — the tint itself still appears, because the information is the
      // tint and not the fade.
      motion: IuxMotionPolicy.resolve(
        context,
        role: IuxMotionRole.stateChange,
        scale: IuxMotionScale.short,
      ),
    );
  }
}
