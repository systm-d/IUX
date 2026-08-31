import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

void main() {
  const IuxInputDescriptor birth = IuxInputDescriptor(
    semantics: IuxInputSemantics(label: 'Date of birth'),
  );

  const IuxDateFieldLabels labels = IuxDateFieldLabels(
    day: 'Day',
    month: 'Month',
    year: 'Year',
  );

  group('the parts are not a DateTime, and that is the point', () {
    test('an incomplete date names no day', () {
      // DateTime? cannot hold "the user has typed a day and not yet a year",
      // so a field built on it invents a half-state the parent cannot see.
      const IuxDateParts parts = IuxDateParts(day: 4);
      expect(parts.isComplete, isFalse);
      expect(parts.date, isNull);
      expect(parts.isEmpty, isFalse);
    });

    test('nothing typed at all', () {
      expect(const IuxDateParts.empty().isEmpty, isTrue);
      expect(const IuxDateParts.empty().date, isNull);
    });

    test('a complete, real date names its day', () {
      const IuxDateParts parts = IuxDateParts(day: 4, month: 7, year: 1990);
      expect(parts.isComplete, isTrue);
      expect(parts.date, DateTime(1990, 7, 4));
    });

    test('a complete but impossible date names none', () {
      // Dart rolls 31 February over into March rather than refusing, so the
      // check is a round trip: a date that disagrees with the parts it was
      // built from is one the user did not name.
      const IuxDateParts parts = IuxDateParts(day: 31, month: 2, year: 1990);
      expect(parts.isComplete, isTrue);
      expect(parts.date, isNull);
    });

    test('a leap day is real in a leap year and not otherwise', () {
      expect(const IuxDateParts(day: 29, month: 2, year: 2024).date,
          DateTime(2024, 2, 29));
      expect(const IuxDateParts(day: 29, month: 2, year: 2023).date, isNull);
    });

    test('clearing a part is not the same as leaving it alone', () {
      // A null argument cannot mean both "leave it" and "empty it", so the
      // clears are their own flags.
      const IuxDateParts parts = IuxDateParts(day: 4, month: 7, year: 1990);
      expect(parts.copyWith(month: null).month, 7);
      expect(parts.copyWith(clearMonth: true).month, isNull);
    });

    test('two dates with the same parts are the same value', () {
      expect(
        const IuxDateParts(day: 1, month: 2, year: 2000),
        const IuxDateParts(day: 1, month: 2, year: 2000),
      );
    });
  });

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: MaterialApp(
          theme: IuxTheme.fromConfiguration(const IuxThemeConfiguration()),
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Widget field({
    IuxDateParts value = const IuxDateParts.empty(),
    IuxInputDescriptor input = birth,
    ValueChanged<IuxDateParts>? onChanged,
  }) =>
      IuxDateField(
        input: input,
        labels: labels,
        value: value,
        onChanged: onChanged ?? (IuxDateParts _) {},
      );

  group('three named boxes under one named question', () {
    testWidgets('each box announces its own name', (WidgetTester tester) async {
      // Asserted on the node, not on the visible text. A box whose label is
      // merely adjacent is a box announced as "edit box" — the failure every
      // field in this library exists to refuse, and one that a findsOneWidget
      // on the label would not have caught.
      await pump(tester, field());

      final List<String> announced = <String>[
        for (int i = 0; i < 3; i++)
          tester.getSemantics(find.byType(TextField).at(i)).label,
      ];
      expect(announced, <String>['Day', 'Month', 'Year']);
    });

    testWidgets(
        'the question names the group, and is not composed into each '
        'box', (WidgetTester tester) async {
      // "Date of birth day" would be a sentence the framework wrote in a
      // language it cannot read, which no_composed_strings_test refuses. A
      // named container is the platform's own mechanism for the same thing.
      await pump(tester, field());
      expect(find.text('Date of birth'), findsOneWidget);
      expect(find.text('Date of birth Day'), findsNothing);
    });
  });

  group('the parent owns validity, as everywhere else', () {
    testWidgets('an impossible day is accepted and reported',
        (WidgetTester tester) async {
      // A field that refused 32 mid-keystroke would be deciding the user meant
      // something else.
      final List<IuxDateParts> seen = <IuxDateParts>[];
      await pump(tester, field(onChanged: seen.add));

      await tester.enterText(find.byType(TextField).first, '32');
      await tester.pump();

      expect(seen.last.day, 32);
    });

    testWidgets('an incomplete date is reported as it is typed',
        (WidgetTester tester) async {
      final List<IuxDateParts> seen = <IuxDateParts>[];
      await pump(tester, field(onChanged: seen.add));

      await tester.enterText(find.byType(TextField).first, '4');
      await tester.pump();

      expect(seen.last.day, 4);
      expect(seen.last.isComplete, isFalse);
    });

    testWidgets('clearing a box clears the part', (WidgetTester tester) async {
      final List<IuxDateParts> seen = <IuxDateParts>[];
      await pump(
        tester,
        field(
          value: const IuxDateParts(day: 4, month: 7, year: 1990),
          onChanged: seen.add,
        ),
      );

      await tester.enterText(find.byType(TextField).first, '');
      await tester.pump();

      expect(seen.last.day, isNull);
      expect(seen.last.month, 7);
    });

    testWidgets('only digits reach the parts', (WidgetTester tester) async {
      final List<IuxDateParts> seen = <IuxDateParts>[];
      await pump(tester, field(onChanged: seen.add));

      await tester.enterText(find.byType(TextField).first, 'a4');
      await tester.pump();

      expect(seen.last.day, 4);
    });
  });

  group('the supporting lines behave like every other field', () {
    testWidgets('help text and the error are both shown',
        (WidgetTester tester) async {
      await pump(
        tester,
        field(
          input: const IuxInputDescriptor(
            semantics: IuxInputSemantics(label: 'Date of birth'),
            helpText: 'For example, 4 7 1990.',
            validation: IuxInputValidation.invalid('Enter a real date.'),
          ),
        ),
      );

      expect(find.text('For example, 4 7 1990.'), findsOneWidget);
      expect(find.text('Enter a real date.'), findsOneWidget);
    });

    testWidgets('a disabled field cannot be typed into',
        (WidgetTester tester) async {
      await pump(
        tester,
        field(
          input: const IuxInputDescriptor(
            semantics: IuxInputSemantics(label: 'Date of birth'),
            availability: IuxInputAvailability.disabled,
          ),
        ),
      );

      final TextField box = tester.widget(find.byType(TextField).first);
      expect(box.enabled, isFalse);
    });
  });

  group('it survives the conditions the library promises', () {
    testWidgets('at 200% text it grows and keeps its three boxes',
        (WidgetTester tester) async {
      await pump(tester, field(), textScale: 2);
      expect(tester.takeException(), isNull);
      expect(find.byType(TextField), findsNWidgets(3));
    });

    testWidgets('a value the parent changes reaches the boxes',
        (WidgetTester tester) async {
      await pump(tester, field());
      await pump(tester, field(value: const IuxDateParts(day: 9, month: 3)));

      final TextField day = tester.widget(find.byType(TextField).first);
      expect(day.controller!.text, '9');
    });
  });
}
