import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';
// Not yet in the barrel: the team lead owns that file. Imported from source so
// the pattern can be tested before the export lands.

/// What is being waited on. Names the work, not the widget.
const String _kLoadingLabel = 'Loading your orders';

/// The localised word for the category, which IUX may never compose.
const String _kCategoryLabel = 'Error';

/// What went wrong, and whether trying again is worth the user's time.
const String _kFailureMessage =
    'Your orders could not be loaded because the device is offline.';

/// What a screen reader hears when the failed region appears.
const String _kSpokenFailure = '$_kCategoryLabel. $_kFailureMessage';

/// The word on the control.
const String _kRetryLabel = 'Try again';

/// The announced name, fuller than the visible one.
const String _kRetrySemanticLabel = 'Reload the orders';

/// What the load produced.
const String _kContent = 'Order 3141';

/// A message long enough to prove the report wraps rather than clips.
const String _kLongMessage =
    'Your orders could not be loaded because the connection to the ordering '
    'service was refused, which usually means the device is offline or a '
    'proxy is blocking it; the orders themselves are safe and nothing has '
    'been lost, so trying again once the connection is back will bring them '
    'all straight into this list exactly as they were.';

IuxThemeConfiguration _withMotion(IuxMotionPreference motion) =>
    IuxThemeConfiguration(profile: IuxAccessibilityProfile(motion: motion));

/// Builds a retry route, defaulting to one that does nothing observable.
IuxRetryRoute retryRoute({
  String label = _kRetryLabel,
  String? semanticLabel = _kRetrySemanticLabel,
  bool isRunning = false,
  String? busyHint,
  VoidCallback? onRetry,
}) =>
    IuxRetryRoute(
      label: label,
      semanticLabel: semanticLabel,
      isRunning: isRunning,
      busyHint: busyHint,
      onRetry: onRetry ?? () {},
    );

void main() {
  /// Puts one region on a page, under the conditions given.
  ///
  /// Never `pumpAndSettle`: an indeterminate indicator animates forever by
  /// design, so a helper that settled would hang for as long as the wait is on
  /// screen. Fixed frames instead, which is also closer to what the user sees.
  Future<void> host(
    WidgetTester tester,
    Widget region, {
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
          // Keyed by configuration so a test that switches profiles gets the
          // new theme outright rather than a 200ms cross-fade between two.
          key: ValueKey<IuxThemeConfiguration>(configuration),
          theme: IuxTheme.fromConfiguration(configuration),
          home: Directionality(
            textDirection: direction,
            child: Scaffold(body: Center(child: region)),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Widget region(
    IuxLoadState<String> state, {
    IuxRecoveryRoute? recovery,
    String loadingLabel = _kLoadingLabel,
  }) =>
      IuxLoadingRetry<String>(
        state: state,
        loadingLabel: loadingLabel,
        failureCategoryLabel: _kCategoryLabel,
        recovery: recovery ?? retryRoute(),
        builder: (BuildContext context, String value) => Text(value),
      );

  group('a load is one value, not three booleans', () {
    test('a failure with no wording is refused', () {
      // A region that stopped working and a control called "Try again", with
      // no account of why either is there.
      expect(
        () => IuxLoadState<String>.failed(message: ''),
        throwsAssertionError,
      );
    });

    test('two states of the same kind carrying the same thing are equal', () {
      expect(
        const IuxLoadState<String>.loading(),
        equals(const IuxLoadState<String>.loading()),
      );
      expect(
        const IuxLoadState<String>.ready(_kContent),
        equals(const IuxLoadState<String>.ready(_kContent)),
      );
      expect(
        const IuxLoadState<String>.failed(message: _kFailureMessage),
        equals(const IuxLoadState<String>.failed(message: _kFailureMessage)),
      );
    });

    test('states of different kinds never compare equal', () {
      expect(
        const IuxLoadState<String>.loading(),
        isNot(equals(const IuxLoadState<String>.ready(_kContent))),
      );
      expect(
        const IuxLoadState<String>.ready(_kContent),
        isNot(
          equals(const IuxLoadState<String>.failed(message: _kFailureMessage)),
        ),
      );
    });

    test('equality stays symmetric across a covariant type argument', () {
      // The defect this file was opened on. Dart generics are covariant, so
      // IuxLoadReady<int> *is* an IuxLoadReady<Object>: a type test called
      // these equal in one direction and unequal in the other, while hashCode —
      // which folds T in — called them different values throughout. That is a
      // value a Set holds twice and a Map never finds.
      const IuxLoadState<Object> loose = IuxLoadReady<Object>(1);
      const IuxLoadState<int> tight = IuxLoadReady<int>(1);

      expect(loose == tight, equals(tight == loose));
      expect(loose == tight, isFalse);
      // The pair a hash-based collection actually depends on.
      expect(<Object>{loose, tight}, hasLength(2));

      const IuxLoadState<Object> looseWait = IuxLoadInProgress<Object>();
      const IuxLoadState<int> tightWait = IuxLoadInProgress<int>();
      expect(looseWait == tightWait, equals(tightWait == looseWait));
      expect(looseWait == tightWait, isFalse);

      const IuxLoadState<Object> looseFail =
          IuxLoadFailed<Object>(message: _kFailureMessage);
      const IuxLoadState<int> tightFail =
          IuxLoadFailed<int>(message: _kFailureMessage);
      expect(looseFail == tightFail, equals(tightFail == looseFail));
      expect(looseFail == tightFail, isFalse);
    });

    test('equal states agree on their hash code', () {
      expect(
        const IuxLoadState<String>.loading().hashCode,
        equals(const IuxLoadState<String>.loading().hashCode),
      );
      expect(
        const IuxLoadState<String>.ready(_kContent).hashCode,
        equals(const IuxLoadState<String>.ready(_kContent).hashCode),
      );
      expect(
        const IuxLoadState<String>.failed(message: _kFailureMessage).hashCode,
        equals(
          const IuxLoadState<String>.failed(message: _kFailureMessage).hashCode,
        ),
      );
    });

    test('a state names itself and its type for a debugger', () {
      expect(
        const IuxLoadState<String>.loading().toString(),
        contains('String'),
      );
      expect(
        const IuxLoadState<String>.ready(_kContent).toString(),
        contains(_kContent),
      );
      expect(
        const IuxLoadState<String>.failed(message: _kFailureMessage).toString(),
        contains(_kFailureMessage),
      );
    });

    test('an empty result is a ready value, not a fourth state', () {
      // The load answered; what came back has nothing in it. Which kind of
      // emptiness that is belongs to IuxEmptyStateCause, which distinguishes
      // four and would be flattened into one by a state named "empty".
      const IuxLoadState<List<String>> answered =
          IuxLoadState<List<String>>.ready(<String>[]);
      expect(answered, isA<IuxLoadReady<List<String>>>());
    });
  });

  group('a region with no wording for its wait is refused', () {
    test('an empty loading label is refused', () {
      expect(
        () => IuxLoadingRetry<String>(
          state: const IuxLoadState<String>.loading(),
          loadingLabel: '',
          failureCategoryLabel: _kCategoryLabel,
          recovery: retryRoute(),
          builder: (BuildContext context, String value) => Text(value),
        ),
        throwsAssertionError,
      );
    });

    test('the label is required even when the region is not waiting', () {
      // A label that only had to exist in the branch that uses it is a label a
      // caller discovers is missing on the slow request they cannot reproduce.
      expect(
        () => IuxLoadingRetry<String>(
          state: const IuxLoadState<String>.ready(_kContent),
          loadingLabel: '',
          failureCategoryLabel: _kCategoryLabel,
          recovery: retryRoute(),
          builder: (BuildContext context, String value) => Text(value),
        ),
        throwsAssertionError,
      );
    });
  });

  group('exactly one branch is on screen', () {
    testWidgets('a wait shows the wait and nothing else',
        (WidgetTester tester) async {
      await host(tester, region(const IuxLoadState<String>.loading()));

      expect(find.text(_kLoadingLabel), findsOneWidget);
      expect(find.text(_kContent), findsNothing);
      expect(find.text(_kFailureMessage), findsNothing);
      expect(find.text(_kRetryLabel), findsNothing);
    });

    testWidgets('content shows the content and nothing else',
        (WidgetTester tester) async {
      await host(tester, region(const IuxLoadState<String>.ready(_kContent)));

      expect(find.text(_kContent), findsOneWidget);
      // The recovery route was supplied and is still not on screen: a way out
      // of a failure that did not happen is a control that cannot work.
      expect(find.text(_kRetryLabel), findsNothing);
      expect(find.text(_kLoadingLabel), findsNothing);
    });

    testWidgets('a failure shows the failure and its way out',
        (WidgetTester tester) async {
      await host(
        tester,
        region(const IuxLoadState<String>.failed(message: _kFailureMessage)),
      );

      expect(find.text(_kFailureMessage), findsOneWidget);
      expect(find.text(_kRetryLabel), findsOneWidget);
      expect(find.text(_kContent), findsNothing);
      expect(find.text(_kLoadingLabel), findsNothing);
    });

    testWidgets('an empty result is the caller s empty state, in place',
        (WidgetTester tester) async {
      await host(
        tester,
        IuxLoadingRetry<List<String>>(
          state: const IuxLoadState<List<String>>.ready(<String>[]),
          loadingLabel: _kLoadingLabel,
          failureCategoryLabel: _kCategoryLabel,
          recovery: retryRoute(),
          builder: (BuildContext context, List<String> orders) => orders.isEmpty
              ? IuxEmptyState(
                  cause: IuxNoMatches(
                    reset: IuxEmptyStateAction(
                      label: 'Show all orders',
                      action: const IuxActionDescriptor(
                        semantics: IuxActionSemantics(label: 'Show all orders'),
                      ),
                      onActivate: () {},
                    ),
                  ),
                  title: 'No orders match these filters',
                )
              : const Text(_kContent),
        ),
      );

      // Still exactly one branch: the pattern rendered ready, and the situation
      // was named by the pattern that owns the vocabulary for it.
      expect(find.text('No orders match these filters'), findsOneWidget);
      expect(find.text(_kLoadingLabel), findsNothing);
      expect(find.text(_kRetryLabel), findsNothing);
    });

    testWidgets('the state alone decides, and the region follows it',
        (WidgetTester tester) async {
      await host(tester, region(const IuxLoadState<String>.loading()));
      expect(find.text(_kLoadingLabel), findsOneWidget);

      await host(
        tester,
        region(const IuxLoadState<String>.failed(message: _kFailureMessage)),
      );
      // The wait is gone, not layered under the failure.
      expect(find.text(_kLoadingLabel), findsNothing);
      expect(find.text(_kFailureMessage), findsOneWidget);

      await host(tester, region(const IuxLoadState<String>.ready(_kContent)));
      // And the failure is gone, not left stale beside the content.
      expect(find.text(_kFailureMessage), findsNothing);
      expect(find.text(_kContent), findsOneWidget);
    });
  });

  group('the failed branch is IuxErrorRecovery, not a second error block', () {
    testWidgets('the route decides what the failed region offers',
        (WidgetTester tester) async {
      await host(
        tester,
        region(
          const IuxLoadState<String>.failed(message: _kFailureMessage),
          recovery: IuxAlternativeRoute(
            action: IuxNamedAction(
              label: 'Sign in again',
              onActivate: () {},
            ),
          ),
        ),
      );

      // A 401 is not retryable, and the type is what says so. This pattern
      // holds no second opinion about it.
      expect(find.text('Sign in again'), findsOneWidget);
      expect(find.text(_kRetryLabel), findsNothing);
    });

    testWidgets('a failure nobody can act on still says something',
        (WidgetTester tester) async {
      await host(
        tester,
        region(
          const IuxLoadState<String>.failed(message: _kFailureMessage),
          recovery: const IuxUnrecoverable(
            guidance:
                'Nothing has been charged. Contact support with ref 3141.',
          ),
        ),
      );

      expect(find.byType(IuxButton), findsNothing);
      expect(
        find.text('Nothing has been charged. Contact support with ref 3141.'),
        findsOneWidget,
      );
    });

    testWidgets('the block is drawn once, by the pattern that owns it',
        (WidgetTester tester) async {
      await host(
        tester,
        region(const IuxLoadState<String>.failed(message: _kFailureMessage)),
      );

      // Delegation rather than a second implementation: this pattern's whole
      // contribution to the failed branch is choosing it.
      expect(find.byType(IuxErrorRecovery), findsOneWidget);
    });
  });

  group('what a screen reader is told', () {
    testWidgets('the wait announces what is being waited on',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(tester, region(const IuxLoadState<String>.loading()));

      final SemanticsNode node =
          tester.getSemantics(find.bySemanticsLabel(_kLoadingLabel));
      // Announced, not silent. A wait is usually gone before a user reading
      // linearly arrives at it, so the announcement is the only chance they get.
      expect(node, isSemantics(isLiveRegion: true));
      // Exactly the caller's sentence: the framework appended nothing.
      expect(node.getSemanticsData().label, _kLoadingLabel);

      handle.dispose();
    });

    testWidgets('the failure announces its category and its explanation',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(
        tester,
        region(const IuxLoadState<String>.failed(message: _kFailureMessage)),
      );

      final SemanticsNode node =
          tester.getSemantics(find.bySemanticsLabel(_kSpokenFailure));
      expect(node, isSemantics(isLiveRegion: true));
      // The category word is the only carrier of "this is a failure" that
      // survives a screen reader, and it is the caller's word, not IUX's.
      expect(node.getSemanticsData().label, _kSpokenFailure);

      handle.dispose();
    });

    testWidgets('all three branches agree about announcing themselves',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await host(tester, region(const IuxLoadState<String>.loading()));
      expect(
        tester.getSemantics(find.bySemanticsLabel(_kLoadingLabel)),
        isSemantics(isLiveRegion: true),
      );

      await host(
        tester,
        region(const IuxLoadState<String>.failed(message: _kFailureMessage)),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel(_kSpokenFailure)),
        isSemantics(isLiveRegion: true),
      );

      // And the content is not a live region: it is what the user came for,
      // and announcing it would interrupt them reading it.
      await host(tester, region(const IuxLoadState<String>.ready(_kContent)));
      expect(
        tester.getSemantics(find.text(_kContent)),
        isSemantics(isLiveRegion: false),
      );

      handle.dispose();
    });

    testWidgets('the recovery control stays a control of its own',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(
        tester,
        region(const IuxLoadState<String>.failed(message: _kFailureMessage)),
      );

      final SemanticsNode retry =
          tester.getSemantics(find.bySemanticsLabel(_kRetrySemanticLabel));
      // Merged into the message it would be announced and unreachable.
      expect(
        retry,
        isNot(same(tester.getSemantics(find.bySemanticsLabel(
          _kSpokenFailure,
        )))),
      );
      expect(
        retry,
        matchesSemantics(
          label: _kRetrySemanticLabel,
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
      await host(
        tester,
        region(const IuxLoadState<String>.failed(message: _kFailureMessage)),
      );

      // "Try again" on screen, "Reload the orders" in a screen reader — which
      // is what tells two failed sections apart.
      expect(find.text(_kRetryLabel), findsOneWidget);
      expect(find.bySemanticsLabel(_kRetrySemanticLabel), findsOneWidget);

      handle.dispose();
    });

    testWidgets('a retry driven in place announces that it is running',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(
        tester,
        region(
          const IuxLoadState<String>.failed(message: _kFailureMessage),
          recovery: retryRoute(
            isRunning: true,
            busyHint: 'Reloading your orders',
          ),
        ),
      );

      // Silence here is indistinguishable from a control that did nothing, on
      // a screen that has already said something is broken.
      final SemanticsNode node =
          tester.getSemantics(find.bySemanticsLabel(_kRetrySemanticLabel));
      expect(node.getSemanticsData().hint, contains('Reloading your orders'));

      // Probed, not assumed. This asserted the opposite until IUX-038:
      // IuxButton derived its announced enabled state from
      // IuxActionDescriptor.isActivatable, which is false while an action is in
      // progress under the default repeat policy, so a *running* retry was
      // announced as unavailable rather than as busy (IUX-BUTTON-BUSY-001).
      // Availability and operation are orthogonal in the action model, and the
      // descriptor even asserts that a disabled action cannot be in progress;
      // the button collapsed them anyway. It no longer does — only
      // availability decides what is announced — so the running retry says it
      // is working, which is what busyHint is attached to.
      expect(
        node,
        isSemantics(hasEnabledState: true, isEnabled: true),
        reason: 'a busy retry is working, not unavailable',
      );

      handle.dispose();
    });

    testWidgets('the failure is one stop, not one per line',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(
        tester,
        region(const IuxLoadState<String>.failed(message: _kFailureMessage)),
      );

      // One node carries the whole explanation, and the glyph beside it adds
      // none at all.
      expect(find.bySemanticsLabel(_kSpokenFailure), findsOneWidget);
      // The sentence is not also a stop of its own. Left as two nodes, a
      // screen-reader user lands on a category word and then on a fragment,
      // and has to assemble the explanation themselves.
      expect(find.bySemanticsLabel(_kFailureMessage), findsNothing);

      handle.dispose();
    });
  });

  group('the recovery runs once, when the user asks', () {
    testWidgets('activating it calls the parent exactly once',
        (WidgetTester tester) async {
      int attempts = 0;
      await host(
        tester,
        region(
          const IuxLoadState<String>.failed(message: _kFailureMessage),
          recovery: retryRoute(onRetry: () => attempts++),
        ),
      );

      await tester.tap(find.text(_kRetryLabel));
      await tester.pump();
      expect(attempts, 1);
    });

    testWidgets('the region does not change itself when it is activated',
        (WidgetTester tester) async {
      await host(
        tester,
        region(const IuxLoadState<String>.failed(message: _kFailureMessage)),
      );

      await tester.tap(find.text(_kRetryLabel));
      await tester.pump();

      // Still failed. Whether the second attempt is running is something only
      // the parent can know, and a pattern that switched itself to a wait would
      // be claiming an outcome before there was one.
      expect(find.text(_kFailureMessage), findsOneWidget);
      expect(find.text(_kLoadingLabel), findsNothing);
    });

    testWidgets('a retry already in flight cannot be started again',
        (WidgetTester tester) async {
      int attempts = 0;
      await host(
        tester,
        region(
          const IuxLoadState<String>.failed(message: _kFailureMessage),
          recovery: retryRoute(
            onRetry: () => attempts++,
            isRunning: true,
            busyHint: 'Reloading your orders',
          ),
        ),
      );

      await tester.tap(find.text(_kRetryLabel), warnIfMissed: false);
      await tester.tap(find.text(_kRetryLabel), warnIfMissed: false);
      await tester.pump();

      // The request storm, stopped by the action policy rather than by a timer.
      expect(attempts, 0);
    });

    testWidgets('there is nothing to press while the load is running',
        (WidgetTester tester) async {
      await host(tester, region(const IuxLoadState<String>.loading()));

      // The stronger of the two guards: in the default flow the control does
      // not exist, so it cannot be activated a second time at all.
      expect(find.byType(IuxButton), findsNothing);
    });

    testWidgets('nothing retries without being asked',
        (WidgetTester tester) async {
      int attempts = 0;
      await host(
        tester,
        region(
          const IuxLoadState<String>.failed(message: _kFailureMessage),
          recovery: retryRoute(onRetry: () => attempts++),
        ),
      );

      // No timer, no backoff, no attempt counter. Ten seconds of frames and the
      // failing service has been asked for nothing.
      for (int frame = 0; frame < 10; frame++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(attempts, 0);
      // And the region has not decided the load failed harder, or timed out, or
      // recovered on its own.
      expect(find.text(_kFailureMessage), findsOneWidget);
    });

    testWidgets('a wait that never answers stays a wait',
        (WidgetTester tester) async {
      await host(tester, region(const IuxLoadState<String>.loading()));

      for (int frame = 0; frame < 30; frame++) {
        await tester.pump(const Duration(seconds: 1));
      }

      // No timeout, so WCAG SC 2.2.1 has no time limit to adjust. Reporting a
      // failure here would be claiming an outcome the operation never reported.
      expect(find.text(_kLoadingLabel), findsOneWidget);
      expect(find.text(_kFailureMessage), findsNothing);
    });
  });

  group('the wait survives a user who asked for no motion', () {
    testWidgets('the bar is removed and the wording stays',
        (WidgetTester tester) async {
      await host(
        tester,
        region(const IuxLoadState<String>.loading()),
        configuration: _withMotion(IuxMotionPreference.none),
      );

      // Not frozen: a stationary segment reads as a hung operation rather than
      // a running one. Removed, with the label carrying the whole message.
      expect(find.byType(FractionallySizedBox), findsNothing);
      expect(find.text(_kLoadingLabel), findsOneWidget);
    });

    testWidgets('a reduced preference keeps the bar moving',
        (WidgetTester tester) async {
      await host(
        tester,
        region(const IuxLoadState<String>.loading()),
        configuration: _withMotion(IuxMotionPreference.reduced),
      );

      // Progress is preserved under a reduction: removing it would hide that
      // work is happening, which is worse than the movement.
      expect(find.byType(FractionallySizedBox), findsOneWidget);
      expect(find.text(_kLoadingLabel), findsOneWidget);
    });

    testWidgets('the wait keeps moving across frames',
        (WidgetTester tester) async {
      await host(tester, region(const IuxLoadState<String>.loading()));

      double alignmentOf() => (tester
              .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
              .alignment as AlignmentDirectional)
          .start;

      final double first = alignmentOf();
      // Fixed frames, never pumpAndSettle: this animation has no end.
      await tester.pump(const Duration(milliseconds: 300));
      expect(alignmentOf(), isNot(equals(first)));
    });

    testWidgets('the failed branch animates nothing to remove',
        (WidgetTester tester) async {
      await host(
        tester,
        region(const IuxLoadState<String>.failed(message: _kFailureMessage)),
        configuration: _withMotion(IuxMotionPreference.none),
      );

      expect(tester.takeException(), isNull);
      expect(find.text(_kFailureMessage), findsOneWidget);
      expect(find.text(_kRetryLabel), findsOneWidget);
    });
  });

  group('the region survives the conditions it will meet', () {
    testWidgets('a long failure wraps rather than clips',
        (WidgetTester tester) async {
      await host(
        tester,
        region(const IuxLoadState<String>.failed(message: _kLongMessage)),
      );

      expect(tester.takeException(), isNull);
      expect(find.text(_kLongMessage), findsOneWidget);
      expect(find.text(_kRetryLabel), findsOneWidget);
    });

    testWidgets('it survives 200% text on a narrow screen',
        (WidgetTester tester) async {
      await host(
        tester,
        region(const IuxLoadState<String>.failed(message: _kFailureMessage)),
        textScale: 2,
        size: const Size(320, 800),
      );

      expect(tester.takeException(), isNull);
      expect(find.text(_kFailureMessage), findsOneWidget);
      expect(find.text(_kRetryLabel), findsOneWidget);
    });

    testWidgets('the wait survives 200% text on a small screen',
        (WidgetTester tester) async {
      await host(
        tester,
        region(const IuxLoadState<String>.loading()),
        textScale: 2,
        size: const Size(320, 600),
      );

      expect(tester.takeException(), isNull);
      expect(find.text(_kLoadingLabel), findsOneWidget);
    });

    testWidgets('it renders right to left', (WidgetTester tester) async {
      await host(
        tester,
        region(const IuxLoadState<String>.failed(message: _kFailureMessage)),
        direction: TextDirection.rtl,
      );

      expect(tester.takeException(), isNull);
      expect(find.text(_kFailureMessage), findsOneWidget);
      expect(find.text(_kRetryLabel), findsOneWidget);
    });

    testWidgets('it renders in every contrast and brightness profile',
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
        await host(
          tester,
          region(const IuxLoadState<String>.failed(message: _kFailureMessage)),
          configuration: configuration,
        );
        expect(tester.takeException(), isNull, reason: '$configuration');
        expect(find.text(_kFailureMessage), findsOneWidget);

        // DebugOverflowIndicatorMixin reports an overflow once per render
        // object lifetime, so without a teardown between cases every case
        // after the first would pass whatever it laid out
        // (IUX-QA-VACUOUS-003). Two per iteration, because the wait and the
        // failure are two different layouts.
        await tester.pumpWidget(const SizedBox.shrink());

        await host(
          tester,
          region(const IuxLoadState<String>.loading()),
          configuration: configuration,
        );
        expect(tester.takeException(), isNull, reason: '$configuration');
        expect(find.text(_kLoadingLabel), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
      }
    });
  });

  group('what happens to focus, probed rather than asserted in prose', () {
    /// The node the recovery control is focusing on.
    FocusNode retryFocus(WidgetTester tester) =>
        Focus.of(tester.element(find.text(_kRetryLabel)));

    testWidgets('returning the region to a wait takes the focused control away',
        (WidgetTester tester) async {
      await host(
        tester,
        region(const IuxLoadState<String>.failed(message: _kFailureMessage)),
      );

      final FocusNode node = retryFocus(tester)..requestFocus();
      await tester.pump();
      expect(node.hasPrimaryFocus, isTrue);

      await host(tester, region(const IuxLoadState<String>.loading()));

      // The documented limitation, held to by a test rather than a paragraph:
      // the control the user activated is unmounted and focus does not stay on
      // it. The live region on the wait is what tells them it was accepted.
      expect(node.hasPrimaryFocus, isFalse);
      expect(find.text(_kLoadingLabel), findsOneWidget);
    });

    testWidgets('driving the retry in place does not keep focus either',
        (WidgetTester tester) async {
      await host(
        tester,
        region(const IuxLoadState<String>.failed(message: _kFailureMessage)),
      );

      final FocusNode node = retryFocus(tester)..requestFocus();
      await tester.pump();
      expect(node.hasPrimaryFocus, isTrue);

      await host(
        tester,
        region(
          const IuxLoadState<String>.failed(message: _kFailureMessage),
          recovery: retryRoute(
            isRunning: true,
            busyHint: 'Reloading your orders',
          ),
        ),
      );

      // This was written expecting focus to survive — the control is still
      // mounted, after all — and the probe said otherwise, because IuxButton
      // passed IuxActionDescriptor.isActivatable to
      // IuxFocusable.canRequestFocus and that getter is false while an action
      // is in progress (IUX-BUTTON-BUSY-002). The consequence was worse than a
      // lost tab stop: busyHint exists precisely so a running control is not
      // silent, and it was announced on a node the user had just been moved
      // off.
      //
      // Fixed at IUX-038, and this is the assertion flipped. Only
      // *unavailable* now removes a control from the focus order, so driving
      // the retry in place keeps the user where they were — which is what
      // makes this flow worth choosing.
      expect(find.text(_kRetryLabel), findsOneWidget);
      expect(
        retryFocus(tester).hasPrimaryFocus,
        isTrue,
        reason: 'a busy IuxButton is still the control the user is standing on',
      );
    });
  });

  group('the numbers behind the wait, measured rather than assumed', () {
    /// The tokens a component would resolve under [configuration].
    Future<IuxProgressTokens> tokensFor(
      WidgetTester tester,
      IuxThemeConfiguration configuration,
    ) async {
      late IuxProgressTokens resolved;
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey<IuxThemeConfiguration>(configuration),
          theme: IuxTheme.fromConfiguration(configuration),
          home: Builder(
            builder: (BuildContext context) {
              resolved = IuxProgressResolver.resolve(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      // Safe to settle: no indicator is mounted in this harness.
      await tester.pumpAndSettle();
      return resolved;
    }

    testWidgets('one sweep of the bar lasts long enough to read as work',
        (WidgetTester tester) async {
      final IuxProgressTokens standard = await tokensFor(
        tester,
        _withMotion(IuxMotionPreference.standard),
      );
      final IuxProgressTokens reduced = await tokensFor(
        tester,
        _withMotion(IuxMotionPreference.reduced),
      );
      final IuxProgressTokens none = await tokensFor(
        tester,
        _withMotion(IuxMotionPreference.none),
      );

      // The measurement the documented threshold rests on. A load that resolves
      // in 80ms shows the bar for less than a twentieth of one crossing: the
      // user sees it appear, jump and vanish, which is why it reads as a glitch
      // rather than as work being done.
      expect(standard.traversal, const Duration(milliseconds: 1800));
      // Never faster under a reduction: halving a cycle doubles how often the
      // segment sweeps past, so the user who asked for less would get more.
      expect(reduced.traversal, greaterThanOrEqualTo(standard.traversal));
      expect(none.traversal, Duration.zero);
      expect(none.requiresStaticAlternative, isTrue);
    });
  });
}
