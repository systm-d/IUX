# Semantic tokens

## Intention

A component must be able to render correctly in light conditions, dark
conditions and high contrast without knowing that any of those exist. It
achieves that by never naming a color.

Instead it names a role — "the primary action background", "disabled content",
"the focus indicator" — and a theme decides what that role looks like. The
component expresses meaning; the theme expresses appearance.

```dart
final colors = IuxSemanticColors.of(context);
Container(color: colors.action.primary.background);
```

Never:

```dart
Container(color: Colors.blue); // breaks in dark, breaks in high contrast
```

## Layers

```text
Primitive colors   (internal, a hue and a level, no meaning)
        ↓
Semantic roles     (public, a meaning, no appearance)
        ↓
Themes             (IUX-004: resolve roles for a set of conditions)
        ↓
Components         (read roles only)
```

The direction is strict. Primitives never reach a component. A component never
reconstructs a role. This is what makes a palette change a theme-level edit
rather than a sweep through every widget.

## Role groups

| Group | Type | Covers |
| --- | --- | --- |
| `content` | `IuxContentColors` | text, icons, links, disabled content |
| `surface` | `IuxSurfaceColors` | backgrounds and hierarchy levels |
| `border` | `IuxBorderColors` | outlines, dividers, focus |
| `action` | `IuxActionColorSet` | four intents, each with its full state contract |
| `feedback` | `IuxFeedbackColorSet` | info, success, warning, error |
| `comparison` | `IuxComparisonColorSet` | above, at, below — which side of a reference a reading fell on |
| `state` | `IuxStateColors` | focus, selection, hover, press, drag |

Each group is documented separately:

- [content-roles.md](content-roles.md)
- [surface-roles.md](surface-roles.md)
- [border-roles.md](border-roles.md)
- [action-roles.md](action-roles.md)
- [feedback-roles.md](feedback-roles.md)
- [comparison-roles.md](comparison-roles.md)
- [state-roles.md](state-roles.md)

## Why grouped rather than flat

An earlier iteration exposed ten flat `Color` fields. That shape could not
express an action's pressed state, a feedback border, or the difference
between focus and selection, and it invited a component to assemble an
appearance from unrelated fields.

Grouping by responsibility makes an incoherent combination hard to write: an
action's states travel together, so a component cannot pair a primary
background with a destructive foreground.

## Resolution

```dart
IuxSemanticColors.of(context)      // throws if no IUX theme is installed
IuxSemanticColors.maybeOf(context) // returns null instead
```

`of` fails loudly on purpose. A silent fallback would render a plausible but
unverified interface and hide the misconfiguration until it reached a user.

## Rules

1. A component reads roles; it never reads primitives and never hardcodes a
   color.
2. A role name states intent. A role must never be named after a hue.
3. Color alone never carries meaning. See
   [color-and-non-color-signals.md](../accessibility/color-and-non-color-signals.md).
4. Contrast is a theme's responsibility, verified by tests, not repaired at
   runtime by components.

## Limits

- Roles guarantee nothing about a theme an application writes itself. The
  contrast contracts are verified for the mappings IUX ships and tests.
- Passing the automated contrast tests is not WCAG conformance. Real content,
  real typography and real screen readers must be verified in context.
- No theme exists yet. Until IUX-004, an application supplies its own
  `IuxSemanticColors`.

## Evidence level

Strong guidance. Semantic token layers are established practice across design
systems (Material Design 3 color roles, US Web Design System). The specific
role decomposition here is an IUX design decision, not a standard.

## Sources

- Material Design 3 — Color roles.
- WCAG 2.2 — SC 1.4.1 Use of Color, SC 1.4.3 Contrast (Minimum),
  SC 1.4.11 Non-text Contrast.
- ADR-0002 — [semantic colors and `ColorScheme`](../decisions/ADR-0002-semantic-colors-and-color-scheme.md).
