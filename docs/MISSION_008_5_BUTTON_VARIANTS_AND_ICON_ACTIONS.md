---
mission_id: IUX-008.5
epic: IUX-008
title: Button Variants and Icon Actions
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
  - IUX-008.4
platform_priority: Android
package_name: iux_flutter
---

# IUX-008.5 — Button Variants and Icon Actions

## 1. Références obligatoires
Lire intégralement PROJECT_PROMPT.md, COMPONENT_STANDARD.md, les missions dépendantes, les ADR et l’architecture. Vérifier leurs statuts avant modification.

## 2. Contexte
Cette mission poursuit la première version exploitable en apportant déclinaisons filled, outlined, tonal et text ainsi que les actions icône, sans modifier le modèle d’action.

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
Concevoir une API publique concise autour de IuxButtonVariant, IuxIconButton. Elle ne doit exposer ni couleurs, ni ombres, ni rayons, ni valeurs de mouvement arbitraires.

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

`IuxIconButton` et un paramètre `icon` sur `IuxButton`. Implémentée par un
sous-agent, revue et intégrée par le chef d'équipe.

## Garantie centrale

**Un bouton icône sans nom accessible est irreprésentable.**
`IuxIconButton` n'a pas de paramètre `label` : le nom vient de
`IuxActionSemantics.label`, que le modèle d'action assert déjà non vide. Ce
n'est pas une validation, c'est une absence de chemin de code.

## Décisions

- **`IconData`, pas `Widget`** : le bouton dimensionne et colore le glyphe
  depuis `tokens.foreground`, déjà mesuré contre `tokens.background`. Un slot
  `Widget` rendrait cette garantie au site d'appel — la raison même pour
  laquelle il n'y a pas de paramètre `color`.
- **Le glyphe suit le texte, la cible suit le plancher** : taille d'icône via
  `IuxAccessibility.scaleText`, `applyTextScaling` de Flutter désactivé pour
  que l'échelle s'applique exactement une fois.
- **Pas d'icône en position finale** : un glyphe après le libellé se lit comme
  un chevron de navigation, et mélanger les placements coûte un balayage par
  ligne.
- **`IuxButton` assert `variant != icon` et libellé non vide** : les deux
  combinaisons incohérentes que l'API peut exprimer, refusées à l'appel.

## Défaut préexistant trouvé et corrigé

`Container(alignment: Alignment.center)` grandit pour remplir ce que son parent
offre. `IuxButton` dans un `Center` mesurait **792 px de haut** tout en
s'annonçant comme un bouton. Mon test d'IUX-008.4 ne vérifiait que
`>= 48` : il passait au vert.

Corrigé par `Center(widthFactor: 1, heightFactor: 1)`, l'idiome que
`IuxTapTarget` utilisait déjà. Trois tests de régression le verrouillent, et
j'ai ajouté une borne supérieure à mon propre test — un plancher sans plafond
est une demi-assertion.

## Tests

67 tests sur les fichiers bouton (22 + 31 + 14 standard).

## Limites

- Pas d'infobulle : un utilisateur voyant doit reconnaître le glyphe.
  L'aide contextuelle est IUX-018.
- L'échelle d'icône n'est pas plafonnée.
- `IuxButtonTokens.focused` reste toujours faux au niveau widget —
  `IuxFocusable` possède le focus et dessine l'anneau. Token mort ici.
- TalkBack, Voice Access et D-pad restent à valider sur appareil.
