---
mission_id: IUX-010
title: Text Input
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
  - IUX-009
platform_priority: Android
package_name: iux_flutter
---

# IUX-010 — Text Input

## 1. Références obligatoires
Lire intégralement PROJECT_PROMPT.md, COMPONENT_STANDARD.md, les missions dépendantes, les ADR et l’architecture. Vérifier leurs statuts avant modification.

## 2. Contexte
Cette mission poursuit la première version exploitable en apportant champ de texte contrôlé avec libellé, aide, validation externe et saisie accessible.

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
Concevoir une API publique concise autour de IuxTextField. Elle ne doit exposer ni couleurs, ni ombres, ni rayons, ni valeurs de mouvement arbitraires.

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

## Lecture seule sans couleur

L'agent a **vérifié** l'écart `IUX-SURFACE-001` plutôt que de me croire :
`surface.subtle == surface.interactive` sur les quatre palettes, et
`border.standard == border.interactive` sur trois des quatre. Ni le fond ni le
contour ne séparent quoi que ce soit.

Cinq signaux non colorés portent donc la distinction : pas de caret, pas de
clavier logiciel, un **cadenas** au bout de la ligne de lecture (une *forme*,
qui survit au niveau de gris et au daltonisme, et le seul signal présent
*avant* que l'utilisateur essaie quoi que ce soit), pas de placeholder, et
`SemanticsFlag.isReadOnly` prononcé par la plateforme dans la langue de
l'utilisateur.

Lecture seule reste focalisable et copiable ; désactivé sort du parcours.

## Autres décisions

- **`controller` + `onChanged`, tous deux requis.** Une API `value: String`
  serait plus pure mais replace le caret à chaque reconstruction : un
  utilisateur corrigeant le milieu d'un mot finit par taper à la fin. Test de
  régression dédié.
- **Aucun `validator`** : le parent possède la validation.
- **Le placeholder est masqué à la technologie d'assistance**, sinon chaque
  champ vide annonce deux noms.
- **L'erreur épaissit le contour en puisant dans le budget de padding**, donc
  la hauteur de la boîte est identique valide ou non ; seul le message
  apparaît.
- **Obligation exprimée par `Semantics.isRequired`**, pas par un astérisque
  composé.

## Écart au standard, signalé

`_IuxFieldSemantics` compose `Semantics` directement : tous les helpers
`IuxSemantics` posent `excludeSemantics: true`, ce qui supprimerait les
actions set-text, set-selection et move-cursor dont un lecteur d'écran a
besoin pour éditer. Un `IuxSemantics.field` manque dans le runtime — consigné
comme différé.

## Tests

50 nouveaux tests.

## Limites

- L'aide et l'erreur sont des nœuds sémantiques *adjacents*, pas une
  association de type `aria-describedby` — Flutter n'a pas d'équivalent.
- La surbrillance de sélection n'est pas un token IUX et vient du thème
  Material dérivé : son contraste n'est pas mesuré par IUX. Consigné.
