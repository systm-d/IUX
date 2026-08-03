# ADR-0008: Component standard, enforced where it can be

- Status: accepted
- Date: 2026-08-03
- Mission: IUX-008.1

## Context

IUX-002 to IUX-007 built foundations, tokens, themes, a runtime, motion,
feedback and layout. From IUX-008.2 onward the project starts producing
components, and every one of them can quietly undo those guarantees: one
hardcoded colour bypasses the contrast contracts, one direct `HapticFeedback`
call bypasses the feedback policy, one bare `Duration` bypasses reduced motion.

A written standard is the usual answer. Written standards are followed until
someone is in a hurry.

## Decision

**Write the standard, and enforce mechanically every rule that a machine can
decide.**

`test/components/component_standard_test.dart` fails the build when a file
under `lib/src/components/` or `lib/src/patterns/` contains a colour literal, a
Material colour constant, a `MediaQuery` preference read, a direct haptic call,
a direct announcement, a hardcoded animation duration, a `Navigator` call, a
`ScaffoldMessenger` call, or network access.

It also checks that the barrel stays sorted, that every export resolves, and
that the primitive palette is never exported.

Human review keeps what remains: whether a label is understandable, whether the
component solves a real problem, whether TalkBack reads it sensibly.

## Why the source-text approach

The check reads source text with comments stripped. That is crude — it cannot
follow an alias or a helper that wraps a forbidden call.

It was chosen anyway because the alternative, a custom analyzer plugin, is a
large amount of machinery for a project with no components yet, and because the
violations it catches are the ones that actually happen: someone reaches for
`Colors.red` because it is faster than looking up the role.

A lint package is a candidate for Phase 5, when there is enough surface to
justify it.

## Alternatives considered

**Documentation only.** Rejected: the guarantees are exactly the kind that
erode quietly, and nothing would surface the erosion until an audit.

**A custom analyzer plugin now.** Rejected as premature: no components exist,
and the maintenance cost is real.

**Blocking all Flutter primitives.** Rejected: the runtime and theme layers
legitimately use them, so the rule is scoped to components and patterns.

## Consequences

Positive:

- a violation fails the build rather than surviving to an audit;
- the rules have a single written home the later missions can point at;
- the test names read as the rules themselves, so a failure explains itself.

Negative:

- source-text matching produces false negatives for indirection;
- the check is scoped by directory, so a component placed elsewhere escapes it;
- the rules currently pass vacuously, since no components exist. They were
  verified against a deliberate violation before being trusted.

## Risks

- **False confidence from a vacuous pass.** Mitigated by verifying the test
  fails on a probe file. It does.
- **Someone widening the exclusions to make a failure go away.** Nothing
  prevents this beyond review.
