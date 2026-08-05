import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_catalog/main.dart';
import 'package:iux_flutter/iux_flutter.dart';

void main() {
  /// Pumps a fixed number of frames instead of settling.
  ///
  /// `pumpAndSettle` never returns once an indeterminate progress indicator is
  /// on screen: it animates for as long as it is mounted, by design — a
  /// spinner that stopped would say the operation had. Any application showing
  /// one inherits this constraint in its own widget tests.
  Future<void> settle(WidgetTester tester) async {
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Scrolls the lazily built catalog until [label] is mounted and visible.
  ///
  /// Always returns to the top first, so a step that scrolled far down does
  /// not hide a control that lives above it. Written by hand rather than with
  /// `scrollUntilVisible`, which cannot serve this list: a bare text finder
  /// matches several widgets once "reduced" is mounted for both motion and
  /// visual stimulation, while narrowing it with `.first` throws before the
  /// target exists at all.
  Future<void> reveal(WidgetTester tester, String label) async {
    final Finder scrollable = find.byType(Scrollable).first;

    for (int i = 0; i < 60; i++) {
      await tester.drag(scrollable, const Offset(0, 600));
      await settle(tester);
    }

    for (int attempt = 0; attempt < 60; attempt++) {
      if (find.text(label).evaluate().isNotEmpty) {
        await tester.ensureVisible(find.text(label).first);
        await settle(tester);
        return;
      }
      await tester.drag(scrollable, const Offset(0, -300));
      await settle(tester);
    }
    fail('"$label" never became reachable in the catalog');
  }

  /// Selects an option by dimension *and* value, which is what the chips now
  /// expose: several dimensions share a value.
  Future<void> chooseOption(
    WidgetTester tester,
    String dimension,
    String value,
  ) async {
    await reveal(tester, dimension);
    final Finder target = find.bySemanticsLabel('$dimension: $value');
    await tester.ensureVisible(target.first);
    await settle(tester);
    await tester.tap(target.first);
    await settle(tester);
  }

  /// Taps the control announced as [name], after bringing it on screen.
  ///
  /// `reveal` scrolls a panel *title* into view, which says nothing about
  /// where the control inside it ended up — and a tap that lands on nothing
  /// warns rather than fails, so a test that skipped this would pass while
  /// pressing empty space.
  Future<void> tapNamed(WidgetTester tester, String name) async {
    final Finder target = find.bySemanticsLabel(name);
    await tester.ensureVisible(target);
    await settle(tester);
    await tester.tap(target);
    await settle(tester);
  }

  /// Switches the catalog to one of its sections.
  Future<void> section(WidgetTester tester, String name) =>
      chooseOption(tester, 'Section', name);

  /// Puts the catalog into the conditions a component is likeliest to fail in.
  Future<void> stress(WidgetTester tester) async {
    await reveal(tester, 'Worst case');
    await tester.tap(find.text('Worst case'));
    await settle(tester);
  }

  /// Returns to the top of the list without searching for anything.
  ///
  /// Cheaper than `reveal`, and enough for the header, which is always the
  /// first thing in the list.
  Future<void> toTop(WidgetTester tester) async {
    final Finder scrollable = find.byType(Scrollable).first;
    for (int i = 0; i < 20; i++) {
      await tester.drag(scrollable, const Offset(0, 600));
      await settle(tester);
    }
  }

  /// Folds the header away, or opens it again.
  ///
  /// The control keeps a visible word as well as a chevron, which is what
  /// makes it findable here without reaching for a semantics label.
  Future<void> setHeader(WidgetTester tester, {required bool open}) async {
    await toTop(tester);
    final Finder control = find.text(open ? 'Show' : 'Hide');
    if (control.evaluate().isEmpty) return;
    await tester.tap(control);
    await settle(tester);
  }

  /// Switches section by tapping its chip, which lives near the top.
  ///
  /// `section` goes through `reveal`, which scrolls the whole list twice. With
  /// thirteen sections that is most of a test's budget spent looking for a
  /// control that was never more than a screen from the top.
  Future<void> gotoSection(WidgetTester tester, String name) async {
    await toTop(tester);
    final Finder target = find.bySemanticsLabel('Section: $name');
    await tester.ensureVisible(target.first);
    await settle(tester);
    await tester.tap(target.first);
    await settle(tester);
  }

  /// The first panel of each section, which is what proves the section built.
  const Map<String, String> firstPanels = <String, String>{
    'Buttons': 'Emphasis and meaning',
    'Inputs': 'Availability, and what it costs the caret',
    'Forms': 'A form that refuses',
    'Search': 'The query box',
    'Cards and lists': 'A card, and a card that is a button',
    'Media and status': 'Glyphs, meaningful and decorative',
    'Layout': 'Which window this is',
    'Navigation': 'The bar at the top',
    'Overlays': 'A question that stops everything',
    'Feedback': 'A message that stays',
    'Flows': 'Nothing to show, and why',
    'Theme': 'What this profile changed',
    'Runtime': 'Runtime state',
  };

  IuxSemanticColors colorsOf(WidgetTester tester) =>
      IuxSemanticColors.of(tester.element(find.byType(Scaffold)));

  IuxGeometryTheme geometryOf(WidgetTester tester) =>
      IuxGeometryTheme.of(tester.element(find.byType(Scaffold)));

  IuxMotionTheme motionOf(WidgetTester tester) =>
      IuxMotionTheme.of(tester.element(find.byType(Scaffold)));

  /// Walks every panel of the section currently showing.
  Future<void> walk(WidgetTester tester, List<String> panels) async {
    for (final String panel in panels) {
      await reveal(tester, panel);
    }
  }

  group('conditions', () {
    testWidgets('presents every theme dimension', (WidgetTester tester) async {
      await tester.pumpWidget(const IuxCatalogApp());

      expect(find.text('IUX catalog'), findsOneWidget);
      await section(tester, 'Theme');
      await walk(tester, <String>[
        'Conditions',
        'What this profile changed',
        'Surfaces and content',
        'Action token pairs',
        'Feedback',
        'Focus',
        'Typography',
      ]);
    });

    testWidgets('presents every runtime panel', (WidgetTester tester) async {
      await tester.pumpWidget(const IuxCatalogApp());

      await section(tester, 'Runtime');
      await walk(tester, <String>[
        'Runtime state',
        'Touch targets',
        'Motion roles',
        'Feedback roles',
        'Layout',
        'Progress',
        'Announcements',
      ]);
    });

    testWidgets('high contrast is reachable in dark conditions', (
      WidgetTester tester,
    ) async {
      // The defect IUX-004 had to fix: high contrast used to force light, so a
      // user needing both a dark interface and reinforced contrast had no
      // option at all.
      await tester.pumpWidget(const IuxCatalogApp());

      await chooseOption(tester, 'Brightness', 'dark');
      final IuxSemanticColors darkStandard = colorsOf(tester);

      await chooseOption(tester, 'Contrast', 'high');
      final IuxSemanticColors darkHigh = colorsOf(tester);

      expect(darkHigh.surface.base, isNot(equals(darkStandard.surface.base)));
      expect(
        darkHigh.content.primary,
        isNot(equals(darkStandard.content.primary)),
      );
    });

    testWidgets('density changes spacing without shrinking touch targets', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const IuxCatalogApp());

      final IuxGeometryTheme standard = geometryOf(tester);
      await chooseOption(tester, 'Density', 'compact');
      final IuxGeometryTheme compact = geometryOf(tester);

      expect(compact.spacingMd, lessThan(standard.spacingMd));
      expect(
        compact.minimumTouchTarget,
        greaterThanOrEqualTo(IuxTouchTarget.minimum),
      );
    });

    testWidgets('requesting less motion suppresses decorative motion', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const IuxCatalogApp());

      expect(motionOf(tester).allowsNonEssentialMotion, isTrue);
      await chooseOption(tester, 'Motion', 'reduced');
      expect(motionOf(tester).allowsNonEssentialMotion, isFalse);
    });

    testWidgets('the worst-case preset sets all three axes at once', (
      WidgetTester tester,
    ) async {
      // Six chips at 300% is its own obstacle: the preset exists so the
      // conditions that matter are one tap away rather than a scroll away.
      await tester.pumpWidget(const IuxCatalogApp());
      await stress(tester);

      expect(colorsOf(tester).surface.base, isNotNull);
      expect(geometryOf(tester).spacingMd, lessThan(16));
      await reveal(tester, 'Text scale');
      expect(find.bySemanticsLabel('Text scale: 3.0x'), findsOneWidget);
    });
  });

  group('runtime', () {
    testWidgets('the runtime reacts to a preference change', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const IuxCatalogApp());
      await section(tester, 'Runtime');

      await reveal(tester, 'Minimum touch target');
      expect(find.text('48'), findsWidgets);

      await chooseOption(tester, 'Touch target', 'comfortable');
      await reveal(tester, 'Minimum touch target');
      expect(find.text('56'), findsWidgets,
          reason: 'the runtime must follow the requested preference');
    });

    testWidgets('runtime touch targets meet the floor', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const IuxCatalogApp());
      await section(tester, 'Runtime');
      await reveal(tester, 'Touch targets');

      for (final Element element
          in find.byType(IuxTapTarget).evaluate().toList()) {
        final Size size = tester.getSize(find.byWidget(element.widget));
        expect(size.width, greaterThanOrEqualTo(IuxTouchTarget.minimum));
        expect(size.height, greaterThanOrEqualTo(IuxTouchTarget.minimum));
      }
    });

    testWidgets('motion roles adapt to the requested preference', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const IuxCatalogApp());
      await section(tester, 'Runtime');

      await reveal(tester, 'Motion roles');
      expect(find.textContaining('preserve'), findsWidgets);

      await chooseOption(tester, 'Motion', 'reduced');
      await reveal(tester, 'Motion roles');
      expect(find.textContaining('simplify'), findsWidgets,
          reason: 'travel must become a fade rather than a faster movement');
      expect(find.textContaining('remove'), findsWidgets,
          reason: 'decoration must be dropped');
    });

    testWidgets('the indeterminate bar goes away when motion is off', (
      WidgetTester tester,
    ) async {
      // A frozen indeterminate segment is parked at a position that means
      // nothing, which reads as a hung operation. Its label carries the status
      // instead.
      await tester.pumpWidget(const IuxCatalogApp());
      await section(tester, 'Runtime');

      await reveal(tester, 'Progress');
      expect(find.text('Checking availability'), findsOneWidget);

      await chooseOption(tester, 'Motion', 'none');
      await reveal(tester, 'Progress');

      expect(find.text('Checking availability'), findsOneWidget,
          reason: 'the label must survive as the static alternative');
      expect(tester.takeException(), isNull);
    });

    testWidgets('determinate progress keeps its value visible', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const IuxCatalogApp());
      await section(tester, 'Runtime');
      await reveal(tester, 'Progress');
      expect(find.text('45%'), findsOneWidget);
    });
  });

  group('buttons', () {
    testWidgets('opens on the button harness', (WidgetTester tester) async {
      await tester.pumpWidget(const IuxCatalogApp());

      await walk(tester, <String>[
        'Emphasis and meaning',
        'Icon actions',
        'Unavailable, with and without a reason',
        'Where the operation is',
        'Room to wrap',
        'An action that takes time',
        'An action worth being careful about',
        'What the API refuses, and what it does not',
      ]);
    });

    testWidgets('every icon action meets the target floor', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const IuxCatalogApp());
      await reveal(tester, 'Icon actions');

      final double floor = geometryOf(tester).minimumTouchTarget;
      final Finder targets = find.byType(IuxIconButton);
      expect(targets, findsWidgets);

      for (final Element element in targets.evaluate().toList()) {
        final Size size = tester.getSize(find.byWidget(element.widget));
        expect(size.height, greaterThanOrEqualTo(floor));
        expect(size.width, greaterThanOrEqualTo(floor));
      }
    });

    testWidgets('icon actions keep the floor at 300%', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const IuxCatalogApp());
      await chooseOption(tester, 'Text scale', '3.0x');
      await reveal(tester, 'Icon actions');

      final double floor = geometryOf(tester).minimumTouchTarget;
      for (final Element element
          in find.byType(IuxIconButton).evaluate().toList()) {
        final Size size = tester.getSize(find.byWidget(element.widget));
        expect(size.height, greaterThanOrEqualTo(floor),
            reason:
                'enlarging text must never shrink the region that responds');
      }
    });

    testWidgets(
        'the panel that showed the unasked deletion has nothing left '
        'to show', (WidgetTester tester) async {
      // This test used to press a plain IuxButton carrying a confirming
      // descriptor and watch a counter climb, because the button deleted
      // without asking anybody. A plain button now refuses that descriptor at
      // build, so there is no sample to press — the panel explains the rule
      // instead.
      await tester.pumpWidget(const IuxCatalogApp());
      await reveal(tester, 'the same descriptor on a plain IuxButton');

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Ran '), findsNothing,
          reason: 'the counter existed to record deletions nobody was asked '
              'about, and there are none to record');
      expect(
        find.textContaining('refuses to build'),
        findsOneWidget,
        reason: 'the panel must say why the sample is gone, or it reads as a '
            'section somebody forgot to finish',
      );
    });

    testWidgets('the destructive pattern asks before it runs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const IuxCatalogApp());
      await reveal(tester, 'irreversible — asks first');

      await tapNamed(tester, 'Delete the March invoice');

      expect(find.text('Delete the March invoice?'), findsOneWidget);
      expect(find.text('Keep the invoice'), findsOneWidget);

      await tester.tap(find.text('Delete the invoice'));
      await settle(tester);

      expect(find.byType(IuxDialog), findsNothing);
      await reveal(tester, 'Deleted, after the confirmation was answered.');
    });

    testWidgets('a reversible action runs at once and offers an undo', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const IuxCatalogApp());
      await reveal(tester, 'reversible — runs immediately, undo offered');

      expect(find.text('Undo'), findsNothing);
      await tapNamed(tester, 'Archive the March invoice');

      expect(find.byType(IuxDialog), findsNothing,
          reason: 'confirming something reversible is refused by the pattern');
      expect(find.text('Undo'), findsOneWidget);
    });

    testWidgets('a running action drops a second activation', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const IuxCatalogApp());
      await reveal(tester, 'An action that takes time');

      await tapNamed(tester, 'Pay the March invoice');
      expect(find.text('Runs started'), findsOneWidget);
      // Two matches, not one: the caption of the mid-operation sample above
      // says the same word. That the two agree is the point.
      expect(find.text('inProgress'), findsWidgets);
      expect(find.text('1'), findsWidgets);

      await tapNamed(tester, 'Pay the March invoice');
      expect(find.text('2'), findsNothing,
          reason: 'ignoreWhileInProgress is what stops a double-tapped Pay '
              'charging twice');

      // Let the operation finish so no timer outlives the test.
      await tester.pump(const Duration(seconds: 4));
      await settle(tester);
    });

    testWidgets('the semantics readout reports what was published', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const IuxCatalogApp());
      await reveal(tester, 'unavailable, reason given');

      expect(
        find.text('Add a payment method before sending an invoice'),
        findsWidgets,
        reason: 'the reason must reach the semantics node, not only the docs',
      );
    });
  });

  group('stress', () {
    testWidgets('the button harness survives the worst case', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const IuxCatalogApp());
      await stress(tester);
      await walk(tester, <String>[
        'Emphasis and meaning',
        'Room to wrap',
        'An action worth being careful about',
      ]);

      expect(tester.takeException(), isNull);
    });

    testWidgets('the worst case survives a 360-wide phone', (
      WidgetTester tester,
    ) async {
      // The narrowest Android width still shipped in volume. A layout checked
      // only on the 800-wide test surface has not met it.
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const IuxCatalogApp());
      await stress(tester);
      await walk(tester, <String>['Emphasis and meaning', 'Room to wrap']);

      expect(tester.takeException(), isNull);
    });

    testWidgets('large text does not overflow the layout', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const IuxCatalogApp());

      await chooseOption(tester, 'Text scale', '2.0x');
      expect(tester.takeException(), isNull);
    });

    testWidgets('long labels do not overflow the layout', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const IuxCatalogApp());

      await reveal(tester, 'Long labels');
      await tester.ensureVisible(find.byType(Switch));
      await settle(tester);
      await tester.tap(find.byType(Switch));
      await settle(tester);

      expect(tester.takeException(), isNull);
    });
  });

  group('sections', () {
    testWidgets('every section builds its first panel', (
      WidgetTester tester,
    ) async {
      // The check a dead reference in the switch would fail. `flutter analyze`
      // cannot see it: a section wired to a page nobody built compiles.
      await tester.pumpWidget(const IuxCatalogApp());

      for (final MapEntry<String, String> entry in firstPanels.entries) {
        await gotoSection(tester, entry.key);
        await setHeader(tester, open: false);

        expect(find.text(entry.value), findsOneWidget,
            reason: '"${entry.key}" must show "${entry.value}" '
                'once the header is folded away');
        expect(tester.takeException(), isNull,
            reason: '"${entry.key}" must build without throwing');

        await setHeader(tester, open: true);
      }
    });

    testWidgets('folding the header keeps the conditions readable', (
      WidgetTester tester,
    ) async {
      // The header is most of the first screen at 300%. Folding it is the
      // answer, and the summary is what stops that costing the reader the one
      // thing a screenshot has to carry.
      await tester.pumpWidget(const IuxCatalogApp());

      expect(find.bySemanticsLabel('Section: Buttons'), findsOneWidget);

      await setHeader(tester, open: false);
      expect(find.bySemanticsLabel('Section: Buttons'), findsNothing,
          reason: 'the controls must actually leave the tree');
      expect(find.text('Conditions'), findsOneWidget);
      expect(find.textContaining('Buttons · light'), findsOneWidget,
          reason: 'a folded header must still name what is on screen');

      await setHeader(tester, open: true);
      expect(find.bySemanticsLabel('Section: Buttons'), findsOneWidget);
    });

    testWidgets('the summary follows the conditions it names', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const IuxCatalogApp());
      await stress(tester);
      await setHeader(tester, open: false);

      expect(find.textContaining('dark'), findsOneWidget);
      expect(find.textContaining('long labels'), findsOneWidget);
      expect(find.textContaining('3.0x text'), findsOneWidget);
    });
  });

  group('overlays', () {
    testWidgets('a dialog reaches the page-level modal layer', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const IuxCatalogApp());
      await gotoSection(tester, 'Overlays');
      await reveal(tester, 'A question that stops everything');

      expect(find.byType(IuxDialog), findsNothing);
      await tapNamed(tester, 'Open the confirmation dialog');

      expect(find.byType(IuxDialog), findsOneWidget);
      await tester.tap(find.text('Send it'));
      await settle(tester);
      expect(find.byType(IuxDialog), findsNothing);
    });

    testWidgets('a bottom sheet goes in the page layer, not its own Stack', (
      WidgetTester tester,
    ) async {
      // docs/components/bottom-sheet.md once opened its Limits with
      // "IuxModalLayer cannot hold it. Its slot is IuxDialog?" and now marks
      // that closed. The behaviour is pinned here either way.
      await tester.pumpWidget(const IuxCatalogApp());
      await gotoSection(tester, 'Overlays');
      await reveal(tester, 'A panel from the bottom edge');

      await tapNamed(tester, 'Open the options sheet');
      expect(find.byType(IuxBottomSheet), findsOneWidget);
      expect(find.byType(IuxModalLayer), findsOneWidget,
          reason: 'the sheet must be in the page layer, not in its own Stack');

      await tester.tap(find.text('Close'));
      await settle(tester);
      expect(find.byType(IuxBottomSheet), findsNothing);
    });

    testWidgets('the drawer uses the modal layer\'s third slot', (
      WidgetTester tester,
    ) async {
      // docs/components/navigation-drawer.md once listed "No IuxModalLayer
      // slot" as its first limit and now marks it closed at IUX-027.
      await tester.pumpWidget(const IuxCatalogApp());
      await gotoSection(tester, 'Navigation');
      await reveal(tester, 'The drawer, which the page has to place');

      await tapNamed(tester, 'Open the navigation menu');
      expect(find.byType(IuxNavigationDrawer), findsOneWidget);

      await tester.tap(find.text('Close'));
      await settle(tester);
      expect(find.byType(IuxNavigationDrawer), findsNothing);
    });

    testWidgets('an open modal takes the page out of the semantics tree', (
      WidgetTester tester,
    ) async {
      // This started as a test that switching section closes an open modal.
      // It cannot be written that way, and finding out why is the useful part:
      // with a dialog up, the section chips are not merely covered, they are
      // gone from the semantics tree entirely, so nothing can reach them. The
      // guard in `_selectSection` is therefore defensive rather than
      // load-bearing — and the behaviour it is guarding against is exactly
      // what a modal is supposed to prevent.
      await tester.pumpWidget(const IuxCatalogApp());
      await gotoSection(tester, 'Overlays');
      expect(find.bySemanticsLabel('Section: Layout'), findsOneWidget);

      await reveal(tester, 'A question that stops everything');
      await tapNamed(tester, 'Open the confirmation dialog');
      expect(find.byType(IuxDialog), findsOneWidget);

      expect(find.bySemanticsLabel('Section: Layout'), findsNothing,
          reason: 'a screen reader must not be able to walk out of a modal '
              'into the page it is covering');
    });

    testWidgets('a transient message replaces the one before it', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const IuxCatalogApp());
      await gotoSection(tester, 'Overlays');
      await reveal(tester, 'A message that leaves on its own');

      await tapNamed(tester, 'Show the transient message');
      expect(find.text('The March invoice was archived'), findsOneWidget);

      await tapNamed(
        tester,
        'Replace the transient message with another',
      );
      expect(find.text('The April invoice was archived too'), findsOneWidget);
      expect(find.text('The March invoice was archived'), findsNothing,
          reason: 'one message at a time, and no history');

      // Let the dwell expire so no timer outlives the test.
      await tester.pump(const Duration(seconds: 10));
      await settle(tester);
    });
  });

  group('flows', () {
    testWidgets('the destructive flow offers a way back it can honour', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const IuxCatalogApp());
      await gotoSection(tester, 'Flows');
      await reveal(tester, 'Destroying something, proportionately');

      expect(find.textContaining('Destroyed, net of undos'), findsOneWidget);
      await tapNamed(tester, 'Delete the March invoice');

      // Items scope with an undo offer: no question, and a way back on the
      // transient strip the page placed.
      expect(find.byType(IuxDialog), findsNothing,
          reason: 'an undo offer replaces the question rather than joining it');
      expect(find.text('The March invoice was deleted'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await settle(tester);
      expect(find.text('Undo'), findsNothing);
    });

    testWidgets('an unlistable destruction asks before it runs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const IuxCatalogApp());
      await gotoSection(tester, 'Flows');
      await reveal(tester, 'Destroying something, proportionately');

      await chooseOption(
        tester,
        'Safeguard',
        'everything — a question, and no undo is permitted',
      );
      await reveal(tester, 'Destroying something, proportionately');
      await tapNamed(tester, 'Delete the March invoice');

      expect(find.text('Close this workspace?'), findsOneWidget,
          reason: 'a user who cannot list what they lose is asked first');
      await tester.tap(find.text('Keep the workspace'));
      await settle(tester);
      expect(find.byType(IuxDialog), findsNothing);
    });

    testWidgets('a collapsed disclosure loses the state inside it', (
      WidgetTester tester,
    ) async {
      // The documented price of the guarantee, built rather than described.
      await tester.pumpWidget(const IuxCatalogApp());
      await gotoSection(tester, 'Flows');
      await reveal(tester, 'Content that is not on screen yet');

      await tester.tap(find.text('Delivery options'));
      await settle(tester);
      expect(find.byType(IuxTextField), findsWidgets);

      await tester.enterText(find.byType(IuxTextField).first, 'Leave at door');
      await settle(tester);
      expect(find.text('Leave at door'), findsOneWidget);

      await tester.tap(find.text('Delivery options'));
      await settle(tester);
      await tester.tap(find.text('Delivery options'));
      await settle(tester);

      expect(find.text('Leave at door'), findsNothing,
          reason: 'a collapsed section is unmounted, and its state goes '
              'with it');
    });
  });

  group('onboarding', () {
    // A constraint of the harness rather than of the pattern, and it decides
    // the shape of all three tests below: `reveal` returns to the top first,
    // and at the top of the list the whole section is out of the ListView's
    // cache extent and unmounted. Any panel state a chip set is therefore gone
    // by the time a second `reveal` finishes. Panels whose state lives on the
    // page — the destructive flow's — do not notice; this one keeps its step
    // in its own State, so each test sets exactly one chip through
    // `chooseOption`, which leaves the panel on screen, and reaches everything
    // after that with `ensureVisible`, which does not rewind.

    /// Taps something already built, without rewinding the list.
    Future<void> tapWithoutRewinding(WidgetTester tester, String name) async {
      final Finder target = find.bySemanticsLabel(name);
      await tester.ensureVisible(target.first);
      await settle(tester);
      await tester.tap(target.first);
      await settle(tester);
    }

    testWidgets('the way out survives the last step', (
      WidgetTester tester,
    ) async {
      // The branch an application is most tempted to remove, and the one this
      // pattern exists to keep. The forward control is replaced by the one
      // that ends the flow; the exit is not replaced by anything.
      await tester.pumpWidget(const IuxCatalogApp());
      await gotoSection(tester, 'Flows');
      await chooseOption(tester, 'Step', '3 of 3');

      expect(find.text('Start using Ledger'), findsOneWidget);
      expect(find.text('See how budgets work'), findsNothing,
          reason: 'the forward control has nowhere left to go');
      expect(find.text('Skip setup'), findsOneWidget,
          reason: 'the exit is drawn on the last step as well as the first, '
              'and there is no parameter that removes it');

      await tapWithoutRewinding(tester, 'Skip setup');

      expect(find.text('1 left, 0 finished'), findsOneWidget,
          reason: 'leaving and finishing are different facts about the same '
              'user, and the application records them separately');
      expect(find.text('Start using Ledger'), findsOneWidget,
          reason: 'leaving reports to the parent; it does not navigate the '
              'flow underneath the user');
    });

    testWidgets('a permission request in a step doubles the controls', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const IuxCatalogApp());
      await gotoSection(tester, 'Flows');
      await chooseOption(
        tester,
        'Step shows',
        'a permission request — the anti-pattern',
      );
      // Off the first step, where there is no way back to count.
      await tapWithoutRewinding(tester, 'Step: 2 of 3');

      // Scoped to the flow, because the rationale panel further up this
      // section draws the same two labels for its own reasons.
      expect(
        find.descendant(
          of: find.byType(IuxOnboardingFlow),
          matching: find.byType(IuxButton),
        ),
        findsNWidgets(5),
        reason: 'the rationale brings a way on and a refusal of its own to a '
            'step that already had both',
      );
      expect(find.text('5 — 2 forward, 2 refusing'), findsOneWidget,
          reason: 'the arithmetic is the defect, and it is the thing a reader '
              'cannot see by looking at the screen');
    });

    testWidgets('the introduction survives 300% text in a 320dp window', (
      WidgetTester tester,
    ) async {
      // The catalog's text scale is global and its width is whatever window
      // the harness runs in. The combination that breaks a row of controls is
      // both at once, so the preset carries the text and the panel carries the
      // width — in that order, because the preset rewinds the list.
      await tester.pumpWidget(const IuxCatalogApp());
      await gotoSection(tester, 'Flows');
      await stress(tester);
      await chooseOption(tester, 'Window', '320dp — the narrowest phone');
      // The last step, where all three controls are on screen at once.
      await tapWithoutRewinding(tester, 'Step: 3 of 3');

      expect(tester.takeException(), isNull);
      expect(find.text('Einrichtung überspringen'), findsOneWidget,
          reason: 'the exit is still whole and still named at the worst '
              'combination the harness can produce');

      // Measured against the window rather than against a thrown exception.
      // A control wider than the window it is in does not throw: the row
      // wraps, the button takes its natural width, and the label is simply
      // half off the side of the phone. Only the geometry says so.
      final Rect window = tester.getRect(find.byType(IuxOnboardingFlow));
      for (final String label in <String>[
        'Zurück',
        'Einrichtung überspringen',
        'Ledger jetzt verwenden',
      ]) {
        final Rect control =
            tester.getRect(find.widgetWithText(IuxButton, label));
        expect(control.left, greaterThanOrEqualTo(window.left - 0.5),
            reason: '$label starts outside the window');
        expect(control.right, lessThanOrEqualTo(window.right + 0.5),
            reason: '$label runs past the right edge of a 320dp phone at 300% '
                'text, which is the combination this panel exists to reach');
      }
    });
  });

  group('navigation', () {
    testWidgets('a long dismiss label no longer overflows the drawer header', (
      WidgetTester tester,
    ) async {
      // This was pinned as a defect and the day it named has arrived. The
      // header now measures the way out and keeps the shared line only while
      // the heading still gets one line or twelve characters, whichever is
      // less — IuxAppBar's rule. The wide surface is kept because it is where
      // the overflow used to be worst: 9.5px at 1200, and the heading box was
      // 0.0px wide before the row gave up.
      await tester.binding.setSurfaceSize(const Size(1200, 4000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const IuxCatalogApp());
      await gotoSection(tester, 'Navigation');
      await reveal(tester, 'The drawer, which the page has to place');

      await tapNamed(tester, 'Open the navigation menu');
      expect(tester.takeException(), isNull,
          reason: 'a short dismiss label must not overflow');
      await tester.tap(find.text('Close'));
      await settle(tester);

      await chooseOption(
        tester,
        'Dismiss label',
        '"Close the menu" — used to overflow',
      );
      await reveal(tester, 'The drawer, which the page has to place');
      await tapNamed(tester, 'Open the navigation menu');

      expect(tester.takeException(), isNull,
          reason: 'a longer label must not overflow either — it stacks');
    });

    testWidgets('the bottom bar grows taller rather than narrower', (
      WidgetTester tester,
    ) async {
      // The limit docs/components/bottom-navigation.md records, measured
      // rather than quoted: a name is never shortened, so enlarging text buys
      // height.
      await tester.pumpWidget(const IuxCatalogApp());
      await gotoSection(tester, 'Navigation');
      await reveal(
          tester,
          'The bar at the bottom, and what it costs in '
          'height');

      // `.first`, because the adaptive panel further down this section builds
      // a second bar of its own out of the same component.
      final double standard =
          tester.getSize(find.byType(IuxBottomNavigation).first).height;

      await chooseOption(tester, 'Text scale', '3.0x');
      await gotoSection(tester, 'Navigation');
      await reveal(
          tester,
          'The bar at the bottom, and what it costs in '
          'height');

      final double enlarged =
          tester.getSize(find.byType(IuxBottomNavigation).first).height;

      expect(enlarged, greaterThan(standard),
          reason: 'five names at 300% cost height, and the component refuses '
              'to buy it back by truncating one');
    });
  });
}
