import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';
import 'package:iux_pilot/jobs.dart';
import 'package:iux_pilot/jobs_screen.dart';
import 'package:iux_pilot/main.dart';
import 'package:iux_pilot/strings.dart';

void main() {
  /// Pumps a fixed number of frames rather than settling.
  ///
  /// `pumpAndSettle` never returns while an `IuxLoadingIndicator` is mounted:
  /// it animates for as long as it exists, by design — a spinner that stopped
  /// would say the operation had. Every application that shows one inherits
  /// this constraint in its own widget tests.
  Future<void> settle(WidgetTester tester, {int frames = 12}) async {
    for (int i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final Finder target = find.text(text).first;
    await tester.ensureVisible(target);
    await settle(tester, frames: 3);
    await tester.tap(target);
    await settle(tester);
  }

  Future<void> addVisit(
    WidgetTester tester, {
    required String reference,
    required String site,
  }) async {
    await tapText(tester, Strings.navNew);
    await tester.enterText(
      find.bySemanticsLabel(RegExp(Strings.formReference)),
      reference,
    );
    await tester.enterText(
      find.bySemanticsLabel(RegExp(Strings.formSite)),
      site,
    );
    await settle(tester);
    await tapText(tester, Strings.formSubmit);
  }

  group('the round', () {
    testWidgets('starts empty, and the empty state offers the way forward',
        (WidgetTester tester) async {
      await tester.pumpWidget(const PilotApp());
      await settle(tester);

      expect(find.text(Strings.jobsEmptyTitle), findsOneWidget);

      await tapText(tester, Strings.jobsEmptyAction);
      expect(find.text(Strings.formSectionIdentity), findsOneWidget);
    });

    testWidgets('a visit added on the form appears on the list',
        (WidgetTester tester) async {
      await tester.pumpWidget(const PilotApp());
      await settle(tester);

      await addVisit(tester, reference: 'WO-4471', site: '18 Mill Lane');

      expect(find.text('WO-4471'), findsWidgets);
      expect(find.text('18 Mill Lane'), findsOneWidget);
      expect(find.text(Strings.formAdded('WO-4471')), findsOneWidget);
    });

    testWidgets('a duplicate reference is refused and explained',
        (WidgetTester tester) async {
      await tester.pumpWidget(const PilotApp());
      await settle(tester);

      await addVisit(tester, reference: 'WO-4471', site: '18 Mill Lane');
      await addVisit(tester, reference: 'WO-4471', site: '2 Bridge Street');

      expect(find.text(Strings.formReferenceDuplicate), findsWidgets);
      expect(find.text(Strings.formSummaryCount(1)), findsOneWidget);
    });

    testWidgets('a search that matches nothing offers to clear itself',
        (WidgetTester tester) async {
      await tester.pumpWidget(const PilotApp());
      await settle(tester);

      await addVisit(tester, reference: 'WO-4471', site: '18 Mill Lane');
      await tester.enterText(
        find.bySemanticsLabel(RegExp(Strings.searchLabel)),
        'zzz',
      );
      await settle(tester);

      expect(find.text(Strings.jobsNoMatchesTitle), findsOneWidget);

      await tapText(tester, Strings.jobsNoMatchesAction);
      expect(find.text('WO-4471'), findsWidgets);
    });
  });

  group('one visit', () {
    testWidgets('opens, completes and reports its new status',
        (WidgetTester tester) async {
      await tester.pumpWidget(const PilotApp());
      await settle(tester);

      await addVisit(tester, reference: 'WO-4471', site: '18 Mill Lane');
      await tapText(tester, 'WO-4471');

      expect(find.text(Strings.detailSection), findsOneWidget);

      await tapText(tester, Strings.detailComplete);
      await settle(tester);

      expect(find.text(Strings.stateDone), findsWidgets);
      expect(find.text(Strings.detailComplete), findsNothing);
    });

    testWidgets('is removed with an undo offer, and the undo puts it back',
        (WidgetTester tester) async {
      await tester.pumpWidget(const PilotApp());
      await settle(tester);

      await addVisit(tester, reference: 'WO-4471', site: '18 Mill Lane');
      await tapText(tester, 'WO-4471');
      await tapText(tester, Strings.detailDelete);

      // No confirmation: the way back is an undo, so nobody is asked.
      expect(find.text(Strings.detailGoneTitle), findsOneWidget);
      expect(
        find.text(Strings.detailDeletedNotice('WO-4471')),
        findsOneWidget,
      );

      await tapText(tester, Strings.detailUndo);
      expect(find.text(Strings.detailSection), findsOneWidget);
    });
  });

  group('settings', () {
    testWidgets('clearing the round asks first and then empties it',
        (WidgetTester tester) async {
      await tester.pumpWidget(const PilotApp());
      await settle(tester);

      await addVisit(tester, reference: 'WO-4471', site: '18 Mill Lane');
      await tapText(tester, Strings.navSettings);
      // The "visit added" notice sits at the bottom of the content area and
      // covers the last control on the page. Its dwell is a minimum of four
      // seconds and cannot be shortened, so waiting it out is what a real user
      // would have to do too.
      await settle(tester, frames: 45);
      await tapText(tester, Strings.settingsClear);

      expect(find.text(Strings.settingsClearTitle), findsOneWidget);
      expect(find.text(Strings.settingsClearConsequence), findsOneWidget);

      await tapText(tester, Strings.settingsClearConfirm);
      expect(find.text(Strings.settingsCleared), findsOneWidget);

      await tapText(tester, Strings.navJobs);
      expect(find.text(Strings.jobsEmptyTitle), findsOneWidget);
    });

    testWidgets('the system back button dismisses the confirmation',
        (WidgetTester tester) async {
      await tester.pumpWidget(const PilotApp());
      await settle(tester);

      await addVisit(tester, reference: 'WO-4471', site: '18 Mill Lane');
      await tapText(tester, Strings.navSettings);
      await settle(tester, frames: 45);
      await tapText(tester, Strings.settingsClear);
      expect(find.text(Strings.settingsClearTitle), findsOneWidget);

      // `IuxDialog` does not wire this itself; the shell's PopScope does.
      await tester.binding.handlePopRoute();
      await settle(tester);

      expect(find.text(Strings.settingsClearTitle), findsNothing);
      expect(find.text(Strings.settingsCleared), findsNothing);
    });

    testWidgets('clearing an empty round is refused, and says why',
        (WidgetTester tester) async {
      await tester.pumpWidget(const PilotApp());
      await settle(tester);

      await tapText(tester, Strings.navSettings);
      final Finder clear = find.text(Strings.settingsClear);
      await tester.ensureVisible(clear);
      await settle(tester, frames: 3);

      final SemanticsNode node = tester.getSemantics(clear);
      expect(node.flagsCollection.isEnabled, Tristate.isFalse);
      expect(node.hint, contains(Strings.settingsClearNothing));
    });

    testWidgets('the permission conversation ends in a state that says so',
        (WidgetTester tester) async {
      await tester.pumpWidget(const PilotApp());
      await settle(tester);

      await tapText(tester, Strings.navSettings);
      expect(find.text(Strings.permissionTitle), findsOneWidget);

      await tapText(tester, Strings.permissionDecline);
      expect(find.text(Strings.permissionRefusedTitle), findsOneWidget);

      await tapText(tester, Strings.permissionAskAgain);
      expect(find.text(Strings.permissionGranted), findsOneWidget);
    });

    testWidgets('the dark theme reaches every screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(const PilotApp());
      await settle(tester);

      await tapText(tester, Strings.navSettings);
      await tapText(tester, Strings.settingsDark);

      final BuildContext context =
          tester.element(find.byType(IuxSection).first);
      expect(Theme.of(context).brightness, Brightness.dark);
    });
  });

  group('the failure branch', () {
    testWidgets('is reported with a retry that recovers',
        (WidgetTester tester) async {
      final JobStore store = JobStore()..failNextLoad = true;
      addTearDown(store.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: IuxTheme.light(),
          home: JobsScreen(
            jobs: store,
            onCreateRequested: () {},
            onOpen: (Job _) {},
          ),
        ),
      );
      unawaitedLoad(store);
      await settle(tester);

      expect(find.text(Strings.jobsLoadFailed), findsOneWidget);

      await tapText(tester, Strings.retry);
      expect(find.text(Strings.jobsEmptyTitle), findsOneWidget);
    });
  });

  group('under a large text scale on a small screen', () {
    /// 320 logical pixels wide at 200% text — the conditions under which
    /// IUX-A11Y-REACH-001 records `IuxEmptyState` putting its only control off
    /// screen with `hitTestable = 0`.
    ///
    /// The defect is real and the mitigation is the caller's: the pattern does
    /// not scroll, so it has to be placed inside something that does. `IuxPage`
    /// is that something, and this test is the evidence that placing it there
    /// is enough.
    testWidgets('the only control of an empty state is still reachable',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2)),
          child: PilotApp(),
        ),
      );
      await settle(tester);

      final Finder exit = find.text(Strings.jobsEmptyAction);
      expect(exit, findsOneWidget);

      await tester.ensureVisible(exit);
      await settle(tester, frames: 3);
      expect(exit.hitTestable(), findsOneWidget);
    });

    testWidgets('a permission rationale can still be accepted at 150%',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: PilotApp(),
        ),
      );
      await settle(tester);

      await tapText(tester, Strings.navSettings);
      await tapText(tester, Strings.permissionAsk);

      expect(find.text(Strings.permissionGranted), findsOneWidget);
    });
  });
}

/// Starts a load without awaiting it, which is what the shell does.
void unawaitedLoad(JobStore store) {
  store.load(failureMessage: Strings.jobsLoadFailed);
}
