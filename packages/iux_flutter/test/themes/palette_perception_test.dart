import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

import '../support/contrast.dart';
import '../support/perception.dart';

/// Measures the shipped palette with instruments WCAG does not have.
///
/// `theme_contrast_test.dart` already holds every pair to its WCAG 2.x floor,
/// and the palette passes. This file asks the two questions that floor cannot
/// answer:
///
/// 1. **Is a light role and a dark role tuned to the same ratio equally
///    legible?** WCAG's formula is symmetric — a ratio is the same number read
///    in either direction — so it cannot distinguish dark-on-light from
///    light-on-dark. APCA can, and it disagrees with WCAG most sharply exactly
///    where IUX ships two profiles tuned to the same numbers.
/// 2. **Can two roles that both pass be told apart from each other?** Nothing
///    in WCAG measures the distance between two foregrounds. That is the
///    measurement `IUX-PALETTE-HEADROOM-001` needed and did not have when it
///    recorded a user saying four roles "resembled each other more than their
///    own meanings".
///
/// The instruments live in `test/support/perception.dart` and are themselves
/// checked in `test/support/perception_test.dart`, because a number from an
/// unverified implementation is worse than no number — it looks like evidence.
/// Findings are written up in `docs/evidence/semantic-tokens-and-accessibility.md`
/// under `IUX-PALETTE-PERCEPTION-001`.
void main() {
  const List<(String, IuxThemeConfiguration)> profiles =
      <(String, IuxThemeConfiguration)>[
    ('light standard', IuxThemeConfiguration()),
    (
      'light high contrast',
      IuxThemeConfiguration(
        profile: IuxAccessibilityProfile(contrast: IuxContrast.high),
      )
    ),
    ('dark standard', IuxThemeConfiguration(brightness: Brightness.dark)),
    (
      'dark high contrast',
      IuxThemeConfiguration(
        brightness: Brightness.dark,
        profile: IuxAccessibilityProfile(contrast: IuxContrast.high),
      )
    ),
  ];

  IuxSemanticColors resolve(IuxThemeConfiguration configuration) =>
      IuxTheme.resolve(configuration).colors;

  /// The content roles, ordered as the palette intends them: most prominent
  /// first. `content.onAction` and `content.inverse` are excluded because they
  /// are not measured against `surface.base` at all.
  List<(String, Color)> contentRoles(IuxSemanticColors c) => <(String, Color)>[
        ('primary', c.content.primary),
        ('secondary', c.content.secondary),
        ('link', c.content.link),
        ('tertiary', c.content.tertiary),
        ('disabled', c.content.disabled),
      ];

  group('the two metrics agree on order and disagree on magnitude', () {
    for (final (String name, IuxThemeConfiguration configuration) in profiles) {
      test('$name ranks its content roles identically under both', () {
        // This is the reassuring half of the finding, and it is worth
        // asserting: inside one polarity, WCAG is a sound *ordering* of the
        // palette even where its absolute numbers mislead. A palette edit that
        // broke this would mean a role had moved past its neighbour in
        // perceived contrast while the ratio still said otherwise — the
        // failure mode nobody would catch by reading ratios.
        final IuxSemanticColors c = resolve(configuration);
        final Color background = c.surface.base;

        final List<(String, Color)> roles = contentRoles(c);
        final List<(String, Color)> byRatio = roles.toList()
          ..sort((a, b) => ContrastMetric.ratio(b.$2, background)
              .compareTo(ContrastMetric.ratio(a.$2, background)));
        final List<(String, Color)> byLc = roles.toList()
          ..sort((a, b) => ApcaContrast.lc(b.$2, background)
              .abs()
              .compareTo(ApcaContrast.lc(a.$2, background).abs()));

        expect(
          byLc.map((e) => e.$1).toList(),
          byRatio.map((e) => e.$1).toList(),
        );
      });
    }

    test('the same WCAG ratio buys far less contrast in the dark profile', () {
      // The finding this file exists for, stated as the smallest pair that
      // shows it. `content.disabled` and `border.standard` are both tuned to
      // very nearly 3.66:1 in the light and the dark standard profiles — a
      // deliberate match, since the same role should be equally quiet in both.
      // They are not equally quiet. Read as light-on-dark the same ratio
      // delivers well under half the perceived contrast, because WCAG's
      // formula is symmetric and perception is not.
      final IuxSemanticColors light = resolve(const IuxThemeConfiguration());
      final IuxSemanticColors dark =
          resolve(const IuxThemeConfiguration(brightness: Brightness.dark));

      final double lightRatio =
          ContrastMetric.ratio(light.border.standard, light.surface.base);
      final double darkRatio =
          ContrastMetric.ratio(dark.border.standard, dark.surface.base);
      expect(
        (lightRatio - darkRatio).abs(),
        lessThan(0.1),
        reason: 'the premise of this test is that the two profiles tuned this '
            'role to the same ratio; they now measure '
            '${lightRatio.toStringAsFixed(2)}:1 and '
            '${darkRatio.toStringAsFixed(2)}:1, so re-read the finding before '
            'trusting the assertion below',
      );

      final double lightLc =
          ApcaContrast.lc(light.border.standard, light.surface.base).abs();
      final double darkLc =
          ApcaContrast.lc(dark.border.standard, dark.surface.base).abs();
      expect(
        lightLc,
        greaterThan(darkLc * 2),
        reason: 'light Lc ${lightLc.toStringAsFixed(1)} against dark Lc '
            '${darkLc.toStringAsFixed(1)}',
      );
    });

    test(
        'a dark control outline sits below the perceptual floor it clears '
        'in WCAG', () {
      // A characterisation test, not a target: it asserts a defect that is
      // shipped today, so that changing the dark neutral ramp cannot happen
      // silently. **If this fails, the ramp moved — go and update
      // `IUX-PALETTE-PERCEPTION-001` rather than adjusting the number here.**
      //
      // `border.standard` and `border.interactive` are the outlines that
      // identify a control, governed by WCAG 2.2 SC 1.4.11 at 3:1. Both clear
      // it in the dark standard profile. Both land near Lc 27, which is under
      // the Lc 30 APCA treats as the minimum for any solid non-text element —
      // and well under the Lc 45 it asks for a one-pixel outline. The light
      // profile puts the same roles past Lc 64.
      final IuxSemanticColors dark =
          resolve(const IuxThemeConfiguration(brightness: Brightness.dark));
      for (final (String label, Color border) in <(String, Color)>[
        ('standard', dark.border.standard),
        ('interactive', dark.border.interactive),
      ]) {
        expect(
          ContrastMetric.ratio(border, dark.surface.base),
          greaterThanOrEqualTo(ContrastMetric.nonText),
          reason: 'border.$label no longer clears SC 1.4.11',
        );
        expect(
          ApcaContrast.lc(border, dark.surface.base).abs(),
          lessThan(30),
          reason: 'border.$label now measures Lc '
              '${ApcaContrast.lc(border, dark.surface.base).abs().toStringAsFixed(1)}, '
              'so the divergence this test records has been fixed — update '
              'IUX-PALETTE-PERCEPTION-001 and delete this expectation',
        );
      }
    });
  });

  group('the contrast setting raises perceived contrast, not just the ratio',
      () {
    // `IUX-PALETTE-HEADROOM-001` established a two-sided contract in WCAG
    // terms: high contrast must measure strictly higher than standard, role by
    // role rather than on average. Nothing said the same held once polarity
    // was accounted for, and in the dark pair it is the less obvious claim —
    // a light-on-dark role gains Lc more slowly than its ratio suggests.
    for (final (
          String label,
          IuxThemeConfiguration standard,
          IuxThemeConfiguration high
        ) in const <(String, IuxThemeConfiguration, IuxThemeConfiguration)>[
      (
        'light',
        IuxThemeConfiguration(),
        IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(contrast: IuxContrast.high),
        )
      ),
      (
        'dark',
        IuxThemeConfiguration(brightness: Brightness.dark),
        IuxThemeConfiguration(
          brightness: Brightness.dark,
          profile: IuxAccessibilityProfile(contrast: IuxContrast.high),
        )
      ),
    ]) {
      test('$label high contrast gains Lc on every content role', () {
        final IuxSemanticColors s = resolve(standard);
        final IuxSemanticColors h = resolve(high);
        final List<(String, Color)> standardRoles = contentRoles(s);
        final List<(String, Color)> highRoles = contentRoles(h);

        for (int i = 0; i < standardRoles.length; i++) {
          final double before =
              ApcaContrast.lc(standardRoles[i].$2, s.surface.base).abs();
          final double after =
              ApcaContrast.lc(highRoles[i].$2, h.surface.base).abs();
          expect(
            after,
            greaterThan(before),
            reason: 'content.${standardRoles[i].$1} measures Lc '
                '${before.toStringAsFixed(1)} in $label standard and '
                '${after.toStringAsFixed(1)} in $label high contrast, so the '
                'setting returns nothing on this role',
          );
        }
      });
    }
  });

  group('colour alone does not separate the feedback categories', () {
    /// The four category role sets of one profile.
    Map<String, IuxFeedbackRoleColors> categories(IuxSemanticColors c) =>
        <String, IuxFeedbackRoleColors>{
          'info': c.feedback.info,
          'success': c.feedback.success,
          'warning': c.feedback.warning,
          'error': c.feedback.error,
        };

    test('at least one pair collapses under a dichromacy in every profile', () {
      // Measured, not assumed. `IuxFeedbackRoleColors` already documents that
      // "a component must always pair these colors with an icon, wording, or
      // screen-reader semantics" — this is the number that makes that sentence
      // load-bearing rather than cautious. A separation of about 2 on this
      // scale is the smallest difference most people notice with the two
      // colours side by side; roles glanced at across a screen need tens.
      //
      // The worst pair is `success`/`error` under deuteranopia — the most
      // common dichromacy, and the pair whose confusion costs the most.
      for (final (String name, IuxThemeConfiguration configuration)
          in profiles) {
        final Map<String, IuxFeedbackRoleColors> roles =
            categories(resolve(configuration));
        double worst = double.infinity;
        String where = '';
        for (final String a in roles.keys) {
          for (final String b in roles.keys) {
            if (a.compareTo(b) >= 0) continue;
            for (final ColourVisionDeficiency d
                in ColourVisionDeficiency.values) {
              final double separation = OklabColor.fromColor(
                ColourVision.simulate(roles[a]!.content, d),
              ).distanceTo(
                OklabColor.fromColor(
                  ColourVision.simulate(roles[b]!.content, d),
                ),
              );
              if (separation < worst) {
                worst = separation;
                where = '$a/$b under ${d.name}';
              }
            }
          }
        }
        expect(
          worst,
          lessThan(8),
          reason: '$name: the closest pair is $where at '
              '${worst.toStringAsFixed(1)}. If this passes 8 the palette has '
              'become separable by colour alone — a real improvement, but the '
              'redundant channel below stays required by SC 1.4.1 regardless. '
              'Update IUX-PALETTE-PERCEPTION-001 rather than removing it.',
        );
      }
    });

    testWidgets('each category carries a distinct glyph', (tester) async {
      // The channel that does the work colour cannot. Asserted rather than
      // trusted to a doc comment, because the measurement above says a
      // deuteranope has essentially nothing else.
      final Map<IuxFeedbackCategory, IconData> glyphs =
          <IuxFeedbackCategory, IconData>{};
      await tester.pumpWidget(
        MaterialApp(
          theme: IuxTheme.fromConfiguration(const IuxThemeConfiguration()),
          home: Builder(
            builder: (BuildContext context) {
              for (final IuxFeedbackCategory category
                  in IuxFeedbackCategory.values) {
                glyphs[category] =
                    IuxInlineFeedbackResolver.resolve(context, category).glyph;
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(glyphs.length, IuxFeedbackCategory.values.length);
      expect(
        glyphs.values.toSet().length,
        glyphs.length,
        reason: 'two categories share a glyph, which leaves them separated by '
            'colour alone — and the measurement above says colour does not '
            'separate them',
      );
    });
  });

  group('colour alone does not separate the two directions either', () {
    // The measurement ADR-0013 rests on, taken here rather than quoted from
    // the feedback finding above — `ADR-0011` and `ADR-0012` each recorded a
    // number carried across a change it did not survive, and the comparison
    // roles are a change.
    //
    // The pair is warm against cool, which is the diverging pair that survives
    // the two red-green dichromacies best. It survives them; it does not
    // survive them everywhere by a margin worth relying on, and the numbers
    // below say where.
    for (final (String name, IuxThemeConfiguration configuration) in profiles) {
      test('$name keeps the two directions apart under every dichromacy', () {
        final IuxSemanticColors c = resolve(configuration);
        final OklabColor above =
            OklabColor.fromColor(c.comparison.above.content);
        final OklabColor below =
            OklabColor.fromColor(c.comparison.below.content);

        expect(
          above.distanceTo(below),
          greaterThan(2),
          reason: 'the two directions measure '
              '${above.distanceTo(below).toStringAsFixed(1)} apart with '
              'ordinary colour vision, which is at or under the smallest '
              'difference most people notice side by side',
        );

        for (final ColourVisionDeficiency deficiency
            in ColourVisionDeficiency.values) {
          final OklabColor a = OklabColor.fromColor(
            ColourVision.simulate(c.comparison.above.content, deficiency),
          );
          final OklabColor b = OklabColor.fromColor(
            ColourVision.simulate(c.comparison.below.content, deficiency),
          );
          expect(
            a.distanceTo(b),
            greaterThan(2),
            reason: 'under ${deficiency.name} the two directions measure '
                '${a.distanceTo(b).toStringAsFixed(1)} apart '
                '(${a.chromaticDistanceTo(b).toStringAsFixed(1)} of it '
                'chromatic), which is the point at which the mark is the only '
                'thing left',
          );
        }
      });
    }

    test('the dark high contrast profile is where the pair is thinnest', () {
      // A characterisation test, not a target. Buying contrast on a dark
      // ground means lightening, and a lightened hue has less chroma to
      // spend — so the profile whose job is separation is the one where these
      // two colours sit closest. **If this fails the ramps moved: re-take the
      // numbers in ADR-0013 rather than adjusting the bound here.**
      double worst(IuxThemeConfiguration configuration) {
        final IuxSemanticColors c = resolve(configuration);
        return ColourVisionDeficiency.values
            .map((ColourVisionDeficiency d) => OklabColor.fromColor(
                  ColourVision.simulate(c.comparison.above.content, d),
                ).distanceTo(OklabColor.fromColor(
                  ColourVision.simulate(c.comparison.below.content, d),
                )))
            .reduce((double a, double b) => a < b ? a : b);
      }

      final double standardDark =
          worst(const IuxThemeConfiguration(brightness: Brightness.dark));
      final double highDark = worst(
        const IuxThemeConfiguration(
          brightness: Brightness.dark,
          profile: IuxAccessibilityProfile(contrast: IuxContrast.high),
        ),
      );

      expect(
        highDark,
        lessThan(standardDark),
        reason: 'dark high contrast measures '
            '${highDark.toStringAsFixed(1)} against the standard profile\'s '
            '${standardDark.toStringAsFixed(1)}; if raising contrast has '
            'stopped costing separability, the record in ADR-0013 is out of '
            'date',
      );
      expect(
        highDark,
        lessThan(10),
        reason: 'it measures ${highDark.toStringAsFixed(1)}, which is tens '
            'rather than units — the pair is now separable enough that the '
            'argument for the mark should be re-read, not that the mark '
            'should go',
      );
    });

    testWidgets('each direction carries a distinct mark', (tester) async {
      // The channel that does the work colour cannot, and the reason the
      // measurement above is a record rather than a failure.
      final Map<IuxValueDirection, IconData> marks =
          <IuxValueDirection, IconData>{};
      await tester.pumpWidget(
        MaterialApp(
          theme: IuxTheme.fromConfiguration(const IuxThemeConfiguration()),
          home: Builder(
            builder: (BuildContext context) {
              for (final IuxValueDirection direction
                  in IuxValueDirection.values) {
                marks[direction] =
                    IuxValueResolver.resolve(context, direction).mark;
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(marks.length, IuxValueDirection.values.length);
      expect(
        marks.values.toSet().length,
        marks.length,
        reason: 'two directions share a mark, which leaves them separated by '
            'colour alone — and the measurement above says how little colour '
            'separates them in the dark profiles',
      );
    });
  });
}
