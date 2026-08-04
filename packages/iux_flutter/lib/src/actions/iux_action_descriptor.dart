import 'package:flutter/foundation.dart';

import 'iux_action_model.dart';

/// Everything a component needs to know about an action, and nothing about how
/// to draw it.
///
/// One immutable object rather than a dozen parameters, so a component takes a
/// single argument and an incoherent combination is caught in one place.
///
/// The common case stays short:
///
/// ```dart
/// const action = IuxActionDescriptor(
///   semantics: IuxActionSemantics(label: 'Save'),
///   role: IuxActionRole.submit,
/// );
/// ```
///
/// Only [semantics] is required — an action without an accessible name cannot
/// be used with a screen reader, so there is no sensible default for it. Every
/// other dimension defaults to the safest value.
@immutable
final class IuxActionDescriptor {
  /// Creates an action descriptor.
  ///
  /// Invalid combinations fail on an assertion in debug rather than being
  /// silently corrected: quietly repairing a contradiction hides the fact that
  /// the caller believed something untrue.
  const IuxActionDescriptor({
    required this.semantics,
    this.intent = IuxActionIntent.secondary,
    this.importance = IuxActionImportance.medium,
    this.role = IuxActionRole.custom,
    this.availability = IuxActionAvailability.enabled,
    this.operation = IuxActionOperation.idle,
    this.reversibility = IuxActionReversibility.reversible,
    this.confirmation = IuxConfirmationPolicy.none,
    this.repeatPolicy = IuxActionRepeatPolicy.ignoreWhileInProgress,
    this.cancellation = IuxActionCancellation.notSupported,
  })  : assert(
          !(availability == IuxActionAvailability.disabled &&
              operation == IuxActionOperation.inProgress),
          'A disabled action cannot be in progress: an action that cannot be '
          'started cannot be running. Enable it while it runs, or model the '
          'busy state with operation alone.',
        ),
        // There was an assertion here that a hold-to-confirm action could not
        // also be disabled. It went with `IuxConfirmByHold`, which nothing
        // honoured — see iux_action_model.dart. The rule it stated is covered
        // anyway: `IuxActionPolicy.evaluate` blocks a disabled action before
        // it ever looks at a confirmation.
        assert(
          !(role == IuxActionRole.undo &&
              reversibility == IuxActionReversibility.irreversible),
          'An undo action cannot be irreversible: undoing is a reversal by '
          'definition. If the reversal itself cannot be undone, model that on '
          'the original action.',
        );

  /// A prominent primary action.
  const IuxActionDescriptor.primary({
    required IuxActionSemantics semantics,
    IuxActionRole role = IuxActionRole.submit,
    IuxActionAvailability availability = IuxActionAvailability.enabled,
    IuxActionOperation operation = IuxActionOperation.idle,
  }) : this(
          semantics: semantics,
          intent: IuxActionIntent.primary,
          importance: IuxActionImportance.high,
          role: role,
          availability: availability,
          operation: operation,
        );

  /// A destructive action.
  ///
  /// Defaults to irreversible and to confirmation before execution, because
  /// that is the safe reading when the caller has not said otherwise. Both are
  /// overridable: archiving is destructive and reversible, and confirming
  /// every deletion trains users to dismiss confirmations.
  ///
  /// Because of that default, this is the shortest path anybody can write for a
  /// deletion — which is why it is also where the confirmation rule bites.
  /// Something has to honour the policy: hand this descriptor to an
  /// `IuxDestructiveActionController`, which presents the question, or to an
  /// `IuxDialog` choice, which *is* one. A plain `IuxButton` refuses it rather
  /// than deleting unasked. See [IuxConfirmationPolicy].
  ///
  /// Its importance is [IuxActionImportance.high] — not because deleting
  /// things is desirable, but because importance now chooses the container an
  /// action is drawn in, and a control that destroys data must be identifiable
  /// as a control (WCAG 2.2 SC 1.4.11). A caller who wants a quiet deletion
  /// says so on the plain constructor.
  const IuxActionDescriptor.destructive({
    required IuxActionSemantics semantics,
    IuxActionRole role = IuxActionRole.delete,
    IuxActionReversibility reversibility = IuxActionReversibility.irreversible,
    IuxConfirmationPolicy confirmation = const IuxConfirmBeforeExecution(),
    IuxActionAvailability availability = IuxActionAvailability.enabled,
    IuxActionOperation operation = IuxActionOperation.idle,
  }) : this(
          semantics: semantics,
          intent: IuxActionIntent.destructive,
          importance: IuxActionImportance.high,
          role: role,
          availability: availability,
          operation: operation,
          reversibility: reversibility,
          confirmation: confirmation,
        );

  /// What the action means.
  final IuxActionIntent intent;

  /// Its priority relative to its siblings.
  final IuxActionImportance importance;

  /// What it does in the flow.
  final IuxActionRole role;

  /// Whether it can currently be activated.
  final IuxActionAvailability availability;

  /// Where it is in its lifecycle.
  final IuxActionOperation operation;

  /// How hard it is to undo.
  final IuxActionReversibility reversibility;

  /// How it asks the user to confirm.
  final IuxConfirmationPolicy confirmation;

  /// What a repeat activation does.
  final IuxActionRepeatPolicy repeatPolicy;

  /// Whether a running action can be stopped.
  final IuxActionCancellation cancellation;

  /// What it exposes to assistive technology.
  final IuxActionSemantics semantics;

  /// Whether activating the action right now would do anything.
  ///
  /// A component checks this rather than assembling the rule itself, so the
  /// answer cannot differ between two components.
  bool get isActivatable {
    if (availability == IuxActionAvailability.disabled) return false;
    if (repeatPolicy == IuxActionRepeatPolicy.ignoreWhileInProgress &&
        operation == IuxActionOperation.inProgress) {
      return false;
    }
    return true;
  }

  /// Whether the action is currently running.
  bool get isBusy => operation == IuxActionOperation.inProgress;

  /// Whether activation must be confirmed before the action runs.
  bool get requiresConfirmation => confirmation is! IuxNoConfirmation;

  /// Whether the consequence warrants extra care in a pattern.
  ///
  /// True for anything that cannot be casually undone, whatever its intent —
  /// sending a message is not destructive but is irreversible.
  bool get hasSeriousConsequence =>
      reversibility != IuxActionReversibility.reversible;

  /// Returns a copy with the given values replaced.
  IuxActionDescriptor copyWith({
    IuxActionIntent? intent,
    IuxActionImportance? importance,
    IuxActionRole? role,
    IuxActionAvailability? availability,
    IuxActionOperation? operation,
    IuxActionReversibility? reversibility,
    IuxConfirmationPolicy? confirmation,
    IuxActionRepeatPolicy? repeatPolicy,
    IuxActionCancellation? cancellation,
    IuxActionSemantics? semantics,
  }) =>
      IuxActionDescriptor(
        intent: intent ?? this.intent,
        importance: importance ?? this.importance,
        role: role ?? this.role,
        availability: availability ?? this.availability,
        operation: operation ?? this.operation,
        reversibility: reversibility ?? this.reversibility,
        confirmation: confirmation ?? this.confirmation,
        repeatPolicy: repeatPolicy ?? this.repeatPolicy,
        cancellation: cancellation ?? this.cancellation,
        semantics: semantics ?? this.semantics,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxActionDescriptor &&
          other.intent == intent &&
          other.importance == importance &&
          other.role == role &&
          other.availability == availability &&
          other.operation == operation &&
          other.reversibility == reversibility &&
          other.confirmation == confirmation &&
          other.repeatPolicy == repeatPolicy &&
          other.cancellation == cancellation &&
          other.semantics == semantics;

  @override
  int get hashCode => Object.hash(
        intent,
        importance,
        role,
        availability,
        operation,
        reversibility,
        confirmation,
        repeatPolicy,
        cancellation,
        semantics,
      );

  @override
  String toString() => 'IuxActionDescriptor(${semantics.label}, '
      '${intent.name}, ${role.name}, ${availability.name}, '
      '${operation.name})';
}

/// Why an activation did not run.
///
/// Returned rather than swallowed, so a component can explain the refusal
/// instead of appearing broken — a control that does nothing when tapped is
/// indistinguishable from one that is failing.
enum IuxActionBlockedReason {
  /// The action is unavailable.
  unavailable,

  /// It is already running and its repeat policy drops repeats.
  alreadyInProgress,

  /// It needs confirmation that has not been given.
  awaitingConfirmation,
}

/// What an attempted activation produced.
@immutable
final class IuxActionOutcome {
  /// The activation was accepted.
  const IuxActionOutcome.accepted() : blockedReason = null;

  /// The activation was refused, for [blockedReason].
  const IuxActionOutcome.blocked(this.blockedReason);

  /// Why it was refused, or null when it was accepted.
  final IuxActionBlockedReason? blockedReason;

  /// Whether the activation went through.
  bool get isAccepted => blockedReason == null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxActionOutcome && other.blockedReason == blockedReason;

  @override
  int get hashCode => blockedReason.hashCode;

  @override
  String toString() => isAccepted
      ? 'IuxActionOutcome.accepted()'
      : 'IuxActionOutcome.blocked(${blockedReason!.name})';
}

/// Decides whether an activation may proceed.
///
/// One implementation of the rule, so two components cannot disagree about
/// whether a busy action accepts a second tap.
abstract final class IuxActionPolicy {
  /// Evaluates an activation attempt against [descriptor].
  ///
  /// [confirmed] states whether the confirmation this action requires has
  /// already been obtained. The policy does not obtain it: presenting a
  /// confirmation is a pattern's job.
  static IuxActionOutcome evaluate(
    IuxActionDescriptor descriptor, {
    bool confirmed = false,
  }) {
    if (descriptor.availability == IuxActionAvailability.disabled) {
      return const IuxActionOutcome.blocked(
        IuxActionBlockedReason.unavailable,
      );
    }
    if (descriptor.repeatPolicy ==
            IuxActionRepeatPolicy.ignoreWhileInProgress &&
        descriptor.operation == IuxActionOperation.inProgress) {
      return const IuxActionOutcome.blocked(
        IuxActionBlockedReason.alreadyInProgress,
      );
    }
    if (descriptor.requiresConfirmation && !confirmed) {
      return const IuxActionOutcome.blocked(
        IuxActionBlockedReason.awaitingConfirmation,
      );
    }
    return const IuxActionOutcome.accepted();
  }
}
