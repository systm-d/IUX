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
| link on base (light) | 6.30:1 | 13.52:1 |
| standard border on base (light) | 3.67:1 | 14.78:1 |
| border width | 1 | 2 |
| strong border width | 2 | 3 |
| focus ring width | 2 | 3 |
| focus gap | 2 | 3 |
| decorative separators | unchanged | unchanged |

Focus and outlines gain **thickness as well as colour**, so a border stays a
border rather than starting to compete with focus.

## The standard profile aims at AA with margin, not at AAA

The two profiles have to do **different jobs**, and that is a design decision
with a measurement behind it rather than a preference.

Until `IUX-PALETTE-HEADROOM-001` every chromatic content role in the standard
light profile measured past AAA on white:

| role | was | measured | now | measured |
| --- | --- | --- | --- | --- |
| `content.link`, `feedback.info.content` | `accent30` | 9.72:1 | `accent40` | **6.30:1** |
| `feedback.success.content` | `positive30` | 9.16:1 | `positive40` | **6.31:1** |
| `feedback.error.content` | `critical30` | 9.69:1 | `critical40` | **6.81:1** |
| `feedback.warning.content` | `caution30` | 9.60:1 | `caution40` | **5.94:1** |

That cost two things at once.

**Structurally**, `highContrastLight` had nowhere to go. It moves the link from
`accent30` to `accent20` — one rung — so the setting whose entire purpose is
separation returned almost nothing, because the standard profile had already
spent it.

**In use**, the first report from a user shown the light theme was that "the
contrast is too dark — dark blue, dark green, dark red, it is too much". Four
roles darkened until they resembled each other more than they resembled their
own meanings. A semantic colour that no longer reads as its own hue has stopped
being semantic.

The contract is now two-sided, and `test/themes/theme_contrast_test.dart` is the
only place in the suite that asserts an **upper** bound on contrast:

- standard clears AA on every chromatic content role and stops short of AAA;
- high contrast clears AAA on every one of them;
- and high contrast measures strictly higher than standard **role by role**,
  not on average — asking for more contrast has to give more.

`content.primary` is exempt and always will be. It is neutral, there is no
second neutral for it to be confused with, and it should be as dark as the
surface allows in both profiles.

## The caution ramp bends towards orange as it darkens

Held above 4.5:1 on white, a yellow is not a yellow. `caution30` and `caution40`
were `#5E3F00` and `#7D5400` — 9.60:1 and 6.69:1, and khaki browns to look at.
A consuming application had to leave the ramp entirely and pick its own hue to
get a warning anybody recognised.

The dark end of the ramp is therefore orange (`#A34A00`, 5.94:1) and the light
end stays amber. That is not an inconsistency: the hue that reads as "warning"
is not the same hue at every lightness. `caution70` and `caution80` are content
on **dark** surfaces and `caution90` is a tint on a light one, where an orange
bright enough to sit on `neutral90` would drift towards the critical ramp and
stop being distinguishable from an error.

A test holds the bend in place: the warning content's hue must stay below 35°
and must sit measurably apart from the surface behind it.

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
- **The upper bound is a judgement, not a standard.** WCAG sets floors and no
  ceilings, so "stop short of AAA in the standard profile" is IUX's own rule,
  argued from what it costs the high contrast profile and from one user's
  report. It would be wrong for an application whose users mostly need AAA and
  will never open a settings screen; such an application should ship
  `IuxContrast.high` as its default rather than push the standard profile up.
- **The caution hue was chosen on one report and one measurement.** `#A34A00`
  is the value a consuming application arrived at and shipped; that it reads as
  a warning rather than as a brown is a judgement about perception that nothing
  here tests, and hue perception is exactly where a contrast ratio says least.
- Every ratio on this page is computed from the WCAG 2.x formula, which
  correlates imperfectly with perceived contrast. APCA is a candidate successor
  IUX has not adopted, and it would likely disagree with the numbers above.
- Flutter exposes `MediaQuery.highContrast`, but a static theme cannot read it.
  Reconciling the platform preference belongs to IUX-005.

## Evidence level

Standard for the ratios. Context dependent for what specifically is
reinforced, which is an IUX judgement.

## Sources

- WCAG 2.2 — SC 1.4.3, SC 1.4.11, SC 2.4.7.
