# Visual stimulation

## Intention

Reduce non-essential visual activity for users who find a busy interface
tiring, without reducing what the interface communicates.

```dart
IuxTheme.light(
  profile: const IuxAccessibilityProfile(
    visualStimulation: IuxVisualStimulation.reduced,
  ),
)
```

## What reduced stimulation changes

| Aspect | Standard | Reduced |
| --- | --- | --- |
| raised elevation | 1 | 0 |
| modal elevation | 6 | 0 |
| decorative motion | allowed | suppressed |
| colours | unchanged | unchanged |
| contrast | unchanged | unchanged |
| type sizes | unchanged | unchanged |

Flattening elevation is safe precisely because IUX never relied on shadows for
hierarchy: surfaces already separate by colour, and borders already identify
controls. Removing the shadow removes decoration, not information.

## What it must never do

**It must not reduce legibility.** Contrast, type size and colour roles are
untouched, and a test asserts that the resolved colours are identical to the
standard ones.

A "calmer" theme that is harder to read has not helped anyone.

## An honest limit

This is a comfort setting. It is **not** an accommodation for any specific
condition, and IUX does not claim it is.

There is deliberately no `IuxAccessibilityProfile.adhd()` or `.autism()`.
Naming a preference after a diagnosis asserts both that a population shares a
single need and that this setting meets it — neither of which IUX can support.
A user who wants a calmer interface asks for a calmer interface.

The concept has not been validated with users. Treat it as a hypothesis.

## Evidence level

Hypothesis. No standard defines this preference, and the specific effects are
an IUX judgement.

## Sources

None directly. Related: WCAG 2.2 SC 2.3.3 Animation from Interactions covers
the motion component only.
