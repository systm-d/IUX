---
mission_id: IUX-030
title: Loading and Retry Pattern
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
  - IUX-029
platform_priority: Android
package_name: iux_flutter
---

# IUX-030 — Loading and Retry Pattern

## 1. Références obligatoires
Lire intégralement PROJECT_PROMPT.md, COMPONENT_STANDARD.md, les missions dépendantes, ADR et architecture ; vérifier leurs statuts avant toute modification.

## 2. Contexte
Cette mission apporte pattern de chargement et de nouvelle tentative contrôlé par le parent pour la première version exploitable.

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
Concevoir une API concise autour de IuxLoadingRetry, sans couleurs, ombres, rayons ni paramètres de mouvement arbitraires.

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

## Quatre états, trois branches

Pas de `IuxLoadState.empty`. Un résultat vide est `ready` avec une valeur
vide, et le constructeur nomme la situation avec `IuxEmptyState`. Une
quatrième valeur écraserait les quatre situations d'`IuxEmptyStateCause` en un
seul mot, remettant « Ajoutez votre première facture » à une valeur d'énum de
« sous un filtre qui en cache quarante ».

## Rien ne réessaie, rien n'expire

Trois garde-fous contre une tempête déclenchée par l'utilisateur : le contrôle
n'existe pas pendant le chargement ; `ignoreWhileInProgress` du descripteur
dérivé absorbe les activations qui se chevauchent ; et il n'y a aucun drapeau
de disponibilité à mal positionner.

Comme rien n'expire, **SC 2.2.1 n'a aucune limite de temps à contraindre** —
un délai imposé par le framework en aurait *créé* une, sur un écran sans moyen
de la prolonger.

## Ce qui a été mesuré

Une traversée de la barre indéterminée : **1800 ms** au mouvement standard,
jamais plus court en `reduced`, `Duration.zero` en `none`.

C'est ce qui fonde l'argument sur le délai : un chargement résolu en 80 ms
montre la barre moins d'un vingtième d'une traversée. L'utilisateur voit une
chose apparaître à une position et disparaître de cette position — voilà
pourquoi ça se lit comme un défaut de rendu et non comme du travail.

Le seuil d'environ 0,1 s (Miller 1968, Nielsen 1993) est documenté comme
celui de **l'appelant** : un parent qui attend une réponse dans ce délai ne
devrait pas entrer en `loading` du tout.

## La décision qui a refait la mission en vol

IUX-029 a atterri pendant l'écriture des tests. L'agent avait construit un
modèle de réessai avec quatre assertions ; IUX-029 livrait un type scellé qui
rend **inconstructibles** ces quatre mêmes choses.

Il a supprimé sa version. Elle était strictement inférieure : pas de
`categoryLabel` — le seul porteur de « ceci est une panne » qui survive à un
lecteur d'écran (SC 1.4.1) — et elle permettait une panne sans issue, ce
qu'`IuxErrorRecovery` refuse structurellement.

`IuxLoadingRetry` ne dessine plus rien lui-même : il compose, et toute sa
contribution est l'invariant entre les deux.

## Un type scellé générique cassait l'égalité

Les trois sous-classes comparaient par test de type pendant que `hashCode`
intégrait `T`. Les génériques Dart étant covariants, `IuxLoadReady<int>`
**est** un `IuxLoadReady<Object>` : `loose == tight` était vrai, `tight ==
loose` faux, et les hachages divergeaient. Une valeur qu'un `Set` détient deux
fois et qu'une `Map` ne retrouve jamais.

C'est le premier type scellé **générique** du projet, d'où le fait que le
motif de comparaison correct partout ailleurs était silencieusement faux ici.

## Le défaut trouvé ailleurs

L'agent a trouvé qu'`IuxButton` confond « en cours » et « indisponible ». Il
l'a trouvé **en sondant, pas en lisant** : il avait écrit une documentation
affirmant que le flux de réessai sur place *préservait* le focus, et son test
l'a démentie. Consigné IUX-BUTTON-BUSY-001, vérifié indépendamment, et
programmé avec IUX-A11Y-FOCUS-001.

42 tests.
