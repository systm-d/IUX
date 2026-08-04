import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

/// IUX-TRANSIENT-COVER-001.
///
/// A transient notice is pinned to the bottom edge of whatever the layer wraps
/// and reserves no layout space. A bottom navigation bar occupies the same
/// edge. So a layer wrapped *around* the navigation puts every notice on top of
/// the destinations — measured by IUX-041 on a 360x800 window as the notice at
/// y 712-760, the destinations at y 740-786, and all three `hitTestable = 0`.
/// The dwell is at least four seconds and by design cannot be shortened, so the
/// user loses their ability to change section for four seconds every time the
/// application says "added" — WCAG 2.2 SC 2.2.1.
///
/// Two halves are pinned here:
///
/// 1. **The arrangement that produces it is refused**, in every component that
///    owns a destination and in the one that chooses between them. Delete any
///    of the three assertions and the first group fails.
/// 2. **The arrangement that works, measured the way the defect was found** —
///    `hitTestable` on every destination while a notice is on screen, plus a
///    tap that actually changes section — at 100/150/200/300% text on the two
///    narrowest windows IUX supports, with a message long enough to wrap.
///
/// Each case is its own `testWidgets` rather than a loop over one element tree.
/// `DebugOverflowIndicatorMixin` reports a given render object once per
/// lifetime, so a loop that reused the tree would see the first overflow and
/// silently pass every case after it.
void main() {
  const List<IuxNavigationDestination> destinations =
      <IuxNavigationDestination>[
    IuxNavigationDestination(label: 'Jobs', icon: Icons.list_outlined),
    IuxNavigationDestination(label: 'New', icon: Icons.add_circle_outline),
    IuxNavigationDestination(label: 'Settings', icon: Icons.settings_outlined),
  ];

  /// One line at every text scale on both windows.
  const IuxTransientMessage short = IuxTransientMessage(
    text: 'Visit added',
    dismissLabel: 'Dismiss the added-visit notice',
    tone: IuxTransientTone.success,
  );

  /// Wraps on both windows at 100% and is taller than the page above the bar
  /// well before 300%. This is the case the fix has to survive: a long message
  /// at an enlarged text size is exactly when the notice and the navigation
  /// both matter most.
  const IuxTransientMessage long = IuxTransientMessage(
    text: 'Visit WO-1 was added to the round, and the reminder set for it '
        'will arrive tomorrow morning at eight.',
    dismissLabel: 'Dismiss the added-visit notice',
    tone: IuxTransientTone.success,
  );

  /// The correct shell: modal layer outside the navigation, transient layer
  /// inside it. This is the arrangement the assertion leaves expressible.
  Widget shell({
    required IuxTransientMessage? message,
    required ValueChanged<int> onDestinationSelected,
    int selectedIndex = 0,
  }) =>
      IuxModalLayer(
        child: IuxAdaptiveNavigation(
          label: 'Main navigation',
          destinations: destinations,
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          child: IuxTransientLayer(
            message: message,
            onDismissed: () {},
            child: Center(child: Text('Section $selectedIndex')),
          ),
        ),
      );

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Size size = const Size(360, 800),
    double textScale = 1,
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
          theme: IuxTheme.light(),
          home: Scaffold(body: child),
        ),
      ),
    );
    // Past the entrance fade, and nowhere near the four-second floor: the
    // notice is at its most obstructive while it is still on screen.
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// Pumps [child] and returns everything Flutter reported while it did.
  ///
  /// A collected list rather than `takeException`: a build that throws is
  /// replaced by an `ErrorWidget`, which is as tall as it likes and overflows
  /// whatever it was put in. That second error is an artefact of the first one
  /// having been raised at all, and `takeException` returns a "multiple
  /// exceptions were detected" placeholder rather than either of them.
  Future<List<FlutterErrorDetails>> pumpReporting(
    WidgetTester tester,
    Widget child, {
    Size size = const Size(360, 800),
  }) async {
    final List<FlutterErrorDetails> reported = <FlutterErrorDetails>[];
    final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
    FlutterError.onError = reported.add;
    await pump(tester, child, size: size);
    FlutterError.onError = previous;
    return reported;
  }

  group('a navigation component under a transient layer is refused', () {
    /// What every one of these errors has to say, so a caller who hits it in
    /// their own application is told what to do rather than what happened.
    void expectsTheFix(List<FlutterErrorDetails> reported, String component) {
      expect(
        reported,
        isNotEmpty,
        reason: 'the arrangement that costs the user their navigation for '
            'four seconds has to be refused, not rendered',
      );
      final Object error = reported.first.exception;
      expect(error, isA<FlutterError>());
      final String text = error.toString();
      expect(
        text,
        contains('$component is inside an IuxTransientLayer'),
        reason: 'the error has to name the widget the caller wrote',
      );
      expect(
        text,
        contains('hitTestable = 0'),
        reason: 'the measurement is what makes this more than an opinion',
      );
      expect(
        text,
        contains('The transient layer goes inside the navigation'),
        reason: 'an error that only says "no" leaves the caller guessing',
      );
    }

    testWidgets('IuxAdaptiveNavigation, on a window that takes the bar',
        (WidgetTester tester) async {
      final List<FlutterErrorDetails> reported = await pumpReporting(
        tester,
        IuxTransientLayer(
          message: short,
          onDismissed: () {},
          child: IuxAdaptiveNavigation(
            label: 'Main navigation',
            destinations: destinations,
            selectedIndex: 0,
            onDestinationSelected: (int _) {},
            child: const SizedBox.expand(),
          ),
        ),
      );

      expectsTheFix(reported, 'IuxAdaptiveNavigation');
    });

    testWidgets('IuxAdaptiveNavigation, on a window that takes the rail',
        (WidgetTester tester) async {
      // The same mistake, named the same way, on the device where the notice
      // would not have overlapped anything at 100% text. A caller who was only
      // told about it on a phone would fix it on a phone.
      final List<FlutterErrorDetails> reported = await pumpReporting(
        tester,
        IuxTransientLayer(
          message: short,
          onDismissed: () {},
          child: IuxAdaptiveNavigation(
            label: 'Main navigation',
            destinations: destinations,
            selectedIndex: 0,
            onDestinationSelected: (int _) {},
            child: const SizedBox.expand(),
          ),
        ),
        size: const Size(900, 420),
      );

      expectsTheFix(reported, 'IuxAdaptiveNavigation');
    });

    testWidgets('IuxBottomNavigation placed by hand',
        (WidgetTester tester) async {
      final List<FlutterErrorDetails> reported = await pumpReporting(
        tester,
        IuxTransientLayer(
          message: short,
          onDismissed: () {},
          child: Column(
            children: <Widget>[
              const Expanded(child: SizedBox.expand()),
              IuxBottomNavigation(
                label: 'Main navigation',
                destinations: destinations,
                selectedIndex: 0,
                onDestinationSelected: (int _) {},
              ),
            ],
          ),
        ),
      );

      expectsTheFix(reported, 'IuxBottomNavigation');
    });

    testWidgets('IuxNavigationRail placed by hand',
        (WidgetTester tester) async {
      final List<FlutterErrorDetails> reported = await pumpReporting(
        tester,
        IuxTransientLayer(
          message: short,
          onDismissed: () {},
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              IuxNavigationRail(
                label: 'Main navigation',
                destinations: destinations,
                selectedIndex: 0,
                onDestinationSelected: (int _) {},
              ),
              const Expanded(child: SizedBox.expand()),
            ],
          ),
        ),
        size: const Size(900, 420),
      );

      expectsTheFix(reported, 'IuxNavigationRail');
    });
  });

  group('the arrangements that do not cover a destination are left alone', () {
    testWidgets('the layer inside the navigation', (WidgetTester tester) async {
      await pump(
        tester,
        shell(message: long, onDestinationSelected: (int _) {}),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(IuxBottomNavigation), findsOneWidget);
    });

    testWidgets('the layer beside the bar, as Scaffold arranges it',
        (WidgetTester tester) async {
      // `IuxBottomNavigation`'s own example puts the page in `Scaffold.body`
      // and the bar in `Scaffold.bottomNavigationBar`. A layer wrapped around
      // that page is a sibling of the bar, not an ancestor, and a notice in it
      // cannot reach the bar — so the check must not fire.
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(360, 800)),
          child: MaterialApp(
            theme: IuxTheme.light(),
            home: Scaffold(
              body: IuxTransientLayer(
                message: long,
                onDismissed: () {},
                child: const SizedBox.expand(),
              ),
              bottomNavigationBar: IuxBottomNavigation(
                label: 'Main navigation',
                destinations: destinations,
                selectedIndex: 0,
                onDestinationSelected: (int _) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);
      for (final IuxNavigationDestination destination in destinations) {
        expect(find.text(destination.label).hitTestable(), findsOneWidget);
      }
    });

    testWidgets('a bar rendered as a specimen inside a scroll view',
        (WidgetTester tester) async {
      // The library's own catalog does exactly this: live navigation
      // components inside a `ListView`, under the page's single transient
      // layer. A notice is pinned to the bottom of the *viewport*, and content
      // in a scroll view moves past that edge rather than sitting on it — so
      // the specimen is content, and content is what a notice may cover.
      // Refusing this would refuse `apps/catalog`.
      await pump(
        tester,
        IuxTransientLayer(
          message: long,
          onDismissed: () {},
          child: ListView(
            children: <Widget>[
              const SizedBox(height: 400),
              IuxBottomNavigation(
                label: 'Main sections',
                destinations: destinations,
                selectedIndex: 0,
                onDestinationSelected: (int _) {},
              ),
              const SizedBox(height: 400),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(IuxBottomNavigation), findsOneWidget);
    });

    testWidgets('navigation with no transient layer in the tree at all',
        (WidgetTester tester) async {
      await pump(
        tester,
        IuxAdaptiveNavigation(
          label: 'Main navigation',
          destinations: destinations,
          selectedIndex: 0,
          onDestinationSelected: (int _) {},
          child: const SizedBox.expand(),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('every destination stays reachable while a notice is showing', () {
    /// The measurement, run once per window, text scale and message length.
    ///
    /// Asserted the way IUX-041 found the defect — `hitTestable` on every
    /// destination — and then one step further, because a hit test is a
    /// prediction and a tap is the event: the third destination is tapped and
    /// the section has to change.
    Future<void> measure(
      WidgetTester tester, {
      required Size size,
      required double textScale,
      required IuxTransientMessage message,
    }) async {
      int? chosen;
      await pump(
        tester,
        shell(message: message, onDestinationSelected: (int i) => chosen = i),
        size: size,
        textScale: textScale,
      );

      expect(
        tester.takeException(),
        isNull,
        reason: 'the notice is clipped by the box the navigation left it; '
            'nothing may overflow',
      );

      // Non-vacuous: a test that measured reachability while no notice was on
      // screen would pass on the broken arrangement too.
      expect(find.text(message.text), findsOneWidget);

      final Rect bar = tester.getRect(find.byType(IuxBottomNavigation));
      final Rect notice = tester.getRect(find.text(message.text));
      expect(
        notice.bottom,
        lessThanOrEqualTo(bar.top),
        reason: 'the notice is laid out inside the box above the bar, so its '
            'bottom edge is the bar\'s top edge at worst — this is the '
            'geometry the defect inverted',
      );

      for (final IuxNavigationDestination destination in destinations) {
        expect(
          find.text(destination.label).hitTestable(),
          findsOneWidget,
          reason: '"${destination.label}" is under the notice at '
              '${size.width.toInt()}x${size.height.toInt()} @ '
              '${(textScale * 100).toInt()}% text',
        );
      }

      await tester.tap(find.text('Settings'));
      await tester.pump();
      expect(
        chosen,
        2,
        reason: 'a hit test that passes while the tap is swallowed is the '
            'failure this defect actually was',
      );
    }

    for (final Size size in <Size>[
      const Size(320, 640),
      const Size(360, 800),
    ]) {
      final String window = '${size.width.toInt()}x${size.height.toInt()}';
      for (final double scale in <double>[1, 1.5, 2, 3]) {
        final String at = '${(scale * 100).toInt()}% text';

        testWidgets('$window at $at, one line', (WidgetTester tester) async {
          await measure(
            tester,
            size: size,
            textScale: scale,
            message: short,
          );
        });

        testWidgets('$window at $at, wrapped over several lines',
            (WidgetTester tester) async {
          await measure(
            tester,
            size: size,
            textScale: scale,
            message: long,
          );
        });
      }
    }
  });

  testWidgets('the rail keeps its destinations too',
      (WidgetTester tester) async {
    // The same guarantee on the other arrangement. The notice is centred on the
    // reading measure, so at 100% it clears a rail on the start edge anyway;
    // at 200% the measure is wider than the window and the only thing keeping
    // the two apart is that the layer is inside the navigation.
    int? chosen;
    await pump(
      tester,
      shell(message: long, onDestinationSelected: (int i) => chosen = i),
      size: const Size(900, 420),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(IuxNavigationRail), findsOneWidget);
    expect(find.text(long.text), findsOneWidget);

    for (final IuxNavigationDestination destination in destinations) {
      expect(find.text(destination.label).hitTestable(), findsOneWidget);
    }

    await tester.tap(find.text('Settings'));
    await tester.pump();
    expect(chosen, 2);
  });
}
