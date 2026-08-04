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

## The variant a call site did not name

`IuxButtonResolver.defaultVariantFor(action)` derives it. Intent says which
containers exist for that meaning; `IuxActionDescriptor.importance` picks a
rung of what is left.

| | primary, destructive | secondary, tertiary |
| --- | --- | --- |
| `high` | `filled` | `outlined` |
| `medium` | `outlined` | `tonal` |
| `low` | `text` | `text` |

There was an `IuxButtonTheme.variant` field until IUX-039, holding one constant
— `filled` — for all four intents. Two of them have no fill, so the most
ordinary button in the package, a plain secondary descriptor, resolved to a
container exactly equal to the page it sat on. Keeping it as an application-wide
override was refused: it would have had to be ignored for secondary and tertiary
to stay legal, which is the same silent discard described below, and nothing in
`lib/`, `test/` or `apps/` ever set it to anything but the default.

This is also what gave `importance` an effect. It was read by nothing at all
until IUX-039 — `high` and `low` rendered and announced identically. Choosing
the default is the one job that neither duplicates the variant axis nor adds a
second colour channel the caller has to keep in step with it.

`IuxActionDescriptor.destructive` states `importance: high` so that a deletion
keeps its fill. Not because deleting is desirable — because a control that
destroys data has to be identifiable as a control (WCAG 2.2 SC 1.4.11).

## Where an intent's accent lives

Not every intent keeps its accent in the same role, and assuming otherwise
produced a white label on a white surface — caught by the contrast test, not
by review.

| Intent | Accent role | Why |
| --- | --- | --- |
| `primary`, `destructive` | `background` | filled in the semantic layer |
| `secondary`, `tertiary` | `foreground` | already modelled as unfilled; their `background` *is* the page surface |

The accent is the label of every variant and the outline of every unfilled one.
`IuxActionColors` used to carry a separate `border` for the outline; it was
painted by nothing — the only variant that read it was `filled`, whose outline
width is zero except when disabled, and the disabled palette overrides the
colour anyway — and it was the only unmeasured colour in the file, which is how
two of the four profiles came to set it to the page surface itself. It was
removed at IUX-039 rather than wired: an outline that must clear 3:1 on the page
while the label it encloses clears 4.5:1 has one sensible value, the label's.

Applying an `outlined` variant to a `secondary` intent therefore double-encodes
emphasis. The resolver handles it explicitly rather than pretending the two
axes are independent.

A brand theme that gives `secondary` a real fill must revisit this. Every
variant × intent × state × profile pair is measured, so the failure is loud.

## Filled refuses secondary and tertiary

Same shape as the tonal rule below, found the same way. Since those two intents
have no fill, `filled` painted the page over the page: measured on all four
profiles, `filled` + `tertiary` was byte-identical to `text`, and `filled` +
`secondary` differed only in the unpainted `border` token. The request was
accepted and discarded in silence until IUX-039, which is worse than a refusal
because the call site reads as though it worked (§22).

Giving them a fill was refused rather than deferred: one filled action per group
is what makes the primary readable as the primary.

## Tertiary is the intent without an accent

`tertiary` used to mean "a low-emphasis action" — a statement about weight,
which the variant axis and `importance` already make. Measured on all four
profiles, it rendered byte-identically to `secondary` in `outlined`, `tonal`,
`text` and `icon`: the two roles differed by one `border` token that no variant
painted, and in the two high-contrast profiles not even by that.

It now means an action that leads *away* from the task rather than through it —
back, close, skip, dismiss — and it is drawn in the profile's supporting neutral
rather than the accent. Quieter by hue, never by contrast: every tertiary
foreground clears 4.5:1 on its own container on every profile, because reducing
contrast to signal low emphasis fails exactly the reader who most needs the
label. This is the meaning `IuxAppBar`'s back control already relied on when it
declared `tertiary`, and did not receive.

Deleting the member instead was the alternative considered, and it is the
cleaner answer to "an intent that names an emphasis level duplicates the axis
that resolves emphasis". It was rejected because `IuxAppBar`, the Material
`ColorScheme` bridge and two catalog panels all name it, and because the
back-control case is a real meaning that no other intent expresses.

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
is drawn additively by `IuxFocusable`, *outside* the container. There is no
`focused` field on `IuxButtonTokens`: one existed, no button ever set it, and
adding one back would mean a ring painted in the container's own decoration —
over the content it identifies, which is the failure WCAG 2.2 SC 2.4.11 was
added for. A design where pressing hides the focus ring is one a keyboard user
loses their place in.

**A finished operation is not in this list either.** `success` and `error`
members existed until IUX-038 and nothing painted them, while they outranked
`hovered` — so the only thing they achieved was to stop a settled button
answering the pointer. A result belongs in wording; see
`IuxAsyncActionButton`.

## No shadow, and no switch that offers one

There is no `elevateFilled` and no `IuxButtonTokens.elevation`. Both existed
until IUX-038 and no widget ever read the value: setting the switch produced a
byte-identical decoration while the resolver reported a shadow it had computed.
Wiring it up was refused rather than merely dropped — PROJECT_PROMPT §20 names
`elevation:` as the archetype of a parameter a button should not take, every
other IUX surface rests hierarchy on colour, and a shadow vanishes under a
reduced visual stimulation preference, so any separation resting on it is
separation some users never receive. A filled button is already separated from
its background by a contrast-measured fill.

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
