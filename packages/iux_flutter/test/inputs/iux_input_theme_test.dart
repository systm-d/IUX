import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

import '../support/contrast.dart';

void main() {
  const IuxInputSemantics label = IuxInputSemantics(label: 'Email address');
  const IuxInputDescriptor field = IuxInputDescriptor(semantics: label);

  /// The descriptor and pointer position that produce each visual state.
  Map<IuxInputState, (IuxInputDescriptor, bool)> scenarios() =>
      <IuxInputState, (IuxInputDescriptor, bool)>{
        IuxInputState.enabled: (field, false),
        IuxInputState.hovered: (field, true),
        IuxInputState.readOnly: (
          field.copyWith(availability: IuxInputAvailability.readOnly),
          false,
        ),
        IuxInputState.disabled: (
          field.copyWith(availability: IuxInputAvailability.disabled),
          false,
        ),
        IuxInputState.validating: (
          field.copyWith(validation: const IuxInputValidation.validating()),
          false,
        ),
        IuxInputState.valid: (
          field.copyWith(validation: const IuxInputValidation.valid()),
          false,
        ),
        IuxInputState.invalid: (
          field.copyWith(
            validation:
                const IuxInputValidation.invalid('Enter a full address'),
          ),
          false,
        ),
      };

  Future<IuxInputTokens> resolve(
    WidgetTester tester, {
    required IuxInputDescriptor input,
    IuxInputVariant? variant,
    bool hovered = false,
    bool focused = false,
    IuxThemeConfiguration configuration = const IuxThemeConfiguration(),
    IuxInputTheme? inputTheme,
  }) async {
    final ThemeData base = IuxTheme.fromConfiguration(configuration);
    // The input theme is not installed by the theme engine yet, so a test that
    // needs a non-default one adds it alongside the resolved extensions.
    final List<ThemeExtension<dynamic>> extensions =
        base.extensions.values.toList();
    if (inputTheme != null) extensions.add(inputTheme);

    late IuxInputTokens tokens;
    await tester.pumpWidget(
      MaterialApp(
        theme: base.copyWith(extensions: extensions),
        home: Builder(
          builder: (BuildContext context) {
            tokens = IuxInputResolver.resolve(
              context,
              input,
              variant: variant,
              hovered: hovered,
              focused: focused,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    return tokens;
  }

  group('state precedence is decided once', () {
    test('disabled outranks everything', () {
      expect(
        IuxInputStateResolver.resolve(
          field.copyWith(
            availability: IuxInputAvailability.disabled,
            validation: const IuxInputValidation.validating(),
          ),
          hovered: true,
        ),
        IuxInputState.disabled,
      );
    });

    test('a validation result outranks read-only', () {
      // Read-onlyness is already carried by the absence of a caret and by
      // semantics, so it must not be what hides an error.
      expect(
        IuxInputStateResolver.resolve(
          field.copyWith(
            availability: IuxInputAvailability.readOnly,
            validation: const IuxInputValidation.invalid('No longer accepted'),
          ),
        ),
        IuxInputState.invalid,
      );
    });

    test('read-only outranks a pointer resting on the field', () {
      // Hovering must not make an uneditable field look editable.
      expect(
        IuxInputStateResolver.resolve(
          field.copyWith(availability: IuxInputAvailability.readOnly),
          hovered: true,
        ),
        IuxInputState.readOnly,
      );
    });

    test('a pending check is rendered as pending, not as an error', () {
      expect(
        IuxInputStateResolver.resolve(
          field.copyWith(validation: const IuxInputValidation.validating()),
        ),
        IuxInputState.validating,
      );
    });

    test('every state is reachable', () {
      final Set<IuxInputState> reached = <IuxInputState>{
        for (final (IuxInputDescriptor, bool) scenario in scenarios().values)
          IuxInputStateResolver.resolve(scenario.$1, hovered: scenario.$2),
      };
      expect(reached, hasLength(IuxInputState.values.length));
    });

    test('each scenario resolves to the state it claims', () {
      scenarios().forEach(
        (IuxInputState expected, (IuxInputDescriptor, bool) scenario) {
          expect(
            IuxInputStateResolver.resolve(scenario.$1, hovered: scenario.$2),
            expected,
          );
        },
      );
    });
  });

  group('focus survives every other state', () {
    testWidgets('the ring is requested even on a field showing an error',
        (WidgetTester tester) async {
      // A field showing an error is exactly the field a keyboard user is about
      // to correct, so losing the ring there loses their place.
      for (final MapEntry<IuxInputState, (IuxInputDescriptor, bool)> entry
          in scenarios().entries) {
        if (entry.key == IuxInputState.disabled) continue;
        final IuxInputTokens tokens = await resolve(
          tester,
          input: entry.value.$1,
          hovered: entry.value.$2,
          focused: true,
        );
        expect(tokens.focused, isTrue, reason: '${tokens.state} lost focus');
      }
    });
  });

  group('an error is never carried by colour alone', () {
    testWidgets('the invalid outline is thicker than any other',
        (WidgetTester tester) async {
      final IuxInputTokens resting = await resolve(tester, input: field);
      final IuxInputTokens invalid = await resolve(
        tester,
        input: field.copyWith(
          validation: const IuxInputValidation.invalid('Enter a full address'),
        ),
      );
      expect(invalid.borderWidth, greaterThan(resting.borderWidth));
    });

    testWidgets('an invalid field keeps its ordinary fill',
        (WidgetTester tester) async {
      // A red container would put the error in the one channel a user with a
      // colour-vision deficiency cannot read, and would drag the contrast of
      // the value they are trying to fix down with it.
      final IuxInputTokens resting = await resolve(tester, input: field);
      final IuxInputTokens invalid = await resolve(
        tester,
        input: field.copyWith(
          validation: const IuxInputValidation.invalid('Enter a full address'),
        ),
      );
      expect(invalid.background, resting.background);
    });

    test('the model refuses an invalid value with no message', () {
      expect(() => IuxInputValidation.invalid(''), throwsAssertionError);
    });
  });

  group('contradictions fail loudly', () {
    testWidgets('an error on a disabled field is refused',
        (WidgetTester tester) async {
      // The user would be told something is wrong and given no way to fix it.
      await tester.pumpWidget(
        MaterialApp(
          theme: IuxTheme.light(),
          home: Builder(
            builder: (BuildContext context) {
              IuxInputResolver.resolve(
                context,
                const IuxInputDescriptor(
                  semantics: label,
                  availability: IuxInputAvailability.disabled,
                  validation: IuxInputValidation.invalid('Enter an address'),
                ),
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(tester.takeException(), isA<AssertionError>());
    });
  });

  group('colour resolution never hardcodes and always contrasts', () {
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
        const IuxThemeConfiguration(brightness: Brightness.dark)
      ),
      (
        'dark high contrast',
        const IuxThemeConfiguration(
          brightness: Brightness.dark,
          profile: IuxAccessibilityProfile(contrast: IuxContrast.high),
        )
      ),
    ];

    testWidgets('the value and the placeholder stay readable everywhere',
        (WidgetTester tester) async {
      for (final (String name, IuxThemeConfiguration configuration)
          in profiles) {
        for (final IuxInputVariant variant in IuxInputVariant.values) {
          for (final MapEntry<IuxInputState, (IuxInputDescriptor, bool)> entry
              in scenarios().entries) {
            final IuxInputTokens tokens = await resolve(
              tester,
              input: entry.value.$1,
              hovered: entry.value.$2,
              variant: variant,
              configuration: configuration,
            );
            // A field the user cannot fill is still a field they have to read;
            // IUX holds 3:1 there rather than taking the WCAG exemption.
            final double threshold = entry.key == IuxInputState.disabled
                ? ContrastMetric.nonText
                : ContrastMetric.normalText;
            for (final (String role, TextStyle style) in <(String, TextStyle)>[
              ('value', tokens.valueStyle),
              ('placeholder', tokens.placeholderStyle),
            ]) {
              final double measured = ContrastMetric.ratio(
                style.color!,
                tokens.background,
              );
              expect(
                measured,
                greaterThanOrEqualTo(threshold),
                reason: '$role on ${entry.key.name}/${variant.name} in $name '
                    'measured ${measured.toStringAsFixed(2)}:1',
              );
            }
          }
        }
      }
    });

    testWidgets('the label, the help and the message stay readable',
        (WidgetTester tester) async {
      for (final (String name, IuxThemeConfiguration configuration)
          in profiles) {
        final Color page = IuxTheme.resolve(configuration).colors.surface.base;
        for (final MapEntry<IuxInputState, (IuxInputDescriptor, bool)> entry
            in scenarios().entries) {
          final IuxInputTokens tokens = await resolve(
            tester,
            input: entry.value.$1,
            hovered: entry.value.$2,
            configuration: configuration,
          );
          final double threshold = entry.key == IuxInputState.disabled
              ? ContrastMetric.nonText
              : ContrastMetric.normalText;
          for (final (String role, TextStyle style) in <(String, TextStyle)>[
            ('label', tokens.labelStyle),
            ('help', tokens.helpStyle),
            ('message', tokens.messageStyle),
          ]) {
            final double measured = ContrastMetric.ratio(style.color!, page);
            expect(
              measured,
              greaterThanOrEqualTo(threshold),
              reason: '$role on ${entry.key.name} in $name measured '
                  '${measured.toStringAsFixed(2)}:1 against the page',
            );
          }
        }
      }
    });

    testWidgets('the outline identifies the control on every profile',
        (WidgetTester tester) async {
      for (final (String name, IuxThemeConfiguration configuration)
          in profiles) {
        final Color page = IuxTheme.resolve(configuration).colors.surface.base;
        for (final MapEntry<IuxInputState, (IuxInputDescriptor, bool)> entry
            in scenarios().entries) {
          // WCAG 2.2 SC 1.4.11 exempts an inactive control, and the disabled
          // field is identified by its fill, its label and its semantics.
          if (entry.key == IuxInputState.disabled) continue;
          final IuxInputTokens tokens = await resolve(
            tester,
            input: entry.value.$1,
            hovered: entry.value.$2,
            configuration: configuration,
          );
          final double measured = ContrastMetric.ratio(tokens.border, page);
          expect(
            measured,
            greaterThanOrEqualTo(ContrastMetric.nonText),
            reason: 'the ${entry.key.name} outline in $name measured '
                '${measured.toStringAsFixed(2)}:1',
          );
        }
      }
    });
  });

  group('read-only is not disabled', () {
    testWidgets('a read-only field keeps full-strength content',
        (WidgetTester tester) async {
      // It is still information the user has to read; only the caret is gone.
      final IuxInputTokens readOnly = await resolve(
        tester,
        input: field.copyWith(availability: IuxInputAvailability.readOnly),
      );
      final IuxInputTokens disabled = await resolve(
        tester,
        input: field.copyWith(availability: IuxInputAvailability.disabled),
      );
      expect(readOnly.valueStyle.color, isNot(disabled.valueStyle.color));
      expect(readOnly.border, isNot(disabled.border));
    });

    testWidgets('it asks for the recessed surface, not the interactive one',
        (WidgetTester tester) async {
      // The two roles are distinct; the four shipped palettes happen to map
      // `subtle` and `interactive` to the same value, so in the filled variant
      // the fill alone does not separate them today. Pinning the role rather
      // than the colour keeps the intent correct for a theme that does
      // separate them, and keeps this test honest about what is guaranteed.
      final IuxSemanticColors colors =
          IuxTheme.resolve(const IuxThemeConfiguration()).colors;
      final IuxInputTokens readOnly = await resolve(
        tester,
        input: field.copyWith(availability: IuxInputAvailability.readOnly),
      );
      final IuxInputTokens editable = await resolve(
        tester,
        input: field,
        variant: IuxInputVariant.filled,
      );
      expect(readOnly.background, colors.surface.subtle);
      expect(editable.background, colors.surface.interactive);
    });
  });

  group('geometry follows the theme, never a literal', () {
    testWidgets('the target floor is respected on every profile',
        (WidgetTester tester) async {
      for (final IuxThemeConfiguration configuration in <IuxThemeConfiguration>[
        const IuxThemeConfiguration(),
        const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(density: IuxDensity.compact),
        ),
        const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(
            touchTarget: IuxTouchTargetPreference.comfortable,
          ),
        ),
      ]) {
        final IuxInputTokens tokens = await resolve(
          tester,
          input: field,
          configuration: configuration,
        );
        expect(
          tokens.minimumSize,
          greaterThanOrEqualTo(IuxTouchTarget.minimum),
          reason: 'density tightens spacing, never the target',
        );
      }
    });

    testWidgets('high contrast thickens the outline rather than recolouring it',
        (WidgetTester tester) async {
      final IuxInputTokens standard = await resolve(tester, input: field);
      final IuxInputTokens high = await resolve(
        tester,
        input: field,
        configuration: const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(contrast: IuxContrast.high),
        ),
      );
      expect(high.borderWidth, greaterThan(standard.borderWidth));
    });

    testWidgets('the padding needs no right-to-left special case',
        (WidgetTester tester) async {
      // Symmetric horizontal padding mirrors itself. An asymmetric one would
      // put the breathing room on the wrong side of an Arabic or Hebrew
      // layout, which is the defect nobody notices until a user reports it.
      final IuxInputTokens tokens = await resolve(tester, input: field);
      expect(tokens.padding.left, tokens.padding.right);
    });

    testWidgets('the radius comes from the foundation shape scale',
        (WidgetTester tester) async {
      final IuxInputTokens square = await resolve(
        tester,
        input: field,
        inputTheme: const IuxInputTheme(shape: IuxShape.none),
      );
      final IuxInputTokens rounded = await resolve(
        tester,
        input: field,
        inputTheme: const IuxInputTheme(shape: IuxShape.full),
      );
      expect(square.radius, 0);
      expect(rounded.radius, double.infinity);
    });
  });

  group('the theme extension behaves as a value', () {
    test('the default variant does not rely on a nearly invisible fill', () {
      const IuxInputTheme theme = IuxInputTheme();
      expect(theme.variant, IuxInputVariant.outlined);
      expect(theme.shape, IuxShape.medium);
    });

    test('copyWith and equality cover every field', () {
      const IuxInputTheme base = IuxInputTheme();
      expect(base.copyWith(), equals(base));
      expect(base.copyWith(shape: IuxShape.subtle).shape, IuxShape.subtle);
      expect(
        base.copyWith(variant: IuxInputVariant.filled),
        isNot(equals(base)),
      );
      expect(base.hashCode, const IuxInputTheme().hashCode);
    });

    test('categorical fields never land between two values', () {
      const IuxInputTheme a = IuxInputTheme();
      const IuxInputTheme b = IuxInputTheme(variant: IuxInputVariant.filled);
      for (final double t in <double>[0, 0.25, 0.5, 0.75, 1]) {
        expect(
          a.lerp(b, t).variant,
          anyOf(IuxInputVariant.outlined, IuxInputVariant.filled),
        );
      }
      expect(a.lerp(null, 0.5), same(a));
    });

    testWidgets('a field without an explicit input theme still resolves',
        (WidgetTester tester) async {
      late IuxInputTheme resolved;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              resolved = IuxInputTheme.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(resolved, const IuxInputTheme());
    });

    test('a configuration implies a usable input theme', () {
      expect(const IuxThemeConfiguration().inputTheme, const IuxInputTheme());
    });

    testWidgets('an installed theme supplies the default variant',
        (WidgetTester tester) async {
      final IuxInputTokens tokens = await resolve(
        tester,
        input: field,
        inputTheme: const IuxInputTheme(variant: IuxInputVariant.filled),
      );
      final IuxInputTokens outlined = await resolve(
        tester,
        input: field,
        variant: IuxInputVariant.outlined,
        inputTheme: const IuxInputTheme(variant: IuxInputVariant.filled),
      );
      expect(tokens.background, isNot(equals(outlined.background)));
    });
  });

  group('tokens are a value type', () {
    testWidgets('identical inputs resolve equal', (WidgetTester tester) async {
      final IuxInputTokens a = await resolve(tester, input: field);
      final IuxInputTokens b = await resolve(tester, input: field);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    testWidgets('a different state resolves differently',
        (WidgetTester tester) async {
      final IuxInputTokens enabled = await resolve(tester, input: field);
      final IuxInputTokens disabled = await resolve(
        tester,
        input: field.copyWith(availability: IuxInputAvailability.disabled),
      );
      expect(enabled, isNot(equals(disabled)));
    });
  });
}
