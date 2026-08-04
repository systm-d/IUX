# IUX — Intuitive UX

IUX is an experimental open-source Flutter framework for building Android-first
mobile interfaces that are more accessible, understandable, and consistent.
It provides foundations, semantic intentions, components, and UX patterns; it
is not a visual design system or a collection of decorative widgets.

The project is at an early development stage. Its foundations and default
choices must be validated in the context of each application; IUX does not yet
claim WCAG conformance or universal accessibility.

## Status

The package is **licensed but not a release candidate**, and the distinction is
load-bearing rather than modest.

IUX is **MIT licensed**, so you may legally use, copy, modify and distribute
it, and `dart pub publish --dry-run` now passes without an error.

What is still true is that it is not ready. `publish_to: none` stays on
purpose: being publishable and being ready to publish are different questions,
and the second answer is still no. Most decisively, **nothing here has ever
been validated on a real device with a screen reader** — every accessibility
claim in this repository is measured on a semantics tree in a unit test, which
is a great deal and is not the same thing.

Twenty-two entries in
[docs/evidence/semantic-tokens-and-accessibility.md](docs/evidence/semantic-tokens-and-accessibility.md)
are open, several of them severe: at a large text scale two patterns put their
only control out of reach, a transient notice makes the bottom navigation
unreachable for four seconds, and a button carrying a confirmation policy runs
its action on the first tap. Read
[docs/MISSION_042_RELEASE_CANDIDATE.md](docs/MISSION_042_RELEASE_CANDIDATE.md)
before building anything on this — it ranks what is open by what it costs a
user, and names the compositions to avoid.

No manual accessibility validation has been performed on hardware. Every
accessibility claim here rests on widget tests.

## Repository structure

- `packages/iux_flutter/`: primary Flutter package.
- `apps/catalog/`: one component at a time, under the conditions most likely to
  break it.
- `apps/pilot/`: a small application built entirely on IUX, end to end. Its
  value is its friction log — `apps/pilot/README.md` indexes every place the
  framework had to be worked around, and several of those workarounds are the
  only written record of the correct composition.
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

## Using it in an application

The package sets `publish_to: none`, so there is no pub.dev install yet. The
only supported dependency today is a path:

```yaml
dependencies:
  iux_flutter:
    path: ../../packages/iux_flutter
```

**One ancestor is required and one is conditionally required**, and getting
either wrong throws rather than degrading:

- **An IUX theme, always.** `IuxSemanticColors.of` throws *No IuxSemanticColors
  found in the ambient theme* when none is installed, because a silent fallback
  would render a plausible but unverified interface. Every component resolves
  through it.
- **`IuxFeedbackScope`, if anything emits feedback.**
  `IuxFeedbackScope.of` throws when absent, and `IuxAsyncActionButton` is the
  only caller that tolerates its absence. Wrap the application root.

There is no accessibility-runtime ancestor to install: `IuxAccessibility.of`
derives from `MediaQuery` and the theme, with a default profile as the
fallback.

```dart
import 'package:iux_flutter/iux_flutter.dart';

IuxFeedbackScope(
  child: MaterialApp(
    theme: IuxTheme.light(),
    darkTheme: IuxTheme.dark(),
    home: IuxPage(child: /* … */),
  ),
)
```

`IuxModalLayer` and `IuxTransientLayer` are **not** ancestors of the
application; they are placed at a chosen depth, and the depth is load-bearing.
A dialog must cover the navigation and a notice must not, so the modal layer
goes outside `IuxAdaptiveNavigation` and the transient layer inside it. Getting
this wrong is `IUX-TRANSIENT-COVER-001`, and the working shape is in
`apps/pilot/lib/main.dart`.

## Local workflow

Fetch dependencies before running validation:

```bash
cd packages/iux_flutter && flutter pub get
cd ../../apps/catalog && flutter pub get
cd ../pilot && flutter pub get
```

Validate the package and both applications:

```bash
dart format .
cd packages/iux_flutter && flutter analyze && flutter test
cd ../../apps/catalog && flutter analyze && flutter test
cd ../pilot && flutter analyze && flutter test
```

Run either application on a configured Flutter target with `flutter run`.
Android is the platform priority.

Read [PROJECT_PROMPT.md](PROJECT_PROMPT.md) before a mission, then read the
active Mission Prompt in `docs/`.
