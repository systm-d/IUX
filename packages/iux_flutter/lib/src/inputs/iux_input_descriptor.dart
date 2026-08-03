import 'package:flutter/foundation.dart';

import 'iux_input_model.dart';

/// Everything a component needs to know about a field, and nothing about how
/// to draw it.
///
/// One immutable object rather than a dozen parameters, so a text field, a
/// checkbox and a future date picker all take the same argument and cannot
/// disagree about what "read-only and invalid" means.
///
/// The common case stays short:
///
/// ```dart
/// const email = IuxInputDescriptor(
///   semantics: IuxInputSemantics(label: 'Email address'),
///   requirement: IuxInputRequirement.required,
/// );
/// ```
///
/// Only [semantics] is required — a field without an accessible name cannot be
/// used with a screen reader, so there is no sensible default for it. Every
/// other dimension defaults to the safest value.
///
/// **The parent owns validation.** Whether a value is acceptable, what the
/// message says and when it appears are decisions this model records and never
/// makes. A field that validated itself would eventually reject something the
/// server accepts, or accept something it rejects, and the user would be told
/// two different things by the same application.
@immutable
final class IuxInputDescriptor {
  /// Creates a field descriptor.
  ///
  /// Contradictions that can be decided from these values alone fail on an
  /// assertion rather than being silently corrected: quietly repairing a
  /// contradiction hides the fact that the caller believed something untrue.
  /// The ones that need the ambient theme are checked when the field resolves.
  const IuxInputDescriptor({
    required this.semantics,
    this.availability = IuxInputAvailability.enabled,
    this.requirement = IuxInputRequirement.optional,
    this.validation = const IuxInputValidation.notValidated(),
    this.helpText,
  }) : assert(
          helpText == null || helpText.length > 0,
          'Empty help text reserves a line and says nothing. Pass null '
          'instead, so the layout does not hold space for a sentence that '
          'never arrives.',
        );

  /// What the field exposes to assistive technology.
  final IuxInputSemantics semantics;

  /// Whether the user may change the value, only read it, or neither.
  final IuxInputAvailability availability;

  /// Whether an answer is expected.
  final IuxInputRequirement requirement;

  /// What is known about the validity of the current value.
  final IuxInputValidation validation;

  /// A persistent instruction shown with the field, already localised.
  ///
  /// Kept separate from [IuxInputValidation.message] because IUX shows both.
  /// Replacing the instruction with the error — the common pattern — removes
  /// the sentence that says how to write a correct value at the exact moment
  /// the user has proved they need it.
  final String? helpText;

  /// Whether the user may change the value.
  bool get isEditable => availability == IuxInputAvailability.enabled;

  /// Whether the field takes keyboard focus.
  ///
  /// True for read-only fields. Their value is still information, and a value
  /// a keyboard or screen-reader user cannot reach is a value they do not
  /// have.
  bool get isFocusable => availability != IuxInputAvailability.disabled;

  /// Whether the form cannot be completed without a value.
  bool get isRequired => requirement == IuxInputRequirement.required;

  /// Whether the value was checked and rejected.
  bool get hasError => validation.isInvalid;

  /// The hint a screen reader reads after the name.
  ///
  /// An unavailable field explains itself when the caller said why, falling
  /// back to the ordinary hint. Resolved here rather than in each widget, so
  /// the text field and the checkbox cannot announce the same situation
  /// differently. Nothing is composed: one caller-supplied string is chosen
  /// over another.
  String? get accessibleHint => availability == IuxInputAvailability.disabled
      ? semantics.unavailabilityReason ?? semantics.hint
      : semantics.hint;

  /// Returns a copy with the given values replaced.
  ///
  /// [validation] carries its message with it, so moving a field from invalid
  /// to valid cannot leave the old error behind.
  IuxInputDescriptor copyWith({
    IuxInputSemantics? semantics,
    IuxInputAvailability? availability,
    IuxInputRequirement? requirement,
    IuxInputValidation? validation,
    String? helpText,
  }) =>
      IuxInputDescriptor(
        semantics: semantics ?? this.semantics,
        availability: availability ?? this.availability,
        requirement: requirement ?? this.requirement,
        validation: validation ?? this.validation,
        helpText: helpText ?? this.helpText,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxInputDescriptor &&
          other.semantics == semantics &&
          other.availability == availability &&
          other.requirement == requirement &&
          other.validation == validation &&
          other.helpText == helpText;

  @override
  int get hashCode =>
      Object.hash(semantics, availability, requirement, validation, helpText);

  @override
  String toString() => 'IuxInputDescriptor(${semantics.label}, '
      '${availability.name}, ${requirement.name}, '
      '${validation.status.name})';
}
