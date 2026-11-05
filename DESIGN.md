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
- **Ambiance** : un graphite sombre et calme, monochrome. L'information porte la couleur, jamais la
  décoration.
- **Émotions** : maîtrise, lisibilité, sérieux sans froideur.
- **Thème** : **sombre d'abord**, avec un thème clair complet (`data-theme="light"`). Le changement de
  thème est instantané, jamais animé.
- **Couleur de marque** : aucune. Le logo (`.mark`, 22 px de haut) est une image blanche, inversée en
  noir sur le thème clair. Le seul accent récurrent est le **vert « récent / fait »**.
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
| Texte secondaire | `--text-2` | `#b4b4b4` | `#3f3f3f` |
| Texte tertiaire | `--text-3` | `#8b8b8b` | `#595959` |
| Texte éteint | `--text-4` | `#5c5c5c` | `#666666` |
| Bouton plein, pastille | `--on` / `--on-text` | `#ececec` sur `#0f0f0f` | `#161616` sur `#fff` |
| Anneau de focus | `--ring` / `--focus` | encre à 88 % / 16 % | noir à 85 % / 14 % |
| Voile de modale | `--scrim` / `--scrim-2` | noir à 45 % / 50 % | `rgba(20,20,20,.32/.38)` |

`--ink` est la couleur de teinte, `255,255,255` en sombre et `0,0,0` en clair. Les filets et les
voiles s'écrivent `rgba(var(--ink), α)` pour suivre le thème tout seuls.

### Sémantique

| Sens | Variable | Sombre | Clair |
|---|---|---|---|
| Récent / fait | `--recent` (texte dessus `--on-recent-text`) | `#4ade80` | `#157a3a` |
| Succès | `--ok`, `--ok-bg`, `--ok-text` | `#6fd7a8` | `#1a8a5b` |
| Sévérité haute (erreur, bloqué) | `--sev-high`, `--err-text` | `#f28b8b` | `#c94a4a` |
| Sévérité moyenne (attention, en cours) | `--sev-medium`, `--warn-bg`, `--warn-text` | `#f0c36b` | `#946000` |
| Sévérité basse | `--sev-low` | `#8b8b8b` | `#666666` |

### Statuts de travail (onglet Projet, Phases 69 et 68)

| Statut | Variable | Doit valoir |
|---|---|---|
| Fait | `--st-done` | `var(--recent)` |
| En cours, à recetter | `--st-active` | `var(--sev-medium)` |
| À faire | `--st-todo` | `var(--text-4)` |
| Bloqué | `--st-blocked` | `var(--sev-high)` |

> **Écart corrigé** (recette de la Phase 69, arbitrage Samuel, AskUserQuestion, session principale,
> 2026-11-04) : dans `ui/00-vibeflow.js`, `--st-active` vaut `var(--sev-medium)` et `--st-blocked`
> `var(--sev-high)`, comme la colonne « Doit valoir » ; le texte des pastilles est teinté vers `--text`
> pour tenir 4,5:1 dans les deux thèmes.
> « À recetter » garde la couleur « en cours » et s'écrit en toutes lettres (P69-D-25).

### Graphe de code (vendorisé, ne pas étendre sans besoin)

- Familles de nœuds : `--n-*` (ui, service, worker, library, feature, data, config, test, script,
  infra, external…).
- Types de liens : `--k-*` (import, http, call, rpc, event, queue, data, config, contains).
- Méthodes HTTP : `--m-*` (GET, POST, PUT, PATCH, DELETE, CALL, ANY).

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
- **Carte** : padding 16 sur les quatre côtés (`--inset-card`), gap 8 px entre ses lignes.
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

- **Carte** (`.card`) : fond `--surface`, rayon `--r-card`, ombre `--shadow-card`. Variantes :
  - `recent` : liseré vert de 1,5 px ;
  - `dir` : verre `--dir-bg` ;
  - `module` : fond `--raise` ;
  - `external` : contour seul, fond transparent ;
  - `has-note` : point ambre de 6 px après le titre.
- **Groupe d'onglets** (`.vf-tabs`) : piste `--raise`, rayon 12 px, 4 px de padding (onglet 4 × 12). L'onglet actif
  prend `--surface` et une ombre de 1 px. Un nouvel onglet (par exemple « Équipe », P69-D-17) suit
  exactement ce modèle.
- **Barre de progression** (`.vf-bar`) : 6 px de haut, piste `--raise-2`, remplissage par la couleur
  du statut, en pilule.
- **Chip, badge** : en pilule. Le texte sur fond rouge ou ambre est `--on-sev-text`, jamais un blanc
  en dur.
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
- **Mouvement réduit** : toute animation a une variante `prefers-reduced-motion: reduce` qui la
  coupe.
- **Jamais animé** : le changement de thème (`html.theme-switching`, transitions coupées).

## 7. Icônes

- Pictos au trait, en SVG inline : classe `svg.i`, 16 × 16 px, `stroke: currentColor`, épaisseur
  1,75, extrémités arrondies, sans remplissage.
- La couleur de l'icône vient du texte qui la porte. Jamais d'icône en couleur pleine, sauf la
  pastille de statut.

## 8. Fichiers de référence

| Fichier | Rôle |
|---|---|
| `plugin/cockpit/skills/cockpit-moteur/assets/viewer.html` | variables (`:root`, thème clair), composants du moteur |
| `plugin/cockpit/skills/cockpit-moteur/assets/ui/00-vibeflow.js` | couche VibeFlow : onglets, statuts, barres, « qui travaille » |
| `plugin/cockpit/skills/cockpit-moteur/assets/ui/05-theme.js` | bascule de thème |
| `plugin/cockpit/skills/cockpit-moteur/assets/ui/01-vf-responsive.js` | adaptations mobile et tactile |
| `plugin/cockpit/skills/cockpit-moteur/VENDORED.txt` | journal des patchs du moteur vendorisé |

Stack : HTML, CSS et JS vanilla servis en local. Pas de Tailwind, pas de framework. Le système de
design, ce sont les variables CSS de `viewer.html`.

## 9. Règles strictes

**Toujours**
- Passer par les variables du thème : une couleur, une ombre ou un rayon écrits en dur dans un
  composant sont un défaut.
- Passer par les jetons d'espacement : aucune valeur d'espacement hors jeton (`--sp-*`, `--edge`,
  `--inset-*`, §4), sauf les exceptions écrites.
- Vérifier chaque écran dans les deux thèmes, sombre et clair.
- Ajouter le style VibeFlow dans les fichiers `ui/*vf*` et le tracer dans `VENDORED.txt` dès qu'on
  touche un fichier du moteur.
- Écrire l'interface en français (texte visible, `aria-label`, infobulles), avec des espaces
  insécables avant `: ; ! ?` et dans « 1 024 px ».
- Rendre chaque élément interactif atteignable au clavier, avec un focus visible (`--ring`).

**Jamais**
- Une couleur de marque ou un dégradé décoratif : l'interface reste monochrome, et seule
  l'information porte la couleur.
- Une variable qui n'existe pas. `--text-1` n'existe pas : on écrit `--text` (écart connu dans
  `00-vibeflow.js`, corrigé en Phase 70).
- Une police chargée depuis un CDN, ou un appel réseau sortant pour l'affichage.
- Une animation sans variante en mouvement réduit, ou plus longue que 700 ms.
- Une nouvelle famille d'ombres, de rayons ou de courbes : on réutilise celles du §4 au §6.
