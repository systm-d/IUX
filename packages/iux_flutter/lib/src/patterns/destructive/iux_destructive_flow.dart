import 'package:flutter/widgets.dart';

import '../../actions/iux_action_descriptor.dart';
import '../../actions/iux_action_model.dart';
import '../../components/overlay/iux_dialog.dart';
import '../../components/transient/iux_transient_message.dart';
import '../../themes/extensions/iux_button_theme.dart';
import 'iux_confirmation_prompt.dart';
import 'iux_destructive_action.dart';
import 'iux_destructive_flow_model.dart';

/// Why an undo offer is refused for a loss the user cannot enumerate.
const String _kUndoBeyondItems =
    'This flow is declared IuxDestructiveScope.everything and also offers an '
    'IuxUndoOffer. An undo offer is a control on the screen the user is '
    'standing on, and it only protects somebody who can tell that they need '
    'it — which is precisely what deleting a whole account, workspace or '
    'history takes away: they cannot inspect what went, and the screen that '
    'would carry the offer is usually part of what went with it. Declare '
    'IuxNoWayBack and write what is lost into the confirmation, where the '
    'user reads it before answering instead of after. If the user really can '
    'list what they are about to lose, this is IuxDestructiveScope.items.';

/// Why wording with nothing to present it is refused.
const String _kUnusedPrompt =
    'An IuxConfirmationPrompt was given to a flow whose way back is an '
    'IuxUndoOffer, so nobody is asked and the wording would never be shown. '
    'Left alone this reads at the call site as though the user were being '
    'warned, and the deletion runs on the first tap. Choose one: an undo, '
    'which costs nothing until somebody errs, or a confirmation, which costs '
    'every user a step. Asking for both interrupts everyone and still leaves '
    'a control on screen afterwards; asking for neither is the failure this '
    'type exists to prevent.';

/// Why a confirming flow with no wording is refused.
const String _kMissingPrompt =
    'This flow declares IuxNoWayBack, so the user has to be asked before the '
    'deletion runs — and there is no wording to ask with, which would leave a '
    'control that does nothing when tapped. Supply the IuxConfirmationPrompt: '
    'what is about to happen, what it costs, the name of going ahead and the '
    'name of not going ahead. If the deletion can genuinely be taken back '
    'from this screen in one control, say so with IuxUndoOffer and nobody has '
    'to be asked at all.';

/// Why taking back a deletion nobody made is refused.
const String _kNoOfferOutstanding =
    'undo() was called while no undo offer was outstanding, so this would '
    'restore something on behalf of a user who never asked — or, more likely, '
    'restore it twice. The offer exists only between the deletion running and '
    'the notice being answered or dismissed; read notice != null before '
    'calling this from anywhere but the notice itself.';

/// Runs a deletion with exactly one safeguard, and picks which one.
///
/// ```dart
/// // One thing the user chose, and the application can put it back.
/// // Nobody is asked; the way back is offered afterwards.
/// final controller = IuxDestructiveFlowController(
///   semantics: IuxActionSemantics(label: l10n.archiveTheMarchInvoice),
///   scope: IuxDestructiveScope.items,
///   wayBack: IuxUndoOffer(
///     notice: l10n.invoiceArchived,
///     undoLabel: l10n.undo,
///     undoSemanticLabel: l10n.undoArchivingTheMarchInvoice,
///     dismissLabel: l10n.dismissTheArchivedNotice,
///     onUndo: model.restoreInvoice,
///   ),
///   onDestroy: model.archiveInvoice,
/// );
/// ```
///
/// ## What this adds to `IuxDestructiveActionController`
///
/// That controller presents the confirmation an action *asks* for. It takes
/// the caller's word for whether one is warranted, and it models no way back
/// at all — its own documentation lists both as limits.
///
/// This one answers the question before it: **given what is being destroyed
/// and whether it can be put back, which safeguard is proportionate?** Two
/// facts go in and the answer comes out, so the decision is made once, in a
/// place a reviewer can read, instead of being spelled out again at every call
/// site.
///
/// | Way back | Scope | The user is | And afterwards |
/// | --- | --- | --- | --- |
/// | [IuxUndoOffer] | [IuxDestructiveScope.items] | not asked | offered the way back, in a notice that never expires |
/// | [IuxUndoOffer] | [IuxDestructiveScope.everything] | — | refused: see [IuxDestructiveScope] |
/// | [IuxNoWayBack] | either | asked, with the consequence stated | told nothing; there is nothing to offer |
///
/// **Exactly one safeguard, always.** Both failures are refused on an
/// assertion rather than documented: a flow cannot ask *and* offer a way back
/// — that interrupts everyone and still leaves a control on screen — and it
/// cannot do neither, which is the deletion that runs on the first tap with
/// nothing offered and is the trap this pattern exists to close.
///
/// ## The descriptor is derived, and it is not published
///
/// Nothing here accepts an [IuxActionDescriptor]. Taking one would let a call
/// site write `confirmation: IuxConfirmBeforeExecution()` on a flow that
/// offers an undo, `role: IuxActionRole.retry` on a deletion, or
/// `reversibility: IuxActionReversibility.reversible` on something nothing can
/// reverse — none of which is a decision the caller should be offered once
/// they have said what is being destroyed.
///
/// | Field | Value | Where it comes from |
/// | --- | --- | --- |
/// | `intent` | [IuxActionIntent.destructive] | naming this pattern claimed it |
/// | `role` | [IuxActionRole.delete] | the same |
/// | `reversibility` | reversible / irreversible | which [IuxWayBack] was named |
/// | `confirmation` | none / [IuxConfirmBeforeExecution] | the same |
/// | `availability`, `operation`, `semantics` | the caller's | only the parent can know them |
///
/// It is also not exposed. A public descriptor carrying
/// [IuxConfirmBeforeExecution] can be handed to a plain `IuxButton`, which
/// evaluates with `confirmed: true` and runs the action on the first tap with
/// nobody asked — the open defect recorded as `IUX-BUTTON-CONFIRM-001`. A
/// caller of this flow never holds such a descriptor, so within this pattern
/// that trap is unreachable rather than merely documented. It remains
/// reachable elsewhere; closing it in general is a decision about where a
/// policy is evaluated, and that is not this mission's.
///
/// ## Where the two layers go
///
/// The flow puts nothing on screen. It produces two values and the parent
/// places them, at page level, where interruptions and notices belong:
///
/// ```dart
/// ListenableBuilder(
///   listenable: controller,
///   builder: (BuildContext context, Widget? child) => IuxModalLayer(
///     dialog: controller.dialog,
///     child: IuxTransientLayer(
///       message: controller.notice,
///       onDismissed: controller.dismissNotice,
///       child: IuxPage(child: content),
///     ),
///   ),
/// )
/// ```
///
/// Both slots are needed whichever safeguard the flow picked, because the
/// safeguard follows the way back and the way back can change under the
/// controller. A parent that wires only one has a working flow until the day
/// somebody changes a `wayBack`, which is the kind of failure that is cheapest
/// to prevent by writing both lines now.
///
/// A pattern that pushed a route would be deciding navigation, and a pattern
/// that opened its own overlay from wherever the trigger happened to sit would
/// be deciding layering. Both belong to the application. The cost of that is
/// the two lines above, and it is stated rather than hidden — see the known
/// limitations in `docs/patterns/destructive-flow.md`.
class IuxDestructiveFlowController extends ChangeNotifier {
  /// Creates a flow that destroys something and protects the user once.
  ///
  /// [prompt] is required exactly when the flow asks first — that is, when
  /// [wayBack] is [IuxNoWayBack] — and refused when it does not. Both
  /// directions are asserted, because wording that is never shown reads at the
  /// call site as though the user were being warned, and a question with no
  /// wording produces a trigger that does nothing.
  ///
  /// [availability] and [operation] are the parent's, exactly as they are on
  /// any `IuxActionDescriptor`: a bulk trigger is built disabled with nothing
  /// selected, and a deletion that takes a network round trip reports itself as
  /// running. [update] takes the same arguments as this constructor, so
  /// learning one is learning both.
  IuxDestructiveFlowController({
    required IuxActionSemantics semantics,
    required IuxDestructiveScope scope,
    required IuxWayBack wayBack,
    required VoidCallback onDestroy,
    IuxConfirmationPrompt? prompt,
    IuxActionAvailability availability = IuxActionAvailability.enabled,
    IuxActionOperation operation = IuxActionOperation.idle,
  })  : _semantics = semantics,
        _wayBack = wayBack,
        _availability = availability,
        _operation = operation,
        _onDestroy = onDestroy {
    assert(_debugProportionate(scope, wayBack, prompt));
    _trigger = IuxDestructiveActionController(
      action: _descriptor,
      prompt: prompt,
      onConfirmed: _run,
    );
    // Forwarded rather than re-derived. The trigger widget activates the inner
    // controller directly, so a question opened by a tap would otherwise
    // change [dialog] with nothing telling the page to look again.
    _trigger.addListener(notifyListeners);
  }

  /// The confirmation half, reused rather than re-implemented.
  ///
  /// Every rule about what an activation means — unavailable, already running,
  /// awaiting an answer — is `IuxDestructiveActionController`'s, evaluated with
  /// `confirmed: false`. A second implementation of that rule would eventually
  /// disagree with the first about whether a busy deletion accepts a second
  /// tap.
  late final IuxDestructiveActionController _trigger;

  final VoidCallback _onDestroy;
  IuxActionSemantics _semantics;
  IuxWayBack _wayBack;
  IuxActionAvailability _availability;
  IuxActionOperation _operation;

  /// The offer belonging to the deletion that has already run, or null.
  ///
  /// Captured at the moment the action runs rather than read from [_wayBack],
  /// so that replacing the flow's way back through [update] cannot retract a
  /// promise already made to the user about something already destroyed.
  IuxUndoOffer? _outstanding;

  /// Whether this flow interrupts the user before it runs.
  ///
  /// The proportionality verdict, in one word: false when the way back is an
  /// [IuxUndoOffer], true when it is [IuxNoWayBack]. It is derived from the
  /// two facts the caller stated and cannot be set.
  /// There is deliberately no getter for the scope or the way back beside it.
  /// Both are the caller's own arguments handed back, and this one is not: it
  /// is what the pattern concluded from them.
  bool get asksFirst => !_wayBack.replacesConfirmation;

  /// Whether the user has been asked and has not yet answered.
  bool get isConfirming => _trigger.isConfirming;

  /// The confirmation currently open, or null when none is.
  ///
  /// Hand it to `IuxModalLayer.dialog`. Null for a flow that offers an undo,
  /// always — such a flow asks nobody anything.
  IuxDialog? get dialog => _trigger.dialog;

  /// The notice offering the way back, or null when none is outstanding.
  ///
  /// Hand it to `IuxTransientLayer.message`, with [dismissNotice] as its
  /// `onDismissed`. It is non-null from the moment a deletion with an
  /// [IuxUndoOffer] has run until the user takes the way back, dismisses the
  /// notice, or the parent retracts it.
  ///
  /// Derived, never accepted, for the same reason the descriptor is. Two
  /// values are fixed here and neither is the caller's:
  ///
  /// | Field | Value | Why |
  /// | --- | --- | --- |
  /// | `action` | always attached | it is what stops the notice expiring, and the way back must not be a race the slowest users lose |
  /// | `tone` | `IuxTransientTone.neutral` | a deletion is a fact, not an achievement; `success` would tint it and add a glyph celebrating the loss |
  ///
  /// Rebuilt on each read, so wording or a callback the parent changed reaches
  /// a notice that is already on screen. `IuxTransientMessage.saysTheSameAs`
  /// deliberately ignores the callback, so this does not restart anything.
  IuxTransientMessage? get notice {
    final IuxUndoOffer? offer = _outstanding;
    if (offer == null) return null;
    return IuxTransientMessage(
      text: offer.notice,
      dismissLabel: offer.dismissLabel,
      action: IuxTransientAction(
        label: offer.undoLabel,
        semanticLabel: offer.undoSemanticLabel,
        onActivate: undo,
      ),
    );
  }

  /// Attempts an activation, and says what became of it.
  ///
  /// [IuxDestructiveFlow] calls this for the caller; use it directly for a
  /// trigger that is not this pattern's control — a menu item, a keyboard
  /// shortcut, a swipe the application already owns.
  ///
  /// Returns synchronously:
  ///
  /// - accepted — the flow asks nobody, the deletion has run, and [notice]
  ///   now carries the way back;
  /// - blocked for [IuxActionBlockedReason.awaitingConfirmation] — the
  ///   question is open, [dialog] is no longer null, nothing has run;
  /// - blocked for any other reason — unavailable or already running.
  IuxActionOutcome activate() => _trigger.activate();

  /// Records the answer "go ahead", and runs the deletion.
  ///
  /// Wired to the confirming choice of [dialog] already. The question closes
  /// first and the deletion runs after, so the parent's callback never
  /// observes a question that is still open.
  void confirm() => _trigger.confirm();

  /// Records the answer "leave it alone". Nothing runs.
  ///
  /// Wired to every way out of [dialog] — the labelled control, the scrim and
  /// the Escape key — so the three cannot come to mean different things.
  void cancel() => _trigger.cancel();

  /// Takes the deletion back, and removes the offer.
  ///
  /// Wired to the notice's own control already; call it directly for an undo
  /// the application offers somewhere else, such as a keyboard shortcut. The
  /// offer is removed **before** `onUndo` runs, so a callback that rebuilds the
  /// page cannot find a control still offering to restore what it just
  /// restored.
  ///
  /// Whether the data actually came back is the application's to know and to
  /// report. This flow reports only that the user asked.
  void undo() {
    final IuxUndoOffer? offer = _outstanding;
    assert(offer != null, _kNoOfferOutstanding);
    if (offer == null) return;
    _outstanding = null;
    notifyListeners();
    offer.onUndo();
  }

  /// Removes the notice without taking the deletion back.
  ///
  /// Wired to `IuxTransientLayer.onDismissed`, which is how the user's own
  /// dismissal reaches it. Call it from the application when a window of its
  /// own closes: the moment the deletion is committed and can no longer be
  /// reversed, the offer must go, because a control that says "Undo" and
  /// cannot is worse than no offer at all.
  ///
  /// A no-op when no notice is outstanding, deliberately: the layer may report
  /// a dismissal for a notice the parent has already cleared.
  void dismissNotice() {
    if (_outstanding == null) return;
    _outstanding = null;
    notifyListeners();
  }

  /// Replaces what this flow describes, restating all of it.
  ///
  /// The same arguments as the constructor, and for the same reason
  /// `IuxDestructiveActionController.update` restates both of its halves:
  /// updating the pieces separately would pass through a state where the scope,
  /// the way back and the wording disagree, and the direction that disagreement
  /// usually takes — a flow still asking with wording that has gone — is a
  /// trigger that silently stops working. Omitting [prompt] therefore means
  /// "this flow asks nobody", and is refused when the way back says otherwise.
  ///
  /// An outstanding notice is **not** cleared. It belongs to a deletion that
  /// has already happened, and changing what the trigger will do next says
  /// nothing about whether the last one can still be taken back. Use
  /// [dismissNotice] for that, which is the honest way to retract a promise.
  void update({
    required IuxActionSemantics semantics,
    required IuxDestructiveScope scope,
    required IuxWayBack wayBack,
    IuxConfirmationPrompt? prompt,
    IuxActionAvailability availability = IuxActionAvailability.enabled,
    IuxActionOperation operation = IuxActionOperation.idle,
  }) {
    assert(_debugProportionate(scope, wayBack, prompt));
    _semantics = semantics;
    _wayBack = wayBack;
    _availability = availability;
    _operation = operation;
    // The inner controller decides whether anything observable changed and
    // notifies through the forwarded listener, so an update that changes
    // nothing still notifies nobody.
    _trigger.update(action: _descriptor, prompt: prompt);
  }

  @override
  void dispose() {
    _trigger.removeListener(notifyListeners);
    _trigger.dispose();
    super.dispose();
  }

  /// The action as the model already understands it, assembled from the two
  /// facts the caller stated.
  IuxActionDescriptor get _descriptor => IuxActionDescriptor.destructive(
        semantics: _semantics,
        availability: _availability,
        operation: _operation,
        // An undo offer is a way back; anything else, from this screen, is not.
        // Where one exists elsewhere — a trash, a support route — it belongs in
        // the consequence the user reads before answering, not in a field
        // nothing renders.
        reversibility: _wayBack.replacesConfirmation
            ? IuxActionReversibility.reversible
            : IuxActionReversibility.irreversible,
        confirmation: _wayBack.replacesConfirmation
            ? IuxConfirmationPolicy.none
            : const IuxConfirmBeforeExecution(),
      );

  /// Runs the caller's deletion and raises the way back, in that order.
  ///
  /// The notice says something has happened, so it must not appear before it
  /// has. A callback that throws leaves no offer, which is correct: there is
  /// nothing to take back.
  void _run() {
    final IuxWayBack wayBack = _wayBack;
    _onDestroy();
    if (wayBack is IuxUndoOffer) {
      // A second deletion replaces the offer belonging to the first, and the
      // first way back is gone. That is a real loss, and it is the one place
      // where the transient channel's replacement rule costs the user
      // something they needed — see the limitations in the documentation.
      _outstanding = wayBack;
      notifyListeners();
    }
  }

  /// Checks the combinations that cannot mean anything, in debug only.
  ///
  /// Returns true so it can be used inside an `assert`; it never returns false,
  /// because each failure is worth its own sentence.
  static bool _debugProportionate(
    IuxDestructiveScope scope,
    IuxWayBack wayBack,
    IuxConfirmationPrompt? prompt,
  ) {
    assert(
      !(scope == IuxDestructiveScope.everything && wayBack is IuxUndoOffer),
      _kUndoBeyondItems,
    );
    assert(!(wayBack.replacesConfirmation && prompt != null), _kUnusedPrompt);
    assert(wayBack.replacesConfirmation || prompt != null, _kMissingPrompt);
    return true;
  }
}

/// The control that starts a destructive flow.
///
/// ```dart
/// IuxDestructiveFlow(label: l10n.archive, controller: controller)
/// ```
///
/// **Use it** wherever an `IuxButton` would go for an action that deletes,
/// revokes, discards or overwrites. The call site is the same whether the flow
/// asks first or offers a way back afterwards, which is the point: changing
/// which safeguard applies is a change to the controller, not a different
/// widget and not a restructured page, so the decision stays reviewable
/// instead of load-bearing.
///
/// **Why not `IuxDestructiveAction`.** That widget is what this one is built
/// from, and it is the right choice when the caller has already decided which
/// safeguard applies and models the way back themselves. This one exists for
/// the decision: it will not let the two be confused, and it produces the undo
/// offer as well as the question.
///
/// **There is no `autofocus`, here or below.** A control that deletes
/// something and takes focus on arrival is one Enter press away from running,
/// pressed by a keyboard user who was still reading the page.
///
/// **Accessibility.** Everything visible belongs to `IuxDestructiveAction`,
/// `IuxButton`, `IuxDialog` and `IuxTransientLayer`: the accessible name comes
/// from `IuxActionSemantics.label`, the target size from `IuxTapTarget`, the
/// focus ring from `IuxFocusable`, the confirmation's focus trap and route
/// semantics from `IuxDialog`, and the notice's live region from
/// `IuxTransientLayer`. This widget draws nothing and adds no semantics of its
/// own, which is what keeps those guarantees in one place each.
class IuxDestructiveFlow extends StatelessWidget {
  /// Creates the control that starts [controller]'s flow.
  const IuxDestructiveFlow({
    super.key,
    required this.label,
    required this.controller,
    this.icon,
    this.variant,
    this.focusNode,
    this.expand = false,
    this.busyHint,
  });

  /// The visible text, already localised.
  ///
  /// Kept separate from the announced name in the controller's
  /// `IuxActionSemantics`, so the button can read "Delete" while a screen
  /// reader hears which thing is being deleted.
  final String label;

  /// The parent-owned state of this flow.
  ///
  /// Created and disposed by the parent, exactly like a
  /// `TextEditingController`.
  final IuxDestructiveFlowController controller;

  /// A glyph shown before [label], in reading order.
  ///
  /// Must be redundant with [label]: it is excluded from the semantic tree.
  final IconData? icon;

  /// How much visual weight to carry. Defaults to the theme's variant.
  ///
  /// Emphasis, not meaning. Reach for a heavier variant because the action
  /// dominates the screen, never to make the user hesitate — hesitation is
  /// what the safeguard is for, and the safeguard is already chosen.
  final IuxButtonVariant? variant;

  /// An externally owned focus node.
  final FocusNode? focusNode;

  /// Whether to fill the available width.
  final bool expand;

  /// Announced after the name while the deletion is running.
  ///
  /// Already localised. Leave it null and a screen reader hears nothing extra,
  /// which is indistinguishable from a control that did nothing — so supply it
  /// whenever the flow's `operation` is driven asynchronously.
  final String? busyHint;

  @override
  Widget build(BuildContext context) => IuxDestructiveAction(
        label: label,
        // The trigger activates the confirmation half directly, and the flow
        // hears about it through the forwarded listener. Routing the tap
        // through the outer controller as well would give the same activation
        // two paths, which is how a deletion ends up running twice.
        controller: controller._trigger,
        icon: icon,
        variant: variant,
        focusNode: focusNode,
        expand: expand,
        busyHint: busyHint,
      );
}
