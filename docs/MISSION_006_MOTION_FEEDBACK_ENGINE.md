---
mission_id: IUX-006
title: Moteur de mouvement et de feedback
priority: critical
status: ready
target_version: 0.1.0-dev.6
compatibility: additive
depends_on:
  - IUX-001
  - IUX-002
  - IUX-003
  - IUX-004
  - IUX-005
platform_priority: Android
package_name: iux_flutter
---

# IUX-006 — Moteur de mouvement et de feedback

## 1. Références obligatoires

Avant toute action :

1. Lire intégralement `PROJECT_PROMPT.md`.
2. Lire intégralement les missions IUX-001 à IUX-005.
3. Vérifier que les missions précédentes ont été terminées et validées.
4. Lire intégralement ce document.
5. Considérer ce document comme la seule mission active.
6. Ne pas modifier le dépôt `d4-dark-ds`.
7. Ne pas commencer les composants finaux.
8. Réutiliser l’infrastructure d’accessibilité créée en IUX-005.
9. Réutiliser le moteur de thèmes et les préférences de mouvement créés en IUX-004.

En cas de conflit, `PROJECT_PROMPT.md` prévaut.

---

## 2. Contexte

IUX possède désormais :

- une architecture initiale ;
- des fondations de design et d’interaction ;
- des tokens sémantiques ;
- un moteur de thèmes accessibles ;
- un runtime d’accessibilité.

Cette mission doit construire une infrastructure commune de mouvement et de feedback.

Le mouvement ne doit jamais être considéré comme une décoration automatique.

Il doit uniquement servir à :

- expliquer un changement ;
- montrer une continuité ;
- attirer l’attention de manière proportionnée ;
- confirmer une interaction ;
- réduire l’ambiguïté ;
- aider l’utilisateur à comprendre l’état de l’interface.

Le feedback doit rester :

- explicite ;
- proportionné ;
- non intrusif ;
- accessible ;
- contrôlable ;
- cohérent.

---

## 3. Objectif utilisateur

Garantir que les futurs composants IUX fournissent des retours cohérents et compréhensibles après une interaction, sans animations excessives, sans vibrations systématiques et sans dépendance à un seul canal sensoriel.

L’utilisateur final doit pouvoir :

- comprendre qu’une action a été prise en compte ;
- distinguer chargement, succès, erreur et annulation ;
- utiliser l’application avec des animations réduites ;
- recevoir un feedback visuel, sémantique ou haptique proportionné ;
- ne pas subir de mouvement répétitif ou inutile.

---

## 4. Objectifs de la mission

Cette mission doit :

1. Définir les rôles de mouvement.
2. Définir les durées et courbes.
3. Créer une politique de mouvement réduit.
4. Créer une résolution contextualisée du mouvement.
5. Définir les rôles de feedback.
6. Créer une politique haptique.
7. Créer une politique d’annonces sémantiques.
8. Définir les retours visuels de base.
9. Créer une abstraction de feedback contrôlée par le parent.
10. Éviter que les futurs composants réimplémentent ces mécanismes.
11. Ajouter documentation, tests, ADR et démonstrations.
12. Préparer les composants d’action et de statut des missions suivantes.

---

## 5. Hors périmètre

Ne pas réaliser dans cette mission :

- de bouton final ;
- de snackbar final ;
- de dialogue final ;
- de loader final ;
- de système de notification ;
- de toast métier ;
- de composant de succès ou d’erreur final ;
- d’animation de marque ;
- d’animation illustrative complexe ;
- de son ;
- de vibration continue ;
- de moteur d’animation tiers ;
- de logique métier asynchrone ;
- de gestion d’état globale ;
- de publication sur `pub.dev`.

Le catalogue peut utiliser des widgets Flutter standards pour démontrer le moteur.

---

## 6. Audit préalable obligatoire

Avant toute modification, inspecter :

- les fondations de mouvement de IUX-002 ;
- les préférences de mouvement de IUX-004 ;
- le runtime d’accessibilité de IUX-005 ;
- les helpers d’annonce existants ;
- les tokens sémantiques ;
- les `ThemeExtension` ;
- le catalogue ;
- les tests ;
- les ADR ;
- les dépendances.

Présenter :

- ce qui existe ;
- ce qui doit être réutilisé ;
- les risques de duplication ;
- les conflits éventuels entre thème et runtime ;
- les risques d’abstraction trop générale ;
- les risques de feedback déclenché implicitement ;
- les limites des APIs Flutter pour l’haptique et les annonces.

---

## 7. Principes directeurs

Le moteur doit respecter les règles suivantes.

### Le mouvement explique

Une animation doit répondre à au moins une question :

- Qu’est-ce qui vient de changer ?
- Où est passé l’élément ?
- Quelle action a été prise en compte ?
- Quel état est actif ?
- Que dois-je regarder ?

Sans réponse claire, l’animation est probablement inutile.

### Le feedback est proportionné

Une action mineure ne doit pas provoquer :

- vibration forte ;
- annonce intrusive ;
- animation longue ;
- confirmation redondante.

### Le feedback est multimodal

Une information importante ne doit pas dépendre uniquement :

- de la couleur ;
- du mouvement ;
- de l’haptique ;
- d’une annonce.

### Le parent garde le contrôle

Les composants futurs ne doivent pas déclencher silencieusement :

- succès ;
- erreur ;
- vibration ;
- annonce ;
- transition métier.

L’état reste contrôlé par le parent.

---

## 8. Architecture cible

Structure indicative :

```text
packages/iux_flutter/lib/src/motion/
├── motion_role.dart
├── motion_duration.dart
├── motion_curve.dart
├── motion_policy.dart
├── resolved_motion.dart
└── motion_context.dart

packages/iux_flutter/lib/src/feedback/
├── feedback_role.dart
├── feedback_policy.dart
├── feedback_event.dart
├── feedback_controller.dart
├── haptic_policy.dart
├── announcement_policy.dart
└── visual_feedback_policy.dart
```

Adapter cette structure si elle devient trop fragmentée.

Éviter :

- une classe monolithique ;
- un service global mutable ;
- un singleton implicite ;
- une dépendance à des composants finaux ;
- des événements non typés ;
- des maps dynamiques.

---

## 9. Rôles de mouvement

Créer des rôles sémantiques, par exemple :

```dart
enum IuxMotionRole {
  stateChange,
  enter,
  exit,
  reveal,
  conceal,
  reposition,
  emphasis,
  progress,
}
```

Adapter si certains rôles sont trop vagues.

Chaque rôle doit documenter :

- son intention ;
- les cas d’usage ;
- les cas interdits ;
- son comportement en mouvement réduit ;
- son comportement sans mouvement.

Le rôle `emphasis` doit être utilisé avec prudence.

---

## 10. Durées

Définir une échelle limitée de durées.

Exemple d’intention :

```dart
IuxMotionDuration.instant
IuxMotionDuration.short
IuxMotionDuration.standard
IuxMotionDuration.long
```

Ne pas multiplier les durées arbitraires.

Documenter :

- la relation entre durée et distance ;
- la relation entre durée et complexité ;
- les usages ;
- le comportement réduit ;
- les limites.

Éviter les animations longues qui bloquent l’action.

---

## 11. Courbes

Définir des rôles de courbes.

Exemple :

```dart
IuxMotionCurve.enter
IuxMotionCurve.exit
IuxMotionCurve.standard
IuxMotionCurve.emphasized
```

Les courbes doivent rester sobres.

Ne pas introduire :

- rebond excessif ;
- overshoot systématique ;
- oscillation ;
- pulsation permanente.

---

## 12. Politique de mouvement

Créer une politique permettant de résoudre un mouvement selon :

- le rôle ;
- la préférence du thème ;
- le runtime d’accessibilité ;
- `MediaQuery.disableAnimations` ;
- la plateforme ;
- le contexte.

Exemple conceptuel :

```dart
final resolved = IuxMotionPolicy.resolve(
  context,
  role: IuxMotionRole.stateChange,
);
```

Le résultat peut inclure :

```dart
duration
curve
enabled
replacementBehavior
```

Le moteur doit distinguer :

- animation essentielle ;
- animation utile mais non essentielle ;
- animation décorative.

Les animations décoratives doivent être supprimées en mouvement réduit.

---

## 13. Mouvement réduit

Prévoir des comportements explicites :

```dart
enum IuxReducedMotionBehavior {
  preserve,
  shorten,
  simplify,
  remove,
}
```

ou une meilleure API.

Exemples :

- transition de page : simplifier ou raccourcir ;
- spinner : conserver une indication de progression mais réduire l’effet ;
- pulsation décorative : supprimer ;
- déplacement important : remplacer par fondu ou changement instantané ;
- succès : conserver un indicateur statique.

Documenter ces règles.

---

## 14. Résolution depuis le contexte

Fournir une API principale cohérente.

Exemples :

```dart
IuxMotion.of(context)
```

ou :

```dart
context.iuxMotion
```

Éviter plusieurs APIs concurrentes.

La résolution doit combiner :

- configuration du thème ;
- runtime d’accessibilité ;
- préférences système ;
- rôle demandé.

---

## 15. Rôles de feedback

Créer des rôles sémantiques couvrant au minimum :

```dart
enum IuxFeedbackRole {
  interaction,
  confirmation,
  success,
  warning,
  error,
  progress,
  selection,
  destructive,
}
```

Adapter si nécessaire.

Chaque rôle doit documenter :

- intensité ;
- canaux possibles ;
- fréquence acceptable ;
- contexte ;
- exclusions ;
- accessibilité.

---

## 16. Événements de feedback

Créer un modèle fortement typé.

Exemple :

```dart
final class IuxFeedbackEvent {
  final IuxFeedbackRole role;
  final String? semanticMessage;
  final bool allowHaptics;
  final bool allowVisual;
}
```

Éviter un objet trop libre.

Évaluer des constructeurs nommés :

```dart
IuxFeedbackEvent.success(...)
IuxFeedbackEvent.error(...)
IuxFeedbackEvent.selection(...)
```

Le modèle ne doit pas transporter de logique métier.

---

## 17. Politique haptique

Créer une politique haptique commune.

Elle doit distinguer au minimum :

- sélection légère ;
- confirmation ;
- avertissement ;
- erreur ;
- action destructive ;
- aucun feedback.

Utiliser les APIs Flutter disponibles de manière prudente.

Contraintes :

- aucune vibration systématique ;
- respect des préférences utilisateur ;
- possibilité de désactivation ;
- aucune vibration continue ;
- aucune intensité excessive ;
- pas de double feedback pour un même événement ;
- pas d’haptique pour chaque scroll ou hover.

Le feedback haptique ne doit jamais être le seul indicateur.

---

## 18. Annonces sémantiques

Créer une politique d’annonces réutilisant IUX-005.

Les annonces doivent être utilisées pour :

- changement de statut important ;
- chargement terminé ;
- erreur ;
- succès ;
- changement de contexte ;
- résultat asynchrone.

Éviter :

- annoncer chaque micro-interaction ;
- répéter un label déjà lu ;
- annoncer des états purement décoratifs ;
- interrompre inutilement TalkBack.

Prévoir :

- priorité ;
- déduplication ;
- temporisation raisonnable ;
- message fourni par le parent ;
- localisation.

Ne jamais coder en dur des textes anglais dans le runtime.

---

## 19. Feedback visuel

Définir des politiques visuelles abstraites.

Exemples :

- changement d’état ;
- contour ;
- icône ;
- texte ;
- indicateur de progression ;
- couleur sémantique ;
- surface temporaire.

Cette mission ne doit pas créer les composants finaux.

Elle doit définir les règles que ces composants utiliseront.

---

## 20. Contrôleur de feedback

Évaluer une abstraction contrôlée telle que :

```dart
IuxFeedbackController.of(context).emit(event)
```

ou un service injecté.

Éviter un singleton global.

Le contrôleur doit :

- rester testable ;
- respecter les préférences ;
- orchestrer les canaux ;
- éviter les doublons ;
- ne pas imposer d’UI ;
- permettre au parent de choisir les messages.

Si un contrôleur central n’apporte pas de valeur, préférer des helpers spécialisés.

Documenter le compromis.

---

## 21. État contrôlé par le parent

Le runtime ne doit pas deviner :

- qu’une action a réussi ;
- qu’une action a échoué ;
- qu’un chargement est terminé ;
- qu’une suppression a été confirmée.

Le parent doit fournir explicitement l’événement.

Exemple conceptuel :

```dart
feedback.emit(
  IuxFeedbackEvent.success(
    semanticMessage: localizedSuccessMessage,
  ),
);
```

---

## 22. Déduplication

Prévoir une stratégie empêchant :

- plusieurs annonces identiques ;
- plusieurs vibrations identiques ;
- plusieurs confirmations visuelles concurrentes ;
- double feedback produit par parent et composant.

La stratégie doit rester simple.

Ne pas créer un bus d’événements complexe sans nécessité.

---

## 23. Localisation

Les messages utilisateur doivent être fournis par l’application ou le composant localisé.

Le moteur ne doit pas contenir de chaînes métier.

Il peut contenir uniquement :

- clés ;
- rôles ;
- descriptions développeur ;
- textes de diagnostic non affichés.

Documenter la responsabilité de localisation.

---

## 24. Intégration au thème

Créer ou faire évoluer les extensions nécessaires.

Exemples :

```dart
IuxMotionTheme
IuxFeedbackTheme
IuxHapticTheme
```

Éviter une extension par champ.

Le thème doit permettre de configurer :

- durées ;
- courbes ;
- intensité ;
- activation haptique ;
- politique de mouvement réduit ;
- niveau de stimulation.

---

## 25. Intégration au runtime d’accessibilité

Le moteur doit consommer les préférences de IUX-005.

Il ne doit pas dupliquer :

- mouvement réduit ;
- annonces ;
- focus ;
- contraste ;
- profil utilisateur.

Documenter la direction des dépendances.

---

## 26. API publique

Exporter uniquement :

- rôles de mouvement ;
- politiques publiques ;
- rôles de feedback ;
- événements publics ;
- contrôleur ou helpers publics retenus ;
- thèmes de mouvement/feedback.

Ne pas exporter :

- détails internes de déduplication ;
- adaptateurs plateforme ;
- utilitaires de test internes ;
- implémentations temporaires.

---

## 27. Documentation Dart

Toute API publique doit expliquer :

- son intention ;
- son usage ;
- ses limites ;
- les canaux utilisés ;
- le comportement réduit ;
- la responsabilité du parent ;
- les erreurs d’usage fréquentes.

---

## 28. Documentation conceptuelle

Créer au minimum :

```text
docs/motion/overview.md
docs/motion/roles.md
docs/motion/reduced-motion.md
docs/motion/durations-and-curves.md
docs/feedback/overview.md
docs/feedback/haptics.md
docs/feedback/semantic-announcements.md
docs/feedback/proportional-feedback.md
```

Chaque document doit inclure :

- intention ;
- API ;
- exemples ;
- contre-exemples ;
- limites ;
- niveau de preuve ;
- sources.

---

## 29. ADR

Créer au minimum :

```text
docs/decisions/ADR-0005-motion-resolution.md
docs/decisions/ADR-0006-feedback-orchestration.md
```

Inclure :

- contexte ;
- décision ;
- alternatives ;
- conséquences ;
- risques ;
- statut.

---

## 30. Evidence Registry

Ajouter des entrées pour :

- mouvement réduit ;
- animation fonctionnelle ;
- feedback proportionné ;
- haptique ;
- annonces TalkBack ;
- déduplication ;
- suppression des animations décoratives ;
- feedback multimodal.

Ne pas inventer de source.

Marquer les hypothèses.

---

## 31. Tests unitaires du mouvement

Tester :

- résolution standard ;
- résolution réduite ;
- désactivation système ;
- rôle essentiel ;
- rôle décoratif ;
- durée ;
- courbe ;
- fallback ;
- copie ;
- interpolation si utilisée.

---

## 32. Tests unitaires du feedback

Tester :

- mapping rôle vers canaux ;
- haptique activée ou désactivée ;
- annonces activées ou désactivées ;
- déduplication ;
- événement success ;
- événement error ;
- événement selection ;
- respect des profils ;
- message absent ;
- localisation fournie par le parent.

---

## 33. Tests d’intégration runtime

Tester :

- thème + runtime accessibilité + mouvement ;
- mouvement réduit système + override IUX ;
- feedback sans haptique ;
- feedback sans annonce ;
- événement multicanal ;
- absence de contrôleur ;
- résolution depuis `BuildContext`.

---

## 34. Tests de contrat

Garantir que :

- aucun composant final n’est nécessaire ;
- aucun texte utilisateur n’est codé en dur ;
- le moteur ne dépend pas du catalogue ;
- le moteur ne dépend pas de `d4-dark-ds` ;
- les événements sont immuables ;
- les politiques sont testables ;
- les préférences sont respectées.

---

## 35. Catalogue

Ajouter une section démontrant :

- mouvement standard ;
- mouvement réduit ;
- mouvement désactivé ;
- entrée ;
- sortie ;
- changement d’état ;
- feedback de sélection ;
- confirmation ;
- succès ;
- avertissement ;
- erreur ;
- haptique simulée ou documentée ;
- annonce sémantique.

Le catalogue doit permettre d’activer ou désactiver :

- mouvement ;
- haptique ;
- annonces ;
- stimulation visuelle.

Ne pas créer de composants finaux.

---

## 36. Démonstrations sûres

Les exemples du catalogue doivent éviter :

- clignotement ;
- pulsation répétée ;
- mouvement rapide ;
- vibration fréquente ;
- son ;
- animation infinie.

Toute animation répétée doit pouvoir être arrêtée.

---

## 37. Dépendances

Ne pas ajouter de dépendance externe sauf nécessité forte.

Les APIs Flutter standards doivent être privilégiées.

Toute dépendance doit être justifiée selon :

- maintenance ;
- licence ;
- poids ;
- alternatives ;
- valeur immédiate ;
- accessibilité ;
- contrôle utilisateur.

---

## 38. Performance

Le moteur doit être léger.

Éviter :

- timers permanents ;
- streams globaux ;
- bus d’événements complexe ;
- allocations répétées ;
- listeners non nettoyés ;
- animations créées sans besoin ;
- calculs dans chaque frame.

Préférer :

- objets immuables ;
- résolutions simples ;
- contrôleurs locaux ;
- aucune ressource persistante inutile.

---

## 39. Compatibilité

Cette mission est additive.

Ne pas casser :

- les thèmes ;
- les profils ;
- le runtime d’accessibilité ;
- les tokens ;
- les fondations ;
- le catalogue ;
- les tests existants.

Toute évolution doit être documentée.

---

## 40. Commandes de validation

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

## 41. Livrables obligatoires

À la fin de cette mission, fournir :

- rôles de mouvement ;
- durées et courbes ;
- politique de mouvement ;
- gestion du mouvement réduit ;
- rôles de feedback ;
- modèle d’événement ;
- politique haptique ;
- politique d’annonces ;
- orchestration ou helpers retenus ;
- intégration thème/runtime ;
- tests ;
- documentation ;
- ADR ;
- evidence registry ;
- catalogue mis à jour ;
- résultats des validations ;
- liste des fichiers créés et modifiés ;
- limites et décisions différées.

---

## 42. Critères d’acceptation

La mission est terminée uniquement si :

- les futurs composants peuvent résoudre un mouvement par rôle ;
- le mouvement réduit est respecté ;
- les animations décoratives peuvent être supprimées ;
- le feedback est typé ;
- l’haptique est configurable ;
- les annonces sont contrôlées ;
- le parent garde le contrôle des événements ;
- aucun texte utilisateur n’est codé en dur ;
- la déduplication est prévue ;
- aucun composant final n’est créé ;
- le catalogue démontre les politiques ;
- `flutter analyze` ne retourne aucune erreur ;
- `flutter test` réussit.

---

## 43. Rapport final attendu

Répondre avec cette structure :

### Résumé

Décrire le moteur de mouvement et de feedback.

### Audit initial

Présenter l’état du projet avant modification.

### Architecture retenue

Expliquer rôles, politiques, runtime et thème.

### API publique

Lister les types publics ajoutés.

### Mouvement

Présenter durées, courbes, rôles et reduced motion.

### Feedback

Présenter événements, haptique, annonces et orchestration.

### Accessibilité

Présenter les garanties et limites.

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

- composants finaux non encore créés ;
- limitations haptique Android ;
- limitations annonces ;
- comportements expérimentaux ;
- sources restant à vérifier.

### Prochaine mission recommandée

Indiquer que la prochaine étape logique est la création du système de layout, sans la commencer.

---

## 44. Instruction finale

Commence par auditer le résultat réel des missions IUX-001 à IUX-005.

Présente ensuite un plan court et concret.

Puis implémente le moteur de mouvement et de feedback.

Ne crée aucun composant final.

Ne commence pas la mission suivante.
