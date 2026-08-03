import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

void main() {
  const IuxActionSemantics saveSemantics = IuxActionSemantics(label: 'Save');
  const IuxActionDescriptor idle = IuxActionDescriptor(
    semantics: saveSemantics,
    intent: IuxActionIntent.primary,
  );

  Future<int> pump(
    WidgetTester tester, {
    IuxActionDescriptor action = idle,
    String label = 'Save',
    IuxButtonVariant? variant,
    IuxThemeConfiguration configuration = const IuxThemeConfiguration(),
    TextDirection direction = TextDirection.ltr,
    double textScale = 1,
    Size size = const Size(400, 800),
    bool autofocus = false,
    void Function()? onActivate,
    List<int>? counter,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final List<int> calls = counter ?? <int>[];
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
              body: Center(
                child: IuxButton(
                  label: label,
                  action: action,
                  variant: variant,
                  autofocus: autofocus,
                  onActivate: onActivate ?? () => calls.add(calls.length),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return calls.length;
  }

  group('activation', () {
    testWidgets('one accepted gesture calls back exactly once',
        (WidgetTester tester) async {
      final List<int> calls = <int>[];
      await pump(tester, counter: calls);

      await tester.tap(find.byType(IuxButton));
      await tester.pumpAndSettle();

      expect(calls, hasLength(1));
    });

    testWidgets('a disabled action produces no callback',
        (WidgetTester tester) async {
      final List<int> calls = <int>[];
      await pump(
        tester,
        action: idle.copyWith(availability: IuxActionAvailability.disabled),
        counter: calls,
      );

      await tester.tap(find.byType(IuxButton), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(calls, isEmpty);
    });

    testWidgets('a second tap while running is dropped',
        (WidgetTester tester) async {
      // This is what prevents a double-tapped "Pay" from charging twice.
      final List<int> calls = <int>[];
      await pump(
        tester,
        action: idle.copyWith(operation: IuxActionOperation.inProgress),
        counter: calls,
      );

      await tester.tap(find.byType(IuxButton), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(calls, isEmpty);
    });

    testWidgets('an explicit allow policy lets a repeat through',
        (WidgetTester tester) async {
      final List<int> calls = <int>[];
      await pump(
        tester,
        action: idle.copyWith(
          operation: IuxActionOperation.inProgress,
          repeatPolicy: IuxActionRepeatPolicy.allow,
        ),
        counter: calls,
      );

      await tester.tap(find.byType(IuxButton));
      await tester.pumpAndSettle();

      expect(calls, hasLength(1));
    });

    testWidgets('two taps are two activations', (WidgetTester tester) async {
      final List<int> calls = <int>[];
      await pump(tester, counter: calls);

      await tester.tap(find.byType(IuxButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(IuxButton));
      await tester.pumpAndSettle();

      expect(calls, hasLength(2),
          reason: 'the widget must not swallow a genuine second gesture');
    });
  });

  group('keyboard', () {
    testWidgets('focus activates with Enter and Space',
        (WidgetTester tester) async {
      final List<int> calls = <int>[];
      await pump(tester, autofocus: true, counter: calls);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(calls, hasLength(2));
    });

    testWidgets('a disabled button is skipped by focus traversal',
        (WidgetTester tester) async {
      await pump(
        tester,
        action: idle.copyWith(availability: IuxActionAvailability.disabled),
        autofocus: true,
      );
      final Focus focus = tester.widget<Focus>(find.byType(Focus).first);
      expect(focus.canRequestFocus, isFalse);
    });
  });

  group('semantics', () {
    testWidgets('it is announced as an enabled button with its name',
        (WidgetTester tester) async {
      await pump(tester);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Save')),
        matchesSemantics(
          label: 'Save',
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
        ),
      );
    });

    testWidgets('a disabled button announces its state',
        (WidgetTester tester) async {
      await pump(
        tester,
        action: idle.copyWith(availability: IuxActionAvailability.disabled),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Save')),
        matchesSemantics(
          label: 'Save',
          isButton: true,
          isEnabled: false,
          hasEnabledState: true,
        ),
      );
    });

    testWidgets('an unavailable button explains itself',
        (WidgetTester tester) async {
      // A greyed control with no explanation leaves the user unable to tell
      // whether they did something wrong or the feature does not apply.
      await pump(
        tester,
        action: const IuxActionDescriptor(
          semantics: IuxActionSemantics(
            label: 'Publish',
            unavailabilityReason: 'Add a title first',
          ),
          availability: IuxActionAvailability.disabled,
        ),
        label: 'Publish',
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Publish')).hint,
        contains('Add a title first'),
      );
    });

    testWidgets('a running button says so, since silence is ambiguous',
        (WidgetTester tester) async {
      await pump(
        tester,
        action: idle.copyWith(operation: IuxActionOperation.inProgress),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Save')).hint,
        contains('In progress'),
      );
    });

    testWidgets('the announced name can differ from the visible label',
        (WidgetTester tester) async {
      // A screen reader user hears the row they are on; a sighted user sees
      // the column they are in.
      await pump(
        tester,
        label: 'Delete',
        action: const IuxActionDescriptor(
          semantics: IuxActionSemantics(label: 'Delete the March invoice'),
        ),
      );
      expect(find.text('Delete'), findsOneWidget);
      expect(find.bySemanticsLabel('Delete the March invoice'), findsOneWidget);
    });
  });

  group('touch target', () {
    testWidgets('never smaller than the resolved floor, at any density',
        (WidgetTester tester) async {
      for (final IuxDensity density in IuxDensity.values) {
        await pump(
          tester,
          label: 'Ok',
          configuration: IuxThemeConfiguration(
            profile: IuxAccessibilityProfile(density: density),
          ),
        );
        final Size size = tester.getSize(find.byType(IuxButton));
        expect(
          size.height,
          greaterThanOrEqualTo(IuxTouchTarget.minimum),
          reason: '${density.name} produced ${size.height}',
        );
        expect(size.width, greaterThanOrEqualTo(IuxTouchTarget.minimum));
        // An upper bound too. Asserting only the floor let a real defect
        // through: the container aligned its child instead of shrink-wrapping,
        // so a button inside a Center filled the viewport while still passing
        // this test. A floor with no ceiling is half an assertion.
        expect(
          size.height,
          lessThan(120),
          reason: '${density.name} produced a button ${size.height} tall, '
              'which is a banner, not a button',
        );
      }
    });

    testWidgets('a comfortable preference enlarges it',
        (WidgetTester tester) async {
      await pump(
        tester,
        label: 'Ok',
        configuration: const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(
            touchTarget: IuxTouchTargetPreference.comfortable,
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(IuxButton)).height,
        greaterThanOrEqualTo(IuxTouchTarget.comfortable),
      );
    });
  });

  group('resilience', () {
    testWidgets('a long label wraps rather than being truncated',
        (WidgetTester tester) async {
      // A truncated action label is an action the user cannot identify.
      await pump(
        tester,
        label: 'Confirm the permanent deletion of every archived invoice',
        size: const Size(320, 640),
      );
      expect(tester.takeException(), isNull);
      final Text text = tester.widget<Text>(find.byType(Text));
      expect(text.overflow, isNot(TextOverflow.ellipsis));
      expect(text.maxLines, isNull);
    });

    testWidgets('it survives a 200% text scale on a small screen',
        (WidgetTester tester) async {
      await pump(
        tester,
        label: 'Confirm and continue',
        textScale: 2,
        size: const Size(320, 480),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('it renders right-to-left', (WidgetTester tester) async {
      await pump(tester, label: 'حفظ', direction: TextDirection.rtl);
      expect(tester.takeException(), isNull);
      expect(find.text('حفظ'), findsOneWidget);
    });

    testWidgets('it renders on every theme profile',
        (WidgetTester tester) async {
      for (final IuxThemeConfiguration configuration in <IuxThemeConfiguration>[
        const IuxThemeConfiguration(),
        const IuxThemeConfiguration(brightness: Brightness.dark),
        const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(contrast: IuxContrast.high),
        ),
        const IuxThemeConfiguration(
          brightness: Brightness.dark,
          profile: IuxAccessibilityProfile(contrast: IuxContrast.high),
        ),
      ]) {
        await pump(tester, configuration: configuration);
        expect(tester.takeException(), isNull);
        expect(find.text('Save'), findsOneWidget);
      }
    });
  });

  group('motion', () {
    testWidgets('no motion still changes state, only instantly',
        (WidgetTester tester) async {
      await pump(
        tester,
        configuration: const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(motion: IuxMotionPreference.none),
        ),
      );
      final AnimatedContainer container =
          tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      expect(container.duration, Duration.zero);
    });

    testWidgets('reduced motion shortens rather than removes',
        (WidgetTester tester) async {
      await pump(
        tester,
        configuration: const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(
            motion: IuxMotionPreference.standard,
          ),
        ),
      );
      final Duration full = tester
          .widget<AnimatedContainer>(find.byType(AnimatedContainer))
          .duration;

      await pump(
        tester,
        configuration: const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(
            motion: IuxMotionPreference.reduced,
          ),
        ),
      );
      final Duration reduced = tester
          .widget<AnimatedContainer>(find.byType(AnimatedContainer))
          .duration;

      expect(reduced, lessThan(full));
      expect(reduced, greaterThan(Duration.zero));
    });
  });

  group('the widget carries no business meaning', () {
    testWidgets('it never advances the operation itself',
        (WidgetTester tester) async {
      // The parent owns the outcome. A button that ran its own future would be
      // guessing at something only the caller knows.
      final List<int> calls = <int>[];
      await pump(tester, counter: calls);

      await tester.tap(find.byType(IuxButton));
      await tester.pumpAndSettle();

      final IuxButton button = tester.widget<IuxButton>(find.byType(IuxButton));
      expect(button.action.operation, IuxActionOperation.idle,
          reason: 'the descriptor is unchanged; only the parent may change it');
      expect(calls, hasLength(1));
    });

    testWidgets('it emits no feedback of its own', (WidgetTester tester) async {
      // No haptic, no announcement, no snack bar. Those are the parent's.
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

      await pump(tester);
      await tester.tap(find.byType(IuxButton));
      await tester.pumpAndSettle();

      expect(
        platform.where((MethodCall c) => c.method.startsWith('HapticFeedback')),
        isEmpty,
      );
    });
  });
}
