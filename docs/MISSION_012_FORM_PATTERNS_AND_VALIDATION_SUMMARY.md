---
mission_id: IUX-012
title: Form Patterns and Validation Summary
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
  - IUX-011
platform_priority: Android
package_name: iux_flutter
---

# IUX-012 — Form Patterns and Validation Summary

## 1. Références obligatoires
Lire intégralement PROJECT_PROMPT.md, COMPONENT_STANDARD.md, les missions dépendantes, les ADR et l’architecture. Vérifier leurs statuts avant modification.

## 2. Contexte
Cette mission poursuit la première version exploitable en apportant composition de formulaires, résumé de validation et guidage vers les erreurs.

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
Concevoir une API publique concise autour de IuxFormSection, IuxValidationSummary. Elle ne doit exposer ni couleurs, ni ombres, ni rayons, ni valeurs de mouvement arbitraires.

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

## Quand valider

**`onBlur` par défaut** : un champ est vérifié quand l'utilisateur le quitte
*après l'avoir édité*, et tous les champs à la soumission.

La défense : valider à chaque frappe signale une erreur sur une valeur qui
n'était pas fausse, seulement inachevée. Valider seulement à la soumission
rend tous les problèmes d'un coup, au moment précis où l'utilisateur se croyait
arrivé. Le blur signale un champ à la fois, après la tentative et avant qu'il
soit allé assez loin pour devoir revenir.

Deux garde-fous rendent ça sûr :

- **`IuxFormField.edited` (faux par défaut)** conditionne la vérification au
  blur. Sans lui, tabuler jusqu'au bouton d'envoi produirait une colonne
  d'erreurs « obligatoire » sur des champs que personne n'a touchés. Le défaut
  prudent : un formulaire qui ne vérifie rien au blur est moins utile ; un qui
  vérifie des champs intouchés est activement faux.
- **Pas de valeur `onChange`** : le formulaire ne voit pas les frappes. Un
  réglage qu'il ne pourrait pas honorer serait un mensonge.

## Envoi refusé

Le focus va au **récapitulatif**, pas au premier champ invalide. Il énonce
combien de problèmes existent, préserve le choix de l'ordre de réparation, et
c'est **la même destination à chaque fois** — ce qu'une règle « premier champ »
n'est pas. Coût énoncé : pour une erreur unique, c'est un saut de plus.

Le récapitulatif n'est délibérément **pas** une région live : le focus l'annonce
déjà, les deux le feraient prononcer deux fois.

`IuxFormSubmit` **refuse à la construction** une action désactivée sans
`unavailabilityReason` — le bouton d'envoi grisé qui ne dit jamais pourquoi est
le refus silencieux canonique.

## Un refus cohérent

Bloquer l'envoi pendant qu'une vérification est en `validating` a été rejeté
pour la même raison : bloquer sur quelque chose que le framework ne peut pas
expliquer *est* un refus silencieux.

## Nom

`IuxForm`, pas `IuxGuidedForm` — la mission 033 possède ce nom pour la variante
par étapes.

## Tests

49 nouveaux tests.
