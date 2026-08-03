import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';
import 'package:iux_flutter/src/actions/iux_async_action.dart';
import 'package:iux_flutter/src/components/button/iux_async_button.dart';

/// The four conditions every IUX component is held to.
const List<IuxThemeConfiguration> _profiles = <IuxThemeConfiguration>[
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

/// Records what a component asked the feedback engine to deliver.
///
/// Substituted for the real controller so the assertion is about what the
/// button *requested*, not about whether a device happened to vibrate.
class _RecordingFeedback extends IuxFeedbackController {
  final List<IuxFeedbackEvent> events = <IuxFeedbackEvent>[];

  @override
  Future<IuxFeedbackOutcome> emit(
    BuildContext context,
    IuxFeedbackEvent event,
  ) async {
    events.add(event);
    return const IuxFeedbackOutcome(
      hapticPerformed: false,
      announced: false,
      suppressedAsDuplicate: false,
    );
  }
}

void main() {
  const IuxActionSemantics paySemantics = IuxActionSemantics(label: 'Pay');
  const IuxActionDescriptor pay = IuxActionDescriptor.primary(
    semantics: paySemantics,
  );

  late List<Completer<IuxAsyncOutcome>> completers;
  late List<IuxAsyncActionSignal> signals;

  setUp(() {
    completers = <Completer<IuxAsyncOutcome>>[];
    signals = <IuxAsyncActionSignal>[];
  });

  /// A controller whose run finishes only when the test says so.
  IuxAsyncActionController controllerFor({IuxActionDescriptor action = pay}) {
    final IuxAsyncActionController controller = IuxAsyncActionController(
      action: action,
      operation: (IuxAsyncActionSignal signal) {
        signals.add(signal);
        final Completer<IuxAsyncOutcome> completer =
            Completer<IuxAsyncOutcome>();
        completers.add(completer);
        return completer.future;
      },
    );
    addTearDown(controller.dispose);
    return controller;
  }

  Future<void> pump(
    WidgetTester tester, {
    required IuxAsyncActionController controller,
    String label = 'Pay',
    String busyLabel = 'Paying...',
    String? cancelLabel,
    IuxThemeConfiguration configuration = const IuxThemeConfiguration(),
    TextDirection direction = TextDirection.ltr,
    double textScale = 1,
    Size size = const Size(400, 800),
    bool expand = false,
    IuxFeedbackController? feedback,
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
            child: IuxFeedbackScope(
              controller: feedback,
              child: Scaffold(
                body: Center(
                  child: SingleChildScrollView(
                    child: IuxAsyncActionButton(
                      controller: controller,
                      label: label,
                      busyLabel: busyLabel,
                      cancelLabel: cancelLabel,
                      expand: expand,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('a pending operation is perceivable without motion', () {
    testWidgets('the label becomes the busy label while the run is going',
        (WidgetTester tester) async {
      final IuxAsyncActionController controller = controllerFor();
      await pump(tester, controller: controller);

      expect(find.text('Pay'), findsOneWidget);
      await tester.tap(find.text('Pay'));
      await tester.pump();

      expect(find.text('Paying...'), findsOneWidget);
      expect(find.text('Pay'), findsNothing);

      completers.single.complete(const IuxAsyncOutcome.succeeded());
      await tester.pumpAndSettle();
    });

    testWidgets('the busy state survives a preference for no motion at all',
        (WidgetTester tester) async {
      // Under IuxMotionPreference.none a spinner is not an option, and colour
      // alone is not perceivable by everyone. A word is both.
      final IuxAsyncActionController controller = controllerFor();
      await pump(
        tester,
        controller: controller,
        configuration: const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(motion: IuxMotionPreference.none),
        ),
      );

      await tester.tap(find.text('Pay'));
      await tester.pump();

      expect(find.text('Paying...'), findsOneWidget);
      expect(
        tester
            .widget<AnimatedContainer>(find.byType(AnimatedContainer))
            .duration,
        Duration.zero,
        reason: 'nothing may animate here, so the word has to carry the state',
      );

      completers.single.complete(const IuxAsyncOutcome.succeeded());
      await tester.pumpAndSettle();
    });

    testWidgets('a running button announces that it is busy',
        (WidgetTester tester) async {
      // Silence is indistinguishable from a control that did nothing.
      final IuxAsyncActionController controller = controllerFor();
      await pump(tester, controller: controller);

      await tester.tap(find.text('Pay'));
      await tester.pump();

      // In the caller's own words. The framework composes no wording: the
      // accessible name still comes from the descriptor, so the busy state
      // has to be announced through the hint the caller supplied.
      expect(
        tester.getSemantics(find.bySemanticsLabel('Pay')).hint,
        contains('Paying...'),
      );

      completers.single.complete(const IuxAsyncOutcome.succeeded());
      await tester.pumpAndSettle();
    });
  });

  group('a second activation while running is dropped', () {
    testWidgets('a double tap starts the operation once',
        (WidgetTester tester) async {
      // This is what stops a double-tapped "Pay" charging twice.
      final IuxAsyncActionController controller = controllerFor();
      await pump(tester, controller: controller);

      await tester.tap(find.text('Pay'));
      await tester.pump();
      await tester.tap(find.text('Paying...'), warnIfMissed: false);
      await tester.pump();

      expect(completers, hasLength(1));

      completers.single.complete(const IuxAsyncOutcome.succeeded());
      await tester.pumpAndSettle();
    });

    testWidgets('a genuine second attempt after the first is allowed through',
        (WidgetTester tester) async {
      final IuxAsyncActionController controller = controllerFor();
      await pump(tester, controller: controller);

      await tester.tap(find.text('Pay'));
      await tester.pump();
      completers.single.complete(
        const IuxAsyncOutcome.failed(message: 'Card declined'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pay'));
      await tester.pump();
      expect(completers, hasLength(2));

      completers.last.complete(const IuxAsyncOutcome.succeeded());
      await tester.pumpAndSettle();
    });
  });

  group('cancellation is offered exactly as the action declared it', () {
    testWidgets('no cancel control appears before the run starts',
        (WidgetTester tester) async {
      final IuxAsyncActionController controller = controllerFor(
        action: pay.copyWith(cancellation: IuxActionCancellation.supported),
      );
      await pump(tester, controller: controller, cancelLabel: 'Stop');

      expect(find.text('Stop'), findsNothing);
    });

    testWidgets('it appears while running and passes the request on',
        (WidgetTester tester) async {
      final IuxAsyncActionController controller = controllerFor(
        action: pay.copyWith(cancellation: IuxActionCancellation.supported),
      );
      await pump(tester, controller: controller, cancelLabel: 'Stop');

      await tester.tap(find.text('Pay'));
      await tester.pump();
      expect(find.text('Stop'), findsOneWidget);

      await tester.tap(find.text('Stop'));
      await tester.pump();
      expect(signals.single.isCancellationRequested, isTrue);

      completers.single.complete(const IuxAsyncOutcome.cancelled());
      await tester.pumpAndSettle();
      expect(find.text('Pay'), findsOneWidget,
          reason: 'a cancelled run leaves the action ready to be tried again');
    });

    testWidgets('an action that must be stoppable refuses to hide the way out',
        (WidgetTester tester) async {
      // IuxActionCancellation.required exists for operations long enough that
      // no exit is a trap. Promising one and drawing none is worse than not
      // promising.
      final IuxAsyncActionController controller = controllerFor(
        action: pay.copyWith(cancellation: IuxActionCancellation.required),
      );
      await pump(tester, controller: controller);

      expect(tester.takeException(), isA<AssertionError>());
    });

    testWidgets('a cancel control for an unstoppable action is refused',
        (WidgetTester tester) async {
      final IuxAsyncActionController controller = controllerFor();
      await pump(tester, controller: controller, cancelLabel: 'Stop');

      expect(tester.takeException(), isA<AssertionError>());
    });

    testWidgets('a full-width button cannot also carry a cancel control',
        (WidgetTester tester) async {
      final IuxAsyncActionController controller = controllerFor(
        action: pay.copyWith(cancellation: IuxActionCancellation.supported),
      );
      expect(
        () => IuxAsyncActionButton(
          controller: controller,
          label: 'Pay',
          busyLabel: 'Paying...',
          cancelLabel: 'Stop',
          expand: true,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('a failure is never signalled by colour alone', () {
    testWidgets('the message the operation supplied is shown',
        (WidgetTester tester) async {
      final IuxAsyncActionController controller = controllerFor();
      await pump(tester, controller: controller);

      await tester.tap(find.text('Pay'));
      await tester.pump();
      completers.single.complete(
        const IuxAsyncOutcome.failed(message: 'Card declined'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Card declined'), findsOneWidget);
    });

    testWidgets('the message is a live region, so it reaches a screen reader',
        (WidgetTester tester) async {
      final IuxAsyncActionController controller = controllerFor();
      await pump(tester, controller: controller);

      await tester.tap(find.text('Pay'));
      await tester.pump();
      completers.single.complete(
        const IuxAsyncOutcome.failed(message: 'Card declined'),
      );
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (Widget widget) =>
              widget is Semantics && (widget.properties.liveRegion ?? false),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a raised exception shows no message, since none was written',
        (WidgetTester tester) async {
      // The framework will not turn a stack trace into a sentence for a user.
      final IuxAsyncActionController controller = controllerFor();
      await pump(tester, controller: controller);

      await tester.tap(find.text('Pay'));
      await tester.pump();
      completers.single.completeError(StateError('socket closed'));
      await tester.pumpAndSettle();

      expect(controller.value.hasFailed, isTrue);
      expect(
        find.byWidgetPredicate(
          (Widget widget) =>
              widget is Semantics && (widget.properties.liveRegion ?? false),
        ),
        findsNothing,
      );
      expect(find.text('Pay'), findsOneWidget);
    });
  });

  group('feedback is the caller\'s event, delivered by the engine', () {
    testWidgets('the event the operation returned is emitted once',
        (WidgetTester tester) async {
      const IuxFeedbackEvent event = IuxFeedbackEvent.success(
        semanticMessage: 'Payment taken',
      );
      final _RecordingFeedback feedback = _RecordingFeedback();
      final IuxAsyncActionController controller = controllerFor();
      await pump(tester, controller: controller, feedback: feedback);

      await tester.tap(find.text('Pay'));
      await tester.pump();
      completers.single.complete(
        const IuxAsyncOutcome.succeeded(feedback: event),
      );
      await tester.pumpAndSettle();

      expect(feedback.events, <IuxFeedbackEvent>[event]);

      // A rebuild is not a second result.
      await tester.pump();
      await tester.pumpAndSettle();
      expect(feedback.events, hasLength(1));
    });

    testWidgets('an outcome carrying no event produces no feedback',
        (WidgetTester tester) async {
      final _RecordingFeedback feedback = _RecordingFeedback();
      final IuxAsyncActionController controller = controllerFor();
      await pump(tester, controller: controller, feedback: feedback);

      await tester.tap(find.text('Pay'));
      await tester.pump();
      completers.single.complete(const IuxAsyncOutcome.succeeded());
      await tester.pumpAndSettle();

      expect(feedback.events, isEmpty);
    });

    testWidgets('the button produces no haptic of its own',
        (WidgetTester tester) async {
      final List<MethodCall> platform = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform,
              (MethodCall call) async {
        platform.add(call);
        return null;
      });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );

      final IuxAsyncActionController controller = controllerFor();
      await pump(tester, controller: controller);

      await tester.tap(find.text('Pay'));
      await tester.pump();
      completers.single.complete(const IuxAsyncOutcome.succeeded());
      await tester.pumpAndSettle();

      expect(
        platform.where((MethodCall c) => c.method.startsWith('HapticFeedback')),
        isEmpty,
      );
    });
  });

  group('the widget carries no business meaning', () {
    testWidgets('it never advances the operation itself',
        (WidgetTester tester) async {
      final IuxAsyncActionController controller = controllerFor();
      await pump(tester, controller: controller);

      await tester.tap(find.text('Pay'));
      await tester.pumpAndSettle();

      expect(controller.value.operation, IuxActionOperation.inProgress,
          reason: 'only the operation may say that it finished');
      expect(find.text('Paying...'), findsOneWidget);

      completers.single.complete(const IuxAsyncOutcome.succeeded());
      await tester.pumpAndSettle();
    });

    testWidgets('a result arriving after the widget is gone breaks nothing',
        (WidgetTester tester) async {
      final IuxAsyncActionController controller = controllerFor();
      await pump(tester, controller: controller);

      await tester.tap(find.text('Pay'));
      await tester.pump();

      await tester.pumpWidget(const SizedBox.shrink());
      completers.single.complete(const IuxAsyncOutcome.succeeded());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('resilience', () {
    testWidgets('it survives a 200% text scale on a small screen',
        (WidgetTester tester) async {
      final IuxAsyncActionController controller = controllerFor(
        action: pay.copyWith(cancellation: IuxActionCancellation.supported),
      );
      await pump(
        tester,
        controller: controller,
        label: 'Confirm and pay',
        busyLabel: 'Taking your payment...',
        cancelLabel: 'Stop the payment',
        textScale: 2,
        size: const Size(320, 480),
      );

      await tester.tap(find.text('Confirm and pay'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Taking your payment...'), findsOneWidget);
      expect(find.text('Stop the payment'), findsOneWidget);

      completers.single.complete(
        const IuxAsyncOutcome.failed(
          message: 'The payment could not be taken. Check the card and try '
              'again.',
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('it renders right-to-left', (WidgetTester tester) async {
      final IuxAsyncActionController controller = controllerFor();
      await pump(
        tester,
        controller: controller,
        label: 'ادفع',
        busyLabel: 'جاري الدفع...',
        direction: TextDirection.rtl,
      );

      await tester.tap(find.text('ادفع'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('جاري الدفع...'), findsOneWidget);

      completers.single.complete(
        const IuxAsyncOutcome.failed(message: 'فشل الدفع'),
      );
      await tester.pumpAndSettle();
      expect(find.text('فشل الدفع'), findsOneWidget);
    });

    testWidgets('it renders on every theme profile',
        (WidgetTester tester) async {
      for (final IuxThemeConfiguration configuration in _profiles) {
        final IuxAsyncActionController controller = controllerFor();
        await pump(
          tester,
          controller: controller,
          configuration: configuration,
        );

        await tester.tap(find.text('Pay'));
        await tester.pump();
        expect(find.text('Paying...'), findsOneWidget);

        completers.last.complete(
          const IuxAsyncOutcome.failed(message: 'Card declined'),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Card declined'), findsOneWidget);
      }
    });

    testWidgets('a full-width button keeps the height of a button',
        (WidgetTester tester) async {
      final IuxAsyncActionController controller = controllerFor();
      await pump(tester, controller: controller, expand: true);

      final Size size = tester.getSize(find.byType(IuxAsyncActionButton));
      expect(size.height, greaterThanOrEqualTo(IuxTouchTarget.minimum));
      expect(size.height, lessThan(120),
          reason: 'a button as tall as the screen is a banner, not a button');
    });
  });
}
