# IuxButton

## Purpose

Identify and activate a textual action.

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
| `variant` | no | defaults to the theme's |
| `autofocus`, `focusNode` | no | focus handling |
| `expand` | no | fill the width; off by default |

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

| State | Source |
| --- | --- |
| enabled, disabled | `action.availability` |
| loading, success, error | `action.operation` — the parent's |
| hovered, pressed | internal to the widget |
| focused | internal, drawn additively |

Availability, interaction and operation are three separate things. Focus,
press and hover stay inside the widget because they belong to this instance and
to nothing else.

## Accessibility

- Announced as a button, with its name and enabled state.
- A disabled button explains itself when the caller supplied
  `unavailabilityReason`. A greyed control with no explanation leaves the user
  unable to tell whether they did something wrong or the feature does not
  apply.
- A running button announces "In progress" — silence is indistinguishable from
  a control that did nothing.
- Enter and Space activate it; a disabled button is skipped by focus
  traversal.
- At least the resolved touch target floor, at every density.
- The label wraps and is never truncated. A truncated action label is an
  action the user cannot identify, and truncation gets worse exactly when
  someone has enlarged their text.

**Verified in widget tests.** Still requires manual checking on device:
TalkBack reading order, Voice Access naming, D-pad traversal.

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
// Right: destructive wording, plus a confirmation policy (IUX-008.7).
```

## Limits

- Text only. Icons and icon-only buttons are IUX-008.5.
- No asynchronous handling of its own: IUX-008.6.
- No confirmation flow: IUX-008.7.
- `expand` fills the width but does not cap it; use `IuxReadableWidth` when
  that matters.

## Evidence level

Standard for the accessibility guarantees. Context dependent for the
two-label design.

## Sources

- WCAG 2.2 — SC 4.1.2, SC 2.1.1, SC 2.4.7, SC 2.5.8, SC 1.4.4.
