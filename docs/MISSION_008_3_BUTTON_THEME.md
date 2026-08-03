---
mission_id: IUX-008.3
epic: IUX-008
title: Button Theme
priority: critical
status: ready
---

# IUX-008.3 — Button Theme

## Références obligatoires

- PROJECT_PROMPT.md
- COMPONENT_STANDARD.md
- IUX-001 à IUX-008.2

## Objectif

Créer toute l'infrastructure de thème du futur système de boutons, sans créer le moindre widget.

## Livrables

Créer une architecture telle que :

- IuxButtonTheme
- IuxButtonThemeData
- IuxButtonTokens
- IuxButtonStateResolver
- IuxButtonColorResolver
- IuxButtonShapeResolver
- IuxButtonBorderResolver
- IuxButtonElevationResolver
- IuxButtonPaddingResolver
- IuxButtonIconResolver

Le découpage peut évoluer si une meilleure architecture est proposée.

## Contraintes

Ne pas créer :

- IuxButton
- IuxIconButton
- Renderer
- Motion spécifique
- Feedback spécifique
- Variantes visuelles

Aucun rendu Flutter ne doit être produit.

## États à résoudre

Prévoir la résolution pour :

- enabled
- disabled
- focused
- hovered
- pressed
- loading
- success
- error

Les états proviennent du modèle défini en IUX-008.2.

## Résolution

La résolution doit partir uniquement de :

Action Descriptor
→ Theme
→ Semantic Tokens
→ Render Model

Aucune couleur codée en dur.

## Variantes préparées

Préparer les résolveurs pour :

- filled
- outlined
- tonal
- text
- icon

Sans implémenter les widgets.

## ThemeExtension

Créer une ou plusieurs ThemeExtension adaptées.

Éviter une extension contenant des dizaines de champs.

## API

L'API publique doit rester compacte.

Le futur bouton ne devra jamais manipuler directement les tokens.

## Documentation

Créer :

- docs/buttons/theme.md
- docs/buttons/state-resolution.md
- docs/buttons/button-tokens.md

Créer une ADR expliquant les choix d'architecture.

## Tests

Ajouter des tests couvrant :

- résolution des états
- résolution des couleurs
- résolution des bordures
- résolution des formes
- copyWith
- égalité
- ThemeExtension
- valeurs par défaut

## Critères d'acceptation

Mission terminée uniquement si :

- aucun widget n'est créé ;
- aucun rendu n'est créé ;
- tous les états peuvent être résolus ;
- les variantes futures sont préparées ;
- aucune couleur n'est codée en dur ;
- flutter analyze réussit ;
- flutter test réussit.

## Rapport final

Présenter :

1. Audit.
2. Architecture retenue.
3. API publique.
4. Résolveurs créés.
5. Tests.
6. Documentation.
7. Limites.
8. Prochaine mission : IUX-008.4 — Button Core.

## Instruction finale

Implémenter uniquement le moteur de thème des boutons.

Ne créer aucun bouton.

