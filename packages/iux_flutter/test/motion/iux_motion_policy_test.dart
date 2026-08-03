import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

void main() {
  Future<IuxResolvedMotion> resolve(
    WidgetTester tester, {
    required IuxMotionRole role,
    IuxMotionScale scale = IuxMotionScale.standard,
    IuxAccessibilityProfile profile = const IuxAccessibilityProfile(),
    bool platformDisablesAnimations = false,
    bool installTheme = true,
  }) async {
    late IuxResolvedMotion resolved;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(disableAnimations: platformDisablesAnimations),
        child: MaterialApp(
          theme: installTheme ? IuxTheme.light(profile: profile) : ThemeData(),
          home: Builder(
            builder: (BuildContext context) {
              resolved = IuxMotionPolicy.resolve(
                context,
                role: role,
                scale: scale,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    // A theme change animates; settle so the resolved values are the requested
    // ones rather than an interpolation of the previous pump.
    await tester.pumpAndSettle();
    return resolved;
  }

  const IuxAccessibilityProfile standard = IuxAccessibilityProfile(
    motion: IuxMotionPreference.standard,
  );
  const IuxAccessibilityProfile reduced = IuxAccessibilityProfile(
    motion: IuxMotionPreference.reduced,
  );
  const IuxAccessibilityProfile none = IuxAccessibilityProfile(
    motion: IuxMotionPreference.none,
  );

  group('standard motion', () {
    testWidgets('every role animates and is preserved',
        (WidgetTester tester) async {
      for (final IuxMotionRole role in IuxMotionRole.values) {
        final IuxResolvedMotion motion =
            await resolve(tester, role: role, profile: standard);
        expect(motion.isAnimated, isTrue, reason: '${role.name} did not run');
        expect(motion.behavior, IuxReducedMotionBehavior.preserve);
        expect(motion.prefersFade, isFalse);
      }
    });

    testWidgets('scale selects the duration', (WidgetTester tester) async {
      final IuxResolvedMotion short = await resolve(
        tester,
        role: IuxMotionRole.stateChange,
        scale: IuxMotionScale.short,
        profile: standard,
      );
      final IuxResolvedMotion long = await resolve(
        tester,
        role: IuxMotionRole.stateChange,
        scale: IuxMotionScale.long,
        profile: standard,
      );
      expect(short.duration, lessThan(long.duration));
    });

    testWidgets('entering and leaving use opposite easing',
        (WidgetTester tester) async {
      final IuxResolvedMotion enter =
          await resolve(tester, role: IuxMotionRole.enter, profile: standard);
      final IuxResolvedMotion exit =
          await resolve(tester, role: IuxMotionRole.exit, profile: standard);
      expect(enter.curve, isNot(equals(exit.curve)));
    });
  });

  group('reduced motion', () {
    testWidgets('decoration is removed', (WidgetTester tester) async {
      final IuxResolvedMotion motion =
          await resolve(tester, role: IuxMotionRole.emphasis, profile: reduced);
      expect(motion.isAnimated, isFalse);
      expect(motion.behavior, IuxReducedMotionBehavior.remove);
    });

    testWidgets('travel is simplified to a fade rather than sped up',
        (WidgetTester tester) async {
      // A fast large movement is worse than a slow one for a user prone to
      // motion discomfort, so shortening would be the wrong adaptation.
      for (final IuxMotionRole role in <IuxMotionRole>[
        IuxMotionRole.reposition,
        IuxMotionRole.reveal,
        IuxMotionRole.conceal,
      ]) {
        final IuxResolvedMotion motion =
            await resolve(tester, role: role, profile: reduced);
        expect(motion.behavior, IuxReducedMotionBehavior.simplify);
        expect(motion.prefersFade, isTrue);
        expect(motion.isAnimated, isTrue);
      }
    });

    testWidgets('in-place changes are shortened, not removed',
        (WidgetTester tester) async {
      for (final IuxMotionRole role in <IuxMotionRole>[
        IuxMotionRole.stateChange,
        IuxMotionRole.enter,
        IuxMotionRole.exit,
      ]) {
        final IuxResolvedMotion motion =
            await resolve(tester, role: role, profile: reduced);
        expect(motion.behavior, IuxReducedMotionBehavior.shorten);
        expect(motion.isAnimated, isTrue);
      }
    });

    testWidgets('progress is preserved, because removing it hides the work',
        (WidgetTester tester) async {
      final IuxResolvedMotion motion =
          await resolve(tester, role: IuxMotionRole.progress, profile: reduced);
      expect(motion.behavior, IuxReducedMotionBehavior.preserve);
      expect(motion.isAnimated, isTrue);
    });

    testWidgets('durations are shorter than at standard motion',
        (WidgetTester tester) async {
      final IuxResolvedMotion full =
          await resolve(tester, role: IuxMotionRole.enter, profile: standard);
      final IuxResolvedMotion less =
          await resolve(tester, role: IuxMotionRole.enter, profile: reduced);
      expect(less.duration, lessThan(full.duration));
    });
  });

  group('no motion', () {
    testWidgets('nothing animates, including progress',
        (WidgetTester tester) async {
      for (final IuxMotionRole role in IuxMotionRole.values) {
        final IuxResolvedMotion motion =
            await resolve(tester, role: role, profile: none);
        expect(motion.isAnimated, isFalse, reason: '${role.name} still ran');
        expect(motion.requiresStaticAlternative, isTrue);
      }
    });
  });

  group('platform preference', () {
    testWidgets('disabling animations reduces without an explicit request',
        (WidgetTester tester) async {
      final IuxResolvedMotion motion = await resolve(
        tester,
        role: IuxMotionRole.emphasis,
        platformDisablesAnimations: true,
      );
      expect(motion.isAnimated, isFalse);
    });

    testWidgets('an explicit standard request still yields to the platform',
        (WidgetTester tester) async {
      final IuxResolvedMotion motion = await resolve(
        tester,
        role: IuxMotionRole.reposition,
        profile: standard,
        platformDisablesAnimations: true,
      );
      expect(motion.behavior, IuxReducedMotionBehavior.simplify);
    });
  });

  group('visual stimulation', () {
    testWidgets('reducing stimulation also removes decoration',
        (WidgetTester tester) async {
      final IuxResolvedMotion motion = await resolve(
        tester,
        role: IuxMotionRole.emphasis,
        profile: const IuxAccessibilityProfile(
          motion: IuxMotionPreference.standard,
          visualStimulation: IuxVisualStimulation.reduced,
        ),
      );
      expect(motion.isAnimated, isFalse);
    });
  });

  group('fallbacks and contracts', () {
    testWidgets('it resolves without an IUX theme installed',
        (WidgetTester tester) async {
      final IuxResolvedMotion motion = await resolve(
        tester,
        role: IuxMotionRole.enter,
        installTheme: false,
      );
      expect(motion.isAnimated, isTrue);
    });

    test('only emphasis is decorative', () {
      for (final IuxMotionRole role in IuxMotionRole.values) {
        expect(role.isEssential, role != IuxMotionRole.emphasis);
      }
    });

    testWidgets('the result is a value type', (WidgetTester tester) async {
      final IuxResolvedMotion a =
          await resolve(tester, role: IuxMotionRole.enter, profile: standard);
      final IuxResolvedMotion b =
          await resolve(tester, role: IuxMotionRole.enter, profile: standard);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a.toString(), contains('enter'));
    });
  });
}
