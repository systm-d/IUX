import 'package:flutter/material.dart';

import '../../accessibility/iux_accessibility.dart';
import '../../layout/iux_content_width.dart';
import '../../layout/iux_spacing_primitives.dart';
import '../../motion/iux_motion_policy.dart';
import '../../motion/iux_motion_role.dart';
import '../../semantics/iux_semantic_colors.dart';
import '../../themes/extensions/iux_geometry_theme.dart';
import '../../themes/extensions/iux_typography_theme.dart';

/// The glyph edge length before text scaling, in logical pixels.
///
/// The same figure the button theme and the status indicator use. A help glyph
/// beside a label that is a different size to a button glyph beside a label is
/// the kind of inconsistency nobody can name and everybody notices.
const double _kGlyphSize = 20;

/// The longest message an [IuxTooltip] will carry, counted in characters.
///
/// This is the boundary between a tooltip and a disclosed help panel, and it is
/// enforced rather than advised: a floating box is the worst reading surface in
/// the library, so the component refuses the content that would make it one.
///
/// Eighty characters is roughly two lines at the default text size on a phone,
/// and four to five lines at 200% on a 320-pixel screen — already at the edge
/// of what may reasonably float over a page. Anything longer is prose, prose
/// needs a place the user can scroll, re-read and leave open, and that place is
/// `IuxContextualHelp`.
///
/// The exact figure is a judgement rather than a measured threshold. What is
/// not a judgement is that *some* ceiling has to exist and has to be checked by
/// the compiler's nearest available equivalent, because "keep tooltips short"
/// written in a document has never once kept a tooltip short.
const int kIuxTooltipMaximumCharacters = 80;

/// Everything needed to paint a tooltip, and nothing about how.
///
/// Every pair here is one the theme already measures on all four profiles:
/// `content.primary` reaches 4.5:1 on `surface.overlay`, and `border.strong`
/// reaches 3:1 on the page. A component that reached for its own colours would
/// be painting a pair nobody measured, on a box floating over arbitrary
/// content.
@immutable
final class IuxTooltipTokens {
  /// Creates a resolved appearance.
  const IuxTooltipTokens({
    required this.background,
    required this.foreground,
    required this.border,
    required this.borderWidth,
    required this.radius,
    required this.padding,
    required this.gap,
    required this.margin,
    required this.maxWidth,
    required this.textStyle,
    required this.entrance,
  });

  /// The container colour.
  ///
  /// The overlay surface, the same one a dialog and a bottom sheet sit on. A
  /// tooltip floats above the page, so it takes the level the theme resolved
  /// for things that float above the page — and two floating surfaces that
  /// looked different would be two visual languages for one idea.
  final Color background;

  /// The text colour, held to 4.5:1 against [background] by the theme.
  final Color foreground;

  /// The outline separating the tooltip from whatever it floats over.
  final Color border;

  /// The outline width.
  ///
  /// The theme's *strong* width, for the reason the transient message uses it:
  /// this floats over content the theme never measured, which may be a
  /// photograph, and the edge of such a box may not be the first thing to
  /// disappear.
  final double borderWidth;

  /// The corner radius of the container.
  final double radius;

  /// Padding inside the container.
  final EdgeInsets padding;

  /// The distance between the anchor's edge and the tooltip's.
  ///
  /// Doubles as the height of the transparent bridge that keeps the pointer
  /// inside the tooltip's mouse region while it travels from the anchor. WCAG
  /// 2.2 SC 1.4.13 requires the additional content to be hoverable; a gap the
  /// pointer falls through would dismiss the tooltip on the way to reading it.
  final double gap;

  /// The smallest distance the tooltip keeps from the edge of the screen.
  final double margin;

  /// The widest the tooltip may grow.
  ///
  /// Capped in characters rather than pixels, so enlarging the text widens the
  /// box instead of squeezing the same words into a narrower column.
  final double maxWidth;

  /// The message style, already carrying [foreground].
  ///
  /// The body role rather than the supporting one. A tooltip exists for the
  /// user who could not decode a glyph; answering them in the smallest type in
  /// the library would be an odd way to help.
  final TextStyle textStyle;

  /// How the tooltip appears.
  ///
  /// A fade and nothing else. It arrives beside the control the user just
  /// touched, so "where did this come from" is already answered, and travel
  /// across the screen is a known vestibular trigger.
  final IuxResolvedMotion entrance;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxTooltipTokens &&
          other.background == background &&
          other.foreground == foreground &&
          other.border == border &&
          other.borderWidth == borderWidth &&
          other.radius == radius &&
          other.padding == padding &&
          other.gap == gap &&
          other.margin == margin &&
          other.maxWidth == maxWidth &&
          other.textStyle == textStyle &&
          other.entrance == entrance;

  @override
  int get hashCode => Object.hashAll(<Object>[
        background,
        foreground,
        border,
        borderWidth,
        radius,
        padding,
        gap,
        margin,
        maxWidth,
        textStyle,
        entrance,
      ]);
}

/// Resolves the complete appearance of a tooltip.
///
/// There is no `IuxTooltipTheme`. A tooltip has no decision an application
/// could usefully vary that the semantic palette, geometry and typography do
/// not already carry — and the two things an application might reach for, how
/// long it stays and how quickly it appears, are deliberately not values at
/// all: this component has no clock.
abstract final class IuxTooltipResolver {
  /// Resolves the tokens in force at [context].
  static IuxTooltipTokens resolve(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme typography = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);

    return IuxTooltipTokens(
      background: colors.surface.overlay,
      foreground: colors.content.primary,
      border: colors.border.strong,
      borderWidth: geometry.strongBorderWidth,
      radius: geometry.radiusMedium,
      padding: IuxInsets.compact(context),
      gap: geometry.spacingXs,
      margin: geometry.spacingSm,
      // Narrow, not reading width: a tooltip is a phrase, and a phrase set on a
      // seventy-character measure is a phrase floating in an empty box.
      maxWidth: IuxContentWidthResolver.maxWidthFor(
            context,
            IuxContentWidth.narrow,
          ) ??
          double.infinity,
      textStyle: typography.body.copyWith(color: colors.content.primary),
      entrance: IuxMotionPolicy.resolve(
        context,
        role: IuxMotionRole.enter,
        scale: IuxMotionScale.short,
      ),
    );
  }
}

/// Everything needed to paint a contextual help disclosure.
///
/// The pairs are the theme's measured ones again: `content.primary` reaches
/// 4.5:1 on `surface.base` and on `surface.subtle`, which are the two surfaces
/// this component paints on.
@immutable
final class IuxContextualHelpTokens {
  /// Creates a resolved appearance.
  const IuxContextualHelpTokens({
    required this.glyph,
    required this.stateGlyph,
    required this.glyphColor,
    required this.glyphSize,
    required this.labelStyle,
    required this.helpStyle,
    required this.panelBackground,
    required this.panelBorder,
    required this.borderWidth,
    required this.radius,
    required this.panelPadding,
    required this.controlPadding,
    required this.gap,
    required this.minimumSize,
  });

  /// The glyph that marks the control as being about help.
  ///
  /// Redundant with the label, which is why it is excluded from the semantic
  /// tree: an icon carrying information the name does not is information a
  /// screen-reader user never receives.
  final IconData glyph;

  /// The glyph that says whether the panel is open, by pointing.
  ///
  /// A direction, not a hue: it survives a monochrome screen, a colour-vision
  /// deficiency and a screenshot printed in black and white. The state is
  /// carried a second time in the semantic tree, where the platform speaks it
  /// in the user's own language.
  final IconData stateGlyph;

  /// The glyph colour, held to 4.5:1 against the page by the theme.
  ///
  /// The *content* ratio rather than the 3:1 non-text one, because these two
  /// glyphs sit inside a control's label and are read alongside it.
  final Color glyphColor;

  /// The glyph edge length, already scaled for the user's text size.
  final double glyphSize;

  /// The control label's style, already carrying [glyphColor].
  final TextStyle labelStyle;

  /// The disclosed text's style.
  ///
  /// The body role. Help is running text and is read rather than scanned, so it
  /// is set at the size the library uses for anything a user must read — not at
  /// the supporting size, which is where help usually ends up and where it
  /// stops being read at all.
  final TextStyle helpStyle;

  /// The panel's background: a recessed surface that groups it with nothing
  /// else on the page.
  final Color panelBackground;

  /// The panel's outline.
  ///
  /// `border.subtle`, the one border role exempt from the 3:1 minimum, and the
  /// right one here for exactly the reason its own documentation gives: it may
  /// not delimit an interactive control, and this panel is not one. The fill
  /// and the outline together separate the panel; neither carries meaning.
  final Color panelBorder;

  /// The outline width.
  final double borderWidth;

  /// The panel's corner radius.
  final double radius;

  /// Padding inside the panel.
  final EdgeInsets panelPadding;

  /// Padding around the control's row.
  ///
  /// Vertical only. The control lines up with whatever it annotates, and a
  /// horizontal inset would set the question a few pixels to the side of the
  /// field it is about.
  final EdgeInsets controlPadding;

  /// Space between the glyph and the label, and between the control and the
  /// panel.
  final double gap;

  /// The smallest permitted interactive dimension.
  final double minimumSize;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxContextualHelpTokens &&
          other.glyph == glyph &&
          other.stateGlyph == stateGlyph &&
          other.glyphColor == glyphColor &&
          other.glyphSize == glyphSize &&
          other.labelStyle == labelStyle &&
          other.helpStyle == helpStyle &&
          other.panelBackground == panelBackground &&
          other.panelBorder == panelBorder &&
          other.borderWidth == borderWidth &&
          other.radius == radius &&
          other.panelPadding == panelPadding &&
          other.controlPadding == controlPadding &&
          other.gap == gap &&
          other.minimumSize == minimumSize;

  @override
  int get hashCode => Object.hashAll(<Object>[
        glyph,
        stateGlyph,
        glyphColor,
        glyphSize,
        labelStyle,
        helpStyle,
        panelBackground,
        panelBorder,
        borderWidth,
        radius,
        panelPadding,
        controlPadding,
        gap,
        minimumSize,
      ]);
}

/// Resolves the appearance of a contextual help disclosure.
abstract final class IuxContextualHelpResolver {
  /// Resolves the tokens for the given state at [context].
  static IuxContextualHelpTokens resolve(
    BuildContext context, {
    required bool expanded,
  }) {
    final IuxAccessibility accessibility = IuxAccessibility.of(context);
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme typography = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);

    return IuxContextualHelpTokens(
      glyph: Icons.help_outline,
      stateGlyph: expanded ? Icons.expand_less : Icons.expand_more,
      glyphColor: colors.content.primary,
      // Scaled through the runtime rather than by Flutter, so the glyphs and
      // the label enlarge by the same factor.
      glyphSize: accessibility.scaleText(_kGlyphSize),
      labelStyle: typography.label.copyWith(color: colors.content.primary),
      helpStyle: typography.body.copyWith(color: colors.content.primary),
      panelBackground: colors.surface.subtle,
      panelBorder: colors.border.subtle,
      borderWidth: geometry.borderWidth,
      radius: geometry.radiusMedium,
      panelPadding: IuxInsets.surface(context),
      controlPadding: EdgeInsets.symmetric(vertical: geometry.spacingXxs),
      gap: geometry.spacingXs,
      minimumSize: geometry.minimumTouchTarget,
    );
  }
}
