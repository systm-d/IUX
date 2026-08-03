import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

void main() {
  /// Builds a tree with a given theme and platform preferences, and returns
  /// the runtime state that results from reconciling them.
  Future<IuxAccessibility> resolve(
    WidgetTester tester, {
    IuxAccessibilityProfile profile = const IuxAccessibilityProfile(),
    Brightness brightness = Brightness.light,
    bool platformHighContrast = false,
    bool platformDisablesAnimations = false,
    TextScaler textScaler = TextScaler.noScaling,
    bool installTheme = true,
  }) async {
    late IuxAccessibility resolved;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          highContrast: platformHighContrast,
          disableAnimations: platformDisablesAnimations,
          textScaler: textScaler,
        ),
        child: MaterialApp(
          theme: installTheme
              ? (brightness == Brightness.light
                  ? IuxTheme.light(profile: profile)
                  : IuxTheme.dark(profile: profile))
              : ThemeData(),
          home: Builder(
            builder: (BuildContext context) {
              resolved = IuxAccessibility.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    // A theme change animates, and IuxAccessibilityTheme.lerp holds the
    // previous value for the first half of it. Reading before the transition
    // settles would observe the theme from the previous pump.
    await tester.pumpAndSettle();
    return resolved;
  }

  group('reconciling the platform with the application', () {
    testWidgets('the platform can strengthen contrast the app did not ask for',
        (WidgetTester tester) async {
      final IuxAccessibility a11y = await resolve(
        tester,
        platformHighContrast: true,
      );
      expect(a11y.contrast, IuxContrast.high);
      expect(a11y.isHighContrast, isTrue);
    });

    testWidgets('the application cannot weaken what the platform asked for',
        (WidgetTester tester) async {
      // A user who enabled high contrast system-wide did so for a reason. An
      // application requesting standard contrast did so without knowing that.
      final IuxAccessibility a11y = await resolve(
        tester,
        profile: const IuxAccessibilityProfile(contrast: IuxContrast.standard),
        platformHighContrast: true,
      );
      expect(a11y.contrast, IuxContrast.high);
    });

    testWidgets('the application can strengthen beyond the platform',
        (WidgetTester tester) async {
      final IuxAccessibility a11y = await resolve(
        tester,
        profile: const IuxAccessibilityProfile(contrast: IuxContrast.high),
      );
      expect(a11y.contrast, IuxContrast.high);
    });

    testWidgets('system motion adopts the platform preference',
        (WidgetTester tester) async {
      final IuxAccessibility off = await resolve(
        tester,
        profile: const IuxAccessibilityProfile(
          motion: IuxMotionPreference.system,
        ),
        platformDisablesAnimations: true,
      );
      expect(off.motion, IuxMotionPreference.reduced);

      final IuxAccessibility on = await resolve(
        tester,
        profile: const IuxAccessibilityProfile(
          motion: IuxMotionPreference.system,
        ),
      );
      expect(on.motion, IuxMotionPreference.standard);
    });

    testWidgets('an explicit standard motion still yields to the platform',
        (WidgetTester tester) async {
      final IuxAccessibility a11y = await resolve(
        tester,
        profile: const IuxAccessibilityProfile(
          motion: IuxMotionPreference.standard,
        ),
        platformDisablesAnimations: true,
      );
      expect(a11y.motion, IuxMotionPreference.reduced);
    });

    testWidgets('an explicit no-motion is not softened by the platform',
        (WidgetTester tester) async {
      final IuxAccessibility a11y = await resolve(
        tester,
        profile: const IuxAccessibilityProfile(
          motion: IuxMotionPreference.none,
        ),
      );
      expect(a11y.motion, IuxMotionPreference.none);
      expect(a11y.suppressesAllMotion, isTrue);
    });

    testWidgets('the resolved motion is never left unresolved',
        (WidgetTester tester) async {
      for (final bool platform in <bool>[true, false]) {
        for (final IuxMotionPreference requested
            in IuxMotionPreference.values) {
          final IuxAccessibility a11y = await resolve(
            tester,
            profile: IuxAccessibilityProfile(motion: requested),
            platformDisablesAnimations: platform,
          );
          expect(
            a11y.motion,
            isNot(IuxMotionPreference.system),
            reason: 'the platform has been consulted by this point',
          );
        }
      }
    });
  });

  group('without an IUX theme', () {
    testWidgets('platform values alone still resolve',
        (WidgetTester tester) async {
      final IuxAccessibility a11y = await resolve(
        tester,
        installTheme: false,
        platformHighContrast: true,
      );
      expect(a11y.contrast, IuxContrast.high);
      expect(a11y.minimumTouchTarget, IuxTouchTarget.minimum);
    });
  });

  group('text scaling', () {
    testWidgets('a large scale asks the layout to stack',
        (WidgetTester tester) async {
      final IuxAccessibility small = await resolve(tester);
      expect(small.prefersStackedLayout, isFalse);

      final IuxAccessibility large = await resolve(
        tester,
        textScaler: const TextScaler.linear(2),
      );
      expect(large.prefersStackedLayout, isTrue);
      expect(large.scaleText(16), 32);
    });

    testWidgets('enlarged text is never truncated',
        (WidgetTester tester) async {
      late int? lines;
      late TextOverflow overflow;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: MaterialApp(
            theme: IuxTheme.light(),
            home: Builder(
              builder: (BuildContext context) {
                lines = IuxReadableText.maxLines(context, 1);
                overflow = IuxReadableText.overflow(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(lines, isNull, reason: 'a line limit would clip enlarged text');
      expect(overflow, TextOverflow.visible);
    });
  });

  group('decorative motion', () {
    testWidgets('is suppressed as soon as less movement is requested',
        (WidgetTester tester) async {
      expect(
        (await resolve(
          tester,
          profile: const IuxAccessibilityProfile(
            motion: IuxMotionPreference.standard,
          ),
        ))
            .allowsNonEssentialMotion,
        isTrue,
      );
      expect(
        (await resolve(tester, platformDisablesAnimations: true))
            .allowsNonEssentialMotion,
        isFalse,
      );
      expect(
        (await resolve(
          tester,
          profile: const IuxAccessibilityProfile(
            motion: IuxMotionPreference.standard,
            visualStimulation: IuxVisualStimulation.reduced,
          ),
        ))
            .allowsNonEssentialMotion,
        isFalse,
      );
    });
  });

  group('equality', () {
    testWidgets('identical conditions resolve equal', (
      WidgetTester tester,
    ) async {
      final IuxAccessibility a = await resolve(tester);
      final IuxAccessibility b = await resolve(tester);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    testWidgets('a changed condition breaks equality', (
      WidgetTester tester,
    ) async {
      final IuxAccessibility a = await resolve(tester);
      final IuxAccessibility b =
          await resolve(tester, platformHighContrast: true);
      expect(a, isNot(equals(b)));
    });
  });
}
