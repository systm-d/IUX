---
mission_id: IUX-039
title: API Consistency Review
priority: high
status: completed
started_at: 2026-08-04
started_by: IUX-039 audit agent
last_updated_at: 2026-08-04
completion_status: accepted
validation_status: passed
target_version: 0.2.0-dev
compatibility: additive
depends_on:
  - IUX-038
platform_priority: Android
package_name: iux_flutter
---

# IUX-039 — API Consistency Review

## 1. Références obligatoires
Lire intégralement PROJECT_PROMPT.md, COMPONENT_STANDARD.md, les missions dépendantes, ADR et architecture ; vérifier leurs statuts avant toute modification.

## 2. Contexte
Cette mission apporte revue de cohérence, stabilité et migration des API publiques pour la première version exploitable.

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
Concevoir une API concise autour de public API contract review, sans couleurs, ombres, rayons ni paramètres de mouvement arbitraires.

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

## La question centrale, et la réponse est non

IUX-033 avait proposé une seule ligne pour réconcilier sept décisions de focus
prises indépendamment : *l'utilisateur l'a-t-il demandé ?* Mesuré sur les
sept : **cinq tiennent**, les deux motifs de formulaire non.

`_handleSubmit` incrémente `_attempt`, mais sur le chemin **accepté** il
n'appelle jamais le déplacement de focus, donc `_focusedAttempt` n'est jamais
remis à niveau. La condition devient alors définitivement vraie, et **chaque**
`didUpdateWidget` ultérieur portant un champ rejeté déplace le focus.

Mesuré : l'utilisateur envoie avec succès, corrige un champ, tabule — le
parent répond au contrôle de **perte de focus** — et le curseur est arraché
vers le résumé. Il n'avait rien demandé.

Et ce n'est pas une correction d'une ligne : remonter l'affectation ne fait
rien puisque la méthode n'est pas appelée sur ce chemin ; l'affecter dans
`_handleSubmit` corrige ceci et **casse** le comportement délibéré « un rejet
qui arrive après l'envoi déplace quand même le focus », dans les deux suites —
vérifié en le faisant. Il faut une fenêtre bornée de soumission en attente,
c'est-à-dire une décision.

Le test était une bonne description de l'intention, pas du code.

## Ce que personne n'honore ni ne lit

**Deux membres sur quatre d'`IuxConfirmationPolicy` ne sont honorés par rien.**
`IuxConfirmByHold` sur un `IuxButton` simple exécute `onActivate` au premier
tap. Distinct d'IUX-BUTTON-CONFIRM-001 : là c'était un honoreur sur quatre,
ici c'est **zéro**.

`IuxActionDescriptor.importance` est stocké, copié, comparé, haché — et lu par
**zéro** site d'appel : `high` et `low` rendent et s'annoncent à l'identique.
Le tableau des dimensions affirmait que `role` sert « à la sémantique, au
retour et à la sélection de motif » : mesuré, aucun des trois.

`IuxElevation` est une énumération **exportée entière sans aucune référence**.

## Un nom pour trois choses, une chose sous deux noms

`summary` désigne une `String`, un objet de libellés et une fonction — même
nom, sens différents, la pire forme. Et `IuxInlineFeedbackAction` /
`IuxTransientAction` sont identiques champ pour champ : déplacer un contrôle
d'une bannière vers un bandeau oblige à le reconstruire.

## Ce qui est propre, dit franchement

`selectedIndex` cohérent 4/4. La famille des libellés de sortie : chaque
différence porte un sens. L'appariement `label`/`semanticLabel`. Le câblage
`autofocus`/`focusNode`.

**Et une correction à IUX-038 :** sur 59 constructeurs publics, exactement un
atteint onze paramètres, et aucun des onze n'est un bouton de style. §20 vise
la couleur, l'élévation, le rayon et l'ombre ; celui-ci est fait
d'emplacements de contenu et de plomberie de focus. L'argument « widget à onze
paramètres » qu'IUX-038 opposait à la fusion du contrôle de divulgation ne
porte pas le poids qu'il paraissait avoir. Ses deux autres raisons tiennent.

## Aucun test creux

Il a douté d'un test et l'a cassé pour vérifier : il échoue correctement. Il
n'est pas creux — seulement monté sur le seul chemin où le défaut est
invisible, ce qui est exactement ce qui a permis au défaut d'être livré.

13 tests mécaniques plus deux épingles de défaut.
