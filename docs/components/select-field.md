# Select field

## Purpose

`IuxSelectField` holds one answer chosen from a list that is too long to show
as a set of radio buttons.

**It exists because `IuxRadioGroup` stops working, not because a dropdown looks
tidier.** A radio group shows every option at once, which is the best
arrangement a chooser can have: nothing is hidden, nothing has to be opened, and
a screen-reader user hears "1 of 5" without acting. Somewhere past a dozen
options that stops being a help and becomes a wall, and this component trades
the overview for a shorter resting state.

That trade is a real cost, and it is the reason the two components take
**exactly the same arguments**. A question that outgrows a radio group becomes a
select by changing the class name and nothing else. The moment the APIs diverge,
the choice between them stops being about the user and starts being about
migration cost.

## Use when

- One question, one answer, and roughly twelve to thirty options.
- The options are known, finite and stable — countries, currencies, a status.

## Do not use when

- **Fewer than about a dozen options.** Use `IuxRadioGroup`. Hiding five options
  behind a control the user has to open is a cost with nothing bought.
- **More than about thirty.** A list nobody can scan is not fixed by collapsing
  it. Those need search — `IuxSearchField` and a result list.
- **Several answers at once.** That is a set of `IuxCheckbox`. A control that
  looks like this one and accepts many answers is how a user comes to believe
  they chose one thing when they chose three.
- **An action.** `IuxButton`. This holds a value; it does not do anything.

## API

```dart
IuxSelectField<String>(
  label: l10n.country,
  input: const IuxInputDescriptor(
    semantics: IuxInputSemantics(label: 'Country'),
    requirement: IuxInputRequirement.required,
  ),
  value: form.country,
  options: countries,
  placeholder: l10n.chooseACountry,
  onChanged: form.setCountry,
)
```

`options` is `List<IuxRadioOption<T>>` — the same option type the radio group
takes, so a list built for one works in the other unchanged.

## What a screen reader is told

Collapsed, **one stop** carrying:

| | |
| --- | --- |
| name | the question — `label` |
| value | the chosen option's own label, or nothing at all |
| state | collapsed, and required or read-only when it is |
| action | activate, which opens the list |

The name and the value stay **separate strings**. The platform joins them in
the user's own language and with its own punctuation; a framework that composes
`"Country, France"` has written a sentence in a language it cannot read. This is
the rule `no_composed_strings_test.dart` enforces across the library, and it is
asserted positively here.

An unanswered control announces **no value**, not the placeholder. "Choose a
country" read as a value tells the user the question has been answered and that
sentence is the answer.

Expanded, the control **becomes `IuxRadioGroup`** — the same options, the same
mutually-exclusive group, the same "1 of n", the same heading. None of the open
state is this component's own invention, which is the point: the arrangement a
screen-reader user meets was already tested before this component existed.

### There is no `comboBox` role, and the reason is upstream

`SemanticsRole.comboBox` is declared in Flutter's enum and its debug role checks
are **not written** — the framework maps it to `_unimplemented`, which throws
*"Missing checks for role SemanticsRole.comboBox"* on the first frame of any
debug or profile build. `spinButton`, `dragHandle`, `tooltip` and `hotKey` are
in the same state (flutter/flutter#159741).

So the node is a **button that carries a value and an expanded state**, which is
what the platform can speak today. A test asserts the absent role, so it will
fail — usefully — when the upstream checks land.

## States

| State | Behaviour |
| --- | --- |
| default | the chosen option, or the placeholder |
| focused | `IuxFocusable`'s ring, which reserves its space whether drawn or not |
| pressed | the field's hover and press tokens, as every field |
| disabled | announced disabled, leaves the focus order, and does not open |
| read-only | **stays in the focus order** and still announces its value |
| error | the message is shown *and* announced, below the help text |
| empty | refused — a select with no options is a question with no answers |

Read-only is not disabled. A value a keyboard or screen-reader user cannot reach
is a value they do not have.

## Accessibility

- **200% text.** The control grows; a long option name wraps rather than clips.
  Asserted by measuring the height at both scales — a control whose height does
  not move at 200% is clipping its own text.
- **Target.** `IuxTapTarget`, as every control.
- **Colour.** The answered and unanswered states differ in type style, and that
  difference carries nothing colour alone would have to: the announced value and
  the word itself both say whether the question is answered.
- **Focus.** One node, named twice — the announced node and the focusable region
  share a focus node. This is `IUX-A11Y-FOCUS-001`, and this component
  reproduced it on its first draft.

## What it refuses

- A value that is not among the options. Otherwise the collapsed control shows
  its placeholder while the application believes it has an answer, which is how
  a form submits a value the user never saw.
- No options at all. Render the reason there are none — `IuxEmptyState` — rather
  than a control the user can open and find empty.
- An empty label or an empty placeholder.

## Limits

- **Opening is one-way.** Once the list is open, choosing is what closes it.
  There is no cancel, because a radio cannot be un-chosen and an answered list
  has nothing left to offer. A user who opens a thirty-option list to look
  around scrolls past it rather than dismissing it. This is the sharpest cost of
  the composition and the first thing to revisit.
- **The options are not searchable.** That is the boundary at which this
  component is the wrong one; the documentation says so and nothing enforces it.
- **Nothing verifies that an option's label is distinguishable from its
  neighbours'.** Two options reading "Ireland" and "Iceland" in a list of thirty
  is a real hazard and it is the caller's.
- **No device has heard this.** `IUX-MANUAL-001` applies here as everywhere: the
  announcement above is what the semantics tree says, not what TalkBack says.

## Evidence level

Context dependent. The accessibility requirements restate obligations that are
external — EN 301 549 clause 11.5.2.5 and WCAG 2.2 SC 4.1.2 — and the choice of
arrangement is IUX's own.

## Sources

- WCAG 2.2 — SC 1.3.1, 1.4.1, 1.4.4, 2.1.1, 2.4.7, 4.1.2.
- EN 301 549 V3.2.1 — 11.5.2.5 (role, state, name, value), 11.5.2.11.
- `IUX-SELECT-001`, `IUX-LIST-SINGLECHOICE-001`, `IUX-A11Y-FOCUS-001`.
