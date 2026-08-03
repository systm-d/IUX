# Density

## Intention

Let an interface trade information quantity against breathing room, without
letting that trade reach the size of what a finger must hit.

```dart
IuxTheme.light(
  profile: const IuxAccessibilityProfile(density: IuxDensity.comfortable),
)
```

## Levels

| Level | Spacing factor | Default spacing |
| --- | --- | --- |
| `compact` | ×0.875 | 14 |
| `standard` | ×1 | 16 |
| `comfortable` | ×1.125 | 18 |

## The invariant

**Density never reduces the minimum touch target.**

A compact layout tightens the space *between* controls. It does not shrink the
controls. The two are frequently confused, and confusing them is how a dense
interface becomes unusable for anyone with a tremor or an imprecise pointer.

`minimumTouchTarget` is resolved from the touch target preference alone, never
from density, and a test asserts the floor holds at every density.

## Text scaling

Density scales spacing, not type. A user who enlarges text keeps that
enlargement at every density; the two settings do not fight.

## Counter-example

```dart
// Wrong: density used to shrink a control.
final size = density == IuxDensity.compact ? 36.0 : 48.0;

// Right: the resolved floor, whatever the density.
final size = IuxGeometryTheme.of(context).minimumTouchTarget;
```

## Limits

The three levels are fixed. An application needing a fourth is probably
encoding a layout decision as a density.

## Evidence level

Standard for the touch target floor. Context dependent for the specific
factors, which are an IUX choice.

## Sources

- Android accessibility — minimum 48dp touch targets.
- WCAG 2.2 — SC 2.5.8 Target Size (Minimum).
