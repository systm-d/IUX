import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../accessibility/iux_semantics.dart';
import '../../motion/iux_motion_policy.dart';
import 'iux_help_tokens.dart';

/// Why an empty message is refused.
const String _kEmptyMessage =
    'A tooltip with no message is a box that appears and says nothing. Pass '
    'the phrase you meant to show, or remove the IuxTooltip: a control that '
    'needs no elaboration is better without one.';

/// Why a message longer than the ceiling is refused.
const String _kTooLong =
    'A tooltip carries at most $kIuxTooltipMaximumCharacters characters. What '
    'you have is a paragraph, and a paragraph in a box floating over a page — '
    'at 200% text, on a 320-pixel screen — is unreadable and cannot be '
    'scrolled. Use IuxContextualHelp: it opens in the page, stays open, and '
    'has room. See docs/components/contextual-help.md.';

/// Why a message with a line break is refused.
const String _kMultiLine =
    'A tooltip is one phrase, so it has nowhere to put a line break. Two lines '
    'means two thoughts, and the second one is already too much for a box the '
    'user cannot scroll or keep open. Use IuxContextualHelp.';

/// A short elaboration attached to a control, revealed on demand.
///
/// ```dart
/// IuxTooltip(
///   message: l10n.archiveThisConversation,
///   child: IuxIconButton(
///     icon: Icons.archive_outlined,
///     action: const IuxActionDescriptor(
///       semantics: IuxActionSemantics(label: 'Archive'),
///     ),
///     onActivate: controller.archive,
///   ),
/// )
/// ```
///
/// **Use it** to say what a glyph means to the sighted user who cannot decode
/// it. That is the case this component exists for: `IuxIconButton` documents
/// that "a sighted user must still recognise the glyph", and this is the
/// answer.
///
/// **Do not use it** for anything the user needs. The rule below is not a
/// recommendation, and every decision on this page follows from it.
///
/// ## The rule: a tooltip is never the only place information exists
///
/// A tooltip is reached by hovering, by holding, or by moving keyboard focus.
/// Each of those loses somebody:
///
/// - **hover does not exist on a phone**, which is this framework's primary
///   platform, so every Android user loses hover-only content entirely;
/// - **long-press is not announced and not discoverable** — nothing on screen
///   says the gesture is available, so a user who does not already know it will
///   never find out;
/// - **a screen-reader user does not move Flutter focus** by swiping through
///   the page, so a focus-triggered reveal does not happen for them;
/// - **a user with a motor impairment** may not be able to hold a press
///   steady for the length of a long-press at all.
///
/// So: the accessible name carries the meaning, and the tooltip elaborates.
/// `IuxIconButton` already makes the name unrepresentable-as-missing —
/// [IuxActionSemantics.label] is required and non-empty — which is what makes
/// attaching a tooltip to one safe. Attaching one to a control with no name is
/// how a library ends up with buttons only mouse users can identify.
///
/// The framework cannot check that a message is redundant. It checks the two
/// things a machine can decide — that the message is short, and that it is one
/// line — because those are what stop a tooltip from *becoming* the only place
/// the information could reasonably live.
///
/// ## WCAG 2.2 SC 1.4.13, satisfied rather than approximated
///
/// Content shown on hover or focus must be **dismissable**, **hoverable** and
/// **persistent**. Most tooltip implementations fail the third by hiding on a
/// timer; this one has no clock at all.
///
/// - **Dismissable.** `Escape` closes it while the pointer stays where it is
///   and focus stays where it is. So does a tap anywhere outside, a tap on the
///   tooltip itself, and a press on the anchor.
/// - **Hoverable.** The tooltip's mouse region extends across the gap that
///   separates it from its anchor, so the pointer travels onto the tooltip
///   without ever crossing a dead zone. Reading it does not dismiss it.
/// - **Persistent.** There is no duration, no `showDuration`, and no way to
///   add one. It stays until the user dismisses it, focus leaves, or the
///   pointer leaves both the anchor and the tooltip.
///
/// ## Reaching it without hover
///
/// | Input | How the tooltip is reached |
/// | --- | --- |
/// | touch | long-press the control |
/// | keyboard / D-pad | move focus to the control |
/// | pointer | hover the control |
/// | screen reader | the control's own accessible name, which is not this |
///
/// ## What this does not do
///
/// It shows text. There is no rich content, no link and no control inside a
/// tooltip, and there will not be: anything a user can interact with has to be
/// reachable, and this box is reachable only by the three routes above.
class IuxTooltip extends StatefulWidget {
  /// Attaches [message] to [child].
  const IuxTooltip({
    super.key,
    required this.message,
    required this.child,
  }) : assert(message.length > 0, _kEmptyMessage);

  /// Whether [message] is short enough and simple enough to float.
  ///
  /// Public so the boundary can be asserted directly, and so a caller building
  /// a message at runtime — joining a name to a state, say — can ask before
  /// they have already shipped a paragraph in a floating box.
  ///
  /// Counted in runes rather than code units, so an emoji or an accented
  /// character is one character and not two.
  static bool isWithinBounds(String message) =>
      message.runes.length <= kIuxTooltipMaximumCharacters &&
      !message.contains('\n');

  /// The phrase shown beside the control. Already localised.
  ///
  /// At most [kIuxTooltipMaximumCharacters] characters, and one line. Both are
  /// asserted rather than advised, because a ceiling written in a document has
  /// never once kept a tooltip short.
  ///
  /// It elaborates; it does not name. A control whose *name* is only here is a
  /// control most users cannot identify — see the class documentation.
  final String message;

  /// The control the tooltip is about.
  ///
  /// It must already have an accessible name of its own. This widget adds the
  /// message as a semantic tooltip on the same subtree, but it neither supplies
  /// nor checks a name, and it cannot: a name is the control's own obligation.
  final Widget child;

  @override
  State<IuxTooltip> createState() => _IuxTooltipState();
}

class _IuxTooltipState extends State<IuxTooltip>
    with SingleTickerProviderStateMixin {
  final OverlayPortalController _portal = OverlayPortalController();

  /// Drives the fade. Created eagerly and always at rest holding a visible
  /// value, so the overlay can never be built against a controller that does
  /// not exist yet — a tooltip stuck at zero opacity is a tooltip that is not
  /// there.
  late final AnimationController _entrance;

  /// Whether the pointer rests on the anchor.
  bool _hoveringAnchor = false;

  /// Whether the pointer rests on the tooltip, or on the bridge between the
  /// two. Keeping this separate is what makes the content hoverable.
  bool _hoveringTooltip = false;

  /// Whether anything inside the anchor holds focus.
  bool _focused = false;

  /// Whether a hover decision is already queued for the end of this event.
  bool _evaluationScheduled = false;

  @override
  void initState() {
    super.initState();
    _entrance =
        AnimationController(vsync: this, duration: Duration.zero, value: 1);
    _assertMessage();
  }

  @override
  void didUpdateWidget(covariant IuxTooltip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.message != oldWidget.message) _assertMessage();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  /// Checked here rather than in the constructor because neither a rune count
  /// nor a substring search is a constant expression, and [IuxTooltip] is worth
  /// keeping `const`. Debug-only, like every other bound in the library.
  void _assertMessage() {
    assert(
      widget.message.runes.length <= kIuxTooltipMaximumCharacters,
      _kTooLong,
    );
    assert(!widget.message.contains('\n'), _kMultiLine);
  }

  void _show() {
    if (_portal.isShowing) return;
    _portal.show();
    _playEntrance();
  }

  void _hide() {
    if (!_portal.isShowing) return;
    _portal.hide();
  }

  void _playEntrance() {
    final IuxResolvedMotion motion =
        IuxTooltipResolver.resolve(context).entrance;

    if (!motion.isAnimated) {
      // Set rather than animated over zero time: an animation that "runs" for
      // no time still leaves one frame at zero opacity, and a box that flickers
      // is worse than one that simply appears — especially for the user who
      // asked for no motion in the first place.
      _entrance.value = 1;
      return;
    }
    _entrance.duration = motion.duration;
    _entrance.forward(from: 0);
  }

  /// A pointer went down on the anchor.
  ///
  /// Shown, it goes away: this is the touch user's way out, and it costs them
  /// nothing because the press they were making still reaches the control
  /// underneath. Not shown, this does nothing at all, so a long press can still
  /// arrive and open it.
  void _handlePointerDown(PointerDownEvent event) => _hide();

  void _handleAnchorHover(bool hovering) {
    _hoveringAnchor = hovering;
    _scheduleEvaluation();
  }

  void _handleTooltipHover(bool hovering) {
    _hoveringTooltip = hovering;
    _scheduleEvaluation();
  }

  void _handleFocusChange(bool focused) {
    _focused = focused;
    if (focused) {
      _show();
      return;
    }
    _scheduleEvaluation();
  }

  /// Decides whether the tooltip should still be up, once this pointer event
  /// has finished being dispatched.
  ///
  /// Deferred to a microtask rather than decided on the spot, and that is the
  /// whole of SC 1.4.13's "hoverable" requirement. Moving the pointer from the
  /// anchor onto the tooltip produces an exit and an enter in the *same*
  /// dispatch, exits first. Acting on the exit immediately would close the
  /// tooltip before the enter it was travelling towards ever arrived, so the
  /// content could be seen and never read.
  ///
  /// A microtask rather than a delay, because a delay would be a duration, and
  /// a duration is a clock. This component has none.
  void _scheduleEvaluation() {
    if (_evaluationScheduled) return;
    _evaluationScheduled = true;
    scheduleMicrotask(() {
      _evaluationScheduled = false;
      if (!mounted) return;
      if (_hoveringAnchor || _hoveringTooltip) {
        _show();
        return;
      }
      if (!_focused) _hide();
    });
  }

  /// Escape closes it without the pointer or the focus having to move, which is
  /// the mechanism SC 1.4.13 asks for by name.
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!_portal.isShowing) return KeyEventResult.ignored;
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey != LogicalKeyboardKey.escape) {
      return KeyEventResult.ignored;
    }
    _hide();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    // A tooltip has to escape whatever clips its anchor — an app bar, a list,
    // a card — so it is painted on the ambient overlay. Checked here so the
    // failure names itself, rather than surfacing later as a tooltip that
    // silently never appears.
    assert(debugCheckHasOverlay(context));

    Widget result = IuxSemantics.elaboration(
      message: widget.message,
      child: OverlayPortal.overlayChildLayoutBuilder(
        controller: _portal,
        overlayChildBuilder: _buildTooltip,
        child: widget.child,
      ),
    );

    result = GestureDetector(
      // Defers to the child, so the gesture region is the control and not a
      // rectangle around it. A long press in the margin beside an icon button
      // would otherwise open a tooltip for a control the user was not on.
      behavior: HitTestBehavior.deferToChild,
      // The touch route. It competes with the control's own tap recogniser in
      // the gesture arena and wins only after the press deadline, so a quick
      // tap still activates the control and never opens this.
      onLongPress: _show,
      child: result,
    );

    result = Listener(
      onPointerDown: _handlePointerDown,
      child: MouseRegion(
        onEnter: (PointerEnterEvent _) => _handleAnchorHover(true),
        onExit: (PointerExitEvent _) => _handleAnchorHover(false),
        child: result,
      ),
    );

    // Registered whether or not the tooltip is up, so the first tap elsewhere
    // closes it. It reports the tap rather than consuming it: whatever the user
    // was reaching for still receives the press, so dismissing costs no gesture.
    result =
        TapRegion(onTapOutside: (PointerDownEvent _) => _hide(), child: result);

    // One node, not three. Left unmerged, the tooltip property lands on a
    // wrapper *above* the control and the long-press action on another one
    // above that, while a screen reader lands on the control itself — so the
    // message it exists to carry reaches nobody, and the gesture that reveals
    // it cannot be triggered. Merged, the user meets a single stop carrying the
    // name, the role, the message and the gesture together.
    //
    // This is also why [IuxTooltip.child] is one control. Wrap a row of them
    // and they collapse into a single announcement — a defect this widget
    // cannot detect and the caller has to avoid.
    result = MergeSemantics(child: result);

    return Focus(
      // Not focusable and skipped by traversal: this node exists to hear when a
      // control *inside* takes focus, and to catch Escape on the way up. Making
      // it focusable would add a stop in the traversal order that does nothing.
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: _handleFocusChange,
      onKeyEvent: _handleKeyEvent,
      child: result,
    );
  }

  Widget _buildTooltip(BuildContext context, OverlayChildLayoutInfo info) {
    // A zero determinant means the anchor is not being painted — it scrolled
    // out of view, or an ancestor removed it. Nothing to point at.
    if (info.childPaintTransform.determinant() == 0) {
      return const SizedBox.shrink();
    }

    // Resolved from the anchor's context, not the overlay's: a tooltip belongs
    // to the control it annotates and must take the theme that control is in.
    final IuxTooltipTokens tokens = IuxTooltipResolver.resolve(this.context);

    final Offset target = MatrixUtils.transformPoint(
      info.childPaintTransform,
      info.childSize.center(Offset.zero),
    );

    Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.background,
        borderRadius: BorderRadius.circular(tokens.radius),
        // Outlined and not elevated. A shadow resolves to zero under a reduced
        // visual stimulation preference, and the edge of something floating
        // over arbitrary content is not a thing that may quietly disappear.
        border: Border.all(color: tokens.border, width: tokens.borderWidth),
      ),
      child: Padding(
        padding: tokens.padding,
        child: Text(
          widget.message,
          // No line limit and no ellipsis at any text size. A truncated
          // explanation is a different explanation, and truncation gets worse
          // exactly when a user has enlarged their text.
          style: tokens.textStyle,
        ),
      ),
    );

    surface = GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      // Touching the tooltip closes it. On a touch screen this is the mechanism
      // the user finds first, because it is the thing they can see.
      onTap: _hide,
      child: surface,
    );

    return Positioned.fill(
      // Excluded from the semantic tree. The message is already on the anchor's
      // node, where a screen-reader user meets it in place; repeated here it
      // would appear as a loose fragment somewhere else in the reading order,
      // arriving and leaving for reasons that user cannot perceive.
      child: IuxSemantics.decorative(
        child: CustomSingleChildLayout(
          delegate: _IuxTooltipPosition(
            target: target,
            // Half the anchor, so the tooltip clears the control's own edge
            // rather than its centre.
            verticalOffset: info.childSize.height / 2,
            margin: tokens.margin,
            maxWidth: tokens.maxWidth,
          ),
          child: MouseRegion(
            onEnter: (PointerEnterEvent _) => _handleTooltipHover(true),
            onExit: (PointerExitEvent _) => _handleTooltipHover(false),
            child: Padding(
              // The bridge. Transparent, on both vertical sides because the
              // tooltip may end up above or below, and part of the mouse region
              // above — so the pointer reaches the tooltip without ever
              // crossing a gap that would have dismissed it.
              padding: EdgeInsets.symmetric(vertical: tokens.gap),
              child: FadeTransition(opacity: _entrance, child: surface),
            ),
          ),
        ),
      ),
    );
  }
}

/// Places the tooltip beside its anchor and inside the screen.
///
/// Delegated to `positionDependentBox`, the same function Flutter's own tooltip
/// uses, because the rules it encodes are the ones that matter and are easy to
/// get subtly wrong: flip to the other side when the preferred one does not
/// fit, and never cross the screen margin. The second is what keeps the tooltip
/// of a trailing app-bar icon on screen, which is the single most common place
/// a tooltip is put and the single most common place one is clipped.
class _IuxTooltipPosition extends SingleChildLayoutDelegate {
  const _IuxTooltipPosition({
    required this.target,
    required this.verticalOffset,
    required this.margin,
    required this.maxWidth,
  });

  /// The centre of the anchor, in the overlay's coordinates.
  final Offset target;

  /// How far from [target] the near edge of the tooltip sits.
  final double verticalOffset;

  /// The smallest distance kept from the edge of the screen.
  final double margin;

  /// The widest the tooltip may grow, before the screen is taken into account.
  final double maxWidth;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    // Whichever is narrower: the reading cap, or what the screen leaves once
    // both margins are taken. The second is what stops a tooltip running off a
    // small screen when the user has enlarged their text — the cap is expressed
    // in characters, so it grows with the text and can exceed the display.
    final double available = constraints.maxWidth - margin * 2;
    return constraints.loosen().copyWith(
          maxWidth: available <= 0
              ? constraints.maxWidth
              : available.clamp(0, maxWidth),
        );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) => positionDependentBox(
        size: size,
        childSize: childSize,
        target: target,
        verticalOffset: verticalOffset,
        // Below, so the tooltip of a control near the top of the screen — an
        // app bar icon — does not cover the control it explains. Flipped
        // automatically when there is no room.
        preferBelow: true,
        margin: margin,
      );

  @override
  bool shouldRelayout(_IuxTooltipPosition oldDelegate) =>
      target != oldDelegate.target ||
      verticalOffset != oldDelegate.verticalOffset ||
      margin != oldDelegate.margin ||
      maxWidth != oldDelegate.maxWidth;
}
