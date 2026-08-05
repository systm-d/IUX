import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

const IuxChartAxis _months = IuxChartAxis(
  min: 0,
  max: 11,
  ticks: <IuxAxisTick>[
    IuxAxisTick(value: 0, label: 'Jan'),
    IuxAxisTick(value: 6, label: 'Jul'),
  ],
);

const IuxChartAxis _degrees = IuxChartAxis(
  min: -5,
  max: 35,
  ticks: <IuxAxisTick>[
    IuxAxisTick(value: 0, label: 'zero'),
    IuxAxisTick(value: 20, label: 'twenty'),
    IuxAxisTick(value: 35, label: 'thirty-five'),
  ],
);

const IuxChartSeries _thisYear = IuxChartSeries(
  label: '2026',
  stroke: IuxSeriesStroke.solid,
  points: <IuxChartPoint>[
    IuxChartPoint(position: 0, value: 4),
    IuxChartPoint(position: 6, value: 24),
    IuxChartPoint(position: 11, value: 6),
  ],
);

const IuxChartSeries _lastYear = IuxChartSeries(
  label: '2025',
  stroke: IuxSeriesStroke.dashed,
  emphasis: IuxSeriesEmphasis.secondary,
  points: <IuxChartPoint>[
    IuxChartPoint(position: 0, value: 3),
    IuxChartPoint(position: 6, value: 22),
    IuxChartPoint(position: 11, value: 5),
  ],
);

const IuxChartBand _normal = IuxChartBand(
  label: 'Normal',
  lower: <IuxChartPoint>[
    IuxChartPoint(position: 0, value: 1),
    IuxChartPoint(position: 6, value: 18),
    IuxChartPoint(position: 11, value: 2),
  ],
  upper: <IuxChartPoint>[
    IuxChartPoint(position: 0, value: 6),
    IuxChartPoint(position: 6, value: 26),
    IuxChartPoint(position: 11, value: 8),
  ],
);

void main() {
  Future<void> host(
    WidgetTester tester,
    Widget child, {
    IuxThemeConfiguration configuration = const IuxThemeConfiguration(),
    TextDirection direction = TextDirection.ltr,
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: MaterialApp(
          key: ValueKey<Object>(<Object>[configuration, direction, textScale]),
          theme: IuxTheme.fromConfiguration(configuration),
          home: Directionality(
            textDirection: direction,
            child: Scaffold(body: SingleChildScrollView(child: child)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  IuxLineChart chart({
    List<IuxChartSeries> series = const <IuxChartSeries>[_thisYear],
    IuxChartBand? band,
    List<IuxChartStop> stops = const <IuxChartStop>[],
    String summary = 'Warmer than usual all summer',
  }) =>
      IuxLineChart(
        series: series,
        horizontalAxis: _months,
        verticalAxis: _degrees,
        semanticsSummary: summary,
        band: band,
        stops: stops,
      );

  testWidgets('one gridline per tick on the value axis',
      (WidgetTester tester) async {
    await host(tester, chart());
    expect(
      tester.renderObject(find.byType(IuxLineChart)),
      paintsExactlyCountTimes(#drawLine, 3),
      reason: 'three ticks were declared. A grid the caller did not ask for '
          'is a grid they have to read past',
    );
  });

  testWidgets('a band is a filled shape and its outline',
      (WidgetTester tester) async {
    await host(tester, chart(band: _normal));
    expect(
      tester.renderObject(find.byType(IuxLineChart)),
      paintsExactlyCountTimes(#drawPath, 4),
      reason: 'the band filled, the band outlined, the one series, and the '
          'one legend swatch',
    );
  });

  testWidgets(
      'the outline is drawn under every profile, not only high contrast',
      (WidgetTester tester) async {
    // A fill difference is exactly what a high-contrast palette flattens. The
    // band states its extent with a line as well as an area, always, so no
    // branch on contrast exists to get wrong.
    for (final IuxThemeConfiguration configuration in <IuxThemeConfiguration>[
      const IuxThemeConfiguration(),
      const IuxThemeConfiguration(
        profile: IuxAccessibilityProfile(contrast: IuxContrast.high),
      ),
    ]) {
      await host(tester, chart(band: _normal), configuration: configuration);
      expect(
        tester.renderObject(find.byType(IuxLineChart)),
        paintsExactlyCountTimes(#drawPath, 4),
        reason: '$configuration',
      );
    }
  });

  testWidgets('two series sharing a stroke pattern are refused',
      (WidgetTester tester) async {
    // The mechanically checkable half of "colour never carries meaning". On a
    // monochrome screen these two would be one line drawn twice.
    await host(
      tester,
      chart(
        series: const <IuxChartSeries>[
          _thisYear,
          IuxChartSeries(
            label: '2025',
            stroke: IuxSeriesStroke.solid,
            points: <IuxChartPoint>[IuxChartPoint(position: 0, value: 1)],
          ),
        ],
      ),
    );
    expect(tester.takeException(), isA<AssertionError>());
  });

  testWidgets('two series with different patterns are fine',
      (WidgetTester tester) async {
    await host(
      tester,
      chart(series: const <IuxChartSeries>[_thisYear, _lastYear]),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('every series is named in the legend',
      (WidgetTester tester) async {
    await host(
      tester,
      chart(series: const <IuxChartSeries>[_thisYear, _lastYear]),
    );
    expect(find.text('2026'), findsOneWidget);
    expect(find.text('2025'), findsOneWidget);
  });

  testWidgets('the band is named there too', (WidgetTester tester) async {
    await host(tester, chart(band: _normal));
    expect(find.text('Normal'), findsOneWidget);
  });

  testWidgets('the axis labels are on screen', (WidgetTester tester) async {
    await host(tester, chart());
    expect(find.text('Jan'), findsOneWidget);
    expect(find.text('Jul'), findsOneWidget);
    expect(find.text('twenty'), findsOneWidget);
  });

  testWidgets('the axis runs in the reading direction',
      (WidgetTester tester) async {
    await host(tester, chart());
    final double ltr = tester.getCenter(find.text('Jan')).dx;
    await host(tester, chart(), direction: TextDirection.rtl);
    final double rtl = tester.getCenter(find.text('Jan')).dx;
    expect(
      rtl,
      greaterThan(ltr),
      reason: 'the first month sits at the reading start, which is the right '
          'edge in a right-to-left interface. A curve that ran one way while '
          'the labels beside it ran the other would be worse than either '
          'convention',
    );
  });

  testWidgets('each stop is a place a screen reader can stand',
      (WidgetTester tester) async {
    // Disposed in the body and not through addTearDown: the framework
    // verifies that no SemanticsHandle survives the test *before* it runs the
    // tear-downs, so a handle released there is still reported as leaked.
    final SemanticsHandle handle = tester.ensureSemantics();

    await host(
      tester,
      chart(
        stops: const <IuxChartStop>[
          IuxChartStop(start: 0, end: 5, label: 'First half, mild'),
          IuxChartStop(start: 6, end: 11, label: 'Second half, hot'),
        ],
      ),
    );

    expect(find.bySemanticsLabel('First half, mild'), findsOneWidget);
    expect(find.bySemanticsLabel('Second half, hot'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Warmer than usual all summer'),
      findsOneWidget,
    );

    handle.dispose();
  });

  testWidgets('a chart with no series is refused', (WidgetTester tester) async {
    await host(tester, chart(series: const <IuxChartSeries>[]));
    expect(tester.takeException(), isA<AssertionError>());
  });

  testWidgets('a summary of nothing is refused', (WidgetTester tester) async {
    await host(tester, chart(summary: ''));
    expect(tester.takeException(), isA<AssertionError>());
  });

  testWidgets('nothing is clipped at twice the text size',
      (WidgetTester tester) async {
    await host(
      tester,
      chart(series: const <IuxChartSeries>[_thisYear, _lastYear]),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    expect(find.text('2026'), findsOneWidget);
    expect(find.text('thirty-five'), findsOneWidget);
  });
}
