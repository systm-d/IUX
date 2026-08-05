import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

/// Six readings with a hole in the middle.
const List<IuxChartPoint> _withGap = <IuxChartPoint>[
  IuxChartPoint(position: 0, value: 3),
  IuxChartPoint(position: 1, value: 5),
  IuxChartPoint(position: 2, value: 4),
  IuxChartPoint(position: 3, value: null),
  IuxChartPoint(position: 4, value: 6),
  IuxChartPoint(position: 5, value: 7),
];

const List<IuxChartPoint> _continuous = <IuxChartPoint>[
  IuxChartPoint(position: 0, value: 3),
  IuxChartPoint(position: 1, value: 5),
  IuxChartPoint(position: 2, value: 4),
];

void main() {
  Future<void> host(
    WidgetTester tester,
    Widget child, {
    IuxThemeConfiguration configuration = const IuxThemeConfiguration(),
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        key: ValueKey<IuxThemeConfiguration>(configuration),
        theme: IuxTheme.fromConfiguration(configuration),
        home: Scaffold(body: Center(child: SizedBox(width: 200, child: child))),
      ),
    );
    await tester.pump();
  }

  testWidgets('an unbroken series is drawn as one stroke',
      (WidgetTester tester) async {
    await host(
      tester,
      const IuxSparkline(points: _continuous, semanticsSummary: 'Rising'),
    );
    expect(
      tester.renderObject(find.byType(IuxSparkline)),
      paintsExactlyCountTimes(#drawPath, 1),
    );
  });

  testWidgets('a missing reading leaves a hole rather than a straight line',
      (WidgetTester tester) async {
    await host(
      tester,
      const IuxSparkline(points: _withGap, semanticsSummary: 'Rising'),
    );
    expect(
      tester.renderObject(find.byType(IuxSparkline)),
      paintsExactlyCountTimes(#drawPath, 2),
      reason: 'one stroke each side of the gap. A single stroke would mean '
          'the missing day had been drawn as a straight line between its '
          'neighbours, which is a reading nobody took',
    );
  });

  testWidgets('the summary is what a screen reader is given',
      (WidgetTester tester) async {
    // Disposed inside the body and not through addTearDown: the framework
    // verifies that no SemanticsHandle survives the test *before* it runs the
    // tear-downs, so a handle released there is still reported as leaked.
    final SemanticsHandle handle = tester.ensureSemantics();

    await host(
      tester,
      const IuxSparkline(
        points: _continuous,
        semanticsSummary: 'Warmer every year since 2014',
      ),
    );

    expect(
      find.bySemanticsLabel('Warmer every year since 2014'),
      findsOneWidget,
    );

    handle.dispose();
  });

  testWidgets('an empty series is refused', (WidgetTester tester) async {
    await host(
      tester,
      const IuxSparkline(points: <IuxChartPoint>[], semanticsSummary: 'None'),
    );
    expect(tester.takeException(), isA<AssertionError>());
  });

  testWidgets('a summary of nothing is refused', (WidgetTester tester) async {
    await host(
      tester,
      const IuxSparkline(points: _continuous, semanticsSummary: ''),
    );
    expect(tester.takeException(), isA<AssertionError>());
  });

  testWidgets('a flat series still draws', (WidgetTester tester) async {
    // Every reading identical is a degenerate range, and dividing by it would
    // put the line at NaN — drawn nowhere, with nothing on screen to say why.
    await host(
      tester,
      const IuxSparkline(
        points: <IuxChartPoint>[
          IuxChartPoint(position: 0, value: 4),
          IuxChartPoint(position: 1, value: 4),
        ],
        semanticsSummary: 'Unchanged',
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.renderObject(find.byType(IuxSparkline)),
      paintsExactlyCountTimes(#drawPath, 1),
    );
  });

  testWidgets('the draw-in is gone when less motion is asked for',
      (WidgetTester tester) async {
    await host(
      tester,
      const IuxSparkline(points: _continuous, semanticsSummary: 'Rising'),
      configuration: const IuxThemeConfiguration(
        profile: IuxAccessibilityProfile(motion: IuxMotionPreference.reduced),
      ),
    );
    expect(
      find.byType(TweenAnimationBuilder<double>),
      findsNothing,
      reason: 'not merely a zero duration: the whole animator is absent, so '
          'the first frame is the finished chart',
    );
    expect(
      tester.renderObject(find.byType(IuxSparkline)),
      paintsExactlyCountTimes(#drawPath, 1),
    );
  });

  testWidgets('and present when it is not', (WidgetTester tester) async {
    await host(
      tester,
      const IuxSparkline(points: _continuous, semanticsSummary: 'Rising'),
    );
    expect(find.byType(TweenAnimationBuilder<double>), findsOneWidget);
    await tester.pumpAndSettle();
  });
}
