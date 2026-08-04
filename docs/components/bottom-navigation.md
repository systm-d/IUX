# IuxBottomNavigation and IuxNavigationDestination

## Purpose

Give an application three to five permanent places, say which one the user is
in, and report which one they asked for next.

```dart
Scaffold(
  body: IuxPage(
    // The bar below handles the bottom inset itself.
    insets: IuxPageInsets.topOnly,
    child: body,
  ),
  bottomNavigationBar: IuxBottomNavigation(
    label: l10n.mainNavigation,
    selectedIndex: section.index,
    destinations: <IuxNavigationDestination>[
      IuxNavigationDestination(label: l10n.home, icon: Icons.home_outlined),
      IuxNavigationDestination(
        label: l10n.messages,
        icon: Icons.mail_outline,
        selectedIcon: Icons.mail,
        badge: IuxBadge.count(
          count: l10n.formatCount(unread),
          label: l10n.unreadMessages(unread),
        ),
      ),
      IuxNavigationDestination(label: l10n.account, icon: Icons.person_outline),
    ],
    onDestinationSelected: controller.goTo,
  ),
)
```

## Use when

- The application has three to five sections that exist for its whole life.
- The user moves *between* them rather than *through* them: they are peers, and
  none is a step towards another.
- All of them are reachable at all times.

## Avoid when

- **The sections are steps of a task.** A checkout or a wizard has an order and
  a meaning for "back". A bar that lets the user leave step two for step four
  is a bar that produced an invalid order.
- **You are switching a view inside one section.** Filters, "All / Unread /
  Archived", a date range — that is a tab strip, and it belongs *inside* the
  section rather than under the whole application.
- **There are two destinations, or six.** Both are asserted. Two is a toggle
  wearing a navigation bar; six is a menu. See *Three to five* below.
- **One of the entries is an action.** "New message" is not a place. A bar that
  mixes places with actions makes the user guess which taps take them somewhere
  they will have to come back from.
- **A destination is sometimes unreachable.** There is no disabled state and
  there will not be one: a permanent strip of the screen advertising a place the
  user is not allowed to go costs more than one fewer destination.

## It does not navigate

The bar reports which destination was chosen. It pushes no route, owns no
navigator, and keeps no index of its own.

```dart
// Wrong: the component owns where the user is.
IuxBottomNavigation(onDestinationSelected: (int i) => Navigator.push(...))

// Right: the parent owns it and tells the bar what to render.
IuxBottomNavigation(
  selectedIndex: state.section,
  onDestinationSelected: controller.goTo,
)
```

This is the Component Standard §1 and §3 applied to the one component most
often written the other way. Only the application knows whether a section has
its own history to restore, whether an unsaved form must be confirmed first, or
whether the user may leave the screen they are on at all. If the parent does not
re-render with a new `selectedIndex`, the indicator does not move — which is
correct, because a bar that marked the new destination and then failed to reach
it would be showing the user something untrue.

### Choosing the current destination is reported too

`onDestinationSelected` fires when the user taps the section they are already
in. This is the one place the bar deliberately differs from `IuxRadioGroup`,
which swallows a choice that changes nothing.

A radio's already-chosen option cannot be unchosen, so activating it is a no-op
and reporting it would have parents re-running whatever a choice triggers.
Re-selecting the current *destination* is different: it is a distinguishable
gesture with an established meaning — return to the top of this section — and
only the parent knows whether it means anything here. Swallowing it removes a
capability the parent has no other way to get; reporting it costs a parent that
does not want it one idempotent rebuild.

## Labels: every destination, always

There is no `labelBehavior`, no `showLabel`, and no icon-only form.

**Icon-only navigation is a guessing game.** A house and a magnifier are
learned; a stack of horizontal lines, a square with an arrow, and three dots
are not, and they mean different things in different applications. The user
finds out which kind they are looking at by tapping, which is the one thing
navigation should never require.

**Labelling only the current destination is worse.** It tells the user the name
of the one place they already know they are, and keeps the other four secret
until they visit them. It also moves the layout every time the user chooses:
the widest column changes, so all of them do.

### What that costs, measured

The names are never truncated, at any text size, so the bar's height is
intrinsic and grows. On a 320-pixel-wide screen with short names
(`Home`, `Messages`, `Search`, `Alerts`, `Account`):

| Text scale | 3 destinations | 5 destinations | Arrangement |
| --- | --- | --- | --- |
| 100% | 92 px | 112 px | row of columns |
| 125% | 108 px | 158 px | row of columns |
| 150% | 180 px | 300 px | stacked |
| 200% | 216 px | **360 px** | stacked |
| 300% | 368 px | 640 px (scrolls) | stacked |

The mission's test case — 200% text, 320 px, five destinations — costs 360 px
of a 640-pixel screen, and every name is whole and on one line. The defence is
what the alternatives cost:

- **Hide the labels**: 5 × 48 px ≈ 100 px, and a user at 200% text, who is the
  most likely to be reading with a magnifier, is left with five unlabelled
  glyphs.
- **Keep the row and let the names wrap**: about 230 px, and `Notifications` in
  a 56-pixel column at 28-pixel type breaks as `Noti / fica / tion / s`. That is
  not a smaller cost; it is the same space spent on something unreadable.
- **Truncate**: `Notific…` and `Notifi…` are the same word to a user who is
  scanning, and truncation gets worse exactly when someone has enlarged their
  text in order to read it.

The 130 px difference between hiding the names and keeping them is the price of
an application whose sections can be identified without visiting them. IUX pays
it.

### The two arrangements

The cost is paid by changing the arrangement rather than by hiding anything.

- Below roughly 130% text — `IuxAccessibility.prefersStackedLayout` — the
  destinations share one row, each a column of glyph over name.
- Above it they stack, each destination a full-width row of glyph beside name,
  so a name has 320 pixels to fit in rather than 56.

That threshold is the same runtime signal `IuxListItem` uses to move a value
under its title, and the reason is identical: a fraction of a phone width stops
holding a word long before the user stops enlarging their text.

Keep names short. The bar is as tall as its longest name needs: `Notifications`
across five 64-pixel columns makes a 152-pixel bar at 100% text, where `Alerts`
makes a 112-pixel one. A name that needs a sentence belongs to a section this
bar should not be offering.

## How the current destination is announced

Colour is never the signal. The current destination is marked three ways, and
only one of them is a hue.

### 1. In the semantics

Each destination is announced as a checked member of a mutually exclusive group
— exactly the properties `IuxSemantics.selection` gives `IuxSelectionRole.radio`
— and the bar itself as a named radio group:

```text
"Main navigation"
"Home, not checked, radio button, 1 of 3"
"Messages, 3 unread messages, checked, radio button, 2 of 3"
```

**Why `checked` rather than `selected`.** A checked node is announced in both
states, so a screen-reader user hears "not checked" at the four destinations
they are not in and learns where they are from the first one they land on.
`selected` is announced only when true, which leaves the user sweeping the whole
bar to find the one that said something. The trade is that TalkBack says "radio
button" — which is at least the same word the application's own radio groups
use, rather than a vocabulary invented for navigation.

The membership flag is also what lets the platform count "2 of 5" natively,
without IUX composing that sentence in a language it does not know.

### 2. As a shape

A filled, outlined indicator sits behind the current destination's glyph. Its
*presence* is the signal, and presence survives a monochrome screen. The outline
is drawn as well as the fill because surface contrast is deliberately gentle in
IUX: an indicator resting on the fill alone would disappear for exactly the user
it exists for.

The indicator's space is reserved whether or not it is drawn. Choosing a
destination never resizes it, and in a row of equal columns a change in one
column moves all of them.

### 3. Optionally as a different glyph

`selectedIcon` takes a filled variant of the same glyph. It is a reinforcement,
never the signal, and it should stay recognisably the same symbol: a *different*
glyph would tell the user the destination changed identity when they arrived.

## Badges say what they count

`IuxNavigationDestination.badge` is typed as `IuxBadge`, not as a widget. That
is the whole mechanism: `IuxBadge` already refuses a bare number
(`IuxBadge.count(count: '3', label: '3')` asserts), and accepting any widget
here would have been a second, unchecked way to put a number on a destination.

The badge is laid out **after** the name in reading order — under it in the row
arrangement, beside it in the stacked one — and merged into the destination's
single announcement. Never over the glyph: an overlay covers the thing it
counts, clips the moment the user enlarges their text, and leaves the number and
its subject in two unrelated places for a screen reader.

## Targets

The mission's arithmetic: five destinations on a 320-pixel screen is 64 pixels
each, against a floor of 48.

Measured, at 320 px with five destinations, the interactive region of each
destination is **64 × 112** at standard density — width from the bar, height
from the content, both above the floor. The floor is asserted in the test suite
at all three densities, at both touch-target preferences, and at 150% and 200%
text.

**The destinations touch.** They partition the bar edge to edge, with no
`kIuxMinimumTargetSpacing` between them, and that is a deliberate reading of
Component Standard §5 rather than an oversight — the same one `IuxListItem`
records for adjacent rows. WCAG 2.2 SC 2.5.8 treats spacing as an *alternative*
to size for targets below 24 CSS pixels; at 48 and above the size requirement is
met outright. Inserting a gap here would create four dead strips in the part of
the screen a thumb reaches most, where a tap does nothing at all — and unlike a
mis-tap, which costs one tap back, a dead tap teaches the user the bar is
unreliable.

The interactive region is also the full height of the bar, not the box the glyph
and name happen to need. There is no band above the shortest destination that
looks tappable and is not.

## Nothing may be pinned over it

**The bar refuses to build underneath an `IuxTransientLayer`**, on every build,
through `IuxTransientLayer.debugCheckNotPlacedOver` — and so do
`IuxNavigationRail` and `IuxAdaptiveNavigation`.

A transient message is pinned to the bottom edge of whatever its layer wraps and
reserves no layout space for it. The bar is on that same edge. So a layer
wrapped around the navigation puts every notice on top of the destinations, and
IUX-041 measured what that costs on a 360×800 window: the notice at y 712–760,
the destinations at y 740–786, **all three `hitTestable = 0`** — for a dwell of
at least four seconds that by design cannot be shortened. That is a time limit
on the ability to change section, which is WCAG 2.2 SC 2.2.1, produced by
composition with neither component at fault on its own.

```dart
// Right: the layer is a sibling of the bar, not an ancestor of it.
Scaffold(
  body: IuxTransientLayer(message: notice, onDismissed: clear, child: page),
  bottomNavigationBar: IuxBottomNavigation(...),
)

// Right: the frame owns both, and the layer is inside it.
IuxAdaptiveNavigation(
  child: IuxTransientLayer(message: notice, onDismissed: clear, child: page),
  ...,
)

// Refused: everything the layer wraps is something a notice can cover.
IuxTransientLayer(
  message: notice,
  onDismissed: clear,
  child: IuxAdaptiveNavigation(child: page, ...),
)
```

The `Scaffold` arrangement at the top of this page is safe for a reason worth
saying out loud: `Scaffold.body` and `Scaffold.bottomNavigationBar` are
siblings, so a layer around the body cannot reach the bar. The check knows the
difference and does not fire there.

**A scroll view between the layer and the bar also ends the check.** A notice is
pinned to the bottom of the viewport and scrolled content moves past that edge
rather than standing on it, so a bar found inside a scroll view is not acting as
navigation — it is a specimen, which is exactly what `apps/catalog` renders. See
`docs/components/transient-feedback.md` for the exemption and the one hole it
leaves.

## Behavior

| Gesture | Result |
| --- | --- |
| tap a destination | `onDestinationSelected(index)` |
| tap the current destination | `onDestinationSelected(index)` — see above |
| keyboard <kbd>Enter</kbd> / <kbd>Space</kbd> | activates the focused destination |
| screen reader double-tap | activates it — the tap action is on the node |
| press | a tint behind the content, resolved through `IuxMotionPolicy` |
| focus | a ring whose space is reserved permanently, so nothing moves |

## States

| State | What the bar does |
| --- | --- |
| default | every destination named, one marked current |
| current | indicator behind the glyph, `checked` in semantics, optional filled glyph |
| focused | focus ring, distinct from the indicator, no layout shift |
| pressed | tint behind the content, animated through the motion policy |
| disabled | **not supported** — see *Avoid when* |
| loading | not supported: a bar is not an operation |
| error | not supported: navigation does not fail, the destination does |
| empty | unrepresentable — three destinations is the floor, asserted |

## API

### `IuxBottomNavigation`

| Parameter | Type | Notes |
| --- | --- | --- |
| `label` | `String` | required, non-empty, localised. Names the group for a screen reader; not drawn. |
| `destinations` | `List<IuxNavigationDestination>` | 3–5, distinct names, both asserted. Order is the caller's and never sorted. |
| `selectedIndex` | `int` | required, in range, asserted. Owned by the parent. |
| `onDestinationSelected` | `ValueChanged<int>` | required. Fires for the current destination too. |

### `IuxNavigationDestination`

| Parameter | Type | Notes |
| --- | --- | --- |
| `label` | `String` | required, non-empty, localised. Drawn and announced. Keep it short. |
| `icon` | `IconData` | required. Decorative — the name says what this is. |
| `selectedIcon` | `IconData?` | a filled variant of the same glyph. Reinforcement only. |
| `badge` | `IuxBadge?` | after the name in reading order, merged into the announcement. |

### `IuxBottomNavigationTokens` / `IuxBottomNavigationResolver`

The resolved appearance, and the one place it is decided. There is no
`IuxNavigationTheme`: every decision the bar makes is already carried by the
semantic palette, the geometry and the typography an application configures
once, and a dedicated extension would only have created a place to break the
contrast guarantee and the target floor.

## Accessibility

**What the component guarantees.**

- Every destination has a visible and accessible name — the same string,
  deliberately: a navigation bar has no context in which they could legitimately
  differ.
- The current destination is in the semantics, not only in the paint, and it is
  announced at every destination rather than only at the current one.
- One stop per destination. The glyph is removed from the semantic tree and the
  badge is merged in, so a five-destination bar is five stops, not fifteen.
- The tap action is registered on the semantics node, so a screen reader's
  double-tap works.
- Targets at or above `IuxAccessibility.minimumTouchTarget` in both dimensions,
  at every density and both target preferences, with no dead space between them.
- Keyboard reachable and activatable; the focus ring is distinct from the
  indicator and its space is reserved permanently.
- Names wrap and are never truncated, at any text scale, and the arrangement
  reflows before a name would have to break mid-word.
- Every animation goes through `IuxMotionPolicy`. Under no motion the indicator
  still appears; only the fade is removed.
- RTL: the arrangement is direction-aware, so the first destination is at the
  start of the reading direction.

**What the application owns.**

- The wording of `label` and every destination name, already localised.
- The badge's count string and its sentence — IUX will not join a number to a
  noun.
- Whether choosing a destination is allowed, and what happens when it is.
- Announcing the arrival, if the new screen needs it. The bar announces nothing:
  the focus and content change is the user's own doing and speaks for itself.

**What needs a device.** TalkBack's exact phrasing for a checked member of a
radio group, Voice Access target labelling, and behaviour with a screen
magnifier at the stacked breakpoint. Widget tests approximate these and no more.

## Themes

Everything resolves from `IuxSemanticColors`, `IuxGeometryTheme` and
`IuxTypographyTheme`: the bar's surface is `surface.raised`, its leading edge is
`border.standard`, the indicator is `surface.selected` outlined in
`border.selected`, the current destination's glyph and name are
`content.primary` and the others `content.secondary`. The suite renders the bar
in light, dark, high-contrast light and high-contrast dark.

No elevation. Hierarchy rests on surface contrast and a 3:1 edge, both of which
survive a reduced visual stimulation preference — where the theme resolves
elevation to zero anyway.

The current name and the others share a font size and a weight, and differ only
in colour. A heavier current label would change the measured width of the text,
so choosing a destination would move the four beside it.

## Anti-patterns

```dart
// Navigating from the component.
onDestinationSelected: (int i) => Navigator.pushNamed(context, routes[i]),

// A second source of truth. The bar renders selectedIndex; it does not keep one.
onDestinationSelected: (int i) => setState(() => _barIndex = i),   // and never used

// A bare number on a destination. IuxBadge asserts.
badge: IuxBadge.count(count: '3', label: '3'),

// An action among the places.
IuxNavigationDestination(label: l10n.newMessage, icon: Icons.add),

// A section that is sometimes unavailable, kept in the bar and ignored.
onDestinationSelected: (int i) { if (i == 2 && !signedIn) return; ... }
```

The last one is the interesting failure: the destination stays visible, keeps
its target, announces itself as available, and does nothing. Remove it from
`destinations` instead — the bar accepts three.

## Migration

Additive. Nothing in IUX 0.1 renders navigation, so there is nothing to migrate
from. Coming from Material's `NavigationBar`:

| `NavigationBar` | `IuxBottomNavigation` |
| --- | --- |
| `labelBehavior` | gone — names are always shown |
| `destinations` (widgets) | `destinations` (values) |
| `NavigationDestination.icon` (widget) | `icon` (`IconData`) |
| `NavigationDestination.label` | `label`, and it is the accessible name too |
| a `Badge` widget in `icon` | `badge`, after the name, never over the glyph |
| `height`, `elevation`, `backgroundColor`, `indicatorColor` | resolved from the theme |
| unlimited destinations | 3–5, asserted |
| (no group name) | `label`, required |

## Limits

- **Height is intrinsic and can be large.** Five destinations at 200% text on a
  320-pixel screen take 360 px. Three take 216. If an application expects
  enlarged text, three destinations is the choice that survives it.
- **Above roughly 250% text with five destinations on a short screen, the bar
  cannot fit.** It then clamps to the space available and scrolls. That is a
  degradation, not a feature: a destination the user has to scroll to is a
  destination they may not find — but a destination that is not rendered is one
  they certainly will not.
- **Long names make a tall bar.** Nothing is truncated, so `Notifications`
  across five columns costs 40 px more than `Alerts` at 100% text. The bar
  cannot shorten a word and will not hide it.
- **The arrangement switches on text scale, not on available width.** A very
  narrow screen at 100% text keeps the row arrangement and lets names wrap. IUX
  supports 320 px as the floor; below it the target guarantee is arithmetically
  impossible for five destinations (5 × 48 = 240) and nothing here rescues it.
- **No disabled destination, no loading state, no error state.** See *States*.
- **`IntrinsicHeight` in the row arrangement.** One extra layout pass over at
  most five children, paid once per bar. It is what makes every column's target
  span the full height; a fixed height would clip enlarged names instead.
- **The bar does not restore per-section scroll or history.** That is the
  application's, and it is why the bar reports rather than navigates.

## Deviations from the Component Standard

Two, both deliberate, both with precedent in the library.

### A bare `Semantics`, not `IuxSemantics.selection`

§2 says a component uses the `IuxSemantics` helpers rather than a bare
`Semantics`. A destination uses `MergeSemantics` plus an explicit node.

`IuxSemantics.selection` sets `excludeSemantics: true`, which is right for a
control whose visible content only repeats the name it was given and wrong here:
it would delete the badge from the interface of every screen-reader user, so
"Messages, 3 unread messages" would be announced as "Messages" and the number
would exist for sighted users only. `IuxListItem` recorded the same deviation
for the same reason.

The properties set are exactly the ones `IuxSemantics.selection` gives
`IuxSelectionRole.radio` — `checked`, `inMutuallyExclusiveGroup`, `enabled`, and
the tap action on the node itself. The vocabulary is not invented; only the
exclusion is dropped. The bar's own container *does* go through the runtime, as
`IuxSemantics.radioGroup`.

### No `kIuxMinimumTargetSpacing` between destinations

§5 asks for spacing between adjacent targets. The destinations touch. See
*Targets* above: the size requirement is met outright, and a gap would be a dead
strip in the thumb zone. `IuxListItem` makes the same call for adjacent rows.

`IuxTapTarget` is likewise not used, for the same reason `IuxListItem` does not
use it: it declares `button: true` on its own semantics node, which would
contradict the destination's role. The floor value is read from
`IuxAccessibility.minimumTouchTarget` — the same source `IuxTapTarget` reads —
and applied with a `ConstrainedBox` outside the focus ring.

## Evidence

| Rule | Level | Basis |
| --- | --- | --- |
| Selection state is announced, not only painted | **Standard** | WCAG 2.2 SC 4.1.2 (Name, Role, Value); Android accessibility guidance |
| Colour is never the only carrier of the current destination | **Standard** | WCAG 2.2 SC 1.4.1 |
| Targets ≥ 48 dp | **Standard** | Android accessibility guidance; WCAG 2.2 SC 2.5.8 (24 px minimum, met with margin) |
| Names never truncated, layout works at 200% | **Standard** | WCAG 2.2 SC 1.4.4, 1.4.10 |
| Focus visible and non-displacing | **Standard** | WCAG 2.2 SC 2.4.7, 2.4.11 |
| Motion routed through a reduced-motion policy | **Standard** | WCAG 2.2 SC 2.3.3 |
| Three to five destinations | **Strong guidance** | Material Design navigation bar guidance; the ≥6 case fails the target floor arithmetically at 320 px |
| Labels always visible | **Strong guidance** | Material Design (`alwaysShow` is the Material 3 default); Nielsen Norman Group on icon ambiguity — *to_verify*, the specific NN/g article has not been re-read for this mission |
| Reflow to a stacked arrangement above ~130% text | **Hypothesis** | The threshold is `IuxAccessibility.prefersStackedLayout`, itself documented as a heuristic. The measured alternative (mid-word breaks in a 56 px column) is a fact; that 130% is the right crossover is not. Needs user validation. |
| Re-selecting the current destination is reported | **Context dependent** | The "return to top" idiom is common on Android and iOS but undiscoverable. IUX reports the gesture and takes no position on what it means. |
| Indicator carries an outline as well as a fill | **Context dependent** | Follows `IuxSurface`'s own rationale that surface contrast alone is intentionally gentle. Not separately measured. |
| The bar scrolls rather than clipping above ~250% text | **Hypothesis** | Chosen because unreachable is worse than inconvenient. No user evidence either way. |

## Sources

- WCAG 2.2 — SC 1.4.1, 1.4.4, 1.4.10, 1.4.11, 2.1.1, 2.3.3, 2.4.7, 2.4.11,
  2.5.8, 4.1.2.
- Android accessibility guidance — touch target size, `AccessibilityNodeInfo`
  checkable state, radio group position announcement.
- Material Design 3 — navigation bar: three to five destinations, labels shown
  by default.
- `docs/components/component-standard.md` §1–§5, §7, §9, §11, §12.
- `docs/components/list-items.md` — the precedent for both deviations recorded
  above.
- `docs/components/badges-and-chips.md` — why a badge announces its subject.
- `PROJECT_PROMPT.md` §16, §19–23, §31, §35–36.

## One role, and why it is `radioGroup` rather than `navigation`

Verified against the real semantics tree, not assumed. A destination node ends
up carrying `label`, `checked` (true or false — never absent),
`inMutuallyExclusiveGroup`, and the `tap` and `focus` actions. Its parent
carries `SemanticsRole.radioGroup` and the bar's own `label`.

Two things follow from that measurement.

The first is that there is **no `SemanticsRole.radio`** in Flutter — the enum
offers `radioGroup` and `menuItemRadio`, and nothing for a plain radio child.
So `checked` plus `inMutuallyExclusiveGroup` is not a stylistic preference
here, it is the only available way to say what a destination is.

The second is a genuine trade-off. `SemanticsRole.navigation` exists and is the
landmark role a navigation bar would otherwise claim, letting a screen-reader
user jump to it by landmark. A node holds **one** role, so the bar cannot have
both. It keeps `radioGroup`, because the landmark helps a user find the bar
they were already going to reach with two swipes, while the group role is what
makes "where am I" audible at all. The cost is real and is recorded here
rather than left to be discovered.

## Correction: why `checked` and not `selected`

This page originally argued for `checked` on the grounds that `selected` is
announced only when true. **That premise no longer holds**, and it was caught
by the tabs mission rather than by this one. Measured on Flutter 3.44:

| | `selected` | `checked` |
| --- | --- | --- |
| `true` | `Tristate.isTrue` | `CheckedState.isTrue` |
| `false` | `Tristate.isFalse` | `CheckedState.isFalse` |
| unset | `Tristate.none` | `CheckedState.none` |

The flags are tri-state, so `selected: false` is explicitly present, not
absent. Framework-side the two are indistinguishable, and the original
argument was measuring a Flutter that has since changed.

What survives is narrower and is now stated as such. `checked` combined with
`inMutuallyExclusiveGroup` is the pairing that says *one of these, and only
one* — a claim `selected` does not make, since a set of selected items may
have any number selected. That is a semantic distinction, not an announcement
one. **Whether a given screen reader speaks the unselected state is a device
question that has not been tested on hardware**, and no claim about it is made
here.

The choice stands. The reason it stood on has been replaced with one that is
true.
