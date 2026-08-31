# Device session — 2026-08-31, Pixel 7

The first time anything in this repository was observed on a device.
`IUX-MANUAL-001` had said no session had ever been run. That sentence is now
wrong in one direction and still right in another, and this file is the
difference.

## What it ran on

| | |
| --- | --- |
| device | **Pixel 7** (`panther`), serial `34031FDH2006JT`, USB-authorised |
| Android | **17** (SDK 37) |
| TalkBack | **17.0.1.926549743** |
| build | catalog debug APK, built from `main` at `a477cef` |
| Flutter | 3.44.8 stable |

TalkBack was enabled over `adb` **alongside** the accessibility service already
running on the phone, and both settings were restored afterwards and verified
byte-for-byte against what was captured before. TalkBack's process is stopped.

## What was done, and what half was not

The protocol asks for six blocks. **What follows is the mechanical half of Block
A only**: the node tree the platform composes, and whether a control can be
activated.

**TalkBack's speech and traversal order could not be captured over `adb`.** Its
utterance logging lives behind an in-app developer setting, `setprop
log.tag.*` does not reach it, and `uiautomator dump` exposes input focus but not
accessibility focus. So *what it says, in what order, and whether it says
anything twice* — the questions Block A exists for — still need a person with
the phone in their hand. Blocks B to F likewise.

---

## Finding 1 — the instrument's proven blind spot is not blind here

The library shipped **no icons at all** for weeks while the whole suite passed,
because `flutter_test` substitutes a font that draws every glyph as a filled
box. That is the story `IUX-MANUAL-001` tells about why a device matters.

**The icons render.** Whatever else this session found, that class of defect is
absent from the build on `main` today.

## Finding 2 — names and states do reach `AccessibilityNodeInfo`

This is the first non-modelled evidence for **clause 11.5.2.5**, and it is
positive. Read from the real platform tree, not from Flutter's semantics:

```
[Button] 'Brightness: dark'      focusable
[Button] 'Brightness: light'     focusable, selected
[Button] 'Contrast: standard'    focusable, selected
[Button] 'Contrast: high'        focusable
```

Names arrive as `content-desc`, roles map onto Android widget classes, and
`selected` is set on **exactly** the chosen chips and no others. The inference
this project has been resting on — that Flutter's semantics tree reaches the
platform — holds, on this device, for these controls.

## Finding 3 — an inference from the tree was wrong, and the device is the only thing that could say so

**This is the session's most useful result, and it is a correction rather than a
defect.**

The catalog's chips and section buttons appear in the platform tree with
`clickable=false`. Reading only the tree, the conclusion was obvious and it is
the one this repository's own dartdoc states: *"the node announces a button and
offers nothing to activate, so a screen-reader double-tap does nothing at all —
the control is visible, named, and unusable."*

It was tested rather than assumed. With TalkBack running and touch exploration
on, double-tapping `Section: Charts`:

```
selected before:  Section: Buttons
selected after:   Section: Charts
```

**The control activated.** TalkBack's double-tap, finding no `ACTION_CLICK` on
the node, falls back to a synthesised touch at the focused node's bounds, and
the `GestureDetector` underneath receives it.

What survives: the node does not advertise the action, which still matters for
assistive technology that drives actions rather than synthesising touches —
Switch Access, Voice Access — and neither was tested. What does **not** survive
is "unusable". The model was wrong in the pessimistic direction, and no widget
test could have shown it.

## Finding 4 — a real defect, in the harness rather than the library

`apps/catalog/lib/catalog_chrome.dart:239`:

```dart
Semantics(
  label: 'Catalog conditions', button: true, excludeSemantics: true,
  child: GestureDetector(onTap: () => onExpandedChanged(!expanded), …
```

`excludeSemantics: true` removes the child's semantics **including the
`GestureDetector`'s tap action**, and no `onTap` is re-published on the
`Semantics` node. This is the defect `IuxSemantics.action` documents in its own
dartdoc and re-publishes `onTap` specifically to avoid.

Its visible consequence in the tree is worse than the missing action: one
`Switch` node carries a **626-character** accessible name that has swallowed the
header's explanatory paragraph *and* the list of section names.

**The catalog builds this by hand** — a raw Material `Switch` and a raw
`Semantics`, not IUX components — for a reason its own comment gives: it is the
control a maintainer needs in order to leave a broken state. So this is not a
library defect.

**The structural point is better than the defect.** The library has a guard
against exactly this — `announced_controls_test.dart`, *"a node announced as a
control offers something to activate"* — and it scans `Directory('lib/src')`.
The catalog is outside its reach, so the harness reproduced, unimpeded, the
precise failure the library documents and guards. That is a coverage hole.

---

## What this session does not establish

- **Nothing about speech.** Not one utterance was heard or captured. Every
  finding above is about the node tree and one activation.
- **Nothing about order.** Whether the reading order is sensible, whether
  anything is announced twice, whether a live region fires in the same frame as
  a focus move — `IUX-GUIDED-FORM-LIVE-001` is still unexamined.
- **Nothing perceptual.** F3 and F6 — the chip's outline in monochrome, the
  octagon against the circle in greyscale at arm's length — need eyes at a
  physical distance from a physical screen.
- **Nothing about the five newest components.** `IuxSelectField`,
  `IuxDataTable`, `IuxDateField`, `IuxSlider` and `IuxTimelineChart` were on the
  build and none was opened. The protocol has no blocks for them yet.
- **One device, one Android version, one TalkBack.** A Pixel says nothing about
  Samsung's stack, and a default TalkBack says nothing about one a user has
  configured.
