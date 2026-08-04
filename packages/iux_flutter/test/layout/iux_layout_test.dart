import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Size size = const Size(400, 800),
    double textScale = 1,
    IuxAccessibilityProfile profile = const IuxAccessibilityProfile(),
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
          theme: IuxTheme.light(profile: profile),
          home: Scaffold(body: child),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('layout classes', () {
    test('follow the Android window size class thresholds', () {
      expect(IuxBreakpoints.classFor(359), IuxLayoutClass.compact);
      expect(IuxBreakpoints.classFor(599), IuxLayoutClass.compact);
      expect(IuxBreakpoints.classFor(600), IuxLayoutClass.medium);
      expect(IuxBreakpoints.classFor(839), IuxLayoutClass.medium);
      expect(IuxBreakpoints.classFor(840), IuxLayoutClass.expanded);
    });

    testWidgets('are measured from the available width, not the screen',
        (WidgetTester tester) async {
      late IuxLayoutClass resolved;
      await pump(
        tester,
        Builder(
          builder: (BuildContext context) {
            resolved = IuxBreakpoints.of(context);
            return const SizedBox.shrink();
          },
        ),
        size: const Size(400, 800),
      );
      expect(resolved, IuxLayoutClass.compact);
    });
  });

  group('responsive values', () {
    test('narrower classes fall back so compact can never be forgotten', () {
      const IuxResponsiveValue<int> onlyCompact = IuxResponsiveValue<int>(
        compact: 1,
      );
      expect(onlyCompact.resolveFor(IuxLayoutClass.compact), 1);
      expect(onlyCompact.resolveFor(IuxLayoutClass.medium), 1);
      expect(onlyCompact.resolveFor(IuxLayoutClass.expanded), 1);

      const IuxResponsiveValue<int> upTo = IuxResponsiveValue<int>(
        compact: 1,
        medium: 2,
      );
      expect(upTo.resolveFor(IuxLayoutClass.expanded), 2);
    });

    test('is a value type', () {
      expect(
        const IuxResponsiveValue<int>(compact: 1, medium: 2),
        equals(const IuxResponsiveValue<int>(compact: 1, medium: 2)),
      );
    });
  });

  group('content width', () {
    testWidgets('grows with the user text size', (WidgetTester tester) async {
      // A fixed pixel cap silently halves the characters per line when a user
      // doubles their text size, which is the opposite of what they asked for.
      late double? normal;
      late double? enlarged;

      await pump(
        tester,
        Builder(
          builder: (BuildContext context) {
            normal = IuxContentWidthResolver.maxWidthFor(
              context,
              IuxContentWidth.reading,
            );
            return const SizedBox.shrink();
          },
        ),
      );
      await pump(
        tester,
        Builder(
          builder: (BuildContext context) {
            enlarged = IuxContentWidthResolver.maxWidthFor(
              context,
              IuxContentWidth.reading,
            );
            return const SizedBox.shrink();
          },
        ),
        textScale: 2,
      );

      expect(enlarged, greaterThan(normal!));
    });

    testWidgets('fluid content is never capped', (WidgetTester tester) async {
      late double? maxWidth;
      await pump(
        tester,
        Builder(
          builder: (BuildContext context) {
            maxWidth = IuxContentWidthResolver.maxWidthFor(
              context,
              IuxContentWidth.fluid,
            );
            return const SizedBox.shrink();
          },
        ),
      );
      expect(maxWidth, isNull);
    });

    testWidgets('a narrow screen is never made narrower',
        (WidgetTester tester) async {
      await pump(
        tester,
        const IuxReadableWidth(
          width: IuxContentWidth.narrow,
          child: SizedBox(key: Key('content'), height: 10),
        ),
        size: const Size(320, 640),
      );
      // The cap is above the viewport, so the child simply fills it.
      expect(
        tester.getSize(find.byKey(const Key('content'))).width,
        lessThanOrEqualTo(320),
      );
    });
  });

  group('target spacing', () {
    testWidgets('adjacent targets are separated by at least the floor',
        (WidgetTester tester) async {
      // Target size alone does not prevent mis-taps: two 48-pixel targets
      // touching each other still produce them.
      await pump(
        tester,
        const IuxTargetSpacing(
          axis: Axis.horizontal,
          children: <Widget>[
            SizedBox(key: Key('a'), width: 48, height: 48),
            SizedBox(key: Key('b'), width: 48, height: 48),
          ],
        ),
      );

      final Rect a = tester.getRect(find.byKey(const Key('a')));
      final Rect b = tester.getRect(find.byKey(const Key('b')));
      expect(b.left - a.right, greaterThanOrEqualTo(kIuxMinimumTargetSpacing));
    });

    testWidgets('a smaller requested spacing is raised to the floor',
        (WidgetTester tester) async {
      await pump(
        tester,
        const IuxTargetSpacing(
          axis: Axis.horizontal,
          spacing: 2,
          children: <Widget>[
            SizedBox(key: Key('a'), width: 48, height: 48),
            SizedBox(key: Key('b'), width: 48, height: 48),
          ],
        ),
      );
      final Rect a = tester.getRect(find.byKey(const Key('a')));
      final Rect b = tester.getRect(find.byKey(const Key('b')));
      expect(b.left - a.right, greaterThanOrEqualTo(kIuxMinimumTargetSpacing));
    });

    testWidgets('controls wrap instead of overflowing a narrow screen',
        (WidgetTester tester) async {
      await pump(
        tester,
        const IuxTargetSpacing(
          axis: Axis.horizontal,
          children: <Widget>[
            SizedBox(width: 200, height: 48),
            SizedBox(width: 200, height: 48),
          ],
        ),
        size: const Size(320, 640),
      );
      expect(tester.takeException(), isNull);
    });
  });

  // IUX-EXPAND-CRASH-001. Two stacked full-width buttons is the most ordinary
  // thing anyone writes, and the primitive that exists to keep adjacent
  // targets 8 px apart was the one arrangement that threw. The caller was
  // pushed onto a hand-written `Column` and an `IuxGap`, which lays out and
  // guarantees nothing.
  //
  // Every case clears the element tree first. `DebugOverflowIndicatorMixin`
  // reports a render object's overflow once per lifetime, so a loop that
  // reuses the tree and asserts on exceptions passes vacuously after the first
  // pass (IUX-QA-VACUOUS-003).
  group('stacking full-width targets', () {
    const List<double> scales = <double>[1, 1.5, 2, 3];

    Widget expanding(String label) => IuxButton(
          label: label,
          action: IuxActionDescriptor(
            semantics: IuxActionSemantics(label: label),
          ),
          expand: true,
          onActivate: () {},
        );

    Widget plain(String label) => IuxButton(
          label: label,
          action: IuxActionDescriptor(
            semantics: IuxActionSemantics(label: label),
          ),
          onActivate: () {},
        );

    Future<void> clear(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }

    testWidgets('two full-width buttons stack, at 100/150/200/300% on 320',
        (WidgetTester tester) async {
      for (final double scale in scales) {
        await clear(tester);
        await pump(
          tester,
          SingleChildScrollView(
            child: IuxTargetSpacing(
              children: <Widget>[
                expanding('Save'),
                expanding('Discard everything typed so far'),
              ],
            ),
          ),
          size: const Size(320, 640),
          textScale: scale,
        );
        expect(tester.takeException(), isNull, reason: 'at $scale');

        // Both took the whole 320, so expand was honoured rather than quietly
        // degraded to the width of the label — which at 100% would leave
        // "Save" at 89 and the two controls a different size.
        for (int i = 0; i < 2; i++) {
          expect(
            tester.getSize(find.byType(IuxButton).at(i)).width,
            320,
            reason: 'button $i at $scale did not take the width',
          );
        }

        // Measured between the hit areas, which is what a finger meets. The
        // 4 px the focus ring reserves on each side is not interactive, so the
        // separation comes out above the floor rather than equal to it.
        final Rect first = tester.getRect(find.byType(AnimatedContainer).at(0));
        final Rect second =
            tester.getRect(find.byType(AnimatedContainer).at(1));
        expect(
          second.top - first.bottom,
          greaterThanOrEqualTo(kIuxMinimumTargetSpacing),
          reason: 'at $scale',
        );
      }
    });

    testWidgets('the floor still governs the vertical axis',
        (WidgetTester tester) async {
      // The point of routing the caller back here rather than to a Column and
      // a gap: a smaller request is raised. The smallest step on the spacing
      // scale is 4, half the floor, and nothing raises that.
      await clear(tester);
      await pump(
        tester,
        const IuxTargetSpacing(
          spacing: 2,
          children: <Widget>[
            SizedBox(key: Key('a'), width: 200, height: 48),
            SizedBox(key: Key('b'), width: 200, height: 48),
          ],
        ),
        size: const Size(320, 640),
      );
      final Rect a = tester.getRect(find.byKey(const Key('a')));
      final Rect b = tester.getRect(find.byKey(const Key('b')));
      expect(b.top - a.bottom, greaterThanOrEqualTo(kIuxMinimumTargetSpacing));
    });

    testWidgets('a child that does not ask for the width keeps its own',
        (WidgetTester tester) async {
      // The cross alignment has to stay `start`. Stretching every child would
      // fix the crash by making every stacked control full width, which is a
      // different layout than the caller wrote.
      await clear(tester);
      await pump(
        tester,
        SingleChildScrollView(
          child: IuxTargetSpacing(
            children: <Widget>[plain('Save'), plain('Discard')],
          ),
        ),
        size: const Size(320, 640),
      );
      final Rect a = tester.getRect(find.byType(AnimatedContainer).at(0));
      final Rect b = tester.getRect(find.byType(AnimatedContainer).at(1));
      expect(a.width, lessThan(320), reason: 'a plain button was stretched');
      expect(a.width, isNot(equals(b.width)), reason: 'both were stretched');
      expect(a.left, b.left, reason: 'the two no longer share an edge');
    });

    testWidgets('the horizontal axis keeps the floor whether or not it fits',
        (WidgetTester tester) async {
      for (final double scale in scales) {
        await clear(tester);
        await pump(
          tester,
          SingleChildScrollView(
            child: IuxTargetSpacing(
              axis: Axis.horizontal,
              children: <Widget>[plain('Keep'), plain('Delete')],
            ),
          ),
          size: const Size(320, 640),
          textScale: scale,
        );
        expect(tester.takeException(), isNull, reason: 'at $scale');

        // Side by side at 100%, on two lines from 150% up. Either way the
        // separation is the same floor, so the pair is never a thumb's width
        // apart on whichever axis it happened to land.
        final Rect a = tester.getRect(find.byType(AnimatedContainer).at(0));
        final Rect b = tester.getRect(find.byType(AnimatedContainer).at(1));
        final double separation =
            b.left >= a.right ? b.left - a.right : b.top - a.bottom;
        expect(
          separation,
          greaterThanOrEqualTo(kIuxMinimumTargetSpacing),
          reason: 'at $scale',
        );
      }
    });

    testWidgets('a vertical stack too tall for its box says so',
        (WidgetTester tester) async {
      // This is the measurement that chose a Column over a vertical Wrap. The
      // Wrap moved the overflow *sideways and in silence*: in this same
      // 320-wide box the third target landed at x 256.8–388.5, 68 px past the
      // right edge, and nothing was reported. A target nobody can reach and no
      // test can see is worse than a loud overflow, which is a bug somebody
      // fixes.
      await clear(tester);
      await pump(
        tester,
        const Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 320,
            height: 100,
            child: IuxTargetSpacing(
              children: <Widget>[
                SizedBox(key: Key('a'), width: 120, height: 48),
                SizedBox(key: Key('b'), width: 120, height: 48),
                SizedBox(key: Key('c'), width: 120, height: 48),
              ],
            ),
          ),
        ),
        size: const Size(320, 640),
      );

      for (final String key in <String>['a', 'b', 'c']) {
        expect(
          tester.getRect(find.byKey(Key(key))).right,
          lessThanOrEqualTo(320),
          reason: '$key left the box it was given',
        );
      }
      expect(
        tester.takeException(),
        isNotNull,
        reason: 'three 48-pixel targets do not fit in 100 px, and a layout '
            'that cannot fit them has to say so rather than put one of them '
            'somewhere the user cannot reach',
      );
    });

    testWidgets('expand with no width on offer names the way out',
        (WidgetTester tester) async {
      // The failure stays loud — quietly ignoring what the caller asked for
      // would be worse — but it now carries the arrangement that works, which
      // is the whole reason this defect cost anybody a day.
      await clear(tester);
      final List<FlutterErrorDetails> reported = <FlutterErrorDetails>[];
      final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
      FlutterError.onError = reported.add;
      addTearDown(() => FlutterError.onError = previous);

      await pump(
        tester,
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: expanding('Continue'),
        ),
        size: const Size(320, 640),
      );
      FlutterError.onError = previous;

      expect(reported, isNotEmpty);
      final String message = reported.first.exception.toString();
      expect(message, contains('IuxButton(expand: true)'));
      expect(
        message,
        contains('IuxTargetSpacing'),
        reason: 'a caller stuck here has to be told where the working '
            'arrangement is, not just which constraint was invalid',
      );
    });
  });

  group('gaps and insets follow density', () {
    testWidgets('a gap shrinks with a compact density',
        (WidgetTester tester) async {
      await pump(
        tester,
        const Column(children: <Widget>[IuxGap.standard()]),
      );
      final double standard = tester.getSize(find.byType(IuxGap)).height;

      await pump(
        tester,
        const Column(children: <Widget>[IuxGap.standard()]),
        profile: const IuxAccessibilityProfile(density: IuxDensity.compact),
      );
      final double compact = tester.getSize(find.byType(IuxGap)).height;

      expect(compact, lessThan(standard));
    });

    testWidgets('page insets follow density', (WidgetTester tester) async {
      late EdgeInsets standard;
      late EdgeInsets comfortable;

      await pump(
        tester,
        Builder(
          builder: (BuildContext context) {
            standard = IuxInsets.page(context);
            return const SizedBox.shrink();
          },
        ),
      );
      await pump(
        tester,
        Builder(
          builder: (BuildContext context) {
            comfortable = IuxInsets.page(context);
            return const SizedBox.shrink();
          },
        ),
        profile: const IuxAccessibilityProfile(
          density: IuxDensity.comfortable,
        ),
      );

      expect(comfortable.left, greaterThan(standard.left));
    });
  });

  group('surface', () {
    testWidgets('resolves its colour from the role, never from a literal',
        (WidgetTester tester) async {
      late IuxSemanticColors colors;
      await pump(
        tester,
        Builder(
          builder: (BuildContext context) {
            colors = IuxSemanticColors.of(context);
            return const IuxSurface(
              role: IuxSurfaceRole.raised,
              child: SizedBox(width: 10, height: 10),
            );
          },
        ),
      );

      final DecoratedBox box = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(IuxSurface),
          matching: find.byType(DecoratedBox),
        ),
      );
      expect(
        (box.decoration as BoxDecoration).color,
        colors.surface.raised,
      );
    });

    testWidgets('casts no shadow when stimulation is reduced',
        (WidgetTester tester) async {
      await pump(
        tester,
        const IuxSurface(
          elevated: true,
          child: SizedBox(width: 10, height: 10),
        ),
        profile: const IuxAccessibilityProfile(
          visualStimulation: IuxVisualStimulation.reduced,
        ),
      );

      final DecoratedBox box = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(IuxSurface),
          matching: find.byType(DecoratedBox),
        ),
      );
      expect((box.decoration as BoxDecoration).boxShadow, isNull);
    });

    testWidgets('adds no semantics of its own', (WidgetTester tester) async {
      // A surface is a background, not a card component and not a button.
      await pump(
        tester,
        const IuxSurface(
          child: Text('Content', textDirection: TextDirection.ltr),
        ),
      );
      expect(find.bySemanticsLabel('Content'), findsOneWidget);
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Content'))
            .flagsCollection
            .isButton,
        isFalse,
      );
    });
  });

  group('section', () {
    testWidgets('exposes its title as a header', (WidgetTester tester) async {
      await pump(
        tester,
        const IuxSection(
          title: 'Delivery',
          children: <Widget>[SizedBox(height: 10)],
        ),
      );
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Delivery'))
            .flagsCollection
            .isHeader,
        isTrue,
      );
    });

    testWidgets('a heading and its action wrap rather than clip',
        (WidgetTester tester) async {
      await pump(
        tester,
        const IuxSection(
          title: 'A rather long section heading that will not fit',
          trailing: SizedBox(width: 180, height: 48),
          children: <Widget>[SizedBox(height: 10)],
        ),
        size: const Size(320, 640),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('page', () {
    testWidgets('scrolls by default', (WidgetTester tester) async {
      await pump(
        tester,
        const IuxPage(child: SizedBox(height: 4000)),
      );
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('survives a tall content at a large text scale',
        (WidgetTester tester) async {
      await pump(
        tester,
        const IuxPage(
          child: Column(
            children: <Widget>[
              Text('A line of content', textDirection: TextDirection.ltr),
              Text('Another line', textDirection: TextDirection.ltr),
            ],
          ),
        ),
        size: const Size(320, 480),
        textScale: 3,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('consumes only the insets it was asked to',
        (WidgetTester tester) async {
      // Applying SafeArea everywhere is how double padding happens.
      await pump(
        tester,
        const IuxPage(
          insets: IuxPageInsets.none,
          child: SizedBox(height: 10),
        ),
      );
      final SafeArea area = tester.widget<SafeArea>(find.byType(SafeArea));
      expect(area.top, isFalse);
      expect(area.bottom, isFalse);
      expect(area.left, isFalse);
    });

    testWidgets('a footer stays out of the scrolling area',
        (WidgetTester tester) async {
      await pump(
        tester,
        const IuxPage(
          child: SizedBox(height: 4000),
          footer: SizedBox(key: Key('footer'), height: 48),
        ),
      );
      final Rect footer = tester.getRect(find.byKey(const Key('footer')));
      expect(footer.height, greaterThan(0));
      expect(
        find.descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.byKey(const Key('footer')),
        ),
        findsNothing,
        reason: 'a pinned action must not require scrolling to the end',
      );
    });

    testWidgets('composes with a Scaffold rather than replacing it',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: IuxTheme.light(),
          home: Scaffold(
            appBar: AppBar(title: const Text('Orders')),
            body: const IuxPage(child: SizedBox(height: 10)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(IuxPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('no horizontal overflow on a small screen', () {
    testWidgets('a full composition holds at 320 by 480 and 2x text',
        (WidgetTester tester) async {
      await pump(
        tester,
        IuxPage(
          child: IuxSection(
            title: 'Payment method',
            description: 'Choose how you would like to pay for this order.',
            children: <Widget>[
              const IuxSurface(
                bordered: true,
                padding: EdgeInsets.all(16),
                child: Text(
                  'A description long enough to need wrapping on a narrow '
                  'screen at an enlarged text size.',
                  textDirection: TextDirection.ltr,
                ),
              ),
              const IuxGap.tight(),
              IuxTargetSpacing(
                axis: Axis.horizontal,
                children: <Widget>[
                  Container(
                      width: 140, height: 48, color: const Color(0xFF000000)),
                  Container(
                      width: 140, height: 48, color: const Color(0xFF000000)),
                ],
              ),
            ],
          ),
        ),
        size: const Size(320, 480),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
