import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

/// The four profiles every visual guarantee has to survive.
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

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget subject, {
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
            child: Scaffold(body: SingleChildScrollView(child: subject)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// A control built without touching another mission's component, so this
  /// file keeps testing the card rather than whatever the button is doing.
  Widget control(String label, VoidCallback onTap) => IuxTapTarget(
        onTap: onTap,
        semanticLabel: label,
        child: const Icon(Icons.chevron_right),
      );

  BoxDecoration surfaceDecoration(WidgetTester tester) => tester
      .widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(IuxSurface),
              matching: find.byType(DecoratedBox),
            )
            .first,
      )
      .decoration as BoxDecoration;

  /// What a screen reader actually announces for [node], after merging.
  String announced(SemanticsNode node) => node.getSemanticsData().label;

  /// How many separate stops a screen reader finds below [node].
  ///
  /// A node merged into its parent is not a stop: the user cannot land on it,
  /// which is the whole point of merging a card into one control.
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

  group('a card is either a control or it contains controls, never both', () {
    testWidgets('a tappable card containing an IUX control fails loudly',
        (WidgetTester tester) async {
      await pump(
        tester,
        IuxCard.tappable(
          semanticLabel: 'Open order 3141',
          onActivate: () {},
          child: Column(
            children: <Widget>[
              const Text('Order 3141'),
              control('Track', () {}),
            ],
          ),
        ),
      );

      final Object? error = tester.takeException();
      expect(error, isFlutterError);
      expect(
        error.toString(),
        contains('IuxTapTarget'),
        reason: 'the message has to name what to go and remove',
      );
      expect(
        error.toString(),
        contains('what does tapping do'),
        reason: 'the message explains the failure, not only the rule',
      );
    });

    testWidgets('a tappable card containing a Material control fails too',
        (WidgetTester tester) async {
      // The check is not an IUX allow-list. A card assembled from Material
      // widgets produces exactly the same nested-control confusion.
      await pump(
        tester,
        IuxCard.tappable(
          semanticLabel: 'Open order 3141',
          onActivate: () {},
          child: Column(
            children: <Widget>[
              const Text('Order 3141'),
              TextButton(onPressed: () {}, child: const Text('Track')),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isFlutterError);
    });

    testWidgets('a tappable card accepts content that is not a control',
        (WidgetTester tester) async {
      await pump(
        tester,
        IuxCard.tappable(
          semanticLabel: 'Open order 3141',
          onActivate: () {},
          child: const Column(
            children: <Widget>[
              Text('Order 3141'),
              Icon(Icons.local_shipping),
              Text('Delivered'),
            ],
          ),
        ),
      );

      expect(
        tester.takeException(),
        isNull,
        reason: 'text and icons are content; only controls are the problem',
      );
    });

    testWidgets('a tappable card has no way to declare actions',
        (WidgetTester tester) async {
      // The API half of the rule. `IuxCard.tappable(actions: ...)` does not
      // compile, so the sanctioned way to put a control in a card is closed
      // for the form that is itself a control.
      final IuxCard card = IuxCard.tappable(
        semanticLabel: 'Open order 3141',
        onActivate: () {},
        child: const Text('Order 3141'),
      );

      expect(card.actions, isNull);
      expect(card.onActivate, isNotNull);
    });

    testWidgets('a plain card keeps each of its actions reachable',
        (WidgetTester tester) async {
      final List<String> pressed = <String>[];
      await pump(
        tester,
        IuxCard(
          child: const Text('Order 3141'),
          actions: <Widget>[
            control('Track', () => pressed.add('track')),
            control('Cancel', () => pressed.add('cancel')),
          ],
        ),
      );

      expect(tester.takeException(), isNull);

      await tester.tap(find.bySemanticsLabel('Track'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Cancel'));
      await tester.pumpAndSettle();

      expect(
        pressed,
        <String>['track', 'cancel'],
        reason: 'each control is its own target with its own name, which is '
            'what a card that is not itself a control buys the user',
      );
    });
  });

  group('a tappable card is one named control', () {
    Future<void> pumpTappable(
      WidgetTester tester, {
      String label = 'Open order 3141',
      String? hint,
      VoidCallback? onActivate,
      bool autofocus = false,
      Widget child = const Column(
        children: <Widget>[Text('Order 3141'), Text('Delivered')],
      ),
      IuxThemeConfiguration configuration = const IuxThemeConfiguration(),
      Size size = const Size(400, 800),
    }) =>
        pump(
          tester,
          IuxCard.tappable(
            semanticLabel: label,
            hint: hint,
            autofocus: autofocus,
            onActivate: onActivate ?? () {},
            child: child,
          ),
          configuration: configuration,
          size: size,
        );

    testWidgets('it is announced as an enabled button',
        (WidgetTester tester) async {
      await pumpTappable(tester);

      expect(
        tester.getSemantics(find.byType(IuxCard)),
        isSemantics(
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          hasTapAction: true,
        ),
      );
    });

    testWidgets('it announces the name it was given',
        (WidgetTester tester) async {
      await pumpTappable(tester);

      expect(
        announced(tester.getSemantics(find.byType(IuxCard))),
        contains('Open order 3141'),
      );
    });

    testWidgets('it also announces the content it shows',
        (WidgetTester tester) async {
      // The name says what the user is about to open; the content says what
      // they are looking at. Dropping the content would delete the status and
      // the amount from the interface of every screen-reader user.
      await pumpTappable(tester);

      final String label = announced(tester.getSemantics(find.byType(IuxCard)));
      expect(label, contains('Order 3141'));
      expect(label, contains('Delivered'));
    });

    testWidgets('the whole card is a single stop, not one stop per line',
        (WidgetTester tester) async {
      await pumpTappable(tester);

      expect(
        stopsBelow(tester.getSemantics(find.byType(IuxCard))),
        0,
        reason: 'a card that is one control must not offer its lines as '
            'separate stops, or the user cannot tell which one activates',
      );
    });

    testWidgets('a nameless tappable card is refused',
        (WidgetTester tester) async {
      expect(
        () => IuxCard.tappable(
          semanticLabel: '',
          onActivate: () {},
          child: const Text('Order 3141'),
        ),
        throwsAssertionError,
      );
    });

    testWidgets('the hint says what activating does',
        (WidgetTester tester) async {
      await pumpTappable(tester, hint: 'Opens the order');

      expect(
        tester.getSemantics(find.byType(IuxCard)).getSemanticsData().hint,
        contains('Opens the order'),
      );
    });

    testWidgets('one tap activates it exactly once',
        (WidgetTester tester) async {
      int calls = 0;
      await pumpTappable(tester, onActivate: () => calls++);

      await tester.tap(find.byType(IuxCard));
      await tester.pumpAndSettle();

      expect(calls, 1);
    });

    testWidgets('Enter and Space activate it', (WidgetTester tester) async {
      int calls = 0;
      await pumpTappable(tester, autofocus: true, onActivate: () => calls++);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(calls, 2,
          reason: 'a card reached by keyboard has to activate '
              'without a pointer, like any other control');
    });

    testWidgets('it meets the touch target floor however small its content',
        (WidgetTester tester) async {
      for (final IuxDensity density in IuxDensity.values) {
        await pumpTappable(
          tester,
          child: const SizedBox.shrink(),
          configuration: IuxThemeConfiguration(
            profile: IuxAccessibilityProfile(density: density),
          ),
        );

        final Size size = tester.getSize(find.byType(IuxSurface));
        expect(
          size.height,
          greaterThanOrEqualTo(IuxTouchTarget.minimum),
          reason: '${density.name} produced a card ${size.height} tall',
        );
      }
    });

    testWidgets('a comfortable target preference enlarges it',
        (WidgetTester tester) async {
      await pumpTappable(
        tester,
        child: const SizedBox.shrink(),
        configuration: const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(
            touchTarget: IuxTouchTargetPreference.comfortable,
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(IuxSurface)).height,
        greaterThanOrEqualTo(IuxTouchTarget.comfortable),
      );
    });
  });

  group('a plain card is not a control', () {
    testWidgets('it is not announced as a button', (WidgetTester tester) async {
      await pump(tester, const IuxCard(child: Text('Order 3141')));

      expect(
        tester.getSemantics(find.byType(IuxCard)),
        isSemantics(isButton: false, hasTapAction: false),
      );
    });

    testWidgets('its content stays individually readable',
        (WidgetTester tester) async {
      // The opposite of the tappable card, and deliberately so: nothing here
      // is one control, so nothing is collapsed into one utterance.
      await pump(
        tester,
        IuxCard(
          child: const Text('Order 3141'),
          actions: <Widget>[control('Track', () {})],
        ),
      );

      expect(
        stopsBelow(tester.getSemantics(find.byType(IuxCard))),
        greaterThan(0),
        reason: 'a card that is not a control must not absorb its content '
            'into one node: the control inside it would stop being somewhere '
            'the user can land',
      );
    });

    testWidgets('adjacent actions keep the minimum separation',
        (WidgetTester tester) async {
      // Target size alone does not prevent mis-taps: a finger landing on the
      // seam between two touching targets has no margin for error.
      await pump(
        tester,
        IuxCard(
          child: const Text('Order 3141'),
          actions: <Widget>[
            control('Track', () {}),
            control('Cancel', () {}),
          ],
        ),
      );

      final Rect first = tester.getRect(find.bySemanticsLabel('Track'));
      final Rect second = tester.getRect(find.bySemanticsLabel('Cancel'));

      expect(
        second.left - first.right,
        greaterThanOrEqualTo(kIuxMinimumTargetSpacing),
      );
    });

    testWidgets('actions are laid out after the content they belong to',
        (WidgetTester tester) async {
      await pump(
        tester,
        IuxCard(
          child: const Text('Order 3141'),
          actions: <Widget>[control('Track', () {})],
        ),
      );

      expect(
        tester.getRect(find.text('Order 3141')).bottom,
        lessThanOrEqualTo(tester.getRect(find.bySemanticsLabel('Track')).top),
        reason: 'visual order and tree order have to agree, or a screen '
            'reader reads a sequence nobody can see',
      );
    });

    testWidgets('an empty actions list is refused',
        (WidgetTester tester) async {
      await pump(
        tester,
        const IuxCard(child: Text('Order 3141'), actions: <Widget>[]),
      );

      expect(tester.takeException(), isAssertionError);
    });
  });

  group('grouping survives when elevation resolves to zero', () {
    testWidgets('a card keeps its outline once the theme is flattened',
        (WidgetTester tester) async {
      await pump(
        tester,
        const IuxCard(child: Text('Order 3141')),
        configuration: const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(
            visualStimulation: IuxVisualStimulation.reduced,
          ),
        ),
      );

      expect(
        IuxGeometryTheme.of(tester.element(find.byType(IuxCard)))
            .elevationRaised,
        0,
        reason: 'the premise of this test: the theme has removed elevation',
      );

      final BoxDecoration decoration = surfaceDecoration(tester);
      expect(
        decoration.border,
        isNotNull,
        reason: 'with elevation gone, the outline is what is left to say '
            'where the card starts and stops',
      );
    });

    testWidgets('a card never casts a shadow, at any profile',
        (WidgetTester tester) async {
      for (final IuxThemeConfiguration configuration in _profiles) {
        await pump(
          tester,
          const IuxCard(child: Text('Order 3141')),
          configuration: configuration,
        );

        expect(
          surfaceDecoration(tester).boxShadow,
          isNull,
          reason: 'a shadow is invisible in dark conditions and removed under '
              'reduced visual stimulation, so it is never the signal — '
              'failed on $configuration',
        );
      }
    });

    testWidgets('a card is distinguishable from the page at every profile',
        (WidgetTester tester) async {
      // The outline is not decoration. The light profile paints a raised
      // surface the same colour as the page, so on that profile the outline is
      // the only thing saying where the card is — and it is the reason the
      // border is unconditional rather than a parameter.
      for (final IuxThemeConfiguration configuration in _profiles) {
        await pump(
          tester,
          const IuxCard(child: Text('Order 3141')),
          configuration: configuration,
        );

        final IuxSemanticColors colors =
            IuxSemanticColors.of(tester.element(find.byType(IuxCard)));
        final BoxDecoration decoration = surfaceDecoration(tester);

        expect(
          decoration.border != null || decoration.color != colors.surface.base,
          isTrue,
          reason: 'a card has to be separable from the page by something that '
              'survives elevation resolving to zero — failed on $configuration',
        );
      }
    });

    testWidgets('a group of three items draws two separators',
        (WidgetTester tester) async {
      await pump(
        tester,
        const IuxContentGroup(
          children: <Widget>[Text('Street'), Text('City'), Text('Postcode')],
        ),
      );

      final IuxSemanticColors colors =
          IuxSemanticColors.of(tester.element(find.byType(IuxContentGroup)));
      final Iterable<DecoratedBox> boxes = tester.widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(IuxContentGroup),
          matching: find.byType(DecoratedBox),
        ),
      );

      final int separators = boxes.where((DecoratedBox box) {
        final BoxDecoration decoration = box.decoration as BoxDecoration;
        return decoration.color == colors.border.subtle &&
            decoration.border == null;
      }).length;

      expect(
        separators,
        2,
        reason: 'three items have two boundaries between them, and none '
            'around the outside where the group border already is',
      );
    });

    testWidgets('a group keeps its outline once the theme is flattened',
        (WidgetTester tester) async {
      await pump(
        tester,
        const IuxContentGroup(children: <Widget>[Text('Street')]),
        configuration: const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(
            visualStimulation: IuxVisualStimulation.reduced,
          ),
        ),
      );

      final BoxDecoration decoration = surfaceDecoration(tester);
      expect(decoration.border, isNotNull);
      expect(decoration.boxShadow, isNull);
    });

    testWidgets('an empty group is refused', (WidgetTester tester) async {
      await pump(tester, const IuxContentGroup(children: <Widget>[]));

      expect(tester.takeException(), isAssertionError);
    });
  });

  group('a group is not a section', () {
    testWidgets('a group publishes a container and no heading',
        (WidgetTester tester) async {
      await pump(
        tester,
        const IuxContentGroup(children: <Widget>[Text('Street')]),
      );

      expect(
        tester.getSemantics(find.byType(IuxContentGroup)),
        isSemantics(isHeader: false),
      );
    });

    testWidgets('a group of three items is three stops, not one paragraph',
        (WidgetTester tester) async {
      // The opposite decision from a tappable card, and the reason both are
      // written down: that card is one control, so it is one stop; a group is
      // several items, so a user has to be able to move between them.
      await pump(
        tester,
        const IuxContentGroup(
          children: <Widget>[Text('Street'), Text('City'), Text('Postcode')],
        ),
      );

      expect(
        stopsBelow(tester.getSemantics(find.byType(IuxContentGroup))),
        3,
      );
    });

    testWidgets('a section around a group supplies the heading',
        (WidgetTester tester) async {
      // This is the composition the group exists for: a group encloses, a
      // section names. Giving the group its own title would produce a second
      // way to write a heading, only one of which reaches a screen reader's
      // heading index.
      await pump(
        tester,
        const IuxSection(
          title: 'Delivery',
          children: <Widget>[
            IuxContentGroup(children: <Widget>[Text('Street'), Text('City')]),
          ],
        ),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('Delivery')),
        isSemantics(isHeader: true, label: 'Delivery'),
      );
    });
  });

  group('resilience', () {
    testWidgets('a long line wraps rather than being clipped',
        (WidgetTester tester) async {
      await pump(
        tester,
        const IuxCard(
          child: Text(
            'Your parcel was handed to the carrier and is expected to arrive '
            'between Tuesday and Thursday next week',
          ),
        ),
        size: const Size(320, 640),
      );

      expect(tester.takeException(), isNull);
      expect(tester.widget<Text>(find.byType(Text)).overflow,
          isNot(TextOverflow.ellipsis));
    });

    testWidgets('a card survives 200% text on a small screen',
        (WidgetTester tester) async {
      await pump(
        tester,
        IuxCard(
          child: const Text('Order 3141 was delivered on Tuesday'),
          actions: <Widget>[
            control('Track', () {}),
            control('Cancel', () {}),
          ],
        ),
        textScale: 2,
        size: const Size(320, 480),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('a tappable card survives 200% text on a small screen',
        (WidgetTester tester) async {
      await pump(
        tester,
        IuxCard.tappable(
          semanticLabel: 'Open order 3141',
          onActivate: () {},
          child: const Text('Order 3141 was delivered on Tuesday'),
        ),
        textScale: 2,
        size: const Size(320, 480),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('a group survives 200% text on a small screen',
        (WidgetTester tester) async {
      await pump(
        tester,
        const IuxContentGroup(
          children: <Widget>[
            Text('12 Rue des Fleurs, Building C, Staircase 3'),
            Text('75011 Paris'),
          ],
        ),
        textScale: 2,
        size: const Size(320, 480),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('both render right to left', (WidgetTester tester) async {
      await pump(
        tester,
        const Column(
          children: <Widget>[
            IuxCard(child: Text('الطلب ٣١٤١')),
            IuxContentGroup(children: <Widget>[Text('شارع'), Text('المدينة')]),
          ],
        ),
        direction: TextDirection.rtl,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('الطلب ٣١٤١'), findsOneWidget);
      expect(find.text('المدينة'), findsOneWidget);
    });

    testWidgets('both render on every theme profile',
        (WidgetTester tester) async {
      for (final IuxThemeConfiguration configuration in _profiles) {
        await pump(
          tester,
          Column(
            children: <Widget>[
              IuxCard(
                child: const Text('Order 3141'),
                actions: <Widget>[control('Track', () {})],
              ),
              IuxCard.tappable(
                semanticLabel: 'Open order 3140',
                onActivate: () {},
                child: const Text('Order 3140'),
              ),
              const IuxContentGroup(
                children: <Widget>[Text('Street'), Text('City')],
              ),
            ],
          ),
          configuration: configuration,
        );

        expect(tester.takeException(), isNull, reason: '$configuration');
        expect(find.text('Order 3141'), findsOneWidget);
        expect(find.text('City'), findsOneWidget);
      }
    });
  });

  group('motion', () {
    Finder pressLayer() => find.descendant(
          of: find.byType(IuxCard),
          matching: find.byType(AnimatedOpacity),
        );

    Future<void> pumpTappable(
      WidgetTester tester,
      IuxMotionPreference motion,
    ) =>
        pump(
          tester,
          IuxCard.tappable(
            semanticLabel: 'Open order 3141',
            onActivate: () {},
            child: const Text('Order 3141'),
          ),
          configuration: IuxThemeConfiguration(
            profile: IuxAccessibilityProfile(motion: motion),
          ),
        );

    testWidgets('no motion removes the fade, not the pressed state',
        (WidgetTester tester) async {
      await pumpTappable(tester, IuxMotionPreference.none);

      expect(
          tester.widget<AnimatedOpacity>(pressLayer()).duration, Duration.zero);

      final TestGesture gesture =
          await tester.startGesture(tester.getCenter(find.byType(IuxCard)));
      await tester.pump();

      expect(
        tester.widget<AnimatedOpacity>(pressLayer()).opacity,
        1,
        reason: 'removing the animation must never remove the information it '
            'carried: the press is still visible, it simply does not fade',
      );

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('reduced motion shortens the fade rather than removing it',
        (WidgetTester tester) async {
      await pumpTappable(tester, IuxMotionPreference.standard);
      final Duration full =
          tester.widget<AnimatedOpacity>(pressLayer()).duration;

      await pumpTappable(tester, IuxMotionPreference.reduced);
      final Duration reduced =
          tester.widget<AnimatedOpacity>(pressLayer()).duration;

      expect(reduced, lessThan(full));
      expect(reduced, greaterThan(Duration.zero));
    });
  });

  group('the card carries no business meaning', () {
    testWidgets('it emits no feedback of its own', (WidgetTester tester) async {
      // No haptic, no announcement, no snack bar. Those belong to the parent,
      // which is the only place that knows whether anything succeeded.
      final List<MethodCall> platform = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform,
              (MethodCall call) async {
        platform.add(call);
        return null;
      });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );

      await pump(
        tester,
        IuxCard.tappable(
          semanticLabel: 'Open order 3141',
          onActivate: () {},
          child: const Text('Order 3141'),
        ),
      );
      await tester.tap(find.byType(IuxCard));
      await tester.pumpAndSettle();

      expect(
        platform.where((MethodCall c) => c.method.startsWith('HapticFeedback')),
        isEmpty,
      );
    });
  });
}
