# Selection controls

`IuxCheckbox`, `IuxSwitch`, `IuxRadioGroup`, `IuxSelectionGroup`.

## Purpose

Let the user say yes, say which, or turn something on — and make the wrong
choice of control hard to ship.

```dart
IuxCheckbox(
  label: l10n.sendMeTheNewsletter,
  input: const IuxInputDescriptor(
    semantics: IuxInputSemantics(label: 'Send me the newsletter'),
  ),
  value: IuxSelectionState.fromSelected(subscribed),
  onChanged: controller.setSubscribed,
)
```

## The three are not interchangeable

This is the section worth reading. The three controls look similar and mean
different things, and picking the wrong one produces a screen that is
internally contradictory rather than merely ugly.

| | Question it asks | Applies | Cardinality |
| --- | --- | --- | --- |
| `IuxCheckbox` | "is this true?" | when the form is submitted | any number, including none |
| `IuxSwitch` | "is this on?" | immediately | one setting, on its own |
| `IuxRadioGroup` | "which one?" | when the form is submitted | exactly one of a visible set |

### Do not use a checkbox when

- **The setting takes effect immediately.** Use `IuxSwitch`. A checkbox makes
  users look for the Save button that does not exist, and they leave the screen
  unsure whether the change was kept.
- **Only one of several may be true.** Use `IuxRadioGroup`. Two checkboxes with
  a rule saying only one may be ticked is a radio group with a defect already
  in it, and nothing on screen tells the user the two are related.

### Do not use a switch when

- **There is a Save button.** A switch plus a confirmation step is a
  contradiction: either the switch already did the thing, in which case Save is
  a lie, or it did not, in which case the switch is. If your design has both,
  one of them is wrong.
- **The action is not reversible.** A switch's whole shape says "you can put
  this back". "Delete my account" is not a setting.
- **You want a third position.** There is none. `IuxSwitch` asserts against
  `IuxSelectionState.partial` rather than choosing a position and hoping.

### Do not use a radio group when

- **The user may answer "none".** A radio cannot be unchosen once chosen, so
  "none of these" has to be an option in its own right, in words you write.
- **There is one option.** `IuxRadioGroup` asserts on it: one radio is a
  checkbox that lost its off state.
- **There are many options.** Past roughly five, a list or a menu costs the
  user less to read.

There is **no standalone radio widget and there will not be one**. A radio
outside a group announces itself as one of one and never says what the choice
is about. Making the group the only way to build one removes the defect instead
of documenting it.

## The label is part of the target

Tapping the text toggles the control. So does tapping the help text under it.
The interactive region is the whole row, and it meets the resolved touch-target
floor even though the box inside it is around 24 logical pixels — those are two
different measurements.

A small box with an untappable label beside it is the classic accessibility
failure of this component family: it is legal, it looks right, and it is
unusable for anyone with a tremor.

## Adjacent controls are kept apart

`IuxSelectionGroup` and `IuxRadioGroup` keep at least
`kIuxMinimumTargetSpacing` between neighbouring targets. Two 48-pixel targets
that touch still produce mis-taps — a finger landing near the seam has no
margin for error — which is why WCAG 2.2 SC 2.5.8 treats size and spacing as
one requirement.

A bare `Column` of checkboxes does not do this. Wrap them.

```dart
IuxSelectionGroup(
  label: l10n.notifyMeAbout,
  children: <Widget>[replies, mentions, weeklyDigest],
)
```

`label` is required. A group nobody named is a group a screen-reader user
experiences as loose controls; and if a set of controls cannot be given a name,
they probably do not belong together. Where the intent really is only spacing —
a row of chips, a pair of buttons — use `IuxTargetSpacing` from the layout
layer instead.

## The parent owns the value

These are controlled widgets. `value` goes in, a request comes out, and nothing
moves until the parent re-renders.

```dart
// Wrong: the control decides.
IuxCheckbox(onChanged: (bool v) => setState(() => _local = v))  // and never saves

// Right: the parent owns it.
IuxCheckbox(value: state.value, onChanged: controller.set)
```

A control that flipped itself and then discovered the write had failed would
have told the user their answer was saved.

`onChanged` is **not nullable**. Unavailability has one home —
`IuxInputDescriptor.availability` — because two ways of saying "unavailable"
eventually disagree, and the result is a control that announces itself as
available and does nothing. The callback is simply never invoked while the
control is not editable.

## Selection state

```dart
enum IuxSelectionState { unselected, selected, partial }
```

One enum for all three controls. IUX-009 deliberately kept selection out of
`IuxInputDescriptor`: a shared field descriptor carrying `selected: false`
would make every text field announce "not selected", sending users to look for
a selection that does not exist. Selection belongs to the controls that offer a
choice.

`partial` is legal on a checkbox and nowhere else. It is how a "select all"
reports that some of what it stands for is chosen. The user can never *ask* for
it: activation reports a plain boolean, and activating a partial summary asks
for **select all**, never clear — clearing would destroy choices the user had
already made, which is the expensive direction to be wrong in.

## API

### `IuxCheckbox` / `IuxSwitch`

| Parameter | Required | Note |
| --- | --- | --- |
| `label` | yes | the visible text, already localised |
| `input` | yes | `IuxInputDescriptor` — name, availability, requirement, validation, help text |
| `value` | yes | `IuxSelectionState`, owned by the parent |
| `onChanged` | yes | called with the selection the user asked for |
| `autofocus`, `focusNode` | no | focus handling |

### `IuxRadioGroup<T>`

| Parameter | Required | Note |
| --- | --- | --- |
| `label` | yes | the visible name of the choice, rendered as a heading |
| `input` | yes | group-level name, availability, requirement, validation |
| `value` | yes | `T?` — null means unanswered, which is a real state |
| `options` | yes | at least two, values distinct |
| `onChanged` | yes | called with the option chosen; silent when it was already chosen |

`IuxRadioOption<T>` carries `value`, `label`, `helpText` and
`unavailabilityReason`. That last field is one field rather than a flag plus a
reason, so a greyed option with no explanation cannot be expressed.

There is no colour, radius, elevation or duration parameter, and there will not
be one.

## States

| State | Source |
| --- | --- |
| unselected, selected, partial | `value` — the parent's |
| enabled, read-only, disabled | `input.availability` |
| not validated, validating, valid, invalid | `input.validation` — the parent's |
| hovered, pressed | internal to the widget |
| focused | internal, drawn additively by the focus ring |

Read-only is distinct from disabled, and the distinction is load-bearing: a
read-only control stays in the focus order and still announces its value, while
a disabled one leaves it. A value a keyboard or screen-reader user cannot reach
is a value they do not have.

## Accessibility

- A checkbox announces a **checked** state; a partly chosen one announces
  **mixed**; a switch announces a **toggled** state; a radio announces
  **checked** plus membership of a mutually exclusive group. Android reads
  "checked" and "on" differently, and a switch announced as a checkbox tells
  the user a Save button is coming.
- The group of a radio set carries `SemanticsRole.radioGroup`, which is what
  lets the platform say "1 of 3" instead of leaving the user to count. The
  group name is also a heading, so it can be jumped to.
- Every control exposes a tap action **on its own node**, so a screen reader's
  double-tap activates it. Everything below the node is excluded from the
  semantic tree, so without this the control would be announced correctly and
  refuse to respond.
- **And it publishes the focus it holds on that same node**, for the same
  reason: the exclusion takes the `Focus` widget's own
  `focusable`/`focused`/`onFocus` annotations along with everything else. Until
  this was fixed, a checkbox reported `isFocused: Tristate.none` with
  `actions: [tap]` where Flutter's own reported `Tristate.isFalse` with
  `[tap, focus]` — meaning the node declared no focusable state at all and
  assistive technology could not move accessibility focus onto the control.
  That is `IUX-A11Y-FOCUS-001`, which was declared fixed for `IuxButton` and
  found still live in `IuxSemantics.selection` by sweeping every helper that
  excludes. A read-only control stays focusable; a disabled one declares no
  focusable state, because it has left the focus order entirely.
- A disabled control announces its state and, when the caller supplied
  `unavailabilityReason`, explains itself.
- A required control announces that an answer is expected.
- The validation message sits on its own node below the control, and is a live
  region **when it appears** — not when the control arrives already carrying it.
  A message already on screen when the control mounted is content rather than a
  status change (SC 4.1.3), and announcing it competes with whatever put the
  control there (IUX-GUIDED-FORM-LIVE-001). The node and the words are the same
  either way; only the flag differs.
- Enter and Space activate a focused control; a disabled one is skipped by
  focus traversal.
- At least the resolved touch-target floor, at every density, with the spacing
  floor between neighbours.
- Labels wrap and are never truncated, at any text scale.
- **No state is carried by colour alone**: a chosen checkbox shows a tick, a
  partly chosen one a dash, a switch that is on shows both a thumb position and
  a tick. A rejected value is stated in words, because
  `IuxInputValidation.invalid` requires a message.
- Shape is not themeable. Square means "any number of these", round means "one
  of these"; a fully rounded checkbox is a radio that behaves differently, and
  the user finds out by getting it wrong.

**Verified in widget tests.** Still requires checking on a device: TalkBack
reading order and grouping, Voice Access naming, D-pad traversal.

## Errors

A checkbox or a switch that is invalid recolours its own outline and states the
message below itself. A radio group does **not** recolour its options: an
unanswered required group is not five wrong options, and painting every ring
red would say each choice is invalid when the problem is that none was made.
The message sits under the group.

A disabled control may not also carry an error — the resolver asserts on it. The
user would be told something is wrong and given no way to fix it.

## Motion

The tick, the dot and the thumb animate under `IuxMotionRole.stateChange` at
the short scale. Reduced motion shortens it; no motion removes it. Nothing the
animation carried is lost either way — the mark is still there, it simply
arrives instantly.

## Anti-patterns

```dart
// Wrong: a switch and a Save button on the same screen.
Column(children: [IuxSwitch(...), IuxButton(label: 'Save', ...)])

// Wrong: two checkboxes where only one may be true.
Column(children: [IuxCheckbox(label: 'Card'), IuxCheckbox(label: 'Transfer')])
// Right:
IuxRadioGroup<Method>(label: 'Payment method', options: ...)

// Wrong: a bare Column of checkboxes, targets touching.
Column(children: checkboxes)
// Right:
IuxSelectionGroup(label: 'Notify me about', children: checkboxes)
```

## Limits

- ~~Bare `Semantics`~~ — **Fermé.** Le runtime expose désormais les helpers manquants (`IuxSemantics.selection`, `.radioGroup`, `.field`, `.route`, `.contentAction`, `.contentContainer`) et le composant les utilise. Voir `docs/accessibility/semantics.md`.
- **Historique.** The component standard §2 says a component uses the
  `IuxSemantics` helpers rather than `Semantics` directly. The accessibility
  runtime has no builder for a checked, a mixed or a toggled state, and
  IUX-011 could not extend it. The deviation is contained in one private
  function shared by all three controls, so they cannot drift; promoting those
  builders into `IuxSemantics` is a follow-up.
- **No `focusable` flag on the semantic node.** The subtree is excluded, so the
  `Focus` widget's own annotation does not reach the node. Keyboard focus works;
  the flag is absent. `IuxButton` has the same shape, and both should be fixed
  together.
- **No arrow-key navigation within a radio group.** Each option is
  individually focusable and reachable by Tab or D-pad. Flutter's
  `RadioGroup` adds arrow-key traversal that skips unselected options; IUX does
  not, yet.
- **The group name may be read twice** — once from the group container and once
  from the heading. Both are standard practice for a fieldset legend, but the
  actual TalkBack behaviour needs a device to confirm.
- **Disabled contrast.** A chosen-and-disabled indicator paints
  `content.disabled` on `surface.disabled`. Both roles are individually held to
  3:1 against the base surface; the pair has not been measured against each
  other.
- **No indeterminate switch, no tri-state radio.** Both are asserted against
  rather than rendered.
- **Not in the catalog yet.** IUX-011 owned no catalog files.

## Evidence level

Standard for the accessibility guarantees. Strong guidance for the choice of
control (Material, NN/g and the Android guidelines agree on immediate versus
deferred). Context dependent for the partial-checkbox activation rule, which is
a safety argument rather than a measured preference.

## Sources

- WCAG 2.2 — SC 1.4.1, 1.4.11, 2.1.1, 2.4.7, 2.5.8, 3.3.2, 4.1.2.
- Material Design 3 — checkbox, switch and radio button guidance.
- Android accessibility guidance — announcing checked and toggled states.
- Nielsen Norman Group — "Checkboxes vs. Radio Buttons", "Toggle-Switch
  Guidelines".
- `PROJECT_PROMPT.md` §19–23, §42–45.
- `docs/components/component-standard.md`.
