# Changelog

The version in `packages/iux_flutter/pubspec.yaml` decides; the heading below
repeats it. See CONTRIBUTING.md, "Versioning".

## Unreleased

### `IuxNavigationDestination.badgePlacement` — the corner, asked for and never assumed

A badge on a glyph resolves compact tokens — the supporting type role, a
tighter minimum extent, horizontal padding only. Measured first: a counted
badge at the label role is 28.5 wide against a 24-pixel glyph, so at full size
it does not sit in a corner, it replaces the icon. The size is asked for by the
component that owns the placement and never by the caller; a public size knob
would let two applications draw two different badges for the same meaning.

The badge on a destination was laid out after the label, and the documentation
gave three reasons: an overlay covers the glyph, clips as soon as the text
grows, and leaves the number and its subject in two unrelated places for a
screen reader. Two of those are avoidable, and the third does not apply here.

`IuxBadgePlacement.onGlyph` puts the badge on the corner of the glyph, which is
the most widely learned convention on a phone and the one a user has already
spent years reading. `afterLabel` remains the default and the recommendation:
nothing changes for any existing caller.

What the exception is careful about:

* **Covering the glyph is accepted here and nowhere else**, because a
  destination's glyph is decorative by construction — the label beside it
  carries the meaning and is drawn at every size.
* **It does not clip.** The corner exists only while the bar is in its compact
  arrangement; once the text grows enough that destinations lay out in rows,
  the badge returns after the label on its own. The overlay is an enhancement
  for the sizes that can carry it, never a layout that breaks at the size
  somebody chose in order to read.
* **It does not lose the number.** The badge is merged into the destination's
  single announcement either way, so a screen reader hears the same sentence
  and finds the same one stop whichever placement is drawn. A test asserts it
  for both.

The arrangement is read from the resolved tokens rather than from `MediaQuery`,
because a component does not reach below the layers it is given — the standard
test says so, and said so about the first attempt at this.


### `IuxOnboardingStep.forwardLabel` — the label moves to the step it names

**Breaking.** `IuxOnboardingFlow.forwardLabel` is removed;
`IuxOnboardingStep.forwardLabel` replaces it, and is null on the last step only.

The pattern's own assertion demanded something its API refused. The message
reads *"Name where it goes — 'See how budgets work' — rather than the
mechanism"*, and it guarded a single `String` for the entire flow. A flow of
four steps has three forward controls pointing at three different destinations,
so from the second step onward the label was either wrong or generic — and
generic is exactly what the assertion refuses. The class documentation's own
example showed it, and the catalog was shipping it: after "Set a budget", the
control still read "See how budgets work".

`backLabel` stays one word for the whole flow, and its argument is kept because
it is right: going back always goes to the step just left, and a control renamed
at every step has to be read again each time. That reasoning does not transfer
to forwards, which is why the two parameters now differ and both say so.

The shape is checked on the first build, in both directions: a step other than
the last with no label is a control with no name, and a label *on* the last step
is never drawn — the quieter half, where a caller believes they named something
and did not.

`IuxGuidedForm` carries the same single-string shape with the same demand in its
own assertion. It is recorded in `IUX-ONBOARDING-FORWARD-001` and deliberately
left alone: a guided form's forward control genuinely does the same thing at
every step, and changing two patterns on one report is wider than the report.

### A one-answer question is `IuxRadioGroup`, and the list row cannot say so by refusing

**Documentation only.** An integrator built a weekday chooser — one question,
one answer, seven options — out of `IuxListGroup` and seven
`IuxListItem.selectable`, and shipped it for several days. It renders correctly
and passes a widget test. It is seven independent toggles: a screen reader reads
seven controls with no question attached, because a group of rows is not a group
and there is no heading to jump to, and nothing but the caller's own `setState`
stops two of them reporting selected at once.

This is the one wrong composition the framework cannot refuse, and the reason is
worth stating: several independent choices in a list is a legitimate arrangement
— files to delete, days to include — and it is byte-identical to a single-choice
question built the wrong way. The row's own dartdoc is what makes the trap work,
by saying truthfully that a selectable row "is a checkbox in disguise". Both the
dartdoc and the component documentation now name `IuxRadioGroup` at that point,
with a table of what the two arrangements announce.

### What binds a native mobile framework is EN 301 549, and the RGAA does not apply

**Documentation only.** The issue that asked for this mapping named EN 301 549
*and RGAA*, on the reasoning that the RGAA is what a French audit tests against.
Half of that is wrong: **the RGAA's technical method covers web technologies
only** and explicitly excludes native mobile applications, for which the
European standard applies directly. IUX produces native Android interfaces, so
its 106 criteria do not apply here at all. The mobile referential is **RAAM**,
which verifies against EN 301 549 and whose 2.0 revision adopted the RGAA's
thematic structure — very likely why the two get conflated. Finding that cost
nothing; discovering it after writing a mapping against the wrong criteria set
would have cost a great deal.

`research/accessibility/en-301-549-mapping.md` is **half-finished on purpose.**
Our own side is measured and complete: 166 register entries, 85 citing a WCAG
2.2 success criterion, 87 at level `standard`, **29 distinct success criteria**,
each asserted by a test rather than claimed — and that still does not establish
coverage, because the denominator is in a document nobody here has opened. The
clause side is empty because every primary source is unreachable from this
environment: ETSI, W3C and both government portals are refused by the network
egress proxy. A clause number quoted from a commercial summary is exactly the
failure `IUX-RESEARCH-GAP-001` reported, one level up, so the leads are marked
as leads and none may reach a register `Sources` line unread.

The finding that survives regardless of which clause numbers turn out right:
**the requirements most likely to be satisfied here have never been claimed, and
the one at the centre of the framework's proposition cannot yet be evidenced.**
Honouring platform preferences for colour, contrast and text size is probably
IUX's strongest answer in the whole standard and is claimed against nothing;
exposing information through the platform's accessibility service is what the
library is *for*, and `IUX-MANUAL-001` still means no screen reader has ever
seen it. `IUX-CONFORMANCE-001`.

### The error glyph becomes an octagon, and the four shapes get one definition

**Visual change in every application.** `IUX-PALETTE-PERCEPTION-001` measured
the four feedback colours under simulated dichromacy and found `success` and
`error` **0.4 apart** in the dark high contrast profile — the same colour, under
the most common dichromacy, for the pair whose confusion costs the most. For
that pair the glyph and the wording are not reinforcement; they are the signal.

The glyph set was not carrying that weight. Its doc comment argued "a user with
deuteranopia distinguishes the triangle from the circles" — true, and the wrong
pair: the triangle is `warning`, which colour separates well. **Three of the four
glyphs were circles**, and `success` against `error` was a circled tick against a
circled exclamation mark at roughly twenty logical pixels. Never an SC 1.4.1
failure, since the text always carried the category, but a redundancy that was
thin exactly where it was load-bearing.

`error` is now an octagon holding an "!" — the only octagon in the set, and the
road sign for "stop" opposite `warning`'s for "take care". Both shapes are
borrowed rather than designed, and separate by outline alone in a
black-and-white screenshot.

**The more dangerous finding was the duplication.** Three components drew these
categories and each resolved its own glyph map. They happened to agree, held
together by nothing, and because each was internally consistent **each
component's own distinctness test would have passed while the same category
became two shapes.** The shapes now have one definition and a test asserts all
three read it.

**No test here checks the thing the change is for.** Icons render under
`flutter_test` through a substitute font in which every glyph is an identical
square — this library shipped with no icons at all for weeks while the whole
suite passed. The manual protocol gains check F6: the four blocks, greyscale
filter on, named at arm's length from the shape alone.

### A cited `IUX-*` identifier must resolve, and resolve to something still true

The register is the project's memory, and a citation into it is a promise: a
level, a scope, a source, a limit. Nothing checked the promise. **Three
identifiers were cited in earnest by source and documentation with no entry
anywhere** — the citation looked like evidence and cost the reader the search
before they could conclude there was none. All three have since been written
up, so `test/package/evidence_register_test.dart` passes on the day it is
added; it exists to stop the fourth. The register is appended to by hand at the
end of a piece of work, which is exactly when a deadline is nearest and an ID
is most likely to be cited from code and never registered.

Writing it found a second, quieter version of the same defect. An ID may carry
more than one entry and the register uses that deliberately — a finding first,
its fix or refinement later, the title saying which. But a reader following a
citation lands on the **earliest** entry. `IUX-OVERLAY-001` read "open, and
deliberately not fixed here" for as long as it took to fix it elsewhere, with
nothing on the page telling anyone to read on. Three IDs were in that state.
Each earlier entry now carries a forward pointer naming what continues it, and
the test holds the convention: a superseded entry must say so.

The check does not run in reverse. An entry nobody cites yet is fine.

### The palette, measured with instruments WCAG does not have

**Measurement only. No shipped colour changed.** `theme_contrast_test.dart`
holds every pair to its WCAG 2.x floor and the palette passes. Two questions
that floor cannot answer had never been asked: whether a light role and a dark
role tuned to the *same ratio* are equally legible — WCAG's formula is
symmetric, so by construction it cannot tell — and whether two roles that both
pass can be told apart *from each other*, which nothing in WCAG measures at all.

New under `test/support/`: APCA lightness contrast, Oklab distance, and
simulation of the three dichromacies. Each is checked against a property of its
own algorithm in `perception_test.dart` before any measurement is allowed to use
it, because a number from an unverified implementation is worse than no number —
it looks like evidence.

Three findings, in `IUX-PALETTE-PERCEPTION-001`:

- **The same ratio buys less than half the contrast in dark.** `border.standard`
  is tuned to 3.67:1 light and 3.65:1 dark, deliberately matched, and delivers
  Lc 64.3 against Lc 27.2. The two metrics agree on *ordering* inside a polarity
  — asserted, in all four profiles — and disagree on magnitude across them.
- **A dark control outline clears SC 1.4.11 and sits under the perceptual
  floor.** `border.standard` and `border.interactive` measure 3.65:1, past the
  required 3:1, at Lc 27.2. Recorded rather than fixed: the two candidate rungs
  are measured and choosing between them is a palette decision.
- **Colour does not separate the feedback categories.** Under deuteranopia,
  success and error content are 0.4 apart in dark high contrast — the same
  colour. The glyph is what carries the category, and the test suite now asserts
  the four glyphs are distinct instead of trusting a doc comment to say so.

A fourth finding is left as a proposal: three of the four glyphs are circles, so
the pair colour fails hardest on is a circled tick against a circled
exclamation mark. `research/perception/open-questions.md` says what would settle
each of these.

### The manual validation protocol covers what shipped since it was written

**Documentation only.** `docs/accessibility/manual-validation-protocol.md` dates
from 2026-08-05 and predates the six changes that landed on 2026-08-27 from a
real migration. Every one of those was argued from numbers, and five left a
question a number cannot close.

**Block F** adds them, and it is different in kind from the blocks above it:
those check whether the platform does what the semantics tree says, these check
**judgements**.

- **F1** — the caution ramp changed hue because a yellow held above 4.5:1 on
  white stops being a yellow. That `#A34A00` reads as a warning rather than as a
  brown is a judgement about perception nothing here tests.
- **F2** — the standard profile now stops short of AAA so reinforced contrast
  has room. Whether that reads as *enough* room needs an eye.
- **F3** — `IuxChipMark.outline` gives up the checkmark to buy width. Weight is
  not colour, so SC 1.4.1 holds; but it is quieter, and quieter for exactly the
  users the glyph was put there for. **This one could send a default back.**
- **F4** — a shared-line radio group keeps the spacing floor against what the
  reporting application did. A mis-tap says that was not conservative enough.
- **F5** — a brand mark does not grow with the text setting. A documented cost;
  what it costs a user at 200% has never been looked at.

`IUX-MANUAL-001` also gains a register entry. It was cited as the limit on four
other entries and had none of its own — the same shape as the two findings
recorded under `IUX-RESEARCH-GAP-001`.

The session itself still has not been run, and that is still the release
blocker.

### `IuxTapTarget` announced a button and offered nothing to activate

**Behaviour fix, in the case the widget exists for.** Passing `semanticLabel`
excludes the subtree — the only way to replace what an icon-only control would
otherwise announce — and that took the child gesture detector's tap action with
it. The node said "button, enabled" and had nothing to fire. A finger worked; a
screen reader could not activate it at all.

The fix is the line `IuxSemantics.action` already carries: `onTap` published on
the node itself.

**This is the fourth thing that one mechanism has deleted** — `onTap` on every
IUX button (IUX-005 to IUX-011), the focus state and `focus` action on eleven
controls (`IUX-A11Y-FOCUS-001`), the `Focus` widget's own annotations, and now
this. So the durable half of the change is the check:
`announced_controls_test.dart` required a **literal** `button: true`, and
`IuxTapTarget` writes `button: onTap != null` — the file was scanned and this
call was never examined. The predicate now matches anything that is not a
literal `false`, because a computed button flag is the node most worth checking,
not the least. Run across the library, it flags nothing else.

Verified in both directions with three instruments: with the fix removed, the
scanner names the file and two behavioural tests fail — one on the announcement,
one on the effect.

No IUX component was affected: all six in-library call sites pass `onTap` and
none passes `semanticLabel`, so the exclusion never fired. This was the public
API contract, met by callers.

Also documents that **`IuxFocusable` answers Enter and Space only** and
publishes no tap action — correct by design, since focusability is not
activability, but undocumented until now.

See `IUX-TAPTARGET-ACTION-001`.

### `research/` was empty while the charter required traceable evidence

**No library change. Claims, a method, a backlog, and a guard.**

`PROJECT_PROMPT.md` §3 says decisions must rest on serious research and that an
intuition is not a proof. `research/README.md` described subdirectories for
accessibility, Android, HCI and UX material. For the whole life of the project
`research/` held that README and nothing else.

Counted on `c37a1e0` rather than asserted — the commit the report was written
against, so that entries added by this batch of work are not counted as evidence
for it: **156 entries, 74 at level `standard`, 74 resting on a named WCAG
success criterion, 4 citing Nielsen Norman Group, and exactly one citing primary
literature in HCI**. That one is `IUX-LOAD-001`, for the ~0.1 s response-time
threshold (Miller 1968, Nielsen 1993), in its prose rather than in its `Sources`
line — which is why searching the source lines alone reports none. Nothing
anywhere rests on reading rate, working-memory span, a pointing law or visual
search: the four this library's own rules would need.

So the two claims are different claims. What is delivered is a **conformance and
semantics library, tested to an unusual standard**. What is *also* claimed is
that the framework produces **ergonomic** interfaces, and nothing in the
register supports that.

Both halves of the report were taken, because they are not alternatives:

- **The claim.** The README states plainly what is delivered and marks the
  ergonomics an explicitly unsupported ambition. §8 marks its last three source
  families — HCI literature, cognitive psychology, ergonomics — as ambition
  rather than practice. §17 records that no component is anchored to a
  measurement of any of the six things it asks components to reduce.
- **The directory.** `research/README.md` is now a working method, including the
  rule that **a citation nobody has read is a lead, not a source** and may not
  enter a register `Sources` line until somebody has read it.
  `research/hci/open-questions.md` works the five rules the framework enforces
  today on an argument alone — the transient dwell, the 60–75 character reading
  width, the app bar's three-action limit, the 1.3× reflow threshold, and
  reduced visual stimulation.

**Two findings fell out of writing the backlog.** `kIuxAppBarMaximumActions = 3`
has no register entry at all despite being enforced by an assertion — and its
own doc comment argues from width, which the bar already measures, so a better
rule needs no literature. And `IUX-RUNTIME-006`'s 1.3× threshold is a
measurement against supported widths rather than a research question; it has sat
at `hypothesis` longest because nobody framed it as measurable.

`test/package/research_test.dart` guards the shallow part: the directory is not
empty, and no subdirectory is an empty promise. It cannot check that the
contents are any good, and a test that pretended to would be worse than none.

**This closes the gap between the claim and the artefact. It does not close the
gap the claim described** — `research/` holds a method and a backlog, no read
primary source and no measurement.

See `IUX-RESEARCH-GAP-001`.

### `IuxAppBar` has somewhere to put a brand mark, and a rule about it

**Additive. `brand` is null by default and a bar that does not pass it is
byte-identical.**

`title` is a `String` and stays one: the heading a screen reader reads has to be
text this component owns, and a free widget cannot play that part. Nothing here
relaxes that.

But an application migrating a bar that carried an **illustrated wordmark** had
nowhere to put it, so the wordmark went to the top of the page — and the first
screen then showed the name of the application **twice**, about ninety pixels
apart. The application's own UX audit filed that as a defect. It was one, and
the cause was here.

**The rule comes first, and it holds with or without the parameter: identity
does not belong in the page.** A wordmark under the bar is a duplicate to
remove, not a placement. That sentence was missing from
`docs/components/app-bar.md`, which explained why the title is textual and said
nothing about what an application carrying an identity should therefore do.

`brand` is drawn where the title's text would have been. The exclusion is
structural rather than requested — `IuxSemantics.header` already excludes its
subtree, so a mark cannot announce anything, even one built out of deliberately
labelled widgets. `title` stays required and stays the heading.

**What a mark gives up** are the two guarantees the text carries. It does not
wrap, so where a title would break into narrower lines the bar hands the mark
its own full-width line, and only a mark wider than the bar scales down. And it
does not grow with the text scale: a user who enlarged their text gets a larger
heading on every screen except this one. Where the name has to be legible at
200%, pass no mark.

Nothing can verify that a mark shows the name `title` says — SC 2.5.3 is the
caller's to hold.

See `IUX-APPBAR-BRAND-001`.

### The standard light palette had already spent the high contrast profile's room

**Behaviour change for every application on the light standard profile.** Four
content roles get one rung lighter and the caution ramp changes hue.

Every chromatic content role in the standard light profile measured past AAA on
white — `content.link` and `feedback.info.content` at 9.72:1,
`feedback.success.content` at 9.16:1, `feedback.warning.content` at 9.60:1,
`feedback.error.content` at 9.69:1.

That cost two different things. **Structurally**, `highContrastLight` had one
rung left for the link — `accent30` to `accent20` — so the setting whose whole
purpose is separation returned almost nothing. **In use**, the first report from
a user shown the light theme was "the contrast is too dark, dark blue, dark
green, dark red, it is too much": four roles darkened until they resembled each
other more than they resembled their own meanings.

| role | was | now |
| --- | --- | --- |
| `content.link`, `feedback.info.*` | `accent30`, 9.72:1 | `accent40`, **6.30:1** |
| `feedback.success.*` | `positive30`, 9.16:1 | `positive40`, **6.31:1** |
| `feedback.error.*` | `critical30`, 9.69:1 | `critical40`, **6.81:1** |
| `feedback.warning.*` | `caution30`, 9.60:1 | `caution40`, **5.94:1** |

The contract is now two-sided, and `theme_contrast_test.dart` is the only place
in the suite that asserts an **upper** bound on contrast: standard clears AA and
stops short of AAA on every chromatic content role, high contrast clears AAA on
every one of them, and high contrast measures strictly higher **role by role**
rather than on average. `content.primary` is exempt — it is neutral and should
be as dark as the surface allows in both profiles.

**The caution ramp needed a hue change rather than a rung.** Held above 4.5:1 on
white a yellow is not a yellow: `#5E3F00` and `#7D5400` read as khaki browns, and
the reporting application had to leave the ramp to get a warning anybody
recognised. Its dark end is now orange — `#A34A00`, 5.94:1 — keeping the darkness
ordering and very nearly the ratios it replaces. The light end stays amber: an
orange bright enough to sit on `neutral90` drifts towards the critical ramp. The
hue that reads as "warning" is not the same hue at every lightness, so the ramp
bends.

`action.secondary.foreground` stays at `accent30`, and that is forced rather than
chosen: on every unfilled variant it *is* the intent, and moving it made twelve
secondary buttons byte-identical to the same primary. Measured, not assumed.

**The upper bound is IUX's judgement, not a standard** — WCAG sets floors and no
ceilings. An application whose users mostly need AAA should ship
`IuxContrast.high` as its default rather than push the standard profile up.
`IuxTheme.withSemanticColors` remains the way out either way.

See `IUX-PALETTE-HEADROOM-001`.

### The chip's reserved slot has a price, and now a documented one and a lever

**Additive. `IuxChipMark.checkmark` is the default and nothing changes for
existing callers.**

`IuxFilterChip` reserves its checkmark slot whether or not the chip is selected,
so that toggling one does not reflow the row. That decision is right. **Its cost
was undocumented**, and it is large: on a 360-wide screen, four two-character
chips do not fit on one line and seven take three.

| | `checkmark` | `outline` |
| --- | --- | --- |
| one-character label | 78 px | 56 px |
| two-character label | 93 px | 65 px |
| four two-character chips | 120 px, two lines | **56 px, one line** |
| seven two-character chips | 184 px, three lines | **120 px, two lines** |

**Shortening the labels does almost nothing**, which is the part nobody guesses
while trying to compact a row: 22 of a one-character chip's 78 pixels are the
slot and the space before it, and only 16 are the character. Three call sites in
a migrating application left the component over exactly this.

`IuxChipGroup` now carries that budget in its own documentation, and
`IuxChipGroup.mark` is the lever. `IuxChipMark.outline` drops the glyph and the
slot; selection stays carried by the fill, the outline weight and the announced
state. Nothing reflows either way — the heavier outline was already drawn inside
the padding rather than added to it.

**The price is a signal**, and it is why this is not the default: weight is not
colour, so WCAG 2.2 SC 1.4.1 still holds, but a change of outline weight is
quieter than a glyph appearing — and quieter for exactly the users the glyph was
put there for. Use it for short scales the user reads at a glance, not for named
criteria where a chip may be the only thing saying a filter is applied.

`mark` sits on the group so a row cannot be half one shape and half the other.

See `IUX-CHIP-WIDTH-001`.

### `IuxRadioGroup` can spend width instead of height

**Additive. `IuxRadioGroupLayout.column` is the default and nothing changes for
existing callers.**

`layout: IuxRadioGroupLayout.row` puts the options on a shared line, wrapping
onto the next when they stop fitting.

The group had exactly one shape, and its vertical cost took it out of a
migrating application entirely: six exclusive choices on one settings screen
pushed everything after them below the fold. The spacing was never the cause —
what costs the height is the **48-pixel row each option reserves**, the
guaranteed touch target, for a label 24 pixels tall. No lever could help, and
none should: `IuxTapTarget.minimumSize` only ever raises the floor and
`IuxDensity.compact` moves spacings rather than targets. Measured:

| options | width | stacked | shared line |
| --- | --- | --- | --- |
| `3 min` `5 min` `10 min` `15 min` | 400 | 276 px | **148 px** |
| `3` `5` `10` `15` | 360 | 276 px | **84 px** |
| seven weekday abbreviations | 360 | 468 px | **148 px** |

**`kIuxMinimumTargetSpacing` is kept.** A shared line is where fingers are
closest together, so it is the last place that floor may be relaxed — and
keeping it costs nothing, because what was being paid for was rows, not gaps.
Same ring, same target at every density, same announcement: the option flags
asserted for a shared line are the stacked group's expectations verbatim.

Use it for short, comparable labels. A label long enough to wrap gives a ragged
block in which no option owns an edge; that is documented rather than asserted,
because the same words are short in one language and long in another.

See `IUX-RADIO-LAYOUT-001`.

### The suite can now see a control that no finger can use

**No library change. A test rule, and the sweep that applies it.**

`IUX-SELECTION-PRESS-001` — three selection controls that did not respond to a
finger while 2 320 tests passed — was fixed in `c37a1e0`. What was left open is
that **the suite could not have seen it, and would not see the next one.**

`tester.tap()` sends `down` and `up` with no frame between them. A finger
always leaves one, and any component that redraws while it is held gets that
frame to change the shape of its own subtree — disposing the `State` that holds
the recogniser tracking the pointer, so the `up` lands nowhere. With no frame,
the rebuild never happens before the `up`. The defect is not missed by that
instrument; it is unreachable by it.

Three things close it:

- **`realTap`** (`test/support/gestures.dart`) — press, one frame, release.
- **A rule** (`COMPONENT_STANDARD.md` §18.1) — every assertion that a component
  *responds* to a press goes through `realTap`. `tester.tap()` stays correct
  where only the target is in question: region large enough, label inside it,
  disabled control refusing.
- **A sweep** (`test/components/press_feedback_sweep_test.dart`) — one
  realistic press per component that holds press state, and a check that reads
  `lib/src` and fails if a component holding press state is missing from it. The
  list cannot silently fall behind the library.

**The sweep came back clean.** Twelve components, twelve passes — including the
two navigation strips, the drawer and the tabs, which had never been looked at.
Reintroducing the original cause against the suite as it stands now fails 4
tests of 2 332; against the 2 320 that existed before the fix it fails **none**.

### `IuxListItem` painted its press tint over the row instead of behind it

**Behaviour change, and the reason to take this build.** An interactive row drew
its press and hover tint as the topmost layer of its own stack. Every colour in
this package is opaque — `IuxStateColors` records why — and the resolver hands
that layer an opacity of exactly 1 while the row is engaged. So the tint did not
tint anything: for the whole length of every tap it replaced the row with a
blank rectangle. Measured by counting the pixels the row painted in
`content.primary`, at one device pixel per logical one: **8226 at rest, 0 while
pressed, 8226 again after release.**

The layer now sits below the content and above the chosen background. The same
colour is the row's background for the duration of the press, which is what the
palette entry always described.

**It was reported from a device as "the row stays selected".** That is what a
grey band reads as once the text identifying the row is gone, and it is why the
report arrived filed under selection rather than under press. A row that opens a
screen has no selection to persist and never had one; nothing about selection
changed.

**The same arrangement is still in five other components** — `IuxCard`,
`IuxTabs`, `IuxBottomNavigation`, `IuxNavigationRail`, `IuxNavigationDrawer` —
and none was measured here. See `IUX-LISTITEM-STATE-001`.

Callers need change nothing.

### `IuxListItem.tappable` can show that it opens a screen

`disclosure: IuxListItemDisclosure.opensScreen` adds a chevron after the row's
value, excluded from the semantic tree because the row is already announced as a
button. It is **off by default**: of the four tappable rows in the pilot
application three open a screen and one opens a browser, and a chevron promises
the screen the back button returns from. Only the caller knows which it is.

There is deliberately no value for "leaves the application". Additive; a row that
names nothing is drawn exactly as before.

### Every layer that can be a route root now provides its own `Material`

**Behaviour change, and the reason to take this build.** `IuxScreen`, `IuxPage`,
`IuxModalLayer`, `IuxTransientLayer` and `IuxAdaptiveNavigation` each establish a
transparent `Material` around their own subtree. Until now they required the
caller to supply one — `Scaffold`'s job in an ordinary Material application — and
a route whose root is not a `Scaffold` never has one. Text in that position
resolves against the style Flutter labels *"fallback style; consider putting your
text in a Material"*: monospace, double-underlined in yellow.

**Two consumer applications out of two shipped a build with it.** One on the
single screen it pushed as its own route; one on all five of its screens, with no
`Scaffold` anywhere. Neither test suite could see it, and one of them was a
**golden suite over all five screens** whose committed PNGs were pictures of the
defect — under `flutter_test` every glyph is a filled black box, so a thin yellow
rule beneath a black box reads as a style flourish. They were reviewed by eye and
approved. The same font substitution that hid the missing icons hid this, one
level up and against a stronger instrument.

The fix could not stop at `IuxScreen`. The three layers place their content as a
**sibling** of the page, so a medium established inside the page never reaches
them: with the first correction in place, a dialog's title, message and dismiss
label still rendered in the fallback style. Each addition here is backed by a
measurement, tabulated in `IUX-MATERIAL-GROUND-001`.

**What this does not change.** `MaterialType.transparency` paints no background,
absorbs no hit test and clips nothing, so surface colour stays with the semantic
tokens. A `Scaffold` above any of these is still correct and still recommended —
it owns the scaffold background, the floating action button, the drawers and the
snack bars. It is simply no longer what stands between a screen and legible text.

Callers need change nothing. A route root that was already correct stays correct;
one that was not now renders.

## 0.2.0-dev.3 — IUX-043

Three chart primitives, and the first painting code in the package.

- `IuxLineChart` — one or more series over an axis, optionally against a
  reference band, with screen-reader stops laid over the stretch they describe.
- `IuxBarChart` — horizontal bars, one per row. No vertical arrangement, on
  purpose: columns collide at 200% text and the usual fixes break the chart for
  the reader who enlarged it.
- `IuxSparkline` — a trend small enough to sit beside the number it is about.

`semanticsSummary` is required on all three. A chart with no text alternative
does not exist for a screen-reader user, and the gap is invisible at review
time; making it a parameter is the only version of the rule that cannot be
forgotten.

Two series may not share a stroke pattern, which caps a chart at three. The
pattern is the channel that survives a monochrome screen, and two series sharing
one are a single line drawn twice for a large share of readers.

Known limits, all documented in `docs/components/chart.md`: no interaction, no
height parameter, non-negative bars only, the right-to-left mirroring is a
decision rather than a standard, and nothing here has been looked at on a
running screen.

### Also on this branch, and not part of IUX-043

Two workstreams shared a working tree while this mission ran, and a broad
`git add` merged them: **the commit `754c4fe` ("IUX-043: IuxLineChart, band and
all") also contains `iux_list_item.dart` and `iux_list_test.dart` in full**, and
a later chart commit carries the list panel in `apps/catalog`. Nothing was lost
and everything is tested, but a reader looking for the reasoning behind the list
change will not find it in the message above it. It is here instead.

- **`IUX-LISTITEM-TRAILING-001` is closed on both axes.** Bounding the trailing
  control to the row's one-third share had closed the width overflow (214 px at
  300% down to 6) and opened its mirror image on the other axis, which nothing
  recorded until a read-only audit measured it. The share is 86 px and does not
  grow with the text, while an `IuxStatusIndicator` reading one word has a
  minimum intrinsic width of 180 px at 100% — a single word has no wrap point,
  so below its minimum the label breaks **inside the word, one glyph to a
  line**. The row was 480 px tall without the status and 924 with it: 444 px for
  one word, and 284 px of bottom overflow in a bounded 320x640 box.

  The recorded "6 px residual" was never the row's either. It was raised inside
  the indicator, whose label had been laid out in a box **zero pixels wide** and
  painted outside it. The height was the symptom; an unreadable status was the
  defect.

  The row now uses the share as the question rather than the answer: a trailing
  control keeps the line while what it asks for fits, and moves under the row's
  text when it does not. No overflow on either axis at 100, 150, 200 or 300%. A
  row that genuinely does not fit still clips, draws the indicator and reports,
  because clamping without reporting would have made a visible overflow silent.
  Side effect: a row carrying a control can now answer `IntrinsicHeight` and
  `IntrinsicWidth`.

- **Eleven of the twelve release blockers were re-measured** by an audit with no
  write access, at `d72dc49`. B1–B10 closed, B11 partially (the entry above is
  its other half), B12 untouched. `docs/MISSION_042_RELEASE_CANDIDATE.md` §4
  carries the measurement for each, including two sentences of its own that had
  become literally false, B2's and B4's guarantees holding in debug builds only,
  and the 24 px that B5's surviving half was missing.

## 0.2.0-dev.2 — the IUX-042 follow-through

No new mission. This entry records the work that closed the release
assessment's blockers, and it covers a gap: nothing between IUX-042 and here had
been written down at all.

**The licence is settled.** MIT, chosen by the project owner, at the repository
root and in the package directory. `LICENSE` no longer grants nobody anything,
which was blocker B1 and the entry every other one sat underneath.
`publish_to: none` stays in the pubspec while the repository has no remote —
that is a guard against publishing by accident, not a legal position.

**Still not a release candidate**, and the reason has narrowed to one thing that
no amount of code closes: **nobody has run TalkBack, Voice Access or a D-pad on
a real device**, at any point in forty-two missions plus this. Everything this
repository claims about accessibility is measured on a semantics tree in a unit
test. That is a great deal, and it is not the same claim.

### Breaking

- `IuxFormField.child` is replaced by `IuxFormField.builder`, of the new type
  `IuxFormFieldBuilder = Widget Function(BuildContext, IuxFormField)`. The
  builder is handed the field, so the widget takes `field.input` and
  `field.focusNode` instead of a second copy of each — the duplication that had
  nothing checking the two agreed. Migration: `child: IuxTextField(input: x,
  focusNode: n, …)` becomes `builder: (BuildContext context, IuxFormField
  field) => IuxTextField(input: field.input, focusNode: field.focusNode, …)`.
  22 call sites in this repository, all migrated.
- `IuxFormSection` now refuses, in debug, a field whose `focusNode` is held by
  no widget inside that field — including one held by the *neighbouring* field.
  A widget that accepts no focus node cannot be a form field, which is what the
  required parameter has always meant.
- `IuxButtonState.loading` is removed. It resolved to the resting palette in all
  68 measured cells (four colour profiles × seventeen legal intent/variant
  pairs) while outranking `pressed` and `hovered`, so a running action whose
  repeat policy still accepted activations answered neither the pointer nor the
  finger. The last of the three unpainted rungs, after `success` and `error`.
- `IuxActionColors.border` and `IuxButtonTheme.variant` are removed, and
  `IuxActionIntent.tertiary` is redefined — from a statement about weight, which
  variant and importance already make, to **an action that leads away from the
  task**. `IuxInlineFeedbackAction` becomes `IuxNamedAction`, and `onDismiss`
  becomes `onDismissed` on three components.

### Added

- **`IuxScreen`**, which owns the app-bar-plus-page composition every
  application was writing by hand and getting wrong three ways. On 320x640 at
  250% the hand-written arrangement overflowed by 154 px and left the page
  nothing; it now splits 178/178. `IuxAppBar`'s `LayoutBuilder` is gone,
  rewritten as a slotted render object, so `IntrinsicHeight` and
  `SliverFillRemaining` work on an IUX screen — with bar heights byte-identical
  before and after across five scales and two widths.
- **`IuxPlaceMap`**, the accessible shell around a caller-supplied map. IUX
  renders no tiles and gains no dependency. A map without its list equivalent is
  **unconstructible**: `places` is required, the widget renders the rows itself,
  and there is no parameter that hides them. That guarantee is what licenses the
  other half — because the list is certain, the map subtree is removed from the
  semantics tree outright.
- **`IuxRadioGroup.focusNode`**, attached to the group's first option that can
  take focus. Without it the node an `IuxFormField` handed over was adopted by
  nothing: a validation-summary entry naming a radio group left focus on the
  summary and moved the user nowhere at all. The destination is argued rather
  than assumed — a group is a question, and focusing the column would give a
  stop the user cannot act on and which carries no focus ring, trading an
  SC 2.4.3 failure for an SC 2.4.7 one.
- `IuxAdaptiveNavigation` refuses an unbounded box by name, which
  `docs/components/navigation-rail.md` had claimed since IUX-025 without it
  being true.
- `IuxTransientLayer.debugCheckNotPlacedOver`, called from the three navigation
  components, so a notice placed over the navigation fails at build with the
  corrected arrangement printed.
- `uses-material-design: true` in the package pubspec.

### Fixed

- **A deletion ran without asking** (B2). `IuxActionDescriptor.destructive`
  *defaults* to `IuxConfirmBeforeExecution`, and a plain `IuxButton` discarded
  it in silence: the call site read as though the user were being asked, and the
  action ran on the first tap. A policy is now honoured or refused, never
  discarded — the button refuses at build, by name, and says what to use
  instead.
- **Two patterns put their only control out of reach** (B3). `IuxEmptyState` and
  `IuxPermissionRationale` now scroll themselves when, and only when, they are
  given a bounded height. The discriminator is not a heuristic: every vertical
  scroll view hands its children an unbounded height, so a block inside a
  caller's scrollable adds nothing, and a block given a bounded height was told
  the size of a box by something that will not scroll it — which is the dead
  screen.
- **A notice removed the navigation for four seconds** (B4).
- **The app-bar-plus-page composition** (B5), by `IuxScreen` above.
- **Assistive technology could not move focus onto four control types** (B6) —
  the sweep found **eleven**, and three of them had no tap action at all:
  announced as buttons, inert to a screen-reader double-tap. The mechanical
  check had missed them because it scans bare `Semantics` calls, and the helper
  writes `button: true` and `onTap:` in its own source, satisfying the scan on
  behalf of every caller. A test that verified the one place the defect could
  not be.
- **`IuxSearchResults` was unusable for a searchable list** (B7).
- **Two stacked full-width buttons threw** (B8). `IuxTargetSpacing` lays its two
  axes out with two different widgets now; the vertical `Wrap`'s wrapping
  protected nothing and cost a target — where the height was bounded it moved
  the overflow **sideways, in silence**, a third target landing 68 px off the
  right edge of a 320-wide box with no exception reported at all.
- **Opening a modal disposed the widget that opened it** (B9). `IuxModalLayer`
  keeps its `Stack` whether or not anything is open, so the page never changes
  depth: measured on all three slots, disposals 1 → 0, scroll offset 0.0 → 400,
  and no more `setState() called after dispose()` on the tap that answered the
  dialog. The page is also no longer re-laid-out between loose and tight
  constraints on open.
- **An accepted submission armed an unbounded focus move** (B10). Submitting
  opens a window in which a rejection may move focus, and it closes on the first
  of: the failure being shown, focus arriving in one of the form's own fields,
  or a step change.
- **A list row overflowed at accessible text sizes** (B11): 214 px at 300%, now
  6 px, pinned at the real number rather than rounded away.
- **The library shipped no icons at all.** The package pubspec did not declare
  `uses-material-design: true`, so every Material glyph rendered blank — which
  reads as "the radio buttons do not work" rather than as a missing font,
  because a radio group still updates its value and still calls `onChanged`; it
  simply has no visible mark saying which option is chosen. **No test could have
  caught it**: `flutter_test` substitutes a font that draws every glyph as a
  filled box regardless of what the pubspec declares, so 1976 tests passed
  against a package that shipped no icons. Reported from a real device.
- **Opening a keyboard rebuilt 7.6× what Material does** (`IUX-PERF-001`).
  `IuxAccessibility.of` read six platform values through `MediaQuery.of`, which
  subscribes to every aspect, across 34 call sites; each now reads its own
  aspect. Keyboard 114 → 8 rebuilds, notch 101 → 8, rotation 130 → 26, and text
  scale unchanged at 140 — correctly, since it is the one change that must
  rebuild. Nothing observable changed, verified by dumping 672 resolutions
  before and after, byte-identical.
- **`IUX-SURFACE-001`**: `surface.interactive` has its own primitive per
  profile. The recorded defect was the mirror of the real one — read-only and
  disabled did differ, but in the `filled` variant a read-only field was
  byte-identical to the **editable** field beside it on all four profiles, and a
  lock glyph was the only thing between them.
- **`IUX-RAIL-OVERFLOW-001`**, **`IUX-PROGRESS-LABEL-001`**,
  **`IUX-DRAWER-LABEL-001`**, **`IUX-DESTRUCTIVE-FOCUS-001`** and
  **`IUX-EXPAND-CRASH-001`** are all closed; see
  `docs/evidence/semantic-tokens-and-accessibility.md` for the measurement on
  each.

### Corrected — findings withdrawn, not quietly dropped

- **IUX-027 is withdrawn.** It reported that `BlockSemantics` does not remove a
  covered page whose element survives, and that finding is what kept B9 open for
  fifteen missions under an argument that accessibility outranked the
  ergonomics. It was measured with `find.bySemanticsLabel`, which reads
  `RenderObject.debugSemantics` — a per-render-object cache that keeps its last
  value for a subtree that stops being **visited** rather than being dirtied,
  which is exactly what a blocked page does. On the tree the platform is given,
  and on the simulated screen-reader traversal, the covered page is absent under
  every placement. There was never a trade. **The rule this leaves: an entry
  whose justification rests on a single measurement must name the instrument.**
- **"Five other signals carry read-only" was false.** Four of the five separate
  read-only from *editable* and say nothing about *disabled*, and the fifth is
  worse — a disabled field also publishes `isReadOnly`, because Flutter resolves
  `readOnly: widget.readOnly || !_isEnabled` and merged flags disjoin.
- **`IuxAdaptiveNavigation`'s old behaviour was never *silent*.** One
  `SingleChildScrollView` produced 27 exceptions. The choice was loud in the
  framework's words versus loud in ours.
- **Eight of the catalog's thirteen findings were closed and still described as
  open**, and the "396 px against 360" in the rail entry turned out to be the
  catalog's own longer destination names rather than the package suite's.
- **An exclusion needs the same evidence as an assertion.** The
  distinguishability sweep had excluded the running state, justified by "the
  progress indicator the button swaps in" — there is no progress indicator in
  either button.

### Known open

- **The manual validation register is still empty.** It needs a device, not a
  decision.
- **`find.bySemanticsLabel` is still used elsewhere in the suite**, surviving
  only because the pages behind those modals are still destroyed or genuinely
  absent. A sweep for that instrument is owed.
- The duplicate-descriptor half of the form-field fix is closed by shape, not by
  a check: nothing detects a caller who ignores `field.input` and builds a
  second descriptor, because the form never sees what the widget was passed.
- A running plain `IuxButton` with no `busyHint` carries the operation nowhere.
  Documented rather than asserted, because the assertion would fire across
  roughly twenty call sites in pattern files.
- `surface.subtle` still equals `surface.disabled` on dark standard; every
  alternative rung measured there costs `border.interactive` its 3:1.
- A rail placed by hand still gets no IUX refusal and cannot get one — a `Row`
  lays out a non-flexible child against an infinite width, so the rail is never
  told the window it is in.

## 0.2.0-dev.1 — IUX-008.8, 008.9, 029 to 041

Eight patterns, three audits, and the first application built on the framework
end to end. The `0.1.0-dev` line ends at `0.1.0-dev.11`: the pubspec's
`0.1.0-dev.9` and the package changelog's `0.1.0-dev.1` were lags, never
releases, and the three files are reconciled here.

**This is not a release candidate, and calling it one would be the first thing
this project has claimed without evidence.** Twenty-two entries in
`docs/evidence/semantic-tokens-and-accessibility.md` are open. Several are
severe enough to lock an end user out of a control they need — the assessment,
with the argument for what blocks a release and what does not, is in
`docs/MISSION_042_RELEASE_CANDIDATE.md`.

### Added

Eight patterns, sixteen libraries, in `src/patterns/`.

- **`IuxErrorRecovery`** with a sealed `IuxRecoveryRoute` — `IuxRetryRoute`,
  `IuxAlternativeRoute`, `IuxUnrecoverable` (IUX-029). An error with no way
  forward has to be *declared*, not shipped by omission. `IuxRetryRoute`
  accepts no `IuxActionDescriptor` at all: a parent out of retry budget swaps
  the route rather than greying the control, which removing the parameter turns
  from advice into a rule. Nothing retries on its own — verified by pumping 30
  seconds for zero attempts — so the pattern sets no time limit and SC 2.2.1
  has nothing to bind.
- **`IuxLoadingRetry<T>`** over a sealed `IuxLoadState<T>` — `IuxLoadInProgress`,
  `IuxLoadReady`, `IuxLoadFailed` (IUX-030). **There is no `.empty`.** An empty
  result is *ready with an empty value*, so the builder can name which of
  `IuxEmptyStateCause`'s four situations it is; a fourth enum value would put
  "add your first invoice" one step away from "a filter hid forty". One
  traversal of the indeterminate bar is 1800 ms, which is why a load resolving
  in 80 ms shows under a twentieth of one crossing and reads as a rendering
  fault rather than as work.
- **`IuxPermissionRationale`** with a sealed `IuxPermissionMoment` —
  `IuxBeforeAsking`, `IuxAfterRefusal`, `IuxSystemWillNotAsk` (IUX-031). Before
  and after cannot be confused because they are different types.
  `IuxSystemWillNotAsk` has **no ask parameter**: a control offering to request
  a permission the system will refuse to request reads as a broken app.
  `decline` is required on all three — it is the only signal an application
  gets that the user said no to *being asked*, and a pattern without it can
  only nag. The refusal comes first in reading order, so the control that opens
  the OS prompt is never under the first Enter, and both answers are real
  buttons: the asymmetry, not the wording, is the manipulation.
- **`IuxDestructiveFlow`** and `IuxDestructiveFlowController`, with
  `IuxDestructiveScope` and a sealed, required `IuxWayBack` — `IuxUndoOffer` or
  `IuxNoWayBack` (IUX-032). Proportionality asks one question a caller cannot
  get wrong: *could the user list what they are about to lose?* Two values, not
  four, because there are exactly two safeguards to allocate. `everything` plus
  an undo offer is refused — an undo only protects somebody who can tell they
  need it, and a user who deleted an account cannot inspect what went.
- **`IuxGuidedForm`** with `IuxGuidedFormStep` (IUX-033). Forward progress is
  never blocked and no step can be locked: a step that refuses is worse than a
  button that does, because the question at fault is not on screen. `summary`
  is required here where `IuxForm` allows null, since focusing the first
  rejected field is impossible when that field is unmounted.
- **`IuxSearchField`** and `IuxSearchResults<T>` (IUX-034). Two widgets rather
  than one, because on Android the box very often lives in the app bar and the
  results in the body. The results take an `IuxLoadState<List<T>>` — a search
  is a load, so there is no second state machine. Exactly one announcement per
  settled search: measured, a five-character undebounced query produces ten
  live regions, and with one pause, two.
- **`IuxProgressiveDisclosure`** over a sealed `IuxDisclosureState` —
  `collapsed`, `expanded`, `heldOpen` (IUX-035). Four rules are stated for what
  may never be disclosed and **exactly one is enforced by a type**; the docs say
  which, because a guarantee that is a guess is worse than none. Nothing
  animates, and the absence is proved rather than described.
- **`IuxOnboardingFlow`** with `IuxOnboardingStep` (IUX-036). Skip is required
  on every step including the last: an onboarding a user cannot leave is a wall.
- `IuxTextContent.search` and `IuxTextField.onSubmitted` (IUX-038), closing two
  of the three gaps IUX-034 recorded. No `textInputAction` parameter — the
  action key is resolved from `content` — and `onSubmitted` on a multiline field
  asserts, because its action key *is* the newline key.
- A catalog covering every barrel export, at text scales to 300% with a
  worst-case preset in one tap (IUX-008.8, IUX-037), and `apps/pilot` — a
  four-screen application whose deliverable is its friction log (IUX-041).

### Changed

**Breaking**, all in the button theme (IUX-038). Five members removed rather
than wired, with the reasoning left where each field was: `elevateFilled`,
`IuxButtonTokens.elevation`, `IuxButtonTokens.focused`, `IuxButtonState.success`
and `.error`.

`success` and `error` were not merely inert — **they swallowed hover.** They sat
above `hovered` in the resolver's precedence and returned the resting palette,
so an idle filled button moves `#1560B0` → `#0F4289` on hover while a succeeded
or failed one does not move at all. Removing them repairs an observable defect.

`component_standard_test.dart` now asserts that every field of every
`Iux*Tokens` class is read outside its declaring file. It rediscovered
`elevation` independently across all eighteen token classes, and was proved by
re-adding a dead field.

### Fixed

- **Assistive technology could not move focus onto an IUX control.**
  `IuxSemantics.action` set `excludeSemantics` to control the announced name,
  which deleted the focus state the `IuxFocusable` subtree contributed: an IUX
  button reported `isFocused: Tristate.none` with actions `[tap]` where
  Flutter's own reports `Tristate.isFalse` and `[tap, focus]`. `IuxButton` now
  matches Flutter. This is the third thing that one mechanism had silently
  deleted — it took `onTap` first, at IUX-005, and every IUX button was
  unusable with a screen reader for six missions. **Still open everywhere
  else**; see *Known open*.
- **A running button announced itself as unavailable and threw away the user's
  focus.** `_IuxActionSurface` fed one `isActivatable` value to both
  `canRequestFocus` and the semantics `enabled` flag, so a keyboard user who
  pressed "Try again" was thrown back to the enclosing scope, Android announced
  "unavailable" for something that was working, and `busyHint` landed on a node
  the user had just been moved off. A running button now keeps its focus,
  reports enabled, carries its hint, and offers `[focus]` but not `tap` —
  withholding the tap is the truth, since the repeat policy really does decline
  a second activation, while claiming the control was disabled was not.
  IUX-008.9 proved the conflation by measuring the same running action keeping
  focus under `repeatPolicy: allow` and losing it under `ignoreWhileInProgress`.
- **A generic sealed type broke equality silently** (IUX-030). All three
  subclasses of `IuxLoadState<T>` compared with a type test while `hashCode`
  folded `T` in. Dart generics are covariant, so `loose == tight` was true and
  `tight == loose` false: a value a `Set` holds twice and a `Map` never finds.
  First generic sealed type in the project, which is why the pattern used
  correctly everywhere else was wrong here.
- **The lint the project relied on had never run** (IUX-040). The root
  `analysis_options.yaml` raised the *severity* of `public_member_api_docs`
  without adding it to `linter.rules` — a no-op, for forty-two missions.
  Enabling it surfaced 41 undocumented public members in the foundations file
  alone, now written. The package lint set goes from 8 rules to 160.
- **Two tests that had never tested anything**, each now proved by breaking the
  code (IUX-008.9). *"A disabled button is skipped by focus traversal"* read
  `find.byType(Focus).first` — a `MaterialApp` puts nine `Focus` widgets in the
  tree and the button's own is the last, so the behaviour was entirely
  unguarded and passed with `canRequestFocus: true` hardcoded. A third
  (IUX-QA-VACUOUS-002) was repaired in its harness at IUX-038, where a fourth
  surfaced underneath it: at 200 px the summary entry sat at y = −82, and
  `tester.tap` only *warns* on a miss.
- `IuxRetryRoute.alternative` was a public field nothing could read, which also
  contradicted the doc twelve lines below it (IUX-029).

### Measured, and stated so nobody optimises on a hunch

- **Resolvers are not hot** (IUX-PERF-002). 200k calls each after a 20k warm-up:
  `IuxButtonResolver` 710 ns, the slowest (`IuxNavigationDrawerResolver`)
  1,557 ns. One 60 Hz frame is 16,667,000 ns, so the worst is 0.009% of one.
  The per-frame contrast maths that does exist — two `computeLuminance()` calls
  for a scrim — costs 37 ns. Nothing to optimise.
- **The Flutter lower bound is now evidence rather than habit.**
  `flutter: '>=3.35.0'` is where `MediaQuery.supportsAnnounceOf` first appears
  in a stable tag, and all 202 Flutter types referenced by `lib/` exist there.
  Only Flutter 3.44.8 / Dart 3.12.2 has actually run the suite.
- **The cost of composing no user-facing strings, measured for the first time**
  (IUX-041): 99 declarations, 19% of the pilot's `lib/`. The finding is not the
  total but that **17 of the 99 never appear on screen** — they exist only for
  assistive technology, no design mock contains them, and the easiest to forget
  are exactly the ones only a screen-reader user would miss. The decision stays
  right; the cost is now honest.

### Corrected

- **`IUX-A11Y-FOCUS-001` had been recorded as fixed for every IUX control. It
  was fixed for one.** `IuxFocusNodeOwner` has exactly one call site; the
  disclosure control, validation-summary entries and both transient-layer
  controls still report `isFocused: Tristate.none`. Found by IUX-038 auditing
  the fix it had just landed.
- **IUX-033 proposed *"did the user ask for this?"* as the single line behind
  seven independent focus decisions. Measured across all seven, five hold**
  (IUX-039). The two form patterns do not, and the reason is a real defect
  (IUX-FORM-FOCUS-001). The test was a good description of the intent and not
  of the code.
- **IUX-038's eleven-parameter argument was weaker than it looked** (IUX-039).
  Across all 59 public widget constructors exactly one reaches eleven
  parameters, and none of its eleven is a styling knob. Its other two reasons
  for declining the disclosure-control merge stand.
- IUX-037 recorded that `src/patterns/onboarding/` was "not exported and
  therefore not public API yet", and so did not give it a catalog panel. The
  onboarding exports had landed 21 minutes earlier, at IUX-036.
  **`IuxOnboardingFlow` is public API with no catalog coverage.**
- `IUX-PUBLISH-001` records "47 broken dartdoc references … that render as
  literal text on pub.dev". Both halves are true of different things: the
  `comment_references` lint reports 48 (47 `lib`, 1 `test`), while `dart doc`
  reports **4** unresolved references — those four are what actually renders as
  literal text. The remediation is four one-line fixes, not forty-seven.
- Two doc pages claimed a running button announces "In progress"; that literal
  was removed at IUX-008.6 precisely because it shipped English into every
  non-English application (IUX-008.9).

### Refused, and recorded rather than deferred

Accordion exclusivity and the group widget with it (IUX-035). A leading-glyph
parameter with no caller (IUX-035). Suggestions — `SemanticsRole.comboBox`
**throws** on Flutter 3.44.8, so a list could ship only with no role at all, and
a test pins the day that changes (IUX-034). The onboarding dot row: probed
first, and four decorated `Container`s produce a node with an empty label and
zero children, so it announces nothing (IUX-036). A four-rung proportionality
ladder, and any default undo window (IUX-032). A framework timeout, and a
debounce — one tuned to a fast typist fires after every character for a slow
one, and slow typists are disproportionately the screen-reader and
switch-access population (IUX-029, 030, 034). `prefer_is_empty`, because a
probe shows `assert(label.isNotEmpty)` in a `const` constructor fails, so the
lint would take `const` off every widget that refuses an empty label (IUX-040).

A guard making `IuxButton` refuse a confirmation policy it cannot honour was
**written, tested and reverted**, and the record kept so the next person does
not spend the same hour: it cannot be an initialiser assertion because the
constructors are `const`, and past that it breaks two legitimate callers.

### Known open

Twenty-two entries, **as of commit `80bdcc9`**. Four of them were being fixed by
other missions while this entry was being written — `IUX-EXPAND-CRASH-001`,
`IUX-A11Y-REACH-001`, `IUX-FORM-FOCUS-001` and `IUX-TRANSIENT-COVER-001` — so
check the evidence registry before relying on any of those four still being
open. The full text, with measurements, is in
`docs/evidence/semantic-tokens-and-accessibility.md`; the release argument is in
`docs/MISSION_042_RELEASE_CANDIDATE.md`. The ones that reach an end user:

- **`IUX-BUTTON-CONFIRM-001`.** `IuxButton(action:
  IuxActionDescriptor.destructive(...))` compiles, asserts nothing and runs
  `onActivate` on the **first tap** — measured, `runs == 1`. The `destructive`
  factory *defaults* to `IuxConfirmBeforeExecution`, so the trap sits on the
  shortest path a caller can write for a deletion. `IuxConfirmByHold` is worse:
  nothing anywhere honours it.
- **`IUX-A11Y-REACH-001`.** `IuxEmptyState` at 200% on a 320 px screen puts its
  only control at y 904–1008 against a 640 px fold, with **no scrollable on the
  page**; tapping yields zero activations. `IuxPermissionRationale` at **150%**
  lets the user refuse but not accept. The pilot showed the documented
  mitigation works — both sit inside `IuxPage`, which scrolls — so the defect is
  that nothing makes it the default.
- **`IUX-TRANSIENT-COVER-001`.** A notice pins over the bottom navigation and
  the layer reserves no space: on 360x800, notice at y 712–760, destinations at
  y 740–786, all three `hitTestable = 0` for a dwell of at least four seconds
  that by design cannot be shortened. The fix — transient layer *inside* the
  navigation, modal layer outside — is written in the pilot and nowhere in the
  framework.
- **`IUX-APPBAR-PAGE-001`.** Three defects in the most-repeated composition
  there is. The top inset is applied twice and nothing asserts. The chrome does
  not fit: on 320x640 at 300% the bar and navigation take 260 and 408 px and
  leave the content **−28**, because no component owns the total. And the
  standard fix is unavailable — `IuxAppBar` uses a `LayoutBuilder`, so no IUX
  screen containing one can take part in `IntrinsicHeight`.
- **`IUX-EXPAND-CRASH-001`.** Two stacked full-width buttons inside
  `IuxTargetSpacing` throw. The workaround gives up the 8 px target floor that
  `IuxTargetSpacing` exists to provide.
- **`IUX-SEARCH-RESULTS-001`.** The ready branch throws on an `IuxPage`, and the
  pattern hard-codes `IuxNoMatches`, so a collection that never held anything is
  reported as "no matches, clear the search" beside an empty box.
- **`IUX-OVERLAY-001`**, worse than previously recorded: opening a modal does
  not merely lose a scroll position, it **disposes** the panel that was scrolled
  to, so its callback throws `setState() called after dispose()`.
- **`IUX-FORM-FOCUS-001`.** An accepted submission arms an unbounded focus move,
  so a later blur check rips the caret into the summary. Needs a bounded
  pending-submission window, which is a decision.
- **`IUX-LISTITEM-TRAILING-001`.** `IuxListItem.tappable` with an
  `IuxStatusIndicator` overflows 68 px at 200% and 214 px at 300% on 320 px.
  Neither component overflows alone.
- **`IUX-A11Y-FOCUS-001` (partial)**, `IUX-DESTRUCTIVE-FOCUS-001`,
  `IUX-GUIDED-FORM-LIVE-001`, `IUX-PROGRESS-LABEL-001` (a 45% bar can announce
  "90%"), `IUX-RAIL-OVERFLOW-001`, `IUX-DRAWER-LABEL-001`, `IUX-SURFACE-001`.

Not defects but open all the same: `IUX-API-DEAD-001` (`importance` read by
zero call sites, `IuxElevation` an exported enum with no references),
`IUX-API-NAMING-001` (`summary` names three unrelated types;
`IuxInlineFeedbackAction` and `IuxTransientAction` are field-for-field
identical), `IUX-QA-VACUOUS-003`, `IUX-ONBOARDING-003`, `IUX-PERF-001`
(opening a keyboard rebuilds 106 elements against Material's 14, none of which
can change a pixel), and `IUX-PUBLISH-001`.

**The manual validation register is still empty.** No TalkBack, Voice Access,
physical keyboard, D-pad, on-device display scaling or platform high-contrast
run has been performed on hardware, at any point in forty-two missions. Every
accessibility claim in this changelog rests on widget tests.

## 0.1.0-dev.11 — IUX-025, 026, 027, 028

Navigation completed across three arrangements, plus the first of the
recovery patterns — and four corrections to work that was already committed.

### Added

- `IuxNavigationRail` and `IuxAdaptiveNavigation` (IUX-025). No breakpoint is
  adopted; the arrangement is decided by what each option leaves the content,
  with text scale as a term in the decision. Android's 600dp was considered
  and not taken, and the residual disagreement is logged as a hypothesis.
- `IuxNavigationDrawer` (IUX-027), and an `IuxModalLayer.drawer` slot to go
  with it. The three modals are now mutually exclusive by assertion.
- `IuxTabs` (IUX-026). Each tab carries `SemanticsRole.tab`, the strip carries
  `tabBar`, and Flutter enforces the rest itself.
- `IuxEmptyState` (IUX-028). Four situations, not one — nothing yet created, a
  filter that matched nothing, a search that matched nothing, and a permission
  that hides everything. The wrong situation/action pairing cannot be
  constructed.
- Two mechanical checks under `test/accessibility/`, each pinning a rule that
  had already failed once: a `Semantics` node declaring `button: true` must
  offer something to activate, and the framework may compose no string
  containing letters into a spoken property.

### Fixed

- **The drawer's own documented usage example broke accessibility silently.**
  `Stack(children: [page, if (open) drawer])` leaves the page element alive,
  so its semantics node is never recompiled and `BlockSemantics` does not
  remove the covered page — a screen reader goes on reading, and offering to
  activate, controls the user cannot touch. Touch is identical in both shapes,
  which is why nothing short of a screen reader catches it. The
  `IuxModalLayer.drawer` slot makes the working shape the only expressible
  one.
- **The rail's widest name always wrapped**, which is exactly what its
  documentation promised to prevent. `widthFor` measured the label style
  alone, while the rendered `Text` merges it over the ambient
  `DefaultTextStyle` and inherits a `letterSpacing` the typography theme never
  sets — 0.25px per character, and "Messages" needed 114px against 112.
- **The adaptive rule returned the worse arrangement on a landscape window**:
  at 640x320 at 300%, the rail leaves 286x320 and the bar leaves 640x0.
- **The display inset was applied twice**, and the documented workaround was
  worse than the bug, dropping the top inset and putting content under the
  status bar.

### Corrected

- `docs/components/bottom-navigation.md` argued for `checked` over `selected`
  on the grounds that `selected` is announced only when true. Measured on
  Flutter 3.44, `selected: false` yields `Tristate.isFalse` — explicitly
  present. The flags are tri-state and the two are indistinguishable
  framework-side. The choice stands on a narrower claim that is true:
  `checked` with `inMutuallyExclusiveGroup` says *one of these and only one*.
  What a screen reader speaks is a device question, untested on hardware, and
  is no longer asserted.

### Known open

- **IUX-A11Y-FOCUS-001.** `IuxSemantics.action` yields nodes with
  `isFocused: Tristate.none` and actions `[tap]`, where Flutter's own button
  yields `Tristate.isFalse` and `[tap, focus]`. Assistive technology cannot
  move accessibility focus onto an IUX control programmatically. This is the
  third thing `excludeSemantics` has silently deleted — it took `onTap` first.
  Deferred to IUX-038 rather than fixed mid-wave, because the fix lives in a
  helper every component depends on.

## 0.1.0-dev.10 — IUX-008.7, 012, 018, 023, 024

Two patterns, three components, and one runtime gap closed.

### Added

- **Destructive action pattern** (IUX-008.7) and **guided form pattern**
  (IUX-012) — the first two entries under `src/patterns/`.
- `IuxAppBar` (IUX-023): a title that is never abbreviated.
- `IuxBottomNavigation`, `IuxNavigationDestination` (IUX-024): every
  destination always named. No `labelBehavior`, no icon-only form. Above
  roughly 130% text the destinations stop sharing a row and stack as
  full-width glyph-beside-name, so a name gets 320px instead of 56.
- `IuxTooltip`, `IuxContextualHelp` (IUX-018): reachable by long press, focus
  and hover; dismissable, hoverable and persistent per SC 1.4.13, with no
  clock anywhere in the implementation. The 80-character boundary between a
  floating tooltip and in-flow help is asserted, not advised.
- `IuxSemantics.action` gains `expanded`, and `IuxSemantics.elaboration`
  carries the platform tooltip property. Both close deviations from component
  standard §2 that IUX-018 had to declare because the runtime had nowhere to
  put them — a disclosure whose state a screen reader never hears, and a
  tooltip message that reached no node at all.

### Fixed

- `test/iux_flutter_test.dart` asserted that only patterns remained
  unexported — an assertion invalidated by exporting patterns in IUX-008.7 and
  012. It has now narrowed twice, so it is replaced by the invariant that
  actually holds: every export belongs to a layer the component standard
  names.

### Deliberate deviations, argued

- Bottom navigation destinations tile the bar with no spacing between them,
  against `kIuxMinimumTargetSpacing`. A gap would be four dead strips in the
  thumb zone, and SC 2.5.8 treats spacing as an alternative to size — which
  64 x 112 clears outright.

## 0.1.0-dev.9 — IUX-010, 011, 014, 015, 016, 017, 019, 020, 021, 022

Ten components, plus the runtime helpers four of them needed.

### Added

- Text field, selection controls, inline alerts, transient messages, dialog,
  bottom sheet, card, list items, badges/chips/status, icons/avatars/images.
- `IuxSemantics.selection`, `.radioGroup`, `.field`, `.route`,
  `.contentAction`, `.contentContainer` — the helpers whose absence had forced
  four components to compose a bare `Semantics` and declare a deviation. All
  four deviations are now closed.
- `IuxInsets.keyboard` and `IuxInsets.windowHeight`. A view inset is a
  measurement, not a preference, so it belongs in the layout layer — and with
  it there, the bottom sheet needs no exception to the standard either.
- `IuxModalLayer` gains a `sheet` slot, with an assertion refusing a dialog and
  a sheet at once.

### Fixed

- **Every button was unusable with a screen reader.** `IuxSemantics.action`
  sets `excludeSemantics` to control the announced name, which also deleted
  the child gesture detector's tap action. Nodes announced a button and
  offered nothing to activate. Present since IUX-005; verified by probe
  (`actions: 0` → `1`) and locked by two regression tests.

### Known open

- `IUX-OVERLAY-001`: opening a modal resets the page's scroll position,
  measured at 400 → 0. The one-line fix breaks a working accessibility
  guarantee, so it stays open. See the evidence registry.


## 0.1.0-dev.8 — IUX-008.1 to IUX-008.3

Component standard, action model, button theme. Additive.

### Added

- The operative Component Standard, with nine of its prohibitions enforced by
  `test/components/component_standard_test.dart` rather than only written
  down.
- `IuxActionDescriptor` and its ten orthogonal dimensions;
  `IuxActionPolicy.evaluate`, which decides activation once and returns *why*
  a refusal happened.
- `IuxButtonTheme`, `IuxButtonTokens`, `IuxButtonResolver`,
  `IuxButtonStateResolver` — a seventh theme extension.

### Notes

The button contrast test caught `outlined` + `secondary` resolving to a white
label on a white surface (1.00:1). An intent's accent is not always in the
same role: primary and destructive carry it in `background`, secondary and
tertiary in `foreground`, because the semantic layer already models the latter
as unfilled. 152 variant × intent × state × profile combinations are now
measured.

Focus is deliberately not a button state: it must stay visible while pressed,
loading and showing a result.


## 0.1.0-dev.7 — IUX-007

Layout primitives. Additive.

### Added

- `IuxPage`, which composes with `Scaffold` rather than replacing it. Scrolls
  by default, because a screen that does not scroll breaks the moment text is
  enlarged or a keyboard appears.
- `IuxPageInsets`, four explicit safe-area modes. A boolean cannot express
  which edges a nested element already consumed, which is how double padding
  happens.
- `IuxSurface`, `IuxSection`, `IuxSectionHeader` — a section title is exposed
  as a screen-reader landmark, so the grouping exists for someone who cannot
  see the spacing that expresses it.
- `IuxTargetSpacing` and `kIuxMinimumTargetSpacing`, closing the gap IUX-005
  deferred: two touching 48-pixel targets still produce mis-taps.
- `IuxContentWidth` / `IuxReadableWidth`, with caps measured in characters and
  converted at the text size in force. A fixed pixel cap halves the characters
  per line when a user doubles their text.
- `IuxGap`, `IuxInsets`, `IuxLayoutClass`, `IuxBreakpoints`,
  `IuxResponsiveValue`.

### Notes

Control groups use `Wrap`, not `Row`: at a large text scale a row stops
fitting, and wrapping beats clipping a label the user cannot then read. A full
composition is tested at 320×480 with a 2x text scale.


## 0.1.0-dev.6 — IUX-006

Motion and feedback engine. **Breaking** for the minimal motion policy
introduced in IUX-005.

### Changed

- `IuxMotionRole` replaces `{essential, decorative}` with eight intent roles,
  each declaring how it adapts: shorten, simplify, preserve or remove.
  `reposition`, `reveal` and `conceal` become a fade rather than a faster
  movement — a fast large movement is worse than a slow one for a user prone
  to motion discomfort, not better.
- `IuxMotionPolicy.resolve` returns `IuxResolvedMotion` (was
  `IuxMotionDecision`), adding `behavior`, `prefersFade` and
  `requiresStaticAlternative`.
- Motion moved from `src/accessibility/` to `src/motion/`.

### Added

- `IuxFeedbackEvent` with named constructors, emitted explicitly by the
  parent. The runtime never infers that something succeeded or failed.
- `IuxFeedbackScope` / `IuxFeedbackController`, scoped rather than a global
  singleton, returning an `IuxFeedbackOutcome` per emission.
- `IuxHapticPolicy` mapping roles to patterns; `progress` never vibrates.
- `IuxFeedbackTheme`, a sixth theme extension, controlling channel
  permissions and the deduplication window.

### Notes

Only `error` and `destructive` interrupt a screen reader. Interrupting for a
success trains users to turn announcements off, at which point failures stop
being heard too.


## 0.1.0-dev.5 — IUX-005

Accessibility runtime. Additive.

### Added

- `IuxAccessibility.of(context)` — the single place where the application's
  requested profile is reconciled with the platform's reported preferences.
  Closes the gap IUX-004 left explicit via `respectsPlatformPreference`.
- `IuxMotionPolicy` — a component states what an animation is *for*
  (`essential` or `decorative`) and is told whether it runs.
- `IuxTapTarget` — guarantees the interactive floor without enlarging the
  visual element; `minimumSize` can only raise it.
- `IuxFocusRing`, `IuxFocusable`, `IuxFocus` — visible focus that reserves its
  space, keyboard activation, and focus restoration for future overlays.
- `IuxSemantics`, `IuxAnnouncement`, `IuxReadableText`.
- `IuxInterpolation`, extracted from the foundations.

### Changed

- `IuxSemantics.action` takes a nullable `selected`. Passing `false` would
  advertise a selected state on a control that does not toggle.
- The catalog labels each preference chip by dimension *and* value: several
  dimensions share a value, so a chip labelled only "comfortable" was
  ambiguous to a screen reader.

### Notes

`IuxAnnouncement` prefers `IuxSemantics.liveRegion` and says so. Android has
deprecated `announceForAccessibility` because it clears TalkBack's speech
queue, cutting off the user.


## 0.1.0-dev.4 — IUX-004

Accessible theme engine. Additive.

### Added

- `IuxTheme.light()` / `IuxTheme.dark()` returning `ThemeData` directly, with
  an optional `IuxAccessibilityProfile`.
- `IuxThemeConfiguration` (the request) and `IuxResolvedTheme` (the result),
  deliberately separate.
- Four `const` colour mappings: light and dark, each in standard and high
  contrast. **High contrast is now reachable in dark conditions** — the
  previous theme forced `Brightness.light`, leaving users who need both
  without an option.
- Theme extensions `IuxTypographyTheme`, `IuxGeometryTheme`, `IuxMotionTheme`,
  `IuxAccessibilityTheme`.
- `IuxVisualStimulation` and `IuxMotionPreference.standard` in the
  foundations; `IuxAccessibilityProfile` gains `visualStimulation`, equality
  and three named constructors.
- A theme explorer in the catalog covering every profile, text scale and long
  labels.

### Changed

- `ColorScheme` is derived from IUX roles (ADR-0002), and `surfaceTint` is
  disabled: Material 3's elevation tint would move surfaces away from the
  measured values.
- High contrast thickens outlines and the focus ring rather than only
  recolouring them.

### Notes

Two invariants worth knowing: density never reduces the minimum touch target,
and the target never dips below the floor mid-transition. Reduced motion
shortens durations while `none` removes them.

## 0.1.0-dev.3.1 — IUX-003.1

Remediation of the semantic layer. This release is **breaking** for the API
introduced by IUX-003. No published consumer exists (`publish_to: none`).

### Removed

Out-of-scope code that pre-empted later missions, along with its exports:

| Removed | Recreated by |
| --- | --- |
| `IuxButton` | IUX-008.4 |
| `IuxTextField`, `IuxCheckbox`, `IuxSwitch` | IUX-010, IUX-011 |
| overlay placeholders | IUX-016 to IUX-018 |
| `IuxLoadingState`, `IuxErrorState`, `IuxEmptyState` | IUX-028 to IUX-030 |
| `IuxSurface`, `IuxSection` | IUX-007 |
| `IuxActionDescriptor` and action enums | IUX-008.2 |
| `IuxAccessibility` | IUX-005 |
| `IuxFeedback`, `IuxMotionPolicy` | IUX-006 |
| `IuxTheme`, `IuxThemeProfile` | IUX-004 |

`IuxSemanticColors.fromColorScheme` is removed. It inverted the dependency by
placing the source of truth in Material, where IUX cannot verify contrast. See
ADR-0002.

### Changed

- `IuxSemanticColors` becomes a composition of six role groups — `content`,
  `surface`, `border`, `action`, `feedback`, `state` — instead of ten flat
  `Color` fields.
- `IuxSemanticColors.of` now throws a diagnosable `FlutterError` when no IUX
  theme is installed, instead of silently substituting colours derived from the
  ambient `ColorScheme`. `maybeOf` returns null for callers where absence is
  legitimate.

### Fixed

- `IuxSemanticColors.copyWith` accepted only `contentPrimary`, silently
  discarding every other role. It now covers the whole contract, and a
  regression test asserts it.

### Added

- Role groups: `IuxContentColors`, `IuxSurfaceColors`, `IuxBorderColors`,
  `IuxActionColors` / `IuxActionColorSet`, `IuxFeedbackRoleColors` /
  `IuxFeedbackColorSet`, `IuxStateColors` — each with `copyWith`, `lerp`,
  equality and hash code.
- An internal primitive palette, deliberately not exported.
- A contrast measurement helper, confined to `test/`.
- A contrast contract test matrix covering both demonstration mappings.
- A catalog that presents every role group, switches between light and dark
  mappings, and includes a single-hue check for colour-only signalling.
- Documentation: six role documents, contrast contracts, colour and non-colour
  signals, ADR-0002, and an evidence registry.

## 0.1.0-dev.1

- Initialized the IUX repository structure.
- Added the experimental `iux_flutter` package and local catalog integration
  surface.
