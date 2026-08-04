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

/// Three questions, which is enough for "the second one is wrong" to be a
/// different sentence from "the first one is wrong".
const List<String> _kLabels = <String>[
  'Email address',
  'Postcode',
  'Contact me by email',
];

/// The one field that is not a text box.
///
/// IUX-QA-VACUOUS-002. Every field here used to be an [IuxTextField], and an
/// `EditableText` scrolls *itself* into view when it takes focus — so the test
/// below passed with `Scrollable.ensureVisible` deleted from `IuxForm`, and
/// would not have caught its removal. A checkbox does not self-scroll, so it
/// measures what the form does rather than what Flutter does for it.
const int _kCheckboxField = 2;

void main() {
  group('validation timing', () {
    testWidgets('leaving an edited field asks the parent to check it',
        (WidgetTester tester) async {
      final _Host host = await pumpForm(tester);

      host.state.focusNodes[0].requestFocus();
      await tester.pumpAndSettle();
      host.state.focusNodes[1].requestFocus();
      await tester.pumpAndSettle();

      expect(host.requests, <String>['Email address:blur']);
    });

    testWidgets('leaving a field the user never edited asks for nothing',
        (WidgetTester tester) async {
      final _Host host = await pumpForm(tester, edited: false);

      host.state.focusNodes[0].requestFocus();
      await tester.pumpAndSettle();
      host.state.focusNodes[1].requestFocus();
      await tester.pumpAndSettle();

      // The error that would otherwise appear here is about a value the user
      // was never given the chance to get wrong.
      expect(host.requests, isEmpty);
    });

    testWidgets('arriving in a field asks for nothing',
        (WidgetTester tester) async {
      final _Host host = await pumpForm(tester);

      host.state.focusNodes[0].requestFocus();
      await tester.pumpAndSettle();

      expect(host.requests, isEmpty);
    });

    testWidgets('onSubmit timing asks for nothing on blur',
        (WidgetTester tester) async {
      final _Host host = await pumpForm(
        tester,
        timing: IuxValidationTiming.onSubmit,
      );

      host.state.focusNodes[0].requestFocus();
      await tester.pumpAndSettle();
      host.state.focusNodes[1].requestFocus();
      await tester.pumpAndSettle();

      expect(host.requests, isEmpty);
    });

    testWidgets('submitting asks every field, edited or not',
        (WidgetTester tester) async {
      final _Host host = await pumpForm(tester, edited: false);

      await submit(tester);

      expect(host.requests, <String>[
        'Email address:submit',
        'Postcode:submit',
        'Contact me by email:submit',
      ]);
    });

    testWidgets('a field already known to be wrong is not asked again',
        (WidgetTester tester) async {
      final _Host host = await pumpForm(tester);
      host.state.reject(1, 'Enter a postcode');
      await tester.pumpAndSettle();

      await submit(tester);

      // Nothing was sent and nothing was re-checked: the answer is already on
      // screen, under the field.
      expect(host.requests, isEmpty);
      expect(host.submissions, 0);
    });
  });

  group('submission', () {
    testWidgets('a form with nothing rejected submits',
        (WidgetTester tester) async {
      final _Host host = await pumpForm(tester);

      await submit(tester);

      expect(host.submissions, 1);
      expect(host.blocked, 0);
    });

    testWidgets('a rejected field blocks the submission and says so',
        (WidgetTester tester) async {
      final _Host host = await pumpForm(tester);
      host.state.reject(0, 'Enter an email address');
      await tester.pumpAndSettle();

      await submit(tester);

      expect(host.submissions, 0);
      expect(host.blocked, 1);
      expect(find.byType(IuxValidationSummary), findsOneWidget);
    });

    testWidgets('the summary stays away until the user has tried to submit',
        (WidgetTester tester) async {
      final _Host host = await pumpForm(tester);
      host.state.reject(0, 'Enter an email address');
      await tester.pumpAndSettle();

      // The field already shows its own message, where the user is looking.
      expect(find.byType(IuxValidationSummary), findsNothing);

      await submit(tester);
      expect(find.byType(IuxValidationSummary), findsOneWidget);
    });

    testWidgets('the summary lists every rejected field, in field order',
        (WidgetTester tester) async {
      final _Host host = await pumpForm(tester);
      host.state
        ..reject(2, 'Choose whether we may email you')
        ..reject(0, 'Enter an email address');
      await tester.pumpAndSettle();

      await submit(tester);

      final List<String> listed = tester
          .widget<IuxValidationSummary>(find.byType(IuxValidationSummary))
          .entries
          .map((IuxValidationSummaryEntry e) => e.label)
          .toList();
      expect(listed, <String>['Email address', 'Contact me by email']);
    });

    testWidgets('the count in the sentence comes from the caller',
        (WidgetTester tester) async {
      final _Host host = await pumpForm(tester);
      host.state
        ..reject(0, 'Enter an email address')
        ..reject(1, 'Enter a postcode');
      await tester.pumpAndSettle();

      await submit(tester);

      // The framework composes nothing: it hands the count to the caller's own
      // sentence, so the number above the list is the length of the list.
      expect(find.text('2 fields need your attention'), findsOneWidget);
    });

    testWidgets('the summary goes when the last rejection is repaired',
        (WidgetTester tester) async {
      final _Host host = await pumpForm(tester);
      host.state.reject(0, 'Enter an email address');
      await tester.pumpAndSettle();
      await submit(tester);
      expect(find.byType(IuxValidationSummary), findsOneWidget);

      host.state.accept(0);
      await tester.pumpAndSettle();

      expect(find.byType(IuxValidationSummary), findsNothing);
    });

    testWidgets('a form with no summary configured still refuses',
        (WidgetTester tester) async {
      final _Host host = await pumpForm(tester, withSummary: false);
      host.state.reject(0, 'Enter an email address');
      await tester.pumpAndSettle();

      await submit(tester);

      expect(host.submissions, 0);
      expect(host.blocked, 1);
      expect(find.byType(IuxValidationSummary), findsNothing);
    });
  });

  group('focus after a refused submission', () {
    testWidgets('focus moves to the summary', (WidgetTester tester) async {
      final _Host host = await pumpForm(tester);
      host.state.reject(1, 'Enter a postcode');
      await tester.pumpAndSettle();

      await submit(tester);

      expect(summaryNode(tester).hasPrimaryFocus, isTrue);
    });

    testWidgets('focus falls back to the first rejected field with no summary',
        (WidgetTester tester) async {
      final _Host host = await pumpForm(tester, withSummary: false);
      host.state
        ..reject(1, 'Enter a postcode')
        ..reject(2, 'Choose whether we may email you');
      await tester.pumpAndSettle();

      await submit(tester);

      expect(host.state.focusNodes[1].hasPrimaryFocus, isTrue);
      expect(host.state.focusNodes[2].hasPrimaryFocus, isFalse);
    });

    testWidgets('a rejection that arrives after the submission still moves it',
        (WidgetTester tester) async {
      final _Host host = await pumpForm(tester);

      // Nothing is known to be wrong, so the submission goes out.
      await submit(tester);
      expect(host.submissions, 1);
      expect(find.byType(IuxValidationSummary), findsNothing);

      // The parent comes back with a rejection, as an asynchronous check does.
      host.state.reject(0, 'That address is already registered');
      await tester.pumpAndSettle();

      expect(find.byType(IuxValidationSummary), findsOneWidget);
      expect(summaryNode(tester).hasPrimaryFocus, isTrue);
    });

    testWidgets('a second refusal moves focus again',
        (WidgetTester tester) async {
      final _Host host = await pumpForm(tester);
      host.state.reject(0, 'Enter an email address');
      await tester.pumpAndSettle();

      await submit(tester);
      expect(summaryNode(tester).hasPrimaryFocus, isTrue);

      // The user goes back into a field and tries again without fixing it.
      host.state.focusNodes[2].requestFocus();
      await tester.pumpAndSettle();
      expect(summaryNode(tester).hasPrimaryFocus, isFalse);

      await submit(tester);
      expect(summaryNode(tester).hasPrimaryFocus, isTrue);
    });

    testWidgets('an ordinary rebuild does not steal focus',
        (WidgetTester tester) async {
      final _Host host = await pumpForm(tester);
      host.state.reject(0, 'Enter an email address');
      await tester.pumpAndSettle();
      await submit(tester);

      host.state.focusNodes[2].requestFocus();
      await tester.pumpAndSettle();

      // Another field is rejected while the user is elsewhere in the form. The
      // summary updates; focus stays where the user put it.
      host.state.reject(1, 'Enter a postcode');
      await tester.pumpAndSettle();

      expect(host.state.focusNodes[2].hasPrimaryFocus, isTrue);
      expect(summaryNode(tester).hasPrimaryFocus, isFalse);
    });

    // IUX-FORM-FOCUS-001, pinned as a defect by IUX-039 and fixed here. The
    // test above makes a general claim — "an ordinary rebuild does not steal
    // focus" — and demonstrated it only on the path where the submission was
    // *refused*. On the accepted path `_handleSubmit` used to increment
    // `_attempt`, find nothing invalid, and call `onSubmit`, so
    // `_moveFocusToFailure` never ran and `_focusedAttempt` was never brought
    // level. `_attempt != _focusedAttempt` was then permanently true, and the
    // next `didUpdateWidget` carrying any rejected field moved focus, however
    // long afterwards and whatever caused it.
    //
    // Measured here with an ordinary blur check: the user edits a field, tabs
    // onward, and the parent answers the *blur* — the request list proves that
    // is what it is answering — and the caret used to be taken out from under
    // them. WCAG 2.2 SC 3.2.2.
    //
    // What closes the window is the user arriving in a field; the three tests
    // below are the other side of that rule, and each of them fails under a
    // different wrong bound.
    testWidgets('a rejection long after an accepted submission moves nothing',
        (WidgetTester tester) async {
      final _Host host = await pumpForm(tester);

      // Nothing is wrong, so the submission goes out and is accepted.
      await submit(tester);
      expect(host.submissions, 1);
      expect(find.byType(IuxValidationSummary), findsNothing);
      host.requests.clear();

      // Later, the user edits the first field and tabs onward.
      host.state.focusNodes[0].requestFocus();
      await tester.pumpAndSettle();
      host.state.focusNodes[1].requestFocus();
      await tester.pumpAndSettle();
      expect(host.state.focusNodes[1].hasPrimaryFocus, isTrue);

      // The parent answers the blur check, not any submission.
      expect(host.requests, <String>['Email address:blur']);
      host.state.reject(0, 'That address is already registered');
      await tester.pumpAndSettle();

      // The summary appears, because something is wrong and the user has asked
      // to submit at least once. It does not take the caret.
      expect(find.byType(IuxValidationSummary), findsOneWidget);
      expect(host.state.focusNodes[1].hasPrimaryFocus, isTrue);
      expect(summaryNode(tester).hasPrimaryFocus, isFalse);
    });

    testWidgets('submitting from inside a field still lets the answer move it',
        (WidgetTester tester) async {
      final _Host host = await pumpForm(tester);

      // The user is standing in a box when they ask to submit — the ordinary
      // case for anyone whose last act before reaching for the control was to
      // type. The window closes on focus *arriving* in a field, so an arrival
      // that happened before the submission must not close the window that
      // submission opens.
      host.state.focusNodes[0].requestFocus();
      await tester.pumpAndSettle();
      await submit(tester);
      expect(host.submissions, 1);

      host.state.reject(0, 'That address is already registered');
      await tester.pumpAndSettle();

      expect(summaryNode(tester).hasPrimaryFocus, isTrue);
    });

    testWidgets('leaving a field does not close the window an arrival closes',
        (WidgetTester tester) async {
      final _Host host = await pumpForm(tester);

      host.state.focusNodes[0].requestFocus();
      await tester.pumpAndSettle();
      await submit(tester);
      expect(host.submissions, 1);
      host.requests.clear();

      // The user drops out of the field without entering another — tapping
      // dead space, dismissing the keyboard. Focus is now at the enclosing
      // scope, so there is no caret to take; and the blur check that goes out
      // here is the one whose answer arrives below.
      host.state.focusNodes[0].unfocus();
      await tester.pumpAndSettle();
      expect(host.requests, <String>['Email address:blur']);
      expect(host.state.focusNodes[0].hasPrimaryFocus, isFalse);

      host.state.reject(0, 'That address is already registered');
      await tester.pumpAndSettle();

      // Moving here costs the user nothing they were holding, and not moving
      // would leave a screen-reader user with a refusal nothing announced.
      expect(summaryNode(tester).hasPrimaryFocus, isTrue);
    });

    testWidgets('the window is not spent by rebuilds that carry no answer',
        (WidgetTester tester) async {
      final _Host host = await pumpForm(tester);

      await submit(tester);
      expect(host.submissions, 1);

      // The parent rebuilds several times while its check is still in flight —
      // a busy descriptor going up, a value arriving from somewhere else, any
      // of the things a parent rebuilds for. None of them is the answer, and
      // none of them may close the window: a window closed by the first
      // rebuild is a window that only ever catches a synchronous rejection.
      for (int i = 0; i < 3; i++) {
        host.state.accept(1);
        await tester.pumpAndSettle();
      }

      host.state.reject(0, 'That address is already registered');
      await tester.pumpAndSettle();

      expect(summaryNode(tester).hasPrimaryFocus, isTrue);
    });
  });

  group('the summary links to the fields', () {
    testWidgets('activating an entry focuses the field it names',
        (WidgetTester tester) async {
      final _Host host = await pumpForm(tester);
      host.state.reject(2, 'Choose whether we may email you');
      await tester.pumpAndSettle();
      await submit(tester);

      await tester.tap(
        find.descendant(
          of: find.byType(IuxValidationSummary),
          matching: find.text('Contact me by email'),
        ),
      );
      await tester.pumpAndSettle();

      expect(host.state.focusNodes[2].hasPrimaryFocus, isTrue);
    });

    testWidgets('an entry repeats the field message rather than only naming it',
        (WidgetTester tester) async {
      final _Host host = await pumpForm(tester);
      host.state.reject(0, 'Enter an email address');
      await tester.pumpAndSettle();
      await submit(tester);

      // Once under the field, once in the summary: the user reading the summary
      // is not looking at the field.
      expect(find.text('Enter an email address'), findsNWidgets(2));
    });

    testWidgets('an entry brings its field on screen',
        (WidgetTester tester) async {
      // Rewritten at IUX-038 (IUX-QA-VACUOUS-002). This test passed with
      // `Scrollable.ensureVisible` removed from `IuxForm._navigateTo`, because
      // the field it measured was an `IuxTextField` and an `EditableText`
      // brings *itself* into view when it takes focus. It proved Flutter's
      // behaviour, not the form's. The field is now a checkbox, which does not.
      //
      // The viewport is short enough that the summary and the field it names
      // cannot both be on screen, which is the situation the scroll exists for.
      final _Host host = await pumpForm(tester, size: const Size(360, 200));
      host.state.reject(2, 'Choose whether we may email you');
      await tester.pumpAndSettle();
      await submit(tester);

      final Finder entry = find.descendant(
        of: find.byType(IuxValidationSummary),
        matching: find.text('Contact me by email'),
      );
      // The user has to be able to reach the entry before activating it, and
      // `submit` left the window at the bottom of the form. Without this the
      // tap lands on nothing — and `tester.tap` only *warns* when it misses, so
      // the assertions below would then be measuring a form nobody touched.
      await tester.ensureVisible(entry);
      await tester.pumpAndSettle();

      final Rect window = tester.getRect(find.byType(SingleChildScrollView));
      expect(
        tester.getRect(find.byType(IuxCheckbox)).top,
        greaterThan(window.bottom),
        reason: 'the field has to start off screen for this to measure '
            'anything at all',
      );

      await tester.tap(entry);
      await tester.pumpAndSettle();

      expect(host.state.focusNodes[2].hasPrimaryFocus, isTrue,
          reason: 'the entry was activated, not merely tapped at');

      // The whole box, not merely its top edge: a field whose label is on
      // screen and whose control is below the fold is a field the user has
      // been sent to and still cannot use.
      final Rect field = tester.getRect(find.byType(IuxCheckbox));
      expect(field.top, greaterThanOrEqualTo(window.top));
      expect(field.bottom, lessThanOrEqualTo(window.bottom));
    });
  });

  group('accessibility', () {
    testWidgets('the focused summary node carries the category and the count',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final _Host host = await pumpForm(tester);
      host.state.reject(0, 'Enter an email address');
      await tester.pumpAndSettle();
      await submit(tester);

      final SemanticsNode node = tester.getSemantics(
        find.bySemanticsLabel('Error. 1 field needs your attention'),
      );
      // Both on one node: the announcement a screen-reader user hears when
      // focus lands here is the whole of what happened.
      expect(node.flagsCollection.isFocused, Tristate.isTrue);
      handle.dispose();
    });

    testWidgets('every entry is a named, activatable control',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final _Host host = await pumpForm(tester);
      host.state.reject(1, 'Enter a postcode');
      await tester.pumpAndSettle();
      await submit(tester);

      final SemanticsNode entry = tester.getSemantics(
        find.bySemanticsLabel('Postcode. Enter a postcode'),
      );
      expect(entry.flagsCollection.isButton, isTrue);
      expect(entry.getSemanticsData().hint, 'Go to this field');
      expect(entry.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      handle.dispose();
    });

    testWidgets('a screen reader can activate an entry',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final _Host host = await pumpForm(tester);
      host.state.reject(2, 'Choose whether we may email you');
      await tester.pumpAndSettle();
      await submit(tester);

      final SemanticsNode entry = tester.getSemantics(
        find.bySemanticsLabel(
          'Contact me by email. Choose whether we may email you',
        ),
      );
      // ignore: deprecated_member_use
      tester.binding.pipelineOwner.semanticsOwner!
          .performAction(entry.id, SemanticsAction.tap);
      await tester.pumpAndSettle();

      expect(host.state.focusNodes[2].hasPrimaryFocus, isTrue);
      handle.dispose();
    });

    testWidgets('an entry meets the touch target floor',
        (WidgetTester tester) async {
      final _Host host = await pumpForm(tester);
      host.state.reject(0, 'Enter an email address');
      await tester.pumpAndSettle();
      await submit(tester);

      final Size size = tester.getSize(
        find.descendant(
          of: find.byType(IuxValidationSummary),
          matching: find.byType(IuxTapTarget),
        ),
      );
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('the summary is reachable by keyboard traversal',
        (WidgetTester tester) async {
      final _Host host = await pumpForm(tester);
      host.state.reject(0, 'Enter an email address');
      await tester.pumpAndSettle();
      await submit(tester);

      // Focus arrived at the summary; the next stop is the entry, so a keyboard
      // user walks the list of problems rather than being parked on a heading.
      expect(summaryNode(tester).hasPrimaryFocus, isTrue);
      expect(summaryNode(tester).nextFocus(), isTrue);
      await tester.pumpAndSettle();
      expect(summaryNode(tester).hasPrimaryFocus, isFalse);
    });

    testWidgets('long text at 200% neither clips nor overflows',
        (WidgetTester tester) async {
      final _Host host = await pumpForm(
        tester,
        textScale: 2,
        size: const Size(320, 640),
      );
      host.state.reject(
        0,
        'Enter the email address you use to sign in, including the part after '
        'the at sign, because we could not find an account for what you typed',
      );
      await tester.pumpAndSettle();
      await submit(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(IuxValidationSummary), findsOneWidget);
    });

    testWidgets('right to left lays out without complaint',
        (WidgetTester tester) async {
      final _Host host = await pumpForm(
        tester,
        direction: TextDirection.rtl,
      );
      host.state.reject(0, 'Enter an email address');
      await tester.pumpAndSettle();
      await submit(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(IuxValidationSummary), findsOneWidget);
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
        final _Host host = await pumpForm(tester, configuration: configuration);
        host.state.reject(0, 'Enter an email address');
        await tester.pumpAndSettle();
        await submit(tester);

        expect(tester.takeException(), isNull);
        expect(find.byType(IuxValidationSummary), findsOneWidget);
      });
    }
  });

  group('the submit control', () {
    testWidgets('a disabled submit announces why it is unavailable',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpForm(
        tester,
        submitAction: const IuxActionDescriptor(
          semantics: IuxActionSemantics(
            label: 'Save',
            unavailabilityReason: 'Your session has expired',
          ),
          availability: IuxActionAvailability.disabled,
        ),
      );

      final SemanticsNode node =
          tester.getSemantics(find.bySemanticsLabel('Save'));
      expect(node.getSemanticsData().hint, 'Your session has expired');
      expect(node.flagsCollection.isEnabled, Tristate.isFalse);
      handle.dispose();
    });

    testWidgets('a disabled submit cannot be activated',
        (WidgetTester tester) async {
      final _Host host = await pumpForm(
        tester,
        submitAction: const IuxActionDescriptor(
          semantics: IuxActionSemantics(
            label: 'Save',
            unavailabilityReason: 'Your session has expired',
          ),
          availability: IuxActionAvailability.disabled,
        ),
      );

      await submit(tester);

      expect(host.submissions, 0);
      expect(host.requests, isEmpty);
    });

    testWidgets('a running submission is not sent twice',
        (WidgetTester tester) async {
      final _Host host = await pumpForm(
        tester,
        submitAction: const IuxActionDescriptor.primary(
          semantics: IuxActionSemantics(label: 'Save'),
          operation: IuxActionOperation.inProgress,
        ),
      );

      await submit(tester);

      expect(host.submissions, 0);
    });
  });

  group('configurations that cannot be right', () {
    test('a disabled submit with no explanation is refused', () {
      expect(
        () => IuxFormSubmit(
          label: 'Save',
          action: const IuxActionDescriptor(
            semantics: IuxActionSemantics(label: 'Save'),
            availability: IuxActionAvailability.disabled,
          ),
          onSubmit: () {},
        ),
        throwsAssertionError,
      );
    });

    test('a disabled submit with an explanation is allowed', () {
      expect(
        IuxFormSubmit(
          label: 'Save',
          action: const IuxActionDescriptor(
            semantics: IuxActionSemantics(
              label: 'Save',
              unavailabilityReason: 'Your session has expired',
            ),
            availability: IuxActionAvailability.disabled,
          ),
          onSubmit: () {},
        ).label,
        'Save',
      );
    });

    test('an empty submit label is refused', () {
      expect(
        () => IuxFormSubmit(
          label: '',
          action: const IuxActionDescriptor(
            semantics: IuxActionSemantics(label: 'Save'),
          ),
          onSubmit: () {},
        ),
        throwsAssertionError,
      );
    });

    test('a section with no fields is refused', () {
      expect(
        () => IuxFormSection(fields: const <IuxFormField>[]),
        throwsAssertionError,
      );
    });

    test('a section with an empty title is refused', () {
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      expect(
        () => IuxFormSection(
          title: '',
          fields: <IuxFormField>[
            IuxFormField(
              input: const IuxInputDescriptor(
                semantics: IuxInputSemantics(label: 'Email address'),
              ),
              focusNode: node,
              child: const SizedBox.shrink(),
            ),
          ],
        ),
        throwsAssertionError,
      );
    });

    test('a summary of nothing is refused', () {
      expect(
        () => IuxValidationSummary(
          categoryLabel: 'Error',
          message: 'There is a problem',
          entries: const <IuxValidationSummaryEntry>[],
        ),
        throwsAssertionError,
      );
    });

    test('an entry with no message is refused', () {
      expect(
        () => IuxValidationSummaryEntry(
          label: 'Email address',
          message: '',
          onActivate: () {},
        ),
        throwsAssertionError,
      );
    });

    test('an entry with no name is refused', () {
      expect(
        () => IuxValidationSummaryEntry(
          label: '',
          message: 'Enter an email address',
          onActivate: () {},
        ),
        throwsAssertionError,
      );
    });

    test('a summary with no opening sentence is refused', () {
      expect(
        () => IuxValidationSummary(
          categoryLabel: 'Error',
          message: '',
          entries: <IuxValidationSummaryEntry>[
            IuxValidationSummaryEntry(
              label: 'Email address',
              message: 'Enter an email address',
              onActivate: () {},
            ),
          ],
        ),
        throwsAssertionError,
      );
    });

    test('a form with no sections is refused', () {
      expect(
        () => IuxForm(
          sections: const <IuxFormSection>[],
          submit: IuxFormSubmit(
            label: 'Save',
            action: const IuxActionDescriptor(
              semantics: IuxActionSemantics(label: 'Save'),
            ),
            onSubmit: () {},
          ),
        ),
        throwsAssertionError,
      );
    });

    test('summary labels with no category word are refused', () {
      expect(
        () => IuxValidationSummaryLabels(
          categoryLabel: '',
          describeCount: (int n) => '$n',
        ),
        throwsAssertionError,
      );
    });
  });

  group('the model', () {
    test('a field reports whether the parent has rejected it', () {
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      const IuxInputDescriptor clean = IuxInputDescriptor(
        semantics: IuxInputSemantics(label: 'Email address'),
      );

      expect(
        IuxFormField(
          input: clean,
          focusNode: node,
          child: const SizedBox.shrink(),
        ).isInvalid,
        isFalse,
      );
      expect(
        IuxFormField(
          input: clean.copyWith(
            validation: const IuxInputValidation.invalid('Enter an address'),
          ),
          focusNode: node,
          child: const SizedBox.shrink(),
        ).isInvalid,
        isTrue,
      );
    });

    test('a validating field is not a rejected one', () {
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);

      // The lifecycle IUX-009 modelled: "being checked" is not "wrong".
      expect(
        IuxFormField(
          input: const IuxInputDescriptor(
            semantics: IuxInputSemantics(label: 'User name'),
            validation: IuxInputValidation.validating(),
          ),
          focusNode: node,
          child: const SizedBox.shrink(),
        ).isInvalid,
        isFalse,
      );
    });

    test('fields compare by value', () {
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      const Widget child = SizedBox.shrink();
      const IuxInputDescriptor input = IuxInputDescriptor(
        semantics: IuxInputSemantics(label: 'Email address'),
      );

      expect(
        IuxFormField(input: input, focusNode: node, child: child),
        IuxFormField(input: input, focusNode: node, child: child),
      );
      expect(
        IuxFormField(input: input, focusNode: node, child: child).hashCode,
        IuxFormField(input: input, focusNode: node, child: child).hashCode,
      );
      expect(
        IuxFormField(input: input, focusNode: node, child: child),
        isNot(
          IuxFormField(
            input: input,
            focusNode: node,
            child: child,
            edited: true,
          ),
        ),
      );
    });

    test('a field names itself for a debugger', () {
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      expect(
        IuxFormField(
          input: const IuxInputDescriptor(
            semantics: IuxInputSemantics(label: 'Email address'),
          ),
          focusNode: node,
          child: const SizedBox.shrink(),
        ).toString(),
        'IuxFormField(Email address, notValidated)',
      );
    });
  });
}

/// Presses the form's submit control.
Future<void> submit(WidgetTester tester) async {
  final Finder button = find.text('Save');
  // Brought on screen first: on a small window at a large text size the
  // control is below the fold, and a tap that lands on nothing would look
  // exactly like a form that refused silently.
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

/// The node the form gave its summary, which is where focus is sent on refusal.
FocusNode summaryNode(WidgetTester tester) => tester
    .widget<IuxValidationSummary>(find.byType(IuxValidationSummary))
    .focusNode!;

/// What a test needs to reach back into the form it pumped.
class _Host {
  _Host({
    required this.state,
    required this.requests,
  });

  final _FormHostState state;

  /// Every check the form asked for, as `label:trigger`.
  final List<String> requests;

  int get submissions => state.submissions;

  int get blocked => state.blocked;
}

/// Builds a three-field form and returns the handles a test needs.
Future<_Host> pumpForm(
  WidgetTester tester, {
  IuxValidationTiming timing = IuxValidationTiming.onBlur,
  bool withSummary = true,
  bool edited = true,
  IuxActionDescriptor? submitAction,
  IuxThemeConfiguration configuration = const IuxThemeConfiguration(),
  TextDirection direction = TextDirection.ltr,
  double textScale = 1,
  Size size = const Size(400, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final List<String> requests = <String>[];
  final GlobalKey<_FormHostState> key = GlobalKey<_FormHostState>();

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
              child: _FormHost(
                key: key,
                timing: timing,
                withSummary: withSummary,
                edited: edited,
                submitAction: submitAction,
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

/// A parent that owns the values, the descriptors and the outcome — everything
/// the form refuses to own.
class _FormHost extends StatefulWidget {
  const _FormHost({
    super.key,
    required this.timing,
    required this.withSummary,
    required this.edited,
    required this.requests,
    this.submitAction,
  });

  final IuxValidationTiming timing;
  final bool withSummary;
  final bool edited;
  final List<String> requests;
  final IuxActionDescriptor? submitAction;

  @override
  State<_FormHost> createState() => _FormHostState();
}

class _FormHostState extends State<_FormHost> {
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

  int submissions = 0;
  int blocked = 0;
  IuxSelectionState checkbox = IuxSelectionState.unselected;

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
    return IuxForm(
      timing: widget.timing,
      summary: widget.withSummary
          ? IuxValidationSummaryLabels(
              categoryLabel: 'Error',
              navigationHint: 'Go to this field',
              describeCount: (int count) => count == 1
                  ? '1 field needs your attention'
                  : '$count fields need your attention',
            )
          : null,
      submit: IuxFormSubmit(
        label: 'Save',
        action: widget.submitAction ??
            const IuxActionDescriptor.primary(
              semantics: IuxActionSemantics(label: 'Save'),
            ),
        onSubmit: () => submissions++,
        onBlocked: () => blocked++,
      ),
      sections: <IuxFormSection>[
        IuxFormSection(
          title: 'Your details',
          fields: <IuxFormField>[
            for (int i = 0; i < _kLabels.length; i++)
              IuxFormField(
                input: inputs[i],
                focusNode: focusNodes[i],
                edited: widget.edited,
                onValidationRequested: (IuxValidationTrigger trigger) =>
                    widget.requests.add('${_kLabels[i]}:${trigger.name}'),
                child: i == _kCheckboxField
                    ? IuxCheckbox(
                        label: _kLabels[i],
                        input: inputs[i],
                        value: checkbox,
                        focusNode: focusNodes[i],
                        onChanged: (bool next) => setState(
                          () => checkbox = next
                              ? IuxSelectionState.selected
                              : IuxSelectionState.unselected,
                        ),
                      )
                    : IuxTextField(
                        input: inputs[i],
                        controller: controllers[i],
                        focusNode: focusNodes[i],
                        onChanged: (String _) {},
                      ),
              ),
          ],
        ),
      ],
    );
  }
}
