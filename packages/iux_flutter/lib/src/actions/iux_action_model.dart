import 'package:flutter/foundation.dart';

/// What an action means in its context.
///
/// Intent is meaning, and it is the only dimension a component may resolve
/// into colour. How *heavy* the result is belongs to `IuxButtonVariant` when a
/// call site names one, and to [IuxActionImportance] when it does not.
///
/// There is no `neutral`. A role that resolves to nothing distinguishable is a
/// name for nothing — which is precisely what [tertiary] was until IUX-039
/// measured it.
enum IuxActionIntent {
  /// The single most important action of a context.
  ///
  /// One dominant primary action per logical group. "Primary" describes this
  /// screen, not the application: a rarely used screen still has one.
  ///
  /// Never use it on a destructive action merely to draw attention.
  primary,

  /// A supporting action that carries the interface's accent.
  ///
  /// It is a way *through* the task, just not the dominant one: "Save draft"
  /// beside "Publish", "Add another" beside "Continue".
  secondary,

  /// An action that leads away from the task rather than through it.
  ///
  /// Going back, closing, skipping, dismissing. It is drawn without the
  /// accent — not dimmed, not shrunk, and never below the contrast every other
  /// intent must meet: it simply does not claim to be a step forward, because
  /// it is not one.
  ///
  /// Until IUX-039 this member read "a low-emphasis action", which is a
  /// statement about weight rather than about meaning — and weight is what
  /// `IuxButtonVariant` and [IuxActionImportance] already say. Measured across
  /// all four theme profiles, it rendered byte-identically to [secondary] in
  /// `outlined`, `tonal`, `text` and `icon`: the semantic layer distinguished
  /// the two by a `border` token no variant painted. An intent that describes
  /// emphasis can only ever duplicate the axis that resolves emphasis, so this
  /// one was given the meaning its only deliberate caller already relied on —
  /// `IuxAppBar`'s back control, which carries it because leaving a screen is
  /// never the thing the user came to do.
  tertiary,

  /// An action that deletes, alters or revokes data, state or access.
  ///
  /// Its consequence is carried by wording, confirmation and semantics —
  /// never by colour alone.
  destructive,
}

/// How prominent an action is when no call site names a variant.
///
/// Orthogonal to intent: intent says what an action means, importance says how
/// hard it should be to miss. A destructive action may be low importance
/// ("Clear filters"); a secondary action may be high ("Save draft" on a form
/// the user has been filling for ten minutes).
///
/// It resolves to the button variant an action is drawn with when the call
/// site does not override it — see `IuxButtonResolver`. That is the whole of
/// its effect, and it is deliberately the whole: until IUX-039 this enum was
/// stored, copied, compared and hashed and read by nothing, so `high` and
/// `low` rendered and announced identically. Wiring it to a *second* visual
/// channel alongside the variant would have given a caller two knobs that must
/// agree, which §20 refuses; deleting it would have left "how loud is this"
/// expressible only by naming a variant, which is the styling parameter §20
/// refuses just as firmly. Choosing the default is the one job that is neither.
enum IuxActionImportance {
  /// Prominent. The user is expected to reach for it.
  ///
  /// Resolves to the heaviest container the intent permits: a fill for
  /// [IuxActionIntent.primary] and [IuxActionIntent.destructive], an outline
  /// for the two intents the semantic layer models unfilled.
  high,

  /// Available without competing for attention. The default.
  medium,

  /// Present for those who need it. Drawn as a label with no container.
  low,
}

/// What the action does in the flow.
///
/// A vocabulary for stating what an action is, so that a component or a
/// pattern can refuse a combination that cannot mean anything: `IuxEmptyState`
/// rejects [retry] because a collection that is empty never failed, and this
/// library rejects an [undo] that declares itself irreversible.
///
/// It reaches no pixel and no announcement, and saying otherwise was a defect
/// of its own — the docstring claimed "semantics, feedback and pattern
/// selection" and IUX-039 measured none of the three. What it buys is error
/// prevention (PROJECT_PROMPT §22), which is worth more here than a rendering
/// difference would be: two buttons that differ only by role would differ for
/// a sighted user and not for a screen-reader one.
///
/// Deliberately finite: an open-ended list becomes a taxonomy nobody agrees
/// on. Business meanings belong to the application, not here.
enum IuxActionRole {
  /// Commits a form or a composition.
  submit,

  /// Confirms a decision the user already expressed.
  confirm,

  /// Abandons an in-progress task, discarding input.
  cancel,

  /// Closes something without discarding anything.
  ///
  /// Distinct from [cancel]: dismissing a tooltip loses nothing, cancelling a
  /// form loses what was typed, and announcing them identically is how users
  /// lose work.
  dismiss,

  /// Moves the user elsewhere.
  navigate,

  /// Attempts a failed operation again.
  retry,

  /// Reverses a previous action.
  undo,

  /// Removes something.
  delete,

  /// Opens something for modification.
  edit,

  /// Chooses among options.
  select,

  /// None of the above.
  ///
  /// Reach for this last. A `custom` role tells the semantics layer nothing.
  custom,
}

/// Whether an action can currently be activated.
///
/// There is no `readOnly`. Read-only describes a field, not an action: an
/// action that cannot be performed is simply unavailable, and a second word
/// for it would only invite inconsistent use.
enum IuxActionAvailability {
  /// Can be activated.
  enabled,

  /// Cannot be activated.
  ///
  /// A disabled action emits no event and produces no activation feedback. It
  /// stays readable and announces its state, and should explain why it is
  /// unavailable through [IuxActionSemantics.unavailabilityReason] — an
  /// unexplained absence is worse than a visible obstacle.
  disabled,
}

/// Where the action is in its lifecycle.
///
/// Owned by the parent. A component never infers that an operation finished.
enum IuxActionOperation {
  /// Not running.
  idle,

  /// Running.
  inProgress,

  /// Finished successfully.
  succeeded,

  /// Finished unsuccessfully.
  failed,
}

/// How hard the action is to undo.
///
/// Informs patterns; it triggers no UI by itself. Reversibility and intent are
/// independent: archiving is destructive and reversible, sending a message is
/// not destructive and is irreversible.
enum IuxActionReversibility {
  /// The user can easily go back.
  reversible,

  /// Going back is possible but costly, indirect or delayed.
  difficultToReverse,

  /// No reasonable way back exists.
  irreversible,
}

/// How an action asks the user to confirm.
///
/// Sealed so a component can exhaustively handle the policies that exist, and
/// so adding one is a deliberate, reviewable change. Every member here is
/// honoured by something; a member that is not honoured is a promise of safety
/// the user does not receive, which is why two of them were removed.
///
/// Destructive does not imply confirmation. A confirmation on every delete
/// trains users to dismiss confirmations, which is how the one that mattered
/// gets dismissed too. Weigh reversibility instead.
@immutable
sealed class IuxConfirmationPolicy {
  /// Creates a policy.
  const IuxConfirmationPolicy();

  /// The action runs on activation.
  static const IuxConfirmationPolicy none = IuxNoConfirmation();
}

/// The action runs immediately when activated.
@immutable
final class IuxNoConfirmation extends IuxConfirmationPolicy {
  /// Creates the policy.
  const IuxNoConfirmation();

  @override
  bool operator ==(Object other) => other is IuxNoConfirmation;

  @override
  int get hashCode => (IuxNoConfirmation).hashCode;
}

/// The user must confirm before the action runs.
///
/// How the confirmation is presented is the pattern's decision, not this
/// model's. Nothing here imposes a dialog.
@immutable
final class IuxConfirmBeforeExecution extends IuxConfirmationPolicy {
  /// Creates the policy.
  const IuxConfirmBeforeExecution();

  @override
  bool operator ==(Object other) => other is IuxConfirmBeforeExecution;

  @override
  int get hashCode => (IuxConfirmBeforeExecution).hashCode;
}

// There is no `IuxConfirmByHold` and no `IuxConfirmByDoubleActivation`. Both
// were exported, documented and constructible, and honoured by *nothing* —
// measured: `IuxButton` with `confirmation: IuxConfirmByHold()` ran
// `onActivate` on the first ordinary tap, and the one type in the package that
// evaluates a policy at all, `IuxDestructiveActionController`, asserted against
// both. Half of a sealed safety type was a way to state a precaution and
// receive none. On an action worth confirming that is not a missing feature,
// it is the failure mode PROJECT_PROMPT §5 puts first (IUX-API-DEAD-001).
//
// Implementing them was refused rather than deferred, on the grounds the
// destructive pattern had already written down. Hold-to-confirm is invisible
// to a screen-reader user unless it is announced and is hard to perform with
// tremor or limited dexterity, so it may never be the *only* route to an
// action — and a single control has no second route to itself to offer.
// Double activation arms a control in place, which needs either a disarm
// timeout the user has to beat or a visible way back, and one button has
// nowhere to put either; arming also changes what a control does without
// announcing it, which is what WCAG 2.2 SC 3.2.2 is about. Both need a pattern
// that owns more of the screen than a button does. When one exists it can
// re-add the member it implements, which is the reviewable change this sealed
// type was designed to make deliberate.
//
// Removed rather than left in place with an assertion: an API whose entire
// behaviour is to throw is not an API.

/// What happens when an action is activated again while already running.
///
/// There is no `debounce` or `throttle`. Both need a duration, which does not
/// belong in an enum, and both are timing mechanics rather than a statement of
/// intent. An application that needs them owns the timer.
enum IuxActionRepeatPolicy {
  /// Every activation is delivered.
  allow,

  /// Activations during [IuxActionOperation.inProgress] are dropped.
  ///
  /// The right default for anything asynchronous: it is what prevents a
  /// double-tapped "Pay" from charging twice.
  ignoreWhileInProgress,
}

/// Whether a running action can be stopped.
enum IuxActionCancellation {
  /// Once started, it runs to completion.
  notSupported,

  /// The user may stop it.
  supported,

  /// The user must be offered a way to stop it.
  ///
  /// For long operations, where no exit is a trap.
  required,
}

/// The text an action exposes to assistive technology.
///
/// Every string arrives already localised from the caller. The model composes
/// no user-facing text, so it cannot leak one language into another.
@immutable
final class IuxActionSemantics {
  /// Creates the semantic description of an action.
  const IuxActionSemantics({
    required this.label,
    this.hint,
    this.unavailabilityReason,
  }) : assert(label.length > 0, 'An action must have an accessible name.');

  /// The accessible name. Required: an unnamed action cannot be used with a
  /// screen reader, so there is no valid default.
  final String label;

  /// What activating this does, when the label alone is ambiguous.
  final String? hint;

  /// Why the action is unavailable.
  ///
  /// Only meaningful when availability is
  /// [IuxActionAvailability.disabled]. A control that is greyed with no
  /// explanation leaves the user unable to tell whether they did something
  /// wrong or the feature does not apply.
  final String? unavailabilityReason;

  /// Returns a copy with the given values replaced.
  IuxActionSemantics copyWith({
    String? label,
    String? hint,
    String? unavailabilityReason,
  }) =>
      IuxActionSemantics(
        label: label ?? this.label,
        hint: hint ?? this.hint,
        unavailabilityReason: unavailabilityReason ?? this.unavailabilityReason,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxActionSemantics &&
          other.label == label &&
          other.hint == hint &&
          other.unavailabilityReason == unavailabilityReason;

  @override
  int get hashCode => Object.hash(label, hint, unavailabilityReason);
}
