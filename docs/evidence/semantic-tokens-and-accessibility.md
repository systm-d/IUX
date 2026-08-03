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

### IUX-A11Y-FOCUS-001 — Every IUX control is missing its focus semantics (OPEN)

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
- **Deferred deliberately**: the fix belongs in `IuxSemantics.action`, which
  every component depends on, and it was found while two missions were live in
  the same tree. Changing the shared foundation mid-wave trades a known defect
  for an unknown one. Scheduled as the first item of IUX-038, which is the
  accessibility audit.

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

### IUX-BUTTON-BUSY-001 — A running button is announced as unavailable (OPEN)

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
- **Scheduled with IUX-A11Y-FOCUS-001** in one pass: same file, same class of
  defect, and IUX-008.9's audit is strengthening the button tests right now —
  those tests are the safety net the fix should land against.

## Deferred to later missions

| Subject | Mission |
| --- | --- |
| Visual feedback components (snackbar, alerts, loaders) | IUX-013 to IUX-015 |
| A lint enforcing that components read the runtime | Phase 5 |
| Per-intent action container roles, so tonal can express intent | unscheduled |
| Distinct `surface.interactive`, so a read-only field differs by fill | unscheduled |
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

Components do not exist yet, so this is a commitment rather than a backlog. It
becomes actionable from IUX-008 onward.
