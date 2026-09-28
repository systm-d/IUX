import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

/// Every digit IUX draws takes the same width.
///
/// Three applications declared a monospace family and laid it over IUX's
/// resolved styles by hand — about twenty call sites, then an unknown number,
/// then ninety-five — to get a column of times or counts to line up
/// (systm-d/IUX#66). The workaround stopped at their own text, because the
/// components that draw values take a `String`. This holds the fix where it
/// has to hold: in the roles, and in what the components actually render.
///
/// **What it cannot hold is the result.** `flutter_test` draws every glyph in
/// a face where all characters are one width already, so no measurement here
/// can tell tabular figures from proportional ones. These assert that the
/// request reaches the text; whether the face honours it is the face's.
void main() {
  const FontFeature tabular = FontFeature.tabularFigures();

  const List<(String, IuxThemeConfiguration)> configurations =
      <(String, IuxThemeConfiguration)>[
    ('the default', IuxThemeConfiguration()),
    ('dark', IuxThemeConfiguration(brightness: Brightness.dark)),
    (
      'high contrast',
      IuxThemeConfiguration(
        profile: IuxAccessibilityProfile(contrast: IuxContrast.high),
      )
    ),
    (
      // The workaround's own path: an application choosing a family. The
      // feature has to survive it, or a brand face would silently drop it.
      'a brand family',
      IuxThemeConfiguration(
        typography: IuxTypographyConfiguration(fontFamily: 'Brand Sans'),
      )
    ),
  ];

  group('every role asks for tabular figures', () {
    for (final (String name, IuxThemeConfiguration configuration)
        in configurations) {
      test('under $name', () {
        final IuxTypographyTheme type =
            IuxTypographyTheme.resolve(configuration);
        for (final IuxTypographyRole role in IuxTypographyRole.values) {
          expect(
            type.forRole(role).fontFeatures,
            contains(tabular),
            reason: '${role.name} would draw proportional digits, so a column '
                'of them in that role would not line up',
          );
        }
      });
    }
  });

  group('the request reaches text the application never styles', () {
    /// The effective style of the text painted for [text].
    TextStyle? painted(WidgetTester tester, String text) => tester
        .widget<RichText>(
          find.descendant(
            of: find.text(text),
            matching: find.byType(RichText),
            matchRoot: true,
          ),
        )
        .text
        .style;

    Future<void> host(WidgetTester tester, Widget child) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: IuxTheme.fromConfiguration(const IuxThemeConfiguration()),
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets("a list row's trailing value", (WidgetTester tester) async {
      // The times down a schedule editor, in the report's own example.
      await host(
        tester,
        const IuxListItem(title: 'Departure', trailingText: '09:41'),
      );
      expect(painted(tester, '09:41')?.fontFeatures, contains(tabular));
    });

    testWidgets('a table cell', (WidgetTester tester) async {
      // The case the report says alignment matters most for.
      await host(
        tester,
        IuxDataTable<({String day, String parcels})>(
          title: 'Deliveries this week',
          columns: <IuxTableColumn<({String day, String parcels})>>[
            IuxTableColumn<({String day, String parcels})>(
              label: 'Day',
              value: (({String day, String parcels}) d) => d.day,
            ),
            IuxTableColumn<({String day, String parcels})>(
              label: 'Parcels',
              value: (({String day, String parcels}) d) => d.parcels,
            ),
          ],
          rows: const <({String day, String parcels})>[
            (day: 'Monday', parcels: '118'),
            (day: 'Tuesday', parcels: '9'),
          ],
        ),
      );
      expect(painted(tester, '118')?.fontFeatures, contains(tabular));
      expect(painted(tester, '9')?.fontFeatures, contains(tabular));
    });
  });
}
