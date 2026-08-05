# IuxStatusIndicator, IuxBadge and the chips

## Purpose

Report a state, a count, or an attribute in the smallest amount of space an
interface has — without letting colour become the thing that carries the
meaning.

```dart
IuxStatusIndicator(status: IuxStatus.error(l10n.paymentDeclined))

IuxBadge.count(count: l10n.formatCount(3), label: l10n.unreadMessages(3))
IuxBadge.marker(label: l10n.unreadMessages)

IuxTagChip(label: l10n.categoryVegetarian)

IuxChipGroup(
  label: l10n.filterByDiet,
  chips: <Widget>[
    IuxFilterChip(
      label: l10n.categoryVegetarian,
      selected: filters.vegetarian,
      onSelectionChanged: controller.setVegetarian,
    ),
  ],
)
```

This is the family where "colour alone" failures concentrate. A green dot
meaning online, a red badge meaning error, a coloured chip meaning category —
each of those is invisible to a screen-reader user, ambiguous to roughly 1 in 12
men, and gone entirely on a monochrome screen, in direct sunlight, or under a
platform colour override. `docs/accessibility/color-and-non-color-signals.md`
makes the rule absolute; this document is what applying it produced.

## Use when

| Component | Use it when |
| --- | --- |
| `IuxStatusIndicator` | a record, row or connection is in a state that changes what the user can do |
| `IuxBadge.count` | you can say how many of something are waiting |
| `IuxBadge.marker` | there are some and the number does not matter |
| `IuxTagChip` | you are showing an attribute the record already has |
| `IuxFilterChip` | the user switches a criterion on and off and sees the effect at once |
| `IuxChipGroup` | you have chips — any number of them, including one |

## Do not use when

- **A status is something the user can act on.** The indicator reports; it takes
  no focus and no gesture. Put a button beside it.
- **A badge is the thing being pressed.** A badge is never tappable. Whatever it
  decorates owns the gesture and the touch target; the badge owns neither.
- **A badge stands for a state.** An order that failed is a status, not a
  number. `IuxBadge` has one tone and no others, on purpose: a red badge reports
  an error the count has not had.
- **A chip runs an action.** A chip that submits, navigates or deletes is a
  button wearing the wrong shape. Use `IuxButton`, which announces itself as
  one.
- **A chip is one of several where exactly one must win.** A row of chips gives
  no clue that the options are exclusive. A radio group does.
- **A tag is really a control.** If the user can change it, it is an
  `IuxFilterChip` and it needs the target floor, the focus ring and the
  announced state that a tag deliberately lacks.

## The decision that shapes this API: two chips, not one

There is no `IuxChip`. There is `IuxTagChip` and there is `IuxFilterChip`, and
the difference is not a flag.

A single type with an optional `onSelectionChanged` would produce a widget that
is sometimes a control and sometimes text, looking identical either way. A user
cannot tell those apart without trying them, and a screen-reader user is told
one of two different things about the same shape depending on a parameter they
cannot see. That is the same reasoning that made `IuxIconButton` a separate
widget from `IuxButton` rather than a nullable `label`.

So the two differ in every dimension that matters, and the differences are
enforced rather than recommended:

| | `IuxTagChip` | `IuxFilterChip` |
| --- | --- | --- |
| announced as | a labelled group | a button, with a selected state |
| focus | never takes it | takes it, ring visible |
| keyboard | not reachable | Enter and Space activate it |
| touch target | none — resolved minimum is `0` | at least the resolved floor |
| gesture | no `GestureDetector` at all | tap, with press feedback |
| outline | `border.subtle`, the one role IUX forbids on interactive elements | `border.interactive`, then `border.strong` when chosen |

The last row is the one that matters visually: a tag does not merely behave
differently from a filter chip, it *looks* different, because it is drawn with
the border role whose own documentation says never to use it to delimit a
control.

## API

### `IuxStatus` and `IuxStatusIndicator`

| Member | Required | Note |
| --- | --- | --- |
| `IuxStatus.neutral(label)` | label | a state with no consequence: idle, offline, draft |
| `IuxStatus.success(label)` | label | connected, paid, published |
| `IuxStatus.warning(label)` | label | expiring, low, degraded |
| `IuxStatus.error(label)` | label | failed, rejected, disconnected |
| `IuxStatusIndicator(status:)` | status | draws it |

There is no constructor without a label and no label that may be empty. That is
the whole design. See "How the non-colour signal is made structural" below.

### `IuxBadge`

| Constructor | Parameters | Note |
| --- | --- | --- |
| `IuxBadge.count` | `count`, `label` | `count` is what the eye reads, `label` what the ear hears |
| `IuxBadge.marker` | `label` | a dot; the label is the whole meaning |

`count` is a `String`, not an `int`, for the same reason
`IuxProgressIndicator.valueLabel` is: `3`, `٣` and `99+` are three different
strings, and a component that formatted the number itself would ship Western
numerals into every locale and invent its own overflow marker.

`label` is the complete announcement — `3 unread messages`, not `unread
messages`. IUX will not join a number to a noun, because word order, agreement
and numeral form all vary and only the caller knows the language.

### `IuxTagChip`, `IuxFilterChip`, `IuxChipGroup`

| Component | Parameter | Required | Note |
| --- | --- | --- | --- |
| `IuxTagChip` | `label` | yes | visible text and accessible name |
| `IuxFilterChip` | `label` | yes | the criterion |
| | `selected` | yes | owned by the parent |
| | `onSelectionChanged` | yes, nullable | null means unavailable |
| | `autofocus`, `focusNode` | no | |
| `IuxChipGroup` | `label` | yes | names the set for a screen reader |
| | `chips` | yes | in reading order |

`onSelectionChanged` is `required` *and* nullable. Null means "this criterion is
currently unavailable" and produces disabled semantics along with the disabled
appearance, so the two cannot drift. It has to be written out at the call site
because a chip that is never selectable is an `IuxTagChip` and should have been
one from the start.

There is no colour, radius, elevation, icon or duration parameter anywhere in
this family, and there will not be one. An API that accepts a colour has already
lost the contrast guarantee.

## How the non-colour signal is made structural

Every rule below is enforced by the type system or by an assertion that fires at
construction. None of them is a convention.

1. **`IuxStatus` has no constructor that omits the words.** All four are
   `IuxStatus.tone(String label)`, and the shared private constructor asserts
   the label is non-empty. A status carried by a coloured shape cannot be built.
2. **`IuxStatusIndicator` always draws that label.** There is no `showLabel`
   flag, no `compact` variant and no dot-only form. The failure is unreachable
   rather than discouraged.
3. **Each tone resolves a different glyph.** `IuxStatusResolver.glyph` is public
   so the rule is asserted directly: the four shapes must stay distinct, because
   two tones drawn identically are two tones separated by hue alone.
4. **A badge may not announce its own number.** `IuxBadge.count(count: '3',
   label: '3')` throws. That is the exact shape of the mistake — a digit with no
   noun — so it is rejected rather than reviewed.
5. **Selection is three signals, not one.** A chosen chip gains a checkmark, a
   heavier outline and an announced `selected` state. Remove the fill colour and
   two of the three remain.
6. **A tag cannot announce itself as a button.** It is built from
   `IuxSemantics.group`, never `IuxSemantics.action`, and it has no
   `GestureDetector` and no `Focus` to reach.

The mirror of that: nothing here relies on a glyph *instead* of words. The glyph
is excluded from the semantic tree in every case, because it repeats what the
label already says. An icon carrying information the label does not is
information a screen-reader user never receives.

### Why a marker badge is not a colour-alone failure

A dot with no number looks like the thing this document forbids, and is not.
What carries the meaning is that the marker is *there* — presence and absence
survive a monochrome screen, a colour override and a screen reader, provided the
marker is named. What would fail is two markers of different colours meaning
different things, which is why `IuxBadge` has exactly one tone.

## States

| Component | State | Source |
| --- | --- | --- |
| `IuxStatusIndicator` | one of four tones | the `IuxStatus` the parent holds |
| `IuxBadge` | counted / marker | which constructor was called |
| `IuxFilterChip` | unselected, selected | `selected`, owned by the parent |
| | disabled | `onSelectionChanged == null` |
| | pressed | the widget's own, while a finger is down |
| | focused | the widget's own, drawn additively |
| `IuxTagChip` | read-only | the only one it has |

Neither the status indicator nor the badge has a disabled, focused, pressed or
error state: they are not interactive. `IuxFilterChip` has no loading state — a
filter that takes time to apply is an operation, and the list it filters is
where that belongs.

The chip never changes its own `selected` value. A control that toggled itself
would show a criterion as applied before the list it filters had been rebuilt,
and the two would disagree for as long as the caller took to catch up.

## Accessibility

- **Named, always.** Every component in this family refuses to build without a
  label, and none of them has a form where the label is optional.
- **Announced once.** The visual is excluded wherever the accessible name
  repeats it, so a screen reader hears "3 unread messages" rather than "3"
  followed by "3 unread messages".
- **Roles are honest.** A status and a badge carry no button flag. A filter chip
  carries `button` plus `selected`; a tag carries neither. `selected` rather
  than `toggled`, because a filter is something the user chose rather than a
  switch they threw.
- **And a role that is honest is not enough.** `IuxFilterChip` announced itself
  as a button with **no tap action and no focus state** until this was fixed: a
  screen-reader double-tap did nothing, and assistive technology could not move
  accessibility focus onto it. `IuxSemantics.action` sets `excludeSemantics` to
  control the announced name, which deletes the gesture detector's tap and the
  `Focus` widget's annotations along with it — the IUX-011 and
  IUX-A11Y-FOCUS-001 defects, both live here until a sweep of every composer of
  the helper found them. The chip now carries `[tap, focus]` and reports a real
  focus state, matching `ElevatedButton`. A *disabled* chip still declares no
  focusable state, deliberately: it has left the focus order entirely, and
  announcing "not focused" would describe a state it does not have.
- **Targets.** A filter chip is at least
  `IuxAccessibility.minimumTouchTarget` in both dimensions, at every touch
  target preference. A tag resolves a minimum of `0` on purpose: padding it out
  to 48 would make it look tappable, and a row of things that look tappable and
  are not is worse than a row that looks inert.
- **Spacing.** `IuxChipGroup` applies `kIuxMinimumTargetSpacing` through
  `IuxTargetSpacing`. Target size alone does not prevent mis-taps: a finger
  landing near the seam between two touching targets has no margin for error.
- **The set has a name.** A screen-reader user arriving at eight unrelated
  buttons has no way to know they are the filters for the list below.
  `IuxChipGroup.label` is that sentence, and the chips inside stay individually
  reachable.
- **Text scaling.** Everything works at 200% on a 320×480 screen. No component
  has a fixed height, no label has a line limit or an ellipsis, and the badge
  and the glyphs scale with the text rather than staying put beside it.
- **Nothing moves when a state changes.** The checkmark slot is reserved whether
  or not it is filled, and the heavier selected outline is drawn inside space
  the unselected chip already reserved. A chip that changed width on every tap
  would reflow the group and move the chips the user was about to press next.
- **RTL.** Reading order is directional throughout; the glyph leads in reading
  order rather than on the left.
- **Contrast.** Every pair is measured on all four theme profiles in
  `test/components/iux_status_test.dart`: label on container at 4.5:1, glyph on
  container at 3:1, outline against the page at 3:1, and disabled content at the
  3:1 IUX commits to.

**Verified in widget tests. Still needs a device**: TalkBack phrasing for
"selected" versus "not selected" on a chip, whether the reserved checkmark slot
reads as an empty box under Voice Access, and whether the status pill is
distinguishable from a tag chip at a glance for users who have not been told the
difference.

## Themes

Nothing in this family invents a colour. The status indicator reuses the
**feedback roles** rather than defining a fifth palette — their pairs are
already measured on all four profiles, so a status inherits guarantees instead
of asking for new ones. The badge takes the primary action pair. The chips take
surface, content and border roles that the theme contrast test already covers.

High contrast thickens outlines rather than recolouring them, here as
everywhere: the selected chip's outline is `strongBorderWidth`, which the
geometry theme raises under a high contrast preference.

## Motion

Only the chip moves, and only between two states:
`IuxMotionRole.stateChange` at the short scale. A reduced-motion preference
shortens it; `IuxMotionPreference.none` removes it entirely. Nothing is lost
when it goes — the checkmark, the outline weight and the announced state are all
still there, because the animation was never what carried them.

Nothing in this family pulses, blinks or draws attention to itself. A pulsing
status dot is `IuxMotionRole.emphasis`, which IUX classes as decoration and
removes as soon as the user asks for less; a signal that only exists while it is
animating is a signal those users never get.

## Feedback

No component here emits a haptic, speaks, or shows anything of its own. A chip
toggling is the parent's event to report, per §10 of the component standard.

## Anti-patterns

```dart
// Wrong: the state is the colour, and there is nothing else.
Container(width: 8, height: 8, decoration: BoxDecoration(color: green))

// Right: the words are the state; the colour and the shape reinforce it.
IuxStatusIndicator(status: IuxStatus.success(l10n.online))
```

```dart
// Wrong: a number with no noun. Announced as "3", which is not information.
IuxBadge.count(count: '3', label: '3')   // throws

// Right.
IuxBadge.count(count: l10n.formatCount(3), label: l10n.unreadMessages(3))
```

```dart
// Wrong: a chip that is really a button.
IuxFilterChip(
  label: l10n.clearFilters,
  selected: false,
  onSelectionChanged: (_) => controller.clear(),
)

// Right: it runs an action, so it says so.
IuxButton(label: l10n.clearFilters, action: ..., onActivate: controller.clear)
```

```dart
// Wrong: chips in a bare Row. Adjacent targets touch, and the set has no name.
Row(children: chips)

// Right.
IuxChipGroup(label: l10n.filterByDiet, chips: chips)
```

```dart
// Wrong: a badge floating over the corner of an icon. It covers the glyph,
// clips as soon as the user enlarges their text, and separates the badge from
// its subject in the reading order.
Stack(children: [icon, Positioned(top: 0, right: 0, child: badge)])

// Right: beside what it counts, in reading order.
Row(children: [icon, const IuxGap.horizontal(IuxSpacingStep.xs), badge])
```

```dart
// Wrong: the status tells the user something is wrong and the tone says which.
IuxStatus.error(l10n.error)

// Right: the label stands alone, because it is announced alone.
IuxStatus.error(l10n.paymentDeclined)
```

## Limits

- **No dot-only status, and no way to ask for one.** This is the most likely
  objection to the design, and the answer is that a bare dot is precisely what
  the component exists to prevent. Where a table genuinely has no room for a
  status pill in every row, put the status text in a column of its own; the
  component does not solve that layout for you.
- **A status indicator has a minimum width and it is the width of its longest
  word.** The label wraps, so a two-word status shrinks; a one-word status has
  no wrap point and cannot. Measured: `IuxStatus.neutral('Scheduled')` needs
  **180.3 px at 100% text and 472.3 at 300%**, and given less it breaks inside
  the word — one glyph to a line, and once the glyph and its gap alone exceed
  the room, the label is laid out in a box zero pixels wide and paints outside
  the pill. A caller bounding this component must bound it above that minimum
  or move it somewhere with room. `IuxListItem` learned this the expensive way
  (`IUX-LISTITEM-TRAILING-001`) and now measures the control rather than
  capping it; nothing in this component can detect the mistake for you, because
  from inside it a narrow box and a small screen look identical.
- **The status indicator is not a live region.** A list of thirty rows each
  announcing itself on every refresh is a list nobody can use with TalkBack, and
  only the caller knows which of its statuses is worth an interruption. Wrap it
  in `IuxSemantics.liveRegion` at the call site when a change must be heard.
- **Four tones and no more.** An application needing a fifth meaning is
  describing its domain rather than a UX category, and that belongs in the
  label.
- **No overlay badge.** See the anti-pattern above. If a later mission
  demonstrates the need, it should arrive as a positioning widget with its own
  clipping and text-scaling tests, not as a parameter here.
- **No removable chip.** The "×" on an input chip is a second control inside the
  first, which produces nested targets, an ambiguous tap near the boundary and
  two focus stops that look like one. It needs its own design.
- **No leading icon on a chip.** No demonstrated need, and a category glyph
  beside a category name is either redundant or ambiguous.
- **A chip that is both disabled and selected keeps its checkmark and its
  announced state, but not the heavier outline.** `IuxChipState` is one state
  rather than two independent dimensions, and splitting it would double the
  enum to express a combination that is rare. Two of the three non-colour
  signals survive, which is why it is a limit rather than a defect.
- **A tag chip is smaller than a touch target on purpose**, which means a tag
  placed next to a filter chip in the same row will look inconsistent. That is
  intentional and the two should not be mixed; `IuxChipGroup` does not enforce
  it, because a `List<Widget>` cannot.
- **`IuxChipGroup` wraps rather than scrolls.** A horizontally scrolling chip
  row hides options off screen with no affordance, but wrapping does consume
  vertical space at a large text scale.
- **Whether a status pill and a tag chip are distinguishable at a glance** by
  someone who has not been told the difference is a hypothesis. They differ in
  glyph, fill and outline; that has not been user-tested.

## Evidence level

| Claim | Level |
| --- | --- |
| No state may be carried by colour alone | Standard — WCAG 2.2 SC 1.4.1 |
| Text and meaningful graphics need 4.5:1 and 3:1 | Standard — SC 1.4.3, 1.4.11 |
| Everything works at 200% text | Standard — SC 1.4.4 |
| Interactive elements need the target floor and spacing | Standard — SC 2.5.8, Android guidance |
| A control's role and state must be exposed | Standard — SC 4.1.2 |
| Two chip types rather than one with a flag | Context dependent — IUX governance, §8 of the component standard |
| Reusing the feedback roles for status tones | Context dependent |
| A reserved checkmark slot beats an animated width | Strong guidance — layout stability, Material |
| `selected` rather than `toggled` for a chip | Strong guidance — Material, Android semantics |
| A status pill reads as distinct from a tag chip | Hypothesis — not user-tested |
| The four glyph choices are recognisable | Hypothesis — conventional, not measured |

## Sources

- WCAG 2.2 — SC 1.4.1, 1.4.3, 1.4.4, 1.4.11, 2.1.1, 2.4.7, 2.5.8, 4.1.2.
- Android accessibility guidance — do not rely on colour alone; touch target
  sizing.
- `docs/accessibility/color-and-non-color-signals.md`.
- `docs/accessibility/touch-targets.md`.
- `docs/components/component-standard.md` §5, §6, §7, §8, §10, §11.
- Material Design, on filter chips and chip selection semantics.
