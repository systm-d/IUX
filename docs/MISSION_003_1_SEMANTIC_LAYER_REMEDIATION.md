---
mission_id: IUX-003.1
title: Remédiation de la couche sémantique et retrait du code hors périmètre
priority: critical
status: completed
started_at: 2026-08-03
started_by: Claude
last_updated_at: 2026-08-03
completion_status: accepted
validation_status: passed
target_version: 0.1.0-dev.3.1
compatibility: breaking
depends_on:
  - IUX-001
  - IUX-002
  - IUX-003
platform_priority: Android
package_name: iux_flutter
---

# IUX-003.1 — Remédiation de la couche sémantique et retrait du code hors périmètre

## 1. Origine de cette mission

`PROJECT_PROMPT.md` §63 interdit de rouvrir une mission `completed` :

> ne jamais modifier une mission `completed` pour la reprendre : créer une
> nouvelle mission de suivi.

La mission IUX-003 est marquée `completed / accepted / passed`. Un audit du
dépôt montre que ses critères d'acceptation (§35) ne sont pas remplis. Cette
mission de suivi corrige l'écart sans modifier le statut de IUX-003.

Le statut de IUX-003 reste `completed`. Son rapport historique n'est pas
réécrit. L'écart est enregistré ici.

---

## 2. Écarts constatés

Audit réalisé sur l'état du dépôt avant cette mission.

### 2.1 Rôles sémantiques incomplets

`IuxSemanticColors` expose dix champs `Color` plats. La mission IUX-003
demandait :

| Exigence IUX-003 | Attendu | Constaté |
| --- | --- | --- |
| §10 rôles de contenu | 7 | 2 |
| §11 rôles de surface | 8 | 1 |
| §12 rôles de bordure | 8 | 1 |
| §13 rôles d'action | 4 intentions × 4 états | 2 couleurs, aucun état |
| §14 rôles de feedback | 4 rôles structurés | 3 couleurs plates |
| §15 rôles d'état | modélisés | absents |

### 2.2 Absence de couleurs primitives internes

IUX-003 §9 demande une couche de primitives internes servant à construire les
futurs thèmes. Aucune primitive n'existe. `IuxSemanticColors.fromColorScheme`
dérive tous les rôles d'un `ColorScheme` Material, ce qui place la source de
vérité hors d'IUX et rend impossible toute garantie de contraste.

### 2.3 `copyWith` non fonctionnel

`IuxSemanticColors.copyWith` n'accepte que `contentPrimary`. Les autres rôles
ne peuvent pas être surchargés. Le critère IUX-003 §35 « `copyWith` et `lerp`
fonctionnent » n'est pas satisfait. Le test associé passe à vide.

### 2.4 Contraste non outillé

IUX-003 §18, §26 et §29 demandent des contrats de contraste documentés, un
utilitaire de mesure et des tests sur les paires critiques. Aucun code de
calcul de luminance ou de ratio n'existe dans le dépôt.

### 2.5 Documentation et ADR manquantes

IUX-003 §24 demande sept documents conceptuels ; un seul existe. IUX-003 §17
demande `ADR-0002-semantic-colors-and-color-scheme.md` ; le fichier présent est
`ADR-0002-semantic-theme-profiles.md` et traite un autre sujet.

### 2.6 Code hors périmètre

IUX-003 §5 et IUX-004 §5 interdisent explicitement la création de composants
finaux et de thèmes. Le dépôt contient déjà, sous forme d'enveloppes Material
sans valeur UX ajoutée :

| Fichier | Mission propriétaire |
| --- | --- |
| `src/components/iux_button.dart` | IUX-008.4 |
| `src/components/iux_inputs.dart` | IUX-010, IUX-011 |
| `src/components/iux_overlays.dart` | IUX-016 à IUX-018 |
| `src/components/iux_states.dart` | IUX-028 à IUX-030 |
| `src/layout/iux_layout.dart` | IUX-007 |
| `src/actions/iux_action.dart` | IUX-008.2 |
| `src/accessibility/iux_accessibility.dart` | IUX-005 |
| `src/feedback/iux_feedback.dart` | IUX-006 |
| `src/themes/iux_theme.dart` | IUX-004 |

Ce code pré-empte la conception d'API que ces missions doivent produire.

### 2.7 Thème contredisant le PROJECT_PROMPT

`IuxTheme.data` utilise `ColorScheme.fromSeed(seedColor: Colors.indigo)`, soit
une graine de marque codée en dur, contraire à `PROJECT_PROMPT.md` §23. Le
profil `highContrast` force `Brightness.light`, rendant le contraste renforcé
sombre inatteignable.

---

## 3. Objectif

Livrer la couche sémantique réellement exigée par IUX-003, et restituer au
dépôt un périmètre conforme, afin que IUX-004 puisse construire le moteur de
thèmes sur une base saine.

---

## 4. Périmètre

### Dans le périmètre

1. Retirer le code hors périmètre listé en §2.6.
2. Créer les couleurs primitives internes minimales.
3. Créer les rôles de contenu, surface, bordure, action, feedback et état.
4. Rendre `copyWith`, `lerp`, `==` et `hashCode` complets et testés.
5. Créer l'utilitaire de mesure de contraste réservé aux tests.
6. Documenter les contrats de contraste et la non-dépendance à la couleur.
7. Créer les documents conceptuels et l'ADR manquants.
8. Alimenter l'evidence registry.
9. Fournir au catalogue deux jeux de démonstration temporaires.
10. Exécuter les validations réelles.

### Hors périmètre

- tout thème final clair, sombre ou contraste renforcé ;
- tout composant final ;
- tout pattern UX ;
- toute palette de marque ;
- toute revendication de conformité WCAG globale ;
- toute publication.

Les jeux de démonstration du catalogue doivent être nommés explicitement comme
temporaires, conformément à IUX-003 §28.

---

## 5. Contraintes

- Les primitives restent internes et non exportées.
- Aucun nom public ne contient de teinte ni de marque.
- Les objets sémantiques sont immuables et `const` lorsque possible.
- Les composants futurs ne doivent pas recalculer de contraste au runtime.
- L'utilitaire de contraste ne doit pas être exposé au runtime.

---

## 6. Rupture d'API assumée

Cette mission est `breaking` pour l'API introduite par IUX-003 :

- `IuxSemanticColors` passe d'une classe plate à une composition de groupes ;
- les types retirés en §2.6 disparaissent de l'API publique.

Aucune application tierce ne consomme le package (`publish_to: none`,
version `0.1.0-dev`). La rupture est documentée dans le `CHANGELOG.md`.

---

## 7. Critères d'acceptation

La mission est terminée uniquement si :

- aucun composant final, thème final ou pattern ne subsiste dans le package ;
- les couleurs primitives existent et restent internes ;
- les rôles de contenu, surface, bordure, action, feedback et état sont
  publics, documentés et complets ;
- `copyWith` couvre l'intégralité des rôles ;
- `lerp` est exact aux bornes 0 et 1 ;
- l'égalité et le `hashCode` sont cohérents ;
- l'utilitaire de contraste calcule luminance et ratio, et reste hors runtime ;
- les paires de contraste critiques sont testées sur les deux jeux de
  démonstration ;
- les contrats de contraste et la règle de non-dépendance à la couleur sont
  documentés ;
- l'ADR sur la relation avec `ColorScheme` existe ;
- l'evidence registry est mis à jour ;
- le catalogue présente les rôles ;
- `dart format`, `flutter analyze` et `flutter test` passent réellement sur le
  package et sur le catalogue.

---

## 8. Rapport final attendu

Structure identique à IUX-003 §36, complétée par :

- la liste du code retiré et la mission qui le recréera ;
- la liste des ruptures d'API ;
- l'état des critères d'acceptation de IUX-003 après remédiation.

---

# Rapport final

## Résumé

La couche sémantique exigée par IUX-003 est livrée : six groupes de rôles
immuables, une palette primitive interne, un outil de mesure de contraste
confiné aux tests, et une matrice de contraste vérifiée sur deux jeux de
démonstration. Le code hors périmètre a été retiré.

## Architecture retenue

```text
IuxPrimitiveColors   (interne, non exporté)
        ↓
IuxSemanticColors    (public — content, surface, border, action, feedback, state)
        ↓
Thèmes               (IUX-004)
        ↓
Composants           (IUX-008+)
```

## API publique ajoutée

`IuxContentColors`, `IuxSurfaceColors`, `IuxBorderColors`, `IuxActionColors`,
`IuxActionColorSet`, `IuxFeedbackRoleColors`, `IuxFeedbackColorSet`,
`IuxStateColors`, et `IuxSemanticColors` qui les compose.

Chaque type est `@immutable`, avec constructeur `const`, `copyWith` couvrant
tous ses champs, `lerp`, `==` et `hashCode`.

## Ruptures d'API

| Rupture | Raison |
| --- | --- |
| `IuxSemanticColors` passe de 10 champs plats à 6 groupes | les champs plats ne pouvaient exprimer ni les états d'action, ni les bordures de feedback |
| `IuxSemanticColors.fromColorScheme` retiré | inversait la dépendance ; voir ADR-0002 |
| `of()` lève une erreur au lieu de retomber silencieusement | un repli masquait une configuration invalide |
| Composants, thème, layout, actions, accessibilité, feedback retirés | hors périmètre ; voir CHANGELOG pour la mission propriétaire de chacun |

## Contraste

68 paires mesurées sur les deux jeux de démonstration, toutes conformes.
Deux choix ont été modifiés après mesure plutôt que d'abaisser un seuil :

- le survol assombrit en clair et éclaircit en sombre — la variante naïve
  mesurait 4,12:1 pour l'action principale ;
- le neutre médian a été calibré à `#7E8693` pour tenir 3:1 en contenu
  désactivé sur surface désactivée.

Détail dans `docs/accessibility/contrast-contracts.md`.

## Fichiers créés

- `packages/iux_flutter/lib/src/semantics/colors/` : primitives + 6 groupes
- `packages/iux_flutter/test/support/contrast.dart` et son test
- `packages/iux_flutter/test/support/demonstration_palettes.dart`
- `packages/iux_flutter/test/semantics/contrast_contracts_test.dart`
- `apps/catalog/lib/demonstration_palettes.dart`
- `docs/semantics/{content,surface,border,action,feedback,state}-roles.md`
- `docs/accessibility/{contrast-contracts,color-and-non-color-signals}.md`
- `docs/decisions/ADR-0002-semantic-colors-and-color-scheme.md`
- `docs/evidence/semantic-tokens-and-accessibility.md`

## Fichiers modifiés

`lib/iux_flutter.dart`, `lib/src/semantics/iux_semantic_colors.dart`,
`test/iux_flutter_test.dart`, `test/semantics/iux_semantic_colors_test.dart`,
`apps/catalog/lib/main.dart`, `apps/catalog/test/app_test.dart`,
`docs/README.md`, `docs/semantics/semantic-tokens.md`, `CHANGELOG.md`.

## Fichiers supprimés

`lib/src/{components,layout,actions,accessibility,feedback,themes}/`,
`test/{themes,feedback}/`, `docs/decisions/ADR-0002-semantic-theme-profiles.md`,
`docs/evidence/tokens-themes-accessibility-motion.md`.

## Dépendances

Aucune ajoutée. Flutter et Dart uniquement.

## Commandes exécutées

| Commande | Résultat réel |
| --- | --- |
| `dart format .` | 21 fichiers, 0 modifié |
| `flutter analyze` (package) | No issues found |
| `flutter test` (package) | 41 tests, tous passés |
| `flutter analyze` (catalogue) | No issues found |
| `flutter test` (catalogue) | 3 tests, tous passés |
| `flutter build apk --debug` | `app-debug.apk` construit |

## État des critères d'acceptation d'IUX-003 après remédiation

| Critère IUX-003 §35 | État |
| --- | --- |
| Rôles publics et documentés | rempli |
| Primitives internes | rempli |
| Aucun nom public lié à une teinte ou une marque | rempli, testé |
| Rôles contenu/surface/bordure/action/feedback | rempli |
| États principaux modélisés | rempli |
| `copyWith` et `lerp` fonctionnent | rempli, testé |
| Résolution depuis le thème | rempli, testé |
| Contrats de contraste documentés | rempli |
| Tests de contraste ciblés | rempli |
| Non-dépendance à la couleur documentée | rempli |
| Catalogue présente les rôles | rempli |
| Aucun composant final | rempli, testé |
| Analyse statique et tests | rempli |

## Limites et décisions différées

- Aucun thème n'existe : une application doit fournir son `IuxSemanticColors`
  jusqu'à IUX-004.
- Le mapping vers `ColorScheme` est différé à IUX-004 (ADR-0002).
- Les jeux de démonstration sont dupliqués entre les tests du package et le
  catalogue, parce qu'IUX-003 §22 interdit d'exporter un mapping de
  démonstration. Cette duplication disparaît avec IUX-004.
- Le contraste WCAG 2.x corrèle imparfaitement avec le contraste perçu ;
  APCA n'est pas adopté.
- Aucune validation manuelle (TalkBack, Voice Access, clavier, mise à
  l'échelle) n'a été réalisée : aucun composant n'existe encore.

## Prochaine mission

IUX-004 — moteur de thèmes accessibles. Elle peut désormais s'appuyer sur des
rôles complets et des contrats de contraste vérifiables.
