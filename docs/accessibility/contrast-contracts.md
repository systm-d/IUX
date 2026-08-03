# Contrast contracts

## Intention

State, per role pair, the contrast ratio IUX commits to — so that a theme can
be verified mechanically instead of judged by eye.

## Thresholds

| Contract | Ratio | Applies to |
| --- | --- | --- |
| Normal text | 4.5:1 | body content, labels, links, action labels |
| Large text | 3:1 | ≥18pt, or ≥14pt bold |
| Non-text | 3:1 | control outlines, focus, meaningful icons |
| Disabled | 3:1 | inactive content — see below |

The first three follow WCAG 2.2 SC 1.4.3 and SC 1.4.11 at level AA.

The fourth does not. WCAG explicitly exempts inactive controls from any
contrast minimum. IUX holds 3:1 anyway: a user must be able to read the option
they cannot currently choose, otherwise a disabled control becomes an
unexplained absence. This is a deliberate choice to exceed the standard, and it
constrains the palette — the neutral level used for disabled content was
calibrated specifically to satisfy it against both the base and the disabled
surface.

## Verified pairs

`packages/iux_flutter/test/semantics/contrast_contracts_test.dart` measures
every pair below against both demonstration role mappings. Ratios were
measured with the WCAG relative luminance formula.

### Content

| Pair | Light | Dark | Required |
| --- | --- | --- | --- |
| `content.primary` / `surface.base` | 17.44 | 16.27 | 4.5 |
| `content.primary` / `surface.subtle` | 16.27 | 13.79 | 4.5 |
| `content.primary` / `surface.selected` | 14.41 | 12.61 | 4.5 |
| `content.secondary` / `surface.base` | 7.63 | 10.16 | 4.5 |
| `content.tertiary` / `surface.base` | 4.77 | 6.62 | 4.5 |
| `content.link` / `surface.base` | 9.72 | 8.95 | 4.5 |
| `content.inverse` / `surface.inverse` | 17.63 | 16.27 | 4.5 |
| `content.disabled` / `surface.base` | 3.67 | 3.65 | 3.0 |
| `content.disabled` / `surface.disabled` | 3.16 | 3.10 | 3.0 |

### Borders and focus

| Pair | Light | Dark | Required |
| --- | --- | --- | --- |
| `border.standard` / `surface.base` | 3.67 | 3.65 | 3.0 |
| `border.strong` / `surface.base` | 7.63 | 6.62 | 3.0 |
| `border.interactive` / `surface.base` | 4.77 | 3.65 | 3.0 |
| `border.focus` / `surface.base` | 6.30 | 8.95 | 3.0 |
| `border.error` / `surface.base` | 6.81 | 8.22 | 3.0 |

`border.subtle` is exempt. It separates content decoratively; removing it must
never prevent a task. It must not be used to delimit an interactive control.

### Actions

Every intent is measured in all four background states: resting, hovered and
pressed against the 4.5:1 contract, disabled against 3:1.

| Contract | Lowest observed, light | Lowest observed, dark | Required |
| --- | --- | --- | --- |
| foreground on rest / hover / press | 6.30 | 5.79 | 4.5 |
| disabled foreground on disabled background | 3.16 | 3.10 | 3.0 |

Interaction states change direction by condition: in light an action deepens as
it is engaged, in dark it brightens. An earlier mapping that lightened on hover
in light conditions measured 4.12:1 for the primary intent and was rejected
rather than granted an exception.

### Feedback

| Pair | Light | Dark | Required |
| --- | --- | --- | --- |
| `info` content / surface | 8.03 | 7.59 | 4.5 |
| `success` content / surface | 7.82 | 7.58 | 4.5 |
| `warning` content / surface | 8.41 | 8.31 | 4.5 |
| `error` content / surface | 7.94 | 6.96 | 4.5 |

Each role's border is also verified at 3:1 against the base surface.

## Measurement

`packages/iux_flutter/test/support/contrast.dart` implements relative luminance
and the contrast ratio. It lives under `test/`, not `lib/`, on purpose:
measuring contrast at runtime would let a component correct its own colors, and
a component that repairs a bad palette hides the fact that the palette is bad.

Translucent colors are rejected rather than composited. A translucent color has
no contrast of its own, only one relative to whatever happens to be behind it.

## Rules

1. A theme is responsible for contrast. A component never compensates.
2. Any new role pair that carries meaning must be added to the test matrix.
3. A ratio below its contract is a defect, not a design preference.

## Limits

- These measurements cover the two demonstration mappings only. A theme written
  by an application is not covered.
- Contrast is necessary, not sufficient. It says nothing about reading order,
  screen-reader output, target size or motion.
- Ratios apply to opaque, fully composited colors. Overlapping translucency,
  gradients and images are out of scope.
- WCAG 2.x contrast is known to correlate imperfectly with perceived contrast,
  particularly for dark conditions and for saturated hues. APCA is a candidate
  successor; IUX has not adopted it.

## Evidence level

Standard for the 4.5:1 and 3:1 thresholds. Context dependent for the disabled
contract, which is an IUX decision beyond the standard.

## Sources

- WCAG 2.2 — SC 1.4.3 Contrast (Minimum), level AA.
- WCAG 2.2 — SC 1.4.11 Non-text Contrast, level AA.
- WCAG 2.2 — relative luminance and contrast ratio definitions.
