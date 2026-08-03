# MISSION_PROMPT_TEMPLATE.md

# IUX — Mission Prompt Template

Version : 1.0

---
mission_id: IUX-XXX
title: Titre de la mission
priority: medium
status: ready
started_at:
started_by:
last_updated_at:
completion_status: pending
validation_status: not_started
---

---

# Objectif

Ce document décrit une mission ponctuelle à réaliser sur le projet **IUX (Intuitive UX)**.

Il complète le document `PROJECT_PROMPT.md`.

Le `PROJECT_PROMPT.md` définit les règles permanentes du projet.

Le présent document décrit uniquement le travail demandé.

En cas de conflit :

1. `PROJECT_PROMPT.md` prévaut toujours.
2. Le Mission Prompt précise uniquement la mission en cours.

---

# Avant de commencer

Avant toute implémentation :

* lire intégralement `PROJECT_PROMPT.md` ;
* lire intégralement ce document ;
* comprendre les objectifs de la mission ;
* identifier les impacts sur l'architecture ;
* identifier les impacts UX ;
* identifier les impacts d'accessibilité.

Ne jamais commencer à coder immédiatement.

---

# Contexte

Décrire ici :

* le problème utilisateur ;
* le contexte fonctionnel ;
* les composants concernés ;
* les limitations actuelles ;
* les motivations de cette évolution.

Exemple :

> Les boutons actuels ne distinguent pas clairement une action principale d'une action destructive. Cette mission consiste à introduire une sémantique d'action plus explicite tout en améliorant l'accessibilité.

---

# Objectifs

Décrire précisément ce qui doit être obtenu.

Les objectifs doivent être mesurables.

Exemple :

* créer une API d'action sémantique ;
* conserver la compatibilité avec les composants existants ;
* améliorer la lisibilité ;
* réduire les erreurs utilisateur ;
* améliorer l'expérience TalkBack.

---

# Hors périmètre

Lister explicitement ce qui ne doit pas être fait.

Exemple :

* ne pas refondre toute la bibliothèque ;
* ne pas modifier les composants non concernés ;
* ne pas changer l'architecture globale ;
* ne pas introduire de nouvelles dépendances importantes.

Définir le hors périmètre évite les refactorings inutiles.

---

# Contraintes

Lister les contraintes spécifiques de la mission.

Exemples :

* compatibilité API ;
* performances ;
* Android uniquement ;
* Flutter stable uniquement ;
* aucune dépendance supplémentaire ;
* migration progressive ;
* documentation obligatoire.

---

# Principes à respecter

Pendant toute la mission, respecter les principes définis dans `PROJECT_PROMPT.md`.

En particulier :

* Human First
* Accessibility First
* Simplicity
* Evidence Informed
* Consistency

Ne jamais les sacrifier pour gagner du temps.

---

# Méthode de travail

Respecter impérativement l'ordre suivant.

1. Comprendre.
2. Auditer.
3. Concevoir.
4. Valider l'architecture.
5. Implémenter.
6. Documenter.
7. Tester.
8. Vérifier.
9. Résumer.

Le code n'est jamais la première étape.

---

# Étape 1 — Audit

Avant toute modification, réaliser un audit.

Identifier :

* les fichiers concernés ;
* les composants concernés ;
* les dépendances ;
* les responsabilités ;
* les duplications éventuelles ;
* les risques.

L'audit doit expliquer :

ce qui existe ;

pourquoi cela fonctionne ;

pourquoi cela doit évoluer.

---

# Étape 2 — Analyse UX

Pour chaque décision importante répondre aux questions suivantes.

Quel problème utilisateur résout-on ?

Quelle frustration actuelle est supprimée ?

Quelle erreur est évitée ?

Quel bénéfice utilisateur est attendu ?

Quels utilisateurs sont concernés ?

Quels profils d'accessibilité sont concernés ?

---

# Étape 3 — Recherche

Avant d'implémenter une règle importante :

Identifier les recommandations applicables.

Exemples :

* Android
* Material
* WCAG
* littérature HCI
* documentation Flutter

Si une décision est une hypothèse, l'indiquer explicitement.

---

# Étape 4 — Analyse de l'API

Avant d'ajouter une API :

Vérifier :

Existe-t-elle déjà ?

Peut-elle être simplifiée ?

Ajoute-t-elle réellement de la valeur ?

Est-elle cohérente avec les autres composants ?

Peut-elle être mal utilisée ?

Les paramètres sont-ils suffisamment explicites ?

---

# Étape 5 — Proposition d'architecture

Avant de coder :

Présenter :

* les nouvelles classes ;
* les nouvelles responsabilités ;
* les modifications d'API ;
* les dépendances ;
* les risques.

Ne jamais commencer une implémentation importante sans cette étape.

---

# Étape 6 — Plan d'implémentation

Découper la mission en petits lots.

Chaque lot doit être indépendant.

Chaque lot doit être testable.

Chaque lot doit produire une amélioration visible.

Exemple :

Lot 1

Semantic Tokens

Lot 2

Theme

Lot 3

Button

Lot 4

Tests

Lot 5

Documentation

Lot 6

Catalog

---

# Règles d'implémentation

Le code doit respecter :

* la null safety ;
* la composition ;
* les widgets immuables ;
* les constructeurs const ;
* les responsabilités uniques ;
* les conventions du projet.

Éviter :

* les booléens multiples ;
* les paramètres ambigus ;
* les classes géantes ;
* la duplication.

---

# API publique

Toute API publique doit être :

simple ;

prévisible ;

documentée ;

cohérente.

Préférer :

```dart
IuxActionIntent.primary
```

à :

```dart
color: Colors.blue
```

Préférer :

```dart
IuxButtonVariant.primary
```

à :

```dart
isBlue: true
```

Ne jamais faire dépendre une API d'un détail graphique.

---

# Compatibilité

Avant de modifier une API publique :

Évaluer :

* les impacts ;
* les migrations ;
* les alternatives.

Si une dépréciation est nécessaire :

Ajouter :

* @Deprecated ;
* un message ;
* une documentation ;
* une migration.

Les ruptures doivent rester exceptionnelles.
# Implémentation

L'implémentation ne commence qu'après validation des étapes précédentes.

Chaque modification doit être :

* justifiée ;
* documentée ;
* testée ;
* cohérente avec l'architecture du projet.

Ne jamais modifier plusieurs sous-systèmes sans raison.

Préférer plusieurs petits changements à une refonte massive.

---

# Accessibilité

Chaque composant créé ou modifié doit être évalué selon les critères suivants.

## Sémantique

Le composant possède-t-il :

* un rôle clair ;
* un label compréhensible ;
* une description lorsque nécessaire ;
* un ordre de lecture logique ?

---

## Interaction

Le composant est-il utilisable :

* au clavier ;
* avec TalkBack ;
* avec Voice Access lorsque pertinent ?

---

## Zones tactiles

Les zones interactives respectent-elles les recommandations Android ?

Les composants proches restent-ils faciles à utiliser ?

---

## Taille du texte

Le composant reste-t-il lisible lorsque la taille du texte augmente ?

Le contenu reste-t-il accessible ?

Y a-t-il des débordements ?

---

## Contraste

Le composant reste-t-il compréhensible :

* en thème clair ;
* en thème sombre ;
* en contraste renforcé ?

---

## Mouvement

Le composant reste-t-il utilisable lorsque :

les animations sont réduites ;

les transitions sont désactivées.

---

## Couleurs

Le composant dépend-il uniquement de la couleur ?

Si oui, modifier la conception.

Toujours fournir un autre indicateur :

* icône ;
* texte ;
* contour ;
* état ;
* forme.

---

# UX Checklist

Avant de considérer une implémentation terminée, vérifier.

Le composant :

réduit-il la charge cognitive ?

évite-t-il une erreur fréquente ?

améliore-t-il la compréhension ?

reste-t-il simple ?

respecte-t-il les conventions Android ?

reste-t-il cohérent avec les autres composants ?

---

# Documentation

Toute nouvelle API publique doit être documentée.

Chaque composant doit expliquer :

Purpose

Use When

Avoid When

Accessibility

Behavior

Parameters

States

Examples

Evidence

Known Limitations

Migration

Ne jamais se contenter d'un commentaire Dart minimal.

---

# Widget Catalog

Tout nouveau composant doit être ajouté au catalogue.

Le catalogue doit montrer au minimum.

Default

Disabled

Focused

Loading

Success

Error

Long Label

Large Text

Small Screen

Dark Theme

Light Theme

High Contrast

Reduced Motion

Lorsque ces états existent.

---

# Exemples

Chaque composant doit fournir.

Un exemple minimal.

Un exemple réaliste.

Un exemple avancé.

L'objectif est qu'un développeur puisse copier l'exemple directement.

---

# Tests

Toute nouvelle fonctionnalité doit être accompagnée de tests.

Minimum attendu.

## Unit Tests

Validation des :

tokens

utilitaires

extensions

thèmes

---

## Widget Tests

Validation :

des états

des callbacks

des interactions

des comportements

---

## Accessibility Tests

Validation :

Semantics

Focus

Labels

Text Scaling

Touch Target

Navigation

---

## Integration Tests

Lorsque plusieurs composants collaborent.

---

# Cas limites

Toujours vérifier les situations suivantes.

Texte vide.

Texte très long.

Texte multiligne.

Écran étroit.

Écran large.

Orientation paysage.

Mode sombre.

Mode clair.

Contraste renforcé.

Animations réduites.

Langues plus longues.

Absence de réseau lorsque pertinent.

Chargement lent.

Erreur.

Succès.

Annulation.

Double clic.

Double tap.

Actions répétées.

---

# Performance

Avant de terminer la mission vérifier.

Les rebuilds inutiles.

Les allocations inutiles.

Les animations coûteuses.

Les calculs répétés.

Les objets pouvant être const.

Les effets inutiles.

Optimiser uniquement lorsque cela apporte un bénéfice réel.

---

# Compatibilité

Avant toute modification.

Lister :

API modifiées.

API dépréciées.

API supprimées.

Comportements modifiés.

Impacts possibles.

Toujours proposer une stratégie de migration.

---

# Fichiers modifiés

Pour chaque mission fournir une liste explicite.

Créés.

Modifiés.

Supprimés.

Renommés.

Déplacés.

Ne jamais laisser ces informations implicites.

---

# Rapport d'implémentation

À la fin de chaque mission produire un rapport.

Structure attendue.

## Résumé

Quelques lignes expliquant le résultat.

---

## Objectifs atteints

Lister chaque objectif réalisé.

---

## Décisions importantes

Expliquer les décisions d'architecture.

---

## Compromis

Expliquer les compromis réalisés.

---

## Risques

Lister les risques restants.

---

## Limitations

Lister les limitations connues.

---

## Travaux futurs

Lister les améliorations possibles.

---

# Vérifications finales

Avant de considérer la mission terminée.

Vérifier.

Le projet compile.

Les tests passent.

Le code est formaté.

Les warnings importants sont traités.

Les composants sont documentés.

Le catalogue est mis à jour.

Les exemples compilent.

La migration est documentée.

Les nouveaux comportements sont testés.

Les principes du PROJECT_PROMPT sont respectés.

---

# Critères d'acceptation

La mission est considérée comme réussie uniquement si.

Le besoin utilisateur est résolu.

Les principes du projet sont respectés.

L'accessibilité est prise en compte.

Les composants sont cohérents.

Les tests sont présents.

La documentation est présente.

Les exemples sont présents.

La compatibilité est préservée ou documentée.

Les performances restent acceptables.

Aucune régression majeure n'est introduite.

---

# Format attendu de la réponse

À la fin de chaque mission, répondre selon la structure suivante.

## 1. Analyse

Résumé du problème.

---

## 2. Audit

État actuel.

---

## 3. Proposition

Architecture proposée.

---

## 4. Plan

Découpage des travaux.

---

## 5. Implémentation

Description des modifications réalisées.

---

## 6. Tests

Tests ajoutés.

Tests exécutés.

Résultats.

---

## 7. Documentation

Documentation ajoutée.

---

## 8. Migration

Impacts API.

Étapes nécessaires.

---

## 9. Conclusion

Résumé des bénéfices.

Prochaines étapes recommandées.

---

# Règles de comportement de Codex

Pendant cette mission.

Ne jamais modifier du code sans comprendre son rôle.

Ne jamais supprimer une API publique sans justification.

Ne jamais introduire une dépendance importante sans analyse.

Ne jamais contourner les principes du `PROJECT_PROMPT.md`.

Toujours privilégier les petits changements cohérents.

Toujours expliquer les décisions importantes.

Toujours produire un code maintenable.

Toujours penser à l'utilisateur final avant de penser au développeur.

Toujours penser à l'accessibilité avant de penser à l'esthétique.

---

# Fin de mission

Une fois la mission terminée.

Attendre une nouvelle mission.

Ne pas commencer spontanément un autre chantier.

Chaque Mission Prompt est indépendant.

Ne jamais supposer les objectifs de la mission suivante.

Toujours repartir du `PROJECT_PROMPT.md` puis lire le nouveau `MISSION_PROMPT.md` avant toute nouvelle implémentation.
