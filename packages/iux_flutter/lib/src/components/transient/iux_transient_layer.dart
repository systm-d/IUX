import 'dart:async';

import 'package:flutter/material.dart';

import '../../accessibility/iux_focus.dart';
import '../../accessibility/iux_semantics.dart';
import '../../accessibility/iux_touch_target.dart';
import '../../layout/iux_content_width.dart';
import '../../layout/iux_spacing_primitives.dart';
import '../../motion/iux_motion_policy.dart';
import '../../themes/extensions/iux_geometry_theme.dart';
import 'iux_transient_message.dart';
import 'iux_transient_timing.dart';
import 'iux_transient_tokens.dart';

/// Why a non-positive floor is refused.
const String _kNonPositiveDwell =
    'minimumDwell raises the floor on how long a message stays. Zero or a '
    'negative value asks for a message that leaves before it can be read, '
    'which is what this parameter exists to prevent. Omit it instead.';

/// Places at most one transient message over a page.
///
/// ```dart
/// Scaffold(
///   body: IuxTransientLayer(
///     message: state.notice,          // an IuxTransientMessage, or null
///     onDismissed: controller.clearNotice,
///     child: IuxPage(child: content),
///   ),
/// )
/// ```
///
/// **Where it goes when the application has navigation.** Inside it, always —
/// this layer wraps the *page*, never the frame. See
/// [debugCheckNotPlacedOver], which refuses the other arrangement, and
/// `docs/components/transient-feedback.md` for the measurement that put the
/// check there.
///
/// ```dart
/// IuxModalLayer(                       // outside: a dialog covers navigation
///   dialog: state.dialog,
///   child: IuxAdaptiveNavigation(
///     label: l10n.mainNavigation,
///     selectedIndex: section.index,
///     destinations: destinations,
///     onDestinationSelected: controller.goTo,
///     child: IuxTransientLayer(        // inside: a notice must not
///       message: state.notice,
///       onDismissed: controller.clearNotice,
///       child: IuxPage(child: body),
///     ),
///   ),
/// )
/// ```
///
/// This is what other libraries call a snack bar or a toast. IUX names it for
/// the property that decides whether you may use it — that it disappears —
/// rather than for its shape, because the shape is not what goes wrong.
///
/// **Read `IuxTransientMessage` before using this.** The single rule that
/// shaped every decision here: nothing the user needs may be put in this
/// channel. A message that leaves on a timer is lost by the slow reader, by
/// the screen-reader user who was midway through another sentence, and by
/// anyone who looked away — and none of them is told that anything left.
///
/// **Why a layer rather than a route or a messenger.** A component that pushed
/// a route, or reached for `ScaffoldMessenger`, would be deciding navigation
/// and owning application state. Here the parent owns a nullable value, the
/// message exists exactly while that value is non-null, and it cannot be left
/// on screen by a code path that forgot to pop. It is the same arrangement as
/// `IuxModalLayer`, for the same reason.
///
/// **There is no queue, and [message] is a single value rather than a list.**
/// A second message replaces the first, and the first is destroyed —
/// immediately, possibly before it was read. That is a real loss and it is
/// chosen deliberately:
///
/// - A queue makes the newest fact wait behind a stale one, and in this
///   channel the newest is the only one still likely to be true.
/// - A queue multiplies the total time the bottom of the screen is occupied,
///   and multiplies the number of things a user is expected to catch.
/// - Refusing the second message is worse than either: it keeps the stale one.
///
/// Replacement is only defensible because of what this component refuses to
/// carry. The information destroyed is, by construction, information nobody
/// needed. A parent that finds itself wanting a queue has content that is not
/// disposable, and that content belongs in an `IuxAlert` where it can be
/// stacked, read, and re-read.
///
/// **It never takes focus.** Moving focus to a message that is about to vanish
/// strands the keyboard user it moved. Both controls are reachable by tabbing,
/// and reaching either one stops the clock — so the message cannot disappear
/// out from under someone who is on it.
///
/// **It does not block the page.** Unlike a dialog, it declares no route, traps
/// no focus and blocks no semantics: the page behind stays readable, operable,
/// and last in the reading order it already had.
class IuxTransientLayer extends StatelessWidget {
  /// Places [message], when there is one, over [child].
  const IuxTransientLayer({
    super.key,
    required this.child,
    required this.onDismissed,
    this.message,
    this.minimumDwell,
  }) : assert(
          minimumDwell == null || minimumDwell > Duration.zero,
          _kNonPositiveDwell,
        );

  /// The page the message floats over.
  final Widget child;

  /// The message currently shown, or null when none is.
  ///
  /// Typed as [IuxTransientMessage] rather than as a `Widget`: the slot exists
  /// to hold something that owns no layout space and removes itself from the
  /// bottom of the screen, and an arbitrary widget dropped in here would do
  /// neither while looking identical from the call site.
  final IuxTransientMessage? message;

  /// Called when the message should stop being shown.
  ///
  /// Required. A layer whose parent ignored this would leave every message on
  /// screen forever, and the component will not remove itself — the parent
  /// owns the state, so the parent sets [message] to null in response.
  ///
  /// It carries no reason. The two causes are the clock expiring and the user
  /// dismissing, and they can only differ for a message that expires — which is
  /// a message whose content is disposable by construction. A parent that would
  /// act differently on the two is acting on something it should not have put
  /// here.
  final VoidCallback onDismissed;

  /// Raises the floor on how long a message stays. Never lowers it.
  ///
  /// The hook for an application that offers its users a "give me more time"
  /// setting, which is the adjustment WCAG 2.2 SC 2.2.1 asks for and which IUX
  /// cannot offer on its own because it has no settings surface. Values below
  /// the reading time derived from the message are ignored, and there is
  /// deliberately no parameter anywhere that can shorten a dwell.
  final Duration? minimumDwell;

  /// Refuses a component this layer would pin a message over.
  ///
  /// Call it from `build`, and only inside an `assert`:
  ///
  /// ```dart
  /// @override
  /// Widget build(BuildContext context) {
  ///   assert(IuxTransientLayer.debugCheckNotPlacedOver(context));
  ///   // …
  /// }
  /// ```
  ///
  /// Returns true when no [IuxTransientLayer] frames [context], and throws a
  /// [FlutterError] naming `context.widget.runtimeType` when one does — which is
  /// why it belongs in `build` rather than in a builder callback, where it would
  /// name the builder. The whole body is inside an assertion, so a release build
  /// carries none of it; the ancestor walk is O(depth) and runs once per build
  /// of the component that asks.
  ///
  /// **What it is for.** This layer pins its message to the bottom edge of
  /// whatever it wraps and reserves no layout space for it. That is the
  /// contract, and it is safe over a page. It is not safe over a *frame*: a
  /// bottom navigation bar sits at the same edge, so a layer wrapped around the
  /// navigation puts every notice on top of the destinations and takes the
  /// user's ability to change section away for the length of the dwell. The
  /// dwell is at least four seconds and there is deliberately no parameter that
  /// can shorten it — see `IuxTransientTiming` — which turns what looks like a
  /// cosmetic overlap into a failure of WCAG 2.2 SC 2.2.1.
  ///
  /// IUX-041 measured it on a 360 × 800 window with the layer wrapped around
  /// `IuxAdaptiveNavigation`: the notice occupied y 712–760, the three
  /// destinations sat at y 740–786, and all three reported `hitTestable = 0`.
  /// Neither component was wrong on its own. Only the arrangement was, and
  /// nothing said so — which is why this is a thrown error rather than another
  /// paragraph in a document.
  ///
  /// **Why ancestry is almost the whole test.** A message is painted over
  /// exactly the subtree this layer wraps, so a navigation component that is a
  /// descendant is one a message can land on and one that is not, is not.
  ///
  /// **And why a scroll view ends the walk.** A notice is pinned to the bottom
  /// of the *viewport*; content inside a scroll view moves past that edge and is
  /// not at it. Navigation never scrolls — `docs/components/navigation-rail.md`
  /// and `docs/components/bottom-navigation.md` both say to put it in
  /// `Scaffold.body` and not in a scroll view — so a navigation component found
  /// on the far side of one is not acting as navigation. It is a specimen: a
  /// component gallery, a design-system page, a screenshot harness. IUX ships
  /// one of those in `apps/catalog`, where three of these components are
  /// rendered live inside a `ListView` under the catalog's own transient layer,
  /// and a notice drifting over a specimen costs a reader nothing. Refusing that
  /// would be refusing the library's own documentation of itself.
  ///
  /// The hole this leaves is an application that puts its real navigation inside
  /// a scroll view. That arrangement is already broken for a louder reason — an
  /// unbounded height makes `IuxAdaptiveNavigation` choose the bar without ever
  /// measuring the window — and buying a warning for it at the price of refusing
  /// every catalog in existence is the wrong trade.
  static bool debugCheckNotPlacedOver(BuildContext context) {
    assert(() {
      bool covered = false;
      context.visitAncestorElements((Element element) {
        final Widget widget = element.widget;
        // Content, not a frame: the walk stops before it can find a layer.
        if (widget is Scrollable) return false;
        if (widget is! IuxTransientLayer) return true;
        covered = true;
        return false;
      });
      if (!covered) return true;
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary(
          '${context.widget.runtimeType} is inside an IuxTransientLayer.',
        ),
        ErrorDescription(
          'The layer pins its message to the bottom edge of whatever it wraps '
          'and reserves no layout space for it, so every message it shows '
          'lands on top of the navigation and swallows the taps meant for it. '
          'Measured on a 360x800 window: the notice at y 712-760, the '
          'destinations at y 740-786, all of them hitTestable = 0. A dwell is '
          'at least four seconds and no parameter can shorten it, so this is a '
          'time limit on the ability to change section - WCAG 2.2 SC 2.2.1.',
        ),
        ErrorHint(
          'The transient layer goes inside the navigation and the modal layer '
          'stays outside it. A dialog must cover the navigation, because it is '
          'a question about the screen underneath; a notice must not, because '
          'it is not.\n'
          '\n'
          'IuxModalLayer(\n'
          '  dialog: state.dialog,\n'
          '  child: IuxAdaptiveNavigation(\n'
          '    ...,\n'
          '    child: IuxTransientLayer(\n'
          '      message: state.notice,\n'
          '      onDismissed: controller.clearNotice,\n'
          '      child: IuxPage(child: body),\n'
          '    ),\n'
          '  ),\n'
          ')',
        ),
      ]);
    }());
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final IuxTransientMessage? current = message;
    // The Stack exists whether or not a message does, and [child] keeps slot
    // zero either way. Collapsing to a bare child while nothing is shown would
    // save one render object and cost the page its element identity every time
    // a message appeared: the subtree would be rebuilt from scratch, taking
    // scroll offsets, keyboard focus and in-flight animations with it. That is
    // a spectacular price to pay for a notice nobody needed.
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        child,
        // Positioned rather than a second full-screen layer: the message
        // occupies the bottom strip and nothing else, so the rest of the page
        // stays tappable underneath it. A transient message that swallowed
        // taps across the whole screen would be an invisible modal.
        if (current != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _IuxTransientSurface(
              message: current,
              onDismissed: onDismissed,
              minimumDwell: minimumDwell,
            ),
          ),
      ],
    );
  }
}

/// The message itself: its clock, its entrance, and its two controls.
///
/// Private on purpose. Everything about it — that it sits at the bottom, that
/// it owns no layout space, that it announces itself once and never twice — is
/// only true because [IuxTransientLayer] is the one thing that places it.
class _IuxTransientSurface extends StatefulWidget {
  const _IuxTransientSurface({
    required this.message,
    required this.onDismissed,
    required this.minimumDwell,
  });

  final IuxTransientMessage message;
  final VoidCallback onDismissed;
  final Duration? minimumDwell;

  @override
  State<_IuxTransientSurface> createState() => _IuxTransientSurfaceState();
}

class _IuxTransientSurfaceState extends State<_IuxTransientSurface>
    with SingleTickerProviderStateMixin {
  /// The clock, or null when this message does not expire.
  Timer? _timer;

  AnimationController? _entrance;
  bool _started = false;

  /// Whether a pointer is resting on the message.
  bool _held = false;

  /// Whether a control inside the message holds focus.
  bool _focused = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _playEntrance();
      _restartClock();
      return;
    }
    // A preference may have changed under a message that is already up — a
    // screen reader switched on, for instance. The only change acted on here
    // is one that *removes* the deadline. Restarting the clock because the
    // keyboard appeared and changed the metrics would hand the user a fresh
    // countdown they did not ask for and cannot see.
    if (_resolveDwell() == null) _cancelClock();
  }

  @override
  void didUpdateWidget(covariant _IuxTransientSurface old) {
    super.didUpdateWidget(old);
    // The same message rebuilt is not news. Without this check a parent that
    // rebuilds every frame would restart the countdown every frame, and the
    // message would never leave.
    if (widget.message.saysTheSameAs(old.message)) return;
    // A replacement is a new message in the same place: it fades in again, so
    // a sighted user sees that something changed, and the live region label
    // changes, so a screen reader says the new sentence rather than nothing.
    _playEntrance();
    _restartClock();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _entrance?.dispose();
    super.dispose();
  }

  Duration? _resolveDwell() => IuxTransientTiming.resolve(
        context,
        widget.message,
        minimumDwell: widget.minimumDwell,
      );

  void _cancelClock() {
    _timer?.cancel();
    _timer = null;
  }

  /// Starts the clock from the beginning, unless something says it must not
  /// run at all.
  ///
  /// Restarting rather than resuming after an interruption is deliberate. A
  /// user who pressed the message, or tabbed onto it, and then let go has lost
  /// their place in the sentence; handing back the remaining three hundred
  /// milliseconds hands back nothing.
  void _restartClock() {
    _cancelClock();
    if (_held || _focused) return;
    final Duration? dwell = _resolveDwell();
    if (dwell == null) return;
    _timer = Timer(dwell, () {
      if (mounted) widget.onDismissed();
    });
  }

  void _playEntrance() {
    final IuxResolvedMotion motion =
        IuxTransientResolver.resolve(context, widget.message.tone).entrance;
    final AnimationController controller =
        _entrance ??= AnimationController(vsync: this, duration: Duration.zero);

    if (!motion.isAnimated) {
      // Set rather than animated over zero time: an animation that "runs" for
      // no time still leaves one frame at zero opacity, and a message that
      // flickers is worse than one that simply appears — especially for the
      // user who asked for no motion in the first place.
      controller.value = 1;
      return;
    }
    controller.duration = motion.duration;
    controller.forward(from: 0);
  }

  void _handleHold(bool held) {
    if (!mounted || _held == held) return;
    _held = held;
    _restartClock();
  }

  void _handleFocusChange(bool focused) {
    if (!mounted || _focused == focused) return;
    _focused = focused;
    _restartClock();
  }

  @override
  Widget build(BuildContext context) {
    final IuxTransientTokens tokens =
        IuxTransientResolver.resolve(context, widget.message.tone);

    return IuxSemantics.liveRegion(
      // The text alone, with no category word joined to it. An IuxAlert speaks
      // its category because the category is part of what the user is being
      // told; here there is nothing to add, and a message that needed a spoken
      // "Success" prefix to be understood would be a message that must not
      // disappear.
      label: widget.message.text,
      child: SafeArea(
        // Bottom insets only. The page consumes its own, and this is a sibling
        // of the page rather than content inside it, so neither insets the
        // other twice.
        top: false,
        child: Padding(
          padding: IuxInsets.page(context),
          child: IuxReadableWidth(
            // Capped in characters rather than pixels, so enlarging the text
            // widens the message instead of squeezing the same words into a
            // narrower column.
            width: IuxContentWidth.reading,
            alignment: Alignment.bottomCenter,
            child: FadeTransition(
              opacity: _entrance!,
              child: Focus(
                // Not focusable itself and skipped by traversal: this node
                // exists only to hear when a control *inside* the message
                // takes focus. Making it focusable would add a stop in the
                // traversal order that does nothing.
                canRequestFocus: false,
                skipTraversal: true,
                onFocusChange: _handleFocusChange,
                child: Listener(
                  // Opaque, so the whole message registers a press and so a
                  // tap meant for the message never falls through to whatever
                  // control happens to be underneath it.
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (PointerDownEvent _) => _handleHold(true),
                  onPointerUp: (PointerUpEvent _) => _handleHold(false),
                  onPointerCancel: (PointerCancelEvent _) => _handleHold(false),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: tokens.surface,
                      borderRadius: BorderRadius.circular(tokens.radius),
                      // Outlined and not elevated. A shadow is resolved to
                      // zero under a reduced visual stimulation preference,
                      // and the edge of something floating over arbitrary
                      // content is not a thing that may quietly disappear.
                      border: Border.all(
                        color: tokens.border,
                        width: tokens.borderWidth,
                      ),
                    ),
                    child: Padding(
                      padding: IuxInsets.surface(context),
                      child: _content(tokens),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The glyph, the sentence, the action, and the way out.
  ///
  /// The same arrangement as an inline message, deliberately: two comparable
  /// components that laid their controls out differently would teach the user
  /// two habits for one idea.
  Widget _content(IuxTransientTokens tokens) {
    final IuxTransientAction? action = widget.message.action;
    final IconData? glyph = tokens.glyph;

    return Row(
      // Top-aligned: the glyph belongs beside the first line, not floating in
      // the middle of a message that wrapped onto three.
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (glyph != null) ...<Widget>[
          // Excluded from the semantic tree. The tone carries no information,
          // so announcing it would make the user swipe past "image" to reach
          // a sentence that already said everything.
          IuxSemantics.decorative(
            child: Icon(
              glyph,
              size: tokens.iconSize,
              color: tokens.icon,
              // Scaled once, by the runtime every other IUX component reads.
              // Letting Flutter scale it again would grow the glyph twice as
              // fast as the text beside it.
              applyTextScaling: false,
            ),
          ),
          const IuxGap.horizontal(IuxSpacingStep.xs),
        ],
        // Expanded rather than Flexible: the sentence takes whatever the glyph
        // and the dismiss control leave, which is what keeps the dismiss
        // control on screen at 200% text on a small phone.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // The words are already the live region's label; left in the
              // tree as well they would be read a second time.
              IuxSemantics.decorative(
                child: Text(
                  widget.message.text,
                  // No line limit and no ellipsis at any text size. Half a
                  // sentence is not a shorter message, it is a different one.
                  style: tokens.messageStyle,
                ),
              ),
              if (action != null) ...<Widget>[
                const IuxGap.tight(),
                _IuxTransientActionControl(action: action, tokens: tokens),
              ],
            ],
          ),
        ),
        const IuxGap.horizontal(IuxSpacingStep.xs),
        _IuxTransientDismissControl(
          label: widget.message.dismissLabel,
          onDismiss: widget.onDismissed,
          tokens: tokens,
        ),
      ],
    );
  }
}

/// The action control.
///
/// Not an [IuxButton], for the same reason an inline message's control is not:
/// a button resolves its container against the *page* surface, so it would
/// paint a patch of page colour inside a tinted block and carry a label colour
/// measured against a background it is not on. Drawing it from the same
/// feedback role as the message keeps the pair the theme actually verified.
class _IuxTransientActionControl extends StatelessWidget {
  const _IuxTransientActionControl(
      {required this.action, required this.tokens});

  final IuxTransientAction action;
  final IuxTransientTokens tokens;

  @override
  Widget build(BuildContext context) => IuxSemantics.action(
        label: action.effectiveSemanticLabel,
        // Carried through so a screen-reader double-tap activates it. The
        // helper excludes the child's semantics in order to control the
        // announced name, and that removes the child's own tap action with it.
        onTap: action.onActivate,
        child: IuxFocusable(
          onActivate: action.onActivate,
          borderRadius: BorderRadius.circular(tokens.actionRadius),
          child: IuxTapTarget(
            onTap: action.onActivate,
            child: DecoratedBox(
              decoration: BoxDecoration(
                // Outlined, so the control is identifiable as one by shape. A
                // bare coloured word inside an already-coloured block asks the
                // user to tell two tints apart to find out what is tappable.
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
      );
}

/// The way out, and the way to stop the clock.
///
/// Present on every message, including one that would have left on its own.
/// It is the "hide" mechanism WCAG 2.2 SC 2.2.2 asks for on auto-updating
/// content, and it is the only such mechanism a switch user or a screen-reader
/// user can discover — a swipe-to-dismiss gesture is neither announced nor
/// reliably performable.
class _IuxTransientDismissControl extends StatelessWidget {
  const _IuxTransientDismissControl({
    required this.label,
    required this.onDismiss,
    required this.tokens,
  });

  final String label;
  final VoidCallback onDismiss;
  final IuxTransientTokens tokens;

  @override
  Widget build(BuildContext context) => IuxSemantics.action(
        label: label,
        onTap: onDismiss,
        child: IuxFocusable(
          onActivate: onDismiss,
          child: IuxTapTarget(
            onTap: onDismiss,
            child: Icon(
              Icons.close,
              size: tokens.iconSize,
              // The content role, not the icon role: this glyph is a control
              // rather than the tone, and a control is held to the text ratio
              // the theme measured for content on this surface.
              color: tokens.content,
              applyTextScaling: false,
            ),
          ),
        ),
      );
}
