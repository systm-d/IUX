import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

/// `IuxTagChip.removable`: a tag the user can take back out of a list they
/// built (systm-d/IUX#68).
void main() {
  Future<void> host(
    WidgetTester tester,
    Widget child, {
    double textScale = 1,
    TextDirection direction = TextDirection.ltr,
  }) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: const Size(400, 800),
          textScaler: TextScaler.linear(textScale),
        ),
        child: MaterialApp(
          theme: IuxTheme.fromConfiguration(const IuxThemeConfiguration()),
          home: Directionality(
            textDirection: direction,
            child: Scaffold(body: Center(child: child)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// A list of organisations the user edits, with the field it grows from
  /// standing in front of it — the shape the report describes.
  Widget organisations(List<String> names, ValueChanged<String> onRemove) =>
      Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IuxButton(
            label: 'Add organisation',
            action: const IuxActionDescriptor(
              semantics: IuxActionSemantics(label: 'Add organisation'),
            ),
            onActivate: () {},
          ),
          IuxChipGroup(
            label: 'Organisations',
            chips: <Widget>[
              for (final String name in names)
                IuxTagChip.removable(
                  key: ValueKey<String>(name),
                  label: name,
                  removeLabel: 'Remove $name',
                  onRemove: () => onRemove(name),
                ),
            ],
          ),
        ],
      );

  /// A stateful host, so a removal really takes the tag out of the tree.
  Widget editable(List<String> initial, List<String> removed) =>
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) => organisations(
          initial,
          (String name) => setState(() {
            initial.remove(name);
            removed.add(name);
          }),
        ),
      );

  Finder removeButton(String name) => find.ancestor(
        of: find.byIcon(Icons.close),
        matching: find.byWidgetPredicate(
          (Widget w) =>
              w is IuxIconButton && w.action.semantics.label == 'Remove $name',
        ),
      );

  group('it removes, and only the button does', () {
    testWidgets('a tap on the button asks the parent to remove the tag',
        (WidgetTester tester) async {
      final List<String> removed = <String>[];
      await host(tester, editable(<String>['acme', 'globex'], removed));

      await tester.tap(removeButton('acme'));
      await tester.pumpAndSettle();

      expect(removed, <String>['acme']);
      expect(find.text('acme'), findsNothing);
      expect(find.text('globex'), findsOneWidget);
    });

    testWidgets('a tap on the tag body does nothing',
        (WidgetTester tester) async {
      // The body is still a tag. A tag that removed itself when touched would
      // be a delete control the size of the label, with no name saying so.
      final List<String> removed = <String>[];
      await host(tester, editable(<String>['acme'], removed));

      await tester.tap(find.text('acme'));
      await tester.pumpAndSettle();
      expect(removed, isEmpty);
    });

    testWidgets('the remove target meets the floor, whatever the tag measures',
        (WidgetTester tester) async {
      await host(tester, editable(<String>['a'], <String>[]));
      final Size target = tester.getSize(removeButton('a'));
      expect(target.width, greaterThanOrEqualTo(IuxTouchTarget.minimum));
      expect(target.height, greaterThanOrEqualTo(IuxTouchTarget.minimum));
    });

    testWidgets('the tag contains its button, so the two read as one object',
        (WidgetTester tester) async {
      await host(tester, editable(<String>['acme'], <String>[]));
      final Rect tag = tester.getRect(find.byType(IuxTagChip));
      final Rect button = tester.getRect(removeButton('acme'));
      expect(tag.contains(button.center), isTrue);
      expect(tag.contains(tester.getCenter(find.text('acme'))), isTrue);
    });
  });

  group('it is announced as a tag holding one control', () {
    testWidgets('the button is a button, named with the tag it removes',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(tester, editable(<String>['acme'], <String>[]));

      expect(
        tester.getSemantics(find.bySemanticsLabel('Remove acme')),
        isSemantics(
          label: 'Remove acme',
          isButton: true,
          hasTapAction: true,
          isFocusable: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('the tag text stays text, never part of the button',
        (WidgetTester tester) async {
      // Merged, the whole tag would be announced as a button called "acme,
      // Remove acme" — the failure the read-only form exists to prevent,
      // arriving through its sibling.
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(tester, editable(<String>['acme'], <String>[]));

      final SemanticsNode text = tester.getSemantics(find.text('acme'));
      expect(text.label, 'acme');
      expect(text.flagsCollection.isButton, isFalse);
      expect(text.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
      handle.dispose();
    });

    testWidgets('one focus stop per tag, and it is the button',
        (WidgetTester tester) async {
      await host(tester, editable(<String>['acme', 'globex'], <String>[]));

      // Past the add button, then one stop per tag.
      final FocusNode add =
          Focus.of(tester.element(find.text('Add organisation')));
      add.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'remove acme',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'remove globex',
      );
    });
  });

  group('focus survives the removal', () {
    Future<void> focusRemove(WidgetTester tester, String name) async {
      final FocusNode node = Focus.of(
        tester.element(
          find.descendant(
              of: removeButton(name), matching: find.byIcon(Icons.close)),
        ),
      );
      node.requestFocus();
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'remove $name');
    }

    testWidgets('removing from the keyboard lands on the tag before it',
        (WidgetTester tester) async {
      final List<String> removed = <String>[];
      await host(
          tester, editable(<String>['acme', 'globex', 'initech'], removed));

      await focusRemove(tester, 'globex');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(removed, <String>['globex']);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'remove acme');
    });

    testWidgets('removing the first tag lands on what the list grows from',
        (WidgetTester tester) async {
      final List<String> removed = <String>[];
      await host(tester, editable(<String>['acme', 'globex'], removed));

      await focusRemove(tester, 'acme');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(removed, <String>['acme']);
      final FocusNode? now = FocusManager.instance.primaryFocus;
      expect(now, isNotNull);
      // Focus is on a live node inside the page, not dropped to the scope.
      expect(now!.context, isNotNull);
      expect(
        find.ancestor(
          of: find.byWidget(now.context!.widget),
          matching: find.byType(IuxButton),
        ),
        findsOneWidget,
        reason: 'focus should be on "Add organisation", the stop before '
            'the list',
      );
    });

    testWidgets('a tap moves no focus', (WidgetTester tester) async {
      final List<String> removed = <String>[];
      await host(tester, editable(<String>['acme', 'globex'], removed));
      final FocusNode? before = FocusManager.instance.primaryFocus;

      await tester.tap(removeButton('globex'));
      await tester.pumpAndSettle();

      expect(removed, <String>['globex']);
      expect(FocusManager.instance.primaryFocus, same(before));
    });
  });

  group('it refuses a remove button that does not say what it removes', () {
    test('an empty name', () {
      expect(
        () => IuxTagChip.removable(
          label: 'acme',
          removeLabel: '',
          onRemove: () {},
        ),
        throwsAssertionError,
      );
    });

    testWidgets('a name that leaves the tag out', (WidgetTester tester) async {
      // Five buttons called "Remove" are five guesses to a user listing the
      // controls on the page.
      await tester.pumpWidget(
        MaterialApp(
          theme: IuxTheme.fromConfiguration(const IuxThemeConfiguration()),
          home: IuxTagChip.removable(
            label: 'acme',
            removeLabel: 'Remove',
            onRemove: () {},
          ),
        ),
      );
      expect(tester.takeException(), isAssertionError);
    });

    testWidgets('case is not the caller\'s problem',
        (WidgetTester tester) async {
      await host(
        tester,
        IuxTagChip.removable(
          label: 'Vegetarian',
          removeLabel: 'Remove vegetarian',
          onRemove: () {},
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('the read-only tag is unchanged', () {
    testWidgets('it still takes no focus and no gesture',
        (WidgetTester tester) async {
      await host(tester, const IuxTagChip(label: 'Vegetarian'));
      expect(
        find.descendant(
          of: find.byType(IuxTagChip),
          matching: find.byType(IuxIconButton),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(IuxTagChip),
          matching: find.byType(Focus),
        ),
        findsNothing,
      );
    });
  });

  group('it survives the conditions the library promises', () {
    testWidgets('at 200% text a long name wraps rather than overflowing',
        (WidgetTester tester) async {
      await host(
        tester,
        editable(<String>['a-very-long-organisation-name-indeed'], <String>[]),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      expect(
        tester
            .getSize(removeButton('a-very-long-organisation-name-indeed'))
            .width,
        greaterThanOrEqualTo(IuxTouchTarget.minimum),
      );
    });

    testWidgets('right to left puts the button at the reading end',
        (WidgetTester tester) async {
      await host(
        tester,
        editable(<String>['acme'], <String>[]),
        direction: TextDirection.rtl,
      );
      expect(
        tester.getCenter(removeButton('acme')).dx,
        lessThan(tester.getCenter(find.text('acme')).dx),
      );
    });

    testWidgets('two removable tags keep the separation between targets',
        (WidgetTester tester) async {
      await host(tester, editable(<String>['acme', 'globex'], <String>[]));
      final Rect a = tester.getRect(find.byKey(const ValueKey<String>('acme')));
      final Rect b =
          tester.getRect(find.byKey(const ValueKey<String>('globex')));
      final double gap =
          b.left >= a.right ? b.left - a.right : b.top - a.bottom;
      expect(gap, greaterThanOrEqualTo(kIuxMinimumTargetSpacing));
    });
  });
}
