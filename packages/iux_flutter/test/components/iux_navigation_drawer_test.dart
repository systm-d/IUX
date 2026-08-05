// `CheckedState` lives in dart:ui and is not re-exported: the three-valued
// answer ("checked", "not checked", "no such state") is the whole point of the
// assertions below, so it is imported rather than approximated with a bool.
import 'dart:ui' show CheckedState;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

import '../support/contrast.dart';

/// The mutable state the host page and the assertions share.
///
/// The parent owns whether the drawer is open and which section the user is in,
/// which is the whole point of the component: the test plays the parent so the
/// assertions can check that the drawer never takes either decision for itself.
class _Scenario {
  bool open = false;
  int section = 1;
  int dismissals = 0;
  final List<int> chosen = <int>[];
  int pageTaps = 0;
  final FocusNode background = FocusNode(debugLabel: 'background');
  final FocusNode elsewhere = FocusNode(debugLabel: 'elsewhere');
  late StateSetter setHostState;

  void setOpen(bool value) => setHostState(() => open = value);
}

void main() {
  const String title = 'Main navigation';
  const String longLabel =
      'Invoices awaiting approval from the finance team this quarter';

  const IuxNavigationDestination home =
      IuxNavigationDestination(label: 'Home', icon: Icons.home_outlined);
  const IuxNavigationDestination orders = IuxNavigationDestination(
    label: 'Orders',
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long,
    badge: IuxBadge.count(count: '3', label: '3 orders awaiting approval'),
  );
  const IuxNavigationDestination settings = IuxNavigationDestination(
      label: 'Settings', icon: Icons.settings_outlined);

  const List<IuxNavigationDestination> threeSections =
      <IuxNavigationDestination>[home, orders, settings];

  /// Builds the host page with the drawer over it.
  ///
  /// [placement] chooses how. All three shapes a caller can write are
  /// available as a parameter rather than described in a comment, because the
  /// differences between them are the subject of the IUX-OVERLAY-001 group and
  /// have to be measured rather than asserted in prose.
  Future<_Scenario> pump(
    WidgetTester tester, {
    bool open = false,
    int section = 1,
    List<IuxNavigationDestination> destinations = threeSections,
    IuxThemeConfiguration configuration = const IuxThemeConfiguration(),
    TextDirection direction = TextDirection.ltr,
    double textScale = 1,
    Size size = const Size(400, 800),
    String dismissLabel = 'Close',
    String drawerTitle = title,
    _Placement placement = _Placement.layer,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final _Scenario scenario = _Scenario()
      ..open = open
      ..section = section;
    addTearDown(scenario.background.dispose);
    addTearDown(scenario.elsewhere.dispose);

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
              body: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  scenario.setHostState = setState;

                  final Widget page = IuxPage(
                    child: Column(
                      children: <Widget>[
                        IuxButton(
                          label: 'Open',
                          action: const IuxActionDescriptor(
                            semantics: IuxActionSemantics(label: 'Open'),
                          ),
                          focusNode: scenario.background,
                          onActivate: () => scenario.pageTaps++,
                        ),
                        IuxButton(
                          label: 'Elsewhere',
                          action: const IuxActionDescriptor(
                            semantics: IuxActionSemantics(label: 'Elsewhere'),
                          ),
                          focusNode: scenario.elsewhere,
                          onActivate: () {},
                        ),
                        // Carries no interface of its own. It is here only so
                        // the page's lifetime can be measured, which is what
                        // IUX-OVERLAY-001 is about.
                        const _PageProbe(),
                      ],
                    ),
                  );

                  final IuxNavigationDrawer drawer = IuxNavigationDrawer(
                    title: drawerTitle,
                    dismissLabel: dismissLabel,
                    onDismiss: () => scenario.dismissals++,
                    destinations: destinations,
                    selectedIndex: scenario.section,
                    onDestinationSelected: scenario.chosen.add,
                  );

                  switch (placement) {
                    case _Placement.layer:
                      return IuxModalLayer(
                        drawer: scenario.open ? drawer : null,
                        child: page,
                      );
                    case _Placement.permanentStack:
                      return Stack(
                        fit: StackFit.expand,
                        children: <Widget>[page, if (scenario.open) drawer],
                      );
                    case _Placement.conditionalTree:
                      if (!scenario.open) return page;
                      return Stack(
                        fit: StackFit.expand,
                        children: <Widget>[page, drawer],
                      );
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return scenario;
  }

  /// Whether whatever holds focus right now is inside the drawer.
  bool focusIsInsideDrawer() {
    final BuildContext? focused = FocusManager.instance.primaryFocus?.context;
    if (focused == null) return false;
    return focused.findAncestorWidgetOfExactType<IuxNavigationDrawer>() != null;
  }

  /// Every label the compiled semantic tree currently exposes.
  ///
  /// Read from the tree assistive technology actually sees rather than through
  /// `find.bySemanticsLabel`, which reads each render object's *last* semantics
  /// node: a subtree that has been blocked keeps holding its node, so the
  /// finder reports content a screen reader can no longer reach. The same
  /// helper, and the same reason, as `iux_bottom_sheet_test.dart`.
  ///
  /// The distinction became load-bearing when IUX-OVERLAY-001 was fixed: the
  /// page's element now survives the drawer opening, so its stale node
  /// survives with it and the finder answers the wrong question.
  List<String> announcedLabels(WidgetTester tester) {
    final List<String> labels = <String>[];
    void visit(SemanticsNode node) {
      if (node.label.isNotEmpty) labels.add(node.label);
      node.visitChildren((SemanticsNode child) {
        visit(child);
        return true;
      });
    }

    visit(tester.getSemantics(find.byType(MaterialApp)));
    return labels;
  }

  /// The nearest ancestor semantics node of [finder] that scopes a route.
  SemanticsNode routeNodeAbove(WidgetTester tester, Finder finder) {
    SemanticsNode? node = tester.getSemantics(finder);
    while (node != null && !node.flagsCollection.scopesRoute) {
      node = node.parent;
    }
    return node!;
  }

  /// Every node under [root] a screen-reader swipe actually lands on.
  ///
  /// Leaves only, in order. A node merged into an ancestor is not a stop of its
  /// own — that is what `MergeSemantics` is for — and a node with children is a
  /// container that supplies context rather than a place to land, which is why
  /// the route and the mutually exclusive set do not appear here. Both are
  /// asserted on their own, above.
  List<SemanticsData> spokenStopsUnder(SemanticsNode root) {
    final List<SemanticsData> stops = <SemanticsData>[];
    void visit(SemanticsNode node) {
      final List<SemanticsNode> children = <SemanticsNode>[];
      node.visitChildren((SemanticsNode child) {
        if (!child.isMergedIntoParent) children.add(child);
        return true;
      });
      if (children.isEmpty) {
        final SemanticsData data = node.getSemanticsData();
        if (data.label.isNotEmpty) stops.add(data);
        return;
      }
      children.forEach(visit);
    }

    visit(root);
    return stops;
  }

  /// The tokens the drawer itself resolves, read from a real tree.
  IuxNavigationDrawerTokens tokensOf(
    WidgetTester tester, {
    bool current = false,
    bool pressed = false,
    bool hovered = false,
  }) {
    final BuildContext context = tester.element(find.byType(IuxSurface).first);
    return IuxNavigationDrawerResolver.resolve(
      context,
      current: current,
      pressed: pressed,
      hovered: hovered,
    );
  }

  group('a drawer that cannot work is refused at construction', () {
    test('an unnamed drawer announces nothing when it appears', () {
      expect(
        () => IuxNavigationDrawer(
          title: '',
          dismissLabel: 'Close',
          onDismiss: () {},
          destinations: threeSections,
          selectedIndex: 0,
          onDestinationSelected: (int _) {},
        ),
        throwsAssertionError,
      );
    });

    test('an unlabelled way out is a trap', () {
      expect(
        () => IuxNavigationDrawer(
          title: title,
          dismissLabel: '',
          onDismiss: () {},
          destinations: threeSections,
          selectedIndex: 0,
          onDestinationSelected: (int _) {},
        ),
        throwsAssertionError,
      );
    });

    test('a drawer with no destinations interrupts for nothing', () {
      expect(
        () => IuxNavigationDrawer(
          title: title,
          dismissLabel: 'Close',
          onDismiss: () {},
          destinations: const <IuxNavigationDestination>[],
          selectedIndex: 0,
          onDestinationSelected: (int _) {},
        ),
        throwsAssertionError,
      );
    });

    test('a current destination outside the list would mark none of them', () {
      for (final int index in <int>[-1, 3, 99]) {
        expect(
          () => IuxNavigationDrawer(
            title: title,
            dismissLabel: 'Close',
            onDismiss: () {},
            destinations: threeSections,
            selectedIndex: index,
            onDestinationSelected: (int _) {},
          ),
          throwsAssertionError,
          reason: 'selectedIndex $index was accepted',
        );
      }
    });

    test('two destinations with one name are a choice nobody can make', () {
      expect(
        () => IuxNavigationDrawer(
          title: title,
          dismissLabel: 'Close',
          onDismiss: () {},
          destinations: const <IuxNavigationDestination>[
            home,
            IuxNavigationDestination(label: 'Home', icon: Icons.house_outlined),
          ],
          selectedIndex: 0,
          onDestinationSelected: (int _) {},
        ),
        throwsAssertionError,
      );
    });

    test('one destination is enough; a drawer is not a bar', () {
      expect(
        () => IuxNavigationDrawer(
          title: title,
          dismissLabel: 'Close',
          onDismiss: () {},
          destinations: const <IuxNavigationDestination>[home],
          selectedIndex: 0,
          onDestinationSelected: (int _) {},
        ),
        returnsNormally,
      );
    });
  });

  group('the parent owns where the user is, and whether the drawer is open',
      () {
    testWidgets('choosing a destination reports its index and nothing else',
        (WidgetTester tester) async {
      final _Scenario scenario = await pump(tester, open: true);

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(scenario.chosen, <int>[2]);
      expect(scenario.dismissals, 0);
    });

    testWidgets('the drawer does not close itself when a destination is taken',
        (WidgetTester tester) async {
      // A drawer that closed itself would leave the parent's flag saying it was
      // still open, and the next frame would put it back.
      final _Scenario scenario = await pump(tester, open: true);

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      expect(scenario.chosen, <int>[0]);
      expect(find.byType(IuxNavigationDrawer), findsOneWidget);
    });

    testWidgets('choosing the current destination is still reported',
        (WidgetTester tester) async {
      // From a drawer it usually means "close this and leave me where I am",
      // and only the parent knows that.
      final _Scenario scenario = await pump(tester, open: true, section: 1);

      await tester.tap(find.text('Orders'));
      await tester.pumpAndSettle();

      expect(scenario.chosen, <int>[1]);
    });

    testWidgets('the page it covers stays behind it',
        (WidgetTester tester) async {
      await pump(tester, open: true);
      expect(find.byType(IuxPage), findsOneWidget);
    });

    testWidgets('the current destination is rendered, never decided',
        (WidgetTester tester) async {
      final _Scenario scenario = await pump(tester, open: true, section: 0);
      expect(
        tester
            .getSemantics(find.text('Home'))
            .getSemanticsData()
            .flagsCollection
            .isChecked,
        CheckedState.isTrue,
      );

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(
        tester
            .getSemantics(find.text('Home'))
            .getSemanticsData()
            .flagsCollection
            .isChecked,
        CheckedState.isTrue,
        reason: 'the drawer moved the mark itself; only the parent may',
      );

      scenario.setHostState(() => scenario.section = 2);
      await tester.pumpAndSettle();

      expect(
        tester
            .getSemantics(find.text('Settings'))
            .getSemanticsData()
            .flagsCollection
            .isChecked,
        CheckedState.isTrue,
      );
    });
  });

  group('there is always a way out, and they all mean the same thing', () {
    testWidgets('a tap on the scrim dismisses', (WidgetTester tester) async {
      final _Scenario scenario = await pump(tester, open: true);
      final Rect panel = tester.getRect(find.byType(IuxSurface));

      await tester.tapAt(Offset(panel.right + 40, panel.bottom - 20));
      await tester.pumpAndSettle();

      expect(scenario.dismissals, 1);
      expect(scenario.chosen, isEmpty);
    });

    testWidgets('Escape dismisses', (WidgetTester tester) async {
      final _Scenario scenario = await pump(tester, open: true);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(scenario.dismissals, 1);
      expect(scenario.chosen, isEmpty);
    });

    testWidgets('Escape still dismisses once focus has moved to a destination',
        (WidgetTester tester) async {
      // SC 2.1.2: a modal a keyboard user cannot leave is a trap, and it is a
      // trap from wherever they happen to be standing in it.
      final _Scenario scenario = await pump(tester, open: true);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(scenario.dismissals, 1);
    });

    testWidgets('the system back gesture dismisses without navigating',
        (WidgetTester tester) async {
      // The first thing an Android user tries. Nothing is pushed and nothing is
      // popped: the drawer declines the pop and reports the intent.
      final _Scenario scenario = await pump(tester, open: true);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(scenario.dismissals, 1);
      expect(find.byType(IuxPage), findsOneWidget);
      expect(find.byType(IuxNavigationDrawer), findsOneWidget);
    });

    testWidgets('the header button dismisses', (WidgetTester tester) async {
      final _Scenario scenario = await pump(tester, open: true);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(scenario.dismissals, 1);
    });

    testWidgets('a tap on the panel is not a dismissal',
        (WidgetTester tester) async {
      // Without an opaque panel the tap falls through to the scrim and closes
      // the drawer the user was reading.
      final _Scenario scenario = await pump(tester, open: true);
      final Rect panel = tester.getRect(find.byType(IuxSurface));

      await tester.tapAt(Offset(panel.width / 2, panel.bottom - 20));
      await tester.pumpAndSettle();

      expect(scenario.dismissals, 0);
    });

    testWidgets('the way out survives one destination and 200% text',
        (WidgetTester tester) async {
      final _Scenario scenario = await pump(
        tester,
        open: true,
        destinations: const <IuxNavigationDestination>[home],
        section: 0,
        textScale: 2,
        size: const Size(320, 480),
      );

      await tester.ensureVisible(find.text('Close'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(scenario.dismissals, 1);
    });
  });

  group('focus, which is what decides whether the drawer is usable at all', () {
    testWidgets('opening the drawer moves focus into it',
        (WidgetTester tester) async {
      final _Scenario scenario = await pump(tester);
      scenario.background.requestFocus();
      await tester.pump();
      expect(scenario.background.hasFocus, isTrue);

      scenario.setOpen(true);
      await tester.pumpAndSettle();

      expect(scenario.background.hasFocus, isFalse);
      expect(focusIsInsideDrawer(), isTrue);
    });

    testWidgets(
        'focus lands on the panel, not on a destination, so Enter cannot '
        'navigate somewhere unread', (WidgetTester tester) async {
      await pump(tester, open: true);

      final FocusNode focused = FocusManager.instance.primaryFocus!;
      expect(focused.debugLabel, 'IuxNavigationDrawer panel');
      expect(
        focused.context!.findAncestorWidgetOfExactType<IuxButton>(),
        isNull,
      );
    });

    testWidgets('the keyboard cannot leave the drawer',
        (WidgetTester tester) async {
      final _Scenario scenario = await pump(tester, open: true);

      for (int press = 1; press <= 12; press++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(
          scenario.background.hasFocus || scenario.elsewhere.hasFocus,
          isFalse,
          reason: 'focus reached the covered page after $press tabs',
        );
        expect(
          focusIsInsideDrawer(),
          isTrue,
          reason: 'focus left the drawer after $press tabs',
        );
      }
    });

    testWidgets('the way out is the first control the keyboard reaches',
        (WidgetTester tester) async {
      // A way out found only after twelve swipes is a way out most users never
      // find, and in a drawer the alternative is choosing a destination they
      // did not want.
      await pump(tester, open: true);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      final BuildContext focused = FocusManager.instance.primaryFocus!.context!;
      expect(
        focused.findAncestorWidgetOfExactType<IuxButton>()?.label,
        'Close',
      );
    });

    testWidgets('every destination is reachable by keyboard, in order',
        (WidgetTester tester) async {
      final _Scenario scenario = await pump(tester, open: true);

      final List<int> activated = <int>[];
      for (int press = 0; press < 4; press++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      // Four tabs: the way out, then the three destinations. The fourth stop is
      // the last destination, which Enter must be able to take.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      activated.addAll(scenario.chosen);

      expect(activated, <int>[2]);
    });

    testWidgets('closing the drawer returns focus to what held it before',
        (WidgetTester tester) async {
      final _Scenario scenario = await pump(tester);
      scenario.background.requestFocus();
      await tester.pump();

      scenario.setOpen(true);
      await tester.pumpAndSettle();
      expect(scenario.background.hasFocus, isFalse);

      scenario.setOpen(false);
      await tester.pumpAndSettle();

      expect(scenario.background.hasFocus, isTrue);
    });

    testWidgets(
        'focus returns to where the user was, not to wherever it drifted '
        'while the drawer was open', (WidgetTester tester) async {
      final _Scenario scenario = await pump(tester);
      scenario.background.requestFocus();
      await tester.pump();

      scenario.setOpen(true);
      await tester.pumpAndSettle();

      scenario.elsewhere.requestFocus();
      await tester.pump();

      scenario.setOpen(false);
      await tester.pumpAndSettle();

      expect(scenario.background.hasFocus, isTrue);
      expect(scenario.elsewhere.hasFocus, isFalse);
    });
  });

  group('the covered page is unreachable, by touch and by screen reader', () {
    testWidgets('a tap where the page is does not reach the page',
        (WidgetTester tester) async {
      final _Scenario scenario = await pump(tester, open: true);

      await tester.tap(find.text('Open'), warnIfMissed: false);
      await tester.tap(find.text('Elsewhere'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(scenario.pageTaps, 0);
    });

    testWidgets('the page leaves the semantic tree while the drawer is up',
        (WidgetTester tester) async {
      // A control that reads out but no longer responds is worse than one that
      // is gone.
      final _Scenario scenario = await pump(tester);
      expect(announcedLabels(tester), contains('Open'));

      scenario.setOpen(true);
      await tester.pumpAndSettle();

      expect(announcedLabels(tester), isNot(contains('Open')));
      expect(announcedLabels(tester), isNot(contains('Elsewhere')));
    });

    testWidgets('the page returns to the semantic tree when the drawer closes',
        (WidgetTester tester) async {
      final _Scenario scenario = await pump(tester, open: true);

      scenario.setOpen(false);
      await tester.pumpAndSettle();

      expect(announcedLabels(tester), contains('Open'));
    });

    testWidgets('IUX-027, withdrawn: every placement hides the covered page',
        (WidgetTester tester) async {
      // This test used to assert the opposite for the permanent stack, and
      // that reversal is the reason IUX-OVERLAY-001 stayed open for so long.
      //
      // IUX-027 concluded that `BlockSemantics` blocks a sibling only when its
      // semantics are recompiled, so a page whose element survives stays
      // readable — which made the page being destroyed look like the price of
      // the accessibility guarantee, and the guarantee outranks ergonomics.
      // The conclusion came from `find.bySemanticsLabel`, which reads
      // `RenderObject.debugSemantics`: a per-render-object cache that keeps
      // its last value for a subtree that stops being visited instead of being
      // dirtied.
      //
      // Both instruments are run below on the same trees. The finder half is
      // not a test of IUX; the day it starts finding nothing, Flutter has
      // tightened `debugSemantics` and it can go.
      for (final _Placement placement in _Placement.values) {
        final _Scenario scenario = await pump(tester, placement: placement);

        scenario.setOpen(true);
        await tester.pumpAndSettle();

        expect(
          announcedLabels(tester),
          isNot(contains('Open')),
          reason: 'the semantics tree the platform is given still holds the '
              'covered page under $placement',
        );
        expect(
          tester.semantics
              .simulatedAccessibilityTraversal()
              .map((SemanticsNode node) => node.label),
          isNot(contains('Open')),
          reason: 'a screen-reader swipe lands on the covered page under '
              '$placement',
        );
        expect(
          find.bySemanticsLabel('Open'),
          placement == _Placement.conditionalTree
              ? findsNothing
              : findsOneWidget,
          reason: 'the stale cache IUX-027 read is still stale wherever the '
              "page's element survives, and only there — which is exactly why "
              'the finding came out backwards',
        );
      }
    });

    testWidgets('IUX-OVERLAY-001: what the placements actually cost',
        (WidgetTester tester) async {
      // With the semantics claim withdrawn, the three placements differ in
      // exactly one thing: whether the page survives being covered. The shape
      // this component used to document — return the page, or return a Stack
      // holding it — is the only one that destroys it, because the page
      // changes depth in the element tree. Its `State` is disposed, so a list
      // is back at the top and any callback the page handed to the drawer
      // fires on a dead object.
      final Map<_Placement, int> disposals = <_Placement, int>{};
      for (final _Placement placement in _Placement.values) {
        final _Scenario scenario = await pump(tester, placement: placement);
        final int before = _PageProbe.disposals;

        scenario.setOpen(true);
        await tester.pumpAndSettle();

        disposals[placement] = _PageProbe.disposals - before;
      }

      expect(
        disposals,
        <_Placement, int>{
          _Placement.layer: 0,
          _Placement.permanentStack: 0,
          _Placement.conditionalTree: 1,
        },
        reason: 'IuxModalLayer must keep the page that opened the drawer, and '
            'the shape this component used to document must be shown to be '
            'the one that does not',
      );
    });
  });

  group('assistive technology is told what appeared and where the user is', () {
    testWidgets('it scopes and names a route', (WidgetTester tester) async {
      await pump(tester, open: true);

      final SemanticsNode route = routeNodeAbove(tester, find.text('Home'));

      expect(route.flagsCollection.namesRoute, isTrue);
      expect(
        route.label,
        contains(title),
        reason: 'the route is scoped but unnamed, so nothing is announced',
      );
    });

    testWidgets('the title is a heading, so it can be jumped to',
        (WidgetTester tester) async {
      await pump(tester, open: true);

      expect(
        tester.getSemantics(find.text(title)).flagsCollection.isHeader,
        isTrue,
      );
    });

    testWidgets('every destination announces its state, not only the current',
        (WidgetTester tester) async {
      // "Checked" is announced in both states, so a user hears "not checked" at
      // the destinations they are not in. `selected` is announced only when
      // true, which leaves them sweeping the list for the one that spoke.
      await pump(tester, open: true, section: 1);

      const Map<String, CheckedState> expected = <String, CheckedState>{
        'Home': CheckedState.isFalse,
        'Orders': CheckedState.isTrue,
        'Settings': CheckedState.isFalse,
      };
      expected.forEach((String label, CheckedState state) {
        final SemanticsData data =
            tester.getSemantics(find.text(label)).getSemanticsData();
        expect(data.flagsCollection.isChecked, state, reason: label);
        expect(
          data.flagsCollection.isInMutuallyExclusiveGroup,
          isTrue,
          reason: '$label is not announced as one option among several',
        );
      });
    });

    testWidgets('the destinations are named as one mutually exclusive set',
        (WidgetTester tester) async {
      await pump(tester, open: true);

      SemanticsNode? node = tester.getSemantics(find.text('Home')).parent;
      while (node != null && node.role != SemanticsRole.radioGroup) {
        node = node.parent;
      }

      expect(node, isNotNull, reason: 'the destinations are not a group');
      expect(node!.label, title);
    });

    testWidgets('a destination is one stop, and it reads name then badge',
        (WidgetTester tester) async {
      // `IuxSemantics.selection` would have excluded the subtree and deleted
      // the badge from the interface of every screen-reader user.
      await pump(tester, open: true);

      final SemanticsData orders =
          tester.getSemantics(find.text('Orders')).getSemanticsData();

      expect(orders.label, contains('Orders'));
      expect(orders.label, contains('3 orders awaiting approval'));
      expect(
        orders.label.indexOf('Orders'),
        lessThan(orders.label.indexOf('3 orders awaiting approval')),
        reason: 'the count is announced before the place it counts',
      );
      expect(find.bySemanticsLabel(RegExp('Orders')), findsOneWidget);
    });

    testWidgets('a destination offers something to activate',
        (WidgetTester tester) async {
      // A destination announced correctly that refuses a screen reader's
      // double-tap is a control that is visible, named and unusable.
      final _Scenario scenario = await pump(tester, open: true);

      final SemanticsData data =
          tester.getSemantics(find.text('Settings')).getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isTrue);

      // performAction is the closest a widget test gets to TalkBack's
      // double-tap: it invokes the action the platform would.
      // ignore: deprecated_member_use
      tester.binding.pipelineOwner.semanticsOwner!.performAction(
        tester.getSemantics(find.text('Settings')).id,
        SemanticsAction.tap,
      );
      await tester.pumpAndSettle();

      expect(scenario.chosen, <int>[2]);
    });

    testWidgets(
        'the drawer is exactly five stops: a heading, a way out, and one '
        'per destination', (WidgetTester tester) async {
      // The glyphs are not among them: the name beside each one already says
      // what the destination is, and a screen reader that announced both would
      // read every section twice.
      await pump(tester, open: true);

      final List<SemanticsData> stops =
          spokenStopsUnder(routeNodeAbove(tester, find.text('Home')));

      expect(
        stops.map((SemanticsData d) => d.label).toList(),
        <String>[
          title,
          'Close',
          'Home',
          'Orders\n3 orders awaiting approval',
          'Settings',
        ],
        reason: 'the drawer announces something it does not show, or shows '
            'something it does not announce',
      );
    });

    testWidgets('the scrim is not announced as a second, invisible way out',
        (WidgetTester tester) async {
      // A dismiss target reachable only by swiping is a control the user cannot
      // verify before activating; the header button says the same in words.
      await pump(tester, open: true);

      final List<SemanticsData> stops =
          spokenStopsUnder(routeNodeAbove(tester, find.text('Home')));

      expect(
        stops
            .where((SemanticsData d) => d.hasAction(SemanticsAction.tap))
            .map((SemanticsData d) => d.label)
            .toList(),
        <String>[
          'Close',
          'Home',
          'Orders\n3 orders awaiting approval',
          'Settings',
        ],
        reason: 'the way out, plus one per destination, and nothing else',
      );
    });
  });

  group('everything is reachable on a small screen with large text', () {
    testWidgets('the drawer scrolls at 200% text on a 320x480 screen',
        (WidgetTester tester) async {
      final _Scenario scenario = await pump(
        tester,
        open: true,
        textScale: 2,
        size: const Size(320, 480),
        destinations: const <IuxNavigationDestination>[
          home,
          orders,
          settings,
          IuxNavigationDestination(
              label: longLabel, icon: Icons.folder_outlined),
        ],
      );

      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.text(longLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(longLabel));
      await tester.pumpAndSettle();

      expect(scenario.chosen, <int>[3]);
    });

    testWidgets('a long destination name wraps rather than being clipped',
        (WidgetTester tester) async {
      await pump(
        tester,
        open: true,
        textScale: 2,
        size: const Size(320, 480),
        destinations: const <IuxNavigationDestination>[
          home,
          IuxNavigationDestination(
              label: longLabel, icon: Icons.folder_outlined),
        ],
      );

      final Text label = tester.widget<Text>(find.text(longLabel));
      expect(label.maxLines, isNull);
      expect(label.overflow, isNot(TextOverflow.ellipsis));
    });

    testWidgets('the heading is never truncated either',
        (WidgetTester tester) async {
      await pump(
        tester,
        open: true,
        textScale: 2,
        size: const Size(320, 480),
        drawerTitle: longLabel,
      );

      final Text heading = tester.widget<Text>(find.text(longLabel));
      expect(heading.maxLines, isNull);
      expect(heading.overflow, isNot(TextOverflow.ellipsis));
    });

    testWidgets('the panel always leaves a strip of the page showing',
        (WidgetTester tester) async {
      // The strip is not decoration: it is what tells the user the page is
      // still there, and it is the target they tap to get back to it.
      for (final Size size in <Size>[
        const Size(320, 480),
        const Size(400, 800),
        const Size(800, 600),
      ]) {
        for (final double scale in <double>[1, 2]) {
          await pump(tester, open: true, size: size, textScale: scale);
          final Size panel = tester.getSize(find.byType(IuxSurface));

          expect(
            panel.width,
            lessThanOrEqualTo(size.width * 0.8),
            reason: 'no page left at $size, scale $scale',
          );
          expect(panel.height, lessThanOrEqualTo(size.height));
          expect(tester.takeException(), isNull);
        }
      }
    });

    testWidgets('enlarging the text widens the panel rather than the column',
        (WidgetTester tester) async {
      // A drawer pinned at a pixel width clips exactly the names of the user
      // who enlarged them.
      await pump(tester, open: true, size: const Size(1280, 800));
      final double atOne = tester.getSize(find.byType(IuxSurface)).width;

      await pump(
        tester,
        open: true,
        size: const Size(1280, 800),
        textScale: 2,
      );
      final double atTwo = tester.getSize(find.byType(IuxSurface)).width;

      expect(atTwo, greaterThan(atOne));
    });

    testWidgets('every destination is at least a full touch target tall',
        (WidgetTester tester) async {
      await pump(tester, open: true);
      final double floor = tokensOf(tester).minExtent;

      for (final String label in <String>['Home', 'Orders', 'Settings']) {
        final Finder row = find
            .ancestor(of: find.text(label), matching: find.byType(IuxFocusable))
            .first;
        expect(
          tester.getSize(row).height,
          greaterThanOrEqualTo(floor),
          reason: '$label is smaller than a finger',
        );
      }
    });
  });

  group('the header holds whatever label the caller wrote', () {
    // IUX-DRAWER-LABEL-001, closed. `dismissLabel: 'Close the menu'` overflowed
    // the header by 9.5 px at 100% text on 360-, 800- and 1200-wide surfaces
    // and by 34 px on a 320-wide one — recorded elsewhere as 7.5 px, and both
    // numbers are historical — with the heading squeezed to a box zero pixels
    // wide, while `'Close'` did not, and *enlarging* the text to 150% repaired
    // it, because the arrangement was chosen from the text scale rather than
    // from the label.
    //
    // Re-measured on the current header: at 100% text with 'Close the menu',
    // the panel is 280 px wide on both an 800- and a 1200-wide surface, the
    // header stacks, the heading spans x 16–264 and the way out x 37–236.5.
    // Every child sits 16 px inside the panel edge; the overflow is 0 at all
    // sixteen combinations below.
    //
    // The assertion that carries this is 'never squeezes the heading below the
    // way out', not the absence of an overflow exception: the header is a
    // render object that clamps a starved heading to zero width rather than
    // painting past its box, so *no arrangement of it can raise an overflow*.
    // Forcing the pre-fix decision (never stack) leaves the exception test
    // green and the heading at 0.0 px wide, which is how the two were told
    // apart.
    //
    // The panel caps near the width the destination names need whatever the
    // screen is, so a wider screen does not help. Every case below is measured
    // in its own element tree: `DebugOverflowIndicatorMixin` reports an
    // overflow once per render-object lifetime, so a loop that kept the tree
    // would see the first case and be silent for the fifteen after it. The
    // `SizedBox.shrink()` between cases is what throws those render objects
    // away.
    const List<double> widths = <double>[320, 360, 800, 1200];
    const List<double> scales = <double>[1, 1.5, 2, 3];

    /// Runs [body] once per width and text scale, each in a fresh tree.
    Future<void> everywhere(
      WidgetTester tester,
      String dismissLabel,
      void Function(double width, double scale) body,
    ) async {
      for (final double width in widths) {
        for (final double scale in scales) {
          await pump(
            tester,
            open: true,
            size: Size(width, 800),
            textScale: scale,
            dismissLabel: dismissLabel,
          );
          body(width, scale);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        }
      }
    }

    for (final String label in <String>['Close', 'Close the menu']) {
      testWidgets('"$label" overflows nothing, at any width and text size',
          (WidgetTester tester) async {
        await everywhere(tester, label, (double width, double scale) {
          expect(
            tester.takeException(),
            isNull,
            reason: 'the header overflowed at $width wide, $scale text',
          );
        });
      });

      testWidgets('"$label" never squeezes the heading below the way out',
          (WidgetTester tester) async {
        // The measurement that mattered was not the exception. Before the fix
        // the heading was handed a box **zero pixels wide** at 100% text, and
        // an overflow assertion alone would have called 320 and 1200 the same
        // kind of healthy. The heading is what says which drawer this is.
        await everywhere(tester, label, (double width, double scale) {
          final double heading = tester.getSize(find.text(title)).width;
          final double wayOut = tester.getSize(find.text(label)).width;

          expect(heading, greaterThan(0),
              reason: 'the heading has no width at $width wide, $scale text');
          expect(
            heading,
            greaterThanOrEqualTo(wayOut),
            reason: 'the heading is narrower than the way out beside it at '
                '$width wide, $scale text',
          );
        });
      });
    }

    testWidgets('the arrangement follows the label, not the text scale',
        (WidgetTester tester) async {
      // The whole defect in one assertion. Both cases are 100% text on the
      // same 800-wide surface, so a decision taken from the text scale cannot
      // tell them apart — and it did not: the long label stayed on the shared
      // line and overflowed it.
      await pump(
        tester,
        open: true,
        size: const Size(800, 800),
        dismissLabel: 'Close the menu',
      );
      expect(
        tester.getRect(find.text('Close the menu')).top,
        greaterThan(tester.getRect(find.text(title)).bottom),
        reason: 'a label this long does not fit beside the heading, so it '
            'belongs below it',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      await pump(
        tester,
        open: true,
        size: const Size(800, 800),
        drawerTitle: 'Menu',
        dismissLabel: 'Close',
      );
      expect(
        tester.getRect(find.text('Close')).top,
        lessThan(tester.getRect(find.text('Menu')).bottom),
        reason: 'a short heading and a short label fit on one line, and a rule '
            'that always stacked would be no more measured than one that never '
            'did',
      );
    });

    testWidgets('a panel with room keeps the line the narrow one gave up',
        (WidgetTester tester) async {
      // Enlarging the text widens the panel, so at 150% on a wide screen there
      // is more room than at 100%, not less. The old rule read the scale and
      // stacked; this one measures and does not.
      await pump(
        tester,
        open: true,
        size: const Size(1200, 800),
        textScale: 1.5,
      );

      expect(
        tester.getRect(find.text('Close')).top,
        lessThan(tester.getRect(find.text(title)).bottom),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('it survives the conditions it will actually meet', () {
    testWidgets('the panel sits at the edge the reading direction starts at',
        (WidgetTester tester) async {
      await pump(tester, open: true);
      expect(tester.getRect(find.byType(IuxSurface)).left, 0);

      await pump(tester, open: true, direction: TextDirection.rtl);
      expect(tester.getRect(find.byType(IuxSurface)).right, 400);
    });

    testWidgets('it renders and dismisses right-to-left',
        (WidgetTester tester) async {
      final _Scenario scenario = await pump(
        tester,
        open: true,
        direction: TextDirection.rtl,
        dismissLabel: 'إغلاق',
        drawerTitle: 'التنقل الرئيسي',
      );

      expect(tester.takeException(), isNull);
      await tester.tap(find.text('إغلاق'));
      await tester.pumpAndSettle();
      expect(scenario.dismissals, 1);
    });

    testWidgets('it renders and dismisses on every theme profile',
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
        final _Scenario scenario =
            await pump(tester, open: true, configuration: configuration);

        expect(tester.takeException(), isNull);
        expect(find.text(title), findsOneWidget);

        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
        expect(scenario.dismissals, 1, reason: 'failed on $configuration');
      }
    });

    testWidgets('it works with no Navigator above it',
        (WidgetTester tester) async {
      // The `PopScope` registers against the enclosing route when there is one
      // and is inert when there is not. Asserted rather than assumed, because
      // "safe outside a Navigator" is a claim the documentation makes.
      int dismissals = 0;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Theme(
              data: IuxTheme.fromConfiguration(const IuxThemeConfiguration()),
              child: IuxNavigationDrawer(
                title: title,
                dismissLabel: 'Close',
                onDismiss: () => dismissals++,
                destinations: threeSections,
                selectedIndex: 0,
                onDestinationSelected: (int _) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(dismissals, 1);
    });

    testWidgets('the scrim never brightens what it covers',
        (WidgetTester tester) async {
      for (final Brightness brightness in Brightness.values) {
        await pump(
          tester,
          open: true,
          configuration: IuxThemeConfiguration(brightness: brightness),
        );

        final ColoredBox scrim = tester.widget<ColoredBox>(
          find
              .descendant(
                of: find.byType(IuxNavigationDrawer),
                matching: find.byType(ColoredBox),
              )
              .first,
        );
        final IuxSemanticColors colors = IuxTheme.resolve(
          IuxThemeConfiguration(brightness: brightness),
        ).colors;

        expect(
          scrim.color.computeLuminance(),
          lessThanOrEqualTo(colors.surface.base.computeLuminance()),
          reason: 'the scrim is lighter than the page in ${brightness.name}',
        );
      }
    });
  });

  group('the current destination is marked by more than colour', () {
    testWidgets('the indicator is a fill and an outline, both from the theme',
        (WidgetTester tester) async {
      // Surface contrast alone is deliberately gentle in IUX, so an indicator
      // that relied on it would disappear under a colour-vision difference —
      // which is precisely the user it exists for.
      await pump(tester, open: true);
      final IuxNavigationDrawerTokens tokens = tokensOf(tester, current: true);
      final IuxSemanticColors colors =
          IuxTheme.resolve(const IuxThemeConfiguration()).colors;

      expect(tokens.indicatorFill, colors.surface.selected);
      expect(tokens.indicatorBorder, colors.border.selected);
      expect(tokens.indicatorBorderWidth, greaterThan(0));
    });

    testWidgets('the outline is visible against the surface it sits on',
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
        await pump(tester, open: true, configuration: configuration);
        final IuxNavigationDrawerTokens tokens =
            tokensOf(tester, current: true);
        final IuxSemanticColors colors = IuxTheme.resolve(configuration).colors;

        expect(
          ContrastMetric.ratio(tokens.indicatorBorder, colors.surface.overlay),
          greaterThanOrEqualTo(ContrastMetric.nonText),
          reason: 'the mark for the current destination is invisible on '
              '$configuration',
        );
      }
    });

    testWidgets('a different glyph is a reinforcement, never the only signal',
        (WidgetTester tester) async {
      await pump(tester, open: true, section: 1);

      expect(find.byIcon(Icons.receipt_long), findsOneWidget);
      expect(find.byIcon(Icons.receipt_long_outlined), findsNothing);

      await pump(tester, open: true, section: 0);
      expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
    });

    testWidgets('the row keeps its height whichever destination is current',
        (WidgetTester tester) async {
      // A list that reflowed under the finger that caused it is a list the user
      // has to re-read.
      await pump(tester, open: true, section: 0);
      final double resting = tester
          .getSize(
            find
                .ancestor(
                  of: find.text('Settings'),
                  matching: find.byType(IuxFocusable),
                )
                .first,
          )
          .height;

      await pump(tester, open: true, section: 2);
      final double current = tester
          .getSize(
            find
                .ancestor(
                  of: find.text('Settings'),
                  matching: find.byType(IuxFocusable),
                )
                .first,
          )
          .height;

      expect(current, resting);
    });
  });

  group('motion explains the change and never carries it', () {
    Finder slides() => find.descendant(
          of: find.byType(IuxNavigationDrawer),
          matching: find.byType(SlideTransition),
        );

    FadeTransition fadeOf(WidgetTester tester) => tester.widget<FadeTransition>(
          find
              .descendant(
                of: find.byType(IuxNavigationDrawer),
                matching: find.byType(FadeTransition),
              )
              .first,
        );

    testWidgets('with motion off the drawer is there on the first frame',
        (WidgetTester tester) async {
      // A drawer invisible for one frame is a drawer that flickers for the user
      // who asked for no motion at all.
      final _Scenario scenario = await pump(
        tester,
        configuration: const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(motion: IuxMotionPreference.none),
        ),
      );

      scenario.setOpen(true);
      await tester.pump();

      expect(find.text(title), findsOneWidget);
      expect(fadeOf(tester).opacity.value, 1);
      expect(slides(), findsNothing);
    });

    testWidgets('a reduced preference removes the travel, not the drawer',
        (WidgetTester tester) async {
      // A fast sweep across most of the screen is worse for a vestibular
      // disorder than a slow one, so `reveal` becomes a fade rather than a
      // shorter journey.
      final _Scenario scenario = await pump(
        tester,
        configuration: const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(motion: IuxMotionPreference.reduced),
        ),
      );

      scenario.setOpen(true);
      await tester.pump();

      expect(slides(), findsNothing);
      expect(fadeOf(tester).opacity.value, lessThan(1));
      await tester.pumpAndSettle();
      expect(fadeOf(tester).opacity.value, 1);
      expect(find.text(title), findsOneWidget);
    });

    testWidgets('with motion allowed it travels in from the leading edge',
        (WidgetTester tester) async {
      final _Scenario scenario = await pump(tester);

      scenario.setOpen(true);
      await tester.pump();

      expect(slides(), findsOneWidget);
      expect(
        tester.widget<SlideTransition>(slides()).position.value,
        const Offset(-1, 0),
        reason: 'the panel did not start off the leading edge',
      );

      await tester.pumpAndSettle();
      expect(tester.getRect(find.byType(IuxSurface)).left, 0);
    });

    testWidgets('right-to-left it travels in from the other edge',
        (WidgetTester tester) async {
      final _Scenario scenario =
          await pump(tester, direction: TextDirection.rtl);

      scenario.setOpen(true);
      await tester.pump();

      expect(
        tester.widget<SlideTransition>(slides()).position.value,
        const Offset(1, 0),
      );
    });
  });

  group('the drawer resolves its appearance and holds no appearance itself',
      () {
    testWidgets('a destination reacts to press and to hover, and rests at zero',
        (WidgetTester tester) async {
      await pump(tester, open: true);

      expect(tokensOf(tester).overlayOpacity, 0);
      expect(tokensOf(tester, hovered: true).overlayOpacity, 1);
      expect(tokensOf(tester, pressed: true).overlayOpacity, 1);
    });

    testWidgets('a press wins over the hover it necessarily also is',
        (WidgetTester tester) async {
      // Reporting the weaker of the two would leave a press with no feedback.
      await pump(tester, open: true);
      final IuxSemanticColors colors =
          IuxTheme.resolve(const IuxThemeConfiguration()).colors;

      expect(
        tokensOf(tester, pressed: true, hovered: true).overlayColor,
        colors.state.pressed,
      );
      expect(
          tokensOf(tester, hovered: true).overlayColor, colors.state.hovered);
    });

    testWidgets('the current destination is not given a heavier label',
        (WidgetTester tester) async {
      // A heavier current label changes the text's measured width, so choosing
      // a destination would reflow the rows around it.
      await pump(tester, open: true);

      expect(
        tokensOf(tester, current: true).labelStyle.fontWeight,
        tokensOf(tester).labelStyle.fontWeight,
      );
      expect(
        tokensOf(tester, current: true).labelStyle.fontSize,
        tokensOf(tester).labelStyle.fontSize,
      );
    });

    testWidgets('the glyph is scaled once, through the runtime',
        (WidgetTester tester) async {
      // Letting Flutter scale it again would enlarge the glyph twice as fast as
      // the name beside it.
      await pump(tester, open: true, textScale: 2);

      final Icon glyph = tester.widget<Icon>(find.byIcon(Icons.home_outlined));
      expect(glyph.applyTextScaling, isFalse);
      expect(glyph.size, tokensOf(tester).iconSize);
      expect(glyph.size, greaterThan(24));
    });

    testWidgets('two resolutions of the same state are the same value',
        (WidgetTester tester) async {
      await pump(tester, open: true);

      expect(tokensOf(tester, current: true), tokensOf(tester, current: true));
      expect(
        tokensOf(tester, current: true).hashCode,
        tokensOf(tester, current: true).hashCode,
      );
      expect(tokensOf(tester, current: true), isNot(tokensOf(tester)));
    });
  });
}

/// A zero-size widget in the page whose `State` lifetime can be counted.
///
/// The page's own controls cannot answer "was the page destroyed" — they are
/// rebuilt either way and look identical afterwards. A `State` disposal is the
/// thing that distinguishes a page that survived from a page that was thrown
/// away and replaced, and it is what turns IUX-OVERLAY-001 from a lost scroll
/// position into a callback firing on a defunct object.
class _PageProbe extends StatefulWidget {
  const _PageProbe();

  /// Every disposal since the test file started. Read as a delta.
  static int disposals = 0;

  @override
  State<_PageProbe> createState() => _PageProbeState();
}

class _PageProbeState extends State<_PageProbe> {
  @override
  void dispose() {
    _PageProbe.disposals++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// The three ways a caller can put the drawer over a page.
///
/// Named rather than described, because the differences between them are
/// measured in the IUX-OVERLAY-001 group and a comment cannot be run.
enum _Placement {
  /// `IuxModalLayer(drawer: open ? drawer : null, child: page)` — what this
  /// component's documentation shows.
  layer,

  /// `Stack(children: [page, if (open) drawer])` — the shape IUX-027 reported
  /// as leaving the covered page readable, a finding since withdrawn.
  permanentStack,

  /// `if (!open) return page; return Stack(children: [page, drawer])` — the
  /// shape this component used to document, and the one that destroys the page
  /// every time the drawer opens.
  conditionalTree,
}
