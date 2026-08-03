# Content roles

## Intention

Rank content by how much the user needs it, not by how it should look.

## Roles

| Role | Meaning | Contract |
| --- | --- | --- |
| `primary` | essential content: body text, headings, meaningful icons | 4.5:1 |
| `secondary` | supporting content that qualifies primary content | 4.5:1 |
| `tertiary` | incidental content: timestamps, counters | 4.5:1 |
| `disabled` | content of an inactive control | 3:1 |
| `inverse` | content on `surface.inverse` | 4.5:1 |
| `onAction` | content on an action background | 4.5:1 |
| `link` | content that navigates or opens a resource | 4.5:1 |

Emphasis decreases from `primary` to `tertiary`, and contrast decreases with
it — but every level stays above 4.5:1. Lower emphasis means less visual
weight, never less legibility.

## Example

```dart
final colors = IuxSemanticColors.of(context);

Text('Order #4182', style: TextStyle(color: colors.content.primary));
Text('Placed 3 days ago', style: TextStyle(color: colors.content.tertiary));
```

## Counter-examples

```dart
// Wrong: hides information the user needs in order to act.
Text('Payment failed', style: TextStyle(color: colors.content.tertiary));

// Wrong: a link identified by color alone.
Text('Terms', style: TextStyle(color: colors.content.link));
// Right: pair it with an underline or an explicit affordance.
```

## Rules

1. Never use a lower-emphasis role to de-emphasise information required to
   complete a task. If it is not needed, remove it; if it is needed, rank it
   honestly.
2. `link` must be accompanied by a non-color affordance.
3. `disabled` must be paired with disabled semantics, so a screen-reader user
   learns the control is unavailable.

## Limits

- These roles say nothing about type size, weight or spacing. Those belong to
  the typography foundations.
- `onAction` is only valid on an action background from the same theme.

## Evidence level

Standard for the contrast contracts. Strong guidance for the three-level
emphasis scale, which is conventional rather than empirically fixed.

## Sources

- WCAG 2.2 — SC 1.4.3 Contrast (Minimum), SC 1.4.1 Use of Color.
