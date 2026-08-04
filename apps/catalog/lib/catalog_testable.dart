import 'package:flutter/material.dart';
import 'package:iux_flutter/iux_flutter.dart';

/// A frame around a sample that actually responds.
///
/// The catalog shows live controls and deliberately inert specimens side by
/// side, on purpose: a disabled field, a read-only field, an unavailable radio
/// option, a refused variant. That is the point of a stress harness — you have
/// to be able to see what a refusal looks like.
///
/// The cost was reported by the first person to use it on a phone: *the radio
/// buttons and switches do not work*. They did. Some of the ones being pressed
/// were the inert specimens, and nothing on screen said which was which.
///
/// So this frame says it. It goes around the samples a reader is meant to
/// press, and the ones without it are either commentary or a refusal being
/// demonstrated.
///
/// It is deliberately not the reverse — a "does not respond" badge on the
/// inert ones. There are far more of those, several are inert for reasons that
/// take a sentence to state, and a screen covered in warning badges reads as a
/// broken application rather than a catalogue of decisions.
class CatalogTestable extends StatelessWidget {
  /// Frames [child] as a sample the reader may interact with.
  ///
  /// [what] names what will happen, in the caller's words — "changes the
  /// selection", "opens a dialog". It is required: a frame that says "Test it"
  /// and nothing else tells the reader to press something without telling them
  /// what to look for, which is most of the way back to the problem this
  /// solves.
  const CatalogTestable({
    super.key,
    required this.what,
    required this.child,
  }) : assert(
          what.length > 0,
          'Say what pressing this does. "Test it" alone leaves the reader '
          'pressing a control and guessing whether the absence of a change '
          'was the answer.',
        );

  /// What interacting with [child] does, already localised.
  final String what;

  /// The live sample.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final IuxSemanticColors colors = IuxSemanticColors.of(context);
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme type = IuxTypographyTheme.of(context);

    return Container(
      margin: EdgeInsets.only(bottom: geometry.spacingSm),
      padding: EdgeInsets.all(geometry.spacingSm),
      decoration: BoxDecoration(
        // The page surface rather than the panel's, so a live sample sits in
        // a well rather than on a card. The border carries the distinction;
        // a second raised surface inside a raised panel reads as depth for
        // its own sake.
        color: colors.surface.base,
        border: Border.all(
          color: colors.border.standard,
          width: geometry.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // One node for the heading and the sentence, so a screen reader
          // hears "Test it. Changes the selection." as one stop rather than
          // two, and neither half arrives without the other.
          Semantics(
            header: true,
            label: 'Test it. $what',
            excludeSemantics: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const IuxIcon(
                  icon: Icons.touch_app_outlined,
                  description: const IuxImageDescription.decorative(),
                  size: IuxIconSize.small,
                ),
                SizedBox(width: geometry.spacingXxs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Test it',
                        style:
                            type.label.copyWith(color: colors.content.primary),
                      ),
                      Text(
                        what,
                        style: type.supporting
                            .copyWith(color: colors.content.secondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: geometry.spacingXs),
          child,
        ],
      ),
    );
  }
}
