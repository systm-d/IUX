import 'package:flutter/foundation.dart';

import '../../actions/iux_action_descriptor.dart';
import '../../actions/iux_action_model.dart';
import '../../components/feedback/iux_inline_feedback.dart';

/// Why an unlabelled retry control is refused.
const String _kEmptyRetryLabel =
    'A retry control with no text is a button the user is asked to trust '
    'without being told what it does. Pass the localised verb — "Try again", '
    '"Réessayer" — and name the outcome rather than the mechanism.';

/// Why an empty semantic label is refused rather than ignored.
const String _kEmptyRetrySemanticLabel =
    'An empty semanticLabel would replace the visible one with nothing, '
    'leaving a control a screen reader announces as "button". Omit the '
    'parameter instead.';

/// Why an empty busy hint is refused rather than ignored.
const String _kEmptyBusyHint =
    'An empty busyHint is the same as no busyHint, and says so less clearly. '
    'Omit the parameter, or pass the localised sentence a screen reader '
    'should hear while the retry runs.';

/// Why an unrecoverable failure must still say something.
const String _kEmptyGuidance =
    'IuxUnrecoverable is the one route with no control on it, so its words '
    'are the whole of what the user gets. An empty guidance leaves them told '
    'that something failed, told that nothing here will fix it, and told '
    'nothing about what to do — which is the apology this pattern exists to '
    'prevent. Say what state they are now in, or what they can do outside '
    'this screen: "Your payment was not taken. Nothing has been charged.", '
    '"Quote this reference when you call us: 4471-B".';

/// The way out of a failure.
///
/// **An error the user cannot act on is an apology, not recovery.** This type
/// is why `IuxErrorRecovery` has no optional action parameter: the route is
/// required, so a failure cannot be reported without an answer to *what now*.
/// Every member answers that question — two of them with a control, and the
/// third with a sentence, because an error with genuinely nowhere to go still
/// owes the user an account of where they are.
///
/// It is sealed for two reasons. A component can handle every route
/// exhaustively, so adding one is a change the compiler forces every call site
/// to consider; and the choice between them is a claim about the failure that
/// only the caller can make, so it is made by *naming a type* rather than by
/// setting a flag that reads the same whichever value it holds.
///
/// The claim each name makes:
///
/// | Route | Claims |
/// | --- | --- |
/// | [IuxRetryRoute] | sending the identical request again may succeed |
/// | [IuxAlternativeRoute] | it will not, but this other action gets there |
/// | [IuxUnrecoverable] | nothing on this screen moves the user forward |
///
/// See [IuxRetryRoute] for the failures that must never be given one.
@immutable
sealed class IuxRecoveryRoute {
  /// Creates a route.
  const IuxRecoveryRoute();

  /// Running the same operation again. See [IuxRetryRoute].
  const factory IuxRecoveryRoute.retry({
    required String label,
    required VoidCallback onRetry,
    String? semanticLabel,
    bool isRunning,
    String? busyHint,
  }) = IuxRetryRoute;

  /// A different way to the same place. See [IuxAlternativeRoute].
  const factory IuxRecoveryRoute.alternative({
    required IuxNamedAction action,
  }) = IuxAlternativeRoute;

  /// Nothing on this screen moves the user forward. See [IuxUnrecoverable].
  const factory IuxRecoveryRoute.unrecoverable({
    required String guidance,
  }) = IuxUnrecoverable;
}

/// Running the same operation again, on the user's request.
///
/// ```dart
/// IuxRetryRoute(
///   label: l10n.tryAgain,
///   onRetry: controller.activate,
///   isRunning: controller.isRunning,
///   busyHint: l10n.reloadingYourOrders,
/// )
/// ```
///
/// **Choosing this type is a claim: that repeating the identical request could
/// produce a different answer.** For a great many failures that claim is
/// false, and offering retry anyway is worse than offering nothing — the user
/// presses it, waits, and fails in exactly the same way, having learned only
/// that the interface does not know what happened either.
///
/// | Failure | Retry? |
/// | --- | --- |
/// | the network dropped, the server timed out, a 503, a 429 | yes |
/// | a conflict the server resolves on the next attempt | yes |
/// | not signed in, or signed in as the wrong person (401) | **no** — [IuxAlternativeRoute] to the sign-in screen |
/// | not allowed (403) | **no** — nothing the user repeats changes their permissions |
/// | not there (404) | **no** — the identical request finds the identical nothing |
/// | the value the user sent was rejected | **no** — the field is the route, and a form owns that |
/// | the payment was declined | **no** — [IuxAlternativeRoute] to another payment method |
///
/// The framework cannot check this. It has no network, no status codes and no
/// business knowledge, and a parameter that asked "is this retryable?" would
/// be answered `true` by everyone who had not thought about it. What a type
/// system can do is make the claim visible in the source, in one word, at the
/// place a reviewer is already looking.
///
/// ## Nothing here retries on its own
///
/// There is no attempt count, no backoff and no automatic repeat, and their
/// absence is the design rather than an omission:
///
/// - an interface that retries by itself turns one user's bad connection into
///   a burst of traffic against a service that is already failing, and it does
///   so hardest at the exact moment the service can least take it;
/// - not every operation may be repeated safely. A framework that re-sent an
///   operation the user did not ask it to re-send would eventually charge a
///   card twice, and no amount of care about the common case makes that
///   acceptable;
/// - a retry that succeeds silently leaves the user unable to explain what
///   they saw, and one that fails silently leaves them looking at an
///   unchanged screen with no account of what has been going on behind it.
///
/// So every attempt is one the user asked for, and [isRunning] is what stops
/// them asking twice by accident: [descriptor] carries
/// [IuxActionRepeatPolicy.ignoreWhileInProgress], so `IuxActionPolicy` drops a
/// second activation while the first is in flight — the same mechanism that
/// stops a double-tapped "Pay" charging twice, rather than a second copy of it.
///
/// A parent that must stop the user retrying at all — a rate limit, an attempt
/// budget it has decided to spend — does not disable this control. There is no
/// availability parameter here for that reason. It swaps the route for an
/// [IuxAlternativeRoute], so the block goes on offering a way forward instead
/// of a way that has been taken away without explanation.
@immutable
final class IuxRetryRoute extends IuxRecoveryRoute {
  /// Creates a retry route.
  const IuxRetryRoute({
    required this.label,
    required this.onRetry,
    this.semanticLabel,
    this.isRunning = false,
    this.busyHint,
  })  : assert(label.length > 0, _kEmptyRetryLabel),
        assert(
          semanticLabel == null || semanticLabel.length > 0,
          _kEmptyRetrySemanticLabel,
        ),
        assert(busyHint == null || busyHint.length > 0, _kEmptyBusyHint);

  /// The visible text of the control, already localised.
  ///
  /// Name what happens — "Try again", "Reload the list". "OK" inside an error
  /// block tells the user something will happen and refuses to say what, and
  /// the one thing they want to know is whether it costs them anything.
  final String label;

  /// Called once per accepted activation.
  ///
  /// Never called while [isRunning] is true. What it starts, whether it
  /// worked, and what is on screen afterwards are all the parent's: this
  /// widget reports that the user asked, and nothing more.
  final VoidCallback onRetry;

  /// What a screen reader announces instead of [label].
  ///
  /// A screen holding two failed sections holds two controls called "Try
  /// again", and a user moving through them by control cannot tell which is
  /// which. "Try loading your orders again" costs the sighted user nothing.
  final String? semanticLabel;

  /// Whether the retry the user already asked for is still running.
  ///
  /// The parent's, like every other piece of state in IUX. Wire it from
  /// whatever already knows — `IuxAsyncActionController.isRunning` is the
  /// shape this was built against.
  ///
  /// A boolean rather than an [IuxActionOperation], and deliberately: of the
  /// four lifecycle values only two can be true of a control inside a block
  /// that is *currently reporting a failure*. A retry that succeeded has
  /// removed this block; a retry that failed has replaced its message. Taking
  /// the full enum would have accepted two values that describe a screen that
  /// cannot exist, and then needed an assertion to reject them — which is a
  /// worse version of not accepting them at all.
  final bool isRunning;

  /// Announced after the name while the retry runs, already localised.
  ///
  /// Leave it null and a screen reader hears nothing when the control is
  /// pressed, and silence is indistinguishable from a control that did
  /// nothing — which is the impression an error block can least afford to
  /// give. Supply it for anything that takes a network round trip.
  final String? busyHint;

  /// The accessible name actually used.
  String get effectiveSemanticLabel => semanticLabel ?? label;

  /// This route as the action model already understands it.
  ///
  /// Derived rather than accepted, which is the whole point. Taking an
  /// [IuxActionDescriptor] here would let a call site write
  /// `role: IuxActionRole.delete` on a retry, `confirmation:
  /// IuxConfirmBeforeExecution()` on a control whose block presents no
  /// question, or `repeatPolicy: IuxActionRepeatPolicy.allow` on the one
  /// control in the library that must never accept a second tap while the
  /// first is running. None of those is a decision the caller should be
  /// offered, so none of them is a parameter — and the four fixed values below
  /// stop being documentation that can drift from the code:
  ///
  /// | Field | Value | Why it is not the caller's |
  /// | --- | --- | --- |
  /// | `role` | [IuxActionRole.retry] | it is what naming this type claimed |
  /// | `repeatPolicy` | [IuxActionRepeatPolicy.ignoreWhileInProgress] | a second attempt in flight is the defect this route exists to avoid |
  /// | `intent`/`importance` | primary, high | it is the only control in the block |
  /// | `confirmation` | none | nothing here presents a question |
  ///
  /// `operation` follows [isRunning], so `IuxButton` announces the busy state
  /// and `IuxActionPolicy` refuses the repeat, with no second implementation of
  /// either rule living here.
  IuxActionDescriptor get descriptor => IuxActionDescriptor(
        semantics: IuxActionSemantics(label: effectiveSemanticLabel),
        intent: IuxActionIntent.primary,
        importance: IuxActionImportance.high,
        role: IuxActionRole.retry,
        operation:
            isRunning ? IuxActionOperation.inProgress : IuxActionOperation.idle,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxRetryRoute &&
          other.label == label &&
          other.onRetry == onRetry &&
          other.semanticLabel == semanticLabel &&
          other.isRunning == isRunning &&
          other.busyHint == busyHint;

  @override
  int get hashCode => Object.hash(
        label,
        onRetry,
        semanticLabel,
        isRunning,
        busyHint,
      );

  @override
  String toString() => 'IuxRetryRoute($label${isRunning ? ', running' : ''})';
}

/// A different action, for a failure that repeating will not fix.
///
/// ```dart
/// IuxAlternativeRoute(
///   action: IuxNamedAction(
///     label: l10n.signInAgain,
///     onActivate: controller.openSignIn,
///   ),
/// )
/// ```
///
/// This is the route for every failure whose cause is outside the request: an
/// expired session, a permission the user does not have, a card the bank
/// refuses, a device setting that is switched off, a document that is no
/// longer there. The user is not stuck — they simply have to go somewhere
/// else, and the whole value of this route is that it takes them there instead
/// of describing where they should go.
///
/// It carries exactly one action, and one is a limit rather than an oversight.
/// A failure the user must resolve by choosing between three things is a
/// decision, and a decision belongs somewhere the user can read the options
/// side by side — not underneath a sentence explaining that something broke.
/// That limit binds every route: [IuxRetryRoute] cannot carry a second control
/// either, so "Try again" and "Use another card" together are not something
/// this pattern builds. Where both are genuinely honest offers, put the second
/// one below the block as an [IuxButton] of its own — which is what [IuxAlert]
/// already tells a caller to do when an action needs a lifecycle the message
/// cannot hold.
///
/// **It is not the place for an action that destroys data.** "Discard your
/// changes and start again" is a way forward and it is also irreversible, and
/// an irreversible control sitting under a message the user is still reading
/// is the one they press while they are still upset. Put an
/// `IuxDestructiveAction` below this block, where it can ask.
@immutable
final class IuxAlternativeRoute extends IuxRecoveryRoute {
  /// Creates an alternative route.
  const IuxAlternativeRoute({required this.action});

  /// What the user should do instead, already localised.
  ///
  /// Name the destination — "Sign in again", "Use another card", "Open
  /// settings" — so the control says where it goes before it goes there.
  ///
  /// An [IuxNamedAction] because that is already the library's value
  /// for "a labelled way out of a message", and because a call site that
  /// outgrows [IuxAlert] should not have to rewrite its actions to move here.
  /// It carries no lifecycle, which is correct: an alternative goes somewhere
  /// else, and the somewhere else owns its own progress. A control that has to
  /// report progress *in this block* is a retry, and that is the other type.
  final IuxNamedAction action;

  /// This route as the action model already understands it.
  ///
  /// Derived, for the reasons given on [IuxRetryRoute.descriptor]. The role is
  /// [IuxActionRole.navigate] because that is the claim the type makes — the
  /// user is not stuck, they have to be somewhere else — and it is the one
  /// thing that keeps this control from being announced as, and treated as,
  /// the retry it deliberately is not.
  ///
  /// There is no operation, so the control is never busy and never refuses a
  /// second activation. Opening a sign-in screen twice is a navigation the
  /// destination absorbs; it is not a second charge on a card.
  IuxActionDescriptor get descriptor => IuxActionDescriptor(
        semantics: IuxActionSemantics(label: action.effectiveSemanticLabel),
        intent: IuxActionIntent.primary,
        importance: IuxActionImportance.high,
        role: IuxActionRole.navigate,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxAlternativeRoute && other.action == action;

  @override
  int get hashCode => Object.hash(IuxAlternativeRoute, action);

  @override
  String toString() => 'IuxAlternativeRoute(${action.label})';
}

/// A failure this screen cannot move the user past, declared deliberately.
///
/// ```dart
/// IuxUnrecoverable(guidance: l10n.paymentNotTakenNothingCharged)
/// ```
///
/// **Reach for it last.** Most failures that look unrecoverable are not: a
/// server error can be retried, an expired session can be renewed, a missing
/// document can be left for a list the user can get back to. Before using
/// this, check that the answer to *what now* is genuinely not a control, and
/// not merely a control nobody has written yet.
///
/// It exists because the alternative is worse. Without it, a caller with no
/// route would either invent one — a "Try again" that cannot work, an "OK"
/// that does nothing — or the pattern would have to make the route optional,
/// and an optional route is one every rushed call site omits. Requiring a type
/// to be named, and a sentence to be written, is the smallest deliberate act
/// that keeps "nothing can be done" from being the path of least resistance.
///
/// The sentence is not decoration. It is the entirety of what the user
/// receives beyond the fact of the failure, and it is announced with the
/// message rather than after it.
@immutable
final class IuxUnrecoverable extends IuxRecoveryRoute {
  /// Creates the route for a failure with no control to offer.
  const IuxUnrecoverable({required this.guidance})
      : assert(guidance.length > 0, _kEmptyGuidance);

  /// What the user should know now, already localised.
  ///
  /// Two things are worth saying here and both are the caller's to judge:
  /// **what state they are in** — "Nothing has been charged", "Your draft is
  /// still saved on this device" — and **what they can do away from this
  /// screen**, including a reference to quote if they contact anyone.
  ///
  /// What is not worth saying is that an unexpected error occurred. The user
  /// can see that something went wrong; a sentence restating it spends their
  /// attention and returns nothing.
  final String guidance;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxUnrecoverable && other.guidance == guidance;

  @override
  int get hashCode => Object.hash(IuxUnrecoverable, guidance);

  @override
  String toString() => 'IuxUnrecoverable($guidance)';
}
