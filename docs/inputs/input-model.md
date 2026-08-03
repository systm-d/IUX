# Input model

## Intention

Describe a field completely enough that a component can render it, announce it
and refuse an incoherent configuration — without knowing anything about the
application, and without ever deciding whether a value is acceptable.

```dart
const email = IuxInputDescriptor(
  semantics: IuxInputSemantics(label: l10n.emailAddress),
  requirement: IuxInputRequirement.required,
  helpText: l10n.emailHelp,
);
```

Only `semantics` is required. A field without an accessible name is announced
as "edit box" and nothing else, which tells the user where the caret is and not
what to type. Everything else defaults to the cautious value.

This mission delivers the model and the theme resolution. There is no field
widget yet — `IuxTextField` is IUX-010, selection controls are IUX-011.

## Dimensions, and why they are separate

| Dimension | Answers |
| --- | --- |
| `availability` | may the user change it, only read it, or neither |
| `requirement` | is an answer expected |
| `validation` | what is known about the current value, and what to say |
| `helpText` | what instruction stays on screen |
| `semantics` | what does assistive technology hear |

They are separate because they genuinely vary independently:

- **Availability is not requirement.** A read-only field can still be required:
  the value is already supplied and must not be cleared.
- **Requirement is not validity.** A required field that has never been checked
  is not invalid; it is unchecked. Rendering the two the same is how a form
  greets a user with errors before they have typed anything.
- **Validity is not a boolean.** "Not checked yet", "checking", "accepted" and
  "rejected" are four different answers, and collapsing the first two into
  "invalid" makes users correct something that was never wrong.

## Read-only is not disabled

This is the distinction the whole model turns on.

| | in focus order | announced | editable |
| --- | --- | --- | --- |
| `enabled` | yes | normally | yes |
| `readOnly` | **yes** | as read-only | no |
| `disabled` | no | as unavailable | no |

A disabled field leaves focus traversal, so a screen-reader user is never told
the value at all — they are not told it is fixed, they are simply not told. Use
`readOnly` whenever the value is still information the user needs: an order
reference they have to quote, an address computed from earlier answers.

The action model deliberately has no `readOnly`, on the grounds that read-only
describes a field rather than an action. This is the field.

## The parent owns validation

Whether a value is acceptable, what the message says and when it appears are
decisions this model records and never makes.

```dart
// Wrong: the field decides.
IuxTextField(validator: (v) => v.contains('@') ? null : 'Invalid');

// Right: the parent decides and tells the field what to render.
descriptor.copyWith(
  validation: IuxInputValidation.invalid(l10n.emailNeedsDomain),
)
```

A field that validated itself would eventually reject something the server
accepts, and the user would be told two different things by the same
application.

## No message is ever invented

Every user-facing string arrives already localised from the caller. IUX
composes none of them, so it cannot leak one language into another and cannot
ship a "This field is required" that says the wrong thing in the wrong tone.

## An error is never colour alone

`IuxInputValidation.invalid` takes a **required, non-empty** message. That is
the enforcement point: there is no way to express "this field is wrong" without
also saying what is wrong.

Two more signals reinforce it, so no single channel carries the error:

- the outline is thicker, not merely redder (see `theme.md`);
- the message is text, which survives greyscale, colour-vision deficiency and a
  screen reader.

## Help text survives an error

IUX shows the instruction **and** the error message. The common pattern —
replacing the helper line with the error — removes the sentence explaining how
to write a correct value at the exact moment the user has proved they need it.

## Invariants

Contradictions fail on an assertion in debug rather than being silently
corrected. Quietly repairing a contradiction hides the fact that the caller
believed something untrue.

| Invalid | Why | Checked in |
| --- | --- | --- |
| empty accessible name | an unnamed field is unusable with a screen reader | `IuxInputSemantics` |
| `invalid` with no message | an error carried by colour alone | `IuxInputValidation` |
| empty help text | reserves a line and says nothing | `IuxInputDescriptor` |
| empty hint or reason | null already means "none" | `IuxInputSemantics` |
| `disabled` + `invalid` | the user is told something is wrong and given no way to fix it | `IuxInputResolver` |

The last one is checked when the field resolves rather than in the constructor.
Dart cannot evaluate a field access on a constant object inside a `const`
constructor's assertion, and `const IuxInputDescriptor(...)` is worth more than
moving the check three frames earlier.

## What was deliberately left out

**`IuxInputValidation.copyWith`.** The named constructors *are* the
transitions. A copy that changed only the status would happily produce an
invalid field carrying its old success message — the exact drift the type
exists to prevent.

**An `operation` dimension.** The action model has one because an action has a
lifecycle. The only operation a field has is the validation of its own value,
which `validation` already models. Saving the form is the submit action's
lifecycle, not the field's.

**A `selected` dimension.** Selection belongs to a control that offers choices,
not to input in general. Putting it here would give every text field a
meaningless `selected: false`, which is what makes a screen reader announce
"not selected" and send the user looking for a selection that does not exist.
IUX-011 models it where it applies.

**A required-field marker.** Marking the rarer case is a form-level decision,
and the marker is caller-supplied text that has to be localised. IUX-012 owns
it.

**An assertion on `disabled` + `required`.** It looks like a trap — a form that
cannot be completed — but a field can legitimately be required in general and
unavailable right now, and whether the form can be submitted is the form's
question. IUX-012 owns it.

**A placeholder.** A placeholder is rendering, and IUX-010 adds it. The
accessible name being required here already prevents the trap it usually
carries: a field whose only name is its placeholder becomes an unlabelled box
the moment the user types.

## Limits

- The invariants are assertions, so they are debug-only. A release build with a
  contradictory descriptor renders something; it just may not make sense.
- The model describes a field; it renders nothing and validates nothing.
- Nothing here can tell whether a label is understandable, whether an error
  message says how to fix the value, or whether the help text is true.
- TalkBack, Voice Access and physical keyboard behaviour need a device. They
  are recorded as manual validations against IUX-010, where the widget exists.

## Evidence level

Context dependent for the dimension split, which is an IUX design decision.
Standard for the accessible name, for explained unavailability and for the
requirement that an error is not signalled by colour alone.

## Sources

- WCAG 2.2 — SC 1.4.1 Use of Color, SC 3.3.1 Error Identification, SC 3.3.2
  Labels or Instructions, SC 3.3.3 Error Suggestion, SC 4.1.2 Name, Role,
  Value.
- Android accessibility guidance on labelling and on disabled controls leaving
  the traversal order.
- Nielsen Norman Group — placeholders as labels, and error messages that
  explain the fix.
