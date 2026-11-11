---
phase: "76"
slug: "tracabilite-au-cockpit"
status: draft
shadcn_initialized: false
preset: none
created: "2026-11-11"
---

# Phase 76 : Traçabilité au cockpit — UI-SPEC

**Contrat de design** pour la section « Traçabilité » du panneau d'une phase, les trois sections repliées de la vue
d'ensemble de Projet (« Jalon », « Décisions », « Mémoire des agents ») et les panneaux d'une exigence, d'une ADR,
d'une décision et d'une entrée de mémoire. Direction « Graphite » (`DESIGN.md`).

Sources lues : `76-CONTEXT.md` (P76-D-01..29, amendé le 2026-11-11 sur le Retour commun de la Phase 80), `REQUIREMENTS.md`
(TRAC-01..12), `DESIGN.md`, `DESIGNS.md` § 1, § 2, § 9, `78-UI-SPEC.md` (modèle), `viewer.html` (`:root`, `#panel`, `.sec`,
`.row`, `.more`, `.group-h`, `renderPanel`, API `SC`), `ui/00-vibeflow.js` (masques de glyphes `G_ST`, `.vst`, `.vf-link`,
`.vf-ref`, `.vf-copie`, `details.vf-tech`), `ui/77-vf-git-tiroir.js` (`VFGitTiroir`). Aucune brique externe de craft
consultée : dégradation sur les premiers principes (contraste WCAG, grille fermée, hiérarchie).

**Règles d'écriture de ce document et du copy.** Libellés en français, exacts. À l'affichage, une espace insécable
(U+00A0) précède `: ; ! ?` et sépare un nombre de son unité (« 1 024 px », « 2 000 liens ») ; le document écrit des espaces
ordinaires pour rester lisible, l'exécutant pose les insécables. Aucun tiret cadratin dans le copy. Tout texte venu des
fichiers du lab (nom d'exigence, titre d'ADR, ligne de décision, sujet de commit, `name:` de mémoire, statut lu) s'écrit en
`textContent`, jamais en `innerHTML`. Classes neuves en `vf-trace-*`, dans le ou les fichiers de page
`ui/7x-vf-trace*.js` (numéro fixé au plan ; 74 est libre aujourd'hui, **à revalider**) ; rien dans `viewer.html`, rien dans
`00-vibeflow.js`.

## 0. Bornes qui encadrent le contrat (rappel, non rouvert)

- Lecture seule : aucun bouton qui écrit, coche, corrige ou crée. Aucune action, ni « copier la commande » ni lancement ;
  la seule interaction est d'ouvrir un objet, de plier, de dérouler, de copier un chemin (comportement existant
  `.vf-copie`).
- Pas de canevas, pas de dessin de nœuds et d'arêtes, pas de quatrième onglet, pas de nouvelle vue plein cadre, aucune
  modification de `viewer.html` (P76-D-01, P76-D-02, P78-D-04).
- Surface unique : le `#panel` existant (colonne de 360 px à droite, feuille basse sous 700 px). Aucun tiroir neuf, aucun
  `z-index` neuf, aucune classe posée sur `body`, aucun `padding` du plan modifié : la carte n'est jamais poussée (Q12).
- Les trois sections de la vue d'ensemble et la section de la phase n'existent que sur l'onglet Projet servi par le
  serveur (`TAB === 'project'` et `window.FLOORPLAN_SERVER`). Dans une page autonome ou un export : pas de section, pas
  de ligne « indisponible » (P76-D-11).
- Ni fond teinté, ni texte coloré, ni liseré ou contour coloré : une teinte d'état ne vit que dans un glyphe ou un trait
  (Q9, P71.5-D-12, D-19, D-21, D-27, D-28). Grille d'espacements fermée (P71.5-D-01). Points de rupture inchangés (Q11).
- Rien de la mémoire des agents au-delà de `name`, agent, `metadata.type`, jour du dernier commit, nombre de liens entrants
  et sortants, chemins du dépôt absents (P76-D-20). Aucun titre ni résumé écrit par un modèle (PU-G-162).
- Le Retour n'est pas dessiné par cette phase : c'est le bouton « Retour » de l'en-tête du panneau, pile de sélections
  commune de la Phase 80 (`VibeFlow.panneau.retour()`, P80-C76-3, P76-D-03 amendé). La 76 y empile en appelant `select(id)`
  ou `reveal(id)`. **À revalider** à l'exécution : que l'en-tête commun reste présent au-dessus d'un panneau posé par
  `SC.showPanel` ; sinon, c'est un point à rouvrir avec la 80, jamais un bouton « Retour » propre à la 76.

## Design System

| Propriété | Valeur |
|-----------|--------|
| Outil | none (HTML, CSS et JS vanilla servis en local ; pas de shadcn, pas de Tailwind) |
| Preset | non applicable |
| Bibliothèque de composants | aucune ; briques du moteur et de la couche VibeFlow (voir « Briques réutilisées ») |
| Icônes | `svg.i` 16 px, trait 1,75, extrémités arrondies ; glyphes d'état en masques SVG teintés par `--c-st` |
| Polices | `--sans` (Inter), `--mono` (JetBrains Mono) ; aucune police neuve |

## Briques réutilisées (non exhaustif)

Relevées par `grep -n "^\.sec\|^\.pt\|^\.ph \|^\.pd\|^\.more\|^\.group-h\|^\.tag\|^\.btn\.soft\|^\.row" viewer.html` et
`grep -n "\.vf-ref\|\.vf-copie\|\.vf-link\|details.vf-tech\|\.vst" ui/00-vibeflow.js`, état du dépôt au 2026-11-11. Ce n'est
pas un inventaire de bibliothèque, seulement les briques à réemployer avant d'en écrire une.

| Brique | Où | Usage ici |
|--------|----|-----------|
| `.sec`, `.sec h3`, `.sec h3 .c` | `viewer.html` | Enveloppe de chaque section ajoutée ; titre 12,5 px/500 `--text-3` et compteur `--text-4` |
| `.ph`, `.ph .kindlabel`, `.pt`, `.pd` | `viewer.html` | En-tête des panneaux d'objet : type en ligne, titre 20 px/600, texte courant |
| `.group-h` | `viewer.html` | Intertitre d'un groupe (par plan dans « Preuves attachées ») |
| `.tag` | `viewer.html` | Type de mémoire (`metadata.type`), identifiants de plan |
| `.btn.soft` | `viewer.html` | « Réessayer », « Précédentes », « Suivantes » |
| `.vf-ref`, `.vf-copie`, `.vf-copie-etat` | `ui/00-vibeflow.js` | Chemin relatif copiable au clic, retour « Copié » 1,6 s (gestionnaire de clic déjà posé sur `document`) |
| `.vst` + `vst-*` | `ui/00-vibeflow.js` | Pastille d'état de phase des lignes du « Jalon » (glyphe + mot) |
| `details.vf-tech` (motif) | `ui/00-vibeflow.js` | Motif du repli natif `details`/`summary` ; reproduit sous `.vf-trace-repli` |
| `SC.addPanelSection`, `SC.showPanel`, `SC.reveal`, `select` | `viewer.html`, API `SC` | Seuls points d'accroche (P76-D-02) |

## 1. Vocabulaire des états (glyphe + mot)

Le sens ne repose jamais sur la couleur seule : forme distincte et mot. Les masques ci-dessous suivent le patron
`GLYPHE(...)` de `00-vibeflow.js` (carré de 16, trait 1,75, `stroke='black'`, teinté par `--c-st`). Le glyphe vaut
`1.45em` de la police du mot, soit 16 px à 11,5 px de police.

### 1.1 Maillons d'une exigence (plan, SUMMARY, VERIFICATION, recette)

| État du maillon | Glyphe (forme) | Teinte | Mot | Fonde |
|-----------------|----------------|--------|-----|-------|
| Lu | coche (tracé de `done`, copié) | `--text-2` | « lu » | champ ou citation lu (P76-D-14) |
| Manque | anneau vide (forme de `todo`) | `--text-4` (`--st-todo`) | « manque » | absence simple, neutre (P76-D-04) |
| Non lisible | anneau et « i » (forme de `info`) | `--text-3` | « non lisible » | SUMMARY sans frontmatter : pas « manque » (P76-D-14) |
| Contradiction | carré arrondi (`rx` 3) barré du signe « différent de » : `<rect x='2' y='2' width='12' height='12' rx='3'/>` et `<path d='M5.5 6.6h5M5.5 9.4h5M9.6 4.8L6.4 11.2'/>` | `--st-blocked` (= `--sev-high`, corail) | « contradiction » | contradiction lue (P76-D-04, P76-D-15) |

Le glyphe « lu » est neutre à dessein : le vert dit « fait » ailleurs (statut de travail), et quatre coches vertes par ligne
noieraient le seul signal qui demande une action. **Décision déléguée par Samuel (message session principale, 2026-11-08),
option recommandée** : le corail est réservé aux contradictions ; vert et jaune ne servent dans cette phase que par le
glyphe `.vst` de phase réemployé dans le « Jalon ». Confirmation « Les trous en rouge » : voir § 12, A-1.

Chaque maillon dit son niveau : « niveau exigence » (l'identifiant est cité dans le fichier ou le champ) ou « niveau phase »
(le fichier existe, il ne cite pas l'identifiant). Dans la bande, le niveau vit dans le `title` et l'`aria-label` du glyphe ;
dans le panneau d'exigence, il est écrit.

### 1.2 États de la mémoire des agents

| État | Glyphe | Teinte | Mot | Nature |
|------|--------|--------|-----|--------|
| Hors index (absente de son `MEMORY.md`, égalité exacte du nom de fichier) | carré barré (contradiction) | `--st-blocked` | « hors index » | contradiction |
| Lien cassé (ni `name:` ni nom de fichier) | carré barré | `--st-blocked` | « lien cassé » | contradiction |
| Cite un chemin absent (relatif au dépôt, absent de HEAD, présent dans l'historique lu) | carré barré | `--st-blocked` | « cite un chemin absent » | contradiction |
| Résolu par nom de fichier | anneau et « i » | `--text-3` | « résolu par nom de fichier » | état propre, compté |
| Sans lien entrant (les liens d'index ne comptent pas) | aucun glyphe | `--text-3` | « sans lien entrant » | filtre neutre, jamais un verdict |

Aucun mot « périmée » : la date est une information (« modifiée le 8 nov. 2026 »), jamais un verdict (P76-D-22).

## 2. Section « Traçabilité » du panneau d'une phase

**Accroche.** `SC.addPanelSection('item', fn)`, rappel `fn(cible)` à chaque rendu ; la section ne répond que si `cible` est
un identifiant de phase (`ph-<N>` ou `ph-<N>@<ws>`, P80-C76-1) ; sinon elle rend `''`. Position : `{ top: true }`, juste
après la première section du panneau (titre et description de la phase), car c'est la réponse à « où en est cette phase ».
**Décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée.** Contenu chargé à l'ouverture du
panneau par `GET /api/vf/tracabilite?vue=phase&cle=<N>` ; le rendu synchrone livre d'abord le titre et l'état de chargement
(§ 9), l'asynchrone remplit en place (`[data-ext]` rebindé, jamais un `rerender()` de la carte).

**Structure (de haut en bas).**
1. `h3` « Traçabilité » (`.sec h3`) et compteur `.c` = nombre d'exigences rattachées.
2. Ligne de bilan (12,5 px/400, `--text-3`) : « 4 exigences, 1 avec un manque, 1 contradiction ». Singulier à 1
   (« 1 exigence »). Aucun manque ni contradiction : « 4 exigences, toutes avec une chaîne complète ». Jamais de pourcentage
   (P69-D-01).
3. Légende de la bande (11,5 px, `--text-3`) : « Bande : plan, SUMMARY, VERIFICATION, recette. » Une seule ligne, sous le bilan.
4. Liste des lignes d'exigence (≤ 30, puis « + N autres », § 7).
5. Repli « Preuves attachées » (§ 3), fermé par défaut.

**Ligne d'exigence** (un seul `button type="button"`, classe `vf-trace-ligne`, pleine largeur, `margin-inline: calc(-1 * var(--sp-12))`
et `padding: var(--inset-row)` comme `.vf-link`, rayon 10 px comme `.vf-link`) :
- Ligne 1 : identifiant en `--mono` 11,5 px/500 `--text-2` (« TRAC-01 »), puis le texte de l'exigence en 12,5 px/400
  `--text`, `-webkit-line-clamp: 2` (la valeur de `.row .rd`), `overflow-wrap: anywhere`. L'identifiant ne se tronque pas.
- Ligne 2 : la bande (quatre glyphes de 16 px, `gap: var(--sp-4)`, dans l'ordre plan, SUMMARY, VERIFICATION, recette),
  puis, après `margin-left: var(--sp-8)`, un seul mot : le premier trou. Mot en 11,5 px/500 `--text-2`, passe à la ligne
  plutôt que de se tronquer (`white-space: normal`, `min-width: 0`).
- Mot de la ligne, par priorité : (1) contradiction, préfixée « contradiction : » ; (2) premier manque dans l'ordre de la
  bande, « manque : plan », « manque : SUMMARY », « manque : VERIFICATION », « manque : recette » ; (3) premier « non
  lisible », « non lisible : SUMMARY » ; (4) « chaîne complète ». Un seul mot, jamais une liste ; le détail est dans le
  panneau de l'exigence.
- Mots de contradiction (forme courte) : « contradiction : cochée, sans SUMMARY » ; « contradiction : non cochée, SUMMARY
  lu » ; « contradiction : Complete, sans plan » ; « contradiction : ligne sans exigence » ; « contradiction : sans ligne de
  traçabilité ».
- Lecteur d'écran : `aria-label` = « TRAC-01, plan lu, SUMMARY manque, VERIFICATION lu au niveau de la phase, recette
  manque. Ouvrir l'exigence. » (chaque maillon, état puis niveau si « lu » ou « non lisible »).
- États : repos fond transparent ; survol `rgba(var(--ink), .06)` (comme `.row:hover`) ; focus clavier
  `outline: 2px solid var(--ring); outline-offset: -2px` ; actif sans échelle. Le glyphe de contradiction n'est jamais posé
  sur `--raise` ni `--raise-2` (thème clair, sous 3:1) : les lignes reposent sur le fond du panneau (`--elev`) ou `--surface`.
- Clic, Entrée, Espace : ouvre le panneau de l'exigence (§ 5.1) ; focus sur son titre si l'activation vient du clavier.

**Absence de données de rattachement.** Phase sans exigence rattachée : sous le `h3`, une ligne neutre « Aucune exigence
rattachée à cette phase. » (12,5 px, `--text-3`) ; le repli « Preuves attachées » reste montré s'il y a des preuves.

## 3. Preuves attachées (AUDC-I33)

Repli natif `<details class="vf-trace-repli">` dans la section de la phase, fermé par défaut ; `<summary>` : « Preuves
attachées » et compteur `.c` (nombre de fichiers de preuve), 12 px/500 `--text-3`, hauteur 32 px (44 px tactile), curseur
pointeur, focus `outline: 2px solid var(--ring); outline-offset: 2px`, marqueur natif conservé (Entrée et Espace plient).
Même forme que `details.vf-tech` (`> summary` 12 px/500 `--text-3`, survol `--text`, `margin-bottom: var(--sp-8)` ouvert).

Contenu, par groupe `.group-h` : d'abord « Phase » (preuves de la phase), puis un groupe par plan (« 76-01 », mono) :
- une ligne par fichier de preuve existant : libellé (12,5 px/500 `--text`) parmi
  « VERIFICATION », « Recette », « Trace rouge », « Sécurité », « Validation » ; puis le statut lu entre parenthèses,
  « statut : passed » (mot venu du frontmatter ou de la ligne `**Statut :`, `textContent`, `--text-3`) ;
- dessous, le chemin relatif au lab en `--mono` 11,5 px `--text-3`, rendu comme un `.vf-ref` : un clic le copie, le mot
  « Copié » apparaît 1,6 s dans `.vf-copie-etat` (comportement existant, rien de neuf). Le cockpit ne peut pas ouvrir un
  fichier : le chemin est copiable, pas cliquable comme un lien externe. `aria-label` : « Copier le chemin : <chemin> ».
- pour un plan qui porte des `must_haves` : une ligne « Critères du plan » et le compte (« 5 critères »), puis la liste en
  texte (puces ordinaires, 12,5 px `--text-2`, `overflow-wrap: anywhere`, ≤ 30 puis « + N autres »).
- Jamais un contenu de transcript, jamais une capture, jamais une preuve déduite (P76-D-24). Un fichier de preuve absent
  ne produit aucune ligne : l'absence est dite par le glyphe « manque » de la bande, pas ici.
- Aucune preuve : « Aucune preuve attachée. » (12,5 px, `--text-3`).

## 4. Vue d'ensemble de Projet : trois sections repliées

**Accroche.** Trois appels `SC.addPanelSection('overview', fn)` ; `setOverview` n'est jamais touché (il remplace). Ordre :
« Jalon », « Décisions », « Mémoire des agents », posés après le corps de la vue d'ensemble (P80-C76-2). Chaque section est un
`.sec` contenant un `<details class="vf-trace-repli">`, **fermé par défaut**, `<summary>` pleine largeur au style de
`.sec h3` (12,5 px/500 `--text-3`) avec le compteur `.c` (`--text-4`) à droite du titre. L'état ouvert ou fermé est tenu
dans une variable de module (par section) et restauré à chaque rendu de la vue d'ensemble : un re-rendu ne referme jamais
une section ouverte ; il n'est pas mémorisé entre deux chargements de page.

**Chargement paresseux.** À la première ouverture d'une section : `GET /api/vf/tracabilite?vue=jalon`, `vue=adr` (qui
porte aussi les registres) ou `vue=memoire` ; une réponse en cache par empreinte est affichée tout de suite. La clé
`planning` de `VF_ETAT` (changement de `.planning/`) relance l'appel d'une section **ouverte** (jamais d'une section
fermée), sans refermer, sans perdre le défilement (P76-D-06, A13 de la 79).

### 4.1 « Jalon »

Compteur : nombre de phases du jalon actif. Une ligne par phase (`button.vf-trace-ligne`), ≤ 30 puis « + N autres » :
- Ligne 1 : « Phase 76 » (12,5 px/500 `--text`) puis le nom (12,5 px/400 `--text-3`, une ligne, ellipsis), pastille d'état
  de phase `.vst` à droite (glyphe et mot de l'état lu : « À faire », « En cours », « À recetter », « Fait »).
- Ligne 2 : les trous **par maillon**, en mots : « manque : SUMMARY 2, VERIFICATION 1 » (seuls les maillons qui manquent,
  dans l'ordre plan, SUMMARY, VERIFICATION, recette, en 11,5 px/500 `--text-2`) ; si des contradictions : le glyphe de
  contradiction (16 px) puis « 1 contradiction » ; aucun trou : « chaîne complète » (`--text-3`) ; aucune exigence :
  « aucune exigence rattachée » (`--text-3`).
- Clic ou Entrée : ouvre le panneau de la phase par `select('ph-<N>')` (identifiant stable ; `ph-<N>@<ws>` si le
  compartiment le demande), la section « Traçabilité » (§ 2) s'y trouve ; pas de panneau neuf.
- Bilan sous le `summary` (11,5 px, `--text-3`), un compte seulement, pas de phrase d'aide : « 12 phases, 7 avec un manque,
  2 contradictions ».

### 4.2 « Décisions »

Compteur : nombre d'ADR. Contenu en deux blocs :
1. Une ligne par ADR (`button.vf-trace-ligne`) : identifiant `--mono` 11,5 px/500 `--text-2` (« ADR-075 ») puis le titre
   lu après le numéro (12,5 px/400 `--text`, une ligne, ellipsis, `title` = titre complet). ≤ 30, puis « + N autres ADR »
   (liste paginée, § 7). Une ADR citée sans section dans `docs/ADR.md` n'a pas de ligne ici : elle n'apparaît que comme
   identifiant cité dans le panneau d'une décision (§ 5.3).
2. Un repli par registre de phase, sous le groupe `.group-h` « Registres de phase » : `<details class="vf-trace-repli">`
   fermé, `<summary>` « Phase 41 » (12,5 px/500 `--text-2`) et le compte `.c` (« 12 décisions »). Au plus 30 registres,
   du plus récent au plus ancien, puis « + N autres registres ». Un registre déplié liste ses décisions (≤ 30 puis « + N
   autres ») : identifiant mono 11,5 px (« P41-D-02 » ; décision nue « D-04 ») et le début de la ligne de définition
   (12,5 px, `--text-2`, une ligne, ellipsis). Un seul niveau de pliage dans un pliage : retrait gauche `var(--sp-12)`, pas
   plus profond.

### 4.3 « Mémoire des agents »

Compteur : nombre d'entrées suivies. Une ligne par agent (le dossier sous `.claude/agent-memory/`, ≤ 30 puis « + N autres
agents ») :
- Ligne 1 : nom de l'agent en `--mono` 12,5 px/500 `--text`, à droite « 24 entrées » (11,5 px, `--text-3`, tabular-nums).
- Ligne 2 : le glyphe de contradiction (16 px) si l'agent porte au moins une contradiction (hors index, lien cassé, chemin
  absent), puis les comptes en mots : « 3 hors index, 2 liens cassés » ; puis, en `--text-3`, « 11 sans lien entrant » ; rien
  à signaler : « aucun écart » (`--text-3`).
- Clic ou Entrée : ouvre le panneau de liste de l'agent (§ 6), empilé sur la pile commune.
- Ligne de bilan sous le `summary` : « 268 entrées, 12 agents, 33 liens cassés, 143 sans lien entrant » (11,5 px, `--text-3`).
  Chiffres lus dans la route, jamais recalculés côté page.

## 5. Panneaux d'objet (`SC.showPanel(html, bind)`)

`showPanel` remplace tout le contenu du `#panel` : le panneau d'objet porte donc son propre corps complet. Gabarit commun,
dans cet ordre :

1. **Fil d'Ariane** (`<nav aria-label="Fil d'Ariane"><ol>`), en tête, 11,5 px, `--text-3` : ancêtres structurels de
   l'objet, séparés par « › » (`aria-hidden`, `--text-4`), chacun un `button` (dernier maillon = objet courant, texte non
   interactif, `aria-current="page"`, `--text`). Chaque maillon `max-width: 140px`, ellipsis, `title` = texte complet. Il
   dit **où l'objet vit** (parenté), alors que le Retour de l'en-tête commun dit **d'où l'on vient** (historique) : les deux
   ne se confondent pas et la 76 ne dessine pas le second. À 390 px, la liste passe à la ligne (`flex-wrap: wrap`).
   - exigence : « Phase 76 › TRAC-01 » ; ADR : « Décisions › ADR-075 » ; décision : « Phase 41 › P41-D-02 » (décision nue :
     « Phase 41 › D-04 ») ; entrée : « Mémoire des agents › vf-dev-manager › nom-de-l-entrée » ; liste : « … › Liste ».
   - Ancêtre « Phase N » : `select('ph-<N>')`. « Décisions » et « Mémoire des agents » : ferme le panneau d'objet, rend la
     vue d'ensemble avec la section **ouverte** et son `summary` focalisé. Un agent : panneau de liste (§ 6).
2. **Titre** : `.ph` (type de l'objet en `kindlabel` : « Exigence », « ADR », « Décision », « Mémoire ») puis `.pt` 20 px/600.
   Identifiants en `--mono` dans le titre. Chaque objet porte une **ancre** : `id="vf-trace-<vue>-<cle>"` et
   `data-trace="<vue>:<cle>"` sur le titre (le fragment d'URL n'est pas promis : le moteur réécrit son propre hash, **à
   revalider**). Focus sur le titre (`tabindex="-1"`) quand l'ouverture vient du clavier.
3. **Corps** : sections `.sec` (`h3` + compteur), voisins en lignes `button.vf-trace-ligne` (≤ 30 par sorte, § 7).
4. **Pied de source** (`.pd`, 11,5 px, `--text-3`) : « Lu dans <chemin relatif> » en mono, copiable (`.vf-ref`). Jamais un
   chemin absolu ni `~/`.

### 5.1 Exigence

- Titre : identifiant (« TRAC-01 »). Sous le titre, `.pd` : le texte de l'exigence, entier (pas de clamp), `overflow-wrap:
  anywhere`.
- Section « Chaîne » (`h3`) : quatre lignes, une par maillon, pas des boutons (sauf le lien du plan) : glyphe 16 px, nom
  du maillon (12,5 px/500 `--text`), puis sur la même ligne l'état et le niveau en mots (« lu, niveau exigence », « lu,
  niveau phase », « manque », « non lisible »), 11,5 px `--text-3`. Dessous, la source : chemin mono copiable et le champ lu
  (« champ requirements »). Plan : un `.tag` par plan qui la cite (« 76-01 ») ; chaque plan s'ouvre en le sélectionnant sur
  la carte (`select('f:<chemin>')`).
- Section « Contradictions » (absente si aucune) : une ligne par contradiction, glyphe de contradiction et phrase complète en
  `--text-2` (§ 10). Jamais corrigée, jamais un bouton.
- Section « Rattachement » : « Phase 76, Traçabilité au cockpit » (bouton, ouvre la phase), puis « Ligne de traçabilité du
  ledger : Phase 76, Pending » si elle existe, sinon « Rattachée par le champ requirements d'un plan. »
- Pas de section « Décisions citées » : aucune arête exigence vers décision n'est lue (P76-D-17).

### 5.2 ADR

- Titre : « ADR-075 » ; `.pd` : le titre lu après le numéro. Aucun résumé, aucun extrait du corps.
- « Décisions qui la citent » : ≤ 30 lignes (identifiant mono, « Phase 41 »), puis « + N autres ».
- « Commits qui la citent » : ≤ 30 lignes (§ 5.5), puis « + N autres ».
- Source : « Lu dans docs/ADR.md ».

### 5.3 Décision

- Titre : « P41-D-02 » ; décision nue « D-04, Phase 41 » (qualifiée par la phase de son registre, P76-D-16). `.pd` : la ligne
  de définition, entière.
- « Phase » : un bouton qui ouvre la phase. « ADR citées » : une ligne par ADR citée dans la définition ; si l'ADR a une
  section, bouton ; sinon texte seul, mono, suivi de « sans section dans docs/ADR.md » (`--text-3`), non interactif.
- « Commits qui la citent » : ≤ 30 (§ 5.5). Pour une décision nue : aucune section de commits, une ligne neutre
  « Décision nue : aucun commit ne lui est relié, la citation sans phase est ambiguë. » (12,5 px, `--text-3`).
- Source : « Lu dans <registre de phase> » (chemin relatif).

### 5.4 Entrée de mémoire

- Titre : le `name` de l'entrée (mono, peut passer à la ligne). Ligne de rappel (11,5 px, `--text-3`) : « Seule la structure
  est lue : ni description ni contenu. »
- Section « Fiche » : liste de définitions (étiquette `--text-3`, valeur `--text`, 12,5 px) : « Agent » (mono),
  « Type » (`.tag` avec `metadata.type`), « Dernier commit » (« 8 nov. 2026 », jour seul), « Liens sortants » (nombre),
  « Liens entrants » (nombre).
- Section « État » : un mot par état de § 1.2 qui s'applique, avec son glyphe ; « Aucun écart » si aucun.
- Section « Liens sortants » : une ligne par lien (nom cible mono, puis état : « résolu », « résolu par nom de fichier »,
  « lien cassé » avec le glyphe de contradiction). Une cible résolue est un bouton qui ouvre l'entrée ; une cible cassée est
  du texte. ≤ 30, puis « + N autres ».
- Section « Liens entrants » : lignes de boutons, ≤ 30. Les liens d'index (`MEMORY.md`) n'y figurent pas.
- Section « Chemins du dépôt cités » (absente si aucun) : chemin relatif mono ; absent de HEAD : glyphe de contradiction et
  « absent de HEAD, présent dans l'historique lu ».
- Jamais `description`, jamais le corps, jamais un chemin `~/` ou absolu (P76-D-20).

### 5.5 Ligne de commit

`button.vf-trace-commit` : sha court en `--mono` 11,5 px/500 `--text-2` (7 caractères), jour (« 8 nov. 2026 », `--text-3`),
puis le sujet (12,5 px `--text`, une ligne, ellipsis, `title` = sujet complet). Le corps du message n'est jamais servi.
Clic ou Entrée : ouvre le tiroir Git existant (`window.VFGitTiroir.ouvrir()`, Phase 78, détail sans diff) ; la sélection du
commit par son sha dépend d'un crochet de la 78 (`VFGitExt`) **à revalider au plan** ; à défaut de crochet, le tiroir
s'ouvre sans sélection et la ligne ne promet pas davantage. Git absent ou `VFGitTiroir` absent : la ligne est du texte,
non interactive. `aria-label` : « Commit a1b2c3d, 8 nov. 2026, <sujet>. Ouvrir dans l'historique Git. »
Borne atteinte (`bornes.tronque`) : au-dessus de la liste, « Lecture bornée : la liste peut être incomplète. »

## 6. Panneaux de liste et pagination

Ouverts par « + N autres », par une ligne d'agent (§ 4.3) ou par un registre au-delà de 30. Même gabarit que § 5 (fil
d'Ariane, titre `.pt` 20 px/600 comme « Exigences de la Phase 76 », « Entrées de vf-dev-manager », « ADR »). Corps : 30 lignes
par page, puis une barre de pagination : `.btn.soft` « Précédentes » et « Suivantes » (attribut `disabled` à la borne), au
centre le texte « 31 à 60 sur 83 » (11,5 px `--text-3`, tabular-nums, `aria-live="polite"` pour l'annonce du changement de
page). Aucune pagination infinie. Le changement de page replace le focus sur le titre de la liste. Hauteur des boutons 32
px (44 px tactile).

## 7. Échelle : au plus 30, puis « + N autres »

Dans un panneau ou une section, au plus 30 voisins d'une même sorte (exigences, ADR, décisions, commits, liens, entrées,
agents, registres). Au-delà : un `button.vf-trace-plus` « + 12 autres » (12,5 px/500 `--text-2`, padding `var(--inset-row)`,
survol `rgba(var(--ink), .06)`, focus `--ring`), qui ouvre le panneau de liste paginé (§ 6). Sorte nommée dans le libellé
quand le contexte est ambigu : « + 2 autres ADR », « + 5 autres registres », « + 40 autres commits ». Jamais la classe `.more`
du moteur (c'est du texte non interactif en `--text-4`). Le total est celui de la route, jamais calculé par la page.

## 8. Clavier et lecteur d'écran

- Tout lien et toute ligne est un `button type="button"` ou un `summary` natif : focalisable, Entrée et Espace, ordre de
  tabulation = ordre visuel du panneau (fil d'Ariane, corps, pagination). Aucun `tabindex` positif. Aucune touche globale
  neuve (ni `t`, ni `g`) : la 76 ne prend aucune lettre au moteur.
- Focus visible : `outline: 2px solid var(--ring)`, `outline-offset: -2px` dans le panneau, `2px` sur un `summary`.
- Ouverture d'un objet par le clavier : le focus va sur le titre (`tabindex="-1"`). Par la souris ou le toucher : le focus
  ne bouge pas (une proposition ne prend jamais le focus, Q5).
- Échap, focus dans le panneau de la 76 : s'il y a un état précédent dans la pile commune, appelle le Retour commun
  (`VibeFlow.panneau.retour()`, `stopPropagation`) ; pile vide, ferme le panneau d'objet (`SC.closePanel()`) et rend le
  focus à la ligne qui l'a ouvert, mémorisée à l'ouverture ; sur téléphone, pile vide, l'événement n'est pas arrêté et le
  comportement du moteur ferme la feuille. Échap ne ferme jamais une section dépliée seule. **À revalider** après la 80.
- Rôles : fil d'Ariane `nav` + `ol` ; sections et replis `details`/`summary` natifs ; listes `ul` de `li`, lignes en
  `button` ; une région `role="status"` par section chargée dit « Lecture de la traçabilité » puis rien (annonce seulement
  du chargement et des erreurs) ; `aria-busy="true"` pendant le chargement ; chaque glyphe est `aria-hidden`, son sens est
  dans l'`aria-label` de la ligne ou dans le mot voisin.
- L'ancre : `id` unique par objet dans le panneau, jamais d'`id` dupliqué entre deux panneaux ouverts (un seul panneau).

## 9. États : chargement, vide, dégradé, erreur

Tous neutres : texte `--text-2` ou `--text-3`, jamais coral, jamais de fond teinté, jamais de texte coloré. Boîte
éventuelle : `--warn-bg` (neutre, 5 % d'encre) sur `--surface`, `--r-ctl`, `padding: var(--inset-box)`, texte `--text-2`
(pas `--warn-text`, le texte n'est pas coloré ici).

| État | Où | Rendu et copy exacts |
|------|----|----------------------|
| Chargement (au-delà de 150 ms) | section, panneau | `aria-busy="true"` ; trois lignes fantômes de 32 px (`--raise`, `--r-ctl`, sans balayage) ; texte « Lecture de la traçabilité » (`--text-3`). Avant 150 ms : rien, pas de clignotement |
| Phase sans exigence | « Traçabilité » | « Aucune exigence rattachée à cette phase. » |
| Aucune phase au jalon | « Jalon » | « Aucune phase dans le jalon en cours. » |
| Pas de `docs/ADR.md` | « Décisions » | « Pas de docs/ADR.md dans ce dossier. » ; les registres de phase restent montrés s'ils existent |
| Aucun registre de décisions | « Décisions » | « Aucune décision définie dans les registres de phase. » |
| Pas de compartiment de planification | les trois sections et « Traçabilité » | « Aucun compartiment de planification lu : la traçabilité n'est pas disponible. » (une ligne, rien d'autre) |
| Traçabilité rangée en « Étape N » | « Traçabilité », « Jalon » | « La traçabilité de ce ledger est rangée par Étape N : 3 étapes lues comme des phases, 2 sans dossier de phase. » ; aucune étape ne désigne un dossier : « La traçabilité de ce ledger est rangée par Étape N, aucune ne désigne un dossier de phase. » (P76-D-12) |
| Pas de `.claude/agent-memory/` | « Mémoire des agents » | « Pas de .claude/agent-memory/ dans ce dossier. » |
| `.claude/` ignoré par git | « Mémoire des agents » | « .claude/ n'est pas suivi par git : 12 fichiers non suivis, aucune entrée à lire. » (le nombre, jamais un nom) |
| Pas de git | « Mémoire », commits | Mémoire : « Git n'est pas disponible : la mémoire des agents n'est pas lue. » ; commits : « Git n'est pas disponible : les commits qui citent cet objet ne sont pas lus. » ; le reste (exigences, ADR, décisions) s'affiche |
| Agent sans entrée | panneau de liste | « Aucune entrée suivie pour cet agent. » |
| Réponse bornée | listes de commits, d'entrées | « Lecture bornée : la liste peut être incomplète. » (`bornes.tronque`, 11,5 px `--text-3`, au-dessus de la liste) ; une réponse bornée ne se présente jamais comme complète |
| Route en échec (503, délai, réseau local) | section, panneau | boîte neutre : titre « La traçabilité est indisponible » (12,5 px/600 `--text`), cause « La lecture du dépôt a échoué ou dépassé le délai. » (12 px, `--text-2`), `.btn.soft` « Réessayer » ; le reste du panneau continue de fonctionner |
| Rafraîchissement par `planning` | section ouverte | le contenu se remplace sans fondu ; défilement et pliages conservés ; si l'objet affiché a disparu : « Cet objet n'existe plus dans le dépôt. » et le fil d'Ariane reste utilisable |
| Objet introuvable (cible morte) | panneau | « Cet objet n'existe plus dans le dépôt. » ; le fil d'Ariane reste utilisable |

Un paramètre invalide (400) ne se montre pas à l'utilisateur : la page ne construit jamais une `cle` hors motif ; en cas de
400 inattendu, même rendu que « Route en échec ».

## 10. Contradictions du ledger (texte complet, panneau d'exigence)

Phrase en `--text-2`, jamais colorée ; seul le glyphe de contradiction porte le corail (`--st-blocked`).

| Cause lue | Phrase complète | Mot court de ligne |
|-----------|-----------------|--------------------|
| Case cochée sans SUMMARY lu | « Case cochée au ledger, aucun SUMMARY lu. » | « cochée, sans SUMMARY » |
| Case non cochée avec SUMMARY lu | « Case non cochée au ledger, un SUMMARY est lu. » | « non cochée, SUMMARY lu » |
| Statut « Complete » sans plan | « Statut Complete au tableau de traçabilité, aucun plan ne la cite. » | « Complete, sans plan » |
| Ligne de traçabilité sans exigence | « Ligne de traçabilité sans exigence au ledger. » | « ligne sans exigence » |
| Exigence sans ligne de traçabilité | « Exigence sans ligne de traçabilité. » | « sans ligne de traçabilité » |

Le mot « rouge » du but du 2026-11-03 est lu « marqué et visible » dans les teintes Graphite (A-1, § 12). Aucune de ces
phrases n'est un verdict sur le travail : elle décrit ce que deux fichiers disent l'un de l'autre.

## Spacing Scale

Grille fermée de DESIGN § 4 (P71.5-D-01) : 2, 4, 6, 8, 12, 16, 20, 24, 32. Jamais 10, 14, 22. Chaque valeur s'écrit
`var(--sp-N)`, un jeton sémantique ou `calc()` de jetons.

| Jeton | Valeur | Usage dans cette phase |
|-------|--------|------------------------|
| `--sp-2` | 2 px | écart entre deux lignes de liste, entre les deux lignes d'une ligne d'objet |
| `--sp-4` | 4 px | écart entre glyphes de la bande, entre glyphe et mot |
| `--sp-6` | 6 px | écart entre identifiant et texte, séparateurs du fil d'Ariane |
| `--sp-8` | 8 px | écart bande et mot ; marge sous un `summary` ouvert |
| `--sp-12` | 12 px | retrait d'un registre déplié ; `margin-inline` négatif d'une ligne pleine largeur ; boîte neutre |
| `--sp-16` | 16 px | écart entre blocs d'un panneau d'objet |
| `--inset-row` | 8 × 12 | `padding` de toute ligne cliquable |
| `--inset-pill` | 2 × 8 | `.tag` |
| `--inset-panel`, `--gap-section` | 20, 24 | via `.sec`, jamais redéfinis |

Tailles hors grille d'espacement, listes fermées (hauteurs de contrôle et dimensions) : glyphe 16 px (`1.45em` de 11,5 px) ;
ligne fantôme et `summary` 32 px ; cible tactile 44 px ; maillon de fil d'Ariane `max-width: 140px` ; au plus 30 voisins.
Exceptions : aucune autre. Rien d'existant n'est modifié.

## Typography

Quatre tailles, deux graisses posées (500 et 600 ; le 400 est hérité du moteur, jamais écrit).

| Rôle | Taille | Graisse | Interligne |
|------|--------|---------|------------|
| Titre de panneau d'objet (`.pt`) | 20 px | 600 | 1.3 (existant), interlettrage -.02em |
| Corps et texte d'objet (`.pd`, définition, phrase de contradiction) | 13,5 px (hérité) | 400 hérité | 1.6 (existant) |
| Ligne, titre de section (`.sec h3`), libellé de maillon, ADR | 12,5 px | 500 (libellés), 400 (texte) ; 600 pour « La traçabilité est indisponible » | 1.45 |
| Méta : identifiants mono, sha, dates, mots d'état, légende, fil d'Ariane, compteurs | 11,5 px | 500 (identifiants, mots d'état), 400 (reste) | 16 px |

`--mono` pour identifiants (TRAC-01, ADR-075, P41-D-02), sha, chemins, `name` de mémoire, commandes ; `--sans` ailleurs.
Chiffres en `font-variant-numeric: tabular-nums` (compteurs, pagination).

## Color

Graphite : aucune couleur de marque, `--accent` = `--on` (neutre). Pas de répartition 60/30/10 imposée ; répartition réelle.

| Rôle | Valeur (variable) | Usage |
|------|-------------------|-------|
| Dominant | `--elev` (verre du panneau), `--surface` | fond du panneau, lignes au repos |
| Secondaire | `rgba(var(--ink), .06)` survol, `--surface-hover`, `--raise` (hors teinte d'état), `--hair` (filets) | survol de ligne, lignes fantômes, séparateurs |
| Texte | `--text`, `--text-2`, `--text-3`, `--text-4` | hiérarchie ; `--text-4` seulement pour un compteur ou un séparateur non essentiel doublé par un texte lisible |
| Accent | aucun | |
| Teintes d'état | `--st-blocked` (corail) | uniquement le glyphe de contradiction (carré barré) |

Réservé au corail : le glyphe de contradiction (maillon, ledger, lien cassé, hors index, chemin absent). Rien d'autre :
ni texte, ni fond, ni contour, ni liseré. Vert et jaune : pas d'usage neuf ; seule la pastille de phase `.vst` du « Jalon »
les porte déjà par son glyphe. Contraste : texte ≥ 4,5:1 (`--text-3` et `--text-4` mesurés dans DESIGN § 2) ; glyphe
≥ 3:1 sur `--surface` et `--bg` ; une teinte d'état jamais sur `--raise` ni `--raise-2` en thème clair, d'où des lignes
posées sur `--elev` ou `--surface`. Destructif : sans objet (aucune action).

## Copywriting Contract

| Élément | Copy |
|---------|------|
| CTA principal | aucun (lecture seule) ; l'action la plus proche : « Ouvrir l'exigence », « Ouvrir l'ADR », « Ouvrir la décision », « Ouvrir l'entrée » (`aria-label` des lignes, jamais un libellé visible) |
| Titres de section | « Traçabilité », « Jalon », « Décisions », « Mémoire des agents », « Preuves attachées », « Chaîne », « Contradictions », « Rattachement », « Fiche », « État », « Liens sortants », « Liens entrants », « Chemins du dépôt cités », « Décisions qui la citent », « Commits qui la citent », « ADR citées », « Registres de phase » |
| Maillons | « Plan », « SUMMARY », « VERIFICATION », « Recette » (dans la bande : plan, SUMMARY, VERIFICATION, recette) |
| États de maillon | « lu », « manque », « non lisible », « contradiction » ; niveaux : « niveau exigence », « niveau phase » |
| Mot de ligne | « manque : plan », « manque : SUMMARY », « manque : VERIFICATION », « manque : recette », « non lisible : SUMMARY », « chaîne complète » ; contradictions : voir § 10 |
| Bilan de section | « 4 exigences, 1 avec un manque, 1 contradiction » ; « 4 exigences, toutes avec une chaîne complète » ; « 12 phases, 7 avec un manque, 2 contradictions » ; « 268 entrées, 12 agents, 33 liens cassés, 143 sans lien entrant » |
| États mémoire | « hors index », « lien cassé », « cite un chemin absent », « résolu par nom de fichier », « sans lien entrant », « aucun écart » |
| Preuves | « VERIFICATION », « Recette », « Trace rouge », « Sécurité », « Validation », « Critères du plan », « 5 critères », « statut : passed », « Aucune preuve attachée. » |
| Dates, sha | « 8 nov. 2026 » (jour seul, mois abrégé français) ; sha de 7 caractères |
| Débordement | « + 12 autres », « + 2 autres ADR », « + 5 autres registres », « + 40 autres commits », « + 3 autres agents » ; « Précédentes », « Suivantes », « 31 à 60 sur 83 » |
| Fil d'Ariane | « Fil d'Ariane » (`aria-label`), « › » séparateur, « Liste » |
| Chargement | « Lecture de la traçabilité » |
| État vide (titre) | la ligne neutre du cas concerné, § 9 : une phrase, pas de titre séparé ; exemple « Aucune exigence rattachée à cette phase. » |
| État vide (corps) | aucun : la ligne neutre suffit, aucune action à proposer (lecture seule) |
| Erreur | titre « La traçabilité est indisponible » ; cause « La lecture du dépôt a échoué ou dépassé le délai. » ; bouton « Réessayer » |
| Borne | « Lecture bornée : la liste peut être incomplète. » |
| Note mémoire | « Seule la structure est lue : ni description ni contenu. » |
| Source | « Lu dans <chemin relatif> » ; copie : « Copier le chemin : <chemin> », retour « Copié » |
| Confirmation destructive | sans objet : aucune action destructive, aucune écriture (hors périmètre, P76-D) |

## 11. Responsive : 1440, 1024, 390 px

Le panneau d'objet est le `#panel` du moteur ; la 76 ne change ni sa position, ni sa taille, ni son `z-index`. Un panneau
latéral ne pousse jamais la carte (Q12).

| Largeur | Comportement du panneau | Ce que la 76 vérifie |
|---------|-------------------------|----------------------|
| 1440 px | colonne de 360 px à droite (`--panel-w`, redimensionnable ; largeur utile de ligne = 360 − 2 × 20 = 320 px) | lignes d'exigence sur deux lignes sans coupe de l'identifiant ; mot de ligne qui passe à la ligne ; carte non poussée |
| 1024 px (souris ≥ 1000 px) | même colonne de 360 px ; il reste ≥ 280 px de carte visible | idem ; fil d'Ariane sur une ligne, sinon à la ligne ; aucun défilement horizontal |
| 768 px et 700 à 999 px | colonne de 360 px conservée (sauf tactile), carte réduite | cibles 44 px si `pointer: coarse` ; aucune largeur fixe de ligne |
| 390 px (≤ 700 px) | feuille basse : `left/right 8 px`, hauteur max `min(56vh, 480px)`, défilement dans la feuille | largeur utile ≈ 334 px ; sections repliées par défaut (la feuille est courte) ; lignes et boutons ≥ 44 px (`min-height: 44px`) ; fil d'Ariane à la ligne ; pagination en boutons 44 px ; aucun défilement horizontal |

Largeur de panneau redimensionnée par l'utilisateur : toute ligne reste fluide (`min-width: 0`, `overflow-wrap: anywhere`,
jamais de largeur fixe en px sur un texte). Cibles tactiles ≥ 44 px dans `@media (max-width: 700px), (pointer: coarse)`
(`.vf-trace-ligne`, `.vf-trace-commit`, `.vf-trace-plus`, `summary`, boutons de pagination, maillons du fil d'Ariane).
Mouvement : aucune animation neuve (le moteur anime déjà l'entrée du panneau, `panelIn`, avec sa variante mouvement réduit) ;
pliage de `details` sans transition.

## 12. À Samuel (non bloquant, le contrat tient sans réponse)

Ces deux questions viennent du CONTEXT (§ À Samuel) ; le contrat applique l'option recommandée.
- **A-1 : « Les trous en rouge » face à Q9.** Appliqué : (a), glyphe neutre et mot pour une absence, trait corail sur le glyphe
  pour une contradiction lue. Alternatives : trait corail pour tout trou ; tout neutre.
- **A-2 : « graphe navigable » sans dessin.** Appliqué : panneaux reliés, voisinage seul. Un dessin de l'îlot de mémoire
  d'un agent peut venir plus tard sans rien défaire (différé).

Aucune autre question de goût pur n'est ouverte : forme du glyphe de contradiction (carré barré du signe « différent de »),
position haute de la section de phase et priorité des mots de ligne sont des **décisions déléguées par Samuel (message
session principale, 2026-11-08), option recommandée**, à challenger par `vf-design-judge`.

## 13. Variables CSS utilisées (toutes existantes)

| Variable | Usage |
|----------|-------|
| `--sans`, `--mono` | texte ; identifiants, sha, chemins, `name` |
| `--elev`, `--surface`, `--surface-hover`, `--raise` | fond du panneau, lignes, survol, lignes fantômes (`--raise` jamais sous une teinte d'état) |
| `--hair`, `--ink` | filets ; `rgba(var(--ink), α)` de survol |
| `--text`, `--text-2`, `--text-3`, `--text-4` | hiérarchie du texte |
| `--st-blocked` (`--sev-high`), `--st-todo` | glyphes de contradiction et de manque |
| `--ring` | focus |
| `--r-ctl`, `--r-panel` | boîtes neutres, panneau (non modifié) |
| `--warn-bg` | boîte neutre d'erreur (5 % d'encre) |
| `--sp-2`, `--sp-4`, `--sp-6`, `--sp-8`, `--sp-12`, `--sp-16`, `--inset-row`, `--inset-pill`, `--inset-box` | espacements |
| `--ease` | aucune transition neuve ; mentionné pour mémoire |

Variables absentes à ne pas inventer : `--text-1`, `--trace-*`, `--git-*`. Aucune valeur de couleur, d'espacement ou de
rayon écrite en dur ; seules exceptions de DESIGN § 4 (filets 1 px, tailles de contrôle).

## 14. Ce que le juge de design doit vérifier

1. Aucune valeur en dur de couleur, d'espacement, de rayon : `grep` de la feuille neuve contre § 13, deux thèmes.
2. Bande de quatre glyphes lisible à 16 px dans les deux thèmes : coche, anneau, anneau et « i », carré barré
   distincts en niveaux de gris ; le corail du carré barré ≥ 3:1 sur `--elev` clair et sombre ; jamais posé sur `--raise`.
3. Un seul mot par ligne d'exigence, jamais une liste ; priorité contradiction, manque, non lisible, chaîne complète.
4. Aucun fond teinté, aucun texte coloré, aucun liseré : seules la forme et la teinte du glyphe disent la contradiction.
5. Trois sections repliées par défaut ; pliage conservé au re-rendu ; compteurs lus de la route ; aucun `setOverview`.
6. Panneaux d'exigence, d'ADR, de décision et d'entrée : fil d'Ariane (parenté), pas de bouton Retour propre, titre
   focalisé au clavier, ancre par objet, source relative copiable, aucun chemin absolu ni `~/`.
7. Mémoire : jamais `description` ni corps, chemins relatifs, états distincts (hors index, lien cassé, chemin absent,
   résolu par nom de fichier, sans lien entrant), aucun mot « périmée ».
8. « + N autres » au-delà de 30, pagination à 30 par page, bornes (`tronque`) dites, aucun défilement infini.
9. États : chargement après 150 ms, vide, dégradés de § 9 (sans ADR, sans compartiment, « Étape N », sans mémoire, `.claude/`
   ignoré, sans git), route en échec avec « Réessayer ».
10. Clavier : tout parcourable sans souris, Échap (Retour commun puis fermeture), aucune touche globale prise, focus
    visible, cibles 44 px tactiles.
11. 1440, 1024, 390 px : carte jamais poussée, aucun défilement horizontal, lignes fluides à largeur redimensionnée.
12. Anti-slop : monochrome, aucune couleur de marque ni dégradé, aucune police neuve, aucun tiret cadratin dans le copy,
    copy entièrement français (le garde d'inventaire du français du cockpit ne doit trouver aucune fuite).

## 15. Points à revalider à l'exécution

- Chemin réel des contrats de la 79 (A10 à A13) et de la 80 (P80-C76-1 à 4) : l'API `SC` présente sert de base.
- Présence du Retour commun de la 80 au-dessus d'un panneau posé par `SC.showPanel` (§ 0) ; comportement d'Échap (§ 8).
- Crochet de sélection d'un commit par son sha dans le tiroir Git de la 78 (§ 5.5).
- Numéro du ou des fichiers `ui/7x-vf-trace*.js` (§ en-tête) et poids de chaque fichier (≤ 300 lignes, gate V4).
- Que la carte de phase en couloirs de la 80 ouvre le même panneau, section « Traçabilité » comprise (P80-C76-1).

## UI Considerations

> Rempli par la sonde de considérations d'UI du flux ui-phase (étape 9.5) ; lignes remplacées, jamais ajoutées. La couverture
> d'états de cette phase est décrite au § 9 et au § 7 ; le copy y est référencé, pas dupliqué.

Applicable state considerations resolved: à renseigner par la sonde

| Category | Element(s) | Status | Resolution / Reason |
|----------|------------|--------|---------------------|

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | aucun (Tool: none) | non applicable |
| tiers | aucun | non applicable |

## Checker Sign-Off

- [ ] Dimension 1 Copywriting: PASS
- [ ] Dimension 2 Visuals: PASS
- [ ] Dimension 3 Color: PASS
- [ ] Dimension 4 Typography: PASS
- [ ] Dimension 5 Spacing: PASS
- [ ] Dimension 6 Registry Safety: PASS
- [ ] Dimension 7 Inventory Provenance: PASS

**Approval:** pending
