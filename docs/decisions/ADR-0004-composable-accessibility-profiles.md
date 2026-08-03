# ADR-0004: Composable accessibility profiles

- Status: accepted
- Date: 2026-08-03
- Mission: IUX-004

## Context

IUX must offer accessibility preferences. Two questions had to be settled:
how they combine, and how they are named.

Both have a common failure mode. Design systems frequently ship profiles like
`highContrast` or `accessible` that bundle several unrelated changes — and
sometimes name them after a population or a diagnosis.

## Decision

**Preferences are orthogonal axes on a single immutable profile, and no
preference is ever named after a person or a condition.**

```dart
const IuxAccessibilityProfile(
  contrast: IuxContrast.high,
  motion: IuxMotionPreference.reduced,
  density: IuxDensity.comfortable,
  touchTarget: IuxTouchTargetPreference.comfortable,
  visualStimulation: IuxVisualStimulation.reduced,
)
```

Any combination is valid. No preference implies another.

Three named constructors exist — `standard()`, `comfortable()`,
`reducedMotion()` — as shorthands for common requests. Each is documented by
what it sets, and each remains overridable.

## Why orthogonal

A bundled profile assumes the preferences correlate. They do not. A user who
needs reinforced contrast may be entirely comfortable with motion; a user who
needs reduced motion may prefer a dense layout.

Bundling makes the unwanted parts of a profile the price of the wanted part,
which pushes users to disable the whole thing.

## Why no diagnosis-based naming

`IuxAccessibilityProfile.adhd()` would assert two things IUX cannot support:
that a population shares a single interface need, and that this particular
combination of settings meets it.

It also invites an application to infer a diagnosis from a settings choice,
which is a privacy problem as much as a correctness one.

A user who wants less motion asks for less motion. IUX does not ask why.

## Alternatives considered

**Bundled named profiles.** Rejected: forces unwanted changes, and any
combination nobody named is unreachable.

**A free-form map of preferences.** Rejected: no type safety, no exhaustive
testing, and no way for a component to know what it may read.

**Profiles named after conditions.** Rejected on the grounds above.

## Consequences

Positive:

- 192 combinations, all valid, all tested;
- a user changes one preference without side effects;
- no claim is made about any population.

Negative:

- more configuration surface than three named profiles;
- an application wanting a preset defines it itself — which is correct, since
  a preset is a product decision.

## Risks

- **Combinatorial explosion in testing.** Mitigation: a test resolves all 192
  combinations and asserts none produces a null field, an invalid target or an
  exception.
- **An application inventing diagnosis-named presets.** IUX cannot prevent
  this; `docs/themes/visual-stimulation.md` states the reasoning so the choice
  is at least informed.
