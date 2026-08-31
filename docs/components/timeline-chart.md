# Timeline chart

## Purpose

`IuxTimelineChart` lays stretches of time on a shared axis, one row per subject.

**The chart family answers "how much"; this answers "when, and for how long".**
`IuxBarChart`, `IuxLineChart` and `IuxSparkline` all measure a magnitude.
Nothing measured a duration until this, and the gap was reported by an
integrator who had already built the view by hand — `systm-d/IUX#51`.

Their sentence is the best statement of why it exists: a list saying *"daily
rest short by one hour"* is arithmetic, whereas a row whose rest band is visibly
thinner than the one above it is the same fact understood without doing any.

## Use when

- The subject is *when* something happened and *for how long*.
- There is more than one row, and comparing them down the column is the point.

## Do not use when

- **You want a magnitude.** `IuxBarChart`.
- **You have one row.** A single span is a sentence, and a sentence is cheaper
  to read than a chart.
- **The rows are not on the same axis.** Rows drawn against different ranges
  cannot be compared down the column, which is the only reason to stack them.
- **You have no rows.** `IuxEmptyState`, which can say why.

## The drawing is not the hard part

The reporter's own estimate for the visual was *"a `Row` of `Expanded` flex
weights, about forty lines"*. Two things are hard, and both are in this
component's contract rather than in its advice.

### 1. The bands are made disjoint before they are drawn

The sets an application holds **do** overlap — somebody can be on call during
their working hours. `resolveSpans` sweeps the axis boundary by boundary against
a precedence order and returns disjoint bands.

Getting this wrong produces a chart that **renders, looks plausible, and states
something untrue**. That is the failure a charting component should prevent
rather than pass on, and it is the reason this is a component and not a
paragraph in the chart documentation.

`resolveSpans` is exported and pure, so a caller can test their own precedence
against it.

Precedence is the **order of the list**, first winning. Not a number on each
kind: a number invites two kinds to share one, and there is no honest answer to
a tie — so the constructor refuses a kind that appears twice.

A stretch nothing covers stays a gap. Inventing an "unallocated" band would be
the component asserting something the caller never said.

### 2. `describeRow` receives the resolved bands

```dart
describeRow: (IuxTimelineRow row, List<IuxResolvedSpan> bands) => …
```

**This is the guarantee worth having.** The callback is handed exactly what was
drawn, so the sentence a screen reader hears cannot describe a different
arrangement from the one on screen.

The framework does the arithmetic, which it can verify. The caller writes the
sentence, which it cannot: composing *"Monday: work from 09:00 to 17:00"* here
would be the framework writing in a language it does not know it is using, which
is what `no_composed_strings_test.dart` refuses everywhere else.

## Four kinds, two colours

The chart palette carries `primaryStroke` and `secondaryStroke`, deliberately —
*"a chart in which four things all claim different weight has no subject"*. The
reported case needs four kinds.

Adding a categorical palette would have meant proving four fills distinguishable
across four theme profiles **and** under dichromacy. `research/perception/`
exists to measure exactly that and has not.

So the kinds are told apart by **fill texture** and colour assists:

| texture | reads as |
| --- | --- |
| `solid` | the subject of the row |
| `hatched` | filled at a glance, distinguishable close up |
| `dotted` | context rather than subject |
| `open` | absence |

This is `IUX-GLYPH-SILHOUETTE-001`'s argument applied to an area instead of a
glyph: where the colour channel is weakest, the shape channel carries. One
function paints both the legend swatch and the band, so a kind cannot be drawn
one way in the key and another on the chart.

Every kind is **spelled out in the legend** beside its own swatch. A legend that
shows textures and expects the reader to match them is the failure SC 1.4.1
names.

## What it announces

- The chart is a container, headed by its title.
- **One node per row**, carrying the caller's sentence. The bands underneath are
  excluded: forty nodes reading "band" is a worse way to hear the same thing.
- The swatches are excluded; the word beside each already says what it is.

## Limits

- **Only the ends of the axis are labelled.** Intermediate ticks collide at 200%
  text on a row this short. The detail is in the row's announcement — which
  means a sighted reader who cannot judge a proportion by eye is **worse served
  than a screen-reader user here**. That is an inversion of the usual shape and
  a real cost.
- **Nothing checks that a description matches its bands.** The callback gets the
  right data; a caller can still return a constant. Non-empty is all that can be
  required.
- **The textures are unmeasured.** That the four are distinguishable at a band's
  height, at 200% text and in high contrast is an argument from the glyph work,
  not a measurement of these four fills.
- **`IUX-MANUAL-001`, and harder than usual.** This component's whole value is a
  comparison *down a column* — one row's band against the row above it. A
  semantics tree cannot hold that claim at all, and no test here asserts it.

## Evidence level

Context dependent. The disjointness guarantee is measured; the choice of
channel follows `IUX-GLYPH-SILHOUETTE-001`, and the textures themselves are not
measured.

## Sources

- systm-d/IUX#51.
- WCAG 2.2 — SC 1.3.1, SC 1.4.1.
- `IUX-TIMELINE-001`, `IUX-GLYPH-SILHOUETTE-001`.
