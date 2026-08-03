import 'package:flutter/material.dart';

import '../../accessibility/iux_accessibility.dart';
import '../../motion/iux_motion_policy.dart';
import '../../motion/iux_motion_role.dart';
import '../../semantics/colors/iux_feedback_colors.dart';
import '../../semantics/iux_semantic_colors.dart';
import '../../themes/extensions/iux_geometry_theme.dart';
import '../../themes/extensions/iux_typography_theme.dart';

/// What an inline message is about.
///
/// These are the four categories the semantic layer already models in
/// [IuxFeedbackColorSet], named so a component can ask for one.
///
/// Deliberately *not* `IuxFeedbackRole`, which the feedback engine uses for
/// events. Half of that enum — `interaction`, `selection`, `progress` —
/// describes something that happened for an instant and cannot describe a
/// message sitting on a screen, and an API that accepted it would let a caller
/// write `role: IuxFeedbackRole.progress` and receive whichever colour the
/// mapping happened to fall through to.
///
/// The category is not only a colour. It selects the glyph and it is spoken to
/// a screen reader through the localised word the caller supplies, so it
/// survives both a monochrome screen and a user who never sees one.
enum IuxFeedbackCategory {
  /// Something the user should know, with nothing to do about it.
  ///
  /// The weakest category. An informational message never interrupts, and one
  /// that appears on every visit is one the user stops reading.
  info,

  /// An operation the user started completed.
  ///
  /// Worth stating only when the result is not visible on its own. A success
  /// message beside a list that already shows the new row is a second
  /// announcement of the same fact.
  success,

  /// A consequence to weigh before continuing.
  ///
  /// Nothing has failed. Use it where the user still has a choice — and say
  /// what the choice is, otherwise a warning is only anxiety.
  warning,

  /// Something failed, and the user cannot get what they asked for until it is
  /// resolved.
  ///
  /// The only category that must always answer two questions: what happened,
  /// and what to do next.
  error,
}

/// Everything needed to paint an inline message, and nothing about how.
///
/// [IuxAlert] and [IuxBanner] both read this, so the two cannot drift into
/// different glyphs, different outlines or different text roles — which is the
/// usual way a library ends up with a banner that does not look like its own
/// alert.
///
/// Every colour here comes from one [IuxFeedbackRoleColors]. That matters more
/// than it looks: [content] is measured against [surface] by the theme, so
/// anything painted with [content] on [surface] is contrast-checked by
/// construction. A control that reached for a general action colour instead
/// would be a colour pair nobody measured, sitting on a tinted background.
@immutable
final class IuxInlineFeedbackTokens {
  /// Creates a resolved appearance.
  const IuxInlineFeedbackTokens({
    required this.category,
    required this.glyph,
    required this.content,
    required this.surface,
    required this.border,
    required this.icon,
    required this.borderWidth,
    required this.radius,
    required this.actionRadius,
    required this.iconSize,
    required this.titleStyle,
    required this.messageStyle,
    required this.actionStyle,
    required this.motion,
  });

  /// The category these tokens were resolved for.
  final IuxFeedbackCategory category;

  /// The glyph that carries the category without colour.
  ///
  /// Fixed per category and not overridable. A caller who could choose the
  /// glyph could ship a tick on a failure, and the one signal that survives a
  /// monochrome screen would then be wrong.
  final IconData glyph;

  /// The text colour, held to 4.5:1 against [surface] by the theme.
  final Color content;

  /// The background of the message.
  final Color surface;

  /// The outline separating the message from the page.
  ///
  /// Measured against the page behind the message, not against [surface]. It
  /// is what makes the block identifiable as a distinct region when the tint
  /// alone is gentle — which it is on the standard profiles.
  final Color border;

  /// The glyph colour, held to 3:1 against [surface] by the theme.
  final Color icon;

  /// The outline width. Thickened by the theme under high contrast.
  final double borderWidth;

  /// The corner radius of an inset message.
  final double radius;

  /// The corner radius of the recovery control.
  final double actionRadius;

  /// The glyph edge length, already scaled for the user's text size.
  ///
  /// An icon that stays at 24 while text doubles is an icon that shrinks, and
  /// this one carries the category.
  final double iconSize;

  /// The style of the optional first line.
  final TextStyle titleStyle;

  /// The style of the message itself.
  final TextStyle messageStyle;

  /// The style of the recovery control's label.
  final TextStyle actionStyle;

  /// How the container may animate when the category changes underneath it.
  ///
  /// A state change, not an entrance: the parent decides when the message is
  /// on screen.
  final IuxResolvedMotion motion;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxInlineFeedbackTokens &&
          other.category == category &&
          other.glyph == glyph &&
          other.content == content &&
          other.surface == surface &&
          other.border == border &&
          other.icon == icon &&
          other.borderWidth == borderWidth &&
          other.radius == radius &&
          other.actionRadius == actionRadius &&
          other.iconSize == iconSize &&
          other.titleStyle == titleStyle &&
          other.messageStyle == messageStyle &&
          other.actionStyle == actionStyle &&
          other.motion == motion;

  @override
  int get hashCode => Object.hashAll(<Object>[
        category,
        glyph,
        content,
        surface,
        border,
        icon,
        borderWidth,
        radius,
        actionRadius,
        iconSize,
        titleStyle,
        messageStyle,
        actionStyle,
        motion,
      ]);
}

/// Resolves the complete appearance of an inline message.
///
/// There is no `IuxInlineFeedbackTheme`, and deliberately so: an inline message
/// has no decision an application could usefully vary that the semantic
/// palette, geometry and typography do not already carry. Adding an extension
/// would have created a second place to set an outline width and a second
/// place for it to disagree with the first.
abstract final class IuxInlineFeedbackResolver {
  /// Resolves the tokens for [category] at [context].
  static IuxInlineFeedbackTokens resolve(
    BuildContext context,
    IuxFeedbackCategory category,
  ) {
    final IuxAccessibility accessibility = IuxAccessibility.of(context);
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme typography = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);

    final IuxFeedbackRoleColors role = switch (category) {
      IuxFeedbackCategory.info => colors.feedback.info,
      IuxFeedbackCategory.success => colors.feedback.success,
      IuxFeedbackCategory.warning => colors.feedback.warning,
      IuxFeedbackCategory.error => colors.feedback.error,
    };

    return IuxInlineFeedbackTokens(
      category: category,
      glyph: _glyphFor(category),
      content: role.content,
      surface: role.surface,
      border: role.border,
      icon: role.icon,
      borderWidth: geometry.borderWidth,
      radius: geometry.radiusMedium,
      actionRadius: geometry.radiusSubtle,
      // Taken from the spacing scale rather than written as a number, so a
      // density change moves the glyph with everything around it, and scaled
      // with the text because the glyph is content and not decoration.
      iconSize: accessibility.scaleText(geometry.spacingLg),
      titleStyle: typography.title.copyWith(color: role.content),
      messageStyle: typography.body.copyWith(color: role.content),
      actionStyle: typography.label.copyWith(color: role.content),
      // A state change, and a short one. The only thing that can animate here
      // is the container changing category in place — a warning that becomes
      // an error while the user is looking at it. Everything else about the
      // message is owned by the parent, including whether it exists.
      motion: IuxMotionPolicy.resolve(
        context,
        role: IuxMotionRole.stateChange,
        scale: IuxMotionScale.short,
      ),
    );
  }

  /// The glyph for a category.
  ///
  /// Four shapes, not four colours: a circled "i", a circled tick, a triangle
  /// and a circled "!". A user with deuteranopia distinguishes the triangle
  /// from the circles without seeing a single hue, and a user reading a
  /// black-and-white screenshot of your app does too.
  static IconData _glyphFor(IuxFeedbackCategory category) => switch (category) {
        IuxFeedbackCategory.info => Icons.info_outline,
        IuxFeedbackCategory.success => Icons.check_circle_outline,
        IuxFeedbackCategory.warning => Icons.warning_amber_outlined,
        IuxFeedbackCategory.error => Icons.error_outline,
      };
}
