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

/// The three densities, which move every measurement except the target floor.
const List<IuxDensity> _densities = <IuxDensity>[
  IuxDensity.compact,
  IuxDensity.standard,
  IuxDensity.comfortable,
];

/// The narrowest screen width IUX supports, and the case the mission names.
const Size _smallPhone = Size(320, 640);

/// Five names, in the order a bar shows them.
const List<String> _names = <String>[
  'Home',
  'Messages',
  'Search',
  'Alerts',
  'Account',
];

/// The glyphs, one per name. Which glyph is irrelevant to every assertion here;
/// what matters is that a destination has one and that it is never announced.
const List<IconData> _glyphs = <IconData>[
  Icons.home_outlined,
  Icons.mail_outline,
  Icons.search_outlined,
  Icons.notifications_outlined,
  Icons.person_outline,
];

void main() {
  /// [count] destinations, optionally with a badge on the second one.
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
    Widget bar, {
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
          theme: IuxTheme.fromConfiguration(configuration),
          home: Directionality(
            textDirection: direction,
            child: Scaffold(
              body: const SizedBox.expand(),
              bottomNavigationBar: bar,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Widget bar({
    int count = 5,
    int selectedIndex = 0,
    bool badge = false,
    String? longName,
    ValueChanged<int>? onDestinationSelected,
  }) =>
      IuxBottomNavigation(
        label: 'Main navigation',
        destinations: destinations(count, badge: badge, longName: longName),
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected ?? (_) {},
      );

  /// The interactive region of each destination, in order.
  ///
  /// Measured on the gesture detector rather than on the whole cell: it is the
  /// widget that actually responds, so a target measured anywhere else would
  /// be a number nobody can tap.
  Finder cells() => find.descendant(
        of: find.byType(IuxBottomNavigation),
        matching: find.byType(GestureDetector),
      );

  /// The indicator behind one destination's glyph.
  ///
  /// The press tint is the bar's other animated opacity, and it sits outside
  /// the gesture detector, so scoping to the cell leaves exactly one.
  Finder indicator(int index) => find
      .descendant(
        of: cells().at(index),
        matching: find.byType(AnimatedOpacity),
      )
      .first;

  AnimatedOpacity indicatorOf(WidgetTester tester, int index) =>
      tester.widget<AnimatedOpacity>(indicator(index));

  /// What a screen reader actually announces for the destination named [name],
  /// after merging.
  ///
  /// The merged data, not the node's own: a destination's name, its badge and
  /// its state are contributed by three different nodes and collapsed into one
  /// stop, so reading the outer node's own properties would report an empty
  /// label and no state at all.
  SemanticsData dataOf(WidgetTester tester, String name) =>
      tester.getSemantics(find.text(name)).getSemanticsData();

  /// How many separate stops a screen reader finds below [node].
  ///
  /// A node merged into its parent is not a stop: the user cannot land on it,
  /// which is the whole point of merging a destination into one control.
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

  group('a bar refuses the configurations that cannot work', () {
    test('two destinations are refused', () {
      expect(
        () => IuxBottomNavigation(
          label: 'Main navigation',
          destinations: destinations(2),
          selectedIndex: 0,
          onDestinationSelected: (_) {},
        ),
        throwsAssertionError,
      );
    });

    test('six destinations are refused', () {
      // There is no sixth name in _names, so the sixth is built by hand.
      expect(
        () => IuxBottomNavigation(
          label: 'Main navigation',
          destinations: <IuxNavigationDestination>[
            ...destinations(5),
            const IuxNavigationDestination(
              label: 'Settings',
              icon: Icons.settings_outlined,
            ),
          ],
          selectedIndex: 0,
          onDestinationSelected: (_) {},
        ),
        throwsAssertionError,
      );
    });

    test('three, four and five destinations are accepted', () {
      for (int count = 3; count <= 5; count++) {
        expect(
          () => IuxBottomNavigation(
            label: 'Main navigation',
            destinations: destinations(count),
            selectedIndex: 0,
            onDestinationSelected: (_) {},
          ),
          returnsNormally,
        );
      }
    });

    test('a current destination outside the set is refused', () {
      // A bar marking none of its destinations is a bar that cannot say where
      // the user is.
      for (final int index in <int>[-1, 3]) {
        expect(
          () => IuxBottomNavigation(
            label: 'Main navigation',
            destinations: destinations(3),
            selectedIndex: index,
            onDestinationSelected: (_) {},
          ),
          throwsAssertionError,
        );
      }
    });

    test('two destinations sharing a name are refused', () {
      expect(
        () => IuxBottomNavigation(
          label: 'Main navigation',
          destinations: const <IuxNavigationDestination>[
            IuxNavigationDestination(label: 'Home', icon: Icons.home_outlined),
            IuxNavigationDestination(label: 'Home', icon: Icons.mail_outline),
            IuxNavigationDestination(
              label: 'Account',
              icon: Icons.person_outline,
            ),
          ],
          selectedIndex: 0,
          onDestinationSelected: (_) {},
        ),
        throwsAssertionError,
      );
    });

    test('an unnamed bar is refused', () {
      expect(
        () => IuxBottomNavigation(
          label: '',
          destinations: destinations(3),
          selectedIndex: 0,
          onDestinationSelected: (_) {},
        ),
        throwsAssertionError,
      );
    });

    test('an unnamed destination is refused', () {
      expect(
        () => IuxNavigationDestination(label: '', icon: Icons.home_outlined),
        throwsAssertionError,
      );
    });
  });

  group('the current destination is announced, not only coloured', () {
    testWidgets('the current destination is checked and the others are not',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester, bar(selectedIndex: 2));

      expect(
        dataOf(tester, 'Search').flagsCollection.isChecked,
        CheckedState.isTrue,
      );
      for (final String other in <String>['Home', 'Messages', 'Alerts']) {
        expect(
          dataOf(tester, other).flagsCollection.isChecked,
          CheckedState.isFalse,
          reason: 'a destination that says nothing about its state leaves the '
              'user to sweep the whole bar to find the one that did',
        );
      }

      handle.dispose();
    });

    testWidgets('every destination belongs to a mutually exclusive group',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester, bar());

      for (final String name in _names) {
        expect(
          dataOf(tester, name).flagsCollection.isInMutuallyExclusiveGroup,
          isTrue,
          reason: 'without it the platform cannot say "2 of 5", and nothing '
              'tells the user that choosing one unchooses another',
        );
      }

      handle.dispose();
    });

    testWidgets('the announcement survives the stacked arrangement',
        (WidgetTester tester) async {
      // The arrangement that carries enlarged text is the one a screen-reader
      // user with a magnifier is most likely to be in, so it is the one that
      // must not quietly lose its state.
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(
        tester,
        bar(selectedIndex: 2, badge: true),
        size: _smallPhone,
        textScale: 2,
      );

      expect(
        dataOf(tester, 'Search').flagsCollection.isChecked,
        CheckedState.isTrue,
      );
      expect(
        dataOf(tester, 'Home').flagsCollection.isChecked,
        CheckedState.isFalse,
      );
      expect(
        dataOf(tester, 'Messages').label,
        contains('3 unread messages'),
      );
      expect(stopsBelow(tester.getSemantics(find.text('Messages'))), 0);

      handle.dispose();
    });

    testWidgets('the bar itself is announced as a named group',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester, bar());

      final SemanticsNode group =
          tester.getSemantics(find.bySemanticsLabel('Main navigation'));
      expect(group.getSemanticsData().role, SemanticsRole.radioGroup);
      expect(group.label, 'Main navigation');

      handle.dispose();
    });

    testWidgets('a screen reader can activate a destination',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final List<int> chosen = <int>[];
      await pump(tester, bar(onDestinationSelected: chosen.add));

      expect(
        dataOf(tester, 'Alerts').hasAction(
          SemanticsAction.tap,
        ),
        isTrue,
        reason: 'a destination announced correctly and inert is a control the '
            'user can find and cannot use',
      );

      handle.dispose();
      expect(chosen, isEmpty);
    });

    testWidgets('the mark is a shape, and it is there in every theme profile',
        (WidgetTester tester) async {
      for (final IuxThemeConfiguration configuration in _profiles) {
        await pump(tester, bar(selectedIndex: 3), configuration: configuration);

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
      await pump(tester, bar(selectedIndex: 1));

      final DecoratedBox box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: indicator(1),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final BoxDecoration decoration = box.decoration as BoxDecoration;

      expect(
        decoration.border,
        isNotNull,
        reason: 'surface contrast alone is deliberately gentle in IUX, so an '
            'indicator that relied on the fill would disappear for the exact '
            'user it exists for',
      );
      expect(decoration.borderRadius, isNotNull);
    });

    testWidgets('choosing a destination does not resize it',
        (WidgetTester tester) async {
      // The indicator's space is reserved in both states. In a row of equal
      // columns, one column changing width moves all five.
      await pump(tester, bar(selectedIndex: 0));
      final List<Rect> before = <Rect>[
        for (int index = 0; index < 5; index++)
          tester.getRect(cells().at(index))
      ];

      await pump(tester, bar(selectedIndex: 4));
      final List<Rect> after = <Rect>[
        for (int index = 0; index < 5; index++)
          tester.getRect(cells().at(index))
      ];

      expect(after, before);
    });
  });

  group('a destination is one stop, and it says what is waiting there', () {
    testWidgets('a destination is a single stop', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester, bar(badge: true));

      expect(
        stopsBelow(tester.getSemantics(find.text('Messages'))),
        0,
        reason: 'a badge that were its own stop would make a five-destination '
            'bar a ten-stop sweep',
      );

      handle.dispose();
    });

    testWidgets('a badge is announced with what it counts',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester, bar(badge: true));

      final String announced = dataOf(tester, 'Messages').label;
      expect(announced, contains('Messages'));
      expect(
        announced,
        contains('3 unread messages'),
        reason: '"3" on its own tells a screen-reader user how many of nothing '
            'they have',
      );
      expect(
        announced,
        isNot(matches(RegExp(r'^\s*3\s*$'))),
      );

      handle.dispose();
    });

    test('a badge cannot be a bare number', () {
      // The refusal belongs to IuxBadge, and the destination reuses it rather
      // than opening a second way to put a number on a destination. Built from
      // a runtime string so the assertion fires when the test runs it rather
      // than when the compiler folds it.
      final String number = 3.toString();
      expect(
        () => IuxBadge.count(count: number, label: number),
        throwsAssertionError,
      );
    });

    testWidgets('the glyph is not announced', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester, bar());

      // The name beside the glyph already says what this destination is. A
      // described glyph would have every section read out twice.
      expect(dataOf(tester, 'Home').label, 'Home');

      handle.dispose();
    });
  });

  group('every destination is named, at every size', () {
    testWidgets('every name is drawn, current or not',
        (WidgetTester tester) async {
      await pump(tester, bar(selectedIndex: 0));

      for (final String name in _names) {
        expect(
          find.text(name),
          findsOneWidget,
          reason: 'labelling only the current destination tells the user the '
              'name of the one place they already know they are',
        );
      }
    });

    testWidgets('names are never truncated', (WidgetTester tester) async {
      for (final double scale in <double>[1, 1.5, 2]) {
        await pump(
          tester,
          bar(longName: 'Notifications and reminders'),
          textScale: scale,
          size: _smallPhone,
        );

        for (final Element element in find.byType(Text).evaluate()) {
          final Text text = element.widget as Text;
          expect(text.maxLines, isNull, reason: 'at scale $scale');
          expect(text.overflow, isNot(TextOverflow.ellipsis));
        }
      }
    });

    testWidgets('the row becomes a stack once text is enlarged',
        (WidgetTester tester) async {
      await pump(tester, bar(), size: _smallPhone);
      final List<Rect> row = <Rect>[
        for (int index = 0; index < 5; index++)
          tester.getRect(cells().at(index))
      ];
      expect(
        row.map((Rect r) => r.top).toSet().length,
        1,
        reason: 'at ordinary sizes the destinations share one row',
      );
      expect(row.map((Rect r) => r.left).toSet().length, 5);

      await pump(tester, bar(), size: _smallPhone, textScale: 2);
      final List<Rect> stacked = <Rect>[
        for (int index = 0; index < 5; index++)
          tester.getRect(cells().at(index))
      ];
      expect(
        stacked.map((Rect r) => r.left).toSet().length,
        1,
        reason: 'a fifth of 320 pixels cannot hold an enlarged word, so the '
            'destinations take the width one at a time instead of breaking '
            'their names mid-syllable',
      );
      expect(stacked.map((Rect r) => r.top).toSet().length, 5);
      for (final Rect cell in stacked) {
        expect(cell.width, _smallPhone.width);
      }
    });

    testWidgets('five names on a 320-pixel screen at 200% do not overflow',
        (WidgetTester tester) async {
      await pump(
        tester,
        bar(longName: 'Notifications'),
        size: _smallPhone,
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
      // Every name is still whole and still on screen.
      for (final String name in <String>[
        'Home',
        'Notifications',
        'Search',
        'Alerts',
        'Account',
      ]) {
        expect(find.text(name), findsOneWidget);
      }
    });

    testWidgets('a bar too tall for the screen degrades rather than clipping',
        (WidgetTester tester) async {
      // Three times the text size, five destinations, a short screen: the bar
      // needs more room than exists. Every destination is still built and
      // still reachable, which is the half of the argument that matters.
      await pump(tester, bar(), size: _smallPhone, textScale: 3);

      expect(tester.takeException(), isNull);
      for (final String name in _names) {
        expect(find.text(name), findsOneWidget);
      }
      expect(
        tester.getRect(find.byType(IuxBottomNavigation)).height,
        lessThanOrEqualTo(_smallPhone.height),
      );
    });

    testWidgets('a long name wraps rather than clipping',
        (WidgetTester tester) async {
      await pump(
        tester,
        bar(longName: 'Notifications and reminders'),
        size: _smallPhone,
      );

      expect(
        tester.getSize(find.text('Notifications and reminders')).height,
        greaterThan(tester.getSize(find.text('Home')).height),
        reason: 'the name took more than one line rather than being cut',
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('targets meet the floor, at every density', () {
    testWidgets('five destinations on a 320-pixel screen each meet the floor',
        (WidgetTester tester) async {
      for (final IuxDensity density in _densities) {
        for (final IuxTouchTargetPreference target
            in IuxTouchTargetPreference.values) {
          await pump(
            tester,
            bar(),
            size: _smallPhone,
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
              greaterThanOrEqualTo(IuxTouchTarget.minimum),
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
        await pump(tester, bar(), size: _smallPhone, textScale: scale);

        for (int index = 0; index < 5; index++) {
          final Rect cell = tester.getRect(cells().at(index));
          expect(cell.width, greaterThanOrEqualTo(IuxTouchTarget.minimum));
          expect(cell.height, greaterThanOrEqualTo(IuxTouchTarget.minimum));
        }
      }
    });

    testWidgets('destinations tile the bar, leaving no dead strip',
        (WidgetTester tester) async {
      await pump(tester, bar(), size: _smallPhone);

      final Rect barRect = tester.getRect(find.byType(IuxBottomNavigation));
      final List<Rect> rects = <Rect>[
        for (int index = 0; index < 5; index++)
          tester.getRect(cells().at(index))
      ];

      expect(rects.first.left, barRect.left);
      expect(rects.last.right, barRect.right);
      for (int index = 0; index < 4; index++) {
        expect(
          rects[index].right,
          closeTo(rects[index + 1].left, 0.01),
          reason: 'a gap belonging to neither destination is a strip in the '
              'thumb zone where a tap does nothing at all',
        );
      }
      // Full height too: no band above a short destination that ignores taps.
      for (final Rect cell in rects) {
        expect(cell.height, closeTo(rects.first.height, 0.01));
      }
    });
  });

  group('the parent owns where the user is', () {
    testWidgets('choosing a destination reports its index and moves nothing',
        (WidgetTester tester) async {
      final List<int> chosen = <int>[];
      await pump(tester, bar(onDestinationSelected: chosen.add));

      await tester.tap(find.text('Alerts'));
      await tester.pumpAndSettle();

      expect(chosen, <int>[3]);
      expect(
        indicatorOf(tester, 0).opacity,
        1,
        reason: 'the bar renders the index it was given; a bar that marked the '
            'new destination and then failed to reach it would be showing the '
            'user something untrue',
      );
      expect(indicatorOf(tester, 3).opacity, 0);
    });

    testWidgets('choosing the current destination is reported too',
        (WidgetTester tester) async {
      // Unlike IuxRadioGroup, which swallows a choice that changes nothing:
      // returning to the top of the section the user is already in is a real
      // gesture, and only the parent knows whether it means anything here.
      final List<int> chosen = <int>[];
      await pump(
          tester, bar(selectedIndex: 1, onDestinationSelected: chosen.add));

      await tester.tap(find.text('Messages'));
      await tester.pumpAndSettle();

      expect(chosen, <int>[1]);
    });

    testWidgets('a tap anywhere in the column counts, including the padding',
        (WidgetTester tester) async {
      final List<int> chosen = <int>[];
      await pump(tester, bar(onDestinationSelected: chosen.add));

      final Rect cell = tester.getRect(cells().at(2));
      await tester.tapAt(Offset(cell.left + 2, cell.top + 2));
      await tester.pumpAndSettle();

      expect(chosen, <int>[2]);
    });

    testWidgets('a keyboard activates the focused destination',
        (WidgetTester tester) async {
      final List<int> chosen = <int>[];
      await pump(tester, bar(onDestinationSelected: chosen.add));

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
      await pump(tester, bar());
      final List<Rect> resting = <Rect>[
        for (int index = 0; index < 5; index++)
          tester.getRect(cells().at(index))
      ];

      Focus.of(tester.element(find.text('Search'))).requestFocus();
      await tester.pumpAndSettle();

      final List<Rect> focused = <Rect>[
        for (int index = 0; index < 5; index++)
          tester.getRect(cells().at(index))
      ];
      expect(focused, resting);
    });
  });

  group('motion is a policy decision, never a component one', () {
    testWidgets('no motion still marks the current destination',
        (WidgetTester tester) async {
      await pump(
        tester,
        bar(selectedIndex: 2),
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
        bar(selectedIndex: 2),
        configuration: const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(motion: IuxMotionPreference.reduced),
        ),
      );

      expect(indicatorOf(tester, 2).duration, greaterThan(Duration.zero));
      expect(indicatorOf(tester, 2).opacity, 1);
    });
  });

  group('the bar reads in the direction the user reads', () {
    testWidgets('the first destination sits at the start of the line',
        (WidgetTester tester) async {
      await pump(tester, bar(), size: _smallPhone);
      expect(
        tester.getRect(cells().at(0)).left,
        lessThan(tester.getRect(cells().at(4)).left),
      );

      await pump(tester, bar(),
          size: _smallPhone, direction: TextDirection.rtl);
      expect(
        tester.getRect(cells().at(0)).left,
        greaterThan(tester.getRect(cells().at(4)).left),
        reason: 'a bar that read backwards would put the section the user '
            'expects first at the far end of their reach',
      );
    });
  });

  group('appearance is resolved, never chosen at the call site', () {
    testWidgets('the bar renders in every profile',
        (WidgetTester tester) async {
      for (final IuxThemeConfiguration configuration in _profiles) {
        await pump(tester, bar(badge: true), configuration: configuration);
        expect(tester.takeException(), isNull, reason: '$configuration');
        expect(find.byType(IuxBottomNavigation), findsOneWidget);
      }
    });

    testWidgets(
        'the current destination and the others differ in more than '
        'a hue', (WidgetTester tester) async {
      await pump(tester, bar(selectedIndex: 0));

      final TextStyle current = tester.widget<Text>(find.text('Home')).style!;
      final TextStyle other = tester.widget<Text>(find.text('Search')).style!;

      // Same metrics, different colour. A heavier current label would change
      // the measured width, so choosing a destination would move the four
      // beside it.
      expect(current.fontSize, other.fontSize);
      expect(current.fontWeight, other.fontWeight);
      expect(current.color, isNot(other.color));
    });

    testWidgets(
        'the resolver reads the target floor from the runtime, not '
        'from itself', (WidgetTester tester) async {
      late IuxBottomNavigationTokens standard;
      late IuxBottomNavigationTokens comfortable;

      await tester.pumpWidget(
        MaterialApp(
          theme: IuxTheme.light(),
          home: Builder(
            builder: (BuildContext context) {
              standard = IuxBottomNavigationResolver.resolve(context);
              return const SizedBox();
            },
          ),
        ),
      );
      // Settled, because MaterialApp animates a theme change: read on the
      // frame after the swap and the resolver is still looking at the old one.
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        MaterialApp(
          theme: IuxTheme.fromConfiguration(
            const IuxThemeConfiguration(
              profile: IuxAccessibilityProfile(
                touchTarget: IuxTouchTargetPreference.comfortable,
              ),
            ),
          ),
          home: Builder(
            builder: (BuildContext context) {
              comfortable = IuxBottomNavigationResolver.resolve(context);
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(standard.minExtent, IuxTouchTarget.minimum);
      expect(comfortable.minExtent, IuxTouchTarget.comfortable);
      expect(standard.stacked, isFalse);
    });

    testWidgets('tokens compare by value', (WidgetTester tester) async {
      late IuxBottomNavigationTokens first;
      late IuxBottomNavigationTokens second;
      late IuxBottomNavigationTokens current;

      await tester.pumpWidget(
        MaterialApp(
          theme: IuxTheme.light(),
          home: Builder(
            builder: (BuildContext context) {
              first = IuxBottomNavigationResolver.resolve(context);
              second = IuxBottomNavigationResolver.resolve(context);
              current = IuxBottomNavigationResolver.resolve(
                context,
                current: true,
              );
              return const SizedBox();
            },
          ),
        ),
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first, isNot(current));
    });

    test('a destination compares by value', () {
      const IuxNavigationDestination home = IuxNavigationDestination(
        label: 'Home',
        icon: Icons.home_outlined,
      );
      expect(
        home,
        const IuxNavigationDestination(
          label: 'Home',
          icon: Icons.home_outlined,
        ),
      );
      expect(
        home,
        isNot(
          const IuxNavigationDestination(
            label: 'Home',
            icon: Icons.home,
          ),
        ),
      );
      expect(home.toString(), contains('Home'));
    });
  });

  group('a badge on the glyph', () {
    /// Three destinations, the middle one badged, placed as asked.
    Widget badged(IuxBadgePlacement placement) => IuxBottomNavigation(
          label: 'Main navigation',
          selectedIndex: 0,
          onDestinationSelected: (int _) {},
          destinations: <IuxNavigationDestination>[
            const IuxNavigationDestination(
              label: 'Home',
              icon: Icons.home_outlined,
            ),
            IuxNavigationDestination(
              label: 'Messages',
              icon: Icons.mail_outline,
              badge: const IuxBadge.count(
                count: '3',
                label: '3 unread messages',
              ),
              badgePlacement: placement,
            ),
            const IuxNavigationDestination(
              label: 'Search',
              icon: Icons.search_outlined,
            ),
          ],
        );

    /// Whether the badge is drawn within the glyph's own box.
    ///
    /// Asked of the glyph rather than of the name, because "on the glyph" is
    /// what the placement means and the bar rearranges itself into a row at
    /// large text sizes — where a badge beside the name shares its height and
    /// a vertical comparison stops saying anything.
    bool overlaysGlyph(WidgetTester tester) => tester
        .getRect(find.byIcon(Icons.mail_outline))
        .inflate(8)
        .contains(tester.getCenter(find.text('3')));

    testWidgets('is asked for, never assumed', (WidgetTester tester) async {
      // A destination that says nothing keeps the documented placement: the
      // badge under the name, where nothing covers and nothing clips.
      await pump(tester, badged(IuxBadgePlacement.afterLabel));
      expect(overlaysGlyph(tester), isFalse);
    });

    testWidgets('sits on the glyph when it is', (WidgetTester tester) async {
      await pump(tester, badged(IuxBadgePlacement.onGlyph));
      expect(overlaysGlyph(tester), isTrue);
    });

    testWidgets('gives the corner up rather than clip it',
        (WidgetTester tester) async {
      // Past the scale the corner can hold, the bar returns to the documented
      // placement on its own. The badge somebody enlarged their text to read
      // must not be the one that gets cut off.
      await pump(tester, badged(IuxBadgePlacement.onGlyph), textScale: 2);
      expect(overlaysGlyph(tester), isFalse);
    });

    testWidgets('is announced either way', (WidgetTester tester) async {
      // The placement is a drawing decision and must not be an accessibility
      // one: the destination is still one stop, still saying how many.
      for (final IuxBadgePlacement placement in IuxBadgePlacement.values) {
        await pump(tester, badged(placement));
        expect(
          dataOf(tester, 'Messages').label,
          contains('3 unread messages'),
          reason: 'placement $placement lost the count',
        );
        expect(stopsBelow(tester.getSemantics(find.text('Messages'))), 0);
      }
    });
  });
}
