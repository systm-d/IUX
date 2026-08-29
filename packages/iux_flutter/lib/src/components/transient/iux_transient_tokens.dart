import 'package:flutter/material.dart';

import '../../accessibility/iux_accessibility.dart';
import '../../accessibility/iux_category_glyphs.dart';
import '../../motion/iux_motion_policy.dart';
import '../../motion/iux_motion_role.dart';
import '../../semantics/colors/iux_feedback_colors.dart';
import '../../semantics/iux_semantic_colors.dart';
import '../../themes/extensions/iux_geometry_theme.dart';
import '../../themes/extensions/iux_typography_theme.dart';
import 'iux_transient_message.dart';

/// Everything needed to paint a transient message, and nothing about how.
///
/// Every colour comes from one [IuxFeedbackRoleColors], which is what makes the
/// pairs contrast-checked by construction: [content] is measured against
/// [surface] by the theme, and [border] against the page. A component that
/// reached for a general content colour instead would be painting a pair
/// nobody measured on a tinted block floating over arbitrary content.
@immutable
final class IuxTransientTokens {
  /// Creates a resolved appearance.
  const IuxTransientTokens({
    required this.tone,
    required this.glyph,
    required this.content,
    required this.surface,
    required this.border,
    required this.icon,
    required this.borderWidth,
    required this.radius,
    required this.actionRadius,
    required this.iconSize,
    required this.messageStyle,
    required this.actionStyle,
    required this.entrance,
  });

  /// The tone these tokens were resolved for.
  final IuxTransientTone tone;

  /// The glyph that carries the tone without colour, or null when there is
  /// nothing to carry.
  ///
  /// Null for [IuxTransientTone.neutral], which asserts nothing beyond the
  /// words: a generic "information" glyph on "Copied" is a shape the user has
  /// to decode before discovering it meant nothing.
  final IconData? glyph;

  /// The text colour, held to 4.5:1 against [surface] by the theme.
  final Color content;

  /// The background of the message.
  final Color surface;

  /// The outline separating the message from whatever it floats over.
  final Color border;

  /// The glyph colour, held to 3:1 against [surface] by the theme.
  final Color icon;

  /// The outline width.
  ///
  /// The theme's *strong* width, not its standard one, and that is the single
  /// visual difference from an inline alert. An alert sits in the page's own
  /// flow against a background the theme measured. This floats over whatever
  /// happens to be beneath it, which may be a photograph.
  final double borderWidth;

  /// The corner radius of the container.
  final double radius;

  /// The corner radius of the action control.
  final double actionRadius;

  /// The glyph edge length, already scaled for the user's text size.
  final double iconSize;

  /// The style of the message itself.
  final TextStyle messageStyle;

  /// The style of the action control's label.
  final TextStyle actionStyle;

  /// How the message appears, and how it re-appears when it is replaced.
  ///
  /// A fade and nothing else. Travel across the screen is a known vestibular
  /// trigger, and a message arriving at the bottom edge of a screen has nowhere
  /// informative to travel from — "where did this come from" is answered by
  /// the fact that it is where every transient message in the application
  /// appears.
  final IuxResolvedMotion entrance;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxTransientTokens &&
          other.tone == tone &&
          other.glyph == glyph &&
          other.content == content &&
          other.surface == surface &&
          other.border == border &&
          other.icon == icon &&
          other.borderWidth == borderWidth &&
          other.radius == radius &&
          other.actionRadius == actionRadius &&
          other.iconSize == iconSize &&
          other.messageStyle == messageStyle &&
          other.actionStyle == actionStyle &&
          other.entrance == entrance;

  @override
  int get hashCode => Object.hashAll(<Object?>[
        tone,
        glyph,
        content,
        surface,
        border,
        icon,
        borderWidth,
        radius,
        actionRadius,
        iconSize,
        messageStyle,
        actionStyle,
        entrance,
      ]);
}

/// Resolves the complete appearance of a transient message.
///
/// There is no `IuxTransientTheme`. A message this small has no decision an
/// application could usefully vary that the semantic palette, geometry and
/// typography do not already carry, and the one thing an application might
/// genuinely want to change — how long it stays — is deliberately not a
/// theme value: a theme is a look, and reading time is not.
abstract final class IuxTransientResolver {
  /// Resolves the tokens for [tone] at [context].
  static IuxTransientTokens resolve(
      BuildContext context, IuxTransientTone tone) {
    final IuxAccessibility accessibility = IuxAccessibility.of(context);
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme typography = IuxTypographyTheme.of(context);
    final IuxSemanticColors palette = IuxSemanticColors.of(context);

    // Two tones, two feedback roles. The set also holds warning and error, and
    // nothing here can reach them: IuxTransientTone has no value that maps to
    // either, which is the refusal expressed as a type rather than as advice.
    final IuxFeedbackRoleColors role = switch (tone) {
      IuxTransientTone.neutral => palette.feedback.info,
      IuxTransientTone.success => palette.feedback.success,
    };

    return IuxTransientTokens(
      tone: tone,
      glyph: switch (tone) {
        IuxTransientTone.neutral => null,
        IuxTransientTone.success => IuxCategoryGlyphs.success,
      },
      content: role.content,
      surface: role.surface,
      border: role.border,
      icon: role.icon,
      borderWidth: geometry.strongBorderWidth,
      radius: geometry.radiusMedium,
      actionRadius: geometry.radiusSubtle,
      // Taken from the spacing scale rather than written as a number, and
      // scaled with the text: the glyph is content, and an icon that stays at
      // 24 while the text beside it doubles is an icon that shrank.
      iconSize: accessibility.scaleText(geometry.spacingLg),
      messageStyle: typography.body.copyWith(color: role.content),
      actionStyle: typography.label.copyWith(color: role.content),
      entrance: IuxMotionPolicy.resolve(
        context,
        role: IuxMotionRole.enter,
        scale: IuxMotionScale.short,
      ),
    );
  }
}
