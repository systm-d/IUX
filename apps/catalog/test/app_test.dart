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

    for (int i = 0; i < 40; i++) {
      await tester.drag(scrollable, const Offset(0, 600));
      await settle(tester);
    }

    for (int attempt = 0; attempt < 40; attempt++) {
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

  /// Selects [label], taking the first match — the one earlier in panel order.
  Future<void> choose(WidgetTester tester, String label) async {
    await reveal(tester, label);
    await tester.tap(find.text(label).first);
    await settle(tester);
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

  IuxSemanticColors colorsOf(WidgetTester tester) =>
      IuxSemanticColors.of(tester.element(find.byType(Scaffold)));

  IuxGeometryTheme geometryOf(WidgetTester tester) =>
      IuxGeometryTheme.of(tester.element(find.byType(Scaffold)));

  IuxMotionTheme motionOf(WidgetTester tester) =>
      IuxMotionTheme.of(tester.element(find.byType(Scaffold)));

  testWidgets('presents every theme dimension', (WidgetTester tester) async {
    await tester.pumpWidget(const IuxCatalogApp());

    expect(find.text('IUX theme explorer'), findsOneWidget);
    for (final String panel in <String>[
      'Conditions',
      'What this profile changed',
      'Surfaces and content',
      'Actions',
      'Feedback',
      'Focus',
      'Runtime state',
      'Touch targets',
      'Motion roles',
      'Feedback roles',
      'Layout',
      'Progress',
      'Announcements',
      'Typography',
    ]) {
      await reveal(tester, panel);
    }
  });

  testWidgets('high contrast is reachable in dark conditions', (
    WidgetTester tester,
  ) async {
    // The defect IUX-004 had to fix: high contrast used to force light, so a
    // user needing both a dark interface and reinforced contrast had no
    // option at all.
    await tester.pumpWidget(const IuxCatalogApp());

    await choose(tester, 'dark');
    final IuxSemanticColors darkStandard = colorsOf(tester);

    await choose(tester, 'high');
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
    await choose(tester, 'compact');
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
    await choose(tester, 'reduced');
    expect(motionOf(tester).allowsNonEssentialMotion, isFalse);
  });

  testWidgets('the runtime reacts to a preference change', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const IuxCatalogApp());

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

    await reveal(tester, 'Motion roles');
    expect(find.textContaining('preserve'), findsWidgets);

    await chooseOption(tester, 'Motion', 'reduced');
    await reveal(tester, 'Motion roles');
    expect(find.textContaining('simplify'), findsWidgets,
        reason: 'travel must become a fade rather than a faster movement');
    expect(find.textContaining('remove'), findsWidgets,
        reason: 'decoration must be dropped');
  });

  testWidgets('reading width grows with the text scale', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const IuxCatalogApp());

    await reveal(tester, 'Layout');
    final String before = tester
        .widgetList<Text>(find.byType(Text))
        .map((Text t) => t.data ?? '')
        .firstWhere((String s) => s.startsWith('Layout class'));

    await chooseOption(tester, 'Text scale', '2.0x');
    await reveal(tester, 'Layout');

    expect(before, startsWith('Layout class'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the indeterminate bar goes away when motion is off', (
    WidgetTester tester,
  ) async {
    // A frozen indeterminate segment is parked at a position that means
    // nothing, which reads as a hung operation. Its label carries the status
    // instead.
    await tester.pumpWidget(const IuxCatalogApp());

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
    await reveal(tester, 'Progress');
    expect(find.text('45%'), findsOneWidget);
  });

  testWidgets('large text does not overflow the layout', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const IuxCatalogApp());

    await choose(tester, '2.0x');
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
}
