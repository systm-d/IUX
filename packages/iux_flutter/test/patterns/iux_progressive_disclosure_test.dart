// Tristate is declared in `dart:ui` and is not re-exported by
// `package:flutter/semantics.dart`, so this is the only way to name it. It is
// what distinguishes "collapsed" from "has no open state at all", which is the
// difference between the disclosure control and the heading that replaces it.
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';
// Imported from source rather than from the barrel: IUX-035 does not own
// lib/iux_flutter.dart, so the exports are added by whoever integrates the
// mission. The behaviour asserted here is the same either way.

import '../support/contrast.dart';

/// The four conditions every IUX component and pattern is held to.
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

const String _summary = 'Delivery options';
const String _bodyText = 'Leave the parcel with a neighbour if nobody answers.';
const String _innerControl = 'Choose a neighbour';

/// Content that contains a control, which is the whole difference between this
/// pattern and `IuxContextualHelp`. A string could never be tabbed into.
class _Content extends StatelessWidget {
  const _Content({this.focusNode});

  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text(_bodyText),
          IuxButton(
            label: _innerControl,
            action: const IuxActionDescriptor(
              semantics: IuxActionSemantics(label: _innerControl),
            ),
            focusNode: focusNode,
            onActivate: () {},
          ),
        ],
      );
}

/// A parent that owns the disclosure state, exactly as a real one does. The
/// pattern never opens or closes itself.
class _DisclosureHost extends StatefulWidget {
  const _DisclosureHost({
    super.key,
    this.initial = const IuxDisclosureState.collapsed(),
    this.accept = true,
    this.summary = _summary,
    this.controlFocus,
    this.contentFocus,
  });

  final IuxDisclosureState initial;

  /// Whether the parent acts on what the user asked for.
  final bool accept;
  final String summary;
  final FocusNode? controlFocus;
  final FocusNode? contentFocus;

  @override
  State<_DisclosureHost> createState() => _DisclosureHostState();
}

class _DisclosureHostState extends State<_DisclosureHost> {
  late IuxDisclosureState state = widget.initial;

  /// Every value the pattern has asked the parent for.
  final List<bool> requested = <bool>[];

  /// Drives the state from outside, the way a submission would.
  void set(IuxDisclosureState next) => setState(() => state = next);

  @override
  Widget build(BuildContext context) => IuxProgressiveDisclosure(
        summary: widget.summary,
        state: state,
        focusNode: widget.controlFocus,
        onExpandedChanged: (bool value) {
          requested.add(value);
          if (!widget.accept) return;
          setState(() => state = value
              ? const IuxDisclosureState.expanded()
              : const IuxDisclosureState.collapsed());
        },
        child: _Content(focusNode: widget.contentFocus),
      );
}

void main() {
  Future<void> host(
    WidgetTester tester,
    Widget child, {
    IuxThemeConfiguration configuration = const IuxThemeConfiguration(),
    TextDirection direction = TextDirection.ltr,
    double textScale = 1,
    Size size = const Size(400, 800),
    Alignment alignment = Alignment.center,
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
          key: ValueKey<IuxThemeConfiguration>(configuration),
          theme: IuxTheme.fromConfiguration(configuration),
          home: Directionality(
            textDirection: direction,
            child: Scaffold(
              body: Align(alignment: alignment, child: child),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('the state a disclosure can be in', () {
    test('the three states are values, so a rebuild is not a change', () {
      expect(
        const IuxDisclosureState.collapsed(),
        const IuxDisclosureState.collapsed(),
      );
      expect(
        const IuxDisclosureState.expanded(),
        const IuxDisclosureState.expanded(),
      );
      expect(
        const IuxDisclosureState.heldOpen(),
        const IuxDisclosureState.heldOpen(),
      );
      expect(
        const IuxDisclosureState.collapsed(),
        isNot(const IuxDisclosureState.expanded()),
      );
      expect(
        const IuxDisclosureState.expanded(),
        isNot(const IuxDisclosureState.heldOpen()),
      );
    });

    test('equal states agree on their hash code', () {
      // A value whose `==` and `hashCode` disagree goes into a Set twice and
      // comes out of a Map never, which is how a rebuild starts looking like a
      // state change.
      const List<IuxDisclosureState> every = <IuxDisclosureState>[
        IuxDisclosureState.collapsed(),
        IuxDisclosureState.expanded(),
        IuxDisclosureState.heldOpen(),
      ];
      expect(<IuxDisclosureState>[...every, ...every].toSet(), hasLength(3));
    });

    test('each state says what it is, for a debugger and a failure message',
        () {
      expect(
        const IuxDisclosureState.collapsed().toString(),
        'IuxDisclosureState.collapsed()',
      );
      expect(
        const IuxDisclosureState.heldOpen().toString(),
        'IuxDisclosureState.heldOpen()',
      );
    });

    test('closed-while-it-matters is not a value that exists', () {
      // The point of the sealed type, asserted the only way a type-level
      // guarantee can be: by enumerating what can be constructed. Two booleans
      // would have four combinations and one of them — collapsed while the
      // content must be dealt with — is the defect this pattern exists to
      // prevent. Three states, and it is not among them.
      const List<IuxDisclosureState> every = <IuxDisclosureState>[
        IuxDisclosureState.collapsed(),
        IuxDisclosureState.expanded(),
        IuxDisclosureState.heldOpen(),
      ];
      expect(every.whereType<IuxDisclosureHeldOpen>(), hasLength(1));
      expect(
        every.whereType<IuxDisclosureCollapsed>().first,
        isNot(isA<IuxDisclosureHeldOpen>()),
      );
    });

    test('a disclosure with nothing to say is refused', () {
      expect(
        () => IuxProgressiveDisclosure(
          summary: '',
          state: const IuxDisclosureState.collapsed(),
          onExpandedChanged: (bool _) {},
          child: const SizedBox.shrink(),
        ),
        throwsAssertionError,
      );
    });
  });

  group('the control announces what it is and whether it is open', () {
    testWidgets('name, button role and open state are on one node',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(tester, const _DisclosureHost());

      final SemanticsNode collapsed =
          tester.getSemantics(find.bySemanticsLabel(_summary));
      // The three assertions that matter are on *this* node. A separate node
      // carrying the state would be a fragment the user meets somewhere else,
      // or not at all.
      expect(collapsed.label, _summary);
      expect(collapsed.flagsCollection.isButton, isTrue);
      // Not `none`: the platform is told the control *has* an open state, which
      // is what lets it say "collapsed" before the user presses.
      expect(collapsed.flagsCollection.isExpanded, Tristate.isFalse);
      expect(
        collapsed.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
      );

      await tester.tap(find.text(_summary));
      await tester.pumpAndSettle();

      final SemanticsNode expanded =
          tester.getSemantics(find.bySemanticsLabel(_summary));
      expect(expanded.label, _summary);
      expect(expanded.flagsCollection.isExpanded, Tristate.isTrue);
      handle.dispose();
    });

    testWidgets('a screen-reader activation opens it',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final GlobalKey<_DisclosureHostState> key =
          GlobalKey<_DisclosureHostState>();
      await host(tester, _DisclosureHost(key: key));

      final SemanticsNode node =
          tester.getSemantics(find.bySemanticsLabel(_summary));
      // performAction is the closest a widget test gets to TalkBack's
      // double-tap: it invokes the action the platform would.
      // ignore: deprecated_member_use
      tester.binding.pipelineOwner.semanticsOwner!
          .performAction(node.id, SemanticsAction.tap);
      await tester.pumpAndSettle();

      expect(key.currentState!.requested, <bool>[true]);
      expect(find.text(_bodyText), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the chevron adds no announcement of its own',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(tester, const _DisclosureHost());
      expect(
        tester.getSemantics(find.bySemanticsLabel(_summary)).label,
        _summary,
      );
      handle.dispose();
    });

    testWidgets('the open state is carried by a shape as well as by speech',
        (WidgetTester tester) async {
      // Render the screen in one hue and every state carried by colour alone
      // disappears. A direction survives it.
      await host(tester, const _DisclosureHost());
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
      expect(find.byIcon(Icons.expand_less), findsNothing);

      await tester.tap(find.text(_summary));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.expand_less), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsNothing);
    });

    testWidgets('the revealed region is not announced a second time',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(
        tester,
        const _DisclosureHost(initial: IuxDisclosureState.expanded()),
      );
      expect(
        tester.getSemantics(find.text(_bodyText)).flagsCollection.isLiveRegion,
        isFalse,
      );
      handle.dispose();
    });

    testWidgets('the keyboard opens it without a pointer',
        (WidgetTester tester) async {
      final FocusNode control = FocusNode();
      addTearDown(control.dispose);
      final GlobalKey<_DisclosureHostState> key =
          GlobalKey<_DisclosureHostState>();
      await host(tester, _DisclosureHost(key: key, controlFocus: control));

      control.requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(key.currentState!.requested, <bool>[true]);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(key.currentState!.requested, <bool>[true, false]);
    });

    testWidgets(
        'a parent that ignores the request gets a section that stays '
        'shut', (WidgetTester tester) async {
      final GlobalKey<_DisclosureHostState> key =
          GlobalKey<_DisclosureHostState>();
      await host(tester, _DisclosureHost(key: key, accept: false));

      await tester.tap(find.text(_summary));
      await tester.pumpAndSettle();

      expect(key.currentState!.requested, <bool>[true]);
      expect(find.text(_bodyText), findsNothing);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
    });
  });

  group('hidden means absent, not invisible', () {
    testWidgets('a collapsed section builds none of its content',
        (WidgetTester tester) async {
      await host(tester, const _DisclosureHost());
      expect(find.text(_bodyText), findsNothing);
      expect(find.byType(IuxButton), findsNothing);

      // The ways of getting this wrong all leave the subtree mounted and all
      // look correct on screen. Scoped to this pattern's own subtree: the
      // scaffolding around it has an Offstage of its own, which is not the
      // question being asked.
      for (final Type hider in <Type>[Offstage, Visibility, Opacity]) {
        expect(
          find.descendant(
            of: find.byType(IuxProgressiveDisclosure),
            matching: find.byType(hider),
          ),
          findsNothing,
          reason: '$hider hides content without removing it, so a keyboard '
              'user still tabs into it and a screen reader still reads it',
        );
      }
    });

    testWidgets(
        'a control inside a collapsed section is not in the semantics '
        'tree', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(tester, const _DisclosureHost());
      expect(find.bySemanticsLabel(_innerControl), findsNothing);

      await tester.tap(find.text(_summary));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(_innerControl), findsOneWidget);
      handle.dispose();
    });

    testWidgets(
        'a control inside a collapsed section is not in the focus '
        'order', (WidgetTester tester) async {
      final FocusNode control = FocusNode();
      final FocusNode inner = FocusNode();
      addTearDown(control.dispose);
      addTearDown(inner.dispose);

      await host(
        tester,
        _DisclosureHost(controlFocus: control, contentFocus: inner),
      );

      // Not merely unfocused — absent from the traversal tree. This is the
      // guarantee a keyboard user needs, and it is asked of the focus manager
      // rather than of the node: `FocusNode.context` keeps pointing at a
      // defunct element after an unmount, so it answers a different question.
      expect(
        FocusManager.instance.rootScope.descendants.contains(inner),
        isFalse,
      );

      control.requestFocus();
      await tester.pumpAndSettle();
      control.nextFocus();
      await tester.pumpAndSettle();
      expect(inner.hasFocus, isFalse);
    });

    testWidgets('once revealed, the content is the next focus stop',
        (WidgetTester tester) async {
      final FocusNode control = FocusNode();
      final FocusNode inner = FocusNode();
      addTearDown(control.dispose);
      addTearDown(inner.dispose);

      await host(
        tester,
        _DisclosureHost(
          initial: const IuxDisclosureState.expanded(),
          controlFocus: control,
          contentFocus: inner,
        ),
      );

      control.requestFocus();
      await tester.pumpAndSettle();
      control.nextFocus();
      await tester.pumpAndSettle();

      // Adjacency in the tree is the whole association between the control and
      // what it opens: Flutter's semantics have no `aria-controls`.
      expect(inner.hasFocus, isTrue);
    });

    testWidgets('closing it takes the content back out of the tree',
        (WidgetTester tester) async {
      final FocusNode inner = FocusNode();
      addTearDown(inner.dispose);
      await host(
        tester,
        _DisclosureHost(
          initial: const IuxDisclosureState.expanded(),
          contentFocus: inner,
        ),
      );
      expect(
        FocusManager.instance.rootScope.descendants.contains(inner),
        isTrue,
      );

      await tester.tap(find.text(_summary));
      await tester.pumpAndSettle();
      expect(find.text(_bodyText), findsNothing);
      expect(
        FocusManager.instance.rootScope.descendants.contains(inner),
        isFalse,
        reason: 'a closed section leaves nothing behind in the focus order',
      );
    });
  });

  group('opening a section does not take focus away from the user', () {
    testWidgets('focus stays on the control that was pressed',
        (WidgetTester tester) async {
      final FocusNode control = FocusNode();
      addTearDown(control.dispose);
      await host(tester, _DisclosureHost(controlFocus: control));

      control.requestFocus();
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus, control);

      await tester.tap(find.text(_summary));
      await tester.pumpAndSettle();

      expect(find.text(_bodyText), findsOneWidget);
      expect(
        FocusManager.instance.primaryFocus,
        control,
        reason: 'the user asked for the content and the content is the next '
            'thing in the tree; moving focus would take a keyboard user past '
            'the control they may want to press again',
      );
    });

    testWidgets('closing a section does not move focus either',
        (WidgetTester tester) async {
      final FocusNode control = FocusNode();
      addTearDown(control.dispose);
      await host(
        tester,
        _DisclosureHost(
          initial: const IuxDisclosureState.expanded(),
          controlFocus: control,
        ),
      );

      control.requestFocus();
      await tester.pumpAndSettle();
      await tester.tap(find.text(_summary));
      await tester.pumpAndSettle();

      expect(FocusManager.instance.primaryFocus, control);
    });
  });

  group('a section that may no longer be closed', () {
    testWidgets('is a heading, with no button role and no open state',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(
        tester,
        const _DisclosureHost(initial: IuxDisclosureState.heldOpen()),
      );

      final SemanticsNode node =
          tester.getSemantics(find.bySemanticsLabel(_summary));
      expect(node.label, _summary);
      expect(node.flagsCollection.isHeader, isTrue);
      expect(node.flagsCollection.isButton, isFalse);
      // `none`, not `isTrue`. The platform is told the line has no open state
      // rather than told it is permanently open — which would invite a user to
      // look for a way to close it.
      expect(node.flagsCollection.isExpanded, Tristate.none);
      expect(
        node.getSemanticsData().hasAction(SemanticsAction.tap),
        isFalse,
      );
      handle.dispose();
    });

    testWidgets('shows its content and offers no way to hide it',
        (WidgetTester tester) async {
      final GlobalKey<_DisclosureHostState> key =
          GlobalKey<_DisclosureHostState>();
      await host(
        tester,
        _DisclosureHost(
          key: key,
          initial: const IuxDisclosureState.heldOpen(),
        ),
      );

      expect(find.text(_bodyText), findsOneWidget);
      expect(find.byIcon(Icons.expand_less), findsNothing);
      expect(find.byIcon(Icons.expand_more), findsNothing);

      await tester.tap(find.text(_summary));
      await tester.pumpAndSettle();
      expect(key.currentState!.requested, isEmpty);
      expect(find.text(_bodyText), findsOneWidget);
    });

    testWidgets('a collapsed section flipped to held open reveals its content',
        (WidgetTester tester) async {
      // The flow this state exists for: a submission is refused and the
      // rejected field is inside a section the user had closed.
      final GlobalKey<_DisclosureHostState> key =
          GlobalKey<_DisclosureHostState>();
      await host(tester, _DisclosureHost(key: key));
      expect(find.text(_bodyText), findsNothing);

      key.currentState!.set(const IuxDisclosureState.heldOpen());
      await tester.pumpAndSettle();
      expect(find.text(_bodyText), findsOneWidget);
    });

    testWidgets('the content does not shift when the toggle becomes a heading',
        (WidgetTester tester) async {
      final GlobalKey<_DisclosureHostState> key =
          GlobalKey<_DisclosureHostState>();
      await host(
        tester,
        _DisclosureHost(
          key: key,
          initial: const IuxDisclosureState.expanded(),
        ),
        alignment: Alignment.topCenter,
      );
      final double before = tester.getTopLeft(find.text(_bodyText)).dy;

      key.currentState!.set(const IuxDisclosureState.heldOpen());
      await tester.pumpAndSettle();
      final double after = tester.getTopLeft(find.text(_bodyText)).dy;

      // The row keeps its minimum height and the focus ring keeps its reserved
      // inset, so the only change the user absorbs is the one they were told
      // about.
      expect(after, before);
    });

    testWidgets('the vanishing toggle drops the focus it was holding',
        (WidgetTester tester) async {
      // Measured rather than assumed, and recorded because it is a real cost.
      // The flow this state exists for puts focus on the validation summary
      // (IUX-012) at the moment of the flip, so the toggle is not usually the
      // node holding focus — but when it is, Flutter hands focus back to the
      // enclosing scope and the user's place in the order is lost.
      final FocusNode control = FocusNode();
      addTearDown(control.dispose);
      final GlobalKey<_DisclosureHostState> key =
          GlobalKey<_DisclosureHostState>();
      await host(
        tester,
        _DisclosureHost(
          key: key,
          initial: const IuxDisclosureState.expanded(),
          controlFocus: control,
        ),
      );

      control.requestFocus();
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus, control);

      key.currentState!.set(const IuxDisclosureState.heldOpen());
      await tester.pumpAndSettle();

      expect(control.hasFocus, isFalse);
      expect(FocusManager.instance.primaryFocus, isNot(control));
      // Where it actually lands, pinned rather than described: the nearest
      // enclosing scope, which is where a keyboard user then tabs from. This
      // is the same behaviour IUX-030 measured when a retry control unmounted.
      expect(FocusManager.instance.primaryFocus, isA<FocusScopeNode>());
    });
  });

  group('nothing here animates', () {
    testWidgets('the content is complete on the first frame after the press',
        (WidgetTester tester) async {
      await host(tester, const _DisclosureHost());

      await tester.tap(find.text(_summary));
      // One frame. No pumpAndSettle, which would hide a running animation by
      // waiting for it.
      await tester.pump();

      expect(find.text(_bodyText), findsOneWidget);
      expect(find.text(_innerControl), findsOneWidget);
      expect(
        tester.binding.transientCallbackCount,
        0,
        reason: 'a ticker here would be an in-flow reveal moving everything '
            'below it while it runs, and a control whose hit box travels '
            'while the user reaches for it',
      );
    });

    testWidgets(
        'and it does not animate under a reduced motion preference '
        'either, because there is nothing to reduce',
        (WidgetTester tester) async {
      await host(
        tester,
        const _DisclosureHost(),
        configuration: const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(motion: IuxMotionPreference.none),
        ),
      );

      await tester.tap(find.text(_summary));
      await tester.pump();
      expect(find.text(_bodyText), findsOneWidget);
      expect(tester.binding.transientCallbackCount, 0);
    });
  });

  group('the disclosure survives the conditions a page is actually read in',
      () {
    testWidgets('the control meets the touch target floor',
        (WidgetTester tester) async {
      await host(tester, const _DisclosureHost());
      final Rect control = tester.getRect(
        find
            .ancestor(
              of: find.text(_summary),
              matching: find.byType(ConstrainedBox),
            )
            .first,
      );
      expect(control.height, greaterThanOrEqualTo(IuxTouchTarget.minimum));
    });

    testWidgets('a comfortable target preference raises the floor',
        (WidgetTester tester) async {
      await host(
        tester,
        const _DisclosureHost(),
        configuration: const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(
            touchTarget: IuxTouchTargetPreference.comfortable,
          ),
        ),
      );
      final Rect control = tester.getRect(
        find
            .ancestor(
              of: find.text(_summary),
              matching: find.byType(ConstrainedBox),
            )
            .first,
      );
      expect(control.height, greaterThanOrEqualTo(IuxTouchTarget.comfortable));
    });

    testWidgets('a long summary wraps rather than truncating',
        (WidgetTester tester) async {
      const String long =
          'Where should we leave your parcel if nobody is at home?';
      await host(
        tester,
        const _DisclosureHost(summary: long),
        size: const Size(320, 640),
        textScale: 2,
        alignment: Alignment.topCenter,
      );
      expect(tester.takeException(), isNull);
      expect(find.text(long), findsOneWidget);

      final Text text = tester.widget<Text>(find.text(long));
      // A truncated summary is a summary the user cannot decide on, which is
      // the one thing this control has to let them do.
      expect(text.maxLines, isNull);
      expect(text.overflow, isNot(TextOverflow.ellipsis));
    });

    testWidgets(
        'a revealed section at 200% on a small screen neither clips '
        'nor overflows', (WidgetTester tester) async {
      await host(
        tester,
        const SingleChildScrollView(
          child: _DisclosureHost(initial: IuxDisclosureState.expanded()),
        ),
        size: const Size(320, 640),
        textScale: 2,
        alignment: Alignment.topCenter,
      );
      expect(tester.takeException(), isNull);
      expect(find.text(_bodyText), findsOneWidget);
      expect(find.text(_innerControl), findsOneWidget);
    });

    testWidgets('the chevron grows with the words beside it',
        (WidgetTester tester) async {
      await host(tester, const _DisclosureHost());
      final double standard =
          tester.getSize(find.byIcon(Icons.expand_more)).height;

      await host(tester, const _DisclosureHost(), textScale: 2);
      final double enlarged =
          tester.getSize(find.byIcon(Icons.expand_more)).height;

      expect(enlarged, greaterThan(standard));
    });

    testWidgets(
        'right to left reverses the row without the widget knowing '
        'the language', (WidgetTester tester) async {
      await host(
        tester,
        const _DisclosureHost(),
        direction: TextDirection.rtl,
      );
      final double chevron =
          tester.getCenter(find.byIcon(Icons.expand_more)).dx;
      final double label = tester.getCenter(find.text(_summary)).dx;
      expect(chevron, lessThan(label));
    });

    testWidgets('and it still opens when the page reads right to left',
        (WidgetTester tester) async {
      await host(
        tester,
        const _DisclosureHost(),
        direction: TextDirection.rtl,
      );
      await tester.tap(find.text(_summary));
      await tester.pumpAndSettle();
      expect(find.text(_bodyText), findsOneWidget);
    });
  });

  group('the disclosure is drawn from the theme and nothing else', () {
    for (final IuxThemeConfiguration configuration in _profiles) {
      testWidgets('its summary is readable under $configuration',
          (WidgetTester tester) async {
        await host(
          tester,
          const _DisclosureHost(),
          configuration: configuration,
        );

        // Measured on what is painted rather than on what a resolver returns:
        // the two can drift, and only one of them reaches a user.
        final Text summary = tester.widget<Text>(find.text(_summary));
        final IuxSemanticColors colors = IuxTheme.resolve(configuration).colors;

        expect(
          ContrastMetric.ratio(summary.style!.color!, colors.surface.base),
          greaterThanOrEqualTo(ContrastMetric.normalText),
          reason: 'the summary sits on the page',
        );

        final Icon chevron =
            tester.widget<Icon>(find.byIcon(Icons.expand_more));
        expect(
          ContrastMetric.ratio(chevron.color!, colors.surface.base),
          greaterThanOrEqualTo(ContrastMetric.normalText),
          reason: 'the chevron is part of a control label, not decoration',
        );
      });
    }

    testWidgets(
        'the heading is set in the same type as the control it '
        'replaces', (WidgetTester tester) async {
      await host(
        tester,
        const _DisclosureHost(initial: IuxDisclosureState.expanded()),
      );
      final TextStyle asControl =
          tester.widget<Text>(find.text(_summary)).style!;

      await host(
        tester,
        const _DisclosureHost(initial: IuxDisclosureState.heldOpen()),
      );
      final TextStyle asHeading =
          tester.widget<Text>(find.text(_summary)).style!;

      // The only change between the two states is the affordance. A summary
      // that also changed size would read as a different line.
      expect(asHeading, asControl);
    });
  });
}
