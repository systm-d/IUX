import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../accessibility/iux_focus.dart';
import '../../accessibility/iux_semantics.dart';
import '../../inputs/iux_input_descriptor.dart';
import '../../inputs/iux_input_model.dart';
import '../../layout/iux_vertical_separator.dart';
import '../selection/iux_selection_model.dart';
import '../selection/iux_selection_tokens.dart';
import '../status/iux_status_model.dart';
import '../status/iux_value_indicator.dart';
import 'iux_list_tokens.dart';

/// Which of the four forms a row takes.
///
/// Private, and it stays private. The first three differ in what a tap
/// *means* — nothing, "open this", "choose this" — so a public parameter
/// choosing between them would let a call site swap one meaning for another
/// without changing anything the user can see. [dense] means the same as
/// [tappable] and differs in what the row *carries*, which is a difference of
/// arrangement rather than of outcome; it is here rather than in a flag
/// because the arrangement it selects is a different render object.
enum _IuxListItemKind { plain, tappable, selectable, dense }

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

/// One measured fact on a dense row.
///
/// ```dart
/// IuxRowDetail(
///   glyph: Icons.wb_sunny_outlined,
///   label: l10n.longestDrySpell,
///   value: l10n.days(36),
/// )
/// ```
///
/// **Strings, an icon and one qualifier — never a widget.** [IuxListItem] runs
/// a debug-only subtree check on [IuxListItem.leading] precisely because a
/// widget slot lets a control into a row that is itself one control, and a
/// screen reader then announces a button inside a button. There is nothing to
/// check here: a `String`, an `IconData` and an [IuxValue] cannot be tapped.
///
/// **And a value type is what makes the fold measurable.** The row decides
/// whether the details keep the line by asking them for their *minimum
/// intrinsic width*, and `getMinIntrinsicWidth` throws for any subtree holding
/// a `LayoutBuilder` — `IuxTooltip` and `IuxAppBar` both hold one. A row that
/// asked a caller's widget for its minimum could crash on a legal child. The
/// row builds this content itself, so it can ask without asking a stranger.
/// See `docs/decisions/ADR-0012-dense-rows-fold.md`.
///
/// **A fact compared down the column, not a sentence.** [value] is what a
/// reader reads across five rows — `36 days`, `434 mm` — and [label] names the
/// quantity being compared. A dense row whose details are prose folds
/// correctly and reads as a paragraph in two columns. Nothing here can refuse
/// that, which is why ADR-0012 wrote it into the decision.
///
/// [glyph] is decorative and excluded from the semantic tree: it repeats what
/// [label] says, and a glyph carrying more than the label is information a
/// screen-reader user never receives.
///
/// **There is no `note`.** A second string under the value would compete with
/// [qualifier] for the one place under it, and ADR-0012 refused to open that
/// layout question before the first one had been measured.
@immutable
final class IuxRowDetail {
  /// Creates one fact.
  const IuxRowDetail({
    required this.value,
    this.label,
    this.glyph,
    this.qualifier,
  })  : assert(
          value.length > 0,
          'A detail with no value reserves a column for a measurement that '
          'never arrives. Leave the detail out.',
        ),
        assert(
          label == null || label.length > 0,
          'An empty label reserves a line and says nothing. Pass null.',
        );

  /// The measurement, already formatted and localised.
  final String value;

  /// What the measurement is, drawn above it and announced with it.
  final String? label;

  /// A decorative glyph beside the value. Drawn, never announced.
  final IconData? glyph;

  /// A tonal pill under the value, when the measurement has been compared.
  ///
  /// An [IuxValue] and not an `IuxStatus`: a rainfall total read against a
  /// thirty-year normal is a reading, not news, and sending it through
  /// `IuxStatusTone.error` to obtain a red pill ships the judgement *this is a
  /// malfunction* as a colour. See
  /// `docs/decisions/ADR-0013-a-reading-is-compared-not-judged.md`.
  final IuxValue? qualifier;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxRowDetail &&
          other.value == value &&
          other.label == label &&
          other.glyph == glyph &&
          other.qualifier == qualifier;

  @override
  int get hashCode => Object.hash(value, label, glyph, qualifier);
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
        details = null,
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
        details = null,
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
        details = null,
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

  /// Creates a row that carries several measurements about one item.
  ///
  /// ```dart
  /// IuxListItem.dense(
  ///   title: l10n.year(2022),
  ///   subtitle: l10n.rainyDays(112),
  ///   leading: rankMark,
  ///   details: <IuxRowDetail>[dryStreak, total],
  ///   hint: l10n.opensTheYear,
  ///   disclosure: IuxListItemDisclosure.opensScreen,
  ///   onActivate: () => open(2022),
  /// )
  /// ```
  ///
  /// **The details fold.** They sit beside the row's text while what they ask
  /// for fits in their share of the width, and *all* of them move below it
  /// when it does not — see `docs/decisions/ADR-0012-dense-rows-fold.md`. That
  /// is the rule this component already applies to a trailing control,
  /// generalised: a block that cannot be re-wrapped without being destroyed
  /// gives way by *moving*. There is no per-detail fold: the details are one
  /// child of the arrangement, so a row in which one detail keeps the line and
  /// another has dropped below it is not a case this layout can reach.
  ///
  /// **Tappable only, and there is no trailing control.** A row showing five
  /// facts and doing nothing is a table row, and `IuxDataTable` exists. A
  /// control beside a row already carrying two detail blocks is a fourth thing
  /// competing for a width that has none left; put it on the screen the row
  /// opens.
  ///
  /// **One stop for a screen reader.** The details are merged into the row's
  /// single node, in reading order, after the title and the supporting line —
  /// and the announcement is the same whether they kept the line or moved
  /// under it. Six stops per row over five rows is thirty swipes to read a
  /// table of five years.
  ///
  /// **Nine parameters, where the other two interactive rows take eleven.**
  /// It drops `semanticLabel` — a dense row is named by its own text, of which
  /// it has more than any other row — `autofocus`, because a row in the middle
  /// of a list is not an entry point, `trailingText`, because a detail
  /// carrying only a value *is* a trailing text, and `trailingAction`, for the
  /// reason above.
  const IuxListItem.dense({
    super.key,
    required this.title,
    required VoidCallback this.onActivate,
    required List<IuxRowDetail> this.details,
    this.subtitle,
    this.leading,
    this.hint,
    this.disclosure = IuxListItemDisclosure.none,
    this.focusNode,
  })  : _kind = _IuxListItemKind.dense,
        trailingText = null,
        trailingAction = null,
        semanticLabel = null,
        selected = IuxSelectionState.unselected,
        onSelectedChanged = null,
        autofocus = false,
        assert(
          title.length > 0,
          'A dense row must say what all these measurements are about. '
          'Without a title the row is five numbers with no subject.',
        ),
        assert(
          subtitle == null || subtitle.length > 0,
          'Empty supporting text reserves a line and says nothing. Pass null.',
        ),
        assert(
          details.length > 0,
          'A dense row with no details is IuxListItem.tappable, which is '
          'lighter and already handles this shape.',
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

  /// The measurements this row carries, on the dense form. Null elsewhere.
  ///
  /// Two is the shape this was measured for. Nothing refuses four, and four
  /// fold at a lower text scale than two — see *Limits* in
  /// `docs/components/list-items.md`. There is no cap, because a cap is a
  /// number and nobody has measured one.
  final List<IuxRowDetail>? details;

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
      details: details,
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
    required this.details,
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
  final List<IuxRowDetail>? details;
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
      case _IuxListItemKind.dense:
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
      details: widget.details,
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
        button: widget.kind == _IuxListItemKind.tappable ||
                widget.kind == _IuxListItemKind.dense
            ? true
            : null,
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
    required this.details,
    required this.mark,
    required this.disclosure,
    required this.guardLeading,
  });

  final IuxListItemTokens tokens;
  final String title;
  final String? subtitle;
  final String? trailingText;
  final Widget? leading;
  final List<IuxRowDetail>? details;
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

    final List<IuxRowDetail>? blocks = details;

    // No line limit and no ellipsis, at any text scale. Truncating the title
    // removes the only thing that tells this item from the next one, and
    // truncation gets worse exactly when someone has enlarged their text in
    // order to read it.
    //
    // On a dense row the title also reports its whole line as its minimum,
    // which is what decides the fold below. Only there: a row with no details
    // has nothing that could move out of the title's way, so asking for the
    // line would ask for something no arrangement can give.
    final Widget headline = Text(title, style: tokens.titleStyle);
    final Widget rowTitle =
        blocks == null ? headline : _TitleKeepsItsLine(child: headline);

    final Widget texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        rowTitle,
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

    if (blocks != null) {
      // A render object rather than a `Row`, and it owns the whole row rather
      // than the space between the leading element and the chevron: the
      // details that have left the line take the row's *inner* width, which is
      // not the width that was left between two things sitting on the line.
      return _IuxRowDetailsArrangement(
        // The floor the details are never laid out below while they keep the
        // line — the same fraction the trailing value and the trailing control
        // already take, so a row does not have three different ideas of how
        // much of itself belongs to its right-hand side.
        share: tokens.valueFlex / (tokens.textFlex + tokens.valueFlex),
        gap: tokens.gap,
        direction: Directionality.of(context),
        leading: lead == null
            ? null
            : _FirstLineBand(
                extent: tokens.lineExtent,
                child: guardLeading ? _IuxRowContentGuard(child: lead) : lead,
              ),
        texts: texts,
        details: _IuxRowDetails(details: blocks, tokens: tokens),
        disclosure: disclosure == IuxListItemDisclosure.opensScreen
            ? _FirstLineBand(
                extent: tokens.lineExtent,
                child: _IuxDisclosureChevron(tokens: tokens),
              )
            : null,
      );
    }

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

/// The detail blocks of a dense row, side by side, ruled apart.
///
/// Built by the row rather than passed in, which is what lets the arrangement
/// above ask it for a minimum intrinsic width without the `LayoutBuilder`
/// hazard `ADR-0012` records against a widget slot.
class _IuxRowDetails extends StatelessWidget {
  const _IuxRowDetails({required this.details, required this.tokens});

  final List<IuxRowDetail> details;
  final IuxListItemTokens tokens;

  @override
  Widget build(BuildContext context) {
    Widget block(IuxRowDetail detail) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (detail.label != null) ...<Widget>[
              // No line limit and no ellipsis, like every other string on this
              // row: a label truncated to "Longest dry spe…" names nothing.
              Text(detail.label!, style: tokens.detailLabelStyle),
              SizedBox(height: tokens.textGap),
            ],
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (detail.glyph != null) ...<Widget>[
                  // Decorative: it repeats what the label says, and the label
                  // is already in the row's merged announcement.
                  IuxSemantics.decorative(
                    child: Icon(
                      detail.glyph,
                      size: tokens.detailValueStyle.fontSize,
                      color: tokens.detailLabelStyle.color,
                      // Scaled by Flutter, unlike the chevron, because the
                      // size it is given here is the *unscaled* size of the
                      // value beside it — a `TextStyle.fontSize`, which the
                      // framework scales at paint. Pre-scaling this one would
                      // scale it twice.
                      applyTextScaling: true,
                    ),
                  ),
                  SizedBox(width: tokens.detailGap),
                ],
                Flexible(
                  child: Text(detail.value, style: tokens.detailValueStyle),
                ),
              ],
            ),
            if (detail.qualifier != null) ...<Widget>[
              SizedBox(height: tokens.textGap),
              IuxValueIndicator(value: detail.qualifier!),
            ],
          ],
        );

    return IntrinsicHeight(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        // Stretched so the rules run the full height of the tallest block.
        // `IuxVerticalSeparator` has no height of its own by design.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int i = 0; i < details.length; i++) ...<Widget>[
            if (i > 0) ...<Widget>[
              SizedBox(width: tokens.detailGap),
              const IuxVerticalSeparator(),
              SizedBox(width: tokens.detailGap),
            ],
            Flexible(child: block(details[i])),
          ],
        ],
      ),
    );
  }
}

/// A title that asks for the width of its whole line, not of its longest word.
///
/// Transparent at layout — it takes the width it is given and its child wraps
/// in it exactly as before — and it changes one number: the minimum intrinsic
/// width the row's text reports. `Text` reports its **longest word**, because
/// that is the narrowest box it can paint in without clipping, and
/// [_RenderIuxRowDetails] takes that number twice: to decide whether the
/// details keep the line, and to bound how much of the line they may take.
///
/// Both readings were wrong for a title, and the same measurement says so.
/// Three dense rows on a Pixel 7 at 100% in the test font, carrying the same
/// two details and differing only in the length of their longest word — the
/// line offers 335.4 px, the details need 235.0, and 88.4 are left for the
/// text:
///
/// | Title | Longest word | Its line | What happened |
/// | --- | --- | --- | --- |
/// | `September 2025` | 146.3 | 227.5 | folds, title whole |
/// | `March 2026` | 81.3 | 162.5 | keeps the line, 88.4 offered for 162.5 |
/// | `July 2025` | 65.0 | 146.3 | keeps the line, 88.4 offered for 146.3 |
///
/// Two of the three concluded that the row fits from a width at which their
/// title was already in pieces, and then drew in that width. Nothing separates
/// the three but a space in a string.
///
/// So the title reports the width at which it is whole, and the row's rule
/// becomes: **the details keep the line only when nothing on it breaks and the
/// title is not wrapped.** It is the one change that closes both readings,
/// because both read the same number.
///
/// The subtitle is deliberately left alone. A supporting line is prose and
/// gives way by wrapping, which is what `IUX-LISTITEM-TRAILING-001`'s rule
/// says a value does; the title is the row's identity and is what a reader
/// scans a list by. Requiring the subtitle's line too was measured and
/// rejected: measured on the pilot's row it moves the fold threshold from
/// **440.00 px of screen to 603.00**, which is past every phone, so the
/// unfolded arrangement would be unreachable for any dense row carrying a
/// supporting line — and three of this row's own measured guarantees, the
/// 442/438 pair among them, would have had to be rewritten to say so.
class _TitleKeepsItsLine extends SingleChildRenderObjectWidget {
  const _TitleKeepsItsLine({required Widget super.child});

  @override
  _RenderTitleKeepsItsLine createRenderObject(BuildContext context) =>
      _RenderTitleKeepsItsLine();
}

class _RenderTitleKeepsItsLine extends RenderProxyBox {
  /// The width the child needs in order not to wrap.
  ///
  /// Larger than the child's own minimum, and that is the whole of it. It is
  /// not a claim that the title cannot be painted narrower — it can, and a
  /// folded row that is still too narrow paints it on two lines — it is the
  /// row saying that a width at which its title breaks is not a width it will
  /// choose while it has somewhere to move the details to.
  @override
  double computeMinIntrinsicWidth(double height) =>
      child?.getMaxIntrinsicWidth(height) ?? 0;
}

/// The four things on a dense row, in reading order.
enum _IuxRowDetailsSlot {
  /// The rank mark or avatar. Absent on a row that has none.
  leading,

  /// The title and the supporting line. Always present.
  texts,

  /// The measurements. Always present — this arrangement is not built without
  /// them.
  details,

  /// The chevron. Absent unless the row says it opens a screen.
  disclosure,
}

/// Lays the details beside the row's text, or under it when they do not fit.
///
/// A render object rather than a `LayoutBuilder`, for the reason
/// [_IuxListItemArrangement] is one: the decision needs the two blocks'
/// *minimum intrinsic width* — what they would need in order to be drawn
/// without a word being broken, rather than what they were given — and a
/// `LayoutBuilder` has to build before it can know anything.
///
/// It owns the leading element and the chevron as well, rather than sitting
/// between them inside a `Row`, and that is not tidiness. A detail block that
/// has left the line takes the **row's** inner width; the width left over
/// between an avatar and a chevron is a different, smaller number, and handing
/// it to a block that has already been refused the line is how a fold stops
/// being a remedy. Measured on the pilot's row at 300% on a Pixel 7: 155.4
/// pixels between the two against 371.4 across the row, and the narrower of
/// the two overflows inside the qualifier's pill.
class _IuxRowDetailsArrangement
    extends SlottedMultiChildRenderObjectWidget<_IuxRowDetailsSlot, RenderBox> {
  const _IuxRowDetailsArrangement({
    required this.share,
    required this.gap,
    required this.direction,
    required this.leading,
    required this.texts,
    required this.details,
    required this.disclosure,
  });

  /// The fraction of the shared width the details are never drawn below while
  /// they keep the line.
  final double share;

  /// Between any two of the four, on whichever axis they end up separated by.
  final double gap;

  /// Which edge reading starts from.
  final TextDirection direction;

  final Widget? leading;
  final Widget texts;
  final Widget details;
  final Widget? disclosure;

  @override
  Iterable<_IuxRowDetailsSlot> get slots => _IuxRowDetailsSlot.values;

  @override
  Widget? childForSlot(_IuxRowDetailsSlot slot) => switch (slot) {
        _IuxRowDetailsSlot.leading => leading,
        _IuxRowDetailsSlot.texts => texts,
        _IuxRowDetailsSlot.details => details,
        _IuxRowDetailsSlot.disclosure => disclosure,
      };

  @override
  _RenderIuxRowDetails createRenderObject(BuildContext context) =>
      _RenderIuxRowDetails(share: share, gap: gap, direction: direction);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderIuxRowDetails renderObject,
  ) {
    renderObject
      ..share = share
      ..gap = gap
      ..direction = direction;
  }
}

/// Lays a dense row onto one line, or onto two.
///
/// **The decision, and why it is not the share.** The trailing control's
/// arrangement asks whether what the control wants fits inside its third. That
/// question was measured here before it was reused, and it answers *no* at
/// every text scale: on the pilot's row the third is 119.8 pixels at 100% on a
/// bare Pixel 7 and the two detail blocks need 235 to be drawn without a word
/// being broken, so a share-based decision folds the row the maquette draws
/// unfolded. That is the failure `IUX-LISTITEM-TRAILING-001` recorded against
/// branching on the text scale — *86 pixels is short of 180 at every scale, so
/// it would have left the 100% case broken* — arriving from the other side.
///
/// So the question asked here is the one the incident's rule is *about*: can
/// the row's text and the details both be laid out on this line without a word
/// being broken. That is `textMin + gap + detailMin <= inner`, it is a
/// measurement of the content the caller actually passed, and it is the
/// weakest condition under which nothing on the line breaks inside itself.
/// The share stays, one job smaller: it is the floor the details are never
/// drawn below while they keep the line, so a row carrying one short detail
/// puts it exactly where a plain row puts its trailing value.
class _RenderIuxRowDetails extends RenderBox
    with
        SlottedContainerRenderObjectMixin<_IuxRowDetailsSlot, RenderBox>,
        DebugOverflowIndicatorMixin {
  _RenderIuxRowDetails({
    required double share,
    required double gap,
    required TextDirection direction,
  })  : _share = share,
        _gap = gap,
        _direction = direction;

  double get share => _share;
  double _share;
  set share(double value) {
    if (_share == value) return;
    _share = value;
    markNeedsLayout();
  }

  double get gap => _gap;
  double _gap;
  set gap(double value) {
    if (_gap == value) return;
    _gap = value;
    markNeedsLayout();
  }

  /// Read rather than inferred from the constraints: which edge the details sit
  /// against is a reading-order question, and a render object that guessed it
  /// would put the block on the opposite side from the chevron in Arabic.
  TextDirection get direction => _direction;
  TextDirection _direction;
  set direction(TextDirection value) {
    if (_direction == value) return;
    _direction = value;
    markNeedsLayout();
  }

  RenderBox? get _leading => childForSlot(_IuxRowDetailsSlot.leading);
  RenderBox get _texts => childForSlot(_IuxRowDetailsSlot.texts)!;
  RenderBox get _details => childForSlot(_IuxRowDetailsSlot.details)!;
  RenderBox? get _disclosure => childForSlot(_IuxRowDetailsSlot.disclosure);

  /// Painted, hit tested and visited in reading order.
  ///
  /// Written against the nullable slots for the reason
  /// [_RenderIuxListItemArrangement.children] gives: the mixin walks this
  /// during `attach`, once per slot as each child arrives, so for one call the
  /// later slots are genuinely still empty.
  @override
  Iterable<RenderBox> get children => <RenderBox>[
        for (final _IuxRowDetailsSlot slot in _IuxRowDetailsSlot.values)
          if (childForSlot(slot) case final RenderBox child) child,
      ];

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! BoxParentData) child.parentData = BoxParentData();
  }

  /// Mirrors an offset measured from the leading edge under a right-to-left
  /// directionality, so the row's text still starts where reading starts.
  Offset _place(double start, double top, double extent, double available) =>
      Offset(
        _direction == TextDirection.ltr ? start : available - start - extent,
        top,
      );

  /// The whole arrangement, shared by [performLayout] and [computeDryLayout].
  ///
  /// `positionChild` is null for the dry pass, which is what keeps the two from
  /// drifting: one description of the arrangement, measured twice.
  Size _arrange(
    BoxConstraints constraints,
    ChildLayouter layoutChild, {
    void Function(RenderBox child, Offset offset)? positionChild,
  }) {
    final RenderBox? leading = _leading;
    final RenderBox? chevron = _disclosure;
    final RenderBox texts = _texts;
    final RenderBox details = _details;

    // Unbounded width is left alone rather than guessed at, for the reason
    // [_RenderIuxListItemArrangement] gives: there is no share to take a
    // fraction of and nothing to be too narrow for, so every part takes what
    // it asks for and the row keeps its line.
    if (!constraints.hasBoundedWidth) {
      const BoxConstraints free = BoxConstraints();
      final Size leadSize =
          leading == null ? Size.zero : layoutChild(leading, free);
      final Size textSize = layoutChild(texts, free);
      final Size detailSize = layoutChild(details, free);
      final Size markSize =
          chevron == null ? Size.zero : layoutChild(chevron, free);
      double x = 0;
      double advance(Size size, RenderBox? child) {
        if (child != null && positionChild != null) {
          positionChild(child, Offset(x, 0));
        }
        final double at = x;
        x += size.width + _gap;
        return at;
      }

      advance(leadSize, leading);
      advance(textSize, texts);
      advance(detailSize, details);
      advance(markSize, chevron);
      return Size(
        x - _gap,
        <double>[
          leadSize.height,
          textSize.height,
          detailSize.height,
          markSize.height,
        ].reduce(math.max),
      );
    }

    final double width = constraints.maxWidth;
    final BoxConstraints loose = BoxConstraints(maxWidth: width);
    // The two fixed elements are measured first: they take what they need at
    // this text size, and what is left is what the line has to offer.
    final Size leadSize =
        leading == null ? Size.zero : layoutChild(leading, loose);
    final Size markSize =
        chevron == null ? Size.zero : layoutChild(chevron, loose);
    final double textStart =
        leading == null ? 0 : math.min(width, leadSize.width + _gap);
    final double markSpace = chevron == null ? 0 : markSize.width + _gap;
    final double line = math.max(0, width - textStart - markSpace);

    final double textMin = texts.getMinIntrinsicWidth(double.infinity);
    final double detailMin = details.getMinIntrinsicWidth(double.infinity);
    final bool folds = textMin + _gap + detailMin > line;

    if (!folds) {
      final double shared = math.max(0, line - _gap);
      // Never below the share a trailing value would have had, never below
      // what the details need, and never so wide that the text is left with
      // less than it needs. The three cannot conflict: the branch is only
      // taken when both minima fit.
      final double detailWidth = clampDouble(
          shared * _share, detailMin, math.max(0, shared - textMin));
      final double textWidth = math.max(0, shared - detailWidth);
      final Size textSize =
          layoutChild(texts, BoxConstraints.tightFor(width: textWidth));
      final Size detailSize =
          layoutChild(details, BoxConstraints.tightFor(width: detailWidth));
      final double height = <double>[
        leadSize.height,
        textSize.height,
        detailSize.height,
        markSize.height,
      ].reduce(math.max);
      if (positionChild != null) {
        if (leading != null) {
          positionChild(leading, _place(0, 0, leadSize.width, width));
        }
        positionChild(texts, _place(textStart, 0, textWidth, width));
        positionChild(
          details,
          _place(textStart + textWidth + _gap, 0, detailWidth, width),
        );
        if (chevron != null) {
          positionChild(
            chevron,
            _place(width - markSize.width, 0, markSize.width, width),
          );
        }
      }
      return Size(width, height);
    }

    // Folded. The details take the row's inner width from where its text
    // starts — about three times the share they were refused — and sit under
    // the text, aligned with it rather than with the edge of the group,
    // because a block that has moved below the text belongs to it.
    final Size textSize =
        layoutChild(texts, BoxConstraints.tightFor(width: line));
    final double first = <double>[
      leadSize.height,
      textSize.height,
      markSize.height,
    ].reduce(math.max);
    final double detailWidth = math.max(0, width - textStart);
    final Size detailSize =
        layoutChild(details, BoxConstraints.tightFor(width: detailWidth));
    if (positionChild != null) {
      if (leading != null) {
        positionChild(leading, _place(0, 0, leadSize.width, width));
      }
      positionChild(texts, _place(textStart, 0, line, width));
      if (chevron != null) {
        positionChild(
          chevron,
          _place(width - markSize.width, 0, markSize.width, width),
        );
      }
      positionChild(
        details,
        _place(textStart, first + _gap, detailWidth, width),
      );
    }
    return Size(width, first + _gap + detailSize.height);
  }

  /// What the two fixed elements cost the line, measured through the intrinsic
  /// protocol.
  double _fixed(double height) {
    final RenderBox? leading = _leading;
    final RenderBox? chevron = _disclosure;
    return (leading == null ? 0 : leading.getMaxIntrinsicWidth(height) + _gap) +
        (chevron == null ? 0 : chevron.getMaxIntrinsicWidth(height) + _gap);
  }

  /// The same arrangement, measured through the intrinsic protocol.
  ///
  /// Separate from [_arrange] because nothing may be laid out during an
  /// intrinsic pass. The two agree by construction: the same decision, the
  /// same widths handed to the same children.
  double _intrinsicHeight(double width) {
    final RenderBox? leading = _leading;
    final RenderBox? chevron = _disclosure;
    final double lead =
        leading == null ? 0 : leading.getMaxIntrinsicHeight(double.infinity);
    final double mark =
        chevron == null ? 0 : chevron.getMaxIntrinsicHeight(double.infinity);
    if (!width.isFinite) {
      return <double>[
        lead,
        _texts.getMaxIntrinsicHeight(double.infinity),
        _details.getMaxIntrinsicHeight(double.infinity),
        mark,
      ].reduce(math.max);
    }

    final double textStart = leading == null
        ? 0
        : math.min(width, leading.getMaxIntrinsicWidth(double.infinity) + _gap);
    final double line = math.max(0, width - _fixed(double.infinity));
    final double textMin = _texts.getMinIntrinsicWidth(double.infinity);
    final double detailMin = _details.getMinIntrinsicWidth(double.infinity);

    if (textMin + _gap + detailMin <= line) {
      final double shared = math.max(0, line - _gap);
      final double detailWidth = clampDouble(
        shared * _share,
        detailMin,
        math.max(0, shared - textMin),
      );
      return <double>[
        lead,
        _texts.getMaxIntrinsicHeight(math.max(0, shared - detailWidth)),
        _details.getMaxIntrinsicHeight(detailWidth),
        mark,
      ].reduce(math.max);
    }

    final double first = <double>[
      lead,
      _texts.getMaxIntrinsicHeight(line),
      mark,
    ].reduce(math.max);
    return first +
        _gap +
        _details.getMaxIntrinsicHeight(math.max(0, width - textStart));
  }

  /// The narrowest the row can be laid out in.
  ///
  /// The *maximum* of the two minima and not their sum, because at that width
  /// the arrangement has folded and each of them has the whole line. Returning
  /// the text's minimum alone — the shape a first reading suggests — would
  /// promise a width the details cannot be drawn in.
  @override
  double computeMinIntrinsicWidth(double height) =>
      _fixed(height) +
      math.max(
        _texts.getMinIntrinsicWidth(height),
        _details.getMinIntrinsicWidth(height),
      );

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _fixed(height) +
      _texts.getMaxIntrinsicWidth(height) +
      _gap +
      _details.getMaxIntrinsicWidth(height);

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
  /// Kept so an overflow is *reported* rather than absorbed, which is the rule
  /// [_RenderIuxListItemArrangement] already follows: a row that does not fit
  /// and paints over whatever follows it in silence is worse than one that
  /// does not fit.
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
            'The dense row was given ${size.height.toStringAsFixed(1)} pixels '
            'of height and its content needs '
            '${_arranged.height.toStringAsFixed(1)}.',
          ),
          ErrorHint(
            'A dense row moves its details under its text rather than '
            'truncating them, so at an enlarged text size it is several times '
            'the height of a line. Put the list in something that scrolls — '
            'IuxPage, a ListView, a SingleChildScrollView — rather than in a '
            'box of a fixed height.',
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
    // Reverse of paint order, so the element on top is asked first.
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
