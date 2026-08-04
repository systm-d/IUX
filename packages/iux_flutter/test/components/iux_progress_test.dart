import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

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
          // themes over 200ms, and every colour and measurement read during
          // that window belongs to neither of them.
          key: ValueKey<IuxThemeConfiguration>(configuration),
          theme: IuxTheme.fromConfiguration(configuration),
          home: Directionality(
            textDirection: direction,
            child: Scaffold(body: Center(child: child)),
          ),
        ),
      ),
    );
    // Never pumpAndSettle here: an indeterminate indicator animates forever by
    // design, and a helper that settled would either hang or hide that.
    await tester.pump();
  }

  Future<void> determinate(
    WidgetTester tester, {
    String label = 'Uploading photos',
    double value = 0.45,
    String valueLabel = '45%',
    IuxThemeConfiguration configuration = const IuxThemeConfiguration(),
    TextDirection direction = TextDirection.ltr,
    double textScale = 1,
    Size size = const Size(400, 800),
  }) =>
      host(
        tester,
        IuxProgressIndicator(
          label: label,
          value: value,
          valueLabel: valueLabel,
        ),
        configuration: configuration,
        direction: direction,
        textScale: textScale,
        size: size,
      );

  Future<void> indeterminate(
    WidgetTester tester, {
    String label = 'Searching nearby stores',
    IuxThemeConfiguration configuration = const IuxThemeConfiguration(),
    TextDirection direction = TextDirection.ltr,
    double textScale = 1,
    Size size = const Size(400, 800),
  }) =>
      host(
        tester,
        IuxLoadingIndicator(label: label),
        configuration: configuration,
        direction: direction,
        textScale: textScale,
        size: size,
      );

  /// The tokens a component would resolve under [configuration].
  Future<IuxProgressTokens> tokensFor(
    WidgetTester tester,
    IuxThemeConfiguration configuration, {
    double textScale = 1,
  }) async {
    late IuxProgressTokens resolved;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: MaterialApp(
          key: ValueKey<IuxThemeConfiguration>(configuration),
          theme: IuxTheme.fromConfiguration(configuration),
          home: Builder(
            builder: (BuildContext context) {
              resolved = IuxProgressResolver.resolve(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return resolved;
  }

  group('a determinate indicator states how far it has got', () {
    testWidgets('the value is readable as words, not only as a length',
        (WidgetTester tester) async {
      await determinate(tester);
      expect(find.text('Uploading photos'), findsOneWidget);
      expect(find.text('45%'), findsOneWidget);
    });

    testWidgets('the fill covers exactly the fraction it was given',
        (WidgetTester tester) async {
      await determinate(tester, value: 0.25, valueLabel: '25%');
      await tester.pumpAndSettle();
      expect(
        tester.widget<FractionallySizedBox>(find.byType(FractionallySizedBox)),
        isA<FractionallySizedBox>().having(
            (FractionallySizedBox b) => b.widthFactor,
            'widthFactor',
            closeTo(0.25, 0.001)),
      );
    });

    testWidgets('the fill grows from the side the user reads from',
        (WidgetTester tester) async {
      // A left-anchored bar in an Arabic interface reports progress running
      // backwards, so the anchor is directional rather than absolute.
      for (final TextDirection direction in TextDirection.values) {
        await determinate(tester, direction: direction);
        expect(
          tester
              .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
              .alignment,
          AlignmentDirectional.centerStart,
          reason: 'failed for $direction',
        );
      }
    });
  });

  group('an operation with no known extent still names itself', () {
    testWidgets('the label is visible, not only announced',
        (WidgetTester tester) async {
      await indeterminate(tester);
      expect(find.text('Searching nearby stores'), findsOneWidget);
    });

    testWidgets('the segment moves while motion is permitted',
        (WidgetTester tester) async {
      await indeterminate(tester);
      final AlignmentGeometry first = tester
          .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
          .alignment;

      await tester.pump(const Duration(milliseconds: 400));
      final AlignmentGeometry later = tester
          .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
          .alignment;

      expect(later, isNot(first));
    });
  });

  group('progress survives a reduced-motion preference', () {
    testWidgets('the determinate fill still animates, only shorter',
        (WidgetTester tester) async {
      // IuxMotionRole.progress is preserved rather than removed: taking the
      // indicator away would hide that work is happening, which is worse than
      // the movement.
      await determinate(tester,
          configuration: _withMotion(
            IuxMotionPreference.standard,
          ));
      final Duration full = tester
          .widget<TweenAnimationBuilder<double>>(
              find.byType(TweenAnimationBuilder<double>))
          .duration;

      await determinate(tester,
          configuration: _withMotion(
            IuxMotionPreference.reduced,
          ));
      final Duration reduced = tester
          .widget<TweenAnimationBuilder<double>>(
              find.byType(TweenAnimationBuilder<double>))
          .duration;

      expect(reduced, greaterThan(Duration.zero));
      expect(reduced, lessThan(full));
    });

    testWidgets('the indeterminate bar remains, and does not speed up',
        (WidgetTester tester) async {
      // Halving a transition makes it less intrusive. Halving a loop doubles
      // how often the segment sweeps past, which is the opposite of what the
      // user asked for.
      final IuxProgressTokens standard =
          await tokensFor(tester, _withMotion(IuxMotionPreference.standard));
      final IuxProgressTokens reduced =
          await tokensFor(tester, _withMotion(IuxMotionPreference.reduced));

      expect(reduced.traversal, greaterThanOrEqualTo(standard.traversal));

      await indeterminate(
        tester,
        configuration: _withMotion(IuxMotionPreference.reduced),
      );
      expect(find.byType(FractionallySizedBox), findsOneWidget);
    });

    testWidgets('a calmer interface is not a silent one',
        (WidgetTester tester) async {
      // Reduced visual stimulation removes decoration. Progress is not
      // decoration, so the bar stays and only the animation is subject to the
      // motion preference beside it.
      await indeterminate(
        tester,
        configuration: const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(
            visualStimulation: IuxVisualStimulation.reduced,
          ),
        ),
      );
      expect(find.byType(FractionallySizedBox), findsOneWidget);
      expect(find.text('Searching nearby stores'), findsOneWidget);
    });
  });

  group('no motion replaces the movement, it does not merely stop it', () {
    testWidgets('a loading indicator falls back to a static status line',
        (WidgetTester tester) async {
      // A frozen indeterminate segment is parked at a position that means
      // nothing, which reads as a hung operation. So the bar is removed and
      // the words carry the whole message.
      await indeterminate(
        tester,
        configuration: _withMotion(IuxMotionPreference.none),
      );

      expect(find.byType(FractionallySizedBox), findsNothing);
      expect(find.text('Searching nearby stores'), findsOneWidget);
    });

    testWidgets('nothing is left animating, so the frame loop can rest',
        (WidgetTester tester) async {
      await indeterminate(
        tester,
        configuration: _withMotion(IuxMotionPreference.none),
      );
      // Would time out if any animation were still running.
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('a determinate indicator keeps its bar and snaps to the value',
        (WidgetTester tester) async {
      // A bar at 45% is a static statement whether or not the last change was
      // animated, so removing it would remove information the motion never
      // carried.
      await determinate(
        tester,
        configuration: _withMotion(IuxMotionPreference.none),
      );

      expect(find.text('45%'), findsOneWidget);
      expect(find.byType(FractionallySizedBox), findsOneWidget);
      expect(
        tester
            .widget<TweenAnimationBuilder<double>>(
                find.byType(TweenAnimationBuilder<double>))
            .duration,
        Duration.zero,
      );
    });

    testWidgets('a screen reader is still told what is happening',
        (WidgetTester tester) async {
      // The whole point of requiresStaticAlternative: what disappears is the
      // movement, never the information.
      await indeterminate(
        tester,
        configuration: _withMotion(IuxMotionPreference.none),
      );
      expect(
        find.bySemanticsLabel('Searching nearby stores'),
        findsOneWidget,
      );
    });
  });

  group('a screen reader hears progress without being flooded by it', () {
    testWidgets('the description and the value are both announced',
        (WidgetTester tester) async {
      await determinate(tester);
      expect(find.bySemanticsLabel('Uploading photos'), findsOneWidget);
      expect(find.bySemanticsLabel('45%'), findsOneWidget);
    });

    testWidgets('a small advance updates the eye but not the ear',
        (WidgetTester tester) async {
      await determinate(tester);
      await determinate(tester, value: 0.47, valueLabel: '47%');

      expect(find.text('47%'), findsOneWidget,
          reason: 'the visible value is never throttled');
      expect(find.bySemanticsLabel('45%'), findsOneWidget,
          reason: 'announcing every percent would make TalkBack unusable');
      expect(find.bySemanticsLabel('47%'), findsNothing);
    });

    testWidgets('crossing a milestone does update the ear',
        (WidgetTester tester) async {
      await determinate(tester);
      await determinate(tester, value: 0.6, valueLabel: '60%');

      expect(find.bySemanticsLabel('60%'), findsOneWidget);
    });

    testWidgets('reaching the end is announced even from a small step',
        (WidgetTester tester) async {
      // The last few percent are exactly the ones the user is waiting on.
      await determinate(tester, value: 0.97, valueLabel: '97%');
      await determinate(tester, value: 1, valueLabel: '100%');

      expect(find.bySemanticsLabel('100%'), findsOneWidget);
    });

    testWidgets('changing the phase is announced whatever the number does',
        (WidgetTester tester) async {
      await determinate(tester, label: 'Uploading photos');
      await determinate(
        tester,
        label: 'Processing photos',
        value: 0.46,
        valueLabel: '46%',
      );

      expect(find.bySemanticsLabel('Processing photos'), findsOneWidget);
      expect(find.bySemanticsLabel('46%'), findsOneWidget);
    });

    testWidgets('the visual is not read a second time',
        (WidgetTester tester) async {
      await determinate(tester);
      expect(find.bySemanticsLabel('45%'), findsOneWidget);
      expect(find.bySemanticsLabel('Uploading photos'), findsOneWidget);
    });
  });

  group('the announcement rule, on its own', () {
    test('a phase change always announces', () {
      expect(
        IuxProgressAnnouncementPolicy.shouldAnnounce(
          announced: 0.5,
          current: 0.5,
          phaseChanged: true,
        ),
        isTrue,
      );
    });

    test('a step below the milestone stays silent', () {
      expect(
        IuxProgressAnnouncementPolicy.shouldAnnounce(
          announced: 0.5,
          current: 0.55,
          phaseChanged: false,
        ),
        isFalse,
      );
    });

    test('a step at the milestone announces', () {
      expect(
        IuxProgressAnnouncementPolicy.shouldAnnounce(
          announced: 0.5,
          current: 0.6,
          phaseChanged: false,
        ),
        isTrue,
      );
    });

    test('going backwards announces, because a restart is news', () {
      expect(
        IuxProgressAnnouncementPolicy.shouldAnnounce(
          announced: 0.9,
          current: 0.1,
          phaseChanged: false,
        ),
        isTrue,
      );
    });

    test('completion announces however small the final step', () {
      expect(
        IuxProgressAnnouncementPolicy.shouldAnnounce(
          announced: 0.99,
          current: 1,
          phaseChanged: false,
        ),
        isTrue,
      );
    });

    test('completion announces once, not on every rebuild', () {
      expect(
        IuxProgressAnnouncementPolicy.shouldAnnounce(
          announced: 1,
          current: 1,
          phaseChanged: false,
        ),
        isFalse,
      );
    });
  });

  group('an incoherent configuration fails loudly', () {
    test('a fraction above one is rejected at the call site', () {
      expect(
        () => IuxProgressIndicator(
          label: 'Uploading',
          value: 1.4,
          valueLabel: '140%',
        ),
        throwsAssertionError,
      );
    });

    test('a negative fraction is rejected', () {
      expect(
        () => IuxProgressIndicator(
          label: 'Uploading',
          value: -0.1,
          valueLabel: '-10%',
        ),
        throwsAssertionError,
      );
    });

    test('an unnamed indicator is rejected', () {
      expect(
        () => IuxProgressIndicator(label: '', value: 0.5, valueLabel: '50%'),
        throwsAssertionError,
      );
      expect(() => IuxLoadingIndicator(label: ''), throwsAssertionError);
    });

    test('a value with no words is rejected', () {
      expect(
        () => IuxProgressIndicator(
          label: 'Uploading',
          value: 0.5,
          valueLabel: '',
        ),
        throwsAssertionError,
      );
    });
  });

  group('a label that states a percentage must state the one being painted',
      () {
    /// Pumps an indicator and returns whatever it threw, or null.
    ///
    /// The check runs in `build` rather than in the constructor — a `const`
    /// constructor may only assert on constant expressions, and a regular
    /// expression match is not one — so the widget has to be mounted for the
    /// assertion to be reached.
    Future<Object?> mount(
      WidgetTester tester, {
      required double value,
      required String valueLabel,
    }) async {
      await determinate(tester, value: value, valueLabel: valueLabel);
      return tester.takeException();
    }

    testWidgets('a bar at 45% announcing 90% is refused',
        (WidgetTester tester) async {
      // IUX-PROGRESS-LABEL-001, WCAG 2.2 SC 1.1.1. The two audiences were told
      // different things and neither was warned.
      final Object? thrown =
          await mount(tester, value: 0.45, valueLabel: '90%');

      expect(thrown, isA<AssertionError>());
      expect(
        thrown.toString(),
        allOf(contains('90'), contains('45')),
        reason: 'the message has to carry both numbers, or the developer has '
            'to go and find the one that is wrong',
      );
    });

    testWidgets('a label that agrees is accepted', (WidgetTester tester) async {
      expect(await mount(tester, value: 0.45, valueLabel: '45%'), isNull);
      expect(await mount(tester, value: 0, valueLabel: '0%'), isNull);
      expect(await mount(tester, value: 1, valueLabel: '100%'), isNull);
    });

    testWidgets('rounding and truncation are not disagreement',
        (WidgetTester tester) async {
      // The check exists to catch a label describing different progress, not
      // one that is merely coarse. A tolerance tight enough to argue about
      // rounding conventions would refuse correct code, which is worse than
      // the defect.
      final Map<String, (double, String)> rounded = <String, (double, String)>{
        'truncated to the nearest one': (0.4599, '45%'),
        'rounded to the nearest one': (0.4549, '45%'),
        'rounded to the nearest ten, downward': (0.4499, '40%'),
        'rounded to the nearest ten, upward': (0.45, '50%'),
        'stated to a decimal place': (0.4567, '45.7%'),
      };

      for (final MapEntry<String, (double, String)> entry in rounded.entries) {
        expect(
          await mount(
            tester,
            value: entry.value.$1,
            valueLabel: entry.value.$2,
          ),
          isNull,
          reason: entry.key,
        );
      }
    });

    testWidgets('a percentage is read wherever it sits in the sentence',
        (WidgetTester tester) async {
      // The parameter's own documentation asks for a label that stands alone,
      // so the number is rarely the whole string.
      expect(
        await mount(tester, value: 0.45, valueLabel: '45% uploaded'),
        isNull,
      );
      expect(
        await mount(tester, value: 0.45, valueLabel: 'Uploaded 90% so far'),
        isA<AssertionError>(),
      );
    });

    testWidgets('the space and the sign a locale writes are both read',
        (WidgetTester tester) async {
      // French writes "45 %" with a non-breaking space; Arabic writes U+066A;
      // CJK setting uses the fullwidth U+FF05. All three are the same claim.
      expect(
        await mount(tester, value: 0.45, valueLabel: '45 %'),
        isNull,
      );
      expect(
        await mount(tester, value: 0.45, valueLabel: '90 %'),
        isA<AssertionError>(),
      );
      expect(
        await mount(tester, value: 0.45, valueLabel: '90٪'),
        isA<AssertionError>(),
      );
      expect(
        await mount(tester, value: 0.45, valueLabel: '90％'),
        isA<AssertionError>(),
      );
      // A decimal comma, which is what most of Europe writes.
      expect(
        await mount(tester, value: 0.457, valueLabel: '45,7 %'),
        isNull,
      );
    });

    testWidgets('a label with no percentage in it is not inspected',
        (WidgetTester tester) async {
      // Deliberate, and the reason the check is worth having. "3 of 7"
      // describes both a run that finished three steps and one that finished
      // two and started the third, so reading it as a fraction would refuse
      // correct code — and a false-positive assertion is worse than a missing
      // one. The forms this parameter documents are all here.
      for (final String label in <String>[
        '3 of 7',
        '12 MB of 40 MB',
        'Almost there',
        '٤٥٪', // "45%" in Arabic-Indic digits: not ASCII, so
        // no match and therefore no claim.
      ]) {
        expect(
          await mount(tester, value: 0.45, valueLabel: label),
          isNull,
          reason: 'inspected "$label", which it cannot read unambiguously',
        );
      }
    });

    testWidgets('two percentages in one label are left alone',
        (WidgetTester tester) async {
      // There is no way to tell which of them is meant to be the value, and
      // guessing is how a check starts refusing correct code.
      expect(
        await mount(
          tester,
          value: 0.45,
          valueLabel: '45% of the 90% allowance',
        ),
        isNull,
      );
    });

    testWidgets('a label computed apart from the value is caught as it drifts',
        (WidgetTester tester) async {
      // The realistic shape of this defect: the two agree at the start and
      // separate afterwards, which is why the check runs on every build rather
      // than once at construction.
      expect(await mount(tester, value: 0, valueLabel: '0%'), isNull);

      await determinate(tester, value: 0.6, valueLabel: '30%');
      expect(tester.takeException(), isA<AssertionError>());
    });
  });

  group('it holds up under the conditions users actually have', () {
    testWidgets('a 200% text scale on a small screen clips nothing',
        (WidgetTester tester) async {
      await determinate(
        tester,
        label: 'Uploading the photographs from your last trip',
        textScale: 2,
        size: const Size(320, 480),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('45%'), findsOneWidget);
    });

    testWidgets(
        'an enlarged description stacks above its value rather than '
        'shrinking', (WidgetTester tester) async {
      await determinate(tester, textScale: 2, size: const Size(320, 480));
      expect(
        find.descendant(
          of: find.byType(IuxProgressIndicator),
          matching: find.byType(Row),
        ),
        findsNothing,
      );

      await determinate(tester, size: const Size(320, 480));
      expect(
        find.descendant(
          of: find.byType(IuxProgressIndicator),
          matching: find.byType(Row),
        ),
        findsOneWidget,
        reason: 'at a normal scale the two lines still fit side by side',
      );
    });

    testWidgets('a long description wraps rather than being truncated',
        (WidgetTester tester) async {
      await determinate(
        tester,
        label: 'Uploading the photographs you selected from your last trip',
        size: const Size(320, 640),
      );
      expect(tester.takeException(), isNull);
      final Text description = tester.widget<Text>(
        find.text('Uploading the photographs you selected from your last trip'),
      );
      expect(description.overflow, isNot(TextOverflow.ellipsis));
      expect(description.maxLines, isNull,
          reason: 'a truncated status line is worse than no status line');
    });

    testWidgets('a loading indicator survives the same conditions',
        (WidgetTester tester) async {
      await indeterminate(
        tester,
        label: 'Searching every store within twenty kilometres of you',
        textScale: 2,
        size: const Size(320, 480),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('it renders right-to-left', (WidgetTester tester) async {
      await determinate(
        tester,
        label: 'جارٍ الرفع',
        valueLabel: '٤٥٪',
        direction: TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('٤٥٪'), findsOneWidget);

      await indeterminate(
        tester,
        label: 'جارٍ البحث',
        direction: TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('it renders on every theme profile',
        (WidgetTester tester) async {
      for (final IuxThemeConfiguration configuration in _profiles) {
        await determinate(tester, configuration: configuration);
        expect(tester.takeException(), isNull, reason: '$configuration');
        expect(find.text('45%'), findsOneWidget);

        await indeterminate(tester, configuration: configuration);
        expect(tester.takeException(), isNull, reason: '$configuration');
      }
    });
  });

  group('the bar carries its meaning without relying on a shadow or a hue', () {
    testWidgets(
        'the covered part is distinguishable from the rest, on every '
        'profile', (WidgetTester tester) async {
      // WCAG 2.2 SC 1.4.11. The boundary between filled and unfilled is the
      // only thing in the bar that carries the value.
      for (final IuxThemeConfiguration configuration in _profiles) {
        final IuxProgressTokens tokens = await tokensFor(tester, configuration);
        expect(
          ContrastMetric.ratio(tokens.fill, tokens.track),
          greaterThanOrEqualTo(ContrastMetric.nonText),
          reason: '$configuration',
        );
      }
    });

    testWidgets('and from the page it sits on', (WidgetTester tester) async {
      for (final IuxThemeConfiguration configuration in _profiles) {
        final IuxProgressTokens tokens = await tokensFor(tester, configuration);
        final IuxSemanticColors colors =
            IuxTheme.fromConfiguration(configuration)
                .extension<IuxSemanticColors>()!;
        expect(
          ContrastMetric.ratio(tokens.fill, colors.surface.base),
          greaterThanOrEqualTo(ContrastMetric.nonText),
          reason: '$configuration',
        );
      }
    });

    testWidgets('the text stays readable on every profile',
        (WidgetTester tester) async {
      for (final IuxThemeConfiguration configuration in _profiles) {
        final IuxProgressTokens tokens = await tokensFor(tester, configuration);
        final IuxSemanticColors colors =
            IuxTheme.fromConfiguration(configuration)
                .extension<IuxSemanticColors>()!;
        for (final TextStyle style in <TextStyle>[
          tokens.labelStyle,
          tokens.valueStyle,
        ]) {
          expect(
            ContrastMetric.ratio(style.color!, colors.surface.base),
            greaterThanOrEqualTo(ContrastMetric.normalText),
            reason: '$configuration',
          );
        }
      }
    });

    testWidgets('high contrast thickens the bar rather than recolouring it',
        (WidgetTester tester) async {
      final IuxProgressTokens standard =
          await tokensFor(tester, const IuxThemeConfiguration());
      final IuxProgressTokens high = await tokensFor(
        tester,
        const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(contrast: IuxContrast.high),
        ),
      );
      expect(high.thickness, greaterThan(standard.thickness));
    });

    testWidgets('enlarged text enlarges the bar with it',
        (WidgetTester tester) async {
      // Someone who enlarged their text has said that four logical pixels are
      // not enough.
      final IuxProgressTokens standard =
          await tokensFor(tester, const IuxThemeConfiguration());
      final IuxProgressTokens enlarged = await tokensFor(
        tester,
        const IuxThemeConfiguration(),
        textScale: 2,
      );
      expect(enlarged.thickness, greaterThan(standard.thickness));
    });
  });

  group('the widget carries no business meaning', () {
    testWidgets('a full bar is not a success, and says nothing of the kind',
        (WidgetTester tester) async {
      // The parent owns the outcome. Reaching 1.0 means the caller supplied
      // 1.0 and nothing more.
      await determinate(tester, value: 1, valueLabel: '100%');
      expect(find.byType(IuxProgressIndicator), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('Uploading photos'), findsOneWidget,
          reason: 'the description is the caller\'s, not a completion notice');
    });

    testWidgets('it emits no haptic and shows nothing of its own',
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

      await determinate(tester);
      await determinate(tester, value: 1, valueLabel: '100%');

      expect(
        platform.where((MethodCall c) => c.method.startsWith('HapticFeedback')),
        isEmpty,
      );
    });
  });
}
