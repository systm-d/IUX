import 'dart:ui' show SemanticsInputType, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';
// Not yet in the barrel: the team lead exports it. Imported from source so the
// component can be tested before that lands.

import '../support/contrast.dart';

void main() {
  const IuxInputSemantics emailSemantics =
      IuxInputSemantics(label: 'Email address');
  const IuxInputDescriptor email =
      IuxInputDescriptor(semantics: emailSemantics);

  /// The four shipped role mappings, reached through the public theme engine.
  const List<(String, IuxThemeConfiguration)> profiles =
      <(String, IuxThemeConfiguration)>[
    ('light standard', IuxThemeConfiguration()),
    (
      'light high contrast',
      IuxThemeConfiguration(
        profile: IuxAccessibilityProfile(contrast: IuxContrast.high),
      )
    ),
    ('dark standard', IuxThemeConfiguration(brightness: Brightness.dark)),
    (
      'dark high contrast',
      IuxThemeConfiguration(
        brightness: Brightness.dark,
        profile: IuxAccessibilityProfile(contrast: IuxContrast.high),
      )
    ),
  ];

  /// Builds one field and returns the text reported through `onChanged`.
  Future<List<String>> pump(
    WidgetTester tester, {
    IuxInputDescriptor input = email,
    TextEditingController? controller,
    String? placeholder,
    IuxTextContent content = IuxTextContent.text,
    IuxInputVariant? variant,
    IuxThemeConfiguration configuration = const IuxThemeConfiguration(),
    TextDirection direction = TextDirection.ltr,
    double textScale = 1,
    Size size = const Size(400, 800),
    bool autofocus = false,
    FocusNode? focusNode,
    List<String>? changes,
    ValueChanged<String>? onSubmitted,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final List<String> reported = changes ?? <String>[];
    final TextEditingController effective =
        controller ?? TextEditingController();
    if (controller == null) addTearDown(effective.dispose);

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
              body: Center(
                child: IuxTextField(
                  input: input,
                  controller: effective,
                  onChanged: reported.add,
                  placeholder: placeholder,
                  content: content,
                  variant: variant,
                  autofocus: autofocus,
                  focusNode: focusNode,
                  onSubmitted: onSubmitted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return reported;
  }

  TextEditingController controllerFor(String text) {
    final TextEditingController controller = TextEditingController(text: text);
    addTearDown(controller.dispose);
    return controller;
  }

  Decoration decorationOf(WidgetTester tester) => tester
      .widget<AnimatedContainer>(find.byType(AnimatedContainer))
      .decoration!;

  group('editing', () {
    testWidgets('what the user types is reported to the parent',
        (WidgetTester tester) async {
      final List<String> changes = await pump(tester);

      await tester.enterText(find.byType(TextField), 'a@b.example');
      await tester.pumpAndSettle();

      expect(changes, <String>['a@b.example']);
    });

    testWidgets('the caret ends where the user stopped typing',
        (WidgetTester tester) async {
      final TextEditingController controller = controllerFor('');
      await pump(tester, controller: controller);

      await tester.enterText(find.byType(TextField), 'hello');
      await tester.pumpAndSettle();

      expect(controller.text, 'hello');
      expect(controller.selection.baseOffset, 5);
    });

    testWidgets('the value survives a rebuild with a new descriptor',
        (WidgetTester tester) async {
      // The classic defect of a field rebuilt from a plain string: the caret
      // is re-seated and the user correcting the middle of a word ends up
      // typing at the end of it.
      final TextEditingController controller = controllerFor('');
      await pump(tester, controller: controller);

      await tester.enterText(find.byType(TextField), 'abcdef');
      controller.selection = const TextSelection.collapsed(offset: 3);
      await tester.pumpAndSettle();

      await pump(
        tester,
        controller: controller,
        input: email.copyWith(
          validation: const IuxInputValidation.invalid('Needs a domain'),
        ),
      );

      expect(controller.text, 'abcdef');
      expect(controller.selection.baseOffset, 3);
    });
  });

  group('availability', () {
    testWidgets('a read-only field keeps its place in focus traversal',
        (WidgetTester tester) async {
      // Its value is still information. A value a keyboard or screen-reader
      // user cannot reach is a value they do not have.
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);

      await pump(
        tester,
        input: email.copyWith(availability: IuxInputAvailability.readOnly),
        controller: controllerFor('AB-1234'),
        focusNode: node,
      );

      node.requestFocus();
      await tester.pumpAndSettle();

      expect(node.hasFocus, isTrue);
    });

    testWidgets('a disabled field is skipped by focus traversal',
        (WidgetTester tester) async {
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);

      await pump(
        tester,
        input: email.copyWith(availability: IuxInputAvailability.disabled),
        focusNode: node,
      );

      node.requestFocus();
      await tester.pumpAndSettle();

      expect(node.hasFocus, isFalse);
    });

    // What actually separates read-only from disabled, measured rather than
    // listed.
    //
    // The component documentation used to name five signals as carrying
    // read-onlyness: no caret, no keyboard, a marker, no placeholder, and the
    // `readOnly` semantic flag. Four of those five separate a read-only field
    // from an *editable* one and say nothing at all about a disabled one,
    // which has no caret, opens no keyboard and shows no placeholder either.
    // The fifth does not separate them either: Flutter's own `TextField`
    // resolves `readOnly: widget.readOnly || !_isEnabled`
    // (`material/text_field.dart`), so the flag is published on a disabled
    // field too, whatever IUX asks for.
    //
    // These tests pin what is left — a shape the disabled field does not have,
    // an availability the tree does report, and the actions that go with it —
    // so that the page describing the difference cannot drift away from it
    // again.
    group('read-only is not disabled', () {
      IuxInputDescriptor availability(IuxInputAvailability value) =>
          email.copyWith(availability: value);

      testWidgets('only one of the two wears the marker',
          (WidgetTester tester) async {
        await pump(
          tester,
          input: availability(IuxInputAvailability.readOnly),
          controller: controllerFor('AB-1234'),
        );
        expect(find.byIcon(Icons.lock_outline), findsOneWidget);

        await pump(
          tester,
          input: availability(IuxInputAvailability.disabled),
          controller: controllerFor('AB-1234'),
        );
        expect(
          find.byIcon(Icons.lock_outline),
          findsNothing,
          reason: 'a disabled field wearing the read-only marker would make '
              'the one always-visible signal that separates them mean both',
        );
      });

      testWidgets('the marker is a meaningful graphic and is measured as one',
          (WidgetTester tester) async {
        // WCAG 2.2 SC 1.4.11. It is the only signal that is present before the
        // user has tried to type, so it is the one that has to be visible.
        for (final (String name, IuxThemeConfiguration configuration)
            in profiles) {
          await pump(
            tester,
            input: availability(IuxInputAvailability.readOnly),
            controller: controllerFor('AB-1234'),
            configuration: configuration,
            variant: IuxInputVariant.filled,
          );
          final Icon marker =
              tester.widget<Icon>(find.byIcon(Icons.lock_outline));
          final Color fill =
              IuxTheme.resolve(configuration).colors.surface.subtle;
          final double measured = ContrastMetric.ratio(marker.color!, fill);
          expect(
            measured,
            greaterThanOrEqualTo(ContrastMetric.nonText),
            reason: 'the read-only marker in $name measured '
                '${measured.toStringAsFixed(2)}:1 against the fill it sits on',
          );
        }
      });

      testWidgets(
          'the semantic tree separates them by availability, '
          'never by the read-only flag', (WidgetTester tester) async {
        // `SemanticsData` and not `SemanticsNode`: a node is a live object
        // that the next pump rewrites in place, so holding two of them and
        // comparing at the end compares one field with itself.
        Future<SemanticsData> announce(IuxInputAvailability value) async {
          await pump(
            tester,
            input: availability(value),
            controller: controllerFor('AB-1234'),
          );
          return tester
              .getSemantics(find.byType(EditableText))
              .getSemanticsData();
        }

        final SemanticsData readOnly =
            await announce(IuxInputAvailability.readOnly);
        final SemanticsData disabled =
            await announce(IuxInputAvailability.disabled);

        // What does separate them: one is live and answers a tap, the other
        // is neither.
        expect(readOnly.flagsCollection.isEnabled, Tristate.isTrue);
        expect(readOnly.hasAction(SemanticsAction.tap), isTrue);
        expect(disabled.flagsCollection.isEnabled, Tristate.isFalse);
        expect(disabled.hasAction(SemanticsAction.tap), isFalse);

        // What does not, and this is the part the documentation got wrong.
        // Both carry it, so a page claiming the flag is *the* read-only signal
        // is claiming something that is equally true of the disabled field.
        expect(readOnly.flagsCollection.isReadOnly, isTrue);
        expect(
          disabled.flagsCollection.isReadOnly,
          isTrue,
          reason: 'if Flutter ever stops resolving readOnly as '
              '`widget.readOnly || !_isEnabled`, the flag becomes a real '
              'discriminator and the note in docs/components/text-field.md '
              'should be struck',
        );
      });

      testWidgets('the value keeps full strength on one and dims on the other',
          (WidgetTester tester) async {
        // Dimming is a luminance change, so it survives greyscale where a hue
        // change would not.
        for (final (String name, IuxThemeConfiguration configuration)
            in profiles) {
          final IuxSemanticColors colors =
              IuxTheme.resolve(configuration).colors;
          expect(
            colors.content.primary,
            isNot(colors.content.disabled),
            reason: 'the read-only value and the disabled value are the same '
                'colour in $name',
          );
        }
      });
    });

    testWidgets('a read-only field shows no caret',
        (WidgetTester tester) async {
      await pump(
        tester,
        input: email.copyWith(availability: IuxInputAvailability.readOnly),
        controller: controllerFor('AB-1234'),
      );

      expect(
        tester.widget<EditableText>(find.byType(EditableText)).showCursor,
        isFalse,
      );
    });

    testWidgets('an editable field shows one', (WidgetTester tester) async {
      await pump(tester);

      expect(
        tester.widget<EditableText>(find.byType(EditableText)).showCursor,
        isTrue,
      );
    });

    testWidgets('tapping a read-only field opens no keyboard',
        (WidgetTester tester) async {
      await pump(
        tester,
        input: email.copyWith(availability: IuxInputAvailability.readOnly),
        controller: controllerFor('AB-1234'),
      );

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      expect(tester.testTextInput.hasAnyClients, isFalse);
    });

    testWidgets('tapping an editable field opens one',
        (WidgetTester tester) async {
      await pump(tester);

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      expect(tester.testTextInput.hasAnyClients, isTrue);
    });

    testWidgets('a read-only field wears a marker an editable one does not',
        (WidgetTester tester) async {
      // The marker is a shape, so it survives greyscale, a colour-vision
      // deficiency and a printed screenshot — and unlike the caret, the
      // keyboard and the placeholder it is there before the user has tried to
      // do anything. Since IUX-SURFACE-001 was closed the fill separates the
      // two as well, but the fill is a hue and this is not.
      await pump(
        tester,
        input: email.copyWith(availability: IuxInputAvailability.readOnly),
        controller: controllerFor('AB-1234'),
        variant: IuxInputVariant.filled,
      );
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);

      await pump(tester, variant: IuxInputVariant.filled);
      expect(find.byIcon(Icons.lock_outline), findsNothing);
    });

    testWidgets('a read-only field is still selectable and copyable',
        (WidgetTester tester) async {
      final TextEditingController controller = controllerFor('AB-1234');
      await pump(
        tester,
        input: email.copyWith(availability: IuxInputAvailability.readOnly),
        controller: controller,
      );

      final EditableText editable =
          tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.enableInteractiveSelection, isTrue);
    });

    testWidgets('a disabled field reports no change',
        (WidgetTester tester) async {
      final List<String> changes = await pump(
        tester,
        input: email.copyWith(availability: IuxInputAvailability.disabled),
      );

      expect(
        tester.widget<TextField>(find.byType(TextField)).enabled,
        isFalse,
      );
      expect(changes, isEmpty);
    });
  });

  group('the label is attached, not merely adjacent', () {
    testWidgets('the field is announced by name', (WidgetTester tester) async {
      // A placeholder is not a label: it disappears when typing starts, and a
      // user who has forgotten what the field was has no way back.
      await pump(tester, placeholder: 'name@example.com');

      expect(
        tester.getSemantics(find.byType(TextField)),
        isSemantics(
          label: 'Email address',
          isTextField: true,
          isEnabled: true,
        ),
      );
    });

    testWidgets('the name is also on screen', (WidgetTester tester) async {
      await pump(tester);
      expect(find.text('Email address'), findsOneWidget);
    });

    testWidgets('the placeholder never becomes the name',
        (WidgetTester tester) async {
      await pump(tester, placeholder: 'name@example.com');

      final SemanticsNode node = tester.getSemantics(find.byType(TextField));
      expect(node.label, 'Email address');
      expect(node.label, isNot(contains('name@example.com')));
    });

    testWidgets('a screen reader can still edit the value',
        (WidgetTester tester) async {
      // Attaching the label must not cost the text-editing actions. They are
      // offered by the platform only once the field holds focus, which is
      // also the only moment they mean anything.
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await pump(tester, controller: controllerFor('abc'), focusNode: node);

      node.requestFocus();
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.byType(TextField)),
        isSemantics(
          label: 'Email address',
          value: 'abc',
          isTextField: true,
          isFocused: true,
          hasSetTextAction: true,
          hasSetSelectionAction: true,
        ),
      );
    });

    testWidgets('a required field says so as a property, not as an asterisk',
        (WidgetTester tester) async {
      await pump(
        tester,
        input: email.copyWith(requirement: IuxInputRequirement.required),
      );

      expect(
        tester.getSemantics(find.byType(TextField)),
        isSemantics(isRequired: true),
      );
    });

    testWidgets('a read-only field announces that it is read-only',
        (WidgetTester tester) async {
      await pump(
        tester,
        input: email.copyWith(availability: IuxInputAvailability.readOnly),
        controller: controllerFor('AB-1234'),
      );

      expect(
        tester.getSemantics(find.byType(TextField)),
        isSemantics(isReadOnly: true, isEnabled: true),
      );
    });

    testWidgets('a disabled field explains itself',
        (WidgetTester tester) async {
      // A greyed field with no explanation leaves the user unable to tell
      // whether they did something wrong or the question does not apply.
      await pump(
        tester,
        input: const IuxInputDescriptor(
          semantics: IuxInputSemantics(
            label: 'Delivery date',
            unavailabilityReason: 'Choose a delivery method first',
          ),
          availability: IuxInputAvailability.disabled,
        ),
      );

      expect(
        tester.getSemantics(find.byType(TextField)).hint,
        contains('Choose a delivery method first'),
      );
    });

    testWidgets('the caller hint reaches the field node',
        (WidgetTester tester) async {
      await pump(
        tester,
        input: const IuxInputDescriptor(
          semantics: IuxInputSemantics(
            label: 'Reference',
            hint: 'Four letters then four digits',
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byType(TextField)).hint,
        contains('Four letters then four digits'),
      );
    });

    testWidgets('the content kind reaches assistive technology',
        (WidgetTester tester) async {
      await pump(tester, content: IuxTextContent.email);

      expect(
        tester.getSemantics(find.byType(TextField)).inputType,
        SemanticsInputType.email,
      );
    });
  });

  group('validation', () {
    const IuxInputDescriptor invalid = IuxInputDescriptor(
      semantics: emailSemantics,
      helpText: 'We only use it for your receipt',
      validation: IuxInputValidation.invalid('Add the part after the @'),
    );

    testWidgets('the error is announced, not only shown',
        (WidgetTester tester) async {
      // The field is on screen first and the parent rejects the value after,
      // which is the only order in which the message is a *status change*.
      // Pumping straight into the rejected state was the old shape of this
      // test, and it could not tell the two apart.
      await pump(tester, input: email);
      await pump(tester, input: invalid);

      expect(
        find.bySemanticsLabel('Add the part after the @'),
        findsOneWidget,
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Add the part after the @')),
        isSemantics(
          label: 'Add the part after the @',
          isLiveRegion: true,
        ),
      );
    });

    testWidgets('a message the field arrived carrying is read, not announced',
        (WidgetTester tester) async {
      // A live region is for a status *change* (SC 4.1.3). A message that was
      // already there when the field appeared is content: the user did not do
      // anything, and speaking it competes with whatever put the field on
      // screen — a step change, a revealed section, a page. That collision is
      // IUX-GUIDED-FORM-LIVE-001, measured as two utterances for one event.
      await pump(tester, input: invalid);

      final SemanticsNode node = tester
          .getSemantics(find.bySemanticsLabel('Add the part after the @'));

      expect(
        node,
        isSemantics(label: 'Add the part after the @', isLiveRegion: false),
        reason: 'a message present on arrival is not a status change',
      );
      // And it is still a node of its own, so nothing became unreachable: the
      // difference is whether it interrupts, not whether it can be read.
      expect(find.bySemanticsLabel('Add the part after the @'), findsOneWidget);
    });

    testWidgets('the same message coming back is announced again',
        (WidgetTester tester) async {
      // The user changed the value, the parent refused it for the same reason,
      // and that refusal is news even though the sentence is the one they saw
      // before.
      await pump(tester, input: invalid);
      await pump(tester, input: email);
      await pump(tester, input: invalid);

      expect(
        tester.getSemantics(find.bySemanticsLabel('Add the part after the @')),
        isSemantics(label: 'Add the part after the @', isLiveRegion: true),
      );
    });

    testWidgets('the field node carries the invalid result',
        (WidgetTester tester) async {
      await pump(tester, input: invalid);

      expect(
        tester.getSemantics(find.byType(TextField)).validationResult,
        SemanticsValidationResult.invalid,
      );
    });

    testWidgets('help text survives an error', (WidgetTester tester) async {
      // Replacing the instruction with the error removes the sentence saying
      // how to write a correct value at the exact moment the user needs it.
      await pump(tester, input: invalid);

      expect(find.text('We only use it for your receipt'), findsOneWidget);
      expect(find.text('Add the part after the @'), findsOneWidget);
    });

    testWidgets('the fill never turns red', (WidgetTester tester) async {
      await pump(tester);
      final BoxDecoration resting = decorationOf(tester) as BoxDecoration;

      await pump(tester, input: invalid);
      final BoxDecoration errored = decorationOf(tester) as BoxDecoration;

      expect(errored.color, resting.color,
          reason: 'a red container puts the error in the one channel a user '
              'with a colour-vision deficiency cannot read');
    });

    testWidgets('the outline thickens instead', (WidgetTester tester) async {
      await pump(tester);
      final BorderSide resting =
          (decorationOf(tester) as BoxDecoration).border!.top;

      await pump(tester, input: invalid);
      final BorderSide errored =
          (decorationOf(tester) as BoxDecoration).border!.top;

      expect(errored.width, greaterThan(resting.width));
      expect(errored.color, isNot(resting.color));
    });

    testWidgets('an error does not move the field it describes',
        (WidgetTester tester) async {
      // The thicker outline is paid for out of the padding, so the box keeps
      // its size and the caret does not jump when the error appears.
      await pump(tester);
      final Size resting = tester.getSize(find.byType(AnimatedContainer));

      await pump(tester, input: invalid);
      final Size errored = tester.getSize(find.byType(AnimatedContainer));

      expect(errored, resting);
    });

    testWidgets('a pending check is not an error', (WidgetTester tester) async {
      // Showing an error while the answer is unknown makes the user correct
      // something that was never wrong.
      await pump(
        tester,
        input: email.copyWith(
          validation: const IuxInputValidation.validating(
            message: 'Checking availability',
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byType(TextField)).validationResult,
        SemanticsValidationResult.none,
      );
      expect(find.text('Checking availability'), findsOneWidget);
    });

    testWidgets('an untouched field shows nothing at all',
        (WidgetTester tester) async {
      await pump(tester);

      expect(
        tester.getSemantics(find.byType(TextField)).validationResult,
        SemanticsValidationResult.none,
      );
      expect(find.byType(Text), findsOneWidget,
          reason: 'only the label; no reserved empty help or error line');
    });
  });

  group('touch target', () {
    testWidgets('the field itself meets the floor, at any density',
        (WidgetTester tester) async {
      for (final IuxDensity density in IuxDensity.values) {
        await pump(
          tester,
          configuration: IuxThemeConfiguration(
            profile: IuxAccessibilityProfile(density: density),
          ),
        );
        final Size size = tester.getSize(find.byType(AnimatedContainer));
        expect(
          size.height,
          greaterThanOrEqualTo(IuxTouchTarget.minimum),
          reason: '${density.name} produced ${size.height}',
        );
      }
    });

    testWidgets('a comfortable preference enlarges it',
        (WidgetTester tester) async {
      await pump(
        tester,
        configuration: const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(
            touchTarget: IuxTouchTargetPreference.comfortable,
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(AnimatedContainer)).height,
        greaterThanOrEqualTo(IuxTouchTarget.comfortable),
      );
    });
  });

  group('focus', () {
    testWidgets('gaining focus does not move anything',
        (WidgetTester tester) async {
      // A moving target is hard to follow, and for a screen-magnifier user it
      // can push the element off screen.
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);

      await pump(tester, focusNode: node);
      final Rect before = tester.getRect(find.byType(AnimatedContainer));

      node.requestFocus();
      await tester.pumpAndSettle();
      final Rect after = tester.getRect(find.byType(AnimatedContainer));

      expect(after, before);
    });

    testWidgets('a focus ring is available and reacts to focus',
        (WidgetTester tester) async {
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);

      await pump(tester, focusNode: node);
      expect(
        tester.widget<IuxFocusRing>(find.byType(IuxFocusRing)).focused,
        isFalse,
      );

      node.requestFocus();
      await tester.pumpAndSettle();
      expect(
        tester.widget<IuxFocusRing>(find.byType(IuxFocusRing)).focused,
        isTrue,
      );
    });

    testWidgets('an invalid field keeps its focus ring',
        (WidgetTester tester) async {
      // The field showing an error is exactly the field a keyboard user is
      // about to correct.
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);

      await pump(
        tester,
        input: email.copyWith(
          validation: const IuxInputValidation.invalid('Add the domain'),
        ),
        focusNode: node,
      );
      node.requestFocus();
      await tester.pumpAndSettle();

      expect(
        tester.widget<IuxFocusRing>(find.byType(IuxFocusRing)).focused,
        isTrue,
      );
    });

    testWidgets('tapping the padding around the text still focuses it',
        (WidgetTester tester) async {
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);

      await pump(tester, focusNode: node);
      final Rect box = tester.getRect(find.byType(AnimatedContainer));

      await tester.tapAt(Offset(box.right - 2, box.center.dy));
      await tester.pumpAndSettle();

      expect(node.hasFocus, isTrue);
    });
  });

  group('the placeholder is a prompt and nothing more', () {
    testWidgets('it is shown while the field is empty',
        (WidgetTester tester) async {
      await pump(tester, placeholder: 'name@example.com');
      expect(find.text('name@example.com'), findsOneWidget);
    });

    testWidgets('it disappears once there is a value',
        (WidgetTester tester) async {
      await pump(tester, placeholder: 'name@example.com');

      await tester.enterText(find.byType(TextField), 'a@b.example');
      await tester.pumpAndSettle();

      expect(find.text('name@example.com'), findsNothing);
    });

    testWidgets('a field nobody may fill is not prompted to be filled',
        (WidgetTester tester) async {
      await pump(
        tester,
        input: email.copyWith(availability: IuxInputAvailability.readOnly),
        placeholder: 'name@example.com',
      );

      expect(find.text('name@example.com'), findsNothing);
    });
  });

  group('the content kind decides five settings at once', () {
    testWidgets('email turns off capitalisation and autocorrect',
        (WidgetTester tester) async {
      // The field that capitalises the first letter of an address and then
      // rejects it is the reason this is one decision and not five.
      await pump(tester, content: IuxTextContent.email);

      final TextField field = tester.widget<TextField>(find.byType(TextField));
      expect(field.keyboardType, TextInputType.emailAddress);
      expect(field.textCapitalization, TextCapitalization.none);
      expect(field.autocorrect, isFalse);
      expect(field.autofillHints, contains(AutofillHints.email));
      expect(field.maxLines, 1);
    });

    testWidgets('multiline grows rather than scrolling sideways',
        (WidgetTester tester) async {
      await pump(tester, content: IuxTextContent.multiline);

      final TextField field = tester.widget<TextField>(find.byType(TextField));
      expect(field.maxLines, isNull);
      expect(field.minLines, greaterThan(1));
      expect(field.keyboardType, TextInputType.multiline);
    });

    testWidgets(
        'search is the only content that reaches assistive '
        'technology as a search', (WidgetTester tester) async {
      // IUX-038 (IUX-TEXTFIELD-GAPS-001). SemanticsInputType.search was
      // unreachable from any IUX field: the private resolution extension
      // mapped every other member of the enum and there was no member to map.
      // A screen reader could only say "text field" for a box the user had been
      // told was a search.
      final SemanticsHandle handle = tester.ensureSemantics();
      for (final IuxTextContent content in IuxTextContent.values) {
        await pump(tester, content: content);
        expect(
          tester.getSemantics(find.byType(TextField)).inputType,
          content == IuxTextContent.search
              ? SemanticsInputType.search
              : isNot(SemanticsInputType.search),
          reason: '$content resolved the wrong input type',
        );
      }
      handle.dispose();
    });

    testWidgets('search turns off autocorrect and offers nothing to autofill',
        (WidgetTester tester) async {
      await pump(tester, content: IuxTextContent.search);

      final TextField field = tester.widget<TextField>(find.byType(TextField));
      expect(field.autocorrect, isFalse);
      expect(field.textCapitalization, TextCapitalization.none);
      expect(field.autofillHints, isNull);
      expect(field.maxLines, 1);
    });
  });

  group('the keyboard action key follows the content', () {
    testWidgets('a search offers the search key, everything else offers done',
        (WidgetTester tester) async {
      // IUX-038 (IUX-TEXTFIELD-GAPS-001). There was no textInputAction and no
      // onSubmitted, so a search that runs when the user presses the
      // keyboard's action key could not be built on this widget at all.
      for (final IuxTextContent content in IuxTextContent.values) {
        await pump(tester, content: content);
        final TextField field =
            tester.widget<TextField>(find.byType(TextField));
        expect(
          field.textInputAction,
          switch (content) {
            IuxTextContent.search => TextInputAction.search,
            // The multiline action key is the newline key; taking it away is
            // what would make a multiline field unable to hold a paragraph.
            IuxTextContent.multiline => isNull,
            _ => TextInputAction.done,
          },
          reason: '$content offered the wrong action key',
        );
      }
    });

    testWidgets('the action key reports the text the user had typed',
        (WidgetTester tester) async {
      final List<String> submitted = <String>[];
      final TextEditingController controller = controllerFor('');
      await pump(
        tester,
        controller: controller,
        content: IuxTextContent.search,
        onSubmitted: submitted.add,
      );

      await tester.enterText(find.byType(TextField), 'invoices');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(submitted, <String>['invoices']);
    });

    test('a multiline field refuses to pretend it can be submitted', () {
      // PROJECT_PROMPT §22: prevent the incoherent state rather than document
      // it. onSubmitted on a multiline field would never fire, and the caller
      // would be left waiting for a callback the platform never sends.
      expect(
        () => IuxTextField(
          input: email,
          controller: TextEditingController(),
          onChanged: (String _) {},
          content: IuxTextContent.multiline,
          onSubmitted: (String _) {},
        ),
        throwsAssertionError,
      );
    });
  });

  group('resilience', () {
    testWidgets('a long label wraps rather than being truncated',
        (WidgetTester tester) async {
      await pump(
        tester,
        input: const IuxInputDescriptor(
          semantics: IuxInputSemantics(
            label: 'The email address we should use to send your receipt',
          ),
          helpText: 'We never share it, and you can change it at any time '
              'from your account settings',
        ),
        size: const Size(320, 640),
      );

      expect(tester.takeException(), isNull);
      for (final Text text in tester.widgetList<Text>(find.byType(Text))) {
        expect(text.maxLines, isNull);
        expect(text.overflow, isNot(TextOverflow.ellipsis));
      }
    });

    testWidgets('label, help and error all survive 200% on a 320x480 screen',
        (WidgetTester tester) async {
      await pump(
        tester,
        input: const IuxInputDescriptor(
          semantics: IuxInputSemantics(label: 'Email address'),
          helpText: 'Used for your receipt',
          validation: IuxInputValidation.invalid('Add the part after the @'),
        ),
        textScale: 2,
        size: const Size(320, 480),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Email address'), findsOneWidget);
      expect(find.text('Used for your receipt'), findsOneWidget);
      expect(find.text('Add the part after the @'), findsOneWidget);
      // Present is not enough; it has to be inside the viewport.
      for (final String line in <String>[
        'Email address',
        'Used for your receipt',
        'Add the part after the @',
      ]) {
        final Rect rect = tester.getRect(find.text(line));
        expect(rect.left, greaterThanOrEqualTo(0), reason: line);
        expect(rect.right, lessThanOrEqualTo(320), reason: line);
      }
    });

    testWidgets('the read-only marker grows with the text',
        (WidgetTester tester) async {
      await pump(
        tester,
        input: email.copyWith(availability: IuxInputAvailability.readOnly),
        controller: controllerFor('AB-1234'),
      );
      final double standard =
          tester.widget<Icon>(find.byIcon(Icons.lock_outline)).size!;

      await pump(
        tester,
        input: email.copyWith(availability: IuxInputAvailability.readOnly),
        controller: controllerFor('AB-1234'),
        textScale: 2,
        size: const Size(320, 480),
      );
      final double enlarged =
          tester.widget<Icon>(find.byIcon(Icons.lock_outline)).size!;

      expect(enlarged, greaterThan(standard));
    });

    testWidgets('it renders right-to-left and the caret follows the text',
        (WidgetTester tester) async {
      final TextEditingController controller = controllerFor('');
      await pump(
        tester,
        input: const IuxInputDescriptor(
          semantics: IuxInputSemantics(label: 'البريد الإلكتروني'),
        ),
        controller: controller,
        direction: TextDirection.rtl,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('البريد الإلكتروني'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'مرحبا');
      await tester.pumpAndSettle();

      expect(controller.text, 'مرحبا');
      expect(controller.selection.baseOffset, 5);
    });

    testWidgets('the read-only marker sits on the reading end',
        (WidgetTester tester) async {
      final IuxInputDescriptor readOnly =
          email.copyWith(availability: IuxInputAvailability.readOnly);

      await pump(
        tester,
        input: readOnly,
        controller: controllerFor('AB-1234'),
      );
      final Rect ltr = tester.getRect(find.byIcon(Icons.lock_outline));
      final Rect ltrBox = tester.getRect(find.byType(AnimatedContainer));
      expect(ltr.center.dx, greaterThan(ltrBox.center.dx));

      await pump(
        tester,
        input: readOnly,
        controller: controllerFor('AB-1234'),
        direction: TextDirection.rtl,
      );
      final Rect rtl = tester.getRect(find.byIcon(Icons.lock_outline));
      final Rect rtlBox = tester.getRect(find.byType(AnimatedContainer));
      expect(rtl.center.dx, lessThan(rtlBox.center.dx));
    });

    testWidgets('it renders on every theme profile, in both variants',
        (WidgetTester tester) async {
      for (final IuxThemeConfiguration configuration in <IuxThemeConfiguration>[
        const IuxThemeConfiguration(),
        const IuxThemeConfiguration(brightness: Brightness.dark),
        const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(contrast: IuxContrast.high),
        ),
        const IuxThemeConfiguration(
          brightness: Brightness.dark,
          profile: IuxAccessibilityProfile(contrast: IuxContrast.high),
        ),
      ]) {
        for (final IuxInputVariant variant in IuxInputVariant.values) {
          await pump(
            tester,
            input: const IuxInputDescriptor(
              semantics: IuxInputSemantics(label: 'Email address'),
              helpText: 'Used for your receipt',
            ),
            configuration: configuration,
            variant: variant,
          );
          expect(tester.takeException(), isNull);
          expect(find.text('Email address'), findsOneWidget);
        }
      }
    });
  });

  group('motion', () {
    testWidgets('no motion still changes state, only instantly',
        (WidgetTester tester) async {
      await pump(
        tester,
        configuration: const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(motion: IuxMotionPreference.none),
        ),
      );

      expect(
        tester
            .widget<AnimatedContainer>(find.byType(AnimatedContainer))
            .duration,
        Duration.zero,
      );
    });

    testWidgets('reduced motion shortens rather than removes',
        (WidgetTester tester) async {
      await pump(
        tester,
        configuration: const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(
            motion: IuxMotionPreference.standard,
          ),
        ),
      );
      final Duration full = tester
          .widget<AnimatedContainer>(find.byType(AnimatedContainer))
          .duration;

      await pump(
        tester,
        configuration: const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(motion: IuxMotionPreference.reduced),
        ),
      );
      final Duration reduced = tester
          .widget<AnimatedContainer>(find.byType(AnimatedContainer))
          .duration;

      expect(reduced, lessThan(full));
      expect(reduced, greaterThan(Duration.zero));
    });
  });

  group('the widget carries no business meaning', () {
    testWidgets('it never decides whether a value is acceptable',
        (WidgetTester tester) async {
      await pump(tester);

      await tester.enterText(find.byType(TextField), 'not-an-address');
      await tester.pumpAndSettle();

      final IuxTextField field =
          tester.widget<IuxTextField>(find.byType(IuxTextField));
      expect(
        field.input.validation.status,
        IuxInputValidationStatus.notValidated,
        reason: 'only the parent may change the validation state',
      );
      expect(
        tester.getSemantics(find.byType(TextField)).validationResult,
        SemanticsValidationResult.none,
      );
    });

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

      await pump(
        tester,
        input: email.copyWith(
          validation: const IuxInputValidation.invalid('Add the domain'),
        ),
      );
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      expect(
        platform.where((MethodCall c) => c.method.startsWith('HapticFeedback')),
        isEmpty,
      );
    });
  });
}
