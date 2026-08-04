# Action model

## Intention

Describe an action completely enough that a component can render it, decide
whether to accept an activation, and announce it — without knowing anything
about the application.

```dart
const action = IuxActionDescriptor(
  semantics: IuxActionSemantics(label: l10n.save),
  role: IuxActionRole.submit,
);
```

Only `semantics` is required. An action without an accessible name cannot be
used with a screen reader, so there is no sensible default for it; everything
else defaults to the cautious value.

## Dimensions, and why they are separate

| Dimension | Answers |
| --- | --- |
| `intent` | what does it mean |
| `importance` | how much priority relative to its siblings |
| `role` | what does it do in the flow |
| `availability` | can it be activated now |
| `operation` | where is it in its lifecycle |
| `reversibility` | how hard is it to undo |
| `confirmation` | does the user have to confirm |
| `repeatPolicy` | what does a second activation do |
| `cancellation` | can a running action be stopped |
| `semantics` | what does assistive technology hear |

They are separate because they genuinely vary independently, and collapsing
them produces wrong defaults:

- **Intent is not importance.** "Clear filters" is destructive and low
  priority. "Save draft" is secondary and, ten minutes into a form, the most
  important thing on screen.
- **Intent is not reversibility.** Archiving is destructive and reversible.
  Sending a message is neither destructive nor reversible.
- **Destructive does not imply confirmation.** A confirmation on every delete
  trains users to dismiss confirmations, which is how the one that mattered
  gets dismissed too. Weigh reversibility.

## What was deliberately left out

**`IuxActionIntent.neutral`.** It would resolve to nothing distinguishable
from `tertiary`. A role with no distinct resolution is a name for nothing.

**`IuxActionAvailability.readOnly`.** Read-only describes a field, not an
action. An action that cannot be performed is unavailable, and a second word
for it only invites inconsistent use.

**`debounce` and `throttle`.** Both need a duration, which does not belong in
an enum, and both are timing mechanics rather than a statement of intent. An
application that needs them owns the timer.

## Invariants

Contradictions fail on an assertion in debug rather than being silently
corrected. Quietly repairing a contradiction hides the fact that the caller
believed something untrue.

| Invalid | Why |
| --- | --- |
| disabled + inProgress | an action that cannot be started cannot be running |
| hold-to-confirm + disabled | a disabled control cannot be held |
| `undo` role + irreversible | undoing is a reversal by definition |
| empty semantic label | an unnamed action is unusable with a screen reader |

Each message says what is wrong and how to fix it.

## One activation rule

```dart
final outcome = IuxActionPolicy.evaluate(action, confirmed: hasConfirmed);
if (outcome.isAccepted) { ... }
```

Decided once so two components cannot disagree about whether a busy action
accepts a second tap. Refusals carry a reason — `unavailable`,
`alreadyInProgress`, `awaitingConfirmation` — because a control that does
nothing when tapped is indistinguishable from one that is broken.

Unavailability outranks a missing confirmation: telling a user to confirm an
action they cannot perform would be a lie.

`ignoreWhileInProgress` is the default. It is what prevents a double-tapped
"Pay" from charging twice.

## Confirmation policies

Sealed, so a component can handle them exhaustively and adding one is a
reviewable change.

| Policy | Honoured by | Note |
| --- | --- | --- |
| `IuxNoConfirmation` | every widget | the action runs on activation |
| `IuxConfirmBeforeExecution` | `IuxDestructiveAction`, `IuxDestructiveFlow` | how it is presented is the pattern's decision, not this model's |
| `IuxConfirmByHold` | **nothing** | deliberate by construction, but invisible to a screen reader unless announced, and hard with tremor — never the only route |
| `IuxConfirmByDoubleActivation` | **nothing** | the first activation arms |

The third column is the part a caller needs and this table used to omit
(measured at IUX-039). Two of the four policies are honoured by no widget in
the package: `IuxDestructiveActionController` — the only thing that evaluates
a policy at all — asserts that it is given one of the first two, and every
other control runs `onActivate` on the first tap whatever the policy says.
`docs/patterns/destructive-action.md` explains why that pattern refuses them,
and the reasoning is good; what was missing is that no other pattern accepts
them either. Pinned in `test/api/api_consistency_test.dart`, so the day one is
implemented the test fails and this table has to be updated.

The second column is also the answer to the wider trap recorded as
IUX-BUTTON-CONFIRM-001: a policy on a descriptor is a *statement*, not an
enforcement, and handing such a descriptor to a plain `IuxButton` runs the
action on the first tap.

Nothing here imposes a dialog.

## Localisation

Every string arrives already localised from the caller. The model composes no
user-facing text, so it cannot leak one language into another.

## Limits

- The model describes policy; it executes nothing. Presenting a confirmation,
  running the operation and reporting the outcome are the parent's and the
  pattern's jobs.
- **`role` tells the semantics layer nothing — not just `custom`.** Measured at
  IUX-039: the only reads of `IuxActionDescriptor.role` in the library are two
  debug assertions (an `undo` action may not be irreversible; an
  `IuxEmptyStateAction` may not be `retry`). No role reaches a rendered pixel
  or a spoken word, and three of the eleven — `confirm`, `edit`, `select` — are
  never constructed anywhere in the repository. Read the dimension table above
  as *what the caller is stating*, not as what the framework will do about it.
- **`importance` is read by nothing at all.** It is stored, copied by
  `copyWith`, compared in `==` and folded into `hashCode`, and `high`, `medium`
  and `low` render and announce identically. Both are pinned by
  `test/api/api_consistency_test.dart`, which fails the day either is wired up.
- Invariants are assertions, so they are debug-only. A release build with a
  contradictory descriptor renders something, it just may not make sense.

## Evidence level

Context dependent. The dimension split is an IUX design decision. The
requirement for an accessible name and for explained unavailability restates
WCAG obligations.

## Sources

- WCAG 2.2 — SC 4.1.2 Name, Role, Value; SC 3.3.4 Error Prevention.
- Nielsen Norman Group — confirmation fatigue and error prevention.
