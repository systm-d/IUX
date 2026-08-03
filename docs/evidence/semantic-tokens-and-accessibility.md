# Evidence registry — semantic tokens and accessibility

Each entry records a decision, the strength of the evidence behind it, and what
remains unverified. A decision resting on weak evidence is not forbidden;
presenting it as settled would be.

Levels follow `PROJECT_PROMPT.md` §9: `standard`, `strong_guidance`,
`context_dependent`, `hypothesis`, `brand_choice`.

## Entries

### IUX-SEM-001 — Components consume roles, never literal colours

- **Level**: strong_guidance
- **Scope**: IUX-003 onward
- **Sources**: Material Design 3 colour roles; US Web Design System tokens
- **Status**: implemented, enforced by test (`test/iux_flutter_test.dart`)
- **Limits**: enforcement is structural — the barrel exports no primitives —
  not a guarantee that an application will not hardcode a colour of its own.

### IUX-SEM-002 — IUX roles are the source of truth, not `ColorScheme`

- **Level**: context_dependent
- **Scope**: IUX-003.1 onward
- **Sources**: ADR-0002
- **Status**: implemented; the `ColorScheme` mapping is deferred to IUX-004
- **Limits**: an IUX design decision, not an external standard. Its cost is
  that IUX must maintain the mapping.

### IUX-SEM-003 — Interaction states reverse direction by condition

- **Level**: hypothesis
- **Scope**: IUX-003.1 onward
- **Sources**: none external; derived from the contrast measurements
- **Status**: implemented — actions deepen on engagement in light, brighten in
  dark
- **Limits**: adopted because the naive alternative measured 4.12:1 and failed
  the contract. Whether users perceive both directions as equally "engaged"
  has not been tested.

### IUX-A11Y-002 — Body content reaches 4.5:1, interface elements 3:1

- **Level**: standard
- **Scope**: IUX-003.1 onward
- **Sources**: WCAG 2.2 SC 1.4.3 (AA); SC 1.4.11 (AA)
- **Status**: verified for both demonstration mappings
  (`test/semantics/contrast_contracts_test.dart`)
- **Limits**: verified for the shipped mappings only; not a conformance claim
  for any application. WCAG 2.x contrast correlates imperfectly with perceived
  contrast, particularly in dark conditions. APCA is a candidate successor that
  IUX has not adopted.

### IUX-A11Y-003 — Disabled content holds 3:1 despite the WCAG exemption

- **Level**: context_dependent
- **Scope**: IUX-003.1 onward
- **Sources**: WCAG 2.2 SC 1.4.3 exempts inactive controls; IUX exceeds it
- **Status**: implemented; constrained the palette, whose mid neutral was
  calibrated specifically to satisfy it
- **Limits**: a deliberate choice beyond the standard, with a real cost — a
  disabled control is more visually present than convention expects. Not
  validated with users. Reasonable projects disagree here.

### IUX-A11Y-004 — No important state is carried by colour alone

- **Level**: standard
- **Scope**: IUX-003 onward
- **Sources**: WCAG 2.2 SC 1.4.1 (A); Android accessibility guidance
- **Status**: documented as a contract; the catalog includes a single-hue check
- **Limits**: components do not exist yet, so the contract is stated rather
  than enforced on real widgets. Automated checks can verify an icon slot is
  populated; they cannot verify the wording is understandable.

### IUX-A11Y-005 — Focus stays distinct from selection

- **Level**: standard
- **Scope**: IUX-003.1 onward
- **Sources**: WCAG 2.2 SC 2.4.7 Focus Visible; SC 1.4.11
- **Status**: modelled as separate roles and measured
- **Limits**: distinctness is asserted as "a different colour". Whether the
  difference is perceptually obvious needs human review per theme.

### IUX-A11Y-006 — Disabled is a dedicated colour, not an opacity

- **Level**: context_dependent
- **Scope**: IUX-003.1 onward
- **Sources**: derived from SC 1.4.3; no external source prescribes this
- **Status**: implemented — `IuxStateColors` deliberately has no disabled entry
- **Limits**: an IUX decision taken so contrast stays measurable. An opacity
  over an unknown background has no determinate ratio.

### IUX-A11Y-007 — Hierarchy survives without shadows

- **Level**: strong_guidance
- **Scope**: IUX-003.1 onward
- **Sources**: Material Design 3 guidance on surface tint in dark themes
- **Status**: implemented — surface levels separate by colour
- **Limits**: light-condition separation is small (about 1.07:1). It groups
  content; it does not identify a control. Anything requiring identification
  needs a border.

## Deferred to later missions

| Subject | Mission |
| --- | --- |
| Theme engine, `ColorScheme` mapping, high contrast | IUX-004 |
| Runtime accessibility preferences | IUX-005 |
| Motion and reduced-motion policy | IUX-006 |

## Manual validation register

Not yet performed. None of the following is implied by the widget tests, and
none may be claimed until executed on real devices:

- TalkBack reading order and announcements;
- Voice Access target naming;
- physical keyboard and D-pad navigation;
- display scaling and large text;
- platform high-contrast and colour-inversion settings.

Components do not exist yet, so this is a commitment rather than a backlog. It
becomes actionable from IUX-008 onward.
