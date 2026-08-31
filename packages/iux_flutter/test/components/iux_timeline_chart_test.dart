import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

/// The four conditions every IUX component is held to.
const List<IuxThemeConfiguration> _profiles = <IuxThemeConfiguration>[
  IuxThemeConfiguration(),
  IuxThemeConfiguration(brightness: Brightness.dark),
  IuxThemeConfiguration(
    profile: IuxAccessibilityProfile(contrast: IuxContrast.high),
  ),
  IuxThemeConfiguration(
    brightness: Brightness.dark,
    profile: IuxAccessibilityProfile(contrast: IuxContrast.high),
  ),
];

void main() {
  const IuxSpanKind work = IuxSpanKind(
    label: 'Declared work',
    texture: IuxSpanTexture.solid,
  );
  const IuxSpanKind onCall = IuxSpanKind(
    label: 'On call',
    texture: IuxSpanTexture.hatched,
  );
  const List<IuxSpanKind> order = <IuxSpanKind>[work, onCall];

  String hours(double v) => '${v.toInt()}:00';

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    IuxThemeConfiguration configuration = const IuxThemeConfiguration(),
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: MaterialApp(
          theme: IuxTheme.fromConfiguration(configuration),
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Widget chart({
    List<IuxTimelineRow>? rows,
    String Function(IuxTimelineRow, List<IuxResolvedSpan>)? describeRow,
  }) =>
      IuxTimelineChart(
        title: 'This week',
        precedence: order,
        axisStart: 0,
        axisEnd: 24,
        formatPosition: hours,
        rows: rows ??
            const <IuxTimelineRow>[
              IuxTimelineRow(
                label: 'Mon',
                spans: <IuxSpan>[IuxSpan(kind: work, start: 9, end: 17)],
              ),
            ],
        describeRow: describeRow ??
            (IuxTimelineRow row, List<IuxResolvedSpan> bands) =>
                '${row.label}: ${bands.length} band(s)',
      );

  group('the description describes what was drawn', () {
    testWidgets('describeRow is handed the resolved bands, not the input',
        (WidgetTester tester) async {
      // The guarantee the component exists for. The caller gave two
      // overlapping stretches; what is drawn is three disjoint bands, and the
      // sentence a screen reader hears has to be about those.
      late List<IuxResolvedSpan> seen;
      await pump(
        tester,
        chart(
          rows: const <IuxTimelineRow>[
            IuxTimelineRow(
              label: 'Mon',
              spans: <IuxSpan>[
                IuxSpan(kind: onCall, start: 8, end: 20),
                IuxSpan(kind: work, start: 12, end: 14),
              ],
            ),
          ],
          describeRow: (IuxTimelineRow row, List<IuxResolvedSpan> bands) {
            seen = bands;
            return 'described';
          },
        ),
      );

      expect(seen.length, 3);
      expect(
        seen.map((IuxResolvedSpan b) => '${b.kind.label} ${b.start}-${b.end}'),
        <String>[
          'On call 8.0-12.0',
          'Declared work 12.0-14.0',
          'On call 14.0-20.0',
        ],
      );
    });

    testWidgets('the row announces the caller sentence and nothing else',
        (WidgetTester tester) async {
      await pump(
        tester,
        chart(
          describeRow: (IuxTimelineRow row, List<IuxResolvedSpan> bands) =>
              'Monday: work from 9 to 17',
        ),
      );

      expect(
        find.bySemanticsLabel('Monday: work from 9 to 17'),
        findsOneWidget,
      );
    });

    testWidgets('the bands are not announced one by one',
        (WidgetTester tester) async {
      // Forty nodes reading "band" would be a worse way to hear the same
      // thing than one sentence.
      await pump(tester, chart());
      expect(find.bySemanticsLabel('band'), findsNothing);
    });
  });

  group('the legend spells every kind out', () {
    testWidgets('each kind appears in words', (WidgetTester tester) async {
      // A legend that shows textures and expects the reader to match them is
      // the failure SC 1.4.1 names.
      await pump(tester, chart());
      expect(find.text('Declared work'), findsOneWidget);
      expect(find.text('On call'), findsOneWidget);
    });

    testWidgets('the ends of the axis are shown', (WidgetTester tester) async {
      await pump(tester, chart());
      expect(find.text('0:00'), findsOneWidget);
      expect(find.text('24:00'), findsOneWidget);
    });
  });

  group('it refuses what it cannot draw honestly', () {
    test('no rows', () {
      expect(
        () => IuxTimelineChart(
          title: 'This week',
          precedence: order,
          rows: const <IuxTimelineRow>[],
          axisStart: 0,
          axisEnd: 24,
          formatPosition: hours,
          describeRow: (_, __) => 'x',
        ),
        throwsAssertionError,
      );
    });

    test('an axis that ends before it starts', () {
      expect(
        () => IuxTimelineChart(
          title: 'This week',
          precedence: order,
          rows: const <IuxTimelineRow>[
            IuxTimelineRow(label: 'Mon', spans: <IuxSpan>[]),
          ],
          axisStart: 24,
          axisEnd: 0,
          formatPosition: hours,
          describeRow: (_, __) => 'x',
        ),
        throwsAssertionError,
      );
    });

    test('a kind ranked twice, so which position wins is undefined', () {
      expect(
        () => IuxTimelineChart(
          title: 'This week',
          precedence: const <IuxSpanKind>[work, onCall, work],
          rows: const <IuxTimelineRow>[
            IuxTimelineRow(label: 'Mon', spans: <IuxSpan>[]),
          ],
          axisStart: 0,
          axisEnd: 24,
          formatPosition: hours,
          describeRow: (_, __) => 'x',
        ),
        throwsAssertionError,
      );
    });

    testWidgets('a row described by nothing', (WidgetTester tester) async {
      await pump(tester, chart(describeRow: (_, __) => ''));
      expect(tester.takeException(), isAssertionError);
    });
  });

  group('it survives the conditions the library promises', () {
    for (final IuxThemeConfiguration configuration in _profiles) {
      testWidgets('it renders under $configuration',
          (WidgetTester tester) async {
        await pump(tester, chart(), configuration: configuration);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('at 200% text it grows and keeps its legend',
        (WidgetTester tester) async {
      await pump(tester, chart(), textScale: 2);
      expect(tester.takeException(), isNull);
      expect(find.text('Declared work'), findsOneWidget);
    });
  });
}
