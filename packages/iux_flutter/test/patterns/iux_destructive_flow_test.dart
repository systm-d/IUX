import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';
// `lib/iux_flutter.dart`; once these two files are exported there, both lines
// below collapse into the import above with no other change to this file.

/// The action's accessible name, fuller than the word on the button.
const IuxActionSemantics _semantics = IuxActionSemantics(
  label: 'Archive the March invoice',
);

/// The name announced for a deletion nobody can enumerate.
const IuxActionSemantics _accountSemantics = IuxActionSemantics(
  label: 'Delete your account',
);

const IuxConfirmationPrompt _prompt = IuxConfirmationPrompt(
  title: 'Delete your account?',
  consequence:
      'Your invoices, your uploads and the people you shared them with go '
      'with it. Nothing here brings them back.',
  confirmLabel: 'Delete the account',
  keepLabel: 'Keep my account',
);

/// A long notice, to prove the way back survives a sentence that wraps.
const String _longNotice =
    'The March invoice, every version of it kept for the last ninety days and '
    'the comments recorded against it, are archived and no longer listed with '
    'the invoices for this quarter.';

/// What the host page and the assertions share.
///
/// The parent owns the page, both layers and the controller, which is the
/// point of the pattern: the test plays the parent so the assertions can check
/// that nothing is decided behind its back.
class _Host {
  _Host(this.controller);

  final IuxDestructiveFlowController controller;
  int destroyed = 0;
  int restored = 0;
  final FocusNode elsewhere = FocusNode(debugLabel: 'elsewhere');
}

void main() {
  late int destroyed;
  late int restored;

  setUp(() {
    destroyed = 0;
    restored = 0;
  });

  IuxUndoOffer undoOffer({String notice = 'Invoice archived'}) => IuxUndoOffer(
        notice: notice,
        undoLabel: 'Undo',
        undoSemanticLabel: 'Undo archiving the March invoice',
        dismissLabel: 'Dismiss the archived-invoice notice',
        onUndo: () => restored++,
      );

  IuxDestructiveFlowController flowFor({
    IuxDestructiveScope scope = IuxDestructiveScope.items,
    IuxWayBack? wayBack,
    IuxConfirmationPrompt? prompt,
    IuxActionSemantics semantics = _semantics,
    IuxActionAvailability availability = IuxActionAvailability.enabled,
    IuxActionOperation operation = IuxActionOperation.idle,
  }) {
    final IuxDestructiveFlowController controller =
        IuxDestructiveFlowController(
      semantics: semantics,
      scope: scope,
      wayBack: wayBack ?? undoOffer(),
      prompt: prompt,
      availability: availability,
      operation: operation,
      onDestroy: () => destroyed++,
    );
    addTearDown(controller.dispose);
    return controller;
  }

  group('proportionality, which is the decision this pattern exists to make',
      () {
    test('a loss the user chose and can take back interrupts nobody', () {
      // The shortest thing this API can express, and deliberately so: the
      // safeguard that costs nothing until somebody actually errs.
      final IuxDestructiveFlowController flow = flowFor();

      expect(flow.asksFirst, isFalse);
      expect(flow.dialog, isNull);
    });

    test('a loss nothing here reverses is put to the user first', () {
      final IuxDestructiveFlowController flow = flowFor(
        wayBack: const IuxNoWayBack(),
        prompt: _prompt,
      );

      expect(flow.asksFirst, isTrue);
    });

    test('the way back alone decides, and says so about itself', () {
      // The switch between the two safeguards is a property of the type, so no
      // call site can claim both or neither.
      expect(undoOffer().replacesConfirmation, isTrue);
      expect(const IuxNoWayBack().replacesConfirmation, isFalse);
    });

    test('an undo offer is refused for a loss nobody can enumerate', () {
      // The mission's own example: one draft and one account are not the same
      // event, and the difference is whether the user could list what goes.
      expect(
        () => IuxDestructiveFlowController(
          semantics: _accountSemantics,
          scope: IuxDestructiveScope.everything,
          wayBack: undoOffer(),
          onDestroy: () {},
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('the same account deletion is accepted once it asks first', () {
      final IuxDestructiveFlowController flow = flowFor(
        semantics: _accountSemantics,
        scope: IuxDestructiveScope.everything,
        wayBack: const IuxNoWayBack(),
        prompt: _prompt,
      );

      expect(flow.asksFirst, isTrue);
    });

    test('a flow cannot both ask and offer a way back', () {
      // Wording that is never shown reads at the call site as though the user
      // were being warned, and the deletion runs on the first tap.
      expect(
        () => IuxDestructiveFlowController(
          semantics: _semantics,
          scope: IuxDestructiveScope.items,
          wayBack: undoOffer(),
          prompt: _prompt,
          onDestroy: () {},
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('a flow cannot ask with no wording to ask with', () {
      expect(
        () => IuxDestructiveFlowController(
          semantics: _semantics,
          scope: IuxDestructiveScope.items,
          wayBack: const IuxNoWayBack(),
          onDestroy: () {},
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    group('an offer the user could not act on is refused', () {
      void refuses(String description, VoidCallback build) {
        test(description, () => expect(build, throwsA(isA<AssertionError>())));
      }

      refuses(
        'a notice with nothing in it, which announces an empty live region',
        () => IuxUndoOffer(
          notice: '',
          undoLabel: 'Undo',
          dismissLabel: 'Dismiss',
          onUndo: () {},
        ),
      );

      refuses(
        'an unlabelled way back, which is the control the user needs most',
        () => IuxUndoOffer(
          notice: 'Invoice archived',
          undoLabel: '',
          dismissLabel: 'Dismiss',
          onUndo: () {},
        ),
      );

      refuses(
        'an unnamed dismissal, which reaches a screen reader as "button"',
        () => IuxUndoOffer(
          notice: 'Invoice archived',
          undoLabel: 'Undo',
          dismissLabel: '',
          onUndo: () {},
        ),
      );

      refuses(
        'an empty announced name, which would replace the visible one with '
        'nothing',
        () => IuxUndoOffer(
          notice: 'Invoice archived',
          undoLabel: 'Undo',
          dismissLabel: 'Dismiss',
          undoSemanticLabel: '',
          onUndo: () {},
        ),
      );
    });

    test('an undo offer says the same as another with the same words', () {
      // Value semantics, so a parent rebuilding from an immutable model does
      // not produce a different offer every frame.
      void undo() {}
      const String notice = 'Invoice archived';
      expect(
        IuxUndoOffer(
          notice: notice,
          undoLabel: 'Undo',
          dismissLabel: 'Dismiss',
          onUndo: undo,
        ),
        equals(IuxUndoOffer(
          notice: notice,
          undoLabel: 'Undo',
          dismissLabel: 'Dismiss',
          onUndo: undo,
        )),
      );
      expect(const IuxNoWayBack(), equals(const IuxNoWayBack()));
    });
  });

  group('the flow, driven by the parent', () {
    test('a flow that offers a way back runs on the first activation', () {
      final IuxDestructiveFlowController flow = flowFor();

      final IuxActionOutcome outcome = flow.activate();

      expect(outcome.isAccepted, isTrue);
      expect(destroyed, 1);
      expect(flow.dialog, isNull, reason: 'nobody was asked anything');
      expect(flow.notice, isNotNull, reason: 'and the way back is on offer');
    });

    test('the notice states what happened and carries the way back', () {
      final IuxDestructiveFlowController flow = flowFor();
      flow.activate();

      final IuxTransientMessage notice = flow.notice!;
      expect(notice.text, 'Invoice archived');
      expect(notice.dismissLabel, 'Dismiss the archived-invoice notice');
      expect(notice.action, isNotNull);
      expect(notice.action!.label, 'Undo');
      expect(
        notice.action!.effectiveSemanticLabel,
        'Undo archiving the March invoice',
        reason: 'a bare "Undo" tells a user who swiped onto it nothing',
      );
      expect(
        notice.tone,
        IuxTransientTone.neutral,
        reason: 'a deletion is a fact, not an achievement to be tinted',
      );
    });

    test('nothing is on offer before the deletion has happened', () {
      expect(flowFor().notice, isNull);
    });

    test('a flow that asks first runs nothing on activation', () {
      final IuxDestructiveFlowController flow = flowFor(
        wayBack: const IuxNoWayBack(),
        prompt: _prompt,
      );

      final IuxActionOutcome outcome = flow.activate();

      expect(
          outcome.blockedReason, IuxActionBlockedReason.awaitingConfirmation);
      expect(destroyed, 0);
      expect(flow.isConfirming, isTrue);
      expect(flow.dialog, isNotNull);
      expect(flow.notice, isNull);
    });

    test('confirming runs the deletion once and offers nothing afterwards', () {
      final IuxDestructiveFlowController flow = flowFor(
        wayBack: const IuxNoWayBack(),
        prompt: _prompt,
      );
      flow.activate();

      flow.confirm();

      expect(destroyed, 1);
      expect(flow.isConfirming, isFalse);
      expect(flow.dialog, isNull);
      expect(
        flow.notice,
        isNull,
        reason: 'IuxNoWayBack means there is nothing to put on offer',
      );
    });

    test('leaving the question runs nothing', () {
      final IuxDestructiveFlowController flow = flowFor(
        wayBack: const IuxNoWayBack(),
        prompt: _prompt,
      );
      flow.activate();

      flow.cancel();

      expect(destroyed, 0);
      expect(flow.dialog, isNull);
    });

    test('the way back is taken exactly once and then withdrawn', () {
      final IuxDestructiveFlowController flow = flowFor();
      flow.activate();

      flow.undo();

      expect(restored, 1);
      expect(
        flow.notice,
        isNull,
        reason: 'a control offering to restore what it just restored is a lie',
      );
    });

    test('taking a way back nobody was offered is refused', () {
      final IuxDestructiveFlowController flow = flowFor();

      expect(() => flow.undo(), throwsA(isA<AssertionError>()));
      expect(restored, 0);
    });

    test('dismissing the notice keeps the deletion', () {
      final IuxDestructiveFlowController flow = flowFor();
      flow.activate();

      flow.dismissNotice();

      expect(restored, 0, reason: 'dismissing is not undoing');
      expect(flow.notice, isNull);
      expect(destroyed, 1);
    });

    test('dismissing a notice that has already gone changes nothing', () {
      // The layer may report a dismissal for a notice the parent cleared.
      final IuxDestructiveFlowController flow = flowFor();
      int notifications = 0;
      flow.addListener(() => notifications++);

      flow.dismissNotice();

      expect(notifications, 0);
    });

    test('a second deletion replaces the way back out of the first', () {
      // Measured rather than assumed, because it is a real loss: the transient
      // channel holds one message, so the earlier offer is destroyed. It is
      // documented as a limitation for exactly this reason.
      final IuxDestructiveFlowController flow = flowFor();
      flow.activate();
      flow.activate();

      expect(destroyed, 2);
      flow.undo();
      expect(
        restored,
        1,
        reason: 'one offer outstanding, so one way back, not two',
      );
      expect(flow.notice, isNull);
    });

    test('an unavailable flow neither runs nor asks', () {
      final IuxDestructiveFlowController flow = flowFor(
        availability: IuxActionAvailability.disabled,
      );

      final IuxActionOutcome outcome = flow.activate();

      expect(outcome.blockedReason, IuxActionBlockedReason.unavailable);
      expect(destroyed, 0);
      expect(flow.notice, isNull);
    });

    test('a running flow drops a repeat activation', () {
      final IuxDestructiveFlowController flow = flowFor(
        operation: IuxActionOperation.inProgress,
      );

      final IuxActionOutcome outcome = flow.activate();

      expect(outcome.blockedReason, IuxActionBlockedReason.alreadyInProgress);
      expect(destroyed, 0);
    });

    test('a second activation does not open a second question', () {
      final IuxDestructiveFlowController flow = flowFor(
        wayBack: const IuxNoWayBack(),
        prompt: _prompt,
      );
      int notifications = 0;
      flow.addListener(() => notifications++);

      flow.activate();
      flow.activate();

      expect(notifications, 1);
      expect(flow.isConfirming, isTrue);
    });

    test('the confirming choice does not ask to be confirmed again', () {
      final IuxDestructiveFlowController flow = flowFor(
        wayBack: const IuxNoWayBack(),
        prompt: _prompt,
      );
      flow.activate();

      final IuxDialogAction choice = flow.dialog!.actions.single;

      expect(choice.action.requiresConfirmation, isFalse);
      expect(choice.action.intent, IuxActionIntent.destructive);
      expect(choice.action.semantics.label, _semantics.label);
    });

    test('an update that changes nothing notifies nobody', () {
      final IuxDestructiveFlowController flow = flowFor();
      int notifications = 0;
      flow.addListener(() => notifications++);

      flow.update(
        semantics: _semantics,
        scope: IuxDestructiveScope.items,
        wayBack: undoOffer(),
      );

      expect(notifications, 0);
    });

    test('a flow that stops asking closes the question it had open', () {
      final IuxDestructiveFlowController flow = flowFor(
        wayBack: const IuxNoWayBack(),
        prompt: _prompt,
      );
      flow.activate();
      expect(flow.isConfirming, isTrue);

      flow.update(
        semantics: _semantics,
        scope: IuxDestructiveScope.items,
        wayBack: undoOffer(),
      );

      expect(
        flow.isConfirming,
        isFalse,
        reason: 'the confirming choice would otherwise run it immediately, '
            'which is not the question the user was asked',
      );
      expect(flow.asksFirst, isFalse);
      expect(destroyed, 0);
    });

    test('an outstanding way back survives a flow that changed under it', () {
      // The offer belongs to a deletion that already happened. Changing what
      // the trigger will do next says nothing about whether the last one can
      // still be taken back.
      final IuxDestructiveFlowController flow = flowFor();
      flow.activate();

      flow.update(
        semantics: _semantics,
        scope: IuxDestructiveScope.items,
        wayBack: const IuxNoWayBack(),
        prompt: _prompt,
      );

      expect(flow.notice, isNotNull);
      flow.undo();
      expect(restored, 1);
    });

    test('an update is held to the same proportionality as the constructor',
        () {
      final IuxDestructiveFlowController flow = flowFor();

      expect(
        () => flow.update(
          semantics: _accountSemantics,
          scope: IuxDestructiveScope.everything,
          wayBack: undoOffer(),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('an availability that followed the selection reaches the trigger', () {
      final IuxDestructiveFlowController flow = flowFor();

      flow.update(
        semantics: _semantics,
        scope: IuxDestructiveScope.items,
        wayBack: undoOffer(),
        availability: IuxActionAvailability.disabled,
      );

      expect(flow.activate().blockedReason, IuxActionBlockedReason.unavailable);
      expect(destroyed, 0);
    });

    test('disposing a flow that was never used is quiet', () {
      expect(
        () => IuxDestructiveFlowController(
          semantics: _semantics,
          scope: IuxDestructiveScope.items,
          wayBack: const IuxNoWayBack(),
          prompt: _prompt,
          onDestroy: () {},
        ).dispose(),
        returnsNormally,
      );
    });
  });

  group('the control, in a page', () {
    Future<_Host> pump(
      WidgetTester tester, {
      IuxDestructiveScope scope = IuxDestructiveScope.items,
      IuxWayBack? wayBack,
      IuxConfirmationPrompt? prompt,
      IuxActionSemantics semantics = _semantics,
      IuxActionAvailability availability = IuxActionAvailability.enabled,
      IuxThemeConfiguration configuration = const IuxThemeConfiguration(),
      TextDirection direction = TextDirection.ltr,
      double textScale = 1,
      bool accessibleNavigation = false,
      Size size = const Size(400, 800),
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      late final _Host host;
      final IuxDestructiveFlowController controller =
          IuxDestructiveFlowController(
        semantics: semantics,
        scope: scope,
        availability: availability,
        wayBack: wayBack ??
            IuxUndoOffer(
              notice: 'Invoice archived',
              undoLabel: 'Undo',
              undoSemanticLabel: 'Undo archiving the March invoice',
              dismissLabel: 'Dismiss the archived-invoice notice',
              onUndo: () => host.restored++,
            ),
        prompt: prompt,
        onDestroy: () => host.destroyed++,
      );
      host = _Host(controller);
      addTearDown(controller.dispose);
      addTearDown(host.elsewhere.dispose);

      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
            accessibleNavigation: accessibleNavigation,
          ),
          child: MaterialApp(
            theme: IuxTheme.fromConfiguration(configuration),
            home: Directionality(
              textDirection: direction,
              child: Scaffold(
                // Both layers, at page level, exactly as the documentation
                // asks. The pattern puts nothing on screen by itself, which is
                // what keeps layering the application's.
                body: ListenableBuilder(
                  listenable: controller,
                  builder: (BuildContext context, Widget? child) =>
                      IuxModalLayer(
                    dialog: controller.dialog,
                    child: IuxTransientLayer(
                      message: controller.notice,
                      onDismissed: controller.dismissNotice,
                      child: IuxPage(
                        child: Column(
                          children: <Widget>[
                            IuxButton(
                              label: 'Elsewhere',
                              action: const IuxActionDescriptor(
                                semantics:
                                    IuxActionSemantics(label: 'Elsewhere'),
                              ),
                              focusNode: host.elsewhere,
                              onActivate: () {},
                            ),
                            IuxDestructiveFlow(
                              label: 'Archive',
                              controller: controller,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return host;
    }

    testWidgets('a flow that offers a way back runs on the first tap',
        (WidgetTester tester) async {
      final _Host host = await pump(tester);

      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();

      expect(host.destroyed, 1);
      expect(find.byType(IuxDialog), findsNothing);
      expect(find.text('Invoice archived'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
    });

    testWidgets('the way back does not expire, and there is no clock to lose',
        (WidgetTester tester) async {
      final _Host host = await pump(tester);
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();

      // The rule, read from the timing itself rather than inferred from the
      // widget: a message carrying an action has no dwell at all.
      final BuildContext context = tester.element(find.text('Undo'));
      expect(
        IuxTransientTiming.resolve(context, host.controller.notice!),
        isNull,
      );

      // And the behaviour that follows from it. Sixty seconds is far past any
      // dwell the timing could have derived from thirty characters.
      await tester.pump(const Duration(seconds: 60));
      expect(find.text('Undo'), findsOneWidget);
      expect(host.restored, 0);
    });

    testWidgets('taking the way back restores once and removes the offer',
        (WidgetTester tester) async {
      final _Host host = await pump(tester);
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(host.restored, 1);
      expect(find.text('Undo'), findsNothing);
      expect(find.text('Invoice archived'), findsNothing);
    });

    testWidgets('dismissing the notice keeps the deletion',
        (WidgetTester tester) async {
      final _Host host = await pump(tester);
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.bySemanticsLabel('Dismiss the archived-invoice notice'),
      );
      await tester.pumpAndSettle();

      expect(host.restored, 0);
      expect(host.destroyed, 1);
      expect(find.text('Undo'), findsNothing);
    });

    testWidgets(
        'a flow that asks first states its consequence and runs nothing',
        (WidgetTester tester) async {
      // The symptom of IUX-BUTTON-CONFIRM-001, measured on this pattern: a
      // descriptor asking to be confirmed handed to a plain IuxButton runs on
      // the first tap. This trigger does not, because the flow never publishes
      // the descriptor at all.
      final _Host host = await pump(
        tester,
        scope: IuxDestructiveScope.everything,
        wayBack: const IuxNoWayBack(),
        prompt: _prompt,
        semantics: _accountSemantics,
      );

      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();

      expect(host.destroyed, 0);
      expect(find.byType(IuxDialog), findsOneWidget);
      expect(find.text(_prompt.consequence), findsOneWidget);
      expect(find.text(_prompt.keepLabel), findsOneWidget);
      expect(find.text('Undo'), findsNothing);
    });

    testWidgets('confirming runs it once and offers nothing afterwards',
        (WidgetTester tester) async {
      final _Host host = await pump(
        tester,
        scope: IuxDestructiveScope.everything,
        wayBack: const IuxNoWayBack(),
        prompt: _prompt,
        semantics: _accountSemantics,
      );
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(_prompt.confirmLabel));
      await tester.pumpAndSettle();

      expect(host.destroyed, 1);
      expect(find.byType(IuxDialog), findsNothing);
      expect(find.byType(IuxTransientLayer), findsOneWidget);
      expect(find.text('Undo'), findsNothing);
    });

    testWidgets('the trigger announces the action, not the word on it',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester);

      expect(
        tester.getSemantics(find.bySemanticsLabel(_semantics.label)),
        matchesSemantics(
          label: _semantics.label,
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          hasTapAction: true,
          isFocusable: true,
          hasFocusAction: true,
        ),
      );

      // Measured, and stated here rather than assumed. This used to record the
      // opposite: the announced node carried no isFocusable flag and no focus
      // action, because `IuxSemantics.action` excluded the child semantics in
      // order to control the announced name and took the focusability with it
      // (IUX-A11Y-FOCUS-001, fixed at IUX-038). The comparison against a plain
      // IuxButton beside it is what said this was the library's shape and not
      // this pattern's, so it is kept: it now holds in the other direction.
      expect(
        tester
            .getSemantics(find.bySemanticsLabel(_semantics.label))
            .getSemanticsData()
            .hasAction(SemanticsAction.focus),
        tester
            .getSemantics(find.bySemanticsLabel('Elsewhere'))
            .getSemanticsData()
            .hasAction(SemanticsAction.focus),
      );

      handle.dispose();
    });

    testWidgets('the way back is announced by what it undoes',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester);
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();

      final SemanticsNode undo = tester.getSemantics(
        find.bySemanticsLabel('Undo archiving the March invoice'),
      );

      expect(
        undo.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
        reason: 'a screen-reader double tap must reach the way back',
      );
      expect(
        find.bySemanticsLabel('Undo'),
        findsNothing,
        reason: 'the fuller name replaces the visible one, it does not join it',
      );

      handle.dispose();
    });

    testWidgets('the notice announces itself once, as a live region',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester);
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();

      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Invoice archived'))
            .flagsCollection
            .isLiveRegion,
        isTrue,
      );

      handle.dispose();
    });

    testWidgets(
        'a way back offered to a screen-reader user still has no deadline',
        (WidgetTester tester) async {
      // The failure this pattern is most exposed to: an offer that leaves
      // while the announcement is still queued behind whatever the platform
      // was already speaking.
      final _Host host = await pump(tester, accessibleNavigation: true);
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.text('Undo'));
      expect(
        IuxTransientTiming.resolve(context, host.controller.notice!),
        isNull,
      );

      await tester.pump(const Duration(seconds: 60));
      expect(find.text('Undo'), findsOneWidget);
    });

    testWidgets('an unavailable trigger is announced, not merely greyed',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final _Host host = await pump(
        tester,
        availability: IuxActionAvailability.disabled,
        semantics: const IuxActionSemantics(
          label: 'Archive the March invoice',
          unavailabilityReason: 'Select an invoice first',
        ),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel(_semantics.label)),
        matchesSemantics(
          label: _semantics.label,
          hint: 'Select an invoice first',
          isButton: true,
          isEnabled: false,
          hasEnabledState: true,
          hasTapAction: false,
        ),
      );

      await tester.tap(find.text('Archive'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(host.destroyed, 0);

      handle.dispose();
    });

    testWidgets('the way back survives 200% text on a small screen',
        (WidgetTester tester) async {
      final _Host host = await pump(
        tester,
        textScale: 2,
        size: const Size(320, 640),
      );

      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Undo'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Dismiss the archived-invoice notice'),
        findsOneWidget,
        reason: 'the way out must not be pushed off a small screen',
      );

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(host.restored, 1);
    });

    testWidgets('a long notice wraps rather than being cut short',
        (WidgetTester tester) async {
      await pump(
        tester,
        wayBack: IuxUndoOffer(
          notice: _longNotice,
          undoLabel: 'Undo',
          dismissLabel: 'Dismiss the archived-invoice notice',
          onUndo: () {},
        ),
        textScale: 1.5,
        size: const Size(320, 640),
      );

      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final Text notice = tester.widget<Text>(find.text(_longNotice));
      expect(notice.maxLines, isNull);
      expect(notice.overflow, isNot(TextOverflow.ellipsis));
    });

    testWidgets('right to left changes the layout, not the decision',
        (WidgetTester tester) async {
      final _Host host = await pump(tester, direction: TextDirection.rtl);

      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();
      expect(find.text('Invoice archived'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(host.restored, 1);
    });

    testWidgets('the way back appears with no motion at all',
        (WidgetTester tester) async {
      final _Host host = await pump(
        tester,
        configuration: const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(motion: IuxMotionPreference.none),
        ),
      );

      await tester.tap(find.text('Archive'));
      await tester.pump();

      // One frame, no settle: under IuxMotionPreference.none the entrance is
      // set rather than animated, so the offer is reachable immediately rather
      // than invisible for a frame.
      expect(find.text('Undo'), findsOneWidget);
      expect(host.destroyed, 1);
    });

    testWidgets('high contrast and dark still reach the same decision',
        (WidgetTester tester) async {
      final _Host host = await pump(
        tester,
        configuration: const IuxThemeConfiguration(
          brightness: Brightness.dark,
          profile: IuxAccessibilityProfile(contrast: IuxContrast.high),
        ),
      );

      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(host.restored, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'the trigger does not take focus, and the notice does not '
        'take it away', (WidgetTester tester) async {
      final _Host host = await pump(tester);
      host.elsewhere.requestFocus();
      await tester.pumpAndSettle();
      expect(host.elsewhere.hasFocus, isTrue);

      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();

      expect(
        host.elsewhere.hasFocus,
        isTrue,
        reason: 'moving focus to a notice would strand the keyboard user it '
            'moved, and the notice is not an interruption',
      );
      expect(find.text('Undo'), findsOneWidget);
    });
  });
}
