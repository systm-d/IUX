import 'package:flutter/foundation.dart';

import '../feedback/iux_feedback_event.dart';
import 'iux_action_descriptor.dart';
import 'iux_action_model.dart';

/// What an operation reported about itself when it finished.
///
/// Returned by the operation, never deduced by the framework. This is the
/// whole point of the type: a `Future<void>` that completes normally says only
/// that a Dart function returned, which is not the same as the user's request
/// having been carried out. A save can return having written nothing; a
/// request can come back 500 without throwing. A framework that treated
/// "returned" as "succeeded" would eventually announce a success that did not
/// happen.
///
/// There is therefore no way to register a `Future<void>` and receive a
/// success out of it. The operation states its own result, or it raises.
@immutable
sealed class IuxAsyncOutcome {
  /// Creates an outcome.
  const IuxAsyncOutcome();

  /// The operation states that it did what it was asked to do.
  const factory IuxAsyncOutcome.succeeded({IuxFeedbackEvent? feedback}) =
      IuxAsyncSuccess;

  /// The operation states that it did not.
  const factory IuxAsyncOutcome.failed({
    required String message,
    IuxFeedbackEvent? feedback,
  }) = IuxAsyncFailure;

  /// The operation stopped because it was asked to.
  const factory IuxAsyncOutcome.cancelled() = IuxAsyncCancelled;

  /// The lifecycle value this outcome puts the action into.
  IuxActionOperation get operation;

  /// The event the caller asked to be delivered, or null for none.
  ///
  /// Composed by the caller, already localised. The framework routes it and
  /// composes nothing, so it cannot leak one language into another or claim an
  /// outcome the operation did not claim.
  IuxFeedbackEvent? get feedback;
}

/// The operation completed and says so.
@immutable
final class IuxAsyncSuccess extends IuxAsyncOutcome {
  /// States a success, optionally carrying the event to deliver for it.
  const IuxAsyncSuccess({this.feedback});

  @override
  final IuxFeedbackEvent? feedback;

  @override
  IuxActionOperation get operation => IuxActionOperation.succeeded;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxAsyncSuccess && other.feedback == feedback;

  @override
  int get hashCode => Object.hash(IuxAsyncSuccess, feedback);

  @override
  String toString() => 'IuxAsyncOutcome.succeeded()';
}

/// The operation did not complete.
///
/// [message] is required on the explicit constructor because a failed control
/// that shows only a colour tells a user with a colour vision deficiency
/// nothing at all, and tells everyone else nothing about how to recover.
/// [IuxAsyncFailure.raised] is the one case with no message: an exception is
/// not a sentence anybody can read, and the framework will not invent one.
@immutable
final class IuxAsyncFailure extends IuxAsyncOutcome {
  /// States a failure the operation itself described.
  const IuxAsyncFailure({required String this.message, this.feedback})
      : error = null,
        stackTrace = null,
        assert(
          message.length > 0,
          'A failure must say what went wrong. An empty message leaves the '
          'user a changed colour and no way to recover, and colour alone is '
          'not perceivable by everyone. Pass the localised sentence you would '
          'have shown, or use IuxAsyncFailure.raised for an exception you '
          'have no wording for yet.',
        );

  /// Records an exception the operation threw.
  ///
  /// Produced by [IuxAsyncActionController] when an operation raises. A throw
  /// is an *observed* failure — the operation did not complete — so reporting
  /// it as one infers nothing. What it cannot supply is wording: [message] is
  /// null, and the caller is expected to map [error] to a localised sentence
  /// and re-report it rather than show the user an exception.
  const IuxAsyncFailure.raised(this.error, {this.stackTrace, this.feedback})
      : message = null;

  /// A localised explanation of what went wrong, or null when it was raised.
  final String? message;

  /// The exception, when the operation threw one.
  final Object? error;

  /// Where it was thrown.
  final StackTrace? stackTrace;

  @override
  final IuxFeedbackEvent? feedback;

  @override
  IuxActionOperation get operation => IuxActionOperation.failed;

  /// Whether this failure has something a user can read.
  ///
  /// False means the interface must supply wording of its own; showing an
  /// exception to a user explains nothing and often leaks internals.
  bool get isExplained => message != null && message!.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxAsyncFailure &&
          other.message == message &&
          other.error == error &&
          other.feedback == feedback;

  @override
  int get hashCode => Object.hash(IuxAsyncFailure, message, error, feedback);

  @override
  String toString() =>
      'IuxAsyncOutcome.failed(${message ?? error ?? 'unspecified'})';
}

/// The operation stopped because the user asked it to.
///
/// Neither a success nor a failure: nothing was accomplished and nothing went
/// wrong, so the action returns to [IuxActionOperation.idle] and can be
/// started again. Reporting a cancellation as a failure would put a recovery
/// path in front of a user who already got what they asked for.
@immutable
final class IuxAsyncCancelled extends IuxAsyncOutcome {
  /// States that the operation stopped on request.
  const IuxAsyncCancelled({this.feedback});

  @override
  final IuxFeedbackEvent? feedback;

  @override
  IuxActionOperation get operation => IuxActionOperation.idle;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxAsyncCancelled && other.feedback == feedback;

  @override
  int get hashCode => Object.hash(IuxAsyncCancelled, feedback);

  @override
  String toString() => 'IuxAsyncOutcome.cancelled()';
}

/// How an operation learns that the user asked it to stop.
///
/// Passed to the operation rather than thrown at it, because only the
/// operation knows what stopping means: closing a socket, rolling back, or
/// finishing anyway because the money already moved.
final class IuxAsyncActionSignal {
  IuxAsyncActionSignal._();

  final List<VoidCallback> _listeners = <VoidCallback>[];
  bool _requested = false;

  /// Whether a cancellation has been requested.
  ///
  /// Poll this between steps of a long operation. Ignoring it is legitimate:
  /// see [IuxAsyncActionController.requestCancellation].
  bool get isCancellationRequested => _requested;

  /// Registers [listener], to abort work already in flight.
  ///
  /// Called immediately when cancellation was already requested, so a listener
  /// registered late cannot miss it — a race that would otherwise leave a
  /// request hanging until it timed out.
  void onCancel(VoidCallback listener) {
    if (_requested) {
      listener();
      return;
    }
    _listeners.add(listener);
  }

  void _request() {
    if (_requested) return;
    _requested = true;
    for (final VoidCallback listener in List<VoidCallback>.of(_listeners)) {
      listener();
    }
    _listeners.clear();
  }
}

/// The work an asynchronous action performs.
///
/// It receives a [IuxAsyncActionSignal] and returns what actually happened.
/// The return type is deliberate: see [IuxAsyncOutcome].
typedef IuxAsyncOperation = Future<IuxAsyncOutcome> Function(
  IuxAsyncActionSignal signal,
);

/// The live state of one asynchronous action.
///
/// Immutable, and produced only by [IuxAsyncActionController], so a state that
/// says "succeeded" can only have come from an operation that said so.
@immutable
final class IuxAsyncActionState {
  /// Creates a state.
  const IuxAsyncActionState({
    this.operation = IuxActionOperation.idle,
    this.generation = 0,
    this.failure,
    this.feedback,
    this.cancellationRequested = false,
  })  : assert(
          (operation == IuxActionOperation.failed) == (failure != null),
          'A failed action must carry the failure that produced it, and an '
          'action that is not failed must not carry one. They are read '
          'together, and letting them disagree is how a stale error survives '
          'a successful retry.',
        ),
        assert(
          !(cancellationRequested &&
              operation != IuxActionOperation.inProgress),
          'Only a running operation can have been asked to stop. Clear the '
          'request when the run ends rather than carrying it into the next '
          'one.',
        );

  /// Where the action is in its lifecycle.
  final IuxActionOperation operation;

  /// How many runs have been started, counting from zero.
  ///
  /// Identity for a run, so a result from a superseded one can be discarded
  /// and a completion can be reported exactly once. A widget that delivers
  /// feedback records the generation it delivered for; without that, a rebuild
  /// would vibrate again for an event that already happened.
  final int generation;

  /// Why the last run failed, or null when it did not.
  final IuxAsyncFailure? failure;

  /// The event the finished run asked to be delivered, or null for none.
  final IuxFeedbackEvent? feedback;

  /// Whether the user has asked the running operation to stop.
  ///
  /// A request, not an outcome. The operation stays
  /// [IuxActionOperation.inProgress] until it reports that it actually
  /// stopped.
  final bool cancellationRequested;

  /// Whether the action is running.
  bool get isRunning => operation == IuxActionOperation.inProgress;

  /// Whether the last run failed.
  bool get hasFailed => operation == IuxActionOperation.failed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxAsyncActionState &&
          other.operation == operation &&
          other.generation == generation &&
          other.failure == failure &&
          other.feedback == feedback &&
          other.cancellationRequested == cancellationRequested;

  @override
  int get hashCode => Object.hash(
        operation,
        generation,
        failure,
        feedback,
        cancellationRequested,
      );

  @override
  String toString() => 'IuxAsyncActionState(${operation.name}, '
      'run $generation${cancellationRequested ? ', stopping' : ''})';
}

/// Holds the lifecycle of one asynchronous action, on the parent's behalf.
///
/// **The parent still owns the state.** This controller is created, held and
/// disposed by the parent, and it reports only what the operation told it.
/// What it removes is the bookkeeping every call site otherwise reimplements
/// and half of them get wrong:
///
/// - flipping to [IuxActionOperation.inProgress] before the first `await`, so
///   a slow start is not an unresponsive control;
/// - dropping a repeat activation while running, which is what stops a
///   double-tapped "Pay" charging twice;
/// - discarding a result from a run that was superseded or from a controller
///   that has been disposed, which is the usual source of "setState called
///   after dispose" and of an old error overwriting a fresh success.
///
/// ```dart
/// late final IuxAsyncActionController controller = IuxAsyncActionController(
///   action: const IuxActionDescriptor.primary(
///     semantics: IuxActionSemantics(label: 'Pay'),
///   ),
///   operation: (IuxAsyncActionSignal signal) async {
///     final PaymentResult result = await api.pay();
///     return result.isPaid
///         ? IuxAsyncOutcome.succeeded(
///             feedback: IuxFeedbackEvent.success(
///               semanticMessage: l10n.paymentTaken,
///             ),
///           )
///         : IuxAsyncOutcome.failed(message: l10n.paymentDeclined);
///   },
/// );
/// ```
///
/// Note what the operation must do: decide. `api.pay()` returning is not a
/// success, and nothing here will pretend otherwise.
class IuxAsyncActionController extends ChangeNotifier
    implements ValueListenable<IuxAsyncActionState> {
  /// Creates a controller for [action], running [operation] on activation.
  ///
  /// [action] describes what the action *is* — its intent, its semantics, its
  /// repeat policy, whether it may be cancelled. Its
  /// [IuxActionDescriptor.operation] must be idle: the lifecycle is what this
  /// controller maintains, and two owners of one value is how they drift.
  IuxAsyncActionController({
    required IuxActionDescriptor action,
    required IuxAsyncOperation operation,
  })  : assert(
          action.operation == IuxActionOperation.idle,
          'The descriptor handed to an IuxAsyncActionController must start '
          'idle. This controller maintains the operation value from what the '
          'run reports; a descriptor that already claims one would be '
          'overwritten on the first activation. Remove the operation argument '
          'from the descriptor.',
        ),
        _action = action,
        _operation = operation;

  final IuxAsyncOperation _operation;
  IuxActionDescriptor _action;
  IuxAsyncActionState _state = const IuxAsyncActionState();
  IuxAsyncActionSignal? _signal;
  bool _disposed = false;

  /// What the action is, without its lifecycle.
  IuxActionDescriptor get action => _action;

  /// The descriptor to hand a component, carrying the live lifecycle.
  ///
  /// ```dart
  /// IuxButton(action: controller.descriptor, onActivate: controller.activate)
  /// ```
  IuxActionDescriptor get descriptor =>
      _action.copyWith(operation: _state.operation);

  @override
  IuxAsyncActionState get value => _state;

  /// Whether the operation is running.
  bool get isRunning => _state.isRunning;

  /// Why the last run failed, or null when it did not.
  IuxAsyncFailure? get failure => _state.failure;

  /// Attempts an activation, and says whether it was accepted.
  ///
  /// Returns synchronously: the verdict is knowable now, the result is not.
  /// A blocked attempt names its reason rather than doing nothing, because a
  /// control that appears inert is indistinguishable from one that is broken.
  ///
  /// Confirmation is treated as already given. Presenting a confirmation is a
  /// pattern's job, not a controller's, and the core components make the same
  /// assumption so the two cannot disagree.
  IuxActionOutcome activate() {
    assert(
      !_disposed,
      'This IuxAsyncActionController has been disposed. Activating it would '
      'start work whose result nothing is listening for.',
    );
    if (_disposed) {
      return const IuxActionOutcome.blocked(
        IuxActionBlockedReason.unavailable,
      );
    }

    final IuxActionOutcome verdict = IuxActionPolicy.evaluate(
      descriptor,
      confirmed: true,
    );
    if (!verdict.isAccepted) return verdict;

    final int generation = _state.generation + 1;
    final IuxAsyncActionSignal signal = IuxAsyncActionSignal._();
    _signal = signal;
    _publish(
      IuxAsyncActionState(
        operation: IuxActionOperation.inProgress,
        generation: generation,
      ),
    );
    _run(generation, signal);
    return verdict;
  }

  /// Asks the running operation to stop, and says whether the request was
  /// passed on.
  ///
  /// A request, not a guarantee. If the operation finishes anyway, that
  /// completion is reported: pretending a payment was cancelled when it went
  /// through is the one lie a framework must never tell.
  ///
  /// Returns false when nothing is running, or when the request is already
  /// pending.
  bool requestCancellation() {
    assert(
      _action.cancellation != IuxActionCancellation.notSupported,
      'This action declares IuxActionCancellation.notSupported, so nothing '
      'will listen for the request. Declare it supported — or required, when '
      'the operation is long enough that having no way out is a trap — before '
      'offering the user a way to stop it.',
    );
    if (_disposed) return false;
    if (_action.cancellation == IuxActionCancellation.notSupported)
      return false;
    if (!_state.isRunning || _state.cancellationRequested) return false;

    _publish(
      IuxAsyncActionState(
        operation: _state.operation,
        generation: _state.generation,
        cancellationRequested: true,
      ),
    );
    _signal?._request();
    return true;
  }

  /// Returns the action to idle, clearing any result.
  ///
  /// Use when a result has been acknowledged — the user edited the form again,
  /// the error message was dismissed. It does not stop a running operation;
  /// that is [requestCancellation], and confusing the two would leave work
  /// running with nothing watching it.
  void reset() {
    if (_disposed || _state.isRunning) return;
    _publish(IuxAsyncActionState(generation: _state.generation));
  }

  /// Replaces the description of the action, keeping the lifecycle.
  ///
  /// For a descriptor that depends on something that changes — an availability
  /// that follows form validity, a label that follows the selected row.
  void updateAction(IuxActionDescriptor action) {
    assert(
      action.operation == IuxActionOperation.idle,
      'The lifecycle belongs to the controller. Pass the descriptor without '
      'an operation; the controller applies the one the run reported.',
    );
    assert(
      !(_state.isRunning &&
          action.availability == IuxActionAvailability.disabled),
      'An action cannot be disabled while it is running: a control that '
      'cannot be started cannot be the one that is running, and the descriptor '
      'refuses that combination. Wait for the run to end, or cancel it first.',
    );
    if (_disposed || action == _action) return;
    _action = action;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _signal = null;
    super.dispose();
  }

  Future<void> _run(int generation, IuxAsyncActionSignal signal) async {
    IuxAsyncOutcome outcome;
    try {
      outcome = await _operation(signal);
    } catch (error, stackTrace) {
      // Observed, not inferred: the operation raised, so it did not complete.
      // A normal return is the ambiguous case, and that one the operation has
      // to speak for itself.
      outcome = IuxAsyncFailure.raised(error, stackTrace: stackTrace);
    }

    // A result from a superseded run is dropped rather than applied. Under
    // IuxActionRepeatPolicy.allow two runs can overlap, and letting the slower
    // one land last would show the user the older answer.
    if (_disposed || _state.generation != generation) return;

    _publish(
      IuxAsyncActionState(
        operation: outcome.operation,
        generation: generation,
        failure: outcome is IuxAsyncFailure ? outcome : null,
        feedback: outcome.feedback,
      ),
    );
  }

  void _publish(IuxAsyncActionState state) {
    if (_disposed || state == _state) return;
    _state = state;
    notifyListeners();
  }
}
