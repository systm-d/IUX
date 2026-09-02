# Comparison roles

## Intention

Say which side of a stated reference a reading fell on, without asserting a hue
and without judging the reading.

## Roles

| Role | Meaning |
| --- | --- |
| `above` | the reading sits on the upper side of its reference |
| `at` | the reading is level with its reference |
| `below` | the reading sits on the lower side of its reference |

Each role provides `content`, `surface`, `border` and `mark`.

Three, and the number is arithmetic rather than taste: a quantity compared with
a reference is above it, level with it, or below it. There is no fourth side,
so nothing will arrive asking for one.

## Why these are not the feedback roles

`feedback` names four categories of **news** — something worked, something is
about to stop working, something failed. A reading two degrees above its
reference is none of those, and drawing it through `feedback.error` to obtain
the red the eye expects asserts that a warm summer is a malfunction. That is a
judgement, and a judgement shipped as a colour is one the user has no way to
argue with.

A direction is a fact about arithmetic the caller already performed: two
numbers were compared and one was larger. Whether that is good news is not
something the framework knows, and it belongs in the words.

See [../decisions/ADR-0013-a-reading-is-compared-not-judged.md](../decisions/ADR-0013-a-reading-is-compared-not-judged.md).

## Colour is not the direction

These roles never state that above is warm and below is cool. They state which
side of a reference a reading fell on, and a theme decides the rendering.

That is why the `mark` field is part of the contract rather than left to the
component. The reading beside a pill *usually* carries a sign — `+2.1 °C` reads
as "above" without any colour at all — but "usually" is not a guarantee the
framework can make: `IuxValue.above('2.1 °C', …)` compiles, and so does every
locale's formatting of a deviation. A mark that is part of the contract is
harder to forget than one that is optional.

The shipped mappings put the two directions between 30.4 and 9.9 apart in Oklab
×100, and between 22.7 and 6.5 apart under the worst of the three simulated
dichromacies — thinnest in the dark high contrast profile, because contrast on a
dark ground is bought by lightening and a lightened hue has less chroma to
spend. The measurements live in `test/themes/palette_perception_test.dart`.

## Example

```dart
final comparison = IuxSemanticColors.of(context).comparison.above;

Container(
  color: comparison.surface,
  child: Row(children: [
    Icon(Icons.arrow_upward, color: comparison.mark),
    Text('+2.1 °C', style: TextStyle(color: comparison.content)),
  ]),
);
```

In practice, use `IuxValueIndicator`, which resolves all four and carries the
accessible name.

## Counter-example

```dart
// Wrong: the direction exists only in the hue.
Container(color: comparison.surface, child: const Text('2.1 °C'));

// Wrong: the direction is a judgement, and the judgement is not the
// framework's to make.
IuxStatus.error('Très sec')
```

## Rules

1. A comparison role is always accompanied by a mark, wording, or both.
2. The reference has to be named in the words. "Above" says nothing; "2.1
   degrees above the 1991 to 2020 normal" says what was compared with what.
3. `at` is neutral in every shipped mapping, and should stay neutral in a brand
   one. A coloured pill on every row of a list is a pill users learn to skip.

## Limits

- These roles cover appearance. What counts as "above" is a threshold the
  caller chooses; IUX is never told the numbers and could not check them.
- In the two dark profiles the shipped mapping renders `above` and `below` in
  the same colours the feedback content roles take, on the same surface. That
  is recorded in ADR-0013 rather than avoided: paling them one rung to make the
  roles numerically distinct was measured and cost the separation between the
  two *directions*, which is the separation a reader actually has to make.
- Three sides will not fit a domain that wants a magnitude as well — "far
  above" is not a fourth direction, it is a bigger number, and it belongs in the
  reading.

## Evidence level

Standard for the non-reliance on colour. Context dependent for the three-role
taxonomy, which is IUX governance.

## Sources

- WCAG 2.2 — SC 1.4.1 Use of Color, SC 1.4.3, SC 1.4.11.
- `docs/decisions/ADR-0013-a-reading-is-compared-not-judged.md`.
- `test/themes/palette_perception_test.dart`, for the measurements quoted here.
