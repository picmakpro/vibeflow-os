# VibeFlow — Design System & Direction Artistique

> **Direction : « Graphite ».** Elle fige ce qui est déjà à l'écran dans le cockpit (`plugin/cockpit`),
> sans repeinture. Choix de Samuel, AskUserQuestion, session principale, 2026-11-03 : « Figer
> l'existant (Recommandé) ».
>
> **Origine.** La base visuelle vient du moteur vendorisé **floorplan v0.6.0 @ 92d6854** (licence MIT,
> `plugin/cockpit/skills/cockpit-moteur/`). VibeFlow y ajoute sa propre couche, les classes `vf-*` dans
> `assets/ui/00-vibeflow.js` et `70-vf-live.js`. La source de vérité des valeurs est
> `assets/viewer.html` (`:root` et `:root[data-theme="light"]`). Ce document les recopie pour les
> nommer et en fixer l'usage. Si une valeur diverge, c'est le CSS qui fait foi, et ce fichier doit
> être corrigé.
>
> **Pour qui.** Les agents qui touchent une interface VibeFlow : le cockpit (Phases 69, 70, 71, 72),
> vf-signal (Phase 68), et toute future page locale.

---

## 1. Identité visuelle

- **Produit** : un outil de pilotage local pour développeurs, qui montre le projet, le code et
  l'équipe d'agents au travail. Il se lit vite, longtemps, souvent sur un deuxième écran.
- **Ambiance** : un graphite sombre et calme, presque monochrome. L'information porte la couleur, jamais la
  décoration : trois teintes d'état pastel (vert, jaune, corail) sur des neutres.
- **Émotions** : maîtrise, lisibilité, sérieux sans froideur.
- **Thème** : **sombre d'abord**, avec un thème clair complet (`data-theme="light"`). Le changement de
  thème est instantané, jamais animé.
- **Couleur de marque** : aucune. Le logo (`.mark`, 22 px de haut) est une image blanche, inversée en
  noir sur le thème clair. Il n'y a plus d'accent unique : `--accent` vaut `--on` (neutre). Les teintes
  de mise en avant sont les trois couleurs d'état de §2, en jeu « pastel lumineux » : vert (fait, récent),
  jaune sombre / moutarde claire (en cours), corail / rouge (bloqué, haute sévérité). Elles ne servent
  qu'un glyphe, un trait ou un remplissage de barre, jamais un fond ni un contour.
- **Densité** : dense mais aérée. Texte courant à 13,5 px, cartes très arrondies, beaucoup de surface
  sombre entre les blocs.

## 2. Palette de couleurs

Toujours passer par les variables CSS : jamais une couleur en dur dans un composant (voir §9).

### Système

| Rôle | Variable | Sombre | Clair |
|---|---|---|---|
| Fond de page | `--bg` | `#0f0f0f` | `#f3f3f1` |
| Grille du plan | `--grid` | `#1f1f1f` | `#d2d2ce` |
| Surface (carte) | `--surface` | `#191919` | `#ffffff` |
| Surface au survol | `--surface-hover` | `#1e1e1e` | `#fbfbfa` |
| Relief 1 (contrôles, onglets) | `--raise` | `#232323` | `#ebebe8` |
| Relief 2 (pistes, barres) | `--raise-2` | `#2b2b2b` | `#e0e0dc` |
| Filet | `--hair` / `--hair-2` | encre à 6 % / 10 % | noir à 9 % / 15 % |
| Texte principal | `--text` | `#ececec` | `#161616` |
| Texte secondaire | `--text-2` | `#c6c6c6` | `#3f3f3f` |
| Texte tertiaire | `--text-3` | `#a8a8a8` | `#595959` |
| Texte éteint | `--text-4` | `#828282` | `#666666` |
| Accent (neutre) | `--accent` | `var(--on)` | `var(--on)` |
| Fond de boîte d'information | `--note-bg`, `--warn-bg` | encre à 5 % | noir à 5 % |
| Bouton plein, pastille | `--on` / `--on-text` | `#ececec` sur `#0f0f0f` | `#161616` sur `#fff` |
| Anneau de focus | `--ring` / `--focus` | encre à 88 % / 16 % | noir à 85 % / 14 % |
| Voile de modale | `--scrim` / `--scrim-2` | noir à 45 % / 50 % | `rgba(20,20,20,.32/.38)` |

`--ink` est la couleur de teinte, `255,255,255` en sombre et `0,0,0` en clair. Les filets et les
voiles s'écrivent `rgba(var(--ink), α)` pour suivre le thème tout seuls.

### Sémantique

| Sens | Variable | Sombre | Clair |
|---|---|---|---|
| Récent / fait, succès, en cours d'écriture | `--recent` (encre dessus `--on-recent-text`) | `#9ece6a` | `#009e5a` |
| Sévérité haute (erreur, bloqué) | `--sev-high` | `#ff9aa8` | `#f2384a` |
| Sévérité moyenne (attention, en cours) | `--sev-medium` | `#ffe08a` | `#b88100` |
| Sévérité basse | `--sev-low` | `#8b8b8b` | `#666666` |

`--ok` est un alias de `--recent`, `--ok-bg` de `--note-bg`, `--ok-text` de `--recent-text`, `--warn-sheet` de `--menu-solid` (P71.5-D-26, D-29) : on garde les noms, on ne crée plus d'usage nouveau.

Texte d'état (le texte coloré lit au moins 4,5:1) :

| Sens | Variable | Sombre | Clair |
|---|---|---|---|
| Succès, récent | `--recent-text` (`--ok-text`) | `#9ece6a` | `#007f3d` |
| Attention | `--warn-text` | `#ffe9a8` | `#986300` |
| Erreur | `--err-text` | `#ffb3bc` | `#da1637` |
| Encre sur puce pleine | `--on-sev-text`, `--on-recent-text` | `#0f0f0f`, `#0b1f12` | `#161616` |

### Statuts de travail (onglet Projet, Phases 69 et 68)

| Statut | Variable | Doit valoir |
|---|---|---|
| Fait | `--st-done` | `var(--recent)` |
| En cours | `--st-active` | `var(--sev-medium)` |
| À recetter | `--st-recette` | `var(--st-active)` |
| À faire | `--st-todo` | `var(--text-4)` |
| Bloqué | `--st-blocked` | `var(--sev-high)` |

> **Écart corrigé** (recette de la Phase 69, arbitrage Samuel, AskUserQuestion, session principale,
> 2026-11-04) : dans `ui/00-vibeflow.js`, `--st-active` vaut `var(--sev-medium)` et `--st-blocked`
> `var(--sev-high)`, comme la colonne « Doit valoir » ; le texte des pastilles est teinté vers `--text`
> pour tenir 4,5:1 dans les deux thèmes.
> « À recetter » a la teinte de « en cours » et se distingue par son glyphe (anneau et point) et son mot, sur la carte de phase comme dans le panneau (statut `recette`, classe `st-recette`, mêmes paliers que `st-active`) (P69-D-25, P71.5-D-20). Le glyphe est la seule couleur d'une pastille ; le mot est en `--text-2`.
> Une famille du graphe qui valait une teinte d'état la suit (`--n-worker`, `--k-queue`, `--m-PUT` = `--sev-medium` ; `--n-library`, `--m-GET` = `--recent` ; `--n-infra`, `--m-DELETE` = `--sev-high`).
> **En thème clair, une teinte d'état ne se pose ni sur `--raise` ni sur `--raise-2`** (2,6 à 2,9:1) : seules les variantes texte y reposent.

### Graphe de code (vendorisé, ne pas étendre sans besoin)

- Familles de nœuds : `--n-*` (ui, service, worker, library, feature, data, config, test, script,
  infra, external…).
- Types de liens : `--k-*` (import, http, call, rpc, event, queue, data, config, contains).
- Méthodes HTTP : `--m-*` (GET, POST, PUT, PATCH, DELETE, CALL, ANY).
- Lentilles d'activité (Phase 75) : points chauds, couplage, gardes et empreinte marquent une carte par un glyphe neutre et un mot, jamais par une teinte ; la seule teinte est `--recent` (écriture en cours).

Ces familles ont une valeur sombre et une valeur claire. Une nouvelle catégorie réutilise une
couleur existante avant d'en créer une.

## 3. Typographie

- **Texte** : `--sans` = `"Inter", ui-sans-serif, system-ui, -apple-system, "Segoe UI", sans-serif`.
- **Code, chemins, identifiants** : `--mono` = `"JetBrains Mono", ui-monospace, "Cascadia Code", "SF Mono", Consolas, monospace`.
- Les polices sont embarquées à l'assemblage (`/*__FONTS__*/`) : aucun appel à un CDN.
- Lissage `-webkit-font-smoothing: antialiased`.

| Niveau | Taille | Graisse | Interlettrage | Usage |
|---|---|---|---|---|
| Grand titre | 22-24 px | 600 | -.02em / -.025em | rare, un ou deux usages |
| Titre de section | 18-20 px | 600 | -.015em | titres de panneau |
| Titre de carte | 15 px | 600 | -.015em | `.title`, deux lignes au plus |
| Titre mono | 13 px | 500 | 0 | `.title.mono` |
| Corps | **13,5 px** | 400 | 0 | `html, body` |
| Interface | 13 px | 500 | 0 | onglets (`.vf-tabs a`), libellés |
| Courant dense | **12-12,5 px** | 400/500 | 0 | la majorité des métadonnées |
| Petit | 11-11,5 px | 500 | .02em | pastilles, compteurs |
| Micro | 10,5 px | 600 | .02em | badges |

Seules deux graisses servent vraiment, 500 et 600. Le 700 est réservé à un cas d'exception.

## 4. Spacing & Layout

- **Pas de base** : grille fermée de 8 avec demi-pas : 2, 4, 6, 8, 12, 16, 20, 24, 32 (ni 10, ni 14, ni 22).
  Jetons primitifs `--sp-2` à `--sp-32` (un primitif ne change jamais de valeur) et sept jetons
  sémantiques : `--edge` 16 (tout ce qui touche un bord de fenêtre), `--inset-panel` 20 (bord d'un
  conteneur flottant : panneau, feuille, visite, modale), `--gap-section` 24 (entre deux sections),
  `--inset-card` 16, `--inset-box` 12 (boîtes d'information), `--inset-row` 8 × 12 (lignes de liste,
  items de menu), `--inset-pill` 2 × 8 (pastilles, tags). Règle : intérieur ≤ extérieur (ligne 8,
  boîte 12, panneau 20), un seul écart entre deux frères (jamais deux marges qui s'additionnent).
  Les plus fréquents sont 6, 8 et 12 px.
- **Règle : aucune valeur d'espacement hors jeton.** `padding`, `margin`, `gap`, `top/right/bottom/left`
  s'écrivent `var(--sp-N)`, un jeton sémantique, un `calc()` de jetons, `0` ou `auto`. Exceptions
  écrites, en liste fermée : les filets et bordures (1 et 1,5 px), l'alignement optique écrit
  `calc(var(--sp-N) + 1px) /* optique : … */`, les géométries dérivées commentées `/* dérivé : … */`
  (un bas de 96 px posé au-dessus de la barre de question, le décalage du halo du titre), les
  hauteurs et tailles de contrôle (24, 28, 32, 36, 44 px) et les barres d'une seule ligne, qui sont des
  contrôles et gardent 12 en haut, en bas et côté bouton (barre du tiroir, `#flowbar`, `#ask-warn`).
- **Gouttière de carte** : `--gutter` 24 px (réserve d'ombre, égale à la constante `GUTTER` du
  viewer). **Panneau latéral** : `--panel-w` 360 px (+ 32 px de marge, `--pw`).
- **Carte** : padding 16 sur les quatre côtés (`--inset-card`), gap 8 px entre ses lignes. Sur l'onglet Code, un pied de 28 unités est réservé à toute carte marquable, posé à la construction du graphe : la géométrie ne change ni avec la lentille ni avec la présence de git. Le contour pointillé de 1,5 px de la carte prévue se pose en `outline` à décalage négatif, sans bordure : le contenu ne bouge pas.
- **Rayons** :

| Élément | Variable / valeur |
|---|---|
| Carte | `--r-card` 20 px |
| Panneau, tiroir, modale | `--r-panel` 24 px |
| Contrôle (champ, groupe d'onglets) | `--r-ctl` 12 px |
| Onglet dans son groupe | 9 px |
| Petit bouton, icône carrée | 8-10 px |
| Pastille, chip, barre de progression | 999 px (pilule) |

Le rayon de 9 px de l'onglet est une exception écrite : le rayon concentrique avec un rail de 4 px
serait 8, mais les rayons ne font pas partie de la grille d'espacement.

- **Points de rupture** : ≤ 700 px (téléphone), ≤ 999 px (tablette, ou tout écran tactile),
  ≤ 1 279 px en tactile. Le tactile (`pointer: coarse`) est traité comme un écran plus étroit.

## 5. Composants

- **Carte** (`.card`) : fond `--surface`, rayon `--r-card`, `--shadow-card`, c'est sa seule élévation. Variantes :
  - `st-prevu` : fond transparent, contour pointillé de 1,5 px `--hair-2`, sans ombre, glyphe anneau à trois arcs (`--st-todo`) et mot « Prévu » dans le pied ; le statut reprend `--st-todo` ;
  - `st-active` : palier neutre un cran au-dessus de `--surface-hover` (`--raise` allégé), titre 600 `--text` ; `st-done` et `st-todo` : titre 500 `--text-2` ;
  - `st-blocked` : aucun anneau ; glyphe anneau-barré et mot « Bloqué » dans le pied ;
  - `dir` : verre `--dir-bg` ;
  - `module` : fond `--raise` ;
  - `external` : contour seul, fond transparent ;
  - `has-note` : point de 6 px après le titre (`--sev-medium`).
- **Pastille de statut** (`.vst`) : 20 px de haut à l'échelle 1 (`line-height 16` + `padding var(--inset-pill)` vertical), pastille sans fond : glyphe et mot. Un glyphe coloré (coche fait, demi-disque en cours, anneau-point à recetter, anneau à faire, anneau barré bloqué, anneau barré en diagonale abandonnée) suivi du mot en `--text-2`, 11 px, 500. Le glyphe suit la taille de police (`em`), donc les paliers du zoom d'éloignement ; il vaut 1,45 em (16 px à l'échelle 1, la hauteur de ligne), assez pour distinguer le demi-disque « en cours » de l'anneau-point « à recetter » à 1x. Un lien qui porte une pastille ne la souligne jamais : seul son libellé l'est.
- **Marque de lentille** (`.lm`) : posée dans l'emplacement droit du pied de carte, glyphe 1,45 em et mot 11 px `--text-2`, sans fond. Glyphes : barres 1, 2 et 3 (largeur de 3 au moins), confluent, bouclier, bouclier barré, rond plein, triangle plein, carré creux, tiret, anneau à trois arcs. Aux paliers `lod-low`, le glyphe seul. Une clé de glyphe inconnue se rend par le glyphe neutre (carré creux `--text-3`).
- **Menu des lentilles** (`#lens-menu`) : rangées radio ; la légende et le radar sont hors du `role="menu"`, qui ne porte que les rangées. Le bouton-compte de la rangée `.k` (glyphe confluent, `--text-2`, anneau `--ring` en pseudo-élément) ouvre le panneau des collisions. La pastille de compte reste la pastille neutre `--on`, sans exception.
- **Groupe d'onglets** (`.vf-tabs`) : piste `--raise`, rayon 12 px, 4 px de padding (onglet 4 × 12). L'onglet actif
  prend `--surface` et une ombre de 1 px. Un nouvel onglet (par exemple « Équipe », P69-D-17) suit
  exactement ce modèle.
- **Barre de progression** (`.vf-bar`) : 6 px, piste `--raise-2`, remplissage `--text-3` neutre ; seule la barre d'un élément en cours (< 100 %) prend `--warn-text`. Une barre à 100 % est neutre.
- **Boîte d'information** (callout, `.engine.warn`, `.hc-calm`, `.xp-err`, travaux récents) : fond neutre (`--warn-bg`, `--ok-bg`, `--note-bg`) posé sur `--surface`, jamais un fond teinté.
- **Verbe HTTP** (`.method`) : point `--m` de 6 px et verbe en `--text-2`, sans fond.
- **Chip, badge** : en pilule. Le texte sur fond rouge ou jaune est `--on-sev-text` (encre, jamais un blanc
  en dur).
- **Panneau, tiroir** : rayon `--r-panel`, fond `--elev` (surface translucide), ombre `--shadow-float`.
  Il se pose au-dessus du plan sans le pousser.
- **Menus et palettes** : `--menu-solid`, `--palette-bg`, `--modal-bg`, toujours sur un voile `--scrim`.
- **Boutons pleins** : `--on` / `--on-text`, survol `--on-hover`.
- **Ombres** : `--shadow-card` (au repos), `--shadow-float` (flottant), `--shadow-lift` (soulevé au
  survol), `--shadow-deep` (modale). Il n'y a pas d'autre ombre.

## 6. Animations

- **Courbes** : `--ease` = `cubic-bezier(.16, 1, .3, 1)` pour presque tout, et `--ease-io` =
  `cubic-bezier(.65, 0, .35, 1)` pour un aller-retour.
- **Durées** : 150 ms (survol), 200 ms (le défaut), 250-300 ms (ouverture d'un panneau),
  450 ms (grands déplacements). On ne dépasse pas 700 ms.
- **Respiration du glyphe « actif »** (glyphe « en cours » de l'empreinte, sur les cartes ; elle a quitté les tiroirs) : une échelle de 1 à .82 en 2,4 s, jamais une variation d'opacité (le glyphe garde son contraste à chaque instant : `--st-active` clair fait 3,06:1 sur `--bg`, aucun palier d'opacité n'y tient 3:1).
- **Mouvement réduit** : toute animation a une variante `prefers-reduced-motion: reduce` qui la
  coupe.
- **Jamais animé** : le changement de thème (`html.theme-switching`, transitions coupées).

## 7. Icônes

- Pictos au trait, en SVG inline : classe `svg.i`, 16 × 16 px, `stroke: currentColor`, épaisseur
  1,75, extrémités arrondies, sans remplissage.
- La couleur de l'icône vient du texte qui la porte, avec une seule exception : les icônes de nœud du graphe de code (onglet Code : carte, résultat de recherche) prennent la couleur de leur famille (`--n-*`), parce que ce type est l'information. Ailleurs (Projet, Équipe, panneaux) l'icône est nue, de la couleur de son texte, sans tuile ni fond coloré. Jamais d'icône en couleur pleine, sauf le glyphe d'une pastille de statut, y compris le glyphe « en cours » de l'empreinte.

## 8. Fichiers de référence

| Fichier | Rôle |
|---|---|
| `plugin/cockpit/skills/cockpit-moteur/assets/viewer.html` | variables (`:root`, thème clair), composants du moteur |
| `plugin/cockpit/skills/cockpit-moteur/assets/ui/00-vibeflow.js` | couche VibeFlow : onglets, statuts, barres, « qui travaille » |
| `plugin/cockpit/skills/cockpit-moteur/assets/ui/05-theme.js` | bascule de thème |
| `plugin/cockpit/skills/cockpit-moteur/assets/ui/01-vf-responsive.js` | adaptations mobile et tactile |
| `plugin/cockpit/skills/cockpit-moteur/VENDORED.txt` | origine du moteur, sentinelle de détection du moteur, inventaire de nos fichiers (plafond de 300 lignes) |

Stack : HTML, CSS et JS vanilla servis en local. Pas de Tailwind, pas de framework. Le système de
design, ce sont les variables CSS de `viewer.html`.

## 9. Règles strictes

**Toujours**
- Passer par les variables du thème : une couleur, une ombre ou un rayon écrits en dur dans un
  composant sont un défaut.
- Passer par les jetons d'espacement : aucune valeur d'espacement hors jeton (`--sp-*`, `--edge`,
  `--inset-*`, §4), sauf les exceptions écrites.
- Vérifier chaque écran dans les deux thèmes, sombre et clair.
- Sur `.card.module` en clair, faire prendre à un glyphe d'état la variante texte (`--recent-text`), jamais `--recent` (2,91:1).
- Ajouter le style VibeFlow dans les fichiers `ui/*vf*` ; un fichier à nous posé sous le moteur
  s'inscrit en `AJOUT` dans `VENDORED.txt` (il entre ainsi dans le plafond de 300 lignes) ;
  l'édition d'un fichier d'origine du moteur ne se trace nulle part (fork assumé, P79-D-07).
- Écrire l'interface en français (texte visible, `aria-label`, infobulles), avec des espaces
  insécables avant `: ; ! ?` et dans « 1 024 px ».
- Rendre chaque élément interactif atteignable au clavier, avec un focus visible (`--ring`).
- Faire lire l'état sans la couleur : un glyphe de forme distincte et un mot ; la couleur ne fait que renforcer (daltonisme, niveaux de gris, zoom éloigné).
- Poser les textes colorés sur `--surface` avec une variante `--*-text` à 4,5:1 ; un glyphe, un trait ou une barre d'état à 3:1 sur `--surface` et `--bg`.

**Jamais**
- Une couleur de marque, un accent unique ou un dégradé décoratif : l'interface reste neutre, seule l'information porte la couleur (trois teintes d'état).
- Une variable qui n'existe pas. `--text-1` n'existe pas : on écrit `--text` (écart connu dans
  `00-vibeflow.js`, corrigé en Phase 70).
- Une police chargée depuis un CDN, ou un appel réseau sortant pour l'affichage.
- Un liseré, un contour ou une bordure colorés (latéral, haut, ou anneau de carte) : la couleur d'un état ne dessine pas un conteneur.
- Un fond teinté pour un état (bandeau, callout, pastille, tuile d'icône, hero-metric, puce de verbe) : une boîte d'information est neutre.
- Un halo coloré (ombre diffuse ou lueur, y compris `drop-shadow`, `box-shadow` flou teinté).
- Deux intentions d'élévation sur une même carte (anneau et ombre, halo et ombre) : une seule.
- Une teinte d'état (glyphe, trait, remplissage) sur `--raise` ou `--raise-2` en thème clair (sous 3:1) : seules les variantes texte y reposent.
- Un titre de section en capitales espacées (« kicker ») au-dessus d'un titre.
- Une animation sans variante en mouvement réduit, ou plus longue que 700 ms.
- Une nouvelle famille d'ombres, de rayons ou de courbes : on réutilise celles du §4 au §6.
