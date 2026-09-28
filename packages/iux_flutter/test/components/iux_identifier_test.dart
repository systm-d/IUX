import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

/// `IuxIdentifier`: the role, plus the announcement a style cannot give
/// (systm-d/IUX#66).
void main() {
  Future<void> host(
    WidgetTester tester,
    Widget child, {
    double textScale = 1,
    double width = 400,
    IuxThemeConfiguration configuration = const IuxThemeConfiguration(),
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: Size(width, 800),
          textScaler: TextScaler.linear(textScale),
        ),
        child: MaterialApp(
          theme: IuxTheme.fromConfiguration(configuration),
          home: Scaffold(body: child),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
      'it is drawn in the identifier role, in the primary content colour',
      (WidgetTester tester) async {
    late TextStyle role;
    late Color primary;
    await host(
      tester,
      Builder(
        builder: (BuildContext context) {
          role = IuxTypographyTheme.of(context).identifier;
          primary = IuxSemanticColors.of(context).content.primary;
          return const IuxIdentifier(value: 'a1b2c3');
        },
      ),
    );
    final Text text = tester.widget<Text>(find.text('a1b2c3'));
    expect(text.style!.fontFamily, role.fontFamily);
    expect(text.style!.fontFeatures, role.fontFeatures);
    expect(text.style!.color, primary);
  });

  testWidgets('a screen reader is told to spell the whole string out',
      (WidgetTester tester) async {
    // A reader meeting "a1b2c3" guesses how to say it. The attribute is what
    // makes it read each character, which is how a recovery code is read aloud.
    final SemanticsHandle handle = tester.ensureSemantics();
    await host(tester, const IuxIdentifier(value: 'a1b2c3'));

    final SemanticsData data =
        tester.getSemantics(find.byType(IuxIdentifier)).getSemanticsData();
    expect(data.attributedLabel.string, 'a1b2c3');
    final List<StringAttribute> attributes = data.attributedLabel.attributes;
    expect(attributes, hasLength(1));
    expect(attributes.single, isA<SpellOutStringAttribute>());
    expect(attributes.single.range, const TextRange(start: 0, end: 6));
    handle.dispose();
  });

  testWidgets('it is announced once, not once guessed and once spelled',
      (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await host(tester, const IuxIdentifier(value: 'a1b2c3'));
    expect(find.bySemanticsLabel('a1b2c3'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a long identifier wraps rather than overflowing, at 200% text',
      (WidgetTester tester) async {
    // No word boundaries to break at, and truncation would hide exactly the
    // characters that tell two identifiers apart.
    await host(
      tester,
      const IuxIdentifier(value: '3f1c305a34464dd48d23d4a36b0ae50f'),
      textScale: 2,
      width: 320,
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(IuxIdentifier)).height,
      greaterThan(48),
      reason: 'it should have wrapped onto more than one line',
    );
  });

  test('an empty identifier is refused', () {
    expect(() => IuxIdentifier(value: ''), throwsAssertionError);
  });
}
