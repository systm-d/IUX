# Brand themes

## Intention

Explain how an organisation applies its own palette without modifying a single
component — and what it takes on by doing so.

IUX ships no brand theme and never will. The framework must be usable by a
bank, a hospital, a school and a startup, which means it cannot assume a
colour, a font or a style.

## How

Supply your own semantic roles:

```dart
final theme = IuxTheme.withSemanticColors(
  const IuxThemeConfiguration(),
  const IuxSemanticColors(
    content: IuxContentColors(...),
    surface: IuxSurfaceColors(...),
    border: IuxBorderColors(...),
    action: IuxActionColorSet(...),
    feedback: IuxFeedbackColorSet(...),
    comparison: IuxComparisonColorSet(...),
    state: IuxStateColors(...),
  ),
);
```

Components read roles, so nothing else changes.

## What you take on

**Contrast becomes your responsibility.** IUX measures the mappings it ships.
It cannot measure yours.

Copy the contract table from
[../accessibility/contrast-contracts.md](../accessibility/contrast-contracts.md)
and test your own roles against it. The test IUX uses is a reasonable starting
point: it walks every pair and reports the measured ratio when one falls short.

At minimum, verify:

- content on every surface it may appear on — 4.5:1;
- disabled content on the base and disabled surfaces — 3:1;
- every border that identifies a control — 3:1;
- every action intent in its resting, hovered and pressed states — 4.5:1;
- every feedback role on its own surface — 4.5:1;
- every comparison role on its own surface — 4.5:1, and its mark 3:1;
- focus, and that it stays distinguishable from selection.

## What must not be bypassed

- **A role's meaning.** Do not map `feedback.error` to a calm colour because
  red is off-brand. If your palette cannot express a failure, the palette is
  the problem.
- **The two vocabularies.** `feedback` classifies news; `comparison` says which
  side of a reference a reading fell on. Mapping `comparison.above` to the same
  values as `feedback.error` is allowed and is what the shipped dark profiles
  do, but mapping them because "above is bad" is deciding for your users
  something only your words can say. See
  [../decisions/ADR-0013-a-reading-is-compared-not-judged.md](../decisions/ADR-0013-a-reading-is-compared-not-judged.md).
- **`comparison.above` and `comparison.below` must differ.** Two directions a
  palette renders identically are one direction, and the reader is left with
  the mark alone.
- **Colour alone.** Every rule in
  [../accessibility/color-and-non-color-signals.md](../accessibility/color-and-non-color-signals.md)
  still applies.
- **Focus visibility.** A focus indicator removed for aesthetic reasons makes
  the application unusable by keyboard.
- **The distinction between focus and selection.**

## A brand choice is not a UX improvement

Per `PROJECT_PROMPT.md` §9, a palette is a `brand_choice`. It may be presented
as an identity decision. It must never be presented as an accessibility or
usability improvement unless it has been measured.

## Limits

- One palette per theme. Contextual palettes are not supported.
- IUX makes no claim about any theme it did not resolve.

## Evidence level

Context dependent for the guidance. Standard for the contrast contracts you
inherit.
