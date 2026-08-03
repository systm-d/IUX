# IUX — Intuitive UX

IUX is an experimental open-source Flutter framework for building Android-first
mobile interfaces that are more accessible, understandable, and consistent.
It provides foundations, semantic intentions, components, and UX patterns; it
is not a visual design system or a collection of decorative widgets.

The project is at an early development stage. Its foundations and default
choices must be validated in the context of each application; IUX does not yet
claim WCAG conformance or universal accessibility.

## Repository structure

- `apps/catalog/`: local integration catalog.
- `packages/iux_flutter/`: primary Flutter package.
- `docs/`: architecture, accessibility, component, foundation, pattern, and
  decision documentation.
- `research/`: traceable research material for future UX decisions.
- `tools/`: shared development tooling when it becomes necessary.

## Prerequisites

Use the Flutter stable SDK available in the development environment. Check the
installed toolchain with:

```bash
flutter --version
dart --version
```

## Local workflow

Fetch package dependencies before running validation:

```bash
cd packages/iux_flutter && flutter pub get
cd ../../apps/catalog && flutter pub get
```

Validate the package and catalog:

```bash
dart format .
cd packages/iux_flutter && flutter analyze && flutter test
cd ../../apps/catalog && flutter analyze && flutter test
```

Run the catalog from `apps/catalog/` on a configured Flutter target:

```bash
flutter run
```

Read [PROJECT_PROMPT.md](PROJECT_PROMPT.md) before a mission, then read the
active Mission Prompt in `docs/`.
