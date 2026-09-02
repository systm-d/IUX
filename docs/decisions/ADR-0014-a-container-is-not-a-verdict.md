# ADR-0014: A container is not a verdict

- Status: accepted
- Date: 2026-09-02

No mission number, for the reason `ADR-0011` and `ADR-0013` both give: this
came from an application building on IUX rather than from a mission of the
framework, `docs/MISSION_*` stops at 043, and citing an `IUX-044` that no
document answers would be a reference that promises a file and delivers none.

## Context

The pilot's maquette (`docs/maquettes/01-saisons.png`) tops each season with a
coloured circle carrying a glyph: a green leaf for spring, a blue snowflake for
winter, an orange maple leaf for autumn, a yellow sun for summer. `IuxAvatar`
already draws a circle with a fallback glyph — `Icons.person_outline`, on
`colors.surface.subtle` — and the task that asked for this component to grow
an `icon` parameter also asked it to grow a `tone`, so the circle could be
filled with something other than the resting neutral.

**The request that arrived proposed spending `IuxStatusTone` on it**: the
caller passes `IuxStatusTone.neutral` for winter, `.success` for spring,
`.warning` for summer, `.error` for autumn, and the resolver reads
`colors.feedback.<role>` the way `IuxStatus` already does. Four members,
already measured on four profiles, already exported — reusing it costs
nothing to add.

**It is also the exact request `ADR-0013` already has a name for, and already
rejected once.** That record's *Alternatives considered* describes it in
these words: "Reusing the four tones and letting the application map them
… it ships a judgement as a colour, and it makes `IuxStatusTone.error` mean
‘hot’ in one application and ‘failed’ in the next, which is the state a
closed enum exists to prevent." Substitute "cold" for "hot" and "autumn" for
"summer" and the sentence describes this request without changing a word
else. `iux_status_model.dart`'s own dartdoc defines the four tones as
families of *news* — "a state with no consequence," "a state the user
wanted," "still works but will not for long," "a state that has stopped
working and needs attention" — and a season is none of those. Winter is not
neutral news, spring did not succeed, summer carries no warning, and autumn
has not failed. Sending the four seasons through `IuxStatusTone` to obtain
four recognisable colours would ship a claim about each of them that the
framework has no way to know is true and the application no way to state
out loud, which is the one thing `IuxStatus` was built to make impossible.

`IuxValueDirection` — `above`, `at`, `below`, added by `ADR-0013` for exactly
the case `IuxStatusTone` does not fit — does not fit either, on inspection
rather than by construction. It answers "which side of a reference did this
reading fall on," and a season is not a reading and sits on no reference:
there is no sense in which summer is *above* winter. Its three members would
also be one short of the four the maquette needs, which is a symptom of the
mismatch rather than the cause of it: the axis is the wrong shape for the
question, not merely short a value.

**Neither of IUX's two colour vocabularies answers "which of several
unrelated things is this," because neither was built to.** `IuxStatusTone` is
built to answer "is this good or bad news." `IuxValueDirection` is built to
answer "which side of a line." A season, a workspace, a label a user picked
from a list — these are answers to "which one," a question with no ordering
and no verdict attached, and IUX has shipped nothing that answers it.

`docs/components/component-standard.md` §4 states the constraint this
container is still held to even though neither existing vocabulary fits it:
"An API that accepts a colour has already lost the contrast guarantee." A
`Color` parameter on `IuxAvatar` was never on the table for that reason.
What was open was which *closed* vocabulary the parameter draws from, and
`§14` of the same document, together with `COMPONENT_STANDARD.md §20`,
requires an ADR for exactly this kind of decision — the same requirement
`ADR-0013` was written under.

## Decision

**A fourth colour role group, `IuxSemanticColors.avatarAccent`, holds four
decorative accents with no meaning attached, and `IuxAvatar` gains `icon` and
`tone: IuxAvatarTone?` to consume them.**

Two things are added:

- `IuxAvatarAccentColorSet`, four `IuxAvatarAccentRoleColors` named `one`
  through `four` — not `neutral`/`success`/`warning`/`error`, not
  `above`/`at`/`below`, because neither pair of words is true of what these
  hold. Each carries `content`, `surface`, `border` and `icon`, the shape
  `IuxFeedbackRoleColors` already has, for the same reason: initials are text
  held to 4.5:1 (WCAG 2.2 SC 1.4.3) and a caller-supplied glyph is a
  graphical object held to 3:1 (SC 1.4.11), and one field cannot honestly
  serve both floors.
- `IuxAvatarTone`, a four-member enum an application passes to select one.
  `IuxAvatarAccentColorSet` and `IuxAvatarTone`'s members are named
  identically, mirroring how `IuxFeedbackColorSet` mirrors `IuxStatusTone`
  and `IuxComparisonColorSet` mirrors `IuxValueDirection`.

Three bounds are part of the decision, not commentary on it:

1. **Four, and only because the palette already has four.** IUX ships four
   non-neutral hue families — `ADR-0013` counted them while looking for two,
   naming them `accent`, `critical`, `positive`, `caution`. This record
   spends the same four rather than asking a fifth into existence: a new hue
   family is new primitives, measured on four profiles under three simulated
   colour-vision deficiencies, which `ADR-0013`'s own *Alternatives
   considered* calls "a mission, not a paragraph in a component's ADR." That
   argument was available to both records and is taken here as read.
2. **No order and no rank.** `one` is not first among equals; nothing about
   its name means better, more urgent, or more likely than `four`. This is
   what separates the naming from `IuxValueDirection`, whose three members
   *are* ordered on purpose, and from `IuxActionColorSet`'s
   `primary`/`secondary`/`tertiary`, which rank on purpose too.
3. **Never used without a glyph.** `IuxAvatar.icon` exists in the same
   change as `IuxAvatar.tone`, and every catalogue sample that sets one sets
   the other. This is policy rather than a compiled guarantee — nothing
   stops a caller from passing `tone` alone — and it is written here because
   the reason is measured, not stylistic: see *What no test can enforce*
   below.

## Where the colours come from, and why the container is filled rather than tinted

`ADR-0013` put a value pill's reading on the profile's flat, subtle surface,
reasoning that "a value pill repeats down a column of rows, and thirty tinted
panels is a screen of alarms." That reasoning does not carry over. A pill is
read as a message; the maquette's circle is read as a badge — the entire
point of `un rond coloré` is that the round *is* the colour, the way a
calendar dot or a legend swatch is, not the way an inline alert is. Diluting
it to a tint on a neutral surface would under-deliver the one thing the
maquette actually asked for.

So each accent **fills** the circle rather than tinting it, reusing the
primitive value each profile's `feedback` block already uses for `content` at
that hue — `accent40`/`positive40`/`caution40`/`critical40` in the light
standard mapping, and the equivalent rung in the other three — with `content`
and `icon` both set to whichever of `neutral0` or `neutral95` reads on top of
it. This is the same technique `ADR-0013` used for `comparison`: no new
primitive, a value already shipped and already trusted for a different role,
recombined under a new name with its own contract and its own tests.

**The apparent gap — every profile's `action.primary`/`action.destructive`
already validates a foreground/background pair at the `accent`/`critical`
hues, but `positive` and `caution` have no existing "filled with white text"
precedent to cite — was closed by measurement rather than by inference.**
Taken this round, with the formula `test/support/contrast.dart` uses:

| profile | surface rung | text/icon | one (accent) | two (positive) | three (caution) | four (critical) |
| --- | --- | --- | --- | --- | --- | --- |
| light standard | 40 | `neutral0` | 6.30:1 | 6.31:1 | 5.94:1 | 6.81:1 |
| dark standard | 70 | `neutral95` | 9.70:1 | 9.70:1 | 10.63:1 | 8.90:1 |
| light high contrast | 10 | `neutral0` | 17.58:1 | 17.21:1 | 17.46:1 | 17.43:1 |
| dark high contrast | 80 | `neutral95` | 12.83:1 | 13.19:1 | 13.65:1 | 12.51:1 |

Every cell clears 4.5:1 with room to spare, so `content` and `icon` both take
it — see *What no test can enforce* for why they end up equal rather than
merely both-sufficient. `border` repeats `surface`: the fill already clears
3:1 against the page unassisted in all sixteen cells above, so a separately
coloured ring would be decoration on decoration. All four are recorded beside
their mapping in `iux_color_palettes.dart` instead of only here, matching
where `ADR-0013`'s own measurements live.

## What no test can enforce

**Two of the four hues collide under colour-vision deficiency, and this was
known before this record was written.** `IuxCategoryGlyphs`'s own dartdoc
cites `IUX-PALETTE-PERCEPTION-001`: under deuteranopia, the most common
dichromacy, `feedback.success` and `feedback.error` are 0.4 apart in Oklab
×100 in the dark high contrast profile — "the same colour" — and every
profile has at least one pair below the threshold most people notice
side by side. `avatarAccent` reuses those exact four hues, so the same
collision is inherited rather than newly introduced: two avatars a colour-
blind user cannot tell apart by hue are not a possibility this record
creates, they are a fact about the palette this record spends.

**This is the entire reason `icon` was added to `IuxAvatar` in the same
change as `tone`, rather than `tone` shipping alone with a documented
recommendation to pair it with something.** `IuxCategoryGlyphs` answers the
identical problem for `IuxStatusIndicator` and `IuxInlineFeedback` with four
distinct silhouettes — a circle, a tick, a triangle, an octagon — because
shape, unlike hue, survives every dichromacy and a monochrome screen alike.
`IuxAvatar` cannot borrow those four shapes: they belong to news, and this
container is explicitly not news. So the glyph that survives where hue fails
has to come from the application, which is consistent with everything else
this record already sends there — the choice of which hue means which
season was never IUX's to make, and neither is the choice of which shape
does. What IUX can and does do is make the pairing available at the same
call site, in the same parameter list, so an application that reads the
`icon` doc comment meets the reason immediately rather than in a linked
accessibility note it may not open.

**Nothing compiled here stops a caller from setting `tone` and leaving
`icon` null**, which draws four colours distinguished by hue alone — exactly
the failure mode above. `docs/components/media.md` *Limits* says so in
words, the same way `IuxComparisonRoleColors`'s "direction is a comparison,
not a judgement" bound is written into prose rather than into a type. A
constructor that required `icon` whenever `tone` was set would have made the
pairing unreachable-by-construction, and was rejected: an application
legitimately wants a coloured circle with no icon at all — a plain accent
mark behind initials — and forcing a glyph onto that case to protect a
different one would have been the wrong container refusing the wrong thing.

## Consequences

- **`IuxSemanticColors` gains an eighth role group**, the second since
  `ADR-0002` defined the contract and the first since `ADR-0013` added
  `comparison`. Every theme must map it: four shipped palettes plus any
  brand palette, and `IuxTheme.withSemanticColors` callers who build a full
  `IuxSemanticColors` by hand — `test/themes/iux_theme_test.dart`'s branded
  fixture — get a compile error until they do, which is the same intended
  failure `ADR-0013` accepted for `comparison`.
- **`IuxStatusTone` and `IuxValueDirection` are both unchanged.** This record
  adds no member to either. An application that wants to say a state is
  alarming still reaches for `IuxStatus`; one comparing a reading with a
  reference still reaches for `IuxValue`; neither is what a season is.
- **`docs/themes/brand-theme-guidelines.md` gains a fourth role group to
  describe**, on top of the three `ADR-0013` already added to its list.
- **`IuxAvatar.icon` and `IuxAvatar.tone` are independent parameters, and
  every catalogue sample that sets one sets the other**, which is policy
  documented in `docs/components/media.md` *Limits* rather than a compiled
  guarantee — see *What no test can enforce*.
- **The tone is never announced**, matching every other colour vocabulary
  this framework has shipped. `IuxAvatar`'s accessible name is `name`; a
  caller-supplied `icon` is drawn and never read, the same as the existing
  fallback glyph.

## Alternatives considered

**Reusing `IuxStatusTone`, as requested.** Rejected in *Context*: it is the
same category error `ADR-0013` already named and rejected once, applied to a
different domain.

**Reusing `IuxValueDirection`/`comparison`.** Rejected in *Context*: a season
is not a reading compared with a reference, and the axis is three members
short a fourth for a reason structural to what it means, not merely to how
many values it happens to hold.

**A fifth hue family, so the container's fill would not double as a hue
already spent on something else.** Rejected on `ADR-0013`'s own terms,
reused rather than re-argued: new primitives measured across four profiles
and three dichromacies is a mission, and this task is one component.

**Tinting the surface, the way `comparison` does, rather than filling it.**
Rejected in *Where the colours come from*: the maquette's own visual intent
— a coloured round, not a coloured pill — is the one requirement a subtle
tint would fail to meet, and `comparison`'s reason for tinting (repetition
down a dense column reading as alarms) does not describe a badge.

**Requiring `icon` whenever `tone` is set, so the CVD collision in *What no
test can enforce* could not be reached at all.** Rejected there: it forecloses
a legitimate plain-accent use this record has no standing to rule out, to
guard a different use that documentation already covers honestly.

## Risks

- **The CVD collision is real and this record ships it rather than closes
  it.** Two of the four accents read as the same hue to some fraction of
  colour-blind users in some profiles, inherited unchanged from
  `IUX-PALETTE-PERCEPTION-001`. The glyph is the mitigation, and nothing
  compiled makes an application supply one.
- **An eighth role group is an eighth place for a brand theme to get wrong**,
  compounding the risk `ADR-0013` already recorded for its own seventh.
- **This record generalises from one pilot, for one component**, the same
  extrapolation `ADR-0013` named as a risk for `comparison`. Whether a second
  application ever reaches for `avatarAccent` for something other than an
  avatar is unproven; the group is scoped to what asked for it.
