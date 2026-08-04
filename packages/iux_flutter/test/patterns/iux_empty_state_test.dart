import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';
// Not yet in the barrel: the team lead owns that file. Imported from source so
// the pattern can be tested before the export lands.

/// What is missing. Names the thing, not the state — see [IuxEmptyState.title].
const String _kTitle = 'No invoices match these filters';

/// What would put something here.
const String _kGuidance = 'Try a wider date range, or include archived months.';

/// The announced name of the way out, fuller than the word on the control.
const IuxActionSemantics _kResetSemantics = IuxActionSemantics(
  label: 'Show all invoices',
);

/// A reset: enabled, idle, confirming nothing.
const IuxActionDescriptor _kReset = IuxActionDescriptor(
  semantics: _kResetSemantics,
);

/// The word on the control.
const String _kResetLabel = 'Show all';

/// A guidance long enough to prove the block wraps rather than clips.
const String _kLongGuidance =
    'Invoices are filed against the month they were issued in, so a range that '
    'starts after the issue date will not find them even when the payment '
    'landed later; widening the range to the whole of the last financial year, '
    'including the months that have already been archived and the ones still '
    'waiting to be approved, is usually enough to bring the missing ones back.';

/// Builds a way out, defaulting to a reset that does nothing observable.
IuxEmptyStateAction wayOut({
  String label = _kResetLabel,
  IuxActionDescriptor action = _kReset,
  String? busyHint,
  VoidCallback? onActivate,
}) =>
    IuxEmptyStateAction(
      label: label,
      action: action,
      busyHint: busyHint,
      onActivate: onActivate ?? () {},
    );

void main() {
  /// Puts one empty state on a page, under the conditions given.
  Future<void> pump(
    WidgetTester tester,
    Widget state, {
    double textScale = 1,
    TextDirection direction = TextDirection.ltr,
    Size size = const Size(400, 800),
    IuxThemeConfiguration configuration = const IuxThemeConfiguration(),
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
            child: Scaffold(body: Center(child: state)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('the way out refuses what it could not present', () {
    test('an unlabelled control is refused', () {
      // On a screen holding nothing else this is a rectangle in the middle of
      // an empty page.
      expect(() => wayOut(label: ''), throwsA(isA<AssertionError>()));
    });

    test('an action that asks to be confirmed is refused', () {
      // Nothing here would present the question, so the policy would be
      // dropped in silence and the action would run on the first tap.
      expect(
        () => wayOut(
          action: const IuxActionDescriptor(
            semantics: _kResetSemantics,
            confirmation: IuxConfirmBeforeExecution(),
          ),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('IuxActionRole.retry is refused', () {
      // A retry describes a failure that did not happen. The request came back;
      // what came back was empty.
      expect(
        () => wayOut(
          action: const IuxActionDescriptor(
            semantics: _kResetSemantics,
            role: IuxActionRole.retry,
          ),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('an unavailable control with no reason is refused', () {
      expect(
        () => wayOut(
          action: const IuxActionDescriptor(
            semantics: _kResetSemantics,
            availability: IuxActionAvailability.disabled,
          ),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('an unavailable control that says why is accepted', () {
      expect(
        () => wayOut(
          action: const IuxActionDescriptor(
            semantics: IuxActionSemantics(
              label: 'Show all invoices',
              unavailabilityReason: 'Reconnect to change the filters',
            ),
            availability: IuxActionAvailability.disabled,
          ),
        ),
        returnsNormally,
      );
    });

    test('an empty busy hint is refused rather than ignored', () {
      expect(() => wayOut(busyHint: ''), throwsA(isA<AssertionError>()));
    });

    test('two ways out with the same parts are the same value', () {
      void onActivate() {}
      final IuxEmptyStateAction a = wayOut(onActivate: onActivate);
      final IuxEmptyStateAction b = wayOut(onActivate: onActivate);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(wayOut(label: 'Clear', onActivate: onActivate))));
    });

    test('it names itself for a debugger', () {
      expect(wayOut().toString(), contains(_kResetLabel));
    });
  });

  group('the situation carries its own exit', () {
    test('a collection nobody has filled may offer none', () {
      const IuxNothingCreatedYet cause = IuxNothingCreatedYet();
      expect(cause.action, isNull);
      // The user came for something and did not get it, so something is still
      // owed — an action or the sentence that replaces one.
      expect(cause.requiresWayForward, isTrue);
    });

    test('criteria that exclude everything always offer a reset', () {
      final IuxNoMatches cause = IuxNoMatches(reset: wayOut());
      // Non-nullable on the subclass: a caller reading this situation never has
      // to check for an absence that cannot happen.
      expect(cause.action.label, _kResetLabel);
      expect(cause.requiresWayForward, isTrue);
    });

    test('missing access may be somebody else s to grant', () {
      const IuxAccessRestricted cause = IuxAccessRestricted();
      expect(cause.action, isNull);
      expect(cause.requiresWayForward, isTrue);
    });

    test('an emptiness the user achieved owes nothing', () {
      const IuxNothingLeftToDo cause = IuxNothingLeftToDo();
      // Structurally, not by omission: there is no parameter to pass.
      expect(cause.action, isNull);
      expect(cause.requiresWayForward, isFalse);
    });

    test('two situations of the same kind with the same exit are equal', () {
      void onActivate() {}
      expect(
        IuxNoMatches(reset: wayOut(onActivate: onActivate)),
        equals(IuxNoMatches(reset: wayOut(onActivate: onActivate))),
      );
      // Different kinds never compare equal, whatever they carry.
      expect(
        const IuxNothingCreatedYet(),
        isNot(equals(const IuxAccessRestricted())),
      );
    });

    test('each situation names itself for a debugger', () {
      // Which of the four is on screen is the first question a bug report about
      // an empty state has to answer.
      expect(
        const IuxNothingCreatedYet().toString(),
        contains('IuxNothingCreatedYet'),
      );
      expect(
        IuxNoMatches(reset: wayOut()).toString(),
        contains('IuxNoMatches'),
      );
      expect(
        const IuxAccessRestricted().toString(),
        contains('IuxAccessRestricted'),
      );
      expect(
        const IuxNothingLeftToDo().toString(),
        contains('IuxNothingLeftToDo'),
      );
    });
  });

  group('what it puts on screen', () {
    testWidgets('the title and the guidance are shown',
        (WidgetTester tester) async {
      await pump(
        tester,
        const IuxEmptyState(
          cause: IuxNothingCreatedYet(),
          title: _kTitle,
          guidance: _kGuidance,
        ),
      );

      expect(find.text(_kTitle), findsOneWidget);
      expect(find.text(_kGuidance), findsOneWidget);
    });

    testWidgets('the situation s exit is the control that appears',
        (WidgetTester tester) async {
      int activations = 0;
      await pump(
        tester,
        IuxEmptyState(
          cause: IuxNoMatches(reset: wayOut(onActivate: () => activations++)),
          title: _kTitle,
        ),
      );

      expect(find.text(_kResetLabel), findsOneWidget);
      await tester.tap(find.text(_kResetLabel));
      await tester.pump();

      expect(activations, 1);
    });

    testWidgets('a situation with no exit renders no control',
        (WidgetTester tester) async {
      await pump(
        tester,
        const IuxEmptyState(
          cause: IuxNothingLeftToDo(),
          title: 'Everything is reviewed',
        ),
      );

      expect(find.byType(IuxButton), findsNothing);
    });

    testWidgets('activating the exit does not remove the empty state',
        (WidgetTester tester) async {
      // Whether the collection is still empty afterwards is something only the
      // parent can know, and a pattern that hid itself would hide a state that
      // is still true.
      await pump(
        tester,
        IuxEmptyState(cause: IuxNoMatches(reset: wayOut()), title: _kTitle),
      );

      await tester.tap(find.text(_kResetLabel));
      await tester.pumpAndSettle();

      expect(find.text(_kTitle), findsOneWidget);
    });

    testWidgets('an unavailable exit is not activatable',
        (WidgetTester tester) async {
      int activations = 0;
      await pump(
        tester,
        IuxEmptyState(
          cause: IuxNoMatches(
            reset: wayOut(
              action: const IuxActionDescriptor(
                semantics: IuxActionSemantics(
                  label: 'Show all invoices',
                  unavailabilityReason: 'Reconnect to change the filters',
                ),
                availability: IuxActionAvailability.disabled,
              ),
              onActivate: () => activations++,
            ),
          ),
          title: _kTitle,
        ),
      );

      await tester.tap(find.text(_kResetLabel));
      await tester.pump();

      expect(activations, 0);
    });
  });

  group('the dead end', () {
    testWidgets('a situation owed a way forward may not offer nothing',
        (WidgetTester tester) async {
      await pump(
        tester,
        const IuxEmptyState(
          cause: IuxNothingCreatedYet(),
          title: 'You have not added a project yet',
        ),
      );

      expect(tester.takeException(), isA<AssertionError>());
    });

    testWidgets('guidance alone is a way forward', (WidgetTester tester) async {
      // Plenty of collections are filled by somebody else. The sentence is the
      // way out; it is simply made of words rather than of a button.
      await pump(
        tester,
        const IuxEmptyState(
          cause: IuxNothingCreatedYet(),
          title: 'No payslips yet',
          guidance: 'Your payslips appear here once payroll files them.',
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(IuxButton), findsNothing);
    });

    testWidgets('an action alone is a way forward',
        (WidgetTester tester) async {
      await pump(
        tester,
        IuxEmptyState(cause: IuxNoMatches(reset: wayOut()), title: _kTitle),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('the one situation owed nothing may offer nothing',
        (WidgetTester tester) async {
      await pump(
        tester,
        const IuxEmptyState(
          cause: IuxNothingLeftToDo(),
          title: 'Everything is reviewed',
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('accessibility', () {
    testWidgets('the explanation is one stop, not two fragments',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(
        tester,
        const IuxEmptyState(
          cause: IuxNothingLeftToDo(),
          title: _kTitle,
          guidance: _kGuidance,
        ),
      );

      final SemanticsNode node = tester.getSemantics(find.text(_kTitle));
      // Read through getSemanticsData: the node merges its descendants, so its
      // own label is empty and the merged one is what a screen reader receives.
      final SemanticsData data = node.getSemanticsData();
      // Both sentences on one node: the user hears the whole explanation as one
      // utterance rather than landing on each line.
      expect(data.label, contains(_kTitle));
      expect(data.label, contains(_kGuidance));
      // And the guidance is not a stop of its own.
      expect(tester.getSemantics(find.text(_kGuidance)), same(node));

      handle.dispose();
    });

    testWidgets('a state the user arrived at is announced',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(
        tester,
        const IuxEmptyState(
          cause: IuxNothingLeftToDo(),
          title: _kTitle,
          guidance: _kGuidance,
          arrival: IuxEmptyStateArrival.afterAChange,
        ),
      );

      // The rows went, the explanation appeared, and without this the
      // screen-reader user is told none of it.
      expect(
        tester.getSemantics(find.text(_kTitle)),
        isSemantics(isLiveRegion: true),
      );

      handle.dispose();
    });

    testWidgets('afterAChange is the default', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(
        tester,
        const IuxEmptyState(cause: IuxNothingLeftToDo(), title: _kTitle),
      );

      // The asymmetry decides the default: announced by mistake is noise,
      // silent by mistake is indistinguishable from an application that hung.
      expect(
        tester.getSemantics(find.text(_kTitle)),
        isSemantics(isLiveRegion: true),
      );

      handle.dispose();
    });

    testWidgets('a screen that opened empty is not announced',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(
        tester,
        const IuxEmptyState(
          cause: IuxNothingLeftToDo(),
          title: _kTitle,
          arrival: IuxEmptyStateArrival.withTheScreen,
        ),
      );

      // The empty state is simply the screen's content. Announcing it on top of
      // that says the same sentence twice.
      expect(
        tester.getSemantics(find.text(_kTitle)),
        isSemantics(isLiveRegion: false),
      );

      handle.dispose();
    });

    testWidgets('the exit stays a control of its own',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(
        tester,
        IuxEmptyState(
          cause: IuxNoMatches(reset: wayOut()),
          title: _kTitle,
          guidance: _kGuidance,
        ),
      );

      // Merged into the message it would be announced and unreachable.
      final SemanticsNode exit =
          tester.getSemantics(find.bySemanticsLabel(_kResetSemantics.label));
      expect(exit, isNot(same(tester.getSemantics(find.text(_kTitle)))));
      expect(
        exit,
        matchesSemantics(
          label: _kResetSemantics.label,
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          hasTapAction: true,
          isFocusable: true,
          hasFocusAction: true,
        ),
      );

      handle.dispose();
    });

    testWidgets('the announced name may be fuller than the visible one',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(
        tester,
        IuxEmptyState(cause: IuxNoMatches(reset: wayOut()), title: _kTitle),
      );

      // "Show all" on screen, "Show all invoices" in a screen reader.
      expect(find.text(_kResetLabel), findsOneWidget);
      expect(find.bySemanticsLabel(_kResetSemantics.label), findsOneWidget);

      handle.dispose();
    });

    testWidgets('an unavailable exit says why', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(
        tester,
        IuxEmptyState(
          cause: IuxNoMatches(
            reset: wayOut(
              action: const IuxActionDescriptor(
                semantics: IuxActionSemantics(
                  label: 'Show all invoices',
                  unavailabilityReason: 'Reconnect to change the filters',
                ),
                availability: IuxActionAvailability.disabled,
              ),
            ),
          ),
          title: _kTitle,
        ),
      );

      final SemanticsData data = tester
          .getSemantics(find.bySemanticsLabel(_kResetSemantics.label))
          .getSemanticsData();
      expect(data.hint, 'Reconnect to change the filters');
      // No tap action while unavailable: a screen reader must not offer an
      // activation that would do nothing.
      expect(data.hasAction(SemanticsAction.tap), isFalse);

      handle.dispose();
    });

    testWidgets('a running exit announces that it is running',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(
        tester,
        const IuxEmptyState(
          cause: IuxNothingCreatedYet(),
          title: 'No projects yet',
          guidance: 'Create one to get started.',
        ),
      );
      await pump(
        tester,
        IuxEmptyState(
          cause: IuxNothingCreatedYet(
            create: wayOut(
              label: 'Add a project',
              action: const IuxActionDescriptor.primary(
                semantics: IuxActionSemantics(label: 'Add your first project'),
                operation: IuxActionOperation.inProgress,
              ),
              busyHint: 'Creating your project',
            ),
          ),
          title: 'No projects yet',
        ),
      );

      // Silence is indistinguishable from a control that did nothing, and this
      // screen holds one control.
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Add your first project'))
            .getSemanticsData()
            .hint,
        contains('Creating your project'),
      );

      handle.dispose();
    });

    testWidgets('the illustration carries nothing',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(
        tester,
        const IuxEmptyState(
          cause: IuxNothingLeftToDo(),
          title: _kTitle,
          illustration: Icons.inbox_outlined,
        ),
      );

      // WCAG SC 1.1.1: decoration is hidden outright rather than described.
      expect(find.byType(Icon), findsOneWidget);

      // The glyph has no node of its own, so this resolves upward to the block
      // — which announces nothing and is not an image.
      final SemanticsNode glyph = tester.getSemantics(find.byType(Icon));
      expect(glyph.getSemanticsData().label, isEmpty);
      expect(glyph, isSemantics(isImage: false));

      // And the message is unchanged by its presence: nothing was appended, and
      // nothing depends on the picture having been seen.
      expect(
        tester.getSemantics(find.text(_kTitle)).getSemanticsData().label,
        equals(_kTitle),
      );

      handle.dispose();
    });

    testWidgets('nothing takes focus on arrival', (WidgetTester tester) async {
      // The opposite choice from IuxValidationSummary, and deliberately: a list
      // emptying under a filter happens while the user's hands are in the
      // search field.
      await pump(
        tester,
        IuxEmptyState(cause: IuxNoMatches(reset: wayOut()), title: _kTitle),
      );

      expect(
        FocusManager.instance.primaryFocus?.context?.widget,
        isNot(isA<IuxButton>()),
      );
    });
  });

  group('the way out stays reachable', () {
    /// The scales the audit measures, and the screen it measures them on.
    const List<double> scales = <double>[1, 1.5, 2, 3];
    const Size small = Size(320, 640);

    /// A block with everything a real one carries, so the control sits where a
    /// real one puts it: below a glyph, a title and a sentence.
    IuxEmptyState block(VoidCallback onActivate) => IuxEmptyState(
          cause: IuxNoMatches(reset: wayOut(onActivate: onActivate)),
          title: _kTitle,
          guidance: _kGuidance,
          illustration: Icons.filter_alt_outlined,
        );

    /// One drag from the middle of the viewport, which is what a user does and
    /// is never on top of the control being reached.
    ///
    /// Far enough to hit the end of any of these blocks; the physics clamp it.
    Future<void> dragToTheEnd(WidgetTester tester) async {
      await tester.dragFrom(const Offset(160, 320), const Offset(0, -3000));
      await tester.pumpAndSettle();
    }

    testWidgets(
        'the reset can be reached and pressed at 100, 150, 200 and 300 '
        'per cent', (WidgetTester tester) async {
      for (final double scale in scales) {
        int activations = 0;
        await pump(
          tester,
          block(() => activations++),
          textScale: scale,
          size: small,
        );

        // DebugOverflowIndicatorMixin reports an overflow once per render
        // object lifetime, so this assertion is only worth anything because
        // every case ends by tearing the tree down (IUX-QA-VACUOUS-003).
        expect(tester.takeException(), isNull, reason: 'at ${scale}x');

        // The block supplies the one scroll view, because on this screen
        // nothing else does. Without it the control below is not reachable at
        // all: measured at 200%, zero hit-testable controls and zero
        // activations.
        expect(find.byType(Scrollable), findsOneWidget, reason: 'at ${scale}x');

        final Finder reset = find.byType(IuxButton);
        await dragToTheEnd(tester);

        expect(reset.hitTestable(), findsOneWidget, reason: 'at ${scale}x');
        await tester.tap(reset);
        await tester.pump();
        expect(activations, 1, reason: 'at ${scale}x');

        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets(
        'a caller who already scrolls does not get a second scroll '
        'view', (WidgetTester tester) async {
      // Every vertical scroll view hands its children an unbounded height, so
      // the block sees one and adds nothing. This is IUX-028's rule, and it now
      // holds structurally rather than by convention.
      final Map<String, Widget Function(Widget)> hosts =
          <String, Widget Function(Widget)>{
        'an IuxPage': (Widget child) => IuxPage(child: child),
        'a single-child scroll view': (Widget child) =>
            SingleChildScrollView(child: child),
        'a list': (Widget child) => ListView(children: <Widget>[child]),
        'a sliver list': (Widget child) => CustomScrollView(
              slivers: <Widget>[SliverToBoxAdapter(child: child)],
            ),
      };

      for (final MapEntry<String, Widget Function(Widget)> host
          in hosts.entries) {
        await pump(
          tester,
          host.value(block(() {})),
          textScale: 2,
          size: small,
        );

        expect(tester.takeException(), isNull, reason: 'inside ${host.key}');
        expect(
          find.byType(Scrollable),
          findsOneWidget,
          reason: 'inside ${host.key} there must be one scroll view, the '
              "caller's — a second one is a nested scrollable, which is its "
              'own defect and the reason IUX-028 refused to impose one',
        );

        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('a block that fits is not moved and takes no gesture',
        (WidgetTester tester) async {
      // The fix has to be invisible where there was nothing wrong. A scroll
      // view whose content fits reports no scroll extent, so it accepts no
      // drag and the gesture goes to whatever is above it.
      await pump(tester, block(() {}), size: small);

      final ScrollableState scrollable =
          tester.state<ScrollableState>(find.byType(Scrollable));
      expect(scrollable.position.maxScrollExtent, 0);

      // And it still hugs its content rather than filling the box it was
      // given, so the parent's alignment is still the parent's: this block is
      // in a Center, and it is still centred.
      expect(
        tester.getRect(find.byType(IuxEmptyState)).center.dy,
        moreOrLessEquals(320, epsilon: 1),
      );
    });

    testWidgets('a block that does not fit reports something to scroll',
        (WidgetTester tester) async {
      await pump(tester, block(() {}), textScale: 2, size: small);

      expect(
        tester
            .state<ScrollableState>(find.byType(Scrollable))
            .position
            .maxScrollExtent,
        greaterThan(0),
      );
    });
  });

  group('layout under pressure', () {
    testWidgets('long text wraps rather than clipping at 200%',
        (WidgetTester tester) async {
      // Placed inside a scroll view, which is the case where the block adds
      // none of its own: a region embedded in a list that already scrolls must
      // not introduce a second one. See "the way out stays reachable" for the
      // standalone case, which the block now scrolls itself.
      await pump(
        tester,
        SingleChildScrollView(
          child: IuxEmptyState(
            cause: IuxNoMatches(reset: wayOut()),
            title: _kTitle,
            guidance: _kLongGuidance,
            illustration: Icons.filter_alt_outlined,
          ),
        ),
        textScale: 2,
        size: const Size(320, 640),
      );

      expect(tester.takeException(), isNull);
      // Whole, not truncated: an ellipsis would hide the content the user
      // enlarged their text in order to read.
      expect(find.text(_kLongGuidance), findsOneWidget);
      expect(
        tester.widget<Text>(find.text(_kLongGuidance)).overflow,
        isNot(TextOverflow.ellipsis),
      );
    });

    testWidgets('it builds right to left', (WidgetTester tester) async {
      await pump(
        tester,
        IuxEmptyState(
          cause: IuxNoMatches(reset: wayOut()),
          title: _kTitle,
          guidance: _kGuidance,
        ),
        direction: TextDirection.rtl,
      );

      expect(tester.takeException(), isNull);
      expect(find.text(_kTitle), findsOneWidget);
    });

    testWidgets('it builds under high contrast', (WidgetTester tester) async {
      await pump(
        tester,
        IuxEmptyState(
          cause: IuxNoMatches(reset: wayOut()),
          title: _kTitle,
          guidance: _kGuidance,
        ),
        configuration: const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(contrast: IuxContrast.high),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text(_kTitle), findsOneWidget);
    });
  });
}
