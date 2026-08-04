import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';
// the pattern can be tested before the export lands.

/// The localised category word. The only carrier of "this is a failure" that
/// reaches a screen reader.
const String _kCategory = 'Error';

/// What failed. Names the user's thing, not the system's experience.
const String _kMessage = 'Your orders could not be loaded';

/// The word on the retry control.
const String _kRetryLabel = 'Try again';

/// What a screen reader announces instead, on a screen with two failed
/// sections.
const String _kRetrySemanticLabel = 'Try loading your orders again';

/// What a screen reader hears while the retry runs.
const String _kBusyHint = 'Reloading your orders';

/// The word on an alternative control.
const String _kAlternativeLabel = 'Sign in again';

/// The whole of what an unrecoverable failure gives the user.
const String _kGuidance = 'Nothing has been charged. Quote 4471-B if you call.';

/// A message long enough to prove the block wraps rather than clips.
const String _kLongMessage =
    'The payment was declined by your bank, which does not tell us why and '
    'usually means either that the card has expired since you last used it, '
    'that the amount is above a limit somebody set on the account, or that a '
    'fraud check somewhere between us and them decided this looked unusual '
    'enough to stop, and none of those is something we can see from here.';

void main() {
  /// Puts one failed region on a page, under the conditions given.
  Future<void> pump(
    WidgetTester tester,
    Widget block, {
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
            child: Scaffold(body: Center(child: block)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('a route refuses what it could not present', () {
    test('an unlabelled retry is refused', () {
      // A button the user is asked to trust without being told what it does.
      expect(
        () => IuxRetryRoute(label: '', onRetry: () {}),
        throwsA(isA<AssertionError>()),
      );
    });

    test('an empty semantic label is refused rather than ignored', () {
      // It would replace the visible name with nothing, leaving a control a
      // screen reader announces as "button".
      expect(
        () => IuxRetryRoute(
          label: _kRetryLabel,
          onRetry: () {},
          semanticLabel: '',
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('an empty busy hint is refused rather than ignored', () {
      expect(
        () => IuxRetryRoute(
          label: _kRetryLabel,
          onRetry: () {},
          busyHint: '',
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('an unrecoverable failure with nothing to say is refused', () {
      // Its words are the whole of what the user gets, so an empty guidance is
      // the apology this pattern exists to prevent.
      expect(
        () => IuxUnrecoverable(guidance: ''),
        throwsA(isA<AssertionError>()),
      );
    });

    test('two routes with the same parts are the same value', () {
      void retry() {}
      expect(
        IuxRetryRoute(label: _kRetryLabel, onRetry: retry),
        equals(IuxRetryRoute(label: _kRetryLabel, onRetry: retry)),
      );
      expect(
        IuxRetryRoute(label: _kRetryLabel, onRetry: retry).hashCode,
        equals(IuxRetryRoute(label: _kRetryLabel, onRetry: retry).hashCode),
      );
      expect(
        const IuxUnrecoverable(guidance: _kGuidance),
        equals(const IuxUnrecoverable(guidance: _kGuidance)),
      );
    });

    test('a running retry is not equal to an idle one', () {
      void retry() {}
      expect(
        IuxRetryRoute(label: _kRetryLabel, onRetry: retry, isRunning: true),
        isNot(equals(IuxRetryRoute(label: _kRetryLabel, onRetry: retry))),
      );
    });

    test('each route names itself for a debugger', () {
      expect(
        IuxRetryRoute(label: _kRetryLabel, onRetry: () {}).toString(),
        contains(_kRetryLabel),
      );
      expect(
        IuxRetryRoute(label: _kRetryLabel, onRetry: () {}, isRunning: true)
            .toString(),
        contains('running'),
      );
      expect(
        IuxAlternativeRoute(
          action: IuxNamedAction(
            label: _kAlternativeLabel,
            onActivate: () {},
          ),
        ).toString(),
        contains(_kAlternativeLabel),
      );
      expect(
        const IuxUnrecoverable(guidance: _kGuidance).toString(),
        contains(_kGuidance),
      );
    });
  });

  group('the route derives the action rather than accepting one', () {
    test('a retry is a retry, and refuses a repeat while it runs', () {
      // The claim the class documentation makes, asserted rather than trusted:
      // there is no second implementation of the repeat rule here, and a
      // caller has no parameter with which to turn it off.
      final IuxRetryRoute route = IuxRetryRoute(
        label: _kRetryLabel,
        onRetry: () {},
        isRunning: true,
      );

      expect(route.descriptor.role, IuxActionRole.retry);
      expect(
        route.descriptor.repeatPolicy,
        IuxActionRepeatPolicy.ignoreWhileInProgress,
      );
      expect(route.descriptor.operation, IuxActionOperation.inProgress);
      expect(route.descriptor.isActivatable, isFalse);
      expect(
        IuxActionPolicy.evaluate(route.descriptor, confirmed: true).isAccepted,
        isFalse,
      );
    });

    test('an idle retry accepts an activation', () {
      final IuxRetryRoute route =
          IuxRetryRoute(label: _kRetryLabel, onRetry: () {});

      expect(route.descriptor.operation, IuxActionOperation.idle);
      expect(route.descriptor.isActivatable, isTrue);
    });

    test('a retry presents no question, so none can be dropped in silence', () {
      final IuxRetryRoute route =
          IuxRetryRoute(label: _kRetryLabel, onRetry: () {});

      expect(route.descriptor.requiresConfirmation, isFalse);
    });

    test('the announced name falls back to the visible one', () {
      expect(
        IuxRetryRoute(label: _kRetryLabel, onRetry: () {})
            .descriptor
            .semantics
            .label,
        _kRetryLabel,
      );
      expect(
        IuxRetryRoute(
          label: _kRetryLabel,
          onRetry: () {},
          semanticLabel: _kRetrySemanticLabel,
        ).descriptor.semantics.label,
        _kRetrySemanticLabel,
      );
    });

    test('an alternative is a navigation and never a retry', () {
      // The one thing that keeps this control from being announced as, and
      // treated as, the retry the type deliberately is not.
      final IuxAlternativeRoute route = IuxAlternativeRoute(
        action: IuxNamedAction(
          label: _kAlternativeLabel,
          onActivate: () {},
        ),
      );

      expect(route.descriptor.role, IuxActionRole.navigate);
      expect(route.descriptor.role, isNot(IuxActionRole.retry));
      expect(route.descriptor.operation, IuxActionOperation.idle);
      expect(route.descriptor.isBusy, isFalse);
    });
  });

  group('what it puts on screen', () {
    testWidgets('the failure and its way out', (WidgetTester tester) async {
      await pump(
        tester,
        IuxErrorRecovery(
          categoryLabel: _kCategory,
          message: _kMessage,
          route: IuxRetryRoute(label: _kRetryLabel, onRetry: () {}),
        ),
      );

      expect(find.text(_kMessage), findsOneWidget);
      expect(find.text(_kRetryLabel), findsOneWidget);
    });

    testWidgets('the category word is never painted', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        IuxErrorRecovery(
          categoryLabel: _kCategory,
          message: _kMessage,
          route: IuxRetryRoute(label: _kRetryLabel, onRetry: () {}),
        ),
      );

      // It exists for the users who never see the glyph. On screen the glyph
      // and the wording already carry the category, and a block that also
      // printed the word "Error" would read as a label above a label.
      expect(find.text(_kCategory), findsNothing);
    });

    testWidgets('an unrecoverable failure shows its guidance and no control', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        const IuxErrorRecovery(
          categoryLabel: _kCategory,
          message: _kMessage,
          route: IuxUnrecoverable(guidance: _kGuidance),
        ),
      );

      expect(find.text(_kGuidance), findsOneWidget);
      expect(find.byType(IuxButton), findsNothing);
    });

    testWidgets('an alternative shows its own words, not a retry', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        IuxErrorRecovery(
          categoryLabel: _kCategory,
          message: _kMessage,
          route: IuxAlternativeRoute(
            action: IuxNamedAction(
              label: _kAlternativeLabel,
              onActivate: () {},
            ),
          ),
        ),
      );

      expect(find.text(_kAlternativeLabel), findsOneWidget);
      expect(find.text(_kRetryLabel), findsNothing);
    });

    testWidgets('a failure with no words is refused', (
      WidgetTester tester,
    ) async {
      expect(
        () => IuxErrorRecovery(
          categoryLabel: _kCategory,
          message: '',
          route: IuxRetryRoute(label: _kRetryLabel, onRetry: () {}),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    testWidgets('a failure with no category word is refused', (
      WidgetTester tester,
    ) async {
      // The glyph and the tint never reach a screen reader; this word is all
      // that does.
      expect(
        () => IuxErrorRecovery(
          categoryLabel: '',
          message: _kMessage,
          route: IuxRetryRoute(label: _kRetryLabel, onRetry: () {}),
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('the user asks for every attempt', () {
    testWidgets('nothing retries on its own', (WidgetTester tester) async {
      int attempts = 0;
      await pump(
        tester,
        IuxErrorRecovery(
          categoryLabel: _kCategory,
          message: _kMessage,
          route: IuxRetryRoute(
            label: _kRetryLabel,
            onRetry: () => attempts++,
          ),
        ),
      );

      // No timer, no backoff, no attempt budget. A block that retried by
      // itself would turn one bad connection into a burst of traffic against a
      // service that is already failing, and would re-send an operation the
      // user never asked it to re-send.
      await tester.pump(const Duration(seconds: 30));
      expect(attempts, 0);
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('a tap is one attempt', (WidgetTester tester) async {
      int attempts = 0;
      await pump(
        tester,
        IuxErrorRecovery(
          categoryLabel: _kCategory,
          message: _kMessage,
          route: IuxRetryRoute(
            label: _kRetryLabel,
            onRetry: () => attempts++,
          ),
        ),
      );

      await tester.tap(find.text(_kRetryLabel));
      await tester.pump();
      expect(attempts, 1);
    });

    testWidgets('a running retry refuses a second tap', (
      WidgetTester tester,
    ) async {
      int attempts = 0;
      await pump(
        tester,
        IuxErrorRecovery(
          categoryLabel: _kCategory,
          message: _kMessage,
          route: IuxRetryRoute(
            label: _kRetryLabel,
            onRetry: () => attempts++,
            isRunning: true,
            busyHint: _kBusyHint,
          ),
        ),
      );

      // The repeat policy, not a flag this pattern invented. It is what stops
      // an impatient double tap from sending a second request while the first
      // is still in flight.
      await tester.tap(find.text(_kRetryLabel), warnIfMissed: false);
      await tester.pump();
      expect(attempts, 0);
    });

    testWidgets('an alternative reports the activation and nothing else', (
      WidgetTester tester,
    ) async {
      int activations = 0;
      await pump(
        tester,
        IuxErrorRecovery(
          categoryLabel: _kCategory,
          message: _kMessage,
          route: IuxAlternativeRoute(
            action: IuxNamedAction(
              label: _kAlternativeLabel,
              onActivate: () => activations++,
            ),
          ),
        ),
      );

      await tester.tap(find.text(_kAlternativeLabel));
      await tester.pump();
      expect(activations, 1);

      // The block does not remove itself. The parent owns whether the failure
      // is still on screen, and a component that hid itself on activation
      // would hide a failure that is still happening.
      expect(find.text(_kMessage), findsOneWidget);
    });
  });

  group('accessibility', () {
    testWidgets('the explanation is one stop, not three fragments', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(
        tester,
        const IuxErrorRecovery(
          categoryLabel: _kCategory,
          message: _kMessage,
          route: IuxUnrecoverable(guidance: _kGuidance),
        ),
      );

      final SemanticsNode node = tester.getSemantics(find.text(_kMessage));
      final SemanticsData data = node.getSemanticsData();

      // The category first, because it is what tells the user this is a
      // breakdown; then what failed; then what they can do about it.
      expect(data.label, contains(_kCategory));
      expect(data.label, contains(_kMessage));
      expect(data.label, contains(_kGuidance));
      expect(
          data.label.indexOf(_kCategory),
          lessThan(data.label.indexOf(
            _kMessage,
          )));
      // And the guidance is not a stop of its own.
      expect(tester.getSemantics(find.text(_kGuidance)), same(node));

      handle.dispose();
    });

    testWidgets('the failure is announced where it appears', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(
        tester,
        IuxErrorRecovery(
          categoryLabel: _kCategory,
          message: _kMessage,
          route: IuxRetryRoute(label: _kRetryLabel, onRetry: () {}),
        ),
      );

      // The content went, the explanation appeared, and without this a
      // screen-reader user is told none of it.
      expect(
        tester.getSemantics(find.text(_kMessage)),
        isSemantics(isLiveRegion: true),
      );

      handle.dispose();
    });

    testWidgets('the block itself is not announced as a control', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(
        tester,
        const IuxErrorRecovery(
          categoryLabel: _kCategory,
          message: _kMessage,
          route: IuxUnrecoverable(guidance: _kGuidance),
        ),
      );

      // A message is not activatable. Announcing it as a button would promise
      // an action that does not exist.
      expect(
        tester.getSemantics(find.text(_kMessage)),
        isSemantics(isButton: false),
      );

      handle.dispose();
    });

    testWidgets('the control stays a stop of its own, and can be activated', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      int attempts = 0;
      await pump(
        tester,
        IuxErrorRecovery(
          categoryLabel: _kCategory,
          message: _kMessage,
          route: IuxRetryRoute(
            label: _kRetryLabel,
            onRetry: () => attempts++,
            semanticLabel: _kRetrySemanticLabel,
          ),
        ),
      );

      final SemanticsNode control =
          tester.getSemantics(find.text(_kRetryLabel));
      expect(
        control,
        isSemantics(
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          // The fuller name, so a screen holding two failed sections does not
          // hold two controls called "Try again".
          label: _kRetrySemanticLabel,
          hasTapAction: true,
        ),
      );

      // A screen-reader double tap is the platform's tap action, not a
      // pointer gesture; a node that announced a button and offered nothing to
      // activate would be visible, named and unusable.
      // ignore: deprecated_member_use
      tester.binding.pipelineOwner.semanticsOwner!.performAction(
        control.id,
        SemanticsAction.tap,
      );
      await tester.pump();
      expect(attempts, 1);

      handle.dispose();
    });

    testWidgets('a running retry says so instead of falling silent', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(
        tester,
        IuxErrorRecovery(
          categoryLabel: _kCategory,
          message: _kMessage,
          route: IuxRetryRoute(
            label: _kRetryLabel,
            onRetry: () {},
            isRunning: true,
            busyHint: _kBusyHint,
          ),
        ),
      );

      // Silence is indistinguishable from a control that did nothing, which is
      // the impression a block reporting a failure can least afford to give.
      final SemanticsData data =
          tester.getSemantics(find.text(_kRetryLabel)).getSemanticsData();
      expect(data.hint, contains(_kBusyHint));

      handle.dispose();
    });

    testWidgets('an unrecoverable failure offers nothing to activate', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(
        tester,
        const IuxErrorRecovery(
          categoryLabel: _kCategory,
          message: _kMessage,
          route: IuxUnrecoverable(guidance: _kGuidance),
        ),
      );

      // Declared deliberately, and therefore honestly: nothing anywhere in the
      // block is announced as a control or offers an activation, so there is
      // no button for the user to press and watch do nothing.
      final List<SemanticsNode> nodes = <SemanticsNode>[];
      void collect(SemanticsNode node) {
        nodes.add(node);
        node.visitChildren((SemanticsNode child) {
          collect(child);
          return true;
        });
      }

      collect(tester.getSemantics(find.byType(IuxErrorRecovery)));
      expect(nodes, isNotEmpty);
      for (final SemanticsNode node in nodes) {
        final SemanticsData data = node.getSemanticsData();
        expect(data.flagsCollection.isButton, isFalse);
        expect(data.hasAction(SemanticsAction.tap), isFalse);
      }

      handle.dispose();
    });

    testWidgets('the block does not take focus when it appears', (
      WidgetTester tester,
    ) async {
      final FocusNode elsewhere = FocusNode();
      addTearDown(elsewhere.dispose);

      final ValueNotifier<bool> failed = ValueNotifier<bool>(false);
      addTearDown(failed.dispose);

      await pump(
        tester,
        ValueListenableBuilder<bool>(
          valueListenable: failed,
          builder: (BuildContext context, bool hasFailed, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Focus(
                  focusNode: elsewhere,
                  child: const SizedBox.square(
                    dimension: 24,
                  )),
              if (hasFailed)
                IuxErrorRecovery(
                  categoryLabel: _kCategory,
                  message: _kMessage,
                  route: IuxRetryRoute(label: _kRetryLabel, onRetry: () {}),
                ),
            ],
          ),
        ),
      );

      elsewhere.requestFocus();
      await tester.pump();
      expect(FocusManager.instance.primaryFocus, same(elsewhere));

      // The failure arrives while the user's hands are somewhere else. Moving
      // focus would interrupt them; worse, moving it onto a retry would arm an
      // activation under the next Enter, in the one pattern whose control must
      // never fire twice.
      failed.value = true;
      await tester.pumpAndSettle();

      expect(find.text(_kRetryLabel), findsOneWidget);
      expect(FocusManager.instance.primaryFocus, same(elsewhere));
    });

    testWidgets('the control is reachable and activatable from a keyboard', (
      WidgetTester tester,
    ) async {
      int attempts = 0;
      await pump(
        tester,
        IuxErrorRecovery(
          categoryLabel: _kCategory,
          message: _kMessage,
          route: IuxRetryRoute(
            label: _kRetryLabel,
            onRetry: () => attempts++,
          ),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(attempts, 1);
    });
  });

  group('the retry stays reachable', () {
    /// The scales the audit measures, and the screen it measures them on.
    const List<double> scales = <double>[1, 1.5, 2, 3];
    const Size small = Size(320, 640);

    /// A block carrying what a real one carries, so the control sits where a
    /// real one puts it: under a long explanation.
    IuxErrorRecovery block(VoidCallback onRetry) => IuxErrorRecovery(
          categoryLabel: _kCategory,
          message: _kLongMessage,
          route: IuxRetryRoute(label: _kRetryLabel, onRetry: onRetry),
        );

    /// Drags from the middle of the viewport until the block stops moving.
    ///
    /// Repeated rather than one long drag, because a message this long at 300%
    /// is taller than any single gesture; the physics clamp the last one. The
    /// start point is never on top of the control being reached.
    Future<void> dragToTheEnd(WidgetTester tester) async {
      for (int i = 0; i < 8; i++) {
        await tester.dragFrom(const Offset(160, 320), const Offset(0, -2000));
        await tester.pumpAndSettle();
      }
    }

    testWidgets(
        'the retry can be reached and pressed at 100, 150, 200 and 300 '
        'per cent', (WidgetTester tester) async {
      // The third pattern with the defect IUX-038 measured on the other two,
      // found because the test that should have caught it wrapped the block in
      // a scroll view. Measured before the fix, standalone on 320x640 at 200%:
      // `RenderFlex overflowed by 2312 pixels` and the retry off screen — an
      // error the user is told about and cannot act on.
      for (final double scale in scales) {
        int attempts = 0;
        await pump(
          tester,
          block(() => attempts++),
          textScale: scale,
          size: small,
        );

        // DebugOverflowIndicatorMixin reports an overflow once per render
        // object lifetime, so this assertion is only worth anything because
        // every case ends by tearing the tree down (IUX-QA-VACUOUS-003).
        expect(tester.takeException(), isNull, reason: 'at ${scale}x');
        expect(find.byType(Scrollable), findsOneWidget, reason: 'at ${scale}x');

        final Finder retry = find.byType(IuxButton);
        await dragToTheEnd(tester);

        expect(retry.hitTestable(), findsOneWidget, reason: 'at ${scale}x');
        await tester.tap(retry);
        await tester.pump();
        expect(attempts, 1, reason: 'at ${scale}x');

        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets(
        'a caller who already scrolls does not get a second scroll view',
        (WidgetTester tester) async {
      // Every vertical scroll view hands its children an unbounded height, so
      // the block sees one and adds nothing. The documented placement keeps
      // costing exactly what it cost before.
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
              "caller's — a second one is a nested scrollable",
        );

        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('a block that fits is not moved and takes no gesture',
        (WidgetTester tester) async {
      // The fix has to be invisible where there was nothing wrong.
      await pump(
        tester,
        IuxErrorRecovery(
          categoryLabel: _kCategory,
          message: _kMessage,
          route: IuxRetryRoute(label: _kRetryLabel, onRetry: () {}),
        ),
        size: small,
      );

      final Rect before = tester.getRect(find.text(_kMessage));
      await dragToTheEnd(tester);

      expect(tester.getRect(find.text(_kMessage)), before);
      expect(tester.takeException(), isNull);
    });
  });

  group('layout under pressure', () {
    testWidgets('a long message wraps rather than clipping', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        IuxErrorRecovery(
          categoryLabel: _kCategory,
          message: _kLongMessage,
          route: IuxRetryRoute(label: _kRetryLabel, onRetry: () {}),
        ),
        size: const Size(320, 900),
      );

      // Half a sentence about a failure is a failure the user cannot act on.
      final Text text = tester.widget<Text>(find.text(_kLongMessage));
      expect(text.maxLines, isNull);
      expect(text.overflow, isNot(TextOverflow.ellipsis));
      expect(tester.takeException(), isNull);
    });

    testWidgets('it survives 200% text on a small screen', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        IuxErrorRecovery(
          categoryLabel: _kCategory,
          message: _kLongMessage,
          route: IuxRetryRoute(label: _kRetryLabel, onRetry: () {}),
        ),
        textScale: 2,
        size: const Size(320, 640),
      );

      expect(tester.takeException(), isNull);
      // Whole, not truncated: an ellipsis would hide the content the user
      // enlarged their text in order to read.
      expect(find.text(_kLongMessage), findsOneWidget);
      expect(
        tester.widget<Text>(find.text(_kLongMessage)).overflow,
        isNot(TextOverflow.ellipsis),
      );
    });

    testWidgets('the control keeps the touch target floor', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        IuxErrorRecovery(
          categoryLabel: _kCategory,
          message: _kMessage,
          route: IuxRetryRoute(label: _kRetryLabel, onRetry: () {}),
        ),
      );

      final Size control = tester.getSize(find.byType(IuxButton));
      final BuildContext context =
          tester.element(find.byType(IuxErrorRecovery));
      final double floor = IuxAccessibility.of(context).minimumTouchTarget;

      expect(control.height, greaterThanOrEqualTo(floor));
    });

    testWidgets('it lays out right to left without complaint', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        IuxErrorRecovery(
          categoryLabel: _kCategory,
          message: _kMessage,
          route: IuxRetryRoute(label: _kRetryLabel, onRetry: () {}),
        ),
        direction: TextDirection.rtl,
      );

      expect(tester.takeException(), isNull);
      expect(find.text(_kMessage), findsOneWidget);
    });

    testWidgets('it renders under every theme profile', (
      WidgetTester tester,
    ) async {
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
        await pump(
          tester,
          IuxErrorRecovery(
            categoryLabel: _kCategory,
            message: _kMessage,
            route: IuxRetryRoute(label: _kRetryLabel, onRetry: () {}),
          ),
          configuration: configuration,
        );

        expect(tester.takeException(), isNull);
        expect(find.text(_kMessage), findsOneWidget);

        // DebugOverflowIndicatorMixin reports an overflow once per render
        // object lifetime, so without this every case after the first would
        // pass whatever it laid out (IUX-QA-VACUOUS-003).
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('nothing animates on arrival', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: IuxTheme.fromConfiguration(const IuxThemeConfiguration()),
          home: Scaffold(
            body: IuxErrorRecovery(
              categoryLabel: _kCategory,
              message: _kMessage,
              route: IuxRetryRoute(label: _kRetryLabel, onRetry: () {}),
            ),
          ),
        ),
      );

      // One frame is enough. An entrance animation here would delay the
      // announcement to save nothing, and there is therefore nothing for a
      // reduced-motion preference to remove.
      expect(find.text(_kMessage), findsOneWidget);
      expect(find.text(_kRetryLabel), findsOneWidget);
    });
  });
}
