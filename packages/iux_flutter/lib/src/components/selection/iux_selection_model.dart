import 'package:flutter/foundation.dart';

/// Whether a control is chosen, not chosen, or standing for a mixed set.
///
/// IUX-009 left selection out of `IuxInputDescriptor` on purpose: a shared
/// field descriptor carrying `selected: false` would give every text field a
/// selected *state*, and a field announced as "not selected" sends the user
/// hunting for a selection that does not exist. Selection belongs to the
/// controls that offer a choice, so it is modelled here and nowhere else.
///
/// One enum for all three controls rather than a `bool` here and a `bool?`
/// there. A form that expresses "on" three different ways is a form where the
/// three controls eventually disagree about what "off" means.
enum IuxSelectionState {
  /// Not chosen. The resting state.
  unselected,

  /// Chosen.
  selected,

  /// Standing for a set in which some, but not all, members are chosen.
  ///
  /// Only a checkbox can be here, and only when it summarises other
  /// checkboxes — the "select all" at the top of a list. A switch has two
  /// physical positions and a radio is one option among several, so neither
  /// has anywhere to render this: `IuxSwitch` asserts against it rather than
  /// picking a position and hoping.
  ///
  /// The user can never *ask* for this state. It is computed from the members,
  /// which is why an activation reports a plain boolean.
  partial;

  /// Whether the control reads as chosen.
  ///
  /// [partial] is not selected. A summary checkbox showing a dash means "not
  /// all of these", and treating it as selected would make "select all"
  /// silently deselect the members the user had already chosen.
  bool get isSelected => this == IuxSelectionState.selected;

  /// Whether the control stands for a partly-chosen set.
  bool get isPartial => this == IuxSelectionState.partial;

  /// The selection an activation asks for.
  ///
  /// Chosen becomes not chosen; everything else becomes chosen. That second
  /// half is the decision worth stating: tapping a partial "select all"
  /// selects everything rather than clearing it, because a user who taps a
  /// half-filled summary is completing the set, not abandoning it — and
  /// clearing it would destroy choices they had already made, which is the
  /// expensive direction to be wrong in.
  ///
  /// There is no way to reach [partial] from here. It is a computed state, not
  /// a state a user can request.
  bool get requestedSelection => this != IuxSelectionState.selected;

  /// The state a plain boolean corresponds to.
  ///
  /// Most applications hold a `bool` in their own model. Without this, every
  /// call site writes the same ternary, and one of them eventually writes it
  /// backwards.
  static IuxSelectionState fromSelected(bool selected) =>
      selected ? IuxSelectionState.selected : IuxSelectionState.unselected;
}

/// One choice in a mutually exclusive group.
///
/// A plain value rather than a widget, so the group can guarantee what a loose
/// radio widget cannot: that every option is spaced from its neighbours, that
/// exactly one of them is marked, and that they all belong to a named group.
/// A stray radio floating on a screen is unusable with a screen reader — it
/// announces "radio button, 1 of 1" and never says what the choice is about.
@immutable
final class IuxRadioOption<T> {
  /// Creates one option of a radio group.
  const IuxRadioOption({
    required this.value,
    required this.label,
    this.helpText,
    this.unavailabilityReason,
  })  : assert(
          label.length > 0,
          'An option must say what it is. An unlabelled radio is a target the '
          'user can hit and cannot identify, and a screen reader announces it '
          'as "radio button" and nothing else.',
        ),
        assert(
          helpText == null || helpText.length > 0,
          'Empty help text reserves a line and says nothing. Pass null.',
        ),
        assert(
          unavailabilityReason == null || unavailabilityReason.length > 0,
          'An option is unavailable *because* of something. Pass the reason, '
          'or pass null and leave the option available.',
        );

  /// What choosing this option means to the application.
  ///
  /// Compared with the group's value by `==`, so a value type works and an
  /// identity-based object works only if the caller keeps the same instance.
  final T value;

  /// The visible text, already localised.
  ///
  /// Also the accessible name. Unlike a button in a table row, a radio option
  /// sits beside its own label with nothing else competing for it, so a second
  /// announced string would be two names for one thing.
  final String label;

  /// A persistent explanation shown under [label], already localised.
  ///
  /// This is where the consequence of the choice goes — "Arrives in 3 to 5
  /// working days". Putting it in a tooltip instead hides it from exactly the
  /// users who are deciding.
  final String? helpText;

  /// Why this option cannot be chosen, already localised, or null when it can.
  ///
  /// One field rather than a flag and a reason, because the two can then never
  /// come apart: there is no way to express a greyed-out option with no
  /// explanation, which is the state that leaves a user unable to tell whether
  /// they did something wrong or the option does not apply to them.
  final String? unavailabilityReason;

  /// Whether this option can be chosen.
  bool get isAvailable => unavailabilityReason == null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxRadioOption<T> &&
          other.value == value &&
          other.label == label &&
          other.helpText == helpText &&
          other.unavailabilityReason == unavailabilityReason;

  @override
  int get hashCode => Object.hash(value, label, helpText, unavailabilityReason);

  @override
  String toString() => 'IuxRadioOption($label)';
}
