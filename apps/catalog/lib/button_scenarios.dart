import 'package:flutter/material.dart';
import 'package:iux_flutter/iux_flutter.dart';

/// The words the button harness uses.
///
/// One place, because the point of the long form is that *every* sample gets
/// longer at once: a harness where only one label grows proves nothing about
/// the row it sits in.
abstract final class ButtonCopy {
  /// A short label, the case every design is drawn for.
  static const String shortLabel = 'Send';

  /// A label of the length a real application in German or Finnish produces.
  ///
  /// Not a stress test for its own sake. A screen laid out in English and
  /// translated afterwards is the normal case, and this is what arrives.
  static const String longLabel = 'Zahlungsbestätigung an den Empfänger senden';

  /// The visible label for the current setting.
  static String label({required bool long}) => long ? longLabel : shortLabel;

  /// The announced name, which may be fuller than the visible one.
  static String announced({required bool long}) =>
      long ? longLabel : 'Send the March invoice';
}

/// What the demonstration operation reports when it finishes.
///
/// The choice is the caller's, which is the whole point of
/// [IuxAsyncOutcome]: a returning future is not a success, so the operation has
/// to say which of these happened.
enum AsyncOutcomeChoice {
  /// The operation states that it did what it was asked to do.
  succeeds,

  /// The operation states that it failed, and supplies wording.
  failsWithMessage,

  /// The operation throws. There is no wording, and nothing can invent one.
  raises,
}

/// Everything the button section owns, so the page above it can own nothing.
///
/// This exists because two of the scenarios need state that outlives a build:
/// an asynchronous action has a lifecycle, and a confirmation has to be handed
/// to an `IuxModalLayer` at page level rather than opened from wherever the
/// button happens to sit. Both are the parent's job in a real application, and
/// the catalog does not get to cheat on that — if the wiring is awkward here,
/// it is awkward everywhere, and that is worth seeing.
class ButtonScenarios extends ChangeNotifier {
  /// Creates the scenario state and its controllers.
  ButtonScenarios() {
    _delete = IuxDestructiveActionController(
      action: const IuxActionDescriptor.destructive(
        semantics: IuxActionSemantics(label: 'Delete the March invoice'),
      ),
      onConfirmed: _recordDeleted,
      prompt: const IuxConfirmationPrompt(
        title: 'Delete the March invoice?',
        consequence: 'The invoice and its three attachments leave this device '
            'and the shared folder. Accounting keeps no copy.',
        confirmLabel: 'Delete the invoice',
        keepLabel: 'Keep the invoice',
      ),
    );
    _delete.addListener(notifyListeners);

    _archive = IuxDestructiveActionController(
      action: const IuxActionDescriptor.destructive(
        semantics: IuxActionSemantics(label: 'Archive the March invoice'),
        // Reversible, so it is not confirmed. The pattern refuses the other
        // combination outright: confirming something the user can undo charges
        // every user a step to prevent a mistake most of them never make.
        reversibility: IuxActionReversibility.reversible,
        confirmation: IuxConfirmationPolicy.none,
        role: IuxActionRole.custom,
      ),
      onConfirmed: _recordArchived,
    );
    _archive.addListener(notifyListeners);

    _async = IuxAsyncActionController(
      action: const IuxActionDescriptor.primary(
        semantics: IuxActionSemantics(label: 'Pay the March invoice'),
      ),
      operation: _runOperation,
    );
    _async.addListener(notifyListeners);
  }

  /// How long the demonstration operation takes.
  ///
  /// Long enough to look at, short enough that nobody waits on it. A real
  /// operation is not a timer, and neither of those numbers is a guideline.
  static const Duration _step = Duration(milliseconds: 100);

  /// How many steps the demonstration operation runs for.
  static const int _steps = 30;

  late final IuxDestructiveActionController _delete;
  late final IuxDestructiveActionController _archive;
  late final IuxAsyncActionController _async;

  AsyncOutcomeChoice _outcome = AsyncOutcomeChoice.succeeds;
  IuxActionCancellation _cancellation = IuxActionCancellation.notSupported;
  IuxActionRepeatPolicy _repeat = IuxActionRepeatPolicy.ignoreWhileInProgress;
  bool _deleted = false;
  bool _archived = false;
  int _unguardedRuns = 0;

  /// The action that asks to be confirmed before it runs.
  IuxDestructiveActionController get delete => _delete;

  /// The action that runs immediately and is taken back with an undo.
  IuxDestructiveActionController get archive => _archive;

  /// The action that takes time.
  IuxAsyncActionController get async => _async;

  /// The confirmation currently open, for the page's `IuxModalLayer`.
  ///
  /// Null when nothing is open. Reading it here rather than opening a dialog
  /// from inside the panel is the shape the pattern requires, and the reason
  /// this class exists at all.
  IuxDialog? get dialog => _delete.dialog;

  /// What the demonstration operation will report next.
  AsyncOutcomeChoice get outcome => _outcome;

  /// Whether the running action offers a way out.
  IuxActionCancellation get cancellation => _cancellation;

  /// What a second activation does while the first is still running.
  IuxActionRepeatPolicy get repeat => _repeat;

  /// Whether the invoice has been deleted in this session.
  bool get deleted => _deleted;

  /// Whether the invoice has been archived in this session.
  bool get archived => _archived;

  /// How many times the unguarded button ran without anybody being asked.
  int get unguardedRuns => _unguardedRuns;

  /// The label of the control that stops the running action, or null when the
  /// action does not support being stopped.
  ///
  /// Null is not a style choice: `IuxAsyncActionButton` refuses a cancel label
  /// for an action declared [IuxActionCancellation.notSupported], because a
  /// control that appears and then does nothing reads as a broken interface.
  String? get cancelLabel =>
      _cancellation == IuxActionCancellation.notSupported ? null : 'Stop';

  /// Chooses what the next run reports.
  void chooseOutcome(AsyncOutcomeChoice value) {
    if (_outcome == value) return;
    _outcome = value;
    notifyListeners();
  }

  /// Chooses whether the running action can be stopped.
  void chooseCancellation(IuxActionCancellation value) {
    if (_cancellation == value || _async.isRunning) return;
    _cancellation = value;
    _applyAsyncAction();
  }

  /// Chooses what a repeat activation does.
  void chooseRepeat(IuxActionRepeatPolicy value) {
    if (_repeat == value || _async.isRunning) return;
    _repeat = value;
    _applyAsyncAction();
  }

  /// Returns the asynchronous action to idle, clearing its last result.
  void resetAsync() => _async.reset();

  /// Runs the action the confirmation was meant to guard, without asking.
  ///
  /// Wired to a plain `IuxButton` holding a descriptor that declares
  /// [IuxConfirmBeforeExecution]. The button evaluates the action with the
  /// confirmation treated as already obtained — which is correct division of
  /// labour and is also the trap the destructive pattern exists to close.
  void runUnguarded() {
    _unguardedRuns++;
    notifyListeners();
  }

  /// Puts the invoice back, and clears every recorded outcome.
  void restore() {
    _deleted = false;
    _archived = false;
    _unguardedRuns = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _delete.removeListener(notifyListeners);
    _archive.removeListener(notifyListeners);
    _async.removeListener(notifyListeners);
    _delete.dispose();
    _archive.dispose();
    _async.dispose();
    super.dispose();
  }

  void _applyAsyncAction() {
    _async.updateAction(
      const IuxActionDescriptor.primary(
        semantics: IuxActionSemantics(label: 'Pay the March invoice'),
      ).copyWith(cancellation: _cancellation, repeatPolicy: _repeat),
    );
    notifyListeners();
  }

  void _recordDeleted() {
    _deleted = true;
    notifyListeners();
  }

  void _recordArchived() {
    _archived = true;
    notifyListeners();
  }

  Future<IuxAsyncOutcome> _runOperation(IuxAsyncActionSignal signal) async {
    for (int tick = 0; tick < _steps; tick++) {
      await Future<void>.delayed(_step);
      // Polled rather than thrown at: only the operation knows what stopping
      // means, and here it means "nothing was written, so nothing failed".
      if (signal.isCancellationRequested) {
        return const IuxAsyncOutcome.cancelled();
      }
    }

    return switch (_outcome) {
      AsyncOutcomeChoice.succeeds => const IuxAsyncOutcome.succeeded(
          feedback: IuxFeedbackEvent.success(
            semanticMessage: 'The March invoice is paid',
          ),
        ),
      AsyncOutcomeChoice.failsWithMessage => const IuxAsyncOutcome.failed(
          message: 'The card was declined. Try another card.',
          // Silenced, because the message below the button is already a live
          // region: without this the same sentence is spoken twice. Note that
          // the role constructors take no `allowAnnouncement`, so saying so
          // means dropping to the unnamed constructor and restating the role.
          feedback: IuxFeedbackEvent(
            role: IuxFeedbackRole.error,
            allowAnnouncement: false,
          ),
        ),
      AsyncOutcomeChoice.raises =>
        throw StateError('the payment gateway did not answer'),
    };
  }
}
