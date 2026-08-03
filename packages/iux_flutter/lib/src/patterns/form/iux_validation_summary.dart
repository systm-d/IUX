import 'package:flutter/widgets.dart';

import '../../accessibility/iux_focus.dart';
import '../../accessibility/iux_semantics.dart';
import '../../accessibility/iux_touch_target.dart';
import '../../components/feedback/iux_inline_feedback_tokens.dart';
import '../../layout/iux_spacing_primitives.dart';
import '../../themes/extensions/iux_geometry_theme.dart';

/// Why a summary with no entries is refused.
const String _kEmptySummary =
    'A summary listing nothing is a red block announcing that something is '
    'wrong and refusing to say what. Render it only while there is at least '
    'one rejected field, and stop rendering it when the last one is fixed.';

/// One rejected field, as it appears in an error summary.
///
/// Both strings are the caller's, already localised, and the pattern that
/// builds these takes them straight from the field: [label] is the field's
/// accessible name and [message] is the message the parent attached when it
/// rejected the value. Nothing here is composed by IUX, so a summary cannot say
/// something the field itself does not.
///
/// [onActivate] is what turns the list from an accusation into a route. A list
/// of errors the user cannot navigate to leaves them scrolling a long form
/// looking for the field the summary just named — and for a screen-reader user,
/// swiping through every control in between.
@immutable
final class IuxValidationSummaryEntry {
  /// Creates an entry pointing at one rejected field.
  const IuxValidationSummaryEntry({
    required this.label,
    required this.message,
    required this.onActivate,
  })  : assert(
          label.length > 0,
          'An entry must name the field it is about. Without a name it says '
          'that something is wrong somewhere, which is the state the summary '
          'exists to end.',
        ),
        assert(
          message.length > 0,
          'An entry must say what is wrong. "Email address" on its own sends '
          'the user back to a field with no more information than they had '
          'before they submitted.',
        );

  /// The field's name, already localised.
  final String label;

  /// What is wrong with it, already localised.
  ///
  /// The same sentence the field shows under itself. Repeating it here is
  /// deliberate: the user reading the summary is not looking at the field, and
  /// a summary that only named the fields would make them travel to each one to
  /// find out what it wanted.
  final String message;

  /// Moves the user to the field.
  ///
  /// Focus, and scrolling if the field is off screen. Built for you by
  /// `IuxForm`; supply it yourself only when you are assembling a summary by
  /// hand.
  final VoidCallback onActivate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxValidationSummaryEntry &&
          other.label == label &&
          other.message == message &&
          other.onActivate == onActivate;

  @override
  int get hashCode => Object.hash(label, message, onActivate);

  @override
  String toString() => 'IuxValidationSummaryEntry($label)';
}

/// The list of everything currently stopping a form from being submitted, with
/// a way to reach each one.
///
/// ```dart
/// IuxValidationSummary(
///   categoryLabel: l10n.error,
///   message: l10n.fieldsNeedAttention(2),
///   entries: <IuxValidationSummaryEntry>[…],
///   focusNode: _summaryFocus,
/// )
/// ```
///
/// **Use it** at the top of a form, after a submission was refused, for as long
/// as something is still refusing it. `IuxForm` builds and places one for you
/// from its own fields, which is the way to get one that cannot drift out of
/// step with the form it describes.
///
/// **Do not use it** before the user has tried to submit. Each field already
/// shows its own message under itself, where the user is looking; a summary
/// that appears while they are still filling the form is the same information a
/// second time, at the top of the screen, about a field they have not reached.
/// Do not use it for a single field either — the field's own message is nearer
/// and needs no travel. And do not use it to report a failure that is not about
/// the fields: a payment declined or a server unavailable is an `IuxAlert`,
/// because there is no field to send the user to.
///
/// **It never decides that it should exist.** The parent renders it or does
/// not, exactly as for every other IUX component.
///
/// ## Accessibility
///
/// The summary is focusable, and being given focus is how a screen-reader user
/// learns that their submission was refused. `IuxForm` moves focus here when a
/// submission fails; if you place one by hand, [focusNode] is how you do the
/// same. A summary that appears silently is a submission that failed silently.
///
/// It is deliberately **not** a live region. It is announced because focus
/// lands on it, and a live region on top of that would speak the same sentence
/// twice — once when it appeared and once when the user arrived. Where focus
/// genuinely cannot move, an `IuxAlert` is the component that announces itself.
///
/// Each entry is a control in its own right, so a screen-reader user moving by
/// control walks the list of problems and can activate any of them. The entries
/// are in the order the fields appear, so the list matches the form rather than
/// the order in which the failures happened to be discovered.
///
/// Nothing here is carried by colour. The block has a glyph and an outline, the
/// entries are underlined and named, and the count is in a sentence the caller
/// wrote.
class IuxValidationSummary extends StatelessWidget {
  /// Creates an error summary.
  const IuxValidationSummary({
    super.key,
    required this.categoryLabel,
    required this.message,
    required this.entries,
    this.focusNode,
    this.navigationHint,
  })  : assert(entries.length > 0, _kEmptySummary),
        assert(
          message.length > 0,
          'The summary must open with a sentence. It is the first thing a '
          'screen-reader user hears when focus arrives here, and the first '
          'thing a sighted user reads after their submission was refused.',
        ),
        assert(
          categoryLabel.length > 0,
          'categoryLabel is the only thing that tells a screen-reader user '
          'this block is an error: the glyph and the tint never reach them. '
          'Pass the localised word — "Error", "Erreur", "エラー".',
        ),
        assert(
          navigationHint == null || navigationHint.length > 0,
          'Pass null rather than an empty hint.',
        );

  /// The localised word for the category — "Error", "Erreur".
  ///
  /// Required, and IUX cannot supply it: the framework holds roles and never
  /// user-facing strings, so a framework-composed word would ship English into
  /// an application that is not in English.
  final String categoryLabel;

  /// The opening sentence, already localised.
  ///
  /// This is where a count belongs — "2 fields need your attention" — and it is
  /// the caller's sentence precisely because of the count. A framework that
  /// composed it would have to know that some languages have one plural form,
  /// some have two, and some have six; it would get it wrong, in a place the
  /// user is already frustrated.
  final String message;

  /// The rejected fields, in the order they appear in the form.
  ///
  /// Must not be empty. See [_kEmptySummary].
  final List<IuxValidationSummaryEntry> entries;

  /// The node that receives focus when the summary appears.
  ///
  /// Owned by the caller. `IuxForm` supplies its own; pass one here only when
  /// you are placing a summary by hand and have to move focus to it yourself.
  final FocusNode? focusNode;

  /// What a screen reader says after each entry's name, already localised.
  ///
  /// Something like "Go to this field". Optional, because the entry is already
  /// named and announced as a control; useful, because "Email address. Must
  /// contain an @, button" does not say what pressing it will do, and the one
  /// thing the user wants to know is whether it costs them anything.
  final String? navigationHint;

  @override
  Widget build(BuildContext context) {
    final IuxInlineFeedbackTokens tokens = IuxInlineFeedbackResolver.resolve(
      context,
      IuxFeedbackCategory.error,
    );

    return IuxSemantics.contentContainer(
      child: IuxFocusable(
        focusNode: focusNode,
        borderRadius: BorderRadius.circular(tokens.radius),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(tokens.radius),
            border: Border.all(
              color: tokens.border,
              width: tokens.borderWidth,
            ),
          ),
          child: Padding(
            padding: IuxInsets.surface(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Not a container, so this annotation merges into the node the
                // focus produced. One node carries "focusable, focused, Error.
                // 2 fields need your attention" — which is what makes arriving
                // here an announcement rather than silence. Split across two
                // nodes, focus would land on the unnamed one.
                Semantics(
                  label: '$categoryLabel. $message',
                  child: IuxSemantics.decorative(
                    child: _IuxSummaryHeader(message: message, tokens: tokens),
                  ),
                ),
                for (final IuxValidationSummaryEntry entry in entries) ...[
                  const IuxGap.tight(),
                  _IuxSummaryEntry(
                    entry: entry,
                    tokens: tokens,
                    hint: navigationHint,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The glyph and the opening sentence.
///
/// Hidden from assistive technology, because the sentence is already on the
/// focusable node above it and the glyph carries the category for the users who
/// can see it. Left in, the summary would be read once on arrival and once
/// again as the user swiped into it.
class _IuxSummaryHeader extends StatelessWidget {
  const _IuxSummaryHeader({required this.message, required this.tokens});

  final String message;
  final IuxInlineFeedbackTokens tokens;

  @override
  Widget build(BuildContext context) => Row(
        // Top-aligned: a glyph centred beside three wrapped lines floats in the
        // middle of the sentence with nothing to anchor it.
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            tokens.glyph,
            size: tokens.iconSize,
            color: tokens.icon,
            // Already scaled once by the resolver, through the runtime every
            // other IUX component reads. Letting Flutter scale it again would
            // enlarge the glyph twice as fast as the words beside it.
            applyTextScaling: false,
          ),
          const IuxGap.horizontal(IuxSpacingStep.xs),
          // Expanded rather than Flexible, so a long sentence wraps inside the
          // block instead of pushing its own right edge off a small screen.
          Expanded(
            child: Text(
              message,
              style: tokens.titleStyle,
              // No line limit and no ellipsis, at any text size. Half a
              // sentence about why a form was refused is a refusal the user
              // cannot act on, and truncation gets worse exactly when someone
              // has enlarged their text because they were struggling to read.
              softWrap: true,
            ),
          ),
        ],
      );
}

/// One entry: a named problem the user can travel to.
///
/// Underlined rather than merely tinted. Inside a block that is already
/// coloured, a differently coloured word asks the user to tell two tints apart
/// in order to find out what is activatable — which is the failure WCAG 1.4.1
/// is about, and which a user reading a monochrome screen cannot do at all.
class _IuxSummaryEntry extends StatelessWidget {
  const _IuxSummaryEntry({
    required this.entry,
    required this.tokens,
    required this.hint,
  });

  final IuxValidationSummaryEntry entry;
  final IuxInlineFeedbackTokens tokens;
  final String? hint;

  @override
  Widget build(BuildContext context) => IuxSemantics.action(
        // Joined with a full stop, which is the pause between two of the
        // caller's own sentences and not a sentence of IUX's own. The
        // alternative is two stops in the reading order for one problem, where
        // the second is a message with nothing to attach it to.
        label: '${entry.label}. ${entry.message}',
        hint: hint,
        onTap: entry.onActivate,
        child: IuxFocusable(
          onActivate: entry.onActivate,
          borderRadius: BorderRadius.circular(tokens.actionRadius),
          child: IuxTapTarget(
            onTap: entry.onActivate,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  entry.label,
                  style: tokens.actionStyle.copyWith(
                    decoration: TextDecoration.underline,
                    decorationColor: tokens.content,
                  ),
                ),
                Text(entry.message, style: tokens.messageStyle),
              ],
            ),
          ),
        ),
      );
}
