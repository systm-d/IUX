import 'package:flutter/material.dart';

import '../../accessibility/iux_semantics.dart';
import 'iux_status_model.dart';
import 'iux_status_tokens.dart';

/// A state the user needs to know about, said in words.
///
/// ```dart
/// IuxStatusIndicator(status: IuxStatus.error(l10n.paymentDeclined))
/// ```
///
/// **Use it** wherever a row, a record or a connection is in a state that
/// changes what the user can do — an order that failed, a device that is
/// offline, a document awaiting review.
///
/// **Do not use it** for a count: that is `IuxBadge`. Do not use it as a
/// control — it takes no focus, has no touch target and reports no gesture; a
/// status the user can act on is a status beside a button. Do not use it to
/// report the outcome of an operation this widget started, because it starts
/// none: the parent owns the state and re-renders when it changes.
///
/// **Accessibility.** There is no `showLabel` flag and no dot-only form, and
/// there will not be one. A coloured dot with no words is the single most
/// common "colour alone" failure in this category: it says nothing to a screen
/// reader, nothing on a monochrome or sun-washed screen, and nothing to a user
/// who cannot separate the hues. `IuxStatus` cannot be constructed without a
/// label, and this widget always draws it — so the failure is unreachable
/// rather than discouraged.
///
/// Three signals carry the state, and only one of them is colour:
///
/// | Signal | Reaches |
/// | --- | --- |
/// | the label | everyone, including a screen reader |
/// | the glyph shape | a monochrome screen, a colour vision deficiency |
/// | the tone colour | everyone else, as reinforcement |
///
/// The glyph is excluded from the semantic tree because the label already says
/// what it says. A glyph carrying information the label does not is information
/// a screen-reader user never receives.
///
/// **When the state changes while the user is looking elsewhere**, wrap this in
/// `IuxSemantics.liveRegion` at the call site. It is not a live region by
/// default: a list of thirty rows each announcing itself on every refresh is a
/// list nobody can use with TalkBack, and only the caller knows which of its
/// statuses is worth an interruption.
class IuxStatusIndicator extends StatelessWidget {
  /// Creates a status indicator.
  const IuxStatusIndicator({super.key, required this.status});

  /// The state to report, and the words that carry it.
  ///
  /// Required, and it has no empty form. See [IuxStatus].
  final IuxStatus status;

  @override
  Widget build(BuildContext context) {
    final IuxStatusTokens tokens =
        IuxStatusResolver.resolve(context, status.tone);

    final Widget visual = DecoratedBox(
      decoration: ShapeDecoration(
        color: tokens.background,
        shape: StadiumBorder(
          side: BorderSide(color: tokens.border, width: tokens.borderWidth),
        ),
      ),
      child: Padding(
        padding: tokens.padding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              tokens.glyph,
              size: tokens.glyphSize,
              color: tokens.glyphColor,
              // Scaled once, through the runtime every other IUX component
              // reads. Letting Flutter scale it again would enlarge the glyph
              // twice as fast as the label beside it.
              applyTextScaling: false,
            ),
            SizedBox(width: tokens.gap),
            // Flexible so the label keeps wrapping once the glyph has taken its
            // share of the width. Without it, enlarging text turns a wrapping
            // indicator into an overflowing one.
            Flexible(
              child: Text(
                status.label,
                style: tokens.textStyle,
                // No line limit and no ellipsis, at any text scale. "Payment
                // decl…" is a status nobody can act on, and truncation gets
                // worse exactly when a user has enlarged their text.
                softWrap: true,
              ),
            ),
          ],
        ),
      ),
    );

    // One node carrying the label, with the visual excluded because it repeats
    // that same string verbatim. No button flag: this is not a control, and a
    // screen reader that announced it as one would send the user looking for a
    // gesture that does nothing.
    return IuxSemantics.group(
      label: status.label,
      child: IuxSemantics.decorative(child: visual),
    );
  }
}
