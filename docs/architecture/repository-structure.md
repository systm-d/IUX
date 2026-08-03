# Repository structure

## Purpose

IUX uses a lightweight monorepo so the framework package, its catalog, its
documentation, and its evidence can evolve together without creating runtime
dependencies between them.

## Responsibilities

- `packages/` contains reusable code and must not depend on applications or
  documentation.
- `apps/` contains local applications such as the catalog. An application may
  depend on packages by local path for integration validation.
- `docs/` explains architecture, accessibility constraints, component use, and
  decisions. It is not runtime input.
- `research/` preserves sources and notes that justify important UX choices. It
  is not runtime input.
- `tools/` may contain shared developer tooling once a concrete need exists.

## Allowed dependency direction

```text
apps/catalog  -> packages/iux_flutter
docs          -> packages and decisions (documentation only)
research      -> external evidence (documentation only)
```

The package must never depend on the catalog, documentation, research, or a
brand identity. Future package layers follow the direction defined by
`PROJECT_PROMPT.md`: foundations, semantic tokens, components, then patterns.

## Monorepo tooling

No monorepo orchestrator is used yet. With one package and one local catalog,
standard Flutter commands remain simpler and more transparent. Re-evaluate
this decision when cross-package orchestration becomes a demonstrated need.
