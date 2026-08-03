# Border roles

## Intention

Delimit, separate and indicate focus — without encoding thickness in a color.

## Roles

| Role | Meaning | Contract |
| --- | --- | --- |
| `standard` | outline of a control whose boundary identifies it | 3:1 |
| `subtle` | decorative separator grouping content | exempt |
| `strong` | outline that must survive adverse conditions | 3:1 |
| `interactive` | resting outline of an interactive control | 3:1 |
| `focus` | the keyboard focus indicator | 3:1 |
| `selected` | outline of a selected element | 3:1 |
| `disabled` | outline of an inactive control | exempt |
| `error` | outline of a control holding an invalid value | 3:1 |

The role the IUX specification calls `borderDefault` is exposed as `standard`,
because `default` is a reserved Dart word.

## Why `subtle` is exempt

`subtle` separates content decoratively. Removing it must never prevent a task.
It is therefore not held to 3:1 — and for the same reason it must never be used
to delimit an interactive control. If a boundary identifies a control, that
boundary is `standard`, not `subtle`.

## Focus is not selection

They answer different questions. Focus says where the keyboard is; selection
says what the user chose. A list where both are drawn identically cannot be
operated with a keyboard: the user loses track of their own position.

The two roles are distinct, and a theme must keep them visually
distinguishable.

## Example

```dart
Container(
  decoration: BoxDecoration(
    border: Border.all(
      color: hasFocus ? colors.border.focus : colors.border.standard,
      width: hasFocus ? IuxFocusStyle().width : 1,
    ),
  ),
);
```

## Counter-example

```dart
// Wrong: an error reported by an outline alone.
Border.all(color: colors.border.error);
// Right: outline plus a message the screen reader announces.
```

## Rules

1. A border role carries no thickness. Geometry lives in the foundations, so a
   high contrast preference can thicken a border without changing its meaning.
2. `error` is always accompanied by a message.
3. Focus is never removed without an equally visible replacement.

## Limits

- 3:1 is measured against the surface directly behind the border. A border over
  an image or a gradient is not covered.

## Evidence level

Standard for the contrast contracts and for focus visibility. Strong guidance
for the focus/selection separation.

## Sources

- WCAG 2.2 — SC 1.4.11 Non-text Contrast, SC 2.4.7 Focus Visible,
  SC 2.4.11 Focus Not Obscured.
