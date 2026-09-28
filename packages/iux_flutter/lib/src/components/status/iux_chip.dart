import 'package:flutter/material.dart';

import '../../accessibility/iux_focus.dart';
import '../../accessibility/iux_focus_ownership.dart';
import '../../accessibility/iux_semantics.dart';
import '../../actions/iux_action_descriptor.dart';
import '../../actions/iux_action_model.dart';
import '../../layout/iux_spacing_primitives.dart';
import '../button/iux_button.dart';
import 'iux_status_tokens.dart';

/// A compact label the user cannot act on, except — in one form — to remove it.
///
/// ```dart
/// IuxTagChip(label: l10n.categoryVegetarian)
/// ```
///
/// **Use it** to show an attribute a record already has — a category, a tag, a
/// language, a plan tier. It is a readable summary of data, sitting where a
/// sentence would be too long.
///
/// **Do not use it** for anything the user can change or choose: that is
/// [IuxFilterChip], and the difference is not cosmetic. (Taking a tag out of a
/// list the user built is the one exception, and it has its own constructor —
/// see [IuxTagChip.removable] below.) A tag takes no focus,
/// has no touch target, announces no selected state and reports no gesture, so
/// a user who tried to act on one would get silence. Do not use it to report a
/// state either — an order that failed is `IuxStatusIndicator`, which has room
/// to say what went wrong. Do not use it as a button; a chip-shaped button is a
/// button that nobody can find with a screen reader, because it announces
/// itself as text.
///
/// **Accessibility.** This is the half of the chip API that must *not* look
/// like a control. It is announced as a plain labelled group with no button
/// flag, is skipped by focus traversal, and is drawn with the one border role
/// that IUX forbids on interactive elements — so a tag differs from a filter
/// chip visually as well as behaviourally. A user who cannot tell which of two
/// chips is tappable has to try them both.
///
/// The label is required and never empty: an unlabelled tag is a shape whose
/// only content is its colour.
///
/// **There is no tone and no fill, and that is a decision rather than a
/// gap.** A small pill filled with the accent is the exact shape of a filled
/// primary button, whichever token painted it. A tag drawn that way tells the
/// user it can be pressed, and the one thing this widget exists to guarantee
/// is that it never says so. The category is carried by the words, which is
/// the only channel that survives a monochrome screen anyway.
///
/// Reported from a migration that wanted a project's type as a filled badge
/// and found no role for it (systm-d/IUX#71). The report was right that the
/// refusal was silent; it is now written here. IUX does have decorative
/// accents with no meaning — `IuxAvatarTone`, for the question "which one of
/// several unrelated things is this" (ADR-0014) — and they fill a *circle
/// carrying a glyph*, which reads as identity rather than as an action.
/// Extending them to a text label is the shape a "yes" would take, and it
/// would need its own record: it spends the same four hues on a second
/// component, and a filled label is the case where they look most like a
/// control.
///
/// ## A tag the user can take back out
///
/// ```dart
/// IuxTagChip.removable(
///   label: organisation.name,
///   removeLabel: l10n.removeOrganisation(organisation.name),
///   onRemove: () => controller.remove(organisation),
/// )
/// ```
///
/// **Use it** where the tags are the user's own list — organisations on an
/// account, recipients of a message, labels they typed — and taking one out is
/// part of editing that list. The tag is still a tag: its body takes no focus
/// and reports no gesture. It carries **one** control, a remove button with a
/// full touch target, a focus stop and a name of its own.
///
/// **Do not use it** for a filter the user switches off — that is
/// [IuxFilterChip], chosen from a set the application offers. A removable tag
/// stands for something the user put there, and removing it takes it away.
///
/// **The name of the button must name the tag.** A screen reader listing the
/// controls on a page reads them without the text around them, and five
/// buttons called "Remove" are five guesses. [removeLabel] is therefore the
/// whole sentence, already localised — "Remove acme-corp" — and a debug build
/// refuses one that does not contain [label].
///
/// **Where focus goes.** When the button is activated from the keyboard, focus
/// moves to the previous stop before the tag disappears — the tag before it, or
/// the field the list is added from. Left alone, focus would fall to the top of
/// the screen and a keyboard user would start over. A tap moves nothing.
///
/// **Removing is immediate, with no question asked.** That is right when the
/// user can add the item straight back. When removal loses something that
/// cannot be re-added, the list needs an undo — `IuxTransientMessage` carries
/// one — or the removal belongs in `IuxDestructiveAction`, not here.
///
/// Reported from a migration whose chips lost their delete affordance the
/// moment they were adopted, silently: the code compiled and the tests passed
/// (systm-d/IUX#68).
class IuxTagChip extends StatelessWidget {
  /// Creates a read-only tag.
  const IuxTagChip({super.key, required this.label})
      : removeLabel = null,
        onRemove = null,
        assert(
          label.length > 0,
          'A tag must say something. An empty one leaves a coloured shape that '
          'a screen reader announces as nothing, and that a sighted user can '
          'see but cannot read.',
        );

  /// Creates a tag carrying one control, which removes it.
  const IuxTagChip.removable({
    super.key,
    required this.label,
    required String this.removeLabel,
    required VoidCallback this.onRemove,
  })  : assert(
          label.length > 0,
          'A tag must say something. An empty one leaves a coloured shape that '
          'a screen reader announces as nothing, and that a sighted user can '
          'see but cannot read.',
        ),
        assert(
          removeLabel.length > 0,
          'The remove button needs a name, and the name has to say which tag '
          'it removes: "Remove acme-corp", already localised.',
        );

  /// The visible text, already localised, and also the accessible name.
  final String label;

  /// The accessible name of the remove button, already localised.
  ///
  /// Null on a read-only tag. On a removable one it must contain [label]: a
  /// screen reader listing controls reads this without the tag beside it.
  final String? removeLabel;

  /// Called when the user asks to remove the tag. Null on a read-only tag.
  ///
  /// The tag does not remove itself. The parent drops it from its list and
  /// rebuilds, as with every other IUX control.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final String? removeLabel = this.removeLabel;
    final VoidCallback? onRemove = this.onRemove;
    if (removeLabel != null && onRemove != null) {
      return _IuxRemovableTag(
        label: label,
        removeLabel: removeLabel,
        onRemove: onRemove,
      );
    }

    final IuxChipTokens tokens = IuxChipResolver.resolve(
      context,
      IuxChipState.readOnly,
    );

    final Widget visual = DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.background,
        borderRadius: BorderRadius.circular(tokens.radius),
        border: Border.all(color: tokens.border, width: tokens.borderWidth),
      ),
      child: Padding(
        padding: tokens.padding,
        // No line limit and no ellipsis. A truncated tag is a tag the user
        // cannot identify, and truncation gets worse exactly when someone has
        // enlarged their text.
        child: Text(label, style: tokens.textStyle, softWrap: true),
      ),
    );

    // A labelled group, never an action. IuxSemantics.action would set the
    // button flag, which is the failure this widget exists to avoid: a screen
    // reader would offer a gesture that does nothing at all.
    return IuxSemantics.group(
      label: label,
      child: IuxSemantics.decorative(child: visual),
    );
  }
}

/// The removable form of [IuxTagChip]: a read-only body and one control.
///
/// Stateful only to own the remove button's focus node, which is what lets it
/// hand focus back before the tag leaves the tree.
class _IuxRemovableTag extends StatefulWidget {
  const _IuxRemovableTag({
    required this.label,
    required this.removeLabel,
    required this.onRemove,
  });

  final String label;
  final String removeLabel;
  final VoidCallback onRemove;

  @override
  State<_IuxRemovableTag> createState() => _IuxRemovableTagState();
}

class _IuxRemovableTagState extends State<_IuxRemovableTag> {
  late final FocusNode _removeNode =
      FocusNode(debugLabel: 'remove ${widget.label}');

  @override
  void dispose() {
    _removeNode.dispose();
    super.dispose();
  }

  void _remove() {
    // Before the callback, while this node still has a place in the traversal
    // order. Once the parent rebuilds without the tag, the node is gone and
    // focus would fall back to the scope — the top of the screen, for a
    // keyboard user who was halfway down a list.
    if (_removeNode.hasPrimaryFocus) _removeNode.previousFocus();
    widget.onRemove();
  }

  @override
  Widget build(BuildContext context) {
    assert(
      widget.removeLabel.toLowerCase().contains(widget.label.toLowerCase()),
      'The remove button is named "${widget.removeLabel}", which does not '
      'say which tag it removes. A screen reader listing the controls reads '
      'the name alone, so write the tag into it: "Remove ${widget.label}", '
      'in the user\'s language.',
    );

    final IuxChipTokens tokens = IuxChipResolver.resolve(
      context,
      IuxChipState.readOnly,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.background,
        borderRadius: BorderRadius.circular(tokens.radius),
        border: Border.all(color: tokens.border, width: tokens.borderWidth),
      ),
      // Each part keeps its own node: the tag's text, read as text, and the
      // button, announced as a button with its own name. Merging them would
      // make the whole tag a button, which is the failure the read-only form
      // exists to avoid.
      child: IuxSemantics.contentContainer(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Flexible(
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  start: tokens.padding.left,
                ),
                // No line limit and no ellipsis, as on the read-only tag.
                child: Text(
                  widget.label,
                  style: tokens.textStyle,
                  softWrap: true,
                ),
              ),
            ),
            // The button sets the height, so the target is never shrunk to
            // the tag. The glyph stays small inside it; see IuxIconButton.
            IuxIconButton(
              icon: Icons.close,
              focusNode: _removeNode,
              // Derived rather than accepted, as on the search field's clear
              // button: a caller-supplied descriptor could ask for a
              // confirmation this control cannot hold, or paint the least
              // consequential control on the screen as destructive.
              action: IuxActionDescriptor(
                semantics: IuxActionSemantics(label: widget.removeLabel),
                role: IuxActionRole.delete,
              ),
              onActivate: _remove,
            ),
          ],
        ),
      ),
    );
  }
}

/// What tells a chip apart from its unchosen neighbour.
///
/// A filter chip has always carried its selection three ways at once — a
/// checkmark, a heavier outline, and the announced state — because a fill
/// alone is invisible to a substantial share of users. This chooses which of
/// those three the chip spends **width** on.
///
/// Neither value reflows. The heavier outline is drawn inside the padding
/// rather than added to it, so a chip is exactly the same size chosen as
/// unchosen either way; that is settled in `IuxChipResolver` and is not what
/// this decides.
///
/// It is set on [IuxChipGroup] rather than on the chip, so a group cannot end
/// up half one and half the other — a row where some chips reserve a slot and
/// others do not is a row with a ragged left edge and no explanation for it.
enum IuxChipMark {
  /// A checkmark, in a slot reserved whether or not it is filled.
  ///
  /// The default, and the right answer wherever the chips have room. Three
  /// signals, one of which is a shape rather than a colour or a weight, is the
  /// strongest statement of "chosen" this component can make.
  checkmark,

  /// The outline and the fill, with no glyph and no slot held for one.
  ///
  /// **The cost is real and it is the reason this is not the default.** The
  /// selection is left carried by the fill, the outline weight and the
  /// announcement. Weight is not colour, so WCAG 2.2 SC 1.4.1 is still
  /// satisfied without it — but a change of outline weight is a quieter signal
  /// than a glyph appearing, and quieter for exactly the users the glyph was
  /// put there for.
  ///
  /// **What it buys is width, and the reserved slot is most of it.** Measured
  /// in-harness on a 360-wide screen: a one-character chip goes from 78 to 56
  /// pixels, a two-character chip from 93 to 65. That is why shortening a
  /// label does so little and this does so much — the slot does not care how
  /// long the text is.
  ///
  /// On that screen it is the difference between a row and a paragraph. Four
  /// two-character chips: two lines become **one**, 120 pixels become 56.
  /// Seven of them: three lines become **two**, 184 pixels become 120.
  ///
  /// **Use it** where the row is a scale the user reads at a glance and the
  /// labels are a character or two: thresholds, intervals, the days of a week.
  /// Those are the sets where a third line costs more than the glyph is worth.
  ///
  /// **Do not use it** for a set of named criteria a user picks through, where
  /// a chip may be the only thing on screen saying a filter is applied.
  outline,
}

/// A compact control that turns one criterion on or off.
///
/// ```dart
/// IuxFilterChip(
///   label: l10n.categoryVegetarian,
///   selected: filters.contains(Category.vegetarian),
///   onSelectionChanged: (bool selected) =>
///       controller.setVegetarian(selected),
/// )
/// ```
///
/// **Use it** for a criterion the user switches on and off and can see the
/// effect of immediately — filtering a list, narrowing a search. Several of
/// them belong in an [IuxChipGroup], which names the set and keeps the required
/// separation between adjacent targets.
///
/// **Do not use it** to run an action: a chip that submits, navigates or
/// deletes is a button wearing the wrong shape, and `IuxButton` says so out
/// loud. Do not use it for a value that is merely displayed — that is
/// [IuxTagChip]. Do not use it for a choice among many where exactly one must
/// win; a row of chips gives no clue that they are exclusive, and a radio group
/// does.
///
/// **Accessibility.** The chip announces itself as a button with a selected
/// state, so a screen reader says "Vegetarian, selected" rather than leaving
/// the user to infer it from a fill colour. Selection is carried by three
/// signals at once — the checkmark, the heavier outline, and the announced
/// state — because the fill alone is invisible to a substantial share of users.
///
/// The checkmark slot is reserved whether or not the chip is selected. The
/// alternative is a chip that changes width on every tap, which reflows the
/// whole group and moves the chips the user was about to press next.
///
/// **The slot is most of the chip's width, and that surprises people.** A
/// one-character chip measures 78 pixels in-harness; 22 of them are the slot
/// and the space before it, and only 16 are the character. Shortening a label
/// therefore buys almost nothing,
/// which is not obvious at the moment somebody is trying to make a row fit —
/// three call sites in a migrating application left this component over it.
/// [IuxChipGroup.mark] is the lever, and [IuxChipGroup] carries the width
/// budget.
///
/// `onSelectionChanged` is required and nullable: passing null means "this
/// criterion is currently unavailable", and produces disabled semantics along
/// with the disabled appearance, so the two cannot drift. It has to be written
/// out at the call site because a chip that is *never* selectable is an
/// [IuxTagChip] and should have been one from the start.
class IuxFilterChip extends StatefulWidget {
  /// Creates a chip that toggles one criterion.
  const IuxFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelectionChanged,
    this.autofocus = false,
    this.focusNode,
  }) : assert(
          label.length > 0,
          'A filter chip must name the criterion it switches. An empty label '
          'leaves a target that a screen reader announces as an unnamed '
          'button, which is a control nobody can use and everybody can hit.',
        );

  /// The criterion, already localised. Also the accessible name.
  final String label;

  /// Whether the criterion is currently applied.
  ///
  /// Owned by the parent. The chip never toggles itself: a control that changed
  /// its own state would show a filter as applied before the list it filters
  /// had been rebuilt, and the two would disagree for as long as the caller
  /// took to catch up.
  final bool selected;

  /// Called with the value the user asked for.
  ///
  /// Null means the criterion is unavailable, which also produces disabled
  /// semantics. Never called while disabled.
  final ValueChanged<bool>? onSelectionChanged;

  /// Whether this takes focus when first built.
  final bool autofocus;

  /// An externally owned focus node.
  final FocusNode? focusNode;

  @override
  State<IuxFilterChip> createState() => _IuxFilterChipState();
}

class _IuxFilterChipState extends State<IuxFilterChip> {
  bool _pressed = false;

  bool get _enabled => widget.onSelectionChanged != null;

  void _handleActivate() {
    final ValueChanged<bool>? callback = widget.onSelectionChanged;
    if (callback == null) return;
    callback(!widget.selected);
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final IuxChipState state = switch ((_enabled, widget.selected)) {
      (false, _) => IuxChipState.disabled,
      (true, true) => IuxChipState.selected,
      (true, false) => IuxChipState.unselected,
    };
    final IuxChipTokens tokens = IuxChipResolver.resolve(context, state);
    // Read from the group rather than taken as a parameter, so a row cannot be
    // half one shape and half the other. A chip outside a group gets the
    // default, which is the stronger of the two.
    final IuxChipMark mark = _IuxChipMarkScope.of(context);

    final Widget visual = AnimatedContainer(
      duration: tokens.motion.duration,
      curve: tokens.motion.curve,
      constraints: BoxConstraints(
        minHeight: tokens.minimumSize,
        minWidth: tokens.minimumSize,
      ),
      padding: tokens.padding,
      decoration: BoxDecoration(
        color: _pressed ? tokens.pressedBackground : tokens.background,
        borderRadius: BorderRadius.circular(tokens.radius),
        border: Border.all(color: tokens.border, width: tokens.borderWidth),
      ),
      // Shrink-wrapped rather than aligned. A container that aligns its child
      // grows to fill whatever its parent offers, which turns a chip placed in
      // a Center or an Expanded into a target the height of the screen.
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (mark == IuxChipMark.checkmark) ...<Widget>[
              _SelectionMark(tokens: tokens, selected: widget.selected),
              SizedBox(width: tokens.gap),
            ],
            Flexible(
              child: Text(
                widget.label,
                style: tokens.textStyle,
                softWrap: true,
              ),
            ),
          ],
        ),
      ),
    );

    return IuxFocusNodeOwner(
      focusNode: widget.focusNode,
      debugLabel: widget.label,
      builder: (BuildContext context, FocusNode node) => IuxSemantics.action(
        label: widget.label,
        enabled: _enabled,
        // Selected, not toggled. A screen reader says "selected" or "not
        // selected" for the first and "on" or "off" for the second, and a
        // filter is something the user chose rather than a switch they threw.
        selected: widget.selected,
        // Carried here because the helper excludes the subtree to control the
        // announced name, and that takes the gesture detector's tap with it.
        // Without this the chip announced itself as a button and refused a
        // screen-reader double-tap — the IUX-011 defect, still live here.
        onTap: _enabled ? _handleActivate : null,
        // The same exclusion took the focus annotations. One node named on
        // both, so they cannot describe two different focuses.
        // IUX-A11Y-FOCUS-001.
        focusNode: node,
        // A disabled chip leaves the focus order entirely, so it declares no
        // focusable state rather than declaring itself unfocused.
        focusable: _enabled,
        child: IuxFocusable(
          autofocus: widget.autofocus,
          focusNode: node,
          canRequestFocus: _enabled,
          onActivate: _enabled ? _handleActivate : null,
          borderRadius: BorderRadius.circular(tokens.radius),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown:
                _enabled ? (TapDownDetails _) => _setPressed(true) : null,
            onTapUp: _enabled ? (TapUpDetails _) => _setPressed(false) : null,
            onTapCancel: _enabled ? () => _setPressed(false) : null,
            onTap: _enabled ? _handleActivate : null,
            child: visual,
          ),
        ),
      ),
    );
  }
}

/// The checkmark slot, reserved whether or not it is filled.
///
/// A separate widget so the reserved-width rule is written once and cannot be
/// forgotten the next time a chip variant is added.
class _SelectionMark extends StatelessWidget {
  const _SelectionMark({required this.tokens, required this.selected});

  final IuxChipTokens tokens;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    if (!selected) return SizedBox.square(dimension: tokens.glyphSize);
    return Icon(
      tokens.checkGlyph,
      size: tokens.glyphSize,
      color: tokens.foreground,
      // Scaled once, through the runtime, so the mark and the label enlarge by
      // the same factor.
      applyTextScaling: false,
    );
  }
}

/// A named set of chips, separated by at least the minimum target spacing.
///
/// ```dart
/// IuxChipGroup(
///   label: l10n.filterByCategory,
///   chips: <Widget>[
///     IuxFilterChip(...),
///     IuxFilterChip(...),
///   ],
/// )
/// ```
///
/// **Use it** for every row of chips, including a row of one. It exists for two
/// reasons that a bare `Row` cannot supply:
///
/// - **Separation.** Adjacent targets that touch produce mis-taps even when
///   each one is large enough, because a finger landing near the seam has no
///   margin for error. This applies `kIuxMinimumTargetSpacing` through
///   [IuxTargetSpacing], so the floor lives in one place and cannot drift.
/// - **A name for the set.** A screen-reader user arriving at eight unrelated
///   buttons has no way to know they are the filters for the list below. The
///   group carries that sentence; the chips inside stay individually reachable.
///
/// It wraps rather than scrolls: at a large text scale a row of chips stops
/// fitting, and moving to a second line is better than overflowing or shrinking
/// the targets.
///
/// ## The width budget
///
/// A chip is far wider than its label, and an integrator otherwise discovers
/// that by measuring a golden. Measured in-harness at one device pixel per
/// logical one, standard density, no text scaling:
///
/// | | [IuxChipMark.checkmark] | [IuxChipMark.outline] |
/// | --- | --- | --- |
/// | one-character label | 78 px | 56 px |
/// | two-character label | 93 px | 65 px |
/// | between two chips | 8 px | 8 px |
/// | four two-character chips | 120 px, two lines | **56 px, one line** |
/// | seven two-character chips | 184 px, three lines | **120 px, two lines** |
///
/// So on a 360-wide screen, with the default mark: **four two-character chips
/// do not fit on one line, and seven take three lines.** Both of those are what
/// a set of thresholds or a week of days looks like, and both are the case
/// where the whole point was reading the row at a glance.
///
/// **Shortening the labels does almost nothing**, which is the part that is not
/// intuitive. 22 of those pixels are the reserved slot and the space before it,
/// and the slot does not care how long the text is: dropping a character saves
/// 16 pixels a chip and rarely a whole line. The lever that works is [mark].
///
/// Those numbers are an upper bound on the text: under `flutter_test` every
/// glyph is a square of the font size, so a two-character label measures two
/// 16-pixel boxes. A proportional face fits more per line. The slot does not
/// change.
///
/// ## Do not use it for
///
/// Anything other than chips — [IuxTargetSpacing] is the general primitive. Do
/// not mix [IuxTagChip] and [IuxFilterChip] in one group, nor read-only tags
/// with [IuxTagChip.removable] ones: a set where some members respond and
/// others do not is a set the user has to probe one by one.
///
class IuxChipGroup extends StatelessWidget {
  /// Creates a named group of chips.
  const IuxChipGroup({
    super.key,
    required this.label,
    required this.chips,
    this.mark = IuxChipMark.checkmark,
  }) : assert(
          label.length > 0,
          'A chip group must say what the set is for. Without it a screen '
          'reader user meets a row of buttons with no idea what they filter, '
          'and a sighted user reads a heading the row does not have.',
        );

  /// What the set is for, already localised — "Filter by category".
  ///
  /// Announced as the container of the chips. It is not drawn: a visible
  /// heading is a layout decision the caller owns, and drawing one here would
  /// duplicate the section title most screens already have.
  final String label;

  /// The chips, in reading order.
  final List<Widget> chips;

  /// What tells a chosen chip from an unchosen one, for every chip here.
  ///
  /// Defaults to [IuxChipMark.checkmark], which is the stronger of the two and
  /// the right answer wherever the row has room. [IuxChipMark.outline] gives
  /// back the reserved slot — 22 pixels a chip — and is what makes a short
  /// scale fit on one line. Read the width budget above before reaching
  /// for it, and the enum for what it costs.
  ///
  /// It applies to every [IuxFilterChip] below this group, including one nested
  /// inside a caller's own layout. [IuxTagChip] has no mark and ignores it.
  final IuxChipMark mark;

  @override
  Widget build(BuildContext context) => IuxSemantics.group(
        label: label,
        // Not excluded: each chip keeps its own node, its own name and its own
        // selected state. Excluding them would collapse the whole set into one
        // unusable announcement.
        child: _IuxChipMarkScope(
          mark: mark,
          child: IuxTargetSpacing(axis: Axis.horizontal, children: chips),
        ),
      );
}

/// Carries [IuxChipGroup.mark] down to the chips inside it.
///
/// An inherited value rather than a parameter on the chip, and that is the
/// whole reason it exists: `chips` is a list of widgets the caller builds, so a
/// parameter would let one row hold three chips that reserve a slot and four
/// that do not. That row has a ragged left edge and nothing on screen to
/// explain it. Here the group decides once and no call site can disagree.
class _IuxChipMarkScope extends InheritedWidget {
  const _IuxChipMarkScope({required this.mark, required super.child});

  final IuxChipMark mark;

  /// The mark in force, or the default outside any group.
  ///
  /// A chip on its own is not a defect — [IuxChipGroup] is required for a row,
  /// not for a lone chip in a caller's own layout — so the absence of a scope
  /// resolves rather than asserting.
  static IuxChipMark of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_IuxChipMarkScope>()?.mark ??
      IuxChipMark.checkmark;

  @override
  bool updateShouldNotify(_IuxChipMarkScope oldWidget) =>
      oldWidget.mark != mark;
}
