import 'package:flutter/material.dart';

import '../../accessibility/iux_focus.dart';
import '../../accessibility/iux_semantics.dart';
import '../../layout/iux_spacing_primitives.dart';
import 'iux_status_tokens.dart';

/// A compact label the user cannot act on.
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
/// [IuxFilterChip], and the difference is not cosmetic. A tag takes no focus,
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
class IuxTagChip extends StatelessWidget {
  /// Creates a read-only tag.
  const IuxTagChip({super.key, required this.label})
      : assert(
          label.length > 0,
          'A tag must say something. An empty one leaves a coloured shape that '
          'a screen reader announces as nothing, and that a sighted user can '
          'see but cannot read.',
        );

  /// The visible text, already localised, and also the accessible name.
  final String label;

  @override
  Widget build(BuildContext context) {
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
            _SelectionMark(tokens: tokens, selected: widget.selected),
            SizedBox(width: tokens.gap),
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

    return IuxSemantics.action(
      label: widget.label,
      enabled: _enabled,
      // Selected, not toggled. A screen reader says "selected" or "not
      // selected" for the first and "on" or "off" for the second, and a filter
      // is something the user chose rather than a switch they threw.
      selected: widget.selected,
      child: IuxFocusable(
        autofocus: widget.autofocus,
        focusNode: widget.focusNode,
        canRequestFocus: _enabled,
        onActivate: _enabled ? _handleActivate : null,
        borderRadius: BorderRadius.circular(tokens.radius),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _enabled ? (TapDownDetails _) => _setPressed(true) : null,
          onTapUp: _enabled ? (TapUpDetails _) => _setPressed(false) : null,
          onTapCancel: _enabled ? () => _setPressed(false) : null,
          onTap: _enabled ? _handleActivate : null,
          child: visual,
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
/// **Do not use it** to lay out anything other than chips — [IuxTargetSpacing]
/// is the general primitive. Do not mix [IuxTagChip] and [IuxFilterChip] in one
/// group: a set where some members respond and others do not is a set the user
/// has to probe one by one.
class IuxChipGroup extends StatelessWidget {
  /// Creates a named group of chips.
  const IuxChipGroup({super.key, required this.label, required this.chips})
      : assert(
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

  @override
  Widget build(BuildContext context) => IuxSemantics.group(
        label: label,
        // Not excluded: each chip keeps its own node, its own name and its own
        // selected state. Excluding them would collapse the whole set into one
        // unusable announcement.
        child: IuxTargetSpacing(axis: Axis.horizontal, children: chips),
      );
}
