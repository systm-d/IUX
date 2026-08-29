import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';
import 'package:iux_flutter/src/accessibility/iux_category_glyphs.dart';

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

IuxThemeConfiguration _withMotion(IuxMotionPreference motion) =>
    IuxThemeConfiguration(profile: IuxAccessibilityProfile(motion: motion));

/// The role colours a configuration resolves for a category.
IuxFeedbackRoleColors _roleColors(
  IuxThemeConfiguration configuration,
  IuxFeedbackCategory category,
) {
  final IuxFeedbackColorSet set = IuxTheme.fromConfiguration(configuration)
      .extension<IuxSemanticColors>()!
      .feedback;
  return switch (category) {
    IuxFeedbackCategory.info => set.info,
    IuxFeedbackCategory.success => set.success,
    IuxFeedbackCategory.warning => set.warning,
    IuxFeedbackCategory.error => set.error,
  };
}

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
          // Keyed by configuration so switching profiles swaps the theme
          // outright. MaterialApp otherwise cross-fades between two themes,
          // and every colour read during that window belongs to neither.
          key: ValueKey<IuxThemeConfiguration>(configuration),
          theme: IuxTheme.fromConfiguration(configuration),
          home: Directionality(
            textDirection: direction,
            // Scrollable rather than centred: a message is a paragraph, and at
            // 200% text on a small phone a paragraph is taller than the phone.
            // A host that overflowed would be testing the host.
            child: Scaffold(body: SingleChildScrollView(child: child)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The tokens a message would resolve under [configuration].
  Future<IuxInlineFeedbackTokens> tokensFor(
    WidgetTester tester,
    IuxThemeConfiguration configuration,
    IuxFeedbackCategory category, {
    double textScale = 1,
  }) async {
    late IuxInlineFeedbackTokens resolved;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: MaterialApp(
          key: ValueKey<IuxThemeConfiguration>(configuration),
          theme: IuxTheme.fromConfiguration(configuration),
          home: Builder(
            builder: (BuildContext context) {
              resolved = IuxInlineFeedbackResolver.resolve(context, category);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return resolved;
  }

  Finder tapTargetAround(Finder child) =>
      find.ancestor(of: child, matching: find.byType(IuxTapTarget));

  group('a category is carried by shape and wording, never by a hue alone', () {
    testWidgets('every category shows a glyph', (WidgetTester tester) async {
      for (final IuxFeedbackCategory category in IuxFeedbackCategory.values) {
        await host(
          tester,
          IuxAlert(
            category: category,
            categoryLabel: category.name,
            message: 'A sentence about ${category.name}.',
          ),
        );
        expect(find.byType(Icon), findsOneWidget, reason: '${category.name}');
      }
    });

    testWidgets('no two categories share a glyph', (WidgetTester tester) async {
      final Set<IconData> glyphs = <IconData>{};
      for (final IuxFeedbackCategory category in IuxFeedbackCategory.values) {
        final IuxInlineFeedbackTokens tokens = await tokensFor(
          tester,
          const IuxThemeConfiguration(),
          category,
        );
        glyphs.add(tokens.glyph);
      }
      expect(
        glyphs,
        hasLength(IuxFeedbackCategory.values.length),
        reason: 'two categories drawn with one shape are one category to a '
            'user who cannot separate the tints',
      );
    });

    testWidgets('the glyph is painted from the role own icon slot',
        (WidgetTester tester) async {
      // IUX-006 put an icon colour in the role contract precisely so the
      // category survives a reader who cannot distinguish hues. A component
      // that reached for the content colour instead would quietly drop it.
      for (final IuxThemeConfiguration configuration in _profiles) {
        for (final IuxFeedbackCategory category in IuxFeedbackCategory.values) {
          final IuxInlineFeedbackTokens tokens =
              await tokensFor(tester, configuration, category);
          expect(
            tokens.icon,
            _roleColors(configuration, category).icon,
            reason: '${category.name} on $configuration',
          );
        }
      }
    });

    testWidgets('the category reaches a screen reader as a word',
        (WidgetTester tester) async {
      // The glyph and the tint exist for the users who can see them. Neither
      // reaches a screen reader, so the localised word is the whole of what a
      // blind user gets of the category.
      await host(
        tester,
        const IuxAlert(
          category: IuxFeedbackCategory.error,
          categoryLabel: 'Error',
          message: 'We could not charge your card.',
        ),
      );
      expect(
        find.bySemanticsLabel('Error. We could not charge your card.'),
        findsOneWidget,
      );
    });
  });

  group('the message is announced once, in place', () {
    testWidgets('the whole message is one live region',
        (WidgetTester tester) async {
      await host(
        tester,
        const IuxAlert(
          category: IuxFeedbackCategory.success,
          categoryLabel: 'Success',
          message: 'Your changes are saved.',
        ),
      );
      final SemanticsNode node = tester.getSemantics(
        find.bySemanticsLabel('Success. Your changes are saved.'),
      );
      expect(node.flagsCollection.isLiveRegion, isTrue);
    });

    testWidgets('the visible text is not a second stop in the reading order',
        (WidgetTester tester) async {
      // The words are already in the live region label. Left in the tree as
      // well, they would be read a second time and the user would swipe
      // through the same sentence twice.
      await host(
        tester,
        const IuxAlert(
          category: IuxFeedbackCategory.info,
          categoryLabel: 'Information',
          message: 'Delivery takes three days.',
        ),
      );
      expect(find.text('Delivery takes three days.'), findsOneWidget);
      expect(find.bySemanticsLabel('Delivery takes three days.'), findsNothing);
    });

    testWidgets('a title is spoken before the message, as one sentence',
        (WidgetTester tester) async {
      await host(
        tester,
        const IuxAlert(
          category: IuxFeedbackCategory.warning,
          categoryLabel: 'Warning',
          title: 'Storage almost full',
          message: 'New photos will not be backed up.',
        ),
      );
      expect(
        find.bySemanticsLabel(
          'Warning. Storage almost full. New photos will not be backed up.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('it needs no feedback scope, because it emits nothing',
        (WidgetTester tester) async {
      // A message the user can see has no business interrupting a screen
      // reader, and nothing here vibrates. IuxFeedbackScope.of throws when it
      // is missing, so rendering without one is proof that nothing is emitted.
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
        IuxAlert(
          category: IuxFeedbackCategory.error,
          categoryLabel: 'Error',
          message: 'The upload failed.',
          action: IuxNamedAction(
            label: 'Try again',
            onActivate: () {},
          ),
        ),
      );
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        platform.where((MethodCall c) => c.method.startsWith('HapticFeedback')),
        isEmpty,
      );
    });
  });

  group('dismissal is named, reachable, and owned by the parent', () {
    testWidgets('no dismissal means no control', (WidgetTester tester) async {
      await host(
        tester,
        const IuxAlert(
          category: IuxFeedbackCategory.error,
          categoryLabel: 'Error',
          message: 'This form cannot be submitted yet.',
        ),
      );
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('the dismiss control says what disappears',
        (WidgetTester tester) async {
      await host(
        tester,
        IuxAlert(
          category: IuxFeedbackCategory.success,
          categoryLabel: 'Success',
          message: 'Your changes are saved.',
          dismissal: IuxInlineFeedbackDismissal(
            label: 'Dismiss the saved notice',
            onDismissed: () {},
          ),
        ),
      );
      expect(
        find.bySemanticsLabel('Dismiss the saved notice'),
        findsOneWidget,
        reason: 'an unnamed close control reaches a screen reader as "button"',
      );
    });

    testWidgets('the dismiss control meets the touch target floor',
        (WidgetTester tester) async {
      await host(
        tester,
        IuxAlert(
          category: IuxFeedbackCategory.info,
          categoryLabel: 'Information',
          message: 'Delivery takes three days.',
          dismissal: IuxInlineFeedbackDismissal(
            label: 'Dismiss the delivery notice',
            onDismissed: () {},
          ),
        ),
      );
      final Size size = tester.getSize(
        tapTargetAround(find.byIcon(Icons.close)),
      );
      expect(size.width, greaterThanOrEqualTo(IuxTouchTarget.minimum));
      expect(size.height, greaterThanOrEqualTo(IuxTouchTarget.minimum));
    });

    testWidgets('dismissing reports to the parent and removes nothing itself',
        (WidgetTester tester) async {
      // The parent owns whether the message exists. A component that hid
      // itself would hide a condition that may still be true.
      int dismissed = 0;
      await host(
        tester,
        IuxAlert(
          category: IuxFeedbackCategory.success,
          categoryLabel: 'Success',
          message: 'Your changes are saved.',
          dismissal: IuxInlineFeedbackDismissal(
            label: 'Dismiss the saved notice',
            onDismissed: () => dismissed++,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(dismissed, 1);
      expect(find.text('Your changes are saved.'), findsOneWidget);
    });

    testWidgets('an error may not offer dismissal as its only control',
        (WidgetTester tester) async {
      // Closing it erases the one explanation of why the screen is broken,
      // while the failure is still there.
      expect(
        () => IuxAlert(
          category: IuxFeedbackCategory.error,
          categoryLabel: 'Error',
          message: 'We could not charge your card.',
          dismissal: IuxInlineFeedbackDismissal(
            label: 'Dismiss',
            onDismissed: () {},
          ),
        ),
        throwsAssertionError,
      );
      expect(
        () => IuxBanner(
          category: IuxFeedbackCategory.error,
          categoryLabel: 'Error',
          message: 'Your session expired.',
          dismissal: IuxInlineFeedbackDismissal(
            label: 'Dismiss',
            onDismissed: () {},
          ),
        ),
        throwsAssertionError,
      );
    });

    testWidgets('an error with a way out may be dismissed',
        (WidgetTester tester) async {
      await host(
        tester,
        IuxAlert(
          category: IuxFeedbackCategory.error,
          categoryLabel: 'Error',
          message: 'We could not charge your card.',
          action: IuxNamedAction(
            label: 'Use another card',
            onActivate: () {},
          ),
          dismissal: IuxInlineFeedbackDismissal(
            label: 'Dismiss the payment error',
            onDismissed: () {},
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.text('Use another card'), findsOneWidget);
    });

    testWidgets('the other categories may be dismissed without an action',
        (WidgetTester tester) async {
      for (final IuxFeedbackCategory category in <IuxFeedbackCategory>[
        IuxFeedbackCategory.info,
        IuxFeedbackCategory.success,
        IuxFeedbackCategory.warning,
      ]) {
        await host(
          tester,
          IuxAlert(
            category: category,
            categoryLabel: category.name,
            message: 'A sentence about ${category.name}.',
            dismissal: IuxInlineFeedbackDismissal(
              label: 'Dismiss the ${category.name} notice',
              onDismissed: () {},
            ),
          ),
        );
        expect(tester.takeException(), isNull, reason: category.name);

        // DebugOverflowIndicatorMixin reports an overflow once per render
        // object lifetime, so without this every case after the first would
        // pass whatever it laid out (IUX-QA-VACUOUS-003).
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });
  });

  group('a failure names the way out', () {
    testWidgets('the recovery control is activatable',
        (WidgetTester tester) async {
      int retried = 0;
      await host(
        tester,
        IuxAlert(
          category: IuxFeedbackCategory.error,
          categoryLabel: 'Error',
          message: 'The upload failed because you went offline.',
          action: IuxNamedAction(
            label: 'Try again',
            onActivate: () => retried++,
          ),
        ),
      );

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(retried, 1);
      expect(
        find.text('The upload failed because you went offline.'),
        findsOneWidget,
        reason: 'the message is the parent\'s to replace, not the action\'s',
      );
    });

    testWidgets('the recovery control meets the touch target floor',
        (WidgetTester tester) async {
      await host(
        tester,
        IuxAlert(
          category: IuxFeedbackCategory.error,
          categoryLabel: 'Error',
          message: 'The upload failed.',
          action: IuxNamedAction(
            label: 'Try again',
            onActivate: () {},
          ),
        ),
      );
      final Size size = tester.getSize(tapTargetAround(find.text('Try again')));
      expect(size.width, greaterThanOrEqualTo(IuxTouchTarget.minimum));
      expect(size.height, greaterThanOrEqualTo(IuxTouchTarget.minimum));
    });

    testWidgets('a terse label can announce a longer one',
        (WidgetTester tester) async {
      // Three failures on one screen produce three controls called "Retry",
      // and a user moving by control cannot tell which is which.
      await host(
        tester,
        IuxAlert(
          category: IuxFeedbackCategory.error,
          categoryLabel: 'Error',
          message: 'The upload failed.',
          action: IuxNamedAction(
            label: 'Retry',
            semanticLabel: 'Retry uploading the photographs',
            onActivate: () {},
          ),
        ),
      );
      expect(find.text('Retry'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Retry uploading the photographs'),
        findsOneWidget,
      );
    });

    testWidgets('the control is reachable and activatable from a keyboard',
        (WidgetTester tester) async {
      int retried = 0;
      await host(
        tester,
        IuxAlert(
          category: IuxFeedbackCategory.error,
          categoryLabel: 'Error',
          message: 'The upload failed.',
          action: IuxNamedAction(
            label: 'Try again',
            onActivate: () => retried++,
          ),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(retried, 1);
    });

    testWidgets('every control in the message is reachable from a keyboard',
        (WidgetTester tester) async {
      // The order is the one the layout produces, not one imposed on top of
      // it. Forcing the recovery control ahead of the dismiss control would
      // give the keyboard a different sequence from the screen reader, which
      // reads geometrically — and two orders for one message is worse for
      // someone using both than either order is on its own.
      int retried = 0;
      int dismissed = 0;
      await host(
        tester,
        IuxAlert(
          category: IuxFeedbackCategory.error,
          categoryLabel: 'Error',
          message: 'The upload failed.',
          action: IuxNamedAction(
            label: 'Try again',
            onActivate: () => retried++,
          ),
          dismissal: IuxInlineFeedbackDismissal(
            label: 'Dismiss the upload error',
            onDismissed: () => dismissed++,
          ),
        ),
      );

      for (int stop = 0; stop < 2; stop++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
      }

      expect(retried, 1, reason: 'the recovery control was never reached');
      expect(dismissed, 1, reason: 'the dismiss control was never reached');
    });
  });

  group('it holds up under the conditions users actually have', () {
    testWidgets('a long message wraps rather than being truncated',
        (WidgetTester tester) async {
      const String long = 'We could not charge the card ending in 4242 '
          'because your bank declined the payment. Try another card, or '
          'contact your bank and try again.';
      await host(
        tester,
        const IuxAlert(
          category: IuxFeedbackCategory.error,
          categoryLabel: 'Error',
          message: long,
        ),
        size: const Size(320, 640),
      );

      expect(tester.takeException(), isNull);
      final Text text = tester.widget<Text>(find.text(long));
      expect(text.maxLines, isNull);
      expect(text.overflow, isNot(TextOverflow.ellipsis));
    });

    testWidgets('a 200% text scale on a small screen clips nothing',
        (WidgetTester tester) async {
      await host(
        tester,
        IuxAlert(
          category: IuxFeedbackCategory.error,
          categoryLabel: 'Error',
          message: 'We could not charge your card. Try another one.',
          action: IuxNamedAction(
            label: 'Use another card',
            onActivate: () {},
          ),
          dismissal: IuxInlineFeedbackDismissal(
            label: 'Dismiss the payment error',
            onDismissed: () {},
          ),
        ),
        textScale: 2,
        size: const Size(320, 480),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Use another card'), findsOneWidget);
    });

    testWidgets('and does not push the dismiss control off the screen',
        (WidgetTester tester) async {
      await host(
        tester,
        IuxAlert(
          category: IuxFeedbackCategory.warning,
          categoryLabel: 'Warning',
          message: 'Your subscription ends on Friday and will not renew '
              'automatically because your card expired.',
          dismissal: IuxInlineFeedbackDismissal(
            label: 'Dismiss the subscription notice',
            onDismissed: () {},
          ),
        ),
        textScale: 2,
        size: const Size(320, 480),
      );

      final Rect target = tester.getRect(
        tapTargetAround(find.byIcon(Icons.close)),
      );
      expect(target.left, greaterThanOrEqualTo(0));
      expect(target.right, lessThanOrEqualTo(320));
    });

    testWidgets('it renders right-to-left', (WidgetTester tester) async {
      await host(
        tester,
        IuxAlert(
          category: IuxFeedbackCategory.error,
          categoryLabel: 'خطأ',
          message: 'تعذر إتمام الدفع.',
          action: IuxNamedAction(
            label: 'حاول مرة أخرى',
            onActivate: () {},
          ),
          dismissal: IuxInlineFeedbackDismissal(
            label: 'إغلاق',
            onDismissed: () {},
          ),
        ),
        direction: TextDirection.rtl,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('حاول مرة أخرى'), findsOneWidget);
    });

    testWidgets(
        'the glyph leads and the dismiss control trails, in reading '
        'order', (WidgetTester tester) async {
      // Mirrored rather than mirrored-by-hand: a Row lays out in reading
      // order, so an Arabic interface gets the glyph on the right without the
      // widget knowing which language it is in.
      for (final TextDirection direction in TextDirection.values) {
        await host(
          tester,
          IuxAlert(
            category: IuxFeedbackCategory.info,
            categoryLabel: 'Information',
            message: 'A short note.',
            dismissal: IuxInlineFeedbackDismissal(
              label: 'Dismiss',
              onDismissed: () {},
            ),
          ),
          direction: direction,
        );

        final double glyph =
            tester.getCenter(find.byIcon(IuxCategoryGlyphs.info)).dx;
        final double close = tester.getCenter(find.byIcon(Icons.close)).dx;
        expect(
          direction == TextDirection.ltr ? glyph < close : glyph > close,
          isTrue,
          reason: 'failed for $direction',
        );
      }
    });

    testWidgets('it renders on every theme profile',
        (WidgetTester tester) async {
      for (final IuxThemeConfiguration configuration in _profiles) {
        for (final IuxFeedbackCategory category in IuxFeedbackCategory.values) {
          await host(
            tester,
            IuxAlert(
              category: category,
              categoryLabel: category.name,
              message: 'A sentence about ${category.name}.',
              action: IuxNamedAction(
                label: 'Act',
                onActivate: () {},
              ),
            ),
            configuration: configuration,
          );
          expect(tester.takeException(), isNull, reason: '$configuration');
          expect(
              find.text('A sentence about ${category.name}.'), findsOneWidget);

          // DebugOverflowIndicatorMixin reports an overflow once per render
          // object lifetime, so without a teardown between cases every case
          // after the first would pass whatever it laid out
          // (IUX-QA-VACUOUS-003).
          await tester.pumpWidget(const SizedBox.shrink());

          await host(
            tester,
            IuxBanner(
              category: category,
              categoryLabel: category.name,
              message: 'A condition about ${category.name}.',
            ),
            configuration: configuration,
          );
          expect(tester.takeException(), isNull, reason: '$configuration');

          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
    });
  });

  group('motion explains a change and never carries one', () {
    testWidgets(
        'a reduced preference shortens the transition without removing '
        'it', (WidgetTester tester) async {
      await host(
        tester,
        const IuxAlert(
          category: IuxFeedbackCategory.warning,
          categoryLabel: 'Warning',
          message: 'Your card expires next month.',
        ),
        configuration: _withMotion(IuxMotionPreference.standard),
      );
      final Duration full = tester
          .widget<AnimatedContainer>(find.byType(AnimatedContainer))
          .duration;

      await host(
        tester,
        const IuxAlert(
          category: IuxFeedbackCategory.warning,
          categoryLabel: 'Warning',
          message: 'Your card expires next month.',
        ),
        configuration: _withMotion(IuxMotionPreference.reduced),
      );
      final Duration reduced = tester
          .widget<AnimatedContainer>(find.byType(AnimatedContainer))
          .duration;

      expect(reduced, greaterThan(Duration.zero));
      expect(reduced, lessThan(full));
    });

    testWidgets('no motion removes the transition and keeps the message',
        (WidgetTester tester) async {
      // Nothing is lost: the glyph and the words changed with the colour, and
      // they were never animated in the first place.
      await host(
        tester,
        const IuxAlert(
          category: IuxFeedbackCategory.error,
          categoryLabel: 'Error',
          message: 'We could not charge your card.',
        ),
        configuration: _withMotion(IuxMotionPreference.none),
      );

      expect(
        tester
            .widget<AnimatedContainer>(find.byType(AnimatedContainer))
            .duration,
        Duration.zero,
      );
      expect(find.text('We could not charge your card.'), findsOneWidget);
      expect(find.byIcon(IuxCategoryGlyphs.error), findsOneWidget);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('changing category changes the glyph, not only the colour',
        (WidgetTester tester) async {
      await host(
        tester,
        const IuxAlert(
          category: IuxFeedbackCategory.warning,
          categoryLabel: 'Warning',
          message: 'The connection is unstable.',
        ),
      );
      expect(find.byIcon(IuxCategoryGlyphs.warning), findsOneWidget);

      await host(
        tester,
        const IuxAlert(
          category: IuxFeedbackCategory.error,
          categoryLabel: 'Error',
          message: 'The connection was lost.',
        ),
      );
      expect(find.byIcon(IuxCategoryGlyphs.error), findsOneWidget);
      expect(find.byIcon(IuxCategoryGlyphs.warning), findsNothing);
    });
  });

  group('every colour is measured against the surface it actually sits on', () {
    testWidgets('the message text is readable on its own surface',
        (WidgetTester tester) async {
      // WCAG 2.2 SC 1.4.3. The point of resolving every colour from one
      // feedback role: a component reaching for a general content colour
      // would land on a pair nobody measured against this tint.
      for (final IuxThemeConfiguration configuration in _profiles) {
        for (final IuxFeedbackCategory category in IuxFeedbackCategory.values) {
          final IuxInlineFeedbackTokens tokens =
              await tokensFor(tester, configuration, category);
          for (final TextStyle style in <TextStyle>[
            tokens.titleStyle,
            tokens.messageStyle,
            tokens.actionStyle,
          ]) {
            expect(
              ContrastMetric.ratio(style.color!, tokens.surface),
              greaterThanOrEqualTo(ContrastMetric.normalText),
              reason: '${category.name} on $configuration',
            );
          }
        }
      }
    });

    testWidgets('the glyph is distinguishable on its own surface',
        (WidgetTester tester) async {
      // WCAG 2.2 SC 1.4.11: the glyph is a meaningful graphic, not decoration.
      for (final IuxThemeConfiguration configuration in _profiles) {
        for (final IuxFeedbackCategory category in IuxFeedbackCategory.values) {
          final IuxInlineFeedbackTokens tokens =
              await tokensFor(tester, configuration, category);
          expect(
            ContrastMetric.ratio(tokens.icon, tokens.surface),
            greaterThanOrEqualTo(ContrastMetric.nonText),
            reason: '${category.name} on $configuration',
          );
        }
      }
    });

    testWidgets('the outline separates the message from the page behind it',
        (WidgetTester tester) async {
      for (final IuxThemeConfiguration configuration in _profiles) {
        final Color page = IuxTheme.fromConfiguration(configuration)
            .extension<IuxSemanticColors>()!
            .surface
            .base;
        for (final IuxFeedbackCategory category in IuxFeedbackCategory.values) {
          final IuxInlineFeedbackTokens tokens =
              await tokensFor(tester, configuration, category);
          expect(
            ContrastMetric.ratio(tokens.border, page),
            greaterThanOrEqualTo(ContrastMetric.nonText),
            reason: '${category.name} on $configuration',
          );
        }
      }
    });

    testWidgets('high contrast thickens the outline rather than recolouring it',
        (WidgetTester tester) async {
      final IuxInlineFeedbackTokens standard = await tokensFor(
        tester,
        const IuxThemeConfiguration(),
        IuxFeedbackCategory.error,
      );
      final IuxInlineFeedbackTokens high = await tokensFor(
        tester,
        const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(contrast: IuxContrast.high),
        ),
        IuxFeedbackCategory.error,
      );
      expect(high.borderWidth, greaterThan(standard.borderWidth));
    });

    testWidgets('enlarged text enlarges the glyph with it',
        (WidgetTester tester) async {
      // Someone who doubled their text has said that 24 logical pixels are not
      // enough, and this glyph is one of the three carriers of the category.
      final IuxInlineFeedbackTokens standard = await tokensFor(
        tester,
        const IuxThemeConfiguration(),
        IuxFeedbackCategory.info,
      );
      final IuxInlineFeedbackTokens enlarged = await tokensFor(
        tester,
        const IuxThemeConfiguration(),
        IuxFeedbackCategory.info,
        textScale: 2,
      );
      expect(enlarged.iconSize, greaterThan(standard.iconSize));
    });
  });

  group('a banner is anchored to its region, an alert floats inside it', () {
    testWidgets('an alert is outlined and rounded',
        (WidgetTester tester) async {
      await host(
        tester,
        const IuxAlert(
          category: IuxFeedbackCategory.info,
          categoryLabel: 'Information',
          message: 'Delivery takes three days.',
        ),
      );
      final BoxDecoration decoration = tester
          .widget<AnimatedContainer>(find.byType(AnimatedContainer))
          .decoration! as BoxDecoration;

      expect(decoration.borderRadius, isNotNull);
      expect(decoration.border!.isUniform, isTrue);
    });

    testWidgets('a banner takes the region edges and rules above and below',
        (WidgetTester tester) async {
      // Its side edges are the region's own, so an outline there would draw a
      // line down the screen.
      await host(
        tester,
        const IuxBanner(
          category: IuxFeedbackCategory.warning,
          categoryLabel: 'Warning',
          message: 'You are working offline.',
        ),
      );
      final BoxDecoration decoration = tester
          .widget<AnimatedContainer>(find.byType(AnimatedContainer))
          .decoration! as BoxDecoration;

      expect(decoration.borderRadius, isNull);
      expect((decoration.border! as Border).left, BorderSide.none);
      expect((decoration.border! as Border).top, isNot(BorderSide.none));
    });

    testWidgets('both carry the same content and the same semantics',
        (WidgetTester tester) async {
      for (final Widget widget in <Widget>[
        const IuxAlert(
          category: IuxFeedbackCategory.error,
          categoryLabel: 'Error',
          message: 'Your session expired.',
        ),
        const IuxBanner(
          category: IuxFeedbackCategory.error,
          categoryLabel: 'Error',
          message: 'Your session expired.',
        ),
      ]) {
        await host(tester, widget);
        expect(
          find.bySemanticsLabel('Error. Your session expired.'),
          findsOneWidget,
          reason: '${widget.runtimeType}',
        );
        expect(find.byIcon(IuxCategoryGlyphs.error), findsOneWidget);
      }
    });
  });

  group('an incoherent configuration fails loudly', () {
    test('a message with no words is rejected', () {
      expect(
        () => IuxAlert(
          category: IuxFeedbackCategory.info,
          categoryLabel: 'Information',
          message: '',
        ),
        throwsAssertionError,
      );
      expect(
        () => IuxBanner(
          category: IuxFeedbackCategory.info,
          categoryLabel: 'Information',
          message: '',
        ),
        throwsAssertionError,
      );
    });

    test('a category with no localised word is rejected', () {
      expect(
        () => IuxAlert(
          category: IuxFeedbackCategory.error,
          categoryLabel: '',
          message: 'It failed.',
        ),
        throwsAssertionError,
      );
    });

    test('an empty title is rejected rather than rendered as a blank line', () {
      expect(
        () => IuxAlert(
          category: IuxFeedbackCategory.info,
          categoryLabel: 'Information',
          title: '',
          message: 'It happened.',
        ),
        throwsAssertionError,
      );
    });

    test('an unlabelled recovery control is rejected', () {
      expect(
        () => IuxNamedAction(label: '', onActivate: () {}),
        throwsAssertionError,
      );
      expect(
        () => IuxNamedAction(
          label: 'Retry',
          semanticLabel: '',
          onActivate: () {},
        ),
        throwsAssertionError,
      );
    });

    test('an unnamed dismiss control is rejected', () {
      expect(
        () => IuxInlineFeedbackDismissal(label: '', onDismissed: () {}),
        throwsAssertionError,
      );
    });
  });
}
