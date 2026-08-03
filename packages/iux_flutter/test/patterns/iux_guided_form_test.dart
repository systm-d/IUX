// Tristate is declared in dart:ui and not re-exported by
// package:flutter/semantics.dart, so this is the only way to name it. It is
// what a semantics flag reads as now: set, cleared, or never mentioned.
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';
// Not yet in the barrel: the team lead exports it. Imported from source so the
// pattern can be tested before that lands.

/// Three steps, so "the step before this one" and "the step after this one"
/// are different steps, and a field can be two steps away rather than one.
/// The second field is a checkbox rather than a text box, because a guided
/// form combines fields and selection — and because a text box scrolls itself
/// into view when it takes focus, which would hide whether this pattern
/// brings a field on screen or merely focuses it.
const List<List<String>> _kSteps = <List<String>>[
  <String>['Email address', 'Contact me by email'],
  <String>['Street', 'Postcode'],
  <String>['Card number'],
];

/// The one field that is a selection control, as an index into the flat list.
const int _kCheckboxField = 1;

/// What each step is called.
const List<String> _kTitles = <String>[
  'Your details',
  'Delivery address',
  'Payment',
];

/// Every field label, flattened, in the order they are asked.
final List<String> _kLabels = <String>[
  for (final List<String> step in _kSteps) ...step,
];

void main() {
  group('one step at a time', () {
    testWidgets('only the step on screen is rendered',
        (WidgetTester tester) async {
      await pumpGuidedForm(tester);

      expect(find.text('Email address'), findsOneWidget);
      expect(find.text('Street'), findsNothing);
      expect(find.text('Card number'), findsNothing);
    });

    testWidgets('the first step offers no way back',
        (WidgetTester tester) async {
      await pumpGuidedForm(tester);

      expect(find.text('Back'), findsNothing);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('a middle step offers both ways', (WidgetTester tester) async {
      await pumpGuidedForm(tester, step: 1);

      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('the last step commits instead of continuing',
        (WidgetTester tester) async {
      await pumpGuidedForm(tester, step: 2);

      expect(find.text('Continue'), findsNothing);
      expect(find.text('Place the order'), findsOneWidget);
    });

    testWidgets('the heading says where the user is, in the caller\'s words',
        (WidgetTester tester) async {
      await pumpGuidedForm(tester, step: 1);

      // The count in the sentence is the number of steps that exist, because
      // the form supplied both numbers to the caller's function.
      expect(find.text('Step 2 of 3'), findsOneWidget);
      expect(find.text('Delivery address'), findsOneWidget);
    });
  });

  group('moving between steps', () {
    testWidgets('the forward control asks the parent for the next step',
        (WidgetTester tester) async {
      final _Host host = await pumpGuidedForm(tester);

      await tap(tester, 'Continue');

      expect(host.state.requestedSteps, <int>[1]);
      expect(host.state.step, 1);
    });

    testWidgets('the way back asks for the previous step',
        (WidgetTester tester) async {
      final _Host host = await pumpGuidedForm(tester, step: 2);

      await tap(tester, 'Back');

      expect(host.state.requestedSteps, <int>[1]);
      expect(host.state.step, 1);
    });

    testWidgets('a parent that declines leaves the form where it was',
        (WidgetTester tester) async {
      final _Host host = await pumpGuidedForm(tester, declineSteps: true);

      await tap(tester, 'Continue');

      // The request was made and refused. Nothing here moved on its own.
      expect(host.state.requestedSteps, <int>[1]);
      expect(find.text('Email address'), findsOneWidget);
      expect(find.text('Street'), findsNothing);
    });

    testWidgets('a rejected field does not block the way forward',
        (WidgetTester tester) async {
      final _Host host = await pumpGuidedForm(tester);
      host.state.reject(0, 'Enter an email address');
      await tester.pumpAndSettle();

      await tap(tester, 'Continue');

      // Filling a form out of order is ordinary. The guarantee is at the end,
      // not at every step boundary.
      expect(host.state.step, 1);
    });

    testWidgets('moving between steps asks for no checks',
        (WidgetTester tester) async {
      final _Host host = await pumpGuidedForm(tester);

      await tap(tester, 'Continue');
      await tap(tester, 'Back');

      // A rejection raised on leaving a step lands on a question the user can
      // no longer see.
      expect(host.requests, isEmpty);
    });
  });

  group('focus when the step changes', () {
    testWidgets('focus moves to the heading of the step that arrived',
        (WidgetTester tester) async {
      await pumpGuidedForm(tester);

      await tap(tester, 'Continue');

      expect(headingNode(tester).hasPrimaryFocus, isTrue);
    });

    testWidgets('focus does not stay on the control the user pressed',
        (WidgetTester tester) async {
      await pumpGuidedForm(tester);

      await tap(tester, 'Continue');

      // One frame later that control is a different control — and on the last
      // step it is the submit.
      final FocusNode? primary = FocusManager.instance.primaryFocus;
      expect(primary, isNotNull);
      expect(primary!.debugLabel, 'IuxGuidedForm step');
    });

    testWidgets('going back announces the step it went back to',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpGuidedForm(tester, step: 2);

      await tap(tester, 'Back');

      final SemanticsNode node = tester.getSemantics(
        find.bySemanticsLabel('Step 2 of 3. Delivery address'),
      );
      expect(node.flagsCollection.isFocused, Tristate.isTrue);
      handle.dispose();
    });

    testWidgets('a rebuild that is not a step change does not move focus',
        (WidgetTester tester) async {
      final _Host host = await pumpGuidedForm(tester);

      host.state.focusNodes[1].requestFocus();
      await tester.pumpAndSettle();

      host.state.reject(0, 'Enter an email address');
      await tester.pumpAndSettle();

      expect(host.state.focusNodes[1].hasPrimaryFocus, isTrue);
      expect(headingNode(tester).hasPrimaryFocus, isFalse);
    });
  });

  group('the heading announces the whole arrival', () {
    testWidgets('position, title and description are one node',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpGuidedForm(tester, step: 1, withDescription: true);

      final SemanticsNode node = tester.getSemantics(
        find.bySemanticsLabel(
          'Step 2 of 3. Delivery address. We only deliver within the city',
        ),
      );
      // One stop, not three: the position alone is the only fragment focus
      // would otherwise have landed on.
      expect(node.flagsCollection.isHeader, isTrue);
      handle.dispose();
    });

    testWidgets('the heading advertises a focus state and can take focus',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpGuidedForm(tester);

      final SemanticsNode node = tester.getSemantics(
        find.bySemanticsLabel('Step 1 of 3. Your details'),
      );
      // Not Tristate.none: the node says whether it is focused, which is what
      // separates somewhere the user can land from a line of text.
      expect(node.flagsCollection.isFocused, isNot(Tristate.none));

      headingNode(tester).requestFocus();
      await tester.pumpAndSettle();
      expect(headingNode(tester).hasPrimaryFocus, isTrue);
      handle.dispose();
    });
  });

  group('submitting the whole form', () {
    testWidgets('a form with nothing rejected submits',
        (WidgetTester tester) async {
      final _Host host = await pumpGuidedForm(tester, step: 2);

      await tap(tester, 'Place the order');

      expect(host.state.submissions, 1);
      expect(host.state.blocked, 0);
    });

    testWidgets('submitting asks every field of every step',
        (WidgetTester tester) async {
      final _Host host = await pumpGuidedForm(tester, step: 2);

      await tap(tester, 'Place the order');

      // Including the four fields that are not on screen: a question that was
      // never answered is exactly the one that has to be caught here.
      expect(host.requests, <String>[
        for (final String label in _kLabels) '$label:submit',
      ]);
    });

    testWidgets('a rejection two steps back refuses the submission',
        (WidgetTester tester) async {
      final _Host host = await pumpGuidedForm(tester, step: 2);
      host.state.reject(0, 'Enter an email address');
      await tester.pumpAndSettle();

      await tap(tester, 'Place the order');

      expect(host.state.submissions, 0);
      expect(host.state.blocked, 1);
      expect(find.byType(IuxValidationSummary), findsOneWidget);
    });

    testWidgets('the summary lists rejections from every step, in field order',
        (WidgetTester tester) async {
      final _Host host = await pumpGuidedForm(tester, step: 2);
      host.state
        ..reject(4, 'Enter a card number')
        ..reject(2, 'Enter a street')
        ..reject(0, 'Enter an email address');
      await tester.pumpAndSettle();

      await tap(tester, 'Place the order');

      expect(listedEntries(tester),
          <String>['Email address', 'Street', 'Card number']);
    });

    testWidgets('focus moves to the summary when the submission is refused',
        (WidgetTester tester) async {
      final _Host host = await pumpGuidedForm(tester, step: 2);
      host.state.reject(0, 'Enter an email address');
      await tester.pumpAndSettle();

      await tap(tester, 'Place the order');

      expect(summaryNode(tester).hasPrimaryFocus, isTrue);
    });

    testWidgets('a rejection arriving after the submission still refuses it',
        (WidgetTester tester) async {
      final _Host host = await pumpGuidedForm(tester, step: 2);

      await tap(tester, 'Place the order');
      expect(host.state.submissions, 1);

      host.state.reject(1, 'Choose whether we may email you');
      await tester.pumpAndSettle();

      expect(find.byType(IuxValidationSummary), findsOneWidget);
      expect(summaryNode(tester).hasPrimaryFocus, isTrue);
    });

    testWidgets('the summary goes when the last rejection is repaired',
        (WidgetTester tester) async {
      final _Host host = await pumpGuidedForm(tester, step: 2);
      host.state.reject(0, 'Enter an email address');
      await tester.pumpAndSettle();
      await tap(tester, 'Place the order');
      expect(find.byType(IuxValidationSummary), findsOneWidget);

      host.state.accept(0);
      await tester.pumpAndSettle();

      expect(find.byType(IuxValidationSummary), findsNothing);
    });
  });

  group('the summary reaches across steps', () {
    testWidgets('an entry for another step asks the parent for that step',
        (WidgetTester tester) async {
      final _Host host = await pumpGuidedForm(tester, step: 2);
      host.state.reject(0, 'Enter an email address');
      await tester.pumpAndSettle();
      await tap(tester, 'Place the order');

      await activateEntry(tester, 'Email address');

      expect(host.state.requestedSteps, <int>[0]);
      expect(host.state.step, 0);
    });

    testWidgets('the journey ends on the field, not on the heading',
        (WidgetTester tester) async {
      final _Host host = await pumpGuidedForm(tester, step: 2);
      host.state.reject(0, 'Enter an email address');
      await tester.pumpAndSettle();
      await tap(tester, 'Place the order');

      await activateEntry(tester, 'Email address');

      // The user asked to be taken to a box, not to be told about a step.
      expect(host.state.focusNodes[0].hasPrimaryFocus, isTrue);
      expect(headingNode(tester).hasPrimaryFocus, isFalse);
    });

    testWidgets('the field it lands on is on screen',
        (WidgetTester tester) async {
      final _Host host = await pumpGuidedForm(
        tester,
        step: 2,
        size: const Size(360, 200),
      );
      host.state.reject(1, 'Choose whether we may email you');
      await tester.pumpAndSettle();
      await tap(tester, 'Place the order');

      await activateEntry(tester, 'Contact me by email');

      // The whole box, not merely its top edge: a field whose label is on
      // screen and whose input is below the fold is a field the user has been
      // sent to and still cannot use. Measured at a viewport short enough that
      // arriving here without a scroll would leave it several hundred pixels
      // down.
      final Rect field = tester.getRect(find.byType(IuxCheckbox));
      final Rect window = tester.getRect(find.byType(SingleChildScrollView));
      expect(field.top, greaterThanOrEqualTo(window.top));
      expect(field.bottom, lessThanOrEqualTo(window.bottom));
    });

    testWidgets('an entry for the step on screen changes no step',
        (WidgetTester tester) async {
      final _Host host = await pumpGuidedForm(tester, step: 2);
      host.state.reject(4, 'Enter a card number');
      await tester.pumpAndSettle();
      await tap(tester, 'Place the order');

      await activateEntry(tester, 'Card number');

      expect(host.state.requestedSteps, isEmpty);
      expect(host.state.focusNodes[4].hasPrimaryFocus, isTrue);
    });

    testWidgets('a declined step change moves nothing',
        (WidgetTester tester) async {
      final _Host host = await pumpGuidedForm(
        tester,
        step: 2,
        declineSteps: true,
      );
      host.state.reject(0, 'Enter an email address');
      await tester.pumpAndSettle();
      await tap(tester, 'Place the order');

      await activateEntry(tester, 'Email address');

      expect(host.state.step, 2);
      expect(summaryNode(tester).hasPrimaryFocus, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a declined journey is not finished by a later step change',
        (WidgetTester tester) async {
      final _Host host = await pumpGuidedForm(tester, step: 2);
      host.state.reject(2, 'Enter a street');
      await tester.pumpAndSettle();
      await tap(tester, 'Place the order');

      // The parent refuses this one journey, then grants an ordinary step
      // change to the very step it refused.
      host.state.declineNextStep = true;
      await activateEntry(tester, 'Street');
      expect(host.state.step, 2);

      await tap(tester, 'Back');

      // The user pressed Back. They are told where they now are; they are not
      // dropped into a field because of a journey the parent refused a moment
      // ago.
      expect(host.state.step, 1);
      expect(headingNode(tester).hasPrimaryFocus, isTrue);
      expect(host.state.focusNodes[2].hasPrimaryFocus, isFalse);
    });

    testWidgets('a screen reader can activate an entry that crosses a step',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final _Host host = await pumpGuidedForm(tester, step: 2);
      host.state.reject(2, 'Enter a street');
      await tester.pumpAndSettle();
      await tap(tester, 'Place the order');

      final SemanticsNode entry = tester.getSemantics(
        find.bySemanticsLabel('Street. Enter a street'),
      );
      expect(entry.flagsCollection.isButton, isTrue);
      expect(entry.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

      // ignore: deprecated_member_use
      tester.binding.pipelineOwner.semanticsOwner!
          .performAction(entry.id, SemanticsAction.tap);
      await tester.pumpAndSettle();

      expect(host.state.step, 1);
      expect(host.state.focusNodes[2].hasPrimaryFocus, isTrue);
      handle.dispose();
    });
  });

  group('the whole journey', () {
    testWidgets(
        'a question answered wrongly two steps back is reachable, '
        'repairable and then accepted', (WidgetTester tester) async {
      final _Host host = await pumpGuidedForm(tester);

      // Step 1, answered wrongly, and the user walks on regardless.
      host.state.reject(0, 'Enter an email address');
      await tester.pumpAndSettle();
      await tap(tester, 'Continue');
      await tap(tester, 'Continue');
      expect(host.state.step, 2);
      expect(find.text('Enter an email address'), findsNothing);

      // The refusal is the first time the problem is visible again.
      await tap(tester, 'Place the order');
      expect(host.state.submissions, 0);
      expect(summaryNode(tester).hasPrimaryFocus, isTrue);

      // And it is a route, not only an accusation.
      await activateEntry(tester, 'Email address');
      expect(host.state.step, 0);
      expect(host.state.focusNodes[0].hasPrimaryFocus, isTrue);

      host.state.accept(0);
      await tester.pumpAndSettle();
      expect(find.byType(IuxValidationSummary), findsNothing);

      await tap(tester, 'Continue');
      await tap(tester, 'Continue');
      await tap(tester, 'Place the order');
      expect(host.state.submissions, 1);
    });
  });

  group('where the summary sits', () {
    testWidgets('it follows the user onto every step',
        (WidgetTester tester) async {
      final _Host host = await pumpGuidedForm(tester, step: 2);
      host.state
        ..reject(0, 'Enter an email address')
        ..reject(2, 'Enter a street');
      await tester.pumpAndSettle();
      await tap(tester, 'Place the order');

      await activateEntry(tester, 'Email address');

      // The list of what is left survives the user acting on one of it.
      expect(find.byType(IuxValidationSummary), findsOneWidget);
      expect(listedEntries(tester), <String>['Email address', 'Street']);
    });

    testWidgets('the stop after the heading is the summary',
        (WidgetTester tester) async {
      final _Host host = await pumpGuidedForm(tester, step: 2);
      host.state.reject(0, 'Enter an email address');
      await tester.pumpAndSettle();
      await tap(tester, 'Place the order');

      // Arrive at step 1 the way a user going back arrives: focus on the
      // heading.
      await activateEntry(tester, 'Email address');
      headingNode(tester).requestFocus();
      await tester.pumpAndSettle();

      expect(headingNode(tester).nextFocus(), isTrue);
      await tester.pumpAndSettle();

      // A user who navigates back to fix one problem must not have walked away
      // from the list of the others.
      expect(summaryNode(tester).hasPrimaryFocus, isTrue);
    });
  });

  group('validation timing', () {
    testWidgets('leaving an edited field on this step asks for a check',
        (WidgetTester tester) async {
      final _Host host = await pumpGuidedForm(tester);

      host.state.focusNodes[0].requestFocus();
      await tester.pumpAndSettle();
      host.state.focusNodes[1].requestFocus();
      await tester.pumpAndSettle();

      expect(host.requests, <String>['Email address:blur']);
    });

    testWidgets('leaving a field the user never edited asks for nothing',
        (WidgetTester tester) async {
      final _Host host = await pumpGuidedForm(tester, edited: false);

      host.state.focusNodes[0].requestFocus();
      await tester.pumpAndSettle();
      host.state.focusNodes[1].requestFocus();
      await tester.pumpAndSettle();

      expect(host.requests, isEmpty);
    });

    testWidgets('onSubmit timing asks for nothing on blur',
        (WidgetTester tester) async {
      final _Host host = await pumpGuidedForm(
        tester,
        timing: IuxValidationTiming.onSubmit,
      );

      host.state.focusNodes[0].requestFocus();
      await tester.pumpAndSettle();
      host.state.focusNodes[1].requestFocus();
      await tester.pumpAndSettle();

      expect(host.requests, isEmpty);
    });

    testWidgets(
        'a field the user was standing in when the step left asks '
        'nothing', (WidgetTester tester) async {
      final _Host host = await pumpGuidedForm(tester);

      host.state.focusNodes[0].requestFocus();
      await tester.pumpAndSettle();
      expect(host.state.focusNodes[0].hasFocus, isTrue);

      await tap(tester, 'Continue');

      // A pin rather than a guarantee. This holds because a FocusNode detached
      // from the tree does not notify its listeners, which was measured rather
      // than assumed: the same scenario with every step's nodes watched still
      // produces nothing. If Flutter ever changes that, this fails — and what
      // it would be reporting is an error raised against a question that has
      // just left the screen.
      expect(host.state.focusNodes[0].hasFocus, isFalse);
      expect(host.requests, isEmpty);
      expect(tester.takeException(), isNull);
    });
  });

  group('accessibility', () {
    testWidgets('long text at 200% neither clips nor overflows',
        (WidgetTester tester) async {
      final _Host host = await pumpGuidedForm(
        tester,
        step: 2,
        textScale: 2,
        size: const Size(320, 640),
        withDescription: true,
      );
      host.state.reject(
        0,
        'Enter the email address you use to sign in, including the part after '
        'the at sign, because we could not find an account for what you typed',
      );
      await tester.pumpAndSettle();
      await tap(tester, 'Place the order');

      expect(tester.takeException(), isNull);
      expect(find.byType(IuxValidationSummary), findsOneWidget);
    });

    testWidgets('the two controls stack rather than overflow at 200%',
        (WidgetTester tester) async {
      await pumpGuidedForm(
        tester,
        step: 1,
        textScale: 2,
        size: const Size(320, 900),
      );

      expect(tester.takeException(), isNull);
      final Rect back = tester.getRect(find.text('Back'));
      final Rect forward = tester.getRect(find.text('Continue'));
      // Either side by side or one under the other, but never off the edge.
      expect(back.right, lessThanOrEqualTo(320));
      expect(forward.right, lessThanOrEqualTo(320));
    });

    testWidgets('right to left lays out without complaint',
        (WidgetTester tester) async {
      final _Host host = await pumpGuidedForm(
        tester,
        step: 2,
        direction: TextDirection.rtl,
      );
      host.state.reject(0, 'Enter an email address');
      await tester.pumpAndSettle();
      await tap(tester, 'Place the order');

      expect(tester.takeException(), isNull);
      expect(find.byType(IuxValidationSummary), findsOneWidget);
    });

    testWidgets('nothing here animates a step change',
        (WidgetTester tester) async {
      await pumpGuidedForm(
        tester,
        configuration: const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(motion: IuxMotionPreference.none),
        ),
      );

      await tester.tap(find.text('Continue'));
      // One frame, no settle: the new step is already fully drawn, so a user
      // who asked for no motion is not shown a transition and a screen reader
      // is not made to wait for one.
      await tester.pump();

      expect(find.text('Street'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final IuxThemeConfiguration configuration in <IuxThemeConfiguration>[
      const IuxThemeConfiguration(),
      const IuxThemeConfiguration(brightness: Brightness.dark),
      const IuxThemeConfiguration(
        profile: IuxAccessibilityProfile(contrast: IuxContrast.high),
      ),
    ]) {
      testWidgets(
          'renders under ${configuration.brightness.name}/'
          '${configuration.contrast.name}', (WidgetTester tester) async {
        final _Host host = await pumpGuidedForm(
          tester,
          step: 2,
          configuration: configuration,
        );
        host.state.reject(0, 'Enter an email address');
        await tester.pumpAndSettle();
        await tap(tester, 'Place the order');

        expect(tester.takeException(), isNull);
        expect(find.byType(IuxValidationSummary), findsOneWidget);
      });
    }
  });

  group('configurations that cannot be right', () {
    IuxFormSubmit submit() => IuxFormSubmit(
          label: 'Place the order',
          action: const IuxActionDescriptor.primary(
            semantics: IuxActionSemantics(label: 'Place the order'),
          ),
          onSubmit: () {},
        );

    IuxValidationSummaryLabels labels() => IuxValidationSummaryLabels(
          categoryLabel: 'Error',
          describeCount: (int count) => '$count',
        );

    IuxGuidedFormStep step(String title) => IuxGuidedFormStep(
          title: title,
          sections: <IuxFormSection>[
            IuxFormSection(
              fields: <IuxFormField>[
                IuxFormField(
                  input: const IuxInputDescriptor(
                    semantics: IuxInputSemantics(label: 'Email address'),
                  ),
                  focusNode: FocusNode(),
                  child: const SizedBox.shrink(),
                ),
              ],
            ),
          ],
        );

    IuxGuidedForm build({
      List<IuxGuidedFormStep>? steps,
      int currentStep = 0,
      String backLabel = 'Back',
      String forwardLabel = 'Continue',
    }) =>
        IuxGuidedForm(
          steps: steps ??
              <IuxGuidedFormStep>[step('Your details'), step('Payment')],
          currentStep: currentStep,
          onStepChanged: (int _) {},
          describePosition: (int n, int total) => '$n/$total',
          backLabel: backLabel,
          forwardLabel: forwardLabel,
          summary: labels(),
          submit: submit(),
        );

    test('a guided form of one step is refused', () {
      expect(
        () => build(steps: <IuxGuidedFormStep>[step('Your details')]),
        throwsAssertionError,
      );
    });

    test('a step index outside the list is refused', () {
      expect(() => build(currentStep: 2), throwsAssertionError);
      expect(() => build(currentStep: -1), throwsAssertionError);
    });

    test('an unnamed way back is refused', () {
      expect(() => build(backLabel: ''), throwsAssertionError);
    });

    test('an unnamed way forward is refused', () {
      expect(() => build(forwardLabel: ''), throwsAssertionError);
    });

    test('a step with no name is refused', () {
      expect(
        () => IuxGuidedFormStep(
          title: '',
          sections: <IuxFormSection>[step('x').sections.first],
        ),
        throwsAssertionError,
      );
    });

    test('a step with no sections is refused', () {
      expect(
        () => IuxGuidedFormStep(
          title: 'Your details',
          sections: List<IuxFormSection>.empty(),
        ),
        throwsAssertionError,
      );
    });

    test('a step with an empty description is refused', () {
      expect(
        () => IuxGuidedFormStep(
          title: 'Your details',
          description: '',
          sections: <IuxFormSection>[step('x').sections.first],
        ),
        throwsAssertionError,
      );
    });
  });

  group('the step model', () {
    IuxFormField field(String label) {
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      return IuxFormField(
        input: IuxInputDescriptor(semantics: IuxInputSemantics(label: label)),
        focusNode: node,
        child: const SizedBox.shrink(),
      );
    }

    test('a step flattens its sections into the order they are asked', () {
      final IuxGuidedFormStep step = IuxGuidedFormStep(
        title: 'Your details',
        sections: <IuxFormSection>[
          IuxFormSection(fields: <IuxFormField>[field('A'), field('B')]),
          IuxFormSection(fields: <IuxFormField>[field('C')]),
        ],
      );

      expect(
        step.fields.map((IuxFormField f) => f.input.semantics.label).toList(),
        <String>['A', 'B', 'C'],
      );
    });

    test('steps compare by value', () {
      final IuxFormSection section =
          IuxFormSection(fields: <IuxFormField>[field('A')]);

      expect(
        IuxGuidedFormStep(
            title: 'Your details', sections: <IuxFormSection>[section]),
        IuxGuidedFormStep(
            title: 'Your details', sections: <IuxFormSection>[section]),
      );
      expect(
        IuxGuidedFormStep(
            title: 'Your details',
            sections: <IuxFormSection>[section]).hashCode,
        IuxGuidedFormStep(
            title: 'Your details',
            sections: <IuxFormSection>[section]).hashCode,
      );
      expect(
        IuxGuidedFormStep(
            title: 'Your details', sections: <IuxFormSection>[section]),
        isNot(
          IuxGuidedFormStep(
            title: 'Your details',
            description: 'Who you are',
            sections: <IuxFormSection>[section],
          ),
        ),
      );
    });

    test('a step names itself for a debugger', () {
      expect(
        IuxGuidedFormStep(
          title: 'Your details',
          sections: <IuxFormSection>[
            IuxFormSection(fields: <IuxFormField>[field('A'), field('B')]),
          ],
        ).toString(),
        'IuxGuidedFormStep(Your details, 2 fields)',
      );
    });
  });
}

/// Presses a control by its visible text, bringing it on screen first.
///
/// A tap that landed on nothing would look exactly like a control that
/// refused silently.
Future<void> tap(WidgetTester tester, String label) async {
  final Finder control = find.text(label);
  await tester.ensureVisible(control);
  await tester.pumpAndSettle();
  await tester.tap(control);
  await tester.pumpAndSettle();
}

/// Activates a summary entry by the name of the field it points at.
Future<void> activateEntry(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(
      of: find.byType(IuxValidationSummary),
      matching: find.text(label),
    ),
  );
  await tester.pumpAndSettle();
}

/// The node the form gave its summary, which is where focus goes on a refusal.
FocusNode summaryNode(WidgetTester tester) => tester
    .widget<IuxValidationSummary>(find.byType(IuxValidationSummary))
    .focusNode!;

/// The node the form gave its step heading, which is where focus goes when the
/// step changes.
FocusNode headingNode(WidgetTester tester) => tester
    .widgetList<Focus>(find.byType(Focus))
    .map((Focus focus) => focus.focusNode)
    .whereType<FocusNode>()
    .firstWhere((FocusNode node) => node.debugLabel == 'IuxGuidedForm step');

/// The field names the summary is currently listing, in order.
List<String> listedEntries(WidgetTester tester) => tester
    .widget<IuxValidationSummary>(find.byType(IuxValidationSummary))
    .entries
    .map((IuxValidationSummaryEntry entry) => entry.label)
    .toList();

/// What a test needs to reach back into the form it pumped.
class _Host {
  _Host({required this.state, required this.requests});

  final _GuidedHostState state;

  /// Every check the form asked for, as `label:trigger`.
  final List<String> requests;
}

/// Builds a three-step form and returns the handles a test needs.
Future<_Host> pumpGuidedForm(
  WidgetTester tester, {
  int step = 0,
  IuxValidationTiming timing = IuxValidationTiming.onBlur,
  bool edited = true,
  bool declineSteps = false,
  bool withDescription = false,
  IuxThemeConfiguration configuration = const IuxThemeConfiguration(),
  TextDirection direction = TextDirection.ltr,
  double textScale = 1,
  Size size = const Size(400, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final List<String> requests = <String>[];
  final GlobalKey<_GuidedHostState> key = GlobalKey<_GuidedHostState>();

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
            body: SingleChildScrollView(
              child: _GuidedHost(
                key: key,
                initialStep: step,
                timing: timing,
                edited: edited,
                declineSteps: declineSteps,
                withDescription: withDescription,
                requests: requests,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return _Host(state: key.currentState!, requests: requests);
}

/// A parent that owns the step, the values, the descriptors and the outcome —
/// everything the guided form refuses to own.
class _GuidedHost extends StatefulWidget {
  const _GuidedHost({
    super.key,
    required this.initialStep,
    required this.timing,
    required this.edited,
    required this.declineSteps,
    required this.withDescription,
    required this.requests,
  });

  final int initialStep;
  final IuxValidationTiming timing;
  final bool edited;
  final bool declineSteps;
  final bool withDescription;
  final List<String> requests;

  @override
  State<_GuidedHost> createState() => _GuidedHostState();
}

class _GuidedHostState extends State<_GuidedHost> {
  late int step = widget.initialStep;

  late final List<IuxInputDescriptor> inputs = <IuxInputDescriptor>[
    for (final String label in _kLabels)
      IuxInputDescriptor(semantics: IuxInputSemantics(label: label)),
  ];

  final List<FocusNode> focusNodes = <FocusNode>[
    for (final String label in _kLabels) FocusNode(debugLabel: label),
  ];

  final List<TextEditingController> controllers = <TextEditingController>[
    for (final String _ in _kLabels) TextEditingController(),
  ];

  /// Every step the form asked to go to, in order.
  final List<int> requestedSteps = <int>[];

  /// Refuses exactly one step change, the way an application that has to save
  /// a draft first might.
  bool declineNextStep = false;

  /// The one selection value the parent owns.
  IuxSelectionState checkbox = IuxSelectionState.unselected;

  int submissions = 0;
  int blocked = 0;

  /// The parent rejecting a value, which is the only place that ever happens.
  void reject(int index, String message) => setState(() {
        inputs[index] = inputs[index].copyWith(
          validation: IuxInputValidation.invalid(message),
        );
      });

  /// The parent accepting a value.
  void accept(int index) => setState(() {
        inputs[index] = inputs[index].copyWith(
          validation: const IuxInputValidation.valid(),
        );
      });

  /// The index of the first field of [stepIndex] within the flat list.
  int _offsetOf(int stepIndex) {
    int offset = 0;
    for (int i = 0; i < stepIndex; i++) {
      offset += _kSteps[i].length;
    }
    return offset;
  }

  @override
  void dispose() {
    for (final FocusNode node in focusNodes) {
      node.dispose();
    }
    for (final TextEditingController controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IuxGuidedForm(
      currentStep: step,
      timing: widget.timing,
      onStepChanged: (int next) {
        requestedSteps.add(next);
        if (widget.declineSteps || declineNextStep) {
          declineNextStep = false;
          return;
        }
        setState(() => step = next);
      },
      describePosition: (int n, int total) => 'Step $n of $total',
      backLabel: 'Back',
      forwardLabel: 'Continue',
      summary: IuxValidationSummaryLabels(
        categoryLabel: 'Error',
        navigationHint: 'Go to this field',
        describeCount: (int count) => count == 1
            ? '1 field needs your attention'
            : '$count fields need your attention',
      ),
      submit: IuxFormSubmit(
        label: 'Place the order',
        action: const IuxActionDescriptor.primary(
          semantics: IuxActionSemantics(label: 'Place the order'),
        ),
        onSubmit: () => submissions++,
        onBlocked: () => blocked++,
      ),
      steps: <IuxGuidedFormStep>[
        for (int s = 0; s < _kSteps.length; s++)
          IuxGuidedFormStep(
            title: _kTitles[s],
            description: widget.withDescription && s == 1
                ? 'We only deliver within the city'
                : null,
            sections: <IuxFormSection>[
              IuxFormSection(
                fields: <IuxFormField>[
                  for (int f = 0; f < _kSteps[s].length; f++)
                    _field(_offsetOf(s) + f),
                ],
              ),
            ],
          ),
      ],
    );
  }

  IuxFormField _field(int index) => IuxFormField(
        input: inputs[index],
        focusNode: focusNodes[index],
        edited: widget.edited,
        onValidationRequested: (IuxValidationTrigger trigger) =>
            widget.requests.add('${_kLabels[index]}:${trigger.name}'),
        child: index == _kCheckboxField
            ? IuxCheckbox(
                label: _kLabels[index],
                input: inputs[index],
                value: checkbox,
                focusNode: focusNodes[index],
                onChanged: (bool next) => setState(
                  () => checkbox = next
                      ? IuxSelectionState.selected
                      : IuxSelectionState.unselected,
                ),
              )
            : IuxTextField(
                input: inputs[index],
                controller: controllers[index],
                focusNode: focusNodes[index],
                onChanged: (String _) {},
              ),
      );
}
