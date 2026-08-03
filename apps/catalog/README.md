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

## Sections

- **Buttons** — the button system and the action model behind it. This is what
  the catalog opens on.
- **Theme** — what a profile resolves to, drawn as bare rectangles, so the theme
  can be inspected without a component's own decisions in the way.
- **Runtime** — the accessibility, motion, feedback and layout runtimes.

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

`test/app_test.dart` walks every panel of every section, taps through the
destructive and asynchronous scenarios, and asserts that the worst case
survives both the default surface and a 360-wide phone — the narrowest Android
width still shipped in volume.

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
