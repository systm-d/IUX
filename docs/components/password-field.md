# IuxPasswordField — a secret, and the switch that shows it

```dart
IuxPasswordField(
  input: IuxInputDescriptor(
    semantics: IuxInputSemantics(label: l10n.personalAccessToken),
    requirement: IuxInputRequirement.required,
    helpText: l10n.tokenHelp,
    validation: state.tokenValidation,
  ),
  purpose: IuxSecretPurpose.token,
  revealLabel: l10n.showToken,
  controller: _token,
  onChanged: controller.tokenChanged,
)
```

A value that must not be on screen by default, and a labelled switch under it
that shows it. Everything else — the visible label, help text, validation
message, focus ring, variants — is `IuxTextField`'s, unchanged.

## Use when

Anything that would be a problem on a screen someone else can see: a password,
a token, an API key, a recovery code.

## Do not use when

- **The value is not secret.** A licence plate or a reference number is not a
  credential because it looks like one. Concealing it costs every user a check
  they did not need.
- **You want a PIN pad or a one-time code.** A row of single-digit boxes is a
  different component with its own focus and paste behaviour. This is not it.

## Why a component and not a flag

`IuxTextContent` refused a `password` value before this existed, in these words:
an obscured field owes the user a way to reveal what they typed — otherwise a
motor or dyslexic user cannot check a long password before submitting it — and
that reveal control is a second interactive element with its own name, state
and announcement. The first application migrated onto IUX needed a token field
and reached the same conclusion on its own (systm-d/IUX#67).

`IuxTextField` still cannot conceal a value from outside this package. The
settings a secret needs reach it through an internal constructor that only this
component uses, and a test checks that no public `IuxTextField` configuration
ever obscures.

## The reveal control is a labelled switch, not an eye

The eye icon inside the field is the obvious design and it was refused.

| | eye icon in the field | labelled switch under it |
| --- | --- | --- |
| what the user reads | a glyph whose meaning varies between applications — the open eye means "hidden" in some and "shown" in others | "Show password" |
| what a screen reader says | a name the icon never shows | "Show password, switch, off" |
| target | a 48 dp square inside a small-screen field, taking width from the text | a full switch row with its own floor |
| `IuxTextField`'s rule | breaks it: no control inside the box (IUX-TEXTFIELD-GAPS-001) | keeps it |
| implementation | a new control | `IuxSwitch`, already measured |

It is a switch rather than a checkbox by `IuxSwitch`'s own rule: revealing
takes effect the moment it moves and is undone the same way, and there is no
Save button it waits for.

The switch's name does not change with its state. The state is announced as on
or off; a name that flipped between "Show" and "Hide" would have to be read
again each time to know what the control does now.

## `IuxSecretPurpose`

Required, because the three look the same on screen and are opposites to a
password manager.

| Purpose | Autofill | For |
| --- | --- | --- |
| `current` | offers the saved password | signing in |
| `created` | may generate one, offers to save it | signing up, changing a password |
| `token` | nothing at all | a token, API key or code pasted from elsewhere |

A token declared as a password is offered to be saved *as the account's
password*. A user who accepts has overwritten it.

## Behaviour

- **Concealed on arrival, always.** No parameter starts it revealed: showing a
  credential is decided by the user, in the moment, knowing who can see their
  screen.
- **The reveal state is the widget's.** The value is the parent's, as for every
  IUX field. Whether it is currently drawn as bullets is not a fact about the
  value, any more than focus is.
- **Revealing does not move focus.** Clearing a search returns focus to the box
  because the user is about to type. Revealing is for reading; a screen-reader
  user moves to the field, which now speaks the value.
- **One keyboard in both states.** The visible-password keyboard throughout, so
  revealing never re-lays the keyboard out mid-word.
- **Nothing leaves the box.** Suggestions, autocorrect, capitalisation, smart
  punctuation and the keyboard's own learning are off in both states. Each would
  put the secret somewhere other than this field.
- **The switch follows the field.** Disabled with a disabled field. Enabled with
  a read-only one — a generated token shown once, to be copied, is exactly what
  someone needs to reveal and may not edit.

## Accessibility

- The field announces its name, required state, validation and that it is
  obscured; the value is not exposed while concealed and is once revealed.
- The switch is visible text and a switch role with its state.
- Focus order is the field, then the switch.

## Limits

- **Measured under `flutter_test` only.** What a password manager actually
  offers for each purpose, what TalkBack says for an obscured field, and whether
  the keyboard truly stays put when the value is revealed are platform
  behaviours. The catalog's password panel lists what to check on a device;
  `IUX-MANUAL-001`.
- **No confirmation field, strength meter or rule list.** Those belong to the
  form that knows the rules, and a strength meter that disagrees with the
  server is two answers to one question.
- **The reveal does not re-conceal on its own** — not on submit, not when the
  application goes to the background. Whether it should is a real question and
  it is left open rather than decided by default.
