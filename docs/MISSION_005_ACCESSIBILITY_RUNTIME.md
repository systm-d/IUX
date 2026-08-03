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
