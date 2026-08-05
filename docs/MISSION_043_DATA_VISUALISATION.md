---
mission_id: IUX-043
title: Data Visualisation
priority: medium
status: completed
started_at: 2026-08-05
started_by: agent/iux-043-data-visualisation
last_updated_at: 2026-08-05
completion_status: accepted
validation_status: passed
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

---

# Rapport final

## Commandes réellement exécutées

Depuis `packages/iux_flutter/` :

```
flutter analyze   → No issues found
flutter test      → 2290 tests, tous verts
```

Depuis `apps/catalog/` :

```
flutter analyze   → No issues found
flutter test      → 56 tests, tous verts
```

`dart format` appliqué aux fichiers livrés uniquement, pour ne pas réécrire du
code appartenant à des travaux concurrents non commités.

## Tests de contrat, tenus sans exception

Le plafond d'arité à dix paramètres, l'interdiction des chaînes destinées à
l'utilisateur dans `lib/src`, le balayage des jetons morts, le recensement des
énumérations et le tri du barillet ont tous été respectés sans dérogation.
`every enum in lib/src is referenced or resolved` et
`every field of every Iux*Tokens class is read by something` sont restés rouges
entre les livraisons intermédiaires — c'était attendu et documenté, pas
contourné : le premier s'est refermé quand `strokeAsPattern` a nommé
`IuxSeriesStroke`, le second quand `IuxBarChart` a lu `barTrack` et `barHeight`.

## Défauts trouvés en écrivant les tests

1. **Canonicalisation des `const`.** Le test d'égalité par identité
   d'`IuxChartSeries` passait en mesurant le compilateur : Dart fusionne deux
   `const` structurellement identiques en une seule instance. Reconstruit sans
   `const`, il mesure désormais la classe.
2. **`addTearDown(handle.dispose)`.** Flutter vérifie qu'aucun
   `SemanticsHandle` ne survit au test *avant* d'exécuter les tear-downs : un
   handle libéré là est signalé comme fuité. Disposé dans le corps.
3. **Bande à trois colonnes.** Le test « un trou coupe la bande » attendait deux
   formes et en obtenait zéro : avec trois colonnes, chaque côté du trou n'en a
   qu'une, qui n'enferme aucune aire et est correctement écartée. Le test
   mesurait la règle de la colonne unique. Porté à cinq colonnes.
4. **`Transform` non qualifié.** Le test de remplissage RTL des barres mesurait
   un `Transform` de Material, identité dans les deux sens, et passait pour la
   mauvaise raison. Finder restreint au graphe.

## Ce qui n'a pas été validé

- **Aucun appareil réel, aucun lecteur d'écran.** Les widget tests approchent
  TalkBack et rien de plus, limite que porte déjà tout le paquet.
- **Le catalogue n'a pas été lancé.** `flutter run -d linux` demande `ninja` et
  les fichiers de développement GTK 3, absents de la machine de construction.
  Les cinq panneaux sont analysés et testés, jamais regardés. La vérification à
  l'œil du §21 — légende à 300 %, bande en contraste renforcé, première image
  en mouvement réduit, janvier à droite en RTL — reste à faire.
- **Aucune mesure de performance.** §23 demandait qu'aucune allocation ne se
  produise par image ; les chemins sont construits dans `paint` comme prévu,
  mais rien ne l'a chronométré.
