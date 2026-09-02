import 'package:flutter/material.dart';

import '../../accessibility/iux_semantics.dart';
import 'iux_status_model.dart';
import 'iux_status_tokens.dart';

/// A measured reading, shown as the number it is with the word that reads it.
///
/// ```dart
/// IuxValueIndicator(
///   value: IuxValue.above(
///     '+2.1 °C',
///     meaning: l10n.warmer,
///     label: l10n.aboveTheNormalBy(2.1),
///     accent: IuxValueAccent.one,
///   ),
/// )
/// ```
///
/// **Use it** beside a quantity that has been compared with something — a
/// deviation from a normal, a difference from a budget, a gap to a target —
/// where the number is the point and a word says what it means.
///
/// **Do not use it** for a state: an order that failed is `IuxStatusIndicator`,
/// which draws a category glyph because a state has no reference to be read
/// against. Do not use it for a count of waiting things — that is `IuxBadge`,
/// which is a marker rather than a measurement. Do not use it as a control: it
/// takes no focus, has no touch target and reports no gesture. Do not use it
/// for a reading nobody compared with anything; a column whose every capsule
/// is [IuxValueDirection.at] is decoration that users learn to skip.
///
/// ## Why the direction and not a status tone
///
/// `IuxStatusTone` has four members and they are four families of *news*:
/// a fact, a state the user wanted, a state that will stop working, a state
/// that has stopped. A reading is none of those until somebody judges it, and
/// the framework is not who judges it. Drawing "2.1 degrees above the normal"
/// through `IuxStatusTone.error` to obtain the red the eye expects asserts that
/// a warm summer is a malfunction — a claim IUX has no standing to make and the
/// user no way to refuse. So the reading has its own axis, with three members
/// and no judgement in any of them. See
/// `docs/decisions/ADR-0013-a-reading-is-compared-not-judged.md`.
///
/// ## Why the direction does not choose the colour
///
/// Because one side of a reference is not one hue, and a single application
/// shows it. Rainfall above its normal is *wetter* and reads blue; rainfall
/// below it is *drier* and reads orange; a temperature below its normal is
/// *colder* and reads the same blue as the wet rain. Two of those are above
/// their reference and two below, and the hues cross the axis rather than
/// following it. What decides the hue is what the quantity *means*, which is
/// the application's to know — so [IuxValue.accent] is the caller's, and the
/// only colour the framework still decides is the absence of one, for a reading
/// level with its reference. See
/// `docs/decisions/ADR-0015-the-sign-is-not-the-meaning.md`.
///
/// ## Why there is a word here, and no arrow
///
/// There used to be an arrow, and the argument for it was sound: the reading
/// beside it *usually* carries a sign, and *usually* is not a guarantee — the
/// framework cannot compose a `+` of its own, because it puts no characters
/// into anything a user reads and a `+` is the wrong glyph in some scripts and
/// on the wrong side in others. But the arrow answered that with a shape nobody
/// hears, and it answered nothing at all about *meaning*: it said which side,
/// never which sense. [IuxValue.meaning] answers both, cannot be omitted, and
/// reaches every reader.
///
/// | Signal | Reaches |
/// | --- | --- |
/// | `IuxValue.meaning` | a monochrome screen, a colour vision deficiency |
/// | `IuxValue.label` | everyone, including a screen reader |
/// | the formatted reading | everyone who can see the capsule |
/// | the accent colour | everyone else, as reinforcement |
///
/// **What this cannot guarantee** is that two readings sharing an accent are
/// told apart. `IuxValue.above('12', meaning: 'more', …)` beside another of the
/// same is two identical capsules, and nothing here can refuse them — see
/// *Limits* in `docs/components/badges-and-chips.md`. Write the difference into
/// the words.
class IuxValueIndicator extends StatelessWidget {
  /// Creates a value pill.
  const IuxValueIndicator({super.key, required this.value});

  /// The reading, its accent, and the words that explain it.
  ///
  /// Required, and it has no empty form. See [IuxValue].
  final IuxValue value;

  @override
  Widget build(BuildContext context) {
    final IuxValueTokens tokens = IuxValueResolver.resolve(context, value);

    final Widget visual = Column(
      // Reading order rather than left-to-right order: the word starts where
      // the capsule starts, in every script.
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        DecoratedBox(
          // A tint and no outline. A capsule that rings itself in its own
          // hue reads as an alert the moment it repeats down a column, which
          // is the only place this component is ever used — "une petite
          // capsule légèrement teintée, sans flèche et sans bordure forte".
          // Its extent carries nothing the reading and the word do not carry
          // in text, so there is no boundary to hold to a contrast floor.
          decoration: ShapeDecoration(
            color: tokens.background,
            shape: const StadiumBorder(),
          ),
          child: Padding(
            padding: tokens.padding,
            child: Text(
              value.value,
              style: tokens.textStyle,
              // No line limit and no ellipsis, at any text scale. A truncated
              // measurement — "+2.1 °…" — is a measurement nobody can use, and
              // it gets worse exactly when a user has enlarged their text.
              softWrap: true,
            ),
          ),
        ),
        SizedBox(height: tokens.gap),
        // Outside the capsule, and deliberately. The capsule is the deviation;
        // the word is what the deviation means, and a tint around both would
        // make the sentence look like part of the measurement. It is also what
        // keeps the capsule small enough to sit in a column beside three more
        // of itself.
        Text(value.meaning, style: tokens.meaningStyle, softWrap: true),
      ],
    );

    // One node carrying the sentence, with the visual excluded because the
    // sentence already contains the reading and the word. No button flag: this
    // is not a control, and a screen reader that announced it as one would send
    // the user looking for a gesture that does nothing.
    return IuxSemantics.group(
      label: value.label,
      child: IuxSemantics.decorative(child: visual),
    );
  }
}
