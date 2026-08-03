# IuxTextField

## Purpose

Let the user type one value, know what it is for, and be told — in words — when
it is not accepted.

```dart
IuxTextField(
  input: IuxInputDescriptor(
    semantics: IuxInputSemantics(label: l10n.emailAddress),
    requirement: IuxInputRequirement.required,
    helpText: l10n.emailHelp,
    validation: state.emailValidation,
  ),
  content: IuxTextContent.email,
  controller: _email,
  onChanged: controller.emailChanged,
)
```

The widget is the second half of IUX-009. That mission decided what a field
*is*; this one decides what it looks like, how it behaves and what a screen
reader hears. It re-models nothing: `IuxInputDescriptor`,
`IuxInputValidation` and `IuxInputResolver` are used exactly as delivered.

## Use when

The user has to type something the application keeps — an address, a
reference, a message.

## Do not use when

- **You want a password.** There is no obscured mode, and adding one is not a
  parameter. An obscured field owes the user a way to reveal what they typed,
  otherwise a motor-impaired or dyslexic user cannot check a long password
  before submitting it. That reveal control is a second interactive element
  with its own name, state and announcement, so it is a component, not an enum
  value.
- **The value is chosen rather than typed.** A choice among known options is a
  selection control (IUX-011). A text field that only accepts six spellings of
  "yes" is a dropdown that has been made harder.
- **Nothing may ever change it.** A value that is fixed for all users under all
  conditions is a label and a value, not a control. Reach for
  `IuxInputAvailability.readOnly` only when it is genuinely a field that
  happens to be fixed *right now* — an order reference, an address computed
  from earlier answers.
- **You want the field to decide whether the value is acceptable.** There is no
  `validator`, and there will not be one. See below.

## API

| Parameter | Required | Note |
| --- | --- | --- |
| `input` | yes | the descriptor — name, availability, requirement, validation, help |
| `controller` | yes | the live text, created and disposed by the parent |
| `onChanged` | yes | called on every user edit |
| `placeholder` | no | an example, already localised, shown while empty |
| `content` | no | what kind of thing is being asked for. Defaults to `text` |
| `variant` | no | `outlined` or `filled`. Defaults to the theme's |
| `autofocus` | no | off by default, and it should usually stay off |
| `focusNode` | no | for a form that has to move focus into this field |

There is no colour, radius, border, elevation or duration parameter, and there
will not be one. An API that accepts a colour has already lost the contrast
guarantee: the theme can no longer be held responsible for something a call
site overrode.

### Why a controller and not a `value` string

A `value: String` field is a purer expression of "the parent owns the state",
and it is the wrong trade here. The caret and the composing region live in the
controller. Rebuilding the field from a plain string means re-seating the caret
on every keystroke, and the user correcting the middle of a word finds
themselves typing at the end of it — a defect that appears exactly when
someone is fixing the mistake the error message told them about.

The controller is still the parent's: it creates it, disposes it, and can read
or write it at any time. There is no internal fallback controller, because a
field that quietly made its own would be a field whose value the parent cannot
read.

### Why `onChanged` is required

It is how the parent learns that whatever it decided about the old value no
longer applies. A field whose changes nobody listens to is a field whose
validation state will drift out of date, and a stale "looks good" under a value
the user has since broken is worse than no message at all.

It fires for user edits only. A programmatic change through `controller` is the
parent's own doing and does not come back to it.

### `IuxTextContent` is one decision, not five

| Value | Keyboard | Capitalisation | Autocorrect | Autofill | Lines |
| --- | --- | --- | --- | --- | --- |
| `text` | text | sentences | on | — | 1 |
| `name` | name | words | **off** | name | 1 |
| `email` | email | none | off | email | 1 |
| `phone` | phone | none | off | telephone | 1 |
| `url` | url | none | off | url | 1 |
| `multiline` | multiline | sentences | on | — | grows from 3 |

Set separately, those are five chances to ship the field that capitalises the
first letter of an email address and then rejects it, or the one that
autocorrects a surname into a dictionary word. The caller names the content;
the widget decides what that implies, and can change its mind in a later
version without a migration at the call site.

The autofill hints are not a convenience. For a user with a motor impairment,
an address filled by the platform is an address not typed one character at a
time.

There is no `number`. "A number" is at least three fields — a quantity, a
formatted code, a currency amount — each with a different keyboard, grouping
and validation, and one value covering all three would be right a third of the
time.

## The label is attached, not merely adjacent

The visible name and the accessible name are the same string,
`IuxInputSemantics.label`. It is shown above the box and merged into the box's
semantic node, so a screen reader announces the field by name rather than as
"edit box".

There is **no floating-label mode and no label-as-placeholder mode.** A name
that disappears when typing starts leaves a user who has forgotten what the
field was with no way back — and that is precisely the moment they are checking
what they entered. It is also the mode that fails hardest at 200% text scaling,
where a shrinking label becomes unreadable at the exact size the user asked to
avoid.

There is no separate "visible label" parameter either. A button legitimately
reads `Delete` while announcing `Delete the March invoice`, because the button
sits in a row that supplies the rest. A field does not: two names for one box
is two things to remember.

## What a screen reader is told

| Signal | Source |
| --- | --- |
| name | `IuxInputSemantics.label` |
| role | `textField`, plus `inputType` from `content` |
| value | the controller's text |
| hint | `IuxInputDescriptor.accessibleHint` — the caller's hint, or the reason it is unavailable |
| required | the `isRequired` property, never a composed asterisk |
| read-only | the `readOnly` flag |
| unavailable | `enabled: false` |
| valid / invalid | `SemanticsValidationResult` |
| the error itself | a live region beside the field |

Required-ness is announced as a property rather than folded into the label,
because the platform speaks a property in the user's own language and IUX
cannot: a framework-authored "required" would be the wrong word, the wrong
language or both. The visible marker for required fields is a form-level
decision and belongs to IUX-012.

## States

| State | What changes |
| --- | --- |
| resting | the theme's outline on the theme's fill |
| hovered | a stronger outline. Never occurs on a touch-only device |
| focused | a focus ring, drawn outside the box in reserved space |
| read-only | no caret, no keyboard, a marker, and the read-only flag |
| disabled | recessed fill, dimmed content, out of the focus order |
| validating | the resting outline and the caller's message. **Not** an error |
| valid | a success outline and, if given, a message |
| invalid | a thicker outline, the message, and a live-region announcement |

There is no pressed state. A field is not activated by a press; a tap places
the caret, and the state that follows is focus.

## Read-only is not disabled, and has to look like it

`surface.subtle` and `surface.interactive` are distinct roles that every
palette IUX ships maps to the same colour — recorded as **IUX-SURFACE-001**. In
the `filled` variant, therefore, the fill separates a read-only field from an
editable one by nothing at all. (In `outlined` it does: `surface.subtle`
differs from `surface.base` on all four profiles.)

Five signals carry the distinction instead, and none of them is a hue:

1. **No caret.** `showCursor` is false, so focusing a read-only field puts no
   blinking bar in it.
2. **No keyboard.** Tapping it opens no software keyboard, which is the fastest
   feedback a touch user can get.
3. **A marker.** A small lock glyph sits at the reading end of the box. It is a
   *shape*, so it survives greyscale, a colour-vision deficiency and a printed
   screenshot, and — unlike the four other signals — it is there before the
   user has tried to do anything.
4. **No placeholder.** A field nobody may fill is not prompted to be filled.
   Prompting for input the user may not give is an instruction they cannot
   follow.
5. **The `readOnly` semantic flag**, which the platform speaks in the user's
   own language.

The marker is excluded from the semantic tree: the flag already says it, and an
icon carrying information the semantics do not is information a screen-reader
user never receives.

A read-only field **stays in the focus order** and stays selectable and
copyable, which is the whole reason it is not `disabled`. A disabled field
leaves traversal, so a screen-reader user is never told the value at all — they
are not told it is fixed, they are simply not told.

## Errors

**The parent owns validation.** The widget has no `validator` and never decides
that a value is right or wrong. A field that validated itself would eventually
reject something the server accepts, and the user would be told two different
things by the same application.

When the parent says a value is invalid:

- **The message is required.** `IuxInputValidation.invalid` takes a non-empty
  string, so there is no way to express "this is wrong" without saying what is
  wrong.
- **The outline thickens** (`strongBorderWidth`) as well as changing colour, so
  the error survives greyscale.
- **The fill never turns red.** A red container puts the error in the one
  channel a user with a colour-vision deficiency cannot read, and drags down
  the contrast of the very value the user is trying to fix.
- **The field does not move.** The extra border width is paid for out of the
  padding, so the box keeps its size and the caret stays where the user left
  it. Only the message below appears.
- **The message is a live region**, announced once, in place. Never
  `SemanticsService`: Android deprecated `announceForAccessibility` because it
  clears TalkBack's speech queue and cuts off whatever the user was listening
  to.

**Help text survives an error.** IUX shows the instruction *and* the message.
Replacing the helper line with the error — the common pattern — removes the
sentence explaining how to write a correct value at the exact moment the user
has proved they need it.

**A pending check is not an error.** `validating` shows the caller's message
with the resting outline and reports `SemanticsValidationResult.none`. Showing
an error while the answer is unknown makes the user correct something that was
never wrong.

## The placeholder is a prompt and nothing more

It is shown while the field is empty and editable, and it is hidden from
assistive technology. Repeating it would make every empty field announce two
names, and the first thing a screen-reader user needs is the one that will
still be there after they type.

Anything a user must know in order to answer therefore belongs in two places,
not in the placeholder:

- `IuxInputDescriptor.helpText`, which stays on screen;
- `IuxInputSemantics.hint`, which a screen reader reads after the name.

Passing the same sentence to both is the intended usage, and it is what
`input-model.md` anticipated when it said format requirements belong in the
hint "and also on screen".

## Accessibility

- **Named.** There is no way to build an unnamed field: the model requires the
  label, and this widget both shows it and attaches it.
- **Target.** The box meets the resolved touch-target floor at every density
  and grows with a comfortable preference.
- **Focus.** Visible, drawn outside the box, and the space is reserved whether
  or not the ring is painted — so gaining focus moves nothing. A moving target
  is hard to follow, and for a screen-magnifier user it can push the element
  off screen. The ring survives an error, because the field showing an error is
  exactly the field a keyboard user is about to correct.
- **Keyboard.** Reachable by traversal; typing is the activation. Enter and
  Space are deliberately *not* intercepted — a field that treated Space as an
  activation would be a field you cannot put a space in.
- **Text scaling.** Verified at 200% on a 320×480 screen with a label, help
  text and an error all present. No line limits and no ellipsis anywhere: a
  truncated instruction tells the user less than nothing, and truncation gets
  worse exactly when someone has enlarged their text. The read-only marker
  scales with the text rather than shrinking into a dot.
- **Colour.** Never the only carrier. Errors carry a message and a thicker
  outline; read-only carries a shape and four behaviours.
- **Reduced motion.** The only animation is the state-change tint on the
  container, resolved through `IuxMotionPolicy`. Under
  `IuxMotionPreference.none` it becomes instant — the colours still change,
  they simply arrive at once.
- **RTL.** Renders and edits right-to-left; the marker sits at the reading end.

**Verified in widget tests.** Still requires manual checking on device:
TalkBack reading order across label, field, help and error; whether the
read-only flag is spoken usefully; Voice Access naming; the software keyboard
variants; and physical-keyboard traversal on a real Android device.

## Anti-patterns

```dart
// Wrong: the field decides what is acceptable.
IuxTextField(validator: (v) => v.contains('@') ? null : 'Invalid')

// Right: the parent decides and tells the field what to render.
IuxTextField(
  input: descriptor.copyWith(
    validation: IuxInputValidation.invalid(l10n.emailNeedsDomain),
  ),
  ...
)
```

```dart
// Wrong: the placeholder is doing the label's job. It vanishes on the first
// keystroke, and with it the only clue what the box was for.
IuxTextField(
  input: IuxInputDescriptor(semantics: IuxInputSemantics(label: '')),
  placeholder: 'Email',
)

// Right: the name is permanent; the placeholder is an example.
IuxTextField(
  input: IuxInputDescriptor(
    semantics: IuxInputSemantics(label: l10n.emailAddress),
  ),
  placeholder: l10n.emailExample,
)
```

```dart
// Wrong: hiding a value the user still needs.
availability: IuxInputAvailability.disabled   // for an order reference

// Right: they can read it, focus it and copy it; they cannot change it.
availability: IuxInputAvailability.readOnly
```

```dart
// Wrong: the instruction is replaced by the error, so the user is told what
// is broken and no longer told how to fix it.
helpText: hasError ? null : l10n.emailHelp

// Right: IUX shows both. Always pass the instruction.
helpText: l10n.emailHelp
```

## Limits

- **No obscured / password mode.** See "Do not use when".
- **No character counter and no `maxLength`.** A counter is caller-supplied
  localised text ("12 of 40", "٤٠ / ١٢") and a limit that truncates silently is
  a data-loss bug. Both belong with the form patterns that know what the limit
  means.
- **No `onSubmitted` and no keyboard action control.** What "Done" should do,
  and whether the next field or the submit button follows, are questions only a
  form can answer. IUX-012 owns them.
- **No prefix, suffix, unit or currency slot, and no clear button.** No
  demonstrated need yet, and each would add an element with its own contrast,
  target-size and naming obligations.
- **Help text and the error are adjacent nodes, not an association.** Flutter
  has no `aria-describedby` equivalent, so a user landing directly on the field
  hears the label and the hint but not the on-screen help until they move to
  it. Pairing `helpText` with `IuxInputSemantics.hint` is the workaround, and
  it is a workaround.
- **The selection highlight is not an IUX token.** `IuxSemanticColors` has no
  text-selection role, so the highlight comes from the Material theme IUX
  derives. Its contrast against the value is therefore not measured by IUX.
  The caret is: it takes the value's own colour, which is the one already
  measured against this background, and thickens with the theme's strong
  border under high contrast.
- **`IuxInputTheme` is not installed by `IuxTheme.resolve`.** That is IUX-009's
  recorded limitation, not this widget's. Until it lands, `IuxInputTheme.of`
  falls back to its defaults, so the `variant` default is `outlined` whatever
  the configuration says. Passing `variant` explicitly always works.
- **The read-only marker is a judgement.** A lock glyph is a widely used
  convention, not a measured optimum, and it has not been validated with users.
  It is the honest answer to IUX-SURFACE-001; separating `surface.subtle` from
  `surface.interactive` in the palettes would be a better one.
- **Hover exists and never happens.** It is carried for parity with the button.
  On a touch-only Android device it can only ever reinforce something already
  available elsewhere.
- ~~`_IuxFieldSemantics` composes `Semantics` directly~~ — **Fermé.** Le runtime expose désormais les helpers manquants (`IuxSemantics.selection`, `.radioGroup`, `.field`, `.route`, `.contentAction`, `.contentContainer`) et le composant les utilise. Voir `docs/accessibility/semantics.md`.
- **Historique.** `IuxSemantics` has no
  field helper: every existing helper sets `excludeSemantics: true`, and
  excluding the subtree here would delete the set-text, set-selection and
  move-cursor actions a screen reader needs in order to edit at all. Lifting a
  `IuxSemantics.field(...)` out of this file is worth doing before the second
  input component exists.
- **No catalog entry yet.** `apps/catalog` was outside this mission's scope.

## Evidence level

| Claim | Level |
| --- | --- |
| A field needs a programmatically associated name | Standard — WCAG 2.2 SC 1.3.1, 3.3.2, 4.1.2 |
| A placeholder is not a label | Strong guidance — Nielsen Norman Group; WCAG SC 3.3.2 |
| An error must be identified in text, not colour | Standard — WCAG 2.2 SC 1.4.1, 3.3.1, 3.3.3 |
| Focus must be visible and must not move the layout | Standard — WCAG 2.2 SC 2.4.7, 2.4.11 |
| Text must survive 200% scaling | Standard — WCAG 2.2 SC 1.4.4 |
| The target floor applies to the field | Standard — WCAG 2.2 SC 2.5.8 |
| Read-only stays in the focus order; disabled does not | Standard — Android accessibility guidance |
| A live region rather than an announcement | Standard — Android deprecated `announceForAccessibility` |
| Help text should survive an error | Strong guidance — Baymard, NN/g on form error recovery |
| One content kind rather than five settings | Context dependent — IUX API design |
| A lock glyph as the read-only marker | Hypothesis — convention, not validated |
| Three lines as the multi-line opening height | Hypothesis |

## Sources

- WCAG 2.2 — SC 1.3.1, 1.4.1, 1.4.3, 1.4.4, 1.4.11, 2.4.7, 2.4.11, 2.5.8,
  3.3.1, 3.3.2, 3.3.3, 4.1.2.
- Android accessibility guidance on labelling, on disabled controls leaving the
  traversal order, and on live regions.
- Nielsen Norman Group — placeholders as labels; error messages that explain
  the fix.
- Baymard Institute — inline validation and form error recovery.
- `docs/inputs/input-model.md`, `docs/inputs/theme.md`.
- `docs/components/component-standard.md` §2, §3, §5, §6, §7, §11.
