---
mission_id: IUX-036
title: Onboarding Foundations
priority: high
status: completed
started_at: 2026-08-03
started_by: agent/IUX-036 (resumed after an interrupted first attempt)
last_updated_at: 2026-08-04
completion_status: accepted
validation_status: passed
target_version: 0.2.0-dev
compatibility: additive
depends_on:
  - IUX-035
platform_priority: Android
package_name: iux_flutter
---

# IUX-036 — Onboarding Foundations

## 1. Références obligatoires
Lire intégralement PROJECT_PROMPT.md, COMPONENT_STANDARD.md, les missions dépendantes, ADR et architecture ; vérifier leurs statuts avant toute modification.

## 2. Contexte
Cette mission apporte fondations d’onboarding optionnelles et interrompables pour la première version exploitable.

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
Concevoir une API concise autour de IuxOnboardingStep, sans couleurs, ombres, rayons ni paramètres de mouvement arbitraires.

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

## L'onboarding est-il le formulaire par étapes avec du contenu ?

**Oui, et c'est mesuré au lieu d'être affirmé.** Commentaires retirés,
`_IuxOnboardingHeading` fait 51 lignes de code contre 58 pour
`_IuxStepHeading`, et **40 des 51 sont identiques au bit près**. Même typedef
importé, pas recopié.

Toute la différence tient en un champ : la `description` optionnelle du
formulaire, en style secondaire, contre un `body` requis en style principal —
parce qu'en onboarding la prose *est* la substance de l'écran, pas une note
au-dessus de questions.

La composition a pourtant été refusée, et défendablement : `IuxGuidedForm`
exige des `IuxFormSection`, des libellés de résumé de validation et un
`IuxFormSubmit`. Composer inventerait donc **un résumé qui ne résume rien** —
et chaque utilisateur de lecteur d'écran s'entendrait annoncer un résumé
d'erreurs qui ne peut jamais avoir d'entrée.

La dette est consignée avec sa mesure et son point de départ.

## La sortie est requise partout, y compris à la dernière étape

Emprunté à IUX-031 et à son raisonnement : un onboarding dont on ne peut pas
sortir est un mur, et rendre la sortie obligatoire est une structure, pas un
conseil.

## Pas de rangée de points, et c'est sondé avant d'être refusé

Quatre `Container` décorés produisent un nœud à **libellé vide et zéro
enfant** : une rangée de points n'annonce rien du tout. Un signal de position
qui n'existe que visuellement échoue SC 1.4.1, et §19 interdit une API
publique dont le seul effet est un rôle invérifiable.

## L'audit du code survivant

Quatre choses attendaient, toutes invisibles à `flutter analyze` : deux liens
de doc pointant vers des symboles non importés (dartdoc aurait émis des liens
morts), une affirmation périmée à propos d'un fichier qu'il ne possédait pas,
**trois revendications documentées sans aucun test derrière** — dont un test
tautologique qui cherchait un nœud par son libellé exact puis vérifiait que le
libellé valait ce libellé — et une page de doc référencée depuis le code mais
inexistante.

## Six mutants, six morts

Focus supprimé → 2 tests. `skip` masqué à la dernière étape → 5.
`content` déplacé après les contrôles → le nouveau test d'ordre, seul.
`MergeSemantics` par-dessus → les deux nouveaux tests de contenu.
Défilement injecté → le test de défilement, seul. `Future.delayed` →
l'épingle plus 6 tests comportementaux.

42 tests.
