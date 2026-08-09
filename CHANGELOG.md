# Changelog

The version in `packages/iux_flutter/pubspec.yaml` decides; the heading below
repeats it. See CONTRIBUTING.md, "Versioning".

## Unreleased

### `IuxListItem` painted its press tint over the row instead of behind it

**Behaviour change, and the reason to take this build.** An interactive row drew
its press and hover tint as the topmost layer of its own stack. Every colour in
this package is opaque — `IuxStateColors` records why — and the resolver hands
that layer an opacity of exactly 1 while the row is engaged. So the tint did not
tint anything: for the whole length of every tap it replaced the row with a
blank rectangle. Measured by counting the pixels the row painted in
`content.primary`, at one device pixel per logical one: **8226 at rest, 0 while
pressed, 8226 again after release.**

The layer now sits below the content and above the chosen background. The same
colour is the row's background for the duration of the press, which is what the
palette entry always described.

**It was reported from a device as "the row stays selected".** That is what a
grey band reads as once the text identifying the row is gone, and it is why the
report arrived filed under selection rather than under press. A row that opens a
screen has no selection to persist and never had one; nothing about selection
changed.

**The same arrangement is still in five other components** — `IuxCard`,
`IuxTabs`, `IuxBottomNavigation`, `IuxNavigationRail`, `IuxNavigationDrawer` —
and none was measured here. See `IUX-LISTITEM-STATE-001`.

Callers need change nothing.

### `IuxListItem.tappable` can show that it opens a screen

`disclosure: IuxListItemDisclosure.opensScreen` adds a chevron after the row's
value, excluded from the semantic tree because the row is already announced as a
button. It is **off by default**: of the four tappable rows in the pilot
application three open a screen and one opens a browser, and a chevron promises
the screen the back button returns from. Only the caller knows which it is.

There is deliberately no value for "leaves the application". Additive; a row that
names nothing is drawn exactly as before.

### Every layer that can be a route root now provides its own `Material`

**Behaviour change, and the reason to take this build.** `IuxScreen`, `IuxPage`,
`IuxModalLayer`, `IuxTransientLayer` and `IuxAdaptiveNavigation` each establish a
transparent `Material` around their own subtree. Until now they required the
caller to supply one — `Scaffold`'s job in an ordinary Material application — and
a route whose root is not a `Scaffold` never has one. Text in that position
resolves against the style Flutter labels *"fallback style; consider putting your
text in a Material"*: monospace, double-underlined in yellow.

**Two consumer applications out of two shipped a build with it.** One on the
single screen it pushed as its own route; one on all five of its screens, with no
`Scaffold` anywhere. Neither test suite could see it, and one of them was a
**golden suite over all five screens** whose committed PNGs were pictures of the
defect — under `flutter_test` every glyph is a filled black box, so a thin yellow
rule beneath a black box reads as a style flourish. They were reviewed by eye and
approved. The same font substitution that hid the missing icons hid this, one
level up and against a stronger instrument.

The fix could not stop at `IuxScreen`. The three layers place their content as a
**sibling** of the page, so a medium established inside the page never reaches
them: with the first correction in place, a dialog's title, message and dismiss
label still rendered in the fallback style. Each addition here is backed by a
measurement, tabulated in `IUX-MATERIAL-GROUND-001`.

**What this does not change.** `MaterialType.transparency` paints no background,
absorbs no hit test and clips nothing, so surface colour stays with the semantic
tokens. A `Scaffold` above any of these is still correct and still recommended —
it owns the scaffold background, the floating action button, the drawers and the
snack bars. It is simply no longer what stands between a screen and legible text.

Callers need change nothing. A route root that was already correct stays correct;
one that was not now renders.

## 0.2.0-dev.3 — IUX-043

Three chart primitives, and the first painting code in the package.

- `IuxLineChart` — one or more series over an axis, optionally against a
  reference band, with screen-reader stops laid over the stretch they describe.
- `IuxBarChart` — horizontal bars, one per row. No vertical arrangement, on
  purpose: columns collide at 200% text and the usual fixes break the chart for
  the reader who enlarged it.
- `IuxSparkline` — a trend small enough to sit beside the number it is about.

`semanticsSummary` is required on all three. A chart with no text alternative
does not exist for a screen-reader user, and the gap is invisible at review
time; making it a parameter is the only version of the rule that cannot be
forgotten.

Two series may not share a stroke pattern, which caps a chart at three. The
pattern is the channel that survives a monochrome screen, and two series sharing
one are a single line drawn twice for a large share of readers.

Known limits, all documented in `docs/components/chart.md`: no interaction, no
height parameter, non-negative bars only, the right-to-left mirroring is a
decision rather than a standard, and nothing here has been looked at on a
running screen.

### Also on this branch, and not part of IUX-043

Two workstreams shared a working tree while this mission ran, and a broad
`git add` merged them: **the commit `754c4fe` ("IUX-043: IuxLineChart, band and
all") also contains `iux_list_item.dart` and `iux_list_test.dart` in full**, and
a later chart commit carries the list panel in `apps/catalog`. Nothing was lost
and everything is tested, but a reader looking for the reasoning behind the list
change will not find it in the message above it. It is here instead.

- **`IUX-LISTITEM-TRAILING-001` is closed on both axes.** Bounding the trailing
  control to the row's one-third share had closed the width overflow (214 px at
  300% down to 6) and opened its mirror image on the other axis, which nothing
  recorded until a read-only audit measured it. The share is 86 px and does not
  grow with the text, while an `IuxStatusIndicator` reading one word has a
  minimum intrinsic width of 180 px at 100% — a single word has no wrap point,
  so below its minimum the label breaks **inside the word, one glyph to a
  line**. The row was 480 px tall without the status and 924 with it: 444 px for
  one word, and 284 px of bottom overflow in a bounded 320x640 box.

  The recorded "6 px residual" was never the row's either. It was raised inside
  the indicator, whose label had been laid out in a box **zero pixels wide** and
  painted outside it. The height was the symptom; an unreadable status was the
  defect.

  The row now uses the share as the question rather than the answer: a trailing
  control keeps the line while what it asks for fits, and moves under the row's
  text when it does not. No overflow on either axis at 100, 150, 200 or 300%. A
  row that genuinely does not fit still clips, draws the indicator and reports,
  because clamping without reporting would have made a visible overflow silent.
  Side effect: a row carrying a control can now answer `IntrinsicHeight` and
  `IntrinsicWidth`.

- **Eleven of the twelve release blockers were re-measured** by an audit with no
  write access, at `d72dc49`. B1–B10 closed, B11 partially (the entry above is
  its other half), B12 untouched. `docs/MISSION_042_RELEASE_CANDIDATE.md` §4
  carries the measurement for each, including two sentences of its own that had
  become literally false, B2's and B4's guarantees holding in debug builds only,
  and the 24 px that B5's surviving half was missing.

## 0.2.0-dev.2 — the IUX-042 follow-through

No new mission. This entry records the work that closed the release
assessment's blockers, and it covers a gap: nothing between IUX-042 and here had
been written down at all.

**The licence is settled.** MIT, chosen by the project owner, at the repository
root and in the package directory. `LICENSE` no longer grants nobody anything,
which was blocker B1 and the entry every other one sat underneath.
`publish_to: none` stays in the pubspec while the repository has no remote —
that is a guard against publishing by accident, not a legal position.

**Still not a release candidate**, and the reason has narrowed to one thing that
no amount of code closes: **nobody has run TalkBack, Voice Access or a D-pad on
a real device**, at any point in forty-two missions plus this. Everything this
repository claims about accessibility is measured on a semantics tree in a unit
test. That is a great deal, and it is not the same claim.

### Breaking

- `IuxFormField.child` is replaced by `IuxFormField.builder`, of the new type
  `IuxFormFieldBuilder = Widget Function(BuildContext, IuxFormField)`. The
  builder is handed the field, so the widget takes `field.input` and
  `field.focusNode` instead of a second copy of each — the duplication that had
  nothing checking the two agreed. Migration: `child: IuxTextField(input: x,
  focusNode: n, …)` becomes `builder: (BuildContext context, IuxFormField
  field) => IuxTextField(input: field.input, focusNode: field.focusNode, …)`.
  22 call sites in this repository, all migrated.
- `IuxFormSection` now refuses, in debug, a field whose `focusNode` is held by
  no widget inside that field — including one held by the *neighbouring* field.
  A widget that accepts no focus node cannot be a form field, which is what the
  required parameter has always meant.
- `IuxButtonState.loading` is removed. It resolved to the resting palette in all
  68 measured cells (four colour profiles × seventeen legal intent/variant
  pairs) while outranking `pressed` and `hovered`, so a running action whose
  repeat policy still accepted activations answered neither the pointer nor the
  finger. The last of the three unpainted rungs, after `success` and `error`.
- `IuxActionColors.border` and `IuxButtonTheme.variant` are removed, and
  `IuxActionIntent.tertiary` is redefined — from a statement about weight, which
  variant and importance already make, to **an action that leads away from the
  task**. `IuxInlineFeedbackAction` becomes `IuxNamedAction`, and `onDismiss`
  becomes `onDismissed` on three components.

### Added

- **`IuxScreen`**, which owns the app-bar-plus-page composition every
  application was writing by hand and getting wrong three ways. On 320x640 at
  250% the hand-written arrangement overflowed by 154 px and left the page
  nothing; it now splits 178/178. `IuxAppBar`'s `LayoutBuilder` is gone,
  rewritten as a slotted render object, so `IntrinsicHeight` and
  `SliverFillRemaining` work on an IUX screen — with bar heights byte-identical
  before and after across five scales and two widths.
- **`IuxPlaceMap`**, the accessible shell around a caller-supplied map. IUX
  renders no tiles and gains no dependency. A map without its list equivalent is
  **unconstructible**: `places` is required, the widget renders the rows itself,
  and there is no parameter that hides them. That guarantee is what licenses the
  other half — because the list is certain, the map subtree is removed from the
  semantics tree outright.
- **`IuxRadioGroup.focusNode`**, attached to the group's first option that can
  take focus. Without it the node an `IuxFormField` handed over was adopted by
  nothing: a validation-summary entry naming a radio group left focus on the
  summary and moved the user nowhere at all. The destination is argued rather
  than assumed — a group is a question, and focusing the column would give a
  stop the user cannot act on and which carries no focus ring, trading an
  SC 2.4.3 failure for an SC 2.4.7 one.
- `IuxAdaptiveNavigation` refuses an unbounded box by name, which
  `docs/components/navigation-rail.md` had claimed since IUX-025 without it
  being true.
- `IuxTransientLayer.debugCheckNotPlacedOver`, called from the three navigation
  components, so a notice placed over the navigation fails at build with the
  corrected arrangement printed.
- `uses-material-design: true` in the package pubspec.

### Fixed

- **A deletion ran without asking** (B2). `IuxActionDescriptor.destructive`
  *defaults* to `IuxConfirmBeforeExecution`, and a plain `IuxButton` discarded
  it in silence: the call site read as though the user were being asked, and the
  action ran on the first tap. A policy is now honoured or refused, never
  discarded — the button refuses at build, by name, and says what to use
  instead.
- **Two patterns put their only control out of reach** (B3). `IuxEmptyState` and
  `IuxPermissionRationale` now scroll themselves when, and only when, they are
  given a bounded height. The discriminator is not a heuristic: every vertical
  scroll view hands its children an unbounded height, so a block inside a
  caller's scrollable adds nothing, and a block given a bounded height was told
  the size of a box by something that will not scroll it — which is the dead
  screen.
- **A notice removed the navigation for four seconds** (B4).
- **The app-bar-plus-page composition** (B5), by `IuxScreen` above.
- **Assistive technology could not move focus onto four control types** (B6) —
  the sweep found **eleven**, and three of them had no tap action at all:
  announced as buttons, inert to a screen-reader double-tap. The mechanical
  check had missed them because it scans bare `Semantics` calls, and the helper
  writes `button: true` and `onTap:` in its own source, satisfying the scan on
  behalf of every caller. A test that verified the one place the defect could
  not be.
- **`IuxSearchResults` was unusable for a searchable list** (B7).
- **Two stacked full-width buttons threw** (B8). `IuxTargetSpacing` lays its two
  axes out with two different widgets now; the vertical `Wrap`'s wrapping
  protected nothing and cost a target — where the height was bounded it moved
  the overflow **sideways, in silence**, a third target landing 68 px off the
  right edge of a 320-wide box with no exception reported at all.
- **Opening a modal disposed the widget that opened it** (B9). `IuxModalLayer`
  keeps its `Stack` whether or not anything is open, so the page never changes
  depth: measured on all three slots, disposals 1 → 0, scroll offset 0.0 → 400,
  and no more `setState() called after dispose()` on the tap that answered the
  dialog. The page is also no longer re-laid-out between loose and tight
  constraints on open.
- **An accepted submission armed an unbounded focus move** (B10). Submitting
  opens a window in which a rejection may move focus, and it closes on the first
  of: the failure being shown, focus arriving in one of the form's own fields,
  or a step change.
- **A list row overflowed at accessible text sizes** (B11): 214 px at 300%, now
  6 px, pinned at the real number rather than rounded away.
- **The library shipped no icons at all.** The package pubspec did not declare
  `uses-material-design: true`, so every Material glyph rendered blank — which
  reads as "the radio buttons do not work" rather than as a missing font,
  because a radio group still updates its value and still calls `onChanged`; it
  simply has no visible mark saying which option is chosen. **No test could have
  caught it**: `flutter_test` substitutes a font that draws every glyph as a
  filled box regardless of what the pubspec declares, so 1976 tests passed
  against a package that shipped no icons. Reported from a real device.
- **Opening a keyboard rebuilt 7.6× what Material does** (`IUX-PERF-001`).
  `IuxAccessibility.of` read six platform values through `MediaQuery.of`, which
  subscribes to every aspect, across 34 call sites; each now reads its own
  aspect. Keyboard 114 → 8 rebuilds, notch 101 → 8, rotation 130 → 26, and text
  scale unchanged at 140 — correctly, since it is the one change that must
  rebuild. Nothing observable changed, verified by dumping 672 resolutions
  before and after, byte-identical.
- **`IUX-SURFACE-001`**: `surface.interactive` has its own primitive per
  profile. The recorded defect was the mirror of the real one — read-only and
  disabled did differ, but in the `filled` variant a read-only field was
  byte-identical to the **editable** field beside it on all four profiles, and a
  lock glyph was the only thing between them.
- **`IUX-RAIL-OVERFLOW-001`**, **`IUX-PROGRESS-LABEL-001`**,
  **`IUX-DRAWER-LABEL-001`**, **`IUX-DESTRUCTIVE-FOCUS-001`** and
  **`IUX-EXPAND-CRASH-001`** are all closed; see
  `docs/evidence/semantic-tokens-and-accessibility.md` for the measurement on
  each.

### Corrected — findings withdrawn, not quietly dropped

- **IUX-027 is withdrawn.** It reported that `BlockSemantics` does not remove a
  covered page whose element survives, and that finding is what kept B9 open for
  fifteen missions under an argument that accessibility outranked the
  ergonomics. It was measured with `find.bySemanticsLabel`, which reads
  `RenderObject.debugSemantics` — a per-render-object cache that keeps its last
  value for a subtree that stops being **visited** rather than being dirtied,
  which is exactly what a blocked page does. On the tree the platform is given,
  and on the simulated screen-reader traversal, the covered page is absent under
  every placement. There was never a trade. **The rule this leaves: an entry
  whose justification rests on a single measurement must name the instrument.**
- **"Five other signals carry read-only" was false.** Four of the five separate
  read-only from *editable* and say nothing about *disabled*, and the fifth is
  worse — a disabled field also publishes `isReadOnly`, because Flutter resolves
  `readOnly: widget.readOnly || !_isEnabled` and merged flags disjoin.
- **`IuxAdaptiveNavigation`'s old behaviour was never *silent*.** One
  `SingleChildScrollView` produced 27 exceptions. The choice was loud in the
  framework's words versus loud in ours.
- **Eight of the catalog's thirteen findings were closed and still described as
  open**, and the "396 px against 360" in the rail entry turned out to be the
  catalog's own longer destination names rather than the package suite's.
- **An exclusion needs the same evidence as an assertion.** The
  distinguishability sweep had excluded the running state, justified by "the
  progress indicator the button swaps in" — there is no progress indicator in
  either button.

### Known open

- **The manual validation register is still empty.** It needs a device, not a
  decision.
- **`find.bySemanticsLabel` is still used elsewhere in the suite**, surviving
  only because the pages behind those modals are still destroyed or genuinely
  absent. A sweep for that instrument is owed.
- The duplicate-descriptor half of the form-field fix is closed by shape, not by
  a check: nothing detects a caller who ignores `field.input` and builds a
  second descriptor, because the form never sees what the widget was passed.
- A running plain `IuxButton` with no `busyHint` carries the operation nowhere.
  Documented rather than asserted, because the assertion would fire across
  roughly twenty call sites in pattern files.
- `surface.subtle` still equals `surface.disabled` on dark standard; every
  alternative rung measured there costs `border.interactive` its 3:1.
- A rail placed by hand still gets no IUX refusal and cannot get one — a `Row`
  lays out a non-flexible child against an infinite width, so the rail is never
  told the window it is in.

## 0.2.0-dev.1 — IUX-008.8, 008.9, 029 to 041

Eight patterns, three audits, and the first application built on the framework
end to end. The `0.1.0-dev` line ends at `0.1.0-dev.11`: the pubspec's
`0.1.0-dev.9` and the package changelog's `0.1.0-dev.1` were lags, never
releases, and the three files are reconciled here.

**This is not a release candidate, and calling it one would be the first thing
this project has claimed without evidence.** Twenty-two entries in
`docs/evidence/semantic-tokens-and-accessibility.md` are open. Several are
severe enough to lock an end user out of a control they need — the assessment,
with the argument for what blocks a release and what does not, is in
`docs/MISSION_042_RELEASE_CANDIDATE.md`.

### Added

Eight patterns, sixteen libraries, in `src/patterns/`.

- **`IuxErrorRecovery`** with a sealed `IuxRecoveryRoute` — `IuxRetryRoute`,
  `IuxAlternativeRoute`, `IuxUnrecoverable` (IUX-029). An error with no way
  forward has to be *declared*, not shipped by omission. `IuxRetryRoute`
  accepts no `IuxActionDescriptor` at all: a parent out of retry budget swaps
  the route rather than greying the control, which removing the parameter turns
  from advice into a rule. Nothing retries on its own — verified by pumping 30
  seconds for zero attempts — so the pattern sets no time limit and SC 2.2.1
  has nothing to bind.
- **`IuxLoadingRetry<T>`** over a sealed `IuxLoadState<T>` — `IuxLoadInProgress`,
  `IuxLoadReady`, `IuxLoadFailed` (IUX-030). **There is no `.empty`.** An empty
  result is *ready with an empty value*, so the builder can name which of
  `IuxEmptyStateCause`'s four situations it is; a fourth enum value would put
  "add your first invoice" one step away from "a filter hid forty". One
  traversal of the indeterminate bar is 1800 ms, which is why a load resolving
  in 80 ms shows under a twentieth of one crossing and reads as a rendering
  fault rather than as work.
- **`IuxPermissionRationale`** with a sealed `IuxPermissionMoment` —
  `IuxBeforeAsking`, `IuxAfterRefusal`, `IuxSystemWillNotAsk` (IUX-031). Before
  and after cannot be confused because they are different types.
  `IuxSystemWillNotAsk` has **no ask parameter**: a control offering to request
  a permission the system will refuse to request reads as a broken app.
  `decline` is required on all three — it is the only signal an application
  gets that the user said no to *being asked*, and a pattern without it can
  only nag. The refusal comes first in reading order, so the control that opens
  the OS prompt is never under the first Enter, and both answers are real
  buttons: the asymmetry, not the wording, is the manipulation.
- **`IuxDestructiveFlow`** and `IuxDestructiveFlowController`, with
  `IuxDestructiveScope` and a sealed, required `IuxWayBack` — `IuxUndoOffer` or
  `IuxNoWayBack` (IUX-032). Proportionality asks one question a caller cannot
  get wrong: *could the user list what they are about to lose?* Two values, not
  four, because there are exactly two safeguards to allocate. `everything` plus
  an undo offer is refused — an undo only protects somebody who can tell they
  need it, and a user who deleted an account cannot inspect what went.
- **`IuxGuidedForm`** with `IuxGuidedFormStep` (IUX-033). Forward progress is
  never blocked and no step can be locked: a step that refuses is worse than a
  button that does, because the question at fault is not on screen. `summary`
  is required here where `IuxForm` allows null, since focusing the first
  rejected field is impossible when that field is unmounted.
- **`IuxSearchField`** and `IuxSearchResults<T>` (IUX-034). Two widgets rather
  than one, because on Android the box very often lives in the app bar and the
  results in the body. The results take an `IuxLoadState<List<T>>` — a search
  is a load, so there is no second state machine. Exactly one announcement per
  settled search: measured, a five-character undebounced query produces ten
  live regions, and with one pause, two.
- **`IuxProgressiveDisclosure`** over a sealed `IuxDisclosureState` —
  `collapsed`, `expanded`, `heldOpen` (IUX-035). Four rules are stated for what
  may never be disclosed and **exactly one is enforced by a type**; the docs say
  which, because a guarantee that is a guess is worse than none. Nothing
  animates, and the absence is proved rather than described.
- **`IuxOnboardingFlow`** with `IuxOnboardingStep` (IUX-036). Skip is required
  on every step including the last: an onboarding a user cannot leave is a wall.
- `IuxTextContent.search` and `IuxTextField.onSubmitted` (IUX-038), closing two
  of the three gaps IUX-034 recorded. No `textInputAction` parameter — the
  action key is resolved from `content` — and `onSubmitted` on a multiline field
  asserts, because its action key *is* the newline key.
- A catalog covering every barrel export, at text scales to 300% with a
  worst-case preset in one tap (IUX-008.8, IUX-037), and `apps/pilot` — a
  four-screen application whose deliverable is its friction log (IUX-041).

### Changed

**Breaking**, all in the button theme (IUX-038). Five members removed rather
than wired, with the reasoning left where each field was: `elevateFilled`,
`IuxButtonTokens.elevation`, `IuxButtonTokens.focused`, `IuxButtonState.success`
and `.error`.

`success` and `error` were not merely inert — **they swallowed hover.** They sat
above `hovered` in the resolver's precedence and returned the resting palette,
so an idle filled button moves `#1560B0` → `#0F4289` on hover while a succeeded
or failed one does not move at all. Removing them repairs an observable defect.

`component_standard_test.dart` now asserts that every field of every
`Iux*Tokens` class is read outside its declaring file. It rediscovered
`elevation` independently across all eighteen token classes, and was proved by
re-adding a dead field.

### Fixed

- **Assistive technology could not move focus onto an IUX control.**
  `IuxSemantics.action` set `excludeSemantics` to control the announced name,
  which deleted the focus state the `IuxFocusable` subtree contributed: an IUX
  button reported `isFocused: Tristate.none` with actions `[tap]` where
  Flutter's own reports `Tristate.isFalse` and `[tap, focus]`. `IuxButton` now
  matches Flutter. This is the third thing that one mechanism had silently
  deleted — it took `onTap` first, at IUX-005, and every IUX button was
  unusable with a screen reader for six missions. **Still open everywhere
  else**; see *Known open*.
- **A running button announced itself as unavailable and threw away the user's
  focus.** `_IuxActionSurface` fed one `isActivatable` value to both
  `canRequestFocus` and the semantics `enabled` flag, so a keyboard user who
  pressed "Try again" was thrown back to the enclosing scope, Android announced
  "unavailable" for something that was working, and `busyHint` landed on a node
  the user had just been moved off. A running button now keeps its focus,
  reports enabled, carries its hint, and offers `[focus]` but not `tap` —
  withholding the tap is the truth, since the repeat policy really does decline
  a second activation, while claiming the control was disabled was not.
  IUX-008.9 proved the conflation by measuring the same running action keeping
  focus under `repeatPolicy: allow` and losing it under `ignoreWhileInProgress`.
- **A generic sealed type broke equality silently** (IUX-030). All three
  subclasses of `IuxLoadState<T>` compared with a type test while `hashCode`
  folded `T` in. Dart generics are covariant, so `loose == tight` was true and
  `tight == loose` false: a value a `Set` holds twice and a `Map` never finds.
  First generic sealed type in the project, which is why the pattern used
  correctly everywhere else was wrong here.
- **The lint the project relied on had never run** (IUX-040). The root
  `analysis_options.yaml` raised the *severity* of `public_member_api_docs`
  without adding it to `linter.rules` — a no-op, for forty-two missions.
  Enabling it surfaced 41 undocumented public members in the foundations file
  alone, now written. The package lint set goes from 8 rules to 160.
- **Two tests that had never tested anything**, each now proved by breaking the
  code (IUX-008.9). *"A disabled button is skipped by focus traversal"* read
  `find.byType(Focus).first` — a `MaterialApp` puts nine `Focus` widgets in the
  tree and the button's own is the last, so the behaviour was entirely
  unguarded and passed with `canRequestFocus: true` hardcoded. A third
  (IUX-QA-VACUOUS-002) was repaired in its harness at IUX-038, where a fourth
  surfaced underneath it: at 200 px the summary entry sat at y = −82, and
  `tester.tap` only *warns* on a miss.
- `IuxRetryRoute.alternative` was a public field nothing could read, which also
  contradicted the doc twelve lines below it (IUX-029).

### Measured, and stated so nobody optimises on a hunch

- **Resolvers are not hot** (IUX-PERF-002). 200k calls each after a 20k warm-up:
  `IuxButtonResolver` 710 ns, the slowest (`IuxNavigationDrawerResolver`)
  1,557 ns. One 60 Hz frame is 16,667,000 ns, so the worst is 0.009% of one.
  The per-frame contrast maths that does exist — two `computeLuminance()` calls
  for a scrim — costs 37 ns. Nothing to optimise.
- **The Flutter lower bound is now evidence rather than habit.**
  `flutter: '>=3.35.0'` is where `MediaQuery.supportsAnnounceOf` first appears
  in a stable tag, and all 202 Flutter types referenced by `lib/` exist there.
  Only Flutter 3.44.8 / Dart 3.12.2 has actually run the suite.
- **The cost of composing no user-facing strings, measured for the first time**
  (IUX-041): 99 declarations, 19% of the pilot's `lib/`. The finding is not the
  total but that **17 of the 99 never appear on screen** — they exist only for
  assistive technology, no design mock contains them, and the easiest to forget
  are exactly the ones only a screen-reader user would miss. The decision stays
  right; the cost is now honest.

### Corrected

- **`IUX-A11Y-FOCUS-001` had been recorded as fixed for every IUX control. It
  was fixed for one.** `IuxFocusNodeOwner` has exactly one call site; the
  disclosure control, validation-summary entries and both transient-layer
  controls still report `isFocused: Tristate.none`. Found by IUX-038 auditing
  the fix it had just landed.
- **IUX-033 proposed *"did the user ask for this?"* as the single line behind
  seven independent focus decisions. Measured across all seven, five hold**
  (IUX-039). The two form patterns do not, and the reason is a real defect
  (IUX-FORM-FOCUS-001). The test was a good description of the intent and not
  of the code.
- **IUX-038's eleven-parameter argument was weaker than it looked** (IUX-039).
  Across all 59 public widget constructors exactly one reaches eleven
  parameters, and none of its eleven is a styling knob. Its other two reasons
  for declining the disclosure-control merge stand.
- IUX-037 recorded that `src/patterns/onboarding/` was "not exported and
  therefore not public API yet", and so did not give it a catalog panel. The
  onboarding exports had landed 21 minutes earlier, at IUX-036.
  **`IuxOnboardingFlow` is public API with no catalog coverage.**
- `IUX-PUBLISH-001` records "47 broken dartdoc references … that render as
  literal text on pub.dev". Both halves are true of different things: the
  `comment_references` lint reports 48 (47 `lib`, 1 `test`), while `dart doc`
  reports **4** unresolved references — those four are what actually renders as
  literal text. The remediation is four one-line fixes, not forty-seven.
- Two doc pages claimed a running button announces "In progress"; that literal
  was removed at IUX-008.6 precisely because it shipped English into every
  non-English application (IUX-008.9).

### Refused, and recorded rather than deferred

Accordion exclusivity and the group widget with it (IUX-035). A leading-glyph
parameter with no caller (IUX-035). Suggestions — `SemanticsRole.comboBox`
**throws** on Flutter 3.44.8, so a list could ship only with no role at all, and
a test pins the day that changes (IUX-034). The onboarding dot row: probed
first, and four decorated `Container`s produce a node with an empty label and
zero children, so it announces nothing (IUX-036). A four-rung proportionality
ladder, and any default undo window (IUX-032). A framework timeout, and a
debounce — one tuned to a fast typist fires after every character for a slow
one, and slow typists are disproportionately the screen-reader and
switch-access population (IUX-029, 030, 034). `prefer_is_empty`, because a
probe shows `assert(label.isNotEmpty)` in a `const` constructor fails, so the
lint would take `const` off every widget that refuses an empty label (IUX-040).

A guard making `IuxButton` refuse a confirmation policy it cannot honour was
**written, tested and reverted**, and the record kept so the next person does
not spend the same hour: it cannot be an initialiser assertion because the
constructors are `const`, and past that it breaks two legitimate callers.

### Known open

Twenty-two entries, **as of commit `80bdcc9`**. Four of them were being fixed by
other missions while this entry was being written — `IUX-EXPAND-CRASH-001`,
`IUX-A11Y-REACH-001`, `IUX-FORM-FOCUS-001` and `IUX-TRANSIENT-COVER-001` — so
check the evidence registry before relying on any of those four still being
open. The full text, with measurements, is in
`docs/evidence/semantic-tokens-and-accessibility.md`; the release argument is in
`docs/MISSION_042_RELEASE_CANDIDATE.md`. The ones that reach an end user:

- **`IUX-BUTTON-CONFIRM-001`.** `IuxButton(action:
  IuxActionDescriptor.destructive(...))` compiles, asserts nothing and runs
  `onActivate` on the **first tap** — measured, `runs == 1`. The `destructive`
  factory *defaults* to `IuxConfirmBeforeExecution`, so the trap sits on the
  shortest path a caller can write for a deletion. `IuxConfirmByHold` is worse:
  nothing anywhere honours it.
- **`IUX-A11Y-REACH-001`.** `IuxEmptyState` at 200% on a 320 px screen puts its
  only control at y 904–1008 against a 640 px fold, with **no scrollable on the
  page**; tapping yields zero activations. `IuxPermissionRationale` at **150%**
  lets the user refuse but not accept. The pilot showed the documented
  mitigation works — both sit inside `IuxPage`, which scrolls — so the defect is
  that nothing makes it the default.
- **`IUX-TRANSIENT-COVER-001`.** A notice pins over the bottom navigation and
  the layer reserves no space: on 360x800, notice at y 712–760, destinations at
  y 740–786, all three `hitTestable = 0` for a dwell of at least four seconds
  that by design cannot be shortened. The fix — transient layer *inside* the
  navigation, modal layer outside — is written in the pilot and nowhere in the
  framework.
- **`IUX-APPBAR-PAGE-001`.** Three defects in the most-repeated composition
  there is. The top inset is applied twice and nothing asserts. The chrome does
  not fit: on 320x640 at 300% the bar and navigation take 260 and 408 px and
  leave the content **−28**, because no component owns the total. And the
  standard fix is unavailable — `IuxAppBar` uses a `LayoutBuilder`, so no IUX
  screen containing one can take part in `IntrinsicHeight`.
- **`IUX-EXPAND-CRASH-001`.** Two stacked full-width buttons inside
  `IuxTargetSpacing` throw. The workaround gives up the 8 px target floor that
  `IuxTargetSpacing` exists to provide.
- **`IUX-SEARCH-RESULTS-001`.** The ready branch throws on an `IuxPage`, and the
  pattern hard-codes `IuxNoMatches`, so a collection that never held anything is
  reported as "no matches, clear the search" beside an empty box.
- **`IUX-OVERLAY-001`**, worse than previously recorded: opening a modal does
  not merely lose a scroll position, it **disposes** the panel that was scrolled
  to, so its callback throws `setState() called after dispose()`.
- **`IUX-FORM-FOCUS-001`.** An accepted submission arms an unbounded focus move,
  so a later blur check rips the caret into the summary. Needs a bounded
  pending-submission window, which is a decision.
- **`IUX-LISTITEM-TRAILING-001`.** `IuxListItem.tappable` with an
  `IuxStatusIndicator` overflows 68 px at 200% and 214 px at 300% on 320 px.
  Neither component overflows alone.
- **`IUX-A11Y-FOCUS-001` (partial)**, `IUX-DESTRUCTIVE-FOCUS-001`,
  `IUX-GUIDED-FORM-LIVE-001`, `IUX-PROGRESS-LABEL-001` (a 45% bar can announce
  "90%"), `IUX-RAIL-OVERFLOW-001`, `IUX-DRAWER-LABEL-001`, `IUX-SURFACE-001`.

Not defects but open all the same: `IUX-API-DEAD-001` (`importance` read by
zero call sites, `IuxElevation` an exported enum with no references),
`IUX-API-NAMING-001` (`summary` names three unrelated types;
`IuxInlineFeedbackAction` and `IuxTransientAction` are field-for-field
identical), `IUX-QA-VACUOUS-003`, `IUX-ONBOARDING-003`, `IUX-PERF-001`
(opening a keyboard rebuilds 106 elements against Material's 14, none of which
can change a pixel), and `IUX-PUBLISH-001`.

**The manual validation register is still empty.** No TalkBack, Voice Access,
physical keyboard, D-pad, on-device display scaling or platform high-contrast
run has been performed on hardware, at any point in forty-two missions. Every
accessibility claim in this changelog rests on widget tests.

## 0.1.0-dev.11 — IUX-025, 026, 027, 028

Navigation completed across three arrangements, plus the first of the
recovery patterns — and four corrections to work that was already committed.

### Added

- `IuxNavigationRail` and `IuxAdaptiveNavigation` (IUX-025). No breakpoint is
  adopted; the arrangement is decided by what each option leaves the content,
  with text scale as a term in the decision. Android's 600dp was considered
  and not taken, and the residual disagreement is logged as a hypothesis.
- `IuxNavigationDrawer` (IUX-027), and an `IuxModalLayer.drawer` slot to go
  with it. The three modals are now mutually exclusive by assertion.
- `IuxTabs` (IUX-026). Each tab carries `SemanticsRole.tab`, the strip carries
  `tabBar`, and Flutter enforces the rest itself.
- `IuxEmptyState` (IUX-028). Four situations, not one — nothing yet created, a
  filter that matched nothing, a search that matched nothing, and a permission
  that hides everything. The wrong situation/action pairing cannot be
  constructed.
- Two mechanical checks under `test/accessibility/`, each pinning a rule that
  had already failed once: a `Semantics` node declaring `button: true` must
  offer something to activate, and the framework may compose no string
  containing letters into a spoken property.

### Fixed

- **The drawer's own documented usage example broke accessibility silently.**
  `Stack(children: [page, if (open) drawer])` leaves the page element alive,
  so its semantics node is never recompiled and `BlockSemantics` does not
  remove the covered page — a screen reader goes on reading, and offering to
  activate, controls the user cannot touch. Touch is identical in both shapes,
  which is why nothing short of a screen reader catches it. The
  `IuxModalLayer.drawer` slot makes the working shape the only expressible
  one.
- **The rail's widest name always wrapped**, which is exactly what its
  documentation promised to prevent. `widthFor` measured the label style
  alone, while the rendered `Text` merges it over the ambient
  `DefaultTextStyle` and inherits a `letterSpacing` the typography theme never
  sets — 0.25px per character, and "Messages" needed 114px against 112.
- **The adaptive rule returned the worse arrangement on a landscape window**:
  at 640x320 at 300%, the rail leaves 286x320 and the bar leaves 640x0.
- **The display inset was applied twice**, and the documented workaround was
  worse than the bug, dropping the top inset and putting content under the
  status bar.

### Corrected

- `docs/components/bottom-navigation.md` argued for `checked` over `selected`
  on the grounds that `selected` is announced only when true. Measured on
  Flutter 3.44, `selected: false` yields `Tristate.isFalse` — explicitly
  present. The flags are tri-state and the two are indistinguishable
  framework-side. The choice stands on a narrower claim that is true:
  `checked` with `inMutuallyExclusiveGroup` says *one of these and only one*.
  What a screen reader speaks is a device question, untested on hardware, and
  is no longer asserted.

### Known open

- **IUX-A11Y-FOCUS-001.** `IuxSemantics.action` yields nodes with
  `isFocused: Tristate.none` and actions `[tap]`, where Flutter's own button
  yields `Tristate.isFalse` and `[tap, focus]`. Assistive technology cannot
  move accessibility focus onto an IUX control programmatically. This is the
  third thing `excludeSemantics` has silently deleted — it took `onTap` first.
  Deferred to IUX-038 rather than fixed mid-wave, because the fix lives in a
  helper every component depends on.

## 0.1.0-dev.10 — IUX-008.7, 012, 018, 023, 024

Two patterns, three components, and one runtime gap closed.

### Added

- **Destructive action pattern** (IUX-008.7) and **guided form pattern**
  (IUX-012) — the first two entries under `src/patterns/`.
- `IuxAppBar` (IUX-023): a title that is never abbreviated.
- `IuxBottomNavigation`, `IuxNavigationDestination` (IUX-024): every
  destination always named. No `labelBehavior`, no icon-only form. Above
  roughly 130% text the destinations stop sharing a row and stack as
  full-width glyph-beside-name, so a name gets 320px instead of 56.
- `IuxTooltip`, `IuxContextualHelp` (IUX-018): reachable by long press, focus
  and hover; dismissable, hoverable and persistent per SC 1.4.13, with no
  clock anywhere in the implementation. The 80-character boundary between a
  floating tooltip and in-flow help is asserted, not advised.
- `IuxSemantics.action` gains `expanded`, and `IuxSemantics.elaboration`
  carries the platform tooltip property. Both close deviations from component
  standard §2 that IUX-018 had to declare because the runtime had nowhere to
  put them — a disclosure whose state a screen reader never hears, and a
  tooltip message that reached no node at all.

### Fixed

- `test/iux_flutter_test.dart` asserted that only patterns remained
  unexported — an assertion invalidated by exporting patterns in IUX-008.7 and
  012. It has now narrowed twice, so it is replaced by the invariant that
  actually holds: every export belongs to a layer the component standard
  names.

### Deliberate deviations, argued

- Bottom navigation destinations tile the bar with no spacing between them,
  against `kIuxMinimumTargetSpacing`. A gap would be four dead strips in the
  thumb zone, and SC 2.5.8 treats spacing as an alternative to size — which
  64 x 112 clears outright.

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
