# ADR-0015: The sign is not the meaning

- Status: accepted
- Date: 2026-09-02

No mission number, for the reason `ADR-0011` gives and `ADR-0001` set the
precedent for: this came from an application building on IUX rather than from a
mission of the framework, `docs/MISSION_*` stops at 043, and citing an
`IUX-044` that no document answers would be a reference that promises a file
and delivers none.

## Context

`ADR-0013` shipped this morning. It gave a compared reading its own axis —
`IuxValueDirection { above, at, below }` — with its own colour roles, and it
argued the axis correctly: a reading is not news, a direction is arithmetic, and
a framework that decided whether a dry summer was bad news would be shipping a
judgement as a colour. None of that is retracted here.

What it also did, without arguing it, is decide **which hue each side of the
reference takes**. `comparison.above` is the warm end of the palette in all four
mappings and `comparison.below` is the cool end. That is a diverging scale, and
a diverging scale assumes the two sides of a reference are two opposed senses.

The pilot's own debrief for its `Saisons` screen states the counter-example, and
it states it as a requirement:

> **Il faut séparer le signe mathématique de la signification climatique.**

| Quantity | Deviation | Word | Hue |
| --- | --- | --- | --- |
| temperature | above | plus chaud | warm `#E74C3C` |
| temperature | below | plus froid | cool `#2E77FF` |
| rainfall | above | plus humide | cool `#2E77FF` |
| rainfall | below | plus sec | amber `#F59E0B` |
| either | ≈ zero | proche de la normale | neutral `#6B7288` |

Two of those readings are above their reference and two below, and the hues
cross the axis rather than following it: *wetter* and *colder* are one hue on
opposite sides, *warmer* and *drier* are two hues on opposite sides. The
debrief writes the rule out: "à éviter absolument : positif = rouge, négatif =
bleu. Cette logique vaut éventuellement pour la température et devient fausse
pour les précipitations."

And there is a harder consequence than a mis-mapping. The axis has **two**
non-neutral ends and this screen needs **three** hues. `ADR-0013`'s own
*What the maquette asked for and did not get* read the earlier maquette,
noticed the colour was tracking the quantity rather than the side, and
concluded that applying the record "gives `+51 mm` the **above** appearance,
not the maquette's blue… a framework that shipped hot-versus-cold would be
shipping meteorology." The observation was right and the conclusion did not
follow: the framework was not being asked for meteorology, it was being asked
to stop supplying it. **"Plus sec" had no colour at all**, because the axis had
already spent both of its ends on the sign.

`ADR-0013` also gave the pill an arrow, on an argument this record has to
answer rather than ignore: the reading beside it *usually* carries a sign, and
usually is not a guarantee the framework can make, because
`IuxValue.above('2.1 °C', …)` compiles and the library composes no user-facing
text. The arrow is the one signal it could draw itself.

The same debrief rejects that arrow, and on grounds of weight rather than of
principle — "éviter une grosse capsule bordée de rouge avec une flèche",
preferring "une petite capsule légèrement teintée, sans flèche et sans bordure
forte" — while adding a second requirement that turns out to answer the arrow's
argument better than the arrow did: **"un écart n'est jamais montré seul.
Toujours le mot qui l'interprète."**

`docs/components/component-standard.md` §14 requires an ADR for an
architectural decision, and `COMPONENT_STANDARD.md` §20 requires that anything
moving the standard be motivated, recorded, coherent with the rest, and
exceptional. Restructuring a semantic colour group two days after it shipped is
exactly that.

## Decision

**The direction says which side. The caller says which hue. The word says what
it means, and it cannot be omitted.**

Four things change:

- `IuxValue` gains **`meaning`**, a required non-empty string that may not
  equal the reading, drawn under the capsule by `IuxValueIndicator`.
- `IuxValue` gains **`accent`**, an `IuxValueAccent` — `one`, `two`, `three`,
  `four` — required on `above` and `below` and **absent from `at`**.
- `IuxSemanticColors.comparison` becomes an `IuxComparisonColorSet` of
  `neutral`, `one`, `two`, `three`, `four`, and `IuxComparisonRoleColors`
  drops `mark` and `border` and keeps `content` and `surface`.
- `IuxValueIndicator` draws a tinted capsule with **no mark and no outline**,
  and the word under it. `IuxSparkline.direction` becomes `accent` for the same
  reason.

Five bounds are part of the decision, not commentary on it:

1. **`IuxValueDirection` stays at three and stays arithmetic.** It selects no
   colour and no glyph. Everything `ADR-0013` argued about why a reading is not
   news still holds; what is removed is the second, unargued claim about which
   side is which colour.
2. **The accent has no meaning and no order.** `one` is not first among equals
   and nothing about its name means warmer, worse or larger. This is the
   vocabulary shape `ADR-0014` established for `IuxAvatarTone`, taken here for
   the same reason and by the same argument.
3. **`at` takes no accent.** A reading level with its reference has nothing to
   interpret, so there is no hue to choose and no way to choose one. This is
   the one place the arithmetic still decides a colour, and it decides the
   absence of one.
4. **`meaning` is required, non-empty, and never equal to the reading.** A
   deviation shown on its own leaves its interpretation to the hue.
5. **An accent is a hue the caller assigned, not a claim the framework makes.**
   Mapping `one` to *warmer* in one screen and to *over budget* in another is
   legal and correct. Mapping it to *warmer* on one screen and *colder* on the
   next is a defect no type can catch.

The first four are unreachable by construction. **The fifth is judgement, no
test can hold it, and it is written into the decision rather than only into
`docs/components/badges-and-chips.md` for that reason** — the same shape
`ADR-0011` bound 4, `ADR-0012` bound 4 and `ADR-0013` bound 4 already have.

## Why the word replaces the arrow rather than joining it

`ADR-0013`'s bound 2 — *the mark is never optional, and never replaces the
reading* — existed to close one hole: a caller who formats without a sign
leaves the pill separated from its opposite by hue alone. The hole is real. The
arrow was the wrong plug, and this record can say why in three lines:

- **The arrow answers the wrong question.** It says *which side*. On this
  screen, which side is not what the reader needs — `+51 mm` and `−42 mm` are
  both deviations of rainfall and one is wetter and one drier, which no arrow
  distinguishes.
- **The arrow does not reach a screen reader.** It is drawn and excluded from
  the semantic tree, by design, because a shape has no name. `meaning` is text.
- **The arrow costs width that could not wrap.** Measured: with the arrow, a
  dense row carrying three details at 300% text on a Pixel 7 threw, 24 px out
  of the capsule, and `docs/components/list-items.md` recorded it as a pinned
  defect. Without it, the same row is **2596.0 px tall and raises nothing**.
  The mark's own gap was the residual.

A required word closes the same hole more completely: it is refused at
construction, it survives a monochrome screen and every dichromacy, it is the
only one of the four signals a screen reader could have received, and it wraps.

**And the measurement says it is not reinforcement.** The four accents reuse the
four hue families `ADR-0014` spends on avatars, so they inherit
`IUX-PALETTE-PERCEPTION-001`'s collision rather than introducing a new one.
Taken this round, in Oklab ×100, the closest pair under deuteranopia:

| profile | closest pair | apart |
| --- | --- | --- |
| light standard | one and three | 2.2 |
| dark standard | one and four | 1.5 |
| light high contrast | one and three | 1.1 |
| dark high contrast | one and four | 0.4 |

`one` and `three` are the warm and the amber accent — which is to say **"plus
chaud" and "plus sec", the pilot's own two, in adjacent columns of the same
row.** To a reader with the most common dichromacy they are one colour. The
word is not a second channel there; it is the channel.

## Why the accents are unnamed, and why there are four

`ADR-0013` counted the palette while looking for two: IUX ships four
non-neutral hue families — `accent`, `critical`, `positive`, `caution` — and
`ADR-0014` spent all four on `avatarAccent` for the same reason a fifth was not
invented. This record spends the same four again, under a second contract, and
adds nothing to the palette's primitives.

Naming them `warm`, `cool`, `wet` and `dry` was never on the table: that is the
meteorology `ADR-0013` was right to refuse. Naming them `positive` and
`negative` would be the diverging scale under another spelling. Naming them
`one` to `four` says exactly what is true — the theme offers four
distinguishable hues, and what they mean arrives in `meaning`, in the
application's own words, where the user can read it.

**A fifth accent would be a new hue family**, which is seven primitives across
four profiles measured under three simulated dichromacies, which `ADR-0013`
calls "a mission, not a paragraph in a component's ADR". Four is what the
palette has; it is also one more than the pilot needs.

## Why the capsule is a tint, and why the outline went with the arrow

`ADR-0013` put the reading on the profile's neutral subtle surface and drew a
line around it, reasoning that "a value pill repeats down a column — five
ranking rows, four seasons, a row per month — and thirty tinted panels is a
screen of alarms". The reasoning is right and the remedy was aimed at the wrong
feature. What reads as an alarm is the **ring**, not the wash: a bordered
capsule with a glyph in it is an inline alert, and a pale field behind four
characters is a highlight.

So the capsule takes a tint of its accent's own hue where the palette has one —
the two light profiles, reusing the rung `feedback` already tints with — and
the profile's raised neutral where it does not, which is both dark profiles,
inherited from how the whole palette treats a dark ground. And there is no
outline role at all.

Measured this round with `test/support/contrast.dart`. Content on its own
capsule and the same colour on the page, in the order neutral, one, two, three,
four:

| profile | on the capsule | on the page |
| --- | --- | --- |
| light standard | 7.12, 5.58, 5.21, 5.20, 5.39 | 7.63, 6.81, 6.30, 5.94, 6.31 |
| dark standard | 5.61, 6.96, 7.59, 8.31, 7.58 | 6.62, 8.22, 8.95, 9.81, 8.95 |
| light high contrast | 12.72, 14.28, 14.53, 15.29, 14.70 | 14.78, 17.43, 17.58, 17.46, 17.21 |
| dark high contrast | 11.16, 9.78, 10.03, 10.68, 10.31 | 14.27, 12.51, 12.83, 13.65, 13.19 |

**Two grounds and one colour, deliberately.** The reading sits on the tint and
the word sits on the page, so a single `content` role is held to 4.5:1 twice.
A second role whose value is always equal to the first is a role nobody can
tell has been measured — the defect `action.tertiary` already shipped once.

The tints themselves stand **1.07 to 1.28** from the page. That is below the
3:1 SC 1.4.11 asks of a graphical object, and it is intended: the capsule's
extent carries nothing. What carries the information is text, twice, at 4.5:1.

## Consequences

- **`IuxSemanticColors` keeps eight role groups and one of them changes
  shape.** Every theme must map five comparison roles instead of three, and a
  `IuxTheme.withSemanticColors` caller building the group by hand gets a
  compile error until it does — the intended failure `ADR-0013` and `ADR-0014`
  both accepted.
- **`IuxDirectionGlyphs` is deleted.** It existed for the mark and nothing else
  read it. `IuxCategoryGlyphs` is untouched: a status still needs shapes,
  because a status has no word beside it that the caller is forced to write.
- **`IuxSparkline.direction` becomes `accent`**, reading
  `comparison.<accent>.content` — byte-identical to the `mark` role it
  replaces in all four mappings, so no shipped chart changes colour. A series
  of rainfall totals above their normal is *wetter*, and a line that read its
  hue off the side of the reference would be the same wrong claim made twice in
  one library.
- **`IuxRowDetail` gains nothing, and the maquette's third text arrives
  anyway.** Each of its columns carries a value, a deviation and a word;
  `ADR-0012` refused a `note` because "the qualifier already occupies the space
  below the value, and two independent blocks competing for it is a second
  layout question". That refusal is honoured rather than reversed: the word is
  *inside* the qualifier, so there is still one block below the value, and a
  row cannot draw a deviation without it.
- **Every value pill gets taller by a line.** On the pilot's dense row,
  measured at 411.43 px and 115% text, the word costs 27.0 px — 4.0 of gap and
  23.0 of text. The capsule's own padding gave 8.0 back and `ADR-0012`'s fold
  geometry gave 18.0 more, so the row that carries three texts a column is
  **157.0 px where the row that carried two was 156.0**.
- **The pilot's four colours are now expressible and IUX still knows no
  meteorology.** `IuxValueAccent.one` is a hue; that it means *plus chaud* is
  written in the pilot's own strings, in French, where its user reads it.
- **Nothing here measures the capsule on a narrow screen.** `ADR-0013` said the
  status indicator's 180.3 px minimum did not transport to a pill, and it does
  not transport to this one either — the composition changed again. The
  measurement is still owed, on 320 px, and `docs/components/badges-and-chips.md`
  still says so.

## Alternatives considered

**Leaving `above` warm and `below` cool, and adding an override.** Rejected: an
overridable default is not a removed assumption, it is the same assumption with
an escape hatch — and the default it would keep is the exact one the debrief
names as the thing to avoid absolutely, `positif = rouge`.

**Two axes: keep the diverging pair and add a "quantity" enum beside it.** This
is the shape the request arrives in — temperature versus precipitation — and it
is meteorology with an indirection. Whatever the members were called, the
framework would be asserting that some quantities invert and others do not,
which is a claim about domains it cannot see.

**A fifth and sixth hue family, so the accents need not be shared with
avatars.** Rejected on `ADR-0013`'s and `ADR-0014`'s own terms, reused rather
than re-argued: new primitives measured across four profiles and three
dichromacies is a mission.

**Keeping the arrow alongside the word.** Genuinely considered, and it is the
version that changes least. Rejected on three measurements and one principle:
the arrow costs the width that put a three-detail row 24 px into overflow at
300%; it says which side rather than which sense; it reaches nobody the word
does not; and a second signal for a fact the first already carries is what the
debrief calls a capsule that looks like an alert.

**A `note` string on `IuxRowDetail`, which is what the maquette literally
asks for.** Rejected in *Consequences*: it is `ADR-0012`'s rejected
alternative arriving a second time, and it would let a row draw a deviation
with no word — the failure this record exists to make unreachable.

**Naming the accents after the pilot's senses.** Rejected: it is the whole
category error, and the next application to arrive would want a fifth sense
rather than a fifth hue.

**Reusing `IuxAvatarTone` rather than adding a second four-member enum.**
Rejected, and the two look identical enough to be worth the sentence.
`IuxAvatarTone` selects `avatarAccent`, whose surface is a **fill** at level 40
or 70 with `neutral0`/`neutral95` on it; `IuxValueAccent` selects `comparison`,
whose surface is a **tint** at level 90 with the hue's own dark end on it. One
enum in front of two sets of colours that are not interchangeable is the
aliasing `action.tertiary` already cost this repository once.

## Risks

- **Bound 5 is unenforceable.** An application that maps `one` to *warmer* on
  one screen and to *colder* on the next builds exactly the same widget tree as
  one that is consistent. The framework can refuse an unworded deviation and a
  level reading with a hue; it cannot refuse an incoherent palette. This bound
  is a review criterion, and the suite being green says nothing about it.
- **Two accents are one colour to a colour-blind reader, in every profile.**
  Measured above, and the pilot's own pair is one of them. The word is the
  mitigation and it is compiled in, which is the strongest form available; it
  is not a fix for the palette.
- **The capsule is below 3:1 against the page.** Deliberate, and it means a
  reader in bright sunlight may not see the capsule at all. Everything it holds
  is still text at 4.5:1, so nothing is lost — but an application that wanted
  the capsule to group two readings visually would find it too faint.
- **This is the second restructuring of one colour group in one day.** ADR-0013
  measured a warm/cool separation and characterised it in a test; that test is
  replaced here by one measuring a different property of a different set. A
  reader of the two records in sequence should read the first for why a reading
  is not news and the second for why a side is not a hue, and should not expect
  the first record's numbers to describe what ships.
- **This record generalises from one pilot**, the same extrapolation `ADR-0013`
  and `ADR-0014` each named. One application has asked for a hue it chooses
  itself; that budgets, blood pressures and lap times want the same thing is
  argued and unproven.
