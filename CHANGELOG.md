# Changelog

## 0.1.0-dev.5 — IUX-005

Accessibility runtime. Additive.

### Added

- `IuxAccessibility.of(context)` — the single place where the application's
  requested profile is reconciled with the platform's reported preferences.
  Closes the gap IUX-004 left explicit via `respectsPlatformPreference`.
- `IuxMotionPolicy` — a component states what an animation is *for*
  (`essential` or `decorative`) and is told whether it runs.
- `IuxTapTarget` — guarantees the interactive floor without enlarging the
  visual element; `minimumSize` can only raise it.
- `IuxFocusRing`, `IuxFocusable`, `IuxFocus` — visible focus that reserves its
  space, keyboard activation, and focus restoration for future overlays.
- `IuxSemantics`, `IuxAnnouncement`, `IuxReadableText`.
- `IuxInterpolation`, extracted from the foundations.

### Changed

- `IuxSemantics.action` takes a nullable `selected`. Passing `false` would
  advertise a selected state on a control that does not toggle.
- The catalog labels each preference chip by dimension *and* value: several
  dimensions share a value, so a chip labelled only "comfortable" was
  ambiguous to a screen reader.

### Notes

`IuxAnnouncement` prefers `IuxSemantics.liveRegion` and says so. Android has
deprecated `announceForAccessibility` because it clears TalkBack's speech
queue, cutting off the user.


## 0.1.0-dev.4 — IUX-004

Accessible theme engine. Additive.

### Added

- `IuxTheme.light()` / `IuxTheme.dark()` returning `ThemeData` directly, with
  an optional `IuxAccessibilityProfile`.
- `IuxThemeConfiguration` (the request) and `IuxResolvedTheme` (the result),
  deliberately separate.
- Four `const` colour mappings: light and dark, each in standard and high
  contrast. **High contrast is now reachable in dark conditions** — the
  previous theme forced `Brightness.light`, leaving users who need both
  without an option.
- Theme extensions `IuxTypographyTheme`, `IuxGeometryTheme`, `IuxMotionTheme`,
  `IuxAccessibilityTheme`.
- `IuxVisualStimulation` and `IuxMotionPreference.standard` in the
  foundations; `IuxAccessibilityProfile` gains `visualStimulation`, equality
  and three named constructors.
- A theme explorer in the catalog covering every profile, text scale and long
  labels.

### Changed

- `ColorScheme` is derived from IUX roles (ADR-0002), and `surfaceTint` is
  disabled: Material 3's elevation tint would move surfaces away from the
  measured values.
- High contrast thickens outlines and the focus ring rather than only
  recolouring them.

### Notes

Two invariants worth knowing: density never reduces the minimum touch target,
and the target never dips below the floor mid-transition. Reduced motion
shortens durations while `none` removes them.

## 0.1.0-dev.3.1 — IUX-003.1

Remediation of the semantic layer. This release is **breaking** for the API
introduced by IUX-003. No published consumer exists (`publish_to: none`).

### Removed

Out-of-scope code that pre-empted later missions, along with its exports:

| Removed | Recreated by |
| --- | --- |
| `IuxButton` | IUX-008.4 |
| `IuxTextField`, `IuxCheckbox`, `IuxSwitch` | IUX-010, IUX-011 |
| overlay placeholders | IUX-016 to IUX-018 |
| `IuxLoadingState`, `IuxErrorState`, `IuxEmptyState` | IUX-028 to IUX-030 |
| `IuxSurface`, `IuxSection` | IUX-007 |
| `IuxActionDescriptor` and action enums | IUX-008.2 |
| `IuxAccessibility` | IUX-005 |
| `IuxFeedback`, `IuxMotionPolicy` | IUX-006 |
| `IuxTheme`, `IuxThemeProfile` | IUX-004 |

`IuxSemanticColors.fromColorScheme` is removed. It inverted the dependency by
placing the source of truth in Material, where IUX cannot verify contrast. See
ADR-0002.

### Changed

- `IuxSemanticColors` becomes a composition of six role groups — `content`,
  `surface`, `border`, `action`, `feedback`, `state` — instead of ten flat
  `Color` fields.
- `IuxSemanticColors.of` now throws a diagnosable `FlutterError` when no IUX
  theme is installed, instead of silently substituting colours derived from the
  ambient `ColorScheme`. `maybeOf` returns null for callers where absence is
  legitimate.

### Fixed

- `IuxSemanticColors.copyWith` accepted only `contentPrimary`, silently
  discarding every other role. It now covers the whole contract, and a
  regression test asserts it.

### Added

- Role groups: `IuxContentColors`, `IuxSurfaceColors`, `IuxBorderColors`,
  `IuxActionColors` / `IuxActionColorSet`, `IuxFeedbackRoleColors` /
  `IuxFeedbackColorSet`, `IuxStateColors` — each with `copyWith`, `lerp`,
  equality and hash code.
- An internal primitive palette, deliberately not exported.
- A contrast measurement helper, confined to `test/`.
- A contrast contract test matrix covering both demonstration mappings.
- A catalog that presents every role group, switches between light and dark
  mappings, and includes a single-hue check for colour-only signalling.
- Documentation: six role documents, contrast contracts, colour and non-colour
  signals, ADR-0002, and an evidence registry.

## 0.1.0-dev.1

- Initialized the IUX repository structure.
- Added the experimental `iux_flutter` package and local catalog integration
  surface.
