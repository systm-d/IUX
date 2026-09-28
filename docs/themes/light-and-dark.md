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

## Feedback in dark is not tinted

In both dark profiles, `feedback.info.surface`, `feedback.success.surface`,
`feedback.warning.surface` and `feedback.error.surface` are one colour:
`neutral80`, the same neutral as `surface.subtle`. The field exists per role,
and in dark the value does not vary by role.

**The category is carried by everything except the fill**: the words, the icon —
four distinct glyphs, with success and error, the pair colour confuses most, on
different silhouettes (`IUX-GLYPH-SILHOUETTE-001`) — the content colour and the
border. A status banner whose *fill* said "failure" in another design
system says it here through those four, and should be designed for that rather
than around it.

This is inherited rather than chosen, and the reason is a measurement gap, not a
taste: a dark tint of a hue is a colour nobody has measured. Every hue in the
dark palettes — feedback, and the comparison accents after it — sits on that
same neutral and is separated by content alone. `IUX-PALETTE-PERCEPTION-001`
measured the result: the four surfaces are 0.0 apart on every pair. It was
reported from a migration that met it by finding four token paths returning the
same colour (systm-d/IUX#72), which is the wrong way to learn a visual language.
Recorded as `IUX-FEEDBACK-DARK-SURFACE-001`.

## Do not soften a token with alpha

The instinct is common — `withValues(alpha: 0.5)` on a border to make it
quieter, or on a feedback colour to dilute a tint. Every IUX role is measured
*as shipped*, opaque, against the surface it is documented to sit on. Alpha
blends it with whatever is behind it, and the ratio the role promised is no
longer the ratio on screen: `feedback.*.border` targets 3:1 against the surface
behind the feedback, and a half-transparent border does not. The same migration
had been diluting its old tint this way and dropped it for exactly this reason.

If a role is too loud, the fix is a different role, or a palette passed to
`IuxTheme.withSemanticColors` and measured — not a transparency the contrast
tests cannot see.

## Counter-example

```dart
// Wrong: a component deciding what dark means.
final background = isDark ? Colors.black : Colors.white;

// Right: the role, resolved by whichever theme is installed.
final background = IuxSemanticColors.of(context).surface.base;
```

## Limits

Measured ratios apply to the shipped mappings. Perceived contrast in dark
conditions correlates imperfectly with the WCAG 2.x formula — measured in
`IUX-PALETTE-PERCEPTION-001`, where a control outline tuned to the same ratio in
both polarities delivers under half the perceived contrast in dark.

## Evidence level

Standard for the ratios. Strong guidance for avoiding pure black and pure
white. Hypothesis for the reversed engagement direction, which was adopted
because it satisfies the contracts, not because it was user-tested.

## Sources

- WCAG 2.2 — SC 1.4.3, SC 1.4.11.
- Material Design 3 — dark theme surface guidance.
