# ADR-0011: Icons on tabs, for a measured quantity

- Status: accepted
- Date: 2026-09-02

This record has no mission number. It came from an application building on IUX
rather than from a mission of the framework, and inventing an `IUX-0NN` that no
`docs/MISSION_*` answers would be a citation that promises a document and
delivers none. `ADR-0001` carries the same header without one.

## Context

`IuxTabs` refuses glyphs today, and says so in its own dartdoc, on the `tabs`
field: there is no `IuxTab` value type "because it would carry exactly this
field, no glyph because a glyph beside a word doubles the height of the strip at
the top of a phone screen and adds nothing the word does not already say".
`docs/components/tabs.md` §"A tab is a word" makes the same argument at length,
and its *Limits* section records the cost: adding a glyph later "means changing
`List<String>` to a value type — a breaking change".

**That argument is not being overturned. It is being given its boundary.** It
was written about the case it was written for, and that case is still the
common one: "All / Unread / Archived" over a list of messages, where the word is
the whole meaning and a glyph beside it would be an illustration of the word. An
envelope next to "Unread" tells a reader nothing they did not have, and costs
the strip room to say it. For a tab whose word suffices — "Details",
"History" — the answer stays no.

A pilot application then produced a strip the argument does not cover: a choice
between **Températures** and **Précipitations** over the same chart. A
thermometer and a drop are not illustrations of those words. They are the
conventional marks of the quantities themselves, in the interface category —
weather — that established them; a reader who has used any forecast application
identifies the row before reading it, and the word confirms what the glyph
already said rather than the other way round. That is redundancy that is read
without being read, which is a different thing from decoration.

`docs/components/component-standard.md` §14 requires an ADR for an
architectural decision, and the root `COMPONENT_STANDARD.md` §20 requires that
anything that moves the standard be motivated, recorded, coherent with the rest,
and exceptional. Reversing a refusal a component argued for in its own
documentation is exactly that, so it is written here and bounded here rather
than adjusted in a dartdoc.

## Decision

**A tab strip may carry one icon per tab, for all its tabs or for none, when
each tab names a measured quantity that has a conventional glyph.**

`IuxTabs` gains `List<IconData>? icons`. Null is the strip exactly as it is
today, and stays the default and the recommendation. A non-null list must be
exactly as long as `tabs`, asserted.

Four bounds are part of the decision, not commentary on it:

1. **All or none.** There is no per-tab icon, so a strip in which some tabs are
   marked and others are not cannot be built.
2. **The icon never replaces the word.** `tabs` stays a `List<String>` whose
   entries stay required, non-empty and distinct. No arrangement of parameters
   yields an unlabelled tab.
3. **Beside, not above.** The glyph is drawn before the label, in reading order,
   on the same line, inside the same target, sized from the type ramp so it
   grows with the text. A stacked glyph-over-word arrangement is not what is
   being allowed; that is `IuxBottomNavigation`, and the two components do not
   converge here.
4. **A measured quantity, not a category.** The case this opens is a selector
   between quantities of the same thing, where the glyph is the quantity's own
   conventional mark. A strip of views, states, filters or sections is not it,
   and `docs/components/tabs.md` keeps arguing against a glyph there.

The fourth bound is judgement and no test can hold it, which is why it is
written into the decision instead of only into the component document. A record
that opens a door without saying how far ends up having opened it entirely.

The icon is excluded from the semantic tree. The label is unchanged, required,
and remains the whole accessible name.

## Why all or none

A strip where two tabs of three carry an icon is a strip where the icon means
"this one is different". The reader looks for what distinguishes the marked tabs
and finds nothing, because nothing does — the third quantity simply had no
conventional glyph to hand. All-or-none makes that state unreachable rather than
discouraged, which is the technique `IuxStatus` already uses for the same class
of failure: there is no constructor without a label, so the labelless status
cannot be built rather than merely being advised against.

## Why the icon never replaces the word

Because the strip would then be a row of unlabelled targets, and the argument
`IuxStatusIndicator` makes about a coloured dot applies to a glyph unchanged: it
says nothing to a screen reader, nothing on a monochrome or sun-washed screen,
and nothing to a reader who does not share the convention.
`docs/accessibility/color-and-non-color-signals.md` states the rule as "an icon
without a label is not sufficient when the icon is ambiguous", and whether a
glyph is ambiguous is not knowable from inside the framework. The rule that
colour never carries meaning alone is the same rule; a glyph is a non-colour
signal that can fail in the same way, so it is held to the same condition.

An icon-only strip is also the version that would genuinely save vertical space,
which is worth naming: the thing this record refuses is the thing that would
have paid for itself. It is refused anyway.

## Alternatives considered

**An `IuxTab` value type carrying a label and an optional icon.** Rejected. An
optional icon per tab is exactly the mixed strip bound 1 forbids, and a value
type invites it by construction — the field would be nullable in the type, so
every caller gets to leave it null on three tabs out of five. It is also the
breaking change `docs/components/tabs.md` *Limits* assumed was the only route to
a glyph, and it is not: a parallel list bought the same capability without
touching an existing call site.

**A separate `IuxQuantityTabs` component.** `docs/components/component-standard.md`
§8 says a component that needs a new visual mode is usually two components, so
this is the alternative the standard points at first, and it is rejected on the
narrower ground the same section gives. §8's target is configuration
accumulating — the fourteenth enum value keeping one class alive. Here the
second component would share the constructor, the tab and tabBar roles, the
target floor, the wrap behaviour, the mark and every accessibility guarantee
with `IuxTabs`, and differ in whether one list is null. Two components that
differ by one optional parameter are one component and a maintenance obligation
to keep them identical.

**Leaving the application to draw its own strip.** Rejected. It would have to
reimplement `SemanticsRole.tabBar` and the per-tab `tab` role with its selected
state, the target floor, the wrap, and the three-signal mark for the current
tab. `_IuxTab` is private precisely because a hand-assembled strip drops one of
them, and it is never the visible one.

**Saying no and letting the pilot use two words.** Considered seriously, since
it costs the framework nothing. Rejected because the words are already there —
this record does not remove them — and the glyph is doing work no wording does:
it is recognised before it is read, which is what a selector above a chart is
for.

## Consequences

- `docs/components/tabs.md` §"A tab is a word" is amended by this record and
  must point at it. The section is not deleted: its argument still decides the
  default, and bound 4 is what it now says about the exception. Its *Limits*
  entry claiming a glyph requires a value type and a breaking change is wrong as
  written and must be corrected.
- The `tabs` field dartdoc must stop saying "no glyph" flatly and say what it
  now refuses instead: a glyph on some tabs and not others, and a glyph without
  its word.
- The five-tab cap is unchanged. The measurement recorded in
  `docs/components/tabs.md` that justified it — five one-word tabs on a
  320-pixel screen at 200% text, in the widget-test font — was taken without
  icons and does not carry over. It is to be retaken with icons and recorded
  there, not assumed to still hold.
- The strip does not grow a second line to hold the glyph, because bound 3
  forbids the arrangement that would. What it spends is horizontal room, which
  it already knows how to spend: it wraps, and it wrapped before this record at
  large text sizes.
- A caller can build a strip whose icons are all `Icons.circle`. Nothing refuses
  it and nothing should: a framework that policed glyph choice would have to
  know what the application means by each tab, and it does not.
- `IuxBottomNavigation` is unaffected. It carries a glyph over a name because a
  destination is a fixed column whose position users memorise; nothing here
  changes that, and this record is not a step towards making the two components
  the same.

## Risks

- **The fourth bound is unenforceable.** Nothing can tell a thermometer over a
  chart from a random glyph over a list of views. The framework can only make
  the two *hard* failures unreachable — the mixed strip and the wordless tab —
  and argue for the rest. This record is a review criterion, not a test.
- **The exception is the kind that widens.** The next application will have a
  strip that is nearly a quantity selector, and the argument for it will start
  with this file. The answer is that the bounds are the record, not the
  permission: an ADR that opens a case opens the case it describes.
- **The wrap point moves and is not yet known.** Until the measurement above is
  retaken, an application putting icons on five tabs is spending an unmeasured
  amount of horizontal room. Two or three tabs remains the choice that survives
  enlarged text on a phone, with icons more than without.
