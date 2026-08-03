---
mission_id: IUX-023
title: App Bar and Top-Level Structure
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
  - IUX-022
platform_priority: Android
package_name: iux_flutter
---

# IUX-023 — App Bar and Top-Level Structure

## 1. Références obligatoires
Lire intégralement PROJECT_PROMPT.md, COMPONENT_STANDARD.md, les missions dépendantes, les ADR et l’architecture. Vérifier leurs statuts avant modification.

## 2. Contexte
Cette mission poursuit la première version exploitable en apportant structure haute de page, titre, actions et navigation de retour.

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
Concevoir une API publique concise autour de IuxAppBar, IuxPage. Elle ne doit exposer ni couleurs, ni ombres, ni rayons, ni valeurs de mouvement arbitraires.

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

## Ce qui cède à 200 % sur 320 px

La **rangée partagée**, puis la **hauteur de la barre**. Avec un retour et deux
actions, les contrôles gardent leur rangée et le titre prend celle du dessous,
pleine largeur — mesuré à plus de 85 % des 320 px.

`maxLines` est nul, l'overflow n'est jamais `ellipsis`, `softWrap` est vrai :
**aucun chemin de code n'abrège un titre**.

La décision d'empiler est **mesurée, pas seuillée** : un `TextPainter` donne la
largeur réelle sur une ligne à l'échelle réelle, et la largeur du bandeau de
contrôles vient de `IuxButtonResolver` — en demandant sa géométrie au bouton
plutôt qu'en la redéclarant.

L'agent a **refusé** de brancher sur `IuxAccessibility.prefersStackedLayout` :
sa propre documentation qualifie le seuil de 1,3× d'heuristique, et il
empilerait un titre de deux mots sur une tablette tout en laissant un titre
long à l'étroit à 100 % sur un téléphone.

## Pas un `PreferredSizeWidget`, et la raison est honnête

`Scaffold.appBar` lit `preferredSize` **avant** la mise en page : sans
`BuildContext`, sans échelle de texte, sans largeur, sans nombre de lignes —
puis plafonne la barre à cette hauteur. L'`AppBar` de Material échoue de la
même façon un étage plus bas.

Utiliser l'un ou l'autre aurait livré exactement le titre tronqué que ce
composant existe pour empêcher. `IuxAppBar` se compose donc dans le *corps* du
`Scaffold`, au-dessus d'`IuxPage` — le précédent posé par `IuxPage` qui se
compose au lieu d'absorber. Deux tests le verrouillent.

Le coût est tabulé dans la doc : `SystemUiOverlayStyle`, bouton de tiroir
automatique, scroll-under.

## Garanties de nommage

`actions` est typé `List<IuxIconButton>`, pas `List<Widget>` : une action sans
nom est **irreprésentable par le typage**, et la barre hérite de l'anneau de
focus, des sémantiques désactivées et du plancher tactile au lieu d'un chemin
parallèle.

`IuxAppBarLeading.back` / `.close` exigent un libellé non vide fourni par
l'appelant. `Icons.arrow_back` déclare `matchTextDirection`, donc le miroir RTL
est gratuit.

## Tests

34 nouveaux tests.

## Limite non machinée

La barre consomme l'inset haut, donc la page en dessous doit être en
`IuxPageInsets.bottomOnly`. Aucun composant ne peut inspecter son frère : c'est
documenté et illustré, pas asserté. Un widget de composition possédant les deux
rendrait le double-padding irreprésentable — cela appartient à `patterns/`.
