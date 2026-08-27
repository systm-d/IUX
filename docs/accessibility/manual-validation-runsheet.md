# Feuille de passation — validation manuelle sur appareil

Document opérationnel, rempli à la main pendant la session, par la personne qui
tient le téléphone. Rédigé en français pour cette raison ; le raisonnement, les
critères et le contexte sont dans
[`manual-validation-protocol.md`](manual-validation-protocol.md).

**Appareil :** Pixel 7 (`34031FDH2006JT`) · **Builds :** catalogue et pilote en
**debug** · **Date :** _______ · **Version :** 0.2.0-dev.3

Mettre un **X** dans la colonne OK si le comportement attendu est constaté.
Laisser vide si ce n'est pas le cas, et écrire ce qui s'est passé dans les
**Observations** en bas, en citant l'ID.

Un échec vaut plus qu'un succès : c'est la première fois que ce projet reçoit
une observation venue d'ailleurs que de son propre harnais de test. Si quelque
chose sonne bizarre sans que tu saches dire pourquoi, écris-le quand même.

**Raccourci TalkBack :** maintenir les deux touches de volume. À apprendre avant
de commencer — le couper depuis l'intérieur de TalkBack avec un modal ouvert est
pénible.

---

## Bloc A — TalkBack (~20 min)

| ID | Où | Quoi faire | Attendu | OK |
| --- | --- | --- | --- | :---: |
| **A1** | Catalogue → Media and status, puis Inputs. **TalkBack éteint** | Regarder les glyphes, coches et marques radio | Tout est dessiné. Une option cochée se distingue d'une décochée | |
| **A2** | Buttons | Balayer la grille d'emphase | Une seule énonciation par contrôle : nom, puis « bouton ». Pas de libellé répété, pas de nom vide, aucun contrôle sauté | |
| **A3** | Buttons → panneau async | Lancer une action, balayer sur le bouton pendant qu'elle tourne | Il reste atteignable et n'est **pas** annoncé désactivé | |
| **A4** ⭐ | Overlays → dialogue | Ouvrir, puis balayer **vers la gauche en insistant**, au-delà du premier élément | On n'atteint que le contenu du dialogue, jamais la page derrière | |
| **A4b** | Overlays → bottom sheet | Idem | Idem | |
| **A4c** | Navigation → drawer | Idem | Idem | |
| **A5** | Cards and lists, **police système au maximum** | Balayer une ligne portant un statut | La ligne et son statut = **deux** arrêts, dans cet ordre | |
| **A6** | Inputs → panneau champ texte | Balayer sur le champ lecture seule, puis sur le désactivé | Ils se distinguent. **Noter les deux phrases exactes** quoi qu'il arrive | |
| **A7** | Forms | Soumettre à vide, balayer jusqu'à une entrée du résumé, **double-taper** | Le focus atterrit sur le champ nommé, qui s'annonce | |
| **A7b** | Forms, entrée pointant le groupe radio | Idem | Le focus atterrit sur la **première option** : « …, case d'option, non cochée, 1 sur 2 » | |
| **A8** | Forms → formulaire guidé | Changer d'étape ; soumettre une étape en erreur | Une seule chose parle à la fois, rien n'est coupé | |
| **A9** | Overlays → message transitoire | Le déclencher, y compris pendant un balayage | Annoncé sans réinitialiser la position de lecture, et sans couvrir la navigation | |
| **A9b** ⭐ | Runtime → panneau Announcements | Balayer sur **Refresh** et **double-taper** | Il s'annonce comme bouton **et** le double-tap déclenche l'annonce. Avant `IUX-TAPTARGET-ACTION-001` il n'offrait aucune action | |
| **A10** | Feedback → barre de progression déterminée | Balayer dessus | Le pourcentage annoncé correspond au tracé | |

## Bloc B — Voice Access (~10 min)

| ID | Où | Quoi faire | Attendu | OK |
| --- | --- | --- | --- | :---: |
| **B1** | Catalogue → Buttons | Dire à voix haute le libellé visible d'un contrôle | Il s'active | |
| **B2** | Navigation, puis Media and status | Activer un contrôle icône seule **par son nom** | Il a un nom prononçable qui fonctionne | |
| **B3** | Deux sections au choix | Activer « Afficher les numéros », compter les contrôles atteignables **uniquement** par numéro | Noter le nombre et lesquels | |

## Bloc C — Clavier physique / D-pad (~10 min, clavier BT ou USB requis)

| ID | Où | Quoi faire | Attendu | OK |
| --- | --- | --- | --- | :---: |
| **C1** | Overlays → dialogue, bottom sheet, drawer | Tabuler à l'intérieur de chacun | Le focus tourne **dans** le modal et revient au contrôle qui l'a ouvert à la fermeture | |
| **C2** | Forms et Inputs | Tabuler lentement | Un anneau de focus visible, dessiné **à l'extérieur** du contrôle, à chaque arrêt | |
| **C3** | N'importe quel bouton, puis une case à cocher | Entrée sur le bouton, Espace sur la case | Les deux activent | |
| **C4** | Flows → flux destructif | Ouvrir la confirmation, annuler **au clavier** | Le focus revient sur le déclencheur, pas sur la racine de la page | |

## Bloc D — Mise à l'échelle système (~10 min)

| ID | Où | Quoi faire | Attendu | OK |
| --- | --- | --- | --- | :---: |
| **D1** | Catalogue, **taille de police au maximum** | Parcourir les treize sections | Rien de tronqué, rien de coupé, tout contrôle atteignable | |
| **D2** | Catalogue, **police ET taille d'affichage au maximum** | Navigation, Forms, Cards and lists | La navigation change d'agencement au lieu de déborder | |
| **D3** ⭐ | **Pilote**, les deux réglages au maximum | Créer un job de bout en bout | La tâche entière est réalisable | |

## Bloc E — Contraste plateforme et inversion (~5 min)

| ID | Où | Quoi faire | Attendu | OK |
| --- | --- | --- | --- | :---: |
| **E1** | Catalogue → Theme, puis Buttons, **inversion des couleurs activée** | Regarder | Le texte reste lisible, les contrôles restent distinguables | |
| **E2** | Idem + profil « contraste renforcé » dans la section Theme | Comparer | Mieux, ou au moins pas pire | |
| **E3** | Mode sombre système **+** inversion | Regarder | Noter si quoi que ce soit reste lisible | |

---

## Ce à quoi il ne faut **pas** perdre de temps

Le temps sur appareil est cher. Ne pas revérifier ce qu'un test de widget règle
déjà gratuitement : l'existence des libellés, les rôles, les 48 dp de cible, les
ratios de contraste. Tout ça est épinglé et re-mesurable à volonté.

Ce que seul un appareil tranche, c'est ce que la plateforme **compose** à partir
de l'arbre, ce qu'elle **prononce**, dans quel **ordre**, et si les réglages
système de l'utilisateur survivent au contact du framework.

## Deux défauts sont attendus, pas redoutés

- **A8** — `IUX-GUIDED-FORM-LIVE-001` est ouvert exactement là-dessus : une
  région live qui se déclenche dans la même frame qu'un déplacement de focus.
  Décrire ce qu'on entend est le livrable, pas obtenir un X.
- **E1/E2** — l'inversion recompose l'écran **après** que IUX ait résolu sa
  palette, donc les contrastes que ce projet mesure ne sont pas ceux qui seront
  vus. Personne n'a jamais regardé.

## Les deux résultats qui pèsent le plus

- **A4**, parce qu'une mesure fausse de cette affirmation exacte a gardé un
  plantage ouvert quinze missions, et que la correction a une semaine.
- **D3**, parce qu'une vraie tâche sur un vrai écran à un vrai réglage
  d'accessibilité est ce qui ressemble le plus à l'utilisateur pour qui ce
  projet existe.

---

## Observations

Citer l'ID, dire ce qui s'est passé. Les phrases exactes prononcées par TalkBack
valent de l'or — les recopier telles quelles quand c'est possible.

| ID | Ce que j'ai vu / entendu |
| --- | --- |
| | |
| | |
| | |
| | |
| | |
| | |
| | |
| | |

## Non exécuté

Ce qui n'a pas été fait pendant la session, et pourquoi. Une case vide sans
explication se lit plus tard comme un échec ; le dire est ce qui garde le
registre honnête.

| ID | Pourquoi |
| --- | --- |
| | |
| | |
