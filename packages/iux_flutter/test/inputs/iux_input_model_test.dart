import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/src/inputs/iux_input_descriptor.dart';
import 'package:iux_flutter/src/inputs/iux_input_model.dart';

void main() {
  const IuxInputSemantics email = IuxInputSemantics(label: 'Email address');

  group('a field cannot be described incoherently', () {
    test('a field must have an accessible name', () {
      expect(() => IuxInputSemantics(label: ''), throwsAssertionError);
    });

    test('an invalid value must say what is wrong', () {
      // Colour alone cannot be perceived by every user and cannot explain how
      // to fix the value.
      expect(() => IuxInputValidation.invalid(''), throwsAssertionError);
    });

    test('help text that says nothing is refused rather than reserved', () {
      expect(
        () => IuxInputDescriptor(semantics: email, helpText: ''),
        throwsAssertionError,
      );
    });

    test('an empty hint is refused, so null means one thing', () {
      expect(
        () => IuxInputSemantics(label: 'Name', hint: ''),
        throwsAssertionError,
      );
      expect(
        () => IuxInputSemantics(label: 'Name', unavailabilityReason: ''),
        throwsAssertionError,
      );
      expect(() => IuxInputValidation.valid(message: ''), throwsAssertionError);
      expect(
        () => IuxInputValidation.validating(message: ''),
        throwsAssertionError,
      );
    });
  });

  group('the defaults are the cautious ones', () {
    const IuxInputDescriptor field = IuxInputDescriptor(semantics: email);

    test('a field is editable, optional and unchecked until said otherwise',
        () {
      expect(field.availability, IuxInputAvailability.enabled);
      expect(field.requirement, IuxInputRequirement.optional);
      expect(field.validation.status, IuxInputValidationStatus.notValidated);
      expect(field.helpText, isNull);
    });

    test('nothing is claimed about a value nobody has checked', () {
      expect(field.hasError, isFalse);
      expect(field.validation.isResolved, isFalse);
      expect(field.validation.message, isNull);
    });
  });

  group('availability decides what the user can reach', () {
    const IuxInputDescriptor field = IuxInputDescriptor(semantics: email);

    test('a read-only field stays in the focus order', () {
      // Its value is still information, and a value a keyboard or
      // screen-reader user cannot reach is a value they do not have.
      final IuxInputDescriptor readOnly =
          field.copyWith(availability: IuxInputAvailability.readOnly);
      expect(readOnly.isFocusable, isTrue);
      expect(readOnly.isEditable, isFalse);
    });

    test('a disabled field leaves the focus order', () {
      final IuxInputDescriptor disabled =
          field.copyWith(availability: IuxInputAvailability.disabled);
      expect(disabled.isFocusable, isFalse);
      expect(disabled.isEditable, isFalse);
    });

    test('only an enabled field is editable', () {
      expect(field.isEditable, isTrue);
      expect(field.isFocusable, isTrue);
    });
  });

  group('an unavailable field explains itself', () {
    const IuxInputSemantics semantics = IuxInputSemantics(
      label: 'VAT number',
      hint: 'Nine digits',
      unavailabilityReason: 'Only businesses provide a VAT number',
    );

    test('a disabled field announces why, not just that', () {
      const IuxInputDescriptor disabled = IuxInputDescriptor(
        semantics: semantics,
        availability: IuxInputAvailability.disabled,
      );
      expect(disabled.accessibleHint, 'Only businesses provide a VAT number');
    });

    test('a disabled field with no reason falls back to its hint', () {
      const IuxInputDescriptor disabled = IuxInputDescriptor(
        semantics: IuxInputSemantics(label: 'VAT number', hint: 'Nine digits'),
        availability: IuxInputAvailability.disabled,
      );
      expect(disabled.accessibleHint, 'Nine digits');
    });

    test('an available field never borrows the unavailability reason', () {
      const IuxInputDescriptor enabled =
          IuxInputDescriptor(semantics: semantics);
      expect(enabled.accessibleHint, 'Nine digits');
    });
  });

  group('a validation result carries its own message', () {
    test('changing the status cannot leave the old message behind', () {
      const IuxInputDescriptor rejected = IuxInputDescriptor(
        semantics: email,
        validation: IuxInputValidation.invalid('Enter a full email address'),
      );
      final IuxInputDescriptor accepted =
          rejected.copyWith(validation: const IuxInputValidation.valid());

      expect(accepted.hasError, isFalse);
      expect(accepted.validation.message, isNull);
    });

    test('a pending check is not an error', () {
      const IuxInputValidation pending = IuxInputValidation.validating();
      expect(pending.isPending, isTrue);
      expect(pending.isInvalid, isFalse);
      expect(pending.isResolved, isFalse);
    });

    test('checked and accepted is not the same as never checked', () {
      const IuxInputValidation untouched = IuxInputValidation.notValidated();
      const IuxInputValidation accepted = IuxInputValidation.valid();
      expect(untouched.isResolved, isFalse);
      expect(accepted.isResolved, isTrue);
      expect(untouched, isNot(equals(accepted)));
    });

    test('help text survives an error, because it says how to fix it', () {
      const IuxInputDescriptor field = IuxInputDescriptor(
        semantics: email,
        helpText: 'We use it only to send your receipt',
        validation: IuxInputValidation.invalid('Enter a full email address'),
      );
      expect(field.helpText, isNotNull);
      expect(field.validation.message, isNotNull);
    });
  });

  group('the model behaves as a value', () {
    const IuxInputDescriptor field = IuxInputDescriptor(semantics: email);

    test('an unchanged copy equals its original', () {
      expect(field.copyWith(), equals(field));
      expect(field.copyWith().hashCode, equals(field.hashCode));
    });

    test('every dimension participates in equality', () {
      expect(
        field.copyWith(availability: IuxInputAvailability.readOnly),
        isNot(equals(field)),
      );
      expect(
        field.copyWith(requirement: IuxInputRequirement.required),
        isNot(equals(field)),
      );
      expect(
        field.copyWith(validation: const IuxInputValidation.valid()),
        isNot(equals(field)),
      );
      expect(field.copyWith(helpText: 'Anything'), isNot(equals(field)));
      expect(
        field.copyWith(
          semantics: const IuxInputSemantics(label: 'Something else'),
        ),
        isNot(equals(field)),
      );
    });

    test('semantics copy and compare on every field', () {
      const IuxInputSemantics base = IuxInputSemantics(label: 'Name');
      expect(base.copyWith(), equals(base));
      expect(base.copyWith(hint: 'As printed'), isNot(equals(base)));
      expect(
        base.copyWith(unavailabilityReason: 'Set by your administrator'),
        isNot(equals(base)),
      );
      expect(base.hashCode, const IuxInputSemantics(label: 'Name').hashCode);
    });

    test('a description names the field it describes', () {
      expect(field.toString(), contains('Email address'));
      expect(
        const IuxInputValidation.invalid('Too short').toString(),
        contains('Too short'),
      );
    });

    test('required-ness is readable without inspecting the enum', () {
      expect(field.isRequired, isFalse);
      expect(
        field.copyWith(requirement: IuxInputRequirement.required).isRequired,
        isTrue,
      );
    });
  });
}
