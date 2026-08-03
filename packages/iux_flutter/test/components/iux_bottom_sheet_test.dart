import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

/// The mutable state the host page and the assertions share.
///
/// The parent owns whether the sheet is open, which is the whole point of the
/// component: the test plays the parent so the assertions can check that the
/// sheet never takes that decision for itself.
class _Scenario {
  bool open = false;
  int dismissals = 0;
  final FocusNode background = FocusNode(debugLabel: 'background');
  final FocusNode elsewhere = FocusNode(debugLabel: 'elsewhere');
  late StateSetter setHostState;

  void setOpen(bool value) => setHostState(() => open = value);
}

void main() {
  const String title = 'Filter orders';
  const String longTitle =
      'Filter the orders placed in this workspace during the current quarter';

  /// Content short enough that the sheet is sized by it rather than by its cap.
  const Widget shortContent = Text('Only unpaid orders are shown.');

  /// Content far taller than any sheet, so the cap and the scroll both bite.
  Widget tallContent() => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (int index = 0; index < 20; index++) Text('Item $index'),
        ],
      );

  Future<_Scenario> pump(
    WidgetTester tester, {
    bool open = false,
    IuxThemeConfiguration configuration = const IuxThemeConfiguration(),
    TextDirection direction = TextDirection.ltr,
    double textScale = 1,
    Size size = const Size(400, 800),
    double keyboard = 0,
    double systemBottomInset = 0,
    bool resizeToAvoidBottomInset = true,
    bool scaffold = true,
    String sheetTitle = title,
    String dismissLabel = 'Close',
    Widget content = shortContent,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final _Scenario scenario = _Scenario()..open = open;
    addTearDown(scenario.background.dispose);
    addTearDown(scenario.elsewhere.dispose);

    Widget host(BuildContext context, StateSetter setState) {
      scenario.setHostState = setState;
      return Stack(
        fit: StackFit.expand,
        children: <Widget>[
          IuxPage(
            child: Column(
              children: <Widget>[
                IuxButton(
                  label: 'Open',
                  action: const IuxActionDescriptor(
                    semantics: IuxActionSemantics(label: 'Open'),
                  ),
                  focusNode: scenario.background,
                  onActivate: () {},
                ),
                IuxButton(
                  label: 'Elsewhere',
                  action: const IuxActionDescriptor(
                    semantics: IuxActionSemantics(label: 'Elsewhere'),
                  ),
                  focusNode: scenario.elsewhere,
                  onActivate: () {},
                ),
              ],
            ),
          ),
          if (scenario.open)
            IuxBottomSheet(
              title: sheetTitle,
              dismissLabel: dismissLabel,
              onDismiss: () => scenario.dismissals++,
              child: content,
            ),
        ],
      );
    }

    final Widget body = StatefulBuilder(builder: host);

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
          // The keyboard is reported as a *view inset*: a strip of the window
          // the platform has taken away this frame. It is not a preference,
          // which is why the component is allowed to read it.
          viewInsets: EdgeInsets.only(bottom: keyboard),
          // And this is the platform contract the sheet leans on: while the
          // keyboard covers the navigation bar, `padding` no longer reports
          // it, because it is no longer the thing the content must avoid.
          // `viewPadding` still does.
          padding:
              EdgeInsets.only(bottom: keyboard > 0 ? 0 : systemBottomInset),
          viewPadding: EdgeInsets.only(bottom: systemBottomInset),
        ),
        child: MaterialApp(
          theme: IuxTheme.fromConfiguration(configuration),
          home: Directionality(
            textDirection: direction,
            child: scaffold
                ? Scaffold(
                    resizeToAvoidBottomInset: resizeToAvoidBottomInset,
                    body: body,
                  )
                : body,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return scenario;
  }

  Finder panelFinder() => find.descendant(
        of: find.byType(IuxBottomSheet),
        matching: find.byType(IuxSurface),
      );

  Rect panelRect(WidgetTester tester) => tester.getRect(panelFinder());

  /// Whether whatever holds focus right now is inside the sheet.
  bool focusIsInsideSheet() {
    final BuildContext? focused = FocusManager.instance.primaryFocus?.context;
    if (focused == null) return false;
    return focused.findAncestorWidgetOfExactType<IuxBottomSheet>() != null;
  }

  /// The nearest ancestor semantics node of [finder] that scopes a route.
  SemanticsNode? routeNodeAbove(WidgetTester tester, Finder finder) {
    SemanticsNode? node = tester.getSemantics(finder);
    while (node != null && !node.flagsCollection.scopesRoute) {
      node = node.parent;
    }
    return node;
  }

  /// Every label the compiled semantic tree currently exposes.
  ///
  /// Read from the tree assistive technology actually sees rather than through
  /// `find.bySemanticsLabel`, which reads each render object's *last* semantics
  /// node: a subtree that has been blocked keeps holding its node, so the
  /// finder reports content a screen reader can no longer reach.
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

  /// The accessible names of every control announced under [root].
  List<String> buttonLabelsUnder(SemanticsNode root) {
    final List<String> labels = <String>[];
    void visit(SemanticsNode node) {
      if (node.flagsCollection.isButton) labels.add(node.label);
      node.visitChildren((SemanticsNode child) {
        visit(child);
        return true;
      });
    }

    visit(root);
    return labels;
  }

  group('the keyboard, which is the reason a sheet is harder than a dialog',
      () {
    testWidgets('the sheet lifts itself clear of the keyboard',
        (WidgetTester tester) async {
      // Nothing else in this tree resizes for the keyboard, so the sheet must.
      await pump(
        tester,
        open: true,
        keyboard: 300,
        scaffold: false,
      );

      expect(
        tester.getSize(find.byType(IuxBottomSheet)).height,
        800,
        reason: 'the sheet was handed a box that already excluded the '
            'keyboard, so this is testing the other path',
      );
      expect(panelRect(tester).bottom, 500);
    });

    testWidgets(
        'the sheet does not lift twice when something already resized '
        'for the keyboard', (WidgetTester tester) async {
      // A Scaffold with the default resizeToAvoidBottomInset shrinks its body
      // above the keyboard and does *not* remove the inset from the MediaQuery
      // the body sees. Adding the full inset on top of that is the single most
      // common way this component is got wrong: it leaves a keyboard-sized
      // band of scrim under the sheet.
      await pump(tester, open: true, keyboard: 300);

      expect(
        tester.getSize(find.byType(IuxBottomSheet)).height,
        500,
        reason: 'the host did not resize, so this is testing the other path',
      );
      expect(
        panelRect(tester).bottom,
        500,
        reason: 'the sheet lifted by the keyboard a second time',
      );
    });

    testWidgets(
        'the sheet lands in the same place whether or not the host '
        'resizes', (WidgetTester tester) async {
      await pump(tester, open: true, keyboard: 300);
      final double resized = panelRect(tester).bottom;

      await pump(
        tester,
        open: true,
        keyboard: 300,
        resizeToAvoidBottomInset: false,
      );

      expect(panelRect(tester).bottom, resized);
    });

    testWidgets('the way out stays above the keyboard',
        (WidgetTester tester) async {
      await pump(tester, open: true, keyboard: 300, content: tallContent());

      expect(tester.getRect(find.text('Close')).bottom, lessThanOrEqualTo(500));
    });

    testWidgets('the content still scrolls in whatever the keyboard leaves',
        (WidgetTester tester) async {
      // The sheet sits above the keyboard, so the keyboard covers none of it —
      // but it takes the room the content had, and content that cannot be
      // reached is content the user cannot act on.
      await pump(tester, open: true, keyboard: 300, content: tallContent());

      await tester.ensureVisible(find.text('Item 19'));
      await tester.pumpAndSettle();

      final Rect panel = panelRect(tester);
      final Rect last = tester.getRect(find.text('Item 19'));
      expect(last.bottom, lessThanOrEqualTo(panel.bottom));
      expect(last.top, greaterThanOrEqualTo(panel.top));
    });

    testWidgets('a keyboard appearing does not push the sheet off the top',
        (WidgetTester tester) async {
      await pump(tester, open: true, keyboard: 300, content: tallContent());

      expect(panelRect(tester).top, greaterThanOrEqualTo(0));
    });

    testWidgets('with no keyboard the sheet sits on the bottom edge',
        (WidgetTester tester) async {
      await pump(tester, open: true);

      expect(panelRect(tester).bottom, 800);
    });
  });

  group('height is decided, not left to the caller', () {
    testWidgets('a short sheet is as tall as its content',
        (WidgetTester tester) async {
      // A sheet that always opens at its cap is mostly empty space covering a
      // page the user still needs.
      await pump(tester, open: true);

      expect(panelRect(tester).height, lessThan(800 * 0.6));
    });

    testWidgets('a long sheet stops at a fraction of the screen',
        (WidgetTester tester) async {
      // A sheet at 90% of a small screen is a dialog wearing a disguise: the
      // page behind is what tells the user where they still are.
      await pump(tester, open: true, content: tallContent());

      expect(panelRect(tester).height, lessThanOrEqualTo(800 * 0.6 + 0.5));
      expect(panelRect(tester).top, greaterThan(0));
    });

    testWidgets('the page behind stays visible above it',
        (WidgetTester tester) async {
      await pump(tester, open: true, content: tallContent());

      expect(
        panelRect(tester).top,
        greaterThanOrEqualTo(800 * 0.4 - 0.5),
        reason: 'the sheet covered the context it exists to preserve',
      );
    });

    testWidgets('the cap scales with the screen rather than being fixed',
        (WidgetTester tester) async {
      await pump(
        tester,
        open: true,
        size: const Size(320, 480),
        content: tallContent(),
      );

      expect(panelRect(tester).height, lessThanOrEqualTo(480 * 0.6 + 0.5));
      expect(
        panelRect(tester).height,
        greaterThan(0),
        reason: 'a sheet with no height hides its own content',
      );
    });
  });

  group('system insets are consumed once, by whoever is on that edge', () {
    testWidgets('the panel reaches the physical bottom edge',
        (WidgetTester tester) async {
      // Otherwise a strip of page shows under the sheet, which reads as a
      // rendering fault rather than as a design.
      await pump(tester, open: true, systemBottomInset: 48);

      expect(panelRect(tester).bottom, 800);
    });

    testWidgets('the content is held above the system bottom inset',
        (WidgetTester tester) async {
      await pump(tester, open: true, systemBottomInset: 48);

      final Finder body = find.descendant(
        of: find.byType(IuxBottomSheet),
        matching: find.byType(SingleChildScrollView),
      );
      expect(tester.getRect(body).bottom, lessThanOrEqualTo(800 - 48));
    });

    testWidgets('the page behind keeps consuming its own insets',
        (WidgetTester tester) async {
      // The two inset different content, so both are right. What must never
      // happen is a sheet placed *inside* the page, which insets one piece of
      // content twice from a bar that is only there once.
      final _Scenario scenario =
          await pump(tester, open: true, systemBottomInset: 48);

      expect(find.byType(IuxPage), findsOneWidget);
      expect(scenario.dismissals, 0);
    });
  });

  group('focus, which is what decides whether the sheet is usable at all', () {
    testWidgets('opening the sheet moves focus into it',
        (WidgetTester tester) async {
      final _Scenario scenario = await pump(tester);
      scenario.background.requestFocus();
      await tester.pump();
      expect(scenario.background.hasFocus, isTrue);

      scenario.setOpen(true);
      await tester.pumpAndSettle();

      expect(scenario.background.hasFocus, isFalse);
      expect(focusIsInsideSheet(), isTrue);
    });

    testWidgets(
        'focus does not land on a control, so the keyboard does not open '
        'over a sheet nobody has read yet', (WidgetTester tester) async {
      await pump(tester, open: true);

      final BuildContext focused = FocusManager.instance.primaryFocus!.context!;
      expect(
        focused.findAncestorWidgetOfExactType<IuxButton>(),
        isNull,
        reason: 'focus landed on a button; Enter would activate it',
      );
      expect(focused.findAncestorWidgetOfExactType<EditableText>(), isNull);
    });

    testWidgets('the keyboard cannot leave the sheet',
        (WidgetTester tester) async {
      final _Scenario scenario = await pump(tester, open: true);

      for (int press = 1; press <= 8; press++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(
          scenario.background.hasFocus,
          isFalse,
          reason: 'focus reached the covered page after $press tabs',
        );
        expect(
          focusIsInsideSheet(),
          isTrue,
          reason: 'focus left the sheet after $press tabs',
        );
      }
    });

    testWidgets('the way out is the first control reached by keyboard',
        (WidgetTester tester) async {
      await pump(tester, open: true);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      final BuildContext focused = FocusManager.instance.primaryFocus!.context!;
      final IuxButton? button =
          focused.findAncestorWidgetOfExactType<IuxButton>();
      expect(button, isNotNull);
      expect(button!.label, 'Close');
    });

    testWidgets('closing the sheet returns focus to what held it before',
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
        'while the sheet was open', (WidgetTester tester) async {
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

  group('there is always a way out, and none of them is a gesture', () {
    testWidgets('a labelled button dismisses', (WidgetTester tester) async {
      final _Scenario scenario = await pump(tester, open: true);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(scenario.dismissals, 1);
    });

    testWidgets('Escape dismisses', (WidgetTester tester) async {
      final _Scenario scenario = await pump(tester, open: true);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(scenario.dismissals, 1);
    });

    testWidgets('a tap on the scrim dismisses', (WidgetTester tester) async {
      final _Scenario scenario = await pump(tester, open: true);

      await tester.tapAt(const Offset(200, 40));
      await tester.pumpAndSettle();

      expect(scenario.dismissals, 1);
    });

    testWidgets('a tap just above the panel dismisses',
        (WidgetTester tester) async {
      // The space between the panel and the top of the screen is scrim, not
      // an inert margin belonging to the sheet.
      final _Scenario scenario = await pump(tester, open: true);
      final Rect panel = panelRect(tester);

      await tester.tapAt(Offset(panel.center.dx, panel.top - 8));
      await tester.pumpAndSettle();

      expect(scenario.dismissals, 1);
    });

    testWidgets('a tap inside the sheet is not a dismissal',
        (WidgetTester tester) async {
      final _Scenario scenario = await pump(tester, open: true);

      await tester.tap(find.text(title));
      await tester.pumpAndSettle();

      expect(scenario.dismissals, 0);
    });

    testWidgets('Escape still dismisses once focus has moved to a control',
        (WidgetTester tester) async {
      final _Scenario scenario = await pump(tester, open: true);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(scenario.dismissals, 1);
    });

    testWidgets('there is no drag handle pretending to be a control',
        (WidgetTester tester) async {
      // A handle that does not drag is a lie, and a drag that is the only way
      // out is a trap. Until drag exists as a redundant accelerator over the
      // button, nothing draws an affordance for it.
      final _Scenario scenario = await pump(tester, open: true);
      final Rect panel = panelRect(tester);

      await tester.dragFrom(
        Offset(panel.center.dx, panel.top + 4),
        const Offset(0, 300),
      );
      await tester.pumpAndSettle();

      expect(scenario.dismissals, 0);
      expect(find.byType(IuxBottomSheet), findsOneWidget);
    });
  });

  group('the parent owns the outcome', () {
    testWidgets('the sheet never closes itself', (WidgetTester tester) async {
      final _Scenario scenario = await pump(tester, open: true);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(scenario.dismissals, 1);
      expect(
        find.byType(IuxBottomSheet),
        findsOneWidget,
        reason: 'the sheet closed itself; only the parent may close it',
      );
    });

    testWidgets('the page it covers stays behind it',
        (WidgetTester tester) async {
      await pump(tester, open: true);

      expect(find.byType(IuxPage), findsOneWidget);
    });

    testWidgets('nothing is rendered while the parent says it is closed',
        (WidgetTester tester) async {
      await pump(tester);

      expect(find.byType(IuxBottomSheet), findsNothing);
      expect(find.text(title), findsNothing);
    });
  });

  group('assistive technology is told a sheet appeared', () {
    testWidgets('it scopes and names a route', (WidgetTester tester) async {
      await pump(tester, open: true);

      final SemanticsNode? route = routeNodeAbove(tester, find.text(title));

      expect(route, isNotNull);
      expect(route!.flagsCollection.namesRoute, isTrue);
      expect(
        route.label,
        contains(title),
        reason: 'the route is scoped but unnamed, so nothing is announced',
      );
    });

    testWidgets('the page behind it leaves the semantic tree',
        (WidgetTester tester) async {
      final _Scenario scenario = await pump(tester);
      expect(announcedLabels(tester), contains('Open'));

      scenario.setOpen(true);
      await tester.pumpAndSettle();

      expect(announcedLabels(tester), isNot(contains('Open')));
    });

    testWidgets('the page returns to the semantic tree when the sheet closes',
        (WidgetTester tester) async {
      final _Scenario scenario = await pump(tester, open: true);

      scenario.setOpen(false);
      await tester.pumpAndSettle();

      expect(announcedLabels(tester), contains('Open'));
    });

    testWidgets('the title is a heading, so it can be jumped to',
        (WidgetTester tester) async {
      await pump(tester, open: true);

      expect(
        tester.getSemantics(find.text(title)).flagsCollection.isHeader,
        isTrue,
      );
    });

    testWidgets('the only control the sheet adds is the way out',
        (WidgetTester tester) async {
      // The scrim dismisses too, but it is not announced: the button says the
      // same thing in words, and an unlabelled tappable region reachable only
      // by swiping is a control the user cannot verify before activating.
      await pump(tester, open: true);

      final SemanticsNode route = routeNodeAbove(tester, find.text(title))!;

      expect(buttonLabelsUnder(route), <String>['Close']);
    });
  });

  group('it survives large text on a small screen', () {
    testWidgets('everything still fits and the way out is reachable',
        (WidgetTester tester) async {
      final _Scenario scenario = await pump(
        tester,
        open: true,
        textScale: 2,
        size: const Size(320, 480),
        sheetTitle: longTitle,
        content: tallContent(),
      );

      expect(tester.takeException(), isNull);

      // Scrolled to, deliberately. At this size the title alone is taller than
      // the sheet is allowed to be, so the way out is below the fold — which
      // is the price of letting the header scroll rather than pinning it and
      // leaving the content no room at all.
      await tester.ensureVisible(find.text('Close'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(
        scenario.dismissals,
        1,
        reason: 'the way out could not be reached, so it does not exist',
      );
    });

    testWidgets('the header stacks rather than squeezing the title',
        (WidgetTester tester) async {
      await pump(
        tester,
        open: true,
        textScale: 2,
        size: const Size(320, 480),
        sheetTitle: longTitle,
      );

      expect(
        tester.getCenter(find.text('Close')).dy,
        greaterThan(tester.getCenter(find.text(longTitle)).dy),
      );
    });

    testWidgets('the header shares a line at ordinary text sizes',
        (WidgetTester tester) async {
      await pump(tester, open: true);

      expect(
        tester.getCenter(find.text('Close')).dx,
        greaterThan(tester.getCenter(find.text(title)).dx),
      );
    });

    testWidgets('the title is never truncated', (WidgetTester tester) async {
      await pump(
        tester,
        open: true,
        textScale: 2,
        size: const Size(320, 480),
        sheetTitle: longTitle,
      );

      final Text rendered = tester.widget<Text>(find.text(longTitle));
      expect(rendered.maxLines, isNull);
      expect(rendered.overflow, isNot(TextOverflow.ellipsis));
    });

    testWidgets('the content still scrolls at 200% on a small screen',
        (WidgetTester tester) async {
      await pump(
        tester,
        open: true,
        textScale: 2,
        size: const Size(320, 480),
        content: tallContent(),
      );

      await tester.ensureVisible(find.text('Item 19'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('it survives the conditions it will actually meet', () {
    testWidgets('the title still reads before the way out in RTL',
        (WidgetTester tester) async {
      await pump(tester, open: true, direction: TextDirection.rtl);

      expect(
        tester.getCenter(find.text(title)).dx,
        greaterThan(tester.getCenter(find.text('Close')).dx),
      );
    });

    testWidgets('it renders and dismisses right-to-left',
        (WidgetTester tester) async {
      final _Scenario scenario = await pump(
        tester,
        open: true,
        direction: TextDirection.rtl,
        sheetTitle: 'تصفية الطلبات',
        dismissLabel: 'إغلاق',
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

    testWidgets('the scrim never brightens what it covers',
        (WidgetTester tester) async {
      for (final Brightness brightness in Brightness.values) {
        await pump(
          tester,
          open: true,
          configuration: IuxThemeConfiguration(brightness: brightness),
        );

        final ColoredBox scrim = tester.widget<ColoredBox>(
          find.descendant(
            of: find.byType(IuxBottomSheet),
            matching: find.byType(ColoredBox),
          ),
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

  group('motion says where the sheet came from, and stops when asked', () {
    testWidgets('it rises from the bottom edge when motion is allowed',
        (WidgetTester tester) async {
      final _Scenario scenario = await pump(tester);

      scenario.setOpen(true);
      await tester.pump();

      final Finder slide = find.descendant(
        of: find.byType(IuxBottomSheet),
        matching: find.byType(SlideTransition),
      );
      expect(slide, findsOneWidget);
      expect(
        tester.widget<SlideTransition>(slide).position.value.dy,
        greaterThan(0),
      );

      await tester.pumpAndSettle();
      expect(tester.widget<SlideTransition>(slide).position.value, Offset.zero);
    });

    testWidgets('a reduced preference replaces the travel with a fade',
        (WidgetTester tester) async {
      // Shortening a large movement makes it worse, not better: for a
      // vestibular disorder a fast sweep is harder than a slow one.
      final _Scenario scenario = await pump(
        tester,
        configuration: const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(motion: IuxMotionPreference.reduced),
        ),
      );

      scenario.setOpen(true);
      await tester.pump();

      expect(
        find.descendant(
          of: find.byType(IuxBottomSheet),
          matching: find.byType(SlideTransition),
        ),
        findsNothing,
      );
      expect(_fadeOf(tester).opacity.value, lessThan(1));

      await tester.pumpAndSettle();
      expect(_fadeOf(tester).opacity.value, 1);
    });

    testWidgets('with motion turned off the sheet is there on the first frame',
        (WidgetTester tester) async {
      final _Scenario scenario = await pump(
        tester,
        configuration: const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(motion: IuxMotionPreference.none),
        ),
      );

      scenario.setOpen(true);
      await tester.pump();

      expect(find.text(title), findsOneWidget);
      expect(_fadeOf(tester).opacity.value, 1);
      expect(
        find.descendant(
          of: find.byType(IuxBottomSheet),
          matching: find.byType(SlideTransition),
        ),
        findsNothing,
      );
    });
  });

  group('incoherent sheets are rejected at construction', () {
    test('a sheet with no title cannot announce itself', () {
      expect(
        () => IuxBottomSheet(
          title: '',
          dismissLabel: 'Close',
          onDismiss: () {},
          child: const SizedBox.shrink(),
        ),
        throwsAssertionError,
      );
    });

    test('a sheet with no labelled way out is a trap', () {
      expect(
        () => IuxBottomSheet(
          title: title,
          dismissLabel: '',
          onDismiss: () {},
          child: const SizedBox.shrink(),
        ),
        throwsAssertionError,
      );
    });
  });
}

FadeTransition _fadeOf(WidgetTester tester) => tester.widget<FadeTransition>(
      find.descendant(
        of: find.byType(IuxBottomSheet),
        matching: find.byType(FadeTransition),
      ),
    );
