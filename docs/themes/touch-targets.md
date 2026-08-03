# Touch targets

## Intention

Guarantee a floor for what a finger must hit, and let a user raise it.

| Preference | Minimum |
| --- | --- |
| `standard` | 48 |
| `comfortable` | 56 |

```dart
IuxTheme.light(
  profile: const IuxAccessibilityProfile(
    touchTarget: IuxTouchTargetPreference.comfortable,
  ),
)
```

## Reading it

```dart
final size = IuxGeometryTheme.of(context).minimumTouchTarget;
Container(constraints: BoxConstraints(minHeight: size, minWidth: size));
```

A component reads this value rather than recomputing the rule. There is one
place where the floor is defined, so there is one place where it can be wrong.

## Interactive area is not visual size

A 24-pixel icon may sit inside a 48-pixel target. The visual element stays
small; the region that responds to touch does not.

## During a theme transition

Interpolating linearly between 48 and 56 is safe in both directions, but
interpolating between two *different* themes can momentarily produce a value
below what either intended. `IuxGeometryTheme.lerp` therefore holds the larger
endpoint mid-transition and only lands on the exact value at the bounds.

A target that is briefly too small is a target the user can miss for the
duration of the animation — and animations are exactly when a user is likely
to be reaching for something.

## Limits

- The floor is a minimum, not a recommendation. Frequently used or destructive
  actions deserve more.
- Spacing between targets matters as much as their size; that belongs to the
  layout system in IUX-007.

## Evidence level

Standard.

## Sources

- Android accessibility — minimum 48dp touch targets.
- WCAG 2.2 — SC 2.5.8 Target Size (Minimum), level AA.
