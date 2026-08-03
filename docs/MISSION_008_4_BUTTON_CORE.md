---
mission_id: IUX-008.4
epic: IUX-008
title: Button Core
priority: critical
status: ready
started_at:
started_by:
last_updated_at: 2026-08-01
completion_status: pending
validation_status: not_started
target_version: 0.2.0-dev.4
compatibility: additive
depends_on:
  - IUX-008.1
  - IUX-008.2
  - IUX-008.3
platform_priority: Android
package_name: iux_flutter
---

# IUX-008.4 — Button Core

## 1. Références obligatoires
Lire PROJECT_PROMPT.md, COMPONENT_STANDARD.md, IUX-001 à IUX-008.3, les ADR et l’architecture. Vérifier toutes les dépendances. Respecter intégralement COMPONENT_STANDARD.md.

## 2. Contexte
IUX-008.2 décrit l’action et IUX-008.3 le thème sans rendu. Cette mission crée une primitive de bouton textuel qui les consomme.

## 3. Objectif utilisateur
Permettre d’identifier et d’activer une action textuelle avec TalkBack, clavier, texte agrandi, RTL, contraste renforcé et mouvement réduit.

## 4. Objectifs de la mission
Créer IuxButton, le relier au descriptor, runtime et thème, séparer disponibilité, interaction et opération, et empêcher les activations interdites.

## 5. Hors périmètre
Pas de bouton icône, variante spécialisée, FAB, menu, confirmation, dialogue, asynchrone interne, animation métier ni renderer générique.

## 6. Audit préalable obligatoire
Inspecter Action Model, Button Theme, runtime, focus, feedback, touch targets, layout, exports, catalogue et ADR. Documenter tout écart avant modification.

## 7. Principes directeurs
Un bouton représente une action, pas une couleur. Le parent possède état et logique métier. Préférer composition et résolveurs spécifiques.

## 8. Architecture ou structure cible
Créer ou adapter lib/src/components/button/ avec iux_button.dart, button_semantics.dart, button_interaction_controller.dart et resolved_button_state.dart, tests associés et docs/components/button.md.

## 9. API attendue
Évaluer IuxButton(label: 'Save', action: saveAction, onActivate: save). Label et action sont requis; aucun paramètre de couleur, forme, ombre, rayon ou durée.

## 10. Comportements attendus
Une action activable est appelée une fois par geste accepté; une action désactivée ne produit ni callback ni feedback. L’opération vient du parent; focus, pression et survol restent internes.

## 11. Accessibilité
Garantir rôle, label, état enabled/disabled, cible tactile, ordre de focus et focus visible. Tester manuellement TalkBack, Voice Access et D-pad; le contenu localisé reste responsabilité applicative.

## 12. Thèmes et tokens
Résoudre uniquement avec IuxButtonThemeData, tokens sémantiques et profil actif. Tester clair, sombre, contraste renforcé et densité. Interdire Colors.* et métriques arbitraires.

## 13. Mouvement et feedback
Utiliser les moteurs IUX. Le mouvement réduit retire les transitions non essentielles. Aucun succès, erreur, annonce ou haptique métier n’est déclenché automatiquement.

## 14. Documentation
Documenter intention, usage/non-usage, API, états, accessibilité, thèmes, exemples, anti-patterns et limites.

## 15. ADR
Créer une ADR seulement si une nouvelle décision durable sur la frontière descriptor/widget est nécessaire.

## 16. Evidence Registry
Relier cible tactile, focus, disponibilité sémantique et double activation à l’Evidence Registry; marquer toute source non vérifiée to_verify.

## 17. Tests unitaires
Tester résolution des états, combinaisons invalides et politique de répétition.

## 18. Widget tests
Tester label, activation, désactivation, opération contrôlée, pression, focus clavier et double activation.

## 19. Tests d’accessibilité
Tester Semantics, cible, focus, texte long/agrandi, RTL, petit écran, paysage, contraste et mouvement réduit; documenter les contrôles manuels.

## 20. Tests de contrat
Vérifier absence de paramètres graphiques, usage des abstractions IUX, état métier externe et compatibilité ascendante.

## 21. Catalogue
Ajouter scénarios d’intention, disponibilité, focus, opération, texte long/agrandi, RTL, petit écran, thèmes, mouvement réduit, bonnes pratiques et anti-patterns.

## 22. Dépendances
Aucune dépendance de production sans besoin démontré; ne pas ajouter animation, gestion d’état, design system ou renderer.

## 23. Performance
Privilégier const, résolution stable et contrôleurs locaux; éviter calcul coûteux dans build et rebuild inutile.

## 24. Compatibilité
Mission additive. Toute modification des contrats IUX-008.2 ou IUX-008.3 doit rester rétrocompatible.

## 25. Commandes de validation
Exécuter et rapporter le résultat réel de dart format ., flutter analyze, flutter test et flutter build apk --debug.

## 26. Livrables obligatoires
Composant, exports documentés, tests, catalogue, documentation, Evidence Registry, ADR éventuelle, résultats et limites.

## 27. Critères d’acceptation
Le bouton respecte le Component Standard, utilise Action Model et Button Theme, ne porte pas de logique métier, supporte accessibilité, thèmes, texte agrandi, RTL et mouvement réduit, et n’ajoute ni variante ni asynchrone.

## 28. Rapport final attendu
Présenter résumé, audit, API, résolution, états, accessibilité, thèmes, tests et commandes réelles, fichiers, Evidence/ADR, limites et prochaine mission.

## 29. Instruction finale
Commencer par l’audit. Implémenter uniquement le bouton textuel de base; ne pas commencer IUX-008.5.

