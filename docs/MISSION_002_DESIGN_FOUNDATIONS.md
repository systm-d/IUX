---
mission_id: IUX-002
title: Fondations de design, interaction et accessibilité
priority: critical
status: completed
started_at: 2026-08-01
started_by: Codex
last_updated_at: 2026-08-01
completion_status: accepted
validation_status: passed
target_version: 0.1.0-dev.2
compatibility: additive
depends_on:
  - IUX-001
platform_priority: Android
package_name: iux_flutter
---

# IUX-002 — Fondations de design, interaction et accessibilité

## 1. Références obligatoires

Avant toute action :

1. Lire intégralement `PROJECT_PROMPT.md`.
2. Lire intégralement `MISSION_001_REPOSITORY_FOUNDATION.md`.
3. Vérifier que la mission IUX-001 a été terminée et validée.
4. Lire intégralement ce document.
5. Considérer ce document comme la seule mission active.
6. Ne pas modifier le dépôt `d4-dark-ds`.
7. Ne pas commencer les composants finaux de la bibliothèque.

En cas de conflit, `PROJECT_PROMPT.md` prévaut.

---

## 2. Contexte

Le dépôt IUX et le package `iux_flutter` ont été initialisés lors de la mission IUX-001.

Cette mission doit créer les fondations réutilisables sur lesquelles reposeront les futurs thèmes, composants et patterns.

Ces fondations ne doivent représenter :

- ni une marque ;
- ni une identité visuelle ;
- ni un secteur métier ;
- ni un thème clair ou sombre spécifique ;
- ni un composant utilisateur final.

Elles doivent exprimer des règles structurelles, ergonomiques et interactives.

---

## 3. Objectif utilisateur

Garantir que les futurs composants IUX reposent sur des règles cohérentes concernant :

- l’espacement ;
- les tailles ;
- les zones tactiles ;
- la typographie ;
- les formes ;
- l’élévation ;
- la densité ;
- les mouvements ;
- le focus ;
- le feedback ;
- l’accessibilité.

L’utilisateur final doit bénéficier d’une interface plus prévisible, plus lisible et plus facile à manipuler, sans que chaque application réinvente ces règles.

---

## 4. Objectifs de la mission

Cette mission doit :

1. Définir les fondations de spacing.
2. Définir les fondations de sizing.
3. Définir les contraintes de tailles tactiles.
4. Définir les fondations de formes.
5. Définir les fondations d’élévation.
6. Définir les fondations typographiques.
7. Définir les fondations de densité.
8. Définir les fondations de mouvement.
9. Définir les fondations de focus.
10. Définir les fondations d’interaction.
11. Définir un profil d’accessibilité combinable.
12. Exposer les fondations dans l’API publique.
13. Ajouter la documentation et les tests associés.
14. Préparer les bases nécessaires à la mission suivante sur les tokens sémantiques.

---

## 5. Hors périmètre

Ne pas réaliser dans cette mission :

- de thème clair final ;
- de thème sombre final ;
- de palette de couleurs finale ;
- de tokens sémantiques de couleur complets ;
- de bouton ;
- de champ de formulaire ;
- de carte ;
- de dialogue ;
- de navigation ;
- de snackbar ;
- de pattern UX ;
- de système de formulaires ;
- de catalogue complet ;
- de conformité WCAG revendiquée ;
- de publication sur `pub.dev`.

Ne pas créer de composant visuel uniquement pour démontrer les fondations.

---

## 6. Audit préalable obligatoire

Avant toute modification, inspecter :

- la structure réelle du package `iux_flutter` ;
- les exports publics existants ;
- les conventions définies dans IUX-001 ;
- les fichiers d’analyse statique ;
- les tests existants ;
- le catalogue minimal ;
- les éventuelles contraintes SDK ;
- les décisions d’architecture déjà documentées.

Présenter :

- ce qui existe ;
- ce qui doit être conservé ;
- ce qui doit être ajouté ;
- les risques de sur-abstraction ;
- les risques de couplage avec Flutter Material.

Ne pas supposer que tous les dossiers prévus en IUX-001 existent réellement.

---

## 7. Principes d’architecture

Les fondations doivent être organisées par responsabilité.

Structure indicative :

```text
packages/iux_flutter/lib/src/foundations/
├── spacing/
├── sizing/
├── shape/
├── elevation/
├── typography/
├── density/
├── motion/
├── focus/
├── interaction/
└── accessibility/
```

Cette structure peut être simplifiée si elle crée trop de fichiers vides ou trop de granularité.

Éviter :

- une classe unique contenant toutes les fondations ;
- un fichier géant ;
- des dépendances circulaires ;
- des imports vers les composants ;
- des valeurs nommées selon leur apparence ;
- des valeurs nommées selon une marque.

---

## 8. Convention de nommage

Tous les types publics doivent utiliser le préfixe `Iux`.

Exemples possibles :

```dart
IuxSpacing
IuxSizing
IuxShape
IuxElevation
IuxTypography
IuxDensity
IuxMotion
IuxFocus
IuxInteraction
IuxAccessibilityProfile
```

Les noms définitifs doivent être justifiés.

Préférer des noms exprimant une intention.

Éviter :

```dart
IuxBlueSpacing
IuxDarkRadius
IuxNeonMotion
IuxPrettyElevation
IuxPremiumTypography
```

---

## 9. Fondations d’espacement

Créer une échelle d’espacement cohérente.

L’échelle doit :

- être limitée ;
- être prévisible ;
- faciliter la composition ;
- éviter les valeurs arbitraires ;
- fonctionner sur petits et grands écrans ;
- pouvoir être ajustée par densité si nécessaire.

Les tokens peuvent suivre une échelle nommée telle que :

```dart
IuxSpacing.xxs
IuxSpacing.xs
IuxSpacing.sm
IuxSpacing.md
IuxSpacing.lg
IuxSpacing.xl
IuxSpacing.xxl
```

Ne pas choisir les valeurs uniquement par préférence esthétique.

Documenter :

- l’intention de chaque valeur ;
- les usages recommandés ;
- les usages déconseillés ;
- la relation avec la densité.

---

## 10. Fondations de taille

Définir les tailles structurelles nécessaires aux futurs composants.

Cela peut inclure :

- tailles minimales interactives ;
- tailles d’icônes ;
- hauteurs minimales ;
- largeurs maximales de contenu ;
- contraintes de lisibilité ;
- dimensions de contrôle.

Éviter de figer trop tôt les dimensions de composants qui n’existent pas encore.

Créer uniquement les contrats réellement utiles.

---

## 11. Zones tactiles

Créer une fondation explicite pour les tailles tactiles minimales.

L’API doit permettre aux futurs composants de respecter une taille interactive minimale sans que chaque composant recopie la logique.

Évaluer une API telle que :

```dart
abstract final class IuxTouchTarget {
  static const double minimum = ...;
  static const double comfortable = ...;
}
```

ou une meilleure modélisation.

Contraintes :

- documenter la source de la valeur ;
- distinguer taille visuelle et taille interactive ;
- prévoir un profil plus confortable ;
- éviter de prétendre à une conformité universelle sans contexte.

---

## 12. Fondations de forme

Créer des rôles de forme sobres.

Les formes doivent exprimer un niveau de regroupement ou d’importance, pas une identité de marque.

Exemples possibles :

```dart
IuxShape.none
IuxShape.subtle
IuxShape.medium
IuxShape.prominent
IuxShape.full
```

Ne pas créer une multitude de rayons.

Documenter :

- l’usage ;
- les limites ;
- la relation entre forme et affordance ;
- les cas où une forme ne doit pas être utilisée comme seul indicateur.

---

## 13. Fondations d’élévation

Définir une abstraction minimale pour :

- absence d’élévation ;
- surface légèrement élevée ;
- surface modale ;
- élément temporaire.

L’élévation ne doit pas dépendre uniquement d’ombres.

Prévoir une documentation expliquant que :

- l’élévation peut être exprimée par ombre, contraste, bordure ou séparation ;
- le thème futur décidera de la représentation ;
- les composants ne doivent pas coder en dur les ombres.

---

## 14. Fondations typographiques

Créer une hiérarchie typographique sémantique.

Éviter de figer une police de marque.

Les rôles peuvent inclure :

- display ;
- headline ;
- title ;
- body ;
- label ;
- supporting text ;
- code ou données techniques si réellement nécessaire.

L’API doit permettre d’exprimer une intention comme :

```dart
IuxTypographyRole.body
IuxTypographyRole.label
IuxTypographyRole.supporting
```

Évaluer si les styles doivent être exposés comme tokens, enums ou objets de thème.

Contraintes :

- support du text scaling ;
- hauteurs de ligne lisibles ;
- poids raisonnables ;
- pas de taille trop petite par défaut ;
- pas d’hypothèse sur une police embarquée ;
- support des langues à textes longs.

---

## 15. Fondations de densité

Créer un modèle de densité combinable.

Prévoir au minimum :

```dart
enum IuxDensity {
  compact,
  standard,
  comfortable,
}
```

ou une API équivalente.

La densité doit pouvoir affecter :

- espacements ;
- hauteurs minimales ;
- paddings ;
- tailles tactiles ;
- éventuellement taille de texte, uniquement si justifié.

Le mode compact ne doit jamais réduire les cibles tactiles sous le minimum retenu.

---

## 16. Fondations de mouvement

Créer une architecture de mouvement cohérente.

Elle doit distinguer :

- durée instantanée ;
- courte ;
- standard ;
- longue ;
- mouvement désactivé ou réduit.

Prévoir des courbes ou rôles tels que :

- entrée ;
- sortie ;
- changement d’état ;
- déplacement ;
- feedback.

Ne pas définir une animation visuelle finale.

Ne pas ajouter de dépendance d’animation externe.

Le système doit pouvoir respecter :

- `MediaQuery.disableAnimations` ;
- une préférence IUX de mouvement réduit ;
- un mode sans mouvement non essentiel.

---

## 17. Fondations de focus

Créer des contrats pour le focus visible.

Ils doivent prévoir :

- épaisseur minimale ;
- espace autour de l’élément ;
- contraste ;
- état focus visible ;
- navigation clavier ou périphérique externe.

Ne pas coder une couleur de focus définitive.

Créer des rôles structurels qui seront reliés aux tokens sémantiques dans la mission suivante.

---

## 18. Fondations d’interaction

Définir les principaux états interactifs :

```dart
enum IuxInteractionState {
  idle,
  hovered,
  focused,
  pressed,
  selected,
  disabled,
  loading,
}
```

Adapter si cette modélisation mélange trop de dimensions.

Il peut être préférable de séparer :

- l’état d’interaction ;
- l’état de sélection ;
- l’état de disponibilité ;
- l’état asynchrone.

Ne pas créer un enum unique uniquement pour simplifier artificiellement.

Documenter la décision retenue.

---

## 19. Profil d’accessibilité

Créer un profil combinable pour les préférences ou besoins transverses.

Exemple d’intention :

```dart
const IuxAccessibilityProfile(
  contrast: IuxContrast.standard,
  motion: IuxMotionPreference.system,
  density: IuxDensity.standard,
  touchTarget: IuxTouchTargetPreference.standard,
)
```

Le profil doit rester simple.

Ne pas prétendre détecter un handicap.

Ne pas catégoriser les utilisateurs par diagnostic.

Exprimer uniquement des préférences d’interface.

Évaluer au minimum :

- contraste ;
- mouvement ;
- densité ;
- taille tactile ;
- niveau de stimulation visuelle.

---

## 20. Intégration avec Flutter

Les fondations doivent rester compatibles avec Flutter.

Évaluer l’utilisation de :

- classes immuables ;
- enums ;
- `ThemeExtension` ;
- `BuildContext` extensions ;
- objets de configuration ;
- `InheritedWidget` uniquement si nécessaire.

Ne pas utiliser `BuildContext` dans les fondations qui peuvent rester pures.

Séparer :

1. les données pures ;
2. leur résolution depuis un thème ;
3. leur usage futur dans les composants.

---

## 21. API publique

Mettre à jour :

```text
packages/iux_flutter/lib/iux_flutter.dart
```

Exporter uniquement les fondations publiques et stables de cette mission.

Ne pas exporter :

- des helpers internes ;
- des implémentations temporaires ;
- des fichiers de test ;
- des détails de résolution ;
- des classes dont le contrat n’est pas défini.

Créer éventuellement des barrels internes si cela améliore la lisibilité, sans multiplier les couches inutiles.

---

## 22. Immutabilité et égalité

Les objets de configuration doivent être immuables.

Utiliser :

- champs `final` ;
- constructeurs `const` lorsque possible ;
- `copyWith` lorsque nécessaire ;
- `lerp` pour les extensions de thème ;
- égalité cohérente lorsque le type l’exige.

Ne pas ajouter de package d’égalité externe sans justification.

---

## 23. Documentation Dart

Toute API publique doit documenter :

- son intention ;
- son usage ;
- ses limites ;
- son interaction avec l’accessibilité ;
- son comportement avec la densité ou le mouvement ;
- les valeurs par défaut.

La documentation ne doit pas seulement répéter le nom du type.

Mauvais :

```dart
/// Spacing medium.
static const md = 16;
```

Meilleur :

```dart
/// Espacement standard entre deux éléments appartenant au même groupe.
```

---

## 24. Documentation conceptuelle

Créer au minimum :

```text
docs/foundations/overview.md
docs/foundations/spacing.md
docs/foundations/sizing-and-touch-targets.md
docs/foundations/typography.md
docs/foundations/density.md
docs/foundations/motion.md
docs/foundations/focus-and-interaction.md
docs/accessibility/profiles.md
```

Adapter la quantité de fichiers si certains contenus sont trop courts.

Chaque document doit présenter :

- intention ;
- règles ;
- API ;
- exemples ;
- limites ;
- niveau de preuve ;
- sources ou références à valider.

---

## 25. Evidence Registry initial

Créer ou enrichir un registre des décisions.

Format possible :

```text
docs/evidence/
```

ou :

```text
research/evidence/
```

Ajouter au minimum les décisions liées à :

- tailles tactiles ;
- mouvement réduit ;
- texte agrandi ;
- focus visible ;
- densité confortable.

Chaque entrée doit inclure :

- identifiant ;
- principe ;
- niveau de preuve ;
- source ;
- date de consultation ;
- limites ;
- composants futurs concernés.

Ne pas inventer de source.

Si une source n’a pas été vérifiée, marquer explicitement :

```text
status: to_verify
```

---

## 26. Tests attendus

Créer des tests pour :

### Espacement

- valeurs ordonnées ;
- absence de doublons involontaires ;
- cohérence de l’échelle.

### Taille

- minimum tactile ;
- mode confortable ;
- invariants.

### Formes

- valeurs ordonnées ;
- absence de valeur négative.

### Typographie

- rôles disponibles ;
- support de la copie ou résolution ;
- absence de police de marque codée en dur.

### Densité

- transformation cohérente des valeurs ;
- respect du minimum tactile.

### Mouvement

- préférence système ;
- réduction ;
- suppression des animations non essentielles ;
- interpolation si `ThemeExtension`.

### Focus

- valeurs non nulles ;
- épaisseur et espace valides.

### Accessibilité

- profils par défaut ;
- profils copiables ;
- combinaison des préférences.

---

## 27. Tests de contrat

Ajouter des tests garantissant que :

- aucune fondation publique n’importe un composant ;
- les fondations ne dépendent pas d’un thème de marque ;
- le package reste importable via le barrel public ;
- les types publics sont documentés si l’analyse statique le permet ;
- les objets sont immuables.

Éviter les tests fragiles basés sur les chemins internes si aucune meilleure approche n’existe.

---

## 28. Catalogue

Mettre à jour le catalogue uniquement pour documenter les fondations.

Créer un écran ou une section affichant :

- l’échelle d’espacement ;
- les tailles tactiles ;
- les formes ;
- la hiérarchie typographique ;
- les densités ;
- les préférences de mouvement ;
- les états de focus structurels.

Le catalogue doit rester une démonstration technique.

Ne pas présenter ces éléments comme des composants finaux.

Ne pas ajouter d’esthétique forte.

---

## 29. Dépendances

Ne pas ajouter de dépendance externe sauf nécessité réelle.

Les fondations doivent idéalement utiliser uniquement Flutter et Dart.

Toute nouvelle dépendance doit être justifiée selon :

- bénéfice ;
- maintenance ;
- licence ;
- poids ;
- alternatives ;
- risque de verrouillage.

---

## 30. Performance

Les fondations doivent être légères.

Éviter :

- allocations répétées ;
- résolution complexe dans `build` ;
- objets mutables ;
- calculs coûteux ;
- dépendance à des animations permanentes.

Préférer :

- constantes ;
- objets immuables ;
- valeurs pré-calculées ;
- résolutions simples.

---

## 31. Compatibilité

Cette mission est additive.

Ne pas casser :

- le point d’entrée public ;
- le catalogue minimal ;
- les tests de IUX-001 ;
- les commandes documentées.

Toute modification d’un contrat créé en IUX-001 doit être justifiée.

---

## 32. Commandes de validation

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

Ne pas annoncer une réussite sans avoir exécuté les commandes.

---

## 33. Livrables obligatoires

À la fin de cette mission, fournir :

- les classes de fondation ;
- les exports publics ;
- le profil d’accessibilité ;
- les tests ;
- la documentation ;
- les entrées d’evidence registry ;
- la mise à jour du catalogue ;
- les résultats des validations ;
- la liste des fichiers créés et modifiés ;
- les décisions d’architecture ;
- les limites et sujets différés.

---

## 34. Critères d’acceptation

La mission est terminée uniquement si :

- aucune identité de marque n’est présente ;
- aucun composant final n’est créé ;
- les fondations sont publiques et documentées ;
- les fondations sont immuables ;
- les tailles tactiles sont modélisées ;
- la densité ne peut pas réduire les cibles sous le minimum retenu ;
- le mouvement réduit est prévu ;
- le focus visible est modélisé ;
- les préférences d’accessibilité sont combinables ;
- les tests passent ;
- le catalogue présente les fondations ;
- l’analyse statique ne retourne aucune erreur.

---

## 35. Rapport final attendu

Répondre avec cette structure :

### Résumé

Décrire les fondations ajoutées.

### Audit initial

Présenter l’état du projet avant modification.

### Architecture retenue

Expliquer les responsabilités et dépendances.

### API publique

Lister les types publics ajoutés.

### Valeurs et décisions

Présenter les échelles et justifier leur intention.

### Accessibilité

Expliquer les profils et garanties introduites.

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

- les couleurs sémantiques non encore implémentées ;
- les thèmes non encore implémentés ;
- les composants non encore créés ;
- les sources restant à vérifier.

### Prochaine mission recommandée

Indiquer que la prochaine étape logique est la création des tokens sémantiques, sans la commencer.

---

## 36. Instruction finale

Commence par auditer le résultat réel de IUX-001.

Présente ensuite un plan court et concret.

Puis implémente les fondations de cette mission.

Ne crée aucun composant final.

Ne commence pas la mission suivante.
