import 'package:flutter/material.dart';

import '../../accessibility/iux_semantics.dart';
import 'iux_media_model.dart';
import 'iux_media_tokens.dart';

/// The picture that stands for a person or an organisation, and their name.
///
/// ```dart
/// // The avatar is the only thing identifying the person here.
/// IuxAvatar(
///   name: person.displayName,
///   initials: person.initials,
///   image: photo,
/// )
///
/// // The row already shows the name in text beside it.
/// IuxAvatar.decorative(initials: person.initials, image: photo)
/// ```
///
/// **Use it** wherever a person or an organisation appears as an object the
/// user recognises — a list of participants, a comment, an account header.
///
/// **Do not use it as a control.** There is no `onTap`, and there will not be
/// one. An avatar is almost always inside something that is already tappable —
/// a row, a card, a mention — and `IuxCard.tappable` refuses to contain a
/// control precisely because a screen reader would then announce a button
/// inside a button and neither a sighted nor a screen-reader user could tell
/// which one a tap would reach. When the picture itself must be actionable
/// ("change your photo"), put an `IuxIconButton` or an `IuxButton` beside it
/// with its own name and its own target; the action then has words, which a
/// tappable circle never does.
///
/// **Do not use it for a picture that is not a person or an organisation.** A
/// product, a chart, a map, a screenshot is `IuxImage`, which reserves its box,
/// reports failure and renders its description in the picture's place.
///
/// ## The initials are not the name
///
/// [name] is what a screen reader announces. [initials] is what the eye sees
/// when there is no photograph. They are separate parameters because they are
/// separate things, and the mistake this separation prevents is common enough
/// to be the reason the widget exists: "JD" announced to a screen reader is two
/// letters with no referent. The user hears a spelling, not a person.
///
/// **IUX never derives [initials] from [name].** Taking the first letter of
/// each word is a rule that holds for `John Doe` and fails for `李明`, for
/// `van der Berg`, for a mononym, for every script written without spaces, and
/// for `Dr. Maria de la Cruz-Fernández`. A framework that guessed would
/// generate a wrong abbreviation of a real person's name in the languages it
/// was not tested in. Pass the initials your application knows how to build, or
/// pass none: an avatar with no initials falls back to a neutral glyph, which
/// claims nothing rather than claiming something wrong.
///
/// [initials] is never announced, at any size, in either constructor.
///
/// ## Decorative or named, and the caller decides
///
/// The default constructor requires [name] and announces it.
/// [IuxAvatar.decorative] announces nothing and is hidden from assistive
/// technology entirely.
///
/// Pick the second whenever the name is already visible beside the avatar,
/// which is most rows in most lists. Otherwise a screen-reader user hears the
/// name twice — once for the circle and once for the text — and a list of
/// twenty participants becomes forty utterances with no extra information in
/// any of them.
///
/// Pick the first whenever the avatar stands alone: a header, a stack of
/// overlapping participants, a mention with no adjacent label. There the circle
/// is the only thing identifying the person, and hiding it deletes them from
/// the interface of every user who cannot see it.
///
/// ## A photograph that never arrives
///
/// An avatar has no failure state, by construction. [image] is drawn on top of
/// a fallback that is already there — the initials, or the neutral glyph — so
/// the circle is filled before the network is consulted, while it is slow, and
/// after it has failed. What a user sees when a photograph 404s is what they
/// saw a moment earlier: a labelled circle, not a hole.
///
/// A screen reader is told the same thing in all three cases: [name], for the
/// named form, and nothing at all for the decorative one. The photograph
/// carried no information the name did not, so its absence has nothing to
/// report — which is exactly why a spinner and an error glyph would both be
/// wrong here, and why `IuxImage` does report failure where the picture *was*
/// the information.
///
/// IUX loads nothing and caches nothing. [image] is an `ImageProvider` the
/// parent supplies and owns: a component with a network layer inside it is a
/// component that decides retry policy, cache size and offline behaviour for an
/// application it knows nothing about.
class IuxAvatar extends StatelessWidget {
  /// Creates an avatar that carries the name of who it belongs to.
  ///
  /// [name] arrives already localised and must not be empty. It is the
  /// accessible name, not a description of the picture: "Maria Costa", never
  /// "photo of Maria Costa" — a screen reader already says the node is an
  /// image, and repeating it costs the user a word on every row.
  const IuxAvatar({
    super.key,
    required String this.name,
    this.initials,
    this.image,
    this.size = IuxAvatarSize.standard,
  })  : assert(
          name.length > 0,
          'An avatar that is announced needs something to announce. An empty '
          'name leaves an image node with no label, which tells the user a '
          'picture is there and refuses to say whose. Pass the person or '
          "organisation's name, or use IuxAvatar.decorative when the name is "
          'already visible beside the avatar.',
        ),
        assert(
          initials == null || initials.length > 0,
          'An empty initials string draws an empty circle. Pass null instead '
          'and the avatar falls back to a neutral glyph, which reads as "no '
          'photograph" rather than as "something failed to render".',
        );

  /// Creates an avatar beside a name the user can already read.
  ///
  /// Hidden from assistive technology entirely: the adjacent text is the
  /// accessible name, and announcing the circle as well would say it twice.
  ///
  /// This is not the "I have not written a name yet" constructor. Choosing it
  /// for an avatar that stands alone removes the person from the interface of
  /// every user who cannot see the picture.
  const IuxAvatar.decorative({
    super.key,
    this.initials,
    this.image,
    this.size = IuxAvatarSize.standard,
  })  : name = null,
        assert(
          initials == null || initials.length > 0,
          'An empty initials string draws an empty circle. Pass null instead '
          'and the avatar falls back to a neutral glyph.',
        );

  /// Who the avatar belongs to, already localised. Null on the decorative form.
  ///
  /// Announced as the accessible name of the image. Never drawn: the circle
  /// shows a photograph or [initials], and the words live in the row beside it.
  final String? name;

  /// The short visual stand-in drawn when there is no photograph.
  ///
  /// Drawn, never announced, in either constructor. Supplied by the caller
  /// because only the caller knows how a name abbreviates in its own script —
  /// see the class documentation for why IUX will not compute this.
  ///
  /// Null is a valid and safe answer: the avatar then draws a neutral glyph.
  final String? initials;

  /// The photograph, supplied and owned by the parent.
  ///
  /// Any `ImageProvider` — an asset, a file, a network image, a decoded
  /// buffer. IUX neither fetches nor caches it: whatever this resolves to
  /// arrives on top of a fallback that is already drawn, so a slow or failed
  /// load is invisible rather than broken.
  final ImageProvider? image;

  /// How large to draw the circle.
  final IuxAvatarSize size;

  @override
  Widget build(BuildContext context) {
    final IuxAvatarTokens tokens = IuxAvatarResolver.resolve(
      context,
      size: size,
    );

    final Widget visual = SizedBox.square(
      dimension: tokens.diameter,
      child: Container(
        decoration: ShapeDecoration(
          color: tokens.background,
          shape: const CircleBorder(),
        ),
        // A foreground decoration, so the outline is drawn over a photograph
        // rather than under it. Beneath, a pale picture and a pale page meet
        // with nothing between them and the avatar stops being one object.
        foregroundDecoration: ShapeDecoration(
          shape: CircleBorder(
            side: BorderSide(color: tokens.border, width: tokens.borderWidth),
          ),
        ),
        child: ClipOval(child: Center(child: _content(tokens))),
      ),
    );

    // One call for both constructors: IuxSemantics.image treats an empty label
    // as "hide this". The decorative form passes one, and the named form
    // cannot — the assertion in its constructor sees to that.
    //
    // The helper also excludes descendant semantics, which is the structural
    // half of "the initials are not the name": there is no arrangement of
    // parameters that gets "JD" spoken.
    return IuxSemantics.image(label: name ?? '', child: visual);
  }

  /// The photograph when it is there, and what stands in its place until it is.
  Widget _content(IuxAvatarTokens tokens) {
    final Widget fallback = _fallback(tokens);
    final ImageProvider? provider = image;
    if (provider == null) return fallback;

    return Image(
      image: provider,
      width: tokens.diameter,
      height: tokens.diameter,
      // The circle is fixed and the photograph is not: cropping keeps the
      // avatar round, where fitting would leave bands of background and make
      // one person's portrait a different shape from the next one's.
      fit: BoxFit.cover,
      // The circle already carries the name. A second node inside it would
      // announce the picture again, under a label Flutter took from nowhere.
      excludeFromSemantics: true,
      // The previous photograph stays until the new one decodes, so changing
      // the provider does not blink the row.
      gaplessPlayback: true,
      // Supplied rather than left to Flutter, for two reasons. Flutter's
      // default fades a newly decoded image in over a duration this component
      // is not allowed to hardcode; and until that first frame exists there
      // would be nothing on screen, which is the blank circle this widget is
      // built to avoid.
      frameBuilder: (
        BuildContext context,
        Widget child,
        int? frame,
        bool wasSynchronouslyLoaded,
      ) =>
          wasSynchronouslyLoaded || frame != null ? child : fallback,
      // Offline, 404, a malformed file, a revoked URL: all of them land here,
      // and all of them look like an avatar with no photograph, because that
      // is what they are. Nothing is announced, because nothing was lost.
      errorBuilder: (
        BuildContext context,
        Object error,
        StackTrace? stackTrace,
      ) =>
          fallback,
    );
  }

  /// The initials, or a glyph that claims nothing.
  Widget _fallback(IuxAvatarTokens tokens) {
    final String? letters = initials;
    if (letters == null) {
      return Icon(
        tokens.fallbackGlyph,
        size: tokens.glyphSize,
        color: tokens.foreground,
        // Scaled once, in the resolver, along with the circle around it.
        applyTextScaling: false,
      );
    }

    return Padding(
      padding: tokens.padding,
      child: FittedBox(
        // Only ever shrinks, and only when a caller passes more letters than
        // fit. Three or four characters then stay inside the circle instead of
        // being clipped by it — clipped initials read as a different name.
        fit: BoxFit.scaleDown,
        child: Text(
          letters,
          style: tokens.initialsStyle,
          maxLines: 1,
          softWrap: false,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
