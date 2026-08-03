---
mission_id: IUX-008.9
epic: IUX-008
title: Button QA and API Review
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
  - IUX-008.8
platform_priority: Android
package_name: iux_flutter
---

# IUX-008.9 — Button QA and API Review

## 1. Références obligatoires
Lire intégralement PROJECT_PROMPT.md, COMPONENT_STANDARD.md, les missions dépendantes, les ADR et l’architecture. Vérifier leurs statuts avant modification.

## 2. Contexte
Cette mission poursuit la première version exploitable en apportant audit de cohérence, stabilité API et accessibilité du système de boutons.

## 3. Objectif utilisateur
Permettre une interaction compréhensible, prévisible et accessible dans une application Android IUX.

## 4. Objectifs de la mission
Créer seulement les contrats, composants et scénarios nécessaires au périmètre ; réutiliser Foundations, tokens, Theme Engine, Accessibility Runtime, Motion, Feedback, Layout et Action Model.

## 5. Hors périmètre
Ne pas ajouter de logique métier, stockage, réseau, navigation applicative, identité graphique, abstraction universelle de rendu ni fonctionnalité de la mission suivante.

## 6. Audit préalable obligatoire
Inventorier les API réellement livrées, exports, tests, catalogue, ADR, doublons et limitations ; documenter les écarts avec ce plan avant de coder.

## 7. Principes directeurs
Respecter intégralement COMPONENT_STANDARD.md. Préférer composition, états indépendants et API orientées intention ; le parent reste propriétaire de l’état métier.

## 8. Architecture ou structure cible
Placer le code sous lib/src/components ou lib/src/patterns selon sa responsabilité, avec résolveurs locaux, tests et documentation correspondante. Ne pas créer de couche transverse sans plusieurs usages réels.

## 9. API attendue
Concevoir une API publique concise autour de button API contract suite. Elle ne doit exposer ni couleurs, ni ombres, ni rayons, ni valeurs de mouvement arbitraires.

## 10. Comportements attendus
Définir explicitement disponibilité, interaction, opération, validation et sélection seulement lorsqu’elles sont pertinentes. Empêcher les combinaisons incohérentes et les activations interdites.

## 11. Accessibilité
Garantir automatiquement Semantics, focus applicable, cibles tactiles, clavier/D-pad, texte agrandi, display scaling, RTL, contrastes et mouvement réduit. Distinguer les obligations du composant, du contenu applicatif et des tests manuels TalkBack/Voice Access.

## 12. Thèmes et tokens
Résoudre tout rendu depuis les tokens et thèmes IUX, y compris clair, sombre et contraste renforcé. Ne coder aucune couleur ou métrique graphique dans le composant.

## 13. Mouvement et feedback
Réutiliser Motion et Feedback Engine ; le mouvement explique uniquement un changement et est réduit selon le profil. Aucun feedback métier implicite.

## 14. Documentation
Documenter intention, usage, non-usage, API, états, accessibilité, thèmes, exemples, anti-patterns, limites et migration si nécessaire.

## 15. ADR
Créer une ADR seulement pour une décision architecturale durable nouvelle, avec alternatives et conséquences.

## 16. Evidence Registry
Enregistrer les règles UX importantes avec niveau standard, strong_guidance, context_dependent, hypothesis ou brand_choice ; marquer toute source non vérifiée to_verify.

## 17. Tests unitaires
Tester résolutions, invariants, valeurs par défaut, transitions de modèle et configurations invalides.

## 18. Widget tests
Tester interactions, callbacks, états, texte long, petits écrans et comportements observables.

## 19. Tests d’accessibilité
Tester Semantics, ordre et visibilité du focus, clavier, cibles, texte agrandi, RTL, thèmes et mouvement réduit ; consigner les validations manuelles.

## 20. Tests de contrat
Vérifier exports publics, absence de dépendance graphique/métier, compatibilité et réutilisation des abstractions existantes.

## 21. Catalogue
Ajouter des scénarios expliquant intention, états, accessibilité, profils de thème, texte agrandi, RTL, anti-patterns et limites, sans galerie décorative.

## 22. Dépendances
N’ajouter aucune dépendance sans nécessité immédiate, maintenance et justification ; préférer les APIs Flutter et IUX existantes.

## 23. Performance
Mesurer seulement un problème défini ; privilégier const, résolution stable, listes paresseuses si pertinentes et rebuilds limités.

## 24. Compatibilité
La mission est additive. Toute rupture exige une stratégie de dépréciation et migration explicitement approuvée.

## 25. Commandes de validation
Exécuter et rapporter les résultats réels de dart format ., flutter analyze, flutter test et, si une application Android est concernée, flutter build apk --debug.

## 26. Livrables obligatoires
Code limité au périmètre, tests, documentation, catalogue, Evidence Registry, ADR éventuelle, résultats de validation et limites connues.

## 27. Critères d’acceptation
Terminer uniquement si le besoin est couvert, l’API est cohérente, les états et l’accessibilité sont vérifiés, les profils de thème sont testés et aucune fonctionnalité hors périmètre n’est introduite.

## 28. Rapport final attendu
Présenter audit, solution, API, états, accessibilité, evidence/ADR, fichiers, dépendances, tests, commandes réellement exécutées, limites et prochaine mission.

## 29. Instruction finale
Commencer par l’audit. Implémenter uniquement cette mission après validation des dépendances ; ne pas commencer la suivante.



---

# Rapport final

Audit sans droit d'écriture sur `lib/` — un audit qui édite ce qu'il audite
n'est pas crédible. `git diff` sur `packages/iux_flutter/lib` est vide.

## Huit constats, dont un de sûreté

Le plus grave : `IuxButton(action: IuxActionDescriptor.destructive(...))`
compile, n'asserte rien, et exécute `onActivate` **au premier tap**. La
fabrique `destructive` a pourtant `IuxConfirmBeforeExecution` par défaut — le
piège est donc sur le chemin le plus court qu'un appelant puisse écrire pour
une suppression. Seul `IuxDestructiveActionController` évalue la politique.

La perte de focus est une **confusion démontrée**, pas une inférence : la
*même* action en cours garde le focus avec `repeatPolicy: allow` et le perd
avec `ignoreWhileInProgress`. Rien du focus n'a changé entre les deux — seule
l'acceptation d'un second tap.

Trois interrupteurs publics ne commandent rien : `elevateFilled` (zéro
consommateur, décorations identiques au bit près), `IuxButtonTokens.focused`
(jamais transmis par aucun site d'appel), et `IuxButtonState.success`/`.error`
(publiés avec une précédence documentée, jamais peints).

## Deux tests creux, prouvés dans les deux sens

« un bouton désactivé est sauté par la traversée du focus » lisait
`find.byType(Focus).first` — or un `MaterialApp` place **neuf** `Focus` dans
l'arbre, celui du bouton est le **dernier**, et le premier est faux quoi qu'il
arrive. Le test passait avec `canRequestFocus: true` codé en dur dans
`IuxButton` — **et toute la suite aussi**. Le comportement n'était gardé par
rien.

« le glyphe n'ajoute pas de seconde annonce » affirmait qu'un label est trouvé
une fois. Un second nœud serait *sans label*, donc non apparié : l'assertion
ne pouvait pas échouer pour la raison qu'elle nommait.

Les deux échouent désormais sous la même casse.

## Ce qui est propre, dit sans padding

Contraste : aucun échec sur variante × intention × 4 profils, y compris les
appariements désactivé/survolé que `test/themes/` n'avait jamais couverts.
192 configurations à 200 % sur 320 px sans exception. Échelle jusqu'à 300 % :
hauteur croissante de 56 à 316, jamais de rognage. Le focus revient bien au
déclencheur après une confirmation destructive, sur les deux réponses — le
contrôleur le documentait, rien ne le testait.

29 tests ajoutés, groupés `open defect —` ou `verified —` ; les tests de
défaut **assertent le comportement actuel**, pour qu'une correction échoue
bruyamment au lieu d'atterrir en silence.
