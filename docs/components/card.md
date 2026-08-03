# IuxCard and IuxContentGroup

## Purpose

Give related content a visible boundary, so a user can tell where one thing
stops and the next begins.

```dart
IuxCard(
  child: OrderSummary(order),
  actions: <Widget>[IuxButton(label: l10n.track, ...)],
)
```

```dart
IuxCard.tappable(
  semanticLabel: l10n.orderNumber(order.reference),
  hint: l10n.opensTheOrder,
  onActivate: () => open(order),
  child: OrderSummary(order),
)
```

## A card is not a section

This is the comparison worth reading before choosing.

| | What it does | What a screen-reader user gets | Reach for it when |
| --- | --- | --- | --- |
| `IuxSection` | names a group and spaces its children apart | a **heading landmark** to navigate by | the group deserves a name |
| `IuxContentGroup` | encloses several items in one object | a container boundary and one stop per item | the items are parts of one thing |
| `IuxCard` | presents one object with a visible boundary | a container boundary, no name | the object is one of several on the page |

A card draws a box. It does not say what is in the box. A page built only from
cards gives a screen-reader user a sequence of unlabelled containers and no
structure at all — no headings to jump between, nothing to skim. That is why
sections go **outside** cards:

```dart
IuxSection(
  title: l10n.recentOrders,           // the name, and the landmark
  children: <Widget>[
    IuxCard(child: OrderSummary(a)),  // the objects
    IuxCard(child: OrderSummary(b)),
  ],
)
```

`IuxContentGroup` takes no title on purpose. A second way to write a heading
would be a second way to write one that never reaches the heading index. Wrap
it in a section instead.

## Tappable, or containing actions. Never both

A card that is itself a link **and** contains buttons is the most common
accessibility failure of this component. IUX makes it unrepresentable rather
than discouraged.

**What goes wrong.** A screen reader announces the card as a button and then
announces the buttons inside it: the user hears controls nested in a control
and cannot tell which one they are on. A sighted user has no way to see where
"open the card" stops and "press the button" starts, so a tap resolves against
a boundary they cannot perceive. Keyboard traversal stops on the card and again
on every control inside it, with nothing to say the outer one does something
different.

**How the rule is enforced.** Two layers, because either one alone leaks:

1. **The API.** `IuxCard.tappable` has no `actions` parameter. The sanctioned
   way to put a control in a card is closed for the form that is itself a
   control. This is a compile error, not a runtime one.
2. **A debug-only subtree check.** A control dropped straight into `child`
   would slip past the first layer, so a tappable card walks its own content
   after the first frame and throws, naming the offending widget:

```text
A tappable IuxCard contains an interactive element (IuxButton).

A card that is itself a control and also contains controls has two answers to
"what does tapping do", and nothing on screen tells the user which one they are
about to get. …

Either keep the whole card tappable and move the control outside it, or use the
default IuxCard constructor and pass the control in `actions`, where it stays
its own target with its own name.
```

The check recognises a `GestureDetector` carrying a tap handler and a
`Semantics` node claiming a button, link, text field, slider or tap action —
between them, every IUX control and every Material one. Its limits are real and
worth knowing: it does not see custom hit testing, it deliberately ignores
long-press-only handlers so a tooltip does not trip it, and it is compiled out
of release builds. It finds the mistake fast; it does not prove the mistake is
absent.

## A tappable card is one control, and it has a name

`semanticLabel` is required and may not be empty. A container with a tap
handler and no name is announced as "button" and nothing else, which tells the
user that something will happen and refuses to say what.

The card is **one** stop for a screen reader, and its content is **merged into**
that stop rather than dropped:

```text
"Open order 3141, Order 3141, Delivered, €82.40, button. Opens the order."
 └ semanticLabel ┘└──────── the card's own text ────────┘
```

The alternative — excluding descendant semantics, which is what a button does —
would delete the status and the amount from the interface of every
screen-reader user, leaving them to open the card to learn what a sighted user
reads at a glance. The cost of merging is a little repetition when the label
restates a title the card already shows. That is the cheap failure; a card that
announces only "button" is the expensive one.

Write `semanticLabel` as what the card **is**. The button role already says it
can be activated, and `hint` is there for the outcome ("opens the order").

## Grouping does not rest on elevation

There is no elevation parameter and a card never casts a shadow.

A shadow disappears three ways: the theme resolves elevation to zero under a
reduced visual stimulation preference, shadows are close to invisible in dark
conditions, and they vanish entirely in greyscale. Anything that survives all
three has to be the real signal, so the real signals are **surface contrast**
and **an outline** — both measurable, and neither of them something a user
turns off by accident.

The outline is unconditional rather than a parameter, and the reason is
concrete: in the light profile the theme paints a raised surface the same
colour as the page. On that profile the outline is the *only* thing marking the
card. A `bordered: false` option would be an option to make the card disappear.

`IuxContentGroup` adds a third signal between its items — a separator drawn in
the subtle border role. That role is exempt from the 3:1 contrast minimum,
which is correct here: the separator repeats a boundary the padding already
expresses, so a user who cannot see it loses nothing.

## API

### `IuxCard`

| Parameter | Required | Note |
| --- | --- | --- |
| `child` | yes | the content, in reading order |
| `actions` | no | controls belonging to the card; null when there are none |

### `IuxCard.tappable`

| Parameter | Required | Note |
| --- | --- | --- |
| `child` | yes | the content, and it must contain no control |
| `semanticLabel` | yes | the accessible name; may not be empty |
| `onActivate` | yes | called once per accepted tap |
| `hint` | no | what activating does |
| `autofocus`, `focusNode` | no | focus handling |

### `IuxContentGroup`

| Parameter | Required | Note |
| --- | --- | --- |
| `children` | yes | the items, in reading order; each is padded by the group |

There is no colour, radius, elevation or padding parameter anywhere here, and
there will not be one. An API that accepts a colour has already lost the
contrast guarantee: the theme can no longer be held responsible for something a
call site overrode.

There is no `IuxActionDescriptor` on the tappable card either. A card that
opens something has no intent, no destructiveness and no operation of its own,
so a descriptor would offer three dimensions that are all meaningless here —
and one of them would silently colour the card as destructive.

## States

| State | Card | Tappable card | Group |
| --- | --- | --- | --- |
| default | ✓ | ✓ | ✓ |
| pressed | — | tint from `state.pressed`, faded in under `IuxMotionRole.stateChange` | — |
| focused | — | focus ring, drawn outside the card so it never covers content | — |
| disabled | not modelled | not modelled | not modelled |
| loading, error, empty | the parent's, rendered as content | same | same |

**Disabled is deliberately absent.** `onActivate` is non-nullable on
`IuxCard.tappable`, so there is no state where the card looks activatable and
is not. A card that should not be opened is a card that should not be tappable;
render the plain form.

## Accessibility

- A tappable card is announced as an enabled button with the name it was given,
  followed by the text it shows.
- It is **one** stop. A plain card is **not** one stop: its content and its
  actions stay individually reachable, which is what makes `actions` usable at
  all. Both are asserted by counting semantics nodes that are not merged into
  their parent.
- Enter and Space activate a tappable card; it is reachable by keyboard and by
  D-pad.
- The interactive region is never smaller than the resolved touch target floor,
  at every density, however small the content.
- Adjacent entries in `actions` keep at least `kIuxMinimumTargetSpacing`
  between them. Target size alone does not prevent mis-taps — a finger landing
  on the seam between two touching targets has no margin for error.
- Content order is semantic order. `child` then `actions`, in tree order, with
  nothing reordered visually that is not also reordered semantically.
- Text wraps and is never truncated by the card. Verified at 200% on a 320×480
  screen for all three widgets.
- Rendered right-to-left and on all four theme profiles under test.

**Verified in widget tests.** Still requires checking on a device: TalkBack
reading order and how it announces the merged card label in practice, Voice
Access naming of a card whose name is not visible text, and D-pad traversal
between cards in a scrolling list.

## Anti-patterns

```dart
// Wrong: two answers to "what does tapping do".
IuxCard.tappable(
  semanticLabel: 'Order 3141',
  onActivate: open,
  child: Column(children: <Widget>[summary, IuxButton(...)]),  // throws in debug
)

// Right: the card is the control, and the extra action lives beside it.
Column(children: <Widget>[IuxCard.tappable(...), IuxButton(...)])

// Also right: the card is not a control, and each action is its own target.
IuxCard(child: summary, actions: <Widget>[IuxButton(...)])
```

```dart
// Wrong: the card is the page structure. Nothing is named, nothing is a
// landmark, and a screen reader user has no way to skim.
Column(children: <Widget>[IuxCard(...), IuxCard(...)])

// Right: the section names the group; the cards are the objects in it.
IuxSection(title: l10n.recentOrders, children: <Widget>[IuxCard(...), ...])
```

```dart
// Wrong: a card around one control. A button with a box drawn round it, and
// one more container for a screen reader to step through.
IuxCard(child: IuxButton(...))
```

```dart
// Wrong: three unrelated objects presented as one.
IuxContentGroup(children: <Widget>[orderA, orderB, orderC])

// Right: a group is one object's parts.
IuxContentGroup(children: <Widget>[street, city, postcode])
```

## Limits

- **No selection.** A selected card needs a non-colour signal and a `selected`
  semantics flag, and belongs with list items — IUX-020.
- **No disabled state**, by construction. See *States*.
- **No tone or surface level.** A card is always `IuxSurfaceRole.raised`. A
  card inside an already-raised container — a bottom sheet — may have too
  little contrast against it. Sheets are IUX-017, and the parameter should be
  added when there is something real to measure it against.
- **No edge-to-edge content.** The card owns its padding, so a full-bleed image
  header is not expressible. Adding a padding parameter would reintroduce
  hardcoded spacing at call sites; a dedicated media slot is the likelier
  answer, and it is not needed yet.
- **A tappable card is padded slightly more than a plain one**, because the
  focus ring reserves its gap whether or not it is drawn. Mixing both in one
  list produces a small difference in outer size. Reserving the gap is the
  deliberate half: focus must not move the layout when it appears.
- **`IuxContentGroup` builds eagerly** and does not clip its children. Long
  lists are IUX-020; a child that paints its own background will spill past the
  group's rounded corners.
- **The nested-control check is a debug heuristic**, not a guarantee. See
  *Tappable, or containing actions*.
- **`IuxCard` and `IuxContentGroup` are not exported from the barrel yet.** The
  export lines belong to whoever owns `lib/iux_flutter.dart`.

## Deviation from the Component Standard

§2 of the standard says a component uses the `IuxSemantics` helpers rather than
a bare `Semantics` widget. These three widgets use `Semantics` directly, in
three places, and the reason is the same each time: the helper set has no form
for what is needed.

- `IuxSemantics.action` sets `excludeSemantics: true`. Correct for a button
  whose only content is its own label; for a card it deletes the content.
- `IuxSemantics.group` keeps the content but announces no role, so a tappable
  card would be a container the user can activate without being told they can.
- Neither helper exposes `explicitChildNodes`, which is what stops a plain card
  absorbing its own controls into a single node — the failure this mission
  found by writing the test before believing the code.

The right fix is a helper in the accessibility runtime, which is another
mission's file. `PROJECT_PROMPT.md` §16 puts accessibility above consistency,
so the deviation is taken and written down rather than worked around.

## Evidence level

Standard for the accessibility guarantees — accessible name, role, target size,
target spacing, text scaling, reduced motion. Strong guidance for refusing the
tappable-card-with-actions combination, which is a recurring finding in
screen-reader usability work rather than a clause in a specification. Context
dependent for the section/group/card split and for the eager separator layout.

## Sources

- WCAG 2.2 — SC 1.3.1 Info and Relationships, SC 1.3.2 Meaningful Sequence,
  SC 1.4.1 Use of Color, SC 1.4.4 Resize Text, SC 2.1.1 Keyboard,
  SC 2.4.7 Focus Visible, SC 2.5.8 Target Size (Minimum), SC 4.1.2 Name, Role,
  Value.
- Android accessibility guidance — grouping content for TalkBack.
- `docs/layout/overview.md` for the primitives this composes.
- `docs/components/component-standard.md`.
