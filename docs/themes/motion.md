# Motion

## Intention

Motion answers a question — what just happened, where did that go, what should
I look at. Motion that answers nothing is decoration, and decoration is what a
reduced-motion preference removes first.

## Preferences

| Preference | Meaning |
| --- | --- |
| `system` | defer to the platform, read from `MediaQuery` |
| `standard` | full motion regardless of the platform |
| `reduced` | essential transitions only, halved |
| `none` | no motion; state changes are instant |

## Why `reduced` and `none` both exist

`reduced` keeps the transitions that carry meaning and shortens them. `none`
removes even those.

The distinction is real: for a user with a vestibular disorder, an essential
animation is still an animation. Offering only "reduced" would force that user
to accept motion they cannot tolerate, on the grounds that it is useful.

## What a component must check

```dart
final motion = IuxMotionTheme.of(context);

if (motion.allowsNonEssentialMotion) {
  // decorative movement is permitted
}

// Meaningful transitions use the resolved durations, which are already
// shortened when the user asked for less.
AnimatedContainer(duration: motion.standard, curve: motion.change);
```

`allowsNonEssentialMotion` is false as soon as motion *or* visual stimulation
is reduced.

## Curves

Reduced motion also simplifies easing to linear. An emphasised curve draws
attention to the movement itself, which is the opposite of the intent.

## The platform preference

A theme is built statically, before any context exists, so it cannot read
`MediaQuery.disableAnimations`. With `IuxMotionPreference.system` the theme
resolves to standard motion and sets `respectsPlatformPreference`, recording
that a widget still has to consult the platform.

Reconciling the two is IUX-005 and IUX-006. Until then, an application that
must honour the platform setting reads it itself and passes an explicit
preference.

## Limits

- Halving a duration is a heuristic, not a measured threshold.
- `Duration.zero` removes travel but not the state change itself; a component
  must still make the change perceivable by other means.

## Evidence level

Standard for honouring a reduced-motion preference. Hypothesis for the halving
factor and for the linear easing substitution.

## Sources

- WCAG 2.2 — SC 2.3.3 Animation from Interactions.
- Android accessibility — remove animations setting.
