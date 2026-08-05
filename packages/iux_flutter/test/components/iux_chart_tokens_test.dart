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
  }) async {
    late IuxChartTokens tokens;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: MaterialApp(
          key: ValueKey<Object>(<Object>[configuration, textScale]),
          theme: IuxTheme.fromConfiguration(configuration),
          home: Builder(
            builder: (BuildContext context) {
              tokens = IuxChartResolver.resolve(context);
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
}
