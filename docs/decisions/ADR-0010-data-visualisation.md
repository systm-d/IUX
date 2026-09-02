# ADR-0010: IUX draws charts

- Status: accepted
- Date: 2026-08-05
- Mission: IUX-043

## Context

The README says IUX is "not a visual design system", and MISSION_042 §5 rules
out any "abstraction universelle de rendu". Read strictly, a chart component is
outside the framework's stated scope, and until now IUX contained no
`CustomPainter` at all.

The first two applications built on IUX then both needed one. A chart is where
an accessibility framework is tested hardest: it is the component most often
shipped having been looked at once, at 100% text, in light mode, by somebody who
could see it.

## Decision

IUX ships three chart primitives — `IuxLineChart`, `IuxBarChart`,
`IuxSparkline` — resolved from the existing layers, with a required text
alternative.

## Why not leave them to the application

Because the failure mode is silent. An application that paints its own chart
gets one that works, looks right, and is invisible to a screen reader — and
nothing about the code says so. The rule that would have prevented it lives in
this framework, not in the application, and a rule that cannot be enforced where
it is written is a rule that will be broken where it is not.

Making `semanticsSummary` a required parameter is the whole argument in one
line: the chart does not compile without its alternative.

## What this is not

It is not a rendering abstraction. There is no plot engine, no scale inference,
no chart-type enum, no plugin surface. Three widgets, one geometry file, and a
vocabulary of values. A fourth chart type would be a fourth widget, argued for
on its own.

It is not interactive, and the boundary is deliberate. Hover, tooltips and point
selection bring focus order, keyboard traversal and target sizes with them, and
those are a mission rather than a parameter.

## Consequences

- IUX now owns painting code, and `lib/src/components/chart/` is the first place
  in the package where a `Canvas` appears. The Component Standard's mechanical
  rules apply to it unchanged, and did: the arity cap, the composed-strings
  ban, the dead-token scan and the sorted barrel all held without exception.
- A chart carries at most three series, because there are three stroke patterns
  and colour may not carry the distinction alone. This is a cap the framework
  imposes on applications, which is unusual and intended.
- `IuxBarChart` has no vertical arrangement. An application that wants columns
  cannot get them from IUX.
- The package gains no dependency.

## Alternatives considered

**Wrapping an existing chart package.** Rejected: every candidate exposes
colours directly, which forfeits the contrast guarantee the theme is responsible
for, and none makes a text alternative mandatory.

**Leaving charts to each application.** Rejected above.

**A generic `IuxChart` with a type enum.** Rejected: the three have different
data shapes, different axes and different accessibility structures. One class
switching on an enum would be three components sharing a constructor, and the
Component Standard §8 says so directly.
