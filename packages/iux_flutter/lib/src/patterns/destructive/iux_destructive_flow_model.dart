import 'package:flutter/foundation.dart';

/// Why a notice with no words is refused.
const String _kEmptyNotice =
    'The notice is what tells the user the deletion happened, and it is the '
    'only thing carrying the way back with it. Empty, it reaches a sighted '
    'user as a bar with a button in it and a screen-reader user as an empty '
    'live region followed by a control called "Undo" — undo of what, neither '
    'is told. Say what happened: "Invoice archived", already localised.';

/// Why an unlabelled way back is refused.
const String _kEmptyUndoLabel =
    'The control that takes the deletion back must be labelled. Name the '
    'outcome — "Undo", "Restore", "Put it back" — already localised. An '
    'unlabelled control inside a message nobody is obliged to read is a '
    'control nobody can identify, and this is the one control the user needs '
    'most.';

/// Why an empty announced name is refused rather than ignored.
const String _kEmptyUndoSemanticLabel =
    'An empty undoSemanticLabel would replace the visible one with nothing. '
    'Omit the parameter instead.';

/// Why an unnamed dismissal is refused.
const String _kEmptyDismissLabel =
    'The control that removes the notice must be named: it is an icon with no '
    'text, so unnamed it reaches a screen reader as "button" beside the one '
    'control that would give the user their data back. Say what disappears — '
    '"Dismiss the archived-invoice notice" — already localised.';

/// How far the loss reaches, which is what decides how much protection is
/// proportionate.
///
/// **The question this enum asks is not "how bad is it".** Nobody answers that
/// consistently, and a caller who has just written a deletion is the worst
/// placed person in the project to judge it. It asks something a caller can
/// answer without training and cannot get wrong by accident:
///
/// > **Could the user list what they are about to lose?**
///
/// That question is the difference between deleting one draft and deleting an
/// account, and it is the difference that matters here — because a way back
/// offered *after* the fact only helps somebody who can tell that they need
/// it. A user who deleted the wrong draft knows immediately. A user who
/// deleted an account cannot know what was in it, so an offer to reverse it is
/// an offer they cannot evaluate, on a screen they are on their way out of.
///
/// ## There are two values, and there are two for a reason
///
/// This pattern has exactly two safeguards to allocate — the user is asked
/// first, or the user is given a way back — so a scale with four rungs would
/// have two that changed nothing. `PROJECT_PROMPT.md` §19 calls that dead
/// public API, and a ladder whose middle steps are decorative teaches a
/// precision the framework does not have.
///
/// The scale is therefore the smallest one that separates the two cases, and
/// the documentation carries the worked examples instead of the type.
enum IuxDestructiveScope {
  /// Things the user picked out and could name: a draft, a photo, the
  /// forty-one messages they selected, one person's access to one document.
  ///
  /// The user knows what goes because they chose it, so they will know at once
  /// if it was the wrong thing — which is exactly the condition an undo offer
  /// needs in order to be a safeguard rather than a formality.
  ///
  /// A count does not move a deletion out of this value. Forty-one selected
  /// photographs are still forty-one things the user chose; what would move it
  /// is the user no longer being able to say what is in the set.
  items,

  /// A whole account, workspace, library, history or device's local data.
  ///
  /// Nobody can enumerate what is inside, including the person deleting it,
  /// which is why they must be told what it costs **before** they answer
  /// rather than offered a reversal afterwards. An [IuxUndoOffer] is refused
  /// at this scope: it would be a control shown on a screen the deletion takes
  /// away, offering to reverse something the user cannot inspect.
  ///
  /// Use it for a container the user cannot open and count — "delete this
  /// folder and everything in it" qualifies as surely as "delete your
  /// account".
  everything,
}

/// What the user can do about a deletion afterwards, stated rather than
/// assumed.
///
/// **This type exists because the absence of a way back has to be a claim
/// somebody made, not a parameter somebody forgot.** It is the same reasoning
/// as `IuxUnrecoverable` in the error pattern: an optional undo is one every
/// rushed call site omits, and the omission is silent — the deletion still
/// runs, on the first tap, with nothing offered and nobody asked.
///
/// Naming one of the two members is what decides the whole shape of the flow,
/// and the two are exhaustive by construction:
///
/// | Member | Claims | The flow then |
/// | --- | --- | --- |
/// | [IuxUndoOffer] | this screen can put it back, in one control | runs on the first activation and offers the way back |
/// | [IuxNoWayBack] | this screen cannot | asks before running, and needs the wording to ask with |
///
/// ## Undo or confirmation, never both and never neither
///
/// A confirmation charges **every** user a step to prevent a mistake **most**
/// of them will never make. An undo charges nothing until somebody errs, and
/// it is the only one of the two that helps the user who meant to press the
/// button and was wrong about what it did — they confirm the dialog too.
///
/// So an undo, where it is genuinely available, is the better instrument, and
/// this type makes it the shorter thing to write. But it is not free, and the
/// cost falls on particular people: an undo requires the user to *notice* the
/// offer. Somebody working with a screen reader hears the notice queued behind
/// whatever was already being spoken; somebody scanning with a switch needs
/// several seconds to reach the control; somebody who looked away sees
/// nothing. A confirmation interrupts all of them, which is its whole cost and
/// also its whole virtue — nobody misses it.
///
/// The framework's answer is to remove the failure rather than narrow it. The
/// notice built from an [IuxUndoOffer] **carries an action, so it never
/// expires** — `IuxTransientTiming` returns no dwell at all for it. There is no
/// window to beat and no race to lose. What remains is that the user must
/// still find the control, which is why the offer is refused for losses they
/// cannot evaluate: see [IuxDestructiveScope].
@immutable
sealed class IuxWayBack {
  /// Creates a way back.
  const IuxWayBack();

  /// Whether this way back removes the need to ask the user first.
  ///
  /// Exactly one safeguard is applied, and this is the switch between them.
  /// It is a property of the type rather than a parameter, so no call site can
  /// claim an undo and a confirmation at once — which would interrupt everyone
  /// *and* leave a control on screen afterwards — or claim neither.
  bool get replacesConfirmation => this is IuxUndoOffer;
}

/// The deletion can be taken back from here, in one control, and here is it.
///
/// ```dart
/// IuxUndoOffer(
///   notice: l10n.invoiceArchived,                     // 'Invoice archived'
///   undoLabel: l10n.undo,                             // 'Undo'
///   undoSemanticLabel: l10n.undoArchivingMarchInvoice,
///   dismissLabel: l10n.dismissArchivedNotice,
///   onUndo: model.restoreInvoice,
/// )
/// ```
///
/// Naming this type is a claim, and the claim is stronger than "the data could
/// in principle be recovered". It says the application can restore what was
/// destroyed **when [onUndo] is called**, with no further work from the user
/// and no second screen. A trash folder the user has to go and find is not
/// this; a support request is not this; a backup taken last night is not this.
/// Those are ways back, and they are ways back the user must be told about
/// *before* they answer, which makes them [IuxNoWayBack] with the route
/// written into the confirmation's consequence.
///
/// ## The window is not here, and it is not anywhere in the framework
///
/// How long an application holds a deleted row before committing is a decision
/// about data. It depends on what the row is, what else refers to it, and what
/// the storage costs — none of which a widget can see. So IUX imposes no
/// window, and the offer it builds has no deadline of its own.
///
/// If the application *does* have a window, the application has created a time
/// limit, and WCAG 2.2 SC 2.2.1 then applies to the application rather than to
/// this pattern: it must be possible to turn the limit off, adjust it, or
/// extend it. At the very least, call
/// `IuxDestructiveFlowController.dismissNotice()` at the instant the window
/// closes, so the control never outlives the promise it makes. An "Undo" that
/// does nothing is worse than no offer at all: the user presses it, believes
/// their work is back, and finds out later that it is not.
@immutable
final class IuxUndoOffer extends IuxWayBack {
  /// Creates the offer shown after the deletion has run.
  const IuxUndoOffer({
    required this.notice,
    required this.undoLabel,
    required this.dismissLabel,
    required this.onUndo,
    this.undoSemanticLabel,
  })  : assert(notice.length > 0, _kEmptyNotice),
        assert(undoLabel.length > 0, _kEmptyUndoLabel),
        assert(dismissLabel.length > 0, _kEmptyDismissLabel),
        assert(
          undoSemanticLabel == null || undoSemanticLabel.length > 0,
          _kEmptyUndoSemanticLabel,
        );

  /// What has now happened, already localised.
  ///
  /// One short sentence in the past tense — "Invoice archived", "3 photos
  /// deleted". It is announced as a live region the moment the notice appears,
  /// so it is the first and sometimes the only thing a screen-reader user
  /// receives about the deletion.
  ///
  /// State the fact, not the offer. "Invoice archived" reads as an account of
  /// what the user's own tap did; "Tap undo to restore the invoice" is an
  /// instruction for a control that is already labelled and already announced,
  /// and it spends the one sentence available saying so.
  final String notice;

  /// The visible text of the control that takes it back, already localised.
  ///
  /// Name the outcome — "Undo", "Restore", "Put it back". One word or two: it
  /// sits in a bar at the bottom of a screen the user was not looking at.
  final String undoLabel;

  /// The accessible name of the control that removes the notice, already
  /// localised.
  ///
  /// Required, and it is not bureaucracy: it is an icon with no text of its
  /// own, and it sits next to the way back. "Close" is the same word for every
  /// message the application will ever show, which is no help to somebody
  /// deciding whether the thing they are about to activate is the one that
  /// restores their invoice.
  final String dismissLabel;

  /// Called once each time the user takes the way back.
  ///
  /// What it restores, and whether restoring it worked, are the application's.
  /// The flow reports that the user asked and removes the offer; it does not
  /// decide that the data came back, because it cannot know.
  final VoidCallback onUndo;

  /// What a screen reader announces instead of [undoLabel].
  ///
  /// A bare "Undo" tells a user who arrived at the control by swiping nothing
  /// about what it undoes, and this is the control where that matters most —
  /// they are being asked to trust it with data that is currently gone. "Undo
  /// archiving the March invoice" costs the sighted user nothing.
  final String? undoSemanticLabel;

  /// The accessible name actually used by the way back.
  String get effectiveUndoSemanticLabel => undoSemanticLabel ?? undoLabel;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxUndoOffer &&
          other.notice == notice &&
          other.undoLabel == undoLabel &&
          other.dismissLabel == dismissLabel &&
          other.onUndo == onUndo &&
          other.undoSemanticLabel == undoSemanticLabel;

  @override
  int get hashCode => Object.hash(
        notice,
        undoLabel,
        dismissLabel,
        onUndo,
        undoSemanticLabel,
      );

  @override
  String toString() => 'IuxUndoOffer($notice)';
}

/// This screen cannot put it back, so the user is asked before it happens.
///
/// ```dart
/// const IuxNoWayBack()
/// ```
///
/// It carries nothing, deliberately. Everything the user needs in order to
/// answer belongs in the `IuxConfirmationPrompt` the flow then requires —
/// including a way back that exists somewhere else. "The files move to Trash
/// and are removed after 30 days" is a consequence, and it belongs in the
/// sentence the user reads *before* deciding, where it can change their
/// answer. Told afterwards it is a fact about a screen they are no longer on.
///
/// So this member does not mean "the data is destroyed forever". It means the
/// weaker and more useful thing: **there is no control this pattern can put in
/// front of the user that undoes it**, and therefore the protection has to
/// come before rather than after.
@immutable
final class IuxNoWayBack extends IuxWayBack {
  /// Creates the claim that nothing here reverses the deletion.
  const IuxNoWayBack();

  @override
  bool operator ==(Object other) => other is IuxNoWayBack;

  @override
  int get hashCode => (IuxNoWayBack).hashCode;

  @override
  String toString() => 'IuxNoWayBack()';
}
