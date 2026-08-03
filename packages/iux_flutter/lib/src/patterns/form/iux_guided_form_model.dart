import 'package:flutter/foundation.dart';

import 'iux_form_model.dart';
import 'iux_form_section.dart';

/// Why a step with no name is refused.
const String _kEmptyStepTitle =
    'A step must be named. The name is what a screen-reader user hears when '
    'the step changes under them — it is the whole of the announcement that a '
    'different set of questions is now on screen — and it is what a sighted '
    'user reads to find out what this part of the form is about. A step with '
    'no name is a page that silently became a different page.';

/// Why a step with no questions is refused.
const String _kEmptyStep =
    'A step with no sections is a heading, a progress position and two '
    'navigation controls over nothing. Stop including the step instead, so '
    'the count the user is told about matches the number of times they will '
    'be asked something.';

/// Produces the sentence that says where in the form the user is.
///
/// ```dart
/// (int step, int stepCount) => l10n.stepOf(step, stepCount)  // "Step 2 of 5"
/// ```
///
/// A function of both numbers rather than a string per step, for the reason
/// [IuxErrorCountDescription] is a function: the position the user is told and
/// the number of steps that exist must be the same two numbers. A caller
/// writing one label per step keeps that count by hand, in parallel with the
/// list, and the two drift the first time a step is added — leaving "Step 3 of
/// 4" above the fourth of five.
///
/// [step] is one-based, because it is read by a person: the first step is step
/// one. [stepCount] is how many there are in total.
///
/// The sentence is the caller's, already localised, and IUX composes none of
/// it. "Step 2 of 5", "2 / 5" and "Étape 2 sur 5" are three different strings
/// and only the application knows which one its users read.
typedef IuxStepPositionDescription = String Function(int step, int stepCount);

/// One step of a guided form: what it is called, and what it asks.
///
/// ```dart
/// IuxGuidedFormStep(
///   title: l10n.deliveryAddress,
///   description: l10n.weOnlyDeliverWithinTheCity,
///   sections: <IuxFormSection>[
///     IuxFormSection(fields: <IuxFormField>[street, postcode, city]),
///   ],
/// )
/// ```
///
/// **It holds [IuxFormSection]s rather than widgets**, for the reason
/// [IuxFormSection] holds [IuxFormField]s rather than widgets: `IuxGuidedForm`
/// reads the fields back out of every step — including the steps that are not
/// on screen — to build one error summary for the whole form, and to know
/// which step it has to take the user to when they activate an entry. A step
/// holding opaque widgets could do neither, and a summary assembled by hand
/// beside the form is how a summary comes to list a field that no longer
/// exists.
///
/// A step with no internal grouping is one untitled section:
/// `IuxFormSection(fields: …)`. The section is what keeps
/// `kIuxMinimumTargetSpacing` between two adjacent fields, so going around it
/// would mean losing that floor or restating it.
///
/// [title] is required, unlike [IuxFormSection.title]. A section inside a step
/// may reasonably be unnamed — the step above it already says what this is
/// about — but the step itself is where focus lands every time the user moves,
/// and an unnamed destination is a move a screen-reader user cannot hear.
@immutable
final class IuxGuidedFormStep {
  /// Creates one step.
  const IuxGuidedFormStep({
    required this.title,
    required this.sections,
    this.description,
  })  : assert(title.length > 0, _kEmptyStepTitle),
        assert(sections.length > 0, _kEmptyStep),
        assert(
          description == null || description.length > 0,
          'Pass null rather than an empty description. An empty one reserves a '
          'line, lengthens the announcement by a pause and says nothing.',
        );

  /// What this step is about, already localised.
  ///
  /// Name the questions, not the position: "Delivery address", not "Step 2".
  /// Where the user is comes from
  /// [IuxStepPositionDescription], which is announced beside this, so a title
  /// that repeats the number says the number twice.
  final String title;

  /// What the whole step is for, already localised.
  ///
  /// Use it for something that applies to every question below — why the
  /// address is needed, what happens to it. Anything that applies to one field
  /// is that field's own help text, where the user is looking when they answer
  /// it.
  ///
  /// It is announced on arrival, after the title, so keep it to a sentence: a
  /// paragraph here is a paragraph the user hears before every question, every
  /// time they come back to this step.
  final String? description;

  /// The groups of questions, in the order they are asked.
  final List<IuxFormSection> sections;

  /// Every field of every section of this step, in the order they are asked.
  List<IuxFormField> get fields => <IuxFormField>[
        for (final IuxFormSection section in sections) ...section.fields,
      ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxGuidedFormStep &&
          other.title == title &&
          other.description == description &&
          listEquals(other.sections, sections);

  @override
  int get hashCode => Object.hash(title, description, Object.hashAll(sections));

  @override
  String toString() => 'IuxGuidedFormStep($title, ${fields.length} fields)';
}
