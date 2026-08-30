import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

void main() {
  const IuxInputDescriptor scale = IuxInputDescriptor(
    semantics: IuxInputSemantics(label: 'Text size'),
  );

  String percent(double v) => '${(v * 100).round()}%';

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

  Widget slider({
    double value = 1.5,
    IuxInputDescriptor input = scale,
    ValueChanged<double>? onChanged,
  }) =>
      IuxSlider(
        input: input,
        value: value,
        min: 1,
        max: 2,
        divisions: 10,
        format: percent,
        decreaseLabel: 'Smaller',
        increaseLabel: 'Larger',
        onChanged: onChanged ?? (double _) {},
      );

  SemanticsNode rangeNode(WidgetTester tester) {
    SemanticsNode? node = tester.getSemantics(find.byType(IuxSlider));
    // Walk down to the node that carries the slider flag: the widget's own
    // element sits above it.
    SemanticsNode? found;
    void visit(SemanticsNode current) {
      if (current.getSemanticsData().flagsCollection.isSlider) found = current;
      current.visitChildren((SemanticsNode child) {
        visit(child);
        return true;
      });
    }

    while (node?.parent != null) {
      node = node!.parent;
    }
    visit(node!);
    expect(found, isNotNull, reason: 'no node announced itself as a slider');
    return found!;
  }

  group('clause 11.5.2.7 asks for three numbers, and all three are there', () {
    testWidgets('the current value and both ends of the range',
        (WidgetTester tester) async {
      // "the current value of a user interface element and any minimum or
      // maximum values of the range". This is the one clause in this batch the
      // platform can satisfy in full.
      await pump(tester, slider());

      final SemanticsData data = rangeNode(tester).getSemanticsData();
      expect(data.value, '150%');
      expect(data.minValue, '100%');
      expect(data.maxValue, '200%');
    });

    testWidgets('the caller formats them, so the unit is never invented',
        (WidgetTester tester) async {
      await pump(tester, slider());
      // Not "1.5". A screen reader speaks what it is given, and the framework
      // does not know this range is a percentage.
      expect(rangeNode(tester).getSemanticsData().value, '150%');
    });

    testWidgets('what the value would become, in each direction',
        (WidgetTester tester) async {
      await pump(tester, slider());

      final SemanticsData data = rangeNode(tester).getSemanticsData();
      expect(data.increasedValue, '160%');
      expect(data.decreasedValue, '140%');
    });

    testWidgets(
        'a step that would change nothing says so rather than being '
        'silent', (WidgetTester tester) async {
      await pump(tester, slider(value: 2));

      final SemanticsData data = rangeNode(tester).getSemanticsData();
      expect(data.value, '200%');
      expect(data.increasedValue, '200%');
    });
  });

  group('the drag has a single-pointer alternative, which is what permits it',
      () {
    testWidgets('both buttons exist and are named',
        (WidgetTester tester) async {
      // SC 2.5.1. Without these the track would be a path-based gesture with
      // no alternative — a conformance failure rather than a convenience.
      await pump(tester, slider());
      expect(find.bySemanticsLabel('Smaller'), findsOneWidget);
      expect(find.bySemanticsLabel('Larger'), findsOneWidget);
    });

    testWidgets('the plus button moves the value one step',
        (WidgetTester tester) async {
      final List<double> seen = <double>[];
      await pump(tester, slider(onChanged: seen.add));

      await tester.tap(find.bySemanticsLabel('Larger'));
      await tester.pump();

      expect(seen.single, closeTo(1.6, 0.0001));
    });

    testWidgets('a screen reader can move it without touching the track',
        (WidgetTester tester) async {
      final List<double> seen = <double>[];
      await pump(tester, slider(onChanged: seen.add));

      // performAction refuses a node that does not advertise the action, so
      // this cannot silently do nothing — which is what makes it a real test
      // of the screen-reader route rather than of the callback.
      tester.semantics.performAction(
        find.semantics.byLabel('Text size'),
        SemanticsAction.increase,
      );
      await tester.pump();

      expect(seen.single, closeTo(1.6, 0.0001));
    });

    testWidgets('the value snaps to a step a user can return to',
        (WidgetTester tester) async {
      // An unsnapped drag reports a number nobody can reach again with the
      // buttons.
      final List<double> seen = <double>[];
      await pump(tester, slider(value: 1, onChanged: seen.add));

      await tester.tap(find.bySemanticsLabel('Larger'));
      await tester.pump();

      expect(seen.single, closeTo(1.1, 0.0001));
    });
  });

  group('it refuses what it cannot announce honestly', () {
    test('a range with one end', () {
      expect(
        () => IuxSlider(
          input: scale,
          value: 1,
          min: 1,
          max: 1,
          divisions: 10,
          format: percent,
          decreaseLabel: 'Smaller',
          increaseLabel: 'Larger',
          onChanged: (double _) {},
        ),
        throwsAssertionError,
      );
    });

    test('a range with no steps, which no keyboard can move', () {
      expect(
        () => IuxSlider(
          input: scale,
          value: 1.5,
          min: 1,
          max: 2,
          divisions: 0,
          format: percent,
          decreaseLabel: 'Smaller',
          increaseLabel: 'Larger',
          onChanged: (double _) {},
        ),
        throwsAssertionError,
      );
    });

    test('a value outside its own range', () {
      expect(
        () => IuxSlider(
          input: scale,
          value: 3,
          min: 1,
          max: 2,
          divisions: 10,
          format: percent,
          decreaseLabel: 'Smaller',
          increaseLabel: 'Larger',
          onChanged: (double _) {},
        ),
        throwsAssertionError,
      );
    });

    test('an unnamed button', () {
      expect(
        () => IuxSlider(
          input: scale,
          value: 1.5,
          min: 1,
          max: 2,
          divisions: 10,
          format: percent,
          decreaseLabel: '',
          increaseLabel: 'Larger',
          onChanged: (double _) {},
        ),
        throwsAssertionError,
      );
    });
  });

  group('it survives the conditions the library promises', () {
    testWidgets('the value is on screen, not only in the bar',
        (WidgetTester tester) async {
      // A slider whose position is its only readout is unreadable to anyone
      // who cannot judge a bar against its ends, which is most people at a
      // glance.
      await pump(tester, slider());
      expect(find.text('150%'), findsOneWidget);
    });

    testWidgets('at 200% text it grows and keeps its parts',
        (WidgetTester tester) async {
      await pump(tester, slider(), textScale: 2);
      expect(tester.takeException(), isNull);
      expect(find.bySemanticsLabel('Smaller'), findsOneWidget);
      expect(find.text('150%'), findsOneWidget);
    });

    testWidgets('a disabled range announces itself disabled',
        (WidgetTester tester) async {
      await pump(
        tester,
        slider(
          input: const IuxInputDescriptor(
            semantics: IuxInputSemantics(label: 'Text size'),
            availability: IuxInputAvailability.disabled,
          ),
        ),
      );

      expect(
        rangeNode(tester).getSemanticsData().flagsCollection.isEnabled,
        isNot(Tristate.isTrue),
      );
    });
  });
}
