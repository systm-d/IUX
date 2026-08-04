---
mission_id: IUX-037
title: Catalog Consolidation
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
  - IUX-036
platform_priority: Android
package_name: iux_flutter
---

# IUX-037 — Catalog Consolidation

## 1. Références obligatoires
Lire intégralement PROJECT_PROMPT.md, COMPONENT_STANDARD.md, les missions dépendantes, ADR et architecture ; vérifier leurs statuts avant toute modification.

## 2. Contexte
Cette mission apporte consolidation du catalogue comme outil de comportement et documentation pour la première version exploitable.

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
Concevoir une API concise autour de catalog integration suite, sans couleurs, ombres, rayons ni paramètres de mouvement arbitraires.

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

## L'audit : sept fichiers orphelins

Le travail survivant n'était ni propre à l'analyse ni **câblé**.
`status_panels.dart` avait été coupé en plein import, et surtout — ce que
`flutter analyze` ne peut structurellement pas voir — `main.dart` avait encore
une énumération de sections à trois valeurs. Les **sept** nouveaux fichiers
étaient donc du code mort, jamais construit une seule fois.

Les câbler a immédiatement produit deux plantages réels.

## Sept constats, dont un plantage sur l'appel le plus évident

**`IuxButton(expand: true)` dans `IuxTargetSpacing` lève une exception.** Deux
boutons pleine largeur empilés — ce que n'importe qui écrit en premier —
échouent sur *BoxConstraints forces an infinite width*, parce que
`IuxTargetSpacing` est un `Wrap` sur les deux axes. Le contournement
(`Column` + `IuxGap`) fonctionne en **abandonnant le plancher d'espacement de
8 px que ce primitif existe précisément pour garantir**. Les deux dispositions
sont désormais à l'écran.

**Ouvrir un modal détruit le widget qui l'a ouvert.** IUX-OVERLAY-001 était
documenté comme une perte de position de défilement ; la reconstruction
**dispose** aussi le panneau, dont le rappel lève alors
`setState() called after dispose()` sur le tap même qui répond au dialogue.

**Un libellé de fermeture plus long déborde l'en-tête du tiroir de 7,5 px à
100 % de texte**, sur des surfaces de 800 et 1200 de large — et il ne
s'empile qu'au-delà d'environ 130 %. Autrement dit : **agrandir le texte
corrige le problème, ne rien faire ne le corrige pas.**

**Le rail peut être plus large que sa propre fenêtre** : à 300 % dans une
boîte de 360×320, le reste est négatif et la `Row` déborde de 36 px. La règle
pèse ce qui *reste*, elle ne demande jamais si le rail *tient*.

**`IuxProgressIndicator.valueLabel` n'est pas confronté à `value`** : une
barre à 45 % peut annoncer « 90 % ». Les deux publics reçoivent des
informations différentes et aucun n'est averti.

**Cinq pages de documentation périmées**, dont deux qui nient l'existence
d'emplacements d'`IuxModalLayer` que le catalogue utilise désormais, et une qui
affirme « Assertée. » là où il n'y a aucune assertion — le composant choisit
silencieusement la barre.

## Navigabilité traitée comme un problème, pas ignorée

Treize sections plus sept rangées de conditions dépassaient un écran à 300 %.
L'en-tête se replie donc en gardant une ligne de résumé qui nomme la
combinaison — une capture à en-tête replié reste une preuve.

## Retenu délibérément

Deux scènes produisent des échecs de debug qui feraient tomber le harnais.
Elles impriment les nombres mesurés et retiennent l'échantillon, plutôt que de
faire semblant.

36 tests, APK de debug construit.
