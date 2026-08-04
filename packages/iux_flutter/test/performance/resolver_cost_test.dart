// Resolver cost.
//
// Every component resolves its appearance in `build`, so a resolver runs once
// per widget per frame. This file records what one call costs and guards the
// order of magnitude. The thresholds are around sixty times the measured value
// on purpose: they are not a performance target, they are a tripwire for a
// resolver that starts searching a palette or measuring contrast per element.
//
// Measured on 2026-08-04, `flutter test` on Linux x86-64 with the Dart VM in
// JIT mode — not an Android device in AOT, where the absolute numbers will
// differ. 200,000 calls each, after 20,000 warm-up calls, results assigned to
// a sink so the optimiser cannot delete them:
//
//   Theme.of(context)                             150 ns
//   IuxSemanticColors.of(context)                 156 ns
//   IuxGeometryTheme.of(context)                  151 ns
//   IuxTypographyTheme.of(context)                151 ns
//   MediaQuery.of(context)                         66 ns
//   IuxAccessibility.of(context)                  243 ns
//   IuxMotionPolicy.resolve(stateChange)          418 ns
//   IuxButtonResolver.resolve                     710 ns
//   IuxStatusResolver.resolve                     942 ns
//   IuxBottomNavigationResolver.resolve         1,215 ns
//   IuxInlineFeedbackResolver.resolve           1,251 ns
//   IuxListItemResolver.resolve                 1,270 ns
//   IuxSelectionResolver.resolve                1,335 ns
//   IuxNavigationDrawerResolver.resolve         1,557 ns
//   Color.computeLuminance() x2 (scrim maths)      37 ns
//
// For scale: one 60 Hz frame is 16,667,000 ns. The most expensive resolver is
// 0.009% of it, and the contrast arithmetic three components run to derive a
// scrim is 2.4% of the resolver that runs it — once per overlay, not per item.
// A full rebuild of a column of 50 IuxButtons measured 243 us against 150 us
// for one, so the marginal cost of a button is about 2 us, of which the
// resolver is 0.7 us.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

void main() {
  const IuxActionDescriptor save = IuxActionDescriptor.primary(
    semantics: IuxActionSemantics(label: 'Save'),
  );

  testWidgets('no resolver is anywhere near a frame budget', (
    WidgetTester tester,
  ) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        theme: IuxTheme.light(),
        home: Builder(
          builder: (BuildContext context) {
            ctx = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    Object? sink;

    double nanosecondsPerCall(Object? Function() body) {
      for (int i = 0; i < 2000; i++) {
        sink = body();
      }
      const int n = 20000;
      final Stopwatch w = Stopwatch()..start();
      for (int i = 0; i < n; i++) {
        sink = body();
      }
      w.stop();
      expect(sink, isNotNull, reason: 'the call must not be optimised away');
      return w.elapsedMicroseconds * 1000 / n;
    }

    final Map<String, Object? Function()> resolvers =
        <String, Object? Function()>{
      'IuxButtonResolver': () => IuxButtonResolver.resolve(ctx, save),
      'IuxInlineFeedbackResolver': () =>
          IuxInlineFeedbackResolver.resolve(ctx, IuxFeedbackCategory.error),
      'IuxBottomNavigationResolver': () =>
          IuxBottomNavigationResolver.resolve(ctx, current: true),
      'IuxListItemResolver': () => IuxListItemResolver.resolve(ctx),
      'IuxNavigationDrawerResolver': () =>
          IuxNavigationDrawerResolver.resolve(ctx),
      'IuxStatusResolver': () =>
          IuxStatusResolver.resolve(ctx, IuxStatusTone.success),
      'IuxSelectionResolver': () => IuxSelectionResolver.resolve(
            ctx,
            const IuxInputDescriptor(
              semantics: IuxInputSemantics(label: 'Agree'),
            ),
          ),
      'IuxMotionPolicy': () =>
          IuxMotionPolicy.resolve(ctx, role: IuxMotionRole.stateChange),
      'IuxAccessibility.of': () => IuxAccessibility.of(ctx),
      'IuxSemanticColors.of': () => IuxSemanticColors.of(ctx),
    };

    for (final MapEntry<String, Object? Function()> resolver
        in resolvers.entries) {
      expect(
        nanosecondsPerCall(resolver.value),
        lessThan(100000),
        reason: '${resolver.key} took more than 100 us per call. The slowest '
            'resolver measured 1.6 us when this threshold was written, so '
            'crossing it means the work changed in kind — a search, an '
            'allocation per element, or contrast arithmetic that used to be '
            'done once. Re-measure before changing this number.',
      );
    }
  });

  testWidgets(
    'resolving is pure, so the same inputs allocate an equal result',
    (WidgetTester tester) async {
      // Not a timing claim. A resolver that returned unequal tokens for equal
      // inputs would defeat every `AnimatedContainer` and every `==` short
      // circuit downstream, which is the rebuild cost that actually matters.
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          theme: IuxTheme.light(),
          home: Builder(
            builder: (BuildContext context) {
              ctx = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(
        IuxButtonResolver.resolve(ctx, save),
        IuxButtonResolver.resolve(ctx, save),
      );
      expect(
        IuxListItemResolver.resolve(ctx),
        IuxListItemResolver.resolve(ctx),
      );
      expect(
        IuxBottomNavigationResolver.resolve(ctx, current: true),
        IuxBottomNavigationResolver.resolve(ctx, current: true),
      );
      expect(
        IuxInlineFeedbackResolver.resolve(ctx, IuxFeedbackCategory.error),
        IuxInlineFeedbackResolver.resolve(ctx, IuxFeedbackCategory.error),
      );
      expect(IuxAccessibility.of(ctx), IuxAccessibility.of(ctx));
    },
  );
}
