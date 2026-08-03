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

## Version control conventions

This repository currently has no usable Git worktree. Once initialized, use
small, intentional commits with an imperative summary and keep generated build
artifacts and local secrets untracked. Commit `pubspec.lock` for applications;
do not commit it for reusable packages unless a future package policy says
otherwise.
