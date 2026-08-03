# State roles

## Intention

Cover interaction states that apply to any element, whatever its intent.

## Roles

| Role | Meaning |
| --- | --- |
| `focus` | the keyboard focus indicator |
| `selected` | the indication that an element is chosen |
| `hovered` | a tint while a pointer rests on an element |
| `pressed` | a tint while an element is being activated |
| `dragged` | a tint while an element is being moved |

States scoped to a single action intent live in `IuxActionColors` instead, so
an action never assembles its appearance from two competing sources.

## Two deliberate omissions

**No `disabled` role.** Inactive elements use the dedicated `disabled` roles of
the content, surface and border groups. The common alternative — applying an
opacity to an active color — produces an unpredictable ratio, because the
result depends on whatever happens to be behind it. A dedicated color can be
measured; an opacity cannot.

**No `loading` color.** A pending operation is communicated through progress
semantics and an accessible announcement. A hue tells a screen-reader user
nothing, and tells a sighted user less than a progress indicator does.

## Focus versus selection

Distinct roles, distinct questions: focus says where the keyboard is,
selection says what the user chose. See
[border-roles.md](border-roles.md).

## Example

```dart
final state = IuxSemanticColors.of(context).state;

DecoratedBox(
  decoration: BoxDecoration(
    border: Border.all(color: state.focus, width: 2),
  ),
);
```

## Counter-example

```dart
// Wrong: disabled expressed as an opacity over an unknown background.
Opacity(opacity: 0.38, child: Text('Continue'));
// Right: colors.content.disabled, which is measured.
```

## Rules

1. Focus and selection stay visually distinguishable.
2. Selection is paired with a non-color signal and the `selected` semantics
   flag.
3. Hover only reinforces information available elsewhere.

## Limits

- `hovered`, `pressed` and `dragged` are tints intended to be composited over a
  surface. Their contrast is therefore not independently verifiable and they
  must not be the only carrier of a state.

## Evidence level

Standard for focus visibility. Context dependent for the decision to model
disabled with dedicated colors rather than opacity, which is an IUX choice
made to keep contrast measurable.

## Sources

- WCAG 2.2 — SC 2.4.7 Focus Visible, SC 1.4.11 Non-text Contrast.
