# Feedback

## Intention

Tell the user that something happened — proportionately, through more than one
channel, and only when the parent says it did.

```dart
IuxFeedbackScope.of(context).emit(
  context,
  IuxFeedbackEvent.success(semanticMessage: l10n.orderPlaced),
);
```

## The parent owns the truth

The runtime never infers that something succeeded, failed or finished. It
cannot know, and a framework that guesses will eventually announce a success
that did not happen.

The parent holds the state and emits the event. That is why there is no
`onSuccess` hook anywhere in this engine.

## Roles and proportion

| Role | Intensity | Haptic | Interrupts |
| --- | --- | --- | --- |
| `interaction` | subtle | selection | no |
| `selection` | subtle | selection | no |
| `confirmation` | subtle | light | no |
| `success` | moderate | light | no |
| `progress` | none | **none** | no |
| `warning` | moderate | medium | no |
| `error` | strong | heavy | **yes** |
| `destructive` | strong | heavy | **yes** |

Only failures and irreversible consequences interrupt a screen reader.
Interrupting for a success trains users to turn announcements off — at which
point the failures stop being heard too.

`progress` never vibrates: an ongoing operation would mean repeated vibration.

## Feedback is multimodal, and no channel is guaranteed

`emit` returns an `IuxFeedbackOutcome` saying what actually happened. Haptics
may be disabled by the application or unfelt on the device; announcements are
unsupported on some platforms and are discouraged on Android.

`anyChannelResponded == false` is a normal outcome. That is precisely why the
**visual state must always carry the information on its own**, and why haptics
and announcements only ever reinforce it.

## Deduplication

An identical event within a short window is dropped, so that:

- a parent and a component both reporting the same outcome vibrate once;
- a retry loop does not vibrate five times.

Identity defaults to role plus message, and can be overridden with
`dedupeKey`. `IuxFeedbackController.reset()` lets a genuine second attempt
report again even though it looks the same.

The window is deliberately short: long enough to absorb a double emission,
short enough that a real second attempt still registers.

## Localisation

The engine holds roles, never user-facing strings. `semanticMessage` arrives
already localised from the caller, so the engine can never leak an English
sentence into a Japanese application.

## No global singleton

The controller is provided by an `IuxFeedbackScope`. A singleton cannot be
configured per subtree, cannot be replaced in a test without leaking state
between tests, and hides who is emitting what.

A missing scope throws rather than discarding the event: silently delivering
nothing is a defect that must surface in development, not in the field.

## Rules

1. Never emit an event the parent did not ask for.
2. Never let a haptic or an announcement be the only signal.
3. One user-visible event produces at most one haptic.
4. Never emit `interaction` feedback on scroll or hover.

## Limits

- Flutter does not report whether the platform's own haptic setting is on, so
  a performed haptic may be felt by nobody.
- Announcement support varies and is reported, not assumed.
- The engine defines policy. Snackbars, dialogs and loaders are IUX-013 to
  IUX-015.

## Evidence level

Standard for multimodality and for not relying on a single channel. Context
dependent for the role-to-intensity mapping. Hypothesis for the deduplication
window.

## Sources

- WCAG 2.2 — SC 1.4.1 Use of Color, SC 4.1.3 Status Messages.
- Android — `View.announceForAccessibility` deprecation.
