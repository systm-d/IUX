# Contributing to IUX

## Required reading order

1. Read `PROJECT_PROMPT.md` completely.
2. Find a mission with `status: ready` in `docs/`.
3. Read that Mission Prompt completely.
4. Before implementation, change its status to `in_progress` and record the
   required lifecycle metadata.

`PROJECT_PROMPT.md` always prevails over a Mission Prompt. Do not begin a
mission that is already `in_progress`, `completed`, or `blocked` without the
explicitly documented follow-up process.

## Validation

Run formatting from the repository root and analyze and test each Flutter
package/application from its own directory:

```bash
dart format .
cd packages/iux_flutter && flutter analyze && flutter test
cd ../../apps/catalog && flutter analyze && flutter test
```

## Definition of done

A change is complete only when it meets the active mission's acceptance
criteria, preserves the project architecture, is documented, is tested, and
has its accessibility implications assessed. Record commands actually run and
their results; do not claim unexecuted validation.

## Versioning

The project follows Semantic Versioning (`PROJECT_PROMPT.md` §50). Three files
carry the version and they disagreed for three missions, so the rule is written
here rather than assumed:

1. **`packages/iux_flutter/pubspec.yaml` decides.** It is the only place a
   version number is chosen. Nothing else may introduce one.
2. **`CHANGELOG.md` at the repository root is the only history.** Its topmost
   heading repeats the pubspec version verbatim. Every entry goes here.
3. **`packages/iux_flutter/CHANGELOG.md` is not a second history.** `dart pub`
   requires a changelog in the package directory naming the current version, so
   it names that version, summarises it in a sentence, and points here.

The check is free and already exists: `dart pub publish --dry-run` reports
*"CHANGELOG.md doesn't mention current version"* whenever (1) and (3) drift.
Run it with the other validation commands below. Nothing detects a drift
between (1) and (2), so bump them in the same edit.

A version is bumped when a mission wave lands, not per mission. The
`0.1.0-dev` line ended at `0.1.0-dev.11`; `0.1.0-dev.9` in the pubspec and
`0.1.0-dev.1` in the package changelog were lags, never releases.

## Version control conventions

Use small, intentional commits with an imperative summary, and keep generated
build artifacts and local secrets untracked. Commit `pubspec.lock` for
applications; do not commit it for reusable packages unless a future package
policy says otherwise — note that `packages/iux_flutter/pubspec.lock` is
tracked today, which contradicts this line and is one of the two that needs
settling. The repository has no remote, which is why
`packages/iux_flutter/pubspec.yaml` still declares no `repository:` or
`homepage:`.
