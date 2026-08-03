# Motion roles

## Intention

A component names what an animation is *for*. The policy decides duration,
easing, and whether it runs.

Naming intent rather than timing is what lets a reduced-motion preference be
applied once, correctly — instead of being re-decided in every component, which
is how it ends up honoured in nine places out of ten.

```dart
final motion = IuxMotionPolicy.resolve(context, role: IuxMotionRole.reveal);

if (motion.prefersFade) return FadeTransition(...);
return SizeTransition(...);
```

## The roles

| Role | Answers | Under reduced motion |
| --- | --- | --- |
| `stateChange` | what just changed | shorten |
| `enter` | where did this come from | shorten |
| `exit` | where did it go | shorten |
| `reveal` | what opened | **simplify** |
| `conceal` | what closed | **simplify** |
| `reposition` | where did it move to | **simplify** |
| `progress` | is work happening | **preserve** |
| `emphasis` | look here | **remove** |

If a movement matches no role, it is almost certainly decoration.

## Why travel is simplified rather than shortened

`reposition`, `reveal` and `conceal` become a fade instead of a faster
movement.

A fast large movement is *worse* than a slow one for a user prone to motion
discomfort, not better. Shortening is the wrong adaptation for travel; removing
the travel while keeping the transition legible is the right one.

## Why progress is preserved

Removing a progress indicator hides that work is happening, which is worse than
the motion itself. It is preserved under `reduced`.

Under `none` it is removed like everything else — and the component must then
substitute a static indicator: a percentage, a count, a status line.
`IuxResolvedMotion.requiresStaticAlternative` signals exactly that.

## Why emphasis is suspect

`emphasis` is the only decorative role, and it is removed the moment any
reduction is requested. It is worth questioning even when none is: if an
element needs to move to be noticed, its placement or its wording is usually
the real problem.

## Rules

1. Never animate without asking the policy.
2. Removing an animation must never remove the information it carried.
3. `emphasis` is the default assumption for anything you cannot justify.

## Limits

- Halving durations under `reduced` is a heuristic, not a measured threshold.
- Parallax, auto-playing media and scroll-linked effects are not modelled here.
- The policy decides *whether* and *how long*. Building the fade or the
  transition remains the component's job.

## Evidence level

Standard for honouring the preference. Hypothesis for the role taxonomy and
for simplify-versus-shorten, which are IUX judgements.

## Sources

- WCAG 2.2 — SC 2.3.3 Animation from Interactions.
- Android accessibility — remove animations setting.
