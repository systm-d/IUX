# IuxIcon, IuxAvatar and IuxImage

## Purpose

Three ways to put a picture on a screen, and one decision none of them will
make for you: **does this picture carry information, or not?**

That question has exactly two answers and they are opposites. A picture that
carries information needs words that carry the same information without it. A
picture that carries none must be removed from the semantic tree entirely, not
described. Getting it backwards is how a screen-reader user ends up hearing
`IMG_2049.jpg` — or, worse, hearing nothing where the only content was.

Every other framework makes this decision by defaulting. Flutter's `Icon` has
an optional `semanticLabel` that defaults to null; `Image` has an optional
`semanticLabel` that defaults to null. So the shortest way to write either one
is also a way to produce an unnamed image, and "I have not written the
description yet" is indistinguishable from "this picture says nothing".

`IuxImageDescription` is the whole point of this component family. It is
required, it has no default, and it has two constructors:

```dart
IuxImageDescription.meaningful(l10n.salesRoseInQ3)   // announced
const IuxImageDescription.decorative()               // hidden
```

| Component | For | Announcement |
| --- | --- | --- |
| `IuxIcon` | a glyph | the description, or nothing |
| `IuxAvatar` | a person or an organisation | their **name** — never their initials |
| `IuxImage` | a picture that is content | the description, in every state |

## Use when

- **`IuxIcon`** — a glyph stands on its own in a layout: a list row, a legend,
  beside a heading, next to a label it repeats.
- **`IuxAvatar`** — a person or an organisation appears as an object the user
  recognises: a participant list, a comment, an account header, a mention.
- **`IuxImage`** — a picture *is* content: a product photograph, a chart, a
  map, a screenshot, a scanned document.

## Do not use when

- **The picture is a control.** None of the three takes an `onTap`, and none
  will. A tappable picture is a control with no name, no role, no focus ring
  and no target floor. Use `IuxIconButton` for an icon action, `IuxButton`
  beside a picture, or make the surrounding block one `IuxCard.tappable`.
- **The component already draws its own glyph.** `IuxButton`,
  `IuxStatusIndicator` and the chips size and colour their glyphs from their
  own tokens. Passing an `IuxIcon` into them gives two answers to one question.
- **The glyph's meaning has to be guessed.** A description does not rescue an
  unconventional glyph: only one of the two audiences gets the answer. Put a
  word beside it and mark the glyph decorative.
- **You need an image cache, a retry, a timeout or a placeholder URL.** IUX
  fetches nothing. The parent supplies an `ImageProvider` and owns everything
  about how it is obtained.

## The decision that shapes this API

`IuxImageDescription` is a value class rather than a pair of widget
constructors, for the same reason `IuxStatus` is: the answer usually arrives
with the data. A CMS record carries a URL *and* an alternative text; a product
carries a photo *and* a caption. Keeping a picture's meaning next to the
picture is what stops a screen describing the wrong one after a list is
reordered.

It records `isDecorative` explicitly rather than inferring it from an empty
string. Inferring would make a forgotten description and a deliberate absence
of one the same value in a release build, where the assertion no longer runs —
the single most consequential difference in this file, collapsed by an
optimisation.

The description arrives already localised. IUX composes no user-facing text
anywhere: it cannot know how to say "photo of" in the reader's language.

## API

### `IuxImageDescription`

```dart
IuxImageDescription.meaningful(String description)  // description must not be empty
const IuxImageDescription.decorative()

String description   // the words; empty when decorative
bool   isDecorative
bool   isMeaningful
```

The test for decorative is **not** whether the picture is pretty. It is whether
a user who never sees it has lost anything. An avatar beside a visible name is
decorative; the same avatar alone in a header is not.

### `IuxIcon`

```dart
IuxIcon({
  required IconData icon,
  required IuxImageDescription description,
  IuxIconSize size = IuxIconSize.standard,          // small | standard
  IuxIconEmphasis emphasis = IuxIconEmphasis.primary,  // primary | secondary
})
```

`emphasis` names a content role, never a colour: an API that accepted a colour
would have given away the contrast guarantee. `size` is an enum for the same
reason a spacing is — a glyph sized at the call site stops matching the text
beside it the moment either changes.

### `IuxAvatar`

```dart
IuxAvatar({
  required String name,        // announced; never drawn
  String? initials,            // drawn; never announced
  ImageProvider? image,
  IconData? icon,               // drawn; never announced; excludes initials
  IuxAvatarTone? tone,           // one | two | three | four; null keeps the resting surface
  IuxAvatarSize size = IuxAvatarSize.standard,   // standard | large
})

IuxAvatar.decorative({
  String? initials,
  ImageProvider? image,
  IconData? icon,
  IuxAvatarTone? tone,
  IuxAvatarSize size = IuxAvatarSize.standard,
})
```

`icon` and `initials` are mutually exclusive — both answer "what stands in for
the picture", and an avatar constructed with both throws. `icon` and `tone` are
independent of each other and both independent of `initials`: a plain circle
with a tone and no glyph, or a tone-free circle with a glyph, are both valid.

### `IuxImage`

```dart
IuxImage({
  required ImageProvider image,
  required IuxImageDescription description,
  required double aspectRatio,
  IuxImageFit fit = IuxImageFit.cover,   // cover | contain
})
```

`aspectRatio` is required. A picture whose size is unknown until it decodes
pushes everything below it down the moment it arrives — under a finger already
travelling toward a button, on exactly the slow connections where the delay is
longest. One number at the call site removes the whole class of failure.

`fit` is an intent rather than a `BoxFit`, because only two of Flutter's eight
answers are ever right here and choosing between them is a comprehension
question. `cover` crops; never use it for a chart, whose edges carry data.

## The initials are not the name

This is the second thing the family is built around.

`name` is what a screen reader announces. `initials` is what the eye sees when
there is no photograph. They are separate parameters because they are separate
things:

```dart
// Wrong, and the reason the split exists. "JD" spoken aloud is a spelling.
Avatar(label: 'JD')

// Right.
IuxAvatar(name: 'Maria Costa', initials: 'MC')
```

`initials` is excluded from the semantic tree in both constructors, structurally
— `IuxSemantics.image` excludes descendant semantics, so there is no
arrangement of parameters that gets the letters announced.

### IUX never derives the initials

Taking the first letter of each word holds for `John Doe` and fails for `李明`,
for `van der Berg`, for a mononym, for every script written without spaces, and
for `Dr. Maria de la Cruz-Fernández`. A framework that guessed would generate a
wrong abbreviation of a real person's name in every language it was not tested
in.

Pass the initials your application knows how to build, or pass none: an avatar
with no initials falls back to a neutral glyph, which claims nothing rather
than claiming something wrong.

### Named or decorative

Pick `IuxAvatar.decorative` whenever the name is already visible beside the
avatar, which is most rows in most lists. Otherwise a screen-reader user hears
the name twice, and a list of twenty participants becomes forty utterances
carrying twenty facts.

Pick the named form whenever the avatar stands alone: a header, a stack of
overlapping participants, a mention with no adjacent label. There the circle is
the only thing identifying the person.

### An avatar for a thing, and why IUX ships no icon set

`IuxAvatar` also stands for something that is not a person: a season, a
category, a place — anything a caller wants to represent as a small coloured
circle with a glyph in it, the way `01-saisons.png` tops each season with one.
Two parameters make that possible, and IUX owns exactly one of them.

**The container, the icon slot and the tint are generic, and IUX owns them.**
The circle, its outline, the fact that it holds one glyph, and the fact that
the glyph is drawn on top of a coloured fill — none of that is specific to
seasons, and all of it is what `icon` and `tone` add.

**Which glyph means which thing is domain, and the application owns it.**
`icon` is a plain `IconData`, taken from `Icons.*` the way every other glyph in
this package is — `IuxIcon.icon`, `IuxCategoryGlyphs`. IUX defines no icon set
and ships no mapping from "winter" to a snowflake: a framework that shipped
that mapping would be shipping meteorology, or a calendar, or whatever domain
asked first. The same is true of `tone`: `IuxAvatarTone`'s four members —
`one` through `four` — carry no meaning of their own, on purpose. Which one
means spring is the caller's decision, in the caller's own code, the same way
the choice of glyph is.

**Why the tint is not `IuxStatusTone` or `IuxValueDirection`, when both already
exist.** A season is not a piece of news and it is not a reading compared with
a reference, so neither of IUX's existing colour vocabularies answers the
question `tone` asks — "which of several unrelated things is this." Sending a
season through `IuxStatusTone.error` to get a recognisable colour would assert
that the season *failed*, which is a claim about the season IUX has no
standing to make. `docs/decisions/ADR-0014-a-container-is-not-a-verdict.md`
records the decision in full, including where the four accent colours come
from and what they cost.

**The tone is never announced, the same as every other colour in this
package.** `IuxAvatar`'s accessible name is `name`; `icon` is drawn and never
read, exactly like the existing fallback glyph. A decorative avatar with a
tone announces nothing at all, same as one without.

**Pass a distinct `icon` with every distinct `tone`.** Two of the four accents
read as the same hue to some colour-vision deficiencies in some theme
profiles — `IUX-PALETTE-PERCEPTION-001`, inherited unchanged because
`IuxAvatarTone` spends the same four hues `IuxStatusTone` already does. Nothing
compiled stops a caller from setting `tone` alone; see *Limits*.

## What happens when a picture does not arrive

Network images fail. Offline, 404, a revoked URL, a malformed file, or simply
slow. This is the part most implementations skip, and a blank circle or a grey
rectangle is a failure the user cannot interpret.

### `IuxAvatar` has no failure state, by construction

| | The eye sees | A screen reader hears |
| --- | --- | --- |
| no photograph | the initials, or a neutral glyph | the name |
| photograph loading | the initials, or a neutral glyph | the name |
| photograph failed | the initials, or a neutral glyph | the name |
| photograph loaded | the photograph | the name |

The photograph is drawn *on top of* a fallback that is already there. The
circle is filled before the network is consulted, while it is slow, and after
it has failed — what a user sees when a photograph 404s is what they saw a
moment earlier.

Nothing is announced about the failure, because nothing was lost: the
photograph carried no information the name did not. A spinner and an error
glyph would both be reporting a non-event.

### `IuxImage` does report failure, because the picture *was* the information

| | The eye sees | A screen reader hears |
| --- | --- | --- |
| loading | the reserved frame, filled | the description |
| loaded | the picture | the description, as an image |
| failed, meaningful | a bordered frame, a broken-picture glyph, **the description as text** | the description, as text |
| failed, decorative | the reserved frame, filled | nothing |

**A failed meaningful picture renders its own description in its place.** This
is what a browser does with `alt` and it is the behaviour WCAG SC 1.1.1 is
written around: the information the picture carried survives the picture. It
also means IUX invents no user-facing text — there is no "Image unavailable"
string to translate, because the words that appear are the words the caller
already wrote.

It is why `IuxImageDescription.meaningful` asks for a description that stands on
its own. "Product photo" is a poor alternative and an absurd paragraph; "Blue
running shoe, side view" is both.

The failed node is announced as **text, not as an image**. There is no image
any more, and a node that still claimed to be one would describe something the
user cannot reach.

**A failed decorative picture says nothing at all.** Its frame keeps its space
so the page does not reflow around an absence, and it stays hidden. A
broken-picture glyph there would be an error message about a non-event.

### Loading shows a filled frame, not a spinner

One indicator per picture turns a scrolling list into a field of moving parts,
and a reduced-motion profile removes every one of them, leaving nothing in
their place. The filled frame needs no motion, is already the shape the picture
will take, and does not compete with the content around it.

The description is announced while the picture is still arriving. This is what
a browser does with `alt`. The alternative — announcing "loading" — either
interrupts the user for something that resolves in a second, or leaves the node
nameless until it does.

## States

| State | `IuxIcon` | `IuxAvatar` | `IuxImage` |
| --- | --- | --- | --- |
| default | glyph | photograph or fallback | picture |
| loading | — | fallback, silently | filled frame, named |
| error | — | fallback, silently | glyph + description as text |
| empty | — | neutral glyph | — |
| focused | — | — | — |
| pressed | — | — | — |
| disabled | — | — | — |

The last three rows are blank on purpose: **none of these is a control**, so
none has a focused, pressed or disabled state to express. A component that
cannot express a state should say so rather than let the caller discover it.

## Accessibility

- **Name.** `IuxAvatar` requires a non-empty `name`, or the explicitly
  decorative constructor. `IuxIcon` and `IuxImage` require an
  `IuxImageDescription`. There is no path to an unnamed meaningful picture.
- **Role.** A meaningful picture is an `image` node. A decorative one is not in
  the tree at all. A failed meaningful picture is a text node — the role
  changes because the truth changed.
- **Target and focus.** None of the three is focusable or hit-testable, which
  is what allows an avatar to live inside `IuxCard.tappable`. That card's debug
  guard throws on any nested control; an avatar that were independently
  tappable would fail it, and a screen reader would announce a button inside a
  button.
- **Text scaling.** Glyph sizes and the avatar diameter are scaled through
  `IuxAccessibility.scaleText`, once, with `applyTextScaling: false` on the
  underlying `Icon` so Flutter does not scale them a second time. A glyph that
  stayed 24 pixels while its label doubled is a glyph the person who enlarged
  their text can no longer see.
- **Long text.** The replacement text on a failed picture has no line limit and
  no ellipsis, and the reserved height is a floor rather than a cage: the frame
  grows when the sentence needs the room. Truncating it would lose the
  information the failure was supposed to preserve.
- **Colour.** No state is carried by hue. Missing is a distinct *shape* (a
  broken-picture glyph) plus an outline plus words. Render the screen in one
  hue and nothing disappears.
- **RTL.** Nothing here mirrors or reorders; the description is a `Text` and
  follows the ambient directionality.

### What the component guarantees, and what it cannot

The component guarantees that a description reaches assistive technology, that
decoration does not, and that the choice was made deliberately. It cannot
verify that the words are *good*. "Image" passes every assertion in this file
and helps nobody. That is content review, and no test replaces it.

## Themes

Every colour comes from `IuxSemanticColors` and every metric from
`IuxGeometryTheme` or `IuxTypographyTheme`. There is no colour, radius,
elevation or padding parameter on any of the three, and there will not be one:
an API that accepts a colour has already lost the contrast guarantee, because
the theme can no longer be held responsible for something a call site
overrode.

| Element | Role | Held to |
| --- | --- | --- |
| glyph, primary | `content.primary` | 4.5:1 |
| glyph, secondary | `content.secondary` | 4.5:1 |
| avatar fill, untoned | `surface.subtle` | — |
| avatar initials, untoned | `content.primary` | 4.5:1 on the fill |
| avatar outline, untoned | `border.subtle` | exempt — decoration only |
| avatar fill, toned | `avatarAccent.<one\|two\|three\|four>.surface` | — |
| avatar initials, toned | `avatarAccent.<…>.content` | 4.5:1 on the fill |
| avatar icon, toned | `avatarAccent.<…>.icon` | 3:1 on the fill |
| avatar outline, toned | `avatarAccent.<…>.border` | 3:1 on the page |
| frame fill | `surface.subtle` | — |
| frame outline | `border.standard` | 3:1 |
| broken glyph | `content.secondary` | 4.5:1 |
| replacement text | `content.primary` | 4.5:1 |

The avatar outline takes the one border role exempt from the 3:1 floor when
untoned. That is correct there and only there: the outline carries no
information — it stops a pale photograph bleeding into a pale page — and
`border.subtle`'s own documentation forbids using it to delimit an interactive
control, which an avatar is never allowed to be. A toned avatar's outline is
held to 3:1 like every other role in `avatarAccent`, though in every mapping
this package ships it repeats the fill, which already clears 3:1 against the
page unassisted — see `docs/decisions/ADR-0014-a-container-is-not-a-verdict.md`.

`avatarAccent` is not `feedback` and not `comparison`. Its four members carry
no meaning, and nothing in the theme layer maps `one` to a season — that
mapping is the caller's, made at the call site with `IuxAvatarTone` and
`icon` together.

The contrast pairs are asserted on all four theme profiles in
`test/components/iux_media_test.dart`.

## Motion

None. There is no animation in any of the three, so there is nothing for
`IuxMotionPolicy` to reduce.

The one place Flutter would have introduced motion is `Image`'s default
`frameBuilder`, which fades a newly decoded picture in over a duration a
component is not allowed to hardcode. Both `IuxAvatar` and `IuxImage` supply
their own frame builder — which also removes the window in which there would
have been nothing on screen at all.

## Feedback

None. None of the three is a control and none emits an event.

## Anti-patterns

```dart
// Wrong: a filename is not a description. It is a screen-reader user hearing
// the contents of your storage bucket.
IuxImage(description: IuxImageDescription.meaningful('IMG_2049.jpg'), ...)

// Wrong: an empty string is not "no description needed". It is an image node
// with no name — the assertion catches it.
IuxImage(description: IuxImageDescription.meaningful(''), ...)

// Wrong: describes the container, not the content.
IuxImageDescription.meaningful('Chart')
// Right:
IuxImageDescription.meaningful(l10n.salesRoseTwentyPercentInQ3)

// Wrong: "photo of" is what the image role already says.
IuxAvatar(name: 'Photo of Maria Costa')
// Right:
IuxAvatar(name: 'Maria Costa')

// Wrong: the initials announced as the person.
IuxAvatar(name: 'MC', initials: 'MC')
// Right:
IuxAvatar(name: 'Maria Costa', initials: 'MC')

// Wrong: the name said twice, once by the circle and once by the text.
Row(children: [IuxAvatar(name: p.name), Text(p.name)])
// Right:
Row(children: [IuxAvatar.decorative(initials: p.initials), Text(p.name)])

// Wrong: a decorative glyph announced on every row of a list.
IuxIcon(icon: Icons.chevron_right,
        description: IuxImageDescription.meaningful('Chevron'))
// Right:
IuxIcon(icon: Icons.chevron_right,
        description: const IuxImageDescription.decorative())

// Wrong: a control with no name, no role and no target floor.
GestureDetector(onTap: openProfile, child: IuxAvatar(name: p.name))
// Right:
IuxCard.tappable(
  semanticLabel: l10n.openProfileOf(p.name),
  onActivate: openProfile,
  child: Row(children: [IuxAvatar.decorative(initials: p.initials),
                        Text(p.name)]),
)

// Wrong: a chart cropped to fill a frame is a chart with data missing, and
// nothing on screen says so.
IuxImage(image: chart, fit: IuxImageFit.cover, ...)
// Right:
IuxImage(image: chart, fit: IuxImageFit.contain, ...)

// Wrong: a tone with no glyph. Four of these in a row are four circles a
// colour-vision deficiency can collapse into two.
IuxAvatar.decorative(tone: IuxAvatarTone.one)
// Right: the glyph carries the distinction the hue cannot promise.
IuxAvatar.decorative(icon: Icons.ac_unit, tone: IuxAvatarTone.one)

// Wrong: initials and an icon both claim to be the stand-in. The assertion
// refuses this rather than silently drawing one of them.
IuxAvatar(name: 'Winter 2026', initials: 'W', icon: Icons.ac_unit)
```

## Limits

- **No test can tell whether a description is understandable.** All this
  guarantees is that a description exists and reaches the right audience.
  "Image" satisfies every assertion and helps nobody. Content review remains a
  human obligation, and it is the one that matters most in this family.
- **A screen-reader user is not told that a picture failed.** They receive the
  description, delivered as text rather than as an image, which is the honest
  outcome — the information survived. But there is no "unavailable" wording,
  because IUX composes no user-facing text and requiring the caller to supply
  one on every meaningful image was judged disproportionate. If a later mission
  demonstrates the need, it belongs on `IuxImageDescription.meaningful` as a
  second string, not as a hardcoded English literal.
- **The failure state is not a live region.** A grid of twelve pictures each
  announcing its own failure is worse than the failures. Wrap the region in
  `IuxSemantics.liveRegion` at the call site when one picture's absence is worth
  an interruption.
- **`IuxAvatar` has no status dot, no badge and no overlapping stack.** Each is
  a positioning problem with its own clipping, text-scaling and reading-order
  consequences. A status beside an avatar is `IuxStatusIndicator`; a count is
  `IuxBadge`, in reading order rather than floating over the circle.
- **The tone does not change what is announced.** Four avatars differing only
  in tone are four identical announcements, and nothing here can refuse that —
  pass a different glyph with each tone, or accept that the distinction exists
  for sighted readers only.
- **A tone behind a photograph is invisible.** It is still resolved, because
  the circle is painted before the network is consulted, but a caller who set
  it to mean something will find that meaning gone as soon as a picture
  arrives.
- **Two of the four `IuxAvatarTone` members read as the same hue to some
  colour-vision deficiencies, in some theme profiles.** `avatarAccent` spends
  the same four hues `IuxStatusTone`'s feedback roles already carry that
  collision for — `IUX-PALETTE-PERCEPTION-001` — rather than measuring a new,
  separable set, which `docs/decisions/ADR-0014-*` explains is out of reach for
  a single component. The glyph is what survives where the hue does not, and
  nothing compiled requires a caller to supply one.
- **`avatarAccent` is an eighth role group on `IuxSemanticColors`, and it is
  scoped to one component.** Whether a second application ever reaches for it
  for something other than an avatar is unproven; a brand theme now has one
  more role group to map correctly.
- **Two avatar sizes and two icon sizes.** No demonstrated need for a third.
  Adding one is cheap; removing one after an application depends on it is not.
- **`IuxImage` has no shape parameter.** Always the medium radius. A full-bleed
  hero with square corners has no demonstrated need yet.
- **The reserved frame does not prevent all layout shift**, only the shift
  caused by an unknown picture size. A caller who passes the wrong aspect ratio
  gets a correctly reserved box around a wrongly cropped picture.
- **A failed picture needs somewhere to grow.** Its description can be taller
  than the frame it replaced, especially at 200% text. Inside scrollable
  content — where a picture normally lives — that is fine. Pinned inside a
  fixed-height box it overflows visibly instead of clipping, which is
  deliberate: a visible overflow in debug is a bug report, where a silent clip
  is the information disappearing for the users least able to notice it.
- **Whether a filled frame reads as "loading" rather than as "broken"** to a
  first-time user is a hypothesis. It is conventional and it avoids the motion
  cost of a spinner, but it has not been user-tested.
- **`IuxAvatar` and `IuxImage` are not tested against a real network.** Widget
  tests cannot load one. The three states are exercised with fake
  `ImageProvider`s that resolve synchronously, never, and with an error;
  behaviour against a real slow connection needs manual validation.
- **TalkBack, Voice Access and a physical keyboard need a device.** The
  semantics assertions here approximate them and no more.

## Manual validation still required

- TalkBack on Android: confirm a decorative avatar is genuinely skipped rather
  than announced as an unlabelled image.
- TalkBack on a failed meaningful picture: confirm the description is read once
  and the broken glyph adds nothing.
- A real slow connection, and airplane mode, on a list of avatars.
- 200% text scaling on a list row containing an avatar and a name.
- A row of four toned avatars under a colour-vision deficiency simulator:
  confirm the glyph, not only the hue, is what tells them apart.

## Evidence level

| Claim | Level |
| --- | --- |
| A meaningful image needs a text alternative | Standard — WCAG 2.2 SC 1.1.1 |
| A decorative image must be hidden, not described | Standard — SC 1.1.1, WAI-ARIA `presentation` |
| The alternative is rendered when the image is unavailable | Standard — HTML `alt` semantics, SC 1.1.1 |
| Everything works at 200% text | Standard — SC 1.4.4 |
| Text at 4.5:1, meaningful graphics at 3:1 | Standard — SC 1.4.3, 1.4.11 |
| No state carried by colour alone | Standard — SC 1.4.1 |
| Reserving a picture's box prevents layout shift | Strong guidance — Core Web Vitals CLS, Baymard |
| An accessible name should not begin "image of" | Strong guidance — WAI, Android guidance |
| Initials must not be derived from a name | Context dependent — internationalisation; IUX governance |
| Two components rather than one with a shape flag | Context dependent — component standard §8 |
| A filled frame beats a spinner per picture | Hypothesis — not user-tested |
| A neutral glyph reads as "no photograph" | Hypothesis — conventional, not measured |
| A tone alone does not reliably distinguish two avatars under colour-vision deficiency | Standard — `IUX-PALETTE-PERCEPTION-001`, measured |
| A season's tint belongs in a vocabulary distinct from status and comparison | Context dependent — `docs/decisions/ADR-0014-*` |

## Sources

- WCAG 2.2 — SC 1.1.1 Non-text Content, 1.4.1, 1.4.3, 1.4.4, 1.4.11, 4.1.2.
- HTML Living Standard — requirements for the `alt` attribute, including
  rendering the alternative when the image is unavailable.
- WAI-ARIA — `img` and `presentation` roles.
- Android accessibility guidance — content labels, and
  `importantForAccessibility="no"` for decorative graphics.
- `docs/accessibility/color-and-non-color-signals.md`.
- `docs/components/component-standard.md` §5, §6, §7, §8, §11.
- `docs/components/card.md` — why a card refuses to contain a control.
- `docs/decisions/ADR-0013-a-reading-is-compared-not-judged.md` and
  `docs/decisions/ADR-0014-a-container-is-not-a-verdict.md` — why the tone on
  `IuxAvatar` is neither `IuxStatusTone` nor `IuxValueDirection`.
