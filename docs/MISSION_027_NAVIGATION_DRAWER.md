---
mission_id: IUX-027
title: Navigation Drawer
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
  - IUX-026
platform_priority: Android
package_name: iux_flutter
---

# IUX-027 — Navigation Drawer

## 1. Références obligatoires
Lire intégralement PROJECT_PROMPT.md, COMPONENT_STANDARD.md, les missions dépendantes, ADR et architecture ; vérifier leurs statuts avant toute modification.

## 2. Contexte
Cette mission apporte navigation secondaire latérale accessible pour la première version exploitable.

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
Concevoir une API concise autour de IuxNavigationDrawer, sans couleurs, ombres, rayons ni paramètres de mouvement arbitraires.

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

## Un tiroir est une couche, jamais une route

Le parent possède un drapeau, et le tiroir existe exactement tant que le
drapeau est vrai. Aucun `Navigator`, rien n'est empilé ni dépilé.

## Ce que le sondage a trouvé — et pourquoi la doc mentait sans le savoir

L'exemple d'usage montrait `Stack(children: [page, if (open) drawer])`. L'agent
a sondé l'arbre sémantique réel : dans cette forme, l'élément de la page
survit, son nœud sémantique n'est jamais recompilé, et `BlockSemantics` **ne
retire pas** la page couverte. Un lecteur d'écran continue de lire — et de
proposer d'activer — des contrôles que l'utilisateur ne peut pas toucher.

Le tactile se comporte **identiquement** dans les deux formes. C'est
précisément pour ça que rien d'autre qu'un lecteur d'écran ne l'attrape.

`IuxModalLayer` gagne donc un emplacement `drawer`, et les trois modaux
deviennent mutuellement exclusifs par assertion. La bonne forme n'est plus un
idiome à connaître : c'est la seule que l'appelant peut exprimer. Trois tests
la fixent, dont un qui **échouera le jour où Flutter corrigera le
comportement** — ce jour-là, la justification de l'emplacement et
IUX-OVERLAY-001 seront à relire.

## Ce qui a été mesuré, pas supposé

Cinq arrêts sémantiques exactement : titre (en-tête), Fermer (bouton), puis un
nœud fusionné par destination. Les glyphes ne sont pas des arrêts, le voile non
plus. Cycle de tabulation mesuré `Fermer → dest1 → dest2 → dest3 → panneau →
Fermer` ; douze pressions n'atteignent jamais la page. Le focus revient sur ce
qui le tenait **à l'ouverture**, pas sur où il a dérivé.

Sorties : voile, Échap (y compris après déplacement du focus), retour système
(`handlePopRoute` → `onDismiss`, rien empilé ni dépilé), bouton d'en-tête. Un
appui sur le vide du panneau ne ferme pas.

Géométrie : panneau = min(80 % de l'écran, largeur de contenu étroite). Sur
320×480 → 256 px, laissant exactement les 64 px annoncés.

## Écarts assumés

`PopScope` vit dans le tiroir, contrairement au dialogue et à la feuille qui le
délèguent : le retour est la **première** chose qu'un utilisateur Android
essaie sur un tiroir, et « documenté » n'est pas « fonctionne » (SC 2.1.2). Un
test vérifie qu'il est inerte sans `Navigator` au-dessus, puisque le code le
prétend.

`Semantics` nu plutôt que `IuxSemantics.selection` : `selection` pose
`excludeSemantics`, ce qui supprimerait le badge de l'annonce de tout
utilisateur de lecteur d'écran.

61 tests.
