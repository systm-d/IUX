import 'package:flutter/foundation.dart';

/// Why an unnamed confirmation is refused.
const String _kEmptyTitle =
    'A confirmation must say what it is about. The title is what assistive '
    'technology announces when the confirmation appears, so an empty one '
    'interrupts a screen-reader user with no idea by what. Name what is about '
    'to happen — "Delete 3 files?" — never a category such as "Warning".';

/// Why a confirmation with no stated consequence is refused.
const String _kEmptyConsequence =
    'A confirmation must state its consequence. "Are you sure?" describes '
    'nothing: it asks the user to weigh an outcome nobody told them, so the '
    'only thing they can answer is whether they trust their own memory of what '
    'they tapped. Say what the action costs — "The files leave this device and '
    'the shared folder" — already localised.';

/// Why an unlabelled confirming control is refused.
const String _kEmptyConfirmLabel =
    'The confirming control must be labelled, and labelled with its outcome. '
    '"Delete" says what the control does; "OK" and "Yes" answer a question the '
    'user has to read back up the dialog to recover — and a screen-reader user '
    'has to swipe back up to hear.';

/// Why an unlabelled way out is refused.
const String _kEmptyKeepLabel =
    'The way out must be labelled. An unlabelled dismissal is a control a '
    'screen-reader user cannot find and a sighted user will not trust, and '
    '"Cancel" beside "Delete" offers two words for stopping. Name what '
    'survives instead: "Keep the files".';

/// The words a confirmation is made of, already localised.
///
/// A confirmation is not a widget here, it is four sentences: what is about to
/// happen, what it costs, the name of going ahead, and the name of not going
/// ahead. `IuxDestructiveActionController` turns them into an `IuxDialog`;
/// this type exists so the wording is stated once, in the caller's language,
/// and so none of the four can be omitted.
///
/// ```dart
/// IuxConfirmationPrompt(
///   title: l10n.deleteSelectedFilesTitle,       // 'Delete 3 files?'
///   consequence: l10n.deleteSelectedFilesBody,  // 'They leave this device…'
///   confirmLabel: l10n.delete,                  // 'Delete'
///   keepLabel: l10n.keepTheFiles,               // 'Keep the files'
/// )
/// ```
///
/// **Every string is the caller's.** The framework composes no user-facing
/// text, so it cannot ship one language inside another, and it cannot invent
/// the sentence that is the entire reason the user is being interrupted.
///
/// **There is no `isDangerous`, no icon and no tone.** How the confirmation is
/// drawn follows from the action's own
/// `IuxActionDescriptor.intent`, which the controller already holds. A second
/// place to say "this one is serious" is a second place for the two to
/// disagree.
@immutable
final class IuxConfirmationPrompt {
  /// Creates the wording of one confirmation.
  const IuxConfirmationPrompt({
    required this.title,
    required this.consequence,
    required this.confirmLabel,
    required this.keepLabel,
  })  : assert(title.length > 0, _kEmptyTitle),
        assert(consequence.length > 0, _kEmptyConsequence),
        assert(confirmLabel.length > 0, _kEmptyConfirmLabel),
        assert(keepLabel.length > 0, _kEmptyKeepLabel);

  /// What is about to happen, in the user's language.
  ///
  /// Also the name announced when the confirmation opens, which is why it is
  /// required: it is the only thing a screen-reader user hears before the
  /// interruption.
  ///
  /// Name the operation and its scope — "Delete 3 files?" — rather than a
  /// category. "Warning" tells the user that something appeared and refuses to
  /// say what.
  final String title;

  /// What the action costs, stated plainly.
  ///
  /// Required, and it is the reason this type exists. A user cannot consent to
  /// a consequence they were never told, and the confirmations people dismiss
  /// reflexively are exactly the ones that said nothing.
  ///
  /// Write the outcome, not the risk: "The files leave this device and the
  /// shared folder", not "This cannot be undone" — which the user already
  /// suspected and still cannot act on.
  final String consequence;

  /// The visible text of the control that goes ahead.
  ///
  /// Name the outcome: "Delete", "Revoke access", "Leave without saving". A
  /// button labelled "OK" is only meaningful to somebody still holding the
  /// question in their head.
  final String confirmLabel;

  /// The visible text of the way out.
  ///
  /// Name what survives — "Keep the files" — rather than the mechanism.
  /// "Cancel" next to "Delete" is two words for stopping, and a user working
  /// quickly has to decide which one cancels which.
  final String keepLabel;

  /// Returns a copy with the given values replaced.
  IuxConfirmationPrompt copyWith({
    String? title,
    String? consequence,
    String? confirmLabel,
    String? keepLabel,
  }) =>
      IuxConfirmationPrompt(
        title: title ?? this.title,
        consequence: consequence ?? this.consequence,
        confirmLabel: confirmLabel ?? this.confirmLabel,
        keepLabel: keepLabel ?? this.keepLabel,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxConfirmationPrompt &&
          other.title == title &&
          other.consequence == consequence &&
          other.confirmLabel == confirmLabel &&
          other.keepLabel == keepLabel;

  @override
  int get hashCode => Object.hash(title, consequence, confirmLabel, keepLabel);

  @override
  String toString() => 'IuxConfirmationPrompt($title)';
}
