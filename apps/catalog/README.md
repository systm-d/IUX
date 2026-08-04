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
rediscovered. None of them is fixed by this catalog; the catalog only makes them
visible.

### 1. Four lifecycle values, one appearance

`IuxButtonStateResolver` computes `loading`, `success` and `error`, and
`IuxButtonResolver` gives all three the resting palette. Every token is
identical:

```dart
for (final IuxActionOperation operation in IuxActionOperation.values) {
  IuxButtonResolver.resolve(context, descriptor.copyWith(operation: operation));
}
// idle       state=enabled  bg=#1560B0 fg=#FFFFFF border=#1560B0/0.0
// inProgress state=loading  bg=#1560B0 fg=#FFFFFF border=#1560B0/0.0
// succeeded  state=success  bg=#1560B0 fg=#FFFFFF border=#1560B0/0.0
// failed     state=error    bg=#1560B0 fg=#FFFFFF border=#1560B0/0.0
```

A plain `IuxButton` carrying a failed operation is pixel-identical to one that
never ran. See the **Where the operation is** panel.

### 2. A busy button is announced as disabled, and loses focus

With the default repeat policy, a running action is not activatable, so the
button publishes `enabled: false` and no tap action, and `IuxFocusable` drops
`canRequestFocus`. Combined with finding 1, the control looks available, reads
as unavailable, and cannot be reached by a keyboard:

```dart
// focus the button, then rebuild it with operation: inProgress
// idle: focused=true
// busy: focused=false label="Send" hint="" enabled=isFalse tap=false
```

`IuxAsyncActionButton` avoids all of this by swapping the label and supplying
`busyHint`. A plain `IuxButton` handed `operation: inProgress` does not, and
nothing warns.

### 3. A raised failure says nothing at all

`IuxAsyncFailure.raised` carries no message, so `IuxAsyncActionButton` renders
no message; the button itself is drawn exactly like an idle one. The framework
refusing to invent a sentence for an exception is right. The result is still a
control that ran, failed, and is silent until the parent maps the error to
words. Reproduce with **Outcome: raises** in the async panel.

### 4. `IuxButtonTokens.focused` is dead public surface

`IuxButtonResolver.resolve` takes a `focused` argument and stores it on the
tokens. No button widget passes it and nothing reads it — the ring comes from
`IuxFocusable`. The equivalent token on the text field *is* consumed
(`iux_text_field.dart`), so the shape reads as intentional and is not.

### 5. A confirming descriptor on a plain button runs unasked

`IuxButton` evaluates an action with `confirmed: true`, because obtaining a
confirmation belongs to a pattern. So a descriptor declaring
`IuxConfirmBeforeExecution` handed to a plain `IuxButton` compiles, runs on the
first tap, and nobody is ever asked. `IuxDestructiveAction` exists to close
this, and nothing at the call site distinguishes the two. The panel keeps a
running count of how many times it happened.

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

`IuxTargetSpacing` is a `Wrap` on **both** axes, a `Wrap` offers its children no
width, and `expand` is a `SizedBox(width: double.infinity)`. The layout fails on
*BoxConstraints forces an infinite width* at `iux_button.dart:417`. The button's
own comment says the loud failure is intended for an unbounded `Row`; nothing
anticipated that `IuxTargetSpacing` would be one. The workaround — a `Column`
with `IuxGap` — gives up the eight-pixel target floor the primitive exists to
guarantee. See the **Layout** section, where both arrangements are shown.

### 9. Opening a modal can destroy the widget that opened it

`IUX-OVERLAY-001` is documented as a lost scroll position. The undocumented half
is that the rebuild **disposes** any panel that had been scrolled to, so a
callback closing over that panel's `setState` fires on a dead `State`:

```
setState() called after dispose(): _DialogPanelState#9a73d
  (lifecycle state: defunct, not mounted)
```

thrown from the tap that answered the dialog. Anything an overlay's controls
report has to outlive the widget that opened it, which is why the catalog's
counters live on `CatalogOverlays`. See the **Overlays** section.

### 10. A long `dismissLabel` overflows the navigation drawer's header

Measured: `dismissLabel: 'Close the menu'` overflows by **7.5 pixels** at 100%
text, on an 800-wide surface and again on a 1200-wide one. `'Close'` does not.
The panel is capped at a readable width of about 280 whatever the screen, so a
wider screen never helps; the header is `Row([Expanded(title), gap, dismiss])`
and once the dismissal's intrinsic width plus the gap exceeds the content width
the `Expanded` is handed negative space. The row stacks instead of sharing a
line only past roughly 130% text — so *enlarging* the text fixes it and leaving
it alone does not, which is the opposite of every other size failure here.
Reproduce from the **Navigation** section's "Dismiss label" chooser; pinned by a
test.

### 11. `IuxAdaptiveNavigation` picks a rail wider than its own window

On a landscape box past the stacked-text threshold the component takes the rail
even when the content budget fails, and the argument for that is sound: the bar
there is a full-width list that would leave zero content. But the reasoning
weighs how much is *left over* and never asks whether the rail fits at all. At
300% text in a **360 × 320** box the rail asks for more than the whole box, the
leftover is negative, and the `Row` overflows by **36 pixels** — a debug error
rather than the degradation the documentation promises. A rail placed by hand
gets no refusal and no warning either.

### 12. `IuxProgressIndicator.valueLabel` is unchecked against `value`

`IuxProgressIndicator(value: 0.45, valueLabel: '90%')` compiles and renders: a
bar at 45% announcing ninety. The parameter exists for a good reason — IUX
cannot compose a percentage, because `%`, `٪` and `45 %` are all locale
decisions — but nothing compares the two, and the announcement is what a
screen-reader user receives. The two audiences are told different things. See
the **Feedback** section's "Value label" chooser.

### 13. Documentation that no longer matches the code

Four pages describe limits that have since been fixed, and each would send a
reader off to build a workaround they do not need:

- `docs/components/app-bar.md` — "Not exported from the barrel." It is exported,
  at `iux_flutter.dart:16`.
- `docs/components/bottom-sheet.md` — "`IuxModalLayer` cannot hold it. Its slot
  is `IuxDialog?`." The `sheet` slot exists and this catalog uses it.
- `docs/components/navigation-drawer.md` — "No `IuxModalLayer` slot." The
  `drawer` slot exists and this catalog uses it.
- `docs/patterns/loading-and-retry.md` — still describes a running retry as
  announced *unavailable* and dropped from the focus order. IUX-038 fixed that;
  the source docstring on `IuxLoadingRetry` now says the opposite of the page.

And one that describes a guarantee the code does not make:

- `docs/components/navigation-rail.md` — an unbounded box "fails loudly rather
  than silently … **Asserted.**" There is no assertion. The private width check
  returns false for an unbounded constraint, so the widget silently chooses the
  bar; a caller who put it in a scroll view gets the phone arrangement on a
  tablet and no warning at all.

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
- **Two limits cannot be shown without stopping the thing showing them.** A
  fourth app-bar action and an adaptive box too narrow for its own rail both
  produce a debug failure that would take the harness down, so those panels
  print the measured numbers and withhold the sample. Everything else that
  looked wrong is on screen.
- The drawer's overflowing dismiss label *is* built, behind a chooser that is
  off by default. Turning it on renders a real debug overflow, which is the
  point.
