import 'package:flutter/foundation.dart';

/// Whether a picture carries information, and — when it does — what it says.
///
/// ```dart
/// IuxImage(
///   image: provider,
///   description: IuxImageDescription.meaningful(l10n.salesRoseInQ3),
///   aspectRatio: 16 / 9,
/// )
///
/// IuxImage(
///   image: provider,
///   description: const IuxImageDescription.decorative(),
///   aspectRatio: 16 / 9,
/// )
/// ```
///
/// **This is the decision the rest of the media components are built around,
/// and it is the one an API must not make on the caller's behalf.** A picture
/// either carries information a user would lose without it, or it does not.
/// Only the person placing it on the screen knows which, and the two outcomes
/// are opposites:
///
/// | | Screen reader | Consequence of getting it wrong |
/// | --- | --- | --- |
/// | meaningful | reads the description | silence where the only content was |
/// | decorative | skips the node entirely | "IMG_2049.jpg", or a filename read aloud |
///
/// There is no default and there is no nullable label, because both of those
/// are ways of choosing without noticing. A `String?` where null quietly means
/// decoration turns "I have not written the description yet" into "this image
/// says nothing" — the two most common states of a codebase, rendered
/// identically. Passing this object is one extra token at the call site and it
/// is the only place the question is asked.
///
/// A value class rather than two widget constructors, because the answer
/// usually arrives with the data. A record from a CMS carries a URL and an
/// alternative text; a product carries a photo and a caption. Keeping the
/// picture's meaning next to the picture is what stops a screen from
/// describing the wrong one after a list is reordered.
///
/// The description arrives already localised. IUX composes no user-facing
/// text: it cannot know how to say "photo of" in the reader's language, and a
/// framework that guessed would ship one language into every locale.
@immutable
final class IuxImageDescription {
  const IuxImageDescription._({
    required this.description,
    required this.isDecorative,
  }) : assert(
          isDecorative || description.length > 0,
          'A meaningful image was given an empty description. An empty string '
          'is not "no description needed" — that is '
          'IuxImageDescription.decorative(), which hides the image from a '
          'screen reader outright. As written, the image is announced as an '
          'image with no name, so the user is told something is there and '
          'refused any way to know what. Either write the sentence or declare '
          'the image decorative.',
        );

  /// A picture that carries information, and the words that carry the same
  /// information without it.
  ///
  /// [description] must not be empty, and must say what the picture *tells*
  /// the user rather than what it is made of. "Chart" describes a rectangle;
  /// "Sales rose 20% in the third quarter" describes the content the picture
  /// was placed there to deliver.
  ///
  /// Write it so it stands on its own. When the picture cannot be loaded it is
  /// rendered in the picture's place, so it has to work as text as well as it
  /// works as an alternative.
  const IuxImageDescription.meaningful(String description)
      : this._(description: description, isDecorative: false);

  /// A picture that carries no information the user would otherwise lose.
  ///
  /// A texture behind a heading, a divider flourish, a glyph beside a label
  /// that already says the same word. It is hidden from assistive technology
  /// entirely rather than described, because a description of decoration is
  /// noise a screen-reader user has to step through on every visit.
  ///
  /// **The test is not whether the picture is pretty.** It is whether a user
  /// who never sees it has lost anything. An avatar beside a visible name is
  /// decorative; the same avatar alone in a header is not.
  const IuxImageDescription.decorative()
      : this._(description: '', isDecorative: true);

  /// What the picture says, already localised. Empty when decorative.
  ///
  /// Both the accessible name and, when the picture cannot be shown, the text
  /// rendered in its place. They are deliberately the same string: an image
  /// whose spoken form differs from its written fallback gives two users two
  /// different facts about the same screen.
  final String description;

  /// Whether the picture is to be hidden from assistive technology.
  ///
  /// Recorded rather than inferred from an empty [description]. Inferring it
  /// would make a forgotten description indistinguishable from a deliberate
  /// one in release builds, where the assertion no longer runs.
  final bool isDecorative;

  /// Whether the picture carries information that must reach every user.
  bool get isMeaningful => !isDecorative;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxImageDescription &&
          other.description == description &&
          other.isDecorative == isDecorative;

  @override
  int get hashCode => Object.hash(description, isDecorative);

  @override
  String toString() => isDecorative
      ? 'IuxImageDescription.decorative()'
      : 'IuxImageDescription.meaningful("$description")';
}

/// How large a glyph should be drawn, expressed as its relationship to text.
///
/// Two values rather than a number: an icon whose size is set at the call site
/// is an icon that stops matching the text beside it the moment either one
/// changes. Both are scaled by the user's text setting, so a glyph never stays
/// put while the words around it grow.
enum IuxIconSize {
  /// A glyph that sits inside a line of text, beside a label.
  ///
  /// The size the status indicator and the chip already use, so a glyph does
  /// not change size when it moves between them.
  small,

  /// A glyph standing on its own, in a row or a header.
  ///
  /// The default, and the size Android guidance assumes for a list-row glyph.
  standard,
}

/// How much visual weight a glyph carries, expressed as a role.
///
/// Never a colour. A call site that could pass a colour could pass one that
/// fails contrast, and the theme would no longer be answerable for the result.
enum IuxIconEmphasis {
  /// Essential content, at the same weight as body text.
  ///
  /// The default. Use it whenever the glyph is part of what the user came to
  /// read, and always when it is the only thing in its slot.
  primary,

  /// Supporting content that qualifies something else.
  ///
  /// A chevron, a separator glyph, an affordance hint. Never use it for a
  /// glyph that is the sole carrier of a piece of information.
  secondary,
}

/// How large an avatar is drawn.
///
/// Both values scale with the user's text setting, for the same reason the
/// glyph sizes do: an avatar that stayed 40 pixels while its name doubled
/// stops reading as belonging to that name.
enum IuxAvatarSize {
  /// The size for a list row or an inline mention. The default.
  standard,

  /// The size for a profile header, where the person is the subject of the
  /// screen rather than one entry in a list.
  large,
}

/// Which of the four decorative accents tints an avatar's circle.
///
/// **The members carry no meaning, and are named so that none can be read
/// into them.** [one] does not outrank [four]; there is no order here the
/// way there is an order in `IuxValueDirection`. An application maps each
/// member to whatever it needs distinguished — a season, a workspace, a
/// label a user picked — and that mapping belongs to the application, the
/// same way the choice of [IuxAvatar.icon] does.
///
/// **This is not a fifth `IuxStatusTone` and not a fourth
/// `IuxValueDirection`.** Neither vocabulary answers "which of several
/// unrelated things is this" — one answers "is this good or bad news," the
/// other "which side of a reference" — and forcing this question through
/// either would ship a claim about the thing tinted that IUX has no way to
/// know is true. See
/// `docs/decisions/ADR-0014-a-container-is-not-a-verdict.md`.
///
/// Four, because IUX ships exactly four non-neutral hue families and
/// inventing a fifth is palette work — new primitives, measured across four
/// theme profiles under three simulated colour-vision deficiencies — which
/// is out of reach for a single component.
///
/// **Two of the four collide under colour-vision deficiency in some
/// profiles**, inherited from the same hues `IuxStatusTone` and
/// `IuxCategoryGlyphs` already carry that collision for —
/// `IUX-PALETTE-PERCEPTION-001`. [IuxAvatar.icon] is what survives where hue
/// does not; pass a distinct one with every tone, never the tone alone.
enum IuxAvatarTone {
  /// The first accent.
  one,

  /// The second accent.
  two,

  /// The third accent.
  three,

  /// The fourth accent.
  four,
}

/// What to do when a picture and its frame have different proportions.
///
/// An intent rather than a `BoxFit`, because only two of Flutter's eight
/// answers are ever right here and the difference between them is a
/// comprehension question, not a styling one.
enum IuxImageFit {
  /// Fill the frame, cropping whatever does not fit.
  ///
  /// The default, and correct for a photograph: the frame stays the shape the
  /// layout reserved and no empty bands appear beside the picture.
  ///
  /// Never use it for a picture whose edges carry meaning. A cropped chart is
  /// a chart with data missing, and nothing on screen says so.
  cover,

  /// Show the whole picture, leaving the frame partly empty.
  ///
  /// Correct for a diagram, a chart, a screenshot, a logo — anything where
  /// losing the edges loses information.
  contain,
}
