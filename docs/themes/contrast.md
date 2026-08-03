# Contrast

## Intention

Offer reinforced contrast as a preference that combines with everything else.

```dart
IuxTheme.dark(
  profile: const IuxAccessibilityProfile(contrast: IuxContrast.high),
)
```

## What high contrast changes

It does not raise every value uniformly. Raising everything produces a grid of
hard lines in which nothing is emphasised, because emphasis is relative.

| Aspect | Standard | High |
| --- | --- | --- |
| content on base (light) | 17.44:1 | 21:1 |
| standard border on base (light) | 3.67:1 | 14.78:1 |
| border width | 1 | 2 |
| strong border width | 2 | 3 |
| focus ring width | 2 | 3 |
| focus gap | 2 | 3 |
| decorative separators | unchanged | unchanged |

Focus and outlines gain **thickness as well as colour**, so a border stays a
border rather than starting to compete with focus.

## What it deliberately leaves alone

`border.subtle`, the decorative separator, is not reinforced. It groups
content; making it prominent would add visual noise without adding
information.

## Both brightnesses

High contrast exists for dark as well as light. This is the defect this engine
was built to fix: the previous implementation mapped `highContrast` to a
`contrastLevel` while forcing `Brightness.light`, so a user needing both a dark
interface and reinforced contrast had no reachable option.

`test/themes/theme_contrast_test.dart` asserts that a dark high contrast theme
is still dark.

## Limits

- Reinforced contrast is not a substitute for a platform-level accessibility
  setting; it is an application-level offer.
- Flutter exposes `MediaQuery.highContrast`, but a static theme cannot read it.
  Reconciling the platform preference belongs to IUX-005.

## Evidence level

Standard for the ratios. Context dependent for what specifically is
reinforced, which is an IUX judgement.

## Sources

- WCAG 2.2 — SC 1.4.3, SC 1.4.11, SC 2.4.7.
