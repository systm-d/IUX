import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

import '../support/contrast.dart';

void main() {
  const IuxActionSemantics label = IuxActionSemantics(label: 'Save');

  Future<IuxButtonTokens> resolve(
    WidgetTester tester, {
    required IuxActionDescriptor action,
    IuxButtonVariant variant = IuxButtonVariant.filled,
    bool hovered = false,
    bool pressed = false,
    IuxThemeConfiguration configuration = const IuxThemeConfiguration(),
  }) async {
    late IuxButtonTokens tokens;
    await tester.pumpWidget(
      MaterialApp(
        theme: IuxTheme.fromConfiguration(configuration),
        home: Builder(
          builder: (BuildContext context) {
            tokens = IuxButtonResolver.resolve(
              context,
              action,
              variant: variant,
              hovered: hovered,
              pressed: pressed,
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
    const IuxActionDescriptor idle = IuxActionDescriptor(semantics: label);

    test('disabled outranks everything', () {
      expect(
        IuxButtonStateResolver.resolve(
          idle.copyWith(availability: IuxActionAvailability.disabled),
          hovered: true,
          pressed: true,
        ),
        IuxButtonState.disabled,
      );
    });

    test('loading outranks pressed', () {
      expect(
        IuxButtonStateResolver.resolve(
          idle.copyWith(operation: IuxActionOperation.inProgress),
          pressed: true,
        ),
        IuxButtonState.loading,
      );
    });

    test('pressed outranks a result, so a tap always registers', () {
      expect(
        IuxButtonStateResolver.resolve(
          idle.copyWith(operation: IuxActionOperation.failed),
          pressed: true,
        ),
        IuxButtonState.pressed,
      );
    });

    test('a settled result does not outrank a pointer position', () {
      // Flipped at IUX-038 (IUX-BUTTON-DEAD-001). It used to, and the rung was
      // never worth what it cost: `error` and `success` resolved to the resting
      // palette, so outranking `hovered` only meant a settled button stopped
      // answering the pointer. The operation still exists on the descriptor;
      // it is the button's unpainted mirror of it that is gone.
      expect(
        IuxButtonStateResolver.resolve(
          idle.copyWith(operation: IuxActionOperation.failed),
          hovered: true,
        ),
        IuxButtonState.hovered,
      );
      expect(
        IuxButtonStateResolver.resolve(
          idle.copyWith(operation: IuxActionOperation.succeeded),
          hovered: true,
        ),
        IuxButtonState.hovered,
      );
    });

    test('a finished operation resolves to plain enabled', () {
      for (final IuxActionOperation settled in <IuxActionOperation>[
        IuxActionOperation.succeeded,
        IuxActionOperation.failed,
      ]) {
        expect(
          IuxButtonStateResolver.resolve(idle.copyWith(operation: settled)),
          IuxButtonState.enabled,
        );
      }
    });

    test('every state is reachable', () {
      final Set<IuxButtonState> reached = <IuxButtonState>{
        IuxButtonStateResolver.resolve(idle),
        IuxButtonStateResolver.resolve(idle, hovered: true),
        IuxButtonStateResolver.resolve(idle, pressed: true),
        IuxButtonStateResolver.resolve(
            idle.copyWith(availability: IuxActionAvailability.disabled)),
        IuxButtonStateResolver.resolve(
            idle.copyWith(operation: IuxActionOperation.inProgress)),
      };
      expect(reached, hasLength(IuxButtonState.values.length));
    });
  });

  group('focus survives every other state', () {
    testWidgets('the ring is drawn even while pressed or loading',
        (WidgetTester tester) async {
      // A design where pressing hides the focus ring is one a keyboard user
      // loses their place in.
      //
      // Rewritten at IUX-038. This used to read `IuxButtonTokens.focused`,
      // which no button ever set — so it asserted a value the test itself had
      // just passed in, and would have gone on passing with the focus ring
      // deleted. It now measures the ring the user would actually see, on a
      // real focused button.
      final FocusNode node = FocusNode(debugLabel: 'ring');
      addTearDown(node.dispose);

      for (final IuxActionOperation operation in <IuxActionOperation>[
        IuxActionOperation.idle,
        IuxActionOperation.inProgress,
        IuxActionOperation.failed,
        IuxActionOperation.succeeded,
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: IuxTheme.light(),
            home: Scaffold(
              body: Center(
                child: IuxButton(
                  label: 'Save',
                  focusNode: node,
                  busyHint: 'Saving',
                  action: IuxActionDescriptor(
                    semantics: label,
                    operation: operation,
                  ),
                  onActivate: () {},
                ),
              ),
            ),
          ),
        );
        node.requestFocus();
        await tester.pumpAndSettle();
        // Held down, so the press state is live at the moment we measure.
        final TestGesture press =
            await tester.startGesture(tester.getCenter(find.byType(IuxButton)));
        await tester.pumpAndSettle();

        expect(
          tester.widget<IuxFocusRing>(find.byType(IuxFocusRing)).focused,
          isTrue,
          reason: 'a $operation button being pressed lost its focus ring',
        );

        await press.up();
        await tester.pumpAndSettle();
      }
    });
  });

  group('colour resolution never hardcodes and always contrasts', () {
    testWidgets('every variant and intent stays readable on every profile',
        (WidgetTester tester) async {
      for (final IuxThemeConfiguration configuration in <IuxThemeConfiguration>[
        const IuxThemeConfiguration(),
        const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(contrast: IuxContrast.high),
        ),
        const IuxThemeConfiguration(brightness: Brightness.dark),
        const IuxThemeConfiguration(
          brightness: Brightness.dark,
          profile: IuxAccessibilityProfile(contrast: IuxContrast.high),
        ),
      ]) {
        for (final IuxButtonVariant variant in IuxButtonVariant.values) {
          for (final IuxActionIntent intent in IuxActionIntent.values) {
            // Two pairs are refused by design; both are covered separately.
            // Tonal carries intent through its border, which is not enough
            // separation for a destructive action; and secondary and tertiary
            // have no fill for `filled` to draw.
            if (variant == IuxButtonVariant.tonal &&
                intent == IuxActionIntent.destructive) {
              continue;
            }
            if (variant == IuxButtonVariant.filled &&
                (intent == IuxActionIntent.secondary ||
                    intent == IuxActionIntent.tertiary)) {
              continue;
            }
            for (final bool pressed in <bool>[false, true]) {
              final IuxButtonTokens tokens = await resolve(
                tester,
                action: IuxActionDescriptor(semantics: label, intent: intent),
                variant: variant,
                pressed: pressed,
                configuration: configuration,
              );
              final double ratio = ContrastMetric.ratio(
                tokens.foreground,
                tokens.background,
              );
              expect(
                ratio,
                greaterThanOrEqualTo(ContrastMetric.normalText),
                reason: '${variant.name}/${intent.name}/'
                    '${pressed ? "pressed" : "resting"} on '
                    '$configuration measured ${ratio.toStringAsFixed(2)}:1',
              );
            }
          }
        }
      }
    });

    testWidgets('disabled stays legible above the WCAG exemption',
        (WidgetTester tester) async {
      final IuxButtonTokens tokens = await resolve(
        tester,
        action: const IuxActionDescriptor(
          semantics: label,
          intent: IuxActionIntent.primary,
          availability: IuxActionAvailability.disabled,
        ),
      );
      expect(
        ContrastMetric.ratio(tokens.foreground, tokens.background),
        greaterThanOrEqualTo(ContrastMetric.nonText),
      );
    });

    testWidgets('a disabled filled button keeps an outline',
        (WidgetTester tester) async {
      // Its fill sits close to the surface behind it, so without an outline
      // the control stops being identifiable as a control.
      final IuxButtonTokens tokens = await resolve(
        tester,
        action: const IuxActionDescriptor(
          semantics: label,
          intent: IuxActionIntent.primary,
          availability: IuxActionAvailability.disabled,
        ),
      );
      expect(tokens.borderWidth, greaterThan(0));
    });
  });

  group('variants differ where it matters', () {
    testWidgets('outlined and text carry no fill of their own',
        (WidgetTester tester) async {
      const IuxActionDescriptor action = IuxActionDescriptor(
        semantics: label,
        intent: IuxActionIntent.primary,
      );
      final IuxButtonTokens filled = await resolve(
        tester,
        action: action,
        variant: IuxButtonVariant.filled,
      );
      final IuxButtonTokens outlined = await resolve(
        tester,
        action: action,
        variant: IuxButtonVariant.outlined,
      );
      final IuxButtonTokens text = await resolve(
        tester,
        action: action,
        variant: IuxButtonVariant.text,
      );

      expect(outlined.background, isNot(equals(filled.background)));
      expect(outlined.borderWidth, greaterThan(0));
      expect(text.borderWidth, 0);
    });

    testWidgets('an icon button is padded squarely',
        (WidgetTester tester) async {
      final IuxButtonTokens tokens = await resolve(
        tester,
        action: const IuxActionDescriptor(semantics: label),
        variant: IuxButtonVariant.icon,
      );
      expect(tokens.padding.left, tokens.padding.top);
      expect(tokens.minimumSize, greaterThanOrEqualTo(IuxTouchTarget.minimum));
    });

    testWidgets('a destructive tonal button is refused',
        (WidgetTester tester) async {
      // Tonal carries intent through its border rather than its fill, which
      // is not enough separation for an action that destroys data.
      await tester.pumpWidget(
        MaterialApp(
          theme: IuxTheme.light(),
          home: Builder(
            builder: (BuildContext context) {
              IuxButtonResolver.resolve(
                context,
                const IuxActionDescriptor.destructive(
                  semantics: IuxActionSemantics(label: 'Delete'),
                ),
                variant: IuxButtonVariant.tonal,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(tester.takeException(), isA<AssertionError>());
    });

    for (final IuxActionIntent intent in <IuxActionIntent>[
      IuxActionIntent.secondary,
      IuxActionIntent.tertiary,
    ]) {
      testWidgets('a ${intent.name} action cannot be filled',
          (WidgetTester tester) async {
        // IUX-039. This combination used to be accepted and discarded: the
        // semantic layer models both intents unfilled, so `filled` painted the
        // page surface over the page surface and resolved — measured — to a
        // text button. §22 asks a component to prevent an incoherent state,
        // and the resolver already refused one such pair; this is the second.
        await tester.pumpWidget(
          MaterialApp(
            theme: IuxTheme.light(),
            home: Builder(
              builder: (BuildContext context) {
                IuxButtonResolver.resolve(
                  context,
                  IuxActionDescriptor(semantics: label, intent: intent),
                  variant: IuxButtonVariant.filled,
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        expect(tester.takeException(), isA<AssertionError>());
      });
    }
  });

  group('the variant a call site did not name', () {
    // `IuxButtonTheme.variant` used to answer this with one constant, `filled`,
    // for every intent — so the most ordinary button in the package, a plain
    // secondary descriptor, resolved to a fill equal to the page and an
    // outline of width zero. The action answers now.
    const Map<(IuxActionIntent, IuxActionImportance), IuxButtonVariant> table =
        <(IuxActionIntent, IuxActionImportance), IuxButtonVariant>{
      (IuxActionIntent.primary, IuxActionImportance.high):
          IuxButtonVariant.filled,
      (IuxActionIntent.primary, IuxActionImportance.medium):
          IuxButtonVariant.outlined,
      (IuxActionIntent.primary, IuxActionImportance.low): IuxButtonVariant.text,
      (IuxActionIntent.destructive, IuxActionImportance.high):
          IuxButtonVariant.filled,
      (IuxActionIntent.secondary, IuxActionImportance.high):
          IuxButtonVariant.outlined,
      (IuxActionIntent.secondary, IuxActionImportance.medium):
          IuxButtonVariant.tonal,
      (IuxActionIntent.secondary, IuxActionImportance.low):
          IuxButtonVariant.text,
      (IuxActionIntent.tertiary, IuxActionImportance.medium):
          IuxButtonVariant.tonal,
      (IuxActionIntent.tertiary, IuxActionImportance.low):
          IuxButtonVariant.text,
    };

    test('follows intent and importance together', () {
      table.forEach(
        ((IuxActionIntent, IuxActionImportance) input,
            IuxButtonVariant expected) {
          expect(
            IuxButtonResolver.defaultVariantFor(
              IuxActionDescriptor(
                semantics: label,
                intent: input.$1,
                importance: input.$2,
              ),
            ),
            expected,
            reason: '${input.$1.name} + ${input.$2.name}',
          );
        },
      );
    });

    test('never resolves to a combination the resolver refuses', () {
      // A default that trips an assertion is worse than no default: it fails
      // on the shortest call a caller can write.
      for (final IuxActionIntent intent in IuxActionIntent.values) {
        for (final IuxActionImportance importance
            in IuxActionImportance.values) {
          final IuxButtonVariant resolved = IuxButtonResolver.defaultVariantFor(
            IuxActionDescriptor(
              semantics: label,
              intent: intent,
              importance: importance,
            ),
          );
          expect(
            resolved == IuxButtonVariant.filled &&
                (intent == IuxActionIntent.secondary ||
                    intent == IuxActionIntent.tertiary),
            isFalse,
            reason: '${intent.name} + ${importance.name} defaults to filled',
          );
          expect(
            resolved == IuxButtonVariant.tonal &&
                intent == IuxActionIntent.destructive,
            isFalse,
            reason: '${intent.name} + ${importance.name} defaults to tonal',
          );
        }
      }
    });

    testWidgets('the two factory constructors keep their container',
        (WidgetTester tester) async {
      // `IuxActionDescriptor.destructive` was importance medium, which under
      // this table would have made every deletion in the package an outlined
      // button. It is high now — not because deleting is desirable, but
      // because a control that destroys data has to be identifiable as a
      // control.
      for (final IuxActionDescriptor action in <IuxActionDescriptor>[
        const IuxActionDescriptor.primary(semantics: label),
        const IuxActionDescriptor.destructive(semantics: label),
      ]) {
        expect(
          IuxButtonResolver.defaultVariantFor(action),
          IuxButtonVariant.filled,
          reason: '${action.intent.name} lost its fill',
        );
      }
    });
  });

  group('geometry follows the theme, never a literal', () {
    testWidgets('the target floor is always respected',
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
        final IuxButtonTokens tokens = await resolve(
          tester,
          action: const IuxActionDescriptor(
            semantics: label,
            intent: IuxActionIntent.primary,
          ),
          configuration: configuration,
        );
        expect(
          tokens.minimumSize,
          greaterThanOrEqualTo(IuxTouchTarget.minimum),
        );
      }
    });

    testWidgets('high contrast thickens the outline',
        (WidgetTester tester) async {
      final IuxButtonTokens standard = await resolve(
        tester,
        action: const IuxActionDescriptor(semantics: label),
        variant: IuxButtonVariant.outlined,
      );
      final IuxButtonTokens high = await resolve(
        tester,
        action: const IuxActionDescriptor(semantics: label),
        variant: IuxButtonVariant.outlined,
        configuration: const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(contrast: IuxContrast.high),
        ),
      );
      expect(high.borderWidth, greaterThan(standard.borderWidth));
    });

    testWidgets('no button ever paints a shadow', (WidgetTester tester) async {
      // Rewritten at IUX-038. This used to assert `tokens.elevation == 0` on a
      // field no widget read, so it could not have caught a shadow appearing.
      // It now measures the decoration a button actually paints, for every
      // variant — the guarantee being that hierarchy rests on contrast-measured
      // colour and never on a shadow that a reduced visual stimulation
      // preference removes.
      // Primary throughout: it is the one intent every variant is legal for.
      const IuxActionDescriptor action = IuxActionDescriptor(
        semantics: label,
        intent: IuxActionIntent.primary,
      );
      for (final IuxButtonVariant variant in IuxButtonVariant.values) {
        await tester.pumpWidget(
          MaterialApp(
            theme: IuxTheme.light(),
            home: Scaffold(
              body: Center(
                child: variant == IuxButtonVariant.icon
                    ? IuxIconButton(
                        icon: Icons.close,
                        action: action,
                        onActivate: () {},
                      )
                    : IuxButton(
                        label: 'Save',
                        variant: variant,
                        action: action,
                        onActivate: () {},
                      ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final BoxDecoration painted = tester
            .widget<AnimatedContainer>(find.byType(AnimatedContainer))
            .decoration! as BoxDecoration;
        expect(
          painted.boxShadow,
          isNull,
          reason: '$variant cast a shadow; a filled button is already '
              'separated from its background by colour',
        );
      }
    });
  });

  group('the theme extension behaves as a value', () {
    test('defaults are the cautious ones', () {
      const IuxButtonTheme theme = IuxButtonTheme();
      expect(theme.shape, IuxButtonShape.medium);
      expect(theme.iconSize, 20);
    });

    test('copyWith and equality cover every field', () {
      const IuxButtonTheme base = IuxButtonTheme();
      expect(base.copyWith(), equals(base));
      expect(base.copyWith(iconSize: 24).iconSize, 24);
      expect(
        base.copyWith(shape: IuxButtonShape.full),
        isNot(equals(base)),
      );
      expect(base.hashCode, equals(const IuxButtonTheme().hashCode));
    });

    test('categorical fields never land between two values', () {
      const IuxButtonTheme a = IuxButtonTheme();
      const IuxButtonTheme b = IuxButtonTheme(shape: IuxButtonShape.full);
      for (final double t in <double>[0, 0.25, 0.5, 0.75, 1]) {
        expect(
          a.lerp(b, t).shape,
          anyOf(IuxButtonShape.medium, IuxButtonShape.full),
        );
      }
    });

    test('it is installed on every resolved theme', () {
      expect(IuxTheme.light().extension<IuxButtonTheme>(), isNotNull);
    });

    testWidgets('a button without an explicit theme still resolves',
        (WidgetTester tester) async {
      late IuxButtonTheme resolved;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              resolved = IuxButtonTheme.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(resolved, const IuxButtonTheme());
    });
  });

  group('tokens are a value type', () {
    testWidgets('identical inputs resolve equal', (WidgetTester tester) async {
      const IuxActionDescriptor action = IuxActionDescriptor(
        semantics: label,
        intent: IuxActionIntent.primary,
      );
      final IuxButtonTokens a = await resolve(tester, action: action);
      final IuxButtonTokens b = await resolve(tester, action: action);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
