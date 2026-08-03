# IuxProgressIndicator and IuxLoadingIndicator

## Purpose

Tell the user that work is happening, and — whenever it can be known — how much
longer it will take.

```dart
IuxProgressIndicator(
  label: l10n.uploadingPhotos,
  value: uploaded / total,
  valueLabel: l10n.percentComplete(percent),
)

IuxLoadingIndicator(label: l10n.searchingNearbyStores)
```

Two components rather than one flag, because the choice between them is a UX
decision and not a rendering detail. A boolean `indeterminate: true` would let
a developer reach for the weaker of the two without noticing they had.

## Use when

| Component | Use it when |
| --- | --- |
| `IuxProgressIndicator` | the caller can say how far along the work is, even roughly |
| `IuxLoadingIndicator` | nothing can be counted — a request whose size is unknown, a search with no total |

**Prefer the determinate one whenever a fraction exists.** A determinate
indicator answers "how much longer"; an indeterminate one answers nothing, and
a user who cannot estimate the wait cannot decide whether to keep waiting.
Bytes received over bytes expected, files done over files queued, steps
completed over steps planned — most operations can produce a fraction, and the
work of producing it belongs at the call site, not in the component.

## Do not use when

- **The operation finishes in under a couple of hundred milliseconds.** An
  indicator that appears and vanishes reads as a glitch, and the flicker costs
  more attention than the wait did.
- **You want the indicator to report the outcome.** It does not. Reaching 1.0
  means the caller supplied 1.0 and nothing more. Neither component ever
  decides that an operation finished, succeeded or failed; the parent stops
  rendering it and renders whatever comes next. A bar sitting at 100% with no
  successor on screen is a parent that forgot to re-render.
- **You have nothing to say about what is loading.** Both components require a
  label, and there is no way around it. An unlabelled spinner is the most
  common accessibility failure in this category: the user knows something is
  happening, cannot tell what, and cannot tell whether it is stuck.
- **You want a spinner inside a button.** A button reports its own operation
  through `IuxActionDescriptor.operation` (IUX-008.6).

## API

### `IuxProgressIndicator`

| Parameter | Required | Note |
| --- | --- | --- |
| `label` | yes | what is happening, already localised |
| `value` | yes | the fraction done, 0 to 1 |
| `valueLabel` | yes | `value` in words, already localised |

### `IuxLoadingIndicator`

| Parameter | Required | Note |
| --- | --- | --- |
| `label` | yes | what is being waited on, already localised |

There is no colour, thickness, radius, shape or duration parameter, and there
will not be one. There is no `IuxProgressTheme` either: a progress indicator
has no decision an application could usefully vary that geometry, typography
and the semantic palette do not already carry, and a fourth place to set a
thickness is a fourth place for it to disagree with the others.

### Why `valueLabel` is required

A bar with no number leaves the user estimating a length, which people do
badly, and it is the only thing a screen reader can announce as the work
advances.

IUX will not compose it. `45%`, `45 %` and `٤٥٪` are three different strings
and only the caller knows which applies; a framework that guessed would ship
the wrong one in most locales. The same parameter takes `3 of 7` and
`12 MB of 40 MB` without the component needing to know the difference.

Write it so it stands alone — it is announced on its own when progress crosses
a milestone, so `45% uploaded` is kinder than `45%` on a screen holding more
than one operation.

## States

| State | Source |
| --- | --- |
| determinate, at a value | `value` and `valueLabel` — the parent's |
| indeterminate | choosing `IuxLoadingIndicator` at all |
| animated / static | resolved from the motion policy, never from a parameter |

There is no disabled, focused, pressed or error state. A progress indicator is
not interactive: it takes no focus, has no touch target, and reports no
failure. When an operation fails, the parent replaces the indicator with an
error the user can act on — a progress bar that turns red is a progress bar
that has been asked to do a second job.

## Motion, and what happens when it is switched off

Both indicators declare `IuxMotionRole.progress`, the one role IUX preserves
under a reduced-motion preference: removing it would hide the fact that work is
happening, and that is worse than the movement.

Under `IuxMotionPreference.none` the policy removes it anyway — for a user with
a vestibular disorder an essential animation is still an animation — and
`IuxResolvedMotion.requiresStaticAlternative` becomes true. The two components
answer that differently, on purpose:

| | motion permitted | `requiresStaticAlternative` |
| --- | --- | --- |
| `IuxProgressIndicator` | the fill travels between values | the fill snaps; **the bar and the number stay** |
| `IuxLoadingIndicator` | a segment crosses the track | **the bar is removed**; the label is the status line |

A determinate bar is a static statement already: 45% full means 45%, whether or
not the last change was animated. An indeterminate bar is nothing but movement
— freeze it and it becomes a segment parked at a position that means nothing,
which reads as a hung operation rather than a running one. So progress keeps
its track and drops the tween; loading drops the track and keeps the words.

This is why the label of `IuxLoadingIndicator` is always visible, in both
modes, and not only when motion is off. A static alternative that exists only
under one preference is a static alternative nobody has ever seen fail.

One further consequence: a reduced-motion preference halves every transition,
which is right for a transition and wrong for a loop. Halving a cycle doubles
how often the segment sweeps past, so the user who asked for less movement
would receive twice as much of it. The indeterminate traversal therefore never
drops below its standard length. It also travels back and forth rather than
resetting, because a reset is an instant jump the full width of the track — the
sudden large movement that reduced motion exists to remove, and a visual
restart that suggests the operation itself began again.

## Accessibility

- **Named.** Both components refuse to build without a label. The label is
  announced when the user lands on the indicator, and again whenever the caller
  changes it.
- **Announced without flooding.** Progress reaches a screen reader through
  `IuxSemantics.liveRegion`, never `SemanticsService`. A live region makes
  TalkBack speak a whole phrase every time its text changes, so the announced
  value is throttled to milestones roughly ten points apart
  (`kIuxProgressAnnouncementStep`). The eye is never throttled: the visible
  number updates on every value the caller supplies. A phase change always
  announces, and so does reaching the end, because the last few percent are
  exactly the ones the user is waiting on.
- **Not colour alone.** The value is always present as text. The filled portion
  is held to 3:1 against both the track and the page (WCAG 2.2 SC 1.4.11), on
  all four theme profiles, and that is asserted in the tests rather than
  assumed.
- **Text scaling.** Works at 200%. The description and the value sit side by
  side until roughly 130% scaling and stack after that, rather than shrinking
  into each other. The description has no line limit and no ellipsis at any
  scale: `Uploading the photographs you sele…` tells the user less than
  nothing.
- **High contrast and enlarged text thicken the bar.** For the same reason
  high contrast thickens an outline — the shape has to survive a screen the
  user is already struggling to read, and someone who enlarged their text has
  said that four logical pixels are not enough.
- **RTL.** The fill grows from the reading start. A left-anchored bar in an
  Arabic interface reports progress running backwards.

**Verified in widget tests.** Still requires manual checking on device:
TalkBack reading order and announcement pacing during a real upload, Voice
Access naming, and whether the milestone step feels right at speed.

## Anti-patterns

```dart
// Wrong: the indicator is asked to own an outcome it cannot know.
if (progress.value == 1) showSuccessBanner();

// Right: the parent knows the operation finished and renders the result.
switch (state) {
  Loading() => IuxProgressIndicator(...),
  Done()    => resultView,
}
```

```dart
// Wrong: a spinner because a fraction was inconvenient to compute.
IuxLoadingIndicator(label: l10n.uploading)

// Right: the fraction exists; produce it.
IuxProgressIndicator(
  label: l10n.uploading,
  value: sent / total,
  valueLabel: l10n.bytesOf(sent, total),
)
```

```dart
// Wrong: a label that describes the widget rather than the work.
IuxLoadingIndicator(label: 'Loading…')

// Right: name the operation. It is what the user is waiting on.
IuxLoadingIndicator(label: l10n.searchingNearbyStores)
```

```dart
// Wrong: composing the value text in the framework's language.
valueLabel: '${(value * 100).round()}%'

// Right: it comes from the localisation layer, like every other string.
valueLabel: l10n.percentComplete((value * 100).round())
```

## Limits

- **Linear only.** There is no circular variant. A circular indicator has no
  room for a label beside it and is the shape most often shipped without one; a
  linear track sits above a status line naturally. A centred full-screen
  loading state is a pattern (Phase 3), and it composes this component rather
  than replacing it.
- **No elapsed time, no "this is taking longer than usual", no cancel.** All
  three need to know about the operation, which a component may not. They
  belong to an async pattern.
- **No buffered or secondary progress** — the "downloaded versus played" bar of
  a media player. No demonstrated need yet, and it would double the colour
  contract.
- **The unfilled track is low contrast against the page** on the standard
  profiles. What must be perceived is the boundary between filled and unfilled,
  and that is measured; the outer edge of the track is not, which makes the
  total extent easier to judge on high contrast than on standard. The visible
  value is what carries the information in every case.
- **TalkBack presents the determinate indicator as two stops** — the
  description, then the value. That is one swipe more than a single node, and
  it is the cost of being able to announce the value on its own without
  composing a sentence IUX has no right to compose.
- **Announcement pacing is a hypothesis.** Ten points is a judgement, not a
  measured optimum. It has not been validated with screen-reader users.

## Evidence level

| Claim | Level |
| --- | --- |
| Progress must be perceivable without motion | Standard — WCAG 2.2 SC 2.3.3, and IUX's own motion policy |
| The filled portion needs 3:1 | Standard — WCAG 2.2 SC 1.4.11 |
| Text must survive 200% scaling | Standard — WCAG 2.2 SC 1.4.4 |
| Determinate is preferable to indeterminate | Strong guidance — Nielsen Norman Group, Material |
| A live region rather than an announcement | Standard — Android deprecated `announceForAccessibility` |
| Ten-point announcement milestones | Hypothesis — needs validation with screen-reader users |
| Back-and-forth rather than a reset sweep | Context dependent |

## Sources

- WCAG 2.2 — SC 1.4.1, 1.4.4, 1.4.11, 2.2.1, 2.3.3, 4.1.3.
- Android accessibility guidance on live regions and the deprecation of
  `announceForAccessibility`.
- Nielsen Norman Group, on progress indicators and perceived wait.
- `docs/components/component-standard.md` §5, §6, §9, §11.
