import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

import '../support/contrast.dart';
import '../support/demonstration_palettes.dart';

/// Verifies the contrast contracts documented in
/// `docs/accessibility/contrast-contracts.md` against the demonstration role
/// mappings.
///
/// Passing here does not establish WCAG conformance for an application: it
/// establishes that these specific pairs hold for these specific values.
/// Real content, real typography and real themes must be verified in context.
void main() {
  for (final (String name, IuxSemanticColors colors)
      in <(String, IuxSemanticColors)>[
    ('light', IuxDemonstrationPalettes.light),
    ('dark', IuxDemonstrationPalettes.dark),
  ]) {
    group('$name role mapping', () {
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

      test('content is readable on the surfaces it appears on', () {
        expectRatio('content.primary on surface.base', colors.content.primary,
            colors.surface.base, ContrastMetric.normalText);
        expectRatio('content.primary on surface.subtle', colors.content.primary,
            colors.surface.subtle, ContrastMetric.normalText);
        expectRatio('content.primary on surface.raised', colors.content.primary,
            colors.surface.raised, ContrastMetric.normalText);
        expectRatio(
            'content.primary on surface.overlay',
            colors.content.primary,
            colors.surface.overlay,
            ContrastMetric.normalText);
        expectRatio(
            'content.primary on surface.selected',
            colors.content.primary,
            colors.surface.selected,
            ContrastMetric.normalText);
        expectRatio(
            'content.secondary on surface.base',
            colors.content.secondary,
            colors.surface.base,
            ContrastMetric.normalText);
        expectRatio('content.tertiary on surface.base', colors.content.tertiary,
            colors.surface.base, ContrastMetric.normalText);
        expectRatio('content.link on surface.base', colors.content.link,
            colors.surface.base, ContrastMetric.normalText);
        expectRatio(
            'content.inverse on surface.inverse',
            colors.content.inverse,
            colors.surface.inverse,
            ContrastMetric.normalText);
      });

      test('disabled content stays legible above the WCAG exemption', () {
        expectRatio('content.disabled on surface.base', colors.content.disabled,
            colors.surface.base, ContrastMetric.nonText);
        expectRatio(
            'content.disabled on surface.disabled',
            colors.content.disabled,
            colors.surface.disabled,
            ContrastMetric.nonText);
      });

      test('borders that identify a control reach the non-text minimum', () {
        expectRatio('border.standard on surface.base', colors.border.standard,
            colors.surface.base, ContrastMetric.nonText);
        expectRatio('border.strong on surface.base', colors.border.strong,
            colors.surface.base, ContrastMetric.nonText);
        expectRatio(
            'border.interactive on surface.base',
            colors.border.interactive,
            colors.surface.base,
            ContrastMetric.nonText);
        expectRatio('border.focus on surface.base', colors.border.focus,
            colors.surface.base, ContrastMetric.nonText);
        expectRatio('border.error on surface.base', colors.border.error,
            colors.surface.base, ContrastMetric.nonText);
      });

      test('focus is visible and distinct from selection', () {
        expectRatio('state.focus on surface.base', colors.state.focus,
            colors.surface.base, ContrastMetric.nonText);
        expectRatio('state.focus on surface.selected', colors.state.focus,
            colors.surface.selected, 1.0);
      });

      test('every action intent is readable in every background state', () {
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
          expectRatio('feedback.$role border on surface.base', feedback.border,
              colors.surface.base, ContrastMetric.nonText);
        });
      });

      test('surface levels are distinguishable without a shadow', () {
        expect(
          ContrastMetric.ratio(colors.surface.subtle, colors.surface.base),
          greaterThan(1.0),
          reason: 'surface.subtle must differ from surface.base',
        );
        expect(
          ContrastMetric.ratio(colors.surface.inverse, colors.surface.base),
          greaterThan(ContrastMetric.normalText),
          reason: 'surface.inverse must clearly oppose surface.base',
        );
      });
    });
  }

  test('the two role mappings are genuinely different', () {
    expect(
      IuxDemonstrationPalettes.light,
      isNot(equals(IuxDemonstrationPalettes.dark)),
    );
  });
}
