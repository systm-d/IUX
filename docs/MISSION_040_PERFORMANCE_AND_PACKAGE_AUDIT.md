---
mission_id: IUX-040
title: Performance and Package Audit
priority: high
status: completed
started_at: 2026-08-04
started_by: IUX-040 audit agent
last_updated_at: 2026-08-04
completion_status: accepted
validation_status: passed
target_version: 0.2.0-dev
compatibility: additive
depends_on:
  - IUX-039
platform_priority: Android
package_name: iux_flutter
---

# IUX-040 — Performance and Package Audit

## 1. Références obligatoires
Lire intégralement PROJECT_PROMPT.md, COMPONENT_STANDARD.md, les missions dépendantes, ADR et architecture ; vérifier leurs statuts avant toute modification.

## 2. Contexte
Cette mission apporte audit de performances, taille et dépendances du package pour la première version exploitable.

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
Concevoir une API concise autour de package performance audit, sans couleurs, ombres, rayons ni paramètres de mouvement arbitraires.

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

# Findings

Every number below was produced by running something. Nothing here is inferred
from reading the code, and where a claim could only be established by
measurement and was not, it is not made.

**Conditions.** Flutter 3.44.8 (stable, engine 0cd610717b) / Dart 3.12.2, Linux
x86-64, `flutter test` on the Dart VM in **JIT** mode. Not an Android device
and not AOT: the absolute timings will differ there, the relative picture
should not. Date: 2026-08-04.

## 1. Rebuild scope — the one real finding

`IuxAccessibility.of(context)` resolves six platform values —
`textScaler`, `highContrast`, `disableAnimations`, `boldText`, `invertColors`,
`accessibleNavigation` — through `MediaQuery.of(context)`, which registers a
dependency on **every** aspect of the media query. It has 34 call sites across
25 files in `lib/`, so nearly every IUX component depends on the whole
`MediaQueryData` rather than on the six values it reads.

Controlled A/B, 20 identical widgets, differing only in how they read those
six values (`test/performance/rebuild_scope_test.dart`):

| change | reads via `IuxAccessibility.of` | reads via `MediaQuery.<aspect>Of` |
| --- | --- | --- |
| software keyboard (`viewInsets`) | **20 of 20 rebuilt** | 0 of 20 |
| notch reported (`padding`) | **20 of 20 rebuilt** | 0 of 20 |
| rotation (`size`) | **20 of 20 rebuilt** | 0 of 20 |
| text enlarged (`textScaler`) | 20 of 20 | 20 of 20 |

On a realistic screen — app bar with an icon action, page, card, status
indicator, text field, two buttons, three-destination bottom navigation — and
against the same screen built from Material widgets, tuned to the **same 518
elements**, one frame after the change:

| change | IUX screen | Material screen |
| --- | --- | --- |
| software keyboard | **106** | 14 |
| notch reported | **93** | 6 |
| rotation | **122** | 30 |
| text enlarged | 132 | 112 |
| theme light → dark | 132 | 170 |

Text scaling and the theme flip are changes IUX genuinely depends on, and there
it is level with or cheaper than Material. The keyboard and the notch are not:
opening the keyboard on a form rebuilds 7.6× what the same Material screen
rebuilds, and none of it can change anything on screen.

**Not fixed here.** The change is one line in
`lib/src/accessibility/iux_accessibility.dart`, which this mission does not own,
and it is worth stating that it is *not* free: six aspect subscriptions instead
of one whole-model subscription, and `MediaQuery.of` measured 66 ns against six
aspect reads. It also cannot weaken any accessibility guarantee — the resolved
values are identical, only the dependency narrows — so PROJECT_PROMPT §5 does
not stand in the way.

Instrumented with `debugOnRebuildDirtyWidget`, Flutter's own per-element build
hook. One caveat worth recording for whoever repeats this: the `builtOnce` flag
it passes is only maintained while `debugPrintRebuildDirtyWidgets` is on, so it
reads `false` forever otherwise and filtering on it silently counts nothing.

## 2. Resolver cost — not a problem, and now guarded

200,000 calls each after 20,000 warm-up calls, results assigned to a sink so
the optimiser cannot delete them, two runs agreeing within 3%:

| | ns/call |
| --- | --- |
| `MediaQuery.of(context)` | 66 |
| `Theme.of(context)` | 150 |
| `IuxSemanticColors.of` / `IuxGeometryTheme.of` / `IuxTypographyTheme.of` | 151–156 |
| `IuxAccessibility.of(context)` | 243 |
| `IuxMotionPolicy.resolve(stateChange)` | 418 |
| `IuxButtonResolver.resolve` | 710 |
| `IuxStatusResolver.resolve` | 942 |
| `IuxBottomNavigationResolver.resolve` | 1,215 |
| `IuxInlineFeedbackResolver.resolve` | 1,251 |
| `IuxListItemResolver.resolve` | 1,270 |
| `IuxSelectionResolver.resolve` | 1,335 |
| `IuxNavigationDrawerResolver.resolve` | 1,557 |
| `Color.computeLuminance()` ×2 (the scrim derivation) | 37 |

One frame at 60 Hz is 16,667,000 ns. The most expensive resolver is 0.009% of
it. A full rebuild of a column of 50 `IuxButton`s measured 243 µs against 150 µs
for one, so a button costs about 2 µs to rebuild, of which the resolver is
0.7 µs — 35%.

The audit specifically looked for contrast arithmetic per frame. There is some:
`IuxDialog`, `IuxBottomSheet` and `IuxNavigationDrawerResolver` each call
`Color.computeLuminance()` twice to pick the darker of two surfaces for the
scrim. It costs **37 ns**, 2.4% of the resolver that runs it, once per overlay
rather than once per item. There is nothing to optimise.

`test/performance/resolver_cost_test.dart` keeps a 100 µs ceiling per call —
about 60× the slowest measurement. It is not a target; it is a tripwire for a
resolver that starts allocating per element or searching a palette.

## 3. Const-ness — one accidental loss, five forced

Thirteen constructors in `lib/` are not `const`. Four are controllers holding
mutable state, one is private. Of the remaining eight widgets and models:

- **`IuxSelectionGroup` lost `const` with no forcing reason.** Its two
  assertions are `label.length > 0` and `children.length > 0`, and a probe
  confirmed both are legal in a `const` constructor — `String.length` and
  `List.length` are constant expressions. Flagged independently by
  `prefer_const_constructors_in_immutables`, which reports it and nothing else
  in `lib/`. Not fixed: `lib/src/components/selection/` is not this mission's.
- **`IuxRadioGroup`, `IuxBottomNavigation`, `IuxNavigationDrawer`,
  `IuxNavigationRail`, `IuxTabs` are forced.** Each asserts uniqueness with
  `.map(...).toSet().length`, and a probe confirmed `children.toSet()` in a
  `const` assertion fails with *Invalid constant value*.
- **`IuxEmptyStateAction` and `IuxFormSubmit` are forced**, and their stated
  reason is exact: it is field access on a parameter of a user type
  (`action.confirmation`, `action.availability`) that Dart rejects, not
  `.length`. The linter agrees — it does not flag either.

No `const` was missed at a call site: `prefer_const_constructors` and
`prefer_const_declarations` are enabled and report nothing.

## 4. Package hygiene

**Dependencies.** `flutter` and `flutter_test`, both from the SDK, and nothing
else. A sweep of every `package:` import across `lib/` and `test/` finds only
`flutter` (235), `flutter_test` (55) and `iux_flutter` itself (51, all in
tests). `@internal` and `@immutable` arrive through
`flutter/foundation.dart`, so `package:meta` is not an undeclared dependency.
Nothing is unused.

**`@internal` leakage: none.** Of 112 libraries under `lib/src`, 108 are
exported by the barrel. The four that are not are
`iux_primitive_colors.dart`, `iux_color_palettes.dart`,
`iux_color_scheme_mapping.dart` and `iux_focus_ownership.dart`. No library
under `lib/src` re-exports anything, and none of the four appears in a public
signature — every use is internal to an implementation. One nit: the first
three carry `@internal`, `iux_focus_ownership.dart` does not.

**Documentation coverage: complete, and it had never been checked.** The root
`analysis_options.yaml` raises the *severity* of `public_member_api_docs`
without ever adding it to `linter.rules`, which is a no-op — so the rule the
project relies on for PROJECT_PROMPT §35 had never run. Enabling it surfaced
**41 undocumented public members**, all in
`lib/src/foundations/iux_foundations.dart` — the enum values and constants of
the very first layer. All are now written. A separate probe confirmed the rule
does cover `lib/src`, not only `lib/`.

**SDK constraint.** The package declared `sdk: '>=3.0.0 <4.0.0'` and no Flutter
bound at all. The newest Flutter API used by `lib/` is
`MediaQuery.supportsAnnounceOf`, whose introducing commit first appears in the
stable tag **3.35.0** (found with `git log -S` and `git tag --contains` against
the Flutter checkout); all 202 Flutter types referenced by `lib/` exist at that
tag. `flutter: '>=3.35.0'` is now declared, and because Flutter 3.35.0 itself
requires Dart `^3.8.0-0`, that bound is what actually protects a consumer.
`sdk` is left at 3.0 on purpose: nothing here uses a language feature above
Dart 3.0, and raising it to 3.8 switches `dart format` to its 3.7 "tall" style
and rewrites **157 of the 172 files** in the package with no behavioural
content. Measured, and left as somebody's deliberate decision.

**Archive.** 611 KB compressed, of which roughly half is `test/`. Shipping the
tests is defensible for a project whose tests are its evidence; no `.pubignore`
was added.

## 5. `dart pub publish --dry-run` — two blockers, both governance

1. **`You must have a LICENSE file in the root directory.`** The repository's
   `LICENSE` is a placeholder that explicitly grants *no* permission to use,
   copy, modify or distribute. This is not a file that can be written by an
   audit; it is a decision the project owner has not taken. `publish_to: none`
   is kept for exactly this reason and now says so in the pubspec.
2. **No `repository:` or `homepage:`.** The working tree has no git remote, so
   any URL written there would be invented. Left absent deliberately.

Two further warnings, both real:

- the package `CHANGELOG.md` still describes `0.1.0-dev.1` while the pubspec
  says `0.1.0-dev.9` and the repository `CHANGELOG.md` has reached
  `0.1.0-dev.11`. Three versions, three files, no two agreeing. The changelogs
  are out of this mission's scope;
- the package `README.md` said IUX "does not yet provide final user-interface
  components, semantic tokens, or themes". It is pub.dev's front page for this
  package and it was describing a state that ended around IUX-003. Rewritten.

## 6. Analysis options — measured, then tightened

The package now enables **160 lint rules** where the repository root enables
eight. The set is the one the Flutter framework applies to its own source
(`flutter/analysis_options.yaml`, 172 rules at 3.44.8) minus the 17 measured to
fail here, plus five Flutter does not enable. `flutter analyze` reports **No
issues found**, so 159 of the 160 cost nothing and constrain new code only; the
exception was `public_member_api_docs`, above.

Adopting the Flutter set wholesale would have cost **338 fixes** (207 in `lib/`,
131 in `test/`), and the distribution is the point:

| rule | lib | test | note |
| --- | --- | --- | --- |
| `always_put_control_body_on_new_line` | 157 | 63 | 65% of the total, pure layout |
| `avoid_redundant_argument_values` | 10 | 39 | |
| `prefer_is_empty` | 20 | 0 | **would break `const`** |
| `avoid_escaping_inner_quotes` | 1 | 12 | |
| `use_if_null_to_convert_nulls_to_bools` | 8 | 0 | |
| `sort_child_properties_last` | 0 | 8 | |
| `specify_nonobvious_property_types` | 4 | 0 | |
| others (10 rules) | 7 | 9 | |

`prefer_is_empty` deserves its own line. All 20 hits are `length > 0` inside a
constructor assertion, and a probe confirmed `const C(...) : assert(
label.isNotEmpty)` fails with *Invalid constant value* while
`assert(label.length > 0)` compiles. Adopting the rule would take `const` off
every widget that refuses an empty label — a lint that would have made the
package measurably worse.

Three lints reported **zero** and were adopted for what they prevent rather
than what they found: `use_build_context_synchronously`, `unawaited_futures`,
`close_sinks`.

One measured and deliberately left off, because it is a real defect this
mission cannot fix cleanly: **`comment_references` reports 47 broken doc
references in `lib/`** — a `[Type]` that dartdoc cannot resolve renders as
literal text on pub.dev instead of a link. Each fix needs an import added to a
library this mission does not own. Recommended as a follow-up.

## 7. Reported and deliberately not fixed

| finding | why not here |
| --- | --- |
| `IuxAccessibility.of` depends on the whole `MediaQuery` (§1) | `lib/src/accessibility/` is not this mission's, and the fix changes component rebuild behaviour |
| `IuxSelectionGroup` could be `const` (§3) | `lib/src/components/selection/` is not this mission's |
| 47 broken dartdoc references (§6) | each needs an import in a library this mission does not own |
| `iux_focus_ownership.dart` lacks `@internal` (§4) | annotation on a library this mission does not own; harmless, since it is unexported |
| package `CHANGELOG.md` three versions behind (§5) | changelogs are out of scope |
| the root `analysis_options.yaml` still raises the severity of a lint it never enables (§4) | the root file is shared with `apps/catalog` and `apps/pilot`; enabling it there would surface their undocumented members |

## 8. Validation

```
$ dart format --output=none --set-exit-if-changed lib test
Formatted 172 files (0 changed)

$ flutter analyze
No issues found!

$ flutter test
All tests passed!   (1929)

$ dart pub publish --dry-run
Package validation found the following error:
* You must have a LICENSE file in the root directory.
Sorry, your package is missing a requirement and can't be published yet.
```

The suite stood at 1,901 when this mission started and at 1,916 by the time it
finished, IUX-039 having landed `test(api)` in between. 13 of the 1,929 are
this mission's, all under `test/performance/`.

**Publishable: no.** One blocker, and it is not technical: the project has not
chosen a licence.

