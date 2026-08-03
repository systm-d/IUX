---
mission_id: IUX-001
title: Initialisation du dépôt et fondations techniques
priority: critical
status: completed
started_at: 2026-08-01
started_by: Codex
last_updated_at: 2026-08-01
completion_status: accepted
validation_status: passed
target_version: 0.1.0-dev.1
compatibility: new_project
depends_on: []
platform_priority: Android
package_name: iux_flutter
---

# IUX-001 — Initialisation du dépôt et fondations techniques

## 1. Références obligatoires

Avant toute action :

1. Lire intégralement `PROJECT_PROMPT.md`.
2. Considérer ce document comme la mission active.
3. Ne pas consulter ni modifier le dépôt `d4-dark-ds`.
4. Ne pas réutiliser automatiquement son code, son architecture, ses composants ou son identité visuelle.
5. Traiter IUX comme un nouveau projet indépendant.

En cas de conflit, `PROJECT_PROMPT.md` prévaut.

---

## 2. Contexte

IUX, pour **Intuitive UX**, est un nouveau framework Flutter centré sur l’humain.

Il vise à aider les développeurs à créer des applications mobiles :

- accessibles ;
- compréhensibles ;
- cohérentes ;
- robustes ;
- sobres ;
- faciles à utiliser ;
- adaptées en priorité aux appareils Android.

IUX ne doit pas être conçu comme une simple collection de widgets esthétiques.

Cette première mission ne doit produire aucun composant utilisateur final. Elle doit uniquement établir une base technique propre, stable et extensible pour les missions suivantes.

---

## 3. Objectif utilisateur

Créer une fondation technique fiable afin que les futurs composants IUX puissent être développés sans dette structurelle prématurée, sans dépendance à une identité graphique et sans incohérence entre packages, documentation, tests et catalogue.

---

## 4. Objectifs de la mission

Cette mission doit :

1. Initialiser le nouveau dépôt IUX.
2. Créer le package Flutter principal `iux_flutter`.
3. Mettre en place une architecture claire par responsabilités.
4. Configurer l’analyse statique, le formatage et les tests.
5. Créer une application catalogue minimale.
6. Préparer les espaces de documentation et de recherche.
7. Définir les conventions initiales du dépôt.
8. Vérifier que le projet compile et que les tests de base passent.
9. Documenter la manière de travailler localement.
10. Produire un rapport d’implémentation complet.

---

## 5. Hors périmètre

Ne pas réaliser dans cette mission :

- de bouton ;
- de champ de formulaire ;
- de carte ;
- de dialogue ;
- de système de navigation ;
- de pattern UX ;
- de thème visuel final ;
- de palette définitive ;
- de tokens sémantiques définitifs ;
- de moteur d’accessibilité complet ;
- de générateur de code ;
- de package de lint personnalisé ;
- de publication sur `pub.dev` ;
- de migration depuis `d4-dark-ds` ;
- de refonte ou modification de `d4-dark-ds`.

Ne pas créer de faux composants temporaires qui devraient être supprimés ensuite.

---

## 6. Audit préalable obligatoire

Avant toute modification, inspecter le contenu réel du dépôt courant.

Présenter brièvement :

- les fichiers déjà présents ;
- l’état Git ;
- la présence éventuelle d’un projet Flutter existant ;
- les versions disponibles de Flutter et Dart ;
- les contraintes détectées dans l’environnement ;
- les risques de collision avec des fichiers existants.

Ne pas supposer que le dépôt est vide.

Si une structure existe déjà, proposer une adaptation minimale et cohérente plutôt qu’un écrasement.

### Résultat de l'audit du 2026-08-01

- Le dépôt contenait les prompts de projet et les Mission Prompts, sans projet
  Flutter, package ou application existants.
- Le dossier `.git` était présent mais vide, en lecture seule, et `git status`
  ne le reconnaissait pas comme un dépôt. Il n'a pas été écrasé.
- Les exécutables Flutter et Dart disponibles via Snap ne pouvaient pas démarrer
  : `timeout waiting for snap system profiles to get updated`.
- Aucun fichier existant n'entrait en collision avec la structure créée.
- La validation Flutter, la génération des plateformes hôtes et
  l'initialisation effective de Git restent bloquées par ces contraintes.

---

## 7. Structure cible du dépôt

Créer ou préparer une structure proche de celle-ci :

```text
iux/
├── apps/
│   └── catalog/
├── packages/
│   └── iux_flutter/
├── docs/
│   ├── architecture/
│   ├── accessibility/
│   ├── components/
│   ├── foundations/
│   ├── patterns/
│   └── decisions/
├── research/
│   ├── accessibility/
│   ├── android/
│   ├── hci/
│   └── ux/
├── tools/
├── PROJECT_PROMPT.md
├── MISSION_PROMPT_TEMPLATE.md
├── README.md
├── CHANGELOG.md
├── CONTRIBUTING.md
├── LICENSE
└── .gitignore
```

Cette structure est une cible, pas une obligation aveugle.

Adapter uniquement si l’environnement ou les outils Flutter imposent une meilleure organisation. Toute adaptation doit être justifiée.

---

## 8. Structure cible du package `iux_flutter`

Créer le package principal dans :

```text
packages/iux_flutter/
```

Structure attendue :

```text
packages/iux_flutter/
├── lib/
│   ├── iux_flutter.dart
│   └── src/
│       ├── accessibility/
│       ├── components/
│       ├── foundations/
│       ├── interactions/
│       ├── motion/
│       ├── patterns/
│       ├── semantics/
│       ├── testing/
│       ├── themes/
│       └── utilities/
├── test/
├── pubspec.yaml
├── README.md
├── CHANGELOG.md
└── analysis_options.yaml
```

Les dossiers vides ne doivent pas être artificiellement remplis avec du code inutile.

Lorsque Git ne conserve pas les dossiers vides, utiliser un fichier documentaire local uniquement si cela apporte une valeur réelle, ou créer les dossiers au moment où ils deviennent nécessaires.

---

## 9. Package public

Le package Flutter doit être nommé :

```yaml
name: iux_flutter
```

Le point d’entrée public doit être :

```dart
import 'package:iux_flutter/iux_flutter.dart';
```

Le fichier `lib/iux_flutter.dart` doit rester minimal.

À cette étape, il peut n’exporter qu’une API de version ou une fondation technique strictement nécessaire au smoke test.

Ne pas inventer d’API publique future pour remplir le barrel export.

---

## 10. Version initiale

Utiliser une version de développement cohérente, par exemple :

```yaml
version: 0.1.0-dev.1
```

La version exacte peut être adaptée si l’écosystème choisi impose une autre convention, mais le projet ne doit pas être présenté comme stable.

---

## 11. Compatibilité Flutter et Dart

Utiliser la version Flutter stable disponible dans l’environnement.

Définir des contraintes SDK réalistes dans `pubspec.yaml`.

Ne pas déclarer une version plus récente que celle réellement disponible.

Documenter :

- la version Flutter utilisée ;
- la version Dart utilisée ;
- la commande permettant de les vérifier ;
- les éventuelles contraintes Android.

---

## 12. Dépendances

La première mission doit limiter les dépendances.

Le package `iux_flutter` doit idéalement dépendre uniquement de :

```yaml
flutter:
  sdk: flutter
```

Toute dépendance supplémentaire doit être :

- nécessaire à la mission ;
- activement maintenue ;
- compatible avec la licence du projet ;
- justifiée dans le rapport final.

Ne pas ajouter Widgetbook ou un outil équivalent au package principal.

Les outils de catalogue doivent rester dans l’application dédiée.

---

## 13. Catalogue minimal

Créer une application Flutter dans :

```text
apps/catalog/
```

Son objectif initial est uniquement de vérifier l’intégration locale du package.

Elle doit :

- dépendre de `iux_flutter` par chemin local ;
- compiler ;
- afficher un écran minimal ;
- confirmer visuellement que le package est correctement importé ;
- ne pas inventer de composant IUX final.

Un simple écran d’accueil présentant le nom, la version et l’état du projet est suffisant.

Ne pas construire le catalogue complet dans cette mission.

---

## 14. Documentation racine

### `README.md`

Le README racine doit expliquer :

- ce qu’est IUX ;
- ce que IUX n’est pas ;
- son statut expérimental ;
- la plateforme prioritaire ;
- la structure du dépôt ;
- comment installer les dépendances ;
- comment exécuter les tests ;
- comment lancer le catalogue ;
- où trouver `PROJECT_PROMPT.md`.

Ne pas faire de promesses non vérifiées telles que :

- « accessible par défaut » ;
- « scientifiquement prouvé » ;
- « intuitif pour tout le monde » ;
- « conforme WCAG » sans audit complet.

Préférer des formulations comme :

> IUX fournit des fondations accessibles et des choix par défaut plus sûrs, à valider dans le contexte de chaque application.

### `CONTRIBUTING.md`

Documenter au minimum :

- l’ordre de lecture des documents ;
- la nécessité d’un Mission Prompt ;
- les commandes de validation ;
- les conventions de branche et de commit si elles sont définies ;
- la définition de terminé.

### `CHANGELOG.md`

Créer un changelog initial indiquant l’initialisation du dépôt.

### `LICENSE`

Ne pas choisir silencieusement une licence.

Si la licence n’est pas déjà décidée, créer un fichier ou une note explicite indiquant que la décision est en attente, puis signaler ce point dans le rapport final.

Ne jamais inventer l’autorisation de publier sous une licence spécifique.

---

## 15. Documentation d’architecture

Créer au minimum :

```text
docs/architecture/repository-structure.md
```

Ce document doit expliquer :

- pourquoi le dépôt est organisé en monorepo ;
- le rôle de `apps/` ;
- le rôle de `packages/` ;
- le rôle de `docs/` ;
- le rôle de `research/` ;
- la direction autorisée des dépendances ;
- la séparation entre package, catalogue et documentation.

Créer également une première décision d’architecture :

```text
docs/decisions/ADR-0001-repository-structure.md
```

Elle doit contenir :

- contexte ;
- décision ;
- alternatives considérées ;
- conséquences ;
- statut.

---

## 16. Analyse statique

Configurer une analyse statique stricte mais pragmatique.

Les règles doivent favoriser :

- `const` lorsque pertinent ;
- API documentées ;
- imports propres ;
- immutabilité ;
- absence de code mort ;
- sécurité des types ;
- lisibilité.

Ne pas activer une quantité excessive de règles contradictoires ou bruyantes.

Documenter tout assouplissement significatif.

---

## 17. Formatage

Le projet doit utiliser le formatage Dart standard.

Commande attendue :

```bash
dart format .
```

Aucun formatteur alternatif ne doit être introduit.

---

## 18. Tests initiaux

Créer au minimum :

1. Un smoke test du package.
2. Un test vérifiant que le point d’entrée public est importable.
3. Un test minimal du catalogue si pertinent.
4. Un test de version ou de métadonnée seulement si une telle API est réellement utile.

Éviter les tests artificiels ne validant aucun contrat réel.

---

## 19. API de version

Évaluer si une API légère telle que celle-ci apporte une valeur réelle :

```dart
abstract final class Iux {
  static const packageName = 'iux_flutter';
  static const version = '0.1.0-dev.1';
}
```

Ne l’implémenter que si elle est utile au catalogue, aux diagnostics ou à la documentation.

Si elle est créée :

- la documenter ;
- la tester ;
- éviter la duplication incontrôlée de la version avec `pubspec.yaml` ;
- expliquer le compromis.

Une simple constante temporaire non maintenable ne doit pas être ajoutée.

---

## 20. Gestion du monorepo

Évaluer si un outil de monorepo est nécessaire dès cette première mission.

Par défaut :

- ne pas ajouter d’outil externe si les commandes Flutter standard suffisent ;
- documenter les commandes par package ;
- différer l’adoption d’un orchestrateur tant qu’il n’existe qu’un package et une application.

Si un outil est retenu, justifier précisément son bénéfice immédiat.

---

## 21. Git et fichiers ignorés

Créer un `.gitignore` adapté à :

- Flutter ;
- Dart ;
- Android ;
- IDE courants ;
- fichiers générés ;
- caches ;
- builds ;
- secrets locaux.

Ne pas ignorer :

- les fichiers de verrouillage qui doivent être versionnés selon le type de package ;
- la documentation ;
- les configurations nécessaires au build.

Documenter la stratégie retenue pour les `pubspec.lock`.

---

## 22. CI minimale

Évaluer l’ajout d’une CI minimale.

Si la plateforme Git distante est GitHub, créer éventuellement un workflow initial réalisant :

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

La CI doit :

- utiliser une version Flutter explicite ;
- mettre en cache uniquement lorsque cela reste simple ;
- ne pas publier de package ;
- ne pas effectuer de release.

Si l’environnement ne permet pas de configurer correctement la CI, documenter le workflow recommandé sans prétendre qu’il a été validé.

---

## 23. Sécurité et confidentialité

Vérifier qu’aucun secret, token, chemin local ou fichier sensible n’est ajouté.

Ne pas introduire :

- clé API ;
- certificat ;
- keystore ;
- identifiant personnel ;
- configuration privée.

---

## 24. Conventions de nommage initiales

Utiliser :

- `Iux` comme préfixe des types publics ;
- `iux_` pour les packages éventuels ;
- `snake_case` pour les fichiers Dart ;
- des noms fondés sur les responsabilités ;
- aucun préfixe graphique ou lié à une marque.

Exemples acceptables :

```dart
IuxTheme
IuxSpacing
IuxActionIntent
```

Exemples interdits :

```dart
IUXTheme
IuxNeonTheme
IuxPrettyButton
D4IuxTheme
```

À cette étape, ne créer que les types réellement nécessaires.

---

## 25. Qualité attendue

Le code doit :

- être idiomatique ;
- utiliser la null safety ;
- éviter les abstractions prématurées ;
- rester minimal ;
- être documenté lorsqu’il est public ;
- ne contenir aucun TODO vague ;
- ne contenir aucun code copié inutilement ;
- ne contenir aucune identité visuelle définitive.

---

## 26. Commandes de validation

Exécuter, depuis les emplacements appropriés :

```bash
dart format .
flutter analyze
flutter test
```

Lancer également le catalogue ou au minimum vérifier son build :

```bash
flutter run
```

ou :

```bash
flutter build apk --debug
```

selon ce que permet l’environnement.

Ne jamais déclarer une commande réussie sans l’avoir exécutée.

---

## 27. Livrables obligatoires

À la fin de cette mission, fournir :

- le dépôt initialisé ;
- le package `iux_flutter` ;
- l’application `catalog` minimale ;
- les fichiers de configuration ;
- le README racine ;
- le README du package ;
- le changelog ;
- le guide de contribution ;
- la documentation d’architecture ;
- l’ADR initial ;
- les tests smoke ;
- le résultat des commandes de validation ;
- la liste des fichiers créés et modifiés ;
- les limites restantes ;
- les décisions différées.

---

## 28. Critères d’acceptation

La mission est terminée uniquement si :

- le dépôt `d4-dark-ds` n’a pas été modifié ;
- `iux_flutter` est un nouveau package indépendant ;
- le package est importable depuis le catalogue ;
- le projet compile ;
- `dart format` réussit ;
- `flutter analyze` ne retourne aucune erreur ;
- `flutter test` réussit ;
- l’architecture est documentée ;
- aucun composant fonctionnel final n’a été créé ;
- aucune identité graphique n’a été imposée ;
- les dépendances sont minimales ;
- les limites et décisions ouvertes sont explicitement signalées.

---

## 29. Rapport final attendu

Répondre avec cette structure :

### Résumé

Décrire ce qui a été initialisé.

### Audit initial

Présenter l’état du dépôt avant modification.

### Architecture retenue

Expliquer la structure et les responsabilités.

### Fichiers créés et modifiés

Lister précisément les fichiers.

### Dépendances

Lister et justifier chaque dépendance ajoutée.

### Commandes exécutées

Indiquer chaque commande et son résultat réel.

### Tests

Présenter les tests créés et leurs résultats.

### Décisions d’architecture

Résumer les ADR et compromis.

### Limites et décisions différées

Signaler notamment :

- la licence si non décidée ;
- l’outil de monorepo si différé ;
- la CI si non validée ;
- les futures fondations non encore implémentées.

### Prochaine mission recommandée

Indiquer que la prochaine étape logique est la mission consacrée aux fondations.

---

## 30. Instruction finale

Commence par l’audit du dépôt.

Présente ensuite un plan d’implémentation court et concret.

Puis réalise cette mission dans son intégralité.

Ne crée encore aucun composant final IUX.
