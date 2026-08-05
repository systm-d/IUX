# IuxButton

## Purpose

Identify and activate a textual action. For an action with no room for a
label, see [`IuxIconButton`](button-variants.md).

```dart
IuxButton(
  label: l10n.save,
  action: const IuxActionDescriptor.primary(
    semantics: IuxActionSemantics(label: 'Save'),
  ),
  onActivate: controller.save,
)
```

## Use when

The user activates something and it has a text label.

## Do not use when

- **Navigating.** A button that behaves like a link misleads a screen reader
  user about what will happen.
- **Toggling a value.** A switch or checkbox says more, and announces its
  state.
- **You want the button to run the operation.** It will not. The parent owns
  the operation and reports it through `IuxActionDescriptor.operation`; a
  button that ran its own future would be guessing at an outcome only the
  caller knows.

## API

| Parameter | Required | Note |
| --- | --- | --- |
| `label` | yes | the visible text, already localised |
| `action` | yes | what it is and whether it may run |
| `onActivate` | yes | called once per accepted gesture |
| `icon` | no | `IconData`, leading in reading order, redundant with `label` |
| `variant` | no | defaults to the theme's |
| `autofocus`, `focusNode` | no | focus handling |
| `expand` | no | fill the width; off by default |
| `busyHint` | no | announced after the name while the action runs |

There is no colour, radius, elevation or duration parameter, and there will not
be one. An API that accepts a colour has already lost the contrast guarantee:
the theme can no longer be held responsible for something a call site
overrode.

## Two labels, on purpose

`label` is what is seen; `action.semantics.label` is what is heard. They may
differ:

```dart
IuxButton(
  label: 'Delete',
  action: const IuxActionDescriptor(
    semantics: IuxActionSemantics(label: 'Delete the March invoice'),
  ),
  onActivate: remove,
)
```

A sighted user sees the column they are in. A screen-reader user hears the row
they are on, because they have no column.

## States

| State | Source | Expressed |
| --- | --- | --- |
| enabled, disabled | `action.availability` | yes |
| loading | `action.operation` — the parent's | through `busyHint` only |
| success, error | `action.operation` — the parent's | **no** |
| hovered, pressed | internal to the widget | yes, when a tap would run |
| focused | internal, drawn additively | yes |

Availability, interaction and operation are three separate things. Focus,
press and hover stay inside the widget because they belong to this instance and
to nothing else.

**Engagement feedback is offered exactly when engaging would run something.**
The hover tint and the press colour follow `action.isActivatable`, which is the
same question the tap action and the gesture handlers ask, so the container
cannot come to promise a tap the repeat policy will decline. A running action
under the default `ignoreWhileInProgress` therefore sits still; the same action
under `IuxActionRepeatPolicy.allow` hovers and presses exactly like an idle one,
because a second activation genuinely is accepted.

**`IuxButton` cannot show a result, and that is deliberate.** Component
standard §6 asks a component that cannot express one of its states to say so
rather than leave the caller to discover it, so: an `IuxActionDescriptor`
carrying `IuxActionOperation.succeeded` or `IuxActionOperation.failed` renders
a button byte-identical to one that has not run, and announces the same node. A
result painted on the container would be a colour and nothing else — WCAG 2.2
SC 1.4.1, and §6 asks an error state for "a message, never a colour alone".

The resolver used to carry `IuxButtonState.success` and `IuxButtonState.error`
with a documented precedence above `hovered`. Neither reached the screen, and
because they outranked `hovered` a settled button silently stopped responding
to the pointer. Both were removed at IUX-038; the hover behaviour is pinned in
`test/components/iux_button_qa_test.dart`.

`IuxButtonState.loading` was the third and last of them, removed at IUX-040 on
the same grounds and after the same measurement: byte-identical to `enabled` in
every token, on all four colour profiles, in all seventeen legal intent/variant
pairs — 68 cells swept, 68 collisions. It cost what the other two cost. Sitting
above `pressed` and `hovered`, it swallowed the feedback of a running action
whose repeat policy accepted a second tap: measured on the filled primary in
light standard, an idle button moved `#1560B0` → `#0F4289` on hover and
`#0A2C63` on press, while a running one that *was* accepting taps stayed at
`#1560B0` for both. The enum now has four members and each resolves to an
appearance no other produces, swept per profile in
`test/themes/button_distinguishability_test.dart`.

A failure the user can see is `IuxAsyncActionButton`, which renders the message
the operation supplied beneath the control — never a colour alone, and never a
message the framework invented.

## Accessibility

- Announced as a button, with its name and enabled state.
- A disabled button explains itself when the caller supplied
  `unavailabilityReason`. A greyed control with no explanation leaves the user
  unable to tell whether they did something wrong or the feature does not
  apply.
- A running button announces the wording you passed as `busyHint`, and nothing
  at all when you pass none. The framework composes no user-facing text, so it
  cannot supply this for you — but silence is indistinguishable from a control
  that did nothing, so supply it for anything asynchronous. (An earlier version
  of this document said the button announces "In progress". It did until
  IUX-008.6, in English, in every locale — see IUX-A11Y-008.)
- Enter and Space activate it; a disabled button is skipped by focus
  traversal. A *running* one is not: it keeps its place in the order and keeps
  the focus the user had put on it, whatever the repeat policy. Only
  unavailability takes a control out of traversal, which is where Flutter draws
  the line too.
- At least the resolved touch target floor, at every density.
- The label wraps and is never truncated. A truncated action label is an
  action the user cannot identify, and truncation gets worse exactly when
  someone has enlarged their text.

**Verified in widget tests**, including every combination of the five
accessibility preferences on both brightnesses at 200% on a 320-pixel screen,
and label wrapping to 300%. Still requires manual checking on device: TalkBack
reading order, Voice Access naming, D-pad traversal.

**A running button is not a disabled one, and no longer says it is.** Two
measured defects stood here until IUX-038: a running button announced itself as
*disabled* — a node indistinguishable from an unavailable one apart from
`busyHint` — and it left focus traversal for the duration of the run, so a
keyboard user who pressed Enter was thrown back to the enclosing scope. One flag
fed both the semantics and the focus node; they are now two. A running control
publishes `isEnabled: true`, `isFocusable: true` and `SemanticsAction.focus`,
and withholds only `SemanticsAction.tap`, which is honest: under the default
repeat policy the activation really would be dropped. Measured in
`test/components/iux_button_qa_test.dart` and, against Flutter's own controls,
in `test/accessibility/control_focus_semantics_test.dart`.

`IuxSemantics.action` used to yield `isFocused: Tristate.none` and no
`SemanticsAction.focus`, which left every control it built unreachable by an
assistive technology trying to *move* accessibility focus onto it. That is
IUX-A11Y-FOCUS-001, fixed here at IUX-038 and at the remaining eight call
sites since: the button now reports the same focus state and the same
`[tap, focus]` pair as Flutter's own, measured side by side in
`test/accessibility/control_focus_semantics_test.dart`.

## Catalog

`apps/catalog`, **Buttons** section — the button system under the conditions it
is most likely to fail in, not a gallery of it.

```bash
cd apps/catalog && flutter run
```

Three conditions are owned above every panel and apply to all of them at once:
the accessibility profile, a text scale reaching 300%, and a long-label switch
that replaces every sample label with one of the length a German or Finnish
translation produces. **Worst case** sets all of them in one tap.

| Panel | What it is checking |
| --- | --- |
| Emphasis and meaning | every intent × variant pair, and the one the resolver refuses |
| Icon actions | the interactive region, measured and printed against the resolved floor |
| Unavailable, with and without a reason | two controls that look identical and announce differently |
| Focus | the ring in every profile; the unavailable control skipped |
| Where the operation is | the four lifecycle values side by side — see Limits |
| Room to wrap | natural, expanded, squeezed to 140px, sharing a row, inside a `Center` |
| An action that takes time | the busy state with no spinner; outcome, cancellation and repeat policy switchable |
| An action worth being careful about | confirmation versus undo, and the plain button that now refuses a confirming action |
| What the API refuses | the assertions, and the fact that a release build has none of them |

Three of those panels print the semantics node the framework actually
published — name, hint, role, enabled state, whether anything is there to
activate. It is not TalkBack: it reports the properties Flutter set, not the
sentence Android composes from them. It is enough to see the defects above
without a device, and `apps/catalog/README.md` records the ones it surfaced.

## Anti-patterns

```dart
// Wrong: the button is asked to own an outcome it cannot know.
IuxButton(onActivate: () async { await save(); setState(showSuccess); })

// Right: the parent owns it and re-renders with a new descriptor.
IuxButton(action: descriptor, onActivate: controller.save)
```

```dart
// Wrong: two primary buttons in one group.
Row(children: [IuxButton(action: primaryA), IuxButton(action: primaryB)])
```

```dart
// Wrong: relying on colour alone to mark a destructive action.
// Right: destructive wording, plus IuxDestructiveAction to present the
// confirmation the descriptor asks for. An IuxButton will not present it.
```

## Limits

- A leading icon is available via `icon`; an icon-only action uses
  `IuxIconButton`. There is no trailing icon position — see
  [button-variants.md](button-variants.md).
- No asynchronous handling of its own. `IuxAsyncActionButton` is that widget;
  see [async-actions.md](async-actions.md).
- **A confirmation policy on the descriptor is refused here, not ignored.**
  Obtaining an answer is a pattern's job, and this widget now says so rather
  than dropping the policy in silence:

  ```dart
  // Fails a debug check on the first frame it is built.
  IuxButton(label: l10n.delete, action: IuxActionDescriptor.destructive(...))
  ```

  That call site used to compile, assert nothing and delete on the first tap —
  `IuxActionDescriptor.destructive` defaults to `IuxConfirmBeforeExecution`, so
  the trap sat on the shortest path anybody could write for a deletion
  (`IUX-BUTTON-CONFIRM-001`). It reads as though the user will be asked, and
  they were not.

  The check is at `build`, not on the constructor, because the constructors are
  `const` and Dart forbids reading a parameter's field in a `const` assertion.
  It fires on the first frame the control exists, before any gesture, so no
  debug run or widget test can reach a release build without seeing it. The
  release build behaves exactly as it did before — the assertion is compiled
  out, and flipping the evaluation there would turn a caller's mistake into a
  control that does nothing when tapped.

  Use `IuxDestructiveAction`, which routes activation through a policy asked
  with `confirmed: false`. See
  [destructive-action.md](../patterns/destructive-action.md). If something
  above the button has already obtained the answer, strip the policy before
  handing the descriptor down — `copyWith(confirmation:
  IuxConfirmationPolicy.none)` — which is what every honourer in the library
  does. See [action-model.md](action-model.md).
- **`IuxActionCancellation` is ignored here too.** `IuxAsyncActionButton`
  asserts that `IuxActionCancellation.required` comes with a `cancelLabel`;
  `IuxButton` draws no exit and says nothing. An operation long enough to need
  one belongs on `IuxAsyncActionButton`.
- **The lifecycle is not drawn, and the resolver no longer pretends it is.**
  The four values of `IuxActionOperation` resolve to identical background,
  foreground, border and border width, so a button carrying `operation: failed`
  is pixel-identical to one that never ran. That is the deliberate half — see
  *States* — and it is now the only half. `IuxButtonStateResolver` used to
  mirror the lifecycle in `IuxButtonState.loading`, `.success` and `.error`,
  three members that resolved to the resting palette and outranked the rungs
  that had something to show; all three are gone (IUX-038, IUX-040). Compare the
  four values in the catalog's **Where the operation is** panel. A failure worth
  showing belongs on `IuxAsyncActionButton`, which puts the wording beneath the
  control — and even that shows nothing for `IuxAsyncFailure.raised`, which has
  no wording to show.
- **A running plain button looks exactly like an idle one.** The operation
  reaches a screen-reader user through `busyHint` and reaches a sighted user
  through nothing at all, and `busyHint` is optional with no assertion pushing a
  caller towards it. This is the cost of refusing a colour-only status signal
  with only one channel to spend: `IuxAsyncActionButton` is the widget that has
  a second one, and it spends it on a word, swapping `label` for `busyLabel`.
  Anything a user has to wait for belongs there.
- **`IuxActionSemantics.unavailabilityReason` is read only while the action is
  unavailable.** Setting it on an enabled action discards it silently.
- `expand` fills the width but does not cap it; use `IuxReadableWidth` when
  that matters.

## Evidence level

Standard for the accessibility guarantees. Context dependent for the
two-label design.

## Sources

- WCAG 2.2 — SC 4.1.2, SC 2.1.1, SC 2.4.7, SC 2.5.8, SC 1.4.4.
