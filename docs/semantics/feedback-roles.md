# Feedback roles

## Intention

Classify a message by what it means for the user, without asserting a hue.

## Roles

| Role | Meaning |
| --- | --- |
| `info` | neutral information requiring no action |
| `success` | confirmation that a user-initiated operation completed |
| `warning` | a consequence to consider before continuing |
| `error` | a failure that blocks progress and needs a recovery path |

Each role provides `content`, `surface`, `border` and `icon`.

## Colour is not the message

These roles never state that success is green or that error is red. They state
that a message belongs to a category. A theme decides the rendering, and under
a constrained palette it may render two categories with the same hue.

That is why the `icon` field exists in the contract rather than being left to
the component: the category must survive a reader who cannot distinguish the
hues, and an icon slot that is part of the contract is harder to forget than
one that is optional.

Roughly 1 in 12 men and 1 in 200 women have some form of colour vision
deficiency, so this is a majority-of-deployments concern, not an edge case.

## Example

```dart
final feedback = IuxSemanticColors.of(context).feedback.error;

Container(
  color: feedback.surface,
  child: Row(children: [
    Icon(Icons.error_outline, color: feedback.icon),
    Text('Payment declined', style: TextStyle(color: feedback.content)),
  ]),
);
```

## Counter-example

```dart
// Wrong: the category exists only in the hue.
Container(color: feedback.surface, child: Text('Declined'));
```

## Rules

1. A feedback role is always accompanied by an icon, wording, or both.
2. An error must state what happened and what the user can do next.
3. Success feedback must not be so loud that it competes with the next task.

## Limits

- These roles cover appearance. Placement, timing, dismissal and screen-reader
  announcement belong to IUX-014 and IUX-015.
- Four categories will not fit every domain. A fifth is a deliberate API
  decision, not a local addition.

## Evidence level

Standard for the non-reliance on colour. Strong guidance for the four-category
taxonomy.

## Sources

- WCAG 2.2 — SC 1.4.1 Use of Color.
- WCAG 2.2 — SC 3.3.1 Error Identification, SC 3.3.3 Error Suggestion.
