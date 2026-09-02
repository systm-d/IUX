import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

void main() {
  group('construction', () {
    test('light and dark are directly usable by MaterialApp', () {
      expect(IuxTheme.light(), isA<ThemeData>());
      expect(IuxTheme.dark(), isA<ThemeData>());
      expect(IuxTheme.light().brightness, Brightness.light);
      expect(IuxTheme.dark().brightness, Brightness.dark);
    });

    test('every preference combination resolves without error', () {
      for (final Brightness brightness in Brightness.values) {
        for (final IuxContrast contrast in IuxContrast.values) {
          for (final IuxDensity density in IuxDensity.values) {
            for (final IuxMotionPreference motion
                in IuxMotionPreference.values) {
              for (final IuxTouchTargetPreference target
                  in IuxTouchTargetPreference.values) {
                for (final IuxVisualStimulation stimulation
                    in IuxVisualStimulation.values) {
                  final IuxThemeConfiguration configuration =
                      IuxThemeConfiguration(
                    brightness: brightness,
                    profile: IuxAccessibilityProfile(
                      contrast: contrast,
                      density: density,
                      motion: motion,
                      touchTarget: target,
                      visualStimulation: stimulation,
                    ),
                  );
                  final IuxResolvedTheme resolved =
                      IuxTheme.resolve(configuration);
                  expect(resolved.material, isA<ThemeData>());
                  expect(resolved.extensions, hasLength(8));
                }
              }
            }
          }
        }
      }
    });

    test('the named profiles express what they claim', () {
      const IuxAccessibilityProfile comfortable =
          IuxAccessibilityProfile.comfortable();
      expect(comfortable.density, IuxDensity.comfortable);
      expect(comfortable.touchTarget, IuxTouchTargetPreference.comfortable);
      expect(comfortable.contrast, IuxContrast.standard,
          reason: 'preferences are orthogonal; comfort implies no contrast');

      const IuxAccessibilityProfile reduced =
          IuxAccessibilityProfile.reducedMotion();
      expect(reduced.motion, IuxMotionPreference.reduced);
      expect(reduced.visualStimulation, IuxVisualStimulation.reduced);
    });
  });

  group('resolution', () {
    test('every IUX extension is installed on the Material theme', () {
      final ThemeData theme = IuxTheme.light();
      expect(theme.extension<IuxSemanticColors>(), isNotNull);
      expect(theme.extension<IuxTypographyTheme>(), isNotNull);
      expect(theme.extension<IuxGeometryTheme>(), isNotNull);
      expect(theme.extension<IuxMotionTheme>(), isNotNull);
      expect(theme.extension<IuxAccessibilityTheme>(), isNotNull);
      expect(theme.extension<IuxFeedbackTheme>(), isNotNull);
    });

    test('the ColorScheme is derived from IUX roles', () {
      final IuxResolvedTheme resolved =
          IuxTheme.resolve(const IuxThemeConfiguration());
      final ColorScheme scheme = resolved.material.colorScheme;

      expect(scheme.primary, resolved.colors.action.primary.background);
      expect(scheme.onPrimary, resolved.colors.action.primary.foreground);
      expect(scheme.surface, resolved.colors.surface.base);
      expect(scheme.onSurface, resolved.colors.content.primary);
      expect(scheme.outline, resolved.colors.border.standard);
      expect(scheme.error, resolved.colors.action.destructive.background);
    });

    test('the surface tint is disabled so elevation cannot shift a surface',
        () {
      // Material 3 tints surfaces as elevation rises, which would move them
      // away from the values the contrast tests measured.
      expect(IuxTheme.light().colorScheme.surfaceTint.a, 0.0);
      expect(IuxTheme.dark().colorScheme.surfaceTint.a, 0.0);
    });

    test('the scaffold background matches the base surface role', () {
      final IuxResolvedTheme resolved =
          IuxTheme.resolve(const IuxThemeConfiguration());
      expect(
        resolved.material.scaffoldBackgroundColor,
        resolved.colors.surface.base,
      );
    });

    test('the accessibility record reports the requested conditions', () {
      final IuxAccessibilityTheme record = IuxTheme.resolve(
        const IuxThemeConfiguration(
          brightness: Brightness.dark,
          profile: IuxAccessibilityProfile(
            contrast: IuxContrast.high,
            motion: IuxMotionPreference.none,
            visualStimulation: IuxVisualStimulation.reduced,
          ),
        ),
      ).accessibility;

      expect(record.isHighContrast, isTrue);
      expect(record.prefersReducedMotion, isTrue);
      expect(record.prefersReducedStimulation, isTrue);
      expect(record.brightness, Brightness.dark);
    });
  });

  group('density and touch targets', () {
    test('density changes spacing', () {
      double spacing(IuxDensity density) => IuxTheme.resolve(
            IuxThemeConfiguration(
              profile: IuxAccessibilityProfile(density: density),
            ),
          ).geometry.spacingMd;

      expect(
          spacing(IuxDensity.compact), lessThan(spacing(IuxDensity.standard)));
      expect(spacing(IuxDensity.comfortable),
          greaterThan(spacing(IuxDensity.standard)));
    });

    test('compact density never reduces the minimum touch target', () {
      for (final IuxDensity density in IuxDensity.values) {
        final IuxGeometryTheme geometry = IuxTheme.resolve(
          IuxThemeConfiguration(
            profile: IuxAccessibilityProfile(density: density),
          ),
        ).geometry;
        expect(
          geometry.minimumTouchTarget,
          greaterThanOrEqualTo(IuxTouchTarget.minimum),
          reason: 'a compact layout tightens spacing, not what a finger hits',
        );
      }
    });

    test('comfortable targets are larger than standard ones', () {
      double target(IuxTouchTargetPreference preference) => IuxTheme.resolve(
            IuxThemeConfiguration(
              profile: IuxAccessibilityProfile(touchTarget: preference),
            ),
          ).geometry.minimumTouchTarget;

      expect(
        target(IuxTouchTargetPreference.comfortable),
        greaterThan(target(IuxTouchTargetPreference.standard)),
      );
    });
  });

  group('motion', () {
    IuxMotionTheme motionFor(IuxMotionPreference preference) =>
        IuxTheme.resolve(
          IuxThemeConfiguration(
            profile: IuxAccessibilityProfile(motion: preference),
          ),
        ).motion;

    test('reduced motion shortens rather than removes', () {
      final IuxMotionTheme standard = motionFor(IuxMotionPreference.standard);
      final IuxMotionTheme reduced = motionFor(IuxMotionPreference.reduced);

      expect(reduced.standard, lessThan(standard.standard));
      expect(reduced.standard, greaterThan(Duration.zero),
          reason: 'reduced motion keeps the transitions that carry meaning');
    });

    test('no motion removes every duration', () {
      final IuxMotionTheme none = motionFor(IuxMotionPreference.none);
      expect(none.short, Duration.zero);
      expect(none.standard, Duration.zero);
      expect(none.long, Duration.zero);
    });

    test('decorative motion is forbidden as soon as less is requested', () {
      expect(motionFor(IuxMotionPreference.standard).allowsNonEssentialMotion,
          isTrue);
      expect(motionFor(IuxMotionPreference.reduced).allowsNonEssentialMotion,
          isFalse);
      expect(motionFor(IuxMotionPreference.none).allowsNonEssentialMotion,
          isFalse);
    });

    test('reduced visual stimulation also suppresses decorative motion', () {
      final IuxMotionTheme motion = IuxTheme.resolve(
        const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(
            motion: IuxMotionPreference.standard,
            visualStimulation: IuxVisualStimulation.reduced,
          ),
        ),
      ).motion;
      expect(motion.allowsNonEssentialMotion, isFalse);
    });

    test('the system preference is flagged as unresolved', () {
      // A theme is built statically and cannot read MediaQuery, so the
      // decision has to be deferred rather than guessed.
      expect(motionFor(IuxMotionPreference.system).respectsPlatformPreference,
          isTrue);
      expect(motionFor(IuxMotionPreference.reduced).respectsPlatformPreference,
          isFalse);
    });
  });

  group('visual stimulation', () {
    test('reduced stimulation flattens elevation', () {
      IuxGeometryTheme geometry(IuxVisualStimulation stimulation) =>
          IuxTheme.resolve(
            IuxThemeConfiguration(
              profile: IuxAccessibilityProfile(visualStimulation: stimulation),
            ),
          ).geometry;

      expect(geometry(IuxVisualStimulation.reduced).elevationRaised, 0);
      expect(geometry(IuxVisualStimulation.reduced).elevationModal, 0);
      expect(
        geometry(IuxVisualStimulation.standard).elevationRaised,
        greaterThan(0),
      );
    });

    test('reduced stimulation does not reduce legibility', () {
      final IuxSemanticColors standard =
          IuxTheme.resolve(const IuxThemeConfiguration()).colors;
      final IuxSemanticColors reduced = IuxTheme.resolve(
        const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(
            visualStimulation: IuxVisualStimulation.reduced,
          ),
        ),
      ).colors;
      expect(reduced.content.primary, standard.content.primary);
      expect(reduced.surface.base, standard.surface.base);
    });
  });

  group('high contrast geometry', () {
    test('outlines and focus thicken instead of only changing colour', () {
      final IuxGeometryTheme standard =
          IuxTheme.resolve(const IuxThemeConfiguration()).geometry;
      final IuxGeometryTheme high = IuxTheme.resolve(
        const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(contrast: IuxContrast.high),
        ),
      ).geometry;

      expect(high.borderWidth, greaterThan(standard.borderWidth));
      expect(high.focus.width, greaterThan(standard.focus.width));
    });
  });

  group('typography', () {
    test('no role is smaller than the readable minimum', () {
      final IuxTypographyTheme typography =
          IuxTheme.resolve(const IuxThemeConfiguration()).typography;
      for (final IuxTypographyRole role in IuxTypographyRole.values) {
        expect(
          typography.forRole(role).fontSize,
          greaterThanOrEqualTo(14),
          reason: '$role is below the readable minimum',
        );
      }
    });

    test('emphasis is ordered', () {
      final IuxTypographyTheme t =
          IuxTheme.resolve(const IuxThemeConfiguration()).typography;
      expect(t.display.fontSize!, greaterThan(t.headline.fontSize!));
      expect(t.headline.fontSize!, greaterThan(t.title.fontSize!));
      expect(t.title.fontSize!, greaterThan(t.body.fontSize!));
    });

    test('no font family is imposed by default', () {
      final IuxTypographyTheme typography =
          IuxTheme.resolve(const IuxThemeConfiguration()).typography;
      expect(typography.body.fontFamily, isNull,
          reason: 'the platform font is the default; IUX imposes no brand');
    });

    test('a font family override reaches every role', () {
      final IuxTypographyTheme typography = IuxTheme.resolve(
        const IuxThemeConfiguration(
          typography: IuxTypographyConfiguration(fontFamily: 'Atkinson'),
        ),
      ).typography;
      for (final IuxTypographyRole role in IuxTypographyRole.values) {
        expect(typography.forRole(role).fontFamily, 'Atkinson');
      }
    });
  });

  group('the overline role', () {
    // `resolve` is a factory that computes its result (it calls a local
    // `style` closure per role), so it cannot be `const` — unlike
    // `IuxThemeConfiguration()`, which has no work to do. `final` is the
    // correct binding here, not a relaxation of the brief's intent.
    final IuxTypographyTheme resolved =
        IuxTypographyTheme.resolve(const IuxThemeConfiguration());

    test('every role has a style and forRole answers for all of them', () {
      // The enum and the extension have to stay in step: a role with no style
      // is a role whose `forRole` throws at the first call site that uses it.
      for (final IuxTypographyRole role in IuxTypographyRole.values) {
        expect(resolved.forRole(role), isNotNull);
      }
      expect(resolved.forRole(IuxTypographyRole.overline), resolved.overline);
    });

    test('it is no smaller than the floor the ramp holds everywhere else', () {
      // "No size is below 14 logical pixels" is the ramp's own rule, and an
      // overline is exactly where a design system is tempted to break it —
      // 11 pt small caps look right and are unreadable at arm's length.
      for (final IuxTypographyRole role in IuxTypographyRole.values) {
        expect(resolved.forRole(role).fontSize, greaterThanOrEqualTo(14));
      }
    });

    test('it is spaced, which is what makes it an overline', () {
      // The register is carried by letter spacing and weight, not by size:
      // a 14-pixel label and a 14-pixel overline have to be told apart, and
      // the only other thing they could differ by is colour.
      expect(resolved.overline.letterSpacing, isNotNull);
      expect(resolved.overline.letterSpacing, greaterThan(0));
      expect(
          resolved.overline.fontWeight, isNot(resolved.supporting.fontWeight));
      expect(resolved.overline, isNot(resolved.label));
    });

    test('copyWith replaces it and leaves the others alone', () {
      const TextStyle other = TextStyle(fontSize: 99);
      final IuxTypographyTheme copy = resolved.copyWith(overline: other);
      expect(copy.overline, other);
      expect(copy.label, resolved.label);
      expect(copy.supporting, resolved.supporting);
    });

    test('lerp interpolates it like every other role', () {
      final IuxTypographyTheme other =
          resolved.copyWith(overline: const TextStyle(fontSize: 30));
      // `lerp`'s declared return type is already `IuxTypographyTheme` — a
      // covariant narrowing of `ThemeExtension<IuxTypographyTheme>.lerp` —
      // so no cast is needed, and `flutter analyze` flags one that is.
      final IuxTypographyTheme half = resolved.lerp(other, 0.5);
      expect(
        half.overline.fontSize,
        closeTo((resolved.overline.fontSize! + 30) / 2, 1e-9),
      );
    });

    test('equality and hashCode see it', () {
      final IuxTypographyTheme other =
          resolved.copyWith(overline: const TextStyle(fontSize: 30));
      expect(resolved == other, isFalse);
      expect(resolved.hashCode == other.hashCode, isFalse);
    });

    test('it claims no Material slot', () {
      // Material 3 dropped `overline`, and every remaining slot in `TextTheme`
      // is already answered by another role. Claiming one twice would make
      // `Theme.of(context).textTheme` disagree with `IuxTypographyTheme` about
      // what that slot means.
      final TextTheme material = resolved.toTextTheme();
      for (final TextStyle? style in <TextStyle?>[
        material.displayLarge,
        material.displayMedium,
        material.displaySmall,
        material.headlineLarge,
        material.headlineMedium,
        material.headlineSmall,
        material.titleLarge,
        material.titleMedium,
        material.titleSmall,
        material.bodyLarge,
        material.bodyMedium,
        material.bodySmall,
        material.labelLarge,
        material.labelMedium,
        material.labelSmall,
      ]) {
        expect(style, isNot(resolved.overline));
      }
    });
  });

  group('customisation', () {
    test('semantic colours can be replaced without touching components', () {
      const IuxSemanticColors branded = IuxSemanticColors(
        content: IuxContentColors(
          primary: Color(0xFF101010),
          secondary: Color(0xFF303030),
          tertiary: Color(0xFF505050),
          disabled: Color(0xFF707070),
          inverse: Color(0xFFFFFFFF),
          onAction: Color(0xFFFFFFFF),
          link: Color(0xFF0000EE),
        ),
        surface: IuxSurfaceColors(
          base: Color(0xFFFFFFFF),
          subtle: Color(0xFFF0F0F0),
          raised: Color(0xFFFFFFFF),
          overlay: Color(0xFFFFFFFF),
          interactive: Color(0xFFF0F0F0),
          selected: Color(0xFFE0E8FF),
          disabled: Color(0xFFE8E8E8),
          inverse: Color(0xFF101010),
        ),
        border: IuxBorderColors(
          standard: Color(0xFF707070),
          subtle: Color(0xFFD0D0D0),
          strong: Color(0xFF303030),
          interactive: Color(0xFF505050),
          focus: Color(0xFF0000EE),
          selected: Color(0xFF0000EE),
          disabled: Color(0xFFD0D0D0),
          error: Color(0xFFB00020),
        ),
        action: IuxActionColorSet(
          primary: IuxActionColors(
            foreground: Color(0xFFFFFFFF),
            background: Color(0xFF0000EE),
            hoveredBackground: Color(0xFF0000CC),
            pressedBackground: Color(0xFF0000AA),
            disabledForeground: Color(0xFF707070),
            disabledBackground: Color(0xFFE8E8E8),
          ),
          secondary: IuxActionColors(
            foreground: Color(0xFF0000EE),
            background: Color(0xFFFFFFFF),
            hoveredBackground: Color(0xFFF0F0F0),
            pressedBackground: Color(0xFFE8E8E8),
            disabledForeground: Color(0xFF707070),
            disabledBackground: Color(0xFFE8E8E8),
          ),
          tertiary: IuxActionColors(
            foreground: Color(0xFF0000EE),
            background: Color(0xFFFFFFFF),
            hoveredBackground: Color(0xFFF0F0F0),
            pressedBackground: Color(0xFFE8E8E8),
            disabledForeground: Color(0xFF707070),
            disabledBackground: Color(0xFFE8E8E8),
          ),
          destructive: IuxActionColors(
            foreground: Color(0xFFFFFFFF),
            background: Color(0xFFB00020),
            hoveredBackground: Color(0xFF8E001A),
            pressedBackground: Color(0xFF6C0014),
            disabledForeground: Color(0xFF707070),
            disabledBackground: Color(0xFFE8E8E8),
          ),
        ),
        feedback: IuxFeedbackColorSet(
          info: IuxFeedbackRoleColors(
            content: Color(0xFF0000EE),
            surface: Color(0xFFE0E8FF),
            border: Color(0xFF0000EE),
            icon: Color(0xFF0000EE),
          ),
          success: IuxFeedbackRoleColors(
            content: Color(0xFF0A5330),
            surface: Color(0xFFDDF2E7),
            border: Color(0xFF0A5330),
            icon: Color(0xFF0A5330),
          ),
          warning: IuxFeedbackRoleColors(
            content: Color(0xFF5E3F00),
            surface: Color(0xFFFCEFCF),
            border: Color(0xFF5E3F00),
            icon: Color(0xFF5E3F00),
          ),
          error: IuxFeedbackRoleColors(
            content: Color(0xFFB00020),
            surface: Color(0xFFFBE3E4),
            border: Color(0xFFB00020),
            icon: Color(0xFFB00020),
          ),
        ),
        comparison: IuxComparisonColorSet(
          neutral: IuxComparisonRoleColors(
            content: Color(0xFF505050),
            surface: Color(0xFFF0F0F0),
          ),
          one: IuxComparisonRoleColors(
            content: Color(0xFFB00020),
            surface: Color(0xFFFBE3E4),
          ),
          two: IuxComparisonRoleColors(
            content: Color(0xFF1D4ED8),
            surface: Color(0xFFE3EAFB),
          ),
          three: IuxComparisonRoleColors(
            content: Color(0xFF9A3412),
            surface: Color(0xFFFBEEE3),
          ),
          four: IuxComparisonRoleColors(
            content: Color(0xFF166534),
            surface: Color(0xFFE3FBEA),
          ),
        ),
        state: IuxStateColors(
          focus: Color(0xFF0000EE),
          selected: Color(0xFF0000EE),
          hovered: Color(0xFFF0F0F0),
          pressed: Color(0xFFE8E8E8),
          dragged: Color(0xFFD0D0D0),
        ),
        avatarAccent: IuxAvatarAccentColorSet(
          one: IuxAvatarAccentRoleColors(
            content: Color(0xFFFFFFFF),
            surface: Color(0xFF0000EE),
            border: Color(0xFF0000EE),
            icon: Color(0xFFFFFFFF),
          ),
          two: IuxAvatarAccentRoleColors(
            content: Color(0xFFFFFFFF),
            surface: Color(0xFF0A5330),
            border: Color(0xFF0A5330),
            icon: Color(0xFFFFFFFF),
          ),
          three: IuxAvatarAccentRoleColors(
            content: Color(0xFFFFFFFF),
            surface: Color(0xFF7A3700),
            border: Color(0xFF7A3700),
            icon: Color(0xFFFFFFFF),
          ),
          four: IuxAvatarAccentRoleColors(
            content: Color(0xFFFFFFFF),
            surface: Color(0xFFB00020),
            border: Color(0xFFB00020),
            icon: Color(0xFFFFFFFF),
          ),
        ),
      );

      final ThemeData theme = IuxTheme.withSemanticColors(
        const IuxThemeConfiguration(),
        branded,
      );

      expect(theme.extension<IuxSemanticColors>(), branded);
      expect(theme.colorScheme.primary, branded.action.primary.background);
      // Geometry, motion and typography are untouched by a colour override.
      expect(theme.extension<IuxGeometryTheme>()?.minimumTouchTarget,
          IuxTouchTarget.minimum);
    });
  });

  group('immutability and equality', () {
    test('the same configuration resolves to an equal theme', () {
      const IuxThemeConfiguration configuration = IuxThemeConfiguration(
        brightness: Brightness.dark,
        profile: IuxAccessibilityProfile(density: IuxDensity.comfortable),
      );
      expect(IuxTheme.resolve(configuration),
          equals(IuxTheme.resolve(configuration)));
    });

    test('different configurations resolve differently', () {
      expect(
        IuxTheme.resolve(const IuxThemeConfiguration()),
        isNot(equals(
          IuxTheme.resolve(
            const IuxThemeConfiguration(brightness: Brightness.dark),
          ),
        )),
      );
    });

    test('configuration copyWith replaces only what is supplied', () {
      const IuxThemeConfiguration base = IuxThemeConfiguration();
      final IuxThemeConfiguration dark =
          base.copyWith(brightness: Brightness.dark);
      expect(dark.brightness, Brightness.dark);
      expect(dark.profile, base.profile);
      expect(dark.typography, base.typography);
    });
  });
}
