---
mission_id: IUX-034
title: Search Experience
priority: high
status: completed
started_at: 2026-08-03
started_by: IUX-034 implementation agent
last_updated_at: 2026-08-03
completion_status: accepted
validation_status: passed
target_version: 0.2.0-dev
compatibility: additive
depends_on:
  - IUX-033
platform_priority: Android
package_name: iux_flutter
---

# IUX-034 — Search Experience

## 1. Références obligatoires
Lire intégralement PROJECT_PROMPT.md, COMPONENT_STANDARD.md, les missions dépendantes, ADR et architecture ; vérifier leurs statuts avant toute modification.

## 2. Contexte
Cette mission apporte expérience de recherche avec saisie, états et résultats accessibles pour la première version exploitable.

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
Concevoir une API concise autour de IuxSearchExperience, sans couleurs, ombres, rayons ni paramètres de mouvement arbitraires.

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

## Une recherche *est* un chargement

`IuxSearchResults.results` est un `IuxLoadState<List<T>>`, et le widget
**compose** `IuxLoadingRetry` au lieu d'aiguiller une seconde fois. Il n'y a
pas d'`IuxSearchState`.

`List<T>` plutôt que `T` est délibéré : cela permet au widget de voir le vide
et donc de nommer lui-même la situation en `IuxNoMatches`, ce qui rend `reset`
structurellement requis. Une impasse « aucun résultat » devient
inconstructible au lieu d'être relue.

## Exactement une annonce par recherche stabilisée

Résultats non vides → une ligne d'état **visible** qui est aussi la région
vivante. Résultats vides → la région vivante de l'état vide, et **pas** de
ligne d'état, car les deux ensemble diraient deux fois la même phrase.

Le résumé est une **fonction du résultat**, pas une chaîne posée à côté : il ne
peut donc pas devenir périmé. Et il est visible autant que prononcé, donc rien
d'essentiel ne repose sur une région vivante que la plateforme peut refuser de
lire.

Mesuré : une requête de cinq caractères sans anti-rebond produit **dix**
régions vivantes. Avec une pause : deux.

## L'anti-rebond refusé, et l'argument qui vaut d'être gardé

Aucune minuterie, comme IUX-030. Mais surtout : **un anti-rebond réglé pour un
frappeur rapide se déclenche après chaque caractère pour un frappeur lent** —
et les frappeurs lents sont, de façon disproportionnée, la population des
lecteurs d'écran et des contacteurs. Régler sur le bas de la fourchette, et
préférer « l'utilisateur s'est arrêté » à un intervalle fixe.

## Pas de suggestions, et c'est mesuré

`SemanticsRole.comboBox` **lève une exception** en Flutter 3.44.8 :
`Missing checks for role SemanticsRole.comboBox`, le framework l'envoyant vers
`_unimplemented`. Inutilisable et pas seulement silencieux. Une liste de
suggestions ne pourrait donc partir qu'avec aucun rôle — §19 l'interdit. Un
test l'épingle, pour que le jour où Flutter l'implémente soit visible.

## Un écart assumé à la lettre de la mission

Deux widgets, pas un `IuxSearchExperience` unique. Sur Android le champ vit
très souvent dans la barre d'application et les résultats dans le corps ; un
widget unique les forcerait adjacents et serait inutilisable pour la
disposition la plus courante. Écart annoncé en tête de la page de doc.

41 tests.
