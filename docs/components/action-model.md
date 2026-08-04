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
| `importance` | how prominent is it when no call site names a variant |
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
  important thing on screen. Intent decides which containers are available —
  only `primary` and `destructive` have a fill — and importance picks one of
  them. Naming `variant:` overrides both.
- **Intent is not reversibility.** Archiving is destructive and reversible.
  Sending a message is neither destructive nor reversible.
- **Destructive does not imply confirmation.** A confirmation on every delete
  trains users to dismiss confirmations, which is how the one that mattered
  gets dismissed too. Weigh reversibility.

## What was deliberately left out

**`IuxActionIntent.neutral`.** It would resolve to nothing distinguishable
from `tertiary`. A role with no distinct resolution is a name for nothing —
which is what `tertiary` itself was until IUX-039 measured it. See
[button-variants.md](button-variants.md) for what changed and why.

**`IuxConfirmByHold` and `IuxConfirmByDoubleActivation`.** Removed at IUX-039,
having been exported, documented and honoured by nothing: `IuxButton` with
`confirmation: IuxConfirmByHold()` ran `onActivate` on the first ordinary tap.
Hold-to-confirm is invisible to a screen-reader user unless announced and hard
to perform with tremor, so it may never be the only route to an action, and one
control has no second route to itself to offer. Double activation arms a
control in place, which needs a disarm timeout or a visible way back that a
button has nowhere to put, and changes what a control does without announcing
it. Both need a pattern that owns more of the screen than a button does; when
one exists it can re-add the member it implements.

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

The second column is the part a caller needs and this table used to omit. There
were four members until IUX-039 and two of them had **nothing** in that column:
`IuxDestructiveActionController` — the only thing that evaluates a policy at
all — asserted that it was given one of the first two, and every other control
ran `onActivate` on the first tap whatever the policy said. They were removed
rather than implemented, for the reasons under *What was deliberately left
out*. `test/api/api_consistency_test.dart` now derives this table's left column
from the source and fails if any member has an empty right one, so a fifth
policy cannot be added without something reading it.

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
  or a spoken word. It was kept anyway, and its docstring corrected: unlike
  `importance` it is not a knob whose effect is missing but a vocabulary whose
  value is what it *forbids*, which is §22's subject. Rendering it would help
  exactly one kind of user — two buttons differing only by role would differ
  for a sighted reader and not for a screen-reader one. Read the dimension
  table above as *what the caller is stating*, and expect the framework to hold
  you to it rather than to draw it. (One correction to the finding: `confirm`
  is constructed, at `apps/pilot/lib/job_detail_screen.dart`. `edit` and
  `select` are not, which is what an unused member of a caller-facing
  vocabulary looks like.)
- **`importance` reaches the screen through exactly one channel.** Until
  IUX-039 it was stored, copied by `copyWith`, compared in `==` and folded into
  `hashCode` and read by nothing, so `high`, `medium` and `low` rendered and
  announced identically. It now chooses the default variant, and nothing else:
  a second visual channel alongside the variant would be two knobs that have to
  agree (§20), and deleting it would leave "how loud is this" expressible only
  by naming a styling parameter (§20 again). `test/api/api_consistency_test.dart`
  requires all three values to resolve differently.
- Invariants are assertions, so they are debug-only. A release build with a
  contradictory descriptor renders something, it just may not make sense.

## Evidence level

Context dependent. The dimension split is an IUX design decision. The
requirement for an accessible name and for explained unavailability restates
WCAG obligations.

## Sources

- WCAG 2.2 — SC 4.1.2 Name, Role, Value; SC 3.3.4 Error Prevention.
- Nielsen Norman Group — confirmation fatigue and error prevention.
