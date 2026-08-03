# Reduced motion at runtime

## Intention

Let a component state what an animation is *for*, and get told whether it runs.

```dart
final decision = IuxMotionPolicy.resolve(
  context,
  role: IuxMotionRole.essential,
);
AnimatedOpacity(duration: decision.duration, curve: decision.curve, ...);
```

A component never reads `MediaQuery`, never branches on a preference, and never
decides for itself whether a user's request applies to it. That last part is
how reduced motion normally ends up honoured in some places and quietly
forgotten in others.

## Roles

| Role | Meaning | Under `reduced` | Under `none` |
| --- | --- | --- | --- |
| `essential` | answers what changed, where it went, what to look at | shortened | removed |
| `decorative` | makes the interface feel responsive | removed | removed |

## Why decoration goes first

Decorative motion carries no information, so removing it costs nothing. It is
therefore removed as soon as the user asks for less — including when they asked
only for reduced *visual stimulation* rather than reduced motion.

## Why `none` also removes essential motion

For a user with a vestibular disorder, an essential animation is still an
animation. Offering only "reduced" would force them to accept movement they
cannot tolerate on the grounds that it is useful to someone else.

Removing the travel does not remove the state change. A component must still
make the change perceivable — by content, by a live region, by focus.

## Works without a theme

`IuxMotionPolicy` falls back to the foundation durations when no IUX theme is
installed, so partial adoption does not crash.

## Rules

1. Never animate without asking the policy.
2. `decorative` is the default assumption for anything you cannot justify.
3. A removed animation must not remove the information it carried.

## Limits

- Halving durations under `reduced` is a heuristic, not a measured threshold.
- Parallax, auto-playing content and scroll-linked effects are not covered
  here; they need component-level decisions, from IUX-006 onward.

## Evidence level

Standard for honouring the preference. Hypothesis for the halving factor and
for the essential/decorative split, which is an IUX taxonomy.

## Sources

- WCAG 2.2 — SC 2.3.3 Animation from Interactions.
- Android accessibility — remove animations setting.
