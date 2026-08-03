---
mission_id: IUX-022
title: Avatar, Icon and Media Presentation
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
  - IUX-021
platform_priority: Android
package_name: iux_flutter
---

# IUX-022 — Avatar, Icon and Media Presentation

## 1. Références obligatoires
Lire intégralement PROJECT_PROMPT.md, COMPONENT_STANDARD.md, les missions dépendantes, les ADR et l’architecture. Vérifier leurs statuts avant modification.

## 2. Contexte
Cette mission poursuit la première version exploitable en apportant présentation d’avatar, icône et média avec alternatives textuelles.

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
Concevoir une API publique concise autour de IuxAvatar, IuxIcon. Elle ne doit exposer ni couleurs, ni ombres, ni rayons, ni valeurs de mouvement arbitraires.

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

## Décoratif ou porteur de sens : énoncé, jamais déduit

`IuxImageDescription` est un paramètre **requis sans défaut**, avec exactement
deux constructeurs : `.meaningful(String)` — qui assert non vide — et
`.decorative()`.

Pas de libellé nullable. Un `String?` où `null` signifie discrètement
« décoratif » confond « je ne l'ai pas encore écrit » et « ça ne dit rien ».

Et `isDecorative` est un **champ**, pas une déduction sur chaîne vide : déduire
rendrait une description oubliée et une absence délibérée identiques en
release, là où les assertions ne tournent plus.

## Les initiales sont dessinées, jamais annoncées

Structurellement : `IuxSemantics.image` exclut les sémantiques descendantes,
donc aucun agencement de paramètres ne fait prononcer « JD ».

Et IUX ne **dérive** jamais les initiales d'un nom — cette règle casse pour
李明, van der Berg, les mononymes, et toute écriture sans espaces. L'appelant
les fournit.

## Échec d'image

`IuxAvatar` **n'a pas d'état d'échec par construction** : la photo est
dessinée *par-dessus* un repli déjà présent. Hors ligne, 404, lent ou corrompu,
l'utilisateur voit ce qu'il voyait l'instant d'avant.

`IuxImage` rapporte l'échec, parce que là l'image *était* l'information. Une
image porteuse de sens qui échoue **rend sa propre description en texte** —
le comportement de `alt` en HTML, autour duquel WCAG SC 1.1.1 est écrit. Le
rôle du nœud passe d'image à texte, parce que la vérité a changé. Une image
décorative qui échoue garde sa place et se tait : rien n'a été perdu, donc un
glyphe cassé serait un message d'erreur à propos d'un non-événement.

## Tests

46 nouveaux tests. Les trois états sont pilotés par de faux `ImageProvider`
résolvant immédiatement, jamais, et en erreur.

## Limites

- Aucun test ne peut juger si une description est *compréhensible* :
  « Image » passe tout et n'aide personne.
- Un utilisateur de lecteur d'écran n'est pas informé de l'*échec* ; il reçoit
  la description en texte.
- Une image échouée a besoin de place pour grandir. Épinglée dans une boîte à
  hauteur fixe, une longue description à 200 % déborde visiblement —
  délibéré : un débordement en debug est un rapport de bug, une troncature
  silencieuse est de l'information qui disparaît.
