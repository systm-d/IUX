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

### IUX-SURFACE-001 — Interactive and subtle surfaces were not distinct (FIXED)

- **Level**: context_dependent
- **Scope**: found in IUX-009, affected the IUX-003.1 palettes; closed after
  IUX-042
- **Sources**: measurement of the four shipped palettes
- **Status**: **closed.** `surface.interactive` has its own primitive per
  profile. Two real consumers, both re-measured.
- **The defect was the mirror of the one recorded.** The entry said a read-only
  field was not separated from a *disabled* one; measured, those two differ by
  border, value colour and marker on all four profiles, and only the fill
  collided, and only on dark standard. What actually collided was read-only
  against **editable**: in the `filled` variant, byte-identical fill on all four
  profiles, identical value colour on all four, identical outline on three. A
  lock glyph was the only thing separating a box you may type in from one you
  may not, and the *sighted* user was the one misled.
- **A claim withdrawn with it**: "five other signals carry read-only" was false.
  Four of the five separate read-only from editable and say nothing about
  disabled; the fifth is worse, because a **disabled** field also publishes
  `isReadOnly` — Flutter resolves `readOnly: widget.readOnly || !_isEnabled` and
  merged flags disjoin. Exactly one signal, the marker, separated the two.
- **Limits**: fill still does not *carry* the distinction and cannot — no two
  steps of the neutral ramp reach 3:1, the widest pair on any profile being
  1.86:1. `surface.subtle` still equals `surface.disabled` on dark standard;
  every alternative rung measured there costs `border.interactive` its 3:1, and
  buying a 1.3:1 fill difference with an unreadable outline is the wrong trade.
  Whether a *lock* is the right marker is untested — its contrast is measured,
  its meaning is a hypothesis, and it arguably reads as "unavailable", which is
  what the neighbouring state means.

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

### IUX-A11Y-009 — A named button with no tap action is unusable

- **Level**: standard
- **Scope**: IUX-005 (defect), fixed during IUX-011
- **Sources**: WCAG 2.2 SC 4.1.2 Name, Role, Value
- **Status**: **fixed**. `IuxSemantics.action` sets `excludeSemantics: true`
  to control the announced name, which also removed the child gesture
  detector's tap action. `IuxButton` therefore announced a button and offered
  nothing to activate — visible, named, and unusable with TalkBack.
- **Limits**: verified by probe before and after (`actions: 0` → `actions: 1`)
  and locked by two regression tests, including one asserting a disabled
  button offers *no* tap action.

### IUX-CARD-001 — A tappable card may not contain controls

- **Level**: strong_guidance
- **Scope**: IUX-019 onward
- **Sources**: WCAG 2.2 SC 4.1.2; nested interactive elements
- **Status**: implemented in two layers — `IuxCard.tappable` has no `actions`
  parameter, and a debug-only subtree guard throws naming the offender
- **Limits**: a card that is itself a control and also contains controls has
  two answers to "what does tapping do", and nothing on screen says which.
  The guard is a heuristic, compiled out in release, and blind to custom hit
  testing.

### IUX-DIALOG-001 — A modal is a layer the parent places, not a route

- **Level**: context_dependent
- **Scope**: IUX-016 onward
- **Sources**: the component standard forbids `Navigator` in a component
- **Status**: implemented — `IuxModalLayer` stacks one dialog over the page
- **Limits**: the real cost is that the Android back button does not reach it;
  the parent wires `PopScope` to the same dismissal. Stated rather than
  hidden. A single dialog slot makes stacking structurally impossible.

### IUX-DIALOG-002 — Focus lands on the panel, never on an action

- **Level**: strong_guidance
- **Scope**: IUX-016 onward
- **Sources**: WCAG 2.2 SC 2.4.3 Focus Order
- **Status**: implemented and mutation-tested
- **Limits**: a dialog that focuses its confirming action turns an in-flight
  Enter keystroke into a confirmation nobody read.

### IUX-SELECTION-001 — Activating a partial control selects all

- **Level**: strong_guidance
- **Scope**: IUX-011 onward
- **Sources**: derived from PROJECT_PROMPT §18 (error prevention)
- **Status**: implemented — the user can never request `partial`
- **Limits**: clearing would destroy choices already made; selecting all is
  recoverable by one more activation.

### IUX-MEDIA-001 — Decorative versus meaningful is stated, never inferred

- **Level**: standard
- **Scope**: IUX-022 onward
- **Sources**: WCAG 2.2 SC 1.1.1 Non-text Content
- **Status**: implemented — `IuxImageDescription` is required with no default
  and has exactly two constructors, `.meaningful(String)` and `.decorative()`
- **Limits**: a nullable label where null quietly means decoration collapses
  "I have not written it yet" and "this says nothing" into one value.
  `isDecorative` is a field rather than an empty-string check, so a forgotten
  description and a deliberate absence stay distinguishable in release, where
  assertions no longer run.

### IUX-MEDIA-002 — An avatar's initials are drawn but never announced

- **Level**: standard
- **Scope**: IUX-022 onward
- **Sources**: WCAG 2.2 SC 1.1.1
- **Status**: implemented structurally — `IuxSemantics.image` excludes
  descendant semantics, so no arrangement of parameters gets "JD" spoken
- **Limits**: IUX never derives initials from a name. That rule breaks for
  李明, van der Berg, mononyms, and every script without spaces. The caller
  supplies them.

### IUX-MEDIA-003 — A failed meaningful image renders its own description

- **Level**: standard
- **Scope**: IUX-022 onward
- **Sources**: WCAG 2.2 SC 1.1.1; HTML `alt` behaviour
- **Status**: implemented — the node's role changes from image to text,
  because the truth changed. A failed decorative image keeps its space and
  stays silent.
- **Limits**: a screen-reader user is not told the picture *failed*; they get
  the description as text. Honest, but not identical to a sighted user's
  experience. IUX invents no failure wording.

### IUX-MEDIA-004 — An avatar has no failure state by construction

- **Level**: strong_guidance
- **Scope**: IUX-022 onward
- **Sources**: none external; an IUX design decision
- **Status**: implemented — the photograph is drawn on top of a fallback that
  is already present
- **Limits**: offline, 404, slow or malformed, the user sees what they saw a
  moment earlier. A blank circle is a failure the user cannot interpret.

### IUX-OVERLAY-001 — Opening a modal resets the page's scroll position

- **Level**: context_dependent
- **Scope**: found in IUX-015, affects IUX-016
- **Sources**: measured — a list at offset 400 snaps to 0 the instant a dialog
  appears
- **Status**: **open, and deliberately not fixed here.** `IuxModalLayer`
  returns its child bare while idle, so the page changes depth in the element
  tree when a modal opens and its subtree rebuilds, taking scroll offsets,
  keyboard focus and in-flight animations with it.
- **Limits**: keeping the `Stack` permanently fixes the scroll loss and breaks
  something worse — with the page element preserved, `BlockSemantics` no
  longer removes it from the semantics tree, so a screen-reader user can read
  and try to activate a page they cannot touch. `PROJECT_PROMPT.md` §5 puts
  accessibility above ergonomics, so the scroll loss stays until both can be
  had at once.

### IUX-TRANSIENT-001 — A transient channel cannot carry a failure

- **Level**: standard
- **Scope**: IUX-015 onward
- **Sources**: WCAG 2.2 SC 2.2.1 Timing Adjustable
- **Status**: implemented in the type — `IuxTransientTone` has only `neutral`
  and `success`. There is no `error` and no `warning`.
- **Limits**: a message that disappears on a timer is lost by a slow reader, a
  screen-reader user mid-sentence, or anyone who looked away. Making the
  channel unable to hold anything needed is what lets replacement-on-collision
  be defensible.

### IUX-TRANSIENT-002 — An action removes the timer entirely

- **Level**: standard
- **Scope**: IUX-015 onward
- **Sources**: WCAG 2.2 SC 2.2.1, SC 2.2.2
- **Status**: implemented — a message carrying an action never expires, and an
  expected screen reader also removes the timer
- **Limits**: "Undo" that vanishes after four seconds is undo for fast people
  only. The cost is that the message occupies the bottom strip until dealt
  with; if that is unacceptable, the action does not belong there.

### IUX-LIST-001 — A trailing control is a sibling, never inside the row

- **Level**: strong_guidance
- **Scope**: IUX-020 onward
- **Sources**: WCAG 2.2 SC 4.1.2; consistent with IUX-CARD-001
- **Status**: implemented — `title`, `subtitle` and `trailingText` are
  `String`, not `Widget`, so a control inside the activatable region is a type
  error rather than a runtime warning
- **Limits**: a card's answer was "move the button outside the card"; a row has
  no outside. `trailingAction` is laid out beside the region, spaced by the
  floor, exposed as a sibling semantics node, and the press tint stops at the
  boundary. Whether users perceive it as a second target is a hypothesis.

### IUX-SHEET-001 — The keyboard lift is the residue, not the inset

- **Level**: standard
- **Scope**: IUX-017 onward
- **Sources**: measured against a `Scaffold` with the default
  `resizeToAvoidBottomInset`
- **Status**: implemented — the sheet lifts by
  `max(0, keyboard − (windowHeight − boxHeight))`
- **Limits**: a host that already resized has consumed part of the inset.
  Adding the full inset on top lifts the sheet twice and leaves a
  keyboard-sized band of scrim beneath it.

### IUX-DESTRUCTIVE-001 — A reversible action may not ask for confirmation

- **Level**: strong_guidance
- **Scope**: IUX-008.7 onward
- **Sources**: Nielsen Norman Group on confirmation fatigue; PROJECT_PROMPT §18
- **Status**: implemented — `IuxDestructiveAction` asserts on
  `reversible` + any confirmation policy, with the argument in the message
- **Limits**: a confirmation charges every user a step against a mistake most
  will not make; an undo costs nothing until someone errs, and it is the only
  one that helps the user who *meant* to press the button and was wrong about
  what it did. `difficultToReverse` is the escape hatch and confirms without
  complaint.

### IUX-DESTRUCTIVE-002 — A prompt without a policy, and a policy without a prompt, are both refused

- **Level**: context_dependent
- **Scope**: IUX-008.7 onward
- **Sources**: none external; an IUX judgement
- **Status**: implemented as two assertions
- **Limits**: the dangerous direction is a prompt attached to an action
  declaring no confirmation — the call site *reads* as though the user is
  being asked, and the action runs on the first tap.

### IUX-DESTRUCTIVE-003 — Hold and double-activation are refused, not approximated

- **Level**: context_dependent
- **Scope**: IUX-008.7 onward
- **Sources**: the action model already documents hold as unusable with
  tremor and invisible to a screen reader
- **Status**: both assert, pointing at the supported policies
- **Limits**: hold must never be the only route to an action, and one control
  cannot offer a second route to itself. A hold threshold is also a duration
  IUX has no token for — inventing one would put an untunable delay in front
  of the users least able to beat it.

### IUX-DESTRUCTIVE-004 — The shortest destructive descriptor still confirms

- **Level**: context_dependent
- **Scope**: open observation, IUX-008.2
- **Sources**: found during IUX-008.7
- **Status**: **open, deliberately unchanged.**
  `IuxActionDescriptor.destructive` defaults to `IuxConfirmBeforeExecution`,
  which is the safe reading when a caller says nothing — but it means the
  briefest destructive descriptor is a confirming one, pulling against the
  pattern's thesis that undo beats confirmation.
- **Limits**: changing a default is a breaking behaviour change. The pattern's
  assertions steer callers toward the reversible-plus-undo path instead.

### IUX-FORM-001 — Validation happens on blur, and only for edited fields

- **Level**: strong_guidance
- **Scope**: IUX-012 onward
- **Sources**: Nielsen Norman Group, "reward early, punish late"
- **Status**: implemented — `IuxValidationTiming.onBlur` by default, gated by
  `IuxFormField.edited`
- **Limits**: per-keystroke validation reports an error about a value that was
  never wrong, only unfinished. Submit-only hands the user every problem at the
  moment they believed they were done. The `edited` gate is what stops tabbing
  toward Submit from producing a column of "required" errors about fields
  nobody touched. `edited` is taken on trust; nothing can verify it.

### IUX-FORM-002 — A failed submit moves focus to the summary, not the first field

- **Level**: context_dependent
- **Scope**: IUX-012 onward
- **Sources**: WCAG 2.2 SC 3.3.1; PROJECT_PROMPT §5
- **Status**: implemented — the summary is focusable, announces on arrival,
  and each entry focuses and scrolls to its field
- **Limits**: the summary states how many problems exist and preserves the
  user's choice of repair order, and it is the same destination every time —
  which a first-field rule is not. The cost, stated: for a single error it is
  one extra hop. With no summary, focus falls back to the first invalid field.

### IUX-FORM-003 — A blocked submit is never silent

- **Level**: standard
- **Scope**: IUX-012 onward
- **Sources**: WCAG 2.2 SC 3.3.1 Error Identification
- **Status**: implemented — `IuxFormSubmit` refuses at construction a disabled
  action with no `unavailabilityReason`, and a blocked submit calls
  `onBlocked` rather than nothing
- **Limits**: a disabled submit button that never says why is the canonical
  silent refusal. Blocking while a check is still `validating` was rejected
  for the same reason: blocking on something the framework cannot explain is
  itself a silent refusal.

### IUX-APPBAR-001 — The title is never abbreviated; the row gives instead

- **Level**: standard
- **Scope**: IUX-023 onward
- **Sources**: WCAG 2.2 SC 1.4.4 Resize Text, SC 2.4.6 Headings and Labels
- **Status**: implemented — `maxLines` is null, overflow is never `ellipsis`,
  and there is no code path that abbreviates a title. When it stops fitting,
  the controls keep their row and the title takes the one below, full width.
- **Limits**: the decision is measured with a `TextPainter` at the real scale
  rather than thresholded. The twelve-character readable floor and the
  half-em-per-character conversion are a hypothesis, wrong for CJK and
  monospace in the generous direction.

### IUX-APPBAR-002 — Not a PreferredSizeWidget, on purpose

- **Level**: context_dependent
- **Scope**: IUX-023 onward
- **Sources**: `Scaffold.appBar` reads `preferredSize` before layout
- **Status**: implemented — `IuxAppBar` composes into the `Scaffold` body,
  above `IuxPage`, and two tests lock it in
- **Limits**: `preferredSize` is read with no `BuildContext`, no text scale,
  no width and no line count, then caps the bar at that height. Material's own
  `AppBar` fails identically one level down. Using either slot would have
  shipped the clipped title this component exists to prevent — at the cost of
  `SystemUiOverlayStyle`, the automatic drawer button and scroll-under, all
  tabulated in the doc.

### IUX-APPBAR-003 — The bar consumes the top inset, so the page must not

- **Level**: context_dependent
- **Scope**: IUX-023 onward
- **Sources**: the `IuxPageInsets` design from IUX-007
- **Status**: documented and exemplified, **not** asserted
- **Limits**: no component can inspect its sibling, so the pairing
  (`IuxAppBar` + `IuxPageInsets.bottomOnly`) is a convention. A composition
  widget owning both would make the double-padding hazard unrepresentable;
  that belongs in `patterns/`.

### IUX-NAV-001 — Every destination is named, always

- **Level**: strong_guidance
- **Scope**: IUX-024 onward
- **Sources**: WCAG 2.2 SC 2.4.6; measured on a 320 px viewport
- **Status**: implemented — no `labelBehavior`, no `showLabel`, no icon-only
  form. Above ~130% text the destinations stop sharing a row and stack as
  full-width glyph-beside-name, so a name gets 320 px instead of 56.
- **Limits**: five destinations at 200% cost 360 px of a 640 px screen, every
  name whole. Hiding labels saves ~130 px and leaves five unlabelled glyphs
  for the user most likely reading with a magnifier; wrapping in a 56 px
  column renders "Notifications" as four fragments. Above ~250% with five
  destinations the bar scrolls rather than dropping one — documented as a
  degradation, not a feature.

### IUX-NAV-002 — The current destination is `checked`, not `selected`

- **Level**: context_dependent
- **Scope**: IUX-024 onward
- **Sources**: WCAG 2.2 SC 4.1.2
- **Status**: implemented — `checked` + `inMutuallyExclusiveGroup`, inside a
  `SemanticsRole.radioGroup`
- **Limits**: a checked node is announced in *both* states, so the user learns
  where they are from the destination they land on rather than sweeping the
  bar for the one that spoke. Verified by probing the real semantics tree:
  destinations carry label + checked + inMutuallyExclusiveGroup + tap + focus,
  and the parent carries `SemanticsRole.radioGroup` with the bar's own name.
  Two findings from that probe: Flutter has **no `SemanticsRole.radio`**, so
  `checked` + `inMutuallyExclusiveGroup` is the only available expression, not
  a preference; and a node holds one role, so keeping `radioGroup` costs the
  `navigation` landmark. The group role wins because it is what makes "where
  am I" audible, while the landmark only shortens a journey of two swipes.
- **Corrected at IUX-026**: the original rationale said `selected` is announced
  only when true. Measured on Flutter 3.44, `selected: false` yields
  `Tristate.isFalse` — explicitly present. The flags are tri-state and the two
  are indistinguishable framework-side. What survives is that `checked` plus
  `inMutuallyExclusiveGroup` says *one of these and only one*, which
  `selected` does not claim. Whether a screen reader speaks the unselected
  state is untested on hardware and is no longer asserted.

### IUX-NAV-003 — Destinations tile the bar, with no spacing between them

- **Level**: context_dependent
- **Scope**: IUX-024 onward
- **Sources**: WCAG 2.2 SC 2.5.8, which treats spacing as an alternative to
  size
- **Status**: deliberate deviation from `kIuxMinimumTargetSpacing`
- **Limits**: a gap would be four dead strips in the thumb zone, and 64 × 112
  clears the 48 floor outright. Below 320 px the floor is arithmetically
  impossible for five destinations.

### IUX-HELP-001 — A tooltip is never the only carrier of a meaning

- **Level**: standard
- **Scope**: IUX-018 onward
- **Sources**: WCAG 2.2 SC 1.4.13, SC 2.1.1
- **Status**: implemented — reachable by long press (touch), focus (keyboard),
  hover (pointer); dismissable by `Escape`, by a press outside, by a press on
  the control or on the tooltip; hoverable through a transparent bridge across
  the gap; persistent with no clock in the implementation at all.
- **Limits**: long press is undiscoverable and unannounced to sighted users,
  which is exactly why a tooltip may never carry something essential. The
  outline's 3:1 is measured against the theme's page surface, not against a
  photograph the tooltip happens to float over. Nothing can check that a
  message is genuinely redundant.

### IUX-HELP-002 — 80 characters is the enforced boundary between float and flow

- **Level**: context_dependent
- **Scope**: IUX-018 onward
- **Sources**: measured at 200% on a 320 px viewport
- **Status**: implemented — `kIuxTooltipMaximumCharacters = 80`, asserted, not
  advised
- **Limits**: 80 is about two lines at default text and four to five at 200%
  on 320 px — the edge of what may float. A floating box cannot scroll, cannot
  be kept open and covers the page it explains; `IuxContextualHelp` sits in the
  flow and has none of those problems, at the cost of moving content below it.

### IUX-A11Y-EXPANDED — Disclosure state rides the control's own node

- **Level**: standard
- **Scope**: IUX-018 onward
- **Sources**: WCAG 2.2 SC 4.1.2
- **Status**: implemented — `IuxSemantics.action` gained `expanded`, and
  `IuxSemantics.elaboration` carries the platform tooltip property. Both close
  documented deviations from component standard §2: two components had been
  composing bare `Semantics` because the runtime had nowhere to put these.
- **Limits**: `expanded` is null rather than false by default, so an ordinary
  button is never announced as "collapsed" — a state it does not have.

### IUX-A11Y-FOCUS-001 — Focus semantics, closed across the library (FIXED)

- **Level**: standard
- **Scope**: every component built on `IuxSemantics.action`, since IUX-005
- **Sources**: WCAG 2.2 SC 4.1.2; measured against Flutter's own button
- **Status**: **open defect, confirmed by probe.** Flagged by the IUX-028
  agent, verified independently rather than taken on the report — and it is
  worse than reported.

  | | `isFocused` | actions |
  | --- | --- | --- |
  | `IuxButton` | `Tristate.none` | `[tap]` |
  | `ElevatedButton` | `Tristate.isFalse` | `[tap, focus]` |

  `Tristate.none` means the node declares no focusable state at all, and the
  missing `SemanticsAction.focus` means assistive technology cannot move
  accessibility focus onto an IUX control programmatically.

- **Cause**: the third instance of one mechanism. `IuxSemantics.action` sets
  `excludeSemantics: true` to control the announced name, which deletes
  everything the `IuxFocusable` subtree contributed. It deleted `onTap` first
  (fixed at IUX-011, after every IUX button had been unusable with a screen
  reader since IUX-005); it deletes the focus state too.
- **Not a regression**: `IuxBottomNavigation` destinations do carry
  `[tap, focus]`, because they do not route through the helper.
- **Fixed for `IuxButton` at IUX-038**, verified by re-probing rather than by
  reading the diff: it now reports `isFocused: Tristate.isTrue` when it holds
  focus and offers `[tap, focus]`, matching Flutter's own.
- **Closed.** The sweep found **eleven** controls affected, not the four first
  reported, and three of them had no `tap` action at all — announced as
  buttons, inert to a screen-reader double-tap. `IuxFocusNodeOwner` now has ten
  call sites, and a later independent audit re-probed every control and found
  the flag and the `focus` action present throughout.
- **My first two write-ups of this were both wrong**, in opposite directions:
  the first claimed it was fixed everywhere when one call site existed, the
  second left it marked partial after the sweep had closed it. Both were
  corrected by somebody measuring rather than reading the entry.
- The original text is kept below because the mechanism still matters:
  `_IuxDisclosureControl`, `IuxValidationSummary` entries and both
  transient-layer controls still report `isFocused: Tristate.none` with
  `actions=[tap]` — and driving `performAction(SemanticsAction.focus)` on the
  disclosure control does nothing at all. Found by IUX-038 auditing the fix it
  had just landed.
- **The mechanism of the fix**: `IuxSemantics.action` now publishes the focus
  state and the `focus` action itself, naming the *same* `FocusNode` that
  `IuxFocusable` holds. A private `IuxFocusNodeOwner` supplies that node —
  deliberately unexported — because otherwise every control repeats four lines
  (hold a fallback, create it lazily, prefer the caller's, dispose only the one
  it owns) at eight call sites, and the line most easily forgotten is the
  disposal.

### IUX-DRAWER-001 — The working stack shape is the only one a caller can express

- **Level**: standard
- **Scope**: IUX-027 onward
- **Sources**: WCAG 2.2 SC 4.1.2, SC 2.1.2; measured against the real
  semantics tree
- **Status**: implemented — `IuxModalLayer` gains a `drawer` slot, and the
  three modals are mutually exclusive by assertion.
- **Finding**: `Stack(children: [page, if (open) drawer])` looks correct and
  is not. The page element survives the transition, its semantics node is
  never recompiled, and `BlockSemantics` therefore does **not** remove the
  covered page — a screen reader goes on reading, and offering to activate,
  controls the user cannot touch. Touch behaves identically in both shapes,
  which is why nothing but a screen reader catches it. Verified from both
  sides: the page leaves the tree through `IuxModalLayer`, and demonstrably
  does not in the hand-rolled shape.
- **Limits**: the second test is not a test of IUX. It pins Flutter's
  behaviour, and the day it fails is the day this entry and IUX-OVERLAY-001
  both need rereading.

### IUX-EMPTY-001 — Four situations, not one empty state

- **Level**: strong_guidance
- **Scope**: IUX-028 onward
- **Sources**: WCAG 2.2 SC 3.3.3; WCAG 2.2 SC 4.1.3 for the announcement
- **Status**: implemented — nothing yet created, a filter that matched
  nothing, a search that matched nothing and a permission that hides
  everything are distinct, and the wrong situation/action pairing cannot be
  constructed. An unavailable action must carry its `unavailabilityReason`:
  on an empty state the greyed control *is* the whole interface, and a
  disabled control leaves the focus order on Android, so a screen-reader user
  cannot even reach it to wonder why.
- **Limits**: focus is deliberately **not** moved — the opposite of
  `IuxValidationSummary`, because a refused submission happens while the user
  waits for an answer, whereas a list empties under a filter while their hands
  are in the search field. The live region is on the message, not the block:
  the action stays a node of its own, since merged in it would be announced
  and unreachable.

### IUX-RAIL-001 — The arrangement is chosen by what is left for the content

- **Level**: context_dependent
- **Scope**: IUX-025 onward
- **Sources**: measured on real windows, at 100–300% text
- **Status**: implemented — no adopted breakpoint. Android's 600 dp was
  considered and not taken; the disagreement is confined to wide-portrait
  windows and is logged as a **hypothesis**, not a finding.
- **Measured**: on 412x915 the bar costs 10% of height; a rail would cost 31%
  and leave 282 px, under the floor, so it is refused twice over. Turned to
  915x412 at 200% the bar costs 87% of the height and the rail 26%. Five
  destinations begin to scroll from about 125% text on a 412-tall window
  (415 px needed against 412).
- **Limits**: on 320x640 at 300% neither arrangement fits and the content is
  laid out at zero height. That is IUX-024's documented bar degradation and is
  not fixed here.

### IUX-RAIL-002 — Three defects the measurement itself was causing

- **Level**: standard
- **Scope**: IUX-025
- **Status**: fixed, each found by measuring rather than reading.
  1. The rail's widest name always wrapped to two lines — exactly the failure
     its own documentation promised to prevent. `widthFor` measured the label
     style alone, while the rendered `Text` merges it over the ambient
     `DefaultTextStyle` and picks up a `letterSpacing` the typography theme
     never sets. 0.25 px per character: `Messages` needed 114 px and was given
     112. Cell heights measured `[72, 92, 72, 72, 72]`; the 92 was the defect.
  2. The arrangement rule handed the user the worse option on a landscape
     window. At 640x320 at 300%, the rail leaves 286x320 and the bar leaves
     **640x0** — content at zero height. The content budget now applies only
     while the bar is still a compact strip.
  3. The display inset was applied twice: with a 48 px cutout the child's
     `MediaQuery.padding` still read `left: 48` after the rail had already
     stood on it. The documented workaround was worse than the bug, since it
     also dropped the *top* inset and put content under the status bar.
     `MediaQuery.removePadding` now hands off only the consumed edge.

### IUX-TABS-001 — Flutter enforces the tab contract, and one detector breaks it silently

- **Level**: standard
- **Scope**: IUX-026 onward
- **Sources**: WCAG 2.2 SC 4.1.2; probed against the real semantics tree and
  Flutter's own assertions
- **Status**: implemented. `SemanticsRole.tab` on each tab, `tabBar` on the
  strip. Flutter itself refuses a tab without a selected state ("A tab needs
  selected states"), without a tap action ("A tab must have a tap action"),
  and refuses a `tabBar` child that is not a tab — all three error strings
  probed directly rather than assumed.
- **The load-bearing finding**: a `GestureDetector` that describes itself
  creates a *second* semantics node per tab — measured 6 stops for 3 tabs —
  and pushes the tab role onto a parent whose child is then not a tab.
  `MergeSemantics` collapses the stops but moves the role off the checked
  node, so its own role becomes `none` and **Flutter's tab check silently
  never runs**. Building the detector with `excludeFromSemantics: true` gets
  both: one stop per tab, and the role on the node the framework checks.
- **Limits**: `SemanticsRole.tabPanel` is `_noCheckRequired` — Flutter does
  nothing with it, and there is no `aria-controls` equivalent, so a tab-panel
  association is inexpressible. No panel wrapper ships, because §19 forbids a
  public widget whose only effect is an unverified role.

### IUX-TABS-002 — Roving focus declined, and the asymmetry that decided it

- **Level**: context_dependent
- **Scope**: IUX-026 onward
- **Sources**: WAI-ARIA authoring practices (not followed); WCAG 2.2 SC 2.1.1
- **Status**: deliberate deviation from the ARIA practice. Tab visits every
  tab and then leaves into the panel; arrows move within and across wrapped
  rows through Flutter's own directional traversal.
- **Reasoning**: verified in Flutter source that
  `FocusScopeNode.traversalDescendants` filters `skipTraversal`, so the change
  that removes four tabs from Tab removes them from the arrow keys too, and
  arrow handling would have to be hand-rolled. The risk is asymmetric: a
  device emitting only Tab and Enter would leave four of five views
  **unreachable** — an outright SC 2.1.1 failure — where Tab-through costs
  four extra presses.

### IUX-ERROR-001 — The way out is part of the error, not a decoration

- **Level**: strong_guidance
- **Scope**: IUX-029 onward
- **Sources**: WCAG 2.2 SC 3.3.3; SC 2.2.1
- **Status**: implemented — a sealed route type, so an error with no way
  forward has to be declared as one. `IuxRetryRoute` accepts **no**
  `IuxActionDescriptor`: role, repeat policy, importance and confirmation are
  fixed because none is a decision the caller should be offered, and there is
  no `availability` either — a parent out of retry budget must *swap the
  route*, not grey the control, and removing the parameter is what makes that
  enforceable rather than advisory.
- **Honest about the limit**: the two patterns cannot blur from either side —
  `IuxEmptyStateAction` refuses `IuxActionRole.retry` and `IuxAlternativeRoute`
  derives `navigate` with no way to become a retry. But whether a *given*
  failure is retryable needs a status code the framework does not have. No
  guarantee is faked; the type system reduces the claim to one reviewable word
  in the diff.
- **Nothing retries on its own**: no timer, no counter, no backoff. Tested by
  pumping thirty seconds and asserting zero attempts. The consequence is that
  the pattern imposes no time limit, so SC 2.2.1 has nothing to adjust.

### IUX-ERROR-002 — Focus is not moved, and there is no hook to move it

- **Level**: context_dependent
- **Scope**: IUX-029 onward
- **Sources**: WCAG 2.2 SC 3.3.1, SC 4.1.3
- **Status**: implemented, and deliberately opposite to `IuxForm`, which moves
  focus because it *knows* the user just pressed submit. Nothing here knows
  that: an operation can fail while the user is typing elsewhere.
- **The decisive argument is specific to this pattern**: focus landing on a
  retry arms an activation under the next Enter or screen-reader double-tap,
  so the one control in the library that must never fire twice would be the
  one that armed itself. Measured rather than argued in prose — focus is put
  on a control elsewhere, the failure is inserted, and `primaryFocus` is
  required unchanged with the retry on screen.
- **Divergence from IUX-028**: the live region is unconditional, with no
  `arrival` enum. A region that is empty may always have been; a region that
  *failed* is an event by definition.

### IUX-LOAD-001 — Four states, three branches, and no fourth enum value

- **Level**: strong_guidance
- **Scope**: IUX-030 onward
- **Sources**: WCAG 2.2 SC 4.1.3; SC 2.2.1, SC 2.2.2, SC 2.3.3
- **Status**: implemented — there is no `IuxLoadState.empty`. An empty result
  is `ready` with an empty value, and the builder names the situation with
  `IuxEmptyState`. A fourth value would flatten `IuxEmptyStateCause`'s four
  situations back into one word. The impossible combinations are not asserted:
  one sealed value, one exhaustive `switch`.
- **Nothing retries on its own and nothing times out.** Three guards against a
  user-driven storm: the control does not exist while loading, the derived
  descriptor's `ignoreWhileInProgress` drops overlapping activations, and there
  is no availability flag to mis-set. Because nothing times out, **SC 2.2.1
  has no time limit to bind** — a framework timeout would have *created* one,
  on a screen with no way to extend it. SC 2.2.2 does not bind the bar
  (essential motion, and the wait replaces content rather than sitting beside
  it); SC 2.3.3 does, and is honoured through `IuxMotionPolicy`.
- **Measured**: one traversal of the indeterminate bar is 1800 ms at standard
  motion, never shorter under `reduced`, `Duration.zero` under `none`. That
  grounds the delay argument — a load resolving in 80 ms shows the bar for
  under a twentieth of one crossing, so the user sees something appear at a
  position and vanish from it, which is why it reads as a rendering fault
  rather than as work. The ~0.1 s threshold (Miller 1968, Nielsen 1993) is
  documented as the **caller's**: a parent expecting an answer inside it
  should not enter `loading` at all.
- **No skeleton, and no slot for one**: it claims a shape only the caller
  knows, its shimmer is decorative motion, it is announced as nothing, and the
  perceived-speed evidence is contested — §9 forbids shipping a hypothesis as
  fact.

### IUX-LOAD-002 — A generic sealed type broke equality, silently

- **Level**: standard
- **Scope**: IUX-030
- **Status**: fixed. All three subclasses of `IuxLoadState<T>` compared with a
  type test (`other is IuxLoadReady<T>`) while `hashCode` folded `T` in. Dart
  generics are covariant, so `IuxLoadReady<int>` *is* an
  `IuxLoadReady<Object>`: `loose == tight` was true, `tight == loose` false,
  and the hash codes disagreed throughout — a value a `Set` holds twice and a
  `Map` never finds. Fixed with `runtimeType` and pinned by a symmetry and
  set-cardinality test.
- **Why it was missed**: this is the project's first *generic* sealed type,
  so the comparison pattern used correctly everywhere else was silently wrong
  here.

### IUX-BUTTON-BUSY-001 — A running button was announced as unavailable (FIXED)

- **Level**: standard
- **Scope**: every component built on `IuxButton`, including IUX-029's
  shipped retry
- **Sources**: WCAG 2.2 SC 4.1.2; probed directly
- **Status**: **open defect, confirmed by probe.** Reported by the IUX-030
  agent, verified independently rather than taken on the report.

  | | focus | `enabled` | `hint` |
  | --- | --- | --- | --- |
  | idle | held | `Tristate.isTrue` | empty |
  | in progress | **lost** | **`Tristate.isFalse`** | "Envoi en cours" |

- **Cause**: `_IuxActionSurface` computes `activatable` from
  `IuxActionDescriptor.isActivatable`, which is false while
  `operation == inProgress` under the default repeat policy, and feeds that one
  value to both `IuxFocusable(canRequestFocus:)` and
  `IuxSemantics.action(enabled:)`. In progress and unavailable are collapsed
  into one flag.
- **Consequences**: a keyboard user who presses "Try again" is thrown back to
  the enclosing scope; Android announces "unavailable" for something that is
  working; and `busyHint` — added at IUX-008.6 precisely because "silence is
  indistinguishable from a control that did nothing" — is attached to a node
  the user has just been moved off.
- **It contradicts the model it is built on**: IUX-008.2 made the action
  dimensions orthogonal, and `IuxActionDescriptor` even asserts that a
  disabled action cannot be in progress in order to keep them apart. The
  button collapses them anyway.
- **Fixed at IUX-038**, re-probed rather than read. A running button now keeps
  the focus the user put on it, reports `enabled: Tristate.isTrue`, carries its
  `busyHint`, and offers `[focus]` but **not** `tap`.
- **That last part is the whole fix**: withholding the tap is the truth — the
  repeat policy really does decline a second activation — while claiming the
  control is *disabled* was not. The two were one flag and are now two.
- The tests IUX-008.9 wrote to pin the defective behaviour were flipped, not
  deleted, which is what they were written for.

### IUX-BUTTON-CONFIRM-001 — A confirmation policy is honoured by one widget in four (FIXED)

- **Level**: standard
- **Scope**: `IuxButton`, `IuxIconButton`, `IuxAsyncActionButton`
- **Sources**: PROJECT_PROMPT §5 (user safety first), §22 (components prevent
  incoherent states)
- **Status**: **open defect, the most serious found so far.**
  `IuxButton(action: IuxActionDescriptor.destructive(semantics: ...))`
  compiles, asserts nothing, and runs `onActivate` on the **first tap** —
  measured, `runs == 1`, no exception. The destructive factory *defaults* to
  `IuxConfirmBeforeExecution`, so the trap sits on the shortest path a caller
  can write for a deletion. `IuxAsyncActionController.activate()` behaves
  identically. Only `IuxDestructiveActionController` evaluates the policy.
- **Why it is a defect and not a division of labour**: the destructive
  pattern's own docstring calls it "a quiet trap" and accepts it. A caller who
  reaches for the factory named `destructive` has stated an intention the type
  system then discards in silence.
- **An attempted fix was written, tested and reverted.** Making `IuxButton`
  refuse a descriptor carrying an unhonourable policy is the obvious shape and
  it is unsound. It has to be a debug check at `build`, not an initialiser
  assertion, because the constructors are `const` and Dart forbids reading a
  parameter's field there — the same constraint IUX-028 hit. Past that it
  broke two legitimate callers. `IuxDialog` hands `choice.action` to a button
  whose tap *is* the answer, and `IuxDestructiveAction`'s trigger holds the
  policy precisely because its tap is what opens the question. The first was
  fixable by stripping the policy on the way in — the codebase already has
  that idiom at `iux_destructive_action.dart:217`. The second is not: the
  policy must survive to the button, and `IuxButton` cannot know whether
  anything above it will honour it.
- **A second reachable path, found by IUX-032**:
  `IuxDestructiveActionController.action` is a **public getter** returning a
  descriptor that still carries `IuxConfirmBeforeExecution`. Handing it to a
  plain `IuxButton` reproduces the defect from inside the very pattern that
  exists to prevent it. IUX-032 closed the trap *locally* — its own descriptor
  is derived and never published, so a caller of `IuxDestructiveFlow` never
  holds a confirming descriptor — and said plainly that this is a local
  closure and not a fix.
- **FIXED, and the reverted attempt's own conclusion was wrong.** That attempt
  ended by saying the destructive trigger *cannot* strip, because "the policy
  must survive to the button". Measured: **nothing inside a button reads
  `confirmation`.** `IuxButtonResolver` does not, `IuxSemantics.action` does
  not, `isActivatable` does not — the field reaches no pixel and no
  announcement. The honourer is the *controller*, which keeps its own
  undisturbed copy and evaluates it with `confirmed: false`; the descriptor the
  trigger receives only has to describe the control, and the truthful
  description is "activating this does something immediately". What it does is
  open the question.
- **The shipped rule, both halves enforced**: an honourer strips before
  delegating, and anything that cannot present a question refuses one. Three
  callers changed — the public getter, the dialog's choices, the async
  controller's constructor *and* `updateAction`, because one guarded door is
  not a guard. The trigger needed no edit: it reads the getter.
- **Release behaviour is deliberately unchanged.** The check fires at build on
  the first frame rather than flipping `confirmed:`, because flipping it would
  turn a caller's mistake into a control that does nothing when tapped.
- **Proved by five deliberate breaks**, the largest telling: removing the
  dialog's strip fails **33 tests**, because that file's shared fixture *is* a
  destructive descriptor. And stripping on the way *in* rather than out fails
  ten or more — the strip must be outbound only.
- **Two residuals, documented rather than hidden.** `IuxFormSubmit.action` is
  caller-supplied and unconstrained, so a confirming submit is now diagnosed
  one layer late. And a trigger wired to the wrong callback still bypasses the
  pattern — no type can catch that, since the callback is the caller's own
  function.
- **Historical note**: the rule "whoever honours the policy strips it before
  delegating" was sound and half-adopted already, but making it enforceable
  needs a decision about *where* a policy is evaluated, not an assertion. That
  is design work, and it is recorded here rather than half-applied. The
  reverted attempt is on record so the next person does not spend the same
  hour discovering the same two callers.

### IUX-BUTTON-BUSY-002 — The focus loss was a conflation, proven then undone (FIXED)

- **Level**: standard
- **Scope**: every `IuxButton`
- **Sources**: WCAG 2.2 SC 2.4.3, SC 3.2.2
- **Status**: open, and now demonstrated rather than inferred. The *same*
  running action keeps focus under `repeatPolicy: allow` and loses it under
  `ignoreWhileInProgress`. Nothing about focus changed between the two — only
  whether a second tap would be accepted.
- **Measured reproduction**: three buttons, the middle one async. Tab, Tab →
  focus on "Pay". Enter → **focus jumps backwards to "Before"**. One Tab →
  lands on "After", skipping the running control. The operation completes and
  **focus is never restored**. The user resumes two controls away from where
  they were, having asked for none of it.
- **Not platform behaviour**: `ElevatedButton` drops focus on *disable* the
  same way, so the disabled case is Flutter's and is not the defect. Flutter
  has no equivalent for the busy case — a Flutter button never stops being
  focusable merely because work is in flight.

### IUX-BUTTON-DEAD-001 — Three public switches with nothing behind them (FIXED)

- **Level**: standard (PROJECT_PROMPT §19)
- **Status**: fixed at IUX-038, **all three removed rather than wired**, with
  the reasoning written where each field was: §20 names `elevation:` as the
  archetype a button must not take, and every other IUX surface rests
  hierarchy on colour; a `focused` token would have to be painted inside the
  container's own decoration, which is the SC 2.4.11 failure `IuxFocusRing`
  exists to avoid; and a result painted on the container is a colour-only
  signal (SC 1.4.1) that `IuxAsyncActionButton` already carries as a message.
- **The finding this entry did not have: `success` and `error` were not inert
  — they swallowed hover.** They sat *above* `hovered` in the precedence and
  returned the resting palette, so an idle filled button moves
  `#1560B0` → `#0F4289` on hover while a `succeeded` or `failed` one does not
  move at all. Removing them repairs an observable defect rather than merely
  deleting dead API.
- **Pinned mechanically**: `component_standard_test.dart` now asserts that
  every field of every `Iux*Tokens` class is read outside its declaring file.
  It rediscovered `elevation` independently across all eighteen token classes,
  and was proved by re-adding a dead field.
  - `IuxButtonTheme.elevateFilled` — `IuxButtonTokens.elevation` has zero
    consumers in the library. `true` and `false` produce byte-identical
    decorations while the resolver still reports `elevation > 0`. The theme
    asked for a shadow, got nothing, and was told nothing.
  - `IuxButtonTokens.focused` — neither call site of the resolver passes it,
    so it is false for every button ever built. The focus ring is real, but it
    comes from `IuxFocusable`; this field carries nothing.
  - `IuxButtonState.success` / `.error` — published with a documented
    precedence, but `_resolveColors` branches only on pressed/hovered. The
    decorations for idle, succeeded and failed compare **equal**, and the
    semantics node is identical.

### IUX-QA-VACUOUS-001 — Two tests that had never tested anything

- **Level**: standard
- **Status**: fixed, and each proven both ways by breaking the code.
  - *"a disabled button is skipped by focus traversal"* read
    `find.byType(Focus).first.canRequestFocus`. A `MaterialApp` puts **nine**
    `Focus` widgets in the tree; the button's own is the **last**, and the
    first is false regardless. The test passed with `canRequestFocus: true`
    hardcoded into `IuxButton` — **and so did every other test in the
    package**. The behaviour was entirely unguarded.
  - *"the glyph adds no second announcement"* asserted that a semantics label
    is found once. A second node would be *unlabelled* and therefore
    unmatched, so the assertion could not fail for the reason it named. It
    passed with `excludeSemantics: false` forced into `IuxSemantics.action` —
    exactly the change that creates the extra stop.
- **Both now fail under the same break.** A test that has only ever passed has
  not been shown to work.

### IUX-DISCLOSURE-001 — One rule enforced by a type, three by prose, and the docs say which

- **Level**: standard
- **Scope**: IUX-035 onward
- **Sources**: WCAG 2.2 SC 4.1.2, SC 2.4.3
- **Status**: implemented. Four rules are stated for what may never be
  disclosed — required input, an error or its cause, the way out, and
  cost or consent — and **exactly one is enforced by a type**. No widget can
  read a subtree and decide whether it holds a required field, and a guarantee
  that is a guess is worse than none, so the documentation says which is
  which rather than implying four.
- **What is enforced**: `IuxDisclosureState` is sealed as `collapsed` /
  `expanded` / `heldOpen`, so "collapsed while the content must be dealt with"
  is not constructible. Two booleans would have four combinations and one of
  them is the defect.
- **`heldOpen` removes the toggle and makes the summary a heading.** Three
  alternatives are refused in the docs: an ignored toggle announces "expanded,
  button" and does nothing; a disabled one leaves the Android focus order and
  says nothing about why; and letting the parent refuse reads as a stuck
  screen when the user asks for *less*.
- **Measured**: `expanded` lands on the same node as the name, checked in one
  call across label, button flag and expanded flag. Collapsed is
  `Tristate.isFalse`, not absent. `heldOpen` is `Tristate.none` with
  `isHeader: true` and no tap action. Hidden means **absent**, probed three
  ways — no `Offstage`/`Visibility`/`Opacity`, absent from the semantics tree,
  absent from the focus manager's descendants.

### IUX-DISCLOSURE-002 — No animation, and the absence is proved

- **Level**: standard
- **Scope**: IUX-035 onward
- **Sources**: WCAG 2.2 SC 2.3.3
- **Status**: implemented — the file imports the motion policy nowhere, and
  there is no parameter that could add one. Verified by asserting the content
  is complete after a single `pump()` with `transientCallbackCount == 0`, then
  again under `IuxMotionPreference.none`.
- **Reasoning beyond IUX-018's**: the child may contain **controls**, so
  animating means a hit box travelling while the user reaches for it; and a
  reveal interrupted by a second press leaves the semantics tree mid-flight.

### IUX-DISCLOSURE-003 — Accordion exclusivity refused, and with it the group widget

- **Level**: context_dependent
- **Scope**: IUX-035 onward
- **Status**: refused. Exclusivity closes content the user just found. Once it
  is gone a group has nothing left to coordinate — `Column`, `IuxSection` and
  `IuxContentGroup` already stack — so a group widget would be dead API (§19),
  and with the parent owning the state, exclusivity is one line for anyone who
  genuinely wants it.

### IUX-DISCLOSURE-004 — The disclosure control exists twice, and merging is worse (WONTFIX)

- **Level**: standard (PROJECT_PROMPT §19)
- **Status**: open, reported by IUX-035 and not fixed, since it does not own
  `lib/src/components/help/`. `_IuxHelpDisclosureControl` is
  `_IuxDisclosureControl` plus a leading help glyph — same
  `IuxSemantics.action(expanded:)`, same `IuxFocusable`, same opaque detector,
  same floor, same chevron, same decision to exclude the glyphs.
- **The right end state**: `IuxContextualHelp` composes the pattern and adds
  its glyph, which is about one leading-glyph parameter on the shared control.
  That parameter was **deliberately not pre-added**: a parameter with no caller
  is dead public API.
- **Why two widgets remain justified even after the refactor**: prose has no
  focus order, cannot be tabbed into, and cannot be left half-filled. A
  revealed form section is all three, and every guarantee specific to the
  pattern falls out of that one difference. `IuxContextualHelp`'s `help` being
  a `String` is what stops a help panel becoming a destination.
- **IUX-038 measured the two side by side and found no drift**: identical
  label, `expanded` tristate, `button: true`, `header: false`, one `tap`
  action, identical resolved label style; the rects differ only by the glyph's
  width. It then declined to merge them, with three reasons. The proposed end
  state **inverts the layer direction** — there are zero `components/` →
  `patterns/` imports today and eight or more the other way. Extracting
  downward leaves **eight fields** of the *exported* `IuxContextualHelpTokens`
  unread, which the new mechanical dead-token test would then fail on. And
  passing them through yields an eleven-parameter widget — the shape §20 names
  as bad — traded for forty lines of entirely private duplication.
- **Closed as wontfix on that evidence**, rather than left open to look like
  neglected debt.

### IUX-DESTRUCTIVE-FLOW-001 — Proportionality asks one question a caller cannot get wrong

- **Level**: hypothesis (graded as such deliberately, not as a finding)
- **Scope**: IUX-032 onward
- **Status**: implemented. The test is **"could the user list what they are
  about to lose?"** — not "how bad is it", which nobody answers consistently.
  `IuxDestructiveScope.items` covers a draft, forty-one selected photos, one
  person's access; `.everything` covers an account, a workspace, a folder and
  its contents.
- **Why the distinction decides the safeguard**: an undo offer only protects
  somebody who can *tell that they need it*. A user who deleted the wrong
  draft knows at once; a user who deleted an account cannot inspect what went
  and is usually already leaving the screen that carries the offer. So
  `everything` plus an undo offer is refused.
- **Two values, not four, and argued rather than hidden**: there are exactly
  two safeguards to allocate, so a four-rung ladder would have two rungs that
  changed nothing — dead public API under §19.

### IUX-DESTRUCTIVE-FLOW-002 — The way back is required, so its absence is a claim

- **Level**: standard
- **Scope**: IUX-032 onward
- **Sources**: WCAG 2.2 SC 2.2.1, SC 3.3.4
- **Status**: implemented. `IuxWayBack` is sealed and **required**:
  `IuxUndoOffer` or `IuxNoWayBack`, borrowing the `IuxUnrecoverable` idiom from
  the error pattern so that having no way back is something somebody stated.
  `IuxNoWayBack` means *no control this pattern can put in front of the user*,
  not "destroyed forever" — a trash folder is a consequence to state before the
  answer, not an offer to make after.
- **Refused in both directions**: an undo offer with a prompt asserts (it
  interrupts everyone *and* still leaves a control up), and no way back
  without a prompt asserts (the deletion nobody was protected from).
- **The framework imposes no undo window, so SC 2.2.1 is not engaged** — no
  time limit is set by the content. If the application commits on its own
  clock then the application created the time limit and inherits the
  obligation; at minimum it must dismiss the notice the instant the window
  closes, so the control never outlives the promise. No default ships, because
  five seconds means three different things to a sighted user, a screen-reader
  user three sentences behind, and a switch user.
- **Reused rather than invented**: IUX-021 had already decided that a
  transient message carrying an action gets no dwell at all, and again when a
  screen reader is expected. Verified from the timing and then behaviourally,
  by pumping sixty seconds with the undo control still present.
- **Limits, measured not assumed**: a second deletion destroys the first way
  back — there is one transient slot. This is the one place IUX-021's
  replacement rule costs the user something they needed, and where several
  destructions must each be reversible the way back belongs in a durable
  trash.

### IUX-PERMISSION-001 — Before and after cannot be confused, because they are different types

- **Level**: standard
- **Scope**: IUX-031 onward
- **Sources**: Android permission guidance *(to verify)*; EDPB deceptive-design
  guidelines *(to verify)*
- **Status**: implemented. `IuxPermissionMoment` is sealed:
  `IuxBeforeAsking({required ask, required decline})`,
  `IuxAfterRefusal({askAgain, required decline})`,
  `IuxSystemWillNotAsk({openSettings, required decline})`.
- **The one thing made unrepresentable rather than asserted**:
  `IuxSystemWillNotAsk` has **no ask parameter at all**. A control offering to
  request a permission the system will refuse to request produces nothing when
  pressed and reads as a broken app.
- **`decline` is required on all three**, and this is the loop-breaker rather
  than advice: the user always has a way out, and the parent always receives
  the refusal — the only signal an app gets that the user said no to *being
  asked*. A pattern with no such signal can only nag, because the caller has
  nothing to record.
- **Re-asking is permitted once, where the user came back.** Forbidding it
  would push every app that needs `shouldShowRequestPermissionRationale` out
  of the pattern, where nothing constrains them at all. Stated plainly in code
  and docs: **a parent that rebuilds this on every screen entry will nag, and
  no widget can stop it.**
- **The framework touches no platform.** Verified by parsing the source files
  rather than by inspection: every import must be `package:flutter/…` or
  relative, and code outside comments must contain no `MethodChannel`,
  `Platform.`, `dart:io`, `permission_handler`, `openAppSettings`,
  `requestPermissions` or `shouldShowRequestPermissionRationale`.

### IUX-PERMISSION-002 — Focus never moves, and the hazard is worse than a retry

- **Level**: standard
- **Scope**: IUX-031 onward
- **Sources**: WCAG 2.2 SC 4.1.3, SC 3.2.2
- **Status**: implemented. The live region is unconditional — a region that is
  empty may always have been, but **a request is an event by definition**, and
  a question nobody heard is not a question.
- **Why focus does not move, and why there is no hook**: focus arms the next
  Enter, and the armed control opens the **OS permission prompt**. A refusal
  the user never meant to give can close that prompt permanently. This is the
  fourth pattern to decide focus and the first where the cost is irreversible.
- **Refusal first in reading order**, so the way out is never past the request
  and the prompt-opening control is never under the first Enter. Both answers
  are real `IuxButton`s, and there is no parameter that draws the refusal as a
  grey link — **that asymmetry, not the wording, is the manipulation.**
- **SC 3.3.1 does not bind and the docs say so** rather than claiming it:
  nothing the user entered was rejected.
- **Measured, not assumed**: one Tab and one Enter run the refusal, not the
  request. The two controls **wrap to a second line** at 400 px with real
  labels, so the spacing test measures whichever axis they land on — behaviour
  documented rather than hidden.

### IUX-SEARCH-001 — Exactly one announcement per settled search

- **Level**: standard
- **Scope**: IUX-034 onward
- **Sources**: WCAG 2.2 SC 4.1.3; measured on the real semantics tree
- **Status**: implemented. Non-empty results get a **visible** status line
  that is also the live region; empty results get `IuxEmptyState`'s own live
  region and no status line, because the two together would say the same
  sentence twice. `arrival` is hardcoded and not configurable: a search result
  region is only ever reached by asking. The summary is a **function of the
  result**, not a string beside it, so it cannot go stale — and it is visible
  as well as spoken, so nothing essential rides on a live region the platform
  may decline to speak.
- **Measured**: a five-character undebounced query produces **ten** live
  regions — five "Searching…" and five counts. With one pause, two.

### IUX-SEARCH-002 — No debounce, and the reason a fixed interval is wrong

- **Level**: context_dependent
- **Scope**: IUX-034 onward
- **Sources**: WCAG 2.2 SC 2.2.1
- **Status**: no timer in either widget, consistent with IUX-030. SC 2.2.1 is
  satisfied by imposing no limit; a trailing-edge debounce sets none either,
  since it restarts per keystroke, whereas a fixed polling interval would.
- **The argument worth keeping**: a debounce tuned to a fast typist fires
  after **every character** for a slow one — and slow typists are
  disproportionately the screen-reader and switch-access population. Tune to
  the slow end, and prefer "the user stopped" to a fixed interval.

### IUX-SEARCH-003 — `SemanticsRole.comboBox` throws, so no suggestions ship

- **Level**: standard
- **Scope**: IUX-034 onward
- **Status**: measured, not assumed. On Flutter 3.44.8 `SemanticsRole.comboBox`
  **throws** `Missing checks for role SemanticsRole.comboBox` — the framework
  routes it to `_unimplemented` in `_DebugSemanticsRoleChecks`. It is unusable
  rather than merely silent, so a suggestion list could only ship with no role
  at all, and §19 forbids public API whose only effect is an unverified
  announcement. Pinned by a test, so the day Flutter implements it is visible.

### IUX-TEXTFIELD-GAPS-001 — Two gaps closed, one refused (FIXED)

- **Level**: standard
- **Scope**: `IuxTextField`
- **Status**: closed at IUX-038. `IuxTextContent.search` now maps to
  `SemanticsInputType.search`, and `onSubmitted` exists — but **no
  `textInputAction` parameter**: the action key is resolved from `content`
  (search → search, multiline → null, otherwise done), keeping the platform
  type out of the API exactly as the existing private extension already does.
  `onSubmitted` on a multiline field asserts, because its action key *is* the
  newline key, so the callback could never fire.
- **The trailing-control slot is refused, not deferred**: a control inside the
  box is a second interactive element inside a node announced as one text
  field, and the target floor settles it — a target meeting the minimum leaves
  too little of a small-screen field for text, and one that fits is below the
  minimum. IUX-034 reached the same conclusion from the other side.
  - No `textInputAction` and no `onSubmitted`, so a search that runs when the
    user presses the keyboard's action key **cannot be built** on it.
  - `IuxTextContent` has no `search` member, so `SemanticsInputType.search` is
    unreachable from any IUX field — the private resolution extension already
    maps every other member.
  - No trailing-control slot. Not a defect on its own, since IUX-034 argues a
    control *beside* the box is better than one inside it, but it is why the
    choice was not available to weigh.

### IUX-STEPPED-FORM-001 — Forward progress is never blocked, and no step can be locked

- **Level**: strong_guidance
- **Scope**: IUX-033 onward
- **Sources**: WCAG 2.2 SC 3.3.1, SC 3.3.3
- **Status**: implemented. This is IUX-012's disabled-submit rule one level up:
  a **step** that refuses is worse than a button that does, because the
  question at fault is not on screen. The guarantee moves to submit, where the
  summary makes every problem navigable.
- **`summary` is required here** where `IuxForm` allows null. `IuxForm`'s
  fallback — focus the first rejected field — is impossible when that field is
  unmounted, so without a summary a refusal would be invisible *and*
  unreachable.
- **The summary sits below the heading**, one position lower than in
  `IuxForm`, because focus lands on the heading at every step change and the
  summary must be the *next* stop. Above it, a user going back to fix one
  problem walks away from the list of the others.

### IUX-STEPPED-FORM-002 — Focus moves on a step change, and the exception proves the rule

- **Level**: standard
- **Scope**: IUX-033 onward
- **Sources**: WCAG 2.2 SC 2.4.3, SC 4.1.3
- **Status**: implemented. Focus lands on the step heading — one node carrying
  position, title and description together.
- **Reconciled against all four prior focus decisions with one test**: *did
  the user ask for this?* IUX-028, IUX-029 and IUX-030 do not move focus
  because the event happened *to* the user; IUX-012 moves it because the user
  pressed submit and is waiting. A step change is IUX-012's shape.
- **The exception**: arriving from a summary entry lands on the **field**, not
  the heading. The user asked for a box, not a lecture about a step.
- **No progress bar.** `IuxProgressIndicator` is a live region, so drawing one
  would put a second utterance in the same frame as the focus move — the exact
  failure `IuxValidationSummary` avoids by *not* being a live region. Position
  is one required function of step and count, so the two cannot drift.

### IUX-QA-VACUOUS-002 — A second test that proves nothing (FIXED)

- **Level**: standard
- **Scope**: `test/patterns/iux_form_test.dart`
- **Status**: open, found by IUX-033 in a file it does not own. *"An entry
  brings its field on screen"* still passes with `Scrollable.ensureVisible`
  removed from `IuxForm._navigateTo`, because **every field in that harness is
  an `IuxTextField`, which scrolls itself into view on focus**. `IuxForm`'s
  behaviour is correct; the test does not demonstrate it and would not catch
  its removal.
- **Measured**: a text field scrolls itself; a checkbox does not — 512 px down
  a 200 px viewport. The fix is to make one field in that harness a
  non-self-scrolling control, which is what IUX-033's own harness does.
- **Fixed at IUX-038** in the harness, not in `IuxForm`. Field two is now an
  `IuxCheckbox`; proved by commenting out `Scrollable.ensureVisible`, which
  puts the field bottom at 444 against a 200 px viewport.
- **A second vacuity surfaced while fixing the first**: at 200 px the summary
  entry sat at y = **−82**, and `tester.tap` only *warns* on a miss — so the
  first rewrite was measuring a form nobody had touched. The test now calls
  `ensureVisible` and asserts `hasPrimaryFocus` to prove activation happened.

### IUX-ONBOARDING-001 — Skip is required on every step, including the last

- **Level**: strong_guidance
- **Scope**: IUX-036 onward
- **Status**: implemented, borrowing IUX-031's `decline` and its reasoning
  wholesale: an onboarding a user cannot leave is a wall, and making the exit
  required is a structure rather than advice. Same derived descriptor —
  `dismiss` plus `secondary`.
- `finish` is an `IuxInlineFeedbackAction` rather than an `IuxFormSubmit`,
  because nothing commits here and there is therefore no busy state to model.

### IUX-ONBOARDING-002 — No dot row, and it was probed before being refused

- **Level**: standard
- **Scope**: IUX-036 onward
- **Sources**: WCAG 2.2 SC 1.4.1
- **Status**: refused. Probed rather than assumed: four decorated `Container`s
  produce a node with an **empty label and zero children**, so a dot row
  announces nothing at all. A position signal that only exists visually fails
  SC 1.4.1, and §19 forbids public API whose only effect is an unverified
  role. Same precedent as IUX-034 shipping no suggestions because
  `SemanticsRole.comboBox` throws.
- No auto-advance and no `PageView` either — SC 2.2.1 and SC 2.2.2 — pinned by
  reading the source back rather than by prose.
- Focus moves to the heading on a step change but **not on first build**: the
  user asked for nothing, which is the IUX-028 case. This is the sixth pattern
  to decide focus and the line held is still IUX-033's — *did the user ask?*

### IUX-ONBOARDING-003 — The heading is duplicated from the stepped form, measured (OPEN)

- **Level**: standard (PROJECT_PROMPT §19)
- **Status**: open, quantified rather than asserted. With comments stripped,
  `_IuxOnboardingHeading` is 51 code lines against `_IuxStepHeading`'s 58, and
  **40 of the 51 are byte-identical**. `IuxFocusable`,
  `Semantics(header: true)`, `IuxSemantics.decorative`, the position-first
  column, the join and `softWrap` are the same lines in the same order.
  `IuxStepPositionDescription` is the *same typedef*, imported rather than
  copied.
- **The whole difference is one field**: the guided form's optional
  `description` in supporting style against a required `body` in body style,
  because in onboarding the prose is the substance of the screen rather than a
  note above questions.
- **Why composition was refused, and defensibly**: `IuxGuidedForm` requires
  `IuxFormSection`s, `IuxValidationSummaryLabels` and `IuxFormSubmit`, so
  composing would invent a summary that summarises nothing — and every
  screen-reader user would be told about an error summary that can never have
  an entry.
- Consolidation starts at the two `_spoken` getters and needs edits to
  `iux_guided_form.dart`, which IUX-036 does not own.

### IUX-A11Y-REACH-001 — Two patterns lost their only control under scaling (FIXED)

- **Level**: standard
- **Scope**: `IuxEmptyState`, `IuxPermissionRationale`, `IuxSearchResults`
- **Sources**: WCAG 2.2 SC 1.4.4, SC 1.4.10; measured at 320 px
- **Status**: **open, and the most serious thing IUX-038 found.**
  - `IuxEmptyState` at 200%: the reset button lands at y 904–1008 against a
    640 px fold, `hitTestable = 0`, tap yields **zero** activations — and there
    are **no scrollables on the page**. It is the only control on screen.
  - `IuxPermissionRationale` at **150%**: decline taps, ask does not. **The
    user can refuse but cannot accept.**
  - `IuxSearchResults` at 200%: its only way out is off-screen, and *both*
    documented placements fail — the mandated bounded height clips, and a
    `SingleChildScrollView` makes the `ready` branch throw on unbounded
    constraints.
- **Fixed for `IuxEmptyState` and `IuxPermissionRationale`.** The block
  scrolls itself when, and only when, it is given a **bounded height**. One
  `LayoutBuilder`, `constraints.hasBoundedHeight` decides, no new parameter,
  no new public API.
- **Why that discriminator and not a flag.** It is not a heuristic — it *is*
  the question IUX-028 was asking. Every vertical scroll view in Flutter hands
  its children an unbounded height; that is what makes it a scroll view. So a
  block inside a caller's `ListView`, `SingleChildScrollView`,
  `CustomScrollView` or `IuxPage` sees unbounded height and adds nothing, and
  **IUX-028's rule now holds structurally rather than by convention**. A block
  given a bounded height was told the size of a box by something that will not
  scroll it — the dead-screen case.
- **The alternatives, rejected with reasons.** A `placement:` flag is the
  right behaviour by the wrong mechanism: a fact the constraints already state,
  restated as a parameter a caller can get wrong — and it fails in the case
  that matters most, because the caller who never read the docs is exactly the
  one who leaves it at its wrong default. Laying out so the control cannot
  leave the viewport needs shrinking text or pinning the control, and still
  fails at 300% where the *text* needs the scrolling too. An assertion would be
  a false-positive machine: unbounded-and-not-scrolling is a legitimate
  `Column` that fits.
- **Measured on 320x640.** Empty state reset button: unreachable at 200%
  (136 px overflow) and 300% (1016 px); now one scrollable and one drag away.
  Permission ask button: at **150%** the refusal takes its tap and the request
  does not — IUX-038's asymmetry reproduced exactly — and both tap after the
  fix. Scrollable count is **1** standalone and **1** inside all four nesting
  hosts. Never two.
- **IUX-QA-VACUOUS-003 was demonstrated rather than assumed**: with the fix
  removed, the same loop with and without the `SizedBox.shrink()` teardown
  catches the overflow at 200% either way, and **at 300% only with it**.
- **The lesson worth sweeping for**: the pre-existing "survives 200% text"
  tests in both files assert `findsOneWidget` on the control labels — presence,
  not reachability. That is the assertion the defect walked past.
  `findsOneWidget` is not evidence a control can be pressed.
- **Open follow-up**: the seven-line `LayoutBuilder` is duplicated across the
  two patterns because `lib/src/layout/` belonged to a concurrent mission, and
  `IuxSearchResults` has the same defect and will need the same shape — which
  would make three. It wants to be one layout primitive.

### IUX-QA-VACUOUS-003 — Two more, and the mechanism that makes them possible (FIXED)

- **Level**: standard
- **Status**: open. `iux_permission_rationale_test.dart` and
  `iux_empty_state_test.dart` both wrap the pattern in a
  `SingleChildScrollView`, which gives the `Column` unbounded extent, so
  `expect(tester.takeException(), isNull)` **cannot fail**. Rebuilt without it:
  `RenderFlex overflowed by 584 pixels`.
- **The methodology note is worth more than the two tests**:
  `DebugOverflowIndicatorMixin` reports a render object's overflow **once per
  lifetime**, so any loop that reuses the element tree and asserts
  `takeException()` is null passes vacuously after the first case. Insert
  `pumpWidget(const SizedBox.shrink())` between cases.
- Fifth and sixth vacuous tests found in this project.

### IUX-GUIDED-FORM-LIVE-001 — The collision it refused a progress bar to avoid (FIXED)

- **Level**: standard
- **Status**: open. `IuxGuidedForm` puts a live region in the same frame as its
  focus move — which is precisely the failure it declined to ship a progress
  bar in order to prevent.

### IUX-DESTRUCTIVE-FOCUS-001 — Cancelling drops focus to the page root (FIXED)

- **Level**: standard
- **Sources**: WCAG 2.2 SC 2.4.3
- **Status**: open. Cancelling a destructive confirmation costs four Tab
  presses to recover; Flutter's own dialog restores focus at cost zero.

### IUX-EXPAND-CRASH-001 — `expand: true` inside `IuxTargetSpacing` (FIXED)

- **Level**: standard
- **Scope**: `IuxButton`, `IuxTargetSpacing`
- **Status**: **open, found by the catalog putting the obvious call on screen.**
  Two stacked full-width buttons — the most obvious thing anyone writes —
  fails with *BoxConstraints forces an infinite width* at
  `iux_button.dart:417`, because `IuxTargetSpacing` is a `Wrap` on both axes.
- **The workaround costs the guarantee**: `Column` plus `IuxGap` works and
  gives up the 8 px target floor that `IuxTargetSpacing` exists to provide.
  Measured: bare 120x48 targets with `IuxGap(IuxSpacingStep.xxs)` come out
  **4 px** apart; `IuxTargetSpacing` comes out **8**.
- **Fixed**: `IuxTargetSpacing` now lays its two axes out with two different
  widgets. Horizontal stays a `Wrap`; vertical becomes a `Column`, which gives
  a bounded cross-axis width for `expand` to take.
- **The measurement that decided the shape is better than the crash it fixes.**
  The vertical `Wrap`'s wrapping **protected nothing and cost a target**. A
  page scrolls, so height is normally unbounded and a vertical `Wrap` never
  wraps at all; and where height *is* bounded it moved the overflow
  **sideways, in silence** — in a 320-wide box the third of three targets
  landed at x 256.8–388.5, **68 px off the right edge with zero exceptions
  reported**. An unreachable control no test could see. The `Column` reports
  `RenderFlex overflowed by 84 pixels` instead.
- **Alternatives rejected, argued in `docs/layout/overview.md`**: letting
  `expand` shrink-wrap under unbounded constraints removes the exception and
  keeps the trap (a mismatched 89 px / 132 px stack with no error); asserting
  the combination illegal leaves the caller on the arrangement that measurably
  goes under the floor; a dedicated stacking widget is the drift this
  primitive exists to prevent.
- `IuxButton.expand` now fails through a private `_IuxExpandedWidth` that
  names the way out, instead of a bare `SizedBox` and a line number.
- **A caveat worth keeping**: the 8 px between two `IuxButton`s is partly
  accidental — `IuxFocusRing` reserves 4 px of non-interactive padding per
  side. The floor only bites for targets without that padding, which is
  exactly where the 4 px workaround failure was measured. The guarantee is
  real; the button's headroom is a coincidence of a different feature.

### IUX-OVERLAY-001 — the scroll loss also disposed the opener (FIXED)

- **Status**: **closed.** The rebuild did not merely lose a scroll position: it
  **disposed** the panel that had been scrolled to, so its callback threw
  `setState() called after dispose()` on the very tap that answered the dialog.
  `IuxModalLayer` now keeps its `Stack` whether or not anything is open, so the
  page never changes depth and its element is reused. Measured on all three
  slots: disposals 1 → 0, inflations 2 → 1, scroll offset 0.0 → 400, exception
  → none. A second, unrecorded half is closed with it: the layer handed the page
  loose constraints while closed and tight `constraints.biggest` on open, so the
  page also re-laid-out every time.
- **Why it stayed open for fifteen missions, which matters more than the fix**:
  the entry said the known fix breaks `BlockSemantics`. It does not. IUX-027
  measured that with `find.bySemanticsLabel`, which reads
  `RenderObject.debugSemantics` — a per-render-object cache that keeps its last
  value for a subtree that stops being **visited** rather than being dirtied,
  which is exactly what a blocked page does. On the semantics tree the platform
  is actually given, and on `simulatedAccessibilityTraversal`, the covered page
  is absent under a permanent `Stack`, under a hand-rolled one, and under the
  conditional shape alike. **IUX-027 is withdrawn**, and with it the argument
  that accessibility outranked the ergonomics here — there was never a trade.
- **The rule this leaves**: an entry whose justification rests on a single
  measurement must name the instrument. Other `find.bySemanticsLabel` call sites
  survive elsewhere in the suite only because the pages behind their modals are
  still destroyed or genuinely absent; a sweep of the whole suite for this
  instrument is owed.
- **Limits**: measured in widget tests. The traversal is
  `simulatedAccessibilityTraversal`, not TalkBack on a device.

### IUX-PROGRESS-LABEL-001 — `valueLabel` is unchecked against `value` (FIXED)

- **Level**: standard
- **Sources**: WCAG 2.2 SC 1.1.1
- **Status**: **closed.** A percentage written in `valueLabel` is compared
  against `value` with a five-point tolerance; `%`, `٪`, `﹪` and `％` are read,
  with or without the space French puts in front. The parameter survives,
  because IUX still cannot compose a percentage — that is a locale decision and
  it belongs to the application.
- **Limits**: what is not inspected stays uninspected deliberately, because a
  false positive is worse than a miss — `3 of 7`, `12 MB of 40 MB`, non-ASCII
  digits (`\d` is ASCII-only in Dart, so no match means no claim), and any label
  carrying two percentages. A caller who computes the percentage wrongly and
  writes it out consistently is undetectable: both audiences get the same wrong
  number. It is an `assert`, so a release build has none of it.

### IUX-RAIL-OVERFLOW-001 — the rail could be wider than its own window (FIXED)

- **Level**: standard
- **Status**: **closed.** IUX-025's rule weighed *how much is left over* and
  never asked whether the rail fits at all, so a negative remainder failed the
  budget exactly as a small positive one did. The rule now carries a fit term.
- **What was measured**: re-measured as arithmetic rather than as one font — a
  landscape box *N* px narrower than the rail overflowed by exactly *N* without
  the term (36 → 36, 100 → 100) and by nothing with it. Across 25 windows × 7
  text scales, 21 cells flip rail → bar and 18 stop throwing, with every
  ordinary size unchanged. The "396 px against 360" originally recorded is the
  catalog's longer destination names; five short ones cost 354 at 300%.
- **Corrected with it**: an unbounded box is now refused by name, which
  `docs/components/navigation-rail.md` had claimed since IUX-025 without it
  being true. The charge that the old behaviour was *silent* was also wrong —
  one `SingleChildScrollView` produced 27 exceptions, the first a `RenderFlex`
  unbounded-height error reported against a `Column` the caller never wrote.
- **Limits**: a rail placed by hand still gets no IUX refusal and cannot get
  one — a `Row` lays out a non-flexible child against an infinite width, so the
  rail is never told the window it is in. The check is an `assert`, so a release
  build still falls through to the bar rather than throwing at the user.

### IUX-DRAWER-LABEL-001 — a longer dismiss label overflows, and text scale fixes it (FIXED)

- **Level**: context_dependent
- **Status**: **fixed**, and the measurement was worse than recorded. The
  header is now a slotted render object that measures the way out and keeps
  the shared line only while the heading still gets `min(one line, twelve
  characters)` — `IuxAppBar`'s rule verbatim, whose own comment already named
  `IuxReadableText.shouldStack` as the wrong tool for this decision.
- **What the re-measurement found**: 9.5 px at 360, 800 and 1200 confirms the
  corrected figure, but **34 px at 320**, which no entry mentioned — and in all
  four cases the heading box was **0.0 px wide**. The `Expanded` heading
  absorbed the entire shortfall before the row gave up, so the visible
  overflow was the smaller half of the defect.
- Zero overflow across all thirty-two cases after, and the heading is never
  narrower than the control beside it.
- **Still open elsewhere**: `IuxReadableText.shouldStack` decides the same kind
  of label-and-control arrangement in `iux_progress.dart` and
  `iux_bottom_sheet.dart`, unmeasured.
- Originally recorded: `dismissLabel: 'Close the menu'` overflows the drawer
  header by **9.5 px** — the 7.5 first recorded was measured on a different
  label — at **100%** text on 800- and 1200-wide surfaces, while
  `'Close'` does not — the panel caps near 280 px whatever the screen. It only
  stacks past about 130% text, so **enlarging the text fixes it and leaving it
  alone does not**. Pinned by a catalog test.

### IUX-FORM-FOCUS-001 — An accepted submission armed an unbounded focus move (FIXED)

- **Level**: standard
- **Scope**: `IuxForm`, `IuxGuidedForm`
- **Sources**: WCAG 2.2 SC 3.2.2
- **Status**: **open, and it answers the question IUX-033 thought it had
  settled.** `_handleSubmit` increments `_attempt`, but on the *accepted* path
  it never calls the focus move, so `_focusedAttempt` is never brought level.
  `_attempt != _focusedAttempt` is then permanently true, and **every** later
  `didUpdateWidget` carrying a rejected field moves focus.
- **Measured**: the user submits successfully, edits a field, tabs on, the
  parent answers the **blur** check — and the caret is ripped into the
  summary. The user asked for nothing.
- **Not a one-line fix**: hoisting the assignment does nothing, because the
  method is not called on that path at all; assigning it in `_handleSubmit`
  fixes this and breaks the deliberate *"a rejection that arrives after the
  submission still moves focus"* in both suites — verified by doing exactly
  that. It needs a bounded pending-submission window, which is a decision.
- **What this meant for IUX-033's reconciling test.** IUX-033 proposed *"did
  the user ask for this?"* as the single line behind seven independent focus
  decisions. Measured, five held and the two form patterns did not: the test
  was a good description of the intent and not of the code.
- **Fixed with a bounded pending-submission window.** Pressing submit opens a
  window in which a rejection may move focus. It closes on the first of: the
  failure being shown, **focus arriving in one of the form's own fields**, or
  — in `IuxGuidedForm` — a step change. `_focusedAttempt` became
  `_awaitingOutcome`; no new public API, no new parameter, no barrel change.
- **Only an arrival closes it, never a departure — and the first rationale for
  that was wrong.** The agent's draft claimed the submit gesture blurs the
  field; it probed that and found it **false**: `IuxButton` does not take focus
  on activation, and a focused `IuxTextField` keeps focus through the tap. The
  rationale that survives measurement is different — the window protects a
  caret in a box, you can only be in a box you arrived in, and a departure
  leaves the user at the enclosing scope with no caret to take, where a
  refusal that moved nothing is a refusal a screen-reader user is never told
  about.
- **The alternatives, rejected with reasons.** Elapsed time: the framework
  cannot see it and should not want to — a slow screen-reader user is not a
  different user, and a seconds-wide window moves focus for whoever was quick
  and refuses it to whoever was not. An outcome the parent reports: a window
  the parent closes is a window the parent can **forget** to close, which
  reinstates this defect silently. The next rebuild after submit: deletes the
  asynchronous case the window exists for.
- **Now measured across the whole library**: exactly **seven**
  `IuxFocus.request` call sites across nine patterns. Empty, error, loading,
  permission, destructive and disclosure have **zero**; onboarding has one
  behind a step guard; the two forms have the rest. Each of the seven has a
  test pinning its decision. **IUX-033's rule now holds seven of seven.** An
  eighth site exists that the table never counted — the search field's clear
  control — and it holds the rule too.
- **A find along the way**: `IuxGuidedForm` has consumed the pending attempt
  on a step change since IUX-033, with a comment explaining why, and **nothing
  measured it** — removing the line broke no test. Now pinned.
- **The residue, documented rather than hidden**: a submission the parent never
  answers keeps its window open, so a rejection arriving much later still moves
  focus. Right for someone still waiting, wrong for someone who walked away.
  The only fix is the parent-reported outcome that was argued against.

### IUX-API-DEAD-001 — Reachable API that nothing honours or reads (FIXED)

- **Level**: standard (PROJECT_PROMPT §19)
- **Status**: open, all measured across lib, test and apps.
  - **Two of four `IuxConfirmationPolicy` members are honoured by nothing.**
    `IuxConfirmByHold` on a plain `IuxButton` runs `onActivate` on the first
    tap. This is distinct from IUX-BUTTON-CONFIRM-001 — that is one honourer
    in four, this is **zero**.
  - `IuxActionDescriptor.importance` is stored, copied, compared and hashed
    and read by **zero** call sites: `high` and `low` render and announce
    identically. `role`'s only reads are two debug assertions, and
    `confirm`/`edit`/`select` are never constructed anywhere. The dimension
    table called `role` "used for semantics, feedback and pattern selection";
    measured, none of the three.
  - `IuxElevation` is an entire **exported enum with zero references**.
    Deleting it breaks nothing.

### IUX-API-NAMING-001 — One name for three things, and one thing under two names (FIXED)

- **Level**: standard (PROJECT_PROMPT §20)
- **Status**: open.
  - **`summary` names three unrelated types** — a `String` headline, a labels
    object, and a result-describing function. Same name, different meanings,
    which is the worst shape. Recommended: `headline` and `describeResults`.
  - **`IuxInlineFeedbackAction` and `IuxTransientAction` are field-for-field
    identical** — same three fields, same `effectiveSemanticLabel`, same
    equality. One type under two names, so moving a control from a banner to a
    snack bar means rebuilding it.
  - **`busyLabel` versus `busyHint` is an undiscoverable difference**: the
    hint only appends to the announcement, the label *also replaces the
    visible text*.
  - **`onDismiss` (four widgets) versus `onDismissed` (one)** — and
    `iux_transient_layer.dart` uses both spellings internally, which is how
    you can tell it is an accident.
  - **Sealed-type construction splits three to five**: three front their
    members with `const factory`, five expect the subclass name.
    `IuxConfirmationPolicy` is also the only sealed type *defaulted* rather
    than required — the one safety-relevant answer nobody has to give.

### IUX-038's eleven-parameter argument was weaker than it looked

- Across all 59 public widget constructors exactly one reaches eleven
  parameters — `IuxListItem.selectable` — and none of its eleven is a styling
  knob. §20's complaint is colour, elevation, radius and shadow; that
  constructor is content slots plus focus plumbing. IUX-038 cited "an
  eleven-parameter widget" as a reason not to merge the duplicated disclosure
  control; that particular argument does not carry the weight it appeared to.
  Its other two reasons — the inverted layer direction and the eight unread
  exported token fields — stand.

### IUX-TRANSIENT-COVER-001 — A notice made the navigation unreachable for four seconds (FIXED)

- **Level**: standard
- **Scope**: `IuxTransientLayer` composed with `IuxAdaptiveNavigation`
- **Sources**: WCAG 2.2 SC 2.2.1; measured on 360x800
- **Status**: **open, and the worst thing the pilot application found.** The
  transient layer must sit at page level while the navigation owns the frame,
  so the reading that follows from both doc pages pins every notice on top of
  the navigation bar — and the layer reserves **no layout space**. Measured:
  notice at y 712–760, destinations at y 740–786, **all three
  `hitTestable = 0`**. The dwell is a minimum of four seconds and by design
  cannot be shortened, so every "added" message costs the user their ability
  to change section.
- **Fixed by refusing the arrangement at build time.**
  `IuxTransientLayer.debugCheckNotPlacedOver` is called from
  `IuxBottomNavigation`, `IuxNavigationRail` and `IuxAdaptiveNavigation`; it
  walks ancestors and throws a `FlutterError` naming the caller's widget,
  carrying IUX-041's measurement and printing the corrected arrangement.
  Entirely inside an `assert`, so a release build carries none of it.
- **Why an ancestor test is the right test**: a message is painted over exactly
  the subtree the layer wraps, so a destination that is a descendant is one a
  message can cover and one that is not, cannot be. No configuration of either
  component changes the answer.
- **The alternatives, rejected with reasons.** Reserving the strip contradicts
  the component's central contract — a transient message is *defined by not
  occupying layout* — and would move the navigation bar 48 to 360 px under the
  user's thumb every time a notice appears: an unreachable target traded for a
  moving one. Exposing the notice height fails the §19 test outright, since the
  caller must first know a defect exists. A notice slot on the navigation
  cannot make the correct nesting the only expressible one, because
  `IuxTransientLayer` remains a public widget with a public `child`.
- **Measured, sixteen cases** across 320x640 and 360x800 at 100/150/200/300%,
  one line and wrapped: **3 of 3 destinations reachable at every scale**, each
  verified by a real tap reporting the right index. The same sixteen on the
  refused arrangement: **0 of 3 in six cases, 1 of 3 in two** — and no overflow
  exception in any of them, because the `Stack` clips the notice rather than
  reporting.
- **The exemption was found by the check, not designed in advance.** A
  `Scrollable` between the two ends the walk. The strict version broke four
  catalog tests, and inspection showed why: a navigation bar inside a gallery's
  `ListView` is a **specimen, not a frame**. A notice drifting over a demo bar
  costs a reader nothing, and a check that refused it would refuse every
  component gallery — including the library's documentation of itself. It is
  principled rather than convenient: a notice is pinned to the *viewport*, and
  scrolled content moves past that edge.
- **The hole that exemption leaves, recorded**: an application putting its
  *real* navigation inside a scroll view gets no warning. That arrangement is
  already broken more loudly, since unbounded height makes
  `IuxAdaptiveNavigation` pick the bar without measuring the window.
- **The cost this fix charges, stated rather than hidden**: the notice now has
  the page's height instead of the window's, so a long message runs off the top
  of its box earlier. What is lost is the top of a sentence nobody needed,
  against a navigation bar everybody does.

### IUX-APPBAR-PAGE-001 — Three defects in one composition (FIXED)

- **Level**: standard
- **Scope**: `IuxAppBar` composed with `IuxPage` — the most-repeated
  composition in any application
- **Status**: open, all three measured by IUX-041.
  - **Double top inset.** The bar's `SafeArea` removes the inset for its own
    subtree only, and the sibling page consumes it again. With a 40 px inset,
    content top lands at y 152 instead of y 112, and nothing asserts.
    `IuxPageInsets` cannot express the fix: `none` also drops the landscape
    side insets and there is no `exceptTop`.
  - **The chrome does not fit.** On 320x640 with three destinations:
    100% → 56 + 92 leaves 492; 200% → 120 + 240 leaves 280; 250% → 148 + 316
    leaves 176; **300% → 260 + 408 leaves −28**, and the frame overflows.
    `IuxBottomNavigation` documents its own degradation and takes its 408 px
    first. **No component owns the total.**
  - **The standard fix is unavailable.** Fill-viewport-or-scroll needs
    `IntrinsicHeight`, which throws because `IuxAppBar` uses a `LayoutBuilder`
    internally. **No IUX screen containing an app bar can take part in
    `IntrinsicHeight`, `IntrinsicWidth` or intrinsic `Table` sizing**, so the
    pilot had to scroll the whole screen and lose its pinned title at every
    text scale.

### IUX-SEARCH-RESULTS-001 — Unusable for a searchable list, two ways (FIXED)

- **Level**: standard
- **Status**: open. Its ready branch wraps the caller's list in an `Expanded`
  while `IuxPage` scrolls by default, so the first non-empty result throws
  *RenderFlex children have non-zero flex but incoming height constraints are
  unbounded*. The documented placement means giving up `IuxPage` — the only
  thing that knows the page insets and the reading width. And it hard-codes
  `IuxNoMatches` and **requires** a `reset`, so a collection that never held
  anything is reported as "no matches, clear the search" beside an empty
  search box. `IuxEmptyStateCause` exists precisely to keep those apart, and
  this pattern can express one of the four.

### IUX-LISTITEM-TRAILING-001 — Two components that only overflow together (FIXED)

- **Level**: standard
- **Sources**: WCAG 2.2 SC 1.4.4
- **Status**: open. `IuxListItem.tappable` with an `IuxStatusIndicator` in
  `trailingAction` on a 320 px screen: clean at 100% and 150%, **68 px over at
  200%, 214 px at 300%**. The row lays the trailing control out as a
  non-flexible `Row` child, so it takes its full intrinsic width and the
  `Expanded` holding the text absorbs a negative remainder. **Neither
  component overflows alone**, which is why no component test found it.

### IUX-A11Y-REACH-001 — refined by the pilot: the mitigation works, the default does not

- The two severe reachability defects (`IuxEmptyState` at 200%,
  `IuxPermissionRationale` at 150%) **did not bite the pilot application**,
  because both sit inside `IuxPage`, which scrolls. That is worth as much as
  the original finding: the documented mitigation is real, and the defect is
  that nothing makes it the default.

### The measured cost of composing no user-facing strings

- **99 declarations, 362 of 1889 `lib/` lines (19%), 113 literals, 2815
  characters** in the pilot application — its string file is its largest file.
- **The finding is the composition, not the total: 17 of the 99 never appear
  on screen.** They exist only for assistive technology or to satisfy an
  assertion. A developer who has not read the docs will not know they are
  owed, and no design mock contains them.
- Six had to be **functions** rather than constants, for counts and plurals.
- The decision remains right — an invented English "Back" shipped
  untranslated is worse — but the honest cost is that one control routinely
  costs one to six entries, and **the easiest to forget are exactly the ones
  only a screen-reader user would miss**. The framework's assertions are the
  existing mitigation; the gap is the strings no assertion can demand.

### IUX-PERF-001 — Opening a keyboard rebuilds 7.6x what Material does (FIXED)

- **Level**: standard
- **Scope**: `IuxAccessibility.of`, 34 call sites across 25 files
- **Status**: **open, and the only real performance finding.** It reads six
  platform values through `MediaQuery.of(context)`, which subscribes to
  **every** aspect of the media query.
- **Controlled A/B**, 20 identical widgets differing only in how they read the
  same six values: a keyboard change rebuilds **20 of 20** through
  `IuxAccessibility.of` and **0 of 20** through the aspect-scoped accessors.
  Same for a notch change and a rotation. Text scale rebuilds 20 of 20 either
  way, correctly.
- **On a realistic screen against the same screen in Material, tuned to the
  same 518 elements**: keyboard **106 vs 14**, notch 93 vs 6, rotation 122 vs
  30. Where IUX genuinely depends on the change it is level with or cheaper —
  text scale 132 vs 112, theme flip 132 vs 170. So the cost is precisely the
  rebuilds that cannot alter a pixel.
- **Fixed.** `IuxAccessibility.of` now reads each of the six values through its
  own aspect accessor. Measured after: the A/B goes **20 of 20 to 0 of 20** for
  keyboard, notch and rotation, and text scale stays 20 of 20 both ways —
  correctly, since it is the one change that must rebuild. On the realistic
  screen: keyboard **114 → 8**, notch 101 → 8, rotation 130 → 26, text scale
  140 unchanged. Material on the same screen is 14 / 6 / 30 / 112, so **three
  of four are now at or below it**.
- **Nothing observable changed**, verified rather than argued: 672 resolutions
  — seven theme cases × thirty-two platform-input combinations × three text
  scales — dumped before and after with sixteen values each including every
  derived getter, byte-identical. One honest caveat: `hashCode` had to be
  excluded, because `Object.hash` is seeded per run and differed between two
  runs of the *unchanged* code. That was checked, not assumed.

### IUX-PERF-002 — Resolvers are not hot, stated so nobody optimises them

- **Level**: standard
- **Status**: measured and closed. 200k calls each after a 20k warm-up, JIT on
  Linux x86-64: `IuxButtonResolver` **710 ns**, the slowest
  (`IuxNavigationDrawerResolver`) **1,557 ns**. A 60 Hz frame is 16,667,000 ns,
  so the worst resolver is **0.009%** of one. A column of fifty buttons
  rebuilds in 243 µs — about 2 µs per button, of which 0.7 µs is the resolver.
- Per-frame contrast maths does exist — two `computeLuminance()` calls for the
  scrim — and costs **37 ns**, which is 2.4% of the resolver that runs it,
  once per overlay. Nothing to optimise.

### IUX-LINT-001 — The rule the project relied on had never run

- **Level**: standard (PROJECT_PROMPT §35)
- **Status**: fixed. The root `analysis_options.yaml` raised the *severity* of
  `public_member_api_docs` without ever adding it to `linter.rules` — a no-op.
  The rule the project depends on for documented public API had therefore
  never executed. Turning it on surfaced **41 undocumented public members** in
  the foundations file alone, now written.
- The rule set went from 8 to **160**, the Flutter framework's own minus the 17
  measured to fail plus five. `prefer_is_empty` is deliberately excluded: a
  probe shows `assert(label.isNotEmpty)` in a `const` constructor fails, so the
  lint would take `const` off every widget that refuses an empty label.

### IUX-PUBLISH-001 — The package cannot be published, and the reason is not technical (RESOLVED)

- **Status**: resolved. The project owner chose **MIT**. `LICENSE` is now a
  real MIT licence at the repository root and in the package, and
  `dart pub publish --dry-run` passes with no errors — `repository` and
  `issue_tracker` now point at the GitHub project.
- **`publish_to: none` deliberately stays.** Being publishable and being ready
  to publish are different questions, and the answer to the second is still
  no: defects remain open in this file, and nothing has ever been validated on
  a real device with a screen reader.
- Also open: the package `CHANGELOG.md` says `0.1.0-dev.1`, the pubspec says
  `0.1.0-dev.9`, and the repository changelog says `0.1.0-dev.11` — three
  files and no two agreeing.
- Also open: **47 broken dartdoc references** in `lib/` that render as literal
  text on pub.dev.

### IUX-DISTINGUISHABILITY-001 — Choices that resolved to the same thing (FIXED)

- **Level**: standard (PROJECT_PROMPT §19, §20)
- **The rule**: *any two values a caller can choose between must produce a
  different resolved result; where they do not, either the API is lying or one
  of them is dead.* Nothing in 1978 tests asked this question — each test
  checked one configuration against its own expectation, and none compared two.
- **What it found**, all measured across four theme profiles:
  - `IuxActionIntent.tertiary` was identical to `secondary` in `outlined`,
    `tonal` and `text`, and identical to `text` in `filled`. Redefined from a
    statement about *weight* — which `IuxButtonVariant` and `importance`
    already make — to **an action that leads away from the task**: back, close,
    skip. That is the meaning `IuxAppBar`'s back control already declared and
    never received. Quieter by hue, never by contrast: lowest measured 6.31:1.
  - **`primary` and `secondary` were byte-identical in every unfilled variant
    on dark standard, high-contrast light and high-contrast dark.**
  - **A pressed filled `destructive` was byte-identical to a pressed filled
    `primary` in both high-contrast profiles** — a pressed "Delete"
    indistinguishable from a pressed "Save", in the profile whose entire
    purpose is separation, at the moment the user commits.
- `IuxActionColors.border` was **removed**: painted by nothing, measured by
  nothing, and set to the page surface itself in two of four profiles — while
  being the *sole* source-level difference between `secondary` and `tertiary`,
  so the file read as though they were distinct while every pixel was
  identical.
- `IuxButtonTheme.variant` was **removed** too. A single constant `filled` for
  all four intents meant the most ordinary button in the package — a plain
  descriptor is secondary — resolved to a fill equal to the page and an outline
  of width zero. Replaced by a derived default: intent says which containers
  exist, importance picks the rung. **A named `variant:` always wins or
  asserts** — deriving a default is not the same failure as discarding a
  request.
- Now permanent: `test/themes/button_distinguishability_test.dart`, 26 tests,
  every profile x legal intent x legal variant x interaction state, with the
  deliberate exclusions pinned and argued rather than left silent.
- **Applied again after IUX-042, and it found the rung the first sweep had
  excluded.** `IuxButtonState.loading` survived IUX-038's removal of `success`
  and `error`, and measured byte-identical to `enabled` in **68 of 68 cells**
  (four profiles × seventeen legal intent/variant pairs). Its cost was not the
  wasted name: it sat **above `pressed` and `hovered`**, so a running action
  whose repeat policy was still *accepting taps* answered neither the pointer
  nor the finger — `rest=#1560B0 hover=#1560B0 press=#1560B0` against
  `#1560B0 / #0F4289 / #0A2C63` idle. The rung is removed and engagement
  feedback now follows `IuxActionDescriptor.isActivatable`, the same predicate
  as the tap action and the gesture handlers, so the three cannot drift apart
  again. The exclusion that hid it was justified in the test by "the progress
  indicator the button swaps in" — there is no progress indicator in either
  button, and `IuxAsyncActionButton` documents at length why the busy state is a
  *word* rather than a spinner. **An exclusion needs the same evidence as an
  assertion.**

### IUX-LISTITEM-TRAILING-001 — the width fix bought its own defect on the other axis (FIXED)

- **Level**: standard
- **Sources**: WCAG 2.2 SC 1.4.4
- **Status**: closed on both axes. The trailing control was first laid out as a
  plain `Row` child and took its intrinsic width, squeezing the title to
  **2.8 px at 150%** and overflowing **68 px at 200%, 214 at 300%**. Capping it
  at the row's one-third share closed that and opened its mirror image.
- **The measurement that mattered was never the exception.** The 2.8 px title at
  150% was silent, with nothing thrown until 200%; a `takeException` assertion
  alone would have called 150% healthy.
- **The cap answered "how much may you have" and never asked "is that enough to
  be read".** The share is a fraction of the row and does not grow: **86 px** in
  the pilot's composition, **97.3** on a bare 320 px screen, at *every* text
  scale. `IuxStatusIndicator` reading one word has **min intrinsic = max
  intrinsic** — 180.25 px at 100%, 253.25 at 150%, 326.25 at 200%, 472.25 at
  300% — because a single word has no wrap point. Below its minimum the label
  breaks **inside the word**, one glyph to a line.
- **Measured under the cap**: control 116 px tall at 100% against a natural 36,
  286 at 150%, 376 at 200%, 556 at 300%. The row was **480 px tall without the
  status and 924 with it — 444 px for one word** — and in a bounded 320x640 box
  with no scrollable the pair overflowed **284 px on the bottom** where the row
  alone had 160 to spare.
- **The recorded "6 px residual at 300%" was never the row's.** It is
  `A RenderFlex overflowed by 6.0 pixels on the right` raised inside
  `iux_status_indicator.dart`: the glyph (60) plus its gap (8) is 68 against the
  62 px left inside the pill, so the label was laid out in a box **zero pixels
  wide** and painted outside it. The height was the symptom; an unreadable
  status was the defect. It also appears only at 286 px of row width — on a bare
  320 px screen nothing overflowed horizontally at any scale, which is why the
  two compositions must not be quoted as one, and the earlier record did quote
  them as one.
- **Fixed by using the share as the question rather than the answer.** The
  control keeps the line while what it asks for fits inside its third, and moves
  under the row's text when it does not — the rule the trailing *value* already
  follows, with the difference that a value gives way by wrapping and a control
  gives way by moving, because it cannot be re-wrapped without being destroyed.
  After: **no overflow on either axis at 100, 150, 200 or 300%**; row
  148 / 220 / 400 / 688 against 144 / 286 / 460 / 924; the cost of the status
  48 / 58 / 108 / 208 against 44 / 124 / 168 / 444; the title box in the pilot's
  composition 113.8 / 169.8 / 225.8 / 250 against 113.8 / 136 / 136 / 136.
- **Branching on the text scale was rejected on measurement.**
  `IuxAccessibility.prefersStackedLayout` is the obvious move and the one the
  trailing *text* uses, but it answers a question about the **user's** text size
  with a decision that depends on the **caller's** control: 86 px is short of
  180 at every scale, so it would have left **100%** broken.
  `IUX-DRAWER-LABEL-001` recorded the same finding, and the row now uses the
  same mechanism — a slotted render object that asks the control how wide it
  would like to be, where a `LayoutBuilder` can only report the room. As a side
  effect a row carrying a control can now answer `IntrinsicHeight` and
  `IntrinsicWidth`, which it could not before.
- **Also rejected**: an internal `Scrollable` behind `constraints.hasBoundedHeight`
  — the remedy that closed `IUX-A11Y-REACH-001` — because a row that scrolls
  inside itself hides the text it refused to truncate, nests a scrollable inside
  every `ListView`, and would have fixed neither the unreadable label nor the
  6 px clip; `IuxEmptyState` is a page-filling pattern and a row is not. Raising
  the cap to the control's minimum reopens the width defect, measured: title
  back to 2.75 px. Deciding on `getMinIntrinsicWidth` of the caller's control
  would be tighter, but intrinsics **throw** for any subtree holding a
  `LayoutBuilder`, and both `IuxTooltip` and `IuxAppBar` hold one — a layout
  that is occasionally taller beats one that can crash on a legal child.
- **A row that still does not fit says so.** At 300% the row is genuinely 688 px
  tall, and in a 640 px box with no scrollable it clips, draws the indicator and
  reports **48 px** (down from 284), naming the row and pointing at `IuxPage`,
  `ListView` and `SingleChildScrollView`. The clamp without the report would
  have made a previously-visible overflow silent, which is worse than the
  defect.
- **Limits**: the beside-or-below threshold is context dependent — a multi-word
  control that could have wrapped inside its third is moved below anyway. The
  property underneath it, that a control is never laid out narrower than it
  asked for while the row has room, is standard. And per B12, whether a control
  that has moved below the row's text still reads as a *second* target rather
  than as part of the row is unverified on a device: the geometry and the
  sibling semantics node are asserted, the perception is a hypothesis.
- **Independent corroboration, and a methodology correction it exposed**: the
  QuoiD'Neuf pilot's own accessibility bench (its task 22) first measured what
  looked like a violation of this entry's principle at 320×640, 200% text —
  two `IuxListItem` rows (no `trailingAction` involved; height came from
  `subtitle` wrap, a distinct cause reaching the same shape) at 552 px and
  592 px tall, bottoms landing at 744 and 784 against a 641 px fold. The
  instrument was the defect: the check compared `RenderBox.localToGlobal`
  against the viewport rectangle directly, the exact naive geometry this
  entry's own §"Also rejected" already argued against for a row taller than
  its viewport. Re-measured with `Finder.hitTestable()` — a real hit test at
  the row's centre, run after `Scrollable.ensureVisible` — both rows resolve
  centres at y=468 and y=488, comfortably inside the 640 px window, and both
  report `hitTestable: true`. The rows were reachable the entire time; only
  the rectangle comparison said otherwise. Two more rows on an unrelated
  screen (`a-propos`, 540 px and 492 px tall, same false rectangle failure)
  corroborate. **The lesson for anyone else writing a device-scale
  accessibility gate**: "does the target's full bounding box fit inside the
  viewport" is not the same claim as "can the user reach and press the
  target", and only the latter is the one that matters — a scrollable makes
  the former routinely false for perfectly honest content.

### IUX-MAP-001 — A map without its list equivalent is unconstructible

- **Level**: standard
- **Scope**: IUX map pattern onward
- **Sources**: WCAG 2.2 SC 1.1.1, SC 2.1.1, SC 2.5.1
- **Status**: implemented. `places` is required, the widget renders the rows
  itself, and **there is no parameter that hides them** — no `showList`, no
  `accessibleMode`, no `listBuilder` that could return something else. An empty
  round is refused, naming all four `IuxEmptyStateCause` members.
- **Why a described map is not the answer**: a `semanticLabel` says how many
  places there are and never which. A screen-reader user does not read a map;
  they read what is on it, in an order that serves them.
- **The trade that closes the loop, and neither half stands alone**: because
  the list is guaranteed, the map subtree is removed from the semantics tree
  outright. Hiding a map with no list would be a deletion; a list beside a
  half-announced map would be two competing accounts of the same places.
- **Rejected, argued in the doc**: a `semanticLabel` on the map; an optional
  `places` defaulting to none (the default *is* the failure); a shell plus a
  separate list the caller composes (composition can silently omit a half); a
  lint; documentation.
- **Peer, never a fallback.** The list is always on screen. A switch was
  refused because until it is found the default state is the one SC 1.1.1
  forbids; a draggable sheet was refused because dragging it open is a
  path-based gesture, so SC 2.5.1 gets *bought* rather than met.
- **The map yields; the list never does.** Two fifths of the height **divided
  by the text scale**, capped at 360, dropped below 120.
- **That division was forced by measurement, not chosen.** With a fixed share,
  at 300% on 320x640 the list had 304 px for rows whose titles alone are 144 px
  tall — **zero rows fully visible**, behind a 256 px map whose own street
  labels do not scale. The cost is recorded: the map vanishes over a cliff
  between about 200% and 210%.
- **Zoom**: `IuxMapZoom` is sealed with no default, so `IuxZoomFixed` is a
  claim somebody made — the `IuxNoWayBack` idiom. The controls sit **under**
  the map, never over it: a control floating over tiles has no determinate
  contrast ratio.
- **Markers, stated precisely rather than promised**: guaranteed is that every
  place carries a non-empty, non-colour ordinal, drawn in the list and
  announced before the name. Not guaranteed is that it was painted on the
  marker, its 3:1 against real tiles, its size or its position.

### IUX-MAP-002 — The first component whose visual half cannot be verified here

- **Level**: standard
- **Status**: **open by nature, not by neglect.** No test and no emulator draws
  a tile. Unverified and needing a device: that markers exist, sit where they
  should, carry the ordinal, clear 3:1 against real tiles and are hittable;
  that pinch actually zooms and that `IuxZoomFixed` is true when claimed; that
  TalkBack speaks the live region and when; **that hiding the map subtree is
  right against a real `GoogleMap`** rather than the single-node stand-in the
  tests use — a real SDK may expose nodes worth keeping, and this pattern
  removes them; that 128 px of map at 200% is usable; and the pan-versus-scroll
  drag conflict, which needs a platform view.
- **The strings are denser than anywhere else measured**: 9 of 18 public fields
  are caller-supplied strings, and **three of those nine never appear on
  screen**. A round of eight with every field supplied is 37 strings, three of
  them invisible to the developer testing the screen — against the pilot's 17
  of 99.

### IUX-RADIO-FOCUS-001 — A radio group's focus node had to land on a control

- **Level**: standard
- **Scope**: IUX-011 onward; closed after IUX-042
- **Sources**: WCAG 2.2 SC 2.4.3 (focus order), SC 4.1.2 (name, role, value);
  SC 2.4.7 for the destination argument
- **Status**: implemented, measured in `test/patterns/iux_form_test.dart`
- **What was measured**: `IuxRadioGroup` accepted no `focusNode`, so the node an
  `IuxFormField` handed over had `context == null` and `parent == null`. With a
  rule attached and the summary entry activated, `primaryFocus` stayed on the
  summary — focus did not land badly, it did not move at all — and
  `Scrollable.ensureVisible` was a no-op for the same reason.
- **The destination is the argued half**: the node attaches to the group's first
  option that can take focus, not to the group. A group is a question and a
  question is not a control; focusing the column would give a stop the user
  cannot act on, must leave again, and which carries no focus ring — trading an
  SC 2.4.3 failure for an SC 2.4.7 one. The first-option choice is
  **strong_guidance**, not standard: it follows the GOV.UK error-summary
  pattern, and no user testing was run here.
- **Limits**: the announcement on arrival is measured against Flutter's
  semantics tree, not against TalkBack on a device.

### IUX-FORM-DUPLICATE-STATE-001 — A field's descriptor and node were written twice

- **Level**: context_dependent
- **Scope**: IUX-012 onward
- **Sources**: none external; an API-design judgement
- **Status**: implemented — `IuxFormField.builder` replaces `child` and is
  handed the field itself, so `field.input` and `field.focusNode` are the
  objects the form uses rather than a second copy; `IuxFormSection` refuses in
  debug a field whose node is adopted by nothing, or by the neighbouring field
- **Limits**: only the *node* half is checkable. Nothing detects a caller who
  ignores `field.input` and builds a second descriptor, because the form never
  sees what the widget was passed — that half is closed by shape alone. The
  adoption check is debug-only: a release build gets the ergonomics and no
  check, since the alternatives are throwing at the user or a logging channel
  IUX does not have. Four pieces of caller state per validated field remain.

### IUX-LISTITEM-STATE-001 — The press tint did not tint the row, it covered it

- **Level**: standard
- **Scope**: `IuxListItem` since IUX-019; `IuxCard`, `IuxTabs`,
  `IuxBottomNavigation`, `IuxNavigationRail` and `IuxNavigationDrawer` still
  carry the same arrangement
- **Sources**: WCAG 2.2 SC 1.4.3 (contrast), SC 1.4.11 (non-text contrast);
  reported from a device by the QuoiD'Neuf UX audit of 2026-08-09, §P0.5
- **Status**: fixed for `IuxListItem`, measured in
  `test/components/iux_list_test.dart`, group *the six states a row can be in*
- **What was measured**: an `IuxListItem.tappable` rendered at one device pixel
  per logical one, counting the pixels it painted in `content.primary` — an
  exact count, because a glyph under `flutter_test` is a filled box. **8226 at
  rest, 0 while pressed, 8226 after release.** The title, the supporting line
  and the value were all absent for the length of every tap.
- **The cause is one line of paint order, and it was invisible in review.** The
  tint was the last child of the row's stack, so it painted above the content;
  every colour in this package is opaque, on purpose — `IuxStateColors` records
  why: an opacity over an unknown background has no predictable contrast ratio —
  and the resolver hands the layer an opacity of exactly 1 while engaged. A
  translucent overlay would have tinted. An opaque one at full opacity replaces.
- **The report from the device was "the line stays selected".** That is what a
  blank grey band looks like when the text that identified the row is gone, and
  it is why the audit filed it under selection rather than under press.
- **The fix is the layer moving below the content**, above the chosen
  background. The same opaque colour is then the row's background for the
  duration of the press — which is what the palette entry always described — and
  the state becomes measurable for the first time: text over a tint has a
  contrast ratio, text under a rectangle has none. Measured after the move, on
  all four profiles, the title clears 10.5:1 and the supporting line 6.5:1 over
  both tints.
- **Limits, and they are the load-bearing part.**
  - The five other components listed above still paint their state layer over
    their content, from the same tokens. `IuxCard` was read and carries the
    arrangement verbatim. None was measured here.
  - **`state.hovered` equals `surface.subtle` in all four profiles**
    (light `#F6F7F9`, light high contrast `#ECEEF2`, dark `#222834`, dark high
    contrast `#222834`), and `IuxListGroup` draws itself on `surface.subtle`.
    A hovered row inside a group is therefore byte-identical to a resting one:
    hover is not merely quiet there, it is absent. Not fixed here — the token is
    read by the button, the tabs, the rails, the drawer, the selection controls
    and the input theme, so moving it is a palette mission with its own
    four-profile re-measurement, not a side effect of a row fix.
  - Nothing here was seen on a device. The measurement is a pixel capture under
    `flutter_test`, which proves occlusion and contrast and proves nothing about
    how long a real tap holds the tint on a Pixel 7.

### IUX-LISTITEM-DISCLOSURE-001 — A row that opens a screen now says so, and only when asked

- **Level**: strong_guidance
- **Scope**: `IuxListItem.tappable`, additive
- **Sources**: WCAG 2.2 SC 1.3.3 (not by shape alone), SC 4.1.2; QuoiD'Neuf UX
  audit §P1.4 and §8
- **Status**: implemented as `IuxListItemDisclosure`, measured in
  `test/components/iux_list_test.dart`, group *a row that opens a screen says
  so*
- **The argued half is the default.** An automatic chevron on every tappable row
  needs no parameter and was rejected on a measurement: of the four
  `IuxListItem.tappable` call sites in the pilot application, three open a screen
  and one opens a browser. A chevron promises the screen the back button returns
  from, so on the fourth it would be a lie — and a mark that appears on rows
  leading nowhere is one users stop reading. It is therefore opt-in, and
  `IuxListItemDisclosure` deliberately has no value for "leaves the application":
  that would be a second glyph nobody has measured.
- **The cost is an eleventh parameter**, which made `IuxListItem.tappable` the
  second constructor to reach the arity `api_consistency_test.dart` guards. The
  argument is recorded in that test rather than here, because that list is where
  the next arrival will be weighed.
- **Excluded from the semantic tree**, and the exclusion is measured rather than
  asserted: the announced label and the number of stops below the row are
  identical with and without the mark. A named glyph *inside* the exclusion
  changes neither, and the same glyph outside it changes both — both directions
  are run.
- **Limits**: the chevron's 3:1 floor is measured against the four backgrounds
  the row can take, not against a caller's custom palette; and nothing here
  proves TalkBack stays silent on a real device, only that the tree it reads
  from has nothing to say.

## Deferred to later missions

| Subject | Mission |
| --- | --- |
| Visual feedback components (snackbar, alerts, loaders) | IUX-013 to IUX-015 |
| A lint enforcing that components read the runtime | Phase 5 |
| Per-intent action container roles, so tonal can express intent | unscheduled |
| ~~Distinct `surface.interactive`, so a read-only field differs by fill~~ | **done**, after IUX-042 — though fill still does not *carry* the distinction, and cannot: no two steps of the neutral ramp reach 3:1 |
| `IuxSemantics.field`, so a text field need not compose `Semantics` directly | unscheduled |
| A semantic role for text selection, currently inherited from Material | unscheduled |
| `IuxSemantics` helpers for checked/toggled/route/field, so components stop composing bare `Semantics` | unscheduled |
| A scrim role in the semantic layer, currently derived by luminance | unscheduled |

## Manual validation register

Not yet performed. None of the following is implied by the widget tests, and
none may be claimed until executed on real devices:

- TalkBack reading order and announcements;
- Voice Access target naming;
- physical keyboard and D-pad navigation;
- display scaling and large text;
- platform high-contrast and colour-inversion settings.

This was written before any component existed, as a commitment rather than a
backlog, and said it "becomes actionable from IUX-008 onward". **It became
actionable roughly forty components ago and nothing here has been performed
since.** It is the last release blocker (B12) and the only one that needs a
device rather than a decision.

The strongest argument for running it is not procedural. The library shipped
**no icons at all** for weeks — `uses-material-design` was undeclared, so every
Material glyph rendered blank — while 1976 tests passed over it, because
`flutter_test` substitutes a font that draws every glyph as a filled box
regardless of the pubspec. No test in this repository could have caught it, and
a person holding a phone caught it immediately.

### IUX-MATERIAL-GROUND-001 — Every layer that can be a route root now carries its own Material (FIXED)

- **Level**: standard
- **Scope**: IUX-001 onward; found by two consumer applications, fixed after
  IUX-043
- **Sources**: Flutter's own `_errorTextStyle` (`material/app.dart:45`), whose
  `debugLabel` reads *"fallback style; consider putting your text in a
  Material"*; WCAG 2.2 SC 1.4.3 (contrast), SC 1.4.12 (text spacing) — a screen
  rendered in the fallback style meets neither, and nothing in this repository
  measured that it was happening
- **Status**: implemented in `IuxMaterialGround`, applied by `IuxScreen`,
  `IuxPage`, `IuxModalLayer`, `IuxTransientLayer` and `IuxAdaptiveNavigation`;
  measured in `test/layout/iux_material_ground_test.dart`

**What was measured.** `MaterialApp` installs a deliberately hostile
`DefaultTextStyle` at the root — monospace, 48 point, double-underlined in
yellow — which `Material` is meant to displace. In an ordinary Material
application `Scaffold` does that, and a route whose root is not a `Scaffold`
never gets one. Every IUX component required that ancestor and none provided it;
`grep -c 'Material('` over `lib/src` returned zero.

Probed with each layer as the route root, reading `DefaultTextStyle.of(context)`
at the text itself:

| layer | its own content | the page it wraps |
| --- | --- | --- |
| `IuxScreen` | title: **fallback** | ok |
| `IuxPage` | **fallback** | — |
| `IuxModalLayer` | dialog title, message, dismiss label: **fallback** | ok |
| `IuxTransientLayer` | message: **fallback** | ok |
| `IuxAdaptiveNavigation` | every destination label: **fallback** | ok |

The three layers place their content as a **sibling** of the page in a `Stack`
or a `Row`, so a medium the page establishes for itself can never reach them.
That is why the fix could not stop at `IuxScreen`: a confirmation dialog in
monospace with yellow rules is the worst place this could have surfaced, and it
was still there after the first correction.

**Why documentation was the wrong instrument.** The contract was written down —
`IuxScreen` said in as many words that it was not a `Scaffold` replacement and
needed a `Material` ancestor. **Two consumer applications out of two got it
wrong.** That is not an error rate, it is an API result.

- One had four screens inside a chassis `Scaffold` and one pushed as its own
  route. That screen rendered yellow on the device. Its two widget tests passed
  throughout, because the test host supplied the `Scaffold` the route did not.
  The source comment asserting the invariant — *"the Scaffold is here and
  nowhere else"* — was true only of what sat **under** it.
- The other had five screens, each a route root, and no `Scaffold` anywhere in
  the application. Every screen rendered yellow, and it had **golden tests over
  all five**. The committed PNGs were pictures of the defect: under
  `flutter_test` every glyph is a filled black box, so a thin yellow rule
  beneath a black box reads as a style flourish. They were regenerated,
  reviewed by eye, and approved.

**The second case is the finding.** A golden suite is the strongest instrument
this class of defect can meet, and it recorded the defect as the expectation.
The same font substitution that hid the missing icons hid this — one level up,
and against a stronger instrument.

**The rule this adds.** *A contract that only documentation enforces is a
contract that measurement cannot see.* Where a component depends on an ancestor
it does not provide, either provide it or make its absence fail loudly; leaving
it to the caller means the failure surfaces as a rendering artefact, and a
rendering artefact is exactly what a harness is worst at seeing.

**The exclusion, and its evidence.** `IuxSection` still resolves against the
fallback when mounted alone, and deliberately: it is content, documented as
living inside an `IuxPage`, and is never a route root. The distinction drawn is
*can this be the outermost widget of a route* — not *does this contain text*.

**What it is not.** `MaterialType.transparency`: it paints no background,
absorbs no hit test and clips nothing, so the surface decision stays with the
semantic tokens rather than moving to `canvasColor`. A `Scaffold` above any of
these is still correct and still recommended — it owns the scaffold background,
the floating action button, the drawers and the snack bars. It is simply no
longer what stands between a screen and legible text.

**Nesting is accepted rather than avoided.** Composed, the five layers give five
transparent Materials. A conditional ground — one that checked for an ancestor
before inserting itself — was rejected without being tried: conditional
structure changes a subtree's depth, and `IUX-OVERLAY-001` is the record of what
that costs when it happens on a page.

### IUX-SELECTION-PRESS-001 — The suite could not see a control that no finger could use (FIXED)

- **Level**: standard
- **Scope**: the instrument, not one component. `IuxSwitch`, `IuxCheckbox` and
  `IuxRadioGroup` carried the defect; every component that redraws while it is
  held could have.
- **Sources**: reported from a device during the Terminus migration
  (systm-d/IUX#21); WCAG 2.2 SC 2.5.1 (pointer gestures), SC 2.1.1 (keyboard,
  which kept working throughout and is why the report said "the mouse works")
- **Status**: cause fixed in `c37a1e0`; the instrument closed here —
  `realTap` in `test/support/gestures.dart`, `COMPONENT_STANDARD.md` §18.1, and
  a per-component sweep in
  `test/components/press_feedback_sweep_test.dart` that checks its own
  completeness against `lib/src/`.

- **The cause, in one sentence.** `Container(color: …)` inserts a
  `DecoratedBox` only when the colour is non-null, so the first
  `onPointerDown` grew a box where there had been none, reparented the
  `GestureDetector` below it, and disposed the `State` holding the recogniser
  that was tracking the pointer. The `up` landed nowhere. Wrapping the colour
  in a `BoxDecoration` that is always present keeps the shape of the tree
  constant under the pointer.

- **What is registered here is the second half: why nothing saw it.**
  `tester.tap()` sends `down` and `up` with **no frame between them**. The
  rebuild that throws the recogniser away happens in that frame, so with no
  frame there is no rebuild and no defect to observe. The instrument did not
  miss the defect by bad luck; it could not represent it.

- **Measured, both directions.** With the cause reintroduced against the
  suite as it stands today: **4 tests of 2 332 fail** — the three in the new
  sweep, plus the single assertion in `iux_selection_test.dart` that goes
  through `realTap`. Of the 2 320 tests that existed *before* the fix,
  **none** fails. Every tap test written directly against the three broken
  controls passes with the controls unusable, including
  *the label is part of the target › tapping the text toggles the control*,
  which is the assertion whose whole subject is that a press reaches the
  control.

- **The sweep came back clean, and that is a finding rather than a
  formality.** All nine sources in `lib/src` that hold a `bool _pressed` are
  now exercised, through the twelve widgets they declare: `IuxButton`,
  `IuxIconButton`, `IuxFilterChip`, `IuxCard.tappable`,
  `IuxListItem.tappable`, `IuxCheckbox`, `IuxSwitch`, `IuxRadioGroup`,
  `IuxBottomNavigation`, `IuxNavigationRail`, `IuxNavigationDrawer`,
  `IuxTabs`. Twelve cases, twelve passes.

  Of the twelve, five had been *read* and judged sound when the cause was
  fixed, three were the controls the cause broke, and **four had never been
  looked at** — the two navigation strips, the drawer and the tabs. Those
  four are the reason this is a measurement rather than a restatement: they
  all compose their state layer as `DecoratedBox(decoration: BoxDecoration(…))`
  unconditionally, which is the shape that cannot lose a recogniser, but
  nothing established that before this file pressed them.

- **Limits.**
  - `bool _pressed` is a proxy for "rebuilds under a pointer", and a component
    could rebuild mid-gesture for some other reason — an incoming stream, a
    parent's animation — and lose its recogniser the same way. Nothing here
    watches that.
  - The remaining ~230 `tester.tap()` call sites in the suite were **not**
    converted. Each is subject to its own file's question, most of them about
    a target or a refusal rather than a response, and a blanket rewrite would
    have changed the settle behaviour of timing-sensitive suites
    (`iux_async_button_test.dart`, `iux_transient_test.dart`) for no signal
    the sweep does not already carry. The rule in §18.1 governs assertions
    about *response*; the sweep is what makes it structural.
  - `hold` defaults to 80 ms of test time, which is not 80 ms of a device.
    This proves a frame elapses, not that a real press on real hardware
    behaves identically. Nothing in this repository has still been validated
    on a device — see `IUX-MANUAL-001`.

### IUX-RADIO-LAYOUT-001 — The group had one shape, and its height made it unusable (FIXED)

- **Level**: strong_guidance
- **Scope**: `IuxRadioGroup.layout`, additive; the default is unchanged
- **Sources**: WCAG 2.2 SC 2.5.8 (target size), SC 2.5.5 (target size, enhanced);
  reported from a device during the Terminus migration (systm-d/IUX#21..#26,
  issue #22)
- **Status**: implemented as `IuxRadioGroupLayout`, measured in
  `test/components/iux_selection_test.dart`, group *a group can spend width
  instead of height*; sampled in `apps/catalog/lib/input_panels.dart`

- **The report.** `IuxRadioGroup` was tried on the six exclusive choices of one
  settings screen, then removed from the whole project after three attempts.
  Six groups of that shape pushed the section after them well below the fold.
  The application shipped a replacement built out of `IuxTapTarget`,
  `IuxSemantics.selection` and `IuxSemantics.radioGroup` — the IUX pieces,
  reassembled, because the component would not do it.

- **The diagnosis in the report is right, and it is worth restating.** The
  spacing was never the problem: `_SpacedColumn` applies 8 pixels, which is
  correct. What costs the height is the **48-pixel row each option reserves** —
  the guaranteed touch target — for a label 24 pixels tall. A 64-pixel step per
  option, 256 for four values. And there is no lever, by design:
  `IuxTapTarget.minimumSize` "only ever raises it"; `IuxDensity.compact`
  multiplies *spacings* by 0.875 and leaves the floor alone, taking 64 to about
  61. Both refusals are correct. The floor is the one number here that is not a
  matter of taste.

- **So the answer is not a smaller option, it is a second arrangement.**
  `IuxRadioGroupLayout.row` lays the options out with `IuxTargetSpacing` on the
  horizontal axis — the same primitive `IuxChipGroup` uses, a spaced `Wrap`.
  Measured at one device pixel per logical one:

  | options | width | stacked | shared line |
  | --- | --- | --- | --- |
  | `3 min` `5 min` `10 min` `15 min` | 400 | 276 px | **148 px** |
  | `3` `5` `10` `15` | 360 | 276 px | **84 px** |
  | seven weekday abbreviations | 360 | 468 px | **148 px** |

- **The spacing floor is kept, and that is a departure from the report.** The
  application's replacement lets its targets touch, justified on SC 2.5.8 being
  satisfied by size alone at 48 pixels. That is true of the success criterion
  and beside the point of the IUX rule, which exists because a finger landing
  near a seam has no margin whichever side it drifts to — and a shared line is
  the arrangement where fingers are closest together. Keeping the floor still
  delivers the whole saving, because what was being paid for was rows, not gaps.

- **Nothing else changes.** Same ring, same target floor at every density, same
  announcement — the option flags asserted for a shared line are the stacked
  group's expectations verbatim, so a screen-reader user cannot tell which was
  chosen. Options that stop fitting move to the next line rather than shrinking
  or clipping, which is what keeps this usable at 200% text: measured on a
  320-wide screen at twice the text size, the group wraps, reports no exception
  and stays inside its width.

- **Limits.**
  - **No compact mark.** A shared line saves height by using width and by
    nothing else. Selection carried by the outline and the fill, rather than by
    a ring in permanent reserve, would save more — and is the same question
    `IuxFilterChip` faces about its reserved checkmark slot (issue #23). It
    should be answered once for both rather than twice differently.
  - **Long labels are not refused.** A label long enough to wrap gives a ragged
    block in which no option owns an edge. There is no assertion, because the
    same words are short in one language and long in another and a run-time
    refusal would break the translation rather than the layout. Documented on
    the enum value and in `docs/components/selection-controls.md`.
  - **The widths above are an upper bound.** Under `flutter_test` every glyph is
    a square of the font size, so `10 min` measures six 16-pixel boxes. A
    proportional face fits more per line than any number here claims. Nothing
    was measured on a device — `IUX-MANUAL-001`.
  - Arrow-key traversal within a group is still absent, in both arrangements.

### IUX-CHIP-WIDTH-001 — The reserved slot cost half the usable width, undocumented (FIXED)

- **Level**: strong_guidance
- **Scope**: `IuxChipGroup.mark`, additive; the default is unchanged
- **Sources**: WCAG 2.2 SC 1.4.1 (use of colour), SC 2.5.8 (target size);
  reported from a device during the Terminus migration (systm-d/IUX#23)
- **Status**: implemented as `IuxChipMark`, measured in
  `test/components/iux_status_test.dart`, group *the reserved slot is a choice,
  and it has a price in width*; sampled in
  `apps/catalog/lib/status_panels.dart`

- **The report.** Three usages left `IuxFilterChip` for this reason alone — all
  of them short value scales (thresholds, intervals, days), which is precisely
  the case where reading the row at a glance was the point. The decision to
  reserve the checkmark slot is documented and correct; **its cost was not
  documented at all**, and an integrator met it by measuring a golden.

- **Measured here**, at one device pixel per logical one, standard density, no
  text scaling, on a 360-wide screen:

  | | `checkmark` | `outline` |
  | --- | --- | --- |
  | one-character label | 78 px | 56 px |
  | two-character label | 93 px | 65 px |
  | between two chips | 8 px | 8 px |
  | four two-character chips | 120 px, **two lines** | 56 px, **one line** |
  | seven two-character chips | 184 px, **three lines** | 120 px, **two lines** |

  The three-line result for seven chips reproduces the report exactly.

- **The counter-intuitive part, and the reason the report exists.** 22 of a
  one-character chip's 78 pixels are the reserved slot and the space before it;
  only 16 are the character. The slot does not scale with the text, so dropping
  a letter saves 16 pixels a chip and rarely a whole line — which is why the
  reporter tried three letters, then two, and gained nothing. It is asserted
  rather than described: the test proves the slot is worth more than a second
  character is.

- **The fix has two halves and the first is the one the issue asked for.**
  `IuxChipGroup` now carries the width budget in its own documentation, with
  the table above. `docs/components/badges-and-chips.md` repeats it where an
  integrator looks first.

- **The second half is `IuxChipMark.outline`**: no glyph and no slot for one.
  Selection is left to the fill, the outline weight and the announced state.
  **Nothing reflows** — the heavier outline was already drawn inside the
  padding rather than added to it, and with no glyph in either state there is
  nothing left to appear, so the guarantee the slot existed for holds without
  it.

- **It is set on the group, not the chip.** `chips` is a list of widgets the
  caller builds, so a per-chip parameter would permit a row with three chips
  reserving a slot and four not — a ragged left edge with nothing on screen to
  explain it. An inherited scope inside `IuxChipGroup` makes that
  unrepresentable; a chip outside any group resolves to the default, which is
  the stronger of the two.

- **Limits.**
  - **It gives up a signal, and that is why it is not the default.** Weight is
    not colour, so SC 1.4.1 still holds without the glyph — but a change of
    outline weight is quieter than a glyph appearing, and quieter for exactly
    the users the glyph was put there for. Documented on the enum value, in the
    component page, and in the catalog beside a standard row to compare
    against.
  - **56 pixels is still the floor for one character**, because the floor is
    the touch target rather than the content. Seven chips still take two lines
    at 360. Nothing here can go below `minimumTouchTarget` and nothing should.
  - **No third option was attempted.** A mark that kept a shape without holding
    a slot — a fill covering the whole chip, a rule under the label — would be a
    fourth visual language for "chosen" in a library that already has three, and
    it is the same open question `IUX-RADIO-LAYOUT-001` records about the radio
    group's ring. Both should be answered together or not at all.
  - The text widths are an upper bound: under `flutter_test` every glyph is a
    square of the font size. A proportional face fits more per line; the slot
    does not change. Nothing was measured on a device — `IUX-MANUAL-001`.

### IUX-PALETTE-HEADROOM-001 — The standard light profile had already spent the high contrast profile's room (FIXED)

- **Level**: context_dependent
- **Scope**: `IuxColorPalettes.light`, and the dark end of the caution ramp in
  `IuxPrimitiveColors`. Behaviour change for every application on the light
  standard profile.
- **Sources**: WCAG 2.2 SC 1.4.3 (AA, 4.5:1), SC 1.4.6 (AAA, 7:1); reported
  from a device during the Terminus migration (systm-d/IUX#24)
- **Status**: implemented; measured in `test/themes/theme_contrast_test.dart`,
  group *the two light profiles do different jobs*

- **The measurement that opens it.** Every chromatic content role in the
  standard light profile was past AAA on white: `content.link` and
  `feedback.info.content` at 9.72:1, `feedback.success.content` at 9.16:1,
  `feedback.warning.content` at 9.60:1, `feedback.error.content` at 9.69:1.

- **That cost two different things.** Structurally, `highContrastLight` had one
  rung left for the link — `accent30` to `accent20` — so the setting whose whole
  purpose is separation returned almost nothing, because the standard profile
  had already spent it. In use, the first report from a user shown the light
  theme was "the contrast is too dark, dark blue, dark green, dark red, it is
  too much": four roles darkened until they resembled each other more than
  their own meanings. **A semantic colour that no longer reads as its own hue
  has stopped being semantic**, which is the part a contrast test cannot see.

- **The fix is one rung on three ramps**: `accent40` (6.30:1), `positive40`
  (6.31:1), `critical40` (6.81:1) for `content.link` and for the feedback
  content and icon roles. Each feedback content is still measured on its own
  tinted surface, where it lands between 5.21:1 and 5.86:1 — AA with margin,
  short of AAA on purpose. `highContrastLight` sits at level 10 and is
  untouched, so its headroom goes from one rung to three.

- **The contract is now two-sided**, and this is the only place in the suite
  that asserts an *upper* bound on contrast: standard clears AA and stops short
  of AAA on every chromatic content role; high contrast clears AAA on every one
  of them; and high contrast measures strictly higher **role by role** rather
  than on average. `content.primary` is exempt and always will be — it is
  neutral, no second neutral can be confused with it, and it should be as dark
  as the surface allows in both profiles.

- **`action.secondary.foreground` stays at `accent30`, and that is forced.** On
  every unfilled variant that field *is* the intent: `IuxButtonThemeResolver`
  derives primary's accent from `action.primary.background` (`accent40`) and
  secondary's from this one. Moving it makes an outlined, tonal, text or icon
  secondary byte-identical to the same primary —
  `button_distinguishability_test.dart` reported **twelve collisions** when it
  was tried, which is how this is known rather than assumed. So the light
  palette keeps two accent text colours; `content.link` now matches the one an
  unfilled *primary* paints, which is the right neighbour.

- **The caution ramp needed a hue change, not a rung.** Held above 4.5:1 on
  white a yellow is not a yellow: `#5E3F00` and `#7D5400` measure 9.60:1 and
  6.69:1 and read as khaki browns. The consuming application had to leave the
  ramp entirely and pick `#A34A00` — 5.94:1, recognisable as a warning, and the
  convention public transport already uses. The dark end of the ramp is now that
  orange (`caution10` `#2E1200`, `caution20` `#4A2000`, `caution30` `#7A3700`,
  `caution40` `#A34A00`), keeping the darkness ordering and very nearly the
  ratios it replaces: 17.46, 14.02, 8.85, 5.94 against 17.37, 13.56, 9.60, 6.69.

  **The light end stays amber, and that is not an inconsistency.** `caution70`
  and `caution80` are content on *dark* surfaces and `caution90` is a tint on a
  light one; an orange bright enough to sit on `neutral90` drifts towards the
  critical ramp and stops being distinguishable from an error. The hue that
  reads as "warning" is not the same hue at every lightness, so the ramp bends.
  A test holds the bend: the warning content's hue must stay below 35° and sit
  measurably apart from the surface behind it.

- **Limits, and the first is the load-bearing one.**
  - **The upper bound is IUX's judgement, not a standard.** WCAG sets floors and
    no ceilings. "Stop short of AAA in the standard profile" is argued from what
    it costs the high contrast profile and from one user's report; it would be
    wrong for an application whose users mostly need AAA and will never open a
    settings screen, and that application should ship `IuxContrast.high` as its
    default rather than push the standard profile up.
  - **The caution hue rests on one report and one shipped application.** That
    `#A34A00` reads as a warning rather than as a brown is a judgement about
    perception; nothing here tests it, and hue is exactly where a contrast ratio
    says least.
  - **This is a visible change for every existing light-theme application.**
    Four content roles get lighter and one changes hue. It is additive to
    nothing: `IuxTheme.withSemanticColors` remains the way out, and the
    application that reported this had already used it.
  - Every ratio is the WCAG 2.x formula, which correlates imperfectly with
    perceived contrast. APCA would likely disagree. Nothing was seen on a
    device — `IUX-MANUAL-001`.

### IUX-APPBAR-BRAND-001 — A textual title alone pushed brand identity into the page (FIXED)

- **Level**: strong_guidance
- **Scope**: `IuxAppBar.brand`, additive; null by default and nothing changes
  for a bar that does not pass it
- **Sources**: WCAG 2.2 SC 4.1.2 (name, role, value), SC 2.5.3 (label in name),
  SC 1.4.4 (resize text); reported from a device during the Terminus migration
  (systm-d/IUX#25)
- **Status**: implemented, measured in `test/components/iux_app_bar_test.dart`,
  group *a brand mark, drawn where the title would be*; sampled in
  `apps/catalog/lib/navigation_panels.dart`

- **The report, and it was filed as a discussion rather than a defect.**
  `IuxAppBar.title` is a `String` on purpose: the heading a screen reader reads
  has to be text this component owns, and a free widget cannot play that part.
  The reasoning holds. What the report records is the friction it produced —
  an application migrating a bar that carried an **illustrated wordmark** (a
  glyph, a name set in two colours, a strapline) had nowhere to put it, so the
  wordmark went to the top of the page. The first screen then showed the name
  of the application **twice**, about ninety pixels apart, and the
  application's own UX audit filed that as a defect. It was one. The cause was
  here.

- **The rule comes first, and it holds with or without the parameter.**
  Identity does not belong in the page. A wordmark under the bar is not a
  placement, it is a duplicate, and the fix is to remove it. That sentence was
  missing from `docs/components/app-bar.md`, which explained why the title is
  textual and said nothing about what an application carrying an identity
  should therefore do. It is now there, and it is the half of this the reporter
  said was most missing.

- **The parameter does not reopen anything.** `brand` is drawn where the
  title's text would have been; `title` stays required and stays the announced
  heading. The exclusion is **structural rather than requested**:
  `IuxSemantics.header` already sets `excludeSemantics`, so nothing below that
  node reaches the tree. Measured with a mark built out of a deliberately
  labelled `Semantics` widget — the label is absent from the tree and the title
  string is what is announced.

- **The layout decision changes shape, and had to.** For a text title the bar
  compares the room left by the controls against a *readable fragment* — twelve
  characters — because a title that does not fit can wrap into narrower lines
  and still be words. A mark cannot wrap: it either fits beside the controls or
  it does not. `readableTitle` is therefore infinity when a mark is present, so
  the comparison is against the mark's own width and a mark that does not fit
  takes its own full-width line. Only a mark wider than the bar itself scales
  down, which is the last degradation available and is bounded. Both branches
  are measured, and so is the intrinsic protocol `IUX-APPBAR-PAGE-001` bought.

- **Limits, and the first two are real accessibility costs.**
  - **A mark does not grow with the text scale.** A user who enlarged their
    text gets a larger heading on every screen except the one carrying the
    mark. The bar hands the mark a box; what is inside is the caller's, and
    nothing here can reflow an image. Documented on the parameter, in the
    component page and in the catalog. **Where the name has to be legible at
    200%, the answer is to pass no mark.**
  - **Nothing verifies that a mark says what `title` says.** A logo reading
    "Acme" under a heading announcing "Orders" leaves a voice-control user
    asking for a control that is not there by that name (SC 2.5.3). The name is
    inside an image; the caller holds this.
  - **A strapline inside a mark is not the subtitle this component still
    refuses.** It is pixels the bar knows nothing about, and it carries none of
    the guarantees a second title line would have had. The refusal is unchanged.
  - The alternative design — a separate decorative slot beside the title, which
    is what the report proposed first — was not taken. It would have put the
    identity and the screen name side by side, which for the reporting
    application means the name of the application twice again, in a narrower
    strip. Replacing the text is what actually removes the duplicate.

### IUX-RESEARCH-GAP-001 — The charter required traceable research; the directory for it was empty

- **Level**: context_dependent
- **Scope**: the repository's claims about itself, and `research/`
- **Sources**: `PROJECT_PROMPT.md` §3 (*Evidence Informed*) and §8 (*Sources de
  référence*); reported during the Terminus migration (systm-d/IUX#26)
- **Status**: both halves done — claims aligned in `README.md` and
  `PROJECT_PROMPT.md` §8 and §17; `research/` seeded with a method and a
  five-question backlog; guarded by
  `test/package/research_test.dart`

- **What was measured, on this register.** Counted rather than asserted:

  | | count |
  | --- | --- |
  | entries | 156 |
  | at level `standard` | 74 |
  | mentioning a WCAG success criterion | 74 |
  | citing Nielsen Norman Group | 4 |
  | citing primary HCI or cognitive-psychology literature | **1** |

  Counted on `c37a1e0` — the commit the report was written against, and
  deliberately not a later one, so that entries added by this batch of work are
  not counted as evidence for it. The report's figure of 151 entries was right
  when it was written.

  **The report said zero, and one is the honest number.** `IUX-LOAD-001` cites
  **Miller 1968 and Nielsen 1993** for the ~0.1 s response-time threshold, in
  support and not against. It sits in that entry's prose rather than in its
  `Sources` line, which is why a search of the source lines alone reports none —
  and that is a finding about how this register is searched as much as about
  what it contains.

  What the correction does not change is the shape: one prose citation across
  156 entries, and **nothing at all** on reading rate, working-memory span,
  pointing law or visual search — the four this library's own rules would need.
  `Hick` appears **nowhere**; an earlier count of two was a case-insensitive
  search matching "thickness", which is the sort of mistake this entry exists to
  make less likely.

- **So the two claims are different claims.** What is delivered is a
  **conformance and semantics library, tested to an unusual standard** — every
  entry carries its level and its limits, which few libraries in this space
  manage. What is *also* claimed, in `PROJECT_PROMPT.md` §2 and in the README's
  opening, is that the framework produces interfaces that are **ergonomic**.
  Nothing in the register supports the second. A gap between an artefact and its
  own description is not a defect in either, until an integrator arrives looking
  for the thing that was advertised — which is what happened.

- **Both halves of the report were taken, and the reason is that they are not
  alternatives.** Aligning the claim without seeding the directory leaves
  `PROJECT_PROMPT.md` §8 naming three source families nothing uses. Seeding the
  directory without aligning the claim leaves the README promising what a
  backlog does not yet deliver.

  - **The claim**: the README now states plainly that the accessibility
    foundations are conformant and tested and that the ergonomics is an
    explicitly unsupported ambition, with the counts above. §8 marks its last
    three source families as ambition rather than practice. §17 records that
    **no component is anchored to a measurement** of any of the six things it
    asks components to reduce.
  - **The directory**: `research/README.md` is a working method — what counts as
    a source, in what order, and the rule that **a citation nobody has read is a
    lead, not a source** and may not enter a `Sources` line until somebody has
    read it. `research/hci/open-questions.md` works the five rules the framework
    enforces today on an argument alone.

- **Two findings came out of writing the backlog, and they are the part worth
  keeping.**
  - **`kIuxAppBarMaximumActions = 3` has no register entry at all.** It is
    enforced by an assertion — a fourth action throws — and argued only in a doc
    comment. It is the most enforced unregistered number in the framework. Its
    doc comment argues from *width*, and the bar already measures itself, so the
    better rule is available today with no literature: refuse the action that
    would take the title below its readable floor, which is right on a tablet
    and on a 320-pixel phone and is not the same number on both.
  - **`IUX-RUNTIME-006`'s 1.3× threshold needs no research either.** It is a
    measurement against the widths IUX supports — a test somebody could write in
    an afternoon. It has sat at `hypothesis` longest because nobody framed it as
    measurable.

- **Limits, and they are the honest part.**
  - **This closes the gap between the claim and the artefact. It does not close
    the gap the claim described.** `research/` now holds a method and a backlog;
    it holds no read primary source and no measurement. It is more than an empty
    directory and less than the research programme the name promises.
  - **Every lead in `open-questions.md` is unverified**, marked as such, and may
    not be cited by a register entry until read. That rule is deliberately
    stricter than the alternative — quoting a well-known result from memory —
    because half the value of such a result is knowing what it does *not* cover,
    and that half is only available to a reader.
  - **The guard is shallow on purpose.** `research_test.dart` checks that the
    directory is not empty and that no subdirectory is an empty promise. It
    cannot check that the contents are any good, and a test that pretended to
    would be worse than none.
  - The counts above are of this register only. They say nothing about the
    reasoning in doc comments, which is where a good deal of this framework's
    actual argument lives — `IuxTransientTiming` being the clearest example, and
    the reason Q1 exists.

### IUX-TAPTARGET-ACTION-001 — A named tap target announced a button and offered nothing (FIXED)

- **Level**: standard
- **Scope**: `IuxTapTarget`, and the scan that was supposed to be watching it
- **Sources**: WCAG 2.2 SC 4.1.2 (name, role, value); reported from a catalog
  sweep probing the semantics tree (systm-d/IUX#20)
- **Status**: fixed; measured in
  `test/accessibility/iux_runtime_widgets_test.dart`, group *IuxTapTarget*, and
  now caught structurally by `test/accessibility/announced_controls_test.dart`

- **The defect.** `IuxTapTarget` composed
  `Semantics(button: onTap != null, …, excludeSemantics: semanticLabel != null)`.
  The exclusion is necessary — an icon-only control has no text of its own, so
  the name has to come from the wrapper — and it takes the child
  `GestureDetector`'s tap action with it. The node announced "button, enabled"
  and offered nothing to activate, **in exactly the case the widget exists
  for**. A finger worked. A screen reader could not activate it at all.

- **The fourth time this one mechanism has deleted something.** `onTap` on every
  IUX button (IUX-005 to IUX-011), the focus state and `focus` action on eleven
  controls (`IUX-A11Y-FOCUS-001`), the `Focus` widget's own annotations, and
  this. The shape is identical every time: `excludeSemantics` is set to control
  the announced name, and it silently removes something the subtree was
  contributing.

- **The fix is one line**, and it is the same one `IuxSemantics.action` already
  carries: `onTap: enabled ? onTap : null` published on the node itself.

- **The check that should have caught it, and why it did not.**
  `announced_controls_test.dart` scans every bare `Semantics(` call and requires
  a node declaring a button to offer an activation. Its predicate matched a
  **literal** `button: true`. `IuxTapTarget` writes `button: onTap != null`, so
  the file was scanned and this call was never examined. The predicate now
  matches anything that is not a literal `false`.

  That widening is the durable half of this entry. **A computed button flag is
  the node most worth checking**, not the least: it is a button *sometimes*, and
  the sometimes is where the action goes missing. Run against the whole library,
  the wider predicate flags nothing else — so this was the only such site, which
  is a measurement rather than an assumption.

- **Verified in both directions**, three instruments. With the fix removed:
  the scanner fails on `iux_touch_target.dart` by name, and two behavioural
  tests fail — one on the announcement (`matchesSemantics` with `hasTapAction`)
  and one on the effect (`SemanticsController.tap`, which refuses a node
  offering no action, so it tests the announcement and the callback at once).
  With the fix, 2380 tests pass.

- **What was reported and deliberately not changed.**
  - **`IuxFocusable` answers Enter and Space only**, with no gesture recogniser
    and no tap action, so a region built from it alone cannot be pressed by a
    finger or by a screen reader. That is correct — focusability is not
    activability, and a focus ring that captured pointers would compete for the
    gesture arena with whatever it wraps. It was undocumented, which is why the
    probe reported it as a surprise; it is now documented on `onActivate`.
  - **`enabled` still publishes `hasEnabledState` even when `onTap` is null.**
    Tempting to derive control-ness from `onTap`, and wrong: `onTap == null` is
    both how a caller says "this is only a size guarantee" *and* how the same
    caller disables a control — `_IuxSelectionControl` writes exactly
    `enabled: _canActivate, onTap: _canActivate ? … : null`. Deriving from it
    would strip the enabled state off every disabled control in the library. The
    ambiguity is real and is recorded here rather than guessed at.

- **Limits.**
  - The six `IuxTapTarget` call sites inside `lib/` all pass `onTap` and **none
    passes `semanticLabel`**, so the exclusion never fired in-library and no IUX
    component was affected. This was a defect in the public API contract, met by
    callers — the catalog's Announcements "Refresh" control among them, which
    the catalog sweep correctly refused to frame as testable.
  - The scan reads source text with balanced-parenthesis extraction, not an
    analysis. A call assembled across a helper, or a flag passed through a
    variable declared elsewhere, is still invisible to it.
  - Measured on a semantics tree under `flutter_test`. That a screen reader
    then speaks and activates it on a device remains unverified —
    `IUX-MANUAL-001`.

### IUX-PALETTE-PERCEPTION-001 — The palette measured with instruments WCAG does not have

- **Level**: context_dependent
- **Scope**: measurement only. No shipped colour changed. Adds
  `test/support/perception.dart`, `test/support/perception_test.dart` and
  `test/themes/palette_perception_test.dart`.
- **Sources**: APCA-W3 0.98G-4g; Oklab (Ottosson, 2020); dichromacy simulation
  matrices (Machado, Oliveira & Fernandes, 2009). **All three are reproduced
  from secondary circulation and none of the primaries has been read by anybody
  working on this repository** — `research/README.md` is explicit that this
  makes them leads rather than sources, so what the numbers below actually rest
  on is `perception_test.dart`, which checks each instrument against a property
  of the algorithm itself before any measurement is allowed to use it.
- **Status**: implemented; 10 assertions, all passing, in
  `test/themes/palette_perception_test.dart`. Full suite: 2405 tests pass.

- **Why.** `theme_contrast_test.dart` holds every pair to its WCAG 2.x floor and
  the palette passes. Two questions that floor cannot answer had never been
  asked. First: is a light role and a dark role tuned to the *same ratio*
  equally legible? WCAG's formula is symmetric — a ratio reads the same in
  either direction — so by construction it cannot tell dark-on-light from
  light-on-dark. Second: can two roles that both pass be told apart *from each
  other*? Nothing in WCAG measures the distance between two foregrounds, which
  is exactly the measurement `IUX-PALETTE-HEADROOM-001` needed and did not have
  when it recorded a user saying four roles "resembled each other more than
  their own meanings".

- **Finding 1 — WCAG orders the palette correctly and sizes it wrongly.** Inside
  a single polarity the two metrics rank the content roles identically, in all
  four profiles; that is asserted, and it means reading ratios is a sound way to
  order a palette. Across polarities they diverge sharply. `border.standard` is
  tuned to 3.67:1 in light standard and 3.65:1 in dark standard — a deliberate
  match, the same role equally quiet in both — and delivers **Lc 64.3 against
  Lc 27.2**. The same ratio buys under half the perceived contrast when it is
  read light-on-dark. `content.disabled` shows the same split at the same rung.

- **Finding 2 — a dark control outline clears SC 1.4.11 and sits under the
  perceptual floor.** `border.standard` and `border.interactive` are the
  outlines that identify a control. In dark standard both measure 3.65:1,
  clearing the 3:1 of WCAG 2.2 SC 1.4.11, and both land at Lc 27.2 — under the
  Lc 30 APCA treats as the minimum for a solid non-text element, and far under
  the Lc 45 it asks for a one-pixel line. The light profile puts the same roles
  past Lc 64. **This is a shipped defect and it is recorded rather than fixed**:
  the ramp rung is shared, and the last time a rung was moved on an argument
  `button_distinguishability_test.dart` reported twelve collisions. The
  candidate is `neutral45` (4.75:1, Lc 36.0 on `surface.base`; 4.02:1, Lc 33.9
  on `surface.subtle`), which clears the floor by the smallest step available;
  `neutral40` (6.62:1, Lc 49.2) clears it comfortably but is the rung
  `content.tertiary` already holds. Choosing between them is a design decision
  with the blast radius of a palette change, and it is deliberately left open.
  `test/themes/palette_perception_test.dart` asserts the defect as it stands, so
  that changing the ramp fails loudly and sends the next reader here.

- **Finding 3 — colour does not separate the feedback categories, and the glyph
  is not a nicety.** Pairwise Oklab distance between the four `feedback.content`
  roles, re-measured under each dichromacy (×100 scale; about 2 is the smallest
  difference most people notice with two colours side by side, and roles glanced
  at across a screen need tens):

  | profile | worst pair | normal | measured |
  |---|---|---|---|
  | light standard | warning/error under deuteranopia | 8.7 | **2.2** |
  | light high contrast | warning/error under deuteranopia | 4.4 | **1.1** |
  | dark standard | success/error under deuteranopia | 18.9 | **1.5** |
  | dark high contrast | success/error under deuteranopia | 11.1 | **0.4** |

  Success and error, the pair whose confusion costs the most, under the most
  common dichromacy, are **0.4 apart in the dark high contrast profile** — the
  same colour. `IuxFeedbackRoleColors` already documents that "a component must
  always pair these colors with an icon, wording, or screen-reader semantics".
  These are the numbers that make that sentence load-bearing rather than
  cautious, and `palette_perception_test.dart` now asserts the glyphs are
  distinct rather than trusting a doc comment.

- **Finding 4 — the shape channel is weakest exactly where the colour channel
  fails.** `_glyphFor` is documented as "four shapes, not four colours: a
  circled 'i', a circled tick, a triangle and a circled '!'", and reasons that
  "a user with deuteranopia distinguishes the triangle from the circles". True,
  and it names the wrong pair. **Three of the four glyphs are circles.** The
  pair colour fails hardest on — success against error, 0.4 apart — is a circled
  tick against a circled exclamation mark, differing only in the mark inside a
  shared silhouette at icon size. The message text and the live-region label
  still carry the category, so this is not an SC 1.4.1 failure; it is a
  redundancy that is thinner than the comment claims. Giving `error` a distinct
  silhouette, or dropping the circle from `success`, would cost nothing and is
  proposed rather than taken here.

- **Finding 5 — in both dark profiles the four feedback surfaces are one
  colour.** Pairwise distance 0.0 on all six pairs. The tint channel does no
  work at all in dark, so the whole burden falls on content colour (Finding 3)
  and the glyph (Finding 4).

- **Limits.**
  - Three algorithms transcribed from memory of secondary circulation. The
    verification tests check properties — APCA's two published extremes and its
    asymmetry, Oklab's behaviour on the sRGB primaries and along a grey ramp,
    each dichromacy matrix leaving a neutral untinted and collapsing its own
    chromatic axis while sparing the others — which catches a transposition, not
    a decimal.
  - The APCA thresholds quoted in Finding 2 (Lc 30 solid non-text, Lc 45 fine
    line, Lc 75 body text) are recalled from the APCA readability criteria and
    are **not** reproduced by any instrument here. They are why the numbers are
    interesting; they are not themselves measured, and no test asserts against
    them.
  - Dichromacy simulation models the three complete dichromacies. Anomalous
    trichromacy — much more common than dichromacy — is not modelled, and its
    separations lie somewhere between the "normal" and "measured" columns above.
  - Every measurement is of a colour pair, not of a rendered screen. Type size,
    weight, anti-aliasing, ambient light and display calibration all move real
    legibility and none of them is here. `IUX-MANUAL-001` still stands.
