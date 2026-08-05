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

const IuxChartAxis _axis = IuxChartAxis(
  min: 0,
  max: 10,
  ticks: <IuxAxisTick>[IuxAxisTick(value: 5, label: 'five')],
);

const List<IuxChartPoint> _points = <IuxChartPoint>[
  IuxChartPoint(position: 0, value: 2),
  IuxChartPoint(position: 5, value: 8),
  IuxChartPoint(position: 10, value: 4),
];

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

  List<Widget> everyChart() => <Widget>[
        const IuxSparkline(points: _points, semanticsSummary: 'Up then down'),
        const IuxLineChart(
          series: <IuxChartSeries>[
            IuxChartSeries(
              label: 'This year',
              stroke: IuxSeriesStroke.solid,
              points: _points,
            ),
          ],
          horizontalAxis: _axis,
          verticalAxis: _axis,
          semanticsSummary: 'Up then down',
        ),
        const IuxBarChart(
          bars: <IuxChartBar>[
            IuxChartBar(label: 'January', value: 8, valueLabel: '8 mm'),
          ],
          semanticsSummary: 'One month',
        ),
      ];

  testWidgets('every chart renders under every profile',
      (WidgetTester tester) async {
    for (final IuxThemeConfiguration configuration in _profiles) {
      for (final Widget chart in everyChart()) {
        await host(tester, chart, configuration: configuration);
        expect(
          tester.takeException(),
          isNull,
          reason: '${chart.runtimeType} under $configuration',
        );
      }
    }
  });

  testWidgets('every chart renders at twice the text size',
      (WidgetTester tester) async {
    for (final Widget chart in everyChart()) {
      await host(tester, chart, textScale: 2);
      expect(tester.takeException(), isNull, reason: '${chart.runtimeType}');
    }
  });

  testWidgets('every chart renders right to left', (WidgetTester tester) async {
    for (final Widget chart in everyChart()) {
      await host(tester, chart, direction: TextDirection.rtl);
      expect(tester.takeException(), isNull, reason: '${chart.runtimeType}');
    }
  });

  testWidgets('a bar fills from the side the reader starts at',
      (WidgetTester tester) async {
    // The one thing a mirrored layout does not fix on its own: a rectangle
    // painted from x = 0 fills from the left in every language. The Transform
    // above the painter is what turns it round, and this is what notices if
    // somebody removes it.
    const IuxBarChart chart = IuxBarChart(
      bars: <IuxChartBar>[
        IuxChartBar(label: 'January', value: 8, valueLabel: '8 mm'),
        IuxChartBar(label: 'February', value: 2, valueLabel: '2 mm'),
      ],
      semanticsSummary: 'Wetter in January',
    );

    // Scoped to the chart: Material and the scroll view put Transforms of
    // their own in the tree, and an unscoped finder measures one of those —
    // which is identity in both directions and passes for the wrong reason.
    final Finder mirroir = find.descendant(
      of: find.byType(IuxBarChart),
      matching: find.byType(Transform),
    );

    await host(tester, chart);
    final Matrix4 ltr = tester.widget<Transform>(mirroir.first).transform;
    await host(tester, chart, direction: TextDirection.rtl);
    final Matrix4 rtl = tester.widget<Transform>(mirroir.first).transform;

    expect(
      ltr.entry(0, 0),
      isNot(rtl.entry(0, 0)),
      reason: 'the horizontal scale of the bar differs by reading direction, '
          'which is the whole mechanism',
    );
    expect(rtl.entry(0, 0), lessThan(0));
  });

  testWidgets('every chart says something to a screen reader',
      (WidgetTester tester) async {
    // Disposed in the body and not through addTearDown: the framework
    // verifies that no SemanticsHandle survives the test *before* it runs the
    // tear-downs, so a handle released there is still reported as leaked.
    final SemanticsHandle handle = tester.ensureSemantics();

    for (final Widget chart in everyChart()) {
      await host(tester, chart);
      expect(
        find.bySemanticsLabel(RegExp('Up then down|One month')),
        findsWidgets,
        reason: '${chart.runtimeType} announced nothing',
      );
    }

    handle.dispose();
  });

  testWidgets('no chart animates when less motion is asked for',
      (WidgetTester tester) async {
    for (final Widget chart in everyChart()) {
      await host(
        tester,
        chart,
        configuration: const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(motion: IuxMotionPreference.reduced),
        ),
      );
      expect(
        find.byType(TweenAnimationBuilder<double>),
        findsNothing,
        reason: '${chart.runtimeType} kept its draw-in',
      );
    }
  });

  testWidgets('and the two that can animate do, when nothing is asked for',
      (WidgetTester tester) async {
    // The guard for the test above. `findsNothing` is exactly the shape that
    // passes for the wrong reason, and IuxBarChart has no draw-in under any
    // profile — so a third of that loop would prove nothing without this.
    for (final Widget chart in <Widget>[everyChart()[0], everyChart()[1]]) {
      await host(tester, chart);
      expect(
        find.byType(TweenAnimationBuilder<double>),
        findsOneWidget,
        reason: '${chart.runtimeType} never animated in the first place, so '
            'the reduced-motion assertion about it is empty',
      );
    }
  });
}
