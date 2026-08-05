import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

const List<IuxChartBar> _rainfall = <IuxChartBar>[
  IuxChartBar(label: 'January', value: 82, valueLabel: '82 mm'),
  IuxChartBar(label: 'February', value: 61, valueLabel: '61 mm'),
  IuxChartBar(
    label: 'March',
    value: 104,
    valueLabel: '104 mm',
    emphasis: IuxSeriesEmphasis.secondary,
  ),
];

void main() {
  Future<void> host(
    WidgetTester tester,
    Widget child, {
    double textScale = 1,
    TextDirection direction = TextDirection.ltr,
  }) async {
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: MaterialApp(
          theme: IuxTheme.fromConfiguration(const IuxThemeConfiguration()),
          home: Directionality(
            textDirection: direction,
            child: Scaffold(body: SingleChildScrollView(child: child)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('every bar is a track and a fill', (WidgetTester tester) async {
    await host(
      tester,
      const IuxBarChart(bars: _rainfall, semanticsSummary: 'Wettest in March'),
    );
    expect(
      tester.renderObject(find.byType(IuxBarChart)),
      paintsExactlyCountTimes(#drawRRect, 6),
      reason: 'three rows, each a track and the part of it filled. Without '
          'the track a row of bars shows which is longest and refuses to say '
          'of what',
    );
  });

  testWidgets('every bar states its value in words',
      (WidgetTester tester) async {
    await host(
      tester,
      const IuxBarChart(bars: _rainfall, semanticsSummary: 'Wettest in March'),
    );
    for (final IuxChartBar bar in _rainfall) {
      expect(find.text(bar.label), findsOneWidget);
      expect(find.text(bar.valueLabel), findsOneWidget);
    }
  });

  testWidgets('the summary is announced and the rows stay reachable',
      (WidgetTester tester) async {
    // Disposed in the body and not through addTearDown: the framework
    // verifies that no SemanticsHandle survives the test *before* it runs the
    // tear-downs, so a handle released there is still reported as leaked.
    final SemanticsHandle handle = tester.ensureSemantics();

    await host(
      tester,
      const IuxBarChart(bars: _rainfall, semanticsSummary: 'Wettest in March'),
    );

    expect(find.bySemanticsLabel('Wettest in March'), findsOneWidget);
    // Each row is one stop carrying both its name and its value, rather than
    // two fragments with nothing joining them.
    expect(find.bySemanticsLabel(RegExp('January')), findsWidgets);

    handle.dispose();
  });

  testWidgets('an empty chart is refused', (WidgetTester tester) async {
    await host(
      tester,
      const IuxBarChart(bars: <IuxChartBar>[], semanticsSummary: 'Nothing'),
    );
    expect(tester.takeException(), isA<AssertionError>());
  });

  testWidgets('a summary of nothing is refused', (WidgetTester tester) async {
    await host(
      tester,
      const IuxBarChart(bars: _rainfall, semanticsSummary: ''),
    );
    expect(tester.takeException(), isA<AssertionError>());
  });

  testWidgets('all-zero bars draw without dividing by zero',
      (WidgetTester tester) async {
    await host(
      tester,
      const IuxBarChart(
        bars: <IuxChartBar>[
          IuxChartBar(label: 'January', value: 0, valueLabel: 'none'),
          IuxChartBar(label: 'February', value: 0, valueLabel: 'none'),
        ],
        semanticsSummary: 'No rain at all',
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.renderObject(find.byType(IuxBarChart)),
      paintsExactlyCountTimes(#drawRRect, 4),
    );
  });

  testWidgets('nothing is clipped at twice the text size',
      (WidgetTester tester) async {
    await host(
      tester,
      const IuxBarChart(
        bars: <IuxChartBar>[
          IuxChartBar(
            label: 'Villars-les-Dombes, Ain, Auvergne-Rhône-Alpes',
            value: 82,
            valueLabel: '82 millimetres of rain',
          ),
        ],
        semanticsSummary: 'One commune',
      ),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    expect(
      find.text('Villars-les-Dombes, Ain, Auvergne-Rhône-Alpes'),
      findsOneWidget,
    );
  });
}
