# ADR-0005: Accessibility runtime

- Status: accepted
- Date: 2026-08-03
- Mission: IUX-005

## Context

IUX-004 delivered themes that resolve statically. A static theme cannot read
`MediaQuery`, so the platform's accessibility settings were left unresolved and
`IuxMotionTheme.respectsPlatformPreference` recorded the gap.

Something has to reconcile the application's request with the platform's. The
question is where, and who wins.

## Decision

**One runtime object reconciles both, and the platform can strengthen an
accommodation while the application cannot weaken one.**

```dart
final a11y = IuxAccessibility.of(context);
```

Components read this. No component reads `MediaQuery` for a preference.

Alongside it, four services remove the need for each component to reimplement
the same mechanics: `IuxMotionPolicy` (should this animate), `IuxTapTarget`
(is this hittable), `IuxFocusRing` / `IuxFocusable` (is focus visible),
`IuxSemantics` / `IuxAnnouncement` (how is this described).

## Why the asymmetry

A user who enabled high contrast system-wide did so for a reason. An
application that requested standard contrast did so without knowing that.
Letting the application win would mean a developer's default silently
overriding an explicit accessibility setting — which is the failure mode the
setting exists to prevent.

The reverse direction stays open: an application may ask for *more*
accommodation than the platform reports, because it may know something the
platform does not.

## Alternatives considered

**Each component reads `MediaQuery`.** Rejected: the reconciliation rule would
be reimplemented per component and would diverge. Reduced motion honoured in
nine components out of ten is not honoured.

**Resolve preferences into the theme.** Rejected: a theme is built before any
context exists. Building it inside a `Builder` would make it depend on where it
is built, and would hide whether the user or the application asked for
something — a distinction components need.

**An `InheritedWidget` holding the runtime state.** Rejected as unnecessary:
`IuxAccessibility.of` already depends on `Theme` and `MediaQuery`, both of
which are inherited, so rebuilds propagate correctly without a third mechanism.

**Application preference wins over platform.** Rejected on the grounds above.

## Consequences

Positive:

- one reconciliation, tested once;
- components state intent (`IuxMotionRole.decorative`) rather than reading
  settings;
- the touch-target floor cannot be opted out of;
- partial adoption works — everything falls back to platform values.

Negative:

- `IuxAccessibility.of` reads two inherited widgets, so it rebuilds on either;
- an application that genuinely needs to render with less contrast than the
  platform requests has no way to do so. That is intended.

## Risks

- **A component bypassing the runtime.** Mitigation: documented rule; a lint
  rule is a candidate for IUX Phase 5.
- **Announcement behaviour varying by platform.** Mitigation:
  `IuxAnnouncement` reports whether delivery happened, and the documentation
  directs callers to live regions first, following Android's own deprecation
  of `announceForAccessibility`.
- **The 1.3x reflow threshold being wrong.** Recorded as a hypothesis in the
  evidence registry.
