import 'package:flutter/widgets.dart';

import '../../accessibility/iux_focus.dart';
import '../../accessibility/iux_semantics.dart';
import '../../actions/iux_action_descriptor.dart';
import '../../actions/iux_action_model.dart';
import '../../components/button/iux_button.dart';
import '../../components/feedback/iux_inline_feedback.dart';
import '../../layout/iux_spacing_primitives.dart';
import '../../semantics/iux_semantic_colors.dart';
import '../../themes/extensions/iux_typography_theme.dart';
import '../form/iux_guided_form_model.dart';
import 'iux_onboarding_model.dart';

/// Why a flow of fewer than two steps is refused.
const String _kTooFewSteps =
    'An onboarding flow needs at least two steps. One step is not a flow: it '
    'is a screen, and it is very often the better answer — a heading, a '
    'sentence, and two controls, built out of IuxPage and IuxButton, with no '
    'position to announce, no navigation to learn and no place for the user to '
    'get lost. Reach for that first. If a second screen genuinely earns its '
    'place, this pattern is here.';

/// Why an out-of-range step is refused.
const String _kStepOutOfRange =
    'currentStep is an index into steps, and this one is outside it. A flow '
    'cannot draw a step that does not exist, and the position it would '
    'announce — "4 of 3" — describes a screen the user is not on.';

/// Why the way back must be named.
const String _kEmptyBackLabel =
    'The way back must be named. An unnamed control is announced as "button" '
    'and nothing else, and this is the control a user reaches for after '
    'realising they moved past the screen that explained the thing they now '
    'want.';

/// Why the way forward must be named.
const String _kEmptyForwardLabel =
    'The way forward must be named. Name where it goes — "See how budgets '
    'work" — rather than the mechanism; "Next" tells the user that something '
    'will happen and refuses to say what, which is the one fact they are using '
    'to decide whether to stay.';

/// A sequence of screens shown before the user has done anything, which they
/// may leave at any point.
///
/// ```dart
/// IuxOnboardingFlow(
///   currentStep: state.step,
///   onStepChanged: controller.goToStep,
///   describePosition: l10n.stepOf,              // (int, int) => String
///   backLabel: l10n.back,
///   forwardLabel: l10n.seeHowBudgetsWork,
///   steps: <IuxOnboardingStep>[
///     IuxOnboardingStep(
///       title: l10n.trackWhatYouSpend,
///       body: l10n.receiptsAreReadOnThisDeviceAndNeverUploaded,
///     ),
///     IuxOnboardingStep(
///       title: l10n.setABudget,
///       body: l10n.weWillTellYouWhenYouAreCloseToIt,
///     ),
///   ],
///   skip: IuxNamedAction(
///     label: l10n.skipSetup,
///     onActivate: controller.leaveOnboarding,
///   ),
///   finish: IuxNamedAction(
///     label: l10n.startUsingLedger,
///     onActivate: controller.completeOnboarding,
///   ),
/// )
/// ```
///
/// **Use it** for the short sequence of screens an application shows before the
/// user has done anything: what this is for, what it will and will not do with
/// their data, the one setting that is worth choosing up front.
///
/// **Do not use it** for a sequence that collects answers — that is
/// `IuxGuidedForm`, which owns validation, an error summary reaching across
/// every step, and a route back to a rejected field. None of that is here,
/// because none of it applies to a screen that asks for nothing, and a form
/// built on this pattern is a form that cannot tell the user what is wrong.
/// Do not use it for one screen: see [_kTooFewSteps], which names the better
/// answer. Do not use it for lateral views of the same thing, which are
/// `IuxTabs`. And do not use it to explain a control the user is looking at —
/// that is `IuxContextualHelp`, next to the control, at the moment of the
/// question rather than several screens before it.
///
/// ## What makes this different from a stepped form
///
/// Structurally, very little: parent-owned index, focus to the step heading,
/// the position as one required function, and no progress bar. Those four
/// decisions are IUX-033's, argued in `docs/patterns/stepped-form.md`, and they
/// are reused here rather than re-derived.
///
/// What differs is one fact, and everything specific to this pattern follows
/// from it: **the user did not ask to be here.** A checkout is a task they
/// started. An onboarding flow is an interruption placed between them and the
/// application they opened, before they have seen anything to weigh it against.
///
/// | | `IuxGuidedForm` | [IuxOnboardingFlow] |
/// | --- | --- | --- |
/// | the user | started this | was placed in it |
/// | a step holds | `IuxFormSection`s | a title, a sentence, and anything else |
/// | leaving early | is abandoning their own task | is **required to be offered, on every step** |
/// | the end | submits one set of answers | leaves the flow |
///
/// A composition was considered and refused. `IuxGuidedForm` requires
/// `IuxFormSection`s, an `IuxValidationSummaryLabels` and an `IuxFormSubmit`,
/// and an onboarding flow has none of them: it would have to invent a summary
/// that summarises nothing and a submission that submits nothing, and every
/// screen-reader user would then be told about an error summary that can never
/// have an entry. What *is* reused is the piece that carries no form with it —
/// [IuxStepPositionDescription], the same typedef, so the two stepped patterns
/// cannot drift on how a position is expressed.
///
/// ## The way out is required, on every step
///
/// [skip] is not optional, there is no parameter that removes it, and it is
/// drawn on the last step as well as the first.
///
/// This is IUX-031's decision, taken again in the place it matters most.
/// `IuxPermissionMoment` made `decline` required on all three of its moments
/// and called it the most load-bearing requirement in the file, for two
/// reasons that both apply here: **the user always has a way out**, and **the
/// parent always receives the signal that they took it**. A flow with no exit
/// is not an introduction, it is a wall; and an application that cannot tell
/// that this user left can only show the flow again.
///
/// It is a full [IuxButton], beside the others, with the same target floor and
/// the same place in the focus order. There is no parameter with which to draw
/// it as a bare word under a filled rectangle, because that asymmetry — not the
/// wording and not the order — is what makes a screen feel like a trap. This is
/// the same refusal `IuxPermissionRationale` makes, and it is made structurally
/// in the same way: the descriptor is derived here rather than accepted.
///
/// **On every step, including the last.** The alternative — an exit that
/// disappears once the user is nearly through — costs them the one control that
/// must never need discovering (`IuxDisclosureState`, third row) at the exact
/// moment an application is most tempted to remove it. The price is that the
/// last step carries two controls that both leave, and that price is documented
/// under "Known limitations" rather than paid by the user.
///
/// **What this cannot prevent** is stated rather than hidden: an application
/// that shows the flow again on the next launch to somebody who skipped it has
/// turned [skip] into a lie, and no widget can stop it. IUX holds the shape of
/// the conversation; its cadence belongs to the application. That is
/// `IuxPermissionRationale`'s sentence, and it is true here for the same reason.
///
/// ## Nothing moves on its own
///
/// **There is no auto-advance, and no parameter that would add one.** A screen
/// that replaces itself after a few seconds is a time limit on reading (WCAG
/// 2.2 SC 2.2.1), and the version that loops back to the first screen is moving
/// content the user cannot pause (SC 2.2.2). Both fail for exactly the people
/// an introduction is for: somebody reading with a magnifier, somebody
/// translating as they go, somebody who looked away. And an automatic step
/// change would move focus — which is this pattern's announcement — while the
/// user was in the middle of something else.
///
/// So this file imports no timer, starts no animation and holds no ticker.
/// SC 2.2.1 is satisfied by there being no limit to extend rather than by a
/// setting that could be got wrong, and a test pins the absence so that adding
/// one is visible in a diff rather than in the field.
///
/// **There is no swipe, and no `PageView`.** A horizontal drag has no name, no
/// focus stop and no keyboard or D-pad equivalent, so a flow driven by one is a
/// flow a switch user cannot leave — and on Android a horizontal swipe is
/// already TalkBack's own gesture for moving between elements, so the drag
/// never reaches the application at all. The steps move by named controls, which
/// every input method can reach. A caller who wants the gesture as well owns
/// that addition and the four ways it can be got wrong.
///
/// ## Where focus goes when the step changes
///
/// When [currentStep] changes, focus moves to the new step's heading, whose node
/// carries the position, the title and the body as one utterance. That is the
/// announcement.
///
/// This is the sixth focus decision in this library and it agrees with the
/// fifth. `IuxEmptyState` (IUX-028), `IuxErrorRecovery` (IUX-029) and
/// `IuxLoadingRetry` (IUX-030) all decline to move focus, because the thing
/// that changed happened *to* the user while their hands were elsewhere.
/// `IuxForm` (IUX-012) and `IuxGuidedForm` (IUX-033) move it, because the user
/// pressed something and is standing still waiting to find out what happened.
/// A step change here is the second shape: the user pressed Back or the forward
/// control, and is waiting to learn where they now are.
///
/// **Not on the first build.** Focus is moved by a *change*, never by arrival,
/// and here that is a decision rather than a mechanism. The first step is on
/// screen because the application decided to show an onboarding flow — the user
/// asked for nothing — so it is exactly the IUX-028 case, and taking focus on
/// arrival would interrupt whatever the platform was already saying about the
/// screen that just opened.
///
/// **Not the first control.** One frame later that control is a different
/// control, and on the last step it is the one that ends the flow.
///
/// **The heading is not a live region.** Focus arriving there is already the
/// announcement, and a live region would put a second utterance in the same
/// frame — the failure `IuxGuidedForm` refuses a progress bar to avoid.
///
/// ## Where the user is, in words
///
/// [describePosition] is required, and there is no way to render a flow without
/// it. This is IUX-033's rule and the argument is stronger here: a user
/// deciding whether to sit through an interruption is deciding on how long it
/// is, and a flow that will not say has taken that decision away from them.
///
/// **It is text, and there is no dot row.** A row of dots is the usual answer
/// and it fails three ways at once: it carries position through shape and
/// position alone, which is the SC 1.4.1 failure; it is drawn from decorated
/// boxes, which produce no semantic node at all, so it is invisible to a screen
/// reader; and the fix — labelling the row — puts a second utterance in the
/// frame the focus move already owns. Measured rather than assumed: the naive
/// dot row's semantics are probed in this pattern's test and it contributes
/// nothing to the tree. An indicator that cannot announce correctly is not
/// shipped as decoration.
///
/// ## Known limitations
///
/// **The last step carries two controls that both leave.** [skip] and [finish]
/// differ in what the application records, not in what the user sees happen. A
/// caller who cannot make that difference legible in the two labels should ask
/// whether they need [skip] to mean anything on the last step at all — and
/// should not conclude that the exit may be removed there.
///
/// **A long body is a long announcement.** Title and body are one node, heard
/// in full on every arrival at that step, including on the way back. That is the
/// trade for a step change being one utterance rather than three fragments, and
/// the fix is a shorter body rather than a parameter.
///
/// **Nothing here scrolls.** A step with a long body and a picture at a large
/// text scale is the caller's to place inside something scrollable, because a
/// block embedded in a list that already scrolls must not introduce a second
/// one.
///
/// **Nothing here knows whether the flow is worth showing.** Whether these five
/// screens teach anything, and whether the application would be better with
/// none of them, is a judgement no widget can make. The strongest thing this
/// pattern does about it is refuse a single-step flow and name the alternative.
///
/// **The assertions are debug-only.** A release build with an out-of-range step
/// will still try to draw one.
class IuxOnboardingFlow extends StatefulWidget {
  /// Creates an onboarding flow.
  const IuxOnboardingFlow({
    super.key,
    required this.steps,
    required this.currentStep,
    required this.onStepChanged,
    required this.describePosition,
    required this.backLabel,
    required this.forwardLabel,
    required this.skip,
    required this.finish,
  })  : assert(steps.length > 1, _kTooFewSteps),
        assert(
            currentStep >= 0 && currentStep < steps.length, _kStepOutOfRange),
        assert(backLabel.length > 0, _kEmptyBackLabel),
        assert(forwardLabel.length > 0, _kEmptyForwardLabel);

  /// The screens, in the order they are shown.
  final List<IuxOnboardingStep> steps;

  /// Which step is on screen, as an index into [steps].
  ///
  /// Owned by the parent, which is Component Standard §3 and is load-bearing
  /// rather than tidy: only the application knows whether the user may leave,
  /// whether a step should be shown at all on this device, and whether the flow
  /// has already been seen. Nothing here holds an index, and nothing here
  /// advances one.
  final int currentStep;

  /// Called with the index of the step the user asked to go to.
  ///
  /// Fired by the two navigation controls and by nothing else — no timer, no
  /// gesture, no animation completing. It is a request rather than a report:
  /// nothing moves until the parent rebuilds with the new [currentStep], and a
  /// parent that declines leaves the flow exactly where it was.
  final ValueChanged<int> onStepChanged;

  /// The sentence saying where in the flow the user is.
  ///
  /// See [IuxStepPositionDescription], which is `IuxGuidedForm`'s and is shared
  /// rather than copied so the two stepped patterns cannot disagree about how a
  /// position is expressed. Required: see the class documentation.
  final IuxStepPositionDescription describePosition;

  /// The visible text of the control that goes back one step, already
  /// localised.
  ///
  /// One word for the whole flow rather than one per step. The position already
  /// says where the user is, and a control whose name changes at every step has
  /// to be read again each time to be sure it still does what it did.
  ///
  /// Not drawn on the first step, where there is nowhere to go back to.
  final String backLabel;

  /// The visible text of the control that goes forward one step, already
  /// localised.
  ///
  /// Replaced by [finish] on the last step, where the control leaves the flow
  /// rather than moving within it.
  final String forwardLabel;

  /// How the user leaves the flow without reaching the end.
  ///
  /// Required, drawn on every step, and drawn as a full control. See "The way
  /// out is required, on every step" in the class documentation — this is the
  /// most load-bearing parameter in this file.
  ///
  /// Name what happens rather than the mechanism: "Skip setup", "Not now",
  /// "I will look later". "Cancel" makes the user work out which of two things
  /// is being cancelled, and here one of them is the application they opened.
  ///
  /// Its callback is the only signal an application receives that this user
  /// chose not to sit through the flow. A caller that records nothing there can
  /// only show it again.
  final IuxNamedAction skip;

  /// How the user leaves the flow having reached the end.
  ///
  /// Shown in place of the forward control on the last step. Name the
  /// destination — "Start using Ledger" — rather than the mechanism: "Done"
  /// describes the flow rather than what the user is about to get.
  ///
  /// Separate from [skip] because the two are different facts about the same
  /// user, and an application legitimately records them differently. They are
  /// not different *events* as far as the person pressing them is concerned,
  /// which is the limitation named above.
  ///
  /// An [IuxNamedAction] rather than an `IuxFormSubmit`: finishing an
  /// onboarding flow carries no operation and has no busy state, because
  /// nothing here commits anything. An application whose last step starts real
  /// work owns that screen and its progress; a spinner underneath a flow that
  /// has already been left is a spinner nobody sees.
  final IuxNamedAction finish;

  @override
  State<IuxOnboardingFlow> createState() => _IuxOnboardingFlowState();
}

class _IuxOnboardingFlowState extends State<IuxOnboardingFlow> {
  /// The node focus moves to when the step changes.
  ///
  /// One node for every step rather than one per step: it is the heading of
  /// whichever step is on screen, and a list of nodes kept in step with
  /// [IuxOnboardingFlow.steps] would be bookkeeping with nothing to gain.
  final FocusNode _stepNode = FocusNode(debugLabel: 'IuxOnboardingFlow step');

  @override
  void didUpdateWidget(IuxOnboardingFlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentStep == oldWidget.currentStep) return;

    // Scheduled for after the frame, because the heading this focuses belongs
    // to a step that is not mounted until the build that follows.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      IuxFocus.request(_stepNode);
    });
  }

  @override
  void dispose() {
    _stepNode.dispose();
    super.dispose();
  }

  /// Whether the step on screen is the last one.
  bool get _isLastStep => widget.currentStep == widget.steps.length - 1;

  /// The way back, the way out, and the way on, in reading order.
  ///
  /// **Back, skip, forward.** The order is both predecessors' at once: it is
  /// `IuxGuidedForm`'s way back first, so the way out of a mistake is the first
  /// control reached by keyboard, D-pad and screen-reader swipe; and it is
  /// `IuxPermissionRationale`'s refusal-before-offer for the pair that remains,
  /// so the control that ends the flow is never the one an accidental
  /// activation lands on.
  ///
  /// All three descriptors are derived rather than accepted. A control a caller
  /// could configure could be given a confirmation policy, a destructive intent
  /// or a repeat policy that lets two step changes run at once, and none of
  /// those describes moving between two screens of an introduction. There is
  /// therefore also no descriptor with which [IuxOnboardingFlow.skip] could be
  /// drawn as anything less than a peer of the control beside it.
  List<Widget> _controls() {
    return <Widget>[
      if (widget.currentStep > 0)
        IuxButton(
          label: widget.backLabel,
          action: IuxActionDescriptor(
            semantics: IuxActionSemantics(label: widget.backLabel),
            // Navigate, not cancel: going back discards nothing, and
            // announcing it as a cancellation would tell the user something is
            // about to be thrown away.
            role: IuxActionRole.navigate,
          ),
          onActivate: () => widget.onStepChanged(widget.currentStep - 1),
        ),
      IuxButton(
        label: widget.skip.label,
        action: IuxActionDescriptor(
          semantics:
              IuxActionSemantics(label: widget.skip.effectiveSemanticLabel),
          // Dismiss rather than cancel, for the reason
          // `IuxPermissionMoment.declineDescriptor` gives: cancelling abandons
          // an in-progress task and discards what was in it, while leaving an
          // introduction discards nothing at all.
          //
          // Secondary rather than primary — emphasis, not availability. It is
          // a full button with the same target floor and the same place in the
          // focus order as the control beside it.
          role: IuxActionRole.dismiss,
          intent: IuxActionIntent.secondary,
        ),
        onActivate: widget.skip.onActivate,
      ),
      if (_isLastStep)
        IuxButton(
          label: widget.finish.label,
          action: IuxActionDescriptor(
            semantics:
                IuxActionSemantics(label: widget.finish.effectiveSemanticLabel),
            // Navigate rather than submit or confirm: nothing is committed by
            // reaching the end of an introduction, and announcing it as a
            // submission would tell the user their answers are being sent.
            role: IuxActionRole.navigate,
            intent: IuxActionIntent.primary,
            importance: IuxActionImportance.high,
          ),
          onActivate: widget.finish.onActivate,
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
          onActivate: () => widget.onStepChanged(widget.currentStep + 1),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final IuxOnboardingStep step = widget.steps[widget.currentStep];
    final Widget? content = step.content;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _IuxOnboardingHeading(
          focusNode: _stepNode,
          position: widget.describePosition(
            widget.currentStep + 1,
            widget.steps.length,
          ),
          title: step.title,
          body: step.body,
        ),
        if (content != null) ...<Widget>[
          const IuxGap.between(),
          content,
        ],
        const IuxGap.between(),
        // Aligned to the start rather than stretched, and wrapping rather than
        // overflowing: at a large text scale three controls stop fitting side
        // by side, and stacking is the only outcome in which all three stay
        // usable — including the one that leaves.
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: IuxTargetSpacing(
            axis: Axis.horizontal,
            children: _controls(),
          ),
        ),
      ],
    );
  }
}

/// The heading of the step on screen: where the user is, what this step is
/// called, and what it says.
///
/// Focusable, because it is the destination of every step change. One node
/// carries all three sentences, so arriving is a single announcement rather
/// than three fragments the user has to swipe through to assemble.
///
/// **This is very nearly `IuxGuidedForm`'s private `_IuxStepHeading`, and the
/// duplication is recorded rather than hidden.** The two differ in that the
/// body here is required and is the substance of the screen rather than an
/// optional note above a set of questions, so it takes the primary content
/// role. Extracting one shared widget would mean editing
/// `lib/src/patterns/form/iux_guided_form.dart`, which IUX-036 does not own; it
/// is noted in `docs/patterns/onboarding.md` for whoever does. This is the same
/// kind of debt `IuxProgressiveDisclosure` recorded against
/// `IuxContextualHelp`'s private disclosure control.
class _IuxOnboardingHeading extends StatelessWidget {
  const _IuxOnboardingHeading({
    required this.focusNode,
    required this.position,
    required this.title,
    required this.body,
  });

  /// The node focus is moved to when the step changes.
  final FocusNode focusNode;

  /// Where the user is, in the caller's words.
  final String position;

  /// What this step is called, in the caller's words.
  final String title;

  /// What this step says, in the caller's words.
  final String body;

  /// What a screen reader says when focus arrives here.
  ///
  /// Joined with a full stop, which is a pause between three of the caller's
  /// own sentences rather than a sentence of IUX's own — the same trade
  /// `IuxValidationSummary` and `IuxGuidedForm` already make, and which
  /// `test/accessibility/no_composed_strings_test.dart` argues for at length:
  /// a text-to-speech engine reads the stop as prosody rather than as
  /// orthography, and the same pause is wanted in every language.
  ///
  /// **This is the third such site, and that test's preamble still says there
  /// are two.** The count is stale rather than the rule: the trade is
  /// identical, the test passes because a separator made only of punctuation
  /// carries no word to ship untranslated, and IUX-036 does not own
  /// `test/accessibility/`. Whoever next edits that file should say three.
  String get _spoken => <String>[position, title, body].join('. ');

  @override
  Widget build(BuildContext context) {
    final IuxTypographyTheme type = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);

    return IuxFocusable(
      focusNode: focusNode,
      child: Semantics(
        // Not a container, so this annotation merges into the node the focus
        // produced. One node carries "focusable, focused, heading, 2 of 4.
        // Set a budget. We will tell you when you are close to it." — which is
        // what makes arriving here an announcement rather than silence. Split
        // across two nodes, focus would land on the unnamed one.
        //
        // A heading as well as a destination, so a screen-reader user moving by
        // heading can reach the top of the step without walking back through
        // whatever the step is showing.
        header: true,
        label: _spoken,
        child: IuxSemantics.decorative(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // The position first, in the supporting style. It is the
              // smallest thing on the heading and the one a user weighing
              // whether to stay looks for; putting it under the title would
              // make them read the title to find it.
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
              const IuxGap.tight(),
              Text(
                body,
                // The substance rather than a caption, so it takes the primary
                // content role: the sentence that has to earn the screen, set
                // in the secondary colour, reads as small print.
                //
                // No line limit and no ellipsis, at any text size. Half a
                // reason is a reason the user cannot weigh, and truncation gets
                // worse exactly when someone has enlarged their text because
                // they were struggling to read.
                style: type.body.copyWith(color: colors.content.primary),
                softWrap: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
