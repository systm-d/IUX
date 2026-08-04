---
mission_id: IUX-038
title: Accessibility Audit
priority: high
status: completed
started_at:
started_by:
last_updated_at: 2026-08-04
completion_status: partial
validation_status: passed
target_version: 0.2.0-dev
compatibility: additive
depends_on:
  - IUX-037
platform_priority: Android
package_name: iux_flutter
---

# IUX-038 — Accessibility Audit

## 1. Références obligatoires
Lire intégralement PROJECT_PROMPT.md, COMPONENT_STANDARD.md, les missions dépendantes, ADR et architecture ; vérifier leurs statuts avant toute modification.

## 2. Contexte
Cette mission apporte audit transversal d’accessibilité de la première version pour la première version exploitable.

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
Concevoir une API concise autour de accessibility audit report, sans couleurs, ombres, rayons ni paramètres de mouvement arbitraires.

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

# Résultats — IUX-038

## Défauts fermés

| Réf | État | Test qui l'épingle |
| --- | --- | --- |
| IUX-A11Y-FOCUS-001 | corrigé (session précédente, `4b364bb`) | `iux_button_qa_test.dart` |
| IUX-BUTTON-BUSY-001 / -002 | corrigé (session précédente, `4b364bb`) | `iux_button_qa_test.dart` |
| IUX-BUTTON-DEAD-001 | **corrigé** — les trois interrupteurs supprimés, pas câblés | `component_standard_test.dart` §19 ; `iux_button_qa_test.dart` ; `iux_button_theme_test.dart` |
| IUX-QA-VACUOUS-002 | **corrigé** — harnais, pas `IuxForm` | `iux_form_test.dart` |
| IUX-TEXTFIELD-GAPS-001 | **corrigé** — deux écarts comblés, le troisième refusé et argumenté | `iux_text_field_test.dart` |
| IUX-DISCLOSURE-004 | **non corrigé, mesuré et argumenté** | probe : aucune dérive entre les deux contrôles |
| IUX-BUTTON-CONFIRM-001 | non tenté, comme demandé | — |

### IUX-BUTTON-DEAD-001 — supprimés, pas câblés

`IuxButtonTheme.elevateFilled`, `IuxButtonTokens.elevation`,
`IuxButtonTokens.focused`, `IuxButtonState.success` et `IuxButtonState.error`
sont retirés. Les trois arguments sont écrits à l'endroit où les champs se
trouvaient.

`success` / `.error` n'étaient pas inertes : placés **au-dessus** de `hovered`
dans la précédence du résolveur et rendant la palette au repos, ils
supprimaient le survol. Mesuré : un bouton au repos passe de `#1560B0` à
`#0F4289` au survol, un bouton `succeeded` ne bouge pas. Leur suppression
répare donc un défaut observable.

Un test générique de jeton mort est ajouté à `component_standard_test.dart` :
tout champ d'une classe `Iux*Tokens` doit être lu quelque part hors du fichier
qui le déclare. Il a retrouvé `elevation` indépendamment, sur les 18 classes de
jetons du paquet.

### IUX-DISCLOSURE-004 — non fusionné, et pourquoi

Mesuré côte à côte : mêmes libellé, `expanded`, `button: true`,
`header: false`, même action `tap` unique, même style résolu ; les rectangles ne
diffèrent que de la largeur du glyphe. Aucune dérive.

Trois raisons de ne pas fusionner, écrites dans
`lib/src/components/help/iux_contextual_help.dart` :

1. l'état final proposé (`IuxContextualHelp` composant le pattern) inverse le
   sens des couches — `grep` : **0** import `patterns/` depuis `components/`,
   8+ dans l'autre sens ;
2. descendre le contrôle et lui faire résoudre ses propres jetons laisserait
   **8 champs** d'`IuxContextualHelpTokens` — classe exportée — sans lecteur,
   donc une rupture publique que le nouveau test §19 ferait échouer ;
3. les passer en paramètres produit un widget à onze paramètres, la forme que
   PROJECT_PROMPT §20 désigne comme mauvaise, contre quarante lignes de
   duplication entièrement privée.

## Constats nouveaux — signalés, non corrigés

Trouvés en mesurant l'arbre sémantique et la mise en page réels. Aucun n'a été
touché : un audit qui modifie ce qu'il audite n'est pas croyable.

| Réf | Constat | Sévérité |
| --- | --- | --- |
| A1 | `IuxEmptyState` et `IuxPermissionRationale` perdent des fonctionnalités à 320 px sous agrandissement du texte | haute |
| A2 | Les contrôles de `_IuxTransientActionControl` / `_IuxTransientDismissControl` n'ont pas de sémantique de focus | haute |
| A3 | Annuler une confirmation destructive renvoie le focus à la racine ; le dialogue Flutter le restaure | moyenne-haute |
| A4 | Deux tests « mise en page sous contrainte » sont vacants (`SingleChildScrollView` rend l'assertion infalsifiable) | moyenne |
| B1 | `_IuxDisclosureControl` a encore la signature de focus d'avant IUX-A11Y-FOCUS-001 | haute |
| B2 | Les entrées d'`IuxValidationSummary` de même | haute |
| B3 | `IuxGuidedForm` met une live region dans la même frame que son déplacement de focus | haute |
| B4 | `IuxSearchResults` place son unique sortie hors écran à 200 % sur 320 px, et les deux placements documentés échouent | moyenne-haute |
| B5 | Passer une disclosure en `heldOpen` perd le focus clavier | basse-moyenne |
| C1 | `IuxFocusNodeOwner` n'a qu'**un seul** site d'appel, donc IUX-A11Y-FOCUS-001 n'est corrigé que pour le bouton | haute |

Détail des reproductions mesurées : voir le rapport de mission.

## Validation

```
dart format .     Formatted 169 files (1 changed)
flutter analyze   No issues found!
flutter test      All tests passed!  (1901, contre 1893 au départ)
```


---

# Rapport final

## Deux défauts fermés, et un que je croyais fermé ne l'était qu'à moitié

`IuxButton` déclare désormais son état de focus et offre l'action `focus`, et
un bouton qui travaille garde son focus au lieu de s'annoncer indisponible.
Vérifié par sondage.

**Mais `IuxFocusNodeOwner` n'a qu'un seul site d'appel.** Le contrôle de
divulgation, les entrées de résumé de validation et les deux contrôles de la
couche transitoire rapportent toujours `Tristate.none` avec `[tap]` — et
piloter `performAction(SemanticsAction.focus)` sur la divulgation ne fait
**rien**. L'agent l'a trouvé en auditant la correction qu'il venait de poser.
Mon premier compte rendu revendiquait « tout contrôle IUX » ; c'est corrigé.

## Les trois interrupteurs morts : retirés, pas branchés

Et l'entrée du registre ratait le principal : **`success` et `error` n'étaient
pas inertes, ils avalaient le survol.** Placés *au-dessus* de `hovered` dans la
précédence, ils rendaient la palette au repos. Mesuré : un bouton plein au
repos passe de `#1560B0` à `#0F4289` au survol ; un bouton « réussi » ou
« échoué » ne bouge pas du tout. Les retirer répare un défaut observable, pas
seulement une API morte.

Épinglé **mécaniquement** : chaque champ de chaque classe `Iux*Tokens` doit
désormais être lu hors de son fichier de déclaration. Le test a redécouvert
`elevation` tout seul à travers les dix-huit classes de jetons.

## Une vacuité en cachait une autre

En corrigeant le test creux du formulaire, l'agent a découvert qu'à 200 px
l'entrée de résumé se trouvait à y = **−82**, et que `tester.tap` se contente
d'**avertir** en cas de raté. Sa première réécriture mesurait donc un
formulaire que personne n'avait touché.

## Un refus argumenté plutôt qu'une dette laissée ouverte

Sur le contrôle de divulgation en double, il a mesuré les deux côte à côte —
aucune dérive — puis a refusé de fusionner, avec trois raisons : la fusion
**inverse le sens des couches** (zéro import `components/` → `patterns/`
aujourd'hui, huit ou plus dans l'autre sens) ; l'extraction laisserait huit
champs d'un type **exporté** non lus, ce que son propre nouveau test
mécanique ferait échouer ; et les passer en paramètres donne un widget à onze
paramètres — la forme que §20 nomme comme mauvaise — contre quarante lignes de
duplication entièrement privée. Classé wontfix sur cette base.

## Ce qu'il a trouvé et n'a pas touché

Le plus grave : **`IuxPermissionRationale` à 150 %, l'utilisateur peut refuser
mais pas accepter.** Le contrôle de refus reçoit le tap, celui de demande non.
Et `IuxEmptyState` à 200 % met son unique bouton hors écran sur une page qui
ne contient **aucun défilement**.

Deux nouveaux tests creux, plus la note de méthode qui vaut mieux que les deux :
`DebugOverflowIndicatorMixin` ne signale un débordement **qu'une fois par
durée de vie** de l'objet de rendu, donc toute boucle qui réutilise l'arbre
d'éléments passe à vide après le premier cas.

Et deux soupçons mesurés puis déclarés **non réels**, dit franchement — dont un
où son propre détecteur avait pris un `:` de ternaire pour un argument nommé.

1901 tests.
