# IuxAlert and IuxBanner

## Purpose

Say what happened, where the user is looking, and — when something went wrong —
what they can do about it.

```dart
IuxAlert(
  category: IuxFeedbackCategory.error,
  categoryLabel: l10n.error,
  message: l10n.cardDeclined,
  action: IuxNamedAction(
    label: l10n.useAnotherCard,
    onActivate: controller.changePaymentMethod,
  ),
)

IuxBanner(
  category: IuxFeedbackCategory.warning,
  categoryLabel: l10n.warning,
  message: l10n.workingOffline,
)
```

Two components rather than one flag, because the choice between them is a UX
decision and not a rendering detail. `spanning: true` would let a developer put
a single field's failure across the top of the screen without noticing they had.

## Use when

| Component | Scope | Example |
| --- | --- | --- |
| `IuxAlert` | one part of the screen, usually caused by what is there | a form that will not submit, a section whose data failed to load, an operation that just succeeded |
| `IuxBanner` | the whole screen or session, not caused by anything here | working offline, a service degraded, an account not yet verified |

**Choose by scope, not by looks.** A banner is read as "this applies to
everything below it". Putting one field's failure in a banner sends the user
looking for a screen-wide problem that does not exist; putting an outage in an
alert beside the save button suggests the save button caused it.

Place an alert next to what it is about. A message about the payment section,
parked at the top of the page, makes the user hunt for the thing it refers to.

## Do not use when

- **The message should disappear on its own.** These two never do. A transient
  confirmation is IUX-015.
- **A single field failed validation.** The field owns its own error and shows
  it underneath itself. An alert repeating it is the same failure announced
  twice, and the user has to work out whether they are two problems.
- **The result is already visible.** A success alert beside a list that now
  contains the new row is noise with a tick on it.
- **You want the component to decide.** Neither ever decides that it should
  appear, removes itself, or changes because a control inside it was used. The
  parent owns the state; these render what they are given.
- **You are about to stack two banners.** A screen whose content starts halfway
  down is a screen where the second banner is not read.

## API

Both widgets take the same parameters.

| Parameter | Required | Note |
| --- | --- | --- |
| `category` | yes | `info`, `success`, `warning`, `error` |
| `categoryLabel` | yes | the localised word for `category` |
| `message` | yes | what happened, already localised |
| `title` | no | a short first line, when the message runs long |
| `action` | no | `IuxNamedAction` — the way out |
| `dismissal` | no | `IuxInlineFeedbackDismissal` — the way to remove it |

There is no colour, glyph, radius, elevation or duration parameter, and there
will not be one. An API that accepted a colour has already lost the contrast
guarantee, and an API that accepted a glyph could ship a tick on a failure —
which would break the one signal that survives a monochrome screen.

There is no `IuxInlineFeedbackTheme` either. An inline message has no decision
an application could usefully vary that the semantic palette, geometry and
typography do not already carry, and a second place to set an outline width is
a second place for it to disagree with the first.

### Why `categoryLabel` is required

It is the whole of what a screen-reader user gets of the category. The tint and
the glyph exist for the users who can see them; neither reaches TalkBack.

IUX will not supply the word. The feedback layer holds roles and never
user-facing strings, so a framework-composed "Error" would ship English into a
Japanese application. Pass `l10n.error`, not `category.name`.

### The recovery action

`action` is optional in the type system and close to mandatory in practice for
`IuxFeedbackCategory.error`.

**An error message must answer two questions: what happened, and what to do
next.** "Something went wrong" answers neither. It spends the user's attention
and hands back nothing — the user now knows they are stuck and still does not
know why, or whether trying again will cost them anything. Naming the next step
is what turns a report into a way out.

```dart
IuxNamedAction(
  label: l10n.tryAgain,            // name the outcome, not the mechanism
  semanticLabel: l10n.retryUpload, // when three controls all read "Retry"
  onActivate: controller.retry,
)
```

`semanticLabel` exists for the screen holding three failures and therefore three
controls called *Retry*. A user moving through them by control cannot tell which
is which; "Retry uploading the photographs" costs the sighted user nothing.

It is deliberately **not** an `IuxActionDescriptor`. Half of that model has no
meaning here: `intent` cannot vary because the category already fixes the
colour, and `confirmation`, `cancellation` and a running `operation` describe an
action with a lifecycle of its own, which does not belong inside a sentence the
user is still reading. When you need those, put an `IuxButton` below the message
and let it own its own state.

**It was called `IuxInlineFeedbackAction`, and the name had stopped being
true.** The same type is the recovery path of `IuxAlternativeRoute`, both
answers of `IuxPermissionRationale`, and both controls of `IuxOnboardingFlow`;
a name saying "inline feedback" on a permission prompt teaches a caller
something false about where the type belongs. `IuxNamedAction` says what it is —
a control that has a name and does one thing — and says nothing about where it
appears (IUX-API-NAMING-001).

## Dismissal

**Offer it only when the information survives being removed.** The test is not
whether the message is annoying; it is whether the user can still get the fact
back afterwards.

| Message | Dismissible | Why |
| --- | --- | --- |
| a success confirmation | **yes** | once read it is spent |
| an informational note the user has now seen | **yes** | it was never blocking anything |
| a standing condition also shown elsewhere — offline, with an offline icon in the bar | **yes** | the fact remains obtainable |
| a validation failure explaining why a form will not submit | **no** | the form is still refusing, and the explanation is gone |
| a warning about what the next action will cost | **no** | the cost has not gone away |
| an error with no recovery path | **no**, and the constructor refuses it | see below |

A message that reappears the moment the user acts is worse than one that never
left: it teaches them that closing things does nothing, and the next message
they close is the one that mattered.

### The one combination that is refused

```dart
// Asserts. An error whose only control erases the explanation of itself.
IuxAlert(
  category: IuxFeedbackCategory.error,
  categoryLabel: l10n.error,
  message: l10n.cardDeclined,
  dismissal: IuxInlineFeedbackDismissal(...),   // and no action
)
```

Dismissing it asks the user to erase the one account of why their screen is
broken while the failure is still there. Give it an action — retry, open
settings, edit the field — so closing is a choice and not amnesia. If there is
genuinely nothing to do, leave it undismissible.

Every dismissible message carries an accessible name for its control, because
`IuxInlineFeedbackDismissal` requires one. A close control is an icon and
nothing else; unnamed, it reaches a screen reader as "button", and the only way
to find out what it removes is to remove it. Say what disappears — "Dismiss the
offline notice" — not "Close", which is two identical controls with different
consequences on a screen holding two messages.

## States

| State | Source |
| --- | --- |
| category | `category` — the parent's |
| with or without a recovery path | `action` — the parent's |
| dismissible or not | `dismissal` — the parent's |
| focused (each control) | the runtime focus ring, drawn outside the control |
| pressed (each control) | the tap target |

There is no loading, disabled or error state on the message itself. An inline
message is not an operation: it does not run, cannot be unavailable, and never
reports a failure of its own. When the recovery action is long-running or
needs confirming, it belongs in an `IuxButton` below the message rather than
inside it.

## Accessibility

- **Announced once, in place.** The whole message is one live region. When it
  appears, or when its text changes, the platform announces it — once, in
  context, and the user can go back and re-read it. IUX does **not** call an
  announcement API here: on Android that clears TalkBack's speech queue, and a
  message that is on screen has no business interrupting. A user who heard it
  announced and then reached it by swiping would hear it twice.
- **Never colour alone.** Glyph, wording and colour say the same thing three
  times, so any one of them can fail. The four glyphs are four shapes — a
  circled "i", a circled tick, a triangle, a circled "!" — not four colours, so
  the category survives deuteranopia and a black-and-white screenshot. The
  glyph is fixed per category and cannot be overridden.
- **Measured against the surface it sits on.** Text is held to 4.5:1 and the
  glyph to 3:1 against the message's own tinted surface, on all four theme
  profiles, and the outline to 3:1 against the page behind it. That is asserted
  in the tests rather than assumed. It is also why the controls inside the
  message are drawn from the same feedback role rather than from an `IuxButton`:
  a button resolves its container against the *page* surface, so a text or
  outlined button dropped in here would paint a patch of page colour inside a
  tinted block, with a label colour nobody measured against this background.
- **Targets.** Both the dismiss control and the recovery control meet the
  resolved touch target floor through `IuxTapTarget`, while their glyph and
  label stay the size of the text beside them. The interactive region and the
  visual element are different measurements.
- **Text scaling.** Works at 200%. No line limit and no ellipsis, at any scale:
  "We could not charge your card because th…" is a message nobody can act on,
  and truncation gets worse exactly when someone has enlarged their text
  because they were struggling to read it. The text takes whatever the glyph
  and the dismiss control leave, which is what keeps the dismiss control on
  screen on a 320-pixel phone instead of being pushed past the edge.
- **Keyboard.** Both controls are reachable and activatable without a pointer.
- **A screen reader can activate either control, and can be sent to either.**
  Both were announced as buttons with **no tap action at all** and no focus
  state until this was fixed — visible, correctly named, and inert to a
  screen-reader double-tap. That is the IUX-011 defect surviving in a second
  place, found alongside IUX-A11Y-FOCUS-001 by sweeping every composer of
  `IuxSemantics.action`; the mechanical check that was supposed to prevent it
  reads bare `Semantics(` calls and these compose the helper instead. Both now
  carry `[tap, focus]`, and both are measured in
  `test/accessibility/control_focus_semantics_test.dart` — including performing
  each action and checking something happened.
- **RTL.** The glyph leads and the dismiss control trails, in reading order. A
  `Row` lays out in reading order, so an Arabic interface gets the glyph on the
  right without the widget knowing which language it is in.

**Verified in widget tests.** Still requires checking on a device: TalkBack
reading order and whether the live region fires when the parent swaps one
category for another, Voice Access naming of the two controls, and whether the
joined spoken sentence is paced well in a non-Latin script.

## Motion

Only one thing animates: the container, when the category changes underneath it
— a warning becoming an error while the user is looking at it. It is declared as
`IuxMotionRole.stateChange`, so a reduced-motion preference shortens it and
`IuxMotionPreference.none` removes it. Nothing is lost either way, because the
glyph and the words changed with the colour and were never animated.

The **arrival is deliberately not animated**. The parent decides when the
message is on screen, and a component that animated its own entrance would
fight whatever transition the parent had already wrapped it in.

## Anti-patterns

```dart
// Wrong: the message says a failure happened and stops there.
IuxAlert(
  category: IuxFeedbackCategory.error,
  categoryLabel: l10n.error,
  message: l10n.somethingWentWrong,
)

// Right: what happened, and what to do about it.
IuxAlert(
  category: IuxFeedbackCategory.error,
  categoryLabel: l10n.error,
  message: l10n.uploadFailedNoConnection,
  action: IuxNamedAction(
    label: l10n.tryAgain,
    onActivate: controller.retry,
  ),
)
```

```dart
// Wrong: the component decides it is finished.
IuxAlert(..., dismissal: IuxInlineFeedbackDismissal(
  label: l10n.dismiss,
  onDismissed: () {},          // nothing changes; it reappears next rebuild
))

// Right: the parent owns whether it exists.
if (state.lastError != null) IuxAlert(..., dismissal: ...onDismissed: controller.clearError)
```

```dart
// Wrong: the enum name as the spoken category.
categoryLabel: category.name

// Right: it comes from the localisation layer, like every other string.
categoryLabel: l10n.error
```

```dart
// Wrong: a banner for something one section did.
IuxBanner(category: ..., message: l10n.photoUploadFailed)

// Right: put it beside the section it is about.
IuxAlert(category: ..., message: l10n.photoUploadFailed)
```

## Limits

- **One action, and it cannot be busy.** There is no second action, no loading
  state and no confirmation. An action with a lifecycle of its own belongs in a
  button below the message; two actions inside a message is a decision, and a
  decision belongs in a dialog or a pattern.
- **The spoken sentence is joined with a full stop.** The parts are always the
  caller's; only the pause between them is IUX's. A script that pauses with
  something other than "." — Japanese "。" — gets a Latin full stop in the
  spoken string. The alternative was a fourth required string on every call
  site, or three separate stops in the reading order for one sentence.
  `IuxSemantics.action` already makes the same trade when it appends a hint.
- **The dismiss control comes before the recovery control in reading order.**
  It sits in the trailing top corner, and both TalkBack and the focus traversal
  sort geometrically. Imposing a different keyboard order would give a user of
  both a switch and a screen reader two different sequences for one message,
  which is worse than the order itself. The control is named, so hearing it
  first costs a swipe rather than a mistake — but the message is heard before
  either control in every case.
- **Nothing is throttled.** Changing `message` on every frame would make the
  live region speak on every frame. Progress solved this with milestones
  because progress changes continuously; an inline message is not expected to,
  and a parent that changes one continuously has a different problem.
- **No icon-free variant.** Every message carries a glyph, including
  informational ones, which costs about 32 logical pixels of width on a narrow
  screen. Removing it would leave colour and wording, and wording is the
  caller's.
- **The banner does not pin itself.** It renders where it is placed. Keeping it
  visible while the content below scrolls is the caller's layout decision, and
  a component that installed itself at the top of a screen would be doing
  navigation.

## Evidence level

| Claim | Level |
| --- | --- |
| The category must not be carried by colour alone | Standard — WCAG 2.2 SC 1.4.1 |
| Text at 4.5:1, glyph and outline at 3:1 | Standard — WCAG 2.2 SC 1.4.3, 1.4.11 |
| Text must survive 200% scaling without clipping | Standard — WCAG 2.2 SC 1.4.4 |
| A live region rather than an announcement | Standard — Android deprecated `announceForAccessibility`; WCAG 2.2 SC 4.1.3 |
| Controls meet the touch target floor | Standard — WCAG 2.2 SC 2.5.8, Android guidance |
| An error must state the recovery path | Strong guidance — Nielsen Norman Group, WCAG 2.2 SC 3.3.3 |
| Refusing a dismissible error with no action | Context dependent — IUX's reading of the above, enforced by an assertion |
| Alert versus banner split by scope | Strong guidance — Material, and the same reasoning as progress versus loading |
| The four glyph shapes | Context dependent — shape distinctness is the point, the specific glyphs are conventional |
| Dismissible only when the information survives | Hypothesis — the table is judgement, not a measured result |

## Sources

- WCAG 2.2 — SC 1.4.1, 1.4.3, 1.4.4, 1.4.11, 2.4.7, 2.5.8, 3.3.1, 3.3.3, 4.1.3.
- Android accessibility guidance on live regions and the deprecation of
  `announceForAccessibility`.
- Nielsen Norman Group, on error message content and recovery.
- `docs/feedback/overview.md` — roles, proportion, and why the parent owns the
  truth.
- `docs/components/component-standard.md` §2, §3, §5, §6, §9, §11.
