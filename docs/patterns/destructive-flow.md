# Destructive flow

## Purpose

Destroy something with **exactly one** safeguard, and let the shape of the loss
decide which safeguard that is.

```dart
// One thing the user chose, and the application can put it back.
// Nobody is asked; the way back is offered afterwards, and it does not expire.
final controller = IuxDestructiveFlowController(
  semantics: IuxActionSemantics(label: l10n.archiveTheMarchInvoice),
  scope: IuxDestructiveScope.items,
  wayBack: IuxUndoOffer(
    notice: l10n.invoiceArchived,
    undoLabel: l10n.undo,
    undoSemanticLabel: l10n.undoArchivingTheMarchInvoice,
    dismissLabel: l10n.dismissTheArchivedNotice,
    onUndo: model.restoreInvoice,
  ),
  onDestroy: model.archiveInvoice,
);

IuxDestructiveFlow(label: l10n.archive, controller: controller);
```

## What this adds to the destructive action

`IuxDestructiveActionController` (IUX-008.7) presents the confirmation an action
*asks* for. It takes the caller's word for whether one is warranted, and it
models no way back at all — both are stated as limits in
[`destructive-action.md`](destructive-action.md).

This pattern answers the question that comes before those: **given what is being
destroyed and whether it can be put back, which safeguard is proportionate?**
Two facts go in, and the answer comes out.

| Way back | Scope | The user is | And afterwards |
| --- | --- | --- | --- |
| `IuxUndoOffer` | `items` | not asked | offered the way back, in a notice that never expires |
| `IuxUndoOffer` | `everything` | — | **refused on an assertion** |
| `IuxNoWayBack` | either | asked, with the consequence stated | told nothing; there is nothing to offer |

The confirmation half is not re-implemented: the controller composes an
`IuxDestructiveActionController` and lets it decide what an activation means, so
the two cannot come to disagree about whether a busy deletion accepts a second
tap.

## Proportionality

Deleting one draft and deleting an account are not the same event. The type
that separates them asks one question, and it is deliberately not "how bad is
it" — nobody answers that consistently, and the person who has just written a
deletion is the worst placed in the project to judge it:

> **Could the user list what they are about to lose?**

| Value | Answers | Examples |
| --- | --- | --- |
| `IuxDestructiveScope.items` | yes — they picked it out | a draft, a photo, the forty-one messages they selected, one person's access to one document |
| `IuxDestructiveScope.everything` | no — nobody can enumerate it | an account, a workspace, a chat history, a folder and its contents, a device's local data |

A count does not move a deletion between them. Forty-one selected photographs
are forty-one things the user chose, and they will know at once if it was the
wrong forty-one. What moves it is the user no longer being able to say what is
inside.

**Why the answer changes the safeguard.** An undo offer only protects somebody
who can tell that they need it. A user who deleted the wrong draft knows
immediately; a user who deleted an account cannot inspect what went, so a
control offering to reverse it is a control they cannot evaluate — usually on a
screen the deletion takes away. So `everything` refuses an `IuxUndoOffer` and
the consequence has to be stated *before* the answer, where it can change it.

### Why there are two values and not four

This pattern has exactly two safeguards to allocate. A scale with four rungs
would have two that changed nothing, which `PROJECT_PROMPT.md` §19 calls dead
public API — and a ladder whose middle steps are decorative teaches a precision
the framework does not have. The scale is the smallest one that separates the
two cases, and the worked examples live here rather than in the type.

## Undo or confirmation: the trade, and why it is not a preference

A confirmation charges **every** user a step to prevent a mistake **most** of
them will never make. An undo charges nothing until somebody errs, and it is the
only one of the two that helps the user who meant to press the button and was
wrong about what it did — they confirm the dialog too. They were sure; they were
simply mistaken.

Confirming everything has a second cost, and it compounds: it teaches people
that dialogs are noise between them and their work. They learn to dismiss
without reading, and the habit does not distinguish the trivial confirmation
from the one that mattered. **Confirming everything is indistinguishable, in
effect, from confirming nothing.**

But an undo is not free either, and the cost falls on particular people. It
requires the user to **notice the offer**. Somebody working with a screen reader
hears the notice queued behind whatever the platform was already speaking;
somebody scanning with a switch needs several seconds to reach the control;
somebody who looked away sees nothing at all. A confirmation interrupts every
one of them — that is its whole cost, and also its whole virtue.

So the two are not ranked. They are matched to conditions:

| Reach for | When |
| --- | --- |
| an undo | the application can restore it on one call, and the user could list what they are losing |
| a confirmation | it cannot be restored from this screen, **or** the loss is something nobody can enumerate |

### The wrong pairings are refused, not documented

- **Both.** A flow that asks first *and* offers a way back interrupts everyone
  and still leaves a control on screen afterwards. Passing an
  `IuxConfirmationPrompt` alongside an `IuxUndoOffer` fails on an assertion.
- **Neither.** A deletion that runs on the first tap with nothing offered is the
  failure this pattern exists to close. `wayBack` is required, so the absence of
  a way back has to be a claim somebody made — `const IuxNoWayBack()` — and
  making it requires the wording to ask with.
- **An undo for a loss nobody can enumerate.** See above.

The framework removes the failure it *can* remove rather than narrowing it: the
notice built from an `IuxUndoOffer` **carries an action, so it never expires.**
`IuxTransientTiming.resolve` returns no dwell for it at all — measured, not
inferred. There is no window to beat and no race to lose.

## Undo is a promise about time

**The framework imposes no window, and it will not.** The offer has no deadline
of its own, so nothing here engages WCAG 2.2 SC 2.2.1: there is no time limit
set by the content.

If the **application** holds a deleted row for thirty seconds and then commits,
the application has created a time limit, and SC 2.2.1 then applies to the
application: the limit must be able to be turned off, adjusted, or extended. At
minimum, call `dismissNotice()` at the instant the window closes, so the control
never outlives the promise it makes. An "Undo" that does nothing is worse than
no offer at all — the user presses it, believes their work is back, and finds
out later that it is not.

IUX ships no default window because any number would be measured in the wrong
units. Five seconds means one thing to somebody watching the screen, another to
somebody whose screen reader is three sentences behind, and another again to
somebody scanning with a switch. A duration that is generous for the first is a
broken promise to the third.

## Use when

- An action deletes, revokes, discards or overwrites, and you have decided
  neither how to protect the user nor how to tell them afterwards.
- A deletion the application can genuinely reverse on one call — this is the
  case the pattern makes shortest to write, deliberately.
- A deletion nothing on this screen reverses, including account and workspace
  deletion.

## Do not use when

- **The action destroys nothing.** Sending a message and publishing a post are
  irreversible without being destructive. Use
  `IuxDestructiveActionController`, which does not fix `intent` or `role`.
- **The safeguard is already decided and the way back is modelled elsewhere.**
  `IuxDestructiveAction` is the smaller tool, and this pattern is built from it.
- **The consequence cannot be stated.** If you cannot write the sentence saying
  what the user loses, there is nothing to confirm — "Are you sure?" asks them
  to weigh an outcome nobody described.
- **The action is a step in a flow the user is already committed to.** The last
  page of a checkout does not need a confirmation on top of itself.
- **Several destructions can be in flight at once and each must be
  reversible.** One offer is outstanding at a time; see the limits.

## API

### `IuxDestructiveScope`

`items` or `everything`. See [Proportionality](#proportionality).

### `IuxWayBack`

Sealed, required, two members.

Each member is reachable two ways, and both mean the same thing —
`IuxWayBack.none()` and `IuxNoWayBack()`. The factory is the one to reach for: it makes the
sealed type the single place a caller has to look to find out which situations
exist, and it is the convention every sealed situation type in IUX now follows
(IUX-API-NAMING-001).

| Member | Claims | Fields |
| --- | --- | --- |
| `IuxUndoOffer` | this screen puts it back, in one control | `notice`, `undoLabel`, `dismissLabel`, `onUndo`, `undoSemanticLabel` |
| `IuxNoWayBack` | this screen cannot | none |

`IuxUndoOffer` is a strong claim: the application restores what was destroyed
**when `onUndo` is called**, with no further work from the user and no second
screen. A trash folder the user has to find is not this; a support request is
not this; last night's backup is not this. Those are ways back the user must be
told about *before* they answer — which is `IuxNoWayBack` with the route written
into the confirmation's `consequence`.

`IuxNoWayBack` therefore does not mean "destroyed forever". It means the weaker
and more useful thing: there is no control this pattern can put in front of the
user that undoes it, so the protection has to come before rather than after.

### `IuxDestructiveFlowController`

Owned, created and disposed by the parent, like a `TextEditingController`.

| Member | Meaning |
| --- | --- |
| `asksFirst` | the verdict: whether this flow interrupts before running |
| `isConfirming` | whether the user has been asked and has not answered |
| `dialog` | the `IuxDialog` for `IuxModalLayer`, or null |
| `notice` | the `IuxTransientMessage` for `IuxTransientLayer`, or null |
| `activate()` | attempts an activation and says what became of it |
| `confirm()` | records "go ahead" and runs the deletion |
| `cancel()` | records "leave it alone"; nothing runs |
| `undo()` | takes the deletion back and withdraws the offer |
| `dismissNotice()` | removes the offer without taking the deletion back |
| `update(...)` | restates everything the constructor took |

There is deliberately no getter for `scope` or `wayBack`: both are the caller's
own arguments handed back. `asksFirst` is not — it is what the pattern concluded
from them.

`prompt` is required exactly when `asksFirst` is true, and refused when it is
false. Both directions are asserted.

### `IuxDestructiveFlow`

The trigger. A thin widget over `IuxDestructiveAction`, which is itself a thin
widget over `IuxButton`.

| Parameter | Meaning |
| --- | --- |
| `label` | the visible text; required and non-empty |
| `controller` | the parent-owned flow state |
| `icon`, `variant`, `expand`, `focusNode`, `busyHint` | as on `IuxButton` |

There is **no `autofocus`**. A control that deletes something and takes focus on
arrival is one Enter press away from running, pressed by a keyboard user who was
still reading the page.

## The descriptor is derived, and it is not published

Nothing here accepts an `IuxActionDescriptor`. Taking one would let a call site
write `confirmation: IuxConfirmBeforeExecution()` on a flow that offers an undo,
or `reversibility: reversible` on something nothing reverses.

| Field | Value | Where it comes from |
| --- | --- | --- |
| `intent` | `IuxActionIntent.destructive` | naming this pattern claimed it |
| `role` | `IuxActionRole.delete` | the same |
| `reversibility` | reversible / irreversible | which `IuxWayBack` was named |
| `confirmation` | none / `IuxConfirmBeforeExecution` | the same |
| `availability`, `operation`, `semantics` | the caller's | only the parent can know them |

It is also **not exposed**, and that is load-bearing rather than tidy. A public
descriptor carrying `IuxConfirmBeforeExecution` can be handed to a plain
`IuxButton`, which evaluates with `confirmed: true` and runs the action on the
first tap with nobody asked — the open defect recorded as
`IUX-BUTTON-CONFIRM-001`. A caller of this flow never holds such a descriptor,
so **within this pattern the trap is unreachable rather than merely
documented**. It remains reachable elsewhere, including through
`IuxDestructiveActionController.action`; closing it in general is a decision
about where a policy is evaluated, and that is not this pattern's to make.

The `IuxTransientMessage` is derived for the same reason. Two of its fields are
fixed and neither is the caller's:

| Field | Value | Why |
| --- | --- | --- |
| `action` | always attached | it is what stops the notice expiring |
| `tone` | `IuxTransientTone.neutral` | a deletion is a fact, not an achievement; `success` would tint it and add a glyph celebrating the loss |

## Where the two layers go

The pattern puts nothing on screen. It produces two values and the parent places
them, at page level:

```dart
ListenableBuilder(
  listenable: controller,
  builder: (BuildContext context, Widget? child) => IuxModalLayer(
    dialog: controller.dialog,
    child: IuxTransientLayer(
      message: controller.notice,
      onDismissed: controller.dismissNotice,
      child: IuxPage(child: content),
    ),
  ),
)
```

Wire **both**, whichever safeguard the flow currently picks. The safeguard
follows the way back, and the way back can change under the controller through
`update(...)`. A parent that wires one has a working flow until the day somebody
changes a `wayBack`.

A pattern that pushed a route would be deciding navigation; a pattern that
opened its own overlay from wherever the trigger sat would be deciding layering,
which is how two modals end up open at once with the way out of neither visible.
Both belong to the application.

## Behaviour

| The user does | What happens |
| --- | --- |
| activates a flow with an undo offer | `onDestroy` runs immediately; `notice` carries the way back |
| activates a flow with no way back | the question opens; nothing runs |
| activates while unavailable | nothing; `blockedReason` is `unavailable` |
| activates while running | nothing; `blockedReason` is `alreadyInProgress` |
| activates twice before answering | one question, not two |
| confirms | the question closes, then `onDestroy` runs, exactly once |
| dismisses, taps the scrim, or presses Escape | the question closes; nothing runs |
| takes the way back | the offer is withdrawn, then `onUndo` runs, exactly once |
| dismisses the notice | the offer goes; the deletion stands |
| destroys a second thing | the second offer replaces the first, and the first way back is gone |

`confirm()` closes the question *before* running, and `undo()` withdraws the
offer *before* restoring, so neither callback observes a control still offering
what it has just done.

## Accessibility

| Guarantee | Where it comes from |
| --- | --- |
| The trigger is named | `IuxActionSemantics.label`, required non-empty by the model |
| The announced name may be fuller than the visible one | `label` and `semantics.label` are separate |
| Disabled is announced, with a reason | `IuxButton`, from `unavailabilityReason` |
| Target size, focus ring, keyboard activation | `IuxButton` → `IuxTapTarget`, `IuxFocusable` |
| The confirmation announces itself as a route, traps focus, restores it | `IuxDialog` |
| Focus never lands on the confirming choice | `IuxDialog` focuses its panel |
| The notice announces itself once, as a live region | `IuxTransientLayer` → `IuxSemantics.liveRegion` |
| The notice never takes focus | `IuxTransientLayer` |
| The way back is announced by what it undoes | `IuxUndoOffer.undoSemanticLabel` |
| The way back never expires | `IuxTransientTiming`, measured returning null |
| The way back is still there for a screen-reader user | the same, measured with `accessibleNavigation` on |
| Long text wraps and scrolls at 200% | `IuxDialog`, `IuxTransientLayer` |

The pattern draws nothing and adds no semantics of its own, which is what keeps
each of those guarantees in exactly one place.

**Measured and recorded**: the trigger's announced node carries no `isFocusable`
flag and no focus action, because `IuxSemantics.action` excludes the child
semantics in order to control the announced name. A plain `IuxButton` beside it
behaves identically, so this is the library's shape and not this pattern's. The
test asserts the two are equal so a future divergence is caught here.

**Still needs a device.** TalkBack reading order, whether the live region is
actually spoken before the user swipes away from it, Voice Access labelling and
physical keyboard traversal are approximated by widget tests and no more.

## Themes and tokens

Nothing in this pattern draws. Every colour, radius, spacing and duration is
resolved by `IuxButton`, `IuxDialog` and `IuxTransientLayer` from the theme, so
light, dark, high contrast, reduced motion and reduced visual stimulation are
inherited rather than re-implemented. The pattern names no colour, and the
seriousness of a deletion is never carried by colour — the wording carries it.

## Anti-patterns

```dart
// No. Interrupting everyone AND leaving a control on screen afterwards.
// Refused on an assertion.
IuxDestructiveFlowController(
  wayBack: IuxUndoOffer(...),
  prompt: IuxConfirmationPrompt(...),
  ...
)
```

```dart
// No. Nobody can list what is inside an account, so an offer to reverse it is
// an offer they cannot evaluate — on a screen the deletion takes away.
IuxDestructiveFlowController(
  scope: IuxDestructiveScope.everything,
  wayBack: IuxUndoOffer(label: 'Undo', ...),
  ...
)
```

```dart
// No. "It is in the Trash for 30 days" is a way back the user cannot reach
// from here, and telling them afterwards is telling them about a screen they
// have left. Say it in the consequence, before they answer.
IuxUndoOffer(notice: 'Moved to Trash, kept for 30 days', ...)
```

```dart
// No. The deletion is committed after five seconds and the control is not,
// so the offer outlives the promise. Call dismissNotice() when the window
// closes — and read SC 2.2.1, because the window is now yours.
Timer(const Duration(seconds: 5), model.commitDeletion);
```

```dart
// No. onDestroy bypasses the flow, so the safeguard is decoration.
IuxDestructiveFlow(label: 'Delete', controller: controller);
onSomethingElse: model.delete;
```

## States

| State | Source |
| --- | --- |
| default, focused, pressed, disabled | `IuxButton`, from the derived descriptor |
| in progress | `operation`, still the parent's, through `update(...)` |
| asking | `isConfirming`, set by `activate()` |
| answered | `confirm()` or `cancel()` |
| offering a way back | `notice != null`, set when the deletion ran |
| offer withdrawn | `undo()` or `dismissNotice()` |

There is **no error state**. Whether the deletion or the restoration failed is
the parent's to report: drive an `IuxAsyncActionController` from `onDestroy` and
feed its lifecycle back through `update(...)`, or show an `IuxAlert` beside the
content.

## Limits

- **One offer at a time, and a second deletion destroys the first way back.**
  Measured, not assumed. The transient channel holds one message, and this is
  the one place where its replacement rule costs the user something they
  needed. Where several destructions can be in flight and each must be
  reversible, the way back belongs somewhere durable — a trash the user can
  open — which is `IuxNoWayBack` with the route in the consequence.
- **The parent must place both layers.** With no `IuxModalLayer` the
  confirmation is computed and never shown; with no `IuxTransientLayer` the way
  back is computed and never offered, and the deletion simply happens. Nothing
  detects either, because nothing can from where the trigger sits.
- **A user who leaves the page loses the offer.** The notice is page state the
  parent owns, and navigation is the application's. If the destruction is worth
  reversing after a navigation, it is worth a trash.
- **`scope` only refuses; it does not otherwise change behaviour.** Its whole
  job is to make the claim explicit and to reject the pairing that cannot mean
  anything.
- **The assertions are debug-only.** A release build with an account-scoped undo
  offer will offer it. The rules are teaching tools, not runtime guards — the
  same position `destructive-action.md` takes.
- **No feedback is emitted.** A component emits feedback only when the parent
  supplies the event; emit from `onDestroy` through `IuxFeedbackScope`.
- **Non-destructive irreversibility is out of scope.** The derived descriptor
  fixes `intent: destructive` and `role: delete`, so sending a message or
  publishing a post belongs to `IuxDestructiveActionController`, which fixes
  neither.
- **Not in the catalog yet.** `apps/catalog` is outside this mission's scope.

## Evidence level

| Rule | Level | Source |
| --- | --- | --- |
| An undo is preferred to a confirmation for a reversible action | Strong guidance | NN/g, error prevention and undo; ISO 9241-110 controllability |
| A confirmation states its consequence rather than asking a question | Strong guidance | NN/g, confirmation dialogs; WCAG 2.2 SC 3.3.4 |
| Irreversible actions get an explicit confirmation step | Standard | WCAG 2.2 SC 3.3.4 (Error Prevention) |
| An offer carrying an action must not expire | Standard | WCAG 2.2 SC 2.2.1; `docs/components/transient-feedback.md` |
| A time limit created by the application is the application's obligation under SC 2.2.1 | Standard | WCAG 2.2 SC 2.2.1 |
| Every control is named and its state announced | Standard | WCAG 2.2 SC 4.1.2 |
| The notice never takes focus | Strong guidance | WAI-ARIA APG, status/live region; `IuxTransientLayer` |
| Enumerability as the proportionality test | Hypothesis | IUX; needs user validation, and is stated as a judgement rather than a finding |
| Refusing an undo offer at `everything` scope | Brand choice | IUX governance, `PROJECT_PROMPT.md` §5, §18, §22 |
| Two scope values rather than four | Brand choice | `PROJECT_PROMPT.md` §19 (no dead public API), §20 |

## Sources

- WCAG 2.2 — SC 2.1.1, 2.2.1, 2.4.3, 3.3.4, 4.1.2.
- WAI-ARIA Authoring Practices, dialog (modal) pattern.
- Nielsen Norman Group, on confirmation dialogs, undo and error prevention.
- `PROJECT_PROMPT.md` §5 (priorities), §18 (error prevention), §19 (API design),
  §22 (hard to misuse), §57 (patterns).
- `docs/components/component-standard.md` §2, §3, §4, §7, §11.
- `docs/patterns/destructive-action.md`, `docs/components/transient-feedback.md`,
  `docs/components/dialog.md`, `docs/components/action-model.md`.
