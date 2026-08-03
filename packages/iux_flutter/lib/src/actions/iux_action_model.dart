import 'package:flutter/foundation.dart';

/// What an action means in its context.
///
/// Intent drives appearance. It is deliberately separate from
/// [IuxActionImportance], which drives priority: a destructive action can be
/// low priority, and a secondary action can be the most important one on a
/// screen.
///
/// There is no `neutral`. A role that resolves to nothing distinguishable is a
/// name for nothing, and [tertiary] already covers low emphasis.
enum IuxActionIntent {
  /// The single most important action of a context.
  ///
  /// One dominant primary action per logical group. "Primary" describes this
  /// screen, not the application: a rarely used screen still has one.
  ///
  /// Never use it on a destructive action merely to draw attention.
  primary,

  /// An important action that is not the dominant one.
  secondary,

  /// A low-emphasis action.
  tertiary,

  /// An action that deletes, alters or revokes data, state or access.
  ///
  /// Its consequence is carried by wording, confirmation and semantics —
  /// never by colour alone.
  destructive,
}

/// How much priority an action has relative to its siblings.
///
/// Orthogonal to intent. A destructive action may be low importance
/// ("Clear filters"); a secondary action may be high ("Save draft" on a form
/// the user has been filling for ten minutes).
enum IuxActionImportance {
  /// Prominent. The user is expected to reach for it.
  high,

  /// Available without competing for attention.
  medium,

  /// Present for those who need it.
  low,
}

/// What the action does in the flow.
///
/// Used for semantics, feedback and pattern selection. Deliberately finite:
/// an open-ended list becomes a taxonomy nobody agrees on. Business meanings
/// belong to the application, not here.
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
/// so adding one is a deliberate, reviewable change.
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

/// The user must hold the control to commit.
///
/// Deliberate by construction, and it avoids a second screen. But it is
/// invisible to a screen-reader user unless announced, and it is hard for
/// users with tremor or limited dexterity — so it must never be the only way
/// to perform an action.
@immutable
final class IuxConfirmByHold extends IuxConfirmationPolicy {
  /// Creates the policy.
  const IuxConfirmByHold();

  @override
  bool operator ==(Object other) => other is IuxConfirmByHold;

  @override
  int get hashCode => (IuxConfirmByHold).hashCode;
}

/// The user must activate twice, the first activation arming the action.
@immutable
final class IuxConfirmByDoubleActivation extends IuxConfirmationPolicy {
  /// Creates the policy.
  const IuxConfirmByDoubleActivation();

  @override
  bool operator ==(Object other) => other is IuxConfirmByDoubleActivation;

  @override
  int get hashCode => (IuxConfirmByDoubleActivation).hashCode;
}

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
