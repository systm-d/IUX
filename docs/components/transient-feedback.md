# IuxTransientLayer and IuxTransientMessage

## Purpose

Say something the user is allowed to miss.

```dart
IuxTransientLayer(
  message: state.notice,             // an IuxTransientMessage, or null
  onDismissed: controller.clearNotice,
  child: IuxPage(child: content),
)
```

This is what other libraries call a snack bar or a toast. IUX names it for the
property that decides whether you may use it — that it disappears — rather than
for its shape, because the shape is not what goes wrong.

## The rule

**Never put anything here that the user needs.**

Everything else on this page follows from that sentence. A transient message is
the worst carrier of information in the library, and not by a small margin:

- it leaves on a timer, so a slow reader loses it;
- it leaves on a timer, so a screen-reader user who was three words into
  another sentence loses it;
- it leaves on a timer, so anyone who looked at their hands, at the keyboard,
  or out of the window loses it;
- there is no scrollback, no history and no notification centre, so nobody who
  lost it can get it back;
- **nothing tells any of them that something left.** The failure is silent, and
  a silent failure cannot be recovered from because it cannot be noticed.

The test to apply before writing one:

> If this user looked away for ten seconds and never saw this message at all,
> is anything worse for them?

If the answer is yes, it does not belong here. If the answer is no, it may go
here — and it may just as well go nowhere.

## Use when, and where it goes instead

| What you have | Where it goes | Why |
| --- | --- | --- |
| a failure — the upload broke, the card was declined | `IuxAlert` | it stays until the parent removes it, and it names a way out |
| a standing condition — offline, service degraded | `IuxBanner` | the condition has not ended, so neither may the message |
| a warning about what the next action costs | `IuxAlert`, or `IuxDialog` | the cost is still coming |
| a decision the user must make before continuing | `IuxDialog` | it waits for an answer instead of expiring |
| one field's validation failure | the field itself | it belongs under the control it refuses |
| a result the screen already shows | nowhere | a "Sent" notice over a conversation showing the sent message is the same fact twice |
| a result that is *not* visible, and that nothing depends on | **here** | "Draft saved", "Copied", "Reconnected", "Sorting by date" |

The distinction from IUX-014 is not shape, and it is not urgency. It is
**whether the information survives being missed**. An alert and a banner are
removed by the parent when the state they describe changes; this is removed by
a clock that knows nothing about that state. The two are not interchangeable and
no parameter turns one into the other.

`IuxTransientTone` has exactly two values, `neutral` and `success`, and the
missing ones are the design: there is no `error` and no `warning`, so a failure
cannot be placed in this channel at all.

## Where the layer goes, when there is navigation

**`IuxTransientLayer` goes *inside* `IuxAdaptiveNavigation`; `IuxModalLayer`
goes outside it.** The order is not a preference, and getting it wrong is
`IUX-TRANSIENT-COVER-001` — the worst defect the pilot application found.

**The other order is now refused rather than described.** Every component that
owns a navigation destination checks, on every build, that no
`IuxTransientLayer` frames it, and throws when one does. The check is
`IuxTransientLayer.debugCheckNotPlacedOver`, it lives entirely inside an
`assert`, and the error it throws names the widget you wrote and prints the
arrangement below as the fix. So the paragraphs that follow explain a mistake
you can no longer ship in a debug build; they are here because knowing *why*
survives a refactor and an error message does not.

**A scroll view between the two ends the check**, and that exemption is not a
convenience. A notice is pinned to the bottom of the *viewport*; content inside
a scroll view moves past that edge rather than standing on it. Navigation never
scrolls — both navigation pages say to put it in `Scaffold.body` and not in a
scroll view — so a navigation component found on the far side of one is not
acting as navigation. It is a specimen: a component gallery, a design-system
page, a screenshot harness. `apps/catalog` is exactly that, and renders three of
these components live inside a `ListView` under its own transient layer. A
notice drifting over a specimen costs a reader nothing, and a check that refused
it would be refusing the library's own documentation of itself.

```dart
IuxModalLayer(                 // outside: a dialog must cover the navigation
  dialog: controller.dialog,
  child: IuxAdaptiveNavigation(
    // …
    child: IuxTransientLayer(  // inside: a notice must not
      message: notice,
      onDismissed: dismiss,
      child: screen,
    ),
  ),
)
```

A dialog is a question, and a user who can change section while it is open
answers it about a screen they have left — so it covers the navigation. A notice
is not a question, and covering the navigation with one is a reachability
failure rather than a modal one.

**This layer pins its message to the bottom of whatever it wraps and reserves no
layout space for it.** Wrapped around the whole shell it therefore lands on top
of the bottom navigation bar. Measured on a 360x800 window: the notice occupies
y 712–760, the three destinations sit at y 740–786, and **all three report
`hitTestable = 0` for the whole dwell**. The dwell is a minimum of four seconds
and by design cannot be shortened, so on that arrangement every "Draft saved"
costs the user their ability to change section — a WCAG 2.2 SC 2.2.1 failure
produced by composition, with neither component at fault on its own.

A pushed route cannot reach the layers beneath it, so **every route that shows a
notice or a dialog places its own pair.** See `apps/pilot/lib/main.dart` and
`apps/pilot/lib/job_detail_screen.dart`.

### What the working arrangement measures

Placed inside the navigation, the notice is laid out in the box the navigation
left over, so its bottom edge is the bar's top edge at worst. Three destinations,
a message long enough to wrap, `hitTestable` on every destination and a tap that
changes section — the way the defect was found:

| Window | Text | Bar | Notice | Destinations reachable |
| --- | --- | --- | --- | --- |
| 320×640 | 100% | 548–640 | 252–516 | 3 / 3 |
| 320×640 | 150% | 460–640 | −148–428 | 3 / 3 |
| 320×640 | 200% | 424–640 | −616–392 | 3 / 3 |
| 320×640 | 300% | 312–640 | −1880–280 | 3 / 3 |
| 360×800 | 100% | 708–800 | 484–676 | 3 / 3 |
| 360×800 | 150% | 620–800 | 156–588 | 3 / 3 |
| 360×800 | 200% | 584–800 | −216–552 | 3 / 3 |
| 360×800 | 300% | 472–800 | −1360–280 | 3 / 3 |

Against the same eight cases on the arrangement that is now refused: **0 / 3
reachable in six of them and 1 / 3 in the other two**, the one that survives
being the first destination on the rows where a one-line notice happens to sit
between two stacked ones.

The negative tops are the cost, and it is the one this fix charges: the notice
now has the page's height rather than the window's, so a long message at an
enlarged text size runs off the top of its box sooner than it used to and is
clipped there. That is the limit already recorded below — *a long message at
200% text on a small screen can exceed the space above the bottom edge* — moved
earlier by the height of the bar. It is clipping rather than an overflow, the
`Stack` absorbs it, and what is lost is the top of a sentence nobody needed
against a navigation bar everybody does. Keep the sentence short.

Both are in
`packages/iux_flutter/test/components/iux_transient_navigation_test.dart`.

## Do not use when

- **The message answers a question the user asked.** They are waiting for it;
  make them look for it and they will read it once, at the bottom of the screen,
  if they are lucky.
- **Two of them would appear together.** There is no queue. See below.
- **You need the user to notice the tone.** The tone is not spoken and carries
  no information. If it mattered, the message is information.
- **You are about to write a second sentence.** A message long enough to need
  one is a message someone has to be given time to read.
- **You want the component to decide anything.** It never decides that it should
  appear, never removes itself, and never changes because a control inside it
  was used.

## API

```dart
IuxTransientMessage(
  text: l10n.draftSaved,                       // required, localised
  dismissLabel: l10n.dismissDraftSavedNotice,  // required, localised
  tone: IuxTransientTone.success,              // default: neutral
  action: null,                                // read the section below first
)

IuxTransientLayer(
  message: message,        // one, or null. Never a list.
  onDismissed: clear,      // required
  minimumDwell: null,      // raises the floor, never lowers it
  child: page,
)
```

| Type | What it is |
| --- | --- |
| `IuxTransientMessage` | the value: text, dismiss label, tone, optional action |
| `IuxTransientTone` | `neutral`, `success` — and nothing else |
| `IuxTransientAction` | one thing the user may do; attaching it removes the timer |
| `IuxTransientLayer` | the layer a parent places; owns the clock |
| `IuxTransientLayer.debugCheckNotPlacedOver` | the composition check every navigation component runs; debug only |
| `IuxTransientTiming` | how long a message stays, and when it must not expire |
| `IuxTransientTokens` / `IuxTransientResolver` | the resolved appearance |

There is no colour, glyph, radius, elevation or duration parameter, and there
will not be one. There is no `IuxTransientTheme` either: the one thing an
application might genuinely want to vary — how long a message stays — is
deliberately not a theme value, because a theme is a look and reading time is
not.

**The message is a value, not a widget.** An `IuxDialog` can be passed around as
a widget because a dialog is self-contained wherever it is placed. A transient
message is defined by *not* occupying layout: put one in a `Column` and it
pushes the page down, which is the one thing it must never do. Describing it as
a value and letting the layer place it removes that mistake from the API instead
of warning about it.

**`dismissLabel` is required**, and it is not bureaucracy. The dismiss control
is what stops the clock and removes the message for a user who has read it, and
it is an icon with no text of its own — unnamed it reaches a screen reader as
"button". Say what disappears ("Dismiss the saved-draft notice"), not "Close",
which would be the same word for every message the application ever shows.

## Timing, and WCAG 2.2 SC 2.2.1

**A fixed four-second dismissal fails SC 2.2.1.** The criterion requires that a
time limit set by the content can be turned off, adjusted, or extended, and a
constant offers none of the three. So there is no constant here.

Four mechanisms, in the order they matter:

**1. Nothing that matters is under a timer.** This is the one the other three
rest on. `IuxTransientTone` cannot express a failure or a warning, so the
content under the clock is content whose loss costs the user nothing. A time
limit on something nobody needs is not a time limit on a task.

**2. An action removes the timer entirely.** `IuxTransientTiming.resolve`
returns null the moment `action` is set. If there is something to do, there is
no deadline for doing it.

**3. An expected screen reader removes the timer entirely.** A live region is
queued behind whatever the platform is already speaking, so a clock started when
the message is painted measures nothing for that user; and a screen-reader user
reaches content by navigating to it, which cannot be done to content that has
already gone.

**4. The user stops the clock, and removes the message early.** Touching the
message or moving focus into it suspends the countdown; letting go restarts it
**from the beginning**, because someone who was interrupted has lost their place
and handing back the last three hundred milliseconds hands back nothing. The
dismiss control removes it immediately. Those are the pause and hide mechanisms
of SC 2.2.2, and the focus rule is also what stops a keyboard user being
stranded: the message cannot vanish while they are standing on it.

Where a clock does run, its length is derived rather than chosen:

```text
dwell = max(4 seconds, characters ÷ 10 per second)
```

- The **floor** is four seconds. A short message is not a message that can be
  read quickly: the cost is noticing that something appeared at the edge of a
  screen the user was not looking at, moving their eyes there, and only then
  reading two words. Material's own defaults are shorter than this in both of
  their lengths.
- The **rate** is about 120 words per minute, roughly half the average adult
  silent reading rate. That is not a mistake: the average is measured on someone
  reading deliberately, and this component's reader is doing something else at
  the time.
- There is **no ceiling**. A ceiling is a truncation of somebody's reading time.
  If a message's derived dwell looks absurd, the message is too long to be
  transient.

`IuxTransientLayer.minimumDwell` raises the floor and never lowers it — the same
shape as `IuxTapTarget.minimumSize`. It is the hook for an application that
offers its users a "give me more time" setting, which is the adjustment SC 2.2.1
asks for and which IUX cannot offer on its own because it has no settings
surface. **There is no parameter anywhere in this component that can shorten a
dwell**, because the only reason to want one is to fit more messages into the
same second.

Text size deliberately does *not* shorten or lengthen the dwell. Enlarged text
is a vision accommodation and IUX will not infer a reading speed from it.

## The action, and who loses it

**An action inside a transient message is a trap.** "Undo" that vanishes after
four seconds is undo for fast people. The users who lose it are exactly the ones
who most needed a way back: the person reading slowly, the person listening to a
screen reader that had not reached the message yet, the person moving a switch
one step at a time, the person whose hands were elsewhere.

IUX answers that in the only way that removes the failure rather than narrowing
it: **a message carrying an action does not expire.** There is no duration to
tune and no race to lose.

So: *what happens to a user who cannot reach the action in time?* Nothing
happens. There is no "in time". The message stays until they answer it, dismiss
it, or the parent replaces it.

That has a price, and it is the parent's: the message occupies the bottom of the
screen until somebody deals with it. If that is unacceptable in your layout, the
conclusion is not a shorter timer — it is that the action does not belong in a
transient message, and the undo belongs in the page.

**The undo window is not the message's business.** How long an application holds
a deleted row before committing the deletion is a decision about data. The
parent can run its own clock for that and clear the message when it fires; what
it must not do is let "how long a widget happened to be painted" decide when
data becomes unrecoverable. That is how "Undo" becomes a promise the interface
breaks for the slowest users first.

## Queueing: replace, and what that destroys

**There is no queue.** `message` is a single nullable value rather than a list,
so one cannot be built. A second message replaces the first, and the first is
destroyed — immediately, possibly before it was read.

That is a real loss. It is chosen because the alternatives are worse:

| Strategy | What it destroys |
| --- | --- |
| **replace** (chosen) | the older message, possibly unread |
| queue | the *newness* of the newer message — it waits behind a fact that may already be false, and the user acts on the stale one |
| refuse | the newer message entirely, which is the same loss plus a stale message left on screen |

A queue also multiplies the total time the bottom of the screen is occupied and
the number of things a user is expected to catch, which makes every message in
the queue less likely to be read than the single message would have been.

Replacement is only defensible because of what this component refuses to carry.
**The information destroyed is, by construction, information nobody needed.** A
parent that finds itself wanting a queue has content that is not disposable, and
that content belongs in an `IuxAlert`, where messages can be stacked, read, and
re-read.

The clock restarts with the replacement, so the new message gets its own full
reading time. A message rebuilt with the same words does not restart it — a
parent that rebuilds every frame would otherwise hold a message on screen
forever, one restarted countdown at a time.

## Focus

**It never takes focus.** Moving focus onto something that is about to vanish
strands the user it moved: the message goes, and their focus is somewhere
undefined, in a place they did not choose to be.

Both controls are reachable by tabbing, and reaching either one stops the clock —
so the message cannot disappear out from under someone who is on it. It is last
in the reading order, which is where the least important thing on the screen
belongs; the live region is what brings it to a screen-reader user's attention,
not a jump in the focus order.

**It blocks nothing.** Unlike `IuxDialog`, the layer declares no route, traps no
focus, and does not block the page's semantics. The page behind stays readable
and operable, and the message occupies only the bottom strip, so taps elsewhere
reach the page underneath.

## Accessibility

- **Announced in place, through a live region.** `IuxSemantics.liveRegion`
  carries the sentence. IUX does **not** call an announcement API here: Android
  deprecated `announceForAccessibility` because it clears TalkBack's speech
  queue, cutting off whatever the user chose to listen to. Interrupting someone
  in order to tell them their draft was saved is exactly the trade this
  component must never make.
- **The label is the sentence, and nothing is joined to it.** An `IuxAlert`
  requires a localised category word because the category is part of what the
  user is being told. This asks for none, because the tone says nothing — and a
  message whose category a user needs to hear is a message that must not
  disappear.
- **Colour is never the only carrier**, and there is nothing for it to carry.
  `success` adds a tick; `neutral` adds no glyph at all, because a generic
  "information" symbol on "Copied" is a shape the user decodes before
  discovering it meant nothing.
- **Measured against the surface it sits on.** Text is held to 4.5:1 and the
  glyph to 3:1 against the message's own tinted surface, on all four theme
  profiles, and the outline to 3:1 against the page. Asserted in the tests, not
  assumed. The outline uses the theme's *strong* width rather than its standard
  one — an alert sits in the page's flow against a background the theme
  measured, while this floats over whatever happens to be beneath it.
- **Not elevated.** A shadow resolves to zero under a reduced visual stimulation
  preference, and the edge of something floating over arbitrary content may not
  quietly disappear. Hierarchy rests on the outline and the tint, both of which
  are measurable.
- **Targets.** Both controls meet the resolved touch target floor through
  `IuxTapTarget`, while the glyph and the label stay the size of the text beside
  them.
- **Text scaling.** Works at 200%. No line limit and no ellipsis at any size:
  half a sentence is not a shorter message, it is a different one.
- **Keyboard.** Both controls are reachable and activatable without a pointer,
  and screen-reader activation works because the tap action is carried onto the
  semantic node.
- **Assistive technology can be *sent* to either control**, not only swipe to
  it. Both report a real focus state and offer `SemanticsAction.focus`, and
  performing that action moves focus onto the node the control holds. That
  matters most here of anywhere in the library: the message is on a clock, and
  reaching it stops that clock. Both reported `Tristate.none` with
  `actions: [tap]` until IUX-A11Y-FOCUS-001 was fixed at every call site.
- **RTL.** A `Row` lays out in reading order, so an Arabic interface gets the
  glyph on the right without the widget knowing which language it is in.

**Verified in widget tests.** Still needs a device: whether TalkBack reads the
live region at the moment it appears rather than at the next focus change,
whether Voice Access can name the dismiss control, and whether the pause-on-touch
behaviour is discoverable at all (it is not announced — see Limits).

## States

| State | Source |
| --- | --- |
| shown / absent | `message` — the parent's |
| tone | `message.tone` — the parent's |
| with or without an action | `message.action` — the parent's |
| counting down / suspended | the component's, driven by touch and focus |
| does not expire | derived: an action, or an expected screen reader |
| focused (each control) | the runtime focus ring, drawn outside the control |
| pressed (each control) | the tap target |

There is no loading, disabled or error state. A transient message is not an
operation: it does not run, cannot be unavailable, and never reports a failure of
its own — it has no way to express one, which is the point.

## Motion

One animation: the entrance, declared as `IuxMotionRole.enter` at the short
scale, so a reduced-motion preference shortens it and `IuxMotionPreference.none`
removes it entirely. Nothing is lost either way, because the fade never carried
the message — the sentence did.

**A fade, and no travel.** Travel across the screen is a known vestibular
trigger, and a message arriving at the bottom edge has nowhere informative to
travel from: "where did this come from" is answered by the fact that it is where
every transient message in the application appears.

**No exit animation.** The parent removes the message, and a layer that kept
painting one after the parent said it was gone would be showing a statement
about a state that had already changed.

## Anti-patterns

```dart
// Wrong: a failure in a channel that forgets.
IuxTransientMessage(text: l10n.uploadFailed, dismissLabel: ...)   // no tone fits

// Right: it stays until the parent removes it, and it names a way out.
IuxAlert(
  category: IuxFeedbackCategory.error,
  categoryLabel: l10n.error,
  message: l10n.uploadFailedNoConnection,
  action: IuxNamedAction(label: l10n.tryAgain, onActivate: retry),
)
```

```dart
// Wrong: the parent ignores onDismissed, so the message never leaves.
IuxTransientLayer(message: notice, onDismissed: () {}, child: page)

// Right: the parent owns whether it exists.
IuxTransientLayer(
  message: state.notice,
  onDismissed: () => setState(() => state.notice = null),
  child: page,
)
```

```dart
// Wrong: two messages, one slot. The first is destroyed unread.
show(savedNotice);
show(reconnectedNotice);

// Right: say the one thing that is still true.
show(reconnectedNotice);
```

```dart
// Wrong: an undo whose window is "however long the widget was painted".
onDismissed: () { commitDeletion(); clearNotice(); }

// Right: the data decision is the parent's, and has its own clock.
onDismissed: clearNotice;   // commitDeletion() runs on the parent's schedule
```

```dart
// Wrong: the layer wraps the frame, so every notice lands on the navigation.
// Refused in debug; it used to render, and used to cost the user four seconds
// of navigation per message.
IuxTransientLayer(
  message: state.notice,
  onDismissed: controller.clearNotice,
  child: IuxAdaptiveNavigation(child: page, ...),
)

// Right: the layer wraps the page, which is all it was ever for.
IuxAdaptiveNavigation(
  child: IuxTransientLayer(
    message: state.notice,
    onDismissed: controller.clearNotice,
    child: page,
  ),
  ...,
)
```

## Limits

- **The check is an ancestor test, so it sees composition and nothing else.** It
  catches the arrangement that puts a message over a navigation destination,
  which is the whole of `IUX-TRANSIENT-COVER-001`. It does not know what else is
  at the bottom of the page: a call site that puts its own primary action there
  can still have it covered for a dwell, and nothing warns. The navigation case
  is enforced because navigation is permanent, is always on that edge, and is
  the same edge in every application; a page's own bottom content is none of
  those things.
- **It is an assertion, so a release build has none of it.** That is the right
  trade — the wrong arrangement cannot survive a single run in development, and
  the alternative was a runtime cost on every navigation build forever — but it
  does mean the guarantee is "you cannot develop this mistake", not "you cannot
  run it".
- **The scroll-view exemption leaves one hole**: an application that puts its
  *real* navigation inside a scroll view, under a transient layer, is not
  warned. That arrangement is already broken for a louder reason — an unbounded
  height makes `IuxAdaptiveNavigation` choose the bar without ever measuring the
  window — and closing the hole would mean refusing every component gallery.
- **A message with an action never leaves on its own.** If the parent never
  clears it and the user never touches it, it occupies the bottom of the screen
  indefinitely. That is the deliberate cost of not losing the action; the
  component will not pick a deadline on the user's behalf.
- **Under an expected screen reader nothing auto-dismisses**, including messages
  with no action. One message can therefore sit over the bottom strip until the
  next one replaces it. `MediaQueryData.accessibleNavigation` is a hint rather
  than a guarantee, so a sighted user with an assistive service running gets the
  persistent behaviour too.
- **Pause-on-touch is not announced and not discoverable.** A user who does not
  already know they can press the message to keep it will not find out. The
  dismiss control is the discoverable mechanism; this one is a safety net.
- **The reading rate is calibrated for Latin script.** Thirty characters of
  Japanese carry far more than thirty characters of English, so a dense script
  gets a shorter dwell than it deserves. The floor absorbs short messages;
  longer ones in such scripts are under-served, and the honest mitigation is
  that nothing here is needed.
- **A long message at 200% text on a small screen can exceed the space above the
  bottom edge**, and the top of it is then clipped by the screen. It does not
  scroll, and it will not: a transient message that needs scrolling is not
  transient. Keep the sentence short.
- **The outline is measured against the theme's page surface**, not against
  whatever is actually behind the message. Over a photograph or a video the 3:1
  guarantee does not hold, and no component can make it hold without inspecting
  its own backdrop.
- **The dismiss control comes before the action in reading order.** It sits in
  the trailing top corner, and both TalkBack and the focus traversal sort
  geometrically. Imposing a different keyboard order would give a user of both a
  switch and a screen reader two different sequences for one message, which is
  worse than the order itself. This matches `IuxAlert`, deliberately: two
  comparable components that ordered their controls differently would teach the
  user two habits for one idea.
- **No swipe-to-dismiss.** A swipe is neither announced nor reliably performable
  with a motor impairment, so it would be an affordance for the users who need
  it least. The named control is the only way out.
- **One message at a time, and no history.** Nothing that has been replaced can
  be recovered. That is the property that makes the whole component dangerous
  and the reason for the rule at the top of this page.

## Evidence level

| Claim | Level |
| --- | --- |
| A time limit on content must be adjustable, extendable, or absent | Standard — WCAG 2.2 SC 2.2.1 |
| Auto-updating content needs a pause or hide mechanism | Standard — WCAG 2.2 SC 2.2.2 |
| A live region rather than an announcement API | Standard — Android deprecated `announceForAccessibility`; WCAG 2.2 SC 4.1.3 |
| Text at 4.5:1, glyph and outline at 3:1 | Standard — WCAG 2.2 SC 1.4.3, 1.4.11 |
| Text survives 200% scaling without clipping | Standard — WCAG 2.2 SC 1.4.4 |
| Controls meet the touch target floor | Standard — WCAG 2.2 SC 2.5.8, Android guidance |
| Focus must not move to a transient element | Standard — WCAG 2.2 SC 3.2.1, and the practical consequence of it vanishing |
| Nothing essential belongs in a transient message | Strong guidance — Nielsen Norman Group on transient notifications; Material guidance on snack bar content |
| Refusing to model a failure or a warning as transient | Context dependent — IUX's reading of the above, enforced by the enum having no such value |
| Removing the timer when an action is attached | Context dependent — the strongest available reading of SC 2.2.1; Material allows an indefinite snack bar for exactly this case |
| Replacing rather than queueing | Context dependent — the reasoning is stated above; it has not been user-tested |
| The four-second floor and the ten-characters-per-second rate | Hypothesis — calibrated against published reading rates and deliberately halved, but not measured on this component |
| Restarting the clock rather than resuming it after an interruption | Hypothesis — judgement, not a measured result |

## Sources

- WCAG 2.2 — SC 1.4.3, 1.4.4, 1.4.11, 2.2.1, 2.2.2, 2.4.7, 2.5.8, 3.2.1, 4.1.3.
- Android accessibility guidance on live regions and the deprecation of
  `announceForAccessibility`.
- Material guidance on snack bars: content that is "not essential", and
  indefinite duration where an action is offered.
- Nielsen Norman Group, on transient notifications and the cost of information
  that disappears.
- Brysbaert (2019), on adult silent reading rates — the figure this component
  deliberately halves.
- `docs/components/inline-feedback.md` — where everything refused here goes.
- `docs/feedback/overview.md` — roles, proportion, and why the parent owns the
  truth.
- `docs/components/component-standard.md` §2, §3, §5, §6, §9, §10, §11.
