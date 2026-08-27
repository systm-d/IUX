# COMPONENT_STANDARD.md

# IUX Component Standard

**Version :** 1.0 (Draft)

> **Statut.** Ce document est le brouillon d'origine, conservé pour référence.
> La version opérante, alignée sur les API réellement livrées par IUX-002 à
> IUX-007, est [`docs/components/component-standard.md`](docs/components/component-standard.md).
> Sa moitié mécanique est vérifiée par
> `packages/iux_flutter/test/components/component_standard_test.dart`.
> En cas de divergence, la version opérante prévaut.

---

# 1. Objectif

Ce document constitue la référence officielle pour la conception, l'implémentation, la validation et la maintenance de tous les composants de la bibliothèque **IUX**.

Il ne décrit pas un composant particulier.

Il définit les règles auxquelles **tous les composants** devront se conformer.

En cas de conflit entre une mission et ce document, les principes de ce document prévalent, sauf mention explicite justifiée et documentée.

---

# 2. Philosophie

Un composant IUX n'est pas un simple widget Flutter.

C'est un élément d'interface reposant sur :

* des principes UX documentés ;
* des règles d'accessibilité ;
* des modèles d'interaction cohérents ;
* des conventions de développement stables ;
* une architecture réutilisable.

Chaque composant doit résoudre un besoin utilisateur avant de résoudre un problème visuel.

---

# 3. Principes fondamentaux

Tous les composants doivent respecter les principes suivants :

* Intentions avant apparence.
* Accessibilité par défaut.
* Cohérence de comportement.
* Simplicité de l'API.
* Composition avant héritage.
* Séparation stricte des responsabilités.
* Performances prévisibles.
* Compatibilité ascendante autant que possible.
* Documentation systématique.
* Tests obligatoires.

---

# 4. Architecture de référence

Chaque composant suit la même architecture logique.

```text
Public API
        │
        ▼
Intentions UX
        │
        ▼
Semantic Resolution
        │
        ▼
Theme Resolution
        │
        ▼
Accessibility Runtime
        │
        ▼
Interaction Runtime
        │
        ▼
Motion Runtime
        │
        ▼
Feedback Runtime
        │
        ▼
Rendering
```

Aucune couche ne doit mélanger plusieurs responsabilités.

---

# 5. API publique

L'API publique doit :

* être concise ;
* être fortement typée ;
* être stable ;
* être orientée intention.

Elle ne doit jamais exposer directement :

* couleurs ;
* ombres ;
* rayons ;
* gradients ;
* effets décoratifs.

Exemple :

Bon :

```dart
IuxButton(
  intent: IuxActionIntent.primary,
)
```

À éviter :

```dart
Button(
  backgroundColor: Colors.blue,
)
```

---

# 6. Responsabilités

Un composant est responsable de :

* représenter une intention UX ;
* résoudre son thème ;
* exposer un comportement cohérent ;
* collaborer avec le Runtime IUX.

Un composant n'est jamais responsable :

* de la logique métier ;
* des appels réseau ;
* de la navigation ;
* du stockage ;
* des notifications applicatives.

---

# 7. Le Runtime IUX

Tous les composants doivent utiliser le Runtime IUX comme point d'entrée.

Conceptuellement :

```dart
final runtime = IuxRuntime.of(context);
```

Le Runtime fournit :

* thème ;
* accessibilité ;
* mouvement ;
* feedback ;
* layout.

Les composants ne doivent pas interroger directement Flutter lorsqu'une abstraction IUX existe.

---

# 8. Résolution graphique

Les composants demandent des rôles.

Le thème fournit des valeurs.

Jamais l'inverse.

Exemple :

```text
Intent
        ↓
Semantic Role
        ↓
Theme
        ↓
Colors / Shapes / Typography
```

---

# 9. États

Les composants utilisent un modèle d'état commun.

Les dimensions doivent rester indépendantes :

* disponibilité ;
* interaction ;
* opération ;
* validation.

Le parent reste propriétaire de l'état.

Le composant ne déduit jamais :

* succès ;
* erreur ;
* chargement terminé.

---

# 10. Accessibilité

Tous les composants doivent :

* fonctionner avec TalkBack ;
* être utilisables au clavier lorsqu'applicable ;
* respecter les tailles tactiles minimales ;
* gérer le focus visible ;
* supporter le texte agrandi ;
* fonctionner en RTL ;
* éviter de transmettre une information uniquement par la couleur.

Aucune exception ne doit être introduite sans justification documentée.

---

# 11. Mouvement

Le mouvement doit :

* expliquer un changement ;
* renforcer la compréhension ;
* rester proportionné.

Les animations décoratives doivent pouvoir être supprimées lorsque le mouvement réduit est actif.

---

# 12. Feedback

Le feedback doit être :

* cohérent ;
* non intrusif ;
* configurable ;
* accessible.

Les composants n'utilisent jamais directement les API haptiques de Flutter.

Ils délèguent au moteur de feedback IUX.

---

# 13. Layout

Les composants utilisent :

* les fondations d'espacement ;
* les primitives de layout ;
* les surfaces ;
* les sections.

Ils n'introduisent pas de valeurs arbitraires.

---

# 14. Thèmes

Les composants doivent fonctionner avec :

* thème clair ;
* thème sombre ;
* contraste renforcé ;
* densité compacte ;
* densité confortable ;
* mouvement réduit.

Ils ne doivent jamais dépendre d'un thème particulier.

---

# 15. Performances

Les composants doivent :

* limiter les allocations ;
* éviter les rebuilds inutiles ;
* privilégier les widgets `const` ;
* éviter les calculs dans `build()` ;
* séparer clairement rendu et résolution.

---

# 16. Documentation

Chaque composant doit posséder une documentation structurée comprenant au minimum :

* Purpose
* When to use
* When not to use
* Accessibility
* API
* Examples
* Best Practices
* Anti-patterns
* Known Limitations

---

# 17. Catalogue

Chaque composant doit disposer d'une démonstration couvrant au minimum :

* variantes ;
* états ;
* thèmes ;
* contraste ;
* texte agrandi ;
* RTL ;
* mouvement réduit ;
* responsive ;
* bonnes pratiques ;
* anti-patterns.

---

# 18. Tests

Chaque composant doit disposer de :

* tests unitaires ;
* widget tests ;
* tests Semantics ;
* tests d'accessibilité ;
* tests de focus ;
* tests de responsive ;
* tests de texte agrandi.

Les Golden Tests sont recommandés pour les composants dont le rendu est stable.

## 18.1 Appuis réalistes

**Tout test qui vérifie qu'un composant réagit à un appui doit passer par
`realTap` (`test/support/gestures.dart`).** `tester.tap()` reste correct
lorsque seule la cible est en cause — région assez grande, libellé inclus dans
la cible, contrôle désactivé qui refuse : ces questions ne dépendent pas de ce
qui se passe entre l'appui et le relâchement.

La raison est mécanique. `tester.tap()` envoie `down` puis `up` **sans frame
intermédiaire** ; un doigt en laisse toujours au moins une. Tout composant qui
se reconstruit pendant l'appui — c'est-à-dire tout composant à retour d'appui —
dispose de cette frame pour changer la forme de son propre sous-arbre. Quand
il le fait, le `State` qui porte le recognizer suivant le pointeur est
détruit, le `up` n'atterrit nulle part, et le contrôle ne se déclenche jamais.
Sans frame intermédiaire, la reconstruction n'a pas lieu avant le `up` : le
défaut n'est pas seulement manqué, il est **inatteignable** par cet
instrument.

Ce n'est pas une hypothèse. `IUX-SELECTION-PRESS-001` a été livré ainsi :
aucun `IuxSwitch`, `IuxCheckbox` ni `IuxRadioGroup` ne répondait au doigt,
alors que les 2 320 tests du dépôt passaient — tests d'appui écrits contre ces
contrôles compris.

**Tout composant qui garde un état d'appui doit figurer dans
`test/components/press_feedback_sweep_test.dart`**, où un appui réaliste par
composant est exigé. Ce fichier vérifie lui-même sa propre exhaustivité : il
lit `lib/src/`, y cherche les sources portant un état d'appui, et échoue si
l'une d'elles n'y est pas exercée.

---

# 19. Critères d'acceptation

Un composant ne peut être considéré comme terminé que si :

* son API est stable ;
* sa documentation est complète ;
* ses tests passent ;
* son accessibilité est validée ;
* son intégration au Runtime IUX est conforme ;
* il respecte les conventions de cette spécification.

---

# 20. Évolutions

Toute évolution du Component Standard doit :

* être motivée ;
* être documentée dans une ADR ;
* préserver la cohérence globale ;
* être compatible avec les composants existants autant que possible.

Le Component Standard est un document vivant, mais son évolution doit rester exceptionnelle afin de garantir la stabilité de l'écosystème IUX.

