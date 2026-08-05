import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

/// The action's accessible name, fuller than the word on the button.
const IuxActionSemantics _semantics = IuxActionSemantics(
  label: 'Delete the three selected files',
);

/// An action that asks to be confirmed, which is the model's own default for
/// [IuxActionDescriptor.destructive].
const IuxActionDescriptor _confirming = IuxActionDescriptor.destructive(
  semantics: _semantics,
);

/// An action that runs on the first activation, because it can be undone.
///
/// The shorter of the two, and the one the pattern documents first.
const IuxActionDescriptor _immediate = IuxActionDescriptor.destructive(
  semantics: _semantics,
  reversibility: IuxActionReversibility.reversible,
  confirmation: IuxConfirmationPolicy.none,
);

const IuxConfirmationPrompt _prompt = IuxConfirmationPrompt(
  title: 'Delete 3 files?',
  consequence: 'The files leave this device and the shared folder.',
  confirmLabel: 'Delete',
  keepLabel: 'Keep the files',
);

/// A consequence long enough to prove the confirmation wraps rather than clips.
const String _longConsequence =
    'The three files, every version of them kept for the last ninety days, the '
    'comments recorded against each one and the links shared with people '
    'outside this workspace are removed from this device and from the shared '
    'folder. Nobody in the team will be able to restore them afterwards, and '
    'the exports already scheduled for the end of the month will go out '
    'without them.';

/// What the host page and the assertions share.
///
/// The parent owns the page and the controller, which is the point of the
/// pattern: the test plays the parent so the assertions can check that nothing
/// here is decided behind its back.
class _Host {
  _Host(this.controller);

  final IuxDestructiveActionController controller;
  int runs = 0;
  final FocusNode elsewhere = FocusNode(debugLabel: 'elsewhere');
}

void main() {
  group('the controller, which decides what an activation means', () {
    late int runs;

    IuxDestructiveActionController controllerFor(
      IuxActionDescriptor action, {
      IuxConfirmationPrompt? prompt,
    }) {
      final IuxDestructiveActionController controller =
          IuxDestructiveActionController(
        action: action,
        prompt: prompt,
        onConfirmed: () => runs++,
      );
      addTearDown(controller.dispose);
      return controller;
    }

    setUp(() => runs = 0);

    test('an action that can be undone runs on the first activation', () {
      // The path the documentation leads with, and the one with the least in
      // it: no prompt, no dialog, no second step for the user who was right.
      final IuxDestructiveActionController controller =
          controllerFor(_immediate);

      final IuxActionOutcome outcome = controller.activate();

      expect(outcome.isAccepted, isTrue);
      expect(runs, 1);
      expect(controller.isConfirming, isFalse);
      expect(controller.dialog, isNull);
    });

    test('an action that asks to be confirmed does not run on activation', () {
      final IuxDestructiveActionController controller =
          controllerFor(_confirming, prompt: _prompt);

      final IuxActionOutcome outcome = controller.activate();

      expect(outcome.isAccepted, isFalse);
      expect(
        outcome.blockedReason,
        IuxActionBlockedReason.awaitingConfirmation,
      );
      expect(runs, 0);
      expect(controller.isConfirming, isTrue);
      expect(controller.dialog, isNotNull);
    });

    test('confirming runs the action exactly once and closes the question', () {
      final IuxDestructiveActionController controller =
          controllerFor(_confirming, prompt: _prompt)..activate();

      controller.confirm();

      expect(runs, 1);
      expect(controller.isConfirming, isFalse);
      expect(controller.dialog, isNull);
    });

    test('leaving the confirmation runs nothing', () {
      final IuxDestructiveActionController controller =
          controllerFor(_confirming, prompt: _prompt)..activate();

      controller.cancel();

      expect(runs, 0);
      expect(controller.isConfirming, isFalse);
      expect(controller.dialog, isNull);
    });

    test('a second activation does not open a second question', () {
      final IuxDestructiveActionController controller =
          controllerFor(_confirming, prompt: _prompt);
      int notifications = 0;
      controller.addListener(() => notifications++);

      controller
        ..activate()
        ..activate();

      expect(notifications, 1);
      expect(controller.isConfirming, isTrue);
    });

    test('an unavailable action neither runs nor asks', () {
      final IuxDestructiveActionController controller = controllerFor(
        _confirming.copyWith(availability: IuxActionAvailability.disabled),
        prompt: _prompt,
      );

      final IuxActionOutcome outcome = controller.activate();

      expect(outcome.blockedReason, IuxActionBlockedReason.unavailable);
      expect(runs, 0);
      expect(controller.dialog, isNull);
    });

    test('a running action drops a repeat activation', () {
      final IuxDestructiveActionController controller = controllerFor(
        _immediate.copyWith(operation: IuxActionOperation.inProgress),
      );

      final IuxActionOutcome outcome = controller.activate();

      expect(outcome.blockedReason, IuxActionBlockedReason.alreadyInProgress);
      expect(runs, 0);
    });

    test('the confirming choice does not ask to be confirmed again', () {
      // Otherwise the confirmation confirms the confirmation, and the action
      // never runs at all.
      final IuxDestructiveActionController controller =
          controllerFor(_confirming, prompt: _prompt)..activate();

      final IuxDialogAction choice = controller.dialog!.actions.single;

      expect(choice.label, 'Delete');
      expect(choice.action.requiresConfirmation, isFalse);
    });

    test('the confirming choice keeps the action it is confirming', () {
      final IuxDestructiveActionController controller =
          controllerFor(_confirming, prompt: _prompt)..activate();

      final IuxDialogAction choice = controller.dialog!.actions.single;

      expect(choice.action.semantics, _semantics);
      expect(choice.action.intent, IuxActionIntent.destructive);
      expect(choice.action.role, IuxActionRole.delete);
      expect(choice.action.reversibility, IuxActionReversibility.irreversible);
    });

    test('an unavailable action is unavailable inside its own confirmation',
        () {
      final IuxDestructiveActionController controller =
          controllerFor(_confirming, prompt: _prompt)..activate();

      controller.update(
        action:
            _confirming.copyWith(availability: IuxActionAvailability.disabled),
        prompt: _prompt,
      );

      expect(controller.dialog!.actions.single.action.isActivatable, isFalse);
    });

    test(
        'OPEN DEFECT (IUX-008.9): confirm() runs an action that became '
        'unavailable while the question was open', () {
      // The test above proves the *dialog* refuses it: the choice it builds is
      // not activatable, so no user can reach this through the interface. The
      // controller method itself has no such guard. `activate()` asks
      // IuxActionPolicy; `confirm()` asks nothing and calls onConfirmed, and
      // `update()` explicitly invites an availability that follows the
      // selection to change under an open confirmation.
      //
      // Asserted as it behaves today because an audit does not edit what it
      // audits. Whoever adds the guard will see this test fail, which is the
      // intended way for it to change.
      final IuxDestructiveActionController controller =
          controllerFor(_confirming, prompt: _prompt)..activate();

      controller.update(
        action:
            _confirming.copyWith(availability: IuxActionAvailability.disabled),
        prompt: _prompt,
      );
      controller.confirm();

      expect(
        runs,
        1,
        reason: 'the action ran after it had been declared unavailable',
      );
    });

    test('the confirmation is offered exactly one way out and one way on', () {
      final IuxDestructiveActionController controller =
          controllerFor(_confirming, prompt: _prompt)..activate();

      final IuxDialog dialog = controller.dialog!;

      expect(dialog.title, _prompt.title);
      expect(dialog.message, _prompt.consequence);
      expect(dialog.dismissLabel, _prompt.keepLabel);
      expect(dialog.actions, hasLength(1));
    });

    test('new wording reaches a confirmation that is already open', () {
      final IuxDestructiveActionController controller =
          controllerFor(_confirming, prompt: _prompt)..activate();

      const IuxConfirmationPrompt updated = IuxConfirmationPrompt(
        title: 'Delete 4 files?',
        consequence: 'The files leave this device and the shared folder.',
        confirmLabel: 'Delete',
        keepLabel: 'Keep the files',
      );
      controller.update(action: _confirming, prompt: updated);

      expect(controller.dialog!.title, 'Delete 4 files?');
    });

    test('an action that stops asking closes the question it had open', () {
      final IuxDestructiveActionController controller =
          controllerFor(_confirming, prompt: _prompt)..activate();

      controller.update(action: _immediate);

      expect(controller.isConfirming, isFalse);
      expect(controller.dialog, isNull);
      expect(runs, 0, reason: 'closing a question is not answering it');
    });

    test('an update that changes nothing notifies nobody', () {
      final IuxDestructiveActionController controller =
          controllerFor(_confirming, prompt: _prompt);
      int notifications = 0;
      controller.addListener(() => notifications++);

      controller.update(action: _confirming, prompt: _prompt);

      expect(notifications, 0);
    });
  });

  group('combinations the controller refuses, because they mean nothing', () {
    void refuses(String description, VoidCallback build) {
      test(description, () => expect(build, throwsA(isA<AssertionError>())));
    }

    refuses('an action that asks to be confirmed with no wording', () {
      IuxDestructiveActionController(action: _confirming, onConfirmed: () {});
    });

    refuses('wording for an action that asks for no confirmation', () {
      // The dangerous half: the call site reads as though the user were being
      // asked, and the action runs on the first tap.
      IuxDestructiveActionController(
        action: _immediate,
        prompt: _prompt,
        onConfirmed: () {},
      );
    });

    refuses('confirming an action that can simply be undone', () {
      // Undo beats confirmation whenever going back is on offer. An action
      // that is genuinely slow to reverse says so with difficultToReverse.
      IuxDestructiveActionController(
        action: const IuxActionDescriptor.destructive(
          semantics: _semantics,
          reversibility: IuxActionReversibility.reversible,
        ),
        prompt: _prompt,
        onConfirmed: () {},
      );
    });

    // Two cases stood here, checking that this controller refused
    // `IuxConfirmByHold` and `IuxConfirmByDoubleActivation`. IUX-039 removed
    // both policies from `IuxConfirmationPolicy` — this controller's refusal
    // was the only reading either ever received, and a policy honoured by
    // nothing is a precaution the user is promised and never gets. There is
    // now no unhonourable member left to refuse, so the assertion in
    // `_debugCoherent` is a guard against a future member rather than against
    // a shipped one.

    refuses('an update that leaves the wording behind', () {
      IuxDestructiveActionController(
        action: _confirming,
        prompt: _prompt,
        onConfirmed: () {},
      ).update(action: _confirming);
    });

    refuses('confirming something the user was never asked about', () {
      IuxDestructiveActionController(
        action: _confirming,
        prompt: _prompt,
        onConfirmed: () {},
      ).confirm();
    });

    test('an action that asks for nothing is accepted as it stands', () {
      // The counterpart to every refusal above: the encouraged shape is the
      // one with the fewest arguments.
      expect(
        () => IuxDestructiveActionController(
          action: _immediate,
          onConfirmed: () {},
        ).dispose(),
        returnsNormally,
      );
    });
  });

  group('the honourer strips before delegating', () {
    // IUX-BUTTON-CONFIRM-001, and the path IUX-032 found into it: this
    // controller is the one thing in the package that evaluates a confirmation
    // policy, and it used to publish a descriptor that still carried one. A
    // plain `IuxButton` given that descriptor reproduced the defect from inside
    // the pattern that exists to prevent it.
    IuxDestructiveActionController controllerFor(
      IuxActionDescriptor action, {
      IuxConfirmationPrompt? prompt,
      VoidCallback? onConfirmed,
    }) {
      final IuxDestructiveActionController controller =
          IuxDestructiveActionController(
        action: action,
        prompt: prompt,
        onConfirmed: onConfirmed ?? () {},
      );
      addTearDown(controller.dispose);
      return controller;
    }

    test('the public getter no longer publishes a confirming descriptor', () {
      final IuxDestructiveActionController controller =
          controllerFor(_confirming, prompt: _prompt);

      expect(
        _confirming.requiresConfirmation,
        isTrue,
        reason: 'sanity: the descriptor going in is the one that asks',
      );
      expect(
        controller.action.requiresConfirmation,
        isFalse,
        reason: 'the descriptor coming out must not. Anything holding it can '
            'only hand it to a control, and no control presents a question — '
            'the controller does, and it has kept the policy for itself.',
      );
      expect(
        controller.action.confirmation,
        IuxConfirmationPolicy.none,
        reason: 'and it says so with the member that means it, not by '
            'accident',
      );
    });

    test('nothing else about the descriptor is disturbed', () {
      // A safety fix that quietly re-enabled a disabled deletion would be
      // worse than the defect it closed.
      final IuxDestructiveActionController controller = controllerFor(
        _confirming.copyWith(
          availability: IuxActionAvailability.disabled,
          operation: IuxActionOperation.idle,
        ),
        prompt: _prompt,
      );

      expect(
        controller.action,
        _confirming.copyWith(
          availability: IuxActionAvailability.disabled,
          confirmation: IuxConfirmationPolicy.none,
        ),
        reason: 'one field moved and no other',
      );
      expect(controller.action.semantics, _semantics);
      expect(controller.action.intent, IuxActionIntent.destructive);
      expect(
          controller.action.reversibility, IuxActionReversibility.irreversible);
      expect(controller.action.isActivatable, isFalse);
    });

    test('the controller keeps the policy it stripped, and still asks', () {
      // The strip is on the way *out*. Were it applied to the stored
      // descriptor, `activate()` would evaluate an action that asks for
      // nothing and the deletion would run unasked — the defect, moved one
      // file over.
      int runs = 0;
      final IuxDestructiveActionController controller = controllerFor(
        _confirming,
        prompt: _prompt,
        onConfirmed: () => runs++,
      );

      expect(
        controller.activate().blockedReason,
        IuxActionBlockedReason.awaitingConfirmation,
      );
      expect(runs, 0);
      expect(controller.dialog, isNotNull);
    });

    test('an update carrying a policy is stripped on the way out too', () {
      // update() is the second way a descriptor reaches this controller, and a
      // getter that stripped only what the constructor was given would leak on
      // the first availability change.
      final IuxDestructiveActionController controller =
          controllerFor(_immediate)
            ..update(action: _confirming, prompt: _prompt);

      expect(controller.action.requiresConfirmation, isFalse);
      expect(
        controller.activate().blockedReason,
        IuxActionBlockedReason.awaitingConfirmation,
        reason: 'and the controller is still honouring the updated policy',
      );
    });

    testWidgets('the stripped descriptor is what a plain IuxButton will accept',
        (WidgetTester tester) async {
      // The composition IuxDestructiveAction performs, written by hand: this is
      // what a caller reading `action`\'s docstring builds, and it is the exact
      // call site IUX-032 measured the defect on.
      int runs = 0;
      final IuxDestructiveActionController controller = controllerFor(
        _confirming,
        prompt: _prompt,
        onConfirmed: () => runs++,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: IuxTheme.light(),
          home: Scaffold(
            body: ListenableBuilder(
              listenable: controller,
              builder: (BuildContext context, Widget? child) => IuxButton(
                label: 'Delete',
                action: controller.action,
                onActivate: controller.activate,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: 'a descriptor published by the honourer is one a button may '
            'be given. If this throws, the getter has started leaking again '
            'and the refusal in IuxButton has caught it.',
      );

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(
        runs,
        0,
        reason: 'and the tap opened the question rather than running the '
            'deletion — the button accepted the activation, the controller '
            'refused it',
      );
      expect(controller.isConfirming, isTrue);
    });
  });

  group('the control, in a page', () {
    Future<_Host> pump(
      WidgetTester tester, {
      IuxActionDescriptor action = _confirming,
      IuxConfirmationPrompt? prompt = _prompt,
      IuxThemeConfiguration configuration = const IuxThemeConfiguration(),
      TextDirection direction = TextDirection.ltr,
      double textScale = 1,
      Size size = const Size(400, 800),
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      late final _Host host;
      final IuxDestructiveActionController controller =
          IuxDestructiveActionController(
        action: action,
        prompt: prompt,
        onConfirmed: () => host.runs++,
      );
      host = _Host(controller);
      addTearDown(controller.dispose);
      addTearDown(host.elsewhere.dispose);

      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: MaterialApp(
            theme: IuxTheme.fromConfiguration(configuration),
            home: Directionality(
              textDirection: direction,
              child: Scaffold(
                // The parent rebuilds the page when the answer is asked for and
                // again when it is given. The pattern puts nothing on screen by
                // itself, which is what keeps layering the application's.
                body: ListenableBuilder(
                  listenable: controller,
                  builder: (BuildContext context, Widget? child) =>
                      IuxModalLayer(
                    dialog: controller.dialog,
                    child: IuxPage(
                      child: Column(
                        children: <Widget>[
                          IuxButton(
                            label: 'Elsewhere',
                            action: const IuxActionDescriptor(
                              semantics: IuxActionSemantics(label: 'Elsewhere'),
                            ),
                            focusNode: host.elsewhere,
                            onActivate: () {},
                          ),
                          IuxDestructiveAction(
                            label: 'Delete',
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
      );
      await tester.pumpAndSettle();
      return host;
    }

    testWidgets('an action that can be undone runs on the first tap',
        (WidgetTester tester) async {
      final _Host host = await pump(tester, action: _immediate, prompt: null);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(host.runs, 1);
      expect(find.byType(IuxDialog), findsNothing);
    });

    testWidgets('an action that asks to be confirmed states its consequence',
        (WidgetTester tester) async {
      final _Host host = await pump(tester);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(host.runs, 0);
      expect(find.byType(IuxDialog), findsOneWidget);
      expect(find.text(_prompt.title), findsOneWidget);
      expect(find.text(_prompt.consequence), findsOneWidget);
      expect(find.text(_prompt.keepLabel), findsOneWidget);
    });

    testWidgets(
        'the trigger is given the stripped descriptor and announces '
        'exactly what it did before', (WidgetTester tester) async {
      // The second legitimate caller of IUX-BUTTON-CONFIRM-001, and the one the
      // reverted attempt concluded could not be fixed: this trigger's tap is
      // what *opens* the question, so the policy looked load-bearing here.
      //
      // It is not. Nothing in IuxButton reads the field — not the resolver, not
      // the semantics, not isActivatable — so the policy reaches no pixel and
      // no announcement, and the honourer that does read it is the controller
      // this button calls into. Measured rather than assumed: the announced
      // node is unchanged, and the tap below still opens the dialog.
      final SemanticsHandle handle = tester.ensureSemantics();
      final _Host host = await pump(tester);

      final IuxButton trigger = tester.widget<IuxButton>(
        find.ancestor(
          of: find.text('Delete'),
          matching: find.byType(IuxButton),
        ),
      );

      expect(
        trigger.action.requiresConfirmation,
        isFalse,
        reason: 'the trigger is delegated to, not an honourer',
      );
      expect(
        trigger.action,
        _confirming.copyWith(confirmation: IuxConfirmationPolicy.none),
        reason: 'and one field is all that moved',
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel(_semantics.label)),
        matchesSemantics(
          // The fuller announced name still comes from the descriptor, and the
          // node is byte-identical to the one the unstripped descriptor
          // produced: nothing in IuxButton ever read the policy.
          label: _semantics.label,
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(host.runs, 0, reason: 'end to end: the question opened');
      expect(find.byType(IuxDialog), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the confirming choice runs the action once and closes',
        (WidgetTester tester) async {
      final _Host host = await pump(tester);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // The trigger and the confirming choice both read "Delete"; the one in
      // the dialog is the one under the consequence.
      await tester.tap(find.descendant(
        of: find.byType(IuxDialog),
        matching: find.text('Delete'),
      ));
      await tester.pumpAndSettle();

      expect(host.runs, 1);
      expect(find.byType(IuxDialog), findsNothing);
    });

    testWidgets('the way out runs nothing', (WidgetTester tester) async {
      final _Host host = await pump(tester);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(_prompt.keepLabel));
      await tester.pumpAndSettle();

      expect(host.runs, 0);
      expect(find.byType(IuxDialog), findsNothing);
    });

    testWidgets('Escape leaves without running', (WidgetTester tester) async {
      final _Host host = await pump(tester);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(host.runs, 0);
      expect(find.byType(IuxDialog), findsNothing);
    });

    testWidgets(
        'a keypress already in flight cannot confirm an unread consequence',
        (WidgetTester tester) async {
      // The confirming choice must never hold focus when the confirmation
      // opens. A user part way through pressing Enter would otherwise delete
      // something they have not been shown.
      final _Host host = await pump(tester);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      final BuildContext focused = FocusManager.instance.primaryFocus!.context!;
      expect(
        focused.findAncestorWidgetOfExactType<IuxButton>(),
        isNull,
        reason: 'focus landed on a choice; Enter would take it',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(host.runs, 0);
      expect(find.byType(IuxDialog), findsOneWidget);
    });

    testWidgets(
        'both choices are reachable by keyboard, and nothing behind '
        'the confirmation is', (WidgetTester tester) async {
      // Strengthened in IUX-008.9. The page behind carries a control labelled
      // "Delete" of its own — the trigger — so collecting labels alone cannot
      // tell a reachable confirming choice from an escaped traversal that
      // landed back on the trigger. Every stop is now recorded with whether it
      // was inside the dialog, which also pins the focus trap: measured, six
      // presses cycle "Keep the files", "Delete", the panel, and never leave.
      final _Host host = await pump(tester);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      final Set<String> reachedInDialog = <String>{};
      final Set<String> escaped = <String>{};
      for (int press = 0; press < 6; press++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final BuildContext focused =
            FocusManager.instance.primaryFocus!.context!;
        final IuxButton? button =
            focused.findAncestorWidgetOfExactType<IuxButton>();
        if (button == null) continue;
        if (focused.findAncestorWidgetOfExactType<IuxDialog>() != null) {
          reachedInDialog.add(button.label);
        } else {
          escaped.add(button.label);
        }
      }

      expect(
        reachedInDialog,
        containsAll(<String>['Keep the files', 'Delete']),
      );
      expect(
        escaped,
        isEmpty,
        reason: 'a confirmation the user can tab out of is a question they can '
            'answer by acting on the page it was asked about',
      );
      expect(host.runs, 0);
    });

    testWidgets('focus returns to the trigger when the question closes',
        (WidgetTester tester) async {
      // The controller documents that it closes the confirmation before
      // running the action, "so focus is already on its way back to whatever
      // held it". Nothing measured that. It does come back — to the trigger,
      // on both answers — which is what stops a keyboard user landing at the
      // top of the page after every confirmation.
      final _Host host = await pump(tester);
      final FocusNode trigger = FocusNode(debugLabel: 'trigger');
      addTearDown(trigger.dispose);

      // Rebuilt with a node this test owns, so the assertion is about the
      // trigger rather than about whatever happens to hold focus.
      await tester.pumpWidget(
        MaterialApp(
          theme: IuxTheme.light(),
          home: ListenableBuilder(
            listenable: host.controller,
            builder: (BuildContext context, Widget? child) => IuxModalLayer(
              dialog: host.controller.dialog,
              child: IuxPage(
                child: IuxDestructiveAction(
                  label: 'Delete',
                  controller: host.controller,
                  focusNode: trigger,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      trigger.requestFocus();
      await tester.pumpAndSettle();
      expect(trigger.hasFocus, isTrue);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(
        trigger.hasFocus,
        isFalse,
        reason: 'the confirmation takes focus; its own test covers where',
      );

      await tester.tap(find.text(_prompt.keepLabel));
      await tester.pumpAndSettle();
      expect(
        trigger.hasFocus,
        isTrue,
        reason: 'leaving the question puts the user back where they asked it',
      );
      expect(host.runs, 0);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(
        of: find.byType(IuxDialog),
        matching: find.text('Delete'),
      ));
      await tester.pumpAndSettle();
      expect(host.runs, 1);
      expect(
        trigger.hasFocus,
        isTrue,
        reason: 'and going ahead does too',
      );
    });

    testWidgets('and it returns there when the caller supplied no node',
        (WidgetTester tester) async {
      // The test above hands the trigger a node the *test* owns, which is what
      // made it pass while the ordinary call site was broken. Without a node
      // the trigger's own was created by the widget, and the widget does not
      // survive its own confirmation: `IuxModalLayer` adds a `Stack` when the
      // dialog opens and removes it when it closes, so the page changes depth
      // in the element tree twice and is rebuilt from scratch both times.
      // `IuxFocus.restore` then found a node with no context and did nothing.
      //
      // Measured before the fix on this page of four controls: focus landed on
      // the page's root scope and cost **three Tab presses** to get back to
      // the trigger. After it, zero (IUX-DESTRUCTIVE-FOCUS-001, WCAG 2.2 SC
      // 2.4.3 — Flutter's own dialog costs zero too).
      final IuxDestructiveActionController controller =
          IuxDestructiveActionController(
        action: _confirming,
        prompt: _prompt,
        onConfirmed: () {},
      );
      addTearDown(controller.dispose);

      Widget filler(String label) => IuxButton(
            label: label,
            action: IuxActionDescriptor.primary(
              semantics: IuxActionSemantics(label: label),
            ),
            onActivate: () {},
          );

      await tester.pumpWidget(
        MaterialApp(
          theme: IuxTheme.light(),
          home: ListenableBuilder(
            listenable: controller,
            builder: (BuildContext context, Widget? child) => IuxModalLayer(
              dialog: controller.dialog,
              child: IuxPage(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    filler('One'),
                    filler('Two'),
                    // No focusNode: the ordinary call site.
                    IuxDestructiveAction(
                      label: 'Delete',
                      controller: controller,
                    ),
                    filler('Four'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      bool onTrigger() {
        final BuildContext? held = FocusManager.instance.primaryFocus?.context;
        return held != null &&
            held.findAncestorWidgetOfExactType<IuxDestructiveAction>() != null;
      }

      /// Tabs until the trigger holds focus, and says how many presses it took.
      Future<int> tabsToTheTrigger() async {
        int presses = 0;
        while (!onTrigger() && presses < 12) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pumpAndSettle();
          presses++;
        }
        return presses;
      }

      // A keyboard user arrives at the trigger and opens the question from it.
      expect(await tabsToTheTrigger(), lessThan(12));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(onTrigger(), isFalse, reason: 'the confirmation takes focus');

      await tester.tap(find.text(_prompt.keepLabel));
      await tester.pumpAndSettle();

      expect(
        onTrigger(),
        isTrue,
        reason: 'leaving the question puts the user back on the control they '
            'asked it from, without a node the caller had to know to supply',
      );
      expect(
        await tabsToTheTrigger(),
        0,
        reason: 'and the way back costs no presses at all',
      );
    });

    testWidgets('the trigger announces the action, not the word on it',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester);

      expect(find.bySemanticsLabel(_semantics.label), findsOneWidget);
      expect(
        tester
            .getSemantics(find.bySemanticsLabel(_semantics.label))
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );

      handle.dispose();
    });

    testWidgets('the confirming choice announces the action too',
        (WidgetTester tester) async {
      // "Delete" alone tells a screen-reader user who swiped onto the control
      // nothing about what is being deleted.
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Walked from the application's node down, not through
      // `find.bySemanticsLabel`: that finder reads each render object's
      // `debugSemantics`, a cache that keeps its last value for a subtree
      // which stops being visited. Since IUX-OVERLAY-001 was closed the page
      // behind the dialog survives, so its blocked node survives with it and
      // the finder reports two matches for one announced label.
      final List<String> announced = <String>[];
      void visit(SemanticsNode node) {
        if (node.label.isNotEmpty) announced.add(node.label);
        node.visitChildren((SemanticsNode child) {
          visit(child);
          return true;
        });
      }

      visit(tester.getSemantics(find.byType(MaterialApp)));

      expect(announced, contains(_semantics.label));
      expect(announced, contains(_prompt.keepLabel));

      handle.dispose();
    });

    testWidgets('an unavailable trigger is announced, not merely greyed',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final _Host host = await pump(
        tester,
        action: _confirming.copyWith(
          availability: IuxActionAvailability.disabled,
          semantics: _semantics.copyWith(
            unavailabilityReason: 'Select a file first',
          ),
        ),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel(_semantics.label)),
        matchesSemantics(
          label: _semantics.label,
          // The reason is announced. A greyed control with no explanation
          // leaves the user unable to tell whether they did something wrong.
          hint: 'Select a file first',
          isButton: true,
          isEnabled: false,
          hasEnabledState: true,
          // No tap action while unavailable: a screen reader must not offer an
          // activation that would do nothing.
          hasTapAction: false,
        ),
      );

      await tester.tap(find.text('Delete'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(host.runs, 0);
      expect(find.byType(IuxDialog), findsNothing);

      handle.dispose();
    });

    testWidgets('a running action does not ask a second time',
        (WidgetTester tester) async {
      final _Host host = await pump(
        tester,
        action: _confirming.copyWith(operation: IuxActionOperation.inProgress),
      );

      await tester.tap(find.text('Delete'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(host.runs, 0);
      expect(find.byType(IuxDialog), findsNothing);
    });

    testWidgets('the consequence survives 200% text on a small screen',
        (WidgetTester tester) async {
      final _Host host = await pump(
        tester,
        textScale: 2,
        size: const Size(320, 640),
      );

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(_prompt.consequence), findsOneWidget);
      expect(host.runs, 0);
    });

    testWidgets('a long consequence wraps rather than being cut short',
        (WidgetTester tester) async {
      await pump(
        tester,
        prompt: const IuxConfirmationPrompt(
          title: 'Delete 3 files?',
          consequence: _longConsequence,
          confirmLabel: 'Delete',
          keepLabel: 'Keep the files',
        ),
        textScale: 1.5,
        size: const Size(320, 640),
      );

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final Text message = tester.widget<Text>(find.text(_longConsequence));
      expect(message.maxLines, isNull);
      expect(message.overflow, isNot(TextOverflow.ellipsis));
    });

    testWidgets('right to left changes the layout, not the decision',
        (WidgetTester tester) async {
      final _Host host = await pump(tester, direction: TextDirection.rtl);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(find.text(_prompt.consequence), findsOneWidget);

      await tester.tap(find.descendant(
        of: find.byType(IuxDialog),
        matching: find.text('Delete'),
      ));
      await tester.pumpAndSettle();

      expect(host.runs, 1);
    });

    testWidgets('the confirmation appears with no motion at all',
        (WidgetTester tester) async {
      // Under IuxMotionPreference.none the entrance is set rather than
      // animated, so a user who asked for no motion is not shown an invisible
      // dialog for a frame.
      final _Host host = await pump(
        tester,
        configuration: const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(motion: IuxMotionPreference.none),
        ),
      );

      await tester.tap(find.text('Delete'));
      await tester.pump();

      expect(find.text(_prompt.consequence), findsOneWidget);
      expect(host.runs, 0);
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

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(
        of: find.byType(IuxDialog),
        matching: find.text('Delete'),
      ));
      await tester.pumpAndSettle();

      expect(host.runs, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the trigger follows an action that changed under it',
        (WidgetTester tester) async {
      final _Host host = await pump(tester, action: _immediate, prompt: null);

      host.controller.update(
        action: _immediate.copyWith(
          availability: IuxActionAvailability.disabled,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(host.runs, 0);
    });
  });
}
