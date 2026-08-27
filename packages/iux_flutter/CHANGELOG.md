# Changelog

This file is not a second history. `dart pub` requires a changelog in the
package directory that names the current version, so it names it and points at
the one changelog. Every entry, for every version, is in
[`CHANGELOG.md`](../../CHANGELOG.md) at the repository root.

## Unreleased

Repository claims and `research/`: the register cites zero primary HCI or
cognitive-psychology literature, so the README now describes IUX as conformant,
tested accessibility foundations and marks the ergonomics an explicitly
unsupported ambition. `research/` gains a method and a five-question backlog.
No library change.

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
