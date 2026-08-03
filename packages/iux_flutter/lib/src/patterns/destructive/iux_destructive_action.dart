import 'package:flutter/widgets.dart';

import '../../actions/iux_action_descriptor.dart';
import '../../actions/iux_action_model.dart';
import '../../components/button/iux_button.dart';
import '../../components/overlay/iux_dialog.dart';
import '../../themes/extensions/iux_button_theme.dart';
import 'iux_confirmation_prompt.dart';

/// Why a confirming action with no wording is refused.
const String _kMissingPrompt =
    'This action declares a confirmation policy but no IuxConfirmationPrompt '
    'was given, so nothing would be shown and the action would never run — a '
    'control that does nothing when tapped is indistinguishable from one that '
    'is broken. Supply the prompt, or declare IuxConfirmationPolicy.none and '
    'offer an undo instead.';

/// Why wording with no policy to present it is refused.
const String _kUnusedPrompt =
    'An IuxConfirmationPrompt was given for an action whose confirmation '
    'policy is IuxConfirmationPolicy.none, so it would never be shown. Left '
    'alone this is the worst kind of bug: the call site reads as if the user '
    'were being asked, and the action runs on the first tap. Set '
    'IuxConfirmBeforeExecution on the descriptor, or drop the prompt.';

/// Why confirming a reversible action is refused.
const String _kReversibleConfirmation =
    'This action is declared IuxActionReversibility.reversible and also asks '
    'to be confirmed. Undo beats confirmation whenever the action can be '
    'undone: a confirmation charges every user a step to prevent a mistake '
    'most of them will never make, while an undo costs nothing until somebody '
    'actually errs — and it is the only one of the two that helps the user who '
    'meant to press the button and was wrong about what it did. Confirming '
    'everything also trains people to dismiss confirmations unread, which is '
    'how the one that mattered gets dismissed too. Declare '
    'IuxConfirmationPolicy.none and offer an undo, or — if going back is '
    'genuinely slow or partial — say so with '
    'IuxActionReversibility.difficultToReverse.';

/// Why hold-to-confirm and double activation are not presented here.
const String _kUnsupportedPolicy =
    'This pattern presents IuxNoConfirmation and IuxConfirmBeforeExecution. '
    'IuxConfirmByHold is invisible to a screen reader unless it is announced '
    'and is hard to perform with tremor or limited dexterity, so it may never '
    'be the only way to reach an action — and a single control cannot offer a '
    'second route to itself. IuxConfirmByDoubleActivation arms a control in '
    'place, which needs either a disarm timeout the user has to beat or a '
    'visible way back that one button has nowhere to put. Both belong to a '
    'pattern that owns more of the screen than this one does. Use '
    'IuxConfirmBeforeExecution, or IuxConfirmationPolicy.none with an undo.';

/// Why confirming something nobody asked about is refused.
const String _kNotConfirming =
    'confirm() was called while no confirmation was open, so this would run '
    'the action on behalf of a user who was never asked. Call activate() and '
    'let the controller decide whether an answer is needed.';

/// Runs an action worth being careful about, and presents the confirmation it
/// asks for — when it asks for one.
///
/// **Read this before reaching for a confirmation.** An action the user can
/// undo should not be confirmed. A confirmation charges every user a step to
/// prevent a mistake most of them will never make; an undo costs nothing until
/// somebody actually errs, and it is the only one of the two that helps the
/// user who meant to press the button and was wrong about what it did.
/// Confirming every deletion also trains people to dismiss confirmations
/// unread, which is how the one that mattered gets dismissed too.
///
/// So the shortest path through this API is the one with no confirmation in
/// it, and that is deliberate:
///
/// ```dart
/// // Reversible. It runs on the first tap; the page offers the way back.
/// final controller = IuxDestructiveActionController(
///   action: IuxActionDescriptor.destructive(
///     semantics: IuxActionSemantics(label: l10n.archiveMarchInvoice),
///     reversibility: IuxActionReversibility.reversible,
///     confirmation: IuxConfirmationPolicy.none,
///   ),
///   onConfirmed: model.archive,
/// );
/// ```
///
/// The undo offer itself belongs to the parent, because the undo *window* is a
/// decision about data rather than about pixels: how long an application holds
/// an archived row before committing is not something a widget can know. Show
/// it with an `IuxTransientMessage` carrying an `IuxTransientAction` — a
/// message with an action does not expire, so the offer is not a race the
/// slowest users lose.
///
/// When going back is genuinely not on offer, the confirmation is one more
/// argument:
///
/// ```dart
/// final controller = IuxDestructiveActionController(
///   action: IuxActionDescriptor.destructive(
///     semantics: IuxActionSemantics(label: l10n.deleteSelectedFiles),
///   ),
///   onConfirmed: model.delete,
///   prompt: IuxConfirmationPrompt(
///     title: l10n.deleteThreeFilesTitle,
///     consequence: l10n.deleteThreeFilesConsequence,
///     confirmLabel: l10n.delete,
///     keepLabel: l10n.keepTheFiles,
///   ),
/// );
/// ```
///
/// Nothing else about the call site changes. Turning a confirmation on or off
/// is a word in the descriptor, not a different widget and not a restructured
/// page, which is what makes the decision reviewable instead of load-bearing.
///
/// ## Where the dialog goes
///
/// The controller does not put anything on screen. It exposes [dialog], and
/// the parent hands it to an `IuxModalLayer` at page level:
///
/// ```dart
/// ListenableBuilder(
///   listenable: controller,
///   builder: (BuildContext context, Widget? child) => IuxModalLayer(
///     dialog: controller.dialog,
///     child: IuxPage(child: content),
///   ),
/// )
/// ```
///
/// The `ListenableBuilder` is what rebuilds the page when the answer is asked
/// for and again when it is given. [IuxDestructiveAction] listens on its own
/// behalf, so the button below stays correct either way — but the layer that
/// holds the dialog is above it, and nothing else would tell it to look again.
///
/// A pattern that pushed a route would be deciding navigation, and navigation
/// belongs to the application. A pattern that opened its own overlay from
/// wherever the button happened to sit would be deciding layering, which is
/// how two modals end up open at once with the way out of neither visible.
///
/// The cost of that honesty is one line the parent must not forget: with no
/// `IuxModalLayer` reading [dialog], the confirmation is computed and never
/// shown, and the button appears inert. See the known limitations in
/// `docs/patterns/destructive-action.md`.
///
/// ## It is not only for destruction
///
/// Any action with a serious consequence fits, whatever its intent: sending a
/// message is not destructive and is irreversible. The model already says so
/// through `IuxActionDescriptor.hasSeriousConsequence`, and nothing here
/// requires [IuxActionIntent.destructive].
///
/// ## It does not decide the outcome
///
/// The `onConfirmed` callback is the parent's. This controller reports that the
/// user asked for the action and that any confirmation it required was
/// obtained; whether the deletion then succeeded is something only the caller
/// can know. For work that takes time, drive an `IuxAsyncActionController` from
/// `onConfirmed` and feed its `descriptor` back through [update], so the same
/// control shows the operation running.
class IuxDestructiveActionController extends ChangeNotifier {
  /// Creates a controller for [action], running [onConfirmed] once the
  /// confirmation it requires — if any — has been given.
  ///
  /// [prompt] is required exactly when [action] declares a confirmation
  /// policy, and refused when it does not. Both directions are asserted: wording
  /// with no policy reads at the call site as though the user were being asked
  /// and is not, and a policy with no wording produces a control that does
  /// nothing.
  IuxDestructiveActionController({
    required IuxActionDescriptor action,
    required VoidCallback onConfirmed,
    IuxConfirmationPrompt? prompt,
  })  : _action = action,
        _prompt = prompt,
        _onConfirmed = onConfirmed {
    assert(_debugCoherent(action, prompt));
  }

  final VoidCallback _onConfirmed;
  IuxActionDescriptor _action;
  IuxConfirmationPrompt? _prompt;
  bool _confirming = false;

  /// What the action is, and whether it may currently run.
  ///
  /// Hand this to the control that triggers it. [IuxDestructiveAction] does so
  /// already.
  IuxActionDescriptor get action => _action;

  /// The wording of the confirmation, or null when the action asks for none.
  IuxConfirmationPrompt? get prompt => _prompt;

  /// Whether the user has been asked and has not yet answered.
  bool get isConfirming => _confirming;

  /// The confirmation currently open, or null when none is.
  ///
  /// Give it to `IuxModalLayer.dialog`. It is rebuilt on every read, which is
  /// what lets a label or an availability that changed reach the open dialog;
  /// the dialog keeps its own state because it stays in the same position in
  /// the tree.
  ///
  /// The confirming choice carries this action's descriptor with its
  /// confirmation policy cleared — it *is* the confirmation, and an action that
  /// asked to be confirmed again inside its own confirmation would never run.
  /// Everything else is kept, so a disabled or already-running action is
  /// disabled or already-running here too.
  IuxDialog? get dialog {
    final IuxConfirmationPrompt? prompt = _prompt;
    if (!_confirming || prompt == null) return null;
    return IuxDialog(
      title: prompt.title,
      message: prompt.consequence,
      dismissLabel: prompt.keepLabel,
      onDismiss: cancel,
      actions: <IuxDialogAction>[
        IuxDialogAction(
          label: prompt.confirmLabel,
          action: _action.copyWith(confirmation: IuxConfirmationPolicy.none),
          onActivate: confirm,
        ),
      ],
    );
  }

  /// Attempts an activation, and says what became of it.
  ///
  /// Returns synchronously, because the verdict is knowable now:
  ///
  /// - accepted — the action needed no confirmation and `onConfirmed` has
  ///   already run;
  /// - blocked for [IuxActionBlockedReason.awaitingConfirmation] — the
  ///   confirmation is now open, [dialog] is no longer null, and nothing has
  ///   run;
  /// - blocked for any other reason — the action is unavailable or already
  ///   running, and nothing has run or opened.
  ///
  /// The verdict comes from [IuxActionPolicy], asked with `confirmed: false`.
  /// That is the difference between this pattern and a plain `IuxButton`: the
  /// core components assume the confirmation was already obtained, because
  /// obtaining it is this pattern's job.
  IuxActionOutcome activate() {
    final IuxActionOutcome outcome =
        IuxActionPolicy.evaluate(_action, confirmed: false);

    if (outcome.isAccepted) {
      _onConfirmed();
      return outcome;
    }

    if (outcome.blockedReason == IuxActionBlockedReason.awaitingConfirmation &&
        !_confirming) {
      _confirming = true;
      notifyListeners();
    }

    return outcome;
  }

  /// Records the answer "go ahead", and runs the action.
  ///
  /// Wired to the confirming choice of [dialog]. The confirmation is closed
  /// first and the action runs after, so the parent's callback never observes a
  /// question that is still open, and focus is already on its way back to
  /// whatever held it.
  void confirm() {
    assert(_confirming, _kNotConfirming);
    if (!_confirming) return;
    _confirming = false;
    notifyListeners();
    _onConfirmed();
  }

  /// Records the answer "leave it alone".
  ///
  /// Wired to every way out of [dialog] — the labelled control, the scrim and
  /// the Escape key — so the three cannot come to mean different things.
  /// Nothing runs.
  void cancel() {
    if (!_confirming) return;
    _confirming = false;
    notifyListeners();
  }

  /// Replaces what this controller describes.
  ///
  /// For anything that moves: an availability that follows the selection, an
  /// operation driven by an `IuxAsyncActionController`, wording that names the
  /// row the user is on, a locale that changed under an already-built
  /// controller.
  ///
  /// Both halves are stated together and neither is merged, deliberately.
  /// Updating them separately would pass through a state where the policy and
  /// the wording disagree, and the direction that disagreement usually takes —
  /// a policy still asking for a confirmation whose wording has gone — is a
  /// control that silently stops working. Omitting [prompt] therefore means
  /// "this action asks for none", and is refused when the action says
  /// otherwise.
  ///
  /// An open confirmation is closed when the new action no longer asks for one.
  /// The alternative is a dialog whose confirming choice would run the action
  /// immediately, which is not the question the user was asked.
  void update({
    required IuxActionDescriptor action,
    IuxConfirmationPrompt? prompt,
  }) {
    assert(_debugCoherent(action, prompt));
    if (action == _action && prompt == _prompt) return;
    _action = action;
    _prompt = prompt;
    if (_confirming && !action.requiresConfirmation) _confirming = false;
    notifyListeners();
  }

  /// Checks the combinations that cannot mean anything, in debug only.
  ///
  /// Returns true so it can be used inside an `assert`; it never returns false,
  /// because each failure is worth its own sentence.
  static bool _debugCoherent(
    IuxActionDescriptor action,
    IuxConfirmationPrompt? prompt,
  ) {
    assert(
      action.confirmation is IuxNoConfirmation ||
          action.confirmation is IuxConfirmBeforeExecution,
      _kUnsupportedPolicy,
    );
    assert(
      !(action.reversibility == IuxActionReversibility.reversible &&
          action.requiresConfirmation),
      _kReversibleConfirmation,
    );
    assert(!action.requiresConfirmation || prompt != null, _kMissingPrompt);
    assert(action.requiresConfirmation || prompt == null, _kUnusedPrompt);
    return true;
  }
}

/// The control that triggers an action worth being careful about.
///
/// ```dart
/// IuxDestructiveAction(label: l10n.delete, controller: controller)
/// ```
///
/// **Use it** wherever an `IuxButton` would go for an action that deletes,
/// revokes, discards, or otherwise cannot be casually taken back — with or
/// without a confirmation. The call site is the same either way; the
/// descriptor decides.
///
/// **Why not just an `IuxButton`.** Because an `IuxButton` handed a descriptor
/// that asks to be confirmed runs the action anyway: it evaluates the action
/// with `confirmed: true` and leaves obtaining the answer to a pattern. That is
/// the correct division of labour and it is also a quiet trap — the descriptor
/// says "confirm me", the code compiles, and nobody is ever asked. This widget
/// is the other half: it routes activation through
/// [IuxDestructiveActionController.activate], which asks with `confirmed:
/// false`.
///
/// **There is no `autofocus`, and there will not be one.** A control that
/// deletes something and takes focus on arrival is one Enter press away from
/// running, pressed by a keyboard user who was still reading the page. The
/// confirmation itself is held to the same rule: `IuxDialog` focuses its panel
/// and never a choice.
///
/// **Accessibility.** The accessible name comes from
/// `IuxActionDescriptor.semantics`, which the action model already requires to
/// be non-empty, so the announced name can be fuller than the visible one —
/// "Delete" on screen, "Delete the March invoice" in a screen reader. Focus,
/// target size, disabled semantics and text scaling are `IuxButton`'s, which is
/// why this widget delegates to it rather than drawing anything itself.
///
/// **States.** Default, focused, pressed, disabled and running all come from
/// the descriptor and from `IuxButton`. There is no error state here: whether
/// the deletion failed is the parent's to report, and an `IuxAsyncActionButton`
/// driven from the controller's `onConfirmed` callback is the shape for that.
class IuxDestructiveAction extends StatelessWidget {
  /// Creates the control that triggers [controller]'s action.
  const IuxDestructiveAction({
    super.key,
    required this.label,
    required this.controller,
    this.icon,
    this.variant,
    this.focusNode,
    this.expand = false,
    this.busyHint,
  }) : assert(
          label.length > 0,
          'A button must show something. An empty label leaves a container a '
          'sighted user can see but cannot identify — and this one deletes '
          'things. There is no icon-only form of this widget for the same '
          'reason: an unlabelled control is the easiest one to hit by '
          'accident.',
        );

  /// The visible text, already localised.
  ///
  /// Kept separate from the announced name in
  /// `IuxActionDescriptor.semantics`, so the button can read "Delete" while a
  /// screen reader hears which thing is being deleted.
  final String label;

  /// The parent-owned confirmation state of this action.
  ///
  /// Created and disposed by the parent, exactly like a `TextEditingController`.
  /// This widget listens to it and renders what it reports.
  final IuxDestructiveActionController controller;

  /// A glyph shown before [label], in reading order.
  ///
  /// Must be redundant with [label]: it is excluded from the semantic tree, so
  /// anything it alone carries is information a screen-reader user never
  /// receives.
  final IconData? icon;

  /// How much visual weight to carry. Defaults to the theme's variant.
  ///
  /// Emphasis, not meaning. Meaning stays in
  /// `IuxActionDescriptor.intent`, and a destructive action drawn loudly is
  /// still a destructive action — reach for a heavier variant because the
  /// action dominates the screen, never to make the user hesitate.
  final IuxButtonVariant? variant;

  /// An externally owned focus node.
  final FocusNode? focusNode;

  /// Whether to fill the available width.
  final bool expand;

  /// Announced after the name while the action is running.
  ///
  /// Already localised. Leave it null and a screen reader hears nothing extra —
  /// silence is indistinguishable from a control that did nothing, so supply it
  /// whenever the descriptor's operation is driven asynchronously.
  final String? busyHint;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: controller,
        builder: (BuildContext context, Widget? child) => IuxButton(
          label: label,
          action: controller.action,
          icon: icon,
          variant: variant,
          focusNode: focusNode,
          expand: expand,
          busyHint: busyHint,
          // The controller decides what an activation means. This widget does
          // not re-implement the rule, so the trigger and the confirmation
          // cannot disagree about whether an answer is still owed.
          onActivate: controller.activate,
        ),
      );
}
