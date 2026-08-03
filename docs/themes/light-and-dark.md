# Light and dark

## Intention

Two usage conditions, not two moods.

## Light

- content reaches 17.44:1 against the base surface;
- surfaces separate gently (about 1.07:1) — enough to group, not enough to
  fence content in;
- actions **deepen** as they are engaged.

## Dark

- the base surface is `#151A23`, deliberately not pure black;
- content is `#F6F7F9`, deliberately not pure white;
- surfaces separate more strongly than in light, because a dark interface has
  no shadow to fall back on;
- actions **brighten** as they are engaged.

## Why not pure black

A fully black background removes the ability to express elevation through
surface contrast — and in dark conditions surface contrast is the only
elevation signal that survives, since a shadow on black is invisible.

Pure white text on pure black also produces halation for many readers,
particularly those with astigmatism: the glyphs appear to bleed into the
background. Both ends of the ramp are pulled in slightly.

## Why engagement reverses direction

In light conditions an action deepens on hover and press; in dark it brightens.
Both directions increase separation from the surface while preserving the
foreground contrast.

The naive alternative — always lighten — was measured and rejected: it dropped
the primary action to 4.12:1 in light conditions, below the 4.5:1 contract.

## Counter-example

```dart
// Wrong: a component deciding what dark means.
final background = isDark ? Colors.black : Colors.white;

// Right: the role, resolved by whichever theme is installed.
final background = IuxSemanticColors.of(context).surface.base;
```

## Limits

Measured ratios apply to the shipped mappings. Perceived contrast in dark
conditions correlates imperfectly with the WCAG 2.x formula.

## Evidence level

Standard for the ratios. Strong guidance for avoiding pure black and pure
white. Hypothesis for the reversed engagement direction, which was adopted
because it satisfies the contracts, not because it was user-tested.

## Sources

- WCAG 2.2 — SC 1.4.3, SC 1.4.11.
- Material Design 3 — dark theme surface guidance.
