---
mission_id: IUX-035
title: Progressive Disclosure
priority: high
status: completed
started_at: 2026-08-03
started_by: IUX-035 implementation agent
last_updated_at: 2026-08-03
completion_status: accepted
validation_status: passed
target_version: 0.2.0-dev
compatibility: additive
depends_on:
  - IUX-034
platform_priority: Android
package_name: iux_flutter
---

# IUX-035 — Progressive Disclosure

## 1. Références obligatoires
Lire intégralement PROJECT_PROMPT.md, COMPONENT_STANDARD.md, les missions dépendantes, ADR et architecture ; vérifier leurs statuts avant toute modification.

## 2. Contexte
Cette mission apporte révélation progressive d’informations sans cacher une conséquence importante pour la première version exploitable.

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
Concevoir une API concise autour de IuxProgressiveDisclosure, sans couleurs, ombres, rayons ni paramètres de mouvement arbitraires.

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

## La question IUX-018, et la réponse honnête

*Faut-il généraliser le contrôle de divulgation d'IUX-018 plutôt qu'en livrer
un second ?* **Oui pour le contrôle, non pour le composant.**

`IuxContextualHelp` doit continuer d'exister : sa contrainte *est* sa valeur.
Son `help` est une `String` et ne peut contenir aucun contrôle — c'est ce qui
empêche un panneau d'aide de devenir une destination avec un ordre de focus et
un chemin de retour. Le supprimer au profit de la forme générale supprimerait
ce refus.

**Mais le contrôle lui-même existe deux fois.** Consigné ouvert
(IUX-DISCLOSURE-004). L'agent n'a délibérément **pas** pré-ajouté le paramètre
de glyphe qui permettrait la fusion : un paramètre sans appelant est une API
publique morte.

## Une règle tenue par un type, trois par la prose — et la doc le dit

Quatre règles sur ce qui ne doit jamais être divulgué. **Une seule est tenue
par un type.** Aucun widget ne peut lire un sous-arbre et décider s'il
contient un champ requis, et une garantie qui est une supposition vaut moins
que pas de garantie du tout. La documentation dit donc laquelle est laquelle,
au lieu de laisser croire qu'il y en a quatre.

Ce qui est tenu : `IuxDisclosureState` est scellé en `collapsed` / `expanded`
/ `heldOpen`, donc « replié alors que le contenu doit être traité » n'est pas
constructible. Deux booléens auraient quatre combinaisons, et l'une d'elles
est le défaut.

## Pas d'animation, et l'absence est *prouvée*

Le fichier n'importe la politique de mouvement nulle part, et aucun paramètre
ne pourrait en ajouter une. Vérifié en exigeant le contenu complet après un
seul `pump()` avec `transientCallbackCount == 0`.

Deux arguments s'ajoutent à ceux d'IUX-018 : l'enfant peut contenir des
**contrôles**, donc animer, c'est faire voyager une zone de frappe pendant que
l'utilisateur tend la main vers elle ; et une révélation interrompue par une
seconde pression laisse l'arbre sémantique en plein vol.

## Deux défauts trouvés dans ses propres sondes

`FocusNode.context` continue de pointer vers un élément **défunt** après
démontage, et répond donc silencieusement à une autre question que « est-ce
dans l'ordre de focus » — le test interroge désormais le `FocusManager`. Et
quand la bascule détient le focus au moment du passage en `heldOpen`, Flutter
le rend à la portée englobante — le même comportement qu'IUX-030 avait mesuré
pour un réessai démonté. Épinglé et documenté comme un coût réel, pas maquillé.

38 tests.
