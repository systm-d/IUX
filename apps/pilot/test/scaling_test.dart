import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';
import 'package:iux_pilot/job_detail_screen.dart';
import 'package:iux_pilot/jobs.dart';
import 'package:iux_pilot/main.dart';
import 'package:iux_pilot/strings.dart';

/// Every screen, at every text scale, on the smallest window IUX supports.
///
/// WCAG 2.2 SC 1.4.4 binds at 200%; Android reaches 300% with the largest font
/// setting and display size together, which is why the loop goes that far.
void main() {
  Future<void> settle(WidgetTester tester, {int frames = 10}) async {
    for (int i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Each case gets a fresh element tree.
  ///
  /// `DebugOverflowIndicatorMixin` reports a render object's overflow once per
  /// lifetime, so a loop that reuses the tree passes vacuously after the first
  /// case — the mechanism recorded as IUX-QA-VACUOUS-003.
  /// `pumpWidget(SizedBox.shrink())` between cases is the documented fix, and
  /// this suite would be worthless without it.
  Future<void> clear(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  for (final double scale in <double>[1, 1.5, 2, 3]) {
    testWidgets('the whole application lays out at ${scale}x on 320x640',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      Future<void> start() async {
        await clear(tester);
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: const PilotApp(),
          ),
        );
        await settle(tester);
      }

      await start();
      expect(tester.takeException(), isNull, reason: 'empty list');

      await tester.tap(find.text(Strings.navNew).first, warnIfMissed: false);
      await settle(tester);
      expect(tester.takeException(), isNull, reason: 'form');
      expect(find.text(Strings.formSectionIdentity), findsOneWidget);

      await tester.tap(find.text(Strings.navSettings).first,
          warnIfMissed: false);
      await settle(tester);
      expect(tester.takeException(), isNull, reason: 'settings');
      expect(find.text(Strings.settingsDisplay), findsOneWidget);

      // The list with a row on it, which is the case the empty screen cannot
      // reach and where the row's own layout is exercised.
      await start();
      await tester.tap(find.text(Strings.navNew).first, warnIfMissed: false);
      await settle(tester);
      await tester.enterText(
        find.bySemanticsLabel(RegExp(Strings.formReference)),
        'WO-4471',
      );
      await tester.enterText(
        find.bySemanticsLabel(RegExp(Strings.formSite)),
        '18 Mill Lane, Northwood',
      );
      await settle(tester);
      final Finder submit = find.text(Strings.formSubmit);
      await tester.ensureVisible(submit);
      await settle(tester, frames: 3);
      await tester.tap(submit);
      await settle(tester);
      expect(tester.takeException(), isNull, reason: 'list with a row');
      expect(find.text('WO-4471'), findsWidgets);
    });

    testWidgets('the detail screen lays out at ${scale}x on 320x640',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final JobStore store = JobStore();
      addTearDown(store.dispose);
      final Job job = store.add(
        reference: 'WO-4471',
        site: '18 Mill Lane, Northwood',
        priority: JobPriority.urgent,
        notes: 'Gate code 4471. The dog is friendly but loud.',
      );

      await clear(tester);
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: MaterialApp(
            theme: IuxTheme.light(),
            home: Scaffold(
              body: JobDetailScreen(
                jobs: store,
                jobId: job.id,
                onClose: () {},
              ),
            ),
          ),
        ),
      );
      await settle(tester);

      expect(tester.takeException(), isNull);

      // Both controls exist and both can be reached by scrolling to them.
      for (final String label in <String>[
        Strings.detailComplete,
        Strings.detailDelete,
      ]) {
        final Finder control = find.text(label);
        expect(control, findsOneWidget, reason: label);
        await tester.ensureVisible(control);
        await settle(tester, frames: 3);
        expect(control.hitTestable(), findsOneWidget, reason: label);
      }
    });
  }

  testWidgets('the application lays out right-to-left',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.rtl,
        child: PilotApp(),
      ),
    );
    await settle(tester);
    expect(tester.takeException(), isNull);
  });
}
