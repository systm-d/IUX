# IuxNavigationRail and IuxAdaptiveNavigation

## Purpose

The same three to five permanent places `IuxBottomNavigation` gives an
application, standing up along the start edge — and a component that decides
which of the two a given window can afford.

```dart
Scaffold(
  body: IuxAdaptiveNavigation(
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
    child: IuxPage(child: body),
  ),
)
```

This is one navigation with two arrangements, not two components. Everything
`docs/components/bottom-navigation.md` establishes — every destination named,
no icon-only form, no disabled destination, no action among the places, no
navigation performed by the component, and the announcement of the current
destination — holds here identically and is asserted identically. A rail that
relaxed one of them would make the choice between arrangements a choice about
accessibility.

## Use when

- **`IuxAdaptiveNavigation`**: always, for an application with one set of
  top-level sections. On Android that is every application, because every phone
  rotates.
- **`IuxNavigationRail` directly**: only when you are building the frame
  yourself and have already decided, on a measurement of your own, that this
  window can afford a rail.

## Avoid when

- **You want to force an arrangement.** There is no parameter for it and there
  is not going to be one. A call site that forced the rail would be forcing it
  on the portrait phone too, which is the one window where the measurement
  below says it does not fit. An application that genuinely needs one
  arrangement everywhere can use that component directly and own the
  consequence.
- **As a `Scaffold` replacement.** Put `IuxAdaptiveNavigation` in
  `Scaffold.body`, and do not also fill `Scaffold.bottomNavigationBar` — the
  bar would then exist twice on a phone and once in the wrong place on a
  tablet.
- **Everything `IuxBottomNavigation` lists.** Steps of a task, a view switch
  inside one section, two destinations or six, an action among the places, a
  destination that is sometimes unreachable.

## How the arrangement is chosen

A bottom bar spends **height**. A rail spends **width**. So: spend the axis the
window has more of, and never spend width the content cannot afford.

```text
rail  ⟺  available.width >= available.height
         && available.width > railWidth
         && (available.width - railWidth >= 320  ||  the bar is no longer a strip)
```

Every term is measured rather than assumed.

The middle term asks whether the rail **fits**; the last one asks how much it
**leaves**. They look like the same question and are not, which is what
`IUX-RAIL-OVERFLOW-001` cost: a rail wider than its window leaves a *negative*
remainder, and a negative number fails a positive budget in exactly the way a
small positive one does. The budget therefore answered "narrow" to a rail that
did not fit at all, and the stacked-layout fallback below then chose it anyway.
The audit measured it at 300% on 360x320, where the catalog's own destination
names put the rail at 396 px against a 360 px window: the `Row` overflowed by
36 and the content beside it was laid out at zero. Re-measured as arithmetic
rather than as one font — five short names cost 354 px at 300% in the
widget-test face — **the overflow is exactly the deficit**: a landscape box 36
px narrower than the rail overflows by 36, one 100 px narrower by 100. Both are
pinned, with the window derived from `widthFor`.

The floor is zero and deliberately not more. A window that small at that text
scale has no arrangement leaving a usable page — five short names put the rail
at 354 px there, so the page is six pixels wide, while the bar takes all 320 of
the height and leaves none. Raising the fit term to a touch target would trade
the first for the second, which is not an improvement. This term fixes the case
that is unambiguously wrong — a rail wider than the screen it is drawn on — and
claims nothing about the case where nothing fits.

`railWidth` is `IuxNavigationRail.widthFor`: the widest destination name at the
text size actually in force, not a constant. That is how text scale enters the
decision with the same weight as width — a window that affords a rail at 100%
text can stop affording one at 120%, because the same five names then need a
wider column.

320 is the narrowest content width IUX supports anywhere, the figure
`docs/components/bottom-navigation.md` already commits to. It is a **budget**,
not a breakpoint: it says the rail may take what it needs only while the page
beside it stays inside the range the rest of the library was designed for.

"The bar is no longer a strip" is `IuxAccessibility.prefersStackedLayout`, the
same signal the bar itself uses to reflow. See *The budget is a rule about the
rail only while the bar is cheap*, below.

The decision reads the constraints the widget **receives**, not the display. A
split-screen window, a panel inside a larger layout and a real device are all
measured the same way; a component that asked how big the *screen* was would
put a rail in a 300-pixel pane on a tablet.

### An unbounded box is refused, and what it used to do instead

Both terms of the rule compare something against the width available. An
infinite width answers both of them "yes" for a reason that has nothing to do
with the window, so a box unbounded in either axis is **refused in debug**,
before the rule runs, with an error naming `IuxAdaptiveNavigation` and saying
where the component belongs.

That refusal is new, and it replaces a claim this page made from IUX-025 until
IUX-042 struck it. The private width check returned false for an unbounded
constraint, so the component chose the **bar** — the phone arrangement, on a
window it had not measured — and the layout then failed anyway one level down.
Measured: one `SingleChildScrollView` around `IuxAdaptiveNavigation` produced
**27 exceptions**, the first of them *RenderFlex children have non-zero flex
but incoming height constraints are unbounded*, reported against a `Column`
that lives inside this component and that the caller never wrote. Nothing in
it said navigation, said rail, or said what to do.

So the choice was not between a silent failure and a loud one — it was between
a loud failure in somebody else's words and a loud failure in ours.
`PROJECT_PROMPT.md` §22 asks components to detect invalid configurations and
produce explicit messages, and §52 forbids masking a critical error; making the
documentation match the old behaviour would have satisfied neither. The
assertion was written instead. It is an `assert`, so a release build still
falls through to the bar — the only arrangement that can be chosen without a
width — exactly as before.

Nothing bounded changed. The arrangement chosen was pinned across 25 windows ×
7 text scales (100% to 300%) before and after, and every cell is identical.

### What was measured

All figures below come from `test/components/iux_navigation_rail_test.dart` and
the probes that produced it, at standard density and standard contrast.

**Caveat, stated up front.** Widget tests render in a test font in which every
glyph is roughly one em wide — `Messages` measures 114 px at 14 pt there, which
is materially wider than a proportional face like Roboto would give. So every
**width** below is close to a worst case, and the real crossover sits a little
further towards the rail than these tables suggest. The **heights** are real:
line height does not depend on glyph width. The rule itself never reads these
numbers — it recomputes from the font actually in use.

What one navigation costs, five destinations, short names:

| Window | Text | Bar height | Rail width | Chosen | Content left |
| --- | --- | --- | --- | --- | --- |
| 412 × 915 (phone upright) | 100% | 92 | 130 | bar | 412 × 823 |
| 412 × 915 | 200% | 360 | 242 | bar | 412 × 555 |
| 915 × 412 (phone turned) | 100% | 72 | 130 | **rail** | 785 × 412 |
| 915 × 412 | 200% | 360 | 242 | **rail** | 673 × 412 |
| 320 × 640 (narrowest) | 100% | 112 | 130 | bar | 320 × 528 |
| 600 × 800 (tablet upright) | 100% | 92 | 130 | bar | 600 × 708 |
| 800 × 600 (tablet turned) | 100% | 72 | 130 | **rail** | 670 × 600 |
| 1280 × 800 (desktop) | 100% | 72 | 130 | **rail** | 1150 × 800 |

**What fails on either side.**

On a phone upright the rail is refused twice over: it would cost 31% of the
width and leave 282 px of content, under the 320 floor. The bar there costs 10%
of the height and sits under the thumb.

Turn the same phone and the arithmetic inverts. The bar costs 17% of the height
at 100% text and **87% at 200%** — 360 px of a 412 px window, which is very
nearly the whole screen. The rail costs 14% and 26%. That case is the reason
this component exists.

The rail's own width per text size, five short names:

| Text | Rail width | Destination height | Five destinations |
| --- | --- | --- | --- |
| 100% | 130 | 72 | 360 |
| 130% | 163.5 | 94 | 470 |
| 200% | 242 | 116 | 580 |
| 300% | 354 | 160 | 800 |

At 200% the five need 580 px against the 412 a landscape phone has, so they
scroll. That is the arithmetic behind the five-destination ceiling: a sixth
would be a destination that exists only for users who have not enlarged their
text.

### The Android 600 dp width breakpoint was not adopted

It is strong guidance and it is width-only, which is the term that does not
decide this. At 600 × 800 the bar costs 12% of the height and stays where a
hand is; at 600 × 400 the same bar costs 23% and the aspect term has already
moved to the rail without a breakpoint saying so.

Where the two disagree is a **wide portrait** window — a portrait tablet, an
unfolded foldable held upright — which Android would give a rail and this gives
a bar. At 600 × 800 the bar leaves 600 × 708 of content; a rail would leave
470 × 800. Neither is obviously wrong, and IUX takes the one that keeps
navigation within thumb reach. **That is a hypothesis, not a measurement**: it
needs user validation on a tablet held two-handed, and it is recorded in the
evidence table below as such.

### The budget is a rule about the rail only while the bar is cheap

The first draft of this rule was `width >= height && width - railWidth >= 320`,
and it had an inversion in it. On a landscape window where the budget failed it
fell back to the bar — the arrangement that spends the axis that window has
least of.

Measured, on a 640 × 320 window at 300% text:

| Arrangement | Content left |
| --- | --- |
| rail | 286 × 320 — under the budget, which is why the budget refused it |
| bar | 640 × **0** |

The bar there is not a strip; it is a full-width stacked list taller than the
window, so it takes all of it and the content is laid out at zero height.
Choosing it is choosing the worse of two degradations.

So the budget now applies only while the bar is still the cheap option, which
is exactly while it is still a compact row —
`IuxAccessibility.prefersStackedLayout` is false, below roughly 130% text.
Above that, on a landscape window, the rail wins outright even when it leaves
the content narrower than IUX would like. Narrow content is a degradation; no
content is a defect.

The budget still decides real cases: a 471 × 470 window at 100% text gets the
rail, and the same window at 120% gets the bar. That case is asserted, with the
window derived from `widthFor` rather than written down, so the test measures
the rule and not a font.

## It is as wide as its longest name, and no wider

The rail draws every name, always. Unlike the bar it is not forced into a
column a fifth of the screen wide, so it needs no second arrangement to keep
names whole: it measures them with a `TextPainter` and takes the width the
widest one needs. That is the same technique `IuxAppBar` uses to decide whether
its title still fits beside its controls.

That width is capped at `IuxContentWidth.narrow` — about 35 characters, scaled
with the user's text size rather than a pixel count that silently shrinks when
they enlarge it. Past the cap a name wraps, exactly as it would in the bar. An
uncapped width is an overflow waiting for a call site to write a sentence where
a name belongs.

### A defect this measurement caused, and the fix

The first implementation measured `tokens.labelStyle` alone. The rendered
`Text` merges that style over the ambient `DefaultTextStyle` and so picks up
its **letter spacing**, which the IUX typography theme does not set. A quarter
of a pixel per character is enough: the rail came out 2 px too narrow for
`Messages`, and the widest destination in every rail wrapped to two lines — in
the rail that had just been sized for it.

`widthFor` now measures `DefaultTextStyle.of(context).style.merge(labelStyle)`,
which is precisely what `Text` will do. It follows that the `context` passed to
`widthFor` must be one the rail will be built under; a context outside a
`DefaultTextStyle` the rail sits inside would measure a different font. The
regression is pinned at 100%, 150%, 200% and 300% text.

## How the current destination is announced

Identically to the bar, deliberately: a user who learns the announcement on a
phone hears the same thing on a tablet.

```text
"Main navigation"
"Home, not checked, radio button, 1 of 5"
"Messages, 3 unread messages, checked, radio button, 2 of 5"
```

Each destination is a `checked` member of an `inMutuallyExclusiveGroup`, inside
a `SemanticsRole.radioGroup` carrying the rail's own `label`. `checked` rather
than `selected` because a checked node is announced in **both** states, so the
user hears "not checked" at the destinations they are not in rather than
sweeping the rail for the one that said something.

`docs/components/bottom-navigation.md` records the two findings behind that,
both verified against the real semantics tree: Flutter has **no**
`SemanticsRole.radio`, so `checked` plus `inMutuallyExclusiveGroup` is the only
available way to say what a destination is; and a node holds **one** role, so
`radioGroup` costs the `navigation` landmark. The rail pays the same price for
the same reason, and paying a different one would mean the announcement changed
when the device rotated.

The mark is also a bounded shape — a filled, outlined indicator whose space is
reserved in both states — and optionally a filled variant of the glyph. Colour
is never the signal.

## Layout and insets

The rail runs the full height of what it is given and owns the display insets
on the edge it stands on and at both ends. The boundary between navigation and
content is a `BorderDirectional` on the **end** edge, so it stays between them
when the user reads right to left.

`IuxAdaptiveNavigation` then **removes that inset from the child's
`MediaQuery`** — the start edge in the rail arrangement, the bottom edge in the
bar arrangement. So an `IuxPage` beside the navigation can stay on its default
`IuxPageInsets.handled` and will see exactly the insets still exposed.

An earlier draft told callers to pass `IuxPageInsets.none` instead. That was
worse than the problem it solved: it also gave up the **top** inset, and the
content read out from under the status bar.

Building the row by hand means doing the handoff by hand:

```dart
Row(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: <Widget>[
    IuxNavigationRail(...),
    Expanded(
      child: MediaQuery.removePadding(
        context: context,
        removeLeft: true,          // removeRight in a right-to-left reading
        child: IuxPage(child: body),
      ),
    ),
  ],
)
```

## Where the overlay layers go

`IuxModalLayer` **outside** `IuxAdaptiveNavigation`, `IuxTransientLayer`
**inside** it, in `child`. A dialog is a question about the screen underneath,
so it must cover the navigation; a notice is something the user is allowed to
miss, so it must not.

The other order is refused: this component, `IuxBottomNavigation` and
`IuxAdaptiveNavigation` all run
`IuxTransientLayer.debugCheckNotPlacedOver(context)` on every build and throw
when a transient layer is above them. `docs/components/bottom-navigation.md` has
the measurement — a notice over the bar leaves all three destinations at
`hitTestable = 0` for at least four seconds.

**The rail is checked even though the overlap is intermittent there**, and that
is the reason it is checked. A notice is centred on the reading measure, so on a
wide window at 100% text it clears a rail on the start edge and the mistake
looks like something that cannot happen in this arrangement. At 200% the measure
is wider than the window, and a rail whose destinations have started scrolling
has one on the bottom edge. A defect that appears only after the user enlarges
their text, on the arrangement the developer tested last, is worse than one that
is always there — the same argument this page already makes for keeping the
bar's assertions here rather than in the adaptive component.

A scroll view between the layer and the navigation ends the check: content that
scrolls past the bottom edge is not standing on it, so a rail inside one is a
specimen rather than navigation. `apps/catalog` renders exactly that.

## Behavior

| Gesture | Result |
| --- | --- |
| tap a destination | `onDestinationSelected(index)` |
| tap the current destination | `onDestinationSelected(index)` — the "return to top" gesture, reported rather than interpreted |
| keyboard <kbd>Enter</kbd> / <kbd>Space</kbd> | activates the focused destination |
| screen reader double-tap | activates it — the tap action is on the node |
| press | a tint behind the content, resolved through `IuxMotionPolicy` |
| focus | a ring whose space is reserved permanently, so nothing moves |
| rotate the device | the arrangement changes; the index, the order and the announcement do not |

## States

| State | What the rail does |
| --- | --- |
| default | every destination named, one marked current |
| current | indicator behind the glyph, `checked` in semantics, optional filled glyph |
| focused | focus ring, distinct from the indicator, no layout shift |
| pressed | tint behind the content, animated through the motion policy |
| disabled | **not supported** — a permanent strip advertising a place the user may not go costs more than one fewer destination |
| loading | not supported: navigation is not an operation |
| error | not supported: navigation does not fail, the destination does |
| empty | unrepresentable — three destinations is the floor, asserted |

## API

### `IuxNavigationRail`

| Parameter | Type | Notes |
| --- | --- | --- |
| `label` | `String` | required, non-empty, localised. Names the group for a screen reader; not drawn. |
| `destinations` | `List<IuxNavigationDestination>` | 3–5, distinct names, both asserted. Order is the caller's and never sorted. |
| `selectedIndex` | `int` | required, in range, asserted. Owned by the parent. |
| `onDestinationSelected` | `ValueChanged<int>` | required. Fires for the current destination too. |

`static double widthFor(BuildContext, List<IuxNavigationDestination>)` — what a
rail carrying these destinations would cost at this context. Public because
`IuxAdaptiveNavigation` cannot make its choice without it, and because an
application building its own three-pane frame is making the same choice; the
alternative is that it guesses. Excludes display insets, which on the windows
where a rail is chosen at all are tens of pixels against hundreds to spare.

### `IuxAdaptiveNavigation`

| Parameter | Type | Notes |
| --- | --- | --- |
| `label` | `String` | as above, and the same string in both arrangements. |
| `destinations` | `List<IuxNavigationDestination>` | as above, same order in both. |
| `selectedIndex` | `int` | as above. |
| `onDestinationSelected` | `ValueChanged<int>` | same callback, same index, whichever arrangement is showing. |
| `child` | `Widget` | the screen. Placed beside the rail or above the bar. |

No assertions on its **arguments**: both arrangements refuse exactly the same
configurations, so whichever is built rejects an invalid set — and the failure
does not depend on the window size the developer happened to test on.
Restating the rules here would be a third copy that can disagree with the other
two. That equivalence is itself asserted.

It does assert twice on the tree and the box it is given, which no argument can
express: that no `IuxTransientLayer` is above it, and that the box it was
handed is bounded in both axes.

It owns the frame rather than being dropped into a slot because the two
arrangements put the content in different places; a caller who had to place it
would be making the adaptive decision a second time.

### Reused unchanged

`IuxNavigationDestination`, `IuxBottomNavigationTokens` and
`IuxBottomNavigationResolver` are IUX-024's and are not modified. One resolver
means the target floor, the type and the indicator cannot drift between the two
arrangements — asserted, by comparing the rendered label style in each.

There is no rail theme extension and no rail tokens file, for the reason
IUX-024 gives: every decision either arrangement makes is already carried by
the semantic palette, the geometry and the typography an application configures
once, and a dedicated extension would only create a place to break the contrast
guarantee and the target floor.

## Accessibility

**What the component guarantees.**

- Every destination has a visible and accessible name, the same string.
- The current destination is in the semantics, not only in the paint, and is
  announced at every destination rather than only the current one.
- One stop per destination: the glyph is removed from the semantic tree and the
  badge is merged in.
- The tap action is on the semantics node, so a screen reader's double-tap
  works.
- Targets at or above `IuxAccessibility.minimumTouchTarget` in both dimensions,
  at all three densities and both target preferences, at 150% and 200% text.
- The destinations tile the rail: full width, vertically contiguous, no dead
  strip.
- Keyboard reachable and activatable; the focus ring is distinct from the
  indicator and its space is reserved permanently.
- Names wrap and are never truncated at any text scale — including the widest
  name, which is the one the rail was measured for.
- Every animation goes through `IuxMotionPolicy`. Under no motion the indicator
  still appears; only the fade is removed.
- RTL: the rail stands at the start of the reading direction and its boundary
  line stays between navigation and content.
- Rotating the device changes the arrangement and nothing else — same index,
  same order, same announcement.

**What the application owns.** The wording of `label` and every destination
name, already localised; the badge's count string and its sentence; whether
choosing a destination is allowed and what happens when it is; announcing the
arrival, if the new screen needs it.

**What needs a device.** TalkBack's exact phrasing for a checked member of a
radio group, Voice Access target labelling, whether a rail or a bar is easier
to reach one-handed on a large tablet, and behaviour with a screen magnifier
when the rail scrolls. Widget tests approximate these and no more.

## Themes

Everything resolves through `IuxBottomNavigationResolver`, so the rail's
surface is `surface.raised`, its boundary is `border.standard`, the indicator
is `surface.selected` outlined in `border.selected`, and the current
destination's glyph and name are `content.primary` against `content.secondary`
for the others. The suite renders the rail in light, dark, high-contrast light
and high-contrast dark.

High contrast widens the rail by 4 px, because the focus ring it reserves is
wider. Density moves it by ±1 px and never moves the target floor.

The current name and the others share a font size and weight and differ only in
colour: a heavier current label would change the text's measured width, and the
rail's width is measured from the text.

## Anti-patterns

```dart
// Navigating from the component.
onDestinationSelected: (int i) => Navigator.pushNamed(context, routes[i]),

// A second source of truth. It renders selectedIndex; it does not keep one.
onDestinationSelected: (int i) => setState(() => _railIndex = i),  // and never used

// Picking the arrangement yourself, on a window you have not measured.
if (MediaQuery.sizeOf(context).width > 600) IuxNavigationRail(...)

// Two navigations. The bar exists twice on a phone.
Scaffold(
  body: IuxAdaptiveNavigation(...),
  bottomNavigationBar: IuxBottomNavigation(...),
)

// Double-inset from one cutout: the rail is already standing on it.
IuxAdaptiveNavigation(child: SafeArea(child: body))

// A different set of destinations per arrangement.
IuxAdaptiveNavigation(destinations: isWide ? all : all.take(3).toList())

// A frame inside a scroll view. There is no window to measure, so there is no
// arrangement to choose — refused rather than answered with the phone one.
SingleChildScrollView(child: IuxAdaptiveNavigation(...))
```

The last one is the interesting failure: it type-checks, renders, and reshuffles
the application when the user turns the device.

## Limits

- **It needs a bounded box.** `IuxAdaptiveNavigation` still cannot choose an
  arrangement without one — both terms of the rule are comparisons against the
  width it was offered — but the case is now **refused by name**, which this
  page claimed from IUX-025 until IUX-042 struck the claim. See
  [An unbounded box is refused, and what it used to do instead](#an-unbounded-box-is-refused-and-what-it-used-to-do-instead).
- ~~**The rail can be wider than its own window**~~ (`IUX-RAIL-OVERFLOW-001`).
  **Fixed.** The rule weighed *how much was left over* for the content and
  never asked whether the rail itself fitted, so a negative remainder — a rail
  wider than the screen — failed the 320-pixel budget in exactly the way a
  narrow-but-affordable window did, and the fallback for a window too short for
  the bar then chose it anyway. The rule now carries a fit term of its own —
  see [How the arrangement is chosen](#how-the-arrangement-is-chosen).
  Re-measured after the fix, deriving each window from `widthFor` rather than
  writing a pixel count down: at 300% the rail costs 354 px, and a landscape
  box **36 px narrower than that** overflowed by exactly 36 with the fit term
  removed and by nothing with it in place. The audit's original figure — 396 px
  against a 360-wide box — is the same arithmetic read off the catalog's own
  longer destination names.
- **A rail placed by hand is still not refused, and cannot be.** A `Row` lays
  out a non-flexible child against `maxWidth: infinity`, so the rail is never
  told the width of the window it is in; there is nothing for it to compare and
  no refusal it could make. Whatever owns the total has to make that call,
  which is what `IuxAdaptiveNavigation` is for and why `widthFor` is public.
  What a hand-placed rail does get is Flutter's own report, measured at 100%,
  200% and 300% text: **the `Row` overflows by exactly the number of pixels the
  rail was short by**, and the page beside it is laid out at zero width. Loud,
  but in the framework's words — it names a `RenderFlex`, not a rail. In a
  *bounded* box narrower than it asked for there is no overflow and no report
  at all: the rail takes the width it is given, the names wrap, and every
  destination still renders. Measured at 300%, asking 354 and given 200, 100
  and 48 px: no exception in any of the three, all five names present.
- **Widths here are measured in a test font that is wider than Roboto.** Real
  rails are narrower, so the arrangement flips to the rail slightly earlier on
  a device than the tables above suggest. Nothing in the rule depends on the
  absolute number — it is recomputed from the real font at runtime — but the
  documented pixel counts are an upper bound, not a prediction.
- **On a 412-pixel-tall window the rail starts scrolling at about 125% text**
  with five destinations: they need 415 px there against 412, against 404 at
  120%. A destination the user must scroll to is one they may not find;
  a destination that is not rendered is one they certainly will not — but this
  is a degradation, not a feature, and three destinations is the choice that
  survives enlarged text on a small landscape window.
- **On a 320 × 640 phone at 300% text neither arrangement fits.** The bar takes
  the window and the content is laid out at zero height. The rail cannot rescue
  it: at that text size it would need 354 px of a 320 px screen. This is
  IUX-024's documented degradation and it is not fixed here.
- **The wide-portrait call is a hypothesis.** See above.
- **`widthFor` ignores badges.** A badge sits under the name and is narrower
  than any realistic name, so it has never driven the width; a pathological
  count string would wrap inside the column rather than overflow. Not
  separately guaranteed.
- **`widthFor` excludes display insets**, so the adaptive budget is optimistic
  by the width of a cutout — tens of pixels against hundreds to spare on the
  windows where a rail is chosen.
- **No disabled destination, no loading state, no error state.** See *States*.
- **The rail does not restore per-section scroll or history.** That is the
  application's, and it is why it reports rather than navigates.

## Deviations from the Component Standard

### A bare `Semantics`, not `IuxSemantics.selection`

The same deviation `IuxListItem` recorded first and `IuxBottomNavigation`
repeated, for the same reason: `IuxSemantics.selection` sets
`excludeSemantics`, which would delete the badge from the interface of every
screen-reader user. The properties set are exactly the ones it gives
`IuxSelectionRole.radio`; only the exclusion is dropped. The rail's own
container does go through the runtime, as `IuxSemantics.radioGroup`.

### No `kIuxMinimumTargetSpacing` between destinations

The destinations tile the rail edge to edge. WCAG 2.2 SC 2.5.8 treats spacing
as an *alternative* to size below 24 px; at 48 and above the size requirement
is met outright, and a gap would be a dead strip where a tap does nothing.
`IuxTapTarget` is likewise not used because it declares `button: true`, which
would contradict the destination's role; the floor is read from
`IuxAccessibility.minimumTouchTarget` — the same source `IuxTapTarget` reads.

### `MediaQuery.removePadding` in `IuxAdaptiveNavigation`

§2 forbids reaching to `MediaQuery` **for a preference**. A display inset is
not a preference, IUX has no runtime wrapper for one, and `IuxPage` and
`IuxBottomNavigation` already read the same data through `SafeArea`.
`removePadding` is the framework's own companion to `SafeArea` and is what
`Scaffold` uses for its navigation slot. Recorded here so it is a decision
rather than an oversight.

## Evidence

| Rule | Level | Basis |
| --- | --- | --- |
| Selection state is announced, not only painted | **Standard** | WCAG 2.2 SC 4.1.2; Android accessibility guidance |
| Colour is never the only carrier of the current destination | **Standard** | WCAG 2.2 SC 1.4.1 |
| Targets ≥ 48 dp | **Standard** | Android accessibility guidance; WCAG 2.2 SC 2.5.8 |
| Names never truncated, layout works at 200% | **Standard** | WCAG 2.2 SC 1.4.4, 1.4.10 |
| Focus visible and non-displacing | **Standard** | WCAG 2.2 SC 2.4.7, 2.4.11 |
| Motion routed through a reduced-motion policy | **Standard** | WCAG 2.2 SC 2.3.3 |
| A rail is the large-window form of a bottom bar | **Strong guidance** | Material Design 3 navigation rail; Android adaptive layout guidance |
| Three to five destinations in the rail too | **Strong guidance** | Inherited from IUX-024 so the two arrangements accept the same set; the vertical arithmetic is measured above |
| Rail width is the widest name, capped at the narrow reading measure | **Context dependent** | Follows `IuxContentWidth`'s own reasoning. The 35-character cap is a typographic default, not a finding. |
| The arrangement is chosen on aspect plus a measured content budget | **Context dependent** | The measurements above are facts about this library. That aspect ratio is the right primary term is a design position, not an external standard. |
| The Android 600 dp width breakpoint is not adopted | **Hypothesis** | The disagreement is confined to wide-portrait windows. Needs validation on a tablet held two-handed. |
| The budget yields to the rail once the bar has stacked | **Context dependent** | The zero-height failure it replaces is measured and reproduced in the suite; that ~130% is the right crossover is inherited from `prefersStackedLayout`, itself documented as a heuristic. |
| An unbounded box is refused rather than answered | **Context dependent** | The alternative was measured — 27 exceptions naming a `Column` the caller never wrote — and `PROJECT_PROMPT.md` §22 and §52 decide between them. That an assertion is the right vehicle, rather than a rendered explanation, follows the precedent of `IuxTransientLayer.debugCheckNotPlacedOver`. |
| The rail scrolls rather than clipping above ~250% text | **Hypothesis** | Chosen because unreachable is worse than inconvenient. No user evidence either way. |
| Re-selecting the current destination is reported | **Context dependent** | Inherited unchanged from IUX-024. |

## Sources

- WCAG 2.2 — SC 1.4.1, 1.4.4, 1.4.10, 1.4.11, 2.1.1, 2.3.3, 2.4.7, 2.4.11,
  2.5.8, 4.1.2.
- Android accessibility guidance — touch target size, `AccessibilityNodeInfo`
  checkable state, radio group position announcement.
- Android adaptive layout guidance — window size classes and the 600 dp
  breakpoint, considered and not adopted; see above.
- Material Design 3 — navigation rail and navigation bar.
- `docs/components/bottom-navigation.md` — the shared destination model, the
  announcement, and the `radioGroup`-over-`navigation` trade.
- `docs/components/component-standard.md` §1–§5, §7, §9, §11, §12.
- `docs/components/list-items.md` — the precedent for the semantics deviation.
- `PROJECT_PROMPT.md` §5, §9, §19, §23.

## Migration

Additive. Nothing in IUX 0.1 renders navigation. Coming from Material's
`NavigationRail`:

| `NavigationRail` | `IuxNavigationRail` |
| --- | --- |
| `labelType` (`none` / `selected` / `all`) | gone — names are always shown |
| `extended` | gone — the rail is already as wide as its names need |
| `destinations` (widgets) | `destinations` (values) |
| `leading`, `trailing` | not offered: a rail holds places, not controls |
| `groupAlignment` | gone — destinations start at the top and tile downwards |
| `minWidth`, `minExtendedWidth`, `backgroundColor`, `elevation`, `indicatorColor` | resolved from the theme |
| unlimited destinations | 3–5, asserted |
| (no group name) | `label`, required |
| choosing the arrangement yourself | `IuxAdaptiveNavigation` |
