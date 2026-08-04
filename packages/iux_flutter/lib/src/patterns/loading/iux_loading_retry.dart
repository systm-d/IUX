import 'package:flutter/widgets.dart';

import '../../components/progress/iux_progress.dart';
import '../error/iux_error_recovery.dart';
import '../error/iux_recovery_route.dart';
import 'iux_load_state.dart';

/// Why a wait with no wording is refused.
const String _kEmptyLoadingLabel =
    'A wait must say what is being waited on. Without it the user is looking '
    'at a moving bar that means "something", and a screen-reader user hears a '
    'region that changed and refuses to say into what — which is '
    'indistinguishable from an application that has hung. It is also the line '
    'that replaces the bar entirely when the user has asked for no motion, so '
    'an empty string would leave that user with an empty region. Pass the '
    'localised name of the operation: "Loading your orders", not "Loading".';

/// Builds the region once the load has produced something.
///
/// Receives the value rather than the state, because by the time this runs
/// there is nothing else the region could be showing. A builder that still had
/// to ask "am I loading?" would be a builder that could get the answer wrong.
typedef IuxLoadedBuilder<T> = Widget Function(BuildContext context, T value);

/// One region, one load: the wait, the content, or the failure and its way out.
///
/// ```dart
/// IuxLoadingRetry<List<Order>>(
///   state: controller.state,
///   loadingLabel: l10n.loadingYourOrders,
///   failureCategoryLabel: l10n.error,
///   recovery: IuxRetryRoute(
///     label: l10n.tryAgain,
///     onRetry: controller.load,
///     isRunning: controller.isRunning,
///     busyHint: l10n.reloadingYourOrders,
///   ),
///   builder: (BuildContext context, List<Order> orders) => OrderList(orders),
/// )
/// ```
///
/// **Use it** for any region whose content arrives from one operation that can
/// be waited on and can fail: a list, a detail panel, a whole screen body. It
/// answers the `loading` and `error` rows of the component standard's state
/// table together, which is the point — nearly every screen needs both, and
/// most applications answer them with a spinner, a boolean and a stale error
/// that outlives the retry.
///
/// **What it adds over its two halves.** `IuxLoadingIndicator` and
/// `IuxErrorRecovery` already exist and this pattern draws neither: it composes
/// them. What it contributes is the invariant between them — that a region
/// shows the wait, the content or the failure, and never two of those and never
/// none. That invariant is the defect; the widgets were never the problem.
///
/// **Do not use it for two operations.** A screen whose header and whose list
/// load separately has two regions, each with its own [IuxLoadState]. One
/// widget spanning both would have to decide what "loading" means when one has
/// arrived and the other has not, and every answer to that is wrong for
/// somebody.
///
/// **Do not use it for an action.** A save, a payment, a submission — anything
/// the user starts by pressing a control — is `IuxAsyncButton`, which keeps the
/// outcome on the control the user pressed. This is for content the region
/// *is*, not for work the region *did*.
///
/// **Do not use it to decide anything.** It never starts a load, never decides
/// one finished, and never activates the recovery by itself. See "Nothing here
/// retries on its own" below.
///
/// ## Exactly one branch, structurally
///
/// The classic defect in this territory is a region rendering two answers at
/// once — a spinner over a populated list, an error under fresh content — or
/// none at all, because three booleans drifted apart. There are no booleans
/// here. [state] is one sealed value, this widget is one `switch` over it, and
/// the exhaustiveness checker refuses to compile a `switch` that forgets a case
/// if a fourth state is ever added. The impossible combinations are not
/// asserted; they cannot be written.
///
/// An empty result is not a fourth branch. The load succeeded and what came
/// back has no rows in it, so it is [IuxLoadState.ready] with an empty value
/// and [builder] names the situation with `IuxEmptyState` — which distinguishes
/// four kinds of emptiness that a state called `empty` would flatten into one.
/// See the note on `empty` in [IuxLoadState].
///
/// ## The failure is `IuxErrorRecovery`, not a second error block
///
/// [IuxLoadFailed] carries the wording; [recovery] carries what the user can do
/// about it; this pattern hands both to `IuxErrorRecovery` and draws nothing of
/// its own. There is deliberately no retry model here, no availability flag and
/// no way to render a failure without a route: [IuxRecoveryRoute] already makes
/// the choice that matters unrepresentable rather than validated —
/// [IuxRetryRoute] for a failure repeating could fix, [IuxAlternativeRoute] for
/// one it could not, [IuxUnrecoverable] for one nothing will — and it derives
/// the action descriptor rather than accepting one, so a retry cannot be given
/// a confirmation policy or a repeat policy that lets two run at once.
///
/// A second vocabulary for "the way out of a failure" would have been the
/// mistake this library keeps declining to make elsewhere: `IuxEmptyState`
/// refuses `IuxActionRole.retry` precisely so that the line between an answer
/// and a breakdown has exactly one home.
///
/// The consequence worth stating is that [recovery] belongs to the *region*
/// rather than to the failure that happened. Where the honest route depends on
/// which failure it was — a timeout that may be retried, a refusal that may
/// not — the parent recomputes it beside the state, which it can, because it
/// produced both from the same answer.
///
/// ## Nothing here retries on its own
///
/// There is no timer, no backoff schedule and no attempt counter in this
/// pattern, and there will not be one. Three reasons, in order of how badly
/// each fails:
///
/// 1. **Only the caller knows whether the operation is safe to repeat.** A
///    read is; a request that created an order is not, and a framework that
///    re-fired it would charge a card twice. Nothing here can inspect the
///    operation to find out, so the safe default is the only defensible one.
/// 2. **An automatic retry is an activation the user did not make.** The whole
///    action model exists to stop a double-tapped control running twice; a
///    pattern that fired the same request on a schedule would reintroduce that
///    one layer up.
/// 3. **It hammers a service that is already failing** while showing the user a
///    screen that looks stuck, and it re-enters the wait on a cadence the user
///    cannot predict or stop — which re-fires the live region, so a
///    screen-reader user is interrupted on a timer they did not set.
///
/// What stops a *user* doing the same thing by hand is two mechanisms, neither
/// of them a timer. In the default flow the control does not exist while the
/// load is running, so there is nothing to press. When the parent instead
/// drives [IuxRetryRoute.isRunning], the route's descriptor carries
/// [IuxActionRepeatPolicy.ignoreWhileInProgress] and `IuxActionPolicy` drops
/// the second activation — the same mechanism that stops a double-tapped "Pay"
/// charging twice, rather than a second copy of it.
///
/// ## Nothing here times out, either
///
/// A load that never comes back stays a load. This pattern will not decide,
/// after some number of seconds, that the operation failed — it did not fail,
/// it has not answered, and reporting an outcome the operation never reported
/// is the one thing [IuxLoadState] exists to make impossible.
///
/// That is also the reading which keeps WCAG 2.2 SC 2.2.1 (Timing Adjustable)
/// out of this pattern entirely. The criterion binds time limits *set by the
/// content* which the user must beat; a region that waits indefinitely sets
/// none, removes nothing on a schedule and asks the user for nothing. A
/// framework-imposed timeout would have created exactly such a limit, on a
/// screen where the user has no way to extend it, and would have needed an
/// exception to be conformant. Not having one is simpler and more honest: if a
/// request must give up, the operation gives up and the parent reports a
/// failure it can put into words.
///
/// ## Accessibility
///
/// **The wait is announced, and that is a decision.** `IuxLoadingIndicator`
/// marks itself a live region carrying [loadingLabel], so a user whose content
/// was replaced by a wait is told what is being waited on. Silence would be
/// defensible for a permanent region the user will reach by exploring; it is
/// not defensible here, because a wait is usually gone before a user reading
/// linearly arrives at it. The announcement is the only chance they get.
///
/// **This is where it diverges from `IuxEmptyState`**, which takes an arrival
/// dimension and stays silent when the screen opened that way. An empty state
/// is content: it is still there when the user reaches it, so announcing it as
/// well says the same sentence twice. A wait is not content, and a wait that
/// announced only sometimes would be silent in the case that matters most — a
/// screen that opens on a slow request and shows a bar the user cannot see.
/// `IuxErrorRecovery` reaches the same conclusion for a failure and announces
/// unconditionally, so all three branches of this region agree.
///
/// **Focus is never moved.** Not to the failure, not to the recovery control,
/// not back into the region when content arrives. This is `IuxEmptyState`'s
/// choice and `IuxErrorRecovery`'s, and the opposite of
/// `IuxValidationSummary`'s; the difference is whether the user asked for the
/// change. A refused submission answers a button they just pressed, whereas a
/// load resolving happens to them, often with their hands elsewhere on the
/// screen. Moving focus for it would take the caret out of a search field to
/// announce the consequence of what the user is still typing — and landing
/// focus on a retry would arm the one control in the library that must never
/// fire twice.
///
/// **Reduced motion** is `IuxLoadingIndicator`'s, which is part of why the wait
/// is delegated to it rather than drawn here. Under
/// [IuxMotionPreference.none] the bar is removed rather than frozen — a
/// stationary segment reads as a hung operation — and [loadingLabel] stays on
/// screen as the static alternative. This pattern's own tests exercise that
/// path rather than assuming it was inherited.
///
/// SC 2.2.2 (Pause, Stop, Hide) does not bind the moving bar. It applies to
/// motion that starts automatically, lasts more than five seconds *and* is
/// presented in parallel with other content; the wait replaces the region's
/// content rather than sitting beside it, and a progress indicator is the
/// canonical case of the criterion's own essential-motion exception — the
/// movement is the information. SC 2.3.3 (Animation from Interactions) is the
/// one that does apply, and it is honoured through the motion policy.
///
/// ## Known limitations
///
/// **Returning the region to a wait loses keyboard focus.**
///
/// It unmounts the control the user just activated, and Flutter hands focus
/// back to the nearest enclosing scope; a keyboard user then tabs from there
/// rather than from where they were. This pattern does not paper over that,
/// because every fix is a focus movement of the kind it has just argued
/// against, onto a node that would itself vanish when the content arrived —
/// two interruptions in place of one.
///
/// Leaving the region [IuxLoadState.failed] and driving
/// [IuxRetryRoute.isRunning] instead is the answer, and now behaves like one.
/// The control stays mounted and keeps both focus and the user's place. It did
/// not until IUX-038: `IuxButton` passed [IuxActionDescriptor.isActivatable] to
/// its focus node's `canRequestFocus`, and that getter is false while an action
/// is in progress under the default repeat policy, so a running control left
/// the focus order and dropped the focus it was holding. The same getter fed
/// the announced enabled state, so a running retry was announced as
/// *unavailable* rather than as busy, and [IuxRetryRoute.busyHint] — which
/// exists so a running control is not silent — was attached to a node the user
/// had just been moved off. Availability and operation are separate questions
/// again, and this pattern's tests pin the corrected behaviour.
///
/// So prefer driving [IuxRetryRoute.isRunning] where the caller can: the user
/// keeps their place, and the busy hint reaches them. Either way it is the live
/// region — on the wait or on the failure — that tells a screen-reader user
/// their activation was accepted.
///
/// **The wait is indeterminate.** A load whose extent the caller can count is
/// better served by `IuxProgressIndicator`, which answers "how much longer"
/// where this answers nothing — and a user who cannot estimate a wait is a user
/// who abandons it. Supporting it here would mean putting a fraction and its
/// spoken form into [IuxLoadInProgress], which is an additive change nobody has
/// yet asked for. Until then, a counted load places its own indicator.
///
/// **There is no skeleton, and no slot for one.** A skeleton claims a shape —
/// three rows, this tall — that only the caller knows, its shimmer is
/// decorative motion that disappears the moment the user asks for less, and it
/// carries no text at all, so a screen-reader user gets silence where the bar
/// would have given them a sentence. The evidence that it beats an indicator on
/// perceived speed is contested rather than settled, which is not a basis for
/// putting an unlabelled region in front of anybody.
///
/// **Neither branch scrolls.** A long message at a large text scale in a short
/// viewport overflows rather than shrinking or truncating, which is
/// `IuxErrorRecovery`'s documented behaviour and this pattern inherits it: a
/// region embedded in a list that already scrolls must not introduce a second
/// scroll view, and half an account of why something is broken is worse than an
/// overflow, which is at least visible in development. Place the region inside
/// something scrollable when the viewport may be short.
///
/// **A live region is a request, not a guarantee.** Whether the platform speaks
/// it, and when, is the platform's decision; a widget test can assert that the
/// node carries the flag and no more, so TalkBack stays a manual check. Nothing
/// essential depends on it — the same words are on screen either way.
///
/// **This pattern does not delay the indicator.** Showing a spinner for a load
/// that resolves in eighty milliseconds is a flash that reads as a glitch, and
/// it is a real defect — but it is not one a widget can fix. To withhold the
/// indicator the region has to render something else meanwhile, and its only
/// options are nothing, which collapses the region and adds a second layout
/// change, or the previous content, which is this widget claiming
/// [IuxLoadState.ready] while the parent says otherwise. A timer here would
/// also make the branch a function of wall-clock time rather than of the state
/// it was handed, which is the one property the whole design rests on. The fix
/// belongs where the knowledge is: a parent expecting an answer inside the
/// window in which people perceive a system as responding at all — roughly a
/// tenth of a second, the figure Miller and Nielsen both land on — should not
/// enter [IuxLoadState.loading], and should swap the value when it arrives.
/// See `docs/patterns/loading-and-retry.md` for the measurement behind that.
class IuxLoadingRetry<T> extends StatelessWidget {
  /// Creates a region driven by one load.
  const IuxLoadingRetry({
    super.key,
    required this.state,
    required this.loadingLabel,
    required this.failureCategoryLabel,
    required this.recovery,
    required this.builder,
  }) : assert(loadingLabel.length > 0, _kEmptyLoadingLabel);

  /// Where the load has got to.
  ///
  /// Owned by the parent and never produced here. See [IuxLoadState].
  final IuxLoadState<T> state;

  /// What is being waited on, already localised.
  ///
  /// Describe the work, not the widget: "Loading your orders", not "Loading".
  /// It is what a screen reader announces when the wait begins and what stays
  /// on screen in place of the bar when the user has asked for no motion, so it
  /// has to stand on its own in both roles.
  ///
  /// Required even when [state] is not a wait. The alternative — a label that
  /// only has to exist in the branch that uses it — is a label a caller
  /// discovers is missing in production, on the slow request they could not
  /// reproduce.
  final String loadingLabel;

  /// The localised word for the failure category — "Error", "Erreur".
  ///
  /// Passed straight to `IuxErrorRecovery`, which requires it because it is the
  /// only carrier of the category that survives a screen reader, a monochrome
  /// display and an inverted one (WCAG SC 1.4.1). IUX cannot supply it: the
  /// framework holds roles and never words.
  ///
  /// Required in every branch, for the same reason [loadingLabel] is: a string
  /// that only had to exist in the branch that uses it is a string a caller
  /// discovers is missing on the failure they could not reproduce.
  final String failureCategoryLabel;

  /// What the user can do about a failure, and therefore what the failed
  /// region offers.
  ///
  /// Required, and a sealed type, so a failed region cannot be built without an
  /// answer to "what now" — which is how `IuxErrorRecovery` meets WCAG SC 3.3.3
  /// structurally rather than by review. A caller with nothing to offer names
  /// [IuxUnrecoverable] and writes the sentence.
  ///
  /// See [IuxRecoveryRoute] for the table of which failures may honestly be
  /// retried and which must never be. Choosing wrongly is the failure this
  /// whole area of the library is arranged to prevent: "Try again" over a 403
  /// sends the user to repeat a request that will refuse them identically, and
  /// teaches them the interface does not know what happened either.
  final IuxRecoveryRoute recovery;

  /// Builds the region from what the load produced.
  ///
  /// Called only for [IuxLoadReady], so there is no state left to check. An
  /// empty value is the caller's to interpret: see the note on `empty` in
  /// [IuxLoadState].
  final IuxLoadedBuilder<T> builder;

  @override
  Widget build(BuildContext context) => switch (state) {
        // Both branches are delegated rather than drawn. The indicator owns the
        // reduced-motion substitution and the live region that survives it; the
        // recovery block owns the tinted pairing the theme measured, the
        // category word and the route. A second implementation of either would
        // be a second place for them to be got wrong.
        IuxLoadInProgress<T>() => IuxLoadingIndicator(label: loadingLabel),
        IuxLoadReady<T>(:final T value) => builder(context, value),
        IuxLoadFailed<T>(:final String message) => IuxErrorRecovery(
            route: recovery,
            categoryLabel: failureCategoryLabel,
            message: message,
          ),
      };
}
