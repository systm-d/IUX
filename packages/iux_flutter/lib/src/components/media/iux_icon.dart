import 'package:flutter/material.dart';

import '../../accessibility/iux_semantics.dart';
import 'iux_media_model.dart';
import 'iux_media_tokens.dart';

/// A glyph, and a statement of whether it says anything.
///
/// ```dart
/// // Beside a label that already says "Delete": the glyph repeats it.
/// IuxIcon(
///   icon: Icons.delete_outline,
///   description: const IuxImageDescription.decorative(),
/// )
///
/// // Alone in a row: the glyph is the only thing that says what this is.
/// IuxIcon(
///   icon: Icons.lock_outline,
///   description: IuxImageDescription.meaningful(l10n.privateAlbum),
/// )
/// ```
///
/// **Use it** for a glyph that stands on its own in a layout — in a list row,
/// beside a heading, inside a legend.
///
/// **Do not use it as a control.** It takes no focus, has no touch target and
/// reports no gesture. An icon the user can act on is `IuxIconButton`, which
/// carries a name, a role, a focus ring and a target that meets the floor. A
/// glyph with a tap handler bolted on is a control a screen-reader user cannot
/// find and a motor-impaired user cannot hit.
///
/// **Do not use it inside a component that already draws its own glyph.**
/// `IuxButton`, `IuxStatusIndicator` and the chips size and colour their glyphs
/// from their own tokens, so passing an icon widget into them would produce two
/// answers to the same question.
///
/// **Do not use it for a glyph the user has to guess.** A glyph whose meaning
/// is not conventional is a puzzle with a description attached, and only one of
/// the two audiences gets the answer. Put a word next to it and mark the glyph
/// decorative.
///
/// ## The description is required, and there is no default
///
/// [description] is the whole reason this widget exists rather than
/// `Icon(Icons.lock)`. Flutter's `Icon` has an optional `semanticLabel` that
/// defaults to null, so the ordinary way to write an icon is also the way to
/// produce an unnamed one — and the two failures that follow are opposites:
///
/// - A meaningful glyph left unnamed is silence. A padlock beside a filename
///   is the only thing saying the file is private; a screen-reader user is
///   told there is a file and not that it is locked.
/// - A decorative glyph given a name is noise. Every row of a list announcing
///   "image, chevron" before its content is a list nobody finishes.
///
/// [IuxImageDescription] makes the question unavoidable and answers both
/// cases correctly: a meaningful glyph becomes a named image node, a decorative
/// one is removed from the semantic tree outright rather than described.
///
/// ## Size and colour
///
/// Both come from the theme. The glyph is scaled by the user's text setting
/// once, through the same runtime every other IUX component reads, so a glyph
/// and the words beside it grow together — and a glyph that is the only content
/// in its slot grows at all, which is the case a fixed pixel size gets wrong.
class IuxIcon extends StatelessWidget {
  /// Creates a glyph.
  const IuxIcon({
    super.key,
    required this.icon,
    required this.description,
    this.size = IuxIconSize.standard,
    this.emphasis = IuxIconEmphasis.primary,
  });

  /// The glyph to draw.
  ///
  /// An [IconData] rather than a `Widget`, so this widget sizes and colours it
  /// from the theme. A caller that passed a widget could pass one carrying its
  /// own colour, and the contrast guarantee would leave with it.
  final IconData icon;

  /// Whether this glyph says anything, and what.
  ///
  /// Required, with no default. See [IuxImageDescription].
  final IuxImageDescription description;

  /// How large to draw the glyph, relative to text.
  final IuxIconSize size;

  /// How much visual weight the glyph carries.
  final IuxIconEmphasis emphasis;

  @override
  Widget build(BuildContext context) {
    final IuxIconTokens tokens = IuxIconResolver.resolve(
      context,
      size: size,
      emphasis: emphasis,
    );

    // Both branches go through one call: IuxSemantics.image treats an empty
    // label as "hide this", which is exactly what a decorative glyph needs and
    // the reason the description type has no third state.
    return IuxSemantics.image(
      label: description.description,
      child: Icon(
        icon,
        size: tokens.size,
        color: tokens.color,
        // Scaled once, in the resolver. Letting Flutter scale it again would
        // enlarge the glyph twice as fast as the text it sits beside.
        applyTextScaling: false,
      ),
    );
  }
}
