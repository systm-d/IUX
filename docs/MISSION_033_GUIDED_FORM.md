---
mission_id: IUX-033
title: Guided Form
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
  - IUX-032
platform_priority: Android
package_name: iux_flutter
---

# IUX-033 — Guided Form

## 1. Références obligatoires
Lire intégralement PROJECT_PROMPT.md, COMPONENT_STANDARD.md, les missions dépendantes, ADR et architecture ; vérifier leurs statuts avant toute modification.

## 2. Contexte
Cette mission apporte formulaire guidé combinant champs, sélection et résumé de validation pour la première version exploitable.

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
Concevoir une API concise autour de IuxGuidedForm, sans couleurs, ombres, rayons ni paramètres de mouvement arbitraires.

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

## L'audit, et pourquoi la mission n'était pas déjà satisfaite

IUX-012 le dit lui-même, dans son propre rapport : « `IuxForm`, pas
`IuxGuidedForm` — la mission 033 possède ce nom pour la variante par étapes. »
Sa page de doc renvoie explicitement « un flux multi-étapes avec progression
et retour » vers IUX-033.

Manquaient réellement : les étapes, une position perceptible, le focus et
l'annonce au changement d'étape, un résumé qui traverse les étapes, et une
entrée de résumé capable de voyager vers un champ **non monté**.

Déjà satisfait, donc non reconstruit : le calendrier de validation, le gating
par `edited`, le widget de résumé et sa règle de focus, l'assertion sur l'envoi
désactivé, l'espacement entre champs.

## La progression n'est jamais bloquée, et aucune étape n'est verrouillable

C'est la règle de l'envoi désactivé d'IUX-012, un niveau plus haut : une
**étape** qui refuse est pire qu'un bouton qui refuse, parce que la question
fautive n'est pas à l'écran. La garantie se déplace vers l'envoi, là où le
résumé rend chaque problème atteignable.

Le `summary` est donc **requis** ici alors qu'`IuxForm` l'autorise nul : le
repli d'`IuxForm` — focaliser le premier champ rejeté — est impossible quand
ce champ n'est pas monté. Sans résumé, un refus serait invisible **et**
inatteignable.

## Le focus bouge, et l'exception confirme la règle

Réconcilié avec les quatre décisions antérieures par un seul test : *est-ce
que l'utilisateur l'a demandé ?* 028, 029 et 030 ne bougent pas le focus parce
que l'événement est arrivé **à** l'utilisateur ; 012 le bouge parce qu'il vient
d'appuyer sur envoyer et attend. Un changement d'étape a la forme de 012.

L'exception : arriver depuis une entrée de résumé atterrit sur le **champ**,
pas sur l'en-tête. L'utilisateur a demandé une case, pas un exposé sur une
étape.

Pas de barre de progression : `IuxProgressIndicator` est une région vivante, et
en dessiner une mettrait une seconde énonciation dans la même frame que le
déplacement du focus — exactement l'échec qu'`IuxValidationSummary` évite en
n'étant *pas* une région vivante.

## Un défaut dans son propre code, trouvé en sondant

Un voyage vers un champ d'une autre étape restait **armé** quand le parent
déclinait en ne se reconstruisant pas du tout — `didUpdateWidget` ne s'exécute
alors jamais. Il détournait ensuite le changement d'étape suivant :
l'utilisateur appuyait sur Retour et se retrouvait déposé dans un champ.

Et il avait écrit qu'un `FocusNode` détaché notifie ses auditeurs. Après
mesure, il ne le fait pas. Le commentaire est corrigé et le test requalifié en
épingle.

54 tests.
