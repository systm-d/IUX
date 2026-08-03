# Layout system

## Intention

Give screens a predictable skeleton, and make the failures that break layouts
in the field — narrow screens, enlarged text, notches, keyboards — hard to
reproduce.

```dart
Scaffold(
  appBar: AppBar(title: Text(l10n.orders)),
  body: IuxPage(
    child: IuxSection(
      title: l10n.recent,
      children: <Widget>[...],
    ),
  ),
)
```

## Primitives

| Primitive | Responsibility |
| --- | --- |
| `IuxPage` | background, safe areas, width cap, padding, scroll, pinned footer |
| `IuxSurface` | a themed background at a named level |
| `IuxSection` | a titled group, exposed as a screen-reader landmark |
| `IuxGap` / `IuxInsets` | spacing taken from the scale, adapted to density |
| `IuxTargetSpacing` | the minimum separation between adjacent controls |
| `IuxReadableWidth` | a reading-width cap that scales with text size |
| `IuxLayoutClass` / `IuxResponsiveValue` | width-class branching |

## `IuxPage` does not replace `Scaffold`

A `Scaffold` owns app bars, sheets and the snack bar host. `IuxPage` owns the
content area. They compose, and neither tries to absorb the other — a page
primitive that swallowed `Scaffold` would have to re-expose everything it hid,
badly.

## Scrolling is the default

A screen that does not scroll breaks the moment a user enlarges their text or
a keyboard appears. Both happen constantly, and neither is an edge case.

The scroll physics are `AlwaysScrollableScrollPhysics`, so content can be
dragged out from under a keyboard even when it would otherwise fit.

## Safe areas are opt-in per edge

Applying `SafeArea` everywhere is how double padding happens: a page adds it,
a sheet inside adds it again, and the content sits twice as far from a notch
that exists once.

| `IuxPageInsets` | Use when |
| --- | --- |
| `handled` | a full screen. The default. |
| `topOnly` | the bottom is occupied by navigation that handles its own inset |
| `bottomOnly` | the top is occupied by an app bar that already does |
| `none` | edge-to-edge content painting behind the system bars |

Under `none` the application owns the insets, including
`SystemUiOverlayStyle`. IUX imposes no system bar colour.

## Reading width scales with text size

The width caps are expressed in **characters**, then converted using the text
size actually in force.

A fixed pixel cap silently halves the characters per line when a user doubles
their text size — producing a narrow column of enlarged text, which is the
opposite of what they asked for.

| Cap | Characters | Use for |
| --- | --- | --- |
| `narrow` | ~35 | a single input, a confirmation |
| `reading` | ~70 | running prose |
| `standard` | ~100 | forms, lists, cards |
| `wide` | ~140 | dense content such as a table |
| `fluid` | — | no cap |

Below the cap the content simply fills the width, so this never makes a narrow
screen narrower.

## Spacing between targets

`IuxTargetSpacing` guarantees at least 8 logical pixels between adjacent
interactive elements, and raises any smaller request to that floor.

Target *size* alone does not prevent mis-taps: two 48-pixel targets touching
each other still produce them, because a finger landing near the seam has no
margin. WCAG 2.2 SC 2.5.8 recognises this by allowing smaller targets when
spacing compensates; IUX keeps both.

This is the concern IUX-005 explicitly deferred when it delivered the target
floor.

## Wrapping beats clipping

`IuxTargetSpacing` and `IuxSectionHeader` use `Wrap`, not `Row`. At a large
text scale a row of controls stops fitting, and moving to a second line is
better than clipping a label the user cannot then read.

## Layout classes

Three, matching Android's window size classes: compact below 600, medium to
840, expanded above.

They are measured from the **available width**, not the physical screen. A
split-screen window on a tablet is compact, and treating it as expanded is the
classic way to ship an unusable multi-window experience.

`IuxResponsiveValue` requires `compact` and falls back upward, so the narrow
case — the one most users are in — cannot be forgotten.

## Reading order

The primitives lay out in tree order, so the visual, semantic and focus orders
agree by construction. Nothing here reorders visually without reordering
semantically.

## One-handed reach

IUX does not impose a thumb-zone rule. Reach depends on hand size, grip, device
size and whether the user has two hands free, and a framework-level rule would
be wrong for most of them.

`IuxPage.footer` exists so a primary action can stay reachable without
scrolling to the end — which is where it matters most, on long forms. Whether
to use it is the screen's decision.

## Limits

- No custom scroll engine. Flutter's primitives are used directly.
- Nested scrolling is not modelled; a page inside a page is a design problem.
- The character-to-pixel conversion assumes a proportional Latin face and is
  deliberately generous. It will be wrong for CJK and for monospace.
- Form fields, navigation and app bars are later missions.

## Evidence level

Standard for the target spacing floor and for text-scale resilience. Strong
guidance for the reading-width range. Context dependent for the primitive
decomposition. Hypothesis for the character counts.

## Sources

- WCAG 2.2 — SC 2.5.8 Target Size (Minimum), SC 1.4.4 Resize Text,
  SC 1.4.10 Reflow.
- Android — window size classes.
