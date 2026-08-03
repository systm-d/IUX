# ADR-0003: Theme engine architecture

- Status: accepted
- Date: 2026-08-03
- Mission: IUX-004

## Context

IUX needs themes for combinable usage conditions: two brightnesses, two
contrast levels, three densities, four motion preferences, two target sizes and
two visual stimulation levels — 192 combinations.

The implementation being replaced offered three named profiles built from
`ColorScheme.fromSeed(seedColor: Colors.indigo)`. It had three defects:

1. a brand seed was hardcoded, contrary to `PROJECT_PROMPT.md` §23;
2. `fromSeed` offers no contrast guarantee, so nothing could be asserted;
3. the `highContrast` profile forced `Brightness.light`, making high contrast
   unreachable in dark conditions.

The third is the one that matters most: it did not merely limit the API, it
removed the option entirely for users who need both.

## Decision

**Separate configuration from resolution, and make every preference an
orthogonal axis rather than a named profile.**

```text
IuxThemeConfiguration → IuxResolvedTheme → ThemeData
```

Concretely:

- `IuxThemeConfiguration` is an immutable request, independent of
  `BuildContext`;
- `IuxResolvedTheme` holds the concrete values, inspectable without building a
  `ThemeData`;
- colours come from four `const` mappings selected by (brightness, contrast);
- five `ThemeExtension`s carry the resolved values;
- `IuxTheme.light()` and `IuxTheme.dark()` return `ThemeData` directly, with an
  optional profile.

## Alternatives considered

**A named constructor per combination.** Rejected: 192 combinations cannot be
named, and any combination nobody named would be unreachable — the exact defect
being fixed.

**Generating palettes from a seed.** Rejected: no contrast guarantee, and it
places the palette's correctness outside anything IUX can test.

**A single monolithic extension.** Rejected: any preference change would
invalidate every value, and the extension would have no coherent
responsibility.

**One extension per concern (seven or more).** Rejected: shape, elevation and
spacing always change together and are always read together. Separate
extensions for them would never be independently useful.

**Reading `MediaQuery` inside the theme.** Rejected: makes the theme depend on
where it is built, and hides the platform preference inside resolved values
where a component can no longer tell whether the user asked for something or
the platform did.

## Consequences

Positive:

- every combination is reachable and tested;
- resolution is a table lookup — nothing is computed per frame;
- resolved values are inspectable without a `ThemeData`;
- contrast is measured for all four mappings.

Negative:

- four `const` mappings must be maintained by hand; adding a role means editing
  four places, and a test enforces that each is complete;
- `IuxMotionPreference.system` cannot be resolved statically and defers to a
  runtime layer that does not exist yet.

## Risks

- **Mapping drift between the four palettes.** Mitigation: the contrast test
  walks all four through the public API, so an incomplete mapping fails.
- **Extension proliferation.** Mitigation: the split is documented by what
  changes each extension; a new extension needs that justification.
- **The unresolved platform preference.** `respectsPlatformPreference` makes
  the gap explicit rather than silent, and IUX-005 closes it.
