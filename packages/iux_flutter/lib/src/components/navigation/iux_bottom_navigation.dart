import 'package:flutter/widgets.dart';

import '../../accessibility/iux_focus.dart';
import '../../accessibility/iux_semantics.dart';
import '../status/iux_badge.dart';
import '../transient/iux_transient_layer.dart';
import 'iux_navigation_destination.dart';
import 'iux_navigation_tokens.dart';

/// The fewest destinations a bar may carry.
///
/// Two destinations are a toggle wearing a navigation bar: the user sees a
/// choice of two permanent places where the interface only has one axis, and a
/// segmented control or a tab strip says that in less space and less
/// prominence.
const int _minimumDestinations = 3;

/// The most destinations a bar may carry.
///
/// Six 53-pixel columns on a 320-pixel screen is below the target floor before
/// anything is drawn in them, and the names get shorter and shorter until they
/// stop being names. A sixth top-level section is a menu, or evidence that two
/// of the five belong together.
const int _maximumDestinations = 5;

/// The permanent way between the top-level sections of an application.
///
/// ```dart
/// Scaffold(
///   body: IuxPage(
///     // The bar below handles the bottom inset itself.
///     insets: IuxPageInsets.topOnly,
///     child: body,
///   ),
///   bottomNavigationBar: IuxBottomNavigation(
///     label: l10n.mainNavigation,
///     selectedIndex: section.index,
///     destinations: <IuxNavigationDestination>[
///       IuxNavigationDestination(label: l10n.home, icon: Icons.home_outlined),
///       IuxNavigationDestination(
///         label: l10n.messages,
///         icon: Icons.mail_outline,
///         badge: IuxBadge.count(
///           count: l10n.formatCount(unread),
///           label: l10n.unreadMessages(unread),
///         ),
///       ),
///       IuxNavigationDestination(label: l10n.account, icon: Icons.person_outline),
///     ],
///     onDestinationSelected: controller.goTo,
///   ),
/// )
/// ```
///
/// **Use it** for three to five sections that exist for the whole life of the
/// application, that a user moves between rather than through, and that are all
/// reachable at all times. The bar's value is that it is always there and
/// always says where "there" is.
///
/// **Do not use it** for steps of a task — a checkout, a wizard — where going
/// "back" means something and the sections are not peers. Do not use it for
/// filtering or switching a view within one section: that is a tab strip, which
/// belongs inside the section rather than under it. Do not use it for two
/// destinations, or six; both are asserted, and both are a different component.
/// Do not use it for actions: a destination is a place, and a bar that mixes
/// "Home" with "New message" makes the user guess which taps will take them
/// somewhere they have to come back from.
///
/// ## It does not navigate
///
/// The bar reports which destination the user chose. It does not push a route,
/// does not own a navigator, and does not keep an index of its own. That is not
/// an omission: only the application knows whether a section has its own
/// history to restore, whether the choice must be confirmed, or whether the
/// user is allowed to leave the screen they are on at all. A component that
/// navigated would be making that decision on evidence it does not have.
///
/// ```dart
/// // Wrong: the component owns where the user is.
/// IuxBottomNavigation(onDestinationSelected: (int i) => Navigator.push(...))
///
/// // Right: the parent owns it and tells the bar what to render.
/// IuxBottomNavigation(
///   selectedIndex: state.section,
///   onDestinationSelected: controller.goTo,
/// )
/// ```
///
/// If the parent does not re-render with a new [selectedIndex], the indicator
/// does not move — which is correct, because a bar that marked the new
/// destination and then failed to reach it would be showing the user something
/// untrue.
///
/// ## Every destination is named, always
///
/// There is no icon-only mode and no "label the current one" mode. See
/// [IuxNavigationDestination.label] for why, and the component document for
/// what that costs at 200% text.
///
/// The cost is paid by changing the arrangement rather than by hiding the
/// names: below roughly 130% text the destinations share one row as columns of
/// glyph-over-name; above it they stack, each one a full-width row of
/// glyph-beside-name. That threshold is the same runtime signal `IuxListItem`
/// uses to move a value under its title, and the reason is the same — a fifth
/// of a 320-pixel screen cannot hold an enlarged word, and a row that tries
/// breaks "Notifications" across four lines in the middle of a syllable.
///
/// ## How the current destination is announced
///
/// Colour is never the signal. The current destination is marked three ways,
/// and only one of them is a hue:
///
/// 1. **In the semantics**, as a checked member of a mutually exclusive group —
///    exactly the properties `IuxSemantics.selection` gives a radio. A screen
///    reader announces "checked" or "not checked" at *every* destination, so a
///    user learns where they are from the one they land on rather than by
///    sweeping the whole bar looking for the one that said something.
/// 2. **As a shape**: a filled, outlined indicator behind the glyph. Its
///    presence survives a monochrome screen; the outline is drawn as well as
///    the fill because surface contrast alone is deliberately gentle in IUX.
/// 3. **Optionally as a different glyph**, through
///    [IuxNavigationDestination.selectedIcon].
///
/// The indicator's space is reserved whether or not it is drawn, so choosing a
/// destination never resizes it — in a bar of equal columns, one column
/// changing width moves all of them.
class IuxBottomNavigation extends StatelessWidget {
  /// Creates a bottom navigation bar.
  ///
  /// The assertions here catch the contradictions that can be decided from the
  /// arguments alone. Quietly repairing them would hide that the caller
  /// believed something untrue about their own navigation.
  IuxBottomNavigation({
    super.key,
    required this.label,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
  })  : assert(
          label.length > 0,
          'A navigation bar must be named. Unnamed, a screen reader announces '
          'a group of five controls and refuses to say what the group is, so '
          'the user hears five section names with nothing tying them together.',
        ),
        assert(
          destinations.length >= _minimumDestinations,
          'A bottom navigation bar needs at least three destinations. Two is a '
          'toggle wearing a navigation bar: it takes a permanent strip of the '
          'screen to express one axis. Use a tab strip or a segmented control.',
        ),
        assert(
          destinations.length <= _maximumDestinations,
          'A bottom navigation bar holds at most five destinations. A sixth '
          'column is below the touch-target floor on a 320-pixel screen before '
          'anything is drawn in it, and its name has to shrink until it stops '
          'being a name. A sixth top-level section is a menu, or evidence that '
          'two of the five belong together.',
        ),
        assert(
          selectedIndex >= 0 && selectedIndex < destinations.length,
          'The current destination is not one of the destinations, so the bar '
          'would mark none of them. A bar showing no current destination while '
          'the application believes it has one is how a user ends up unable to '
          'tell which section they are in.',
        ),
        assert(
          destinations
                  .map((IuxNavigationDestination d) => d.label)
                  .toSet()
                  .length ==
              destinations.length,
          'Two destinations share a name. They are indistinguishable to a '
          'screen reader and to anyone reading the bar, so the user is shown a '
          'choice they cannot make.',
        );

  /// What this set of destinations is, already localised.
  ///
  /// Announced when a screen reader enters the bar — "Main navigation" — so the
  /// five names that follow are heard as sections of an application rather than
  /// as five loose controls. Required, for the same reason `IuxRadioGroup`
  /// requires one: a set nobody named is a set the user has to infer.
  ///
  /// Not drawn. The bar's position and its permanence say what it is to a
  /// sighted user; a visible heading over it would spend a line of a phone
  /// screen repeating that.
  final String label;

  /// The destinations, in the order they are shown and read.
  ///
  /// Three to five, with distinct names, both asserted. Order is the caller's
  /// and is never sorted here: position in a navigation bar is what users
  /// remember, and a bar that reordered itself would be a bar nobody can learn.
  final List<IuxNavigationDestination> destinations;

  /// Which destination the user is currently in.
  ///
  /// Owned by the parent. The bar renders it and never changes it.
  final int selectedIndex;

  /// Called with the index of the destination the user chose.
  ///
  /// **Called for the current destination too**, and that is the one place this
  /// deliberately differs from `IuxRadioGroup`, which swallows a choice that
  /// changes nothing. Choosing the section you are already in is a real and
  /// distinguishable gesture — applications commonly answer it by returning to
  /// the top of that section — and only the parent knows whether it means
  /// anything here. Swallowing it would remove a capability the parent has no
  /// other way to get; reporting it costs a parent that does not want it one
  /// idempotent rebuild.
  ///
  /// Non-nullable. A destination that cannot be reached should not be in the
  /// bar: a permanent strip of the screen showing a place the user is not
  /// allowed to go is worse than a bar with one fewer destination.
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    // The one thing about this bar that cannot be decided from its arguments:
    // whether anything is going to be painted over it. A transient message is
    // pinned to the bottom edge and reserves no space, so a bar underneath one
    // is a bar whose destinations stop responding for the length of a dwell.
    // The measurement is on `IuxTransientLayer.debugCheckNotPlacedOver`.
    assert(IuxTransientLayer.debugCheckNotPlacedOver(context));

    final IuxBottomNavigationTokens tokens =
        IuxBottomNavigationResolver.resolve(context);

    final List<Widget> cells = <Widget>[
      for (int index = 0; index < destinations.length; index++)
        _IuxNavigationCell(
          destination: destinations[index],
          current: index == selectedIndex,
          onSelected: () => onDestinationSelected(index),
        ),
    ];

    final Widget arrangement = tokens.stacked
        // Scrollable, and that is a degradation rather than a feature. Five
        // destinations at three times the text size need more room than a
        // short phone has, and the two ways to lose that argument are to clip
        // the last destination — which removes a section of the application
        // for the user who most needed the larger text — or to let them reach
        // it by dragging. A destination the user has to scroll to is a
        // destination they may not find; a destination that is not rendered is
        // one they certainly will not. Where the bar fits, this scrolls
        // nothing and measures exactly as the column would.
        ? SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: cells,
            ),
          )
        // Intrinsic rather than fixed, and stretched rather than centred: every
        // column's target then spans the whole height of the bar, so there is
        // no strip above a short destination where a thumb lands and nothing
        // happens. The cost is one extra layout pass over at most five
        // children, paid once per bar rather than per frame of a list.
        : IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Equal shares, and no spacing between them. The destinations
                // partition the bar: a gap belonging to neither would be a
                // strip in the thumb zone where a tap does nothing at all, and
                // the target floor is met with margin without it.
                for (final Widget cell in cells) Expanded(child: cell),
              ],
            ),
          );

    return IuxSemantics.radioGroup(
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.background,
          border: Border(
            top: BorderSide(
              color: tokens.separator,
              width: tokens.separatorWidth,
            ),
          ),
        ),
        // The bar consumes the bottom inset itself, which is the contract
        // `IuxPageInsets.topOnly` was written against: the page above stops at
        // the bar, and the bar's own content clears the gesture area. Doing it
        // in both places is how content ends up inset twice from a notch that
        // is only there once.
        child: SafeArea(top: false, child: arrangement),
      ),
    );
  }
}

/// One destination: a target, a glyph, a name, and at most one badge.
///
/// Private, and it stays private. It is the answer to "what does a navigation
/// destination behave like", and there is one answer: the target floor, the
/// reserved indicator space, the merged announcement and the selection
/// semantics must not be able to drift between the two arrangements. Exposing
/// it would invite a bar assembled by hand that skips one of them.
class _IuxNavigationCell extends StatefulWidget {
  const _IuxNavigationCell({
    required this.destination,
    required this.current,
    required this.onSelected,
  });

  final IuxNavigationDestination destination;
  final bool current;
  final VoidCallback onSelected;

  @override
  State<_IuxNavigationCell> createState() => _IuxNavigationCellState();
}

class _IuxNavigationCellState extends State<_IuxNavigationCell> {
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

    final Widget content = _IuxNavigationCellContent(
      destination: widget.destination,
      current: widget.current,
      tokens: tokens,
    );

    final Widget interactive = GestureDetector(
      // Opaque so the whole column responds, including the space the focus
      // ring reserves, and not only the glyph painted in the middle of it.
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
          // responds rather than to the part that is painted. Width is normally
          // decided by the bar — a fifth of the screen — and this is what keeps
          // a short destination from collapsing below the floor in height.
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
              child: content,
            ),
          ),
        ),
      ),
    );

    final Widget region = Stack(
      // Passthrough, so the region that responds is the whole cell the bar
      // gave this destination rather than only the box its glyph and name
      // happen to need. A loose fit leaves a band above the shortest
      // destination where a tap lands on the bar and nothing happens.
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

    // A bare `Semantics` rather than `IuxSemantics.selection`, and the
    // deviation is the one `IuxListItem` recorded before it.
    // `IuxSemantics.selection` excludes its subtree, which is right for a
    // control whose visible content only repeats the name it was given and
    // wrong here: it would delete the badge from the interface of every
    // screen-reader user, so "Messages, 3 unread messages" would be announced
    // as "Messages" and the number would exist for sighted users only.
    //
    // Merging instead gives one stop that reads the name, then what is waiting
    // there, then the state. The properties are exactly the ones
    // `IuxSemantics.selection` sets for `IuxSelectionRole.radio` — checked, in
    // a mutually exclusive group, with the tap action on the node itself —
    // because a navigation bar *is* a mutually exclusive selection and must not
    // invent a second vocabulary for saying so.
    return MergeSemantics(
      child: Semantics(
        container: true,
        enabled: true,
        // "Checked", not "selected". A checked node is announced in both
        // states, so a user hears "not checked" at the four destinations they
        // are not in; `selected` is announced only when true, which leaves a
        // user to sweep the whole bar to find the one that said something.
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

/// The content of a destination, in reading order, in one of two arrangements.
class _IuxNavigationCellContent extends StatelessWidget {
  const _IuxNavigationCellContent({
    required this.destination,
    required this.current,
    required this.tokens,
  });

  final IuxNavigationDestination destination;
  final bool current;
  final IuxBottomNavigationTokens tokens;

  @override
  Widget build(BuildContext context) {
    final Widget indicator = _IuxNavigationIndicator(
      icon: current
          ? destination.selectedIcon ?? destination.icon
          : destination.icon,
      current: current,
      tokens: tokens,
    );

    // No line limit and no ellipsis, at any text scale. A truncated destination
    // is a place the user cannot identify, and truncation gets worse exactly
    // when someone has enlarged their text in order to read it.
    final Widget name = Text(
      destination.label,
      style: tokens.labelStyle,
      textAlign: tokens.stacked ? TextAlign.start : TextAlign.center,
    );

    final Widget? badge = destination.badge;

    // The corner can only be asked for, and only granted while the bar is in
    // its compact arrangement. Once it has rearranged into rows — which is
    // what it does when the text grows — there is no corner left to sit in,
    // and a badge that clipped at the size somebody chose in order to read
    // would fail exactly the person it was drawn for.
    //
    // Read from the resolved tokens rather than from `MediaQuery`: a component
    // does not reach below the layers it is given, and the arrangement is
    // already the answer to the question being asked.
    final bool onGlyph = badge != null &&
        destination.badgePlacement == IuxBadgePlacement.onGlyph &&
        !tokens.stacked;

    final Widget glyph = onGlyph
        ? Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              indicator,
              // Overhanging the indicator rather than sitting inside it. A
              // counted badge is wider than a 24-pixel glyph — measured, not
              // assumed — so a badge placed *within* the corner covers the
              // thing it counts. Outside it, the glyph stays readable and the
              // result is the corner marker a launcher draws.
              Positioned(
                top: -4,
                right: -8,
                child: IuxBadgeOnGlyph(child: badge),
              ),
            ],
          )
        : indicator;
    final Widget? trailingBadge = onGlyph ? null : badge;

    if (tokens.stacked) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          glyph,
          SizedBox(width: tokens.gap),
          // Flexible rather than fixed: without it, a long name in a wide row
          // is an overflow instead of a second line.
          Expanded(child: name),
          if (trailingBadge != null) ...<Widget>[
            SizedBox(width: tokens.gap),
            trailingBadge,
          ],
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        glyph,
        SizedBox(height: tokens.gap),
        name,
        // Under the name rather than beside it. A fifth of a phone screen has
        // no room for both on one line, and squeezing the name is the wrong
        // half to give up: the badge says how many, the name says of what.
        if (trailingBadge != null) ...<Widget>[
          SizedBox(height: tokens.gap),
          trailingBadge,
        ],
      ],
    );
  }
}

/// The glyph, and the shape that marks it as the current destination.
class _IuxNavigationIndicator extends StatelessWidget {
  const _IuxNavigationIndicator({
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
          // both states. An indicator that appeared by growing would resize its
          // column, and in a row of equal columns that moves all five.
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
                // runtime every other IUX component reads. Letting Flutter
                // scale it again would enlarge the glyph twice as fast as the
                // name under it.
                applyTextScaling: false,
              ),
            ),
          ),
        ],
      );
}
