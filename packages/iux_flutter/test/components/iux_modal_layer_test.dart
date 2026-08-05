import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

/// What the layer owes the page it interrupts, measured rather than assumed.
///
/// Two things, and they were long believed to be in conflict:
///
/// 1. **The page survives.** Opening a modal must not destroy the widget that
///    opened it. IUX-OVERLAY-001 was recorded as a lost scroll position and is
///    worse than that: a callback closing over the opener's `State` fires
///    `setState() called after dispose()` on the tap that answers the dialog.
/// 2. **The page is unreachable.** While a modal is open the page must be gone
///    from the semantics tree, or a screen-reader user is read — and offered
///    the chance to activate — controls they cannot touch.
///
/// IUX-027 concluded that 1 could not be had without giving up 2, because
/// `BlockSemantics` was measured not to reach a page whose element survived.
/// **That conclusion is withdrawn.** It was measured with
/// `find.bySemanticsLabel`, which reads `RenderObject.debugSemantics` — a
/// per-render-object cache that keeps its last value when a subtree stops
/// being visited instead of being dirtied. Every assertion about the semantics
/// tree in this file therefore walks the tree the platform is actually given,
/// through [_liveLabels] and the simulated screen-reader traversal.
void main() {
  const String pageControl = 'Ouvrir le menu';
  const String drawerTitle = 'Sections';

  Widget page() => Scaffold(
        body: Center(
          child: IuxButton(
            label: pageControl,
            action: const IuxActionDescriptor(
              semantics: IuxActionSemantics(label: pageControl),
            ),
            onActivate: () {},
          ),
        ),
      );

  IuxNavigationDrawer drawer() => IuxNavigationDrawer(
        title: drawerTitle,
        dismissLabel: 'Fermer',
        onDismiss: () {},
        selectedIndex: 0,
        onDestinationSelected: (int index) {},
        destinations: const <IuxNavigationDestination>[
          IuxNavigationDestination(icon: Icons.inbox, label: 'Boîte'),
          IuxNavigationDestination(icon: Icons.send, label: 'Envoyés'),
          IuxNavigationDestination(icon: Icons.archive, label: 'Archives'),
        ],
      );

  Widget host(Widget child) => MaterialApp(
        theme: IuxTheme.light(),
        home: child,
      );

  group('the drawer slot', () {
    testWidgets('an open drawer takes the page out of the semantics tree',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.pumpWidget(host(IuxModalLayer(child: page())));
      expect(
        _liveLabels(tester),
        contains(pageControl),
        reason: 'the page is readable while nothing is open',
      );

      await tester.pumpWidget(
        host(IuxModalLayer(drawer: drawer(), child: page())),
      );
      await tester.pumpAndSettle();

      expect(
        _liveLabels(tester),
        isNot(contains(pageControl)),
        reason: 'a control the user cannot touch must not be readable, or a '
            'screen-reader user is offered an action that does nothing',
      );
      expect(find.text(drawerTitle), findsOneWidget);

      handle.dispose();
    });

    testWidgets('IUX-027, withdrawn: the hand-rolled stack hides the page too',
        (WidgetTester tester) async {
      // IUX-027 reported that `Stack(children: [page, if (open) drawer])`
      // leaves the covered page readable, and that report is the reason
      // IUX-OVERLAY-001 was left open for so long: it made the scroll loss
      // look like the price of the semantics barrier. It is not. The original
      // measurement used `find.bySemanticsLabel`, which reads
      // `RenderObject.debugSemantics` — and that cache keeps its last value
      // for a subtree that stops being visited rather than being dirtied, so
      // it reports a page that the platform is no longer told about.
      //
      // Both instruments are run here, on the same tree, so the difference is
      // the measurement rather than an argument. The finder half is not a test
      // of IUX: the day it starts returning nothing, Flutter has tightened
      // `debugSemantics` and this test can go.
      final SemanticsHandle handle = tester.ensureSemantics();

      Widget stacked({required bool open}) => host(
            Stack(
              fit: StackFit.expand,
              children: <Widget>[page(), if (open) drawer()],
            ),
          );

      await tester.pumpWidget(stacked(open: false));
      await tester.pumpWidget(stacked(open: true));
      await tester.pumpAndSettle();

      expect(
        _liveLabels(tester),
        isNot(contains(pageControl)),
        reason: 'the semantics tree the platform is given does not hold the '
            'covered page, in this shape either',
      );
      expect(
        _traversal(tester),
        isNot(contains(pageControl)),
        reason: 'no screen-reader swipe lands on the covered page',
      );
      expect(
        find.bySemanticsLabel(pageControl),
        findsOneWidget,
        reason: 'the stale cache IUX-027 read is still stale — this is the '
            'measurement that produced the withdrawn finding',
      );

      handle.dispose();
    });

    testWidgets('two modals at once are refused', (WidgetTester tester) async {
      expect(
        () => IuxModalLayer(
          drawer: drawer(),
          sheet: IuxBottomSheet(
            title: 'Trier',
            dismissLabel: 'Fermer',
            onDismissed: () {},
            child: const SizedBox(),
          ),
          child: page(),
        ),
        throwsAssertionError,
      );
    });
  });

  group('IUX-OVERLAY-001: opening a modal keeps the page it interrupts', () {
    // The page a modal interrupts is the page the user comes back to. If the
    // layer destroys it, three things happen at once and only one of them is
    // visible: the list they were reading returns to the top, every controller
    // and animation below is thrown away and rebuilt, and — the reason this is
    // a crash rather than an annoyance — any callback the opener handed to the
    // modal is now closed over a defunct `State`. The tap that answers the
    // dialog is the tap that throws.
    //
    // Each test below measures one of the three. The group after this one
    // measures the barrier that was believed to be the price of them.

    for (final _Slot slot in _Slot.values) {
      testWidgets('${slot.name}: the opener is not disposed',
          (WidgetTester tester) async {
        final _OpenerLog log = await _pumpOpener(tester, slot: slot);

        await tester.tap(find.text(_openLabel));
        await tester.pumpAndSettle();

        expect(
          log.disposals,
          0,
          reason: 'opening a modal destroyed the widget that opened it',
        );
        expect(
          log.inflations,
          1,
          reason: 'the page was built from scratch behind the modal',
        );
      });

      testWidgets('${slot.name}: answering does not throw on a dead State',
          (WidgetTester tester) async {
        final _OpenerLog log = await _pumpOpener(tester, slot: slot);

        await tester.tap(find.text(_openLabel));
        await tester.pumpAndSettle();

        await tester.tap(find.text(_dismissLabel));
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason: 'the callback the opener handed to the modal fired on a '
              'State the layer had already disposed',
        );
        expect(log.answers, 1, reason: 'the answer never reached the page');
      });

      testWidgets('${slot.name}: the page keeps its scroll position',
          (WidgetTester tester) async {
        await _pumpOpener(tester, slot: slot);

        _scrollableUnder(tester).position.jumpTo(400);
        await tester.pump();
        expect(_scrollableUnder(tester).position.pixels, 400);

        await tester.tap(find.text(_openLabel));
        await tester.pumpAndSettle();

        expect(
          _scrollableUnder(tester).position.pixels,
          400,
          reason: 'the user lost their place in the list the modal '
              'interrupted',
        );
      });
    }
  });

  group('the page behind a modal is unreachable', () {
    // The barrier this component promises, and the one a fix for
    // IUX-OVERLAY-001 could plausibly have broken: with the page's element now
    // preserved across the transition, nothing may let the page back into the
    // semantics tree. A control a screen reader reads out and offers to
    // activate, while the user cannot touch it, is worse than one that is
    // gone.
    //
    // Measured on the semantics tree the platform is given, never through
    // `find.bySemanticsLabel` — see 'IUX-027, withdrawn' above for why that
    // distinction is the whole story here.

    for (final _Slot slot in _Slot.values) {
      testWidgets('${slot.name}: the page leaves the semantics tree',
          (WidgetTester tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        await _pumpOpener(tester, slot: slot);

        expect(_liveLabels(tester), contains(_openLabel));
        expect(_liveLabels(tester), contains(_rowLabel));

        await tester.tap(find.text(_openLabel));
        await tester.pumpAndSettle();

        expect(
          _liveLabels(tester),
          isNot(contains(_openLabel)),
          reason: 'a control the user cannot touch must not be readable',
        );
        expect(
          _liveLabels(tester),
          isNot(contains(_rowLabel)),
          reason: 'the whole covered page goes, not only its controls',
        );
        expect(
          _traversal(tester),
          isNot(contains(_openLabel)),
          reason: 'no screen-reader swipe lands on the covered page',
        );

        handle.dispose();
      });

      testWidgets('${slot.name}: the page returns when the modal closes',
          (WidgetTester tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        await _pumpOpener(tester, slot: slot);

        await tester.tap(find.text(_openLabel));
        await tester.pumpAndSettle();
        await tester.tap(find.text(_dismissLabel));
        await tester.pumpAndSettle();

        expect(
          _liveLabels(tester),
          contains(_openLabel),
          reason: 'the page was hidden and never given back',
        );
        expect(_liveLabels(tester), contains(_rowLabel));

        handle.dispose();
      });

      testWidgets('${slot.name}: a tap where the page is does not reach it',
          (WidgetTester tester) async {
        // The half of the barrier that never depended on semantics, and the
        // one the preserved page could plausibly have broken: the page is
        // still laid out and still hit-testable underneath, so something has
        // to be in front of it. Whatever the tap does land on — the scrim, or
        // the drawer's own panel — it must not be the page.
        final _OpenerLog log = await _pumpOpener(tester, slot: slot);

        await tester.tap(find.text(_openLabel));
        await tester.pumpAndSettle();
        final int opened = log.opens;

        await tester.tap(find.text(_openLabel), warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(
          log.opens,
          opened,
          reason: 'the covered page answered a tap through the modal',
        );
        expect(tester.takeException(), isNull);
      });
    }
  });
}

/// What a screen-reader swipe would land on, in order.
List<String> _traversal(WidgetTester tester) => tester.semantics
    .simulatedAccessibilityTraversal()
    .map((SemanticsNode node) => node.label)
    .where((String label) => label.isNotEmpty)
    .toList();

/// Every label the compiled semantic tree currently exposes.
///
/// Walked from the application's own node downwards, so every label reached is
/// a real child of a live node. `find.bySemanticsLabel` asks each render object
/// for its `debugSemantics` instead, and that cache keeps its last value for a
/// subtree that stops being visited rather than being dirtied — which is
/// exactly what a blocked page does, and exactly how IUX-027 came out
/// backwards. The same helper, and the same reason, as
/// `iux_bottom_sheet_test.dart`.
List<String> _liveLabels(WidgetTester tester) {
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

/// Which slot of [IuxModalLayer] a scenario opens.
///
/// The three are exercised identically on purpose: they are one mechanism, and
/// a defect fixed in one slot and not the other two is a defect a caller finds
/// by switching component.
enum _Slot { dialog, sheet, drawer }

const String _openLabel = 'Ouvrir';
const String _dismissLabel = 'Fermer';
const String _rowLabel = 'Ligne 7';

/// What the opener's `State` did, recorded outside it so the record outlives
/// the `State` — which is the whole question here.
class _OpenerLog {
  int inflations = 0;
  int disposals = 0;
  int opens = 0;
  int answers = 0;
}

/// A page with a control that opens a modal and a list the user has scrolled.
///
/// It hands its *own* `setState` to the modal at the moment the modal is
/// asked for, which is what an application writes: the opener wants to know
/// what the user answered. That closure is the thing IUX-OVERLAY-001 turns
/// into a crash.
class _Opener extends StatefulWidget {
  const _Opener({required this.log, required this.onOpen});

  final _OpenerLog log;
  final ValueChanged<VoidCallback> onOpen;

  @override
  State<_Opener> createState() => _OpenerState();
}

class _OpenerState extends State<_Opener> {
  @override
  void initState() {
    super.initState();
    widget.log.inflations++;
  }

  @override
  void dispose() {
    widget.log.disposals++;
    super.dispose();
  }

  void _answered() => setState(() => widget.log.answers++);

  @override
  Widget build(BuildContext context) => Column(
        children: <Widget>[
          IuxButton(
            label: _openLabel,
            action: const IuxActionDescriptor(
              semantics: IuxActionSemantics(label: _openLabel),
            ),
            onActivate: () {
              widget.log.opens++;
              widget.onOpen(_answered);
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 40,
              itemExtent: 48,
              itemBuilder: (BuildContext context, int index) =>
                  Text('Ligne $index'),
            ),
          ),
        ],
      );
}

/// The page's scrollable, never the modal's.
ScrollableState _scrollableUnder(WidgetTester tester) => tester.state(
      find.descendant(
        of: find.byType(_Opener),
        matching: find.byType(Scrollable),
      ),
    );

/// Builds the layer with [slot] wired to a flag the host owns.
Future<_OpenerLog> _pumpOpener(
  WidgetTester tester, {
  required _Slot slot,
}) async {
  final _OpenerLog log = _OpenerLog();
  bool open = false;
  VoidCallback? answer;

  await tester.pumpWidget(
    MaterialApp(
      theme: IuxTheme.light(),
      home: Scaffold(
        body: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            void close() {
              // The order an application writes: tell the opener first, then
              // lower the flag. Reversing it would hide the defect behind the
              // rebuild rather than measure it.
              answer?.call();
              setState(() => open = false);
            }

            final Widget opener = _Opener(
              log: log,
              onOpen: (VoidCallback captured) => setState(() {
                answer = captured;
                open = true;
              }),
            );

            return IuxModalLayer(
              dialog: open && slot == _Slot.dialog
                  ? IuxDialog(
                      title: 'Supprimer ?',
                      message: 'La facture est supprimée définitivement.',
                      dismissLabel: _dismissLabel,
                      onDismissed: close,
                    )
                  : null,
              sheet: open && slot == _Slot.sheet
                  ? IuxBottomSheet(
                      title: 'Trier',
                      dismissLabel: _dismissLabel,
                      onDismissed: close,
                      child: const SizedBox(height: 80),
                    )
                  : null,
              drawer: open && slot == _Slot.drawer
                  ? IuxNavigationDrawer(
                      title: 'Sections',
                      dismissLabel: _dismissLabel,
                      onDismiss: close,
                      selectedIndex: 0,
                      onDestinationSelected: (int _) {},
                      destinations: const <IuxNavigationDestination>[
                        IuxNavigationDestination(
                            icon: Icons.inbox, label: 'Boîte'),
                        IuxNavigationDestination(
                            icon: Icons.send, label: 'Envoyés'),
                      ],
                    )
                  : null,
              child: opener,
            );
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return log;
}
