# iux_flutter

`iux_flutter` is the primary Flutter package for IUX (Intuitive UX): a set of
foundations, semantic intentions, components and UX patterns for building
Android-first interfaces that are accessible, understandable and consistent.

It is not a visual design system. Components express an intention — a primary
action, a destructive action, an error the user can recover from — and a theme
decides what that looks like. No component takes a colour, a radius, an
elevation or a duration.

The package is experimental. Its public API is not stable, and it does not
claim WCAG conformance for any application built with it: it measures the
contrast of the palettes it ships and states what it has not verified.

## Use

```dart
import 'package:iux_flutter/iux_flutter.dart';

MaterialApp(
  theme: IuxTheme.light(),
  darkTheme: IuxTheme.dark(),
  home: IuxPage(
    child: IuxButton(
      label: 'Save',
      action: const IuxActionDescriptor.primary(
        semantics: IuxActionSemantics(label: 'Save'),
      ),
      onActivate: save,
    ),
  ),
)
```

`lib/iux_flutter.dart` is the only entry point. Nothing under `lib/src/` is
part of the public API, and the primitive colour palette is deliberately not
exported: a component that could reach a raw colour could bypass the contrast
guarantees a theme is responsible for.

## What is here

Foundations (spacing, typography, motion, density, touch targets), a semantic
colour layer, a theme engine covering light, dark and high contrast, an
accessibility runtime that reconciles application preferences with platform
ones, and — built on those — components and patterns from buttons and text
fields to guided forms, destructive flows, onboarding and error recovery.

## Requirements

Flutter 3.35.0 or newer, Dart 3.8.0 or newer. Only Flutter 3.44.8 has run the
test suite.

## Before proposing an API

Read the repository [PROJECT_PROMPT](../../PROJECT_PROMPT.md) and
[COMPONENT_STANDARD](../../COMPONENT_STANDARD.md). Decisions that affect
accessibility are recorded, with their evidence level and their known limits,
in `docs/evidence/`.
