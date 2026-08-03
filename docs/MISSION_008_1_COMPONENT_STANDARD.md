---
mission_id: IUX-008.1
epic: IUX-008
title: Component Standard — Part 1 — Vision, Architecture & Design Principles
priority: critical
status: completed
started_at: 2026-08-03
started_by: Claude
last_updated_at: 2026-08-03
completion_status: accepted
validation_status: passed
target_version: 0.2.0-dev.1
compatibility: additive
depends_on:
  - IUX-001
  - IUX-002
  - IUX-003
  - IUX-004
  - IUX-005
  - IUX-006
  - IUX-007
platform_priority: Android
package_name: iux_flutter
---

# IUX-008.1 — Component Standard
## Partie 1 — Vision, Architecture & Design Principles

---

# 1. Références obligatoires

Avant toute modification :

1. Lire intégralement `PROJECT_PROMPT.md`.
2. Lire toutes les missions IUX-001 à IUX-007.
3. Vérifier que toutes les missions précédentes sont terminées.
4. Lire entièrement cette mission.
5. Considérer cette mission comme le contrat officiel de développement des composants IUX.
6. Ne pas modifier `d4-dark-ds`.
7. Ne créer aucun composant qui ne respecte pas cette spécification.

---

# 2. Importance de cette mission

Cette mission est la plus importante de toute la bibliothèque.

Elle ne décrit pas un bouton.

Elle définit **la manière dont tous les composants devront être construits**.

Les missions suivantes devront s'y conformer :

- Buttons
- Text Fields
- Checkbox
- Radio
- Switch
- Card
- Dialog
- Snackbar
- Bottom Sheet
- Navigation
- List
- Avatar
- Badge
- Chip
- etc.

Elle devient le **Component Standard IUX**.

---

# 3. Objectif

Créer un standard garantissant que chaque composant possède :

- une API cohérente ;
- un comportement prévisible ;
- une accessibilité native ;
- une résolution de thème uniforme ;
- un cycle de vie identique ;
- une architecture facilement maintenable ;
- une documentation homogène ;
- une stratégie de tests identique.

Le développeur doit avoir l'impression d'utiliser une seule famille de composants.

---

# 4. Philosophie

Un composant IUX n'est jamais uniquement un widget Flutter.

C'est l'association de plusieurs couches indépendantes.

```text
Public API

↓

Intentions UX

↓

Semantic Resolution

↓

Theme Resolution

↓

Accessibility Runtime

↓

Interaction Engine

↓

Motion Engine

↓

Feedback Engine

↓

Rendering
```

Aucune couche ne doit fusionner plusieurs responsabilités.

---

# 5. Responsabilités

Chaque composant doit être responsable uniquement de :

- représenter un rôle UX ;
- exposer une API stable ;
- résoudre son apparence depuis le thème ;
- dialoguer avec le runtime d'accessibilité ;
- déclencher les événements appropriés ;
- afficher son état.

Il ne doit jamais :

- gérer la logique métier ;
- effectuer des appels réseau ;
- connaître une architecture applicative ;
- dépendre d'un package métier.

---

# 6. Les composants ne sont pas des styles

Un bouton n'est pas :

> un rectangle bleu.

Un bouton représente :

> une action.

Une carte représente :

> un regroupement.

Un badge représente :

> un statut.

Un champ représente :

> une saisie.

Toutes les décisions graphiques proviennent du thème.

---

# 7. Les composants expriment une intention

L'API doit privilégier :

```dart
intent

importance

role

state
```

plutôt que :

```dart
color

shadow

radius

borderColor

background
```

Le développeur décrit une intention.

Le thème décide de la représentation.

---

# 8. Architecture interne

Tous les composants IUX devront suivre la même architecture.

```text
Component

├── Public API
├── Theme Resolution
├── Semantic Resolution
├── Accessibility Layer
├── Interaction Layer
├── Motion Layer
├── Feedback Layer
├── Render Layer
└── Tests
```

Cette architecture devient obligatoire.

---

# 9. Public API

La Public API est la seule couche visible.

Elle doit :

- être concise ;
- être explicite ;
- éviter les paramètres décoratifs ;
- utiliser des valeurs fortement typées ;
- être stable.

Éviter :

```dart
Button(
  color: ...
)
```

Préférer :

```dart
IuxButton(
  intent: IuxActionIntent.primary,
)
```

---

# 10. Intentions

Les composants décrivent une intention.

Jamais une couleur.

Exemples :

```text
primary

secondary

tertiary

destructive

informational

neutral
```

Ces intentions seront définies dans les missions suivantes.

---

# 11. Séparation stricte

Ne jamais mélanger :

- rôle UX ;
- apparence ;
- interaction ;
- animation ;
- accessibilité.

Chaque couche doit rester indépendante.

---

# 12. Dépendances

Chaque composant pourra dépendre :

✔ Foundations

✔ Semantic Tokens

✔ Theme Engine

✔ Accessibility Runtime

✔ Motion Engine

✔ Layout System

Mais jamais :

❌ d'un autre composant équivalent

Exemple :

Un TextField ne dépend pas d'un Button.

Un Button ne dépend pas d'un Dialog.

---

# 13. Sens des dépendances

Toujours :

```text
Foundations

↓

Themes

↓

Runtime

↓

Component
```

Jamais :

```text
Component

↓

Theme
```

Le thème ne doit jamais dépendre d'un composant.

---

# 14. Responsabilité unique

Chaque composant possède une seule responsabilité.

Exemple :

Un bouton :

✔ déclenche une action

Il ne :

- valide pas un formulaire
- n'appelle pas une API
- n'ouvre pas automatiquement un dialogue
- n'affiche pas automatiquement une snackbar

---

# 15. Les composants restent contrôlés

Les composants IUX sont contrôlés.

Ils ne décident jamais seuls :

- qu'une action est réussie ;
- qu'une action échoue ;
- qu'une suppression est confirmée.

Le parent garde la responsabilité métier.

---

# 16. Composition

La composition est préférée à l'héritage.

Préférer :

```text
Button

+

Theme

+

Accessibility

+

Motion
```

plutôt que :

```text
AbstractButton

↓

MaterialButton

↓

FancyButton

↓

MyCompanyButton
```

---

# 17. Flutter First

IUX complète Flutter.

Il ne cherche pas à le remplacer.

Les composants Flutter standards restent utilisables.

Les développeurs doivent pouvoir mélanger progressivement :

```dart
Text()

IuxButton()

Container()
```

sans friction.

---

# 18. Material n'est pas l'API publique

Les composants pourront utiliser Material.

Mais Material ne doit pas définir l'API publique.

Exemple :

Le développeur ne devrait pas avoir besoin de connaître :

- ButtonStyle
- MaterialStateProperty
- WidgetStateProperty

Le composant IUX traduit ces mécanismes.

---

# 19. BuildContext

Le BuildContext ne doit être utilisé que lorsqu'il est réellement nécessaire.

Exemples :

✔ thème

✔ localisation

✔ accessibilité

✔ MediaQuery

Éviter :

- stocker le contexte ;
- passer le contexte inutilement ;
- résoudre plusieurs fois les mêmes informations.

---

# 20. Immutabilité

Tous les objets publics doivent être immuables.

Utiliser :

- final
- const
- copyWith
- ==

si pertinent.

Aucun état mutable partagé.

---

# 21. Valeurs arbitraires

Interdiction d'utiliser :

```dart
padding: EdgeInsets.all(13)
```

ou

```dart
borderRadius: 11
```

Toutes les valeurs doivent provenir :

- des fondations ;
- des thèmes ;
- des tokens.

---

# 22. Magic Numbers

Aucun nombre magique.

Toute valeur doit être :

- nommée ;
- documentée ;
- centralisée.

---

# 23. Le thème est la seule source graphique

Les composants ne choisissent jamais :

- une couleur ;
- une ombre ;
- une bordure ;
- une police.

Ils demandent :

> un rôle.

Le thème répond.

---

# 24. Les composants restent prédictibles

Un même état produit toujours le même comportement.

Exemple :

Disabled

↓

Toujours :

- pas de clic
- focus impossible
- feedback réduit
- annonce cohérente

Jamais un comportement spécifique à un composant.

---

# 25. Convention de nommage

Tous les composants publics utilisent :

```text
Iux...
```

Exemple :

```text
IuxButton

IuxTextField

IuxDialog

IuxBadge
```

Aucune abréviation obscure.

---

# 26. Préparation de la partie suivante

La partie suivante définira :

- l'API Design ;
- les conventions de paramètres ;
- les variantes ;
- les états ;
- le cycle de vie ;
- les conventions de rendu ;
- les conventions d'interaction.

Ces règles deviendront obligatoires pour tous les composants IUX.

# 27. Principe fondamental

Tous les composants IUX doivent partager une API homogène.

Un développeur qui apprend à utiliser :

- IuxButton

doit immédiatement comprendre :

- IuxTextField
- IuxCheckbox
- IuxCard
- IuxDialog
- IuxChip
- IuxAvatar
- IuxBanner

sans devoir réapprendre une nouvelle convention.

L'objectif est de créer une cohérence de bibliothèque.

---

# 28. Une API pilotée par l'intention

Les paramètres publics doivent décrire :

- ce que le développeur souhaite obtenir ;
- jamais comment le composant doit être dessiné.

Exemple :

✔

```dart
intent: IuxActionIntent.primary
```

❌

```dart
backgroundColor: Colors.blue
```

---

# 29. Une API fortement typée

Éviter les paramètres libres.

Mauvais :

```dart
String type
```

Préférer :

```dart
enum IuxActionIntent
```

ou

```dart
sealed class IuxButtonVariant
```

Les erreurs doivent être détectées à la compilation.

---

# 30. Les paramètres décoratifs sont interdits

L'API publique ne doit pas contenir :

```dart
backgroundColor

foregroundColor

shadow

radius

borderWidth

borderColor

gradient
```

Ces décisions appartiennent au thème.

---

# 31. Les paramètres fonctionnels sont autorisés

L'API publique peut contenir :

```dart
enabled

autofocus

onPressed

child

leading

trailing

semanticLabel

tooltip

intent

importance

state
```

Uniquement des paramètres liés au comportement.

---

# 32. Les paramètres doivent être regroupés

Éviter :

```dart
loading

error

success

busy

retry
```

Préférer une abstraction.

Exemple :

```dart
state: IuxActionState.loading
```

---

# 33. Les booléens sont limités

Accumuler des booléens rend l'API illisible.

Mauvais :

```dart
enabled

loading

outlined

filled

rounded

destructive

primary
```

Préférer :

```dart
intent

variant

state

importance
```

---

# 34. Les valeurs nulles

Éviter les paramètres nullable lorsqu'une valeur par défaut existe.

Exemple :

✔

```dart
intent = primary
```

plutôt que

```dart
IuxActionIntent?
```

Le null ne doit jamais servir de valeur métier.

---

# 35. Les constructeurs

Limiter le nombre de constructeurs.

Préférer :

```dart
IuxButton()
```

à

```dart
IuxPrimaryButton()

IuxDangerButton()

IuxBlueButton()
```

Les variantes doivent être exprimées par des intentions.

---

# 36. Les paramètres obligatoires

Limiter les paramètres obligatoires.

Exemple :

```dart
required Widget child

required VoidCallback onPressed
```

Tout le reste doit posséder une valeur par défaut raisonnable.

---

# 37. L'ordre des paramètres

Toujours utiliser le même ordre.

Exemple :

```dart
child

intent

variant

state

enabled

autofocus

focusNode

semanticLabel

tooltip

onPressed
```

Tous les composants devront respecter cette logique.

---

# 38. Les callbacks

Les callbacks décrivent uniquement :

une interaction.

Jamais :

un résultat métier.

Exemple :

✔

```dart
onPressed
```

❌

```dart
onLoginSucceeded
```

---

# 39. Les composants sont contrôlés

Le parent possède toujours l'état.

Exemple :

```dart
IuxButton(
    state: loading,
)
```

Le bouton ne décide jamais seul qu'il est en succès.

---

# 40. Cycle de vie

Tous les composants suivent :

```text
Construction

↓

Theme Resolution

↓

Accessibility Resolution

↓

Interaction Resolution

↓

Motion Resolution

↓

Render

↓

Interaction

↓

Notification au parent

↓

Rebuild
```

Aucun composant ne saute une étape.

---

# 41. Architecture interne

Tous les composants devront être organisés de manière similaire.

Exemple :

```text
button/

    button.dart

    button_theme.dart

    button_renderer.dart

    button_semantics.dart

    button_motion.dart

    button_feedback.dart

    button_states.dart

    button_tests/
```

Cette structure est une référence.

Elle peut évoluer si une meilleure organisation est justifiée.

---

# 42. La couche Render

La couche Render :

- ne décide rien ;
- ne résout rien ;
- ne choisit aucune couleur.

Elle reçoit un modèle entièrement résolu.

Elle dessine.

Uniquement.

---

# 43. La couche Theme

Elle transforme :

```text
Intentions

↓

Tokens

↓

Valeurs graphiques
```

Elle ne construit pas le widget.

---

# 44. La couche Accessibility

Elle résout :

- Semantics
- Focus
- Touch Target
- TalkBack
- Text Scaling

Elle ne dessine rien.

---

# 45. La couche Motion

Elle décide :

- durée
- courbe
- transition
- suppression éventuelle

Elle ne connaît pas le thème.

---

# 46. La couche Feedback

Elle décide :

- feedback visuel
- feedback haptique
- annonce

Elle ne modifie jamais la logique métier.

---

# 47. Le rendu est stateless

Le rendu doit rester le plus stateless possible.

Les états métier ne doivent jamais être cachés.

---

# 48. La logique interne

Si une logique interne est nécessaire :

elle doit être :

- isolée ;
- testable ;
- documentée.

Éviter les méthodes privées gigantesques.

---

# 49. BuildContext

Une information issue du contexte ne doit être résolue qu'une seule fois.

Mauvais :

```dart
Theme.of(context)

Theme.of(context)

Theme.of(context)
```

Préférer :

```dart
final theme = IuxTheme.of(context);
```

---

# 50. Composition des couches

Toutes les couches doivent pouvoir évoluer indépendamment.

Modifier :

- le moteur de mouvement

ne doit pas imposer :

- une réécriture des composants.

---

# 51. Pas d'effets de bord

Construire un composant ne doit jamais :

- lancer un Future ;
- afficher une Snackbar ;
- vibrer ;
- déclencher une navigation.

Ces comportements appartiennent au parent.

---

# 52. Les erreurs

Un composant ne masque jamais une erreur.

Si une configuration est invalide :

- assertion en debug ;
- documentation ;
- comportement explicite.

Jamais :

une correction silencieuse.

---

# 53. Contrats publics

Chaque composant devra documenter :

- ce qui est garanti ;
- ce qui ne l'est pas.

Les comportements implicites doivent être évités.

---

# 54. Compatibilité

Une évolution d'API doit être :

- additive ;
- documentée ;
- migrable.

Les changements cassants doivent être exceptionnels.

---

# 55. Préparation de la partie suivante

La prochaine partie définira :

- tous les états ;
- les intentions ;
- les variantes ;
- les transitions d'état ;
- le cycle de vie interactif ;
- les conventions communes à tous les composants.

# 56. Objectif

Tous les composants IUX doivent partager le même modèle d'état.

Un utilisateur ne doit jamais observer deux composants qui réagissent différemment dans une situation identique.

Les états doivent être :

- prévisibles ;
- accessibles ;
- documentés ;
- réutilisables ;
- testables.

---

# 57. Principe fondamental

Un composant possède :

- un état fonctionnel ;
- un état interactif ;
- éventuellement un état visuel dérivé.

Ces dimensions ne doivent jamais être fusionnées dans un unique enum.

---

# 58. Les trois familles d'états

Les composants distinguent :

```text
Functional State

↓

Interaction State

↓

Visual State
```

Chaque couche possède une responsabilité différente.

---

# 59. Functional State

Le Functional State décrit la capacité du composant.

Exemple :

```text
Enabled

Disabled

Loading

Success

Error
```

Ce sont des états métier fournis par le parent.

---

# 60. Interaction State

Il représente l'interaction utilisateur.

Exemple :

```text
Idle

Hovered

Focused

Pressed
```

Ces états sont pilotés par Flutter.

---

# 61. Visual State

Le rendu final peut combiner plusieurs dimensions.

Exemple :

```text
Enabled

+

Pressed

↓

Pressed Enabled
```

ou

```text
Loading

+

Focused

↓

Focused Loading
```

Le composant ne doit jamais exposer directement ces combinaisons.

---

# 62. Le parent reste propriétaire

Le parent décide toujours :

```dart
loading

enabled

error

success
```

Le composant ne les invente jamais.

---

# 63. Les états autorisés

Tous les composants doivent pouvoir exprimer au minimum :

```text
Enabled

Disabled

Loading
```

Les autres états sont optionnels selon leur pertinence.

---

# 64. Idle

Idle représente :

- disponible ;
- sans interaction ;
- prêt.

C'est l'état initial.

---

# 65. Hover

Hover n'est pas garanti.

Sur Android il peut ne jamais exister.

Les composants ne doivent jamais dépendre de Hover.

---

# 66. Focus

Le focus est obligatoire.

Tous les composants interactifs doivent gérer :

- focus visible ;
- focus clavier ;
- focus TalkBack.

---

# 67. Pressed

Pressed représente une interaction temporaire.

Il disparaît dès la fin de l'interaction.

Aucun état métier ne doit en dépendre.

---

# 68. Disabled

Disabled signifie :

- impossible à utiliser ;
- impossible à focaliser (sauf exception documentée) ;
- feedback réduit ;
- annonce adaptée.

Le composant reste lisible.

---

# 69. Loading

Loading indique :

- action en cours ;
- attente utilisateur.

Il ne signifie pas :

succès.

Ni :

erreur.

---

# 70. Success

Success représente un résultat.

Jamais :

une animation.

Le composant reçoit cette information.

Il ne la déduit jamais.

---

# 71. Error

Même principe.

L'erreur provient :

du parent.

Jamais :

du composant.

---

# 72. Selected

Tous les composants ne possèdent pas Selected.

Uniquement ceux dont le rôle le justifie.

Par exemple :

Checkbox

Chip

Navigation

Tab

Segment

---

# 73. Read Only

ReadOnly n'est pas Disabled.

ReadOnly :

✔ lisible

✔ focalisable si nécessaire

✔ copiable

mais

❌ non modifiable.

---

# 74. Busy

Busy est différent de Loading.

Busy signifie :

> l'interface est momentanément indisponible.

Loading signifie :

> une opération est en cours.

Les deux concepts ne doivent pas être fusionnés.

---

# 75. États interdits

Ne jamais créer :

```text
BlueState

DangerState

PremiumState

RoundedState
```

Un état ne décrit jamais l'apparence.

---

# 76. Intentions

Les intentions représentent :

le but UX.

Exemple :

```text
Primary

Secondary

Tertiary

Destructive

Neutral

Informational
```

Les intentions sont indépendantes des états.

---

# 77. Importance

Une action peut posséder une importance.

Par exemple :

```text
High

Medium

Low
```

L'importance ne doit pas être déduite d'une couleur.

---

# 78. Réversibilité

Toutes les actions importantes doivent pouvoir indiquer :

```text
Reversible

DifficultToReverse

Irreversible
```

Cette information permettra plus tard :

- confirmations ;
- animations ;
- feedback.

---

# 79. Variantes

Une variante décrit :

la représentation.

Exemple :

```text
Filled

Outlined

Text

Icon
```

Elle ne modifie pas :

l'intention.

---

# 80. Intentions ≠ Variantes

Toujours distinguer :

```text
Primary

↓

Filled
```

de

```text
Secondary

↓

Outlined
```

Les deux dimensions sont indépendantes.

---

# 81. Etats impossibles

Certaines combinaisons doivent être interdites.

Par exemple :

```text
Disabled

+

Pressed
```

ou

```text
Loading

+

Hover
```

Si une combinaison est impossible, elle doit être documentée.

---

# 82. Machine à états

Les transitions doivent être explicites.

Exemple :

```text
Idle

↓

Pressed

↓

Loading

↓

Success

↓

Idle
```

ou

```text
Idle

↓

Pressed

↓

Loading

↓

Error

↓

Idle
```

---

# 83. Transitions interdites

Éviter :

```text
Loading

↓

Pressed
```

ou

```text
Disabled

↓

Pressed
```

Ces transitions sont invalides.

---

# 84. Durée des états

Les états interactifs sont temporaires.

Les états fonctionnels persistent tant que le parent le décide.

---

# 85. Les composants ne devinent jamais

Un composant ne transforme jamais :

Loading

↓

Success

automatiquement.

Le parent doit toujours envoyer :

```dart
state = success
```

---

# 86. Les animations suivent les états

Les animations sont une conséquence.

Jamais :

la source de vérité.

---

# 87. Les thèmes suivent les états

Les couleurs suivent :

l'état.

Jamais :

l'inverse.

---

# 88. Feedback

Le feedback suit :

les transitions.

Exemple :

```text
Loading

↓

Success

↓

Feedback
```

Pas :

```text
Pressed

↓

Success
```

---

# 89. Accessibilité

Chaque transition importante doit être :

- lisible ;
- annoncée si nécessaire ;
- visible ;
- compréhensible sans couleur seule.

---

# 90. Préparation de la Partie 4

La prochaine partie définira :

- Semantics ;
- Focus ;
- Touch Targets ;
- Reduced Motion ;
- Feedback ;
- Haptics ;
- TalkBack ;
- High Contrast ;
- Long Labels ;
- RTL ;
- Text Scaling.

Toutes ces règles deviendront obligatoires pour chaque composant

# 91. Objectif

Cette partie définit le **Runtime Contract**.

Tous les composants IUX devront communiquer avec les mêmes moteurs.

Aucun composant ne devra réimplémenter :

- le focus ;
- les semantics ;
- le mouvement ;
- le feedback ;
- les touch targets ;
- les annonces ;
- les préférences utilisateur.

---

# 92. Le Runtime IUX

Chaque composant fonctionne au-dessus du Runtime.

```text
Application

↓

Theme Engine

↓

Accessibility Runtime

↓

Motion Runtime

↓

Feedback Runtime

↓

Component Runtime

↓

Render Layer
```

Le composant n'accède jamais directement aux couches basses lorsqu'un service IUX existe.

---

# 93. Component Runtime

Le Runtime représente :

> tout ce dont un composant a besoin pour fonctionner.

Il résout notamment :

- thème
- accessibilité
- mouvement
- feedback
- layout
- plateforme

---

# 94. Les composants ne parlent pas directement à Flutter

Éviter :

```dart
Theme.of(context)

MediaQuery.of(context)

SemanticsService

HapticFeedback

FocusScope
```

dans chaque composant.

Préférer les abstractions IUX.

---

# 95. Résolution unique

Toutes les informations sont résolues une seule fois.

Exemple :

```text
BuildContext

↓

IuxRuntime

↓

Component
```

Jamais :

```text
Component

↓

Theme

↓

Theme

↓

MediaQuery

↓

Focus

↓

Theme
```

---

# 96. Semantics

Tous les composants interactifs doivent fournir automatiquement :

✔ rôle

✔ état

✔ activation

✔ désactivation

✔ sélection

✔ annonce

✔ description

✔ ordre de lecture

---

# 97. Les composants ne manipulent pas Semantics directement

Préférer :

```dart
IuxSemantics(
    ...
)
```

plutôt que :

```dart
Semantics(
...
)
```

dans tous les composants.

---

# 98. TalkBack

Chaque composant doit fonctionner avec :

TalkBack

sans configuration supplémentaire.

Les annonces doivent être :

- courtes
- utiles
- localisées
- non redondantes.

---

# 99. Focus

Tous les composants interactifs doivent supporter :

- clavier
- switch access
- TalkBack
- D-Pad
- souris

si Flutter les fournit.

---

# 100. Focus Ring

Le Focus Ring provient exclusivement du thème.

Le composant ne choisit jamais :

- sa couleur
- son épaisseur
- sa forme.

---

# 101. Touch Targets

Tous les composants doivent respecter :

les règles définies dans IUX-005.

Aucune exception.

---

# 102. Les Touch Targets sont invisibles

La surface interactive

≠

la surface visuelle.

Le Runtime doit pouvoir les distinguer.

---

# 103. Reduced Motion

Tous les composants doivent consulter :

```text
IuxMotion
```

Jamais :

MediaQuery directement.

---

# 104. Les animations décoratives

Les animations décoratives doivent disparaître

en Reduced Motion.

---

# 105. Les animations fonctionnelles

Certaines animations restent utiles.

Exemple :

- changement de taille
- ouverture
- fermeture
- apparition

Le Runtime décide.

---

# 106. Haptics

Les composants ne doivent jamais appeler directement :

```dart
HapticFeedback.lightImpact()
```

Ils utilisent :

```text
IuxFeedback
```

---

# 107. Feedback

Les composants ne produisent pas eux-mêmes :

- vibration
- annonce
- snackbar
- toast

Ils émettent :

un événement.

---

# 108. Le parent reste maître

Le Runtime ne déclenche jamais :

une logique métier.

Il fournit :

des services.

---

# 109. BuildContext

Le Runtime doit être obtenu une seule fois.

Exemple :

```dart
final runtime = IuxRuntime.of(context);
```

Puis :

```dart
runtime.theme

runtime.motion

runtime.feedback

runtime.accessibility
```

---

# 110. Text Scaling

Tous les composants doivent accepter :

200 %

voire davantage.

Sans :

overflow majeur.

---

# 111. Long Labels

Les composants doivent fonctionner avec :

des textes longs.

Exemple :

Allemand

Finnois

Polonais

Français

---

# 112. RTL

Tous les composants doivent fonctionner en RTL.

Aucune position "left"

ou "right"

ne doit être codée.

Toujours utiliser :

```text
start

end
```

---

# 113. Couleur

Aucun état important ne dépend uniquement :

de la couleur.

Toujours prévoir :

- texte
- icône
- forme
- semantics

si nécessaire.

---

# 114. Keyboard

Tous les composants interactifs doivent être utilisables :

sans souris.

---

# 115. Accessibilité progressive

Le développeur ne devrait pas avoir besoin de connaître :

TalkBack

Semantics

Focus

pour produire un composant accessible.

Le Runtime fournit ces comportements.

---

# 116. Contrats obligatoires

Chaque composant devra respecter :

✔ Focus

✔ Semantics

✔ Reduced Motion

✔ Touch Targets

✔ Theme

✔ Feedback

✔ Runtime

sans exception.

---

# 117. Interactions

Toutes les interactions suivent :

```text
Input

↓

Validation

↓

State

↓

Motion

↓

Feedback

↓

Semantics

↓

Render
```

Jamais l'inverse.

---

# 118. Les composants sont silencieux

Un composant ne décide jamais :

- de naviguer
- d'ouvrir une page
- d'afficher un message

Il notifie uniquement :

son parent.

---

# 119. Contrat Runtime

Le Runtime devient obligatoire

pour tous les composants IUX.

Aucune implémentation parallèle ne sera acceptée.

---

# 120. Préparation de la Partie 5

La dernière partie définira :

- Documentation
- Catalogue
- Tests
- Golden Tests
- Benchmarks
- API Stability
- Versioning
- Release Checklist
- Component Review Checklist

Elle conclura définitivement le Component Standard IUX.

# 121. Objectif

Cette partie définit les exigences minimales de qualité.

Aucun composant IUX ne pourra être considéré comme terminé tant qu'il ne respecte pas intégralement cette spécification.

Ces exigences s'appliquent à tous les composants, quelle que soit leur taille.

---

# 122. Définition de "Done"

Un composant est considéré comme terminé uniquement si :

- son API est stable ;
- son comportement est documenté ;
- son accessibilité est validée ;
- ses tests passent ;
- son catalogue est complet ;
- ses performances sont acceptables ;
- il respecte les conventions IUX.

Le rendu visuel seul n'est jamais un critère suffisant.

---

# 123. Documentation obligatoire

Chaque composant doit posséder sa propre documentation.

Structure minimale :

```text
Purpose

When to use

When not to use

Accessibility

API

Examples

Best Practices

Anti-patterns

Known limitations
```

---

# 124. Les exemples

Chaque composant doit fournir plusieurs exemples.

Au minimum :

- utilisation minimale ;
- utilisation recommandée ;
- utilisation avancée ;
- intégration avec le thème ;
- intégration avec le runtime.

Les exemples doivent être exécutables.

---

# 125. Anti-patterns

Chaque documentation doit montrer :

✔ les bonnes pratiques

mais aussi

❌ les mauvaises pratiques.

Exemple :

Ne pas utiliser un bouton destructif pour une action sans conséquence.

---

# 126. Catalogue

Tous les composants doivent apparaître dans le catalogue.

Chaque composant possède une section dédiée.

---

# 127. Structure du catalogue

Chaque composant présente au minimum :

```text
Overview

Variants

States

Accessibility

Theming

Responsive

Long Labels

RTL

Text Scaling

Reduced Motion

High Contrast

Performance

Do

Don't
```

Tous les composants utilisent exactement cette structure.

---

# 128. Démonstrations obligatoires

Chaque composant doit être testé dans plusieurs contextes :

- clair ;
- sombre ;
- contraste élevé ;
- densité compacte ;
- densité confortable ;
- texte agrandi ;
- libellés longs ;
- RTL ;
- mouvement réduit.

---

# 129. Widget Tests

Tous les composants possèdent des Widget Tests.

Ils doivent couvrir :

- rendu ;
- interactions ;
- états ;
- rebuilds ;
- accessibilité.

---

# 130. Unit Tests

Toute logique non graphique doit être testée.

Exemples :

- résolution des états ;
- résolution des thèmes ;
- runtime ;
- transitions.

---

# 131. Tests Semantics

Tous les composants interactifs doivent vérifier :

- rôle ;
- label ;
- état ;
- ordre de lecture ;
- activation.

---

# 132. Tests Focus

Tous les composants interactifs doivent tester :

- focus clavier ;
- focus TalkBack ;
- ordre de focus ;
- visibilité du focus.

---

# 133. Tests Motion

Les animations doivent être testées.

Notamment :

- réduction ;
- suppression ;
- durée ;
- courbe.

---

# 134. Tests Feedback

Tester :

- événements ;
- haptique ;
- annonces ;
- absence de doublons.

---

# 135. Golden Tests

Les Golden Tests sont recommandés pour les composants visuels stables.

Ils doivent couvrir au minimum :

- Light
- Dark
- High Contrast

Ils ne remplacent jamais les Widget Tests.

---

# 136. Tests Responsive

Tester plusieurs tailles d'écran :

- compact ;
- medium ;
- expanded.

Le composant ne doit pas casser sa mise en page.

---

# 137. Text Scaling

Tester au minimum :

100 %

150 %

200 %

Le composant doit rester utilisable.

---

# 138. Long Labels

Tester des langues réputées longues.

Exemple :

Allemand

Finnois

Français

Aucun overflow important ne doit apparaître.

---

# 139. RTL

Tester systématiquement :

Directionality.rtl

Tous les composants doivent fonctionner sans adaptation spécifique.

---

# 140. Performance

Les composants doivent rester légers.

Éviter :

- rebuilds inutiles ;
- allocations répétées ;
- calculs dans build() ;
- objets mutables.

---

# 141. API Stability

Une API publique ne peut évoluer que si :

- la migration est documentée ;
- les changements sont justifiés ;
- les ruptures sont exceptionnelles.

---

# 142. Dépréciation

Toute API obsolète doit :

- être annotée ;
- proposer une alternative ;
- rester disponible pendant une période définie avant suppression.

---

# 143. Versionnement

Les composants suivent le versionnement global d'IUX.

Toute modification cassante doit être accompagnée :

- d'une note de migration ;
- d'une justification.

---

# 144. Revue obligatoire

Avant validation, chaque composant doit répondre à toutes les questions suivantes.

## Architecture

- respecte-t-il le Component Standard ?
- les responsabilités sont-elles séparées ?
- le Runtime est-il utilisé ?

## API

- l'API est-elle cohérente ?
- les intentions sont-elles explicites ?
- aucun paramètre décoratif n'est-il exposé ?

## Accessibilité

- TalkBack fonctionne-t-il ?
- le focus est-il visible ?
- les touch targets sont-elles respectées ?
- le texte agrandi fonctionne-t-il ?
- le RTL fonctionne-t-il ?

## UX

- les états sont-ils cohérents ?
- le feedback est-il proportionné ?
- les animations sont-elles justifiées ?

## Code

- la logique est-elle testée ?
- le composant est-il documenté ?
- les dépendances sont-elles minimales ?

---

# 145. Checklist Release

Avant fusion :

□ flutter analyze

□ flutter test

□ catalogue mis à jour

□ documentation mise à jour

□ ADR créée si nécessaire

□ Evidence Registry mise à jour

□ API revue

□ accessibilité vérifiée

□ performances validées

---

# 146. Interdictions

Un composant IUX ne doit jamais :

- contenir des couleurs codées en dur ;
- lancer un appel réseau ;
- dépendre d'un package métier ;
- déclencher une navigation ;
- afficher directement une Snackbar ;
- vibrer directement ;
- manipuler MediaQuery ou Theme partout ;
- réimplémenter le Runtime.

---

# 147. Contrat de qualité

Tous les composants futurs devront appliquer cette mission.

Les missions suivantes (Buttons, TextField, Dialog, Card, etc.) ne redéfiniront plus ces règles.

Elles devront simplement les respecter.

---

# 148. Statut

À partir de cette mission :

Le **Component Standard IUX** devient la référence officielle de développement.

Toute nouvelle API devra être cohérente avec cette spécification.

---

# 149. Livrable attendu

À la fin de cette mission, Codex devra fournir :

- la documentation ;
- les ADR ;
- les conventions de développement ;
- les conventions d'API ;
- les conventions d'accessibilité ;
- les conventions de tests ;
- les conventions de catalogue ;
- les checklists de revue.

Aucun composant concret n'est créé dans cette mission.

---

# 150. Instruction finale

Ne créer aucun composant.

Ne créer aucune implémentation visuelle.

Produire uniquement le **Component Standard IUX**.

Toutes les missions suivantes devront s'y conformer intégralement.


---

# Rapport final

## Résumé

Le Component Standard opérant est livré, aligné sur les API réellement
construites par IUX-002 à IUX-007 — et sa moitié mécanique est **exécutée**,
pas seulement écrite.

## Livrables

- `docs/components/component-standard.md` — la référence opérante
- `docs/components/review-checklist.md` — ce qu'une machine ne peut pas juger
- `docs/decisions/ADR-0008-component-standard.md`
- `packages/iux_flutter/test/components/component_standard_test.dart`
- `COMPONENT_STANDARD.md` racine annoté comme brouillon d'origine

Aucun composant créé, conformément au §150.

## Décision principale

Un standard écrit est respecté jusqu'à ce que quelqu'un soit pressé. Neuf
interdits du §146 sont donc vérifiés par test : littéral de couleur, constante
`Colors.*`, lecture de `MediaQuery`, appel haptique direct, annonce directe,
durée d'animation codée en dur, `Navigator`, `ScaffoldMessenger`, accès
réseau. Plus la forme du barrel : trié, exports résolvables, primitives non
exportées.

La revue humaine garde ce qui relève du jugement — un libellé est-il
compréhensible, le composant résout-il un vrai problème, TalkBack le lit-il
correctement.

## Vérification de la garantie

Les règles passent actuellement à vide, aucun composant n'existant. Une
garantie vide est une fausse garantie : le test a donc été confronté à un
fichier sonde contenant `Colors.red`, qu'il a bien rejeté, avant d'être
considéré comme fiable.

## Limites

- La correspondance sur le texte source ne suit ni alias ni helper masquant un
  appel interdit.
- La portée est fixée par répertoire : un composant placé ailleurs échappe au
  contrôle.
- Un plugin analyzer serait plus robuste ; prématuré tant qu'aucun composant
  n'existe. Candidat Phase 5.

## Prochaine mission

IUX-008.2 — Action Model.
