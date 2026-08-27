# Open questions — perception

`research/hci/open-questions.md` covers five numbers this framework enforces on
an argument alone. These three are different in kind: they are numbers the
framework **measures correctly by the standard it cites**, and which a second
instrument says are wrong anyway.

They come out of `IUX-PALETTE-PERCEPTION-001`, which measured the shipped
palette with APCA, Oklab and dichromacy simulation. That entry holds the
numbers; this file holds what is still unanswered about them.

As in the HCI file: none of the leads below has been read by anybody working on
this repository, and they are marked accordingly.

---

## P1 — WCAG 2.x contrast is polarity-blind, and IUX ships two polarities

**What was measured.** `border.standard` is tuned to 3.67:1 in the light
standard profile and 3.65:1 in the dark standard profile. Under APCA the same
pair of ratios delivers Lc 64.3 and Lc 27.2. The ratio is symmetric by
construction; perception is not, and the divergence is a factor of 2.4 on a role
governed by a success criterion.

**What is settled.** That the two metrics disagree, and by how much on this
palette. Also that they *agree on ordering* inside a single polarity, in all
four profiles — so reading ratios remains a sound way to rank a palette, and an
unsound way to compare a light role against a dark one.

**What is unsupported.** Which one is right. APCA is a candidate method for
WCAG 3 and has not been adopted; its thresholds (Lc 30 for a solid non-text
element, 45 for a fine line, 75 for body text) are recalled here from secondary
circulation and reproduced by no instrument in this repository. A framework
cannot conform to a metric that is not yet a standard, and conformance is not
optional — so the question is not "switch" but **what a second, non-normative
instrument is allowed to do to a palette that already conforms.**

**What would settle it.**

1. Read the APCA readability criteria and record the thresholds *with their
   conditions* — they are stated per font size and weight, and quoting a single
   number for "body text" is already a simplification this repository has made.
2. Decide the governance question, which is the real one: is APCA an advisory
   second opinion that raises a question, or a floor a role must clear before it
   ships? The first is cheap and changes nothing today. The second is a palette
   re-tune and needs Finding 2 below settled first.
3. Check whether WCAG 3 / silver has moved. This was written 2026-08 and the
   answer may simply exist.

**If the answer went the other way**, the dark profiles get re-tuned across the
board rather than at one rung, because the divergence is not specific to
`border.standard` — it is a property of every light-on-dark pair in the palette.

**Leads (unverified).**

- APCA-W3, the readability criteria and lookup tables (`git.apcacontrast.com`).
- Somers, A. — the argument for why a symmetric ratio is the wrong model. This
  is the piece that would say whether the divergence measured here is the
  expected size or a transcription error in our own implementation.
- WCAG 3 working drafts, for whether any of this is heading for normative
  status.

---

## P2 — A shipped dark control outline sits under the perceptual floor

**As implemented.** `border.standard` and `border.interactive` resolve to
`neutral50` (`#6B7382`) in the dark standard profile: 3.65:1 on `surface.base`,
clearing WCAG 2.2 SC 1.4.11, at Lc 27.2.

**Why it is a question rather than a fix.** The two candidate rungs are
measured and neither is free. `neutral45` (`#7E8693`) gives 4.75:1 / Lc 36.0 on
`surface.base` and 4.02:1 / Lc 33.9 on `surface.subtle` — the smallest step that
clears Lc 30 on both, and thin on the second. `neutral40` (`#98A0AE`) gives
6.62:1 / Lc 49.2, comfortable, and is the rung `content.tertiary` already holds,
so a control outline would become exactly as prominent as tertiary text.

Neither is obviously right, and the cost of guessing is known: the last rung
moved on an argument produced twelve collisions in
`button_distinguishability_test.dart`, which is how `IUX-PALETTE-HEADROOM-001`
learned that `action.secondary.foreground` could not follow `content.link`.

**What would settle it.** Not literature. Render both candidates and look, on a
device, in the conditions a dark theme is actually used in — which is
`IUX-MANUAL-001`'s protocol and the reason it exists. The measurement has done
what a measurement can do; it narrowed a ramp to two rungs and cannot choose
between them.

**Note the shape of this.** P1 asks whether the instrument should have authority.
P2 is what happens if it does, on the one role where the answer is already
actionable. They can be answered in either order, and answering P2 first is
cheaper.

---

## P3 — The redundant channel is thinner than its own comment claims

**As implemented.** `IuxInlineFeedbackResolver._glyphFor` maps the four feedback
categories to `info_outline`, `check_circle_outline`, `warning_amber_outlined`
and `error_outline`, documented as "four shapes, not four colours" and defended
with "a user with deuteranopia distinguishes the triangle from the circles".

**What was measured.** Under deuteranopia the `success` and `error` content
colours are 1.5 apart in the dark standard profile and **0.4 apart in dark high
contrast** — the same colour, on the ×100 Oklab scale where about 2 is the
smallest side-by-side difference most people notice. The colour channel does not
merely weaken for that pair; it closes.

**What is unsupported.** That the shape channel picks it up. The comment's
argument is about the triangle, and the triangle is `warning` — a pair the
colour channel handles comparatively well. **Three of the four glyphs are
circles**, and the pair colour fails hardest on is a circled tick against a
circled exclamation mark, distinguished by the mark inside a shared silhouette
at roughly 20 logical pixels.

This is not a WCAG 2.2 SC 1.4.1 failure: the message text carries the category,
and `IuxInlineFeedback` puts it in the live-region label as well. It is a
redundancy claimed in a doc comment and not delivered where it is most needed.

**What would settle it.** Two things, and the first needs nobody's permission:

1. **Give the pair distinct silhouettes.** An octagon for `error`, or a bare
   tick for `success`. This costs one line, breaks no contract, and removes the
   question rather than answering it. It is not taken here only because a glyph
   set is a visual identity decision and the palette owner should make it.
2. Only if (1) is declined: whether a mark-inside-a-circle is discriminable at
   icon size under time pressure. That is a real visual-search question and the
   literature for it is the same body `research/hci/open-questions.md` Q3 says
   is entirely absent from this repository.

**Leads (unverified).**

- Machado, G. M., Oliveira, M. M. & Fernandes, L. A. F. (2009), *A
  physiologically-based model for simulation of color vision deficiency*, IEEE
  TVCG. The source of the matrices used to produce these numbers, and the thing
  to read before quoting them anywhere outside this repository.
- Anomalous trichromacy is more common than dichromacy and is not simulated at
  all here. Whether the separations for a deuteranomalous reader — somewhere
  between the "normal" and "measured" columns of the register table — clear a
  useful floor is unmeasured and would change how urgent P3 is.
