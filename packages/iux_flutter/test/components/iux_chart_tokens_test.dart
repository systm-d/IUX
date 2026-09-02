import 'dart:io';

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
  Future<IuxChartTokens> resolve(
    WidgetTester tester, {
    IuxThemeConfiguration configuration = const IuxThemeConfiguration(),
    double textScale = 1,
    IuxValueAccent? accent,
  }) async {
    late IuxChartTokens tokens;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: MaterialApp(
          key: ValueKey<Object?>(
            <Object?>[configuration, textScale, accent],
          ),
          theme: IuxTheme.fromConfiguration(configuration),
          home: Builder(
            builder: (BuildContext context) {
              tokens = IuxChartResolver.resolve(context, accent: accent);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    await tester.pump();
    return tokens;
  }

  testWidgets('resolves under every profile', (WidgetTester tester) async {
    for (final IuxThemeConfiguration configuration in _profiles) {
      final IuxChartTokens tokens =
          await resolve(tester, configuration: configuration);
      expect(tokens.plotHeight, greaterThan(0), reason: '$configuration');
      expect(tokens.strokeWidth, greaterThan(0), reason: '$configuration');
      expect(tokens.dashUnit, greaterThan(0), reason: '$configuration');
    }
  });

  testWidgets('the two series colours are distinguishable',
      (WidgetTester tester) async {
    // Colour is not the only channel — the stroke pattern is the one that
    // survives a monochrome screen — but where there is colour, two series
    // resolving to the same one would be a palette defect worth failing on.
    for (final IuxThemeConfiguration configuration in _profiles) {
      final IuxChartTokens tokens =
          await resolve(tester, configuration: configuration);
      expect(
        tokens.primaryStroke,
        isNot(tokens.secondaryStroke),
        reason: '$configuration',
      );
    }
  });

  testWidgets('enlarging the text makes the plot taller',
      (WidgetTester tester) async {
    // Somebody who enlarged their text has said that this many pixels were not
    // enough. A chart that keeps its height is legible for everyone except the
    // person who asked for help.
    final double standard = (await resolve(tester)).plotHeight;
    final double enlarged = (await resolve(tester, textScale: 2)).plotHeight;
    expect(enlarged, greaterThan(standard));
  });

  testWidgets('the sparkline is shorter than a full plot',
      (WidgetTester tester) async {
    final IuxChartTokens tokens = await resolve(tester);
    expect(tokens.sparklineHeight, lessThan(tokens.plotHeight));
  });

  testWidgets('the reveal is decoration, so it goes when motion is reduced',
      (WidgetTester tester) async {
    final IuxChartTokens standard = await resolve(tester);
    expect(standard.reveal.isAnimated, isTrue);

    final IuxChartTokens reduced = await resolve(
      tester,
      configuration: const IuxThemeConfiguration(
        profile: IuxAccessibilityProfile(motion: IuxMotionPreference.reduced),
      ),
    );
    expect(
      reduced.reveal.isAnimated,
      isFalse,
      reason: 'drawing a chart in carries no information the finished chart '
          'does not, so it is emphasis — removed at the first request for '
          'less motion, not only when motion is switched off entirely',
    );
  });

  testWidgets('the reveal is also gone under reduced visual stimulation',
      (WidgetTester tester) async {
    final IuxChartTokens tokens = await resolve(
      tester,
      configuration: const IuxThemeConfiguration(
        profile: IuxAccessibilityProfile(
          visualStimulation: IuxVisualStimulation.reduced,
        ),
      ),
    );
    expect(tokens.reveal.isAnimated, isFalse);
  });

  testWidgets('value semantics, so a rebuild with the same theme is cheap',
      (WidgetTester tester) async {
    final IuxChartTokens first = await resolve(tester);
    final IuxChartTokens second = await resolve(tester);
    expect(first, second);
    expect(first.hashCode, second.hashCode);
  });

  testWidgets('the end marker is thicker than the line it ends',
      (WidgetTester tester) async {
    // A marker the width of the stroke is a thickening, not a marker. Twice is
    // a choice rather than a measurement: what is asserted is the relation,
    // which is what keeps the two in step when the theme changes either.
    final IuxChartTokens tokens = await resolve(tester);
    expect(tokens.endMarkerRadius, greaterThan(tokens.strokeWidth));
  });

  testWidgets('the four reading accents resolve four distinct strokes',
      (WidgetTester tester) async {
    // `IuxValueAccent`, not `IuxStatusTone` and not `IuxValueDirection`: a
    // sparkline tinted for a reading compared with a reference is the same
    // claim `IuxValueIndicator` makes, ADR-0013 is what says a comparison is
    // not news, and ADR-0015 is what says the side of the reference does not
    // pick the hue.
    for (final IuxThemeConfiguration configuration in _profiles) {
      final Set<Color> strokes = <Color>{};
      for (final IuxValueAccent accent in IuxValueAccent.values) {
        final IuxChartTokens tokens = await resolve(
          tester,
          configuration: configuration,
          accent: accent,
        );
        strokes.add(tokens.primaryStroke);
      }
      expect(
        strokes,
        hasLength(IuxValueAccent.values.length),
        reason: '$configuration',
      );
    }
  });

  testWidgets("an accent resolves the comparison axis's own colour",
      (WidgetTester tester) async {
    // The point of reusing `IuxValueAccent` instead of introducing a second,
    // parallel vocabulary: the stroke has to actually come from `comparison`,
    // not merely happen to differ across accents. A card that drew its line in
    // one red and its capsule in another would be two hues for one reading.
    for (final IuxThemeConfiguration configuration in _profiles) {
      final IuxChartTokens tinted = await resolve(
        tester,
        configuration: configuration,
        accent: IuxValueAccent.one,
      );
      late Color expected;
      await tester.pumpWidget(
        MaterialApp(
          theme: IuxTheme.fromConfiguration(configuration),
          home: Builder(
            builder: (BuildContext context) {
              expected = IuxSemanticColors.of(context).comparison.one.content;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pump();
      expect(tinted.primaryStroke, expected, reason: '$configuration');
    }
  });

  test('the accent is resolved through the comparison axis, not feedback', () {
    // `comparison.one.content` and `feedback.error.content` are the same value
    // in every shipped profile — both `critical40`/`critical70`/`critical10`/
    // `critical80` — because ADR-0013 reused the existing hue families rather
    // than inventing new ones for the axis, and ADR-0015 kept them. Measured
    // in this round: swapping `colors.comparison.one.content` for
    // `colors.feedback.error.content` above does not change a single resolved
    // `Color`, so no widget test can catch that substitution — the test above
    // this one is blind to it. This reads the source instead, which is the
    // same technique `component_standard_test.dart`'s dead-token check already
    // uses for a claim a resolved `Color` cannot make.
    final String body = File('lib/src/components/chart/iux_chart_tokens.dart')
        .readAsStringSync();
    final int switchStart = body.indexOf('switch (accent)');
    expect(switchStart, greaterThan(-1),
        reason: 'the switch moved or was '
            'renamed; update this test to find it again');
    final int switchEnd = body.indexOf('};', switchStart);
    final String branch = body.substring(switchStart, switchEnd);

    for (final String role in <String>['one', 'two', 'three', 'four']) {
      expect(branch, contains('colors.comparison.$role.content'));
    }
    expect(
      branch,
      isNot(contains('colors.feedback')),
      reason: 'a reading compared with a reference is not news — ADR-0013 — '
          'and feedback.error.content happening to paint the same red as '
          'comparison.one.content is not licence to read it from there',
    );
  });
}
