import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

import '../support/gestures.dart';

/// Presses every component that redraws while it is held, the way a finger
/// does.
///
/// This file exists because of what `IUX-SELECTION-PRESS-001` proved about the
/// rest of the suite rather than about the selection controls. Three controls
/// shipped unable to respond to a finger while every tap test written against
/// them passed, because `tester.tap()` sends `down` and `up` with no frame in
/// between and the defect only exists in that frame. The instrument could not
/// reach it. Nothing about the defect was specific to selection.
///
/// So the question this file asks is not *does this component work* — the
/// component's own file asks that, far more thoroughly. It is the narrower one
/// that was never asked anywhere: **does it still work when the press and the
/// release are a frame apart.** One case per component, deliberately: the value
/// is in the list being complete, not in any single entry being deep.
///
/// The list is every component in `lib/` that holds press state and rebuilds
/// on it — the ones that carry the risk. Adding a component with press
/// feedback and not adding it here is the way this file stops being a sweep.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: IuxTheme.fromConfiguration(const IuxThemeConfiguration()),
        home: Scaffold(body: child),
      ),
    );
    await tester.pumpAndSettle();
  }

  const IuxActionDescriptor save = IuxActionDescriptor(
    semantics: IuxActionSemantics(label: 'Save'),
  );

  List<IuxNavigationDestination> destinations() =>
      const <IuxNavigationDestination>[
        IuxNavigationDestination(label: 'Home', icon: Icons.home_outlined),
        IuxNavigationDestination(label: 'Messages', icon: Icons.mail_outline),
        IuxNavigationDestination(label: 'Account', icon: Icons.person_outline),
      ];

  group('a press and a release a frame apart still activates', () {
    testWidgets('IuxButton', (WidgetTester tester) async {
      final List<int> taps = <int>[];
      await pump(
        tester,
        IuxButton(
          label: 'Save',
          action: save,
          onActivate: () => taps.add(taps.length),
        ),
      );

      await realTap(tester, find.text('Save'));

      expect(taps, <int>[0]);
    });

    testWidgets('IuxIconButton', (WidgetTester tester) async {
      final List<int> taps = <int>[];
      await pump(
        tester,
        IuxIconButton(
          icon: Icons.search,
          action: const IuxActionDescriptor(
            semantics: IuxActionSemantics(label: 'Search'),
          ),
          onActivate: () => taps.add(taps.length),
        ),
      );

      await realTap(tester, find.byType(IuxIconButton));

      expect(taps, <int>[0]);
    });

    testWidgets('IuxFilterChip', (WidgetTester tester) async {
      final List<bool> asked = <bool>[];
      await pump(
        tester,
        IuxChipGroup(
          label: 'Filter by category',
          chips: <Widget>[
            IuxFilterChip(
              label: 'Vegetarian',
              selected: false,
              onSelectionChanged: asked.add,
            ),
          ],
        ),
      );

      await realTap(tester, find.text('Vegetarian'));

      expect(asked, <bool>[true]);
    });

    testWidgets('IuxCard.tappable', (WidgetTester tester) async {
      final List<int> taps = <int>[];
      await pump(
        tester,
        IuxCard.tappable(
          semanticLabel: 'Open order 3141',
          onActivate: () => taps.add(taps.length),
          child: const Text('Order 3141'),
        ),
      );

      await realTap(tester, find.text('Order 3141'));

      expect(taps, <int>[0]);
    });

    testWidgets('IuxListItem.tappable', (WidgetTester tester) async {
      final List<int> taps = <int>[];
      await pump(
        tester,
        IuxListItem.tappable(
          title: 'Order 3141',
          onActivate: () => taps.add(taps.length),
        ),
      );

      await realTap(tester, find.text('Order 3141'));

      expect(taps, <int>[0]);
    });

    testWidgets('IuxCheckbox', (WidgetTester tester) async {
      final List<bool> asked = <bool>[];
      await pump(
        tester,
        IuxCheckbox(
          label: 'Send me the newsletter',
          input: const IuxInputDescriptor(
            semantics: IuxInputSemantics(label: 'Send me the newsletter'),
          ),
          value: IuxSelectionState.unselected,
          onChanged: asked.add,
        ),
      );

      await realTap(tester, find.text('Send me the newsletter'));

      expect(asked, <bool>[true]);
    });

    testWidgets('IuxSwitch', (WidgetTester tester) async {
      final List<bool> asked = <bool>[];
      await pump(
        tester,
        IuxSwitch(
          label: 'Use mobile data',
          input: const IuxInputDescriptor(
            semantics: IuxInputSemantics(label: 'Use mobile data'),
          ),
          value: IuxSelectionState.unselected,
          onChanged: asked.add,
        ),
      );

      await realTap(tester, find.text('Use mobile data'));

      expect(asked, <bool>[true]);
    });

    testWidgets('IuxRadioGroup', (WidgetTester tester) async {
      final List<String> chosen = <String>[];
      await pump(
        tester,
        IuxRadioGroup<String>(
          label: 'Delivery speed',
          input: const IuxInputDescriptor(
            semantics: IuxInputSemantics(label: 'How fast do you need it'),
          ),
          value: 'standard',
          options: const <IuxRadioOption<String>>[
            IuxRadioOption<String>(value: 'standard', label: 'Standard'),
            IuxRadioOption<String>(value: 'express', label: 'Express'),
          ],
          onChanged: chosen.add,
        ),
      );

      await realTap(tester, find.text('Express'));

      expect(chosen, <String>['express']);
    });

    testWidgets('IuxBottomNavigation', (WidgetTester tester) async {
      final List<int> chosen = <int>[];
      await pump(
        tester,
        Column(
          children: <Widget>[
            const Expanded(child: SizedBox.expand()),
            IuxBottomNavigation(
              label: 'Main navigation',
              destinations: destinations(),
              selectedIndex: 0,
              onDestinationSelected: chosen.add,
            ),
          ],
        ),
      );

      await realTap(tester, find.text('Messages'));

      expect(chosen, <int>[1]);
    });

    testWidgets('IuxNavigationRail', (WidgetTester tester) async {
      final List<int> chosen = <int>[];
      await pump(
        tester,
        Row(
          children: <Widget>[
            IuxNavigationRail(
              label: 'Main navigation',
              destinations: destinations(),
              selectedIndex: 0,
              onDestinationSelected: chosen.add,
            ),
            const Expanded(child: SizedBox.expand()),
          ],
        ),
      );

      await realTap(tester, find.text('Messages'));

      expect(chosen, <int>[1]);
    });

    testWidgets('IuxNavigationDrawer', (WidgetTester tester) async {
      final List<int> chosen = <int>[];
      await pump(
        tester,
        Stack(
          fit: StackFit.expand,
          children: <Widget>[
            const SizedBox.expand(),
            IuxNavigationDrawer(
              title: 'Sections',
              dismissLabel: 'Close',
              onDismiss: () {},
              destinations: destinations(),
              selectedIndex: 0,
              onDestinationSelected: chosen.add,
            ),
          ],
        ),
      );

      await realTap(tester, find.text('Messages'));

      expect(chosen, <int>[1]);
    });

    testWidgets('IuxTabs', (WidgetTester tester) async {
      final List<int> chosen = <int>[];
      await pump(
        tester,
        IuxTabs(
          label: 'Order sections',
          tabs: const <String>['All', 'Open', 'Closed'],
          selectedIndex: 0,
          onTabSelected: chosen.add,
        ),
      );

      await realTap(tester, find.text('Open'));

      expect(chosen, <int>[1]);
    });
  });

  // The list above is only worth having if it is complete, and a list kept
  // complete by remembering is a list that is complete until the next
  // component. This reads the library and asks the question the other way
  // round: every source that holds press state has to be named here.
  //
  // `bool _pressed` is the marker because it is what the defect needs — a
  // field whose change rebuilds the subtree while a pointer is down. A
  // component that redraws on press without one (the transient layer pauses
  // its timer on a hold, and rebuilds nothing) cannot lose a recogniser this
  // way, and is deliberately not required here.
  group('every component that holds press state is swept', () {
    final File sweep = File('test/components/press_feedback_sweep_test.dart');
    final String sweptText = sweep.readAsStringSync();

    test('this file can read itself', () {
      expect(sweep.existsSync(), isTrue);
    });

    final List<File> sources = Directory('lib/src')
        .listSync(recursive: true)
        .whereType<File>()
        .where((File file) => file.path.endsWith('.dart'))
        .where((File file) => file.readAsStringSync().contains('bool _pressed'))
        .toList();

    test('the library has components that hold press state', () {
      expect(sources, isNotEmpty);
    });

    for (final File source in sources) {
      test(source.path, () {
        final List<String> exported = _publicWidgets(source.readAsStringSync());
        expect(
          exported,
          isNotEmpty,
          reason: '${source.path} holds press state but declares no public '
              'IUX widget, so this check cannot name what to sweep. Widen '
              '_publicWidgets or sweep it by hand.',
        );
        expect(
          exported.any(sweptText.contains),
          isTrue,
          reason: '${source.path} holds press state — it rebuilds while a '
              'pointer is down — and none of the widgets it declares '
              '($exported) is pressed in this file. That is the exact shape '
              'of IUX-SELECTION-PRESS-001: a rebuild mid-gesture can throw '
              'away the recogniser tracking the pointer, and no test using '
              'tester.tap() can see it. Add a realTap case above.',
        );
      });
    }
  });
}

/// The public IUX widget names a source declares.
///
/// Deliberately crude — a regular expression over `class Iux…`, not an
/// analysis. It only has to produce a name this file can be searched for, and
/// a private class is filtered by the `Iux` prefix the package already
/// enforces on everything it exports.
List<String> _publicWidgets(String source) =>
    RegExp(r'^class (Iux\w+)', multiLine: true)
        .allMatches(source)
        .map((RegExpMatch match) => match.group(1)!)
        .toList();
