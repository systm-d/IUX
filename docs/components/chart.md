# IuxLineChart, IuxBarChart and IuxSparkline

## Purpose

Three ways of showing a quantity that changes, and one rule they share: the
picture is never the only copy of what it says.

| Component | Answers |
| --- | --- |
| `IuxLineChart` | how a run of readings moved, and where it sits against a reference range |
| `IuxBarChart` | which of these is largest, and by how much |
| `IuxSparkline` | up or down |

## Use when

- **`IuxLineChart`** — the reader has to take values off the picture, compare
  two runs, or see one against an envelope. It is the only one of the three
  with an axis, and therefore the only one that can be read from.
- **`IuxBarChart`** — a ranking, or quantities belonging to categories rather
  than to positions on a scale.
- **`IuxSparkline`** — the shape is the message and the numbers are already
  beside it.

## Do not use when

- **You want vertical columns.** `IuxBarChart` is horizontal and has no
  orientation parameter. Twelve columns with their labels underneath collide at
  200% text, and the usual fixes — rotating or truncating the labels — break
  the chart for exactly the reader who enlarged the text. A caller who wants
  columns wants a different component, and IUX does not have one.
- **You want to compare two sparklines.** Each is scaled to its own readings.
  Two series on one scale is two series on one `IuxLineChart`.
- **You want a line through categories.** Joining shops or departments with a
  line asserts a continuity that does not exist.
- **You want interaction.** None of the three has hover, tooltips or point
  selection. See *Limits*.
- **You have no data.** A chart of nothing draws an empty grid and explains
  nothing. That is `IuxEmptyState`, which can say why there is nothing.

## API

### `IuxLineChart`

| Parameter | Type | |
| --- | --- | --- |
| `series` | `List<IuxChartSeries>` | required, at most three |
| `horizontalAxis` | `IuxChartAxis` | required |
| `verticalAxis` | `IuxChartAxis` | required |
| `semanticsSummary` | `String` | required |
| `band` | `IuxChartBand?` | |
| `stops` | `List<IuxChartStop>` | defaults to none |

### `IuxBarChart`

| Parameter | Type | |
| --- | --- | --- |
| `bars` | `List<IuxChartBar>` | required |
| `semanticsSummary` | `String` | required |

### `IuxSparkline`

| Parameter | Type | |
| --- | --- | --- |
| `points` | `List<IuxChartPoint>` | required |
| `semanticsSummary` | `String` | required |

## Why `semanticsSummary` is required everywhere

A chart with no text alternative is not a chart that is hard to use without
sight. It is a chart that does not exist without sight, and the gap is invisible
at review time because the picture looks finished. Making the sentence a
required parameter is the only version of this rule that cannot be forgotten:
the code does not compile without it.

IUX never composes it. "Warmer than usual" is a claim about the data, and only
the caller knows both the data and the language.

## Why two series may not share a stroke pattern

`docs/accessibility/color-and-non-color-signals.md` is absolute: no important
state may be carried by colour alone. For a line chart, the state carried by
colour is *which line is which*, and the complement is the stroke pattern.

There are three patterns, so a chart carries at most three series. That cap is
a benefit rather than a shortfall — a five-line chart is unreadable before it is
inaccessible — and it is asserted in debug rather than documented and hoped for.

The legend shows the pattern, not only the colour, which is what makes the rule
visible instead of theoretical.

## Why the bounds are the caller's

`IuxChartAxis` carries `min` and `max`. IUX never rounds them to pleasant
numbers, because two charts on one screen with two silently different scales
are not comparable and nothing on either one says so. Stating the range is also
what lets several years be drawn against each other.

## States

| State | What happens |
| --- | --- |
| default | the chart |
| a missing reading | the line breaks; a lone reading is drawn as a dot |
| an empty band stretch | the envelope stops and restarts |
| no data at all | refused in debug — use `IuxEmptyState` |
| focused, pressed, disabled | not applicable, see *Limits* |

## Motion

One animation: the chart draws itself in, under `IuxMotionRole.emphasis`.

A finished chart says exactly what a chart being drawn says, so the movement
carries no information and is removed at the **first** request for less motion —
not only when motion is switched off entirely. Classing it as an entrance would
have been more flattering and untrue. Under any reduction the first frame is
the finished chart, and the animator is absent rather than set to zero.

`IuxBarChart` has no draw-in under any profile: bars that grew would move the
value labels beside them, and a number sliding while somebody reads it is worse
than a bar that simply appears.

## Accessibility

- **The summary** is the alternative, and it is required.
- **Stops** (`IuxLineChart` only) add places a screen reader can stand, laid
  over the stretch they describe so exploring by touch lands on the part being
  spoken about. A stop is deliberately not a datum: a year profile paints 365
  points and declares twelve stops, and making them one type would force a
  choice between a chart too coarse to read and an exploration 365 swipes long.
- **Bar rows** are one stop each, carrying the name and the value as one
  utterance rather than two unrelated fragments.
- **Text is never painted.** Axis labels, legend entries and bar labels are
  ordinary `Text` widgets, so text scaling, right-to-left and font fallback work
  without special handling.
- **The axis runs in the reading direction.** In a right-to-left interface the
  first position is at the right edge, so the curve agrees with the labels
  beside it, and a bar fills from the side the reader starts at.
- **The band is outlined under every profile**, not only under high contrast: a
  fill difference is what a high-contrast palette flattens, and a branch that
  exists is a branch that can be got wrong.

## Anti-patterns

```dart
// Wrong: the summary restates the widget instead of the data.
IuxLineChart(semanticsSummary: 'A chart of temperatures', ...)

// Right: the sentence the picture is for.
IuxLineChart(semanticsSummary: l10n.warmerThanNormalEveryMonthSinceMay, ...)
```

```dart
// Wrong: a gap filled with a zero. A freezing day appears in July and
// nothing says it was invented.
IuxChartPoint(position: day, value: reading ?? 0)

// Right.
IuxChartPoint(position: day, value: reading)
```

```dart
// Wrong: one stop per daily reading. 365 swipes is not an exploration.
stops: <IuxChartStop>[for (final d in days) IuxChartStop(...)]

// Right: one per month.
stops: <IuxChartStop>[for (final m in months) IuxChartStop(...)]
```

## Testing

The charts are tested by what they paint, not by how they look. There is no
golden test, and that is the Component Standard §12 rather than an omission:
"tests assert behaviour, not pixels". A gap in a series is asserted as *two
stroked paths instead of one*, which is a claim about the component; a
screenshot would only be a claim about a font.

Two traps found while writing those tests, recorded because both pass for the
wrong reason rather than failing:

- **Dart canonicalises structurally identical `const` objects into one
  instance.** A `const`-built identity-equality test measures the compiler, and
  keeps passing if somebody later adds a deep `==`. Build both sides without
  `const`.
- **`addTearDown(handle.dispose)` does not release a `SemanticsHandle` in
  time.** The framework verifies that none survives the test *before* it runs
  the tear-downs, so the handle must be disposed inside the body.

## Limits

- **Not interactive.** No hover, no tooltip, no point selection, no zoom, no
  pan. There is therefore no focus behaviour, no keyboard behaviour and no
  target size to describe. A chart that needs those is a different component.
- **No `height` parameter.** The plot is as tall as the tokens make it, scaled
  with the text. A caller who set 40 logical pixels would get an unreadable
  chart, and the component does not offer that knob.
- **Three series maximum**, by construction. See above.
- **Bars are horizontal only**, and non-negative only. A chart of signed values
  needs a baseline in the middle of the row, which changes how every bar is
  read.
- **Mirroring in a right-to-left interface is a decision, not a standard.**
  Some publications keep time running left to right even in right-to-left
  setting. IUX mirrors, because a curve that disagreed with the axis labels
  beside it would be worse than either convention. If your locale expects
  otherwise, this is the line to argue with.
- **Value-axis labels are aligned by fraction**, so a label near an edge is
  positioned by its centre and can overhang slightly. Nothing is clipped; the
  alignment is approximate at the extremes.
- **Never validated on a device with a screen reader**, and never looked at on
  a running screen: the catalog was analysed and tested but not launched, for
  want of the Linux desktop toolchain on the machine that built this. Widget
  tests approximate TalkBack and no more — the same limit the rest of the
  package carries, with one more layer of approximation on top.

## Evidence level

Context dependent. The accessibility requirements restate obligations that are
standard; the three-pattern cap and the horizontal-only bar are IUX judgement.

## Sources

- WCAG 2.2 — SC 1.1.1 Non-text Content, 1.4.1 Use of Color, 1.4.4 Resize Text,
  1.4.11 Non-text Contrast, 2.3.3 Animation from Interactions.
- `docs/accessibility/color-and-non-color-signals.md`.
- `docs/components/component-standard.md` §5, §6, §9, §12.
