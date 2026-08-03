// `Tristate` is declared in `dart:ui` and is not re-exported by
// `package:flutter/semantics.dart`. It is what distinguishes a tab that says
// it is not selected from one that says nothing about selection at all, which
// is the difference this suite exists to hold.
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

import '../support/contrast.dart';

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

/// The narrowest screen width IUX supports.
const Size _smallPhone = Size(320, 640);

/// Five names, in the order a strip shows them.
const List<String> _names = <String>[
  'All',
  'Unread',
  'Archived',
  'Drafts',
  'Sent',
];

/// The name of the set, which is announced and never drawn.
const String _stripName = 'Message filter';

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget strip, {
    IuxThemeConfiguration configuration = const IuxThemeConfiguration(),
    TextDirection direction = TextDirection.ltr,
    double textScale = 1,
    Size size = _smallPhone,
    Widget panel = const SizedBox.expand(),
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
              body: Column(
                children: <Widget>[strip, Expanded(child: panel)],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Widget strip({
    int count = 3,
    int selectedIndex = 0,
    ValueChanged<int>? onTabSelected,
    List<String>? tabs,
  }) =>
      IuxTabs(
        label: _stripName,
        tabs: tabs ?? _names.take(count).toList(),
        selectedIndex: selectedIndex,
        onTabSelected: onTabSelected ?? (_) {},
      );

  /// The interactive region of each tab, in order.
  ///
  /// Measured on the gesture detector rather than on the whole tab: it is the
  /// widget that actually responds, so a target measured anywhere else would be
  /// a number nobody can tap.
  Finder targets() => find.descendant(
        of: find.byType(IuxTabs),
        matching: find.byType(GestureDetector),
      );

  /// The mark drawn behind the current tab's label.
  ///
  /// The press tint is the strip's other animated opacity and it sits outside
  /// the focus ring, so scoping to the tab and taking the last leaves exactly
  /// the mark.
  AnimatedOpacity markOf(WidgetTester tester, int index) =>
      tester.widget<AnimatedOpacity>(
        find
            .descendant(
              of: targets().at(index),
              matching: find.byType(AnimatedOpacity),
            )
            .last,
      );

  /// The strip's own semantics node, found by role rather than by position.
  SemanticsNode barNode(WidgetTester tester) {
    SemanticsNode? node = tester.getSemantics(find.text(_names[0]));
    while (node != null && node.role != SemanticsRole.tabBar) {
      node = node.parent;
    }
    expect(node, isNotNull, reason: 'the strip announced no tabBar container');
    return node!;
  }

  /// How many separate stops a screen reader finds below [node].
  ///
  /// A node merged into its parent is not a stop: the user cannot land on it,
  /// which is the whole point of one announcement per tab.
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

  /// Which tab currently holds input focus, or -1 when none does.
  int focusedTab(WidgetTester tester, int count) {
    final BuildContext? context = FocusManager.instance.primaryFocus?.context;
    if (context == null) return -1;
    final RenderObject? object = context.findRenderObject();
    if (object is! RenderBox) return -1;
    final Offset centre = object.localToGlobal(object.size.center(Offset.zero));
    for (int index = 0; index < count; index++) {
      if (tester.getRect(targets().at(index)).contains(centre)) return index;
    }
    return -1;
  }

  group('a strip refuses the configurations that cannot work', () {
    test('one tab is refused', () {
      expect(
        () => IuxTabs(
          label: _stripName,
          tabs: const <String>['All'],
          selectedIndex: 0,
          onTabSelected: (_) {},
        ),
        throwsAssertionError,
      );
    });

    test('six tabs are refused', () {
      expect(
        () => IuxTabs(
          label: _stripName,
          tabs: const <String>[..._names, 'Spam'],
          selectedIndex: 0,
          onTabSelected: (_) {},
        ),
        throwsAssertionError,
      );
    });

    test('a current tab outside the set is refused', () {
      expect(
        () => IuxTabs(
          label: _stripName,
          tabs: const <String>['All', 'Unread'],
          selectedIndex: 2,
          onTabSelected: (_) {},
        ),
        throwsAssertionError,
      );
    });

    test('an unnamed strip is refused', () {
      expect(
        () => IuxTabs(
          label: '',
          tabs: const <String>['All', 'Unread'],
          selectedIndex: 0,
          onTabSelected: (_) {},
        ),
        throwsAssertionError,
      );
    });

    test('an unnamed tab is refused', () {
      expect(
        () => IuxTabs(
          label: _stripName,
          tabs: const <String>['All', ''],
          selectedIndex: 0,
          onTabSelected: (_) {},
        ),
        throwsAssertionError,
      );
    });

    test('two tabs with the same name are refused', () {
      expect(
        () => IuxTabs(
          label: _stripName,
          tabs: const <String>['All', 'All'],
          selectedIndex: 0,
          onTabSelected: (_) {},
        ),
        throwsAssertionError,
      );
    });

    test('two tabs are the floor, not an error', () {
      expect(
        () => IuxTabs(
          label: _stripName,
          tabs: const <String>['All', 'Unread'],
          selectedIndex: 0,
          onTabSelected: (_) {},
        ),
        returnsNormally,
      );
    });
  });

  group('the strip says what it is, in the semantics', () {
    testWidgets('the container is a tab bar carrying the caller\'s name',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester, strip());

      final SemanticsNode bar = barNode(tester);
      expect(bar.getSemanticsData().label, _stripName);
      expect(bar.childrenCount, 3);
      handle.dispose();
    });

    testWidgets('every semantic child of the bar is a tab',
        (WidgetTester tester) async {
      // Flutter rejects a tab bar whose children are not tabs, so this is the
      // invariant that keeps anything else — a divider, a scroll view, a stray
      // line of text — out of the strip.
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester, strip(count: 5));

      final List<SemanticsRole> roles = <SemanticsRole>[];
      barNode(tester).visitChildren((SemanticsNode child) {
        roles.add(child.getSemanticsData().role);
        return true;
      });
      expect(roles, everyElement(SemanticsRole.tab));
      expect(roles, hasLength(5));
      handle.dispose();
    });

    testWidgets(
        'the selected state is present on every tab, not only the '
        'current one', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester, strip(selectedIndex: 1));

      for (int index = 0; index < 3; index++) {
        final SemanticsData data =
            tester.getSemantics(find.text(_names[index])).getSemanticsData();
        expect(
          data.flagsCollection.isSelected,
          index == 1 ? Tristate.isTrue : Tristate.isFalse,
          reason: 'tab $index must say whether it is selected. Absent, a user '
              'has to sweep the whole strip to find the one that spoke.',
        );
      }
      handle.dispose();
    });

    testWidgets('a tab is named by the caller\'s own string',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester, strip());

      for (final String name in _names.take(3)) {
        expect(
          tester.getSemantics(find.text(name)).getSemanticsData().label,
          name,
        );
      }
      handle.dispose();
    });

    testWidgets('a tab offers something to activate',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester, strip());

      final SemanticsData data =
          tester.getSemantics(find.text(_names[2])).getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      expect(data.flagsCollection.isEnabled, Tristate.isTrue);
      handle.dispose();
    });

    testWidgets('one stop per tab', (WidgetTester tester) async {
      // A gesture detector that describes itself would add a second node per
      // tab. Measured before this component existed: six stops for three tabs.
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester, strip(count: 5));

      expect(stopsBelow(barNode(tester)), 5);
      handle.dispose();
    });

    testWidgets('focus is reported on the tab node itself',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester, strip());

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(
        tester
            .getSemantics(find.text(_names[0]))
            .getSemanticsData()
            .flagsCollection
            .isFocused,
        Tristate.isTrue,
      );
      handle.dispose();
    });
  });

  group('the strip reports and never decides', () {
    testWidgets('tapping a tab reports its index', (WidgetTester tester) async {
      final List<int> chosen = <int>[];
      await pump(tester, strip(onTabSelected: chosen.add));

      await tester.tap(targets().at(2));
      await tester.pump();
      expect(chosen, <int>[2]);
    });

    testWidgets('tapping the current tab reports it too',
        (WidgetTester tester) async {
      final List<int> chosen = <int>[];
      await pump(tester, strip(selectedIndex: 1, onTabSelected: chosen.add));

      await tester.tap(targets().at(1));
      await tester.pump();
      expect(chosen, <int>[1]);
    });

    testWidgets('a parent that ignores the report keeps the old mark',
        (WidgetTester tester) async {
      await pump(tester, strip(selectedIndex: 0));

      await tester.tap(targets().at(2));
      await tester.pumpAndSettle();

      expect(markOf(tester, 0).opacity, 1);
      expect(markOf(tester, 2).opacity, 0);
    });

    testWidgets('the mark follows the parent\'s index',
        (WidgetTester tester) async {
      await pump(tester, strip(selectedIndex: 2));

      expect(markOf(tester, 0).opacity, 0);
      expect(markOf(tester, 2).opacity, 1);
    });
  });

  group('a keyboard reaches every tab and then leaves', () {
    testWidgets('tab visits each tab in order and then the panel',
        (WidgetTester tester) async {
      await pump(
        tester,
        strip(),
        panel: const TextField(key: Key('panel')),
      );

      final List<int> visited = <int>[];
      for (int press = 0; press < 3; press++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        visited.add(focusedTab(tester, 3));
      }
      expect(visited, <int>[0, 1, 2]);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        focusedTab(tester, 3),
        -1,
        reason: 'a fourth Tab must leave the strip rather than cycle inside it',
      );
      expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<TextField>(),
        isNotNull,
      );
    });

    testWidgets('arrow keys move between tabs along the row',
        (WidgetTester tester) async {
      await pump(tester, strip(tabs: const <String>['A', 'B']));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedTab(tester, 2), 0);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(focusedTab(tester, 2), 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(focusedTab(tester, 2), 0);
    });

    testWidgets('arrow keys cross rows when the strip has wrapped',
        (WidgetTester tester) async {
      await pump(tester, strip());

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedTab(tester, 3), 0);

      // Three tabs do not fit on one 320-pixel row, so the third is on a
      // second row and only a vertical key reaches it.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(focusedTab(tester, 3), 2);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(focusedTab(tester, 3), 0);
    });

    testWidgets('enter and space activate the focused tab',
        (WidgetTester tester) async {
      final List<int> chosen = <int>[];
      await pump(tester, strip(onTabSelected: chosen.add));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedTab(tester, 3), 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(chosen, <int>[1, 1]);
    });
  });

  group('a finger can hit every tab', () {
    testWidgets('targets hold the floor at every density, preference and scale',
        (WidgetTester tester) async {
      for (final IuxDensity density in IuxDensity.values) {
        for (final IuxTouchTargetPreference preference
            in IuxTouchTargetPreference.values) {
          for (final double scale in <double>[1, 1.5, 2]) {
            await pump(
              tester,
              strip(count: 5),
              configuration: IuxThemeConfiguration(
                profile: IuxAccessibilityProfile(
                  density: density,
                  touchTarget: preference,
                ),
              ),
              textScale: scale,
            );

            final double floor =
                preference == IuxTouchTargetPreference.comfortable
                    ? IuxTouchTarget.comfortable
                    : IuxTouchTarget.minimum;

            for (int index = 0; index < 5; index++) {
              final Size size = tester.getSize(targets().at(index));
              expect(
                size.width,
                greaterThanOrEqualTo(floor),
                reason: 'tab $index is $size at ${density.name}, '
                    '${preference.name}, ${scale}x',
              );
              expect(
                size.height,
                greaterThanOrEqualTo(floor),
                reason: 'tab $index is $size at ${density.name}, '
                    '${preference.name}, ${scale}x',
              );
            }
          }
        }
      }
    });

    testWidgets('the tabs of a row touch, leaving no dead strip between them',
        (WidgetTester tester) async {
      await pump(tester, strip(tabs: const <String>['A', 'B']));

      final Rect first = tester.getRect(targets().at(0));
      final Rect second = tester.getRect(targets().at(1));
      expect(first.top, second.top);
      expect(second.left, first.right);
    });
  });

  group('enlarged text costs rows, never letters', () {
    testWidgets('every label is still rendered at 300% on a 320-pixel screen',
        (WidgetTester tester) async {
      for (final double scale in <double>[1, 1.25, 1.5, 2, 3]) {
        await pump(tester, strip(count: 5), textScale: scale);
        for (final String name in _names) {
          expect(
            find.text(name),
            findsOneWidget,
            reason: '"$name" disappeared at ${scale}x',
          );
        }
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('no label is truncated or ellipsised',
        (WidgetTester tester) async {
      await pump(tester, strip(count: 5), textScale: 2);

      for (final Text text in tester.widgetList<Text>(find.descendant(
        of: find.byType(IuxTabs),
        matching: find.byType(Text),
      ))) {
        expect(text.maxLines, isNull);
        expect(text.overflow, isNot(TextOverflow.ellipsis));
      }
    });

    testWidgets('the strip grows taller rather than hiding a tab',
        (WidgetTester tester) async {
      await pump(tester, strip(count: 5));
      final double small = tester.getSize(find.byType(IuxTabs)).height;

      await pump(tester, strip(count: 5), textScale: 2);
      final double large = tester.getSize(find.byType(IuxTabs)).height;

      expect(large, greaterThan(small));
    });

    testWidgets('a word too long for the strip takes its own row whole',
        (WidgetTester tester) async {
      await pump(
        tester,
        strip(tabs: const <String>['Ok', 'Notifications']),
        textScale: 3,
      );

      final Rect first = tester.getRect(targets().at(0));
      final Rect second = tester.getRect(targets().at(1));
      expect(second.top, greaterThanOrEqualTo(first.bottom));
      expect(find.text('Notifications'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('the strip never scrolls', () {
    testWidgets('there is no scroll view inside it, at any text size',
        (WidgetTester tester) async {
      for (final double scale in <double>[1, 2, 3]) {
        await pump(tester, strip(count: 5), textScale: scale);
        expect(
          find.descendant(
            of: find.byType(IuxTabs),
            matching: find.byType(Scrollable),
          ),
          findsNothing,
          reason: 'a strip that scrolls hides views the user cannot know are '
              'there',
        );
      }
    });
  });

  group('reading direction', () {
    testWidgets('the first tab is at the start of the reading direction',
        (WidgetTester tester) async {
      await pump(tester, strip(tabs: const <String>['A', 'B']));
      expect(
        tester.getRect(targets().at(0)).left,
        lessThan(tester.getRect(targets().at(1)).left),
      );

      await pump(
        tester,
        strip(tabs: const <String>['A', 'B']),
        direction: TextDirection.rtl,
      );
      expect(
        tester.getRect(targets().at(0)).left,
        greaterThan(tester.getRect(targets().at(1)).left),
      );
    });
  });

  group('themes and motion', () {
    testWidgets('the strip renders in every profile',
        (WidgetTester tester) async {
      for (final IuxThemeConfiguration configuration in _profiles) {
        await pump(tester, strip(count: 5), configuration: configuration);
        expect(find.byType(IuxTabs), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('the current tab is marked by more than its colour',
        (WidgetTester tester) async {
      for (final IuxThemeConfiguration configuration in _profiles) {
        await pump(
          tester,
          strip(count: 3, selectedIndex: 1),
          configuration: configuration,
        );
        expect(markOf(tester, 1).opacity, 1);
        expect(markOf(tester, 0).opacity, 0);
        expect(markOf(tester, 2).opacity, 0);
      }
    });

    testWidgets('the mark still appears when all motion is suppressed',
        (WidgetTester tester) async {
      await pump(
        tester,
        strip(selectedIndex: 1),
        configuration: const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(motion: IuxMotionPreference.none),
        ),
      );

      expect(markOf(tester, 1).opacity, 1);
      expect(markOf(tester, 1).duration, Duration.zero);
    });

    testWidgets(
        'the current label and the others differ in colour but not in '
        'metrics', (WidgetTester tester) async {
      await pump(tester, strip(selectedIndex: 1));

      final TextStyle current =
          tester.widget<Text>(find.text(_names[1])).style!;
      final TextStyle other = tester.widget<Text>(find.text(_names[0])).style!;

      expect(current.color, isNot(other.color));
      expect(current.fontSize, other.fontSize);
      expect(current.fontWeight, other.fontWeight);
    });
  });

  group('the strip is legible in every profile', () {
    /// The resolved appearance of a resting and of a current tab, in
    /// [configuration].
    Future<(IuxTabsTokens, IuxTabsTokens)> tokensFor(
      WidgetTester tester,
      IuxThemeConfiguration configuration,
    ) async {
      late IuxTabsTokens resting;
      late IuxTabsTokens current;
      await tester.pumpWidget(
        MaterialApp(
          theme: IuxTheme.fromConfiguration(configuration),
          home: Builder(
            builder: (BuildContext context) {
              resting = IuxTabsResolver.resolve(context);
              current = IuxTabsResolver.resolve(context, current: true);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      return (resting, current);
    }

    testWidgets('a label that is not the current one is readable on the strip',
        (WidgetTester tester) async {
      for (final IuxThemeConfiguration configuration in _profiles) {
        final (IuxTabsTokens resting, _) =
            await tokensFor(tester, configuration);
        expect(
          ContrastMetric.ratio(resting.labelStyle.color!, resting.background),
          greaterThanOrEqualTo(ContrastMetric.normalText),
        );
      }
    });

    testWidgets('the current label is readable on the mark behind it',
        (WidgetTester tester) async {
      for (final IuxThemeConfiguration configuration in _profiles) {
        final (_, IuxTabsTokens current) =
            await tokensFor(tester, configuration);
        expect(
          ContrastMetric.ratio(
              current.labelStyle.color!, current.indicatorFill),
          greaterThanOrEqualTo(ContrastMetric.normalText),
        );
      }
    });

    testWidgets('the mark is a shape a user can see without reading colour',
        (WidgetTester tester) async {
      // The outline, not the fill. Surface contrast is deliberately gentle in
      // IUX, so the outline is what carries the mark for a user who cannot
      // distinguish two nearby surfaces.
      for (final IuxThemeConfiguration configuration in _profiles) {
        final (_, IuxTabsTokens current) =
            await tokensFor(tester, configuration);
        expect(
          ContrastMetric.ratio(current.indicatorBorder, current.background),
          greaterThanOrEqualTo(ContrastMetric.nonText),
        );
      }
    });

    testWidgets('the line between the strip and its panel is visible',
        (WidgetTester tester) async {
      for (final IuxThemeConfiguration configuration in _profiles) {
        final (IuxTabsTokens resting, _) =
            await tokensFor(tester, configuration);
        expect(
          ContrastMetric.ratio(resting.separator, resting.background),
          greaterThanOrEqualTo(ContrastMetric.nonText),
        );
      }
    });
  });

  group('the resolved appearance is a value', () {
    testWidgets('two resolutions of the same state are equal',
        (WidgetTester tester) async {
      late IuxTabsTokens first;
      late IuxTabsTokens second;

      await tester.pumpWidget(
        MaterialApp(
          theme: IuxTheme.fromConfiguration(const IuxThemeConfiguration()),
          home: Builder(
            builder: (BuildContext context) {
              first = IuxTabsResolver.resolve(context, current: true);
              second = IuxTabsResolver.resolve(context, current: true);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    testWidgets('a pressed tab resolves differently from a resting one',
        (WidgetTester tester) async {
      late IuxTabsTokens resting;
      late IuxTabsTokens pressed;

      await tester.pumpWidget(
        MaterialApp(
          theme: IuxTheme.fromConfiguration(const IuxThemeConfiguration()),
          home: Builder(
            builder: (BuildContext context) {
              resting = IuxTabsResolver.resolve(context);
              pressed = IuxTabsResolver.resolve(context, pressed: true);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resting.overlayOpacity, 0);
      expect(pressed.overlayOpacity, 1);
      expect(resting, isNot(pressed));
    });
  });
}
