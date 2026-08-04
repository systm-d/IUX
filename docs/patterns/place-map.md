# Place map

## Purpose

Put a set of real-world places on a map and guarantee that the same
information exists as a list: every place named, ordered, and findable without
looking at the map.

```dart
IuxPlaceMap(
  places: <IuxPlace>[
    for (final Visit visit in round)
      IuxPlace(
        id: visit.reference,
        ordinal: l10n.stopNumber(visit.position),   // '3'
        name: visit.site,                           // 'Renshaw & Co, Depot 4'
        detail: l10n.addressLine(visit.address),    // '18 Mill Lane, Salford'
        distance: l10n.distance(visit.metres),      // '1.2 km'
      ),
  ],
  map: GoogleMap(initialCameraPosition: camera, markers: markers),
  zoom: IuxZoomControls(
    zoomInLabel: l10n.zoomIn,
    zoomOutLabel: l10n.zoomOut,
    onZoomIn: controller.zoomIn,
    onZoomOut: controller.zoomOut,
  ),
  listLabel: l10n.visitsOnThisRound,
  selection: selected,
  placeActionHint: l10n.centresTheMapOnThisVisit,
  onPlaceSelected: controller.select,
)
```

## IUX draws no map, and that is the constraint the rest follows from

This package touches no platform. IUX-031 established the rule and proved it by
parsing its own source, and `test/patterns/iux_place_map_test.dart` applies the
same parse to these two files: every import is `package:flutter/…` or relative,
and no line of code outside a comment mentions `MethodChannel`, `Platform.`,
`dart:io`, `google_maps_flutter`, `GoogleMap`, `LatLng`, `CameraPosition`,
`mapbox` or `flutter_map`. No dependency was added to `pubspec.yaml`; the
package still has exactly two, both from the SDK.

So `map:` is the caller's widget and everything around it is the pattern's.

**This is the first component in the project whose visual half cannot be
verified here at all.** No widget test and no emulator in this repository draws
a tile. The division of what is guaranteed and what is not is tabulated
[below](#what-iux-guarantees-and-what-is-yours), and the list of claims that
need a device is at the end.

## The problem: a map is the hardest case in SC 1.1.1

WCAG 2.2 SC 1.1.1 (Non-text Content, level A) asks for a text alternative that
serves the *same purpose*. A map's purpose is spatial arrangement, and spatial
arrangement is exactly what a sentence cannot carry.

The reflex answer is a described image — a `semanticLabel` on the map region:

```dart
Semantics(label: 'A map showing five visits around Salford', child: map)
```

That is a description of a picture, and it is the wrong answer here. It tells a
screen-reader user that there are five visits and gives them nothing they can
act on: not where the visits are, not which is next, not which is nearest, not
the address of any of them, no way to choose one. It is a caption on a
photograph of a document.

The honest answer is that **the same information already exists as a list.**
A round is places, in an order, each with an address and a distance. A
screen-reader user does not read a map; they read what is on it, in an order
that serves them — and so, quite often, does a driver at a junction.

## The central decision: the list is not a parameter

A map without its list equivalent is not something a call site can express.

- `places` is **required** and refuses an empty list.
- The rows are rendered **by this widget**, from that list.
- There is **no parameter that hides them** — no `showList`, no
  `accessibleMode`, no `listBuilder` that could return something else. The
  seven parameters are `places`, `map`, `zoom`, `listLabel`, `selection`,
  `onPlaceSelected` and `placeActionHint`, and no combination of the last three
  removes a row.

This is the same move `IuxDestructiveFlow` makes with `IuxWayBack`: something
everybody agrees is required becomes a thing somebody has to declare, rather
than a thing somebody remembers.

### The alternatives, and why each was rejected

| Alternative | Why not |
| --- | --- |
| `semanticLabel` on the map | A described image. Says how many, never which. Argued above. |
| An optional `places` list, defaulting to none | The default is the failure. The caller who never read this page is exactly the one who leaves it empty, and the screen looks finished either way. |
| A `IuxMapShell` and a separate `IuxPlaceList` the caller composes | Composition can omit one half, silently, and reviews do not catch an absence. It also puts the ordering contract in two places. |
| An assertion that a `semanticLabel` is non-empty | Enforces that a sentence exists, not that it is an equivalent. `'map'` passes. |
| A lint rule | Not enforceable at the point of use, and IUX has no lint package shipping yet. A type is available today. |
| Documentation | The thing this project has repeatedly found does not survive a deadline. IUX-STATUS-001 states the general form: making the words structural rather than recommended is the only version of the rule that survives. |

### What it buys: the map can be hidden outright

Because the list is guaranteed, the map subtree is removed from the semantics
tree through `IuxSemantics.decorative`.

That is only defensible as a pair. Hiding a map with no text equivalent is
deleting the content. Leaving a platform map view in the tree is leaving a pile
of unlabelled nodes that a screen-reader user swipes through and learns nothing
from. Both halves are asserted in one test, so neither can be changed without
the other being looked at.

**Measured**: the stand-in map in the test suite contributes a single, clearly
labelled semantics node — the easiest possible case for the pattern to leave
alone — and it is absent from the traversal. The list heading and all three
rows are present in the same traversal.

## The list is a peer, not a fallback

It is on screen, always, below the map. Three arrangements were considered.

**A switch ("accessible view").** Rejected. The user has to know it exists, and
until they find it the default state of the screen is a map with no text
equivalent — the state SC 1.1.1 forbids. It also takes the list away from
everyone else: scanning a round as text is faster than reading it off a map,
and that is not a screen-reader-specific benefit.

**A draggable sheet**, which is what every consumer map application does.
Rejected on two grounds. Dragging a sheet open is a path-based gesture, so
SC 2.5.1 then requires a single-pointer alternative for the *sheet* as well as
for the pinch — a criterion bought rather than met. And collapsed it shows one
row, which is a disclosure wearing a different shape.

**Both on screen.** Adopted, and the cost is real. Measured on 320×640 with a
round of eight, counting a row as visible only when its title can be hit at its
centre — a conservative metric that scores a half-visible row as zero:

| Text | Map | List viewport | Rows visible |
| --- | --- | --- | --- |
| 100% | 256 px | 304 px | 2 of 8 |
| 150% | 171 px | 389 px | 2 of 8 |
| 200% | 128 px | 424 px | 1 of 8 |
| 300% | not drawn | 640 px | 1 of 8 |

Two rows out of eight is a worse overview than a sheet dragged to full height
would give. It is a worse overview that is always there, that nobody has to
discover, and that costs no gesture. Every row is reachable by scrolling in one
direction, which is what SC 1.4.10 asks for — and **the fortieth row of forty
is measured hit-testable and activated at 100%, 150%, 200% and 300%**.

## The map yields, the list never does

The map region takes **two fifths** of the height it is given **divided by the
user's text scale**, capped at **360** logical pixels, and if that leaves it
under **120** the map is not drawn at all and the list takes the whole height.
The zoom controls go with it, because controls for a camera nobody can see are
two dead targets in the thumb zone.

The asymmetry is the point: **the list is the equivalent of the map, and the map
is not the equivalent of the list.** When the two compete for the same pixels,
the space goes to the one everybody can read. A 90-pixel band of tiles is not a
map anyone navigates by, so nothing that was working is lost.

**The division by the text scale was a measurement, not a preference, and it
changed the design.** The first version held the share fixed. Measured on
320×640 at 300% text, that left the list 304 pixels for rows whose titles alone
are 144 pixels tall, and **not one place was fully visible until the user
scrolled** — behind a 256-pixel map whose own street labels do not scale, and
are therefore *harder* to read for the same person. Dividing applies the
asymmetry above continuously rather than only at the cliff edge. The cost is a
cliff between about 200% and 210% text, where the map disappears; the benefit is
that the half with no equivalent stops being the half that gets squeezed.

The three numbers are hypotheses, not measured optima. What is measured is the
behaviour they produce, and a test pins each value: on 320×640, **256 px at
100%, 170.67 at 150%, 128 at 200% and no map at 300%**; 360 px in a 1200-px
window; 120 px under an unbounded height; and no map at all in a 260-px box.

**Unbounded height** — inside a `ListView`, a `SingleChildScrollView`, an
`IuxPage` — gives the map its minimum and adds no scroll view of its own. That
discriminator is `IuxEmptyState`'s and it is not a heuristic: every vertical
scroll view in Flutter hands its children an unbounded height, which is what
makes it a scroll view. Exactly one `Scrollable` is measured in both
arrangements.

The selection status line sits **inside** the scrolling region rather than above
it, and that is a measurement rather than a preference. Everything above the
list is a fixed height the map must fit inside; on a 320-tall viewport at 300%
text a long selection sentence wraps, and hoisting it above the `Expanded`
produces `A RenderFlex overflowed by 572 pixels on the bottom`. A test pins it.

## Pinch is never the only way to zoom

A pinch is a multipoint gesture. SC 2.5.1 (Pointer Gestures, level A) requires
that anything operated by one can also be operated with a single pointer, and
SC 2.1.1 (Keyboard, level A) requires the same functionality from a keyboard,
which cannot pinch at all.

`zoom` is required and sealed. There are exactly two honest answers:

| Answer | The claim |
| --- | --- |
| `IuxZoomControls` | the map zooms, and here is the route that is not a gesture |
| `IuxZoomFixed` | the map does not zoom, so there is no gesture to replace |

There is no third member and no default. A default would be one of those claims
made on the caller's behalf about a widget IUX cannot inspect, and the
direction it would be wrong in is the expensive one: a map left zoomable with no
controls looks finished and is unusable.

Both callbacks are non-nullable, so a user who can zoom in and cannot zoom out
is not a state that exists. Neither control is ever disabled: IUX has no camera
and no maximum, and a control greyed for a reason it cannot state is the silent
refusal `IuxFormSubmit` refuses to ship.

**The controls are under the map, never over it**, and that is a contrast
decision. A control floating over tiles has no determinate contrast ratio at
all — the background is a photograph the theme has never measured, and it
changes as the user pans. This is the same reasoning as IUX-A11Y-006 (an opacity
over an unknown background has no determinate ratio) and IUX-HELP-001's caveat
about a tooltip outline over a photograph. IUX has one honest place to put a
control it is asked to guarantee 3:1 for, and that is the page surface where
`IuxButton`'s measurements hold. The cost is a strip of vertical space.

## What IUX guarantees, and what is yours

The marker question — SC 1.4.1 (Use of Color) and SC 1.4.11 (Non-text
Contrast) — is where this division matters most, because IUX does not draw the
marker.

| | Guaranteed by IUX, and tested | Yours |
| --- | --- | --- |
| Marker identity | every place carries a non-empty `ordinal` that is not a colour; it is drawn in the list and announced before the name | painting the same token on the marker |
| Marker contrast | nothing | 3:1 against the tiles behind it (SC 1.4.11) |
| Marker size | nothing | a target a thumb can hit |
| Marker meaning | the name, the address and the distance are on screen as text | that the marker for stop 3 is where stop 3 is |
| Zoom | a named, single-pointer, keyboard-reachable pair of controls, on a measured surface | that they move the camera; that the pinch is not the only route in the widget itself |
| Selection | the selection is announced and shown as words | the highlight on the map |
| Tiles | nothing at all | that they arrive, and what the screen shows when they do not |

The honest summary of the SC 1.4.1 half: **IUX guarantees that a non-colour
identity exists and is shared. It cannot guarantee that you used it.**
`ordinal` being required is the strongest available form of that: a caller who
has to supply "3" for the list has it to hand for the marker.

## There is no empty branch, and no loading branch

An empty round is refused at construction, and the assertion names all four
causes. "No places" is not one situation:

| Situation | `IuxEmptyStateCause` | The way out |
| --- | --- | --- |
| nobody has scheduled a round | `IuxNothingCreatedYet` | create one, or say who does |
| a filter excluded every visit | `IuxNoMatches` | a reset, which that cause requires |
| this user may not see the round | `IuxAccessRestricted` | obtain access |
| every visit is done | `IuxNothingLeftToDo` | none is owed |

No fifth cause was invented and none was needed. An `empty` branch here would
flatten the four into one word, which is the argument `IuxLoadState` already
makes for having no `empty` state of its own.

A round that has not answered yet is `IuxLoadState`, and the region that renders
the wait and the failure is `IuxLoadingRetry`, one level up:

```dart
IuxLoadingRetry<List<Visit>>(
  state: controller.state,
  loadingLabel: l10n.loadingTodaysRound,
  failureCategoryLabel: l10n.error,
  recovery: IuxRetryRoute(label: l10n.tryAgain, onRetry: controller.load),
  builder: (BuildContext context, List<Visit> round) => round.isEmpty
      ? IuxEmptyState(
          cause: IuxNothingCreatedYet(create: schedule),
          title: l10n.nothingScheduledToday,
        )
      : IuxPlaceMap(places: ..., map: ..., zoom: ..., listLabel: ...),
)
```

No state machine was invented. The load state is taken rather than owned for the
same reason `IuxEmptyState` does not take one: the two patterns meet at exactly
one point and neither knows the other's vocabulary.

**The one wait this pattern genuinely cannot see is the map's own tiles.** They
load over the network, inside a widget IUX does not own and cannot observe
without touching the platform. If they never arrive, the caller's map shows a
blank square and nothing in IUX knows. The list is unaffected, which is the
strongest single argument for it being there.

## Selection, and why no row is tinted

`selection` names the current place and carries the caller's own sentence for
it. That sentence does two jobs:

1. it is announced through a live region when it changes;
2. it is the accessible name of the matching row for as long as it holds.

So it must be written as a **name**, not as an event. "Stop 3 of 8, Renshaw &
Co, selected" reads correctly in both roles; "You have just selected stop 3"
reads correctly in neither.

**No row changes colour.** A fill is the canonical SC 1.4.1 failure — a state
carried by colour alone — and this pattern has no second visual signal to pair
with it that would not be a word IUX composed. Three alternatives were weighed:

- **`IuxListItem.selectable`**, which announces `checked`. Rejected: it is
  checkbox vocabulary for a single choice, and tapping the current row would
  announce an unchecking that means nothing here.
- **`IuxSemantics.selection` with `IuxSelectionRole.radio`**, which is the
  expression IUX-NAV-002 settled on for one-of-many. Rejected because it sets
  `excludeSemantics: true`: the address and the distance — the two things that
  make a place findable — would be deleted from every row. That is the
  information this pattern exists to preserve.
- **A tint drawn around the row.** Not possible from outside: an interactive
  `IuxListItem` paints its own background edge to edge, so an outer decoration
  is covered.

The words carry it instead, and the status line is visible as well as
announced — so a sighted user on a monochrome display gets it too.

## Focus

**Focus never moves.** Not when the selection changes, not when the list
rebuilds, not when a row is activated. There is no `IuxFocus.request` in either
file, pinned mechanically as well as behaviourally.

This is the eighth IUX pattern to decide focus, and the line held is still
IUX-033's — *did the user ask for this?*

- Selecting a place **in the list** is a user action, and the user is already
  standing on the row they used. Moving them anywhere would be answering a
  question they did not ask.
- Selecting one **on the map** is an action a screen-reader or keyboard user
  cannot perform at all, because the map is not in the focus order or the
  semantics tree. A focus move for it would land somebody somewhere in response
  to an event they could not have caused.

Both are the `IuxEmptyState`/`IuxLoadingRetry` shape rather than the
`IuxValidationSummary` shape. The measurement: a focus node parked outside the
pattern keeps primary focus across a selection change and across a row
activation.

## The string cost, stated rather than hidden

The framework composes nothing. Every place name, address, distance, ordinal,
unit, heading, control name, hint and selection sentence arrives already
formatted and localised.

That is expensive here, and the figures are worth having:

| Measure | Count |
| --- | --- |
| public fields across the four types | 18 |
| of those, strings the caller must localise | **9 — exactly half** |
| of those nine, strings a sighted user never sees | **3 (`zoomInLabel`, `zoomOutLabel`, `placeActionHint`) — a third** |
| strings for one round of eight places, every field supplied | 37 |
| of those 37, never on screen | 3 |

The pilot measured its own version of this cost at 19% of `lib/`, with 17 of its
99 strings never appearing on screen. This pattern is denser on both counts,
and the second row is the one worth pausing on: **a third of the strings this
API asks for are invisible to the developer testing the screen.** A zoom control
with an untranslated label looks perfect in every screenshot.

The one field that is *not* a string to translate is `IuxPlace.id`. It is never
shown and never spoken, and the documentation says so, because the alternative
is a translator being handed a list of work-order numbers.

There is no latitude and no longitude anywhere in this API. IUX draws no map, so
it has nothing to do with a coordinate except hold it, and a field nothing reads
is the dead API `PROJECT_PROMPT.md` §19 forbids. `id` ties a marker back to a
row.

## States

| State | What happens |
| --- | --- |
| default | map, zoom controls, list |
| no places | refused at construction; `IuxEmptyState` names the situation |
| one place | a list of one; nothing special-cased |
| forty places | all built eagerly; the last is reachable and activatable at every scale |
| loading | not this pattern's; `IuxLoadingRetry` one level up |
| failed | likewise |
| tiles not loaded | invisible to IUX; the list is unaffected |
| a place selected | announced, named on its row, not tinted |
| viewport too short | the map is dropped, the list keeps everything |
| unbounded height | the map takes its minimum; no second scroll view |

## Known limitations

**A row does not announce that it is the selected one unless the list is
interactive.** The name comes from `IuxMapSelection.announcement`, and
`IuxListItem`'s plain form takes no `semanticLabel` by design. With
`onPlaceSelected` null the status line is the only carrier.

**The rows are built eagerly.** This is `IuxListGroup`: two hundred places
build two hundred rows. A round is a day's work — five to forty stops — and
forty is measured. A set large enough to need recycling is not a round and wants
a `ListView.separated` the caller owns.

**Inside a scroll view the map competes for the drag.** A platform map view
consumes vertical drags to pan, so a drag starting on the map may not scroll the
page. Giving the widget a bounded height avoids it entirely, and that is the
usual arrangement.

**A long `ordinal` steals width from the name.** It is capped at the width of a
touch target and wraps inside its own box rather than squeezing the title — the
failure IUX-LISTITEM-TRAILING-001 recorded at the other end of the row — but a
ten-character ordinal will make every row taller. Keep it short; that is what
it is for.

**`IuxZoomFixed` is a claim IUX cannot verify.** Declaring it while leaving
`zoomGesturesEnabled` on is undetectable from here. The type makes the decision
explicit and reviewable, which is all a package that touches no platform can do.

**A live region is a request, not a guarantee.** Whether the platform speaks
the selection, and when, is the platform's decision. A widget test asserts the
node carries the flag and no more.

## What is measured here, and what needs a device

Everything in this column is asserted by
`test/patterns/iux_place_map_test.dart` — 42 tests, with ten deliberate
mutations of the implementation confirmed to be caught:

- every place's ordinal, name, address and distance is on screen as text and in
  the semantics tree;
- the caller's map contributes nothing to the semantics tree;
- a row is one merged utterance with the ordinal first;
- both zoom controls are named, carry a tap action, and activate exactly once;
- `IuxZoomFixed` draws none, and a dropped map drops them;
- the map is 256 / 170.67 / 128 px and then absent at 100 / 150 / 200 / 300%
  text on 320×640, capped at 360 in a tall window, 120 under an unbounded
  height, and absent in a 260-px box;
- exactly one `Scrollable`, standalone and nested;
- no overflow at 100 / 150 / 200 / 300%, standalone and nested, and on a
  320-tall landscape viewport at 300% with a four-line selection sentence;
- the fortieth of forty rows is hit-testable and activates at every scale, and
  the zoom control does too wherever the map is drawn — and is absent wherever
  it is not;
- the selection is a live region, the selected row names itself, the others do
  not;
- focus is unchanged across a selection change and across a row activation;
- every painted string and every spoken string came from the call site;
- no platform import, no map SDK token, no `IuxFocus`.

**None of this touches a tile.** The following need a device and a person:

- that the markers exist, are where they should be, carry the ordinal, meet 3:1
  against real tiles and are large enough to hit;
- that the pinch actually zooms, and that `IuxZoomFixed` is true when claimed;
- that TalkBack speaks the live region, and when;
- that hiding the map subtree is right against a **real** `GoogleMap` rather
  than the single-node stand-in used here — a real SDK may expose nodes worth
  keeping, and this pattern removes them;
- that 128 px of map at 200% text is usable rather than merely present, and
  that taking it away entirely at 300% is the right trade for the person who
  set 300%;
- what the screen looks like when the tiles never arrive;
- the drag conflict between map pan and page scroll, which cannot be reproduced
  without a platform view;
- that the ordinal in the list and the ordinal on the marker read as the same
  thing to a user.

## Evidence level

**Standard** for the obligations: SC 1.1.1 (the text equivalent), SC 2.1.1 and
SC 2.5.1 (the zoom equivalent), SC 1.4.1 (no meaning by colour alone), SC 1.4.11
(3:1 for graphical elements), SC 1.4.4 and SC 1.4.10 (text scaling and reflow),
SC 4.1.2 (name, role, value).

**Context dependent** for the design decisions: that a list is the right
equivalent for a *place* map, that hiding the map subtree is the right trade,
that the list belongs on screen rather than in a sheet, and that the map is the
half that yields.

**Hypothesis** for the four layout decisions — two fifths, 120, 360, and
dividing the share by the text scale — and for the claim that a shared ordinal
genuinely helps a user match a row to a marker. None has been validated with
users; the division is argued from a measurement of what the alternative cost,
which is not the same as knowing it is right.

**Unverified** for everything the map itself renders. See the section above.

## Sources

- WCAG 2.2 — SC 1.1.1, 1.4.1, 1.4.4, 1.4.10, 1.4.11, 2.1.1, 2.5.1, 4.1.2.
- `docs/components/component-standard.md` §5, §6, §8, §11.
- `PROJECT_PROMPT.md` §5 (accessibility outranks ergonomics), §19–23, §30.
- IUX-031 (the platform-purity parse), IUX-033 (*did the user ask for this?*),
  IUX-STATUS-001 (structural beats recommended), IUX-A11Y-006 and IUX-HELP-001
  (contrast over an unknown background), IUX-NAV-002 (single selection),
  IUX-LISTITEM-TRAILING-001 (a non-flex row child takes what it wants),
  IUX-A11Y-REACH-001 (`findsOneWidget` is not evidence a control can be
  pressed), IUX-QA-VACUOUS-003 (the overflow teardown).
