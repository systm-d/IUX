---
mission_id: IUX-026
title: Tabs
priority: high
status: completed
started_at:
started_by:
last_updated_at: 2026-08-01
completion_status: accepted
validation_status: passed
target_version: 0.2.0-dev
compatibility: additive
depends_on:
  - IUX-025
platform_priority: Android
package_name: iux_flutter
---

# IUX-026 — Tabs

## 1. Références obligatoires
Lire intégralement PROJECT_PROMPT.md, COMPONENT_STANDARD.md, les missions dépendantes, ADR et architecture ; vérifier leurs statuts avant toute modification.

## 2. Contexte
Cette mission apporte navigation entre contenus liés sans remplacer la navigation hiérarchique pour la première version exploitable.

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
Concevoir une API concise autour de IuxTabs, sans couleurs, ombres, rayons ni paramètres de mouvement arbitraires.

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

# Rapport final

## Flutter fait respecter le contrat — sauf quand un detector le désarme

Chaque onglet porte `SemanticsRole.tab`, la bande porte `tabBar`. Flutter
refuse lui-même un onglet sans état sélectionné, sans action de tap, et refuse
un enfant de `tabBar` qui n'est pas un onglet. Les trois messages d'erreur ont
été sondés directement, pas supposés.

**La trouvaille porteuse** : un `GestureDetector` qui se décrit crée un
*second* nœud sémantique par onglet — 6 arrêts mesurés pour 3 onglets — et
pousse le rôle d'onglet sur un parent dont l'enfant, du coup, n'est pas un
onglet. `MergeSemantics` fusionne bien les arrêts, mais déplace le rôle hors du
nœud coché : son propre rôle devient `none`, et **la vérification d'onglet de
Flutter ne s'exécute plus jamais, en silence**. Construire le detector avec
`excludeFromSemantics: true` obtient les deux : un arrêt par onglet, et le rôle
sur le nœud que le framework contrôle.

`SemanticsRole.tabPanel` est `_noCheckRequired` — Flutter n'en fait rien, et il
n'existe pas d'équivalent à `aria-controls`. L'association onglet↔panneau est
donc inexprimable, et aucun widget de panneau n'est livré : §19 interdit une
API publique dont le seul effet est un rôle invérifiable.

## Focus itinérant refusé, et l'asymétrie qui a tranché

Contre la pratique WAI-ARIA, et pour une raison vérifiée dans les sources de
Flutter : `FocusScopeNode.traversalDescendants` filtre `skipTraversal`, donc
le changement qui retire quatre onglets de Tab les retire **aussi** des
flèches, imposant une gestion manuelle des flèches.

Le risque est asymétrique. Un appareil n'émettant que Tab et Entrée rendrait
quatre vues sur cinq **inatteignables** — un échec net de SC 2.1.1 — là où la
tabulation complète coûte quatre pressions de plus.

## Ce qui a été refusé

Pas de mode défilant : un onglet caché n'a rien à l'écran qui dise qu'il
existe, et le geste de révélation entre en collision avec le défilement du
panneau. Payé autrement : 2 à 5 onglets (asserté) et un `Wrap` qui ajoute des
rangées.

Pas de marque en soulignement — un soulignement revendique une adjacence au
panneau, ce qui est faux pour les rangées supérieures d'une bande enroulée.

## Une propriété prouvée plutôt qu'affirmée

Les onglets d'une même rangée ont toujours la même hauteur : une étiquette n'a
besoin d'une seconde ligne que si elle est plus large que la bande entière, et
un onglet aussi large ne peut pas partager sa rangée. Donc aucune bande morte.

## Ce que cette mission a corrigé ailleurs

Elle a signalé que le raisonnement de la navigation basse reposait sur une
prémisse périmée — `selected` serait annoncé seulement à vrai. Vérifié :
`selected: false` donne `Tristate.isFalse`, explicitement présent. Le document
est corrigé.

40 tests.
