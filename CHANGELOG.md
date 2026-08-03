# Changelog

## 0.1.0-dev.9 — IUX-010, 011, 014, 015, 016, 017, 019, 020, 021, 022

Ten components, plus the runtime helpers four of them needed.

### Added

- Text field, selection controls, inline alerts, transient messages, dialog,
  bottom sheet, card, list items, badges/chips/status, icons/avatars/images.
- `IuxSemantics.selection`, `.radioGroup`, `.field`, `.route`,
  `.contentAction`, `.contentContainer` — the helpers whose absence had forced
  four components to compose a bare `Semantics` and declare a deviation. All
  four deviations are now closed.
- `IuxInsets.keyboard` and `IuxInsets.windowHeight`. A view inset is a
  measurement, not a preference, so it belongs in the layout layer — and with
  it there, the bottom sheet needs no exception to the standard either.
- `IuxModalLayer` gains a `sheet` slot, with an assertion refusing a dialog and
  a sheet at once.

### Fixed

- **Every button was unusable with a screen reader.** `IuxSemantics.action`
  sets `excludeSemantics` to control the announced name, which also deleted
  the child gesture detector's tap action. Nodes announced a button and
  offered nothing to activate. Present since IUX-005; verified by probe
  (`actions: 0` → `1`) and locked by two regression tests.

### Known open

- `IUX-OVERLAY-001`: opening a modal resets the page's scroll position,
  measured at 400 → 0. The one-line fix breaks a working accessibility
  guarantee, so it stays open. See the evidence registry.


## 0.1.0-dev.8 — IUX-008.1 to IUX-008.3

Component standard, action model, button theme. Additive.

### Added

- The operative Component Standard, with nine of its prohibitions enforced by
  `test/components/component_standard_test.dart` rather than only written
  down.
- `IuxActionDescriptor` and its ten orthogonal dimensions;
  `IuxActionPolicy.evaluate`, which decides activation once and returns *why*
  a refusal happened.
- `IuxButtonTheme`, `IuxButtonTokens`, `IuxButtonResolver`,
  `IuxButtonStateResolver` — a seventh theme extension.

### Notes

The button contrast test caught `outlined` + `secondary` resolving to a white
label on a white surface (1.00:1). An intent's accent is not always in the
same role: primary and destructive carry it in `background`, secondary and
tertiary in `foreground`, because the semantic layer already models the latter
as unfilled. 152 variant × intent × state × profile combinations are now
measured.

Focus is deliberately not a button state: it must stay visible while pressed,
loading and showing a result.


## 0.1.0-dev.7 — IUX-007

Layout primitives. Additive.

### Added

- `IuxPage`, which composes with `Scaffold` rather than replacing it. Scrolls
  by default, because a screen that does not scroll breaks the moment text is
  enlarged or a keyboard appears.
- `IuxPageInsets`, four explicit safe-area modes. A boolean cannot express
  which edges a nested element already consumed, which is how double padding
  happens.
- `IuxSurface`, `IuxSection`, `IuxSectionHeader` — a section title is exposed
  as a screen-reader landmark, so the grouping exists for someone who cannot
  see the spacing that expresses it.
- `IuxTargetSpacing` and `kIuxMinimumTargetSpacing`, closing the gap IUX-005
  deferred: two touching 48-pixel targets still produce mis-taps.
- `IuxContentWidth` / `IuxReadableWidth`, with caps measured in characters and
  converted at the text size in force. A fixed pixel cap halves the characters
  per line when a user doubles their text.
- `IuxGap`, `IuxInsets`, `IuxLayoutClass`, `IuxBreakpoints`,
  `IuxResponsiveValue`.

### Notes

Control groups use `Wrap`, not `Row`: at a large text scale a row stops
fitting, and wrapping beats clipping a label the user cannot then read. A full
composition is tested at 320×480 with a 2x text scale.


## 0.1.0-dev.6 — IUX-006

Motion and feedback engine. **Breaking** for the minimal motion policy
introduced in IUX-005.

### Changed

- `IuxMotionRole` replaces `{essential, decorative}` with eight intent roles,
  each declaring how it adapts: shorten, simplify, preserve or remove.
  `reposition`, `reveal` and `conceal` become a fade rather than a faster
  movement — a fast large movement is worse than a slow one for a user prone
  to motion discomfort, not better.
- `IuxMotionPolicy.resolve` returns `IuxResolvedMotion` (was
  `IuxMotionDecision`), adding `behavior`, `prefersFade` and
  `requiresStaticAlternative`.
- Motion moved from `src/accessibility/` to `src/motion/`.

### Added

- `IuxFeedbackEvent` with named constructors, emitted explicitly by the
  parent. The runtime never infers that something succeeded or failed.
- `IuxFeedbackScope` / `IuxFeedbackController`, scoped rather than a global
  singleton, returning an `IuxFeedbackOutcome` per emission.
- `IuxHapticPolicy` mapping roles to patterns; `progress` never vibrates.
- `IuxFeedbackTheme`, a sixth theme extension, controlling channel
  permissions and the deduplication window.

### Notes

Only `error` and `destructive` interrupt a screen reader. Interrupting for a
success trains users to turn announcements off, at which point failures stop
being heard too.


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
