# Permission rationale

## Purpose

Explain why an application wants a permission, and offer only the moves that
are honest at this point in the conversation.

```dart
IuxPermissionRationale(
  moment: IuxBeforeAsking(
    ask: IuxInlineFeedbackAction(
      label: l10n.chooseCameraAccess,
      onActivate: controller.requestCameraPermission,
    ),
    decline: IuxInlineFeedbackAction(
      label: l10n.notNow,
      onActivate: controller.dismissRationale,
    ),
  ),
  title: l10n.scanReceiptsWithYourCamera,
  reason: l10n.photographsAreReadOnThisDeviceAndNeverUploaded,
)
```

## "Before" and "after" are not the same screen

This is the whole argument of the pattern, so it comes before the API.

A rationale shown **before** the system prompt is a request to be allowed to
ask. A rationale shown **after** the user has refused is a reply to an answer
they already gave. A rationale shown once the system has stopped offering the
prompt is neither, because nothing this application does can reopen it.

| Moment | The user has | The application may |
| --- | --- | --- |
| `IuxBeforeAsking` | not been asked | ask, once they agree to be asked |
| `IuxAfterRefusal` | said no | explain, and ask at most once more |
| `IuxSystemWillNotAsk` | said no, and the system has closed the door | send them to the setting, and nothing else |

Collapsing those into one `PermissionPrompt(title, message, onAllow)` is how
applications end up nagging: the same block, with the same button, shown again
on every entry to the screen, long after the answer stopped being obtainable.
So the three are separate types and the wrong offer is not validated at runtime
— it does not compile:

```dart
// The ask is required. A rationale that cannot lead to the question is a wall
// of text with no door.
IuxBeforeAsking(ask: …, decline: …)

// Optional, because deciding not to ask twice must be as cheap as asking.
IuxAfterRefusal(decline: …)

// There is no ask parameter. The system will not put the question, and a
// control that produced nothing when pressed reads as a broken application.
IuxSystemWillNotAsk(openSettings: …, decline: …)
```

### Every moment can be declined

`decline` is required on all three, and it is the most load-bearing rule here.

The user always has a way out. A request that cannot be refused is not a
request, and a screen that explains why an application wants something and
offers a single control is a wall.

And the parent always receives the refusal. That callback is the only signal an
application gets that this user said no *to being asked* — the system prompt
reports its own answer, but nothing reports that the user walked away from the
rationale before it. **A pattern with no such signal can only nag, because the
caller has nothing to record.**

## The platform boundary

**This pattern calls no permission API, reads no permission status, and imports
nothing platform-specific.** Not as an omission to be filled in later — as the
design. Three reasons, in order of how badly each would fail:

1. **A framework that asked would be asking on the user's behalf.** The system
   prompt is answerable a fixed number of times. Spending one of those on a
   request a widget made during a build is not a mistake an application can
   recover from: on Android the second refusal closes the prompt for the
   lifetime of the installation.
2. **A framework that checked would be wrong somewhere.** Permission models
   differ by platform, by API level and by permission — foreground against
   background location, partial photo access, a notification permission that did
   not exist before Android 13. One abstraction over all of that either lies
   about a platform or grows into the plugin it was trying to avoid.
3. **It would put a dependency in everyone's way.** A package that pulled in a
   permission plugin would drag its manifest entries, its platform channels and
   its release cadence into applications that never touch a permission.

So the application makes the call and hands this pattern the answer. A typical
mapping, which is the *caller's* to write and is given here only so nobody has
to invent it:

| Platform answer | Moment |
| --- | --- |
| not asked yet; or granted in part and more can be asked for | `IuxBeforeAsking` |
| denied, and the platform says a rationale should be shown | `IuxAfterRefusal` |
| denied and the prompt no longer appears; restricted by policy | `IuxSystemWillNotAsk` |
| granted | render the feature — there is no rationale to show |

`test/patterns/iux_permission_rationale_test.dart` measures this rather than
asserting it: the two source files are read, every `import` is required to be
`package:flutter/…` or a relative IUX path, and the code outside comments is
required to contain no `MethodChannel`, no `Platform.`, no `dart:io` and no
permission-plugin symbol.

## Asking twice: the position this pattern takes

**Re-asking is permitted, and it is permitted exactly once, and only where the
user came back.**

Forbidding it outright would be dishonest. The platform provides
`shouldShowRequestPermissionRationale` precisely so an application can explain
itself and put the question again, and a pattern that refused would push every
application that needs it back into building its own — where nothing constrains
it at all.

What is not permitted is the loop, and the loop is prevented structurally rather
than by advice:

- **Nothing here decides it should be on screen.** This is a value a parent
  renders. There is no controller that opens anything, no route pushed, no
  overlay inserted.
- **Nothing here calls the platform.** There is no path from a build to a system
  prompt. Every prompt is one a user activated with their own finger.
- **Nothing here counts, waits or repeats.** No attempt budget, no timer, no
  backoff, no "ask again in three days". A rationale left on screen for an hour
  asks for nothing, and the test that advances thirty seconds and finds no
  activation and no transient callback is what keeps that true.
- **The refusal is always reported**, so the parent is handed the signal it
  needs in order to stop.
- **`IuxSystemWillNotAsk` cannot ask**, so the one re-ask that is guaranteed to
  do nothing at all is unrepresentable.

**What the framework cannot prevent**, stated rather than hidden: a parent that
rebuilds this block on every entry to a screen will ask every time, and no
widget can stop it. IUX holds the shape of the conversation; its cadence belongs
to the application.

## Use when

- a feature the user has just reached for needs a permission they have not
  granted, and the reason is not obvious from what they pressed;
- the user refused, has come back to the feature, and is owed an explanation
  before anything asks again;
- the system will not put the question any more, and the screen has to say so
  and point at the setting.

## Do not use when

| Situation | Use |
| --- | --- |
| the region is empty because this user may not see what is in it | `IuxEmptyState` with `IuxAccessRestricted` |
| an operation the user started broke on a missing permission | `IuxErrorRecovery` with `IuxAlternativeRoute` |
| the reason is obvious from the control the user pressed | ask directly; the rationale is a screen they did not need |
| the user has not touched the feature yet | nothing — a rationale on first launch is still an interruption |
| the permission is granted | render the feature |

Three of those are worth spelling out.

**An empty state reports a consequence; this makes a request.** `IuxEmptyState`
with `IuxAccessRestricted` is what a region looks like *afterwards*: the content
is there, this user may not see it, and the block accounts for why. This block
is a question being put, with an answer expected and a refusal always on offer.

| | `IuxEmptyState` + `IuxAccessRestricted` | `IuxPermissionRationale` |
| --- | --- | --- |
| the user is | looking at a region with nothing in it | being asked something |
| the block is | an account of why | an argument, and a choice |
| it offers | one exit | a forward control, always beside a refusal |
| the moment | afterwards | before, or between |

They meet at exactly one point: the empty state's optional `request` action is a
natural place for a parent to raise this block. Neither renders the other, and
neither holds the other's wording.

**A refusal is not a failure.** Reporting it with `IuxErrorRecovery` would put
the word "Error", an error tint and an error glyph around a decision the user was
entitled to make. Where a *running operation* broke because a permission was
missing — an upload that reached the storage layer and stopped — that genuinely
is a failure, and `error-recovery.md` already says which route it takes: never
`IuxRetryRoute`, because nothing the user repeats changes their permissions.

**It is not a dialog.** Do not place it inside an `IuxDialog`. A dialog is
already a question and already composes its own title, message and choices, so
the two together produce a block with two headings and four controls. Put it
where the feature is — inline in the region the permission unlocks, or in a sheet
the parent opens — so the user can see what they are being asked about.

## Where it sits among the patterns

| | The content is | The block is |
| --- | --- | --- |
| `IuxPermissionRationale` | not available yet | a request, and a choice |
| `IuxEmptyState` | missing, because there is none for you | what stands in its place |
| `IuxErrorRecovery` | missing, because it failed | what stands in its place |
| `IuxLoadingRetry` | on its way | the wait, the content, or the failure |

## API

### `IuxPermissionMoment`

Sealed. The choice between the three is a claim about the conversation that only
the caller can make, so it is made by naming a type rather than by setting a flag
that reads the same whichever value it holds. A reviewer sees
`IuxSystemWillNotAsk` in a diff; nobody sees `stage: 2`.

| Member | Carries | Forward control |
| --- | --- | --- |
| `IuxBeforeAsking({required ask, required decline})` | a required ask | always |
| `IuxAfterRefusal({askAgain, required decline})` | an optional second ask | when the caller chose to offer one |
| `IuxSystemWillNotAsk({openSettings, required decline})` | an optional settings link | never an ask — there is no parameter |

Both controls are `IuxInlineFeedbackAction`, the library's existing value for a
labelled control with no lifecycle of its own — the same type `IuxAlternativeRoute`
takes, for the same reason. A fourth near-identical action type would have been a
second vocabulary for something the library already says.

`openSettings` is optional because self-service is not always on offer. On a
managed device, under a work profile, or where a guardian holds the setting, the
settings screen shows the user a control they cannot move; sending them there is
worse than not offering, because they now believe they failed at something. The
guidance names who can change it instead.

#### The descriptors are derived, not accepted

There is **no `IuxActionDescriptor` parameter** anywhere in this pattern. Both
descriptors are derived, and their fixed values are the point:

| Control | `role` | `intent` | Why it is not the caller's |
| --- | --- | --- | --- |
| the ask, the settings link | `navigate` | primary, high | it moves the user to a surface this application does not own |
| the refusal | `dismiss` | secondary | declining discards nothing, so it is not a `cancel` |

`navigate` is one claim covering both forward controls: **neither grants
anything.** One hands the user to the operating system's question, the other to
the operating system's settings. An application that advertised either as
"Allow" would promise an outcome it cannot produce.

The role a caller cannot reach for is `retry`. Asking again is not repeating a
request that failed for a transient reason; it is putting a question to a person
for the second time, and announcing it as "Try again" tells someone who
deliberately said no that the interface read their decision as a malfunction.

`dismiss` rather than `cancel` is the distinction the action model already draws:
cancelling abandons an in-progress task and discards what was in it. Declining a
permission discards nothing, and announcing it as a cancellation would tell a
screen-reader user they are about to lose something at the exact moment the
interface is trying to establish that saying no is free.

There is no lifecycle on either control — no `isRunning`, no busy hint, no
availability. What they open is a system surface that takes over the screen, and
the somewhere-else owns its own progress. A spinner underneath a system dialog is
a spinner nobody sees.

### `IuxPermissionRationale`

| Parameter | | |
| --- | --- | --- |
| `moment` | required | where the conversation stands, and therefore what may be offered |
| `title` | required | what is being asked for, in the user's terms |
| `reason` | required | why the application wants it, and what the user gets back |
| `guidance` | optional | what happens without it, and who can change that |
| `illustration` | optional | a decorative glyph, carrying nothing |

`title` names the thing the user gets, not the permission: "Scan receipts with
your camera?" rather than "Camera permission". The user is not short of a
permission; they are short of a feature, and the permission is the application's
problem described in the application's vocabulary.

`reason` is the sentence this pattern exists to carry, and it is required for
that reason. A block that asks for a permission and declines to say why is the
system prompt with extra steps: the user is asked the same unanswerable question
having spent one more screen getting there. Two things earn their place — what
the application does with it, and what the user gets in exchange. "So we can
improve your experience" is neither, and a user told that has been told they are
not owed a reason.

It is separate from `title` for the reason `IuxDialog` keeps its own two apart: a
title states a topic, and a user cannot agree to a topic.

## The dead end

**A moment offering no forward control must be accompanied by `guidance`.** It is
the same rule `IuxEmptyState` enforces, in the one place it applies here, and it
is the one assertion that cannot be replaced by a type.

```dart
// Refused: the system will not ask, nothing points at the setting, and the
// screen declines to say what would help.
IuxPermissionRationale(
  moment: IuxSystemWillNotAsk(decline: …),
  title: l10n.scanReceiptsWithYourCamera,
  reason: l10n.receiptsAreReadOnThisDevice,
)

// Accepted: the sentence is the way out. It is simply made of words.
IuxPermissionRationale(
  moment: IuxSystemWillNotAsk(decline: …),
  title: l10n.scanReceiptsWithYourCamera,
  reason: l10n.receiptsAreReadOnThisDevice,
  guidance: l10n.yourWorkProfileManagesCameraAccessAskYourAdministrator,
)
```

Unlike `IuxEmptyState` there is no exempt moment. `IuxNothingLeftToDo` is exempt
there because the user got exactly what they came for; in every permission
moment the user is short of a feature they reached for.

## Behaviour

- The parent decides whether this widget is on screen. Nothing here inspects a
  permission, nothing infers an answer, and nothing hides itself on activation:
  whether the permission was granted afterwards is something only the parent can
  know, and a block that hid itself would hide a question that may still be
  unanswered.
- Both controls are `IuxButton`s, so availability, focus, press, target size,
  text scaling and repeat handling come from `IuxActionDescriptor` exactly as
  they do everywhere else.
- **The refusal comes first**, which is `IuxDialog`'s ordering and is chosen
  twice over here: it is the first control reached by keyboard, by D-pad and by a
  screen-reader swipe, so the way out is never something the user has to travel
  past a request to find — and the control that opens a system prompt is never
  the one sitting under the first Enter press.
- The controls are laid out with `IuxTargetSpacing`, which wraps to a second line
  rather than overflowing. With real labels on a 400-pixel screen they do not fit
  side by side, and stacking is the only outcome in which both stay usable. The
  minimum target spacing is held either way (SC 2.5.8).
- Nothing animates, so there is nothing for a reduced-motion preference to
  remove and nothing that was carrying information through movement.
- No feedback is emitted. A component emits feedback only when the parent
  supplies the event.
- No surface and no tint is drawn. A tint would have to come from a feedback
  category and none of them is true here: nothing has failed, nothing has
  succeeded, and labelling a request "Information" adds a category word the user
  must hear before the sentence that matters.
- The text is aligned to the start rather than centred, which is where this
  diverges from `IuxEmptyState`. A rationale is a paragraph the user has to read
  and weigh, and centred running text gives both edges a ragged start for the eye
  to find on every line. A one-line empty-state title does not pay that cost; two
  or three sentences of argument do.

## States

| State | Source |
| --- | --- |
| default | the moment, the title, the reason and the guidance |
| focused, pressed | `IuxButton`, on either control |
| announced | always: the argument is a live region |
| no forward control | `IuxAfterRefusal` and `IuxSystemWillNotAsk`, and then the guidance is required |

There is **no disabled state** and no parameter that would produce one. An
application that must stop offering the ask removes the ask — `askAgain: null` —
rather than greying it, so the block goes on offering a way forward instead of a
way that has been taken away without explanation. This is `IuxRetryRoute`'s
position, reached the same way.

There is **no loading state and no error state.** Those are separate patterns,
and the boundary is stated in "Do not use when" rather than blurred by an extra
value here.

## Accessibility

- **The request is announced, unconditionally.** The title, the reason and the
  guidance form one live region, so the platform speaks the whole argument once,
  in place, and the user can go back over it. `IuxEmptyState` takes an arrival
  dimension and stays silent when a screen opened that way; this does not, and
  the asymmetry is the one `IuxErrorRecovery` argues: a region that is empty may
  always have been, but **a request is an event by definition**. A question
  nobody heard is not a question. Being wrong in one direction costs a duplicated
  sentence; being wrong in the other costs a request that reaches only the users
  who can see it (SC 4.1.3).
- `IuxSemantics.liveRegion` is used rather than an announcement API, because an
  announcement on Android clears TalkBack's speech queue and cuts off whatever
  the user was listening to.
- **The argument is one stop, the controls are two more.** Title, reason and
  guidance merge into a single node, so a screen-reader user hears the whole case
  as one utterance rather than landing on three fragments. Each control keeps its
  own node — the block uses `IuxSemantics.contentContainer` — because each is
  somewhere the user has to be able to land.
- **The framework adds no words.** The announced label is measured in the tests:
  the caller's three sentences are removed from it and nothing containing a
  letter may be left.
- **Nothing is carried by colour** (SC 1.4.1). The moment reaches the user
  through the wording and through which controls exist, never through a tint;
  there is no tint. The glyph is excluded from the semantic tree outright
  (SC 1.1.1) and cannot be the sole carrier of anything, because `title` and
  `reason` are both required and neither may be empty.
- **The refusal is held to the same floor as the request** — same control type,
  same target size, same place in the focus order. There is no parameter that
  would draw it as a bare word beside a filled rectangle, because that asymmetry,
  not the wording and not the order, is what makes a permission screen feel like
  a trap.
- **Text scaling.** No line limits and no ellipsis, at any scale. Half a reason is
  a reason the user cannot weigh, and a user who cannot weigh a request refuses
  it. At 200% on a 320-pixel screen both answers are still on screen, which the
  tests check: a request whose refusal has been pushed off the layout is a request
  with one answer.

### Focus is not moved, and there is no hook to move it

This reaches `IuxEmptyState`'s and `IuxErrorRecovery`'s conclusion rather than
`IuxValidationSummary`'s. All four are right, and the difference is what the
framework knows.

`IuxForm` moves focus to its summary because it built that summary in response to
a submission it watched the user make, so it knows they are standing still
waiting for an answer. Nothing here knows that. This block is rendered by a
parent, and the parent may be rendering it because the user tapped a feature,
because a settings row expanded, or because a screen opened with it already on
it. Moving focus in the last two cases interrupts a user to announce something
they did not ask about.

The specific hazard is worse than interruption, and it is worse here than
anywhere else in the library. Focus landing on a control arms it under the next
Enter or the next screen-reader double-tap — and the control this block offers
opens the operating system's permission prompt. A retry fired by accident costs a
request; a permission prompt fired by accident costs the user an answer they
cannot get back, because a refusal they never meant to give can close the prompt
permanently. The live region says everything focus would have said and arms
nothing.

`test/patterns/iux_permission_rationale_test.dart` measures this rather than
asserting prose: focus is put on a control elsewhere, the rationale is then
inserted, and the primary focus is required to be unchanged with the request on
screen. A second test sends one Tab and one Enter and requires the refusal to
have run and the request not to have.

### On WCAG SC 3.3.1

**It does not bind, and saying so is more useful than claiming it.** SC 3.3.1
(Error Identification) applies where an input error is automatically detected: an
item the user entered, identified and described in text. Nothing the user entered
is rejected here. A permission refusal is a decision they made, and treating it
as an error is precisely the mistake "Do not use when" is about.

What is met in the same spirit — and the reason the criterion comes up at all —
is that the state of the conversation reaches the user in text: the moment is
carried by the wording and by which controls exist, never by a colour, so a
screen-reader user, a monochrome display and an inverted one all receive it.

Manual validation still required: TalkBack (that the live region is spoken, and
spoken once), Voice Access, and a physical keyboard and D-pad reaching both
controls.

## Themes and tokens

Everything is resolved from the theme: `IuxTypographyTheme.title` over
`content.primary` for the title, `body` over `content.primary` for the reason —
the substance rather than a caption, because a justification set in the secondary
colour reads as small print — and `body` over `content.secondary` for the
guidance. The glyph is an `IuxIcon` at secondary emphasis; spacing comes from
`IuxGap` and `IuxTargetSpacing`. There is no colour, radius or duration
parameter, and there will not be one.

## Anti-patterns

| Instead of | Do |
| --- | --- |
| a button labelled "Allow" in your own interface | name what it does: "Choose camera access" — the system allows, you do not |
| "Try again" after a refusal | a fresh offer, or no offer; the descriptor refuses the retry role |
| showing the rationale on first launch | show it where the feature is, when the user reaches for it |
| a rationale with a single button | every moment carries a refusal, and the type requires one |
| a full-width "Allow" above a grey "no thanks" link | two `IuxButton`s; the asymmetry is the manipulation |
| a button that offers to ask when the system will not | `IuxSystemWillNotAsk`, which has no such parameter |
| "This app needs the camera permission" | say what the user gets: "Scan receipts with your camera" |
| "So we can improve your experience" | a bounded claim: "read on this device and never uploaded" |
| an error block for a refusal | this pattern; a refusal is a decision, not a breakdown |
| re-showing the rationale on every screen entry | record the refusal `decline` reports, and stop |

## Limits

- **Nothing here can stop an application nagging.** The pattern starts no loop,
  but cadence belongs to the parent. See "Asking twice", above.
- **A live region is a request, not a guarantee.** Whether the platform speaks
  it, and when, is the platform's decision. A widget test can assert the node
  carries the flag and no more, so TalkBack remains a manual check. Nothing
  essential depends on it — the same words are on screen either way.
- **The block does not scroll.** A long reason at a large text scale in a short
  viewport is the caller's to place inside something scrollable, because a block
  embedded in a list that already scrolls must not introduce a second one.
- **One permission, one block.** A feature needing three of them is three
  conversations, and stacking three of these is a screen that asks for everything
  at once — which is the pattern users learn to refuse wholesale. Ask for each
  where it is used.
- **No status is read and none can be.** The correctness of the moment is the
  caller's. A caller who passes `IuxBeforeAsking` for a permanently denied
  permission will render a button that does nothing, and no assertion here can
  catch it — the framework has no way to know.
- **The assertions are debug-only.** A release build with a dead end will render
  one. The rules are teaching tools, not runtime guards.
- **Not in the catalog yet.** `apps/catalog` is outside this mission's scope.

## Evidence level

| Rule | Level | Source |
| --- | --- | --- |
| Meaning is never carried by colour alone | Standard | WCAG 2.2 SC 1.4.1 |
| A change of content is announced to assistive technology | Standard | WCAG 2.2 SC 4.1.3 |
| Every control is named and its state announced | Standard | WCAG 2.2 SC 4.1.2 |
| Text stays readable when enlarged | Standard | WCAG 2.2 SC 1.4.4 |
| Decorative imagery is hidden rather than described | Standard | WCAG 2.2 SC 1.1.1 |
| Adjacent targets keep spacing as well as size | Standard | WCAG 2.2 SC 2.5.8 |
| No time limit is imposed, so there is none to adjust | Standard | WCAG 2.2 SC 2.2.1 |
| SC 3.3.1 does not bind a permission refusal | Standard, read narrowly | WCAG 2.2 SC 3.3.1 — see the section above |
| A permission is requested in context, when the feature is used | Strong guidance | Android developer guidance on requesting permissions; NN/g *(to verify)* |
| An educational screen explains why before the system prompt | Strong guidance | Android developer guidance, "explain why your app needs permissions" *(to verify)* |
| Refusing is always as reachable as agreeing | Strong guidance | EDPB guidelines on deceptive design; deceptive-design literature *(to verify)* |
| The dismissive control comes first in reading order | Context dependent | Material Design dialog action order; `docs/components/dialog.md` |
| Running text is start-aligned rather than centred | Context dependent | readability guidance for long passages *(to verify)*; and `IuxEmptyState` diverges deliberately |
| Three moments rather than two or four | Brand choice | IUX governance; the third exists so "the system will not ask" cannot be represented as an ask |
| A refusal is required in every moment | Brand choice | IUX governance, `PROJECT_PROMPT.md` §22 |
| The descriptors are derived so no control can be a retry | Brand choice | follows from `docs/patterns/error-recovery.md` |
| Unconditional live region, and focus is never moved | Hypothesis | reasoned from the prompt-arming hazard; needs TalkBack validation |
| One re-ask permitted, none automated | Hypothesis | reasoned from the platform's own rationale signal; needs field validation |

Rows marked *(to verify)* are cited from working knowledge and were not opened
during this mission. They are recorded so the next reader can confirm or correct
them rather than inherit them as settled.

## Sources

- WCAG 2.2 — SC 1.1.1, 1.4.1, 1.4.4, 2.2.1, 2.5.8, 3.3.1, 4.1.2, 4.1.3.
- Android accessibility guidance, live regions and the
  `announceForAccessibility` deprecation.
- Android developer guidance on requesting runtime permissions and on
  explaining why a permission is needed *(to verify)*.
- European Data Protection Board guidelines on deceptive design patterns
  *(to verify)*.
- Nielsen Norman Group, on permission requests and on consent *(to verify)*.
- Material Design, dialog action order.
- `PROJECT_PROMPT.md` §5 (priorities), §17 (cognitive load), §19–22 (API
  design), §52 (safety), §57 (patterns).
- `docs/components/component-standard.md` §2, §3, §5, §6, §7, §11.
- `docs/components/action-model.md`, `docs/components/dialog.md`,
  `docs/components/inline-feedback.md`, `docs/patterns/empty-state.md`,
  `docs/patterns/error-recovery.md`, `docs/patterns/guided-form.md`.
