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
