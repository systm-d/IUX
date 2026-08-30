// Tristate is declared in `dart:ui` and is not re-exported by
// `package:flutter/semantics.dart`, so this is the only way to name it. It is
// what distinguishes "collapsed" from "has no open state at all".
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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
  const IuxInputDescriptor country = IuxInputDescriptor(
    semantics: IuxInputSemantics(label: 'Country'),
  );

  const List<IuxRadioOption<String>> options = <IuxRadioOption<String>>[
    IuxRadioOption<String>(value: 'fr', label: 'France'),
    IuxRadioOption<String>(value: 'be', label: 'Belgium'),
    IuxRadioOption<String>(value: 'ch', label: 'Switzerland'),
  ];

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    IuxThemeConfiguration configuration = const IuxThemeConfiguration(),
    double textScale = 1,
    Size size = const Size(400, 800),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: MaterialApp(
          theme: IuxTheme.fromConfiguration(configuration),
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Widget select({
    String? value,
    IuxInputDescriptor input = country,
    String? placeholder = 'Choose a country',
    ValueChanged<String>? onChanged,
  }) =>
      IuxSelectField<String>(
        label: 'Country',
        input: input,
        value: value,
        options: options,
        placeholder: placeholder,
        onChanged: onChanged ?? (String _) {},
      );

  /// Read from inside the control, never from the widget.
  ///
  /// The announced node sits below `IuxSelectField`'s own element, so
  /// `getSemantics(find.byType(...))` walks *up* to an ancestor and returns a
  /// node with no label at all — a matcher that would have passed for the
  /// wrong reason if it had been written the other way round.
  SemanticsNode nodeOf(WidgetTester tester) =>
      tester.getSemantics(find.byIcon(Icons.expand_more));

  group('the collapsed control announces name, role and value', () {
    testWidgets('the answer is the value, not part of the name',
        (WidgetTester tester) async {
      // The platform joins a name to a value in the user's own language. A
      // framework that composes "Country, France" has written a sentence in a
      // language it cannot read — which is what no_composed_strings_test
      // exists to prevent, and what this asserts positively.
      await pump(tester, select(value: 'fr'));

      final SemanticsNode node = nodeOf(tester);
      expect(node.label, 'Country');
      expect(node.value, 'France');
    });

    testWidgets(
        'it is a button that carries a value, because comboBox is not '
        'usable yet', (WidgetTester tester) async {
      // SemanticsRole.comboBox is declared upstream and its debug checks are
      // not written, so setting it throws on the first frame
      // (flutter/flutter#159741). A button with a value and an expanded state
      // is what the platform can speak today. This test is what will fail,
      // usefully, when that changes.
      await pump(tester, select(value: 'fr'));
      final SemanticsNode node = nodeOf(tester);
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.role, SemanticsRole.none);
    });

    testWidgets('it announces that it is collapsed',
        (WidgetTester tester) async {
      await pump(tester, select(value: 'fr'));
      // Tristate.isFalse rather than Tristate.none: the control has an open
      // state and is closed, which is different from having none at all.
      expect(nodeOf(tester).flagsCollection.isExpanded, Tristate.isFalse);
    });

    testWidgets('an unanswered question announces no value at all',
        (WidgetTester tester) async {
      // Not the placeholder. "Choose a country" announced as a value tells the
      // user the question has been answered, and the answer is that sentence.
      await pump(tester, select());

      final SemanticsNode node = nodeOf(tester);
      expect(node.value, isEmpty);
      expect(find.text('Choose a country'), findsOneWidget);
    });

    testWidgets('the question is not read twice', (WidgetTester tester) async {
      // The visible heading repeats the accessible name verbatim, so it is
      // excluded. Left in, the user hears the question as a heading and again
      // as the name of the control below it.
      await pump(tester, select(value: 'fr'));
      expect(nodeOf(tester).label, 'Country');
      expect(find.text('Country'), findsOneWidget);
    });
  });

  group('opening it hands the user a radio group', () {
    testWidgets('activating shows every option as a radio',
        (WidgetTester tester) async {
      await pump(tester, select(value: 'fr'));
      expect(find.byType(IuxRadioGroup<String>), findsNothing);

      await tester.tap(find.byType(IuxSelectField<String>));
      await tester.pumpAndSettle();

      // Not a list this component invented: the arrangement the user meets
      // when the options are open is one that had tests before this existed.
      expect(find.byType(IuxRadioGroup<String>), findsOneWidget);
      expect(find.text('Belgium'), findsOneWidget);
      expect(find.text('Switzerland'), findsOneWidget);
    });

    testWidgets('choosing reports the value and closes the list',
        (WidgetTester tester) async {
      final List<String> chosen = <String>[];
      await pump(
        tester,
        select(value: 'fr', onChanged: chosen.add),
      );

      await tester.tap(find.byType(IuxSelectField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Belgium'));
      await tester.pumpAndSettle();

      expect(chosen, <String>['be']);
      // A radio cannot be un-chosen, so an answered list has nothing left to
      // offer and holding it open would hold the page open around a finished
      // question.
      expect(find.byType(IuxRadioGroup<String>), findsNothing);
    });
  });

  group('availability is announced, not merely drawn', () {
    testWidgets('a disabled control says so and leaves the focus order',
        (WidgetTester tester) async {
      await pump(
        tester,
        select(
          value: 'fr',
          input: const IuxInputDescriptor(
            semantics: IuxInputSemantics(label: 'Country'),
            availability: IuxInputAvailability.disabled,
          ),
        ),
      );

      final SemanticsNode node = nodeOf(tester);
      expect(node.flagsCollection.isEnabled, Tristate.isFalse);
      expect(node.getSemanticsData().hasAction(SemanticsAction.focus), isFalse);
    });

    testWidgets('a read-only control keeps its place in the focus order',
        (WidgetTester tester) async {
      // Its value is still information, and a value a keyboard or
      // screen-reader user cannot reach is a value they do not have.
      await pump(
        tester,
        select(
          value: 'fr',
          input: const IuxInputDescriptor(
            semantics: IuxInputSemantics(label: 'Country'),
            availability: IuxInputAvailability.readOnly,
          ),
        ),
      );

      final SemanticsNode node = nodeOf(tester);
      expect(node.getSemanticsData().hasAction(SemanticsAction.focus), isTrue);
      expect(node.value, 'France');
    });

    testWidgets('a disabled control does not open',
        (WidgetTester tester) async {
      await pump(
        tester,
        select(
          value: 'fr',
          input: const IuxInputDescriptor(
            semantics: IuxInputSemantics(label: 'Country'),
            availability: IuxInputAvailability.disabled,
          ),
        ),
      );

      await tester.tap(find.byType(IuxSelectField<String>),
          warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(IuxRadioGroup<String>), findsNothing);
    });
  });

  group('the supporting lines behave like every other field', () {
    testWidgets(
        'help text and the error are both shown, neither replacing '
        'the other', (WidgetTester tester) async {
      await pump(
        tester,
        select(
          input: const IuxInputDescriptor(
            semantics: IuxInputSemantics(label: 'Country'),
            helpText: 'Where the order will be delivered.',
            validation: IuxInputValidation.invalid('Choose a country.'),
          ),
        ),
      );

      expect(find.text('Where the order will be delivered.'), findsOneWidget);
      expect(find.text('Choose a country.'), findsOneWidget);
    });
  });

  group('it refuses what it cannot render honestly', () {
    test('a value that is not among the options', () {
      // Otherwise the collapsed control shows its placeholder while the
      // application believes it has an answer.
      expect(
        () => IuxSelectField<String>(
          label: 'Country',
          input: country,
          value: 'de',
          options: options,
          onChanged: (String _) {},
        ),
        throwsAssertionError,
      );
    });

    test('no options at all', () {
      expect(
        () => IuxSelectField<String>(
          label: 'Country',
          input: country,
          value: null,
          options: const <IuxRadioOption<String>>[],
          onChanged: (String _) {},
        ),
        throwsAssertionError,
      );
    });
  });

  group('it survives the conditions the library promises', () {
    for (final IuxThemeConfiguration configuration in _profiles) {
      testWidgets('it renders under $configuration',
          (WidgetTester tester) async {
        await pump(tester, select(value: 'fr'), configuration: configuration);
        expect(tester.takeException(), isNull);
        expect(nodeOf(tester).value, 'France');
      });
    }

    testWidgets('at 200% text it grows and clips nothing',
        (WidgetTester tester) async {
      await pump(tester, select(value: 'fr'), textScale: 2);
      expect(tester.takeException(), isNull);

      final double tall =
          tester.getSize(find.byType(IuxSelectField<String>)).height;
      await pump(tester, select(value: 'fr'));
      final double short =
          tester.getSize(find.byType(IuxSelectField<String>)).height;

      // A control whose height does not move at 200% is a control that is
      // clipping its own text.
      expect(tall, greaterThan(short));
    });
  });
}
