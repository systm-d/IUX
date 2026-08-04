# Accessibility runtime

## Intention

Give every component one place to ask "what does this user need", so that no
component has to ask `MediaQuery` itself.

A theme records what the *application* requested. The platform records what the
*user* requested. `IuxAccessibility` reconciles the two and is the only place
that reconciliation happens.

```dart
final a11y = IuxAccessibility.of(context);
if (a11y.allowsNonEssentialMotion) { ... }
```

## The reconciliation rule

> The platform can strengthen an accommodation. The application cannot weaken
> one.

| Application asked | Platform reports | In force |
| --- | --- | --- |
| standard contrast | high contrast | **high** |
| high contrast | no preference | **high** |
| `motion: system` | animations disabled | **reduced** |
| `motion: system` | no preference | **standard** |
| `motion: standard` | animations disabled | **reduced** |
| `motion: none` | no preference | **none** |

A user who enabled high contrast system-wide did so for a reason. An
application that requested standard contrast did so without knowing that.
Between the two, the accommodation wins — and the reverse would let a
developer's default silently override an explicit accessibility setting.

The rule is asymmetric on purpose: an application may always ask for *more*
accommodation than the platform reports, because it may know something the
platform does not.

## What it exposes

| Field | Source |
| --- | --- |
| `contrast`, `motion` | reconciled |
| `density`, `touchTarget`, `visualStimulation` | application only — the platform reports nothing |
| `textScaler`, `boldText`, `invertColors` | platform only |
| `screenReaderExpected` | platform hint |

`motion` is never `system` once resolved: the platform has been consulted by
the time an `IuxAccessibility` exists.

## One accessor per value, never `MediaQuery.of`

`IuxAccessibility.of` reads each platform value through its own aspect
accessor — `MediaQuery.textScalerOf`, `MediaQuery.highContrastOf`,
`MediaQuery.disableAnimationsOf`, `MediaQuery.boldTextOf`,
`MediaQuery.invertColorsOf`, `MediaQuery.accessibleNavigationOf`.

The two ways of reading resolve the same six values. They differ in what the
caller is then rebuilt *for*: `MediaQuery.of` registers a dependency on every
aspect of the media query, so everything reading the runtime was rebuilt by the
software keyboard opening, by a notch being reported and by the device
rotating — none of which can change any value here.

Measured on a realistic screen, one frame after the change (`IUX-PERF-001`):

| Change | Through `MediaQuery.of` | One aspect at a time | The same screen in Material |
| --- | --- | --- | --- |
| keyboard opens | 114 | **8** | 14 |
| notch reported | 101 | **8** | 6 |
| device rotates | 130 | **26** | 30 |
| text enlarged | 140 | **140** | 112 |

Text scale is one of the six, so it rebuilds everything that reads it — which
is correct, and is what stops the other three rows being explained by a runtime
that simply stopped reacting. A controlled A/B over 20 identical widgets
differing only in how they read the same six values reports 0 of 20 for the
first three changes and 20 of 20 for the fourth, both ways.

Pinned by `test/performance/rebuild_scope_test.dart`. Nothing resolved changed:
every value, over the full cross of the platform inputs and six application
profiles, is identical before and after.

## Without an IUX theme

Resolution falls back to platform values alone. The runtime stays usable during
incremental adoption, rather than throwing on the first screen that has not
been migrated.

## Rules

1. A component reads `IuxAccessibility`; it never reads `MediaQuery` for a
   preference.
2. `screenReaderExpected` is a hint. Never gate essential behaviour on it — a
   false negative would silently remove that behaviour.
3. `invertColors` is not to be compensated for. The inversion is the user's
   choice, and second-guessing it produces unpredictable results.

## Limits

- The platform reports no density, target-size or visual-stimulation
  preference. IUX offers those as application settings and does not pretend to
  detect them.
- `MediaQuery.highContrast` is not reliably reported on all Android versions.
  Its absence does not mean the user does not want contrast.
- Detection is not testing. TalkBack and the real platform settings still have
  to be exercised on device.

## Evidence level

Standard for the platform fields. Context dependent for the reconciliation
rule, which is an IUX decision documented in ADR-0005.
