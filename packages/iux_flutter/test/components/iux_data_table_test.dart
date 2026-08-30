import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

/// A row of the sample table.
typedef _Delivery = ({String day, String parcels});

void main() {
  const List<_Delivery> week = <_Delivery>[
    (day: 'Monday', parcels: '12'),
    (day: 'Tuesday', parcels: '9'),
  ];

  List<IuxTableColumn<_Delivery>> columns() => <IuxTableColumn<_Delivery>>[
        IuxTableColumn<_Delivery>(
          label: 'Day',
          value: (_Delivery d) => d.day,
        ),
        IuxTableColumn<_Delivery>(
          label: 'Parcels',
          value: (_Delivery d) => d.parcels,
        ),
      ];

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: MaterialApp(
          theme: IuxTheme.fromConfiguration(const IuxThemeConfiguration()),
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Widget table({String? description}) => IuxDataTable<_Delivery>(
        title: 'Deliveries this week',
        description: description,
        columns: columns(),
        rows: week,
      );

  /// Every semantics node under the table, by role.
  ///
  /// Walks up from a node known to be inside the table rather than down from
  /// the root: in a widget test the root pipeline owner carries no semantics
  /// owner, and the one that does is reached through a deprecated getter.
  List<SemanticsNode> nodesWithRole(WidgetTester tester, SemanticsRole role) {
    SemanticsNode? node = tester.getSemantics(find.text('Day'));
    while (
        node != null && node.getSemanticsData().role != SemanticsRole.table) {
      node = node.parent;
    }
    expect(node, isNotNull, reason: 'no table node above the header cell');

    final List<SemanticsNode> found = <SemanticsNode>[];
    void visit(SemanticsNode current) {
      if (current.getSemanticsData().role == role) found.add(current);
      current.visitChildren((SemanticsNode child) {
        visit(child);
        return true;
      });
    }

    visit(node!);
    return found;
  }

  group('the structure the clause asks for is actually there', () {
    testWidgets('a table node, named, carrying one row per row plus a header',
        (WidgetTester tester) async {
      // EN 301 549 clause 11.5.2.6, and RAAM 4.5. A table assembled from a
      // Column of Rows renders identically and announces a flat run of strings
      // with no structure at all, so this is the whole point of the component.
      await pump(tester, table());

      final List<SemanticsNode> tables =
          nodesWithRole(tester, SemanticsRole.table);
      expect(tables, hasLength(1));
      expect(tables.single.label, 'Deliveries this week');

      // Two data rows and the header row.
      expect(nodesWithRole(tester, SemanticsRole.row), hasLength(3));
    });

    testWidgets('the header row carries column headers, not cells',
        (WidgetTester tester) async {
      await pump(tester, table());

      final List<SemanticsNode> headers =
          nodesWithRole(tester, SemanticsRole.columnHeader);
      expect(headers.map((SemanticsNode n) => n.label),
          <String>['Day', 'Parcels']);
    });

    testWidgets('every data value is its own cell',
        (WidgetTester tester) async {
      await pump(tester, table());

      final List<SemanticsNode> cells =
          nodesWithRole(tester, SemanticsRole.cell);
      expect(cells.map((SemanticsNode n) => n.label),
          <String>['Monday', '12', 'Tuesday', '9']);
    });

    testWidgets('the nesting satisfies the framework, which checks it',
        (WidgetTester tester) async {
      // Flutter asserts that a table's children are rows and a row's children
      // are cells or column headers, and throws on the first frame when they
      // are not. A silent pass here is the assertion having run.
      await pump(tester, table());
      expect(tester.takeException(), isNull);
    });
  });

  group('it says what was tabulated', () {
    testWidgets('the title is a heading, so it can be jumped to',
        (WidgetTester tester) async {
      // RAAM 4.3. Without it a screen-reader user meets a grid of values with
      // nothing saying what was tabulated.
      await pump(tester, table());

      final SemanticsNode heading =
          tester.getSemantics(find.text('Deliveries this week'));
      expect(heading.flagsCollection.isHeader, isTrue);
    });

    testWidgets('a description is shown when one is given',
        (WidgetTester tester) async {
      // RAAM 4.1, for a table complex enough to need reading instructions.
      await pump(tester, table(description: 'Parcels delivered, by weekday.'));
      expect(find.text('Parcels delivered, by weekday.'), findsOneWidget);
    });

    testWidgets('and nothing is reserved when one is not',
        (WidgetTester tester) async {
      await pump(tester, table());
      expect(find.text('Parcels delivered, by weekday.'), findsNothing);
    });
  });

  group('it refuses what it cannot announce honestly', () {
    test('no rows', () {
      expect(
        () => IuxDataTable<_Delivery>(
          title: 'Deliveries',
          columns: columns(),
          rows: const <_Delivery>[],
        ),
        throwsAssertionError,
      );
    });

    test('no columns', () {
      expect(
        () => IuxDataTable<_Delivery>(
          title: 'Deliveries',
          columns: const <IuxTableColumn<_Delivery>>[],
          rows: week,
        ),
        throwsAssertionError,
      );
    });

    test('an unnamed table', () {
      expect(
        () => IuxDataTable<_Delivery>(
          title: '',
          columns: columns(),
          rows: week,
        ),
        throwsAssertionError,
      );
    });

    test('an unnamed column', () {
      expect(
        () => IuxTableColumn<_Delivery>(
          label: '',
          value: (_Delivery d) => d.day,
        ),
        throwsAssertionError,
      );
    });
  });

  group('it survives the conditions the library promises', () {
    testWidgets('at 200% text it grows and keeps its structure',
        (WidgetTester tester) async {
      // The columns share the width and wrap rather than scrolling sideways,
      // so the structure has to survive the wrapping.
      await pump(tester, table(), textScale: 2);
      expect(tester.takeException(), isNull);
      expect(nodesWithRole(tester, SemanticsRole.row), hasLength(3));
      expect(nodesWithRole(tester, SemanticsRole.cell), hasLength(4));
    });
  });
}
