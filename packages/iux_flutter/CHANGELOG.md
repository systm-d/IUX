# Changelog

This file is not a second history. `dart pub` requires a changelog in the
package directory that names the current version, so it names it and points at
the one changelog. Every entry, for every version, is in
[`CHANGELOG.md`](../../CHANGELOG.md) at the repository root.

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
