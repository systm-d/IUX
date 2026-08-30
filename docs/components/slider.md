# Slider

## Purpose

`IuxSlider` holds one value from a continuous range.

**It is the component whose clause the platform can satisfy in full.** EN 301
549 V3.2.1 clause 11.5.2.7 asks that the current value *and any minimum or
maximum values of the range* be programmatically determinable. Nothing in this
library had a range, so nothing exercised it — every other component holds a
string, a boolean, or one option of a set.

## Use when

- The value is one the user **judges** rather than knows: a text size, a
  brightness, a tolerance.
- The ends of the range mean something, and seeing where you are between them
  is part of the answer.

## Do not use when

- **The number matters exactly.** An amount, a date, an age — those are fields.
  A slider asks the user to aim.
- **More than about a dozen steps.** The buttons become the only usable route
  and fifty taps is worse than typing.
- **For on and off.** That is `IuxSwitch`.

## API

```dart
IuxSlider(
  input: const IuxInputDescriptor(
    semantics: IuxInputSemantics(label: 'Text size'),
  ),
  value: settings.scale,
  min: 1,
  max: 2,
  divisions: 10,
  format: (double v) => '${(v * 100).round()}%',
  decreaseLabel: l10n.smaller,
  increaseLabel: l10n.larger,
  onChanged: settings.setScale,
)
```

### `format` is required, and so are the two labels

A screen reader speaks what it is given. `0.7` is the wrong answer when the
range is a price, a percentage or a temperature, and **the framework does not
know the unit**. The same requirement covers the ends, so the minimum and
maximum are announced in the caller's units too.

### `divisions` is required rather than defaulted

A continuous slider cannot be operated by a keyboard or a screen reader at all.
The step is a decision every caller has to take, not one this component can
guess. The value snaps to it, because an unsnapped drag reports a number the
buttons can never reach again.

## The buttons are not decoration

A control that can only be dragged is a **path-based gesture with no
single-pointer alternative**: WCAG 2.2 SC 2.5.1 outright, and unreachable by a
screen reader whatever its semantics say.

The minus and plus are what make the drag permissible. They are not optional and
there is no parameter to remove them.

This is also the **first and only path-based gesture in the library**.
`IUX-EN301549-002` recorded that there were none; this component amends it
rather than leaving the claim to rot.

## What it announces

| | |
| --- | --- |
| role | slider |
| name | the question |
| value | the current value, in the caller's units |
| minimum / maximum | both ends, in the caller's units |
| increased / decreased value | what it *would* become — so a step that changes nothing is heard, not met with silence |
| actions | increase, decrease |

## States

| State | Behaviour |
| --- | --- |
| default | the filled portion is the position |
| at either end | that direction's button is disabled, and the step announces no change |
| disabled | announced disabled; neither button nor drag responds |
| error | one message below, announced |

The value is **written out beside the bar**. A slider whose position is its only
readout is unreadable to anyone who cannot judge a bar against its ends, which
is most people at a glance.

## Limits

- **No visible thumb.** The filled portion is the position. At small widths that
  is a thinner distinction than a handle would be. It is not the only signal —
  the value is written out — but it is thinner.
- **A slider is for a judged value.** Enforced nowhere; a caller can use one for
  a price and nothing will stop them.
- **Past about a dozen steps** the buttons are the only usable route. Also
  documentation.
- **No device has heard this.** `IUX-MANUAL-001`. TalkBack adjusts a slider with
  a swipe up and down; whether that gesture reaches these actions is exactly
  what a device settles. **That the actions are advertised is not that they
  work.**

## Evidence level

Standard. Clause 11.5.2.7 is quoted, and the value, minimum and maximum are
asserted on the semantics node.

## Sources

- **EN 301 549 V3.2.1** — clause 11.5.2.7, read; see `IUX-EN301549-001`.
- WCAG 2.2 — SC 1.4.1, SC 2.5.1.
- `IUX-SLIDER-001`, and `IUX-EN301549-002` which it amends.
