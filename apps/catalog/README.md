# IUX catalog

A harness for the IUX package, not a showroom for it.

```bash
cd apps/catalog
flutter run                 # Android is the platform priority
flutter test                # the harness checks itself
flutter build apk --debug
```

## What it is for

A catalog that shows a happy-path component in a nice light is decoration: a
screenshot cannot be wrong. This one exists so a maintainer can put a component
under the conditions it is most likely to fail in and *watch it fail* — an
accessibility profile nobody designs for, a text scale of 300%, a label of the
length translation actually produces.

Every panel states what it is trying to prove, and what would count as a
failure, before it shows anything.

## The three axes

They are owned at the top of the application, above every section, because they
have to apply to all of it at once. Anything that changed only one panel would
prove only that the panel was written to survive it.

| Axis | Range | Why |
| --- | --- | --- |
| accessibility profile | contrast, density, motion, touch target, visual stimulation, brightness | each is independent, and every combination is legal |
| text scale | 100%, 150%, 200%, **300%** | Android reaches 300% with the largest font setting and display size enlarged; a component checked at 200% has not met its largest users |
| long labels | on/off | replaces every sample label at once with one of German length |

**Worst case** sets all of them in one tap: dark, high contrast, compact, 300%,
long labels. At 300% the chips are large enough that setting six of them by hand
is its own obstacle, which is the reason the preset exists.

**The header folds away.** With thirteen sections the chooser and the seven
condition rows were most of the first screen at 100% and rather more than one
screen at 300%, so the panel a maintainer came to look at started below the
fold. It opens by default — a harness whose axes are hidden until discovered is
a harness that gets used at 100% forever — and the summary line survives the
fold, so a screenshot of a folded header still says which combination produced
it.

## Sections

Ordered the way the library is built: the things a user touches, then the things
that arrange them, then the patterns made out of both, then the two engines
underneath.

| Section | Covers |
| --- | --- |
| **Buttons** | the button system and the action model behind it; what the catalog opens on |
| **Inputs** | text field, checkbox, switch, radio group, selection groups |
| **Forms** | `IuxForm`, the validation summary, the guided form |
| **Search** | the query box and the four states a search is ever in |
| **Cards and lists** | cards, rows, groups, separators, selectable rows |
| **Media and status** | glyphs, avatars, images, statuses, chips, badges |
| **Layout** | breakpoints, pages, sections, surfaces, spacing, reading width |
| **Navigation** | app bar, bottom bar, rail, adaptive, drawer, tabs |
| **Overlays** | dialog, bottom sheet, transient messages, tooltip |
| **Feedback** | alerts, banners, progress |
| **Flows** | empty state, error recovery, loading and retry, permission rationale, destructive flow, disclosure |
| **Theme** | what a profile resolves to, drawn as bare rectangles |
| **Runtime** | the accessibility, motion, feedback and layout runtimes |

Every panel of every section ends in a **refusal panel** listing what that part
of the API will not let you build. They are all `assert`, so a release build has
none of them, and each one says so.

### Coverage against the barrel

Everything exported from `lib/iux_flutter.dart` has a panel. The exceptions,
stated rather than left to be discovered:

- `lib/src/patterns/onboarding/` exists on disk but is **not exported**, so it
  is not public API and has no panel.
- `IuxProgressIndicator` appears twice on purpose — in **Runtime** for its
  interaction with the motion preference, and in **Feedback** for its own
  contract.
- Token classes (`*_tokens.dart`) are resolved by the components that consume
  them and are inspected in **Theme** rather than given panels of their own.

## The overlays are owned by the page

Four sections need a dialog, a sheet, a drawer or a transient strip, and all
four are placed **once**, in `main.dart`, through one `IuxModalLayer` and one
`IuxTransientLayer`. That is not a catalog convenience: it is the arrangement
the library requires, and building it anywhere else is how an application ends
up with two scrims. `catalog_overlays.dart` is the owner, and the panels hand it
values rather than opening anything themselves.

## The button panels, and what each one is checking

| Panel | Looking for |
| --- | --- |
| Emphasis and meaning | every intent × variant pair, and the one the resolver refuses; a label that stops reading against its container in high contrast |
| Icon actions | the interactive region against the resolved target floor, printed under each control, at every text scale |
| Unavailable, with and without a reason | two controls that look identical and announce differently |
| Focus | the ring visible in every profile, distinct from selection, not moving the layout; the unavailable control skipped |
| Where the operation is | four lifecycle values side by side — any two that are indistinguishable name a state nothing carries |
| Room to wrap | natural, expanded, squeezed to 140px, with an icon, sharing a row, inside a `Center`; nothing may clip |
| An action that takes time | the busy state with no spinner; outcome, cancellation and repeat policy all switchable |
| An action worth being careful about | confirmation versus undo, and the plain button that runs a confirming action anyway |
| What the API refuses | the assertions, and the fact that a release build has none of them |

## The semantics readout

Three panels print the semantics node the framework actually published: name,
hint, role, enabled state, and whether anything is there to activate. A button's
announcement is invisible, it is the half most likely to be wrong, and checking
it normally means installing TalkBack on a device.

It is **not** TalkBack. It reports the properties Flutter published, not the
sentence Android composes from them — word order, the word for "button" and the
treatment of a disabled control belong to the platform and differ between screen
readers. What it proves is which properties are set, and that is where the
defects are.

Turning it on forces the semantics tree to be built for the whole application,
exactly as an assistive service would, and it only works in debug and profile
builds (`RenderObject.debugSemantics` returns null in release).

## Findings this harness surfaced

Recorded here because a finding nobody wrote down is a finding that gets
rediscovered. The catalog fixes none of them; it only makes them visible. Where
a later mission closed one, the entry says so and keeps the measurement, because
a finding that disappears when it is fixed teaches nobody why it was there — and
because three of these turned out to have been closed for weeks while the page
still described them as open.

### 1. Four lifecycle values, one appearance

`IuxButtonStateResolver` computed `loading`, `success` and `error`, and
`IuxButtonResolver` gave all three the resting palette. Measured byte-identical
across all four colour profiles in all seventeen legal intent/variant pairs —
**68 cells, 68 collisions**:

```dart
for (final IuxActionOperation operation in IuxActionOperation.values) {
  IuxButtonResolver.resolve(context, descriptor.copyWith(operation: operation));
}
// idle       state=enabled  bg=#1560B0 fg=#FFFFFF border=#1560B0/0.0
// inProgress state=loading  bg=#1560B0 fg=#FFFFFF border=#1560B0/0.0
// succeeded  state=success  bg=#1560B0 fg=#FFFFFF border=#1560B0/0.0
// failed     state=error    bg=#1560B0 fg=#FFFFFF border=#1560B0/0.0
```

All three rungs are now gone — `success` and `error` at IUX-038, `loading`
after this catalog reported it. Their real cost was not the wasted name: they
outranked `pressed` and `hovered`, so a running action whose repeat policy was
still *accepting taps* answered neither the pointer nor the finger.

```dart
// repeatPolicy=allow  idle       rest=#1560B0 hover=#0F4289 press=#0A2C63  moved
// repeatPolicy=allow  inProgress rest=#1560B0 hover=#1560B0 press=#1560B0  did not
```

Engagement feedback now follows `IuxActionDescriptor.isActivatable`, the same
predicate as the tap action and the gesture handlers, so the three cannot drift
apart again. What remains is deliberate: the four values of `IuxActionOperation`
still render identically on a plain `IuxButton`, because a lifecycle painted on
a container is a colour and nothing else. See the **Where the operation is**
panel.

### 2. A busy button is announced as disabled, and loses focus — closed at IUX-038

One flag fed both the semantics node and the focus node, so a running action
announced `enabled: false`, offered no tap action, and dropped out of focus
traversal. Re-measured against a live semantics tree and a real `FocusNode`:

```dart
// busy: isEnabled=isTrue isFocusable SemanticsAction.focus present
//       SemanticsAction.tap absent   hasFocus=true before and after Enter
```

Only the tap is withheld, which is honest — the default repeat policy really
does decline it. Still true, and not a defect: a running plain button looks
exactly like an idle one to a sighted user, and `busyHint` is optional.
`IuxAsyncActionButton` is the widget with a second channel to spend.

### 3. A raised failure says nothing at all

`IuxAsyncFailure.raised` carries no message, so `IuxAsyncActionButton` renders
no message; the button itself is drawn exactly like an idle one. The framework
refusing to invent a sentence for an exception is right. The result is still a
control that ran, failed, and is silent until the parent maps the error to
words. Reproduce with **Outcome: raises** in the async panel.

### 4. `IuxButtonTokens.focused` is dead public surface — closed at IUX-038

`IuxButtonResolver.resolve` took a `focused` argument and stored it on the
tokens; no button widget passed it and nothing read it. It was removed rather
than wired, and the reason is not tidiness: a token-driven ring can only be
painted by the container's own decoration, inside the control and over the
content it identifies, which is the failure WCAG 2.2 SC 2.4.11 exists for.
`IuxFocusRing`, drawn *outside* the control by `IuxFocusable`, is the only
channel. Neither the field nor the resolver parameter exists today.

### 5. A confirming descriptor on a plain button runs unasked — closed

This was the most serious defect the harness found, and it was the shortest path
anybody could write for a deletion: `IuxActionDescriptor.destructive` *defaults*
to `IuxConfirmBeforeExecution`, `IuxButton` evaluated the action with
`confirmed: true`, and the policy was dropped in silence — the call site read as
though the user were being asked, and the deletion ran on the first tap.

A plain `IuxButton` now refuses the descriptor at build, by name, and says what
to do instead: use `IuxDestructiveAction` with a controller, which evaluates the
policy with `confirmed: false` and runs the action only once the question has
been answered — or, if the answer was already obtained above the button, strip
the policy explicitly with `action.copyWith(confirmation:
IuxConfirmationPolicy.none)`. Every honourer in the library strips before
delegating, so a descriptor that still carries a policy at a button has been
honoured by nobody.

The check fires on the first frame the control is built, not on activation, so
no debug run, widget test or catalog page can reach a release build without
seeing it. `confirmed: true` stays at the evaluation site deliberately: flipping
it in release would turn a caller's mistake into a control that does nothing
when tapped, which is indistinguishable from one that is broken.

### 6. Every refusal is an assertion

Destructive + tonal, a confirmation policy with no prompt, a promised
cancellation with no cancel control — all of them are `assert`, so a release
build has none of them. They catch a developer, not a user.

### 7. Smaller

- `IuxFeedbackEvent`'s role constructors take no `allowAnnouncement`, so
  silencing a duplicate announcement means dropping to the unnamed constructor
  and restating the role.
- `IuxActionRole` has no value for archiving. `custom` is the only fit, and it
  tells the semantics layer nothing.

### 8. `IuxButton(expand: true)` inside `IuxTargetSpacing` throws

Two full-width buttons stacked with the library's own spacing primitive is the
most ordinary thing a caller can write:

```dart
IuxTargetSpacing(children: <Widget>[
  IuxButton(label: 'Keep', expand: true, …),
  IuxButton(label: 'Delete', expand: true, …),
])
```

`IuxTargetSpacing` was a `Wrap` on **both** axes, a `Wrap` offers its children no
width, and `expand` is a `SizedBox(width: double.infinity)`, so the layout failed
on *BoxConstraints forces an infinite width*. The workaround — a `Column` with
`IuxGap` — gave up the eight-pixel target floor the primitive exists to
guarantee.

**Closed** (`IUX-EXPAND-CRASH-001`): the vertical axis is a `Column` now. The
wrapping given up there protected nothing, and the measurement is the argument.
A page scrolls, so the height is usually unbounded and a vertical `Wrap` never
wrapped anyway; and where the height *was* bounded it moved the overflow
**sideways, in silence** — on a 320-wide box a third target landed at
x 256.8–388.5, **68 px past the right edge, with no exception reported at all**.
A `Column` overflows loudly instead: a bug somebody fixes, rather than a target
nobody can reach. The horizontal axis stays a `Wrap`, because a row of controls
that stops fitting at a large text scale should move to a second line rather
than clip a label. See the **Layout** section, where both arrangements are
shown.

### 9. Opening a modal destroyed the widget that opened it — closed

`IUX-OVERLAY-001`, recorded as a lost scroll position. The undocumented half was
that the rebuild **disposed** any panel that had been scrolled to, so a callback
closing over that panel's `setState` fired on a dead `State`:

```
setState() called after dispose(): _DialogPanelState#9a73d
  (lifecycle state: defunct, not mounted)
```

thrown from the tap that answered the dialog. `IuxModalLayer` now keeps its
`Stack` whether or not anything is open, so the page's element survives:
measured on all three slots, 0 disposals against 1, scroll offset 400 against 0,
and no exception.

The reason it stayed open is worth more than the fix. IUX-027 had measured that
a preserved page stays readable to a screen reader, which made the destruction
look like the price of the semantics barrier — and `PROJECT_PROMPT.md` §5 puts
accessibility above ergonomics, so the price was paid for fifteen missions.
**That measurement was wrong.** It used `find.bySemanticsLabel`, which reads
`RenderObject.debugSemantics`: a per-render-object cache that keeps its last
value for a subtree that stops being *visited* rather than being dirtied.
Walking the semantics tree the platform is actually given, and the simulated
screen-reader traversal, shows the covered page absent under every placement.
There was no trade. The counters still live on `CatalogOverlays`, but now
because that is the clearer shape rather than because the panel would die.

### 10. A long `dismissLabel` overflowed the navigation drawer's header — closed

Recorded here as **7.5 px** at 100% text on 800- and 1200-wide surfaces, and in
`iux_navigation_drawer_test.dart` as **9.5 px** on 360/800/1200 plus 34 px on
320. Both numbers are historical: the header is no longer a
`Row([Expanded(title), gap, dismiss])` but a slotted render object that measures
the label it was actually given and chooses the arrangement from that, not from
the text scale.

Re-measured with `dismissLabel: 'Close the menu'` at 100% text: on both an 800-
and a 1200-wide surface the panel is 280 px, the header stacks, the heading
spans x 16–264 and the way out x 37–236.5 — every child 16 px inside the panel
edge, overflow **0**. Zero at all sixteen combinations of {320, 360, 800, 1200}
× {100%, 150%, 200%, 300%}. The inversion this entry described — enlarging the
text repaired it — is gone with the rule that caused it.

Note for whoever tests this next: the absence of an overflow *exception* is not
the evidence. The header clamps a starved heading to zero width rather than
painting past its box, so no arrangement of it can raise one. The assertion that
distinguishes fixed from broken is that the heading is never squeezed below the
way out beside it; forcing the pre-fix decision leaves the exception test green
and the heading **0.0 px** wide.

### 11. `IuxAdaptiveNavigation` picks a rail wider than its own window — closed

On a landscape box past the stacked-text threshold the component took the rail
even when the content budget failed, and the argument for that is sound: the bar
there is a full-width list that would leave zero content. But the reasoning
weighed how much is *left over* and never asked whether the rail fits at all, so
a negative remainder failed the budget exactly as a small positive one did. The
rule now carries a fit term.

Re-measured as arithmetic rather than as one font: a landscape box *N* pixels
narrower than the rail overflowed by exactly *N* with the term removed
(36 → 36, 100 → 100), and by nothing with it in place. Across a grid of 25
windows × 7 text scales, **21 cells flip from rail to bar and 18 of them stop
throwing**, while every ordinary size is unchanged. The "396 px against 360" in
the release assessment is *this panel's* longer destination names; five short
ones cost 354 at 300%.

What remains, and is not a defect: **a rail placed by hand still gets no IUX
refusal, and cannot get one.** A `Row` lays out a non-flexible child against an
infinite width, so the rail is never told the window it is in. It does get
Flutter's own report — the overflow equals the deficit exactly, measured at
100%, 200% and 300% — and in a *bounded* box narrower than it asked for there is
no report at all: the rail takes what it is given, the names wrap, and every
destination still renders (measured at 300%, asking 354 and given 200, 100 and
48 px). Whatever owns the total has to make the call, which is what
`IuxAdaptiveNavigation` is and why `widthFor` is public.

### 12. `IuxProgressIndicator.valueLabel` is unchecked against `value` — closed

`IuxProgressIndicator(value: 0.45, valueLabel: '90%')` used to compile and
render: a bar at 45% announcing ninety. It now asserts in debug. A percentage
written in `valueLabel` is compared against `value` with a five-point tolerance;
`%`, `٪`, `﹪` and `％` are all read, with or without the space French puts in
front. The parameter survives, because IUX still cannot compose a percentage —
that is a locale decision and it belongs to the application.

What is *not* inspected stays uninspected on purpose: `3 of 7`, `12 MB of
40 MB`, non-ASCII digits, and any label carrying two percentages. A
false-positive assertion is worse than a missing one. And the check is an
`assert`, so finding 6 applies to it in full.

### 13. Documentation that no longer matches the code — closed

Five pages described limits that had since been fixed, and each would have sent
a reader off to build a workaround they did not need. All five now match the
code. Kept here because the class of defect outlives the instances: a page that
records a limitation is a page that has to be revisited when the limitation
goes, and nothing mechanical enforces that.

- `docs/components/app-bar.md` — "Not exported from the barrel." It was.
- `docs/components/bottom-sheet.md` — "`IuxModalLayer` cannot hold it."
  The `sheet` slot arrived at IUX-020 and this catalog uses it.
- `docs/components/navigation-drawer.md` — "No `IuxModalLayer` slot."
  The `drawer` slot arrived with the component itself at IUX-027.
- `docs/patterns/loading-and-retry.md` — described a running retry as announced
  *unavailable* and dropped from the focus order. IUX-038 fixed that, and the
  source docstring had been saying the opposite of the page ever since.
- `docs/components/navigation-rail.md` — an unbounded box "fails loudly rather
  than silently … **Asserted.**" It was not, from IUX-025 until IUX-042 struck
  the claim. It is now: `IuxAdaptiveNavigation` refuses an unbounded box by
  name. The charge that the old behaviour was *silent* was wrong too — measured,
  one `SingleChildScrollView` produced **27 exceptions**, the first "RenderFlex
  children have non-zero flex but incoming height constraints are unbounded",
  reported against a `Column` inside the component. The choice was never
  silent-versus-loud; it was loud in the framework's words versus loud in ours.

## What was checked and found sound

Worth recording, because a suspicion that turned out to be wrong is still work
somebody would otherwise repeat.

- `IuxTargetSpacing` is a `Wrap`, not a `Row`: two controls that no longer fit
  side by side move to a second line rather than overflowing.
- The confirmation dialog survives 300% on a 360-wide surface.
- An asynchronous button with a cancel control beside it survives the same.
- An icon action measures 84 × 84 at 300%, well above the 48 floor. The glyph
  scales because an icon is content, and the region is applied separately.

## Testing the harness

`test/app_test.dart` builds **every section** and checks that its first panel
renders — the one thing `flutter analyze` cannot do, because a section wired to
a page nobody built still compiles. It taps through the destructive,
asynchronous and overlay scenarios, folds and unfolds the header, and asserts
that the worst case survives both the default surface and a 360-wide phone, the
narrowest Android width still shipped in volume.

Two tests pin defects rather than behaviour, and both say so: a long
`dismissLabel` must still overflow the drawer header, and the bottom bar must
still grow taller rather than narrower at 300%. The day either stops being true
the test fails, which is when the corresponding finding above should be struck.

The tests scroll by hand rather than with `scrollUntilVisible`, and they pump a
fixed number of frames rather than settling: `pumpAndSettle` never returns once
an indeterminate progress indicator is on screen, by design, since a spinner
that stopped would say the operation had. Any application showing one inherits
that constraint.

## Limits

- Rendering is not checked. Contrast, colour and layout are checked by eye here
  and by the package's own tests elsewhere; a widget test asserts behaviour, not
  pixels.
- TalkBack, Voice Access and D-pad traversal need a device. The semantics
  readout narrows what has to be checked there; it does not replace it.
- The section switch rebuilds the list, so a scroll position is not kept
  between sections.
- **One limit cannot be shown without stopping the thing showing it.** A fourth
  app-bar action produces a debug failure that would take the harness down, so
  that panel prints the measured numbers and withholds the sample. The adaptive
  box too narrow for its own rail is now built at every width: the component
  refuses the rail, so the case that used to overflow renders the bar.
  Everything else that looked wrong is on screen.
- The drawer's overflowing dismiss label *is* built, behind a chooser that is
  off by default. Turning it on renders a real debug overflow, which is the
  point.
