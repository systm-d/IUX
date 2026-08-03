import 'package:flutter/widgets.dart';

import '../../accessibility/iux_focus.dart';
import '../../accessibility/iux_semantics.dart';
import '../../actions/iux_action_descriptor.dart';
import '../../actions/iux_action_model.dart';
import '../../components/button/iux_button.dart';
import '../../layout/iux_spacing_primitives.dart';
import '../../semantics/iux_semantic_colors.dart';
import '../../themes/extensions/iux_typography_theme.dart';
import 'iux_form.dart';
import 'iux_form_model.dart';
import 'iux_guided_form_model.dart';
import 'iux_validation_summary.dart';

/// Why a guided form of fewer than two steps is refused.
const String _kTooFewSteps =
    'A guided form needs at least two steps. One step is an ordinary form '
    'wearing a position indicator: it tells the user they are on step 1 of 1, '
    'offers a control that goes nowhere, and charges everyone the extra '
    'heading and the extra focus stop that splitting a form is supposed to '
    'buy back. Use IuxForm.';

/// Why an out-of-range step is refused.
const String _kStepOutOfRange =
    'currentStep is an index into steps, and this one is outside it. A guided '
    'form cannot draw a step that does not exist, and the position it would '
    'announce — "step 6 of 5" — describes a form the user is not in.';

/// One rejected field, together with the step it lives on.
///
/// The pairing is the whole reason this pattern exists beside `IuxForm`: an
/// entry in the summary has to know not only which box to focus but which
/// step to be on first, because the box is usually not on screen.
typedef _Rejected = ({int step, IuxFormField field});

/// A form asked in steps, with one summary that reaches across all of them.
///
/// The stepped half of the form pattern. Everything about validation timing,
/// the summary and the submit control is `IuxForm`'s, reused unchanged; what
/// is added here is the step, the announcement that follows one, and a summary
/// entry that can cross a step boundary. See `docs/patterns/stepped-form.md`.
///
/// ```dart
/// IuxGuidedForm(
///   currentStep: state.step,
///   onStepChanged: controller.goToStep,
///   describePosition: l10n.stepOf,              // (int, int) => String
///   backLabel: l10n.back,
///   forwardLabel: l10n.continueLabel,
///   steps: <IuxGuidedFormStep>[
///     IuxGuidedFormStep(
///       title: l10n.yourDetails,
///       sections: <IuxFormSection>[IuxFormSection(fields: details)],
///     ),
///     IuxGuidedFormStep(
///       title: l10n.deliveryAddress,
///       sections: <IuxFormSection>[IuxFormSection(fields: address)],
///     ),
///   ],
///   summary: IuxValidationSummaryLabels(
///     categoryLabel: l10n.error,
///     describeCount: l10n.fieldsNeedAttention,
///     navigationHint: l10n.goToThisField,
///   ),
///   submit: IuxFormSubmit(
///     label: l10n.placeTheOrder,
///     action: state.submitAction,
///     onSubmit: controller.placeOrder,
///   ),
/// )
/// ```
///
/// **Use it** when a form is long enough that showing it at once is the reason
/// people abandon it, and its questions fall into groups that can be answered
/// in an order: a checkout, an application, an account set-up.
///
/// **Do not use it** for a form that fits on one screen. Splitting five
/// questions across three steps adds two navigation events, two announcements
/// and two chances to lose the user's place, and buys nothing back — that is
/// `IuxForm`, and it is the default. Do not use it for lateral views of the
/// same thing, which are `IuxTabs`: a step has an order and a meaning for
/// "back", a tab has neither. And do not use it to sequence something that is
/// not a form; a guided form ends in one submission of one set of answers.
///
/// **The parent owns which step is shown.** [currentStep] comes in,
/// [onStepChanged] goes out, and nothing here holds an index. This is
/// Component Standard §3, and here it is load-bearing rather than tidy: only
/// the application knows whether it must save a draft first, whether the next
/// step depends on an answer that has not arrived, and whether the user may
/// leave at all. If the parent does not rebuild with a new index, the step
/// does not move — which is correct, because a form that showed step 3 while
/// the application believed the user was on step 2 is describing a screen that
/// does not exist.
///
/// ## Nothing here blocks the way forward
///
/// The forward control never refuses, and no step is ever locked. There is no
/// parameter to make it do either.
///
/// The reason is the one `IuxFormSubmit` already gives for keeping a submit
/// control enabled: a control that refuses without explaining is a refusal the
/// user cannot act on, and a *step* that refuses is worse than a button that
/// does, because the user cannot even see which of the questions behind them
/// is the problem. Filling a form out of order is also ordinary behaviour with
/// ordinary reasons — the postcode is on another device, the reference number
/// is in an email, the user wants to see what is asked later before committing
/// to what is asked now.
///
/// So the guarantee is moved to the end rather than removed. Submitting is
/// refused exactly as `IuxForm` refuses it, the summary lists every rejected
/// field on *every* step, and each entry takes the user to the step it is on
/// and then to the field. Nothing can be hidden by being behind the user.
///
/// ## A step change is a navigation event
///
/// When [currentStep] changes, focus moves to the new step's heading, whose
/// node carries the position, the title and the description as one utterance.
/// That is the announcement. A step change that moves nothing leaves a
/// screen-reader user on a control that is now a different control, on a page
/// that silently became a different page (WCAG SC 4.1.3, SC 2.4.3).
///
/// It goes to the heading rather than to the first field, and the difference
/// matters in two ways. The heading says what this step is, so the user hears
/// the question before being asked to answer it. And landing in a text field
/// on Android raises the keyboard over the step the user has not seen yet.
///
/// It goes to the heading rather than staying on the forward control for the
/// same reason a refusal is not announced by leaving focus where it was: the
/// control the user just pressed is, one frame later, a *different* control —
/// on the last step it is the submit — and focus resting on it announces
/// nothing about what changed.
///
/// The one exception is arriving from the summary. Activating an entry that
/// points at another step changes the step and then focuses the *field*,
/// because the user did not ask to be told about the step; they asked to be
/// taken to a box they were told was wrong. Stopping at the heading first
/// would be a second journey they did not ask for.
///
/// ## Where the user is, in words
///
/// [describePosition] is required, and there is no way to render a guided form
/// without it. A stepped form that does not say how many steps remain has
/// taken the one thing it charges the user for — the extra navigation — and
/// given back nothing they can plan around.
///
/// It is text, not a bar, and that is a decision rather than an omission. The
/// sentence reaches everybody: a screen-reader user, a user reading a
/// monochrome screen, a user who has turned the contrast up. A bar carries the
/// same fact in a second, weaker encoding for the people who already had it —
/// and drawing one with `IuxProgressIndicator` would put a live region in the
/// same frame as the focus move, so a screen-reader user would hear two
/// utterances competing for one event. That is the failure
/// `IuxValidationSummary` avoids by not being a live region, and the reason
/// `IuxForm` forbids a second focus move from `onBlocked`.
///
/// A caller who wants a bar places one above this widget and owns the
/// duplication knowingly. See `docs/patterns/stepped-form.md` for what that
/// costs.
///
/// ## Where the summary lives
///
/// Under the step heading, above the questions — one position lower than
/// `IuxForm` puts it, and deliberately.
///
/// Focus lands on the heading on every step change, so the summary has to be
/// the *next* stop after it. Put above the heading, it would sit behind the
/// user every time they navigated back to repair something, and a user who
/// arrives to fix one problem would have walked away from the list of the
/// others. At the moment of the refusal nothing is lost either way: focus goes
/// straight to the summary wherever it is.
///
/// It stays on screen, on every step, until nothing is rejected. A summary
/// that vanished when the user acted on it would delete the list of remaining
/// problems at the exact moment the user started working through them.
///
/// ## Known limitations
///
/// The summary is one flat list in field order across every step; it does not
/// say which step an entry is on. The entry labels are the field names the
/// parent supplied, and a form with "Address" on two different steps has to
/// distinguish them in those names.
///
/// Nothing here reviews the earlier steps before submission. A confirmation
/// page that lists the answers with a way back to each is a screen the
/// application builds, out of the same steps.
///
/// There is no per-step submission and no draft saving. One guided form is one
/// set of answers committed once, by [submit], on the last step.
///
/// A journey to a field on another step lasts exactly as long as the parent's
/// next answer. It completes if the next rebuild is the step it asked for; it
/// is abandoned by a rebuild that is not, by either navigation control, and by
/// submitting. The residue is one case: a parent whose next rebuild is that
/// step, granted long after the request for a reason of its own, finishes a
/// journey the user had stopped expecting. Nothing here can tell that apart
/// from a slow grant.
class IuxGuidedForm extends StatefulWidget {
  /// Creates a form asked in steps.
  const IuxGuidedForm({
    super.key,
    required this.steps,
    required this.currentStep,
    required this.onStepChanged,
    required this.describePosition,
    required this.backLabel,
    required this.forwardLabel,
    required this.summary,
    required this.submit,
    this.timing = IuxValidationTiming.onBlur,
  })  : assert(steps.length > 1, _kTooFewSteps),
        assert(
            currentStep >= 0 && currentStep < steps.length, _kStepOutOfRange),
        assert(
          backLabel.length > 0,
          'The way back must be named. An unnamed control is announced as '
          '"button" and nothing else, and the way back is the control a user '
          'reaches for after realising they answered the previous question '
          'wrongly.',
        ),
        assert(
          forwardLabel.length > 0,
          'The way forward must be named. Name where it goes — "Continue to '
          'payment" — rather than the mechanism; "Next" tells the user that '
          'something will happen and refuses to say what.',
        );

  /// The steps, in the order they are asked.
  ///
  /// Every step is described whether or not it is on screen: the summary lists
  /// rejected fields from all of them, so a problem cannot be hidden by being
  /// behind the user.
  final List<IuxGuidedFormStep> steps;

  /// Which step is on screen, as an index into [steps].
  ///
  /// Owned by the parent. See the class documentation.
  final int currentStep;

  /// Called with the index of the step the user asked to go to.
  ///
  /// Fired by the two navigation controls and by a summary entry pointing at
  /// another step. It is a request, not a report: nothing moves until the
  /// parent rebuilds with the new [currentStep], and a parent that declines
  /// leaves the form exactly where it was.
  final ValueChanged<int> onStepChanged;

  /// The sentence saying where in the form the user is.
  ///
  /// See [IuxStepPositionDescription]. Required, because a stepped form that
  /// cannot say how much is left has charged the user for the steps and given
  /// nothing back.
  final IuxStepPositionDescription describePosition;

  /// The visible text of the control that goes back one step, already
  /// localised.
  ///
  /// One word for the whole form rather than one per step. The position
  /// already says where the user is, and a way back whose name changes at
  /// every step is a control they have to read again each time to be sure it
  /// still does what it did.
  final String backLabel;

  /// The visible text of the control that goes forward one step, already
  /// localised.
  ///
  /// Replaced by [submit] on the last step, where the control commits the form
  /// instead of moving within it.
  final String forwardLabel;

  /// The text the error summary is built from.
  ///
  /// Required here, where `IuxForm` allows null. A single-page form without a
  /// summary can still send focus to the first rejected field, because that
  /// field is on screen. In a guided form it usually is not: the rejected
  /// question is two steps back, there is nothing to focus and nothing to see,
  /// and the refusal becomes a form that will not submit and will not say why.
  /// The summary is the only route across a step boundary, so it is not
  /// optional.
  final IuxValidationSummaryLabels summary;

  /// The action that commits the whole form, shown on the last step.
  ///
  /// The same type `IuxForm` takes, including its refusal to accept a disabled
  /// action that does not say why.
  final IuxFormSubmit submit;

  /// When the form asks the parent to check a field.
  ///
  /// See [IuxValidationTiming]; the default and its defence are `IuxForm`'s,
  /// unchanged. Only the fields of the step on screen are watched for a blur —
  /// a field on another step has no focus to lose.
  ///
  /// **Moving between steps asks for no checks**, including for the field the
  /// user was standing in when they pressed the control. Leaving a step is not
  /// abandoning it, and a rejection raised at that moment lands on a question
  /// the user can no longer see. The check that catches an unanswered question
  /// is the one every field is asked for on submit, whose failure the summary
  /// can point at.
  ///
  /// That last part is inherited rather than enforced: a `FocusNode` detached
  /// from the tree does not notify its listeners, so a field that loses focus
  /// by being unmounted produces no blur. It was measured rather than assumed,
  /// and the test that measured it is a pin — the day Flutter changes it, the
  /// day this pattern would start reporting errors about invisible questions,
  /// is visible.
  final IuxValidationTiming timing;

  @override
  State<IuxGuidedForm> createState() => _IuxGuidedFormState();
}

class _IuxGuidedFormState extends State<IuxGuidedForm> {
  /// The node focus moves to when a submission is refused.
  final FocusNode _summaryNode = FocusNode(debugLabel: 'IuxGuidedForm summary');

  /// The node focus moves to when the step changes.
  ///
  /// One node for every step rather than one per step: it is the heading of
  /// whichever step is on screen, and a node per step would be a list to keep
  /// in step with [IuxGuidedForm.steps] for no gain.
  final FocusNode _stepNode = FocusNode(debugLabel: 'IuxGuidedForm step');

  /// The blur listeners currently attached, by the node they are attached to.
  ///
  /// Only ever the fields of the step on screen. A field on another step is
  /// not mounted, so it can neither gain nor lose focus, and a listener on it
  /// is bookkeeping that can only go stale — [_hadFocus] would hold an answer
  /// from before the step left, and the first move after the user came back
  /// would be judged against it.
  final Map<FocusNode, VoidCallback> _listeners = <FocusNode, VoidCallback>{};

  /// Whether each watched node had focus last time we looked.
  ///
  /// A `FocusNode` listener fires for changes other than focus, so "did it
  /// just lose focus" has to be worked out rather than assumed.
  final Map<FocusNode, bool> _hadFocus = <FocusNode, bool>{};

  /// How many times the user has asked to submit.
  int _attempt = 0;

  /// The attempt for which focus has already been moved to the summary.
  int _focusedAttempt = 0;

  /// A field the user asked to be taken to, waiting for its step to arrive.
  FocusNode? _pendingField;

  /// The step [_pendingField] lives on.
  ///
  /// Kept beside the node so a parent that declines the step change cannot
  /// leave a focus move armed for whenever the form next rebuilds.
  int? _pendingStep;

  @override
  void initState() {
    super.initState();
    _syncListeners();
  }

  @override
  void didUpdateWidget(IuxGuidedForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncListeners();

    if (widget.currentStep != oldWidget.currentStep) {
      // The user navigated, which outranks anything else this frame: they are
      // waiting to find out where they now are. Any refusal still pending is
      // consumed rather than deferred, so it cannot ambush focus a frame
      // later — the summary itself stays on screen and still says everything.
      _focusedAttempt = _attempt;
      _handleStepArrival();
      return;
    }

    // The step did not move. If the user had asked to be taken to a field on
    // another step, the parent has declined; drop it rather than leave a focus
    // move waiting for a step that may never arrive.
    _pendingField = null;
    _pendingStep = null;

    // The parent has rebuilt, possibly with the rejections that answer a
    // submission already sent.
    if (_attempt != _focusedAttempt) _moveFocusToSummary();
  }

  @override
  void dispose() {
    for (final MapEntry<FocusNode, VoidCallback> entry in _listeners.entries) {
      entry.key.removeListener(entry.value);
    }
    _listeners.clear();
    _summaryNode.dispose();
    _stepNode.dispose();
    super.dispose();
  }

  /// The step on screen.
  IuxGuidedFormStep get _step => widget.steps[widget.currentStep];

  /// Whether the step on screen is the last one.
  bool get _isLastStep => widget.currentStep == widget.steps.length - 1;

  /// Every field of every step, paired with the step it is on, in the order
  /// they are asked.
  List<_Rejected> get _allFields => <_Rejected>[
        for (int step = 0; step < widget.steps.length; step++)
          for (final IuxFormField field in widget.steps[step].fields)
            (step: step, field: field),
      ];

  /// The fields the parent has rejected, across every step, in field order.
  List<_Rejected> get _rejected =>
      _allFields.where((_Rejected each) => each.field.isInvalid).toList();

  /// Attaches a blur listener to every field of the step on screen, and drops
  /// the ones that left with the previous step.
  ///
  /// The nodes belong to the parent, so this never disposes one — it only
  /// stops listening. A pattern that disposed a node it was handed would take
  /// a field down with it the next time the parent rebuilt.
  ///
  /// Called from `didUpdateWidget`, which runs before the outgoing step's
  /// widgets are unmounted.
  void _syncListeners() {
    final Set<FocusNode> current = <FocusNode>{
      for (final IuxFormField field in _step.fields) field.focusNode,
    };

    for (final FocusNode node in _listeners.keys.toList()) {
      if (current.contains(node)) continue;
      node.removeListener(_listeners.remove(node)!);
      _hadFocus.remove(node);
    }

    for (final FocusNode node in current) {
      if (_listeners.containsKey(node)) continue;
      void listener() => _handleFocusChange(node);
      _listeners[node] = listener;
      _hadFocus[node] = node.hasFocus;
      node.addListener(listener);
    }
  }

  /// Asks for a check when the user leaves a field they have edited.
  void _handleFocusChange(FocusNode node) {
    final bool had = _hadFocus[node] ?? false;
    final bool has = node.hasFocus;
    if (had == has) return;
    _hadFocus[node] = has;

    // Only the departure matters. Checking a field the user has just arrived
    // in would reject a value before they have had the chance to change it.
    if (has) return;
    if (widget.timing != IuxValidationTiming.onBlur) return;

    for (final IuxFormField field in _step.fields) {
      if (field.focusNode != node) continue;
      // A field the user only passed through has nothing to check. The error
      // it would produce is about a value they were never given the chance to
      // get wrong.
      if (!field.edited) return;
      field.onValidationRequested?.call(IuxValidationTrigger.blur);
      return;
    }
  }

  /// Handles an activation of a navigation control.
  ///
  /// Any journey still waiting for a step is abandoned here. A parent may
  /// decline a step change by simply not rebuilding, in which case nothing
  /// tells this widget that its request was refused — and a journey left armed
  /// would then finish itself the next time the user happened to walk back to
  /// that step, dropping them into a field when all they pressed was Back.
  /// The last thing the user asked for is the one that decides where focus
  /// goes.
  void _stepByControl(int step) {
    _pendingField = null;
    _pendingStep = null;
    widget.onStepChanged(step);
  }

  /// Handles an activation of the submit control.
  ///
  /// The control itself has already refused an unavailable or busy action, so
  /// anything arriving here is a genuine request to commit.
  void _handleSubmit() {
    _pendingField = null;
    _pendingStep = null;
    setState(() => _attempt++);

    // Already rejected, and the form knows it — on this step or on any other.
    // Sending the parent a submission it would have to refuse a second time
    // helps nobody.
    if (_rejected.isNotEmpty) {
      widget.submit.onBlocked?.call();
      _moveFocusToSummary();
      return;
    }

    // Nothing is known to be wrong, which is not the same as everything being
    // right: a field two steps back may never have been checked at all. Ask
    // for all of them, then hand the decision to the parent.
    for (final _Rejected each in _allFields) {
      each.field.onValidationRequested?.call(IuxValidationTrigger.submit);
    }
    widget.submit.onSubmit();
  }

  /// Moves focus to the summary after a refused submission.
  ///
  /// Scheduled for after the frame, because the summary this focuses does not
  /// exist until the build that follows the refusal.
  void _moveFocusToSummary() {
    if (_rejected.isEmpty) return;
    _focusedAttempt = _attempt;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      IuxFocus.request(_summaryNode);
    });
  }

  /// Moves focus after the step on screen has changed.
  ///
  /// To the field the user asked for when they arrived from the summary, and
  /// to the step heading otherwise. Scheduled for after the frame, because
  /// neither destination is mounted until the build that follows.
  void _handleStepArrival() {
    final FocusNode? pending =
        _pendingStep == widget.currentStep ? _pendingField : null;
    _pendingField = null;
    _pendingStep = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (pending != null) {
        _focusField(pending);
        return;
      }
      IuxFocus.request(_stepNode);
    });
  }

  /// Takes the user to a rejected field, crossing a step boundary if it is on
  /// another step.
  void _navigateToField(int step, FocusNode node) {
    if (step == widget.currentStep) {
      _focusField(node);
      return;
    }
    // The field is not mounted, so it cannot be focused yet. Ask for the step
    // and finish the journey when the parent grants it.
    _pendingField = node;
    _pendingStep = step;
    widget.onStepChanged(step);
  }

  /// Focuses a field and brings it on screen.
  ///
  /// Both, because either alone leaves someone behind: focus without scrolling
  /// moves a screen-reader user to a field a sighted user still cannot see,
  /// and scrolling without focus does the reverse.
  void _focusField(FocusNode node) {
    IuxFocus.request(node);
    final BuildContext? fieldContext = node.context;
    if (fieldContext == null) return;
    // Instant rather than animated. The user asked to be taken somewhere, and
    // an animation between two points they did not choose is a journey they
    // did not ask to watch.
    Scrollable.ensureVisible(fieldContext);
  }

  /// The summary, or null when there is nothing to summarise.
  ///
  /// It appears only after a submission has been attempted, and then on every
  /// step until the last rejection is repaired. Before the attempt, every
  /// message is already under the field it belongs to; after it, the list of
  /// what is left is the only thing on screen that survives the user walking
  /// back through the steps to fix them.
  Widget? _buildSummary() {
    if (_attempt == 0) return null;

    final List<_Rejected> rejected = _rejected;
    if (rejected.isEmpty) return null;

    return IuxValidationSummary(
      categoryLabel: widget.summary.categoryLabel,
      message: widget.summary.describeCount(rejected.length),
      navigationHint: widget.summary.navigationHint,
      focusNode: _summaryNode,
      entries: <IuxValidationSummaryEntry>[
        for (final _Rejected each in rejected)
          IuxValidationSummaryEntry(
            label: each.field.input.semantics.label,
            // Non-null by construction: IuxInputValidation.invalid requires a
            // message, which is the point of that type.
            message: each.field.input.validation.message!,
            onActivate: () => _navigateToField(each.step, each.field.focusNode),
          ),
      ],
    );
  }

  /// The way back and the way on, in reading order.
  ///
  /// Back first, so the way out of a mistake is the first control reached by
  /// keyboard, by D-pad and by a screen-reader swipe — and so the forward
  /// control, which is the one that commits on the last step, is never the one
  /// a user lands on by accident.
  ///
  /// Both descriptors are derived rather than accepted. A step control that a
  /// caller could configure could be given a confirmation policy, a
  /// destructive intent or a repeat policy that lets two step changes run at
  /// once, and none of those describes moving between two questions. The one
  /// action a caller does own is [IuxGuidedForm.submit], because only the
  /// parent knows when a submission is running.
  Widget _controls() {
    return IuxTargetSpacing(
      axis: Axis.horizontal,
      children: <Widget>[
        if (widget.currentStep > 0)
          IuxButton(
            label: widget.backLabel,
            action: IuxActionDescriptor(
              semantics: IuxActionSemantics(label: widget.backLabel),
              // Navigate, not cancel: going back keeps every answer the user
              // has given. Announcing it as a cancellation would tell them
              // their work is about to be thrown away.
              role: IuxActionRole.navigate,
            ),
            onActivate: () => _stepByControl(widget.currentStep - 1),
          ),
        if (_isLastStep)
          IuxButton(
            label: widget.submit.label,
            action: widget.submit.action,
            busyHint: widget.submit.busyHint,
            onActivate: _handleSubmit,
          )
        else
          IuxButton(
            label: widget.forwardLabel,
            action: IuxActionDescriptor(
              semantics: IuxActionSemantics(label: widget.forwardLabel),
              role: IuxActionRole.navigate,
              intent: IuxActionIntent.primary,
              importance: IuxActionImportance.high,
            ),
            onActivate: () => _stepByControl(widget.currentStep + 1),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final IuxGuidedFormStep step = _step;
    final Widget? summary = _buildSummary();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _IuxStepHeading(
          focusNode: _stepNode,
          position: widget.describePosition(
            widget.currentStep + 1,
            widget.steps.length,
          ),
          title: step.title,
          description: step.description,
        ),
        const IuxGap.between(),
        if (summary != null) ...<Widget>[
          summary,
          const IuxGap.between(),
        ],
        for (int i = 0; i < step.sections.length; i++) ...<Widget>[
          if (i > 0) const IuxGap.between(),
          step.sections[i],
        ],
        const IuxGap.between(),
        // Aligned to the start rather than stretched, and wrapping rather than
        // overflowing: at a large text scale two controls stop fitting side by
        // side, and stacking is the only outcome in which both stay usable.
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: _controls(),
        ),
      ],
    );
  }
}

/// The heading of the step on screen: where the user is, what this step is,
/// and what it is for.
///
/// It is focusable because it is the destination of every step change. One
/// node carries all three sentences, so arriving here is a single announcement
/// rather than three fragments the user has to swipe through to assemble —
/// which is the same arrangement `IuxValidationSummary` uses for the same
/// reason.
class _IuxStepHeading extends StatelessWidget {
  const _IuxStepHeading({
    required this.focusNode,
    required this.position,
    required this.title,
    required this.description,
  });

  /// The node focus is moved to when the step changes.
  final FocusNode focusNode;

  /// Where the user is, in the caller's words.
  final String position;

  /// What this step is about, in the caller's words.
  final String title;

  /// What the step is for, in the caller's words, or null.
  final String? description;

  /// What a screen reader says when focus arrives here.
  ///
  /// Joined with a full stop, which is a pause between three of the caller's
  /// own sentences rather than a sentence of IUX's own. The alternative is
  /// three stops in the reading order for one arrival, of which the first —
  /// "Step 2 of 5" — is the only one focus would have landed on.
  String get _spoken => <String>[
        position,
        title,
        if (description != null) description!,
      ].join('. ');

  @override
  Widget build(BuildContext context) {
    final IuxTypographyTheme type = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);

    return IuxFocusable(
      focusNode: focusNode,
      child: Semantics(
        // Not a container, so this annotation merges into the node the focus
        // produced. One node carries "focusable, focused, heading, Step 2 of
        // 5. Delivery address" — which is what makes arriving here an
        // announcement rather than silence. Split across two nodes, focus
        // would land on the unnamed one.
        //
        // A heading as well as a destination: a screen-reader user who moves
        // by heading can then reach the top of the step without walking back
        // through the questions.
        header: true,
        label: _spoken,
        child: IuxSemantics.decorative(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // The position first, in the supporting style. It is the
              // smallest thing on the heading and the one a returning user
              // looks for; putting it under the title would make them read the
              // title to find it.
              Text(
                position,
                style:
                    type.supporting.copyWith(color: colors.content.secondary),
                softWrap: true,
              ),
              const IuxGap.tight(),
              Text(
                title,
                style: type.headline.copyWith(color: colors.content.primary),
                softWrap: true,
              ),
              if (description != null) ...<Widget>[
                const IuxGap.tight(),
                Text(
                  description!,
                  style:
                      type.supporting.copyWith(color: colors.content.secondary),
                  // No line limit and no ellipsis, at any text size. Half a
                  // sentence explaining what a step is for is worse than none,
                  // and truncation gets worse exactly when someone has
                  // enlarged their text because they were struggling to read.
                  softWrap: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
