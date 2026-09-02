# ADR-0012: A dense row folds rather than overflows

- Status: accepted
- Date: 2026-09-02

No mission number, for the reason `ADR-0011` gives and `ADR-0001` set the
precedent for: this came from an application building on IUX rather than from a
mission of the framework, `docs/MISSION_*` stops at 043, and citing an
`IUX-044` that no document answers would be a reference that promises a file
and delivers none.

## Context

`IuxListItem` carries a leading widget, a title, a subtitle, a trailing value
and one trailing control. That is not a design budget, it is a **measured**
one, and the measurement is on file. Every number in this section is quoted
from `IUX-LISTITEM-TRAILING-001` — the entry in
`docs/evidence/semantic-tokens-and-accessibility.md` and the argument carried
on `_IuxListItemWithAction` — and none of it was re-taken here.

An `IuxListItem.tappable` holding an `IuxStatusIndicator` on a 320-pixel screen
came out **68 pixels over at 200% text and 214 at 300%**. Neither component
overflowed alone. On the way up, before anything was thrown, the title's box
was **75.8 pixels wide at 100%, 2.8 wide and 324 tall at 150%, and zero at
200%** — one character to a line, then no line at all, **with no exception
raised until 200%**. That row was one control and one trailing widget. It is
the shape this component was already at the edge of.

`IUX-LISTITEM-TRAILING-001` closed it at the join, with a render object that
asks the control how wide it would like to be and moves it under the row's text
when that does not fit inside the row's third. The rule the fix landed on is
the one this record generalises: *a value gives way by wrapping, a control
gives way by moving, because it cannot be re-wrapped without being destroyed.*

A pilot application now needs a row carrying more than that at once. Its
`docs/maquettes/04-palmares.png` draws a ranking row holding a rank badge, a
year, a count of rainy days, a named extreme with its own value, a total, a
qualifying pill and a chevron — seven things where the component was measured
failing with four. Read as a request, it asks for a fourth content slot.

**It is not a slot that is missing.** A fourth block on a row that was 68
pixels over at 200% is a row 68 pixels over at 150%: the slot moves the
overflow earlier without removing it, and the earlier it moves the more of the
failure happens silently, because the row's own measurement shows the damage
starting a full scale step before anything is thrown. Whatever is added has to
be able to leave the line.

`docs/components/component-standard.md` §14 requires an ADR for an
architectural decision, and `COMPONENT_STANDARD.md` §20 requires that anything
moving the standard be motivated, recorded, coherent with the rest, and
exceptional. Adding a content capability to the component the standard already
names as the densest thing an application has is exactly that.

## Decision

**A row may carry a set of detail blocks, and when they stop fitting they all
move below the row's text — never clipped, never shrunk, never truncated.**

`IuxListItem` gains a `dense` constructor taking `List<IuxRowDetail> details`.

`IuxRowDetail` is a **value type**, and it holds no widget:

- `value` — the fact the row reports, already localised, required, non-empty.
- `label` — the quantity that value measures, optional, drawn above it.
- `glyph` — an `IconData`, optional, decorative, excluded from the semantic
  tree.
- `qualifier` — an `IuxStatus`, optional, drawn below the value. See
  *Consequences* for what that type does and does not fit.

The fold is decided by measurement at layout, from the same share the trailing
control already uses: `valueFlex / (textFlex + valueFlex)`.

Four bounds are part of the decision, not commentary on it:

1. **All the details move, or none of them do.** There is no per-detail fold,
   so a row in which two details keep the line and a third has dropped below it
   cannot occur.
2. **Nothing in a detail is a widget.** `IuxRowDetail` takes strings, an
   `IconData` and an `IuxStatus`. There is no arrangement of parameters that
   puts a caller's subtree inside a detail.
3. **The dense form is tappable only.** There is no plain dense row and no
   selectable one.
4. **A detail is a fact compared down the column, not a sentence.** The value
   is what a reader reads across five rows — `36 jours`, `434 mm` — and the
   label names the quantity being compared. A dense row whose details are prose
   folds correctly and reads as a paragraph in three columns.

The first three are unreachable by construction. **The fourth is judgement, no
test can hold it, and it is written into the decision rather than only into
`docs/components/list-items.md` for that reason.** A suite that checks the
arity, the all-or-nothing fold and the absence of widgets will be green on a
dense row full of sentences, and a green suite is read as saying more than it
checked. It does not check bound 4 and it cannot.

## Why the fold and not the slot

Because a slot has to be given a width, and a width is a cap, and
`IUX-LISTITEM-TRAILING-001` measured what capping does. Its numbers again, and
again quoted rather than re-taken: on a 286-pixel row the third is **86
pixels**; an `IuxStatusIndicator` reading one word has minimum intrinsic width
equal to its maximum — **180.25 at 100%, 253.25 at 150%, 326.25 at 200%,
472.25 at 300%** — because a single word has no wrap point. Handed 86, the
label broke **inside the word**, one glyph to a line, and at 300% the glyph and
its gap alone (68) exceeded the 62 left for them, so the label was laid out in
a box **zero pixels wide** and painted outside it. The row went from 480 pixels
tall without the status to **924 with it: 444 pixels for one word.**

A cap answers *how much may you have* and never asks *is that enough to be
read*. The failure moved onto the other axis; it did not go away. A block that
cannot be re-wrapped without being destroyed has to give way by **moving**.

## Why a value type and not a widget in each detail

Two reasons, and the second is the one that is not obvious.

**A widget slot lets a control into a row that is itself one control.**
`IuxListItem` runs a debug-only subtree check on `leading` precisely because of
this, and a screen reader then announces a button inside a button. Strings, an
`IconData` and an `IuxStatus` cannot do that.

**And a widget cannot be measured tightly enough to decide the fold well.**
`IUX-LISTITEM-TRAILING-001` had to settle for asking the control what it *wants*
rather than what it *minimally needs*, and `docs/components/list-items.md`
*Limits* records the cost: a multi-word control that could have wrapped inside
its third is moved below anyway. The reason is that `getMinIntrinsicWidth`
**throws** for any subtree holding a `LayoutBuilder`, and both `IuxTooltip` and
`IuxAppBar` hold one — so a row that asked a caller's widget for its minimum
could crash on a legal child. Strings have no such hazard: the row builds the
text itself, so it knows the minimum without asking a stranger for it. The
value type buys a tighter fold decision than a widget slot could ever offer,
which is a gain and not only a restriction.

## Why all the details move, or none

A row where the first two details keep the line and the third drops below it is
a row in steps, and a reader scanning a list has no way to know that the block
underneath belongs to the row above rather than to the row below. The rank
badge and the chevron are the only things marking a row's extent, and a
staggered row breaks both.

There is a second reason, and it is about this file rather than about the user:
all-or-nothing is statable in one sentence, and a per-detail fold is not — it
is a search order, and a search order has cases, and cases are what a decision
record cannot bound. A rule that can be written in one sentence is a rule a
test can check and a reviewer can apply.

## Why the dense form is tappable only

A row showing five facts and doing nothing is a table row, and `IuxDataTable`
exists. A dense row that is not a target has no reason to be dense: the facts
would be better in an `IuxCard`, where they have room to be labelled properly.
A selectable dense row is worse still — it puts a checkbox, five facts and a
fold on one line and asks the user to work out which of them the tap chooses.

## Consequences

- **Arity: eight parameters, and the eleven-parameter ceiling is untouched.**
  `test/api/api_consistency_test.dart` asserts that the constructors at eleven
  or above are exactly `IuxListItem.selectable` and `IuxListItem.tappable`, so
  a third row constructor reaching eleven breaks it by name. `dense` takes
  `title`, `onActivate`, `details`, `subtitle`, `leading`, `hint`,
  `disclosure` and `focusNode`. Against `tappable` it drops four:
  `semanticLabel`, because a dense row is named by its own text and has more of
  it than any other row; `autofocus`, because a row in a list is not an entry
  point; `trailingText`, because a detail carrying only a value *is* a trailing
  text and two ways to say one thing is the defect `IUX-API-NAMING-001` already
  records against this package; and `trailingAction`, argued below. The
  constraint is real and it was met by removing, not by amending the test.
- **The details merge into the row's single semantic node**, in reading order,
  with the title and the subtitle. A dense row is one stop for a screen reader,
  not six. The glyph is excluded; the qualifier's label is not, because it is a
  word the sighted reader gets.
- **`docs/components/list-items.md` gains a fourth API section**, and its
  *Limits* entry "One trailing control, not a list" must be read against bound
  3 of this record rather than around it.
- **The qualifier's type fits in shape and not in vocabulary, and this is the
  bound that will bite first.** `IuxStatus` is the right shape — a value class,
  a required non-empty label, colour never the sole signal — but
  `IuxStatusTone` has exactly four families and they are families of *news*:
  neutral, success, warning, error. The pilot's qualifier is not news. Drawing
  "Très sec" in the red the maquette draws it in requires
  `IuxStatusTone.error`, which `iux_status_model.dart` defines as "a state that
  has stopped working and needs attention", and a dry year is not that; its own
  dartdoc warns that colouring a neutral state red "asks the user to react to
  something that needs no reaction". **This record does not add a fifth tone.**
  The pilot takes `neutral` and a grey pill, or the mismatch is the next
  decision somebody takes. Nothing tests which of those happened.
- **The measurement has not been taken, and nothing here may be read as saying
  it has.** Every number above is `IUX-LISTITEM-TRAILING-001`'s, taken on a row
  carrying a control and no details. What a row carrying two detail blocks does
  on a 320-pixel screen at 100, 150, 200 and 300% is unmeasured. `ADR-0011`
  has just recorded the same trap on the five-tab cap — a number measured
  before the change and not valid after it — and the answer is the same: it is
  to be taken, on the real chassis, and written into
  `docs/components/list-items.md`. A test harness's default width will report
  that everything fits; `IUX-LISTITEM-TRAILING-001` was found because somebody
  measured on 320.
- **No cap on the number of details**, because a cap is a number and this
  record has no measurement to put in one. The maquette carries two. Nothing
  here refuses five, and nobody knows what five does at 200%.
- **IUX still has no way to express a row of arbitrary columns**, and this
  record does not give it one. `IuxRowDetail` holds three strings' worth of
  content and one qualifier, and that is the whole vocabulary.

## Alternatives considered

**A `trailingSecondary` slot.** Rejected: it is the fourth slot on a row that
already overflowed at 200%, and it would need its own share of a width that has
none left to give.

**A `Widget` in each detail.** Rejected on both grounds in *Why a value type*:
it reopens the nested-control failure the subtree check exists to catch, and it
would force the fold to be decided from what a subtree *wants* rather than what
it needs, with the `LayoutBuilder` crash hazard attached.

**Keeping `trailingAction` on the dense form.** Rejected, and this is a
departure worth naming because it is a capability the other two interactive
rows have. The trailing control's fold and the details' fold both claim the
row's third, and the arrangement in which both have moved below the text is a
row of three stacked blocks that nothing has measured and no rule here orders.
`docs/components/list-items.md` *Limits* already says the single trailing
control "will stay one until there is a real case that a menu control cannot
serve", and the pilot's row does not present one — its chevron is `disclosure`,
which is decorative and costs no target. A dense row that genuinely needs a
control is out of scope until somebody measures the pair.

**A `note` string below the value, in addition to the qualifier.** Rejected:
the qualifier already occupies the space below the value, and two independent
blocks competing for it is a second layout question asked before the first has
been measured. If a detail needs a note and a qualifier, that is a finding, and
findings are measured before they are designed.

**Branching on the text scale.** Rejected, and the reason is already recorded
on `_IuxListItemWithAction` and on `_IuxDrawerHeader` before it: it answers a
question about the *user's* text size with a decision that depends on the
*caller's* content and on the room the row was given. The measured consequence
last time was that 86 pixels is short of 180 at *every* scale, so scale-based
branching would have left the **100%** case broken. `stacksTrailingText` is
the right mechanism for a value that wraps and the wrong one for a block that
cannot.

**Truncating a detail.** Rejected: `IuxListItem` sets no `maxLines` and no
ellipsis at any scale, and a truncated measurement — `36 jou…` — is worse than
one that moved, because a number that has lost its unit is not a shorter fact,
it is a different one.

## Risks

- **Bound 4 is unenforceable.** Nothing can tell `36 jours` from a sentence.
  The framework can make the two hard failures unreachable — the staggered row
  and the widget inside a detail — and argue for the rest. This bound is a
  review criterion, not a test, and the suite being green says nothing about
  it.
- **The fold is necessary and is not yet proven sufficient.** Folding gives the
  details the row's whole inner width rather than a third — about three times
  the **97.3 pixels** `IUX-LISTITEM-TRAILING-001` measured as the third on a
  bare 320-pixel screen. Three times more room is not unlimited room. That
  entry's 472-pixel figure at 300% was measured for a **single unwrappable
  word** and does not transport to a two-word qualifier that has a wrap point,
  so the number is not the claim; the *shape* of the risk is, and the way to
  settle it is the measurement named in *Consequences*.
- **`dense` is the constructor everyone will reach for.** It is the one that
  takes the most content, and a caller who wants three facts on a row will find
  it before finding `IuxCard` or `IuxDataTable`. Bounds 3 and 4 are what stand
  between this and `IuxListItem` becoming a table cell factory; neither is
  enforced by anything but review.
- **This record generalises a rule from one measurement.** The move-rather-than-
  shrink rule was measured for exactly one composition: a row and an
  `IuxStatusIndicator`. It is applied here to a class of blocks nobody has put
  on a row yet. That is a defensible extrapolation and it is still an
  extrapolation, and the honest place for it to be checked is the pilot's own
  screen at 320 pixels.
