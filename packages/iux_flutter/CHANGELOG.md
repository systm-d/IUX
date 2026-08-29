# Changelog

This file is not a second history. `dart pub` requires a changelog in the
package directory that names the current version, so it names it and points at
the one changelog. Every entry, for every version, is in
[`CHANGELOG.md`](../../CHANGELOG.md) at the repository root.

## Unreleased

**Breaking.** `IuxOnboardingFlow.forwardLabel` is removed;
`IuxOnboardingStep.forwardLabel` replaces it, null on the last step only. The
pattern's assertion demanded a named destination while its API offered one
string for the whole flow, so from the second step onward the label was either
wrong or generic. `backLabel` stays flow-wide and keeps its argument, which is
sound for backwards and does not transfer to forwards.
`IUX-ONBOARDING-FORWARD-001`.

Documentation: `IuxListItem.selectable` and the list documentation now name
`IuxRadioGroup` for a one-answer question. Seven selectable rows are seven
independent toggles with no question attached and no exclusivity — the one wrong
composition the component cannot refuse, because it is byte-identical to a
legitimate one. `IUX-LIST-SINGLECHOICE-001`.

Documentation: `research/accessibility/en-301-549-mapping.md`. The RGAA's
technical method is web-only and does not apply to a native mobile framework —
the referential that does is RAAM, and the issue asking for this mapping named
the wrong one. Our own side is counted (166 entries, 29 distinct WCAG success
criteria, each tested); the clause side is empty because every primary source is
blocked from this environment, and a clause quoted from a summary is not a
source. `IUX-CONFORMANCE-001`. No library change.

**Visual change in every application.** The error glyph becomes an octagon.
`success` and `error` were measured 0.4 apart under deuteranopia in the dark
high contrast profile — the same colour — and the glyph set had three circles,
putting `error` in a family with the one category it is least affordable to
confuse it with. The four shapes also get a single definition: three components
drew them from three independent maps that happened to agree, so each one's own
distinctness test would have passed while a category became two shapes. No API
change; the glyph was never overridable. `IUX-GLYPH-SILHOUETTE-001`.

A cited `IUX-*` identifier now has to resolve. Three were cited by source and
documentation with no entry anywhere; all three have since been written up, so
the new guard passes on arrival and exists to stop the fourth. It also holds a
convention the register already used and never enforced: an ID may carry more
than one entry, but a superseded one must now say so and name what continues
it — a reader following a citation was landing on a Status line overtaken
elsewhere. No library change.

The palette is measured for the first time with instruments WCAG does not have:
APCA lightness contrast, Oklab distance and simulation of the three
dichromacies, all under `test/support/` and all verified against properties of
their own algorithms before use. No shipped colour changed. Three findings —
the same ratio buys under half the perceived contrast in dark; a dark control
outline clears SC 1.4.11 and sits under the perceptual floor; and under
deuteranopia the success and error feedback colours are the same colour, so the
glyph carries the category and the suite now asserts the four glyphs are
distinct. `IUX-PALETTE-PERCEPTION-001` and `research/perception/`.

`IuxTapTarget` now publishes its own tap action. Passing `semanticLabel`
excludes the subtree and took the child's action with it, so a named target
announced a button and offered nothing to activate — a finger worked, a screen
reader did not. The scan that watches for this required a literal `button: true`
and so never examined it; its predicate is widened.

Repository claims and `research/`: the register cites zero primary HCI or
cognitive-psychology literature, so the README now describes IUX as conformant,
tested accessibility foundations and marks the ergonomics an explicitly
unsupported ambition. `research/` gains a method and a five-question backlog.
No library change.

`IuxAppBar.brand` draws a wordmark where the title's text would have been, while
`title` stays required and stays the announced heading; the mark is excluded from
the semantic tree by construction. It exists because with nowhere in the bar for
an identity, a migrating application put its wordmark in the page and showed the
name twice. Additive.

**Behaviour change on the light standard profile.** Four chromatic content roles
move one rung lighter — `content.link` and the feedback contents were past AAA
at 9.16:1 to 9.72:1, leaving the high contrast profile a single rung to
distinguish itself with. They now clear AA with margin and stop short of AAA on
purpose. The caution ramp's dark end changes hue to orange: a yellow held above
4.5:1 on white is a khaki brown, not a warning. `IuxTheme.withSemanticColors` is
still the way out.

`IuxChipGroup.mark` takes `IuxChipMark.outline`, which gives back the chip's
reserved checkmark slot — 22 pixels a chip, enough to take four short chips from
two lines to one. The group's documentation now carries the width budget either
way. Additive; the reserved slot stays the default, and neither value reflows.

`IuxRadioGroup.layout` takes `IuxRadioGroupLayout.row`, which puts the options
on a shared line and wraps rather than overflowing. Four short values drop from
276 pixels to 84. Additive; the column arrangement stays the default, and the
target floor and spacing floor are unchanged in both.

Test infrastructure: `realTap` (`test/support/gestures.dart`) presses with a
frame between `down` and `up`, the way a finger does, and a per-component sweep
applies it to everything that redraws while held. `tester.tap()` cannot reach
the defect class `IUX-SELECTION-PRESS-001` belongs to. No library change.

`IuxListItem` painted its press tint over its own content rather than behind it.
The colour is opaque and the opacity is 1, so a pressed row was a blank band:
8226 ink pixels at rest, **0 while pressed**. Reported from a device as a row
that stayed selected. `IuxListItem.tappable` also gains an opt-in chevron for
rows that open a screen.

Every layer that can be a route root — `IuxScreen`, `IuxPage`, `IuxModalLayer`,
`IuxTransientLayer`, `IuxAdaptiveNavigation` — now provides its own transparent
`Material`. Without one, text resolves against Flutter's monospace,
yellow-underlined fallback style; two consumer applications shipped a build that
did, and neither test suite could see it.

Additive; callers need change nothing. See [`CHANGELOG.md`](../../CHANGELOG.md)
at the repository root.

## 0.2.0-dev.3

Three chart primitives — `IuxLineChart`, `IuxBarChart`, `IuxSparkline` — and the
first painting code in the package. `semanticsSummary` is required on all three.

Additive. See [`CHANGELOG.md`](../../CHANGELOG.md) at the repository root.

## 0.2.0-dev.2

The IUX-042 follow-through: the release assessment's blockers, closed and
measured. Adds `IuxScreen` and `IuxPlaceMap`. Breaking for `IuxFormField.child`,
which becomes `builder`, and for `IuxButtonState.loading`.

The licence is settled — MIT, at the repository root and in this directory.

Still not a release candidate, and the reason has narrowed to one: **no
TalkBack, Voice Access or D-pad session has ever been run on a real device.**
Everything this package claims about accessibility is measured on a semantics
tree in a unit test. See `docs/MISSION_042_RELEASE_CANDIDATE.md`.

## 0.2.0-dev.1

Eight patterns — error recovery, loading and retry, permission rationale,
destructive flow, guided form, search, progressive disclosure, onboarding —
three audits, and the first application built on the framework end to end.
Breaking for five removed members of the button theme.

## 0.1.0-dev.11 and earlier

At the repository root. The `0.1.0-dev` line ended at `0.1.0-dev.11`; the
`0.1.0-dev.1` this file used to claim was a lag, never a release.
