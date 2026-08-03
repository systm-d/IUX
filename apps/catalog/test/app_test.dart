import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_catalog/main.dart';
import 'package:iux_flutter/iux_flutter.dart';

void main() {
  /// Scrolls the lazily built catalog list until [label] is reachable.
  Future<void> reveal(WidgetTester tester, String label) =>
      tester.scrollUntilVisible(find.text(label), 200,
          scrollable: find
              .byType(
                Scrollable,
              )
              .first);

  testWidgets('presents the semantic role groups', (WidgetTester tester) async {
    await tester.pumpWidget(const IuxCatalogApp());

    expect(find.text('IUX semantic roles'), findsOneWidget);
    for (final String group in <String>[
      'Content',
      'Surface',
      'Border',
      'Action',
      'Feedback',
      'State',
      'Without color alone',
    ]) {
      await reveal(tester, group);
      expect(find.text(group), findsOneWidget, reason: '$group is missing');
    }
  });

  testWidgets('labels every swatch with the role it represents', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const IuxCatalogApp());

    for (final String role in <String>[
      'content.primary',
      'surface.base',
      'border.focus',
      'action.destructive',
      'feedback.error',
      'state.focus',
    ]) {
      await reveal(tester, role);
      expect(find.text(role), findsOneWidget, reason: '$role is missing');
    }
  });

  testWidgets('switches between light and dark role mappings', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const IuxCatalogApp());

    IuxSemanticColors resolve() => IuxSemanticColors.of(
          tester.element(find.byType(Scaffold)),
        );

    final IuxSemanticColors before = resolve();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    final IuxSemanticColors after = resolve();
    expect(after.surface.base, isNot(equals(before.surface.base)));
    expect(after.content.primary, isNot(equals(before.content.primary)));
  });
}
