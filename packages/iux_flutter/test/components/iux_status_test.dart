import 'package:flutter/material.dart';
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
}

IuxStatus _statusFor(IuxStatusTone tone) => switch (tone) {
      IuxStatusTone.neutral => const IuxStatus.neutral('Offline'),
      IuxStatusTone.success => const IuxStatus.success('Delivered'),
      IuxStatusTone.warning => const IuxStatus.warning('Expires today'),
      IuxStatusTone.error => const IuxStatus.error('Payment declined'),
    };
