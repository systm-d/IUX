import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../accessibility/iux_focus.dart';
import '../../accessibility/iux_semantics.dart';
import '../../actions/iux_action_descriptor.dart';
import '../../actions/iux_action_model.dart';
import '../../layout/iux_content_width.dart';
import '../../layout/iux_spacing_primitives.dart';
import '../../layout/iux_surface.dart';
import '../../motion/iux_motion_policy.dart';
import '../../motion/iux_motion_role.dart';
import '../../semantics/iux_semantic_colors.dart';
import '../../themes/extensions/iux_geometry_theme.dart';
import '../../themes/extensions/iux_typography_theme.dart';
import '../button/iux_button.dart';

/// How much of the content behind the dialog the scrim covers.
///
/// Enough that the page behind stops competing for attention, not so much that
/// the user loses the context they were in — a dialog that asks "delete this?"
/// is unanswerable when "this" has been blacked out.
const double _kScrimOpacity = 0.6;

/// One of the choices a dialog offers, other than the way out.
///
/// It carries a callback rather than a result value because the parent already
/// knows which choice it offered. Returning a value would mean the dialog
/// decides what "confirmed" means, and it cannot: only the caller knows what
/// is being confirmed.
@immutable
final class IuxDialogAction {
  /// Describes one choice.
  const IuxDialogAction({
    required this.label,
    required this.action,
    required this.onActivate,
  }) : assert(
          label.length > 0,
          'A dialog choice must show something. An unlabelled button in a '
          'dialog is a decision the user cannot make.',
        );

  /// The visible text, already localised.
  final String label;

  /// What the choice is, and whether it may currently be taken.
  ///
  /// Kept as a full [IuxActionDescriptor] rather than a colour or an enum so
  /// the same action can be disabled, named for a screen reader, and marked
  /// irreversible in one object — and so a dialog button behaves exactly like
  /// the same action anywhere else in the application.
  final IuxActionDescriptor action;

  /// Called once when the user takes this choice.
  ///
  /// The dialog does not close itself afterwards. Closing is a state change,
  /// the parent owns the state, and a dialog that closed itself would leave
  /// the parent's flag saying it was still open.
  final VoidCallback onActivate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxDialogAction &&
          other.label == label &&
          other.action == action &&
          other.onActivate == onActivate;

  @override
  int get hashCode => Object.hash(label, action, onActivate);

  @override
  String toString() => 'IuxDialogAction($label)';
}

/// A modal decision: the interface stops, states one thing, and waits.
///
/// ```dart
/// IuxDialog(
///   title: 'Delete this invoice?',
///   message: 'The invoice and its attachments are removed permanently.',
///   dismissLabel: 'Keep it',
///   onDismiss: controller.closeDialog,
///   actions: <IuxDialogAction>[
///     IuxDialogAction(
///       label: 'Delete',
///       action: const IuxActionDescriptor.destructive(
///         semantics: IuxActionSemantics(label: 'Delete the March invoice'),
///         confirmation: IuxConfirmationPolicy.none,
///       ),
///       onActivate: controller.confirmDelete,
///     ),
///   ],
/// )
/// ```
///
/// **Use it** when the user cannot continue without answering, and the answer
/// changes what happens next: a consequence that cannot be undone, a conflict
/// only they can resolve, a permission that must be granted before the feature
/// can run at all.
///
/// **Do not use it** for:
///
/// - **Information the page could show inline.** A dialog costs the user their
///   place in the task. A message that could sit under the field it concerns
///   should sit there, where it stays readable while they act on it.
/// - **Confirming something trivially reversible.** Confirming every delete
///   trains users to dismiss confirmations without reading them, which is how
///   the one that mattered gets dismissed too. An undo is almost always kinder
///   than a confirmation.
/// - **A form.** A dialog that hosts fields is a page in a box, and a page in a
///   box is exactly what stops fitting at 200% text on a small screen — with a
///   keyboard covering half of what is left.
/// - **Anything the user did not ask for.** An interruption the user did not
///   cause is an interruption they will dismiss reflexively.
///
/// **This widget does not navigate.** It is a layer the parent places, not a
/// route it pushes: a component that pushed a route would decide navigation,
/// which belongs to the application. Place it with `IuxModalLayer`, and remove
/// it from the tree to close it. One consequence is that the Android back
/// button does not reach it — see `docs/components/dialog.md` for the
/// two-line `PopScope` the parent adds.
///
/// **Dismissal is guaranteed and unambiguous.** [onDismiss] is required, and
/// the scrim, the Escape key and the visible dismissal button all call it. No
/// flag turns one of them off: a dialog whose scrim silently ignores taps is
/// indistinguishable from one that is broken, and a dialog with no visible way
/// out is a trap.
///
/// **Accessibility.** The dialog scopes and names a route, so assistive
/// technology announces the change of context instead of leaving the user to
/// discover it. It blocks the semantics of the page behind it, traps keyboard
/// focus, and returns focus on close to whatever held it before — without
/// that, every dialog drops a keyboard or screen-reader user back at the top
/// of the page.
class IuxDialog extends StatefulWidget {
  /// Creates a modal decision.
  const IuxDialog({
    super.key,
    required this.title,
    required this.message,
    required this.dismissLabel,
    required this.onDismiss,
    this.actions = const <IuxDialogAction>[],
    this.content,
  })  : assert(
          title.length > 0,
          'A dialog must have a title. The title is what assistive technology '
          'announces when the dialog appears, so an empty one leaves a screen '
          'reader user interrupted with no idea by what.',
        ),
        assert(
          message.length > 0,
          'A dialog must say what it is asking. A title alone states a topic, '
          'not a consequence, and a user cannot consent to a consequence they '
          'were never told.',
        ),
        assert(
          dismissLabel.length > 0,
          'The way out must be labelled. An unlabelled dismissal is a control '
          'a screen-reader user cannot find and a sighted user will not trust.',
        ),
        assert(
          actions.length <= 2,
          'A dialog is a decision, not a menu. Three or more choices beside '
          'the dismissal is a list, and a list belongs on a page or in a sheet '
          'where it can be read at leisure.',
        );

  /// What the dialog is about, in the user's language.
  ///
  /// Also the route name announced on open, which is why it is required: it is
  /// the only thing a screen-reader user hears before the interruption.
  ///
  /// Phrase it as the question or the consequence ("Delete this invoice?"),
  /// never as a category ("Warning"). A category tells the user a dialog
  /// appeared; it does not tell them what it wants.
  final String title;

  /// The consequence, stated plainly.
  ///
  /// Required. A user cannot weigh a decision whose outcome was never
  /// described, and "Are you sure?" describes nothing.
  final String message;

  /// The visible text of the way out.
  ///
  /// Name the outcome rather than the mechanism: "Keep the invoice" tells the
  /// user what happens, "Cancel" makes them work out which of two things it
  /// cancels.
  final String dismissLabel;

  /// Called when the user leaves without choosing.
  ///
  /// The same callback for the scrim, for Escape and for the dismissal button,
  /// so the three cannot drift into meaning different things. The parent
  /// removes the dialog from the tree in response; this widget does not close
  /// itself.
  final VoidCallback onDismiss;

  /// The choices offered beside the dismissal. At most two.
  ///
  /// May be empty, which produces an acknowledgement: one button, whose label
  /// is [dismissLabel].
  final List<IuxDialogAction> actions;

  /// Detail shown under [message], such as the list of items affected.
  ///
  /// Not a place for a form. Anything the user has to fill in belongs on a
  /// page: the dialog scrolls, but a keyboard over a scrolling dialog on a
  /// small screen leaves a viewport a few lines tall.
  final Widget? content;

  @override
  State<IuxDialog> createState() => _IuxDialogState();
}

class _IuxDialogState extends State<IuxDialog>
    with SingleTickerProviderStateMixin {
  /// Confines keyboard traversal to the dialog.
  ///
  /// Tab and arrow traversal cycle within the nearest enclosing scope, so
  /// declaring one here is what stops the user tabbing into the page they were
  /// just told they cannot use.
  final FocusScopeNode _scope = FocusScopeNode(debugLabel: 'IuxDialog');

  /// Where focus lands when the dialog opens.
  ///
  /// The panel itself, deliberately, and never a button. A dialog that focuses
  /// its confirming action turns the Enter key the user was already pressing
  /// into a confirmation they never read.
  final FocusNode _panel = FocusNode(debugLabel: 'IuxDialog panel');

  /// Whatever held focus when the dialog opened.
  FocusNode? _restoreTo;

  AnimationController? _entrance;
  bool _entranceStarted = false;

  @override
  void initState() {
    super.initState();
    // Captured before anything in the dialog can take focus. By the time the
    // first frame is drawn the answer is already gone.
    _restoreTo = IuxFocus.current(context);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // A dialog appearing answers "where did this come from", so it is an
    // entrance rather than decoration. A fade and nothing else: travel across
    // the screen is a known vestibular trigger, and this transition carries no
    // information that movement would add.
    final IuxResolvedMotion motion = IuxMotionPolicy.resolve(
      context,
      role: IuxMotionRole.enter,
    );

    final AnimationController controller =
        _entrance ??= AnimationController(vsync: this, duration: Duration.zero);

    if (_entranceStarted) return;
    _entranceStarted = true;

    if (motion.isAnimated) {
      controller.duration = motion.duration;
      controller.forward();
    } else {
      // Set rather than animated to zero: an animation that "runs" for no time
      // still leaves the first frame at zero opacity, and a dialog invisible
      // for one frame is a dialog that flickers for the user who asked for no
      // motion at all.
      controller.value = 1;
    }

    // Focus is moved after the first frame, once the nodes below exist to
    // receive it. Requested explicitly rather than left to autofocus, because
    // autofocus yields to whatever already held focus — which is precisely the
    // widget on the page the dialog has just blocked.
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (!mounted) return;
      IuxFocus.request(_panel);
    });
  }

  @override
  void dispose() {
    final FocusNode? restoreTo = _restoreTo;
    _entrance?.dispose();
    _panel.dispose();
    _scope.dispose();

    // Restored at the end of the frame that removed the dialog, once the nodes
    // it owned are gone. Restoring during dispose would hand focus to a node
    // the framework is about to take it back from.
    WidgetsBinding.instance.addPostFrameCallback(
      (Duration _) => IuxFocus.restore(restoreTo),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final IuxSemanticColors colors = IuxSemanticColors.of(context);
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);

    final Widget layer = Stack(
      fit: StackFit.expand,
      children: <Widget>[
        _scrim(colors),
        _panelLayer(context, geometry),
      ],
    );

    return BlockSemantics(
      // Everything painted before this — the page the dialog covers — leaves
      // the semantic tree while the dialog is up. Without it a screen-reader
      // user can still swipe into content that no longer responds to them, and
      // a control that reads out but does nothing is worse than one that is
      // gone.
      child: IuxSemantics.route(
        // Scoped and named through the runtime helper, so the dialog cannot
        // drift from whatever the next modal layer does. The helper keeps the
        // subtree's own nodes, which is what leaves the dismissal and the
        // choices individually reachable.
        label: widget.title,
        child: FocusScope(
          node: _scope,
          child: Shortcuts(
            // Declared here rather than relying on the ambient application's
            // shortcuts, so Escape means the same thing whatever the dialog is
            // embedded in.
            shortcuts: const <ShortcutActivator, Intent>{
              SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
            },
            child: Actions(
              actions: <Type, Action<Intent>>{
                DismissIntent: CallbackAction<DismissIntent>(
                  onInvoke: (DismissIntent intent) {
                    widget.onDismiss();
                    return null;
                  },
                ),
              },
              // The panel holds focus but is not a control: it registers no
              // keyboard activation of its own, so Enter pressed on a dialog
              // the user has not read yet does nothing rather than something.
              child: Focus(
                focusNode: _panel,
                child: FadeTransition(
                  opacity: _entrance!,
                  child: SizedBox.expand(child: layer),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The dimmed area outside the dialog, which is also a way out.
  Widget _scrim(IuxSemanticColors colors) {
    return ExcludeSemantics(
      // Excluded rather than labelled: the dismissal button says the same
      // thing in words, and a second, invisible "dismiss" target reachable
      // only by swiping is a control a user cannot verify before activating.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onDismiss,
        child: ColoredBox(color: _scrimColor(colors)),
      ),
    );
  }

  /// The colour of the scrim.
  ///
  /// IUX has no scrim role, so it is derived: whichever of the two surface
  /// extremes the theme resolved darker, at a fixed opacity. Picking by
  /// measured luminance rather than by brightness means a scrim never
  /// *brightens* what it covers, which is what a fixed "inverse surface" would
  /// do in dark conditions — raising the background's luminance and pushing it
  /// closer to the dialog it is supposed to sit behind.
  Color _scrimColor(IuxSemanticColors colors) {
    final Color base = colors.surface.base;
    final Color inverse = colors.surface.inverse;
    final Color darker =
        base.computeLuminance() <= inverse.computeLuminance() ? base : inverse;
    return darker.withValues(alpha: _kScrimOpacity);
  }

  /// The dialog panel, centred over the scrim.
  Widget _panelLayer(BuildContext context, IuxGeometryTheme geometry) {
    return SafeArea(
      // The dialog is a sibling of the page, not content inside it, so it
      // consumes the system insets itself. Placing it inside IuxPage instead
      // would inset it twice from a notch that is only there once.
      child: Padding(
        padding: EdgeInsets.all(geometry.spacingLg),
        child: IuxReadableWidth(
          // Capped in characters rather than pixels, so enlarging text widens
          // the dialog instead of squeezing the same words into a narrower
          // column.
          width: IuxContentWidth.reading,
          alignment: Alignment.center,
          child: GestureDetector(
            // Opaque, with no callback: a tap that lands on the panel's own
            // padding is not a dismissal, and without this it would fall
            // through to the scrim and close the dialog the user was reading.
            behavior: HitTestBehavior.opaque,
            child: IuxSurface(
              role: IuxSurfaceRole.overlay,
              shape: IuxSurfaceShape.prominent,
              // Bordered as well as elevated. Elevation is resolved to zero
              // under a reduced visual stimulation preference, and the edge of
              // a dialog is not something that may quietly disappear.
              bordered: true,
              elevated: true,
              child: _content(context),
            ),
          ),
        ),
      ),
    );
  }

  /// Title, message, detail and choices — all inside one scroll view.
  ///
  /// Everything scrolls, including the buttons. Pinning the actions looks
  /// tidier until 200% text on a small screen, where the pinned row and the
  /// title together leave no room for the message; content that cannot be
  /// reached is content the user cannot consent to.
  Widget _content(BuildContext context) {
    final IuxTypographyTheme typography = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);
    final Widget? detail = widget.content;

    return SingleChildScrollView(
      child: Padding(
        padding: IuxInsets.surface(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IuxSemantics.header(
              label: widget.title,
              child: Text(
                widget.title,
                // No line limit and no ellipsis anywhere in this column. A
                // truncated consequence is a consequence the user was not
                // told, and truncation gets worse exactly when someone has
                // enlarged their text.
                style: typography.title.copyWith(color: colors.content.primary),
              ),
            ),
            const IuxGap.standard(),
            Text(
              widget.message,
              style: typography.body.copyWith(color: colors.content.primary),
            ),
            if (detail != null) ...<Widget>[
              const IuxGap.standard(),
              detail,
            ],
            const IuxGap.between(),
            _choices(),
          ],
        ),
      ),
    );
  }

  /// The dismissal, then the choices, in reading order.
  ///
  /// The way out comes first so it is the first control reached by keyboard,
  /// by D-pad and by a screen reader swipe. Laid out with [IuxTargetSpacing],
  /// which wraps to a second line rather than overflowing: at a large text
  /// scale two buttons stop fitting side by side, and stacking is the only
  /// outcome in which both stay usable.
  Widget _choices() {
    return IuxTargetSpacing(
      axis: Axis.horizontal,
      children: <Widget>[
        IuxButton(
          label: widget.dismissLabel,
          action: IuxActionDescriptor(
            semantics: IuxActionSemantics(label: widget.dismissLabel),
            // Dismiss, not cancel: leaving a dialog closes it without
            // discarding anything the user typed. Announcing it as a
            // cancellation would suggest work is being thrown away.
            role: IuxActionRole.dismiss,
          ),
          onActivate: widget.onDismiss,
        ),
        for (final IuxDialogAction choice in widget.actions)
          IuxButton(
            label: choice.label,
            action: choice.action,
            onActivate: choice.onActivate,
          ),
      ],
    );
  }
}
