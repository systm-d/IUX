# ADR-0016: A label says which one with a dot, not a fill

- Status: accepted
- Date: 2026-09-28

No mission number, for the reason `ADR-0011` gives: this came from an
application migrating onto IUX (systm-d/IUX#71), and `docs/MISSION_*` stops at
043.

## Context

A migration from another design system had project cards carrying a type label
filled with the accent colour — "library", "service", "tool" — so a user
scanning the cards could tell the types apart before reading them. `IuxTagChip`
had no tone, so the migration painted the label with `action.primary` and said
in a comment that it was borrowing a role that meant something else.

The first answer was a refusal, recorded in `IUX-CHIP-FILL-001`: a small pill
filled with the accent is the shape of a filled primary button, and a tag's one
guarantee is that it never looks pressable. That record named what a "yes"
would take — extending `ADR-0014`'s decorative accents, the ones `IuxAvatar`
uses for "which one of several unrelated things is this", to a text label — and
said it would need its own record. The maintainer has since said yes. This is
that record.

The question it answers is therefore not *whether* a tag carries one of the four
accents, but *how*, given that the reason for the refusal was measured and has
not gone away.

## What was measured

`ADR-0014` fills an avatar's circle with the hue at the rung each profile's
`feedback` block uses for content. Those are also the rungs the action roles
use. Taken this round, from the shipped palettes:

| profile | `avatarAccent.one.surface` = `action.primary.background` | `avatarAccent.four.surface` = `action.destructive.background` |
| --- | --- | --- |
| light | yes — both `accent40` | yes — both `critical40` |
| dark | yes — both `accent70` | yes — both `critical70` |
| light high contrast | no (`accent10` against `accent20`) | no |
| dark high contrast | yes — both `accent80` | no |

So a tag filled with the avatar's accent is not "like" a filled primary button
in three of four profiles. It is the same colour, to the value, and a tag in
tone `four` is the same colour as a delete button in two. The refusal's premise
holds exactly; it was never a matter of taste.

A tint does not escape it either. In the light profiles, a hue-tinted capsule is
what `IuxValue` already draws for a compared reading (`comparison.*.surface`,
`ADR-0013`), so a tinted tag would look like a reading. In the dark profiles no
tint of any hue ships, for the reason `IUX-FEEDBACK-DARK-SURFACE-001` records: a
dark tint of a hue is a colour nobody has measured.

## Decision

**`IuxTagChip` gains `tone: IuxAvatarTone?`, drawn as a filled circle before the
label, in `avatarAccent.<tone>.surface`. The pill itself is unchanged: outlined
in `border.subtle`, on `surface.subtle`, never filled with a tone.**

- **The same vocabulary and the same colour as the avatar.** An application that
  already maps its project types to `IuxAvatarTone` for their avatars uses the
  same mapping for their tags, and a tag and an avatar standing for the same
  thing match. No new role group, so no brand palette has anything to add.
- **A circle, because `ADR-0014` already found that a circle reads as
  identity.** Its argument was that the avatar's round *is* the colour, the way
  a legend swatch is. A dot before a label is a legend swatch, and it sits
  *inside* the tag's outline, so it reads as part of the tag rather than as a
  control beside it. The nearest IUX control is a radio, which draws a ring —
  and, chosen, a ring around a dot — at the full target size and outside any
  pill; a small solid dot inside an outlined label is neither.
- **Half the glyph size, scaling with text**, so it stays in proportion to the
  label at 200%.
- **Both forms of the tag**, read-only and removable, through one private widget
  so they cannot drift.

Measured against the tag's own surface, the dot clears 3:1 in all sixteen
cells:

| profile | one | two | three | four |
| --- | --- | --- | --- | --- |
| light | 5.88:1 | 5.89:1 | 5.54:1 | 6.35:1 |
| dark | 7.59:1 | 7.58:1 | 8.31:1 | 6.96:1 |
| light high contrast | 15.14:1 | 14.82:1 | 15.03:1 | 15.00:1 |
| dark high contrast | 10.03:1 | 10.31:1 | 10.68:1 | 9.78:1 |

## What no test can enforce

**The words carry the category; the dot helps a sighted user scan.** The tone is
never announced, two of the four accents collide under colour-vision deficiency
(`IUX-PALETTE-PERCEPTION-001`), and a monochrome screen draws them all grey. A
tag whose meaning lived only in its tone would have no meaning for those users.
`ADR-0014` bound the avatar's tone to a glyph for the same reason; a tag's label
is required and never empty, so the bound holds by construction here.

**Four, and no more.** `ADR-0014`'s first bound applies unchanged: the palette
has four non-neutral hue families. An application with seven project types maps
four and leaves three untoned, or groups them. A fifth accent is palette work.

## Consequences

- `IuxTagChip` and `IuxTagChip.removable` take `tone`. Additive.
- `IUX-CHIP-FILL-001`'s answer to #71 is overtaken; its answer to #70 (a badge
  has no selected state) stands.
- The tag's documentation, the chips page and the deliberately-absent page say
  "a dot, never a fill" in place of "no tone".
- A test in every profile holds that the pill's fill is never an action fill
  whatever the tone, that the dot is the avatar's colour, that it clears 3:1,
  and that tone `one` still equals the primary fill where the table says so — so
  a palette change that weakens this record's premise fails a test rather than
  passing silently.

## Alternatives considered

**Filling the pill with the avatar's accent, as reported.** Rejected on the
measurement above: it is the primary button's colour in three profiles and the
destructive button's in two.

**Filling it with a tint.** Rejected: in light it is the value pill's capsule,
and in dark there is no measured tint to use.

**A new role group for tags, with its own rungs chosen to differ from the
actions.** Rejected: a ninth role group is one more thing every brand palette
must map, for a problem a shape solves without any colour at all being new. It
would also have to be measured under three dichromacies to say anything
`avatarAccent` does not already say.

**A tinted border instead of a dot.** Rejected: an outline in a strong colour is
how `IuxFilterChip` shows a chip is chosen. A tag must not borrow a control's
selected state any more than its fill.

## Risks

- **The report asked for a filled label, and this is not one.** A user who wanted
  the type to be the first thing seen gets a dot, which is quieter. If that
  proves too quiet in use, the next step is measurement — a fill at a rung no
  action uses, checked under dichromacy — not the action colours.
- **The dot is small.** Ten logical pixels at default text size. It is a scanning
  aid, not a carrier, and was not tested with users.
