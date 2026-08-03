# Theme engine

## Intention

Let an application offer light, dark, reinforced contrast, adjustable density,
reduced motion, larger targets and reduced visual activity — without writing
a second theme and without a component knowing any of it exists.

## The common case

```dart
MaterialApp(
  theme: IuxTheme.light(),
  darkTheme: IuxTheme.dark(),
  themeMode: ThemeMode.system,
)
```

## Adding preferences

```dart
IuxTheme.dark(
  profile: const IuxAccessibilityProfile(
    contrast: IuxContrast.high,
    density: IuxDensity.comfortable,
    motion: IuxMotionPreference.reduced,
  ),
)
```

Every preference is orthogonal. Any combination is valid, and none implies
another: high contrast does not force reduced motion, comfortable density does
not force larger targets.

## Configuration and resolution are separate

```text
IuxThemeConfiguration     what was asked for
        ↓
IuxResolvedTheme          what came out
        ↓
ThemeData                 what Flutter consumes
```

A configuration is a request that can be stored, compared and passed around
without carrying a `ThemeData`. A resolved theme is the concrete values that
request produced. Keeping them apart makes clear which values a developer
chose and which IUX derived.

```dart
final resolved = IuxTheme.resolve(configuration);
resolved.geometry.minimumTouchTarget;  // inspect without building a theme
resolved.material;                     // hand to MaterialApp
```

## No named constructor per combination

There is no `highContrastLight()` or `highContrastDark()`. Four preferences
with two to four values each would need dozens of named constructors, and any
combination nobody thought to name would be unreachable.

That is not hypothetical: the theme this engine replaces offered a
`highContrast` profile that silently forced light conditions, so a user needing
both a dark interface and reinforced contrast had no option at all.

## Extensions

Five, split by what changes them and who reads them.

| Extension | Carries | Changed by |
| --- | --- | --- |
| `IuxSemanticColors` | colour roles | brightness, contrast |
| `IuxTypographyTheme` | text styles per role | font family override |
| `IuxGeometryTheme` | spacing, targets, shape, elevation, focus | density, target size, contrast, stimulation |
| `IuxMotionTheme` | durations, curves, motion permissions | motion, stimulation |
| `IuxAccessibilityTheme` | the conditions requested | the profile |

Spacing, shape and elevation share one extension because they are read together
and change together. Splitting them would produce extensions that are never
independently useful; merging them with colour would rebuild every measurement
whenever contrast changed.

`IuxAccessibilityTheme` exists because the others cannot answer "what was
asked for". Once colours are resolved, nothing in them records whether high
contrast was requested or the theme merely happens to be dark — and a component
deciding whether to add a non-colour indicator needs to know.

## Resolution from context

One accessor per extension, consistently:

```dart
IuxSemanticColors.of(context)
IuxTypographyTheme.of(context)
IuxGeometryTheme.of(context)
IuxMotionTheme.of(context)
IuxAccessibilityTheme.of(context)
```

There is no `context.iuxTheme` shortcut. One approach applied consistently is
easier to learn than two partial ones.

A missing extension throws a diagnosable `FlutterError`. A silent fallback
would render a plausible but unverified interface and hide the
misconfiguration until it reached a user.

## Limits

- A theme is built statically and cannot read `MediaQuery`. Platform
  preferences are reconciled by the widget layer, delivered by IUX-005 and
  IUX-006. See [../accessibility/theme-preferences.md](../accessibility/theme-preferences.md).
- Material component themes are configured only where a gap would be visible
  today. Buttons, chips, cards and navigation belong to later missions.
- The contrast guarantees hold for the four shipped mappings. A theme supplied
  by an application is the application's responsibility.

## Evidence level

Strong guidance for the architecture. Standard for the contrast contracts.
See [../evidence/semantic-tokens-and-accessibility.md](../evidence/semantic-tokens-and-accessibility.md).
