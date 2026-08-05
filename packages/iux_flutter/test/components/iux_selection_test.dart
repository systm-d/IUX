import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

/// The four theme profiles every component has to survive.
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
  const IuxInputDescriptor newsletter = IuxInputDescriptor(
    semantics: IuxInputSemantics(label: 'Send me the newsletter'),
  );

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    IuxThemeConfiguration configuration = const IuxThemeConfiguration(),
    TextDirection direction = TextDirection.ltr,
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
          home: Directionality(
            textDirection: direction,
            child: Scaffold(
              body: SingleChildScrollView(child: child),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  IuxCheckbox checkbox({
    String label = 'Send me the newsletter',
    IuxInputDescriptor input = newsletter,
    IuxSelectionState value = IuxSelectionState.unselected,
    required ValueChanged<bool> onChanged,
    bool autofocus = false,
  }) =>
      IuxCheckbox(
        label: label,
        input: input,
        value: value,
        onChanged: onChanged,
        autofocus: autofocus,
      );

  group('the parent owns the value', () {
    testWidgets(
        'an activation reports the selection and changes nothing itself',
        (WidgetTester tester) async {
      final List<bool> asked = <bool>[];
      await pump(tester, checkbox(onChanged: asked.add));

      await tester.tap(find.byType(IuxCheckbox));
      await tester.pumpAndSettle();

      expect(asked, <bool>[true]);
      expect(
        tester.widget<IuxCheckbox>(find.byType(IuxCheckbox)).value,
        IuxSelectionState.unselected,
        reason: 'the widget must not flip itself; only the parent may, and a '
            'control that moved before the write succeeded would have told the '
            'user something untrue',
      );
    });

    testWidgets('a chosen control asks to be unchosen',
        (WidgetTester tester) async {
      final List<bool> asked = <bool>[];
      await pump(
        tester,
        checkbox(value: IuxSelectionState.selected, onChanged: asked.add),
      );

      await tester.tap(find.byType(IuxCheckbox));
      await tester.pumpAndSettle();

      expect(asked, <bool>[false]);
    });

    testWidgets('a partly chosen summary asks to select all, never to clear it',
        (WidgetTester tester) async {
      // The expensive direction to be wrong in: clearing would destroy the
      // choices the user had already made.
      final List<bool> asked = <bool>[];
      await pump(
        tester,
        checkbox(value: IuxSelectionState.partial, onChanged: asked.add),
      );

      await tester.tap(find.byType(IuxCheckbox));
      await tester.pumpAndSettle();

      expect(asked, <bool>[true]);
    });

    testWidgets('a disabled control never calls back',
        (WidgetTester tester) async {
      final List<bool> asked = <bool>[];
      await pump(
        tester,
        checkbox(
          input: newsletter.copyWith(
            availability: IuxInputAvailability.disabled,
          ),
          onChanged: asked.add,
        ),
      );

      await tester.tap(find.byType(IuxCheckbox), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(asked, isEmpty);
    });

    testWidgets('a read-only control never calls back yet stays reachable',
        (WidgetTester tester) async {
      // A value a keyboard or screen-reader user cannot reach is a value they
      // do not have, so read-only stays in the focus order.
      final List<bool> asked = <bool>[];
      await pump(
        tester,
        checkbox(
          input: newsletter.copyWith(
            availability: IuxInputAvailability.readOnly,
          ),
          onChanged: asked.add,
        ),
      );

      await tester.tap(find.byType(IuxCheckbox), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(asked, isEmpty);
      expect(
        tester
            .widget<Focus>(
              find
                  .descendant(
                    of: find.byType(IuxCheckbox),
                    matching: find.byType(Focus),
                  )
                  .first,
            )
            .canRequestFocus,
        isTrue,
      );
    });

    testWidgets('a disabled control leaves the focus order',
        (WidgetTester tester) async {
      await pump(
        tester,
        checkbox(
          input: newsletter.copyWith(
            availability: IuxInputAvailability.disabled,
          ),
          onChanged: (_) {},
        ),
      );

      expect(
        tester
            .widget<Focus>(
              find
                  .descendant(
                    of: find.byType(IuxCheckbox),
                    matching: find.byType(Focus),
                  )
                  .first,
            )
            .canRequestFocus,
        isFalse,
      );
    });
  });

  group('the label is part of the target', () {
    testWidgets('tapping the text toggles the control',
        (WidgetTester tester) async {
      // A 24-pixel box with an untappable label beside it is the classic
      // failure of this component family.
      final List<bool> asked = <bool>[];
      await pump(tester, checkbox(onChanged: asked.add));

      await tester.tap(find.text('Send me the newsletter'));
      await tester.pumpAndSettle();

      expect(asked, <bool>[true]);
    });

    testWidgets('tapping the help text toggles the control too',
        (WidgetTester tester) async {
      final List<bool> asked = <bool>[];
      await pump(
        tester,
        checkbox(
          input: newsletter.copyWith(helpText: 'About once a month'),
          onChanged: asked.add,
        ),
      );

      await tester.tap(find.text('About once a month'));
      await tester.pumpAndSettle();

      expect(asked, <bool>[true]);
    });
  });

  group('keyboard', () {
    testWidgets('Enter and Space each activate a focused control',
        (WidgetTester tester) async {
      final List<bool> asked = <bool>[];
      await pump(tester, checkbox(autofocus: true, onChanged: asked.add));

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(asked, <bool>[true, true]);
    });
  });

  group('the target is large enough and far enough from its neighbour', () {
    testWidgets('the whole row meets the resolved floor at every density',
        (WidgetTester tester) async {
      for (final IuxDensity density in IuxDensity.values) {
        await pump(
          tester,
          checkbox(label: 'Ok', onChanged: (_) {}),
          configuration: IuxThemeConfiguration(
            profile: IuxAccessibilityProfile(density: density),
          ),
        );
        expect(
          tester.getSize(find.byType(IuxTapTarget)).height,
          greaterThanOrEqualTo(IuxTouchTarget.minimum),
          reason: '${density.name} produced too small a target',
        );
      }
    });

    testWidgets('a comfortable preference enlarges it',
        (WidgetTester tester) async {
      await pump(
        tester,
        checkbox(label: 'Ok', onChanged: (_) {}),
        configuration: const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(
            touchTarget: IuxTouchTargetPreference.comfortable,
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(IuxTapTarget)).height,
        greaterThanOrEqualTo(IuxTouchTarget.comfortable),
      );
    });

    testWidgets('adjacent controls keep the spacing floor between them',
        (WidgetTester tester) async {
      // Two touching 48-pixel targets still produce mis-taps: a finger landing
      // near the seam has no margin for error.
      await pump(
        tester,
        IuxSelectionGroup(
          label: 'Notify me about',
          children: <Widget>[
            checkbox(label: 'Replies', onChanged: (_) {}),
            checkbox(label: 'Mentions', onChanged: (_) {}),
          ],
        ),
      );

      final Rect first = tester.getRect(find.byType(IuxTapTarget).at(0));
      final Rect second = tester.getRect(find.byType(IuxTapTarget).at(1));

      expect(
        second.top - first.bottom,
        greaterThanOrEqualTo(kIuxMinimumTargetSpacing),
      );
    });

    testWidgets('radio options keep the spacing floor between them',
        (WidgetTester tester) async {
      await pump(tester, _speedGroup(onChanged: (_) {}));

      final Rect first = tester.getRect(find.byType(IuxTapTarget).at(0));
      final Rect second = tester.getRect(find.byType(IuxTapTarget).at(1));

      expect(
        second.top - first.bottom,
        greaterThanOrEqualTo(kIuxMinimumTargetSpacing),
      );
    });
  });

  group('semantics say which control this is', () {
    testWidgets('a checkbox announces a checked state',
        (WidgetTester tester) async {
      await pump(
        tester,
        checkbox(value: IuxSelectionState.selected, onChanged: (_) {}),
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
          // The exclusion that sets the announced name also takes the
          // Focus widget's annotations, so the node has to publish the
          // focus itself or assistive technology cannot move
          // accessibility focus here — IUX-A11Y-FOCUS-001.
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
    });

    testWidgets('a partly chosen checkbox announces a mixed state',
        (WidgetTester tester) async {
      await pump(
        tester,
        checkbox(value: IuxSelectionState.partial, onChanged: (_) {}),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('Send me the newsletter')),
        matchesSemantics(
          label: 'Send me the newsletter',
          hasCheckedState: true,
          isCheckStateMixed: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          // The exclusion that sets the announced name also takes the
          // Focus widget's annotations, so the node has to publish the
          // focus itself or assistive technology cannot move
          // accessibility focus here — IUX-A11Y-FOCUS-001.
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
    });

    testWidgets('a switch announces a toggled state, never a checked one',
        (WidgetTester tester) async {
      // Android reads the two differently. A switch announced as a checkbox
      // tells the user a Save button is coming.
      await pump(
        tester,
        IuxSwitch(
          label: 'Use mobile data',
          input: const IuxInputDescriptor(
            semantics: IuxInputSemantics(label: 'Use mobile data'),
          ),
          value: IuxSelectionState.selected,
          onChanged: (_) {},
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
          // The exclusion that sets the announced name also takes the
          // Focus widget's annotations, so the node has to publish the
          // focus itself or assistive technology cannot move
          // accessibility focus here — IUX-A11Y-FOCUS-001.
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
    });

    testWidgets('a radio announces membership of a mutually exclusive group',
        (WidgetTester tester) async {
      await pump(tester, _speedGroup(value: 'express', onChanged: (_) {}));

      expect(
        tester.getSemantics(find.bySemanticsLabel('Express')),
        matchesSemantics(
          label: 'Express',
          isInMutuallyExclusiveGroup: true,
          hasCheckedState: true,
          isChecked: true,
          hasEnabledState: true,
          isEnabled: true,
          // The exclusion that sets the announced name also takes the
          // Focus widget's annotations, so the node has to publish the
          // focus itself or assistive technology cannot move
          // accessibility focus here — IUX-A11Y-FOCUS-001.
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Standard')),
        matchesSemantics(
          label: 'Standard',
          isInMutuallyExclusiveGroup: true,
          hasCheckedState: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          // The exclusion that sets the announced name also takes the
          // Focus widget's annotations, so the node has to publish the
          // focus itself or assistive technology cannot move
          // accessibility focus here — IUX-A11Y-FOCUS-001.
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
    });

    testWidgets('a screen reader can activate the control',
        (WidgetTester tester) async {
      // Everything below the node is excluded from the semantic tree, so the
      // tap action has to live on the node itself. Without it the control
      // would be announced correctly and refuse to respond.
      final List<bool> asked = <bool>[];
      await pump(tester, checkbox(onChanged: asked.add));

      tester.semantics.tap(find.semantics.byLabel('Send me the newsletter'));
      await tester.pumpAndSettle();

      expect(asked, <bool>[true]);
    });

    testWidgets('an unavailable control explains itself',
        (WidgetTester tester) async {
      // A greyed control with no explanation leaves the user unable to tell
      // whether they did something wrong or it does not apply to them.
      await pump(
        tester,
        checkbox(
          input: const IuxInputDescriptor(
            semantics: IuxInputSemantics(
              label: 'Send me the newsletter',
              unavailabilityReason: 'Confirm your address first',
            ),
            availability: IuxInputAvailability.disabled,
          ),
          onChanged: (_) {},
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

    testWidgets('a required control says an answer is expected',
        (WidgetTester tester) async {
      await pump(
        tester,
        checkbox(
          input: newsletter.copyWith(
            requirement: IuxInputRequirement.required,
          ),
          onChanged: (_) {},
        ),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('Send me the newsletter')),
        matchesSemantics(
          label: 'Send me the newsletter',
          hasCheckedState: true,
          hasEnabledState: true,
          isEnabled: true,
          hasRequiredState: true,
          isRequired: true,
          hasTapAction: true,
          // The exclusion that sets the announced name also takes the
          // Focus widget's annotations, so the node has to publish the
          // focus itself or assistive technology cannot move
          // accessibility focus here — IUX-A11Y-FOCUS-001.
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
    });

    testWidgets('a read-only control announces that it cannot be changed',
        (WidgetTester tester) async {
      await pump(
        tester,
        checkbox(
          input: newsletter.copyWith(
            availability: IuxInputAvailability.readOnly,
          ),
          onChanged: (_) {},
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
          // The exclusion that sets the announced name also takes the
          // Focus widget's annotations, so the node has to publish the
          // focus itself or assistive technology cannot move
          // accessibility focus here — IUX-A11Y-FOCUS-001.
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
    });
  });

  group('no state is carried by colour alone', () {
    testWidgets('a chosen checkbox shows a mark, not only a fill',
        (WidgetTester tester) async {
      await pump(
        tester,
        checkbox(value: IuxSelectionState.selected, onChanged: (_) {}),
      );
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('an unchosen checkbox shows no mark',
        (WidgetTester tester) async {
      await pump(tester, checkbox(onChanged: (_) {}));
      expect(find.byIcon(Icons.check), findsNothing);
      expect(find.byIcon(Icons.remove), findsNothing);
    });

    testWidgets('a partly chosen checkbox shows a different mark again',
        (WidgetTester tester) async {
      await pump(
        tester,
        checkbox(value: IuxSelectionState.partial, onChanged: (_) {}),
      );
      expect(find.byIcon(Icons.remove), findsOneWidget);
      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('a switch that is on carries a mark as well as a position',
        (WidgetTester tester) async {
      await pump(
        tester,
        IuxSwitch(
          label: 'Use mobile data',
          input: const IuxInputDescriptor(
            semantics: IuxInputSemantics(label: 'Use mobile data'),
          ),
          value: IuxSelectionState.selected,
          onChanged: (_) {},
        ),
      );
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('a rejected value is explained in words',
        (WidgetTester tester) async {
      // An error carried by a red outline alone is invisible to a user who
      // cannot distinguish the hue, and cannot say what to do instead.
      await pump(
        tester,
        checkbox(
          input: newsletter.copyWith(
            validation:
                const IuxInputValidation.invalid('You must accept the terms'),
          ),
          onChanged: (_) {},
        ),
      );
      expect(find.text('You must accept the terms'), findsOneWidget);
    });
  });

  group('a radio group is a group', () {
    testWidgets('exactly one option is marked', (WidgetTester tester) async {
      await pump(tester, _speedGroup(value: 'express', onChanged: (_) {}));

      expect(
        tester.getSemantics(find.bySemanticsLabel('Express')),
        matchesSemantics(
          label: 'Express',
          isInMutuallyExclusiveGroup: true,
          hasCheckedState: true,
          isChecked: true,
          hasEnabledState: true,
          isEnabled: true,
          // The exclusion that sets the announced name also takes the
          // Focus widget's annotations, so the node has to publish the
          // focus itself or assistive technology cannot move
          // accessibility focus here — IUX-A11Y-FOCUS-001.
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Standard')),
        matchesSemantics(
          label: 'Standard',
          isInMutuallyExclusiveGroup: true,
          hasCheckedState: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          // The exclusion that sets the announced name also takes the
          // Focus widget's annotations, so the node has to publish the
          // focus itself or assistive technology cannot move
          // accessibility focus here — IUX-A11Y-FOCUS-001.
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
    });

    testWidgets('choosing another option reports that option',
        (WidgetTester tester) async {
      final List<String> chosen = <String>[];
      await pump(tester, _speedGroup(value: 'standard', onChanged: chosen.add));

      await tester.tap(find.text('Express'));
      await tester.pumpAndSettle();

      expect(chosen, <String>['express']);
    });

    testWidgets('activating the chosen option reports nothing',
        (WidgetTester tester) async {
      // A radio cannot be unchosen, so that gesture changes nothing; reporting
      // it would have parents re-running whatever a choice triggers.
      final List<String> chosen = <String>[];
      await pump(tester, _speedGroup(value: 'standard', onChanged: chosen.add));

      await tester.tap(find.text('Standard'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(chosen, isEmpty);
    });

    testWidgets('the group name is announced as a heading',
        (WidgetTester tester) async {
      await pump(tester, _speedGroup(onChanged: (_) {}));

      expect(
        tester.getSemantics(find.bySemanticsLabel('Delivery speed')),
        matchesSemantics(label: 'Delivery speed', isHeader: true),
      );
    });

    testWidgets('an unavailable option explains itself and stays visible',
        (WidgetTester tester) async {
      await pump(
        tester,
        IuxRadioGroup<String>(
          label: 'Delivery speed',
          input: const IuxInputDescriptor(
            semantics: IuxInputSemantics(label: 'How fast do you need it'),
          ),
          value: 'standard',
          options: const <IuxRadioOption<String>>[
            IuxRadioOption<String>(value: 'standard', label: 'Standard'),
            IuxRadioOption<String>(
              value: 'sameDay',
              label: 'Same day',
              unavailabilityReason: 'Not available at your address',
            ),
          ],
          onChanged: (_) {},
        ),
      );

      expect(find.text('Same day'), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Same day')),
        matchesSemantics(
          label: 'Same day',
          hint: 'Not available at your address',
          isInMutuallyExclusiveGroup: true,
          hasCheckedState: true,
          hasEnabledState: true,
        ),
      );
    });

    testWidgets('the caller\'s focus node is adopted by the first option',
        (WidgetTester tester) async {
      final FocusNode node = FocusNode(debugLabel: 'How fast do you need it');
      addTearDown(node.dispose);

      await pump(
        tester,
        IuxRadioGroup<String>(
          label: 'Delivery speed',
          input: const IuxInputDescriptor(
            semantics: IuxInputSemantics(label: 'How fast do you need it'),
          ),
          focusNode: node,
          value: null,
          options: const <IuxRadioOption<String>>[
            IuxRadioOption<String>(value: 'standard', label: 'Standard'),
            IuxRadioOption<String>(value: 'express', label: 'Express'),
          ],
          onChanged: (_) {},
        ),
      );

      // Attached to a widget, which is the whole of what "adopted" means: a
      // node with a null context is a node nothing answers to.
      expect(node.context, isNotNull);

      node.requestFocus();
      await tester.pumpAndSettle();

      expect(node.hasPrimaryFocus, isTrue);
      // And it is the first option that holds it, not the column.
      expect(
        find.descendant(
          of: find.ancestor(
            of: find.text('Standard'),
            matching: find.byType(IuxFocusable),
          ),
          matching: find.text('Standard'),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widgetList<IuxFocusable>(
              find.ancestor(
                of: find.text('Standard'),
                matching: find.byType(IuxFocusable),
              ),
            )
            .any((IuxFocusable f) => identical(f.focusNode, node)),
        isTrue,
      );
    });

    testWidgets('the node skips an option that cannot take focus',
        (WidgetTester tester) async {
      final FocusNode node = FocusNode(debugLabel: 'How fast do you need it');
      addTearDown(node.dispose);

      await pump(
        tester,
        IuxRadioGroup<String>(
          label: 'Delivery speed',
          input: const IuxInputDescriptor(
            semantics: IuxInputSemantics(label: 'How fast do you need it'),
          ),
          focusNode: node,
          value: null,
          options: const <IuxRadioOption<String>>[
            IuxRadioOption<String>(
              value: 'sameDay',
              label: 'Same day',
              unavailabilityReason: 'Not available at your address',
            ),
            IuxRadioOption<String>(value: 'standard', label: 'Standard'),
          ],
          onChanged: (_) {},
        ),
      );

      node.requestFocus();
      await tester.pumpAndSettle();

      // A node attached to a control that refuses focus is the original defect
      // with an extra step in it: attached, pointed at, and still going
      // nowhere.
      expect(node.hasPrimaryFocus, isTrue);
      expect(
        tester
            .widgetList<IuxFocusable>(
              find.ancestor(
                of: find.text('Standard'),
                matching: find.byType(IuxFocusable),
              ),
            )
            .any((IuxFocusable f) => identical(f.focusNode, node)),
        isTrue,
        reason: 'the node belongs to the first option that can hold it',
      );
    });

    testWidgets('a group given no node still focuses option by option',
        (WidgetTester tester) async {
      await pump(tester, _speedGroup(onChanged: (_) {}));

      // The parameter is optional, and a group without one is unchanged: every
      // option owns its own node, as before.
      expect(tester.takeException(), isNull);
      expect(find.byType(IuxFocusable), findsNWidgets(2));
    });

    testWidgets('a group-level error is stated once, not on every option',
        (WidgetTester tester) async {
      // An unanswered required group is not five wrong options.
      await pump(
        tester,
        IuxRadioGroup<String>(
          label: 'Delivery speed',
          input: const IuxInputDescriptor(
            semantics: IuxInputSemantics(label: 'How fast do you need it'),
            requirement: IuxInputRequirement.required,
            validation: IuxInputValidation.invalid('Choose a delivery speed'),
          ),
          value: null,
          options: const <IuxRadioOption<String>>[
            IuxRadioOption<String>(value: 'standard', label: 'Standard'),
            IuxRadioOption<String>(value: 'express', label: 'Express'),
          ],
          onChanged: (_) {},
        ),
      );

      expect(find.text('Choose a delivery speed'), findsOneWidget);
    });
  });

  group('contradictions fail rather than being quietly repaired', () {
    test('a switch has no third position', () {
      expect(
        () => IuxSwitch(
          label: 'Use mobile data',
          input: const IuxInputDescriptor(
            semantics: IuxInputSemantics(label: 'Use mobile data'),
          ),
          value: IuxSelectionState.partial,
          onChanged: (_) {},
        ),
        throwsAssertionError,
      );
    });

    test('a radio group of one is a checkbox that lost its off state', () {
      expect(
        () => IuxRadioGroup<String>(
          label: 'Delivery speed',
          input: const IuxInputDescriptor(
            semantics: IuxInputSemantics(label: 'Delivery speed'),
          ),
          value: null,
          options: const <IuxRadioOption<String>>[
            IuxRadioOption<String>(value: 'standard', label: 'Standard'),
          ],
          onChanged: (_) {},
        ),
        throwsAssertionError,
      );
    });

    test('two options may not share a value', () {
      expect(
        () => IuxRadioGroup<String>(
          label: 'Delivery speed',
          input: const IuxInputDescriptor(
            semantics: IuxInputSemantics(label: 'Delivery speed'),
          ),
          value: null,
          options: const <IuxRadioOption<String>>[
            IuxRadioOption<String>(value: 'standard', label: 'Standard'),
            IuxRadioOption<String>(value: 'standard', label: 'Economy'),
          ],
          onChanged: (_) {},
        ),
        throwsAssertionError,
      );
    });

    test('the chosen value has to be one of the options', () {
      expect(
        () => IuxRadioGroup<String>(
          label: 'Delivery speed',
          input: const IuxInputDescriptor(
            semantics: IuxInputSemantics(label: 'Delivery speed'),
          ),
          value: 'overnight',
          options: const <IuxRadioOption<String>>[
            IuxRadioOption<String>(value: 'standard', label: 'Standard'),
            IuxRadioOption<String>(value: 'express', label: 'Express'),
          ],
          onChanged: (_) {},
        ),
        throwsAssertionError,
      );
    });

    test('a group has to be named', () {
      expect(
        () =>
            IuxSelectionGroup(label: '', children: <Widget>[const SizedBox()]),
        throwsAssertionError,
      );
    });

    testWidgets('a disabled control may not also show an error',
        (WidgetTester tester) async {
      // The user would be told something is wrong and given no way to fix it.
      await pump(
        tester,
        checkbox(
          input: const IuxInputDescriptor(
            semantics: IuxInputSemantics(label: 'Send me the newsletter'),
            availability: IuxInputAvailability.disabled,
            validation: IuxInputValidation.invalid('Pick one'),
          ),
          onChanged: (_) {},
        ),
      );
      expect(tester.takeException(), isAssertionError);
    });
  });

  group('the model answers on its own', () {
    test('an activation asks for the opposite of chosen', () {
      expect(IuxSelectionState.selected.requestedSelection, isFalse);
      expect(IuxSelectionState.unselected.requestedSelection, isTrue);
    });

    test('an activation on a partial summary asks to select all', () {
      expect(IuxSelectionState.partial.requestedSelection, isTrue);
    });

    test('a partial summary does not read as chosen', () {
      expect(IuxSelectionState.partial.isSelected, isFalse);
      expect(IuxSelectionState.partial.isPartial, isTrue);
    });

    test('a boolean converts without a ternary at every call site', () {
      expect(IuxSelectionState.fromSelected(true), IuxSelectionState.selected);
      expect(
        IuxSelectionState.fromSelected(false),
        IuxSelectionState.unselected,
      );
    });

    test('an option is unavailable only together with its reason', () {
      const IuxRadioOption<int> available =
          IuxRadioOption<int>(value: 1, label: 'One');
      const IuxRadioOption<int> blocked = IuxRadioOption<int>(
        value: 2,
        label: 'Two',
        unavailabilityReason: 'Sold out',
      );
      expect(available.isAvailable, isTrue);
      expect(blocked.isAvailable, isFalse);
    });

    test('options with the same content are equal', () {
      expect(
        const IuxRadioOption<int>(value: 1, label: 'One'),
        const IuxRadioOption<int>(value: 1, label: 'One'),
      );
      expect(
        const IuxRadioOption<int>(value: 1, label: 'One'),
        isNot(const IuxRadioOption<int>(value: 1, label: 'Uno')),
      );
    });

    test('an unlabelled option is refused', () {
      expect(
        () => IuxRadioOption<int>(value: 1, label: ''),
        throwsAssertionError,
      );
    });
  });

  group('the appearance is resolved, never chosen by a call site', () {
    testWidgets('a chosen indicator outlines itself in its own fill',
        (WidgetTester tester) async {
      late IuxSelectionTokens tokens;
      await pump(
        tester,
        Builder(
          builder: (BuildContext context) {
            tokens = IuxSelectionResolver.resolve(context, newsletter);
            return const SizedBox();
          },
        ),
      );

      expect(tokens.outlineFor(selected: true), tokens.selectedFill);
      expect(tokens.outlineFor(selected: false), tokens.borderColor);
      expect(tokens.fillFor(selected: false), isNull);
    });

    testWidgets('an invalid indicator keeps its error outline even when chosen',
        (WidgetTester tester) async {
      late IuxSelectionTokens tokens;
      await pump(
        tester,
        Builder(
          builder: (BuildContext context) {
            tokens = IuxSelectionResolver.resolve(
              context,
              newsletter.copyWith(
                validation: const IuxInputValidation.invalid('Required'),
              ),
            );
            return const SizedBox();
          },
        ),
      );

      expect(tokens.outlineFor(selected: true), tokens.borderColor);
      expect(tokens.outlineFor(selected: true), isNot(tokens.selectedFill));
    });

    testWidgets('an enlarged text setting enlarges the indicator with it',
        (WidgetTester tester) async {
      // Someone who enlarged their text told you the default was not legible.
      late IuxSelectionTokens plain;
      late IuxSelectionTokens enlarged;

      await pump(
        tester,
        Builder(
          builder: (BuildContext context) {
            plain = IuxSelectionResolver.resolve(context, newsletter);
            return const SizedBox();
          },
        ),
      );
      await pump(
        tester,
        Builder(
          builder: (BuildContext context) {
            enlarged = IuxSelectionResolver.resolve(context, newsletter);
            return const SizedBox();
          },
        ),
        textScale: 2,
      );

      expect(enlarged.indicatorSize, greaterThan(plain.indicatorSize));
    });

    testWidgets('nothing is painted over the row until it is touched',
        (WidgetTester tester) async {
      late IuxSelectionTokens resting;
      await pump(
        tester,
        Builder(
          builder: (BuildContext context) {
            resting = IuxSelectionResolver.resolve(context, newsletter);
            return const SizedBox();
          },
        ),
      );
      expect(resting.rowHighlight, isNull);
    });
  });

  group('resilience', () {
    testWidgets('a long label wraps rather than being truncated',
        (WidgetTester tester) async {
      await pump(
        tester,
        checkbox(
          label: 'I agree to the processing of my personal data for the '
              'purposes described in the privacy notice',
          onChanged: (_) {},
        ),
        size: const Size(320, 640),
      );

      expect(tester.takeException(), isNull);
      final Text text = tester.widget<Text>(
        find.descendant(
            of: find.byType(IuxCheckbox), matching: find.byType(Text)),
      );
      expect(text.overflow, isNot(TextOverflow.ellipsis));
      expect(text.maxLines, isNull);
    });

    testWidgets('it survives a 200% text scale on a small screen',
        (WidgetTester tester) async {
      await pump(
        tester,
        IuxSelectionGroup(
          label: 'Notify me about',
          children: <Widget>[
            checkbox(label: 'Replies to my posts', onChanged: (_) {}),
            checkbox(label: 'Mentions of my name', onChanged: (_) {}),
          ],
        ),
        textScale: 2,
        size: const Size(320, 480),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Replies to my posts'), findsOneWidget);
    });

    testWidgets('a radio group survives a 200% text scale on a small screen',
        (WidgetTester tester) async {
      await pump(
        tester,
        _speedGroup(onChanged: (_) {}),
        textScale: 2,
        size: const Size(320, 480),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('it renders right-to-left', (WidgetTester tester) async {
      await pump(
        tester,
        IuxSwitch(
          label: 'استخدام بيانات الجوال',
          input: const IuxInputDescriptor(
            semantics: IuxInputSemantics(label: 'استخدام بيانات الجوال'),
          ),
          value: IuxSelectionState.selected,
          onChanged: (_) {},
        ),
        direction: TextDirection.rtl,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('استخدام بيانات الجوال'), findsOneWidget);
    });

    testWidgets('the switch thumb travels towards the end of the reading order',
        (WidgetTester tester) async {
      // A switch that reads backwards is a setting the user turns off
      // believing they turned it on.
      Future<double> thumbCentre(TextDirection direction) async {
        await pump(
          tester,
          IuxSwitch(
            label: 'On',
            input: const IuxInputDescriptor(
              semantics: IuxInputSemantics(label: 'On'),
            ),
            value: IuxSelectionState.selected,
            onChanged: (_) {},
          ),
          direction: direction,
        );
        // Measured against the track rather than the row: the row itself
        // mirrors, so comparing against it would pass whatever the thumb did.
        final Rect track = tester.getRect(
          find
              .ancestor(
                of: find.byIcon(Icons.check),
                matching: find.byType(AnimatedContainer),
              )
              .first,
        );
        return tester.getRect(find.byIcon(Icons.check)).center.dx -
            track.center.dx;
      }

      expect(await thumbCentre(TextDirection.ltr), greaterThan(0));
      expect(await thumbCentre(TextDirection.rtl), lessThan(0));
    });

    testWidgets('it renders on every theme profile',
        (WidgetTester tester) async {
      for (final IuxThemeConfiguration configuration in _profiles) {
        await pump(
          tester,
          IuxSelectionGroup(
            label: 'Notify me about',
            children: <Widget>[
              checkbox(
                label: 'Replies',
                value: IuxSelectionState.selected,
                onChanged: (_) {},
              ),
              _speedGroup(value: 'express', onChanged: (_) {}),
            ],
          ),
          configuration: configuration,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Replies'), findsOneWidget);
        expect(find.text('Express'), findsOneWidget);
      }
    });
  });

  group('motion', () {
    testWidgets('no motion still changes state, only instantly',
        (WidgetTester tester) async {
      await pump(
        tester,
        checkbox(value: IuxSelectionState.selected, onChanged: (_) {}),
        configuration: const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(motion: IuxMotionPreference.none),
        ),
      );

      expect(
        tester
            .widget<AnimatedContainer>(find.byType(AnimatedContainer).first)
            .duration,
        Duration.zero,
      );
      expect(
        find.byIcon(Icons.check),
        findsOneWidget,
        reason: 'removing the animation must never remove what it carried',
      );
    });

    testWidgets('reduced motion shortens rather than removes',
        (WidgetTester tester) async {
      Future<Duration> durationFor(IuxMotionPreference preference) async {
        await pump(
          tester,
          checkbox(onChanged: (_) {}),
          configuration: IuxThemeConfiguration(
            profile: IuxAccessibilityProfile(motion: preference),
          ),
        );
        return tester
            .widget<AnimatedContainer>(find.byType(AnimatedContainer).first)
            .duration;
      }

      final Duration full = await durationFor(IuxMotionPreference.standard);
      final Duration reduced = await durationFor(IuxMotionPreference.reduced);

      expect(reduced, lessThan(full));
      expect(reduced, greaterThan(Duration.zero));
    });
  });

  group('the widget carries no business meaning', () {
    testWidgets('it emits no feedback of its own', (WidgetTester tester) async {
      final List<MethodCall> platform = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform,
              (MethodCall call) async {
        platform.add(call);
        return null;
      });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );

      await pump(tester, checkbox(onChanged: (_) {}));
      await tester.tap(find.byType(IuxCheckbox));
      await tester.pumpAndSettle();

      expect(
        platform.where((MethodCall c) => c.method.startsWith('HapticFeedback')),
        isEmpty,
      );
    });
  });
}

/// A radio group used by several tests.
///
/// The visible name and the announced name differ on purpose, so a test can
/// tell the heading apart from the group container without either being
/// ambiguous.
IuxRadioGroup<String> _speedGroup({
  String? value,
  required ValueChanged<String> onChanged,
}) =>
    IuxRadioGroup<String>(
      label: 'Delivery speed',
      input: const IuxInputDescriptor(
        semantics: IuxInputSemantics(label: 'How fast do you need it'),
      ),
      value: value,
      options: const <IuxRadioOption<String>>[
        IuxRadioOption<String>(value: 'standard', label: 'Standard'),
        IuxRadioOption<String>(value: 'express', label: 'Express'),
      ],
      onChanged: onChanged,
    );
