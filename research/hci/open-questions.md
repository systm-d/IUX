# Open questions — HCI

Five numbers this framework enforces today on an argument alone.

Each is a real decision with real consequences, each is currently defended by
reasoning rather than by evidence, and each is written up here so that the
reasoning is visible and the work that would settle it is named. None of the
leads below has been read by anybody working on this repository; they are
marked accordingly, and `research/README.md` says why that distinction is held
so firmly.

They are ordered by how much a wrong answer costs a user.

---

## Q1 — A transient message is given 4 seconds, then 10 characters per second

**As implemented.** `IuxTransientTiming.minimum = Duration(seconds: 4)` and
`IuxTransientTiming.charactersPerSecond = 10`, in
`packages/iux_flutter/lib/src/components/transient/iux_transient_timing.dart`.
The dwell is `max(4s, runes / 10)`, with no ceiling.

**What supports it today.** An argument, and a good one. The source comments it
out loud: 10 characters per second is roughly 120 words per minute for Latin
text, "about half the average adult silent reading rate", and the halving is
deliberate — the average is measured on somebody reading on purpose, and this
component's reader is doing something else at the time. The cost asymmetry is
also argued: a message that overstays is irritating, one that leaves early was
never read.

Note what is *already* strong here and does not depend on this question at all.
The component removes the timer entirely when there is an action, and when a
screen reader is expected; `IuxTransientTone` has no `error` and no `warning`,
so nothing that matters can be put under a clock in the first place. WCAG 2.2
SC 2.2.1 is satisfied by those mechanisms, not by the number. **This question is
about comfort, not conformance**, which is exactly why it belongs here.

**What is unsupported.** The word "average". Nobody here has read a reading-rate
study. Neither the baseline nor the halving factor is measured, the 4-second
floor is a round number, and the model is linear in characters when the fixed
cost the comment describes — noticing, saccading to the corner, orienting — is
the part that does not scale with length at all. A two-word message and a
twenty-word message plausibly differ by less than the formula says.

**What would settle it.**

1. Read a reading-rate meta-analysis and record the figure *with its task*:
   silent reading of prose for comprehension is not glancing at a corner.
2. Decide whether the fixed cost deserves to be a separate term. The current
   model is `max(floor, length/rate)`; the shape the comment actually describes
   is `orient + length/rate`. Those differ most for short messages, which are
   the common case.
3. Measure the orienting cost, or find it measured. This is the number that
   matters and the one nothing in the repository even estimates.

**If the answer went the other way**, the floor would rise and the rate would
stop being the interesting parameter. That is a real code change, so the
question is worth asking.

**Leads (unverified).**

- Brysbaert, M. (2019), *How many words do we read per minute? A review and
  meta-analysis of reading rate*, Journal of Memory and Language. Expected to
  give a defensible baseline for silent reading — and, more usefully, the
  spread and the task dependence.
- The `IuxTransientTiming` doc comment's own claim that Material's defaults are
  shorter than IUX's in both lengths. That is checkable against Material's
  specification today and nobody has checked it.

---

## Q2 — Reading width is capped at 60–75 characters

**As implemented.** `IUX-LAYOUT-002`, level *hypothesis for the counts, strong
guidance for the principle*. Source line, verbatim: **"long-standing
typographic guidance on 60–75 characters per line"**. The cap converts to
pixels at the text size in force, deliberately generously, using half an em per
character.

**What supports it today.** Tradition, named as tradition. The register is
already honest about this and grades it accordingly, which is why this file
exists to do the work rather than to correct the grade.

**What is unsupported.** Everything numeric. Where the range comes from, what
it was measured on (print, almost certainly), whether it transfers to a phone
held at 30 cm, and whether the cost of exceeding it is measurable at all at
phone widths — where the constraint usually binds in the other direction, the
column being too narrow rather than too wide.

**What would settle it.** Establish whether the 60–75 range has an empirical
basis distinct from typographic convention, and if so what outcome it optimises
— reading speed, comprehension, or preference, which do not agree. Then check
whether it binds at all on the widths IUX actually meets. A rule that never
fires on a phone is a rule that costs nothing and proves nothing, and it should
be documented as applying to tablets and windowed sessions only.

**If the answer went the other way**, the cap would become width-class
conditional instead of universal.

**Leads (unverified).**

- Tinker, M. A., *Legibility of Print* (1963) — the usual origin cited for line
  length work; measured on print, which is the limitation to record.
- Dyson, M. C., work on line length and reading from screen. Screen rather than
  print, which is the transfer this question turns on.
- The half-em-per-character conversion is a separate, smaller, *testable*
  question: measure it against the shipped font rather than assuming it, and it
  stops being a hypothesis in an afternoon.

---

## Q3 — An app bar takes at most 3 actions

**As implemented.** `kIuxAppBarMaximumActions = 3`, in
`packages/iux_flutter/lib/src/components/appbar/iux_app_bar.dart`, enforced by
an assertion — a fourth action throws in debug rather than being advised
against.

**It has no register entry at all.** `IUX-APPBAR-001` through `-003` cover the
title, the widget type and the inset; the action limit is argued only in a doc
comment. **This is the most enforced unregistered number in the framework**,
and finding that is half the value of writing this file.

**What supports it today.** A width argument, which is sound and is not the
argument the number is usually defended with: an app bar is the narrowest strip
in an application, every action in it is an unlabelled glyph, and each one takes
width from the only thing on screen that says where the user is. Note that this
argument would justify a *measurement* — the width available minus the title's
minimum — rather than a constant.

**What is unsupported.** Three specifically. Not two, not four. The doc comment
says a fourth action is "the point at which the bar stops being a place to look
and becomes a place to search", which is a claim about visual search and is
precisely the kind of claim `research/` exists for.

**What would settle it.** Either of two routes, and they lead to different code:

1. **Treat it as a search-cost question.** Find whether search time over a small
   set of unlabelled glyphs has a knee, and where. If it does not — if the cost
   is smooth — then a hard assertion at 3 is arbitrary and should be a lint or a
   documented recommendation, not a throw.
2. **Treat it as a width question**, which is what the doc comment actually
   argues. The bar already measures itself (`_RenderIuxAppBarArrangement`), so it
   could refuse the action that would take the title below its readable floor
   instead of counting to three. That is strictly better: it is right on a
   tablet and right on a 320-pixel phone, and the two are not the same number.

Route 2 needs no literature and is available now. **That it was never taken is
the finding.**

**Leads (unverified).**

- Hick, W. E. (1952) and Hyman, R. (1953), on choice reaction time. Note that
  the register already cites Hick twice to argue *against* naive application —
  the law concerns choice among known alternatives, not visual search among
  unlabelled glyphs, and the distinction matters here.
- Visual search literature (feature versus conjunction search) is the better
  fit and is entirely absent from this repository.

---

## Q4 — Enlarged text reflows above roughly 1.3×

**As implemented.** `IUX-RUNTIME-006`, level *hypothesis for the threshold,
standard for the principle*. Above about 1.3×, `IuxReadableText` drops its line
limit and lets overflow become visible.

**What supports it today.** The principle is settled by WCAG 2.2 SC 1.4.4:
truncating enlarged text defeats the reason the user enlarged it. The register
says so and grades the principle `standard`.

**What is unsupported.** The threshold, and the register says that too — "a
heuristic chosen from common phone widths, not a measured value".

**What would settle it.** This one probably needs no literature at all, and
that is worth stating: it is a **measurement against the widths IUX supports**,
which is a test somebody could write this week. For each supported width and
each text scale, does a representative label still fit within its line limit?
The threshold is then the scale at which it stops fitting on the narrowest
supported width, which is a fact about the framework rather than about people.

**Why it is here rather than in the register.** Because the reason the number
was never measured is that nobody framed it as measurable. It is the cheapest
of the five and it has sat at `hypothesis` the longest.

**If the answer went the other way**, the threshold would become width-derived
rather than constant — the same shape as the better answer to Q3.

---

## Q5 — Reduced visual stimulation is a comfort setting, not an accommodation

**As implemented.** `IUX-THEME-009`, level *hypothesis*, source line: **"none;
no standard defines this preference"**. It flattens elevation and suppresses
decorative motion; colours, contrast and type sizes are asserted identical to
the standard profile.

**What supports it today.** A design decision and a governance one. IUX-THEME-010
refuses to name any preference after a population or a diagnosis, which is why
this is not called anything clinical — and that refusal is defensible
independently of whether the preference helps anybody.

**What is unsupported.** That it helps anybody. The register says outright it is
"not validated with users" and asks that it be treated as a hypothesis. It is
also **not clearly distinct from `reducedMotion`**, which users can already ask
for through a platform setting: if the perceived difference between the two
profiles is elevation alone, this preference is a shadow of one that already
exists, with a settings surface IUX does not have.

**What would settle it.** Two things, and the first is nearly free:

1. **A difference audit.** Render the same screens under `standard` and under
   reduced stimulation and diff what actually changes. If the answer is
   "shadows", the honest move is to fold it into the motion preference and
   delete a profile. This is a golden-image test, not research.
2. Only if a real difference survives (1): whether it corresponds to anything a
   user reports.

**Leads (unverified).**

- WCAG 2.2 SC 2.3.3 *Animation from Interactions* (AAA) and the
  `prefers-reduced-motion` platform preference — the neighbouring settled
  ground, and the thing this preference must be shown to differ from.
- Vestibular-disorder literature is the usual justification for reduced motion
  and is a poor fit here, because IUX explicitly declines to present this as an
  accommodation. Recorded so the next person does not reach for it.

---

## What is deliberately not here

**Anything the register already grades `standard`.** Seventy-four entries rest
on a WCAG success criterion or a platform guarantee, and re-deriving those from
first principles would be work with no decision at the end of it.

**Cognitive load in general.** `PROJECT_PROMPT.md` §17 states good principles —
fewer decisions, fewer steps, fewer simultaneous items — and **no component is
anchored to a measurement of any of them**. That is a real gap and it is
deliberately not framed as a question here: "reduce cognitive load" is not
answerable, and breaking it into questions that are is itself the next piece of
work. Q1 and Q3 are two such fragments. There will be more.
