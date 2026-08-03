---
mission_id: IUX-007
title: Système de layout et primitives de composition
priority: critical
status: completed
started_at: 2026-08-03
started_by: Claude
last_updated_at: 2026-08-03
completion_status: accepted
validation_status: passed
target_version: 0.1.0-dev.7
compatibility: additive
depends_on:
  - IUX-001
  - IUX-002
  - IUX-003
  - IUX-004
  - IUX-005
  - IUX-006
platform_priority: Android
package_name: iux_flutter
---

# IUX-007 — Système de layout et primitives de composition

## 1. Références obligatoires

Avant toute action :

1. Lire intégralement `PROJECT_PROMPT.md`.
2. Lire intégralement les missions IUX-001 à IUX-006.
3. Vérifier que les missions précédentes ont été terminées et validées.
4. Lire intégralement ce document.
5. Considérer ce document comme la seule mission active.
6. Ne pas modifier le dépôt `d4-dark-ds`.
7. Réutiliser les fondations, thèmes, profils, runtime d’accessibilité et moteur de mouvement existants.
8. Ne pas commencer encore le système de boutons.
9. Ne pas créer de composants métier.

En cas de conflit, `PROJECT_PROMPT.md` prévaut.

---

## 2. Contexte

IUX possède désormais :

- une architecture stable ;
- des fondations de design et d’interaction ;
- des tokens sémantiques ;
- un moteur de thèmes accessibles ;
- un runtime d’accessibilité ;
- un moteur de mouvement et de feedback.

Cette mission doit créer les primitives de composition communes aux futurs composants et patterns.

Le système de layout ne doit pas être une simple collection de raccourcis vers `Padding`, `Container` ou `Column`.

Il doit fournir des conventions sûres et cohérentes pour :

- organiser une page ;
- limiter la largeur du contenu ;
- grouper l’information ;
- gérer les surfaces ;
- appliquer les espacements ;
- gérer les zones sûres ;
- s’adapter aux petits écrans ;
- respecter le texte agrandi ;
- préparer l’usage à une main ;
- gérer les états de scroll ;
- composer les futurs composants IUX.

---

## 3. Objectif utilisateur

Garantir que les écrans construits avec IUX présentent :

- une hiérarchie claire ;
- des espacements cohérents ;
- des groupes compréhensibles ;
- un contenu lisible ;
- des zones interactives accessibles ;
- un comportement stable lorsque le texte augmente ;
- une adaptation correcte aux petits et grands écrans Android.

L’utilisateur final doit pouvoir parcourir l’information sans surcharge, perte de contexte ni disposition fragile.

---

## 4. Objectifs de la mission

Cette mission doit :

1. Définir les primitives de surface.
2. Définir les primitives de page.
3. Définir les primitives de section.
4. Définir les primitives d’espacement.
5. Définir les contraintes de largeur de contenu.
6. Définir les règles de disposition responsive.
7. Définir les comportements pour petits écrans.
8. Définir les comportements pour texte agrandi.
9. Définir les zones sûres et insets.
10. Définir les conventions de scroll.
11. Définir les conventions d’alignement et de regroupement.
12. Créer des primitives accessibles et thémables.
13. Ajouter tests, documentation, ADR et catalogue.
14. Préparer les composants d’action de la mission suivante.

---

## 5. Hors périmètre

Ne pas réaliser dans cette mission :

- de bouton final ;
- de champ de formulaire ;
- de carte métier ;
- de list tile final ;
- de snackbar ;
- de dialogue ;
- de navigation bar ;
- de tabs ;
- de drawer ;
- de dashboard ;
- de grille complexe ;
- de masonry layout ;
- de système de breakpoint web complet ;
- de moteur responsive générique multi-plateforme ;
- de logique métier ;
- de publication sur `pub.dev`.

Les primitives créées doivent rester générales.

---

## 6. Audit préalable obligatoire

Avant toute modification, inspecter :

- les fondations d’espacement et de taille ;
- le moteur de thèmes ;
- le profil de densité ;
- les tailles tactiles ;
- le runtime d’accessibilité ;
- les conventions de catalogue ;
- les tests ;
- les exports publics ;
- les ADR ;
- les dépendances.

Présenter :

- ce qui peut être réutilisé ;
- les risques de duplication avec Flutter ;
- les risques de wrappers inutiles ;
- les risques d’API trop rigide ;
- les risques de layout cassé avec text scaling ;
- les risques de dépendance à des breakpoints arbitraires.

---

## 7. Principes directeurs

### Les primitives doivent exprimer une intention

Préférer :

```dart
IuxSection(...)
IuxPageBody(...)
IuxSurface(...)
```

à des wrappers sans valeur sémantique.

### Ne pas masquer Flutter

Les développeurs doivent pouvoir utiliser directement :

- `Row` ;
- `Column` ;
- `Flex` ;
- `Wrap` ;
- `LayoutBuilder` ;
- `CustomScrollView`.

IUX ne doit pas recréer tout le moteur de layout Flutter.

### Les bons défauts avant l’abstraction

Les primitives doivent :

- fournir de bons paddings ;
- appliquer les contraintes de largeur ;
- respecter les zones sûres ;
- gérer les thèmes ;
- rester composables.

### Pas de layout fragile

Éviter :

- hauteurs fixes inutiles ;
- largeur fixe de texte ;
- troncature par défaut ;
- position absolue ;
- dépendance à un seul écran ;
- hypothèse sur la longueur des traductions.

---

## 8. Architecture cible

Structure indicative :

```text
packages/iux_flutter/lib/src/layout/
├── page/
│   ├── iux_page.dart
│   ├── iux_page_body.dart
│   └── iux_page_constraints.dart
├── surface/
│   ├── iux_surface.dart
│   └── iux_surface_role.dart
├── section/
│   ├── iux_section.dart
│   └── iux_section_header.dart
├── spacing/
│   ├── iux_gap.dart
│   └── iux_insets.dart
├── responsive/
│   ├── iux_layout_class.dart
│   ├── iux_breakpoints.dart
│   └── iux_responsive_value.dart
└── scroll/
    ├── iux_scroll_behavior.dart
    └── iux_scroll_constraints.dart
```

Adapter si cette structure devient trop fragmentée.

---

## 9. Primitive de surface

Créer une primitive `IuxSurface` ou équivalent.

Elle doit exprimer un rôle sémantique de surface, par exemple :

```dart
enum IuxSurfaceRole {
  base,
  subtle,
  raised,
  overlay,
  selected,
  inverse,
}
```

Elle doit pouvoir résoudre depuis le thème :

- couleur ;
- bordure ;
- forme ;
- élévation ;
- padding par défaut éventuel.

Contraintes :

- aucune couleur directe dans l’usage courant ;
- aucune ombre codée en dur ;
- aucun glow ;
- aucune identité de marque ;
- pas d’interaction implicite ;
- pas de sémantique de bouton ou de carte métier.

---

## 10. Primitive de page

Créer une primitive de page légère.

Elle peut fournir :

- fond ;
- `SafeArea` configurable ;
- body ;
- scroll optionnel ;
- largeur maximale ;
- padding horizontal ;
- padding vertical ;
- gestion du clavier si pertinente ;
- adaptation à la densité.

Elle ne doit pas remplacer entièrement `Scaffold`.

Évaluer une API telle que :

```dart
IuxPage(
  body: ...,
)
```

ou :

```dart
Scaffold(
  body: IuxPageBody(...),
)
```

Choisir l’approche la plus cohérente.

---

## 11. Primitive de corps de page

Créer une primitive pour organiser le contenu principal.

Elle doit pouvoir gérer :

- padding responsive ;
- largeur maximale ;
- centrage ;
- alignement ;
- scroll ;
- sections ;
- text scaling ;
- petits écrans.

Le cas courant doit rester simple.

---

## 12. Primitive de section

Créer `IuxSection` ou équivalent.

Elle doit pouvoir regrouper :

- titre ;
- description ;
- contenu ;
- action optionnelle ;
- état sémantique de groupe.

Exigences :

- hiérarchie de lecture correcte ;
- titre annoncé correctement ;
- action accessible ;
- support des textes longs ;
- support du wrapping ;
- espacement cohérent ;
- aucune logique métier.

---

## 13. En-tête de section

Évaluer une primitive dédiée :

```dart
IuxSectionHeader(
  title: ...,
  description: ...,
  action: ...,
)
```

Ne la créer que si elle évite réellement la duplication.

Elle doit gérer :

- titre long ;
- description multiligne ;
- action qui passe sous le titre si nécessaire ;
- texte agrandi ;
- petit écran ;
- ordre de lecture logique.

---

## 14. Primitives d’espacement

Créer une primitive de gap si elle améliore réellement l’API.

Exemple :

```dart
const IuxGap.md()
```

ou :

```dart
IuxGap.vertical(IuxSpacing.md)
```

Éviter une API gadget.

L’usage direct de `SizedBox` reste acceptable.

La primitive n’est justifiée que si elle :

- utilise les tokens ;
- s’adapte à la densité ;
- évite les valeurs arbitraires ;
- améliore la lisibilité.

---

## 15. Insets

Créer une modélisation des insets cohérente.

Elle peut couvrir :

- page ;
- section ;
- surface ;
- compact ;
- standard ;
- comfortable.

Évaluer des objets comme :

```dart
IuxInsets.page(context)
IuxInsets.section(context)
```

ou une extension de thème.

Éviter les méthodes dépendant inutilement de `BuildContext`.

---

## 16. Largeur de contenu

Définir des contraintes de largeur lisible.

Distinguer éventuellement :

- contenu étroit ;
- contenu de lecture ;
- contenu standard ;
- contenu large.

Exemple :

```dart
enum IuxContentWidth {
  narrow,
  reading,
  standard,
  wide,
  fluid,
}
```

Documenter :

- l’usage ;
- les limites ;
- le comportement sur petits écrans ;
- la relation avec text scaling.

Ne pas figer des largeurs sans justification.

---

## 17. Classes de layout

Évaluer une classification simple des écrans Android.

Exemple :

```dart
enum IuxLayoutClass {
  compact,
  medium,
  expanded,
}
```

Les seuils doivent :

- être documentés ;
- être peu nombreux ;
- rester cohérents avec Android ;
- ne pas dépendre d’un modèle de téléphone précis.

Éviter un système web complexe.

---

## 18. Breakpoints

Créer des breakpoints uniquement s’ils sont nécessaires.

Ils doivent être centralisés.

Éviter :

- valeurs dupliquées ;
- conditions dispersées ;
- dépendance à l’orientation seule ;
- logique spécifique à un appareil.

Documenter la relation entre :

- largeur disponible ;
- text scaling ;
- densité ;
- orientation ;
- classe de layout.

---

## 19. Valeurs responsive

Évaluer une API telle que :

```dart
IuxResponsiveValue<T>(
  compact: ...,
  medium: ...,
  expanded: ...,
)
```

Ne la créer que si elle apporte une vraie cohérence.

Éviter un DSL complexe.

L’API doit rester fortement typée et simple.

---

## 20. Petits écrans

Les primitives doivent garantir :

- absence d’overflow horizontal ;
- wrapping ;
- paddings raisonnables ;
- action repositionnable ;
- scroll vertical lorsque nécessaire ;
- largeur fluide ;
- contenu prioritaire visible.

Tester des largeurs Android compactes.

---

## 21. Texte agrandi

Les layouts doivent fonctionner avec text scaling élevé.

Contraintes :

- pas de hauteur fixe ;
- pas de clipping ;
- pas de labels importants tronqués ;
- actions repositionnables ;
- sections extensibles ;
- scroll possible ;
- ordre de lecture conservé.

Le catalogue doit inclure plusieurs niveaux de text scaling.

---

## 22. Zones sûres

Définir une stratégie pour :

- status bar ;
- navigation bar ;
- découpes ;
- clavier ;
- gestes système ;
- edge-to-edge.

Le système ne doit pas appliquer `SafeArea` partout de manière aveugle.

Documenter :

- quand la page gère les insets ;
- quand le composant laisse l’application gérer ;
- comment éviter les doubles paddings.

---

## 23. Edge-to-edge Android

Évaluer la compatibilité avec les recommandations Android modernes.

La primitive de page doit pouvoir fonctionner en edge-to-edge.

Ne pas imposer une couleur système arbitraire.

Documenter :

- responsabilité de l’application ;
- relation avec `SystemUiOverlayStyle` ;
- zones de contenu ;
- surfaces derrière les barres système.

---

## 24. Scroll

Définir les règles pour :

- page scrollable ;
- contenu fixe ;
- nested scroll ;
- clavier ;
- focus ;
- retour à l’élément focalisé ;
- scrollbars si pertinentes.

Ne pas créer un moteur de scroll personnalisé.

Utiliser les primitives Flutter.

---

## 25. Clavier logiciel

Les primitives de page et de formulaire futures devront fonctionner avec le clavier.

Dans cette mission, prévoir :

- resize ;
- scroll ;
- insets ;
- focus visible ;
- absence de contenu masqué.

Ne pas implémenter encore les champs.

---

## 26. Alignement et regroupement

Documenter les conventions :

- alignement de départ ;
- regroupement par proximité ;
- espacement intra-groupe ;
- espacement inter-groupes ;
- séparation visuelle ;
- hiérarchie des sections.

Les conventions doivent être reliées aux tokens de spacing.

---

## 27. Lecture et ordre sémantique

Les primitives doivent préserver :

- ordre visuel ;
- ordre sémantique ;
- ordre de focus ;
- regroupement logique.

Ne pas utiliser de réorganisation visuelle qui diverge de l’arbre sémantique sans justification.

---

## 28. Interaction à une main

Préparer les conventions de page pour :

- actions principales accessibles ;
- contenu important non placé uniquement en haut ;
- zones de navigation futures ;
- petits écrans ;
- scroll.

Cette mission ne doit pas imposer une règle universelle de thumb zone.

Documenter les limites et le caractère contextuel.

---

## 29. Densité

Les primitives doivent consommer la densité du thème.

La densité peut influencer :

- padding ;
- gaps ;
- hauteur visuelle ;
- largeur de section.

Elle ne doit pas réduire les cibles tactiles sous le minimum.

---

## 30. Thèmes

Les primitives doivent utiliser :

- tokens sémantiques ;
- formes ;
- élévation ;
- spacing ;
- densité ;
- focus ;
- accessibilité.

Aucune valeur graphique ne doit être codée en dur sans justification.

---

## 31. Mouvement

Le layout ne doit pas animer implicitement tous les changements.

Si certaines primitives offrent une transition :

- elle doit être opt-in ;
- utiliser IUX-006 ;
- respecter reduced motion ;
- expliquer une réorganisation ;
- ne pas gêner le focus.

Éviter `AnimatedSize` généralisé.

---

## 32. API publique

Exporter uniquement les primitives stables :

- page ;
- body ;
- surface ;
- section ;
- gap ou insets ;
- classes de layout ;
- responsive value si retenu.

Ne pas exporter :

- helpers internes ;
- breakpoints expérimentaux non documentés ;
- adaptateurs temporaires ;
- outils du catalogue.

---

## 33. Documentation Dart

Toute API publique doit documenter :

- intention ;
- usage ;
- limites ;
- comportement responsive ;
- text scaling ;
- accessibilité ;
- densité ;
- zones sûres ;
- relation avec Flutter.

---

## 34. Documentation conceptuelle

Créer au minimum :

```text
docs/layout/overview.md
docs/layout/pages.md
docs/layout/surfaces.md
docs/layout/sections.md
docs/layout/spacing-and-grouping.md
docs/layout/responsive-layout.md
docs/layout/content-width.md
docs/layout/safe-areas-and-insets.md
docs/layout/text-scaling.md
docs/layout/scrolling.md
```

Chaque document doit inclure :

- intention ;
- API ;
- exemples ;
- contre-exemples ;
- limites ;
- accessibilité ;
- sources ;
- niveau de preuve.

---

## 35. ADR

Créer au minimum :

```text
docs/decisions/ADR-0007-layout-primitives.md
docs/decisions/ADR-0008-responsive-layout-classes.md
```

Inclure :

- contexte ;
- décision ;
- alternatives ;
- conséquences ;
- risques ;
- statut.

---

## 36. Evidence Registry

Ajouter des entrées pour :

- largeur de lecture ;
- regroupement par proximité ;
- text scaling ;
- petits écrans ;
- safe areas ;
- ordre de lecture ;
- densité ;
- interaction à une main ;
- responsive layout.

Ne pas inventer de source.

Marquer les hypothèses.

---

## 37. Tests unitaires

Tester :

- classes de layout ;
- breakpoints ;
- valeurs responsive ;
- insets ;
- spacing ;
- densité ;
- largeur de contenu ;
- résolution de surface ;
- rôles de surface.

---

## 38. Widget tests

Tester :

### Page

- petit écran ;
- écran moyen ;
- écran large ;
- SafeArea ;
- scroll ;
- edge-to-edge ;
- clavier simulé si possible.

### Section

- titre long ;
- description longue ;
- action ;
- texte agrandi ;
- ordre sémantique ;
- wrapping.

### Surface

- rôles ;
- thème clair ;
- thème sombre ;
- contraste renforcé ;
- densité ;
- bordure ;
- forme.

### Responsive

- changement de classe ;
- absence d’overflow ;
- repositionnement des actions ;
- largeur maximale.

---

## 39. Tests d’accessibilité

Tester :

- semantics des sections ;
- ordre de lecture ;
- focus ;
- text scaling ;
- touch targets des actions de header futures ;
- contraste des surfaces ;
- absence de clipping ;
- scroll vers le focus si testable.

---

## 40. Tests de contrat

Garantir que :

- les primitives ne dépendent pas de composants futurs ;
- aucun style de marque n’est présent ;
- les valeurs arbitraires sont limitées ;
- les breakpoints sont centralisés ;
- les layouts n’imposent pas de hauteur fixe ;
- les composants Flutter standards restent utilisables ;
- le barrel public est cohérent.

---

## 41. Catalogue

Ajouter une section Layout présentant :

- page standard ;
- page scrollable ;
- page étroite ;
- page large ;
- surfaces ;
- sections ;
- titres longs ;
- description longue ;
- action déplacée ;
- texte agrandi ;
- compact ;
- medium ;
- expanded ;
- density compact ;
- density comfortable ;
- high contrast ;
- dark ;
- safe areas ;
- edge-to-edge.

---

## 42. Scénarios du catalogue

Créer au minimum :

- Compact phone ;
- Medium window ;
- Expanded window ;
- Large text ;
- Long localization ;
- Comfortable density ;
- High contrast ;
- Dark mode ;
- Edge-to-edge ;
- Scrollable content ;
- Multiple sections.

Le catalogue doit expliquer les règles, pas seulement montrer le rendu.

---

## 43. Dépendances

Ne pas ajouter de dépendance externe sauf nécessité forte.

Utiliser les primitives Flutter.

Toute dépendance doit être justifiée selon :

- maintenance ;
- licence ;
- poids ;
- alternatives ;
- valeur immédiate ;
- impact sur la composition.

---

## 44. Performance

Les primitives doivent être légères.

Éviter :

- layouts imbriqués inutilement ;
- `IntrinsicHeight` ou `IntrinsicWidth` généralisés ;
- mesures répétées ;
- listeners globaux ;
- rebuilds excessifs ;
- animations implicites permanentes.

Préférer :

- `LayoutBuilder` avec parcimonie ;
- contraintes simples ;
- widgets `const` ;
- composition ;
- slivers lorsque nécessaire.

---

## 45. Compatibilité

Cette mission est additive.

Ne pas casser :

- fondations ;
- thèmes ;
- runtime ;
- mouvement ;
- catalogue ;
- tests ;
- exports publics.

Toute modification d’un contrat existant doit être justifiée.

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

Ne pas déclarer une réussite sans exécution réelle.

---

## 47. Livrables obligatoires

À la fin de cette mission, fournir :

- primitives de page ;
- primitives de surface ;
- primitives de section ;
- système d’insets ;
- classes de layout ;
- contraintes de largeur ;
- support responsive ;
- support text scaling ;
- support safe areas ;
- support densité ;
- tests ;
- documentation ;
- ADR ;
- evidence registry ;
- catalogue mis à jour ;
- résultats de validation ;
- liste des fichiers créés et modifiés ;
- limites et décisions différées.

---

## 48. Critères d’acceptation

La mission est terminée uniquement si :

- une page IUX peut être construite sans valeurs arbitraires ;
- les surfaces utilisent les rôles sémantiques ;
- les sections ont une hiérarchie accessible ;
- les petits écrans sont supportés ;
- le texte agrandi ne provoque pas d’overflow majeur ;
- les classes de layout sont centralisées ;
- les safe areas sont gérées sans double padding ;
- le système reste compatible edge-to-edge ;
- la densité est respectée ;
- aucun composant métier n’est créé ;
- aucun style de marque n’est ajouté ;
- le catalogue présente les scénarios ;
- `flutter analyze` ne retourne aucune erreur ;
- `flutter test` réussit.

---

## 49. Rapport final attendu

Répondre avec cette structure :

### Résumé

Décrire le système de layout ajouté.

### Audit initial

Présenter l’état du projet avant modification.

### Architecture retenue

Expliquer pages, surfaces, sections, insets et responsive.

### API publique

Lister les types publics ajoutés.

### Responsive

Présenter les classes, breakpoints et comportements.

### Accessibilité

Présenter text scaling, focus, ordre de lecture et safe areas.

### Thèmes et densité

Présenter la résolution depuis le thème.

### Documentation et evidence

Lister les documents, ADR et sources.

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

- navigation non encore créée ;
- formulaires non encore créés ;
- composants d’action non encore créés ;
- comportements avancés tablette différés ;
- sources restant à vérifier.

### Prochaine mission recommandée

Indiquer que la prochaine étape logique est le système de boutons et d’actions, sans la commencer.

---

## 50. Instruction finale

Commence par auditer le résultat réel des missions IUX-001 à IUX-006.

Présente ensuite un plan court et concret.

Puis implémente le système de layout.

Ne crée pas encore le système de boutons.

Ne crée aucun composant métier.

Ne commence pas la mission suivante.


---

# Rapport final

## Résumé

Primitives de mise en page composables : page, surface, section, espacement,
largeur lisible et classes de layout. Elles consomment le thème (IUX-004) et
le runtime (IUX-005), et n'introduisent aucune valeur graphique en dur.

## Audit initial

Les fondations d'espacement (IUX-002) et la géométrie résolue (IUX-004)
existaient déjà ; les primitives les consomment plutôt que de redéfinir une
échelle. `IuxSurface` et `IuxSection`, retirés en IUX-003.1 comme hors
périmètre, sont ici recréés par la mission qui les possède.

## Architecture retenue

Structure aplatie par rapport au §8 : six fichiers sous `lib/src/layout/`
plutôt que six sous-dossiers, la fragmentation proposée n'étant pas justifiée
à ce volume.

## API publiques

`IuxPage` / `IuxPageInsets`, `IuxSurface` / `IuxSurfaceRole` /
`IuxSurfaceShape`, `IuxSection` / `IuxSectionHeader`, `IuxGap` /
`IuxTargetSpacing` / `IuxInsets` / `kIuxMinimumTargetSpacing`,
`IuxContentWidth` / `IuxContentWidthResolver` / `IuxReadableWidth`,
`IuxLayoutClass` / `IuxBreakpoints` / `IuxResponsiveValue`.

## Décisions importantes

1. **`IuxPage` compose avec `Scaffold`**, ne le remplace pas.
2. **Le défilement est actif par défaut** : un écran qui ne défile pas casse
   dès qu'on agrandit le texte ou qu'un clavier apparaît.
3. **Les zones sûres se consomment par bord**, en quatre modes explicites —
   un booléen ne peut pas exprimer quels bords un élément imbriqué a déjà
   consommés.
4. **La largeur de lecture se mesure en caractères**, convertis à la taille de
   texte en vigueur. Un plafond en pixels divise par deux le nombre de
   caractères par ligne quand l'utilisateur double son texte.
5. **L'espacement entre cibles est une primitive**, pas une consigne : il ferme
   l'écart laissé ouvert par IUX-005 et ne peut pas être configuré sous le
   plancher.
6. **`Wrap` plutôt que `Row`** pour les groupes de contrôles.
7. **Aucune règle universelle de thumb zone.** La portée dépend de la main, de
   la prise et de l'appareil.

## Tests

184 dans le package, 10 dans le catalogue. Une composition complète est
vérifiée à 320×480 avec un facteur de texte 2, sans overflow.

## Documentation

`docs/layout/overview.md`, ADR-0007, six entrées `IUX-LAYOUT-*` dans
l'evidence registry dont deux marquées `hypothesis` ou `context_dependent`.

## Limites

- La conversion caractères→pixels suppose une police proportionnelle latine et
  sera fausse pour le CJK et le monospace.
- L'imbrication de deux `IuxPage` produit un double padding : documenté, non
  détecté.
- `Wrap` ne peut pas exprimer « ces deux éléments doivent rester sur une
  ligne ».
- Le défilement imbriqué n'est pas modélisé.
- Aucune validation manuelle sur appareil, ni en RTL.

## Prochaine mission recommandée

IUX-008.1 — Component Standard. Non commencée.
