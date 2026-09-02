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

  group('a sparkline that carries an accent and marks where it ends', () {
    testWidgets('an untinted sparkline is drawn exactly as before',
        (WidgetTester tester) async {
      // The compatibility clause. Every sparkline written before this change
      // passes `accent: null`, and must resolve the same stroke it always
      // did.
      late Color plain;
      late Color primary;
      await tester.pumpWidget(
        MaterialApp(
          theme: IuxTheme.fromConfiguration(const IuxThemeConfiguration()),
          home: Builder(
            builder: (BuildContext context) {
              plain = IuxChartResolver.resolve(context).primaryStroke;
              primary = IuxSemanticColors.of(context).action.primary.background;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(plain, primary);
    });

    testWidgets('the four accents resolve four distinct strokes',
        (WidgetTester tester) async {
      final Set<Color> strokes = <Color>{};
      for (final IuxValueAccent accent in IuxValueAccent.values) {
        late Color resolved;
        await tester.pumpWidget(
          MaterialApp(
            theme: IuxTheme.fromConfiguration(const IuxThemeConfiguration()),
            home: Builder(
              builder: (BuildContext context) {
                resolved = IuxChartResolver.resolve(context, accent: accent)
                    .primaryStroke;
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        strokes.add(resolved);
      }
      expect(strokes, hasLength(IuxValueAccent.values.length));
    });

    testWidgets('the end marker is drawn, and only when asked',
        (WidgetTester tester) async {
      // A sparkline of three readings is one continuous run, so `seriesPaths`
      // draws no dot at all — the dot it does draw is for a run of one. What
      // is asserted here is the extra circle, at the end of the line.
      const List<IuxChartPoint> points = <IuxChartPoint>[
        IuxChartPoint(position: 0, value: 1),
        IuxChartPoint(position: 1, value: 3),
        IuxChartPoint(position: 2, value: 2),
      ];

      Future<int> circles({required bool marksEnd}) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: IuxTheme.fromConfiguration(const IuxThemeConfiguration()),
            home: Scaffold(
              body: SizedBox(
                width: 120,
                child: IuxSparkline(
                  points: points,
                  semanticsSummary: 'Up, then down.',
                  marksEnd: marksEnd,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final TestRecordingCanvas recorder = TestRecordingCanvas();
        tester.renderObject<RenderBox>(find.byType(CustomPaint).last).paint(
              TestRecordingPaintingContext(recorder),
              Offset.zero,
            );
        return recorder.invocations
            .where((RecordedInvocation i) =>
                i.invocation.memberName == #drawCircle)
            .length;
      }

      expect(await circles(marksEnd: false), 0);
      expect(await circles(marksEnd: true), 1);
    });

    testWidgets(
        'the marker sits at the last measured reading, not the last '
        'position', (WidgetTester tester) async {
      // A series whose tail is missing ends where it was last measured. A
      // marker at the axis end would put a dot over a stretch nothing drew.
      const List<IuxChartPoint> points = <IuxChartPoint>[
        IuxChartPoint(position: 0, value: 1),
        IuxChartPoint(position: 1, value: 3),
        IuxChartPoint(position: 2, value: null),
      ];
      await tester.pumpWidget(
        MaterialApp(
          theme: IuxTheme.fromConfiguration(const IuxThemeConfiguration()),
          home: const Scaffold(
            body: SizedBox(
              width: 120,
              child: IuxSparkline(
                points: points,
                semanticsSummary: 'Up, then nothing.',
                marksEnd: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final TestRecordingCanvas recorder = TestRecordingCanvas();
      tester.renderObject<RenderBox>(find.byType(CustomPaint).last).paint(
            TestRecordingPaintingContext(recorder),
            Offset.zero,
          );
      final RecordedInvocation circle = recorder.invocations.firstWhere(
        (RecordedInvocation i) => i.invocation.memberName == #drawCircle,
      );
      final Offset centre =
          circle.invocation.positionalArguments.first as Offset;
      final double width = tester.getSize(find.byType(CustomPaint).last).width;
      // Position 1 of a 0..2 axis is the middle of the strip.
      expect(centre.dx, closeTo(width / 2, 0.5));
    });

    testWidgets('in RTL the marker follows the line',
        (WidgetTester tester) async {
      // The line is mirrored by `horizontalOffset`. A marker computed any
      // other way would sit at the opposite end of the strip from the reading
      // it marks — and it would look deliberate.
      const List<IuxChartPoint> points = <IuxChartPoint>[
        IuxChartPoint(position: 0, value: 1),
        IuxChartPoint(position: 1, value: 3),
      ];
      await tester.pumpWidget(
        MaterialApp(
          theme: IuxTheme.fromConfiguration(const IuxThemeConfiguration()),
          home: const Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: SizedBox(
                width: 120,
                child: IuxSparkline(
                  points: points,
                  semanticsSummary: 'صعودا.',
                  marksEnd: true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final TestRecordingCanvas recorder = TestRecordingCanvas();
      tester.renderObject<RenderBox>(find.byType(CustomPaint).last).paint(
            TestRecordingPaintingContext(recorder),
            Offset.zero,
          );
      final Offset centre = recorder.invocations
          .firstWhere(
              (RecordedInvocation i) => i.invocation.memberName == #drawCircle)
          .invocation
          .positionalArguments
          .first as Offset;
      expect(centre.dx, closeTo(0, 0.5),
          reason: 'the last reading is at the reading end, which is the left '
              'edge in a right-to-left interface');
    });

    testWidgets('the accent is never the only signal',
        (WidgetTester tester) async {
      // The summary is required and unchanged by the accent, so a tinted
      // sparkline says the same thing to a screen reader as an untinted one.
      // This asserts the parameter did not quietly become a way to ship a
      // picture whose meaning is a hue.
      await tester.pumpWidget(
        MaterialApp(
          theme: IuxTheme.fromConfiguration(const IuxThemeConfiguration()),
          home: const Scaffold(
            body: IuxSparkline(
              points: <IuxChartPoint>[
                IuxChartPoint(position: 0, value: 0),
                IuxChartPoint(position: 1, value: 2),
              ],
              semanticsSummary: 'Warmer every month of the season.',
              accent: IuxValueAccent.one,
              marksEnd: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel('Warmer every month of the season.'),
        findsOneWidget,
      );
    });
  });
}
