import 'package:flutter/material.dart';

import '../../accessibility/iux_focus.dart';
import '../../accessibility/iux_focus_ownership.dart';
import '../../accessibility/iux_semantics.dart';
import '../../accessibility/iux_touch_target.dart';
import '../../layout/iux_spacing_primitives.dart';
import '../../themes/extensions/iux_geometry_theme.dart';
import 'iux_inline_feedback_tokens.dart';

/// Why an empty message is refused.
const String _kEmptyMessage =
    'An inline message with no text is a coloured rectangle. A sighted user '
    'sees that something is wrong and cannot tell what; a screen-reader user '
    'hears the category and nothing else. Pass the localised sentence.';

/// Why the localised category word is required.
const String _kEmptyCategoryLabel =
    'categoryLabel is the only thing that tells a screen-reader user which '
    'category this is: the glyph and the tint never reach them. Pass the '
    'localised word — "Error", "Erreur", "エラー" — not the enum name.';

/// Why an empty title is refused rather than ignored.
const String _kEmptyTitle =
    'An empty title is a blank first line and an extra pause in the spoken '
    'message. Omit the parameter instead of passing an empty string.';

/// Why an error may not offer dismissal as its only control.
const String _kErrorDismissWithoutRecovery =
    'An error that can only be dismissed asks the user to erase the one '
    'explanation of why their screen is broken, while the failure itself is '
    'still there. Give it an action — retry, open settings, edit the field — '
    'so closing it is a choice and not amnesia. If there is genuinely nothing '
    'to do, leave it undismissible: the message is the only account of the '
    'state the user is in.';

/// A labelled control with no lifecycle of its own.
///
/// The library's value for "a control that has a name and does one thing", and
/// the name is deliberately about the shape rather than about any one place it
/// is used. It began as the recovery path inside an inline message and was
/// called `IuxInlineFeedbackAction` for that reason, which had stopped being
/// true: `IuxAlternativeRoute` carries one inside `IuxErrorRecovery`, both
/// answers of `IuxPermissionRationale` are one, and so are the two controls of
/// `IuxOnboardingFlow`. A name that says "inline feedback" on a permission
/// prompt teaches the caller something false about where the type belongs
/// (IUX-API-NAMING-001).
///
/// This exists because of the single most common failure in this component
/// family: a message that says what went wrong and stops there. "Something
/// went wrong" is a message that spent the user's attention and returned
/// nothing. Naming the next step — *Retry*, *Open settings*, *Use a different
/// card* — is what turns a report into a way out.
///
/// It is not an `IuxActionDescriptor`, and that is a deliberate boundary. Half
/// of that model has no meaning here: `intent` cannot vary because the
/// category already fixes the colour, and `confirmation`, `cancellation` and a
/// running `operation` all describe an action with a lifecycle of its own,
/// which does not belong inside a sentence the user is still reading. When you
/// need those, put an [IuxButton] below the message and let it own its own
/// state.
@immutable
final class IuxNamedAction {
  /// Creates a labelled control.
  const IuxNamedAction({
    required this.label,
    required this.onActivate,
    this.semanticLabel,
  })  : assert(
          label.length > 0,
          'An unlabelled control inside a message is a control nobody can '
          'identify. Pass the localised verb.',
        ),
        assert(
          semanticLabel == null || semanticLabel.length > 0,
          'An empty semanticLabel would replace the visible one with nothing. '
          'Omit it instead.',
        );

  /// The visible text, already localised.
  ///
  /// Name the outcome, not the mechanism: *Try again* rather than *OK*. A
  /// control labelled "OK" inside an error tells the user nothing about what
  /// pressing it will do, and the one thing they want to know is whether it
  /// costs them anything.
  final String label;

  /// Called once per activation.
  ///
  /// The message never changes as a result. The parent owns whether this
  /// message is on screen and replaces it when the state it describes changes
  /// — a component that hid itself on retry would hide a failure that is still
  /// happening.
  final VoidCallback onActivate;

  /// What a screen reader announces instead of [label], when the visible text
  /// is too terse to stand on its own.
  ///
  /// A screen holding three failures has three controls called *Retry*, and a
  /// user moving through them by control cannot tell which is which. "Retry
  /// uploading the photographs" costs the sighted user nothing and tells the
  /// other one where they are.
  final String? semanticLabel;

  /// The accessible name actually used.
  String get effectiveSemanticLabel => semanticLabel ?? label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxNamedAction &&
          other.label == label &&
          other.onActivate == onActivate &&
          other.semanticLabel == semanticLabel;

  @override
  int get hashCode => Object.hash(label, onActivate, semanticLabel);

  @override
  String toString() => 'IuxNamedAction($label)';
}

/// The ability to remove an inline message from the screen.
///
/// One object rather than two parameters, so a dismissible message cannot
/// exist without an accessible name for the control that dismisses it. A close
/// control is an icon and nothing else; unnamed, it reaches a screen reader as
/// "button" and the user has to activate it to find out what it removes.
///
/// **Offer dismissal only when the information survives being removed.** The
/// test is not whether the message is annoying, it is whether the user can
/// still get the fact back:
///
/// | Message | Dismissible |
/// | --- | --- |
/// | a success confirmation | yes — once read it is spent |
/// | an informational note the user has now seen | yes |
/// | a standing condition shown elsewhere too, such as offline with an offline icon in the bar | yes |
/// | a validation failure explaining why a form will not submit | **no** — the form is still refusing |
/// | a warning about what the next action will cost | **no** — the cost has not gone away |
/// | an error with no recovery path | **no**, and the constructor refuses it |
///
/// A message that reappears the moment the user acts is worse than one that
/// never left: it teaches them that closing things does nothing, and the next
/// message they close is the one that mattered.
@immutable
final class IuxInlineFeedbackDismissal {
  /// Creates a dismissal control.
  const IuxInlineFeedbackDismissal({
    required this.label,
    required this.onDismissed,
  }) : assert(
          label.length > 0,
          'The dismiss control is an icon with no text. Without a name it '
          'reaches a screen reader as "button", and the only way to find out '
          'what it removes is to remove it. Pass a localised name.',
        );

  /// The accessible name of the control, already localised.
  ///
  /// Say what disappears, not what the widget is: "Dismiss the offline
  /// notice", not "Close". On a screen with two dismissible messages, "Close"
  /// twice is two identical controls with different consequences.
  final String label;

  /// Called once per activation.
  ///
  /// The message does not remove itself. The parent owns the state, so it is
  /// the parent that stops rendering this — which is also what stops a
  /// dismissed message reappearing on the next rebuild.
  final VoidCallback onDismissed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxInlineFeedbackDismissal &&
          other.label == label &&
          other.onDismissed == onDismissed;

  @override
  int get hashCode => Object.hash(label, onDismissed);
}

/// A message about the content beside it.
///
/// ```dart
/// IuxAlert(
///   category: IuxFeedbackCategory.error,
///   categoryLabel: l10n.error,
///   message: l10n.cardDeclined,
///   action: IuxNamedAction(
///     label: l10n.useAnotherCard,
///     onActivate: controller.changePaymentMethod,
///   ),
/// )
/// ```
///
/// **Use it** for something that concerns one part of the screen and is caused
/// by what is there: a form that will not submit, a field that failed
/// validation as a group, a section whose data could not be loaded, an
/// operation that just succeeded. Put it next to what it is about. A message
/// about the payment section, parked at the top of the page, makes the user
/// hunt for the thing it refers to.
///
/// **Do not use it** for a condition that spans the whole screen — that is
/// [IuxBanner], and the distinction is scope rather than appearance. Do not use
/// it for a per-field validation message either: a field owns its own error
/// and shows it under itself, so an alert repeating it is the same failure
/// announced twice. Do not use it for something transient that needs no
/// response; a message that disappears on its own is IUX-015. And do not use it
/// to congratulate the user on something they can already see: a success alert
/// beside a list that now contains the new row is noise with a tick on it.
///
/// **The parent owns whether this exists.** [IuxAlert] never decides that it
/// should appear, never removes itself, and never changes after a control
/// inside it is used. It renders what it is given.
///
/// ## Accessibility
///
/// The whole block is one live region. When it appears, or when its text
/// changes, the platform announces it — once, in place, and the user can go
/// back and re-read it. IUX does not call an announcement API here: on Android
/// that clears TalkBack's speech queue, and a message that is *on screen* has
/// no business interrupting. A user who heard it announced and then reaches it
/// by swiping would otherwise hear it twice.
///
/// The category reaches a screen reader through [categoryLabel], never through
/// the tint or the glyph. Both of those exist for the users who can see them,
/// and neither is ever the only carrier: glyph, wording and colour say the same
/// thing three times, so any one of them can fail.
///
/// ## Motion
///
/// Only one thing animates: the container, when the category changes
/// underneath it — a warning becoming an error while the user is looking at it.
/// It is declared as [IuxMotionRole.stateChange], so a reduced-motion
/// preference shortens it and no motion removes it, and nothing is lost either
/// way because the glyph and the words changed too.
///
/// The arrival is deliberately not animated. The parent decides when this is on
/// screen, and a component that animated its own entrance would fight whatever
/// transition the parent had already wrapped it in.
class IuxAlert extends StatelessWidget {
  /// Creates a message about adjacent content.
  const IuxAlert({
    super.key,
    required this.category,
    required this.categoryLabel,
    required this.message,
    this.title,
    this.action,
    this.dismissal,
  })  : assert(message.length > 0, _kEmptyMessage),
        assert(categoryLabel.length > 0, _kEmptyCategoryLabel),
        assert(title == null || title.length > 0, _kEmptyTitle),
        assert(
          !(category == IuxFeedbackCategory.error &&
              dismissal != null &&
              action == null),
          _kErrorDismissWithoutRecovery,
        );

  /// What the message is about.
  ///
  /// Chooses the glyph and the colour pair. It does not choose the wording,
  /// which is why [categoryLabel] exists beside it.
  final IuxFeedbackCategory category;

  /// The localised name of [category] — "Error", "Warning", "Success".
  ///
  /// Required, because it is the whole of what a screen-reader user gets of
  /// the category. IUX cannot supply it: the engine holds roles and never
  /// user-facing strings, so a framework-composed word would ship English into
  /// a Japanese application.
  final String categoryLabel;

  /// What happened, already localised.
  ///
  /// For anything that went wrong, this must answer two questions and not one:
  /// what happened, and what the user can do about it. "Something went wrong"
  /// answers neither, and a message that spends the user's attention without
  /// giving them a way forward is worse than silence — the user now knows they
  /// are stuck and still does not know why.
  ///
  /// Wraps rather than truncates, at any text size. There is no line limit and
  /// no ellipsis: an alert holds sentences, and half a sentence about a failure
  /// is a failure the user cannot act on.
  final String message;

  /// A short first line, already localised, when the message needs a summary.
  ///
  /// Usually unnecessary. Two levels of text in a message this size is two
  /// things to read before knowing whether it matters; reach for it only when
  /// the message runs long enough that a scanning user needs a handle.
  final String? title;

  /// What the user can do about it.
  ///
  /// Optional in the type system and close to mandatory in practice for
  /// [IuxFeedbackCategory.error]. See [IuxNamedAction].
  final IuxNamedAction? action;

  /// How the user removes the message, or null when they may not.
  ///
  /// Null is the right answer more often than it looks. See
  /// [IuxInlineFeedbackDismissal] for which is which.
  final IuxInlineFeedbackDismissal? dismissal;

  @override
  Widget build(BuildContext context) => _IuxInlineFeedback(
        category: category,
        categoryLabel: categoryLabel,
        message: message,
        title: title,
        action: action,
        dismissal: dismissal,
        edgeToEdge: false,
      );
}

/// A message about the whole screen or session.
///
/// ```dart
/// IuxBanner(
///   category: IuxFeedbackCategory.warning,
///   categoryLabel: l10n.warning,
///   message: l10n.workingOffline,
///   action: IuxNamedAction(
///     label: l10n.retryConnection,
///     onActivate: controller.reconnect,
///   ),
/// )
/// ```
///
/// **Use it** for a standing condition that is not the consequence of anything
/// the user just did here: working offline, a service degraded, a subscription
/// expiring, an account not yet verified. It sits at the top of the region it
/// governs and stays until the condition ends.
///
/// **Do not use it** for the result of an action — that is [IuxAlert], placed
/// beside the thing it concerns. The two are not a choice of shape: a banner is
/// read as "this applies to everything below", so putting a single field's
/// failure in one sends the user looking for a screen-wide problem that does
/// not exist. Do not stack banners either. Two conditions at the top of a
/// screen is a screen whose actual content starts halfway down, and the second
/// one is not read.
///
/// **The parent owns whether this exists**, exactly as for [IuxAlert].
///
/// Structurally it differs from an alert in one respect: it spans its region
/// edge to edge, with square corners and a rule above and below rather than an
/// outline. That follows from the scope — it is anchored to the region's edges
/// rather than floating inside its padding — and it is the visible cue that
/// tells the user this message is not about any one thing on the page.
///
/// Accessibility, motion and the dismissal rules are those of [IuxAlert].
class IuxBanner extends StatelessWidget {
  /// Creates a message about the whole screen or session.
  const IuxBanner({
    super.key,
    required this.category,
    required this.categoryLabel,
    required this.message,
    this.title,
    this.action,
    this.dismissal,
  })  : assert(message.length > 0, _kEmptyMessage),
        assert(categoryLabel.length > 0, _kEmptyCategoryLabel),
        assert(title == null || title.length > 0, _kEmptyTitle),
        assert(
          !(category == IuxFeedbackCategory.error &&
              dismissal != null &&
              action == null),
          _kErrorDismissWithoutRecovery,
        );

  /// What the condition is.
  final IuxFeedbackCategory category;

  /// The localised name of [category], for the users who never see the glyph.
  final String categoryLabel;

  /// The condition, already localised.
  ///
  /// A banner is read once and then becomes furniture, so it has to be worth
  /// the room it takes on every screen below it. State the consequence for the
  /// user — "Changes are saved on this device until you reconnect" — rather
  /// than the system's own status.
  final String message;

  /// A short first line, already localised.
  final String? title;

  /// What the user can do about the condition.
  final IuxNamedAction? action;

  /// How the user removes the banner, or null when they may not.
  ///
  /// A banner describing a condition the user cannot fix and cannot see
  /// elsewhere should not be dismissible: removing it leaves the application
  /// behaving oddly with nothing on screen to explain why.
  final IuxInlineFeedbackDismissal? dismissal;

  @override
  Widget build(BuildContext context) => _IuxInlineFeedback(
        category: category,
        categoryLabel: categoryLabel,
        message: message,
        title: title,
        action: action,
        dismissal: dismissal,
        edgeToEdge: true,
      );
}

/// The container, semantics and layout both inline messages share.
///
/// Private on purpose. It is the answer to "what does an IUX inline message
/// look and behave like", and there is one answer: an alert and a banner must
/// not be able to drift apart on which glyph a warning gets, on whether the
/// text is inside the live region, or on how large the dismiss target is.
class _IuxInlineFeedback extends StatelessWidget {
  const _IuxInlineFeedback({
    required this.category,
    required this.categoryLabel,
    required this.message,
    required this.title,
    required this.action,
    required this.dismissal,
    required this.edgeToEdge,
  });

  final IuxFeedbackCategory category;
  final String categoryLabel;
  final String message;
  final String? title;
  final IuxNamedAction? action;
  final IuxInlineFeedbackDismissal? dismissal;
  final bool edgeToEdge;

  /// What a screen reader says when the message appears or changes.
  ///
  /// Joined here rather than asked of the caller, because the alternative is a
  /// fourth required string on every call site and three separate stops in the
  /// reading order for one sentence. The parts themselves are always the
  /// caller's; only the pause between them is IUX's, which is the same trade
  /// `IuxSemantics.action` already makes when it appends a hint.
  String get _spokenText => <String>[
        categoryLabel,
        if (title != null) title!,
        message,
      ].join('. ');

  @override
  Widget build(BuildContext context) {
    final IuxInlineFeedbackTokens tokens = IuxInlineFeedbackResolver.resolve(
      context,
      category,
    );

    final BorderSide side = BorderSide(
      color: tokens.border,
      width: tokens.borderWidth,
    );

    return IuxSemantics.liveRegion(
      label: _spokenText,
      child: AnimatedContainer(
        duration: tokens.motion.duration,
        curve: tokens.motion.curve,
        padding: IuxInsets.surface(context),
        decoration: BoxDecoration(
          color: tokens.surface,
          // A banner takes the region's own side edges, so an outline there
          // would draw a line down the screen. An alert floats inside the
          // page padding and needs the whole outline to read as one block:
          // the surface tint alone is intentionally gentle, and gentle is not
          // enough to delimit a region under high contrast or on a screen the
          // user has inverted.
          borderRadius:
              edgeToEdge ? null : BorderRadius.circular(tokens.radius),
          border: edgeToEdge
              ? Border(top: side, bottom: side)
              : Border.fromBorderSide(side),
        ),
        child: Row(
          // Top-aligned: the glyph belongs beside the first line, and a
          // centred glyph beside four wrapped lines floats in the middle of
          // the message with nothing to anchor it.
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Excluded from the semantic tree. The category is already in the
            // live region's label, and an icon announced separately makes the
            // user swipe past "image" before reaching the message.
            IuxSemantics.decorative(
              child: Icon(
                tokens.glyph,
                size: tokens.iconSize,
                color: tokens.icon,
                // Scaled once, by the runtime every other IUX component reads.
                // Letting Flutter scale it again would enlarge the glyph twice
                // as fast as the text beside it.
                applyTextScaling: false,
              ),
            ),
            const IuxGap.horizontal(IuxSpacingStep.xs),
            // Expanded rather than Flexible: the text takes whatever the glyph
            // and the dismiss control leave, which is what keeps the dismiss
            // control on screen at 200% text on a small phone instead of being
            // pushed past the edge by a long sentence.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IuxSemantics.decorative(child: _text(tokens)),
                  if (action != null) ...<Widget>[
                    const IuxGap.tight(),
                    _IuxNamedActionControl(
                      action: action!,
                      tokens: tokens,
                    ),
                  ],
                ],
              ),
            ),
            if (dismissal != null) ...<Widget>[
              const IuxGap.horizontal(IuxSpacingStep.xs),
              _IuxInlineFeedbackDismissControl(
                dismissal: dismissal!,
                tokens: tokens,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// The words, with no line limit and no ellipsis at any text size.
  ///
  /// "We could not charge your card because th…" is a message the user cannot
  /// act on, and truncation gets worse exactly when someone has enlarged their
  /// text because they were struggling to read it.
  Widget _text(IuxInlineFeedbackTokens tokens) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (title != null) ...<Widget>[
            Text(title!, style: tokens.titleStyle),
            const IuxGap(IuxSpacingStep.xxs),
          ],
          Text(message, style: tokens.messageStyle),
        ],
      );
}

/// The recovery control.
///
/// Not an [IuxButton], and the reason is contrast rather than convenience.
/// A button resolves its container against the page surface, so a text or
/// outlined button dropped into a tinted message would paint a patch of page
/// colour inside it, and its label would carry an action colour that was
/// measured against the page and never against this surface. Drawing it from
/// the same [IuxFeedbackRoleColors] as the message keeps the pair the theme
/// actually verified.
class _IuxNamedActionControl extends StatelessWidget {
  const _IuxNamedActionControl({
    required this.action,
    required this.tokens,
  });

  final IuxNamedAction action;
  final IuxInlineFeedbackTokens tokens;

  @override
  Widget build(BuildContext context) => IuxFocusNodeOwner(
        focusNode: null,
        debugLabel: action.effectiveSemanticLabel,
        builder: (BuildContext context, FocusNode node) => IuxSemantics.action(
          label: action.effectiveSemanticLabel,
          // Carried here because the helper excludes the subtree in order to
          // control the announced name, and the exclusion takes the tap target's
          // own action with it. Without this the recovery control on a failure
          // message was announced as a button and did nothing at all when a
          // screen-reader user double-tapped it — IUX-011 all over again.
          onTap: action.onActivate,
          // The same exclusion took the focus annotations. Named on both nodes
          // so they describe one focus rather than two. IUX-A11Y-FOCUS-001.
          focusNode: node,
          child: IuxFocusable(
            focusNode: node,
            onActivate: action.onActivate,
            borderRadius: BorderRadius.circular(tokens.actionRadius),
            child: IuxTapTarget(
              onTap: action.onActivate,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  // Outlined, so the control is identifiable as one by its
                  // shape. A bare coloured word inside an already-coloured
                  // block asks the user to tell two tints apart to find out
                  // what is tappable, which is the failure WCAG 1.4.1 is about.
                  border: Border.all(
                    color: tokens.content,
                    width: tokens.borderWidth,
                  ),
                  borderRadius: BorderRadius.circular(tokens.actionRadius),
                ),
                child: Padding(
                  padding: IuxInsets.compact(context),
                  child: Text(action.label, style: tokens.actionStyle),
                ),
              ),
            ),
          ),
        ),
      );
}

/// The dismiss control.
///
/// The glyph stays the size of the category glyph while the interactive region
/// does not: the region meets the touch target floor through [IuxTapTarget].
/// Enlarging the cross to fill the target would make a close control the
/// loudest thing in a message about a failure.
class _IuxInlineFeedbackDismissControl extends StatelessWidget {
  const _IuxInlineFeedbackDismissControl({
    required this.dismissal,
    required this.tokens,
  });

  final IuxInlineFeedbackDismissal dismissal;
  final IuxInlineFeedbackTokens tokens;

  @override
  Widget build(BuildContext context) => IuxFocusNodeOwner(
        focusNode: null,
        debugLabel: dismissal.label,
        builder: (BuildContext context, FocusNode node) => IuxSemantics.action(
          label: dismissal.label,
          // As for the recovery control above: the exclusion that sets the
          // announced name takes the tap target's action and the focus
          // annotations with it, so both are re-published here.
          onTap: dismissal.onDismissed,
          focusNode: node,
          child: IuxFocusable(
            focusNode: node,
            onActivate: dismissal.onDismissed,
            child: IuxTapTarget(
              onTap: dismissal.onDismissed,
              child: Icon(
                Icons.close,
                size: tokens.iconSize,
                // The content role, not the icon role: this glyph is a control
                // rather than the category, and a control is held to the text
                // ratio the theme measured for content on this surface.
                color: tokens.content,
                applyTextScaling: false,
              ),
            ),
          ),
        ),
      );
}
