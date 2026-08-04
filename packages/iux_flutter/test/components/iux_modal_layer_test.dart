import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

/// The drawer slot exists because getting the shape wrong is silent.
///
/// IUX-027 probed `Stack(children: [page, if (open) drawer])` and found that
/// the page element survives, its semantics node is never recompiled, and
/// `BlockSemantics` therefore does not remove the covered page. A screen
/// reader goes on reading — and offering to activate — controls the user
/// cannot touch. Touch behaves identically in both shapes, which is why the
/// broken one looks correct in every manual check that does not involve a
/// screen reader.
///
/// These tests pin both halves: that routing through [IuxModalLayer] hides the
/// page, and that the hand-rolled stack does not. The second is not a test of
/// IUX — it fails the day Flutter changes the underlying behaviour, which is
/// the day the slot's justification needs rereading.
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
        find.bySemanticsLabel(pageControl),
        findsOneWidget,
        reason: 'the page is readable while nothing is open',
      );

      await tester.pumpWidget(
        host(IuxModalLayer(drawer: drawer(), child: page())),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(pageControl),
        findsNothing,
        reason: 'a control the user cannot touch must not be readable, or a '
            'screen-reader user is offered an action that does nothing',
      );
      expect(find.text(drawerTitle), findsOneWidget);

      handle.dispose();
    });

    testWidgets('the hand-rolled stack leaves the page readable',
        (WidgetTester tester) async {
      // Not a test of IUX. This pins the Flutter behaviour the slot exists to
      // work around: when the page element survives the transition, its
      // semantics node is not recompiled and BlockSemantics never reaches it.
      // If this ever starts failing, Flutter has fixed it and the slot's
      // justification — and IUX-OVERLAY-001 — should be reread.
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
        find.bySemanticsLabel(pageControl),
        findsOneWidget,
        reason: 'the covered page is still readable in this shape — this is '
            'the defect IuxModalLayer.drawer exists to make unreachable',
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
}
