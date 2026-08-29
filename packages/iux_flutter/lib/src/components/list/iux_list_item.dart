import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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

/// Whether a tappable row says, on its face, that it leads somewhere.
///
/// Public where [_IuxListItemKind] is private, and the difference is what the
/// two decide. The kind decides what a tap *does*, which no call site may
/// change without changing what the user can see. This decides only whether the
/// row shows the mark for it — a question the row cannot answer, because only
/// the caller knows whether `onActivate` pushes a route, expands something in
/// place, or leaves the application altogether.
///
/// It defaults to [none] deliberately. A chevron placed on every tappable row
/// would restyle every list in every application that already ships this
/// package, including the rows that toggle something in place and the rows that
/// open a browser — and a mark that appears on rows that do not lead anywhere
/// is worse than no mark at all, because the user stops reading it.
enum IuxListItemDisclosure {
  /// No mark. The row does its work where it stands.
  none,

  /// The row opens another screen, and shows a chevron pointing that way.
  ///
  /// The chevron is decorative and is excluded from the semantic tree: the row
  /// is already announced as a button, and `hint` is where "opens the order"
  /// belongs. A screen reader that read the glyph as well would announce every
  /// row of the list twice over.
  ///
  /// **Not for a row that leaves the application.** A chevron promises the
  /// screen the back button returns from. There is deliberately no value here
  /// for "opens a browser": inventing one would mean inventing a second glyph
  /// nobody has measured, and a row whose destination is outside the
  /// application is better served by saying so in [IuxListItem.hint].
  opensScreen,
}

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
/// - the control is laid out **outside** the interactive region, never inside
///   it — beside it while it fits, below it when it does not — so neither
///   target overlaps the other;
/// - at least `kIuxMinimumTargetSpacing` separates the two, on whichever axis
///   they ended up separated by;
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
        disclosure = IuxListItemDisclosure.none,
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
  ///   disclosure: IuxListItemDisclosure.opensScreen,
  ///   onActivate: () => open(message),
  /// )
  /// ```
  ///
  /// The row is announced as a single button named by its own text, followed
  /// by [hint]. [onActivate] is non-nullable: there is no state in which the
  /// row looks activatable and is not, because a disabled row that still
  /// occupies a target is a target that lies.
  ///
  /// [disclosure] adds the chevron for a row that opens a screen. It is off by
  /// default because only the caller knows where activation leads, and a mark
  /// that appears on rows leading nowhere is one the user stops reading.
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
    this.disclosure = IuxListItemDisclosure.none,
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
  /// **A set of rows where only one may be chosen is `IuxRadioGroup`, not
  /// this.** Being a checkbox in disguise is exactly what makes the wrong
  /// arrangement seductive here: several independent choices in a list is a
  /// legitimate composition — files to delete, days to include — and it is
  /// byte-identical to a single-choice question built the wrong way. So
  /// nothing can refuse it. Build a one-answer question from these rows and
  /// you get *n* independent controls: a screen reader reads *n* toggles with
  /// no question attached, because a group of rows is not a group and there is
  /// no heading to jump to; and nothing but the caller's own `setState` stops
  /// two of them reporting `selected` at once. `IuxRadioGroup` names the
  /// question, announces each option as "1 of 4", and makes the exclusivity
  /// the component's problem rather than yours. See
  /// `IuxRadioGroupLayout.row` when the options are short enough to share a
  /// line.
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
        // A chosen row already carries a mark at its leading edge. A second
        // one at the other end, saying the row leads somewhere it does not,
        // would be two answers to "what does this row do".
        disclosure = IuxListItemDisclosure.none,
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

  /// Whether the row shows that it opens a screen.
  ///
  /// Always [IuxListItemDisclosure.none] unless the row is tappable. The mark
  /// is decorative and never announced; see [IuxListItemDisclosure].
  final IuxListItemDisclosure disclosure;

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
      disclosure: disclosure,
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
/// ## Why the control's share is a decision and not a ceiling
///
/// The control used to be laid out as a plain `Row` child, which in Flutter
/// means it is measured against **unbounded** width and takes whatever its
/// content asks for; the `Expanded` beside it then absorbs whatever is left,
/// including a negative remainder. That is fine until the control's own content
/// grows, and the thing that grows all of it at once is the user's text size.
///
/// Measured on a 320-pixel screen, an `IuxListItem.tappable` carrying an
/// `IuxStatusIndicator`: **68 pixels over at 200%** and **214 at 300%**.
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
/// **Capping the control at its share moved the failure onto the other axis
/// rather than removing it.** A cap answers "how much may you have" and never
/// asks "is that enough to be read". On a 286-pixel row the share is 86 pixels
/// and an `IuxStatusIndicator` reading one word has a minimum intrinsic width
/// of **180 at 100%** and **472 at 300%** — a single word has no wrap point, so
/// below its minimum the label breaks *inside the word*, one glyph to a line.
/// Measured, capped, on that row: the control came out **116 pixels tall at
/// 100%** against a natural 36, **286 at 150%**, **376 at 200%** and **556 at
/// 300%**, where at 300% the glyph and its gap alone (68) exceeded the 62 left
/// for them and the label was laid out in a box **zero pixels wide** — six
/// pixels of it painted outside the row. A row that was 480 tall without the
/// status was 924 with it: **444 pixels for one word**, and in a bounded
/// 320x640 box the pair overflowed 284 on the bottom where the row alone had
/// 160 to spare.
///
/// So the share is kept, and it is used as the question rather than as the
/// answer: **the control keeps the line while what it asks for fits in its
/// share, and moves under the row's text when it does not.** That is the rule
/// this component already applies one level down to the trailing *text* — the
/// title identifies the item, so it keeps the space, and the trailing element
/// is the one that gives way — except that a control gives way by *moving*,
/// because unlike a value it cannot be re-wrapped without being destroyed.
///
/// **Measured, not assumed, and this is the distinction that matters.**
/// Branching on the text scale — what [IuxListItemTokens.stacksTrailingText]
/// does for the value, and the obvious thing to reach for here — answers a
/// question about the *user's* text size with a decision that depends on the
/// *caller's* control and on the room the row was given. It would have left the
/// 100% case above broken, because 86 pixels is short of 180 at every scale.
/// `_IuxDrawerHeader` records the same finding for the same reason.
///
/// A control that fits inside its share is laid out exactly as it was before —
/// at its own width, with the region taking the remainder — so this is
/// invisible everywhere the arrangement was already sound.
class _IuxListItemWithAction extends StatelessWidget {
  const _IuxListItemWithAction({required this.region, required this.action});

  final Widget region;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final IuxListItemTokens tokens = IuxListItemResolver.resolve(context);

    return _IuxListItemArrangement(
      metrics: _IuxListItemActionMetrics(
        separation: tokens.actionSpacing,
        endPadding: tokens.horizontalPadding,
        // Where the row's own text starts: the focus ring's reserved gap and
        // then the content padding. A control that has moved below the text
        // lines up with the text rather than with the edge of the group.
        leadingInset: tokens.focusReservation + tokens.horizontalPadding,
        share: tokens.valueFlex / (tokens.textFlex + tokens.valueFlex),
      ),
      region: region,
      action: action,
    );
  }
}

/// The two things on a row that carry a control, in reading order.
enum _IuxListItemActionSlot {
  /// The part of the row that responds. Always present.
  region,

  /// The one control beside it. Always present — this arrangement is not built
  /// when there is none.
  action,
}

/// The resolved numbers the arrangement needs, and nothing else.
///
/// A render object has no `BuildContext`, which is the point rather than an
/// inconvenience: everything the layout depends on is resolved once, in
/// `build`, from the same tokens every other part of the row reads.
@immutable
class _IuxListItemActionMetrics {
  const _IuxListItemActionMetrics({
    required this.separation,
    required this.endPadding,
    required this.leadingInset,
    required this.share,
  });

  /// Between the row's target and the control's, on whichever axis they end up
  /// separated by. Never below `kIuxMinimumTargetSpacing`.
  final double separation;

  /// Between the control and the end edge of the row.
  final double endPadding;

  /// Where the row's text starts, and so where a control that has moved below
  /// it starts too.
  final double leadingInset;

  /// The fraction of the shared width a control may take and still keep the
  /// line.
  final double share;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _IuxListItemActionMetrics &&
          other.separation == separation &&
          other.endPadding == endPadding &&
          other.leadingInset == leadingInset &&
          other.share == share;

  @override
  int get hashCode => Object.hash(separation, endPadding, leadingInset, share);
}

/// The row's two arrangements, chosen by measurement at layout time.
///
/// A render object rather than a `LayoutBuilder`, for two reasons. The first is
/// that the decision needs an answer a `LayoutBuilder` cannot get: *how wide
/// would this control like to be*, which is a question about the widget the
/// caller passed and not about the text scale. The second is the one
/// `IuxAppBar` records — a `LayoutBuilder` has to build before it knows
/// anything, so it can never answer *how tall would you be at this width*, and
/// a row that cannot answer excludes every list holding it from
/// `IntrinsicHeight`, `IntrinsicWidth` and intrinsic `Table` sizing.
class _IuxListItemArrangement extends SlottedMultiChildRenderObjectWidget<
    _IuxListItemActionSlot, RenderBox> {
  const _IuxListItemArrangement({
    required this.metrics,
    required this.region,
    required this.action,
  });

  final _IuxListItemActionMetrics metrics;
  final Widget region;
  final Widget action;

  @override
  Iterable<_IuxListItemActionSlot> get slots => _IuxListItemActionSlot.values;

  @override
  Widget childForSlot(_IuxListItemActionSlot slot) => switch (slot) {
        _IuxListItemActionSlot.region => region,
        _IuxListItemActionSlot.action => action,
      };

  @override
  _RenderIuxListItemArrangement createRenderObject(BuildContext context) =>
      _RenderIuxListItemArrangement(
        metrics: metrics,
        textDirection: Directionality.of(context),
      );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderIuxListItemArrangement renderObject,
  ) {
    renderObject
      ..metrics = metrics
      ..textDirection = Directionality.of(context);
  }
}

/// Lays the row and its control onto one line, or onto two.
///
/// The decision: the control keeps the shared line while the width it asks for
/// fits inside its share of the row. It is asked rather than estimated, so the
/// control the caller actually passed is the control the arrangement is chosen
/// for.
class _RenderIuxListItemArrangement extends RenderBox
    with
        SlottedContainerRenderObjectMixin<_IuxListItemActionSlot, RenderBox>,
        DebugOverflowIndicatorMixin {
  _RenderIuxListItemArrangement({
    required _IuxListItemActionMetrics metrics,
    required TextDirection textDirection,
  })  : _metrics = metrics,
        _textDirection = textDirection;

  _IuxListItemActionMetrics get metrics => _metrics;
  _IuxListItemActionMetrics _metrics;
  set metrics(_IuxListItemActionMetrics value) {
    if (_metrics == value) return;
    _metrics = value;
    markNeedsLayout();
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    markNeedsLayout();
  }

  RenderBox get _region => childForSlot(_IuxListItemActionSlot.region)!;
  RenderBox get _action => childForSlot(_IuxListItemActionSlot.action)!;

  /// Painted, hit tested and visited in reading order.
  ///
  /// Written against the nullable slots rather than [_region] and [_action]:
  /// the mixin walks this during `attach`, which happens once per slot as each
  /// child arrives, so for one call the second slot is genuinely still empty.
  @override
  Iterable<RenderBox> get children {
    final RenderBox? region = childForSlot(_IuxListItemActionSlot.region);
    final RenderBox? action = childForSlot(_IuxListItemActionSlot.action);
    return <RenderBox>[
      if (region != null) region,
      if (action != null) action,
    ];
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! BoxParentData) child.parentData = BoxParentData();
  }

  /// Mirrors an offset measured from the leading edge under a right-to-left
  /// directionality, so the row's text still starts where reading starts.
  Offset _place(double start, double top, double width, double available) =>
      Offset(
        textDirection == TextDirection.ltr ? start : available - start - width,
        top,
      );

  /// The whole layout, shared by [performLayout] and [computeDryLayout].
  ///
  /// `positionChild` is null for the dry pass, which is what keeps the two from
  /// drifting: one description of the arrangement, measured twice.
  Size _arrange(
    BoxConstraints constraints,
    ChildLayouter layoutChild, {
    void Function(RenderBox child, Offset offset)? positionChild,
  }) {
    final RenderBox region = _region;
    final RenderBox action = _action;

    // Unbounded width is left alone rather than guessed at. A row inside a
    // horizontally scrolling parent has no share to take a fraction of, and the
    // region's own `Expanded` refuses that arrangement in terms the framework
    // wrote — which is a better answer than one this layout invented.
    if (!constraints.hasBoundedWidth) {
      final Size wanted = layoutChild(action, const BoxConstraints());
      final Size regionSize = layoutChild(region, const BoxConstraints());
      final double height = math.max(regionSize.height, wanted.height);
      if (positionChild != null) {
        positionChild(region, Offset.zero);
        positionChild(
          action,
          Offset(
            regionSize.width + metrics.separation,
            (height - wanted.height) / 2,
          ),
        );
      }
      return Size(
        regionSize.width +
            metrics.separation +
            wanted.width +
            metrics.endPadding,
        height,
      );
    }

    final double available = constraints.maxWidth;
    final double shared =
        math.max(0, available - metrics.separation - metrics.endPadding);

    // What the control asks for, given the whole row rather than its share. A
    // control measured against its share can only report the share back, so
    // asking that way could never tell a control that fits from one that has
    // been crushed into fitting.
    final Size wanted = layoutChild(
      action,
      BoxConstraints(maxWidth: math.max(0, available - metrics.endPadding)),
    );

    if (wanted.width <= shared * metrics.share) {
      // Beside. The region takes everything the control did not, so the row's
      // target reaches the control rather than stopping at the end of its
      // text: a gap between two targets that belongs to neither is a gap where
      // a tap does nothing at all.
      final double regionWidth = math.max(0, shared - wanted.width);
      final Size regionSize =
          layoutChild(region, BoxConstraints.tightFor(width: regionWidth));
      final double height = math.max(regionSize.height, wanted.height);
      if (positionChild != null) {
        positionChild(region, _place(0, 0, regionWidth, available));
        positionChild(
          action,
          _place(
            available - metrics.endPadding - wanted.width,
            (height - wanted.height) / 2,
            wanted.width,
            available,
          ),
        );
      }
      return Size(available, height);
    }

    // Below. The region takes the full width — so the target still spans the
    // row edge to edge — and the control sits under it at the leading edge,
    // re-measured against the width it now has. The separation between the two
    // targets is the same floor, on the other axis.
    final Size regionSize =
        layoutChild(region, BoxConstraints.tightFor(width: available));
    final Size below = layoutChild(
      action,
      BoxConstraints(
        maxWidth: math.max(
          0,
          available - metrics.leadingInset - metrics.endPadding,
        ),
      ),
    );
    final double top = regionSize.height + metrics.separation;
    if (positionChild != null) {
      positionChild(region, Offset.zero);
      positionChild(
        action,
        _place(metrics.leadingInset, top, below.width, available),
      );
    }
    return Size(available, top + below.height);
  }

  /// The same arrangement, measured through the intrinsic protocol.
  ///
  /// Separate from [_arrange] because nothing may be laid out during an
  /// intrinsic pass. The two agree by construction: the same decision, the same
  /// separation, the same widths handed to the same children.
  double _intrinsicHeight(double width) {
    final double wanted = _action.getMaxIntrinsicWidth(double.infinity);
    if (!width.isFinite) {
      return math.max(
        _region.getMaxIntrinsicHeight(double.infinity),
        _action.getMaxIntrinsicHeight(double.infinity),
      );
    }

    final double shared =
        math.max(0, width - metrics.separation - metrics.endPadding);
    if (wanted <= shared * metrics.share) {
      return math.max(
        _region.getMaxIntrinsicHeight(math.max(0, shared - wanted)),
        _action.getMaxIntrinsicHeight(wanted),
      );
    }

    final double room =
        math.max(0, width - metrics.leadingInset - metrics.endPadding);
    return _region.getMaxIntrinsicHeight(width) +
        metrics.separation +
        _action.getMaxIntrinsicHeight(math.min(wanted, room));
  }

  /// The width the row asks for when nothing constrains it: the region, the
  /// separation, the control, and the control's end padding.
  double _intrinsicWidth(double region, double action) =>
      region + metrics.separation + action + metrics.endPadding;

  @override
  double computeMinIntrinsicWidth(double height) => _intrinsicWidth(
        _region.getMinIntrinsicWidth(double.infinity),
        _action.getMinIntrinsicWidth(double.infinity),
      );

  @override
  double computeMaxIntrinsicWidth(double height) => _intrinsicWidth(
        _region.getMaxIntrinsicWidth(double.infinity),
        _action.getMaxIntrinsicWidth(double.infinity),
      );

  @override
  double computeMinIntrinsicHeight(double width) => _intrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) => _intrinsicHeight(width);

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.constrain(
        _arrange(constraints, ChildLayoutHelper.dryLayoutChild),
      );

  /// What the arrangement asked for, before the incoming constraints had their
  /// say.
  ///
  /// Kept so an overflow is *reported* rather than absorbed. Clamping the
  /// returned size to the constraints is obligatory; doing only that would make
  /// a row that does not fit paint over whatever follows it in silence, which
  /// is the one thing worse than not fitting. The `Column` this arrangement
  /// replaced reported it, so this has to as well.
  Size _arranged = Size.zero;

  final LayerHandle<ClipRectLayer> _clip = LayerHandle<ClipRectLayer>();

  bool get _overflows =>
      _arranged.width - size.width > precisionErrorTolerance ||
      _arranged.height - size.height > precisionErrorTolerance;

  @override
  void dispose() {
    _clip.layer = null;
    super.dispose();
  }

  @override
  void performLayout() {
    _arranged = _arrange(
      constraints,
      ChildLayoutHelper.layoutChild,
      positionChild: (RenderBox child, Offset offset) =>
          (child.parentData! as BoxParentData).offset = offset,
    );
    size = constraints.constrain(_arranged);
  }

  void _paintChildren(PaintingContext context, Offset offset) {
    for (final RenderBox child in children) {
      context.paintChild(
        child,
        (child.parentData! as BoxParentData).offset + offset,
      );
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!_overflows) {
      _clip.layer = null;
      _paintChildren(context, offset);
      return;
    }

    _clip.layer = context.pushClipRect(
      needsCompositing,
      offset,
      Offset.zero & size,
      _paintChildren,
      oldLayer: _clip.layer,
    );

    assert(() {
      paintOverflowIndicator(
        context,
        offset,
        Offset.zero & size,
        Offset.zero & _arranged,
        overflowHints: <DiagnosticsNode>[
          ErrorDescription(
            'The row was given ${size.height.toStringAsFixed(1)} pixels of '
            'height and its content needs '
            '${_arranged.height.toStringAsFixed(1)}.',
          ),
          ErrorHint(
            'A list row wraps its text and never truncates it, so at an '
            'enlarged text size it can be several times the height of a line. '
            'That is the row doing what it is for. Put the list in something '
            'that scrolls — IuxPage, a ListView, a SingleChildScrollView — '
            'rather than in a box of a fixed height: a row that scrolled '
            'inside itself would hide the very text it refused to truncate.',
          ),
        ],
      );
      return true;
    }());
  }

  @override
  Rect? describeApproximatePaintClip(RenderObject child) =>
      _overflows ? Offset.zero & size : null;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    // Reverse of paint order, so the control on top of nothing is still asked
    // first and a row never swallows a tap meant for it.
    for (final RenderBox child in children.toList().reversed) {
      final BoxParentData parentData = child.parentData! as BoxParentData;
      final bool hit = result.addWithPaintOffset(
        offset: parentData.offset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) =>
            child.hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    return false;
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
    required this.disclosure,
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
  final IuxListItemDisclosure disclosure;
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
      disclosure: widget.disclosure,
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
        // The press and hover tint, above the chosen background and *below*
        // the content — which is the whole of `IUX-LISTITEM-STATE-001`.
        //
        // It used to be the last child of this stack, painted over everything.
        // Every colour in this package is opaque, on purpose, so at the full
        // opacity the resolver hands it that layer did not tint the row: it
        // covered it. Measured by counting the row's own dark pixels — 8226 at
        // rest, **0 while pressed**, 8226 after release. For the length of
        // every tap the title, the supporting line and the value were simply
        // not there, and the audit that found it on a device reported the row
        // as "staying selected", because a blank grey band is what a selected
        // row looks like when you cannot read what is in it.
        //
        // Underneath, the same colour is the row's background for the duration
        // of the press. That also makes the state measurable for the first
        // time: text over a tint has a contrast ratio, text under an opaque
        // rectangle has none.
        //
        // It stays *outside* the focus ring's reserved gap, like the chosen
        // background and like the gesture detector below it. A tint that
        // stopped at the ring would leave an unreacting strip all around a row
        // that does respond there — the audit's "la zone visuellement réactive
        // correspond à toute la cible tactile".
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
    required this.disclosure,
    required this.guardLeading,
  });

  final IuxListItemTokens tokens;
  final String title;
  final String? subtitle;
  final String? trailingText;
  final Widget? leading;
  final Widget? mark;
  final IuxListItemDisclosure disclosure;
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
        // After the value and separated from it, so a count and a chevron
        // stay two things — "Médecins 12 ›" and not a number wearing an
        // arrow. Outside the `Expanded` that holds the value, so it never
        // takes the place of the thing the row reports.
        if (disclosure == IuxListItemDisclosure.opensScreen) ...<Widget>[
          SizedBox(width: tokens.gap),
          _FirstLineBand(
            extent: tokens.lineExtent,
            child: _IuxDisclosureChevron(tokens: tokens),
          ),
        ],
      ],
    );
  }
}

/// The mark on a row that opens a screen.
///
/// Drawn from the row's own tokens rather than through `IuxIcon`, for the
/// reason `IuxIcon` itself states: a component that already sizes and colours
/// its glyphs must not take one from outside, or the contrast guarantee leaves
/// with the widget. `_IuxSelectionMark` is the same decision one slot over.
class _IuxDisclosureChevron extends StatelessWidget {
  const _IuxDisclosureChevron({required this.tokens});

  final IuxListItemTokens tokens;

  @override
  Widget build(BuildContext context) {
    // Chosen from the reading direction rather than from `matchTextDirection`,
    // which mirrors the glyph's *painting* and leaves an arrow that is a
    // mirrored right-chevron rather than the left one the font already has.
    final bool rtl = Directionality.of(context) == TextDirection.rtl;

    return ExcludeSemantics(
      child: Icon(
        rtl ? Icons.chevron_left : Icons.chevron_right,
        size: tokens.disclosureSize,
        color: tokens.disclosureColor,
        // Already scaled once, by the resolver, through the same runtime every
        // other IUX component reads. Letting Flutter scale it again would
        // enlarge the chevron past the line it belongs to.
        applyTextScaling: false,
      ),
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
            'outside the row rather than inside it — beside its text while it '
            'fits there and below it when it does not — keeps at least the '
            'minimum target separation either way, and stays its own named '
            'stop for a screen reader. `leading` is for an icon or an avatar.',
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
