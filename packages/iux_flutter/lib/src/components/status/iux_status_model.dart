import 'package:flutter/foundation.dart';

/// The family of meaning a status belongs to.
///
/// Four families rather than an open set of strings: a status indicator has to
/// resolve a glyph and a measured colour pair for whatever it is given, and it
/// can only do that for a closed list. An application that needs a fifth
/// meaning is describing its domain, not a UX category, and that belongs in the
/// label.
///
/// The tone is *not* the signal. It selects a glyph and a colour pair; the
/// words in [IuxStatus.label] carry the meaning. A screen reader is told
/// nothing about the tone, which is why the label has to say "Payment failed"
/// rather than "Payment".
enum IuxStatusTone {
  /// A state with no consequence attached: idle, offline, draft, archived.
  ///
  /// The resting tone. Use it whenever a state is simply a fact rather than
  /// good or bad news — colouring a neutral state green or red asks the user
  /// to react to something that needs no reaction.
  neutral,

  /// A state the user wanted: connected, paid, published, verified.
  success,

  /// A state that still works but will not for long, or that has a
  /// consequence the user should know about: expiring, low, degraded.
  warning,

  /// A state that has stopped working and needs attention: failed, rejected,
  /// disconnected.
  error,
}

/// A state worth telling the user about, and the words that carry it.
///
/// ```dart
/// IuxStatusIndicator(status: IuxStatus.error(l10n.paymentDeclined))
/// ```
///
/// There is no constructor that does not take a label, and the label may not be
/// empty. That is the whole point of this class. A status carried by a coloured
/// dot alone is invisible to a screen reader, ambiguous to the roughly 1 in 12
/// men with a colour vision deficiency, and meaningless on a monochrome or
/// sun-washed display — so IUX makes that state impossible to construct rather
/// than discouraged in a style guide.
///
/// The label arrives already localised, and it must be able to stand alone.
/// "Failed" beside a row the user has already scrolled past says nothing;
/// "Payment failed" says what happened. IUX composes no user-facing text: it
/// cannot know whether the tone should be spoken ("Error: payment failed") in
/// the reader's language, so the caller writes the whole sentence.
///
/// A value class rather than four widget constructors, because the parent
/// normally holds the status in its own model and passes it down. Keeping the
/// tone and the words in one indivisible object is what stops them drifting
/// apart — the same reason `IuxInputValidation` carries its message.
@immutable
final class IuxStatus {
  const IuxStatus._(this.tone, this.label)
      : assert(
          label.length > 0,
          'A status must say what it is. An empty label leaves a coloured '
          'shape that a screen reader announces as nothing and that a user '
          'who cannot distinguish the hue cannot read at all. Pass the '
          'localised sentence — "Payment failed", not "".',
        );

  /// A state with no consequence attached.
  const IuxStatus.neutral(String label) : this._(IuxStatusTone.neutral, label);

  /// A state the user wanted.
  const IuxStatus.success(String label) : this._(IuxStatusTone.success, label);

  /// A state with a consequence the user should know about.
  const IuxStatus.warning(String label) : this._(IuxStatusTone.warning, label);

  /// A state that has stopped working.
  const IuxStatus.error(String label) : this._(IuxStatusTone.error, label);

  /// Which family this state belongs to.
  ///
  /// Selects the glyph and the colour pair. It never replaces [label].
  final IuxStatusTone tone;

  /// What the state is, already localised, and never empty.
  ///
  /// Both the visible text and the accessible name. They are deliberately the
  /// same string: a status whose spoken form differs from its written one gives
  /// two users two different facts about the same row, and there is no case
  /// where that helps.
  final String label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxStatus && other.tone == tone && other.label == label;

  @override
  int get hashCode => Object.hash(tone, label);

  @override
  String toString() => 'IuxStatus(${tone.name}, "$label")';
}

/// Which side of a reference a reading fell on.
///
/// Three members, and the number is arithmetic rather than taste: a quantity
/// compared with a reference is above it, level with it, or below it. There is
/// no fourth side, so there is no pressure on this enum to grow one — which is
/// the property [IuxStatusTone] does not have and has to defend in prose.
///
/// **This is a second axis, not a fifth tone.** [IuxStatusTone] names four
/// families of *news* — a fact, a state the user wanted, a state that will stop
/// working, a state that has stopped. A reading two degrees above its reference
/// is none of those. Sending it through [IuxStatusTone.error] to obtain the
/// colour the eye expects would assert that a warm summer is a malfunction,
/// which is a claim no framework has standing to make about a number it did not
/// measure — and `IuxStatusTone.neutral` already warns that colouring a neutral
/// state red "asks the user to react to something that needs no reaction".
///
/// "Four tones and no more" in `docs/components/badges-and-chips.md` bounds the
/// axis of news. It says an application needing a fifth *meaning of news* is
/// describing its domain. Above, level and below are not a domain: a budget, a
/// blood pressure, a lap time and a rainfall total are all compared with a
/// reference, and none of them is good or bad news until somebody says so. See
/// `docs/decisions/ADR-0013-a-reading-is-compared-not-judged.md`.
///
/// The direction is *not* the signal. It selects a mark and a colour pair; the
/// words in [IuxValue.label] carry the meaning. A screen reader is told nothing
/// about the direction, which is why the label has to say "2.1 degrees above
/// the 1991 to 2020 normal" rather than "2.1 degrees".
enum IuxValueDirection {
  /// The reading sits on the upper side of its reference.
  above,

  /// The reading is level with its reference.
  ///
  /// The resting direction, and the one to reach for whenever a reading is
  /// simply where it was expected to be. It is drawn neutrally on purpose: a
  /// coloured pill on every row of a list is a pill users learn to skip.
  at,

  /// The reading sits on the lower side of its reference.
  below,
}

/// A measured reading, the side of its reference it fell on, and the sentence
/// that says what that means.
///
/// ```dart
/// IuxValue.above('+2.1 °C', label: l10n.aboveTheNormalBy(2.1))
/// ```
///
/// The sister of [IuxStatus], and the difference is what each one is *about*: a
/// status is a state — failed, offline, awaiting review — and a value is a
/// quantity that has been compared with something. "+2.1 °C" is not a state; it
/// is a number read against a reference the caller chose.
///
/// **Why the direction and not a tone.** A tone is news, and news is a
/// judgement about a quantity rather than a property of it. The framework
/// cannot make that judgement — it does not know whether a dry summer is what
/// the user was hoping for — and an application that makes it through a tone
/// ships the judgement as a colour nobody can argue with. A direction is a fact
/// about the arithmetic: the caller compared two numbers and one was larger.
///
/// [value] is what the eye reads, already formatted and localised; [label] is
/// what the ear hears. They are separate parameters because they are different
/// strings, and the assertion fires when they are the same one — a label that
/// repeats the numeral hands a screen-reader user a number with no referent,
/// which is the whole failure this class exists to prevent.
///
/// A value class rather than three widget constructors, because the parent
/// normally holds the reading in its own model and passes it down. Keeping the
/// direction and the words in one indivisible object is what stops them
/// drifting apart — the same reason [IuxStatus] carries its label.
@immutable
final class IuxValue {
  const IuxValue._(this.direction, this.value, this.label)
      : assert(
          value.length > 0,
          'A value pill with nothing in it is a coloured shape that claims '
          'something was measured and refuses to say what. Pass the formatted '
          'reading — "+2.1 °C", not "".',
        ),
        assert(
          label.length > 0,
          'A reading must say what it measures. Without a label a screen '
          'reader announces a bare number, which tells the user how much of '
          'nothing.',
        ),
        assert(
          label != value,
          'The label repeats the numeral instead of saying what it means. '
          '"+2.1 °C" is a reading; "2.1 degrees above the 1991 to 2020 '
          'normal" is information. Pass the localised sentence, not the '
          'numeral twice.',
        );

  /// A reading on the upper side of its reference.
  const IuxValue.above(String value, {required String label})
      : this._(IuxValueDirection.above, value, label);

  /// A reading level with its reference.
  const IuxValue.at(String value, {required String label})
      : this._(IuxValueDirection.at, value, label);

  /// A reading on the lower side of its reference.
  const IuxValue.below(String value, {required String label})
      : this._(IuxValueDirection.below, value, label);

  /// Which side of the reference this reading fell on.
  ///
  /// Selects the mark and the colour pair. It never replaces [label].
  final IuxValueDirection direction;

  /// The formatted reading, drawn and never announced.
  ///
  /// A string rather than a number, for the reason `IuxBadge.count` takes one:
  /// `2,1`, `2.1` and `٢٫١` are three different strings and only the caller
  /// knows which applies, along with the unit and where it goes.
  final String value;

  /// What the reading means, already localised, and never equal to [value].
  ///
  /// It has to stand alone. "Above" beside a row the user has already scrolled
  /// past says nothing; "2.1 degrees above the 1991 to 2020 normal" says what
  /// was measured, against what, and by how much. IUX composes no user-facing
  /// text and cannot name the reference for you.
  final String label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxValue &&
          other.direction == direction &&
          other.value == value &&
          other.label == label;

  @override
  int get hashCode => Object.hash(direction, value, label);

  @override
  String toString() => 'IuxValue(${direction.name}, "$value")';
}
