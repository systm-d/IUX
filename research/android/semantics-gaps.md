# What Flutter's semantics layer can and cannot say

**Measured on Flutter 3.44.8 (stable), engine `13ffd72b2f9a`.** Everything below
is read from the SDK on disk and is reproducible with a checkout of the same
version; the file and line references are given so a reader can disagree.

This directory was named in `research/README.md` as one that would exist "when
there is something to put in it". This is that.

---

## Why this file exists

Four components were built in one batch — a select, a data table, a date field
and a slider — each against a clause of EN 301 549 that nothing in the library
exercised (`IUX-EN301549-001`). **Three of the four hit a limit in Flutter's
semantics layer rather than in IUX**, and the fourth did not.

That contrast is the finding. It was not predictable from reading the standard,
and it is not visible from any one of the four register entries, because each
records only its own gap. Collected here so the next component is designed
against what the platform can actually express.

---

## The four results

| clause | component | what the platform offers | verdict |
| --- | --- | --- | --- |
| 11.5.2.5 role/state/name/value | `IuxSelectField` | `SemanticsRole.comboBox` **declared and unusable** | worked around |
| 11.5.2.6 row, column and headers | `IuxDataTable` | `table`, `row`, `cell`, `columnHeader` — **no row header** | **half satisfiable** |
| 11.5.2.5 for a date | `IuxDateField` | `SemanticsInputType` has **no number and no date** | worked around |
| **11.5.2.7 value, minimum, maximum** | `IuxSlider` | `slider`, `value`, `minValue`, `maxValue`, `increasedValue`, `decreasedValue`, increase and decrease actions | **complete** |

---

## 1. Five roles are declared and throw when used

`packages/flutter/lib/src/semantics/semantics.dart`, lines 190–194, maps these
to `_unimplemented`:

```
SemanticsRole.dragHandle  SemanticsRole.spinButton  SemanticsRole.comboBox
SemanticsRole.tooltip     SemanticsRole.hotKey
```

`_unimplemented` returns `FlutterError('Missing checks for role …')`, which is
thrown from `SemanticsNode._addToUpdate` inside an `assert`. **It fires on the
first frame of any debug or profile build** — the only builds this library's own
assertions run in — so the failure is immediate and total rather than a silent
degradation.

Upstream tracking: **flutter/flutter#159741**, referenced in a `TODO` on line 189
of the same file.

**Consequences already met.** `comboBox` is what a select wants
(`IUX-SELECT-001`); the node is a button carrying a value and an expanded state
instead. **`spinButton` is what a numeric stepper wants, so that component is
not buildable to standard today** — this is the one that should be re-checked
before anybody starts one.

## 2. `SemanticsRole` has no row header

The enum carries 33 members and `columnHeader` is one of them. `rowHeader` does
not appear anywhere in `lib/ui/semantics.dart`.

Clause 11.5.2.6 asks for *"headers of the row and column if present"*. The
column half is expressible and asserted in `IuxDataTable`; **the row half has no
expression on this platform**. A table whose first column names its rows
announces those cells as ordinary cells.

Marking that column `columnHeader` would make a test pass and would state the
wrong axis. `IUX-TABLE-001` records why that was refused: a lie in the semantics
tree is worse than a gap, because it is the one place a user cannot check the
framework's work.

## 3. `SemanticsInputType` has six values and none is numeric

```
none  text  url  phone  search  email
```

A date field can set a numeric *keyboard* through `TextInputType`, which is a
different mechanism and reaches the IME rather than the screen reader. **The
announcement carries no type at all.** `IUX-DATE-001`.

## 4. A range is fully expressible, and it is the only one

`Semantics` accepts `slider`, `value`, `minValue`, `maxValue`, `increasedValue`,
`decreasedValue`, `onIncrease` and `onDecrease`. Clause 11.5.2.7 asks for the
current value and both ends of the range, and all three are publishable in the
caller's own units.

`IUX-SLIDER-001` is therefore the only entry in the batch whose clause is met
without a caveat about the platform.

---

## What this does not establish

- **None of it has been observed.** Every statement above is about what the
  framework *accepts* and what the semantics tree *contains*. Whether TalkBack
  speaks any of it, and how, is `IUX-MANUAL-001` — still open, and the reason
  this file is in `research/` rather than being quoted as conformance.
- **The `_unimplemented` list is a moving target.** It is tied to an open
  upstream issue and will shrink. The version stamp at the top is what makes
  this file falsifiable.
- **Nothing here was reported upstream by this project.** The gaps are recorded
  as constraints we met, not as bugs we filed.
