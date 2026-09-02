import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// The three shapes that carry a direction without using its colour.
///
/// **Why a mark exists here at all**, when the reading beside it usually
/// carries a sign. Because *usually* is not a guarantee the framework can make.
/// `IuxValue.above('2.1 °C', …)` compiles, `IuxValue.above('١٫٢ °م', …)`
/// compiles, and a caller who formats without a sign — or in a locale that
/// writes one the reader does not know — leaves the pill separated from its
/// opposite by hue alone. That is the failure `IuxStatusIndicator` was built to
/// make unreachable, and an argument that the caller will probably avoid it is
/// the kind of argument this repository has already had to retract once.
///
/// The framework cannot compose the sign itself:
/// `test/accessibility/no_composed_strings_test.dart` forbids it from putting
/// characters into a string the user reads, and a `+` prepended by the library
/// would be the wrong glyph in some locales and the wrong position in others.
/// A mark it draws itself is the one signal it can guarantee.
///
/// ## The three silhouettes
///
/// | direction | shape | why this one |
/// | --- | --- | --- |
/// | [above] | arrow, pointing up | the direction itself, not a symbol for it |
/// | [at] | a horizontal rule | no direction, drawn as no direction |
/// | [below] | arrow, pointing down | the mirror of [above] |
///
/// Vertical arrows rather than horizontal ones, deliberately: a left or right
/// arrow means the opposite thing in a right-to-left interface, and Flutter
/// mirrors some of them and not others. Up and down mean up and down in every
/// script.
///
/// The rule for [at] is not an absence. A pill with no mark at all would be a
/// pill whose direction is carried by its colour alone, which is the state
/// these three exist to make unreachable — and it would read as a component
/// that had failed to load its glyph.
///
/// ## What no test here can check
///
/// That these read as three shapes to a person. Icons render in `flutter_test`
/// through a substitute font in which every glyph is the same square, so the
/// suite can assert the three are *different code points* and nothing more —
/// the same limit `IuxCategoryGlyphs` records, and for the same reason.
/// Confirming the silhouettes is a device check.
@internal
abstract final class IuxDirectionGlyphs {
  /// A reading on the upper side of its reference.
  static const IconData above = Icons.arrow_upward;

  /// A reading level with its reference.
  static const IconData at = Icons.horizontal_rule;

  /// A reading on the lower side of its reference.
  static const IconData below = Icons.arrow_downward;

  /// The three, ordered from the upper side to the lower.
  ///
  /// Exposed so a test can assert distinctness over the set rather than over
  /// whichever component happens to be looking at it.
  static const List<IconData> all = <IconData>[above, at, below];
}
