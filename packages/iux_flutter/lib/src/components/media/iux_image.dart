import 'package:flutter/material.dart';

import '../../accessibility/iux_semantics.dart';
import 'iux_media_model.dart';
import 'iux_media_tokens.dart';

/// A picture, a statement of whether it says anything, and what happens when it
/// does not arrive.
///
/// ```dart
/// IuxImage(
///   image: NetworkImage(product.photoUrl),
///   description: IuxImageDescription.meaningful(product.photoCaption),
///   aspectRatio: 4 / 3,
/// )
/// ```
///
/// **Use it** for a picture that is content — a product photograph, a chart, a
/// map, a screenshot, a scanned document.
///
/// **Do not use it for a person.** That is `IuxAvatar`, which is circular,
/// falls back to initials and has no failure state because it needs none.
///
/// **Do not use it as a control.** There is no `onTap`. A tappable picture is a
/// control with no name, no role, no focus ring and no target floor; put an
/// `IuxButton` beside it, or make the surrounding block one `IuxCard.tappable`,
/// which announces itself once and says what activating it does.
///
/// **Do not use it for a glyph.** That is `IuxIcon`, which takes its size and
/// colour from the theme so it matches the text beside it.
///
/// ## The three things a picture can be doing, and what each one says
///
/// | | The eye sees | A screen reader hears |
/// | --- | --- | --- |
/// | loading | the reserved frame, filled | the description |
/// | loaded | the picture | the description, as an image |
/// | failed, meaningful | a frame, a broken-picture glyph, the description as text | the description, as text |
/// | failed, decorative | the reserved frame, filled | nothing |
///
/// **A failed meaningful picture renders its own description in its place.**
/// This is what a browser does with `alt` text and it is the behaviour WCAG
/// SC 1.1.1 is written around: the information the picture carried survives the
/// picture. It also means IUX invents no user-facing text — there is no
/// "Image unavailable" string to translate, because the words that appear are
/// the words the caller already wrote.
///
/// It is also why [IuxImageDescription.meaningful] asks for a description that
/// stands on its own. "Product photo" is a poor alternative and an absurd
/// paragraph; "Blue running shoe, side view" is both.
///
/// **A failed decorative picture says nothing at all**, visually or otherwise.
/// Its frame stays filled so the layout does not collapse, and it stays hidden
/// from assistive technology. Nothing was lost, so there is nothing to report,
/// and a broken-picture glyph would be an error message about a non-event.
///
/// ## The frame is reserved before the picture exists
///
/// [aspectRatio] is required. A picture whose size is unknown until it decodes
/// is a picture that pushes everything below it down the moment it arrives —
/// under a finger already travelling toward a button, on the slow connections
/// where the delay is longest. Reserving the box costs one number at the call
/// site and removes the whole class of failure.
///
/// The reserved height is a *floor*, not a cage: a failed meaningful picture
/// grows taller when its description needs the room, because clipping the text
/// that replaced the picture would lose the information twice.
///
/// That growth needs somewhere to go. A picture inside scrollable content —
/// which is where a picture normally lives — has it. A picture pinned inside a
/// fixed-height box does not, and a long description at a large text size will
/// then overflow visibly. That is deliberate: a visible overflow in debug is a
/// bug report, where a silent clip is the information disappearing for the
/// users least able to notice.
///
/// ## IUX fetches nothing
///
/// [image] is an `ImageProvider` the parent supplies and owns. There is no
/// cache here, no retry, no timeout and no placeholder URL. An application's
/// caching and offline strategy is an application decision, and a component
/// that made it would make it wrongly for everyone who needed a different one.
class IuxImage extends StatelessWidget {
  /// Creates a picture.
  const IuxImage({
    super.key,
    required this.image,
    required this.description,
    required this.aspectRatio,
    this.fit = IuxImageFit.cover,
  }) : assert(
          aspectRatio > 0 && aspectRatio < double.infinity,
          'The aspect ratio must be a positive, finite number — width divided '
          'by height, so 16 / 9 for a landscape frame. It is required because '
          'the frame has to be reserved before the picture decodes: a frame '
          'that grows on arrival moves everything below it, which on a slow '
          'connection happens exactly while the user is reaching for it.',
        );

  /// The picture, supplied and owned by the parent.
  final ImageProvider image;

  /// Whether this picture says anything, and what.
  ///
  /// Required, with no default. See [IuxImageDescription] — this is the
  /// decision the component cannot make for the caller.
  final IuxImageDescription description;

  /// The frame's width divided by its height.
  ///
  /// Reserved before the picture loads. See the class documentation.
  final double aspectRatio;

  /// What to do when the picture and the frame have different proportions.
  final IuxImageFit fit;

  @override
  Widget build(BuildContext context) {
    final IuxImageTokens tokens = IuxImageResolver.resolve(context);

    return Image(
      image: image,
      fit: switch (fit) {
        IuxImageFit.cover => BoxFit.cover,
        IuxImageFit.contain => BoxFit.contain,
      },
      // The semantics are supplied by the branches below, because they are not
      // the same in every state: a picture that failed is no longer an image
      // node, and Flutter's own label would keep calling it one.
      excludeFromSemantics: true,
      // The decoded picture stays while a new provider resolves, so swapping
      // the source does not blink an empty frame at the user.
      gaplessPlayback: true,
      frameBuilder: _buildFrame(tokens),
      errorBuilder: (
        BuildContext context,
        Object error,
        StackTrace? stackTrace,
      ) =>
          _IuxImageUnavailable(
        description: description,
        aspectRatio: aspectRatio,
        tokens: tokens,
      ),
    );
  }

  /// The loading and loaded states, which differ visually and not semantically.
  ///
  /// Announcing the description while the picture is still arriving is
  /// deliberate. It is what a browser does with `alt`, and the alternative —
  /// announcing "loading" — either interrupts the user for something that
  /// resolves in a second, or leaves the node nameless until it does. The
  /// description is true about the frame in both states: it says what is
  /// there, or what is about to be.
  ImageFrameBuilder _buildFrame(IuxImageTokens tokens) => (
        BuildContext context,
        Widget child,
        int? frame,
        bool wasSynchronouslyLoaded,
      ) {
        final bool ready = wasSynchronouslyLoaded || frame != null;
        return IuxSemantics.image(
          label: description.description,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(tokens.radius),
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: DecoratedBox(
                decoration: BoxDecoration(color: tokens.background),
                // A filled frame rather than a spinner. One indicator per
                // picture turns a scrolling list into a field of moving parts,
                // and a reduced-motion profile removes them all, leaving
                // nothing at all in their place. The filled frame is the
                // signal, it needs no motion, and it is already the shape the
                // picture will take.
                child: ready ? child : const SizedBox.expand(),
              ),
            ),
          ),
        );
      };
}

/// What stands in for a picture that could not be shown.
///
/// Private: the two outcomes below are decided by [IuxImageDescription], and
/// exposing this separately would let a caller render a failure state for a
/// picture that is fine.
class _IuxImageUnavailable extends StatelessWidget {
  const _IuxImageUnavailable({
    required this.description,
    required this.aspectRatio,
    required this.tokens,
  });

  final IuxImageDescription description;
  final double aspectRatio;
  final IuxImageTokens tokens;

  @override
  Widget build(BuildContext context) {
    if (description.isDecorative) {
      // Nothing was lost, so nothing is reported. The frame keeps its space so
      // the page does not reflow around an absence, and it stays out of the
      // semantic tree so no one is told about a picture that was never worth
      // mentioning when it worked.
      return IuxSemantics.decorative(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(tokens.radius),
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: DecoratedBox(
              decoration: BoxDecoration(color: tokens.background),
            ),
          ),
        ),
      );
    }

    // Measured rather than assumed, so the reserved height can be a floor. A
    // fixed AspectRatio would clip the description at a large text size, which
    // would lose the information the picture already lost.
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) =>
          ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: constraints.maxWidth.isFinite
              ? constraints.maxWidth / aspectRatio
              : 0,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tokens.background,
            borderRadius: BorderRadius.circular(tokens.radius),
            // An outline the theme holds to 3:1, so the frame reads as a
            // deliberate placeholder and not as a pale gap in the page.
            border: Border.all(
              color: tokens.border,
              width: tokens.borderWidth,
            ),
          ),
          child: Padding(
            padding: tokens.padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // The shape that says "missing" without using colour, and the
                // signal that survives a monochrome screen. Excluded from the
                // semantic tree: the description below already carries the
                // content, and a glyph announced beside it would be a second
                // utterance saying nothing new.
                IuxSemantics.decorative(
                  child: Icon(
                    tokens.unavailableGlyph,
                    size: tokens.glyphSize,
                    color: tokens.glyphColor,
                    applyTextScaling: false,
                  ),
                ),
                SizedBox(height: tokens.gap),
                // Announced as ordinary text, not as an image. There is no
                // image any more, and a screen reader that still called it one
                // would be describing something the user cannot reach.
                //
                // No line limit and no ellipsis, at any text scale. This string
                // is now the content; truncating it would lose exactly what the
                // failure was supposed to preserve.
                Text(
                  description.description,
                  style: tokens.textStyle,
                  textAlign: TextAlign.center,
                  softWrap: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
