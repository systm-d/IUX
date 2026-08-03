import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';
// Not in the barrel yet: the team lead owns that file. Imported from source so
// the pattern can be tested before the export lands.

/// What the box searches. Names the collection, not the act.
const String _kSearchLabel = 'Search your orders';

/// The name of the control that empties the box.
const String _kClearLabel = 'Clear the search';

/// What is being waited on while the search runs.
const String _kSearchingLabel = 'Searching your orders';

/// The localised word for the failure category, which IUX may never compose.
const String _kCategoryLabel = 'Error';

/// What went wrong, and whether trying again is worth the user's time.
const String _kFailureMessage =
    'Your orders could not be searched because the device is offline.';

/// The way back to results when nothing matched.
const String _kResetLabel = 'Clear the search and show everything';

/// What a search that matched nothing is called, in the caller's words.
const String _kNothingMatches = 'Nothing matches trainers';

/// What would find something, when nothing did.
const String _kGuidance = 'Order numbers need their leading zeros.';

/// What the query is matched against, read after the name.
const String _kHint = 'Matches order numbers and customer names';

/// An example query, shown while the box is empty.
const String _kPlaceholder = 'AB-00417';

/// A summary long enough to prove the status line wraps rather than clips.
const String _kLongSummary =
    'Two hundred and forty-seven orders match the words you typed, which is '
    'more than this list shows at once, so narrowing the search by adding the '
    'customer name or the month the order was placed will usually get you to '
    'the one you are looking for a great deal faster than scrolling will.';

IuxThemeConfiguration _withMotion(IuxMotionPreference motion) =>
    IuxThemeConfiguration(profile: IuxAccessibilityProfile(motion: motion));

/// What the caller says about a settled search.
String _summary(BuildContext context, List<String> results) =>
    results.isEmpty ? _kNothingMatches : '${results.length} orders';

/// The exit offered when nothing matched.
IuxEmptyStateAction _reset({VoidCallback? onActivate}) => IuxEmptyStateAction(
      label: _kResetLabel,
      action: const IuxActionDescriptor(
        semantics: IuxActionSemantics(label: _kResetLabel),
      ),
      onActivate: onActivate ?? () {},
    );

void main() {
  /// Every live region in the tree, in traversal order, as the label a screen
  /// reader would be given.
  ///
  /// Walking the real tree rather than asserting prose. The root is reached by
  /// climbing from a node the finder can reach, because the binding's own
  /// accessor for it is deprecated.
  List<String> liveRegions(WidgetTester tester) {
    SemanticsNode node = tester.getSemantics(find.byType(MaterialApp));
    while (node.parent != null) {
      node = node.parent!;
    }

    final List<String> found = <String>[];
    void walk(SemanticsNode current) {
      // A node merged into its parent is not a stop and is not announced
      // separately: its label is already part of the parent's. Counting it
      // would report one announcement as two.
      if (!current.isMergedIntoParent) {
        final SemanticsData data = current.getSemanticsData();
        if (data.flagsCollection.isLiveRegion) found.add(data.label);
      }
      current.visitChildren((SemanticsNode child) {
        walk(child);
        return true;
      });
    }

    walk(node);
    return found;
  }

  /// Puts a widget on a page under the conditions given.
  ///
  /// Never `pumpAndSettle`. The wait branch mounts an indeterminate indicator
  /// which animates for as long as it is on screen by design, so a helper that
  /// settled would never return. Fixed frames instead, which is also closer to
  /// what the user sees.
  Future<void> host(
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
          // Keyed by configuration so a test that switches profiles gets the
          // new theme outright rather than a cross-fade between two.
          key: ValueKey<IuxThemeConfiguration>(configuration),
          theme: IuxTheme.fromConfiguration(configuration),
          home: Directionality(
            textDirection: direction,
            child: Scaffold(body: child),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// A results region, bounded as the widget requires.
  Widget region(
    IuxLoadState<List<String>> state, {
    IuxSearchSummary<String>? summary,
    IuxRecoveryRoute? recovery,
    IuxEmptyStateAction? reset,
    String? guidance,
  }) =>
      SizedBox(
        height: 600,
        child: IuxSearchResults<String>(
          results: state,
          summary: summary ?? _summary,
          searchingLabel: _kSearchingLabel,
          failureCategoryLabel: _kCategoryLabel,
          recovery:
              recovery ?? IuxRetryRoute(label: 'Try again', onRetry: () {}),
          reset: reset ?? _reset(),
          noMatchesGuidance: guidance,
          builder: (BuildContext context, List<String> value) => ListView(
              children: <Widget>[for (final String v in value) Text(v)]),
        ),
      );

  group('the query box is named, and refuses to be nameless', () {
    testWidgets('the name reaches the semantic tree', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final TextEditingController controller = TextEditingController();
      addTearDown(controller.dispose);

      await host(
        tester,
        IuxSearchField(
          label: _kSearchLabel,
          clearLabel: _kClearLabel,
          controller: controller,
          onChanged: (String _) {},
        ),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel(_kSearchLabel)),
        isSemantics(label: _kSearchLabel, isTextField: true),
      );
      handle.dispose();
    });

    test('a box with no name is refused', () {
      expect(
        () => IuxSearchField(
          label: '',
          clearLabel: _kClearLabel,
          controller: TextEditingController(),
          onChanged: (String _) {},
        ),
        throwsAssertionError,
      );
    });

    test('a clear control with no name is refused', () {
      expect(
        () => IuxSearchField(
          label: _kSearchLabel,
          clearLabel: '',
          controller: TextEditingController(),
          onChanged: (String _) {},
        ),
        throwsAssertionError,
      );
    });

    testWidgets('the hint is read after the name', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final TextEditingController controller = TextEditingController();
      addTearDown(controller.dispose);

      await host(
        tester,
        IuxSearchField(
          label: _kSearchLabel,
          clearLabel: _kClearLabel,
          hint: _kHint,
          controller: controller,
          onChanged: (String _) {},
        ),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel(_kSearchLabel)),
        isSemantics(label: _kSearchLabel, hint: _kHint),
      );
      handle.dispose();
    });

    testWidgets('the placeholder is shown and never announced', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final TextEditingController controller = TextEditingController();
      addTearDown(controller.dispose);

      await host(
        tester,
        IuxSearchField(
          label: _kSearchLabel,
          clearLabel: _kClearLabel,
          placeholder: _kPlaceholder,
          controller: controller,
          onChanged: (String _) {},
        ),
      );

      // On screen while the box is empty, and hidden from assistive
      // technology: repeating it would make every empty box announce two
      // names.
      expect(find.text(_kPlaceholder), findsOneWidget);
      expect(find.bySemanticsLabel(_kPlaceholder), findsNothing);
      handle.dispose();
    });

    testWidgets('autofocus puts the caret in the box', (
      WidgetTester tester,
    ) async {
      final TextEditingController controller = TextEditingController();
      addTearDown(controller.dispose);

      await host(
        tester,
        IuxSearchField(
          label: _kSearchLabel,
          clearLabel: _kClearLabel,
          controller: controller,
          onChanged: (String _) {},
          autofocus: true,
        ),
      );

      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
    });

    test('an empty hint and an empty placeholder are refused', () {
      expect(
        () => IuxSearchField(
          label: _kSearchLabel,
          clearLabel: _kClearLabel,
          hint: '',
          controller: TextEditingController(),
          onChanged: (String _) {},
        ),
        throwsAssertionError,
      );
      expect(
        () => IuxSearchField(
          label: _kSearchLabel,
          clearLabel: _kClearLabel,
          placeholder: '',
          controller: TextEditingController(),
          onChanged: (String _) {},
        ),
        throwsAssertionError,
      );
    });
  });

  group('the clear control', () {
    /// A field wired to a controller the test can drive.
    Future<TextEditingController> field(
      WidgetTester tester, {
      String text = '',
      List<String>? changes,
      TextDirection direction = TextDirection.ltr,
      double textScale = 1,
    }) async {
      final TextEditingController controller =
          TextEditingController(text: text);
      addTearDown(controller.dispose);
      await host(
        tester,
        IuxSearchField(
          label: _kSearchLabel,
          clearLabel: _kClearLabel,
          controller: controller,
          onChanged: (String value) => changes?.add(value),
        ),
        direction: direction,
        textScale: textScale,
      );
      return controller;
    }

    testWidgets('it is not offered while there is nothing to clear', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await field(tester);

      // Present in the widget tree — the slot is reserved — and absent from
      // the interface, which is the whole point of reserving it.
      expect(find.byType(IuxIconButton), findsOneWidget);
      expect(find.bySemanticsLabel(_kClearLabel), findsNothing);
      handle.dispose();
    });

    testWidgets('while hidden it does not respond to a tap either', (
      WidgetTester tester,
    ) async {
      final List<String> changes = <String>[];
      await field(tester, changes: changes);

      await tester.tap(find.byType(IuxIconButton), warnIfMissed: false);
      await tester.pump();

      // The slot is reserved, so the control occupies real pixels while the
      // box is empty. Nothing may happen when they are touched: a control that
      // is announced to nobody and does nothing is still a control the user
      // can hit by accident.
      expect(changes, isEmpty);
    });

    testWidgets('it returns focus to an externally owned node', (
      WidgetTester tester,
    ) async {
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      final TextEditingController controller =
          TextEditingController(text: 'trainers');
      addTearDown(controller.dispose);

      await host(
        tester,
        IuxSearchField(
          label: _kSearchLabel,
          clearLabel: _kClearLabel,
          controller: controller,
          onChanged: (String _) {},
          focusNode: node,
        ),
      );

      await tester.tap(find.byType(IuxIconButton));
      await tester.pump();

      // The caller's node, not a private one: something outside may need to
      // put the caret here later, and it has to be the same node.
      expect(node.hasFocus, isTrue);
    });

    testWidgets('it appears once there is something to clear', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final TextEditingController controller = await field(tester);

      controller.text = 'trainers';
      await tester.pump();

      expect(
        tester.getSemantics(find.bySemanticsLabel(_kClearLabel)),
        isSemantics(label: _kClearLabel, isButton: true, isEnabled: true),
      );
      handle.dispose();
    });

    testWidgets('the box does not resize on the first character', (
      WidgetTester tester,
    ) async {
      final TextEditingController controller = await field(tester);
      final Size empty = tester.getSize(find.byType(IuxTextField));

      controller.text = 't';
      await tester.pump();

      // The reserved slot is what buys this. Without it the control appearing
      // would take its width out of the box, moving the caret under the
      // user's finger on the keystroke that starts the query.
      expect(tester.getSize(find.byType(IuxTextField)), equals(empty));
    });

    testWidgets('it clears the box and reports the empty query once', (
      WidgetTester tester,
    ) async {
      final List<String> changes = <String>[];
      final TextEditingController controller =
          await field(tester, text: 'trainers', changes: changes);

      await tester.tap(find.byType(IuxIconButton));
      await tester.pump();

      expect(controller.text, isEmpty);
      expect(changes, equals(<String>['']));
    });

    testWidgets('it returns focus to the box', (WidgetTester tester) async {
      await field(tester, text: 'trainers');

      // Focus starts nowhere: the box does not autofocus by default.
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isFalse,
      );

      await tester.tap(find.byType(IuxIconButton));
      await tester.pump();

      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
    });

    testWidgets('it meets the touch target floor', (
      WidgetTester tester,
    ) async {
      await field(tester, text: 'trainers');
      final Size size = tester.getSize(find.byType(IuxIconButton));

      expect(size.width, greaterThanOrEqualTo(IuxTouchTarget.minimum));
      expect(size.height, greaterThanOrEqualTo(IuxTouchTarget.minimum));
    });

    testWidgets('it keeps the minimum spacing from the box', (
      WidgetTester tester,
    ) async {
      await field(tester, text: 'trainers');

      final Rect box = tester.getRect(find.byType(IuxTextField));
      final Rect clear = tester.getRect(find.byType(IuxIconButton));

      // Two adjacent targets touching each other still produce mis-taps: a
      // finger landing near the seam has no margin. SC 2.5.8 allows smaller
      // targets when spacing compensates; IUX keeps both.
      expect(
        clear.left - box.right,
        greaterThanOrEqualTo(kIuxMinimumTargetSpacing),
      );
    });

    testWidgets('measured: the row it actually renders', (
      WidgetTester tester,
    ) async {
      await field(tester, text: 'trainers');

      final Rect box = tester.getRect(find.byType(IuxTextField));
      final Rect clear = tester.getRect(find.byType(IuxIconButton));

      // The numbers quoted in docs/patterns/search.md, pinned so they cannot
      // drift into fiction: at the standard profile the control renders 56x56
      // against a 48 floor, the gap is exactly the target-spacing floor, and
      // bottom-aligning the row puts the control level with the box it empties
      // rather than half the name's height below it.
      expect(clear.size, equals(const Size(56, 56)));
      expect(clear.left - box.right, equals(kIuxMinimumTargetSpacing));
      expect(clear.bottom - box.bottom, equals(0));
    });

    testWidgets('measured: it grows with the comfortable target preference', (
      WidgetTester tester,
    ) async {
      final TextEditingController controller =
          TextEditingController(text: 'trainers');
      addTearDown(controller.dispose);
      await host(
        tester,
        IuxSearchField(
          label: _kSearchLabel,
          clearLabel: _kClearLabel,
          controller: controller,
          onChanged: (String _) {},
        ),
        configuration: const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile.comfortable(),
        ),
      );

      // 64x64 against a 56 floor. The control is IuxIconButton's, so the
      // preference reaches it without this pattern knowing the preference
      // exists.
      final Size size = tester.getSize(find.byType(IuxIconButton));
      expect(size.width, greaterThanOrEqualTo(IuxTouchTarget.comfortable));
      expect(size.height, greaterThanOrEqualTo(IuxTouchTarget.comfortable));
    });

    testWidgets('it sits on the leading side under RTL', (
      WidgetTester tester,
    ) async {
      await field(tester, text: 'trainers', direction: TextDirection.rtl);

      final Rect box = tester.getRect(find.byType(IuxTextField));
      final Rect clear = tester.getRect(find.byType(IuxIconButton));

      expect(clear.right, lessThanOrEqualTo(box.left));
    });

    testWidgets('it survives 200% text without overflowing', (
      WidgetTester tester,
    ) async {
      await field(tester, text: 'trainers', textScale: 2);

      expect(tester.takeException(), isNull);
      expect(find.byType(IuxIconButton), findsOneWidget);
    });
  });

  group('a search is a load, not a second state machine', () {
    testWidgets('running shows the wait and says what is being searched', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(tester, region(const IuxLoadState<List<String>>.loading()));

      expect(find.text(_kSearchingLabel), findsOneWidget);
      expect(liveRegions(tester), equals(<String>[_kSearchingLabel]));
      handle.dispose();
    });

    testWidgets('answered with rows shows the rows and their count', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(
        tester,
        region(const IuxLoadState<List<String>>.ready(<String>['a', 'b'])),
      );

      expect(find.text('a'), findsOneWidget);
      expect(find.text('b'), findsOneWidget);
      expect(find.text('2 orders'), findsOneWidget);
      expect(find.text(_kSearchingLabel), findsNothing);
      handle.dispose();
    });

    testWidgets('answered with nothing names the situation and the way back', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(
        tester,
        region(const IuxLoadState<List<String>>.ready(<String>[])),
      );

      expect(find.byType(IuxEmptyState), findsOneWidget);
      expect(find.text(_kNothingMatches), findsOneWidget);
      // IuxNoMatches requires the way back, so a dead end is unconstructible
      // rather than reviewed for.
      expect(find.text(_kResetLabel), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the guidance is shown beside the way back', (
      WidgetTester tester,
    ) async {
      await host(
        tester,
        region(
          const IuxLoadState<List<String>>.ready(<String>[]),
          guidance: _kGuidance,
        ),
      );

      expect(find.text(_kNothingMatches), findsOneWidget);
      expect(find.text(_kGuidance), findsOneWidget);
    });

    testWidgets('the reset is the caller\'s callback and nothing else runs', (
      WidgetTester tester,
    ) async {
      int resets = 0;
      await host(
        tester,
        region(
          const IuxLoadState<List<String>>.ready(<String>[]),
          reset: _reset(onActivate: () => resets++),
        ),
      );

      await tester.tap(find.text(_kResetLabel));
      await tester.pump();

      expect(resets, equals(1));
    });

    testWidgets('broken shows the message and the way out', (
      WidgetTester tester,
    ) async {
      await host(
        tester,
        region(
          const IuxLoadState<List<String>>.failed(message: _kFailureMessage),
        ),
      );

      expect(find.text(_kFailureMessage), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      // The category is announced rather than painted — IuxErrorRecovery
      // carries it in the spoken text and gives the eye a glyph instead. This
      // pattern passes it through and adds nothing, which is checked by the
      // announcement test below rather than restated here.
      expect(find.text(_kCategoryLabel), findsNothing);
    });

    testWidgets('exactly one branch is on screen in every state', (
      WidgetTester tester,
    ) async {
      for (final IuxLoadState<List<String>> state
          in <IuxLoadState<List<String>>>[
        const IuxLoadState<List<String>>.loading(),
        const IuxLoadState<List<String>>.ready(<String>['a']),
        const IuxLoadState<List<String>>.ready(<String>[]),
        const IuxLoadState<List<String>>.failed(message: _kFailureMessage),
      ]) {
        await host(tester, region(state));

        final int branches = <bool>[
          find.text(_kSearchingLabel).evaluate().isNotEmpty,
          find.text('a').evaluate().isNotEmpty,
          find.byType(IuxEmptyState).evaluate().isNotEmpty,
          find.text(_kFailureMessage).evaluate().isNotEmpty,
        ].where((bool shown) => shown).length;

        expect(branches, equals(1), reason: 'state $state showed $branches');
      }
    });
  });

  group('exactly one thing is announced per settled search', () {
    testWidgets('the count is a live region carrying the caller\'s words', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(
        tester,
        region(const IuxLoadState<List<String>>.ready(<String>['a', 'b'])),
      );

      expect(liveRegions(tester), equals(<String>['2 orders']));
      handle.dispose();
    });

    testWidgets('the visible count is not read a second time', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(
        tester,
        region(const IuxLoadState<List<String>>.ready(<String>['a', 'b'])),
      );

      // One node carries the words. The painted line repeats them verbatim and
      // is excluded, so the user hears the count once rather than twice.
      expect(
        find.bySemanticsLabel('2 orders').evaluate().length,
        equals(1),
      );
      handle.dispose();
    });

    testWidgets('nothing matching announces once, not twice', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(
        tester,
        region(const IuxLoadState<List<String>>.ready(<String>[])),
      );

      // The empty state's own live region is the announcement for this branch.
      // A status line above it would say the same sentence twice, once as a
      // status and once as a heading.
      expect(liveRegions(tester), equals(<String>[_kNothingMatches]));
      handle.dispose();
    });

    testWidgets('the failure announces once, and it is not the count', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(
        tester,
        region(
          const IuxLoadState<List<String>>.failed(message: _kFailureMessage),
        ),
      );

      expect(
        liveRegions(tester),
        equals(<String>['$_kCategoryLabel. $_kFailureMessage']),
      );
      handle.dispose();
    });

    testWidgets('a summary that says nothing is refused', (
      WidgetTester tester,
    ) async {
      await host(
        tester,
        region(
          const IuxLoadState<List<String>>.ready(<String>['a']),
          summary: (BuildContext context, List<String> results) => '',
        ),
      );

      expect(tester.takeException(), isAssertionError);
    });

    testWidgets(
      'measured: a query per keystroke is one interruption per keystroke',
      (WidgetTester tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        IuxLoadState<List<String>> state =
            const IuxLoadState<List<String>>.ready(<String>[]);
        late StateSetter setState;

        await host(
          tester,
          StatefulBuilder(
            builder: (BuildContext context, StateSetter set) {
              setState = set;
              return region(state);
            },
          ),
        );

        // Five characters typed, no pause waited for: the caller runs a query
        // per keystroke, so the region enters the wait and settles five times.
        final List<String> heard = <String>[];
        for (int keystroke = 1; keystroke <= 5; keystroke++) {
          setState(() => state = const IuxLoadState<List<String>>.loading());
          await tester.pump();
          heard.addAll(liveRegions(tester));
          setState(
            () => state = IuxLoadState<List<String>>.ready(
              List<String>.filled(keystroke, 'row'),
            ),
          );
          await tester.pump();
          heard.addAll(liveRegions(tester));
        }

        // Ten announcements for a five-character word, five of them identical.
        // This is the measurement behind "debounce is the caller's, and it is
        // not optional" — nobody can type through it.
        expect(heard.length, equals(10));
        expect(
          heard.where((String label) => label == _kSearchingLabel).length,
          equals(5),
        );
        expect(heard.last, equals('5 orders'));
        handle.dispose();
      },
    );
  });

  group('there is no suggestion list, and this is why', () {
    testWidgets('SemanticsRole.comboBox is unusable in this Flutter version', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Semantics(
            container: true,
            role: SemanticsRole.comboBox,
            label: _kSearchLabel,
            child: const SizedBox(width: 10, height: 10),
          ),
        ),
      );

      // Flutter 3.44.8 declares the role and routes it to `_unimplemented` in
      // its own debug role checks, which throws the moment the node reaches a
      // semantics update. The role cannot be used at all — it is not merely
      // that it announces nothing. Pinned here so the day it is implemented is
      // visible, and so the decision to ship no suggestions is evidence rather
      // than an opinion.
      expect(
        tester.takeException(),
        isA<FlutterError>().having(
          (FlutterError error) => error.message,
          'message',
          contains('Missing checks for role SemanticsRole.comboBox'),
        ),
      );
      handle.dispose();
    });
  });

  group('motion, scaling and long text', () {
    testWidgets(
        'no motion replaces the bar with the label rather than '
        'freezing it', (WidgetTester tester) async {
      await host(
        tester,
        region(const IuxLoadState<List<String>>.loading()),
        configuration: _withMotion(IuxMotionPreference.none),
      );

      // Removing an animation must never remove the information it carried.
      expect(find.text(_kSearchingLabel), findsOneWidget);
    });

    testWidgets('a long count wraps rather than clipping', (
      WidgetTester tester,
    ) async {
      await host(
        tester,
        region(
          const IuxLoadState<List<String>>.ready(<String>['a']),
          summary: (BuildContext context, List<String> results) =>
              _kLongSummary,
        ),
      );

      expect(tester.takeException(), isNull);
      final Size line = tester.getSize(find.text(_kLongSummary));
      // Several lines tall, and the whole sentence is laid out: it wrapped
      // instead of being cut off with an ellipsis.
      expect(line.height, greaterThan(40));
      expect(find.text(_kLongSummary), findsOneWidget);
    });

    testWidgets('the region survives 200% text', (WidgetTester tester) async {
      await host(
        tester,
        region(const IuxLoadState<List<String>>.ready(<String>['a'])),
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('1 orders'), findsOneWidget);
    });

    testWidgets('the region renders under RTL', (WidgetTester tester) async {
      await host(
        tester,
        region(const IuxLoadState<List<String>>.ready(<String>['a'])),
        direction: TextDirection.rtl,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('1 orders'), findsOneWidget);
    });

    testWidgets('the region renders under high contrast', (
      WidgetTester tester,
    ) async {
      await host(
        tester,
        region(const IuxLoadState<List<String>>.ready(<String>['a'])),
        configuration: const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(contrast: IuxContrast.high),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('1 orders'), findsOneWidget);
    });
  });

  group('the pattern refuses what it cannot present', () {
    test('empty guidance is refused rather than ignored', () {
      expect(
        () => IuxSearchResults<String>(
          results: const IuxLoadState<List<String>>.ready(<String>[]),
          summary: _summary,
          searchingLabel: _kSearchingLabel,
          failureCategoryLabel: _kCategoryLabel,
          recovery: IuxRetryRoute(label: 'Try again', onRetry: () {}),
          reset: _reset(),
          noMatchesGuidance: '',
          builder: (BuildContext context, List<String> value) =>
              const SizedBox.shrink(),
        ),
        throwsAssertionError,
      );
    });

    test('a reset that asks to be confirmed is refused by the empty state', () {
      // Inherited from IuxEmptyStateAction rather than restated: a second
      // vocabulary for the same refusal is a second place for it to drift.
      expect(
        () => IuxEmptyStateAction(
          label: _kResetLabel,
          action: const IuxActionDescriptor(
            semantics: IuxActionSemantics(label: _kResetLabel),
            confirmation: IuxConfirmBeforeExecution(),
          ),
          onActivate: () {},
        ),
        throwsAssertionError,
      );
    });
  });
}
