# Button theme

## Intention

Turn an action into paintable values, in one place, so the mapping cannot
drift between the button, the icon button and the future async button.

```dart
final tokens = IuxButtonResolver.resolve(context, action, variant: variant);
```

A button widget reads `IuxButtonTokens`. It never reaches for a semantic role
itself.

## Variant is emphasis, intent is meaning

They are set separately because the same action can be prominent on one screen
and discreet on another without changing what it does.

| Variant | Weight |
| --- | --- |
| `filled` | most prominent |
| `outlined` | outline on the page |
| `tonal` | soft container, lowest emphasis that still reads as a button |
| `text` | label only |
| `icon` | square target, no label |

## Where an intent's accent lives

Not every intent keeps its accent in the same role, and assuming otherwise
produced a white label on a white surface — caught by the contrast test, not
by review.

| Intent | Accent role | Why |
| --- | --- | --- |
| `primary`, `destructive` | `background` | filled in the semantic layer |
| `secondary`, `tertiary` | `foreground` | already modelled as unfilled; their `background` *is* the page surface |

Applying an `outlined` variant to a `secondary` intent therefore double-encodes
emphasis. The resolver handles it explicitly rather than pretending the two
axes are independent.

A brand theme that gives `secondary` a real fill must revisit this. Every
variant × intent × state × profile pair is measured, so the failure is loud.

## Tonal refuses destructive

`tonal` carries intent through its border, not its fill — the semantic layer
has no per-intent container role, and inventing one here would ship a colour
pair nobody measured. `surface.selected` with `content.primary` is already
verified on all four profiles, so tonal uses that.

That is not enough separation for an action that destroys data, so
`tonal` + `destructive` asserts. Use `filled` or `outlined`.

Adding proper action-container roles to the semantic layer would remove the
restriction. Recorded as deferred.

## Engaged states never change the variant

An unfilled button tints over the page when hovered or pressed; it never
adopts the intent's fill. An outlined button that becomes filled on hover has
changed its emphasis, which is a different button.

## State precedence

Decided once, so two components cannot disagree about a pressed-while-loading
button.

1. `disabled` — nothing else matters if it cannot be used
2. `loading` — the operation is what the user is waiting on
3. `pressed` — activation feedback must never be swallowed, or the user cannot
   tell their tap registered
4. `error`, then `success` — a result outranks a pointer position
5. `hovered`
6. `enabled`

**Focus is not in this list.** It must stay visible while pressed, while
loading and while showing a result, so it cannot be a value where one wins. It
is carried separately by `IuxButtonTokens.focused` and drawn additively. A
design where pressing hides the focus ring is one a keyboard user loses their
place in.

## No shadow by default

`elevateFilled` is off. A filled button is already separated from its
background by colour, and elevation resolves to zero under a reduced visual
stimulation preference — so relying on a shadow would mean the button reads
differently for users who asked for a calmer interface.

A disabled filled button keeps an outline: its fill sits close to the surface
behind it, and without one the control stops being identifiable as a control.

## Limits

- No widget exists yet. This mission resolves values only.
- `IuxButtonShape.full` returns infinity; the widget resolves it against its
  own height, which the theme cannot know.
- The per-intent accent rule is an explicit assumption about the shipped
  palettes, guarded by the contrast test rather than by the type system.
- Tonal cannot express intent by fill. Deferred to an action-container role.

## Evidence level

Standard for the contrast contracts and for focus visibility. Context
dependent for the state precedence and the variant taxonomy.

## Sources

- WCAG 2.2 — SC 1.4.3, SC 1.4.11, SC 2.4.7, SC 2.5.8.
