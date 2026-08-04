import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';
// Imported from `src` because the barrel is owned elsewhere; the export of
// `iux_screen.dart` is reported rather than written by this mission.

/// A title long enough to need its own line, and more than one of them once the
/// text is enlarged.
const String _title = 'Quarterly delivery exceptions';

/// The only thing on the page, so its position is the content's position.
const String _content = 'First line of content';

/// The three sections of an application with a bottom bar.
const List<IuxNavigationDestination> _destinations = <IuxNavigationDestination>[
  IuxNavigationDestination(label: 'Home', icon: Icons.home_outlined),
  IuxNavigationDestination(label: 'Orders', icon: Icons.list_outlined),
  IuxNavigationDestination(label: 'Account', icon: Icons.person_outline),
];

/// The window shapes every measurement below is repeated on: the narrowest
/// screen IUX claims to support, and an ordinary phone.
const List<Size> _windows = <Size>[Size(320, 640), Size(360, 800)];

/// 100% to 300%. Above 200% is past what WCAG requires and is exactly where
/// this composition used to overflow.
const List<double> _scales = <double>[1, 1.5, 2, 2.5, 3];

/// Half of an odd number of logical pixels is not an exact half.
const double _tolerance = 0.51;

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget body, {
    Size size = const Size(320, 640),
    double textScale = 1,
    EdgeInsets padding = EdgeInsets.zero,
    TextDirection direction = TextDirection.ltr,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: size,
          padding: padding,
          textScaler: TextScaler.linear(textScale),
        ),
        child: MaterialApp(
          theme: IuxTheme.fromConfiguration(const IuxThemeConfiguration()),
          home: Directionality(
            textDirection: direction,
            child: Scaffold(body: body),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Clears the element tree between cases.
  ///
  /// `DebugOverflowIndicatorMixin` reports an overflow once per render object
  /// lifetime, so a loop that reuses the tree would see the second case's
  /// overflow swallowed by the first case's report.
  Future<void> reset(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox.shrink());

  IuxAppBar bar({String title = _title}) => IuxAppBar(
        title: title,
        leading: IuxAppBarLeading.back(label: 'Back', onActivate: () {}),
        actions: <IuxIconButton>[
          IuxIconButton(
            icon: Icons.search,
            action: const IuxActionDescriptor(
              semantics: IuxActionSemantics(label: 'Search'),
            ),
            onActivate: () {},
          ),
        ],
      );

  Widget screen({String title = _title, Widget? footer}) => IuxScreen(
        appBar: bar(title: title),
        page: IuxPage(footer: footer, child: const Text(_content)),
      );

  /// The screen under the navigation an application actually ships with.
  Widget navigated({String title = _title}) => IuxAdaptiveNavigation(
        label: 'Main navigation',
        destinations: _destinations,
        selectedIndex: 0,
        onDestinationSelected: (int _) {},
        child: screen(title: title),
      );

  /// What every application wrote before this component existed.
  Widget siblings() => Column(
        children: <Widget>[
          bar(),
          const Expanded(child: IuxPage(child: Text(_content))),
        ],
      );

  group('the top inset is spent once', () {
    testWidgets('a display inset moves the content by exactly its own height',
        (WidgetTester tester) async {
      await pump(tester, screen());
      final double flat = tester.getRect(find.text(_content)).top;

      await reset(tester);
      await pump(tester, screen(), padding: const EdgeInsets.only(top: 40));
      final double inset = tester.getRect(find.text(_content)).top;

      // The bar spends it, inside its own background. If the page spent it
      // again this would be 80.
      expect(inset - flat, 40);
    });

    testWidgets('the arrangement it replaces spends it twice',
        (WidgetTester tester) async {
      // Pinned rather than described: this is the defect the component exists
      // to make unwritable, and it is silent — nothing asserts, and on a device
      // with no cutout nothing looks wrong.
      await pump(tester, siblings());
      final double flat = tester.getRect(find.text(_content)).top;

      await reset(tester);
      await pump(tester, siblings(), padding: const EdgeInsets.only(top: 40));
      final double inset = tester.getRect(find.text(_content)).top;

      expect(inset - flat, 80);
    });

    testWidgets('the side insets a landscape cutout needs are still taken',
        (WidgetTester tester) async {
      // The remedy a caller had to write for the top — `IuxPageInsets.none` —
      // gave these up as well. The page here is on its default, so it keeps
      // them.
      await pump(tester, screen());
      final double flat = tester.getRect(find.text(_content)).left;

      await reset(tester);
      await pump(tester, screen(), padding: const EdgeInsets.only(left: 32));
      final double inset = tester.getRect(find.text(_content)).left;

      expect(inset - flat, 32);
    });

    testWidgets('the bottom inset is still the page\'s to take',
        (WidgetTester tester) async {
      await pump(tester, screen());
      final double flat = tester.getRect(find.text(_content)).bottom;

      await reset(tester);
      await pump(tester, screen(), padding: const EdgeInsets.only(bottom: 48));
      final double inset = tester.getRect(find.text(_content)).bottom;

      // The content is at the top of a page that fills the box, so a bottom
      // inset does not move it; what matters is that the page still consumes
      // it, which the page's own tests cover. Here: it is not consumed twice
      // and it does not move the content.
      expect(inset, flat);
    });
  });

  group('somebody owns the total', () {
    testWidgets('nothing overflows at any text scale, on any window',
        (WidgetTester tester) async {
      for (final Size window in _windows) {
        for (final double scale in _scales) {
          await reset(tester);
          await pump(tester, navigated(), size: window, textScale: scale);

          expect(
            tester.takeException(),
            isNull,
            reason: 'overflowed at ${scale}x on ${window.width}x'
                '${window.height}',
          );
        }
      }
    });

    testWidgets('the arrangement it replaces overflows at 250% and above',
        (WidgetTester tester) async {
      // The measurement that opened IUX-APPBAR-PAGE-001, pinned so that the
      // component cannot be deleted without the defect coming back visibly.
      for (final double scale in <double>[2.5, 3]) {
        await reset(tester);
        await pump(
          tester,
          IuxAdaptiveNavigation(
            label: 'Main navigation',
            destinations: _destinations,
            selectedIndex: 0,
            onDestinationSelected: (int _) {},
            child: siblings(),
          ),
          textScale: scale,
        );

        expect(
          tester.takeException(),
          isA<FlutterError>(),
          reason: 'the sibling Column should still overflow at ${scale}x',
        );
      }
    });

    testWidgets('the chrome never takes more than half the screen',
        (WidgetTester tester) async {
      for (final Size window in _windows) {
        for (final double scale in _scales) {
          await reset(tester);
          await pump(tester, navigated(), size: window, textScale: scale);

          final double frame = tester.getSize(find.byType(IuxScreen)).height;
          final double barHeight =
              tester.getSize(find.byType(IuxAppBar)).height;

          expect(
            barHeight,
            lessThanOrEqualTo(frame / 2 + _tolerance),
            reason: 'the bar took $barHeight of $frame at ${scale}x on '
                '${window.width}x${window.height}',
          );
        }
      }
    });

    testWidgets('the page always keeps the other half',
        (WidgetTester tester) async {
      for (final Size window in _windows) {
        for (final double scale in _scales) {
          await reset(tester);
          await pump(tester, navigated(), size: window, textScale: scale);

          final double frame = tester.getSize(find.byType(IuxScreen)).height;
          final double page = tester.getSize(find.byType(IuxPage)).height;

          // Before this component the page was laid out at zero height on the
          // same window at 250% and 300%, under a bar that had taken
          // everything and then some.
          expect(
            page,
            greaterThanOrEqualTo(frame / 2 - _tolerance),
            reason: 'the page got $page of $frame at ${scale}x on '
                '${window.width}x${window.height}',
          );
          expect(find.text(_content), findsOneWidget);
        }
      }
    });

    testWidgets('a display inset does not change the answer',
        (WidgetTester tester) async {
      for (final double scale in _scales) {
        await reset(tester);
        await pump(
          tester,
          navigated(),
          textScale: scale,
          padding: const EdgeInsets.only(top: 40, bottom: 24),
        );

        expect(tester.takeException(), isNull, reason: 'inset, ${scale}x');
        expect(
          tester.getSize(find.byType(IuxAppBar)).height,
          lessThanOrEqualTo(
            tester.getSize(find.byType(IuxScreen)).height / 2 + _tolerance,
          ),
        );
      }
    });

    testWidgets('the bar is exactly as tall as it asks to be while it fits',
        (WidgetTester tester) async {
      // The share is a ceiling, never a target: below it the bar is untouched,
      // which is every ordinary screen.
      await reset(tester);
      await pump(tester, screen(title: 'Orders'), size: const Size(360, 800));
      final double inScreen = tester.getSize(find.byType(IuxAppBar)).height;

      await reset(tester);
      await pump(
        tester,
        Column(children: <Widget>[bar(title: 'Orders')]),
        size: const Size(360, 800),
      );

      expect(inScreen, tester.getSize(find.byType(IuxAppBar)).height);
    });
  });

  group('when the bar runs out of room', () {
    /// The worst case IUX-APPBAR-PAGE-001 measured: the narrowest window, the
    /// largest text, and a navigation bar already holding a third of it.
    Future<void> pumpWorstCase(WidgetTester tester) async {
      await reset(tester);
      await pump(tester, navigated(), textScale: 3);
    }

    testWidgets('the title is still whole, and still a heading',
        (WidgetTester tester) async {
      await pumpWorstCase(tester);

      final Text text = tester.widget<Text>(find.text(_title));
      expect(text.maxLines, isNull);
      expect(text.overflow, isNot(TextOverflow.ellipsis));
      expect(
        tester.getSemantics(find.text(_title)).flagsCollection.isHeader,
        isTrue,
      );
    });

    testWidgets('the whole title is laid out, not clipped to the strip',
        (WidgetTester tester) async {
      await pumpWorstCase(tester);

      final double strip = tester.getSize(find.byType(IuxAppBar)).height;
      final double title = tester.getSize(find.text(_title)).height;

      // The title alone is taller than the whole strip it lives in, and it is
      // laid out at that height rather than shortened to fit — which is what
      // makes this a degradation rather than a truncation.
      expect(title, greaterThan(strip));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the strip scrolls, so the whole title stays reachable',
        (WidgetTester tester) async {
      await pumpWorstCase(tester);

      final Finder scroller = find.descendant(
        of: find.byType(IuxAppBar),
        matching: find.byType(Scrollable),
      );
      final ScrollPosition position =
          tester.state<ScrollableState>(scroller).position;

      expect(position.maxScrollExtent, greaterThan(0));

      final double before = tester.getRect(find.text(_title)).top;
      await tester.drag(scroller, const Offset(0, -60));
      await tester.pumpAndSettle();

      expect(tester.getRect(find.text(_title)).top, lessThan(before));
    });

    testWidgets('a bar that fits scrolls nothing', (WidgetTester tester) async {
      await reset(tester);
      await pump(tester, screen(title: 'Orders'), size: const Size(360, 800));

      final ScrollPosition position = tester
          .state<ScrollableState>(
            find.descendant(
              of: find.byType(IuxAppBar),
              matching: find.byType(Scrollable),
            ),
          )
          .position;

      expect(position.maxScrollExtent, 0);
    });

    testWidgets('the boundary against the page stays where the page starts',
        (WidgetTester tester) async {
      await pumpWorstCase(tester);

      // The surface and its bottom border belong to the box, not to the
      // scrolling content: a boundary that scrolled away would leave the bar
      // and the page indistinguishable, and it is the only signal separating
      // them.
      final Rect barBox = tester.getRect(find.byType(IuxAppBar));
      final Rect pageBox = tester.getRect(find.byType(IuxPage));

      expect(barBox.bottom, moreOrLessEquals(pageBox.top));
    });
  });

  group('it reports its own dimensions', () {
    testWidgets('a screen can be measured by IntrinsicHeight',
        (WidgetTester tester) async {
      // The arrangement that threw *LayoutBuilder does not support returning
      // intrinsic dimensions* for as long as the bar decided its layout in one.
      await pump(
        tester,
        SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 640),
            child: IntrinsicHeight(child: screen()),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text(_content), findsOneWidget);
      expect(find.text(_title), findsOneWidget);
    });

    testWidgets('a viewport floor is a box to fill, not a minimum to exceed',
        (WidgetTester tester) async {
      // Fill-viewport-or-scroll without the `IntrinsicHeight`: the floor says
      // how tall the screen is, so the page still fills it and its background,
      // footer and centring still have a box to work in.
      await pump(
        tester,
        SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 640),
            child: screen(),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(IuxScreen)).height, 640);
      expect(
        tester.getSize(find.byType(IuxAppBar)).height +
            tester.getSize(find.byType(IuxPage)).height,
        640,
      );
    });

    testWidgets('a bar can size an intrinsic table column',
        (WidgetTester tester) async {
      // The third arrangement the evidence entry names, and the one that reads
      // as most exotic until an application puts a bar in a two-pane layout.
      await pump(
        tester,
        Align(
          alignment: Alignment.topLeft,
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            children: <TableRow>[
              TableRow(children: <Widget>[bar(title: 'Orders')]),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Orders'), findsOneWidget);
    });

    testWidgets('a bar can be measured by IntrinsicWidth',
        (WidgetTester tester) async {
      await pump(
        tester,
        Align(
          alignment: Alignment.topLeft,
          child: IntrinsicWidth(child: bar(title: 'Orders')),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Orders'), findsOneWidget);
    });

    testWidgets('the reported height is the height it takes',
        (WidgetTester tester) async {
      // An intrinsic answer that disagreed with the layout would be worse than
      // no answer: it is used to size the box the layout then happens in.
      await pump(tester, screen());
      final double laidOut = tester.getSize(find.byType(IuxAppBar)).height;

      await reset(tester);
      await pump(
        tester,
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 320,
            child: IntrinsicHeight(child: bar()),
          ),
        ),
      );

      expect(tester.getSize(find.byType(IuxAppBar)).height, laidOut);
    });

    testWidgets('an unbounded width lays out instead of throwing',
        (WidgetTester tester) async {
      // The `Row` the bar used to build put an `Expanded` under an unbounded
      // width, which throws. Nothing here does.
      await pump(
        tester,
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: bar(),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text(_title), findsOneWidget);
    });
  });

  group('what the page keeps', () {
    testWidgets('a footer stays pinned to the bottom of the page',
        (WidgetTester tester) async {
      // The page is given a tight height rather than a loose one, which is what
      // an `Expanded` inside it needs. Loose, this arrangement throws.
      await pump(
        tester,
        screen(footer: const Text('Confirm')),
        size: const Size(360, 800),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getRect(find.text('Confirm')).bottom,
        moreOrLessEquals(tester.getRect(find.byType(IuxPage)).bottom,
            epsilon: 24),
      );
    });

    testWidgets('the content scrolls inside its own half',
        (WidgetTester tester) async {
      await pump(
        tester,
        IuxScreen(
          appBar: bar(),
          page: IuxPage(
            child: Column(
              children: <Widget>[
                for (int i = 0; i < 40; i++) Text('Row $i'),
              ],
            ),
          ),
        ),
        textScale: 3,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Row 0'), findsOneWidget);

      final ScrollPosition position = tester
          .state<ScrollableState>(
            find.descendant(
              of: find.byType(IuxPage),
              matching: find.byType(Scrollable),
            ),
          )
          .position;
      expect(position.maxScrollExtent, greaterThan(0));
    });

    testWidgets('dragging the content does not move the bar',
        (WidgetTester tester) async {
      // Two scrollables in one screen, and the one under the finger is the one
      // that moves. The bar's is inert while it fits and never the primary, so
      // a page drag cannot be answered by the chrome.
      await pump(
        tester,
        IuxScreen(
          appBar: bar(),
          page: IuxPage(
            child: Column(
              children: <Widget>[
                for (int i = 0; i < 40; i++) Text('Row $i'),
              ],
            ),
          ),
        ),
        textScale: 3,
      );

      final double titleBefore = tester.getRect(find.text(_title)).top;
      await tester.drag(find.text('Row 0'), const Offset(0, -80));
      await tester.pumpAndSettle();

      expect(tester.getRect(find.text(_title)).top, titleBefore);
    });

    testWidgets('right-to-left keeps the way out on the trailing edge',
        (WidgetTester tester) async {
      await pump(
        tester,
        IuxScreen(
          appBar: IuxAppBar(
            title: 'الطلبات',
            leading: IuxAppBarLeading.back(label: 'رجوع', onActivate: () {}),
          ),
          page: const IuxPage(child: Text(_content)),
        ),
        direction: TextDirection.rtl,
      );

      expect(
          tester.getRect(find.byType(IuxIconButton)).right, greaterThan(160));
      expect(tester.takeException(), isNull);
    });
  });

  group('it composes with the layers around it', () {
    testWidgets('modal outside, navigation, notice, screen',
        (WidgetTester tester) async {
      // The stack an application actually ships, in the order the two overlay
      // layers already require: a dialog covers the navigation, a notice may
      // not. The screen is the innermost of the four, which is what makes it a
      // frame for content rather than a frame for the application.
      for (final double scale in _scales) {
        await reset(tester);
        await pump(
          tester,
          IuxModalLayer(
            child: IuxAdaptiveNavigation(
              label: 'Main navigation',
              destinations: _destinations,
              selectedIndex: 0,
              onDestinationSelected: (int _) {},
              child: IuxTransientLayer(
                message: const IuxTransientMessage(
                  text: 'Saved',
                  dismissLabel: 'Dismiss',
                ),
                onDismissed: () {},
                child: screen(),
              ),
            ),
          ),
          textScale: scale,
        );

        expect(tester.takeException(), isNull, reason: 'stacked, ${scale}x');
        expect(find.text(_title), findsOneWidget);
        expect(find.text(_content), findsOneWidget);
      }
    });
  });

  group('the reading order survives the frame', () {
    testWidgets('the heading is announced before the content',
        (WidgetTester tester) async {
      await pump(tester, screen());

      final List<String> spoken = <String>[];
      void visit(SemanticsNode node) {
        final String label = node.getSemanticsData().label;
        if (label.isNotEmpty) spoken.add(label);
        node.visitChildren((SemanticsNode child) {
          visit(child);
          return true;
        });
      }

      visit(tester.getSemantics(find.byType(IuxScreen)));

      expect(spoken.indexOf(_title), lessThan(spoken.indexOf(_content)));
      expect(spoken.indexOf('Back'), lessThan(spoken.indexOf(_title)));
    });
  });
}
