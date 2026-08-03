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
- **Status**: implemented; the `ColorScheme` mapping landed with IUX-004
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
- **Status**: verified for all four shipped mappings
  (`test/themes/theme_contrast_test.dart`)
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

### IUX-THEME-001 — High contrast combines with both brightnesses

- **Level**: standard
- **Scope**: IUX-004 onward
- **Sources**: WCAG 2.2 SC 1.4.3, SC 1.4.11
- **Status**: implemented; four mappings measured through the public API
  (`test/themes/theme_contrast_test.dart`)
- **Limits**: fixes a real defect — the previous engine forced light
  conditions under high contrast, leaving users who need both without an
  option. Verified for the shipped mappings only.

### IUX-THEME-002 — High contrast reinforces selectively, not uniformly

- **Level**: context_dependent
- **Scope**: IUX-004 onward
- **Sources**: none external; an IUX judgement
- **Status**: implemented — content, identifying borders, focus and engagement
  states are reinforced; decorative separators are not
- **Limits**: raising every value would flatten emphasis, since emphasis is
  relative. Which aspects deserve reinforcement has not been user-tested.

### IUX-THEME-003 — Outlines and focus gain thickness under high contrast

- **Level**: strong_guidance
- **Scope**: IUX-004 onward
- **Sources**: WCAG 2.2 SC 2.4.7 Focus Visible
- **Status**: implemented — border 1→2, strong border 2→3, focus ring 2→3
- **Limits**: the specific widths are an IUX choice, not a standard.

### IUX-THEME-004 — Density never reduces the minimum touch target

- **Level**: standard
- **Scope**: IUX-004 onward
- **Sources**: Android accessibility (48dp); WCAG 2.2 SC 2.5.8
- **Status**: implemented and asserted at every density
- **Limits**: the floor is a minimum, not a recommendation. Spacing between
  targets is a separate concern, deferred to IUX-007.

### IUX-THEME-005 — The touch target never dips below the floor mid-transition

- **Level**: context_dependent
- **Scope**: IUX-004 onward
- **Sources**: derived from SC 2.5.8
- **Status**: implemented — `IuxGeometryTheme.lerp` holds the larger endpoint
  and lands exactly at the bounds
- **Limits**: an IUX decision. A linearly interpolated target is briefly
  smaller than either theme intended, and an animation is exactly when a user
  is likely to be reaching for something.

### IUX-THEME-006 — Reduced motion shortens; no motion removes

- **Level**: standard for honouring the preference, hypothesis for the factor
- **Scope**: IUX-004 onward
- **Sources**: WCAG 2.2 SC 2.3.3; Android "remove animations"
- **Status**: implemented — durations halved under `reduced`, zeroed under
  `none`, easing simplified to linear
- **Limits**: the 0.5 factor is a heuristic, not a measured threshold. The two
  levels are separate because for a user with a vestibular disorder an
  essential animation is still an animation.

### IUX-THEME-007 — The platform motion preference is deferred, not guessed

- **Level**: context_dependent
- **Scope**: IUX-004 onward
- **Sources**: Flutter `MediaQueryData.disableAnimations`
- **Status**: implemented — `respectsPlatformPreference` records that a widget
  must still consult the platform
- **Limits**: a static theme cannot read `MediaQuery`. The gap is explicit
  rather than silent, and IUX-005 closes it. Until then an application that
  must honour the setting reads it itself.

### IUX-THEME-008 — The Material surface tint is disabled

- **Level**: context_dependent
- **Scope**: IUX-004 onward
- **Sources**: Material Design 3 surface tint behaviour
- **Status**: implemented — `surfaceTint` is fully transparent
- **Limits**: Material 3 tints a surface as elevation rises, which would move
  surfaces away from the measured values. The cost is that IUX diverges from
  default Material appearance.

### IUX-THEME-009 — Reduced visual stimulation never reduces legibility

- **Level**: hypothesis
- **Scope**: IUX-004 onward
- **Sources**: none; no standard defines this preference
- **Status**: implemented — elevation flattened and decorative motion
  suppressed; colours, contrast and type sizes asserted identical to standard
- **Limits**: a comfort setting, explicitly not an accommodation for any
  condition. Not validated with users. Treat as a hypothesis.

### IUX-THEME-010 — No preference is named after a population or diagnosis

- **Level**: context_dependent
- **Scope**: IUX-004 onward
- **Sources**: ADR-0004
- **Status**: implemented — named constructors describe what they set
  (`comfortable`, `reducedMotion`), never who they are for
- **Limits**: an IUX governance decision. Naming a preference after a
  diagnosis would assert that a population shares one interface need, and
  would invite an application to infer a diagnosis from a settings choice.

### IUX-RUNTIME-001 — The platform may strengthen an accommodation; the application may not weaken one

- **Level**: context_dependent
- **Scope**: IUX-005 onward
- **Sources**: ADR-0005; no external standard prescribes the precedence
- **Status**: implemented and tested
  (`test/accessibility/iux_accessibility_test.dart`)
- **Limits**: an IUX decision. Its consequence is that an application which
  genuinely needs less contrast than the platform reports has no way to ask
  for it. That is intended, but it is a real constraint.

### IUX-RUNTIME-002 — Components read the runtime, never `MediaQuery`

- **Level**: context_dependent
- **Scope**: IUX-005 onward
- **Sources**: ADR-0005
- **Status**: implemented; no lint enforces it yet
- **Limits**: structural convention only. A component can still bypass it; a
  lint rule is a candidate for Phase 5.

### IUX-RUNTIME-003 — Live regions are preferred to announcements

- **Level**: standard
- **Scope**: IUX-005 onward
- **Sources**: Android deprecation of `View.announceForAccessibility`, cited in
  Flutter's own `SemanticsService` documentation
- **Status**: implemented — `IuxAnnouncement` checks platform support, reports
  whether delivery happened, and its documentation directs callers to
  `IuxSemantics.liveRegion` first
- **Limits**: announcements interrupt TalkBack by clearing its speech queue.
  Support varies by platform, so essential information must never depend on
  one.

### IUX-RUNTIME-004 — The focus ring reserves its space whether or not it is drawn

- **Level**: strong_guidance
- **Scope**: IUX-005 onward
- **Sources**: WCAG 2.2 SC 2.4.7, SC 2.4.11 Focus Not Obscured
- **Status**: implemented and tested — the element does not move on focus
- **Limits**: costs padding around every focusable element even when unfocused.
  The alternative shifts the layout on every focus change, which is worse under
  magnification.

### IUX-RUNTIME-005 — The touch-target floor cannot be opted out of

- **Level**: standard
- **Scope**: IUX-005 onward
- **Sources**: Android 48dp; WCAG 2.2 SC 2.5.8
- **Status**: implemented — `IuxTapTarget.minimumSize` combines with the
  resolved floor using the larger value
- **Limits**: covers target size only. Spacing between adjacent targets is a
  separate cause of mis-taps and belongs to IUX-007.

### IUX-RUNTIME-006 — Enlarged text is reflowed, never truncated

- **Level**: hypothesis for the threshold, standard for the principle
- **Scope**: IUX-005 onward
- **Sources**: WCAG 2.2 SC 1.4.4 Resize Text
- **Status**: implemented — above roughly 1.3x, `IuxReadableText` drops the
  line limit and switches overflow to visible
- **Limits**: the 1.3x threshold is a heuristic chosen from common phone
  widths, not a measured value. Truncating enlarged text defeats the reason
  the user enlarged it, but where exactly to switch has not been tested.

### IUX-RUNTIME-007 — A non-toggling control does not advertise a selected state

- **Level**: standard
- **Scope**: IUX-005 onward
- **Sources**: WCAG 2.2 SC 4.1.2 Name, Role, Value
- **Status**: implemented — `IuxSemantics.action` takes a nullable `selected`
- **Limits**: passing `false` would announce a plain button as "not selected",
  inviting the user to look for a selection that does not exist.

### IUX-MOTION-001 — Travel is simplified to a fade, not shortened

- **Level**: hypothesis
- **Scope**: IUX-006 onward
- **Sources**: none external; derived from vestibular-discomfort guidance that
  large movement is the trigger
- **Status**: implemented — `reposition`, `reveal` and `conceal` resolve to
  `simplify`; only in-place roles shorten
- **Limits**: a faster large movement is plausibly worse than a slow one, but
  IUX has not tested this with affected users. The taxonomy is an IUX
  judgement.

### IUX-MOTION-002 — Progress motion is preserved under reduced motion

- **Level**: context_dependent
- **Scope**: IUX-006 onward
- **Sources**: WCAG 2.2 SC 2.3.3 exempts motion essential to functionality
- **Status**: implemented; removed only under `none`, where
  `requiresStaticAlternative` obliges the component to substitute a static
  indicator
- **Limits**: removing a progress indicator hides that work is happening,
  which is worse than the motion. Under `none` the burden moves to the
  component, and nothing yet enforces that it complies.

### IUX-FEEDBACK-001 — The parent owns feedback truth

- **Level**: context_dependent
- **Scope**: IUX-006 onward
- **Sources**: ADR-0006; PROJECT_PROMPT §52 (never mask a critical error)
- **Status**: implemented — no inference, no `onSuccess` hook anywhere
- **Limits**: an IUX decision. It makes callers do more work, deliberately: a
  framework that guesses will eventually announce a success that did not
  happen.

### IUX-FEEDBACK-002 — Intensity is proportionate, and only failures interrupt

- **Level**: strong_guidance
- **Scope**: IUX-006 onward
- **Sources**: Nielsen Norman Group on notification fatigue; Android
  announcement deprecation
- **Status**: implemented and tested — only `error` and `destructive` use an
  assertive announcement
- **Limits**: the role-to-intensity mapping is an IUX judgement, not a
  measured one. Interrupting for a success trains users to disable
  announcements, at which point failures stop being heard too.

### IUX-FEEDBACK-003 — Progress never produces haptics

- **Level**: standard
- **Scope**: IUX-006 onward
- **Sources**: derived from the prohibition on continuous vibration
- **Status**: implemented and tested
- **Limits**: an ongoing operation would mean repeated vibration.

### IUX-FEEDBACK-004 — No channel is guaranteed, so none may be the only signal

- **Level**: standard
- **Scope**: IUX-006 onward
- **Sources**: WCAG 2.2 SC 1.4.1; Flutter reports no platform haptic setting
- **Status**: implemented — `emit` returns per-channel outcomes and
  `anyChannelResponded` may legitimately be false
- **Limits**: a performed haptic may be felt by nobody, and announcements are
  unsupported on some platforms. The visual state must always carry the
  information alone.

### IUX-FEEDBACK-005 — Identical events within a short window are deduplicated

- **Level**: hypothesis
- **Scope**: IUX-006 onward
- **Sources**: none; the window is a chosen default
- **Status**: implemented as a single last-event check, configurable through
  `IuxFeedbackTheme`
- **Limits**: 600 ms is a guess — long enough to absorb a double emission,
  short enough that a genuine retry registers. Not validated.

### IUX-FEEDBACK-006 — The engine holds no user-facing strings

- **Level**: standard
- **Scope**: IUX-006 onward
- **Sources**: PROJECT_PROMPT §23; internationalisation practice
- **Status**: implemented — `semanticMessage` arrives already localised
- **Limits**: shipping English defaults would make the omission invisible in
  every other language.

### IUX-LAYOUT-001 — Adjacent interactive elements keep a minimum separation

- **Level**: standard
- **Scope**: IUX-007 onward
- **Sources**: WCAG 2.2 SC 2.5.8, which allows smaller targets when spacing
  compensates
- **Status**: implemented as `IuxTargetSpacing`, which raises any smaller
  request to the floor; tested
- **Limits**: closes the gap IUX-005 deferred. 8 logical pixels is a chosen
  default, not a measured optimum. Target size alone does not prevent
  mis-taps: two touching 48-pixel targets still produce them.

### IUX-LAYOUT-002 — Reading width is measured in characters, not pixels

- **Level**: hypothesis for the counts, strong guidance for the principle
- **Scope**: IUX-007 onward
- **Sources**: long-standing typographic guidance on 60–75 characters per line
- **Status**: implemented — caps convert at the text size in force
- **Limits**: a fixed pixel cap halves the characters per line when text
  doubles. The character-to-pixel conversion assumes a proportional Latin face
  and is deliberately generous; it will be wrong for CJK and monospace.

### IUX-LAYOUT-003 — Control groups wrap rather than clip

- **Level**: standard
- **Scope**: IUX-007 onward
- **Sources**: WCAG 2.2 SC 1.4.4 Resize Text, SC 1.4.10 Reflow
- **Status**: implemented — `IuxTargetSpacing` and `IuxSectionHeader` use
  `Wrap`; tested at 320×480 with a 2x text scale
- **Limits**: `Wrap` cannot express "these two must stay on one line", which
  some designs will want.

### IUX-LAYOUT-004 — Safe areas are consumed per edge, never blanket-applied

- **Level**: context_dependent
- **Scope**: IUX-007 onward
- **Sources**: ADR-0007
- **Status**: implemented as four explicit modes
- **Limits**: prevents double padding, where a page and a nested sheet both
  inset from a notch that exists once. Nesting is documented but not detected.

### IUX-LAYOUT-005 — Layout classes are measured from available width

- **Level**: standard
- **Scope**: IUX-007 onward
- **Sources**: Android window size classes
- **Status**: implemented — three classes at 600 and 840
- **Limits**: a split-screen window on a tablet is compact. Measuring from the
  physical screen instead is the classic way to ship an unusable multi-window
  experience.

### IUX-LAYOUT-006 — No universal thumb-zone rule

- **Level**: context_dependent
- **Scope**: IUX-007 onward
- **Sources**: none prescriptive; reach varies by hand size, grip and device
- **Status**: deliberately not implemented. `IuxPage.footer` lets a screen
  keep a primary action reachable without scrolling; whether to use it is the
  screen's decision.
- **Limits**: a framework-level reach rule would be wrong for most users.

### IUX-BUTTON-001 — An intent's accent is not always in the same role

- **Level**: context_dependent
- **Scope**: IUX-008.3 onward
- **Sources**: none external; found by measurement
- **Status**: implemented — primary and destructive carry their accent in
  `background`, secondary and tertiary in `foreground`
- **Limits**: assuming one universally produced a white label on a white
  surface (1.00:1), caught by the contrast test rather than by review. This is
  an explicit assumption about the shipped palettes; a brand theme that fills
  secondary must revisit it. Guarded by 152 measured combinations.

### IUX-BUTTON-002 — Focus is not a button state

- **Level**: standard
- **Scope**: IUX-008.3 onward
- **Sources**: WCAG 2.2 SC 2.4.7 Focus Visible
- **Status**: implemented — carried separately from the state enum and drawn
  additively
- **Limits**: focus must stay visible while pressed, loading and showing a
  result, so it cannot be a value in a list where one wins.

### IUX-BUTTON-003 — The tonal variant refuses a destructive intent

- **Level**: context_dependent
- **Scope**: IUX-008.3 onward
- **Sources**: none external; an IUX judgement
- **Status**: implemented as an assertion
- **Limits**: tonal carries intent through its border rather than its fill,
  because the semantic layer has no per-intent container role. Adding one
  would remove the restriction; deferred.

### IUX-INPUT-001 — A placeholder uses secondary content, not tertiary

- **Level**: standard
- **Scope**: IUX-009 onward
- **Sources**: WCAG 2.2 SC 1.4.3; found by measurement
- **Status**: implemented
- **Limits**: `content.tertiary` measures **4.45:1** on the filled input
  surface in light conditions — below the 4.5 minimum. A placeholder nobody
  can read is an instruction nobody gets.

### IUX-INPUT-002 — An invalid field cannot omit its message

- **Level**: standard
- **Scope**: IUX-009 onward
- **Sources**: WCAG 2.2 SC 3.3.1 Error Identification, SC 3.3.3 Error
  Suggestion
- **Status**: implemented — `IuxInputValidation.invalid` requires a non-empty
  message, so "wrong" cannot be expressed without saying what is wrong. The
  invalid outline also thickens, so the error is not only a colour change.
- **Limits**: the message's usefulness is not something a test can judge.

### IUX-INPUT-003 — Validation is a lifecycle, not a boolean

- **Level**: strong_guidance
- **Scope**: IUX-009 onward
- **Sources**: Nielsen Norman Group on premature validation
- **Status**: implemented — four statuses
- **Limits**: `notValidated` is not `valid` (a tick on every untouched field
  trains users to ignore ticks) and `validating` is not `invalid` (an error
  while the answer is unknown makes users correct something that was never
  wrong).

### IUX-PROGRESS-001 — An indeterminate indicator is removed when motion is off

- **Level**: context_dependent
- **Scope**: IUX-013 onward
- **Sources**: derived from WCAG 2.2 SC 2.3.3 and the IUX motion policy
- **Status**: implemented — determinate keeps its bar and snaps the fill,
  indeterminate removes the bar and falls back to its label as a status line
- **Limits**: a frozen indeterminate segment is parked at a position that
  means nothing, which reads as a hung operation. The label is therefore
  required and always visible, so the fallback is always available.

### IUX-PROGRESS-002 — Progress announcements are throttled to milestones

- **Level**: hypothesis
- **Scope**: IUX-013 onward
- **Sources**: none; the step is a chosen default
- **Status**: implemented — roughly every 10 points, plus every phase change
  and reaching completion. The eye is never throttled, only the announcement.
- **Limits**: 10 points is not a measured optimum and has not been validated
  with screen-reader users.

### IUX-SURFACE-001 — Interactive and subtle surfaces are not distinct today

- **Level**: context_dependent
- **Scope**: found in IUX-009, affects IUX-003.1 palettes
- **Sources**: measurement of the four shipped palettes
- **Status**: **open**. `surface.subtle` and `surface.interactive` resolve to
  the same primitive on all four profiles, so a read-only field is not
  separated from an editable one by fill alone.
- **Limits**: the resolver asks for the correct distinct roles and a test pins
  the roles rather than the colours, so the intent stays honest. Separating
  them means re-measuring every affected pair. Until then the distinction is
  the widget's — no caret, no keyboard, announced read-only — in IUX-010.

### IUX-ASYNC-001 — An async operation must report its own outcome

- **Level**: context_dependent
- **Scope**: IUX-008.6 onward
- **Sources**: ADR-0006 (the parent owns feedback truth)
- **Status**: implemented — the operation type is
  `Future<IuxAsyncOutcome> Function(...)`, never `Future<void>`. There is no
  overload or adapter accepting a bare future, so handing IUX a future and
  getting a success out of it is **unrepresentable**, not merely discouraged.
- **Limits**: a `Future<void>` completing says only that a Dart function
  returned. A save can return having written nothing; an HTTP call can come
  back 500 without throwing. The only outcome the framework derives is a
  throw, and that is observed rather than inferred.

### IUX-ASYNC-002 — Cancellation is a request, not a guarantee

- **Level**: standard
- **Scope**: IUX-008.6 onward
- **Sources**: derived from PROJECT_PROMPT §52 (never mask a critical error)
- **Status**: implemented — if an operation completes after cancellation was
  requested, the completion is reported
- **Limits**: claiming a payment was cancelled when it went through is the one
  lie a framework must never tell.

### IUX-A11Y-008 — The framework composes no busy wording

- **Level**: standard
- **Scope**: IUX-005 (corrected in IUX-008.6)
- **Sources**: PROJECT_PROMPT §23; internationalisation practice
- **Status**: **fixed**. `IuxSemantics.action` appended the English literal
  `'In progress'`, which every non-English application would have shipped
  untranslated. It now takes a caller-supplied `busyHint` and stays silent
  when none is given.
- **Limits**: silence is indistinguishable from a control that did nothing, so
  an asynchronous action should always supply one. `IuxAsyncActionButton`
  routes its `busyLabel` there automatically.

### IUX-FEEDBACK-007 — An error message with a dismiss and no recovery is refused

- **Level**: context_dependent
- **Scope**: IUX-014 onward
- **Sources**: WCAG 2.2 SC 3.3.3 Error Suggestion
- **Status**: implemented as an assertion
- **Limits**: dismissing an error asks the user to erase the only account of
  why their screen is broken while the failure is still there. Requiring a
  recovery action makes closing a choice rather than amnesia.

### IUX-FEEDBACK-008 — Inline controls are not IuxButtons

- **Level**: context_dependent
- **Scope**: IUX-014 onward
- **Sources**: measurement; `IuxButtonResolver` resolves against
  `colors.surface.base`
- **Status**: implemented — the dismiss and recovery controls are built from
  the runtime primitives with colours from the same `IuxFeedbackRoleColors` as
  the message
- **Limits**: an `IuxButton` inside a tinted alert would paint a patch of
  *page* colour into the message and carry a label colour measured against the
  page, never against this surface.

### IUX-INPUT-004 — Read-only is carried by five non-colour signals

- **Level**: standard
- **Scope**: IUX-010 onward
- **Sources**: WCAG 2.2 SC 1.4.1; forced by open issue IUX-SURFACE-001
- **Status**: implemented — no caret, no software keyboard, a lock *shape* at
  the reading end, no placeholder, and `SemanticsFlag.isReadOnly`
- **Limits**: `surface.subtle == surface.interactive` on all four palettes and
  `border.standard == border.interactive` on three of four, so neither fill
  nor outline separates read-only from editable. The widget carries it
  entirely.

### IUX-INPUT-005 — A text field takes a controller, not a value

- **Level**: strong_guidance
- **Scope**: IUX-010 onward
- **Sources**: Flutter text editing semantics
- **Status**: implemented, with a regression test
- **Limits**: a `value: String` API is purer but re-seats the caret on every
  rebuild, so a user correcting the middle of a word ends up typing at the
  end.

### IUX-STATUS-001 — A status without words is unconstructable

- **Level**: standard
- **Scope**: IUX-021 onward
- **Sources**: WCAG 2.2 SC 1.4.1 Use of Color
- **Status**: implemented — every `IuxStatus` constructor requires a non-empty
  label, `IuxStatusIndicator` always draws it, and there is no parameter that
  could hide it
- **Limits**: a coloured dot meaning "online" is the canonical colour-alone
  failure. Making the words structural rather than recommended is the only
  form of the rule that survives a deadline.

### IUX-STATUS-002 — Each tone resolves a distinct glyph, and a test proves it

- **Level**: strong_guidance
- **Scope**: IUX-021 onward
- **Sources**: WCAG 2.2 SC 1.4.1
- **Status**: implemented — `IuxStatusResolver.glyph` is public precisely so
  `IuxStatusTone.values.map(glyph).toSet()` can be asserted to hold four
  elements
- **Limits**: automates the "render it in one hue and see what disappears"
  check. The four glyph choices themselves are a hypothesis.

### IUX-STATUS-003 — A badge may not announce its own number

- **Level**: standard
- **Scope**: IUX-021 onward
- **Sources**: WCAG 2.2 SC 4.1.2 Name, Role, Value
- **Status**: implemented — `IuxBadge.count(count: '3', label: '3')` throws
- **Limits**: "3" is meaningless; "3 unread messages" is information. The
  number alone works only for someone who already knows what it counts.

### IUX-STATUS-004 — A tag chip cannot announce itself as a control

- **Level**: standard
- **Scope**: IUX-021 onward
- **Sources**: WCAG 2.2 SC 4.1.2
- **Status**: implemented — two distinct types. A tag is built from
  `IuxSemantics.group`, contains no gesture detector and no focus node, and
  resolves `minimumSize` to zero.
- **Limits**: one type with a nullable callback would look identical whether
  or not it was a control. The tag also uses `border.subtle`, the one border
  role IUX forbids on interactive elements, so it looks inert as well as being
  inert.

## Deferred to later missions

| Subject | Mission |
| --- | --- |
| Visual feedback components (snackbar, alerts, loaders) | IUX-013 to IUX-015 |
| A lint enforcing that components read the runtime | Phase 5 |
| Per-intent action container roles, so tonal can express intent | unscheduled |
| Distinct `surface.interactive`, so a read-only field differs by fill | unscheduled |
| `IuxSemantics.field`, so a text field need not compose `Semantics` directly | unscheduled |
| A semantic role for text selection, currently inherited from Material | unscheduled |

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
