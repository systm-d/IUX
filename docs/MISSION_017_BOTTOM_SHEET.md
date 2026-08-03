---
mission_id: IUX-017
title: Bottom Sheet
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
  - IUX-016
platform_priority: Android
package_name: iux_flutter
---

# IUX-017 — Bottom Sheet

## 1. Références obligatoires
Lire intégralement PROJECT_PROMPT.md, COMPONENT_STANDARD.md, les missions dépendantes, les ADR et l’architecture. Vérifier leurs statuts avant modification.

## 2. Contexte
Cette mission poursuit la première version exploitable en apportant surface modale basse accessible et prévisible.

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
Concevoir une API publique concise autour de IuxBottomSheet. Elle ne doit exposer ni couleurs, ni ombres, ni rayons, ni valeurs de mouvement arbitraires.

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

## L'inset clavier : deux problèmes distincts

**Le soulèvement n'est pas la hauteur du clavier.** Un `Scaffold` avec
`resizeToAvoidBottomInset` par défaut réduit déjà son corps au-dessus du
clavier, sans retirer l'inset du `MediaQuery` que ce corps voit. Ajouter
l'inset complet par-dessus soulève la feuille **deux fois** et laisse une bande
de voile de la hauteur du clavier en dessous.

La feuille se soulève donc du **résidu** :
`max(0, clavier − (hauteurFenêtre − hauteurBoîte))`. Deux tests couvrent les
deux chemins, et chacun vérifie d'abord la hauteur de la boîte — sans quoi l'un
testerait silencieusement l'autre.

Le soulèvement est un `Padding` simple, non animé : la plateforme rapporte
l'inset progressivement, donc il est déjà sur une courbe. L'animer à nouveau
ferait traîner la feuille derrière le clavier.

## Ce que j'ai changé après son rapport

L'agent avait dû lire `MediaQuery` en direct et **déclarer une exception au
standard**. J'ai ajouté `IuxInsets.keyboard` et `IuxInsets.windowHeight` dans
la couche layout : une mesure n'est pas une préférence, et le composant lit
désormais comme n'importe quelle autre métrique. **L'exception a disparu.**

J'ai aussi ouvert `IuxModalLayer` à un emplacement `sheet`, avec une assertion
interdisant dialogue et feuille simultanés.

## Pas de glissement, pas de poignée

Une poignée est invisible à un lecteur d'écran et hors de portée en cas de
tremblement ou de dextérité limitée — et une poignée qui ne glisse pas est un
mensonge. Un test vérifie qu'un glissement vers le bas ne fait rien.

## Il a changé d'avis sur en-tête épinglé, guidé par un test qui échoue

Il avait d'abord épinglé titre + fermeture au-dessus d'un corps défilant. À
200 % de texte sur 320×480, **l'en-tête seul dépassait le plafond de 560 px** —
exactement l'échec que `dialog.md` documente. Tout défile désormais, en-tête
en premier, donc la sortie est visible à l'ouverture et reste le premier
contrôle au clavier.

## Mouvement

`IuxMotionRole.reveal`, pas `enter` : seul `reveal` transforme le déplacement
en fondu sous préférence réduite. `enter` ne fait que raccourcir, et un grand
mouvement rapide est pire qu'un lent pour un trouble vestibulaire.

## Tests

49 nouveaux tests.
