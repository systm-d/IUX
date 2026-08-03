---
mission_id: IUX-004
title: Moteur de thèmes accessibles et profils combinables
priority: critical
status: completed
started_at: 2026-08-03
started_by: Claude
last_updated_at: 2026-08-03
completion_status: accepted
validation_status: passed
target_version: 0.1.0-dev.4
compatibility: additive
depends_on:
  - IUX-001
  - IUX-002
  - IUX-003
platform_priority: Android
package_name: iux_flutter
---

# IUX-004 — Moteur de thèmes accessibles et profils combinables

## 1. Références obligatoires

Avant toute action :

1. Lire intégralement `PROJECT_PROMPT.md`.
2. Lire intégralement `MISSION_001_REPOSITORY_FOUNDATION.md`.
3. Lire intégralement `MISSION_002_DESIGN_FOUNDATIONS.md`.
4. Lire intégralement `MISSION_003_SEMANTIC_TOKENS.md`.
5. Vérifier que les missions IUX-001, IUX-002 et IUX-003 ont été terminées et validées.
6. Lire intégralement ce document.
7. Considérer ce document comme la seule mission active.
8. Ne pas modifier le dépôt `d4-dark-ds`.
9. Ne pas créer encore les composants finaux de la bibliothèque.

En cas de conflit, `PROJECT_PROMPT.md` prévaut.

---

## 2. Contexte

Les missions précédentes ont établi :

- l’architecture du dépôt ;
- les fondations de design, d’interaction et d’accessibilité ;
- les rôles sémantiques ;
- les contrats de contraste ;
- les couleurs primitives internes minimales.

Cette mission doit maintenant créer le moteur de thèmes d’IUX.

Ce moteur doit permettre aux futurs composants d’obtenir une représentation cohérente de leurs rôles sémantiques sans connaître :

- une palette particulière ;
- une marque ;
- un secteur métier ;
- un style graphique ;
- un niveau de contraste codé en dur ;
- une préférence de mouvement codée en dur ;
- une densité codée en dur.

Les thèmes fournis par IUX doivent être pensés pour des conditions d’usage, et non comme des univers graphiques.

---

## 3. Objectif utilisateur

Permettre à une application Flutter de proposer une expérience :

- claire ou sombre ;
- avec contraste standard ou renforcé ;
- avec mouvement standard, réduit ou désactivé ;
- avec densité compacte, standard ou confortable ;
- avec zones tactiles standard ou renforcées ;
- avec niveau de stimulation visuelle standard ou réduit ;

sans modifier les composants et sans dupliquer les thèmes.

L’utilisateur final doit bénéficier d’une interface adaptée à ses préférences ou à son contexte d’utilisation, tout en conservant une hiérarchie et des comportements cohérents.

---

## 4. Objectifs de la mission

Cette mission doit :

1. Définir l’architecture publique du moteur de thèmes IUX.
2. Créer une représentation immuable de la configuration d’un thème.
3. Créer des profils combinables.
4. Implémenter un thème clair accessible.
5. Implémenter un thème sombre accessible.
6. Implémenter un contraste renforcé combinable.
7. Implémenter le mouvement réduit combinable.
8. Implémenter la densité configurable.
9. Implémenter des tailles tactiles configurables.
10. Implémenter un niveau de stimulation visuelle configurable.
11. Générer un `ThemeData` Material cohérent.
12. Garantir la présence des `ThemeExtension` IUX.
13. Fournir une résolution simple depuis `BuildContext`.
14. Ajouter des tests de contraste, de copie, d’interpolation et de combinaison.
15. Documenter la création future de thèmes de marque.
16. Mettre à jour le catalogue.
17. Préparer la mission suivante sur l’infrastructure d’accessibilité et les composants.

---

## 5. Hors périmètre

Ne pas réaliser dans cette mission :

- de bouton final ;
- de champ de formulaire ;
- de carte ;
- de navigation ;
- de snackbar ;
- de pattern UX ;
- de thème de marque ;
- de thème TRON ;
- de thème sectoriel final ;
- de générateur automatique de thème ;
- de personnalisation visuelle libre par composant ;
- de moteur de design token distant ;
- de synchronisation avec Figma ;
- de publication sur `pub.dev`.

Les écrans du catalogue peuvent utiliser des widgets Flutter standards uniquement pour visualiser les thèmes.

---

## 6. Audit préalable obligatoire

Avant toute modification, inspecter :

- les fondations réelles de IUX-002 ;
- les tokens sémantiques réels de IUX-003 ;
- les `ThemeExtension` existantes ;
- les exports publics ;
- le catalogue ;
- les tests ;
- la documentation ;
- les ADR ;
- les contraintes SDK ;
- la relation actuelle avec `ThemeData` et `ColorScheme`.

Présenter :

- les types réutilisables ;
- les types à compléter ;
- les risques de duplication ;
- les risques de classe monolithique ;
- les risques de profils impossibles à combiner ;
- les risques de divergence entre Material et IUX ;
- les risques de valeurs par défaut incohérentes.

---

## 7. Principes d’architecture

Le moteur de thèmes doit respecter cette direction :

```text
Foundations
    ↓
Semantic Tokens
    ↓
Iux Theme Configuration
    ↓
Resolved Iux Theme
    ↓
Material ThemeData
    ↓
Components
```

Les composants futurs doivent lire les rôles résolus.

Ils ne doivent pas reconstruire un thème.

Ils ne doivent pas connaître les couleurs primitives.

Le moteur de thèmes doit être la source de vérité pour :

- couleurs sémantiques ;
- typographie ;
- spacing ;
- sizing ;
- formes ;
- élévation ;
- densité ;
- mouvement ;
- focus ;
- accessibilité ;
- interactions.

---

## 8. Séparer configuration et résolution

Distinguer clairement :

1. la configuration demandée ;
2. les valeurs effectivement résolues ;
3. le `ThemeData` Flutter généré.

Exemple conceptuel :

```dart
final configuration = IuxThemeConfiguration(
  brightness: Brightness.dark,
  contrast: IuxContrast.high,
  density: IuxDensity.comfortable,
  motion: IuxMotionPreference.reduced,
);

final resolved = IuxTheme.resolve(configuration);

final materialTheme = resolved.materialTheme;
```

L’API définitive peut être différente, mais la séparation des responsabilités doit rester claire.

---

## 9. API publique attendue

Évaluer une API proche de :

```dart
MaterialApp(
  theme: IuxTheme.light(),
  darkTheme: IuxTheme.dark(),
  themeMode: ThemeMode.system,
)
```

avec profils optionnels :

```dart
MaterialApp(
  theme: IuxTheme.light(
    profile: const IuxAccessibilityProfile(
      contrast: IuxContrast.high,
      motion: IuxMotionPreference.reduced,
      density: IuxDensity.comfortable,
      touchTarget: IuxTouchTargetPreference.comfortable,
    ),
  ),
)
```

Évaluer également une API de bas niveau :

```dart
final theme = IuxTheme.fromConfiguration(
  const IuxThemeConfiguration(...),
);
```

L’API doit rester simple pour 80 % des usages.

---

## 10. Types publics à évaluer

Évaluer la pertinence de types tels que :

```dart
IuxTheme
IuxThemeConfiguration
IuxResolvedTheme
IuxThemeMode
IuxContrast
IuxDensity
IuxMotionPreference
IuxTouchTargetPreference
IuxVisualStimulation
IuxAccessibilityProfile
```

Ne pas multiplier les types si certains existent déjà depuis IUX-002.

Réutiliser ou faire évoluer les types existants plutôt que les dupliquer.

Toute évolution d’un type existant doit rester additive ou être explicitement documentée.

---

## 11. Configuration de thème

La configuration doit pouvoir exprimer au minimum :

```dart
brightness
contrast
density
motion
touchTarget
visualStimulation
```

Évaluer aussi :

```dart
textScalePolicy
focusVisibility
platformAdaptation
```

Ne pas ajouter de paramètre sans usage concret.

La configuration doit être :

- immuable ;
- `const` lorsque possible ;
- copiable ;
- comparable si pertinent ;
- facile à sérialiser mentalement ;
- indépendante de `BuildContext`.

---

## 12. Profil d’accessibilité combinable

Le profil ne doit pas remplacer la configuration complète.

Il doit regrouper les préférences transverses.

Exemple :

```dart
const IuxAccessibilityProfile.standard()
const IuxAccessibilityProfile.comfortable()
const IuxAccessibilityProfile.reducedMotion()
```

Évaluer si des constructeurs nommés apportent une valeur.

Éviter des profils prétendant représenter un diagnostic ou une population.

Mauvais :

```dart
IuxAccessibilityProfile.adhd()
IuxAccessibilityProfile.autism()
```

Bon :

```dart
IuxAccessibilityProfile(
  motion: IuxMotionPreference.reduced,
  density: IuxDensity.comfortable,
  visualStimulation: IuxVisualStimulation.reduced,
)
```

---

## 13. Luminosité

Implémenter au minimum :

```dart
Brightness.light
Brightness.dark
```

Le thème clair doit :

- offrir une hiérarchie lisible ;
- éviter les gris trop faibles ;
- conserver des surfaces distinguables ;
- fournir un focus visible ;
- permettre une utilisation prolongée.

Le thème sombre doit :

- éviter le noir pur systématique ;
- éviter le texte blanc pur systématique ;
- distinguer clairement les surfaces ;
- limiter les contrastes agressifs ;
- rester lisible dans des environnements sombres ;
- ne pas utiliser de glow ou de bordures lumineuses décoratives.

---

## 14. Contraste

Prévoir au minimum :

```dart
enum IuxContrast {
  standard,
  high,
}
```

Le contraste renforcé doit être combinable avec clair ou sombre.

Il peut ajuster :

- contenu ;
- bordures ;
- focus ;
- surfaces ;
- états sélectionnés ;
- états désactivés ;
- séparateurs ;
- composants interactifs futurs.

Le contraste renforcé ne doit pas seulement augmenter toutes les valeurs arbitrairement.

Documenter précisément ce qui change.

---

## 15. Densité

Le moteur doit intégrer la densité définie en IUX-002.

Prévoir :

```dart
compact
standard
comfortable
```

Contraintes :

- compact ne doit pas réduire les cibles tactiles sous le minimum ;
- comfortable peut augmenter spacing et zones tactiles ;
- la densité ne doit pas casser le text scaling ;
- les composants futurs doivent lire la densité depuis le thème.

---

## 16. Mouvement

Prévoir au minimum :

```dart
system
standard
reduced
none
```

Évaluer si `none` est nécessaire ou si `reduced` suffit.

Le moteur doit tenir compte de :

- `MediaQuery.disableAnimations` ;
- la préférence IUX ;
- les animations essentielles ;
- les animations décoratives ;
- les transitions de changement d’état.

Le thème ne peut pas lire directement `MediaQuery` lors de sa construction statique.

Documenter la séparation entre :

- configuration du thème ;
- adaptation au contexte ;
- comportement du composant.

---

## 17. Taille tactile

Prévoir au minimum :

```dart
standard
comfortable
```

Le thème doit exposer :

- taille tactile minimale ;
- taille tactile confortable ;
- spacing autour des éléments ;
- contraintes de densité.

Les composants futurs doivent pouvoir lire ces valeurs sans recalculer les règles.

---

## 18. Stimulation visuelle

Évaluer un enum tel que :

```dart
enum IuxVisualStimulation {
  standard,
  reduced,
}
```

Le mode réduit peut influencer :

- saturation ;
- contraste local excessif ;
- nombre d’effets décoratifs ;
- mouvement ;
- intensité des feedbacks ;
- élévation ;
- transitions.

Il ne doit pas rendre l’interface moins lisible.

Documenter les limites de ce concept.

Ne pas prétendre qu’il convient à tous les profils cognitifs.

---

## 19. Typographie

Le moteur doit résoudre la typographie à partir des fondations.

Contraintes :

- aucune police de marque obligatoire ;
- utilisation de polices système par défaut si aucune police n’est fournie ;
- hiérarchie sémantique ;
- text scaling respecté ;
- tailles minimales lisibles ;
- line heights cohérentes ;
- support des langues longues.

Évaluer si le thème doit permettre une personnalisation globale de famille typographique sans casser les rôles.

---

## 20. Formes et élévation

Le moteur doit résoudre :

- formes ;
- bordures ;
- élévation ;
- séparation des surfaces.

Le thème sombre et le contraste renforcé peuvent représenter l’élévation différemment.

Ne pas supposer qu’une ombre suffit.

Le système doit pouvoir utiliser :

- contraste de surface ;
- bordure ;
- ombre ;
- espace ;
- séparation.

---

## 21. Focus

Le thème doit fournir une représentation visible du focus.

Il doit résoudre :

- couleur ;
- épaisseur ;
- espace ;
- forme ;
- contraste.

Le focus doit rester distinct de :

- sélection ;
- erreur ;
- activation ;
- hover.

Le contraste renforcé doit accentuer le focus.

---

## 22. Intégration avec `ThemeData`

Le moteur doit générer un `ThemeData` cohérent.

Configurer au minimum :

- `brightness` ;
- `colorScheme` ;
- `textTheme` ;
- `scaffoldBackgroundColor` ;
- `focusColor` si pertinent ;
- `disabledColor` si pertinent ;
- `dividerTheme` ;
- `iconTheme` ;
- `appBarTheme` minimal ;
- `inputDecorationTheme` minimal ;
- thèmes Material nécessaires à la cohérence.

Ne pas surconfigurer tous les composants Material avant qu’IUX ne les implémente.

Éviter de créer prématurément des styles détaillés pour :

- buttons ;
- chips ;
- cards ;
- dialogs ;
- navigation ;

si cela appartient à de futures missions.

---

## 23. Material 3

Le thème doit être compatible avec Material 3.

Évaluer :

```dart
useMaterial3: true
```

Documenter :

- ce qui est délégué à Material ;
- ce qui est redéfini par IUX ;
- comment éviter les divergences ;
- comment les futurs composants IUX utiliseront Material sans en dépendre sémantiquement.

---

## 24. `ColorScheme`

Utiliser la décision de l’ADR de IUX-003.

Le moteur doit générer un `ColorScheme` cohérent à partir des rôles sémantiques.

Éviter deux sources de vérité.

Documenter le mapping entre :

- rôles IUX ;
- champs `ColorScheme` ;
- usages Material.

Ajouter des tests garantissant la cohérence du mapping.

---

## 25. `ThemeExtension`

Toutes les fondations nécessaires aux composants futurs doivent être accessibles depuis le thème.

Évaluer plusieurs extensions spécialisées :

```dart
IuxSemanticColors
IuxTypographyTheme
IuxMotionTheme
IuxInteractionTheme
IuxAccessibilityTheme
IuxShapeTheme
IuxElevationTheme
```

Éviter une extension monolithique.

Éviter aussi un trop grand nombre d’extensions minuscules.

Justifier le découpage.

---

## 26. Résolution depuis `BuildContext`

Fournir une API cohérente.

Exemples possibles :

```dart
IuxTheme.of(context)
context.iuxTheme
context.iuxColors
```

Choisir une approche principale.

Ne pas multiplier les raccourcis.

L’absence d’une extension IUX doit produire :

- un message clair en développement ;
- un comportement documenté ;
- aucune erreur silencieuse difficile à diagnostiquer.

---

## 27. Personnalisation

Le moteur doit permettre une personnalisation contrôlée.

Prévoir au minimum :

- override typographique global ;
- override de profils ;
- extension de thème ;
- remplacement de certains tokens sémantiques.

Éviter une API permettant de modifier arbitrairement chaque détail de chaque composant.

La personnalisation doit rester au niveau du thème.

---

## 28. Thèmes de marque futurs

Documenter comment une marque pourra créer un thème sans modifier les composants.

Exemple conceptuel :

```dart
final brandTheme = IuxTheme.fromConfiguration(
  configuration,
  semanticColors: brandSemanticColors,
  typography: brandTypography,
);
```

Cette mission ne doit pas créer de thème de marque.

Créer une documentation dédiée :

```text
docs/themes/brand-theme-guidelines.md
```

Elle doit préciser :

- ce qui peut être personnalisé ;
- ce qui ne doit pas être contourné ;
- les contrats d’accessibilité ;
- les tests nécessaires ;
- la responsabilité de la marque.

---

## 29. API de construction

Évaluer des constructeurs simples :

```dart
IuxTheme.light()
IuxTheme.dark()
IuxTheme.highContrastLight()
IuxTheme.highContrastDark()
```

ou une API combinable :

```dart
IuxTheme(
  brightness: Brightness.light,
  profile: ...
)
```

Éviter la multiplication de constructeurs si une configuration combinable est plus claire.

Le cas courant doit rester court.

---

## 30. Résultat public

Le résultat principal doit idéalement être directement utilisable par `MaterialApp`.

Exemple :

```dart
MaterialApp(
  theme: IuxTheme.light(),
  darkTheme: IuxTheme.dark(),
)
```

Si `IuxTheme.light()` retourne un objet autre que `ThemeData`, fournir une API ergonomique :

```dart
IuxTheme.light().material
```

Justifier ce choix.

---

## 31. Immutabilité, copie et interpolation

Les objets de thème doivent être immuables.

Prévoir :

- constructeurs `const` lorsque possible ;
- `copyWith` ;
- `lerp` ;
- égalité ;
- `hashCode` ;
- transitions cohérentes.

Tester :

- interpolation clair vers sombre ;
- interpolation contraste standard vers élevé ;
- interpolation density ;
- interpolation motion si pertinente ;
- valeurs aux bornes.

---

## 32. Détection système

Le moteur doit documenter ce qui peut être détecté automatiquement :

- brightness système ;
- disable animations ;
- text scale ;
- high contrast si exposé par Flutter ;
- platform brightness ;
- accessibility features.

Ne pas prétendre détecter ce que Flutter ou Android n’expose pas.

Prévoir une stratégie où :

- `ThemeMode.system` gère la luminosité ;
- les composants consultent `MediaQuery` pour certaines préférences ;
- le profil IUX sert d’override explicite.

---

## 33. Fallbacks

Définir des fallbacks sûrs.

Exemples :

- profil standard ;
- densité standard ;
- mouvement système ;
- contraste standard ;
- zones tactiles standard.

Ne pas masquer l’absence d’une configuration critique.

Documenter les cas où un fallback est acceptable.

---

## 34. Documentation Dart

Toute API publique doit documenter :

- son intention ;
- ses valeurs par défaut ;
- sa relation avec Material ;
- sa relation avec l’accessibilité ;
- ses limites ;
- ses effets sur les composants futurs.

---

## 35. Documentation conceptuelle

Créer au minimum :

```text
docs/themes/overview.md
docs/themes/light-and-dark.md
docs/themes/contrast.md
docs/themes/density.md
docs/themes/motion.md
docs/themes/touch-targets.md
docs/themes/visual-stimulation.md
docs/themes/customization.md
docs/themes/brand-theme-guidelines.md
docs/accessibility/theme-preferences.md
```

Adapter le regroupement si nécessaire.

Chaque document doit inclure :

- intention ;
- API ;
- règles ;
- exemples ;
- contre-exemples ;
- limites ;
- niveau de preuve ;
- sources.

---

## 36. ADR

Créer au minimum :

```text
docs/decisions/ADR-0003-theme-engine.md
docs/decisions/ADR-0004-composable-accessibility-profiles.md
```

Chaque ADR doit contenir :

- contexte ;
- décision ;
- alternatives ;
- conséquences ;
- risques ;
- statut.

---

## 37. Evidence Registry

Ajouter des entrées pour :

- thème sombre ;
- contraste renforcé ;
- mouvement réduit ;
- taille tactile renforcée ;
- densité confortable ;
- focus visible ;
- stimulation visuelle réduite ;
- surfaces sombres ;
- text scaling.

Ne pas inventer de source.

Marquer clairement les hypothèses.

---

## 38. Tests unitaires

Créer des tests pour :

### Construction

- thème clair ;
- thème sombre ;
- contraste renforcé ;
- profils combinés.

### Résolution

- présence de toutes les extensions ;
- mapping correct vers `ThemeData` ;
- mapping correct vers `ColorScheme`.

### Copie

- `copyWith` ;
- overrides ;
- valeurs par défaut.

### Interpolation

- clair vers sombre ;
- standard vers high contrast ;
- standard vers comfortable ;
- motion standard vers reduced.

### Invariants

- touch target minimum respecté ;
- compact ne descend pas sous le minimum ;
- focus non transparent ;
- contrastes critiques respectés ;
- surfaces distinguables.

### API

- utilisation dans `MaterialApp` ;
- résolution depuis `BuildContext` ;
- absence d’extension correctement gérée.

---

## 39. Tests de contraste

Tester au minimum les paires critiques pour :

- contenu principal sur surface de base ;
- contenu secondaire sur surface de base ;
- contenu inverse ;
- action principale ;
- action destructive ;
- focus ;
- erreur ;
- succès ;
- warning ;
- high contrast light ;
- high contrast dark.

Documenter les seuils visés.

Ne pas déclarer une conformité complète sur la base de quelques paires.

---

## 40. Tests de combinaison

Tester des combinaisons telles que :

```text
light + standard contrast + standard density
light + high contrast + comfortable density
dark + standard contrast + reduced motion
dark + high contrast + comfortable touch targets
light + reduced visual stimulation
dark + reduced visual stimulation
```

Vérifier qu’aucune combinaison ne produit :

- champ null ;
- contraste critique insuffisant ;
- taille tactile invalide ;
- thème incohérent ;
- exception.

---

## 41. Catalogue

Mettre à jour le catalogue avec un explorateur de thèmes.

Permettre de visualiser :

- clair ;
- sombre ;
- contraste standard ;
- contraste renforcé ;
- densité ;
- mouvement ;
- taille tactile ;
- stimulation visuelle.

Le catalogue peut utiliser des contrôles Flutter standards.

Présenter :

- surfaces ;
- contenus ;
- bordures ;
- focus ;
- actions sémantiques ;
- feedback ;
- typographie ;
- spacing ;
- exemples de text scaling.

Ne pas présenter ces démonstrations comme des composants IUX finaux.

---

## 42. Scénarios de catalogue

Créer au minimum :

- Light Standard ;
- Dark Standard ;
- Light High Contrast ;
- Dark High Contrast ;
- Comfortable Density ;
- Reduced Motion ;
- Comfortable Touch Targets ;
- Reduced Visual Stimulation ;
- Large Text ;
- Long Labels.

Le catalogue doit expliquer ce qui change dans chaque profil.

---

## 43. Dépendances

Ne pas ajouter de dépendance externe sauf nécessité réelle.

Le moteur doit idéalement utiliser uniquement Flutter et Dart.

Toute dépendance doit être justifiée selon :

- maintenance ;
- licence ;
- poids ;
- alternatives ;
- valeur immédiate ;
- risque futur.

---

## 44. Performance

Le moteur doit être léger.

Éviter :

- recalculs coûteux dans `build` ;
- maps dynamiques ;
- lookup par chaîne ;
- réflexion ;
- génération de palette à chaque frame ;
- allocations répétées ;
- contexte global mutable.

Préférer :

- objets immuables ;
- constructeurs `const` ;
- valeurs résolues une fois ;
- accès direct ;
- extensions de thème.

---

## 45. Compatibilité

Cette mission est additive.

Ne pas casser :

- le package ;
- les fondations ;
- les tokens sémantiques ;
- les tests existants ;
- le catalogue ;
- les imports publics.

Toute évolution d’un type existant doit être documentée.

---

## 46. Commandes de validation

Exécuter :

```bash
dart format .
flutter analyze
flutter test
```

Vérifier le catalogue :

```bash
flutter run
```

et si possible :

```bash
flutter build apk --debug
```

Ne pas annoncer une réussite sans exécution réelle.

---

## 47. Livrables obligatoires

À la fin de cette mission, fournir :

- le moteur de thèmes ;
- les configurations publiques ;
- les profils combinables ;
- les thèmes clair et sombre ;
- le contraste renforcé ;
- le mouvement réduit ;
- les densités ;
- les tailles tactiles ;
- la stimulation visuelle réduite ;
- le mapping Material ;
- les `ThemeExtension` ;
- les helpers `BuildContext` ;
- les tests ;
- la documentation ;
- les ADR ;
- l’evidence registry ;
- le catalogue mis à jour ;
- les résultats des validations ;
- la liste des fichiers créés et modifiés ;
- les décisions différées.

---

## 48. Critères d’acceptation

La mission est terminée uniquement si :

- `IuxTheme.light()` ou une API équivalente est directement utilisable ;
- `IuxTheme.dark()` ou une API équivalente est directement utilisable ;
- le contraste renforcé est combinable ;
- la densité est combinable ;
- le mouvement réduit est combinable ;
- les tailles tactiles sont combinables ;
- la stimulation visuelle réduite est modélisée ;
- toutes les extensions nécessaires sont présentes ;
- les futurs composants peuvent lire le thème ;
- les couleurs primitives restent internes ;
- aucun thème de marque n’est créé ;
- aucun composant final n’est créé ;
- les tests de contraste ciblés passent ;
- les tests de combinaison passent ;
- le catalogue permet d’explorer les profils ;
- `flutter analyze` ne retourne aucune erreur ;
- `flutter test` réussit.

---

## 49. Rapport final attendu

Répondre avec cette structure :

### Résumé

Décrire le moteur de thèmes ajouté.

### Audit initial

Présenter l’état du projet avant modification.

### Architecture retenue

Expliquer configuration, résolution et génération Material.

### API publique

Lister les types et constructeurs publics.

### Profils combinables

Présenter contraste, densité, mouvement, touch targets et stimulation.

### Thèmes accessibles

Présenter clair, sombre et contraste renforcé.

### Intégration Material

Expliquer `ThemeData`, `ColorScheme` et `ThemeExtension`.

### Accessibilité

Présenter les garanties et limites.

### Documentation et evidence

Lister les documents, ADR et sources ajoutés.

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

- les composants non encore créés ;
- les comportements dépendant de `MediaQuery` ;
- les profils restant expérimentaux ;
- les sources restant à vérifier ;
- les personnalisations volontairement différées.

### Prochaine mission recommandée

Indiquer que la prochaine étape logique est l’infrastructure d’accessibilité opérationnelle, sans la commencer.

---

## 50. Instruction finale

Commence par auditer le résultat réel des missions IUX-001, IUX-002 et IUX-003.

Présente ensuite un plan court et concret.

Puis implémente le moteur de thèmes accessibles.

Ne crée aucun composant final.

Ne crée aucun thème de marque.

Ne commence pas la mission suivante.


---

# Rapport final

## Résumé

Moteur de thèmes accessibles séparant configuration et résolution. Six
préférences orthogonales produisent 192 combinaisons, toutes valides, toutes
résolues sans erreur. Le contraste renforcé est désormais combinable avec le
clair **et** le sombre.

## Audit initial

État avant la mission, après IUX-003.1 : fondations et couche sémantique
complètes, aucun thème. `IuxVisualStimulation` et
`IuxMotionPreference.standard` manquaient dans les fondations d'IUX-002 ;
ajoutés de façon additive.

## Architecture retenue

```text
IuxThemeConfiguration  → ce qui est demandé
        ↓
IuxResolvedTheme       → ce qui en sort (inspectable sans ThemeData)
        ↓
ThemeData              → ce que Flutter consomme
```

## API publique

- `IuxTheme.light()`, `IuxTheme.dark()` → `ThemeData` directement utilisable
- `IuxTheme.fromConfiguration()`, `IuxTheme.resolve()`,
  `IuxTheme.withSemanticColors()`
- `IuxThemeConfiguration`, `IuxTypographyConfiguration`, `IuxResolvedTheme`
- Extensions : `IuxTypographyTheme`, `IuxGeometryTheme`, `IuxMotionTheme`,
  `IuxAccessibilityTheme` (+ `IuxSemanticColors` d'IUX-003.1)
- Fondations étendues : `IuxVisualStimulation`,
  `IuxMotionPreference.standard`, profil enrichi et comparable

Aucun constructeur nommé par combinaison : le cas courant reste une ligne, et
aucune combinaison n'est inatteignable.

## Profils combinables

6 axes orthogonaux — brightness, contrast, density, motion, touchTarget,
visualStimulation. Aucun n'en implique un autre. Trois constructeurs nommés
(`standard`, `comfortable`, `reducedMotion`) décrivent ce qu'ils règlent,
jamais à qui ils s'adressent (ADR-0004).

## Thèmes accessibles

4 mappings `const` : clair et sombre, chacun en contraste standard et renforcé.
Le contraste renforcé épaissit aussi les traits (bordure 1→2, focus 2→3) au
lieu de seulement recolorer.

## Intégration Material

`ColorScheme` dérivé des rôles IUX (ADR-0002), jamais l'inverse. `surfaceTint`
neutralisé : la teinte Material liée à l'élévation déplacerait les surfaces
hors des valeurs mesurées. Les thèmes de composants Material ne sont
configurés que là où un manque serait visible — boutons, chips, cards et
navigation appartiennent aux missions suivantes.

## Accessibilité

Garanties : 4 profils mesurés, plancher de cible tactile tenu à toutes les
densités et pendant les transitions, focus opaque et distinct de la sélection,
mouvement réduit qui raccourcit sans supprimer le sens.

Limites : un thème statique ne peut pas lire `MediaQuery`.
`IuxMotionPreference.system` est explicitement non résolu et
`respectsPlatformPreference` le signale, plutôt que de deviner. IUX-005 ferme
l'écart.

## Documentation et evidence

`docs/themes/` : overview, light-and-dark, contrast, density, motion,
touch-targets, visual-stimulation, customization, brand-theme-guidelines.
`docs/accessibility/theme-preferences.md`. ADR-0003 et ADR-0004. Dix entrées
`IUX-THEME-*` ajoutées à l'evidence registry, dont deux marquées `hypothesis`.

## Commandes exécutées

| Commande | Résultat réel |
| --- | --- |
| `dart format .` | 30 fichiers, 0 modifié |
| `flutter analyze` (package) | No issues found |
| `flutter test` (package) | 97 tests, tous passés |
| `flutter analyze` (catalogue) | No issues found |
| `flutter test` (catalogue) | 6 tests, tous passés |
| `flutter build apk --debug` | `app-debug.apk` construit |

## Limites et décisions différées

- La préférence plateforme de mouvement reste à réconcilier (IUX-005).
- `MediaQuery.highContrast` n'est pas fiable sur toutes les versions Android.
- `IuxVisualStimulation` est une hypothèse non validée auprès d'utilisateurs.
- Les 4 mappings sont maintenus à la main : ajouter un rôle impose 4 éditions.
- Aucune validation manuelle (TalkBack, Voice Access, clavier) : aucun
  composant n'existe encore.

## Prochaine mission

IUX-005 — infrastructure d'accessibilité opérationnelle, qui réconciliera les
préférences plateforme avec le profil IUX. Non commencée.
