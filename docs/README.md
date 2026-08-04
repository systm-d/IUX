# Documentation

This directory records how IUX is designed, used, validated, and evolved.

## Structure

- `architecture/` — repository and layer boundaries.
- `foundations/` — spacing, sizing, density, typography, focus, motion.
- `semantics/` — the semantic role layer components read.
- `accessibility/` — contracts, constraints, and manual validation notes.
- `themes/` — theme guidance.
- `components/` and `patterns/` — one page per public component and pattern.
- `decisions/` — architecture and UX decision records.
- `evidence/` — decisions with their evidence level, sources, and limits.

## Where to start

If you are **building an application** on IUX:

1. [MISSION_042_RELEASE_CANDIDATE.md](MISSION_042_RELEASE_CANDIDATE.md) — what
   is open, ranked by what it costs a user, and which compositions to avoid.
   Read this before the rest; several of them will change what you write.
2. The root [README](../README.md) — the two ancestors an application must
   install, and where the modal and transient layers go.
3. `components/` and `patterns/` for the widget you need. Each page carries a
   *Limits* section, and on this project those sections are load-bearing.

If you are **contributing**:

- [semantics/semantic-tokens.md](semantics/semantic-tokens.md) explains how a
  component obtains a colour without ever naming one.
- [accessibility/contrast-contracts.md](accessibility/contrast-contracts.md)
  states the ratios IUX commits to and what is verified.
- [accessibility/color-and-non-color-signals.md](accessibility/color-and-non-color-signals.md)
  states the rule no component may violate.

## Finding a component

There is no generated index; `packages/iux_flutter/lib/iux_flutter.dart` is the
authoritative list of what is public. Two page names do not match the type they
document, which is worth knowing before you search:

| Type | Page |
| --- | --- |
| `IuxForm`, `IuxFormSection`, `IuxValidationSummary` | `patterns/guided-form.md` |
| `IuxGuidedForm` (the stepped form) | `patterns/stepped-form.md` |
| `IuxAdaptiveNavigation` | `components/navigation-rail.md` |
| `IuxModalLayer` | `components/dialog.md` |
| `IuxContentGroup` | `components/card.md` |

## Missions

Mission prompts live at the root of this directory as `MISSION_*.md`. Read
`PROJECT_PROMPT.md` first, then the active mission.

Mission status is tracked in each file's YAML header. A mission marked
`completed` is never reopened: a follow-up mission is created instead
(`PROJECT_PROMPT.md` §63). `MISSION_003_1_SEMANTIC_LAYER_REMEDIATION.md` is one
such follow-up, and records why it was needed.
