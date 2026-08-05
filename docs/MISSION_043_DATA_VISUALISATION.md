---
mission_id: IUX-043
title: Data Visualisation
priority: medium
status: in_progress
started_at: 2026-08-05
started_by: agent/iux-043-data-visualisation
last_updated_at: 2026-08-05
completion_status: pending
validation_status: pending
target_version: 0.2.0-dev.3
compatibility: additive
depends_on:
  - IUX-042
platform_priority: Android
package_name: iux_flutter
---

# IUX-043 — Data Visualisation

## 1. Références obligatoires
Lire intégralement PROJECT_PROMPT.md, docs/components/component-standard.md, docs/accessibility/color-and-non-color-signals.md, ADR-0005 et ADR-0006 ; vérifier leurs statuts avant toute modification.

## 2. Contexte
IUX ne fournit aucune primitive de dataviz et l'assume. Une première application réelle a besoin de tracer des séries temporelles : soit elle les enferme chez elle sans accessibilité, soit IUX les livre avec.

## 3. Objectif utilisateur
Lire une évolution chiffrée dans le temps — à l'œil comme au lecteur d'écran, sur un écran monochrome comme en contraste renforcé.

## 4. Objectifs de la mission
Livrer trois composants — une courbe multi-séries avec bande de référence, des barres horizontales, une micro-tendance — résolus depuis Foundations, tokens sémantiques, Theme Engine, Accessibility Runtime et Motion.

## 5. Hors périmètre
Aucune interactivité : ni survol, ni infobulle, ni sélection de point, ni zoom. Aucune abstraction universelle de rendu. Aucun calcul de bornes d'axe. Aucun graphe circulaire.

## 6. Audit préalable obligatoire
Inventorier ce qu'IUX peint déjà : aucun CustomPainter n'existe dans lib/. Vérifier qu'aucun jeton de graphe ne double un jeton existant.

## 7. Principes directeurs
La couleur ne porte jamais l'information seule. Le texte n'est jamais peint. L'alternative textuelle n'est pas optionnelle.

## 8. Architecture ou structure cible
`lib/src/components/chart/` : géométrie pure, modèle de données, jetons résolus, trois widgets. La géométrie n'est pas exportée.

## 9. API attendue
`IuxLineChart`, `IuxBarChart`, `IuxSparkline`, et le vocabulaire `IuxChartPoint`, `IuxChartSeries`, `IuxChartBand`, `IuxChartAxis`, `IuxAxisTick`, `IuxChartStop`, `IuxChartBar`, `IuxSeriesStroke`, `IuxSeriesEmphasis`.

## 10. Comportements attendus
Une valeur absente coupe la courbe. Deux séries ne partagent pas un motif de trait. Les bornes viennent de l'appelant.

## 11. Accessibilité
`semanticsSummary` requis sur les trois composants. Exploration au toucher par arrêts positionnés. Agrandissement à 200 % sans troncature. RTL. Contraste renforcé.

## 12. Thèmes et tokens
Une classe `IuxChartTokens` résolue par `IuxChartResolver`, sans extension de thème nouvelle : géométrie, typographie et palette sémantique portent déjà toutes les décisions.

## 13. Mouvement et feedback
Un seul mouvement, le tracé progressif, de rôle `emphasis` — donc retiré dès qu'une réduction est demandée. Aucun feedback haptique.

## 14. Documentation
`docs/components/chart.md`, structuré selon le Component Standard §11, section « Limits » comprise.

## 15. ADR
`docs/decisions/ADR-0010-data-visualisation.md` : pourquoi IUX peint des graphes après avoir écrit qu'il ne le ferait pas.

## 16. Evidence Registry
Aucune décision UX nouvelle nécessitant une entrée : la règle couleur/non-couleur et les contrats de contraste sont déjà enregistrés.

## 17. Tests unitaires
Géométrie, modèle, résolution des jetons.

## 18. Widget tests
Ce qui est peint, compté par le matcher `paints`.

## 19. Tests d'accessibilité
Sémantique, arrêts, agrandissement, RTL, quatre profils de thème.

## 20. Tests de contrat
Les suites existantes doivent rester vertes sans modification : arité, chaînes composées, standard de composants.

## 21. Catalogue
`apps/catalog/lib/chart_panels.dart`, une section dédiée.

## 22. Dépendances
Aucune nouvelle.

## 23. Performance
Aucune allocation par image : les chemins sont construits dans `paint`, `shouldRepaint` compare les entrées.

## 24. Compatibilité
Additive. Aucune API existante n'est modifiée.

## 25. Commandes de validation
`dart format .` à la racine, puis `flutter analyze && flutter test` depuis `packages/iux_flutter/` et depuis `apps/catalog/`.

## 26. Livrables obligatoires
Six fichiers de code, sept fichiers de tests, une page de documentation, un ADR, un panneau de catalogue, les entrées de changelog.

## 27. Critères d'acceptation
Les commandes de validation sont vertes, la documentation nomme ses limites, le catalogue montre les trois composants sous les quatre profils.

## 28. Rapport final attendu
Les commandes réellement exécutées et leur sortie ; ce qui n'a pas été validé sur appareil réel.

## 29. Instruction finale
Ne pas élargir le périmètre. Un graphe interactif est une mission suivante.
