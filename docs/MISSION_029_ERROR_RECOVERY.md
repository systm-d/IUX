---
mission_id: IUX-029
title: Error Recovery
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
  - IUX-028
platform_priority: Android
package_name: iux_flutter
---

# IUX-029 — Error Recovery

## 1. Références obligatoires
Lire intégralement PROJECT_PROMPT.md, COMPONENT_STANDARD.md, les missions dépendantes, ADR et architecture ; vérifier leurs statuts avant toute modification.

## 2. Contexte
Cette mission apporte récupération d’erreur claire, sans masquer la cause ou imposer une action pour la première version exploitable.

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
Concevoir une API concise autour de IuxErrorRecovery, sans couleurs, ombres, rayons ni paramètres de mouvement arbitraires.

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

## La sortie fait partie de l'erreur

Un type scellé : une erreur sans issue doit être **déclarée** comme telle.

`IuxRetryRoute` n'accepte aucun `IuxActionDescriptor`. Rôle, politique de
répétition, importance et confirmation sont fixés parce qu'aucun n'est une
décision qu'il faut offrir à l'appelant. Et il n'y a pas de `availability` non
plus : le fichier argumentait déjà qu'un parent à court de budget de réessai
doit **changer de route**, pas griser le contrôle — retirer le paramètre est
ce qui rend cette règle applicable plutôt que consultative.

## Honnête sur ce qui n'est pas garanti

Inconstructible : `IuxEmptyStateAction` refuse `IuxActionRole.retry`, et
`IuxAlternativeRoute` dérive `navigate` sans moyen de devenir un réessai — les
deux motifs ne peuvent pas se confondre, d'aucun côté.

Pas applicable : savoir si *une* panne donnée est réessayable demande un code
de statut que le framework n'a pas. Aucune garantie n'a été simulée ; le
système de types réduit la revendication à un mot relisible dans le diff.

## Rien ne réessaie tout seul

Aucune minuterie, aucun compteur, aucun repli exponentiel. Testé en pompant
trente secondes et en exigeant zéro tentative. Conséquence assumée : le motif
n'impose aucune limite de temps, donc SC 2.2.1 n'a rien à ajuster.

## Le focus n'est pas déplacé, et il n'y a pas de crochet pour le déplacer

L'inverse d'`IuxForm`, délibérément : le formulaire déplace le focus parce
qu'il **sait** que l'utilisateur vient d'appuyer sur envoyer. Ici rien ne le
sait — une opération peut échouer pendant qu'il tape ailleurs.

L'argument décisif est propre à ce motif : un focus qui atterrit sur un
réessai **arme une activation** sous le prochain Entrée ou double-tap de
lecteur d'écran. Le seul contrôle de la bibliothèque qui ne doit jamais partir
deux fois serait celui qui se serait armé lui-même. Mesuré, pas affirmé.

## Ce que l'audit a trouvé dans le code préservé

**Un champ public que rien ne pouvait lire** — `IuxRetryRoute.alternative`,
une « seconde issue ». Il se contredisait lui-même : la doc
d'`IuxAlternativeRoute`, douze lignes plus bas, argumente qu'une seule action
est une limite délibérée. Et il rendait l'exhaustivité du type scellé à moitié
fausse. Supprimé.

**Une doc promettant une capacité absente.** La prose disait que le contrôle
« refuse l'activation pendant que l'opération est en vol, via le même
`IuxActionRepeatPolicy` qui empêche un "Payer" double-tapé de débiter deux
fois ». Le type n'avait ni politique de répétition, ni descripteur, et
n'importait même pas le modèle d'action. La promesse faisait un vrai travail
de sûreté dans le texte tout en étant fausse dans le code. **Rendue vraie** :
les deux routes exposent désormais un descripteur dérivé, et le widget délègue
à `IuxButton`, donc `IuxActionPolicy` est l'unique implémentation de la règle.

36 tests.
