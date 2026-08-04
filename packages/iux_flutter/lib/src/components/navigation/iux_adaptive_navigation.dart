import 'package:flutter/widgets.dart';

import '../../accessibility/iux_accessibility.dart';
import '../transient/iux_transient_layer.dart';
import 'iux_bottom_navigation.dart';
import 'iux_navigation_destination.dart';
import 'iux_navigation_rail.dart';

/// The narrowest content IUX claims to support, in logical pixels.
///
/// 320 is the figure `docs/components/bottom-navigation.md` already commits to:
/// below it, five destinations at the 48-pixel target floor no longer fit
/// across a screen, and nothing in the library rescues that arithmetic. It is
/// used here as a budget rather than as a breakpoint — the rail may take the
/// width it needs only while what remains is still a width IUX supports.
///
/// Private, because it is a floor this component applies rather than a value a
/// call site has any reason to read or to change.
const double _minimumContentWidth = 320;

/// Navigation that spends whichever axis the window has to spare.
///
/// ```dart
/// Scaffold(
///   body: IuxAdaptiveNavigation(
///     label: l10n.mainNavigation,
///     selectedIndex: section.index,
///     destinations: destinations,
///     onDestinationSelected: controller.goTo,
///     child: IuxPage(child: body),
///   ),
/// )
/// ```
///
/// **Use it** when an application has one set of top-level sections and runs on
/// more than one shape of window — which on Android is every application, since
/// every phone rotates. It renders [IuxBottomNavigation] or [IuxNavigationRail]
/// and keeps the content beside or above it.
///
/// **Do not use it** to pick an arrangement yourself. There is no parameter for
/// that, and there is not going to be one: a call site that forced the rail
/// would be forcing it on the portrait phone too, which is the one window where
/// the measurement below says it does not fit. If an application genuinely
/// needs one arrangement everywhere, it can use the component for that
/// arrangement directly and own the consequence.
///
/// It is not a `Scaffold` replacement. Put it in `Scaffold.body`, and do not
/// also fill `Scaffold.bottomNavigationBar` — the bar would then exist twice on
/// a phone and once in the wrong place on a tablet.
///
/// ## Where the two overlay layers go
///
/// `IuxModalLayer` **outside** this component, `IuxTransientLayer` **inside**
/// it, in [child]. The two are not symmetric and the asymmetry is the rule: a
/// dialog is a question about the screen underneath, so a user who can change
/// section while it is open answers it about a screen they have left — it must
/// cover the navigation. A notice is something the user is allowed to miss, so
/// it must cost them nothing, and a notice over the navigation costs them every
/// destination for the length of its dwell.
///
/// ```dart
/// Scaffold(
///   body: IuxModalLayer(
///     dialog: state.dialog,
///     child: IuxAdaptiveNavigation(
///       label: l10n.mainNavigation,
///       selectedIndex: section.index,
///       destinations: destinations,
///       onDestinationSelected: controller.goTo,
///       child: IuxTransientLayer(
///         message: state.notice,
///         onDismissed: controller.clearNotice,
///         child: IuxPage(child: body),
///       ),
///     ),
///   ),
/// )
/// ```
///
/// The other order is refused rather than described: see
/// `IuxTransientLayer.debugCheckNotPlacedOver`, which this component asserts on
/// every build.
///
/// ## How the arrangement is chosen
///
/// A bottom bar spends **height**; a rail spends **width**. So the rule is:
/// spend the axis the window has more of, and never spend width the content
/// cannot afford.
///
/// ```text
/// rail  ⟺  available.width >= available.height
///          && (available.width - railWidth >= 320 || the bar is no longer a strip)
/// ```
///
/// Every term is measured rather than assumed.
///
/// `railWidth` is [IuxNavigationRail.widthFor]: the widest destination name at
/// the text size actually in force, not a constant. That is how the text scale
/// enters the decision with the same weight as the width — a 471 × 470 window
/// takes a rail at 100% text and refuses one at 120%, because the same five
/// names then need a wider column.
///
/// The 320 is the narrowest content width IUX supports anywhere. It is a
/// budget, not a breakpoint: it says the rail may take what it needs only while
/// the page beside it stays inside the range the rest of the library was
/// designed for.
///
/// "The bar is no longer a strip" is [IuxAccessibility.prefersStackedLayout],
/// and it is what keeps the budget from inverting the whole rule; the reasoning
/// is with the code that applies it, in `_prefersRail` below.
///
/// ### What was measured, and what fails on either side
///
/// Five short names at 100% text, in the widget-test font — which is wider than
/// a proportional face, so these widths are close to a worst case. The rail
/// measures 130 logical pixels; the bar is 92 tall on a phone and 72 on a
/// wider window.
///
/// On a 412 × 915 phone upright the bar costs 10% of the height and sits under
/// the thumb, while the rail would cost 31% of the width and leave 282 pixels
/// of content — below the floor, so the rule refuses it twice over. Rotate the
/// same phone to 915 × 412 and the bar costs 17% of the *height* against the
/// rail's 14% of the width; at 200% text the bar there measures 360 against a
/// 412-pixel window — 87%, very nearly the whole screen — while the rail costs
/// 26% and leaves 673 pixels. That is the case this component exists for.
///
/// **The Android 600 dp width breakpoint was not adopted.** It is a strong
/// recommendation and it is width-only, which is the term that does not decide
/// this. At 600 × 800 the bar costs 12% of the height and stays where a hand
/// is; at 600 × 400 the same bar costs 23% and the rule has already moved to
/// the rail without needing a breakpoint to say so. Where the two disagree is a
/// **wide portrait** window — a portrait tablet, an unfolded foldable held
/// upright — which Android would give a rail and this gives a bar. That
/// disagreement is a hypothesis, not a measurement: see
/// `docs/components/navigation-rail.md`.
///
/// ## It measures what it was given, not the screen
///
/// The decision reads the constraints this widget receives, so a split-screen
/// window, a panel inside a larger layout and a real device are all measured
/// the same way. A component that asked how big the *display* was would put a
/// rail in a 300-pixel pane on a tablet.
class IuxAdaptiveNavigation extends StatelessWidget {
  /// Creates navigation that adapts to the window it is given.
  ///
  /// No assertions on the arguments. Both arrangements refuse exactly the same
  /// configurations — three to five destinations, distinct names, a current one
  /// inside the set — so whichever is built rejects an invalid set, and the
  /// failure does not depend on the size of the window the developer happened
  /// to be testing on. Restating the rules here would be a third copy that can
  /// disagree with the other two.
  ///
  /// The one check `build` does make is about the tree rather than the
  /// arguments, which is why it cannot live here: whether this component was
  /// placed underneath an `IuxTransientLayer`.
  const IuxAdaptiveNavigation({
    super.key,
    required this.label,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.child,
  });

  /// What this set of destinations is, already localised.
  ///
  /// Passed through to whichever arrangement is built, and announced when a
  /// screen reader enters it. One string for both, because the group is the
  /// same group: a name that changed when the device rotated would tell the
  /// user they had arrived somewhere else.
  final String label;

  /// The destinations, in the order they are shown and read.
  ///
  /// Three to five, with distinct names. Order is the caller's and is the same
  /// in both arrangements: rotating a device must not reshuffle an application.
  final List<IuxNavigationDestination> destinations;

  /// Which destination the user is currently in.
  ///
  /// Owned by the parent, in both arrangements.
  final int selectedIndex;

  /// Called with the index of the destination the user chose.
  ///
  /// The same callback whichever arrangement is showing, and it carries the
  /// same index. A parent never has to ask which one it is talking to.
  final ValueChanged<int> onDestinationSelected;

  /// The screen the navigation belongs to, and anything painted over it.
  ///
  /// Positioned beside the rail or above the bar. It receives the space
  /// navigation did not take, which is why this component owns the frame rather
  /// than being dropped into a slot: the two arrangements put the content in
  /// different places, and a caller that had to place it themselves would be
  /// making the adaptive decision a second time.
  ///
  /// **This is where `IuxTransientLayer` goes.** Placed here, a notice is laid
  /// out inside the box navigation left over, so it can cover the page and
  /// cannot reach the destinations. Placed around this component it covers them
  /// for the length of a dwell, which is asserted against rather than
  /// documented — see the class comment above.
  ///
  /// Nothing to configure if it is an `IuxPage`: leave it on the default
  /// `IuxPageInsets.handled`. Each arrangement consumes the display inset on
  /// the edge it occupies and then removes that edge from the padding this
  /// child is given, so a page that handles its own insets sees exactly the
  /// ones still exposed — and only those. The earlier advice to pass
  /// `IuxPageInsets.none` was worse than the problem: it also gave up the top
  /// inset, and the content read out from under the status bar.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Checked here as well as in the two arrangements, so the error names the
    // component the caller actually wrote. Reached through the bar it would
    // report a widget this call site never mentions — and on a wide window it
    // would report the rail instead, so one mistake would be described two
    // different ways depending on the device it was found on.
    assert(IuxTransientLayer.debugCheckNotPlacedOver(context));

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (_prefersRail(context, constraints)) {
          final bool startIsLeft =
              Directionality.of(context) == TextDirection.ltr;
          return Row(
            // Stretched, so the rail runs the full height of the window
            // rather than the height of its five destinations. A rail that
            // stopped halfway down leaves its own edge line stopping with it,
            // and the boundary between navigation and content disappears
            // exactly where the content is longest.
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              IuxNavigationRail(
                label: label,
                destinations: destinations,
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
              ),
              Expanded(
                child: MediaQuery.removePadding(
                  context: context,
                  // The rail already stands on the start inset, so for the
                  // content that inset no longer exists. Left in place it
                  // would be applied twice from one cutout — once by the rail
                  // that is covering it and once by a page that still
                  // believes it is exposed — and the content would sit a
                  // notch's width away from a rail it is supposed to touch.
                  removeLeft: startIsLeft,
                  removeRight: !startIsLeft,
                  child: child,
                ),
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              // The bar consumes the bottom inset itself, so the content
              // above is no longer exposed to it. Same double-inset,
              // different edge.
              child: MediaQuery.removePadding(
                context: context,
                removeBottom: true,
                child: child,
              ),
            ),
            ConstrainedBox(
              // Bounded by the window, which is what lets the bar's own
              // degradation happen: given unbounded height a scrolling bar
              // simply takes all of it, and the content above would be laid
              // out at zero height without ever being told why. This is also
              // what `Scaffold` does with its own navigation slot.
              constraints: BoxConstraints(maxHeight: constraints.maxHeight),
              child: IuxBottomNavigation(
                label: label,
                destinations: destinations,
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Whether the rail is the arrangement this window can afford.
  ///
  /// Returns false for an unbounded constraint in either axis. A width with no
  /// end cannot be short of anything, and a component that answered "rail"
  /// there would be reasoning about a window that has not been decided yet.
  bool _prefersRail(BuildContext context, BoxConstraints constraints) {
    if (!constraints.hasBoundedWidth || !constraints.hasBoundedHeight) {
      return false;
    }
    // Height is the scarcer axis only when the window is at least as wide as it
    // is tall. Anything taller than it is wide has height to give and width it
    // does not, which is every phone held upright.
    if (constraints.maxWidth < constraints.maxHeight) return false;

    final double remaining = constraints.maxWidth -
        IuxNavigationRail.widthFor(context, destinations);
    if (remaining >= _minimumContentWidth) return true;

    // The budget failed, and the interesting question is what the alternative
    // costs. Below the stacked threshold the bar is a compact strip — 72 to 92
    // pixels — so handing the window back to it is a real choice and the budget
    // is worth respecting.
    //
    // Above the threshold the bar is not a strip; it is a full-width list of
    // destinations, and on a short landscape window it takes the whole of the
    // scarce axis. Measured on a 640 × 320 window at 300% text: the rail leaves
    // 288 pixels of content — under the budget, and the reason the budget said
    // no — while the bar leaves **zero**. Choosing the bar there is choosing the
    // arrangement that spends the axis the window has least of, which is the one
    // thing this component exists to avoid.
    //
    // So the budget is a rule about the rail only while the bar is still the
    // cheap option. Once it is not, the rail wins on a landscape window even
    // when it leaves the content narrower than IUX would like — narrow content
    // is a degradation, and no content is a defect.
    return IuxAccessibility.of(context).prefersStackedLayout;
  }
}
