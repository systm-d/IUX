import 'package:flutter/foundation.dart';

/// Whether the user may change a field, only read it, or neither.
///
/// Three values rather than a boolean, because "you may read this but not
/// change it" and "this does not apply to you" have different consequences for
/// a keyboard or screen-reader user. A disabled field leaves the focus order;
/// a read-only one does not, and a value that cannot be reached is a value the
/// user does not have.
///
/// The action model deliberately has no `readOnly` — read-only describes a
/// field, not an action. This is where it belongs.
enum IuxInputAvailability {
  /// The value can be read and changed.
  enabled,

  /// The value can be read, focused and copied, but not changed.
  ///
  /// Use it whenever the user still needs the value — an order reference they
  /// have to quote, an address computed from earlier answers. Disabling it
  /// instead removes it from focus traversal, which hides it from a screen
  /// reader entirely: the user is not told the value is fixed, they are simply
  /// never told the value.
  readOnly,

  /// The field does not currently apply.
  ///
  /// Skipped by focus traversal and not editable. Say why through
  /// [IuxInputSemantics.unavailabilityReason]: an unexplained greyed field
  /// leaves the user unable to tell whether they did something wrong or the
  /// question does not apply to them.
  disabled,
}

/// Whether an answer is expected.
///
/// An enum rather than a boolean because it sits among several other
/// dimensions, where `requirement: IuxInputRequirement.required` still reads
/// as a sentence and `required: true` no longer does.
///
/// How required-ness is *marked* is not modelled here. Marking the rarer case —
/// asterisks on required fields in a mostly-optional form, the word "optional"
/// in a mostly-required one — is a form-level decision, and the marker itself
/// is caller-supplied text that has to be localised.
enum IuxInputRequirement {
  /// The form cannot be completed without a value.
  required,

  /// The field may be left empty.
  ///
  /// The default. A field is optional until someone says otherwise, because
  /// the failure mode of the other default — silently demanding an answer the
  /// user was never told was needed — is worse.
  optional,
}

/// What is known about the validity of the current value.
///
/// A lifecycle, not a boolean: "not checked yet" and "checked and accepted"
/// are different answers, and rendering them identically produces the green
/// tick on every untouched field that trains users to ignore ticks.
///
/// The parent owns this. A field never decides that a value is valid — it
/// cannot know the rule — and a component that guessed would eventually accept
/// something the server rejects.
enum IuxInputValidationStatus {
  /// Nothing has been checked. The resting status.
  notValidated,

  /// A check is running.
  ///
  /// For a rule that cannot be evaluated locally, such as whether a user name
  /// is taken. It is not "invalid yet to be proven otherwise": showing an
  /// error while the answer is unknown makes the user correct something that
  /// was never wrong.
  validating,

  /// The value was checked and accepted.
  ///
  /// Set it only where the confirmation is worth the noise. Most fields never
  /// need it.
  valid,

  /// The value was checked and rejected.
  ///
  /// Always accompanied by a message saying what is wrong and how to fix it.
  /// See [IuxInputValidation].
  invalid,
}

/// What is known about the validity of the current value, and what to say
/// about it.
///
/// Status and message travel together so they cannot drift. The two failures
/// this prevents are an error signalled by nothing but a red outline, and a
/// stale "looks good" left behind after the value changed — both of which come
/// from a design where the message is one field and the status another.
///
/// Every message arrives already localised from the caller. IUX composes no
/// user-facing text and never invents one: a framework-authored "This field is
/// required" would be the wrong language, the wrong wording, or both.
///
/// There is deliberately no `copyWith`. The named constructors *are* the
/// transitions, and a copy that changed only the status would happily produce
/// an invalid field carrying its old success message.
@immutable
final class IuxInputValidation {
  /// Nothing has been checked yet.
  const IuxInputValidation.notValidated()
      : status = IuxInputValidationStatus.notValidated,
        message = null;

  /// A check is running.
  ///
  /// [message] is optional and, when given, explains the wait.
  const IuxInputValidation.validating({this.message})
      : assert(
          message == null || message.length > 0,
          'An empty message says nothing and still reserves a line. Pass null '
          'instead of an empty string.',
        ),
        status = IuxInputValidationStatus.validating;

  /// The value was checked and accepted.
  ///
  /// [message] is optional: most accepted values need no confirmation, and a
  /// confirmation on every field is noise that hides the one that matters.
  const IuxInputValidation.valid({this.message})
      : assert(
          message == null || message.length > 0,
          'An empty message says nothing and still reserves a line. Pass null '
          'instead of an empty string.',
        ),
        status = IuxInputValidationStatus.valid;

  /// The value was checked and rejected, with the reason.
  ///
  /// [message] is required, and that is the point: an error carried by a red
  /// outline alone is invisible to a user who cannot distinguish the hue, and
  /// useless to everyone else, since a colour cannot say what to type instead.
  const IuxInputValidation.invalid(String message)
      : assert(
          message.length > 0,
          'An invalid field must say what is wrong. Colour alone cannot be '
          'perceived by every user and cannot explain how to fix the value.',
        ),
        status = IuxInputValidationStatus.invalid,
        message = message;

  /// What is known about the value.
  final IuxInputValidationStatus status;

  /// What to tell the user about it, already localised, or null.
  final String? message;

  /// Whether the value was checked and rejected.
  bool get isInvalid => status == IuxInputValidationStatus.invalid;

  /// Whether a check is currently running.
  bool get isPending => status == IuxInputValidationStatus.validating;

  /// Whether anything has been checked at all.
  ///
  /// False for the resting status, which is what distinguishes "we have no
  /// opinion" from "we looked and it is fine".
  bool get isResolved =>
      status == IuxInputValidationStatus.valid ||
      status == IuxInputValidationStatus.invalid;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxInputValidation &&
          other.status == status &&
          other.message == message;

  @override
  int get hashCode => Object.hash(status, message);

  @override
  String toString() => message == null
      ? 'IuxInputValidation(${status.name})'
      : 'IuxInputValidation(${status.name}, "$message")';
}

/// The text a field exposes to assistive technology.
///
/// Every string arrives already localised from the caller, so the model cannot
/// leak one language into another.
///
/// The accessible name lives here rather than being taken from a placeholder,
/// because a placeholder disappears the moment the user types. A field whose
/// only name was its placeholder becomes an unlabelled box exactly when the
/// user is checking what they entered.
@immutable
final class IuxInputSemantics {
  /// Creates the semantic description of a field.
  const IuxInputSemantics({
    required this.label,
    this.hint,
    this.unavailabilityReason,
  })  : assert(
          label.length > 0,
          'A field must have an accessible name. An unnamed field is announced '
          'as "edit box" and nothing else, which tells the user where the '
          'caret is and not what to type.',
        ),
        assert(
          hint == null || hint.length > 0,
          'Pass null rather than an empty hint.',
        ),
        assert(
          unavailabilityReason == null || unavailabilityReason.length > 0,
          'Pass null rather than an empty unavailability reason.',
        );

  /// The accessible name.
  ///
  /// Required: there is no default that could be correct, and a field without
  /// a name cannot be used with a screen reader.
  final String label;

  /// What to enter, when the name alone leaves it ambiguous.
  ///
  /// Format requirements belong here — and also on screen, because a hint that
  /// only a screen reader hears is a rule sighted users have to guess.
  final String? hint;

  /// Why the field is unavailable.
  ///
  /// Only meaningful when availability is [IuxInputAvailability.disabled]. A
  /// greyed field with no explanation leaves the user unable to tell whether
  /// they did something wrong or the question does not apply to them.
  final String? unavailabilityReason;

  /// Returns a copy with the given values replaced.
  IuxInputSemantics copyWith({
    String? label,
    String? hint,
    String? unavailabilityReason,
  }) =>
      IuxInputSemantics(
        label: label ?? this.label,
        hint: hint ?? this.hint,
        unavailabilityReason: unavailabilityReason ?? this.unavailabilityReason,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxInputSemantics &&
          other.label == label &&
          other.hint == hint &&
          other.unavailabilityReason == unavailabilityReason;

  @override
  int get hashCode => Object.hash(label, hint, unavailabilityReason);

  @override
  String toString() => 'IuxInputSemantics($label)';
}
