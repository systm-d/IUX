# Touch targets at runtime

## Intention

Make the interactive floor impossible to get wrong, by making it one widget
rather than a rule each component re-implements.

```dart
IuxTapTarget(
  onTap: dismiss,
  semanticLabel: 'Dismiss',
  child: const Icon(Icons.close, size: 20),
)
```

The icon stays 20 pixels. The region that responds is at least 48.

## Interactive area is not visual size

These are different things, and conflating them is the most common cause of
controls that are visually fine and practically unhittable. `IuxTapTarget`
separates them: it constrains its own minimum size and hit-tests opaquely, so
the whole region responds rather than only the painted child.

## An override can only raise the floor

`minimumSize` is combined with the resolved minimum using the larger value. A
component cannot opt out of the floor — which is the point of having one.

## Preference-aware

The floor comes from `IuxAccessibility`, so a comfortable target preference
raises every target in the application without any component knowing.

Density never lowers it. A compact layout tightens the space between controls;
it does not shrink the controls.

## Rules

1. Every interactive element uses `IuxTapTarget` or satisfies the floor itself.
2. An icon-only target always carries `semanticLabel`.
3. Disabled targets announce their state; they are not merely greyed.

## Limits

- The floor is a minimum, not a recommendation. Frequently used or destructive
  actions deserve more.
- Spacing *between* targets is a separate concern, and belongs to the layout
  system in IUX-007. Two adjacent 48-pixel targets with no gap still produce
  mis-taps.
- `IuxTouchTargetCheck` is for tests and the catalog. Components use the widget.

## Evidence level

Standard.

## Sources

- Android accessibility — minimum 48dp touch targets.
- WCAG 2.2 — SC 2.5.8 Target Size (Minimum), level AA.
