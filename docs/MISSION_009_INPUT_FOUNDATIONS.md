---
mission_id: IUX-009
title: Input Foundations
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
  - IUX-008.9
platform_priority: Android
package_name: iux_flutter
---

# IUX-009 — Input Foundations

## 1. Références obligatoires
Lire intégralement PROJECT_PROMPT.md, COMPONENT_STANDARD.md, les missions dépendantes, les ADR et l’architecture. Vérifier leurs statuts avant modification.

## 2. Contexte
Cette mission poursuit la première version exploitable en apportant fondations de saisie : état, label, aide, erreur, focus et résolution de thème sans champ final.

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
Concevoir une API publique concise autour de IuxInputState, IuxInputThemeData. Elle ne doit exposer ni couleurs, ni ombres, ni rayons, ni valeurs de mouvement arbitraires.

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

## Résumé

Modèle et thème de saisie, sans widget. Implémentée par un sous-agent, revue
et intégrée par le chef d'équipe.

## Décisions notables

- **`readOnly` existe ici, et c'est le gain du modèle d'action.**
  `IuxActionAvailability` l'avait explicitement refusé au motif que « read-only
  décrit un champ ». `IuxInputAvailability` en a trois, et la conséquence est
  concrète : un champ en lecture seule reste dans le parcours de focus, un
  champ désactivé non — donc sa valeur n'est pas « annoncée comme figée »,
  elle n'est jamais annoncée du tout.
- **Le message d'erreur est structurellement impossible à omettre** :
  `IuxInputValidation.invalid(String message)` exige un message non vide. On
  ne peut pas dire « faux » sans dire en quoi.
- **Le remplissage ne devient pas rouge** : cela mettrait l'erreur dans le seul
  canal qu'un daltonien ne lit pas, et dégraderait le contraste de la valeur
  à corriger. C'est la bordure qui épaissit.
- **Le texte d'aide survit à l'erreur.** Remplacer l'instruction par l'erreur
  supprime la phrase qui explique comment écrire une valeur correcte au moment
  précis où l'utilisateur a prouvé qu'il en avait besoin.
- **`copyWith` volontairement absent de `IuxInputValidation`** — seule
  dérogation à la règle « tout type valeur a un copyWith ». Une copie changeant
  seulement le statut produirait un champ invalide portant son ancien message
  de succès.

## Deux constats mesurés

- Le placeholder utilise `content.secondary` : `content.tertiary` mesure
  **4,45:1** sur la surface remplie en clair, sous le minimum.
- `surface.subtle` et `surface.interactive` sont **identiques sur les quatre
  palettes** — un champ en lecture seule n'est donc pas distingué par son fond.
  Vérifié par mes soins. Consigné comme écart ouvert `IUX-SURFACE-001`.

## Tests

63 nouveaux tests. Un test de contrat dédié applique les interdits mécaniques
à `lib/src/inputs/`, que `component_standard_test` ne couvre pas (il ne glob
que `/components/` et `/patterns/`).

## Limites

- Aucun widget : sémantiques, ordre de focus, clavier, texte 200 %, RTL et
  retour à la ligne ne sont ici qu'approchés. IUX-010.
- Invariants en assertions, donc debug uniquement.
- Les couleurs se résolvent contre `surface.base` ; un champ sur une surface
  élevée hérite de cette hypothèse.
