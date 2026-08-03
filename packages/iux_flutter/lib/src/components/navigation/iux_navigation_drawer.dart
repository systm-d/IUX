import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../accessibility/iux_focus.dart';
import '../../accessibility/iux_semantics.dart';
import '../../actions/iux_action_descriptor.dart';
import '../../actions/iux_action_model.dart';
import '../../layout/iux_spacing_primitives.dart';
import '../../layout/iux_surface.dart';
import '../../motion/iux_motion_policy.dart';
import '../../motion/iux_motion_role.dart';
import '../../themes/extensions/iux_geometry_theme.dart';
import '../button/iux_button.dart';
import 'iux_navigation_destination.dart';
import 'iux_navigation_drawer_tokens.dart';

/// The largest share of the screen width the panel may take.
///
/// A drawer is a surface that covers *part* of the screen, and the strip of
/// page still showing is not decoration: it is what tells the user the page
/// they came from is still there, and it is the target they tap to get back to
/// it. A panel that reached the far edge would be a page — and a page has a
/// title bar, a place in the history and a back gesture that this surface
/// cannot offer.
///
/// The fraction is a judgement. What is not a judgement is the consequence of
/// getting it wrong in either direction: a drawer that covers everything
/// removes the way back, and a drawer pinned narrow clips the names it exists
/// to show. On the narrowest screen IUX supports this leaves 64 logical pixels
/// of page, which is above the smallest strip Material considers usable.
const double _kMaximumScreenFraction = 0.8;

/// A modal panel at the leading edge, holding the places the user can go.
///
/// ```dart
/// Widget build(BuildContext context) {
///   final Widget page = IuxPage(child: body);
///   // Not a Stack with a conditional child. See "How to place it" below:
///   // the page has to leave and re-enter the tree, or it stays readable to a
///   // screen reader while the drawer covers it.
///   if (!state.menuOpen) return page;
///   return Stack(
///     fit: StackFit.expand,
///     children: <Widget>[
///       page,
///       IuxNavigationDrawer(
///         title: l10n.mainNavigation,
///         dismissLabel: l10n.closeMenu,
///         onDismiss: controller.closeMenu,
///         selectedIndex: state.section,
///         destinations: <IuxNavigationDestination>[
///           IuxNavigationDestination(label: l10n.home, icon: Icons.home_outlined),
///           IuxNavigationDestination(label: l10n.orders, icon: Icons.receipt_long_outlined),
///           IuxNavigationDestination(label: l10n.settings, icon: Icons.settings_outlined),
///         ],
///         onDestinationSelected: controller.goTo,
///       ),
///     ],
///   );
/// }
/// ```
///
/// **Use it** when an application has more top-level sections than a bar can
/// hold, or sections a user visits rarely enough that a permanent strip of the
/// screen is not worth spending on them. The drawer's value is that it costs
/// nothing until it is opened and can then be as long as it needs to be.
///
/// **Do not use it** for:
///
/// - **Three to five sections the user moves between constantly.** That is
///   `IuxBottomNavigation`, and it is better: the destinations are visible
///   without a gesture, they say where the user is without being opened, and
///   they are in reach of a thumb. A drawer hides all of that behind one tap
///   and a modal interruption.
/// - **Actions.** A destination is a *place*. A drawer that mixes "Orders" with
///   "Sign out" makes the user guess which rows take them somewhere they can
///   come back from, and the guess is made behind a scrim with the page gone.
/// - **A decision that must be answered.** That is `IuxDialog`.
/// - **Content the user works in.** That is `IuxBottomSheet`. A drawer holds a
///   list of places and nothing else — there is no `child`, deliberately.
/// - **Settings, filters or an account panel.** They are not places, and a
///   surface whose rows do different kinds of thing is a surface with no rule
///   the user can learn.
///
/// ## It is a layer, not a route
///
/// Like `IuxDialog` and `IuxBottomSheet`, the drawer is a layer the parent
/// places, not a route it pushes: the back stack, deep links and state
/// restoration belong to the application. The parent owns a flag, and the
/// drawer exists exactly while the flag is true — which also means it cannot be
/// left open by a code path that forgot to pop.
///
/// It follows that **the drawer does not close itself when a destination is
/// chosen.** [onDestinationSelected] reports which row the user activated; the
/// parent changes the section *and* lowers the flag. A drawer that closed
/// itself would leave the parent's flag saying it was still open.
///
/// ```dart
/// // Wrong: the component owns where the user is, and whether it is open.
/// IuxNavigationDrawer(onDestinationSelected: (int i) => Navigator.push(...))
///
/// // Right: the parent owns both.
/// IuxNavigationDrawer(
///   selectedIndex: state.section,
///   onDestinationSelected: (int i) => controller.goTo(i, closeMenu: true),
/// )
/// ```
///
/// ## How to place it, and why the shape matters
///
/// `IuxModalLayer` has no drawer slot yet, so the parent builds the stack. The
/// shape is not a matter of taste, and it was measured rather than assumed:
///
/// ```dart
/// // Wrong. The page's element survives the change, so its semantics node is
/// // never recompiled, so `BlockSemantics` never removes it: the covered page
/// // is still readable and activatable by a screen reader.
/// Stack(children: <Widget>[page, if (open) drawer])
///
/// // Right. The page leaves the tree, its subtree rebuilds, and the page
/// // disappears from the semantics tree while the drawer is up.
/// if (!open) return page;
/// return Stack(fit: StackFit.expand, children: <Widget>[page, drawer]);
/// ```
///
/// This is IUX-OVERLAY-001, recorded on `IuxModalLayer` and reproduced here.
/// The cost of the right shape is the same one that mission recorded: the page
/// changes depth, so a list scrolled to 400 snaps back to 0 when the drawer
/// opens. `PROJECT_PROMPT.md` §5 puts accessibility above ergonomics, so the
/// scroll loss stays. Touch is unaffected either way — the scrim covers the
/// page in both shapes — which is exactly why the wrong shape is hard to
/// notice without a screen reader.
///
/// ## There is always a way out, and none of them is a gesture
///
/// [onDismiss] is required, and the scrim, the Escape key, the system back
/// gesture and a labelled button in the header all call it. There is no flag
/// that turns one of them off, and there is deliberately no swipe-to-close: a
/// swipe is invisible to a screen reader and out of reach for many
/// motor-impaired users, so it can only ever be a shortcut over a real control,
/// never the control itself.
///
/// The system back is answered by the drawer itself, through a `PopScope` that
/// *declines* the pop and reports the intent. That is not navigation — nothing
/// is pushed and nothing is popped — and it is the one behaviour an Android
/// user will try first. `IuxDialog` and `IuxBottomSheet` still leave it to the
/// caller; see `docs/components/navigation-drawer.md`.
///
/// ## Every destination is named, always
///
/// There is no icon-only mode and no "label the current one" mode. See
/// [IuxNavigationDestination.label]. In a drawer the cost of that rule is
/// nothing at all: the rows are full width, so a name has somewhere to wrap.
///
/// ## How the current destination is announced
///
/// The same three ways `IuxBottomNavigation` uses, deliberately, because the
/// two surfaces answer the same question and must not invent two vocabularies
/// for the answer:
///
/// 1. **In the semantics**, as a checked member of a mutually exclusive group.
///    A screen reader announces "checked" or "not checked" at *every*
///    destination, so the user learns where they are from the row they land on
///    rather than by sweeping the list looking for the one that said something.
/// 2. **As a shape**: a filled, outlined band behind the whole row. Its
///    presence survives a monochrome screen; the outline is drawn as well as
///    the fill because surface contrast alone is deliberately gentle in IUX.
/// 3. **Optionally as a different glyph**, through
///    [IuxNavigationDestination.selectedIcon].
///
/// Colour is never the only signal.
class IuxNavigationDrawer extends StatefulWidget {
  /// Creates a navigation drawer.
  ///
  /// The assertions catch the contradictions that can be decided from the
  /// arguments alone. Quietly repairing them would hide that the caller
  /// believed something untrue about their own navigation.
  IuxNavigationDrawer({
    super.key,
    required this.title,
    required this.dismissLabel,
    required this.onDismiss,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
  })  : assert(
          title.length > 0,
          'A drawer must have a title. It is what assistive technology '
          'announces when the drawer appears, so an empty one leaves a '
          'screen-reader user interrupted with no idea by what.',
        ),
        assert(
          dismissLabel.length > 0,
          'The way out must be labelled. A drawer whose only exit is a swipe '
          'or a tap on the scrim is a drawer that a screen-reader user cannot '
          'find and a motor-impaired user cannot use.',
        ),
        assert(
          destinations.length > 0,
          'A navigation drawer with no destinations is a modal surface the '
          'user has to dismiss in exchange for nothing. There is no empty '
          'state to render here: do not open the drawer.',
        ),
        assert(
          selectedIndex >= 0 && selectedIndex < destinations.length,
          'The current destination is not one of the destinations, so the '
          'drawer would mark none of them. A drawer showing no current '
          'destination while the application believes it has one is how a user '
          'ends up unable to tell which section they are in.',
        ),
        assert(
          destinations
                  .map((IuxNavigationDestination d) => d.label)
                  .toSet()
                  .length ==
              destinations.length,
          'Two destinations share a name. They are indistinguishable to a '
          'screen reader and to anyone reading the list, so the user is shown '
          'a choice they cannot make.',
        );

  /// What this set of destinations is, in the user's language.
  ///
  /// Three things at once, and on purpose: the name announced when assistive
  /// technology enters the drawer, the heading drawn at the top of the panel,
  /// and the name of the mutually exclusive set the destinations belong to.
  /// Three parameters would be three strings a caller has to keep in agreement,
  /// and a drawer whose heading and whose announcement disagree is worse than
  /// one that repeats itself.
  ///
  /// Phrase it as what the set *is* ("Main navigation", "Sections"), never as a
  /// mechanism ("Menu"): a mechanism tells the user a surface appeared without
  /// telling them what is in it.
  final String title;

  /// The visible text of the way out.
  ///
  /// Name the outcome rather than the mechanism where the outcome is not
  /// obvious. A drawer discards nothing, so "Close" is honest here.
  final String dismissLabel;

  /// Called when the user leaves the drawer without choosing a destination.
  ///
  /// The same callback for the scrim, for Escape, for the system back gesture
  /// and for the header button, so the four cannot drift into meaning different
  /// things. The parent removes the drawer from the tree in response; this
  /// widget does not close itself.
  ///
  /// Not called when a destination is chosen — that is
  /// [onDestinationSelected], and conflating the two would leave the parent
  /// unable to tell "the user went somewhere" from "the user changed their
  /// mind".
  final VoidCallback onDismiss;

  /// The destinations, in the order they are shown and read.
  ///
  /// At least one, with distinct names, both asserted. There is no upper bound:
  /// a drawer that could not hold more destinations than a bar can would have
  /// no reason to exist, and the list scrolls. Order is the caller's and is
  /// never sorted here — position in a navigation surface is what users
  /// remember.
  final List<IuxNavigationDestination> destinations;

  /// Which destination the user is currently in.
  ///
  /// Owned by the parent. The drawer renders it and never changes it.
  ///
  /// Non-nullable, like `IuxBottomNavigation.selectedIndex`. A drawer whose
  /// every row announces "not checked" is a menu of actions rather than a map
  /// of an application, and the two need different components. If a genuine
  /// "none of these" case appears, it is a change to make with evidence, not in
  /// advance.
  final int selectedIndex;

  /// Called with the index of the destination the user chose.
  ///
  /// **Called for the current destination too**, exactly as
  /// `IuxBottomNavigation` does. Choosing the section you are already in is a
  /// real and distinguishable gesture — from a drawer it usually means "close
  /// this and leave me where I am" — and only the parent knows what it means
  /// here.
  ///
  /// Non-nullable. A destination that cannot be reached should not be in the
  /// list: showing the user a place they are not allowed to go is worse than
  /// one fewer row.
  final ValueChanged<int> onDestinationSelected;

  @override
  State<IuxNavigationDrawer> createState() => _IuxNavigationDrawerState();
}

class _IuxNavigationDrawerState extends State<IuxNavigationDrawer>
    with SingleTickerProviderStateMixin {
  /// Confines keyboard traversal to the drawer.
  ///
  /// Tab and arrow traversal cycle within the nearest enclosing scope, so
  /// declaring one here is what stops the user tabbing into the page the drawer
  /// is covering. A page whose controls still answer the keyboard while being
  /// visually behind a scrim is worse than one that is gone.
  final FocusScopeNode _scope =
      FocusScopeNode(debugLabel: 'IuxNavigationDrawer');

  /// Where focus lands when the drawer opens.
  ///
  /// The panel itself, never the first destination. Landing on a destination
  /// would put an Enter press one keystroke away from navigating somewhere the
  /// user has not read yet, and it would announce a destination before
  /// announcing what the list of destinations is.
  final FocusNode _panel = FocusNode(debugLabel: 'IuxNavigationDrawer panel');

  /// Whatever held focus when the drawer opened.
  FocusNode? _restoreTo;

  AnimationController? _entrance;
  CurvedAnimation? _eased;

  /// The sideways travel of the entrance, or null when it must not travel.
  Animation<Offset>? _slide;

  bool _entranceStarted = false;

  @override
  void initState() {
    super.initState();
    // Captured before anything in the drawer can take focus. By the time the
    // first frame is drawn the answer is already gone.
    _restoreTo = IuxFocus.current(context);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Declared as a reveal rather than as an enter, and the difference is the
    // whole point: both animate an appearance, but only `reveal` turns into a
    // fade when the user asks for less motion. `enter` would merely shorten the
    // travel, and a fast sweep across most of the screen is worse for a
    // vestibular disorder than a slow one, not better.
    final IuxResolvedMotion motion = IuxMotionPolicy.resolve(
      context,
      role: IuxMotionRole.reveal,
    );

    // Read here rather than in build: the direction decides which edge the
    // panel travels from, and that is fixed when the entrance is built.
    final bool rightToLeft = Directionality.of(context) == TextDirection.rtl;

    final AnimationController controller =
        _entrance ??= AnimationController(vsync: this, duration: Duration.zero);

    if (_entranceStarted) return;
    _entranceStarted = true;

    if (motion.isAnimated) {
      controller.duration = motion.duration;
      // The travel says where the drawer came from, and therefore where it
      // lives: the edge the reading direction starts at. Suppressed entirely
      // when the policy asks for a fade, in which case the panel appears in
      // place.
      if (!motion.prefersFade) {
        final CurvedAnimation eased =
            _eased = CurvedAnimation(parent: controller, curve: motion.curve);
        _slide = Tween<Offset>(
          begin: Offset(rightToLeft ? 1 : -1, 0),
          end: Offset.zero,
        ).animate(eased);
      }
      controller.forward();
    } else {
      // Set rather than animated to zero: an animation that "runs" for no time
      // still leaves the first frame at zero opacity, and a drawer invisible
      // for one frame is a drawer that flickers for the user who asked for no
      // motion at all.
      controller.value = 1;
    }

    // Focus is moved after the first frame, once the nodes below exist to
    // receive it. Requested explicitly rather than left to autofocus, because
    // autofocus yields to whatever already held focus — which is precisely the
    // control on the page the drawer has just covered.
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (!mounted) return;
      IuxFocus.request(_panel);
    });
  }

  @override
  void dispose() {
    final FocusNode? restoreTo = _restoreTo;
    _eased?.dispose();
    _entrance?.dispose();
    _panel.dispose();
    _scope.dispose();

    // Restored at the end of the frame that removed the drawer, once the nodes
    // it owned are gone. Restoring during dispose would hand focus to a node
    // the framework is about to take it back from.
    WidgetsBinding.instance.addPostFrameCallback(
      (Duration _) => IuxFocus.restore(restoreTo),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final IuxNavigationDrawerTokens tokens =
        IuxNavigationDrawerResolver.resolve(context);

    return PopScope<Object?>(
      // The system back gesture is the first thing an Android user tries on an
      // open drawer, and a modal it cannot leave is a trap. Declining the pop
      // and reporting the intent is not navigation: nothing is pushed, nothing
      // is popped, and the parent still decides what happens next.
      //
      // Registered against the enclosing route when there is one and ignored
      // when there is not, so this is safe outside a Navigator.
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) widget.onDismiss();
      },
      child: BlockSemantics(
        // Everything painted before this — the page the drawer covers — leaves
        // the semantic tree while the drawer is up. Without it a screen-reader
        // user can still swipe into content that no longer responds to them,
        // and a control that reads out but does nothing is worse than one that
        // is gone.
        child: IuxSemantics.route(
          label: widget.title,
          child: FocusScope(
            node: _scope,
            child: Shortcuts(
              // Declared here rather than relying on the ambient application's
              // shortcuts, so Escape means the same thing whatever the drawer
              // is embedded in.
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
                // keyboard activation of its own, so Enter pressed on a drawer
                // the user has not read yet does nothing rather than something.
                child: Focus(
                  focusNode: _panel,
                  child: FadeTransition(
                    opacity: _entrance!,
                    child: SizedBox.expand(
                      child: Stack(
                        // The panel is painted after the scrim, so the scrim
                        // never covers the thing it is dimming for.
                        fit: StackFit.expand,
                        children: <Widget>[
                          _scrim(tokens),
                          _panelLayer(context, tokens),
                        ],
                      ),
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

  /// The dimmed area outside the panel, which is also a way out.
  Widget _scrim(IuxNavigationDrawerTokens tokens) {
    return ExcludeSemantics(
      // Excluded rather than labelled: the header button says the same thing in
      // words, and a second, invisible "dismiss" target reachable only by
      // swiping is a control a user cannot verify before activating.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onDismiss,
        child: ColoredBox(color: tokens.scrim),
      ),
    );
  }

  /// The panel, anchored to the leading edge and as tall as the screen.
  Widget _panelLayer(
    BuildContext context,
    IuxNavigationDrawerTokens tokens,
  ) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        Widget surface = GestureDetector(
          // Opaque, with no callback: a tap that lands on the panel's own
          // padding is not a dismissal, and without this it would fall through
          // to the scrim and close the drawer the user was reading.
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: _panelWidth(
              box: constraints.maxWidth,
              cap: tokens.readableWidth,
            ),
            // Clamped to the box by the enclosing constraints. The panel spans
            // the full height because it holds a list that has to be able to
            // grow, and a panel floating in the middle of a scrim would be a
            // dialog.
            height: double.infinity,
            child: IuxSurface(
              role: IuxSurfaceRole.overlay,
              shape: IuxSurfaceShape.prominent,
              // Bordered as well as elevated. Elevation is resolved to zero
              // under a reduced visual stimulation preference, and the edge of
              // a modal surface is not something that may quietly disappear.
              bordered: true,
              elevated: true,
              child: _content(context, tokens),
            ),
          ),
        );

        final Animation<Offset>? slide = _slide;
        if (slide != null) {
          // Wrapped around the panel rather than around the layer, so the
          // offset is a fraction of the panel's own width: it travels exactly
          // its own width and no more, whatever the screen is.
          surface = SlideTransition(position: slide, child: surface);
        }

        return Align(
          // Directional, so the panel sits on the edge the reading direction
          // starts at without the caller choosing a side.
          alignment: AlignmentDirectional.centerStart,
          child: surface,
        );
      },
    );
  }

  /// The heading, the way out and the destinations — all in one scroll view.
  ///
  /// Everything scrolls, including the header, for the reason
  /// `IuxBottomSheet` records: at 200% text on a short screen a pinned heading
  /// and button are taller than the surface, and the destinations get nothing
  /// at all. Content that cannot be reached is content the user cannot act on,
  /// so the header gives way.
  ///
  /// The header being *first* is what keeps the cost small: the way out is
  /// visible when the drawer opens, it is the first control any keyboard,
  /// D-pad or screen reader reaches, and it only leaves the viewport once the
  /// user has scrolled past it deliberately. Escape, the scrim and the system
  /// back do not scroll anywhere.
  ///
  /// One scroll view rather than a lazy list. A drawer holds the sections of an
  /// application, which is a number a person can hold in mind; a drawer long
  /// enough to need virtualising is a screen, not a menu.
  Widget _content(BuildContext context, IuxNavigationDrawerTokens tokens) {
    final bool rightToLeft = Directionality.of(context) == TextDirection.rtl;

    return SafeArea(
      // The panel touches the top, the bottom and the leading edge, so it
      // consumes those three insets itself — inside the surface, so the surface
      // still reaches the physical edge and no strip of page shows beside it.
      //
      // Never the trailing edge: nothing of the panel is there, and padding for
      // an obstacle that is not there is a column of empty space between the
      // names and the page.
      left: !rightToLeft,
      right: rightToLeft,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: IuxInsets.surface(context),
              child: _header(context, tokens),
            ),
            IuxSemantics.radioGroup(
              // The same string as the route, deliberately. The destinations
              // *are* the drawer, so naming the set anything else would be
              // inventing a second name for one thing.
              label: widget.title,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (int index = 0;
                      index < widget.destinations.length;
                      index++)
                    _IuxDrawerDestination(
                      destination: widget.destinations[index],
                      current: index == widget.selectedIndex,
                      onSelected: () => widget.onDestinationSelected(index),
                    ),
                ],
              ),
            ),
            // So the last row is not flush against the bottom edge, where a
            // gesture bar would sit on top of its target.
            const IuxGap.standard(),
          ],
        ),
      ),
    );
  }

  /// The heading and the way out, in that order in every direction.
  ///
  /// The heading reads first because it says what the drawer is; the dismissal
  /// is the first *control*, so it is what a Tab, a D-pad press or a screen
  /// reader swipe reaches before any destination. A way out found only after
  /// twelve swipes is a way out most users never find — and in a drawer the
  /// alternative to finding it is choosing a destination the user did not want.
  Widget _header(BuildContext context, IuxNavigationDrawerTokens tokens) {
    final Widget title = IuxSemantics.header(
      label: widget.title,
      child: Text(
        widget.title,
        // No line limit and no ellipsis. A truncated heading is a drawer the
        // user cannot identify, and truncation gets worse exactly when someone
        // has enlarged their text.
        style: tokens.titleStyle,
      ),
    );

    final Widget dismiss = IuxButton(
      label: widget.dismissLabel,
      action: IuxActionDescriptor(
        semantics: IuxActionSemantics(label: widget.dismissLabel),
        // Dismiss, not cancel: closing a drawer discards nothing, and
        // announcing it as a cancellation would suggest something was thrown
        // away.
        role: IuxActionRole.dismiss,
      ),
      onActivate: widget.onDismiss,
    );

    if (IuxReadableText.shouldStack(context)) {
      // Past roughly 130% text a heading and a button stop sharing a line in a
      // panel this narrow, and the row would either overflow or squeeze the
      // heading into a column two characters wide.
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[title, const IuxGap.tight(), dismiss],
      );
    }

    return Row(
      // Aligned to the top, so a heading that wraps to three lines does not
      // drag the button down to the middle of them.
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: title),
        const IuxGap.horizontal(IuxSpacingStep.md),
        dismiss,
      ],
    );
  }

  /// How wide the panel is, given the box it was handed.
  ///
  /// The smaller of two answers, and both have to hold. [cap] is the width the
  /// names need, measured in characters and therefore growing with the user's
  /// text size. [box] times [_kMaximumScreenFraction] is the width the *page*
  /// needs to keep, so there is still a way back and something to tap it with.
  ///
  /// Falls back to [cap] when the box is unbounded, which is not a layout a
  /// drawer should be in but is better answered with a usable panel than with
  /// an exception.
  static double _panelWidth({required double box, required double cap}) =>
      box.isFinite ? math.min(box * _kMaximumScreenFraction, cap) : cap;
}

/// One destination: a target, a glyph, a name, and at most one badge.
///
/// Private, and it stays private. It is the answer to "what does a drawer
/// destination behave like", and there is one answer: the target floor, the
/// merged announcement and the selection semantics must not be able to drift.
/// Exposing it would invite a drawer assembled by hand that skips one of them.
class _IuxDrawerDestination extends StatefulWidget {
  const _IuxDrawerDestination({
    required this.destination,
    required this.current,
    required this.onSelected,
  });

  final IuxNavigationDestination destination;
  final bool current;
  final VoidCallback onSelected;

  @override
  State<_IuxDrawerDestination> createState() => _IuxDrawerDestinationState();
}

class _IuxDrawerDestinationState extends State<_IuxDrawerDestination> {
  bool _pressed = false;
  bool _hovered = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  void _setHovered(bool value) {
    if (_hovered == value) return;
    setState(() => _hovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final IuxNavigationDrawerTokens tokens =
        IuxNavigationDrawerResolver.resolve(
      context,
      current: widget.current,
      pressed: _pressed,
      hovered: _hovered,
    );

    final BorderRadius radius = BorderRadius.circular(tokens.indicatorRadius);

    final Widget interactive = GestureDetector(
      // Opaque so the whole row responds, including the space the focus ring
      // reserves, and not only the glyph and the word painted in the middle.
      behavior: HitTestBehavior.opaque,
      onTapDown: (TapDownDetails _) => _setPressed(true),
      onTapUp: (TapUpDetails _) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onSelected,
      child: MouseRegion(
        onEnter: (_) => _setHovered(true),
        onExit: (_) => _setHovered(false),
        child: ConstrainedBox(
          // Outside the focus ring, so the floor applies to the region that
          // responds rather than to the part that is painted.
          constraints: BoxConstraints(minHeight: tokens.minExtent),
          child: IuxFocusable(
            onActivate: widget.onSelected,
            borderRadius: radius,
            child: Padding(
              padding: tokens.rowPadding,
              child: _content(tokens),
            ),
          ),
        ),
      ),
    );

    final Widget region = Stack(
      // Passthrough, so the region that responds is the whole row rather than
      // only the box its glyph and name happen to need.
      fit: StackFit.passthrough,
      children: <Widget>[
        // Behind the content rather than over it, so neither the indicator nor
        // the press tint ever reduces the contrast of the name it belongs to.
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedOpacity(
              // Faded rather than added, so the row's height never changes when
              // the current destination moves — a list that reflowed under the
              // finger that caused it is a list the user has to re-read.
              opacity: widget.current ? 1 : 0,
              duration: tokens.motion.duration,
              curve: tokens.motion.curve,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: tokens.indicatorFill,
                  borderRadius: radius,
                  border: Border.all(
                    color: tokens.indicatorBorder,
                    width: tokens.indicatorBorderWidth,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: tokens.overlayOpacity,
              duration: tokens.motion.duration,
              curve: tokens.motion.curve,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: tokens.overlayColor,
                  borderRadius: radius,
                ),
              ),
            ),
          ),
        ),
        interactive,
      ],
    );

    // A bare `Semantics` rather than `IuxSemantics.selection`, and the
    // deviation is the one `IuxBottomNavigation` recorded before it.
    // `IuxSemantics.selection` excludes its subtree, which would delete the
    // badge from the interface of every screen-reader user: "Orders, 3 awaiting
    // approval" would be announced as "Orders", and the number would exist for
    // sighted users only.
    //
    // Merging instead gives one stop that reads the name, then what is waiting
    // there, then the state. The properties are exactly the ones
    // `IuxSemantics.selection` sets for `IuxSelectionRole.radio`, because a set
    // of destinations *is* a mutually exclusive selection and must not invent a
    // second vocabulary for saying so.
    return MergeSemantics(
      child: Semantics(
        container: true,
        enabled: true,
        // "Checked", not "selected". A checked node is announced in both
        // states, so a user hears "not checked" at the destinations they are
        // not in; `selected` is announced only when true, which leaves them to
        // sweep the whole list to find the one that said something.
        checked: widget.current,
        inMutuallyExclusiveGroup: true,
        // Registered on the node itself. Without it the destination is
        // announced correctly and refuses to respond to a screen reader's
        // double-tap.
        onTap: widget.onSelected,
        child: region,
      ),
    );
  }

  /// The row's content, in reading order: glyph, name, then what is waiting.
  Widget _content(IuxNavigationDrawerTokens tokens) {
    final IuxNavigationDestination destination = widget.destination;
    final Widget? badge = destination.badge;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        // Removed from the semantic tree, not described. The name beside the
        // glyph already says what this destination is, and a screen reader that
        // announced both would read every section twice.
        IuxSemantics.decorative(
          child: Icon(
            widget.current
                ? destination.selectedIcon ?? destination.icon
                : destination.icon,
            size: tokens.iconSize,
            color: tokens.iconColor,
            // Already scaled once, by the resolver, through the same runtime
            // every other IUX component reads. Letting Flutter scale it again
            // would enlarge the glyph twice as fast as the name beside it.
            applyTextScaling: false,
          ),
        ),
        SizedBox(width: tokens.gap),
        Expanded(
          // Expanded rather than fixed: without it, a long name in a narrow
          // panel is an overflow instead of a second line.
          child: Text(
            destination.label,
            // No line limit and no ellipsis, at any text scale. A truncated
            // destination is a place the user cannot identify, and truncation
            // gets worse exactly when someone enlarged their text in order to
            // read it.
            style: tokens.labelStyle,
          ),
        ),
        if (badge != null) ...<Widget>[
          SizedBox(width: tokens.gap),
          // After the name, in reading order, and never over the glyph: an
          // overlay covers the thing it counts and leaves the number and its
          // subject in two unrelated places for a screen reader.
          badge,
        ],
      ],
    );
  }
}
