---
phase: "76"
slug: "tracabilite-au-cockpit"
status: draft
shadcn_initialized: false
preset: none
created: "2026-11-11"
---

# Phase 76 : Traçabilité au cockpit — UI-SPEC

**Contrat de design** pour l'entrée et la section « Traçabilité » du panneau d'une phase, les trois sections repliées de la
vue d'ensemble de Projet (« Jalon », « Décisions », « Mémoire des agents ») et les panneaux d'une exigence, d'une ADR,
d'une décision et d'une entrée de mémoire. Direction « Graphite » (`DESIGN.md`). Révision du 2026-11-11 sur la critique du
premier jet (75/100) : glyphes de forme propre, corail borné par P76-D-15bis, section de phase bornée en hauteur, nom
accessible, mémoire réduite aux chemins absents.

Sources lues : `76-CONTEXT.md` (P76-D-01..30, P76-D-15bis, Retour et pile commune de la Phase 80, règle A30 de la 79), `REQUIREMENTS.md`
(TRAC-01..12), `DESIGN.md`, `DESIGNS.md` § 1, § 2, § 9, `78-UI-SPEC.md` (modèle), `viewer.html` (`:root`, `#panel`, `.sec`,
`.row`, `.more`, `.group-h`, `renderPanel`, API `SC`), `ui/00-vibeflow.js` (masques `G_ST`, `.vst`, `.vf-link`, `.vf-ref`,
`.vf-copie`, lien `data-vf-section`, `details.vf-tech`), `ui/71-vf-equipe-rendu.js` (glyphes d'Équipe), `ui/77-vf-git-tiroir.js`
(`VFGitTiroir`). Aucune brique externe de craft consultée : dégradation sur les premiers principes (contraste WCAG, grille
fermée, hiérarchie).

**Règles d'écriture de ce document et du copy.** Libellés en français, exacts. À l'affichage, une espace insécable
(U+00A0) précède `: ; ! ?` et sépare un nombre de son unité (« 1 024 px », « 2 000 commits ») ; le document écrit des espaces
ordinaires pour rester lisible, l'exécutant pose les insécables. Aucun tiret cadratin dans le copy. Tout nombre affiché porte
son unité. Tout texte venu des fichiers du lab (texte d'exigence, titre d'ADR, ligne de décision, sujet de commit, `name:`
de mémoire, statut lu) s'écrit en `textContent`, jamais en `innerHTML`. Classes neuves en `vf-trace-*`, dans le ou les
fichiers de page `ui/7x-vf-trace*.js` (numéro fixé au plan ; 74 est libre aujourd'hui, **à revalider**) ; rien dans
`viewer.html`, rien dans `00-vibeflow.js`.

## 0. Bornes qui encadrent le contrat (rappel, non rouvert)

- Lecture seule : aucun bouton qui écrit, coche, corrige ou crée. Aucune action ni « copier la commande ». Seules
  interactions : ouvrir un objet, plier, dérouler, aller à une section, copier un chemin (comportement existant `.vf-copie`).
- Pas de canevas, pas de dessin de nœuds et d'arêtes, pas de quatrième onglet, pas de vue plein cadre, aucune modification
  de `viewer.html` (P76-D-01, P76-D-02, P78-D-04).
- Surface unique : le `#panel` existant (colonne de 360 px à droite, feuille basse sous 700 px). Aucun tiroir neuf, aucun
  `z-index` neuf, aucune classe posée sur `body`, aucun `padding` du plan modifié : la carte n'est jamais poussée (Q12).
- Les sections n'existent que sur l'onglet Projet servi par le serveur (`TAB === 'project'` et `window.FLOORPLAN_SERVER`).
  Dans une page autonome ou un export : pas de section, pas de ligne « indisponible » (P76-D-11).
- Ni fond teinté, ni texte coloré, ni liseré ou contour coloré : une teinte d'état ne vit que dans un glyphe (Q9,
  P71.5-D-12, D-19, D-21, D-27, D-28). Le corail ne désigne que la liste fermée de P76-D-04 / P76-D-15bis (§ 10). Grille
  d'espacements fermée (P71.5-D-01). Points de rupture inchangés (Q11).
- Rien de la mémoire des agents au-delà de `name`, agent, `metadata.type`, jour du dernier commit, nombres de liens
  entrants et sortants, chemins cités absents (P76-D-20, P76-D-22). Aucun titre ni résumé écrit par un modèle (PU-G-162).
- **Pas de fil d'Ariane, pas de Retour propre** (P76-D-03, P76-D-30). Un seul Retour par panneau : le bouton « Retour : <titre
  du dessus> » de l'en-tête du panneau, pile commune de la Phase 80 (`window.VF_PANNEAU.retour()`, P80-C76-3). Phase et plan
  sont des nœuds du graphe : `select(id)` ou `reveal(id)` les ouvre et ils s'empilent d'eux-mêmes. Exigence, ADR, décision et
  entrée de mémoire sont des panneaux sur mesure : chacun appelle `window.VF_PANNEAU.empiler({ titre, rouvrir })` (P80-C76-5)
  avant `SC.showPanel(html, bind)` ; `titre` est une donnée du lab, rendu en texte, jamais en HTML ; `rouvrir` rend de nouveau la
  vue que le bouton ramène. La pile est vidée au changement d'onglet. **À revalider** : que l'en-tête commun et son bouton
  restent présents au-dessus d'un panneau posé par `SC.showPanel`, et le sens exact de `titre` (la vue que l'on quitte) ;
  sinon, point à rouvrir avec la 80, jamais un bouton « Retour » propre à la 76.
- **Initialisation (règle A30 de la 79)** : l'extension (sections, entrée haute, lecture de `GET /api/vf/tracabilite`)
  s'installe par `VF_COQUILLE.surOnglet(rappel)` quand l'onglet vaut Projet, et le rappel rend son nettoyage (écouteurs,
  minuteries, DOM posé) en le quittant ; jamais au seul chargement.

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
`grep -n "\.vf-ref\|\.vf-copie\|\.vf-link\|data-vf-section\|details.vf-tech\|\.vst" ui/00-vibeflow.js`, état du dépôt au
2026-11-11. Ce n'est pas un inventaire de bibliothèque, seulement les briques à réemployer avant d'en écrire une.

| Brique | Où | Usage ici |
|--------|----|-----------|
| `.sec`, `.sec h3`, `.sec h3 .c` | `viewer.html` | Enveloppe de chaque section ; titre 12,5 px/500 `--text-3`, compteur `--text-4` (le compteur porte son unité) |
| `.ph`, `.ph .kindlabel`, `.pt`, `.pd` | `viewer.html` | En-tête des panneaux d'objet : type en ligne, titre 20 px/600, texte courant |
| `.group-h` | `viewer.html` | Intertitre d'un groupe (par plan dans « Preuves attachées ») |
| `.tag` | `viewer.html` | Type de mémoire (`metadata.type`), identifiants de plan |
| `.btn.soft` | `viewer.html` | « Réessayer », « Précédentes », « Suivantes » |
| `.vf-ref`, `.vf-copie`, `.vf-copie-etat` | `ui/00-vibeflow.js` | Chemin relatif copiable au clic, retour « Copié » 1,6 s (gestionnaire de clic déjà posé sur `document`) |
| `[data-vf-section="<id>"]` | `ui/00-vibeflow.js` | Aller à une section du panneau (`scrollIntoView`), sans code neuf |
| `.vst` + `vst-*` | `ui/00-vibeflow.js` | Pastille d'état de phase des lignes du « Jalon » (glyphe + mot) |
| `details.vf-tech` (motif) | `ui/00-vibeflow.js` | Motif du repli natif `details`/`summary` |
| `SC.addPanelSection`, `SC.showPanel`, `SC.reveal`, `select` | `viewer.html`, API `SC` | Seuls points d'accroche (P76-D-02) |
| `window.VF_PANNEAU.empiler`, `.retour` ; `window.VF_COQUILLE.surOnglet` ; `window.VF_SURCOUCHES` | Phase 80 et Phase 79 (non exécutées) | Retour unique, initialisation par onglet, priorité d'Échap aux surcouches ; **à revalider** |

## 1. Vocabulaire des états (glyphe + mot)

Le sens ne repose jamais sur la couleur seule : chaque état a une **forme propre** et un mot ; la teinte ne fait que
renforcer. Les masques suivent le patron `GLYPHE(...)` de `00-vibeflow.js` (viewBox 16, `stroke='black'` explicite, teinté par
`--c-st`) ; trait de contour 1,75, **détail interne 2 px ou plus**. Le glyphe fait 16 px fixes (§ 1.1).

### 1.1 Formes : aucune n'est employée ailleurs dans le cockpit

Formes déjà employées, relevées dans `G_ST` (`00-vibeflow.js`) et `GLYPHE` (`71-vf-equipe-rendu.js`) : coche (fait,
terminé), demi-disque (en cours), anneau et point (à recetter), anneau (à faire), anneau barré d'un trait (bloqué),
anneau barré d'une diagonale (abandonnée), anneau et « i » (info), triangle et « ! » (toléré, bloqué d'Équipe), losange et
croix (ignoré), disque plein (actif), anneau et pause, anneau pointillé, anneau et tiret, anneau et « ? », chevron, cadran,
œil. La famille ci-dessous est faite de **carrés à angles vifs** (`rx` 1,5, plats de 7 px ou plus) et d'un **octogone au
trait** : aucune de ces formes n'y figure.

**Glyphes de 16 px fixes** : `width: 16px; height: 16px` sur `.vf-trace-g`, jamais `1.45em` ; ils ne suivent ni la police ni
le zoom d'éloignement. Masque : patron `GLYPHE(...)` de `00-vibeflow.js` (viewBox 16), teinté par `--c-st`. Chaque corps
du tableau se copie **tel quel** dans `GLYPHE(...)`. Le masque ne lit que l'opacité : tout élément au trait porte
`stroke='black'` et `fill='none'` explicites (sans `stroke` explicite, il disparaît), tout élément plein porte `fill='black'`.

| État | Corps du masque (à copier tel quel) | Teinte | Mot |
|------|-------------------------------------|--------|-----|
| Lu (maillon) | `<rect x='3' y='3' width='10' height='10' rx='1.5' fill='black'/>` | `--text-2` | « lu » |
| Manque (maillon) | `<rect x='2.5' y='2.5' width='11' height='11' rx='1.5' fill='none' stroke='black' stroke-width='1.75'/>` | `--text-4` (`--st-todo`) | « manque » |
| Non lisible (maillon) | `<rect x='2.5' y='2.5' width='11' height='11' rx='1.5' fill='none' stroke='black' stroke-width='1.75'/><circle cx='6' cy='8' r='1' fill='black'/><circle cx='10' cy='8' r='1' fill='black'/>` | `--text-3` | « non lisible » |
| Résolu par nom de fichier (lien de mémoire) | `<rect x='2.5' y='2.5' width='11' height='11' rx='1.5' fill='none' stroke='black' stroke-width='1.75'/><path d='M5.5 6.2h5M5.5 9.8h5' fill='none' stroke='black' stroke-width='2' stroke-linecap='butt'/>` | `--text-3` | « résolu par nom de fichier » |
| Contradiction (liste fermée, § 10) | `<path d='M5 1.8h6l3.2 3.2v6L11 14.2H5L1.8 11V5z' fill='none' stroke='black' stroke-width='1.75' stroke-linejoin='round'/><rect x='5.5' y='5.5' width='5' height='5' rx='1' fill='black'/>` | `--st-blocked` (= `--sev-high`, corail) | « contradiction » (avec sa cause, § 10) |

**Tracés relus coordonnée par coordonnée.**
- Carré plein : de 3 à 13, 10 px, plats de 7 px (`rx` 1,5). Carré vide : contour de 1,75 centré sur 2,5 à 13,5, étendue
  extérieure 1,6 à 14,4, plats de 8 px, bord intérieur à 3,4 et à 12,6.
- Deux points (non lisible) : disques de 2 px à x = 6 et x = 10, y = 8 : 2 px d'écart entre eux, 1,6 px du bord intérieur du
  carré. Deux barres (résolu) : 2 px d'épaisseur à y = 6,2 et 9,8, bouts droits (`butt`), de x = 5,5 à 10,5 : 1,6 px entre les
  barres, 1,8 px du bord intérieur en haut et en bas, 2,1 px sur les côtés.
- Octogone : points (5 ; 1,8), (11 ; 1,8), (14,2 ; 5), (14,2 ; 11), (11 ; 14,2), (5 ; 14,2), (1,8 ; 11), (1,8 ; 5), fermé ;
  trait de 1,75 à jointures rondes, étendue 0,9 à 15,1 (rien n'est rogné par le viewBox). Carré central plein de 5 px (5,5 à
  10,5) à 2,1 px au moins du bord intérieur du trait.
- Détails internes tous ≥ 2 px et espacés d'au moins 1,5 px entre eux et du contour.

**Lecture en niveaux de gris**, à côté d'une pastille de phase `.vst` (anneau et disque) : plats et angles vifs (carrés), masse
pleine (lu), carré vide (manque), carré vide à deux points ou à deux barres (non lisible, résolu), octogone au trait à carré
central (contradiction). Aucun de ces profils ne se confond avec un anneau, un disque, une coche ou un demi-disque : la
silhouette carrée ou octogonale à plats nets suffit sans la teinte. Le glyphe « lu » est neutre à dessein (le vert dit
« fait » ailleurs ; cinq carrés verts par ligne noieraient le seul signal qui demande une action). **Décision du manager
(décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée)** : contradiction = octogone au
trait corail, non plein, sans « ! », détail interne de 5 px. Confirmation « Les trous en rouge » : § 12, A-1.

### 1.2 Niveau d'un maillon : ce que veulent dire « niveau exigence » et « niveau phase »

Seul un maillon « lu » a un niveau (P76-D-14).
- **Niveau exigence** : le champ ou le fichier lu cite l'identifiant de cette exigence : `requirements:` d'un plan,
  `requirements:` ou `requirements-completed:` d'un SUMMARY, ligne de la table de couverture d'une VERIFICATION, mention
  dans le fichier de recette. Plan et SUMMARY lus sont toujours de niveau exigence.
- **Niveau phase** : le fichier existe pour la phase mais ne cite pas l'identifiant ; il dit que la phase a une VERIFICATION
  ou une recette, pas qu'elle couvre cette exigence. Seuls VERIFICATION et recette peuvent être de niveau phase.

**Source accessible unique du niveau.** Dans une ligne de la section : le texte masqué `.vf-trace-sr` du bouton (§ 2),
jamais un `title`, jamais un `aria-label` de glyphe (les glyphes sont `aria-hidden`). Dans le panneau d'une exigence : le
texte visible de la ligne du maillon (§ 5.1). Ces deux surfaces ne se superposent pas.

### 1.3 États de la mémoire des agents

| État | Glyphe | Teinte | Mot | Nature |
|------|--------|--------|-----|--------|
| Hors index (absente de son `MEMORY.md`, égalité exacte du nom de fichier) | octogone à carré central | `--st-blocked` | « hors index » | contradiction |
| Lien cassé (ni `name:` ni nom de fichier) | octogone à carré central | `--st-blocked` | « lien cassé » | contradiction |
| Cite un chemin absent (relatif au dépôt, absent de HEAD, présent dans l'historique lu) | octogone à carré central | `--st-blocked` | « cite un chemin absent » | contradiction |
| Résolu par nom de fichier | carré à deux barres | `--text-3` | « résolu par nom de fichier » | état propre, compté |
| Sans lien entrant (les liens d'index ne comptent pas) | aucun glyphe | `--text-3` | « sans lien entrant » | filtre neutre, jamais un verdict |

Aucun mot « périmée » : la date est une information (« modifiée le 8 nov. 2026 »), jamais un verdict (P76-D-22).
**Les trois contradictions de mémoire partagent le même octogone** : le corail est borné (P76-D-15bis) et 16 px ne portent
pas trois octogones différents lisibles de plus. Elles se distinguent par leur **emplacement** et leur mot : hors index vit dans la
section « État » de l'entrée (et dans le décompte de la ligne d'agent) ; lien cassé vit sur la ligne du lien, dans « Liens
sortants » ; chemin absent vit sur la ligne du chemin, dans « Chemins cités et absents de HEAD ». Jamais deux sur une même
ligne.

## 2. Panneau d'une phase : l'entrée haute et la section « Traçabilité »

Deux rappels `SC.addPanelSection('item', fn)` ; ils ne répondent que si `cible` est un identifiant de phase (`ph-<N>` ou
`ph-<N>@<ws>`, P80-C76-1), sinon `''`. La section ne remplace ni ne déplace rien : le contenu existant du panneau garde son
ordre et sa place. **Décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée** : section en
fin de panneau, pointée par une entrée d'une ligne en haut, plutôt qu'une section haute qui repousse le contenu existant.

### 2.1 Entrée haute (`{ top: true }`)

Un `.sec` contenant un seul `button.vf-trace-ligne` avec `data-vf-section="vf-trace-phase"` (clic, Entrée, Espace : le
panneau défile jusqu'à la section, brique existante). Ligne 1 : « Traçabilité » (12,5 px/500 `--text`). Ligne 2 : le bilan
(11,5 px, `--text-3`) : « 4 exigences : 1 avec une contradiction, 1 avec un manque, 2 avec une chaîne complète » (clamp 2 lignes, § 10.1). Hauteur de l'entrée : deux lignes, ≈ 40 px. Rendue
seulement si la phase a au moins une exigence rattachée. Nom accessible : « Traçabilité, 4 exigences, 1 avec une contradiction,
1 avec un manque, 2 avec une chaîne complète. Aller à la section. »

### 2.2 Section `id="vf-trace-phase"` (position par défaut, en fin de panneau)

Contenu chargé à l'ouverture du panneau par `GET /api/vf/tracabilite?vue=phase&cle=<N>` ; le rendu synchrone livre le titre
et l'état de chargement (§ 9), l'asynchrone remplit en place (`[data-ext]` rebindé, jamais un `rerender()` de la carte).

**Structure (de haut en bas).**
1. `h3` « Traçabilité » et compteur `.c` : « 4 exigences ».
2. Bilan (12,5 px/400, `--text-3`, clamp 2 lignes) : « 4 exigences : 1 avec une contradiction, 1 avec un manque, 2 avec une
   chaîne complète » ; catégories exclusives et règle de décompte : § 10.1 ; « 4 exigences, toutes avec une chaîne complète »
   seulement si les quatre maillons sont lus pour chacune ; jamais un pourcentage (P69-D-01).
3. **Clé des glyphes** (11,5 px, `--text-3`, clamp 3 lignes, une seule fois par section, visible en permanence, jamais au
   survol) : quatre paires glyphe et mot : « lu », « manque », « non lisible », « contradiction », puis « De gauche à droite :
   plan, SUMMARY, VERIFICATION, recette. » : c'est ce qui rend les colonnes de la bande identifiables sans survol.
4. Au plus **5 lignes d'exigence** (**3 sous 700 px**), puis « + N autres exigences » (§ 7). Ordre : d'abord les lignes à
   contradiction, puis à manque, puis à maillon non lisible, puis les chaînes complètes ; à égalité, l'ordre du ledger.
5. Repli « Preuves attachées » (§ 3), fermé par défaut, plafonné ouvert.

**Ligne d'exigence** : un seul `button type="button"`, classe `vf-trace-ligne`, pleine largeur, `margin-inline: calc(-1 *
var(--sp-12))`, `padding: var(--inset-row)`, rayon `var(--r-ctl)`, sur le fond du panneau (jamais sur `--raise`). Clamps
explicites : § 2.3.
- **Ligne 1** : identifiant en `--mono` 11,5 px/500 `--text-2` (« TRAC-01 », jamais tronqué), puis le texte de l'exigence en
  12,5 px/400 `--text`, `overflow-wrap: anywhere`.
- **Ligne 2** : la bande (quatre glyphes de 16 px fixes, `gap: var(--sp-4)`, dans l'ordre plan, SUMMARY, VERIFICATION,
  recette) puis, après `var(--sp-8)`, **un seul mot : le premier maillon qui n'est pas « lu », dans l'ordre de la bande**,
  jamais masqué par un autre : « manque : plan », « manque : SUMMARY », « manque : VERIFICATION », « manque : recette » ;
  « non lisible : SUMMARY » (etc.) ; si ce maillon est une contradiction : « contradiction : cochée, sans SUMMARY » (maillon
  SUMMARY) ou « contradiction : Complete, sans plan » (maillon plan). **« chaîne complète » seulement si les quatre maillons
  sont « lu »** (niveau exigence ou niveau phase). Mot en 11,5 px/500 `--text-2`.
- **Ligne 3** (absente si rien à dire) : les **mentions**, 11,5 px/400 `--text-3`, séparées par « · », dans cet ordre :
  (a) toute autre contradiction de la liste fermée qui n'est pas le mot de la ligne 2, précédée du glyphe octogone et en toutes
  lettres ; (b) les mentions neutres, sans glyphe : « non cochée, SUMMARY lu » ; « sans ligne de traçabilité » (P76-D-15bis) ;
  (c) le niveau des maillons lus au niveau de la phase, sans glyphe : « lu au niveau phase : VERIFICATION, recette ».
- **Emplacement des contradictions dans la bande** : « cochée, sans SUMMARY » met l'octogone à la place du maillon SUMMARY ;
  « Complete, sans plan » à la place du maillon plan. Un seul sens par emplacement.
- **Nom accessible** (le contenu natif du bouton, sans `aria-label` qui le remplace, pour que le texte visible soit contenu
  dans le nom) : le texte visible (identifiant, texte, mot, mentions) puis un `span.vf-trace-sr` masqué visuellement (position
  absolue, 1 px, `overflow: hidden`, `clip-path: inset(50%)` ; exception écrite de taille) : « Plan : lu, niveau exigence.
  SUMMARY : manque. VERIFICATION : lu, niveau phase. Recette : manque. Ouvrir l'exigence. » Glyphes `aria-hidden`.
- États : repos fond transparent ; survol `rgba(var(--ink), .06)` ; focus clavier `outline: 2px solid var(--ring);
  outline-offset: -2px` ; actif sans échelle. Un glyphe de contradiction n'est jamais posé sur `--raise` ni `--raise-2`
  (thème clair, sous 3:1).
- Clic, Entrée, Espace : ouvre le panneau de l'exigence (§ 5.1) ; focus sur son titre si l'activation vient du clavier.

**Aucune exigence rattachée** : sous le `h3` (compteur « 0 exigence »), la ligne neutre de § 9 ; le repli « Preuves attachées »
reste montré s'il y a des preuves.

### 2.3 Budget de hauteur de la section (bornée par des clamps, pas par la largeur)

Chaque bloc de texte porte un `-webkit-line-clamp` explicite : la hauteur ne dépend donc pas de la largeur utile. Le calcul vaut
aux largeurs de 320 px (colonne de 360 px) et de 294 px (plancher visé : colonne redimensionnée ou feuille étroite), où les mots
et mentions passent à la ligne jusqu'à leur clamp. Lignes de 12,5 px à 18 px, de 11,5 px à 16 px.

| Bloc | Bureau (≥ 701 px) | Feuille (≤ 700 px) |
|------|-------------------|--------------------|
| Titre `h3` | 24 | 24 |
| Bilan (clamp 2 lignes de 18) | ≤ 36 | ≤ 36 |
| Clé des glyphes (clamp 3 lignes de 16) | ≤ 48 | ≤ 48 |
| Ligne 1 de ligne d'exigence (clamp) | 2 lignes : 36 | 1 ligne : 18 |
| Ligne 2 (bande 16 ; mot clamp 2 lignes de 16) | ≤ 32 | ≤ 32 |
| Ligne 3 (mentions, clamp) | 2 lignes : ≤ 32 | 1 ligne : ≤ 16 |
| Remplissage et écarts d'une ligne (8 + 8 + 2 × `--sp-2`) | 20 | 20 |
| **Une ligne d'exigence, au pire** | **≤ 124** | **≤ 90** |
| Lignes montrées | 5 | 3 |
| « + N autres exigences » | 32 | 44 |
| Repli « Preuves attachées » fermé (`summary`) | 32 | 44 |
| **Section, au pire (repli fermé)** | **≤ 24 + 36 + 48 + 620 + 32 + 32 = 792** | **≤ 24 + 36 + 48 + 270 + 44 + 44 = 466** |

Sur la feuille, 466 px au pire tient sous le plafond de la feuille (`min(56vh, 480px)` = 480 px au plus) : la section se lit sans
défilement interne dès qu'on l'a atteinte. Le contenu existant du panneau précède la section et reste atteignable sans la
traverser ; l'entrée haute (≈ 40 px) y mène. Repli « Preuves attachées » **ouvert plafonné** : 6 lignes de preuve (4 sous
700 px), au plus ≈ 50 px chacune (libellé 18, chemin clampé à 1 ligne 16, remplissage 16), plus les intertitres : ≤ 356 px
bureau, ≤ 228 px feuille ; au-delà, « + N autres fichiers de preuve » ouvre le panneau de liste (§ 6). Section ouverte au pire :
≤ 1 148 px bureau (792 + 356), ≤ 694 px feuille (466 + 228) ; jamais de défilement interne à la section.

## 3. Preuves attachées (AUDC-I33)

Repli natif `<details class="vf-trace-repli">` dans la section de la phase, fermé par défaut ; son `<summary>` est de **rôle
« section »** (§ 13, style unique) : « Preuves attachées » et compteur `.c` « 5 fichiers ». **Plafonné ouvert** (§ 2.3) : 6 lignes
de preuve (4 sous 700 px), puis « + N autres fichiers de preuve » (§ 7) qui ouvre le panneau de liste « Preuves de la Phase N »
(§ 6).

Contenu, par groupe `.group-h` : d'abord « Phase » (preuves de la phase), puis un groupe par plan (« 76-01 », mono) :
- une ligne par fichier de preuve existant : libellé (12,5 px/500 `--text`) parmi « VERIFICATION », « Recette », « Trace
  rouge », « Sécurité », « Validation » ; puis le statut lu, « statut : passed » (mot du frontmatter ou de la ligne
  `**Statut :`, `textContent`, `--text-3`) ;
- dessous, le chemin relatif au lab en `--mono` 11,5 px `--text-3`, **clampé à 1 ligne** (ellipsis, `title` = chemin complet),
  rendu en `.vf-ref` : un clic copie le chemin **entier**, « Copié » apparaît 1,6 s (comportement existant). Le cockpit ne peut
  pas ouvrir un fichier : le chemin est copiable, pas ouvrable. `aria-label` : « Copier le chemin : <chemin> » ;
- pour un plan qui porte des `must_haves` : une ligne « Critères du plan, 5 critères », **le compte seulement** ; la liste en
  texte est dans le panneau de liste « Preuves de la Phase N » (12,5 px `--text-2`, ≤ 30 par page).
- Jamais un contenu de transcript, jamais une capture, jamais une preuve déduite (P76-D-24). Un fichier absent ne produit aucune
  ligne : son absence se lit dans le glyphe « manque » de la bande.
- Aucune preuve : ligne neutre de § 9.

## 4. Vue d'ensemble de Projet : trois sections repliées

Trois appels `SC.addPanelSection('overview', fn)` ; `setOverview` n'est jamais touché (il remplace). Ordre : « Jalon »,
« Décisions », « Mémoire des agents », après le corps de la vue d'ensemble (P80-C76-2). Chaque section est un `.sec` contenant
un `<details class="vf-trace-repli">`, **fermé par défaut** ; son `<summary>` est de rôle « section » (§ 13) : titre et
compteur avec unité (« 12 phases », « 32 ADR », « 268 entrées »). L'état ouvert ou fermé est tenu en variable de module et
restauré à chaque rendu : un re-rendu ne referme jamais une section ouverte ; il n'est pas mémorisé entre deux chargements.

Première ouverture : `GET /api/vf/tracabilite?vue=jalon`, `vue=adr` (porte aussi les registres) ou `vue=memoire` ; une réponse en
cache par empreinte s'affiche tout de suite. La clé `planning` de `VF_ETAT` relance l'appel d'une section **ouverte** seulement,
sans refermer ni perdre le défilement (P76-D-06, A13 de la 79).

### 4.1 « Jalon »

Bilan sous le `summary` (11,5 px, `--text-3`, clamp 2 lignes), catégories **exclusives par phase** (§ 10.1) : « 12 phases : 2 avec
une contradiction, 7 avec un manque, 1 avec un maillon non lisible, 1 sans exigence, 1 avec toutes les chaînes complètes »
(seules les catégories non nulles ; la somme égale le nombre de phases). Une ligne par phase (`button.vf-trace-ligne`), ≤ 30
puis « + N autres phases » :
- Ligne 1 : « Phase 76 » (12,5 px/500 `--text`), le nom (12,5 px/400 `--text-3`, une ligne, ellipsis), pastille de phase `.vst` à
  droite (glyphe et mot : « À faire », « En cours », « À recetter », « Fait »), `font-size` surchargé à 11,5 px (§ Typography).
- Ligne 2 (clamp 2 lignes) : les maillons en défaut **par maillon et par état**, comptés avec leur unité, dans l'ordre plan,
  SUMMARY, VERIFICATION, recette, « manquants » puis « non lisibles » : « 2 SUMMARY manquants, 1 SUMMARY non lisible,
  1 VERIFICATION manquante » (« 3 plans manquants », « 2 recettes manquantes ») ; ces nombres comptent des maillons et se
  recouvrent entre maillons (une exigence à SUMMARY et VERIFICATION manquants compte dans les deux) ; un maillon en
  contradiction n'est pas « manquant » (§ 10.1). Tous les maillons lus pour toutes les exigences : « toutes les chaînes
  complètes » ; aucune exigence : « aucune exigence rattachée ».
- Ligne 3 (absente si rien ; clamp 2 lignes) : (a) l'octogone puis « 1 exigence en contradiction » (cochée sans SUMMARY ou Complete
  sans plan, comptée une fois par exigence) ; (b) mention neutre, sans glyphe : « 2 lignes de traçabilité sans exigence »
  (**c'est l'unique emplacement de cette cause**, P76-D-15bis).
- Clic ou Entrée : `select('ph-<N>')`, la section de § 2 s'y trouve ; pas de panneau neuf.

### 4.2 « Décisions »

Bilan : « 32 ADR, 71 décisions dans 14 registres de phase ». Deux blocs :
1. Une ligne par ADR (`button.vf-trace-ligne`) : identifiant `--mono` 11,5 px/500 `--text-2` (« ADR-075 ») puis le titre lu après
   le numéro (12,5 px/400 `--text`, une ligne, ellipsis, `title` = titre complet). ≤ 30 puis « + N autres ADR ». Une ADR citée
   sans section dans `docs/ADR.md` n'a pas de ligne ici (§ 5.3).
2. Sous `.group-h` « Registres de phase », un `<details class="vf-trace-repli vf-trace-sous">` par registre, fermé : son
   `<summary>` est de rôle « sous-repli » (§ 13) : « Phase 41 » et « 12 décisions ». ≤ 30 registres, du plus récent au plus
   ancien, puis « + N autres registres ». Déplié : ses décisions (≤ 30 puis « + N autres décisions ») : identifiant mono
   11,5 px (« P41-D-02 » ; nue « D-04 ») et début de la ligne de définition (12,5 px, `--text-2`, une ligne, ellipsis).
   Un seul niveau de pliage dans un pliage : retrait gauche `var(--sp-12)`.

### 4.3 « Mémoire des agents »

Bilan : « 268 entrées, 12 agents, 7 entrées hors index, 33 liens cassés, 143 entrées sans lien entrant » (chiffres de la route,
jamais recalculés côté page). Les compteurs ont des unités différentes (entrées, liens, chemins) et ne s'additionnent pas ; « hors
index » et « sans lien entrant » se recouvrent (une entrée peut avoir les deux), chacun compte ses entrées (§ 10.1). Une ligne
par agent (le dossier sous `.claude/agent-memory/`, ≤ 30 puis « + N autres agents ») :
- Ligne 1 : nom de l'agent en `--mono` 12,5 px/500 `--text`, à droite « 24 entrées » (11,5 px, `--text-3`, tabular-nums).
- Ligne 2 (absente si aucune contradiction ; clamp 2 lignes) : octogone puis les comptes en mots : « 3 entrées hors index, 2 liens
  cassés, 1 chemin cité absent » (seuls les non nuls ; 11,5 px/500 `--text-2`).
- Ligne 3 (clamp 2 lignes) : neutre, `--text-3` : « 11 entrées sans lien entrant, 4 liens résolus par nom de fichier » ; rien :
  « aucun écart ».
- Clic ou Entrée : panneau de liste de l'agent (§ 6).

## 5. Panneaux d'objet (`SC.showPanel(html, bind)`)

`showPanel` remplace tout le contenu du `#panel` : le panneau d'objet porte donc son propre corps. Gabarit commun :

1. **Retour (hors 76)** : l'en-tête du panneau porte, avant le corps, le bouton « Retour : <titre> » de la Phase 80 ; la 76 ne
   dessine rien pour la navigation en arrière et ne répète pas le titre empilé dans son corps. Avant `SC.showPanel`, le panneau
   appelle `window.VF_PANNEAU.empiler({ titre, rouvrir })` (§ 0). La phase d'une exigence, d'une décision ou d'une ADR s'ouvre par
   la ligne « Phase » du corps (`select('ph-<N>')`), jamais par un second chemin d'en-tête.
2. **Titre** : `.ph` (`kindlabel` : « Exigence », « ADR », « Décision », « Mémoire ») puis `.pt` 20 px/600. Identifiants en `--mono`
   dans le titre. Ancre par objet : `id="vf-trace-<vue>-<cle>"` et `data-trace="<vue>:<cle>"` sur le titre (le fragment d'URL
   n'est pas promis : le moteur réécrit son hash, **à revalider**). Focus sur le titre (`tabindex="-1"`) si l'ouverture vient du
   clavier.
3. **Corps** : sections `.sec` (`h3` + compteur avec unité), voisins en lignes `button.vf-trace-ligne` (≤ 30 par sorte, § 7).
4. **Pied de source** (`.pd`, 11,5 px, `--text-3`) : « Lu dans <chemin relatif> » en mono, copiable (`.vf-ref`). Jamais un
   chemin absolu ni `~/`.

### 5.1 Exigence

- Titre : identifiant. `.pd` : le texte de l'exigence, entier (pas de clamp), `overflow-wrap: anywhere`.
- Section « Chaîne » (`h3`) : d'abord une phrase d'aide (11,5 px, `--text-3`) : « Niveau exigence : le fichier lu cite cette
  exigence. Niveau phase : le fichier existe pour la phase sans la citer. » Puis quatre lignes, une par maillon : glyphe de
  16 px, nom du maillon (12,5 px/500 `--text`), puis, sur la même ligne, état et niveau en toutes lettres, **seule source
  visible du niveau** : « lu, niveau exigence », « lu, niveau phase », « manque », « non lisible », et, pour une contradiction,
  la phrase de § 10 à la place de l'état : « contradiction : case cochée au ledger, aucun SUMMARY lu » (11,5 px `--text-3`).
  **Une contradiction de maillon vit ici et nulle part ailleurs dans ce panneau** (pas de section « Contradictions »). Dessous,
  la source : chemin mono copiable et le champ lu. Plan : un `.tag` par plan qui la cite (« 76-01 »), rendu en
  `button.tag.vf-trace-puce` : focus `outline: 2px solid var(--ring)`, survol `rgba(var(--ink), .1)`, cible 44 px sous
  `pointer: coarse` (`min-height: 44px`, `display: inline-flex`, `align-items: center`) ; chaque plan s'ouvre par
  `select('f:<chemin>')`.
- Section « Mentions » (absente si aucune), phrases neutres, sans glyphe : « Case non cochée au ledger, un SUMMARY est lu. » ;
  « Aucune ligne du tableau de traçabilité ne la nomme. »
- Section « Rattachement » : « Phase 76, Traçabilité au cockpit » (bouton), puis « Ligne de traçabilité du ledger : Phase 76,
  Pending » si elle existe, sinon « Rattachée par le champ requirements d'un plan. »
- Pas de section « Décisions citées » : aucune arête exigence vers décision n'est lue (P76-D-17).

### 5.2 ADR

Titre « ADR-075 » ; `.pd` : le titre lu après le numéro, jamais un résumé. « Décisions qui la citent » (≤ 30, puis « + N autres
décisions »), « Commits qui la citent » (≤ 30, § 5.5). Source : « Lu dans docs/ADR.md ».

### 5.3 Décision

- Titre « P41-D-02 » ; nue « D-04, Phase 41 ». `.pd` : la ligne de définition, entière.
- « Phase » : un bouton. « ADR citées » : une ligne par ADR citée ; avec section : bouton ; sans : texte mono suivi de « sans
  section dans docs/ADR.md » (`--text-3`), non interactif.
- « Commits qui la citent » (§ 5.5). Décision nue : à la place, « Décision nue : aucun commit ne lui est relié, la citation sans
  phase est ambiguë. » (12,5 px, `--text-3`).
- Source : « Lu dans <registre de phase> ».

### 5.4 Entrée de mémoire

- Titre : le `name` (mono, passe à la ligne). Rappel (11,5 px, `--text-3`) : « Seule la structure est lue : ni description ni
  contenu. »
- « Fiche » : « Agent » (mono), « Type » (`.tag`), « Dernier commit » (« 8 nov. 2026 », jour seul), « Liens sortants »
  (« 3 liens »), « Liens entrants » (« 2 liens »).
- « État » : **états de l'entrée seulement**, un mot avec son glyphe : « hors index » (octogone) et « sans lien entrant »
  (sans glyphe) ; aucun des deux : « Dans l'index, avec au moins un lien entrant. » Un lien cassé et un chemin absent ne se
  répètent pas ici : ils vivent sur leur ligne.
- « Liens sortants » : une ligne par lien (nom cible mono, puis « résolu », « résolu par nom de fichier » (carré à deux barres)
  ou « lien cassé » (octogone)). Cible résolue : bouton ; cassée : texte. ≤ 30 puis « + N autres liens ».
- « Liens entrants » : lignes de boutons, ≤ 30 ; les liens d'index (`MEMORY.md`) n'y figurent pas.
- **« Chemins cités et absents de HEAD »** (absente si aucun) : **seuls** les chemins qui répondent à « cite un chemin absent »
  (P76-D-22) : relatifs au dépôt, absents de HEAD, présents dans l'historique lu. Une ligne : chemin mono, octogone,
  « absent de HEAD, présent dans l'historique lu ». Aucun autre chemin du corps n'est montré, ni compté, ni nommé ; le chemin du
  fichier de mémoire lui-même (structure suivie par git) n'est montré que dans le pied de source.
- Jamais `description`, jamais le corps, jamais un chemin `~/` ou absolu (P76-D-20).

### 5.5 Ligne de commit

`button.vf-trace-commit` : sha court en `--mono` 11,5 px/500 `--text-2` (7 caractères), jour (« 8 nov. 2026 », `--text-3`), puis
le sujet (12,5 px `--text`, une ligne, ellipsis, `title` = sujet complet). Le corps du message n'est jamais servi. Clic ou
Entrée : ouvre le tiroir Git existant (`window.VFGitTiroir.ouvrir()`, Phase 78, détail sans diff) ; la sélection par sha dépend
d'un crochet de la 78 (`VFGitExt`), **à revalider** ; à défaut, le tiroir s'ouvre sans sélection. Git ou `VFGitTiroir` absent :
la ligne est du texte, non interactive. Nom : « Commit a1b2c3d, 8 nov. 2026, <sujet>. Ouvrir dans l'historique Git. » (le
texte visible est contenu dans le nom). Borne atteinte (`bornes.tronque`) : au-dessus de la liste, « Lecture bornée : la liste
peut être incomplète. »

## 6. Panneaux de liste et pagination

Ouverts par « + N autres », par une ligne d'agent ou par un registre au-delà du seuil. Gabarit de § 5 (Retour de l'en-tête, titre
`.pt` : « Exigences de la Phase 76 », « Preuves de la Phase 76 », « Entrées de vf-dev-manager », « ADR »). Corps : 30 lignes par
page, puis `<nav aria-label="Pagination">` : `.btn.soft` « Précédentes » et « Suivantes » (`disabled` à la borne), au centre
« 31 à 60 sur 83 exigences » (l'unité suit la sorte : ADR, commits, entrées, liens, fichiers de preuve ; 11,5 px `--text-3`,
tabular-nums, `aria-live="polite"`). Pas de pagination infinie. Le changement de page replace le focus sur le titre. Boutons de
32 px de haut (44 px tactile), `font-size` 12,5 px (§ Typography).

**Ligne d'entrée de mémoire** (liste d'un agent, `button.vf-trace-ligne`) : ligne 1 `name` mono 12,5 px/500 `--text` et `.tag`
du type ; ligne 2 « modifiée le 8 nov. 2026 · 2 liens entrants, 3 liens sortants » (11,5 px `--text-3`) ; ligne 3 (absente si
rien, clamp 2 lignes) : octogone puis les contradictions en mots (« hors index », « 1 lien cassé », « cite un chemin absent »),
puis, après « · » et sans glyphe, « sans lien entrant ». **Ligne de preuve** (liste « Preuves de la Phase N ») : libellé,
statut, chemin copiable clampé, puis les critères du plan en texte.

## 7. Échelle : seuils et « + N autres »

- **Section « Traçabilité » d'une phase : 5 lignes (3 sous 700 px)**, lignes à trou d'abord, budget de hauteur § 2.3 ; **repli
  « Preuves attachées » ouvert : 6 lignes (4 sous 700 px)** (§ 3).
- **Ailleurs, dans un panneau ou une section : au plus 30 voisins d'une même sorte** (exigences d'une liste, ADR, décisions,
  commits, liens, entrées, agents, registres, critères).
- Au-delà : `button.vf-trace-plus` (12,5 px/500 `--text-2`, `padding: var(--inset-row)`, survol `rgba(var(--ink), .06)`, focus
  `--ring`) qui ouvre le panneau de liste paginé (§ 6). Le libellé nomme toujours la sorte : « + 12 autres exigences », « + 2 autres
  ADR », « + 5 autres registres », « + 40 autres commits », « + 3 autres agents ». Jamais la classe `.more` du moteur (texte
  non interactif en `--text-4`). Le total est celui de la route, jamais calculé par la page.

## 8. Clavier et lecteur d'écran

- Tout lien et toute ligne est un `button type="button"` ou un `summary` natif : focalisable, Entrée et Espace, ordre de
  tabulation = ordre visuel. Aucun `tabindex` positif. Aucune touche globale neuve : la 76 ne prend aucune lettre au moteur.
- Focus visible : `outline: 2px solid var(--ring)`, `outline-offset: -2px` dans le panneau, `2px` sur un `summary`.
- Ouverture d'un objet par le clavier : focus sur le titre (`tabindex="-1"`). Par la souris ou le toucher : le focus ne bouge
  pas (une proposition ne prend jamais le focus, Q5).
- Échap, focus dans un panneau de la 76 : si une surcouche est ouverte (`window.VF_SURCOUCHES.ouverte()`), la 76 ne fait rien,
  la pile des surcouches a la priorité ; sinon, pile commune non vide : appelle le Retour commun (`window.VF_PANNEAU.retour()`,
  `stopPropagation`) ; pile vide : ferme le panneau d'objet (`SC.closePanel()`) et rend le focus à la ligne qui l'a ouvert,
  mémorisée à l'ouverture ; sur téléphone, pile vide, l'événement n'est pas arrêté et le moteur ferme la feuille. Échap ne ferme
  jamais une section dépliée seule. **À revalider** après la 80.
- Rôles distincts pour chaque élément de navigation : Retour commun (en-tête, hors 76, « Retour : <titre> ») ; lignes d'objet
  `button` (« Ouvrir l'exigence ») ; entrée haute `button` (« Aller à la section ») ; pagination `nav` (« Précédentes »,
  « Suivantes ») ; sections et replis `details`/`summary` natifs.
- Listes `ul` de `li`. Une région `role="status"` par section chargée dit « Lecture de la traçabilité » puis rien (annonce
  seulement du chargement et des erreurs) ; `aria-busy="true"` pendant le chargement. Chaque glyphe est `aria-hidden` ; son sens
  est dans le texte masqué de la ligne (§ 2.2) ou dans le mot voisin. `id` unique par objet (un seul panneau ouvert).

## 9. États : chargement, vide, dégradé, erreur

Tous neutres : texte `--text-2` ou `--text-3`, jamais corail, jamais de fond teinté, jamais de texte coloré. Boîte éventuelle :
`--warn-bg` (neutre, 5 % d'encre) sur `--surface`, `var(--r-ctl)`, `padding: var(--inset-box)`, texte `--text-2`. **Chaque état vide
ou dégradé dit ce qui l'a produit puis ce qui le lèverait.**

| État | Où | Copy exacte |
|------|----|-------------|
| Chargement (au-delà de 150 ms) | section, panneau | `aria-busy="true"` ; trois lignes fantômes de 32 px (`--raise`, `var(--r-ctl)`, sans balayage) ; « Lecture de la traçabilité » (`--text-3`). Avant 150 ms : rien |
| Phase sans exigence | « Traçabilité » | « Aucune exigence rattachée à cette phase. Une ligne du tableau de traçabilité du ledger, ou le champ requirements d'un plan, la rattache. » |
| Aucune phase au jalon | « Jalon » | « Aucune phase dans le jalon en cours. Une phase inscrite à la feuille de route sous ce jalon apparaît ici. » |
| Pas de `docs/ADR.md` | « Décisions » | « Pas de docs/ADR.md dans ce dossier. Les sections ADR-NNN de ce fichier apparaîtraient ici. » (les registres de phase restent montrés s'ils existent) |
| Aucun registre de décisions | « Décisions » | « Aucune décision définie dans les registres de phase. Les lignes Pnn-D-nn d'un fichier CONTEXT de phase apparaissent ici. » |
| Pas de compartiment de planification | « Traçabilité » et les trois sections | « Aucun compartiment de planification lu : la traçabilité n'est pas disponible. Un compartiment avec son ledger de phases la rend lisible. » (une ligne, rien d'autre) |
| Traçabilité rangée en « Étape N » | « Traçabilité », « Jalon » | « La traçabilité de ce ledger est rangée par Étape N : 3 étapes lues comme des phases, 2 sans dossier de phase. Un dossier de phase par étape les rend lisibles. » ; aucune ne désigne un dossier : « La traçabilité de ce ledger est rangée par Étape N, aucune ne désigne un dossier de phase. Un dossier de phase par étape la rend lisible. » (P76-D-12) |
| Pas de `.claude/agent-memory/` | « Mémoire des agents » | « Pas de .claude/agent-memory/ dans ce dossier. Les fichiers de mémoire suivis par git apparaîtraient ici. » |
| `.claude/` ignoré par git | « Mémoire des agents » | « .claude/ n'est pas suivi par git : 12 fichiers non suivis, aucune entrée à lire. Suivre .claude/agent-memory/ dans git les rend lisibles. » (le nombre, jamais un nom) |
| Pas de git | « Mémoire », commits | « Git n'est pas disponible : la mémoire des agents n'est pas lue. Un dépôt git la rend lisible. » ; « Git n'est pas disponible : les commits qui citent cet objet ne sont pas lus. Un dépôt git les rend lisibles. » ; le reste s'affiche |
| Aucun commit citant | panneau ADR, décision | « Aucun commit ne cite cet objet. Un message de commit qui nomme son identifiant le relierait. » |
| Agent sans entrée | liste d'agent | « Aucune entrée suivie pour cet agent. Un fichier de mémoire suivi par git sous son dossier apparaît ici. » |
| Aucune preuve | « Preuves attachées » | « Aucune preuve attachée. Un fichier VERIFICATION, de recette, de trace rouge, de sécurité ou de validation dans le dossier de la phase l'attacherait. » |
| Réponse bornée | listes de commits, d'entrées | « Lecture bornée : la liste peut être incomplète. Une lecture plus courte, ou moins de commits, la lèverait. » (11,5 px `--text-3`, au-dessus de la liste ; une réponse bornée ne se présente jamais comme complète) |
| Route en échec (503, délai, 400 inattendu) | section, panneau | boîte neutre : titre « La traçabilité est indisponible » (12,5 px/600 `--text`), cause « La lecture du dépôt a échoué ou dépassé le délai. » (12,5 px, `--text-2`), `.btn.soft` « Réessayer » ; le reste du panneau fonctionne |
| Objet introuvable ou disparu | panneau | « Cet objet n'existe plus dans le dépôt. Le bouton Retour de l'en-tête rouvre la vue précédente. » |
| Rafraîchissement par `planning` | section ouverte | le contenu se remplace sans fondu ; défilement et pliages conservés |

La page ne construit jamais une `cle` hors motif ; un 400 inattendu se rend comme « Route en échec ».

## 10. Où vit chaque cause de contradiction (P76-D-04, P76-D-15bis)

Corail réservé à la **liste fermée** : cochée sans SUMMARY, Complete sans plan, lien cassé, hors index, chemin cité absent. Le
corail est porté par le seul glyphe octogone ; la phrase est en `--text-2`. **Un emplacement par cause et par surface**, sans
exception tacite : la règle « mot en ligne 2 si c'est le premier maillon non lu, sinon en ligne 3 » est écrite une fois, ici.

| Cause lue | Corail | Ligne d'exigence ou d'agent ou d'entrée | Panneau d'objet | Vue d'ensemble |
|-----------|--------|------------------------------------------|-----------------|----------------|
| Case cochée au ledger, aucun SUMMARY lu | oui | octogone à la place du maillon SUMMARY ; mot « contradiction : cochée, sans SUMMARY » en ligne 2 si SUMMARY est le premier maillon non lu, sinon en ligne 3 | ligne SUMMARY de « Chaîne » (§ 5.1) : « contradiction : case cochée au ledger, aucun SUMMARY lu » | « Jalon », ligne 3 : compté dans « N exigences en contradiction » |
| Statut « Complete » sans plan | oui | octogone à la place du maillon plan ; mot « contradiction : Complete, sans plan » en ligne 2 (le plan est le premier maillon) | ligne Plan de « Chaîne » : « contradiction : statut Complete au tableau de traçabilité, aucun plan ne la cite » | idem |
| Lien `[[…]]` cassé | oui | ligne d'entrée : « 1 lien cassé » en ligne 3 ; ligne d'agent : « 2 liens cassés » en ligne 2 | ligne du lien dans « Liens sortants » : « lien cassé » | décompte du bilan « Mémoire » |
| Mémoire hors index | oui | ligne d'entrée : « hors index » en ligne 3 ; ligne d'agent : « 3 entrées hors index » en ligne 2 | section « État » : « hors index » | décompte du bilan « Mémoire » |
| Chemin cité absent | oui | ligne d'entrée : « cite un chemin absent » en ligne 3 ; ligne d'agent : « 1 chemin cité absent » en ligne 2 | ligne du chemin dans « Chemins cités et absents de HEAD » | décompte du bilan « Mémoire » |
| Case non cochée avec SUMMARY lu | non | mention neutre, ligne 3 : « non cochée, SUMMARY lu » | « Mentions » : « Case non cochée au ledger, un SUMMARY est lu. » | « Jalon » : aucune |
| Exigence sans ligne de traçabilité | non | mention neutre, ligne 3 : « sans ligne de traçabilité » | « Mentions » : « Aucune ligne du tableau de traçabilité ne la nomme. » | « Jalon » : aucune |
| Ligne de traçabilité sans exigence | non | aucune (pas de ligne d'exigence où la poser) | aucun | « Jalon », ligne 3 : « 2 lignes de traçabilité sans exigence », **seul emplacement** |

Un mot de ligne ne masque jamais le premier trou : la ligne 2 dit toujours le premier maillon non lu de la bande ; toute autre
contradiction passe en ligne 3. **Décisions de détail déléguées par Samuel (message session principale, 2026-11-08), option
recommandée** : « non cochée, SUMMARY lu » est neutre (absent de la liste fermée de P76-D-04, malgré P76-D-15). Le mot « rouge »
du but du 2026-11-03 est lu « marqué et visible » dans les teintes Graphite (A-1, § 12). Aucune phrase n'est un verdict sur le
travail : elle décrit ce que deux fichiers disent l'un de l'autre.

### 10.1 Règle de décompte des bilans

- **Un maillon a un seul état** parmi lu, manque, non lisible, contradiction. « Cochée, sans SUMMARY » donne au maillon SUMMARY
  l'état contradiction (jamais « manque ») ; « Complete, sans plan » donne au maillon plan l'état contradiction.
- **Bilan d'exigences** (section de phase, entrée haute) : catégories **exclusives**, chaque exigence comptée une seule fois dans
  la première qui s'applique, dans cet ordre : contradiction, manque, maillon non lisible, chaîne complète. Une exigence « cochée
  sans SUMMARY » dont VERIFICATION manque compte donc en contradiction. La somme égale le nombre d'exigences ; seules les
  catégories non nulles s'écrivent ; « chaîne complète » exige quatre maillons « lu ».
- **Bilan de jalon** : catégories **exclusives par phase**, selon la pire exigence de la phase, mêmes quatre catégories plus
  « sans exigence » ; la somme égale le nombre de phases.
- **Ligne 2 d'une phase du Jalon** : compte des **maillons** par état, avec chevauchement entre maillons (dit au § 4.1) ;
  « manquants » exclut les maillons en contradiction ; « non lisibles » se compte à part. **Ligne 3** : « N exigences en
  contradiction » compte des exigences (une fois chacune), « N lignes de traçabilité sans exigence » compte des lignes.
- **Bilan de mémoire** : compteurs par unité (entrées, liens, chemins), sans somme ; « hors index » et « sans lien entrant »
  se recouvrent et le disent ; les liens résolus par nom de fichier sont comptés à part, jamais en défaut.

## Spacing Scale

Grille fermée de DESIGN § 4 (P71.5-D-01) : 2, 4, 6, 8, 12, 16, 20, 24, 32. Jamais 10, 14, 22. Chaque valeur s'écrit
`var(--sp-N)`, un jeton sémantique ou `calc()` de jetons.

| Jeton | Valeur | Usage dans cette phase |
|-------|--------|------------------------|
| `--sp-2` | 2 px | écart entre deux lignes de liste, entre les lignes d'une ligne d'objet |
| `--sp-4` | 4 px | écart entre glyphes de la bande, entre glyphe et mot |
| `--sp-6` | 6 px | écart entre identifiant et texte, séparateurs « · » des mentions |
| `--sp-8` | 8 px | écart bande et mot ; marge sous un `summary` ouvert |
| `--sp-12` | 12 px | retrait d'un registre déplié ; `margin-inline` négatif d'une ligne pleine largeur ; boîte neutre |
| `--sp-16` | 16 px | écart entre blocs d'un panneau d'objet |
| `--inset-row` | 8 × 12 | `padding` de toute ligne cliquable |
| `--inset-pill` | 2 × 8 | `.tag` |
| `--inset-panel`, `--gap-section` | 20, 24 | via `.sec`, jamais redéfinis |

Tailles hors grille d'espacement, listes fermées (hauteurs de contrôle et dimensions) : glyphe 16 px fixes (`width` et `height`, jamais en `em`) ;
ligne fantôme et `summary` 32 px ; cible tactile 44 px ; seuils de 5, 3 et 30.
Exception écrite : le texte masqué `.vf-trace-sr` (1 px, comme un filet). **Aucun rayon littéral** : toute ligne, boîte et ligne
fantôme prend `var(--r-ctl)` (12 px) ; ce rayon n'est pas celui de `.vf-link` (10 px, littéral) : écart voulu, décision déléguée
par Samuel (message session principale, 2026-11-08), option recommandée, pour n'écrire aucune valeur en dur. Rien d'existant
n'est modifié.

## Typography

**Quatre tailles seulement**, deux graisses posées (500 et 600 ; le 400 est hérité du moteur, jamais écrit). Aucune autre taille
(ni 11, ni 12, ni 13) dans les éléments neufs.

| Rôle | Taille | Graisse | Interligne |
|------|--------|---------|------------|
| Titre de panneau d'objet (`.pt`) | 20 px | 600 | 1.3 (existant), interlettrage -.02em |
| Corps et texte d'objet (`.pd`, définition, phrase de contradiction) | 13,5 px (hérité) | 400 hérité | 1.6 (existant) |
| Ligne, titre de section (`.sec h3`, `summary`), libellé de maillon, ADR, bilan, cause d'erreur | 12,5 px | 500 (libellés, `summary`), 400 (texte), 600 (titre « La traçabilité est indisponible ») | 1.45 |
| Méta : identifiants mono, sha, dates, mots d'état, clé, mentions, pagination | 11,5 px | 500 (identifiants, mots d'état), 400 (reste) | 16 px |

`--mono` pour identifiants (TRAC-01, ADR-075, P41-D-02), sha, chemins, `name` de mémoire ; `--sans` ailleurs. Chiffres en
`font-variant-numeric: tabular-nums` (compteurs, pagination).

**Surcharges des briques réemployées** (écrites sous un parent `.vf-trace`, qui enveloppe chaque section et panneau de la 76,
sans toucher la règle d'origine) : le moteur pose des tailles hors de ces quatre (13, 11, 11,5), on les ramène.

| Brique | Taille d'origine | Surcharge `vf-trace-*` |
|--------|------------------|------------------------|
| `.btn.soft` (Réessayer, Précédentes, Suivantes) | 13 px, hauteur 36 px, pastille | `font-size: 12.5px; height: 32px` (hauteur de `#ask-sheet .sh .btn`) ; 44 px sous `pointer: coarse` ; une seule hauteur pour tous les boutons de la 76 |
| `.vf-ref code` (chemin copiable) | 11 px | `font-size: 11.5px` |
| `.vf-copie-etat` (« Copié ») | 11 px | `font-size: 11.5px` |
| `.vst` (pastille de phase du « Jalon ») | 11 px (glyphe `1.45em`) | `font-size: 11.5px` (glyphe 16,7 px : brique du moteur, pas un glyphe de la famille § 1.1) |
| `.tag` (type, plan) | 11,5 px | aucune |
| `.group-h` | 12,5 px | aucune ; sa variante `.gd` (12 px) n'est pas employée |

## Color

Graphite : aucune couleur de marque, `--accent` = `--on` (neutre). Pas de répartition 60/30/10 imposée ; répartition réelle.

| Rôle | Valeur (variable) | Usage |
|------|-------------------|-------|
| Dominant | `--elev` (verre du panneau), `--surface` | fond du panneau, lignes au repos |
| Secondaire | `rgba(var(--ink), .06)` survol, `--surface-hover`, `--raise` (hors teinte d'état), `--hair` | survol, lignes fantômes, séparateurs |
| Texte | `--text`, `--text-2`, `--text-3`, `--text-4` | hiérarchie ; `--text-4` seulement pour un séparateur ou un compteur doublé par un texte lisible |
| Accent | aucun | |
| Teinte d'état | `--st-blocked` (corail) | uniquement l'octogone de contradiction de la liste fermée (§ 10) |

Réservé au corail : l'octogone des cinq causes de la liste fermée. Rien d'autre : ni texte, ni fond, ni contour, ni liseré ;
ni les mentions neutres, ni « manque », ni « non lisible ». Vert et jaune : pas d'usage neuf ; seule la pastille `.vst` du
« Jalon » les porte par son glyphe. Contraste : texte ≥ 4,5:1 (`--text-3`, `--text-4` mesurés dans DESIGN § 2) ; glyphe ≥ 3:1
sur `--surface` et `--bg` ; une teinte d'état jamais sur `--raise` ni `--raise-2` en thème clair. Destructif : sans objet.

## Copywriting Contract

| Élément | Copy |
|---------|------|
| CTA principal | aucun (lecture seule) ; plus proche : « Ouvrir l'exigence », « Ouvrir l'ADR », « Ouvrir la décision », « Ouvrir l'entrée », « Aller à la section » (nom accessible des lignes, jamais un libellé visible) |
| Titres de section | « Traçabilité », « Jalon », « Décisions », « Mémoire des agents », « Preuves attachées », « Chaîne », « Mentions », « Rattachement », « Fiche », « État », « Liens sortants », « Liens entrants », « Chemins cités et absents de HEAD », « Décisions qui la citent », « Commits qui la citent », « ADR citées », « Registres de phase » |
| Compteurs de section (avec unité) | « 4 exigences », « 12 phases », « 32 ADR », « 268 entrées », « 5 fichiers », « 12 décisions », « 3 liens » |
| Maillons | « Plan », « SUMMARY », « VERIFICATION », « Recette » (dans la clé et les mots : plan, SUMMARY, VERIFICATION, recette) |
| États de maillon | « lu », « manque », « non lisible », « contradiction » ; niveaux : « niveau exigence », « niveau phase » |
| Clé des glyphes | « lu », « manque », « non lisible », « contradiction », « De gauche à droite : plan, SUMMARY, VERIFICATION, recette. » |
| Mot de ligne (ligne 2) | « manque : plan », « manque : SUMMARY », « manque : VERIFICATION », « manque : recette », « non lisible : plan », « non lisible : SUMMARY », « non lisible : VERIFICATION », « non lisible : recette », « contradiction : cochée, sans SUMMARY », « contradiction : Complete, sans plan », « chaîne complète » |
| Mentions (ligne 3) | « non cochée, SUMMARY lu », « sans ligne de traçabilité », « lu au niveau phase : VERIFICATION, recette », « 2 lignes de traçabilité sans exigence » (Jalon) |
| Bilans (catégories exclusives, § 10.1) | « 4 exigences : 1 avec une contradiction, 1 avec un manque, 2 avec une chaîne complète » ; « 4 exigences : 1 avec un maillon non lisible, 3 avec une chaîne complète » ; « 4 exigences, toutes avec une chaîne complète » ; « 12 phases : 2 avec une contradiction, 7 avec un manque, 1 avec un maillon non lisible, 1 sans exigence, 1 avec toutes les chaînes complètes » ; « 32 ADR, 71 décisions dans 14 registres de phase » ; « 268 entrées, 12 agents, 7 entrées hors index, 33 liens cassés, 143 entrées sans lien entrant » |
| Trous du Jalon (maillons par état, § 4.1) | « 2 SUMMARY manquants, 1 SUMMARY non lisible, 1 VERIFICATION manquante », « 3 plans manquants », « 2 recettes manquantes », « 1 VERIFICATION non lisible », « toutes les chaînes complètes », « aucune exigence rattachée », « 1 exigence en contradiction » |
| États mémoire | « hors index », « lien cassé », « cite un chemin absent », « résolu par nom de fichier », « sans lien entrant », « aucun écart » (ligne d'agent), « Dans l'index, avec au moins un lien entrant. » (section « État » d'une entrée) ; comptes d'agent : « 3 entrées hors index », « 2 liens cassés », « 1 chemin cité absent », « 11 entrées sans lien entrant », « 4 liens résolus par nom de fichier » |
| Preuves | « VERIFICATION », « Recette », « Trace rouge », « Sécurité », « Validation », « Critères du plan, 5 critères », « statut : passed », « + 4 autres fichiers de preuve », « Preuves de la Phase 76 » |
| Dates, sha | « 8 nov. 2026 » (jour seul, mois abrégé français) ; sha de 7 caractères |
| Débordement | « + 12 autres exigences », « + 2 autres ADR », « + 5 autres registres », « + 40 autres commits », « + 3 autres agents », « + 4 autres liens », « + 4 autres fichiers de preuve » ; « Précédentes », « Suivantes », « 31 à 60 sur 83 exigences » |
| Retour | « Retour : <titre> » : libellé fourni par l'en-tête de la Phase 80, `<titre>` du lab rendu en texte ; la 76 n'écrit aucun libellé de retour |
| Chargement | « Lecture de la traçabilité » |
| État vide (titre) | la phrase d'absence du cas, § 9 (une seule phrase suivie de ce qui le lèverait) |
| État vide (corps) | la seconde phrase du même cas, § 9 : ce qui lèverait l'absence ; aucune action à proposer (lecture seule) |
| Erreur | titre « La traçabilité est indisponible » ; cause « La lecture du dépôt a échoué ou dépassé le délai. » ; bouton « Réessayer » |
| Borne | « Lecture bornée : la liste peut être incomplète. Une lecture plus courte, ou moins de commits, la lèverait. » |
| Note mémoire | « Seule la structure est lue : ni description ni contenu. » |
| Source | « Lu dans <chemin relatif> » ; copie : « Copier le chemin : <chemin> », retour « Copié » |
| Confirmation destructive | sans objet : aucune action destructive, aucune écriture (hors périmètre) |

## 11. Responsive : 1440, 1024, 390 px

Le panneau d'objet est le `#panel` du moteur ; la 76 ne change ni sa position, ni sa taille, ni son `z-index`. Un panneau
latéral ne pousse jamais la carte (Q12).

| Largeur | Comportement du panneau | Ce que la 76 vérifie |
|---------|-------------------------|----------------------|
| 1440 px | colonne de 360 px à droite (`--panel-w`, redimensionnable ; largeur utile de ligne 320 px) | section de phase : 5 lignes, ≤ 792 px de haut au pire (§ 2.3) ; identifiant jamais coupé ; mots qui passent à la ligne ; carte non poussée |
| 1024 px (souris ≥ 1000 px) | même colonne de 360 px ; il reste ≥ 280 px de carte visible | idem ; aucun défilement horizontal |
| 768 px et 700 à 999 px | colonne de 360 px conservée (sauf tactile), carte réduite | cibles 44 px si `pointer: coarse` ; aucune largeur fixe de ligne |
| 390 px (≤ 700 px) | feuille basse : `left/right 8 px`, hauteur max `min(56vh, 480px)`, défilement dans la feuille | largeur utile ≈ 334 px ; **section de phase : 3 lignes, texte sur 1 ligne, ≤ 466 px au pire (§ 2.3)**, après le contenu existant que l'entrée haute (≈ 40 px) permet de sauter ; sections de la vue d'ensemble repliées ; lignes et boutons ≥ 44 px ; pagination en boutons 44 px ; aucun défilement horizontal |

Largeur de panneau redimensionnée par l'utilisateur : toute ligne reste fluide (`min-width: 0`, `overflow-wrap: anywhere`, aucune
largeur fixe en px sur un texte). Cibles tactiles ≥ 44 px dans `@media (max-width: 700px), (pointer: coarse)` (lignes,
`.vf-trace-commit`, `.vf-trace-plus`, `summary`, boutons de pagination). Mouvement : aucune animation
neuve (le moteur anime déjà l'entrée du panneau, `panelIn`, avec sa variante mouvement réduit) ; pliage de `details` sans
transition.

## 12. À Samuel (non bloquant, le contrat tient sans réponse)

Reprises du CONTEXT ; le contrat applique l'option recommandée.
- **A-1 : « Les trous en rouge » face à Q9.** Appliqué : (a), glyphe de forme propre et mot pour une absence, octogone corail
  pour la liste fermée de contradictions (P76-D-04, P76-D-15bis). Alternatives : corail pour tout trou ; tout neutre.
- **A-2 : « graphe navigable » sans dessin.** Appliqué : panneaux reliés, voisinage seul. Un dessin de l'îlot de mémoire d'un
  agent peut venir plus tard sans rien défaire (différé).

Aucune autre question de goût pur n'est ouverte. Décisions de détail prises, toutes **décisions déléguées par Samuel (message
session principale, 2026-11-08), option recommandée**, à challenger par `vf-design-judge` : famille de formes carrés et octogone
(§ 1.1, octogone au trait à carré central : décision du manager) ; « lu » neutre ; section en fin de panneau avec entrée haute (§ 2) ; seuils de 5 et 3 lignes (§ 2.2) ; aucun fil
d'Ariane, le Retour unique de la 80 (§ 0, § 5) ; « non cochée, SUMMARY lu » neutre (§ 10) ; un seul octogone pour les trois contradictions de
mémoire, distinguées par leur emplacement (§ 1.3) ; rayon `--r-ctl` partout (§ Spacing).

## 13. Variables CSS et styles uniques par rôle

| Variable | Usage |
|----------|-------|
| `--sans`, `--mono` | texte ; identifiants, sha, chemins, `name` |
| `--elev`, `--surface`, `--surface-hover`, `--raise` | fond du panneau, lignes, survol, lignes fantômes (`--raise` jamais sous une teinte d'état) |
| `--hair`, `--ink` | filets ; `rgba(var(--ink), α)` de survol |
| `--text`, `--text-2`, `--text-3`, `--text-4` | hiérarchie du texte |
| `--st-blocked` (`--sev-high`), `--st-todo`, `--c-st`, `--g-st` | octogone ; carré vide ; mécanisme de masque |
| `--ring` | focus |
| `--r-ctl`, `--r-panel` | lignes, boîtes neutres, lignes fantômes ; panneau (non modifié) |
| `--warn-bg` | boîte neutre d'erreur (5 % d'encre) |
| `--sp-2`, `--sp-4`, `--sp-6`, `--sp-8`, `--sp-12`, `--sp-16`, `--inset-row`, `--inset-pill`, `--inset-box` | espacements |

Variables absentes à ne pas inventer : `--text-1`, `--trace-*`, `--git-*`. Aucune valeur de couleur, d'espacement ni de rayon
en dur ; seules exceptions de DESIGN § 4 (filets 1 px, tailles de contrôle).

**Un seul style de `summary` par rôle** (classes `vf-trace-sec-t` et `vf-trace-sous-t`) :

| Rôle | Où | Style |
|------|----|-------|
| Section | les trois sections de la vue d'ensemble ; « Preuves attachées » | 12,5 px/500 `--text-3`, hauteur 32 px (44 px tactile), compteur `.c` `--text-4`, survol `--text`, marqueur natif conservé, focus `outline: 2px solid var(--ring); outline-offset: 2px`, `margin-bottom: var(--sp-8)` ouvert |
| Sous-repli | un registre de phase déplié dans « Décisions » | 12,5 px/500 `--text-2`, mêmes hauteur, focus et marge, retrait `var(--sp-12)` |

## 14. Ce que le juge de design doit vérifier

1. Aucune valeur en dur de couleur, d'espacement, de rayon : `grep` de la feuille neuve contre § 13, deux thèmes.
2. Formes (§ 1.1) : carré plein, carré vide, carré à deux points, carré à deux barres, octogone au trait à carré central : aucune
   n'existe dans `G_ST` ni dans `GLYPHE` d'Équipe ; chaque corps copié tel quel dans un masque donne la forme décrite (`stroke='black'`
   et `fill` explicites, tracés relus en § 1.1) ; glyphes de 16 px fixes ; silhouettes à plats nets distinctes de l'anneau et du
   disque en niveaux de gris ; détails internes ≥ 2 px et espacés d'au moins 1,5 px ; octogone ≥ 3:1 sur `--elev` clair et sombre.
3. Corail : seulement l'octogone, seulement les cinq causes de la liste fermée ; « non cochée, SUMMARY lu », « sans ligne de
   traçabilité » et « lignes sans exigence » en mot neutre ; « ligne sans exigence » uniquement dans le « Jalon ».
4. Un seul mot de ligne 2 (premier maillon non lu), jamais masqué ; contradictions suivantes en ligne 3 ; emplacement de
   l'octogone dans la bande (SUMMARY ou plan) ; clé des glyphes visible en permanence.
5. Section de phase : 5 lignes (3 sous 700 px), lignes à trou d'abord, « + N autres exigences » ; clamps explicites (bilan 2, clé 3,
   ligne 1 : 2 ou 1, mot 2, mentions : 2 ou 1) ; hauteur ≤ 792 px bureau et ≤ 466 px feuille au pire (§ 2.3) ; repli « Preuves
   attachées » ouvert plafonné à 6 lignes (4 sous 700 px) ; contenu existant du panneau non déplacé ; entrée haute d'une ligne
   qui mène à la section.
6. Nom accessible d'une ligne d'exigence : texte visible contenu dans le nom, puis états des maillons ; niveau dit une seule fois
   hors survol (texte masqué en ligne, texte visible dans le panneau) ; « niveau phase » et « niveau exigence » expliqués.
7. Mémoire : seuls les chemins « cite un chemin absent », relatifs ; jamais `description` ni corps ; trois contradictions
   distinguées par emplacement et mot ; bilan cohérent (hors index compté) ; aucun mot « périmée ».
8. Quatre tailles de texte seulement, **briques réemployées comprises** (surcharges `.btn.soft`, `.vf-ref code`, `.vf-copie-etat`,
   `.vst`, § Typography) ; hauteur unique des boutons de la 76 (32 px, 44 px tactile) ; un style de `summary` par rôle ; chaque nombre
   avec son unité ; chaque glyphe avec son mot.
8bis. Décompte (§ 10.1) : bilans à catégories exclusives dont la somme égale le total ; « chaîne complète » seulement si les quatre
   maillons sont lus ; « non lisible » compté et nommé dans les bilans et le « Jalon » ; un emplacement par cause et par surface
   (§ 10) ; mention neutre du niveau phase ; chips de plan interactifs (focus `--ring`, survol, 44 px tactile).
9. Aucun fil d'Ariane ni bouton Retour propre : un seul Retour par panneau, celui de l'en-tête (`VF_PANNEAU`), `empiler` appelé
   avant `SC.showPanel` ; rôles distincts (Retour, entrée, ligne, pagination) ; phase atteinte par un seul chemin (la ligne
   « Phase » du corps).
10. États de § 9 : chacun dit ce qui le lèverait ; route en échec avec « Réessayer » ; aucun fond teinté ni texte coloré.
11. Clavier : tout parcourable sans souris, Échap (Retour commun puis fermeture), aucune touche globale prise, focus visible,
    cibles 44 px tactiles ; 1440, 1024, 390 px sans poussée de la carte ni défilement horizontal.
12. Anti-slop : monochrome, aucune couleur de marque ni dégradé, aucune police neuve, aucun tiret cadratin dans le copy, copy
    entièrement français (le garde d'inventaire du français du cockpit ne doit trouver aucune fuite).

## 15. Points à revalider à l'exécution

- Chemin réel des contrats de la 79 (A10 à A13) et de la 80 (P80-C76-1 à 4) : l'API `SC` présente sert de base.
- Nom et contrat de `window.VF_PANNEAU.retour()` / `empiler({ titre, rouvrir })` et de `window.VF_SURCOUCHES` (P80-C76-3, P80-C76-5) ;
  présence du Retour au-dessus d'un panneau posé par `SC.showPanel`, sens de `titre` (§ 0) ; comportement d'Échap (§ 8).
- Initialisation par `VF_COQUILLE.surOnglet(rappel)` et nettoyage en quittant Projet (règle A30 de la 79, § 0) ; pile vidée au
  changement d'onglet.
- Crochet de sélection d'un commit par son sha dans le tiroir Git de la 78 (§ 5.5).
- Que `[data-vf-section]` (§ 2.1) reste actif après la 79 et la 80 (gestionnaire de `00-vibeflow.js`) ; sinon, l'entrée haute
  porte son propre `scrollIntoView`.
- Numéro du ou des fichiers `ui/7x-vf-trace*.js` et poids de chaque fichier (≤ 300 lignes, gate V4).
- Que la carte de phase en couloirs de la 80 ouvre le même panneau, section « Traçabilité » comprise (P80-C76-1).
- Que les clamps de § 2.3 tiennent au rendu à 320 et 294 px (largeurs utiles), et que le plafond de la feuille reste `min(56vh, 480px)`.
- Hauteur réelle de la section de phase à 1440 et 390 px (mesure au rendu : ≤ 792 px et ≤ 466 px annoncés, § 2.3, repli fermé ; ≤ 1 148 px et ≤ 694 px repli ouvert).

## UI Considerations

> Rempli par la sonde de considérations d'UI du flux ui-phase (étape 9.5) ; lignes remplacées, jamais ajoutées. La couverture
> d'états de cette phase est décrite aux § 2.2, § 7 et § 9 ; le copy y est référencé, pas dupliqué.

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
