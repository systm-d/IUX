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
