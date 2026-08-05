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
| read-only | the `readOnly` flag — but see below: a disabled field carries it too |
| unavailable | `enabled: false`, and the absence of the tap and focus actions. This, not the flag above, is what separates read-only from disabled |
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

This page used to list five signals as carrying read-onlyness. Four of them do
not, and the fifth does not do what was claimed. What follows is measured
(`test/components/iux_text_field_test.dart`,
`test/inputs/iux_input_theme_test.dart`) rather than asserted.

### The fill, and what changed

`surface.subtle` and `surface.interactive` are distinct roles that every
shipped palette used to map to **one** primitive — **IUX-SURFACE-001**. In the
`filled` variant a read-only field was therefore byte-identical to the editable
field beside it: same fill on all four profiles, same value colour on all four,
and the same outline on three of them, because `border.standard` and
`border.interactive` are also one colour outside light standard. A lock glyph
was the only thing between a box you may type in and one you may not.

**This is now closed.** `surface.interactive` has its own primitive on each
profile, so `surface.base`, `surface.subtle`, `surface.interactive` and
`surface.disabled` are four colours everywhere.

It does not follow that the fill carries the distinction. No two steps of the
neutral ramp reach 3:1 against each other — the widest separation between any
two of these four roles on any profile is **1.86:1**, and on dark standard
`surface.subtle` and `surface.disabled` are still the *same* colour, so a
read-only field and a disabled one have one fill there. A fill is legible as a
difference only when the two boxes are adjacent, which a form rarely arranges.
Closing IUX-SURFACE-001 stopped the fill *contradicting* the state. It does not
make the fill announce it, and no arrangement of this ramp could: a signal that
tops out at 1.86:1 is not a signal. What carries the distinction is the marker,
the outline, the value's own strength and the semantic availability — the four
rows marked "yes" below.

### What separates read-only from *editable*

| Signal | Present before the user acts? |
| --- | --- |
| no caret (`showCursor` false) | no — only once focused |
| no software keyboard on tap | no — only once tapped |
| no placeholder | only if a placeholder was passed and the field is empty |
| the lock marker | **yes** |
| the `readOnly` semantic flag | yes, to a screen reader |

### What separates read-only from *disabled*

This is the harder question, and it is the one the old list did not answer. A
disabled field has **no caret, opens no keyboard and shows no placeholder
either**, so three of the five signals above are silent here.

| Signal | Separates read-only from disabled? |
| --- | --- |
| no caret | no — disabled has none either |
| no keyboard | no — disabled opens none either |
| no placeholder | no — disabled shows none either |
| the lock marker | **yes.** Only a read-only field wears it |
| the `readOnly` semantic flag | **no.** See below |
| the value's own colour | yes — full strength against `content.disabled` |
| the outline | yes — `border.standard` against `border.disabled` |
| `enabled` in the semantic tree, and the tap and focus actions | **yes** |

**The `readOnly` flag is on both.** Flutter's `TextField` hands the editing
widget `readOnly: widget.readOnly || !_isEnabled`, and semantic flags merge
upward by disjunction, so a disabled field publishes `isReadOnly` whatever IUX
asks for. That is not *wrong* — a disabled field genuinely cannot be edited —
but it means the flag cannot be what tells a screen-reader user which of the two
they have landed on. `enabled: false` and the absent tap and focus actions are
what do that, and they are unambiguous: a read-only field is announced, is
reachable and answers a tap; a disabled field is announced as unavailable and
answers nothing.

The marker is excluded from the semantic tree: the flag already says it, and an
icon carrying information the semantics do not is information a screen-reader
user never receives. That is why the shape and the semantics are two separate
guarantees rather than one — the sighted user gets the glyph, the screen-reader
user gets the availability, and neither depends on the other.

A read-only field **stays in the focus order** and stays selectable and
copyable, which is the whole reason it is not `disabled`. A disabled field
leaves traversal, so a screen-reader user is never told the value at all — they
are not told it is fixed, they are simply not told.

### Measured

Every ratio below is against the fill the field itself paints, on the `filled`
variant, which is the surface the eye actually receives.

| Profile | read-only value | read-only marker | read-only outline | disabled value |
| --- | --- | --- | --- | --- |
| light standard | 16.27:1 | 7.12:1 | 3.43:1 | 3.16:1 |
| light high contrast | 18.08:1 | 12.72:1 | 12.72:1 | 5.76:1 |
| dark standard | 13.79:1 | 8.61:1 | 3.10:1 | 3.10:1 |
| dark high contrast | 14.78:1 | 11.16:1 | 8.61:1 | 4.28:1 |

Text is held to 4.5:1 and the outline and the marker to 3:1. Disabled content
is held to 3:1 rather than taking the WCAG exemption, because a field the user
cannot fill is still one they have to read to understand the form.

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
- **The message is a live region when it *appears*,** announced once, in place.
  Never `SemanticsService`: Android deprecated `announceForAccessibility`
  because it clears TalkBack's speech queue and cuts off whatever the user was
  listening to.
- **A message the field arrived carrying is read, not announced.** A live region
  is for a status *change* — SC 4.1.3 is about a message that appears in
  response to something the user did. One that was already there when the field
  came on screen is content: the user did not do anything, and speaking it puts
  an utterance in the same frame as whatever mounted the field. That is how
  `IuxGuidedForm` came to speak twice for one step change
  (IUX-GUIDED-FORM-LIVE-001), and it is also why a form arriving with three
  rejected fields no longer fires three live regions at once. The message keeps
  its own labelled node either way, so nothing became unreachable; it loses only
  the flag. The same sentence coming back after the user changed the value *is*
  news, and is announced.

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
  outline. Read-only carries a shape — the marker — which is the only signal
  that separates it from a disabled field before the user has tried to do
  anything; the behaviours it also has (no caret, no keyboard, no placeholder)
  separate it from an *editable* field and are equally true of a disabled one.
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
  Its *contrast* is measured on all four profiles; whether a lock is the right
  shape is not, and a lock arguably reads as "unavailable", which is what the
  neighbouring state means.
- **A disabled field still publishes `isReadOnly`,** because Flutter resolves
  the flag as `widget.readOnly || !_isEnabled` and merged flags disjoin. IUX
  cannot clear it from above. It is accurate but useless as a discriminator;
  `enabled` is the one that works. Closing this would need
  `IuxSemantics.field` to be able to force the flag false, which is the
  accessibility runtime's decision and not this component's.
- **`surface.subtle` and `surface.disabled` are one colour on dark standard,**
  so read-only and disabled share a fill there. Not fixed, and deliberately:
  every alternative rung drops `border.interactive` below the 3:1 an outline
  owes under SC 1.4.11, and buying a 1.3:1 fill difference with an unreadable
  outline is a worse interface than the one it replaces.
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
| The marker, the outline and the value's strength must reach the WCAG floors | Standard — WCAG 2.2 SC 1.4.3, 1.4.11; measured per profile |
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
