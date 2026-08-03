# ADR-0009: Action model as orthogonal dimensions

- Status: accepted
- Date: 2026-08-03
- Mission: IUX-008.2

## Context

Every component from IUX-008.4 onward renders actions. They need to agree on
what an action is: how it looks, whether it can be activated, what a screen
reader says, and what a second tap does.

The tempting model is one enum — primary, secondary, destructive — with
behaviour attached to each value.

## Decision

**Model an action as independent dimensions, and decide activation once.**

Ten dimensions on one immutable `IuxActionDescriptor`, with contradictions
caught by assertion, and a single `IuxActionPolicy.evaluate` that answers
whether an activation proceeds.

## Why not one enum

Attaching behaviour to intent produces wrong defaults that cannot be
overridden:

- destructive would imply confirmation, so "Remove tag" gets a dialog and
  users learn to dismiss dialogs;
- destructive would imply irreversible, so archiving is treated as deletion;
- primary would imply high importance, so a screen with a rarely used primary
  action shouts.

The dimensions vary independently in practice, so the model says so.

## Why refusals carry a reason

`IuxActionPolicy.evaluate` returns why an activation was refused rather than a
bare boolean.

A control that does nothing when tapped is indistinguishable from one that is
broken. With a reason, a component can explain — "already saving", "confirm
first" — which is the difference between a system that feels deliberate and one
that feels unreliable.

## Why assertions rather than silent correction

A contradictory descriptor means the caller believed something untrue.
Correcting it silently ships that misunderstanding. The assertions name the
contradiction and the fix.

They are debug-only, which is a real limitation: a release build renders
something regardless.

## Alternatives considered

**A single intent enum with attached behaviour.** Rejected on the grounds
above.

**Nullable callback as the only availability model.** Rejected: `onPressed:
null` cannot carry why the action is unavailable, and an unexplained greyed
control leaves the user unable to tell whether they did something wrong.

**A validation result instead of assertions.** Rejected for the constructor:
a descriptor is `const`, and returning a result would force every call site to
check something that should be impossible.

**Including `debounce` and `throttle`.** Rejected: both need durations, which
do not belong in an enum.

## Consequences

Positive:

- wrong combinations are impossible to express accidentally;
- the activation rule cannot drift between components;
- a disabled action can say why.

Negative:

- ten dimensions is more surface than one enum, and callers must learn which
  matter for their case. The named constructors and defaults absorb most of it;
- assertions do not fire in release.

## Risks

- **Dimension creep.** Every future addition must show that it varies
  independently of the existing ten.
- **`custom` role becoming the default in practice.** It tells the semantics
  layer nothing; nothing but review prevents its overuse.
