# IuxNavigationDrawer

A modal panel at the leading edge holding the places the user can go.

## Purpose

An application with more top-level sections than a bar can hold has to put the
rest somewhere. A drawer is that somewhere: it costs nothing until it is
opened, and it can then be as long as it needs to be, because it has the whole
height of the screen and a full-width row for every name.

It holds **places**, and nothing else. Every row takes the user somewhere they
can come back from, so the user can activate any of them without first working
out which kind of row they are looking at. That is the whole rule of the
surface, and it is what makes the surface learnable.

```dart
Widget build(BuildContext context) {
  final Widget page = IuxPage(child: body);
  if (!state.menuOpen) return page;
  return Stack(
    fit: StackFit.expand,
    children: <Widget>[
      page,
      IuxNavigationDrawer(
        title: l10n.mainNavigation,
        dismissLabel: l10n.closeMenu,
        onDismiss: controller.closeMenu,
        selectedIndex: state.section,
        destinations: <IuxNavigationDestination>[
          IuxNavigationDestination(label: l10n.home, icon: Icons.home_outlined),
          IuxNavigationDestination(
            label: l10n.orders,
            icon: Icons.receipt_long_outlined,
            selectedIcon: Icons.receipt_long,
            badge: IuxBadge.count(
              count: l10n.formatCount(pending),
              label: l10n.ordersAwaitingApproval(pending),
            ),
          ),
          IuxNavigationDestination(
            label: l10n.settings,
            icon: Icons.settings_outlined,
          ),
        ],
        onDestinationSelected: controller.goTo,
      ),
    ],
  );
}
```

The shape of that `build` is not incidental. See *How to place it*.

## Use when

- The application has more top-level sections than a bar can hold — practically,
  more than five.
- Some sections are visited rarely enough that a permanent strip of the screen
  is not worth spending on them.
- The set of sections is stable enough that a user can learn where things are.

## Do not use when

- **Three to five sections the user moves between constantly.** That is
  `IuxBottomNavigation`, and it is better at this: the destinations are visible
  without a gesture, they say where the user is without being opened, and they
  are in reach of a thumb. A drawer hides all three behind one tap and a modal
  interruption.
- **The rows are actions.** "Sign out", "Export", "Rate this app" are not
  places. Mixing them with "Orders" makes the user guess which rows they can
  come back from, and they make the guess behind a scrim with the page gone.
- **A decision that must be answered.** That is `IuxDialog`.
- **Content the user works in.** That is `IuxBottomSheet`. A drawer holds a list
  of places and nothing else — there is no `child` parameter, deliberately.
- **Settings, filters or an account panel.** They are not places, and a surface
  whose rows do different kinds of thing is a surface with no rule the user can
  learn.

## It is a layer, not a route

Like `IuxDialog` and `IuxBottomSheet`, the drawer is a layer the parent places,
not a route it pushes. The back stack, deep links and state restoration belong
to the application; a component that quietly pushed onto them could not be
reasoned about from the call site.

The parent owns a flag, and the drawer exists exactly while the flag is true —
which also means it cannot be left open by a code path that forgot to pop.

It follows that **the drawer does not close itself when a destination is
chosen**:

```dart
// Wrong: the component owns where the user is, and whether it is open.
IuxNavigationDrawer(onDestinationSelected: (int i) => Navigator.push(...))

// Right: the parent owns both.
IuxNavigationDrawer(
  selectedIndex: state.section,
  onDestinationSelected: (int i) => controller.goTo(i, closeMenu: true),
)
```

`onDestinationSelected` reports which row the user activated. The parent changes
the section *and* lowers the flag. A drawer that closed itself would leave the
parent's flag saying it was still open, and the next frame would put it back.

## How to place it

`IuxModalLayer` has a `drawer` slot, added with this component at IUX-027 and
mutually exclusive with the dialog and sheet slots. **Use it**, and the rest of
this section explains what it is protecting you from:

```dart
IuxModalLayer(
  drawer: isOpen ? IuxNavigationDrawer(/* … */) : null,
  child: page,
)
```

If you assemble the stack yourself instead, the shape is not a matter of taste:

```dart
// Wrong.
Stack(children: <Widget>[page, if (open) drawer])

// Right.
if (!open) return page;
return Stack(fit: StackFit.expand, children: <Widget>[page, drawer]);
```

The reason is measured, not assumed. `BlockSemantics` removes the siblings
painted before it — but only when their semantics are recompiled. In the first
shape the page's element survives the change, its semantics node is reused, and
the covered page **stays in the semantics tree**: a screen-reader user can still
read and activate a page they cannot see or touch. In the second shape the page
leaves the tree, its subtree rebuilds, and it disappears as intended.

Touch behaves identically in both shapes — the scrim covers the page either way
— which is exactly why the wrong shape is invisible without a screen reader.
Both halves of that are pinned by tests in
`test/components/iux_navigation_drawer_test.dart`.

This is **IUX-OVERLAY-001**, first recorded on `IuxModalLayer` and reproduced
here. The right shape has the cost that mission already recorded: the page
changes depth when the drawer opens, so its subtree rebuilds and a list scrolled
to 400 snaps back to 0. `PROJECT_PROMPT.md` §5 puts accessibility above
ergonomics, so the scroll loss stays.

## There is always a way out, and none of them is a gesture

`onDismiss` is required, and **four** things call it: the scrim, the Escape key,
the system back gesture, and a labelled button in the header. No flag turns any
of them off.

There is deliberately **no swipe-to-close**. A swipe is invisible to a screen
reader and out of reach for many motor-impaired users, so it can only ever be a
shortcut over a real control, never the control itself.

### The system back gesture, and how this differs from the dialog

The drawer answers the system back itself, through a `PopScope` that *declines*
the pop and reports the intent. Nothing is pushed and nothing is popped, so this
is not navigation; the parent still decides what happens next. Outside a
`Navigator` the `PopScope` registers against nothing and is inert, so the drawer
is safe to use there too.

`IuxDialog` and `IuxBottomSheet` leave this to the caller and document the
two-line `PopScope` they need. The drawer does not, and the reason is the
platform: a drawer is the one surface where an Android user reaches for back
*first*, before looking for a control. A modal a user cannot leave by the
gesture they will actually try is a trap under WCAG 2.2 SC 2.1.2 — and
"documented" is not the same as "works".

The inconsistency is real and is recorded here rather than hidden. Making the
three agree means either the dialog and the sheet gaining a `PopScope` too, or
this one losing it; the first is the better change and it is not this mission's.

## Every destination is named, always

There is no icon-only mode and no "label the current one" mode — see
`IuxNavigationDestination`. In a drawer the rule costs nothing at all: the rows
are full width, so a name has somewhere to wrap. Neither the heading nor a
destination name is ever truncated or ellipsised, at any text size.

## How the current destination is announced

The same three ways `IuxBottomNavigation` uses, deliberately: the two surfaces
answer the same question and must not invent two vocabularies for the answer.

1. **In the semantics**, as a checked member of a mutually exclusive group.
   Measured on the real tree: each destination carries `label`, `checked` (true
   *or* false — never absent), `inMutuallyExclusiveGroup`, and the `tap` and
   `focus` actions; the parent carries `SemanticsRole.radioGroup` and the
   drawer's title.

   "Checked" rather than "selected" is the point. A checked node is announced in
   both states, so the user hears "not checked" at the destinations they are not
   in. `selected` is announced only when true, which leaves them sweeping the
   whole list to find the one that said something.

2. **As a shape**: a filled band with an outline, behind the whole row. It
   survives a monochrome screen. The outline is drawn as well as the fill
   because surface contrast alone is deliberately gentle in IUX; the test
   measures the outline at ≥ 3:1 against the panel in both brightnesses.

3. **Optionally as a different glyph**, through
   `IuxNavigationDestination.selectedIcon`.

Colour is never the only signal. The current destination is never given a
heavier or larger label: that would change the text's measured width, so
choosing a destination would reflow the rows around it.

## What a screen reader actually hears

Measured, not described. With three destinations, the drawer is **five stops**,
in this order:

| Stop | Announced as |
| --- | --- |
| 1 | the title, as a heading |
| 2 | the dismissal, as a button |
| 3 | destination 1, with its state |
| 4 | destination 2, its badge, and its state |
| 5 | destination 3, with its state |

Three facts follow from that measurement.

**The way out is the first control**, before any destination. A way out found
only after twelve swipes is a way out most users never find, and in a drawer the
alternative to finding it is choosing a destination they did not want.

**The glyphs are not stops.** The name beside each one already says what the
destination is, and a screen reader that announced both would read every section
twice.

**The scrim is not a stop.** It dismisses, but it is not announced: the header
button says the same thing in words, and a second, invisible "dismiss" target
reachable only by swiping is a control a user cannot verify before activating.

The title appears on three nodes — the route, the heading, and the mutually
exclusive set — but only one of them is a stop. The route name is announced on
arrival; the group name is context the platform attaches to the destinations
("1 of 3"), not a place to land.

## Badges

A badge is laid out after the name, in reading order, and merged into the
destination's single announcement: "Orders, 3 orders awaiting approval,
checked". Never over the glyph — an overlay covers the thing it counts, clips as
soon as the user enlarges their text, and leaves the number and its subject in
two unrelated places for a screen reader.

This is why the destination uses a bare `Semantics` rather than
`IuxSemantics.selection`; see *Deviations* below.

## Focus

Measured, not assumed.

| Moment | Behaviour |
| --- | --- |
| on open | focus moves to the **panel**, never to a destination |
| while open | Tab cycles: dismissal → destination 1 → … → panel → dismissal |
| on close | focus returns to whatever held it **when the drawer opened** |

Focus landing on the panel rather than on the first destination is deliberate
twice over: a destination would put an Enter press one keystroke away from
navigating somewhere the user has not read yet, and it would announce a
destination before announcing what the list of destinations is. The panel
registers no keyboard activation of its own, so Enter pressed on an unread
drawer does nothing rather than something.

Focus is restored to where the user *was*, not to wherever it drifted while the
drawer was open. The covered page keeps rebuilding underneath — a stream
arrives, a field autofocuses — and can take focus programmatically even though
the user cannot reach it; returning them there would leave them somewhere they
never went.

The keyboard cannot leave the drawer. A `FocusScope` confines traversal, so Tab
never reaches the page behind the scrim: a page whose controls still answer the
keyboard while being visually behind a scrim is worse than one that is gone.

## Layout

The panel is anchored to the edge the reading direction starts at, spans the
full height, and takes the **smaller** of two widths:

- the width the names need, from `IuxContentWidth.narrow` — expressed in
  characters, so enlarging text *widens* the drawer instead of squeezing the
  same names into a narrower column;
- 80% of the screen, so there is always a strip of page left.

That strip is not decoration. It is what tells the user the page they came from
is still there, and it is the target they tap to get back to it. A panel that
reached the far edge would be a page — and a page has a title bar, a place in
the history and a back gesture that this surface cannot offer.

Measured, at `devicePixelRatio` 1:

| Screen | 100% text | 200% text |
| --- | --- | --- |
| 320 × 480 | 256 (80%) | 256 (80%) |
| 400 × 800 | 280 (70%) | 320 (80%) |
| 800 × 600 | 280 (35%) | 560 (70%) |
| 1280 × 800 | 280 (22%) | 560 (44%) |

On the narrowest screen IUX supports this leaves 64 logical pixels of page.

Everything scrolls, including the header, for the reason `IuxBottomSheet`
records: at 200% text on a short screen a pinned heading and button are taller
than the surface, and the destinations would get nothing at all. The header
being *first* keeps the cost small — the way out is visible when the drawer
opens and only leaves the viewport once the user scrolls past it deliberately,
and Escape, the scrim and the system back do not scroll anywhere.

The panel consumes the top, bottom and leading insets itself, inside the
surface, so the surface still reaches the physical edge. Never the trailing
inset: nothing of the panel is there, and padding for an obstacle that is not
there is a column of empty space between the names and the page.

## Targets

Every destination's interactive region is at least
`IuxAccessibility.minimumTouchTarget` tall, applied outside the focus ring so
the floor covers the region that responds rather than the part that is painted.
The whole row is the target, not the glyph and the word painted in the middle.

Destinations touch, with no spacing between them — the same call
`IuxBottomNavigation` and `IuxListItem` make, and for the same reason: the size
requirement is met outright, and a gap in a vertical list of rows is a dead
strip the user's finger can land in.

## API

### `IuxNavigationDrawer`

| Parameter | Type | Notes |
| --- | --- | --- |
| `title` | `String` | required, non-empty. Announced on arrival, drawn as the heading, and the name of the mutually exclusive set — one string, so three cannot disagree. Phrase it as what the set *is* ("Main navigation"), never as a mechanism ("Menu"). |
| `dismissLabel` | `String` | required, non-empty. The visible text of the way out. |
| `onDismiss` | `VoidCallback` | required. Called by the scrim, Escape, system back and the header button. Never called when a destination is chosen. |
| `destinations` | `List<IuxNavigationDestination>` | required, at least one, distinct names. No upper bound; the list scrolls. Never sorted here. |
| `selectedIndex` | `int` | required, in range. Owned by the parent; rendered, never changed. |
| `onDestinationSelected` | `ValueChanged<int>` | required. Called for the current destination too. |

All six are required and all are asserted. Quietly repairing a contradiction
would hide that the caller believed something untrue about their own navigation.

### `IuxNavigationDrawerTokens` / `IuxNavigationDrawerResolver`

One resolver for the panel, the header and the rows, so target size, type and
the mark for the current destination cannot drift apart.
`IuxNavigationDrawerResolver.resolve(context, current:, pressed:, hovered:)`
returns a value type: two resolutions of the same state are equal.

There is no `IuxNavigationDrawerTheme`, for the reason there is no navigation
bar theme and no list theme: every decision is already carried by the semantic
palette, the geometry and the typography an application configures once. A
dedicated extension would only have created a place to break the contrast
guarantee and the target floor.

## States

| State | Behaviour |
| --- | --- |
| default | panel at the leading edge, scrim over the page |
| focused | ring on the dismissal and on each destination, non-displacing |
| pressed | tint over the row, behind its content, never reducing its contrast |
| hovered | the same tint, weaker; a press wins over the hover it necessarily also is |
| current | fill + outline behind the row, and `checked: true` |
| disabled | **not expressible.** A destination that cannot be reached should not be in the list: showing a place the user is not allowed to go is worse than one fewer row. |
| loading | **not expressible.** The drawer renders a list it is given. |
| error | **not expressible.** |
| empty | **refused.** A drawer with no destinations is asserted against: there is no empty state to render, so do not open the drawer. |

## Themes and motion

Every colour comes from `IuxSemanticColors`, every metric from
`IuxGeometryTheme`, every duration from `IuxMotionPolicy`. Verified against the
four profiles — light, dark, and both at high contrast.

The scrim is **derived, not declared**: IUX has no scrim role, so it is
whichever of the two surface extremes the theme resolved *darker*, at a fixed
0.6 opacity. Picking by measured luminance rather than by brightness means the
scrim never brightens what it covers, which a fixed "inverse surface" would do
in dark conditions. The same 0.6 as `IuxDialog` and `IuxBottomSheet`: three
modal surfaces that dimmed the page by three different amounts would read as
three degrees of interruption when they are the same one.

The entrance is declared as `IuxMotionRole.reveal`, and the difference from
`enter` is the whole point:

| Preference | Entrance |
| --- | --- |
| full | travels in from the leading edge, its own width, while fading |
| reduced | **fades in place**, no travel |
| none | present at full opacity on the first frame |

`reveal` becomes a fade under a reduced preference rather than a shorter
journey, because a fast sweep across most of the screen is worse for a
vestibular disorder than a slow one, not better. `enter` would merely have
shortened the travel.

The indicator behind the current destination is a `stateChange` at the short
scale, animated separately. With motion off the animation goes and the indicator
stays: the information is the indicator, not the transition.

## Anti-patterns

```dart
// Actions in a list of places. Which of these can the user come back from?
destinations: <IuxNavigationDestination>[
  IuxNavigationDestination(label: 'Orders', icon: Icons.receipt_long_outlined),
  IuxNavigationDestination(label: 'Sign out', icon: Icons.logout),
]

// A drawer for three sections the user lives in. Use IuxBottomNavigation.

// Closing on selection, from inside the component.
onDestinationSelected: (int i) { controller.goTo(i); /* and nothing else */ }
// The parent must lower its own flag too, or the drawer reopens next frame.

// A permanent Stack. The covered page stays readable to a screen reader.
Stack(children: <Widget>[page, if (open) drawer])

// Two names that read the same. Refused at construction, and rightly.
IuxNavigationDestination(label: 'Reports', icon: ...),
IuxNavigationDestination(label: 'Reports', icon: ...),
```

## Limits

- ~~**No `IuxModalLayer` slot.**~~ **Closed at IUX-027.** The `drawer` slot
  exists, typed `IuxNavigationDrawer?` and mutually exclusive with the other
  two, so the correct shape is the only one a caller can express. See
  [How to place it](#how-to-place-it).
- **A longer dismiss label overflows the header** (`IUX-DRAWER-LABEL-001`).
  `dismissLabel: 'Close the menu'` overflows by 7.5 px at **100%** text on 800-
  and 1200-wide surfaces, where `'Close'` does not — the panel caps near 280 px
  whatever the screen. It only stacks past about 130% text, so enlarging the
  text fixes it and leaving it alone does not. Keep the label short.
- **IUX-OVERLAY-001.** Opening the drawer rebuilds the page's subtree, so a
  scrolled list behind it loses its position. The accessible alternative is
  worse; see *How to place it*.
- **No exit animation.** The drawer is removed from the tree by the parent, so
  there is no frame in which to animate a departure. The entrance is animated;
  the exit is instant.
- **`PopScope` is inconsistent with `IuxDialog` and `IuxBottomSheet`,** which
  leave the system back to the caller. Recorded above.
- **The badge is a widget slot** (typed `IuxBadge`, so it cannot be an arbitrary
  one). Its contents are the caller's.
- **The panel is a Tab stop.** Traversal cycles through it between the last
  destination and the dismissal. Harmless — it activates nothing — but it is one
  extra press, and it is the same behaviour `IuxDialog` has.
- **No section headers, no dividers, no nested destinations.** A drawer deep
  enough to need them is a navigation screen, and a navigation screen is a page.
- **Scrim colour duplicated.** The same derivation appears privately in
  `IuxDialog`, `IuxBottomSheet` and here. It belongs in one place — a
  `IuxSemanticColors` scrim role, or a shared internal helper — and moving it is
  a change to the semantic layer rather than to any of the three components.
- **TalkBack and Voice Access are not covered by these tests.** Widget tests
  read the semantics tree; they do not run a screen reader. The stop order, the
  group announcement and the back gesture need a device before they can be
  called verified on Android.

## Deviations from the Component Standard

### A bare `Semantics`, not `IuxSemantics.selection`

The same deviation `IuxBottomNavigation` recorded before it, for the same
reason. `IuxSemantics.selection` sets `excludeSemantics`, which would delete the
badge from the interface of every screen-reader user: "Orders, 3 orders awaiting
approval" would be announced as "Orders", and the number would exist for sighted
users only.

Merging instead gives one stop that reads the name, then what is waiting there,
then the state. The properties set are exactly the ones
`IuxSemantics.selection` sets for `IuxSelectionRole.radio` — a set of
destinations *is* a mutually exclusive selection and must not invent a second
vocabulary for saying so.

There is also **no `SemanticsRole.radio`** in Flutter: the enum offers
`radioGroup` and `menuItemRadio`, and nothing for a plain radio child. So
`checked` plus `inMutuallyExclusiveGroup` is not a preference, it is the only
available way to say what a destination is. And a node holds **one** role, so
the group cannot be both `radioGroup` and the `navigation` landmark; it keeps
`radioGroup`, because the landmark helps a user find a surface they have already
opened, while the group role is what makes "where am I" audible at all.

### `IuxTapTarget` is not used

The same reason `IuxBottomNavigation` and `IuxListItem` give: it declares
`button: true` on its own node, which would contradict the destination's role.
The floor value is read from `IuxAccessibility.minimumTouchTarget` — the same
source `IuxTapTarget` reads — and applied with a `ConstrainedBox` outside the
focus ring.

### The component answers the system back gesture

§1 says a component holds no navigation. It still holds none: `PopScope` with
`canPop: false` pushes nothing and pops nothing, and the parent decides what
happens. Recorded because the line is thin and the other two modals sit on the
other side of it.

## Evidence

| Rule | Level | Basis |
| --- | --- | --- |
| Focus moves into the drawer and returns on close | **Standard** | WCAG 2.2 SC 2.4.3, 2.1.1 |
| Focus is trapped while the drawer is open | **Standard** | WAI-ARIA Authoring Practices, dialog pattern |
| Escape and the system back both dismiss | **Standard** | WCAG 2.2 SC 2.1.2 (no keyboard trap); Android platform expectation |
| The covered page leaves the semantics tree | **Standard** | WCAG 2.2 SC 4.1.2; Android accessibility guidance |
| The route is scoped and named | **Standard** | Android accessibility guidance; Flutter route semantics |
| Selection state announced, not only painted | **Standard** | WCAG 2.2 SC 4.1.2 |
| Colour is never the only carrier of the current destination | **Standard** | WCAG 2.2 SC 1.4.1 |
| Targets ≥ `minimumTouchTarget` | **Standard** | Android accessibility guidance; WCAG 2.2 SC 2.5.8 |
| Names never truncated; usable at 200% | **Standard** | WCAG 2.2 SC 1.4.4, 1.4.10 |
| Focus visible and non-displacing | **Standard** | WCAG 2.2 SC 2.4.7, 2.4.11 |
| Motion routed through a reduced-motion policy | **Standard** | WCAG 2.2 SC 2.3.3 |
| Every word comes from the caller | **Standard** | WCAG 2.2 SC 3.1.1/3.1.2 in spirit; IUX rule enforced by `test/accessibility/no_composed_strings_test.dart` |
| The way out precedes the destinations | **Strong guidance** | WAI-ARIA APG dialog pattern; Material drawer guidance |
| Focus lands on the panel, not on a destination | **Strong guidance** | WAI-ARIA APG, "least destructive initial focus" |
| A drawer holds places, never actions | **Strong guidance** | Material navigation drawer guidance; Nielsen Norman Group on the "hamburger menu" as a grab bag — *to_verify*, the specific NN/g article has not been re-read for this mission |
| No swipe-to-close as the only exit | **Strong guidance** | WCAG 2.2 SC 2.5.1 (pointer gestures) applied by analogy; the criterion concerns path-based gestures |
| Re-selecting the current destination is reported | **Context dependent** | Common Android idiom, undiscoverable. IUX reports the gesture and takes no position on what it means. |
| Indicator carries an outline as well as a fill | **Context dependent** | Follows `IuxSurface`'s own rationale that surface contrast is intentionally gentle. Measured here at ≥ 3:1. |
| 80% maximum screen fraction | **Hypothesis** | A judgement. The consequences of getting it wrong in either direction are facts; that 80% is the crossover is not. Needs user validation. |
| The whole panel scrolls, header included | **Hypothesis** | Chosen because unreachable is worse than inconvenient, following `IuxBottomSheet`. No user evidence either way. |
| Scrim opacity of 0.6 | **Brand choice** | Not a measured optimum; consistency with the other two modals is the argument. |
| The drawer answers system back while the other modals do not | **Context dependent** | Platform expectation on Android is strong; the inconsistency is recorded above as a defect to close. |

## Sources

- WCAG 2.2 — SC 1.4.1, 1.4.4, 1.4.10, 1.4.11, 2.1.1, 2.1.2, 2.3.3, 2.4.3,
  2.4.7, 2.4.11, 2.5.1, 2.5.8, 4.1.2.
- WAI-ARIA Authoring Practices — dialog (modal) pattern.
- Android accessibility guidance — touch target size, `AccessibilityNodeInfo`
  checkable state, radio group position announcement, back gesture.
- Material Design 3 — navigation drawer: modal drawer, standard drawer,
  destination lists.
- `docs/components/component-standard.md` §1–§5, §7, §9–§12.
- `docs/components/bottom-navigation.md` — the shared vocabulary for
  destinations, and the precedent for both semantic deviations.
- `docs/components/dialog.md`, `docs/components/bottom-sheet.md` — the modal
  layer contract, the scrim and IUX-OVERLAY-001.
- `PROJECT_PROMPT.md` §5, §9, §16, §19–23, §31, §35–36.
