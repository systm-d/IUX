import 'dart:async';

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
      'open defect — a running action is not focusable, so activating it '
      'with the keyboard throws the user out of their place', () {
    // Measured, not read. IuxButton wires `canRequestFocus` to
    // `action.isActivatable`, and under the default
    // IuxActionRepeatPolicy.ignoreWhileInProgress that is false for the whole
    // run. Availability and focusability are not the same question: an action
    // that cannot be started *right now* is still the control the user is
    // standing on.
    //
    // Distinct from IUX-A11Y-FOCUS-001, which is about the semantics node
    // declaring no focusable state. This is real focus, and it moves.

    testWidgets('activating with Enter moves focus to the previous control',
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
        'Before',
        reason: 'DEFECT: pressing Enter on the action sent focus backwards to '
            'the control above it. The user asked to run something and was '
            'moved somewhere they did not choose.',
      );

      // And the running control cannot be reached again: one Tab from
      // "Before" skips straight past it.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedLabel(), 'After');

      finish(const IuxAsyncOutcome.succeeded());
      await tester.pumpAndSettle();
      expect(
        focusedLabel(),
        'After',
        reason: 'DEFECT: the run finished and focus never came back. A '
            'keyboard user resumes two controls away from where they were.',
      );
    });

    testWidgets(
        'the repeat policy alone decides whether a busy button keeps '
        'its focus', (WidgetTester tester) async {
      // The proof that this is a conflation rather than a deliberate choice:
      // the same running action stays focusable when its repeat policy happens
      // to allow a second activation. Nothing about focus changed.
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
        isFalse,
        reason: 'DEFECT: the default repeat policy removes the control from '
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

  group('open defect — a running button announces itself as disabled', () {
    testWidgets(
        'its node is that of a disabled control, and the only thing '
        'separating the two is a hint the caller may omit',
        (WidgetTester tester) async {
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
      // IuxButton and there is no assertion pushing a caller towards it.
      for (final String name in <String>['Busy', 'Off']) {
        expect(
          tester.getSemantics(find.bySemanticsLabel(name)),
          matchesSemantics(
            label: name,
            isButton: true,
            isEnabled: false,
            hasEnabledState: true,
            hasTapAction: false,
          ),
          reason: 'DEFECT: "$name" — a working control and an unavailable one '
              'produce the same node. WCAG 2.2 SC 4.1.2 asks for the state a '
              'control is actually in.',
        );
      }
    });

    testWidgets('a supplied busyHint is the whole of the difference',
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
          isEnabled: false,
          hasEnabledState: true,
          hasTapAction: false,
        ),
        reason: 'the wording explains the state; the state itself still reads '
            'as unavailable',
      );
    });
  });

  group('open defect — an operation that finished is invisible on IuxButton',
      () {
    testWidgets('succeeded and failed render exactly like idle',
        (WidgetTester tester) async {
      // IuxButtonStateResolver publishes IuxButtonState.success and .error and
      // documents a precedence for them ("a result outranks a pointer
      // position"). Neither reaches the screen: _resolveColors only branches
      // on pressed and hovered, so the three palettes are the same object.
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
        reason: 'DEFECT: a failed action is pixel-identical to one that has '
            'not run. Component standard §6 asks an error state for "a '
            'message, never a colour alone"; this is not even a colour.',
      );
      expect(
        painted[IuxActionOperation.succeeded],
        equals(painted[IuxActionOperation.idle]),
      );
      expect(
        announced[IuxActionOperation.failed],
        equals(announced[IuxActionOperation.idle]),
        reason: 'DEFECT: and nothing reaches a screen reader either.',
      );
      expect(
        announced[IuxActionOperation.succeeded],
        equals(announced[IuxActionOperation.idle]),
      );
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

  group('open defect — elevation is a public knob with nothing behind it', () {
    testWidgets('turning elevateFilled on changes nothing a user can perceive',
        (WidgetTester tester) async {
      // IuxButtonTheme.elevateFilled is settable, IuxButtonResolver computes
      // IuxButtonTokens.elevation from it, and no widget in the library reads
      // that field. §19: an API nobody needs is a defect, and one that looks
      // like it works is worse than one that is missing.
      final ThemeData flat = IuxTheme.light();
      final ThemeData raised = flat.copyWith(
        extensions: <ThemeExtension<Object?>>{
          ...flat.extensions.values.cast<ThemeExtension<Object?>>(),
          const IuxButtonTheme(elevateFilled: true),
        },
      );

      Future<BoxDecoration> render(ThemeData theme) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: Center(
                child: IuxButton(
                  label: 'Save',
                  action: idle,
                  variant: IuxButtonVariant.filled,
                  onActivate: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        return decorationOf(tester);
      }

      final BoxDecoration off = await render(flat);
      final BoxDecoration on = await render(raised);

      expect(on.boxShadow, isNull);
      expect(
        on,
        equals(off),
        reason: 'DEFECT: elevateFilled: true and elevateFilled: false produce '
            'the same decoration. The theme asked for a shadow and got '
            'nothing, silently.',
      );
    });

    testWidgets('and the resolver still reports an elevation it computed',
        (WidgetTester tester) async {
      late IuxButtonTokens tokens;
      final ThemeData flat = IuxTheme.light();
      await tester.pumpWidget(
        MaterialApp(
          theme: flat.copyWith(
            extensions: <ThemeExtension<Object?>>{
              ...flat.extensions.values.cast<ThemeExtension<Object?>>(),
              const IuxButtonTheme(elevateFilled: true),
            },
          ),
          home: Builder(
            builder: (BuildContext context) {
              tokens = IuxButtonResolver.resolve(context, idle);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tokens.elevation,
        greaterThan(0),
        reason: 'the value exists and travels; only its consumer is missing',
      );
    });
  });

  group('open defect — IuxButtonTokens.focused is never set by a button', () {
    testWidgets('the focus indicator comes from the runtime, not the tokens',
        (WidgetTester tester) async {
      // IUX-BUTTON-002 records that focus is "carried separately by
      // IuxButtonTokens.focused and drawn additively by the runtime". Only the
      // second half happens: no button passes `focused:` to the resolver, so
      // the field is false for every button ever built. The ring is real and
      // comes from IuxFocusable; the token is dead weight on a public type.
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
        reason: 'the container is untouched by focus — which is correct, but '
            'it is also why nothing would notice if the token disappeared',
      );
      // The ring itself is present, drawn outside the container.
      expect(find.byType(IuxFocusRing), findsOneWidget);
    });
  });

  group(
      'open defect — a confirmation policy is honoured by exactly one of '
      'the four things that accept a descriptor', () {
    testWidgets(
        'a plain IuxButton runs a confirm-before-execution action on '
        'the first tap', (WidgetTester tester) async {
      // IuxActionDescriptor.destructive defaults to IuxConfirmBeforeExecution.
      // So this call site — which is the shortest one a caller can write for a
      // deletion — reads as though the user will be asked, compiles, raises
      // nothing, and deletes on the first tap. PROJECT_PROMPT §22 asks
      // components to prevent incoherent states; this one is not merely
      // permitted, it is the default shape of the destructive factory.
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

      await tester.tap(find.byType(IuxButton));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'nothing objected');
      expect(
        runs,
        1,
        reason: 'DEFECT: the descriptor asked to be confirmed and the action '
            'ran unasked. IuxDestructiveAction is the only widget that routes '
            'activation through a policy evaluated with confirmed: false.',
      );
    });

    testWidgets('IuxAsyncActionController makes the same assumption',
        (WidgetTester tester) async {
      int runs = 0;
      final IuxAsyncActionController controller = IuxAsyncActionController(
        action: const IuxActionDescriptor.destructive(
          semantics: IuxActionSemantics(label: 'Delete everything'),
        ),
        operation: (IuxAsyncActionSignal signal) async {
          runs++;
          return const IuxAsyncOutcome.succeeded();
        },
      );
      addTearDown(controller.dispose);

      expect(controller.activate().isAccepted, isTrue);
      await tester.pump();
      expect(runs, 1);
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

    accepts('hold-to-confirm on an action that must also be stoppable', () {
      const IuxActionDescriptor(
        semantics: IuxActionSemantics(label: 'Wipe the device'),
        confirmation: IuxConfirmByHold(),
        cancellation: IuxActionCancellation.required,
      );
    });

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
        // Tonal refuses a destructive intent by design.
        if (variant == IuxButtonVariant.tonal &&
            intent == IuxActionIntent.destructive) {
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
