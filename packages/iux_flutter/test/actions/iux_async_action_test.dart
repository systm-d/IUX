import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';
import 'package:iux_flutter/src/actions/iux_async_action.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const IuxActionSemantics paySemantics = IuxActionSemantics(label: 'Pay');
  const IuxActionDescriptor pay = IuxActionDescriptor.primary(
    semantics: paySemantics,
  );

  /// A controller whose operation completes only when the test says so.
  ///
  /// Deliberate rather than timed: a test that waits on a real duration either
  /// leaks a timer or passes for the wrong reason on a slow machine.
  ({
    IuxAsyncActionController controller,
    Completer<IuxAsyncOutcome> completer,
    List<IuxAsyncActionSignal> signals,
  }) controlled({
    IuxActionDescriptor action = pay,
  }) {
    final Completer<IuxAsyncOutcome> completer = Completer<IuxAsyncOutcome>();
    final List<IuxAsyncActionSignal> signals = <IuxAsyncActionSignal>[];
    final IuxAsyncActionController controller = IuxAsyncActionController(
      action: action,
      operation: (IuxAsyncActionSignal signal) {
        signals.add(signal);
        return completer.future;
      },
    );
    addTearDown(controller.dispose);
    return (controller: controller, completer: completer, signals: signals);
  }

  group('the outcome is reported by the operation, never inferred from it', () {
    test('a completed future is not a success unless the operation says so',
        () async {
      // This is the whole design. A future completing means a Dart function
      // returned; it does not mean the payment went through.
      final IuxAsyncActionController controller = IuxAsyncActionController(
        action: pay,
        operation: (IuxAsyncActionSignal signal) async =>
            const IuxAsyncOutcome.failed(message: 'Card declined'),
      );
      addTearDown(controller.dispose);

      controller.activate();
      await pumpEventQueue();

      expect(controller.value.operation, IuxActionOperation.failed);
      expect(controller.failure?.message, 'Card declined');
    });

    test('a success is reported only when the operation states one', () async {
      final IuxAsyncActionController controller = IuxAsyncActionController(
        action: pay,
        operation: (IuxAsyncActionSignal signal) async =>
            const IuxAsyncOutcome.succeeded(),
      );
      addTearDown(controller.dispose);

      controller.activate();
      await pumpEventQueue();

      expect(controller.value.operation, IuxActionOperation.succeeded);
      expect(controller.failure, isNull);
    });

    test('a thrown error is an observed failure, and carries no wording',
        () async {
      // A throw is unambiguous: the operation did not complete. What the
      // framework must not do is invent a sentence for the user.
      final IuxAsyncActionController controller = IuxAsyncActionController(
        action: pay,
        operation: (IuxAsyncActionSignal signal) async =>
            throw StateError('socket closed'),
      );
      addTearDown(controller.dispose);

      controller.activate();
      await pumpEventQueue();

      expect(controller.value.operation, IuxActionOperation.failed);
      expect(controller.failure!.error, isA<StateError>());
      expect(controller.failure!.isExplained, isFalse);
      expect(controller.failure!.message, isNull);
    });

    test('a failure the caller describes must have something to read', () {
      expect(
        () => IuxAsyncOutcome.failed(message: ''),
        throwsA(isA<AssertionError>()),
      );
    });

    test('the controller refuses a descriptor that already claims a lifecycle',
        () {
      expect(
        () => IuxAsyncActionController(
          action: const IuxActionDescriptor(
            semantics: paySemantics,
            operation: IuxActionOperation.succeeded,
          ),
          operation: (IuxAsyncActionSignal signal) async =>
              const IuxAsyncOutcome.succeeded(),
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('a second activation while running is dropped', () {
    test('the operation runs once for two activations', () async {
      // This is what stops a double-tapped "Pay" charging twice.
      int runs = 0;
      final Completer<IuxAsyncOutcome> completer = Completer<IuxAsyncOutcome>();
      final IuxAsyncActionController controller = IuxAsyncActionController(
        action: pay,
        operation: (IuxAsyncActionSignal signal) {
          runs += 1;
          return completer.future;
        },
      );
      addTearDown(controller.dispose);

      expect(controller.activate().isAccepted, isTrue);
      final IuxActionOutcome second = controller.activate();

      expect(runs, 1);
      expect(second.isAccepted, isFalse);
      expect(second.blockedReason, IuxActionBlockedReason.alreadyInProgress);

      completer.complete(const IuxAsyncOutcome.succeeded());
      await pumpEventQueue();
      expect(runs, 1);
    });

    test('the refusal names its reason rather than doing nothing silently', () {
      // A control that appears inert is indistinguishable from one that is
      // broken.
      final IuxAsyncActionController controller = IuxAsyncActionController(
        action: pay.copyWith(availability: IuxActionAvailability.disabled),
        operation: (IuxAsyncActionSignal signal) async =>
            const IuxAsyncOutcome.succeeded(),
      );
      addTearDown(controller.dispose);

      expect(
        controller.activate().blockedReason,
        IuxActionBlockedReason.unavailable,
      );
    });

    test('an explicit allow policy lets a concurrent run through', () async {
      int runs = 0;
      final IuxAsyncActionController controller = IuxAsyncActionController(
        action: pay.copyWith(repeatPolicy: IuxActionRepeatPolicy.allow),
        operation: (IuxAsyncActionSignal signal) {
          runs += 1;
          return Completer<IuxAsyncOutcome>().future;
        },
      );
      addTearDown(controller.dispose);

      controller.activate();
      controller.activate();

      expect(runs, 2);
      expect(controller.value.generation, 2);
    });

    test('a superseded run cannot report over the one that replaced it',
        () async {
      final List<Completer<IuxAsyncOutcome>> completers =
          <Completer<IuxAsyncOutcome>>[];
      final IuxAsyncActionController controller = IuxAsyncActionController(
        action: pay.copyWith(repeatPolicy: IuxActionRepeatPolicy.allow),
        operation: (IuxAsyncActionSignal signal) {
          final Completer<IuxAsyncOutcome> completer =
              Completer<IuxAsyncOutcome>();
          completers.add(completer);
          return completer.future;
        },
      );
      addTearDown(controller.dispose);

      controller.activate();
      controller.activate();

      completers[1].complete(const IuxAsyncOutcome.succeeded());
      await pumpEventQueue();
      expect(controller.value.operation, IuxActionOperation.succeeded);

      // The slower first run lands last. Showing its answer would show the
      // user the older one.
      completers[0].complete(
        const IuxAsyncOutcome.failed(message: 'Timed out'),
      );
      await pumpEventQueue();
      expect(controller.value.operation, IuxActionOperation.succeeded);
      expect(controller.failure, isNull);
    });
  });

  group('cancellation is honoured as the descriptor declares it', () {
    test('cancelling an action declared notSupported is refused', () {
      final ({
        IuxAsyncActionController controller,
        Completer<IuxAsyncOutcome> completer,
        List<IuxAsyncActionSignal> signals,
      }) fixture = controlled();
      fixture.controller.activate();

      expect(
        fixture.controller.requestCancellation,
        throwsA(isA<AssertionError>()),
      );
      addTearDown(
        () => fixture.completer.complete(const IuxAsyncOutcome.cancelled()),
      );
    });

    test('the request reaches the operation that is running', () {
      final ({
        IuxAsyncActionController controller,
        Completer<IuxAsyncOutcome> completer,
        List<IuxAsyncActionSignal> signals,
      }) fixture = controlled(
        action: pay.copyWith(cancellation: IuxActionCancellation.supported),
      );
      bool aborted = false;

      fixture.controller.activate();
      fixture.signals.single.onCancel(() => aborted = true);

      expect(fixture.controller.requestCancellation(), isTrue);
      expect(aborted, isTrue);
      expect(fixture.signals.single.isCancellationRequested, isTrue);
      expect(fixture.controller.value.cancellationRequested, isTrue);

      fixture.completer.complete(const IuxAsyncOutcome.cancelled());
    });

    test('a listener registered after the request still hears it', () {
      // Otherwise a request sent while the operation was between two awaits is
      // lost, and the user waits for a stop that never comes.
      final ({
        IuxAsyncActionController controller,
        Completer<IuxAsyncOutcome> completer,
        List<IuxAsyncActionSignal> signals,
      }) fixture = controlled(
        action: pay.copyWith(cancellation: IuxActionCancellation.supported),
      );
      fixture.controller.activate();
      fixture.controller.requestCancellation();

      bool aborted = false;
      fixture.signals.single.onCancel(() => aborted = true);
      expect(aborted, isTrue);

      fixture.completer.complete(const IuxAsyncOutcome.cancelled());
    });

    test('a cancelled run returns to idle rather than to failed', () async {
      // Nothing was accomplished and nothing went wrong. Reporting a failure
      // would put a recovery path in front of a user who got what they asked
      // for.
      final ({
        IuxAsyncActionController controller,
        Completer<IuxAsyncOutcome> completer,
        List<IuxAsyncActionSignal> signals,
      }) fixture = controlled(
        action: pay.copyWith(cancellation: IuxActionCancellation.supported),
      );
      fixture.controller.activate();
      fixture.controller.requestCancellation();
      fixture.completer.complete(const IuxAsyncOutcome.cancelled());
      await pumpEventQueue();

      expect(fixture.controller.value.operation, IuxActionOperation.idle);
      expect(fixture.controller.value.cancellationRequested, isFalse);
      expect(fixture.controller.descriptor.isActivatable, isTrue);
    });

    test('an operation that finishes anyway is reported as finishing',
        () async {
      // Cancellation is a request, not a guarantee. Claiming a payment was
      // cancelled when it went through is the one lie a framework must never
      // tell.
      final ({
        IuxAsyncActionController controller,
        Completer<IuxAsyncOutcome> completer,
        List<IuxAsyncActionSignal> signals,
      }) fixture = controlled(
        action: pay.copyWith(cancellation: IuxActionCancellation.required),
      );
      fixture.controller.activate();
      fixture.controller.requestCancellation();
      fixture.completer.complete(const IuxAsyncOutcome.succeeded());
      await pumpEventQueue();

      expect(fixture.controller.value.operation, IuxActionOperation.succeeded);
    });

    test('a repeated request is reported as having changed nothing', () {
      final ({
        IuxAsyncActionController controller,
        Completer<IuxAsyncOutcome> completer,
        List<IuxAsyncActionSignal> signals,
      }) fixture = controlled(
        action: pay.copyWith(cancellation: IuxActionCancellation.supported),
      );
      fixture.controller.activate();

      expect(fixture.controller.requestCancellation(), isTrue);
      expect(fixture.controller.requestCancellation(), isFalse);

      fixture.completer.complete(const IuxAsyncOutcome.cancelled());
    });

    test('cancelling an idle action changes nothing', () {
      final ({
        IuxAsyncActionController controller,
        Completer<IuxAsyncOutcome> completer,
        List<IuxAsyncActionSignal> signals,
      }) fixture = controlled(
        action: pay.copyWith(cancellation: IuxActionCancellation.supported),
      );
      expect(fixture.controller.requestCancellation(), isFalse);
      expect(fixture.controller.value.operation, IuxActionOperation.idle);
    });
  });

  group('the descriptor it publishes stays coherent', () {
    test('it carries the lifecycle the run reported', () async {
      final ({
        IuxAsyncActionController controller,
        Completer<IuxAsyncOutcome> completer,
        List<IuxAsyncActionSignal> signals,
      }) fixture = controlled();

      expect(fixture.controller.descriptor.operation, IuxActionOperation.idle);
      fixture.controller.activate();
      expect(fixture.controller.descriptor.isBusy, isTrue);
      expect(fixture.controller.descriptor.isActivatable, isFalse);

      fixture.completer.complete(const IuxAsyncOutcome.succeeded());
      await pumpEventQueue();
      expect(
        fixture.controller.descriptor.operation,
        IuxActionOperation.succeeded,
      );
    });

    test('it keeps the semantics and intent the parent described', () {
      final ({
        IuxAsyncActionController controller,
        Completer<IuxAsyncOutcome> completer,
        List<IuxAsyncActionSignal> signals,
      }) fixture = controlled();
      fixture.controller.activate();

      expect(fixture.controller.descriptor.semantics, paySemantics);
      expect(fixture.controller.descriptor.intent, IuxActionIntent.primary);

      fixture.completer.complete(const IuxAsyncOutcome.succeeded());
    });

    test('a running action cannot be disabled', () {
      // A control that cannot be started cannot be the one that is running.
      final ({
        IuxAsyncActionController controller,
        Completer<IuxAsyncOutcome> completer,
        List<IuxAsyncActionSignal> signals,
      }) fixture = controlled();
      fixture.controller.activate();

      expect(
        () => fixture.controller.updateAction(
          pay.copyWith(availability: IuxActionAvailability.disabled),
        ),
        throwsA(isA<AssertionError>()),
      );

      fixture.completer.complete(const IuxAsyncOutcome.succeeded());
    });

    test('a replacement descriptor may not claim a lifecycle of its own', () {
      final ({
        IuxAsyncActionController controller,
        Completer<IuxAsyncOutcome> completer,
        List<IuxAsyncActionSignal> signals,
      }) fixture = controlled();

      expect(
        () => fixture.controller.updateAction(
          pay.copyWith(operation: IuxActionOperation.succeeded),
        ),
        throwsA(isA<AssertionError>()),
      );

      fixture.completer.complete(const IuxAsyncOutcome.succeeded());
    });

    test('replacing the description notifies, so a view can follow it', () {
      int notifications = 0;
      final ({
        IuxAsyncActionController controller,
        Completer<IuxAsyncOutcome> completer,
        List<IuxAsyncActionSignal> signals,
      }) fixture = controlled();
      fixture.controller.addListener(() => notifications += 1);

      fixture.controller.updateAction(
        pay.copyWith(availability: IuxActionAvailability.disabled),
      );
      expect(notifications, 1);

      // An identical description is not a change, and a rebuild for nothing is
      // a rebuild that costs a frame.
      fixture.controller.updateAction(
        pay.copyWith(availability: IuxActionAvailability.disabled),
      );
      expect(notifications, 1);
    });
  });

  group('a result nobody is waiting for is discarded', () {
    test('a run that completes after dispose reports nothing', () async {
      final Completer<IuxAsyncOutcome> completer = Completer<IuxAsyncOutcome>();
      final IuxAsyncActionController controller = IuxAsyncActionController(
        action: pay,
        operation: (IuxAsyncActionSignal signal) => completer.future,
      );

      controller.activate();
      controller.dispose();
      completer.complete(const IuxAsyncOutcome.succeeded());
      await pumpEventQueue();

      // No "notifyListeners after dispose", which is the usual way this bug
      // is discovered — in the field.
      expect(true, isTrue);
    });

    test('activating a disposed controller is refused rather than started', () {
      final IuxAsyncActionController controller = IuxAsyncActionController(
        action: pay,
        operation: (IuxAsyncActionSignal signal) async =>
            const IuxAsyncOutcome.succeeded(),
      );
      controller.dispose();

      expect(controller.activate, throwsA(isA<AssertionError>()));
    });
  });

  group('a finished run offers the event the caller composed', () {
    test('the outcome carries the event, and the framework composes none',
        () async {
      const IuxFeedbackEvent event = IuxFeedbackEvent.success(
        semanticMessage: 'Payment taken',
      );
      final IuxAsyncActionController controller = IuxAsyncActionController(
        action: pay,
        operation: (IuxAsyncActionSignal signal) async =>
            const IuxAsyncOutcome.succeeded(feedback: event),
      );
      addTearDown(controller.dispose);

      controller.activate();
      await pumpEventQueue();

      expect(controller.value.feedback, event);
    });

    test('an outcome with no event asks for no feedback at all', () async {
      final IuxAsyncActionController controller = IuxAsyncActionController(
        action: pay,
        operation: (IuxAsyncActionSignal signal) async =>
            const IuxAsyncOutcome.succeeded(),
      );
      addTearDown(controller.dispose);

      controller.activate();
      await pumpEventQueue();

      expect(controller.value.feedback, isNull);
    });

    test('each run gets its own identity, so one result reports once',
        () async {
      final IuxAsyncActionController controller = IuxAsyncActionController(
        action: pay,
        operation: (IuxAsyncActionSignal signal) async =>
            const IuxAsyncOutcome.succeeded(),
      );
      addTearDown(controller.dispose);

      controller.activate();
      await pumpEventQueue();
      final int first = controller.value.generation;

      controller.activate();
      await pumpEventQueue();

      expect(controller.value.generation, greaterThan(first));
    });
  });

  group('the state is a value, not a mutable bag', () {
    test('two identical states are equal', () {
      expect(
        const IuxAsyncActionState(
          operation: IuxActionOperation.inProgress,
          generation: 3,
        ),
        const IuxAsyncActionState(
          operation: IuxActionOperation.inProgress,
          generation: 3,
        ),
      );
    });

    test('a failed state must carry the failure that produced it', () {
      expect(
        () => IuxAsyncActionState(operation: IuxActionOperation.failed),
        throwsA(isA<AssertionError>()),
      );
    });

    test('a state that is not failed must not carry a failure', () {
      expect(
        () => IuxAsyncActionState(
          failure: const IuxAsyncFailure(message: 'stale'),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('only a running operation can have been asked to stop', () {
      expect(
        () => IuxAsyncActionState(cancellationRequested: true),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('reset clears a result without touching a run', () {
    test('an acknowledged failure returns the action to idle', () async {
      final IuxAsyncActionController controller = IuxAsyncActionController(
        action: pay,
        operation: (IuxAsyncActionSignal signal) async =>
            const IuxAsyncOutcome.failed(message: 'Card declined'),
      );
      addTearDown(controller.dispose);

      controller.activate();
      await pumpEventQueue();
      expect(controller.value.hasFailed, isTrue);

      controller.reset();
      expect(controller.value.operation, IuxActionOperation.idle);
      expect(controller.failure, isNull);
    });

    test('it refuses to abandon a run that is still going', () {
      final ({
        IuxAsyncActionController controller,
        Completer<IuxAsyncOutcome> completer,
        List<IuxAsyncActionSignal> signals,
      }) fixture = controlled();
      fixture.controller.activate();

      fixture.controller.reset();
      expect(fixture.controller.value.isRunning, isTrue,
          reason: 'resetting a running action would leave work with nothing '
              'watching it; requestCancellation is the way to stop one');

      fixture.completer.complete(const IuxAsyncOutcome.succeeded());
    });
  });
}
