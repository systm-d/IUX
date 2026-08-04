# IuxTooltip and IuxContextualHelp

## Purpose

Explain a control to the people who need it explained, without punishing the
people who do not.

```dart
// A glyph that not everyone will recognise.
IuxTooltip(
  message: l10n.archiveThisConversation,
  child: IuxIconButton(
    icon: Icons.archive_outlined,
    action: const IuxActionDescriptor(
      semantics: IuxActionSemantics(label: 'Archive'),
    ),
    onActivate: controller.archive,
  ),
)

// A question some users will have and most will not.
IuxContextualHelp(
  label: l10n.whatIsASortCode,
  help: l10n.sortCodeExplanation,
  expanded: state.sortCodeHelpOpen,
  onExpandedChanged: controller.toggleSortCodeHelp,
)
```

`IuxIconButton` documents its own limitation: "no tooltip: a sighted user must
still recognise the glyph". This page is the answer to that sentence, and it is
also the answer to why the answer is not simply "add a tooltip".

## The rule

**A tooltip is never the only place information exists.**

Everything below follows from that. A tooltip is reached by hovering, by
holding, or by moving keyboard focus, and each of those routes loses somebody:

- **hover does not exist on a phone.** Android is this framework's primary
  platform. Content that only appears on hover is invisible to every user of it,
  which is most users.
- **long-press is not discoverable.** Nothing on screen says the gesture is
  available. A user who does not already know it will not find out, and the
  failure is silent.
- **a screen-reader user does not move Flutter focus** by swiping through a
  page, so a focus-triggered reveal does not happen for them at all.
- **a user with a motor impairment** may not be able to hold a press steady for
  the length of a long press, or to keep a pointer still over a target.

So the accessible **name** carries the meaning and the tooltip **elaborates**.
`IuxIconButton` already makes the missing-name case unrepresentable —
`IuxActionSemantics.label` is required and non-empty — which is what makes
attaching a tooltip to one safe.

The test to apply before writing one:

> If this user never saw the tooltip at all, can they still identify the control
> and complete the task?

If the answer is no, the words belong in the control's name, in visible help, or
in an `IuxContextualHelp`. Not here.

## Where help goes: three answers, and how to choose

| The user | Where it belongs | What it costs |
| --- | --- | --- |
| needs it in order to answer at all | **always visible** — `IuxInputDescriptor.helpText` | vertical space, on every screen, for every user |
| may need it, and can ask | **`IuxContextualHelp`** | one press, and only for the people who press |
| already knows what to do but not what this glyph means | **`IuxTooltip`** | nothing — and it reaches nobody who does not hover, hold or focus |

The distinction is not length and it is not tone. It is **what happens to the
user who never sees it.**

**Inline, always visible.** `IuxTextField` shows `IuxInputDescriptor.helpText`
under the field, permanently, where a screen reader meets it immediately after
the field. That is the right place for "we ask for this to verify your identity"
or "eight characters or more" — instructions everyone needs. Disclosure would be
a way of hiding required instructions behind a press most people never make. It
also never swaps places with the validation message: both are shown, because
removing the sentence explaining how to write a correct value at the exact
moment the user has proved they need it is a strange thing to do. (Anything that
must be part of the field's *own* announcement rather than the line after it
belongs in `IuxInputSemantics.hint`, which is a different slot for a different
reason.)

**Behind a control.** `IuxContextualHelp` is for the explanation a minority
wants: what a sort code *is*, why a date of birth is being asked for, what
happens after the form is submitted. Putting it on screen for everybody would
add a paragraph to a form that most people can already complete, and a form
nobody reads is a form nobody reads carefully.

**Floating.** `IuxTooltip` is the smallest of the three and the only one that is
allowed to reach nobody. It exists for icon-only controls, where there is
physically no room for a label and the glyph is doing the work.

## The tooltip / help-panel boundary, and where it is drawn

The boundary is enforced, not advised. `IuxTooltip` refuses:

- a message longer than `kIuxTooltipMaximumCharacters` (**80**, counted in
  runes, so an emoji is one character);
- a message containing a line break.

Both are asserted. A ceiling written in a document has never once kept a tooltip
short.

**Why 80.** That is roughly two lines at the default text size on a phone, and
four to five lines at 200% text on a 320-pixel screen — already at the edge of
what may reasonably float over a page. The exact figure is a judgement. What is
not a judgement is that *some* ceiling has to exist, because a floating box is
the worst reading surface in the library:

- it cannot be scrolled, so anything taller than the screen is simply lost;
- it cannot be kept open while the user does something else, so it cannot be
  referred back to;
- it covers the page it is explaining;
- it is reached only by the three routes above, none of which is universal.

`IuxContextualHelp` has none of those problems. It sits **in the page flow**, so
it scrolls with the page, wraps at any text size, stays open until the user
closes it, and never covers anything. The cost is layout: opening a panel moves
everything below it. That trade is made deliberately — content that moves is
recoverable, content that is clipped is not.

**A line break is refused for the same reason a length is.** Two lines means two
thoughts, and the second thought is already more than a box the user cannot
scroll or keep open should be carrying.

## API

```dart
IuxTooltip(
  message: l10n.archiveThisConversation,   // required, localised, ≤ 80, one line
  child: control,                          // required, exactly one named control
)

IuxTooltip.isWithinBounds(String message)  // the same check, callable

IuxContextualHelp(
  label: l10n.whatIsASortCode,             // required, localised
  help: l10n.sortCodeExplanation,          // required, localised
  expanded: state.open,                    // required — the parent's
  onExpandedChanged: controller.toggle,    // required
  focusNode: null,                         // optional
)
```

| Type | What it is |
| --- | --- |
| `IuxTooltip` | a short elaboration attached to one control |
| `kIuxTooltipMaximumCharacters` | the enforced boundary between the two components |
| `IuxTooltipTokens` / `IuxTooltipResolver` | the resolved appearance |
| `IuxContextualHelp` | a named control and the panel it discloses, in the page |
| `IuxContextualHelpTokens` / `IuxContextualHelpResolver` | the resolved appearance |

There is no colour, radius, elevation, offset or duration parameter, and there
will not be one. There is no `IuxTooltipTheme` and no `IuxContextualHelpTheme`
either: neither component has a decision an application could usefully vary that
the semantic palette, geometry and typography do not already carry.

**There is no `showDuration` and no `waitDuration`.** See below.

**`help` is a `String`, not a `Widget`.** The panel then keeps the typography and
the measured contrast the theme is responsible for. Paragraphs are separated by
blank lines in the string. Help that needs a control inside it — a link, a
button, a form — is not contextual help; it is a destination, and it belongs on
a screen of its own where the user can find their way back.

**`label` is both the visible text and the accessible name.** A help control has
nothing to say to one audience that it should hide from the other. Write a
question or a subject — "What is a sort code?" — not "Help": every control in an
application labelled "Help" is the same control as far as a screen-reader user
moving between them can tell.

## The parent owns whether the panel is open

`expanded` and `onExpandedChanged` are required, and there is no internal
fallback and no `initiallyExpanded`.

A form that wants to open the panel explaining the rule a value has just broken
can only do that if the state lives outside the widget. And a component that
owned it would be a component whose state the parent cannot read, which is the
defect the component standard §3 exists to prevent. A parent that ignores the
callback gets a panel that never opens — which is honest, and visible
immediately.

`IuxTooltip` is the exception, and deliberately: whether a tooltip is up is
interaction state belonging to one instance and to nothing else, in the same way
that press and hover stay inside `IuxButton`. No parent has a reason to know,
and giving it one would put a tooltip in every state class in the application.

## WCAG 2.2 SC 1.4.13, satisfied rather than approximated

The criterion governs content shown on hover or focus. It requires three things,
and most tooltip implementations fail the third.

**Dismissable** — "a mechanism is available to dismiss the additional content
without moving pointer hover or focus".

- `Escape` closes it while the pointer stays where it is and focus stays where it
  is. This is the technique the criterion names.
- A press anywhere outside closes it. `TapRegion` **reports** the press rather
  than consuming it, so whatever the user was reaching for still receives it:
  dismissing costs no gesture.
- Pressing the control again closes it — the way out a touch user finds first,
  because it is where their finger already is.
- Touching the tooltip itself closes it.

**Hoverable** — "the pointer can be moved over the additional content without it
disappearing".

The tooltip's mouse region extends across the gap that separates it from its
anchor, so the pointer travels onto the tooltip without ever crossing a dead
zone. The decision to close is also deferred to the end of the pointer event
rather than taken on the spot: moving from anchor to tooltip produces an exit
and an enter in the same dispatch, exits first, and acting on the exit
immediately would close the tooltip on the way to being read.

**Persistent** — "the content remains visible until the hover or focus trigger
is removed, the user dismisses it, or it is no longer valid".

**There is no clock.** No `showDuration`, no auto-hide, no way to add one. A
tooltip that vanishes while it is being read fails this criterion, and the only
way to be certain it cannot is to have nothing that counts. It stays until the
user dismisses it, focus leaves, or the pointer leaves both the anchor and the
tooltip.

## Reaching it without hover

| Input | How the tooltip is reached |
| --- | --- |
| touch | long-press the control |
| keyboard / D-pad | move focus to the control |
| pointer | hover the control |
| screen reader | the control's own accessible name — plus the message, and the long-press action, on the same node |

**The long press competes fairly.** It shares the gesture arena with the
control's own tap recogniser and wins only after the press deadline, so a quick
tap still activates the control and never opens a tooltip. Losing that
competition either way would be a defect: a tooltip on every tap, or a control
that stopped responding.

**The tooltip never takes focus.** Moving focus onto something that appears
uninvited and cannot be navigated back from strands the user it moved.

## Accessibility

### IuxTooltip

- **The message and the control's name are on one semantic node.** Left
  unmerged, Flutter puts the tooltip property on a wrapper *above* the control
  and the long-press action on another wrapper above that, while a screen reader
  lands on the control itself — so the message reaches nobody and the gesture
  cannot be triggered. `MergeSemantics` collapses them: the user meets one stop
  carrying the name, the role, the message and the gesture together. **This is
  why `child` must be exactly one control**; wrap a row of them and they collapse
  into a single announcement, which the widget cannot detect.
- **The floating box itself is excluded from the semantic tree.** The message is
  already on the control's node, where it is met in place. Repeated in the
  overlay it would appear as a loose fragment somewhere else in the reading
  order, arriving and leaving for reasons that user cannot perceive.
- **Measured against the surface it sits on.** Text is held to 4.5:1 against the
  tooltip's own surface and the outline to 3:1 against the page, on all four
  theme profiles. Asserted in the tests, not assumed.
- **Outlined, not elevated.** A shadow resolves to zero under a reduced visual
  stimulation preference, and the edge of something floating over arbitrary
  content is not a thing that may quietly disappear. The outline uses the
  theme's *strong* width, like the transient message and for the same reason.
- **It stays on the screen.** Positioning flips to the other side of the control
  when the preferred one does not fit, and never crosses the screen margin. That
  is what keeps the tooltip of a trailing app-bar icon on screen, which is the
  single most common place a tooltip is put and the single most common place one
  is clipped.
- **It follows its control.** The position is recomputed from the anchor's paint
  transform on every layout, so a page scrolling underneath does not leave a
  tooltip pointing at nothing.
- **Text scaling.** No line limit and no ellipsis at any size. The width cap is
  expressed in characters, so enlarging the text widens the box instead of
  squeezing the same words into a narrower column — bounded by the screen, which
  always wins.
- **RTL.** Nothing here knows which direction the page reads in; the layout is
  computed from the anchor and the screen.

### IuxContextualHelp

- **The control announces that it is a disclosure and whether it is open.** The
  semantic node carries name, button role, tap action and expanded state, so a
  screen-reader user is told there is something to open before they open it, and
  told the state changed after they did.
- **It also announces the focus it holds.** The node reports a real focus state
  and offers `SemanticsAction.focus`, naming the same focus node the control
  itself holds, so assistive technology can move accessibility focus here
  rather than only reach it by swiping. It reported `Tristate.none` with
  `actions: [tap]` until IUX-A11Y-FOCUS-001 was fixed at every call site.
- **The same state is carried visually by a chevron's direction** — a shape, not
  a hue, so it survives a monochrome screen, a colour-vision deficiency and a
  screenshot printed in black and white.
- **The glyphs are excluded from the semantic tree.** Both repeat what the node
  already carries, and the platform speaks that in the user's own language
  rather than as a shape they would have to decode.
- **The panel is not a live region.** The user has just pressed the control, the
  platform announces the state change, and the text is the next thing in the
  reading order. Announcing it as well would interrupt them to repeat something
  they are already on their way to.
- **Target.** The control meets the resolved touch target floor, and a
  comfortable target preference raises it. The glyphs and the label stay the size
  of the text around them: the interactive region and the visual element are
  different measurements.
- **Text scaling.** Works at 200% on a 320-pixel screen. A long question wraps
  rather than truncating — a truncated question is a question the user cannot
  decide whether to ask.
- **Contrast.** The question is held to 4.5:1 against the page, the answer to
  4.5:1 against the panel, and the glyphs to the *text* ratio rather than the
  3:1 non-text one, because they sit inside a control's label and are read
  alongside it. Asserted on all four profiles.

**Verified in widget tests.** Still needs a device: whether TalkBack's
double-tap-and-hold reliably reaches the long-press action on a real handset,
whether Voice Access can name an icon-only control by its tooltip, and whether
the disclosure's expanded state is spoken the way this document assumes.

## States

| State | Source |
| --- | --- |
| tooltip shown / hidden | the component's, driven by long press, hover and focus |
| tooltip dismissed | the user's: Escape, a press outside, a press on the control, a press on the tooltip |
| tooltip above / below its control | derived from the room available |
| help open / closed | `expanded` — the parent's |
| help control focused | the runtime focus ring, drawn outside the control |
| help control pressed | no distinct appearance; the panel opening is the feedback |

Neither component has a loading, disabled or error state. Help is not an
operation: it does not run, cannot be unavailable, and reports no failure of its
own. A control that should not be pressed yet is a control that should not have
help attached to it yet.

## Motion

**The tooltip fades in**, declared as `IuxMotionRole.enter` at the short scale,
so a reduced-motion preference shortens it and `IuxMotionPreference.none`
removes it entirely — set to fully opaque on the first frame rather than
animated over zero time, because an animation that "runs" for no time still
leaves one frame at zero opacity, and a box that flickers is worse than one that
simply appears. Nothing is lost either way: the fade never carried the message.

**A fade, and no travel.** Travel across the screen is a known vestibular
trigger, and a tooltip arriving beside the control the user just touched has
nowhere informative to travel from.

**The help panel does not animate at all**, and that is a decision rather than an
omission:

- an in-flow reveal moves everything below it *while it runs*, which is exactly
  the motion a vestibular user objects to;
- it delays help by up to a few hundred milliseconds for someone who has just
  asked for it;
- the change happens at the point the user pressed, so "what just changed" is
  already answered;
- an animation that does not exist cannot take information with it when a
  preference removes it.

## Anti-patterns

```dart
// Wrong: the name lives only in the tooltip. Every touch user who does not
// know about long press, and every screen-reader user, gets an unnamed button.
IuxTooltip(
  message: l10n.archive,
  child: IuxIconButton(
    icon: Icons.archive_outlined,
    action: const IuxActionDescriptor(
      semantics: IuxActionSemantics(label: 'Button'),   // meaningless
    ),
    onActivate: controller.archive,
  ),
)

// Right: the name identifies the control; the tooltip elaborates.
IuxTooltip(
  message: l10n.archiveThisConversation,
  child: IuxIconButton(
    icon: Icons.archive_outlined,
    action: const IuxActionDescriptor(
      semantics: IuxActionSemantics(label: 'Archive'),
    ),
    onActivate: controller.archive,
  ),
)
```

```dart
// Wrong: a paragraph in a box that cannot scroll. Rejected by an assertion.
IuxTooltip(message: l10n.sortCodeExplanation, child: field)

// Right: it opens in the page, has room, and stays open.
IuxContextualHelp(
  label: l10n.whatIsASortCode,
  help: l10n.sortCodeExplanation,
  expanded: state.open,
  onExpandedChanged: controller.toggle,
)
```

```dart
// Wrong: an instruction everyone needs, hidden behind a press most will not
// make.
IuxContextualHelp(
  label: l10n.passwordRules,
  help: l10n.atLeastEightCharacters,
  ...
)

// Right: it is always on screen and always announced.
IuxTextField(
  input: IuxInputDescriptor(
    semantics: IuxInputSemantics(label: l10n.password),
    helpText: l10n.atLeastEightCharacters,
  ),
  ...
)
```

```dart
// Wrong: the panel is wrapped around several controls, so the tooltip's
// semantics merge them into one announcement.
IuxTooltip(message: l10n.sortOptions, child: Row(children: buttons))

// Right: one tooltip per control.
Row(children: <Widget>[
  for (final button in buttons)
    IuxTooltip(message: button.explanation, child: button),
])
```

## Limits

- **Long press is not discoverable and is not announced to a sighted user.**
  Nothing on screen says the gesture exists. This is the reason for the rule at
  the top of this page and it cannot be fixed inside the component: the only
  honest mitigation is that nothing here is essential.
- **A tooltip requires an ambient `Overlay`.** `MaterialApp` provides one. Where
  none exists the widget asserts at build time rather than silently never
  appearing.
- **`IuxTooltip.child` must be exactly one control.** Its semantics are merged
  into a single node. A row of controls wrapped in one tooltip is announced as
  one control, and the widget cannot detect the mistake.
- **Showing on focus can surprise a touch user** if some other component in the
  tree moves focus on tap. IUX's own controls do not, so this does not arise
  within the library, but a mixed application may see a tooltip appear on a tap.
- **The outline is measured against the theme's page surface**, not against
  whatever is actually behind the tooltip. Over a photograph or a video the 3:1
  guarantee does not hold, and no component can make it hold without inspecting
  its own backdrop.
- **The help panel does not scroll itself.** It is in the flow, so a long
  explanation at 200% text on a small screen grows past the bottom of the
  screen and the *page* has to scroll. Place it inside a scrollable page — which
  is where a form lives anyway. A component that scrolled internally would be a
  second scrollable inside the page's, which is worse.
- **Only one help panel is modelled.** Several `IuxContextualHelp` widgets on
  one screen can all be open at once, because the parent owns each flag
  separately. Nothing coordinates them; an application that wants accordion
  behaviour writes it in the parent, where it belongs.
- **`help` cannot contain a control.** No link, no button, no "Learn more". This
  is deliberate for now — a control inside a disclosed panel needs a reachable
  focus order and a way back — and if a demonstrated need appears, the shape to
  add is a single optional action modelled on `IuxNamedAction`, not a
  widget slot.
- **A tooltip inside a scrollable follows its anchor but does not close when the
  anchor scrolls out of view**; it disappears only when the anchor stops being
  painted. In practice the next press closes it.
- **Nothing checks that a tooltip is redundant.** The framework enforces length
  and single-line, which are what stop a tooltip from *becoming* the only place
  information could live. Whether the message duplicates something the user can
  already reach is a judgement no test can make.

## Evidence level

| Claim | Level |
| --- | --- |
| Content shown on hover or focus must be dismissable, hoverable and persistent | Standard — WCAG 2.2 SC 1.4.13 |
| A disclosure control must expose its expanded state programmatically | Standard — WCAG 2.2 SC 4.1.2 |
| Every control has an accessible name; a tooltip is not one | Standard — WCAG 2.2 SC 4.1.2, Android accessibility guidance |
| Text at 4.5:1, outline at 3:1 | Standard — WCAG 2.2 SC 1.4.3, 1.4.11 |
| Text survives 200% scaling without clipping | Standard — WCAG 2.2 SC 1.4.4 |
| The disclosure control meets the touch target floor | Standard — WCAG 2.2 SC 2.5.8, Android guidance |
| Everything reachable without a pointer | Standard — WCAG 2.2 SC 2.1.1 |
| Long press as the touch route to a tooltip | Strong guidance — Android's own tooltip behaviour, which users are trained on |
| Hover-only content is unusable on touch, so a tooltip must never be essential | Strong guidance — Nielsen Norman Group on tooltips and hover-dependent content |
| Progressive disclosure for explanation a minority needs | Strong guidance — Nielsen Norman Group on progressive disclosure |
| Removing the auto-hide timer entirely | Context dependent — the strongest available reading of SC 1.4.13; Material keeps a timer |
| Refusing rich content and controls inside a tooltip | Context dependent — IUX's reading of the above, enforced by the API having no slot |
| Refusing to animate the help panel | Context dependent — the reasoning is stated above; it has not been user-tested |
| The 80-character ceiling and the one-line rule | Hypothesis — calibrated against two lines at default text on a phone, not measured on users |
| Showing the tooltip on focus rather than on an explicit key | Hypothesis — the common pattern, not a measured result |

## Sources

- WCAG 2.2 — SC 1.4.3, 1.4.4, 1.4.11, 1.4.13, 2.1.1, 2.4.7, 2.5.8, 4.1.2.
- Understanding SC 1.4.13: Content on Hover or Focus — the dismissable /
  hoverable / persistent formulation and the `Escape` technique.
- Android accessibility guidance on labels for icon-only controls.
- Material guidance on tooltips — including the timer this component removes.
- Nielsen Norman Group, on tooltips, on hover-dependent content, and on
  progressive disclosure.
- `docs/components/text-field.md` — where always-visible help lives.
- `docs/components/button.md` — `IuxIconButton` and the limitation this mission
  answers.
- `docs/components/component-standard.md` §2, §3, §5, §6, §9, §11.
