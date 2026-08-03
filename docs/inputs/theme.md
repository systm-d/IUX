# Input theme

## Intention

Turn a field descriptor into paintable values, in one place, so the mapping
cannot drift between the text field, the checkbox and whatever comes next.

```dart
final tokens = IuxInputResolver.resolve(context, descriptor, focused: hasFocus);
```

An input widget reads `IuxInputTokens`. It never reaches for a semantic role
itself, and there is no colour, radius, elevation or duration parameter — an
API that accepts a colour has already lost the contrast guarantee, because the
theme can no longer be held responsible for something a call site overrode.

## Both variants draw an outline

| Variant | What separates it from the page |
| --- | --- |
| `outlined` | a border the theme holds to 3:1 |
| `filled` | the same border, over a fill |

The filled variant's fill measures roughly **1.1:1** against the page in light
conditions — enough to see once you know it is there, not enough to identify a
control. So the fill reinforces the outline and never replaces it, and
`outlined` is the default.

There is no underline-only variant. A single bottom rule leaves three of the
four edges of the control undefined, so the user has to guess where the field
starts, how wide it is and where it is safe to tap.

## State precedence

Decided once, so two components cannot disagree about a hovered read-only
field.

1. `disabled` — nothing else matters if the field does not apply
2. `invalid`, `validating`, `valid` — what the user has to act on. Mutually
   exclusive, so their relative order never arises
3. `readOnly` — already carried by the absence of a caret and by semantics, so
   it yields to a validation result rather than hiding one
4. `hovered`
5. `enabled`

**Focus is not in this list.** A field showing an error is exactly the field a
keyboard user is about to correct, so losing the ring there loses their place
at the worst moment. Focus is carried separately by `IuxInputTokens.focused`
and drawn additively.

**There is no `pressed`.** A field is not activated by a press; a tap places
the caret, and the state that follows is focus.

**There is no `empty`.** Whether the label floats above the value or sits
inside it is a rendering decision. It changes no colour, no border and no
metric, so it is not a state of the theme layer.

## An invalid field keeps its fill

Only the outline and the message change. A red container would put the error in
the one channel a user with a colour-vision deficiency cannot read, and would
drag down the contrast of the very value the user is trying to fix.

The invalid outline uses `strongBorderWidth` rather than `borderWidth`, so the
error is thicker as well as differently coloured and survives greyscale.

## Where each colour comes from

| Token | Role |
| --- | --- |
| fill, editable | `surface.base` (outlined) or `surface.interactive` (filled) |
| fill, read-only | `surface.subtle` |
| fill, disabled | `surface.disabled` |
| outline, resting | `border.interactive` |
| outline, hovered | `border.strong` |
| outline, read-only | `border.standard` |
| outline, invalid | `border.error` |
| outline, valid | `feedback.success.border` |
| outline, disabled | `border.disabled` |
| value | `content.primary`, `content.disabled` when inactive |
| label, help, placeholder | `content.secondary`, `content.disabled` when inactive |
| message, invalid | `feedback.error.content` |
| message, valid | `feedback.success.content` |

## The placeholder is not de-emphasised below readable

`content.tertiary` measures **4.45:1** on the filled surface in light
conditions — below the 4.5:1 minimum. The placeholder therefore uses
`content.secondary`. A placeholder is text the user has to read in order to
know what to type; de-emphasising it below the readable threshold defeats its
only purpose.

Every pair in the table above is measured on all four shipped profiles by
`test/inputs/iux_input_theme_test.dart`.

## Read-only asks for the recessed surface

A read-only field resolves its fill to `surface.subtle` and an editable filled
one to `surface.interactive`. These are distinct roles, but the four shipped
palettes map both to the same value — so **in the filled variant, the fill
alone does not separate a read-only field from an editable one today**.

The separation is carried by the widget instead: no caret, no keyboard, and the
read-only state announced. A theme that wants a visual distinction separates
the two roles, and the resolver already asks for the right one.

In the outlined variant the two are distinguished, because `surface.subtle`
differs from `surface.base` on all four profiles.

## Disabled holds 3:1

WCAG 2.2 exempts an inactive control from the contrast minimum. IUX holds 3:1
for the disabled *content* anyway: a field the user cannot fill is still a
field they have to read in order to understand the form.

The disabled *outline* is the one exception taken. It is not held to 3:1, and
the field is identified by its fill, its label and its semantics instead — the
same position the button theme takes.

## Shape comes from the foundation scale

`IuxInputTheme.shape` is an `IuxShape`, not an input-specific enum. A rounding
level means the same thing on a card, a button and a field, and a second enum
for it would only allow them to disagree. `IuxShape.full` resolves to infinity;
the widget resolves it against its own height, which the theme cannot know.

## Limits

- No widget exists yet. This mission resolves values only; `IuxTextField` is
  IUX-010 and selection controls are IUX-011.
- Colours are resolved against `surface.base`. A field placed on a raised or
  overlay surface inherits that assumption and has to be re-measured — the same
  limitation the button resolver carries.
- In the filled variant a read-only field and an editable one resolve to the
  same fill on the shipped palettes, because `surface.subtle` and
  `surface.interactive` are mapped identically. See above.
- `IuxInputTheme` is not yet installed by `IuxTheme.resolve`, so
  `IuxInputTheme.of` falls back to its defaults. The fallback is the shipped
  configuration, so nothing renders incorrectly; installing it is a one-line
  change in the resolved theme.
- Text scaling, RTL and long-text behaviour are properties of the widget, not
  of the tokens. They are verified in IUX-010.
- Hover exists in the model for parity with the button. On a touch-only Android
  device it never occurs, so it may only ever reinforce information that is
  already available elsewhere.

## Evidence level

Standard for the contrast contracts, for focus visibility and for the
requirement that an error is not carried by colour alone. Context dependent for
the state precedence and for the variant taxonomy.

## Sources

- WCAG 2.2 — SC 1.4.1 Use of Color, SC 1.4.3 Contrast (Minimum), SC 1.4.11
  Non-text Contrast, SC 2.4.7 Focus Visible, SC 2.5.8 Target Size (Minimum).
- Material 3 text field anatomy, for the filled and outlined taxonomy.
