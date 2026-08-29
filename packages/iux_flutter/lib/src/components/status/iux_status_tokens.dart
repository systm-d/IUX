import 'package:flutter/material.dart';

import '../../accessibility/iux_accessibility.dart';
import '../../accessibility/iux_category_glyphs.dart';
import '../../layout/iux_spacing_primitives.dart';
import '../../motion/iux_motion_policy.dart';
import '../../motion/iux_motion_role.dart';
import '../../semantics/colors/iux_feedback_colors.dart';
import '../../semantics/iux_semantic_colors.dart';
import '../../themes/extensions/iux_geometry_theme.dart';
import '../../themes/extensions/iux_typography_theme.dart';
import 'iux_status_model.dart';

/// The glyph edge length before text scaling, in logical pixels.
///
/// The same figure the button theme uses for its icons. A status glyph beside a
/// label that is a different size to a button glyph beside a label is the kind
/// of inconsistency nobody can name and everybody notices.
const double _glyphSize = 20;

/// Everything needed to paint a status indicator, and nothing about how.
///
/// There is no `IuxStatusTheme`. A status indicator has no decision an
/// application could usefully vary that the semantic palette, geometry and
/// typography do not already carry, and a fourth place to set a padding is a
/// fourth place for it to disagree with the others.
@immutable
final class IuxStatusTokens {
  /// Creates a resolved appearance.
  const IuxStatusTokens({
    required this.glyph,
    required this.glyphColor,
    required this.glyphSize,
    required this.background,
    required this.border,
    required this.borderWidth,
    required this.padding,
    required this.gap,
    required this.textStyle,
  });

  /// The shape that distinguishes this tone from the others.
  ///
  /// This is the signal that survives a monochrome screen. It is redundant with
  /// the label rather than a replacement for it — an icon nobody recognises
  /// carries nothing — which is why it is excluded from the semantic tree.
  final IconData glyph;

  /// The glyph colour, held to 3:1 against [background] by the theme.
  final Color glyphColor;

  /// The glyph edge length, already scaled for the user's text size.
  final double glyphSize;

  /// The container colour.
  final Color background;

  /// The outline colour, held to 3:1 against the page by the theme.
  final Color border;

  /// The outline width.
  final double borderWidth;

  /// Padding inside the container.
  final EdgeInsets padding;

  /// Space between the glyph and the label.
  final double gap;

  /// The label style, already carrying its measured colour.
  final TextStyle textStyle;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxStatusTokens &&
          other.glyph == glyph &&
          other.glyphColor == glyphColor &&
          other.glyphSize == glyphSize &&
          other.background == background &&
          other.border == border &&
          other.borderWidth == borderWidth &&
          other.padding == padding &&
          other.gap == gap &&
          other.textStyle == textStyle;

  @override
  int get hashCode => Object.hashAll(<Object>[
        glyph,
        glyphColor,
        glyphSize,
        background,
        border,
        borderWidth,
        padding,
        gap,
        textStyle,
      ]);
}

/// Resolves the appearance of a status indicator.
abstract final class IuxStatusResolver {
  /// The glyph that identifies [tone] without using its colour.
  ///
  /// Public so the rule can be asserted directly: the four glyphs must stay
  /// distinct from one another, because two tones drawn with the same shape are
  /// two tones separated by hue alone — exactly the failure this component
  /// exists to prevent. `IUX-PALETTE-PERCEPTION-001` measured how completely
  /// the colour channel fails for two of these four under deuteranopia, which
  /// is why the shapes are defined once, in [IuxCategoryGlyphs], rather than
  /// per component.
  ///
  /// [IuxStatusTone.neutral] takes the info shape: the two enums name the
  /// resting category differently and mean the same thing by it.
  static IconData glyph(IuxStatusTone tone) => switch (tone) {
        IuxStatusTone.neutral => IuxCategoryGlyphs.info,
        IuxStatusTone.success => IuxCategoryGlyphs.success,
        IuxStatusTone.warning => IuxCategoryGlyphs.warning,
        IuxStatusTone.error => IuxCategoryGlyphs.error,
      };

  /// Resolves the tokens for [tone] at [context].
  static IuxStatusTokens resolve(BuildContext context, IuxStatusTone tone) {
    final IuxAccessibility accessibility = IuxAccessibility.of(context);
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme typography = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);

    // The feedback roles, reused rather than reinvented. Their contrast pairs
    // are already measured on all four theme profiles — content on surface at
    // 4.5:1, icon on surface at 3:1, border on the page at 3:1 — so a status
    // indicator inherits guarantees instead of asking for new ones.
    final IuxFeedbackRoleColors role = switch (tone) {
      IuxStatusTone.neutral => colors.feedback.info,
      IuxStatusTone.success => colors.feedback.success,
      IuxStatusTone.warning => colors.feedback.warning,
      IuxStatusTone.error => colors.feedback.error,
    };

    return IuxStatusTokens(
      glyph: glyph(tone),
      glyphColor: role.icon,
      // Scaled through the runtime rather than by Flutter, so the glyph and the
      // label enlarge by the same factor. A user who enlarged their text
      // because 14pt was unreadable gains nothing from a 20-pixel symbol that
      // stayed where it was.
      glyphSize: accessibility.scaleText(_glyphSize),
      background: role.surface,
      border: role.border,
      borderWidth: geometry.borderWidth,
      padding: IuxInsets.compact(context),
      gap: geometry.spacingXs,
      textStyle: typography.label.copyWith(color: role.content),
    );
  }
}

/// Everything needed to paint a badge.
@immutable
final class IuxBadgeTokens {
  /// Creates a resolved appearance.
  const IuxBadgeTokens({
    required this.background,
    required this.foreground,
    required this.padding,
    required this.minimumExtent,
    required this.markerSize,
    required this.textStyle,
  });

  /// The container colour.
  final Color background;

  /// The numeral colour, held to 4.5:1 against [background] by the theme.
  final Color foreground;

  /// Padding around the numeral.
  final EdgeInsets padding;

  /// The smallest width a counted badge may take.
  ///
  /// Keeps a one-digit badge from collapsing into a lozenge narrower than it is
  /// tall. It is a *shape* floor, not a touch target: a badge is not
  /// interactive and has no target of its own.
  final double minimumExtent;

  /// The diameter of a badge that shows no number.
  ///
  /// Scaled with the user's text size. A marker that stayed eight pixels while
  /// everything around it doubled is a marker the person who enlarged their
  /// text can no longer see.
  final double markerSize;

  /// The numeral style, already carrying [foreground].
  final TextStyle textStyle;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxBadgeTokens &&
          other.background == background &&
          other.foreground == foreground &&
          other.padding == padding &&
          other.minimumExtent == minimumExtent &&
          other.markerSize == markerSize &&
          other.textStyle == textStyle;

  @override
  int get hashCode => Object.hash(
        background,
        foreground,
        padding,
        minimumExtent,
        markerSize,
        textStyle,
      );
}

/// Resolves the appearance of a badge.
abstract final class IuxBadgeResolver {
  /// Resolves the tokens in force at [context].
  static IuxBadgeTokens resolve(BuildContext context) {
    final IuxAccessibility accessibility = IuxAccessibility.of(context);
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme typography = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);

    // The primary action pair, because it is the one role the theme measures at
    // 4.5:1 in both directions and the one an application already recognises as
    // "the accent". A badge is deliberately not toned: red for "3 unread" would
    // be reporting an error that has not happened, and a per-tone badge would
    // duplicate the status indicator with none of its words.
    final Color background = colors.action.primary.background;

    // The numeral is small and it is the whole content, so it takes the label
    // role rather than a supporting one and never shrinks below it.
    final TextStyle textStyle = typography.label.copyWith(
      color: colors.action.primary.foreground,
    );

    final double extent = accessibility.scaleText(geometry.spacingLg);

    return IuxBadgeTokens(
      background: background,
      foreground: colors.action.primary.foreground,
      padding: EdgeInsets.symmetric(
        horizontal: geometry.spacingXs,
        vertical: geometry.spacingXxs,
      ),
      minimumExtent: extent,
      // Half the counted extent: large enough to be seen against a busy row,
      // small enough that it reads as a marker rather than as a control.
      markerSize: extent / 2,
      textStyle: textStyle,
    );
  }
}

/// The visual state a chip resolves to.
///
/// Focus is deliberately absent, for the same reason it is absent from the
/// button states: a focus indicator has to remain visible whatever else is
/// true, so it cannot be one value in a list where only one wins.
enum IuxChipState {
  /// Interactive and not chosen.
  unselected,

  /// Interactive and chosen.
  selected,

  /// Not interactive, and announced as such.
  disabled,

  /// A read-only tag. Never interactive, never focusable.
  readOnly,
}

/// Everything needed to paint a chip.
@immutable
final class IuxChipTokens {
  /// Creates a resolved appearance.
  const IuxChipTokens({
    required this.state,
    required this.background,
    required this.pressedBackground,
    required this.foreground,
    required this.border,
    required this.borderWidth,
    required this.radius,
    required this.padding,
    required this.minimumSize,
    required this.checkGlyph,
    required this.glyphSize,
    required this.gap,
    required this.textStyle,
    required this.motion,
  });

  /// The state these tokens were resolved for.
  final IuxChipState state;

  /// The container colour.
  final Color background;

  /// The container colour while the chip is being activated.
  ///
  /// Equal to [background] where the chip accepts no input, so a disabled or
  /// read-only chip cannot flicker under a stray gesture. Press feedback exists
  /// because hover does not: on a touch screen this is the only confirmation
  /// that a tap landed before the parent rebuilds.
  final Color pressedBackground;

  /// The label colour.
  final Color foreground;

  /// The outline colour.
  final Color border;

  /// The outline width.
  ///
  /// Thicker when selected. Weight is a second non-colour signal, on top of the
  /// checkmark: a user with a monochrome display sees the outline change even
  /// where the glyph is small.
  final double borderWidth;

  /// The corner radius.
  final double radius;

  /// Padding inside the container.
  ///
  /// Already compensated for [borderWidth], so a chip is exactly the same size
  /// chosen as unchosen. Selecting one must not move the chips beside it.
  final EdgeInsets padding;

  /// The smallest permitted interactive dimension.
  ///
  /// Zero for a read-only tag, which is not a target and must not be padded out
  /// to look like one.
  final double minimumSize;

  /// The glyph that marks a chosen chip.
  final IconData checkGlyph;

  /// The glyph edge length, already scaled for the user's text size.
  final double glyphSize;

  /// Space between the glyph slot and the label.
  final double gap;

  /// The label style, already carrying [foreground].
  final TextStyle textStyle;

  /// How the container may travel between two states.
  final IuxResolvedMotion motion;

  /// Whether this state accepts input.
  bool get isInteractive =>
      state == IuxChipState.unselected || state == IuxChipState.selected;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxChipTokens &&
          other.state == state &&
          other.background == background &&
          other.pressedBackground == pressedBackground &&
          other.foreground == foreground &&
          other.border == border &&
          other.borderWidth == borderWidth &&
          other.radius == radius &&
          other.padding == padding &&
          other.minimumSize == minimumSize &&
          other.checkGlyph == checkGlyph &&
          other.glyphSize == glyphSize &&
          other.gap == gap &&
          other.textStyle == textStyle &&
          other.motion == motion;

  @override
  int get hashCode => Object.hashAll(<Object>[
        state,
        background,
        pressedBackground,
        foreground,
        border,
        borderWidth,
        radius,
        padding,
        minimumSize,
        checkGlyph,
        glyphSize,
        gap,
        textStyle,
        motion,
      ]);
}

/// Resolves the appearance of a chip.
///
/// One resolver for both chip widgets, so a tag and a filter chip cannot drift
/// into different paddings — while [IuxChipState] keeps their difference
/// explicit rather than accidental.
abstract final class IuxChipResolver {
  /// Resolves the tokens for [state] at [context].
  static IuxChipTokens resolve(BuildContext context, IuxChipState state) {
    final IuxAccessibility accessibility = IuxAccessibility.of(context);
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme typography = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);

    // Every pair below is one the theme already measures on all four profiles:
    // content.primary reaches 4.5:1 on base, subtle and selected; the
    // interactive and strong borders reach 3:1 on base; disabled content
    // reaches 3:1 on the disabled surface.
    final (Color background, Color foreground, Color border) = switch (state) {
      IuxChipState.unselected => (
          colors.surface.base,
          colors.content.primary,
          colors.border.interactive,
        ),
      IuxChipState.selected => (
          colors.surface.selected,
          colors.content.primary,
          colors.border.strong,
        ),
      IuxChipState.disabled => (
          colors.surface.disabled,
          colors.content.disabled,
          colors.border.disabled,
        ),
      // A recessed fill and a subtle outline. border.subtle is the one border
      // role exempt from 3:1, and its documentation forbids using it to delimit
      // an interactive control — which makes it exactly right here, and makes a
      // tag look different from a filter chip rather than merely behave
      // differently.
      IuxChipState.readOnly => (
          colors.surface.subtle,
          colors.content.primary,
          colors.border.subtle,
        ),
    };

    final double borderWidth = state == IuxChipState.selected
        ? geometry.strongBorderWidth
        : geometry.borderWidth;

    // The heavier outline is drawn *inside* the reserved space rather than
    // added to it. A border that grew the box would make every chip two pixels
    // wider the moment it was chosen, which reflows the whole group and moves
    // the chips the user was about to press next — the same defect the
    // reserved checkmark slot avoids, one layer down.
    final EdgeInsets padding = IuxInsets.compact(context) +
        EdgeInsets.all(geometry.strongBorderWidth - borderWidth);

    return IuxChipTokens(
      state: state,
      background: background,
      // A neutral tint over the chip rather than the selected fill, which would
      // show every press as a selection the user has not made yet.
      pressedBackground:
          state == IuxChipState.unselected || state == IuxChipState.selected
              ? colors.state.pressed
              : background,
      foreground: foreground,
      border: border,
      borderWidth: borderWidth,
      radius: geometry.radiusProminent,
      padding: padding,
      // A tag is not a control. Padding it out to 48 would make it look like
      // one, and a row of things that look tappable and are not is worse than a
      // row that looks inert.
      minimumSize:
          state == IuxChipState.readOnly ? 0 : geometry.minimumTouchTarget,
      checkGlyph: Icons.check,
      glyphSize: accessibility.scaleText(_glyphSize),
      gap: geometry.spacingXs,
      textStyle: typography.label.copyWith(color: foreground),
      // A state change, so a reduced-motion preference shortens it and no
      // motion removes it — without the checkmark, the outline weight or the
      // announced selection ever being lost.
      motion: IuxMotionPolicy.resolve(
        context,
        role: IuxMotionRole.stateChange,
        scale: IuxMotionScale.short,
      ),
    );
  }
}
