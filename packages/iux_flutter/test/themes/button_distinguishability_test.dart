// Two values a caller can choose between must resolve to different results.
//
// This is the check that found IUX-039's two rendering defects, and nothing in
// the 1978 tests that preceded it asked the question. Both defects had the same
// shape and neither was visible from any single test: a public enum member
// whose resolved appearance was byte-identical to another member's.
//
//   - `IuxActionIntent.tertiary` resolved identically to `secondary` in
//     `outlined`, `tonal`, `text` and `icon`, on all four profiles. The two
//     roles differed in the semantic layer by one `border` token, and no
//     variant painted it.
//   - `IuxButtonVariant.filled` resolved identically to `text` for `tertiary`,
//     and differed from it only by that same unpainted token for `secondary`.
//     A filled secondary button was a label on the page with no container.
//
// The rule generalises: where two choices produce one result, either the API is
// lying about the difference or one of the two is dead. So the matrix is swept
// exhaustively — every profile, every legal intent/variant pair, every state —
// and every axis is required to separate. When a future member is added to any
// of these enums and resolves to something that already exists, this fails
// before it ships.
//
// The same sweep is the right place to measure contrast, because a resolved
// token is what reaches the eye: `theme_contrast_test.dart` measures the
// palette, this measures the palette *after* the resolver has chosen which
// entries of it a given button actually uses.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

import '../support/contrast.dart';

/// The four shipped role mappings, reached through the public theme engine.
const List<(String, IuxThemeConfiguration)> _profiles =
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

/// The states a caller can put a button into, as inputs rather than outputs.
///
/// `loading` is absent, and its absence is a decision rather than an oversight.
/// A running action resolves to the resting palette on purpose: what says it is
/// running is the progress indicator the button swaps in and the busy hint it
/// announces, both of which reach a screen-reader user, whereas a colour would
/// not. Including it here would demand that it differ from `enabled` and so
/// argue for exactly the colour-only status signal the component standard
/// refuses — the same argument that removed `IuxButtonState.success`/`.error`
/// in IUX-038.
enum _Interaction { resting, hovered, pressed, unavailable }

/// Whether a caller may ask for [variant] on [intent].
///
/// Two cells are refused by `IuxButtonResolver`, each for its own reason, and
/// they are excluded here rather than expected to differ: an assertion is a
/// different answer from a duplicate, and it is the correct one.
bool _isLegal(IuxActionIntent intent, IuxButtonVariant variant) {
  if (variant == IuxButtonVariant.tonal &&
      intent == IuxActionIntent.destructive) {
    return false;
  }
  if (variant == IuxButtonVariant.filled &&
      (intent == IuxActionIntent.secondary ||
          intent == IuxActionIntent.tertiary)) {
    return false;
  }
  return true;
}

IuxActionDescriptor _action(IuxActionIntent intent, _Interaction interaction) =>
    IuxActionDescriptor(
      semantics: const IuxActionSemantics(label: 'Act'),
      intent: intent,
      availability: interaction == _Interaction.unavailable
          ? IuxActionAvailability.disabled
          : IuxActionAvailability.enabled,
    );

/// Everything a caller can distinguish about a resolved button.
///
/// Compared as a record rather than through `IuxButtonTokens ==`, so a failure
/// names the field that collapsed instead of saying "not equal".
({
  Color background,
  Color foreground,
  Color border,
  double width,
  EdgeInsets padding
}) _shape(IuxButtonTokens tokens) => (
      background: tokens.background,
      foreground: tokens.foreground,
      border: tokens.border,
      width: tokens.borderWidth,
      padding: tokens.padding,
    );

void main() {
  Future<IuxButtonTokens> resolve(
    WidgetTester tester, {
    required IuxThemeConfiguration configuration,
    required IuxActionIntent intent,
    required IuxButtonVariant variant,
    required _Interaction interaction,
  }) async {
    late IuxButtonTokens tokens;
    await tester.pumpWidget(
      MaterialApp(
        theme: IuxTheme.fromConfiguration(configuration),
        home: Builder(
          builder: (BuildContext context) {
            tokens = IuxButtonResolver.resolve(
              context,
              _action(intent, interaction),
              variant: variant,
              hovered: interaction == _Interaction.hovered,
              pressed: interaction == _Interaction.pressed,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    return tokens;
  }

  for (final (String profile, IuxThemeConfiguration configuration)
      in _profiles) {
    group(profile, () {
      testWidgets('no two intents resolve to the same button',
          (WidgetTester tester) async {
        // The defect this file exists for. `tertiary` was a public enum member
        // that produced, in every variant a caller could reach it through, the
        // pixels of `secondary`.
        //
        // Every collision is collected before failing, rather than throwing on
        // the first: a sweep that stops at one cell tells you about one cell,
        // and the point of a sweep is the shape of what it finds.
        //
        // `unavailable` is excluded on purpose and pinned separately below: an
        // action that cannot be performed has no meaning left to express, and
        // every intent has deliberately shared one disabled palette since the
        // semantic layer was written.
        final List<String> collisions = <String>[];
        for (final IuxButtonVariant variant in IuxButtonVariant.values) {
          for (final _Interaction interaction in _Interaction.values) {
            if (interaction == _Interaction.unavailable) continue;
            final Map<IuxActionIntent, Object> seen =
                <IuxActionIntent, Object>{};
            for (final IuxActionIntent intent in IuxActionIntent.values) {
              if (!_isLegal(intent, variant)) continue;
              final Object shape = _shape(await resolve(
                tester,
                configuration: configuration,
                intent: intent,
                variant: variant,
                interaction: interaction,
              ));
              for (final MapEntry<IuxActionIntent, Object> other
                  in seen.entries) {
                if (shape == other.value) {
                  collisions.add('${intent.name} == ${other.key.name} '
                      '(${variant.name}, ${interaction.name})');
                }
              }
              seen[intent] = shape;
            }
          }
        }

        expect(
          collisions,
          isEmpty,
          reason: 'in $profile, a caller who chooses between two intents '
              'receives one appearance. The difference the enum promises does '
              'not exist (PROJECT_PROMPT §19). Either give the intent a '
              'resolved difference, or take it out of the enum.',
        );
      });

      testWidgets('no two variants resolve to the same button',
          (WidgetTester tester) async {
        // The other half of IUX-039's rendering pair: `filled` on a secondary
        // or tertiary action was accepted and produced a text button. That
        // combination is now refused rather than duplicated, which is why
        // `_isLegal` skips it — a refusal is a different answer, not the same
        // one twice.
        //
        // `unavailable` is excluded for the same reason as in the intent
        // sweep, and pinned below: outlined and tonal are one appearance once
        // a control cannot be used, because the disabled palette is a
        // statement about availability rather than about emphasis.
        final List<String> collisions = <String>[];
        for (final IuxActionIntent intent in IuxActionIntent.values) {
          for (final _Interaction interaction in _Interaction.values) {
            if (interaction == _Interaction.unavailable) continue;
            final Map<IuxButtonVariant, Object> seen =
                <IuxButtonVariant, Object>{};
            for (final IuxButtonVariant variant in IuxButtonVariant.values) {
              if (!_isLegal(intent, variant)) continue;
              final Object shape = _shape(await resolve(
                tester,
                configuration: configuration,
                intent: intent,
                variant: variant,
                interaction: interaction,
              ));
              for (final MapEntry<IuxButtonVariant, Object> other
                  in seen.entries) {
                if (shape == other.value) {
                  collisions.add('${variant.name} == ${other.key.name} '
                      '(${intent.name}, ${interaction.name})');
                }
              }
              seen[variant] = shape;
            }
          }
        }

        expect(
          collisions,
          isEmpty,
          reason: 'in $profile, two variants resolve to one button. A variant '
              'is a promise about emphasis; two variants with one appearance '
              'means one of them is not kept (PROJECT_PROMPT §19).',
        );
      });

      testWidgets('no two interaction states resolve to the same button',
          (WidgetTester tester) async {
        // Activation feedback is the case where a duplicate is not merely
        // misleading: a control that looks identical pressed and resting gives
        // the user no way to tell that their tap registered.
        final List<String> collisions = <String>[];
        for (final IuxActionIntent intent in IuxActionIntent.values) {
          for (final IuxButtonVariant variant in IuxButtonVariant.values) {
            if (!_isLegal(intent, variant)) continue;
            final Map<_Interaction, Object> seen = <_Interaction, Object>{};
            for (final _Interaction interaction in _Interaction.values) {
              final Object shape = _shape(await resolve(
                tester,
                configuration: configuration,
                intent: intent,
                variant: variant,
                interaction: interaction,
              ));
              for (final MapEntry<_Interaction, Object> other in seen.entries) {
                if (shape == other.value) {
                  collisions.add('${interaction.name} == ${other.key.name} '
                      '(${intent.name}, ${variant.name})');
                }
              }
              seen[interaction] = shape;
            }
          }
        }

        expect(
          collisions,
          isEmpty,
          reason: 'in $profile, a button looks the same in two states a user '
              'can put it in. Activation feedback that does not change is '
              'activation feedback the user never receives.',
        );
      });

      testWidgets('every resolved button is readable, and its outline visible',
          (WidgetTester tester) async {
        // `theme_contrast_test.dart` measures the palette. This measures what
        // the resolver made of it: a pairing can be safe in the table and
        // unsafe once a variant has chosen which entries to combine, which is
        // how a white label on a white surface reached the tree once already.
        //
        // Unavailable controls are exempt from both minima under WCAG 2.2
        // (SC 1.4.3 and SC 1.4.11 exclude inactive user interface components),
        // and the disabled palette is measured at the non-text ratio by
        // `theme_contrast_test.dart` regardless.
        final IuxSemanticColors colors = IuxTheme.resolve(configuration).colors;

        for (final IuxActionIntent intent in IuxActionIntent.values) {
          for (final IuxButtonVariant variant in IuxButtonVariant.values) {
            if (!_isLegal(intent, variant)) continue;
            for (final _Interaction interaction in _Interaction.values) {
              if (interaction == _Interaction.unavailable) continue;
              final IuxButtonTokens tokens = await resolve(
                tester,
                configuration: configuration,
                intent: intent,
                variant: variant,
                interaction: interaction,
              );
              final String where = '${intent.name} ${variant.name} '
                  '${interaction.name}, $profile';

              final double label = ContrastMetric.ratio(
                tokens.foreground,
                tokens.background,
              );
              expect(
                label,
                greaterThanOrEqualTo(ContrastMetric.normalText),
                reason: '$where: the label measured '
                    '${label.toStringAsFixed(2)}:1 on its own container, below '
                    'the ${ContrastMetric.normalText}:1 WCAG 2.2 SC 1.4.3 asks '
                    'for',
              );

              if (tokens.borderWidth > 0) {
                final double outline = ContrastMetric.ratio(
                  tokens.border,
                  colors.surface.base,
                );
                expect(
                  outline,
                  greaterThanOrEqualTo(ContrastMetric.nonText),
                  reason: '$where: the outline measured '
                      '${outline.toStringAsFixed(2)}:1 against the page, below '
                      'the ${ContrastMetric.nonText}:1 WCAG 2.2 SC 1.4.11 asks '
                      'of the boundary that identifies a control',
                );
              }
            }
          }
        }
      });

      testWidgets('an unavailable action looks the same whatever it meant',
          (WidgetTester tester) async {
        // Pinned rather than left implicit, because it is the one place the
        // sweep above deliberately does not look. A control that cannot be
        // used has no intent left to express: showing a destructive deletion
        // and a tertiary dismissal as different shades of unavailable would
        // offer a distinction the user cannot act on. If a future mission
        // wants per-intent disabled colours, this test is where it argues for
        // them.
        for (final IuxButtonVariant variant in <IuxButtonVariant>[
          IuxButtonVariant.outlined,
          IuxButtonVariant.text,
        ]) {
          final List<Object> shapes = <Object>[];
          for (final IuxActionIntent intent in IuxActionIntent.values) {
            shapes.add(_shape(await resolve(
              tester,
              configuration: configuration,
              intent: intent,
              variant: variant,
              interaction: _Interaction.unavailable,
            )));
          }
          expect(
            shapes.toSet(),
            hasLength(1),
            reason: 'the disabled palette is shared across intents on purpose; '
                'if that changed, the sweep above must stop skipping it',
          );
        }
      });
    });
  }

  group('the sweep can tell two buttons apart', () {
    // Every assertion above is `isNot`, which is the shape that passes when the
    // comparison is broken — six vacuous tests have been found in this project
    // and two of them were assertions that could not fail. So prove the
    // comparison detects a difference, and prove it detects a *sameness*: an
    // `isNot` sweep over a `_shape` that returned a constant would pass every
    // profile and mean nothing.
    testWidgets('it separates two buttons that genuinely differ',
        (WidgetTester tester) async {
      final IuxButtonTokens filled = await _tokens(
        tester,
        intent: IuxActionIntent.primary,
        variant: IuxButtonVariant.filled,
      );
      final IuxButtonTokens text = await _tokens(
        tester,
        intent: IuxActionIntent.primary,
        variant: IuxButtonVariant.text,
      );
      expect(_shape(filled), isNot(_shape(text)));
    });

    testWidgets('it reports two identical buttons as identical',
        (WidgetTester tester) async {
      final IuxButtonTokens once = await _tokens(
        tester,
        intent: IuxActionIntent.tertiary,
        variant: IuxButtonVariant.text,
      );
      final IuxButtonTokens twice = await _tokens(
        tester,
        intent: IuxActionIntent.tertiary,
        variant: IuxButtonVariant.text,
      );
      expect(_shape(once), _shape(twice));
    });
  });
}

Future<IuxButtonTokens> _tokens(
  WidgetTester tester, {
  required IuxActionIntent intent,
  required IuxButtonVariant variant,
}) async {
  late IuxButtonTokens tokens;
  await tester.pumpWidget(
    MaterialApp(
      theme: IuxTheme.fromConfiguration(const IuxThemeConfiguration()),
      home: Builder(
        builder: (BuildContext context) {
          tokens = IuxButtonResolver.resolve(
            context,
            _action(intent, _Interaction.resting),
            variant: variant,
          );
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tokens;
}
