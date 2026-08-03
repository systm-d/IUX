---
mission_id: IUX-003
title: Tokens sémantiques et rôles d’interface
priority: critical
status: completed
started_at: 2026-08-01
started_by: Codex
last_updated_at: 2026-08-01
completion_status: accepted
validation_status: passed
target_version: 0.1.0-dev.3
compatibility: additive
depends_on:
  - IUX-001
  - IUX-002
platform_priority: Android
package_name: iux_flutter
---

# IUX-003 — Tokens sémantiques et rôles d’interface

## 1. Références obligatoires

Avant toute action :

1. Lire intégralement `PROJECT_PROMPT.md`.
2. Lire intégralement `MISSION_001_REPOSITORY_FOUNDATION.md`.
3. Lire intégralement `MISSION_002_DESIGN_FOUNDATIONS.md`.
4. Vérifier que les missions IUX-001 et IUX-002 ont été terminées et validées.
5. Lire intégralement ce document.
6. Ne pas modifier le dépôt `d4-dark-ds`.
7. Ne pas créer encore de composants finaux.
8. Ne pas créer encore les thèmes accessibles complets.

En cas de conflit, `PROJECT_PROMPT.md` prévaut.

---

## 2. Contexte

Les fondations structurelles, interactives et d’accessibilité ont été créées lors de la mission IUX-002.

Cette mission doit introduire la couche sémantique qui séparera définitivement :

- la signification d’un élément ;
- son état ;
- sa représentation visuelle ;
- les couleurs primitives internes ;
- les futurs thèmes.

Les futurs composants IUX ne devront pas choisir directement une couleur pour exprimer une intention utilisateur.

Ils devront demander un rôle sémantique au thème.

Exemple :

```dart
IuxSemanticColors.of(context).actionPrimary
```

plutôt que :

```dart
Colors.blue
```

---

## 3. Objectif utilisateur

Garantir que les futurs composants restent compréhensibles et cohérents dans tous les thèmes, sans dépendre d’une couleur précise ni d’une identité visuelle.

L’utilisateur final doit pouvoir distinguer :

- une action principale ;
- une action secondaire ;
- une action destructive ;
- un succès ;
- un avertissement ;
- une erreur ;
- un état sélectionné ;
- un état désactivé ;
- un état focalisé ;

même lorsque le thème, le contraste ou la luminosité changent.

---

## 4. Objectifs de la mission

Cette mission doit :

1. Définir les rôles sémantiques de contenu.
2. Définir les rôles sémantiques de surface.
3. Définir les rôles sémantiques de bordure.
4. Définir les rôles sémantiques d’action.
5. Définir les rôles sémantiques de feedback.
6. Définir les rôles sémantiques d’état.
7. Séparer les couleurs primitives internes des tokens publics.
8. Créer une `ThemeExtension` ou architecture équivalente.
9. Définir les contrats de contraste attendus.
10. Documenter les usages corrects et incorrects.
11. Exposer uniquement l’API publique nécessaire.
12. Ajouter les tests et le catalogue correspondant.
13. Préparer les thèmes accessibles de la mission suivante.

---

## 5. Hors périmètre

Ne pas réaliser dans cette mission :

- de thème clair final ;
- de thème sombre final ;
- de thème contraste renforcé final ;
- de composant bouton ;
- de composant formulaire ;
- de composant feedback ;
- de navigation ;
- de pattern UX ;
- de palette de marque ;
- de thème sectoriel ;
- de génération automatique de palette ;
- de conformité WCAG globale revendiquée ;
- de publication sur `pub.dev`.

Une ou plusieurs palettes de test internes peuvent être utilisées uniquement pour valider la résolution des tokens, sans être présentées comme thèmes finaux.

---

## 6. Audit préalable obligatoire

Avant toute modification, inspecter :

- les fondations réellement créées en IUX-002 ;
- les types publics existants ;
- les extensions de thème éventuelles ;
- les conventions d’immutabilité ;
- les tests ;
- le catalogue ;
- la documentation ;
- les décisions d’architecture ;
- les éventuelles valeurs de couleur déjà introduites.

Présenter :

- ce qui peut être réutilisé ;
- ce qui doit rester indépendant ;
- les risques de duplication entre `ColorScheme` et IUX ;
- les risques de sur-modélisation ;
- les risques de noms trop liés à Material ;
- les risques de noms trop vagues.

---

## 7. Principes d’architecture

La couche sémantique doit rester entre :

```text
Foundations
    ↓
Semantic Tokens
    ↓
Themes
    ↓
Components
```

Les composants futurs dépendront des rôles sémantiques.

Les thèmes dépendront des couleurs primitives et produiront les rôles sémantiques.

Les fondations ne doivent pas dépendre des tokens sémantiques de couleur, sauf contrat d’interface justifié.

La couche sémantique ne doit pas dépendre des composants.

---

## 8. Structure cible

Structure indicative :

```text
packages/iux_flutter/lib/src/semantics/
├── colors/
│   ├── semantic_colors.dart
│   ├── content_colors.dart
│   ├── surface_colors.dart
│   ├── action_colors.dart
│   ├── feedback_colors.dart
│   └── state_colors.dart
├── roles/
├── contrast/
└── semantic_theme.dart
```

Cette structure peut être simplifiée si elle crée trop de fragmentation.

Éviter :

- un fichier géant ;
- une classe avec des dizaines de champs non regroupés ;
- des classes trop nombreuses pour quelques valeurs ;
- des imports circulaires ;
- des couleurs primitives publiques sans nécessité.

---

## 9. Couleurs primitives internes

Évaluer la création d’une couche interne de couleurs primitives.

Exemple conceptuel :

```dart
@internal
abstract final class IuxPrimitiveColors {
  static const neutral0 = Color(...);
  static const neutral10 = Color(...);
  static const blue40 = Color(...);
}
```

Contraintes :

- les noms primitifs peuvent décrire une teinte et un niveau ;
- ils ne doivent pas être utilisés directement par les composants ;
- ils ne doivent pas être exportés publiquement sauf justification forte ;
- ils ne doivent pas représenter une marque ;
- ils doivent servir uniquement à construire les futurs thèmes.

Ne pas créer une palette excessive.

Créer uniquement les primitives nécessaires à la démonstration et aux futurs thèmes accessibles.

---

## 10. Rôles de contenu

Créer des rôles couvrant au minimum :

```dart
contentPrimary
contentSecondary
contentTertiary
contentDisabled
contentInverse
contentOnAction
contentLink
```

Adapter si certains rôles sont redondants.

Documenter :

- le type de contenu concerné ;
- le niveau de priorité ;
- les cas où ne pas utiliser le rôle ;
- les attentes de contraste ;
- les relations entre rôles.

Ne pas utiliser un rôle secondaire pour masquer une information importante.

---

## 11. Rôles de surface

Créer des rôles couvrant au minimum :

```dart
surfaceBase
surfaceSubtle
surfaceRaised
surfaceOverlay
surfaceInteractive
surfaceSelected
surfaceDisabled
surfaceInverse
```

Adapter si nécessaire.

Les surfaces doivent permettre de représenter :

- l’arrière-plan principal ;
- un groupe ;
- une carte ;
- un élément élevé ;
- un overlay ;
- un élément sélectionné ;
- un élément désactivé.

Ne pas dépendre uniquement d’ombres pour distinguer les niveaux.

---

## 12. Rôles de bordure

Créer des rôles couvrant au minimum :

```dart
borderDefault
borderSubtle
borderStrong
borderInteractive
borderFocus
borderSelected
borderDisabled
borderError
```

Documenter :

- les usages ;
- les épaisseurs attendues, sans les coder dans la couleur ;
- le contraste ;
- les cas où une bordure doit compléter une autre indication.

Le focus ne doit jamais être confondu avec la sélection.

---

## 13. Rôles d’action

Créer des rôles permettant d’exprimer :

```dart
actionPrimary
actionPrimaryHover
actionPrimaryPressed
actionPrimaryDisabled

actionSecondary
actionSecondaryHover
actionSecondaryPressed
actionSecondaryDisabled

actionTertiary
actionTertiaryHover
actionTertiaryPressed
actionTertiaryDisabled

actionDestructive
actionDestructiveHover
actionDestructivePressed
actionDestructiveDisabled
```

Évaluer si un objet par intention est plus cohérent qu’une classe plate.

Exemple possible :

```dart
final class IuxActionColors {
  final Color foreground;
  final Color background;
  final Color border;
  final Color hover;
  final Color pressed;
  final Color disabledForeground;
  final Color disabledBackground;
}
```

Éviter de multiplier les champs sans structure.

Les états doivent rester compréhensibles sans couleur seule.

---

## 14. Rôles de feedback

Créer des rôles couvrant :

```dart
feedbackInfo
feedbackSuccess
feedbackWarning
feedbackError
```

Pour chaque rôle, prévoir éventuellement :

- contenu ;
- fond ;
- bordure ;
- icône ;
- accent.

Évaluer une structure comme :

```dart
IuxFeedbackColors.info
IuxFeedbackColors.success
IuxFeedbackColors.warning
IuxFeedbackColors.error
```

Les rôles ne doivent pas supposer qu’un succès est toujours vert ou qu’une erreur est toujours rouge.

Le thème décidera de la représentation.

---

## 15. Rôles d’état

Définir les besoins transverses pour :

- hovered ;
- focused ;
- pressed ;
- selected ;
- disabled ;
- loading ;
- dragged si pertinent ;
- activated si pertinent.

Éviter de doubler les états déjà présents dans les couleurs d’action.

Déterminer clairement :

- quels états sont globaux ;
- quels états appartiennent à une intention d’action ;
- quels états doivent être représentés par opacité ;
- quels états nécessitent une couleur dédiée ;
- quels états doivent être exprimés autrement que par la couleur.

Documenter la décision.

---

## 16. Structure publique recommandée

Évaluer une API publique telle que :

```dart
final class IuxSemanticColors extends ThemeExtension<IuxSemanticColors> {
  final IuxContentColors content;
  final IuxSurfaceColors surface;
  final IuxBorderColors border;
  final IuxActionColorSet actions;
  final IuxFeedbackColorSet feedback;
}
```

ou une architecture plus simple.

L’API doit être :

- lisible ;
- stable ;
- cohérente ;
- facilement extensible ;
- testable ;
- compatible avec `copyWith` et `lerp`.

Éviter un accès trop profond comme :

```dart
theme.colors.actions.primary.states.pressed.background
```

si cela nuit à l’usage.

Éviter aussi une classe plate contenant cinquante champs.

---

## 17. Intégration avec `ColorScheme`

Évaluer soigneusement la relation avec Flutter `ColorScheme`.

Le projet doit décider :

- quels rôles peuvent s’appuyer directement sur `ColorScheme` ;
- quels rôles IUX sont plus précis ;
- comment éviter deux sources de vérité ;
- comment les futurs thèmes généreront les deux objets ;
- comment les composants IUX liront les rôles IUX ;
- comment les composants Material intégrés resteront cohérents.

Documenter cette décision dans une ADR.

Créer au minimum :

```text
docs/decisions/ADR-0002-semantic-colors-and-color-scheme.md
```

L’ADR doit contenir :

- contexte ;
- décision ;
- alternatives ;
- conséquences ;
- risques ;
- statut.

---

## 18. Contrats de contraste

Créer une documentation explicite des contrats de contraste.

Distinguer au minimum :

- texte normal ;
- texte important ou grand ;
- icônes informatives ;
- contrôles interactifs ;
- focus ;
- contenu désactivé ;
- états non textuels.

Ne pas revendiquer de conformité globale.

Documenter plutôt :

- les paires qui devront être vérifiées ;
- les seuils visés ;
- les exceptions ;
- les limites des états disabled ;
- les cas nécessitant un test manuel.

Créer éventuellement un type de test interne pour mesurer le contraste.

Ne pas exposer une API publique de contraste prématurée sans besoin.

---

## 19. Daltonisme et dépendance à la couleur

Documenter une règle absolue :

> Aucun état important ne doit être communiqué uniquement par la couleur.

Pour chaque famille sémantique, documenter les compléments possibles :

- icône ;
- texte ;
- bordure ;
- motif ;
- forme ;
- position ;
- label ;
- sémantique TalkBack.

Cette mission ne crée pas les composants, mais doit définir le contrat que les composants devront respecter.

---

## 20. Immutabilité, copie et interpolation

Tous les objets sémantiques doivent être immuables.

Prévoir selon les besoins :

- constructeurs `const` ;
- champs `final` ;
- `copyWith` ;
- `lerp` ;
- égalité ;
- `hashCode`.

Les interpolations doivent être testées.

Ne pas introduire de génération de code sans justification.

---

## 21. Résolution depuis le contexte

Évaluer une API simple telle que :

```dart
IuxSemanticColors.of(context)
```

ou :

```dart
context.iuxColors
```

Ne pas imposer les deux sans nécessité.

L’API doit :

- produire un message clair si l’extension manque ;
- prévoir éventuellement une valeur de secours uniquement si cela ne masque pas une configuration invalide ;
- rester testable ;
- ne pas multiplier les extensions `BuildContext`.

Documenter la décision.

---

## 22. API publique

Mettre à jour le barrel public :

```text
packages/iux_flutter/lib/iux_flutter.dart
```

Exporter uniquement :

- les rôles sémantiques stables ;
- l’extension de thème publique ;
- les enums publics nécessaires ;
- les helpers publics justifiés.

Ne pas exporter :

- les couleurs primitives internes ;
- les outils de test internes ;
- les helpers temporaires ;
- les mappings de thème de démonstration.

---

## 23. Documentation Dart

Toute API publique doit documenter :

- son intention ;
- sa relation avec le thème ;
- les usages recommandés ;
- les usages interdits ;
- les exigences de contraste ;
- la distinction entre sémantique et apparence.

Exemple :

```dart
/// Couleur de contenu principale utilisée pour les informations essentielles.
///
/// Ne doit pas être utilisée pour les états désactivés ou les informations
/// secondaires.
```

---

## 24. Documentation conceptuelle

Créer au minimum :

```text
docs/foundations/semantic-tokens.md
docs/foundations/content-roles.md
docs/foundations/surface-roles.md
docs/foundations/action-roles.md
docs/foundations/feedback-roles.md
docs/accessibility/color-and-non-color-signals.md
docs/accessibility/contrast-contracts.md
```

Adapter la quantité de fichiers si certains contenus doivent être regroupés.

Chaque document doit inclure :

- intention ;
- rôles ;
- exemples ;
- contre-exemples ;
- règles ;
- limites ;
- niveau de preuve ;
- sources.

---

## 25. Evidence Registry

Ajouter des entrées pour :

- contraste du contenu ;
- contraste du focus ;
- non-dépendance à la couleur ;
- états disabled ;
- feedback success/warning/error ;
- différenciation focus/sélection ;
- surfaces et hiérarchie.

Chaque entrée doit préciser :

- identifiant ;
- niveau de preuve ;
- sources ;
- date de consultation ;
- limites ;
- statut de vérification.

Ne pas inventer de source.

---

## 26. Tests unitaires

Créer des tests pour :

### Structure

- tous les rôles obligatoires sont présents ;
- aucun champ public requis n’est null ;
- les objets sont immuables.

### Copie

- `copyWith` conserve les valeurs non modifiées ;
- les valeurs modifiées sont appliquées.

### Interpolation

- `lerp` entre deux ensembles fonctionne ;
- les bornes `0` et `1` sont exactes ;
- les valeurs intermédiaires sont cohérentes.

### Résolution

- la résolution depuis le thème fonctionne ;
- l’absence de l’extension produit le comportement documenté.

### Contraste

- les palettes de test respectent les contrats ciblés ;
- les paires critiques sont vérifiées.

### API

- le barrel public permet l’import ;
- les primitives internes ne sont pas exportées.

---

## 27. Tests de contrat

Ajouter des tests garantissant que :

- les composants futurs ne seront pas nécessaires à la couche sémantique ;
- la couche sémantique ne dépend pas du catalogue ;
- les couleurs primitives restent internes ;
- les rôles ne contiennent aucun nom de marque ;
- les rôles ne contiennent aucune teinte spécifique dans leur nom public ;
- `IuxSemanticColors` reste compatible avec `ThemeExtension`.

---

## 28. Catalogue

Mettre à jour le catalogue avec une section dédiée aux tokens sémantiques.

Présenter :

- contenu ;
- surfaces ;
- bordures ;
- actions ;
- feedback ;
- états ;
- paires de contraste ;
- différenciation sans couleur seule.

Le catalogue doit montrer les rôles, pas promouvoir une palette.

Utiliser deux jeux de démonstration neutres au maximum si nécessaire :

- un jeu clair de test ;
- un jeu sombre de test.

Les nommer explicitement comme démonstrations temporaires, pas comme thèmes finaux.

---

## 29. Outil de contraste

Évaluer la création d’un utilitaire interne ou de test pour calculer :

- luminance relative ;
- ratio de contraste ;
- conformité à un seuil donné.

L’outil doit rester dans :

```text
test/
```

ou :

```text
lib/src/testing/
```

uniquement si une future API de test publique est justifiée.

Ne pas exposer inutilement cet outil au runtime.

---

## 30. Dépendances

Ne pas ajouter de dépendance externe sauf nécessité réelle.

Le calcul du contraste peut être implémenté avec les API Flutter/Dart si raisonnable.

Toute dépendance doit être justifiée selon :

- maintenance ;
- licence ;
- poids ;
- précision ;
- alternatives ;
- utilité future.

---

## 31. Performance

Les tokens sémantiques doivent être légers.

Préférer :

- objets immuables ;
- constructeurs `const` ;
- accès direct ;
- aucune allocation répétée dans `build` ;
- résolution simple depuis le thème.

Éviter :

- calculs de contraste au runtime dans les composants ;
- génération dynamique complexe ;
- lookup par chaîne ;
- maps non typées ;
- réflexion.

---

## 32. Compatibilité

Cette mission est additive.

Ne pas casser :

- les API de IUX-001 ;
- les fondations de IUX-002 ;
- le catalogue ;
- les tests ;
- les conventions publiques.

Toute modification d’un contrat existant doit être justifiée et documentée.

---

## 33. Commandes de validation

Exécuter :

```bash
dart format .
flutter analyze
flutter test
```

Vérifier également le catalogue :

```bash
flutter run
```

ou au minimum :

```bash
flutter build apk --debug
```

Ne pas annoncer une réussite sans exécution réelle.

---

## 34. Livrables obligatoires

À la fin de cette mission, fournir :

- les objets de tokens sémantiques ;
- les rôles publics ;
- les couleurs primitives internes minimales ;
- l’intégration `ThemeExtension` ;
- les helpers de résolution ;
- les tests de contraste ;
- les tests de copie et interpolation ;
- la documentation ;
- l’ADR sur `ColorScheme` ;
- les entrées d’evidence registry ;
- la mise à jour du catalogue ;
- les résultats des validations ;
- la liste des fichiers créés et modifiés ;
- les limites et décisions différées.

---

## 35. Critères d’acceptation

La mission est terminée uniquement si :

- les rôles sémantiques sont publics et documentés ;
- les couleurs primitives restent internes ;
- aucun nom public ne dépend d’une teinte ou d’une marque ;
- les rôles couvrent contenu, surface, bordure, action et feedback ;
- les états principaux sont modélisés ;
- `copyWith` et `lerp` fonctionnent ;
- la résolution depuis le thème fonctionne ;
- les contrats de contraste sont documentés ;
- les tests de contraste ciblés passent ;
- la non-dépendance à la couleur est documentée ;
- le catalogue présente les rôles ;
- aucun composant final n’est créé ;
- aucun thème final n’est présenté comme terminé ;
- l’analyse statique et les tests passent.

---

## 36. Rapport final attendu

Répondre avec cette structure :

### Résumé

Décrire la couche sémantique ajoutée.

### Audit initial

Présenter l’état du projet avant modification.

### Architecture retenue

Expliquer la séparation primitives, rôles, thèmes et composants.

### API publique

Lister les types publics ajoutés.

### Rôles définis

Présenter les rôles de contenu, surface, bordure, action, feedback et état.

### Relation avec `ColorScheme`

Résumer la décision et l’ADR.

### Contraste et accessibilité

Présenter les contrats et validations.

### Documentation et evidence

Lister les documents et sources ajoutés.

### Fichiers créés et modifiés

Lister précisément les fichiers.

### Dépendances

Lister et justifier toute dépendance ajoutée.

### Commandes exécutées

Indiquer chaque commande et son résultat réel.

### Tests

Présenter les tests ajoutés et leurs résultats.

### Limites et décisions différées

Signaler notamment :

- les thèmes finaux non encore implémentés ;
- les composants non encore créés ;
- les sources restant à vérifier ;
- les rôles volontairement différés.

### Prochaine mission recommandée

Indiquer que la prochaine étape logique est la création des thèmes accessibles.

---

## 37. Instruction finale

Commence par auditer le résultat réel des missions IUX-001 et IUX-002.

Présente ensuite un plan court et concret.

Puis implémente la couche de tokens sémantiques.

Ne crée aucun composant final.

Ne finalise pas encore les thèmes accessibles.

