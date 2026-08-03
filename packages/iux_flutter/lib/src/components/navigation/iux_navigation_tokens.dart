import 'package:flutter/material.dart';

import '../../accessibility/iux_accessibility.dart';
import '../../motion/iux_motion_policy.dart';
import '../../motion/iux_motion_role.dart';
import '../../semantics/iux_semantic_colors.dart';
import '../../themes/extensions/iux_geometry_theme.dart';
import '../../themes/extensions/iux_typography_theme.dart';

/// The glyph edge length of a navigation icon, before text scaling.
///
/// The same figure `IuxIcon` uses for a standalone glyph. A symbol that changed
/// size when it moved from a list row into the navigation bar is the kind of
/// inconsistency nobody can name and everybody sees.
const double _navigationGlyph = 24;

/// Everything needed to lay out and paint a navigation bar, and nothing about
/// how.
///
/// Resolved in one place so the horizontal arrangement and the stacked one
/// cannot drift apart on target size, on type, or on what marks the current
/// destination. The two arrangements exist because a 64-pixel column cannot
/// hold an enlarged word; they are not two components, and they must not
/// become two.
@immutable
final class IuxBottomNavigationTokens {
  /// Creates a resolved bar appearance.
  const IuxBottomNavigationTokens({
    required this.background,
    required this.separator,
    required this.separatorWidth,
    required this.indicatorFill,
    required this.indicatorBorder,
    required this.indicatorBorderWidth,
    required this.indicatorRadius,
    required this.indicatorPadding,
    required this.iconSize,
    required this.iconColor,
    required this.labelStyle,
    required this.gap,
    required this.verticalPadding,
    required this.horizontalPadding,
    required this.minExtent,
    required this.focusReservation,
    required this.stacked,
    required this.overlayColor,
    required this.overlayOpacity,
    required this.motion,
  });

  /// The bar's own background.
  ///
  /// A raised surface rather than the page's base, so the strip that never
  /// scrolls is visibly not part of the content that does.
  final Color background;

  /// The colour of the line along the bar's leading edge.
  ///
  /// The role held to 3:1, not the decorative one. This line is where content
  /// stops and navigation starts; a user who cannot see the boundary reads the
  /// first destination as the last line of the page.
  final Color separator;

  /// The line's thickness.
  final double separatorWidth;

  /// The fill behind the current destination's glyph.
  final Color indicatorFill;

  /// The outline around the current destination's glyph.
  ///
  /// Drawn as well as the fill, and that is the point. Surface contrast alone
  /// is deliberately gentle in IUX, so an indicator that relied on it would
  /// disappear on a monochrome screen or under a colour-vision difference —
  /// which is precisely the user this indicator exists for.
  final Color indicatorBorder;

  /// The outline's thickness.
  final double indicatorBorderWidth;

  /// The indicator's corner radius.
  final double indicatorRadius;

  /// The space between the glyph and the indicator's edge.
  ///
  /// Deliberately small on the cross axis. Five indicators share one screen
  /// width, and an indicator wider than its column is an overflow at the exact
  /// text size a user chose in order to read.
  final EdgeInsets indicatorPadding;

  /// The glyph edge length, already scaled for the user's text size.
  final double iconSize;

  /// The glyph colour.
  final Color iconColor;

  /// The style of the destination's name, already carrying its colour.
  ///
  /// The same weight and size whether or not the destination is current. A
  /// heavier current label would change the text's measured width, so choosing
  /// a destination would move the four beside it — a layout that shifts under
  /// the finger that caused it.
  final TextStyle labelStyle;

  /// The space between the glyph and the name, and between the name and a
  /// badge.
  final double gap;

  /// The padding above and below a destination's content.
  final double verticalPadding;

  /// The padding at the start and end of a destination's content.
  final double horizontalPadding;

  /// The smallest extent a destination's interactive region may take.
  ///
  /// Read from the runtime rather than measured here, so a destination and a
  /// button cannot end up disagreeing about how large a target has to be.
  /// Density tightens the space around things; it never shrinks what a finger
  /// must hit.
  final double minExtent;

  /// The gap the focus indicator occupies, drawn or not.
  ///
  /// Reserved permanently. Focus must not move the layout when it appears, and
  /// in a bar of five equal columns a shift in one column is a shift in all
  /// five.
  final double focusReservation;

  /// Whether the destinations stack vertically instead of sharing one row.
  ///
  /// True once text is enlarged enough that a fifth of the screen width can no
  /// longer hold a word. Below that a row of columns is the compact, familiar
  /// arrangement; above it the same row breaks names across four lines in the
  /// middle of a syllable, which is the failure this flag exists to avoid.
  final bool stacked;

  /// The tint painted over a destination while it is pressed or hovered.
  final Color overlayColor;

  /// How much of [overlayColor] is visible: one while reacting, zero at rest.
  ///
  /// An opacity rather than a nullable colour, so the transition animates
  /// without the colour itself fading between two hues — which would read as a
  /// third state nobody defined.
  final double overlayOpacity;

  /// Whether and how the indicator may animate as the current destination
  /// changes.
  final IuxResolvedMotion motion;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxBottomNavigationTokens &&
          other.background == background &&
          other.separator == separator &&
          other.separatorWidth == separatorWidth &&
          other.indicatorFill == indicatorFill &&
          other.indicatorBorder == indicatorBorder &&
          other.indicatorBorderWidth == indicatorBorderWidth &&
          other.indicatorRadius == indicatorRadius &&
          other.indicatorPadding == indicatorPadding &&
          other.iconSize == iconSize &&
          other.iconColor == iconColor &&
          other.labelStyle == labelStyle &&
          other.gap == gap &&
          other.verticalPadding == verticalPadding &&
          other.horizontalPadding == horizontalPadding &&
          other.minExtent == minExtent &&
          other.focusReservation == focusReservation &&
          other.stacked == stacked &&
          other.overlayColor == overlayColor &&
          other.overlayOpacity == overlayOpacity &&
          other.motion == motion;

  @override
  int get hashCode => Object.hashAll(<Object?>[
        background,
        separator,
        separatorWidth,
        indicatorFill,
        indicatorBorder,
        indicatorBorderWidth,
        indicatorRadius,
        indicatorPadding,
        iconSize,
        iconColor,
        labelStyle,
        gap,
        verticalPadding,
        horizontalPadding,
        minExtent,
        focusReservation,
        stacked,
        overlayColor,
        overlayOpacity,
        motion,
      ]);
}

/// Resolves the complete appearance of a bottom navigation bar.
///
/// There is no `IuxNavigationTheme`, for the same reason there is no list theme
/// and no selection theme: every decision the bar makes is already carried by
/// the semantic palette, the geometry and the typography an application
/// configures once. A dedicated extension would only have created a place to
/// break the contrast guarantee and the target floor, which are the two things
/// a bar of five adjacent controls must not lose.
abstract final class IuxBottomNavigationResolver {
  /// Resolves the appearance of a destination in the given state.
  ///
  /// [current] is whether this destination is the one the user is on;
  /// [pressed] and [hovered] are the transient interaction states.
  static IuxBottomNavigationTokens resolve(
    BuildContext context, {
    bool current = false,
    bool pressed = false,
    bool hovered = false,
  }) {
    final IuxAccessibility accessibility = IuxAccessibility.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme typography = IuxTypographyTheme.of(context);

    final Color content =
        current ? colors.content.primary : colors.content.secondary;

    return IuxBottomNavigationTokens(
      background: colors.surface.raised,
      separator: colors.border.standard,
      separatorWidth: geometry.borderWidth,
      indicatorFill: colors.surface.selected,
      indicatorBorder: colors.border.selected,
      indicatorBorderWidth: geometry.borderWidth,
      indicatorRadius: geometry.radiusProminent,
      indicatorPadding: EdgeInsets.symmetric(
        horizontal: geometry.spacingXs,
        vertical: geometry.spacingXxs,
      ),
      // Scaled through the runtime rather than by Flutter, so the glyph and the
      // name under it enlarge by the same factor and only once. A glyph pinned
      // at 24 pixels while its label doubled stops looking like it belongs to
      // that label.
      iconSize: accessibility.scaleText(_navigationGlyph),
      iconColor: content,
      labelStyle: typography.label.copyWith(color: content),
      gap: geometry.spacingXxs,
      verticalPadding: geometry.spacingXxs,
      horizontalPadding: geometry.spacingXxs,
      minExtent: accessibility.minimumTouchTarget,
      focusReservation: geometry.focus.width + geometry.focus.gap,
      stacked: accessibility.prefersStackedLayout,
      // Pressed wins over hovered: a pointer that is pressing is also hovering,
      // and reporting the weaker of the two would leave a press with no
      // feedback at all.
      overlayColor: pressed ? colors.state.pressed : colors.state.hovered,
      overlayOpacity: pressed || hovered ? 1 : 0,
      // A state change, at the short scale. The indicator moving answers "where
      // am I now"; a reduced preference shortens it, and no motion removes the
      // animation while leaving the indicator itself — the information is the
      // indicator, not the transition.
      motion: IuxMotionPolicy.resolve(
        context,
        role: IuxMotionRole.stateChange,
        scale: IuxMotionScale.short,
      ),
    );
  }
}
