import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Records the haptic calls the platform channel receives.
  late List<String> haptics;

  setUp(() {
    haptics = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform,
            (MethodCall call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        haptics.add(call.arguments as String? ?? 'vibrate');
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  /// Builds a scope and returns a function that emits into it.
  Future<Future<IuxFeedbackOutcome> Function(IuxFeedbackEvent)> harness(
    WidgetTester tester, {
    IuxFeedbackTheme policy = const IuxFeedbackTheme(),
    IuxFeedbackController? controller,
  }) async {
    late BuildContext captured;
    final IuxFeedbackController resolved =
        controller ?? IuxFeedbackController();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: <ThemeExtension<dynamic>>[policy],
        ),
        home: IuxFeedbackScope(
          controller: resolved,
          child: Builder(
            builder: (BuildContext context) {
              captured = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    return (IuxFeedbackEvent event) => resolved.emit(captured, event);
  }

  group('role behaviour', () {
    test('intensity rises with consequence', () {
      expect(
          IuxFeedbackRole.interaction.intensity, IuxFeedbackIntensity.subtle);
      expect(IuxFeedbackRole.success.intensity, IuxFeedbackIntensity.moderate);
      expect(IuxFeedbackRole.error.intensity, IuxFeedbackIntensity.strong);
      expect(
        IuxFeedbackRole.destructive.intensity,
        IuxFeedbackIntensity.strong,
      );
    });

    test('only failures and irreversible consequences interrupt', () {
      for (final IuxFeedbackRole role in IuxFeedbackRole.values) {
        expect(
          role.interrupts,
          role == IuxFeedbackRole.error || role == IuxFeedbackRole.destructive,
          reason: '${role.name} should not interrupt a screen reader',
        );
      }
    });

    test('progress never vibrates', () {
      // An ongoing operation would mean repeated vibration.
      expect(IuxFeedbackRole.progress.mayVibrate, isFalse);
      expect(
        IuxHapticPolicy.patternFor(IuxFeedbackRole.progress),
        IuxHapticPattern.none,
      );
    });

    test('haptic strength follows the role', () {
      expect(
        IuxHapticPolicy.patternFor(IuxFeedbackRole.selection),
        IuxHapticPattern.selection,
      );
      expect(
        IuxHapticPolicy.patternFor(IuxFeedbackRole.success),
        IuxHapticPattern.light,
      );
      expect(
        IuxHapticPolicy.patternFor(IuxFeedbackRole.warning),
        IuxHapticPattern.medium,
      );
      expect(
        IuxHapticPolicy.patternFor(IuxFeedbackRole.error),
        IuxHapticPattern.heavy,
      );
    });
  });

  group('events', () {
    test('carry no user-facing text of their own', () {
      const IuxFeedbackEvent event = IuxFeedbackEvent.success();
      expect(event.semanticMessage, isNull,
          reason: 'the engine never composes a message; the parent supplies '
              'an already localised one');
    });

    test('named constructors set their role', () {
      expect(const IuxFeedbackEvent.success().role, IuxFeedbackRole.success);
      expect(const IuxFeedbackEvent.error().role, IuxFeedbackRole.error);
      expect(
        const IuxFeedbackEvent.destructive().role,
        IuxFeedbackRole.destructive,
      );
      expect(
        const IuxFeedbackEvent.selection().role,
        IuxFeedbackRole.selection,
      );
    });

    test('are immutable value types', () {
      const IuxFeedbackEvent a = IuxFeedbackEvent.success(
        semanticMessage: 'Saved',
      );
      const IuxFeedbackEvent b = IuxFeedbackEvent.success(
        semanticMessage: 'Saved',
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a.copyWith(allowHaptics: false).allowHaptics, isFalse);
    });

    test('dedupe key defaults to role and message', () {
      expect(
        const IuxFeedbackEvent.error(semanticMessage: 'Nope')
            .effectiveDedupeKey,
        'error:Nope',
      );
      expect(
        const IuxFeedbackEvent.error(dedupeKey: 'retry').effectiveDedupeKey,
        'retry',
      );
    });
  });

  group('delivery', () {
    testWidgets('a success produces one haptic', (WidgetTester tester) async {
      final Future<IuxFeedbackOutcome> Function(IuxFeedbackEvent) emit =
          await harness(tester);
      final IuxFeedbackOutcome outcome =
          await emit(const IuxFeedbackEvent.success());

      expect(outcome.hapticPerformed, isTrue);
      expect(haptics, hasLength(1));
    });

    testWidgets('progress produces none', (WidgetTester tester) async {
      final Future<IuxFeedbackOutcome> Function(IuxFeedbackEvent) emit =
          await harness(tester);
      final IuxFeedbackOutcome outcome = await emit(
        const IuxFeedbackEvent(role: IuxFeedbackRole.progress),
      );

      expect(outcome.hapticPerformed, isFalse);
      expect(haptics, isEmpty);
    });

    testWidgets('a disabled haptic policy silences every role',
        (WidgetTester tester) async {
      final Future<IuxFeedbackOutcome> Function(IuxFeedbackEvent) emit =
          await harness(
        tester,
        policy: const IuxFeedbackTheme(hapticsEnabled: false),
      );
      await emit(const IuxFeedbackEvent.error());
      expect(haptics, isEmpty);
    });

    testWidgets('an event can opt out of haptics for itself',
        (WidgetTester tester) async {
      // Used when the caller already produced one for the same action; double
      // feedback for a single event is worse than none.
      final Future<IuxFeedbackOutcome> Function(IuxFeedbackEvent) emit =
          await harness(tester);
      await emit(const IuxFeedbackEvent.success(allowHaptics: false));
      expect(haptics, isEmpty);
    });

    testWidgets('an event with no message is not announced',
        (WidgetTester tester) async {
      final Future<IuxFeedbackOutcome> Function(IuxFeedbackEvent) emit =
          await harness(tester);
      final IuxFeedbackOutcome outcome =
          await emit(const IuxFeedbackEvent.success());
      expect(outcome.announced, isFalse);
    });

    testWidgets('the outcome reports what actually happened',
        (WidgetTester tester) async {
      final Future<IuxFeedbackOutcome> Function(IuxFeedbackEvent) emit =
          await harness(tester);
      final IuxFeedbackOutcome outcome = await emit(
        const IuxFeedbackEvent.success(semanticMessage: 'Saved'),
      );
      // Announcement support depends on the platform, so the value is
      // reported rather than assumed — which is why essential information
      // must never depend on one.
      expect(outcome.hapticPerformed, isTrue);
      expect(outcome.suppressedAsDuplicate, isFalse);
      expect(outcome.toString(), contains('haptic'));
    });
  });

  group('deduplication', () {
    testWidgets('an identical event within the window is dropped',
        (WidgetTester tester) async {
      final DateTime clock = DateTime(2026);
      final IuxFeedbackController controller =
          IuxFeedbackController(now: () => clock);
      final Future<IuxFeedbackOutcome> Function(IuxFeedbackEvent) emit =
          await harness(tester, controller: controller);

      final IuxFeedbackOutcome first =
          await emit(const IuxFeedbackEvent.error(semanticMessage: 'Nope'));
      final IuxFeedbackOutcome second =
          await emit(const IuxFeedbackEvent.error(semanticMessage: 'Nope'));

      expect(first.suppressedAsDuplicate, isFalse);
      expect(second.suppressedAsDuplicate, isTrue);
      expect(haptics, hasLength(1), reason: 'one event, one vibration');
    });

    testWidgets('the same event after the window is delivered again',
        (WidgetTester tester) async {
      DateTime clock = DateTime(2026);
      final IuxFeedbackController controller =
          IuxFeedbackController(now: () => clock);
      final Future<IuxFeedbackOutcome> Function(IuxFeedbackEvent) emit =
          await harness(tester, controller: controller);

      await emit(const IuxFeedbackEvent.error(semanticMessage: 'Nope'));
      clock = clock.add(const Duration(seconds: 5));
      final IuxFeedbackOutcome second =
          await emit(const IuxFeedbackEvent.error(semanticMessage: 'Nope'));

      expect(second.suppressedAsDuplicate, isFalse);
      expect(haptics, hasLength(2));
    });

    testWidgets('a different event is never suppressed',
        (WidgetTester tester) async {
      final DateTime clock = DateTime(2026);
      final IuxFeedbackController controller =
          IuxFeedbackController(now: () => clock);
      final Future<IuxFeedbackOutcome> Function(IuxFeedbackEvent) emit =
          await harness(tester, controller: controller);

      await emit(const IuxFeedbackEvent.error(semanticMessage: 'A'));
      final IuxFeedbackOutcome second =
          await emit(const IuxFeedbackEvent.error(semanticMessage: 'B'));
      expect(second.suppressedAsDuplicate, isFalse);
    });

    testWidgets('reset allows a genuine retry to report again',
        (WidgetTester tester) async {
      final DateTime clock = DateTime(2026);
      final IuxFeedbackController controller =
          IuxFeedbackController(now: () => clock);
      final Future<IuxFeedbackOutcome> Function(IuxFeedbackEvent) emit =
          await harness(tester, controller: controller);

      await emit(const IuxFeedbackEvent.error(semanticMessage: 'Nope'));
      controller.reset();
      final IuxFeedbackOutcome second =
          await emit(const IuxFeedbackEvent.error(semanticMessage: 'Nope'));
      expect(second.suppressedAsDuplicate, isFalse);
    });
  });

  group('scope', () {
    testWidgets('a missing scope is reported, never silently swallowed',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              IuxFeedbackScope.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(
        tester.takeException().toString(),
        contains('No IuxFeedbackScope found'),
      );
    });

    testWidgets('maybeOf returns null instead of throwing',
        (WidgetTester tester) async {
      IuxFeedbackController? found;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              found = IuxFeedbackScope.maybeOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(found, isNull);
    });

    testWidgets('the scope is not a global singleton',
        (WidgetTester tester) async {
      late IuxFeedbackController outer;
      late IuxFeedbackController inner;
      await tester.pumpWidget(
        MaterialApp(
          home: IuxFeedbackScope(
            child: Builder(
              builder: (BuildContext outerContext) {
                outer = IuxFeedbackScope.of(outerContext);
                return IuxFeedbackScope(
                  child: Builder(
                    builder: (BuildContext innerContext) {
                      inner = IuxFeedbackScope.of(innerContext);
                      return const SizedBox.shrink();
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );
      expect(identical(outer, inner), isFalse);
    });
  });

  group('theme policy', () {
    test('defaults are permissive', () {
      const IuxFeedbackTheme theme = IuxFeedbackTheme();
      expect(theme.hapticsEnabled, isTrue);
      expect(theme.announcementsEnabled, isTrue);
      expect(theme.dedupeWindow, greaterThan(Duration.zero));
    });

    test('channel permissions never interpolate to a half state', () {
      const IuxFeedbackTheme on = IuxFeedbackTheme();
      const IuxFeedbackTheme off = IuxFeedbackTheme(hapticsEnabled: false);
      for (final double t in <double>[0, 0.25, 0.5, 0.75, 1]) {
        final IuxFeedbackTheme mid = on.lerp(off, t);
        expect(mid.hapticsEnabled, anyOf(isTrue, isFalse));
        expect(mid, anyOf(equals(on), equals(off)));
      }
    });

    testWidgets('an application without a policy still receives feedback',
        (WidgetTester tester) async {
      late IuxFeedbackTheme resolved;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              resolved = IuxFeedbackTheme.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(resolved.hapticsEnabled, isTrue);
    });
  });
}
