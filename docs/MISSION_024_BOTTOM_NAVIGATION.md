---
mission_id: IUX-024
title: Bottom Navigation
priority: high
status: completed
started_at: 2026-08-03
started_by: Claude (subagent)
last_updated_at: 2026-08-01
completion_status: accepted
validation_status: passed
target_version: 0.2.0-dev
compatibility: additive
depends_on:
  - IUX-023
platform_priority: Android
package_name: iux_flutter
---

# IUX-024 — Bottom Navigation

## 1. Références obligatoires
Lire intégralement PROJECT_PROMPT.md, COMPONENT_STANDARD.md, les missions dépendantes, ADR et architecture ; vérifier leurs statuts avant toute modification.

## 2. Contexte
Cette mission apporte navigation mobile principale à trois à cinq destinations pour la première version exploitable.

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
Concevoir une API concise autour de IuxBottomNavigation, sans couleurs, ombres, rayons ni paramètres de mouvement arbitraires.

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

## Les libellés : toujours, et le coût est payé en reflux

Aucun `labelBehavior`, aucun `showLabel`, aucune forme icône seule. Une
navigation en icônes est un jeu de devinettes ; n'étiqueter que la destination
courante nomme le seul endroit que l'utilisateur sait déjà, et déplace la mise
en page à chaque choix.

Le coût d'espace est payé **en reflux, pas en masquage** : au-delà d'environ
130 % de texte, les destinations cessent de partager une rangée et s'empilent
en pleine largeur, glyphe à côté du nom — un nom dispose alors de 320 px au
lieu de 56.

Mesuré sur 320 px : cinq destinations à 200 % coûtent 360 px d'un écran de
640 px, chaque nom entier et sur une ligne. Les alternatives : masquer les
libellés économise ~130 px et laisse cinq glyphes anonymes à l'utilisateur le
plus susceptible de lire à la loupe ; garder la rangée rend « Notifications »
en `Noti / fica / tion / s` dans une colonne de 56 px — le même espace dépensé
en quelque chose d'illisible.

Au-delà d'environ 250 % avec cinq destinations, la barre défile au lieu de
faire disparaître une destination. Documenté comme une dégradation, pas comme
une fonctionnalité.

## `checked`, pas `selected`

Un nœud coché est annoncé **dans les deux états**, donc l'utilisateur apprend
où il se trouve depuis la destination sur laquelle il atterrit, au lieu de
balayer la barre pour trouver celle qui a parlé.

## Un écart assumé au plancher d'espacement

Les destinations pavent la barre bord à bord. Un espacement créerait quatre
bandes mortes dans la zone du pouce, et SC 2.5.8 traite justement l'espacement
comme une *alternative* à la taille — or 64 × 112 dépasse 48 largement.

## Tests

41 nouveaux tests.

## Ce que cette mission a trouvé chez moi

L'agent a signalé un échec dans `test/iux_flutter_test.dart` : mon assertion
« seuls les patterns restent non exportés » était devenue fausse quand j'ai
exporté les patterns en 008.7 et 012. Elle a été remplacée par l'invariant
réel — tout export appartient à une couche que le standard nomme.
