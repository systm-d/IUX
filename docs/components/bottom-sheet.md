# IuxBottomSheet

## Purpose

Put a secondary surface at the bottom of the screen without taking the user off
the page they are on — and keep it usable when a keyboard takes half of what is
left.

```dart
Stack(
  fit: StackFit.expand,
  children: <Widget>[
    IuxPage(child: orders),
    if (state.filtering)
      IuxBottomSheet(
        title: 'Filter orders',
        dismissLabel: 'Close',
        onDismissed: controller.closeFilters,
        child: filterFields,
      ),
  ],
)
```

## Use when

The user needs a second surface *and* the page behind it is part of the answer:

- filtering or sorting a list they can still see changing;
- choosing from a set of options that belongs to the row they tapped;
- one or two fields attached to something on the page.

## Do not use when

- **The user must answer before continuing.** That is `IuxDialog`. A sheet
  deliberately leaves the page visible and reachable-looking; a question that
  blocks the task should look like it blocks the task.
- **It is a whole form, or more than a screenful.** The sheet is capped at a
  fraction of the screen precisely so it cannot become a page, and a long form
  needs what a page has: room, a back gesture, a place in the history, and a
  scroll position that survives rotation.
- **The user did not ask for it.** A surface that rises unbidden is dismissed
  reflexively, and so is the next one.
- **It is navigation.** A sheet full of destinations is a menu that vanishes:
  the user cannot go back to it, because there is no "back" to it.

## It is a layer, not a route

`IuxBottomSheet` never calls `Navigator`, for the same reason `IuxDialog` does
not: the back stack, deep links and state restoration belong to the
application, and a component that quietly pushes onto them cannot be reasoned
about from the call site.

So the parent owns a flag, and the sheet exists exactly while the flag is true.
The consequences are the dialog's, unchanged:

| Consequence | What it means for you |
| --- | --- |
| The sheet cannot leak | No code path pops the wrong route or forgets to pop. |
| The page stays mounted behind it | Scroll position, controllers and animations survive. |
| The system back button does not reach it | You wire it, in one place, with the same callback. |

```dart
PopScope(
  canPop: !state.filtering,
  onPopInvokedWithResult: (bool didPop, Object? result) {
    if (!didPop) controller.closeFilters();
  },
  child: Stack(fit: StackFit.expand, children: <Widget>[page, sheet]),
)
```

### Use `IuxModalLayer.sheet`

`IuxModalLayer` gained a `sheet` slot at IUX-020, with an assertion refusing a
dialog and a sheet at once. **Use it.** The plain `Stack` this page used to
prescribe is no longer necessary, and assembling the stack by hand is how a
covered page keeps its semantics node and goes on offering a screen reader
controls the user cannot touch.

```dart
IuxModalLayer(
  sheet: isOpen ? IuxBottomSheet(/* … */) : null,
  child: page,
)
```

## The keyboard

This is the part a sheet has to get right and a dialog never has to face, and
it is two separate problems.

**Lifting.** The sheet raises itself so the keyboard covers none of it, and its
content scrolls inside whatever height is left. The lift is *not* the
keyboard's height. Whatever laid the sheet out may already have removed part of
the keyboard from the box it handed over — a `Scaffold` with the default
`resizeToAvoidBottomInset` shrinks its body above the keyboard and does **not**
remove the inset from the `MediaQuery` that body sees. Adding the full inset on
top of that lifts the sheet twice and leaves a keyboard-sized band of scrim
underneath it. So the sheet lifts by the residue: the part of the keyboard
still underneath the box it was given.

The result is that the sheet lands in the same place whether the host resizes
or not, which is what the tests assert.

**Padding.** While the keyboard is up it is covering the navigation bar, so the
platform already reports `padding.bottom` as zero. The `SafeArea` inside the
panel therefore adds nothing on top of the lift, without needing a special
case. That is why the inset is consumed with a `SafeArea` and not with a
hand-computed number.

The lift is not animated by the component. The platform reports the inset
progressively while the keyboard opens, so the padding is already following a
curve; animating it again would make the sheet lag behind the keyboard it is
supposed to be sitting on.

## Height

The sheet is **as tall as its content, up to 60% of the screen**. Below that it
shrink-wraps; above it, the content scrolls.

Both failure modes are real and neither is a matter of taste:

- A sheet that opens at 90% of a small screen is a dialog wearing a disguise.
  It removes the page that gave the sheet its meaning — "filter *these*" is
  unanswerable when "these" is covered.
- A sheet fixed at some short height hides its own content and turns every use
  into scrolling.

Content-sized-with-a-cap is the only rule that avoids both, and it needs no
parameter: the content already knows how tall it wants to be.

The 60% is a judgement, not a measurement, and it is the one number here worth
arguing about. What is not a judgement is the interaction with the keyboard:
when the keyboard has taken more than 40% of the screen the cap stops binding
and the sheet uses everything above the keyboard. Reserving space for a page
the keyboard has already covered would leave a strip too short to hold a field.

There is no `height`, `initialSize` or `maxSize` parameter, and no snap points.
A caller who needs to choose a height is describing a page.

## Insets

The sheet sits on the bottom edge, so **it** consumes the bottom system inset —
inside the panel, so the surface still reaches the physical edge and no strip of
page shows underneath it. It never consumes the top inset: the padding a notch
needs is at the top of the screen, and applying it inside a panel that is
nowhere near the top would inset the content for an obstacle that is not there.

**Never place an `IuxBottomSheet` inside an `IuxPage`.** The page has already
consumed the system insets and applied its padding; the sheet would inset its
content a second time from a bar that is only there once. That is what
`IuxPageInsets` exists to prevent, and a sheet is where it bites hardest,
because the sheet lives on exactly the edge the page is padding.

A page behind an open sheet keeping `IuxPageInsets.handled` is correct and not a
double inset: the two are insetting *different* content, and the page's own
content is still there behind the sheet.

## API

### `IuxBottomSheet`

| Parameter | Required | Note |
| --- | --- | --- |
| `title` | yes | what the sheet is; also the announced route name |
| `dismissLabel` | yes | the visible text of the way out |
| `onDismissed` | yes | scrim, Escape and the header button all call this |
| `child` | yes | the content, which is the reason the sheet exists |

There is no `actions` list. A sheet is a surface, not a decision: actions that
belong to the content go in the content, at its end. A second place to put
buttons is a second reading order to get wrong.

There is no colour, radius, elevation, duration, height, snap point,
`isDismissible` or `enableDrag` parameter, and there will not be one. See
[What it refuses to do](#what-it-refuses-to-do).

## Behaviour

| Event | Result |
| --- | --- |
| opens | focus moves into the sheet; the route is announced; the page leaves the semantic tree |
| Escape | `onDismissed` |
| tap on the scrim, including above the panel | `onDismissed` |
| tap on the header button | `onDismissed` |
| tap on the panel itself | nothing — a tap on the padding is not a dismissal |
| drag on the panel | nothing; see below |
| a keyboard opens | the sheet lifts above it and its content keeps scrolling |
| removed from the tree | focus returns to whatever held it when the sheet opened |

The sheet never closes itself. Closing is a state change, the parent owns the
state, and a sheet that closed itself would leave the parent's flag saying it
was still open.

## Drag

There is no drag-to-dismiss, and — more importantly — **no drag handle**.

A drag handle is invisible to a screen reader, meaningless to Voice Access, and
out of reach for a user with tremor or limited dexterity. It cannot be the way
out of anything. Drawing one while nothing drags would be worse still: an
affordance that does not work is a lie, and the user who tries it concludes the
application is broken rather than that the gesture was never there.

So the way out is a labelled, focusable button that requires no gesture, plus
Escape, plus the scrim. If drag arrives later it will be a redundant
accelerator over that button, never a replacement — and the button will still
be there.

## Accessibility

- **Focus enters, is trapped, and is restored.** Focus moves into the sheet on
  open, Tab and arrow traversal cycle inside it, and on close it returns to the
  node that held it when the sheet opened — not to wherever it drifted while
  the page was covered.
- **Focus lands on the panel, not on a field.** A sheet that focuses its first
  input raises the keyboard before the user has read the title, covering half
  of what they were about to read. They open the keyboard by choosing a field,
  which is also the moment they know which field they want.
- **The way out is the first control.** The title reads first because it says
  what the sheet is; the dismissal is the first thing a Tab, a D-pad press or a
  screen-reader swipe reaches, ahead of anything in the content.
- **The route is scoped and named** with the title, so assistive technology
  announces the change of context rather than leaving the user to discover it.
- **The page behind leaves the semantic tree.** A control that reads out but no
  longer responds is worse than one that is gone.
- **The scrim is not announced.** It dismisses, but the button says the same
  thing in words. An unlabelled tappable region reachable only by swiping is a
  control the user cannot verify before activating.
- **Everything scrolls, including the header.** Pinning the title and the
  dismissal reads better right up to 200% text on a 320x480 screen, where the
  two of them together are taller than the sheet is allowed to be and the
  content gets nothing at all. The header gives way; being *first* in the
  scroll view is what keeps the cost small.
- **The header stacks past ~130% text**, rather than squeezing the title into a
  column two characters wide beside a button.
- **The title is a heading**, and is never truncated at any text size.
- **Right-to-left** mirrors the header: the title still reads before the way
  out, which puts it on the right.

**Verified in widget tests.** Still needs checking on a device: TalkBack
reading order and route announcement, Voice Access naming, D-pad traversal, the
system back gesture with the `PopScope` above, and the real keyboard animation
on a physical Android device.

## Themes and motion

Every colour is resolved from `IuxSemanticColors`; the panel is
`IuxSurfaceRole.overlay`, bordered as well as elevated, because elevation
resolves to zero under a reduced visual stimulation preference and the edge of
a modal surface is not something that may quietly disappear.

The scrim is derived exactly as the dialog's is: whichever of `surface.base`
and `surface.inverse` the theme resolved *darker*, at 60% opacity. Choosing by
measured luminance rather than by brightness is what stops a scrim brightening
what it covers in dark conditions. The opacity is the same value the dialog
uses, deliberately — two modal surfaces that dim the page by different amounts
read as two different degrees of interruption when they are the same one.

Motion is declared as `IuxMotionRole.reveal`, not `enter`, and the difference is
the whole point. Both animate an appearance, but only `reveal` turns into a
fade when the user asks for less motion; `enter` would merely *shorten* the
travel, and a fast large movement is harder for a vestibular disorder than a
slow one, not easier. So:

| Preference | What happens |
| --- | --- |
| standard | the panel rises its own height from the bottom edge, and fades in |
| reduced | it fades in where it will sit; no travel |
| none | it is fully present on the first frame |

The rise says where the sheet came from and therefore where it lives. There is
no exit animation: the parent removes the sheet from the tree, and a widget
cannot outlive its own removal.

## What it refuses to do

```dart
// Wrong: the sheet is asked to close itself.
IuxBottomSheet(onDismissed: () { save(); closeItself(); })
// Right: the parent owns the flag.
IuxBottomSheet(onDismissed: controller.closeFilters)
```

```dart
// Wrong: a sheet with no way out but a swipe.
// Unrepresentable — onDismissed and dismissLabel are required, and there is no
// enableDrag / isDismissible flag to turn the visible one off.
```

```dart
// Wrong: a sheet asked to be 90% tall.
// There is no height parameter. A caller who needs to choose a height is
// describing a page.
```

```dart
// Wrong: a whole form in a sheet.
// It will not fit at 200% text with a keyboard up, and the sheet's cap is
// what stops that being discovered by a user rather than by you.
```

## States

| State | Source |
| --- | --- |
| open, closed | the parent's flag |
| focused | internal; the panel first, then the way out |
| scrolled | internal; the content decides whether there is anything to scroll |
| lifted | the platform's keyboard inset, minus whatever the host already removed |

There is no loading state for the sheet as a whole and no error state. A sheet
that waits on a network call while covering the page is a sheet the user cannot
act on; report progress inside the content, or on the action's own descriptor.

## Limits

Known, stated rather than hidden. The first three are changes this component
wanted and could not make within its own files.

- ~~**`IuxModalLayer` cannot hold it.**~~ **Closed at IUX-020.** The `sheet`
  slot exists, with `assert(dialog == null || sheet == null)` and a paint order
  of `[child, sheet, dialog]`, exactly as this limit proposed. See
  [Use `IuxModalLayer.sheet`](#use-iuxmodallayersheet).
- **The keyboard inset is read straight from the ambient `MediaQuery`**, via
  `dependOnInheritedWidgetOfExactType`, because the Component Standard forbids
  `MediaQuery.…Of(` inside a component and the contract test enforces it by
  pattern. That rule is right about what it was aimed at — a component must not
  reach its own conclusion about a *preference* behind `IuxAccessibility`'s
  back. A view inset is not a preference: it is a measurement of how much of the
  window the platform took away this frame. The proper fix is a layout-layer
  helper, `IuxInsets.keyboard(context)` beside `IuxInsets.page`, at which point
  this component reads it like every other measurement and the standard needs no
  exception. The cost of the current form is a rebuild when an unrelated part of
  the `MediaQuery` changes.
- **The scrim derivation is duplicated from `IuxDialog`**, where it is private.
  It belongs in one place — either an `IuxScrim` in `components/overlay/`, or,
  better, a scrim role in the semantic layer so it stops being derived at all.
- **The panel is rounded on all four corners**, including the two against the
  screen edge, because `IuxSurface` has one radius. Rounding only the top needs
  a corner option on the surface layer.
- **`resizeToAvoidBottomInset: false` on a `Scaffold` that also has an app bar
  or a bottom bar** makes the lift undershoot by the height of that chrome. The
  residue is computed from the box the sheet was given, and in that one
  configuration the chrome is indistinguishable from a keyboard that has already
  been removed. Leaving `resizeToAvoidBottomInset` at its default is correct and
  is what the tests cover.
- **The system back button does not dismiss it** unless the parent adds the
  `PopScope` above. This is the price of not calling `Navigator`.
- **No exit animation**, for the reason above.
- **`child` is a widget slot**, so contrast, target sizes and semantics inside
  it are the caller's.
- ~~Route scoping uses a bare `Semantics`~~ — **Fermé.** Le runtime expose désormais les helpers manquants (`IuxSemantics.selection`, `.radioGroup`, `.field`, `.route`, `.contentAction`, `.contentContainer`) et le composant les utilise. Voir `docs/accessibility/semantics.md`.
- **Route scoping**, because `IuxSemantics` has no route
  helper yet. Adding one belongs to the accessibility layer.
- **No drag**, by decision rather than omission. See [Drag](#drag).

## Evidence level

| Rule | Level | Source |
| --- | --- | --- |
| Focus moves into the sheet and returns on close | Standard | WCAG 2.2 SC 2.4.3, 2.1.1, 2.1.2 |
| Focus is trapped while the sheet is open | Standard | WAI-ARIA Authoring Practices, dialog pattern |
| The content stays reachable at 200% text | Standard | WCAG 2.2 SC 1.4.4, 1.4.10 |
| A visible, named dismissal that needs no gesture | Standard | WCAG 2.2 SC 2.5.7, 2.1.1; Android accessibility |
| The route is scoped and named | Standard | Android accessibility guidance; Flutter route semantics |
| Escape, scrim and button are the same outcome | Strong guidance | WAI-ARIA APG; Material guidance |
| Focus lands on the panel, not on a field | Strong guidance | WAI-ARIA APG |
| The page behind stays partly visible | Strong guidance | Material bottom sheet guidance; Nielsen Norman Group on context retention |
| Travel becomes a fade under reduced motion | Strong guidance | WCAG 2.2 SC 2.3.3; vestibular disorder guidance |
| A cap of 60% of the screen | Hypothesis | not a measured optimum; needs user validation |
| Scrim opacity of 60% | Brand choice | matches `IuxDialog`; not a measured optimum |

## Sources

- WCAG 2.2 — SC 1.4.4, 1.4.10, 2.1.1, 2.1.2, 2.3.3, 2.4.3, 2.4.7, 2.5.7, 4.1.2.
- WAI-ARIA Authoring Practices, dialog (modal) pattern.
- Android accessibility guidance; Material bottom sheet guidance.
- Nielsen Norman Group, on modal surfaces and retained context.
- `docs/components/component-standard.md` §2, §3, §5, §11.
- `docs/components/dialog.md`, whose decisions this component follows wherever
  the two face the same problem.
