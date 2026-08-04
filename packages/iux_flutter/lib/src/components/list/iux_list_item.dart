import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../accessibility/iux_focus.dart';
import '../../inputs/iux_input_descriptor.dart';
import '../../inputs/iux_input_model.dart';
import '../selection/iux_selection_model.dart';
import '../selection/iux_selection_tokens.dart';
import 'iux_list_tokens.dart';

/// Which of the three forms a row takes.
///
/// Private, and it stays private. The three differ in what a tap *means* —
/// nothing, "open this", "choose this" — so a public parameter choosing
/// between them would let a call site swap one meaning for another without
/// changing anything the user can see.
enum _IuxListItemKind { plain, tappable, selectable }

/// One item in a list: a title, optionally a supporting line, a value, an
/// icon, and at most one control.
///
/// ```dart
/// IuxListItem.tappable(
///   title: order.reference,
///   subtitle: l10n.deliveredOn(order.date),
///   trailingText: l10n.amount(order.total),
///   hint: l10n.opensTheOrder,
///   onActivate: () => open(order),
/// )
/// ```
///
/// **Use it** for the repeating unit of a list — an order, a message, a
/// setting, a search result. A row is the densest interactive element an
/// application has, which is why almost everything about it is decided here
/// rather than at the call site.
///
/// **Do not use it as a layout row.** It is not a `Row` with padding: it
/// applies a touch-target floor, a semantic role and a text hierarchy that
/// only make sense for an item in a list. Two unrelated widgets side by side
/// are a `Row`.
///
/// **Do not use it for a single object with several parts.** That is
/// `IuxCard`, which draws a boundary around one thing. A row is one of many
/// comparable things.
///
/// ## The text is text, not widgets, and that is the point
///
/// [title], [subtitle] and [trailingText] are `String`s. This is the first of
/// the two layers that keep a row from becoming a control containing controls:
/// there is no way to put a button inside the row's text, because the text is
/// not a place widgets can go.
///
/// It also puts wrapping under this component's control. A row is where text
/// wrapping fails first — a title, a subtitle, a value and an icon competing
/// for a 320-pixel line at 200% text — and truncating the title loses the only
/// thing that identifies the item. Nothing here sets `maxLines` or an
/// ellipsis, at any scale. The value moves *under* the text once enlargement
/// makes the horizontal split impossible, instead of squeezing the title into
/// a column two characters wide.
///
/// ## Tappable, or selectable, or neither — and a control is never inside it
///
/// This is the same rule `IuxCard` states, applied to the element where it
/// bites hardest. A row that opens a detail **and** contains a delete button
/// gives a screen-reader user a control nested in a control and no way to know
/// which one they are on; a sighted user cannot see where "open" stops and
/// "delete" starts, so the outcome of a tap depends on a boundary they cannot
/// perceive.
///
/// IUX-019 made that unrepresentable in two layers. This component keeps both
/// and strengthens the first:
///
/// 1. **The types.** Text slots take strings, so a control cannot be smuggled
///    into the content at all. [leading] is the only widget the caller puts
///    inside the row, and it is meant for an icon or an avatar.
/// 2. **A debug-only subtree check.** An interactive row walks [leading] after
///    the first frame and throws, naming the offending widget. It recognises a
///    `GestureDetector` carrying a tap handler and a `Semantics` node claiming
///    a button, link, text field, slider or tap action — between them every
///    IUX control and every Material one. It does not see custom hit testing,
///    and it is compiled out of release builds.
///
/// Where this component goes further than the card is [trailingAction]. The
/// card's answer to "the block opens something *and* has its own button" was
/// "move the button outside the card". A list row has no outside: the second
/// action has to live in the row or not exist. So the row provides the
/// arrangement the card recommended, and guarantees the four properties that
/// make it safe rather than leaving them to a call site:
///
/// - the control is laid out **beside** the interactive region, never inside
///   it, so neither target overlaps the other;
/// - at least `kIuxMinimumTargetSpacing` separates the two;
/// - the control is a **sibling** semantics node, never a descendant, so a
///   screen reader announces two adjacent stops rather than nested controls;
/// - the row's press tint stops at the boundary, so where one target ends and
///   the next begins is visible.
///
/// The combination IUX-019 refused — a control *within* the activatable region
/// — remains impossible here. The combination it recommended is what this
/// builds.
///
/// ## A row's content is merged, not excluded
///
/// An interactive row is **one** stop, and everything it shows is merged into
/// that one utterance:
///
/// ```text
/// "Order 3141, Delivered on Tuesday, €82.40, button. Opens the order."
/// ```
///
/// Excluding descendant semantics — what a button does with its own label —
/// would delete the status and the amount from the interface of every
/// screen-reader user, leaving them to open the row to learn what a sighted
/// user reads at a glance. [semanticLabel] is therefore optional: the row
/// already has visible text to be named by, and a label supplied here is read
/// *before* that text rather than instead of it.
///
/// ## Reading order
///
/// [leading], [title], [subtitle], [trailingText], [trailingAction], in tree
/// order. Nothing is reordered visually without being reordered semantically.
class IuxListItem extends StatelessWidget {
  /// Creates a row that presents content and does not respond to a tap.
  ///
  /// ```dart
  /// IuxListItem(
  ///   title: l10n.postcode,
  ///   trailingText: address.postcode,
  /// )
  /// ```
  ///
  /// Use this form for a row that shows something rather than doing something,
  /// and for a row that *cannot* be acted on right now — an item that should
  /// not be opened is an item that should not look openable.
  const IuxListItem({
    super.key,
    required this.title,
    this.subtitle,
    this.trailingText,
    this.leading,
    this.trailingAction,
  })  : _kind = _IuxListItemKind.plain,
        semanticLabel = null,
        hint = null,
        onActivate = null,
        selected = IuxSelectionState.unselected,
        onSelectedChanged = null,
        autofocus = false,
        focusNode = null,
        assert(
          title.length > 0,
          'A row must say what it is. An untitled row is an item the user can '
          'see and cannot identify, and a screen reader reads it as whatever '
          'happens to be left in it.',
        ),
        assert(
          subtitle == null || subtitle.length > 0,
          'Empty supporting text reserves a line and says nothing. Pass null.',
        ),
        assert(
          trailingText == null || trailingText.length > 0,
          'An empty value reserves space for a number that never arrives. '
          'Pass null.',
        );

  /// Creates a row that is itself one control.
  ///
  /// ```dart
  /// IuxListItem.tappable(
  ///   title: message.sender,
  ///   subtitle: message.preview,
  ///   trailingText: l10n.time(message.receivedAt),
  ///   hint: l10n.opensTheMessage,
  ///   onActivate: () => open(message),
  /// )
  /// ```
  ///
  /// The row is announced as a single button named by its own text, followed
  /// by [hint]. [onActivate] is non-nullable: there is no state in which the
  /// row looks activatable and is not, because a disabled row that still
  /// occupies a target is a target that lies.
  ///
  /// **The row must not contain a control.** [title], [subtitle] and
  /// [trailingText] are strings, so they cannot; [leading] is checked in debug
  /// builds and throws with the offending widget named. A control that belongs
  /// to this item goes in [trailingAction], where it becomes its own target
  /// beside the row rather than a second answer inside it.
  const IuxListItem.tappable({
    super.key,
    required this.title,
    required VoidCallback this.onActivate,
    this.subtitle,
    this.trailingText,
    this.leading,
    this.trailingAction,
    this.semanticLabel,
    this.hint,
    this.autofocus = false,
    this.focusNode,
  })  : _kind = _IuxListItemKind.tappable,
        selected = IuxSelectionState.unselected,
        onSelectedChanged = null,
        assert(
          title.length > 0,
          'A tappable row must say what activating it will act on. Without a '
          'title the row is announced as "button" and nothing else, which '
          'tells the user something will happen and refuses to say what.',
        ),
        assert(
          subtitle == null || subtitle.length > 0,
          'Empty supporting text reserves a line and says nothing. Pass null.',
        ),
        assert(
          trailingText == null || trailingText.length > 0,
          'An empty value reserves space for a number that never arrives. '
          'Pass null.',
        ),
        assert(
          semanticLabel == null || semanticLabel.length > 0,
          'Pass null rather than an empty accessible name. The row is named by '
          'its own text when this is absent, which is usually what you want.',
        );

  /// Creates a row the user chooses, which is a checkbox wearing a list row.
  ///
  /// ```dart
  /// IuxListItem.selectable(
  ///   title: file.name,
  ///   subtitle: l10n.fileSize(file.bytes),
  ///   selected: IuxSelectionState.fromSelected(chosen.contains(file)),
  ///   onSelectedChanged: (bool value) => controller.choose(file, value),
  /// )
  /// ```
  ///
  /// The row is announced as a checked or unchecked control, using exactly the
  /// semantics `IuxCheckbox` uses, and it draws the same tick in the same box
  /// resolved from the same tokens. A selectable row is a checkbox in
  /// disguise; inventing a second set of semantics for it would give the user
  /// two controls to learn where there is one concept.
  ///
  /// **Colour is never the signal.** A chosen row changes its surface *and*
  /// shows a tick. The surface alone would be invisible to a user who cannot
  /// separate the two hues, and it is the only signal a selected row normally
  /// gets.
  ///
  /// **The parent owns the answer.** The row renders [selected] and reports
  /// what the user asked for. If the parent does not re-render, nothing
  /// changes on screen — which is correct, because a row that marked itself
  /// and then failed to save would be showing the user something untrue.
  const IuxListItem.selectable({
    super.key,
    required this.title,
    required this.selected,
    required ValueChanged<bool> this.onSelectedChanged,
    this.subtitle,
    this.trailingText,
    this.leading,
    this.trailingAction,
    this.semanticLabel,
    this.hint,
    this.autofocus = false,
    this.focusNode,
  })  : _kind = _IuxListItemKind.selectable,
        onActivate = null,
        assert(
          title.length > 0,
          'A selectable row must say what is being chosen. An unnamed choice '
          'is a choice the user makes without knowing what they chose.',
        ),
        assert(
          subtitle == null || subtitle.length > 0,
          'Empty supporting text reserves a line and says nothing. Pass null.',
        ),
        assert(
          trailingText == null || trailingText.length > 0,
          'An empty value reserves space for a number that never arrives. '
          'Pass null.',
        ),
        assert(
          semanticLabel == null || semanticLabel.length > 0,
          'Pass null rather than an empty accessible name.',
        ),
        assert(
          selected != IuxSelectionState.partial,
          'A row stands for one item, so it is either chosen or it is not. '
          'There is nowhere on it to render "partly chosen", and a user who '
          'saw such a row could not predict what tapping it would do. A '
          'summary of a set is an IuxCheckbox, which has a partial state.',
        );

  /// The primary text, already localised.
  ///
  /// Required and never empty. It is what identifies the item, so it is never
  /// truncated: it wraps at every text scale, on every screen width.
  final String title;

  /// A supporting line under [title], already localised.
  ///
  /// For the detail that qualifies the item — a date, a preview, a status in
  /// words. Not for anything the user needs in order to choose between two
  /// rows, which belongs in [title].
  final String? subtitle;

  /// The value this row reports, already localised.
  ///
  /// An amount, a count, a time. Laid out at the end of the row, and moved
  /// under the text once enlarged text makes the horizontal split impossible.
  final String? trailingText;

  /// An icon or an avatar at the start of the row.
  ///
  /// Presentation only. On an interactive row a control here is refused in
  /// debug builds, because a control inside a control is the failure this
  /// component exists to prevent. A decorative icon should be wrapped in
  /// `IuxSemantics.decorative` so it is not announced as an unlabelled image.
  final Widget? leading;

  /// One control belonging to this item, laid out beside the row.
  ///
  /// Never inside the interactive region: it is a sibling target, separated by
  /// at least `kIuxMinimumTargetSpacing`, and a sibling semantics node. That is
  /// what makes it usable on a row that is itself a control.
  ///
  /// One, not a list. Two controls plus a row is three targets on one line,
  /// which no longer fits a phone at an enlarged text size and no longer reads
  /// as one item. If an item needs several actions, they belong on the detail
  /// it opens or behind a single menu control placed here.
  final Widget? trailingAction;

  /// An accessible name read before the row's own text, or null.
  ///
  /// Optional, unlike `IuxCard.tappable`, and the difference is that a row
  /// always has a title. Supply this only when the visible text is ambiguous
  /// out of context — a row reading "Yesterday" in a list of backups.
  final String? semanticLabel;

  /// What activating the row does, when its text leaves it ambiguous.
  ///
  /// Read after the name and the role, so write it as an outcome — "opens the
  /// order" — not as an instruction to double-tap, which the screen reader
  /// already supplies.
  final String? hint;

  /// Called once per accepted activation. Null unless the row is tappable.
  final VoidCallback? onActivate;

  /// Whether the row is chosen. Always unselected unless the row is selectable.
  ///
  /// [IuxSelectionState.partial] is refused: see [IuxListItem.selectable].
  final IuxSelectionState selected;

  /// Called with the selection the user asked for.
  ///
  /// Null unless the row is selectable. Never called with the state the row is
  /// already in, so a parent does not have to guard against a no-op write.
  final ValueChanged<bool>? onSelectedChanged;

  /// Whether an interactive row takes focus when first built.
  final bool autofocus;

  /// An externally owned focus node, for an interactive row.
  final FocusNode? focusNode;

  final _IuxListItemKind _kind;

  /// Whether a tap anywhere on the row does something.
  bool get isInteractive => _kind != _IuxListItemKind.plain;

  @override
  Widget build(BuildContext context) {
    final Widget region = _IuxListItemRegion(
      kind: _kind,
      title: title,
      subtitle: subtitle,
      trailingText: trailingText,
      leading: leading,
      semanticLabel: semanticLabel,
      hint: hint,
      onActivate: onActivate,
      selected: selected,
      onSelectedChanged: onSelectedChanged,
      autofocus: autofocus,
      focusNode: focusNode,
      hasTrailingAction: trailingAction != null,
    );

    final Widget? action = trailingAction;
    // Without a control the row is exactly one semantics node, like a tappable
    // card. Adding an empty container around it would cost a screen-reader
    // user a stop that carries nothing.
    if (action == null) return region;

    return Semantics(
      // `explicitChildNodes` is the load-bearing half. Without it the trailing
      // control's own label and role are absorbed into this node, and the row
      // is announced as one control called "Order 3141, Delete" — which is
      // both wrong and unreachable, because the control it came from no longer
      // exists as something the user can land on.
      container: true,
      explicitChildNodes: true,
      child: _IuxListItemWithAction(region: region, action: action),
    );
  }
}

/// Lays a row and its one control out as two targets that cannot overlap.
///
/// Private because the separation is the guarantee, not a layout option. A
/// caller able to assemble this by hand would eventually assemble it without
/// the spacing, which is the arrangement that produces mis-taps between "open"
/// and "delete".
///
/// ## Why the control is given a ceiling
///
/// The control used to be laid out as a plain `Row` child, which in Flutter
/// means it is measured against **unbounded** width and takes whatever its
/// content asks for; the `Expanded` beside it then absorbs whatever is left,
/// including a negative remainder. That is fine until the control's own content
/// grows, and the thing that grows all of it at once is the user's text size.
///
/// Measured on a 320-pixel screen, an `IuxListItem.tappable` carrying an
/// `IuxStatusIndicator`: **34 pixels over at 200%** and **180 at 300%**.
/// Neither component overflows on its own — the indicator wraps its own label
/// perfectly well when something tells it how wide it may be, and the row wraps
/// its title perfectly well when something is left for it — which is why no
/// component test found this and why the fix belongs here, at the join
/// (`IUX-LISTITEM-TRAILING-001`, WCAG 2.2 SC 1.4.4).
///
/// **The overflow is the half of it a test could see.** The same measurement
/// on the way up reports what the row was doing before it ran out of pixels:
/// the title's box came out **75.8 wide at 100%**, **2.8 wide and 324 tall at
/// 150%**, and **zero at 200%** — one character to a line, then no line at
/// all — with no exception thrown until 200%. A control that takes its
/// intrinsic width from a row does not begin failing at the point the
/// framework complains; it begins failing as soon as it takes more than its
/// share, and everything between there and the exception is silent.
///
/// The ceiling is [IuxListItemTokens.valueFlex]'s share of the row, which is
/// the split this component already applies one level down, to the trailing
/// *text*, for the reason written against those constants: the title is the
/// only thing that identifies the item, so it is the part that keeps the space
/// and the trailing element is the part that wraps. A control and a value are
/// the same problem, and answering them differently would mean two rules to
/// get right.
///
/// A control that fits inside its share is untouched — a `maxWidth` a child
/// does not reach changes nothing — so this is invisible at the text sizes
/// where nothing was wrong.
class _IuxListItemWithAction extends StatelessWidget {
  const _IuxListItemWithAction({required this.region, required this.action});

  final Widget region;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final IuxListItemTokens tokens = IuxListItemResolver.resolve(context);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // Unbounded width is left alone rather than guessed at. A row inside a
        // horizontally scrolling parent has no share to take a fraction of,
        // and the `Expanded` below has already refused that arrangement in
        // terms the framework wrote.
        final double ceiling = constraints.hasBoundedWidth
            ? (constraints.maxWidth -
                    tokens.actionSpacing -
                    tokens.horizontalPadding) *
                tokens.valueFlex /
                (tokens.textFlex + tokens.valueFlex)
            : double.infinity;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // Expanded, so the row's target reaches the control rather than
            // stopping at the end of its text. A gap between two targets that
            // belongs to neither is a gap where a tap does nothing at all.
            Expanded(child: region),
            SizedBox(width: tokens.actionSpacing),
            Padding(
              // The control's own end padding, outside its target: the target
              // stops before the edge of the group, the row's does not.
              padding:
                  EdgeInsetsDirectional.only(end: tokens.horizontalPadding),
              child: ConstrainedBox(
                // A maximum, never a minimum and never a tight width: a small
                // control keeps its size, and the row keeps its share.
                constraints: BoxConstraints(maxWidth: math.max(ceiling, 0)),
                child: action,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The part of a row that responds — or, for a plain row, does not.
///
/// One widget for all three forms, so they cannot drift apart on padding, on
/// the target floor, or on whether the content is merged.
class _IuxListItemRegion extends StatefulWidget {
  const _IuxListItemRegion({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.trailingText,
    required this.leading,
    required this.semanticLabel,
    required this.hint,
    required this.onActivate,
    required this.selected,
    required this.onSelectedChanged,
    required this.autofocus,
    required this.focusNode,
    required this.hasTrailingAction,
  });

  final _IuxListItemKind kind;
  final String title;
  final String? subtitle;
  final String? trailingText;
  final Widget? leading;
  final String? semanticLabel;
  final String? hint;
  final VoidCallback? onActivate;
  final IuxSelectionState selected;
  final ValueChanged<bool>? onSelectedChanged;
  final bool autofocus;
  final FocusNode? focusNode;
  final bool hasTrailingAction;

  @override
  State<_IuxListItemRegion> createState() => _IuxListItemRegionState();
}

class _IuxListItemRegionState extends State<_IuxListItemRegion> {
  bool _pressed = false;
  bool _hovered = false;

  bool get _isSelectable => widget.kind == _IuxListItemKind.selectable;

  void _activate() {
    switch (widget.kind) {
      case _IuxListItemKind.plain:
        return;
      case _IuxListItemKind.tappable:
        widget.onActivate!();
      case _IuxListItemKind.selectable:
        widget.onSelectedChanged!(widget.selected.requestedSelection);
    }
  }

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
    final IuxListItemTokens tokens = IuxListItemResolver.resolve(
      context,
      selected: _isSelectable && widget.selected.isSelected,
      pressed: _pressed,
      hovered: _hovered,
    );

    final bool interactive = widget.kind != _IuxListItemKind.plain;

    final Widget content = _IuxListItemContent(
      tokens: tokens,
      title: widget.title,
      subtitle: widget.subtitle,
      trailingText: widget.trailingText,
      leading: widget.leading,
      mark: _isSelectable
          ? _IuxSelectionMark(
              label: widget.semanticLabel ?? widget.title,
              selected: widget.selected.isSelected,
            )
          : null,
      // Only an interactive row is checked. A control inside a row that is not
      // itself a control is legal — it is simply another target on the line.
      guardLeading: interactive,
    );

    final Widget padded = ConstrainedBox(
      // Applied to the padded content rather than around the whole row, so the
      // region that responds and the region that is painted are the same
      // shape. A minimum applied outside would leave a tall row whose tint
      // covers only part of it.
      constraints: BoxConstraints(minHeight: tokens.minHeight),
      child: Padding(
        padding: tokens.paddingFor(hasTrailingAction: widget.hasTrailingAction),
        child: content,
      ),
    );

    if (!interactive) {
      // Merged, and deliberately: a row that is not a control is still one
      // item, and reading its title, its status and its amount as three
      // unrelated fragments is how a list stops being navigable.
      return MergeSemantics(
        child: Semantics(
          container: true,
          child: Padding(
            // The gap an interactive row reserves for its focus ring, held
            // here too. Without it a list mixing plain and tappable rows has
            // two row heights, and the difference reads as a rendering fault
            // rather than as a difference in behaviour.
            padding: EdgeInsets.all(tokens.focusReservation),
            child: padded,
          ),
        ),
      );
    }

    final Widget visual = Stack(
      children: <Widget>[
        // The chosen background, edge to edge and behind everything. Drawn
        // outside the focus ring's reserved gap so a chosen row reads as a
        // full-width band rather than a rectangle floating inside one.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(color: tokens.background),
          ),
        ),
        // The gesture wraps the focus ring rather than sitting inside it,
        // which is the one place this row departs from IuxCard. A card is an
        // object with space around it; a row spans the whole list, so the
        // strip the ring reserves would be a band at the edge of every row
        // where a tap does nothing — invisible, and exactly where a thumb
        // reaching across the screen lands.
        GestureDetector(
          // Opaque so the whole row responds, including its padding, and not
          // only the text painted inside it.
          behavior: HitTestBehavior.opaque,
          onTapDown: (TapDownDetails _) => _setPressed(true),
          onTapUp: (TapUpDetails _) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          onTap: _activate,
          child: MouseRegion(
            onEnter: (_) => _setHovered(true),
            onExit: (_) => _setHovered(false),
            child: IuxFocusable(
              autofocus: widget.autofocus,
              focusNode: widget.focusNode,
              borderRadius: BorderRadius.circular(tokens.focusRadius),
              onActivate: _activate,
              child: padded,
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
                decoration: BoxDecoration(color: tokens.overlayColor),
              ),
            ),
          ),
        ),
      ],
    );

    // A bare `Semantics` rather than an `IuxSemantics` helper, and the
    // deviation is the same one IUX-019 recorded for the card.
    // `IuxSemantics.action` sets `excludeSemantics: true`, which is right for
    // a button whose only content is its own label and wrong here: it would
    // delete the status and the amount from the row. `IuxSemantics.group`
    // keeps them and announces no role, so the row would be a container the
    // user can activate without being told they can. The runtime has no
    // builder for a checked state either. MergeSemantics plus an explicit role
    // gives all of it: one stop, named, announced as activatable or as chosen,
    // reading out everything a sighted user sees.
    return MergeSemantics(
      child: Semantics(
        container: true,
        enabled: true,
        button: widget.kind == _IuxListItemKind.tappable ? true : null,
        // "Checked", not "selected". Android reads a checked control as a
        // checkbox, which is what a selectable row is; announcing it as
        // "selected" instead leaves the user without the on/off vocabulary
        // every other checkbox in the application uses.
        checked: _isSelectable ? widget.selected.isSelected : null,
        label: widget.semanticLabel,
        hint: widget.hint,
        // Registered on the node itself. Without it the row is announced
        // correctly and refuses to respond to a screen reader's activation.
        onTap: _activate,
        child: visual,
      ),
    );
  }
}

/// The content of a row, in reading order.
class _IuxListItemContent extends StatelessWidget {
  const _IuxListItemContent({
    required this.tokens,
    required this.title,
    required this.subtitle,
    required this.trailingText,
    required this.leading,
    required this.mark,
    required this.guardLeading,
  });

  final IuxListItemTokens tokens;
  final String title;
  final String? subtitle;
  final String? trailingText;
  final Widget? leading;
  final Widget? mark;
  final bool guardLeading;

  @override
  Widget build(BuildContext context) {
    final String? supporting = subtitle;
    final String? value = trailingText;
    final bool stacked = tokens.stacksTrailingText;
    final Widget? lead = leading;
    final Widget? tick = mark;

    final Widget texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // No line limit and no ellipsis, at any text scale. Truncating the
        // title removes the only thing that tells this item from the next one,
        // and truncation gets worse exactly when someone has enlarged their
        // text in order to read it.
        Text(title, style: tokens.titleStyle),
        if (supporting != null) ...<Widget>[
          SizedBox(height: tokens.textGap),
          Text(supporting, style: tokens.subtitleStyle),
        ],
        if (value != null && stacked) ...<Widget>[
          SizedBox(height: tokens.textGap),
          Text(value, style: tokens.valueStyle),
        ],
      ],
    );

    return Row(
      // Aligned to the top so a title wrapping to three lines keeps its icon
      // beside the first one, where reading starts.
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (tick != null) ...<Widget>[
          _FirstLineBand(extent: tokens.lineExtent, child: tick),
          SizedBox(width: tokens.gap),
        ],
        if (lead != null) ...<Widget>[
          _FirstLineBand(
            extent: tokens.lineExtent,
            child: guardLeading ? _IuxRowContentGuard(child: lead) : lead,
          ),
          SizedBox(width: tokens.gap),
        ],
        Expanded(flex: tokens.textFlex, child: texts),
        if (value != null && !stacked) ...<Widget>[
          SizedBox(width: tokens.gap),
          // Flexed rather than sized to its content: a long value would
          // otherwise take the space the title needs, and the title is the
          // part that must not be squeezed.
          Expanded(
            flex: tokens.valueFlex,
            child: Text(
              value,
              style: tokens.valueStyle,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ],
    );
  }
}

/// Centres a small element against the first line of the row's text.
class _FirstLineBand extends StatelessWidget {
  const _FirstLineBand({required this.extent, required this.child});

  final double extent;
  final Widget child;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        // A minimum rather than a fixed height: an avatar taller than a line
        // of text keeps its size instead of being squeezed into the band.
        constraints: BoxConstraints(minHeight: extent),
        child: Center(widthFactor: 1, heightFactor: 1, child: child),
      );
}

/// The box and tick a selectable row is marked with.
///
/// Resolved from the selection tokens rather than from the palette directly,
/// so the mark on a row and the mark in an `IuxCheckbox` are the same size,
/// the same shape and the same colour. A list whose "chosen" looks unlike the
/// form's "chosen" is a list the user has to learn separately.
class _IuxSelectionMark extends StatelessWidget {
  const _IuxSelectionMark({required this.label, required this.selected});

  /// The name of the row this mark belongs to, used only to resolve tokens.
  final String label;

  /// Whether the row is chosen.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final IuxSelectionTokens tokens = IuxSelectionResolver.resolve(
      context,
      IuxInputDescriptor(semantics: IuxInputSemantics(label: label)),
    );

    return AnimatedContainer(
      duration: tokens.motion.duration,
      curve: tokens.motion.curve,
      width: tokens.indicatorSize,
      height: tokens.indicatorSize,
      decoration: BoxDecoration(
        color: tokens.fillFor(selected: selected),
        borderRadius: BorderRadius.circular(tokens.checkboxRadius),
        border: Border.all(
          color: tokens.outlineFor(selected: selected),
          width: tokens.borderWidth,
        ),
      ),
      // The mark — not the fill colour — is what carries the state. A user who
      // cannot separate the two hues still sees the difference between a tick
      // and an empty box.
      child: selected
          ? Icon(
              Icons.check,
              size: tokens.markSize,
              color: tokens.markColor,
              // Already scaled once, by the resolver, through the same runtime
              // every other IUX component reads. Letting Flutter scale it
              // again would enlarge the tick past the box holding it.
              applyTextScaling: false,
            )
          : null,
    );
  }
}

/// Fails loudly, in debug builds, when an interactive row's leading slot holds
/// a control.
///
/// Wrapped around the caller's widget and nothing else, so the row's own
/// gesture handling is an ancestor of this check and is never mistaken for a
/// violation.
///
/// Deliberately a second implementation of the check `IuxCard` carries rather
/// than a shared one: extracting it belongs to whoever owns the accessibility
/// runtime, and this mission may not edit that file. The recognition rules and
/// the shape of the error are identical, which is what matters to a developer
/// who hits one after the other.
class _IuxRowContentGuard extends StatefulWidget {
  const _IuxRowContentGuard({required this.child});

  final Widget child;

  @override
  State<_IuxRowContentGuard> createState() => _IuxRowContentGuardState();
}

class _IuxRowContentGuardState extends State<_IuxRowContentGuard> {
  /// Whether this row has already reported a nested control.
  ///
  /// Without it, a row rebuilt every frame reports the same mistake every
  /// frame and the error the developer needs scrolls out of the log.
  bool _reported = false;

  @override
  void initState() {
    super.initState();
    _scheduleCheck();
  }

  @override
  void didUpdateWidget(covariant _IuxRowContentGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-checked on update: a control that appears in only one state of the
    // parent would otherwise never be seen.
    _scheduleCheck();
  }

  void _scheduleCheck() {
    assert(() {
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        if (!mounted || _reported) return;
        final String? offender = _firstInteractiveDescendant(context);
        if (offender == null) return;
        _reported = true;
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
            'An interactive IuxListItem contains an interactive element '
            '($offender).',
          ),
          ErrorDescription(
            'A row that is itself a control and also contains controls has '
            'two answers to "what does tapping do", and nothing on screen '
            'tells the user which one they are about to get. A screen reader '
            'announces the row as a button and then announces the buttons '
            'inside it, so the ambiguity is heard as well as felt. On a list '
            'row the two outcomes are usually "open this item" and "delete '
            'this item", which is the expensive direction to be wrong in.',
          ),
          ErrorHint(
            'Pass the control as `trailingAction` instead. It is laid out '
            'beside the row rather than inside it, keeps at least the minimum '
            'target separation, and stays its own named stop for a screen '
            'reader. `leading` is for an icon or an avatar.',
          ),
        ]);
      });
      return true;
    }());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Names the first control found below [context], or returns null.
///
/// Reports the nearest enclosing IUX widget rather than the raw
/// `GestureDetector` it matched on, because "IuxButton" tells a developer
/// where to look and "GestureDetector" does not.
String? _firstInteractiveDescendant(BuildContext context) {
  String? found;
  String? nearestNamed;

  void visit(Element element) {
    if (found != null) return;
    final Widget widget = element.widget;
    final String type = widget.runtimeType.toString();
    final String? enclosing = nearestNamed;
    if (type.startsWith('Iux')) nearestNamed = type;

    if (_isInteractive(widget)) {
      found = nearestNamed ?? type;
      return;
    }

    element.visitChildren(visit);
    nearestNamed = enclosing;
  }

  context.visitChildElements(visit);
  return found;
}

/// Whether [widget] responds to activation.
///
/// Long press and double tap are deliberately not counted. A tooltip attaches
/// a long-press handler to content that is not a control, and reporting that
/// would train developers to ignore this check — which costs more than missing
/// the rare row whose only nested control is long-press-only.
bool _isInteractive(Widget widget) {
  if (widget is GestureDetector) return widget.onTap != null;
  if (widget is Semantics) {
    final SemanticsProperties properties = widget.properties;
    return properties.button == true ||
        properties.link == true ||
        properties.textField == true ||
        properties.slider == true ||
        properties.onTap != null;
  }
  return false;
}
