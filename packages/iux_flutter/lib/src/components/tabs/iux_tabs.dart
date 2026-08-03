// `SemanticsRole` is declared in `dart:ui` and reaches the framework through
// `package:flutter/semantics.dart` rather than through `widgets.dart`. It is
// what tells the platform that this strip is a set of tabs and not a row of
// buttons that happen to sit together.
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

import '../../accessibility/iux_focus.dart';
import 'iux_tabs_tokens.dart';

/// The fewest tabs a strip may carry.
///
/// One tab is a heading wearing a control: it announces a choice, offers no
/// alternative, and takes a target the user can activate to no effect. Two is
/// the smallest real choice, and it is exactly the case `IuxBottomNavigation`
/// refuses and sends here.
const int _minimumTabs = 2;

/// The most tabs a strip may carry.
///
/// Beyond five the strip stops being a choice and becomes the screen. Measured
/// on a 320-pixel screen at 200% text, five one-word tabs already take four
/// rows in the widget-test font — an upper bound, since that font draws every
/// glyph as a square of the font size — and a sixth adds another row of chrome
/// above the content the user came for. A sixth lateral view is a filter, a
/// menu, or evidence that the section is doing two jobs.
const int _maximumTabs = 5;

/// A lateral choice between views of the same thing.
///
/// ```dart
/// Column(
///   children: <Widget>[
///     IuxTabs(
///       label: l10n.messageFilter,
///       tabs: <String>[l10n.all, l10n.unread, l10n.archived],
///       selectedIndex: filter.index,
///       onTabSelected: controller.showFilter,
///     ),
///     Expanded(child: panelFor(filter)),
///   ],
/// )
/// ```
///
/// **Use it** when one section of an application has two to five views of the
/// same subject, exactly one of them is shown at a time, and moving between
/// them is not going anywhere: the user stays where they are and looks at the
/// same thing differently. "All / Unread / Archived" over one list of messages
/// is the shape. The strip's value is that the alternatives are visible without
/// being visited.
///
/// **Do not use it** for the top-level sections of an application — that is
/// `IuxBottomNavigation`, which is permanent, sits where a thumb reaches, and
/// survives the screen changing under it. Do not use it for steps of a task: a
/// wizard has an order, a meaning for "back", and steps that are not peers, and
/// a strip that lets the user jump from step two to step four is a strip that
/// produced an invalid result. Do not use it for filters that combine — two of
/// those can be on at once, so they are `IuxFilterChip`s in an `IuxChipGroup`,
/// not a set of which exactly one applies. Do not use it for an action: a tab
/// is a view, and "Delete all" among the views is a tap the user cannot take
/// back by choosing another tab.
///
/// ## It switches nothing
///
/// The strip reports which tab the user chose. It does not hold an index, does
/// not build the panel, and does not decide what the panel contains.
///
/// ```dart
/// // Wrong: the strip owns which view is shown.
/// IuxTabs(onTabSelected: (int i) => setState(() => _stripIndex = i))
///
/// // Right: the parent owns it and tells the strip what to render.
/// IuxTabs(selectedIndex: state.filter, onTabSelected: controller.showFilter)
/// ```
///
/// This is Component Standard §3, and here it is load-bearing rather than
/// tidy: only the application knows whether the panel it is about to show
/// needs loading, whether an edit in the current panel must be saved first, or
/// whether the user may leave at all. If the parent does not re-render with a
/// new [selectedIndex] the mark does not move, which is correct — a strip that
/// marked a tab whose panel never appeared would be describing a screen that
/// does not exist.
///
/// ## Every tab is visible, always
///
/// There is no scrollable mode and there will not be one. A strip that scrolls
/// hides views off the edge of the screen, and a user who cannot see that there
/// are more has no way to learn it: nothing on screen says "there are two more
/// to the right", and the gesture that would reveal them is the same one that
/// scrolls the panel underneath. The alternatives IUX takes instead are a
/// smaller number of tabs, asserted, and a strip that wraps onto another row
/// when its words no longer fit on one.
///
/// ## What happens at 200% text
///
/// The strip wraps. Tabs keep their words whole at every text size, so a strip
/// takes as many rows as its words need and the cost is paid in rows of the
/// screen rather than in letters of a word — see the component document for the
/// measured table. Nothing is truncated and nothing is hidden.
///
/// Tabs on the same row always have the same height: a label needs a second
/// line only when it is wider than the whole strip, and a tab that wide cannot
/// share a row with anything. So a short tab is never left with a dead band
/// above and below it.
///
/// This is where the strip parts company with `IuxBottomNavigation`, which
/// keeps five equal columns and changes arrangement at a text-scale threshold.
/// A destination there is a glyph over a name in a fixed column whose position
/// users memorise; a tab is one word, read rather than remembered, so it may
/// simply take the width of its word and let the row end where it ends.
///
/// ## How the current tab is announced
///
/// Colour is never the signal. The current tab is marked three ways, and only
/// one of them is a hue:
///
/// 1. **In the semantics**, as a node whose role is `SemanticsRole.tab` inside
///    a container whose role is `SemanticsRole.tabBar`, carrying a selected
///    state that is present in both cases — true on the current tab, false on
///    every other, never absent. Flutter refuses to build a tab without one.
/// 2. **As a shape**: a filled, outlined mark behind the label. Its presence
///    survives a monochrome screen; the outline is drawn as well as the fill
///    because surface contrast alone is deliberately gentle in IUX.
/// 3. **As content colour**, which is the reinforcement rather than the signal.
///
/// The mark's space is reserved whether or not it is drawn, so choosing a tab
/// never resizes one — in a strip that wraps, a few pixels of extra width is
/// enough to push the last tab onto a new row under the finger that tapped.
class IuxTabs extends StatelessWidget {
  /// Creates a tab strip.
  ///
  /// The assertions here catch the contradictions that can be decided from the
  /// arguments alone. Quietly repairing them would hide that the caller
  /// believed something untrue about their own screen.
  IuxTabs({
    super.key,
    required this.label,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
  })  : assert(
          label.length > 0,
          'A tab strip must be named. Unnamed, a screen reader announces a set '
          'of tabs and refuses to say what the set is about, so the user hears '
          'three words with nothing tying them together and no question they '
          'answer.',
        ),
        assert(
          tabs.length >= _minimumTabs,
          'A tab strip needs at least two tabs. One tab is a heading wearing a '
          'control: it announces a choice, offers no alternative, and gives the '
          'user a target that changes nothing. Show the content without a '
          'strip.',
        ),
        assert(
          tabs.length <= _maximumTabs,
          'A tab strip holds at most five tabs. Five one-word tabs already '
          'take three rows on a 320-pixel screen at 200% text; a sixth adds a '
          'fourth row of chrome above the content the user came for. A sixth '
          'lateral view is a filter, a menu, or evidence that the section is '
          'doing two jobs.',
        ),
        assert(
          selectedIndex >= 0 && selectedIndex < tabs.length,
          'The current tab is not one of the tabs, so the strip would mark none '
          'of them. A strip showing no current tab while the application '
          'believes it has one is how a user ends up unable to tell which view '
          'they are looking at.',
        ),
        assert(
          tabs.length == 0 || !tabs.any((String tab) => tab.isEmpty),
          'A tab has no name. An unnamed tab is announced as "tab" and nothing '
          'else, and drawn as an empty box, so the user is offered a view and '
          'not told which one.',
        ),
        assert(
          tabs.toSet().length == tabs.length,
          'Two tabs share a name. They are indistinguishable to a screen reader '
          'and to anyone reading the strip, so the user is shown a choice they '
          'cannot make.',
        );

  /// What this set of tabs is about, already localised.
  ///
  /// Announced when a screen reader enters the strip — "Message filter" — so
  /// the names that follow are heard as answers to a question rather than as
  /// loose controls. Required, for the same reason `IuxRadioGroup` and
  /// `IuxBottomNavigation` require one.
  ///
  /// Not drawn. The strip's position directly above the content it switches
  /// says what it is to a sighted user, and a visible heading over it would
  /// spend a line of a phone screen repeating that.
  final String label;

  /// The tab names, in the order they are shown and read.
  ///
  /// Two to five, non-empty, distinct — all asserted. Order is the caller's and
  /// is never sorted here.
  ///
  /// Plain strings, and that is the whole model: a tab is a word. There is no
  /// `IuxTab` value type because it would carry exactly this field, no glyph
  /// because a glyph beside a word doubles the height of the strip at the top
  /// of a phone screen and adds nothing the word does not already say, and no
  /// badge because a caller who wants a count can put it in the name — where
  /// their own language decides how a number joins a noun, which IUX cannot.
  ///
  /// Each name is both drawn and announced. A tab has no context in which the
  /// visible and the spoken name could legitimately differ.
  final List<String> tabs;

  /// Which tab's panel the application is currently showing.
  ///
  /// Owned by the parent. The strip renders it and never changes it.
  final int selectedIndex;

  /// Called with the index of the tab the user chose.
  ///
  /// **Called for the current tab too**, which is the same call
  /// `IuxBottomNavigation` makes and for the same reason: re-choosing the view
  /// you are already in is a distinguishable gesture, applications answer it in
  /// different ways or not at all, and only the parent knows which. Swallowing
  /// it removes a capability the parent has no other way to get; reporting it
  /// costs a parent that does not want it one rebuild that changes nothing.
  ///
  /// Non-nullable. A view that cannot be opened should not be a tab: a visible,
  /// named, focusable target that announces itself as available and does
  /// nothing teaches the user that the strip is unreliable. A view with nothing
  /// in it is a tab whose panel is empty, and an empty panel can say why.
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final IuxTabsTokens tokens = IuxTabsResolver.resolve(context);

    // A bare `Semantics` rather than an `IuxSemantics` helper, and the
    // deviation is recorded in the component document. The accessibility
    // runtime has no tab vocabulary — it offers `radioGroup`, which is a
    // different role and would cost the tab role on every child, since a node
    // holds exactly one. Adding `IuxSemantics.tabBar` is the right fix and
    // belongs to the runtime rather than to this component.
    return Semantics(
      container: true,
      // Flutter checks this container: it must have at least one child and
      // every one of its semantic children must carry `SemanticsRole.tab`.
      // That is why nothing else in this subtree may announce itself — the
      // strip has no separator widget, no scroll view, and no stray text.
      role: SemanticsRole.tabBar,
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.background,
          // Along the edge the panel is on. This line is the only thing that
          // says where the choice stops and the chosen content starts; without
          // it the first line of the panel reads as one more tab.
          border: Border(
            bottom: BorderSide(
              color: tokens.separator,
              width: tokens.separatorWidth,
            ),
          ),
        ),
        child: Wrap(
          // No spacing on either axis. The tabs partition the row: a gap
          // belonging to no tab would be a strip where a tap does nothing at
          // all, and the target floor is met with margin without it. What
          // separates one word from the next is each tab's own padding, twice
          // over.
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            for (int index = 0; index < tabs.length; index++)
              _IuxTab(
                label: tabs[index],
                current: index == selectedIndex,
                onSelected: () => onTabSelected(index),
              ),
          ],
        ),
      ),
    );
  }
}

/// One tab: a target, a name, and a mark when it is the current one.
///
/// Private, and it stays private. It is the answer to "what does a tab behave
/// like", and there is one answer: the target floor, the reserved mark space,
/// the single announcement and the tab role must not be able to drift. Exposing
/// it would invite a strip assembled by hand that skips one of them — and a
/// hand-assembled strip is also how a non-tab child ends up under a `tabBar`,
/// which Flutter rejects at runtime.
class _IuxTab extends StatefulWidget {
  const _IuxTab({
    required this.label,
    required this.current,
    required this.onSelected,
  });

  final String label;
  final bool current;
  final VoidCallback onSelected;

  @override
  State<_IuxTab> createState() => _IuxTabState();
}

class _IuxTabState extends State<_IuxTab> {
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
    final IuxTabsTokens tokens = IuxTabsResolver.resolve(
      context,
      current: widget.current,
      pressed: _pressed,
      hovered: _hovered,
    );

    final Widget content = Stack(
      alignment: Alignment.center,
      children: <Widget>[
        // Faded in rather than added, so the space it occupies is reserved in
        // both states. A mark that appeared by growing would widen its tab, and
        // in a strip that wraps a few pixels can push the last tab onto a new
        // row under the finger that caused it.
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: widget.current ? 1 : 0,
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
          padding: EdgeInsets.symmetric(
            horizontal: tokens.horizontalPadding,
            vertical: tokens.verticalPadding,
          ),
          // No line limit and no ellipsis, at any text scale. A truncated tab
          // is a view the user cannot identify, and truncation gets worse
          // exactly when someone has enlarged their text in order to read it.
          child: Text(
            widget.label,
            style: tokens.labelStyle,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );

    final Widget interactive = GestureDetector(
      // Opaque so the whole tab responds, including the space the focus ring
      // reserves, and not only the word painted in the middle of it.
      behavior: HitTestBehavior.opaque,
      // Excluded, and this is the load-bearing line rather than a tidy-up. A
      // gesture detector that describes itself creates a semantics node of its
      // own inside this tab, which doubles the number of stops a screen reader
      // finds — measured, six for three tabs — and pushes the tab role onto a
      // parent whose child is then not a tab, which is exactly what Flutter's
      // `tabBar` check rejects. The tap action is registered on the node below
      // instead, where a screen reader's double-tap looks for it.
      excludeFromSemantics: true,
      onTapDown: (TapDownDetails _) => _setPressed(true),
      onTapUp: (TapUpDetails _) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onSelected,
      child: MouseRegion(
        onEnter: (_) => _setHovered(true),
        onExit: (_) => _setHovered(false),
        child: ConstrainedBox(
          // Outside the focus ring, so the floor applies to the region that
          // responds rather than to the part that is painted. A one-word tab
          // is narrower than a finger without it.
          constraints: BoxConstraints(
            minWidth: tokens.minExtent,
            minHeight: tokens.minExtent,
          ),
          child: IuxFocusable(
            onActivate: widget.onSelected,
            // The mark's radius, so the ring and the mark are concentric
            // instead of almost-aligned when a user focuses the tab they are
            // already on.
            borderRadius: BorderRadius.circular(tokens.indicatorRadius),
            child: content,
          ),
        ),
      ),
    );

    final Widget region = Stack(
      // Passthrough, so the tint covers the whole region that responds rather
      // than only the box the word happens to need. The tint is what answers
      // "did my tap land", and it should show the target that took it.
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

    // A bare `Semantics`, as the strip's own container is, and for the same
    // reason: the runtime has no tab vocabulary yet. The subtree is neither
    // excluded nor merged — the name arrives from the `Text` below and the
    // focus state from `IuxFocusable`, and both are wanted on this node.
    //
    // Because the role sits on this node rather than on a `MergeSemantics`
    // above it, Flutter's own checks apply: a tab without a selected state and
    // a tab without a tap action are both rejected at build time. The
    // invariant is enforced by the framework instead of by this comment.
    return Semantics(
      container: true,
      role: SemanticsRole.tab,
      // Present in both states, never null. A tab whose selected state is
      // absent is refused by Flutter, which is the behaviour IUX wants: a set
      // where only the current member says anything leaves the user sweeping
      // the whole strip to find the one that spoke.
      selected: widget.current,
      enabled: true,
      // Registered here because the gesture detector above is excluded from
      // semantics. Without it the tab is announced correctly and refuses to
      // respond to a screen reader's double-tap.
      onTap: widget.onSelected,
      child: region,
    );
  }
}
