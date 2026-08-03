# ADR-0001: Lightweight monorepo repository structure

- Status: accepted
- Date: 2026-08-01

## Context

IUX needs a reusable Flutter package, a local catalog, durable documentation,
and a research trail. The project is new and has no demonstrated need for
cross-package automation.

## Decision

Use one repository with `packages/`, `apps/`, `docs/`, `research/`, and
`tools/`. Keep `iux_flutter` independent. Let the catalog depend on it through
a local path. Do not introduce a monorepo orchestration dependency yet.

## Alternatives considered

- Separate repositories: rejected because package, catalog, and evidence would
  be harder to evolve and validate together at this early stage.
- Add a monorepo tool immediately: deferred because its operational cost is not
  justified while there is one package and one application.

## Consequences

Developers run Flutter commands from each package or application directory.
The repository may adopt an orchestrator later through a separate documented
decision if coordination becomes materially complex.
