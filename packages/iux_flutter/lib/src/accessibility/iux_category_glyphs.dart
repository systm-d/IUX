import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// The four shapes that carry a feedback category without using its colour.
///
/// **One definition, because two components draw the same four categories.**
/// `IuxInlineFeedback` and `IuxStatusIndicator` each resolved their own glyph
/// map, and the maps happened to agree. Nothing held them together, so the
/// first edit to one would have made the same category two different shapes
/// depending on which component a user met it in.
///
/// ## Why the shapes matter more than the doc comment used to claim
///
/// `IUX-PALETTE-PERCEPTION-001` measured the four `feedback.content` colours
/// under simulated dichromacy. Under deuteranopia — the most common one —
/// [success] and [error] are **0.4 apart** on the Oklab ×100 scale in the dark
/// high contrast profile, where about 2 is the smallest difference most people
/// notice with two colours side by side. They are the same colour. Every
/// profile has at least one pair below the threshold.
///
/// So the shape is not a courtesy that reinforces the colour. For that pair, in
/// that profile, **the shape and the words are the whole signal.**
///
/// The map this replaces defended itself with "a user with deuteranopia
/// distinguishes the triangle from the circles". True, and it named the wrong
/// pair: the triangle is [warning], which colour separates comparatively well.
/// Three of the four glyphs were circles, and the pair colour failed hardest on
/// — a circled tick against a circled exclamation mark — differed only in the
/// mark inside a shared outline at roughly twenty logical pixels.
///
/// ## The four silhouettes
///
/// Round for the two categories that report, angular for the two that ask
/// something of the user, and each outline distinct at a glance before any
/// interior mark is resolved:
///
/// | category | shape | why this one |
/// | --- | --- | --- |
/// | [info] | circle, "i" | the neutral report; nothing is asked |
/// | [success] | circle, tick | the other report, and the tick is unambiguous |
/// | [warning] | triangle | the road sign for "take care", not invented here |
/// | [error] | octagon | the road sign for "stop", and the only octagon |
///
/// The two road-sign shapes are the load-bearing pair, and they are borrowed
/// rather than designed: a triangle and an octagon are separable by outline
/// alone, at small size, in a black-and-white screenshot, and are already
/// learned by anyone who has crossed a street.
///
/// ## What no test here can check
///
/// That these read as four shapes to a person. Icons render in `flutter_test`
/// through a substitute font in which every glyph is the same square, so the
/// suite can assert the four are *different code points* and nothing more —
/// and this library has already shipped with no icons at all for weeks while
/// every test passed. Confirming the silhouettes is a device check, in
/// `docs/accessibility/manual-validation-protocol.md`, under `IUX-MANUAL-001`.
@internal
abstract final class IuxCategoryGlyphs {
  /// Neutral information. A circled "i".
  static const IconData info = Icons.info_outline;

  /// A completed operation. A circled tick.
  static const IconData success = Icons.check_circle_outline;

  /// A consequence to consider. A triangle.
  static const IconData warning = Icons.warning_amber_outlined;

  /// A failure that blocks progress. An octagon holding an "!".
  ///
  /// `Icons.error_outline` — a circled "!" — is the obvious choice and was the
  /// one in place. It is a circle, which put it in a family of three, opposite
  /// the category it is least affordable to confuse it with. This one is the
  /// only octagon in the set.
  static const IconData error = Icons.report_outlined;

  /// The four, in the order the categories escalate.
  ///
  /// Exposed so a test can assert distinctness over the set rather than over
  /// whichever component it happens to be looking at.
  static const List<IconData> all = <IconData>[info, success, warning, error];
}
