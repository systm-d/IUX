import 'package:flutter/material.dart';

import '../../accessibility/iux_accessibility.dart';
import '../../layout/iux_content_width.dart';
import '../../motion/iux_motion_policy.dart';
import '../../motion/iux_motion_role.dart';
import '../../semantics/iux_semantic_colors.dart';
import '../../themes/extensions/iux_geometry_theme.dart';
import '../../themes/extensions/iux_typography_theme.dart';

/// The glyph edge length of a drawer destination, before text scaling.
///
/// The same figure the bottom navigation bar and `IuxIcon` use. A symbol that
/// changed size when the same destination moved from the bar into the drawer
/// would be an inconsistency nobody can name and everybody sees.
const double _drawerGlyph = 24;

/// How much of the page behind the drawer the scrim covers.
///
/// The same value `IuxDialog` and `IuxBottomSheet` use, deliberately. Three
/// modal surfaces that dim the page by three different amounts read as three
/// degrees of interruption, when they are the same one.
const double _kScrimOpacity = 0.6;

/// Everything needed to lay out and paint a navigation drawer, and nothing
/// about how.
///
/// Resolved in one place so the panel, its header and its destination rows
/// cannot drift apart on target size, on type, or on what marks the current
/// destination — the three things a modal list of places must not get wrong.
@immutable
final class IuxNavigationDrawerTokens {
  /// Creates a resolved drawer appearance.
  const IuxNavigationDrawerTokens({
    required this.scrim,
    required this.readableWidth,
    required this.titleStyle,
    required this.labelStyle,
    required this.iconSize,
    required this.iconColor,
    required this.indicatorFill,
    required this.indicatorBorder,
    required this.indicatorBorderWidth,
    required this.indicatorRadius,
    required this.rowPadding,
    required this.gap,
    required this.minExtent,
    required this.overlayColor,
    required this.overlayOpacity,
    required this.motion,
  });

  /// The dimmed area covering the page, which is also a way out.
  ///
  /// Derived rather than named: IUX has no scrim role, so this is whichever of
  /// the two surface extremes the theme resolved *darker*, at a fixed opacity.
  /// Picking by measured luminance rather than by brightness means a scrim
  /// never brightens what it covers, which is what a fixed "inverse surface"
  /// would do in dark conditions.
  final Color scrim;

  /// The widest the panel may grow before the screen has its say.
  ///
  /// [IuxContentWidthResolver] states its caps in characters and returns the
  /// pixels those characters need at the text size actually in force, so
  /// enlarging text *widens* the drawer instead of squeezing the same
  /// destination names into a narrower column. A drawer pinned at a pixel width
  /// is a drawer that clips exactly the names of the user who enlarged them.
  final double readableWidth;

  /// The style of the drawer's own name, already carrying its colour.
  final TextStyle titleStyle;

  /// The style of a destination's name, already carrying its colour.
  ///
  /// The body style rather than the bar's label style: a drawer row is a
  /// full-width line of text like a list row, not a caption under a glyph in a
  /// fifth of a screen, and setting it at caption size would make the drawer
  /// the least legible navigation surface in the framework.
  ///
  /// The same weight and size whether or not the destination is current. A
  /// heavier current label changes the text's measured width, so choosing a
  /// destination would reflow the rows around it.
  final TextStyle labelStyle;

  /// The glyph edge length, already scaled for the user's text size.
  final double iconSize;

  /// The glyph colour.
  final Color iconColor;

  /// The fill behind the current destination's row.
  final Color indicatorFill;

  /// The outline around the current destination's row.
  ///
  /// Drawn as well as the fill, and that is the point. Surface contrast alone
  /// is deliberately gentle in IUX, so an indicator that relied on it would
  /// disappear on a monochrome screen or under a colour-vision difference —
  /// which is precisely the user this indicator exists for.
  final Color indicatorBorder;

  /// The outline's thickness.
  final double indicatorBorderWidth;

  /// The corner radius of the indicator, and of the press tint above it.
  ///
  /// Shared so the tint cannot paint square corners over a rounded indicator,
  /// which reads as a rendering fault rather than as a press.
  final double indicatorRadius;

  /// The padding around a destination's content.
  final EdgeInsets rowPadding;

  /// The space between the glyph and the name, and between the name and a
  /// badge.
  final double gap;

  /// The smallest extent a destination's interactive region may take.
  ///
  /// Read from the runtime rather than measured here, so a destination and a
  /// button cannot end up disagreeing about how large a target has to be.
  /// Density tightens the space around things; it never shrinks what a finger
  /// must hit.
  final double minExtent;

  /// The tint painted over a destination while it is pressed or hovered.
  final Color overlayColor;

  /// How much of [overlayColor] is visible: one while reacting, zero at rest.
  ///
  /// An opacity rather than a nullable colour, so the transition animates
  /// without the colour itself fading between two hues — which would read as a
  /// third state nobody defined.
  final double overlayOpacity;

  /// Whether and how the indicator and the press tint may animate.
  ///
  /// The panel's own entrance is *not* resolved here: it is a reveal rather
  /// than a state change, so it answers a different question and is allowed a
  /// different answer under a reduced-motion preference.
  final IuxResolvedMotion motion;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxNavigationDrawerTokens &&
          other.scrim == scrim &&
          other.readableWidth == readableWidth &&
          other.titleStyle == titleStyle &&
          other.labelStyle == labelStyle &&
          other.iconSize == iconSize &&
          other.iconColor == iconColor &&
          other.indicatorFill == indicatorFill &&
          other.indicatorBorder == indicatorBorder &&
          other.indicatorBorderWidth == indicatorBorderWidth &&
          other.indicatorRadius == indicatorRadius &&
          other.rowPadding == rowPadding &&
          other.gap == gap &&
          other.minExtent == minExtent &&
          other.overlayColor == overlayColor &&
          other.overlayOpacity == overlayOpacity &&
          other.motion == motion;

  @override
  int get hashCode => Object.hashAll(<Object?>[
        scrim,
        readableWidth,
        titleStyle,
        labelStyle,
        iconSize,
        iconColor,
        indicatorFill,
        indicatorBorder,
        indicatorBorderWidth,
        indicatorRadius,
        rowPadding,
        gap,
        minExtent,
        overlayColor,
        overlayOpacity,
        motion,
      ]);
}

/// Resolves the complete appearance of a navigation drawer.
///
/// There is no `IuxNavigationDrawerTheme`, for the same reason there is no
/// navigation bar theme and no list theme: every decision the drawer makes is
/// already carried by the semantic palette, the geometry and the typography an
/// application configures once. A dedicated extension would only have created a
/// place to break the contrast guarantee and the target floor, which are the
/// two things a modal list of places must not lose.
abstract final class IuxNavigationDrawerResolver {
  /// Resolves the appearance of a destination in the given state.
  ///
  /// [current] is whether this destination is the one the user is on;
  /// [pressed] and [hovered] are the transient interaction states. The panel
  /// itself resolves with all three at their defaults, because a panel is
  /// neither current nor pressed.
  static IuxNavigationDrawerTokens resolve(
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

    return IuxNavigationDrawerTokens(
      scrim: _scrim(colors),
      // Narrow, not reading width: a drawer holds names, not prose. The wider
      // caps are sized for lines a reader scans, and applying one here would
      // produce a panel that covers the page it is supposed to be a way back
      // to.
      readableWidth:
          IuxContentWidthResolver.maxWidthFor(context, IuxContentWidth.narrow)!,
      titleStyle: typography.title.copyWith(color: colors.content.primary),
      labelStyle: typography.body.copyWith(color: content),
      // Scaled through the runtime rather than by Flutter, so the glyph and the
      // name beside it enlarge by the same factor and only once.
      iconSize: accessibility.scaleText(_drawerGlyph),
      iconColor: content,
      indicatorFill: colors.surface.selected,
      indicatorBorder: colors.border.selected,
      indicatorBorderWidth: geometry.borderWidth,
      indicatorRadius: geometry.radiusMedium,
      rowPadding: EdgeInsets.symmetric(
        horizontal: geometry.spacingMd,
        vertical: geometry.spacingSm,
      ),
      gap: geometry.spacingSm,
      minExtent: accessibility.minimumTouchTarget,
      // Pressed wins over hovered: a pointer that is pressing is also hovering,
      // and reporting the weaker of the two would leave a press with no
      // feedback at all.
      overlayColor: pressed ? colors.state.pressed : colors.state.hovered,
      overlayOpacity: pressed || hovered ? 1 : 0,
      // A state change, at the short scale. The indicator appearing answers
      // "where am I now"; a reduced preference shortens it, and no motion
      // removes the animation while leaving the indicator itself — the
      // information is the indicator, not the transition.
      motion: IuxMotionPolicy.resolve(
        context,
        role: IuxMotionRole.stateChange,
        scale: IuxMotionScale.short,
      ),
    );
  }

  /// The colour of the area outside the panel.
  ///
  /// The same derivation `IuxDialog` and `IuxBottomSheet` use, duplicated
  /// because it is private in both. It belongs in one place; see
  /// `docs/components/navigation-drawer.md` for the change that would put it
  /// there.
  static Color _scrim(IuxSemanticColors colors) {
    final Color base = colors.surface.base;
    final Color inverse = colors.surface.inverse;
    final Color darker =
        base.computeLuminance() <= inverse.computeLuminance() ? base : inverse;
    return darker.withValues(alpha: _kScrimOpacity);
  }
}
