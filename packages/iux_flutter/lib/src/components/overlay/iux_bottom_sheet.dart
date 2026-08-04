import 'dart:math' as math;

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

/// How much of the content behind the sheet the scrim covers.
///
/// The same value the dialog uses, deliberately. Two modal surfaces that dim
/// the page by different amounts read as two different degrees of
/// interruption, when they are the same one.
const double _kScrimOpacity = 0.6;

/// The largest share of the screen the sheet may cover.
///
/// A sheet is a surface that interrupts *part* of the screen; the page behind
/// it is what tells the user where they still are. Past roughly two thirds it
/// stops being a sheet and becomes a page with rounded corners, at which point
/// it should have been a page — a real one has a back gesture, a title bar and
/// a place in the history the sheet cannot offer.
///
/// The fraction is a judgement, not a measurement. What is measured is the
/// consequence of getting it wrong in either direction: a sheet that fills the
/// screen removes the context the user needs to interpret it, and a sheet
/// fixed at some short height hides its own content.
const double _kMaximumScreenFraction = 0.6;

/// A modal surface at the bottom edge, for content the user works *in*.
///
/// ```dart
/// Stack(
///   fit: StackFit.expand,
///   children: <Widget>[
///     IuxPage(child: content),
///     if (state.filtering)
///       IuxBottomSheet(
///         title: 'Filter orders',
///         dismissLabel: 'Close',
///         onDismissed: controller.closeFilters,
///         child: IuxTextField(...),
///       ),
///   ],
/// )
/// ```
///
/// **Use it** when the user needs a secondary surface without leaving the page
/// they are on, and the page behind is part of the answer: filtering a list
/// they can still see, picking from a set of options, entering one or two
/// fields that belong to the row they were looking at.
///
/// **Do not use it** for:
///
/// - **A decision that must be answered.** That is `IuxDialog`. A sheet
///   deliberately leaves the page visible and reachable-looking; a question
///   that blocks the task should look like it blocks the task.
/// - **A whole form, or anything with more than a screenful of content.** The
///   sheet is capped at a fraction of the screen precisely so it cannot become
///   a page, and a page is what a long form needs: room, a back gesture, a
///   place in the history, and a scroll position that survives rotation.
/// - **Anything the user did not ask for.** A surface that rises over the
///   content unbidden is dismissed reflexively, and so is the next one.
/// - **Navigation.** A sheet full of destinations is a menu that vanishes; the
///   user cannot go back to it, because there is no "back" to it.
///
/// **This widget does not navigate.** Like `IuxDialog` it is a layer the
/// parent places, not a route it pushes: the back stack, deep links and state
/// restoration belong to the application. The parent owns a flag, and the
/// sheet exists exactly while the flag is true. One consequence is that the
/// Android back button does not reach it — see `docs/components/bottom-sheet.md`
/// for the two-line `PopScope` the parent adds.
///
/// **Dismissal is guaranteed, visible and requires no gesture.** [onDismissed]
/// is required, and the scrim, the Escape key and a labelled button in the
/// header all call it. There is no flag that turns one of them off, and there
/// is deliberately no drag-to-dismiss: a drag is invisible to a screen reader
/// and out of reach for many motor-impaired users, so it can only ever be a
/// shortcut over a real control — never the control itself.
///
/// **The keyboard.** The sheet lifts itself above the software keyboard and
/// keeps its content scrolling in whatever height is left. It lifts by the
/// part of the keyboard nothing else has already removed, so it does not rise
/// twice inside a `Scaffold` that is already resizing for it.
class IuxBottomSheet extends StatefulWidget {
  /// Creates a bottom sheet.
  const IuxBottomSheet({
    super.key,
    required this.title,
    required this.dismissLabel,
    required this.onDismissed,
    required this.child,
  })  : assert(
          title.length > 0,
          'A sheet must have a title. The title is what assistive technology '
          'announces when the sheet appears, so an empty one leaves a screen '
          'reader user interrupted with no idea by what — and it is the only '
          'thing that stays visible once the content is scrolled.',
        ),
        assert(
          dismissLabel.length > 0,
          'The way out must be labelled. A sheet whose only exit is a swipe '
          'or a tap on the scrim is a sheet that a screen-reader user cannot '
          'find and a motor-impaired user cannot use.',
        );

  /// What the sheet is about, in the user's language.
  ///
  /// Also the route name announced on open, and the one thing that stays put
  /// while the content scrolls under it. Phrase it as the subject ("Filter
  /// orders"), never as a category ("Options"): a category tells the user a
  /// surface appeared without telling them what it is for.
  final String title;

  /// The visible text of the way out.
  ///
  /// Name the outcome rather than the mechanism where the outcome is not
  /// obvious. "Close" is fine for a sheet that changes nothing on dismissal;
  /// "Discard the draft" is what a sheet that loses work has to say.
  final String dismissLabel;

  /// Called when the user leaves the sheet.
  ///
  /// The same callback for the scrim, for Escape and for the header button, so
  /// the three cannot drift into meaning different things. The parent removes
  /// the sheet from the tree in response; this widget does not close itself.
  final VoidCallback onDismissed;

  /// The content, which is the reason the sheet exists.
  ///
  /// Required, and it scrolls: whatever the keyboard and the height cap leave,
  /// the content is reachable inside it. Anything the caller puts here owns
  /// its own contrast, targets and semantics — the sheet guarantees the frame
  /// around it, not what is inside.
  ///
  /// Actions belonging to the content go *in* the content, at its end. The
  /// sheet exposes no `actions` list of its own: it is a surface, not a
  /// decision, and a second place to put buttons is a second reading order to
  /// get wrong.
  final Widget child;

  @override
  State<IuxBottomSheet> createState() => _IuxBottomSheetState();
}

class _IuxBottomSheetState extends State<IuxBottomSheet>
    with SingleTickerProviderStateMixin {
  /// Confines keyboard traversal to the sheet.
  ///
  /// Tab and arrow traversal cycle within the nearest enclosing scope, so
  /// declaring one here is what stops the user tabbing into the page the sheet
  /// is covering — a page whose controls still answer the keyboard while being
  /// visually behind a scrim is worse than one that is gone.
  final FocusScopeNode _scope = FocusScopeNode(debugLabel: 'IuxBottomSheet');

  /// Where focus lands when the sheet opens.
  ///
  /// The panel itself, and never a field inside it. A sheet that focuses its
  /// first input raises the keyboard before the user has read the title, which
  /// covers half of what they were about to read. They open the keyboard by
  /// choosing the field, which is also when they know which field they want.
  final FocusNode _panel = FocusNode(debugLabel: 'IuxBottomSheet panel');

  /// Whatever held focus when the sheet opened.
  FocusNode? _restoreTo;

  AnimationController? _entrance;
  CurvedAnimation? _eased;

  /// The upward travel of the entrance, or null when it must not travel.
  Animation<Offset>? _rise;

  bool _entranceStarted = false;

  @override
  void initState() {
    super.initState();
    // Captured before anything in the sheet can take focus. By the time the
    // first frame is drawn the answer is already gone.
    _restoreTo = IuxFocus.current(context);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Declared as a reveal rather than as an enter, and the difference is the
    // whole point: both animate an appearance, but only `reveal` turns into a
    // fade when the user asks for less motion. `enter` would merely shorten
    // the travel, and a fast large movement is worse for a vestibular disorder
    // than a slow one, not better.
    final IuxResolvedMotion motion = IuxMotionPolicy.resolve(
      context,
      role: IuxMotionRole.reveal,
    );

    final AnimationController controller =
        _entrance ??= AnimationController(vsync: this, duration: Duration.zero);

    if (_entranceStarted) return;
    _entranceStarted = true;

    if (motion.isAnimated) {
      controller.duration = motion.duration;
      // The rise says where the sheet came from, and therefore where it lives:
      // the bottom edge. Suppressed entirely when the policy asks for a fade,
      // in which case the sheet simply appears in place.
      if (!motion.prefersFade) {
        final CurvedAnimation eased =
            _eased = CurvedAnimation(parent: controller, curve: motion.curve);
        _rise = Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(eased);
      }
      controller.forward();
    } else {
      // Set rather than animated to zero: an animation that "runs" for no time
      // still leaves the first frame at zero opacity, and a sheet invisible
      // for one frame is a sheet that flickers for the user who asked for no
      // motion at all.
      controller.value = 1;
    }

    // Focus is moved after the first frame, once the nodes below exist to
    // receive it. Requested explicitly rather than left to autofocus, because
    // autofocus yields to whatever already held focus — which is precisely the
    // widget on the page the sheet has just covered.
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

    // Restored at the end of the frame that removed the sheet, once the nodes
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
    final _IuxWindowMetrics metrics = _windowMetrics(context);

    return BlockSemantics(
      // Everything painted before this — the page the sheet covers — leaves
      // the semantic tree while the sheet is up. Without it a screen-reader
      // user can still swipe into content that no longer responds to them, and
      // a control that reads out but does nothing is worse than one that is
      // gone.
      child: IuxSemantics.route(
        label: widget.title,
        child: FocusScope(
          node: _scope,
          child: Shortcuts(
            // Declared here rather than relying on the ambient application's
            // shortcuts, so Escape means the same thing whatever the sheet is
            // embedded in.
            shortcuts: const <ShortcutActivator, Intent>{
              SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
            },
            child: Actions(
              actions: <Type, Action<Intent>>{
                DismissIntent: CallbackAction<DismissIntent>(
                  onInvoke: (DismissIntent intent) {
                    widget.onDismissed();
                    return null;
                  },
                ),
              },
              // The panel holds focus but is not a control: it registers no
              // keyboard activation of its own, so Enter pressed on a sheet
              // the user has not read yet does nothing rather than something.
              child: Focus(
                focusNode: _panel,
                child: FadeTransition(
                  opacity: _entrance!,
                  child: SizedBox.expand(
                    child: LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                        final _IuxSheetGeometry geometry = _IuxSheetGeometry.of(
                          box: constraints.maxHeight,
                          window: metrics.height,
                          keyboard: metrics.keyboard,
                        );
                        return Stack(
                          fit: StackFit.expand,
                          children: <Widget>[
                            _scrim(colors),
                            _panelLayer(context, geometry),
                          ],
                        );
                      },
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

  /// The window height and the keyboard height.
  ///
  /// Both come from the layout layer rather than from `MediaQuery` directly.
  /// The Component Standard's ban on reading `MediaQuery` inside a component
  /// is aimed at *preferences* — text scale, contrast, reduced motion — which
  /// a component must never reach its own conclusion about behind
  /// `IuxAccessibility`'s back.
  ///
  /// A view inset is not a preference. It is a measurement of how much of the
  /// window the platform has taken away this frame; it changes several times a
  /// second while a keyboard animates, and no user ever asked for a value of
  /// it. `IuxInsets.keyboard` is where that measurement lives, so this
  /// component needs no exception to the standard.
  _IuxWindowMetrics _windowMetrics(BuildContext context) => _IuxWindowMetrics(
        height: IuxInsets.windowHeight(context),
        keyboard: IuxInsets.keyboard(context),
      );

  /// The dimmed area outside the sheet, which is also a way out.
  Widget _scrim(IuxSemanticColors colors) {
    return ExcludeSemantics(
      // Excluded rather than labelled: the header button says the same thing
      // in words, and a second, invisible "dismiss" target reachable only by
      // swiping is a control a user cannot verify before activating.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onDismissed,
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
  /// closer to the sheet it is supposed to sit behind.
  ///
  /// The same derivation as `IuxDialog`, duplicated because it is private
  /// there. It belongs in one place; see the documentation for the change that
  /// would put it there.
  Color _scrimColor(IuxSemanticColors colors) {
    final Color base = colors.surface.base;
    final Color inverse = colors.surface.inverse;
    final Color darker =
        base.computeLuminance() <= inverse.computeLuminance() ? base : inverse;
    return darker.withValues(alpha: _kScrimOpacity);
  }

  /// The panel, anchored to the bottom edge and lifted clear of the keyboard.
  Widget _panelLayer(BuildContext context, _IuxSheetGeometry geometry) {
    Widget surface = GestureDetector(
      // Opaque, with no callback: a tap that lands on the panel's own padding
      // is not a dismissal, and without this it would fall through to the
      // scrim and close the sheet the user was reading.
      behavior: HitTestBehavior.opaque,
      child: IuxSurface(
        role: IuxSurfaceRole.overlay,
        shape: IuxSurfaceShape.prominent,
        // Bordered as well as elevated. Elevation is resolved to zero under a
        // reduced visual stimulation preference, and the edge of a modal
        // surface is not something that may quietly disappear.
        bordered: true,
        elevated: true,
        child: _content(context),
      ),
    );

    final Animation<Offset>? rise = _rise;
    if (rise != null) {
      // Wrapped around the panel rather than around the layer, so the offset
      // is a fraction of the panel's own height: the sheet travels exactly its
      // own height and no more, whatever size the content gave it.
      surface = SlideTransition(position: rise, child: surface);
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        // The lift. Only the residue of the keyboard, never the whole of it —
        // see [_IuxSheetGeometry]. Not animated here: the platform reports the
        // inset progressively while the keyboard opens, so this padding is
        // already following a curve. Animating it again would make the sheet
        // lag behind the keyboard it is supposed to sit on.
        padding: EdgeInsets.only(bottom: geometry.lift),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: geometry.maximumHeight),
          child: IuxReadableWidth(
            // Capped in characters rather than pixels, so enlarging text
            // widens the sheet instead of squeezing the same words into a
            // narrower column. Below the cap — every phone — it does nothing
            // and the sheet spans the width it is given.
            width: IuxContentWidth.standard,
            alignment: Alignment.bottomCenter,
            child: surface,
          ),
        ),
      ),
    );
  }

  /// Title, way out and content — all inside one scroll view.
  ///
  /// Everything scrolls, including the header. Pinning the title and the
  /// dismissal looks better and reads better right up to 200% text on a small
  /// screen, where the two of them alone are taller than the sheet is allowed
  /// to be and the content gets nothing at all. Content that cannot be reached
  /// is content the user cannot act on, so the header gives way.
  ///
  /// The header being *first* in the scroll view is what keeps the cost small:
  /// the way out is visible when the sheet opens, it is the first control any
  /// keyboard, D-pad or screen reader reaches, and it only leaves the viewport
  /// once the user has scrolled past it deliberately. Escape and the scrim do
  /// not scroll anywhere.
  Widget _content(BuildContext context) {
    return SafeArea(
      // The sheet sits on the bottom edge, so it consumes the bottom system
      // inset itself — inside the surface, so the surface still reaches the
      // physical edge and no strip of page shows under it.
      //
      // Never `top`: the padding a notch needs is at the top of the *screen*,
      // and applying it here would inset the inside of a panel that is nowhere
      // near it.
      //
      // The bottom inset needs no special case for the keyboard. The platform
      // already reports `padding.bottom` as zero while the keyboard covers the
      // navigation bar, so this adds nothing on top of the lift. That is the
      // double-inset `IuxPageInsets` exists to prevent, and it is why an
      // IuxBottomSheet is a *sibling* of the page and never a child of it.
      top: false,
      // Shrink-wrapping rather than filling: the sheet is as tall as its
      // content until it reaches the cap, and a scroll view forced to the cap
      // would leave a sheet that is mostly empty space covering a page the
      // user still needs.
      child: SingleChildScrollView(
        child: Padding(
          padding: IuxInsets.surface(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _header(context),
              const IuxGap.standard(),
              widget.child,
            ],
          ),
        ),
      ),
    );
  }

  /// The title and the way out, in that order in every direction.
  ///
  /// The title reads first because it says what the sheet is; the dismissal is
  /// the first *control*, so it is what a Tab, a D-pad press or a screen
  /// reader swipe reaches before anything in the content. A way out found only
  /// after twelve swipes through a list is a way out most users never find.
  Widget _header(BuildContext context) {
    final IuxTypographyTheme typography = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);

    final Widget title = IuxSemantics.header(
      label: widget.title,
      child: Text(
        widget.title,
        // No line limit and no ellipsis. A truncated title is a sheet the user
        // cannot identify, and truncation gets worse exactly when someone has
        // enlarged their text.
        style: typography.title.copyWith(color: colors.content.primary),
      ),
    );

    final Widget dismiss = IuxButton(
      label: widget.dismissLabel,
      action: IuxActionDescriptor(
        semantics: IuxActionSemantics(label: widget.dismissLabel),
        // Dismiss, not cancel: closing a sheet does not discard what the user
        // typed into it, and announcing it as a cancellation would suggest
        // work is being thrown away.
        role: IuxActionRole.dismiss,
      ),
      onActivate: widget.onDismissed,
    );

    if (IuxReadableText.shouldStack(context)) {
      // Past roughly 130% text a title and a button stop sharing a line, and
      // the row would either overflow or squeeze the title into a column two
      // characters wide. Stacking keeps both legible and keeps the order.
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[title, const IuxGap.tight(), dismiss],
      );
    }

    return Row(
      // Aligned to the top, so a title that wraps to three lines does not drag
      // the button down to the middle of them.
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: title),
        const IuxGap.horizontal(IuxSpacingStep.md),
        dismiss,
      ],
    );
  }
}

/// The window measurements the sheet needs, and nothing else.
@immutable
class _IuxWindowMetrics {
  const _IuxWindowMetrics({required this.height, required this.keyboard});

  /// The height of the window, not of the box the sheet was given.
  final double height;

  /// How much of the window the software keyboard currently occupies.
  final double keyboard;
}

/// How tall the sheet may be, and how far it must lift itself.
///
/// Extracted so both answers are decided in one place, from named inputs, and
/// can be reasoned about without a widget tree.
@immutable
class _IuxSheetGeometry {
  const _IuxSheetGeometry({required this.lift, required this.maximumHeight});

  /// Resolves the geometry for a sheet occupying a [box] of the [window].
  ///
  /// **The lift is not the keyboard's height.** Whatever laid the sheet out
  /// may already have taken part of the keyboard out of the box it handed
  /// over: a `Scaffold` with the default `resizeToAvoidBottomInset` does
  /// exactly that, and does *not* remove the inset from the `MediaQuery` its
  /// body sees. Adding the full inset on top of that lifts the sheet twice and
  /// leaves a keyboard-sized band of scrim underneath it — which is the single
  /// most common way this component is got wrong.
  ///
  /// So the sheet lifts by the residue: the part of the keyboard that is still
  /// underneath the box it was given.
  ///
  /// **The height is capped at [_kMaximumScreenFraction] of the window**, and
  /// the box does the rest. When a keyboard has taken half the screen the box
  /// is already the smaller of the two, so the cap stops binding and the sheet
  /// simply uses everything above the keyboard — which is the right answer,
  /// because the context the cap was protecting has already been covered by
  /// the keyboard.
  factory _IuxSheetGeometry.of({
    required double box,
    required double window,
    required double keyboard,
  }) {
    // Falls back to the box when no MediaQuery reported a window. A sheet with
    // no cap is wrong; a sheet of zero height is unusable.
    final double screen = window > 0 ? window : box;
    final double alreadyRemoved = math.max(0, screen - box);
    final double lift = math.max(0, keyboard - alreadyRemoved);
    return _IuxSheetGeometry(
      lift: lift,
      maximumHeight: math.max(
        0,
        math.min(screen * _kMaximumScreenFraction, box - lift),
      ),
    );
  }

  /// How far above the bottom of its box the panel sits.
  final double lift;

  /// The tallest the panel may be. Its content decides the rest.
  final double maximumHeight;
}
