// Read back as text, so that the absence of a timer is pinned by what the
// source says rather than by how long a test is willing to wait.
import 'dart:io';
// Tristate is declared in `dart:ui` and is not re-exported by
// `package:flutter/semantics.dart`, so this is the only way to name it. It is
// what separates "not focused" from "has no focus state at all", and the
// heading has to have one in order to be somewhere the user can land.
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';
// Imported from source rather than from the barrel: IUX-036 does not own
// lib/iux_flutter.dart, so the exports are added by whoever integrates the
// mission. The behaviour asserted here is the same either way.

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

const String _backLabel = 'Back';
const String _forwardLabel = 'See how budgets work';
const String _skipLabel = 'Skip setup';
const String _finishLabel = 'Start using Ledger';
const String _contentText = 'A sample week of spending';

const List<IuxOnboardingStep> _steps = <IuxOnboardingStep>[
  IuxOnboardingStep(
    title: 'Track what you spend',
    body: 'Receipts are read on this device and never uploaded',
  ),
  IuxOnboardingStep(
    title: 'Set a budget',
    body: 'We tell you when you are close to it',
  ),
  IuxOnboardingStep(
    title: 'Share it',
    body: 'Everyone in the household sees the same figures',
  ),
];

/// The caller's sentence, which the framework never composes.
String _position(int step, int stepCount) => '$step of $stepCount';

/// A parent that owns the step index, exactly as a real one does.
///
/// The pattern never advances itself, so every test that expects the flow to
/// move has to be granted the move by this.
class _Host extends StatefulWidget {
  const _Host({
    super.key,
    this.initialStep = 0,
    this.accept = true,
    this.content,
  });

  final int initialStep;

  /// Whether the parent acts on the step the user asked for.
  final bool accept;

  /// Extra content for the step on screen, used by one test.
  final Widget? content;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late int step = widget.initialStep;

  /// Every step the flow has asked the parent for.
  final List<int> requested = <int>[];

  int skipped = 0;
  int finished = 0;

  /// Forces a rebuild that is not a step change.
  void bump() => setState(() {});

  /// Moves the flow without anybody having pressed anything inside it.
  ///
  /// The parent owns the index, so it may set it for a reason of its own — a
  /// deep link, a restored session, a control the application drew beside the
  /// flow. The pattern sees the same thing either way, which is what the test
  /// using this measures.
  void jump(int to) => setState(() => step = to);

  @override
  Widget build(BuildContext context) {
    final List<IuxOnboardingStep> steps = widget.content == null
        ? _steps
        : <IuxOnboardingStep>[
            for (final IuxOnboardingStep each in _steps)
              IuxOnboardingStep(
                title: each.title,
                body: each.body,
                content: widget.content,
              ),
          ];

    return IuxOnboardingFlow(
      steps: steps,
      currentStep: step,
      onStepChanged: (int next) {
        requested.add(next);
        if (widget.accept) setState(() => step = next);
      },
      describePosition: _position,
      backLabel: _backLabel,
      forwardLabel: _forwardLabel,
      skip: IuxNamedAction(
        label: _skipLabel,
        onActivate: () => skipped++,
      ),
      finish: IuxNamedAction(
        label: _finishLabel,
        onActivate: () => finished++,
      ),
    );
  }
}

/// The usual answer to "where is the position?", drawn the usual way.
///
/// Built here rather than in `lib/` because it is evidence for a decision not
/// to ship it: a row of decorated boxes carries position through shape and
/// place alone, and contributes nothing to the semantics tree. See the test
/// that probes it.
class _DotRow extends StatelessWidget {
  const _DotRow({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < count; i++)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == current
                    ? const Color(0xFF000000)
                    : const Color(0x33000000),
              ),
            ),
        ],
      );
}

void main() {
  Future<_HostState> host(
    WidgetTester tester,
    Widget child, {
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
          key: ValueKey<IuxThemeConfiguration>(configuration),
          theme: IuxTheme.fromConfiguration(configuration),
          home: Directionality(
            textDirection: direction,
            child: Scaffold(
              // The pattern does not scroll, and says so. A real caller places
              // it inside something that does, so the harness does too —
              // otherwise every large-text test measures an overflow rather
              // than the layout.
              body: SingleChildScrollView(child: child),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return tester.state<_HostState>(find.byType(_Host));
  }

  Future<void> tap(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  /// The step heading's node, found by what it announces.
  SemanticsNode headingNode(WidgetTester tester, String spoken) =>
      tester.getSemantics(find.bySemanticsLabel(spoken));

  group('a step is content, and refuses to be less', () {
    test('a step with no name is refused', () {
      // The name is where focus lands on every step change; unnamed, the flow
      // moves and says nothing.
      expect(
        () => IuxOnboardingStep(title: '', body: 'Something'),
        throwsAssertionError,
      );
    });

    test('a step with nothing to say is refused', () {
      // A title over a picture is a screen the user sits through for one noun.
      expect(
        () => IuxOnboardingStep(title: 'Something', body: ''),
        throwsAssertionError,
      );
    });

    test('two steps with the same words are the same value', () {
      const IuxOnboardingStep a =
          IuxOnboardingStep(title: 'Set a budget', body: 'We tell you');
      const IuxOnboardingStep b =
          IuxOnboardingStep(title: 'Set a budget', body: 'We tell you');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(<IuxOnboardingStep>[a, b].toSet(), hasLength(1));
    });

    test('a different body is a different step', () {
      const IuxOnboardingStep a =
          IuxOnboardingStep(title: 'Set a budget', body: 'We tell you');
      const IuxOnboardingStep b =
          IuxOnboardingStep(title: 'Set a budget', body: 'We will not');
      expect(a, isNot(b));
    });

    test('a step says what it is, for a debugger and a failure message', () {
      expect(
          _steps.first.toString(), 'IuxOnboardingStep(Track what you spend)');
    });

    test('content is null by default rather than an empty box', () {
      expect(_steps.first.content, isNull);
    });
  });

  group('the shapes a flow refuses to be built in', () {
    IuxOnboardingFlow build({
      List<IuxOnboardingStep> steps = _steps,
      int currentStep = 0,
      String backLabel = _backLabel,
      String forwardLabel = _forwardLabel,
    }) =>
        IuxOnboardingFlow(
          steps: steps,
          currentStep: currentStep,
          onStepChanged: (int _) {},
          describePosition: _position,
          backLabel: backLabel,
          forwardLabel: forwardLabel,
          skip: IuxNamedAction(label: _skipLabel, onActivate: () {}),
          finish: IuxNamedAction(label: _finishLabel, onActivate: () {}),
        );

    test('one step is not a flow', () {
      // The assertion exists to name the better answer: a screen, built out of
      // a heading, a sentence and two buttons.
      expect(
        () => build(steps: <IuxOnboardingStep>[_steps.first]),
        throwsAssertionError,
      );
      expect(() => build(steps: const <IuxOnboardingStep>[]),
          throwsAssertionError);
    });

    test('a step outside the list is refused', () {
      expect(() => build(currentStep: 3), throwsAssertionError);
      expect(() => build(currentStep: -1), throwsAssertionError);
    });

    test('the two navigation controls must be named', () {
      expect(() => build(backLabel: ''), throwsAssertionError);
      expect(() => build(forwardLabel: ''), throwsAssertionError);
    });

    test('there is no way to build a flow without a way out', () {
      // The type-level half of the loop-breaker: `skip` and `finish` are
      // required, so an onboarding with no exit does not compile. This test is
      // the enumeration of what the constructor accepts — the same way
      // IuxDisclosureState proves the state it refuses does not exist.
      expect(build().skip.label, _skipLabel);
      expect(build().finish.label, _finishLabel);
    });
  });

  group('the parent owns the step', () {
    testWidgets('the forward control asks rather than moves',
        (WidgetTester tester) async {
      final _HostState state = await host(tester, const _Host(accept: false));

      await tap(tester, _forwardLabel);

      expect(state.requested, <int>[1]);
      // The parent declined by not moving, so nothing moved.
      expect(state.step, 0);
      expect(find.text('1 of 3'), findsOneWidget);
    });

    testWidgets('a granted request moves the flow',
        (WidgetTester tester) async {
      final _HostState state = await host(tester, const _Host());

      await tap(tester, _forwardLabel);

      expect(state.step, 1);
      expect(find.text('2 of 3'), findsOneWidget);
      expect(find.text('Set a budget'), findsOneWidget);
    });

    testWidgets('the way back is absent on the first step',
        (WidgetTester tester) async {
      await host(tester, const _Host());
      expect(find.text(_backLabel), findsNothing);

      await tap(tester, _forwardLabel);
      expect(find.text(_backLabel), findsOneWidget);

      await tap(tester, _backLabel);
      expect(find.text('1 of 3'), findsOneWidget);
      expect(find.text(_backLabel), findsNothing);
    });

    testWidgets('the last step ends the flow instead of continuing it',
        (WidgetTester tester) async {
      final _HostState state = await host(tester, const _Host(initialStep: 2));

      expect(find.text(_forwardLabel), findsNothing);
      expect(find.text(_finishLabel), findsOneWidget);

      await tap(tester, _finishLabel);
      expect(state.finished, 1);
      // Finishing leaves the flow. It does not move within it.
      expect(state.requested, isEmpty);
      expect(state.step, 2);
    });
  });

  group('the way out is required, on every step', () {
    testWidgets('the exit is on every step, including the last',
        (WidgetTester tester) async {
      for (int step = 0; step < _steps.length; step++) {
        // Keyed, so each iteration builds a fresh parent. Without it the state
        // is reused and `initialStep` — read once, into a `late` field — never
        // takes effect again, which is a test that walks one step three times.
        await host(tester, _Host(key: ValueKey<int>(step), initialStep: step));
        expect(
          find.text('${step + 1} of 3'),
          findsOneWidget,
          reason: 'the harness did not reach step ${step + 1}',
        );
        expect(
          find.text(_skipLabel),
          findsOneWidget,
          reason: 'the exit vanished on step ${step + 1}, which is the one '
              'control that must never need discovering',
        );
      }
    });

    testWidgets('the exit reports the refusal to the parent',
        (WidgetTester tester) async {
      final _HostState state = await host(tester, const _Host(initialStep: 1));

      await tap(tester, _skipLabel);

      expect(state.skipped, 1);
      // Leaving is not navigating. The parent is told the user left, and the
      // flow does not move underneath them.
      expect(state.requested, isEmpty);
      expect(state.step, 1);
    });

    testWidgets('the exit is a peer of the control beside it, not a grey link',
        (WidgetTester tester) async {
      await host(tester, const _Host(initialStep: 2));

      // The same widget, so the same target floor, the same focus ring and the
      // same place in the focus order. There is no parameter that could make
      // one of these a bare word under a filled rectangle.
      final Finder skip = find.widgetWithText(IuxButton, _skipLabel);
      final Finder finish = find.widgetWithText(IuxButton, _finishLabel);
      expect(skip, findsOneWidget);
      expect(finish, findsOneWidget);
      expect(
        tester.getSize(skip).height,
        tester.getSize(finish).height,
        reason: 'the exit and the control that ends the flow are drawn at '
            'different heights, which is the asymmetry this pattern refuses',
      );
      expect(tester.getSize(skip).height, greaterThanOrEqualTo(48));
    });

    testWidgets('the exit is announced as a control that dismisses',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(tester, const _Host());

      final SemanticsNode node =
          tester.getSemantics(find.bySemanticsLabel(_skipLabel));
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      handle.dispose();
    });

    testWidgets('the exit comes before the control that ends the flow',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(tester, const _Host(initialStep: 2));

      // Measured on the order a screen reader actually walks, not on x
      // coordinates: the controls wrap, so a coordinate test would be
      // measuring the line break rather than the reading order.
      final List<String> spoken = tester.semantics
          .simulatedAccessibilityTraversal()
          .map((SemanticsNode node) => node.label)
          .where((String label) => label.isNotEmpty)
          .toList();

      // The heading first — it is where focus lands — then the way out of a
      // mistake, then the refusal, then the control an accidental activation
      // must never reach.
      expect(spoken.first, startsWith('3 of 3'));
      expect(spoken.indexOf(_backLabel), lessThan(spoken.indexOf(_skipLabel)));
      expect(
        spoken.indexOf(_skipLabel),
        lessThan(spoken.indexOf(_finishLabel)),
      );
      handle.dispose();
    });
  });

  group('nothing moves on its own', () {
    testWidgets('no amount of waiting advances the flow',
        (WidgetTester tester) async {
      final _HostState state = await host(tester, const _Host());

      await tester.pump(const Duration(minutes: 5));
      await tester.pump(const Duration(minutes: 5));
      await tester.pumpAndSettle();

      expect(state.requested, isEmpty);
      expect(state.step, 0);
      expect(find.text('1 of 3'), findsOneWidget);
    });

    test('the pattern holds no timer, no ticker and no pager', () {
      // A pin rather than a belt: SC 2.2.1 is satisfied here by there being no
      // time limit to extend, and the day somebody adds one this fails in a
      // diff rather than in the field. `PageView` is on the list because a
      // horizontal drag has no name, no focus stop and no D-pad equivalent —
      // and on Android it is TalkBack's own gesture.
      const List<String> forbidden = <String>[
        'Timer(',
        'Timer.periodic',
        'Future.delayed',
        'PageView',
        'AnimationController',
        'createTicker',
        'SingleTickerProvider',
      ];

      final List<File> sources = Directory('lib/src/patterns/onboarding')
          .listSync()
          .whereType<File>()
          .where((File file) => file.path.endsWith('.dart'))
          .toList();
      expect(sources, isNotEmpty);

      final List<String> offences = <String>[];
      for (final File file in sources) {
        // Documentation explains why these are absent, so prose must not be
        // mistaken for the thing it forbids.
        final String code = file
            .readAsLinesSync()
            .where((String line) => !line.trimLeft().startsWith('//'))
            .join('\n');
        for (final String each in forbidden) {
          if (code.contains(each)) offences.add('${file.path}: $each');
        }
      }
      expect(offences, isEmpty);
    });
  });

  group('where focus goes when the step changes', () {
    testWidgets('focus moves to the heading of the step that arrived',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(tester, const _Host());

      await tap(tester, _forwardLabel);

      final SemanticsNode node = headingNode(
        tester,
        '2 of 3. Set a budget. We tell you when you are close to it',
      );
      expect(node.flagsCollection.isFocused, Tristate.isTrue);
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'IuxOnboardingFlow step',
      );
      handle.dispose();
    });

    testWidgets('going back announces the step it went back to',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(tester, const _Host(initialStep: 2));

      await tap(tester, _backLabel);

      final SemanticsNode node = headingNode(
        tester,
        '2 of 3. Set a budget. We tell you when you are close to it',
      );
      expect(node.flagsCollection.isFocused, Tristate.isTrue);
      handle.dispose();
    });

    testWidgets('arriving at the flow does not take focus',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(tester, const _Host());

      // The application decided to show this; the user asked for nothing. That
      // is the IUX-028 case, and taking focus would interrupt whatever the
      // platform was already saying about the screen that just opened.
      final SemanticsNode node = headingNode(
        tester,
        '1 of 3. Track what you spend. '
        'Receipts are read on this device and never uploaded',
      );
      expect(node.flagsCollection.isFocused, Tristate.isFalse);
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        isNot('IuxOnboardingFlow step'),
      );
      handle.dispose();
    });

    testWidgets('a rebuild that is not a step change does not move focus',
        (WidgetTester tester) async {
      final _HostState state = await host(tester, const _Host(initialStep: 1));

      final FocusNode skip = Focus.of(
        tester.element(find.text(_skipLabel)),
        scopeOk: true,
      );
      skip.requestFocus();
      await tester.pumpAndSettle();
      expect(skip.hasPrimaryFocus, isTrue);

      state.bump();
      await tester.pumpAndSettle();

      expect(skip.hasPrimaryFocus, isTrue);
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        isNot('IuxOnboardingFlow step'),
      );
    });

    testWidgets('a request the parent declines moves no focus',
        (WidgetTester tester) async {
      await host(tester, const _Host(accept: false));

      await tap(tester, _forwardLabel);

      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        isNot('IuxOnboardingFlow step'),
      );
    });

    testWidgets('a step the parent moved on its own moves focus too',
        (WidgetTester tester) async {
      // Measured rather than assumed, and it corrects a sentence that used to
      // read "nothing else can cause a step change". Something else can: the
      // parent owns the index, so a deep link, a restored session or a control
      // the application drew beside the flow can set it while the user was
      // reading — or, as here, while their focus was on the way out.
      //
      // The move is kept anyway. The alternative is to move focus only after
      // the flow's own request, which means arming a pending move and firing
      // it on whatever change arrives next — IUX-039's finding against the two
      // forms — and the failure it trades into is worse: a step that changes
      // in silence is a screen-reader user reading the previous step's
      // controls under a new step's heading.
      final _HostState state = await host(tester, const _Host(initialStep: 1));

      final FocusNode skip = Focus.of(
        tester.element(find.text(_skipLabel)),
        scopeOk: true,
      );
      skip.requestFocus();
      await tester.pumpAndSettle();
      expect(skip.hasPrimaryFocus, isTrue);

      state.jump(2);
      await tester.pumpAndSettle();

      expect(state.requested, isEmpty,
          reason: 'nothing inside the flow was pressed, so the flow asked for '
              'nothing — this change came from the parent alone');
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'IuxOnboardingFlow step',
        reason: 'the pattern cannot tell a press inside it from a parent that '
            'moved the index, and this pins which of the two behaviours it '
            'has so that changing it is a decision rather than a slip',
      );
    });
  });

  group('the heading announces the whole arrival', () {
    testWidgets('position, title and body are one node',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(tester, const _Host(initialStep: 1));

      final SemanticsNode node = headingNode(
        tester,
        '2 of 3. Set a budget. We tell you when you are close to it',
      );
      // One stop, not three: the position alone is the only fragment focus
      // would otherwise have landed on.
      expect(node.flagsCollection.isHeader, isTrue);
      // Somewhere the user can land, rather than a line of text.
      expect(node.flagsCollection.isFocused, isNot(Tristate.none));
      handle.dispose();
    });

    testWidgets('the heading is not a live region',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(tester, const _Host(initialStep: 1));

      // Focus arriving here is already the announcement. A live region would
      // put a second utterance in the same frame.
      final SemanticsNode node = headingNode(
        tester,
        '2 of 3. Set a budget. We tell you when you are close to it',
      );
      expect(node.flagsCollection.isLiveRegion, isFalse);
      handle.dispose();
    });

    testWidgets('the position is on screen as text, for everybody else',
        (WidgetTester tester) async {
      await host(tester, const _Host(initialStep: 1));
      expect(find.text('2 of 3'), findsOneWidget);
    });

    testWidgets('a dot row announces nothing, which is why there is none',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Align(child: _DotRow(count: 4, current: 1)),
        ),
      );

      // Measured rather than assumed. The usual position indicator is four
      // decorated boxes: it carries position through shape and place alone
      // (SC 1.4.1) and contributes no semantic node at all, so a screen-reader
      // user is told nothing. §19 says ship no indicator rather than a
      // decorative one, and this is the evidence for doing so.
      // The row produced no node of its own, so this is the nearest ancestor
      // that has one — and it has nothing to say and nothing beneath it.
      final SemanticsNode node = tester.getSemantics(find.byType(_DotRow));
      expect(node.label, isEmpty);
      expect(node.childrenCount, 0);
      handle.dispose();
    });
  });

  group('what a step may show beyond its two sentences', () {
    testWidgets('content is a stop of its own, not part of the announcement',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(tester, const _Host(content: Text(_contentText)));

      expect(find.text(_contentText), findsOneWidget);

      // Two nodes, not one. Merged into the heading, the content would be read
      // out again on every arrival at this step — including on the way back —
      // and a control inside it would have no stop of its own to be activated
      // from.
      final SemanticsNode heading = headingNode(
        tester,
        '1 of 3. Track what you spend. '
        'Receipts are read on this device and never uploaded',
      );
      final SemanticsNode content =
          tester.getSemantics(find.bySemanticsLabel(_contentText));
      expect(content.id, isNot(heading.id));
      expect(heading.label, isNot(contains(_contentText)));
      handle.dispose();
    });

    testWidgets('content sits between the heading and the flow controls',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(tester, const _Host(content: Text(_contentText)));

      // The order the class documentation promises, measured on the order a
      // screen reader actually walks: the announcement, then what the step is
      // showing, then the controls that leave it. Content placed after the
      // controls would be a picture a screen-reader user reaches by walking
      // back past the button that ends the flow.
      final List<String> spoken = tester.semantics
          .simulatedAccessibilityTraversal()
          .map((SemanticsNode node) => node.label)
          .where((String label) => label.isNotEmpty)
          .toList();

      final int heading =
          spoken.indexWhere((String label) => label.startsWith('1 of 3'));
      expect(heading, isNonNegative);
      expect(spoken.indexOf(_contentText), heading + 1);
      expect(
        spoken.indexOf(_contentText),
        lessThan(spoken.indexOf(_skipLabel)),
      );
      handle.dispose();
    });

    testWidgets(
        'a permission request in a step puts two ways on and two refusals '
        'on one screen', (WidgetTester tester) async {
      // The anti-pattern, built rather than described, because the cost of it
      // is a number nobody counts by eye. IUX-031's guarantees do travel with
      // the rationale — it still requires a reason, and its decline is still
      // drawn as a peer of the ask — so the arrangement the type refuses stays
      // refused. What is not repaired is the arithmetic, and this measures it.
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(
        tester,
        _Host(
          initialStep: 1,
          content: IuxPermissionRationale(
            moment: IuxBeforeAsking(
              ask: IuxNamedAction(label: 'Allow the camera', onActivate: () {}),
              decline: IuxNamedAction(label: 'Not now', onActivate: () {}),
            ),
            title: 'Photograph a receipt',
            reason: 'The camera is used only to attach a receipt to an '
                'invoice.',
          ),
        ),
        size: const Size(400, 1400),
      );

      expect(
        find.byType(IuxButton),
        findsNWidgets(5),
        reason: 'the rationale brings two controls of its own to a step that '
            'already had three',
      );

      final List<String> spoken = tester.semantics
          .simulatedAccessibilityTraversal()
          .map((SemanticsNode node) => node.label)
          .where((String label) => label.isNotEmpty)
          .toList();

      // Two controls go forward — one into the OS prompt, one into the next
      // screen — and two refuse, one of them the flow's own exit. The user has
      // to work out which of the four leaves what, and no assertion can see
      // that. It is the concrete reason to ask at the feature instead.
      for (final String label in <String>[
        'Not now',
        'Allow the camera',
        _backLabel,
        _skipLabel,
        _forwardLabel,
      ]) {
        expect(spoken, contains(label), reason: label);
      }
      expect(
        spoken.indexOf('Allow the camera'),
        lessThan(spoken.indexOf(_forwardLabel)),
        reason: 'the rationale sits in the content, above the flow\'s own '
            'controls, so its pair is met first',
      );
      expect(spoken.indexOf('Not now'), lessThan(spoken.indexOf(_skipLabel)));
      handle.dispose();
    });

    testWidgets('a step without content draws nothing in its place',
        (WidgetTester tester) async {
      await host(tester, const _Host());
      // The heading and the controls, and no reserved blank between them.
      final double headingBottom =
          tester.getBottomLeft(find.text('Track what you spend')).dy;
      final double controlTop = tester.getTopLeft(find.text(_skipLabel)).dy;
      expect(controlTop, greaterThan(headingBottom));
    });
  });

  group('the conditions the pattern is held to', () {
    for (final IuxThemeConfiguration configuration in _profiles) {
      testWidgets('renders under $configuration', (WidgetTester tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        await host(
          tester,
          const _Host(initialStep: 1),
          configuration: configuration,
        );

        expect(find.text('2 of 3'), findsOneWidget);
        expect(find.text(_skipLabel), findsOneWidget);
        expect(find.text(_forwardLabel), findsOneWidget);
        expect(
          headingNode(
            tester,
            '2 of 3. Set a budget. We tell you when you are close to it',
          ).flagsCollection.isHeader,
          isTrue,
        );
        expect(tester.takeException(), isNull);
        handle.dispose();
      });
    }

    testWidgets('every control stays on screen at 200% text',
        (WidgetTester tester) async {
      await host(
        tester,
        const _Host(initialStep: 2),
        textScale: 2,
        size: const Size(320, 800),
      );

      expect(tester.takeException(), isNull);
      // Wrapped rather than overflowed: every control is still whole and still
      // within the width of the screen, including the one that leaves.
      final Set<double> rows = <double>{};
      for (final String label in <String>[
        _backLabel,
        _skipLabel,
        _finishLabel,
      ]) {
        final Rect rect = tester.getRect(find.text(label));
        expect(rect.left, greaterThanOrEqualTo(0), reason: label);
        expect(rect.right, lessThanOrEqualTo(320), reason: label);
        rows.add(rect.top);
      }
      // They did not all fit on one line, which is the point of wrapping.
      expect(rows.length, greaterThan(1));
    });

    testWidgets('every control survives 300% text on a 320dp window',
        (WidgetTester tester) async {
      // The catalog's worst case, and the narrowest Android width still
      // shipped in volume. 200% is the WCAG floor; this is the combination an
      // application actually meets on somebody's phone.
      await host(
        tester,
        const _Host(initialStep: 2),
        textScale: 3,
        size: const Size(320, 900),
      );

      expect(tester.takeException(), isNull);

      final Set<double> rows = <double>{};
      for (final String label in <String>[
        _backLabel,
        _skipLabel,
        _finishLabel,
      ]) {
        final Rect rect = tester.getRect(find.text(label));
        expect(rect.left, greaterThanOrEqualTo(0), reason: label);
        expect(rect.right, lessThanOrEqualTo(320), reason: label);
        rows.add(rect.top);
      }
      expect(rows.length, 3,
          reason: 'at 300% in 320dp the three controls each take a row of '
              'their own, which is the outcome in which all three stay whole');

      // The exit keeps the floor at the scale where a layout is likeliest to
      // buy space back from it.
      expect(
        tester.getSize(find.widgetWithText(IuxButton, _skipLabel)).height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('the exit is still a peer at 200%, though not the same height',
        (WidgetTester tester) async {
      // The equal-height measurement in the documentation holds at the default
      // text scale and is not a property of the pattern: two labels of
      // different lengths wrap onto different numbers of lines. Measured here
      // at 200% on 320dp, the exit is 106dp against the finishing control's
      // 144 — and it does not matter, because the asymmetry this pattern
      // refuses is drawing weight, not pixels. Both are full buttons, both
      // keep the floor, and neither can be reduced to a bare word.
      await host(
        tester,
        const _Host(initialStep: 2),
        textScale: 2,
        size: const Size(320, 900),
      );

      for (final String label in <String>[_skipLabel, _finishLabel]) {
        final Finder button = find.widgetWithText(IuxButton, label);
        expect(button, findsOneWidget, reason: label);
        expect(
          tester.getSize(button).height,
          greaterThanOrEqualTo(48),
          reason: '$label fell under the target floor at 200%',
        );
      }
    });

    testWidgets('the long body wraps rather than being cut',
        (WidgetTester tester) async {
      await host(tester, const _Host(), textScale: 2);
      final RenderParagraph body = tester.renderObject<RenderParagraph>(
        find.text('Receipts are read on this device and never uploaded'),
      );
      expect(body.maxLines, isNull);
      expect(body.overflow, TextOverflow.clip);
      expect(body.softWrap, isTrue);
    });

    testWidgets('reading order reverses under RTL',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(
        tester,
        const _Host(initialStep: 2),
        direction: TextDirection.rtl,
      );

      // Same order, mirrored: the way back is still the first control reached,
      // which under RTL puts it to the right of the exit beside it.
      expect(
        tester.getTopLeft(find.text(_backLabel)).dx,
        greaterThan(tester.getTopLeft(find.text(_skipLabel)).dx),
      );
      expect(
        headingNode(
          tester,
          '3 of 3. Share it. Everyone in the household sees the same figures',
        ).flagsCollection.isHeader,
        isTrue,
      );
      handle.dispose();
    });

    testWidgets('the pattern introduces no scrolling of its own',
        (WidgetTester tester) async {
      await host(tester, const _Host(content: Text(_contentText)));

      // "Nothing here scrolls" is a documented limitation, and this is what
      // holds it to being one. The harness supplies exactly one scrollable,
      // as a real caller does; a second one inside the pattern would be a
      // nested scroll region — two places a drag can land, and a
      // screen-reader user who cannot tell which of two containers their
      // swipe just moved.
      expect(find.byType(Scrollable), findsOneWidget);
    });

    testWidgets('nothing animates, so a step change is immediate',
        (WidgetTester tester) async {
      final _HostState state = await host(tester, const _Host());

      await tester.tap(find.text(_forwardLabel));
      // One frame, no settling: the announcement is not delayed to play a
      // transition, which is why there is nothing for a reduced-motion
      // preference to remove.
      await tester.pump();

      expect(state.step, 1);
      expect(find.text('2 of 3'), findsOneWidget);
      expect(find.text('Track what you spend'), findsNothing);
    });
  });
}
