# IuxTabs

## Purpose

Give one section of an application two to five views of the same subject, say
which one is on screen, and report which one the user asked for next.

```dart
Column(
  children: <Widget>[
    IuxTabs(
      label: l10n.messageFilter,
      tabs: <String>[l10n.all, l10n.unread, l10n.archived],
      selectedIndex: filter.index,
      onTabSelected: controller.showFilter,
    ),
    Expanded(child: panelFor(filter)),
  ],
)
```

## Use when

- One section holds two to five views of the same subject.
- Exactly one of them is shown at a time.
- Moving between them is not going anywhere: the user stays where they are and
  looks at the same thing differently.

`All / Unread / Archived` over one list of messages is the shape. The strip's
value is that the alternatives are visible without being visited.

## Avoid when

- **These are the top-level sections of the application.** That is
  `IuxBottomNavigation`: permanent, within thumb reach, and unaffected by the
  screen changing under it. A tab strip belongs *inside* one section.
- **The views are steps of a task.** A wizard has an order, a meaning for
  "back", and steps that are not peers. A strip that lets the user jump from
  step two to step four is a strip that produced an invalid result.
- **Two of the choices can be on at once.** Those are filters that combine, so
  they are `IuxFilterChip`s in an `IuxChipGroup` — a set of independent yes/no
  answers, not a set of which exactly one applies.
- **One of the entries is an action.** "Delete all" among the views is a tap
  the user cannot take back by choosing another tab.
- **A view is sometimes unavailable.** There is no disabled tab and there will
  not be one — see *States*. A view with nothing in it is a tab whose panel is
  empty, and an empty panel can say why. A disabled tab cannot.
- **There are six views.** Asserted. See *Two to five*.

### Tabs, chips, or a navigation bar

| | `IuxTabs` | `IuxFilterChip` | `IuxBottomNavigation` |
| --- | --- | --- | --- |
| How many may be on | exactly one | any number, including none | exactly one |
| What it changes | which view of one subject | which items are in one view | which section of the app |
| Where it lives | inside a section | above or beside a list | under the whole app |
| Announced as | `tab` in a `tabBar` | button with a selected state | checked member of a radio group |
| Permanent | no | no | yes |

## It switches nothing

The strip reports which tab the user chose. It holds no index, builds no panel,
and decides nothing about what the panel contains.

```dart
// Wrong: the strip owns which view is shown.
IuxTabs(onTabSelected: (int i) => setState(() => _stripIndex = i))

// Right: the parent owns it and tells the strip what to render.
IuxTabs(selectedIndex: state.filter, onTabSelected: controller.showFilter)
```

This is Component Standard §3, and here it is load-bearing rather than tidy:
only the application knows whether the panel it is about to show needs loading,
whether an edit in the current panel must be saved first, or whether the user
may leave at all. If the parent does not re-render with a new `selectedIndex`
the mark does not move — which is correct, because a strip that marked a tab
whose panel never appeared would be describing a screen that does not exist.

### Choosing the current tab is reported too

`onTabSelected` fires when the user taps the tab they are already on. This is
the same call `IuxBottomNavigation` makes, for the same reason: re-choosing the
view you are already in is a distinguishable gesture, applications answer it in
different ways or not at all, and only the parent knows which. Swallowing it
removes a capability the parent has no other way to get; reporting it costs a
parent that does not want it one rebuild that changes nothing.

`IuxRadioGroup` is the component that swallows an already-chosen option, and the
difference is real: a radio's chosen option cannot be un-chosen, so activating
it is a no-op the parent has no use for.

## A tab is a word

`tabs` is a `List<String>`. There is no `IuxTab` value type, no glyph and no
badge, and each omission is a decision rather than an oversight.

- **No value type.** It would carry exactly one field. A tab has no context in
  which its visible name and its spoken name could legitimately differ, so the
  string is both.
- **No glyph.** An icon beside a word doubles the height of a strip that sits at
  the top of a phone screen — the most contested vertical space there is — and
  says nothing the word does not already say. `IuxBottomNavigation` carries
  glyphs because its destinations are permanent and learned by shape and
  position; a tab is read, every time.
- **No badge.** A caller who wants a count puts it in the name, where their own
  language decides how a number joins a noun. IUX will not join them: the
  framework composes no user-facing string.

The cost of the last one is recorded under *Limits*: adding a glyph or a badge
later means changing `List<String>` to a value type, which is a breaking change.

## Every tab is visible, always

There is no `isScrollable`, and there will not be one.

**A strip that scrolls hides views off the edge of the screen.** Nothing on
screen says "there are two more to the right"; the user finds out by dragging,
and the drag that would reveal them is the same gesture that scrolls the panel
underneath. A view the user does not know exists is a view they do not have.

IUX pays for that differently: a smaller number of tabs, asserted, and a strip
that wraps onto another row when its words no longer fit on one.

### Two to five

- **Two** is the floor. One tab announces a choice, offers no alternative, and
  gives the user a target that changes nothing — show the content without a
  strip. Two is also exactly the case `IuxBottomNavigation` refuses and sends
  here.
- **Five** is the ceiling. Beyond it the strip stops being a choice and becomes
  the screen: five one-word tabs already take four rows on a 320-pixel screen at
  200% text in the measured font (see the table below for why that is an upper
  bound), and a sixth adds another row of chrome above the content the user came
  for. A sixth lateral view is a filter, a menu, or evidence that the section is
  doing two jobs.

Both are asserted, so neither is a guideline somebody can quietly ignore.

## What enlarged text costs, measured

The strip's height is intrinsic and grows; nothing is truncated at any text
size. Measured in the widget-test environment, on a 320-pixel screen at standard
density, with the labels `All`, `Unread`, `Archived`, `Drafts`, `Sent`:

| Text scale | 2 tabs | 3 tabs | 5 tabs |
| --- | --- | --- | --- |
| 100% | 48 px, 1 row | 96 px, 2 rows | 144 px, 3 rows |
| 125% | 49 px, 1 row | 98 px, 2 rows | 147 px, 3 rows |
| 150% | 54 px, 1 row | 108 px, 2 rows | 162 px, 3 rows |
| 200% | 64 px, 1 row | 128 px, 2 rows | **256 px, 4 rows** |
| 300% | 168 px, 2 rows | 312 px, 3 rows | 480 px, 5 rows |

**Read the row counts as an upper bound.** The widget-test font draws every
glyph as a square of the font size, so `Unread` measures 84 px of text at 14 px
type where a proportional font gives roughly half that. The heights per row are
real; the number of rows on a device with a real font is lower. A tab's width is

```text
width = 2 × (focus.width + focus.gap) + 2 × horizontalPadding + text width
      = 32 px + text width          (standard density, standard contrast)
```

so with a proportional font the same five labels come to roughly 350 px at 100%:
two rows on a 320-pixel screen, one row on a 360-pixel one.

The mission's test case — 200% text, 320 px, five tabs — costs four rows of
64 px in the measured (worst-case) font, and every label is whole. The defence is
what the alternatives cost:

- **Scroll**: about 64 px, and the user cannot see that two of the five views
  exist.
- **Truncate**: `Archiv…` and `Archived` are the same word to someone scanning,
  and truncation gets worse exactly when a user has enlarged their text in order
  to read it.
- **Shrink the type**: the setting the user changed stops having an effect,
  which is the failure people report as "large text does nothing in this app".

Keep tab names to one short word. The strip is as wide as its words need.

### Why it wraps rather than reflows

`IuxBottomNavigation` keeps five equal columns and switches to a stacked
arrangement above roughly 130% text. `IuxTabs` has one arrangement and simply
wraps. The difference is what the two components are:

- a destination is a glyph over a name in a fixed column whose *position* users
  memorise, so the columns must stay equal, and an equal column stops holding a
  word long before the user stops enlarging their text;
- a tab is one word, read rather than remembered, so it may take the width of
  its word and let the row end where it ends.

One arrangement also means there is no text-scale threshold to justify, no
second layout to keep in step with the first, and no `stacked` flag in the
tokens.

**Tabs on the same row always have the same height.** A label needs a second
line only when it is wider than the whole strip, and a tab that wide cannot
share a row with anything — so a short tab is never left with a dead band above
and below it.

## How the current tab is announced

Colour is never the signal. The current tab is marked three ways, and only one
of them is a hue.

### 1. In the semantics

Verified against the real semantics tree rather than assumed. Each tab is one
node carrying:

| Property | Value |
| --- | --- |
| `role` | `SemanticsRole.tab` |
| `label` | the caller's string, from the `Text` below it |
| selected | `Tristate.isTrue` on the current tab, `Tristate.isFalse` on every other — never absent |
| `enabled` | true |
| actions | `tap`, `focus` |

and the strip's own node carries `SemanticsRole.tabBar` and the caller's
`label`. Five tabs are five stops, not ten.

**Flutter enforces two of those.** A node whose role is `tab` is rejected at
build time without a selected state ("A tab needs selected states") and without
a tap action ("A tab must have a tap action"), and a node whose role is `tabBar`
is rejected if any of its semantic children is not a tab. Both were confirmed by
probe. That is why the strip contains no divider widget, no scroll view and no
stray text: anything else that announced itself would be a non-tab child.

Getting those checks to run took one non-obvious decision. The gesture detector
inside each tab is built with `excludeFromSemantics: true` rather than being
collapsed with `MergeSemantics`. Measured, a describing gesture detector adds a
second node per tab — **six stops for three tabs** — and pushes the tab role onto
a node whose child is then not a tab. Excluding it keeps one stop *and* leaves
the role on the node the framework checks.

**What is not verified here.** What TalkBack actually says for a tab that is not
selected, and whether Android surfaces "2 of 5" for a tab bar, are device
questions. The framework-side facts above are measured; the announcements are
not, and are listed under *What needs a device*.

### 2. As a shape

A filled, outlined mark sits behind the current tab's label. Its *presence* is
the signal, and presence survives a monochrome screen. The outline is drawn as
well as the fill because surface contrast is deliberately gentle in IUX: a mark
resting on the fill alone would disappear for exactly the user it exists for.

This is deliberately **not** the underline the platform convention draws. An
underline claims adjacency to the panel it belongs to, and this strip may take
more than one row once text is enlarged, at which point only the last row is
adjacent to anything. A two-pixel line is also the hardest possible mark to see
for the low-vision user it matters most to.

The mark's space is reserved whether or not it is drawn. Choosing a tab never
resizes one — in a strip that wraps, a few pixels of extra width is enough to
push the last tab onto a new row under the finger that tapped.

### 3. As content colour

The current label uses `content.primary` and the others `content.secondary`.
Reinforcement, never the signal. Both keep the same size and weight: a heavier
current label would measure wider, so choosing a tab would move the tabs beside
it.

## Keyboard

Measured, not asserted from convention.

| Key | Result |
| --- | --- |
| <kbd>Tab</kbd> | moves to the next tab; after the last one, out of the strip and into whatever follows it |
| <kbd>Shift</kbd>+<kbd>Tab</kbd> | the reverse |
| <kbd>←</kbd> <kbd>→</kbd> | move between tabs on the same row |
| <kbd>↑</kbd> <kbd>↓</kbd> | move between rows when the strip has wrapped |
| <kbd>Enter</kbd> / <kbd>Space</kbd> | activates the focused tab |

Arrow movement is Flutter's own directional traversal, which follows the visual
layout including across wrapped rows. IUX intercepts no arrow key.

### Why there is no roving focus

The WAI-ARIA authoring practice for a tab list is a roving tabindex: one Tab
stop for the whole strip, arrow keys to move inside it. IUX does not do that,
and the reason is specific to Flutter rather than a disagreement with the
practice.

Roving focus in Flutter means marking the non-current tabs `skipTraversal`. But
`FocusTraversalPolicy.inDirection` reads `nearestScope.traversalDescendants`,
which filters `skipTraversal` nodes out as well — so the same change that
removes four tabs from <kbd>Tab</kbd> removes them from the arrow keys, and
arrow navigation would have to be re-implemented by hand inside the component.

That leaves an asymmetric risk. If arrow keys are unavailable to a user — some
switch-access and sip-and-puff configurations emit only <kbd>Tab</kbd> and
<kbd>Enter</kbd> — a roving strip makes four of five views unreachable, while a
Tab-through strip costs four extra key presses. SC 2.1.1 is about functionality
being *operable*; four presses is a cost, unreachable is a failure.

The measured cost of the decision: crossing a five-tab strip takes five
<kbd>Tab</kbd> presses instead of one. Recorded here rather than hidden.

## Targets

Measured on the region that actually responds, at 320 px with five tabs:

| Density | Target preference | 100% | 150% | 200% |
| --- | --- | --- | --- | --- |
| compact | standard | 72 × 48 | 93 × 52 | 114 × 62 |
| standard | standard | 75 × 48 | 96 × 54 | 117 × 64 |
| comfortable | standard | 78 × 48 | 99 × 56 | 120 × 66 |
| compact | comfortable | 72 × 56 | 93 × 56 | 114 × 62 |
| standard | comfortable | 75 × 56 | 96 × 56 | 117 × 64 |
| comfortable | comfortable | 78 × 56 | 99 × 56 | 120 × 66 |

The floor is asserted in the suite at all three densities, at both target
preferences, and at 100%, 150% and 200% text. Width is the smallest measured
tab; the minimum is the runtime's `minimumTouchTarget` and never a number this
component chose.

**The tabs of a row touch.** They partition the row with no
`kIuxMinimumTargetSpacing` between them, and that is the same deliberate reading
of Component Standard §5 that `IuxBottomNavigation` and `IuxListItem` record.
WCAG 2.2 SC 2.5.8 treats spacing as an *alternative* to size for targets below
24 CSS pixels; at 48 and above the size requirement is met outright. A gap here
would be a strip where a tap does nothing at all, and a dead tap teaches the user
the strip is unreliable.

What separates one word from the next is each tab's own horizontal padding,
twice over — about 24 px at standard density.

## Behavior

| Gesture | Result |
| --- | --- |
| tap a tab | `onTabSelected(index)` |
| tap the current tab | `onTabSelected(index)` — see above |
| keyboard <kbd>Enter</kbd> / <kbd>Space</kbd> | activates the focused tab |
| screen reader double-tap | activates it — the tap action is on the node |
| press | a tint over the whole tab, resolved through `IuxMotionPolicy` |
| focus | a ring concentric with the mark, its space reserved permanently |

## States

| State | What the strip does |
| --- | --- |
| default | every tab named, one marked current |
| current | mark behind the label, selected in semantics, `content.primary` |
| focused | focus ring, distinct from the mark, no layout shift |
| pressed | tint over the tab, animated through the motion policy |
| disabled | **not supported** — see *Avoid when* |
| loading | not supported: a strip is not an operation. A panel that is loading says so |
| error | not supported: choosing a view does not fail, the view does |
| empty | unrepresentable — two tabs is the floor, asserted |

## API

### `IuxTabs`

| Parameter | Type | Notes |
| --- | --- | --- |
| `label` | `String` | required, non-empty, localised. Names the set for a screen reader; not drawn. |
| `tabs` | `List<String>` | 2–5, non-empty, distinct — all asserted. Order is the caller's and is never sorted. Drawn and announced. |
| `selectedIndex` | `int` | required, in range, asserted. Owned by the parent. |
| `onTabSelected` | `ValueChanged<int>` | required. Fires for the current tab too. |

### `IuxTabsTokens` / `IuxTabsResolver`

The resolved appearance, and the one place it is decided. There is no
`IuxTabsTheme`: every decision the strip makes is already carried by the semantic
palette, the geometry and the typography an application configures once, and a
dedicated extension would only have created a place to break the contrast
guarantee and the target floor.

## Accessibility

**What the component guarantees.**

- Every tab has a visible and accessible name — the same string, deliberately.
- The current tab is in the semantics, not only in the paint, and every tab says
  whether it is selected rather than only the one that is.
- The role is `tab` inside a `tabBar`, on the nodes Flutter checks, so a strip
  containing anything that is not a tab fails at build time rather than in the
  field.
- One stop per tab. Five tabs are five stops.
- The tap action is on the semantics node, so a screen reader's double-tap works.
- Targets at or above `IuxAccessibility.minimumTouchTarget` in both dimensions,
  at every density and both target preferences, with no dead space between them.
- Keyboard reachable by <kbd>Tab</kbd> alone and activatable by <kbd>Enter</kbd>
  or <kbd>Space</kbd>; <kbd>Tab</kbd> leaves the strip after the last tab.
- Names wrap and are never truncated, at any text scale; the strip takes another
  row rather than a shorter word.
- Nothing scrolls, so no view can be off screen.
- Every animation goes through `IuxMotionPolicy`. Under no motion the mark still
  appears; only the fade is removed.
- RTL: the first tab is at the start of the reading direction, on every row.
- Contrast, asserted in light, dark, high-contrast light and high-contrast dark:
  a resting label on the strip and the current label on its mark both reach
  4.5:1; the mark's outline and the strip's edge both reach 3:1.

**What the application owns.**

- The wording of `label` and every tab name, already localised.
- Any count in a tab name — IUX will not join a number to a noun.
- What the panel contains, whether the choice is allowed, and what happens when
  it is taken.
- Announcing the arrival, if the new panel needs it. The strip announces
  nothing: the content change is the user's own doing.
- Placing the panel after the strip in the tree, so <kbd>Tab</kbd> out of the
  strip lands in it.

**What needs a device.** TalkBack's exact phrasing for a tab, whether it speaks
"not selected" for `Tristate.isFalse`, whether Android surfaces a position
within the tab bar, Voice Access target labelling, and behaviour under a screen
magnifier when the strip has wrapped. Widget tests approximate these and no
more.

## Themes

Everything resolves from `IuxSemanticColors`, `IuxGeometryTheme` and
`IuxTypographyTheme`: the strip's surface is `surface.base`, its trailing edge is
`border.standard`, the mark is `surface.selected` outlined in `border.selected`,
the current label is `content.primary` and the others `content.secondary`. The
suite renders and measures the strip in light, dark, high-contrast light and
high-contrast dark.

The strip uses `surface.base` where `IuxBottomNavigation` uses `surface.raised`.
A bar that never scrolls has to look separate from the content that does; a tab
strip switches a view *inside* a section and has no such claim, and a raised band
here would read as a second piece of chrome competing with the app bar above it.
It is painted rather than left transparent so that the label contrast is a
promise the theme can keep.

No elevation. Hierarchy rests on surface contrast and a 3:1 edge, both of which
survive a reduced visual stimulation preference.

## Anti-patterns

```dart
// A second source of truth. The strip renders selectedIndex; it does not keep one.
onTabSelected: (int i) => setState(() => _stripIndex = i),   // and never used

// Navigating from a lateral choice. A tab is a view, not a destination.
onTabSelected: (int i) => Navigator.pushNamed(context, routes[i]),

// An action among the views.
tabs: <String>[l10n.all, l10n.unread, l10n.deleteAll],

// A count IUX was asked to compose. Put it in the caller's own string instead.
tabs: <String>[l10n.all, '${l10n.unread} ($unread)'],   // fine — it is the caller's
tabs: <String>[l10n.all, l10n.unread + ' ' + unread.toString()],   // not localised

// A view that is sometimes unavailable, kept as a tab and ignored.
onTabSelected: (int i) { if (i == 2 && !signedIn) return; ... }
```

The last one is the interesting failure: the tab stays visible, keeps its target,
announces itself as available, and does nothing. Remove it from `tabs` instead —
the strip accepts two — or show its panel with an explanation.

## Migration

Additive. Nothing in IUX renders a tab strip, so there is nothing to migrate
from. Coming from Material's `TabBar`:

| `TabBar` | `IuxTabs` |
| --- | --- |
| `TabController` | gone — the parent owns `selectedIndex` |
| `isScrollable` | gone — every tab is visible, always |
| `Tab(icon:)` | gone — a tab is a word |
| `Tab(text:)` | an entry in `tabs`, and it is the accessible name too |
| `TabBarView` | the caller's own panel, below the strip |
| `indicatorColor`, `labelStyle`, `indicatorWeight` | resolved from the theme |
| unlimited tabs | 2–5, asserted |
| (no group name) | `label`, required |

`TabBarView`'s swipe-between-panels gesture has no equivalent here and is not
planned: it belongs to the panel, which IUX does not own.

## Limits

- **Height is intrinsic and can be large.** Five tabs on a narrow screen take
  more than one row even at 100% text with a proportional font. Two or three
  tabs is the choice that survives enlarged text on a phone.
- **Long names make a wide tab and therefore more rows.** Nothing is truncated,
  and the strip cannot shorten a word.
- **A word wider than the strip breaks across lines.** It is never clipped and
  never ellipsised, but a very long word at 300% text will break mid-word inside
  its own full-width row. Nothing rescues that except a shorter word.
- **No glyph and no badge**, and adding either later means changing
  `List<String>` to a value type — a breaking change, which is why neither was
  speculated into this version.
- **No disabled tab, no loading state, no error state.** See *States*.
- **No swipe between panels.** The panel is the caller's.
- **Five <kbd>Tab</kbd> presses to cross a five-tab strip.** See *Why there is
  no roving focus*.
- **Below 320 px** IUX makes no target guarantee, and nothing here rescues it.
- **The measured row counts use the widget-test font**, which is wider than any
  real one. They are an upper bound, not a device measurement.

## Deviations from the Component Standard

Two, both deliberate, both with precedent in the library.

### A bare `Semantics`, not an `IuxSemantics` helper

§2 says a component uses the `IuxSemantics` helpers rather than a bare
`Semantics`. Both the strip's container and each tab use a bare one.

The accessibility runtime has no tab vocabulary. What it offers is
`IuxSemantics.radioGroup`, which is a different role — and a node holds exactly
one role, so using it would cost `SemanticsRole.tab` on every child and with it
the framework checks described above. `IuxBottomNavigation` records the same
deviation for a related reason.

**The right fix belongs to the runtime, not here**: `IuxSemantics.tabBar` and
`IuxSemantics.tab`, holding the role, the required selected state and the
required tap action in one place. That is a change to
`lib/src/accessibility/iux_semantics.dart` and is out of this component's scope.

### No `kIuxMinimumTargetSpacing` between tabs

§5 asks for spacing between adjacent targets. The tabs touch. See *Targets*: the
size requirement is met outright, and a gap would be a dead strip.
`IuxListItem` and `IuxBottomNavigation` make the same call.

`IuxTapTarget` is likewise not used, for the same reason `IuxListItem` does not
use it: it declares `button: true` on its own semantics node, which would
contradict the tab role — and a node holds one role. The floor value is read
from `IuxAccessibility.minimumTouchTarget`, the same source `IuxTapTarget`
reads, and applied with a `ConstrainedBox` outside the focus ring.

## Evidence

| Rule | Level | Basis |
| --- | --- | --- |
| Selection state is announced, not only painted | **Standard** | WCAG 2.2 SC 4.1.2 (Name, Role, Value); Android accessibility guidance |
| Colour is never the only carrier of the current tab | **Standard** | WCAG 2.2 SC 1.4.1 |
| Targets ≥ 48 dp | **Standard** | Android accessibility guidance; WCAG 2.2 SC 2.5.8 (24 px minimum, met with margin) |
| Names never truncated; the layout works at 200% | **Standard** | WCAG 2.2 SC 1.4.4, 1.4.10 |
| Every tab reachable and activatable by keyboard | **Standard** | WCAG 2.2 SC 2.1.1 |
| Focus visible and non-displacing | **Standard** | WCAG 2.2 SC 2.4.7, 2.4.11 |
| Motion routed through a reduced-motion policy | **Standard** | WCAG 2.2 SC 2.3.3 |
| Text 4.5:1, mark and edge 3:1 | **Standard** | WCAG 2.2 SC 1.4.3, 1.4.11 — asserted in all four theme profiles |
| A tab set uses the `tab` / `tabBar` roles | **Standard** | Flutter's own role checks, verified by probe; WAI-ARIA `tab` / `tablist` |
| Two to five tabs | **Strong guidance** | Material Design guidance that a fixed tab bar holds a small number; the six-tab case measured at four rows on 320 px at 200% |
| No scrollable tabs | **Strong guidance** | Nielsen Norman Group on hidden navigation and content the user cannot know exists — *to_verify*, the specific article has not been re-read for this mission. The discoverability failure itself is not in dispute; the strength of the citation is. |
| Labels always visible, no icon-only tab | **Strong guidance** | Material Design; the same argument `IuxBottomNavigation` records for icon ambiguity |
| Wrapping rather than reflowing at a threshold | **Context dependent** | Follows from tabs being intrinsically sized, which follows from a tab being one word. Not separately validated with users. |
| No roving focus | **Context dependent** | Departs from the WAI-ARIA authoring practice. The Flutter constraint (`traversalDescendants` filters `skipTraversal`) is verified in the framework source; the judgement that unreachable-without-arrows is worse than four extra key presses is a judgement. |
| A mark rather than an underline | **Context dependent** | Follows `IuxSurface`'s own rationale that surface contrast is intentionally gentle, plus the multi-row adjacency argument. Not separately measured against users. |
| Re-choosing the current tab is reported | **Context dependent** | Consistent with `IuxBottomNavigation`. IUX reports the gesture and takes no position on what it means. |
| Two adjacent labels are told apart by padding alone | **Hypothesis** | About 24 px at standard density. No user validation that this is enough without a divider. |

## Sources

- WCAG 2.2 — SC 1.4.1, 1.4.3, 1.4.4, 1.4.10, 1.4.11, 2.1.1, 2.3.3, 2.4.7,
  2.4.11, 2.5.8, 4.1.2.
- Android accessibility guidance — touch target size, `AccessibilityNodeInfo`
  selected state.
- WAI-ARIA Authoring Practices — Tabs pattern, including the roving tabindex
  this component declines and the reason it declines it.
- Material Design 3 — tabs: fixed versus scrollable, small numbers of tabs.
- Flutter 3.44 `packages/flutter/lib/src/semantics/semantics.dart` —
  `_DebugSemanticsRoleChecks._semanticsTab` and `._semanticsTabBar`, and
  `packages/flutter/lib/src/widgets/focus_manager.dart` —
  `FocusScopeNode.traversalDescendants`.
- `docs/components/component-standard.md` §1–§5, §7, §9, §11, §12.
- `docs/components/bottom-navigation.md` — the sibling component, and the source
  of every "why is this different" answer above.
- `docs/components/badges-and-chips.md` — why a filter chip is not a tab.
- `PROJECT_PROMPT.md` §16, §19–23, §31, §35–36.

## One role, and what that costs

Verified against the real semantics tree, not assumed. A node holds **one**
role, which forces two trades worth recording.

`SemanticsRole.tabPanel` exists and is unused here. IUX ships no panel wrapper,
because the framework performs no check on that role and no platform behaviour
for it has been verified from this environment — a public widget whose only
effect is an unverified role is API nothing uses. Flutter also has no way to
express that a tab *controls* a panel: there is no equivalent of ARIA's
`aria-controls`, so the association a screen-reader user would benefit from
cannot be stated even if the wrapper existed.

`IuxBottomNavigation` faces the mirror image and resolves it the other way: there
is no `SemanticsRole.radio` in Flutter at all, so a destination says what it is
with `checked` plus `inMutuallyExclusiveGroup`, and the bar keeps `radioGroup`
rather than the `navigation` landmark. A tab is luckier — the role it needs
exists — which is why this component can use it and gets the framework's checks
for free.
