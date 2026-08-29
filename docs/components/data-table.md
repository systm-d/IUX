# Data table

## Purpose

`IuxDataTable` shows values related across two dimensions, with the row and
column of every cell exposed to assistive technology.

**It exists for one clause.** EN 301 549 V3.2.1 clause 11.5.2.6 requires the row
and column of each cell in a data table — including headers — to be
programmatically determinable. Nothing in this library exercised it, and the
reason it went unnoticed is the reason it matters: a table assembled from a
`Column` of `Row`s **renders identically** and announces a flat run of strings
with no structure at all. RAAM tests the same ground as its criteria 4.1 to 4.5,
all level A, and `IUX-EN301549-001` recorded the gap.

## Use when

- The values are genuinely two-dimensional: each cell means something because of
  both the row and the column it is in.
- The table has a title you can write. If you cannot say what was tabulated, the
  data is probably a list.

## Do not use when

- **For layout.** A table is a claim about relationships. Using one to place
  things side by side tells a screen-reader user to look for a relationship that
  is not there.
- **For a list of things.** One value per item is `IuxListGroup`.
- **For many columns.** The columns share the width and wrap; past four or five
  on a phone every column becomes a stack of single words. There is no
  assertion, because the right number depends on the words.
- **When it might be empty.** `IuxEmptyState`, and say why there is no data. A
  table with a heading and no rows announces a structure and then holds nothing
  — which is why an empty `rows` is refused.

## API

```dart
IuxDataTable<Delivery>(
  title: l10n.deliveriesThisWeek,
  description: l10n.parcelsByWeekday,      // optional — RAAM's *résumé*
  columns: <IuxTableColumn<Delivery>>[
    IuxTableColumn<Delivery>(label: l10n.day, value: (Delivery d) => d.day),
    IuxTableColumn<Delivery>(label: l10n.parcels, value: (Delivery d) => d.parcels),
  ],
  rows: week,
)
```

A column reads a `String`, not a widget. **A cell that can hold anything is a
cell that cannot be announced**, and the announcement is the reason this
component exists rather than a `Column` of `Row`s.

## What it announces

A `table` node named by `title`, containing `row` nodes, each containing
`columnHeader` or `cell` nodes.

Flutter **enforces that nesting**: a table's children must every one carry the
row role, a row's parent must be a table, and a row's children must be cells or
column headers. It throws on the first frame when the shape is broken rather
than degrading quietly. That is why the structure is built here and not left to
callers, and why the tests assert the roles rather than the pixels.

### The row-header half of 11.5.2.6 cannot be satisfied

`SemanticsRole` has `columnHeader` and **no `rowHeader`**. A table whose first
column names its rows announces those cells as ordinary cells, so the half of
the clause that reads *"headers of the row"* has no expression on this platform.

The limitation is Flutter's. It is recorded rather than worked around: a
`columnHeader` used in the first column would be a lie about which axis the
header belongs to, and a lie in the semantics tree is worse than a gap.

## Why it does not scroll sideways

The columns share the available width and their text wraps.

WCAG 2.2 SC 1.4.10 exempts tables from the reflow requirement, so horizontal
scrolling would have been **permitted**. It is not taken, because permitted is
not usable: a table that scrolls sideways puts the row's own label out of sight
exactly when the reader needs it to interpret the cell they are looking at, and
at 200% text it does so immediately.

The cost is the column cap under *do not use when*, and it is the honest trade.

## States

| State | Behaviour |
| --- | --- |
| default | the header row, then the data rows |
| empty | refused at construction — use `IuxEmptyState` |
| long text | wraps; the row grows |

There is no sorting, no selection, no pagination and no row actions. Each is a
component's worth of accessibility work on its own, and a table that grew them
one at a time would arrive at each without a decision having been taken.

## Limits

- **No row headers**, as above. This is the sharpest one, because it is half of
  the clause the component was built for.
- **No sorting or selection.** Adding either changes what every cell announces.
- **The column cap is documentation, not an assertion.** The right number
  depends on the words, and a component that refused six short columns would be
  wrong more often than it was right.
- **Nothing checks that the description says more than the title.** RAAM 4.2
  asks that it be *relevant*, which no test can decide.
- **No device has heard this.** `IUX-MANUAL-001` applies: the structure above is
  what the semantics tree says, not what TalkBack reads out. For a table that
  distinction is wider than usual, because table navigation is a mode a screen
  reader enters and this library has never watched it happen.

## Evidence level

Standard for the structure — clause 11.5.2.6 is quoted and the roles are
asserted. Context dependent for the layout decisions.

## Sources

- **EN 301 549 V3.2.1** — clause 11.5.2.6, read; see `IUX-EN301549-001`.
- **RAAM 1.1** — criteria 4.1 to 4.5, level A.
- WCAG 2.2 — SC 1.3.1, SC 1.4.10.
- `IUX-TABLE-001`.

## A note on the parameter name

RAAM calls this a table's *résumé*, and the obvious parameter name was
`summary`. It is `description` instead: `summary` already means three unrelated
things in this library — a collapsed section's headline, a validation-error
label set, and a search-result count — and `api_consistency_test.dart` exists to
refuse the fourth. It refused this one, before review did.
