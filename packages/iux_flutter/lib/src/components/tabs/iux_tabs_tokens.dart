import 'package:flutter/material.dart';

import '../../accessibility/iux_accessibility.dart';
import '../../motion/iux_motion_policy.dart';
import '../../motion/iux_motion_role.dart';
import '../../semantics/iux_semantic_colors.dart';
import '../../themes/extensions/iux_geometry_theme.dart';
import '../../themes/extensions/iux_typography_theme.dart';

/// Everything needed to lay out and paint a tab strip, and nothing about how.
///
/// Resolved in one place so a tab's target floor, its type and what marks it as
/// current cannot drift between the resting state and the pressed one.
///
/// The vocabulary is deliberately the same as `IuxBottomNavigationTokens`
/// wherever the two components make the same decision — the current item is
/// marked by a filled *and* outlined shape, the label keeps its metrics in both
/// states, the target floor comes from the runtime. A user who has learned what
/// a marked item looks like at the bottom of the screen should not have to
/// learn it again at the top.
///
/// There is no `stacked` flag here and no second arrangement, which is the one
/// place this deliberately parts company with the navigation bar. A destination
/// there is a glyph over a name in one of five equal columns, and an equal
/// column stops holding a word long before the user stops enlarging their text.
/// A tab is one word and takes the width of that word, so the strip answers
/// enlarged text by wrapping onto another row instead of by changing shape.
@immutable
final class IuxTabsTokens {
  /// Creates a resolved tab strip appearance.
  const IuxTabsTokens({
    required this.background,
    required this.separator,
    required this.separatorWidth,
    required this.indicatorFill,
    required this.indicatorBorder,
    required this.indicatorBorderWidth,
    required this.indicatorRadius,
    required this.labelStyle,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.minExtent,
    required this.overlayColor,
    required this.overlayOpacity,
    required this.motion,
  });

  /// The strip's own background.
  ///
  /// The page's own surface, not a raised one. A tab strip switches a view
  /// *inside* a section; it is part of the screen it sits on rather than a
  /// card floating over it, and a raised band here would read as a second
  /// piece of chrome competing with the app bar above it.
  ///
  /// This is where the strip deliberately differs from `IuxBottomNavigation`,
  /// which uses `surface.raised`: a bar that never scrolls has to look
  /// separate from the content that does, and a tab strip has no such claim.
  /// Painting it rather than leaving it transparent is what makes the label
  /// contrast a promise the theme can keep — a transparent strip inherits
  /// whatever it was dropped onto.
  final Color background;

  /// The colour of the line along the strip's trailing edge.
  ///
  /// The role held to 3:1, not the decorative one. This line is where the
  /// choice stops and the chosen content starts; a user who cannot see the
  /// boundary reads the first line of the panel as one more tab.
  final Color separator;

  /// The line's thickness.
  final double separatorWidth;

  /// The fill behind the current tab.
  final Color indicatorFill;

  /// The outline around the current tab.
  ///
  /// Drawn as well as the fill, and that is the point. Surface contrast alone
  /// is deliberately gentle in IUX, so an indicator that relied on it would
  /// disappear on a monochrome screen or under a colour-vision difference —
  /// which is precisely the user this indicator exists for.
  ///
  /// A fill-and-outline rather than the underline the platform convention
  /// draws. An underline claims adjacency to the panel it belongs to, and this
  /// strip may take more than one row once text is enlarged, at which point
  /// only the last row is adjacent to anything. A two-pixel line is also the
  /// hardest possible mark to see for the low-vision user it matters most to,
  /// where a filled area survives.
  final Color indicatorBorder;

  /// The outline's thickness.
  final double indicatorBorderWidth;

  /// The indicator's corner radius, and the focus ring's.
  ///
  /// One value for both, so the two shapes are concentric rather than
  /// almost-aligned. They stay distinguishable — one is a fill inside, the
  /// other an outline outside — without looking like a mistake when a user
  /// focuses the tab they are already on.
  final double indicatorRadius;

  /// The style of a tab's label, already carrying its colour.
  ///
  /// The same weight and size whether or not the tab is current. A heavier
  /// current label would change the text's measured width, so choosing a tab
  /// would move the tabs beside it — and in a strip that wraps, a few pixels
  /// of extra width is enough to push the last tab onto a new row under the
  /// finger that just tapped.
  final TextStyle labelStyle;

  /// The padding at the start and end of a label.
  ///
  /// Two of these separate one label from the next, because the tabs touch:
  /// there is no divider between them, so this gap is the only thing that says
  /// where one choice ends. Small enough that a tab is mostly its word, large
  /// enough that two words are not read as one phrase.
  final double horizontalPadding;

  /// The padding above and below a label.
  final double verticalPadding;

  /// The smallest extent a tab's interactive region may take.
  ///
  /// Read from the runtime rather than measured here, so a tab and a button
  /// cannot end up disagreeing about how large a target has to be. Density
  /// tightens the space around things; it never shrinks what a finger must hit.
  final double minExtent;

  /// The tint painted over a tab while it is pressed or hovered.
  final Color overlayColor;

  /// How much of [overlayColor] is visible: one while reacting, zero at rest.
  ///
  /// An opacity rather than a nullable colour, so the transition animates
  /// without the colour itself fading between two hues — which would read as a
  /// third state nobody defined.
  final double overlayOpacity;

  /// Whether and how the indicator may animate as the current tab changes.
  final IuxResolvedMotion motion;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxTabsTokens &&
          other.background == background &&
          other.separator == separator &&
          other.separatorWidth == separatorWidth &&
          other.indicatorFill == indicatorFill &&
          other.indicatorBorder == indicatorBorder &&
          other.indicatorBorderWidth == indicatorBorderWidth &&
          other.indicatorRadius == indicatorRadius &&
          other.labelStyle == labelStyle &&
          other.horizontalPadding == horizontalPadding &&
          other.verticalPadding == verticalPadding &&
          other.minExtent == minExtent &&
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
        labelStyle,
        horizontalPadding,
        verticalPadding,
        minExtent,
        overlayColor,
        overlayOpacity,
        motion,
      ]);
}

/// Resolves the complete appearance of a tab strip.
///
/// There is no `IuxTabsTheme`, for the same reason there is no navigation
/// theme, no list theme and no selection theme: every decision the strip makes
/// is already carried by the semantic palette, the geometry and the typography
/// an application configures once. A dedicated extension would only have
/// created a place to break the contrast guarantee and the target floor, which
/// are the two things a row of adjacent controls must not lose.
abstract final class IuxTabsResolver {
  /// Resolves the appearance of a tab in the given state.
  ///
  /// [current] is whether this tab is the one whose panel is shown; [pressed]
  /// and [hovered] are the transient interaction states.
  static IuxTabsTokens resolve(
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

    return IuxTabsTokens(
      background: colors.surface.base,
      separator: colors.border.standard,
      separatorWidth: geometry.borderWidth,
      indicatorFill: colors.surface.selected,
      indicatorBorder: colors.border.selected,
      indicatorBorderWidth: geometry.borderWidth,
      indicatorRadius: geometry.radiusMedium,
      labelStyle: typography.label.copyWith(color: content),
      horizontalPadding: geometry.spacingSm,
      verticalPadding: geometry.spacingXs,
      minExtent: accessibility.minimumTouchTarget,
      // Pressed wins over hovered: a pointer that is pressing is also hovering,
      // and reporting the weaker of the two would leave a press with no
      // feedback at all.
      overlayColor: pressed ? colors.state.pressed : colors.state.hovered,
      overlayOpacity: pressed || hovered ? 1 : 0,
      // A state change, at the short scale. The indicator moving answers "which
      // one am I reading now"; a reduced preference shortens it, and no motion
      // removes the animation while leaving the indicator itself — the
      // information is the indicator, not the transition.
      motion: IuxMotionPolicy.resolve(
        context,
        role: IuxMotionRole.stateChange,
        scale: IuxMotionScale.short,
      ),
    );
  }
}
