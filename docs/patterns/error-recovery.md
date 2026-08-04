# Error recovery

## Purpose

Say what failed, and give the user the way out that actually belongs to that
failure.

```dart
IuxErrorRecovery(
  categoryLabel: l10n.error,
  message: l10n.yourOrdersCouldNotBeLoaded,
  route: IuxRetryRoute(
    label: l10n.tryAgain,
    onRetry: controller.reload,
    isRunning: controller.isRunning,
    busyHint: l10n.reloadingYourOrders,
  ),
)
```

## An error the user cannot act on is an apology

This is the whole argument of the pattern, so it comes before the API.

A failure report has two halves and interfaces routinely ship one. "Something
went wrong" spends the user's attention and returns nothing: they could already
see that something was wrong, and they now know only that the interface cannot
say what. A message with no way forward leaves them re-reading a sentence and
pulling to refresh a screen that has no refresh.

So the way out is not an optional parameter here. `route` is **required**, it is
a sealed type, and every member of it answers *what now*:

| Route | Claims | Gives |
| --- | --- | --- |
| `IuxRetryRoute` | sending the identical request again may succeed | a control |
| `IuxAlternativeRoute` | it will not, but this other action gets there | a control |
| `IuxUnrecoverable` | nothing on this screen moves the user forward | a sentence |

A caller with nothing to offer has to name `IuxUnrecoverable` *and* write the
guidance. That is deliberately the most effortful of the three: making it a
named type with a required sentence is the smallest act that keeps "nothing can
be done" off the path of least resistance, where an optional action parameter
would have put it.

This is also how WCAG SC 3.3.3 (Error Suggestion) is met structurally rather
than by review. The type system will not build the block without a suggestion.

## Retry is a claim, not a default

**Choosing `IuxRetryRoute` asserts that repeating the identical request could
produce a different answer.** For a great many failures that is false, and
offering retry anyway is worse than offering nothing: the user presses it,
waits, and fails in exactly the same way, having learned only that the interface
does not know what happened either.

| Failure | Retry? |
| --- | --- |
| the network dropped, the server timed out, a 503, a 429 | yes |
| a conflict the server resolves on the next attempt | yes |
| not signed in, or signed in as the wrong person (401) | **no** — `IuxAlternativeRoute` to the sign-in screen |
| not allowed (403) | **no** — nothing the user repeats changes their permissions |
| not there (404) | **no** — the identical request finds the identical nothing |
| the value the user sent was rejected | **no** — the field is the route, and `IuxForm` owns that |
| the payment was declined | **no** — `IuxAlternativeRoute` to another payment method |

### What is unconstructible, and what is only visible

Being honest about the limit matters more than claiming a guarantee that does
not exist.

**Unconstructible.** A retry cannot leak into the pattern next door:
`IuxEmptyStateAction` refuses `IuxActionRole.retry` outright, so a collection
that answered "nothing" cannot be given a control that re-asks the question. In
the other direction, `IuxAlternativeRoute` derives `IuxActionRole.navigate` and
has no parameter with which to become a retry. The two patterns cannot blur into
each other from either side.

**Visible only.** Whether *this particular* failure is retryable is a fact about
a status code, a service and a business rule, and the framework has none of
them. A parameter asking "is this retryable?" would be answered `true` by
everyone who had not thought about it. What a type system can do is put the
claim in the source, in one word, at the place a reviewer is already looking —
so `IuxRetryRoute` is a line in a diff rather than a boolean nobody reads.

## Nothing here retries on its own

There is no attempt count, no backoff, no timer and no automatic repeat, and
their absence is the design:

- an interface that retries by itself turns one user's bad connection into a
  burst of traffic against a service that is already failing, and it does so
  hardest at the exact moment the service can least take it;
- not every operation may be repeated safely. A framework that re-sent an
  operation the user did not ask it to re-send would eventually charge a card
  twice, and no amount of care about the common case makes that acceptable;
- a retry that succeeds silently leaves the user unable to explain what they
  saw, and one that fails silently leaves them looking at an unchanged screen
  with no account of what has been going on behind it.

Every attempt is one the user asked for. What stops them asking twice by
accident is not a flag this pattern invented: `IuxRetryRoute.descriptor` carries
`IuxActionRepeatPolicy.ignoreWhileInProgress`, so `IuxActionPolicy` drops a
second activation while the first is in flight — the same mechanism that stops a
double-tapped "Pay" charging twice.

A parent that must stop the user retrying at all — a rate limit, an attempt
budget it has decided to spend — does not disable the control. There is no
availability parameter on the retry route for that reason. It swaps the route
for an `IuxAlternativeRoute`, so the block goes on offering a way forward
instead of a way that has been taken away without explanation.

One further consequence: the pattern imposes **no time limit of any kind**, so
WCAG SC 2.2.1 (Timing Adjustable) has nothing to adjust.

## Use when

- a list, a grid or a section could not load
- an operation the user started failed: a save, an upload, a payment
- a screen's content is missing because the request behind it broke
- a session expired, a permission was refused, a document is gone

## Do not use when

| Situation | Use |
| --- | --- |
| the content is still there and the message is *about* it | `IuxAlert` |
| a field's value was rejected | the field's own message |
| a submission was refused by several fields | `IuxValidationSummary` |
| the collection came back with nothing in it | `IuxEmptyState` |
| the request is still in flight | show progress |
| the user may simply wave the message away | `IuxAlert` with a dismissal |
| a standing condition across the whole screen, such as offline | `IuxBanner` |

Two of those are worth spelling out.

**A rejected value is not a breakdown.** The field owns its own message and
shows it where the user is looking; a form that will not submit gets an
`IuxValidationSummary` whose entries travel to the fields. There is nothing to
retry, because the request was never sent — `IuxRetryRoute` would offer to send
the same rejected value again.

**An empty answer is not a failure.** A collection that came back with nothing
in it succeeded. `IuxEmptyState` explains an answer, this explains a breakdown,
and the two want opposite controls.

## Where it sits among the four

| | The content is | The block is |
| --- | --- | --- |
| `IuxAlert` | still there | a message *beside* it |
| `IuxErrorRecovery` | missing, because it failed | what stands in its place |
| `IuxEmptyState` | missing, because there is none | what stands in its place |
| `IuxValidationSummary` | there, and refused | a list of fields to travel to |

## API

### `IuxRecoveryRoute`

Sealed. A component can handle every route exhaustively, so adding a fourth is a
change the compiler forces every call site to consider; and the choice between
them is a claim about the failure that only the caller can make, so it is made
by naming a type rather than by setting a flag that reads the same whichever
value it holds.

Each member is reachable two ways, and both mean the same thing:

```dart
IuxRecoveryRoute.retry(label: l10n.tryAgain, onRetry: controller.activate)
IuxRetryRoute(label: l10n.tryAgain, onRetry: controller.activate)
```

The factory is the one to reach for. It makes the sealed type the single place
a caller has to look to find out which situations exist, and it is the
convention every sealed situation type in IUX now follows —
`IuxLoadState.loading()`, `IuxWayBack.none()`,
`IuxEmptyStateCause.noMatches(...)`, `IuxPermissionMoment.beforeAsking(...)`.
Before IUX-API-NAMING-001 three of them fronted their members and five did not,
so a caller wrote `IuxLoadState.loading()` on one line and `IuxNoWayBack()` on
the next for the same modelling idea.

#### `IuxRetryRoute`

| Parameter | | |
| --- | --- | --- |
| `label` | required | the visible verb, already localised |
| `onRetry` | required | called once per accepted activation |
| `semanticLabel` | optional | the fuller announced name |
| `isRunning` | `false` | whether the attempt the user asked for is still running |
| `busyHint` | optional | what a screen reader hears while it runs |

`isRunning` is a boolean rather than an `IuxActionOperation`, deliberately. Of
the four lifecycle values only two can be true of a control inside a block that
is *currently reporting a failure*: a retry that succeeded has removed this
block, and a retry that failed has replaced its message. Taking the full enum
would have accepted two values describing a screen that cannot exist, and then
needed an assertion to reject them — which is a worse version of not accepting
them at all.

There is **no `IuxActionDescriptor` parameter.** The descriptor is derived, and
four of its fields are fixed because none of them is a decision the caller
should be offered:

| Field | Value | Why it is not the caller's |
| --- | --- | --- |
| `role` | `IuxActionRole.retry` | it is what naming the type claimed |
| `repeatPolicy` | `ignoreWhileInProgress` | a second attempt in flight is the defect this route exists to avoid |
| `intent` / `importance` | primary, high | it is the only control in the block |
| `confirmation` | none | nothing here presents a question |

#### `IuxAlternativeRoute`

Takes one `IuxNamedAction` — the library's existing value for "a
labelled way out of a message", so a call site that outgrows `IuxAlert` does not
have to rewrite its actions to move here. It carries no lifecycle, which is
correct: an alternative goes somewhere else, and the somewhere else owns its own
progress. A control that has to report progress *in this block* is a retry, and
that is the other type.

Its derived descriptor is `IuxActionRole.navigate`, which is the one thing that
keeps this control from being announced as, and treated as, the retry it
deliberately is not.

**It is not the place for an action that destroys data.** "Discard your changes
and start again" is a way forward and it is also irreversible, and an
irreversible control sitting under a message the user is still reading is the
one they press while they are still upset. Put an `IuxDestructiveAction` below
this block, where it can ask.

#### `IuxUnrecoverable`

Takes one required `guidance` sentence and nothing else.

**Reach for it last.** Most failures that look unrecoverable are not: a server
error can be retried, an expired session can be renewed, a missing document can
be left for a list the user can get back to.

Two things are worth saying in the guidance and both are the caller's to judge:
**what state the user is in** — "Nothing has been charged", "Your draft is still
saved on this device" — and **what they can do away from this screen**,
including a reference to quote if they contact anyone. What is not worth saying
is that an unexpected error occurred; the user can see that, and a sentence
restating it spends their attention and returns nothing.

### `IuxErrorRecovery`

| Parameter | | |
| --- | --- | --- |
| `route` | required | the way out, and therefore what the block offers |
| `categoryLabel` | required | the localised word — "Error", "Erreur" |
| `message` | required | what failed, already localised |

`categoryLabel` is required and IUX cannot supply it: the framework holds roles
and never user-facing strings, so a framework-composed word would ship English
into an application that is not in English. It is also the only carrier of the
category that survives a screen reader, a monochrome display and an inverted
one.

There is **no `guidance` parameter.** Guidance is required exactly where there
is no control and absent everywhere else, which is a rule the sealed type
already holds; a parameter here would be a second place for it to be omitted.

There is **no dismissal**, and there will not be one. Closing this would erase
the only account of why the region is empty while the region is still empty. A
failure the user may wave away is an `IuxAlert` beside content that still
exists.

There is **no title.** Two levels of text in a block this size is two things to
read before knowing whether it matters.

## Behaviour

- The parent decides whether this widget is on screen. Nothing here inspects an
  operation, nothing infers success or failure, and nothing hides itself on
  activation: a component that removed itself on retry would hide a failure that
  is still happening.
- The route's control is an `IuxButton`, so focus, press, disabled semantics,
  target size, text scaling and repeat handling all come from
  `IuxActionDescriptor` exactly as they do everywhere else.
- Nothing animates. The block's arrival is the parent's to transition, and an
  entrance animation here would delay the announcement to save nothing. There is
  therefore nothing for a reduced-motion preference to remove.
- No feedback is emitted. A component emits feedback only when the parent
  supplies the event.
- The block is tinted; the control sits on the page below it. Both follow from
  the contrast guarantee — see below.

### Reaching the retry

**The block scrolls itself when, and only when, it is given a bounded height.**
One `LayoutBuilder`, `constraints.hasBoundedHeight` decides, no new parameter,
no new public API — the same shape and the same argument as `IuxEmptyState` and
`IuxPermissionRationale`.

The reason it is the constraints and not a flag: every vertical scroll view in
Flutter hands its children an unbounded height, so a block inside a caller's
`ListView`, `SingleChildScrollView`, `CustomScrollView` or `IuxPage` sees
unbounded height and adds nothing. A block given a *bounded* height was told the
size of a box by something that will not scroll it — the dead-screen case. A
`placement:` parameter would be the right behaviour by the wrong mechanism: the
caller who never read this page is exactly the one who leaves it at its wrong
default.

Measured on 320×640 at 200% text, standalone: before the fix the block
overflowed by **2312 pixels** and the retry landed off screen — an error the
user is told about and cannot act on. After it, one scrollable and one drag
away, and the retry takes a real tap at 100, 150, 200 and 300 per cent.
Scrollable count is **1** standalone and **1** inside all four nesting hosts.
Never two.

This was found because the test that should have caught it wrapped the block in
a `SingleChildScrollView`, which hands the column an unbounded height and left
`expect(tester.takeException(), isNull)` unable to report anything
(IUX-QA-VACUOUS-003).

### Why the block is tinted and the control is not inside it

`IuxEmptyState` draws no surface, and this one does. The reason is contrast
rather than emphasis.

Every colour in the block comes from one `IuxFeedbackRoleColors`, whose content
colour the theme measured against **its own** surface. Text drawn in that colour
on the page behind it would be a pair nobody measured. Tinting is what keeps the
block inside the pair that was.

The control sits outside for the mirror-image reason. `IuxButton` resolves its
container against the page surface, so a button dropped inside a tinted block
would paint a patch of page colour into it and carry a label colour measured
against the page. This is the composition `IuxAlert` prescribes in so many
words — put the button below the message and let it own its own state — and it
is what lets the retry keep a real operation, a real busy announcement and a
real repeat policy instead of the lifecycle-free control an inline message can
hold.

## States

| State | Source |
| --- | --- |
| default | the route, the category word and the message |
| focused, pressed | `IuxButton`, on the control |
| in progress | `IuxRetryRoute.isRunning`, still the parent's |
| announced | always: the block is a live region |
| no control | `IuxUnrecoverable`, and it must say something |

There is **no disabled state** on the retry control, and no parameter that would
produce one. See "Nothing here retries on its own".

There is **no loading state and no empty state.** Those are separate patterns,
and the boundary is stated in "Do not use when" rather than blurred by an extra
enum value here.

## Accessibility

- **The failure is announced where it appears.** The block is a live region
  carrying one label — the category word, the message, and the guidance when
  there is one — so the platform speaks it once, in place, and the user can go
  back over it. `IuxSemantics.liveRegion` is used rather than a direct
  announcement, because an announcement on Android clears TalkBack's speech
  queue and cuts off whatever the user was listening to.
- **It is a live region unconditionally,** unlike `IuxEmptyState`, which takes an
  arrival dimension. A region that is empty may always have been; a region that
  failed is an event by definition. Where a failure is genuinely on screen before
  the user is, the caller owns whether the block is rendered at all.
- **The explanation is one stop.** The block merges into a single semantic node,
  so a screen-reader user hears the whole account as one utterance rather than
  landing on fragments. The control keeps its own node — the block uses
  `IuxSemantics.contentContainer` — because it is somewhere the user has to be
  able to land.
- **Nothing is carried by colour** (SC 1.4.1). The category reaches a screen
  reader through `categoryLabel`, a monochrome screen through the glyph's shape,
  and everyone through the wording: three carriers, so any one of them can fail.
- **The error is identified in text** (SC 3.3.1) and **a suggestion is always
  present** (SC 3.3.3), the second structurally rather than by review.
- **Text scaling.** No line limits and no ellipsis, at any scale. Half a
  sentence about a failure is a failure the user cannot act on, and truncation
  gets worse exactly when someone has enlarged their text because they were
  struggling to read.

### Focus is not moved, and there is no hook to move it

This pattern reaches `IuxEmptyState`'s conclusion and the opposite of
`IuxValidationSummary`'s. Both of those are right, and the difference is what
the framework knows.

`IuxForm` moves focus to its summary because it knows the user just pressed
submit and is standing still waiting for an answer. Nothing here knows that. An
operation can fail while the user is typing somewhere else, or in the
background, or after they have moved on — and taking focus then interrupts them
to announce something they did not ask about.

The specific hazard is worse than interruption. The control this block offers is
usually a retry, and focus landing on a retry puts an activation under the next
Enter or the next screen-reader double-tap. The one pattern in the library whose
control must never fire twice would be the one that armed itself.

The live region says everything focus would have said and arms nothing. The
counter-argument — that a live region can be missed where focus cannot — is
real, and it is why the announcement is unconditional here and optional in
`IuxEmptyState`.

`test/patterns/iux_error_recovery_test.dart` measures this rather than asserting
prose: focus is put on a control elsewhere, the failure is then inserted, and
the primary focus is required to be unchanged with the retry on screen.

Manual validation still required: TalkBack (that the live region is spoken, and
spoken once), Voice Access, and a physical keyboard and D-pad reaching the
control.

## Themes and tokens

Everything is resolved from `IuxInlineFeedbackResolver` at
`IuxFeedbackCategory.error` — the same resolver `IuxAlert`, `IuxBanner` and
`IuxValidationSummary` read, so the error family cannot drift into different
glyphs, outlines or text roles. Spacing comes from `IuxGap` and `IuxInsets`;
the control's appearance is `IuxButtonResolver`'s. There is no colour, radius or
duration parameter, and there will not be one.

## Anti-patterns

| Instead of | Do |
| --- | --- |
| "Something went wrong" | name what the user does not have: "Your orders could not be loaded" |
| an error with an "OK" button | name the outcome: "Try again", "Sign in again" |
| "Try again" on a 401, 403, 404 or a declined card | `IuxAlternativeRoute` to where the fix actually is |
| retrying three times before telling the user | one attempt, asked for by the user |
| a spinner replacing the message on retry | keep the message; `isRunning` announces the attempt |
| disabling the retry after N attempts | swap the route for an alternative |
| an error the user can only dismiss | `IuxAlert` if it may be dismissed; this if it may not |
| blaming the connection for a server fault | say only what is true |
| an error block for a rejected field | the field's own message, or `IuxValidationSummary` |
| an error block for an empty result | `IuxEmptyState` |

## Limits

- **A live region is a request, not a guarantee.** Whether the platform speaks
  it, and when, is the platform's decision. A widget test can assert the node
  carries the flag and no more, so TalkBack remains a manual check. Nothing
  essential depends on the announcement — the same words are on screen either
  way.
- **The block scrolls itself only when it was given a bounded height.** See
  "Reaching the retry" — inside anything that already scrolls it adds nothing,
  which is the rule it always had.
- **One failure, one block.** A screen with three failed sections shows three of
  these, beside the three things that failed. There is no collected list of
  failures, and `IuxValidationSummary` is not a substitute for one because it
  travels to fields.
- **One control.** A failure the user must resolve by choosing between three
  things is a decision, and a decision belongs somewhere they can read the
  options side by side. Where two offers are genuinely both honest — a declined
  card is a transient authorisation failure *and* a card to stop using — put the
  second one below the block as an `IuxButton` of its own.
- **Whether a failure is retryable is not checked.** It cannot be. See "What is
  unconstructible, and what is only visible".
- **The assertions are debug-only.** A release build with an empty message will
  render one. The rules are teaching tools, not runtime guards.
- **No error code is shown.** A reference the user can quote goes in the message
  or the guidance, in the caller's own wording; the pattern has no slot that
  would tempt an application to print a stack trace at a user.
- **Not in the catalog yet.** `apps/catalog` is outside this mission's scope.

## Evidence level

| Rule | Level | Source |
| --- | --- | --- |
| An error message states what happened in text | Standard | WCAG 2.2 SC 3.3.1 |
| An error offers a suggestion for correction | Standard | WCAG 2.2 SC 3.3.3 |
| Meaning is never carried by colour alone | Standard | WCAG 2.2 SC 1.4.1 |
| No time limit is imposed | Standard | WCAG 2.2 SC 2.2.1 |
| A change of content is announced to assistive technology | Standard | WCAG 2.2 SC 4.1.3 |
| Every control is named and its state announced | Standard | WCAG 2.2 SC 4.1.2 |
| Text stays readable when enlarged | Standard | WCAG 2.2 SC 1.4.4 |
| An error message says what to do, not only that something broke | Strong guidance | NN/g, error message guidelines; Material Design, error states |
| Retry is offered only where repeating can succeed | Strong guidance | NN/g; Google SRE, on client retry behaviour |
| Automatic client retries amplify load on a failing service | Strong guidance | Google SRE, "Handling Overload"; AWS, on retry storms |
| A non-idempotent operation is never repeated without the user asking | Standard | reasoned from idempotency; the failure mode is a double charge |
| Three routes rather than two or four | Brand choice | IUX governance; the third exists to make "nothing can be done" deliberate |
| Requiring the route rather than making it optional | Brand choice | IUX governance, PROJECT_PROMPT.md §22 |
| Not moving focus, unconditional live region | Hypothesis | reasoned from the retry-arming hazard; needs TalkBack validation |
| Tinting the block while `IuxEmptyState` does not | Context dependent | follows from the contrast pairing, not from taste |

## Sources

- WCAG 2.2 — SC 1.4.1, 1.4.4, 2.2.1, 3.3.1, 3.3.3, 4.1.2, 4.1.3.
- Android accessibility guidance, live regions and the
  `announceForAccessibility` deprecation.
- Nielsen Norman Group, on error message guidelines and error recovery.
- Material Design, error states.
- Google SRE Book, "Handling Overload" and "Addressing Cascading Failures", on
  client-side retry amplification.
- `PROJECT_PROMPT.md` §5 (priorities), §18 (error prevention), §19–22 (API
  design), §57 (patterns).
- `docs/components/component-standard.md` §2, §3, §5, §6, §7, §11.
- `docs/components/action-model.md`, `docs/components/inline-feedback.md`,
  `docs/patterns/empty-state.md`, `docs/patterns/guided-form.md`.
