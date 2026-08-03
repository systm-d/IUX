---
mission_id: IUX-018
title: Tooltip and Contextual Help
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
  - IUX-017
platform_priority: Android
package_name: iux_flutter
---

# IUX-018 — Tooltip and Contextual Help

## 1. Références obligatoires
Lire intégralement PROJECT_PROMPT.md, COMPONENT_STANDARD.md, les missions dépendantes, les ADR et l’architecture. Vérifier leurs statuts avant modification.

## 2. Contexte
Cette mission poursuit la première version exploitable en apportant aide contextuelle non indispensable à l’action principale.

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
Concevoir une API publique concise autour de IuxTooltip, IuxContextualHelp. Elle ne doit exposer ni couleurs, ni ombres, ni rayons, ni valeurs de mouvement arbitraires.

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

## Un tooltip n'est jamais le seul porteur d'un sens

Atteignable par appui long (tactile), focus (clavier/D-pad) et survol
(pointeur). L'appui long partage l'arène de gestes avec le tap du contrôle et
ne gagne qu'après le délai de pression : un tap rapide active donc toujours le
contrôle et n'ouvre jamais de tooltip.

Pour un lecteur d'écran, le message atteint **le même nœud sémantique que le
nom du contrôle**. Non fusionné, Flutter place `tooltip` sur un wrapper au-dessus
du contrôle et l'action d'appui long sur un autre encore au-dessus, alors que
le lecteur atterrit sur le contrôle — vérifié contre l'arbre sémantique réel,
puis corrigé avec `MergeSemantics`.

SC 1.4.13 en trois points :
- **Dismissable** — `Escape`, une pression à l'extérieur via `TapRegion` (qui
  *signale* au lieu de consommer, la pression atteint donc quand même sa
  cible), une pression sur le contrôle, une pression sur le tooltip.
- **Hoverable** — un pont transparent enjambe l'espace jusqu'à l'ancre, donc
  pas de zone morte ; et la décision de fermeture est différée à une
  microtâche, parce qu'un déplacement ancre→tooltip émet sortie-puis-entrée
  dans la même passe et agir sur la sortie fermerait le tooltip sur le chemin
  de sa lecture.
- **Persistent** — il n'y a **aucune horloge**. Pas de `showDuration`, pas de
  masquage automatique, pas de paramètre qui pourrait en ajouter un. Testé en
  pompant cinq minutes.

## La frontière est appliquée, pas conseillée

`IuxTooltip` refuse un message de plus de 80 runes ou contenant un saut de
ligne. 80 ≈ deux lignes au texte par défaut, quatre à cinq à 200 % sur 320 px —
la limite de ce qui peut flotter. Une boîte flottante ne défile pas, ne se
laisse pas garder ouverte, et couvre la page qu'elle explique.

La règle à trois branches contre `IuxInputDescriptor.helpText` est clé sur
*ce qui arrive à l'utilisateur qui ne la voit jamais* : toujours visible = il
lui faut ça pour répondre ; divulgué = il peut en avoir besoin et peut le
demander ; tooltip = il le sait déjà, seul le glyphe est ambigu.

## Ce que cette mission a corrigé dans le runtime

L'agent a signalé — sans y toucher, ce n'était pas son périmètre — que
`IuxSemantics` n'avait nulle part où mettre `expanded` ni la propriété
`tooltip` de la plateforme, et que les deux doivent atterrir sur le *même*
`SemanticsConfiguration` que le nom et le rôle. Il a donc composé des
`Semantics` nus à deux endroits, chacun avec un commentaire nommant la règle du
standard §2 qu'il quittait et la priorité PROJECT_PROMPT §5 qui la surclasse.

J'ai fermé les deux : `IuxSemantics.action` gagne `expanded` (nul par défaut,
pour qu'un bouton ordinaire ne soit jamais annoncé « replié »), et
`IuxSemantics.elaboration` porte la propriété tooltip. Les 55 tests de la
mission — y compris les sondes sur l'arbre sémantique réel — passent inchangés
après le remplacement, ce qui est la preuve que la composition est équivalente.

## Tests

55 nouveaux tests. Suite complète : 1181, tous verts.
