# Comparison roles

## Intention

Offer an application the hues it needs to mark a reading that has been compared
with something — without asserting what any of them means, and without judging
the reading.

## Roles

| Role | Meaning |
| --- | --- |
| `neutral` | a reading level with its reference: nothing to interpret |
| `one` | an accent. Means nothing on its own |
| `two` | an accent. Means nothing on its own |
| `three` | an accent. Means nothing on its own |
| `four` | an accent. Means nothing on its own |

Each role provides `content` and `surface`.

Four accents and no order among them. `one` is not first among equals and
nothing about its name means warmer, worse or larger — the same vocabulary
shape `avatarAccent` has, and for the same reason. Four, because IUX ships four
non-neutral hue families and a fifth would be new primitives measured across
four profiles under three simulated dichromacies, which is a mission rather
than a paragraph.

## Why these are not the feedback roles

`feedback` names four categories of **news** — something worked, something is
about to stop working, something failed. A reading two degrees above its
reference is none of those, and drawing it through `feedback.error` to obtain
the red the eye expects asserts that a warm summer is a malfunction. That is a
judgement, and a judgement shipped as a colour is one the user has no way to
argue with.

A comparison is a fact about arithmetic the caller already performed: two
numbers were compared and one was larger. Whether that is good news is not
something the framework knows, and it belongs in the words.

See [../decisions/ADR-0013-a-reading-is-compared-not-judged.md](../decisions/ADR-0013-a-reading-is-compared-not-judged.md).

## Why a side of the reference does not pick a role

These roles used to be `above`, `at` and `below`, which put a warm hue on one
side of every reference and a cool one on the other. One application disproves
that, and it is the application the roles were built for: rainfall above its
normal is *wetter* and reads blue, rainfall below it is *drier* and reads
amber, and a temperature below its normal is *colder* and reads the same blue
as the wet rain. Two of those are above their reference and two below, and the
hues cross the axis rather than following it.

What decides the hue is what the quantity means, and that is the application's
to know. `IuxValueDirection` still exists and is still three members; it is
arithmetic, and it selects nothing here. The one exception is `neutral`, which
`IuxValue.at` resolves because a reading level with its reference has nothing to
interpret and therefore takes no accent at all.

See [../decisions/ADR-0015-the-sign-is-not-the-meaning.md](../decisions/ADR-0015-the-sign-is-not-the-meaning.md).

## Colour is never the signal, and here it cannot be

`IuxValue` cannot be built without `meaning`, the word that reads the deviation,
and the word may not repeat the reading. That is not a style rule with a
compiled backstop; it is the only reason these roles are safe to ship.

The four accents reuse the four hue families `avatarAccent` spends, so they
inherit the collision `IUX-PALETTE-PERCEPTION-001` measured. Taken this round in
Oklab ×100, the closest pair under deuteranopia:

| profile | closest pair | apart |
| --- | --- | --- |
| light standard | one and three | 2.2 |
| dark standard | one and four | 1.5 |
| light high contrast | one and three | 1.1 |
| dark high contrast | one and four | 0.4 |

Every profile has a pair below the threshold most people notice side by side.
The measurements live in `test/themes/palette_perception_test.dart`.

## Two grounds, one colour

`content` paints the reading inside the capsule *and* the word on the page
beside it, so the theme holds it to 4.5:1 twice. That is why there is one role
rather than two: a second role whose value is always equal to the first is a
role nobody can tell has been measured — the defect `action.tertiary` shipped
once already.

There is no outline role. The capsule's extent carries nothing; what carries the
information is text, twice, at 4.5:1. The shipped tints stand between 1.07 and
1.28 from the page, which is a wash rather than an object, deliberately: a
capsule at 3:1 is a bordered box in everything but name, and thirty of them down
a column is a screen of alarms.

## Example

```dart
final comparison = IuxSemanticColors.of(context).comparison.three;

Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
  DecoratedBox(
    decoration: ShapeDecoration(
      color: comparison.surface,
      shape: const StadiumBorder(),
    ),
    child: Text('-42 mm', style: TextStyle(color: comparison.content)),
  ),
  Text('plus sec', style: TextStyle(color: comparison.content)),
]);
```

In practice, use `IuxValueIndicator`, which resolves both roles and carries the
accessible name.

## Counter-example

```dart
// Wrong: the meaning exists only in the hue.
Container(color: comparison.surface, child: const Text('-42 mm'));

// Wrong: the deviation is a judgement, and the judgement is not the
// framework's to make.
IuxStatus.error('Très sec')

// Wrong: one accent for two senses. Nothing refuses it, and a reader scanning
// the column learns nothing from the colour.
IuxValue.above('+51 mm', meaning: wetter, label: …, accent: IuxValueAccent.one)
IuxValue.above('+2.1 °C', meaning: warmer, label: …, accent: IuxValueAccent.one)
```

## Rules

1. A comparison role is always accompanied by the word that reads it.
   `IuxValue.meaning` is required for exactly this.
2. The reference has to be named in the words. "Above" says nothing; "2.1
   degrees above the 1991 to 2020 normal" says what was compared with what.
3. One accent, one sense, across a whole application. Nothing enforces it.
4. `neutral` stays neutral in a brand mapping. A coloured capsule on every row
   of a list is a capsule users learn to skip.

## Limits

- These roles cover appearance. What counts as "level with" is a threshold the
  caller chooses; IUX is never told the numbers and could not check them.
- In the two dark profiles the shipped mapping renders the accents in the same
  colours the feedback content roles take, on the same surface. That is
  recorded in ADR-0013 rather than avoided.
- **Two of the four accents are one colour to a reader with a dichromacy, in
  every profile.** Measured above. The required word is the mitigation and
  nothing more can be done inside a palette of four hue families.
- The capsule's tint is below 3:1 against the page, on purpose. An application
  that needed the capsule's boundary to *mean* something would not get it here.

## Evidence level

Standard for the non-reliance on colour. Context dependent for the four-accent
taxonomy, which is IUX governance. Measured for the separations and the
contrast ratios quoted here.

## Sources

- WCAG 2.2 — SC 1.4.1 Use of Color, SC 1.4.3, SC 1.4.11.
- `docs/decisions/ADR-0013-a-reading-is-compared-not-judged.md`.
- `docs/decisions/ADR-0015-the-sign-is-not-the-meaning.md`.
- `test/themes/palette_perception_test.dart`, for the measurements quoted here.
