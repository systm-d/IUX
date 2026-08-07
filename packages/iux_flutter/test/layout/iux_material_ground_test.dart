import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

/// A route root with no `Scaffold` anywhere, which is the whole point.
///
/// Every other test in this suite reaches its widget through a host that
/// supplies one, and that is exactly why none of them could see the defect
/// these tests exist for: two consumer applications rendered whole screens in
/// Flutter's fallback text style, and their suites — one of them a golden suite
/// over five screens — stayed green throughout.
Widget host(Widget child) => MaterialApp(
      theme: IuxTheme.fromConfiguration(const IuxThemeConfiguration()),
      home: child,
    );

/// The style a bare `Text` would resolve against at [finder].
TextStyle inherited(WidgetTester tester, Finder finder) =>
    DefaultTextStyle.of(tester.element(finder)).style;

void main() {
  group('a route root establishes its own Material medium', () {
    testWidgets('IuxPage alone displaces the fallback style', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(const IuxPage(child: Text('content'))),
      );

      final TextStyle style = inherited(tester, find.text('content'));
      // The three fingerprints of `_errorTextStyle`, which is what a route root
      // without a Material resolves against. Flutter's own debugLabel for it is
      // 'fallback style; consider putting your text in a Material'.
      expect(style.fontFamily, isNot('monospace'));
      expect(style.decoration, isNot(TextDecoration.underline));
      expect(style.decorationColor, isNot(const Color(0xFFFFFF00)));
    });

    testWidgets('IuxScreen covers the bar as well as the page', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          const IuxScreen(
            appBar: IuxAppBar(title: 'Orders'),
            page: IuxPage(child: Text('content')),
          ),
        ),
      );

      // The bar is the page's sibling, so a ground inside the page cannot reach
      // it. Both consumer applications rendered their *title* in the fallback
      // style; this is the assertion that would have said so.
      for (final Finder finder in <Finder>[
        find.text('Orders'),
        find.text('content'),
      ]) {
        final TextStyle style = inherited(tester, finder);
        expect(style.fontFamily, isNot('monospace'), reason: finder.toString());
        expect(
          style.decoration,
          isNot(TextDecoration.underline),
          reason: finder.toString(),
        );
      }
    });

    testWidgets('the resolved style is the body role, with a colour', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(const IuxPage(child: Text('content'))),
      );

      final BuildContext context = tester.element(find.text('content'));
      final TextStyle style = inherited(tester, find.text('content'));

      expect(style.fontSize, IuxTypographyTheme.of(context).body.fontSize);
      // The role styles name size, height and weight and no colour, so an
      // inherited default resolves to the engine's black. Every IUX component
      // sets its own colour and never noticed; a caller's bare `Text` would.
      expect(style.color, IuxSemanticColors.of(context).content.primary);
    });

    // The three layers place their own content as a *sibling* of the page, so
    // the medium the page establishes for itself never reaches them. Each of
    // these was measured falling back before its ground existed — including
    // the dialog, which is the worst of them: a confirmation rendered in
    // monospace and yellow rules.
    testWidgets('IuxModalLayer covers the modal, not just the page', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          IuxModalLayer(
            dialog: IuxDialog(
              title: 'Delete this invoice?',
              message: 'The invoice and its attachments are removed.',
              dismissLabel: 'Keep it',
              onDismissed: () {},
            ),
            child: const IuxPage(child: Text('content')),
          ),
        ),
      );

      for (final String label in <String>[
        'Delete this invoice?',
        'The invoice and its attachments are removed.',
        'Keep it',
      ]) {
        expect(
          inherited(tester, find.text(label)).fontFamily,
          isNot('monospace'),
          reason: label,
        );
      }
    });

    testWidgets('IuxTransientLayer covers the message', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          IuxTransientLayer(
            message: const IuxTransientMessage(
              text: 'Invoice deleted.',
              dismissLabel: 'Dismiss',
            ),
            onDismissed: () {},
            child: const IuxPage(child: Text('content')),
          ),
        ),
      );

      expect(
        inherited(tester, find.text('Invoice deleted.')).fontFamily,
        isNot('monospace'),
      );
    });

    testWidgets('IuxAdaptiveNavigation covers the destinations', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          IuxAdaptiveNavigation(
            label: 'Sections',
            selectedIndex: 0,
            onDestinationSelected: (int _) {},
            destinations: const <IuxNavigationDestination>[
              IuxNavigationDestination(label: 'Home', icon: Icons.home),
              IuxNavigationDestination(label: 'Orders', icon: Icons.list),
              IuxNavigationDestination(label: 'Profile', icon: Icons.person),
            ],
            child: const IuxPage(child: Text('content')),
          ),
        ),
      );

      for (final String label in <String>['Home', 'Orders', 'Profile']) {
        expect(
          inherited(tester, find.text(label)).fontFamily,
          isNot('monospace'),
          reason: label,
        );
      }
    });

    testWidgets('the page background is still the surface token', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(const IuxPage(child: Text('content'))),
      );

      final BuildContext context = tester.element(find.text('content'));
      // Transparency, not a coloured Material: the surface decision stays with
      // the semantic tokens rather than moving to `canvasColor`.
      expect(
        tester
            .widgetList<ColoredBox>(find.byType(ColoredBox))
            .map((ColoredBox box) => box.color),
        contains(IuxSemanticColors.of(context).surface.base),
      );
    });
  });
}
