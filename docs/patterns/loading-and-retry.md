# Loading and retry

## Purpose

Give a region driven by one load exactly one thing to show at a time: the wait,
the content, or the failure and the way out of it.

```dart
IuxLoadingRetry<List<Order>>(
  state: controller.state,
  loadingLabel: l10n.loadingYourOrders,
  failureCategoryLabel: l10n.error,
  recovery: IuxRetryRoute(
    label: l10n.tryAgain,
    semanticLabel: l10n.reloadYourOrders,
    onRetry: controller.load,
    isRunning: controller.isRunning,
    busyHint: l10n.reloadingYourOrders,
  ),
  builder: (BuildContext context, List<Order> orders) => OrderList(orders),
)
```

## The defect this exists to remove

`IuxLoadingIndicator` and `IuxErrorRecovery` already existed before this
pattern, and it draws neither. What it contributes is the **invariant between
them**.

A region fed by one request is nearly always driven by three independent
values — `isLoading`, `error`, `items` — and they drift. The results are
familiar enough to name:

| The drift | What the user sees |
| --- | --- |
| `isLoading` left true after the list arrived | a spinner over content |
| an error not cleared when the retry started | "failed" beside a running wait |
| an error cleared without the wait restarting | a blank region and no explanation |
| `items` empty and `error` null while a request is in flight | "Nothing here" for a question not yet answered |

Every one of those is two answers at once, or none. None is constructible here:
`IuxLoadState` is one sealed value, `IuxLoadingRetry` is one `switch` over it,
and a fourth state added later fails to compile at this widget rather than
falling through to a blank region.

## The four states, and why one of them is not here

| The region is | `IuxLoadState` | What is on screen |
| --- | --- | --- |
| waiting | `IuxLoadInProgress` | `IuxLoadingIndicator`, carrying `loadingLabel` |
| answered | `IuxLoadReady<T>` | whatever `builder` returns for the value |
| answered with nothing | `IuxLoadReady<T>` with an empty value | whatever `builder` returns — normally `IuxEmptyState` |
| broken | `IuxLoadFailed` | `IuxErrorRecovery`, carrying the message and the route |

**There is no `IuxLoadState.empty`, and that is a decision rather than an
omission.** An empty result is not a state of the operation: the load succeeded
and what came back has no rows in it.

The stronger reason is what a fourth value would cost. `IuxEmptyStateCause`
already refuses to treat "empty" as one situation — a collection nobody has
filled, a filter that excluded everything, an account without permission and a
queue the user emptied on purpose are four screens with four different exits,
and the pairing is unrepresentable rather than validated. A single `empty` here
would flatten all of that into one word, and put the most common mis-pairing in
the category — "Add your first invoice" under a filter that hid forty of them —
one enum value away again.

So the empty case goes through the builder, and the caller names the situation:

```dart
builder: (BuildContext context, List<Order> orders) => orders.isEmpty
    ? IuxEmptyState(
        cause: IuxNoMatches(reset: clearFilters),
        title: l10n.noOrdersMatchTheseFilters,
      )
    : OrderList(orders),
```

The invariant survives — exactly one branch is on screen either way — and
`IuxEmptyState` makes the same division from its own side, telling callers to
reach for it "once `IuxLoadState` is ready with an empty value". The two
patterns meet at one point and neither learns the other's vocabulary.

## The failure is `IuxErrorRecovery`, and there is no second retry model

IUX-029 shipped `IuxRecoveryRoute`: a sealed type with `IuxRetryRoute` for a
failure that repeating could fix, `IuxAlternativeRoute` for one it could not,
and `IuxUnrecoverable` for one nothing will. It derives its `IuxActionDescriptor`
rather than accepting one, so a retry cannot be given a confirmation policy, the
wrong role, or a repeat policy that lets two run at once.

This pattern takes that type and hands it, with `IuxLoadFailed.message`, to
`IuxErrorRecovery`. It defines no retry model of its own.

The first draft of this mission did define one — an `IuxRetryAction` wrapping an
`IuxActionDescriptor` with four assertions refusing the combinations
`IuxRecoveryRoute` makes unrepresentable. It was deleted. Two vocabularies for
"the way out of a failure" is exactly the duplication the library declines
elsewhere, and the local version was strictly worse: it had no category label,
which is the only carrier of "this is a failure" that survives a screen reader
(SC 1.4.1), and it allowed a failure with no way out, which `IuxErrorRecovery`
refuses in order to meet SC 3.3.3 structurally.

`recovery` belongs to the **region**, not to the individual failure. Where the
honest route depends on which failure happened — a timeout that may be retried,
a 403 that may not — the parent recomputes it beside the state, which it can,
because it produced both from the same answer. See `IuxRecoveryRoute` for the
table of which failures may honestly be retried.

## Nothing retries on its own

There is no timer, no backoff schedule and no attempt counter, and there will
not be one.

1. **Only the caller knows whether the operation is safe to repeat.** A read is;
   a request that created an order is not. A framework that re-fired one would
   eventually charge a card twice, and nothing here can inspect the operation to
   find out which it is.
2. **An automatic retry is an activation the user did not make.** The action
   model exists to stop a double-tapped control running twice; a pattern that
   fired the same request on a schedule would reintroduce that one layer up.
3. **It hammers a service that is already failing**, hardest at the moment it
   can least take it, while showing the user a screen that looks stuck.
4. **It is an accessibility problem before it is a traffic problem.** A region
   that silently re-enters the wait re-fires the live region, so a
   screen-reader user is interrupted on a cadence they did not set and cannot
   stop.

**What stops a user doing it by hand** is two mechanisms, neither of them a
timer:

- in the default flow the control does not exist while the load runs, so there
  is nothing to press;
- when the parent drives `IuxRetryRoute.isRunning` instead, the derived
  descriptor carries `IuxActionRepeatPolicy.ignoreWhileInProgress` and
  `IuxActionPolicy` drops the second activation — the same mechanism that stops
  a double-tapped "Pay" charging twice, rather than a second copy of it.

## Nothing times out either, and what WCAG says about that

A load that never comes back stays a load. This pattern will not decide, after
some number of seconds, that the operation failed. It did not fail — it has not
answered — and reporting an outcome the operation never reported is the one
thing `IuxLoadState` exists to make impossible.

**SC 2.2.1 (Timing Adjustable)** therefore has nothing to bind. The criterion
applies to time limits *set by the content* which the user must respond within;
a region that waits indefinitely sets none, removes nothing on a schedule, and
asks the user for nothing. A framework-imposed timeout would have created
exactly such a limit, on a screen where the user has no way to turn it off,
extend it or be warned about it, and would then have needed one of the
criterion's exceptions to be conformant. Not having one is simpler and more
honest: if a request must give up, the operation gives up, and the parent
reports a failure it can put into words.

**SC 2.2.2 (Pause, Stop, Hide)** does not bind the moving bar. It applies to
motion that starts automatically, lasts more than five seconds **and** is
presented in parallel with other content. The wait *replaces* the region's
content rather than sitting beside it, and a progress indicator is the canonical
case of the criterion's own essential-motion exception — the movement is the
information, and freezing it would say the operation had hung.

**SC 2.3.3 (Animation from Interactions, AAA)** is the one that does apply, and
it is honoured through `IuxMotionPolicy`: see "Motion" below.

## The delay threshold, and why it is not in the widget

A spinner shown for a load that resolves in eighty milliseconds is a flash that
reads as a glitch. It is a real defect. It is not one this widget can fix.

**What was measured.** One full traversal of the indeterminate bar, resolved
through `IuxProgressResolver` at the standard motion preference, is **1800 ms**
(`IuxMotionDuration.long` × 6). Under a reduced preference it is never shorter —
halving a cycle doubles how often the segment sweeps past, so the traversal has
a floor. Under `IuxMotionPreference.none` it is `Duration.zero` and the bar is
replaced by the label. Those three numbers are asserted in
`test/patterns/iux_loading_retry_test.dart`.

A load that resolves in 80 ms therefore shows the bar for **less than a
twentieth of one crossing**. The user does not see a bar traverse; they see
something appear at one position and vanish from it. That is why the flash reads
as a rendering fault rather than as work being done, and it is a measurement
rather than an aesthetic judgement.

**Where the threshold belongs.** To delay the indicator, the region has to
render something else in the meantime, and it has exactly two options:

- **nothing** — the region collapses, so the user gets two layout changes
  instead of one and a window in which the region reports neither a wait nor
  content;
- **the previous content** — the widget claims `IuxLoadState.ready` while the
  parent says otherwise, which is the precise lie the sealed state was built to
  make unconstructible.

A timer would also make the rendered branch a function of wall-clock time rather
than of the state the widget was handed: two `IuxLoadingRetry` widgets with
identical `state` would show different things. That is the one property the
whole design rests on.

So the threshold is documented and left with the caller, who is the only one who
knows it: **a parent expecting an answer inside the window in which people
perceive a system as responding at all should not enter `IuxLoadState.loading`.**
It holds `ready` and swaps the value when the answer arrives.

That window is roughly **0.1 s**. Miller (1968) and Nielsen (1993) independently
put it there: below about a tenth of a second a system is perceived as reacting
instantaneously and needs no feedback beyond the result; the second landmark,
about **1 s**, is the limit for the user's flow of thought to stay uninterrupted.
A load that outlives 0.1 s has already been noticed, and an indicator is welcome
rather than intrusive. This is the reason the guidance is *not* "wait 900 ms
before showing anything": 900 ms of nothing is well past the point where the
interface has stopped answering, and reads as a frozen application.

## What a screen reader hears

**The wait is announced, and that is a decision.** `IuxLoadingIndicator` is a
live region carrying `loadingLabel`, so a user whose content was replaced by a
wait is told what is being waited on.

Silence would be defensible for content the user will reach by exploring. It is
not defensible here, because **a wait is usually gone before a user reading
linearly arrives at it** — the announcement is the only chance they get.

**This is where the pattern diverges from `IuxEmptyState`**, which takes an
`arrival` dimension and stays silent when the screen opened that way. An empty
state is content: it is still there when the user reaches it, so announcing it
as well says the same sentence twice. A wait is not content, and a wait that
announced only sometimes would be silent in the case that matters most — a
screen that opens on a slow request and shows a bar the user cannot see.
`IuxErrorRecovery` reaches the same conclusion for a failure and announces
unconditionally, so all three branches of the region agree.

**Focus is never moved.** Not to the failure, not to the recovery control, not
back into the region when content arrives. This matches `IuxEmptyState` and
`IuxErrorRecovery` and is the opposite of `IuxValidationSummary`; the difference
is whether the user asked for the change. A refused submission answers a button
they just pressed. A load resolving happens to them, often with their hands
elsewhere — moving focus for it would take the caret out of a search field to
announce the consequence of what they are still typing. Landing focus on a retry
would additionally arm the one control in the library that must never fire
twice.

**Never composed by IUX.** `loadingLabel`, `failureCategoryLabel`, the message
and every label on the route arrive already localised. The framework holds roles
and never words.

## Motion

Delegated to `IuxLoadingIndicator` rather than reimplemented, which is most of
why the wait is not drawn here.

| Preference | The wait |
| --- | --- |
| standard | the bar traverses; one crossing is 1800 ms |
| reduced | the bar still traverses, never faster than at standard |
| none | the bar is **removed**, not frozen; `loadingLabel` stays as the status line |

Removing the animation must never remove the information it carried, which is
why the label is required and always visible in both modes. A frozen segment
parked at an arbitrary position reads as a hung operation rather than a running
one — this pattern's tests exercise that path rather than assuming it was
inherited.

The failed branch animates nothing, so a reduced-motion preference has nothing
to remove there.

## There is no skeleton

Deliberately, and there is no slot for one.

- A skeleton **claims a shape** — three rows, this tall — that only the caller
  knows. A framework skeleton is either wrong or is a layout language.
- Its shimmer is **decorative motion** under `IuxMotionRole.emphasis`, removed
  the moment the user asks for less; what is left is a grey block that says
  nothing.
- It is **announced as nothing at all**. A pile of decorative boxes carries no
  text, so a screen-reader user gets silence where the bar would have given them
  a sentence. Fixing that means wrapping it in a live region with a
  caller-supplied label, at which point it is `IuxLoadingIndicator` with
  decoration.
- The evidence that it beats an indicator on perceived speed is **contested
  rather than settled**, and `PROJECT_PROMPT.md` §9 forbids presenting a
  hypothesis as a fact — particularly one whose cost is an unlabelled region.

## What is not covered

**A determinate load.** The wait is indeterminate. A load whose extent the
caller can count is better served by `IuxProgressIndicator`, which answers "how
much longer" where this answers nothing, and a user who cannot estimate a wait
is a user who abandons it. Supporting it here would mean putting a fraction and
its spoken form into `IuxLoadInProgress` — an additive change to that class and
nothing else, deliberately left until a call site asks.

**Two operations.** A screen whose header and whose list load separately has two
regions, each with its own state. One widget spanning both would have to decide
what "loading" means when one has arrived and the other has not.

**An action.** A save, a payment, a submission — anything the user starts by
pressing a control — is `IuxAsyncButton`, which keeps the outcome on the control
they pressed. This pattern is for content the region *is*, not work the region
*did*.

**Scrolling.** Neither branch scrolls and neither imposes a scroll view: a
region embedded in a list that already scrolls must not introduce a second one.
A long message at a large text scale in a short viewport therefore overflows
rather than shrinking or truncating, which is `IuxErrorRecovery`'s documented
behaviour and is inherited here. Half an account of why something is broken is
worse than an overflow, which is at least visible in development. Place the
region inside something scrollable when the viewport may be short.

## Known limitations

**Activating the recovery loses keyboard focus, whichever flow you choose.**
Half of this is not the pattern's to fix.

Returning the region to a wait unmounts the control the user just activated, and
Flutter hands focus back to the nearest enclosing scope; a keyboard user then
tabs from there rather than from where they were. The pattern does not paper
over this, because every fix is a focus movement of the kind it has just argued
against, onto a node that would itself vanish when the content arrived — two
interruptions in place of one.

> **Fixed at IUX-038** (`IUX-BUTTON-BUSY-001`). The paragraphs below describe
> the behaviour as it was and are kept because the reasoning still explains the
> shape of the fix. A running `IuxButton` now **keeps the focus the user put on
> it**, reports `enabled: Tristate.isTrue`, carries its `busyHint`, and offers
> `[focus]` but not `tap`. Withholding the tap is the truth — the repeat policy
> really does decline a second activation — while calling the control disabled
> was not. The two were one flag and are now two.

Leaving the region failed and driving `IuxRetryRoute.isRunning` instead *should*
have been the answer, since the control stays mounted. **It was not, and a probe
rather than a reading established that.** `IuxButton` passed
`IuxActionDescriptor.isActivatable` to its focus node's `canRequestFocus`, and
that getter is false while an action is in progress under the default repeat
policy, so a running control left the focus order and dropped the focus it held.
The same getter fed the announced enabled state, so a running retry was
announced as **unavailable** rather than as busy, and `busyHint` — which exists
so a running control is not silent — landed on a node the user had just been
moved off.

Both were `IuxButton`'s to fix, and both are fixed. Availability and operation
are orthogonal in the action model, and `IuxActionDescriptor` even asserts that
a disabled action cannot be in progress; the button used to collapse them
anyway. Returning the region to a wait remains the recommendation: it is the
simpler flow and it keeps one state on screen. The two tests that pinned the
defective behaviour were flipped rather than deleted, which is what they were
written for.

**A live region is a request, not a guarantee.** Whether the platform speaks it,
and when, is the platform's decision. A widget test can assert that the node
carries the flag and no more, so TalkBack remains a manual check. Nothing
essential depends on the announcement — the same words are on screen either way.

**Manual validation still owed.** TalkBack ordering and announcement timing
across the three branches; Voice Access activation of the recovery control;
D-pad traversal on a television or a hardware keyboard.

## Evidence level

| Rule | Level | Source |
| --- | --- | --- |
| A wait, an answer and a failure are one state, not three flags | Strong guidance | NN/g, application states; Material Design |
| A wait says what is being waited on | Strong guidance | NN/g, progress indicators; WCAG 2.2 SC 4.1.3 |
| A state change in place is announced to assistive technology | Standard | WCAG 2.2 SC 4.1.3 (Status Messages) |
| No time limit is imposed on the user | Standard | WCAG 2.2 SC 2.2.1 (satisfied by imposing none) |
| Essential motion is exempt from pause/stop/hide | Standard | WCAG 2.2 SC 2.2.2, essential exception |
| Motion is reduced or removed on request, without losing the information | Standard | WCAG 2.2 SC 2.3.3 |
| Meaning is never carried by colour alone | Standard | WCAG 2.2 SC 1.4.1 |
| A failure offers a suggestion | Standard | WCAG 2.2 SC 3.3.3 (structural, via `IuxRecoveryRoute`) |
| Text stays readable when enlarged | Standard | WCAG 2.2 SC 1.4.4 |
| ~0.1 s is the threshold below which a wait needs no indicator | Strong guidance | Miller 1968; Nielsen 1993, response times |
| ~1 s is the limit of uninterrupted flow of thought | Strong guidance | Miller 1968; Nielsen 1993 |
| 1800 ms per traversal of the indeterminate bar | Context dependent | measured from `IuxProgressResolver`; matches Material and iOS |
| Never retrying automatically | Brand choice | IUX governance; PROJECT_PROMPT.md §5, §22 |
| No skeleton | Brand choice | IUX governance; the perceived-speed evidence is contested |
| Announcing the wait unconditionally, unlike `IuxEmptyState` | Hypothesis | reasoned from a wait being transient; needs TalkBack validation |
| Not moving focus when a load resolves | Hypothesis | reasoned from where the user's hands are; needs TalkBack validation |

## Sources

- WCAG 2.2 — SC 1.4.1, 1.4.4, 2.2.1, 2.2.2, 2.3.3, 3.3.3, 4.1.2, 4.1.3.
- Miller, R. B. (1968), *Response time in man-computer conversational
  transactions*.
- Nielsen, J. (1993), *Usability Engineering*, chapter on response times.
- Material Design and Android accessibility guidance, progress indicators.
- `PROJECT_PROMPT.md` §5 (priorities), §9 (evidence levels), §19–22 (API
  design), §32 (motion), §57 (patterns).
- `docs/components/component-standard.md` §2, §3, §5, §6, §7, §11.
- `docs/components/progress.md`, `docs/patterns/error-recovery.md`,
  `docs/patterns/empty-state.md`.
