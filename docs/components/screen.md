# IuxScreen

## Purpose

Own the two halves of a screen — the app bar and the page — so that the inset is
spent once, the height is owned by somebody, and neither half can overflow the
other.

```dart
Scaffold(
  body: IuxScreen(
    appBar: IuxAppBar(
      title: l10n.orders,
      leading: IuxAppBarLeading.back(
        label: l10n.backToHome,
        onActivate: controller.goBack,
      ),
    ),
    page: IuxPage(child: content),
  ),
)
```

**Use it** wherever a screen has a name and content. It is two parameters wide
on purpose: there is nothing to configure, and therefore no reason to write the
`Column` by hand.

**Do not use it** for a screen with no name worth showing — that is an `IuxPage`
on its own — nor as a `Scaffold` replacement. It owns the top chrome and the
content and nothing else. Navigation goes around it, and so do the two overlay
layers:

```dart
IuxModalLayer(                          // a dialog covers navigation
  dialog: state.dialog,
  child: IuxAdaptiveNavigation(
    label: l10n.mainNavigation,
    selectedIndex: section.index,
    destinations: destinations,
    onDestinationSelected: controller.goTo,
    child: IuxTransientLayer(           // a notice must not
      message: state.notice,
      onDismissed: controller.clearNotice,
      child: IuxScreen(
        appBar: IuxAppBar(title: l10n.orders),
        page: IuxPage(child: body),
      ),
    ),
  ),
)
```

That order is not this component's invention; it is `IuxTransientLayer`'s, and
it is asserted rather than described. `IuxScreen` is simply the innermost of the
four, which is what makes it a frame for content rather than a frame for the
application.

## Why it exists

`IuxAppBar` beside an `IuxPage` is the most-repeated composition any application
writes. Written as siblings in a `Column` it carries three separate traps, all
three measured by the pilot application before this component existed
(`IUX-APPBAR-PAGE-001`). Every application would have written it identically and
got at least one of them wrong.

### 1. The top inset was spent twice, and nothing asserted

The bar consumes the top inset inside its own `SafeArea`, which removes it *for
the bar's subtree only*. A sibling page still sees the full `MediaQuery` padding
and insets the content again, below the bar, from a cutout that exists once.

Measured on 320x640 with a 40-pixel top inset, content top:

| | no inset | 40 px inset | difference |
| --- | --- | --- | --- |
| `IuxScreen` | 164 | 204 | **40** |
| bar and page as siblings | 164 | 244 | **80** |

`IuxPageInsets` could not express the fix. `none` also gives up the left and
right insets, which a landscape cutout still needs, and there is no `exceptTop`.
The working remedy was `MediaQuery.removePadding(removeTop: true)` around the
page — which is exactly what this component does, once, where no caller has to
know about it. The page can then be left on its default `handled`, and the side
and bottom insets are still taken.

### 2. Nothing owned the total height

The bar has no fixed height, by design: the title is never truncated, so the bar
grows instead. At a large text scale that puts it in competition with the
content and with the navigation below, and a `Column` settles the competition by
overflowing — laying the page out at zero height and painting the bar outside
the window.

`IuxBottomNavigation` documents its own degradation and takes its share first;
nothing then defended the content. Now something does. See *How the height is
settled*.

### 3. The standard fix was structurally unavailable

Fill-viewport-or-scroll — a `SingleChildScrollView` around a `ConstrainedBox`
around an `IntrinsicHeight`, so the bar stays pinned while there is room and
scrolls away when there is not — is the standard Flutter answer to a screen that
sometimes fits. It threw:

```text
LayoutBuilder does not support returning intrinsic dimensions.
```

`IuxAppBar` decided its arrangement in a `LayoutBuilder`, and a `LayoutBuilder`
has to build before it knows anything, so it can never answer an intrinsic
query. **No tree containing an IUX app bar could take part in `IntrinsicHeight`,
`IntrinsicWidth`, an intrinsic `Table` column or
`SliverFillRemaining(hasScrollBody: false)`.** The pilot's only option was to
scroll the whole screen, bar included, and lose its pinned title at every text
scale.

The `LayoutBuilder` is gone — the bar now decides its arrangement in a render
object, which reports intrinsic dimensions — and all four of those arrangements
are tested here.

**This component does not use one, which is the more useful half.** It measures
the chrome and hands the page whatever is left, so it never asks the caller's
content how tall it would like to be. Content that cannot answer that question
is common — a nested `ListView`, an `IuxListItem`, anything else built on a
`LayoutBuilder` — and all of it lays out here without complaint. The intrinsic
support is what makes an `IuxScreen` composable *inside* something else that
measures; it is not what makes it work.

## How the height is settled

Decided, in this order, rather than emergent:

1. **The page keeps at least half the box.** It is why the screen exists, and it
   scrolls, so what does not fit is still reachable.
2. **The bar takes the height its title needs**, up to the other half. Below
   that it is untouched, which is every ordinary screen.
3. **Past that, the bar's strip scrolls.** Nothing is clipped and nothing is
   abbreviated: the whole title is rendered, at its full height, inside a box too
   short for it.

Half is a rule about what a screen *is* rather than a tuned number: a screen is
content with chrome around it, so the moment the chrome wants more than the
content it has stopped being chrome. There is no parameter for it. A call site
that could raise it would be deciding, on one screen, that the name of the
screen matters more than the screen.

**Scrolling the strip is the degradation `IuxBottomNavigation` already chose**
for the other end of the screen (IUX-024): a destination the user has to scroll
to is a destination they may not find, and one that is not rendered is one they
certainly will not. The same reasoning holds for a title, and using the same
answer at both ends is worth more than a second answer that is marginally
better at one of them.

### The bottom chrome is not in that list

It is not in this widget either. `IuxAdaptiveNavigation` bounds the navigation
bar by the window and hands the content what is left; `IuxScreen` then fits
inside that. Two owners, one boundary between them, and neither able to overflow
the other.

That is a decision and not a dodge — but it is worth stating what it costs. The
navigation still takes its natural height *first*, so on a 320x640 window at
300% text it holds 368 pixels, 57% of the window, and this component's half of
what is left is 136. Nothing overflows and everything is reachable, but a screen
whose navigation takes more than half of it is the same shape of defect this
component fixes one level up. Fixing it belongs to whoever owns
`lib/src/components/navigation/`.

## Measured

A 320x640 window, a back affordance, one action, a twenty-nine character title,
three destinations under an `IuxAdaptiveNavigation`. *Wanted* is the height the
bar asks for when nothing bounds it.

| text | wanted | bar | page | nav | the same tree as siblings |
| --- | --- | --- | --- | --- | --- |
| 100% | 148 | 148 | 400 | 92 | 148 / 400 |
| 150% | 282 | 230 | 230 | 180 | 282 / 178 |
| 200% | 360 | 212 | 212 | 216 | 360 / 64 |
| 250% | 510 | 178 | 178 | 284 | **overflowed by 154**, page 0 |
| 300% | 772 | 136 | 136 | 368 | **overflowed by 500**, page 0 |

The same on 360x800:

| text | wanted | bar | page | nav | the same tree as siblings |
| --- | --- | --- | --- | --- | --- |
| 100% | 120 | 120 | 608 | 72 | 120 / 608 |
| 150% | 218 | 218 | 402 | 180 | 218 / 402 |
| 200% | 360 | 292 | 292 | 216 | 360 / 224 |
| 250% | 510 | 274 | 274 | 252 | 510 / 38 |
| 300% | 772 | 216 | 216 | 368 | **overflowed by 340**, page 0 |

With a simulated display inset of 40 at the top and 24 at the bottom, 320x640,
nothing overflows at any of the five scales and the bar is never over half:
188/336, 218/218, 200/200, 166/166, 124/124.

The page never loses room to the share rule; it only ever gains it. The bar
gives up height only where the page would otherwise have had less than half —
which on 320x640 starts at 150% and on 360x800 at 200%.

## API

### `IuxScreen`

| Parameter | Required | Note |
| --- | --- | --- |
| `appBar` | yes | typed `IuxAppBar`, not `Widget` |
| `page` | yes | typed `IuxPage`, not `Widget` |

Both slots are typed for the reason `IuxAppBar.actions` is typed
`List<IuxIconButton>`: this component makes promises about what is in them — that
the bar spends the top inset and scrolls rather than overflows, that the page
consumes the remaining insets and scrolls its content — and it can only keep
those promises about components that behave that way. A `Widget` slot would turn
both promises back into documentation.

There is no `insets`, no `padding`, no height, no share and no scroll parameter
here. Everything configurable already belongs to one of the two components in
the slots, and re-exposing it would give a caller two places to set the same
thing.

## States

The component owns no state. Every state belongs to the bar or to the page:
focus and pressed to the bar's controls, loading and error to whatever the page
holds. There is no empty state — a screen with an empty page is an
`IuxEmptyState` inside the page, which is where it can explain itself.

## Motion

None. Nothing here animates, so there is nothing for a reduced-motion preference
to take away. The allocation changes when the text scale or the window changes,
which is not an interactive transition and not something an animation would
explain.

## Accessibility

- **The inset is spent once**, so content does not start a status bar's height
  below where it should. Verified with a simulated inset on both windows.
- **Nothing overflows at any text scale**, on either window, with or without a
  display inset — measured at 100, 150, 200, 250 and 300%. An overflow is not
  cosmetic: the page under it was being laid out at zero height, so at 300% the
  screen's entire content was unreachable.
- **The content is never less than half the screen.** The rule exists for the
  user who enlarged their text, which is exactly when the chrome grows.
- **The title is never truncated**, at any scale or window. Where the strip is
  too short the title is still laid out in full and reached by scrolling;
  screen-reader users are unaffected, because the whole title is in the
  semantics tree and focusing it scrolls it into view.
- **Reading order is the arrangement**: the way out, the heading, then the
  content. Verified by walking the semantics tree.
- **Right-to-left** puts the way out on the trailing edge, from the bar's own
  layout.
- **Two scrollables, and the one under the finger is the one that moves.** The
  bar's viewport is never the primary scrollable, so a page drag cannot be
  answered by the chrome. Measured: dragging the content leaves the bar exactly
  where it was.

**Verified in widget tests.** Still requires a device: how TalkBack announces a
heading that has to be scrolled into view, and whether a partially visible title
reads as an affordance to a sighted user.

## Anti-patterns

```dart
// Wrong: siblings. The inset is spent twice, nobody owns the height, and at
// 250% text under a navigation bar the frame overflows by 154 pixels.
Column(children: <Widget>[IuxAppBar(...), Expanded(child: IuxPage(child: body))])

// Right.
IuxScreen(appBar: IuxAppBar(...), page: IuxPage(child: body))
```

```dart
// Wrong: the remedy for the doubled inset that a caller had to discover. It
// also gives up the left and right insets, which a landscape cutout needs.
IuxScreen(appBar: bar, page: IuxPage(insets: IuxPageInsets.none, child: body))

// Right: the default. The top inset has already been removed for this page.
IuxScreen(appBar: bar, page: IuxPage(child: body))
```

```dart
// Wrong: navigation inside the screen. The page then holds the bar that is
// supposed to hold the page, and the navigation is laid out inside the half
// this component reserved for content.
IuxScreen(appBar: bar, page: IuxPage(child: IuxAdaptiveNavigation(...)))

// Right: navigation around it.
IuxAdaptiveNavigation(..., child: IuxScreen(appBar: bar, page: page))
```

## Limits

- **It does not own the navigation.** Two owners, and the boundary between them
  is stated above along with what it costs at 300% on a small window.
- **The share is not configurable and not derived from anything.** Half is a
  judgement about what a screen is; a project that wanted a different split has
  no way to ask for one, which is deliberate and may prove wrong.
- **A capped strip scrolls with no visible affordance.** No scrollbar is drawn,
  so part of a long title can be off the strip with nothing saying so. The same
  cost `IuxBottomNavigation` accepted, for the same reason.
- **The bar's viewport consumes a vertical drag that lands on the bar**, even
  when it has nothing to scroll.
- **It does not make the sibling `Column` unwritable.** No component can inspect
  its sibling, so the old arrangement still behaves as it always did. Two tests
  pin that behaviour — one for the doubled inset, one for the overflow — so the
  defect cannot come back silently if this component is removed.
- **No collapsing or scroll-under bar.** Both need slivers; see
  `docs/components/app-bar.md`.

## Evidence level

**Standard** for the accessibility guarantees: no overflow and no truncation at
any text scale to 300%, the inset spent once, reading order, and the content
never being laid out at zero height.

**Context dependent** for the composition itself — a project could reasonably
own its own frame, as the pilot had to.

**Hypothesis** for the half share, and for scrolling the strip as the right
degradation. Neither has been validated with users; the second is at least
consistent with the answer IUX-024 already gave at the other end of the screen.

## Sources

- WCAG 2.2 — SC 1.4.4 Resize Text, SC 1.4.10 Reflow, SC 1.3.2 Meaningful
  Sequence, SC 2.4.6 Headings and Labels.
- `docs/components/app-bar.md` — the bar, its title rule, and its degradation.
- `docs/layout/overview.md` — `IuxPage`, `IuxPageInsets`, scrolling by default.
- `docs/components/bottom-navigation.md` — the scroll-rather-than-clip
  degradation this component reuses at the other end of the screen.
- `docs/components/component-standard.md`.
- `IUX-APPBAR-PAGE-001` in `docs/evidence/`.
