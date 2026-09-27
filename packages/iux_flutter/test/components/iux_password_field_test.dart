import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

/// `IuxPasswordField`: a concealed field, and the labelled switch that shows it.
///
/// Built after the first application migrated onto IUX needed a token field
/// and found none (systm-d/IUX#67) — and after `IuxTextContent` had already
/// said, in advance, why the thing it needed was a component rather than a
/// flag. These tests hold the parts of that argument a unit test can hold.
void main() {
  const String label = 'Personal access token';
  const String reveal = 'Show token';
  const IuxInputDescriptor token = IuxInputDescriptor(
    semantics: IuxInputSemantics(label: label),
    requirement: IuxInputRequirement.required,
  );

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

  Future<TextEditingController> pump(
    WidgetTester tester, {
    IuxInputDescriptor input = token,
    IuxSecretPurpose purpose = IuxSecretPurpose.token,
    String text = 'example-secret',
    IuxThemeConfiguration configuration = const IuxThemeConfiguration(),
  }) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final TextEditingController controller = TextEditingController(text: text);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: IuxTheme.fromConfiguration(configuration),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: IuxPasswordField(
              input: input,
              purpose: purpose,
              revealLabel: reveal,
              controller: controller,
              onChanged: (String _) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  TextField field(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField));

  Future<void> toggle(WidgetTester tester) async {
    await tester.tap(find.byType(IuxSwitch));
    await tester.pumpAndSettle();
  }

  group('concealed until the user says otherwise', () {
    testWidgets('the value is concealed on arrival',
        (WidgetTester tester) async {
      await pump(tester);

      expect(field(tester).obscureText, isTrue);
      final SemanticsHandle handle = tester.ensureSemantics();
      expect(
        tester.getSemantics(find.byType(TextField)),
        isSemantics(label: label, isTextField: true, isObscured: true),
      );
      handle.dispose();
    });

    testWidgets('the switch reveals it, and conceals it again',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester);

      await toggle(tester);
      expect(field(tester).obscureText, isFalse);
      expect(
        tester.getSemantics(find.byType(TextField)),
        isSemantics(label: label, isObscured: false, value: 'example-secret'),
        reason: 'once revealed, a screen-reader user who moves to the field '
            'hears the value — which is the whole point of revealing it',
      );

      await toggle(tester);
      expect(field(tester).obscureText, isTrue);
      handle.dispose();
    });

    testWidgets('revealing loses nothing the user typed',
        (WidgetTester tester) async {
      final TextEditingController controller = await pump(tester);
      controller.selection = const TextSelection.collapsed(offset: 4);

      await toggle(tester);
      expect(controller.text, 'example-secret');
      expect(controller.selection, const TextSelection.collapsed(offset: 4));
    });
  });

  group('the reveal control is a named switch', () {
    testWidgets('it is visible text, announced as a switch with its state',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester);

      expect(find.text(reveal), findsOneWidget,
          reason: 'the name is read, not only heard: no eye icon to decode');
      expect(
        tester.getSemantics(find.byType(IuxSwitch)),
        isSemantics(label: reveal, hasToggledState: true, isToggled: false),
      );

      await toggle(tester);
      expect(
        tester.getSemantics(find.byType(IuxSwitch)),
        isSemantics(label: reveal, hasToggledState: true, isToggled: true),
        reason: 'the name stays the same and the state changes — a name '
            'flipping between "Show" and "Hide" would have to be read again '
            'to know what the control does now',
      );
      handle.dispose();
    });

    testWidgets('it comes after the field, in the order a user meets them',
        (WidgetTester tester) async {
      await pump(tester);
      expect(
        tester.getTopLeft(find.byType(IuxSwitch)).dy,
        greaterThan(tester.getBottomLeft(find.byType(TextField)).dy),
      );
    });

    test('an unnamed reveal control is refused', () {
      expect(
        () => IuxPasswordField(
          input: token,
          purpose: IuxSecretPurpose.token,
          revealLabel: '',
          controller: TextEditingController(),
          onChanged: (String _) {},
        ),
        throwsAssertionError,
      );
    });
  });

  group('nothing leaves the box', () {
    for (final bool revealed in <bool>[false, true]) {
      testWidgets(
          'no suggestion, correction or learning while '
          '${revealed ? 'revealed' : 'concealed'}',
          (WidgetTester tester) async {
        await pump(tester);
        if (revealed) await toggle(tester);

        final TextField f = field(tester);
        expect(f.enableSuggestions, isFalse, reason: 'a suggestion strip');
        expect(f.autocorrect, isFalse, reason: 'a corrected word');
        expect(
          f.enableIMEPersonalizedLearning,
          isFalse,
          reason: "the keyboard's own dictionary",
        );
        expect(f.textCapitalization, TextCapitalization.none);
        expect(f.smartDashesType, SmartDashesType.disabled);
        expect(f.smartQuotesType, SmartQuotesType.disabled);
        expect(
          f.keyboardType,
          TextInputType.visiblePassword,
          reason: 'the same keyboard in both states, so revealing does not '
              're-lay it out under the user\'s fingers',
        );
      });
    }
  });

  group('the purpose decides what autofill may do', () {
    for (final (IuxSecretPurpose purpose, List<String>? hints)
        in <(IuxSecretPurpose, List<String>?)>[
      (IuxSecretPurpose.current, <String>[AutofillHints.password]),
      (IuxSecretPurpose.created, <String>[AutofillHints.newPassword]),
      // A token offered to a password manager as the account's password is a
      // password the user may overwrite by accepting.
      (IuxSecretPurpose.token, null),
    ]) {
      testWidgets('${purpose.name} → ${hints ?? 'nothing'}',
          (WidgetTester tester) async {
        await pump(tester, purpose: purpose);
        expect(field(tester).autofillHints, hints);
      });
    }
  });

  group('the switch follows the field', () {
    testWidgets('a disabled field has a disabled switch',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(
        tester,
        input: const IuxInputDescriptor(
          semantics: IuxInputSemantics(label: label),
          availability: IuxInputAvailability.disabled,
        ),
      );
      expect(
        tester.getSemantics(find.byType(IuxSwitch)),
        isSemantics(label: reveal, hasEnabledState: true, isEnabled: false),
      );
      handle.dispose();
    });

    testWidgets('a read-only field can still be revealed',
        (WidgetTester tester) async {
      // A generated token shown once, for the user to copy: exactly a value
      // somebody needs to see and may not edit.
      await pump(
        tester,
        input: const IuxInputDescriptor(
          semantics: IuxInputSemantics(label: label),
          availability: IuxInputAvailability.readOnly,
        ),
      );
      await toggle(tester);
      expect(field(tester).obscureText, isFalse);
    });
  });

  group('the refusal it was built from still holds', () {
    for (final IuxTextContent content in IuxTextContent.values) {
      testWidgets('IuxTextField(${content.name}) cannot conceal a value',
          (WidgetTester tester) async {
        // IuxPasswordField is the one way to obscure a field. If IuxTextField
        // ever grew the ability, the argument in IuxTextContent — a concealed
        // value owes the user a way to reveal it — would be unenforced again.
        final TextEditingController controller = TextEditingController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          MaterialApp(
            theme: IuxTheme.light(),
            home: Scaffold(
              body: IuxTextField(
                input: token,
                content: content,
                controller: controller,
                onChanged: (String _) {},
              ),
            ),
          ),
        );
        expect(field(tester).obscureText, isFalse);
        expect(field(tester).enableSuggestions, isTrue);
      });
    }
  });

  group('everything else is IuxTextField\'s', () {
    testWidgets('the label, the help and the message all reach the screen',
        (WidgetTester tester) async {
      await pump(
        tester,
        input: const IuxInputDescriptor(
          semantics: IuxInputSemantics(label: label),
          helpText: 'Created under Settings, Developer settings.',
          validation: IuxInputValidation.invalid('This token has expired.'),
        ),
      );
      expect(find.text(label), findsOneWidget);
      expect(
        find.text('Created under Settings, Developer settings.'),
        findsOneWidget,
      );
      expect(find.text('This token has expired.'), findsOneWidget);
    });

    for (final (String name, IuxThemeConfiguration configuration) in profiles) {
      testWidgets('renders under $name', (WidgetTester tester) async {
        await pump(tester, configuration: configuration);
        expect(tester.takeException(), isNull);
        expect(
          tester.getSize(find.byType(IuxSwitch)).height,
          greaterThanOrEqualTo(48),
          reason: 'the reveal control keeps the target floor',
        );
      });
    }
  });
}
