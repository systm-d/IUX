# Surface roles

## Intention

Express interface hierarchy through color, so that hierarchy survives when a
shadow cannot be seen.

## Roles

| Role | Meaning |
| --- | --- |
| `base` | the background of a screen |
| `subtle` | a recessed grouping surface |
| `raised` | a surface above the base, such as a card |
| `overlay` | a surface above the page, such as a dialog or sheet |
| `interactive` | the resting background of an interactive area |
| `selected` | the background of a selected element |
| `disabled` | the background of an inactive control |
| `inverse` | a surface whose content uses `content.inverse` |

## Why not shadows

A shadow is nearly invisible on a dark surface, is removed by a reduced visual
stimulation preference, and conveys nothing to a screen reader. A surface that
relies on a shadow to be perceived as raised is not raised for a large share of
users.

IUX therefore separates levels by surface contrast, and treats a shadow as
reinforcement rather than the signal.

## Example

```dart
Container(
  color: colors.surface.raised,
  child: Text('Total', style: TextStyle(color: colors.content.primary)),
);
```

## Counter-example

```dart
// Wrong: the level exists only in the shadow.
Container(
  decoration: BoxDecoration(
    color: colors.surface.base,
    boxShadow: const [BoxShadow(blurRadius: 8)],
  ),
);
```

## Rules

1. A level must be distinguishable without a shadow.
2. `content.primary` must remain readable on every surface a component may
   place it on. This is verified for `base`, `subtle`, `raised`, `overlay` and
   `selected`.
3. `selected` must be paired with a non-color signal.

## Limits

- Surface separation in light conditions is intentionally small (about 1.07:1
  between `base` and `subtle`). It groups content; it does not identify a
  control. Anything that must be identified needs a border.
- The number of levels is fixed. A design needing a sixth level of depth is
  probably too deep to be understood.

## Evidence level

Strong guidance. The preference for non-shadow elevation in dark conditions is
widely recommended; the exact separation values are an IUX choice.

## Sources

- Material Design 3 — Elevation and surface tint in dark themes.
- WCAG 2.2 — SC 1.4.11 Non-text Contrast.
