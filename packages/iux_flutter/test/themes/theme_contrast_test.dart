import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

import '../support/contrast.dart';

/// Measures the contrast contracts against all four shipped role mappings.
///
/// The mappings are reached through the public theme engine rather than the
/// internal palette table, so this also proves that every combination is
/// actually reachable — the defect this mission had to fix was a high contrast
/// profile that silently forced light conditions.
void main() {
  final List<(String, IuxThemeConfiguration)> profiles =
      <(String, IuxThemeConfiguration)>[
    ('light standard', const IuxThemeConfiguration()),
    (
      'light high contrast',
      const IuxThemeConfiguration(
        profile: IuxAccessibilityProfile(contrast: IuxContrast.high),
      )
    ),
    (
      'dark standard',
      const IuxThemeConfiguration(brightness: Brightness.dark),
    ),
    (
      'dark high contrast',
      const IuxThemeConfiguration(
        brightness: Brightness.dark,
        profile: IuxAccessibilityProfile(contrast: IuxContrast.high),
      )
    ),
  ];

  for (final (String name, IuxThemeConfiguration configuration) in profiles) {
    group(name, () {
      final IuxSemanticColors colors = IuxTheme.resolve(configuration).colors;

      void expectRatio(
        String description,
        Color foreground,
        Color background,
        double threshold,
      ) {
        final double measured = ContrastMetric.ratio(foreground, background);
        expect(
          measured,
          greaterThanOrEqualTo(threshold),
          reason: '$description measured ${measured.toStringAsFixed(2)}:1, '
              'below the required ${threshold.toStringAsFixed(1)}:1',
        );
      }

      test('content is readable on every surface it may appear on', () {
        for (final (String label, Color surface) in <(String, Color)>[
          ('base', colors.surface.base),
          ('subtle', colors.surface.subtle),
          ('raised', colors.surface.raised),
          ('overlay', colors.surface.overlay),
          ('selected', colors.surface.selected),
        ]) {
          expectRatio('content.primary on surface.$label',
              colors.content.primary, surface, ContrastMetric.normalText);
        }
        expectRatio('content.secondary', colors.content.secondary,
            colors.surface.base, ContrastMetric.normalText);
        expectRatio('content.tertiary', colors.content.tertiary,
            colors.surface.base, ContrastMetric.normalText);
        expectRatio('content.link', colors.content.link, colors.surface.base,
            ContrastMetric.normalText);
        expectRatio('content.inverse', colors.content.inverse,
            colors.surface.inverse, ContrastMetric.normalText);
      });

      test('disabled content holds the ratio IUX commits to', () {
        expectRatio('content.disabled on base', colors.content.disabled,
            colors.surface.base, ContrastMetric.nonText);
        expectRatio(
            'content.disabled on disabled surface',
            colors.content.disabled,
            colors.surface.disabled,
            ContrastMetric.nonText);
      });

      test('borders that identify a control reach the non-text minimum', () {
        for (final (String label, Color border) in <(String, Color)>[
          ('standard', colors.border.standard),
          ('strong', colors.border.strong),
          ('interactive', colors.border.interactive),
          ('focus', colors.border.focus),
          ('error', colors.border.error),
        ]) {
          expectRatio('border.$label', border, colors.surface.base,
              ContrastMetric.nonText);
        }
      });

      test('every action intent is readable in every state', () {
        final Map<String, IuxActionColors> intents = <String, IuxActionColors>{
          'primary': colors.action.primary,
          'secondary': colors.action.secondary,
          'tertiary': colors.action.tertiary,
          'destructive': colors.action.destructive,
        };
        intents.forEach((String intent, IuxActionColors action) {
          expectRatio('action.$intent resting', action.foreground,
              action.background, ContrastMetric.normalText);
          expectRatio('action.$intent hovered', action.foreground,
              action.hoveredBackground, ContrastMetric.normalText);
          expectRatio('action.$intent pressed', action.foreground,
              action.pressedBackground, ContrastMetric.normalText);
          expectRatio('action.$intent disabled', action.disabledForeground,
              action.disabledBackground, ContrastMetric.nonText);
        });
      });

      test('every feedback role is readable on its own surface', () {
        final Map<String, IuxFeedbackRoleColors> roles =
            <String, IuxFeedbackRoleColors>{
          'info': colors.feedback.info,
          'success': colors.feedback.success,
          'warning': colors.feedback.warning,
          'error': colors.feedback.error,
        };
        roles.forEach((String role, IuxFeedbackRoleColors feedback) {
          expectRatio('feedback.$role content', feedback.content,
              feedback.surface, ContrastMetric.normalText);
          expectRatio('feedback.$role icon', feedback.icon, feedback.surface,
              ContrastMetric.nonText);
          expectRatio('feedback.$role border', feedback.border,
              colors.surface.base, ContrastMetric.nonText);
        });
      });

      test('focus is visible and never transparent', () {
        expect(colors.state.focus.a, 1.0);
        expectRatio('state.focus on base', colors.state.focus,
            colors.surface.base, ContrastMetric.nonText);
      });

      test('surfaces are distinguishable without a shadow', () {
        expect(
          ContrastMetric.ratio(colors.surface.subtle, colors.surface.base),
          greaterThan(1.0),
        );
      });
    });
  }

  group('high contrast strengthens rather than merely differs', () {
    test('content contrast increases in light conditions', () {
      final IuxSemanticColors standard =
          IuxTheme.resolve(const IuxThemeConfiguration()).colors;
      final IuxSemanticColors high = IuxTheme.resolve(
        const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(contrast: IuxContrast.high),
        ),
      ).colors;

      expect(
        ContrastMetric.ratio(high.content.primary, high.surface.base),
        greaterThan(
          ContrastMetric.ratio(standard.content.primary, standard.surface.base),
        ),
      );
      expect(
        ContrastMetric.ratio(high.border.standard, high.surface.base),
        greaterThan(
          ContrastMetric.ratio(standard.border.standard, standard.surface.base),
        ),
      );
    });

    test('content contrast increases in dark conditions', () {
      final IuxSemanticColors standard = IuxTheme.resolve(
        const IuxThemeConfiguration(brightness: Brightness.dark),
      ).colors;
      final IuxSemanticColors high = IuxTheme.resolve(
        const IuxThemeConfiguration(
          brightness: Brightness.dark,
          profile: IuxAccessibilityProfile(contrast: IuxContrast.high),
        ),
      ).colors;

      expect(
        ContrastMetric.ratio(high.content.primary, high.surface.base),
        greaterThan(
          ContrastMetric.ratio(standard.content.primary, standard.surface.base),
        ),
      );
    });

    test('dark stays dark under high contrast', () {
      // The defect this mission fixes: high contrast used to force a light
      // brightness, so a user needing both had no option.
      final IuxSemanticColors high = IuxTheme.resolve(
        const IuxThemeConfiguration(
          brightness: Brightness.dark,
          profile: IuxAccessibilityProfile(contrast: IuxContrast.high),
        ),
      ).colors;

      expect(
        ContrastMetric.relativeLuminance(high.surface.base),
        lessThan(0.1),
        reason: 'a dark high contrast theme must still be dark',
      );
      expect(
        ContrastMetric.relativeLuminance(high.content.primary),
        greaterThan(0.5),
      );
    });
  });
}
