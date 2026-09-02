import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';
// Imported from source rather than from the barrel: IUX-021 does not own
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

void main() {
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
          // Keyed by configuration so a test that switches profiles gets the
          // new theme outright. MaterialApp otherwise cross-fades between two
          // themes, and every colour read during that window belongs to
          // neither of them.
          key: ValueKey<IuxThemeConfiguration>(configuration),
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

  IuxSemanticColors colorsOf(IuxThemeConfiguration configuration) =>
      IuxTheme.resolve(configuration).colors;

  group('a status cannot be built without the words that carry it', () {
    test('every tone refuses an empty label', () {
      // The whole design rests on this: a coloured shape with no words is not
      // a status, it is decoration that implies something and refuses to say
      // what. It is made unconstructable rather than discouraged.
      expect(() => IuxStatus.neutral(''), throwsAssertionError);
      expect(() => IuxStatus.success(''), throwsAssertionError);
      expect(() => IuxStatus.warning(''), throwsAssertionError);
      expect(() => IuxStatus.error(''), throwsAssertionError);
    });

    test('the tone and the words travel together and cannot be separated', () {
      const IuxStatus status = IuxStatus.error('Payment declined');
      expect(status.tone, IuxStatusTone.error);
      expect(status.label, 'Payment declined');
      expect(status, const IuxStatus.error('Payment declined'));
      expect(status, isNot(const IuxStatus.warning('Payment declined')));
    });
  });

  group('every status carries a signal that survives a single hue', () {
    testWidgets('the label is drawn, never merely announced',
        (WidgetTester tester) async {
      await host(
        tester,
        const IuxStatusIndicator(status: IuxStatus.error('Payment declined')),
      );
      expect(find.text('Payment declined'), findsOneWidget);
    });

    testWidgets('a screen reader is given the same sentence the eye reads',
        (WidgetTester tester) async {
      await host(
        tester,
        const IuxStatusIndicator(status: IuxStatus.success('Order delivered')),
      );
      expect(find.bySemanticsLabel('Order delivered'), findsOneWidget);
    });

    test('the four tones are drawn with four different shapes', () {
      // Render the screen in one hue and every state that disappears was
      // carried by colour alone. Two tones sharing a glyph would be exactly
      // that failure, so the glyphs are asserted distinct rather than reviewed.
      final Set<IconData> glyphs =
          IuxStatusTone.values.map(IuxStatusResolver.glyph).toSet();
      expect(glyphs, hasLength(IuxStatusTone.values.length));
    });

    testWidgets('the glyph adds no second announcement of its own',
        (WidgetTester tester) async {
      // An icon carrying information the label does not is information a
      // screen-reader user never receives; an icon repeating it is a sentence
      // they hear twice. It is excluded, and the label speaks for both.
      await host(
        tester,
        const IuxStatusIndicator(status: IuxStatus.warning('Expires today')),
      );
      expect(find.bySemanticsLabel('Expires today'), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Expires today')),
        matchesSemantics(label: 'Expires today'),
      );
    });

    testWidgets('it never announces itself as something to press',
        (WidgetTester tester) async {
      // A status is not a control. Announcing one as a button sends the user
      // hunting for a gesture that does nothing.
      await host(
        tester,
        const IuxStatusIndicator(status: IuxStatus.neutral('Offline')),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Offline')),
        matchesSemantics(label: 'Offline'),
      );
    });
  });

  group('a count badge announces what it counts', () {
    testWidgets('the numeral is visible and the subject is spoken',
        (WidgetTester tester) async {
      await host(
        tester,
        const IuxBadge.count(count: '3', label: '3 unread messages'),
      );
      expect(find.text('3'), findsOneWidget);
      expect(find.bySemanticsLabel('3 unread messages'), findsOneWidget);
    });

    test('a badge whose label is only its number is rejected', () {
      // "3" is meaningless to anyone who has not already worked out what it
      // refers to, and it is the exact shape of the mistake this component
      // exists to prevent.
      expect(
        () => IuxBadge.count(count: '3', label: '3'),
        throwsAssertionError,
      );
    });

    test('a badge with no subject at all is rejected', () {
      expect(() => IuxBadge.count(count: '3', label: ''), throwsAssertionError);
      expect(() => IuxBadge.marker(label: ''), throwsAssertionError);
    });

    test('a badge with no number to show is rejected as a count', () {
      expect(
        () => IuxBadge.count(count: '', label: '3 unread messages'),
        throwsAssertionError,
      );
    });

    testWidgets('a badge with no number still says what it means',
        (WidgetTester tester) async {
      // Presence and absence survive a monochrome screen, so a marker is not a
      // colour-alone failure — provided it is named.
      await host(tester, const IuxBadge.marker(label: 'Unread messages'));
      expect(find.bySemanticsLabel('Unread messages'), findsOneWidget);
    });

    testWidgets('a badge is not announced as a control',
        (WidgetTester tester) async {
      // The badge decorates something; that something owns the gesture and the
      // touch target.
      await host(
        tester,
        const IuxBadge.count(count: '3', label: '3 unread messages'),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('3 unread messages')),
        matchesSemantics(label: '3 unread messages'),
      );
    });

    testWidgets('the numeral is not read a second time',
        (WidgetTester tester) async {
      await host(
        tester,
        const IuxBadge.count(count: '3', label: '3 unread messages'),
      );
      expect(find.bySemanticsLabel('3'), findsNothing);
    });
  });

  group('an interactive chip is a control, and says so', () {
    testWidgets('it announces its name and whether it is chosen',
        (WidgetTester tester) async {
      await host(
        tester,
        IuxFilterChip(
          label: 'Vegetarian',
          selected: true,
          onSelectionChanged: (bool _) {},
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Vegetarian')),
        matchesSemantics(
          label: 'Vegetarian',
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          isSelected: true,
          hasSelectedState: true,
          // A screen reader's double-tap has to reach the chip. The helper
          // excludes the subtree in order to control the announced name, so
          // the gesture detector's own action is gone and this node is the
          // only place an activation can live — IUX-011.
          hasTapAction: true,
          // And assistive technology has to be able to *put* accessibility
          // focus here rather than only find it by swiping — IUX-A11Y-FOCUS-001.
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
    });

    testWidgets('an unchosen chip says that too, rather than saying nothing',
        (WidgetTester tester) async {
      await host(
        tester,
        IuxFilterChip(
          label: 'Vegetarian',
          selected: false,
          onSelectionChanged: (bool _) {},
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Vegetarian')),
        matchesSemantics(
          label: 'Vegetarian',
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          hasSelectedState: true,
          hasTapAction: true,
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
    });

    testWidgets('a tap reports the value the user asked for',
        (WidgetTester tester) async {
      final List<bool> asked = <bool>[];
      await host(
        tester,
        IuxFilterChip(
          label: 'Vegetarian',
          selected: false,
          onSelectionChanged: asked.add,
        ),
      );
      await tester.tap(find.byType(IuxFilterChip));
      await tester.pumpAndSettle();
      expect(asked, <bool>[true]);
    });

    testWidgets('it never changes its own state', (WidgetTester tester) async {
      // The parent owns the filter. A chip that toggled itself would show a
      // criterion as applied before the list it filters had been rebuilt.
      await host(
        tester,
        IuxFilterChip(
          label: 'Vegetarian',
          selected: false,
          onSelectionChanged: (bool _) {},
        ),
      );
      await tester.tap(find.byType(IuxFilterChip));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.bySemanticsLabel('Vegetarian')),
        matchesSemantics(
          label: 'Vegetarian',
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          hasSelectedState: true,
          hasTapAction: true,
          isFocusable: true,
          hasFocusAction: true,
        ),
        reason: 'the chip still shows what the parent last told it',
      );
    });

    testWidgets('Enter and Space activate it without a pointer',
        (WidgetTester tester) async {
      final List<bool> asked = <bool>[];
      await host(
        tester,
        IuxFilterChip(
          label: 'Vegetarian',
          selected: false,
          onSelectionChanged: asked.add,
          autofocus: true,
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(asked, <bool>[true, true]);
    });

    testWidgets('it is never smaller than the resolved target floor',
        (WidgetTester tester) async {
      for (final IuxTouchTargetPreference preference
          in IuxTouchTargetPreference.values) {
        await host(
          tester,
          IuxFilterChip(
            label: 'Ok',
            selected: false,
            onSelectionChanged: (bool _) {},
          ),
          configuration: IuxThemeConfiguration(
            profile: IuxAccessibilityProfile(touchTarget: preference),
          ),
        );
        final BuildContext context = tester.element(find.byType(IuxFilterChip));
        final double floor = IuxAccessibility.of(context).minimumTouchTarget;
        final Size size = tester.getSize(
          find.descendant(
            of: find.byType(IuxFilterChip),
            matching: find.byType(AnimatedContainer),
          ),
        );
        expect(size.width, greaterThanOrEqualTo(floor), reason: '$preference');
        expect(size.height, greaterThanOrEqualTo(floor), reason: '$preference');
      }
    });

    testWidgets('a null callback disables it rather than silently ignoring it',
        (WidgetTester tester) async {
      // A nullable callback means "not available", and it has to produce
      // disabled semantics too, so the two cannot drift.
      await host(
        tester,
        const IuxFilterChip(
          label: 'Vegetarian',
          selected: false,
          onSelectionChanged: null,
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Vegetarian')),
        matchesSemantics(
          label: 'Vegetarian',
          isButton: true,
          hasEnabledState: true,
          hasSelectedState: true,
        ),
      );
      expect(
        tester
            .widget<Focus>(
              find.descendant(
                of: find.byType(IuxFilterChip),
                matching: find.byType(Focus),
              ),
            )
            .canRequestFocus,
        isFalse,
        reason: 'an unavailable criterion is skipped by focus traversal',
      );
    });

    test('an unnamed chip is rejected', () {
      expect(
        () => IuxFilterChip(
          label: '',
          selected: false,
          onSelectionChanged: (bool _) {},
        ),
        throwsAssertionError,
      );
    });
  });

  group('a chosen chip is distinguishable without its fill colour', () {
    Finder checkGlyph() => find.descendant(
          of: find.byType(IuxFilterChip),
          matching: find.byIcon(Icons.check),
        );

    testWidgets('choosing one adds a mark, not only a colour',
        (WidgetTester tester) async {
      await host(
        tester,
        IuxFilterChip(
          label: 'Vegetarian',
          selected: false,
          onSelectionChanged: (bool _) {},
        ),
      );
      expect(checkGlyph(), findsNothing);

      await host(
        tester,
        IuxFilterChip(
          label: 'Vegetarian',
          selected: true,
          onSelectionChanged: (bool _) {},
        ),
      );
      expect(checkGlyph(), findsOneWidget);
    });

    testWidgets('and a heavier outline, which survives a monochrome screen',
        (WidgetTester tester) async {
      for (final IuxThemeConfiguration configuration in _profiles) {
        final IuxChipTokens unselected = await resolve(
          tester,
          configuration,
          (BuildContext context) =>
              IuxChipResolver.resolve(context, IuxChipState.unselected),
        );
        final IuxChipTokens selected = await resolve(
          tester,
          configuration,
          (BuildContext context) =>
              IuxChipResolver.resolve(context, IuxChipState.selected),
        );
        expect(
          selected.borderWidth,
          greaterThan(unselected.borderWidth),
          reason: '$configuration',
        );
      }
    });

    testWidgets('the mark keeps its space, so toggling does not move the row',
        (WidgetTester tester) async {
      // A chip that changed width on every tap would reflow the whole group
      // and move the chips the user was about to press next.
      await host(
        tester,
        IuxFilterChip(
          label: 'Vegetarian',
          selected: false,
          onSelectionChanged: (bool _) {},
        ),
      );
      final Size unselected = tester.getSize(find.byType(IuxFilterChip));

      await host(
        tester,
        IuxFilterChip(
          label: 'Vegetarian',
          selected: true,
          onSelectionChanged: (bool _) {},
        ),
      );
      expect(
          tester.getSize(find.byType(IuxFilterChip)).width, unselected.width);
    });
  });

  group('the reserved slot is a choice, and it has a price in width', () {
    /// A group of chips of [labels], measured on a 360-wide screen.
    ///
    /// The width every measurement below is taken at, because it is the
    /// narrowest ordinary phone and the case the report was written from.
    Future<void> row(
      WidgetTester tester,
      List<String> labels, {
      IuxChipMark mark = IuxChipMark.checkmark,
      double textScale = 1,
    }) =>
        host(
          tester,
          SizedBox(
            width: 360,
            child: IuxChipGroup(
              label: 'Refresh interval',
              mark: mark,
              chips: <Widget>[
                for (final String label in labels)
                  IuxFilterChip(
                    label: label,
                    selected: label == labels.first,
                    onSelectionChanged: (bool _) {},
                  ),
              ],
            ),
          ),
          size: const Size(360, 800),
          textScale: textScale,
        );

    /// How many lines the chips occupy.
    int lineCount(WidgetTester tester, int count) {
      final List<double> tops = <double>[];
      for (int index = 0; index < count; index++) {
        final double top =
            tester.getRect(find.byType(IuxFilterChip).at(index)).top;
        if (!tops.any((double seen) => (seen - top).abs() < 0.5)) tops.add(top);
      }
      return tops.length;
    }

    double chipWidth(WidgetTester tester) =>
        tester.getSize(find.byType(IuxFilterChip).first).width;

    Finder checkGlyph() => find.descendant(
          of: find.byType(IuxFilterChip),
          matching: find.byIcon(Icons.check),
        );

    /// The outline a chip actually paints, read from what it was given.
    Border outlineOf(WidgetTester tester, int index) {
      final AnimatedContainer container = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(IuxFilterChip).at(index),
          matching: find.byType(AnimatedContainer),
        ),
      );
      return (container.decoration! as BoxDecoration).border! as Border;
    }

    testWidgets('the slot costs more than the label it sits beside',
        (WidgetTester tester) async {
      // The number that is not intuitive, and the reason three call sites in
      // a migrating application shortened their labels and gained nothing.
      await row(tester, <String>['5']);
      final double reserved = chipWidth(tester);

      await row(tester, <String>['5'], mark: IuxChipMark.outline);
      final double given = chipWidth(tester);

      await row(tester, <String>['15']);
      final double twoCharacters = chipWidth(tester);

      expect(
        reserved - given,
        greaterThan(twoCharacters - reserved),
        reason: 'one character measured $reserved with the slot and $given '
            'without it, while a second character adds only '
            '${twoCharacters - reserved} — so the slot is worth more than the '
            'text, and shortening a label is the wrong lever',
      );
    });

    testWidgets('four short chips stop needing a second line',
        (WidgetTester tester) async {
      const List<String> intervals = <String>['5', '15', '30', '60'];

      await row(tester, intervals);
      expect(lineCount(tester, 4), 2);
      final double reserved = tester.getSize(find.byType(IuxChipGroup)).height;

      await row(tester, intervals, mark: IuxChipMark.outline);
      expect(lineCount(tester, 4), 1);
      expect(
        tester.getSize(find.byType(IuxChipGroup)).height,
        lessThan(reserved),
      );
    });

    testWidgets('seven short chips drop a line', (WidgetTester tester) async {
      const List<String> days = <String>[
        'Lu',
        'Ma',
        'Me',
        'Je',
        'Ve',
        'Sa',
        'Di',
      ];

      await row(tester, days);
      expect(lineCount(tester, 7), 3);

      await row(tester, days, mark: IuxChipMark.outline);
      expect(lineCount(tester, 7), 2);
    });

    testWidgets('an outline group draws no glyph, chosen or not',
        (WidgetTester tester) async {
      await row(
        tester,
        <String>['5', '15'],
        mark: IuxChipMark.outline,
      );

      expect(checkGlyph(), findsNothing);
    });

    testWidgets('and still does not reflow when one is chosen',
        (WidgetTester tester) async {
      // The guarantee the reserved slot existed for. Without a glyph in either
      // state there is nothing left to appear, and the heavier outline is
      // already drawn inside the padding rather than added to it.
      await host(
        tester,
        IuxChipGroup(
          label: 'Refresh interval',
          mark: IuxChipMark.outline,
          chips: <Widget>[
            IuxFilterChip(
              label: '15',
              selected: false,
              onSelectionChanged: (bool _) {},
            ),
          ],
        ),
      );
      final double unselected = chipWidth(tester);

      await host(
        tester,
        IuxChipGroup(
          label: 'Refresh interval',
          mark: IuxChipMark.outline,
          chips: <Widget>[
            IuxFilterChip(
              label: '15',
              selected: true,
              onSelectionChanged: (bool _) {},
            ),
          ],
        ),
      );

      expect(chipWidth(tester), unselected);
    });

    testWidgets('the two signals it keeps are the two that were not the glyph',
        (WidgetTester tester) async {
      // The heavier outline survives a monochrome screen, and the announced
      // state survives having no screen at all. Dropping the glyph leaves both.
      await row(tester, <String>['5', '15'], mark: IuxChipMark.outline);

      expect(
        tester.getSemantics(find.bySemanticsLabel('5')),
        matchesSemantics(
          label: '5',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasFocusAction: true,
          hasTapAction: true,
        ),
      );

      final Border chosen = outlineOf(tester, 0);
      final Border unchosen = outlineOf(tester, 1);
      expect(chosen.top.width, greaterThan(unchosen.top.width));
    });

    testWidgets('every chip still meets the target floor',
        (WidgetTester tester) async {
      for (final IuxDensity density in IuxDensity.values) {
        await host(
          tester,
          SizedBox(
            width: 360,
            child: IuxChipGroup(
              label: 'Refresh interval',
              mark: IuxChipMark.outline,
              chips: <Widget>[
                for (final String label in <String>['5', '15', '30'])
                  IuxFilterChip(
                    label: label,
                    selected: false,
                    onSelectionChanged: (bool _) {},
                  ),
              ],
            ),
          ),
          configuration: IuxThemeConfiguration(
            profile: IuxAccessibilityProfile(density: density),
          ),
          size: const Size(360, 800),
        );

        for (int index = 0; index < 3; index++) {
          final Size size =
              tester.getSize(find.byType(IuxFilterChip).at(index));
          expect(
            size.shortestSide,
            greaterThanOrEqualTo(IuxTouchTarget.minimum),
            reason: '${density.name} left chip $index below the floor',
          );
        }
      }
    });

    testWidgets('a chip outside any group keeps the slot',
        (WidgetTester tester) async {
      // The default is the stronger of the two, so the absence of a group
      // resolves rather than guessing.
      await host(
        tester,
        IuxFilterChip(
          label: '15',
          selected: true,
          onSelectionChanged: (bool _) {},
        ),
      );

      expect(checkGlyph(), findsOneWidget);
    });

    testWidgets('the group decides for chips nested inside a caller layout',
        (WidgetTester tester) async {
      // Inherited rather than passed, so a row cannot be half one shape and
      // half the other. A chip the caller wrapped in its own widgets is still
      // in the group.
      await host(
        tester,
        IuxChipGroup(
          label: 'Refresh interval',
          mark: IuxChipMark.outline,
          chips: <Widget>[
            Padding(
              padding: EdgeInsets.zero,
              child: IuxFilterChip(
                label: '15',
                selected: true,
                onSelectionChanged: (bool _) {},
              ),
            ),
          ],
        ),
      );

      expect(checkGlyph(), findsNothing);
    });

    testWidgets('it still wraps rather than overflowing at 200% text',
        (WidgetTester tester) async {
      await row(
        tester,
        <String>['5', '15', '30', '60'],
        mark: IuxChipMark.outline,
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(IuxChipGroup)).width,
        lessThanOrEqualTo(360),
      );
    });
  });

  group('a read-only chip does not pretend to be a control', () {
    testWidgets('it is announced as a label, with no button flag',
        (WidgetTester tester) async {
      await host(tester, const IuxTagChip(label: 'Vegetarian'));
      expect(
        tester.getSemantics(find.bySemanticsLabel('Vegetarian')),
        matchesSemantics(label: 'Vegetarian'),
      );
    });

    testWidgets('it takes no focus, so it never becomes a dead keyboard stop',
        (WidgetTester tester) async {
      await host(tester, const IuxTagChip(label: 'Vegetarian'));
      expect(
        find.descendant(
          of: find.byType(IuxTagChip),
          matching: find.byType(Focus),
        ),
        findsNothing,
      );
    });

    testWidgets('it accepts no gesture at all', (WidgetTester tester) async {
      await host(tester, const IuxTagChip(label: 'Vegetarian'));
      expect(
        find.descendant(
          of: find.byType(IuxTagChip),
          matching: find.byType(GestureDetector),
        ),
        findsNothing,
      );
    });

    testWidgets('it claims no touch target it cannot honour',
        (WidgetTester tester) async {
      // Padding a tag out to 48 would make it look tappable. A row of things
      // that look tappable and are not is worse than a row that looks inert.
      final IuxChipTokens tag = await resolve(
        tester,
        const IuxThemeConfiguration(),
        (BuildContext context) =>
            IuxChipResolver.resolve(context, IuxChipState.readOnly),
      );
      expect(tag.minimumSize, 0);
      expect(tag.isInteractive, isFalse);
    });

    test('an unnamed tag is rejected', () {
      expect(() => IuxTagChip(label: ''), throwsAssertionError);
    });
  });

  group('adjacent interactive chips keep the minimum separation', () {
    Widget group() => IuxChipGroup(
          label: 'Filter by diet',
          chips: <Widget>[
            IuxFilterChip(
              label: 'Vegetarian',
              selected: false,
              onSelectionChanged: (bool _) {},
            ),
            IuxFilterChip(
              label: 'Vegan',
              selected: false,
              onSelectionChanged: (bool _) {},
            ),
          ],
        );

    testWidgets('two chips never touch', (WidgetTester tester) async {
      // Target size alone does not prevent mis-taps: a finger landing near the
      // seam between two touching targets has no margin for error.
      await host(tester, group());
      final Rect first = tester.getRect(find.byType(IuxFilterChip).first);
      final Rect second = tester.getRect(find.byType(IuxFilterChip).last);
      expect(
        second.left - first.right,
        greaterThanOrEqualTo(kIuxMinimumTargetSpacing),
      );
    });

    testWidgets('the set is named, and each chip stays reachable on its own',
        (WidgetTester tester) async {
      await host(tester, group());
      expect(find.bySemanticsLabel('Filter by diet'), findsOneWidget);
      expect(find.bySemanticsLabel('Vegetarian'), findsOneWidget);
      expect(find.bySemanticsLabel('Vegan'), findsOneWidget);
    });

    testWidgets('the group wraps rather than overflowing when text grows',
        (WidgetTester tester) async {
      await host(
        tester,
        group(),
        textScale: 2,
        size: const Size(320, 480),
      );
      expect(tester.takeException(), isNull);
    });

    test('an unnamed group is rejected', () {
      expect(
        () => IuxChipGroup(label: '', chips: const <Widget>[]),
        throwsAssertionError,
      );
    });
  });

  group('it holds up under the conditions users actually have', () {
    testWidgets('a 200% text scale on a small screen clips nothing',
        (WidgetTester tester) async {
      await host(
        tester,
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IuxStatusIndicator(status: IuxStatus.error('Payment declined')),
            IuxBadge.count(count: '3', label: '3 unread messages'),
            IuxBadge.marker(label: 'Unread messages'),
            IuxTagChip(label: 'Vegetarian'),
          ],
        ),
        textScale: 2,
        size: const Size(320, 480),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Payment declined'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('a badge grows with the text it sits beside',
        (WidgetTester tester) async {
      // A marker that stayed eight pixels while everything around it doubled is
      // a marker the person who enlarged their text can no longer see.
      final IuxBadgeTokens standard = await resolve(
        tester,
        const IuxThemeConfiguration(),
        IuxBadgeResolver.resolve,
      );
      final IuxBadgeTokens enlarged = await resolve(
        tester,
        const IuxThemeConfiguration(),
        IuxBadgeResolver.resolve,
        textScale: 2,
      );
      expect(enlarged.markerSize, greaterThan(standard.markerSize));
      expect(enlarged.minimumExtent, greaterThan(standard.minimumExtent));
    });

    testWidgets('a long status wraps rather than being truncated',
        (WidgetTester tester) async {
      const String long =
          'Payment declined because the card issuer refused the transaction';
      await host(
        tester,
        const IuxStatusIndicator(status: IuxStatus.error(long)),
        size: const Size(320, 640),
      );
      expect(tester.takeException(), isNull);
      final Text text = tester.widget<Text>(find.text(long));
      expect(text.maxLines, isNull);
      expect(text.overflow, isNot(TextOverflow.ellipsis));
    });

    testWidgets('a long chip label wraps too', (WidgetTester tester) async {
      const String long = 'Vegetarian and dairy free, prepared without nuts';
      await host(
        tester,
        IuxChipGroup(
          label: 'Filter by diet',
          chips: <Widget>[
            IuxFilterChip(
              label: long,
              selected: true,
              onSelectionChanged: (bool _) {},
            ),
          ],
        ),
        size: const Size(320, 640),
      );
      expect(tester.takeException(), isNull);
      final Text text = tester.widget<Text>(find.text(long));
      expect(text.maxLines, isNull);
      expect(text.overflow, isNot(TextOverflow.ellipsis));
    });

    testWidgets('it renders right-to-left', (WidgetTester tester) async {
      await host(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const IuxStatusIndicator(status: IuxStatus.error('فشل الدفع')),
            const IuxBadge.count(count: '٣', label: '٣ رسائل غير مقروءة'),
            IuxChipGroup(
              label: 'تصفية',
              chips: <Widget>[
                IuxFilterChip(
                  label: 'نباتي',
                  selected: true,
                  onSelectionChanged: (bool _) {},
                ),
              ],
            ),
          ],
        ),
        direction: TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('فشل الدفع'), findsOneWidget);
      expect(find.text('٣'), findsOneWidget);
    });

    testWidgets('it renders on every theme profile',
        (WidgetTester tester) async {
      for (final IuxThemeConfiguration configuration in _profiles) {
        for (final IuxStatusTone tone in IuxStatusTone.values) {
          await host(
            tester,
            IuxStatusIndicator(status: _statusFor(tone)),
            configuration: configuration,
          );
          expect(tester.takeException(), isNull,
              reason: '$configuration $tone');
        }
        await host(
          tester,
          IuxChipGroup(
            label: 'Filter by diet',
            chips: <Widget>[
              IuxFilterChip(
                label: 'Vegetarian',
                selected: true,
                onSelectionChanged: (bool _) {},
              ),
              const IuxTagChip(label: 'Vegan'),
              const IuxBadge.count(count: '3', label: '3 unread messages'),
            ],
          ),
          configuration: configuration,
        );
        expect(tester.takeException(), isNull, reason: '$configuration');
      }
    });

    testWidgets('a reduced-motion preference removes the travel, not the state',
        (WidgetTester tester) async {
      await host(
        tester,
        IuxFilterChip(
          label: 'Vegetarian',
          selected: true,
          onSelectionChanged: (bool _) {},
        ),
        configuration: const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(motion: IuxMotionPreference.none),
        ),
      );
      expect(
        tester
            .widget<AnimatedContainer>(
              find.descendant(
                of: find.byType(IuxFilterChip),
                matching: find.byType(AnimatedContainer),
              ),
            )
            .duration,
        Duration.zero,
      );
      expect(
        find.descendant(
          of: find.byType(IuxFilterChip),
          matching: find.byIcon(Icons.check),
        ),
        findsOneWidget,
        reason: 'the mark is the state; only the transition was motion',
      );
    });
  });

  group('colour reinforces the meaning, it never carries it', () {
    testWidgets('a status is readable in every tone, on every profile',
        (WidgetTester tester) async {
      for (final IuxThemeConfiguration configuration in _profiles) {
        final IuxSemanticColors colors = colorsOf(configuration);
        for (final IuxStatusTone tone in IuxStatusTone.values) {
          final IuxStatusTokens tokens = await resolve(
            tester,
            configuration,
            (BuildContext context) => IuxStatusResolver.resolve(context, tone),
          );
          final String where = '$configuration $tone';
          expect(
            ContrastMetric.ratio(tokens.textStyle.color!, tokens.background),
            greaterThanOrEqualTo(ContrastMetric.normalText),
            reason: 'label on its container, $where',
          );
          expect(
            ContrastMetric.ratio(tokens.glyphColor, tokens.background),
            greaterThanOrEqualTo(ContrastMetric.nonText),
            reason: 'glyph on its container, $where',
          );
          expect(
            ContrastMetric.ratio(tokens.border, colors.surface.base),
            greaterThanOrEqualTo(ContrastMetric.nonText),
            reason: 'the pill outline against the page, $where',
          );
        }
      }
    });

    testWidgets('a badge numeral is readable, and the badge is visible',
        (WidgetTester tester) async {
      for (final IuxThemeConfiguration configuration in _profiles) {
        final IuxSemanticColors colors = colorsOf(configuration);
        final IuxBadgeTokens tokens = await resolve(
          tester,
          configuration,
          IuxBadgeResolver.resolve,
        );
        expect(
          ContrastMetric.ratio(tokens.foreground, tokens.background),
          greaterThanOrEqualTo(ContrastMetric.normalText),
          reason: 'the numeral on the badge, $configuration',
        );
        expect(
          ContrastMetric.ratio(tokens.background, colors.surface.base),
          greaterThanOrEqualTo(ContrastMetric.nonText),
          reason: 'the badge against the page it marks, $configuration',
        );
      }
    });

    testWidgets('every chip state stays readable', (WidgetTester tester) async {
      for (final IuxThemeConfiguration configuration in _profiles) {
        for (final IuxChipState state in IuxChipState.values) {
          final IuxChipTokens tokens = await resolve(
            tester,
            configuration,
            (BuildContext context) => IuxChipResolver.resolve(context, state),
          );
          final String where = '$configuration $state';
          // IUX holds disabled content to 3:1 and everything else to 4.5:1.
          final double threshold = state == IuxChipState.disabled
              ? ContrastMetric.nonText
              : ContrastMetric.normalText;
          expect(
            ContrastMetric.ratio(tokens.foreground, tokens.background),
            greaterThanOrEqualTo(threshold),
            reason: 'the label on its container, $where',
          );
          expect(
            ContrastMetric.ratio(tokens.foreground, tokens.pressedBackground),
            greaterThanOrEqualTo(threshold),
            reason: 'the label while pressed, $where',
          );
        }
      }
    });

    testWidgets('an interactive chip is outlined well enough to be found',
        (WidgetTester tester) async {
      for (final IuxThemeConfiguration configuration in _profiles) {
        final IuxSemanticColors colors = colorsOf(configuration);
        for (final IuxChipState state in <IuxChipState>[
          IuxChipState.unselected,
          IuxChipState.selected,
        ]) {
          final IuxChipTokens tokens = await resolve(
            tester,
            configuration,
            (BuildContext context) => IuxChipResolver.resolve(context, state),
          );
          expect(
            ContrastMetric.ratio(tokens.border, colors.surface.base),
            greaterThanOrEqualTo(ContrastMetric.nonText),
            reason: 'the outline against the page, $configuration $state',
          );
        }
      }
    });

    testWidgets(
        'high contrast thickens the outlines rather than only shifting '
        'the hues', (WidgetTester tester) async {
      final IuxChipTokens standard = await resolve(
        tester,
        const IuxThemeConfiguration(),
        (BuildContext context) =>
            IuxChipResolver.resolve(context, IuxChipState.unselected),
      );
      final IuxChipTokens high = await resolve(
        tester,
        const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(contrast: IuxContrast.high),
        ),
        (BuildContext context) =>
            IuxChipResolver.resolve(context, IuxChipState.unselected),
      );
      expect(high.borderWidth, greaterThan(standard.borderWidth));
    });
  });

  group('these components carry no meaning of their own', () {
    testWidgets('nothing vibrates, and nothing is spoken uninvited',
        (WidgetTester tester) async {
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

      await host(
        tester,
        IuxFilterChip(
          label: 'Vegetarian',
          selected: false,
          onSelectionChanged: (bool _) {},
        ),
      );
      await tester.tap(find.byType(IuxFilterChip));
      await tester.pumpAndSettle();

      expect(
        platform.where((MethodCall c) => c.method.startsWith('HapticFeedback')),
        isEmpty,
        reason: 'feedback is emitted by the parent, never by the component',
      );
    });

    testWidgets('a disabled chip reports nothing when tapped',
        (WidgetTester tester) async {
      await host(
        tester,
        const IuxFilterChip(
          label: 'Vegetarian',
          selected: false,
          onSelectionChanged: null,
        ),
      );
      await tester.tap(find.byType(IuxFilterChip), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('a reading is compared, never judged', () {
    test('a reading must name what it measures, not repeat its own digits', () {
      // The four ways a value pill can be built into something that says
      // nothing, each made unconstructable rather than discouraged.
      expect(
        () => IuxValue.above('+2.1 °C',
            meaning: 'warmer', label: '+2.1 °C', accent: IuxValueAccent.one),
        throwsAssertionError,
        reason: 'a label that repeats the reading tells a screen-reader user a '
            'number with no referent, which is the failure this class exists '
            'to prevent',
      );
      expect(
        () => IuxValue.at('', meaning: 'as usual', label: 'at the normal'),
        throwsAssertionError,
      );
      expect(
        () => IuxValue.below('-47 mm',
            meaning: 'drier', label: '', accent: IuxValueAccent.three),
        throwsAssertionError,
      );
    });

    test('a deviation cannot be built without the word that reads it', () {
      // The rule the pilot's debrief states and this class enforces: "un écart
      // n'est jamais montré seul". A caller who has nothing to say about a
      // deviation has a number, not a reading — and a bare `-47 mm` in a
      // coloured capsule leaves the meaning to the hue, which is the one thing
      // this family refuses to do.
      expect(
        () => IuxValue.below('-47 mm',
            meaning: '',
            label: '47 millimetres below normal',
            accent: IuxValueAccent.three),
        throwsAssertionError,
        reason: 'an empty word draws a capsule that interprets nothing',
      );
      expect(
        () => IuxValue.below('-47 mm',
            meaning: '-47 mm',
            label: '47 millimetres below normal',
            accent: IuxValueAccent.three),
        throwsAssertionError,
        reason: 'a word that repeats the reading interprets nothing either',
      );
    });

    test('a direction is not a piece of news, and the two axes stay apart', () {
      // The whole point of the separate axis. A reading that sits above its
      // reference is not a warning, and a reading below it is not an error;
      // IuxStatusTone says "good or bad news" in its own dartdoc, and a dry
      // year is neither.
      expect(IuxValueDirection.values, hasLength(3));
      expect(
        IuxValueDirection.values.map((IuxValueDirection d) => d.name).toSet(),
        <String>{'above', 'at', 'below'},
      );
      expect(
        const IuxValue.above('+2.1 °C',
                meaning: 'warmer',
                label: 'above the normal',
                accent: IuxValueAccent.one)
            .direction,
        IuxValueDirection.above,
      );
    });

    test('a reading level with its reference has no hue to choose', () {
      // `at` is the one place the framework still decides a colour, and it
      // decides the absence of one. There is no accent parameter on the
      // constructor, so a neutral reading cannot be built into a coloured one.
      expect(
        const IuxValue.at('0 mm',
                meaning: 'as usual', label: 'at the 1991 to 2020 normal')
            .accent,
        isNull,
      );
      expect(IuxValueAccent.values, hasLength(4));
    });
  });

  group('the direction says which side, the caller says which hue', () {
    /// What a pill would paint for [value] under [configuration].
    Future<IuxValueTokens> tokensFor(
      WidgetTester tester,
      IuxValue value, [
      IuxThemeConfiguration configuration = const IuxThemeConfiguration(),
    ]) =>
        resolve(
          tester,
          configuration,
          (BuildContext context) => IuxValueResolver.resolve(context, value),
        );

    const IuxValue warmer = IuxValue.above('+1.5 °C',
        meaning: 'warmer',
        label: '1.5 degrees above the normal',
        accent: IuxValueAccent.one);
    const IuxValue wetter = IuxValue.above('+51 mm',
        meaning: 'wetter',
        label: '51 millimetres above the normal',
        accent: IuxValueAccent.two);
    const IuxValue colder = IuxValue.below('-1.8 °C',
        meaning: 'colder',
        label: '1.8 degrees below the normal',
        accent: IuxValueAccent.two);
    const IuxValue drier = IuxValue.below('-42 mm',
        meaning: 'drier',
        label: '42 millimetres below the normal',
        accent: IuxValueAccent.three);

    testWidgets('one side of a reference is not one hue',
        (WidgetTester tester) async {
      // The assumption ADR-0013 shipped and this record removes: that a
      // direction picks the colour. Rain above its normal is blue because it
      // is wetter, not because it is above — and rain below it is orange while
      // a temperature below it is blue. Both pairs are asserted, because
      // either one alone is satisfied by a mapping that merely renamed the
      // ends of the old axis.
      final IuxValueTokens above = await tokensFor(tester, wetter);
      final IuxValueTokens below = await tokensFor(tester, colder);
      expect(
        above.foreground,
        below.foreground,
        reason: 'two readings on opposite sides, drawn in one hue, because the '
            'caller said so',
      );

      final IuxValueTokens sameSide = await tokensFor(tester, warmer);
      expect(
        sameSide.foreground,
        isNot(above.foreground),
        reason: 'two readings on the same side, drawn in two hues, for the '
            'same reason',
      );
    });

    testWidgets('a level reading is neutral, and nothing else is',
        (WidgetTester tester) async {
      final IuxValueTokens level = await tokensFor(
        tester,
        const IuxValue.at('0 mm',
            meaning: 'as usual', label: 'at the 1991 to 2020 normal'),
      );
      for (final IuxValue coloured in <IuxValue>[
        warmer,
        wetter,
        colder,
        drier
      ]) {
        expect(
          (await tokensFor(tester, coloured)).foreground,
          isNot(level.foreground),
          reason: '"${coloured.meaning}" resolved the resting colour',
        );
      }
    });

    for (final IuxThemeConfiguration configuration in _profiles) {
      testWidgets('four accents resolve four readable appearances',
          (WidgetTester tester) async {
        final IuxSemanticColors colors = colorsOf(configuration);
        final Set<Color> foregrounds = <Color>{};

        for (final IuxValueAccent accent in IuxValueAccent.values) {
          final IuxValueTokens tokens = await tokensFor(
            tester,
            IuxValue.above('+1',
                meaning: 'more', label: 'more than', accent: accent),
            configuration,
          );
          foregrounds.add(tokens.foreground);

          expect(
            ContrastMetric.ratio(tokens.foreground, tokens.background),
            greaterThanOrEqualTo(ContrastMetric.normalText),
            reason: '$accent reading on its own capsule',
          );
          // The word sits on the page, not on the capsule, so it is held to
          // the page's floor. One colour, two grounds, two measurements — the
          // second is the one a tinted capsule makes easy to forget.
          expect(
            ContrastMetric.ratio(
                tokens.meaningStyle.color!, colors.surface.base),
            greaterThanOrEqualTo(ContrastMetric.normalText),
            reason: '$accent word on the page',
          );
        }

        expect(foregrounds, hasLength(IuxValueAccent.values.length));
      });
    }
  });

  group('a value pill says what it means without its colour', () {
    testWidgets('the reading and its word are drawn, the sentence announced',
        (WidgetTester tester) async {
      await host(
        tester,
        const IuxValueIndicator(
          value: IuxValue.above(
            '+2.1 °C',
            meaning: 'warmer',
            label: '2.1 degrees above the 1991 to 2020 normal',
            accent: IuxValueAccent.one,
          ),
        ),
      );

      expect(find.text('+2.1 °C'), findsOneWidget);
      expect(
        find.text('warmer'),
        findsOneWidget,
        reason: 'the word that interprets the deviation is drawn beside it',
      );
      final SemanticsNode node =
          tester.getSemantics(find.byType(IuxValueIndicator));
      expect(node.label, '2.1 degrees above the 1991 to 2020 normal');
      // The numeral is excluded, so the reader hears the sentence once rather
      // than "plus two point one degrees Celsius" and then the same fact.
      expect(find.bySemanticsLabel('+2.1 °C'), findsNothing);
    });

    testWidgets('nothing is drawn that a monochrome screen would lose',
        (WidgetTester tester) async {
      // The arrow is gone, and what replaced it is stronger than it was: a
      // word this class cannot be built without. An icon here would be a
      // second, weaker signal for something the text already says — and the
      // arrow was never in the semantic tree, where the word's sentence is.
      await host(
        tester,
        const IuxValueIndicator(
          value: IuxValue.below('-47 mm',
              meaning: 'drier',
              label: '47 millimetres below normal',
              accent: IuxValueAccent.three),
        ),
      );
      expect(
        find.descendant(
            of: find.byType(IuxValueIndicator), matching: find.byType(Icon)),
        findsNothing,
      );
      expect(find.text('drier'), findsOneWidget);
    });

    testWidgets('it is not a control', (WidgetTester tester) async {
      await host(
        tester,
        const IuxValueIndicator(
          value: IuxValue.below('-47 mm',
              meaning: 'drier',
              label: '47 millimetres below normal',
              accent: IuxValueAccent.three),
        ),
      );
      expect(
        tester.getSemantics(find.byType(IuxValueIndicator)),
        matchesSemantics(
          label: '47 millimetres below normal',
          textDirection: TextDirection.ltr,
        ),
      );
    });

    testWidgets('the capsule is a tint rather than an outlined object',
        (WidgetTester tester) async {
      // "Une petite capsule légèrement teintée, sans flèche et sans bordure
      // forte." A capsule that rings itself in its own hue reads as an alert
      // the moment it is repeated down a column, which is the only place this
      // component is ever used. ADR-0013 drew an outline and ADR-0015 removed
      // it: the capsule's extent is not information — the reading in it and
      // the word under it are, and both are text.
      //
      // The tint still has to be *visible*, or the reading has no container at
      // all, so the two halves are asserted together: no line, and a fill the
      // page does not already have.
      for (final IuxThemeConfiguration configuration in _profiles) {
        await host(
          tester,
          const IuxValueIndicator(
            value: IuxValue.above('+1.5 °C',
                meaning: 'warmer',
                label: 'above the normal',
                accent: IuxValueAccent.one),
          ),
          configuration: configuration,
        );
        final ShapeDecoration decoration = tester
            .widget<DecoratedBox>(find.descendant(
              of: find.byType(IuxValueIndicator),
              matching: find.byType(DecoratedBox),
            ))
            .decoration as ShapeDecoration;
        expect(
          (decoration.shape as StadiumBorder).side,
          BorderSide.none,
          reason: 'the capsule is outlined on $configuration',
        );
        expect(
          decoration.color,
          isNot(colorsOf(configuration).surface.base),
          reason: 'the capsule is invisible on $configuration',
        );
      }
    });

    testWidgets('the word is drawn under the reading and lighter than it',
        (WidgetTester tester) async {
      // The debrief's hierarchy, in the one place a component can hold it:
      // "le chiffre donne la mesure, l'écart lui donne son contexte, le texte
      // sa signification". A word set at the reading's own weight competes
      // with it, and a column of four rows then has eight things of equal
      // weight in it.
      //
      // Lighter and not smaller, and that is the type ramp's decision rather
      // than this component's: `label` and `supporting` are both 14 px,
      // because 14 is the floor below which IUX does not set text. Weight is
      // the whole of the hierarchy that is left, so it is the whole of what
      // is asserted.
      const IuxValue value = IuxValue.above('+2.1 °C',
          meaning: 'warmer',
          label: 'above the normal',
          accent: IuxValueAccent.one);
      final IuxValueTokens tokens = await resolve(
        tester,
        const IuxThemeConfiguration(),
        (BuildContext context) => IuxValueResolver.resolve(context, value),
      );
      expect(tokens.meaningStyle.fontSize, tokens.textStyle.fontSize);
      expect(
        tokens.meaningStyle.fontWeight!.value,
        lessThan(tokens.textStyle.fontWeight!.value),
      );

      await host(tester, const IuxValueIndicator(value: value));
      expect(
        tester.getTopLeft(find.text('warmer')).dy,
        greaterThan(tester.getBottomLeft(find.text('+2.1 °C')).dy),
        reason: 'the word sits under the capsule, not inside it',
      );
    });
  });

  group('a value pill survives the conditions its readings arrive in', () {
    testWidgets('it wraps rather than clips at 200% text',
        (WidgetTester tester) async {
      await host(
        tester,
        const SizedBox(
          width: 120,
          child: IuxValueIndicator(
            value: IuxValue.above(
              '+2.1 °C compared with the normal',
              meaning: 'warmer than the thirty year normal',
              label: 'well above the normal',
              accent: IuxValueAccent.one,
            ),
          ),
        ),
        textScale: 2,
        // Tall, because the subject is: eleven wrapped lines of reading and
        // nine of word is 812 px at 200%, and a host that clipped it would be
        // testing its own harness rather than this component.
        size: const Size(400, 2000),
      );
      expect(tester.takeException(), isNull);
      for (final String drawn in <String>[
        '+2.1 °C compared with the normal',
        'warmer than the thirty year normal',
      ]) {
        final Text text = tester.widget<Text>(find.text(drawn));
        expect(text.maxLines, isNull,
            reason: 'no line limit, at any text scale');
        expect(text.overflow, isNot(TextOverflow.ellipsis));
      }
    });

    testWidgets('it renders in RTL and on every theme profile',
        (WidgetTester tester) async {
      for (final IuxThemeConfiguration configuration in _profiles) {
        for (final IuxValueDirection direction in IuxValueDirection.values) {
          await host(
            tester,
            IuxValueIndicator(
              value: switch (direction) {
                IuxValueDirection.above => const IuxValue.above('٣+',
                    meaning: 'أكثر',
                    label: 'فوق المعدل',
                    accent: IuxValueAccent.one),
                IuxValueDirection.at => const IuxValue.at('٠',
                    meaning: 'كالمعتاد', label: 'عند المعدل'),
                IuxValueDirection.below => const IuxValue.below('٣-',
                    meaning: 'أقل',
                    label: 'دون المعدل',
                    accent: IuxValueAccent.two),
              },
            ),
            configuration: configuration,
            direction: TextDirection.rtl,
          );
          expect(tester.takeException(), isNull);

          // Reading order, not left-to-right order. The word sits under the
          // capsule and starts where reading starts, so in a right-to-left
          // interface both start on the right — a Column that hard-coded its
          // cross-axis alignment would render without an exception and put
          // the word under the wrong end of the capsule, which no
          // `takeException` can see.
          expect(
            tester.getTopRight(find.byType(IuxValueIndicator)).dx -
                tester
                    .getTopRight(find.text(direction == IuxValueDirection.at
                        ? 'كالمعتاد'
                        : direction == IuxValueDirection.above
                            ? 'أكثر'
                            : 'أقل'))
                    .dx,
            lessThan(1),
            reason: 'the word starts where reading starts',
          );
        }
      }
    });
  });
}

IuxStatus _statusFor(IuxStatusTone tone) => switch (tone) {
      IuxStatusTone.neutral => const IuxStatus.neutral('Offline'),
      IuxStatusTone.success => const IuxStatus.success('Delivered'),
      IuxStatusTone.warning => const IuxStatus.warning('Expires today'),
      IuxStatusTone.error => const IuxStatus.error('Payment declined'),
    };
