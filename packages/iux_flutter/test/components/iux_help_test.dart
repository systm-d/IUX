// Tristate is declared in `dart:ui` and is not re-exported by
// `package:flutter/semantics.dart`, so this is the only way to name it. It is
// what distinguishes "not expanded" from "has no open state at all".
import 'dart:ui' show Tristate;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';
// Imported from source rather than from the barrel: IUX-018 does not own
// lib/iux_flutter.dart, so the exports are added by whoever integrates the
// mission. The behaviour asserted here is the same either way.

import '../support/contrast.dart';

/// The four conditions every IUX component is held to.
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

const String _message = 'Archive this conversation';

const String _helpLabel = 'What is a sort code?';
const String _helpText =
    'A sort code identifies the bank and the branch that hold the account. It '
    'is six digits long and is printed on your card and on your statements.';

/// The control a tooltip is normally attached to: an icon with no room for a
/// label, whose accessible name comes from the action model.
Widget _iconAction({FocusNode? focusNode, VoidCallback? onActivate}) =>
    IuxIconButton(
      icon: Icons.archive_outlined,
      action: const IuxActionDescriptor(
        semantics: IuxActionSemantics(label: 'Archive'),
      ),
      focusNode: focusNode,
      onActivate: onActivate ?? () {},
    );

/// A parent that owns whether the help panel is open, exactly as a real one
/// does. The component never opens itself.
class _HelpHost extends StatefulWidget {
  const _HelpHost({
    super.key,
    this.initiallyExpanded = false,
    this.accept = true,
    this.focusNode,
    this.label = _helpLabel,
  });

  final bool initiallyExpanded;

  /// Whether the parent acts on what the user asked for.
  final bool accept;
  final FocusNode? focusNode;
  final String label;

  @override
  State<_HelpHost> createState() => _HelpHostState();
}

class _HelpHostState extends State<_HelpHost> {
  late bool expanded = widget.initiallyExpanded;

  /// Every value the component has asked the parent for.
  final List<bool> requested = <bool>[];

  @override
  Widget build(BuildContext context) => IuxContextualHelp(
        label: widget.label,
        help: _helpText,
        expanded: expanded,
        focusNode: widget.focusNode,
        onExpandedChanged: (bool value) {
          requested.add(value);
          if (widget.accept) setState(() => expanded = value);
        },
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
          // Keyed by configuration so a test that switches profiles gets the
          // new theme outright, rather than a frame of the cross-fade between
          // two themes, whose colours belong to neither.
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

  /// Resolves what a widget would paint under [configuration], without
  /// rendering one.
  Future<T> resolve<T>(
    WidgetTester tester,
    IuxThemeConfiguration configuration,
    T Function(BuildContext context) resolver, {
    double textScale = 1,
  }) async {
    late T resolved;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: MaterialApp(
          key: ValueKey<IuxThemeConfiguration>(configuration),
          theme: IuxTheme.fromConfiguration(configuration),
          home: Builder(
            builder: (BuildContext context) {
              resolved = resolver(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return resolved;
  }

  /// Moves a mouse onto [finder] and leaves it there until the test ends.
  Future<TestGesture> hover(WidgetTester tester, Finder finder) async {
    final TestGesture gesture =
        await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.moveTo(tester.getCenter(finder));
    await tester.pumpAndSettle();
    return gesture;
  }

  Finder tooltipText() => find.text(_message);

  group('a tooltip is reachable without a mouse', () {
    testWidgets('it says nothing until it is asked for',
        (WidgetTester tester) async {
      await host(
        tester,
        IuxTooltip(message: _message, child: _iconAction()),
      );
      expect(tooltipText(), findsNothing);
    });

    testWidgets('a long press opens it, which is the touch route',
        (WidgetTester tester) async {
      // Hover does not exist on a phone, and Android is this framework's
      // primary platform. If this is the only test that matters on this page,
      // it is this one.
      await host(
        tester,
        IuxTooltip(message: _message, child: _iconAction()),
      );
      await tester.longPress(find.byIcon(Icons.archive_outlined));
      await tester.pumpAndSettle();
      expect(tooltipText(), findsOneWidget);
    });

    testWidgets('a quick tap activates the control and opens nothing',
        (WidgetTester tester) async {
      // The tooltip's long-press recogniser shares the arena with the button's
      // own tap. Losing that competition either way would be a defect: a
      // tooltip on every tap, or a control that stopped responding.
      int activations = 0;
      await host(
        tester,
        IuxTooltip(
          message: _message,
          child: _iconAction(onActivate: () => activations++),
        ),
      );
      await tester.tap(find.byIcon(Icons.archive_outlined));
      await tester.pumpAndSettle();
      expect(activations, 1);
      expect(tooltipText(), findsNothing);
    });

    testWidgets(
        'moving focus onto the control opens it, which is the '
        'keyboard route', (WidgetTester tester) async {
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await host(
        tester,
        IuxTooltip(message: _message, child: _iconAction(focusNode: node)),
      );
      node.requestFocus();
      await tester.pumpAndSettle();
      expect(tooltipText(), findsOneWidget);
    });

    testWidgets('hovering opens it, for the users who have a pointer',
        (WidgetTester tester) async {
      await host(
        tester,
        IuxTooltip(message: _message, child: _iconAction()),
      );
      await hover(tester, find.byIcon(Icons.archive_outlined));
      expect(tooltipText(), findsOneWidget);
    });

    testWidgets('it never takes focus away from the control',
        (WidgetTester tester) async {
      // Focus on something that appears without being asked for, and cannot be
      // navigated back from, strands the user it moved.
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await host(
        tester,
        IuxTooltip(message: _message, child: _iconAction(focusNode: node)),
      );
      node.requestFocus();
      await tester.pumpAndSettle();
      expect(tooltipText(), findsOneWidget);
      expect(FocusManager.instance.primaryFocus, node);
    });
  });

  group('WCAG 2.2 SC 1.4.13: dismissable, hoverable, persistent', () {
    testWidgets('persistent: it has no clock and never leaves on its own',
        (WidgetTester tester) async {
      await host(
        tester,
        IuxTooltip(message: _message, child: _iconAction()),
      );
      await tester.longPress(find.byIcon(Icons.archive_outlined));
      await tester.pumpAndSettle();
      expect(tooltipText(), findsOneWidget);

      // Five minutes is not a realistic reading time; it is a demonstration
      // that no duration exists. A tooltip that vanishes while it is being
      // read fails this criterion, and the only way to be sure it cannot is to
      // have nothing that counts.
      await tester.pump(const Duration(minutes: 5));
      expect(tooltipText(), findsOneWidget);
    });

    testWidgets(
        'dismissable: Escape closes it without focus or the pointer '
        'moving', (WidgetTester tester) async {
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await host(
        tester,
        IuxTooltip(message: _message, child: _iconAction(focusNode: node)),
      );
      node.requestFocus();
      await tester.pumpAndSettle();
      expect(tooltipText(), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(tooltipText(), findsNothing);
      // The criterion's wording: dismissed *without moving pointer hover or
      // focus*. Focus staying put is half of what it asks for.
      expect(FocusManager.instance.primaryFocus, node);
    });

    testWidgets('dismissable: a press anywhere else closes it',
        (WidgetTester tester) async {
      await host(
        tester,
        IuxTooltip(message: _message, child: _iconAction()),
      );
      await tester.longPress(find.byIcon(Icons.archive_outlined));
      await tester.pumpAndSettle();
      expect(tooltipText(), findsOneWidget);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(tooltipText(), findsNothing);
    });

    testWidgets('dismissable: pressing the control again closes it',
        (WidgetTester tester) async {
      // The way out a touch user finds first, because it is where their finger
      // already is.
      await host(
        tester,
        IuxTooltip(message: _message, child: _iconAction()),
      );
      await tester.longPress(find.byIcon(Icons.archive_outlined));
      await tester.pumpAndSettle();
      expect(tooltipText(), findsOneWidget);

      await tester.tap(find.byIcon(Icons.archive_outlined));
      await tester.pumpAndSettle();
      expect(tooltipText(), findsNothing);
    });

    testWidgets('dismissable: touching the tooltip itself closes it',
        (WidgetTester tester) async {
      await host(
        tester,
        IuxTooltip(message: _message, child: _iconAction()),
      );
      await tester.longPress(find.byIcon(Icons.archive_outlined));
      await tester.pumpAndSettle();

      await tester.tap(tooltipText());
      await tester.pumpAndSettle();
      expect(tooltipText(), findsNothing);
    });

    testWidgets('hoverable: the pointer can travel onto it and read it',
        (WidgetTester tester) async {
      // The failure this replaces: the tooltip sits a few pixels away from its
      // anchor, the pointer crosses the gap, the anchor reports an exit, and
      // the tooltip closes on the way to being read.
      await host(
        tester,
        IuxTooltip(message: _message, child: _iconAction()),
      );
      final TestGesture gesture =
          await hover(tester, find.byIcon(Icons.archive_outlined));
      expect(tooltipText(), findsOneWidget);

      await gesture.moveTo(tester.getCenter(tooltipText()));
      await tester.pumpAndSettle();
      expect(tooltipText(), findsOneWidget);
    });

    testWidgets('leaving both the control and the tooltip closes it',
        (WidgetTester tester) async {
      await host(
        tester,
        IuxTooltip(message: _message, child: _iconAction()),
      );
      final TestGesture gesture =
          await hover(tester, find.byIcon(Icons.archive_outlined));
      expect(tooltipText(), findsOneWidget);

      await gesture.moveTo(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(tooltipText(), findsNothing);
    });
  });

  group('a tooltip is never the only place the information exists', () {
    testWidgets(
        'the control keeps its own name, and the message joins it on '
        'the same node', (WidgetTester tester) async {
      // Two nodes would mean a screen reader lands on the named one and never
      // meets the message — which is the usual way a tooltip ends up carrying
      // information nobody receives.
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(
        tester,
        IuxTooltip(message: _message, child: _iconAction()),
      );

      // The merged data rather than the node's own: merging is the point, and
      // what a screen reader receives is the merged result.
      final SemanticsData data = tester
          .getSemantics(find.bySemanticsLabel('Archive'))
          .getSemanticsData();
      expect(data.label, 'Archive');
      expect(data.tooltip, _message);
      expect(data.flagsCollection.isButton, isTrue);
      handle.dispose();
    });

    testWidgets('the screen reader is offered the gesture that reveals it',
        (WidgetTester tester) async {
      // Long press is not discoverable by looking, so the one audience that
      // can be *told* about it must be.
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(
        tester,
        IuxTooltip(message: _message, child: _iconAction()),
      );
      final SemanticsNode node =
          tester.getSemantics(find.bySemanticsLabel('Archive'));
      expect(
          node.getSemanticsData().hasAction(SemanticsAction.longPress), isTrue);
      handle.dispose();
    });

    testWidgets('the floating box adds no second stop in the reading order',
        (WidgetTester tester) async {
      // The message is already on the control's node. Repeated in the overlay
      // it would appear as a loose fragment somewhere else entirely, arriving
      // and leaving for reasons a screen-reader user cannot perceive.
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(
        tester,
        IuxTooltip(message: _message, child: _iconAction()),
      );
      await tester.longPress(find.byIcon(Icons.archive_outlined));
      await tester.pumpAndSettle();

      expect(tooltipText(), findsOneWidget);
      expect(find.bySemanticsLabel(_message), findsNothing);
      handle.dispose();
    });
  });

  group('the boundary between a tooltip and a help panel is enforced', () {
    test('an empty message is refused at construction', () {
      expect(
        () => IuxTooltip(message: '', child: const SizedBox.shrink()),
        throwsAssertionError,
      );
    });

    test('the ceiling is a rune count, so an emoji is one character', () {
      expect(IuxTooltip.isWithinBounds('a' * kIuxTooltipMaximumCharacters),
          isTrue);
      expect(
          IuxTooltip.isWithinBounds('a' * (kIuxTooltipMaximumCharacters + 1)),
          isFalse);
      expect(IuxTooltip.isWithinBounds('🙂' * kIuxTooltipMaximumCharacters),
          isTrue);
    });

    test('a line break is refused, because two lines are two thoughts', () {
      expect(IuxTooltip.isWithinBounds('One thought.\nAnd another.'), isFalse);
    });

    testWidgets('a paragraph is rejected rather than floated',
        (WidgetTester tester) async {
      // The whole boundary rests on this. A ceiling written in a document has
      // never once kept a tooltip short.
      await host(
        tester,
        IuxTooltip(message: _helpText, child: _iconAction()),
      );
      expect(tester.takeException(), isAssertionError);
    });
  });

  group('a tooltip stays on the screen it is drawn on', () {
    testWidgets('a control in the trailing corner keeps its tooltip on screen',
        (WidgetTester tester) async {
      // The single most common place a tooltip is put, and the single most
      // common place one is clipped.
      const Size size = Size(320, 640);
      await host(
        tester,
        IuxTooltip(message: _message, child: _iconAction()),
        size: size,
        alignment: Alignment.topRight,
      );
      await tester.longPress(find.byIcon(Icons.archive_outlined));
      await tester.pumpAndSettle();

      final Rect rect = tester.getRect(tooltipText());
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(size.width));
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThanOrEqualTo(size.height));
    });

    testWidgets('a control at the bottom flips its tooltip above itself',
        (WidgetTester tester) async {
      const Size size = Size(320, 640);
      await host(
        tester,
        IuxTooltip(message: _message, child: _iconAction()),
        size: size,
        alignment: Alignment.bottomCenter,
      );
      await tester.longPress(find.byIcon(Icons.archive_outlined));
      await tester.pumpAndSettle();

      final Rect anchor = tester.getRect(find.byIcon(Icons.archive_outlined));
      final Rect rect = tester.getRect(tooltipText());
      expect(rect.bottom, lessThanOrEqualTo(anchor.top));
      expect(rect.top, greaterThanOrEqualTo(0));
    });

    testWidgets(
        'it survives 200% text on a small screen without clipping or '
        'overflowing', (WidgetTester tester) async {
      const Size size = Size(320, 640);
      await host(
        tester,
        IuxTooltip(message: _message, child: _iconAction()),
        size: size,
        textScale: 2,
        alignment: Alignment.topLeft,
      );
      await tester.longPress(find.byIcon(Icons.archive_outlined));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final Rect rect = tester.getRect(tooltipText());
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(size.width));
    });

    testWidgets('it follows its control when the page scrolls under it',
        (WidgetTester tester) async {
      // A tooltip left behind by a scrolling page points at nothing, and points
      // at it convincingly. The position is recomputed from the anchor's paint
      // transform on every layout, so there is nothing to leave behind.
      final ScrollController controller = ScrollController();
      addTearDown(controller.dispose);

      await host(
        tester,
        SizedBox(
          height: 300,
          child: ListView(
            controller: controller,
            children: <Widget>[
              const SizedBox(height: 100),
              IuxTooltip(message: _message, child: _iconAction()),
              const SizedBox(height: 600),
            ],
          ),
        ),
      );
      await tester.longPress(find.byIcon(Icons.archive_outlined));
      await tester.pumpAndSettle();
      final Rect before = tester.getRect(tooltipText());

      controller.jumpTo(40);
      await tester.pumpAndSettle();
      final Rect after = tester.getRect(tooltipText());

      expect(after.top, closeTo(before.top - 40, 0.5));
    });

    testWidgets(
        'right to left places it without the widget knowing the '
        'language', (WidgetTester tester) async {
      const Size size = Size(320, 640);
      await host(
        tester,
        IuxTooltip(message: _message, child: _iconAction()),
        size: size,
        direction: TextDirection.rtl,
        alignment: Alignment.topLeft,
      );
      await tester.longPress(find.byIcon(Icons.archive_outlined));
      await tester.pumpAndSettle();

      final Rect rect = tester.getRect(tooltipText());
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(size.width));
    });
  });

  group('a tooltip is drawn from the theme and nothing else', () {
    for (final IuxThemeConfiguration configuration in _profiles) {
      testWidgets(
          'its text is readable and its edge visible under '
          '$configuration', (WidgetTester tester) async {
        final IuxTooltipTokens tokens = await resolve(
          tester,
          configuration,
          IuxTooltipResolver.resolve,
        );
        final IuxSemanticColors colors = IuxTheme.resolve(configuration).colors;

        expect(
          ContrastMetric.ratio(tokens.foreground, tokens.background),
          greaterThanOrEqualTo(ContrastMetric.normalText),
          reason: 'the message must be readable on the box it sits in',
        );
        expect(
          ContrastMetric.ratio(tokens.border, colors.surface.base),
          greaterThanOrEqualTo(ContrastMetric.nonText),
          reason: 'the edge of something floating over a page must be visible',
        );
      });
    }

    testWidgets('the box widens with the text rather than squeezing it',
        (WidgetTester tester) async {
      final IuxTooltipTokens standard = await resolve(
        tester,
        const IuxThemeConfiguration(),
        IuxTooltipResolver.resolve,
      );
      final IuxTooltipTokens enlarged = await resolve(
        tester,
        const IuxThemeConfiguration(),
        IuxTooltipResolver.resolve,
        textScale: 2,
      );
      expect(enlarged.maxWidth, greaterThan(standard.maxWidth));
    });

    testWidgets('it is outlined rather than elevated',
        (WidgetTester tester) async {
      // A shadow resolves to zero under a reduced visual stimulation
      // preference, and the edge of something floating over arbitrary content
      // may not be the first thing to disappear.
      final IuxTooltipTokens tokens = await resolve(
        tester,
        const IuxThemeConfiguration(),
        IuxTooltipResolver.resolve,
      );
      expect(tokens.borderWidth, greaterThan(0));
    });
  });

  group('a tooltip animates only if the user allows it', () {
    testWidgets('no motion means it simply appears, fully opaque',
        (WidgetTester tester) async {
      await host(
        tester,
        IuxTooltip(message: _message, child: _iconAction()),
        configuration: const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(motion: IuxMotionPreference.none),
        ),
      );
      await tester.longPress(find.byIcon(Icons.archive_outlined));
      // One frame only. An animation that "runs" for no time still leaves a
      // frame at zero opacity, and a box that flickers is worse than one that
      // simply appears — especially for the user who asked for no motion.
      await tester.pump();
      final FadeTransition fade = tester.widget<FadeTransition>(
        find
            .ancestor(
              of: tooltipText(),
              matching: find.byType(FadeTransition),
            )
            .first,
      );
      expect(fade.opacity.value, 1);
    });

    testWidgets(
        'the entrance is declared as motion, so the policy can remove '
        'it', (WidgetTester tester) async {
      final IuxTooltipTokens standard = await resolve(
        tester,
        const IuxThemeConfiguration(),
        IuxTooltipResolver.resolve,
      );
      final IuxTooltipTokens still = await resolve(
        tester,
        const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(motion: IuxMotionPreference.none),
        ),
        IuxTooltipResolver.resolve,
      );
      expect(standard.entrance.isAnimated, isTrue);
      expect(still.entrance.isAnimated, isFalse);
    });
  });

  group('contextual help is asked for, and the parent decides', () {
    testWidgets('the question is visible; the answer is not, until asked',
        (WidgetTester tester) async {
      await host(tester, const _HelpHost());
      expect(find.text(_helpLabel), findsOneWidget);
      expect(find.text(_helpText), findsNothing);
    });

    testWidgets('pressing it asks the parent, and the panel opens',
        (WidgetTester tester) async {
      final GlobalKey<_HelpHostState> key = GlobalKey<_HelpHostState>();
      await host(tester, _HelpHost(key: key));
      await tester.tap(find.text(_helpLabel));
      await tester.pumpAndSettle();

      expect(key.currentState!.requested, <bool>[true]);
      expect(find.text(_helpText), findsOneWidget);
    });

    testWidgets('pressing it again asks for the opposite',
        (WidgetTester tester) async {
      final GlobalKey<_HelpHostState> key = GlobalKey<_HelpHostState>();
      await host(tester, _HelpHost(key: key, initiallyExpanded: true));
      await tester.tap(find.text(_helpLabel));
      await tester.pumpAndSettle();

      expect(key.currentState!.requested, <bool>[false]);
      expect(find.text(_helpText), findsNothing);
    });

    testWidgets('a parent that ignores the request keeps the panel shut',
        (WidgetTester tester) async {
      // The component owns nothing. A widget that opened itself would be a
      // widget whose state the parent cannot read.
      final GlobalKey<_HelpHostState> key = GlobalKey<_HelpHostState>();
      await host(tester, _HelpHost(key: key, accept: false));
      await tester.tap(find.text(_helpLabel));
      await tester.pumpAndSettle();

      expect(key.currentState!.requested, <bool>[true]);
      expect(find.text(_helpText), findsNothing);
    });

    testWidgets('the keyboard opens it too', (WidgetTester tester) async {
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      final GlobalKey<_HelpHostState> key = GlobalKey<_HelpHostState>();
      await host(tester, _HelpHost(key: key, focusNode: node));

      node.requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text(_helpText), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(find.text(_helpText), findsNothing);
    });

    test('a disclosure with nothing to say is refused', () {
      expect(
        () => IuxContextualHelp(
          label: '',
          help: _helpText,
          expanded: false,
          onExpandedChanged: (bool _) {},
        ),
        throwsAssertionError,
      );
      expect(
        () => IuxContextualHelp(
          label: _helpLabel,
          help: '',
          expanded: false,
          onExpandedChanged: (bool _) {},
        ),
        throwsAssertionError,
      );
    });
  });

  group('contextual help announces what it is and what it is doing', () {
    testWidgets('it is a named button that says whether it is open',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(tester, const _HelpHost());

      final SemanticsNode collapsed =
          tester.getSemantics(find.bySemanticsLabel(_helpLabel));
      expect(collapsed.flagsCollection.isButton, isTrue);
      // Not `none`: the platform is told this control *has* an open state,
      // which is what lets it say "collapsed" before the user presses it.
      expect(collapsed.flagsCollection.isExpanded, Tristate.isFalse);

      await tester.tap(find.text(_helpLabel));
      await tester.pumpAndSettle();

      final SemanticsNode expanded =
          tester.getSemantics(find.bySemanticsLabel(_helpLabel));
      expect(expanded.flagsCollection.isExpanded, Tristate.isTrue);
      handle.dispose();
    });

    testWidgets('a screen-reader activation opens it',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final GlobalKey<_HelpHostState> key = GlobalKey<_HelpHostState>();
      await host(tester, _HelpHost(key: key));

      final SemanticsNode node =
          tester.getSemantics(find.bySemanticsLabel(_helpLabel));
      // performAction is the closest a widget test gets to TalkBack's
      // double-tap: it invokes the action the platform would.
      // ignore: deprecated_member_use
      tester.binding.pipelineOwner.semanticsOwner!
          .performAction(node.id, SemanticsAction.tap);
      await tester.pumpAndSettle();
      expect(key.currentState!.requested, <bool>[true]);
      handle.dispose();
    });

    testWidgets('the glyphs add no announcement of their own',
        (WidgetTester tester) async {
      // The state is already on the node, where the platform speaks it in the
      // user's own language. A glyph carrying it a second time is a shape the
      // user has to decode to learn something they were already told.
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(tester, const _HelpHost());
      final SemanticsNode node =
          tester.getSemantics(find.bySemanticsLabel(_helpLabel));
      expect(node.label, _helpLabel);
      handle.dispose();
    });

    testWidgets('the open state is carried by a shape as well as by speech',
        (WidgetTester tester) async {
      // Render the screen in one hue and every state carried by colour alone
      // disappears. A direction survives it.
      await host(tester, const _HelpHost());
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
      expect(find.byIcon(Icons.expand_less), findsNothing);

      await tester.tap(find.text(_helpLabel));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.expand_less), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsNothing);
    });

    testWidgets('the panel is not announced a second time when it opens',
        (WidgetTester tester) async {
      // The user pressed the control, the platform announced the state change,
      // and the text is the next thing in the reading order. A live region here
      // would interrupt them to repeat what they are already on their way to.
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(tester, const _HelpHost(initiallyExpanded: true));
      final SemanticsNode node = tester.getSemantics(find.text(_helpText));
      expect(node.flagsCollection.isLiveRegion, isFalse);
      expect(find.text(_helpText), findsOneWidget);
      handle.dispose();
    });
  });

  group('contextual help survives the conditions a page is actually read in',
      () {
    testWidgets('the control meets the touch target floor',
        (WidgetTester tester) async {
      await host(tester, const _HelpHost());
      final Size size = tester.getSize(find.byIcon(Icons.expand_more));
      expect(size.height, greaterThan(0));

      final Rect control = tester.getRect(
        find
            .ancestor(
              of: find.text(_helpLabel),
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
        const _HelpHost(),
        configuration: const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(
            touchTarget: IuxTouchTargetPreference.comfortable,
          ),
        ),
      );
      final Rect control = tester.getRect(
        find
            .ancestor(
              of: find.text(_helpLabel),
              matching: find.byType(ConstrainedBox),
            )
            .first,
      );
      expect(control.height, greaterThanOrEqualTo(IuxTouchTarget.comfortable));
    });

    testWidgets(
        'a paragraph of help at 200% on a small screen neither clips '
        'nor overflows', (WidgetTester tester) async {
      // The case a tooltip cannot serve, and the reason this component exists.
      // Hosted in a scroll view, because that is where a page lives. The panel
      // sits in the flow and grows; growing past the bottom of the screen is
      // the parent's to absorb, and it can — which is exactly what a floating
      // box cannot do.
      await host(
        tester,
        const SingleChildScrollView(child: _HelpHost(initiallyExpanded: true)),
        size: const Size(320, 640),
        textScale: 2,
        alignment: Alignment.topCenter,
      );
      expect(tester.takeException(), isNull);
      expect(find.text(_helpText), findsOneWidget);

      final Text text = tester.widget<Text>(find.text(_helpText));
      expect(text.maxLines, isNull);
      expect(text.overflow, isNot(TextOverflow.ellipsis));
    });

    testWidgets('a long question wraps rather than overflowing',
        (WidgetTester tester) async {
      const String question =
          'Why do we ask for the name exactly as it appears on your document?';
      await host(
        tester,
        const _HelpHost(label: question),
        size: const Size(320, 640),
        textScale: 2,
        alignment: Alignment.topCenter,
      );
      expect(tester.takeException(), isNull);
      expect(find.text(question), findsOneWidget);
    });

    testWidgets(
        'right to left reverses the row without the widget knowing '
        'the language', (WidgetTester tester) async {
      await host(
        tester,
        const _HelpHost(),
        direction: TextDirection.rtl,
      );
      final double glyph = tester.getCenter(find.byIcon(Icons.help_outline)).dx;
      final double label = tester.getCenter(find.text(_helpLabel)).dx;
      expect(glyph, greaterThan(label));
    });
  });

  group('contextual help is drawn from the theme and nothing else', () {
    for (final IuxThemeConfiguration configuration in _profiles) {
      testWidgets('its label and its help are readable under $configuration',
          (WidgetTester tester) async {
        final IuxContextualHelpTokens tokens = await resolve(
          tester,
          configuration,
          (BuildContext context) => IuxContextualHelpResolver.resolve(
            context,
            expanded: true,
          ),
        );
        final IuxSemanticColors colors = IuxTheme.resolve(configuration).colors;

        expect(
          ContrastMetric.ratio(tokens.labelStyle.color!, colors.surface.base),
          greaterThanOrEqualTo(ContrastMetric.normalText),
          reason: 'the question sits on the page',
        );
        expect(
          ContrastMetric.ratio(tokens.helpStyle.color!, tokens.panelBackground),
          greaterThanOrEqualTo(ContrastMetric.normalText),
          reason: 'the answer sits on the panel',
        );
        expect(
          ContrastMetric.ratio(tokens.glyphColor, colors.surface.base),
          greaterThanOrEqualTo(ContrastMetric.normalText),
          reason: 'the glyphs are part of a control label, not decoration',
        );
      });
    }

    testWidgets('the glyphs grow with the text they sit beside',
        (WidgetTester tester) async {
      final IuxContextualHelpTokens standard = await resolve(
        tester,
        const IuxThemeConfiguration(),
        (BuildContext context) =>
            IuxContextualHelpResolver.resolve(context, expanded: false),
      );
      final IuxContextualHelpTokens enlarged = await resolve(
        tester,
        const IuxThemeConfiguration(),
        (BuildContext context) =>
            IuxContextualHelpResolver.resolve(context, expanded: false),
        textScale: 2,
      );
      expect(enlarged.glyphSize, greaterThan(standard.glyphSize));
    });

    testWidgets(
        'the panel is separated by a fill and an outline, neither of '
        'which carries meaning', (WidgetTester tester) async {
      final IuxContextualHelpTokens tokens = await resolve(
        tester,
        const IuxThemeConfiguration(),
        (BuildContext context) =>
            IuxContextualHelpResolver.resolve(context, expanded: true),
      );
      final IuxSemanticColors colors =
          IuxTheme.resolve(const IuxThemeConfiguration()).colors;
      expect(tokens.panelBackground, colors.surface.subtle);
      expect(tokens.panelBorder, colors.border.subtle);
      expect(tokens.borderWidth, greaterThan(0));
    });
  });
}
