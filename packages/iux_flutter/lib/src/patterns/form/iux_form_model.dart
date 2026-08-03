import 'package:flutter/widgets.dart';

import '../../inputs/iux_input_descriptor.dart';

/// When the form asks the parent to check a field.
///
/// This is the whole question of a form pattern, and it has two bad answers.
///
/// Checking on every keystroke tells a user their email address is invalid
/// while they are typing the third character of it — an error about something
/// that was never wrong yet, only unfinished. Checking nothing until the user
/// presses Submit hands them a screen of failures at once, usually after they
/// believed they were done, and usually about the field they filled in first
/// and can no longer see.
///
/// IUX takes the middle answer and makes it the default: a field is checked
/// when the user leaves it, and everything is checked again on submit. The user
/// is told about one field at a time, at the moment they have finished with it
/// and before they have moved on far enough to have to come back.
///
/// Two things make that answer safe rather than merely reasonable:
///
/// - a field is only checked on blur once the parent says it was edited
///   ([IuxFormField.edited]), so tabbing through a form does not produce a
///   column of "required" errors about fields the user never touched;
/// - a field that has already been rejected should be re-checked as the user
///   repairs it, so the error clears while they are looking at it rather than
///   on the next submit. The form cannot do that itself — it never sees the
///   value — so the parent does it from its own `onChanged`. See
///   `docs/patterns/guided-form.md`.
///
/// There is no `onChange` value, and its absence is deliberate rather than an
/// omission. The form never sees a keystroke: the value lives in the parent's
/// controller and goes straight from the field to the parent. A value here that
/// the form could not honour would be a setting that silently did nothing,
/// which is worse than no setting. A parent that genuinely wants per-keystroke
/// checking already has everything it needs, and the documentation says when
/// that is defensible — a character counter, a password rule the user can watch
/// being satisfied — and when it is not.
enum IuxValidationTiming {
  /// Checked when the user leaves an edited field, and again on submit.
  ///
  /// The default, and the one to keep unless there is a reason not to.
  onBlur,

  /// Checked only when the user submits.
  ///
  /// Right for a short form whose fields are cheap to fix and where an
  /// interruption per field would outweigh the correction — and for a field
  /// whose check is expensive enough that running it per field would cost the
  /// user their data allowance. It is the weaker default: the user learns
  /// about every problem at the same moment, which is the moment they thought
  /// they had finished.
  onSubmit,
}

/// What made the form ask for a check.
///
/// Passed to [IuxFormField.onValidationRequested] so the parent can answer
/// differently. The usual reason to care: a rule that costs a network round
/// trip — is this user name taken — belongs on [submit], while a rule that is
/// a local test of shape can run on either.
enum IuxValidationTrigger {
  /// The user left the field, having edited it.
  blur,

  /// The user asked to submit the form.
  submit,
}

/// One field inside a form: what it is, where its focus lives, and how to draw
/// it.
///
/// ```dart
/// IuxFormField(
///   input: state.emailDescriptor,
///   focusNode: _emailFocus,
///   edited: state.emailEdited,
///   onValidationRequested: (_) => controller.checkEmail(),
///   child: IuxTextField(
///     input: state.emailDescriptor,
///     controller: _email,
///     focusNode: _emailFocus,
///     onChanged: controller.emailChanged,
///     content: IuxTextContent.email,
///   ),
/// )
/// ```
///
/// It is a description rather than a widget because the form needs three things
/// the widget cannot be asked for: whether the field is currently rejected, so
/// it can be listed in the summary; where its focus node is, so the summary can
/// send the user to it; and a way to ask for a check when the user leaves it.
///
/// **[focusNode] must be the same node the field widget was given.** It is the
/// only link between an entry in the error summary and the box the user has to
/// go and fix, and nothing can check it for you: passing a second, unused node
/// produces a summary whose entries look right and go nowhere. This is the one
/// mistake this API can still make, and it is the reason the parameter is
/// required rather than optional.
@immutable
final class IuxFormField {
  /// Creates a field entry.
  const IuxFormField({
    required this.input,
    required this.focusNode,
    required this.child,
    this.edited = false,
    this.onValidationRequested,
  });

  /// What the field is, and what the parent has decided about its value.
  ///
  /// The same descriptor the widget in [child] was given. The form reads
  /// [IuxInputDescriptor.validation] to decide what the summary lists, and
  /// [IuxInputSemantics.label] to name the entry — both of which are the
  /// parent's strings, already localised.
  final IuxInputDescriptor input;

  /// The field's focus node, owned and disposed by the parent.
  ///
  /// Required, and it must be the node the widget in [child] actually uses.
  /// See the class documentation.
  final FocusNode focusNode;

  /// The field widget itself.
  ///
  /// Usually an `IuxTextField`, an `IuxCheckbox`, an `IuxRadioGroup`. The form
  /// renders it untouched: it lays fields out and never decorates them, so a
  /// field looks the same inside a form as outside one.
  final Widget child;

  /// Whether the user has changed this value since the form was built.
  ///
  /// The form asks for a check when the user leaves an edited field, and asks
  /// for nothing when they leave one they merely passed through. Without this,
  /// a keyboard user tabbing to the bottom of a form to reach Submit would
  /// arrive to find every field they crossed marked as an error — errors about
  /// values that were never wrong, only absent.
  ///
  /// Defaults to false, which is the cautious answer rather than the useful
  /// one. A form that checks nothing on blur is merely less helpful than it
  /// could be; a form that checks fields the user never touched is actively
  /// telling them they made a mistake they did not make. Wire it from whatever
  /// the parent already sets in its own `onChanged`.
  ///
  /// It does not affect submit. Submitting asks for every field to be checked,
  /// edited or not, because a required field that was never touched is exactly
  /// the one that has to be caught there.
  final bool edited;

  /// Called when the form asks the parent to check this field.
  ///
  /// The form never validates anything. It knows when a check is worth running
  /// — the user left the field, the user pressed Submit — and nothing at all
  /// about whether the value is acceptable, which is the parent's to decide and
  /// to report back through [input].
  ///
  /// Null means "there is nothing to check here", which is the honest state for
  /// a field with no rule attached to it.
  final ValueChanged<IuxValidationTrigger>? onValidationRequested;

  /// Whether this field is currently rejected.
  bool get isInvalid => input.hasError;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxFormField &&
          other.input == input &&
          other.focusNode == focusNode &&
          other.child == child &&
          other.edited == edited &&
          other.onValidationRequested == onValidationRequested;

  @override
  int get hashCode =>
      Object.hash(input, focusNode, child, edited, onValidationRequested);

  @override
  String toString() => 'IuxFormField(${input.semantics.label}, '
      '${input.validation.status.name})';
}
