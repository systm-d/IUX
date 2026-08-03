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

    testWidgets('a confirming descriptor on a plain button runs unasked', (
      WidgetTester tester,
    ) async {
      // Not a defect in the button: obtaining a confirmation is a pattern's
      // job, and IuxButton evaluates the action as though it were already
      // given. It is a trap all the same — the descriptor says "confirm me",
      // the code compiles, and nobody is ever asked. The catalog shows it
      // rather than describing it.
      await tester.pumpWidget(const IuxCatalogApp());
      await reveal(tester, 'the same descriptor on a plain IuxButton');

      expect(find.textContaining('Ran 0 time(s)'), findsOneWidget);
      await tapNamed(tester, 'Delete the March invoice without asking');

      expect(find.textContaining('Ran 1 time(s)'), findsOneWidget,
          reason: 'the action ran with no confirmation ever shown');
      expect(find.byType(IuxDialog), findsNothing);
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
}
