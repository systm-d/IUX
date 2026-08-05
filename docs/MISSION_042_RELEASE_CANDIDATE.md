---
mission_id: IUX-042
title: Release Candidate
priority: high
status: completed
started_at: 2026-08-04
started_by: agent/iux-042-release-candidate
last_updated_at: 2026-08-04
completion_status: accepted
validation_status: passed
target_version: 0.2.0-dev.1
compatibility: additive
depends_on:
  - IUX-041
platform_priority: Android
package_name: iux_flutter
---

# IUX-042 — Release Candidate

## 1. Références obligatoires
Lire intégralement PROJECT_PROMPT.md, COMPONENT_STANDARD.md, les missions dépendantes, ADR et architecture ; vérifier leurs statuts avant toute modification.

## 2. Contexte
Cette mission apporte stabilisation d’une release candidate de première version exploitable pour la première version exploitable.

## 3. Objectif utilisateur
Permettre une expérience Android compréhensible, prévisible et accessible.

## 4. Objectifs de la mission
Créer uniquement les contrats, composants ou patterns nécessaires et réutiliser Foundations, tokens, Theme Engine, Accessibility Runtime, Motion, Feedback, Layout, Action Model et thèmes existants.

## 5. Hors périmètre
Ne pas ajouter logique métier, réseau, stockage, identité graphique, abstraction universelle de rendu ni périmètre de la mission suivante.

## 6. Audit préalable obligatoire
Inventorier APIs réellement livrées, exports, tests, catalogue, ADR, doublons et limitations ; documenter les écarts avant de coder.

## 7. Principes directeurs
Respecter intégralement COMPONENT_STANDARD.md. Préférer composition, états indépendants, API orientées intention et propriété applicative de l’état métier.

## 8. Architecture ou structure cible
Placer le code sous lib/src/components ou lib/src/patterns selon sa responsabilité, avec résolveurs locaux, tests et documentation. Aucune couche transverse sans usages multiples démontrés.

## 9. API attendue
Concevoir une API concise autour de release candidate checklist, sans couleurs, ombres, rayons ni paramètres de mouvement arbitraires.

## 10. Comportements attendus
Définir explicitement disponibilité, interaction, opération, validation et sélection seulement si pertinentes ; prévenir les combinaisons incohérentes.

## 11. Accessibilité
Garantir Semantics, focus applicable, clavier/D-pad, cibles tactiles, texte/display scaling, RTL, contraste et mouvement réduit. Distinguer garanties du composant, contenu applicatif et validations TalkBack/Voice Access manuelles.

## 12. Thèmes et tokens
Résoudre le rendu depuis tokens et thèmes IUX pour clair, sombre et contraste renforcé ; interdire couleurs et métriques graphiques codées en dur.

## 13. Mouvement et feedback
Réutiliser Motion et Feedback Engine ; réduire le mouvement selon profil et ne déclencher aucun feedback métier implicite.

## 14. Documentation
Documenter intention, usage/non-usage, API, états, accessibilité, thèmes, exemples, anti-patterns, limites et migration pertinente.

## 15. ADR
Créer une ADR seulement pour une décision architecturale durable nouvelle, avec alternatives et conséquences.

## 16. Evidence Registry
Relier chaque règle UX importante à un niveau standard, strong_guidance, context_dependent, hypothesis ou brand_choice ; marquer les sources non vérifiées to_verify.

## 17. Tests unitaires
Tester résolutions, invariants, valeurs par défaut, transitions et configurations invalides.

## 18. Widget tests
Tester interactions, callbacks, états, texte long, petits écrans et comportements observables.

## 19. Tests d’accessibilité
Tester Semantics, focus, clavier, cibles, texte agrandi, RTL, thèmes et mouvement réduit ; consigner les contrôles manuels.

## 20. Tests de contrat
Vérifier exports, absence de dépendance graphique/métier, compatibilité et réutilisation des abstractions existantes.

## 21. Catalogue
Ajouter scénarios d’intention, états, accessibilité, profils de thème, texte agrandi, RTL, anti-patterns et limites ; pas de galerie décorative.

## 22. Dépendances
N’ajouter aucune dépendance sans nécessité immédiate, maintenance et justification ; préférer les APIs IUX et Flutter existantes.

## 23. Performance
Privilégier const, résolution stable, listes paresseuses si pertinentes et rebuilds limités ; ne benchmarker qu’un scénario défini.

## 24. Compatibilité
Mission additive. Toute rupture exige dépréciation et migration explicitement documentées.

## 25. Commandes de validation
Exécuter et rapporter les résultats réels de dart format ., flutter analyze, flutter test et, si pertinent, flutter build apk --debug.

## 26. Livrables obligatoires
Périmètre implémenté, tests, documentation, catalogue, Evidence Registry, ADR éventuelle, résultats de validation et limites connues.

## 27. Critères d’acceptation
Terminer seulement si besoin couvert, API cohérente, états/accessibilité vérifiés, thèmes testés et aucun hors périmètre introduit.

## 28. Rapport final attendu
Présenter audit, solution, API, états, accessibilité, evidence/ADR, fichiers, dépendances, tests, commandes réellement exécutées, limites et prochaine mission.

## 29. Instruction finale
Commencer par l’audit. Implémenter uniquement cette mission après validation des dépendances ; ne pas commencer la suivante.

---

# Release readiness assessment

## 1. Verdict

**IUX is not a release candidate.** It is a well-evidenced pre-release with
twelve blocking defects, of which one is legal and eleven reach an end user.

The honest framing matters more than the verdict. This is not a project that
cut corners and got caught; it is a project whose own audits found these
defects, measured them, and refused to fix them from inside the mission that
found them. Twenty-two open entries is not a symptom of low quality — it is
what a registry looks like when nobody is allowed to quietly close one. A
project with three audits and an empty open list would be the worrying one.

What blocks the release is narrower than the open list and can be stated in one
sentence: **an application built on IUX today, following the documentation, can
ship a screen where a user cannot reach the only control, and a deletion that
happens without asking.** Both are on the shortest path a competent developer
writes. Neither is the developer’s fault.

### The verdict re-stated at `d72dc49`, and why it does not change

Both halves of that sentence are now closed, and so are nine other entries —
§4 carries the re-measurement for each. **The verdict still stands, and its
reason is now a single entry: B12.** Nobody has run TalkBack, Voice Access or a
D-pad on a real device, at any point in forty-two missions and everything since.

That is not a formality standing in for a solved problem. This project shipped a
library with **no icons at all** for weeks — `uses-material-design` was never
declared, so every Material glyph rendered blank — and 1976 tests passed over it,
because `flutter_test` substitutes a font that draws every glyph as a filled box
regardless of what the pubspec says. It reads to a user as "the radio buttons do
not work". It was found by a person holding a phone.

Everything this repository claims about accessibility is measured on a semantics
tree in a unit test. That is a great deal, it is more than most projects have,
and **it is not the same claim** as "a screen-reader user can operate this".
Until someone runs the register in §5, the honest statement is that IUX is
well-evidenced against the things a test can see.

## 2. What is proven, and it is a great deal

Ranked by how much a consumer can rely on it.

**Verified by measurement, repeatedly, and I re-ran it.**

- **1,929 package tests, 36 catalog tests, 29 pilot tests — all passing**, with
  `flutter analyze` clean in all three under a 160-rule lint set. Verified in
  this mission, not quoted.
- **Contrast.** All four shipped mappings meet 4.5:1 for body content and 3:1
  for interface elements, measured through the public API, including the
  disabled and hovered pairings. 152 button variant × intent × state × profile
  combinations measured. Disabled content holds 3:1 despite WCAG exempting it.
- **High contrast reaches both brightnesses.** The engine that forced light
  conditions under high contrast — leaving users needing both with no option —
  was fixed at IUX-004 and is asserted.
- **The touch-target floor cannot be opted out of**, holds at every density,
  and never dips below the floor mid-transition.
- **Resolvers are not a performance problem** and this is settled rather than
  assumed: the slowest is 0.009% of a 60 Hz frame, with a 100 µs tripwire test
  guarding against regression.
- **No component can reach a raw colour.** Structural, not advisory: the
  primitive palette is unexported.
- **Every field of every `Iux*Tokens` class is read outside its declaring
  file**, enforced mechanically, proved by re-adding a dead field.
- **The framework composes no user-facing string containing letters**,
  enforced by test. The pilot measured the cost of that decision honestly.

**Sound by construction, which is this project’s real achievement.** A large
number of misuse cases are unrepresentable rather than asserted:
`IuxSystemWillNotAsk` has no `ask` parameter; `IuxWayBack` and
`IuxRecoveryRoute` are sealed and required, so "no way back" is a claim
somebody made; `IuxLoadState` has no `.empty`, so an empty result must be named
by cause; an async operation returns `IuxAsyncOutcome`, so handing IUX a bare
future and getting a success out of it cannot be written. The pilot — the only
consumer that had to hold all of it at once — singled out the assertion
messages as having repeatedly taught it the right design before it could get it
wrong. That is the strongest single piece of evidence in the project’s favour,
because it comes from the one place with no incentive to be kind.

**Honest about its own limits**, which is why the rest of this document can be
believed. Hypotheses are labelled as hypotheses. Refusals are recorded with
their reasoning. A reverted fix is on record so the next person does not repeat
it. Three separate audits corrected the mission that preceded them, and IUX-038
corrected a claim the maintainer had made about a fix that had just landed.

## 3. The line between blocking and known

Asserting the line would be worth nothing, so here is the argument.

A framework defect is not one application’s bug. It is **every** adopter’s bug,
it arrives through an API the adopter cannot change, and the adopter usually
cannot tell it is there — the pilot found four of these only by building a real
screen, and one of them (`IUX-LISTITEM-TRAILING-001`) exists only when two
components are combined, so no component test could have found it. That
asymmetry is why the bar for a framework sits higher than for an application.

**A defect blocks the release when, on a path the documentation leads a
competent developer down, it produces one of:**

1. **loss of user data without the user being asked** — §5 priority 1, user
   safety;
2. **a control the end user cannot reach, operate, or leave** — §5 priority 3,
   accessibility, which §5 places above ergonomics, performance and appearance
   and which this project has enforced against itself four times;
3. **a crash**, because a framework that throws on an obvious composition is
   not usable at the level it claims;
4. **a legal bar to use at all.**

**A defect is a known issue when a competent adopter can see it, work around
it, and the workaround is written down.** The cost is then developer time,
which §5 ranks eleventh, rather than user harm, which it ranks first to third.

Two consequences worth naming, because they cut against my own convenience:

- **Ease of fixing is not a criterion, and neither is apparent difficulty.**
  `IUX-DRAWER-LABEL-001` was 7.5 px and a known issue; `IUX-APPBAR-PAGE-001`
  needs a new component and possibly a change to `IuxAppBar`’s internals, and it
  blocks. Ranking by user harm means the blocking list is harder to clear than a
  list chosen for tractability. The reverse trap is `IUX-OVERLAY-001`, which
  read as a hard problem — "the known fix breaks `BlockSemantics`" — and turned
  out to be one deleted line behind one wrong measurement. **An entry whose
  justification rests on a single measurement should name the instrument**, or
  the next reader inherits the conclusion without the means to check it.
- **"The mitigation exists" does not clear a blocker if the default is wrong.**
  `IUX-A11Y-REACH-001` did not bite the pilot, because the pilot put everything
  inside `IuxPage`, which scrolls. That is real and it is why the entry is
  blocking rather than catastrophic — but the defect is that the framework’s
  default composition is the broken one, and an adopter who does not read this
  document gets the broken one.

## 4. Release-blocking

Ranked by user harm. Accessibility outranks ergonomics throughout, per §5.

**Re-audited at `d72dc49` by a read-only pass that re-derived every entry from
its own probes rather than from these paragraphs.** Eleven of the twelve now
carry a verdict below. Two sentences in this section were literally false by
then and are struck where they stood, rather than edited away: the package
directory *does* have its own `LICENSE`, and `IuxConfirmByHold` no longer
exists as a type.

**B1 — No licence. Closed.** `LICENSE` was a placeholder that explicitly
granted no permission to use, copy, modify or distribute, so nobody could
legally depend on this repository and every other item on this list sat
downstream of it. **It is MIT, chosen by the project owner** — root and package
directory, byte-identical. `dart pub publish --dry-run` now reports
**0 warnings** for `iux_flutter 0.2.0-dev.2`: no licence error, no changelog
drift, and no missing-`homepage` warning now that a `repository:` is declared.
`publish_to: none` stays, as a guard against publishing by accident rather than
as a legal position. *(The original entry's note that "the package directory
also has no `LICENSE` file of its own" is no longer true.)*

**B2 — `IUX-BUTTON-CONFIRM-001`: a deletion runs without asking. Closed in
debug; the guard is an `assert`, and for a data-loss entry that distinction
belongs here rather than in a footnote.**
`IuxButton(action: IuxActionDescriptor.destructive(...))` compiled, asserted
nothing, and ran `onActivate` on the first tap — measured, `runs == 1`. The
`destructive` factory *defaults* to `IuxConfirmBeforeExecution`, so the trap sat
on the shortest path a caller can write for a deletion, and the type system
discarded a stated intention in silence.

Re-measured: the same call now throws at build and **`onActivate` runs == 0**,
on `IuxButton` and `IuxIconButton` alike, with the message naming
`IuxDestructiveAction` and the explicit escape
`copyWith(confirmation: IuxConfirmationPolicy.none)` — which builds clean and
runs once, as it should. `IuxConfirmByHold` has been **removed** as a type, so
the "zero honourers" half of the entry is now unrepresentable rather than
merely unhonoured.

**What is not closed, and is stated here because §5 priority 1 is user safety:**
in a release build the check is compiled out and `_handleActivate` still passes
`confirmed: true`, so a descriptor carrying a policy still runs on the first
tap. That is deliberate and argued in the source — flipping it in release would
turn a caller's mistake into a control that does nothing when tapped, which is
indistinguishable from one that is broken — and the check fires on the *first
frame* the control is built, so no debug run, widget test or catalog page can
reach a release build without seeing it. It is still a debug-time guarantee
protecting against a data-loss defect, and a reader deciding whether to depend
on this package should be told so in the entry, not in the source.

**B3 — `IUX-A11Y-REACH-001`: two patterns put their only control out of
reach. Closed.** `IuxEmptyState` at 200% on 320 px landed its reset button at
y 904–1008 against a 640 px fold with **no scrollable on the page**;
`hitTestable = 0`, tap yielded zero activations. `IuxPermissionRationale` at
**150%** — an unremarkable setting — let the user **refuse but not accept**.
WCAG 2.2 SC 1.4.4 and 1.4.10.

Both patterns now supply their own `Scrollable` when, and only when, they are
handed a bounded height, and none when the caller already scrolls — re-measured,
nested scrollables = 0. On 320x640 after a drag: empty state `hitTestable = 1`
and one activation at 200% **and** 300%; the rationale accepts at both, and at
150% without needing to scroll at all.

**B4 — `IUX-TRANSIENT-COVER-001`: a notice removes the navigation for four
seconds. Closed in debug; the guard is an `assert`.** On 360x800 the notice sat
at y 712–760 over destinations at y 740–786, all three `hitTestable = 0`, for a
dwell that is a minimum of four seconds and by design cannot be shortened.
WCAG 2.2 SC 2.2.1.

The broken arrangement now throws at build, naming the caller's widget and
printing the corrected nesting. Re-measured on the correct arrangement: notice
at y 620–644, destinations at y 752–792, **all three `hitTestable = 1`**, and a
tap changes section. As with B2, a release build carries none of the check —
which is right here, because the failure it catches is a developer's
arrangement rather than a user's action, and it cannot survive a single debug
run.

**B5 — `IUX-APPBAR-PAGE-001`: the most-repeated composition is broken three
ways. Closed by a new component; one half survives in the shape it replaces.**
The top inset was applied twice with nothing asserting. The chrome did not fit —
on 320x640 at 300% the bar and navigation took 260 and 408 px and left the
content **−28** — because no component owned the total. And the standard remedy
was structurally unavailable: `IuxAppBar` used a `LayoutBuilder`, so no IUX
screen containing an app bar could take part in `IntrinsicHeight`,
`IntrinsicWidth` or intrinsic `Table` sizing.

`IuxScreen` owns the total now, and all three are measured closed inside it: the
padding handed to `IuxPage` is `EdgeInsets(0, 0, 0, 16)` — **top inset 0, not
doubled**; the chrome fits 320x640 at 100, 200, 250 **and 300%** with zero
errors, splitting 168/168 at 300%; and `IntrinsicHeight` lays out with zero
errors around both an `IuxScreen` and a bare `IuxAppBar`, the `LayoutBuilder`
having been rewritten as a slotted render object.

**The surviving half, now quantified**: a hand-rolled
`Column(IuxAppBar, Expanded(IuxPage))` still receives `top: 24.0` and puts the
body **40 px below the bar instead of 16 — exactly 24 px duplicated — and
nothing refuses it.** `docs/components/app-bar.md` says the entry is "closed by
a component, not by an assertion" and that the composition it replaces "still
behaves as it did"; that is true, and 24 px is the number it was missing.

**B6 — `IUX-A11Y-FOCUS-001`: assistive technology cannot move focus onto four
control types. Closed — and the sweep found eleven, not four.** It was fixed for
`IuxButton` at IUX-038 and nowhere else; `IuxFocusNodeOwner` had exactly one
call site. The disclosure control, validation-summary entries and both
transient-layer controls reported `isFocused: Tristate.none` with actions
`[tap]`, and driving `performAction(SemanticsAction.focus)` on the disclosure
did nothing at all. WCAG 2.2 SC 4.1.2.

Re-measured on the live semantics tree: all four control types, plus the button,
report `actions=[tap, focus]` and `isFocused: Tristate.isFalse`, and driving
`performAction(SemanticsAction.focus)` **moves `primaryFocus` onto the node** in
every case, with the node flipping to `Tristate.isTrue`. `IuxFocusNodeOwner` has
**10 call sites** now.

**Three of the eleven had no tap action at all** — announced as buttons, inert
to a screen-reader double-tap. The mechanical check that should have caught them
scans for bare `Semantics` calls, and the helper writes `button: true` and
`onTap:` in its own source, satisfying the scan on behalf of every caller: a
test that verified the one place the defect could not be.

**B7 — `IUX-SEARCH-RESULTS-001`: unusable for a searchable list, two ways.
Closed, both halves.** The ready branch threw *RenderFlex children have non-zero
flex but incoming height constraints are unbounded* on an `IuxPage`, and the
documented placement meant giving up `IuxPage` — the only thing that knows the
page insets and the reading width. It also hard-coded `IuxNoMatches` and
required a `reset`, so a collection that never held anything was reported as "no
matches, clear the search" beside an empty box: the exact conflation
`IuxEmptyStateCause` exists to prevent.

Re-measured: the ready branch inside an `IuxPage` produces **zero errors** and
renders its rows. `emptyCause` is a **required** parameter now, so nothing is
hard-coded and no `reset` is demanded — `nothingCreatedYet` renders "Add an
order" with "Clear the search" absent — and a cause that owes a way forward
while carrying neither an action nor guidance is refused by assert.

**B8 — `IUX-EXPAND-CRASH-001`: two stacked full-width buttons throw. Closed.**
Inside `IuxTargetSpacing`, `expand: true` failed with *BoxConstraints forces an
infinite width*, and the workaround gave up the 8 px target floor the primitive
exists to provide, so there was no arrangement that gave both.

Re-measured: **zero errors** at 100, 200 and 300%, both buttons 320 px wide, gap
**8.0 px at every scale** — the floor kept, which was the half a `Column` plus
`IuxGap` could not give. A genuinely widthless parent still fails loudly:
*"IuxButton(expand: true) was given no width to fill."*

**B9 — `IUX-OVERLAY-001`: opening a modal disposes the widget that opened it.**
**Closed.** Measured on all three `IuxModalLayer` slots: the opener’s `State`
was disposed on open (1, now 0), a scrolled list returned to 0 (now holds 400),
and the callback the opener had handed to the modal threw `setState() called
after dispose(): _OpenerState#… (lifecycle state: defunct, not mounted)` on the
tap that answered the dialog (now no exception). The fix is the removal of one
line — the `Stack` is permanent, so the page never changes depth.

**The reason this was open needs recording, because it was not neglect.** The
entry said "the known fix breaks `BlockSemantics`". It does not. IUX-027
measured that with `find.bySemanticsLabel`, which reads
`RenderObject.debugSemantics` — a per-render-object cache that keeps its last
value for a subtree that stops being visited rather than being dirtied. On the
semantics tree the platform is actually given, and on the simulated
screen-reader traversal, the covered page is absent under a permanent `Stack`,
under a hand-rolled one, and under the conditional shape alike. IUX-027 is
withdrawn; §5’s ranking was never in play. The barrier is now pinned by
live-tree assertions in `iux_modal_layer_test.dart` that fail if paint order is
reversed.

**B10 — `IUX-FORM-FOCUS-001`: an accepted submission arms an unbounded focus
move. Closed.** `_handleSubmit` never brought `_focusedAttempt` level on the
accepted path, so the comparison was permanently unequal and every later
`didUpdateWidget` carrying a rejected field moved focus: the user submitted
successfully, edited a field, tabbed on, the parent answered the blur check —
and the caret was ripped into the summary. WCAG 2.2 SC 3.2.2.

Re-measured over the whole sequence: after an accepted submission the user edits
field 0, tabs to field 1, the parent answers the blur check and rejects field 0,
the summary appears — **the caret is still in field 1 and the summary did not
take focus**. The control case still behaves: a rejection answering the
*submission itself* does move focus to the summary, which is the whole point of
the window.

**B11 — `IUX-LISTITEM-TRAILING-001`: a list row overflows at accessible text
sizes. Partially closed — and the fix moved the failure to the other axis.**
`IuxListItem.tappable` with an `IuxStatusIndicator` in `trailingAction` on
320 px was clean at 100% and 150%, **68 px over at 200%, 214 px at 300%**.
Neither component overflows alone, which is why no component test found it and
why it is the strongest argument in this project for the pilot's existence.

Horizontally it is fixed: re-measured with the pilot's own row, **0 px at 100%,
150% and 200%**, and **6.0 px at 300%** — pinned at the real number in the
pilot's suite rather than rounded away — with the title box holding 136 px
instead of collapsing.

**The fix had bounded the trailing control to a one-third width share, so at
300% the status wrapped and drove the row's height instead** — 480 px tall
without the status, **924 with it, 444 px for one word**, and 284 px of bottom
overflow in a bounded 320x640 box where the row alone had 160 to spare. This
entry's own signature, pair-only, relocated from one axis to the other.

**Now closed on both axes, and the diagnosis changed on measurement.** The cap
was not failing only at 300%: it laid the control out below its minimum width at
**every** scale, including 100%. The share is 86 px and does not grow, while an
`IuxStatusIndicator` reading one word has min intrinsic equal to max intrinsic —
180 px at 100%, 472 at 300% — because a single word has no wrap point. Handed
less, the label breaks **inside the word, one glyph to a line**. So the height
was not honest content height and the B3-in-reverse argument does not apply: the
row was manufacturing it. The recorded "6 px residual" was not the row's either
— it was raised inside the indicator, whose label had been laid out in a box
**zero pixels wide** and painted outside it. The height was the symptom; an
unreadable status was the defect.

The row now uses the share as the question rather than the answer: a trailing
control keeps the line while what it asks for fits, and moves under the row's
text when it does not. No overflow on either axis at 100, 150, 200 or 300%, and
a row that genuinely does not fit still clips, draws the indicator and reports —
clamping without reporting would have made a visible overflow silent. What
remains open is not geometry but perception, and it is B12's: whether a control
that has moved below the row's text still reads as a *second* target under
TalkBack.

**B12 — The manual validation register is empty.** No TalkBack run, no Voice
Access run, no physical keyboard or D-pad pass, no on-device display scaling,
no platform high-contrast or colour-inversion check — at any point in
forty-two missions. The register itself says none may be claimed until
executed. **For a framework whose entire proposition is accessibility, shipping
without a single screen-reader session on hardware is the gap hardest to
defend**, and it is the one item on this list that needs a device rather than a
decision. Several entries above concern what a screen reader is told; every one
of them rests on widget tests asserting semantics flags, which is not the same
claim.

## 5. Known issues

Real, documented, and survivable — a competent adopter can see and route
around each.

| Entry | What it costs |
| --- | --- |
| `IUX-DESTRUCTIVE-FOCUS-001` | Cancelling a destructive confirmation drops focus to the page root: four Tab presses to recover, where Flutter’s own dialog costs zero. SC 2.4.3, recoverable. |
| `IUX-GUIDED-FORM-LIVE-001` | A live region in the same frame as a focus move — the collision the pattern refused a progress bar to avoid. Degrades an announcement; does not block. |
| `IUX-PROGRESS-LABEL-001` | **Closed.** A percentage written in `valueLabel` is now compared against `value` with a five-point tolerance; `%`, `٪`, `﹪` and `％` are read, with or without the space French puts in front. Uninspected on purpose, because a false positive is worse than a miss: `3 of 7`, `12 MB of 40 MB`, non-ASCII digits, and any label carrying two percentages. It is an `assert`, so finding 6 of the catalog applies. |
| `IUX-RAIL-OVERFLOW-001` | **Closed.** The rule now asks whether the rail fits before asking what it leaves. Re-measured as arithmetic rather than as one font: a landscape box *N* px narrower than the rail overflowed by exactly *N* without the fit term (36 → 36, 100 → 100) and by nothing with it; across 25 windows × 7 text scales, 21 cells flip rail → bar and 18 stop throwing, with every ordinary size unchanged. The "396 px against 360" was the catalog’s longer destination names; five short ones cost 354 at 300%. An unbounded box is now refused by name as well — and the old behaviour was never *silent*, it produced 27 exceptions from a `Column` the caller never wrote. |
| `IUX-DRAWER-LABEL-001` | **Closed.** Overflow 0 at all sixteen combinations of {320, 360, 800, 1200} × {100%, 150%, 200%, 300%}. The header is a slotted render object that measures the label it was given, so the arrangement follows the label and the room rather than the text scale, and the inversion this entry described — enlarging the text repaired it — is gone with the rule that caused it. The recorded 7.5 px, and the 9.5 px in the drawer’s own test file, are historical. |
| `IUX-SURFACE-001` | **Closed.** `surface.interactive` has its own primitive per profile. The claim that "five other signals carry read-only" was false and is withdrawn: four of the five separate read-only from *editable* and say nothing about *disabled*, and the fifth is worse — a disabled field also publishes `isReadOnly`, because Flutter resolves `readOnly: widget.readOnly \|\| !_isEnabled` and merged flags disjoin. Exactly one signal, the marker, separated the two. The real defect was the mirror of the recorded one: in the `filled` variant a read-only field was byte-identical to the **editable** field beside it on all four profiles. Fill still does not carry the distinction and cannot — no two steps of the neutral ramp reach 3:1. |
| `IUX-API-DEAD-001` | `importance` read by zero call sites; `role` read only by two debug assertions; `IuxElevation` an exported enum with no references. Misleads, does not harm. **Its `IuxConfirmByHold` half is B2, not here.** |
| `IUX-API-NAMING-001` | `summary` names three unrelated types; `IuxInlineFeedbackAction` and `IuxTransientAction` are field-for-field identical; `onDismiss` vs `onDismissed`. Costs developer time and a breaking change later. |
| `IUX-QA-VACUOUS-003` | Two tests that cannot fail, plus the mechanism note — `DebugOverflowIndicatorMixin` reports once per render-object lifetime. Weakens the guard, harms no user. |
| `IUX-ONBOARDING-003` | 40 of 51 heading lines duplicated from the stepped form. Maintenance. |
| `IUX-PERF-001` | Opening a keyboard rebuilds 106 elements against Material’s 14, none of which can change a pixel. Measurable; not a correctness defect, and the fix cannot weaken a guarantee. |
| `IUX-DISCLOSURE-004` | Closed **wontfix** on measured evidence, with one of its three reasons later weakened by IUX-039. Listed so it is not mistaken for neglected debt. |
| `IuxDialog` and the Android back button | By design — back is navigation, and navigation is the application’s. But Android is the platform priority, so every application writes the `PopScope` or ships a modal the platform’s primary gesture cannot dismiss. Needs documenting on the dialog page. |
| `IuxRadioGroup` has no `focusNode` | **Closed, and it was worse than "latent".** Measured with a rule attached: activating the summary entry left `primaryFocus` on the summary itself — focus did not land badly, it did not move at all — and `Scrollable.ensureVisible` was a no-op too, because it early-returns on a null context. The parameter now exists and lands on the group’s first option that can take focus, because a group is a question and a question is not a control: focusing the column would give a stop the user cannot act on and which has no focus ring, trading an SC 2.4.3 failure for an SC 2.4.7 one. |
| Five pieces of caller state per form field | **Reduced, and the rest made loud.** `IuxFormField` takes a `builder` handed the field itself, so the descriptor and the node are passed once rather than twice; `IuxFormSection` refuses in debug a field whose node is adopted by nothing, or by the neighbouring field. Four pieces remain. The descriptor half is closed by shape rather than by a check, because the form cannot see what the widget was passed — closing it properly needs the input components to read from an inherited field scope. |
| Per-route modal and transient layers | A pushed route cannot reach the shell’s layers, so every route that opens a dialog or offers an undo places both again. |
| `IuxOnboardingFlow` has no catalog panel | IUX-037 recorded it as unexported and skipped it; the exports had landed 21 minutes earlier. An exported pattern with no catalog scenario. |
| 4 unresolved dartdoc references | See §7 — the registry’s "47" is a different measurement. |

## 6. Versions, reconciled

Three files held three numbers: root `CHANGELOG.md` at `0.1.0-dev.11`, the
pubspec at `0.1.0-dev.9`, the package `CHANGELOG.md` at `0.1.0-dev.1`.

**All three are now `0.2.0-dev.1`.** Reasoning:

- It is greater than every number previously in the tree, so neither stale
  number can be mistaken for current and no ordering question arises.
- `target_version: 0.2.0-dev` is declared by this mission’s header and by 43 of
  the 52 mission files — every mission from IUX-009 onward. The project has
  intended the `0.1.0` line to close for a long time; the changelog simply kept
  incrementing it.
- It stays pre-1.0 **and** pre-release. `-rc` was available and is refused:
  given §4, calling this a release candidate in the version string would be the
  same false claim in a different file.
- `0.1.0-dev.9` and `0.1.0-dev.1` are recorded as lags, not releases. Nothing
  was published under them, so nothing is lost by skipping them.

**The rule, now written in `CONTRIBUTING.md` so it cannot drift again:**

1. `packages/iux_flutter/pubspec.yaml` **decides**. It is the only place a
   version number is chosen.
2. The root `CHANGELOG.md` is **the only history**; its top heading repeats the
   pubspec version verbatim.
3. `packages/iux_flutter/CHANGELOG.md` is **not a second history** — pub
   requires a changelog in the package directory naming the current version, so
   it names it, summarises it in a sentence, and points at the root.

The drift was mechanically detectable the whole time and nobody was running the
check: `dart pub publish --dry-run` reports *"CHANGELOG.md doesn’t mention
current version"* whenever (1) and (3) disagree. It is now part of the
documented validation set. Nothing detects a drift between (1) and (2), so the
rule says to bump them in the same edit; a test asserting it would be better
and is recommended, but writing tests into the package is outside an
assessment’s remit.

## 7. Two corrections to the record

Both matter because the registry is what the next mission will trust.

**`IUX-PUBLISH-001` says "47 broken dartdoc references … that render as literal
text on pub.dev". Both halves are true, of different things.** Measured here:
the `comment_references` lint reports **48** (47 `lib`, 1 `test`) — IUX-040’s
count is right — while `dart doc` reports **4** unresolved references, and
those four are what actually renders as literal text. The lint flags any
`[identifier]` not resolvable in its own library’s scope; dartdoc resolves
across the package’s export graph. The remediation is four one-line fixes:
`[onActivate]` in `iux_empty_state_model.dart:395`, `[IuxFormSubmit.onSubmit]`
broken across a line break in `iux_form.dart:260`, `[children]` in
`iux_semantics.dart:417`, `[operation]` in `iux_recovery_route.dart:210`.

**IUX-037’s coverage claim rests on a false premise.** Its commit states that
`lib/src/patterns/onboarding/` "is not exported and therefore not public API
yet", and on that basis it claims every barrel export has a catalog panel. The
onboarding exports landed at IUX-036, 21 minutes earlier — `git log -S`
confirms it. `IuxOnboardingFlow` is public API with no catalog coverage, and
the coverage claim is therefore not true as stated.

Neither is corrected in `docs/evidence/` by this mission, which does not own
that file.

## 8. Documentation gaps, and what was closed

A first-time user hit all of these. Closed here:

- **The five stale pages IUX-037 counted but never named.** They were named
  only in `apps/catalog/README.md` §13 and never entered the evidence registry.
  `components/app-bar.md` claimed the component was unexported; `bottom-sheet.md`
  and `navigation-drawer.md` each denied an `IuxModalLayer` slot that exists and
  prescribed a hand-built `Stack` — the exact shape that leaves a covered page
  readable by a screen reader; `patterns/loading-and-retry.md` described the
  busy-button defect fixed at IUX-038 as current. The fifth is the worst class:
  `components/navigation-rail.md` promised that an unbounded box "fails loudly …
  Asserted", **and no assertion exists** — the widget silently picks the bar, so
  a caller in a scroll view gets the phone arrangement on a tablet with no
  warning. A doc that promises a safety net that is not there is more dangerous
  than one that is merely out of date.
- **`patterns/search.md`’s primary example throws on `IuxPage`.** Now says so,
  with the consequence stated plainly: a searchable list on the framework’s own
  page widget cannot use this pattern today.
- **The transient/navigation layering rule existed only in a pilot source
  comment**, for the defect the pilot called the worst it found. Now on
  `components/transient-feedback.md` with the working composition.
- **The `expand: true` + `IuxTargetSpacing` crash** was documented nowhere a
  reader would look. Now on both the button and layout pages, with both
  arrangements and the guarantee the workaround costs.
- **`IuxAppBar`’s `IntrinsicHeight` incompatibility and the 300% chrome
  overflow** appeared on no doc page. Now in the app bar’s limits.
- **No install path and no correct minimum wrapper.** Neither README said how
  to depend on the package, and the package README’s example — pub.dev’s front
  page — omits `IuxFeedbackScope`, whose `of` throws. A reader copying it got a
  tree that throws the moment anything emits feedback. Both fixed, with the
  required-ancestor rule stated: an IUX theme always, `IuxFeedbackScope` if
  anything emits, no accessibility-runtime ancestor at all.
- **`apps/pilot/` was absent from the root README**, though it is the richest
  source of correct-composition guidance in the repository.
- **`docs/README.md` said components exist "once they exist"**, and there is no
  component index. Fixed, including the two pages whose filename does not match
  what they document: `patterns/guided-form.md` documents `IuxForm`, and
  `patterns/stepped-form.md` documents `IuxGuidedForm`.

Left open, and needing an owner:

- `components/dialog.md` should document the `PopScope` every application must
  write for the Android back button.
- `docs/evidence/` has no entry for the stale-docs finding, so it was invisible
  to registry readers; and the two corrections in §7 belong there.
- `IuxFocusNodeOwner` has no doc page. It is unexported, so this is minor.

## 9. What this mission changed, and what it must not be read as

Documentation, changelog and version metadata only. **No file under
`packages/iux_flutter/lib/`, `apps/`, `docs/evidence/`, `docs/decisions/` or any
other mission document was modified by this mission, and nothing was
committed.** An assessment that edits what it assesses cannot be trusted; that
discipline has held for four audits and is why their findings were believed.

`packages/iux_flutter/pubspec.lock` shows as modified: `flutter pub get`, run as
part of validation, reconciled its Flutter bound to the `>=3.35.0` IUX-040
declared in the pubspec. It is a consequence of running validation, not an edit.

### This assessment describes commit `80bdcc9`

**Four other missions were fixing these defects while this one was assessing
them**, in parallel and in the same working tree: `IUX-EXPAND-CRASH-001` (B8),
`IUX-A11Y-REACH-001` (B3), `IUX-FORM-FOCUS-001` (B10) and
`IUX-TRANSIENT-COVER-001` (B4). Their changes to
`packages/iux_flutter/lib/` were in flight throughout.

Everything above therefore describes **the tree as of `80bdcc9`**, which is the
last commit and the state this mission was asked to assess. It is not a claim
about the working tree at the moment you read it. Four of the twelve blockers
may already be closed; **the verdict does not change if all four are**, because
B1 (the licence), B12 (no hardware validation), B2, B5, B6, B7, B9 and B11
remain, and B1 alone is dispositive.

**Re-verify before acting on §4 or §5.** Any entry whose fix has landed should
be confirmed against the evidence registry and the tests, not against this
document. This section exists so that a reader who finds `expand: true` working
concludes that a fix landed, rather than that the assessment was careless.

## 10. Validation

Flutter 3.44.8 / Dart 3.12.2, Linux x86-64. Run against a **clean tree at
`80bdcc9`**, before the parallel fix missions of §9 had modified anything —
`git status` showed only `pubspec.lock`, regenerated by `flutter pub get`.

```
packages/iux_flutter   flutter analyze   No issues found! (ran in 0.4s)
packages/iux_flutter   flutter test      All tests passed!   (1929)
apps/catalog           flutter analyze   No issues found! (ran in 0.8s)
apps/catalog           flutter test      All tests passed!   (36)
apps/pilot             flutter analyze   No issues found! (ran in 0.4s)
apps/pilot             flutter test      All tests passed!   (29)

dart pub publish --dry-run
  Package validation found the following error:
  * You must have a LICENSE file in the root directory.
  Sorry, your package is missing a requirement and can't be published yet.
```

`dart pub publish --dry-run`, re-run after the version reconciliation, **no
longer reports** *"CHANGELOG.md doesn't mention current version (0.1.0-dev.9)"*.
That warning disappearing is the mechanical confirmation that §6 landed.
`LICENSE` is the sole remaining error; the only other warning is the absent
`homepage`/`repository`, deliberate while the repository has no remote.

**A re-run at the end of this mission does not reproduce these numbers, and the
reason is §9, not this mission.** The parallel fix missions had the tree
mid-edit: `flutter analyze` reported a `body_might_complete_normally` error in
`lib/src/patterns/empty/iux_empty_state.dart`, and
`iux_guided_form_test.dart`'s *"DEFECT: an accepted submission arms an unbounded
focus move"* failed — which is precisely what that test was written to do the
day the defect is fixed. Neither is reachable from a documentation, changelog or
version change. The clean-tree figures above are the ones this assessment
rests on.

## 11. Next

Not a mission, a decision: **the licence.** It gates everything, it cannot be
taken by an agent, and until it is taken the twelve blockers below it are
theoretical — nobody may use this either way.

After that, the shortest honest path to a real release candidate is a
device-validation mission (B12) and a composition mission owning B4, B5 and B8
together, since all three are failures of *what owns the frame* rather than
defects in any one component.



---

# Addendum — les quatre bloquants d'accessibilité sont fermés

Écrit après le rapport ci-dessus, qui date explicitement son état. Quatre des
douze bloquants ont été corrigés depuis, chacun avec sa mesure et une preuve
par cassage délibéré.

| Bloquant | État |
| --- | --- |
| B3 — contrôle inatteignable sous mise à l'échelle | **fermé** (`d3ad7a7`) |
| B4 — notice couvrant la navigation | **fermé** (`434db4a`) |
| B8 — plantage `expand: true` | **fermé** (`8c759f6`) |
| B10 — déplacement de focus non borné | **fermé** (`3ca5126`) |

**Le verdict ne change pas**, et l'évaluation le disait d'avance : B1 seul est
dirimant. La licence n'accorde toujours aucun droit d'usage, de copie ou de
distribution, et c'est une décision qui appartient au propriétaire du projet.

Restent également ouverts : la politique de confirmation honorée par un widget
sur quatre (B2), la composition barre + page cassée de trois façons (B5), le
focus d'accessibilité absent sur quatre types de contrôle (B6), les résultats
de recherche qui lèvent dans `IuxPage` (B7), le modal qui dispose son ouvreur
(B9), la ligne de liste qui déborde de 214 px à 300 % (B11) — et surtout
**B12**, le registre de validation manuelle vide.

B12 mérite d'être répété parce qu'aucune des quatre corrections ne l'entame :
personne n'a jamais lancé TalkBack, Voice Access ou un D-pad sur un appareil
réel. Tout ce que ce dépôt affirme sur l'accessibilité est mesuré sur un arbre
sémantique en test unitaire. C'est beaucoup, et ce n'est pas la même chose.

Suite complète après les quatre corrections : **1976 tests du paquet, 36 du
catalogue, 29 du pilote**, analyze propre sous le jeu de 160 règles.
