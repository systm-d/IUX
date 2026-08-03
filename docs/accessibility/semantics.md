# Semantics

## Intention

Give components one consistent way to describe themselves to assistive
technology.

Hand-built `Semantics` drifts. One component sets `button: true` and forgets
`enabled`; another labels an icon and forgets to exclude the icon's own
semantics, so the screen reader reads the label twice. The result is a library
whose reading order is unpredictable.

## Helpers

| Helper | Use for |
| --- | --- |
| `IuxSemantics.action` | anything activatable |
| `IuxSemantics.header` | a section title a reader can jump to |
| `IuxSemantics.image` | an image, or `label: ''` for decoration |
| `IuxSemantics.liveRegion` | a status that appears in place |
| `IuxSemantics.group` | content that must be read as one unit |
| `IuxSemantics.decorative` | genuinely redundant content |
| `IuxSemantics.disabled` | an unavailable control |

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

## Rules

1. An icon-only control always has a label.
2. `decorative` is only for content that genuinely repeats something adjacent.
   Hiding anything else removes it from the interface for part of the users.
3. Reserve `assertive` announcements for what the user must know now.
   Interrupting for less trains users to turn announcements off.

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
