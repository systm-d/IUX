# IuxGuidedForm — a form asked in steps

The stepped half of the form pattern: `IuxGuidedForm` and `IuxGuidedFormStep`.
It reuses `IuxFormSection`, `IuxFormField`, `IuxFormSubmit`,
`IuxValidationSummary` and `IuxValidationSummaryLabels` unchanged — everything
IUX-012 shipped in `docs/patterns/guided-form.md`, which despite its filename
documents the single-page `IuxForm`.

What is new here is one thing, and it is the thing that makes a stepped form
either usable or a trap: **a question the user cannot see must still be
reachable**.

## Purpose

Splitting a long form into steps is a real improvement and a real cost. The
improvement is that a user faces five questions instead of thirty. The cost is
paid three times over, and it is paid by the users who can least afford it:

1. **Every step change is a page change.** The screen becomes a different
   screen. If nothing moves and nothing is announced, a screen-reader user is
   standing on a control that is now a different control, on a page that
   silently became a different page (WCAG SC 4.1.3, SC 2.4.3).
2. **A step hides the questions behind it.** A form that refuses to submit
   because of something on step 1, while the user is standing on step 4, is a
   refusal about something invisible. If the route back does not exist, the
   user cannot finish the form at all.
3. **The user cannot see how much is left.** A form of unknown length is a form
   people abandon, and the number is the only thing that answers it.

`IuxGuidedForm` decides exactly four things, and everything else belongs to the
parent: **where focus goes when the step changes**, **what the summary lists
across every step**, **how an entry crosses a step boundary**, and **when a
check is worth asking for**.

It never validates anything and it never changes the step by itself.

## Use when

- The form is long enough that showing it at once is the reason people abandon
  it, and its questions fall into groups with an order: a checkout, an
  application, an account set-up.

## Do not use when

| Situation | Use instead |
| --- | --- |
| the form fits on one screen | `IuxForm` — this is the default |
| lateral views of the same thing | `IuxTabs` — a tab has no order and no "back" |
| a sequence that is not a form | this ends in one submission of one set of answers |
| one field and one action | the field and an `IuxButton` |

Splitting five questions across three steps adds two navigation events, two
announcements and two chances to lose the user's place, and buys nothing back.
`IuxGuidedForm` asserts a minimum of two steps for that reason; one step is an
ordinary form wearing a position indicator.

## The parent owns the step

```dart
IuxGuidedForm(
  currentStep: state.step,               // in
  onStepChanged: controller.goToStep,    // out
  …
)
```

Nothing here holds an index. This is Component Standard §3, and here it is
load-bearing rather than tidy: only the application knows whether a draft has
to be saved first, whether the next step depends on an answer that has not
arrived, and whether the user may leave at all. A parent that declines simply
does not rebuild, and the step does not move — which is right, because a form
showing step 3 while the application believes the user is on step 2 is
describing a screen that does not exist.

`onStepChanged` is the single door: the two navigation controls go through it,
and so does a summary entry pointing at another step.

## Nothing blocks the way forward

**Decision: the forward control never refuses, and no step can be locked.**
There is no parameter for either.

This is IUX-012's rule about the submit control, applied one level up. A submit
button that greys itself out never says what is missing; a *step* that refuses
to advance is worse, because the user cannot even see which of the questions
behind them is the problem — the step they are being sent back to is not on
screen.

Filling a form out of order is also ordinary behaviour with ordinary reasons:
the postcode is on another device, the reference number is in an email, the
user wants to see what is asked later before committing to what is asked now. A
gate at every step boundary charges all of them for a rule that catches
nothing a check at the end does not.

So the guarantee moves to the end rather than disappearing. Submitting is
refused exactly as `IuxForm` refuses it, the summary lists every rejected field
on *every* step, and each entry travels to the step and then to the field.
Nothing can be hidden by being behind the user.

The cost, stated plainly: a user who answers step 1 badly does not find out
until they submit, which may be four steps later. IUX takes that cost because
the alternative interrupts everyone, and because the summary makes the late
discovery navigable rather than merely late.

## Where focus goes when the step changes

**Decision: focus moves to the new step's heading.**

The heading is a focusable node carrying the position, the title and the
description as one utterance — "Step 2 of 5. Delivery address. We only deliver
within the city." Arriving there *is* the announcement.

This is the fifth focus decision in this library, and the five disagree on
purpose. The test each applies is the same: **did the user ask for this?**

| Pattern | On the event | Why |
| --- | --- | --- |
| `IuxEmptyState` (IUX-028) | focus not moved | the emptiness may always have been there; the user did not ask |
| `IuxErrorRecovery` (IUX-029) | focus not moved | a failure can arrive while the user is typing elsewhere — and landing on a retry arms it |
| `IuxLoadingRetry` (IUX-030) | focus not moved | a load resolving happens *to* the user, hands elsewhere |
| `IuxPermissionRationale` (IUX-031) | focus not moved | focus arms the next Enter, and the armed control opens the OS prompt |
| `IuxValidationSummary` via `IuxForm` (IUX-012) | focus moves to the summary | it answers a button the user just pressed and is waiting on |
| `IuxGuidedForm` (this) | focus moves to the step heading | the user pressed Back or Continue and is waiting to find out where they now are |

Two corrections to this table, both measured at IUX-039 rather than reasoned.
`IUX-031` was missing from it, so the count above said "fourth" while the
permission pattern's own evidence entry also claimed fourth; that pattern
decided focus first and belongs here.

And the `IuxForm` row states an intention the code does not hold to. An
*accepted* submission increments the pending-attempt counter and never brings
it level again, so from then on any parent rebuild carrying a rejected field
moves focus to the summary — including an ordinary blur check, arbitrarily
later, while the user is typing somewhere else. Measured in
`test/patterns/iux_form_test.dart`, "DEFECT: an accepted submission arms an
unbounded focus move", and again in the guided form's own test. Until that is
bounded, the row above describes the intended rule and not the shipped one.

A step change is the same shape as a refused submission: the user acted, and is
standing still expecting an answer. Not moving focus would be the failure the
other three are avoiding, inverted.

**Not the first field.** The heading says what this step is, so the user hears
the question before being asked to answer it; and landing in a text box on
Android raises the keyboard over a step they have not seen yet.

**Not the control they pressed.** One frame later that control is a different
control — on the last step it is the submit — so focus resting there announces
nothing about what changed, and parks the user on something that now commits
the form.

**The one exception: arriving from the summary.** Activating an entry that
points at another step changes the step and then focuses the **field**. The
user did not ask to be told about a step; they asked to be taken to a box they
were told was wrong, and stopping at the heading first is a second journey they
did not ask for.

## Crossing a step boundary

This is the mechanism the pattern exists for.

```dart
// inside the summary entry the form builds for you
onActivate: () => _navigateToField(step, field.focusNode)
```

- **Same step:** focus the field and bring it on screen.
- **Another step:** record the field, ask the parent for the step, and finish
  the journey when the parent grants it — the field does not exist to be
  focused until then.

`Scrollable.ensureVisible` is not decoration here. A text field scrolls itself
into view when it takes focus; **a selection control does not.** Measured: with
the call removed, a checkbox reached from the summary lands 512 px down a 200 px
viewport — focused, announced, and invisible. That is why the pattern's test
uses a checkbox rather than a text box for that measurement.

A journey lasts exactly as long as the parent's next answer. It completes if
the next rebuild carries the step it asked for; it is abandoned by a rebuild
that does not, by either navigation control, and by submitting.

Both halves are needed. A parent that declines by rebuilding without the new
step says so, and the journey is dropped there. A parent that declines by *not
rebuilding at all* says nothing — so a journey left armed would finish itself
the next time the user happened to walk back to that step, dropping them into a
field when all they pressed was Back. That was a real defect in this pattern,
found by a test written to fail and passing when it should not have.

## Where the summary sits

**Under the step heading, above the questions** — one position lower than
`IuxForm` puts it, and deliberately.

Focus lands on the heading at every step change, so the summary has to be the
*next* stop after it. Above the heading it would sit behind the user every time
they navigated back to repair something, and a user who arrives to fix one
problem would have walked away from the list of the others. At the moment of
the refusal nothing is lost either way, because focus goes straight to the
summary wherever it is.

It **stays on every step** until nothing is rejected. A summary that vanished
when the user acted on it would delete the list of remaining problems at the
exact moment they started working through them.

`summary` is **required** here, where `IuxForm` allows null. A single-page form
without one can still send focus to the first rejected field, because that
field is on screen. In a guided form it usually is not: there is nothing to
focus, nothing to see, and the refusal becomes a form that will not submit and
will not say why. The summary is the only route across a step boundary.

## Where the user is, in words

```dart
describePosition: (int step, int stepCount) => l10n.stepOf(step, stepCount)
```

Required. A stepped form that cannot say how much is left has charged the user
for the navigation and given back nothing they can plan around.

A **function of both numbers**, for the reason `describeCount` is a function:
the position the user is told and the number of steps that exist must be the
same two numbers. One label per step is a count kept by hand, in parallel with
the list, and the two drift the first time a step is added.

`step` is one-based, because it is read by a person.

### There is no progress bar

**Decision: the position is text, and only text.** This is a decision, not an
omission.

- The sentence reaches everybody — a screen-reader user, a monochrome screen, an
  inverted one (SC 1.4.1). A bar carries the same fact in a second, weaker
  encoding, for the people who already had it.
- Drawing one with `IuxProgressIndicator` would put a **live region in the same
  frame as the focus move**, so a screen-reader user would hear two utterances
  competing for one event. That is exactly the failure `IuxValidationSummary`
  avoids by not being a live region, and the reason `IuxForm` forbids a second
  focus move from `onBlocked`.
- Excluding that indicator's semantics to keep the bar would mean using a
  component whose own documentation calls `valueLabel` "the only thing a screen
  reader can announce" with its announcement deleted.

A caller who wants a bar places `IuxProgressIndicator` above the guided form and
owns the consequence knowingly: two announcements per step change, in an order
the platform decides. A follow-up mission could ship a step indicator with a
resolved announcement policy; this one will not guess at it.

## When to validate

Unchanged from `IuxForm`: `IuxValidationTiming.onBlur` by default, gated on
`IuxFormField.edited`, and every field of every step asked again on submit. The
defence is in `docs/patterns/guided-form.md` and is not restated here.

Two things are specific to steps.

**Only the fields of the step on screen are watched.** A field on another step
is not mounted, so it can neither gain nor lose focus; a listener on it is
bookkeeping that can only go stale.

**Moving between steps asks for no checks**, including for the field the user
was standing in when they pressed the control. Leaving a step is not abandoning
it, and a rejection raised at that moment lands on a question that has just
left the screen. The check that catches an unanswered question is the one on
submit, whose failure the summary can point at.

That last property is *inherited rather than enforced*: a `FocusNode` detached
from the tree does not notify its listeners. That was measured, not assumed —
the same scenario with every step's nodes watched still produces no check — and
the test is a pin, so the day Flutter changes it is visible.

## API

```dart
IuxGuidedForm(
  currentStep: state.step,
  onStepChanged: controller.goToStep,
  describePosition: l10n.stepOf,             // (int step, int count) => String
  backLabel: l10n.back,
  forwardLabel: l10n.continueToDelivery,
  timing: IuxValidationTiming.onBlur,        // the default
  steps: <IuxGuidedFormStep>[
    IuxGuidedFormStep(
      title: l10n.yourDetails,
      description: l10n.weUseThisToContactYou,
      sections: <IuxFormSection>[
        IuxFormSection(fields: <IuxFormField>[email, contactByEmail]),
      ],
    ),
    IuxGuidedFormStep(
      title: l10n.deliveryAddress,
      sections: <IuxFormSection>[
        IuxFormSection(fields: <IuxFormField>[street, postcode]),
      ],
    ),
  ],
  summary: IuxValidationSummaryLabels(
    categoryLabel: l10n.error,
    describeCount: l10n.fieldsNeedAttention,
    navigationHint: l10n.goToThisField,
  ),
  submit: IuxFormSubmit(
    label: l10n.placeTheOrder,
    action: state.submitAction,
    onSubmit: controller.placeOrder,
    onBlocked: controller.reportRefusal,
    busyHint: l10n.placingYourOrder,
  ),
)
```

| Type | Holds | New in IUX-033 |
| --- | --- | --- |
| `IuxGuidedForm` | the pattern | yes |
| `IuxGuidedFormStep` | a title, a description, and its `IuxFormSection`s | yes |
| `IuxStepPositionDescription` | `String Function(int step, int stepCount)` | yes |
| `IuxFormSection`, `IuxFormField` | unchanged | no — IUX-012 |
| `IuxValidationSummary`, `IuxValidationSummaryEntry`, `IuxValidationSummaryLabels` | unchanged | no — IUX-012 |
| `IuxFormSubmit`, `IuxValidationTiming`, `IuxValidationTrigger` | unchanged | no — IUX-012 |

### A step holds sections, not widgets

For the reason a section holds fields rather than widgets: the form reads the
fields back out of **every** step — including the ones not on screen — to build
one summary and to know which step to travel to. A step of opaque widgets could
do neither.

A step with no internal grouping is one untitled section,
`IuxFormSection(fields: …)`. The section is what keeps
`kIuxMinimumTargetSpacing` between adjacent fields; going around it would mean
losing that floor or restating it.

### The step title is required

`IuxFormSection.title` may be null; `IuxGuidedFormStep.title` may not. A section
inside a step can reasonably be unnamed, because the step above it already says
what this is about. The step itself is where focus lands every time the user
moves, and an unnamed destination is a move a screen-reader user cannot hear.

### The navigation controls are derived, not accepted

`backLabel` and `forwardLabel` are strings; the `IuxActionDescriptor`s behind
them are built here. A step control a caller could configure could be given a
confirmation policy, a destructive intent, or a repeat policy that lets two
step changes run at once, and none of those describes moving between two
questions. This is the trade `IuxRecoveryRoute` already makes.

The way back is `IuxActionRole.navigate`, never `cancel`: going back keeps every
answer the user has given, and announcing it as a cancellation would tell them
their work is about to be thrown away.

The one action a caller owns is `submit`, because only the parent knows when a
submission is running.

One pair of labels for the whole form rather than one per step: the position
already says where the user is, and a control whose name changes at every step
has to be re-read each time to be sure it still does what it did.

## States

| State | What the form does |
| --- | --- |
| any step | heading, the step's fields, the way back (except step 1) and the way on |
| last step | the submit control in place of the way forward |
| a field rejected before any submit | the field shows its own message; no summary |
| refused submission | summary appears, focus moves to it, `onBlocked` fires |
| repairing across steps | entries travel to the step and then to the field |
| the last one repaired | the summary goes |
| submitting | the parent sets `operation: inProgress`; `IuxButton` refuses repeats |

## Accessibility

What the pattern guarantees:

- **A step change is announced.** Focus moves to a node carrying
  `"$position. $title. $description"` — one utterance, not three fragments.
  Measured on the real semantics tree: one node, `isHeader: true`,
  `isFocused: Tristate.isTrue` after the change.
- **The heading is a header**, so a screen-reader user moving by heading reaches
  the top of a step without walking back through the questions.
- **A question on another step is reachable.** Every entry is a control that
  changes the step and focuses the field, and brings it on screen — measured for
  a selection control, which does not bring itself.
- **The list of problems survives the repair.** The summary is on every step
  until the last rejection is gone.
- **Nothing is carried by colour** — position, title and messages are all text
  (SC 1.4.1). The summary's own guarantees are `IuxValidationSummary`'s and are
  unchanged.
- **Both navigation controls wrap rather than overflow** at a large text scale,
  through `IuxTargetSpacing`, which also keeps `kIuxMinimumTargetSpacing`
  between them.
- **Nothing animates.** A step change is not a transition to watch: the
  announcement must not be delayed to play one, and there is therefore nothing
  for a reduced-motion preference to remove.

What the application still owns: the position sentence, the step titles and
descriptions, the control labels, the field labels and every error message —
and whether any of them are understandable. No test can decide that.

What needs a device: TalkBack, Voice Access and a physical keyboard. In
particular, whether a platform speaks a focus change on a step it did not
consider a route change is a device question. Widget tests approximate them and
no more.

## Anti-patterns

**Blocking the forward control until the step is valid.** See above. It is the
disabled submit button, moved somewhere the user cannot see what is wrong.

**Announcing the step change yourself.** The heading already does it. A second
announcement from the parent is the same event spoken twice, and on Android an
assertive announcement cuts off the first one.

**Focusing a field from `onStepChanged`.** The pattern has just moved focus.
Two moves in one frame is a screen-reader user hearing half of each — the rule
`IuxForm` states for `onBlocked`.

**Putting the position in the step title.** "Step 2: Delivery address" with
`describePosition` also supplied says the number twice.

**A step per field.** A heading, a position, two controls and one question is
five things around one answer.

**Rendering a progress bar and the position.** Choose. See above for what the
bar costs.

## Limits

- **The summary does not say which step an entry is on.** It is one flat list in
  field order across every step. A form with "Address" on two steps has to
  distinguish them in the field names the parent supplies.
- **Nothing reviews the earlier steps before submission.** A confirmation page
  listing the answers with a way back to each is a screen the application
  builds out of the same steps.
- **There is no per-step submission and no draft saving.** One guided form is one
  set of answers committed once, on the last step.
- **A journey granted late still completes**, in one residual case: a parent
  whose *next* rebuild is the pending step, long after the request and for a
  reason of its own. Any other rebuild in between drops it. Nothing here can
  tell a slow grant from an unrelated move.
- **The form does not scroll**, and neither does a step. The page owns
  scrolling; `Scrollable.ensureVisible` needs a scrollable ancestor to work, so
  place the form inside one.
- **A late rejection takes focus**, exactly as in `IuxForm`, and the form cannot
  tell a waiting user from one who had gone back to reading.
- **Nothing here can tell whether a step is a sensible grouping.** Whether five
  questions belong together is the application's judgement, and it is the whole
  difference between a form that helps and one that adds four page changes.

## Evidence level

| Rule | Level |
| --- | --- |
| a change of context is announced / focus is managed on it | **standard** — WCAG 2.2 SC 4.1.3, SC 2.4.3, SC 3.2.5 |
| errors identified in text, not colour alone | **standard** — SC 1.4.1, 3.3.1 |
| an error message that suggests the correction | **standard** — SC 3.3.3 |
| a visible focus indicator, adjacent targets keep spacing | **standard** — SC 2.4.7, 2.4.11, 2.5.8 |
| focus moves to an error summary that links to the fields | **strong guidance** — GOV.UK Design System (`to_verify`) |
| a stepped flow tells the user where they are and how many steps remain | **strong guidance** — Baymard and Nielsen Norman Group on checkout progress (`to_verify`) |
| splitting a long form reduces abandonment | **strong guidance** — same sources (`to_verify`) |
| focus to the step heading rather than the first field | **context dependent** — argued from the four focus decisions above; untested with users |
| the summary below the heading rather than above it | **context dependent** — follows from where focus lands; untested with users |
| never blocking forward progress on validation | **hypothesis** — consistent with IUX's position on disabled submits, not user-tested for steps |
| one pair of navigation labels rather than one per step | **hypothesis** — chosen for consistency |
| text rather than a progress bar | **brand choice on the visual, hypothesis on the trade** — the announcement conflict is measured; whether users miss the bar is not |

Sources marked strong guidance are cited from memory of well-known
recommendations and should be re-checked against the primary documents before
being quoted as fact — `to_verify`.

## Sources

- WCAG 2.2 — SC 1.4.1 Use of Color, 2.4.3 Focus Order, 2.4.7 Focus Visible,
  2.4.11 Focus Not Obscured, 2.5.8 Target Size (Minimum), 3.2.5 Change on
  Request, 3.3.1 Error Identification, 3.3.3 Error Suggestion, 4.1.2 Name, Role,
  Value, 4.1.3 Status Messages.
- GOV.UK Design System — error summary, question pages, "one thing per page"
  (`to_verify`).
- Baymard Institute and Nielsen Norman Group — checkout progress indicators and
  multi-step form usability (`to_verify`).
- Android accessibility guidance on focus and context changes.
- `docs/patterns/guided-form.md` — IUX-012's single-page `IuxForm`, whose
  validation timing, summary and submit rules this pattern reuses unchanged.
- `docs/patterns/error-recovery.md`, `docs/patterns/empty-state.md`,
  `docs/patterns/loading-and-retry.md` — the three patterns that decided *not*
  to move focus, and why this one does.
- `docs/inputs/input-model.md` — the four-state validation lifecycle this
  pattern reads and never writes.
- `docs/components/component-standard.md` — §3 state is owned by the parent, §5
  accessibility, §7 API conventions.
