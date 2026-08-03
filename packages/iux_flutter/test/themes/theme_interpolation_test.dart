import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

void main() {
  final IuxResolvedTheme light =
      IuxTheme.resolve(const IuxThemeConfiguration());
  final IuxResolvedTheme dark = IuxTheme.resolve(
    const IuxThemeConfiguration(brightness: Brightness.dark),
  );
  final IuxResolvedTheme highContrast = IuxTheme.resolve(
    const IuxThemeConfiguration(
      profile: IuxAccessibilityProfile(contrast: IuxContrast.high),
    ),
  );
  final IuxResolvedTheme comfortable = IuxTheme.resolve(
    const IuxThemeConfiguration(
      profile: IuxAccessibilityProfile(
        density: IuxDensity.comfortable,
        touchTarget: IuxTouchTargetPreference.comfortable,
      ),
    ),
  );

  group('bounds are exact', () {
    test('colours', () {
      expect(light.colors.lerp(dark.colors, 0), equals(light.colors));
      expect(light.colors.lerp(dark.colors, 1), equals(dark.colors));
    });

    test('typography', () {
      expect(
        light.typography.lerp(dark.typography, 0),
        equals(light.typography),
      );
      expect(
        light.typography.lerp(dark.typography, 1),
        equals(dark.typography),
      );
    });

    test('geometry', () {
      expect(
        light.geometry.lerp(comfortable.geometry, 0),
        equals(light.geometry),
      );
      expect(
        light.geometry.lerp(comfortable.geometry, 1),
        equals(comfortable.geometry),
      );
    });

    test('motion', () {
      final IuxMotionTheme reduced = IuxTheme.resolve(
        const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(motion: IuxMotionPreference.reduced),
        ),
      ).motion;
      expect(light.motion.lerp(reduced, 0), equals(light.motion));
      expect(light.motion.lerp(reduced, 1), equals(reduced));
    });

    test('accessibility record', () {
      expect(
        light.accessibility.lerp(dark.accessibility, 0),
        equals(light.accessibility),
      );
      expect(
        light.accessibility.lerp(dark.accessibility, 1),
        equals(dark.accessibility),
      );
    });
  });

  group('intermediate values stay valid', () {
    test('light to dark produces a distinct intermediate', () {
      final IuxSemanticColors mid = light.colors.lerp(dark.colors, 0.5);
      expect(mid, isNot(equals(light.colors)));
      expect(mid, isNot(equals(dark.colors)));
    });

    test('standard to high contrast produces a distinct intermediate', () {
      final IuxSemanticColors mid = light.colors.lerp(highContrast.colors, 0.5);
      expect(mid, isNot(equals(light.colors)));
    });

    test('the touch target never dips below the minimum mid-transition', () {
      // A linear ramp between two valid sizes is itself valid, but a ramp
      // that momentarily sits under the minimum gives the user a target they
      // can miss for the duration of the animation.
      for (final double t in <double>[0, 0.1, 0.25, 0.5, 0.75, 0.9, 1]) {
        final IuxGeometryTheme mid =
            comfortable.geometry.lerp(light.geometry, t);
        expect(
          mid.minimumTouchTarget,
          greaterThanOrEqualTo(IuxTouchTarget.minimum),
          reason: 'target dropped below the minimum at t=$t',
        );
      }
    });

    test('spacing interpolates monotonically', () {
      final double start = light.geometry.spacingMd;
      final double end = comfortable.geometry.spacingMd;
      final double mid =
          light.geometry.lerp(comfortable.geometry, 0.5).spacingMd;
      expect(mid, greaterThan(start));
      expect(mid, lessThan(end));
    });

    test('a categorical preference never lands between two values', () {
      // There is no state between "reduced motion" and "standard motion".
      final IuxMotionTheme reduced = IuxTheme.resolve(
        const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(motion: IuxMotionPreference.reduced),
        ),
      ).motion;
      for (final double t in <double>[0.25, 0.5, 0.75]) {
        final IuxMotionTheme mid = light.motion.lerp(reduced, t);
        expect(
          mid.allowsNonEssentialMotion,
          anyOf(
            light.motion.allowsNonEssentialMotion,
            reduced.allowsNonEssentialMotion,
          ),
        );
      }
    });
  });

  group('resolution from context', () {
    testWidgets('every extension resolves through its own accessor',
        (WidgetTester tester) async {
      late IuxSemanticColors colors;
      late IuxTypographyTheme typography;
      late IuxGeometryTheme geometry;
      late IuxMotionTheme motion;
      late IuxAccessibilityTheme accessibility;

      await tester.pumpWidget(
        MaterialApp(
          theme: IuxTheme.dark(
            profile: const IuxAccessibilityProfile(contrast: IuxContrast.high),
          ),
          home: Builder(
            builder: (BuildContext context) {
              colors = IuxSemanticColors.of(context);
              typography = IuxTypographyTheme.of(context);
              geometry = IuxGeometryTheme.of(context);
              motion = IuxMotionTheme.of(context);
              accessibility = IuxAccessibilityTheme.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(colors, isNotNull);
      expect(typography.body.fontSize, 16);
      expect(geometry.minimumTouchTarget, IuxTouchTarget.minimum);
      expect(motion.standard, greaterThan(Duration.zero));
      expect(accessibility.isHighContrast, isTrue);
      expect(accessibility.brightness, Brightness.dark);
    });

    testWidgets('a missing extension is reported, never silently replaced',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              IuxGeometryTheme.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(
        tester.takeException().toString(),
        contains('No IuxGeometryTheme found'),
      );
    });

    testWidgets('switching themes animates through valid intermediates',
        (WidgetTester tester) async {
      Future<void> pump(ThemeData theme) => tester.pumpWidget(
            MaterialApp(
              theme: theme,
              home: Builder(
                builder: (BuildContext context) => ColoredBox(
                  key: const Key('surface'),
                  color: IuxSemanticColors.of(context).surface.base,
                ),
              ),
            ),
          );

      await pump(IuxTheme.light());
      await pump(IuxTheme.dark());
      await tester.pump(const Duration(milliseconds: 100));

      final ColoredBox box =
          tester.widget<ColoredBox>(find.byKey(const Key('surface')));
      expect(
          box.color, isNot(equals(IuxTheme.light().scaffoldBackgroundColor)));

      await tester.pumpAndSettle();
      final ColoredBox settled =
          tester.widget<ColoredBox>(find.byKey(const Key('surface')));
      expect(settled.color, IuxTheme.dark().scaffoldBackgroundColor);
    });
  });
}
