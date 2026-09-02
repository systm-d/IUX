import 'package:flutter/material.dart';

import '../../accessibility/iux_semantics.dart';
import 'iux_status_model.dart';
import 'iux_status_tokens.dart';

/// A measured reading, shown as the number it is and marked with the side of
/// its reference it fell on.
///
/// ```dart
/// IuxValueIndicator(
///   value: IuxValue.above('+2.1 °C', label: l10n.aboveTheNormalBy(2.1)),
/// )
/// ```
///
/// **Use it** beside a quantity that has been compared with something — a
/// deviation from a normal, a difference from a budget, a gap to a target —
/// where the number is the point and the direction says which way it went.
///
/// **Do not use it** for a state: an order that failed is `IuxStatusIndicator`,
/// which draws a category glyph because a state has no reference to be read
/// against. Do not use it for a count of waiting things — that is `IuxBadge`,
/// which is a marker rather than a measurement. Do not use it as a control: it
/// takes no focus, has no touch target and reports no gesture. Do not use it
/// for a reading nobody compared with anything; a pill whose direction is
/// always [IuxValueDirection.at] is decoration that users learn to skip.
///
/// ## Why the direction and not a status tone
///
/// `IuxStatusTone` has four members and they are four families of *news*:
/// a fact, a state the user wanted, a state that will stop working, a state
/// that has stopped. A reading is none of those until somebody judges it, and
/// the framework is not who judges it. Drawing "2.1 degrees above the normal"
/// through `IuxStatusTone.error` to obtain the red the eye expects asserts that
/// a warm summer is a malfunction — a claim IUX has no standing to make and the
/// user no way to refuse. So the pill has its own axis, with three members and
/// no judgement in any of them. See
/// `docs/decisions/ADR-0013-a-reading-is-compared-not-judged.md`.
///
/// ## Why there is a mark here, when the reading usually carries a sign
///
/// Because *usually* is not a guarantee. `IuxValue.above('2.1 °C', …)` compiles
/// and so does every locale's formatting of it, and a pill whose caller omitted
/// the sign is separated from its opposite by hue alone. That is the failure
/// this family exists to make unreachable rather than to advise against, and
/// the framework cannot add the sign itself: it composes no user-facing text,
/// and a `+` written by the library would be the wrong glyph in some scripts
/// and the wrong position in others.
///
/// | Signal | Reaches |
/// | --- | --- |
/// | the mark's shape | a monochrome screen, a colour vision deficiency |
/// | `IuxValue.label` | everyone, including a screen reader |
/// | the formatted reading | everyone who can see the pill |
/// | the direction colour | everyone else, as reinforcement |
///
/// **What this cannot guarantee** is that two pills sharing a direction are
/// told apart. `IuxValue.above('12', …)` beside another `IuxValue.above('12',
/// …)` is two identical pills, and nothing here can refuse them — see *Limits*
/// in `docs/components/badges-and-chips.md`. Write the difference into the
/// labels.
class IuxValueIndicator extends StatelessWidget {
  /// Creates a value pill.
  const IuxValueIndicator({super.key, required this.value});

  /// The reading, its direction, and the sentence that explains it.
  ///
  /// Required, and it has no empty form. See [IuxValue].
  final IuxValue value;

  @override
  Widget build(BuildContext context) {
    final IuxValueTokens tokens =
        IuxValueResolver.resolve(context, value.direction);

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
              tokens.mark,
              size: tokens.markSize,
              color: tokens.markColor,
              // Scaled once, through the runtime every other IUX component
              // reads. Letting Flutter scale it again would enlarge the mark
              // twice as fast as the reading beside it.
              applyTextScaling: false,
            ),
            SizedBox(width: tokens.gap),
            // Flexible so the reading keeps wrapping once the mark has taken
            // its share of the width. Without it, enlarging text turns a
            // wrapping pill into an overflowing one.
            Flexible(
              child: Text(
                value.value,
                style: tokens.textStyle,
                // No line limit and no ellipsis, at any text scale. A
                // truncated measurement — "+2.1 °…" — is a measurement nobody
                // can use, and it gets worse exactly when a user has enlarged
                // their text.
                softWrap: true,
              ),
            ),
          ],
        ),
      ),
    );

    // One node carrying the sentence, with the visual excluded because the
    // sentence already contains the reading. No button flag: this is not a
    // control, and a screen reader that announced it as one would send the
    // user looking for a gesture that does nothing.
    return IuxSemantics.group(
      label: value.label,
      child: IuxSemantics.decorative(child: visual),
    );
  }
}
