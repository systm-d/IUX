# Theme preferences and the platform

## The problem

A theme is built statically:

```dart
MaterialApp(theme: IuxTheme.light())
```

At that moment no `BuildContext` exists, so nothing can read `MediaQuery`. Yet
the preferences that matter most — reduced motion, high contrast, text scale —
live exactly there.

## What Flutter exposes

| Preference | Where | Notes |
| --- | --- | --- |
| platform brightness | `MediaQuery.platformBrightness` | handled by `ThemeMode.system` |
| disable animations | `MediaQuery.disableAnimations` | Android "remove animations" |
| high contrast | `MediaQuery.highContrast` | not reported by all Android versions |
| bold text | `MediaQuery.boldText` | |
| text scale | `MediaQuery.textScaler` | applied by Flutter at paint time |
| invert colours | `MediaQuery.invertColors` | |

What Flutter does **not** expose: density preference, target size preference,
visual stimulation preference. IUX offers those as application-level settings
and does not pretend to detect them.

## How IUX divides the work

| Layer | Responsibility |
| --- | --- |
| `ThemeMode.system` | brightness |
| `IuxAccessibilityProfile` | an explicit override, chosen by the app or user |
| the widget layer | reconciling the platform preference at runtime |

`IuxMotionPreference.system` means "not resolved yet". The theme resolves it to
standard motion and sets `IuxMotionTheme.respectsPlatformPreference`, which
records that a widget still has to consult `MediaQuery`.

That reconciliation is IUX-005 and IUX-006. Until then, an application that must
honour the platform setting reads it itself:

```dart
final disableAnimations = MediaQuery.disableAnimationsOf(context);
final theme = IuxTheme.light(
  profile: IuxAccessibilityProfile(
    motion: disableAnimations
        ? IuxMotionPreference.reduced
        : IuxMotionPreference.standard,
  ),
);
```

## Text scaling

Flutter applies the user's scale factor at paint time. IUX does **not** bake it
into the theme — doing so would apply it twice.

## Why not read MediaQuery inside the theme

It is technically possible to build the theme inside a `Builder` and read
`MediaQuery` there. IUX does not, for two reasons: it makes the theme depend on
where it is built, and it hides the platform preference inside resolved values
where a component can no longer tell whether the user asked for something or
the platform did.

Keeping the override explicit means a component can distinguish the two — which
is exactly what `IuxAccessibilityTheme` exists to report.

## Limits

- `MediaQuery.highContrast` is not reliably reported on Android. Do not treat
  its absence as "the user does not want contrast".
- No preference detection replaces testing with TalkBack and with the platform
  accessibility settings actually enabled.

## Evidence level

Standard for what the platform exposes. Context dependent for the division of
responsibility, which is an IUX architectural decision.

## Sources

- Flutter — `MediaQueryData` accessibility fields.
- Android accessibility settings — remove animations, high contrast text,
  display size and font size.
