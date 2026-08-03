# ADR-0006: Motion and feedback engine

- Status: accepted
- Date: 2026-08-03
- Mission: IUX-006

## Context

IUX-005 delivered a minimal motion policy with two roles, `essential` and
`decorative`. That split answers "may this run" but not "how should it adapt" —
and the two questions have different answers per role.

Feedback had no home at all: haptics, announcements and visual confirmation
would each have been reimplemented per component.

## Decisions

### 1. Motion roles describe intent, and each carries its own adaptation

Eight roles replace the essential/decorative pair. Each declares what happens
under reduced motion: shorten, simplify, preserve or remove.

The distinction that matters is **simplify versus shorten**. For `reposition`,
`reveal` and `conceal`, a faster large movement is worse than a slow one, not
better. Those roles become a fade; only in-place changes are shortened.

### 2. The parent owns feedback truth

`IuxFeedbackEvent` is emitted explicitly. The runtime never infers success,
failure or completion. A framework that guesses will eventually announce a
success that did not happen.

### 3. A scoped controller, not a singleton

`IuxFeedbackScope` provides an `IuxFeedbackController`. A singleton cannot be
configured per subtree, leaks state between tests, and hides who emits what.

A missing scope throws. Silently discarding feedback means a user receives
nothing, which must surface in development rather than in the field.

### 4. Deduplication is a single last-event check

One key, one timestamp, one window. Not an event bus.

The two real problems are a parent and a component both reporting the same
outcome, and a retry loop firing repeatedly. Both are solved by remembering the
last event. Anything more would be machinery without a demonstrated need.

### 5. The engine holds no user-facing strings

`semanticMessage` arrives already localised. The engine cannot compose text, so
it cannot leak an English sentence into another language.

### 6. Every delivery reports its outcome

`emit` returns what happened per channel. Haptics may be disabled;
announcements may be unsupported. A caller that needs certainty must use the
visual state, and the return value makes that limitation visible rather than
implicit.

## Alternatives considered

**Keeping the two-role motion model.** Rejected: it cannot express that travel
should fade while an in-place change should shorten.

**A global feedback singleton.** Rejected on testability and configurability.

**Inferring feedback from component state.** Rejected: the framework does not
know whether an operation succeeded.

**An event bus with subscribers.** Rejected as unjustified complexity for the
two deduplication cases that actually occur.

**Built-in localised messages.** Rejected: any built-in string is wrong in most
languages, and shipping English defaults makes the omission invisible.

## Consequences

Positive:

- reduced motion is adapted per role, once;
- feedback channels are orchestrated in one place, with proportion enforced;
- no component can produce a double haptic for a single event;
- the engine is testable without a device.

Negative:

- eight motion roles are more to learn than two;
- callers must supply their own messages, which is more work than a default —
  and is the point;
- `IuxFeedbackScope` is one more widget an application must install.

## Risks

- **A component bypassing the policy.** Mitigation: documented; a lint is a
  Phase 5 candidate.
- **The deduplication window being wrong.** Recorded as a hypothesis; it is
  configurable through `IuxFeedbackTheme`.
- **Haptics felt by nobody.** Flutter does not report the platform haptic
  setting. Mitigation: haptics may never be the only signal, and the outcome
  reports what was attempted.
