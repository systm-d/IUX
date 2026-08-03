---
mission_id: IUX-032
title: Destructive Flow Pattern
priority: high
status: completed
started_at: 2026-08-03
started_by: IUX-032 implementation agent
last_updated_at: 2026-08-03
completion_status: accepted
validation_status: passed
target_version: 0.2.0-dev
compatibility: additive
depends_on:
  - IUX-031
platform_priority: Android
package_name: iux_flutter
---

# IUX-032 — Destructive Flow Pattern

## 1. Références obligatoires
Lire intégralement PROJECT_PROMPT.md, COMPONENT_STANDARD.md, les missions dépendantes, ADR et architecture ; vérifier leurs statuts avant toute modification.

## 2. Contexte
Cette mission apporte flux de suppression proportionné, confirmation et possibilité de retour pour la première version exploitable.

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
Concevoir une API concise autour de IuxDestructiveFlow, sans couleurs, ombres, rayons ni paramètres de mouvement arbitraires.

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

## L'audit d'abord, et il a trouvé exactement deux manques

IUX-008.7 livrait le contrôle, la politique et le dialogue. Manquaient :

**La proportionnalité n'existait nulle part.** `IuxActionReversibility` décrit
*si ça revient*, jamais *combien part*. Rien ne distinguait un brouillon d'un
compte, et 008.7 prenait le `confirmation:` de l'appelant pour argent comptant.

**Le retour en arrière n'existait pas en code.** La doc de 008.7 le disait
elle-même dans ses limites : « aucun undo n'est modélisé… documente la
recette, ne l'implémente pas ». La recette était de la prose. Rien ne
vérifiait qu'un flux se déclarant réversible avec `confirmation: none` offrait
effectivement quelque chose — le piège symétrique de IUX-BUTTON-CONFIRM-001 :
**la suppression part au premier tap, personne n'est consulté, et rien n'est
offert.**

## Une question que l'appelant ne peut pas rater

Pas « à quel point est-ce grave » — personne n'y répond de façon cohérente.
Mais : **« l'utilisateur pourrait-il énumérer ce qu'il s'apprête à perdre ? »**

Un brouillon, quarante-et-une photos sélectionnées, l'accès d'une personne →
`items`. Un compte, un espace de travail, un dossier et son contenu →
`everything`.

Ce qui rend la distinction décisive : une offre d'annulation ne protège que
quelqu'un capable de **s'apercevoir qu'il en a besoin**. Qui a supprimé le
mauvais brouillon le sait immédiatement ; qui a supprimé un compte ne peut pas
inspecter ce qui est parti et quitte généralement déjà l'écran qui porte
l'offre. Donc `everything` + annulation est refusé.

Deux valeurs et non quatre, argumenté au lieu d'être caché : il n'y a que deux
sauvegardes à répartir, donc une échelle à quatre barreaux en aurait deux qui
ne changent rien — API publique morte au sens du §19.

## Le retour est requis, donc son absence est une affirmation

`IuxWayBack` est scellé et **requis**. `IuxNoWayBack` signifie « aucun contrôle
que ce motif puisse mettre devant l'utilisateur », pas « détruit à jamais » :
une corbeille est une conséquence à énoncer *avant* la réponse, pas une offre
à faire après.

Refusé dans les deux sens : offrir *et* demander (interrompt tout le monde et
laisse quand même un contrôle), ni l'un ni l'autre (la suppression dont
personne n'a été protégé).

## Aucune fenêtre imposée, et pourquoi

SC 2.2.1 n'est donc pas engagé : aucune limite de temps n'est posée par le
contenu. Si l'application valide sur sa propre horloge, **c'est elle** qui a
créé la limite et qui en hérite l'obligation.

Aucun défaut n'est livré, parce que cinq secondes veulent dire trois choses
différentes selon qu'on voit l'écran, qu'on est trois phrases derrière avec un
lecteur d'écran, ou qu'on utilise un contacteur.

Et l'absence de délai n'est pas une invention : IUX-021 avait déjà décidé
qu'un message transitoire portant une action n'a aucune durée. Réutilisé,
vérifié depuis le calcul puis **comportementalement**, en pompant soixante
secondes avec le contrôle d'annulation toujours présent.

## Sur IUX-BUTTON-CONFIRM-001

L'agent n'a **pas** retenté ma correction — il a lu l'entrée d'abord. Sa
conception rend le piège inatteignable *dans ce motif*, par une autre voie :
le descripteur est dérivé et jamais publié. Il a dit lui-même que c'est une
fermeture locale et pas une correction, et il a trouvé **une voie d'accès
supplémentaire** que je n'avais pas : `IuxDestructiveActionController.action`
est un getter public qui rend un descripteur portant encore la confirmation.
Le défaut est donc reproductible depuis l'intérieur du motif censé l'empêcher.

## Tests prouvés non creux

Trois cassages distincts, chacun annulé et le fichier rediffé identique :
retirer l'assertion de portée → 2 échecs ; retirer l'action de la notice
dérivée → **11** échecs, dont celui du « pas de délai » ; forcer
`confirmation: none` → 12 échecs.

50 tests.
