# ADR-0007: Layout primitives

- Status: accepted
- Date: 2026-08-03
- Mission: IUX-007

## Context

Components need a shared skeleton. Without one, every screen re-derives its
padding, its width cap and its safe-area handling, and they diverge — usually
in the direction of "correct on the reviewer's device".

The question is how much to take over from Flutter.

## Decisions

### 1. `IuxPage` composes with `Scaffold`, it does not replace it

`Scaffold` owns app bars, sheets and the snack bar host. A page primitive that
swallowed it would have to re-expose all of that, badly, and would fight every
Flutter package that expects a `Scaffold`.

### 2. Scrolling is on by default

A screen that does not scroll breaks when text is enlarged or a keyboard
appears. Defaulting to scrollable makes the resilient case the one you get
without thinking about it.

### 3. Safe areas are opt-in per edge

Four explicit modes rather than a boolean. The failure being prevented is
double padding, which a boolean cannot express: the page and a sheet inside it
both need to know which edges the other consumed.

### 4. Reading width is measured in characters, not pixels

A fixed pixel cap halves the characters per line when text doubles. Expressing
the cap in characters and converting at the text size in force keeps the line
length constant, which is what the cap was for.

The conversion is crude — roughly half the font size per character — and
deliberately generous. Measuring precisely would need the actual font, and
being slightly wide is safer than clipping.

### 5. Spacing between targets is a primitive, not a guideline

`IuxTargetSpacing` enforces the floor and cannot be configured below it. A
guideline in a document is followed until someone is in a hurry.

### 6. `Wrap` rather than `Row` for control groups

At a large text scale a row of controls stops fitting. Wrapping to a second
line is better than clipping, and better than shrinking below the target floor.

## Alternatives considered

**A full `Scaffold` replacement.** Rejected: reimplements Flutter surface area
for no gain and breaks package interoperability.

**A boolean `safeArea` flag.** Rejected: cannot express which edges a nested
element already consumed.

**Pixel-based width caps.** Rejected: breaks under text scaling, which is the
case the caps most need to survive.

**Web-style breakpoints.** Rejected: three Android window size classes are
enough, and a finer scale invites per-device tuning.

**A layout DSL.** Rejected: `IuxResponsiveValue` covers the branching that
actually occurs; anything more becomes a language to learn.

## Consequences

Positive:

- narrow screens and enlarged text are the tested default, not an afterthought;
- the target-spacing floor cannot be configured away;
- visual, semantic and focus order agree by construction.

Negative:

- `IuxPage` scrolls by default, which is occasionally not wanted and must be
  turned off explicitly;
- the character-to-pixel conversion is approximate and wrong for CJK;
- `Wrap` cannot express "these two must stay on one line", which some designs
  will want.

## Risks

- **Nested `IuxPage` producing double padding.** Documented; not detected.
- **The character estimate being wrong for non-Latin scripts.** Recorded as a
  hypothesis in the evidence registry.
- **`Wrap` reordering under RTL.** Flutter handles direction, but the
  combination with a large text scale has not been tested on device.
