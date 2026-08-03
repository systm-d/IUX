# Progressive disclosure

## Purpose

Let a page carry content most people do not need, without making everybody read
it — and without making the people who do need it fail to find it.

```dart
IuxProgressiveDisclosure(
  summary: l10n.advancedDeliveryOptions,
  state: state.deliveryDisclosure,           // required — the parent's
  onExpandedChanged: controller.setDeliveryDisclosed,
  child: const DeliveryOptionsFields(),      // any widget, controls included
)
```

## Hidden content is content nobody found

This is the whole argument of the pattern, so it comes before the API.

Progressive disclosure trades discoverability for calm. Every press is a
decision, and a user decides on the summary alone: if those words do not tell
them the answer is inside, they will not spend the press. So the trade is only
sound when what is hidden is **genuinely optional** — when a user who never
opens the section can still finish what they came to do.

Four things therefore never go behind a disclosure, whatever the layout
pressure:

| Never disclosed | Why |
| --- | --- |
| a required input | a form that cannot be completed without opening a panel is a form most people fail |
| an error, or what caused it | WCAG 2.2 SC 3.3.1 requires the error to be described **in text**; text behind a press is text this user has already proved they did not open |
| the way out — cancel, back, the primary action | the exit is the one control that must never need discovering |
| a cost, a consequence, or what is being agreed to | consent obtained from someone who did not read what was hidden is not consent |

**One of those four is enforced by a type. Three are not, and this page says
so rather than implying otherwise.** No widget can read a subtree and decide
whether it holds a required field, an exit or a price; anything claiming to
would be guessing, and a guarantee that is a guess is worse than none, because
reviewers stop looking.

What *is* enforced is the combination the caller declares themselves. Once the
parent says the content must be dealt with, there is exactly one state that says
it, and that state is open by construction:

```dart
// There is no fourth combination to write. Two booleans would have four,
// and one of them — collapsed while the content must be dealt with — is the
// defect this pattern exists to prevent.
const IuxDisclosureState.collapsed()
const IuxDisclosureState.expanded()
const IuxDisclosureState.heldOpen()   // shown, and the toggle is gone
```

## Why this is not `IuxContextualHelp`, and what should change about that

IUX-018 already shipped a disclosure control. It is in the page flow, it
announces its expanded state, and the runtime gained `IuxSemantics.action`'s
`expanded` parameter for it. It was read before a line of this was written, and
most of what is right here was decided there.

The two are not variants of each other, and the difference is not length:

| | What is behind the control | What it is for |
| --- | --- | --- |
| `IuxContextualHelp` | a `String`, and no control may be in it | **explaining** something on the page |
| `IuxProgressiveDisclosure` | any widget, controls included | **being** part of the page |

That single difference is where everything specific to this pattern comes from.
Prose has no focus order, cannot be reached by tab, cannot be left half-filled,
and cannot be reached by a screen reader as anything but text. A revealed form
section is all four. So this pattern owes guarantees that a prose panel never
did — that hidden controls are truly gone, that revealed controls are the next
focus stop, that closing takes them back out — and it owes them by measurement,
not by assertion. See "Hidden means absent" below.

Everything that is *not* specific — the expanded state on the control's own
node, the chevron as a shape rather than a hue, the parent owning whether it is
open, the refusal to animate — is IUX-018's reasoning, reused rather than
re-argued.

### The verdict on generalising it

**Yes for the control; no for the component.**

`IuxContextualHelp` should keep existing. It is the constrained preset, and the
constraint is the value: refusing a widget slot is what stops a help panel
becoming a destination with a focus order and a way back. Deleting it in favour
of the general form would delete that refusal, and this library builds
constrained presets on purpose — `IuxRetryRoute` over `IuxRecoveryRoute`,
`IuxNoMatches` over a generic empty state.

**But the disclosure control itself should exist once, and currently exists
twice.** `_IuxHelpDisclosureControl` is private to
`lib/src/components/help/iux_contextual_help.dart`, written before there was a
pattern layer to put it in. Structurally it is this pattern's
`_IuxDisclosureControl` plus a leading help glyph: the same
`IuxSemantics.action(expanded:)` wrapper, the same `IuxFocusable`, the same
opaque `GestureDetector`, the same `ConstrainedBox` floor, the same trailing
chevron, and the same decision to hide both glyphs from assistive technology.

The right end state is that `IuxContextualHelp` composes this pattern and adds
its glyph and its prose panel. That is one parameter's worth of change — a
leading-glyph slot on the shared control — and it is **not made here**: IUX-035
does not own `lib/src/components/help/`. It is reported rather than done, and
the leading-glyph slot is deliberately *not* pre-added to this pattern, because
a parameter with no caller is dead public API (`PROJECT_PROMPT.md` §19).

Until that refactor happens, the risk is drift: a fix to the announced state in
one control that does not reach the other. Both are covered by tests that probe
the real semantics tree, so drift shows up as a failure rather than as a
difference nobody noticed.

## Accordion exclusivity is not offered, and cannot be

There is no `IuxDisclosureGroup`, no `exclusive` flag, and no group widget of
any kind. Three reasons, in order of how badly each alternative fails:

1. **Exclusivity closes content the user just found.** Opening section three
   closes section one, which the user opened deliberately thirty seconds ago
   and may still be reading. The interface has undone a decision the user made,
   for a reason they cannot see. That is expensive on a small screen — the
   place accordions are usually reached for — because closing a section
   above the fold moves everything under the user's thumb.
2. **A group widget that only stacks would be dead public API.** Once
   exclusivity is refused, a group has nothing left to coordinate: laying
   sections out is `Column`, `IuxSection` and `IuxContentGroup`, all shipped.
   Adding a fourth way to stack widgets to justify a directory would be exactly
   the specialisation `PROJECT_PROMPT.md` §30 forbids.
3. **The parent already owns the state, so exclusivity is theirs and it is one
   line.** An application that genuinely wants it replaces its open set with a
   singleton. Nothing here has to know, and — the point — nothing here has to
   guess *which* section should close when the answer depends on what the user
   was doing.

`IuxContextualHelp` reached the same conclusion from the other side and wrote it
in its own limitations: "an application that wants accordion behaviour writes it
in the parent, where it belongs."

## Hidden means absent

A collapsed disclosure does not build its `child`.

Not `Offstage`, not `Visibility(maintainState: true)`, not `Opacity(opacity: 0)`,
not a zero-height `ClipRect`. Every one of those leaves the content mounted,
which leaves its controls in the focus order and its nodes in the semantics
tree — and every one of them looks perfectly correct on screen, which is why
this is the defect the pattern was most likely to ship.

What that costs the user, concretely: a keyboard user tabs into a section they
cannot see and lands on a control they cannot read; a screen-reader user swipes
onto a button that is not there. Both are worse than the content being
unavailable, because the interface has told them it exists and refused to show
it.

Three probes hold the guarantee, and all three ask the framework rather than
the widget:

```dart
// nothing hiding-but-mounted anywhere in this pattern's subtree
find.descendant(of: find.byType(IuxProgressiveDisclosure), matching: find.byType(Offstage))

// not in the semantics tree
find.bySemanticsLabel('Choose a neighbour')          // findsNothing when closed

// not in the focus order — asked of the manager, because FocusNode.context
// keeps pointing at a defunct element after an unmount and answers a
// different question
FocusManager.instance.rootScope.descendants.contains(innerNode)
```

**The consequence, stated plainly: revealed content is built fresh.** A scroll
position, a half-typed field, a controller's transient state — anything living
inside `child` rather than above it is discarded when the section closes. Hoist
it, exactly as you would out of any other conditional subtree.

## Focus does not move, and here is the measurement

**Decision: opening a section leaves focus on the control the user pressed.**

Four missions have answered this question and none of them answered it the same
way, because none of them was describing the same moment:

| | What the user had just done | Decision |
| --- | --- | --- |
| IUX-012 `IuxValidationSummary` | pressed submit, waiting for an answer | **move** focus to the summary |
| IUX-028 `IuxEmptyState` | typing in a search field | do not move |
| IUX-029 `IuxErrorRecovery` | anything, possibly nothing | do not move |
| IUX-030 `IuxLoadingRetry` | anything, possibly nothing | do not move |
| **IUX-035, here** | pressed this control, asking for this content | **do not move** |

The line is not "did the user ask for it". IUX-012's user asked too. The line is
whether the answer to what they asked is somewhere they cannot get to. A refused
submission puts its explanation at the top of a long form, past content the user
would have to hunt back through. A revealed section puts its content *in the
very next node*: a screen reader's next swipe reaches it, a keyboard's next tab
reaches it, and the platform has already spoken the state change on the node the
user is standing on.

Moving focus would cost more than it bought. It would carry a keyboard user past
the control they may want to press again. It would land a screen-reader user
*inside* a region without their having heard what the region was. And closing
the section would then have to move focus back out of content that is about to
stop existing — two interruptions where the user asked for none.

Measured, not asserted:

- focus is on the control before the press and on the control after it;
- the same on close;
- `control.nextFocus()` lands on the first control inside the revealed content;
- `control.nextFocus()` does not reach it while the section is closed.

**This only holds because the content is adjacent**, which is why there is no
way to reveal content anywhere else. Flutter's semantics have no equivalent of
`aria-controls`: adjacency in the tree is the entire association between this
control and what it opens, so the pattern refuses to break it.

## `IuxDisclosureHeldOpen`, and why the toggle disappears

When the parent says the content must be dealt with, the summary stops being a
button and becomes a heading. It keeps its wording, its place, its type and its
height; it loses the chevron and the tap action, and gains a heading landmark a
screen reader can jump to.

Three worse answers were available:

- **Keep the toggle and ignore the press.** The node still announces "expanded,
  button"; a screen-reader user double-taps it and nothing happens. A control
  that lies about what it does is worse than no control.
- **Disable it.** On Android a disabled control leaves the focus order, so it is
  announced as unavailable to users who reach it and is invisible to users who
  navigate by focus. Neither group is told why.
- **Let the parent refuse the callback.** This *is* honest for a panel that
  never opens, and `IuxContextualHelp` relies on it. The failure here has the
  opposite shape: the user asks for **less**, and the interface silently keeps
  showing more. That reads as a stuck screen, not as a refusal.

**It carries no message.** Why the section is held open is already inside it —
the rejected field shows its own error, and `IuxValidationSummary` names the
failure at the top of the form. A second sentence on the summary line would be a
second error vocabulary, the mistake this library keeps declining to make.

**It is a moment, not a mode.** A section that is *always* held open is not a
disclosure: it is a titled block, and `IuxSection` draws one without pretending
anything was ever hideable.

### What it costs, measured

A control disappearing under a user is a real cost and it is not waved away.

When the toggle held focus at the moment of the flip, Flutter hands focus back
to the nearest enclosing `FocusScopeNode` — pinned in the tests, and the same
behaviour IUX-030 measured when a retry control unmounted. The keyboard user
then tabs from the scope rather than from where they were.

Two things keep it small, and neither is a fix:

- the flow this state exists for is a refused submission, and IUX-012 has
  already moved focus to the validation summary by then, so the toggle is not
  usually the node holding focus;
- the summary line keeps its minimum height and its reserved focus-ring inset,
  so the content below does not shift when the toggle becomes a heading —
  asserted by comparing the content's `dy` across the transition.

The remaining guidance is for the parent: **flip to `heldOpen` at a moment the
user expects** — a submission, a mode change they made — and not on every
keystroke of a live validator. A collapsed section springing open mid-typing is
a layout jump the user did not ask for at a point they were not looking.

## Nothing animates, and there is no parameter to add one

IUX-018 reached this first for its help panel. The argument only gets stronger
with arbitrary content:

- an in-flow reveal moves everything below it **while it runs**, which is the
  motion a vestibular user objects to — and this `child` can be a whole form
  section, so the displacement is larger and lasts longer than a paragraph's;
- it delays content for someone who has just asked for it;
- the change happens at the point the user pressed, so "what just changed" is
  already answered;
- an animation that does not exist cannot take information with it when a
  preference removes it.

Two more apply here and not there. This `child` may contain **controls**, and
animating a reveal means a control whose hit box travels while the user reaches
for it. And a reveal interrupted by a second press would leave the semantics
tree mid-flight, announcing a region that is neither open nor closed.

So there is no `AnimatedSize`, no `AnimatedCrossFade`, and no duration
parameter. `lib/src/patterns/disclosure/` imports the motion policy nowhere.

**WCAG 2.2 SC 2.3.3 (Animation from Interactions) is satisfied by there being no
animation to disable**, rather than by a preference check that could be got
wrong — and the tests prove the absence rather than describe it: after the press
the content is complete on the **next single frame**, with
`tester.binding.transientCallbackCount` at zero. The same is re-run under
`IuxMotionPreference.none`, where it is necessarily also true, so a future
regression that adds a ticker fails in both.

## API

```dart
IuxProgressiveDisclosure(
  summary: l10n.advancedDeliveryOptions,   // required, localised, non-empty
  state: state.disclosure,                 // required — the parent's
  onExpandedChanged: controller.set,       // required
  child: const AdvancedFields(),           // required, any widget
  focusNode: null,                         // optional
)
```

| Type | What it is |
| --- | --- |
| `IuxProgressiveDisclosure` | a named control and the content it reveals, in the page |
| `IuxDisclosureState` | sealed: what the section is doing, and whether it may stop |
| `IuxDisclosureCollapsed` | hidden, and the user may reveal it |
| `IuxDisclosureExpanded` | shown at the user's request, and may be hidden again |
| `IuxDisclosureHeldOpen` | shown, and the toggle is gone |

There is no colour, radius, elevation, duration, icon or padding parameter, and
there will not be one. There is no `IuxProgressiveDisclosureTheme` and no public
token class either: the two decisions a token class would hold — which type role
the summary uses and how tall the row is — are not decisions an application can
vary without breaking the guarantee attached to them, and a token class nobody
outside calls is public API with no caller.

The barrel exports are added by whoever integrates the mission; IUX-035 does not
own `lib/iux_flutter.dart`.

**`summary` is both the visible text and the accessible name.** A disclosure has
nothing to say to one audience it should hide from the other. Name the content,
never the gesture: "Delivery options", not "More" and not "Show". A user
deciding whether to spend a press decides on these words alone, and "More" gives
them nothing to decide with — it is also, to a screen-reader user moving between
them, the same control as every other one in the application called "More".

**`state` is required and there is no `initiallyExpanded`.** A form that must
open the section holding a rejected field can only do that if the state lives
outside the widget, and a component that owned it would be a component whose
state the parent cannot read — the defect component standard §3 exists to
prevent.

**`onExpandedChanged` is required even though `heldOpen` never calls it.** A
disclosure that is always held open is not a disclosure, and asking for the
callback is what makes that obvious at the call site rather than in production.

## States

| State | Source |
| --- | --- |
| collapsed / expanded | `state` — the parent's |
| held open | `state` — the parent's, and the toggle is not rendered |
| focused | the runtime focus ring, drawn outside the control |
| pressed | no distinct appearance; the content appearing is the feedback |

There is **no disabled, loading or error state.** A disclosure is not an
operation: it does not run, cannot be unavailable, and reports no failure of its
own. Content that is not ready to be revealed is content the section should not
be offering yet — and an error *inside* the content is what `heldOpen` is for,
not a state of the disclosure.

## Accessibility

- **The control announces name, button role and open state on one node.** Probed
  with `tester.getSemantics`, checking `label`, `flagsCollection.isButton` and
  `flagsCollection.isExpanded` on the same node, in both states. A separate node
  carrying the state would be a fragment the user meets somewhere else, or not
  at all.
- **Collapsed is `Tristate.isFalse`, not absent.** The platform is told the
  control *has* an open state, which is what lets it say "collapsed" before the
  user presses — the announcement that makes a disclosure usable without opening
  it. (WCAG 2.2 SC 4.1.2.)
- **Held open is `Tristate.none`, not `isTrue`.** A heading has no open state;
  announcing one permanently true would invite the user to look for a way to
  close it that does not exist.
- **A screen-reader activation works.** `SemanticsAction.tap` is performed
  directly on the node, which is the closest a widget test gets to TalkBack's
  double-tap, and the parent receives the request. This is the failure mode
  `test/accessibility/announced_controls_test.dart` exists for: a node announced
  as a button with nothing to activate.
- **The chevron is a shape, not a hue.** Direction survives a monochrome screen,
  a colour-vision deficiency and a black-and-white printout. It is excluded from
  the semantic tree, because the state is already on the node where the platform
  speaks it in the user's own language.
- **The revealed region is not a live region.** The user pressed the control,
  the platform announced the state change, and the content is the next thing in
  the reading order. Announcing it as well would interrupt them to repeat
  something they are already on their way to.
- **Target.** The row meets `IuxAccessibility.minimumTouchTarget`, and a
  comfortable target preference raises it. The words and the chevron stay the
  size of the text around them: the interactive region and the visual element
  are different measurements.
- **Keyboard and D-pad.** `Enter` and `Space` both activate, through
  `IuxFocusable`. Asserted without a pointer.
- **Text scaling.** Works at 200% on a 320-pixel screen. A long summary wraps —
  no `maxLines`, no ellipsis — because a truncated summary is a summary the user
  cannot decide on, which is the one thing this control has to let them do. The
  chevron scales through the runtime, once, so it grows at the same rate as the
  words beside it rather than twice as fast.
- **RTL.** The row is a plain `Row`; nothing here knows which direction the page
  reads in. Asserted by measuring that the chevron sits on the left of the
  summary under `TextDirection.rtl`, and that the control still opens.
- **Contrast.** The summary and the chevron are held to 4.5:1 against the page
  on all four theme profiles — the *text* ratio rather than the 3:1 non-text
  one, because the chevron sits inside a control's label and is read alongside
  it. Measured on the `TextStyle` and `Icon` actually painted, not on what a
  resolver returns; the two can drift and only one of them reaches a user.

**Manual validation still required**, and a widget test cannot stand in for it:
that TalkBack speaks the collapsed/expanded state the way this document assumes;
that it announces the heading landmark under `heldOpen`; that Voice Access can
address the control by its summary; and that a physical keyboard and a D-pad
both reach the revealed controls in the order the tests predict.

## Themes and tokens

Everything is resolved from the theme. The summary takes
`IuxTypographyTheme.label` over `content.primary` — the same role
`IuxContextualHelp` gives its question, because two controls that do the same
thing set in different type are two things as far as the reader is concerned.
The chevron takes `content.primary` at the shared 20-pixel glyph size, scaled
through `IuxAccessibility.scaleText`. Spacing is `spacingXxs` and `spacingXs`;
the floor is `IuxGeometryTheme.minimumTouchTarget`.

No colour literal, no `MediaQuery`, no hardcoded duration, no `Color` parameter.
`test/components/component_standard_test.dart` enforces the mechanical half of
that over `lib/src/patterns/`.

## Anti-patterns

```dart
// Wrong: a required field behind a press. Most people never open it, and the
// form refuses them without ever having shown them what it wanted.
IuxProgressiveDisclosure(
  summary: l10n.billingAddress,
  child: RequiredBillingFields(),
  ...
)

// Right: it is on the page. Optional refinements may be disclosed; the thing
// the form cannot be submitted without may not.
Column(children: <Widget>[
  const RequiredBillingFields(),
  IuxProgressiveDisclosure(
    summary: l10n.deliveryPreferences,
    child: const OptionalPreferences(),
    ...
  ),
])
```

```dart
// Wrong: the summary names the gesture. The user has nothing to decide with,
// and a screen-reader user moving between three of these hears one control.
IuxProgressiveDisclosure(summary: l10n.showMore, ...)

// Right: the summary names the content.
IuxProgressiveDisclosure(summary: l10n.deliveryOptions, ...)
```

```dart
// Wrong: a paragraph of explanation, in the pattern that allows controls.
// Nothing stops it, and it gives up the one guarantee IuxContextualHelp has —
// that a help panel can never become a destination with a focus order.
IuxProgressiveDisclosure(
  summary: l10n.whatIsASortCode,
  child: Text(l10n.sortCodeExplanation),
  ...
)

// Right.
IuxContextualHelp(
  label: l10n.whatIsASortCode,
  help: l10n.sortCodeExplanation,
  expanded: state.open,
  onExpandedChanged: controller.toggle,
)
```

```dart
// Wrong: the parent hides the section again while its content is rejected.
// This does not compile — there is no collapsed state that carries a problem,
// and heldOpen is open by construction.
IuxDisclosureCollapsed(hasError: true)

// Right.
state = const IuxDisclosureState.heldOpen();
```

## Limits

- **Only one of the four "never disclosed" rules is enforced.** Required
  inputs, exits and costs are documentation. Nothing inspects the subtree, and
  nothing can.
- **A collapsed section is unmounted, so state inside it is lost.** Hoist any
  state that must survive a close. This is the price of the guarantee, not an
  oversight.
- **Revealing is eager.** A section holding two hundred rows builds two hundred
  rows the moment it opens. Lazy lists are `IuxListGroup`'s problem.
- **The disclosure control is implemented twice in this library.** See the
  verdict above. `IuxContextualHelp` should compose this pattern; that change
  belongs to whoever owns `lib/src/components/help/`.
- **Flipping to `heldOpen` while the toggle has focus loses the user's place.**
  Measured and pinned; the mitigation is a parent that flips at a moment the
  user expects.
- **Nothing scrolls itself.** The revealed content sits in the flow, so a long
  section at 200% text grows past the bottom of the screen and the *page* must
  scroll. Place it inside a scrollable, which is where a form lives anyway; a
  component that scrolled internally would be a second scrollable inside the
  page's, which is worse.
- **No group, no accordion, no coordination.** Argued above. Several
  disclosures on one screen can all be open at once, because the parent owns
  each state separately.
- **Nothing checks that the summary is honest.** Whether "Delivery options"
  describes what is actually inside is a judgement no test can make. The
  framework enforces that a summary exists and is not empty, which is what stops
  the failure being total.
- **Widget tests approximate a screen reader and no more.** Whether TalkBack
  speaks the expanded state, and how, needs a device.

## Evidence level

| Claim | Level |
| --- | --- |
| A disclosure control must expose its expanded state programmatically | **Standard** — WCAG 2.2 SC 4.1.2 |
| An error must be identified and described in text | **Standard** — WCAG 2.2 SC 3.3.1 |
| Hidden content must not remain focusable or readable by assistive technology | **Standard** — WCAG 2.2 SC 1.3.2, 2.4.3, 4.1.2 |
| Everything reachable and activatable without a pointer | **Standard** — WCAG 2.2 SC 2.1.1 |
| The control meets the touch-target floor | **Standard** — WCAG 2.2 SC 2.5.8, Android guidance |
| Text survives 200% scaling without clipping | **Standard** — WCAG 2.2 SC 1.4.4 |
| Summary at 4.5:1, chevron at the text ratio | **Standard** — WCAG 2.2 SC 1.4.3, 1.4.11 |
| Motion from an interaction must be disableable | **Standard** — WCAG 2.2 SC 2.3.3, met by having none |
| Progressive disclosure for content a minority needs | **Strong guidance** — Nielsen Norman Group on progressive disclosure |
| A summary must name the content, not the gesture | **Strong guidance** — NN/g on link and control labelling |
| Not moving focus into revealed content | **Context dependent** — reasoned from adjacency and from IUX-012/028/029/030; the reasoning is stated, it has not been user-tested |
| Refusing accordion exclusivity outright | **Context dependent** — IUX's reading; Material and most design systems offer it |
| Removing the toggle rather than disabling or ignoring it under `heldOpen` | **Context dependent** — the three alternatives and their failures are stated above; not user-tested |
| Refusing to animate the reveal | **Context dependent** — IUX-018's argument, extended; not user-tested |
| That a user decides on the summary alone and will not press a vague one | **Hypothesis** — consistent with NN/g's findings on labelling, not measured here |

## Sources

- WCAG 2.2 — SC 1.3.2, 1.4.3, 1.4.4, 1.4.11, 2.1.1, 2.3.3, 2.4.3, 2.4.7, 2.5.8,
  3.3.1, 4.1.2.
- Android accessibility guidance on touch targets and on state announcement.
- Nielsen Norman Group, on progressive disclosure and on control labelling.
- `docs/components/contextual-help.md` — IUX-018, where the disclosure control
  and most of its reasoning were first written.
- `docs/patterns/guided-form.md` — IUX-012, the one pattern in this library that
  moves focus, and why.
- `docs/patterns/empty-state.md`, `docs/patterns/error-recovery.md`,
  `docs/patterns/loading-and-retry.md` — IUX-028, IUX-029, IUX-030, the three
  that do not.
- `docs/components/component-standard.md` §2, §3, §5, §6, §7, §9, §11.
- `PROJECT_PROMPT.md` §5, §19, §22, §23, §30.
