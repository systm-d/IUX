---
mission_id: IUX-005
title: Accessibility Runtime
priority: critical
status: completed
started_at: 2026-08-03
started_by: Claude
last_updated_at: 2026-08-03
completion_status: accepted
validation_status: passed
target_version: 0.1.0-dev.5
compatibility: additive
depends_on:
  - IUX-001
  - IUX-002
  - IUX-003
  - IUX-004
platform_priority: Android
package_name: iux_flutter
---

# MISSION_005_ACCESSIBILITY_RUNTIME.md

> Mission ID: IUX-005
> Title: Accessibility Runtime
> Priority: Critical
> Depends on: IUX-001 → IUX-004

# Objectif

Construire l'infrastructure d'accessibilité réutilisable par tous les composants IUX.

Aucun composant final (Button, TextField, Card...) ne doit être créé dans cette mission.

# Livrables

## Runtime

Créer une couche `accessibility/` contenant notamment :

- IuxAccessibility
- IuxAccessibilityProfile
- IuxSemantics
- IuxFocusManager
- IuxFocusRing
- IuxTouchTarget
- IuxAnnouncement
- IuxReducedMotion
- IuxReadableText

Les noms définitifs peuvent évoluer si une meilleure architecture est proposée.

## Profils

Le runtime doit gérer des préférences combinables :

- mouvement réduit
- contraste élevé
- taille tactile confortable
- densité
- stimulation visuelle réduite

Sans dépendre d'un diagnostic utilisateur.

## Semantics

Créer des helpers pour :

- labels
- hints
- rôles
- états
- annonces
- ordre de lecture

Les composants futurs devront utiliser ces helpers plutôt que manipuler directement `Semantics` partout.

## Focus

Créer une infrastructure commune pour :

- focus visible
- navigation clavier
- ordre de focus
- focus restauration
- focus des dialogues futurs

## Touch Targets

Créer un moteur garantissant les tailles interactives minimales.

Les composants devront pouvoir déclarer leur taille cible sans recopier la logique.

## Reduced Motion

Créer une abstraction permettant aux composants de savoir s'ils doivent :

- supprimer
- réduire
- conserver

une animation.

Ne pas laisser chaque composant interroger directement MediaQuery.

## Runtime Context

Évaluer une API telle que :

```dart
final accessibility = IuxAccessibility.of(context);
```

ou

```dart
context.iuxAccessibility
```

Une seule API principale doit être retenue.

# Documentation

Créer :

- docs/accessibility/runtime.md
- docs/accessibility/focus.md
- docs/accessibility/semantics.md
- docs/accessibility/touch-targets.md
- docs/accessibility/reduced-motion.md

Créer une ADR expliquant l'architecture du runtime.

# Tests

Ajouter des tests pour :

- profils
- focus
- touch targets
- semantics
- reduced motion
- BuildContext extensions
- copyWith
- égalité
- ThemeExtension si utilisé

Créer également des tests de contrat garantissant que les composants futurs pourront réutiliser cette infrastructure.

# Catalogue

Ajouter une section démontrant :

- focus visible
- navigation clavier
- text scaling
- reduced motion
- touch targets
- annonces
- profils d'accessibilité

Le catalogue reste démonstratif et ne crée aucun composant métier.

# Critères d'acceptation

La mission est terminée uniquement si :

- tous les services d'accessibilité sont mutualisés ;
- les composants futurs n'auront pas à réimplémenter ces mécanismes ;
- aucune logique n'est dupliquée ;
- flutter analyze réussit ;
- flutter test réussit ;
- le catalogue expose les fonctionnalités du runtime ;
- la documentation et les ADR sont complètes.

# Rapport final

Fournir :

1. Audit initial.
2. Architecture retenue.
3. API publiques.
4. Décisions importantes.
5. Tests.
6. Documentation.
7. Limites.
8. Prochaine mission recommandée : IUX-006 Motion & Feedback Engine.

# Instruction finale

Commencer par auditer le résultat réel des missions IUX-001 à IUX-004.

Ne créer aucun composant final.

Ne commencer aucune autre mission.


---

# Rapport final

## Audit initial

IUX-004 avait livré des thèmes résolus statiquement. Un thème statique ne peut
pas lire `MediaQuery` : la préférence plateforme restait non réconciliée et
`IuxMotionTheme.respectsPlatformPreference` en portait la trace. Cette mission
ferme cet écart.

## Architecture retenue

```text
Theme (ce que l'application a demandé)
        +                                → IuxAccessibility.of(context)
MediaQuery (ce que l'utilisateur a demandé)
        ↓
IuxMotionPolicy · IuxTapTarget · IuxFocusRing · IuxSemantics
```

Un seul point de réconciliation. Aucun composant ne lit `MediaQuery` pour une
préférence.

## API publiques

- `IuxAccessibility` — état résolu, avec `allowsNonEssentialMotion`,
  `minimumTouchTarget`, `prefersStackedLayout`
- `IuxMotionPolicy` / `IuxMotionRole` / `IuxMotionDecision` / `IuxMotionScale`
- `IuxTapTarget`, `IuxTouchTargetCheck`
- `IuxFocusRing`, `IuxFocusable`, `IuxFocus`
- `IuxSemantics`, `IuxAnnouncement`, `IuxReadableText`
- `IuxInterpolation` (extrait des fondations pour éviter une ambiguïté
  d'import avec `dart:ui`)

## Décisions importantes

1. **La plateforme peut renforcer une accommodation ; l'application ne peut
   pas l'affaiblir.** Un utilisateur ayant activé le contraste renforcé
   système l'a fait pour une raison ; une application demandant le contraste
   standard l'a fait sans le savoir. ADR-0005.
2. **Les régions live priment sur les annonces.** Android a déprécié
   `announceForAccessibility` : une annonce vide la file de parole de TalkBack
   et coupe l'utilisateur. `IuxAnnouncement` vérifie le support et rapporte si
   la livraison a eu lieu.
3. **L'anneau de focus réserve son espace en permanence**, pour que prendre le
   focus ne déplace jamais la mise en page.
4. **Le plancher tactile n'est pas contournable** : `minimumSize` ne peut que
   l'élever.
5. **Un contrôle non basculable n'annonce pas d'état sélectionné** —
   `selected` est nullable.

## Tests

126 tests dans le package, 8 dans le catalogue. Couvrent la réconciliation dans
les deux sens, les quatre préférences de mouvement, le plancher tactile, la
stabilité du focus, l'activation clavier, les sémantiques et le repli sans
thème IUX.

Un piège rencontré et corrigé : **un changement de thème s'anime**, et
`IuxAccessibilityTheme.lerp` conserve la valeur précédente sur la première
moitié de la transition. Les helpers de test attendent désormais la fin de
l'animation.

## Documentation

`docs/accessibility/` : runtime, focus, semantics, touch-targets,
reduced-motion. ADR-0005. Sept entrées `IUX-RUNTIME-*` dans l'evidence
registry, dont deux marquées `hypothesis`.

## Limites

- La plateforme n'expose ni densité, ni taille de cible, ni stimulation
  visuelle : ce sont des réglages applicatifs, et IUX ne prétend pas les
  détecter.
- `MediaQuery.highContrast` n'est pas fiable sur toutes les versions Android.
- Le seuil de 1,3x pour le reflow est une heuristique non validée.
- L'espacement entre cibles adjacentes n'est pas couvert (IUX-007).
- Aucune validation manuelle TalkBack ou Voice Access n'a été réalisée.
- Aucun lint n'empêche encore un composant de contourner le runtime.

## Prochaine mission recommandée

IUX-006 — Motion & Feedback Engine. Non commencée.
