# IuxListItem, IuxListGroup and IuxListSeparator

## Purpose

Give a list its repeating unit: an item a user can read, open, or choose,
without having to work out which of those a tap will do.

```dart
IuxListItem.tappable(
  title: order.reference,
  subtitle: l10n.deliveredOn(order.date),
  trailingText: l10n.amount(order.total),
  hint: l10n.opensTheOrder,
  onActivate: () => open(order),
)
```

```dart
IuxListItem.selectable(
  title: file.name,
  subtitle: l10n.fileSize(file.bytes),
  selected: IuxSelectionState.fromSelected(chosen.contains(file)),
  onSelectedChanged: (bool value) => controller.choose(file, value),
)
```

```dart
IuxListItem(
  title: l10n.postcode,
  trailingText: address.postcode,
  trailingAction: IuxButton.icon(icon: Icons.edit, ...),
)
```

## Use when

- The screen shows several comparable things and the user picks one.
- An item needs a name, optionally a supporting line, optionally a value, and
  at most one control.
- A settings block, a message list, a search result list, a multi-select.

## Avoid when

- **It is a layout row.** `IuxListItem` is not a `Row` with padding: it applies
  a target floor, a semantic role and a text hierarchy that only make sense for
  an item in a list. Two unrelated widgets side by side are a `Row`.
- **It is one object with several parts.** That is `IuxCard`, which draws a
  boundary around a single thing. A row is one of many.
- **You want a scrolling list.** There is no `IuxList`, deliberately — see
  *There is no IuxList* below.
- **The item needs two or more controls.** Three targets on one line stop
  fitting on a phone at an enlarged text size, and stop reading as one item.
  Put the extra actions on the detail the row opens, or behind one menu control
  in `trailingAction`.

## Tappable, or selectable, or neither — and a control is never inside it

This is the rule `IuxCard` states, applied to the element where it bites
hardest. A row that opens a detail **and** contains a delete button gives a
screen-reader user a control nested inside a control and no way to know which
one they are on; a sighted user cannot see where "open" stops and "delete"
starts, so a tap resolves against a boundary they cannot perceive; keyboard
traversal stops on the row and again on the button with nothing to say the
outer one does something different.

IUX-019 made that combination unrepresentable in two layers. This component
**keeps both, strengthens the first, and adds an answer the card did not have**.

### Layer 1 — the types

`title`, `subtitle` and `trailingText` are `String`, not `Widget`. There is no
widget position to smuggle a control into, so this is stronger than the card's
API-level half: `IuxCard.tappable` merely omits `actions`, while
`IuxListItem.tappable(title: IuxButton(...))` is a type error.

It buys a second thing. Because the text belongs to the component, the
component controls how it wraps — and a row is where wrapping fails first.

### Layer 2 — a debug-only subtree check

`leading` is the one widget a caller puts inside the interactive region, so an
interactive row walks it after the first frame and throws, naming the offender:

```text
An interactive IuxListItem contains an interactive element (IuxTapTarget).

A row that is itself a control and also contains controls has two answers to
"what does tapping do", and nothing on screen tells the user which one they are
about to get. …

Pass the control as `trailingAction` instead. It is laid out beside the row
rather than inside it, keeps at least the minimum target separation, and stays
its own named stop for a screen reader. `leading` is for an icon or an avatar.
```

The recognition rules are identical to the card's: a `GestureDetector` carrying
a tap handler, and a `Semantics` node claiming a button, link, text field,
slider or tap action — between them every IUX control and every Material one.
Its limits are identical too: no custom hit testing, long-press-only handlers
deliberately ignored so a tooltip does not trip it, and compiled out of release
builds. It finds the mistake fast; it does not prove the mistake is absent.

### Where this goes further than the card, and why

`IuxCard`'s answer to "the block opens something *and* has its own button" was
**move the button outside the card**:

```dart
Column(children: <Widget>[IuxCard.tappable(...), IuxButton(...)])
```

A list row has no outside. The second action has to live in the row or not
exist at all, and "not at all" is not an answer for the single most common list
in an application. So the row provides the arrangement the card recommended and
**guarantees the four properties that make it safe**, rather than leaving them
to a call site that will eventually get one of them wrong:

| Guarantee | Why it is the one that matters |
| --- | --- |
| the control is laid out **beside** the region, never inside it | the two targets cannot overlap, so a tap has one answer |
| at least `kIuxMinimumTargetSpacing` between them | size alone does not prevent mis-taps; a finger on the seam has no margin |
| the control is a **sibling** semantics node | a screen reader gets two adjacent stops, not controls inside a control |
| the row's press tint stops at the boundary | where one target ends and the next begins is visible |

**The combination IUX-019 refused stays impossible.** A control *within* the
activatable region cannot be expressed and is caught if it is smuggled in. The
combination IUX-019 *recommended* is what this builds. That is the sense in
which this is consistent with the card rather than a departure from it.

The judgement being made is that the two failures are different. "Open the
order" versus "press Track" inside one card is ambiguous because nothing marks
the boundary. "Open the row" versus "delete the row" is ambiguous **only if**
the targets touch, overlap, or nest — and all three are now prevented by
construction and asserted in tests.

## A row's content is merged, not excluded

An interactive row is **one** stop, and everything it shows is merged into that
one utterance:

```text
"Order 3141, Delivered on Tuesday, 82.40 EUR, button. Opens the order."
```

Excluding descendant semantics — what a button does with its own label — would
delete the status and the amount from the interface of every screen-reader
user, leaving them to open the row to learn what a sighted user reads at a
glance. IUX-019 found this by writing the test before believing the code; the
same test is here.

`semanticLabel` is therefore **optional**, unlike on `IuxCard.tappable`. The
difference is that a row always has a title, so the name already exists. Supply
one only when the visible text is ambiguous out of context — a row reading
"Yesterday" in a list of backups. It is read *before* the row's own text, never
instead of it.

## Long content, which is where a row fails first

A title, a subtitle, a trailing value and an icon competing for a 320-pixel line
at 200% text is the case this component is built around, and it is the case the
tests pump.

- **Nothing sets `maxLines` or an ellipsis, at any scale.** Truncating a row's
  title removes the only thing that tells this item from the next one, and
  truncation gets worse exactly when someone enlarged their text in order to
  read it.
- **The value moves under the text once text is enlarged** past the point where
  a horizontal split fits — the threshold `IuxAccessibility.prefersStackedLayout`
  already owns. Shrinking it instead is what produces the clipped amounts users
  report as "the app ignores my text size".
- **When the value is beside the text, the split is two thirds to one.** The
  title identifies the item, so it is the part that keeps the space and the
  value is the part that wraps. A layout that lets a long value squeeze the
  title produces rows the user cannot tell apart.
- **The leading element sits beside the first line**, not opposite the middle of
  a three-line sentence.

## Targets, in the densest thing an application has

- The region that responds is at least `IuxAccessibility.minimumTouchTarget`
  tall at every density, and larger under a comfortable target preference.
  Density tightens the space between rows; it never shrinks what a finger hits.
- **The whole row responds, edge to edge.** The focus ring reserves a gap on
  every side; the gesture sits *outside* it rather than inside. This is the one
  place the row departs from `IuxCard` mechanically, and the reason is that a
  card has space around it while a row spans the list: a strip at the edge of
  every row where a tap does nothing would be invisible, and it is where a
  thumb reaching across a phone lands.
- **A plain row reserves the same gap** even though it can never take focus, so
  a list mixing plain and interactive rows does not have two row heights.
- **A trailing control keeps `kIuxMinimumTargetSpacing` from the row's target**,
  and the two never overlap. Both are asserted.

### Rows touch each other, and that is deliberate

Adjacent controls elsewhere in IUX keep `kIuxMinimumTargetSpacing` between
them. Stacked rows do not, and the reason is that the two risks are not the
same one:

- Each row is at least the full target height, the separator marks the
  boundary, and a mis-tap opens the neighbouring item — recoverable with the
  back button.
- Two controls sharing a horizontal edge are usually "confirm" and "cancel",
  where a mis-tap is not recoverable.
- Spacing every row apart would also dissolve the grouping the user reads the
  list by.

The separation that **is** enforced is between a row's target and the target of
a control inside it, which is where the two outcomes really do differ. This is a
context-dependent judgement, not a standard, and it is written here so it can be
argued with.

## There is no IuxList

The mission named `IuxList`. It is not built, and the omission is deliberate.

Flutter's `ListView` already solves lazy building, recycling, scroll physics and
keep-alives. A wrapper around it would add a second place for those to go wrong
and would tempt a developer to hand it two hundred children. What a list
actually needs from IUX is the **row** and the **line between rows**, and both
are here:

```dart
ListView.separated(
  itemCount: orders.length,
  separatorBuilder: (_, __) => const IuxListSeparator(),
  itemBuilder: (BuildContext context, int index) => IuxListItem.tappable(
    title: orders[index].reference,
    onActivate: () => open(orders[index]),
  ),
)
```

`IuxListGroup` is the non-scrolling case: a short run of rows, all on screen,
presented as one bounded object. It builds eagerly and says so.

## IuxListGroup is not IuxContentGroup

`IuxContentGroup` pads each of its children. That is right for content and wrong
for a row: a row's padding has to be **inside** its touch target, or the visible
row is larger than the area that responds and the user finds out by tapping
somewhere that does nothing. IUX-019 recorded the split rather than guessing at
it, and this is the other half.

| | Children | Padding | Reach for it when |
| --- | --- | --- | --- |
| `IuxSection` | anything | spacing between | the group deserves a name and a heading landmark |
| `IuxContentGroup` | any content | added by the group | the items are parts of one object |
| `IuxListGroup` | `IuxListItem` | owned by each row | the items are comparable things |

Neither group takes a title. `IuxSection` publishes the heading landmark, and a
second way to write a heading would be a second way to write one that never
reaches the heading index.

`IuxListGroup` clips its children, which `IuxContentGroup` does not, because
these children paint their own backgrounds: a chosen row at the top would
otherwise spill square corners past the group's rounded ones. It also insets by
the outline width, so a full-bleed row background cannot paint over the line
that says where the group starts.

## Behavior

| | Plain | Tappable | Selectable |
| --- | --- | --- | --- |
| tap on the row | nothing | `onActivate()` once | `onSelectedChanged(!selected)` |
| announced as | a container reading its own text | a button | a checked / unchecked control |
| stops for a screen reader | 1 (+1 per trailing control) | same | same |
| keyboard | not focusable | Enter and Space activate | Enter and Space toggle |
| `trailingAction` | allowed | allowed, as a sibling target | allowed, as a sibling target |
| a control in `leading` | allowed — the row is not a control | refused in debug | refused in debug |

**The parent owns the answer.** A selectable row renders `selected` and reports
what the user asked for. If the parent does not re-render with a new value,
nothing changes on screen — which is correct, because a row that marked itself
and then failed to save would be showing the user something untrue. Asserted.

## States

| State | Plain | Tappable | Selectable |
| --- | --- | --- | --- |
| default | ✓ | ✓ | ✓ |
| pressed | — | tint from `state.pressed`, faded under `IuxMotionRole.stateChange` | same |
| hovered | — | tint from `state.hovered` | same |
| focused | — | focus ring, drawn outside the content so it never covers it | same |
| selected | — | — | `surface.selected` **and** a tick |
| disabled | not modelled | not modelled | not modelled |
| loading, error, empty | the parent's, rendered as content | same | same |

**Disabled is deliberately absent**, and it is the same decision `IuxCard` took.
`onActivate` and `onSelectedChanged` are non-nullable, so there is no state
where a row looks activatable and is not. An item that cannot be acted on is an
item that should not look actionable: render the plain form.

**Selection is never carried by colour alone.** A chosen row changes surface
*and* shows a tick, drawn from the same `IuxSelectionResolver` tokens an
`IuxCheckbox` uses — same size, same shape, same colour. Verified on all four
theme profiles.

## API

### `IuxListItem`

| Parameter | Required | Note |
| --- | --- | --- |
| `title` | yes | the primary text, already localised; never empty, never truncated |
| `subtitle` | no | the supporting line |
| `trailingText` | no | the value the row reports |
| `leading` | no | an icon or avatar; presentation only on an interactive row |
| `trailingAction` | no | **one** control, laid out beside the row |

### `IuxListItem.tappable`

Adds `onActivate` (required), `semanticLabel`, `hint`, `autofocus`, `focusNode`.

### `IuxListItem.selectable`

Adds `selected` and `onSelectedChanged` (both required), plus the same
semantics and focus parameters. `IuxSelectionState.partial` is refused: a row
stands for one item, so it is either chosen or it is not, and there is nowhere
on it to render "partly chosen". A summary of a set is an `IuxCheckbox`, which
has that state.

### `IuxListGroup`

| Parameter | Required | Note |
| --- | --- | --- |
| `children` | yes | the rows, in reading order; never padded by the group |

### `IuxListSeparator`

No parameters. Public — unlike the separator inside `IuxContentGroup` — because
a long list is a `ListView.separated`, and a list whose separators are
hand-drawn drifts from the ones the rest of the application uses.

There is no colour, radius, elevation or padding parameter anywhere here, and
there will not be one. An API that accepts a colour has already lost the
contrast guarantee: the theme can no longer be held responsible for something a
call site overrode.

## Accessibility

- An interactive row is announced as an enabled button, or as a checked or
  unchecked control, with the text it shows read out after the name.
- It is **one** stop. A trailing control is a **second**, sibling stop. Both are
  asserted by counting semantics nodes that are not merged into their parent.
- Enter and Space activate a row; it is reachable by keyboard and by D-pad.
- The interactive region is never smaller than the resolved touch target floor,
  at every density, and it covers the row edge to edge.
- A trailing control keeps at least `kIuxMinimumTargetSpacing` from the row's
  target and never overlaps it.
- Focus is visible, distinct from selection, and reserves its gap permanently,
  so taking focus never moves the layout.
- Text wraps and is never truncated. Verified at 100%, 130% and 200% on a
  320×480 screen, with a title, a subtitle, a value, an icon and a control all
  present at once.
- Selection is announced (`checked`) and drawn (a tick), never colour alone.
- Rendered right-to-left, with the value at the reading end rather than pinned
  to the physical right, and on all four theme profiles under test.

**Verified in widget tests.** Still requires checking on a device: TalkBack
reading order and how it announces a merged row label in practice, Voice Access
naming of a row and its trailing control as two separate targets, D-pad
traversal down a long list, and whether a `checked` list row reads naturally in
a language other than English.

## Anti-patterns

```dart
// Wrong: two answers to "what does tapping do", one of them hidden inside the
// other. Throws in debug, naming the widget.
IuxListItem.tappable(
  title: 'Order 3141',
  onActivate: open,
  leading: IuxButton.icon(icon: Icons.delete, ...),
)

// Right: the control is a sibling target with its own name and its own spacing.
IuxListItem.tappable(
  title: 'Order 3141',
  onActivate: open,
  trailingAction: IuxButton.icon(icon: Icons.delete, ...),
)
```

```dart
// Wrong: a list built by hand out of rows and Containers, with no boundary and
// no lazy building.
Column(children: orders.map((o) => IuxListItem.tappable(...)).toList())

// Right, short list: one bounded object.
IuxListGroup(children: <Widget>[...])

// Right, long list: Flutter already solves this.
ListView.separated(separatorBuilder: (_, __) => const IuxListSeparator(), ...)
```

```dart
// Wrong: the row is the page structure. Nothing is named, nothing is a
// landmark, and a screen-reader user has no way to skim.
Column(children: <Widget>[IuxListGroup(...), IuxListGroup(...)])

// Right: the section names the group.
IuxSection(title: l10n.delivery, children: <Widget>[IuxListGroup(...)])
```

```dart
// Wrong: a row that cannot be acted on, rendered as though it can.
IuxListItem.tappable(title: order.reference, onActivate: () {})

// Right: an item that should not be opened is an item that should not look
// openable.
IuxListItem(title: order.reference)
```

## Migration

Additive. Nothing existing changes. `IuxContentGroup` keeps its meaning and its
padding; rows go in `IuxListGroup` or in a `ListView`.

## Limits

- **No scrolling list.** By design; see *There is no IuxList*. The consequence
  is that a caller reaches for `ListView` directly and IUX has no say over
  scroll physics, overscroll or keep-alives.
- **`IuxListGroup` builds eagerly.** A group of two hundred rows builds two
  hundred rows. That is what `ListView.separated` is for.
- **One trailing control, not a list.** Deliberate, and it will stay one until
  there is a real case that a menu control cannot serve.
- **No disabled state**, by construction. See *States*.
- **No swipe actions, no reordering, no long-press selection mode.** Each is a
  pattern rather than a component: they need gesture arbitration, an
  accessible equivalent that does not depend on a gesture, and an undo path.
  A component that offered the gesture without the equivalent would ship a
  feature only some users can reach.
- **No sticky headers, no index, no section headers inside a list.** Those
  belong with the scrolling list that is not built here.
- **No partial selection.** A row stands for one item. See the API note.
- **The nested-control check is a debug heuristic**, not a guarantee, with the
  same limits the card's has.
- **The selection mark is a second implementation of the checkbox indicator.**
  It resolves the same tokens, so it cannot drift in size, shape or colour, but
  the painting code is duplicated. Extracting it belongs with the accessibility
  or selection layer, and neither is this mission's file.
- **So is the subtree guard.** `IuxCard` carries its own copy. The recognition
  rules and the shape of the error are identical, which is what matters to a
  developer who hits one after the other, but there are now two of them.
- **Rows touch each other**, against the intra-row spacing floor. Argued above;
  context dependent.
- **`IuxListItem`, `IuxListGroup`, `IuxListSeparator`, `IuxListItemTokens` and
  `IuxListItemResolver` are not exported from the barrel yet.** The export lines
  belong to whoever owns `lib/iux_flutter.dart`.
- **No catalog entry yet.** `apps/catalog` is outside this mission's scope.

## Deviation from the Component Standard

§2 of the standard says a component uses the `IuxSemantics` helpers rather than
a bare `Semantics` widget. `IuxListItem` and `IuxListGroup` use `Semantics`
directly, and the reasons are the same three IUX-019 recorded plus one:

- `IuxSemantics.action` sets `excludeSemantics: true`. Correct for a button
  whose only content is its own label; for a row it deletes the subtitle and the
  value.
- `IuxSemantics.group` keeps the content but announces no role, so a tappable
  row would be a container the user can activate without being told they can.
- Neither helper exposes `explicitChildNodes`, which is what keeps a trailing
  control and a group's rows reachable as separate stops.
- The runtime has no builder for a **checked** state, which is what a selectable
  row is. IUX-011 recorded the same gap for the selection controls.

The right fix is a helper in the accessibility runtime, which is another
mission's file. `PROJECT_PROMPT.md` §16 puts accessibility above consistency, so
the deviation is taken and written down rather than worked around.

## Evidence level

**Standard** for the accessibility guarantees — accessible name, role, checked
state, target size, target spacing, text scaling, reduced motion, colour never
the sole carrier of meaning.

**Strong guidance** for refusing a control inside an activatable row, which is a
recurring finding in screen-reader usability work rather than a clause in a
specification, and for a selectable row using checkbox semantics.

**Context dependent** for letting stacked rows touch, for the two-thirds/one-third
split between text and value, for the enlarged-text stacking threshold (inherited
from `IuxAccessibility.prefersStackedLayout`, itself documented as a heuristic),
and for allowing `trailingAction` on an interactive row at all — which is where
this component makes a judgement `IuxCard` did not have to make.

**Hypothesis**, and the honest label: that a sibling trailing control on a
tappable row is understood by users as two targets rather than one. The geometry
and the semantics are guaranteed; whether people perceive the boundary needs
device testing with TalkBack and with users who have a motor impairment. It is
listed under manual validation above for exactly that reason.

## Sources

- WCAG 2.2 — SC 1.3.1 Info and Relationships, SC 1.3.2 Meaningful Sequence,
  SC 1.4.1 Use of Color, SC 1.4.4 Resize Text, SC 2.1.1 Keyboard,
  SC 2.4.7 Focus Visible, SC 2.5.8 Target Size (Minimum), SC 4.1.2 Name, Role,
  Value.
- Android accessibility guidance — grouping content for TalkBack, and touch
  target sizing.
- `docs/components/card.md` — the rule this component inherits and extends.
- `docs/components/selection-controls.md` — the semantics a selectable row
  reuses rather than reinvents.
- `docs/components/component-standard.md`.
