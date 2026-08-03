import 'package:flutter/material.dart';

import '../../accessibility/iux_accessibility.dart';
import '../../layout/iux_spacing_primitives.dart';
import '../../semantics/iux_semantic_colors.dart';
import '../../themes/extensions/iux_geometry_theme.dart';
import '../../themes/extensions/iux_typography_theme.dart';
import 'iux_media_model.dart';

/// The glyph edge length of a small icon, before text scaling.
///
/// The same figure the status indicator and the chip use for the glyph that
/// sits beside a label. A glyph that changed size when it moved between two
/// components is the kind of inconsistency nobody can name and everybody sees.
const double _smallGlyph = 20;

/// The glyph edge length of a standalone icon, before text scaling.
const double _standardGlyph = 24;

/// The diameter of an avatar in a list row, before text scaling.
const double _standardAvatar = 40;

/// The diameter of an avatar in a profile header, before text scaling.
const double _largeAvatar = 64;

/// Everything needed to paint a glyph, and nothing about how.
///
/// There is no `IuxIconTheme`. An icon has no decision an application could
/// usefully vary that the semantic palette and the accessibility runtime do not
/// already carry, and a second place to set a glyph size is a second place for
/// it to disagree with the first.
@immutable
final class IuxIconTokens {
  /// Creates a resolved appearance.
  const IuxIconTokens({required this.size, required this.color});

  /// The glyph edge length, already scaled for the user's text size.
  final double size;

  /// The glyph colour, held to at least 4.5:1 against the surfaces it may
  /// appear on by the theme.
  final Color color;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxIconTokens && other.size == size && other.color == color;

  @override
  int get hashCode => Object.hash(size, color);
}

/// Resolves the appearance of a glyph.
abstract final class IuxIconResolver {
  /// Resolves the tokens for [size] and [emphasis] at [context].
  static IuxIconTokens resolve(
    BuildContext context, {
    IuxIconSize size = IuxIconSize.standard,
    IuxIconEmphasis emphasis = IuxIconEmphasis.primary,
  }) {
    final IuxAccessibility accessibility = IuxAccessibility.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);

    return IuxIconTokens(
      // Scaled through the runtime rather than by Flutter, so a glyph and the
      // label beside it enlarge by the same factor and only once. A user who
      // enlarged their text because 14pt was unreadable gains nothing from a
      // 20-pixel symbol that stayed where it was.
      size: accessibility.scaleText(switch (size) {
        IuxIconSize.small => _smallGlyph,
        IuxIconSize.standard => _standardGlyph,
      }),
      color: switch (emphasis) {
        IuxIconEmphasis.primary => colors.content.primary,
        IuxIconEmphasis.secondary => colors.content.secondary,
      },
    );
  }
}

/// Everything needed to paint an avatar.
@immutable
final class IuxAvatarTokens {
  /// Creates a resolved appearance.
  const IuxAvatarTokens({
    required this.diameter,
    required this.background,
    required this.foreground,
    required this.border,
    required this.borderWidth,
    required this.fallbackGlyph,
    required this.glyphSize,
    required this.initialsStyle,
    required this.padding,
  });

  /// The circle's edge length, already scaled for the user's text size.
  final double diameter;

  /// The circle's fill, behind the photo and behind the fallback.
  ///
  /// Always painted, including under a photograph. A transparent avatar whose
  /// picture has not arrived yet is a hole in the layout rather than a slot
  /// waiting to be filled.
  final Color background;

  /// The colour of the initials and of the fallback glyph.
  ///
  /// Held to 4.5:1 against [background] by the theme, because the initials are
  /// text and are read at a small size inside a small circle.
  final Color foreground;

  /// The circle's outline.
  ///
  /// A photograph with a pale edge otherwise bleeds into a pale page and the
  /// avatar stops being one object. The outline is decoration: it carries no
  /// information, which is why it may take the one border role exempt from the
  /// 3:1 floor.
  final Color border;

  /// The outline width.
  final double borderWidth;

  /// The glyph drawn when there is neither a photograph nor initials.
  ///
  /// Excluded from the semantic tree wherever it is drawn: it claims nothing
  /// about who the avatar belongs to, and the accessible name already says.
  final IconData fallbackGlyph;

  /// The fallback glyph's edge length.
  final double glyphSize;

  /// The style of the initials, already carrying [foreground].
  ///
  /// A typography role rather than a fraction of [diameter], so the initials
  /// stay on the same scale as every other piece of text in the interface.
  final TextStyle initialsStyle;

  /// Space kept between the initials and the circle's edge.
  final EdgeInsets padding;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxAvatarTokens &&
          other.diameter == diameter &&
          other.background == background &&
          other.foreground == foreground &&
          other.border == border &&
          other.borderWidth == borderWidth &&
          other.fallbackGlyph == fallbackGlyph &&
          other.glyphSize == glyphSize &&
          other.initialsStyle == initialsStyle &&
          other.padding == padding;

  @override
  int get hashCode => Object.hashAll(<Object>[
        diameter,
        background,
        foreground,
        border,
        borderWidth,
        fallbackGlyph,
        glyphSize,
        initialsStyle,
        padding,
      ]);
}

/// Resolves the appearance of an avatar.
abstract final class IuxAvatarResolver {
  /// Resolves the tokens for [size] at [context].
  static IuxAvatarTokens resolve(
    BuildContext context, {
    IuxAvatarSize size = IuxAvatarSize.standard,
  }) {
    final IuxAccessibility accessibility = IuxAccessibility.of(context);
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme typography = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);

    final double base = switch (size) {
      IuxAvatarSize.standard => _standardAvatar,
      IuxAvatarSize.large => _largeAvatar,
    };

    // The circle grows with the user's text setting because what is inside it
    // is text. An avatar pinned to 40 pixels while the name beside it doubled
    // stops looking like it belongs to that name, and its initials become
    // unreadable at exactly the setting chosen to make them readable.
    final double diameter = accessibility.scaleText(base);

    return IuxAvatarTokens(
      diameter: diameter,
      background: colors.surface.subtle,
      foreground: colors.content.primary,
      // The one border role exempt from the 3:1 floor, and its documentation
      // forbids using it to delimit an interactive control — which is exactly
      // right here, because an avatar is never one.
      border: colors.border.subtle,
      borderWidth: geometry.borderWidth,
      fallbackGlyph: Icons.person_outline,
      glyphSize: diameter / 2,
      initialsStyle: switch (size) {
        IuxAvatarSize.standard => typography.label,
        IuxAvatarSize.large => typography.title,
      }
          .copyWith(color: colors.content.primary),
      padding: EdgeInsets.all(geometry.spacingXxs),
    );
  }
}

/// Everything needed to paint a picture's frame, and what stands in for the
/// picture when it is not there.
@immutable
final class IuxImageTokens {
  /// Creates a resolved appearance.
  const IuxImageTokens({
    required this.background,
    required this.border,
    required this.borderWidth,
    required this.radius,
    required this.unavailableGlyph,
    required this.glyphColor,
    required this.glyphSize,
    required this.textStyle,
    required this.padding,
    required this.gap,
  });

  /// The frame's fill, used while the picture loads and when it fails.
  ///
  /// A recessed surface rather than nothing at all. A frame that is invisible
  /// until its picture arrives lets the whole page move when it does.
  final Color background;

  /// The outline drawn around a picture that could not be shown.
  ///
  /// Held to 3:1 by the theme, because it is one of the signals that says the
  /// picture is missing rather than merely pale.
  final Color border;

  /// The outline width.
  final double borderWidth;

  /// The frame's corner radius.
  final double radius;

  /// The glyph drawn where a picture could not be shown.
  ///
  /// A non-colour signal, and the one that survives a monochrome screen: the
  /// failure is a distinct shape, not a grey rectangle a user has to interpret.
  final IconData unavailableGlyph;

  /// The glyph colour.
  final Color glyphColor;

  /// The glyph edge length, already scaled for the user's text size.
  final double glyphSize;

  /// The style of the description when it is rendered in the picture's place.
  final TextStyle textStyle;

  /// Padding inside the frame, around the failure content.
  final EdgeInsets padding;

  /// Space between the glyph and the description.
  final double gap;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxImageTokens &&
          other.background == background &&
          other.border == border &&
          other.borderWidth == borderWidth &&
          other.radius == radius &&
          other.unavailableGlyph == unavailableGlyph &&
          other.glyphColor == glyphColor &&
          other.glyphSize == glyphSize &&
          other.textStyle == textStyle &&
          other.padding == padding &&
          other.gap == gap;

  @override
  int get hashCode => Object.hashAll(<Object>[
        background,
        border,
        borderWidth,
        radius,
        unavailableGlyph,
        glyphColor,
        glyphSize,
        textStyle,
        padding,
        gap,
      ]);
}

/// Resolves the appearance of a picture's frame.
abstract final class IuxImageResolver {
  /// Resolves the tokens in force at [context].
  static IuxImageTokens resolve(BuildContext context) {
    final IuxAccessibility accessibility = IuxAccessibility.of(context);
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme typography = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);

    return IuxImageTokens(
      background: colors.surface.subtle,
      border: colors.border.standard,
      borderWidth: geometry.borderWidth,
      radius: geometry.radiusMedium,
      unavailableGlyph: Icons.broken_image_outlined,
      glyphColor: colors.content.secondary,
      glyphSize: accessibility.scaleText(_standardGlyph),
      // The body role, not a caption role. When this string is drawn it is no
      // longer an annotation beside a picture — it *is* the content, and it has
      // to be as readable as the sentence it replaced.
      textStyle: typography.body.copyWith(color: colors.content.primary),
      padding: IuxInsets.section(context),
      gap: geometry.spacingXs,
    );
  }
}
