# ADR-0002: Semantic colours and Flutter's `ColorScheme`

- Status: accepted
- Date: 2026-08-03
- Supersedes: `ADR-0002-semantic-theme-profiles.md` (removed; it described a
  different subject and left this decision unrecorded)

## Context

Flutter components read `ThemeData.colorScheme`. IUX components read
`IuxSemanticColors`. Both describe interface colour, so the project must decide
which one is authoritative — otherwise the two drift and a screen mixing IUX
and Material widgets becomes incoherent.

The previous implementation derived `IuxSemanticColors` from a `ColorScheme`
produced by `ColorScheme.fromSeed(seedColor: Colors.indigo)`. That inverted the
dependency and had three consequences:

1. the source of truth sat in Material, where IUX cannot test contrast;
2. `fromSeed` offers no contrast guarantee, so no contract could be asserted;
3. a brand seed was hardcoded, contrary to `PROJECT_PROMPT.md` §23.

## Decision

**IUX semantic roles are the source of truth. A theme derives `ColorScheme`
from the roles, never the reverse.**

```text
Primitives → IuxSemanticColors → ColorScheme → Material widgets
                     ↓
              IUX components
```

`IuxSemanticColors.fromColorScheme` is removed. The theme engine delivered by
IUX-004 will own the role-to-`ColorScheme` mapping and test it.

## Alternatives considered

**Derive IUX roles from `ColorScheme`.** Rejected: places the contrast
guarantee outside IUX and makes it untestable. This is what was implemented and
is being reversed.

**Expose only `ColorScheme`.** Rejected: `ColorScheme` has no role for focus
versus selection, for a disabled surface, or for the per-intent action state
contract. Expressing them would mean overloading fields with meanings Material
does not give them.

**Maintain both independently.** Rejected: two sources of truth guarantee
divergence.

## Consequences

Positive:

- contrast is verifiable inside IUX, and is verified;
- IUX components stay independent of Material's colour model;
- an application changes its palette by supplying roles, not by reverse
  engineering a seed.

Negative:

- IUX-004 must implement and maintain the role-to-`ColorScheme` mapping;
- a Material widget used directly reads the derived scheme, so any gap in the
  mapping shows up as an inconsistency. The mapping needs its own tests.

## Risks

- **Mapping drift.** Material may add or redefine `ColorScheme` fields.
  Mitigation: the mapping is tested, and Flutter SDK upgrades must re-run it.
- **Imperfect fit.** Some `ColorScheme` fields have no natural IUX role.
  Mitigation: IUX-004 documents each unmapped field and its fallback rather
  than inventing a role for it.

## Status of related work

- IUX-003.1 delivers the roles and the contrast tests.
- IUX-004 delivers the theme engine and the `ColorScheme` mapping.
