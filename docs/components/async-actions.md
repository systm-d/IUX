# Async actions

## Purpose

Let a user start work that takes time, see that it started, and be told what it
did — without the framework ever claiming an outcome it did not observe.

```dart
final controller = IuxAsyncActionController(
  action: const IuxActionDescriptor.primary(
    semantics: IuxActionSemantics(label: 'Pay'),
  ),
  operation: (IuxAsyncActionSignal signal) async {
    final PaymentResult result = await api.pay();
    return result.isPaid
        ? IuxAsyncOutcome.succeeded(
            feedback: IuxFeedbackEvent.success(
              semanticMessage: l10n.paymentTaken,
              allowAnnouncement: false,
            ),
          )
        : IuxAsyncOutcome.failed(message: l10n.paymentDeclined);
  },
);

IuxAsyncActionButton(
  controller: controller,
  label: l10n.pay,
  busyLabel: l10n.payInProgress,
)
```

## The tension, and how it is resolved

Everything before this mission rests on one rule: **the parent owns the state.**
`docs/feedback/overview.md` puts it plainly — "a framework that guesses will
eventually announce a success that did not happen."

The obvious design for an async button contradicts that rule directly:

```dart
// The design IUX refuses.
IuxAsyncButton(onPressed: () async { await save(); })
```

That button has to decide what the completed future *meant*. It cannot. A
`Future<void>` completing says only that a Dart function returned. A save can
return having written nothing. An HTTP call can come back 500 without throwing.
A button that treated "returned" as "succeeded" would announce a success that
did not happen — the exact failure the framework was built to prevent.

So the helper does **not** own the outcome. Three decisions carry that:

1. **The controller is the parent's object.** `IuxAsyncActionController` is
   created, held and disposed by the parent, like a `TextEditingController`.
   Nothing in the framework instantiates one.

2. **The operation returns its own verdict.** Its type is
   `Future<IuxAsyncOutcome> Function(IuxAsyncActionSignal)` — not
   `Future<void>`. There is no overload that takes a `Future<void>`, so *there
   is no way to hand IUX a future and receive a success out of it*. The
   temptation is not discouraged; it is unrepresentable.

3. **The only outcome the framework derives is a throw.** An exception is an
   observed failure: the operation did not complete. Normal completion is the
   ambiguous case, and that one the operation has to speak for itself. Even
   then the framework supplies no wording — see
   [Failures](#failures-are-never-a-colour).

What the controller *does* own is the bookkeeping every call site otherwise
reimplements, and half of them get wrong:

- flipping to `inProgress` before the first `await`, so a slow start is not an
  unresponsive control;
- dropping a repeat activation while running;
- discarding a result from a superseded run, or from a controller that has been
  disposed.

None of those three require knowing what happened. All three are wrong in most
hand-rolled versions.

## Use when

The user activates something and then waits: a payment, a save over the
network, an export, a sync.

## Avoid when

- **The work finishes within a frame.** The label would flicker and say less
  than nothing. Use `IuxButton`.
- **Several controls share one operation.** The busy state then belongs to the
  region, not to any one button.
- **You want the button to decide the result.** It will not, and no parameter
  will make it.
- **You need a confirmation before the work starts.** Confirmation is a
  pattern, IUX-008.7. This controller starts work; it does not ask about it, so
  it *refuses* a descriptor carrying a confirmation policy rather than treating
  it as already answered. Put an `IuxDestructiveActionController` in front and
  drive this one from its `onConfirmed`.

## A second activation is dropped

`IuxActionRepeatPolicy.ignoreWhileInProgress` is the default on
`IuxActionDescriptor`, and it is what stops a double-tapped "Pay" charging
twice. `activate()` returns `IuxActionOutcome.blocked(alreadyInProgress)`
rather than doing nothing, so a caller can explain the refusal instead of
appearing broken.

Set `IuxActionRepeatPolicy.allow` only when concurrent runs are genuinely
meaningful. The controller then reports the most recent run only: a slower
earlier run that lands last is discarded, because showing its answer would show
the user the older one.

## Cancellation

`IuxActionCancellation` is declared on the descriptor and honoured, not
decorated:

| Declared | Behaviour |
| --- | --- |
| `notSupported` | `requestCancellation()` asserts and returns false. Passing a `cancelLabel` to the button asserts too — a control that appears and then refuses to act reads as broken. |
| `supported` | The request is passed to the operation. A `cancelLabel` renders a stop control beside the running button. |
| `required` | Same, and the button **asserts** when no `cancelLabel` was given. Promising an exit and drawing none is worse than not promising. |

**Cancellation is a request, not a guarantee.** The operation decides what
stopping means; it may close a socket, roll back, or finish anyway because the
money already moved. If it finishes, that completion is reported. Claiming a
payment was cancelled when it went through is the one lie a framework must
never tell.

A cancelled run returns to `idle`, not to `failed`. Nothing was accomplished
and nothing went wrong; putting a recovery path in front of a user who got what
they asked for is noise.

The stop control is a **separate** button beside the running one. Turning the
primary button into "Cancel" under the user's finger would make a second tap
cancel the very thing they were confirming.

## A pending operation without motion

There is no spinner, at any motion preference.

Under `IuxMotionPreference.none` a component must express a change without
movement — `IuxResolvedMotion.requiresStaticAlternative` is true there. A
spinner-only busy state would leave those users with a colour change and
nothing else, and colour alone is not perceivable by everyone either.

So the busy state is a **word**: `busyLabel` replaces `label` while the run is
going. It works at every motion preference, is read out by a screen reader,
survives a 200% text scale, and needs nothing to animate. `busyLabel` is
required rather than defaulted because only the caller can localise it — the
framework composes no user-facing text.

The control also announces itself as busy through `IuxSemantics.action`, since
silence is indistinguishable from a control that did nothing.

## Failures are never a colour

A failure the operation describes carries a localised `message`, and the button
shows it beneath the control on the error role's own surface, with an icon.
Three carriers — wording, shape, colour — so the failure survives a colour
vision deficiency and a monochrome display.

`IuxAsyncOutcome.failed(message: '')` fails on an assertion. An empty message
leaves the user a changed colour and no way to recover.

`IuxAsyncFailure.raised` is the one failure with no message: it is what the
controller produces when an operation throws. The framework will not turn a
stack trace into a sentence for a user, so nothing is rendered and the parent is
expected to map the error to wording and report it again.

## Feedback

The outcome may carry an `IuxFeedbackEvent` the caller composed. The button
relays it through `IuxFeedbackScope`, once per run, and composes nothing.

- No event on the outcome means no feedback. The framework never adds one.
- A rebuild is not a second result; the run's identity guards against
  re-announcing something the user already received.
- When the failure message is also rendered, set `allowAnnouncement: false` on
  the event. The message sits in a live region, so leaving both on makes the
  user hear the same sentence twice.

## States

| State | Source |
| --- | --- |
| idle, in progress, succeeded, failed | the controller, from what the operation returned |
| disabled | `controller.action.availability` |
| pressed, hovered, focused | internal to the button |

`reset()` returns an acknowledged result to idle. It refuses to reset a running
action: that is `requestCancellation()`, and confusing the two would leave work
running with nothing watching it.

## API

### `IuxAsyncActionController`

| Member | Note |
| --- | --- |
| `action` | what the action is, without its lifecycle |
| `descriptor` | the same, carrying the live lifecycle — hand this to a component |
| `value` | the `IuxAsyncActionState`; the controller is a `ValueListenable` |
| `activate()` | attempts an activation, returns the verdict synchronously |
| `requestCancellation()` | asks the run to stop; returns whether the request was passed on |
| `reset()` | clears a result |
| `updateAction(...)` | replaces the description, keeping the lifecycle |

The descriptor handed to the constructor must start `idle`, and cannot be
disabled while a run is going. Both fail on an assertion that says how to fix
them: two owners of one value is how they drift.

### `IuxAsyncActionButton`

| Parameter | Required | Note |
| --- | --- | --- |
| `controller` | yes | parent-owned |
| `label` | yes | visible text when idle, already localised |
| `busyLabel` | yes | visible text while running — see above |
| `cancelLabel` | no | required in practice for `IuxActionCancellation.required` |
| `icon` | no | must be redundant with the label |
| `variant`, `autofocus`, `focusNode`, `expand` | no | as `IuxButton` |

There is no colour, radius, elevation or duration parameter, and there will not
be one.

## Accessibility

- Announced as a button, with its name and enabled state.
- A running button shows `busyLabel` and announces it as a hint after its name.
  The wording is yours: the framework composes none, so it announces nothing it
  was not given. (An earlier version of this document said the button announces
  "In progress". That literal was removed in IUX-008.6 — see IUX-A11Y-008.)
- **A running button is announced as *disabled*.** Its semantics node carries
  `hasEnabledState` without `isEnabled` and offers no tap action, exactly like
  an unavailable control; `busyLabel` in the hint is the whole of the
  difference, and a plain `IuxButton` may omit its `busyHint` and have none.
  Measured in IUX-008.9 against Flutter's own disabled button, which produces
  the same flags. WCAG 2.2 SC 4.1.2 asks for the state the control is actually
  in, and busy is not unavailable.
- The failure message is a live region, so it reaches a screen reader without
  the user having to go looking for it.
- Enter and Space activate it; a disabled or running button is not activated by
  either.
- The failure icon scales with the text beside it.
- At least the resolved touch target floor; the cancel control keeps
  `kIuxMinimumTargetSpacing` from the button through `IuxTargetSpacing`, and
  wraps to a second line rather than overflowing when text is enlarged.

**Verified in widget tests** at 200% text scale on 320×480, right-to-left, and
on all four theme profiles. Still requires manual checking on device: TalkBack
reading order, Voice Access naming, D-pad traversal.

## Anti-patterns

```dart
// Wrong: the operation reports a success it did not check.
operation: (signal) async {
  await api.pay();
  return const IuxAsyncOutcome.succeeded();
}

// Right: it looks at what came back.
operation: (signal) async {
  final result = await api.pay();
  return result.isPaid
      ? const IuxAsyncOutcome.succeeded()
      : IuxAsyncOutcome.failed(message: l10n.paymentDeclined);
}
```

```dart
// Wrong: a controller rebuilt on every frame loses the run it started.
Widget build(context) => IuxAsyncActionButton(
      controller: IuxAsyncActionController(...),
      ...
    );

// Right: held by the State, disposed with it.
late final controller = IuxAsyncActionController(...);
```

```dart
// Wrong: a cancel control on an action that cannot be cancelled.
IuxAsyncActionButton(cancelLabel: l10n.stop, ...)   // cancellation: notSupported
```

## Migration

Additive. `IuxButton` is unchanged and still takes a descriptor the parent
owns. A call site that already tracks `IuxActionOperation` by hand can adopt
the controller incrementally:

```dart
IuxButton(action: controller.descriptor, onActivate: controller.activate)
```

wrapped in a `ListenableBuilder`. `IuxAsyncActionButton` is that composition
plus the busy label, the cancel affordance and the feedback relay.

## Known limitations

- **The success state has no visible text of its own.** It is carried by the
  feedback event the caller composed and by whatever the parent renders. The
  button will not invent a "Done" it cannot localise.
- **`expand` and `cancelLabel` are mutually exclusive**, asserted. A full-width
  button leaves no room beside it; place the cancel affordance in your own
  layout and drive it with `requestCancellation()`.
- **No confirmation flow, and the controller says so.** `activate()` evaluates
  the action with `confirmed: true`, so a descriptor carrying
  `IuxConfirmBeforeExecution` — the default of
  `IuxActionDescriptor.destructive` — used to start the operation on the first
  activation with nothing asked and nothing asserted. It is now refused, on
  the constructor and on `updateAction`, with the composition that works named
  in the message: obtain the answer with `IuxDestructiveActionController` and
  drive this controller from its `onConfirmed`, feeding `descriptor` back
  through `update` so the run shows on the same control. Recorded as
  `IUX-BUTTON-CONFIRM-001`.
- **Activating with the keyboard costs the user their place.** The button stops
  being focusable while the operation runs, because `canRequestFocus` follows
  `action.isActivatable`. Measured: pressing Enter moves focus to the control
  *above*, one Tab then skips past the running button, and when the operation
  finishes focus is never restored. A keyboard user resumes two controls away
  from where they were. Pinned in `test/components/iux_button_qa_test.dart`;
  the fix belongs to `lib/`.
- **No progress *amount*.** This is a busy state, not a determinate bar. A
  percentage belongs to a progress component.
- **`IuxActionRepeatPolicy.allow` reports one run.** If you need per-run
  results, hold a controller per run.
- **Timeouts are the operation's business.** The controller starts nothing on a
  clock, so an operation that hangs leaves the control busy forever. That is
  deliberate: a framework-imposed timeout would be a framework deciding an
  outcome.

## Evidence level

Standard for the accessibility guarantees (WCAG 2.2 SC 1.4.1, 2.5.8, 4.1.2,
4.1.3) and for not relying on motion. Strong guidance for preventing duplicate
submission. Context dependent for replacing the label rather than showing a
spinner, and for placing the cancel control beside the button rather than
inside it.

## Sources

- WCAG 2.2 — SC 1.4.1 Use of Color, SC 1.4.4 Resize Text, SC 2.2.2 Pause Stop
  Hide, SC 2.5.8 Target Size, SC 4.1.2 Name Role Value, SC 4.1.3 Status
  Messages.
- Nielsen Norman Group — response time limits and progress indicators.
- `PROJECT_PROMPT.md` §18 Prévention des erreurs, §32 Mouvement, §33 Feedback.
- `docs/components/component-standard.md` §3, §6, §10.
- `docs/feedback/overview.md` — the parent owns the truth.
