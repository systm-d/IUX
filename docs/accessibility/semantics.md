# Semantics

## Intention

Give components one consistent way to describe themselves to assistive
technology.

Hand-built `Semantics` drifts. One component sets `button: true` and forgets
`enabled`; another labels an icon and forgets to exclude the icon's own
semantics, so the screen reader reads the label twice. The result is a library
whose reading order is unpredictable.

## Helpers

| Helper | Use for | The subtree |
| --- | --- | --- |
| `IuxSemantics.action` | a control whose label already says everything | excluded |
| `IuxSemantics.contentAction` | a control whose content is part of the answer — a card | merged in |
| `IuxSemantics.selection` | a checkbox, a switch, one radio | excluded |
| `IuxSemantics.radioGroup` | the set one radio belongs to | kept, separate |
| `IuxSemantics.field` | a value the user types | merged in |
| `IuxSemantics.route` | a layer that takes over the screen — a dialog | kept, separate |
| `IuxSemantics.header` | a section title a reader can jump to | excluded |
| `IuxSemantics.image` | an image, or `label: ''` for decoration | excluded |
| `IuxSemantics.liveRegion` | a status that appears in place | kept |
| `IuxSemantics.group` | content that must be read as one unit | kept |
| `IuxSemantics.contentContainer` | one object whose parts stay reachable — a card | kept, separate |
| `IuxSemantics.decorative` | genuinely redundant content | excluded |
| `IuxSemantics.disabled` | an unavailable control | excluded |

## The third column is the one that goes wrong

Excluding a subtree deletes it from the interface of every screen-reader user,
and nothing on screen changes when it happens. It is the right default for a
button reading "Save", whose icon and text only repeat the name it was given.
It is wrong three ways elsewhere:

- **It deletes content.** A card announcing an order loses the reference, the
  status and the amount, and stays a plausible-looking button.
- **It deletes actions.** A field loses set-text, set-selection and
  move-cursor, so a screen reader can find it, announce it, and never type into
  it. That is why `field` merges rather than excludes.
- **It deletes the tap action.** This one already shipped: `action` excluded
  the subtree and took the child's tap handler with it, so every button in the
  library announced itself and did nothing. `action` now carries its own
  `onTap`, and every helper that announces a control can carry one.

The rule that follows: **anything announcing a control takes its activation
explicitly.** Never rely on a descendant to supply it.

"Kept, separate" is a third answer, and it is not the same as "kept". It forces
every child to keep its own node. Without it a control that does not declare
itself a semantic container has its name and role absorbed into the parent, and
a card is announced as a single button called "Order 3141, Track" — wrong, and
unreachable, because the control it came from is no longer somewhere the user
can land.

## Two helpers, one shape: which one

`action` and `contentAction` both announce a button. `group` and
`contentContainer` both draw a boundary. The pairs differ only in what becomes
of the content, which is exactly the decision worth naming rather than
inferring:

- Content that repeats the label → `action`, `group`.
- Content that *is* the information → `contentAction`, `contentContainer`.

A block that contains its own controls is never `contentAction`: merged into
one stop, a nested button loses the node the user would have landed on.

## Leave `selected` null unless it toggles

`IuxSemantics.action` takes `bool? selected`, defaulting to null. Passing
`false` advertises a selected *state*, so a plain button gets announced as
"not selected" — inviting the user to look for a selection that does not
exist.

## Grouping matters

Without `group`, a row of label and value is announced as two unrelated
fragments and the relationship between them is lost. Grouping is not a
nicety; it is what makes the pair mean anything.

## Announcements are a last resort

**Prefer `liveRegion` to `IuxAnnouncement`, on Android especially.**

Android has deprecated `announceForAccessibility` because it forces TalkBack to
clear its speech queue and speak the given text — cutting off whatever the user
was listening to. An announcement is an interruption in the literal sense.

Use `IuxAnnouncement` only when a change has no on-screen representation at
all: a background save completing, a list refreshing in place with no visible
status. When the message does appear on screen, mark that region live and let
the platform announce it. The user then hears it once, in context, and can
re-read it.

Every announcement method returns whether delivery actually happened.
Announcements are unsupported on some platforms, which is exactly why essential
information must never depend on one.

## Text that the user enlarged

`IuxReadableText` decides line limits and overflow from the scaling in force.
Above roughly 1.3x it removes the line limit and switches overflow to visible:
truncating enlarged text defeats the reason the user enlarged it, and an
ellipsis hides precisely the content they asked to see more of.

The 1.3x threshold is a heuristic, not a standard.

## Name, role, value

`IuxSemantics.selection` takes an `IuxSelectionRole` and an
`IuxSelectionValue`, which are WCAG 4.1.2's own vocabulary rather than three
booleans. Android reads the three roles differently — "checked" for a box, "on"
for a switch, one option of a set for a radio — so announcing a switch as a
checkbox tells the user a Save button is coming that does not exist.

`IuxSelectionValue.partial` is legal only on a checkbox, and that is asserted.
A switch has two physical positions and a radio is one option among several, so
neither has anywhere to put a mixed state.

These are runtime types, not the selection controls' own. The runtime sits
below the components and must not know that a checkbox widget exists, so
`IuxCheckbox` translates its `IuxSelectionState` into `IuxSelectionValue` on the
way in. Two enums with the same three names is the price of the layering, and
the translation is written once so it cannot be written backwards.

## Rules

1. An icon-only control always has a label.
2. `decorative` is only for content that genuinely repeats something adjacent.
   Hiding anything else removes it from the interface for part of the users.
3. Reserve `assertive` announcements for what the user must know now.
   Interrupting for less trains users to turn announcements off.
4. A component composes no bare `Semantics`. If no helper fits, the gap is in
   the runtime; four components carried that gap as a documented exception
   until the helpers above existed.
5. `route` describes a layer. It does not blank the page behind it and does not
   trap focus — a dialog still needs `BlockSemantics` and a focus scope, and a
   layer that announces itself while the page underneath stays swipeable is
   still broken.

## Limits

- Automated tests can verify a label exists. They cannot verify it is
  understandable, which needs human review.
- Reading order follows the widget tree.
- Announcement support varies by platform and is reported, not assumed.

## Evidence level

Standard for labelling and for the colour-independence rule. Context dependent
for the announcement policy, which follows Android's own deprecation. Hypothesis
for the 1.3x reflow threshold.

## Sources

- WCAG 2.2 — SC 1.3.1 Info and Relationships, SC 4.1.2 Name, Role, Value,
  SC 1.4.4 Resize Text.
- Android — `View.announceForAccessibility` deprecation notice.
