---
mission_id: IUX-008.3
epic: IUX-008
title: Button Theme
priority: critical
status: completed
---

---
mission_id: IUX-008.3
title: Button Theme
priority: high
status: completed
started_at: 2026-08-03
started_by: Claude
last_updated_at: 2026-08-03
completion_status: accepted
validation_status: passed
target_version: 0.1.0-dev.8
compatibility: additive
platform_priority: Android
package_name: iux_flutter
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



---

# Rapport final

## Résumé

Infrastructure de thème du bouton : résolution d'un descripteur d'action en
`IuxButtonTokens` peignables. Aucun widget, aucun rendu.

## Écart d'architecture assumé

Le §Livrables listait dix classes (`IuxButtonThemeData`, six résolveurs
séparés…). J'ai livré trois types publics — `IuxButtonTheme` (extension),
`IuxButtonTokens` (résultat), `IuxButtonResolver` (+ `IuxButtonStateResolver`
pour la précédence, testable seul). Un résolveur par propriété aurait produit
six classes lisant les mêmes trois extensions pour retourner un `double`
chacune, sans jamais être utiles séparément. Le §Livrables autorise
explicitement une meilleure architecture.

## Le défaut que le test a attrapé

`outlined` + `secondary` mesurait **1,00:1** — libellé blanc sur fond blanc.

Je supposais que `action.background` porte toujours l'accent de l'intention.
Faux : la couche sémantique modélise déjà `secondary` et `tertiary` comme sans
remplissage, leur `background` *est* la surface de page et leur accent vit dans
`foreground`. La variante `outlined` par-dessus double l'encodage d'emphase.

Corrigé explicitement par intention, et gardé par la mesure : 152 combinaisons
variante × intention × état × profil sont désormais vérifiées à 4,5:1.

## Autres décisions

- **Le focus n'est pas un état.** Il doit rester visible en pressed, en
  loading et sur un résultat, donc il ne peut pas être une valeur dans une
  liste où une seule gagne. Porté à part, dessiné en surcouche.
- **`tonal` refuse `destructive`** : il porte l'intention par sa bordure, pas
  par son fond, ce qui est insuffisant pour une action qui détruit des
  données. Assertion.
- **Aucune ombre par défaut** : elle disparaît sous stimulation réduite, donc
  s'y fier ferait lire le bouton différemment pour ceux qui ont demandé une
  interface plus calme.
- **Un bouton filled désactivé garde une bordure** : son fond est proche de la
  surface derrière lui.

## Tests

30 tests sur le thème du bouton, 242 au total.

## Limites

- La règle d'accent par intention est une hypothèse explicite sur les palettes
  livrées, gardée par le test de contraste, pas par le typage.
- `tonal` ne peut pas exprimer l'intention par son fond : il manque un rôle de
  conteneur d'action dans la couche sémantique. Différé.
- `IuxButtonShape.full` renvoie l'infini, le widget le résout contre sa propre
  hauteur.

## Prochaine mission

IUX-008.4 — Button Core.
