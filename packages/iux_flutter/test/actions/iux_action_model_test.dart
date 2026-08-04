import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

void main() {
  const IuxActionSemantics save = IuxActionSemantics(label: 'Save');

  group('the model separates dimensions that are genuinely independent', () {
    test('intent does not fix importance', () {
      const IuxActionDescriptor quietDelete = IuxActionDescriptor(
        semantics: IuxActionSemantics(label: 'Clear filters'),
        intent: IuxActionIntent.destructive,
        importance: IuxActionImportance.low,
      );
      expect(quietDelete.intent, IuxActionIntent.destructive);
      expect(quietDelete.importance, IuxActionImportance.low);
    });

    test('intent does not fix reversibility', () {
      // Archiving is destructive and reversible; sending a message is neither
      // destructive nor reversible.
      const IuxActionDescriptor archive = IuxActionDescriptor(
        semantics: IuxActionSemantics(label: 'Archive'),
        intent: IuxActionIntent.destructive,
        reversibility: IuxActionReversibility.reversible,
      );
      const IuxActionDescriptor send = IuxActionDescriptor(
        semantics: IuxActionSemantics(label: 'Send'),
        intent: IuxActionIntent.primary,
        reversibility: IuxActionReversibility.irreversible,
      );

      expect(archive.hasSeriousConsequence, isFalse);
      expect(send.hasSeriousConsequence, isTrue);
    });

    test('destructive does not force confirmation', () {
      // A confirmation on every delete trains users to dismiss confirmations.
      const IuxActionDescriptor easy = IuxActionDescriptor.destructive(
        semantics: IuxActionSemantics(label: 'Remove tag'),
        reversibility: IuxActionReversibility.reversible,
        confirmation: IuxNoConfirmation(),
      );
      expect(easy.requiresConfirmation, isFalse);
    });
  });

  group('invariants fail loudly rather than being silently corrected', () {
    test('a disabled action cannot be in progress', () {
      expect(
        () => IuxActionDescriptor(
          semantics: save,
          availability: IuxActionAvailability.disabled,
          operation: IuxActionOperation.inProgress,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    // The assertion that used to sit here — hold-to-confirm on a disabled
    // action — went with `IuxConfirmByHold` in IUX-039. The rule it stated
    // survives without it: a disabled action is blocked by
    // `IuxActionPolicy.evaluate` before any confirmation is considered, which
    // `an unavailable action is blocked whatever else is true` covers.

    test('an undo action cannot be irreversible', () {
      expect(
        () => IuxActionDescriptor(
          semantics: save,
          role: IuxActionRole.undo,
          reversibility: IuxActionReversibility.irreversible,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('an action must have an accessible name', () {
      expect(
        () => IuxActionSemantics(label: ''),
        throwsA(isA<AssertionError>()),
      );
    });

    test('the assertion message says how to fix it', () {
      try {
        IuxActionDescriptor(
          semantics: save,
          availability: IuxActionAvailability.disabled,
          operation: IuxActionOperation.inProgress,
        );
        fail('expected an assertion');
      } on AssertionError catch (error) {
        expect(error.toString(), contains('cannot be running'));
      }
    });
  });

  group('activation policy is decided once, not per component', () {
    test('a disabled action is refused, with a reason', () {
      const IuxActionDescriptor action = IuxActionDescriptor(
        semantics: save,
        availability: IuxActionAvailability.disabled,
      );
      final IuxActionOutcome outcome = IuxActionPolicy.evaluate(action);

      expect(outcome.isAccepted, isFalse);
      expect(outcome.blockedReason, IuxActionBlockedReason.unavailable);
    });

    test('a second activation is dropped while the first runs', () {
      // This is what prevents a double-tapped "Pay" from charging twice.
      const IuxActionDescriptor action = IuxActionDescriptor(
        semantics: save,
        operation: IuxActionOperation.inProgress,
      );
      expect(
        IuxActionPolicy.evaluate(action).blockedReason,
        IuxActionBlockedReason.alreadyInProgress,
      );
      expect(action.isActivatable, isFalse);
    });

    test('an explicit allow policy lets repeats through', () {
      const IuxActionDescriptor action = IuxActionDescriptor(
        semantics: save,
        operation: IuxActionOperation.inProgress,
        repeatPolicy: IuxActionRepeatPolicy.allow,
      );
      expect(IuxActionPolicy.evaluate(action).isAccepted, isTrue);
    });

    test('an unconfirmed action is held, not run', () {
      const IuxActionDescriptor action = IuxActionDescriptor(
        semantics: IuxActionSemantics(label: 'Delete account'),
        confirmation: IuxConfirmBeforeExecution(),
      );
      expect(
        IuxActionPolicy.evaluate(action).blockedReason,
        IuxActionBlockedReason.awaitingConfirmation,
      );
      expect(
        IuxActionPolicy.evaluate(action, confirmed: true).isAccepted,
        isTrue,
      );
    });

    test('unavailability outranks a missing confirmation', () {
      // The user cannot act on it at all, so telling them to confirm would be
      // a lie.
      const IuxActionDescriptor action = IuxActionDescriptor(
        semantics: save,
        availability: IuxActionAvailability.disabled,
        confirmation: IuxConfirmBeforeExecution(),
      );
      expect(
        IuxActionPolicy.evaluate(action).blockedReason,
        IuxActionBlockedReason.unavailable,
      );
    });

    test('a refusal always carries a reason, so nothing fails silently', () {
      for (final IuxActionDescriptor action in <IuxActionDescriptor>[
        const IuxActionDescriptor(
          semantics: save,
          availability: IuxActionAvailability.disabled,
        ),
        const IuxActionDescriptor(
          semantics: save,
          operation: IuxActionOperation.inProgress,
        ),
        const IuxActionDescriptor(
          semantics: save,
          confirmation: IuxConfirmBeforeExecution(),
        ),
      ]) {
        final IuxActionOutcome outcome = IuxActionPolicy.evaluate(action);
        expect(outcome.isAccepted, isFalse);
        expect(outcome.blockedReason, isNotNull);
        expect(outcome.toString(), contains('blocked'));
      }
    });
  });

  group('named constructors express a safe reading', () {
    test('destructive defaults to irreversible and confirmed', () {
      const IuxActionDescriptor action = IuxActionDescriptor.destructive(
        semantics: IuxActionSemantics(label: 'Delete account'),
      );
      expect(action.intent, IuxActionIntent.destructive);
      expect(action.reversibility, IuxActionReversibility.irreversible);
      expect(action.requiresConfirmation, isTrue);
      expect(action.hasSeriousConsequence, isTrue);
    });

    test('primary defaults to submit and high importance', () {
      const IuxActionDescriptor action = IuxActionDescriptor.primary(
        semantics: save,
      );
      expect(action.intent, IuxActionIntent.primary);
      expect(action.role, IuxActionRole.submit);
      expect(action.importance, IuxActionImportance.high);
    });

    test('the default descriptor is the cautious one', () {
      const IuxActionDescriptor action = IuxActionDescriptor(semantics: save);
      expect(action.intent, IuxActionIntent.secondary,
          reason: 'nothing should claim to be primary by accident');
      expect(action.repeatPolicy, IuxActionRepeatPolicy.ignoreWhileInProgress,
          reason: 'the safe default for anything asynchronous');
      expect(action.isActivatable, isTrue);
    });
  });

  group('value semantics', () {
    test('descriptors compare by value', () {
      const IuxActionDescriptor a = IuxActionDescriptor(semantics: save);
      const IuxActionDescriptor b = IuxActionDescriptor(semantics: save);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('confirmation policies compare by value', () {
      expect(const IuxNoConfirmation(), equals(const IuxNoConfirmation()));
      expect(
        const IuxConfirmBeforeExecution(),
        equals(const IuxConfirmBeforeExecution()),
      );
      expect(
        const IuxNoConfirmation(),
        isNot(equals(const IuxConfirmBeforeExecution())),
      );
    });

    test('copyWith reaches every dimension', () {
      const IuxActionDescriptor base = IuxActionDescriptor(semantics: save);
      expect(base.copyWith(intent: IuxActionIntent.primary).intent,
          IuxActionIntent.primary);
      expect(
        base.copyWith(operation: IuxActionOperation.failed).operation,
        IuxActionOperation.failed,
      );
      expect(
        base
            .copyWith(cancellation: IuxActionCancellation.required)
            .cancellation,
        IuxActionCancellation.required,
      );
      expect(base.copyWith(), equals(base));
    });

    test('toString names the action rather than dumping it', () {
      const IuxActionDescriptor action = IuxActionDescriptor(semantics: save);
      expect(action.toString(), contains('Save'));
    });
  });

  group('the model carries no rendering and no business meaning', () {
    test('semantics text is supplied by the caller, never composed', () {
      const IuxActionSemantics semantics = IuxActionSemantics(
        label: 'Supprimer',
        hint: 'Supprime définitivement le compte',
        unavailabilityReason: 'Vous devez être connecté',
      );
      expect(semantics.label, 'Supprimer');
      expect(semantics.unavailabilityReason, isNotNull);
    });

    test('a disabled action can explain itself', () {
      // An unexplained greyed control leaves the user unable to tell whether
      // they did something wrong or the feature does not apply.
      const IuxActionDescriptor action = IuxActionDescriptor(
        semantics: IuxActionSemantics(
          label: 'Publish',
          unavailabilityReason: 'Add a title first',
        ),
        availability: IuxActionAvailability.disabled,
      );
      expect(action.semantics.unavailabilityReason, 'Add a title first');
    });
  });
}
