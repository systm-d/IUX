import 'dart:ui' show SemanticsInputType;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

/// The helpers a component reaches for when `IuxSemantics.action` is the wrong
/// shape.
///
/// `action` excludes the subtree it wraps. That is right for a button whose
/// label says everything and silently wrong everywhere else: it deletes a
/// card's content, a field's text-editing actions and a control's own tap
/// action. Every helper here exists because that exclusion had to be refused,
/// so what these tests mostly assert is what survives.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: IuxTheme.light(),
        home: Scaffold(body: Center(child: child)),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// How many separate stops a screen reader finds below [node].
  ///
  /// A node merged into its parent is not a stop: the user cannot land on it.
  int stopsBelow(SemanticsNode node) {
    int count = 0;
    void visit(SemanticsNode parent) {
      parent.visitChildren((SemanticsNode child) {
        if (!child.isMergedIntoParent) count++;
        visit(child);
        return true;
      });
    }

    visit(node);
    return count;
  }

  group('IuxSemantics.selection', () {
    testWidgets('a checkbox announces a checked state',
        (WidgetTester tester) async {
      await pump(
        tester,
        IuxSemantics.selection(
          role: IuxSelectionRole.checkbox,
          value: IuxSelectionValue.selected,
          label: 'Send me the newsletter',
          onTap: () {},
          child: const SizedBox(width: 40, height: 40),
        ),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('Send me the newsletter')),
        matchesSemantics(
          label: 'Send me the newsletter',
          hasCheckedState: true,
          isChecked: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
    });

    testWidgets('a partly chosen checkbox announces a mixed state',
        (WidgetTester tester) async {
      await pump(
        tester,
        IuxSemantics.selection(
          role: IuxSelectionRole.checkbox,
          value: IuxSelectionValue.partial,
          label: 'Select all',
          onTap: () {},
          child: const SizedBox(width: 40, height: 40),
        ),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('Select all')),
        isSemantics(hasCheckedState: true, isCheckStateMixed: true),
      );
    });

    testWidgets('a switch announces a toggled state, never a checked one',
        (WidgetTester tester) async {
      // Android reads the two differently. A switch announced as a checkbox
      // tells the user a Save button is coming that does not exist.
      await pump(
        tester,
        IuxSemantics.selection(
          role: IuxSelectionRole.toggle,
          value: IuxSelectionValue.selected,
          label: 'Use mobile data',
          onTap: () {},
          child: const SizedBox(width: 40, height: 40),
        ),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('Use mobile data')),
        matchesSemantics(
          label: 'Use mobile data',
          hasToggledState: true,
          isToggled: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
    });

    testWidgets('a radio announces membership of a mutually exclusive group',
        (WidgetTester tester) async {
      await pump(
        tester,
        IuxSemantics.selection(
          role: IuxSelectionRole.radio,
          value: IuxSelectionValue.unselected,
          label: 'Express',
          onTap: () {},
          child: const SizedBox(width: 40, height: 40),
        ),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('Express')),
        isSemantics(
          isInMutuallyExclusiveGroup: true,
          hasCheckedState: true,
          isChecked: false,
        ),
      );
    });

    testWidgets('the excluded subtree costs the control nothing to activate',
        (WidgetTester tester) async {
      // The defect this helper is built around. Everything below the node is
      // excluded, so the tap action has to live on the node itself; without it
      // the control is announced correctly and refuses to respond.
      int taps = 0;
      await pump(
        tester,
        IuxSemantics.selection(
          role: IuxSelectionRole.checkbox,
          value: IuxSelectionValue.unselected,
          label: 'Send me the newsletter',
          onTap: () => taps++,
          child: GestureDetector(
            onTap: () => taps += 100,
            child: const SizedBox(width: 40, height: 40),
          ),
        ),
      );

      tester.semantics.tap(find.semantics.byLabel('Send me the newsletter'));
      await tester.pumpAndSettle();

      expect(
        taps,
        1,
        reason: 'the node itself answers; the excluded child never hears it',
      );
    });

    testWidgets('a disabled control offers no action it cannot honour',
        (WidgetTester tester) async {
      await pump(
        tester,
        IuxSemantics.selection(
          role: IuxSelectionRole.checkbox,
          value: IuxSelectionValue.unselected,
          label: 'Send me the newsletter',
          hint: 'Confirm your address first',
          enabled: false,
          onTap: () {},
          child: const SizedBox(width: 40, height: 40),
        ),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('Send me the newsletter')),
        matchesSemantics(
          label: 'Send me the newsletter',
          hint: 'Confirm your address first',
          hasCheckedState: true,
          hasEnabledState: true,
        ),
      );
    });

    testWidgets('read-only is announced without announcing anything else',
        (WidgetTester tester) async {
      // Read-only is not disabled: the control keeps its place in the focus
      // order and still announces its value.
      await pump(
        tester,
        IuxSemantics.selection(
          role: IuxSelectionRole.checkbox,
          value: IuxSelectionValue.unselected,
          label: 'Send me the newsletter',
          readOnly: true,
          child: const SizedBox(width: 40, height: 40),
        ),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('Send me the newsletter')),
        matchesSemantics(
          label: 'Send me the newsletter',
          hasCheckedState: true,
          hasEnabledState: true,
          isEnabled: true,
          isReadOnly: true,
        ),
      );
    });

    testWidgets('a required control says an answer is expected',
        (WidgetTester tester) async {
      await pump(
        tester,
        IuxSemantics.selection(
          role: IuxSelectionRole.checkbox,
          value: IuxSelectionValue.unselected,
          label: 'Accept the terms',
          isRequired: true,
          onTap: () {},
          child: const SizedBox(width: 40, height: 40),
        ),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('Accept the terms')),
        isSemantics(hasRequiredState: true, isRequired: true),
      );
    });

    test('a mixed state is refused on anything but a checkbox', () {
      // A switch has two physical positions and a radio is one option among
      // several, so neither has anywhere to put a partly-chosen state.
      expect(
        () => IuxSemantics.selection(
          role: IuxSelectionRole.toggle,
          value: IuxSelectionValue.partial,
          label: 'Use mobile data',
          child: const SizedBox.shrink(),
        ),
        throwsAssertionError,
      );
    });

    test('an unnamed control is refused', () {
      expect(
        () => IuxSemantics.selection(
          role: IuxSelectionRole.checkbox,
          value: IuxSelectionValue.unselected,
          label: '',
          child: const SizedBox.shrink(),
        ),
        throwsAssertionError,
      );
    });
  });

  group('IuxSemantics.radioGroup', () {
    testWidgets('it names the question the options answer',
        (WidgetTester tester) async {
      await pump(
        tester,
        IuxSemantics.radioGroup(
          label: 'Delivery speed',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IuxSemantics.selection(
                role: IuxSelectionRole.radio,
                value: IuxSelectionValue.selected,
                label: 'Standard',
                child: const SizedBox(width: 40, height: 40),
              ),
              IuxSemantics.selection(
                role: IuxSelectionRole.radio,
                value: IuxSelectionValue.unselected,
                label: 'Express',
                onTap: () {},
                child: const SizedBox(width: 40, height: 40),
              ),
            ],
          ),
        ),
      );

      final SemanticsNode group =
          tester.getSemantics(find.bySemanticsLabel('Delivery speed'));

      expect(
        group.role,
        SemanticsRole.radioGroup,
        reason: 'the role is what lets the platform count "1 of 2"',
      );
      expect(group.label, 'Delivery speed');
    });

    testWidgets('the options stay separate stops inside it',
        (WidgetTester tester) async {
      // A group that absorbed its options would announce the whole question as
      // one sentence with nothing in it to land on.
      await pump(
        tester,
        IuxSemantics.radioGroup(
          label: 'Delivery speed',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IuxSemantics.selection(
                role: IuxSelectionRole.radio,
                value: IuxSelectionValue.selected,
                label: 'Standard',
                child: const SizedBox(width: 40, height: 40),
              ),
              IuxSemantics.selection(
                role: IuxSelectionRole.radio,
                value: IuxSelectionValue.unselected,
                label: 'Express',
                onTap: () {},
                child: const SizedBox(width: 40, height: 40),
              ),
            ],
          ),
        ),
      );

      expect(
        stopsBelow(
            tester.getSemantics(find.bySemanticsLabel('Delivery speed'))),
        2,
      );
    });

    test('an unnamed group is refused', () {
      expect(
        () => IuxSemantics.radioGroup(
          label: '',
          child: const SizedBox.shrink(),
        ),
        throwsAssertionError,
      );
    });
  });

  group('IuxSemantics.field', () {
    late TextEditingController controller;

    setUp(() => controller = TextEditingController(text: 'abc'));
    tearDown(() => controller.dispose());

    testWidgets('the name lands on the node the user types into',
        (WidgetTester tester) async {
      await pump(
        tester,
        IuxSemantics.field(
          label: 'Email address',
          child: TextField(controller: controller),
        ),
      );

      expect(
        tester.getSemantics(find.byType(TextField)),
        isSemantics(
          label: 'Email address',
          value: 'abc',
          isTextField: true,
          isEnabled: true,
        ),
      );
    });

    testWidgets('naming the field does not cost it its editing actions',
        (WidgetTester tester) async {
      // The reason this helper is not `action`. Excluding the subtree would
      // take set-text, set-selection and move-cursor with it, leaving a field
      // a screen reader can find, announce, and never type into.
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);

      await pump(
        tester,
        IuxSemantics.field(
          label: 'Email address',
          child: TextField(controller: controller, focusNode: node),
        ),
      );

      node.requestFocus();
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.byType(TextField)),
        isSemantics(
          isFocused: true,
          hasSetTextAction: true,
          hasSetSelectionAction: true,
          hasMoveCursorBackwardByCharacterAction: true,
        ),
      );
    });

    testWidgets('state is announced as properties, not spelled into the name',
        (WidgetTester tester) async {
      await pump(
        tester,
        IuxSemantics.field(
          label: 'Email address',
          hint: 'We only use it for receipts',
          readOnly: true,
          isRequired: true,
          validation: SemanticsValidationResult.invalid,
          inputType: SemanticsInputType.email,
          child: TextField(controller: controller, readOnly: true),
        ),
      );

      final SemanticsNode node = tester.getSemantics(find.byType(TextField));

      expect(
        node,
        isSemantics(
          label: 'Email address',
          hint: 'We only use it for receipts',
          isReadOnly: true,
          isRequired: true,
          isEnabled: true,
        ),
      );
      expect(node.validationResult, SemanticsValidationResult.invalid);
      expect(node.inputType, SemanticsInputType.email);
      expect(
        node.label,
        'Email address',
        reason: 'no asterisk and no "required" composed into the name: the '
            'platform speaks the property in the user\'s own language',
      );
    });

    testWidgets('a disabled field says so', (WidgetTester tester) async {
      await pump(
        tester,
        IuxSemantics.field(
          label: 'Email address',
          enabled: false,
          child: TextField(controller: controller, enabled: false),
        ),
      );

      expect(
        tester.getSemantics(find.byType(TextField)),
        isSemantics(hasEnabledState: true, isEnabled: false),
      );
    });

    test('an unnamed field is refused', () {
      expect(
        () => IuxSemantics.field(
          label: '',
          child: const SizedBox.shrink(),
        ),
        throwsAssertionError,
      );
    });
  });

  group('IuxSemantics.contentAction', () {
    testWidgets('it announces its name, its role and its content',
        (WidgetTester tester) async {
      // The name says what the user is about to do; the content says what they
      // are looking at. Dropping the content would delete the status and the
      // amount from the interface of every screen-reader user.
      await pump(
        tester,
        IuxSemantics.contentAction(
          label: 'Open order 3141',
          hint: 'Opens the order',
          onTap: () {},
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[Text('Order 3141'), Text('Delivered')],
          ),
        ),
      );

      final SemanticsNode node = tester.getSemantics(find.text('Order 3141'));

      expect(node, isSemantics(isButton: true, isEnabled: true));
      expect(node.getSemanticsData().label, contains('Open order 3141'));
      expect(node.getSemanticsData().label, contains('Order 3141'));
      expect(node.getSemanticsData().label, contains('Delivered'));
      expect(node.getSemanticsData().hint, contains('Opens the order'));
    });

    testWidgets('the whole block is a single stop',
        (WidgetTester tester) async {
      await pump(
        tester,
        IuxSemantics.contentAction(
          label: 'Open order 3141',
          onTap: () {},
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[Text('Order 3141'), Text('Delivered')],
          ),
        ),
      );

      expect(
        stopsBelow(tester.getSemantics(find.text('Order 3141'))),
        0,
        reason: 'one control has to be one stop, or the user cannot tell '
            'which of its lines activates',
      );
    });

    testWidgets('it carries its own activation, with nothing tappable inside',
        (WidgetTester tester) async {
      int taps = 0;
      await pump(
        tester,
        IuxSemantics.contentAction(
          label: 'Open order 3141',
          onTap: () => taps++,
          child: const Text('Order 3141'),
        ),
      );

      expect(
        tester.getSemantics(find.text('Order 3141')),
        isSemantics(hasTapAction: true),
      );

      tester.semantics.tap(find.semantics.byLabel(RegExp('Open order 3141')));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('a disabled block offers no action it cannot honour',
        (WidgetTester tester) async {
      await pump(
        tester,
        IuxSemantics.contentAction(
          label: 'Open order 3141',
          enabled: false,
          onTap: () {},
          child: const Text('Order 3141'),
        ),
      );

      expect(
        tester.getSemantics(find.text('Order 3141')),
        isSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
          hasTapAction: false,
        ),
      );
    });

    test('an unnamed control is refused', () {
      expect(
        () => IuxSemantics.contentAction(
          label: '',
          onTap: () {},
          child: const SizedBox.shrink(),
        ),
        throwsAssertionError,
      );
    });
  });

  group('IuxSemantics.contentContainer', () {
    testWidgets('it is not announced as a control',
        (WidgetTester tester) async {
      await pump(
        tester,
        IuxSemantics.contentContainer(child: const Text('Order 3141')),
      );

      expect(
        tester.getSemantics(find.byType(Text)),
        isSemantics(isButton: false, hasTapAction: false),
      );
    });

    testWidgets('a control inside it keeps the node the user lands on',
        (WidgetTester tester) async {
      // Without explicit child nodes, a control that does not declare itself a
      // container has its name and its role absorbed into this one: the block
      // is announced as a button called "Order 3141, Track", and the control
      // it came from no longer exists as somewhere to land.
      await pump(
        tester,
        IuxSemantics.contentContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('Order 3141'),
              IuxSemantics.action(
                label: 'Track',
                onTap: () {},
                child: const SizedBox(width: 40, height: 40),
              ),
            ],
          ),
        ),
      );

      expect(find.bySemanticsLabel('Track'), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Track')),
        isSemantics(isButton: true, hasTapAction: true),
      );
    });
  });

  group('IuxSemantics.route', () {
    testWidgets('it scopes and names the layer', (WidgetTester tester) async {
      await pump(
        tester,
        IuxSemantics.route(
          label: 'Delete this invoice?',
          child: const SizedBox(width: 80, height: 80),
        ),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('Delete this invoice?')),
        isSemantics(
          scopesRoute: true,
          namesRoute: true,
          label: 'Delete this invoice?',
        ),
      );
    });

    testWidgets('the controls it contains stay individually reachable',
        (WidgetTester tester) async {
      // A route that absorbed its subtree would announce the change of context
      // and then offer nothing to answer it with.
      await pump(
        tester,
        IuxSemantics.route(
          label: 'Delete this invoice?',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IuxSemantics.action(
                label: 'Keep it',
                onTap: () {},
                child: const SizedBox(width: 40, height: 40),
              ),
              IuxSemantics.action(
                label: 'Delete',
                onTap: () {},
                child: const SizedBox(width: 40, height: 40),
              ),
            ],
          ),
        ),
      );

      expect(find.bySemanticsLabel('Keep it'), findsOneWidget);
      expect(find.bySemanticsLabel('Delete'), findsOneWidget);
    });

    test('an unnamed route is refused', () {
      // Scoping without naming announces that something took over the screen
      // and refuses to say what.
      expect(
        () => IuxSemantics.route(
          label: '',
          child: const SizedBox.shrink(),
        ),
        throwsAssertionError,
      );
    });
  });
}
