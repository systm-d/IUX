---
mission_id: IUX-031
title: Permission Rationale
priority: high
status: completed
started_at: 2026-08-03
started_by: IUX-031 pattern agent
last_updated_at: 2026-08-03
completion_status: accepted
validation_status: passed
target_version: 0.2.0-dev
compatibility: additive
depends_on:
  - IUX-030
platform_priority: Android
package_name: iux_flutter
---

# IUX-031 — Permission Rationale

## 1. Références obligatoires
Lire intégralement PROJECT_PROMPT.md, COMPONENT_STANDARD.md, les missions dépendantes, ADR et architecture ; vérifier leurs statuts avant toute modification.

## 2. Contexte
Cette mission apporte explication de permission sans remplacer les APIs système pour la première version exploitable.

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
Concevoir une API concise autour de IuxPermissionRationale, sans couleurs, ombres, rayons ni paramètres de mouvement arbitraires.

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

## Trois moments, et la forme de chaque constructeur *est* l'affirmation

Une justification montrée **avant** l'invite système demande l'autorisation de
poser la question. Une justification montrée **après** un refus est autre
chose entièrement, et confondre les deux est la mécanique par laquelle une
application se met à harceler.

Ici elles ne peuvent pas se confondre : ce sont des types différents avec des
constructeurs différents. Une justification qui ne peut pas mener à la
question est inconstructible, et **`IuxSystemWillNotAsk` n'a aucun paramètre
`ask`** — la seule chose rendue irreprésentable plutôt qu'assertée, parce
qu'un bouton proposant de demander une permission que le système refusera de
demander ne produit rien quand on l'active et se lit comme une application
cassée.

## `decline` requis partout, et c'est le brise-boucle

Deux conséquences : l'utilisateur a toujours une sortie, et le parent reçoit
**toujours** le refus — le seul signal qu'une application obtienne indiquant
que l'utilisateur a dit non *au fait d'être sollicité*.

Un motif dépourvu d'un tel signal ne peut que harceler, parce que l'appelant
n'a rien à enregistrer. Ce n'est donc pas un conseil, c'est une structure.

Redemander est permis, une fois, là où l'utilisateur est revenu. L'interdire
pousserait hors du motif toute application ayant besoin de
`shouldShowRequestPermissionRationale`, là où plus rien ne la contraint. La
limite est dite franchement, dans le code et dans la doc : **un parent qui
reconstruit ce bloc à chaque entrée d'écran harcèlera, et aucun widget ne peut
l'en empêcher.**

## Pourquoi le focus ne bouge pas, et pourquoi le danger est pire qu'ailleurs

Le focus arme la prochaine touche Entrée — et le contrôle armé ouvre **l'invite
de permission du système**. Un refus que l'utilisateur n'a jamais voulu donner
peut fermer cette invite **définitivement**.

C'est le quatrième motif à trancher la question du focus, et le premier où le
coût est irréversible.

Le refus vient en premier dans l'ordre de lecture, donc la sortie n'est jamais
après la demande et le contrôle qui ouvre l'invite n'est jamais sous le
premier Entrée. Les deux réponses sont de vrais `IuxButton` : aucun paramètre
ne permet de dessiner le refus en lien gris, parce que **c'est cette
asymétrie, pas la formulation, qui est la manipulation.**

## Deux honnêtetés qui méritent d'être notées

Il a vérifié la frontière plateforme **en parsant ses propres fichiers**, pas
en les relisant : tout import doit être `package:flutter/…` ou relatif, et le
code hors commentaires ne doit contenir aucun `MethodChannel`, `Platform.`,
`dart:io`, ni aucun nom de l'API de permissions.

Et il a tagué *(à vérifier)* les sources qu'il citait de mémoire au lieu de
les faire passer pour lues.

Il dit aussi que **SC 3.3.1 ne s'applique pas** — rien de ce que
l'utilisateur a saisi n'a été rejeté — plutôt que de le revendiquer.

45 tests.
