# PROJECT_PROMPT.md

# IUX — Intuitive UX

Version : 1.0

---

# 1. Vision

Tu participes au développement de **IUX (Intuitive UX)**.

IUX est un framework Flutter open source destiné à créer des interfaces mobiles Android centrées sur l'humain.

IUX n'est pas une Design System.

IUX n'est pas une bibliothèque de widgets esthétiques.

IUX est une bibliothèque de composants, de fondations et de patterns UX permettant aux développeurs de créer des applications plus accessibles, plus compréhensibles et plus agréables à utiliser.

La bibliothèque doit permettre d'obtenir de bonnes interfaces par défaut.

L'objectif est que les développeurs aient besoin de prendre le moins de décisions UX possible.

Les composants doivent intégrer les bonnes pratiques directement dans leur conception.

---

# 2. Mission

La mission d'IUX est simple.

Permettre à n'importe quel développeur Flutter de construire une application :

* accessible ;
* cohérente ;
* lisible ;
* compréhensible ;
* robuste ;
* performante ;
* ergonomique.

Le framework doit rendre les bonnes pratiques simples.

Les mauvaises pratiques doivent devenir difficiles à implémenter.

---

# 3. Philosophie

Une belle interface n'est pas nécessairement une bonne interface.

Une bonne interface est une interface :

* comprise rapidement ;
* utilisable sans apprentissage important ;
* accessible au plus grand nombre ;
* cohérente ;
* prévisible ;
* rassurante ;
* tolérante aux erreurs.

IUX privilégie toujours l'expérience utilisateur avant l'apparence.

Une animation n'est utile que si elle améliore la compréhension.

Une couleur n'est utile que si elle améliore la perception.

Un composant n'est utile que s'il résout un problème utilisateur.

---

# 4. Valeurs

Le projet repose sur les valeurs suivantes.

## Human First

Toutes les décisions sont prises pour améliorer l'expérience des utilisateurs.

Jamais pour suivre une mode graphique.

---

## Accessibility First

L'accessibilité est une fonctionnalité.

Elle ne constitue jamais une amélioration optionnelle.

Elle fait partie de la définition de terminé.

---

## Evidence Informed

Les décisions doivent être guidées par :

* des standards ;
* des recommandations reconnues ;
* des recherches sérieuses ;
* des retours utilisateurs.

Une intuition n'est pas une preuve.

Une préférence esthétique n'est pas une règle UX.

---

## Simplicity

Une API simple vaut mieux qu'une API puissante mais difficile à comprendre.

Les composants doivent être faciles à utiliser correctement.

---

## Progressive Complexity

Les composants doivent être simples dans leur usage courant.

La complexité ne doit apparaître que lorsque le développeur en a réellement besoin.

---

## Consistency

Deux composants comparables doivent se comporter de manière comparable.

La cohérence est plus importante que l'originalité.

---

# 5. Priorités

Lorsqu'un choix doit être fait, respecter impérativement cet ordre.

1. Sécurité utilisateur
2. Prévention des erreurs
3. Accessibilité
4. Compréhension
5. Lisibilité
6. Simplicité
7. Cohérence
8. Contrôle utilisateur
9. Performance
10. Maintenabilité
11. Ergonomie développeur
12. Apparence

L'apparence est toujours le dernier critère.

---

# 6. Ce que IUX n'est pas

Ne jamais transformer IUX en bibliothèque graphique.

Ne jamais reproduire une identité visuelle.

Ne jamais créer un composant uniquement parce qu'il paraît moderne.

Ne jamais privilégier un effet décoratif à la compréhension.

Ne jamais ajouter une animation sans justification fonctionnelle.

Ne jamais utiliser :

* glow ;
* néons ;
* ombres complexes ;
* gradients ;
* animations spectaculaires ;

comme éléments nécessaires à la compréhension.

Ils peuvent exister uniquement comme personnalisation.

Jamais comme fondation.

---

# 7. Objectifs

IUX doit améliorer :

* la compréhension ;
* la découvrabilité ;
* la lisibilité ;
* la rapidité d'apprentissage ;
* la prévention des erreurs ;
* la navigation ;
* l'utilisation à une main ;
* l'accessibilité ;
* la cohérence ;
* la confiance utilisateur.

---

# 8. Sources de référence

Les recommandations utilisées par IUX doivent provenir en priorité de :

* Material Design
* Android Accessibility Guidelines
* WCAG
* Human Interface Guidelines lorsque pertinentes
* Human Computer Interaction
* Nielsen Norman Group
* Baymard Institute
* ISO 9241 lorsque pertinente
* littérature scientifique HCI
* psychologie cognitive
* ergonomie

Les choix doivent toujours préciser leur niveau de confiance.

---

# 9. Niveaux de preuve

Chaque décision importante doit être classée.

## Standard

Norme officielle.

Exemples :

* WCAG
* Android Accessibility
* recommandations officielles Flutter

---

## Strong Guidance

Recommandation largement reconnue.

Exemple :

* Nielsen Norman Group
* Baymard
* Material Design

---

## Context Dependent

Bonne pratique dépendante du contexte.

Toujours documenter les limites.

---

## Hypothesis

Choix nécessitant une validation utilisateur.

Ne jamais présenter une hypothèse comme un fait.

---

## Brand Choice

Préférence esthétique.

Ne jamais la présenter comme une amélioration UX.

---

# 10. Architecture générale

Le framework est organisé en couches.

Chaque couche possède une responsabilité unique.

```
Applications

↓

UX Patterns

↓

Components

↓

Semantic Tokens

↓

Foundations

↓

Flutter
```

Une couche supérieure ne doit jamais contourner une couche inférieure.

---

# 11. Foundations

Les foundations représentent les primitives.

Aucune connaissance métier.

Aucune identité graphique.

Uniquement des règles fondamentales.

Exemples :

* spacing
* typography
* sizing
* density
* interaction
* motion
* elevation
* shapes
* accessibility
* feedback
* timing
* focus
* borders

Les foundations sont indépendantes de toute marque.

---

# 12. Semantic Tokens

Les composants ne doivent jamais manipuler directement :

* Colors.blue
* Colors.red
* Colors.green

Ils manipulent des intentions.

Exemple :

```
actionPrimary

actionSecondary

actionDestructive

contentPrimary

contentSecondary

surface

border

focus

success

warning

error
```

Le thème associe ensuite ces intentions à des couleurs.

Jamais les composants.

---

# 13. Themes

Les thèmes représentent des conditions d'utilisation.

Pas une identité graphique.

Le framework fournit uniquement des thèmes génériques.

Minimum :

* Accessible Light
* Accessible Dark
* High Contrast

À terme, d'autres profils pourront être ajoutés :

* Cognitive Comfort
* Reduced Motion
* Comfortable Density

Les thèmes doivent respecter les contraintes d'accessibilité définies par le projet.

---

# 14. Components

Les composants sont les briques de base.

Ils doivent être :

* cohérents ;
* accessibles ;
* prévisibles ;
* simples.

Ils ne contiennent aucune logique métier.

Ils ne contiennent aucune identité graphique.

Ils utilisent uniquement :

* Foundations
* Semantic Tokens

---

# 15. UX Patterns

Les UX Patterns sont la véritable valeur ajoutée du framework.

Ils répondent à une intention utilisateur.

Exemples :

* ActionButton
* AsyncAction
* DestructiveAction
* ConfirmationAction
* DecisionCard
* GuidedTextField
* EmptyState
* ErrorRecovery
* LoadingState
* SuccessState
* PermissionRequest
* ProgressiveDisclosure

Le développeur choisit un Pattern.

Pas un simple widget.

---

# 16. Accessibilité

Tous les composants doivent fonctionner correctement avec :

* TalkBack
* tailles de texte importantes
* contraste renforcé
* navigation clavier
* lecteurs d'écran
* mouvements réduits
* petits écrans
* grands écrans
* orientations différentes
* langues longues

L'accessibilité n'est jamais facultative.

Un composant non accessible n'est pas terminé.

---

# 17. Charge cognitive

Chaque composant doit chercher à réduire :

* le nombre de décisions ;
* le nombre d'étapes ;
* le nombre d'informations simultanées ;
* les distractions ;
* les changements visuels inutiles ;
* les animations concurrentes.

Chaque ajout doit être justifié.

---

# 18. Prévention des erreurs

IUX privilégie toujours la prévention plutôt que la correction.

Les composants doivent :

* éviter les doubles actions ;
* rendre les conséquences visibles ;
* demander confirmation lorsque nécessaire ;
* permettre l'annulation lorsqu'elle est pertinente ;
* éviter les états ambigus ;
* fournir un feedback clair.

La suppression irréversible ne doit jamais être banalisée.

# 19. API Design Principles

L'API publique est l'un des actifs les plus importants du projet.

Elle doit rester stable, cohérente et simple.

Avant d'ajouter une nouvelle API, toujours se poser les questions suivantes :

* Résout-elle un problème utilisateur réel ?
* Peut-elle être comprise sans documentation ?
* Peut-elle être utilisée correctement du premier coup ?
* Peut-elle être simplifiée ?
* Existe-t-il déjà une API similaire ?

Toute nouvelle API doit être justifiée.

---

# 20. Simplicité avant puissance

IUX privilégie toujours une API simple.

Une API comportant vingt paramètres optionnels est probablement une mauvaise API.

Préférer :

```dart
IuxActionButton(
  intent: IuxActionIntent.primary,
)
```

plutôt que :

```dart
IuxButton(
    color: ...
    elevation: ...
    radius: ...
    shadow: ...
    animation: ...
    glow: ...
)
```

La personnalisation doit exister.

Mais elle ne doit jamais compliquer le cas d'usage principal.

---

# 21. Les composants représentent une intention

Le développeur ne choisit pas une couleur.

Il choisit une intention.

Exemple :

```dart
IuxActionIntent.primary
```

et non :

```dart
Colors.blue
```

Autre exemple :

```dart
IuxFeedback.success
```

et non :

```dart
Colors.green
```

Les composants doivent exprimer une signification.

Jamais une implémentation graphique.

---

# 22. Les composants doivent être difficiles à mal utiliser

L'objectif n'est pas seulement de proposer une API.

L'objectif est d'empêcher les erreurs.

Les composants doivent :

* limiter les paramètres inutiles ;
* fournir des valeurs par défaut pertinentes ;
* empêcher les états incohérents ;
* détecter les configurations invalides ;
* produire des messages d'erreur explicites.

---

# 23. Aucun composant ne doit dépendre d'une identité graphique

Le framework doit pouvoir être utilisé dans :

* une banque ;
* un hôpital ;
* une application éducative ;
* une administration ;
* une startup ;
* une application grand public.

L'architecture ne doit jamais supposer une couleur, une police ou un style particulier.

---

# 24. Architecture du dépôt

L'organisation du dépôt doit refléter les responsabilités.

Structure cible :

```text
iux/

packages/
    iux_flutter/
    iux_testing/
    iux_lints/

apps/
    catalog/

docs/

research/

examples/

tools/
```

---

# 25. Architecture du package Flutter

Le package principal doit rester organisé par responsabilité.

Exemple :

```text
lib/

src/

    foundations/

    semantics/

    themes/

    accessibility/

    motion/

    interactions/

    feedback/

    components/

    patterns/

    testing/

    utilities/
```

Chaque dossier possède une responsabilité unique.

---

# 26. Foundations

Les Foundations ne doivent contenir que des primitives.

Exemples :

Spacing

Typography

Shapes

Sizing

Elevation

Density

Motion

Focus

Interaction

Accessibility

Feedback

Timing

Aucune logique métier.

Aucune logique graphique.

---

# 27. Semantic Layer

La couche sémantique représente le langage du framework.

Les composants ne parlent jamais directement en couleurs.

Ils parlent en intentions.

Exemple :

```text
Primary Action

Secondary Action

Destructive Action

Selected

Focused

Hovered

Disabled

Surface

Container

Divider

Border

Accent

Success

Warning

Error
```

---

# 28. Components

Les composants sont volontairement limités.

Ils représentent uniquement des briques.

Exemple :

Button

Card

TextField

Dialog

Snackbar

Progress

BottomSheet

NavigationBar

NavigationRail

ListTile

Tooltip

Checkbox

Switch

Radio

Aucun composant ne doit intégrer de logique métier.

---

# 29. Patterns

Les Patterns représentent une solution UX complète.

Ils combinent plusieurs composants.

Exemple :

ConfirmationAction

DeleteConfirmation

GuidedForm

EmptyState

ErrorRecovery

LoadingScreen

DecisionCard

Wizard

PermissionFlow

OnboardingStep

ProgressIndicatorSection

SearchExperience

SettingsSection

---

# 30. Ne jamais créer un composant trop spécialisé

Mauvais :

```text
PremiumBlueDeleteButton
```

Bon :

```text
DestructiveAction
```

Le composant décrit une intention.

Pas un cas métier.

---

# 31. Accessibilité

L'accessibilité est intégrée dès la conception.

Jamais après.

Chaque composant doit être pensé pour :

TalkBack

Voice Access

Keyboard

Text Scaling

Display Scaling

Contrast

Reduced Motion

Screen Readers

Focus Navigation

Color Blindness

Motor Disabilities

Cognitive Disabilities

Lorsque Flutter ne permet pas une solution parfaite, documenter les limitations.

---

# 32. Mouvement

Les animations doivent améliorer la compréhension.

Jamais décorer.

Une animation doit répondre à une question.

Par exemple :

Que vient-il de se passer ?

Où est allé cet élément ?

Que dois-je regarder ?

Si l'animation n'apporte pas cette information, elle doit être supprimée.

---

# 33. Feedback

Le feedback utilisateur doit être proportionné.

Une action importante mérite un feedback important.

Une action mineure mérite un feedback discret.

Éviter :

* les vibrations systématiques ;
* les animations permanentes ;
* les notifications inutiles ;
* les confirmations redondantes.

---

# 34. Performance

Les performances font partie de l'expérience utilisateur.

Ne jamais :

* reconstruire inutilement ;
* créer des animations coûteuses ;
* multiplier les couches ;
* utiliser des effets visuels lourds.

Préférer :

const

composition

widgets simples

lazy loading lorsque pertinent

---

# 35. Documentation

Toute API publique doit être documentée.

La documentation doit répondre aux questions suivantes.

Pourquoi existe ce composant ?

Quand l'utiliser ?

Quand ne pas l'utiliser ?

Quels problèmes résout-il ?

Quels problèmes ne résout-il pas ?

Quelles sont les contraintes d'accessibilité ?

Quels sont les états possibles ?

Quels principes UX applique-t-il ?

Quelles sources justifient ces choix ?

---

# 36. Documentation des composants

Chaque composant doit disposer au minimum de :

Purpose

Use when

Avoid when

Accessibility

Behavior

States

Parameters

Examples

Migration

Evidence

Known limitations

---

# 37. Evidence Registry

Les décisions UX importantes doivent être documentées.

Chaque règle possède :

un identifiant

une description

le niveau de preuve

les sources

les limites

les composants concernés

la date de dernière validation

Aucune affirmation importante ne doit rester sans justification.

---

# 38. Règles de développement

Avant toute implémentation :

Comprendre le besoin utilisateur.

Identifier les risques UX.

Identifier les contraintes d'accessibilité.

Identifier les impacts API.

Proposer une solution.

Seulement ensuite coder.

---

# 39. Gestion des compromis

Les compromis doivent être expliqués.

Exemple :

Pourquoi cette animation existe ?

Pourquoi cette confirmation est obligatoire ?

Pourquoi cette API possède deux variantes ?

Les décisions importantes ne doivent jamais être implicites.

---

# 40. Refactoring

Le refactoring est encouragé lorsqu'il :

réduit la complexité ;

améliore la cohérence ;

réduit la duplication ;

améliore l'accessibilité.

Le refactoring ne doit jamais casser inutilement l'API publique.

Toute rupture doit être documentée.

---

# 41. Compatibilité

L'API publique est considérée comme un contrat.

Toute rupture doit être :

justifiée ;

documentée ;

annoncée ;

accompagnée d'une stratégie de migration.

---

# 42. Code Quality

Le code doit respecter les principes suivants.

Responsabilité unique.

Composition.

Immutabilité.

Null Safety.

Const lorsque possible.

Petites classes.

Petites méthodes.

Pas de duplication.

Pas de booléens ambigus.

Préférer des enums.

Préférer des objets de configuration.

Le code doit être lisible avant d'être intelligent.

# 43. Testing Philosophy

Les tests sont une partie intégrante du framework.

Un composant n'est pas terminé tant qu'il n'est pas testé.

Les tests doivent privilégier le comportement plutôt que le rendu graphique.

Le framework doit être robuste lors des évolutions.

Les régressions doivent être détectées rapidement.

---

# 44. Types de tests

Le framework doit comporter plusieurs niveaux de tests.

## Unit Tests

Validation des :

* tokens
* thèmes
* règles métier internes
* utilitaires
* extensions

---

## Widget Tests

Validation :

* des états
* des interactions
* des callbacks
* des comportements
* des transitions d'état

---

## Accessibility Tests

Validation :

* Semantics
* labels
* focus
* navigation clavier
* ordre de lecture
* zones tactiles
* texte agrandi
* contrastes lorsque cela est automatisable

---

## Integration Tests

Validation :

* composants combinés
* patterns
* navigation
* formulaires
* actions asynchrones

---

## Manual Validation

Certaines validations nécessitent un test manuel.

Exemple :

* TalkBack
* Voice Access
* mouvement réduit
* différentes tailles d'écran
* différents appareils Android

Ces validations doivent être documentées.

---

# 45. Définition de terminé

Une fonctionnalité est considérée comme terminée uniquement si :

* elle répond au besoin utilisateur ;
* elle respecte les principes du projet ;
* elle est documentée ;
* elle est testée ;
* elle est compatible avec l'architecture existante ;
* elle est cohérente avec les autres composants.

Une fonctionnalité codée mais non documentée n'est pas terminée.

Une fonctionnalité documentée mais non testée n'est pas terminée.

---

# 46. Widget Catalog

Le catalogue de composants est une partie essentielle du projet.

Chaque composant doit posséder une démonstration interactive.

Le catalogue doit montrer :

* les états ;
* les variantes ;
* les comportements ;
* les contraintes ;
* les règles d'utilisation.

Il ne sert pas uniquement à montrer l'apparence.

Il sert à expliquer le fonctionnement.

Chaque composant doit présenter :

* Default
* Disabled
* Focused
* Loading
* Success
* Error
* Long text
* Large text
* Small screen
* Dark theme
* Light theme
* High contrast

Lorsque cela est pertinent.

---

# 47. Documentation

La documentation doit permettre à un développeur de comprendre un composant sans lire son code.

Elle doit expliquer :

Pourquoi ?

Quand ?

Comment ?

Pourquoi pas ?

Quels compromis ?

Quels principes UX ?

Quelles limites ?

Quels exemples ?

---

# 48. Research

Le projet doit conserver les recherches ayant conduit aux décisions importantes.

Créer un dossier dédié.

Exemple :

```text
research/

accessibility/

ux/

hci/

psychology/

android/

material/

wcag/
```

L'objectif est que les décisions restent traçables.

---

# 49. Evidence Registry

Chaque décision UX importante doit être documentée.

Structure recommandée.

```text
ID

Titre

Description

Composants concernés

Niveau de preuve

Sources

Date

Auteur

Limites

Alternatives

Historique
```

Toutes les recommandations ne possèdent pas le même niveau de preuve.

Le projet doit toujours faire preuve d'humilité.

---

# 50. Versioning

Le projet suit le Semantic Versioning.

Toute modification de l'API publique doit être évaluée selon son impact.

Les dépréciations sont préférables aux ruptures immédiates.

Les migrations doivent être documentées.

---

# 51. Performance

Les performances sont une fonctionnalité.

Toujours privilégier :

* widgets const
* composition
* lazy loading lorsque pertinent
* rebuilds limités
* simplicité

Éviter les optimisations prématurées.

Mesurer avant d'optimiser.

---

# 52. Sécurité

Le framework ne doit jamais :

* masquer silencieusement une erreur critique ;
* provoquer une perte de données ;
* encourager une action dangereuse.

Les actions irréversibles doivent être traitées avec une attention particulière.

---

# 53. Gouvernance

Les décisions importantes doivent être argumentées.

Une proposition doit toujours répondre à :

Pourquoi ?

Quels bénéfices ?

Quels risques ?

Quelles alternatives ?

Pourquoi cette solution est-elle préférable ?

---

# 54. Style de communication

Les échanges techniques doivent rester :

factuels ;

argumentés ;

constructifs ;

respectueux.

Éviter les affirmations non justifiées.

Toujours distinguer :

* un fait ;
* une recommandation ;
* une opinion ;
* une hypothèse.

---

# 55. Règles pour les nouvelles fonctionnalités

Avant de créer une nouvelle fonctionnalité :

1. Comprendre le besoin utilisateur.
2. Vérifier qu'elle n'existe pas déjà.
3. Vérifier sa cohérence avec l'architecture.
4. Identifier les impacts.
5. Concevoir l'API.
6. Documenter.
7. Implémenter.
8. Tester.
9. Ajouter les exemples.
10. Vérifier l'accessibilité.

Ne jamais commencer par écrire du code.

---

# 56. Règles pour les composants

Un composant doit :

faire une seule chose ;

la faire correctement ;

être réutilisable ;

être accessible ;

être documenté ;

être testé.

Un composant trop spécialisé doit devenir un Pattern.

---

# 57. Règles pour les Patterns

Les Patterns sont la véritable valeur ajoutée du projet.

Ils doivent résoudre un problème utilisateur complet.

Ils peuvent assembler plusieurs composants.

Ils ne doivent jamais introduire de logique métier spécifique à une application.

---

# 58. Roadmap

L'ordre de développement recommandé est le suivant.

## Phase 1

Foundations

Semantic Tokens

Themes

Accessibility

Motion

Interaction

---

## Phase 2

Core Components

Button

TextField

Card

Dialog

Snackbar

Navigation

Progress

---

## Phase 3

Patterns

Action

Confirmation

Async

Loading

Error

Empty State

Permission

Decision

Forms

---

## Phase 4

Advanced Patterns

Onboarding

Search

Settings

Dashboard

Lists

Selection

Navigation

---

## Phase 5

Developer Experience

Testing helpers

Lint rules

Code generators

Templates

Documentation improvements

---

# 59. Ce que Codex doit éviter

Ne jamais :

réinventer l'architecture ;

modifier massivement sans justification ;

casser l'API publique inutilement ;

ajouter des paramètres redondants ;

multiplier les booléens ;

créer des composants dupliqués ;

introduire une dépendance importante sans justification ;

supposer un besoin utilisateur sans l'avoir identifié.

---

# 60. Mode de raisonnement attendu

Avant chaque implémentation, raisonner dans cet ordre :

1. Quel problème utilisateur résout-on ?

2. Quelles recommandations UX s'appliquent ?

3. Quelles contraintes d'accessibilité s'appliquent ?

4. Quels impacts sur l'API ?

5. Existe-t-il déjà un composant équivalent ?

6. Faut-il créer un nouveau composant ?

7. Comment documenter cette décision ?

8. Quels tests devront être écrits ?

Le code vient en dernier.

---

# 61. Fonctionnement avec les Mission Prompts

Ce document définit la vision permanente du projet.

Il constitue la référence principale.

Cependant, il ne décrit pas les travaux à réaliser.

Chaque session de développement commencera par un **Mission Prompt**.

Le Mission Prompt complète ce document.

Il décrit précisément :

* le contexte de la mission ;
* les objectifs ;
* les contraintes ;
* les livrables ;
* les critères d'acceptation ;
* les composants concernés ;
* les migrations éventuelles ;
* les tests attendus.

Le Mission Prompt peut ajouter des contraintes spécifiques.

Il ne peut jamais contredire les principes fondamentaux définis dans ce document.

En cas de conflit :

1. Les principes du présent document prévalent.
2. Le Mission Prompt précise uniquement la manière de les appliquer à une tâche donnée.

Avant toute implémentation, lire entièrement :

1. le présent document (`PROJECT_PROMPT.md`) ;
2. le Mission Prompt fourni pour la tâche.

Ne jamais commencer à modifier le code tant que le Mission Prompt n'a pas été analysé.

Si un Mission Prompt est ambigu, incomplet ou semble entrer en conflit avec la philosophie d'IUX, interrompre l'implémentation et demander des clarifications.

---

# 62. Objectif final

L'objectif d'IUX n'est pas de créer les composants les plus beaux.

L'objectif est de créer les composants les plus utiles.

Chaque composant doit améliorer la qualité des applications qui l'utilisent.

À terme, un développeur utilisant IUX doit pouvoir produire une interface de qualité professionnelle, cohérente, accessible et centrée sur l'humain en s'appuyant sur les fondations du framework, plutôt que sur une succession de décisions UX individuelles.

Chaque décision prise dans le projet doit contribuer à cette vision.

---

# 63. Suivi des Mission Prompts

Avant de commencer une mission, mettre à jour son en-tête YAML afin de rendre
son état explicite et d'éviter qu'une mission en cours ou terminée soit reprise
par erreur.

L'en-tête doit au minimum contenir :

```yaml
mission_id: IUX-XXX
title: Titre de la mission
priority: critical | high | medium | low
status: ready | in_progress | completed | blocked
started_at: YYYY-MM-DD # uniquement lorsque la mission commence
started_by: Identifiant de l'agent ou du contributeur
last_updated_at: YYYY-MM-DD
completion_status: pending | accepted | incomplete
validation_status: not_started | in_progress | passed | failed | partial
```

Règles de mise à jour :

* ne démarrer une mission que si son statut est `ready` ;
* passer son statut à `in_progress` avant le premier travail d'implémentation ;
* mettre à jour `last_updated_at` à chaque reprise significative ;
* ne passer à `completed` que lorsque les critères d'acceptation sont remplis,
  avec `completion_status: accepted` et un état de validation explicite ;
* utiliser `blocked` si une clarification ou une dépendance indispensable
  empêche la progression, en indiquant le blocage dans le document ;
* ne jamais modifier une mission `completed` pour la reprendre : créer une
  nouvelle mission de suivi.
