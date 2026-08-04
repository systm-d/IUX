# IuxAppBar

## Purpose

Say where the user is, give them a way back out, and offer at most three actions
belonging to the screen as a whole.

```dart
Scaffold(
  body: Column(
    children: <Widget>[
      IuxAppBar(
        title: l10n.orders,
        leading: IuxAppBarLeading.back(
          label: l10n.backToHome,
          onActivate: controller.goBack,
        ),
        actions: <IuxIconButton>[
          IuxIconButton(
            icon: Icons.search,
            action: IuxActionDescriptor(
              semantics: IuxActionSemantics(label: l10n.search),
            ),
            onActivate: controller.search,
          ),
        ],
      ),
      Expanded(
        child: IuxPage(
          insets: IuxPageInsets.bottomOnly,   // the bar spent the top inset
          child: content,
        ),
      ),
    ],
  ),
)
```

**Use it** at the top of a screen that has a name worth showing.

**Do not use it** as a toolbar for one section of a page — that is
`IuxSectionHeader` — nor as a place to park controls that did not fit anywhere
else. There is no search field, no tab strip, no selection mode and no overflow
menu here. Each of those is a different component, and putting all of them in
this one is the usual route to an app bar that does four jobs badly.

## The title is never truncated, and everything else gives way to it

An app bar is the narrowest strip in an application, and the title is the only
thing in it that answers "where am I". An ellipsis replaces that answer with a
guess, and it appears exactly when the user can least afford it: enlarged text
makes truncation worse, and enlarged text is what a user chose because they were
struggling to read.

So the title has no line limit, no `TextOverflow.ellipsis`, and the bar has **no
fixed height**. What gives instead, in order:

1. **The shared row.** When the title cannot be read beside the controls, the
   controls keep the row and the title takes the one below it, full width.
2. **The bar's height.** It grows to fit however many lines the title needs.
3. **The controls' row**, if it comes to that: the control strip is an
   `IuxTargetSpacing`, so at very large glyph sizes the controls move to a
   second line rather than overflow.

At 200% text on a 320-pixel screen with a back affordance and two actions — the
case this component was designed around — the title gets **more than 85% of the
screen width** and wraps over as many lines as it needs. The bar ends up far
taller than any conventional app bar. That is the intended outcome, not a
failure: a tall bar with a readable name is better than a 56-pixel one with
"Quarterly deliv…" in it.

### The stacking decision is measured, not assumed

The title keeps the shared row while it either fits there on one line, or still
gets enough width to wrap into readable lines. Both halves are computed at
layout time:

- the one-line width comes from a `TextPainter` using the real title text, the
  real style and the text scale actually in force;
- the readable floor is twelve characters at the title size in force, using the
  same crude half-an-em-per-character conversion `IuxContentWidthResolver` uses.

The control strip is measured by asking `IuxButtonResolver` for the icon
variant's geometry rather than by restating its numbers, so this cannot drift the
next time the button changes.

The consequence is worth stating: a **short** title keeps its row at 200% text
on a wide screen, and a **long** one gives it up on a 320-pixel screen even at
ordinary text size. Three controls on a 320-pixel screen leave roughly 128
pixels, which is not a line of text — it is a column of syllables.

**This deliberately does not use `IuxAccessibility.prefersStackedLayout`.** That
signal is a text-scale threshold, and its own documentation calls it a
heuristic. Branching on it alone would move a two-word title onto its own line
on a tablet where it fitted perfectly well, and would leave a long one squeezed
into forty pixels on a phone at 100%. This component can measure, so it
measures.

## It is not a `PreferredSizeWidget`, and it does not wrap `AppBar`

`IuxPage` composes with `Scaffold` rather than absorbing it. This does the same,
but it composes into the **body**, not into `Scaffold.appBar`. The reason is
mechanical rather than a preference:

`Scaffold.appBar` accepts a `PreferredSizeWidget`. `preferredSize` is a getter
on the widget — it is read before layout, with no access to a `BuildContext`,
the text scale, the available width, or how many lines the title will take. The
`Scaffold` then constrains the bar to at most that height. A height fixed in
advance and a title that must not be truncated cannot both hold, so one of them
had to go, and it was not going to be the title.

Wrapping Material's `AppBar` fails the same way one level down: its
`toolbarHeight` defaults to 56 and its title is laid out inside a
`NavigationToolbar` at exactly that height, so a three-line title is clipped.
Composing with it would have shipped the precise failure this component exists
to prevent.

**What that costs, and what to do about it:**

| Lost with the `Scaffold` slot | What to do instead |
| --- | --- |
| `SystemUiOverlayStyle` / status bar icon brightness | the application sets it, with `AnnotatedRegion` — IUX imposes no system bar colour, as `docs/layout/overview.md` already states |
| the automatic drawer / back button | supply `leading` explicitly, which is the point |
| scroll-under colouring and `extendBodyBehindAppBar` | not modelled; the page scrolls below the bar, not under it |
| `Scaffold.appBarMaxHeight` | there is no fixed height to report |
| `SliverAppBar` collapse behaviour | not modelled; see *Limits* |

## Insets: the bar spends the top one

The bar consumes the top system inset itself, inside its own background, so the
surface paints behind the status bar while the content clears it.

That makes the page below it `IuxPageInsets.bottomOnly`. This is the exact
double-padding hazard `IuxPageInsets` exists for: the bar and the page are
siblings, so the page still sees a non-zero top padding and will add the status
bar height a second time, below the bar, if it is left on `handled`.

`SafeArea` removes what it consumes for its own subtree, so nesting is safe —
an `IuxAppBar` inside something that already handled the top inset adds nothing.
Only the sibling case needs the caller's attention, and no assertion can detect
it. It is the one thing to get right at the call site.

## The way out must be named

`IuxAppBarLeading` is a typed value, not a `Widget` slot, because the up
affordance is the control most often shipped without a name: a bare chevron that
a screen reader announces as "button" and nothing else. Here `label` is a
required constructor argument and may not be empty, so an unnamed one cannot be
written.

Two constructors, because the two mean different things:

| | Glyph | `IuxActionRole` | Use when |
| --- | --- | --- | --- |
| `IuxAppBarLeading.back` | `Icons.arrow_back` | `navigate` | the user came from somewhere and returns there |
| `IuxAppBarLeading.close` | `Icons.close` | `dismiss` | the screen is a layer over what the user was doing, and closing it loses nothing |

Neither is `cancel`. A control that discards what the user typed needs a
confirmation, and confirmation is a pattern's job.

`Icons.arrow_back` declares `matchTextDirection`, so the arrow mirrors itself
under a right-to-left directionality without the component branching on the
locale.

**It does not navigate.** `onActivate` reports that the user asked to leave; the
parent decides what that means. A component that called `Navigator` would be
deciding where the user goes, which it cannot know — see
`docs/components/component-standard.md` §1.

There is no way to disable it. An exit the user can see and cannot take is worse
than no exit drawn at all; a screen with nowhere to go back to passes `null`.

## Actions are `IuxIconButton`, and the type says so

`actions` is typed `List<IuxIconButton>` rather than `List<Widget>`.

`IuxIconButton` takes its accessible name from `IuxActionSemantics.label`, which
the action model already requires to be non-empty, so an unnamed app bar action
is unrepresentable. A `Widget` list would reopen exactly that hole, and a row of
unnamed glyphs at the top of every screen is the failure this component exists
to prevent. Reusing the button also means the bar inherits its focus ring, its
disabled semantics, its repeat policy and its target floor rather than growing a
parallel implementation that will drift from them.

The limit is three, checked on the first build:

```text
An app bar takes at most 3 actions, and this one was given 4. Each action is an
unlabelled glyph taking width from the title, and past three the bar stops being
a place to look and becomes a place to search. Move the rest into a menu or onto
the page.
```

They are actions on the **screen**, not on its content. An action belonging to
one item in a list belongs beside that item, where a screen-reader user meets it
in context.

## API

### `IuxAppBar`

| Parameter | Required | Note |
| --- | --- | --- |
| `title` | yes | the screen's name, already localised; may not be empty |
| `leading` | no | the way out; null for a root screen |
| `actions` | no | at most three; typed as `IuxIconButton` |

### `IuxAppBarLeading.back` / `.close`

| Parameter | Required | Note |
| --- | --- | --- |
| `label` | yes | the accessible name, already localised; may not be empty |
| `onActivate` | yes | reports intent; the parent navigates |
| `hint` | no | what activating does, when `label` alone is ambiguous |

There is no colour, radius, elevation, height, duration or alignment parameter
anywhere here, and there will not be one. An API that accepts a colour has
already lost the contrast guarantee: the theme can no longer be held responsible
for something a call site overrode.

`kIuxAppBarMaximumActions` is exported alongside them, so a caller building a
list of actions can check the limit before hitting the assertion.

## States

| State | Behaviour |
| --- | --- |
| default | the resting bar |
| focused | carried by each control's own focus ring; the bar has no focus of its own |
| pressed | each control's own |
| disabled | an *action* may be disabled and is announced as such; the bar and the way out may not be |
| loading | an action may carry `IuxActionOperation.inProgress`; the bar has no loading state |
| error | not modelled — a bar does not report an outcome |
| empty | not modelled — a bar with a title is never empty |

The bar owns no state of its own. Everything above belongs to the controls it
holds, which is what keeps it from ever deciding that something succeeded.

## Motion

None, and deliberately.

Nothing here moves, so there is nothing for a reduced-motion preference to take
away and no `IuxMotionPolicy` call to make. The layout switches between the
shared row and the stacked one on a text-size and width change, which is not an
interactive transition and not something an animation would explain. A bar that
animated its own height would be motion that answers no question.

## Accessibility

- The title is exposed as a **heading**, so a screen-reader user can jump
  straight to it and learn where they are instead of listening to the controls
  first.
- The way out and every action carry a caller-supplied, localised accessible
  name. Neither can be written without one.
- Reading order is tree order: on a shared row, the way out, then the heading,
  then the actions; stacked, the way out, the actions, then the heading. Nothing
  is reordered visually without being reordered semantically.
- Every control meets the resolved touch target floor at every density and text
  scale, and adjacent controls keep at least `kIuxMinimumTargetSpacing` between
  them. Both are asserted at 200% on a 320-pixel screen, where they are hardest
  to hold.
- The title wraps and is never truncated. Asserted on all four theme profiles.
- The bar is one semantic container whose controls stay individually reachable.
- A disabled action is announced as disabled and reads out its
  `unavailabilityReason`; it is not merely greyed.
- Keyboard and D-pad reach every control, and each keeps a visible focus ring —
  inherited from `IuxIconButton`, not reimplemented.
- Rendered right-to-left: the way out sits on the trailing edge and its arrow
  mirrors itself.
- The boundary between the bar and the page is a divider in `border.standard`,
  the role that carries a 3:1 guarantee. It is the only visual signal separating
  the two, since both sit on `surface.base` — so it is not allowed to be the
  decorative role, and it is not a shadow, which a reduced visual stimulation
  preference resolves away.

**Verified in widget tests.** Still requires a device: TalkBack heading
navigation and how it announces a wrapped multi-line heading, Voice Access
naming of the icon controls, and D-pad traversal from the bar into the page
below it.

## Anti-patterns

```dart
// Wrong: the slot caps the bar at a height fixed before layout, so the title
// is clipped the moment it needs a second line.
Scaffold(appBar: PreferredSize(preferredSize: Size.fromHeight(56), child: IuxAppBar(...)))

// Right: the bar sits at the top of the body and grows with its title.
Scaffold(body: Column(children: <Widget>[IuxAppBar(...), Expanded(child: page)]))
```

```dart
// Wrong: the top inset is spent twice — once by the bar, once by the page.
Column(children: <Widget>[IuxAppBar(...), Expanded(child: IuxPage(child: content))])

// Right.
Column(children: <Widget>[
  IuxAppBar(...),
  Expanded(child: IuxPage(insets: IuxPageInsets.bottomOnly, child: content)),
])
```

```dart
// Wrong: a title written as a sentence. It will get the lines it asks for, and
// will have pushed the content that far down to do it.
IuxAppBar(title: l10n.reviewTheDeliveryExceptionsFlaggedThisQuarter)

// Right: the name of the place.
IuxAppBar(title: l10n.deliveryExceptions)
```

```dart
// Wrong: five glyphs and no title left. Refused on the first build.
IuxAppBar(title: l10n.orders, actions: <IuxIconButton>[a, b, c, d, e])
```

```dart
// Wrong: an action belonging to one row, hoisted to the screen.
IuxAppBar(title: l10n.orders, actions: <IuxIconButton>[deleteThisOrder])
```

## Limits

- **No overflow menu.** The fourth action has nowhere to go, and this component
  will not grow one: a menu is a surface with its own focus and dismissal
  rules. Until one exists, the fourth action belongs on the page.
- **No search field, no tab strip, no selection mode, no filter chips.** All are
  separate components; a bar that hosts them stops being a bar.
- **No subtitle.** A second line of text under the title competes with the one
  thing the bar is for. If the screen needs context beyond its name, that
  context is content.
- **No collapsing or scroll-under behaviour.** Both need slivers, and `IuxPage`
  scrolls a `SingleChildScrollView`. A sliver-based variant is a separate
  component with a separate contract, not a parameter on this one.
- **No `PreferredSizeWidget`**, so it cannot be dropped into `Scaffold.appBar`
  or into any third-party API that expects one. See above for why.
- **The double-padding rule is documentation, not an assertion.** The bar and
  the page are siblings, and no component can inspect its sibling. A composition
  widget owning both would make it unrepresentable; that belongs to a later
  mission, not to a component that should stay one thing.
- **The readable floor is a hypothesis.** Twelve characters, and half an em per
  character, are the same crude conversion the layout package already uses. It
  will be wrong for CJK and for monospace, in the generous direction — the title
  keeps the shared row slightly more often than it should, and wraps rather than
  truncating when it does.
- **A very long title with no controls can push the content most of the way down
  a small screen.** Nothing clips, which is the guarantee; whether a title that
  long is a good title is the caller's decision.
- **Composed with `IuxPage`, three things go wrong** (`IUX-APPBAR-PAGE-001`),
  and this is the most-repeated composition any application writes.
  - **The top inset is applied twice, and nothing asserts.** The bar's
    `SafeArea` removes the inset for its own subtree only; a sibling `IuxPage`
    on the default `IuxPageInsets.handled` consumes it again. Measured with a
    40 px inset: content starts at y 152 instead of y 112. `IuxPageInsets`
    cannot express the fix — `none` also drops the landscape side insets, and
    there is no `exceptTop` — so the working remedy is
    `MediaQuery.removePadding(removeTop: true)` around the page. See
    `apps/pilot/lib/screen_frame.dart`.
  - **The chrome does not fit at a large text scale, and no component owns the
    total.** On 320x640 with three destinations: at 100% the bar and bottom
    navigation take 56 and 92 px and leave 492; at 300% they take 260 and 408
    and leave **−28**, and the frame overflows. `IuxBottomNavigation` honours
    its own documented degradation and takes its share first; nothing then
    defends the content.
  - **The standard fix is structurally unavailable.** Fill-viewport-or-scroll
    needs `IntrinsicHeight`, which throws with *LayoutBuilder does not support
    returning intrinsic dimensions* — `IuxAppBar` uses a `LayoutBuilder`
    internally to decide whether the title shares a row with the controls. **No
    IUX screen containing an app bar can take part in `IntrinsicHeight`,
    `IntrinsicWidth` or intrinsic `Table` sizing.** What is left is to scroll
    the whole screen, bar included, and the cost is that the title is not
    pinned at any text scale.

## Evidence level

**Standard** for the accessibility guarantees: accessible name on every control,
heading exposure, target size and target spacing, text scaling to 200% without
truncation, reduced motion, and the 3:1 boundary.

**Strong guidance** for the three-action limit and for the back/close
distinction — Material's top app bar guidance and the general finding that
unlabelled icons are the least discoverable form of a control.

**Context dependent** for composing into the body rather than into
`Scaffold.appBar`. It follows from a hard constraint of that slot, but a project
willing to cap its titles could reasonably choose otherwise.

**Hypothesis** for the twelve-character readable floor and the half-em character
width. Neither has been validated with users.

## Sources

- WCAG 2.2 — SC 1.3.1 Info and Relationships, SC 1.3.2 Meaningful Sequence,
  SC 1.4.4 Resize Text, SC 1.4.10 Reflow, SC 1.4.11 Non-text Contrast,
  SC 2.1.1 Keyboard, SC 2.4.6 Headings and Labels, SC 2.4.7 Focus Visible,
  SC 2.5.8 Target Size (Minimum), SC 4.1.2 Name, Role, Value.
- Android accessibility guidance — labelling icon controls, heading navigation
  in TalkBack.
- Material 3 — top app bar: action count, and the medium/large forms that place
  the title on its own line below the controls.
- `docs/layout/overview.md` — `IuxPage`, `IuxPageInsets`, target spacing,
  wrapping beats clipping.
- `docs/components/button.md` and `docs/components/button-variants.md` —
  `IuxIconButton`, which every control here is.
- `docs/components/component-standard.md`.
