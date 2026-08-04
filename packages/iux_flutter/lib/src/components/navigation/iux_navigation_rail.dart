import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../accessibility/iux_accessibility.dart';
import '../../accessibility/iux_focus.dart';
import '../../accessibility/iux_semantics.dart';
import '../../layout/iux_content_width.dart';
import '../transient/iux_transient_layer.dart';
import 'iux_navigation_destination.dart';
import 'iux_navigation_tokens.dart';

/// The fewest destinations a rail may carry.
///
/// Three, the same floor `IuxBottomNavigation` holds, and for the same reason:
/// two permanent places are one axis, and a strip of the screen reserved for
/// one axis is a toggle that has been given the status of a navigation system.
///
/// It is also the range `IuxAdaptiveNavigation` needs. That component renders
/// one set of destinations as a bar or as a rail depending on the window, so a
/// set the rail accepted and the bar refused would be a configuration that
/// worked until the user rotated the device.
const int _minimumDestinations = 3;

/// The most destinations a rail may carry.
///
/// Five, again matching the bar, and this time the arithmetic is vertical
/// rather than horizontal. The rail's own case is a phone in landscape: about
/// 412 logical pixels of height, of which the display cutout and the gesture
/// area take some. Measured on a 915 × 412 window, a destination is 72 pixels
/// tall at 100% text and 116 at 200%, so five of them need 580 against the 412
/// there are — they already scroll, and they start scrolling at about 125%. A
/// sixth would be a destination that exists only for users who have not
/// enlarged their text.
const int _maximumDestinations = 5;

/// The permanent way between top-level sections, along the start edge.
///
/// ```dart
/// Row(
///   children: <Widget>[
///     IuxNavigationRail(
///       label: l10n.mainNavigation,
///       selectedIndex: section.index,
///       destinations: destinations,
///       onDestinationSelected: controller.goTo,
///     ),
///     Expanded(
///       // The rail stands on the start inset, so the page beside it must not
///       // apply that one again. It still owns the other three.
///       child: MediaQuery.removePadding(
///         context: context,
///         removeLeft: true,
///         child: IuxPage(child: body),
///       ),
///     ),
///   ],
/// )
/// ```
///
/// `IuxAdaptiveNavigation` does that handoff itself, which is one of several
/// reasons to prefer it over assembling the row by hand.
///
/// **Use it** for the same three to five permanent sections
/// `IuxBottomNavigation` describes, on a window that has width to spare and
/// height it cannot spare — a phone in landscape, a tablet, a desktop window.
/// It is the same navigation, standing up.
///
/// **Do not use it** on a window where taking its width would leave the content
/// too narrow to read. That decision is a measurement, not a guess, and
/// `IuxAdaptiveNavigation` is where it is made; a rail placed by hand on a
/// 320-pixel portrait phone will render, and it will leave 192 pixels for
/// everything the application actually does — 80 once the user doubles their
/// text.
///
/// Everything `IuxBottomNavigation` refuses, this refuses identically: no
/// icon-only form, no disabled destination, no action among the places, no
/// navigation performed by the component. Those decisions belong to the
/// destination and to the standard, not to the arrangement, and a rail that
/// relaxed one of them would make the choice between the two arrangements a
/// choice about accessibility.
///
/// ## It is as wide as its longest name, and no wider
///
/// The rail draws every name, always — see [IuxNavigationDestination.label].
/// Unlike the bar it is not forced into a column a fifth of the screen wide, so
/// it does not need a second arrangement to keep names whole: it measures them
/// and takes the width the widest one needs.
///
/// That width is capped, because an unbounded one is an overflow waiting for a
/// call site to write a sentence where a name belongs. The cap is the narrowest
/// reading measure IUX already defines — [IuxContentWidth.narrow], about 35
/// characters — and it scales with the user's text size rather than being a
/// pixel count that silently shrinks when they enlarge their text. Past the cap
/// a name wraps, exactly as it would in the bar.
///
/// ## It does not navigate
///
/// The rail reports which destination the user chose. It pushes no route, owns
/// no navigator, and keeps no index of its own — Component Standard §1 and §3,
/// and the reasoning is the same one `docs/components/bottom-navigation.md`
/// sets out at length.
///
/// ## How the current destination is announced
///
/// Identically to the bar, deliberately: a checked member of a mutually
/// exclusive group inside a named [SemanticsRole.radioGroup], an indicator that
/// is a bounded shape rather than a hue, and optionally a filled variant of the
/// glyph. A user who learns the announcement on a phone hears the same thing on
/// a tablet.
class IuxNavigationRail extends StatelessWidget {
  /// Creates a navigation rail.
  ///
  /// The assertions are the bar's, and are here rather than deferred to the
  /// adaptive component because a rail used directly has to refuse the same
  /// configurations. A rule enforced in one of two places is a rule that has
  /// already stopped being one.
  IuxNavigationRail({
    super.key,
    required this.label,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
  })  : assert(
          label.length > 0,
          'A navigation rail must be named. Unnamed, a screen reader announces '
          'a group of five controls and refuses to say what the group is, so '
          'the user hears five section names with nothing tying them together.',
        ),
        assert(
          destinations.length >= _minimumDestinations,
          'A navigation rail needs at least three destinations. Two is a '
          'toggle wearing a navigation system: it takes a permanent column of '
          'the screen to express one axis.',
        ),
        assert(
          destinations.length <= _maximumDestinations,
          'A navigation rail holds at most five destinations. On the window '
          'this component exists for — a phone in landscape — five already '
          'scroll once text is enlarged, so a sixth is a destination that '
          'exists only for users who have not enlarged theirs.',
        ),
        assert(
          selectedIndex >= 0 && selectedIndex < destinations.length,
          'The current destination is not one of the destinations, so the rail '
          'would mark none of them. A rail showing no current destination '
          'while the application believes it has one is how a user ends up '
          'unable to tell which section they are in.',
        ),
        assert(
          destinations
                  .map((IuxNavigationDestination d) => d.label)
                  .toSet()
                  .length ==
              destinations.length,
          'Two destinations share a name. They are indistinguishable to a '
          'screen reader and to anyone reading the rail, so the user is shown '
          'a choice they cannot make.',
        );

  /// What this set of destinations is, already localised.
  ///
  /// Announced when a screen reader enters the rail — "Main navigation" — so
  /// the names that follow are heard as sections of an application rather than
  /// as loose controls. Not drawn: a visible heading over a column of five
  /// names would spend rail width saying what the rail's position already says.
  final String label;

  /// The destinations, in the order they are shown and read.
  ///
  /// Three to five, with distinct names, both asserted. Order is the caller's
  /// and is never sorted here: position is what users remember, and it must
  /// also match the order the same destinations take in the bar, or rotating
  /// the device would reshuffle the application.
  final List<IuxNavigationDestination> destinations;

  /// Which destination the user is currently in.
  ///
  /// Owned by the parent. The rail renders it and never changes it.
  final int selectedIndex;

  /// Called with the index of the destination the user chose.
  ///
  /// Called for the current destination too, for the reason
  /// `IuxBottomNavigation.onDestinationSelected` gives: returning to the top of
  /// the section you are already in is a real gesture, and only the parent
  /// knows whether it means anything here.
  final ValueChanged<int> onDestinationSelected;

  /// The width a rail carrying [destinations] takes at [context].
  ///
  /// Public because `IuxAdaptiveNavigation` cannot choose between a rail and a
  /// bar without it: the choice turns on what the content would have left, and
  /// what the rail costs depends on the names the application chose and on the
  /// text size the user chose. A constant here would be wrong for one of them
  /// and usually for both. It is public rather than internal for the same
  /// reason: an application that builds its own three-pane frame is making the
  /// same decision, and the alternative is that it guesses.
  ///
  /// Measured with a [TextPainter] on the resolved label style rather than by
  /// laying the rail out, which is the same technique `IuxAppBar` uses to
  /// decide whether its title still fits beside the controls.
  ///
  /// The style measured is the one the [Text] will actually be painted with —
  /// the ambient [DefaultTextStyle] with the label style merged over it, which
  /// is exactly what [Text] does with a style that inherits. Measuring the
  /// label style alone is a quarter of a pixel per character too narrow,
  /// because letter spacing arrives from the ambient style and nothing in the
  /// typography theme overrides it. That is enough to wrap the longest name in
  /// the rail that was sized for it: the one failure this measurement exists to
  /// prevent, produced by the measurement itself.
  ///
  /// It follows that [context] must be one the rail will be built under. A
  /// context outside a `DefaultTextStyle` the rail is inside would measure a
  /// different font.
  ///
  /// Excludes display insets: a cutout along the start edge widens the rail by
  /// as much again, and the adaptive component's width budget is that much
  /// optimistic. On the windows where the rail is chosen at all, the difference
  /// is tens of pixels against hundreds to spare.
  static double widthFor(
    BuildContext context,
    List<IuxNavigationDestination> destinations,
  ) {
    final IuxBottomNavigationTokens tokens =
        IuxBottomNavigationResolver.resolve(context);
    final IuxAccessibility accessibility = IuxAccessibility.of(context);
    final TextDirection direction = Directionality.of(context);
    final TextStyle style =
        DefaultTextStyle.of(context).style.merge(tokens.labelStyle);

    // The glyph and its indicator are the floor on content width: a rail
    // narrower than the mark it draws would clip the one thing that says where
    // the user is.
    double widest = tokens.iconSize + tokens.indicatorPadding.horizontal;
    for (final IuxNavigationDestination destination in destinations) {
      final TextPainter painter = TextPainter(
        text: TextSpan(text: destination.label, style: style),
        textDirection: direction,
        textScaler: accessibility.textScaler,
      )..layout();
      widest = math.max(widest, painter.width);
      painter.dispose();
    }

    final double natural =
        widest + 2 * (tokens.horizontalPadding + tokens.focusReservation);
    final double cap =
        IuxContentWidthResolver.maxWidthFor(context, IuxContentWidth.narrow) ??
            double.infinity;

    // The target floor is applied last, so a cap can never pull the rail below
    // the width a finger needs. A name longer than the cap wraps instead.
    return math.max(tokens.minExtent, math.min(natural, cap));
  }

  @override
  Widget build(BuildContext context) {
    // The bar's check, and the rail takes it for the reason it takes the bar's
    // assertions: a rule enforced in one of two arrangements has stopped being
    // one. A message is centred on the reading measure, so on a wide window at
    // 100% text it clears a rail on the start edge and the overlap looks like
    // something that cannot happen here — until the reading measure grows past
    // the window at 200%, or the rail scrolls and puts a destination on the
    // bottom edge. A defect that appears only once the user enlarges their text
    // is worse than one that is always there.
    assert(IuxTransientLayer.debugCheckNotPlacedOver(context));

    final IuxBottomNavigationTokens tokens =
        IuxBottomNavigationResolver.resolve(context);
    final bool leadingEdgeIsLeft =
        Directionality.of(context) == TextDirection.ltr;

    final Widget column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int index = 0; index < destinations.length; index++)
          _IuxRailDestination(
            destination: destinations[index],
            current: index == selectedIndex,
            onSelected: () => onDestinationSelected(index),
          ),
      ],
    );

    return IuxSemantics.radioGroup(
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.background,
          // On the end edge, and directional so it stays there when the user
          // reads right to left. This line is where navigation stops and
          // content starts; without it the first column of the page reads as
          // part of the rail.
          border: BorderDirectional(
            end: BorderSide(
              color: tokens.separator,
              width: tokens.separatorWidth,
            ),
          ),
        ),
        // The rail runs the full height of what it is given, so it owns the
        // insets at both ends as well as the one along the edge it sits on.
        // The far edge belongs to the content beside it.
        child: SafeArea(
          left: leadingEdgeIsLeft,
          right: !leadingEdgeIsLeft,
          child: SizedBox(
            width: widthFor(context, destinations),
            // Scrollable, and a degradation rather than a feature — the same
            // one the bar makes when its destinations no longer fit. Five
            // destinations at 200% text need more height than a phone in
            // landscape has. A destination the user must scroll to is one they
            // may not find; a destination that is not rendered is one they
            // certainly will not.
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: column,
            ),
          ),
        ),
      ),
    );
  }
}

/// One destination in a rail: a target, a glyph, a name, and at most one badge.
///
/// Private, and it stays private for the reason the bar's equivalent does: the
/// target floor, the reserved indicator space, the merged announcement and the
/// selection semantics must not be able to drift between arrangements.
class _IuxRailDestination extends StatefulWidget {
  const _IuxRailDestination({
    required this.destination,
    required this.current,
    required this.onSelected,
  });

  final IuxNavigationDestination destination;
  final bool current;
  final VoidCallback onSelected;

  @override
  State<_IuxRailDestination> createState() => _IuxRailDestinationState();
}

class _IuxRailDestinationState extends State<_IuxRailDestination> {
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
    final IuxBottomNavigationTokens tokens =
        IuxBottomNavigationResolver.resolve(
      context,
      current: widget.current,
      pressed: _pressed,
      hovered: _hovered,
    );

    final Widget interactive = GestureDetector(
      // Opaque so the whole width of the rail responds, including the space the
      // focus ring reserves, and not only the glyph painted in the middle.
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
          // responds rather than to the part that is painted. Width normally
          // comes from the rail; this is what keeps a short destination from
          // collapsing below the floor in height.
          constraints: BoxConstraints(
            minWidth: tokens.minExtent,
            minHeight: tokens.minExtent,
          ),
          child: IuxFocusable(
            onActivate: widget.onSelected,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.horizontalPadding,
                vertical: tokens.verticalPadding,
              ),
              child: _IuxRailDestinationContent(
                destination: widget.destination,
                current: widget.current,
                tokens: tokens,
              ),
            ),
          ),
        ),
      ),
    );

    final Widget region = Stack(
      // Passthrough, so the region that responds is the whole strip the rail
      // gave this destination rather than only the box its glyph and name
      // happen to need.
      fit: StackFit.passthrough,
      children: <Widget>[
        // Behind the content rather than over it, so the tint never reduces the
        // contrast of the name it is reacting to.
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: tokens.overlayOpacity,
              duration: tokens.motion.duration,
              curve: tokens.motion.curve,
              child: DecoratedBox(
                decoration: BoxDecoration(color: tokens.overlayColor),
              ),
            ),
          ),
        ),
        interactive,
      ],
    );

    // A bare `Semantics` rather than `IuxSemantics.selection`, the deviation
    // `IuxListItem` recorded first and `IuxBottomNavigation` repeated:
    // `IuxSemantics.selection` excludes its subtree, which would delete the
    // badge from the interface of every screen-reader user. The properties set
    // here are exactly the ones it gives `IuxSelectionRole.radio`.
    return MergeSemantics(
      child: Semantics(
        container: true,
        enabled: true,
        // "Checked", not "selected". A checked node is announced in both
        // states, so a user hears "not checked" at the destinations they are
        // not in rather than sweeping the rail for the one that said something.
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
}

/// The content of a rail destination, in reading order.
///
/// One arrangement, not two. The bar reflows because its columns are a fixed
/// fraction of the screen and stop holding a word; the rail measured its own
/// width from those words, so there is nothing for a second arrangement to
/// rescue. Glyph beside name would only make the rail wider by the width of the
/// glyph, and every pixel of that comes out of the content.
class _IuxRailDestinationContent extends StatelessWidget {
  const _IuxRailDestinationContent({
    required this.destination,
    required this.current,
    required this.tokens,
  });

  final IuxNavigationDestination destination;
  final bool current;
  final IuxBottomNavigationTokens tokens;

  @override
  Widget build(BuildContext context) {
    final Widget? badge = destination.badge;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _IuxRailIndicator(
          icon: current
              ? destination.selectedIcon ?? destination.icon
              : destination.icon,
          current: current,
          tokens: tokens,
        ),
        SizedBox(height: tokens.gap),
        // No line limit and no ellipsis, at any text scale. A truncated
        // destination is a place the user cannot identify, and truncation gets
        // worse exactly when someone has enlarged their text in order to read.
        Text(
          destination.label,
          style: tokens.labelStyle,
          textAlign: TextAlign.center,
        ),
        // Under the name rather than beside it, as in the bar. The rail's width
        // was measured from the names; a badge sharing their line would either
        // widen the rail for every destination or squeeze the one name it sits
        // beside.
        if (badge != null) ...<Widget>[
          SizedBox(height: tokens.gap),
          badge,
        ],
      ],
    );
  }
}

/// The glyph, and the shape that marks it as the current destination.
class _IuxRailIndicator extends StatelessWidget {
  const _IuxRailIndicator({
    required this.icon,
    required this.current,
    required this.tokens,
  });

  final IconData icon;
  final bool current;
  final IuxBottomNavigationTokens tokens;

  @override
  Widget build(BuildContext context) => Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // Faded in rather than added, so the space it occupies is reserved in
          // both states. An indicator that appeared by growing would resize the
          // destination, and in a column of stretched cells that moves the
          // name under it.
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: current ? 1 : 0,
                duration: tokens.motion.duration,
                curve: tokens.motion.curve,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: tokens.indicatorFill,
                    borderRadius: BorderRadius.circular(tokens.indicatorRadius),
                    border: Border.all(
                      color: tokens.indicatorBorder,
                      width: tokens.indicatorBorderWidth,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: tokens.indicatorPadding,
            // Removed from the semantic tree, not described. The name beside
            // the glyph already says what this destination is, and a screen
            // reader that announced both would read every section twice.
            child: IuxSemantics.decorative(
              child: Icon(
                icon,
                size: tokens.iconSize,
                color: tokens.iconColor,
                // Already scaled once, by the resolver, through the same
                // runtime every other IUX component reads.
                applyTextScaling: false,
              ),
            ),
          ),
        ],
      );
}
