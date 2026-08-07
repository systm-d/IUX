import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../accessibility/iux_accessibility.dart';
import '../../layout/iux_material_ground.dart';
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
///          && available.width > railWidth
///          && (available.width - railWidth >= 320 || the bar is no longer a strip)
/// ```
///
/// The middle term looks implied by the last one and is not. It asks whether
/// the rail *fits*, where the last one asks how much it *leaves*, and a
/// remainder that has gone negative fails a budget test exactly as a small
/// positive one does — so without it the rule answered "narrow but affordable"
/// to a rail wider than the screen it was drawn on. See `_prefersRail`, and
/// `IUX-RAIL-OVERFLOW-001` for the 36 pixels it cost.
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
///
/// ## It needs a bounded box, and now says so
///
/// An axis with no end cannot be compared with anything, so a box that is
/// unbounded in either direction is refused in debug — see
/// `_debugCheckHasBoundedBox`. Both terms of the rule are comparisons against
/// the width available, and neither has an answer when that width is infinite.
///
/// It used to fall through to the bar instead, which is the phone arrangement
/// and was reached without a measurement of any kind. That failed too, but only
/// afterwards and in the framework's words: measured, one
/// `SingleChildScrollView` around this component produced 27 exceptions, the
/// first of them *RenderFlex children have non-zero flex but incoming height
/// constraints are unbounded*, reported against a `Column` this component owns
/// and the caller never wrote. Nothing in it said navigation, said rail, or
/// said what to do. The refusal below is the same failure, named.
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
  /// The two checks `build` does make are about the tree and the box rather
  /// than the arguments, which is why neither can live here: whether this
  /// component was placed underneath an `IuxTransientLayer`, and whether the
  /// box it was handed has an end in both directions.
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

    // Around the whole arrangement, not around [child]: the destinations are
    // the child's siblings, so a medium established inside the page never
    // reaches them. Measured before this line existed, with this component as
    // the route root — the page read against IUX's body style and the two
    // destination labels read against Flutter's fallback, monospace and all.
    // See `IuxMaterialGround`.
    return IuxMaterialGround(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          // Before the rule rather than inside it: an unbounded axis is not a
          // window this component may choose an arrangement for, and the choice
          // it used to make there was the bar, reached without a measurement.
          assert(_debugCheckHasBoundedBox(constraints));

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
      ),
    );
  }

  /// Whether [constraints] describe a box an arrangement can be chosen for.
  ///
  /// Returns true when both axes are bounded, and throws a [FlutterError]
  /// otherwise. The whole body is inside an assertion, so a release build
  /// carries none of it and keeps the old behaviour — the bar, chosen by
  /// elimination in `_prefersRail`, which is the only arrangement that does not
  /// need a width to be decided.
  ///
  /// Private, and it stays private: a caller who wants to make this decision
  /// themselves needs [IuxNavigationRail.widthFor], which is already public and
  /// answers the question this one only guards.
  ///
  /// **What it replaces.** The rule below is two comparisons against the width
  /// available — is it at least the height, and is it more than the rail costs
  /// — and an infinite width answers both of them "yes" for a reason that has
  /// nothing to do with the window. So the component answered "bar" instead, a
  /// measurement it had not made, and the failure surfaced one layer down as
  /// *RenderFlex children have non-zero flex but incoming height constraints
  /// are unbounded*: 27 exceptions from a single `SingleChildScrollView`,
  /// naming a `Column` that lives in this file and that the caller never wrote.
  ///
  /// The page for this component claimed the case was asserted from IUX-025
  /// until IUX-042 struck the claim. This is the assertion, written rather than
  /// the sentence corrected a second time: the alternative was a loud failure
  /// in the framework's words, and `PROJECT_PROMPT.md` §22 and §52 ask for one
  /// in ours.
  static bool _debugCheckHasBoundedBox(BoxConstraints constraints) {
    assert(() {
      if (constraints.hasBoundedWidth && constraints.hasBoundedHeight) {
        return true;
      }
      final String axes =
          !constraints.hasBoundedWidth && !constraints.hasBoundedHeight
              ? 'neither a width nor a height'
              : constraints.hasBoundedWidth
                  ? 'no height'
                  : 'no width';
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('IuxAdaptiveNavigation was given $axes.'),
        ErrorDescription(
          'It chooses between a bottom bar and a rail by comparing the width '
          'it was offered with the height, and with the width the rail\'s own '
          'destination names need at the text size in force. An axis with no '
          'end is not short of anything, so neither comparison has an answer '
          'and there is no arrangement to choose.\n'
          '\n'
          'A scroll view is the usual cause, and it offers an unbounded '
          'height. Before this check the component took the bar there — the '
          'phone arrangement, on a window nobody had measured — and the '
          'layout then failed anyway, one level down, with "RenderFlex '
          'children have non-zero flex but incoming height constraints are '
          'unbounded" reported against a Column inside this component.',
        ),
        ErrorHint(
          'Put IuxAdaptiveNavigation in Scaffold.body, or in any box with a '
          'width and a height: a SizedBox, an Expanded inside a Column, a '
          'SizedBox.expand. It is the frame for a screen, so it needs the '
          'screen\'s box; it is not content, and content is the only thing '
          'that belongs in a scroll view.\n'
          '\n'
          'To show a rail as a specimen — which is what apps/catalog does — '
          'give it a box of its own inside the scroll view, or place '
          'IuxNavigationRail directly and measure with '
          'IuxNavigationRail.widthFor.',
        ),
        DiagnosticsProperty<BoxConstraints>(
          'The offending constraints were',
          constraints,
        ),
      ]);
    }());
    return true;
  }

  /// Whether the rail is the arrangement this window can afford.
  ///
  /// Returns false for an unbounded constraint in either axis, which in debug
  /// is unreachable — [_debugCheckHasBoundedBox] has already thrown. It stays
  /// because a release build has no assertions: the bar is then the only
  /// arrangement that can be chosen without a width, and choosing it is still
  /// better than measuring a rail against infinity.
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

    // Whether the rail *fits* is a different question from how much it leaves,
    // and the rule below only ever asked the second one. A rail wider than the
    // window it is in leaves a **negative** remainder, and every comparison
    // against a positive budget answers a negative number exactly as it
    // answers a small positive one — so the case where the rail is not an
    // arrangement at all read as the case where it is merely a tight one.
    // The audit measured it at 300% in a 360 x 320 box, where the catalog's own
    // destination names put the rail at 396 pixels: the Row overflowed by 36
    // and the content beside it was laid out at zero. Re-measured against the
    // arithmetic rather than against one font — five short names cost 354 at
    // 300% in the widget-test face — a landscape box 36 pixels narrower than
    // whatever the rail costs overflows by exactly 36, and one 100 narrower by
    // exactly 100. The overflow is the deficit; the font only decides where the
    // deficit starts.
    //
    // Nothing below can rescue it. The rail's width is the width its names
    // need, and clamping it would clip the destination the user is looking
    // for, so a window this narrow has no rail in it and the question ends
    // here. The bar is then the answer by elimination rather than on merit,
    // and it is a real answer: it degrades on purpose, it is bounded by the
    // window, and every destination stays reachable.
    //
    // **The floor is zero, and deliberately not more.** A window this small at
    // this text scale has no arrangement that leaves a usable page — measured
    // on 360 x 320 at 300%, five short names put the rail at 354 and the page
    // at six pixels wide, while the bar on the same window takes all 320 and
    // leaves the page none. Raising this floor to a touch target would trade
    // the first for the second, which is not an improvement, and the real
    // answer is the one the pilot's findings point at: something has to own
    // the total and scroll the whole frame. This term fixes the case that is
    // unambiguously wrong — a rail wider than the screen it is drawn on — and
    // claims nothing about the case where nothing fits.
    if (remaining <= 0) return false;

    // The budget failed, and the interesting question is what the alternative
    // costs. Below the stacked threshold the bar is a compact strip — 72 to 92
    // pixels — so handing the window back to it is a real choice and the budget
    // is worth respecting.
    //
    // Above the threshold the bar is not a strip; it is a full-width list of
    // destinations, and on a short landscape window it takes the whole of the
    // scarce axis. Measured on a 640 × 320 window at 300% text: the rail leaves
    // 286 pixels of content — under the budget, and the reason the budget said
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
