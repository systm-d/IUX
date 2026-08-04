// Rebuild scope. What does a screen built from IUX components rebuild when
// something changes, and is any of it avoidable?
//
// Every number in this file was measured with `debugOnRebuildDirtyWidget`,
// Flutter's own per-element build hook, on Flutter 3.44.8 / Dart 3.12.2, and
// none of it is inferred from reading the code. The counts are recorded as
// ceilings rather than equalities: the point is to catch a regression, not to
// freeze an implementation detail of the framework underneath.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

/// Holds one widget instance for the lifetime of a test.
///
/// A `MediaQuery` above this can change without the subtree being rebuilt for
/// any reason other than a real dependency: `ValueListenableBuilder.child` is
/// passed through untouched, so `Element.updateChild` sees the same instance
/// and stops there. Without it every measurement below would report the whole
/// subtree and mean nothing.
class _Frozen extends StatefulWidget {
  const _Frozen({required this.notifier, required this.build});

  final ValueNotifier<MediaQueryData> notifier;
  final Widget Function() build;

  @override
  State<_Frozen> createState() => _FrozenState();
}

class _FrozenState extends State<_Frozen> {
  late final Widget _content = widget.build();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MediaQueryData>(
      valueListenable: widget.notifier,
      child: _content,
      builder: (BuildContext context, MediaQueryData data, Widget? child) =>
          MediaQuery(data: data, child: child!),
    );
  }
}

/// Reads the IUX accessibility runtime, as 34 call sites in `lib/` do.
class _ReadsRuntime extends StatelessWidget {
  const _ReadsRuntime();

  @override
  Widget build(BuildContext context) {
    final IuxAccessibility a11y = IuxAccessibility.of(context);
    return SizedBox(height: 1, width: a11y.minimumTouchTarget);
  }
}

/// Reads the same six platform values, one `MediaQuery` aspect at a time.
class _ReadsAspects extends StatelessWidget {
  const _ReadsAspects();

  @override
  Widget build(BuildContext context) {
    MediaQuery.textScalerOf(context);
    MediaQuery.highContrastOf(context);
    MediaQuery.disableAnimationsOf(context);
    MediaQuery.boldTextOf(context);
    MediaQuery.invertColorsOf(context);
    MediaQuery.accessibleNavigationOf(context);
    return const SizedBox(height: 1, width: 48);
  }
}

/// A screen of the shape an application actually builds.
class _Screen extends StatefulWidget {
  const _Screen();

  @override
  State<_Screen> createState() => _ScreenState();
}

class _ScreenState extends State<_Screen> {
  final TextEditingController _controller = TextEditingController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        children: <Widget>[
          IuxAppBar(
            title: 'Invoices',
            actions: <IuxIconButton>[
              IuxIconButton(
                icon: Icons.search,
                action: const IuxActionDescriptor(
                  semantics: IuxActionSemantics(label: 'Search'),
                ),
                onActivate: () {},
              ),
            ],
          ),
          Expanded(
            child: IuxPage(
              insets: IuxPageInsets.none,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const IuxCard(child: Text('March invoice')),
                  const IuxStatusIndicator(status: IuxStatus.success('Paid')),
                  IuxTextField(
                    input: const IuxInputDescriptor(
                      semantics: IuxInputSemantics(label: 'Reference'),
                    ),
                    controller: _controller,
                    onChanged: (String value) {},
                  ),
                  IuxButton(
                    label: 'Save',
                    action: const IuxActionDescriptor.primary(
                      semantics: IuxActionSemantics(label: 'Save'),
                    ),
                    onActivate: () {},
                  ),
                  IuxButton(
                    label: 'Cancel',
                    action: const IuxActionDescriptor(
                      semantics: IuxActionSemantics(label: 'Cancel'),
                    ),
                    onActivate: () {},
                  ),
                ],
              ),
            ),
          ),
          IuxBottomNavigation(
            label: 'Sections',
            selectedIndex: _index,
            onDestinationSelected: (int i) => setState(() => _index = i),
            destinations: const <IuxNavigationDestination>[
              IuxNavigationDestination(label: 'Home', icon: Icons.home),
              IuxNavigationDestination(label: 'Bills', icon: Icons.receipt),
              IuxNavigationDestination(label: 'Settings', icon: Icons.settings),
            ],
          ),
        ],
      ),
    );
  }
}

void main() {
  const MediaQueryData base = MediaQueryData(size: Size(400, 800));

  late Map<String, int> counts;

  setUp(() => counts = <String, int>{});
  tearDown(() => debugOnRebuildDirtyWidget = null);

  void instrument() {
    // `builtOnce` is deliberately ignored: the framework only maintains it
    // when `debugPrintRebuildDirtyWidgets` is on, so it reads false forever
    // otherwise. Counting every call and clearing the map immediately before
    // the stimulus gives the same answer for a settled tree.
    debugOnRebuildDirtyWidget = (Element element, bool builtOnce) {
      final String name = element.widget.runtimeType.toString();
      counts[name] = (counts[name] ?? 0) + 1;
    };
  }

  /// Builds [child] under an IUX theme, settles, then applies [next] and
  /// returns how many elements were built in that one frame.
  Future<int> built(
    WidgetTester tester,
    Widget Function() child,
    MediaQueryData next,
  ) async {
    final ValueNotifier<MediaQueryData> notifier =
        ValueNotifier<MediaQueryData>(base);
    addTearDown(notifier.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: IuxTheme.light(),
        home: _Frozen(notifier: notifier, build: child),
      ),
    );
    await tester.pumpAndSettle();

    counts.clear();
    instrument();
    notifier.value = next;
    await tester.pump();
    debugOnRebuildDirtyWidget = null;
    await tester.pumpAndSettle();
    return counts.values.fold<int>(0, (int a, int b) => a + b);
  }

  group('a change nothing depends on', () {
    // `IuxAccessibility.of` resolves six platform values through
    // `MediaQuery.of`, which registers a dependency on *every* aspect of the
    // media query rather than on the six it reads. These two widgets read the
    // same six values and differ in nothing else.
    //
    // Measured: 20 of 20 against 0 of 20 for viewInsets, padding and size;
    // 20 of 20 for both on textScaler, which is one of the six.
    Future<int> rebuilt(
      WidgetTester tester,
      Widget probe,
      MediaQueryData next,
    ) async {
      final ValueNotifier<MediaQueryData> notifier =
          ValueNotifier<MediaQueryData>(base);
      addTearDown(notifier.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: IuxTheme.light(),
          home: _Frozen(
            notifier: notifier,
            build: () => Column(children: List<Widget>.filled(20, probe)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      counts.clear();
      instrument();
      notifier.value = next;
      await tester.pump();
      debugOnRebuildDirtyWidget = null;
      return counts[probe.runtimeType.toString()] ?? 0;
    }

    final Map<String, MediaQueryData> irrelevant = <String, MediaQueryData>{
      'the software keyboard opening': base.copyWith(
        viewInsets: const EdgeInsets.only(bottom: 300),
      ),
      'a notch being reported': base.copyWith(
        padding: const EdgeInsets.only(top: 24),
      ),
      'the device rotating': base.copyWith(size: const Size(800, 400)),
    };

    for (final MapEntry<String, MediaQueryData> stimulus
        in irrelevant.entries) {
      testWidgets('${stimulus.key} rebuilds every reader of the runtime', (
        WidgetTester tester,
      ) async {
        expect(
          await rebuilt(tester, const _ReadsRuntime(), stimulus.value),
          20,
          reason: 'IuxAccessibility.of resolves through MediaQuery.of, which '
              'depends on every aspect. None of the six values it reads has '
              'changed. This is a known cost, not an intended behaviour: if '
              'it ever reports 0, the runtime has been narrowed to aspects '
              'and this expectation should become the new one.',
        );
      });

      testWidgets('${stimulus.key} rebuilds no reader of the six aspects', (
        WidgetTester tester,
      ) async {
        expect(
          await rebuilt(tester, const _ReadsAspects(), stimulus.value),
          0,
          reason: 'the control: reading the same six values one aspect at a '
              'time costs nothing when something else changes',
        );
      });
    }

    // Enlarging text is one of the six, so both must react. Two tests rather
    // than two expectations in one: `_Frozen` holds its child for the lifetime
    // of the element, which is what makes the measurement meaningful and also
    // what stops a second `pumpWidget` in the same test from swapping the
    // probe.
    final MediaQueryData scaled = base.copyWith(
      textScaler: const TextScaler.linear(1.5),
    );

    testWidgets('enlarging text rebuilds every reader of the runtime', (
      WidgetTester tester,
    ) async {
      expect(await rebuilt(tester, const _ReadsRuntime(), scaled), 20);
    });

    testWidgets('enlarging text rebuilds every reader of the aspects', (
      WidgetTester tester,
    ) async {
      expect(await rebuilt(tester, const _ReadsAspects(), scaled), 20);
    });
  });

  group('a whole screen', () {
    // Measured on 2026-08-04, Flutter 3.44.8: 106 elements for the keyboard,
    // 93 for the notch, 122 for the rotation, 132 for the text scale. The
    // same screen built from Material widgets, identical in element count
    // (518), rebuilds 14, 6, 30 and 112. The ceilings below sit well above
    // the measurement so that a Flutter upgrade does not fail the suite for
    // no reason; halving them would be the sign that the runtime has been
    // narrowed.
    testWidgets('the keyboard opening stays under its ceiling', (
      WidgetTester tester,
    ) async {
      final int n = await built(
        tester,
        () => const _Screen(),
        base.copyWith(viewInsets: const EdgeInsets.only(bottom: 300)),
      );
      expect(n, lessThan(160), reason: 'measured 106');
      expect(n, greaterThan(0));
    });

    testWidgets('a reported notch stays under its ceiling', (
      WidgetTester tester,
    ) async {
      final int n = await built(
        tester,
        () => const _Screen(),
        base.copyWith(padding: const EdgeInsets.only(top: 24)),
      );
      expect(n, lessThan(160), reason: 'measured 93');
    });

    testWidgets('enlarging text stays under its ceiling', (
      WidgetTester tester,
    ) async {
      final int n = await built(
        tester,
        () => const _Screen(),
        base.copyWith(textScaler: const TextScaler.linear(1.5)),
      );
      expect(
        n,
        lessThan(220),
        reason: 'measured 132, and every one of them '
            'is a rebuild the change genuinely requires',
      );
    });
  });
}
