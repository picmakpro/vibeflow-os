# Phase 80 : UI-SPEC, Projet en couloirs, liste et panneau

**Statut :** proposé au cadrage (2026-11-11), à lire par le planificateur et le juge. Contrat de design, aucun code.
**Périmètre :** onglet Projet seulement (racine en couloirs ou liste, graphe à la demande, intérieur d'une phase en liste,
panneau). Clavier du canevas, minicarte, ligne d'état, palette, tiroir Git, jetons : `80-UI-SPEC-NAVIGATION.md`.
**Sources :** `80-CONTEXT.md` (P80-D-01 à 09, P80-C76-1 à 4, P80-D-18, P80-D-25), `DESIGN.md` (« Graphite », fait foi),
`DESIGNS.md` § 6. Décisions déléguées par Samuel (message session principale, 2026-11-08), option recommandée : rien ici
ne vaut arbitrage de Samuel.
**Règle de lecture :** un jeton nommé existe déjà dans `DESIGN.md`. **Aucun jeton couleur, ombre, rayon ou courbe neuf.**
Aucune valeur d'espacement hors grille 2, 4, 6, 8, 12, 16, 20, 24, 32 (les maquettes de `DESIGNS.md` en contiennent : voir
§ 8).

## 0. Principes

1. Une vue DOM de la couche VF (P80-D-01) remplace la scène du moteur sur `project.html` : pas de zoom, pas d'échelle.
2. Un seul modèle de données, trois formes : **Couloirs** (défaut à la racine), **Liste** (défaut au téléphone),
   **Graphe** (canevas du moteur, à la demande).
3. L'état se lit par un glyphe de forme distincte et un mot (signature Graphite). La couleur ne fait que renforcer.
4. Surface neutre : ni fond teinté, ni halo, ni anneau coloré, ni contour coloré. La couleur d'état ne vit que dans un glyphe
   (et dans le remplissage de la barre d'un jalon en cours, § 1.2).
5. Aucune animation active à repos ; chaque transition a sa forme statique en mouvement réduit (§ 6).
6. **Deux définitions, citées partout (P80-D-50).** « **Feuille de détail** » = largeur ≤ 999 px **ou** pointeur grossier (tactile) à toute
   largeur ; « **panneau latéral** » = ≥ 1 000 px **et** pointeur fin. Les conditions (a) zone basse et (b) extrémités défilables et
   `scroll-padding-inline-*` se lisent sur elles. « Téléphone » ne désigne que la mise en page ≤ 700 px.

## 1. Écran racine : Projet en couloirs

### 1.1 Structure (ordre du DOM = ordre de lecture = ordre de tabulation)

```
h1 « Projet »  (tabindex=-1, cible de repli du focus en couloirs et en liste, § 5)   22 px / 600 / -.02em
barre d'outils : bascule « Couloirs | Liste | Graphe »                    (§ 2.1)
[ bloc de jalon ] × N, jalon en cours d'abord, puis « Hors jalon » s'il existe
    h2 nom du jalon  +  ligne de synthèse  +  barre d'avancement + pourcentage
    4 couloirs (ou la liste, § 2.2)
« Historique » (details, replié)
Backlog, Graines, Releases, Missions hors phase (listes, § 1.6)
```

- Le grand titre `h1` est « Projet », sans surtitre ni capitales espacées (DESIGN § 9). Le bloc de titre flottant du moteur
  (titre de vue, S80-1) n'existe pas dans cette vue ; il reste pour le graphe.
- La vue est une région de défilement vertical propre (`overflow-y:auto`), marges `--edge` (16) de chaque côté.
  Espacement entre deux blocs de jalon : `--gap-section` (24). Entre h1/barre d'outils/premier bloc : `--sp-16`.
- **Le panneau se pose par-dessus la vue, sans la pousser ni lui réserver de place** (DESIGN § 5, P80-D-29 révisée). La
  mise en page des couloirs ne dépend pas de l'état du panneau : largeur des couloirs, nombre de colonnes et positions
  identiques panneau ouvert ou fermé. Si le panneau couvre la carte (ou la rangée) sélectionnée, la vue la ramène dans la
  partie visible : `scrollIntoView({inline:'nearest', block:'nearest', behavior:'auto'})` (instantané, aucune animation), avec
  `scroll-padding-inline-end: var(--pw)` tant que le panneau est ouvert, et `scroll-padding-inline-start` égal à la largeur
  du tiroir Git + `--edge` tant qu'il est ouvert (il recouvre le bord gauche). **Ces `scroll-padding-inline-*` et les
  extrémités défilables ne valent qu'à partir de 1 000 px au pointeur fin (P80-D-50 b) : sous 1 000 px et au tactile, aucun
  défilement horizontal, à 390 px comme à 800 px (le panneau y est une feuille de détail au sens du § 0, point 6).** Pour que ce défilement soit
  possible, la région de la vue est `overflow:auto` et porte, surcouche ouverte seulement, une extrémité de défilement de la largeur de cette
  surcouche (pseudo-éléments en début et en fin de rail : ils agrandissent l'étendue défilable, ils ne déplacent ni ne
  redimensionnent aucun couloir). Même règle que NAVIGATION § 4.6 « une surcouche n'est pas une zone de lecture », étendue à
  la vue DOM (le bas : § 3, zone basse). Voir § 8, point 6.
- Nombre de colonnes selon la **classe de largeur d'écran existante** (Q11 tenu, aucun point de rupture neuf) : ≥ 1 000 px =
  4 couloirs côte à côte ; 701 à 999 px = grille 2 × 2 (ordre de lecture : À faire, En cours / À recetter, Fait) ; ≤ 700 px =
  empilés. Gouttière entre couloirs `--sp-16`.

### 1.2 En-tête de jalon

| Élément | Spécification | Jetons |
|---|---|---|
| Nom | `h2`, 18 px, 600, -.015em, `--text`. Nom complet, retour à la ligne permis, jamais d'ellipse | `--sans`, `--text` |
| Synthèse | « 5 phases faites sur 12, 1 à recetter » ; 13 px / 400 ; segment « K à recetter » omis si K = 0 ; accords au singulier (« 1 phase faite sur 12 ») | `--text-2` |
| Barre | `.vf-bar` : 6 px, rayon pilule, piste `--raise-2`, largeur 180 px au bureau, pleine largeur sous 700 px. Remplissage `--text-3` ; `--warn-text` seulement si le jalon est en cours (0 < % < 100). 0 % et 100 % : neutre | `--raise-2`, `--text-3`, `--warn-text` |
| Pourcentage | « 42 % », mono 12 px / 500, `--text-3`. **Strict** : `floor(100 × faites / total)`, 100 % seulement si faites = total ; total = 0 : « 0 % », barre vide | `--mono` |
| Disposition | rangée : [h2 + synthèse] à gauche, [barre + pourcentage] à droite (`--sp-12` entre barre et pourcentage), alignée sur la base de la synthèse. Sous 700 px : empilée, barre pleine largeur | `--sp-12`, `--sp-16` |

- « Faites » = nombre de phases de l'état `fait` (couloir Fait). Le planificateur vérifie qu'il égale `meta.vf.milestones[].done`
  (cases cochées du ROADMAP) ; en cas d'écart, la source unique est l'état `fait` (P69), l'écart est consigné.
- La barre porte `role="progressbar"`, `aria-valuemin=0`, `aria-valuemax=100`, `aria-valuenow`, `aria-label="Avancement du
  jalon"` et `aria-valuetext="5 phases faites sur 12"` ; le pourcentage visible est `aria-hidden`.
- « Hors jalon » reçoit le même bloc (nom « Hors jalon »). Les autres jalons actifs suivent, le jalon en cours d'abord.

### 1.3 Couloirs (quatre colonnes, ordre fixe : À faire, En cours, À recetter, Fait)

| Élément | Spécification | Jetons |
|---|---|---|
| Couloir | `div role="group"`, `aria-label="À faire, 6 phases"` ; aucun fond, aucun filet latéral ; posé sur `--bg` | `--bg` |
| En-tête de couloir | `h3`, rangée : glyphe, mot, compte à droite. 13 px / 500 `--text` ; compte mono 12 px / 500 `--text-3`. Filet bas 1 px, `padding-bottom` `--sp-8`, marge basse `--sp-12` | `--hair-2`, `--mono` |
| Glyphe | celui de la pastille (`G_ST`, `.vst`), 1,45 em, `aria-hidden`. À faire : anneau (`--st-todo`) ; En cours : demi-disque (`--st-active`) ; À recetter : anneau et point (`--st-recette`) ; Fait : coche (`--st-done`) | `--st-*` |
| Mot | « À faire », « En cours », « À recetter », « Fait » (mots existants de `ST`/`ETAT_UI`) | dictionnaire existant |
| Compte | nombre de phases du couloir, y compris 0 | |
| Couloir vide | l'en-tête reste (compte 0) ; corps : « aucune phase », 12 px / 400, `--text-3`, `--sp-8` de marge haute, non focalisable | `--text-3` |
| Liste de cartes | `ul`, gap `--sp-8` entre cartes (un seul écart entre frères) | `--sp-8` |

Aucune couleur dans un couloir hors du glyphe. Le glyphe « En cours » sur `--bg` en thème clair tient 3,06:1 (≥ 3:1,
DESIGN § 9) ; la cible 3,5:1 de P80-D-20 dépend du lot jetons (voir NAVIGATION).

### 1.4 Carte de phase

Élément : `li > button` (un `button` natif, pas un `div` cliquable). Le bouton **est** la carte.

| Partie | Spécification | Jetons |
|---|---|---|
| Boîte | fond `--surface`, rayon `--r-card`, `padding: var(--sp-12) var(--inset-card)`, pleine largeur du couloir, `min-height` 44 px, texte aligné à gauche | `--surface`, `--r-card`, `--sp-12`, `--inset-card` |
| Grille interne | 2 colonnes : numéro (`min-content`, `min-width` 5 ch) puis texte ; gap colonne `--sp-8`, gap rangée `--sp-2` ; alignement sur la base | `--sp-8`, `--sp-2` |
| Numéro | « 71.5 », « 72 » ; `--mono` 12,5 px / 500 `--text-3` ; **jamais tronqué** (hors du bloc tronqué) ; si l'identifiant de nœud porte un `@<ws>`, l'espace de travail n'apparaît que dans le panneau | `--mono`, `--text-3` |
| Titre | 13 px / 1,4. Phase En cours ou À recetter : 600 `--text` ; Fait ou À faire : 500 `--text-2` (DESIGN § 5). Au plus 3 lignes | `--sans`, `--text`, `--text-2` |
| Ligne d'état | colonne 2, rangée 2 : 12 px / 400 `--text-3`. Séparateur « · » (point médian, pas de tiret long) | `--text-3` |
| Emplacement de preuve (Phase 76) | `span` en fin de ligne d'état, **un mot au plus** (≤ 16 caractères), 12 px / 500 `--text-2`, séparé par « · ». Vide par défaut : la 80 ne le remplit pas, elle pose l'emplacement et une fonction unique `etiquettePreuve(phase)` (rend `''`) que la 76 remplace. Le mot ne remplace jamais la pastille d'état et n'est jamais seul porteur de sens (le détail va au panneau) | `--text-2` |

**Contenu de la ligne d'état** (source : `avancement` et `exigences {faits, total}`, P80-D-06 ; jamais le texte de `foot`) :

| Cas | Ligne |
|---|---|
| plans et exigences | « 16 plans sur 16 · 11 exigences sur 12 » |
| un seul plan, une seule exigence | « 1 plan sur 1 · 1 exigence sur 1 » |
| `exigences.total` = 0 (champ présent) | « 16 plans sur 16 » (segment omis) |
| `plans.total` = 0 et `reste` (tableau présent) contient `cadrage` | « pas de plan · non cadrée » |
| `plans.total` = 0 et `reste` présent sans `cadrage` | « pas de plan » |
| **`avancement` absent** | aucun segment « plans », aucun « pas de plan », aucun « non cadrée » |
| **`exigences` absent** | aucun segment « exigences » |
| **`avancement` et `exigences` absents** | ligne **vide** (hauteur d'une ligne réservée pour éviter un saut à l'arrivée des données, texte masqué aux lecteurs d'écran, aucun signe d'attente animé) |

**Donnée absente n'est pas zéro.** Chaque segment se décide sur la présence du champ, jamais sur une valeur par défaut :
`undefined` n'est jamais lu comme 0. « pas de plan » exige `plans.total === 0` ; « non cadrée » exige que `reste` existe et
contienne `cadrage`. Tant que `avancement` manque (avant la livraison de la 79, ou nœud reçu sans le champ facultatif), le
couloir est celui de `st` du nœud (`done`, `recette`, `active`, `todo` vers Fait, À recetter, En cours, À faire, projection
`PROJECTION_ST`) ; la liste affiche la cellule vide avec un texte masqué « donnée non disponible », triée en dernier.

Même ligne pour les quatre états (rythme égal entre couloirs). Les maquettes l'omettent sur Fait : écart noté § 8.

**Troncature qui garde la partie distinctive.** Aucune ellipse de fin sauf le filet ci-dessous. La capacité est **calculée à la
plus petite carte, barre de défilement classique comprise** (4 couloirs à 1 000 px avec une barre de ≈ 15 px : couloir de
(1 000 − 15 − 2 × 16 − 3 × 16) / 4 ≈ 226 px ; texte = 226 − 2 × 16 (marge interne) − 38 (numéro mono de 5 ch à 12,5 px) − 8
(gap) ≈ 148 px ; **mesure en graisse 600** (la plus large, titre d'une phase en cours) : Inter 13 px ≈ 6,9 px par caractère
moyen, soit ≈ 21 caractères par ligne ; 3 lignes ≈ 64 caractères, ≈ 58 après la perte du retour à la ligne par mots). Seuil de
coupe : **52 caractères partout** (carte, rangée, plan, nom accessible), soit une marge de 6 caractères sous la capacité
mesurée. Un titre de 52 caractères ou moins s'affiche en entier sur ≤ 3 lignes dans toutes les largeurs ; au-delà,
une ellipse **du milieu** : 31 premiers caractères, « … », 20 derniers (52 caractères). Aux autres largeurs la capacité est
plus grande (≈ 37 caractères par ligne à 701 px, ≈ 42 à 390 px) : le seuil reste unique par simplicité. Le titre porte
`overflow-wrap: anywhere` (un identifiant long sans espace ne déborde pas). Filet : si malgré tout le `line-clamp` de 3
lignes coupe (`scrollHeight` > `clientHeight`), l'ellipse native de fin apparaît, le texte complet reste dans le nom
accessible et le panneau, et le témoin le compte comme un défaut. La même règle vaut pour les titres de rangée et de plan
(« 72-04 Poser le … » ne perd pas ce qui le distingue de « 72-05 »). Le texte complet va dans `aria-describedby` (nom
accessible, plus bas) et dans le panneau ; le numéro et l'identifiant de plan sont toujours entiers.

**États de la carte** (une seule intention d'élévation à la fois, DESIGN § 9) :

| État | Thème sombre | Thème clair | Jetons |
|---|---|---|---|
| Repos | `#191919`, ombre de carte | `#ffffff`, ombre de carte | `--surface`, `--shadow-card` |
| Survol (pointeur fin seulement) | `#1e1e1e`, ombre soulevée, 150 ms | `#fbfbfa`, ombre soulevée, 150 ms | `--surface-hover`, `--shadow-lift`, `--ease` |
| Focus visible (`:focus-visible`) | contour 2 px, décalage `--sp-2`, `outline` (pas de `box-shadow`) | idem | `--ring` |
| Sélectionnée (`aria-current="true"`, panneau ouvert sur elle) | fond survol, **sans ombre**, bordure 1,5 px | idem, bordure plus sombre que le fond | `--surface-hover`, `--text-3` |
| Sélectionnée et focus | bordure 1,5 px + contour de focus extérieur (le focus n'est pas une élévation) | idem | `--text-3`, `--ring` |
| Actif (pression) | ombre de carte, fond `--surface-hover` | idem | `--shadow-card` |

- La sélection se lit sans la couleur : bordure 1,5 px de contraste 8,06:1 sur `--bg` (sombre) et 6,3:1 (clair), plus
  `aria-current`. En thème clair, la carte sélectionnée n'est jamais un fond teinté ni un fond grisé (AUDC : « se lit comme
  désactivée ») : elle garde `--surface-hover` (#fbfbfa) plus la bordure.
- Pas de bordure ni d'ombre colorée selon l'état, pas de point `has-note`.
- **Nom accessible** (une seule fonction, enrichissable par la 75/76) : il **commence par le texte visible** (WCAG 2.5.3) :
  « 72 Lancer du travail depuis les cartes du cockpit, 16 plans sur 16 · 11 exigences sur 12, phase, À recetter » (+ mot de
  preuve avant « phase »). Titre tel qu'affiché (coupé si > 52 caractères) ; le titre complet est porté par
  `aria-describedby` (span masqué). Glyphe `aria-hidden` ; le mot d'état, absent de la carte (il est dans l'en-tête du
  couloir), est ajouté en fin de nom.
- **Sélection et plongée (P80-D-47, cohérence avec le canevas).** Au **bureau** (≥ 1 000 px, pointeur fin), la sélection
  **suit le focus** dans les couloirs et la liste : toute arrivée du focus par l'utilisateur sur une carte ou une rangée (Tab,
  flèches, Origine/Fin, clic) appelle `select(id)` avec l'identifiant de nœud stable (`ph-<N>` ou `ph-<N>@<ws>`, P80-C76-1) ;
  le panneau montre la phase focalisée ; un déplacement repart d'une pile de Retour vide. Une restitution programmée du
  focus (re-rendu, bascule) ne change jamais la sélection. **P80-D-51 (révise P80-D-47) : une seule règle de touches pour
  Projet, à toutes les largeurs et dans toutes les formes, comme sur le canevas : Entrée plonge, Espace sélectionne** ;
  double-clic plonge ; le bouton « Ouvrir la phase » du panneau reste. Sur un plan (feuille), Entrée ouvre le panneau s'il est
  fermé. **Au toucher, un appui sélectionne (la feuille de détail s'ouvre ; « Ouvrir la phase » y figure, comme dans le panneau).**
  Au bureau, la sélection suit le focus dans les couloirs et la liste. Aucune action ne lance de session (P80-D-26).

### 1.5 « Historique » (jalons clos)

`details` replié par défaut, posé sous les blocs actifs. `summary` : triangle de la charte (F1), « Historique », compte
« 8 jalons · 45 phases » (mono, `--text-3`) ; 13 px / 500 ; hauteur ≥ 44 px au tactile. Contenu : une rangée-bouton par
jalon clos (nom, « 12 phases faites sur 12 »), qui sélectionne le nœud du jalon (panneau). Aucune carte de phase des jalons
clos dans cette vue.

### 1.6 Backlog, Graines, Releases, Missions hors phase (retrait 2)

Un bloc de quatre disclosures `details` repliés, chacun avec compte (valeurs existantes : « 39 entrées », « 5 graines », « 30
tags », « 11 missions »). Rangées : bouton pleine largeur, min 44 px au tactile, `--inset-row`, filet `--hair` entre rangées,
groupe sur `--surface`, rayon `--r-card`. Une rangée porte : identifiant ou titre (2 lignes max, règle de troncature du
§ 1.4), à droite pastille glyphe + mot (Backlog : « À faire » ou « Fait » seulement ; **jamais « DIFFÉRÉ »**, P80-D-07),
date mono pour une release. Clic : `select(id)` (panneau). Missions hors phase : non citées par P80-D-07, rangées ici par
défaut (à confirmer, § 8).

## 2. Bascule, liste triable, intérieur d'une phase

### 2.1 Bascule couloirs / liste / graphe

| Aspect | Spécification |
|---|---|
| Emplacement | barre d'outils de la vue, sous le `h1` (au bureau : `h1` à gauche, bascule alignée à droite de la même rangée ; sous 700 px : sous le `h1`, pleine largeur, 3 segments égaux) |
| Composant | groupe segmenté sur le modèle de `.vf-tabs` : piste `--raise`, rayon `--r-ctl`, padding `--sp-4`, segment rayon 9 px. Hauteur 36 px au bureau, **44 px** au tactile et sous 700 px |
| Libellés | « Couloirs », « Liste », « Graphe » (mots seuls, pas de pictogramme neuf : l'audit reproche les icônes sans mot). 13 px / 500 |
| Rôle | `div role="group" aria-label="Forme de l'affichage"` ; chaque segment `button aria-pressed="true|false"` |
| Actif | fond `--surface` + ombre 1 px (modèle de l'onglet actif) + graisse 600 + `aria-pressed="true"` : jamais la couleur seule |
| Focus | `--ring` 2 px, décalage `--sp-2` |
| Touche `v` | fait défiler couloirs → liste → graphe → couloirs. Ignorée avec ⌘, Ctrl, Alt et dans INPUT, TEXTAREA, SELECT, contenteditable (garde unique, P80-D-12). Bouton équivalent ; `v` figure dans l'aide `?` et la palette |
| Intérieur d'une phase | deux segments seulement : « Liste », « Graphe » (couloirs n'a pas de sens, P80-D-04) ; défaut « Liste » |
| Défaut | téléphone (≤ 700 px) : Liste ; ailleurs : Couloirs. Choix mémorisé en `localStorage` par lab et par classe de largeur (≤ 700, 701 à 999, ≥ 1 000), jamais dans `.planning/`. `?vue=couloirs\|liste\|graphe` prime sans être mémorisé |
| Mots du couple | état actif annoncé : « Affichage en liste, 12 phases » (zone `role="status"` `aria-live="polite"`, une seule pour toute la vue) |

Au passage de forme, la sélection et le panneau sont conservés (même `id`). Le changement est instantané (§ 6).

### 2.2 Liste triable (racine)

Un `table` par bloc de jalon (même en-tête de jalon qu'en § 1.2, `aria-labelledby` vers le `h2`).

| Colonne | Contenu | Tri |
|---|---|---|
| Phase | numéro mono + titre (bouton, règle § 1.4) | numérique (`71.5` < `72`), égalité : espace de travail |
| État | glyphe + mot | ordre « attention d'abord » : En cours, À recetter, À faire, Fait |
| Plans | « 16 sur 16 » (mono pour les nombres) ; « pas de plan » | fraction faits/total ; sans plan en dernier |
| Exigences | « 11 sur 12 » ; « aucune » si total 0 | idem |

- **Tri par défaut** : État croissant, puis numéro croissant. Raison : sur une liste on lit de haut en bas, le travail vivant
  en tête ; l'ordre À faire, En cours, À recetter, Fait (flux de gauche à droite) reste celui des couloirs. Tri stable, non
  mémorisé.
- **En-têtes accessibles** : `th scope="col"` contenant un `button` « Trier par État » ; `aria-sort="ascending|descending|none"`
  sur le `th` (un seul actif). Indicateur visuel : chevron du moteur tourné (réutilisé, aucune icône neuve), plus l'`aria-sort`.
  Un clic bascule croissant/descendant. Annonce dans la zone `status` : « Trié par État, croissant ».
- **Rangée** : bouton pleine rangée (pseudo-élément étendu), hauteur ≥ 44 px au tactile, `--inset-row` (8 × 12), filet `--hair`
  entre rangées, groupe sur `--surface`, rayon `--r-card`. États : repos `--surface`, survol `--surface-hover`, sélectionnée
  `aria-current="true"` + bordure `--text-3` 1,5 px sur le groupe de cellules, focus `--ring`. En-tête : 12 px / 500 `--text-3`.
- **≤ 700 px** : rangées en grille (`role="table"`, `row`, `cell`, `columnheader` posés explicitement pour garder la sémantique).
  Ligne 1 : numéro et titre ; ligne 2 : glyphe + mot, « 16 plans sur 16 · 11 exigences sur 12 ». Les en-têtes deviennent une
  rangée de 4 boutons de tri (Phase, État, Plans, Exigences), chacun ≥ 44 px de haut, sans défilement horizontal.

### 2.3 Dans une phase (forme Liste)

`h1` « Phase 72 » + titre ; ligne d'état de la carte ; fil d'Ariane du moteur « Projet › jalon › phase » (existant) et bouton
« Monter » (existant, remonte d'un niveau, ne confondre ni avec « Retour » du panneau ni avec les couloirs).

- **Plans par vague** : `h2` « Plans », puis un `h3` par vague (« Vague 1 », « Vague 2 », « Sans vague ») et une liste de
  rangées-boutons : identifiant mono (`72-04`, jamais tronqué), titre (2 lignes, ellipse du milieu au-delà de 96), à droite
  glyphe + mot du plan (« Fait » : coche ; « À faire » : anneau), puis « 3 exigences couvertes ». Clic : `select` (panneau).
  Ordre des vagues croissant ; dans une vague, ordre des identifiants. `vague` vient du champ structuré du nœud plan (P80-D-06).
  **Un seul arrêt de tabulation pour toute la liste de plans** (toutes vagues confondues, tabulation itinérante), ↑/↓
  précédent/suivant dans l'ordre affiché (d'une vague à la suivante), Origine/Fin ; nom accessible commençant par le texte
  visible (identifiant, titre affiché), puis « plan, Fait ».
- **Exigences** : `h2` « Exigences » (sans compte : le compte « 11 exigences sur 12 » est dit une seule fois, dans la ligne
  d'état sous le `h1`), liste en lecture seule (`ul`, pas de `input`) ; chaque `li` : glyphe coche (cochée,
  `--st-done`) ou anneau (non cochée, `--st-todo`) + mot « Cochée » / « Non cochée » à droite, identifiant mono, texte
  (une fois). Non focalisable individuellement (pas de contrôle) ; le texte de l'exigence est lu dans la liste, pas répété
  ailleurs. Même règle pour « Plans » : pas de compte dans l'intitulé de section.
- Les phases sans plan : « pas de plan », sans section « Plans » vide.

## 3. Trois largeurs

| Largeur | Disposition |
|---|---|
| **1 440 px** | vue utile 1 408 px (marges 16), 4 couloirs de ≈ 340 px (gouttière 16), identiques panneau ouvert ou fermé ; le panneau (≈ 360 px à droite) recouvre alors le couloir Fait et le bord du couloir À recetter : la carte sélectionnée est ramenée dans la partie visible (§ 1.1). `h1` et bascule sur une rangée. Carte ≈ 340 × 62 px (titre et ligne d'état d'une ligne) à ≈ 98 px (titre sur 3 lignes). Barre de jalon 180 px à droite. Blocs de jalon empilés. Pied de vue : zone basse `--vf-bas` (ci-dessous) |
| **1 024 px** | 4 couloirs de ≈ 236 px (vue utile 992 px), même mise en page panneau ouvert ou fermé ; carte ≈ 236 × 80 à 115 px (titre 1 à 3 lignes, ligne d'état 1 à 2 lignes). Bascule inchangée (36 px). Plus petite carte du système : ≈ 226 px à 1 000 px (barre de défilement classique comprise) |
| **800 px** (701 à 999 px) | grille 2 × 2 (≈ 376 px par couloir), mêmes cartes ; panneau fermé par défaut (P29), ouvert au choix |
| **390 px** | **Liste par défaut** (§ 2.2). Marges `--edge` 16, vue utile 358 px. `h1`, puis bascule pleine largeur 3 × 44 px, puis blocs. Couloirs choisis : empilés, une colonne, cartes pleine largeur. Aucune échelle de zoom, aucun contrôle de zoom ni minicarte dans ces formes. Cibles ≥ 44 px (segments, cartes, rangées, en-têtes de tri, `summary`, bouton de thème). Panneau : feuille basse existante (P29) ; la carte sélectionnée reste visible au-dessus de la feuille (défilement de la vue pour la dégager, `scrollIntoView` instantané) |

**Zone basse (P80-D-18), à toute largeur.** La vue DOM est un contenu défilant sous des éléments fixes : la barre de question
`#ask`, le bloc `#vf-coin` (ligne d'état seule, sans minicarte dans ces formes ; absent sous 1 000 px) et, quand il est ouvert,
le tiroir du terminal, qui relève `#stage` (la vue vit dans `#stage` et monte avec lui), la pastille « Terminal » (bas gauche)
et, en feuille de détail (§ 0, point 6), cette feuille quand elle est ouverte (P80-D-50). La vue pose **à la fois**
`padding-bottom` et `scroll-padding-block-end` égaux à `--vf-bas` = hauteur mesurée de `#ask` (0 si absente) + `--edge` +
`--sp-8` + hauteur mesurée de `#vf-coin` (0 s'il n'est pas affiché) + `--edge` + `env(safe-area-inset-bottom)`, **sous 1 000 px
plus la hauteur de la feuille de détail ouverte (§ 0, point 6, y compris le tactile ≥ 1 000 px), et la hauteur de la pastille « Terminal »**, écrit `calc(…) /* dérivé : #ask + #vf-coin + feuille + pastille mesurés */` (exception écrite DESIGN § 4), relu à
chaque changement de taille (`ResizeObserver`). Ainsi la dernière rangée, la touche Fin et une carte focalisée en bas ne
passent jamais sous `#ask`, `#vf-coin`, la pastille « Terminal », la feuille de détail ni le zoom ; les contrôles de canevas (zoom, minicarte, repères) sont absents de ces formes. C'est la règle
NAVIGATION § 4.6 (« une surcouche n'est pas une zone de lecture ») étendue aux vues DOM.

## 4. Panneau

Mêmes panneau, `addPanelSection` et `setOverview` du moteur ; rien n'est remplacé, seul le vocabulaire et le contenu changent.

### 4.1 Vocabulaire (P80-D-08, AUDC-X1)

| Aujourd'hui | Devient sur Projet |
|---|---|
| surtitre « Élément » / `file` | type du nœud : « Plan », « Exigence », « Entrée du backlog », « Graine », « Release », « Mission » |
| ligne « module » (parent du plan) | « Dans la phase » : « 72, Lancer du travail… » |
| section « Éléments » | « Plans » (phase) ou « Exigences » (phase), jamais un mot du code |
| « Mentions » / « Une mention » | supprimés pour un plan (règle « document » du moteur neutralisée sur Projet) ; remplacés par « Exigences couvertes », « Dépend de », « Attendu par » |
| statistiques à 0 (lignes, points d'accès) | absentes pour un plan, une exigence, une phase |
| texte d'exigence ×3 (carte, titre, description) | une fois : titre du panneau = identifiant mono, description = le texte |

### 4.2 Contenu par type

| Type | En-tête (surtitre, titre) | Sections, dans l'ordre |
|---|---|---|
| Phase | « Phase », « 72 · titre », pastille d'état et **la ligne d'état, dite une seule fois ici** (mêmes règles de donnée absente que § 1.4) | bouton « Ouvrir la phase » ; « Plans » (rangées avec statut, sans compte dans l'intitulé) ; « Exigences » (rangées cochée ou non, sans compte) ; sections ajoutées (Phase 76) ; « Fichiers touchés dans l'onglet Code » ; repli « Détails techniques » en dernier |
| Plan | « Plan », identifiant mono + titre | « Statut » (glyphe + mot), « Vague » (« Vague 2 » ou « Sans vague »), « Dans la phase » (lien), « Exigences couvertes » (liste de liens, identifiant + statut), « Dépend de », « Attendu par » |
| Exigence | « Exigence », identifiant mono | texte (une fois), « Statut » (« Cochée »/« Non cochée »), « Couverte par » (plans, liens) |
| Jalon | « Jalon », nom | synthèse et barre (§ 1.2), phases par état (comptes) |
| Backlog, graine, release | « Entrée du backlog », « Graine », « Release » | texte, date mono ; backlog : statut (glyphe + mot, jamais « DIFFÉRÉ » en plus) |

Une section de plan n'affiche pas une ligne dont la valeur est vide : elle disparaît.

### 4.3 Bouton « Retour » (P80-C76-3)

- Emplacement : tête du panneau, **à gauche** de l'intitulé, avant « Fermer » dans l'ordre de tabulation ; bouton texte
  « Retour » précédé d'un chevron du moteur tourné vers la gauche ; 13 px / 500 ; 36 px au bureau, 44 px au tactile.
- Pile de sélections du panneau (`VibeFlow.panneau.retour()`) : un clic sur une carte, une rangée ou un nœud du canevas
  **repart d'une pile vide** ; un lien interne au panneau (plan, exigence, phase) **empile** ; Retour dépile et rappelle
  `select` sans empiler. Plafond 20, le plus ancien sort. Fermer le panneau vide la pile. Au bureau, Échap ne ferme pas le panneau
  (il se ferme par `p` ou son bouton) et ne dépile jamais ; en feuille de détail, Échap ferme la feuille.
- Pile vide : `aria-disabled="true"` (il reste focalisable et annoncé « Retour, indisponible »), texte `--text-4`, aucun
  survol. Le nom : « Retour » ; description : « Revenir à la sélection précédente » (`aria-describedby`, pas de `title` seul).
- Il ne change ni la vue, ni la forme, ni le niveau : c'est la pile du panneau. « Monter » reste la remontée de niveau.

### 4.4 Où la Phase 76 ajoute sa section

`addPanelSection('item', fn)` inchangé (P80-C76-1) : la section de la 76 s'insère **après « Exigences »** (phase) et avant
« Fichiers touchés dans l'onglet Code » ; le repli « Détails techniques » reste le dernier bloc. L'ordre exact est celui de
l'enregistrement dans le moteur : le planificateur le vérifie par un témoin (une section ajoutée apparaît après un clic sur
une carte de couloir, avec la cible `ph-<N>`). `addPanelSection('overview')` reste après le corps de `setOverview`
(P80-C76-2).

## 5. Accessibilité

**Ordre de tabulation (bureau)** : en-tête du cockpit (inchangé) → bascule (3 boutons) → par bloc de jalon : 1 arrêt dans les
couloirs (ou 4 en-têtes de tri puis 1 arrêt de rangées en liste) → « Historique » (`summary`) → 4 `summary` des listes (chacun
un arrêt, la liste ouverte un arrêt) → panneau (« Retour », « Fermer », contenu) → barre de question. Tabulation itinérante
dans chaque collection (même principe que P80-D-10) : `tabindex=0` sur la dernière carte active, `-1` ailleurs.

**Clavier dans une collection**
- Couloirs : **règle par position à l'écran**, la même pour 4 côte à côte, 2 × 2 et empilés (les couloirs forment une grille
  de lignes et de colonnes d'écran : 4 colonnes sur 1 ligne, 2 colonnes sur 2 lignes, 1 colonne sur 4 lignes).
  - ↑/↓ : carte précédente/suivante dans le couloir ; au bas d'un couloir, ↓ va à la **première carte du premier couloir
    non vide situé sur une ligne d'écran plus basse**, en prenant la même colonne d'écran, sinon la plus proche (2 × 2 : À
    faire vers À recetter, En cours vers Fait ; si À recetter est vide, À faire ↓ va à Fait ; empilés : couloir non vide
    suivant) ; au haut d'un couloir, ↑ va à la **dernière carte du premier couloir non vide situé sur une ligne plus haute**,
    même règle de colonne ; sans couloir non vide dans cette direction, l'appui ne bouge pas. Côte à côte (une seule ligne),
    ↑/↓ restent dans le couloir.
  - ←/→ : même rang (plafonné à la dernière carte) dans le **prochain couloir non vide de la même ligne d'écran dans la
    direction** de la flèche ; sans couloir non vide dans cette direction sur la ligne, ne bouge pas.
  - Origine/Fin : première/dernière carte du bloc, dans l'ordre de lecture (couloir par couloir). Entrée : plonger ;
    Espace : sélectionner, à toutes les largeurs et dans toutes les formes (P80-D-51, § 1.4). Aucun champ : pas de recherche par frappe.
- Liste : ↑/↓, Origine, Fin ; Entrée plonge, Espace sélectionne (P80-D-51) ; en-têtes de tri : Entrée/Espace.
- Aucune lettre seule ne déclenche une action hors garde de saisie (§ 2.1).

| Élément | Rôle et nom |
|---|---|
| Vue | `section aria-labelledby` du `h1` ; zone `role="status"` unique, `aria-live="polite"`, `aria-atomic="true"` |
| Bascule | `group` « Forme de l'affichage », `button aria-pressed` |
| Barre de jalon | `progressbar` (§ 1.2) |
| Couloir | `group`, nom « À faire, 6 phases » ; `h3` visible ; glyphes `aria-hidden` |
| Carte | `button`, nom « 72 titre, 16 plans sur 16 · 11 exigences sur 12, phase, À recetter » (commence par le texte visible, § 1.4) ; `aria-describedby` = titre complet si coupé ; `aria-current` si sélectionnée |
| Liste | `table` nommé par le `h2` ; `th scope="col"` + `aria-sort` ; rangée = bouton |
| Exigences de phase | `ul`, `li` : « 12.1, texte, Cochée » (glyphe `aria-hidden`, mot lu) |

**Cible de repli du focus (règle unique, citée par NAVIGATION).** Chaque fois qu'un geste ou un rendu doit poser le focus
sans cible plus précise :
- couloirs ou liste (racine ou intérieur de phase) : **l'élément sélectionné** rendu, sinon le `h1` de la vue (`tabindex=-1`) ;
- Graphe (racine ou intérieur de phase) : **la carte itinérante** du canevas, sinon `#stage` (`tabindex=-1`) ;
- jamais `body`. Le `h1` n'existe qu'en couloirs et en liste : aucune règle ne lui envoie le focus en Graphe.

**Focus orphelin (règle de famille).** Tout contrôle focalisé qui disparaît, est remplacé ou devient inopérant, par son
propre geste ou par un re-rendu (en-tête de tri, `summary`, « Réessayer » réussi, rangée de backlog, phase disparue, repère de
bord tombé à 0, « Afficher 100 de plus » épuisé), rend le focus dans cet ordre, au premier qui existe : (1) l'équivalent dans
le rendu suivant, repéré par une clé stable (`ph-<N>`, colonne de tri, identifiant de `summary`, identifiant de rangée,
« Réessayer ») ; (2) le fruit du geste (la carte ramenée par un repère, la première rangée ajoutée) ; (3) le voisin suivant,
puis précédent, de la même collection ; (4) l'arrêt itinérant de la collection ; (5) la cible de repli ci-dessus. Jamais
`body` ; aucune annonce de plus que celles déjà spécifiées.

**Annonce et focus**
- Changement de forme : annonce « Affichage en liste, 12 phases ». Focus : reste sur le segment cliqué ; après la touche `v`
  ou une action de palette, il va à **l'élément équivalent dans la nouvelle forme** (carte, rangée ; en Graphe : la carte
  itinérante, sinon `#stage`), sinon à la cible de repli ci-dessus. L'élément sélectionné est ramené dans la partie
  visible (§ 1.1).
- Entrée dans une phase ou retour : focus sur la cible de repli de la forme d'arrivée (liste : `h1` de la phase ; Graphe :
  première carte du niveau, comme NAVIGATION § 1) ; à la remontée, focus rendu **sur la carte** (ou la rangée) de la phase
  quittée, jamais sur `body`.
- Changement d'onglet (P80-D-22, P80-D-50 e) : la **règle de repli unique** ci-dessus s'applique à la vue chargée :
  élément sélectionné, sinon `h1` « Projet » en couloirs ou en liste (Graphe et Code : carte itinérante, sinon `#stage`) ;
  annonce par la zone `status` « Projet ».
- **Échap.** La vue DOM de Projet (couloirs, liste, intérieur de phase) compte comme **canevas** pour les crans 7 et 8 de la
  chaîne d'Échap (NAVIGATION § 2) : depuis une carte ou une rangée focalisée, un premier appui désélectionne (le panneau
  revient à la vue d'ensemble, le focus reste), un appui suivant remonte d'un niveau dans une phase et ne fait rien à la
  racine ; un Échap venu d'un bouton du panneau ou d'un menu ne les atteint pas (garde PU-G-175).
- Sélection d'une carte : le focus reste sur la carte (le panneau ne prend pas le focus, Q5) ; en feuille de détail, la feuille
  prend la place standard de la feuille du moteur et Échap la ferme en rendant le focus à la carte.
- Tri : annonce « Trié par État, croissant » ; focus reste sur le bouton de tri.

**Re-rendu provoqué par le direct** (relecture `graphe` de la 79, `on('render')` après un patch). La vue se redessine par
réconciliation sur l'identifiant de nœud ; au terme du rendu elle **restitue** :
- le **focus**, pour **tout contrôle de la vue** et pas seulement une phase : carte ou rangée (même `ph-<N>`, même si la phase
  a changé de couloir), en-tête de tri (même colonne), `summary` (même disclosure), bouton « Réessayer », rangée de backlog,
  graine ou release (même identifiant) ; un contrôle disparu suit la règle « focus orphelin » ci-dessus ; jamais sur
  `body` ; le focus d'un champ ou du panneau n'est jamais volé ;
- l'**arrêt itinérant** (`tabindex=0` sur la même phase) et la **sélection** (`aria-current`, bordure, panneau ouvert
  inchangé : l'identifiant sélectionné vient de l'état du panneau, pas du DOM) ;
- le **défilement** (`scrollTop` et `scrollLeft` de la vue) ;
- le **tri** (colonne et sens), l'état des `details` (Historique, listes) et la forme choisie.
Annonce : aucune à chaque patch ; seule la phase focalisée ou sélectionnée qui change de couloir est dite une fois dans la
zone `status` (« Phase 72 : À recetter »).

**États de la vue entière** (sous le `h1` et la bascule ; texte 13 px / 400 `--text-2`, boîte d'information neutre `--warn-bg`
sur `--surface`, rayon `--r-ctl`, `padding` `--inset-box`, glyphe + mot, zone `role="status"`, jamais de fond teinté) :

| État | Texte | Chemin de résolution |
|---|---|---|
| Graphe non chargé (avant la première lecture) | « Chargement du projet » | disparaît au premier rendu ; aucune animation ; la bascule reste active |
| Aucun jalon, aucune phase | « Aucun jalon dans la planification. Le ROADMAP du dépôt ne déclare ni jalon ni phase. » | « Le format attendu est décrit dans « Format de la planification », dans la vue d'ensemble du panneau. » ; Backlog, Graines, Releases restent affichés s'ils existent |
| Erreur de lecture (réponse en erreur ou illisible) | « Lecture impossible. Les données du projet n'ont pas pu être lues. » | bouton « Réessayer » (relit `GET /api/vf/graphe?onglet=projet`, lecture seule) ; sinon recharger la page ou relancer le cockpit ; si une lecture précédente a réussi, elle **reste affichée** sous la boîte |
| Jalon sans phase | « aucune phase » sous le nom du jalon (les 4 couloirs vides ne s'affichent pas) | aucun |

**Contraste visé** (mesuré sur les valeurs de `DESIGN.md`, `python3` hors navigateur ; à remesurer en rendu par le témoin)

| Paire | Sombre | Clair | Seuil |
|---|---|---|---|
| `--text` / `--surface` (titre de carte actif) | 14,88 | 18,10 | 4,5 |
| `--text-2` / `--surface` (titre fait, à faire) | 10,29 | 10,53 | 4,5 |
| `--text-3` / `--surface`, `--surface-hover` (ligne d'état) | 7,39 ; 7,01 | 7,00 ; 6,76 | 4,5 |
| `--text-3` / `--bg` (en-tête de couloir, « aucune phase ») | 8,06 | 6,30 | 4,5 |
| `--text-4` / **fond réel du panneau** (`--elev`, translucide : Retour désactivé) | à mesurer en rendu | à mesurer en rendu | 4,5 ; si non tenu, le Retour désactivé prend `--text-3` |
| `--st-active` / `--bg` ; `--surface` (glyphe En cours) | 14,86 ; 13,63 | 3,06 ; 3,40 | **3,5 (cible P80-D-20, portée par le lot jetons)** : le clair échoue la cible tant que ce lot n'est pas livré (3,06 mesuré) |
| `--st-done` / `--bg` | 10,49 | 3,13 | 3 |
| bordure de sélection `--text-3` / `--bg` | 8,06 | 6,30 | 3 |
| `--warn-text` / `--raise-2` (barre de jalon en cours) | 11,78 | 3,85 | 3 |
| `--ring` (focus) / `--bg` | ≥ 12 | ≥ 12 | 3 |

**Interdits mesurés** : `--text-4` n'est jamais posé sur `--raise` ou `--surface-hover` (4,09 et 4,34 en sombre) ; une teinte
d'état n'est jamais posée sur `--raise` ni `--raise-2` en clair (glyphe) ; les cartes sont sur `--surface`, pas `--raise`.

## 6. Mouvement

| Élément | Comportement | Mouvement réduit |
|---|---|---|
| Survol d'une carte ou rangée | fond et ombre, 150 ms, `--ease`, pointeur fin seulement | `transition: none` |
| Bascule de forme | remplacement instantané, aucun fondu | identique |
| Barre de jalon | largeur posée, aucune transition | identique |
| Glyphes d'état | statiques : **pas** de respiration dans les couloirs (réservée au tiroir « Au travail ») | identique |
| Ouverture du panneau, feuille | animation existante du moteur (250 à 300 ms), **non modifiée** ; elle est couverte par sa variante existante `prefers-reduced-motion: reduce`, la spec n'en ajoute pas | variante existante (le témoin la mesure à part) |
| Ramener la sélection dans la partie visible | défilement instantané (`behavior:'auto'`) | identique |
| `details` (Historique, listes) | ouverture instantanée | identique |
| Défilement vers une carte (focus, sélection) | `scrollIntoView({behavior:'auto'})`, jamais `smooth` ; `scroll-behavior: auto` | identique |

Zéro animation active en mouvement réduit, y compris écrite en JavaScript : le témoin lit `document.getAnimations()` (aucune
en cours) après chargement et après une bascule ; aucune animation n'est créée par cette vue en mouvement réduit.

## 7. Libellés neufs (dictionnaire propre à la phase, P80-D-27) et critères vérifiables

Espaces insécables avant `: ; ! ?` et dans « 1 024 px ». Pas de tiret long dans le texte d'interface. Séparateur « · ».

| Clé | Libellé |
|---|---|
| groupe de bascule | « Forme de l'affichage » |
| segments | « Couloirs », « Liste », « Graphe » |
| annonce de forme | « Affichage en couloirs, 12 phases » ; « Affichage en liste, 12 phases » ; « Affichage en graphe » |
| synthèse de jalon | « 5 phases faites sur 12, 1 à recetter » ; « 1 phase faite sur 12 » ; « 0 phase » |
| avancement | « Avancement du jalon » ; « 42 % » |
| couloir (nom de groupe) | « À faire, 6 phases » ; « Fait, 1 phase » |
| couloir vide | « aucune phase » |
| ligne d'état | « 16 plans sur 16 » ; « 1 plan sur 1 » ; « 11 exigences sur 12 » ; « 1 exigence sur 1 » ; « pas de plan » ; « non cadrée » |
| nom de carte | « {numéro} {titre affiché}, {ligne d'état}, phase, {état} » |
| états de vue | « Chargement du projet » ; « Aucun jalon dans la planification. Le ROADMAP du dépôt ne déclare ni jalon ni phase. » ; « Le format attendu est décrit dans « Format de la planification », dans la vue d'ensemble du panneau. » ; « Lecture impossible. Les données du projet n'ont pas pu être lues. » ; « Réessayer » ; « donnée non disponible » (texte masqué) ; « Phase 72 : À recetter » |
| Historique | « Historique » ; « 8 jalons · 45 phases » ; « 12 phases faites sur 12 » |
| listes sous les couloirs | « Backlog » ; « Graines » ; « Releases » ; « Missions hors phase » (comptes existants) |
| en-têtes de tri | « Phase », « État », « Plans », « Exigences » ; « Trier par {colonne} » ; « Trié par {colonne}, croissant » ; « …, décroissant » |
| cellules de liste | « 16 sur 16 » ; « 11 sur 12 » ; « pas de plan » ; « aucune » |
| intérieur d'une phase | « Plans » ; « Vague 1 » ; « Sans vague » ; « 3 exigences couvertes » ; « Exigences » ; « Cochée » ; « Non cochée » |
| panneau | « Retour » ; « Revenir à la sélection précédente » ; « Retour, indisponible » ; « Ouvrir la phase » |
| types | « Phase », « Plan », « Exigence », « Jalon », « Entrée du backlog », « Graine », « Release », « Mission » |
| champs de panneau | « Statut » ; « Vague » ; « Dans la phase » ; « Exigences couvertes » ; « Couverte par » ; « Dépend de » ; « Attendu par » |

| Élément | Critère vérifiable (mesure d'un témoin) |
|---|---|
| Vue par défaut | `project.html` sans paramètre rend 4 `[role=group]` de couloir au bureau, 0 canevas ; `?vue=graphe` rend le canevas |
| En-tête de jalon | texte égal à « N phases faites sur M, K à recetter » ; `aria-valuenow` = `floor(100·N/M)` ; largeur du remplissage = ce pourcentage ; `100 %` seulement si N = M |
| Couloirs | 4 en-têtes dans l'ordre fixe ; compte affiché = nombre de cartes ; couloir vide contient « aucune phase » |
| Glyphe + mot | chaque en-tête et chaque pastille porte un glyphe distinct **et** un mot ; en niveaux de gris les 4 glyphes restent distincts |
| Carte | `button` natif, hauteur ≥ 44 px ; fond calculé = `--surface` au repos ; rayon = `--r-card` ; aucun `box-shadow` coloré ; titre ≤ 3 lignes ; numéro entier ; nom accessible commence par le texte visible (numéro et titre affiché) |
| Troncature | à 1 000 px avec barre de défilement classique de 15 px (couloir ≈ 226 px), un titre de 52 caractères tient en ≤ 3 lignes sans coupe (`scrollHeight` = `clientHeight`), y compris avec un identifiant long (`overflow-wrap`) ; un titre de 53 caractères ou plus devient 31 premiers + « … » + 20 derniers ; `aria-describedby` porte le texte complet ; aucune ellipse CSS de fin visible (sinon défaut) |
| Ligne d'état | cas du tableau § 1.4 ; ne lit jamais `foot` ; emplacement de preuve ≤ 1 mot |
| Donnée absente | nœud reçu sans `avancement` ni `exigences` : la ligne d'état est vide et ne contient ni « pas de plan » ni « non cadrée » ni « 0 » ; le couloir est celui de `st` ; `plans.total` = 0 explicite : « pas de plan » |
| États de vue | graphe non chargé : « Chargement du projet » ; ROADMAP sans jalon : texte et chemin du § 5 ; lecture en erreur : « Lecture impossible », bouton « Réessayer » relit la route, l'ancien contenu reste |
| États de carte | survol, focus (`outline` 2 px `--ring`), sélection (bordure 1,5 px `--text-3`, sans ombre) ; mesurés dans les deux thèmes ; contraste de la bordure ≥ 3:1 |
| Grille d'espacement | toute valeur d'espacement calculée de la vue appartient à {0, 2, 4, 6, 8, 12, 16, 20, 24, 32} (exceptions écrites § 3) |
| Bascule | 3 `button` `aria-pressed` ; un seul à `true` ; `v` fait tourner ; ignoré dans un champ et avec ⌘ ; hauteur 36 (bureau), 44 (tactile) |
| Mémoire de forme | clef `localStorage` par lab et classe de largeur ; aucun fichier écrit sous `.planning/` |
| Liste | `th[aria-sort]` unique non `none` ; tri par défaut État puis numéro ; clic bascule ; rangée ≥ 44 px au tactile ; aucun défilement horizontal à 390 px |
| Dans une phase | plans groupés par `h3` de vague ; exigences en `ul` sans `input` ; texte d'exigence présent une fois dans le panneau |
| Panneau | aucun des mots « Élément », « module », « Mentions » dans le texte visible de Projet ; panneau de plan : statut, vague, exigences couvertes présents |
| Retour | pile vide : `aria-disabled="true"` ; lien interne : actif ; `retour()` rappelle l'ancienne cible sans empiler ; **en feuille de détail**, Échap ferme la feuille sans dépiler ; au bureau, Échap ne ferme pas le panneau |
| Sélection et plongée | bureau : Tab, flèche ou clic sur une carte la sélectionne (`aria-current`, panneau sur `ph-<N>`), Entrée plonge, Espace sélectionne, à **toutes les largeurs et dans toutes les formes** (P80-D-51) ; une restitution de focus programmée ne change pas la sélection ; toucher : un appui sélectionne (feuille de détail), « Ouvrir la phase » est dans la feuille |
| Repli du focus | après `v` ou une action de palette vers Graphe, `document.activeElement` est la carte itinérante, sinon `#stage` ; vers couloirs ou liste, l'élément sélectionné, sinon le `h1` ; changement d'onglet : idem selon la vue chargée ; jamais `body` ni un `h1` absent du DOM |
| Focus orphelin | pour chaque contrôle de la famille (en-tête de tri re-rendu, `summary`, « Réessayer » réussi, rangée de backlog, phase disparue) : le contrôle focalisé retiré du DOM, `document.activeElement` suit l'ordre équivalent, fruit du geste, voisin, arrêt itinérant, repli ; jamais `body` |
| Échap dans la vue DOM | focus sur une carte : 1er appui désélectionne, 2e remonte (dans une phase) ou sans effet (racine) ; depuis un bouton du panneau, aucun des deux |
| Phase 76 | une section ajoutée par `addPanelSection('item')` apparaît après un clic sur une carte de couloir, cible `ph-<N>` |
| Largeurs | 1440 et 1024 : 4 couloirs de ≥ 226 px, positions et largeurs **identiques panneau ouvert et fermé** ; 800 : 2 × 2 ; 390 : Liste par défaut, zéro `transform: scale`, aucune cible < 44 px, pas de recouvrement de la carte sélectionnée, **`scrollWidth` ≤ `clientWidth` de la vue (aucun défilement horizontal) à 390 et 800 px, feuille ouverte ou non** |
| Panneau par-dessus | panneau ouvert sur une carte du couloir Fait à 1 440 px : la carte est entièrement hors de la zone du panneau (`getBoundingClientRect`), obtenu sans animation ; position de mise en page des couloirs inchangée à l'ouverture et à la fermeture (`offsetLeft`, `offsetTop`, `offsetWidth` identiques ; le défilement est exclu de la mesure) |
| Grille de flèches (1 024 px et 800 px) | à 1 024 (4 couloirs côte à côte) : → parcourt À faire, En cours, À recetter, Fait au rang plafonné, ← revient, ↑/↓ restent dans le couloir. À 800 (2 × 2) : ↓ au bas d'À faire va à la première carte d'À recetter, ↓ au bas d'En cours à la première de Fait, ↑ symétrique (dernière carte), ←/→ dans la ligne ; la suite des appuis visite les quatre couloirs, clavier seul, sans jamais mettre le focus sur `body`. Couloirs vides : À recetter vide, ↓ au bas d'À faire va à la première carte de Fait ; En cours vide, → depuis À faire n'a pas de cible sur la ligne et ne bouge pas |
| Re-rendu en direct | un patch déclenché pendant que le focus est sur une carte : `document.activeElement` est le bouton de la même phase (même `ph-<N>`, même si elle a changé de couloir), jamais `body` ; `tabindex=0` sur elle ; `aria-current` inchangé ; `scrollTop` et `scrollLeft` égaux ; tri et `details` inchangés ; focus d'un champ ou du panneau non volé |
| Plans d'une phase | un seul arrêt de tabulation pour la liste de plans ; ↑/↓ traversent les vagues |
| Zone basse (toutes largeurs) | à 1 440 et 1 024 px (panneau latéral), à 390 **et 800 px (feuille de détail ouverte puis fermée)**, tiroir Git et tiroir du terminal ouverts puis fermés ; tactile ≥ 1 000 px (feuille) inclus : `padding-bottom` = `scroll-padding-block-end` ≥ `#ask` + `#vf-coin` mesurés + marges (+ feuille de détail ouverte, + pastille « Terminal » toujours) ; après Fin, ↓ sur la dernière rangée, et focus sur une carte du bas, le rectangle de l'élément focalisé ou sélectionné n'intersecte ni `#ask`, ni `#vf-coin`, ni la pastille « Terminal », ni la feuille de détail, ni le tiroir Git, ni le panneau, ni le tiroir du terminal |
| Clavier | un seul arrêt de tabulation par collection ; ←/→/↑/↓ comme § 5 ; focus jamais sur `body` après bascule, plongée, remontée |
| Annonce | la zone `status` reçoit « Affichage en liste, N phases » à la bascule et « Trié par … » au tri |
| Contraste | table § 5 remesurée en rendu dans les deux thèmes ; texte ≥ 4,5:1, non-texte ≥ 3:1 ; glyphe « En cours » ≥ 3,5:1 (cible P80-D-20, rouge en clair tant que le lot jetons n'est pas livré) ; « Retour » désactivé mesuré sur le fond réel du panneau |
| Mouvement réduit | `document.getAnimations().length === 0` hors panneau ; aucune transition de survol ; `scrollIntoView` non lissé ; le panneau garde sa variante existante (transition nulle en `reduce`), mesurée à part |
| Direct | un patch du direct redessine les couloirs sur `on('render')` ; les champs `avancement` et `exigences` arrivent par la relecture de l'événement `graphe` (A5) ; avant la 79, au rechargement (le témoin ne prétend pas au direct) |

## 8. Écarts et points ouverts (à signaler au manager, non tranchés)

1. **Grille d'espacement.** Les maquettes de `DESIGNS.md` § 6 (page `audit-cockpit.html`) écrivent `padding: 10px 12px`,
   `gap: 10px` (barre) et une colonne de 34 px : « ni 10 » contredit DESIGN § 4 (P71.5-D-01). La spec suit `DESIGN.md` (12, 16).
2. **Fond des cartes.** La maquette pose les phases sur `--raise`. DESIGN § 5 pose la carte sur `--surface` ; `--text-4` sur
   `--raise` tombe à 4,09:1 en sombre et une teinte d'état sur `--raise` à 2,85:1 en clair. La spec suit `DESIGN.md`.
3. **Barre de jalon.** DESIGNS § 6 la dit « neutre » ; DESIGN § 5 teinte (`--warn-text`) la barre d'un élément en cours
   (< 100 %). La spec suit `DESIGN.md` (neutre à 0 et 100 %, `--warn-text` entre les deux). À confirmer si Samuel la
   veut toujours neutre.
4. **Ligne d'état sur Fait.** La maquette n'en met pas sur les cartes Fait ; P80-D-03 la veut sur chaque carte. La spec la
   met partout.
5. **DESIGNS § 7** (« une bascule à chaque niveau, touche `v` ») contredit DESIGNS § 1 (« Code reste une carte ») et
   P80-D-05 (Projet seulement) : la spec suit P80-D-05.
6. **Panneau par-dessus, sans réserve** (décision du manager, P80-D-29 révisée ; DESIGN § 5 fait foi). À 1 440 px le panneau
   (≈ 360 px) recouvre le couloir Fait et le bord d'À recetter ; à 1 024 px, la moitié de À recetter et tout Fait. Seul remède
   spécifié : ramener la carte sélectionnée dans la partie visible par un défilement horizontal instantané, rendu possible par
   une extrémité défilable de largeur `--pw` ajoutée au rail panneau ouvert, **à partir de 1 000 px au pointeur fin seulement**
   (P80-D-50 b ; elle agrandit l'étendue défilable, ne déplace aucun couloir). Si le juge y lit une « réserve », l'alternative est de ne rien ajouter : les couloirs recouverts ne se
   voient alors qu'en fermant le panneau. Le même mécanisme vaut pour les colonnes de droite des listes.
7. **Écarts à `DESIGN.md` assumés** : carte de phase à `padding` 12 × 16 (DESIGN § 5 : 16 sur les quatre côtés) pour tenir
   une carte dense ; titre de carte à 13 px / 500 ou 600 (DESIGN § 3 : 15 px / 600, `.title`) car 15 px ne tient pas en
   ≈ 226 px de couloir ; variante `st-active` sans palier de fond (DESIGN § 5 : palier neutre au-dessus de `--surface-hover`) :
   la phase en cours se distingue par la graisse 600 et `--text`, le palier gris se lisant « désactivé » en thème clair
   (DESIGNS § 8) ; la sélection prend `--surface-hover` et une bordure. Tailles de police employées : 22, 18, 13, 12,5 et 12 px,
   toutes dans l'échelle de DESIGN § 3 hors le 15 px du titre de carte.
8. **Hauteur de carte** corrigée sur mesure de calcul (§ 3) : 62 à 115 px selon la largeur et le nombre de lignes, non 80 à 112.
9. **Hypothèses à vérifier par le planificateur** : ordre réel d'insertion des sections (§ 4.4) ; égalité entre phases
   faites (état) et `meta.vf.milestones[].done` ; hauteurs de `#ask` et de `#vf-coin` lues par mesure (§ 3, `--vf-ask-h` existe
   au téléphone) ; vue DOM bien posée dans `#stage` (sinon le tiroir du terminal ne la relève pas) ; chevron et
   triangle de `details` : composants de la charte à fournir par le lot jetons (F1) ; rang de « Missions hors phase » (§ 1.6) ;
   thème clair : glyphe « En cours » à 3,06:1 sur `--bg`, au-dessus du minimum 3:1 mais sous la cible 3,5:1 (P80-D-20).
10. **Colonnes** : seulement les classes d'écran existantes (≥ 1 000, 701 à 999, ≤ 700) ; plus de seuil de conteneur.
11. **Hauteur de page** : plusieurs jalons actifs empilent plusieurs blocs de 4 couloirs ; aucun repli de bloc n'est spécifié
   (non décidé par P80-D-03). À rouvrir seulement si le témoin à 1 440 px montre un défilement jugé excessif.
