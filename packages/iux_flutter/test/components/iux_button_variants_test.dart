import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

/// The four profiles a component has to survive, not a sample of them.
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

/// Every variant a labelled button may take.
///
/// `icon` is excluded because it describes a control with no label; a labelled
/// button that accepted it is asserted against.
final List<IuxButtonVariant> _labelledVariants = IuxButtonVariant.values
    .where((IuxButtonVariant v) => v != IuxButtonVariant.icon)
    .toList();

/// Every variant an action the semantic layer models unfilled may take.
///
/// `filled` is excluded because a secondary or tertiary action has no fill to
/// draw: since IUX-039 `IuxButtonResolver` refuses the pair rather than
/// resolving it, measured, to a text button. The `close` fixture below is
/// secondary, which is what makes this list the right one for it.
final List<IuxButtonVariant> _unfilledVariants = IuxButtonVariant.values
    .where((IuxButtonVariant v) => v != IuxButtonVariant.filled)
    .toList();

void main() {
  const IuxActionDescriptor close = IuxActionDescriptor(
    semantics: IuxActionSemantics(label: 'Close'),
    role: IuxActionRole.dismiss,
  );
  const IuxActionDescriptor add = IuxActionDescriptor(
    semantics: IuxActionSemantics(label: 'Add'),
    intent: IuxActionIntent.primary,
  );

  Future<void> host(
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
          theme: IuxTheme.fromConfiguration(configuration),
          home: Directionality(
            textDirection: direction,
            child: Scaffold(body: Center(child: child)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpIconButton(
    WidgetTester tester, {
    IuxActionDescriptor action = close,
    IconData icon = Icons.close,
    IuxButtonVariant variant = IuxButtonVariant.icon,
    IuxThemeConfiguration configuration = const IuxThemeConfiguration(),
    TextDirection direction = TextDirection.ltr,
    double textScale = 1,
    Size size = const Size(400, 800),
    bool autofocus = false,
    List<int>? counter,
  }) async {
    final List<int> calls = counter ?? <int>[];
    await host(
      tester,
      IuxIconButton(
        icon: icon,
        action: action,
        variant: variant,
        autofocus: autofocus,
        onActivate: () => calls.add(calls.length),
      ),
      configuration: configuration,
      direction: direction,
      textScale: textScale,
      size: size,
    );
  }

  Future<void> pumpLabelled(
    WidgetTester tester, {
    IuxActionDescriptor action = add,
    String label = 'Add',
    IconData? icon,
    IuxButtonVariant? variant,
    IuxThemeConfiguration configuration = const IuxThemeConfiguration(),
    TextDirection direction = TextDirection.ltr,
    double textScale = 1,
    Size size = const Size(400, 800),
    List<int>? counter,
  }) async {
    final List<int> calls = counter ?? <int>[];
    await host(
      tester,
      IuxButton(
        label: label,
        icon: icon,
        action: action,
        variant: variant,
        onActivate: () => calls.add(calls.length),
      ),
      configuration: configuration,
      direction: direction,
      textScale: textScale,
      size: size,
    );
  }

  BoxDecoration decorationOf(WidgetTester tester) => tester
      .widget<AnimatedContainer>(find.byType(AnimatedContainer))
      .decoration! as BoxDecoration;

  group('an icon-only action always has a name', () {
    testWidgets('it is announced as a button carrying the action name',
        (WidgetTester tester) async {
      // The single most important guarantee of this widget. An icon-only
      // control without a name is a control a screen-reader user cannot
      // identify, activate deliberately, or describe to anyone else.
      await pumpIconButton(tester);

      expect(
        tester.getSemantics(find.bySemanticsLabel('Close')),
        matchesSemantics(
          label: 'Close',
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          hasTapAction: true,
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
    });

    testWidgets('there is no way to build one without a name',
        (WidgetTester tester) async {
      // Unrepresentable rather than validated: the widget has no label
      // parameter at all, and the action it must be given refuses an empty
      // one. A caller cannot reach the broken state.
      String blank() => '';
      expect(
        () => IuxActionSemantics(label: blank()),
        throwsAssertionError,
      );
    });

    testWidgets('the glyph adds no second announcement',
        (WidgetTester tester) async {
      // Two nodes for one control makes a screen-reader user swipe twice to
      // pass a single button, and the second stop says nothing useful.
      //
      // Strengthened in IUX-008.9. `findsOneWidget` on the *label* cannot
      // detect a second node, because a second node would be unlabelled and
      // therefore not matched: the test passed unchanged with
      // `excludeSemantics: false` forced into `IuxSemantics.action`, which is
      // exactly the change that produces the extra stop. Counting the node's
      // children is what actually answers the question — measured at 1 under
      // that break and 0 as shipped.
      await pumpIconButton(tester);
      expect(find.bySemanticsLabel('Close'), findsOneWidget);

      final SemanticsNode node =
          tester.getSemantics(find.byType(IuxIconButton));
      expect(node.label, 'Close');
      expect(
        node.childrenCount,
        0,
        reason: 'the control is one stop; anything below it is a second one',
      );
    });

    testWidgets('an unavailable icon button explains itself',
        (WidgetTester tester) async {
      await pumpIconButton(
        tester,
        action: const IuxActionDescriptor(
          semantics: IuxActionSemantics(
            label: 'Publish',
            unavailabilityReason: 'Add a title first',
          ),
          availability: IuxActionAvailability.disabled,
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Publish')).hint,
        contains('Add a title first'),
      );
    });
  });

  group('an icon button is small to look at and large to hit', () {
    testWidgets('the target meets the floor at every density',
        (WidgetTester tester) async {
      for (final IuxDensity density in IuxDensity.values) {
        await pumpIconButton(
          tester,
          configuration: IuxThemeConfiguration(
            profile: IuxAccessibilityProfile(density: density),
          ),
        );
        final Size target = tester.getSize(find.byType(AnimatedContainer));
        expect(
          target.height,
          greaterThanOrEqualTo(IuxTouchTarget.minimum),
          reason: '${density.name} produced ${target.height}',
        );
        expect(target.width, greaterThanOrEqualTo(IuxTouchTarget.minimum));
      }
    });

    testWidgets('a comfortable preference enlarges the target',
        (WidgetTester tester) async {
      await pumpIconButton(
        tester,
        configuration: const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(
            touchTarget: IuxTouchTargetPreference.comfortable,
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(AnimatedContainer)).height,
        greaterThanOrEqualTo(IuxTouchTarget.comfortable),
      );
    });

    testWidgets('the glyph stays smaller than the region that responds to it',
        (WidgetTester tester) async {
      // Enlarging the glyph to fill the target would make every icon action
      // shout; shrinking the target to the glyph would make it hard to hit.
      // They are two measurements, and this is the one that proves it.
      await pumpIconButton(tester);
      final Size glyph = tester.getSize(find.byIcon(Icons.close));
      final Size target = tester.getSize(find.byType(AnimatedContainer));

      expect(glyph.height, lessThan(target.height));
      expect(target.height, greaterThanOrEqualTo(IuxTouchTarget.minimum));
    });

    testWidgets('the glyph grows when the user enlarges text',
        (WidgetTester tester) async {
      // For an icon-only button the glyph is the entire content. Leaving it at
      // 20 for a user who asked for 200% keeps unreadable exactly the thing
      // they cannot read.
      await pumpIconButton(tester);
      final double standard = tester.getSize(find.byIcon(Icons.close)).height;

      await pumpIconButton(tester, textScale: 2, size: const Size(320, 480));
      final double enlarged = tester.getSize(find.byIcon(Icons.close)).height;

      expect(enlarged, greaterThan(standard));
      expect(
        tester.getSize(find.byType(AnimatedContainer)).height,
        greaterThanOrEqualTo(enlarged),
        reason: 'the container must still contain what it grew for',
      );
    });
  });

  group('a variant changes emphasis and nothing else', () {
    testWidgets('every icon button variant activates identically',
        (WidgetTester tester) async {
      for (final IuxButtonVariant variant in _unfilledVariants) {
        final List<int> calls = <int>[];
        await pumpIconButton(tester, variant: variant, counter: calls);
        await tester.tap(find.byType(IuxIconButton));
        await tester.pumpAndSettle();
        expect(calls, hasLength(1), reason: '${variant.name} swallowed a tap');
      }
    });

    testWidgets('every labelled variant activates identically',
        (WidgetTester tester) async {
      for (final IuxButtonVariant variant in _labelledVariants) {
        final List<int> calls = <int>[];
        await pumpLabelled(tester, variant: variant, counter: calls);
        await tester.tap(find.byType(IuxButton));
        await tester.pumpAndSettle();
        expect(calls, hasLength(1), reason: '${variant.name} swallowed a tap');
      }
    });

    testWidgets('an outlined button draws the outline it resolved',
        (WidgetTester tester) async {
      // A widget that resolved a border and then failed to paint it ships an
      // outlined button with no outline — invisible on a matching surface.
      await pumpLabelled(tester, variant: IuxButtonVariant.outlined);
      expect(decorationOf(tester).border, isNotNull);
    });

    testWidgets('a text button draws no container edge',
        (WidgetTester tester) async {
      await pumpLabelled(tester, variant: IuxButtonVariant.text);
      expect(decorationOf(tester).border, isNull);
    });

    testWidgets('a filled button and a text button differ in their container',
        (WidgetTester tester) async {
      // Emphasis has to be visible, or the variant is a name for nothing.
      await pumpLabelled(tester, variant: IuxButtonVariant.filled);
      final Color? filled = decorationOf(tester).color;

      await pumpLabelled(tester, variant: IuxButtonVariant.text);
      final Color? text = decorationOf(tester).color;

      expect(filled, isNot(equals(text)));
    });
  });

  group('a button takes the space it needs, and no more', () {
    testWidgets('an icon button is as tall as it is wide',
        (WidgetTester tester) async {
      // A label is what makes a button wider than it is tall. Without one, an
      // oblong target reads as a field the user is meant to type in.
      await pumpIconButton(tester);
      final Size target = tester.getSize(find.byType(AnimatedContainer));
      expect(target.width, closeTo(target.height, 0.01));
    });

    testWidgets('offered the whole screen, it still takes a button height',
        (WidgetTester tester) async {
      // A container that centres its child grows to fill whatever its parent
      // offers. Left unchecked, a button inside a Center became as tall as the
      // screen while still announcing itself as a button.
      await pumpIconButton(tester);
      expect(
        tester.getSize(find.byType(AnimatedContainer)).height,
        lessThan(100),
      );

      await pumpLabelled(tester);
      expect(
        tester.getSize(find.byType(AnimatedContainer)).height,
        lessThan(100),
      );
    });

    testWidgets('expand claims the width and leaves the height alone',
        (WidgetTester tester) async {
      await host(
        tester,
        IuxButton(
          label: 'Continue',
          action: add,
          expand: true,
          onActivate: () {},
        ),
        size: const Size(400, 800),
      );
      final Size size = tester.getSize(find.byType(AnimatedContainer));
      expect(size.width, greaterThan(300),
          reason: 'expand asked for the width');
      expect(size.height, lessThan(100),
          reason: 'it never asked for the height');
    });
  });

  group('incoherent combinations are refused at the call site', () {
    testWidgets('a labelled button refuses the icon variant',
        (WidgetTester tester) async {
      expect(
        () => IuxButton(
          label: 'Save',
          action: add,
          variant: IuxButtonVariant.icon,
          onActivate: () {},
        ),
        throwsAssertionError,
      );
    });

    testWidgets('a labelled button refuses an empty label',
        (WidgetTester tester) async {
      // An empty label leaves a container a sighted user can see and cannot
      // identify. IuxIconButton is the supported way to have no text.
      String blank() => '';
      expect(
        () => IuxButton(
          label: blank(),
          action: add,
          onActivate: () {},
        ),
        throwsAssertionError,
      );
    });

    testWidgets('a destructive icon button refuses the tonal variant',
        (WidgetTester tester) async {
      // Tonal carries intent through its border rather than its fill, which is
      // not enough separation for an action that destroys data — and an
      // unlabelled destructive control has even less to distinguish it.
      await pumpIconButton(
        tester,
        icon: Icons.delete,
        action: const IuxActionDescriptor.destructive(
          semantics: IuxActionSemantics(label: 'Delete'),
        ),
        variant: IuxButtonVariant.tonal,
      );
      expect(tester.takeException(), isA<AssertionError>());
    });
  });

  group('an icon beside a label', () {
    testWidgets('the glyph precedes the label in reading order',
        (WidgetTester tester) async {
      await pumpLabelled(tester, icon: Icons.add);
      expect(
        tester.getCenter(find.byIcon(Icons.add)).dx,
        lessThan(tester.getCenter(find.text('Add')).dx),
      );
    });

    testWidgets('reading order follows the language, not the screen',
        (WidgetTester tester) async {
      // Right-to-left puts the glyph on the right without the widget being
      // told which language it is in.
      await pumpLabelled(
        tester,
        label: 'إضافة',
        icon: Icons.add,
        direction: TextDirection.rtl,
      );
      expect(
        tester.getCenter(find.byIcon(Icons.add)).dx,
        greaterThan(tester.getCenter(find.text('إضافة')).dx),
      );
    });

    testWidgets('the glyph is left out of the announcement',
        (WidgetTester tester) async {
      // It repeats what the label already says. A second reading of it costs
      // the user time and tells them nothing.
      await pumpLabelled(tester, icon: Icons.add);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Add')),
        matchesSemantics(
          label: 'Add',
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          hasTapAction: true,
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
    });

    testWidgets('a long label still wraps once a glyph shares the width',
        (WidgetTester tester) async {
      // Adding an icon must not turn a wrapping button into an overflowing
      // one; a truncated action label is an action the user cannot identify.
      await pumpLabelled(
        tester,
        label: 'Confirm the permanent deletion of every archived invoice',
        icon: Icons.delete,
        action: const IuxActionDescriptor(
          semantics: IuxActionSemantics(label: 'Confirm deletion'),
        ),
        textScale: 2,
        size: const Size(320, 480),
      );
      expect(tester.takeException(), isNull);
      final Text text = tester.widget<Text>(find.byType(Text));
      expect(text.overflow, isNot(TextOverflow.ellipsis));
      expect(text.maxLines, isNull);
    });
  });

  group('availability and repetition behave as they do for a label', () {
    testWidgets('a disabled icon button produces no callback',
        (WidgetTester tester) async {
      final List<int> calls = <int>[];
      await pumpIconButton(
        tester,
        action: close.copyWith(availability: IuxActionAvailability.disabled),
        counter: calls,
      );

      await tester.tap(find.byType(IuxIconButton), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(calls, isEmpty);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Close')),
        matchesSemantics(
          label: 'Close',
          isButton: true,
          isEnabled: false,
          hasEnabledState: true,
          // No tap action while unavailable: a screen reader must not offer
          // an activation that would do nothing.
          hasTapAction: false,
        ),
      );
    });

    testWidgets('a second tap while running is dropped',
        (WidgetTester tester) async {
      final List<int> calls = <int>[];
      await pumpIconButton(
        tester,
        action: close.copyWith(operation: IuxActionOperation.inProgress),
        counter: calls,
      );

      await tester.tap(find.byType(IuxIconButton), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(calls, isEmpty);
    });

    testWidgets('Enter and Space activate a focused icon button',
        (WidgetTester tester) async {
      final List<int> calls = <int>[];
      await pumpIconButton(tester, autofocus: true, counter: calls);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(calls, hasLength(2));
    });
  });

  group('it survives the conditions users actually have', () {
    testWidgets('every icon button variant renders on every theme profile',
        (WidgetTester tester) async {
      for (final IuxThemeConfiguration configuration in _profiles) {
        for (final IuxButtonVariant variant in _unfilledVariants) {
          await pumpIconButton(
            tester,
            variant: variant,
            configuration: configuration,
          );
          expect(
            tester.takeException(),
            isNull,
            reason: '${variant.name} on $configuration',
          );
          expect(find.byIcon(Icons.close), findsOneWidget);
        }
      }
    });

    testWidgets('every labelled variant renders on every theme profile',
        (WidgetTester tester) async {
      for (final IuxThemeConfiguration configuration in _profiles) {
        for (final IuxButtonVariant variant in _labelledVariants) {
          await pumpLabelled(
            tester,
            icon: Icons.add,
            variant: variant,
            configuration: configuration,
          );
          expect(
            tester.takeException(),
            isNull,
            reason: '${variant.name} on $configuration',
          );
          expect(find.text('Add'), findsOneWidget);
        }
      }
    });

    testWidgets('a row of icon actions survives 200% text on a small screen',
        (WidgetTester tester) async {
      await host(
        tester,
        const IuxTargetSpacing(
          axis: Axis.horizontal,
          children: <Widget>[
            IuxIconButton(
              icon: Icons.arrow_back,
              action: IuxActionDescriptor(
                semantics: IuxActionSemantics(label: 'Back'),
              ),
              onActivate: _noop,
            ),
            IuxIconButton(
              icon: Icons.search,
              action: IuxActionDescriptor(
                semantics: IuxActionSemantics(label: 'Search'),
              ),
              onActivate: _noop,
            ),
            IuxIconButton(
              icon: Icons.close,
              action: IuxActionDescriptor(
                semantics: IuxActionSemantics(label: 'Close'),
              ),
              onActivate: _noop,
            ),
          ],
        ),
        textScale: 2,
        size: const Size(320, 480),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(IuxIconButton), findsNWidgets(3));
    });

    testWidgets('an icon button renders right-to-left',
        (WidgetTester tester) async {
      await pumpIconButton(tester, direction: TextDirection.rtl);
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('no motion still changes state, only instantly',
        (WidgetTester tester) async {
      await pumpIconButton(
        tester,
        configuration: const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(motion: IuxMotionPreference.none),
        ),
      );
      expect(
        tester
            .widget<AnimatedContainer>(find.byType(AnimatedContainer))
            .duration,
        Duration.zero,
      );
    });
  });
}

/// A callback that does nothing, so a scenario can build several buttons at
/// once without each one needing a closure of its own.
void _noop() {}
