# Documentation

This directory records how IUX is designed, used, validated, and evolved.

## Structure

- `architecture/` — repository and layer boundaries.
- `foundations/` — spacing, sizing, density, typography, focus, motion.
- `semantics/` — the semantic role layer components read.
- `accessibility/` — contracts, constraints, and manual validation notes.
- `themes/` — theme guidance (the engine arrives with IUX-004).
- `components/` and `patterns/` — public APIs, once they exist.
- `decisions/` — architecture and UX decision records.
- `evidence/` — decisions with their evidence level, sources, and limits.

## Where to start

- [semantics/semantic-tokens.md](semantics/semantic-tokens.md) explains how a
  component obtains a colour without ever naming one.
- [accessibility/contrast-contracts.md](accessibility/contrast-contracts.md)
  states the ratios IUX commits to and what is verified.
- [accessibility/color-and-non-color-signals.md](accessibility/color-and-non-color-signals.md)
  states the rule no component may violate.

## Missions

Mission prompts live at the root of this directory as `MISSION_*.md`. Read
`PROJECT_PROMPT.md` first, then the active mission.

Mission status is tracked in each file's YAML header. A mission marked
`completed` is never reopened: a follow-up mission is created instead
(`PROJECT_PROMPT.md` §63). `MISSION_003_1_SEMANTIC_LAYER_REMEDIATION.md` is one
such follow-up, and records why it was needed.
