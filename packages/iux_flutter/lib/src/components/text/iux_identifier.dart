import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../semantics/iux_semantic_colors.dart';
import '../../themes/extensions/iux_typography_theme.dart';

/// A string read one character at a time, drawn so its characters cannot be
/// confused and announced so a screen reader spells it out.
///
/// ```dart
/// IuxIdentifier(value: commit.shortHash)
/// ```
///
/// **Use it** for a commit hash, a version, a token, a recovery code, an order
/// or booking reference — anything a user compares, copies or reads aloud
/// character by character. It is drawn in [IuxTypographyTheme.identifier], a
/// monospace face with a slashed zero and no ligatures, in the primary content
/// colour.
///
/// **Do not use it** for numbers in prose or in a column: every IUX role
/// already draws digits at one width, and a count or a time is read as a
/// number, not spelled out. Do not use it for a word that happens to be
/// short — a product name is read as a word.
///
/// **Accessibility.** A screen reader meeting `a1b2c3` guesses: it may read it
/// as a word, as a number with letters, or not at all. This widget marks the
/// whole string to be spelled out, character by character, which is how
/// someone reading a recovery code aloud needs to hear it. That is announced
/// behaviour the visible style cannot give, and the reason this is a widget
/// and not only a role.
///
/// The string is the whole accessible name. Where the screen does not already
/// say what the identifier is — a row titled "Commit" beside it — put that in
/// the surrounding text, not here: a spelled-out "c o m m i t" is not what
/// anyone wants to hear.
///
/// A long identifier is spelled out in full. For a forty-character hash that is
/// a long announcement, so show the short form the user actually compares.
///
/// It wraps at any character when the line is too narrow, because an
/// identifier has no word boundaries and truncating one hides the characters
/// that tell two of them apart.
class IuxIdentifier extends StatelessWidget {
  /// Creates an identifier.
  const IuxIdentifier({super.key, required this.value})
      : assert(
          value.length > 0,
          'An identifier must have characters. An empty one is announced as '
          'nothing and drawn as nothing, which a user cannot tell from a '
          'value that failed to load.',
        );

  /// The characters, exactly as the user must read or type them.
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = IuxTypographyTheme.of(context)
        .identifier
        .copyWith(color: IuxSemanticColors.of(context).content.primary);

    return Semantics(
      container: true,
      attributedLabel: AttributedString(
        value,
        attributes: <StringAttribute>[
          SpellOutStringAttribute(
            range: TextRange(start: 0, end: value.length),
          ),
        ],
      ),
      // The Text below would announce the same string without the attribute,
      // and a screen reader meeting both would read it twice — once guessed,
      // once spelled.
      excludeSemantics: true,
      child: Text(value, style: style, softWrap: true),
    );
  }
}
