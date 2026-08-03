import 'package:flutter/material.dart';

import '../../accessibility/iux_accessibility.dart';
import '../../accessibility/iux_semantics.dart';
import '../../actions/iux_action_descriptor.dart';
import '../../actions/iux_action_model.dart';
import '../../actions/iux_async_action.dart';
import '../../feedback/iux_feedback_controller.dart';
import '../../feedback/iux_feedback_event.dart';
import '../../layout/iux_spacing_primitives.dart';
import '../../semantics/iux_semantic_colors.dart';
import '../../themes/extensions/iux_button_theme.dart';
import '../../themes/extensions/iux_geometry_theme.dart';
import '../../themes/extensions/iux_typography_theme.dart';
import 'iux_button.dart';

/// A button for an action that takes time.
///
/// ```dart
/// IuxAsyncActionButton(
///   controller: controller,
///   label: l10n.pay,
///   busyLabel: l10n.payment_inProgress,
/// )
/// ```
///
/// **Use it** when activating something starts work the user has to wait for:
/// a payment, a save over the network, an export.
///
/// **Do not use it** for work that finishes within a frame — the label would
/// flicker and say less than nothing — or when several controls share one
/// operation, where the busy state belongs to the region rather than to any
/// one button.
///
/// ## It does not own the outcome
///
/// The operation lives on an [IuxAsyncActionController] the *parent* creates
/// and disposes, and that operation returns an [IuxAsyncOutcome] saying what
/// happened. This widget renders that answer; it never derives one. There is
/// no `onPressed: () async { ... }` here, and there will not be: a completed
/// future means a function returned, not that a payment went through.
///
/// ## There is no spinner
///
/// A spinner is motion, and under `IuxMotionPreference.none` a component must
/// express a change without any — `IuxResolvedMotion.requiresStaticAlternative`
/// is true there. A spinner-only busy state would leave those users with a
/// colour change and nothing else, and colour alone is not perceivable by
/// everyone either. So the busy state is a *word*: [busyLabel] replaces
/// [label] while the operation runs. That works at every motion preference, is
/// read out by a screen reader, survives a 200% text scale, and needs no
/// animation to be understood.
///
/// Only the caller can supply that word, which is why it is required rather
/// than defaulted — the framework composes no user-facing text.
///
/// ## States
///
/// | State | Source |
/// | --- | --- |
/// | idle, in progress, succeeded, failed | the controller, from the operation |
/// | disabled | `controller.action.availability` |
/// | pressed, hovered, focused | internal to the button |
///
/// A failure that carries a message shows it beneath the control, so the error
/// is never signalled by colour alone. A failure raised as an exception has no
/// message — see [IuxAsyncFailure.raised] — and the parent is expected to map
/// it to wording rather than show the user a stack trace.
class IuxAsyncActionButton extends StatefulWidget {
  /// Creates a button for an asynchronous action.
  const IuxAsyncActionButton({
    super.key,
    required this.controller,
    required this.label,
    required this.busyLabel,
    this.cancelLabel,
    this.icon,
    this.variant,
    this.autofocus = false,
    this.focusNode,
    this.expand = false,
  })  : assert(
          label.length > 0,
          'A button must show something. An empty label leaves a container a '
          'sighted user can see but cannot identify.',
        ),
        assert(
          busyLabel.length > 0,
          'A running button needs a word. Under a no-motion preference there '
          'is no spinner to fall back on, and a colour change alone is not '
          'perceivable by everyone — the label is the only signal left. Pass '
          'the localised equivalent of "Saving...".',
        ),
        assert(
          !(expand && cancelLabel != null),
          'A full-width button cannot share its row with a cancel control: '
          'expand asks for all the width there is, leaving none for the '
          'second control. Drop expand, or place the cancel affordance in '
          'your own layout and drive it with controller.requestCancellation.',
        );

  /// The parent-owned lifecycle of this action.
  ///
  /// Created and disposed by the parent, exactly like a `TextEditingController`.
  /// The widget listens to it and renders what it reports.
  final IuxAsyncActionController controller;

  /// The visible text when the action is not running.
  ///
  /// Already localised. The *announced* name comes from
  /// `controller.action.semantics.label`, which may differ: a button can read
  /// "Pay" while announcing "Pay the March invoice".
  final String label;

  /// The visible text while the action runs.
  ///
  /// Already localised, and phrased as something happening — "Saving…", not
  /// "Save". It is the busy state's only non-colour, motion-free carrier, so
  /// a label that reads the same as [label] would leave the user unable to
  /// tell whether their tap registered.
  final String busyLabel;

  /// The visible text of the control that stops the action, or null for none.
  ///
  /// Required in practice when `controller.action.cancellation` is
  /// [IuxActionCancellation.required], and refused when it is
  /// [IuxActionCancellation.notSupported] — both are asserted, because a
  /// promise of an exit with no exit is worse than no promise.
  ///
  /// The cancel control is a *separate* button placed beside the running one.
  /// Turning the primary button into "Cancel" under the user's finger would
  /// make a second tap cancel the very thing they were confirming.
  final String? cancelLabel;

  /// A glyph shown before the label, in reading order.
  ///
  /// Must be redundant with the label: it is excluded from the semantic tree,
  /// so anything it alone carries is information a screen-reader user never
  /// receives.
  final IconData? icon;

  /// How much visual weight to carry. Defaults to the theme's variant.
  final IuxButtonVariant? variant;

  /// Whether this takes focus when first built.
  final bool autofocus;

  /// An externally owned focus node.
  final FocusNode? focusNode;

  /// Whether the button fills the available width.
  ///
  /// Incompatible with [cancelLabel]; see the assertion on the constructor.
  final bool expand;

  @override
  State<IuxAsyncActionButton> createState() => _IuxAsyncActionButtonState();
}

class _IuxAsyncActionButtonState extends State<IuxAsyncActionButton> {
  IuxFeedbackController? _feedback;

  /// The last run this widget has already delivered feedback for.
  ///
  /// Captured eagerly when the controller is attached, never read lazily: a
  /// value first computed at the moment a result arrives would always equal
  /// that result's own run, and the event would be dropped as already
  /// reported.
  late int _reportedGeneration;

  @override
  void initState() {
    super.initState();
    _reportedGeneration = widget.controller.value.generation;
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Resolved here rather than in the listener: an inherited widget is looked
    // up during a build or a dependency change, never from inside a
    // notification that may arrive mid-frame.
    _feedback = IuxFeedbackScope.maybeOf(context);
  }

  @override
  void didUpdateWidget(covariant IuxAsyncActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_handleControllerChanged);
    widget.controller.addListener(_handleControllerChanged);
    // A new controller brings its own history. Reporting its last completion
    // again would vibrate for something that happened before this widget was
    // pointed at it.
    _reportedGeneration = widget.controller.value.generation;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  /// Relays the event the finished operation asked for, exactly once.
  ///
  /// The widget composes nothing and decides nothing: if the operation
  /// returned an outcome with no event, nothing is emitted. The generation
  /// guard is what keeps a rebuild from re-announcing a result the user
  /// already received.
  void _handleControllerChanged() {
    final IuxAsyncActionState state = widget.controller.value;
    final IuxFeedbackEvent? event = state.feedback;
    if (event == null || state.generation == _reportedGeneration) return;
    _reportedGeneration = state.generation;

    if (!mounted) return;
    assert(
      _feedback != null,
      'This operation returned a feedback event, but no IuxFeedbackScope '
      'encloses this button, so the event would be discarded and the user '
      'would be told nothing. Wrap your application in an IuxFeedbackScope.',
    );
    _feedback?.emit(context, event);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.controller,
        builder: (BuildContext context, Widget? child) => _build(context),
      );

  Widget _build(BuildContext context) {
    final IuxAsyncActionController controller = widget.controller;
    final IuxAsyncActionState state = controller.value;
    final IuxActionDescriptor descriptor = controller.descriptor;

    assert(
      descriptor.cancellation != IuxActionCancellation.required ||
          widget.cancelLabel != null,
      'This action declares IuxActionCancellation.required, meaning the user '
      'must be offered a way out — but no cancelLabel was given, so none '
      'would appear. Supply cancelLabel, or declare the cancellation merely '
      'supported if there is no obligation to offer it.',
    );
    assert(
      widget.cancelLabel == null ||
          descriptor.cancellation != IuxActionCancellation.notSupported,
      'A cancelLabel was given for an action declared '
      'IuxActionCancellation.notSupported, so the control would appear and '
      'then refuse to do anything — which reads as a broken interface. '
      'Declare the action supported or required, or drop cancelLabel.',
    );

    final Widget primary = IuxButton(
      label: state.isRunning ? widget.busyLabel : widget.label,
      // Also announced, because the accessible name comes from the descriptor
      // and does not change when the visible label does. Without this a
      // screen-reader user hears the resting name while the operation runs,
      // and silence is indistinguishable from a control that did nothing.
      busyHint: state.isRunning ? widget.busyLabel : null,
      action: descriptor,
      icon: widget.icon,
      variant: widget.variant,
      autofocus: widget.autofocus,
      focusNode: widget.focusNode,
      expand: widget.expand,
      // The controller decides whether this activation is accepted. The button
      // does not re-implement the rule, so the two cannot disagree about
      // whether a running action takes a second tap.
      onActivate: controller.activate,
    );

    final Widget control = _withCancelControl(primary, state);
    final IuxAsyncFailure? failure = state.failure;
    if (failure == null || !failure.isExplained) return control;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        control,
        const IuxGap.tight(),
        // Live, so the failure reaches a screen-reader user without their
        // having to go looking for it. When the outcome also carries a
        // feedback event, set allowAnnouncement: false on that event —
        // otherwise the same sentence is spoken twice.
        IuxSemantics.liveRegion(
          child: _IuxAsyncFailureMessage(message: failure.message!),
        ),
      ],
    );
  }

  Widget _withCancelControl(Widget primary, IuxAsyncActionState state) {
    final String? cancelLabel = widget.cancelLabel;
    if (cancelLabel == null || !state.isRunning) return primary;

    return IuxTargetSpacing(
      axis: Axis.horizontal,
      children: <Widget>[
        primary,
        IuxButton(
          label: cancelLabel,
          variant: IuxButtonVariant.outlined,
          action: IuxActionDescriptor(
            semantics: IuxActionSemantics(label: cancelLabel),
            role: IuxActionRole.cancel,
          ),
          // Stays enabled after a request has been sent. Disabling it would
          // need a reason to announce, and the framework has no localised
          // sentence to announce; a repeated request is harmless.
          onActivate: widget.controller.requestCancellation,
        ),
      ],
    );
  }
}

/// The failure message shown under a failed action.
///
/// Drawn on the error role's own surface, which is the pairing the theme
/// measures for contrast: `feedback.error.content` is guaranteed against
/// `feedback.error.surface`, not against the page. Carries an icon as well as
/// the wording, so the category survives both a colour vision deficiency and a
/// monochrome display.
class _IuxAsyncFailureMessage extends StatelessWidget {
  const _IuxAsyncFailureMessage({required this.message});

  /// The fallback mark size, used only if a theme supplies text with no size.
  static const double _markSize = 14;

  final String message;

  @override
  Widget build(BuildContext context) {
    final IuxSemanticColors colors = IuxSemanticColors.of(context);
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme typography = IuxTypographyTheme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.feedback.error.surface,
        borderRadius: BorderRadius.circular(geometry.radiusSubtle),
        border: Border.all(
          color: colors.feedback.error.border,
          width: geometry.borderWidth,
        ),
      ),
      child: Padding(
        padding: IuxInsets.compact(context),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            IuxSemantics.decorative(
              child: Icon(
                Icons.error_outline,
                // Scaled through the runtime the rest of the library reads, so
                // the mark grows with the sentence beside it instead of
                // shrinking into a dot for a user who enlarged their text.
                size: IuxAccessibility.of(context)
                    .scaleText(typography.supporting.fontSize ?? _markSize),
                color: colors.feedback.error.icon,
                applyTextScaling: false,
              ),
            ),
            SizedBox(width: geometry.spacingXs),
            // Flexible rather than fixed: the message is a sentence, and a
            // sentence that cannot wrap is a sentence that gets clipped
            // exactly when someone has enlarged their text.
            Flexible(
              child: Text(
                message,
                style: typography.supporting
                    .copyWith(color: colors.feedback.error.content),
                softWrap: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
