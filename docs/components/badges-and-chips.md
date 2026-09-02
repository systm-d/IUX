# IuxStatusIndicator, IuxValueIndicator, IuxBadge and the chips

## Purpose

Report a state, a reading, a count, or an attribute in the smallest amount of
space an interface has — without letting colour become the thing that carries
the meaning.

- `IuxStatusIndicator` reports a **state** — news about something the user can
  act on.
- `IuxValueIndicator` reports a **reading**, held against a reference the caller
  names: a quantity, which side of the reference it fell on, and the word that
  says what that means.
- `IuxBadge` reports a **count**.
- the chips report an **attribute**, or switch a criterion.

```dart
IuxStatusIndicator(status: IuxStatus.error(l10n.paymentDeclined))

IuxValueIndicator(
  value: IuxValue.above(
    '+2.1 °C',
    meaning: l10n.warmer,
    label: l10n.aboveTheNormalBy(2.1),
    accent: IuxValueAccent.one,
  ),
)

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
| `IuxValueIndicator` | a quantity has been compared with a reference and the deviation is worth seeing |
| `IuxBadge.count` | you can say how many of something are waiting |
| `IuxBadge.marker` | there are some and the number does not matter |
| `IuxTagChip` | you are showing an attribute the record already has |
| `IuxFilterChip` | the user switches a criterion on and off and sees the effect at once |
| `IuxChipGroup` | you have chips — any number of them, including one |

## Do not use when

- **A status is something the user can act on.** The indicator reports; it takes
  no focus and no gesture. Put a button beside it.
- **A reading is really a state.** An order that failed is not a number above a
  reference. Use `IuxStatusIndicator`, which draws a category glyph and says
  what happened.
- **A reading nobody compared with anything.** A column of `IuxValue.at` pills
  reading `0.0` on every row is decoration users learn to skip. If there is no
  reference, there is no deviation to interpret, and the number belongs in
  plain text.
- **A reading the user can act on.** The pill takes no focus, has no touch
  target and reports no gesture. Put a button beside it.
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

### `IuxValue` and `IuxValueIndicator`

| Member | Required | Note |
| --- | --- | --- |
| `IuxValue.above(value, meaning:, label:, accent:)` | all four | the reading sits on the upper side of its reference |
| `IuxValue.at(value, meaning:, label:)` | all three | the reading is level with its reference, and takes no accent |
| `IuxValue.below(value, meaning:, label:, accent:)` | all four | the reading sits on the lower side |
| `IuxValueIndicator(value:)` | value | draws it |

Three strings, three jobs:

| field | drawn | announced | example |
| --- | --- | --- | --- |
| `value` | yes | no | `+2.1 °C` |
| `meaning` | yes | no | `warmer` |
| `label` | no | yes | `2.1 degrees above the 1991 to 2020 normal` |

`value` is the formatted numeral. `meaning` is the word that interprets it,
drawn under the capsule, and it is **required** — a deviation shown on its own
leaves its interpretation to the hue, which is exactly what a monochrome screen,
a colour vision deficiency and a screen reader all fail to deliver. `label` is
the sentence the screen reader gets; the drawn strings are excluded from the
semantic tree, so whatever `meaning` says has to be inside `label` too.

The constructor refuses an empty `value`, an empty `meaning`, an empty `label`,
a `label` equal to `value`, and a `meaning` equal to `value`. A label that
repeats the numeral hands a screen-reader user a number with no referent; a word
that repeats it interprets nothing.

`value` is a `String`, not a number, for the reason `IuxBadge.count` is: `2,1`,
`2.1` and `٢٫١` are three different strings, and only the caller knows which
applies, along with the unit and where it goes.

There are three directions and there will not be a fourth. A quantity compared
with a reference is above it, level with it, or below it; "far above" is not a
fourth direction, it is a bigger number, and it belongs in `value`.

`accent` is one of four hues that mean nothing on their own —
`IuxValueAccent.one` to `.four`. It is required on `above` and `below` and
absent from `at`. See "Why the direction does not choose the colour" below.

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
| | `mark` | no | `IuxChipMark.checkmark` (default) or `.outline` — see the width budget below |

`onSelectionChanged` is `required` *and* nullable. Null means "this criterion is
currently unavailable" and produces disabled semantics along with the disabled
appearance, so the two cannot drift. It has to be written out at the call site
because a chip that is never selectable is an `IuxTagChip` and should have been
one from the start.

There is no colour, radius, elevation, icon or duration parameter anywhere in
this family, and there will not be one. An API that accepts a colour has already
lost the contrast guarantee.

## The width budget, and the reserved slot

A filter chip is far wider than its label. Measured in-harness at one device
pixel per logical one, standard density, no text scaling, on a 360-wide screen:

| | `IuxChipMark.checkmark` | `IuxChipMark.outline` |
| --- | --- | --- |
| one-character label | 78 px | 56 px |
| two-character label | 93 px | 65 px |
| between two chips | 8 px | 8 px |
| four two-character chips | 120 px, **two lines** | 56 px, **one line** |
| seven two-character chips | 184 px, **three lines** | 120 px, **two lines** |

With the default mark, on that screen, **four two-character chips do not fit on
one line and seven take three**. Both are what a set of thresholds or a week of
days looks like, and both are the case where reading the row at a glance was the
whole point.

**Shortening the labels does almost nothing.** 22 of a one-character chip's 78
pixels are the reserved slot and the space before it, and only 16 are the
character itself. The slot does not care how long the text is, so going from
three letters to two saves 16 pixels a chip and rarely a whole line. This is not
intuitive at the moment somebody is trying to compact a row, and three call sites
in a migrating application left the component over it (`IUX-CHIP-WIDTH-001`).

### `IuxChipMark`

`IuxChipGroup.mark` chooses which of the chip's three selection signals gets the
width.

- **`checkmark`** — the default. A glyph in a slot reserved whether or not it is
  filled, plus the heavier outline, plus the announced state. Three signals, one
  of them a shape rather than a colour or a weight.
- **`outline`** — no glyph and no slot for one. The fill, the outline weight and
  the announcement remain. Weight is not colour, so WCAG 2.2 SC 1.4.1 is still
  satisfied — but a change of outline weight is a quieter signal than a glyph
  appearing, and quieter for exactly the users the glyph was put there for. That
  is why it is not the default.

```dart
IuxChipGroup(
  label: l10n.refreshInterval,
  mark: IuxChipMark.outline,
  chips: intervals,
)
```

**Use `outline`** where the row is a short scale the user reads at a glance —
thresholds, intervals, the days of a week. **Do not** use it for a set of named
criteria a user picks through, where a chip may be the only thing on screen
saying a filter is applied.

Neither value reflows. The heavier outline is drawn inside the padding rather
than added to it, so a chip is the same size chosen as unchosen either way.

`mark` sits on the group rather than on the chip so that a row cannot be half one
shape and half the other — `chips` is a list of widgets the caller builds, and a
per-chip parameter would allow a row with a ragged left edge and nothing on
screen to explain it. It reaches every `IuxFilterChip` below the group, including
one the caller wrapped in its own widgets. A chip outside any group gets the
default.

The text widths above are an upper bound: under `flutter_test` every glyph is a
square of the font size, so a two-character label measures two 16-pixel boxes. A
proportional face fits more per line. The slot does not change.

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
7. **`IuxValue` has no constructor that omits the word.** `meaning` is required
   on all three, may not be empty, and may not equal the reading. A deviation
   whose interpretation is its hue cannot be built, which matters here more
   than anywhere else in this family: two of the four accents are the same
   colour to a reader with deuteranopia.

The mirror of that: nothing here relies on a glyph *instead* of words. The glyph
is excluded from the semantic tree in every case, because it repeats what the
label already says. An icon carrying information the label does not is
information a screen-reader user never receives.

## Why the reading has its own axis, and does not borrow the four tones

`IuxStatusTone` has four members and they are four families of **news**: a fact,
a state the user wanted, a state that will stop working, a state that has
stopped. `iux_status_model.dart` says so in those words, and warns on `neutral`
that colouring a neutral state red "asks the user to react to something that
needs no reaction".

A reading is not news until somebody judges it, and the framework is not who
judges it. Drawing "2.1 degrees above the normal" through `IuxStatusTone.error`
to obtain the red the eye expects asserts that a warm summer is a malfunction —
a claim IUX has no standing to make and the user no way to argue with, because
it arrives as a colour rather than as a sentence.

So the pill has a second axis, not a fifth tone. **"Four tones and no more"
still holds**: it bounds the axis of news, and its reason — that a fifth family
of news would be a domain concept — is exactly why above, level and below are
not one. A budget, a blood pressure, a lap time and a rainfall total are all
read against a reference, in every domain, and none of them is good or bad news
until the words say so. See
[../decisions/ADR-0013-a-reading-is-compared-not-judged.md](../decisions/ADR-0013-a-reading-is-compared-not-judged.md).

## Why the direction does not choose the colour

`ADR-0013` gave the pill an axis with a warm end and a cool one, and assumed
what every diverging scale assumes: that one side of a reference always takes
one hue. One application disproves it, and it is the application the axis was
built for.

| Quantity | Deviation | Word | Hue |
| --- | --- | --- | --- |
| temperature | above | warmer | warm |
| temperature | below | colder | cool |
| rainfall | above | wetter | cool |
| rainfall | below | drier | amber |

Two of those are above their reference and two below, and the hues cross the
axis rather than following it. Worse, the axis had two ends and this needs
three hues: **"drier" had no colour at all.**

What decides the hue is not the arithmetic but what the quantity *means*, and
that is the application's to know. So `IuxValueAccent` is four hues with no
names — `one` to `four`, unranked, in the vocabulary shape `IuxAvatarTone`
already has — and the caller picks. Naming them `warm` and `cool`, or `hot` and
`wet`, would ship meteorology inside a framework; naming them nothing ships a
palette and leaves the meaning in `meaning`, where the user reads it in words.

The one colour the arithmetic still decides is the absence of one: `IuxValue.at`
takes no accent, because a reading level with its reference has nothing to
interpret. See
[../decisions/ADR-0015-the-sign-is-not-the-meaning.md](../decisions/ADR-0015-the-sign-is-not-the-meaning.md).

## Why the value pill has a word, and no longer has a mark

There used to be an arrow, and the argument for it was sound. `+2.1 °C` reads as
"above" on a monochrome screen, under any colour vision deficiency, and out
loud — but `IuxValue.above('2.1 °C', …)` compiles, and so does every locale's
formatting of a deviation that writes no sign. What IUX can promise is what it
can refuse to build, and it cannot refuse a string; it cannot supply the sign
either, because it composes no user-facing text and a `+` written by the library
would be the wrong glyph in some scripts and on the wrong side in others.

The arrow answered that with a shape nobody hears, and it answered nothing at
all about *meaning*: it said which side, never which sense. `meaning` answers
both, cannot be omitted, and reaches every reader.

| Signal | Reaches |
| --- | --- |
| `IuxValue.meaning` | a monochrome screen, a colour vision deficiency |
| `IuxValue.label` | everyone, including a screen reader |
| the formatted reading | everyone who can see the capsule |
| the accent colour | everyone else, as reinforcement |

The measurement behind the first row, taken this round in Oklab ×100 on the
shipped mapping: the four accents reuse the four hue families `avatarAccent`
spends, so they inherit the collision `IUX-PALETTE-PERCEPTION-001` recorded.
Every profile has a pair under 3 apart at the worst dichromacy, and the pair the
pilot needs is one of them — the warm accent against the amber one measures
**2.2 apart in the light standard profile and 1.1 in light high contrast, under
deuteranopia**. To the most common dichromacy, "plus chaud" and "plus sec" are
one colour and two words.

## Why the capsule is a tint with no outline

`ADR-0013` put the reading on the profile's neutral subtle surface and drew a
line around it, reasoning that a pill repeats down a column of rows and thirty
tinted panels is a screen of alarms. The reasoning is right and the remedy was
the wrong one: what reads as an alarm is the *ring*, not the wash. The capsule
is now a tint of its accent's own hue, with no outline at all.

The tints measure between **1.07 and 1.28** from the page across the four
profiles — a wash, not an object. That is deliberate: a capsule reaching the 3:1
WCAG 2.2 SC 1.4.11 asks of a graphical object would be a bordered box in
everything but name, and the capsule's extent carries nothing. The reading
inside it and the word beside it are text, and both are held to 4.5:1 — the
same colour, on two grounds, measured twice.

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
| `IuxValueIndicator` | at rest — the only one it has | — |
| `IuxBadge` | counted / marker | which constructor was called |
| `IuxFilterChip` | unselected, selected | `selected`, owned by the parent |
| | disabled | `onSelectionChanged == null` |
| | pressed | the widget's own, while a finger is down |
| | focused | the widget's own, drawn additively |
| `IuxTagChip` | read-only | the only one it has |

**`IuxValueIndicator` has one state and it is at rest.** It has no focus, no
pressed, no disabled, no loading, no error and no empty state, and it has no
motion of any kind. That is written here rather than left to be discovered
because §6 of the component standard asks a component that cannot express a
state to say so: a reading that is loading is a row that is loading, and a
reading the user can act on is a reading beside a button.

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

- **`IuxChipMark.outline` gives up a signal, and there is no way to get it back
  cheaply.** Selection is left carried by the fill, the outline weight and the
  announcement. A denser mark that kept a shape without holding a slot — a fill
  covering the whole chip, a rule under the label — was not attempted: it would
  be a fourth visual language for "chosen" in a library that already has three,
  and it is the same question `IuxRadioGroup` faces about its ring
  (`IUX-RADIO-LAYOUT-001`). Both should be answered together or not at all.
- **The outline mark is still 56 pixels wide for one character.** The floor is
  the touch target, not the content, so a row of seven still takes two lines on
  a 360-wide screen. Nothing here can go below `minimumTouchTarget`, and nothing
  should.
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
  label. This bounds the axis of *news*; `IuxValueDirection` is a second axis
  rather than a fifth tone, and ADR-0013 is where that is argued.
- **Four accents and no more, and nothing tells an application which is
  which.** `IuxValueAccent.one` to `.four` mean nothing; an application that
  maps them consistently gets a column a reader can scan, and one that maps
  them differently on two screens gets two vocabularies. Nothing here can
  refuse that, because a hue with no meaning has no wrong use.
- **Two of the four accents collide under a colour vision deficiency, in every
  profile.** They reuse the four hue families `avatarAccent` spends, so the
  collision `IUX-PALETTE-PERCEPTION-001` measured is inherited rather than
  introduced. Measured this round, worst pair under deuteranopia: **2.2** in
  light standard, **1.5** in dark standard, **1.1** in light high contrast,
  **0.4** in dark high contrast, all in Oklab ×100. The word is the mitigation
  and it is required, which is the strongest form the framework has.
- **Two pills that differ only in accent are separated by hue and one word, and
  nothing in this component can refuse two that differ by nothing at all.**
  `IuxValue` requires a word and a label and forbids either repeating the
  reading, which is as far as a constructor can go; whether two words actually
  differ is a judgement no test can make.
- **In the two dark profiles a value capsule and a feedback panel are the same
  colours.** The shipped palette gives `comparison.one` the rung
  `feedback.error` takes there, on the same surface, and the words and the
  geometry are what separate them.
- **The capsule's extent is below 3:1 against the page on purpose**, measured
  this round at 1.07 to 1.28. It is a wash rather than an object, so SC 1.4.11
  does not apply to it — but an application that needed the capsule's boundary
  to *mean* something would not get it from here.
- **Nobody has measured how narrow a value pill can be.** The status
  indicator's floor — 180.3 px at 100% text for one unwrappable word
  (`IUX-LISTITEM-TRAILING-001`) — was taken on a component carrying a glyph, a
  gap and a *label*, and a value pill now carries a reading, a capsule and a
  word with different wrap points. **That number does not transport.** It is to
  be re-taken on a 320-pixel screen and written here.
- **IUX is never told what counts as "above".** The caller compares and passes
  the result; a framework that chose the tolerance would be choosing it for a
  quantity it cannot see.
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
| A reading gets a direction axis rather than a status tone | Context dependent — IUX governance, ADR-0013 |
| The caller picks the accent rather than the direction | Context dependent — IUX governance, ADR-0015 |
| Two of the four accents collide under deuteranopia | Measured — `test/themes/palette_perception_test.dart`, this round |
| The capsule's tint is a wash rather than an object | Measured — `test/themes/theme_contrast_test.dart`, this round |
| A required word beats a drawn arrow as the non-colour signal | Context dependent — it is text rather than a shape, so it also reaches a screen reader |
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
