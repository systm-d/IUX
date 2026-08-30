# Date field

## Purpose

`IuxDateField` collects a date as three named boxes: day, month and year.

**It is not a calendar, and that refusal is the component.** Issue #49 named
date entry as *the field with the most accessibility risk and the one IUX does
not cover*, and the risk is concentrated almost entirely in the calendar picker
most applications reach for.

## Why not a calendar

- A month grid is **forty-two targets** a screen-reader user arrows through to
  find one, with no way to jump.
- It collapses at 200% text, where a seven-column grid of touch targets does
  not fit a phone.
- Reaching one means **opening** something, and a component in this library may
  not touch `Navigator` — the standard forbids it, and the reason is that a
  component that navigates has taken a decision belonging to the application.
- Three labelled boxes are what accessibility audits ask for, and every user can
  already type into a box.

**The cost is real and is not hidden**: this does not look like what most people
expect, and it gives no help at all with a date far from today — a booking three
months out, a historical record. An application that needs a calendar should
build one and own its accessibility. This is the field for a date somebody
knows.

## Use when

- The user knows the date: a birth date, an expiry, a date on a document.

## Do not use when

- **The user is choosing from a range they need to see** — availability, a
  booking window. That is a calendar, and it is the application's.
- **Only a month or a year is wanted.** Three boxes where two are ignored is a
  question with a wrong shape.

## API

```dart
IuxDateField(
  input: const IuxInputDescriptor(
    semantics: IuxInputSemantics(label: 'Date of birth'),
    requirement: IuxInputRequirement.required,
    helpText: 'For example, 4 7 1990.',
  ),
  labels: IuxDateFieldLabels(day: l10n.day, month: l10n.month, year: l10n.year),
  value: form.birthDate,
  onChanged: form.setBirthDate,
)
```

### The value is `IuxDateParts`, not `DateTime?`

**This is the load-bearing API decision.** A user filling in a date has typed a
day and not yet a year, or a month that is 13 because they are mid-keystroke.
`DateTime?` holds neither: it is null, or a complete valid instant. A field
built on it has to invent a private half-state the parent cannot see, cannot
validate and cannot save as a draft.

`IuxDateParts` also carries **no time and no zone**. A `DateTime` used as a date
is a date that moves when the device crosses a boundary — a defect that surfaces
once a year in the field and never in a test.

`IuxDateParts.date` is null unless the three parts name a real day, checked by
round trip rather than a calendar table: Dart rolls 31 February into March, so a
constructed date that disagrees with its own parts is one the user did not name.

## What it announces

A **named container** carrying the question, holding three fields that each
announce their own name.

The question is deliberately *not* composed into each box: "Date of birth day"
is a sentence the framework would be writing in a language it cannot read, and
`no_composed_strings_test.dart` refuses it. A named container is the platform's
own mechanism for the same relationship — the analogue of a `fieldset` and its
`legend`.

Each part's name is **visible as well as announced**. A box labelled only to
assistive technology leaves a sighted user counting boxes to work out which one
is the month, and the order differs by country.

### The platform is not told these are numbers

`SemanticsInputType` offers `text`, `url`, `phone`, `search` and `email`, and
nothing for a number or a date. The keyboard is numeric; the announcement is
not. That is Flutter's limit, recorded rather than worked around.

## Validity is the parent's

The boxes accept what is typed. A field that silently refused `32` would be
deciding mid-keystroke that the user meant something else; one that corrected
`31/02` would be answering a question the user had not finished asking.

`onChanged` fires with incomplete and impossible dates. The parent is the only
thing that knows whether an error is due yet.

## States

| State | Behaviour |
| --- | --- |
| default | three boxes, empty or filled |
| focused | each box takes focus in reading order |
| disabled | all three disabled |
| read-only | values readable, not editable |
| error | one message for the whole field, below all three boxes |

There is one message, not three. Which box is wrong is usually not knowable —
`31/02` has no single guilty part.

## Limits

- **No calendar, no help with an unknown date.** The sharpest limit, stated
  first because it is the trade the component *is*.
- **Day, month, year in that order.** Not reordered by locale. A field that
  reordered itself would move the boxes under a returning user, and the visible
  names are what disambiguate them.
- **No two-digit-year expansion.** `90` is the year ninety. Guessing 1990
  invents data.
- **The error cannot point at a box.** One message for the field.
- **No device has heard this.** `IUX-MANUAL-001`. Whether three boxes with a
  numeric keyboard is genuinely easier with TalkBack than a calendar is an
  argument from audit practice, and this project has not watched either.

## Evidence level

Context dependent. The composition follows accessibility-audit practice rather
than a clause; the announcement requirements restate WCAG 2.2 SC 1.3.1, SC 3.3.2
and SC 4.1.2.

## Sources

- WCAG 2.2 — SC 1.3.1, SC 1.4.4, SC 3.3.2, SC 4.1.2.
- **EN 301 549 V3.2.1** — 11.5.2.5; see `IUX-EN301549-001`.
- systm-d/IUX#49.
- `IUX-DATE-001`.
