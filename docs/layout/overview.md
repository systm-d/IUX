# Layout system

## Intention

Give screens a predictable skeleton, and make the failures that break layouts
in the field — narrow screens, enlarged text, notches, keyboards — hard to
reproduce.

```dart
Scaffold(
  appBar: AppBar(title: Text(l10n.orders)),
  body: IuxPage(
    child: IuxSection(
      title: l10n.recent,
      children: <Widget>[...],
    ),
  ),
)
```

## Primitives

| Primitive | Responsibility |
| --- | --- |
| `IuxPage` | background, safe areas, width cap, padding, scroll, pinned footer |
| `IuxSurface` | a themed background at a named level |
| `IuxSection` | a titled group, exposed as a screen-reader landmark |
| `IuxGap` / `IuxInsets` | spacing taken from the scale, adapted to density |
| `IuxTargetSpacing` | the minimum separation between adjacent controls |
| `IuxReadableWidth` | a reading-width cap that scales with text size |
| `IuxLayoutClass` / `IuxResponsiveValue` | width-class branching |
| `IuxVerticalSeparator` | the line between two peer columns |

## An app bar over a page is one component

`IuxAppBar` and `IuxPage` written as siblings in a `Column` is the most-repeated
composition any application writes, and it carried three defects
(`IUX-APPBAR-PAGE-001`): the top inset was spent twice, nothing owned the total
height so the frame overflowed at a large text scale, and the standard
fill-viewport-or-scroll remedy threw because the bar decided its layout in a
`LayoutBuilder`.

```dart
Scaffold(
  body: IuxScreen(
    appBar: IuxAppBar(title: l10n.orders),
    page: IuxPage(child: content),
  ),
)
```

`IuxScreen` owns both: the inset is spent once, the chrome may take at most half
the box, and the page keeps the rest. Under an app bar there is no longer an
`IuxPageInsets` decision to make. See `docs/components/screen.md`.

## `IuxPage` does not replace `Scaffold`

A `Scaffold` owns app bars, sheets and the snack bar host. `IuxPage` owns the
content area. They compose, and neither tries to absorb the other — a page
primitive that swallowed `Scaffold` would have to re-expose everything it hid,
badly.

## Scrolling is the default

A screen that does not scroll breaks the moment a user enlarges their text or
a keyboard appears. Both happen constantly, and neither is an edge case.

The scroll physics are `AlwaysScrollableScrollPhysics`, so content can be
dragged out from under a keyboard even when it would otherwise fit.

## Safe areas are opt-in per edge

Applying `SafeArea` everywhere is how double padding happens: a page adds it,
a sheet inside adds it again, and the content sits twice as far from a notch
that exists once.

| `IuxPageInsets` | Use when |
| --- | --- |
| `handled` | a full screen. The default, and the right answer inside an `IuxScreen`. |
| `topOnly` | the bottom is occupied by navigation that handles its own inset |
| `bottomOnly` | the top is occupied by a bar that already does, and that IUX did not draw |
| `none` | edge-to-edge content painting behind the system bars |

Under `none` the application owns the insets, including
`SystemUiOverlayStyle`. IUX imposes no system bar colour.

## Reading width scales with text size

The width caps are expressed in **characters**, then converted using the text
size actually in force.

A fixed pixel cap silently halves the characters per line when a user doubles
their text size — producing a narrow column of enlarged text, which is the
opposite of what they asked for.

| Cap | Characters | Use for |
| --- | --- | --- |
| `narrow` | ~35 | a single input, a confirmation |
| `reading` | ~70 | running prose |
| `standard` | ~100 | forms, lists, cards |
| `wide` | ~140 | dense content such as a table |
| `fluid` | — | no cap |

Below the cap the content simply fills the width, so this never makes a narrow
screen narrower.

## Spacing between targets

`IuxTargetSpacing` guarantees at least 8 logical pixels between adjacent
interactive elements, and raises any smaller request to that floor.

Target *size* alone does not prevent mis-taps: two 48-pixel targets touching
each other still produce them, because a finger landing near the seam has no
margin. WCAG 2.2 SC 2.5.8 recognises this by allowing smaller targets when
spacing compensates; IUX keeps both.

This is the concern IUX-005 explicitly deferred when it delivered the target
floor.

It holds full-width children, and that took fixing (`IUX-EXPAND-CRASH-001`).
It used to be a `Wrap` on **both** axes; a vertical `Wrap` offers its children
no width, so `IuxButton(expand: true)` inside it threw *BoxConstraints forces
an infinite width*. Two stacked full-width buttons is the commonest thing
anyone writes and it was exactly what failed, which pushed every caller onto a
hand-written `Column` and an `IuxGap` — an arrangement that lays out and
guarantees nothing.

```dart
// Two full-width buttons, 8 px apart, at any text scale.
IuxTargetSpacing(
  children: <Widget>[
    IuxButton(label: 'Save', expand: true, /* … */),
    IuxButton(label: 'Discard', expand: true, /* … */),
  ],
)
```

Measured on a 320-wide surface at 100, 150, 200 and 300% text: both controls
take the full 320, and 16 px separates the hit areas — the floor plus the 4 px
the focus ring reserves on each side, which is not interactive. The same holds
for `IuxAsyncActionButton` and `IuxDestructiveFlow`, which pass `expand`
straight through.

**Why not the alternatives.**

- *Make `expand` fall back to shrink-wrapping under unbounded constraints.* It
  removes the exception and keeps the trap: the caller asked for full width and
  silently got the width of the label, so at 100% "Save" comes out at 89 px and
  "Discard" at 132 — a stack of mismatched buttons with no error to explain it.
  Preventing errors outranks developer ergonomics (`PROJECT_PROMPT.md` §5), and
  §22 asks components to *detect* invalid configurations rather than absorb
  them.
- *Assert that the combination is illegal.* Precise, and it leaves the caller
  exactly where they started: on the `Column` and the `IuxGap`. Measured with
  bare 120×48 targets, `Column` + `IuxGap(IuxSpacingStep.xxs)` puts 4 px
  between them and `IuxTargetSpacing` puts 8. The workaround does not merely
  fail to state the floor, it goes under it.
- *Add a dedicated stacking widget.* A second widget meaning "adjacent targets
  keep the floor" is the drift this primitive exists to prevent, it needs a new
  export, and it leaves the trap in `IuxTargetSpacing` open for whoever does
  not find it (§19: does a similar API already exist? It does).

## Wrapping beats clipping, except downwards

`IuxSectionHeader` and the **horizontal** axis of `IuxTargetSpacing` use
`Wrap`, not `Row`. At a large text scale a row of controls stops fitting, and
moving to a second line is better than clipping a label the user cannot then
read.

The vertical axis is a `Column`, because wrapping protects nothing there. A
page scrolls, so the height is usually unbounded and a vertical `Wrap` never
wraps at all; and where the height *is* bounded, wrapping moves the overflow
**sideways and in silence**. Measured in a 320-wide box: the third of three
targets landed at x 256.8–388.5, 68 px past the right edge, with no exception
reported. A `Column` overflows loudly instead — a bug somebody fixes, rather
than a control nobody can reach and no test can see.

## Layout classes

Three, matching Android's window size classes: compact below 600, medium to
840, expanded above.

They are measured from the **available width**, not the physical screen. A
split-screen window on a tablet is compact, and treating it as expanded is the
classic way to ship an unusable multi-window experience.

`IuxResponsiveValue` requires `compact` and falls back upward, so the narrow
case — the one most users are in — cannot be forgotten.

## Reading order

The primitives lay out in tree order, so the visual, semantic and focus orders
agree by construction. Nothing here reorders visually without reordering
semantically.

## One-handed reach

IUX does not impose a thumb-zone rule. Reach depends on hand size, grip, device
size and whether the user has two hands free, and a framework-level rule would
be wrong for most of them.

`IuxPage.footer` exists so a primary action can stay reachable without
scrolling to the end — which is where it matters most, on long forms. Whether
to use it is the screen's decision.

## IuxVerticalSeparator

**Purpose.** The line between two columns of one block — the counterpart to
`IuxListSeparator`, which runs the other way, between rows. Neither package
had one until a summary card needed to separate three peer figures — nights,
days, rainfall — side by side.

**Use when** one block is read in columns and the columns are peers: a summary
card whose figures belong to the same subject, a dense row whose facts
describe the same item.

**Do not use when** the two sides are not peers. A line implies they are the
same kind of thing, so a rule between a label and its value is wrong for the
reason a rule between two comparable columns is right — it says "these two
readings are one kind of thing", which is true of two columns and false of a
label and what it labels. Do not use it to separate rows; that is
`IuxListSeparator`, and it runs the other way. Do not use it to delimit a
control: it is drawn in the subtle border role, exempt from the 3:1 contrast
floor, and the exemption does not hold where a line marks where a target
begins.

**API**

```dart
const IuxVerticalSeparator()
```

No parameters. It takes no intent, no colour and no width: everything it
draws is resolved from the ambient `IuxSemanticColors` and `IuxGeometryTheme`,
which is what lets it stay correct across every theme without a caller
deciding anything.

**States.** One, at rest. It receives no input and holds no interaction state,
so there is no focused, pressed or disabled form of it.

**Accessibility.** It announces nothing to a screen reader. That is correct
here, not merely permitted: the line repeats a boundary the column spacing
already expresses, so a reader who cannot see it loses no information by not
hearing it either. A vertical rule between three columns would otherwise cost
a screen-reader user two extra stops on every visit to say nothing an
`Expanded` gap did not already say through position. The moment a separator
is the *only* thing distinguishing two readings — no label, no spacing, only
the rule — that argument stops holding, and the fix is to give the columns
their own accessible names, not to make the line louder.

**On text growth.** It has no height of its own; it stretches to whatever
height its parent resolves to. Inside an `IntrinsicHeight` above a `Row`, that
height is recomputed from the tallest column, so when a column's text wraps
onto a second or third line at a larger text scale, the row grows taller and
the separator grows with it — it never stays the height it was drawn at while
the columns beside it grow past it. What it does not do is decide, on its
own, that the columns no longer belong side by side. It has no notion of its
siblings, so the decision to fold three columns into a stack at some width or
text scale belongs to the caller, which then reaches for `IuxListSeparator`
and a `Column` instead of asking this widget to do something it cannot: judge
whether its neighbours still fit.

**Themes.** Drawn in the subtle border role, the one role exempt from the 3:1
contrast minimum — correct here because the separator is decorative, not a
target boundary. High contrast thickens `IuxGeometryTheme.borderWidth` rather
than recolouring the role: a line that changed hue under high contrast would
start competing with focus for the same meaning, which is the rule
`IuxListSeparator` already records and this primitive inherits rather than
re-deriving.

**Anti-patterns.** A rule between a label and its value — the two are not
peers, and the line claims they are. Reaching for it to delimit a tappable
region, where the subtle role's contrast exemption does not apply.

**Limits.** It has no intrinsic height. In a `Row` whose height comes from its
tallest child, it collapses to zero unless the row stretches or an
`IntrinsicHeight` sits above it. IUX cannot fix this from inside the widget: a
separator that measured its siblings would have to lay them out twice, and
`IntrinsicHeight` is the framework's name for paying that cost deliberately.

## Limits

- No custom scroll engine. Flutter's primitives are used directly.
- Nested scrolling is not modelled; a page inside a page is a design problem.
- The character-to-pixel conversion assumes a proportional Latin face and is
  deliberately generous. It will be wrong for CJK and for monospace.
- Form fields, navigation and app bars are later missions.
- `IuxScreen` owns the top chrome and the content. The bottom chrome belongs to
  `IuxAdaptiveNavigation`, which bounds it by the window rather than by what the
  content can spare — so on a 320x640 window at 300% text the navigation still
  takes 57% of the screen before the screen gets a say.

## Evidence level

Standard for the target spacing floor and for text-scale resilience. Strong
guidance for the reading-width range. Context dependent for the primitive
decomposition. Hypothesis for the character counts.

## Sources

- WCAG 2.2 — SC 2.5.8 Target Size (Minimum), SC 1.4.4 Resize Text,
  SC 1.4.10 Reflow.
- Android — window size classes.
