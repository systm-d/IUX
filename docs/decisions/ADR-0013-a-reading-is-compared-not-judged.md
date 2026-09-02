# ADR-0013: A reading is compared, not judged

- Status: accepted
- Date: 2026-09-02

No mission number, for the reason `ADR-0011` gives and `ADR-0001` set the
precedent for: this came from an application building on IUX rather than from a
mission of the framework, `docs/MISSION_*` stops at 043, and citing an
`IUX-044` that no document answers would be a reference that promises a file
and delivers none.

## Context

`ADR-0012` left this decision open, by name, in its *Consequences*:

> **The qualifier's type fits in shape and not in vocabulary, and this is the
> bound that will bite first.** […] `IuxStatusTone` has exactly four families
> and they are families of *news*: neutral, success, warning, error. The
> pilot's qualifier is not news. […] **This record does not add a fifth tone.**
> The pilot takes `neutral` and a grey pill, or the mismatch is the next
> decision somebody takes. Nothing tests which of those happened.

This is that decision, taken one component to the left of where `ADR-0012`
found it. The pilot's maquettes draw coloured pills for **deviations** —
`+2,1 °C`, `−47 mm`, `+51 mm` — and a pill is what the framework was asked for.
The request arrived as *reuse the four tones and let the application decide
which tone means which climate*.

**That is a category error, and it is worth stating precisely, because the four
tones are not merely a poor fit — they are a different kind of thing.**
`iux_status_model.dart` defines them as news, in its own words: `neutral` is
"a fact rather than good or bad news", `success` "a state the user wanted",
`warning` "still works but will not for long", `error` "a state that has
stopped working and needs attention". The dartdoc on `neutral` goes further and
says that colouring a neutral state red "asks the user to react to something
that needs no reaction".

A summer 2.1 degrees above its thirty-year normal is not a state that stopped
working. Sending it through `IuxStatusTone.error` to obtain the red the eye
expects does not merely mislabel it: it ships a judgement — *this is a
malfunction* — as a colour, in a framework whose entire premise is that a
colour is never allowed to carry a claim on its own. And the judgement is not
even the application's to delegate: whether a dry year is bad news depends on
who is reading, which is exactly the kind of question `IuxStatus` refuses to
answer by requiring the caller to write the sentence.

**The "four tones and no more" rule was read before this record was written,
and it does not forbid a second axis.** `docs/components/badges-and-chips.md`
*Limits* says, in full: "**Four tones and no more.** An application needing a
fifth meaning is describing its domain rather than a UX category, and that
belongs in the label." The enum's own dartdoc says the same thing in the same
terms. Both bound *the axis of news* and both give the same reason — a fifth
family of news would be a domain concept. Above, level and below are not a
domain concept: a budget, a blood pressure, a lap time and a rainfall total are
all read against a reference, and none of them is good or bad news until
somebody says so. The rule is kept, and it is kept where it was written.

`docs/components/component-standard.md` §14 requires an ADR for an
architectural decision, and `COMPONENT_STANDARD.md` §20 requires that anything
moving the standard be motivated, recorded, coherent with the rest, and
exceptional. Adding a second semantic colour vocabulary — the first since the
palette was defined at `ADR-0002` — is exactly that.

## Decision

**A reading that has been compared with a reference gets its own axis, with
three members and no judgement in any of them, and its own colour roles.**

Three things are added:

- `IuxValueDirection` — `above`, `at`, `below` — and `IuxValue`, a value class
  carrying a direction, the formatted reading, and the sentence that says what
  the reading means.
- `IuxValueIndicator`, the pill that draws one.
- `IuxSemanticColors.comparison`, an `IuxComparisonColorSet` of three
  `IuxComparisonRoleColors`, each holding `content`, `surface`, `border` and
  `mark`.

Four bounds are part of the decision, not commentary on it:

1. **Three members, and the number is arithmetic rather than taste.** A
   quantity compared with a reference is above it, level with it, or below it.
   There is no fourth side, so nothing will ever arrive asking for one. This is
   the property `IuxStatusTone` does not have and has to defend in prose.
2. **The mark is never optional, and never replaces the reading.** Every pill
   draws an arrow or a rule. There is no parameter that removes it and no
   arrangement of parameters that yields a pill with a mark and no number.
3. **The direction is never the accessible name.** `IuxValue` cannot be built
   without a label, the label may not be empty, and it may not equal the
   reading. A screen reader is told the sentence and nothing about the
   direction.
4. **A direction is a comparison the caller performed, not a judgement about
   it.** `IuxValue.above` means one number was larger than another. It does not
   mean too high, or worse, or worrying. A pill used to say "this is bad" is
   outside this record, and the four tones of `IuxStatus` are where that
   belongs — with the words that make the claim arguable.

The first three are unreachable by construction. **The fourth is judgement, no
test can hold it, and it is written into the decision rather than only into
`docs/components/badges-and-chips.md` for that reason** — the same shape
`ADR-0011` bound 4 and `ADR-0012` bound 4 already have.

## Why a mark, when the reading usually carries its own sign

The request that produced this component argued that a value pill needs no
glyph where a status pill does, because `+2.1 °C` reads as "above" on a
monochrome screen, under any colour vision deficiency, and out loud — so the
tone is reinforcement of something the characters already say.

**The argument is sound and the guarantee behind it does not exist.**
`IuxValue.above('2.1 °C', …)` compiles. So does every locale's formatting of a
deviation, including the ones that write no sign, and the catalogue sample that
came with the original request drew `0.0 °C` with none. What the framework can
promise is what it can refuse to build, and it cannot refuse a string.

It also cannot supply the sign itself.
`test/accessibility/no_composed_strings_test.dart` forbids the library from
putting characters into anything a user reads, and the rule is not a formality
here: a `+` written by IUX would be the wrong glyph in some scripts and on the
wrong side in others.

So the direction is carried by a mark the component draws — an upward arrow, a
horizontal rule, a downward arrow — and the mark is redundant with the sign
whenever the caller wrote one. That is the same trade `IuxStatusIndicator`
makes with its glyph, and the same technique `ADR-0011` describes: "there is no
constructor without a label, so the labelless status cannot be built rather
than merely being advised against".

Vertical arrows and not horizontal ones, deliberately. A left or right arrow
means the opposite thing in a right-to-left interface and Flutter mirrors some
of them and not others; up and down mean up and down in every script.

## Where the colours come from, and where they do not

**They do not come from `feedback`.** A colour borrowed from the alarm brings
the alarm's meaning with it, which is the whole thing this record exists to
avoid, and a role defined as an alias of another role is not a role — the
palette has already shipped that defect once, in `action.tertiary`.

Reading the palette for an alternative produced a finding worth writing down:
**IUX ships five hue families, four of them already carry a meaning, and the
fifth is neutral.** Accent is action, information, focus and selection;
critical is destructive and error; positive is success; caution is warning. Any
two-ended axis must either take two of those hues or invent new ones, and there
is no third option.

Inventing a sixth and seventh hue was rejected. `IUX-PALETTE-HEADROOM-001`
records what choosing colours without anyone seeing them costs — a warning role
that measured 9.60:1 and read as khaki brown — and a new ramp would need seven
values, four profiles, and a perceptual separation from four existing families
that nobody has looked at on a screen. That is a mission, not a paragraph in a
component's ADR.

So the two directions take the **warm** and **cool** ends of the existing ramps
as hues rather than as roles, and `at` takes the neutral one. The separation
between them was measured in this round, on the shipped mapping, in Oklab ×100
with the instruments in `test/support/perception.dart`:

| profile | ordinary vision | protanopia | deuteranopia | tritanopia |
| --- | --- | --- | --- | --- |
| light standard | 30.4 | 22.7 | 24.5 | 29.9 |
| light high contrast | 13.2 | 9.4 | 11.1 | 13.4 |
| dark standard | 17.2 | 11.8 | 12.4 | 22.2 |
| dark high contrast | 9.9 | 6.5 | 7.3 | 12.6 |

For comparison, and measured the same way: `feedback.success` against
`feedback.error` in the light standard profile is **11.2** apart under
protanopia with **0.2** of it chromatic — the two hues have collapsed
completely and only lightness remains. The warm/cool pair keeps its chroma
under both red-green dichromacies, which is why it is the pair chosen.

**It is units and not tens in the dark high contrast profile, and that is a
bound rather than a boast.** `test/support/perception.dart` says roles that
must never be confused "need tens rather than units". 6.5 is not tens. The
reason is structural: contrast on a dark ground is bought by lightening, and a
lightened hue has less chroma to spend, so the profile whose job is separation
is the profile where these two sit closest. The existing feedback roles make
the same trade in the same mapping. It is characterised by a test that fails if
it ever stops being true, and it is the arithmetic reason bound 2 exists.

The container is the profile's **subtle surface** in all four mappings rather
than a tint of the direction's own hue. Two reasons, and the second is the one
that is not obvious. A value pill repeats down a column — five ranking rows,
four seasons, a row per month — and thirty tinted panels is a screen of alarms;
`IuxTagChip` and `IuxChartTokens.bandFill` already reach for the recessed
neutral for the same reason. And in the two light profiles, where a feedback
panel *is* tinted, it is what keeps a reading from looking like a message
without depending on anyone comparing two hues.

**In the two dark profiles the comparison content colour equals the feedback
content colour on the same surface, and this is recorded rather than avoided.**
On a dark ground the whole palette already puts every feedback role on the same
neutral surface, separated by hue alone. Paling the comparison roles one rung
to make them numerically distinct was tried and measured, and it costs the
separation between *the two directions* — 17.2 down to 9.9 in the standard dark
profile, and 11.8 down to 6.5 under protanopia. The separation a user has to
make is above from below, not pill from panel, so the aliasing is accepted and
the mark and the geometry carry the rest.

## What the maquette asked for and did not get

The pilot's maquettes were read for this record, and they do not encode
direction in colour. `01-saisons.png` draws `+2,1 °C` warm and `−47 mm` cool,
which reads as a diverging scale — and then draws `+51 mm` and `+91 mm` cool as
well. The colour is tracking the **quantity** — temperature warm, precipitation
cool — not the side of the reference. `docs/maquettes/README.md` summarises the
same two pills as "`+2,1 °C` en rouge, `−47 mm` en bleu", which is the reading
the picture invites and not the one the picture contains.

Applying this record therefore gives `+51 mm` the **above** appearance, not the
maquette's blue. That is a deliberate divergence and the pilot should know it
before implementing: what IUX can define is the side of a reference, which is
domain-general and testable. Hot-versus-cold is a domain convention, it belongs
to the application, and a framework that shipped it would be shipping
meteorology.

An application that genuinely needs the quantity's own colour is describing its
domain, which is the case `docs/components/badges-and-chips.md` already sends
to the label — and, for a chart, to `IuxSeriesEmphasis`.

## Consequences

- **`IuxSemanticColors` gains a seventh role group**, the first since
  `ADR-0002` defined the contract. Every theme must map it: four shipped
  palettes plus any brand palette. `IuxTheme.withSemanticColors` callers who
  build a full `IuxSemanticColors` by hand get a compile error, which is the
  intended failure — a silently defaulted colour group is a group nobody
  measured.
- **`IuxStatusTone` is unchanged, and stays at four.** This record adds no
  tone. An application that wants to say a reading is *alarming* still says it
  with an `IuxStatus` and words, and the two components sit side by side in
  `docs/components/badges-and-chips.md`.
- **`IuxRowDetail.qualifier` is not changed by this record.** `ADR-0012` types
  it as `IuxStatus`, and "Très sec" — a word with no reading attached and no
  reference stated — is not an `IuxValue`. The mismatch `ADR-0012` recorded is
  narrowed by this record and not closed by it: a *deviation* on a dense row
  now has a home, and a *qualitative word* on one still does not. Whoever needs
  the second should measure the row first, as `ADR-0012` asks.
- **The pill is not a live region**, for the reason the status indicator is
  not: a list of thirty rows each announcing itself on every refresh is a list
  nobody can use with TalkBack. Wrap it at the call site.
- **Nothing here measures the pill on a narrow screen.** The status indicator's
  minimum-width finding (`IUX-LISTITEM-TRAILING-001`, 180.3 px at 100% text for
  one unwrappable word) was taken on a component with a glyph, a gap and a
  *label*, and a value pill carries a mark, a gap and a *reading* — usually
  shorter, and with different wrap points. **That number does not transport**,
  which is the trap `ADR-0011` and `ADR-0012` each recorded once already. The
  measurement is to be taken on the pilot's own 320-pixel screen and written
  into `docs/components/badges-and-chips.md`.
- **There is no numeric threshold anywhere in this component.** IUX is never
  told what counts as "above": the caller compares and passes the result. A
  framework that decided where `at` ends would be choosing a tolerance for a
  quantity it cannot see.

## Alternatives considered

**Reusing the four tones and letting the application map them.** The request as
it arrived, and rejected in *Context*: it ships a judgement as a colour, and it
makes `IuxStatusTone.error` mean "hot" in one application and "failed" in the
next, which is the state a closed enum exists to prevent.

**A fifth tone on `IuxStatusTone`.** Rejected on the rule's own terms. The four
are families of news and a fifth would have to be one too; "above a reference"
is not news, so it would not be a fifth member of that set but a foreign one
smuggled in — and the enum resolves a glyph and a measured colour pair for
every member, so every component reading it would have to grow a case for a
meaning it has nothing to say about.

**Two hues invented for this axis.** Rejected in *Where the colours come from*:
seven values across four profiles, chosen by someone reading hex in an editor,
in a repository that has already paid for exactly that.

**No colour at all — three neutral pills separated only by the mark.**
Genuinely considered, and it is the version that needs no palette change and
no ADR. Rejected because the direction is the thing a reader scans a column
for, and a channel that is free to add and reaches everyone who can see the
screen is not one to decline on tidiness grounds. The mark makes the colour
redundant; redundant is what a second channel is supposed to be.

**A `reference` parameter on `IuxValue`, so the pill could say what it was
compared with.** Rejected: it is a second string that has to be composed with
the first to be spoken, and the framework composes no user-facing text. The
reference belongs inside `label`, where the caller writes it once — "2.1
degrees above the 1991 to 2020 normal" — and where a screen reader gets it in
one utterance.

## Risks

- **Bound 4 is unenforceable.** Nothing can tell a comparison from a
  judgement dressed as one. An application that maps "hot" to `above` and
  "cold" to `below` builds exactly the same widget tree as one that maps a
  budget overrun. The framework can make the two hard failures unreachable —
  the unmarked pill and the unlabelled one — and argue for the rest. This bound
  is a review criterion, not a test, and the suite being green says nothing
  about it.
- **The dark high contrast pair is thin.** 6.5 in Oklab ×100 under protanopia
  is above the threshold at which most people notice a difference side by side
  and well below the tens a glanced-at separation wants. If that profile is
  where an application's users live, the mark is not reinforcement there — it
  is the signal.
- **A seventh role group is a seventh place for a brand theme to get it
  wrong.** Every group added to `IuxSemanticColors` widens the surface a
  consuming theme has to map correctly, and `docs/themes/brand-theme-guidelines.md`
  now has three more roles to describe.
- **`at` will be over-used.** It is the safe-looking constructor, and a column
  of neutral pills reading `0.0` on every row is decoration users learn to
  skip. Nothing refuses it; `docs/components/badges-and-chips.md` argues
  against it and that is all.
- **This record generalises from one pilot.** The axis is claimed to be
  domain-general — budgets, blood pressures, lap times — and exactly one
  application has asked for it, for one quantity. That is a defensible
  extrapolation and it is still an extrapolation.
