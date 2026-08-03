import 'package:flutter/foundation.dart';

/// Why a message with no words is refused.
const String _kEmptyText =
    'A transient message with no text is a coloured rectangle that disappears. '
    'A sighted user sees a flicker at the bottom of the screen; a '
    'screen-reader user hears an empty live region. Pass the localised '
    'sentence.';

/// Why the dismiss control must be named.
const String _kEmptyDismissLabel =
    'The dismiss control is the only way a user stops the clock and removes '
    'the message before it removes itself, and it is an icon with no text. '
    'Unnamed it reaches a screen reader as "button". Say what disappears — '
    '"Dismiss the saved-draft notice" — already localised.';

/// Why an unlabelled action is refused.
const String _kEmptyActionLabel =
    'An unlabelled control inside a message nobody is required to read is a '
    'control nobody can identify. Pass the localised verb.';

/// Why an empty semantic label is refused rather than ignored.
const String _kEmptyActionSemanticLabel =
    'An empty semanticLabel would replace the visible one with nothing. Omit '
    'it instead.';

/// How a transient message is tinted, and nothing more than that.
///
/// **There are two values, and the missing ones are the point.** There is no
/// `error` and no `warning` here, and there will not be one. A failure that
/// vanishes on a timer is a failure the user cannot act on: they looked away,
/// or they were three words into another sentence, and the only account of
/// what went wrong left the screen while they were not watching. A warning
/// about a consequence is worse still, because the consequence is still
/// coming. Both belong in an `IuxAlert`, which stays until the parent removes
/// it, or in an `IuxDialog` when the user must answer before continuing.
///
/// What is left is the tone of something the user does **not** need: a
/// statement of fact, or the confirmation of an operation they started and
/// already expect to have worked.
///
/// The tone is reinforcement, never information. It tints the container and,
/// for [success], adds a glyph — both for the users who can see them. It is
/// deliberately *not* spoken: unlike `IuxAlert`, this component asks for no
/// localised category word, because a message whose category a user needs to
/// know is a message that must not disappear. If you find yourself needing the
/// user to notice the tone, you have information, and information does not
/// belong here.
enum IuxTransientTone {
  /// A plain statement of fact.
  ///
  /// The default, and the right answer more often than [success]. "Copied",
  /// "Reconnected", "Sorting by date" — nothing succeeded or failed, something
  /// is simply now true.
  neutral,

  /// An operation the user started completed.
  ///
  /// Worth stating only when the result is not visible on its own. A "Sent"
  /// message over a conversation that now shows the sent message is the same
  /// fact told twice, and the second telling costs the bottom of the screen.
  success,
}

/// Something the user may do about a message that is about to leave.
///
/// **This is the most dangerous thing in this file.** An action attached to a
/// message that expires on a timer is an action for fast people: the user who
/// reads slowly, who is mid-sentence in a screen reader, who looked at their
/// hands to press the button, or who needs two seconds to move a switch to the
/// control, all lose it — and they lose it silently, with no way to know what
/// they were offered.
///
/// IUX answers that in the only way that removes the failure rather than
/// narrowing it: **a message carrying an action does not expire.** There is no
/// duration to tune and no race to lose. It stays until the user answers it,
/// dismisses it, or the parent replaces it. See `IuxTransientTiming`.
///
/// That has a price, and the price is the parent's: the message occupies the
/// bottom of the screen until somebody deals with it. If that is unacceptable
/// in your layout, the conclusion is not a shorter timer — it is that the
/// action does not belong in a transient message.
///
/// **The undo window is not this object's business.** How long an application
/// holds a deleted row before committing the deletion is a decision about
/// data, and it belongs to the parent, which can start and stop its own clock.
/// Tying it to how long a widget happens to be painted is how "Undo" becomes a
/// promise the interface breaks for the slowest users first.
@immutable
final class IuxTransientAction {
  /// Creates an action offered inside a transient message.
  const IuxTransientAction({
    required this.label,
    required this.onActivate,
    this.semanticLabel,
  })  : assert(label.length > 0, _kEmptyActionLabel),
        assert(
          semanticLabel == null || semanticLabel.length > 0,
          _kEmptyActionSemanticLabel,
        );

  /// The visible text, already localised.
  ///
  /// One word or two. Name the outcome — *Undo*, *View*, *Retry* — never the
  /// mechanism.
  final String label;

  /// Called once per activation.
  ///
  /// The message does not change as a result, and does not remove itself. The
  /// parent owns whether it is on screen and clears it when the state it
  /// described has moved on.
  final VoidCallback onActivate;

  /// What a screen reader announces instead of [label].
  ///
  /// A bare "Undo" tells a user who arrived at the control by swiping nothing
  /// about what it will undo. "Undo deleting the March invoice" costs the
  /// sighted user nothing.
  final String? semanticLabel;

  /// The accessible name actually used.
  String get effectiveSemanticLabel => semanticLabel ?? label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxTransientAction &&
          other.label == label &&
          other.onActivate == onActivate &&
          other.semanticLabel == semanticLabel;

  @override
  int get hashCode => Object.hash(label, onActivate, semanticLabel);

  @override
  String toString() => 'IuxTransientAction($label)';
}

/// One short sentence the user is allowed to miss.
///
/// ```dart
/// IuxTransientMessage(
///   text: l10n.draftSaved,
///   dismissLabel: l10n.dismissDraftSavedNotice,
///   tone: IuxTransientTone.success,
/// )
/// ```
///
/// **The rule that governs every other decision in this component: never put
/// anything here that the user needs.** A transient message is the worst
/// carrier of information in the library. It leaves on a timer, so a slow
/// reader loses it, a screen-reader user who was midway through another
/// sentence loses it, a user who glanced away loses it, and none of them is
/// told that anything left. There is no scrollback and no history — when it is
/// gone it is gone.
///
/// The test to apply before using it: *if this user looked away for ten
/// seconds and never saw this message at all, is anything worse for them?* If
/// the answer is yes, it belongs in an `IuxAlert` beside the thing it concerns,
/// in an `IuxBanner` if it describes the whole screen, or in an `IuxDialog` if
/// they must answer it. If the answer is no, it may go here — and it may just
/// as well go nowhere.
///
/// **This is a value, not a widget, and deliberately so.** An `IuxDialog` can
/// be handed around as a widget because a dialog is self-contained wherever it
/// is placed. A transient message is defined by *not* occupying layout: put one
/// in a `Column` and it pushes the page down, which is precisely the thing it
/// must never do. Describing it as a value and letting `IuxTransientLayer`
/// place it removes that mistake from the API rather than warning about it.
@immutable
final class IuxTransientMessage {
  /// Creates a transient message.
  const IuxTransientMessage({
    required this.text,
    required this.dismissLabel,
    this.tone = IuxTransientTone.neutral,
    this.action,
  })  : assert(text.length > 0, _kEmptyText),
        assert(dismissLabel.length > 0, _kEmptyDismissLabel);

  /// What is now true, already localised.
  ///
  /// One sentence. It has to be readable in a glance at the bottom of a screen
  /// the user is not looking at, so it carries no preamble, no error code and
  /// no second clause. A message long enough to need two sentences is a message
  /// somebody has to be given time to read, and time is the one thing this
  /// component does not guarantee.
  ///
  /// Length is not capped, because a cap in code cannot know German from
  /// Japanese. It is not free either: `IuxTransientTiming` derives how long the
  /// message stays from how long it takes to read, so a long sentence stays
  /// longer rather than being cut off mid-thought.
  final String text;

  /// The accessible name of the control that removes the message, already
  /// localised.
  ///
  /// Required, and it is not bureaucracy. This control is what stops the clock
  /// and takes the message away for a user who has read it, and it is an icon
  /// with no text of its own. Say what disappears — "Dismiss the saved-draft
  /// notice" — rather than "Close", which is the same word for every message
  /// the application will ever show.
  final String dismissLabel;

  /// How the message is tinted. See [IuxTransientTone].
  ///
  /// It carries no information, and the enum has no value for anything that
  /// would.
  final IuxTransientTone tone;

  /// What the user may do about it, or null — which is the normal answer.
  ///
  /// Attaching one changes the component's behaviour rather than its
  /// appearance: the message stops expiring. Read [IuxTransientAction] before
  /// using it.
  final IuxTransientAction? action;

  /// Whether [other] says the same thing to a user as this message.
  ///
  /// Used to decide whether a rebuild carries a *new* message — which restarts
  /// the clock and re-announces the live region — or the same one again.
  /// Deliberately not `==`: a parent that rebuilds every frame produces a fresh
  /// closure for [IuxTransientAction.onActivate] every frame, and a message
  /// that restarted its own countdown on every frame would never leave.
  ///
  /// [dismissLabel] is excluded for the same reason it is not spoken with the
  /// text: relabelling the way out is not news. Whether an action is *attached*
  /// is included, because that is what decides whether the message expires at
  /// all.
  bool saysTheSameAs(IuxTransientMessage other) =>
      other.text == text &&
      other.tone == tone &&
      (other.action == null) == (action == null);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxTransientMessage &&
          other.text == text &&
          other.dismissLabel == dismissLabel &&
          other.tone == tone &&
          other.action == action;

  @override
  int get hashCode => Object.hash(text, dismissLabel, tone, action);

  @override
  String toString() => 'IuxTransientMessage(${tone.name}, "$text")';
}
