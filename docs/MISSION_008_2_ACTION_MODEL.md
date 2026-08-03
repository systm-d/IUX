---
mission_id: IUX-008.2
epic: IUX-008
title: Action Model
priority: critical
status: ready
target_version: 0.2.0-dev.2
compatibility: additive
depends_on:
  - IUX-001
  - IUX-002
  - IUX-003
  - IUX-004
  - IUX-005
  - IUX-006
  - IUX-007
  - IUX-008.1
platform_priority: Android
package_name: iux_flutter
---

# IUX-008.2 — Action Model

## 1. Références obligatoires

Avant toute action :

1. Lire intégralement `PROJECT_PROMPT.md`.
2. Lire intégralement `COMPONENT_STANDARD.md`.
3. Lire les missions IUX-001 à IUX-007.
4. Lire intégralement IUX-008.1.
5. Vérifier que toutes les missions précédentes ont été terminées et validées.
6. Ne pas modifier `d4-dark-ds`.
7. Ne créer aucun widget dans cette mission.
8. Ne créer aucun rendu visuel.
9. Ne commencer ni le thème des boutons ni le bouton lui-même.

En cas de conflit, `PROJECT_PROMPT.md` puis `COMPONENT_STANDARD.md` prévalent.

---

## 2. Contexte

IUX dispose désormais :

- de fondations ;
- de tokens sémantiques ;
- d’un moteur de thèmes ;
- d’un runtime d’accessibilité ;
- d’un moteur de mouvement et de feedback ;
- d’un système de layout ;
- d’un Component Standard officiel.

Cette mission ouvre l’epic IUX-008 consacré au système d’actions.

Avant de créer un bouton, il faut définir un modèle d’action commun, indépendant du rendu.

Ce modèle doit pouvoir être réutilisé ultérieurement par :

- boutons ;
- boutons icône ;
- actions de menu ;
- actions de toolbar ;
- actions de dialogue ;
- actions de snackbar ;
- actions asynchrones ;
- actions destructives ;
- actions de confirmation ;
- actions de navigation ;
- patterns UX.

---

## 3. Objectif utilisateur

Garantir que les actions proposées dans les applications IUX soient décrites de manière cohérente selon :

- leur intention ;
- leur importance ;
- leur rôle ;
- leur disponibilité ;
- leur état opérationnel ;
- leur réversibilité ;
- leur mode de confirmation ;
- leur feedback attendu.

L’utilisateur final doit pouvoir comprendre la différence entre une action principale, secondaire, destructive ou irréversible sans que chaque composant invente sa propre logique.

---

## 4. Objectifs de la mission

Cette mission doit :

1. Définir le modèle public d’une action IUX.
2. Définir les intentions d’action.
3. Définir l’importance d’une action.
4. Définir le rôle comportemental d’une action.
5. Définir la disponibilité d’une action.
6. Définir l’état opérationnel d’une action.
7. Définir la réversibilité d’une action.
8. Définir les politiques de confirmation.
9. Définir les politiques de répétition et de double activation.
10. Définir les métadonnées sémantiques nécessaires.
11. Définir les événements émis par une action.
12. Définir les invariants.
13. Empêcher ou détecter les combinaisons incohérentes.
14. Fournir des modèles immuables et testables.
15. Ajouter documentation, ADR, tests et exemples conceptuels.
16. Préparer IUX-008.3 consacré au thème des boutons.

---

## 5. Hors périmètre

Ne pas réaliser dans cette mission :

- `IuxButton` ;
- `IuxIconButton` ;
- `IuxAsyncButton` ;
- `IuxConfirmationButton` ;
- renderer ;
- animations ;
- style de bouton ;
- `ThemeExtension` de bouton ;
- couleurs de bouton ;
- formes de bouton ;
- élévation de bouton ;
- widget de chargement ;
- dialogue de confirmation ;
- snackbar ;
- logique réseau ;
- gestion d’état globale ;
- navigation ;
- persistance ;
- catalogue visuel complet.

Cette mission produit uniquement des modèles, contrats et règles.

---

## 6. Audit préalable obligatoire

Avant toute modification, inspecter :

- le modèle d’état défini ou prévu dans `COMPONENT_STANDARD.md` ;
- les enums d’interaction existants ;
- les états opérationnels déjà présents ;
- les tokens d’action de IUX-003 ;
- le moteur de feedback de IUX-006 ;
- le runtime d’accessibilité ;
- les conventions d’immutabilité ;
- les exports publics ;
- les tests ;
- les ADR ;
- les éventuels doublons de concepts.

Présenter :

- les types existants réutilisables ;
- les concepts manquants ;
- les risques de duplication ;
- les risques d’enums trop larges ;
- les risques de modèle trop abstrait ;
- les risques de couplage prématuré aux boutons.

---

## 7. Principes directeurs

Le modèle d’action doit être :

- indépendant du rendu ;
- indépendant de Material ;
- indépendant d’un widget ;
- fortement typé ;
- immuable ;
- composable ;
- explicite ;
- suffisamment simple pour le cas courant ;
- extensible sans casser l’API.

Il ne doit jamais décrire :

- une couleur ;
- une bordure ;
- une ombre ;
- une animation ;
- un rayon ;
- un style de marque.

---

## 8. Architecture cible

Structure indicative :

```text
packages/iux_flutter/lib/src/actions/
├── action_intent.dart
├── action_importance.dart
├── action_role.dart
├── action_availability.dart
├── action_operation.dart
├── action_reversibility.dart
├── action_confirmation.dart
├── action_repeat_policy.dart
├── action_semantics.dart
├── action_event.dart
├── action_descriptor.dart
├── action_invariants.dart
└── action_resolution.dart
```

Adapter si cette structure devient trop fragmentée.

Éviter une classe géante contenant tous les concepts.

---

## 9. Intention d’action

Créer un type public tel que :

```dart
enum IuxActionIntent {
  primary,
  secondary,
  tertiary,
  destructive,
  neutral,
}
```

Évaluer si `neutral` est réellement nécessaire.

Chaque intention doit être documentée.

### `primary`

Action principale d’un contexte donné.

Contraintes :

- une seule action primaire dominante par groupe logique ;
- ne signifie pas forcément action la plus fréquente de toute l’application ;
- ne doit pas être utilisée pour une action destructive uniquement pour attirer l’attention.

### `secondary`

Action importante mais non dominante.

### `tertiary`

Action discrète ou de faible priorité.

### `destructive`

Action susceptible de supprimer, altérer ou compromettre une donnée, un état ou un accès.

### `neutral`

Action sans priorité ni sémantique forte, uniquement si ce rôle apporte une vraie valeur.

---

## 10. Importance

Créer un type public tel que :

```dart
enum IuxActionImportance {
  high,
  medium,
  low,
}
```

L’importance décrit la priorité relative.

Elle ne doit pas être confondue avec l’intention.

Exemples :

- une action destructive peut avoir une importance faible ;
- une action secondaire peut avoir une importance élevée ;
- une action principale a souvent une importance élevée, mais pas toujours.

Documenter cette distinction.

---

## 11. Rôle comportemental

Créer un type décrivant le rôle de l’action dans le flux.

Exemple :

```dart
enum IuxActionRole {
  submit,
  confirm,
  cancel,
  dismiss,
  navigate,
  retry,
  undo,
  delete,
  edit,
  select,
  custom,
}
```

Évaluer le niveau de granularité.

Contraintes :

- éviter une liste infinie ;
- ne pas intégrer de rôles métier ;
- ne pas confondre rôle et libellé ;
- permettre `custom` seulement si nécessaire.

Le rôle peut aider :

- la sémantique ;
- le feedback ;
- les analytics applicatives futures ;
- les patterns UX ;
- la documentation.

---

## 12. Disponibilité

Créer une dimension séparée.

Exemple :

```dart
enum IuxActionAvailability {
  enabled,
  disabled,
  readOnly,
}
```

Évaluer si `readOnly` est pertinent pour une action.

Une action `disabled` :

- ne peut pas être activée ;
- ne doit pas émettre d’événement ;
- ne doit pas produire de feedback d’activation ;
- reste compréhensible ;
- peut fournir une raison d’indisponibilité via sémantique ou aide.

Ne pas utiliser `null` comme seul modèle de disponibilité si un type explicite apporte une vraie valeur.

---

## 13. État opérationnel

Créer une dimension distincte de l’interaction.

Exemple :

```dart
sealed class IuxActionOperation {
  const IuxActionOperation();
}

final class IuxActionIdle extends IuxActionOperation {}

final class IuxActionInProgress extends IuxActionOperation {}

final class IuxActionSucceeded extends IuxActionOperation {}

final class IuxActionFailed extends IuxActionOperation {}
```

ou une API plus simple.

Évaluer :

- enum ;
- sealed class ;
- objet avec données.

Les états succès et erreur peuvent nécessiter :

- identifiant ;
- message sémantique ;
- erreur ;
- possibilité de retry ;
- timestamp.

Ne pas transporter de logique métier complète.

---

## 14. État interactif

Réutiliser les types définis dans les fondations ou le Component Standard.

Ne pas recréer un enum spécifique aux actions si un modèle générique existe déjà.

Les états interactifs peuvent inclure :

- idle ;
- hovered ;
- focused ;
- pressed.

Ils doivent rester internes au rendu ou au runtime.

Le parent ne doit généralement pas avoir à les contrôler.

---

## 15. Réversibilité

Créer un type public tel que :

```dart
enum IuxActionReversibility {
  reversible,
  difficultToReverse,
  irreversible,
}
```

Définition :

### `reversible`

L’utilisateur peut facilement revenir en arrière.

Exemples :

- changement de filtre ;
- archivage avec undo ;
- sélection.

### `difficultToReverse`

Un retour est possible mais coûteux, indirect ou non immédiat.

Exemples :

- réinitialisation complexe ;
- déplacement de données ;
- modification à conséquences multiples.

### `irreversible`

Aucun retour raisonnable n’est possible.

Exemples :

- suppression définitive ;
- révocation irréversible ;
- envoi définitif selon contexte.

Cette dimension doit pouvoir influencer les patterns futurs, mais pas déclencher automatiquement une UI dans cette mission.

---

## 16. Politique de confirmation

Créer un modèle explicite.

Exemple :

```dart
sealed class IuxConfirmationPolicy {
  const IuxConfirmationPolicy();
}

final class IuxNoConfirmation extends IuxConfirmationPolicy {}

final class IuxConfirmBeforeExecution extends IuxConfirmationPolicy {}

final class IuxConfirmByHold extends IuxConfirmationPolicy {}

final class IuxConfirmByDoubleActivation extends IuxConfirmationPolicy {}
```

Évaluer les politiques réellement nécessaires.

Contraintes :

- pas de confirmation obligatoire pour toutes les actions destructives ;
- tenir compte de la réversibilité ;
- ne pas imposer un dialogue ;
- permettre au parent de décider ;
- documenter les anti-patterns.

---

## 17. Politique de répétition

Créer un type définissant les activations répétées.

Exemple :

```dart
enum IuxActionRepeatPolicy {
  allow,
  ignoreWhileInProgress,
  debounce,
  throttle,
}
```

Évaluer si `debounce` et `throttle` appartiennent réellement au modèle public.

Le cas courant doit être :

```dart
ignoreWhileInProgress
```

pour les actions asynchrones.

Ne pas inclure de durée arbitraire dans un enum.

Une configuration séparée peut être nécessaire.

---

## 18. Double activation

Définir clairement la règle.

Une action doit pouvoir préciser :

- si une seconde activation est autorisée ;
- si elle est ignorée ;
- si elle annule la première ;
- si elle doit être mise en file ;
- si elle produit un feedback.

Le modèle ne doit pas implémenter la logique.

Il doit uniquement décrire la politique.

---

## 19. Annulation

Évaluer un modèle pour les actions annulables.

Exemple :

```dart
enum IuxActionCancellation {
  notSupported,
  supported,
  required,
}
```

ou une propriété sur l’opération.

Ne pas sur-modéliser si la mission IUX-008.6 doit gérer ce sujet plus tard.

Documenter ce qui est différé.

---

## 20. Métadonnées sémantiques

Créer un objet dédié.

Exemple :

```dart
final class IuxActionSemantics {
  final String? label;
  final String? hint;
  final String? disabledReason;
  final String? progressLabel;
  final String? successLabel;
  final String? errorLabel;
}
```

Contraintes :

- aucun texte métier par défaut ;
- aucune chaîne anglaise codée en dur ;
- localisation fournie par l’application ;
- pas de duplication du libellé visuel sans nécessité ;
- messages courts et utiles.

Évaluer si ce modèle doit rester public ou interne.

---

## 21. Descripteur d’action

Créer un modèle central tel que :

```dart
final class IuxActionDescriptor {
  final IuxActionIntent intent;
  final IuxActionImportance importance;
  final IuxActionRole role;
  final IuxActionAvailability availability;
  final IuxActionOperation operation;
  final IuxActionReversibility reversibility;
  final IuxConfirmationPolicy confirmation;
  final IuxActionRepeatPolicy repeatPolicy;
  final IuxActionSemantics semantics;
}
```

Le nom peut évoluer.

Ce descripteur doit :

- être immuable ;
- avoir des valeurs par défaut ;
- être `const` si possible ;
- fournir `copyWith` ;
- valider ses invariants ;
- ne contenir aucun rendu.

Évaluer si tous les champs doivent être obligatoires.

---

## 22. API simple pour le cas courant

Le cas courant ne doit pas exiger un objet énorme.

Prévoir des constructeurs ou factories comme :

```dart
IuxActionDescriptor.primary()
IuxActionDescriptor.secondary()
IuxActionDescriptor.destructive()
```

ou une API plus concise.

Ne pas multiplier les factories inutiles.

Exemple attendu :

```dart
const action = IuxActionDescriptor(
  intent: IuxActionIntent.primary,
  role: IuxActionRole.submit,
);
```

---

## 23. Invariants

Définir des invariants explicites.

Exemples :

- une action disabled ne peut pas être inProgress ;
- une action idle peut être enabled ou disabled ;
- une action irreversible ne doit pas avoir une politique d’undo implicite ;
- une action confirmByHold doit être enabled ;
- une action succeeded ne peut pas être pressed ;
- une action destructive n’est pas forcément irreversible ;
- une action primary n’est pas forcément submit.

Les invariants doivent être :

- testés ;
- documentés ;
- vérifiés en debug ;
- appliqués sans correction silencieuse.

---

## 24. Combinaisons invalides

Créer une stratégie claire :

- assertion ;
- exception de configuration ;
- résultat de validation ;
- factory empêchant la construction.

Privilégier la détection à la compilation lorsque possible.

Sinon, utiliser des assertions précises.

Les messages doivent expliquer :

- la combinaison invalide ;
- la raison ;
- la correction attendue.

---

## 25. Validation

Évaluer un type tel que :

```dart
final class IuxActionValidationResult {
  final bool isValid;
  final List<IuxActionViolation> violations;
}
```

Ne le créer que s’il apporte une valeur réelle aux tests, au catalogue ou aux outils développeur.

Éviter d’alourdir le runtime.

---

## 26. Événements d’action

Créer un modèle d’événement typé.

Exemple :

```dart
sealed class IuxActionEvent {
  const IuxActionEvent();
}

final class IuxActionInvoked extends IuxActionEvent {}

final class IuxActionBlocked extends IuxActionEvent {}

final class IuxActionCancelled extends IuxActionEvent {}

final class IuxActionRetried extends IuxActionEvent {}
```

Évaluer les événements nécessaires.

Les événements doivent :

- rester indépendants du widget ;
- ne pas contenir de logique métier ;
- être utilisables par le feedback ;
- être testables.

---

## 27. Événement bloqué

Une action bloquée peut produire un événement expliquant :

- disabled ;
- alreadyInProgress ;
- confirmationRequired ;
- invalidState ;
- throttled.

Créer un motif typé si nécessaire.

Ne pas déclencher automatiquement un feedback dans cette mission.

---

## 28. Résolution future

Préparer une fonction ou un contrat permettant aux futures couches de résoudre :

```text
Action Descriptor
    ↓
Button Theme
    ↓
Button State
    ↓
Render Model
```

Cette mission ne doit pas implémenter le rendu.

Elle peut définir une interface ou un objet de résolution si cela réduit le couplage.

---

## 29. Relation avec le feedback

Le modèle doit permettre au moteur de feedback de comprendre :

- rôle ;
- intention ;
- opération ;
- succès ;
- erreur ;
- destruction ;
- blocage.

Ne pas appeler le feedback directement.

---

## 30. Relation avec l’accessibilité

Le modèle doit fournir les informations nécessaires à :

- rôle sémantique ;
- état disabled ;
- état loading ;
- état success ;
- état error ;
- confirmation ;
- raison de blocage.

Le modèle ne doit pas dépendre de `BuildContext`.

---

## 31. Relation avec le thème

Le thème futur doit pouvoir résoudre un style depuis :

- intent ;
- importance ;
- availability ;
- operation ;
- interaction.

Le modèle ne contient aucune couleur.

---

## 32. Relation avec le runtime

Le runtime futur utilisera le modèle pour :

- valider ;
- résoudre ;
- annoncer ;
- produire du feedback ;
- appliquer les politiques de répétition.

Cette mission ne doit pas créer de service global.

---

## 33. Immutabilité

Tous les modèles doivent être immuables.

Utiliser :

- champs `final` ;
- constructeurs `const` ;
- sealed classes si pertinent ;
- `copyWith` ;
- égalité ;
- `hashCode`.

Ne pas ajouter une dépendance externe d’égalité sans justification.

---

## 34. Sérialisation

Ne pas ajouter de sérialisation JSON par défaut.

Le modèle est un contrat runtime, pas une donnée persistée.

Documenter ce choix.

---

## 35. Extensibilité

L’API doit pouvoir évoluer sans casser les usages courants.

Éviter :

- enum unique impossible à étendre ;
- constructeur avec trop de paramètres obligatoires ;
- champ `dynamic` ;
- map de configuration ;
- chaînes magiques.

---

## 36. Documentation Dart

Chaque type public doit documenter :

- son intention ;
- ses valeurs ;
- ses limites ;
- ses relations avec les autres dimensions ;
- les anti-patterns ;
- les exemples.

---

## 37. Documentation conceptuelle

Créer au minimum :

```text
docs/actions/overview.md
docs/actions/intent.md
docs/actions/importance.md
docs/actions/roles.md
docs/actions/reversibility.md
docs/actions/confirmation.md
docs/actions/repeat-policy.md
docs/actions/state-model.md
docs/actions/semantics.md
```

Adapter si certains documents doivent être regroupés.

Chaque document doit inclure :

- intention ;
- API ;
- exemples ;
- contre-exemples ;
- règles ;
- limites ;
- accessibilité ;
- niveau de preuve ;
- sources.

---

## 38. ADR

Créer au minimum :

```text
docs/decisions/ADR-0009-action-model.md
docs/decisions/ADR-0010-action-state-dimensions.md
```

Inclure :

- contexte ;
- décision ;
- alternatives ;
- conséquences ;
- risques ;
- statut.

---

## 39. Evidence Registry

Ajouter des entrées pour :

- action primaire ;
- hiérarchie des actions ;
- actions destructives ;
- confirmation ;
- réversibilité ;
- double activation ;
- feedback de blocage ;
- disabled state ;
- loading state.

Ne pas inventer de source.

Marquer clairement les hypothèses.

---

## 40. Tests unitaires

Tester :

### Intent

- valeurs ;
- documentation contractuelle si testable ;
- distinction primary/secondary/destructive.

### Importance

- valeurs ;
- indépendance vis-à-vis de l’intention.

### Rôle

- rôles disponibles ;
- absence de rôles métier.

### Réversibilité

- valeurs ;
- invariants.

### Confirmation

- politiques ;
- compatibilité avec réversibilité.

### Répétition

- politiques ;
- compatibilité avec opération.

### Descripteur

- valeurs par défaut ;
- `copyWith` ;
- égalité ;
- hashCode ;
- constructeurs ;
- factories.

### Opération

- idle ;
- inProgress ;
- succeeded ;
- failed ;
- données optionnelles.

---

## 41. Tests d’invariants

Tester au minimum :

- disabled + inProgress ;
- irreversible + undo implicite ;
- confirmation hold + disabled ;
- succeeded + pressed si modélisé ;
- failed sans données si autorisé ;
- primary + destructive ;
- secondary + high importance ;
- destructive + reversible.

Certaines combinaisons doivent être autorisées.

Ne pas interdire des cas valides par simplification excessive.

---

## 42. Tests de contrat

Garantir que :

- aucun widget n’est créé ;
- aucun import Material de rendu n’est nécessaire ;
- aucune couleur n’est présente ;
- aucun `BuildContext` n’est utilisé ;
- aucune logique métier n’est exécutée ;
- les modèles sont immuables ;
- le barrel public expose uniquement les contrats stables ;
- les composants futurs peuvent consommer le modèle.

---

## 43. Catalogue

Ne pas créer de catalogue visuel de boutons.

Ajouter uniquement une section conceptuelle ou développeur présentant :

- intentions ;
- importance ;
- rôle ;
- disponibilité ;
- opération ;
- réversibilité ;
- confirmation ;
- répétition ;
- combinaisons valides ;
- combinaisons invalides.

Utiliser des tableaux, textes et exemples de code.

---

## 44. Exemples attendus

Documenter au minimum :

### Action primaire simple

```dart
const IuxActionDescriptor(
  intent: IuxActionIntent.primary,
  role: IuxActionRole.submit,
);
```

### Action destructive réversible

```dart
const IuxActionDescriptor(
  intent: IuxActionIntent.destructive,
  role: IuxActionRole.delete,
  reversibility: IuxActionReversibility.reversible,
);
```

### Action irréversible avec confirmation

```dart
const IuxActionDescriptor(
  intent: IuxActionIntent.destructive,
  reversibility: IuxActionReversibility.irreversible,
  confirmation: IuxConfirmationPolicy.beforeExecution(),
);
```

Adapter selon l’API finale.

---

## 45. Dépendances

Ne pas ajouter de dépendance externe sauf nécessité absolue.

Le modèle doit idéalement utiliser uniquement Dart.

Toute dépendance doit être justifiée selon :

- maintenance ;
- licence ;
- poids ;
- alternatives ;
- valeur immédiate.

---

## 46. Performance

Les modèles doivent être légers.

Préférer :

- objets `const` ;
- égalité simple ;
- aucune allocation inutile ;
- aucune validation coûteuse au runtime ;
- aucun lookup par chaîne ;
- aucune réflexion.

---

## 47. Compatibilité

Cette mission est additive.

Ne pas casser :

- le Component Standard ;
- les fondations ;
- le runtime ;
- les thèmes ;
- les tests ;
- les exports publics.

Toute évolution d’un type existant doit être justifiée.

---

## 48. API publique

Mettre à jour le point d’entrée public pour exporter uniquement :

- `IuxActionIntent` ;
- `IuxActionImportance` ;
- `IuxActionRole` ;
- `IuxActionAvailability` ;
- `IuxActionOperation` ;
- `IuxActionReversibility` ;
- `IuxConfirmationPolicy` ;
- `IuxActionRepeatPolicy` ;
- `IuxActionSemantics` si public ;
- `IuxActionDescriptor` ;
- `IuxActionEvent` si public.

Ne pas exporter :

- validateurs internes ;
- helpers temporaires ;
- détails d’implémentation ;
- outils de test.

---

## 49. Commandes de validation

Exécuter :

```bash
dart format .
flutter analyze
flutter test
```

Vérifier le catalogue si modifié :

```bash
flutter run
```

Ne pas déclarer une réussite sans exécution réelle.

---

## 50. Livrables obligatoires

À la fin de cette mission, fournir :

- modèle d’intention ;
- modèle d’importance ;
- modèle de rôle ;
- modèle de disponibilité ;
- modèle opérationnel ;
- modèle de réversibilité ;
- politique de confirmation ;
- politique de répétition ;
- métadonnées sémantiques ;
- descripteur d’action ;
- événements d’action ;
- invariants ;
- tests ;
- documentation ;
- ADR ;
- evidence registry ;
- catalogue conceptuel mis à jour ;
- résultats de validation ;
- liste des fichiers créés et modifiés ;
- limites et décisions différées.

---

## 51. Critères d’acceptation

La mission est terminée uniquement si :

- aucun widget n’est créé ;
- aucun rendu n’est créé ;
- les intentions sont typées ;
- l’importance est séparée de l’intention ;
- la réversibilité est modélisée ;
- la confirmation est modélisée ;
- la répétition est modélisée ;
- les états opérationnels sont séparés des états interactifs ;
- les invariants sont testés ;
- les combinaisons valides ne sont pas bloquées inutilement ;
- les modèles sont immuables ;
- l’API est documentée ;
- les futurs boutons peuvent consommer ces modèles ;
- `flutter analyze` ne retourne aucune erreur ;
- `flutter test` réussit.

---

## 52. Rapport final attendu

Répondre avec cette structure :

### Résumé

Décrire le modèle d’action créé.

### Audit initial

Présenter l’état du projet avant modification.

### Architecture retenue

Expliquer les dimensions du modèle.

### API publique

Lister les types publics ajoutés.

### Intentions et rôles

Présenter les distinctions.

### États et réversibilité

Présenter le modèle opérationnel et les invariants.

### Confirmation et répétition

Présenter les politiques.

### Accessibilité et sémantique

Présenter les métadonnées disponibles.

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

- thème de bouton non encore créé ;
- widget non encore créé ;
- logique async différée ;
- confirmation UI différée ;
- feedback runtime différé ;
- sources restant à vérifier.

### Prochaine mission recommandée

Indiquer que la prochaine étape logique est IUX-008.3 — Button Theme.

---

## 53. Instruction finale

Commence par auditer le résultat réel des missions précédentes et du `COMPONENT_STANDARD.md`.

Présente ensuite un plan court et concret.

Puis implémente uniquement le modèle d’action.

Ne crée aucun widget.

Ne crée aucun thème de bouton.

