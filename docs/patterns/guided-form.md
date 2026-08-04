# IuxForm, IuxFormSection and IuxValidationSummary

The form pattern: fields grouped into sections, one action that commits them,
and an answer to the question IUX-009 left open — *whether the form can be
submitted*, and what happens when it cannot.

## Purpose

A form is where a user spends the most effort and gets the least feedback. The
two failures that make one unusable are not layout failures:

1. **Being told too early.** A field that validates on every keystroke reports
   that an email address is invalid while the user is typing the third
   character of it. Nothing was wrong; it was unfinished. Users learn to ignore
   the message, and then they ignore the one that mattered.
2. **Being refused without being told.** The user presses Submit, nothing
   visible happens, and there is no way to find out why. The commonest form of
   this is a submit button that greys itself out until everything is valid: it
   never says what is missing, and on Android a disabled control leaves the
   focus order, so a screen-reader user cannot even reach it to wonder.

`IuxForm` answers both. It decides exactly three things, and everything else
belongs to the parent: **when a check is worth asking for**, **what the failure
summary lists**, and **where focus goes when a submission is refused**.

It never validates anything. Whether a value is acceptable, what the message
says and whether the submission succeeded stay with the parent, exactly as the
input model (`docs/inputs/input-model.md`) requires.

## Use when

- The user answers several questions and then commits them: a sign-up, an
  address, a settings page with a Save button.
- Some of the answers can be rejected and the user has to be sent back to them.

## Do not use when

| Situation | Use instead |
| --- | --- |
| one field and one action, such as a search box | the field and an `IuxButton` |
| settings that apply on contact | `IuxSwitch`, with no Save at all |
| a multi-step flow with progress and a way back | a wizard — IUX-033 |
| a failure that is not about any field (payment declined, server down) | `IuxAlert`, because there is no field to send the user to |

A summary is also the wrong shape for a two-field form: each message is already
under the field it concerns, and a block at the top adds a stop between the user
and the answer they were about to give. Pass `summary: null` there.

## When to validate, and why

**The decision: a field is checked when the user leaves it, having edited it,
and every field is checked again on submit.** That is
`IuxValidationTiming.onBlur`, and it is the default.

The defence is the two failure modes above, taken in order:

- Checking **on every keystroke** produces an error about a value that was never
  wrong, only unfinished. The user is interrupted mid-word, repeatedly, and the
  interruption is loudest at the moment they are concentrating hardest. Luke
  Wroblewski's inline-validation study is the usual citation for inline
  validation being *faster and more satisfying*; the same study is the source of
  "reward early, punish late" — do not report a failure until the user has
  finished the attempt.
- Checking **only on submit** hands the user every problem at once, at the
  moment they believed they were finished, and usually about the field they
  filled in first and can no longer see. It is not wrong — it is what
  `IuxValidationTiming.onSubmit` does, and it is the right answer for a short
  form or an expensive check — but it is the weaker default.
- Checking **on blur** reports one field at a time, at the point the user has
  finished with it and before they have travelled far enough to have to come
  back. It is the answer that neither interrupts nor accumulates.

Two things make that safe rather than merely reasonable.

**`IuxFormField.edited` stops the form punishing a field the user only passed
through.** A keyboard user tabbing to the bottom of a form to reach Submit
crosses every field on the way. Without this, they arrive to find a column of
"required" errors about values they were never given the chance to get wrong.
The form asks for a check on blur only when the parent says the value changed.
It defaults to `false`, which is the cautious answer rather than the useful one:
a form that checks nothing on blur is merely less helpful, while a form that
checks untouched fields is actively telling the user they made a mistake they
did not make.

**A rejected field should be re-checked as the user repairs it.** This is the
other half of "reward early, punish late": once the error is on screen, the user
is looking at it, and it should clear while they watch rather than at the next
submit. The form cannot do this — it never sees the value — so the parent does
it from its own `onChanged`:

```dart
void emailChanged(String value) {
  state.email = value;
  // Only once it has already been rejected. Before that, this would be
  // per-keystroke validation with extra steps.
  if (state.emailValidation.isInvalid) checkEmail();
}
```

### Why there is no `onChange` timing

The form never sees a keystroke: the value lives in the parent's controller and
goes from the field straight back to the parent. A timing value the form could
not honour would be a setting that silently did nothing, which is worse than no
setting. A parent that wants per-keystroke checking already has everything it
needs — and it is defensible in exactly two cases: a live constraint the user
can watch being satisfied (a character counter, a password rule), and repairing
a field that has already been rejected.

## What happens when a submission is refused

The user presses the submit control.

- If a field is **already rejected**, nothing is sent. `IuxFormSubmit.onBlocked`
  is called instead of `onSubmit`. Asking the parent to save data the form can
  see is wrong helps nobody.
- Otherwise every field is asked for a check and `onSubmit` runs. If the parent
  then rejects a field — which is what an asynchronous check does — the form
  ends up in the same state as if it had known.

In both cases the user learns three things, which are the three a silent refusal
withholds:

| Question | Answer |
| --- | --- |
| **that** it was refused | the summary appears at the top of the form, and focus moves onto it |
| **why** | each entry names a field and repeats its message |
| **where** | each entry is a control that focuses and scrolls to that field |

Every field also still shows its own message under itself, drawn by the field.
The summary is a second route to the same information, never the only one.

### Focus goes to the summary

**Decision: focus moves to the summary, not to the first rejected field.**

- The summary says how many problems there are. The first field says only
  itself, so a user sent straight into field one of five learns about the other
  four one submission at a time.
- It is the same destination every time. The first-field rule lands somewhere
  different depending on which questions were answered badly, so the user cannot
  build a habit around it.
- It preserves the choice of order. From the summary the user can go to any
  problem; from inside a field they can only go through them.
- It is what the most heavily user-tested public form guidance does. The GOV.UK
  Design System moves focus to the error summary at the top of the page, and
  makes each entry a link to the field.

The cost, stated plainly: for a form with exactly one problem, the summary is a
detour — one item, one link, one extra hop. IUX takes that cost rather than
making the destination depend on the number of errors, because consistency
ranks above ergonomics in `PROJECT_PROMPT.md` §5.

Where no summary is configured (`summary: null`), focus falls back to the first
rejected field. Being moved somewhere useful beats being left where the failure
is invisible.

### How long a submission is allowed to move focus

**Decision: pressing submit opens a bounded window, and focus arriving in a
field closes it.**

Two requirements pull against each other, and both are right.

- A rejection that arrives *after* the submission was sent must still move
  focus. The parent's check runs over a network; the user pressed the control
  and is standing still waiting for the answer, and this is it.
- A rejection that arrives because the user tabbed out of a field ten minutes
  later must not. They asked for nothing, and a caret leaving the box they are
  typing in is a change of context on input — WCAG 2.2 SC 3.2.2.

Until IUX-039 measured it, the code satisfied the first and not the second.
`_handleSubmit` incremented the attempt counter, and on the *accepted* path
never called the focus move, so the counter that says "a submission is waiting"
was never brought level again. From the first successful submission onward,
every parent rebuild carrying any rejected field moved focus, forever
(`IUX-FORM-FOCUS-001`). The obvious repair — bringing the counter level in
`_handleSubmit` — fixes the second requirement by deleting the first, which
IUX-039 verified by doing exactly that.

So the window has to be bounded by something, and the framework has four
candidates. It cannot use the only one most people reach for first:

| Bound | Why not |
| --- | --- |
| **elapsed time** | The framework cannot see wall-clock time and should not want to. A screen-reader user working slowly through a long form is not a different user from a fast one, and a window measured in seconds moves focus for whoever was quick and refuses it to whoever was not. |
| **an outcome the parent reports** — `IuxActionOperation`, a `closeSubmission()` callback, a generation the parent ends | A window the parent closes is a window the parent can forget to close, and a parent that forgets gets `IUX-FORM-FOCUS-001` back with nothing on screen to say so. That is `PROJECT_PROMPT.md` §22 exactly: the failure has to be impossible, not merely documented. It is also new public API for something the widget can already observe (§19). |
| **the next rebuild after the submission** | Deletes the asynchronous case, which is the case the window exists for. A window one frame wide only ever catches a rejection the parent raised synchronously. |
| **the user going somewhere** | Chosen. |

The window opens when the user asks to submit and closes on the first of two
events: **the failure is shown**, or **focus arrives in one of the form's own
fields**. The form is already listening to every field node — that is how blur
validation works — so this asks nothing of the parent and adds no parameter.

**Only an arrival closes it, never a departure**, and the asymmetry is the rule
rather than a detail of it. What the window protects is a caret in a box the
user is standing in, and a user can only stand in a box they arrived in. A
departure leaves them at the enclosing scope with no caret to take — and a
refusal that moved nothing is a refusal a screen-reader user is never told
about. Closing on a departure would buy no protection and cost the
announcement.

The two rules differ in exactly one sequence — in a field, submit, leave the
field without entering another — and there the arrival rule moves focus,
deliberately. Asking to submit is not itself a departure: `IuxButton` does not
take focus when it is activated and a focused field keeps focus through the
tap, measured rather than assumed.

Four tests hold the four edges, and each was proved by breaking the code the
way it is meant to catch:

| Test | Fails when |
| --- | --- |
| `a rejection long after an accepted submission moves nothing` | the arrival hook is removed (the shipped defect) |
| `a rejection that arrives after the submission still moves it` | the window is never opened, or the accepted path closes its own |
| `leaving a field does not close the window an arrival closes` | a departure closes it too |
| `the window is not spent by rebuilds that carry no answer` | the first rebuild closes it, answer or not |

### Why the summary is not a live region

It is announced because focus lands on it. A live region on top of that would
speak the same sentence twice — once when it appeared, once when the user
arrived. Where focus genuinely cannot move, `IuxAlert` is the component that
announces itself in place.

### The submit control stays enabled

`IuxFormSubmit` refuses a disabled action that does not say why:

```dart
IuxFormSubmit(
  label: l10n.save,
  action: const IuxActionDescriptor(
    semantics: IuxActionSemantics(
      label: 'Save',
      unavailabilityReason: 'Your session has expired',   // required
    ),
    availability: IuxActionAvailability.disabled,
  ),
  onSubmit: controller.save,
)
```

Disable it only for a reason that is **not** about the fields — an expired
session, a plan that does not allow this. For an incomplete form, keep it
enabled: the refusal is the moment the user learns what is wrong, and a control
that greys itself out has taken that moment away and given nothing back.

## API

```dart
IuxForm(
  timing: IuxValidationTiming.onBlur,               // the default
  sections: <IuxFormSection>[
    IuxFormSection(
      title: l10n.yourDetails,
      fields: <IuxFormField>[
        IuxFormField(
          input: state.email,
          focusNode: _emailFocus,
          edited: state.emailEdited,
          onValidationRequested: (_) => controller.checkEmail(),
          child: IuxTextField(
            input: state.email,
            controller: _emailText,
            focusNode: _emailFocus,               // the same node
            content: IuxTextContent.email,
            onChanged: controller.emailChanged,
          ),
        ),
      ],
    ),
  ],
  summary: IuxValidationSummaryLabels(
    categoryLabel: l10n.error,
    describeCount: l10n.fieldsNeedAttention,       // (int) => String
    navigationHint: l10n.goToThisField,
  ),
  submit: IuxFormSubmit(
    label: l10n.createAccount,
    action: state.submitAction,
    onSubmit: controller.createAccount,
    onBlocked: controller.reportRefusal,
    busyHint: l10n.saving,
  ),
)
```

| Type | Holds |
| --- | --- |
| `IuxValidationTiming` | `onBlur` (default) or `onSubmit` |
| `IuxValidationTrigger` | why the form is asking: `blur` or `submit` |
| `IuxFormField` | a descriptor, a focus node, the widget, `edited`, `onValidationRequested` |
| `IuxFormSection` | a titled group of `IuxFormField`s |
| `IuxValidationSummaryEntry` | one rejected field: label, message, `onActivate` |
| `IuxValidationSummary` | the block itself, focusable |
| `IuxValidationSummaryLabels` | the strings a form needs to build one |
| `IuxFormSubmit` | the label, the action descriptor, `onSubmit`, `onBlocked` |
| `IuxForm` | the pattern |
| `IuxErrorCountDescription` | `String Function(int invalidFieldCount)` |

### `focusNode` must be the field's own node

It is the only link between an entry in the summary and the box the user has to
go and fix, and nothing can check it for you. Passing a second, unused node
produces a summary whose entries look right and go nowhere. This is the one
mistake the API can still make, and it is why the parameter is required rather
than optional.

### Why the count is a function

`describeCount` takes the number of rejected fields and returns the caller's
sentence. A fixed string would force the caller to count the failures itself, in
parallel with the form, and the two counts drift the first time a rule changes —
leaving "2 fields need your attention" above a list of three.

**The framework composes no user-facing text.** Not the count, not the category
word, not the join between a field's name and its message. Some languages have
one plural form and some have six; a framework-composed sentence would be wrong
in a place the user is already frustrated. Returning a constant from
`describeCount` — GOV.UK's "There is a problem" — is a perfectly good answer.

The one thing IUX does compose is the *pause* between two of the caller's own
strings: an entry is announced as `"$label. $message"`, and the summary node as
`"$categoryLabel. $message"`. That is the same trade `IuxSemantics.action`
already makes when it appends a hint, and the alternative is two stops in the
reading order for one problem, where the second is a message with nothing to
attach it to.

## States

| State | What the form does |
| --- | --- |
| resting | fields only; no summary, whatever the parent has rejected |
| a field rejected before any submit | the field shows its own message; still no summary |
| refused submission | summary appears, focus moves to it, `onBlocked` fires |
| repairing | entries disappear as the parent accepts values |
| last one repaired | the summary goes |
| submitting | the parent sets `operation: inProgress`; `IuxButton` refuses repeats |
| submitted | the parent decides; the form does not |

A field being `validating` is **not** a rejected field — that is the lifecycle
IUX-009 modelled, and collapsing "being checked" into "wrong" is what makes
users correct something that was never wrong. It follows that a submission
pressed while a check is in flight is *not* blocked by the form. Blocking on
something the framework cannot explain would be the silent refusal this pattern
exists to prevent; keep the submit action `inProgress` while your check runs and
the button will refuse repeats for you.

## Accessibility

What the form guarantees:

- **The refusal is announced.** Focus moves to the summary, whose node carries
  `"$categoryLabel. $message"`. A screen-reader user who presses Submit hears
  what happened rather than nothing.
- **Every entry is a control**, named `"$label. $message"`, carrying a tap
  action, meeting the touch-target floor through `IuxTapTarget`, and reachable
  by keyboard. Moving by control walks the list of problems.
- **Entries are in field order**, so the list matches the form rather than the
  order the failures happened to be discovered in.
- **Nothing is carried by colour.** The block has a glyph, an outline and words;
  each entry is underlined rather than merely tinted, which survives greyscale,
  colour-vision deficiency and a printed screenshot.
- **Fields keep at least `kIuxMinimumTargetSpacing` between them.** Two adjacent
  targets that touch produce mis-taps however large each one is, and in a form a
  mis-tap is a value typed into the wrong question.
- **The section title is a landmark**, so a screen-reader user jumps between
  groups instead of swiping through every field of the one they are in.
- **Nothing animates.** The summary appearing is not a change the user needs
  help following — focus has just been moved onto it — and an animation there
  would delay the announcement to save nothing.

What the application still owns: the labels, the help text, the error messages,
the category word, the count sentence, and whether any of them are
understandable. No test can decide that.

What needs a device: TalkBack, Voice Access and a physical keyboard. Widget
tests approximate them and no more.

## Anti-patterns

**A disabled submit button that waits for the form to be valid.** The control
says nothing about what is missing and, on Android, has left the focus order —
so a screen-reader user cannot reach it to find out. Keep it enabled and let the
refusal explain itself.

**Validating on every keystroke.** See above. If you must, do it only for a
constraint the user can watch being satisfied.

**A summary rendered before the user has submitted.** Every message is already
under the field it belongs to, where the user is looking. A block at the top is
the same information a second time, about a question they have not reached.

**A summary that lists fields without saying what is wrong with them.** The user
travels to the field and arrives no better informed. Entries carry the message,
and `IuxValidationSummaryEntry` refuses an empty one.

**Removing the field's own message because the summary has it.** The summary is
a second route, not a replacement. A user who has scrolled to the field must not
have to scroll back to find out what it wanted.

**Showing your own message from `onBlocked`.** The refusal is already visible
and already announced. `onBlocked` is for a feedback event, a log line or a
metric — the things only the parent may do.

**A second focus move after the refusal.** Do not focus a field from
`onBlocked`: the form has just put focus on the summary, and two moves in one
frame is a screen-reader user hearing half of each.

## Limits

- **The required-field marker is not here.** IUX-009 deferred it to this
  mission; marking belongs beside the field's own label, inside the field
  widget, which IUX-012 does not own. Until it lands, put the convention in
  `IuxFormSection.description` — one localised sentence saying which of required
  or optional is marked — and mark the minority case in the field's own label
  text. Mark whichever is rarer: asterisks on every field of a form where
  everything is required tell the user nothing.
- **The submit control is rendered inline, at the end.** A form whose action
  lives in a fixed bottom bar has to place that control itself and call the same
  handler. There is no slot, because inline and pinned have different scrolling
  and keyboard-avoidance problems and one parameter cannot answer both.
- **The form does not scroll.** The page owns scrolling; a form that brought its
  own scroll view would nest one inside the page's.
- **A submission the parent never answers keeps its window open.** If the user
  presses submit, touches nothing afterwards, and a rejection arrives a long
  time later, focus moves — right for a user still waiting, wrong for one who
  walked away from the screen. The form cannot tell those apart without a
  report the parent has to remember to send, which is the trade the window
  section argues against.
- **`edited` is the parent's word.** The form takes it on trust. A parent that
  never sets it gets submit-only checking, which is safe and less helpful.
- **Sections do not group the summary.** Entries are one flat list in field
  order. For a form long enough that section names would help locate a problem,
  the entry labels have to carry that themselves.
- **Nothing here can tell whether a message says how to fix the value.** That is
  the difference between a form a user completes and one they abandon, and it is
  entirely the application's.

## Evidence level

| Rule | Level |
| --- | --- |
| errors identified in text, not colour alone | **standard** — WCAG 2.2 SC 1.4.1, 3.3.1 |
| a label or instruction for every field | **standard** — SC 3.3.2 |
| an error message that suggests the correction | **standard** — SC 3.3.3 |
| a visible focus indicator not obscured by content | **standard** — SC 2.4.7, 2.4.11 |
| adjacent targets keep spacing | **standard** — SC 2.5.8 |
| focus moves to an error summary that links to the fields | **strong guidance** — GOV.UK Design System, validated in public-service user research |
| validate on blur rather than per keystroke ("reward early, punish late") | **strong guidance** — Wroblewski's inline-validation study; Nielsen Norman Group on error messages |
| keep submit enabled and explain the refusal | **strong guidance** — Nielsen Norman Group and Baymard on disabled submit buttons |
| the summary appears only after a submission attempt | **context dependent** — IUX's reading of the above; untested with users |
| `edited` gating blur validation | **hypothesis** — sound in principle, not user-tested |
| focus to the summary rather than the first field, for a single error too | **hypothesis** — chosen for consistency; a per-count rule may test better |
| a late rejection moves focus only while no field has been entered since the submission | **context dependent** — follows from SC 3.2.2 and from the four bounds weighed above; the arrival is a proxy for "the user has stopped waiting", and the proxy is untested with users |

Sources marked strong guidance are cited from memory of well-known
recommendations and should be re-checked against the primary documents before
being quoted as fact — `to_verify`.

## Sources

- WCAG 2.2 — SC 1.4.1 Use of Color, 2.4.7 Focus Visible, 2.4.11 Focus Not
  Obscured, 2.5.8 Target Size (Minimum), 3.3.1 Error Identification, 3.3.2
  Labels or Instructions, 3.3.3 Error Suggestion, 4.1.2 Name, Role, Value.
- GOV.UK Design System — error summary, error message, question pages
  (`to_verify`).
- Luke Wroblewski, *Web Form Design* and the Etre inline-validation study
  (`to_verify`).
- Nielsen Norman Group — error-message guidelines, and guidance against disabled
  submit buttons (`to_verify`).
- Baymard Institute — form usability and inline validation (`to_verify`).
- Android accessibility guidance on disabled controls leaving the traversal
  order.
- `docs/inputs/input-model.md` — the four-state validation lifecycle this
  pattern reads and never writes.
- `docs/components/component-standard.md` — §3 state is owned by the parent, §5
  accessibility, §7 API conventions.
