import 'package:flutter/widgets.dart';

import '../../accessibility/iux_semantics.dart';
import '../../components/button/iux_button.dart';
import '../../components/feedback/iux_inline_feedback_tokens.dart';
import '../../layout/iux_spacing_primitives.dart';
import '../../themes/extensions/iux_geometry_theme.dart';
import 'iux_recovery_route.dart';

/// Why a failure with no words is refused.
const String _kEmptyMessage =
    'A failure must say what failed. Without a message the user is looking at '
    'a tinted rectangle and a glyph, and a screen-reader user hears the word '
    '"Error" and nothing after it — which is the "something went wrong" this '
    'pattern exists to end. Pass the localised sentence naming what did not '
    'happen: "Your orders could not be loaded", "The payment was declined by '
    'your bank".';

/// Why the localised category word is required.
const String _kEmptyCategoryLabel =
    'categoryLabel is the only thing that tells a screen-reader user this '
    'block is a failure rather than a note: the glyph and the tint never reach '
    'them, and WCAG SC 1.4.1 is exactly the rule that colour may not carry it '
    'alone. Pass the localised word — "Error", "Erreur", "エラー" — not the '
    'enum name.';

/// A region whose content is not there because an operation failed, saying what
/// failed and giving the user the way out that belongs to that failure.
///
/// ```dart
/// IuxErrorRecovery(
///   categoryLabel: l10n.error,
///   message: l10n.yourOrdersCouldNotBeLoaded,
///   route: IuxRetryRoute(
///     label: l10n.tryAgain,
///     onRetry: controller.reload,
///     isRunning: controller.isRunning,
///     busyHint: l10n.reloadingYourOrders,
///   ),
/// )
/// ```
///
/// **Use it** where a list, a section, a form's submission or a whole screen
/// asked a question and got a breakdown instead of an answer: a request that
/// never returned, a server that refused, a payment the bank declined, a
/// document that is no longer there. It is the answer to the `error` row of the
/// component standard's state table, at region scale.
///
/// ## What separates it from the three things it looks like
///
/// | | The content is | The block is |
/// | --- | --- | --- |
/// | `IuxAlert` | still there | a message *beside* it |
/// | [IuxErrorRecovery] | missing, because it failed | what stands in its place |
/// | `IuxEmptyState` | missing, because there is none | what stands in its place |
/// | `IuxValidationSummary` | there, and refused | a list of fields to travel to |
///
/// **Do not use it for a field the user can fix.** A rejected value is not a
/// breakdown: the field owns its own message and shows it where the user is
/// looking, and a form that will not submit gets an `IuxValidationSummary`
/// whose entries travel to the fields. There is nothing to retry — the request
/// was never sent — and [IuxRetryRoute] would offer to send the same rejected
/// value again.
///
/// **Do not use it for an empty answer.** A collection that came back with
/// nothing in it succeeded. `IuxEmptyState` explains an answer, this explains a
/// breakdown, and the two want opposite controls; `IuxEmptyStateAction` refuses
/// `IuxActionRole.retry` so the line cannot be crossed from that side either.
///
/// **Do not use it while the operation is still running.** "It failed" is a
/// statement the interface cannot support until it has, and a screen that makes
/// it early is wrong for as long as the request is in flight. Show progress;
/// reach for this once the parent knows.
///
/// **Do not use it as a dismissible notice.** There is no dismissal here and
/// there will not be one: closing this would erase the only account of why the
/// region is empty while the region is still empty. A failure the user may
/// wave away is an `IuxAlert` beside content that still exists.
///
/// ## The route is required, which is the whole design
///
/// **An error the user cannot act on is an apology, not recovery.** There is no
/// optional action parameter: [route] is required, it is a sealed type, and
/// every member of it answers *what now* — two with a control and one with a
/// sentence. A caller who has nothing to offer has to name [IuxUnrecoverable]
/// and write the sentence, which is the smallest deliberate act that keeps
/// "nothing can be done" off the path of least resistance.
///
/// That is also how WCAG SC 3.3.3 is met structurally rather than by review: a
/// suggestion is present because the type system will not build the block
/// without one. SC 3.3.1 is met by [message], which is text and not a tint.
///
/// See [IuxRecoveryRoute] for the table of which failures may be retried and
/// which must never be.
///
/// ## Nothing here retries by itself
///
/// No timer, no attempt counter, no backoff — see [IuxRetryRoute]. Two
/// consequences worth stating plainly: a failing service is never hammered by
/// this pattern, and a non-idempotent operation is never re-sent without the
/// user asking. It also means the pattern imposes no time limit of any kind, so
/// WCAG SC 2.2.1 has nothing to adjust.
///
/// ## What it puts on screen
///
/// The failure as one tinted block — glyph, then the sentence — and the
/// route's control on the page *below* it, in that order.
///
/// The block is tinted where `IuxEmptyState` is not, and the reason is the
/// contrast guarantee rather than emphasis. Every colour comes from one
/// `IuxFeedbackRoleColors`, whose content colour the theme measured against its
/// own surface; text drawn in that colour on the page behind it would be a pair
/// nobody measured. Tinting is what keeps the block inside the pair that was.
///
/// The control sits outside the block for the mirror-image reason. `IuxButton`
/// resolves its container against the page surface, so a button dropped inside
/// a tinted block would paint a patch of page colour into it and carry a label
/// colour measured against the page. This is the composition `IuxAlert`
/// prescribes in so many words — put the button below the message and let it
/// own its own state — and it is what lets the retry keep a real operation,
/// a real busy announcement and a real repeat policy instead of the
/// lifecycle-free control an inline message can hold.
///
/// Nothing animates. The block's arrival is the parent's to transition, and an
/// entrance animation here would delay the announcement below it to save
/// nothing. There is therefore nothing for a reduced-motion preference to
/// remove.
///
/// ## Accessibility
///
/// **The failure is announced where it appears.** The block is a live region
/// carrying one label — the category word, the message, and the guidance when
/// there is one — so the platform speaks it once, in place, and the user can go
/// back over it. It is a live region unconditionally, unlike `IuxEmptyState`,
/// which takes an arrival dimension: a region that is empty may always have
/// been, but a region that failed is an event by definition. Where a failure is
/// genuinely on screen before the user is, the caller owns whether the block is
/// rendered at all.
///
/// **Focus is not moved, and there is no hook to move it.** This is the same
/// conclusion `IuxEmptyState` reached and the opposite of
/// `IuxValidationSummary`, and the difference is what the framework knows.
/// `IuxForm` moves focus to its summary because it knows the user just pressed
/// submit and is standing still waiting for an answer. Nothing here knows that:
/// an operation can fail while the user is typing somewhere else, or in the
/// background, or after they have moved on, and taking focus then interrupts
/// them to announce something they did not ask about.
///
/// The specific hazard is worse than interruption. The control this block
/// offers is usually a retry, and focus landing on a retry puts an activation
/// under the next Enter or the next screen-reader double-tap — so the one
/// pattern in the library whose control must never fire twice would be the one
/// that armed itself. The live region says everything focus would have said and
/// arms nothing.
///
/// **The message is one stop, the control is another.** The block merges into a
/// single node, so a screen-reader user hears the whole explanation as one
/// utterance instead of landing on fragments; the control keeps its own node,
/// because it is somewhere the user has to be able to land.
///
/// **Nothing is carried by colour** (SC 1.4.1). The category reaches a screen
/// reader through [categoryLabel], a monochrome screen through the glyph's
/// shape, and everyone through the wording — three carriers, so any one of them
/// can fail.
///
/// Target size, focus indication, keyboard and D-pad activation, disabled
/// semantics and text scaling on the control are `IuxButton`'s, which is why
/// this pattern delegates to it rather than drawing a control of its own.
///
/// ## Known limitations
///
/// A live region is a request, not a guarantee: a widget test can assert that
/// the node carries the flag and no more, so TalkBack remains a manual check.
/// Nothing essential depends on the announcement — the same words are on
/// screen either way.
///
/// The block does not scroll and imposes no scroll view. A long message at a
/// large text scale in a short viewport is the caller's to place inside
/// something scrollable, because a region embedded in a list that already
/// scrolls must not introduce a second one.
///
/// It reports one failure. A screen with three failed sections shows three of
/// these, beside the three things that failed; there is no collected list of
/// failures, and `IuxValidationSummary` is not a substitute for one because it
/// travels to fields.
class IuxErrorRecovery extends StatelessWidget {
  /// Creates a failed region with its way out.
  const IuxErrorRecovery({
    super.key,
    required this.route,
    required this.categoryLabel,
    required this.message,
  })  : assert(message.length > 0, _kEmptyMessage),
        assert(categoryLabel.length > 0, _kEmptyCategoryLabel);

  /// The way out of this failure, and therefore what the block offers.
  ///
  /// See [IuxRecoveryRoute]. Choosing the member is the one decision this
  /// pattern asks the caller to make deliberately, because whether the identical
  /// request could succeed a second time is a fact about the failure that no
  /// framework can read.
  final IuxRecoveryRoute route;

  /// The localised word for the category — "Error", "Erreur".
  ///
  /// Required, and IUX cannot supply it: the framework holds roles and never
  /// user-facing strings, so a framework-composed word would ship English into
  /// an application that is not in English. It is also the only carrier of the
  /// category that survives a screen reader, a monochrome display and an
  /// inverted one.
  final String categoryLabel;

  /// What failed, already localised.
  ///
  /// Name what the user does not have — "Your orders could not be loaded",
  /// "The payment was declined by your bank" — rather than what the system
  /// experienced. "An unexpected error occurred" is a sentence that spends the
  /// user's attention and returns nothing: they can already see that something
  /// went wrong, and what they need is which of their things is affected.
  ///
  /// Say only what is true. A message that blames the connection on a server
  /// fault sends the user to restart a router that was working, and they will
  /// not believe the next message either.
  ///
  /// It wraps rather than truncates, at any text size. There is no line limit
  /// and no ellipsis: half a sentence about a failure is a failure the user
  /// cannot act on, and truncation gets worse exactly when someone has enlarged
  /// their text because they were struggling to read.
  final String message;

  @override
  Widget build(BuildContext context) {
    final IuxInlineFeedbackTokens tokens = IuxInlineFeedbackResolver.resolve(
      context,
      IuxFeedbackCategory.error,
    );

    // Read from the route rather than taken as a parameter. Guidance is
    // required exactly where there is no control and absent everywhere else,
    // which is a rule the sealed type already holds; a parameter here would be
    // a second place for it to be omitted.
    final String? guidance = switch (route) {
      IuxUnrecoverable(guidance: final String words) => words,
      IuxRetryRoute() || IuxAlternativeRoute() => null,
    };

    final BorderSide side = BorderSide(
      color: tokens.border,
      width: tokens.borderWidth,
    );

    return IuxSemantics.contentContainer(
      child: Column(
        // The block takes the width it is given; the control takes its own and
        // sits at the start of the reading order, which right-to-left mirrors
        // without this widget knowing which language it is in.
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // One node, one utterance, one live region. The label rides on the
          // same node that is announced: a live container above an unlabelled
          // block would be a change reported and not described.
          IuxSemantics.liveRegion(
            label: _spokenText(guidance),
            child: IuxSemantics.decorative(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: tokens.surface,
                  borderRadius: BorderRadius.circular(tokens.radius),
                  border: Border.fromBorderSide(side),
                ),
                child: Padding(
                  padding: IuxInsets.surface(context),
                  child: Row(
                    // Top-aligned: a glyph centred beside four wrapped lines
                    // floats in the middle of the sentence with nothing to
                    // anchor it.
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(
                        tokens.glyph,
                        size: tokens.iconSize,
                        color: tokens.icon,
                        // Already scaled once by the resolver, through the
                        // runtime every other IUX component reads. Letting
                        // Flutter scale it again would enlarge the glyph twice
                        // as fast as the words beside it.
                        applyTextScaling: false,
                      ),
                      const IuxGap.horizontal(IuxSpacingStep.xs),
                      // Expanded rather than Flexible, so a long sentence wraps
                      // inside the block instead of pushing its own edge off a
                      // small screen at 200% text.
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              message,
                              style: tokens.messageStyle,
                              softWrap: true,
                            ),
                            if (guidance != null) ...<Widget>[
                              const IuxGap.tight(),
                              Text(
                                guidance,
                                style: tokens.messageStyle,
                                softWrap: true,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ..._control(),
        ],
      ),
    );
  }

  /// What a screen reader says when the block appears.
  ///
  /// Joined here rather than asked of the caller, because the alternative is a
  /// third required string on every call site and two or three separate stops
  /// in the reading order for one explanation. The parts are always the
  /// caller's; only the pause between them is IUX's, which is the same trade
  /// `IuxAlert` and `IuxValidationSummary` already make.
  String _spokenText(String? guidance) => <String>[
        categoryLabel,
        message,
        if (guidance != null) guidance,
      ].join('. ');

  /// The route's control, or nothing when the route is a sentence.
  ///
  /// Returns the gap with it, so a block with no control carries no trailing
  /// space — an [IuxUnrecoverable] ends where its words end.
  List<Widget> _control() {
    final Widget? control = switch (route) {
      final IuxRetryRoute retry => IuxButton(
          label: retry.label,
          action: retry.descriptor,
          busyHint: retry.busyHint,
          // The descriptor's repeat policy is what refuses a second attempt
          // while the first is in flight; this callback is only ever reached
          // for an activation the policy already accepted.
          onActivate: retry.onRetry,
        ),
      final IuxAlternativeRoute elsewhere => IuxButton(
          label: elsewhere.action.label,
          action: elsewhere.descriptor,
          onActivate: elsewhere.action.onActivate,
        ),
      IuxUnrecoverable() => null,
    };

    if (control == null) return const <Widget>[];
    return <Widget>[const IuxGap.between(), control];
  }
}
