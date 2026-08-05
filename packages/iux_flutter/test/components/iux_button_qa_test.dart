import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

import '../support/contrast.dart';

/// What IUX-008.9 measured about the button surface, pinned so it cannot drift.
///
/// Every test here was written after a probe, never from reading the code. The
/// group names say which of the two things a test is doing:
///
/// - **verified** — the behaviour is correct, nothing tested it before, and it
///   is now locked;
/// - **open defect** — the behaviour is wrong, the fix belongs to `lib/` and an
///   audit does not edit what it audits. The test asserts what the code *does*
///   today, with the defect named. When somebody fixes it, this test fails,
///   which is the point: the correction is then a deliberate edit rather than a
///   silent change nobody notices.
void main() {
  const IuxActionSemantics saveSemantics = IuxActionSemantics(label: 'Save');
  const IuxActionDescriptor idle = IuxActionDescriptor(
    semantics: saveSemantics,
    intent: IuxActionIntent.primary,
  );

  Future<void> host(
    WidgetTester tester,
    Widget child, {
    IuxThemeConfiguration configuration = const IuxThemeConfiguration(),
    TextDirection direction = TextDirection.ltr,
    double textScale = 1,
    Size size = const Size(400, 800),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

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
            child: Scaffold(body: Center(child: child)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  BoxDecoration decorationOf(WidgetTester tester) => tester
      .widget<AnimatedContainer>(find.byType(AnimatedContainer))
      .decoration! as BoxDecoration;

  group(
      'fixed — a running action keeps the focus the user put on it '
      '(IUX-BUTTON-BUSY-001, IUX-BUTTON-BUSY-002)', () {
    // Measured, not read. IuxButton used to wire `canRequestFocus` to
    // `action.isActivatable`, and under the default
    // IuxActionRepeatPolicy.ignoreWhileInProgress that is false for the whole
    // run. Availability and focusability are not the same question: an action
    // that cannot be started *right now* is still the control the user is
    // standing on. Only *unavailable* now takes a control out of the focus
    // order, which is where Flutter draws the line too.
    //
    // Distinct from IUX-A11Y-FOCUS-001, which was about the semantics node
    // declaring no focusable state. This is real focus, and it used to move.

    testWidgets('activating with Enter leaves focus where the user put it',
        (WidgetTester tester) async {
      late void Function(IuxAsyncOutcome) finish;
      final IuxAsyncActionController controller = IuxAsyncActionController(
        action: const IuxActionDescriptor.primary(
          semantics: IuxActionSemantics(label: 'Pay'),
        ),
        operation: (IuxAsyncActionSignal signal) {
          final Completer<IuxAsyncOutcome> completer =
              Completer<IuxAsyncOutcome>();
          finish = completer.complete;
          return completer.future;
        },
      );
      addTearDown(controller.dispose);

      await host(
        tester,
        Column(
          children: <Widget>[
            IuxButton(
              label: 'Before',
              action: const IuxActionDescriptor(
                semantics: IuxActionSemantics(label: 'Before'),
              ),
              onActivate: () {},
            ),
            IuxAsyncActionButton(
              controller: controller,
              label: 'Pay',
              busyLabel: 'Paying...',
            ),
            IuxButton(
              label: 'After',
              action: const IuxActionDescriptor(
                semantics: IuxActionSemantics(label: 'After'),
              ),
              onActivate: () {},
            ),
          ],
        ),
      );

      String focusedLabel() {
        final BuildContext? context =
            FocusManager.instance.primaryFocus?.context;
        return context?.findAncestorWidgetOfExactType<IuxButton>()?.label ??
            'nothing';
      }

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedLabel(), 'Pay', reason: 'the user tabbed onto the action');

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(find.text('Paying...'), findsOneWidget);

      expect(
        focusedLabel(),
        // The visible label is the caller's busy wording while the operation
        // runs; it is the same control and the same focus node.
        'Paying...',
        reason: 'pressing Enter used to send focus backwards to the control '
            'above. The user asked to run something and was moved somewhere '
            'they did not choose.',
      );

      // And the running control is still a stop of its own: one Tab from it
      // reaches the next control rather than skipping over it from "Before".
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedLabel(), 'After');

      finish(const IuxAsyncOutcome.succeeded());
      await tester.pumpAndSettle();
      expect(
        focusedLabel(),
        'After',
        reason: 'the run finished with the user where they had walked to',
      );
    });

    testWidgets(
        'the repeat policy no longer decides whether a busy button keeps '
        'its focus', (WidgetTester tester) async {
      // The proof that this was a conflation rather than a deliberate choice:
      // the same running action stayed focusable when its repeat policy
      // happened to allow a second activation. Nothing about focus changed
      // between the two, only whether a second tap would be accepted — so the
      // two policies must agree, and now do.
      final FocusNode node = FocusNode(debugLabel: 'busy');
      addTearDown(node.dispose);

      Future<bool> focusableUnder(IuxActionRepeatPolicy policy) async {
        await host(
          tester,
          IuxButton(
            label: 'Save',
            focusNode: node,
            busyHint: 'Saving',
            action: idle.copyWith(
              operation: IuxActionOperation.inProgress,
              repeatPolicy: policy,
            ),
            onActivate: () {},
          ),
        );
        node.requestFocus();
        await tester.pumpAndSettle();
        return node.hasFocus;
      }

      expect(await focusableUnder(IuxActionRepeatPolicy.allow), isTrue);
      expect(
        await focusableUnder(IuxActionRepeatPolicy.ignoreWhileInProgress),
        isTrue,
        reason: 'the default repeat policy used to remove the control from '
            'focus traversal for the duration of the operation.',
      );
    });

    testWidgets(
        'losing focus on *disable* matches Flutter, so only the busy '
        'case is the defect', (WidgetTester tester) async {
      // Not a test of IUX. It pins the platform behaviour this finding is
      // measured against, so the report cannot be read as "IUX drops focus
      // and Flutter does not". Flutter drops it too — for a disabled button,
      // which is a control the user genuinely cannot use. A busy one is not.
      final FocusNode flutterNode = FocusNode(debugLabel: 'flutter');
      final FocusNode iuxNode = FocusNode(debugLabel: 'iux');
      addTearDown(flutterNode.dispose);
      addTearDown(iuxNode.dispose);

      await host(
        tester,
        Column(
          children: <Widget>[
            ElevatedButton(
              focusNode: flutterNode,
              onPressed: () {},
              child: const Text('Flutter'),
            ),
            IuxButton(
              label: 'Iux',
              focusNode: iuxNode,
              action: idle,
              onActivate: () {},
            ),
          ],
        ),
      );
      flutterNode.requestFocus();
      await tester.pumpAndSettle();
      expect(flutterNode.hasFocus, isTrue);

      await host(
        tester,
        Column(
          children: <Widget>[
            ElevatedButton(
              focusNode: flutterNode,
              onPressed: null,
              child: const Text('Flutter'),
            ),
            IuxButton(
              label: 'Iux',
              focusNode: iuxNode,
              action:
                  idle.copyWith(availability: IuxActionAvailability.disabled),
              onActivate: () {},
            ),
          ],
        ),
      );
      expect(flutterNode.hasFocus, isFalse);
      expect(iuxNode.hasFocus, isFalse);
    });
  });

  group('fixed — a running button no longer announces itself as disabled', () {
    testWidgets(
        'a working control and an unavailable one no longer produce the '
        'same node', (WidgetTester tester) async {
      await host(
        tester,
        Column(
          children: <Widget>[
            IuxButton(
              label: 'Busy',
              action: const IuxActionDescriptor(
                semantics: IuxActionSemantics(label: 'Busy'),
                operation: IuxActionOperation.inProgress,
              ),
              onActivate: () {},
            ),
            IuxButton(
              label: 'Off',
              action: const IuxActionDescriptor(
                semantics: IuxActionSemantics(label: 'Off'),
                availability: IuxActionAvailability.disabled,
              ),
              onActivate: () {},
            ),
          ],
        ),
      );

      // No busyHint supplied, which the API permits: it is optional on
      // IuxButton and there is no assertion pushing a caller towards it. So
      // this is the *worst* case for telling the two apart, and it is exactly
      // the case that used to be indistinguishable.
      expect(
        tester.getSemantics(find.bySemanticsLabel('Busy')),
        matchesSemantics(
          label: 'Busy',
          isButton: true,
          // Running is not unavailable. WCAG 2.2 SC 4.1.2 asks for the state
          // the control is actually in, and this one is working.
          isEnabled: true,
          hasEnabledState: true,
          // No tap action, because the default repeat policy would drop one:
          // the node offers an activation exactly when activating would run
          // something. That is the same rule a disabled control follows, and
          // it is the only property the two still share.
          hasTapAction: false,
          // Still the control the user is standing on, and still somewhere
          // assistive technology can put accessibility focus.
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Off')),
        matchesSemantics(
          label: 'Off',
          isButton: true,
          isEnabled: false,
          hasEnabledState: true,
          hasTapAction: false,
        ),
        reason: 'an unavailable control leaves the focus order entirely, which '
            'is what Flutter does too and is not the defect',
      );
    });

    testWidgets('a supplied busyHint says what the state means',
        (WidgetTester tester) async {
      await host(
        tester,
        IuxButton(
          label: 'Save',
          busyHint: 'Enregistrement en cours',
          action: idle.copyWith(operation: IuxActionOperation.inProgress),
          onActivate: () {},
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Save')),
        matchesSemantics(
          label: 'Save',
          hint: 'Enregistrement en cours',
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          hasTapAction: false,
          isFocusable: true,
          hasFocusAction: true,
        ),
        reason: 'the wording explains the state, and the state now agrees '
            'with it — the hint used to be attached to a node announcing '
            'itself as unavailable, on a control the user had been moved off',
      );
    });
  });

  group('engagement feedback is offered exactly when engaging would run', () {
    // The other half of IUX-BUTTON-DEAD-001, closed at IUX-040.
    // `IuxButtonState.loading` was the last rung of the resolver that painted
    // nothing: measured byte-identical to `enabled` on all four profiles, in
    // all seventeen legal intent/variant pairs, in every token. Being inert was
    // not the cost. It sat *above* `pressed` and `hovered`, so a running action
    // whose repeat policy genuinely accepts a second tap answered neither the
    // pointer nor the finger — measured, on the filled primary: idle moved
    // #1560B0 -> #0F4289 on hover and -> #0A2C63 on press, inProgress did not
    // move at all. Exactly what `success` and `error` had done before IUX-038
    // removed them, left behind by that mission.
    //
    // The rule that replaced it is one sentence and holds in both directions:
    // the container answers the pointer when, and only when, activating would
    // run something. `IuxActionDescriptor.isActivatable` is the same question
    // the tap action and the gesture handlers already ask, so the three cannot
    // drift apart.

    Future<(Color, Color, Color)> palette(
      WidgetTester tester, {
      required IuxActionOperation operation,
      required IuxActionRepeatPolicy policy,
      IuxActionAvailability availability = IuxActionAvailability.enabled,
    }) async {
      await host(
        tester,
        IuxButton(
          label: 'Save',
          busyHint: 'Saving',
          variant: IuxButtonVariant.filled,
          action: idle.copyWith(
            operation: operation,
            repeatPolicy: policy,
            availability: availability,
          ),
          onActivate: () {},
        ),
      );
      final Color resting = decorationOf(tester).color!;

      final TestGesture pointer =
          await tester.createGesture(kind: PointerDeviceKind.mouse);
      await pointer.addPointer(location: Offset.zero);
      await tester.pump();
      await pointer.moveTo(tester.getCenter(find.byType(IuxButton)));
      await tester.pumpAndSettle();
      final Color hovered = decorationOf(tester).color!;
      await pointer.removePointer();
      await tester.pumpAndSettle();

      final TestGesture finger =
          await tester.startGesture(tester.getCenter(find.byType(IuxButton)));
      await tester.pumpAndSettle();
      final Color pressed = decorationOf(tester).color!;
      await finger.up();
      await tester.pumpAndSettle();

      return (resting, hovered, pressed);
    }

    testWidgets('a running action that still accepts a tap answers the pointer',
        (WidgetTester tester) async {
      final (Color resting, Color hovered, Color pressed) = await palette(
        tester,
        operation: IuxActionOperation.inProgress,
        policy: IuxActionRepeatPolicy.allow,
      );
      expect(
        hovered,
        isNot(equals(resting)),
        reason: 'this button accepts a second activation — isActivatable is '
            'true — and gave the pointer nothing back. The busy rung outranked '
            'hovered while having no colour of its own to show for it.',
      );
      expect(
        pressed,
        isNot(equals(resting)),
        reason: 'and the tap it accepted registered invisibly. Activation '
            'feedback that does not change is activation feedback the user '
            'never receives.',
      );
      expect(pressed, isNot(equals(hovered)));
    });

    testWidgets('it matches an idle button exactly, because it is one',
        (WidgetTester tester) async {
      // Not "some feedback" but the same feedback. A running control that
      // accepts taps differs from a resting one in nothing the container can
      // say, so inventing a third palette for it would be a colour-only status
      // signal — which is what the component standard refuses and what the
      // removed rung was one careless commit away from becoming.
      expect(
        await palette(
          tester,
          operation: IuxActionOperation.inProgress,
          policy: IuxActionRepeatPolicy.allow,
        ),
        equals(await palette(
          tester,
          operation: IuxActionOperation.idle,
          policy: IuxActionRepeatPolicy.allow,
        )),
      );
    });

    testWidgets('a running action that drops the tap stays still',
        (WidgetTester tester) async {
      // The direction that matters more. Under the default repeat policy the
      // activation *is* dropped, so hover feedback would be the container
      // promising a tap it will not honour — and this used to be guaranteed
      // only as a side effect of the busy rung outranking hovered. It is now
      // stated: `isActivatable` gates the pointer state before the resolver
      // ever sees it.
      final (Color resting, Color hovered, Color pressed) = await palette(
        tester,
        operation: IuxActionOperation.inProgress,
        policy: IuxActionRepeatPolicy.ignoreWhileInProgress,
      );
      expect(hovered, equals(resting));
      expect(pressed, equals(resting));
    });

    testWidgets('and neither does an unavailable one',
        (WidgetTester tester) async {
      final (Color resting, Color hovered, Color pressed) = await palette(
        tester,
        operation: IuxActionOperation.idle,
        policy: IuxActionRepeatPolicy.allow,
        availability: IuxActionAvailability.disabled,
      );
      expect(hovered, equals(resting));
      expect(pressed, equals(resting));
    });
  });

  group('a settled operation is a message, not a colour on the container', () {
    testWidgets('succeeded and failed render exactly like idle',
        (WidgetTester tester) async {
      // Unchanged from IUX-008.9, but no longer filed as a defect. A result
      // painted onto the container would be a colour-only signal — WCAG 2.2
      // SC 1.4.1, and the component standard §6 asks an error state for "a
      // message, never a colour alone". The message exists, in the widget that
      // owns the lifecycle; see the next test.
      final Map<IuxActionOperation, BoxDecoration> painted =
          <IuxActionOperation, BoxDecoration>{};
      final Map<IuxActionOperation, String> announced =
          <IuxActionOperation, String>{};

      for (final IuxActionOperation operation in <IuxActionOperation>[
        IuxActionOperation.idle,
        IuxActionOperation.succeeded,
        IuxActionOperation.failed,
      ]) {
        await host(
          tester,
          IuxButton(
            label: 'Save',
            action: idle.copyWith(operation: operation),
            onActivate: () {},
          ),
        );
        painted[operation] = decorationOf(tester);
        final SemanticsNode node =
            tester.getSemantics(find.bySemanticsLabel('Save'));
        announced[operation] = '${node.label}|${node.hint}|'
            '${node.getSemanticsData().flagsCollection.isEnabled}';
      }

      expect(
        painted[IuxActionOperation.failed],
        equals(painted[IuxActionOperation.idle]),
      );
      expect(
        painted[IuxActionOperation.succeeded],
        equals(painted[IuxActionOperation.idle]),
      );
      expect(
        announced[IuxActionOperation.failed],
        equals(announced[IuxActionOperation.idle]),
      );
      expect(
        announced[IuxActionOperation.succeeded],
        equals(announced[IuxActionOperation.idle]),
      );
    });

    testWidgets('a settled action still answers the pointer',
        (WidgetTester tester) async {
      // IUX-038. The dead IuxButtonState.success/.error were not inert: they
      // sat *above* `hovered` in the resolver's precedence and returned a
      // palette identical to resting, so a succeeded or failed button stopped
      // responding to hover altogether. The states painted nothing and
      // swallowed something. Measured before the fix: an idle button moved
      // from #1560B0 to #0F4289 on hover, a succeeded one did not move at all.
      Future<BoxDecoration> hovered(IuxActionOperation operation) async {
        await host(
          tester,
          IuxButton(
            label: 'Save',
            variant: IuxButtonVariant.filled,
            action: idle.copyWith(operation: operation),
            onActivate: () {},
          ),
        );
        final BoxDecoration resting = decorationOf(tester);
        final TestGesture pointer =
            await tester.createGesture(kind: PointerDeviceKind.mouse);
        await pointer.addPointer(location: Offset.zero);
        await tester.pump();
        await pointer.moveTo(tester.getCenter(find.byType(IuxButton)));
        await tester.pumpAndSettle();
        final BoxDecoration engaged = decorationOf(tester);
        await pointer.removePointer();
        await tester.pumpAndSettle();
        expect(engaged, isNot(equals(resting)),
            reason: 'a $operation button gave the pointer no feedback');
        return engaged;
      }

      final BoxDecoration onIdle = await hovered(IuxActionOperation.idle);
      expect(await hovered(IuxActionOperation.succeeded), equals(onIdle));
      expect(await hovered(IuxActionOperation.failed), equals(onIdle));
    });

    testWidgets('IuxAsyncActionButton is where a failure becomes visible',
        (WidgetTester tester) async {
      // The counterpart, so the finding above is not read as "IUX never shows
      // a failure". It does — in the widget that owns the lifecycle, and only
      // when the operation supplied wording.
      late void Function(IuxAsyncOutcome) finish;
      final IuxAsyncActionController controller = IuxAsyncActionController(
        action: const IuxActionDescriptor.primary(
          semantics: IuxActionSemantics(label: 'Pay'),
        ),
        operation: (IuxAsyncActionSignal signal) {
          final Completer<IuxAsyncOutcome> completer =
              Completer<IuxAsyncOutcome>();
          finish = completer.complete;
          return completer.future;
        },
      );
      addTearDown(controller.dispose);

      await host(
        tester,
        IuxAsyncActionButton(
          controller: controller,
          label: 'Pay',
          busyLabel: 'Paying...',
        ),
      );
      await tester.tap(find.text('Pay'));
      await tester.pump();
      finish(const IuxAsyncOutcome.failed(message: 'Card declined'));
      await tester.pumpAndSettle();

      expect(find.text('Card declined'), findsOneWidget);
    });
  });

  group(
      'fixed — the button theme has no switch that does nothing '
      '(IUX-BUTTON-DEAD-001)', () {
    // Three public switches were removed rather than wired: the theme's
    // `elevateFilled`, the resolved `IuxButtonTokens.elevation` it fed, and
    // `IuxButtonTokens.focused`. Each argument is written where the field used
    // to be, in `iux_button_theme.dart`. What survives here is the observable
    // half — that the container is still not where focus or a shadow is
    // expressed, so nobody re-adds one thinking it was an oversight.

    testWidgets('focus is drawn outside the container, never in its decoration',
        (WidgetTester tester) async {
      final FocusNode node = FocusNode(debugLabel: 'ring');
      addTearDown(node.dispose);

      await host(
        tester,
        IuxButton(
          label: 'Save',
          focusNode: node,
          action: idle,
          onActivate: () {},
        ),
      );
      final BoxDecoration resting = decorationOf(tester);

      node.requestFocus();
      await tester.pumpAndSettle();
      expect(node.hasFocus, isTrue);

      expect(
        decorationOf(tester),
        equals(resting),
        reason: 'the container decoration changed on focus. A ring painted '
            'there sits *inside* the control, over the content it identifies '
            '— the failure WCAG 2.2 SC 2.4.11 was added for. It belongs to '
            'IuxFocusRing, which reserves space outside.',
      );
      expect(
        tester.widget<IuxFocusRing>(find.byType(IuxFocusRing)).focused,
        isTrue,
        reason: 'and the ring the user sees is genuinely on',
      );
    });
  });

  group(
      'fixed — a confirmation policy is now honoured or refused by every '
      'one of the four things that accept a descriptor', () {
    // Flipped, not deleted. Each of these asserted the defect
    // IUX-BUTTON-CONFIRM-001 and named the flip it was waiting for. The rule
    // that closed it: whoever honours a policy strips it before delegating, and
    // whatever cannot present one refuses it.
    testWidgets(
        'a plain IuxButton refuses a confirm-before-execution action rather '
        'than deleting', (WidgetTester tester) async {
      // IuxActionDescriptor.destructive defaults to IuxConfirmBeforeExecution.
      // So this call site — the shortest one a caller can write for a deletion
      // — used to read as though the user would be asked, compile, raise
      // nothing, and delete on the first tap. PROJECT_PROMPT §22 asks
      // components to prevent incoherent states; this one was not merely
      // permitted, it was the default shape of the destructive factory.
      int runs = 0;
      await host(
        tester,
        IuxButton(
          label: 'Delete',
          action: const IuxActionDescriptor.destructive(
            semantics: IuxActionSemantics(label: 'Delete everything'),
          ),
          onActivate: () => runs++,
        ),
      );

      expect(
        tester.takeException(),
        isA<AssertionError>().having(
          (AssertionError e) => e.message.toString(),
          'message',
          allOf(
            contains('IuxDestructiveAction'),
            contains('copyWith(confirmation: IuxConfirmationPolicy.none)'),
          ),
        ),
        reason: 'the refusal has to name both ways out: the pattern that asks '
            'the question, and the strip an honourer performs. A refusal that '
            'only says "no" leaves the caller with a compiling call site and '
            'no next step.',
      );
      expect(
        runs,
        0,
        reason: 'and it refuses at build, before any gesture can reach it — '
            'the check fires on the first frame the control exists, so no '
            'debug run can miss it while waiting for somebody to tap.',
      );
    });

    testWidgets('IuxIconButton refuses it through the same check',
        (WidgetTester tester) async {
      // The shared surface is where the check lives, so the labelled button and
      // the icon-only one cannot come to disagree about it — and the icon-only
      // one is the worse case, being the easiest control to hit by accident.
      await host(
        tester,
        IuxIconButton(
          icon: Icons.delete_outline,
          action: const IuxActionDescriptor.destructive(
            semantics: IuxActionSemantics(label: 'Delete everything'),
          ),
          onActivate: () {},
        ),
      );

      expect(tester.takeException(), isA<AssertionError>());
    });

    testWidgets('IuxAsyncActionController refuses one too',
        (WidgetTester tester) async {
      // It evaluates with confirmed: true and presents nothing, so it made the
      // same assumption IuxButton did — one layer up, where a safe button
      // would have been handed the policy again through `descriptor`.
      expect(
        () => IuxAsyncActionController(
          action: const IuxActionDescriptor.destructive(
            semantics: IuxActionSemantics(label: 'Delete everything'),
          ),
          operation: (IuxAsyncActionSignal signal) async =>
              const IuxAsyncOutcome.succeeded(),
        ),
        throwsA(
          isA<AssertionError>().having(
            (AssertionError e) => e.message.toString(),
            'message',
            contains('IuxDestructiveActionController'),
          ),
        ),
        reason: 'and it names the composition that works, rather than leaving '
            'the caller to discover that a confirmation cannot be attached to '
            'an asynchronous action at all',
      );
    });

    testWidgets('IuxDestructiveAction is the one that asks',
        (WidgetTester tester) async {
      int runs = 0;
      final IuxDestructiveActionController controller =
          IuxDestructiveActionController(
        action: const IuxActionDescriptor.destructive(
          semantics: IuxActionSemantics(label: 'Delete everything'),
        ),
        prompt: const IuxConfirmationPrompt(
          title: 'Delete 3 files?',
          consequence: 'They leave this device and the shared folder.',
          confirmLabel: 'Delete',
          keepLabel: 'Keep the files',
        ),
        onConfirmed: () => runs++,
      );
      addTearDown(controller.dispose);

      expect(controller.activate().blockedReason,
          IuxActionBlockedReason.awaitingConfirmation);
      expect(runs, 0);
    });
  });

  group(
      'open defect — cancellation.required is a contract in one widget and '
      'ignored in the others', () {
    testWidgets(
        'IuxAsyncActionButton refuses to promise an exit it will not '
        'draw', (WidgetTester tester) async {
      final IuxAsyncActionController controller = IuxAsyncActionController(
        action: const IuxActionDescriptor.primary(
          semantics: IuxActionSemantics(label: 'Export'),
        ).copyWith(cancellation: IuxActionCancellation.required),
        operation: (IuxAsyncActionSignal signal) async =>
            const IuxAsyncOutcome.succeeded(),
      );
      addTearDown(controller.dispose);

      await host(
        tester,
        IuxAsyncActionButton(
          controller: controller,
          label: 'Export',
          busyLabel: 'Exporting...',
        ),
      );
      expect(tester.takeException(), isA<AssertionError>());
    });

    testWidgets('IuxButton draws no exit and says nothing about it',
        (WidgetTester tester) async {
      await host(
        tester,
        IuxButton(
          label: 'Export',
          busyHint: 'Exporting',
          action: idle.copyWith(
            cancellation: IuxActionCancellation.required,
            operation: IuxActionOperation.inProgress,
          ),
          onActivate: () {},
        ),
      );
      expect(
        tester.takeException(),
        isNull,
        reason: 'DEFECT: the same field means "the user must be offered a way '
            'out" on one widget and nothing at all on another. A long '
            'operation started from an IuxButton is the trap the enum value '
            'exists to prevent.',
      );
      expect(find.byType(IuxButton), findsOneWidget);
    });
  });

  group(
      'open defect — an unavailabilityReason on an available action is '
      'silently dropped', () {
    testWidgets('the wording never reaches anybody',
        (WidgetTester tester) async {
      // The caller wrote a sentence explaining why the control cannot be used
      // and forgot to make it unavailable. Nothing says so: the model accepts
      // the pair and the widget reads the field only in the disabled branch.
      await host(
        tester,
        IuxButton(
          label: 'Publish',
          action: const IuxActionDescriptor(
            semantics: IuxActionSemantics(
              label: 'Publish',
              unavailabilityReason: 'Add a title first',
            ),
          ),
          onActivate: () {},
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Publish')).hint,
        isEmpty,
        reason: 'DEFECT: a written explanation is discarded without a word',
      );
    });
  });

  group('verified — the axes a button actually has to survive', () {
    testWidgets(
        'every combination of the five accessibility preferences, on '
        'both brightnesses, at 200% on a 320-pixel screen',
        (WidgetTester tester) async {
      // 192 configurations. The point is not that one of them is interesting;
      // it is that the previous tests sampled four and this samples all of
      // them, including visualStimulation, which nothing had exercised.
      for (final IuxVisualStimulation stimulation
          in IuxVisualStimulation.values) {
        for (final IuxContrast contrast in IuxContrast.values) {
          for (final IuxDensity density in IuxDensity.values) {
            for (final IuxTouchTargetPreference target
                in IuxTouchTargetPreference.values) {
              for (final IuxMotionPreference motion
                  in IuxMotionPreference.values) {
                for (final Brightness brightness in Brightness.values) {
                  await host(
                    tester,
                    IuxButton(
                      label: 'Confirm and continue',
                      icon: Icons.check,
                      action: idle,
                      onActivate: () {},
                    ),
                    configuration: IuxThemeConfiguration(
                      brightness: brightness,
                      profile: IuxAccessibilityProfile(
                        contrast: contrast,
                        motion: motion,
                        density: density,
                        touchTarget: target,
                        visualStimulation: stimulation,
                      ),
                    ),
                    textScale: 2,
                    size: const Size(320, 640),
                  );
                  final String where = '$brightness/${contrast.name}/'
                      '${density.name}/${target.name}/${motion.name}/'
                      '${stimulation.name}';
                  expect(tester.takeException(), isNull, reason: where);
                  expect(
                    tester.getSize(find.byType(AnimatedContainer)).height,
                    greaterThanOrEqualTo(IuxTouchTarget.minimum),
                    reason: where,
                  );
                }
              }
            }
          }
        }
      }
    });

    testWidgets('a label wraps rather than clips all the way to 300%',
        (WidgetTester tester) async {
      // 200% is the WCAG floor, not the largest scale Android offers.
      double previous = 0;
      for (final double scale in <double>[1, 1.5, 2, 3]) {
        await host(
          tester,
          IuxButton(
            label: 'Confirm and continue',
            icon: Icons.check,
            action: idle,
            onActivate: () {},
          ),
          textScale: scale,
          size: const Size(320, 640),
        );
        expect(tester.takeException(), isNull, reason: 'at $scale');
        final double height =
            tester.getSize(find.byType(AnimatedContainer)).height;
        expect(
          height,
          greaterThan(previous),
          reason: 'at $scale the button did not grow, so the label was '
              'squeezed rather than wrapped',
        );
        previous = height;
        final Text text = tester.widget<Text>(find.byType(Text));
        expect(text.overflow, isNot(TextOverflow.ellipsis));
        expect(text.maxLines, isNull);
      }
    });

    testWidgets(
        'an icon action stays square and keeps its glyph inside the '
        'target at 300%', (WidgetTester tester) async {
      for (final double scale in <double>[1, 2, 3]) {
        await host(
          tester,
          IuxIconButton(
            icon: Icons.close,
            action: const IuxActionDescriptor(
              semantics: IuxActionSemantics(label: 'Close'),
            ),
            onActivate: () {},
          ),
          textScale: scale,
          size: const Size(320, 640),
        );
        final Size glyph = tester.getSize(find.byIcon(Icons.close));
        final Size target = tester.getSize(find.byType(AnimatedContainer));
        expect(target.width, closeTo(target.height, 0.01), reason: 'at $scale');
        expect(glyph.height, lessThan(target.height), reason: 'at $scale');
        expect(
          target.height,
          greaterThanOrEqualTo(IuxTouchTarget.minimum),
          reason: 'at $scale',
        );
      }
    });

    testWidgets('two adjacent buttons keep the minimum separation',
        (WidgetTester tester) async {
      await host(
        tester,
        const IuxTargetSpacing(
          children: <Widget>[
            IuxButton(
              label: 'Save',
              action: IuxActionDescriptor(
                semantics: IuxActionSemantics(label: 'Save'),
              ),
              onActivate: _noop,
            ),
            IuxButton(
              label: 'Discard',
              action: IuxActionDescriptor(
                semantics: IuxActionSemantics(label: 'Discard'),
              ),
              onActivate: _noop,
            ),
          ],
        ),
      );
      final Rect first = tester.getRect(find.byType(AnimatedContainer).first);
      final Rect second = tester.getRect(find.byType(AnimatedContainer).last);
      expect(
        second.top - first.bottom,
        greaterThanOrEqualTo(kIuxMinimumTargetSpacing),
      );
    });

    testWidgets('expand asks for width in an unbounded row and fails loudly',
        (WidgetTester tester) async {
      // Documented behaviour, previously unmeasured. Quietly ignoring what the
      // caller asked for would be worse. The failure is collected rather than
      // let through, so one deliberate breakage does not bury the run in a
      // hundred lines of render-tree dump.
      final List<FlutterErrorDetails> reported = <FlutterErrorDetails>[];
      final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
      FlutterError.onError = reported.add;
      addTearDown(() => FlutterError.onError = previous);

      await host(
        tester,
        Row(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: IuxButton(
                  label: 'Continue',
                  action: idle,
                  expand: true,
                  onActivate: () {},
                ),
              ),
            ),
          ],
        ),
      );

      FlutterError.onError = previous;
      expect(
        reported,
        isNotEmpty,
        reason: 'an unbounded width has nothing for expand to take, and the '
            'button says so rather than pretending',
      );
    });
  });

  group(
      'verified — disabled and hovered stay readable everywhere, not only '
      'in the one combination that was sampled', () {
    // test/themes measures resting and pressed for every variant and intent,
    // and disabled for exactly one pair. The disabled branch of the resolver
    // puts an unfilled variant on colors.surface.base rather than on the
    // intent's own disabled fill, which is a pairing nothing had measured.
    testWidgets(
        'disabled holds 3:1 for every variant and intent on all four '
        'profiles', (WidgetTester tester) async {
      await _forEveryPalette(tester, disabled: true, hovered: false,
          check: (IuxButtonTokens tokens, String where) {
        expect(
          ContrastMetric.ratio(tokens.foreground, tokens.background),
          greaterThanOrEqualTo(ContrastMetric.nonText),
          reason: where,
        );
      });
    });

    testWidgets(
        'hovered holds 4.5:1 for every variant and intent on all four '
        'profiles', (WidgetTester tester) async {
      await _forEveryPalette(tester, disabled: false, hovered: true,
          check: (IuxButtonTokens tokens, String where) {
        expect(
          ContrastMetric.ratio(tokens.foreground, tokens.background),
          greaterThanOrEqualTo(ContrastMetric.normalText),
          reason: where,
        );
      });
    });
  });

  group('verified — combinations the model accepts that mean nothing', () {
    // §19 asks that every public API be justified. An orthogonal model with
    // nine dimensions has a large product space, and these are the corners of
    // it that no assertion covers. None of them throws today; the list is the
    // finding, and the test is what stops it changing without anyone deciding
    // to change it.
    void accepts(String description, VoidCallback build) {
      test(description, () => expect(build, returnsNormally));
    }

    accepts('a reversible action that also asks to be confirmed', () {
      const IuxActionDescriptor(
        semantics: IuxActionSemantics(label: 'Archive'),
        confirmation: IuxConfirmBeforeExecution(),
      );
    });

    accepts('an irreversible dismiss, though dismissing loses nothing', () {
      const IuxActionDescriptor(
        semantics: IuxActionSemantics(label: 'Close'),
        role: IuxActionRole.dismiss,
        reversibility: IuxActionReversibility.irreversible,
      );
    });

    // A case for `IuxConfirmByHold` stood here. The policy was removed in
    // IUX-039 because nothing in the package honoured it — including this
    // button, which ran the action on the first ordinary tap.

    accepts('an unavailable action that has already succeeded', () {
      const IuxActionDescriptor(
        semantics: IuxActionSemantics(label: 'Save'),
        availability: IuxActionAvailability.disabled,
        operation: IuxActionOperation.succeeded,
      );
    });

    accepts('an unavailable action with nothing to say for itself', () {
      // Permitted on purpose — a reason is not always available — but it is
      // the one the documentation calls essential, and nothing enforces it.
      const IuxActionDescriptor(
        semantics: IuxActionSemantics(label: 'Publish'),
        availability: IuxActionAvailability.disabled,
      );
    });

    test('the pattern refuses the one the model lets through', () {
      // Same descriptor, two verdicts: the model accepts a reversible action
      // asking for confirmation, and IuxDestructiveActionController explains
      // at length why it cannot mean anything. The rule exists; it just does
      // not live where the value is built.
      expect(
        () => IuxDestructiveActionController(
          action: const IuxActionDescriptor.destructive(
            semantics: IuxActionSemantics(label: 'Archive'),
            reversibility: IuxActionReversibility.reversible,
          ),
          prompt: const IuxConfirmationPrompt(
            title: 'Archive?',
            consequence: 'It moves out of the inbox.',
            confirmLabel: 'Archive',
            keepLabel: 'Keep it here',
          ),
          onConfirmed: () {},
        ),
        throwsAssertionError,
      );
    });
  });
}

/// A callback that does nothing, so a scenario can build several buttons at
/// once without each one needing a closure of its own.
void _noop() {}

/// Resolves the palette for every variant and intent on every theme profile.
Future<void> _forEveryPalette(
  WidgetTester tester, {
  required bool disabled,
  required bool hovered,
  required void Function(IuxButtonTokens tokens, String where) check,
}) async {
  const List<IuxThemeConfiguration> profiles = <IuxThemeConfiguration>[
    IuxThemeConfiguration(),
    IuxThemeConfiguration(brightness: Brightness.dark),
    IuxThemeConfiguration(
      profile: IuxAccessibilityProfile(contrast: IuxContrast.high),
    ),
    IuxThemeConfiguration(
      brightness: Brightness.dark,
      profile: IuxAccessibilityProfile(contrast: IuxContrast.high),
    ),
  ];

  for (final IuxThemeConfiguration configuration in profiles) {
    for (final IuxActionIntent intent in IuxActionIntent.values) {
      for (final IuxButtonVariant variant in IuxButtonVariant.values) {
        // Two pairs are refused by design. Tonal refuses a destructive
        // intent; and since IUX-039 `filled` refuses secondary and tertiary,
        // which the semantic layer models unfilled — the combination used to
        // be accepted and resolved, measured, to a text button.
        if (variant == IuxButtonVariant.tonal &&
            intent == IuxActionIntent.destructive) {
          continue;
        }
        if (variant == IuxButtonVariant.filled &&
            (intent == IuxActionIntent.secondary ||
                intent == IuxActionIntent.tertiary)) {
          continue;
        }
        late IuxButtonTokens tokens;
        await tester.pumpWidget(
          MaterialApp(
            theme: IuxTheme.fromConfiguration(configuration),
            home: Builder(
              builder: (BuildContext context) {
                tokens = IuxButtonResolver.resolve(
                  context,
                  IuxActionDescriptor(
                    semantics: const IuxActionSemantics(label: 'Save'),
                    intent: intent,
                    availability: disabled
                        ? IuxActionAvailability.disabled
                        : IuxActionAvailability.enabled,
                  ),
                  variant: variant,
                  hovered: hovered,
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        check(
          tokens,
          '${variant.name}/${intent.name} on $configuration measured '
          '${ContrastMetric.ratio(tokens.foreground, tokens.background).toStringAsFixed(2)}:1',
        );
      }
    }
  }
}
