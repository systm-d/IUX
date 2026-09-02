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
          key: ValueKey<IuxThemeConfiguration>(configuration),
          theme: IuxTheme.fromConfiguration(configuration),
          home: Directionality(
            textDirection: direction,
            child: Scaffold(body: child),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('IuxVerticalSeparator', () {
    testWidgets('it is as thin as the theme says a border is',
        (WidgetTester tester) async {
      late double expected;
      await host(
        tester,
        Builder(
          builder: (BuildContext context) {
            expected = IuxGeometryTheme.of(context).borderWidth;
            return const SizedBox(
              height: 40,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(child: SizedBox()),
                  IuxVerticalSeparator(),
                  Expanded(child: SizedBox()),
                ],
              ),
            );
          },
        ),
      );

      expect(
        tester.getSize(find.byType(IuxVerticalSeparator)).width,
        expected,
      );
    });

    testWidgets('it takes the height its parent gives it',
        (WidgetTester tester) async {
      // The whole reason this is a widget and not a `VerticalDivider`: it
      // stretches to the row it separates rather than declaring a height of
      // its own. A separator shorter than the columns beside it reads as a
      // stray mark.
      await host(
        tester,
        const SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(child: SizedBox()),
              IuxVerticalSeparator(),
              Expanded(child: SizedBox()),
            ],
          ),
        ),
      );

      expect(tester.getSize(find.byType(IuxVerticalSeparator)).height, 120);
    });

    testWidgets(
        'it has no height of its own, absent a parent that supplies one',
        (WidgetTester tester) async {
      // The claim above — "it takes the height its parent gives it" — is
      // true of any ordinary box under a tight constraint, stretched Row or
      // not: Flutter's layout protocol forces that outcome regardless of
      // what this widget's build() does, so that assertion alone cannot
      // fail from a defect in this file. This one can: under a loose
      // constraint (Center gives its child no minimum), a widget that truly
      // declares no height of its own resolves to zero. A hardcoded
      // decorative height would show up here.
      await host(tester, const Center(child: IuxVerticalSeparator()));

      expect(tester.getSize(find.byType(IuxVerticalSeparator)).height, 0);
    });

    testWidgets('it announces nothing', (WidgetTester tester) async {
      // A line between two columns repeats a boundary the spacing already
      // expresses. A screen reader that stopped on it would add a stop per
      // column, on every visit, for no information.
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(
        tester,
        const SizedBox(
          height: 40,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(child: Text('Nights')),
              IuxVerticalSeparator(),
              Expanded(child: Text('Days')),
            ],
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byType(IuxVerticalSeparator)).label,
        isEmpty,
      );
      handle.dispose();
    });

    testWidgets('it thickens under high contrast rather than changing hue',
        (WidgetTester tester) async {
      // The rule IuxListSeparator records: a line that changes colour under
      // high contrast starts competing with focus for the same meaning.
      final List<double> widths = <double>[];
      for (final IuxThemeConfiguration configuration in _profiles) {
        await host(
          tester,
          const SizedBox(
            height: 40,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(child: SizedBox()),
                IuxVerticalSeparator(),
                Expanded(child: SizedBox()),
              ],
            ),
          ),
          configuration: configuration,
        );
        widths.add(tester.getSize(find.byType(IuxVerticalSeparator)).width);
      }
      expect(widths[2], greaterThanOrEqualTo(widths[0]));
      expect(widths[3], greaterThanOrEqualTo(widths[1]));
    });

    testWidgets('it renders in RTL and at 200% text',
        (WidgetTester tester) async {
      await host(
        tester,
        const SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(child: Text('الليالي')),
              IuxVerticalSeparator(),
              Expanded(child: Text('الأيام')),
            ],
          ),
        ),
        direction: TextDirection.rtl,
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
