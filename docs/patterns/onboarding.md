# IuxOnboardingFlow — the screens shown before the user has done anything

```dart
IuxOnboardingFlow(
  currentStep: state.step,
  onStepChanged: controller.goToStep,
  describePosition: l10n.stepOf,              // (int, int) => String
  backLabel: l10n.back,
  forwardLabel: l10n.seeHowBudgetsWork,
  steps: <IuxOnboardingStep>[
    IuxOnboardingStep(
      title: l10n.trackWhatYouSpend,
      body: l10n.receiptsAreReadOnThisDeviceAndNeverUploaded,
    ),
    IuxOnboardingStep(
      title: l10n.setABudget,
      body: l10n.weWillTellYouWhenYouAreCloseToIt,
    ),
  ],
  skip: IuxInlineFeedbackAction(
    label: l10n.skipSetup,
    onActivate: controller.leaveOnboarding,
  ),
  finish: IuxInlineFeedbackAction(
    label: l10n.startUsingLedger,
    onActivate: controller.completeOnboarding,
  ),
)
```

## Purpose

An onboarding flow is the short sequence of screens an application shows before
the user has done anything: what this is for, what it will and will not do with
their data, the one setting worth choosing up front.

Every other stepped pattern in this library exists because the user started
something. This one exists because the application did. That single fact is
where all of its specific decisions come from, and it is the only thing worth
remembering about this page: **the user did not ask to be here.**

Everything an onboarding flow costs — a page change, an announcement, a control
to find, a decision to make — is charged to somebody who opened the application
to do something else, before they have seen anything to weigh it against.

## Use when

- A short sequence of screens genuinely earns its place before first use.
- Each screen tells the user something they would be worse off not knowing.
- The user may leave at any point and lose nothing.

## Do not use when

| Instead | Why |
| --- | --- |
| a sequence that collects answers | `IuxGuidedForm`. It owns validation, an error summary reaching across every step, and a route back to a rejected field. None of that is here, so a form built on this pattern is a form that cannot tell the user what is wrong. |
| one screen | `IuxPage` and two `IuxButton`s. A heading, a sentence and two controls, with no position to announce, no navigation to learn and nowhere to get lost. The constructor refuses a one-step flow and says so. |
| lateral views of the same thing | `IuxTabs`. Steps imply an order and a length; tabs imply neither. |
| explaining a control the user is looking at | `IuxContextualHelp`, next to the control, at the moment of the question rather than several screens before it. |
| asking for a permission | `IuxPermissionRationale`, at the feature. See below — this is the rule this pattern is most often used to break. |

## Structurally this is IUX-033 with content instead of fields

That is the honest description, and it was measured rather than asserted.

Four decisions are IUX-033's, reused rather than re-derived, and argued in
`docs/patterns/stepped-form.md`:

1. the step index is owned by the parent;
2. focus moves to the step heading when the step changes;
3. the position is one required function, so it cannot drift from the step count;
4. there is no progress bar.

The reuse is literal where it can be. `IuxStepPositionDescription` is the *same
typedef*, imported from `lib/src/patterns/form/iux_guided_form_model.dart`, so
the two stepped patterns cannot disagree about how a position is expressed.

The private step headings are near-identical: 51 code lines here against 58
there, and with comments stripped the entire difference is the class name and
one field — the guided form's optional `description`, drawn in the supporting
style, against this pattern's required `body`, drawn in the primary content
style because it is the substance of the screen rather than a note above a set
of questions. `IuxFocusable`, `Semantics(header: true)`, the joined `_spoken`
label, `IuxSemantics.decorative`, the position-first column and the `softWrap`
are the same lines in the same order.

### Why a composition was refused

`IuxGuidedForm` requires `IuxFormSection`s, an `IuxValidationSummaryLabels` and
an `IuxFormSubmit`. An onboarding flow has none of the three. Composing on it
would mean inventing a validation summary that summarises nothing and a
submission that submits nothing — and then every screen-reader user would be
told about an error summary that can never have an entry.

The duplication is real and it is recorded rather than hidden. It is the same
kind of debt `IuxProgressiveDisclosure` recorded against `IuxContextualHelp`'s
private disclosure control. Extracting one shared step heading would mean
editing `lib/src/patterns/form/iux_guided_form.dart`, which IUX-036 does not
own; whoever consolidates them should start from the two `_spoken` getters.

### What is genuinely new

| | `IuxGuidedForm` | `IuxOnboardingFlow` |
| --- | --- | --- |
| the user | started this | was placed in it |
| a step holds | `IuxFormSection`s | a title, a sentence, and anything else |
| leaving early | is abandoning their own task | is **required to be offered, on every step** |
| the end | submits one set of answers | leaves the flow |
| the last control | `IuxFormSubmit`, with a busy state | `IuxInlineFeedbackAction`, with none |

The last row is a decision. Finishing an onboarding flow commits nothing, so it
carries no operation and needs no busy state. An application whose last step
starts real work owns that screen and its progress; a spinner underneath a flow
that has already been left is a spinner nobody sees.

## The way out is required, on every step

`skip` is not optional, there is no parameter that removes it, and it is drawn
on the last step as well as the first.

This is IUX-031's decision taken again in the place it matters most.
`IuxPermissionMoment` made `decline` required on all three of its moments and
called it the most load-bearing requirement in the file, for two reasons that
both apply here:

- **the user always has a way out** — a flow with no exit is not an
  introduction, it is a wall;
- **the parent always receives the signal that they took it** — an application
  that cannot tell that this user left can only show the flow again.

It is drawn as a full `IuxButton`, beside the others, with the same target floor
and the same place in the focus order. There is no parameter with which to draw
it as a bare word under a filled rectangle, because that asymmetry — not the
wording and not the order — is what makes a screen feel like a trap. The
descriptor is *derived* rather than accepted, exactly as
`IuxPermissionMoment.declineDescriptor` is, and with the same two values:
`IuxActionRole.dismiss` and `IuxActionIntent.secondary`. Secondary is emphasis,
not availability.

Measured: on the last step, the exit and the control that ends the flow are the
same widget at the same height, at or above the 48dp floor.

**On every step, including the last.** An exit that disappears once the user is
nearly through costs them the one control that must never need discovering —
`IuxDisclosureState`'s third row — at the exact moment an application is most
tempted to remove it.

**What this cannot prevent** is stated rather than hidden: an application that
shows the flow again on the next launch to somebody who skipped it has turned
`skip` into a lie, and no widget can stop it. IUX holds the shape of the
conversation; its cadence belongs to the application.

## Onboarding is not where permissions get asked

Onboarding is the surface on which permission requests are traditionally buried,
and this pattern does not suspend IUX-031.

`IuxBeforeAsking` already refuses it in its own words: *"a rationale on first
launch, before the user has touched the feature, is still an interruption"*. A
step whose content is a permission request the user did not invite is that
sentence being ignored one layer up.

If an application puts an `IuxPermissionRationale` in a step's `content` anyway,
IUX-031's guarantees travel with it — the rationale requires a reason, and it
requires a `decline` drawn as a peer of the ask. The asymmetry stays
unrepresentable even in the place it is most tempting.

What is *not* repaired is the arithmetic. The step then shows **two forward
controls and two refusals** — the rationale's pair inside, the flow's pair
beneath — and the user has to work out which of the four leaves what. That is
the concrete reason to ask at the feature instead, and it is a defect of
composition that no assertion can see.

**The flow's `skip` is not a permission decline.** Leaving an onboarding flow
says nothing about a question that was put inside one of its screens, and an
application that records it as an answer has recorded something the user did not
say.

## Nothing moves on its own

**There is no auto-advance, and no parameter that would add one.**

- A screen that replaces itself after a few seconds is a time limit on reading
  (SC 2.2.1).
- The version that loops back to the first screen is moving content the user
  cannot pause (SC 2.2.2).
- Both fail for exactly the people an introduction is for: somebody reading with
  a magnifier, somebody translating as they go, somebody who looked away.
- An automatic step change would move focus — which is this pattern's
  announcement — while the user was in the middle of something else.

SC 2.2.1 is satisfied here by there being no limit to extend, rather than by a
setting that could be got wrong. The file imports no timer, starts no animation
and holds no ticker, and a test reads the source back to pin it, so adding one is
visible in a diff rather than in the field.

**There is no swipe, and no `PageView`.** A horizontal drag has no name, no focus
stop and no keyboard or D-pad equivalent, so a flow driven by one is a flow a
switch user cannot leave. On Android a horizontal swipe is already TalkBack's own
gesture for moving between elements, so the drag never reaches the application at
all. The steps move by named controls, which every input method can reach. A
caller who wants the gesture as well owns that addition and the four ways it can
be got wrong.

## Where focus goes when the step changes

When `currentStep` changes, focus moves to the new step's heading, whose node
carries the position, the title and the body as **one utterance**. That is the
announcement — there is no separate live region.

This is the seventh focus decision in this library, and it agrees with the
sixth.

| Pattern | Moves focus? | Because |
| --- | --- | --- |
| `IuxEmptyState` (IUX-028) | no | it happened *to* the user |
| `IuxErrorRecovery` (IUX-029) | no | same |
| `IuxLoadingRetry` (IUX-030) | no | same |
| `IuxPermissionRationale` (IUX-031) | no | focus arms the next Enter, and the armed control opens the OS prompt |
| `IuxForm` (IUX-012) | yes | the user pressed something and is waiting |
| `IuxGuidedForm` (IUX-033) | yes | same |
| `IuxOnboardingFlow` (IUX-036) | **yes** | the user pressed Back or the forward control and is waiting to learn where they now are |

IUX-033 reconciled the six with one test — *did the user ask for this?* A step
change here is unambiguously asked for: nothing else can cause one.

IUX-039 measured that reconciliation across all seven and found it sound
everywhere except the two forms, where the question is asked once and then
never asked again: an accepted submission leaves a pending focus move armed
indefinitely, so a later unrelated rejection moves focus although the user
asked for nothing. See the caveat under the same table in
`docs/patterns/stepped-form.md`. `IuxOnboardingFlow` is unaffected — it moves
focus only on a `currentStep` change and holds nothing pending.

**Not on the first build.** Focus is moved by a *change*, never by arrival, and
here that is a decision rather than a mechanism. The first step is on screen
because the application decided to show an onboarding flow — the user asked for
nothing — so it is exactly the IUX-028 case. Taking focus on arrival would
interrupt whatever the platform was already saying about the screen that just
opened.

**Not the first control.** One frame later that control is a different control,
and on the last step it is the one that ends the flow.

**Not when the parent declines.** `onStepChanged` is a request. If the parent
does not rebuild with a new index, nothing moves and no focus moves either.

**Not on an unrelated rebuild.** A parent that rebuilds for a reason of its own
leaves focus where the user put it.

## Where the user is, in words

`describePosition` is required, and there is no way to render a flow without it.
This is IUX-033's rule and the argument is stronger here: a user deciding whether
to sit through an interruption is deciding on **how long it is**, and a flow that
will not say has taken that decision away from them.

`step` is one-based, because it is read by a person. The sentence is the
caller's, already localised — "2 of 3", "2 / 3" and "étape 2 sur 3" are three
different strings and only the application knows which its users read.

### There is no dot row

**Decision: the position is text, and only text.** The row of dots is the usual
answer for this pattern specifically, and it fails three ways at once:

1. it carries position through **shape and place alone** — the SC 1.4.1 failure;
2. it is drawn from decorated boxes, which produce **no semantic node at all**;
3. the obvious fix — labelling the row — puts a **second utterance in the frame
   the focus move already owns**, which is the failure IUX-033 refuses a progress
   bar to avoid.

Point 2 was measured rather than assumed. The naive dot row is built in this
pattern's test file, deliberately, as evidence for a decision not to ship one:
four decorated `Container`s produce a node with an **empty label and zero
children**. A screen-reader user is told nothing.

§19 forbids public API whose only effect is an unverified role. An indicator that
cannot announce correctly is not shipped as decoration. The precedent is IUX-034,
which shipped no suggestions because `SemanticsRole.comboBox` throws in Flutter
3.44.8.

A caller who wants dots draws them beside the flow and owns the consequence
knowingly. A follow-up mission could ship a step indicator with a resolved
announcement policy; this one will not guess at it.

## API

```dart
IuxOnboardingFlow({
  required List<IuxOnboardingStep> steps,          // at least two
  required int currentStep,                        // owned by the parent
  required ValueChanged<int> onStepChanged,        // a request, not a report
  required IuxStepPositionDescription describePosition,
  required String backLabel,                       // one word for the whole flow
  required String forwardLabel,
  required IuxInlineFeedbackAction skip,           // on every step
  required IuxInlineFeedbackAction finish,         // replaces forward on the last
})

IuxOnboardingStep({
  required String title,                           // non-empty
  required String body,                            // non-empty
  Widget? content,
})
```

**Every parameter is required except `content`.** There is no default that is
right half the time, and each of the nine is load-bearing:

- `backLabel` and `forwardLabel` are **one pair for the whole flow**, not one per
  step. The position already says where the user is, and a control whose name
  changes at every step has to be read again each time to be sure it still does
  what it did. `backLabel` is not drawn on the first step, where there is nowhere
  to go back to.
- Name the **destination**, not the mechanism. "See how budgets work" rather than
  "Next": "Next" tells the user that something will happen and refuses to say
  what, which is the one fact they are using to decide whether to stay. The same
  applies to `finish` — "Start using Ledger", not "Done" — and to `skip` — "Skip
  setup", "Not now", never "Cancel", which makes the user work out which of two
  things is being cancelled when one of them is the application they opened.
- The navigation descriptors are **derived, not accepted**. A control a caller
  could configure could be given a confirmation policy, a destructive intent or a
  repeat policy that lets two step changes run at once, and none of those
  describes moving between two screens of an introduction. Going back and
  finishing are both `IuxActionRole.navigate`: going back discards nothing, and
  reaching the end commits nothing.

### The shapes the constructor refuses

| Refused | Message names the better answer |
| --- | --- |
| fewer than two steps | a screen built from `IuxPage` and `IuxButton` |
| `currentStep` outside `steps` | it would announce "4 of 3" |
| an empty `title` | focus lands here; unnamed, the flow moves and says nothing |
| an empty `body` | a title over a picture is a screen bought for one noun |
| an empty `backLabel` or `forwardLabel` | announced as "button" and nothing else |

`skip` and `finish` being required is the type-level half of the same rule: an
onboarding with no way out does not compile.

These are `assert`s, so they are **debug-only**. A release build with an
out-of-range step will still try to draw one.

### What goes in `content`, and what must not

`content` is the slot for everything that is not the two sentences — an
illustration, a choice the application wants to offer, a sample of the thing
being described. It is a `Widget` rather than an `IconData` slot, which is where
this differs from `IuxPermissionRationale.illustration` and does so deliberately:
a rationale's glyph is decoration beside an argument, while an onboarding step's
picture is frequently the point of the step.

It keeps its own semantic nodes and its own place in the focus order —
**measured**: the traversal is heading, then content, then the controls. It may
contain controls.

| Never in `content` | Why |
| --- | --- |
| the way out of the flow | the flow already draws it on every step. A second exit is a second thing to find, and a flow with two has one the user will miss. |
| a permission request the user did not invite | see above. |

The consequence of a widget slot is stated rather than hidden: **a widget arrives
carrying its own colours**, and the contrast guarantee the theme makes for
everything above it stops at this boundary. Build what goes in here out of
`IuxImage`, `IuxIcon` and the semantic roles and it holds; build it out of
literals and it does not, and nothing in IUX will notice. A decorative picture
should say so — `IuxImage` with `IuxImageDescription.decorative()` — so it does
not become a stop that announces a filename.

Null renders nothing at all, rather than an empty box with a gap above it.

## States

| State | How this pattern expresses it |
| --- | --- |
| default | the step at `currentStep` |
| focused | on the heading after a step change, and on each control; the ring is `IuxButton`'s |
| pressed | `IuxButton`'s |
| disabled | **none.** No control here is ever unavailable — least of all the exit |
| loading | **none.** Nothing here commits anything, so there is no operation to be busy with |
| error | **none.** A screen that asks for nothing cannot be answered wrongly |
| empty | **unrepresentable.** Fewer than two steps is refused at construction |

Four of the seven are absent by design rather than unimplemented. A flow that
could disable its own exit, or sit busy over a step, would be expressing
something this pattern denies exists.

## Accessibility

**Guaranteed by the pattern**

- The step heading is a single node carrying position, title and body, marked
  `header: true`, so a screen-reader user moving by heading reaches the top of a
  step without walking back through its content.
- Focus moves there on a step change and only on a step change (SC 3.2.5,
  SC 4.1.3).
- The heading is **not** a live region, so one event produces one utterance.
- The position is text, so it reaches everybody (SC 1.4.1).
- Reading order is back, exit, forward/finish — the way out of a mistake first,
  then the refusal, then the control an accidental activation must never land on.
  Verified on a simulated traversal rather than on x coordinates, because the
  controls wrap.
- Every control is a full `IuxButton`: named, keyboard- and D-pad-reachable, at
  or above the touch-target floor, with `kIuxMinimumTargetSpacing` between
  neighbours via `IuxTargetSpacing`.
- No time limit and no motion (SC 2.2.1, SC 2.2.2), so there is nothing for a
  reduced-motion preference to remove.
- The body has no line limit and no ellipsis at any text size. Half a reason is a
  reason the user cannot weigh, and truncation gets worse exactly when someone
  has enlarged their text because they were struggling to read.
- Measured at 200% text on a 320dp screen: the three controls wrap onto more than
  one row and every one stays whole and within the width.
- Rendered and asserted under light, dark, high-contrast light and high-contrast
  dark, and under RTL.

**The application's**

- Every string: the three per step, the two navigation labels, the two action
  labels and the position sentence. The framework composes none of them.
- Whether the labels distinguish `skip` from `finish` on the last step.
- Whether `content` holds its contrast, its alternative text and its own
  semantics.
- Placing the flow inside something that scrolls.

**Needs a device**

- TalkBack: that the arrival announcement is heard as one utterance rather than
  three, and that it is not clipped by the platform's own screen-change
  announcement.
- Voice Access: that every control is addressable by its visible label.
- Switch access: that the flow can be left without a pointer.

## Anti-patterns

**Removing the exit on the last step.** The one control that must never need
discovering, removed at the moment the application most wants to remove it.

**Drawing the exit as a bare word.** Not possible through this API, and the
reason it is not possible: asymmetry, not wording, is what makes a screen feel
like a trap.

**Auto-advancing.** A time limit on reading. Not possible through this API.

**A dot row as the only position.** SC 1.4.1, and it announces nothing.

**Putting a permission request in a step.** Two forward controls and two
refusals on one screen. Ask at the feature.

**Recording a skip as a permission decline.** The user said nothing about the
question inside the screen they left.

**Putting the position in the title.** "Step 2: Set a budget" with
`describePosition` also supplied says the number twice.

**A step that is a title over an illustration.** Refused at construction: write
the sentence that would make someone glad they stayed, or drop the step. Three
screens that each earn their place beat six that do not.

**Showing the flow again to somebody who skipped it.** Turns `skip` into a lie.
Nothing here can stop it.

## Limits

- **The last step carries two controls that both leave.** `skip` and `finish`
  differ in what the application records, not in what the user sees happen. A
  caller who cannot make that difference legible in the two labels should ask
  whether they need `skip` to mean anything on the last step at all — and should
  not conclude that the exit may be removed there.
- **A long body is a long announcement.** Title and body are one node, heard in
  full on every arrival at that step, including on the way back. That is the
  trade for a step change being one utterance rather than three fragments, and
  the fix is a shorter body rather than a parameter.
- **Nothing here scrolls.** A step with a long body and a picture at a large text
  scale is the caller's to place inside something scrollable, because a block
  embedded in a list that already scrolls must not introduce a second one. Pinned
  by a test.
- **The step heading is duplicated from `IuxGuidedForm`.** 40 of its 51 code
  lines are identical to `_IuxStepHeading`'s. Recorded above.
- **There is no step indicator of any kind beyond the sentence.** Deliberate, and
  the measurement is above.
- **The assertions are debug-only.**
- **Nothing here knows whether the flow is worth showing.** Whether these five
  screens teach anything, and whether the application would be better with none
  of them, is a judgement no widget can make. The strongest thing this pattern
  does about it is refuse a single-step flow and name the alternative.

## Evidence level

| Rule | Level |
| --- | --- |
| a change of context is announced / focus is managed on it | **standard** — WCAG 2.2 SC 4.1.3, SC 2.4.3, SC 3.2.5 |
| no time limit on reading; no auto-advancing or looping content | **standard** — SC 2.2.1 Timing Adjustable, SC 2.2.2 Pause, Stop, Hide |
| position is not carried by shape and place alone | **standard** — SC 1.4.1 Use of Color |
| a visible focus indicator; adjacent targets keep spacing | **standard** — SC 2.4.7, 2.4.11, 2.5.8 |
| every control has an accessible name | **standard** — SC 4.1.2 |
| text wraps rather than clipping at 200% | **standard** — SC 1.4.4, 1.4.10 |
| an interruption must always be leaveable | **strong guidance** — Nielsen Norman Group on onboarding and user control; IUX-031's own decision restated (`to_verify`) |
| naming the destination rather than the mechanism on a control | **strong guidance** — widely recommended button-labelling practice (`to_verify`) |
| a stepped flow says where the user is and how much is left | **strong guidance** — Baymard and Nielsen Norman Group on progress (`to_verify`) |
| onboarding carousels are largely skipped and poorly recalled | **hypothesis** — the reason this pattern refuses a one-step flow and requires a body, but not user-tested here |
| focus to the step heading rather than the first control | **context dependent** — argued from the six focus decisions above; untested with users |
| not taking focus on the first build | **context dependent** — follows from IUX-028's rule; untested with users |
| the exit drawn as a peer rather than a link | **context dependent** — the asymmetry argument is IUX-031's; the visual weight is not user-tested |
| one pair of navigation labels rather than one per step | **hypothesis** — chosen for consistency with IUX-033 |
| text rather than a dot row | **measured on the announcement, hypothesis on the trade** — that the naive dot row contributes no semantic node is measured in this pattern's test; whether users miss the dots is not |
| requiring at least two steps | **brand choice** — IUX's judgement that a one-screen introduction is a screen, not a flow |

Sources marked strong guidance are cited from memory of well-known
recommendations and should be re-checked against the primary documents before
being quoted as fact — `to_verify`.

## Sources

- WCAG 2.2 — SC 1.4.1 Use of Color, 1.4.4 Resize Text, 1.4.10 Reflow, 2.2.1
  Timing Adjustable, 2.2.2 Pause Stop Hide, 2.4.3 Focus Order, 2.4.7 Focus
  Visible, 2.4.11 Focus Not Obscured, 2.5.8 Target Size (Minimum), 3.2.5 Change
  on Request, 4.1.2 Name Role Value, 4.1.3 Status Messages.
- Android accessibility guidance on focus, context changes and TalkBack's own
  swipe gesture.
- Nielsen Norman Group — onboarding, user control and freedom (`to_verify`).
- Baymard Institute — multi-step progress indicators (`to_verify`).
- `docs/patterns/stepped-form.md` — IUX-033, whose four stepped decisions this
  pattern reuses and whose progress-bar argument it extends to dot rows.
- `docs/patterns/permission-rationale.md` — IUX-031, whose required `decline`
  this pattern's required `skip` restates, and whose rule about asking at the
  feature onboarding must not be used to route around.
- `docs/patterns/disclosure.md` — IUX-035, whose third never-disclosed row is
  the exit.
- `docs/patterns/empty-state.md`, `docs/patterns/error-recovery.md`,
  `docs/patterns/loading-and-retry.md` — the three patterns that decided *not* to
  move focus, and why this one does.
- `docs/components/component-standard.md` — §3 state is owned by the parent, §5
  accessibility, §7 API conventions, §11 documentation.
- `PROJECT_PROMPT.md` §19 (no public API whose only effect is unverified), §22
  (hard to misuse), §23 (no graphic identity).
