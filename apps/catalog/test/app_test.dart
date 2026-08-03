import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_catalog/main.dart';
import 'package:iux_flutter/iux_flutter.dart';

void main() {
  /// Scrolls the lazily built catalog until [label] is mounted and visible.
  ///
  /// Written by hand rather than with `scrollUntilVisible`, which cannot serve
  /// this list: a bare text finder matches several widgets once "reduced" is
  /// mounted for both motion and visual stimulation, while narrowing it with
  /// `.first` throws before the target exists at all.
  Future<void> reveal(WidgetTester tester, String label) async {
    for (int attempt = 0; attempt < 40; attempt++) {
      if (find.text(label).evaluate().isNotEmpty) {
        await tester.ensureVisible(find.text(label).first);
        await tester.pumpAndSettle();
        return;
      }
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
      await tester.pumpAndSettle();
    }
    fail('"$label" never became reachable in the catalog');
  }

  /// Selects [label], taking the first match — the one earlier in panel order.
  Future<void> choose(WidgetTester tester, String label) async {
    await reveal(tester, label);
    await tester.tap(find.text(label).first);
    await tester.pumpAndSettle();
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
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
