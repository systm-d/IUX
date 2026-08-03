# Action roles

## Intention

Let a component express what an action *means* — and make it impossible to
express an action that looks like one thing and behaves like another.

## Intents

| Intent | Meaning |
| --- | --- |
| `primary` | the single most important action of a view |
| `secondary` | a supporting action of comparable legitimacy, lower priority |
| `tertiary` | a low-emphasis action, typically without a filled background |
| `destructive` | an action that destroys or irreversibly alters user data |

## The state contract

Each intent owns its complete contract rather than borrowing from shared
fields:

```dart
final class IuxActionColors {
  final Color foreground;
  final Color background;
  final Color border;
  final Color hoveredBackground;
  final Color pressedBackground;
  final Color disabledForeground;
  final Color disabledBackground;
}
```

Grouping the states of one intent is what prevents an incoherent action. A
component receives `IuxActionIntent.destructive` and resolves the whole
contract; it cannot pair a primary background with a destructive label, because
that combination is not expressible.

## Interaction direction

Engagement deepens an action in light conditions and brightens it in dark
conditions. Both directions preserve the foreground contrast.

The naive alternative — always lighten on hover — was measured and rejected:
in light conditions it dropped the primary intent to 4.12:1, below the 4.5:1
contract.

## Example

```dart
final action = IuxSemanticColors.of(context).action.destructive;

Container(
  color: pressed ? action.pressedBackground : action.background,
  child: Text('Delete account', style: TextStyle(color: action.foreground)),
);
```

## Counter-examples

```dart
// Wrong: an intent assembled from unrelated roles.
Container(
  color: colors.action.primary.background,
  child: Text('Delete', style: TextStyle(color: colors.feedback.error.content)),
);

// Wrong: a destructive action distinguished only by its color.
Text('Delete', style: TextStyle(color: colors.action.destructive.foreground));
// Right: wording, confirmation and semantics carry the consequence.
```

## Rules

1. A component receives an intent, never a color.
2. A destructive action's consequence is carried by wording, confirmation and
   semantics — never by hue alone.
3. Hover is unavailable on touch-only devices. It may only reinforce something
   already available.
4. Disabled uses the dedicated disabled roles, not an opacity.

## Limits

- These roles describe appearance only. Confirmation flow, undo and async
  behaviour belong to later missions (IUX-008.6 and IUX-008.7).
- A view with two primary actions is a design problem the token layer cannot
  detect.

## Evidence level

Standard for the contrast contracts. Strong guidance for the intent taxonomy
and for the prohibition on color-only destructive signalling.

## Sources

- WCAG 2.2 — SC 1.4.1 Use of Color, SC 1.4.3 Contrast (Minimum).
- Nielsen Norman Group — error prevention and destructive action confirmation.
