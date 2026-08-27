# Manual validation protocol — the session B12 has been waiting for

Everything this repository claims about accessibility is measured on Flutter's
semantics tree inside `flutter_test`. That is a model of what an assistive
service would be *told*. This protocol checks what it actually *does*.

**Why it is not a formality.** The library shipped **no icons at all** for weeks
— `uses-material-design` was undeclared, so every Material glyph rendered blank
— while 1976 tests passed over it, because `flutter_test` substitutes a font
that draws every glyph as a filled box whatever the pubspec says. No test here
could have caught it. Someone holding a phone caught it immediately.

## What this protocol deliberately does not test

Time on a device is expensive, so nothing here re-checks what a widget test
already settles. **Do not** spend the session verifying that labels exist, that
roles are set, that a control is 48 dp, or that contrast ratios hold — those are
pinned, measured and re-measurable for free.

What only a device settles is the list below: what the platform *composes* from
the tree, what it *reads out loud*, in what *order*, and whether the user's own
system settings survive contact with the framework.

## Setup

```bash
# from the repository root, phone connected and USB debugging authorised
adb devices                       # must list the phone before anything else
cd apps/catalog && flutter install
cd ../pilot && flutter install    # a real screen beats a harness for reading order
```

Install **debug** builds. The catalog's semantics readout only works in debug and
profile (`RenderObject.debugSemantics` returns null in release), and every
refusal in the library is an `assert`, so a release build has none of them.

On the phone: Settings → Accessibility → **TalkBack**, **Voice Access**,
**Colour inversion**, and Settings → Display → **Font size** and **Display
size**. Learn the TalkBack shortcut (usually holding both volume keys) before
starting — turning it off from inside TalkBack while a modal is open is
genuinely awkward.

## How to record a result

Every check has an ID. Report only what **fails or surprises you** — silence
means pass. Say the ID, what you did, and what happened, in your own words. I
will write the register entry, the evidence entry and the defect ID.

A failure is worth more than a pass here. If something reads oddly but you
cannot say why, say that too: "it said the thing twice and I do not know which
one was real" is a usable observation and has found defects in this project
before.

---

# Block A — TalkBack (the one to do if you do only one)

Roughly 20 minutes. This is where the framework's central claim lives.

### A1 — The icons are really there
**Do:** open the catalog, TalkBack off. Go to **Media and status**, then
**Inputs**.
**Expect:** every glyph, checkbox mark and radio mark is drawn. Checked and
unchecked look different.
**Fail:** blank squares, or a checked option indistinguishable from an unchecked
one. This is the exact defect that shipped invisibly; it is first because it
costs ten seconds.

### A2 — A button announces itself once, and completely
**Do:** TalkBack on. **Buttons** section. Swipe through the emphasis grid.
**Expect:** one utterance per control — name, then "button". No duplicate name.
No stray "double tap to activate" on something that does nothing.
**Fail:** the same label twice, a control announced with an empty name, or a
control TalkBack skips entirely.

### A3 — A busy button is not called unavailable
**Do:** **Buttons** → the async panel. Start an action and swipe onto the button
while it runs.
**Expect:** it stays reachable and is *not* announced as disabled. The busy
state is a **word**, not a spinner — this library refuses to represent it by
motion alone.
**Fail:** "disabled", "dimmed", or the control dropping out of the swipe order
while running.

### A4 — The page behind a modal is genuinely gone
**Do:** **Overlays** → open the dialog. With it open, swipe **left repeatedly**,
past the first element, and keep going.
**Expect:** you reach only the dialog's own content and cannot escape into the
page behind it. Same for the bottom sheet and the drawer.
**Fail:** you land on anything from the page underneath.
**Why it matters most here:** this exact claim was measured wrongly once and
kept a crash open for fifteen missions. Widget tests now say the page is absent
from the live semantics tree. TalkBack is the only thing that settles it.

### A5 — A row whose status moved below the text is still two targets
**Do:** **Cards and lists**. Set the phone's font size to its largest, return,
find a row carrying a status.
**Expect:** the row and its status read as **two** stops, in that order — not as
one run-on sentence, and not with the status orphaned somewhere else.
**Fail:** the status is read as part of the row's title, or it becomes
unreachable.
**Status:** the geometry is asserted; how it *reads* is an open hypothesis.

### A6 — A read-only field is not a disabled one
**Do:** **Inputs** → the text-field panel. Swipe onto the read-only field, then
the disabled one.
**Expect:** they are distinguishable — one you may focus and copy from, one you
may not use at all.
**Fail:** identical announcements. **Expected to be imperfect:** Android
resolves `readOnly || !enabled`, so a *disabled* field also publishes
`isReadOnly`. Tell me the two exact sentences; the point is to learn what
TalkBack says, not to be surprised.

### A7 — The validation summary actually takes you to the field
**Do:** **Forms**. Submit with fields empty. Swipe to the error summary, activate
an entry with a **double tap**.
**Expect:** focus lands **on the field named**, which announces itself. For the
radio group it should land on the **first option** — "…, radio button, not
checked, 1 of 2" or similar.
**Fail:** focus stays on the summary, jumps to the page top, or lands somewhere
silent.
**Note:** this is the defect where focus previously did not move *at all*, so
this check is a direct verification of a fix from this week.

### A8 — Two things do not talk at once
**Do:** **Forms** → the guided form. Move between steps, and submit a step with
an error.
**Expect:** you hear one thing. Either the step heading or the error, not both
overlapping, and nothing cut off mid-word.
**Fail:** overlapping speech, or an announcement that never arrives.
**Status:** `IUX-GUIDED-FORM-LIVE-001` is open against exactly this — a live
region firing in the same frame as a focus move. Expect a defect; describe it.

### A9 — A transient message is heard, and does not steal the screen
**Do:** **Overlays** → trigger a transient message. Also try it while swiping.
**Expect:** it is announced without moving your place in the reading order, and
it does not cover the navigation.
**Fail:** your position is reset, or the message interrupts and is then lost.

### A9b — The Announcements sample can actually be pressed
**Do:** **Runtime** → the Announcements panel. TalkBack on, swipe onto the
**Refresh** control and double-tap it.
**Expect:** it announces as **"Refresh results"** — the accessible name, longer
than the visible word, which is allowed because the visible word is contained in
it (SC 2.5.3) — and the double-tap produces the announcement the panel exists to
demonstrate.
**Fail:** TalkBack says "button" and the double-tap does nothing.
**Status:** this is `IUX-TAPTARGET-ACTION-001`, fixed but **never heard**. Until
the fix this control was announced as a button and offered no action at all, so
the one sample in the whole harness about announcements could not be exercised
by anyone unable to use a pointer. It is composed of `IuxFocusable` over
`IuxTapTarget`, so Enter and Space *did* work throughout — which is why nothing
looked broken from a keyboard, and why a screen reader is the only thing that
could have found it. The tree now says the action is there; whether a screen
reader performs it on hardware is what no test here can answer.

### A10 — Progress says something true
**Do:** **Feedback** → the progress panel. Swipe onto a determinate bar.
**Expect:** the announced percentage matches the drawn bar.
**Fail:** any disagreement. (A debug assert now catches the obvious case; this
checks what is actually spoken.)

---

# Block B — Voice Access

Roughly 10 minutes, and it tests something no other mechanism does: whether the
name a user **says** matches the name they **see**.

### B1 — Say what you see
**Do:** Voice Access on, catalog open at **Buttons**. Say the visible label of a
control: "tap Save".
**Expect:** it activates.
**Fail:** nothing happens, or the wrong control fires.

### B2 — Icon-only controls
**Do:** **Navigation** and **Media and status**. Try to activate an icon-only
control by name, then by the number Voice Access overlays.
**Expect:** it has a usable spoken name.
**Fail:** it is reachable only by number. An icon-only control with no name is
a control a Voice Access user cannot ask for.

### B3 — Numbers are not the only way in
**Do:** turn on "Show numbers" and count how many controls are reachable *only*
by number across two sections.
**Report:** the count, and which ones.

---

# Block C — Physical keyboard and D-pad

Roughly 10 minutes. Needs a Bluetooth or USB keyboard.

### C1 — Nothing traps focus
**Do:** Tab all the way through a section. Open the dialog, the bottom sheet and
the drawer, and Tab in each.
**Expect:** focus cycles inside the modal and, on dismissal, returns to the
control that opened it.
**Fail:** focus escapes to the page behind, or you cannot leave without touching
the screen.

### C2 — Every stop is visible
**Do:** Tab slowly through **Forms** and **Inputs**.
**Expect:** a visible focus ring, drawn *outside* the control, at every stop.
**Fail:** any stop where you cannot tell what has focus. The ring is deliberately
outside the control, so a ring that is clipped or hidden is a real defect.

### C3 — Enter and Space
**Do:** focus a button, press Enter; focus a checkbox, press Space.
**Expect:** both activate.
**Fail:** either is inert. (`IuxFocusable` answers Enter and Space; whether the
platform also expects a tap action here is an open question.)

### C4 — Cancelling returns you somewhere sensible
**Do:** **Flows** → the destructive flow. Open the confirmation, cancel it with
the keyboard.
**Expect:** focus returns to the trigger, not to the page root.

---

# Block D — On-device display scaling

Roughly 10 minutes. Android's font size **and** display size are two separate
settings, and neither is identical to the `textScaler` used in tests.

### D1 — Largest font size, every section
**Do:** Settings → Display → Font size to maximum. Walk all thirteen catalog
sections.
**Expect:** nothing clipped, no text cut off, every control still reachable.
**Fail:** note the section and the panel.

### D2 — Largest display size *and* largest font
**Do:** both to maximum. Repeat on **Navigation**, **Forms** and **Cards and
lists**.
**Expect:** the navigation switches arrangement rather than overflowing.
**Fail:** overflow stripes, or a control off screen.

### D3 — The pilot, not the harness
**Do:** open the pilot app at both settings maximum. Create a job.
**Expect:** the whole task is completable.
**Fail:** anywhere you cannot finish. This is the check with the most weight,
because it is a real screen rather than a demonstration.

---

# Block E — Platform contrast and colour inversion

Roughly 5 minutes, and it is the least-explored corner of the whole project.

### E1 — Colour inversion
**Do:** Settings → Accessibility → Colour inversion on. Open the catalog at
**Theme**, then **Buttons**.
**Expect:** text stays legible and controls stay distinguishable.
**Fail:** anything that becomes unreadable. **Expect trouble:** inversion
recomposites the whole screen *after* IUX has resolved its palette, so the
contrast ratios this project measures are not the ratios you will see. This has
never been looked at.

### E2 — Inversion plus the library's own high contrast
**Do:** with inversion still on, switch the catalog's own profile to high
contrast in the **Theme** section.
**Expect:** ideally better, or at least not worse.
**Fail:** two mechanisms fighting — a "high contrast" that inverts into a lower
one. Two separate systems both claiming the same job is exactly where this
breaks.

### E3 — Dark mode plus inversion
**Do:** system dark mode on, inversion on.
**Report:** whether anything is legible at all.

---

# Block F — What shipped after this protocol was written

Roughly 10 minutes, and it is different in kind from the blocks above. Those
check whether the platform does what the tree says. **These five check
judgements** — decisions taken on a measurement that a measurement cannot
finish, each one recorded in the register as resting on an eye nobody has yet
applied.

Six changes landed on 2026-08-27 from a real migration. Every one of them was
argued from numbers, and five left a question a number cannot close.

### F1 — The warning colour reads as a warning
**Do:** **Feedback** → the inline feedback panel, light theme, standard
contrast. Look at the warning block beside the error block.
**Expect:** the warning reads as a warning — an orange — and is not confusable
with the error red at a glance.
**Fail:** it reads as a brown or a khaki, or you have to think about which of the
two is which.
**Status:** `IUX-PALETTE-HEADROOM-001`. The caution ramp's dark end changed hue
because a yellow held above 4.5:1 on white stops being a yellow. `#A34A00`
measures 5.94:1 and was chosen by a consuming application that shipped it. **That
it reads as a warning is a judgement about perception that nothing in this
repository tests**, and hue is exactly where a contrast ratio says least.

### F2 — Reinforced contrast now returns something you can see
**Do:** **Theme** → light, then switch the profile to high contrast. Watch the link, and
the four feedback blocks.
**Expect:** a difference you would notice without being told to look.
**Fail:** no perceptible change.
**Status:** the same entry, and the structural half of it. The standard profile
used to sit past AAA on every chromatic content role, leaving `highContrastLight`
one rung — so the setting whose whole purpose is separation returned almost
nothing. Standard now stops short of AAA on purpose. Whether that reads as
*enough room* is the question.

### F3 — A chip without its checkmark is still findable in monochrome
**Do:** **Media and status** → the row titled *the same chips without the
reserved slot*. Turn on Android's monochrome colour correction
(*Settings → Accessibility → Colour correction → Greyscale*) and find the
selected chip.
**Expect:** you can, from the outline weight alone.
**Fail:** you cannot tell without colour.
**Status:** `IUX-CHIP-WIDTH-001`, and **this is the check that could send a
default back**. `IuxChipMark.outline` gives up the glyph to buy width — four
short chips go from two lines to one — leaving the fill, the outline weight and
the announcement. Weight is not colour, so SC 1.4.1 holds. But it is a quieter
signal than a glyph appearing, **and quieter for exactly the users the glyph was
put there for**. Compare against the standard row directly above it.

### F4 — A shared-line radio group is still hittable with a thumb
**Do:** **Inputs** → *a radio group on one line*. Tap each of the four options
in turn, quickly, with a thumb rather than a fingertip. Then TalkBack on, and
swipe through them.
**Expect:** no mis-taps. Each option announces its position — "1 of 4" — inside
the named group, exactly as the stacked arrangement does.
**Fail:** you hit a neighbour, or the position is missing on a shared line.
**Status:** `IUX-RADIO-LAYOUT-001`. `kIuxMinimumTargetSpacing` was deliberately
kept on this arrangement, against what the reporting application did, because a
shared line is where fingers are closest together. A mis-tap here says that
decision was not conservative enough.

### F5 — The brand mark at the largest font size
**Do:** **Navigation** → the app bar panel, set the *Heading* choice to
**mark**. System
font size at maximum. Then TalkBack on, and swipe onto the bar.
**Expect:** the title, the controls and everything else grow; **the mark does
not**. TalkBack announces the screen's name as a heading and says nothing at all
about the mark.
**Record either way:** whether the result is acceptable, or whether at that scale
the text title is the only honest answer.
**Status:** `IUX-APPBAR-BRAND-001`. That a mark ignores the text scale is a
documented cost, not a defect — the bar hands it a box and what is inside is the
caller's. The documentation says "where the name has to be legible at 200%, pass
no mark". **Nobody has looked at what that actually costs a user**, and this is
a judgement to record rather than a box to tick.

---

## What would change the release verdict

Not "everything passes". The verdict changes when the register **stops being
empty** — when there is a recorded session with real results, failures included.
A protocol run with six defects found is worth far more than one that finds
none, because this project has never had a single observation from outside its
own test harness.

The two results that would matter most:

1. **A4** — because a wrong measurement of that exact claim kept a crash open
   for fifteen missions, and the correction is a week old.
2. **D3** — because a real task on a real screen at a real accessibility setting
   is the closest thing to the user this project exists for.

And one that would change a **default** rather than the verdict: **F3**. If a
chip's selection cannot be found in monochrome without its checkmark, then
`IuxChipMark.outline` is buying width with a signal it should not be spending,
and the entry that introduced it says so in advance.
