import 'dart:ui' show CheckedState;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

/// The four theme profiles every visual guarantee has to survive.
const List<IuxThemeConfiguration> _profiles = <IuxThemeConfiguration>[
  IuxThemeConfiguration(),
  IuxThemeConfiguration(brightness: Brightness.dark),
  IuxThemeConfiguration(
    profile: IuxAccessibilityProfile(contrast: IuxContrast.high),
  ),
  IuxThemeConfiguration(
    brightness: Brightness.dark,
    profile: IuxAccessibilityProfile(contrast: IuxContrast.high),
  ),
];

const List<IuxDensity> _densities = <IuxDensity>[
  IuxDensity.compact,
  IuxDensity.standard,
  IuxDensity.comfortable,
];

/// The screen the navigation is placed beside, so its box can be measured.
const Key _content = Key('content');

/// A phone in landscape: the window the rail exists for.
const Size _landscapePhone = Size(915, 412);

/// A phone upright, at the narrowest width IUX supports.
const Size _smallPhone = Size(320, 640);

const List<String> _names = <String>[
  'Home',
  'Messages',
  'Search',
  'Alerts',
  'Account',
];

const List<IconData> _glyphs = <IconData>[
  Icons.home_outlined,
  Icons.mail_outline,
  Icons.search_outlined,
  Icons.notifications_outlined,
  Icons.person_outline,
];

void main() {
  List<IuxNavigationDestination> destinations(
    int count, {
    bool badge = false,
    String? longName,
  }) =>
      <IuxNavigationDestination>[
        for (int index = 0; index < count; index++)
          IuxNavigationDestination(
            label: index == 1 && longName != null ? longName : _names[index],
            icon: _glyphs[index],
            selectedIcon: index == 0 ? Icons.home : null,
            badge: badge && index == 1
                ? const IuxBadge.count(count: '3', label: '3 unread messages')
                : null,
          ),
      ];

  Future<void> pump(
    WidgetTester tester,
    Widget body, {
    IuxThemeConfiguration configuration = const IuxThemeConfiguration(),
    TextDirection direction = TextDirection.ltr,
    double textScale = 1,
    Size size = _landscapePhone,
    EdgeInsets padding = EdgeInsets.zero,
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
          theme: IuxTheme.fromConfiguration(configuration),
          home: Directionality(
            textDirection: direction,
            child: Scaffold(body: body),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// A rail beside a page, which is the only way a rail is ever used.
  Widget framed({
    int count = 5,
    int selectedIndex = 0,
    bool badge = false,
    String? longName,
    ValueChanged<int>? onDestinationSelected,
  }) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          IuxNavigationRail(
            label: 'Main navigation',
            destinations: destinations(count, badge: badge, longName: longName),
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected ?? (_) {},
          ),
          const Expanded(child: SizedBox.expand()),
        ],
      );

  Widget adaptive({
    int selectedIndex = 0,
    ValueChanged<int>? onDestinationSelected,
    Widget? child,
  }) =>
      IuxAdaptiveNavigation(
        label: 'Main navigation',
        destinations: destinations(5),
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected ?? (_) {},
        child: child ?? const SizedBox.expand(),
      );

  /// The interactive region of each destination, in order.
  ///
  /// Measured on the gesture detector, the widget that actually responds: a
  /// target measured anywhere else is a number nobody can tap.
  Finder cells() => find.descendant(
        of: find.byType(IuxNavigationRail),
        matching: find.byType(GestureDetector),
      );

  /// The indicator behind one destination's glyph.
  Finder indicator(int index) => find
      .descendant(of: cells().at(index), matching: find.byType(AnimatedOpacity))
      .first;

  AnimatedOpacity indicatorOf(WidgetTester tester, int index) =>
      tester.widget<AnimatedOpacity>(indicator(index));

  /// What a screen reader announces for the destination named [name], merged.
  SemanticsData dataOf(WidgetTester tester, String name) =>
      tester.getSemantics(find.text(name)).getSemanticsData();

  /// How many separate stops a screen reader finds below [node].
  int stopsBelow(SemanticsNode node) {
    int count = 0;
    void visit(SemanticsNode parent) {
      parent.visitChildren((SemanticsNode child) {
        if (!child.isMergedIntoParent) count++;
        visit(child);
        return true;
      });
    }

    visit(node);
    return count;
  }

  /// [IuxNavigationRail.widthFor] evaluated under the given conditions.
  Future<double> measuredWidth(
    WidgetTester tester, {
    double textScale = 1,
    int count = 5,
    IuxThemeConfiguration configuration = const IuxThemeConfiguration(),
  }) async {
    late double width;
    await pump(
      tester,
      Builder(
        builder: (BuildContext context) {
          width = IuxNavigationRail.widthFor(context, destinations(count));
          return const SizedBox();
        },
      ),
      textScale: textScale,
      configuration: configuration,
    );
    return width;
  }

  group('a rail refuses the configurations that cannot work', () {
    IuxNavigationRail build(
      List<IuxNavigationDestination> items, {
      String label = 'Main navigation',
      int selectedIndex = 0,
    }) =>
        IuxNavigationRail(
          label: label,
          destinations: items,
          selectedIndex: selectedIndex,
          onDestinationSelected: (_) {},
        );

    test('two destinations are refused', () {
      expect(() => build(destinations(2)), throwsAssertionError);
    });

    test('six destinations are refused', () {
      expect(
        () => build(<IuxNavigationDestination>[
          ...destinations(5),
          const IuxNavigationDestination(
            label: 'Settings',
            icon: Icons.settings_outlined,
          ),
        ]),
        throwsAssertionError,
      );
    });

    test('three, four and five destinations are accepted', () {
      for (int count = 3; count <= 5; count++) {
        expect(() => build(destinations(count)), returnsNormally);
      }
    });

    test('a current destination outside the set is refused', () {
      for (final int index in <int>[-1, 3]) {
        expect(
          () => build(destinations(3), selectedIndex: index),
          throwsAssertionError,
        );
      }
    });

    test('two destinations sharing a name are refused', () {
      expect(
        () => build(const <IuxNavigationDestination>[
          IuxNavigationDestination(label: 'Home', icon: Icons.home_outlined),
          IuxNavigationDestination(label: 'Home', icon: Icons.mail_outline),
          IuxNavigationDestination(
              label: 'Account', icon: Icons.person_outline),
        ]),
        throwsAssertionError,
      );
    });

    test('an unnamed rail is refused', () {
      expect(
        () => build(destinations(3), label: ''),
        throwsAssertionError,
      );
    });

    test('the rail refuses exactly what the bar refuses', () {
      // The two arrangements are one navigation. A set the rail accepted and
      // the bar refused is a configuration that works until the device rotates.
      for (final int count in <int>[2, 6]) {
        final List<IuxNavigationDestination> items = count == 6
            ? <IuxNavigationDestination>[
                ...destinations(5),
                const IuxNavigationDestination(
                  label: 'Settings',
                  icon: Icons.settings_outlined,
                ),
              ]
            : destinations(count);
        expect(() => build(items), throwsAssertionError);
        expect(
          () => IuxBottomNavigation(
            label: 'Main navigation',
            destinations: items,
            selectedIndex: 0,
            onDestinationSelected: (_) {},
          ),
          throwsAssertionError,
        );
      }
    });
  });

  group('the current destination is announced, not only coloured', () {
    testWidgets('the current destination is checked and the others are not',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester, framed(selectedIndex: 2));

      expect(
        dataOf(tester, 'Search').flagsCollection.isChecked,
        CheckedState.isTrue,
      );
      for (final String other in <String>['Home', 'Messages', 'Alerts']) {
        expect(
          dataOf(tester, other).flagsCollection.isChecked,
          CheckedState.isFalse,
          reason: 'a destination that says nothing about its state leaves the '
              'user to sweep the whole rail to find the one that did',
        );
      }

      handle.dispose();
    });

    testWidgets('every destination belongs to a mutually exclusive group',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester, framed());

      for (final String name in _names) {
        expect(
          dataOf(tester, name).flagsCollection.isInMutuallyExclusiveGroup,
          isTrue,
          reason: 'without it the platform cannot say "2 of 5"',
        );
      }

      handle.dispose();
    });

    testWidgets('the rail itself is announced as a named group',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester, framed());

      final SemanticsNode group =
          tester.getSemantics(find.bySemanticsLabel('Main navigation'));
      expect(
        group.getSemanticsData().role,
        SemanticsRole.radioGroup,
        reason: 'the rail and the bar must announce the same thing; a user who '
            'learns it on a phone hears it again on a tablet',
      );
      expect(group.label, 'Main navigation');

      handle.dispose();
    });

    testWidgets('a screen reader can activate a destination',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final List<int> chosen = <int>[];
      await pump(tester, framed(onDestinationSelected: chosen.add));

      expect(
        dataOf(tester, 'Alerts').hasAction(SemanticsAction.tap),
        isTrue,
        reason: 'a destination announced correctly and inert is a control the '
            'user can find and cannot use',
      );

      handle.dispose();
      expect(chosen, isEmpty);
    });

    testWidgets('a destination is one stop, badge included',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester, framed(badge: true));

      final String announced = dataOf(tester, 'Messages').label;
      expect(announced, contains('Messages'));
      expect(
        announced,
        contains('3 unread messages'),
        reason: '"3" alone tells a screen-reader user how many of nothing',
      );
      expect(stopsBelow(tester.getSemantics(find.text('Messages'))), 0);
      expect(
        dataOf(tester, 'Home').label,
        'Home',
        reason: 'the glyph is decorative; announcing it reads every section '
            'twice',
      );

      handle.dispose();
    });

    testWidgets('the mark is a shape, and it is there in every theme profile',
        (WidgetTester tester) async {
      for (final IuxThemeConfiguration configuration in _profiles) {
        await pump(
          tester,
          framed(selectedIndex: 3),
          configuration: configuration,
        );

        for (int index = 0; index < 5; index++) {
          expect(
            indicatorOf(tester, index).opacity,
            index == 3 ? 1 : 0,
            reason: 'the indicator is what says which destination is current '
                'in $configuration; a hue alone would not',
          );
        }
      }
    });

    testWidgets('the indicator is bounded, so it survives a monochrome screen',
        (WidgetTester tester) async {
      await pump(tester, framed(selectedIndex: 1));

      final DecoratedBox box = tester.widget<DecoratedBox>(
        find
            .descendant(of: indicator(1), matching: find.byType(DecoratedBox))
            .first,
      );
      final BoxDecoration decoration = box.decoration as BoxDecoration;

      expect(decoration.border, isNotNull);
      expect(decoration.borderRadius, isNotNull);
    });

    testWidgets('choosing a destination does not resize it',
        (WidgetTester tester) async {
      await pump(tester, framed(selectedIndex: 0));
      final List<Rect> before = <Rect>[
        for (int index = 0; index < 5; index++)
          tester.getRect(cells().at(index))
      ];

      await pump(tester, framed(selectedIndex: 4));
      final List<Rect> after = <Rect>[
        for (int index = 0; index < 5; index++)
          tester.getRect(cells().at(index))
      ];

      expect(after, before);
    });
  });

  group('it is as wide as its longest name, and no wider', () {
    testWidgets('the widest name is on one line, at every text size',
        (WidgetTester tester) async {
      // The regression that shipped in the first draft: `widthFor` measured
      // `tokens.labelStyle` alone, while the rendered Text merges that style
      // over the ambient DefaultTextStyle and picks up its letter spacing. A
      // quarter of a pixel per character was enough to wrap the longest name in
      // the rail that had just been sized for it — the exact failure the
      // measurement exists to prevent, produced by the measurement.
      for (final double scale in <double>[1, 1.5, 2, 3]) {
        await pump(tester, framed(), textScale: scale);

        final double shortest = tester.getSize(find.text('Home')).height;
        for (final String name in _names) {
          expect(
            tester.getSize(find.text(name)).height,
            shortest,
            reason: '"$name" took more than one line at scale $scale in a rail '
                'measured from its own width',
          );
        }
      }
    });

    testWidgets('the rail takes exactly the width it measured',
        (WidgetTester tester) async {
      final double expected = await measuredWidth(tester);
      await pump(tester, framed());

      expect(tester.getRect(find.byType(IuxNavigationRail)).width, expected);
    });

    testWidgets('the width follows the text size, not a constant',
        (WidgetTester tester) async {
      final double single = await measuredWidth(tester);
      final double doubled = await measuredWidth(tester, textScale: 2);

      expect(
        doubled,
        greaterThan(single * 1.5),
        reason: 'a constant width would be wrong for every user who enlarged '
            'their text, which is the user the rail is measured for',
      );
    });

    testWidgets('a name longer than the reading measure is capped and wraps',
        (WidgetTester tester) async {
      late double cap;
      await pump(
        tester,
        Builder(
          builder: (BuildContext context) {
            cap = IuxContentWidthResolver.maxWidthFor(
              context,
              IuxContentWidth.narrow,
            )!;
            return const SizedBox();
          },
        ),
      );

      await pump(
        tester,
        framed(longName: 'Notifications and reminders and other things'),
      );

      expect(
        tester.getRect(find.byType(IuxNavigationRail)).width,
        lessThanOrEqualTo(cap),
        reason: 'an uncapped rail is an overflow waiting for a call site to '
            'write a sentence where a name belongs',
      );
      expect(
        tester
            .getSize(find.text('Notifications and reminders and other things'))
            .height,
        greaterThan(tester.getSize(find.text('Home')).height),
        reason: 'past the cap the name wraps rather than being cut',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('names are never truncated', (WidgetTester tester) async {
      for (final double scale in <double>[1, 1.5, 2]) {
        await pump(
          tester,
          framed(longName: 'Notifications and reminders'),
          textScale: scale,
        );

        for (final Element element in find.byType(Text).evaluate()) {
          final Text text = element.widget as Text;
          expect(text.maxLines, isNull, reason: 'at scale $scale');
          expect(text.overflow, isNot(TextOverflow.ellipsis));
        }
      }
    });

    testWidgets('every name is drawn, current or not',
        (WidgetTester tester) async {
      await pump(tester, framed(selectedIndex: 0));
      for (final String name in _names) {
        expect(find.text(name), findsOneWidget);
      }
    });

    testWidgets('a rail too tall for the window scrolls rather than clipping',
        (WidgetTester tester) async {
      // Five destinations at 200% need 580 pixels against the 412 a landscape
      // phone has. A destination the user must scroll to is one they may not
      // find; one that is not built is one they certainly will not.
      await pump(tester, framed(), textScale: 2);

      expect(tester.takeException(), isNull);
      for (final String name in _names) {
        expect(find.text(name), findsOneWidget);
      }
      expect(
        tester.getRect(find.byType(IuxNavigationRail)).height,
        lessThanOrEqualTo(_landscapePhone.height),
      );
      expect(find.byType(Scrollable), findsWidgets);
    });
  });

  group('targets meet the floor, at every density', () {
    testWidgets('every destination meets the floor in both dimensions',
        (WidgetTester tester) async {
      for (final IuxDensity density in _densities) {
        for (final IuxTouchTargetPreference target
            in IuxTouchTargetPreference.values) {
          await pump(
            tester,
            framed(),
            configuration: IuxThemeConfiguration(
              profile: IuxAccessibilityProfile(
                density: density,
                touchTarget: target,
              ),
            ),
          );

          final double floor = target == IuxTouchTargetPreference.comfortable
              ? IuxTouchTarget.comfortable
              : IuxTouchTarget.minimum;

          for (int index = 0; index < 5; index++) {
            final Rect cell = tester.getRect(cells().at(index));
            expect(
              cell.width,
              greaterThanOrEqualTo(floor),
              reason: 'destination $index at ${density.name}/${target.name}',
            );
            expect(
              cell.height,
              greaterThanOrEqualTo(floor),
              reason: 'destination $index at ${density.name}/${target.name}',
            );
          }
        }
      }
    });

    testWidgets('the floor still holds once text is enlarged',
        (WidgetTester tester) async {
      for (final double scale in <double>[1.5, 2]) {
        await pump(tester, framed(), textScale: scale);

        for (int index = 0; index < 5; index++) {
          final Rect cell = tester.getRect(cells().at(index));
          expect(cell.width, greaterThanOrEqualTo(IuxTouchTarget.minimum));
          expect(cell.height, greaterThanOrEqualTo(IuxTouchTarget.minimum));
        }
      }
    });

    testWidgets('destinations tile the rail, leaving no dead strip',
        (WidgetTester tester) async {
      await pump(tester, framed());

      final Rect railRect = tester.getRect(find.byType(IuxNavigationRail));
      final List<Rect> rects = <Rect>[
        for (int index = 0; index < 5; index++)
          tester.getRect(cells().at(index))
      ];

      for (int index = 0; index < 4; index++) {
        expect(
          rects[index].bottom,
          closeTo(rects[index + 1].top, 0.01),
          reason: 'a gap belonging to neither destination is a strip where a '
              'tap does nothing at all',
        );
      }
      for (final Rect cell in rects) {
        expect(
          cell.width,
          closeTo(railRect.width, 0.01),
          reason: 'a destination narrower than the rail leaves a column beside '
              'it that looks tappable and is not',
        );
      }
    });
  });

  group('the parent owns where the user is', () {
    testWidgets('choosing a destination reports its index and moves nothing',
        (WidgetTester tester) async {
      final List<int> chosen = <int>[];
      await pump(tester, framed(onDestinationSelected: chosen.add));

      await tester.tap(find.text('Alerts'));
      await tester.pumpAndSettle();

      expect(chosen, <int>[3]);
      expect(
        indicatorOf(tester, 0).opacity,
        1,
        reason: 'the rail renders the index it was given; one that marked the '
            'new destination and then failed to reach it would be showing the '
            'user something untrue',
      );
      expect(indicatorOf(tester, 3).opacity, 0);
    });

    testWidgets('choosing the current destination is reported too',
        (WidgetTester tester) async {
      final List<int> chosen = <int>[];
      await pump(
        tester,
        framed(selectedIndex: 1, onDestinationSelected: chosen.add),
      );

      await tester.tap(find.text('Messages'));
      await tester.pumpAndSettle();

      expect(chosen, <int>[1]);
    });

    testWidgets('a tap anywhere in the strip counts, including the padding',
        (WidgetTester tester) async {
      final List<int> chosen = <int>[];
      await pump(tester, framed(onDestinationSelected: chosen.add));

      final Rect cell = tester.getRect(cells().at(2));
      await tester.tapAt(Offset(cell.left + 2, cell.top + 2));
      await tester.pumpAndSettle();

      expect(chosen, <int>[2]);
    });

    testWidgets('a keyboard activates the focused destination',
        (WidgetTester tester) async {
      final List<int> chosen = <int>[];
      await pump(tester, framed(onDestinationSelected: chosen.add));

      Focus.of(tester.element(find.text('Search'))).requestFocus();
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      expect(chosen, <int>[2, 2]);
    });

    testWidgets('focus does not move the layout when it appears',
        (WidgetTester tester) async {
      await pump(tester, framed());
      final List<Rect> resting = <Rect>[
        for (int index = 0; index < 5; index++)
          tester.getRect(cells().at(index))
      ];

      Focus.of(tester.element(find.text('Search'))).requestFocus();
      await tester.pumpAndSettle();

      expect(
        <Rect>[
          for (int index = 0; index < 5; index++)
            tester.getRect(cells().at(index))
        ],
        resting,
      );
    });
  });

  group('motion is a policy decision, never a component one', () {
    testWidgets('no motion still marks the current destination',
        (WidgetTester tester) async {
      await pump(
        tester,
        framed(selectedIndex: 2),
        configuration: const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(motion: IuxMotionPreference.none),
        ),
      );

      expect(indicatorOf(tester, 2).duration, Duration.zero);
      expect(
        indicatorOf(tester, 2).opacity,
        1,
        reason: 'removing the animation must never remove the information it '
            'carried',
      );
      expect(indicatorOf(tester, 0).opacity, 0);
    });

    testWidgets('a reduced preference shortens rather than removes',
        (WidgetTester tester) async {
      await pump(
        tester,
        framed(selectedIndex: 2),
        configuration: const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(motion: IuxMotionPreference.reduced),
        ),
      );

      expect(indicatorOf(tester, 2).duration, greaterThan(Duration.zero));
      expect(indicatorOf(tester, 2).opacity, 1);
    });
  });

  group('the rail stands on the edge the user reads from', () {
    testWidgets('it sits at the start of the line, in both directions',
        (WidgetTester tester) async {
      await pump(tester, adaptive());
      expect(tester.getRect(find.byType(IuxNavigationRail)).left, 0);

      await pump(tester, adaptive(), direction: TextDirection.rtl);
      expect(
        tester.getRect(find.byType(IuxNavigationRail)).right,
        _landscapePhone.width,
        reason: 'a rail that stayed on the left when the user reads right to '
            'left would put the navigation at the far end of their reach',
      );
    });

    testWidgets('the boundary line is drawn on the end edge',
        (WidgetTester tester) async {
      await pump(tester, framed());

      final DecoratedBox box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(IuxNavigationRail),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final BoxDecoration decoration = box.decoration as BoxDecoration;

      expect(
        decoration.border,
        isA<BorderDirectional>(),
        reason:
            'a physical-edge border would leave the line between navigation '
            'and content on the wrong side in a right-to-left reading',
      );
      expect((decoration.border! as BorderDirectional).end.width, isPositive);
    });

    testWidgets('the rail consumes the display inset it stands on',
        (WidgetTester tester) async {
      await pump(
        tester,
        framed(),
        padding: const EdgeInsets.only(left: 48),
      );

      final double measured = await measuredWidth(tester);
      await pump(
        tester,
        framed(),
        padding: const EdgeInsets.only(left: 48),
      );

      expect(
        tester.getRect(find.byType(IuxNavigationRail)).width,
        measured + 48,
        reason: 'the rail widens by the cutout rather than drawing its '
            'destinations underneath it',
      );
    });
  });

  group('appearance is resolved, never chosen at the call site', () {
    testWidgets('the rail renders in every profile',
        (WidgetTester tester) async {
      for (final IuxThemeConfiguration configuration in _profiles) {
        await pump(
          tester,
          framed(badge: true),
          configuration: configuration,
        );
        expect(tester.takeException(), isNull, reason: '$configuration');
        expect(find.byType(IuxNavigationRail), findsOneWidget);
      }
    });

    testWidgets('the current name and the others differ in more than a hue',
        (WidgetTester tester) async {
      await pump(tester, framed(selectedIndex: 0));

      final TextStyle current = tester.widget<Text>(find.text('Home')).style!;
      final TextStyle other = tester.widget<Text>(find.text('Search')).style!;

      expect(current.fontSize, other.fontSize);
      expect(current.fontWeight, other.fontWeight);
      expect(current.color, isNot(other.color));
    });

    testWidgets('the rail and the bar resolve from the same tokens',
        (WidgetTester tester) async {
      // One resolver, so the target floor and the type cannot drift between
      // the two arrangements of one navigation.
      await pump(tester, framed());
      final TextStyle railStyle = tester.widget<Text>(find.text('Home')).style!;

      await pump(
        tester,
        Column(
          children: <Widget>[
            const Expanded(child: SizedBox.expand()),
            IuxBottomNavigation(
              label: 'Main navigation',
              destinations: destinations(5),
              selectedIndex: 0,
              onDestinationSelected: (_) {},
            ),
          ],
        ),
      );
      final TextStyle barStyle = tester.widget<Text>(find.text('Home')).style!;

      expect(railStyle.fontSize, barStyle.fontSize);
      expect(railStyle.fontWeight, barStyle.fontWeight);
      expect(railStyle.color, barStyle.color);
    });
  });

  group('the arrangement is measured, not read off a breakpoint', () {
    testWidgets(
        'a phone upright gets the bar, the same phone turned gets the '
        'rail', (WidgetTester tester) async {
      await pump(tester, adaptive(), size: const Size(412, 915));
      expect(find.byType(IuxBottomNavigation), findsOneWidget);
      expect(find.byType(IuxNavigationRail), findsNothing);

      await pump(tester, adaptive(), size: const Size(915, 412));
      expect(find.byType(IuxNavigationRail), findsOneWidget);
      expect(find.byType(IuxBottomNavigation), findsNothing);
    });

    testWidgets('enlarging the text alone can change the arrangement',
        (WidgetTester tester) async {
      // The window is derived from the measurement rather than written down,
      // so this asserts that text scale is a term in the decision rather than
      // that some particular pixel count is.
      const double scale = 1.2;
      final double small = await measuredWidth(tester);
      final double large = await measuredWidth(tester, textScale: scale);
      expect(large, greaterThan(small));

      // Wide enough to afford the rail at 100%, not at 120%. Landscape, so the
      // aspect term does not decide it.
      final double width = large + 319;
      expect(width - small, greaterThanOrEqualTo(320));
      final Size window = Size(width, width - 1);

      await pump(tester, adaptive(), size: window);
      expect(
        find.byType(IuxNavigationRail),
        findsOneWidget,
        reason: 'at 100% the rail leaves the content more than the 320 pixels '
            'IUX supports anywhere',
      );

      await pump(tester, adaptive(), size: window, textScale: scale);
      expect(
        find.byType(IuxBottomNavigation),
        findsOneWidget,
        reason: 'the same window, the same names, a larger text size: the rail '
            'now costs more than the content can pay, and the bar is still a '
            'compact strip',
      );
    });

    testWidgets('the arrangement chosen always leaves the content some room',
        (WidgetTester tester) async {
      // The failure this rule was rewritten for. On a 640 x 320 window at 300%
      // text the rail leaves 286 pixels of content — under the 320 budget, and
      // the reason the budget said no — while the bar there leaves zero. The
      // budget is a rule about the rail only while the bar is still cheap.
      for (final Size window in const <Size>[
        Size(640, 320),
        Size(915, 412),
        Size(480, 480),
      ]) {
        for (final double scale in <double>[1, 1.5, 2, 3]) {
          await pump(
            tester,
            adaptive(child: const SizedBox.expand(key: _content)),
            size: window,
            textScale: scale,
          );
          final Rect content = tester.getRect(find.byKey(_content));
          expect(
            content.width * content.height,
            greaterThan(0),
            reason: 'the content was laid out at zero on a $window window at '
                '$scale; navigation took the whole of the axis the window has '
                'least of',
          );
          expect(
            tester.takeException(),
            isNull,
            reason: 'navigation overflowed a $window window at $scale',
          );

          // DebugOverflowIndicatorMixin reports a render object's overflow
          // once per lifetime, so the assertion above is only worth anything
          // because every case ends by tearing the tree down
          // (IUX-QA-VACUOUS-003).
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
    });

    testWidgets('a rail that does not fit its window is not an arrangement',
        (WidgetTester tester) async {
      // IUX-RAIL-OVERFLOW-001. The rule weighed how much the rail *left over*
      // and never asked whether it *fitted*: a rail wider than the window
      // leaves a negative remainder, and a negative number fails a budget test
      // exactly as a small positive one does, so the case where the rail is not
      // an arrangement at all read as the case where it is merely a tight one.
      //
      // The windows are derived from the measurement rather than written down,
      // so this pins the rule and not a pixel count. Every one is landscape, so
      // the aspect term does not decide any of them.
      const double scale = 3;
      final double rail = await measuredWidth(tester, textScale: scale);

      final Map<String, double> tooNarrow = <String, double>{
        // What the audit measured: the rail 36 pixels wider than the screen, a
        // Row overflowing by 36, and the page laid out at zero.
        'the rail is 36 pixels wider than the window': rail - 36,
        // The boundary, where the rail exactly fills the window. It leaves no
        // page at all and throws nothing, so an assertion written against the
        // exception alone would have called it healthy.
        'the rail fills the window exactly': rail,
      };

      for (final MapEntry<String, double> window in tooNarrow.entries) {
        await pump(
          tester,
          adaptive(child: const SizedBox.expand(key: _content)),
          size: Size(window.value, window.value - 1),
          textScale: scale,
        );

        expect(
          find.byType(IuxNavigationRail),
          findsNothing,
          reason: '${window.key}: the rail wants '
              '${rail.toStringAsFixed(1)} pixels and the window has '
              '${window.value.toStringAsFixed(1)}',
        );
        expect(find.byType(IuxBottomNavigation), findsOneWidget);
        expect(
          tester.takeException(),
          isNull,
          reason: window.key,
        );

        // DebugOverflowIndicatorMixin reports a render object's overflow once
        // per lifetime, so the assertion above is only worth anything because
        // every case ends by tearing the tree down (IUX-QA-VACUOUS-003).
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('a rail that fits but leaves little is still chosen',
        (WidgetTester tester) async {
      // The complement, and the reason the new term is a fit test rather than a
      // second content budget. The rule deliberately keeps the rail on a short
      // landscape window where it leaves the content less than the 320 pixels
      // IUX supports, because the bar there leaves zero. Narrowing the window
      // to the point where the rail no longer fits must not have taken that
      // argument with it.
      const double scale = 3;
      final double rail = await measuredWidth(tester, textScale: scale);
      final double width = rail + 100;

      await pump(
        tester,
        adaptive(child: const SizedBox.expand(key: _content)),
        size: Size(width, width - 1),
        textScale: scale,
      );

      expect(
        find.byType(IuxNavigationRail),
        findsOneWidget,
        reason: 'the rail leaves 100 pixels — far under the 320 budget, and '
            'still more than the bar would leave on a window this short',
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getRect(find.byKey(_content)).width,
        greaterThan(0),
      );
    });

    testWidgets('the overflow the fit term prevents, measured',
        (WidgetTester tester) async {
      // IUX-RAIL-OVERFLOW-001, reproduced rather than described. The
      // arrangement below is exactly the one `IuxAdaptiveNavigation` builds
      // when it takes the rail — a stretched Row of the rail and an Expanded —
      // so building it by hand on a window narrower than the rail measures what
      // the component used to do, and pins the number the audit reported.
      //
      // The deficit is chosen and the window derived from `widthFor`, so this
      // asserts arithmetic rather than a font: whatever the rail costs, a
      // window that much narrower overflows by exactly that much.
      const double scale = 3;
      final double rail = await measuredWidth(tester, textScale: scale);

      for (final double deficit in <double>[36, 100]) {
        final double width = rail - deficit;

        await pump(
          tester,
          framed(),
          size: Size(width, width - 1),
          textScale: scale,
        );
        expect(
          tester.takeException().toString(),
          contains('overflowed by ${deficit.toStringAsFixed(0)} pixels'),
          reason: 'a rail is not flexible, so a Row hands it the '
              '${rail.toStringAsFixed(1)} pixels it asked for and the page '
              'beside it is laid out at zero on a '
              '${width.toStringAsFixed(1)}-pixel window',
        );
        await tester.pumpWidget(const SizedBox.shrink());

        // The same window, the same text size, the same destinations — handed
        // to the component that owns the total. It asks whether the rail fits
        // before it asks what the rail leaves, so there is no Row to overflow.
        await pump(
          tester,
          adaptive(child: const SizedBox.expand(key: _content)),
          size: Size(width, width - 1),
          textScale: scale,
        );
        expect(find.byType(IuxNavigationRail), findsNothing);
        expect(find.byType(IuxBottomNavigation), findsOneWidget);
        expect(
          tester.takeException(),
          isNull,
          reason: 'the arrangement that cannot fit was chosen anyway, and the '
              'Row overflowed by $deficit',
        );

        // DebugOverflowIndicatorMixin reports a render object's overflow once
        // per lifetime, so both assertions above are only worth anything
        // because every case ends by tearing the tree down
        // (IUX-QA-VACUOUS-003).
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('an unbounded box is refused by name, not by accident',
        (WidgetTester tester) async {
      // A window with no end in one axis cannot be short of anything in it, and
      // a component that answered "rail" there would be sizing navigation from
      // a window nobody has decided yet.
      //
      // It used to answer "bar" — the phone arrangement, on a window it had not
      // measured — and the failure then arrived from the framework: measured,
      // 27 exceptions from one SingleChildScrollView, the first of them
      // "RenderFlex children have non-zero flex but incoming height constraints
      // are unbounded", reported against a Column this component owns. That is
      // loud, and it is not this component's refusal: nothing in it names the
      // navigation or says what to do instead. `docs/components/navigation-
      // rail.md` claimed the case was asserted for several missions while it
      // was not. It is now, and this is what the assertion has to say.
      for (final Widget unbounded in <Widget>[
        SingleChildScrollView(child: adaptive()),
        Row(children: <Widget>[adaptive()]),
      ]) {
        // Collected rather than taken. An unbounded box produces a cascade —
        // the refusal, and then everything downstream of a subtree that failed
        // to build — and `takeException` answers a cascade with a count rather
        // than with any of the messages in it.
        final List<String> reported = <String>[];
        final void Function(FlutterErrorDetails)? previous =
            FlutterError.onError;
        FlutterError.onError =
            (FlutterErrorDetails details) => reported.add(details.toString());
        await pump(tester, unbounded);
        FlutterError.onError = previous;

        expect(
          find.byType(IuxNavigationRail),
          findsNothing,
          reason: 'a rail measured against an infinite window is a rail sized '
              'from an assumption',
        );
        expect(
          reported.where((String e) => e.contains('IuxAdaptiveNavigation')),
          isNotEmpty,
          reason: 'silently laying out navigation at zero is how a user ends '
              'up on a screen with no way off it, and an error naming only a '
              'Column sends the reader to the wrong widget',
        );
        expect(
          reported.where((String e) => e.contains('Scaffold.body')),
          isNotEmpty,
          reason: 'an error that says what is wrong and not what to do leaves '
              'the reader in the source of the framework',
        );
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('the same index is reported from either arrangement',
        (WidgetTester tester) async {
      final List<int> chosen = <int>[];

      await pump(
        tester,
        adaptive(onDestinationSelected: chosen.add),
        size: const Size(412, 915),
      );
      await tester.tap(find.text('Alerts'));
      await tester.pumpAndSettle();

      await pump(
        tester,
        adaptive(onDestinationSelected: chosen.add),
        size: const Size(915, 412),
      );
      await tester.tap(find.text('Alerts'));
      await tester.pumpAndSettle();

      expect(
        chosen,
        <int>[3, 3],
        reason: 'a parent must never have to ask which arrangement it is '
            'talking to',
      );
    });

    testWidgets('the destinations keep their order in both arrangements',
        (WidgetTester tester) async {
      await pump(tester, adaptive(), size: const Size(412, 915));
      final List<double> across = <double>[
        for (final String name in _names) tester.getRect(find.text(name)).left,
      ];
      expect(across, orderedEquals(<double>[...across]..sort()));

      await pump(tester, adaptive(), size: const Size(915, 412));
      final List<double> down = <double>[
        for (final String name in _names) tester.getRect(find.text(name)).top,
      ];
      expect(
        down,
        orderedEquals(<double>[...down]..sort()),
        reason: 'rotating a device must not reshuffle an application',
      );
    });

    testWidgets('the inset the navigation stands on is not applied twice',
        (WidgetTester tester) async {
      const EdgeInsets insets = EdgeInsets.only(left: 48, top: 24, bottom: 16);

      EdgeInsets childPadding(WidgetTester tester) => tester
          .widget<MediaQuery>(
            find
                .ancestor(
                  of: find.byKey(_content),
                  matching: find.byType(MediaQuery),
                )
                .first,
          )
          .data
          .padding
          .resolve(TextDirection.ltr);

      await pump(
        tester,
        adaptive(child: const SizedBox.expand(key: _content)),
        size: const Size(915, 412),
        padding: insets,
      );
      expect(
        childPadding(tester).left,
        0,
        reason: 'the rail is standing on the cutout; a page that inset itself '
            'from it again would sit a notch away from the rail it is meant to '
            'touch',
      );
      expect(childPadding(tester).top, 24);

      await pump(
        tester,
        adaptive(child: const SizedBox.expand(key: _content)),
        size: const Size(412, 915),
        padding: insets,
      );
      expect(
        childPadding(tester).bottom,
        0,
        reason: 'the bar consumes the gesture area itself',
      );
      expect(childPadding(tester).left, 48);
      expect(childPadding(tester).top, 24);
    });

    testWidgets('a narrow phone never gets the rail, at any text size',
        (WidgetTester tester) async {
      for (final double scale in <double>[1, 1.5, 2, 3]) {
        await pump(
          tester,
          adaptive(),
          size: _smallPhone,
          textScale: scale,
        );
        expect(
          find.byType(IuxNavigationRail),
          findsNothing,
          reason: 'a rail on a 320-pixel portrait phone leaves 192 pixels of '
              'content at 100% text and 78 at 200%',
        );
      }
    });
  });
}
