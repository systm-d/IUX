# Action roles

## Intention

Let a component express what an action *means* — and make it impossible to
express an action that looks like one thing and behaves like another.

## Intents

| Intent | Meaning |
| --- | --- |
| `primary` | the single most important action of a view |
| `secondary` | a supporting action of comparable legitimacy, lower priority |
| `tertiary` | an action that leads away from the task rather than through it |
| `destructive` | an action that destroys or irreversibly alters user data |

## The state contract

Each intent owns its complete contract rather than borrowing from shared
fields:

```dart
final class IuxActionColors {
  final Color foreground;
  final Color background;
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

`foreground` is the label of every variant *and* the outline of every unfilled
one. There was a seventh field, `border`, until IUX-039; nothing painted it —
the only variant that read it drew a zero-width outline — and nothing measured
it, which is how two of the four shipped profiles came to set it to the page
surface itself. It was also the only difference between the `secondary` and
`tertiary` definitions, so the file read as though the two intents were distinct
while every pixel they produced was identical.

`secondary` and `tertiary` are both unfilled: their `background` *is* the page
surface, and that is a statement rather than a placeholder. `IuxButtonResolver`
refuses to draw them filled.

## Interaction direction

Engagement deepens an action in light conditions and brightens it in dark
conditions. Both directions preserve the foreground contrast.

The naive alternative — always lighten on hover — was measured and rejected:
in light conditions it dropped the primary intent to 4.12:1, below the 4.5:1
contract.

Only one intent may reach the neutral extreme when engaged. Both high-contrast
profiles used to end `primary` *and* `destructive` at black (light) or white
(dark) when pressed, which made a pressed "Delete" byte-identical to a pressed
"Save" — in the profile whose entire purpose is separation, at the one moment
the user commits. Primary keeps the extreme; destructive stays inside its own
hue and starts one rung lighter so it has two steps to travel.

## Every intent resolves to something no other intent resolves to

Not a slogan — a test. `test/themes/button_distinguishability_test.dart` sweeps
every intent, every legal variant and every interaction state on all four
profiles, and requires each cell to differ from every other. It is what found
the two collisions above and the `tertiary`/`secondary` one, none of which any
single-case test could see. Two intents that resolve to one appearance mean the
enum promises a difference that does not exist.

The one deliberate exception is `disabled`, which collapses every intent onto a
single palette and is pinned as such: an action that cannot be performed has no
meaning left to express.

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
