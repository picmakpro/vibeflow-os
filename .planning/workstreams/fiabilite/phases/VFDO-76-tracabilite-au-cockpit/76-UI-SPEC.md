---
phase: "76"
slug: "tracabilite-au-cockpit"
status: approved
shadcn_initialized: false
preset: none
created: "2026-11-11"
---

# Phase 76 : Traçabilité au cockpit — UI-SPEC

**Contrat de design** pour l'entrée et la section « Traçabilité » du panneau d'une phase, les trois sections repliées de la
vue d'ensemble de Projet (« Jalon », « Décisions », « Mémoire des agents ») et les panneaux d'une exigence, d'une ADR,
d'une décision et d'une entrée de mémoire. Direction « Graphite » (`DESIGN.md`). Révisions du 2026-11-11 sur les critiques
des tours 1 à 4 : glyphes de forme propre, corail borné par P76-D-15bis, section de phase bornée en hauteur (budget sommé),
bilans qui ne perdent aucune catégorie, nom accessible, mémoire réduite aux chemins absents, exigence qui ouvre ses décisions
et ses preuves (P76-D-38), puis tour 5 : gabarits fermés (aucune ligne ne liste un nombre libre d'états), budget
recalculé sur le pire cas à la largeur utile plancher de 248 px (tour 6 : barre de défilement de 12 px comptée).

Sources lues : `76-CONTEXT.md` (P76-D-01..38, dont P76-D-15bis, P76-D-30, P76-D-32, P76-D-33, P76-D-38 ; Retour et pile commune de la Phase 80, règle A30 de la 79), `REQUIREMENTS.md`
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
  P71.5-D-12, D-19, D-21, D-27, D-28). Le corail ne désigne que la liste fermée de P76-D-04 / P76-D-15bis (§ 10), confirmée par Samuel (P76-D-32). Grille
  d'espacements fermée (P71.5-D-01). Points de rupture inchangés (Q11).
- Rien de la mémoire des agents au-delà de `name`, agent, `metadata.type`, jour du dernier commit, nombres de liens
  entrants et sortants, chemins cités absents, et le chemin du fichier de mémoire suivi (nécessaire au verdict « hors index »,
  montré en pied de source seulement) (P76-D-20, P76-D-22). Aucun titre ni résumé écrit par un modèle (PU-G-162).
- **Pas de fil d'Ariane, pas de Retour propre** (P76-D-03, P76-D-30). Un seul Retour par panneau : le bouton « Retour : <titre
  du dessus> » de l'en-tête du panneau, pile commune de la Phase 80 (`window.VF_PANNEAU.retour()`, P80-C76-3).
  **Règle d'empilement, une seule phrase : le panneau quitté est empilé exactement une fois, par la pile commune quand le départ
  passe par `select`/`reveal` d'un nœud (phase, plan), par la 76 dans tous les autres cas, c'est-à-dire quand elle quitte un
  panneau sur mesure (exigence, ADR, décision, entrée de mémoire, liste) et quand elle quitte un nœud par `SC.showPanel` (phase vers
  exigence, phase vers liste) : la 76 appelle alors `window.VF_PANNEAU.empiler({ titre, rouvrir })` (P80-C76-5) juste avant
  d'ouvrir le voisin.** `titre` est une donnée du lab, rendue en texte, jamais en HTML, **bornée à 40 caractères par la 76 avant
  l'appel** (« … » en fin ; le texte entier est dans le panneau) ; `rouvrir` rend de nouveau le panneau quitté. Un Retour ramène
  toujours au panneau quitté en une pression. La pile est vidée au changement d'onglet. **À revalider avec la 80** : que le bouton
  de l'en-tête reste présent au-dessus d'un panneau posé par `SC.showPanel` ; que le départ d'un nœud par `SC.showPanel` n'est pas
  vu par la pile commune (d'où l'appel de la 76) et n'est donc pas empilé deux fois ; le sens exact de `titre` ; le clamp du
  bouton côté 80 (§ 15). Sinon, point à rouvrir avec la 80, jamais un bouton « Retour » propre à la 76.
- **Gabarits fermés** (règle de classe, § 2.4) : aucune ligne de liste, aucun bilan, aucun résumé n'énumère un nombre libre
  d'états. Chaque ligne est un gabarit à emplacements fermés, dans un ordre fixe, aux nombres plafonnés à 4 chiffres
  (« 9 999+ ») ; la longueur au pire se calcule sur le gabarit rempli, pas sur une donnée observée. L'énumération détaillée vit
  dans le panneau ouvert d'un geste.
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

**Glyphes de 16 px fixes** : `width: 16px; height: 16px` sur `.vf-trace-g`, jamais `1.45em` ; **chaque paire glyphe et mot** (bande, légende, état d'un lien, état de la section « État », glyphe d'une ligne de § 2.2, § 4, § 5.1, § 5.4, § 6) est un `display: inline-flex; align-items: flex-start; gap: var(--sp-4)` : le glyphe de 16 px tient dans la ligne de 16 ou 18 px et **la hauteur de ligne est conservée** ; ils ne suivent ni la police ni
le zoom d'éloignement.

**Alignement d'une paire dont le mot passe sur deux lignes** (règle de classe, tour de craft du 2026-11-13) : le glyphe se cale sur la
**première ligne** du mot, jamais au centre du bloc (un `align-items: center` le ferait flotter entre deux lignes). Le glyphe est
`flex: none`, le mot est dans un `span` `min-width: 0` qui porte son clamp ; le glyphe prend `margin-top: 0` devant un mot de 16 px de
ligne (11,5 px) et `margin-top: calc(var(--sp-2) / 2) /* optique : centre 16 px sur une ligne de 18 px */` devant un mot de 18 px de
ligne (12,5 px). Les paires de la **légende** (§ 2.2) sont des atomes : `white-space: nowrap`, jamais coupées entre le glyphe et le
mot, elles passent à la ligne d'un bloc. Sur la ligne 2 d'une exigence, la bande de quatre glyphes se cale aussi en haut
(`align-items: flex-start`) : son mot de deux lignes la voit sur sa première ligne. Masque : patron `GLYPHE(...)` de `00-vibeflow.js` (viewBox 16), teinté par `--c-st`. Chaque corps
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
trait corail, non plein, sans « ! », détail interne de 5 px. Les trous en rouge : arbitrage rendu, P76-D-32 (§ 12).

### 1.2 Niveau d'un maillon : ce que veulent dire « niveau exigence » et « niveau phase »

Seul un maillon « lu » a un niveau (P76-D-14).
- **Niveau exigence** : le champ ou le fichier lu cite l'identifiant de cette exigence : `requirements:` d'un plan,
  `requirements:` ou `requirements-completed:` d'un SUMMARY, ligne de la table de couverture d'une VERIFICATION, mention
  dans le fichier de recette. Plan et SUMMARY lus sont toujours de niveau exigence.
- **Niveau phase** : le fichier existe pour la phase mais ne cite pas l'identifiant ; il dit que la phase a une VERIFICATION
  ou une recette, pas qu'elle couvre cette exigence. Seuls VERIFICATION et recette peuvent être de niveau phase.

**Une seule source du niveau par surface** (règle de classe, toutes les surfaces balayées) :
- **Ligne de liste** (§ 2.2) : le **nom accessible complet** (texte visible, puis texte masqué `.vf-trace-sr`) dit le niveau d'un
  maillon lu **une seule fois**, jamais repris dans « Mentions ». Le texte masqué est la source par défaut (un « lu, niveau … » par
  maillon lu). La mention visible « lu au niveau phase : VERIFICATION, recette » **n'est visible en ligne que si elle est la première
  mention** (priorité c, soit seulement quand la ligne n'a ni contradiction ni mention neutre) ; sinon elle compte dans « et N autres
  mentions » et le niveau se lit dans « Chaîne ». **Quand elle est visible, son texte fait partie du nom (contenu natif du bouton)
  et porte le niveau des maillons qu'elle nomme : le texte masqué écrit alors ces maillons sans niveau** (« VERIFICATION : lu. »,
  jamais « VERIFICATION : lu, niveau phase. » en plus), et garde le niveau des autres maillons lus.
- **Panneau d'une exigence** (§ 5.1) : la ligne du maillon dans « Chaîne » **seulement**. Ni « Preuves » (sa ligne 2 ne porte que le
  statut), ni « Mentions », ni l'aide ne le répètent.
- **Panneaux de liste et de preuve** (§ 6), **bilans, « Jalon », légende** : aucun niveau.
Jamais un `title`, jamais un `aria-label` de glyphe (les glyphes sont `aria-hidden`).

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
sortants » ; chemin absent vit sur la ligne du chemin, dans « Chemins cités et absents de HEAD ». Un seul octogone par ligne, les causes se disent
en mots.

## 2. Panneau d'une phase : l'entrée haute et la section « Traçabilité »

Deux rappels `SC.addPanelSection('item', fn)` ; ils ne répondent que si `cible` est un identifiant de phase (`ph-<N>` ou
`ph-<N>@<ws>`, P80-C76-1), sinon `''`. La section ne remplace ni ne déplace rien : le contenu existant du panneau garde son
ordre et sa place. **Décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée** : section en
fin de panneau, pointée par une entrée d'une ligne en haut, plutôt qu'une section haute qui repousse le contenu existant.

### 2.1 Entrée haute (`{ top: true }`)

Un `.sec` contenant un seul `button.vf-trace-ligne` avec `data-vf-section="vf-trace-phase"` (clic, Entrée, Espace : le panneau
défile jusqu'à la section, brique existante). Ligne 1 : « Traçabilité » (12,5 px/500 `--text`). Ligne 2 : **gabarit fermé à trois
emplacements** (12,5 px/400 `--text-3`, clamp 2 lignes) : « 4 exigences, 3 incomplètes dont 1 en contradiction » ; toutes complètes : « 4 exigences, toutes
complètes ». « Incomplète » = toute exigence qui n'est pas « complète » (§ 10.1). Au plafond : « 9 999+ exigences, 9 999+ incomplètes dont 9 999+ en contradiction » :
2 (2) lignes à 248 px (308 px). Hauteur au pire : `.sec` 40 + bouton (remplissage 16 + ligne 1 de 18 + écart 2 + ligne 2
de 2 × 18 = 36) 72 = **112 px**. Rendue seulement si la phase a au moins une exigence rattachée. Nom accessible : « Traçabilité,
4 exigences, 3 incomplètes dont 1 en contradiction. Aller à la section. »

### 2.2 Section `id="vf-trace-phase"` (position par défaut, en fin de panneau)

Contenu chargé à l'ouverture du panneau par `GET /api/vf/tracabilite?vue=phase&cle=<N>` ; le rendu synchrone livre le titre
et l'état de chargement (§ 9), l'asynchrone remplit en place (`[data-ext]` rebindé, jamais un `rerender()` de la carte).

**Structure (de haut en bas).**
1. `h3` « Traçabilité » et compteur `.c` : « 4 exigences ».
2. **Bilan, gabarit fermé à quatre emplacements** (12,5 px/400 `--text-3`, clamp 3 lignes), les quatre toujours écrits,
   zéros compris, dans cet ordre : « Par exigence : 1 en contradiction · 1 avec un manque · 0 non lisible · 2 complètes » ;
   toutes complètes : « Par exigence : toutes complètes ». Catégories exclusives (§ 10.1) ; singulier pour 0 et 1 ; jamais un
   pourcentage (P69-D-01).
3. **Légende des glyphes** (11,5 px/400 `--text-3`, clamp 4 lignes, une seule fois par section, visible en permanence,
   jamais au survol) : « Légende : » puis quatre paires glyphe et mot (« lu », « manque », « non lisible », « contradiction »),
   puis « Colonnes : plan, SUMMARY, VERIFICATION, recette. » : c'est ce qui rend les colonnes de la bande identifiables sans
   survol. **La légende est la seule exception à « l'octogone ne marque qu'une contradiction lue » : ses quatre glyphes sont
   rendus en teinte neutre `--text-3`**, car elle montre des formes, pas des états (le corail n'y est jamais posé).
4. Au plus **5 lignes d'exigence** (**3 sous 700 px**), puis « + N autres exigences » (§ 7). Ordre : d'abord les lignes à
   contradiction, puis à manque, puis à maillon non lisible, puis les complètes ; à égalité, l'ordre du registre.
5. Repli « Preuves attachées » (§ 3), fermé par défaut, plafonné ouvert.

**Ligne d'exigence** : un seul `button type="button"`, classe `vf-trace-ligne`, pleine largeur, `margin-inline: calc(-1 *
var(--sp-12))`, `padding: var(--inset-row)`, rayon `var(--r-ctl)`, sur le fond du panneau (jamais sur `--raise`). Trois lignes,
**chacune de longueur bornée par construction** ; clamps explicites : § 2.3.
- **Ligne 1** : identifiant en `--mono` 11,5 px/500 `--text-2` (« TRAC-01 », jamais tronqué), puis le texte de l'exigence en
  12,5 px/400 `--text`, `overflow-wrap: anywhere` : donnée du lab, la seule coupée par un clamp, lisible en entier ailleurs
  (§ 2.4).
- **Ligne 2** : la bande (quatre glyphes de 16 px fixes, `gap: var(--sp-4)`, dans l'ordre plan, SUMMARY, VERIFICATION,
  recette) puis, après `var(--sp-8)`, **un seul mot du lexique fermé : le premier maillon qui n'est pas « lu », dans l'ordre de la
  bande**, jamais masqué par un autre : « manque : plan », « manque : SUMMARY », « manque : VERIFICATION », « manque : recette » ;
  « non lisible : plan », « non lisible : SUMMARY », « non lisible : VERIFICATION », « non lisible : recette » ; « contradiction :
  cochée, sans SUMMARY » (maillon SUMMARY) ; « contradiction : Complete, sans plan » (maillon plan). **« chaîne complète »
  seulement si les quatre maillons sont « lu »** (niveau exigence ou niveau phase). Mot en 11,5 px/500 `--text-2`, clamp 2
  lignes (pire mot : 2 (1) lignes, sur 164 px (224 px) de large après la bande).
- **Ligne 3** (absente si aucune mention ; clamp 2 lignes) : **une seule mention, la première par priorité, puis un compte** :
  « <mention> · et N autres mentions » (N de 1 à 3 ; « et 1 autre mention » au singulier ; pas de suffixe s'il n'y en a qu'une).
  Priorité : (a) une contradiction de la liste fermée qui n'est pas le mot de la ligne 2, précédée de l'octogone ; (b) une
  mention neutre, sans glyphe : « non cochée, SUMMARY lu » ou « sans ligne de traçabilité » (P76-D-15bis) ; (c) le niveau, sans
  glyphe : « lu au niveau phase : VERIFICATION, recette » (au plus deux maillons, ensemble fermé), **visible seulement quand il est la
  première mention** (ni (a) ni (b)) ; sinon il compte dans « et N autres mentions » (§ 1.2). Une exigence a au plus quatre
  mentions sur cette ligne (une contradiction, deux neutres, un niveau). **Toutes sont lisibles en entier** dans « Mentions » et
  « Chaîne » du panneau de l'exigence et dans le texte masqué de la ligne.
- **Emplacement des contradictions dans la bande** : « cochée, sans SUMMARY » met l'octogone à la place du maillon SUMMARY ;
  « Complete, sans plan » à la place du maillon plan. Un seul sens par emplacement.
- **Nom accessible** (le contenu natif du bouton, sans `aria-label` qui le remplace, pour que le texte visible soit contenu
  dans le nom) : le texte visible (identifiant, texte, mot, mention et compte), **entier dans le DOM même quand un clamp le coupe
  à l'écran**, puis un `span.vf-trace-sr` masqué visuellement (position absolue, 1 px, `overflow: hidden`, `clip-path:
  inset(50%)` ; exception écrite de taille) qui énumère tout : « Plan : lu, niveau exigence. SUMMARY : manque. VERIFICATION : lu,
  niveau phase. Recette : manque. Mentions : non cochée, SUMMARY lu ; sans ligne de traçabilité. Ouvrir l'exigence. » (le niveau n'est
  dit qu'au maillon, jamais repris dans « Mentions » : § 1.2). **Cas de la mention de niveau visible** (première mention, § 1.2) : le
  texte visible « lu au niveau phase : VERIFICATION, recette » dit le niveau de ces deux maillons ; le texte masqué ne le redit pas :
  « Plan : lu, niveau exigence. SUMMARY : lu, niveau exigence. VERIFICATION : lu. Recette : lu. Ouvrir l'exigence. » Le nom complet dit
  ainsi chaque niveau une fois. Glyphes `aria-hidden`.
- États : repos fond transparent ; survol `rgba(var(--ink), .06)` ; focus clavier `outline: 2px solid var(--ring);
  outline-offset: -2px` ; actif sans échelle. Un glyphe de contradiction n'est jamais posé sur `--raise` ni `--raise-2`
  (thème clair, sous 3:1).
- Clic, Entrée, Espace : ouvre le panneau de l'exigence (§ 5.1) après avoir empilé le panneau de la phase (départ d'un nœud par `SC.showPanel`, § 0 ; titre « Phase 76 ») ; focus sur son titre si l'activation vient du clavier.

**Aucune exigence rattachée** : sous le `h3` (compteur « 0 exigence »), la ligne neutre de § 9 ; le repli « Preuves attachées »
reste montré s'il y a des preuves.

### 2.3 Budget de hauteur de la section (bornée par des clamps, sommée exactement)

Chaque bloc de texte porte un `-webkit-line-clamp` explicite, dimensionné sur le **pire cas autorisé par le contrat de copy**
(gabarit rempli aux plafonds, § 2.4) à la **largeur utile plancher réelle de 248 px**. Largeur utile = largeur du panneau − 12 px de
barre de défilement (`#panel::-webkit-scrollbar { width: 12px }`, `viewer.html` l. 361) − 2 × 20 px de remplissage de `.sec`. Le moteur
borne `--panel-w` à 300 px au moins (`setPanelWidth`, `clamp(…, 300, …)`, `viewer.html` l. 2378) : **300 − 12 − 40 = 248 px** au
plancher, **360 − 52 = 308 px** par défaut, 252 px sur la feuille à 320 px de large (panneau de 304 px), 322 px à 390 px de large.
Lignes de 12,5 px à 18 px, de 11,5 px à 16 px. Remplissage de `.sec` : 20 en haut (`--inset-panel`), 20 en bas (`.sec:last-child`).

| Bloc | Bureau (≥ 701 px) | Feuille (≤ 700 px) |
|------|-------------------|--------------------|
| `.sec`, remplissage haut + bas | 20 + 20 = 40 | 40 |
| `h3` (ligne de 18) + marge basse `--sp-8` | 18 + 8 = 26 | 26 |
| Bilan (clamp 3 × 18) + écart `--sp-8` | 54 + 8 = 62 | 62 |
| Légende (clamp 4 × 16) + écart `--sp-8` | 64 + 8 = 72 | 72 |
| Ligne d'exigence : remplissage 8 + 8, deux écarts `--sp-2` | 16 + 4 = 20 | 20 |
| – ligne 1 (clamp 2 × 18 ; 1 × 18 sur la feuille) | 36 | 18 |
| – ligne 2 (max de la bande 16 et du mot, clamp 2 × 16) | 32 | 32 |
| – ligne 3 (mention et compte, clamp 2 × 16) | 32 | 32 |
| **Une ligne d'exigence, au pire** | 20 + 36 + 32 + 32 = **120** | 20 + 18 + 32 + 32 = **102** |
| Lignes montrées | 5 | 3 |
| Écarts entre lignes (`--sp-2`) | 4 × 2 = 8 | 2 × 2 = 4 |
| Sous-total des lignes | 5 × 120 + 8 = 608 | 3 × 102 + 4 = 310 |
| Écart `--sp-8` + « + N autres exigences » (`height: 32px` ; 44 px tactile) | 8 + 32 = 40 | 8 + 44 = 52 |
| Écart `--sp-8` + `summary` du repli fermé (32 ; 44 tactile) | 8 + 32 = 40 | 8 + 44 = 52 |
| **Section, repli fermé** | 40 + 26 + 62 + 72 + 608 + 40 + 40 = **888** | 40 + 26 + 62 + 72 + 310 + 52 + 52 = **614** |

Variante tactile sur un grand écran (`pointer: coarse` au-dessus de 700 px) : « + N autres » et `summary` passent à 44 px, soit
+ 12 + 12 : **912**. Les lignes d'exigence dépassent déjà 44 px, rien à ajouter.

**Sur la feuille, la section défile avec la feuille** : ses 614 px sont une **borne, pas une garantie de tenir dans la feuille**
(`min(56vh, 480px)`, 480 px au plus). Le contenu existant du panneau précède la section et reste atteignable sans la traverser ;
l'entrée haute (≤ 112 px, § 2.1) y mène.

**Repli « Preuves attachées » ouvert, plafonné** : 6 lignes de preuve (4 sous 700 px). **Hauteur réelle du chemin `.vf-ref`** : le
chemin est un `.vf-ref` (§ Typography : `display: flex`, `padding: var(--inset-row)`, `min-height: 32px`, **44 px sous 700 px ou
`pointer: coarse`**) ; ses 16 px de remplissage et son `code` clampé à 1 ligne de 16 donnent 32, soit exactement le plancher, et 44
quand la cible tactile s'applique. La ligne de preuve ne porte donc de remplissage qu'en haut : `padding: var(--sp-8) 0 0` ; le
libellé et le statut (une seule ligne de 18) gardent `padding-inline: var(--sp-12)` pour s'aligner sur le chemin. Une ligne =
8 + 18 + écart 2 + `.vf-ref` 32 = **60** au bureau à la souris, 8 + 18 + 2 + 44 = **72** sur la feuille ou en tactile. Bureau : 8 (marge
sous `summary`) + 6 × 60 + 5 × 2 (= 370) + 8 + 32 (« + N autres fichiers de preuve ») = **418** ; feuille : 8 + 4 × 72 + 3 × 2 (= 294)
+ 8 + 44 = **354**. Le repli ne contient **que des fichiers de preuve** : les critères d'un plan n'y figurent pas (§ 3, § 6).
Section ouverte au pire : **1 306** (888 + 418) bureau, **968** (614 + 354) feuille, bornes et non garanties ; **1 414** (912 + 502,
avec 502 = 8 + 6 × 72 + 5 × 2 + 8 + 44) en tactile au-dessus de 700 px.

**Lignes des autres listes, au pire** (hors budget de la section, qui est repliée ou dans un panneau de liste) : ligne du « Jalon »
155 px (remplissage 16 + écarts 6 + **ligne 1 de 21**, la pastille `.vst` faisant 20,7 px de haut, + ligne 2 de 48 + ligne 3 de 32 + ligne 4 de 32) ; ligne d'agent
102 px ; ligne d'entrée de mémoire 120 px ; pagination 72 px (84 px tactile) ; puces de plan 46 px (94 px tactile).

### 2.4 Gabarits fermés : le pire cas calculé, et où lire le détail

**Règle de classe (tour 5, décision du manager : décision déléguée par Samuel (message session principale, 2026-11-08), option
recommandée).** Aucune ligne de liste, aucun bilan, aucun résumé ne liste « les états qui existent » en nombre libre. Chacun est un
**gabarit fermé** : un ensemble fermé d'emplacements, dans un ordre fixe ; chaque emplacement est un nombre et un mot du lexique, ou
un mot du lexique ; les nombres sont plafonnés à 4 chiffres (« 9 999+ » au-delà ; le nombre exact est dans le compteur du panneau
ouvert) ; le seul texte libre est une donnée du lab (texte d'exigence, titre, nom), clampée à 1 ou 2 lignes et lisible en entier
ailleurs. Un emplacement nul s'écrit dans un bilan (gabarit constant) et s'omet dans une ligne de liste (gabarit réduit) ; **dans
les deux cas le pire cas est le gabarit entièrement rempli aux plafonds**, pas une valeur observée. Aucune catégorie n'est retranchée
sous un clamp : le clamp est choisi pour que le pire cas **tienne avec une réserve**, et un libellé qui ne tient pas se raccourcit
(jamais le clamp ne se relève sans recalculer § 2.3). Pluriel : singulier pour 0 et 1 (« 0 non lisible », « 1 complète »).

Mesure : simulation d'un retour à la ligne glouton, avec des largeurs de caractère prudentes (Inter : 6,5 px minuscule, 8,3 px
capitale, 7,5 px chiffre à 12,5 px ; 0,92 de ces valeurs à 11,5 px ; espace 3,4 px ; majorées de 4 %), calculée par script sur les
gabarits ci-dessous aux largeurs utiles de **248 px** (plancher) et **308 px** (défaut) ; **clamp = lignes simulées à 248 px, + 1 si la
dernière ligne remplit plus de 85 % de la largeur** (réserve de 15 %, au-delà des 8 % demandés). **À mesurer au rendu** (§ 15).

| Gabarit | Pire cas (plafonds) | Caractères | Lignes à 248 px (308 px) | Dernière ligne à 248 px | Clamp |
|---------|---------------------|-----------|--------------------------|-------------------------|-------|
| Résumé de l'entrée haute (12,5 px) | « 9 999+ exigences, 9 999+ incomplètes dont 9 999+ en contradiction » | 65 | 2 (2) | 67 % | 2 |
| Bilan d'une phase (12,5 px) | « Par exigence : 9 999+ en contradiction · 9 999+ avec un manque · 9 999+ non lisibles · 9 999+ complètes » | 103 | 3 (2) | 64 % | 3 |
| Bilan du « Jalon » (12,5 px) | « Par phase : 9 999+ en contradiction · 9 999+ avec un manque · 9 999+ non lisibles · 9 999+ sans exigence · 9 999+ complètes » | 123 | 4 (3) | 24 % | 4 |
| Bilan « Décisions » (12,5 px) | « 9 999+ ADR · 9 999+ décisions · 9 999+ registres de phase » | 57 | 2 (2) | 45 % | 2 |
| Bilan « Mémoire » (12,5 px) | « 9 999+ entrées · 9 999+ agents · 9 999+ entrées hors index · 9 999+ liens cassés · 9 999+ chemins cités absents · 9 999+ entrées sans lien entrant » | 146 | 4 (3) | 59 % | 4 |
| Légende des glyphes (11,5 px, quatre glyphes de 16 px) | « Légende : lu · manque · non lisible · contradiction. Colonnes : plan, SUMMARY, VERIFICATION, recette. » | 4 paires + phrase | 4 (3) | 59 % | 4 |
| Ligne 2 d'une phase du « Jalon » (11,5 px) | « Maillons non lus : plan 9 999+ · SUMMARY 9 999+ · VERIFICATION 9 999+ · recette 9 999+ » | 86 | 3 (2) | 15 % | 3 |
| Ligne 3 d'une phase du « Jalon » (11,5 px, avec l'octogone) | « 9 999+ en contradiction · 9 999+ avec un manque · 9 999+ non lisibles » | 69 | 2 (2) | 62 % | 2 |
| Ligne 4 d'une phase du « Jalon » (11,5 px) | « 9 999+ lignes de traçabilité sans exigence » | 42 | 1 (1) | 92 % | 2 |
| Mot de ligne 2 d'une exigence (11,5 px ; 164 px puis 224 px après la bande) | « contradiction : cochée, sans SUMMARY » | 36 | 2 (1) | 34 % | 2 |
| Ligne 3 d'une exigence, mention et compte (11,5 px, avec l'octogone) | « contradiction : cochée, sans SUMMARY · et 3 autres mentions » | 59 | 2 (2) | 45 % | 2 |
| Ligne 3 d'une exigence, niveau seul (11,5 px) | « lu au niveau phase : VERIFICATION, recette » | 42 | 2 (1) | 16 % | 2 |
| Ligne 2 d'un agent (11,5 px, avec l'octogone) | « 9 999+ entrées hors index · 9 999+ liens cassés · 9 999+ chemins cités absents » | 78 | 2 (2) | 83 % | 2 |
| Ligne 3 d'un agent (11,5 px) | « 9 999+ entrées sans lien entrant · 9 999+ liens résolus par nom de fichier » | 74 | 2 (2) | 70 % | 2 |
| Ligne 2 d'une entrée de mémoire (11,5 px) | « modifiée le 28 sept. 2026 · 9 999+ liens entrants · 9 999+ liens sortants » | 73 | 2 (2) | 69 % | 2 |
| Ligne 3 d'une entrée de mémoire (11,5 px, avec l'octogone) | « hors index · 9 999+ liens cassés · 9 999+ chemins cités absents · sans lien entrant » | 83 | 2 (2) | 89 % | 3 |
| Message « Lecture bornée » (11,5 px) | « Lecture bornée : la liste peut être incomplète. Une lecture plus courte, ou moins de commits, la lèverait. » | 106 | 3 (3) | 70 % | 3 |
| Compte de pagination (11,5 px) | « 9 999+ à 9 999+ sur 9 999+ fichiers de preuve » | 45 | 2 (1) | 15 % | 2 |

**Autres éléments à longueur variable : une règle écrite chacun** (tour 6, classe « tout élément à longueur variable ») :

| Élément | Règle fermée | Pire cas calculé |
|---------|--------------|------------------|
| Pagination (§ 6) | **toujours deux lignes**, à toute largeur : ligne 1, le compte « N à M sur T <unité> » (11,5 px/400 `--text-3`, clamp 2), ligne 2, les deux boutons côte à côte (`flex: 1 1 0`, `gap: var(--sp-8)`, `white-space: nowrap`, 32 px ; 44 px tactile) ; **écart déclaré entre les deux lignes : `row-gap: var(--sp-8)`** (nav en `display: flex; flex-direction: column`), et **8 px au-dessus** de la nav (`margin-top: var(--sp-8)`, hors des 72 px) | 72 px = 32 + 8 + 32 (84 px tactile = 32 + 8 + 44) ; boutons « Précédentes » et « Suivantes » sur une ligne à 248 px |
| « + N autres <sorte> » | `white-space: nowrap`, `overflow: hidden`, `text-overflow: ellipsis`, `title` = libellé entier ; N plafonné à « 9 999+ » ; sorte du lexique fermé (exigences, ADR, registres, commits, agents, liens, décisions, phases, fichiers de preuve, critères, entrées, plans) | libellé le plus large : « + 9 999+ autres fichiers de preuve » = 201 px pour 224 px de largeur interne au plancher (248 − 2 × 12) : tient sans ellipsis |
| Puces de plan du panneau d'exigence (§ 5.1) | **au plus 3 puces** `.tag`, puis une 4e puce « + N » (N plafonné à « 9 999+ ») qui ouvre le panneau de liste « Plans de l'exigence <identifiant> » (§ 6) ; `flex-wrap: wrap`, `gap: var(--sp-6)` ; identifiant de plan d'une ligne, `max-width: 100%`, ellipsis, `title` | 2 rangées au plus (puce la plus large simulée : 89 px) : 46 px (94 px tactile) |
| Titre passé à `empiler` (§ 0) | borné à 40 caractères par la 76, « … » en fin ; texte entier dans le panneau ; clamp du bouton de la 80 à valider (§ 15) | 40 caractères au plus |
| Toute autre donnée du lab (nom d'agent ou d'entrée, type de mémoire, titre d'ADR ou de décision, nom de phase, statut, chemin) | une ligne, `min-width: 0`, `overflow: hidden`, `text-overflow: ellipsis`, `title` = valeur entière ; aucune autre largeur libre | une ligne |

**Ce qui est coupé à l'écran reste lisible en entier ailleurs** (le texte complet reste dans le DOM, donc dans le nom accessible) :

| Texte coupé ou résumé | Où le lire en entier |
|-----------------------|----------------------|
| Texte d'une exigence en ligne 1 (clamp 2, 1 sur la feuille) | panneau de l'exigence (`.pd`, entier) et nom accessible de la ligne |
| Mentions d'une exigence au-delà de la première (« et N autres mentions ») | « Mentions » et « Chaîne » du panneau de l'exigence ; texte masqué de la ligne |
| Détail des trous d'une phase du « Jalon » (comptes par maillon et par catégorie) | section « Traçabilité » du panneau de la phase : bilan et lignes triées, une par exigence |
| Détail d'un agent (comptes par état) | panneau de liste de l'agent : une ligne par entrée, avec ses états (§ 6) |
| Nombre plafonné « 9 999+ » | compteur `.c` du panneau ouvert (nombre exact servi par la route) |
| Titre d'ADR (une ligne, ellipsis) | `title` de la ligne, panneau de l'ADR (`.pd`) |
| Titre de décision (coupé à 80 caractères par la route, « … » ajouté par la route) | pied de source du panneau de la décision, qui dit la coupe et où lire la définition entière (§ 5.3) |
| Nom de phase du « Jalon » (une ligne, ellipsis) | `title`, panneau de la phase |
| Nom d'agent (mono, une ligne, ellipsis) | `title`, titre du panneau de liste de l'agent |
| Titre empilé (40 caractères) | titre du panneau quitté, lu en entier à sa réouverture |
| Chemin d'une preuve (clamp 1) | `title` et copie du chemin **entier** au clic (`.vf-ref`) |
| Statut d'une preuve (une ligne, ellipsis) | `title`, panneau de liste « Preuves de la Phase N » |

## 3. Preuves attachées (AUDC-I33)

Repli natif `<details class="vf-trace-repli">` dans la section de la phase, fermé par défaut ; son `<summary>` est de **rôle
« section »** (§ 13, style unique) : « Preuves attachées » et compteur `.c` « 5 fichiers ». **Plafonné ouvert** (§ 2.3) : 6 lignes
de preuve (4 sous 700 px), puis « + N autres fichiers de preuve » (§ 7) qui ouvre le panneau de liste « Preuves de la Phase N »
(§ 6). **Le repli ne contient que des fichiers de preuve** ; les critères `must_haves` d'un plan n'y figurent pas (compte et liste
dans le panneau de liste, § 6), de sorte que le plafond de 6 lignes borne tout le repli.

Contenu, **sans intertitre** (la portée se dit dans la ligne) : d'abord les preuves de la phase, puis celles de chaque plan :
- ligne 1 de chaque preuve, **une seule ligne** : la portée puis le libellé (12,5 px/500 `--text`, sans retour à la ligne) :
  « Phase · VERIFICATION », « Phase · Recette », « 76-01 · Trace rouge », parmi « VERIFICATION », « Recette », « Trace rouge »,
  « Sécurité », « Validation » ; à droite, le statut lu (11,5 px/400 `--text-3`, mot du frontmatter ou de la ligne `**Statut :`,
  `textContent`, une ligne, ellipsis, `title` = statut entier) : « statut : passed » ;
- dessous, le chemin relatif au lab en `--mono` 11,5 px/400 `--text-3`, **clampé à 1 ligne** (ellipsis, `title` = chemin complet),
  rendu en `.vf-ref` : un clic copie le chemin **entier**, « Copié » apparaît 1,6 s (comportement existant). Le cockpit ne peut
  pas ouvrir un fichier : le chemin est copiable, pas ouvrable. `aria-label` : « Copier le chemin : <chemin> ».
- Jamais un contenu de transcript, jamais une capture, jamais une preuve déduite (P76-D-24) ; le contenu d'un fichier de preuve
  n'est jamais rendu (P76-D-38). Un fichier absent ne produit aucune ligne : son absence se lit dans le glyphe « manque » de la
  bande.
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

Bilan sous le `summary` (12,5 px/400 `--text-3`, **clamp 4 lignes**, section repliée par défaut donc hors budget § 2.3), **gabarit fermé à cinq
emplacements**, zéros écrits, catégories **exclusives par phase** (§ 10.1) : « Par phase : 2 en contradiction · 7 avec un manque
· 1 non lisible · 1 sans exigence · 1 complète » ; toutes complètes : « Par phase : toutes complètes ». Pire cas : § 2.4. Une ligne
par phase (`button.vf-trace-ligne`), ≤ 30 puis « + N autres phases ». **Chaque ligne est un gabarit fermé de quatre lignes
au plus** :
- Ligne 1 (21 px de haut) : « Phase 76 » (12,5 px/500 `--text`), le nom (12,5 px/400 `--text-3`, une ligne, ellipsis), pastille de phase `.vst` à
  droite (glyphe et mot : « À faire », « En cours », « À recetter », « Fait »), `font-size` surchargé à 11,5 px (§ Typography).
- Ligne 2 (11,5 px/500 `--text-2`, **clamp 3 lignes**) : **bande fixe de quatre compteurs, un par maillon**, toujours les quatre, dans l'ordre
  du tableau de la phase : « Maillons non lus : plan 0 · SUMMARY 2 · VERIFICATION 1 · recette 3 ». Un compteur compte les
  exigences dont ce maillon n'est pas « lu » (manque, non lisible ou contradiction) ; les compteurs comptent des maillons et se
  recouvrent entre maillons (§ 10.1). Aucune exigence : « aucune exigence rattachée » (à la place des quatre).
- Ligne 3 (absente si rien ; 11,5 px/400 `--text-3`, **clamp 2 lignes**) : **gabarit fermé à trois emplacements**, nuls omis : « 2 en
  contradiction · 3 avec un manque · 1 non lisible », en exigences, catégories exclusives (§ 10.1) ; l'octogone précède le
  premier emplacement seulement quand « en contradiction » est non nul ; tout complet : « toutes complètes ».
- Ligne 4 (absente si nulle ; 11,5 px/400 `--text-3`, **clamp 2 lignes**) : un emplacement unique, sans glyphe : « 2 lignes de traçabilité sans
  exigence » (**c'est l'unique emplacement de cette cause**, P76-D-15bis).
- Hauteur d'une ligne, au pire : 155 px (§ 2.3, ligne 1 comptée à 21 px : pastille `.vst` de 20,7 px). Le détail de chaque exigence vit dans le panneau de la phase.
- Clic ou Entrée : `select('ph-<N>')`, la section de § 2 s'y trouve ; pas de panneau neuf.

### 4.2 « Décisions »

Bilan (12,5 px/400 `--text-3`, clamp 2 lignes), **gabarit fermé à trois emplacements** : « 32 ADR · 71 décisions · 14 registres de phase ». Deux blocs :
1. Une ligne par ADR (`button.vf-trace-ligne`) : identifiant `--mono` 11,5 px/500 `--text-2` (« ADR-075 ») puis le titre lu après
   le numéro (12,5 px/400 `--text-2`, une ligne, ellipsis, `title` = titre complet). ≤ 30 puis « + N autres ADR ». Une ADR citée
   sans section dans `docs/ADR.md` n'a pas de ligne ici (§ 5.3).
2. Sous `.group-h` « Registres de phase », un `<details class="vf-trace-repli vf-trace-sous">` par registre, fermé : son
   `<summary>` est de rôle « sous-repli » (§ 13) : « Phase 41 » et « 12 décisions ». ≤ 30 registres, du plus récent au plus
   ancien, puis « + N autres registres ». Déplié : ses décisions (≤ 30 puis « + N autres décisions ») : identifiant mono
   11,5 px/500 `--text-2` (« P41-D-02 » ; nue « D-04 ») et le **titre** de la définition, coupé à 80 caractères par la route
   (12,5 px/400 `--text-2`, une ligne, ellipsis ; quand le titre est coupé, la route y termine par « … », visible).
   Un seul niveau de pliage dans un pliage : retrait gauche `var(--sp-12)`.

### 4.3 « Mémoire des agents »

Bilan (12,5 px/400 `--text-3`, **clamp 4 lignes**, section repliée par défaut donc hors budget § 2.3), **gabarit fermé à six emplacements**, zéros
écrits : « 268 entrées · 12 agents · 7 entrées hors index · 33 liens cassés · 4 chemins cités absents · 143 entrées sans lien
entrant » (chiffres de la route, jamais recalculés côté page). Les compteurs ont des unités différentes (entrées, liens, chemins)
et ne s'additionnent pas ; « hors index » et « sans lien entrant » se recouvrent (une entrée peut avoir les deux), chacun compte ses
entrées (§ 10.1). Pire cas : § 2.4. Une ligne par agent (le dossier sous `.claude/agent-memory/`, ≤ 30 puis « + N autres agents »),
**gabarit fermé de trois lignes au plus** :
- Ligne 1 : nom de l'agent en `--mono` 12,5 px/500 `--text` (une ligne, ellipsis, `title`), à droite « 24 entrées » (11,5 px/400
  `--text-3`, tabular-nums).
- Ligne 2 (absente si les trois sont nuls ; **clamp 2 lignes**, 11,5 px/500 `--text-2`) : octogone puis **trois emplacements**, nuls
  omis : « 3 entrées hors index · 2 liens cassés · 1 chemin cité absent ».
- Ligne 3 (absente si les deux sont nuls ; **clamp 2 lignes**, 11,5 px/400 `--text-3`) : **deux emplacements**, nuls omis : « 11 entrées
  sans lien entrant · 4 liens résolus par nom de fichier ».
- Les cinq nuls : une seule ligne, « aucun écart ». Le détail par entrée vit dans le panneau de liste de l'agent (§ 6).
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

- Titre : identifiant. `.pd` : le texte de l'exigence, entier (pas de clamp), `overflow-wrap: anywhere`. **Ordre des sections** :
  « Chaîne », « Décisions citées », « Preuves », « Mentions », « Rattachement ».
- Section « Chaîne » (`h3`) : d'abord une phrase d'aide (11,5 px/400 `--text-3`) : « Niveau exigence : le fichier lu cite cette
  exigence. Niveau phase : le fichier existe pour la phase sans la citer. » Puis quatre lignes, une par maillon : glyphe de
  16 px, nom du maillon (12,5 px/500 `--text`), puis, sur la même ligne, état et niveau en toutes lettres, **seule source
  visible du niveau** : « lu, niveau exigence », « lu, niveau phase », « manque », « non lisible », et, pour une contradiction,
  la phrase de § 10 à la place de l'état : « contradiction : case cochée au registre des exigences, aucun SUMMARY lu » (11,5 px/400 `--text-3`).
  **Une contradiction de maillon vit ici et nulle part ailleurs dans ce panneau** (pas de section « Contradictions »). Dessous,
  la source : chemin mono copiable et le champ lu. Plan : un `.tag` par plan qui la cite (« 76-01 »), rendu en
  `button.tag.vf-trace-puce` : focus `outline: 2px solid var(--ring)`, survol `rgba(var(--ink), .1)`, cible 44 px sous
  `pointer: coarse` (`min-height: 44px`, `display: inline-flex`, `align-items: center`) ; **au plus 3 puces, puis une 4e puce « + N »**
  (N plafonné à « 9 999+ ») qui ouvre le panneau de liste « Plans de l'exigence <identifiant> » (§ 6, § 2.4) ; chaque plan s'ouvre par
  `select('f:<chemin>')` après l'empilement du panneau de l'exigence (§ 0).
- Section « Décisions citées » (`h3`, compteur « 2 décisions ») : P76-D-38. Lit les identifiants **cités dans la ligne de
  l'exigence au registre des exigences** : décisions préfixées (`P<n>-D-<nn>`) et ADR ; une décision nue (`D-nn`) n'y est pas reliée (ADR-075) et
  n'est pas montrée. Une ligne par décision citée (`button.vf-trace-ligne`, ≤ 30 puis « + N autres décisions ») : identifiant
  `--mono` 11,5 px/500 `--text-2` puis le titre de la définition, coupé à 80 caractères par la route (12,5 px/400 `--text-2`,
  une ligne, ellipsis, `title` = titre servi) ; pour une ADR, son titre lu après le numéro. **Aucun glyphe** : ce bloc est une
  liste de voisins, pas un état. Nom accessible : « Décision P78-D-01, <titre>. Ouvrir la décision. » (ou « ADR-075, <titre>.
  Ouvrir l'ADR. »). Une décision citée mais sans définition lue (ou une ADR sans section) : texte non interactif, identifiant mono
  puis « sans définition lue » (ou « sans section dans docs/ADR.md »), `--text-3`. Aucune décision citée : « aucune décision
  citée » (12,5 px/400 `--text-3`, neutre, jamais corail) suivi de ce qui la lèverait : « Un identifiant Pnn-D-nn ou ADR-nnn dans
  la ligne de l'exigence au registre des exigences la relierait. »
- Section « Preuves » (`h3`, compteur « 2 fichiers ») : P76-D-38. Une ligne par maillon de preuve **lu** pour cette exigence :
  VERIFICATION, recette, trace rouge de chaque plan qui la cite (`button.vf-trace-ligne`, ≤ 30 puis « + N autres fichiers de
  preuve »). Ligne 1 : portée et libellé (« Phase · VERIFICATION », « 76-01 · Trace rouge », 12,5 px/500 `--text`, une ligne) ; ligne 2
  (11,5 px/400 `--text-3`, une ligne, ellipsis) : **le statut seul**, « statut : passed » ; **le niveau n'y figure pas** (il vit dans
  « Chaîne » seulement, § 1.2). **Aucun glyphe**, aucun chemin ici (le chemin copiable est dans la liste des preuves). **Le contenu du fichier n'est jamais rendu.** Un clic
  ou Entrée ouvre le panneau de liste « Preuves de la Phase N » **positionné sur cette preuve** (§ 6). Aucune preuve lue :
  « Aucune preuve lue pour cette exigence. VERIFICATION, recette ou trace rouge dans le dossier de la phase la relierait. »
- **Ouverture des voisins (plan, décision, ADR, preuve, liste des plans) : la règle d'empilement de § 0.** Le panneau de l'exigence est
  un panneau sur mesure : au clic sur une ligne de voisin, il appelle **une fois** `window.VF_PANNEAU.empiler({ titre, rouvrir })`
  avec l'identifiant de l'exigence (texte, jamais HTML, ≤ 40 caractères) et un `rouvrir` qui rend de nouveau ce panneau, puis ouvre le
  voisin (`SC.showPanel` pour une décision, une ADR ou une liste ; `select('f:<chemin>')` pour un plan). Chaque panneau quitté est
  empilé une fois, par celui qui le quitte : la phase l'a été à son départ vers l'exigence (§ 2.2), l'exigence l'est ici, à son départ
  vers le voisin ; aucun appel n'est fait à l'arrivée sur un panneau. Le bouton « Retour : <titre> » de l'en-tête ramène à l'exigence **en une pression** et le
  focus revient sur la ligne qui a ouvert le voisin (retrouvée par son `data-trace`, **à revalider**). Clavier : chaque ligne est
  un `button` natif (Tab, Entrée, Espace), focus `outline: 2px solid var(--ring); outline-offset: -2px`, aucune touche globale ;
  l'ordre de tabulation suit l'ordre des sections ci-dessus.
- Section « Mentions » (absente si aucune), phrases neutres, sans glyphe, **sans le niveau d'un maillon** (il vit dans « Chaîne » seulement, § 1.2) : « Case non cochée au registre des exigences, un SUMMARY est lu. » ;
  « Aucune ligne du tableau de traçabilité ne la nomme. »
- Section « Rattachement » : « Phase 76, Traçabilité au cockpit » (bouton), puis « Ligne du tableau de traçabilité : Phase 76,
  Pending » si elle existe, sinon « Rattachée par le champ « requirements » d'un plan. »

### 5.2 ADR

Titre « ADR-075 » ; `.pd` : le titre lu après le numéro, jamais un résumé. « Décisions qui la citent » (≤ 30, puis « + N autres
décisions »), « Commits qui la citent » (≤ 30, § 5.5). Source : « Lu dans docs/ADR.md ».

### 5.3 Décision

- Titre « P41-D-02 » ; nue « D-04, Phase 41 ». `.pd` : le **titre** de la définition, coupé à 80 caractères par la route, qui
  y termine par « … » : **la coupe est visible**. Quand le titre est coupé (`titreCoupe`), une ligne le dit sous le titre
  (11,5 px/400 `--text-3`) : « Titre coupé à 80 caractères. La définition entière est dans <chemin relatif du registre>. » ; la
  ligne entière n'est pas servie, le pied de source donne le chemin (le texte entier est ailleurs, § 2.4).
- « Phase » : un bouton. « ADR citées » : une ligne par ADR citée ; avec section : bouton ; sans : texte mono suivi de « sans
  section dans docs/ADR.md » (`--text-3`), non interactif.
- « Commits qui la citent » (§ 5.5). Décision nue : à la place, « Décision nue : aucun commit ne lui est relié, la citation sans
  phase est ambiguë. » (12,5 px, `--text-3`).
- Source : « Lu dans <registre de phase> ».

### 5.4 Entrée de mémoire

- Titre : le `name` (mono, passe à la ligne). Rappel (11,5 px, `--text-3`) : « Seule la structure est lue : ni description ni
  contenu. »
- « Fiche » : étiquettes (11,5 px/400 `--text-3`) et valeurs (12,5 px/400 `--text`) : « Agent » (mono), « Type » (`.tag`), « Dernier commit » (« 8 nov. 2026 », jour seul), « Liens sortants »
  (« 3 liens »), « Liens entrants » (« 2 liens »).
- « État » : **états de l'entrée seulement**, un mot (12,5 px/500 `--text`) avec son glyphe : « hors index » (octogone) et « sans lien entrant »
  (sans glyphe) ; aucun des deux : « Dans l'index, avec au moins un lien entrant. » Un lien cassé et un chemin absent ne se
  répètent pas ici : ils vivent sur leur ligne.
- « Liens sortants » : une ligne par lien (nom cible mono 12,5 px/500 `--text`, puis, 11,5 px/400 `--text-3`, « résolu », « résolu par nom de fichier » (carré à deux barres)
  ou « lien cassé » (octogone)). Cible résolue : bouton ; cassée : texte. ≤ 30 puis « + N autres liens ».
- « Liens entrants » : lignes de boutons, ≤ 30 ; les liens d'index (`MEMORY.md`) n'y figurent pas.
- **« Chemins cités et absents de HEAD »** (absente si aucun) : **seuls** les chemins qui répondent à « cite un chemin absent »
  (P76-D-22) : relatifs au dépôt, absents de HEAD, présents dans l'historique lu. Une ligne : octogone, chemin mono 11,5 px/400 `--text-3`,
  puis « absent de HEAD, présent dans l'historique lu » (11,5 px/400 `--text-3`). Aucun autre chemin du corps n'est montré, ni compté, ni nommé ; le chemin du
  fichier de mémoire suivi lui-même (structure suivie par git, nécessaire au verdict « hors index ») n'est montré que dans le pied de
  source.
- Jamais `description`, jamais le corps, jamais un chemin `~/` ou absolu (P76-D-20).

**Gabarit des lignes de § 5.4** (règle de classe de § 2.4 : emplacements fermés, ordre fixe, une seule donnée libre par ligne, coupée
ou clampée, lisible en entier ailleurs). Largeurs de ligne : 224 px au plancher (248 − 2 × 12 de `--inset-row`), 204 px pour un texte placé
après un glyphe de 16 px et son écart (`var(--sp-4)`), sans retrait de ce genre pour les lignes sans glyphe.

| Ligne | Gabarit (de haut en bas) | Coupe | Hauteur |
|-------|--------------------------|-------|---------|
| Titre (`.pt`, le `name`) | une seule donnée : le `name` mono, `overflow-wrap: anywhere` | **clamp 3 lignes** de 26, `title` = nom entier ; le nom entier se lit aussi dans le chemin du pied de source | 78 au plus |
| Rappel « Seule la structure est lue… » | phrase fixe, 11,5 px/16 | aucune (copy fermé : 2 lignes à 248 px) | 32 |
| Fiche, une rangée | `dl` en grille `minmax(0, 40%) minmax(0, 1fr)`, `column-gap: var(--sp-8)`, `row-gap: var(--sp-2)`, `align-items: baseline` : étiquette (11,5 px/400 `--text-3`) puis valeur (12,5 px/400 `--text`, mono pour « Agent ») | valeur d'une ligne, ellipsis, `title` ; « Type » est un `.tag` (20 px) | 18 (20 pour « Type ») ; cinq rangées : 5 × 18 + 2 + 4 × 2 = **100** |
| « État » | un mot (12,5 px/500 `--text`) avec son glyphe, **ou** la phrase neutre (12,5 px/400 `--text-3`) ; au plus deux mots, un par ligne | phrase neutre clamp 2 | 18 par mot (2 × 18 + 2 = 38 au plus) ; 36 pour la phrase |
| Lien sortant | `padding: var(--inset-row)` ; ligne 1 : nom cible mono 12,5 px/500 `--text` ; ligne 2 (`row-gap: var(--sp-2)`) : état 11,5 px/400 `--text-3`, glyphe seulement pour « résolu par nom de fichier » et « lien cassé » | ligne 1 ellipsis + `title` ; ligne 2 `nowrap` (« résolu par nom de fichier » + glyphe : 180 px pour 224 px) | 16 + 18 + 2 + 16 = **52** |
| Lien entrant | `padding: var(--inset-row)` ; une ligne : nom mono 12,5 px/500 `--text` | ellipsis + `title` | 16 + 18 = **34** |
| Chemin cité absent (texte non interactif) | `padding: var(--inset-row)` ; ligne 1 : octogone puis chemin mono 11,5 px/400 `--text-3` ; ligne 2, **alignée sous le chemin** (retrait `calc(var(--sp-16) + var(--sp-4))`) : « absent de HEAD, présent dans l'historique lu » 11,5 px/400 `--text-3` | ligne 1 ellipsis + `title` = chemin entier ; ligne 2 **clamp 2** (2 lignes à 204 px, dernière à 44 %) | 16 + 16 + 2 + 32 = **66** |
| Pied de source | « Lu dans » + `.vf-ref` du chemin (§ Typography) | `code` ellipsis, copie du chemin entier | 32 (44 tactile) |

Les listes de liens sont plafonnées à 30 (§ 7) ; « + N autres liens » ouvre la liste paginée (§ 6).

### 5.5 Ligne de commit

`button.vf-trace-commit` : sha court en `--mono` 11,5 px/500 `--text-2` (7 caractères), jour (« 8 nov. 2026 », `--text-3`), puis
le sujet (12,5 px `--text`, une ligne, ellipsis, `title` = sujet complet). Le corps du message n'est jamais servi. Clic ou
Entrée : ouvre le tiroir Git existant (`window.VFGitTiroir.ouvrir()`, Phase 78, détail sans diff) ; la sélection par sha dépend
d'un crochet de la 78 (`VFGitExt`), **à revalider** ; à défaut, le tiroir s'ouvre sans sélection. Git ou `VFGitTiroir` absent :
la ligne est du texte, non interactive. Nom : « Commit a1b2c3d, 8 nov. 2026, <sujet>. Ouvrir dans l'historique Git. » (le
texte visible est contenu dans le nom). Borne atteinte (`bornes.tronque`) : au-dessus de la liste, le message de § 9 en entier
(« Lecture bornée : la liste peut être incomplète. Une lecture plus courte, ou moins de commits, la lèverait. »), **11,5 px/16, 400,
`--text-3`, clamp 3 lignes, 8 px d'écart sous lui** (3 lignes simulées à 248 px, dernière à 70 % ; 48 + 8 = 56 px au pire) : une seule
taille et une seule forme du message dans tout le document.

## 6. Panneaux de liste et pagination

Ouverts par « + N autres », par une ligne d'agent ou par un registre au-delà du seuil. Gabarit de § 5 (Retour de l'en-tête, titre
`.pt` : « Exigences de la Phase 76 », « Preuves de la Phase 76 », « Plans de l'exigence TRAC-01 », « Entrées de vf-dev-manager », « ADR »). Corps : 30 lignes par
page, puis `<nav aria-label="Pagination">` en **deux lignes fixes à toute largeur** (§ 2.4) : ligne 1, le compte « 31 à 60 sur 83
exigences » (l'unité suit la sorte : ADR, commits, entrées, liens, fichiers de preuve, plans ; nombres plafonnés à « 9 999+ » ;
11,5 px/400 `--text-3`, tabular-nums, clamp 2, `aria-live="polite"`) ; ligne 2, `.btn.soft` « Précédentes » et « Suivantes »
(`disabled` à la borne), côte à côte (`flex: 1 1 0`, `white-space: nowrap`). Pas de pagination infinie. Le changement de page replace
le focus sur le titre. Boutons de 32 px de haut (44 px tactile), `font-size` 12,5 px (§ Typography). Hauteur de la pagination :
72 px (84 px tactile).

**Ligne d'entrée de mémoire** (liste d'un agent, `button.vf-trace-ligne`, **gabarit fermé de trois lignes**) : ligne 1 `name` mono
12,5 px/500 `--text` (une ligne, ellipsis, `title`) et `.tag` du type ; ligne 2 (clamp 2, 11,5 px/400 `--text-3`) « modifiée le 8 nov. 2026 · 2 liens
entrants · 3 liens sortants » ; ligne 3 (absente si rien ; clamp 3) : octogone puis **quatre emplacements au plus**, nuls
omis, dans cet ordre : « hors index · 1 lien cassé · 1 chemin cité absent · sans lien entrant » ; **deux familles nommées** : les trois
premiers (contradictions, derrière l'octogone) en 11,5 px/500 `--text-2`, le quatrième « sans lien entrant » (filtre neutre) en
11,5 px/400 `--text-3`. Pire cas : § 2.4. **Ligne de preuve** (liste « Preuves de la
Phase N ») : portée et libellé, statut (une ligne, ellipsis), chemin copiable clampé à 1 ligne, puis, pour un plan, « Critères du
plan, 5 critères » et la liste de ses critères en texte (12,5 px/400 `--text-2`, ≤ 30 par page). **Ouverture positionnée** (depuis
« Preuves » d'une exigence, § 5.1) : le panneau s'ouvre sur la page qui contient la preuve visée ; sa ligne est amenée en haut de la
zone visible, porte `aria-current="true"` et un fond `--surface-hover` (état neutre, ni teinte ni contour coloré), et prend le focus
si l'ouverture vient du clavier ; le contenu du fichier n'est jamais rendu.

## 7. Échelle : seuils et « + N autres »

- **Section « Traçabilité » d'une phase : 5 lignes (3 sous 700 px)**, lignes à trou d'abord, budget de hauteur § 2.3 ; **repli
  « Preuves attachées » ouvert : 6 lignes (4 sous 700 px)** (§ 3).
- **Ailleurs, dans un panneau ou une section : au plus 30 voisins d'une même sorte** (exigences d'une liste, ADR, décisions,
  commits, liens, entrées, agents, registres, critères d'un plan, fichiers de preuve d'un panneau de liste).
- Au-delà : `button.vf-trace-plus` (**`height: 32px`**, taille de contrôle de la liste fermée, 44 px sous `pointer: coarse` ; 12,5 px/500 `--text-2`, `padding: 0 var(--sp-12)`, survol `rgba(var(--ink), .06)`, focus
  `--ring`) qui ouvre le panneau de liste paginé (§ 6). N est plafonné à « 9 999+ » et le libellé tient sur une ligne (règle de § 2.4). Le libellé nomme toujours la sorte : « + 12 autres exigences », « + 2 autres
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
| Phase sans exigence | « Traçabilité » | « Aucune exigence rattachée à cette phase. Une ligne du tableau de traçabilité du registre des exigences, ou le champ « requirements » d'un plan, la rattache. » |
| Aucune phase au jalon | « Jalon » | « Aucune phase dans le jalon en cours. Une phase inscrite à la feuille de route sous ce jalon apparaît ici. » |
| Pas de `docs/ADR.md` | « Décisions » | « Pas de docs/ADR.md dans ce dossier. Les sections ADR-NNN de ce fichier apparaîtraient ici. » (les registres de phase restent montrés s'ils existent) |
| Aucun registre de décisions | « Décisions » | « Aucune décision définie dans les registres de phase. Les lignes Pnn-D-nn d'un fichier CONTEXT de phase apparaissent ici. » |
| Pas de compartiment de planification | « Traçabilité » et les trois sections | « Aucun compartiment de planification lu : la traçabilité n'est pas disponible. Un compartiment avec son registre des exigences la rend lisible. » (une ligne, rien d'autre) |
| Traçabilité rangée en « Étape N » | « Traçabilité », « Jalon » | « La traçabilité de ce registre est rangée par Étape N : 3 étapes lues comme des phases, 2 sans dossier de phase. Un dossier de phase par étape les rend lisibles. » ; aucune ne désigne un dossier : « La traçabilité de ce registre est rangée par Étape N, aucune ne désigne un dossier de phase. Un dossier de phase par étape la rend lisible. » (P76-D-12) |
| Pas de `.claude/agent-memory/` | « Mémoire des agents » | « Pas de .claude/agent-memory/ dans ce dossier. Les fichiers de mémoire suivis par git apparaîtraient ici. » |
| `.claude/` ignoré par git | « Mémoire des agents » | « .claude/ n'est pas suivi par git : 12 fichiers non suivis, aucune entrée à lire. Suivre .claude/agent-memory/ dans git les rend lisibles. » (le nombre, jamais un nom) |
| Pas de git | « Mémoire », commits | « Git n'est pas disponible : la mémoire des agents n'est pas lue. Un dépôt git la rend lisible. » ; « Git n'est pas disponible : les commits qui citent cet objet ne sont pas lus. Un dépôt git les rend lisibles. » ; le reste s'affiche |
| Aucun commit citant | panneau ADR, décision | « Aucun commit ne cite cet objet. Un message de commit qui nomme son identifiant le relierait. » |
| Agent sans entrée | liste d'agent | « Aucune entrée suivie pour cet agent. Un fichier de mémoire suivi par git sous son dossier apparaît ici. » |
| Aucune preuve | « Preuves attachées » | « Aucune preuve attachée. Un fichier VERIFICATION, de recette, de trace rouge, de sécurité ou de validation dans le dossier de la phase l'attacherait. » |
| Réponse bornée | listes de commits, d'entrées | « Lecture bornée : la liste peut être incomplète. Une lecture plus courte, ou moins de commits, la lèverait. » (11,5 px/16, 400, `--text-3`, **clamp 3**, au-dessus de la liste avec 8 px d'écart sous le message ; une réponse bornée ne se présente jamais comme complète) |
| Collecte en cours (`collecte: en-cours`, avant la première collecte) | section, panneau | « La collecte du dépôt est en cours. La traçabilité apparaît dès qu'elle est faite. » (12,5 px/400 `--text-3`) ; sans bouton : la clé `planning` de `VF_ETAT` relance l'appel |
| Route en échec (503, délai, 400 inattendu) | section, panneau | boîte neutre : titre « La traçabilité est indisponible » (12,5 px/500 `--text`), cause « La lecture du dépôt a échoué ou dépassé le délai. » (12,5 px, `--text-2`), `.btn.soft` « Réessayer » ; le reste du panneau fonctionne |
| Objet introuvable ou disparu | panneau | « Cet objet n'existe plus dans le dépôt. Le bouton Retour de l'en-tête rouvre la vue précédente. » |
| Rafraîchissement par `planning` | section ouverte | le contenu se remplace sans fondu ; défilement et pliages conservés |

La page ne construit jamais une `cle` hors motif ; un 400 inattendu se rend comme « Route en échec ».

## 10. Où vit chaque cause de contradiction (P76-D-04, P76-D-15bis)

Corail réservé à la **liste fermée** : cochée sans SUMMARY, Complete sans plan, lien cassé, hors index, chemin cité absent. Le
corail est porté par le seul glyphe octogone ; la phrase est en `--text-2`. **Un emplacement par cause et par surface**, sans
exception tacite : la règle « mot en ligne 2 si c'est le premier maillon non lu, sinon mention de ligne 3 » est écrite une fois, ici.

| Cause lue | Corail | Ligne d'exigence ou d'agent ou d'entrée | Panneau d'objet | Vue d'ensemble |
|-----------|--------|------------------------------------------|-----------------|----------------|
| Case cochée au registre des exigences, aucun SUMMARY lu | oui | octogone à la place du maillon SUMMARY ; mot « contradiction : cochée, sans SUMMARY » en ligne 2 si SUMMARY est le premier maillon non lu, sinon en mention de ligne 3 (priorité a) | ligne SUMMARY de « Chaîne » (§ 5.1) : « contradiction : case cochée au registre des exigences, aucun SUMMARY lu » | « Jalon », ligne 3 : compté dans « N en contradiction » |
| Statut « Complete » sans plan | oui | octogone à la place du maillon plan ; mot « contradiction : Complete, sans plan » en ligne 2 (le plan est le premier maillon) | ligne Plan de « Chaîne » : « contradiction : statut Complete au tableau de traçabilité, aucun plan ne la cite » | idem |
| Lien `[[…]]` cassé | oui | ligne d'entrée : « 1 lien cassé » en ligne 3 ; ligne d'agent : « 2 liens cassés » en ligne 2 (gabarit § 4.3) | ligne du lien dans « Liens sortants » : « lien cassé » | décompte du bilan « Mémoire » |
| Mémoire hors index | oui | ligne d'entrée : « hors index » en ligne 3 ; ligne d'agent : « 3 entrées hors index » en ligne 2 | section « État » : « hors index » | décompte du bilan « Mémoire » |
| Chemin cité absent | oui | ligne d'entrée : « cite un chemin absent » en ligne 3 ; ligne d'agent : « 1 chemin cité absent » en ligne 2 | ligne du chemin dans « Chemins cités et absents de HEAD » | décompte du bilan « Mémoire » |
| Case non cochée avec SUMMARY lu | non | mention neutre de ligne 3 (priorité b) : « non cochée, SUMMARY lu » | « Mentions » : « Case non cochée au registre des exigences, un SUMMARY est lu. » | « Jalon » : aucune |
| Exigence sans ligne de traçabilité | non | mention neutre de ligne 3 (priorité b) : « sans ligne de traçabilité » | « Mentions » : « Aucune ligne du tableau de traçabilité ne la nomme. » | « Jalon » : aucune |
| Ligne de traçabilité sans exigence | non | aucune (pas de ligne d'exigence où la poser) | aucun | « Jalon », ligne 4 : « 2 lignes de traçabilité sans exigence », **seul emplacement** |

Un mot de ligne ne masque jamais le premier trou : la ligne 2 dit toujours le premier maillon non lu de la bande ; toute autre
contradiction passe en ligne 3. **Décisions de détail déléguées par Samuel (message session principale, 2026-11-08), option
recommandée** : « non cochée, SUMMARY lu » est neutre (absent de la liste fermée de P76-D-04, malgré P76-D-15). Le mot « rouge »
du but du 2026-11-03 est lu « marqué et visible » dans les teintes Graphite (P76-D-32, § 12). Aucune phrase n'est un verdict sur le
travail : elle décrit ce que deux fichiers disent l'un de l'autre.

### 10.1 Règle de décompte des bilans

- **Un maillon a un seul état** parmi lu, manque, non lisible, contradiction. « Cochée, sans SUMMARY » donne au maillon SUMMARY
  l'état contradiction (jamais « manque ») ; « Complete, sans plan » donne au maillon plan l'état contradiction.
- **Bilan d'exigences** (section de phase, entrée haute) : catégories **exclusives**, chaque exigence comptée une seule fois dans
  la première qui s'applique, dans cet ordre : « en contradiction », « avec un manque », « non lisibles », « complètes ». Une exigence
  « cochée sans SUMMARY » dont VERIFICATION manque compte donc en contradiction. La somme égale le nombre d'exigences ; les quatre
  catégories s'écrivent toujours dans le bilan de la section (zéros compris, § 2.2) ; « complète » exige quatre maillons « lu ». « Incomplète » (entrée haute) = toute exigence non
  complète.
- **Bilan de jalon** : catégories **exclusives par phase**, selon la pire exigence de la phase, mêmes quatre catégories plus
  « sans exigence » ; la somme égale le nombre de phases ; la catégorie « complètes » compte des phases dont toutes les exigences sont
  complètes.
- **Ligne 2 d'une phase du Jalon** : quatre compteurs de **maillons non lus** (manque, non lisible ou contradiction), un par
  maillon, avec chevauchement entre maillons (une exigence à SUMMARY et VERIFICATION non lus compte dans les deux). **Ligne 3** :
  exigences par catégorie exclusive (contradiction, manque, non lisible), chaque exigence comptée une fois. **Ligne 4** : « N
  lignes de traçabilité sans exigence » compte des lignes du tableau de traçabilité.
- **Bilan de mémoire** : compteurs par unité (entrées, liens, chemins), sans somme, les six toujours écrits (« N chemins cités
  absents » compris) ; « hors index » et « sans lien entrant » se recouvrent et le disent ; les liens résolus par nom de fichier
  sont comptés à part, jamais en défaut.
- **Plafond** : un nombre de plus de 9 999 s'écrit « 9 999+ » ; le nombre exact est dans le compteur du panneau ouvert.

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
ligne fantôme, `summary` et `.vf-trace-plus` 32 px ; cible tactile 44 px ; seuils de 5, 3 et 30.
Exception écrite : le texte masqué `.vf-trace-sr` (1 px, comme un filet). **Aucun rayon littéral** : toute ligne, boîte et ligne
fantôme prend `var(--r-ctl)` (12 px) ; ce rayon n'est pas celui de `.vf-link` (10 px, littéral) : écart voulu, décision déléguée
par Samuel (message session principale, 2026-11-08), option recommandée, pour n'écrire aucune valeur en dur. Rien d'existant
n'est modifié.

## Typography

**Quatre tailles seulement** : 20, 13,5 (hérité), 12,5 et 11,5 px. **Deux graisses posées** : 500 et 600 (600 réservé au titre `.pt`,
existant) ; le 400 est hérité du moteur et n'est jamais écrit. **Interlignes déclarés** : 18 px pour 12,5 px, 16 px pour 11,5 px
(`line-height` écrit en px sur `.vf-trace` ; `.tag` surchargé à 16 px, § Surcharges), 26 px (1,3) pour le titre de 20 px et 21,6 px (1,6) pour le 13,5 px, ces deux derniers
existants. Chaque élément nommé ci-dessous a **une seule taille, une seule graisse, une seule teinte**, reprises à l'identique dans
sa section.

| Élément | Section | Taille / interligne | Graisse | Teinte |
|---------|---------|---------------------|---------|--------|
| Titre de panneau d'objet (`.pt`) | § 5 | 20 px / 26 px (-.02em, existant) | 600 | `--text` |
| Type d'objet (`.ph .kindlabel`) | § 5 | 12,5 px / 18 px | 400 hérité | `--text-3` |
| Texte de l'exigence, titre de définition (`.pd`) | § 5.1, § 5.3 | 13,5 px / 21,6 px (existant) | 400 hérité | `--text-2` |
| Titre de section (`.sec h3`) et `summary` de section | § 2, § 3, § 4 | 12,5 px / 18 px | 500 | `--text-3` |
| `summary` de sous-repli (registre de phase) | § 4.2 | 12,5 px / 18 px | 500 | `--text-2` |
| Compteur `.c` | § 2, § 3, § 4 | 12,5 px / 18 px | 400 hérité | `--text-4` |
| Bilan (phase, Jalon, Décisions, Mémoire), résumé de l'entrée haute, ligne neutre d'état vide ou dégradé (§ 9), phrase « Décision nue » | § 2, § 4, § 5, § 9 | 12,5 px / 18 px | 400 hérité | `--text-3` |
| Nom en ligne : « Phase 76 », libellé de maillon, de preuve, de lien ; mot d'état de la section « État » d'une entrée (« hors index ») ; bouton de « Rattachement » ; libellé « Critères du plan, 5 critères » | § 2 à § 6 | 12,5 px / 18 px | 500 | `--text` |
| Nom mono : agent, `name` d'entrée, nom cible d'un lien | § 4.3, § 5.4, § 6 | 12,5 px / 18 px | 500 | `--text` (mono) |
| Bouton « + N autres » (`.vf-trace-plus`) : **une seule graisse, 500**, comme § 7 ; action sans fond, la graisse porte son statut de contrôle | § 7 | 12,5 px / 18 px (hauteur 32 px) | 500 | `--text-2` |
| Texte de ligne : exigence, sujet de commit, valeur d'une « Fiche » | § 2, § 4, § 5 | 12,5 px / 18 px | 400 hérité | `--text` |
| Nom de phase du « Jalon » ; phrase neutre de la section « État » (« Dans l'index, avec au moins un lien entrant. ») | § 4.1, § 5.4 | 12,5 px / 18 px | 400 hérité | `--text-3` |
| Titre d'ADR et titre de décision en liste (une seule teinte), ligne de critères, cause d'erreur | § 3, § 4.2, § 6, § 9 | 12,5 px / 18 px | 400 hérité | `--text-2` |
| Titre d'erreur « La traçabilité est indisponible » | § 9 | 12,5 px / 18 px | 500 | `--text` |
| Boutons `.btn.soft` (Réessayer, Précédentes, Suivantes) | § 6, § 9 | 12,5 px / 18 px (hauteur 32 px) | 400 hérité | `--text` |
| Identifiant mono (TRAC-01, ADR-075, P41-D-02), sha | § 2 à § 6 | 11,5 px / 16 px | 500 | `--text-2` |
| Mot de ligne 2 d'une exigence ; **ligne 2 d'une phase du « Jalon »** (« Maillons non lus : … ») ; comptes d'agent en défaut ; contradictions de la ligne 3 d'une entrée (les trois premiers emplacements) | § 2.2, § 4.1, § 4.3, § 6 | 11,5 px / 16 px | 500 | `--text-2` |
| Mentions et compte, légende des glyphes, comptes secondaires de ligne (lignes 3 et 4 du « Jalon », ligne 3 d'un agent, **« sans lien entrant » de la ligne 3 d'une entrée**), dates, jour de commit, statut, **message « Lecture bornée » (11,5 px/16, § 5.5, § 9)** | § 2 à § 6, § 9 | 11,5 px / 16 px | 400 hérité | `--text-3` |
| État et niveau d'un maillon dans « Chaîne » (« lu, niveau exigence »), état d'un lien (« résolu »), étiquette de « Fiche », phrase de contradiction, **phrases de « Mentions » et de « Rattachement » (« Ligne du tableau de traçabilité : Phase 76, Pending »)**, aide, rappel de mémoire, « absent de HEAD… », pied de source, **compte de pagination** | § 5, § 6 | 11,5 px / 16 px | 400 hérité | `--text-3` |
| Chemin copiable (`.vf-ref code`, mono) et chemin cité (mono) | § 3, § 5.4 | 11,5 px / 16 px | 400 hérité | `--text-3` |
| Commit : sujet (12,5 px/400 `--text`), sha (11,5 px/500 `--text-2`), jour (11,5 px/400 `--text-3`) | § 5.5 | voir l'élément | voir l'élément | voir l'élément |

`--mono` pour identifiants, sha, chemins, `name` de mémoire ; `--sans` ailleurs. Chiffres en `font-variant-numeric: tabular-nums`
(compteurs, pagination, bilans).

**Surcharges des briques réemployées** (écrites sous un parent `.vf-trace`, qui enveloppe chaque section et panneau de la 76,
sans toucher la règle d'origine) : le moteur pose des tailles hors de ces quatre (13, 11) et un rayon littéral, on les ramène.

| Brique | Valeur d'origine | Surcharge `vf-trace-*` |
|--------|------------------|------------------------|
| `.btn.soft` (Réessayer, Précédentes, Suivantes) | 13 px, hauteur 36 px, pastille | `font-size: 12.5px; height: 32px` (hauteur de `#ask-sheet .sh .btn`) ; 44 px sous `pointer: coarse` ; une seule hauteur pour tous les boutons de la 76 ; graisse 400 héritée |
| `.vf-ref code` (chemin copiable) | 11 px, `overflow-wrap: break-word` | `.vf-trace .vf-ref code { font-size: 11.5px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; display: block; min-width: 0 }` |
| `.vf-ref` (ligne du chemin) | `display: block`, `padding: var(--inset-row)` | `.vf-trace .vf-ref { display: flex; align-items: center; gap: var(--sp-8); min-height: 32px }`, **`min-height: 44px` sous `max-width: 700px` ou `pointer: coarse`** ; `code` en `flex: 1 1 0` |
| `.vf-ref` | `border-radius: 10px` littéral | `.vf-trace .vf-ref { border-radius: var(--r-ctl) }` |
| `.vf-copie-etat` (« Copié ») | 11 px, `float: right`, `margin-left: 8px` | `.vf-trace .vf-ref .vf-copie-etat { font-size: 11.5px; float: none; margin: 0; flex: none }` : à droite du chemin, dans la même rangée flex, 1,6 s |
| `.vst` (pastille de phase du « Jalon ») | 11 px (glyphe `1.45em`) | `font-size: 11.5px` (glyphe 16,7 px : brique du moteur, pas un glyphe de la famille § 1.1) |
| `.tag` (type, plan) | 11,5 px, `padding: var(--inset-pill)`, **aucun `line-height` propre** : la pastille hérite de la ligne qui la porte (18 px dans une ligne de 12,5 px, 21,6 px hors `.vf-trace`) | `.vf-trace .tag { line-height: 16px }` : pastille de 16 + 2 + 2 = **20 px** de haut, partout (type d'une entrée, valeur « Type » de la fiche, puces de plan) ; la hauteur de 46 px des deux rangées de puces (2 × 20 + `--sp-6`) en dépend ; `.vf-trace-puce` tactile garde `min-height: 44px` |
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

Réservé au corail : l'octogone des cinq causes de la liste fermée, **jamais dans la légende des glyphes, qui est neutre** (§ 2.2). Rien d'autre : ni texte, ni fond, ni contour, ni liseré ;
ni les mentions neutres, ni « manque », ni « non lisible ». Vert et jaune : pas d'usage neuf ; seule la pastille `.vst` du
« Jalon » les porte par son glyphe. Contraste : texte ≥ 4,5:1 (`--text-3`, `--text-4` mesurés dans DESIGN § 2) ; glyphe ≥ 3:1
sur `--surface` et `--bg` ; une teinte d'état jamais sur `--raise` ni `--raise-2` en thème clair. Destructif : sans objet.

## Copywriting Contract

| Élément | Copy |
|---------|------|
| CTA principal | aucun (lecture seule) ; plus proche : « Ouvrir l'exigence », « Ouvrir l'ADR », « Ouvrir la décision », « Ouvrir l'entrée », « Aller à la section » (nom accessible des lignes, jamais un libellé visible) |
| Titres de section | « Traçabilité », « Jalon », « Décisions », « Mémoire des agents », « Preuves attachées », « Chaîne », « Décisions citées », « Preuves », « Mentions », « Rattachement », « Fiche », « État », « Liens sortants », « Liens entrants », « Chemins cités et absents de HEAD », « Décisions qui la citent », « Commits qui la citent », « ADR citées », « Registres de phase » |
| Compteurs de section (avec unité) | « 4 exigences », « 12 phases », « 32 ADR », « 268 entrées », « 5 fichiers », « 12 décisions », « 3 liens » |
| Maillons | « Plan », « SUMMARY », « VERIFICATION », « Recette » (dans la légende et les mots : plan, SUMMARY, VERIFICATION, recette) |
| États de maillon | « lu », « manque », « non lisible », « contradiction » ; niveaux : « niveau exigence », « niveau phase » |
| Légende des glyphes | « Légende : » puis « lu », « manque », « non lisible », « contradiction » (glyphes neutres), « Colonnes : plan, SUMMARY, VERIFICATION, recette. » |
| Mot de ligne (ligne 2) | « manque : plan », « manque : SUMMARY », « manque : VERIFICATION », « manque : recette », « non lisible : plan », « non lisible : SUMMARY », « non lisible : VERIFICATION », « non lisible : recette », « contradiction : cochée, sans SUMMARY », « contradiction : Complete, sans plan », « chaîne complète » |
| Mentions (ligne 3, une mention puis un compte) | « non cochée, SUMMARY lu », « sans ligne de traçabilité », « lu au niveau phase : VERIFICATION, recette », suffixe « · et 3 autres mentions » ou « · et 1 autre mention » ; Jalon : « 2 lignes de traçabilité sans exigence » (ligne 4) |
| Bilans (gabarits fermés, § 2.4, catégories exclusives § 10.1) | « Par exigence : 1 en contradiction · 1 avec un manque · 0 non lisible · 2 complètes » ; « Par exigence : toutes complètes » ; « Par phase : 2 en contradiction · 7 avec un manque · 1 non lisible · 1 sans exigence · 1 complète » ; « Par phase : toutes complètes » ; « 32 ADR · 71 décisions · 14 registres de phase » ; « 268 entrées · 12 agents · 7 entrées hors index · 33 liens cassés · 4 chemins cités absents · 143 entrées sans lien entrant » |
| Résumé de l'entrée haute | « 4 exigences, 3 incomplètes dont 1 en contradiction » ; « 4 exigences, toutes complètes » |
| Lignes du « Jalon » (gabarits fermés, § 4.1) | « Maillons non lus : plan 0 · SUMMARY 2 · VERIFICATION 1 · recette 3 », « aucune exigence rattachée », « 2 en contradiction · 3 avec un manque · 1 non lisible », « toutes complètes », « 2 lignes de traçabilité sans exigence » |
| États mémoire | « hors index », « lien cassé », « cite un chemin absent », « résolu par nom de fichier », « sans lien entrant », « aucun écart » (ligne d'agent), « Dans l'index, avec au moins un lien entrant. » (section « État » d'une entrée) ; lignes d'agent (§ 4.3) : « 3 entrées hors index · 2 liens cassés · 1 chemin cité absent », « 11 entrées sans lien entrant · 4 liens résolus par nom de fichier » ; ligne d'entrée (§ 6) : « modifiée le 8 nov. 2026 · 2 liens entrants · 3 liens sortants », « hors index · 1 lien cassé · 1 chemin cité absent · sans lien entrant » |
| Preuves | « VERIFICATION », « Recette », « Trace rouge », « Sécurité », « Validation », « Phase · VERIFICATION », « 76-01 · Trace rouge », « Critères du plan, 5 critères » (panneau de liste seulement), « statut : passed », « + 4 autres fichiers de preuve », « Preuves de la Phase 76 », « Aucune preuve lue pour cette exigence. VERIFICATION, recette ou trace rouge dans le dossier de la phase la relierait. » |
| Décisions citées (panneau d'exigence) | « Décisions citées », « 2 décisions », « Ouvrir la décision », « sans définition lue », « sans section dans docs/ADR.md », « aucune décision citée », « Un identifiant Pnn-D-nn ou ADR-nnn dans la ligne de l'exigence au registre des exigences la relierait. » |
| Collecte | « La collecte du dépôt est en cours. La traçabilité apparaît dès qu'elle est faite. » |
| Dates, sha | « 8 nov. 2026 » (jour seul, mois abrégé français) ; sha de 7 caractères |
| Débordement | « + 12 autres exigences », « + 2 autres ADR », « + 5 autres registres », « + 40 autres commits », « + 3 autres agents », « + 4 autres liens », « + 4 autres fichiers de preuve », « + 5 autres plans », « + 9 999+ autres exigences » (plafond) ; titre de liste « Plans de l'exigence TRAC-01 » ; « Précédentes », « Suivantes », « 31 à 60 sur 83 exigences » |
| Retour | « Retour : <titre> » : libellé fourni par l'en-tête de la Phase 80, `<titre>` du lab rendu en texte ; la 76 n'écrit aucun libellé de retour |
| Chargement | « Lecture de la traçabilité » |
| État vide (titre) | la phrase d'absence du cas, § 9 (une seule phrase suivie de ce qui le lèverait) |
| État vide (corps) | la seconde phrase du même cas, § 9 : ce qui lèverait l'absence ; aucune action à proposer (lecture seule) |
| Erreur | titre « La traçabilité est indisponible » ; cause « La lecture du dépôt a échoué ou dépassé le délai. » ; bouton « Réessayer » |
| Borne | « Lecture bornée : la liste peut être incomplète. Une lecture plus courte, ou moins de commits, la lèverait. » |
| Note mémoire | « Seule la structure est lue : ni description ni contenu. » |
| Titre de décision coupé | « Titre coupé à 80 caractères. La définition entière est dans <chemin relatif du registre>. » (le titre se termine par « … ») |
| Source | « Lu dans <chemin relatif> » ; copie : « Copier le chemin : <chemin> », retour « Copié » |
| Confirmation destructive | sans objet : aucune action destructive, aucune écriture (hors périmètre) |

**Mots anglais ou littéraux hors français courant affichés, classés** (le garde d'inventaire du français du cockpit, `vf-cockpit-fr-inventaire.mjs`, relève
tout mot ASCII de trois lettres ou plus sans marque de français ; la zone de données du lab n'y entre pas) :

| Classe | Mots | Traitement |
|--------|------|------------|
| A. Donnée du lab rendue en texte (hors garde, jamais en HTML) | statuts lus (« Complete » quand il est lu comme valeur, « Pending », « passed », « Terminé »…), titres d'exigence, d'ADR et de décision, sujets de commit, `name` et noms d'agent, identifiants (TRAC-01, ADR-075, P41-D-02), noms de fichier et chemins | `textContent` ; rien à inscrire |
| B. Littéral de l'interface, nom propre du lab | SUMMARY, VERIFICATION (noms de fichiers du lab), « Complete » (valeur de statut testée par la cause « Complete, sans plan »), « requirements » (nom de champ), CONTEXT (nom de fichier), HEAD (terme git), « commit », « git », « ADR » (sigle), Pnn-D-nn, ADR-nnn, `docs/ADR.md`, `MEMORY.md`, `.claude/agent-memory/` | à **inscrire au fichier d'exclusions du garde** (`vf-cockpit-fr-exclusions.json`) avec sa raison (« nom propre du lab, identique dans les deux langues ») ; chaque littéral du copy est listé ici, aucun autre n'est admis |
| C. Remplacé par du français | « ledger » devient « registre des exigences » ; « Retour : <titre> » est fourni par la Phase 80 | aucun mot anglais restant dans le copy de la 76 |

## 11. Responsive : 1440, 1024, 390 px

Le panneau d'objet est le `#panel` du moteur ; la 76 ne change ni sa position, ni sa taille, ni son `z-index`. Un panneau
latéral ne pousse jamais la carte (Q12).

| Largeur | Comportement du panneau | Ce que la 76 vérifie |
|---------|-------------------------|----------------------|
| 1440 px | colonne de 360 px à droite (`--panel-w`, redimensionnable de 300 à 720 px ; largeur utile de ligne **308 px**, **248 px au plancher de 300 px**, barre de défilement de 12 px comptée) | section de phase : 5 lignes, 888 px de haut au pire, repli fermé, calculé à 248 px (§ 2.3) ; identifiant jamais coupé ; gabarits sans retranchement (§ 2.4) ; carte non poussée |
| 1024 px (souris ≥ 1000 px) | même colonne de 360 px ; il reste ≥ 280 px de carte visible | idem ; aucun défilement horizontal |
| 768 px et 700 à 999 px | colonne de 360 px conservée (sauf tactile), carte réduite | cibles 44 px si `pointer: coarse` ; aucune largeur fixe de ligne |
| 390 px (≤ 700 px) | feuille basse : `left/right 8 px`, hauteur max `min(56vh, 480px)`, défilement dans la feuille | largeur utile 322 px (252 px à 320 px de large) ; **section de phase : 3 lignes, texte sur 1 ligne, 614 px au pire, borne et non garantie de tenir dans la feuille (§ 2.3)**, qui défile avec la feuille, après le contenu existant que l'entrée haute (≤ 112 px) permet de sauter ; sections de la vue d'ensemble repliées ; lignes et boutons ≥ 44 px ; pagination en boutons 44 px ; aucun défilement horizontal |

Largeur de panneau redimensionnée par l'utilisateur : toute ligne reste fluide (`min-width: 0`, `overflow-wrap: anywhere`, aucune
largeur fixe en px sur un texte). Cibles tactiles ≥ 44 px dans `@media (max-width: 700px), (pointer: coarse)` (lignes,
`.vf-trace-commit`, `.vf-trace-plus`, `summary`, boutons de pagination, puces de plan, **`.vf-ref` (`min-height: 44px`)**). Mouvement : aucune animation
neuve (le moteur anime déjà l'entrée du panneau, `panelIn`, avec sa variante mouvement réduit) ; pliage de `details` sans
transition.

## 12. À Samuel : rien en attente, deux arbitrages rendus

Aucune question en attente. Les deux questions de la première version sont **tranchées** (format C76-Q1 du CONTEXT : P76-Q-01 et
P76-Q-02) :
- **A-1, « Les trous en rouge » face à Q9** : P76-D-32, arbitrage Samuel, AskUserQuestion session principale, 2026-11-11, option
  « Marque neutre ». Une absence se dit par un glyphe et un mot, sans couleur ; seule une contradiction réellement lue prend un
  octogone au trait corail (§ 1, § 10).
- **A-2, « graphe navigable » sans dessin** : P76-D-33, arbitrage Samuel, AskUserQuestion session principale, 2026-11-11, option
  « Panneaux reliés ». Un clic sur un objet ouvre l'objet voisin (l'exigence ouvre son plan, sa décision, sa preuve), avec un seul
  bouton Retour ; ni canevas ni quatrième onglet (§ 0, § 5.1).

Aucune question de goût pur n'est ouverte. Décisions de détail prises, toutes **décisions déléguées par Samuel (message session
principale, 2026-11-08), option recommandée**, à challenger par `vf-design-judge` : famille de formes carrés et octogone au trait à
carré central (§ 1.1, décision du manager) ; « lu » neutre ; section en fin de panneau avec entrée haute et résumé court (§ 2) ;
seuils de 5 et 3 lignes et budget sommé (§ 2.3) ; aucun fil d'Ariane, Retour unique de la 80 (§ 0, § 5) ; « non cochée, SUMMARY
lu » neutre (§ 10) ; un seul octogone pour les trois contradictions de mémoire, distinguées par leur emplacement (§ 1.3) ; rayon
`--r-ctl` partout (§ Spacing) ; blocs « Décisions citées » et « Preuves » sans glyphe, positionnés sur la preuve (§ 5.1, § 6) ;
bilans de 12,5 px à clamp 3 (phase) ou 4 (vue d'ensemble) (§ 2.4) ; gabarits fermés pour toute ligne de liste, bilan et résumé, plafond « 9 999+ » (§ 2.4) ; légende des glyphes en teinte neutre (§ 2.2) ; règle d'empilement unique attribuée par mécanisme de départ (§ 0) ; pagination sur deux lignes fixes, puces de plan plafonnées à 3 (§ 2.4) ; largeurs utiles comptant la barre de défilement de 12 px (§ 2.3) ; section en fin de panneau, un seul chemin d'empilement (§ 0).

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
   l'octogone dans la bande (SUMMARY ou plan) ; légende des glyphes visible en permanence.
5. Section de phase : 5 lignes (3 sous 700 px), lignes à trou d'abord, « + N autres exigences » (`height: 32px`) ; clamps explicites
   (bilan 3, légende 4, ligne 1 : 2 ou 1, mot 2, mention et compte 2) calculés sur le pire cas à 248 px (barre de défilement comptée) ; hauteur 888 px bureau
   et 614 px feuille au pire, sommée exactement (§ 2.3) ; repli « Preuves attachées » ouvert plafonné à 6 lignes (4 sous 700 px), sans
   critères de plan ; contenu existant du panneau non déplacé ; entrée haute d'une ligne qui mène à la section.
6. Nom accessible d'une ligne d'exigence : texte visible contenu dans le nom, puis états des maillons ; niveau dit une seule fois par
   surface (§ 1.2) : nom accessible complet de la ligne qui dit chaque niveau une fois (texte masqué par défaut, mention visible seulement si elle est la première et, alors, texte masqué sans niveau pour les maillons qu'elle nomme), « Chaîne »
   seule dans le panneau, « Preuves » (ligne 2) sans niveau ; « niveau phase » et « niveau exigence » expliqués.
7. Mémoire : seuls les chemins « cite un chemin absent », relatifs ; jamais `description` ni corps ; trois contradictions
   distinguées par emplacement et mot ; bilan cohérent (hors index compté) ; aucun mot « périmée ».
8. Quatre tailles de texte seulement, **briques réemployées comprises** (surcharges `.btn.soft`, `.vf-ref code`, `.vf-copie-etat`,
   `.vst`, § Typography) ; hauteur unique des boutons de la 76 (32 px, 44 px tactile) ; un style de `summary` par rôle ; chaque nombre
   avec son unité ; chaque glyphe avec son mot.
8ter. Gabarits fermés (§ 2.4) : aucune ligne de liste, aucun bilan, aucun résumé n'énumère un nombre libre d'états ; pire cas calculé
   sur le gabarit rempli aux plafonds (« 9 999+ ») à 248 et 308 px, réserve de 15 % sur la dernière ligne ; budget de § 2.3 qui somme exactement (888 / 614 px, repli
   fermé), borne et non garantie sur la feuille ; tout texte coupé lisible en entier
   ailleurs (§ 2.4) ; chaque élément nommé a une seule taille, une seule graisse (§ Typography) ; surcharges des briques
   réemployées dont `.vf-ref` (rayon `--r-ctl`).
8quater. Panneau d'exigence (§ 5.1) : « Décisions citées » (liste, « aucune décision citée » neutre, décision nue non reliée) et
   « Preuves » (lignes positionnées dans le panneau des preuves, contenu jamais rendu) ; le panneau quitté est empilé une seule fois, par la pile
   commune (nœud quitté par `select`/`reveal`) ou par la 76 (panneau sur mesure, ou nœud quitté par `SC.showPanel`) ; un Retour ramène au
   panneau quitté en une pression ; aucun glyphe répété ni neuf dans ces deux blocs.
8bis. Décompte (§ 10.1) : bilans à catégories exclusives dont la somme égale le total ; « chaîne complète » seulement si les quatre
   maillons sont lus ; « non lisible » compté et nommé dans les bilans et le « Jalon » ; un emplacement par cause et par surface
   (§ 10) ; mention neutre du niveau phase ; chips de plan interactifs (focus `--ring`, survol, 44 px tactile).
8sexies. Éléments à longueur variable (§ 2.4) : pagination sur deux lignes fixes, « + N » nowrap plafonné, puces de plan ≤ 3 avec renvoi,
   titre empilé ≤ 40 caractères ; `.vf-ref` : `min-height: 44px` tactile, `code` nowrap avec ellipsis, « Copié » dans la rangée flex ; paires
   glyphe et mot en `inline-flex` calé sur la première ligne du mot (§ 1.1) ; ligne 1 du Jalon comptée à 21 px.
8quinquies. Légende des glyphes neutre (seule exception à l'octogone corail) ; mots anglais affichés tous classés (§ Copywriting :
   A donnée, B littéral inscrit au garde, C remplacé) ; coupe de titre visible (« … ») et dite dans le panneau ; interlignes déclarés ;
   éléments des § 5.2 à § 5.5 présents dans le tableau de typographie.
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
- **Clamp du bouton « Retour : <titre> » de la 80** : le titre est borné à 40 caractères par la 76 ; vérifier que le bouton de la 80 le tient sur une ligne ou le clampe (aucune hypothèse écrite ici).
- Numéro du ou des fichiers `ui/7x-vf-trace*.js` et poids de chaque fichier (≤ 300 lignes, gate V4).
- Que la carte de phase en couloirs de la 80 ouvre le même panneau, section « Traçabilité » comprise (P80-C76-1).
- **Contrôle au rendu** : un manque doit se repérer **sans lire les mots** (le « lu » plein est plus saillant que le « manque » vide :
  vérifier que la bande se lit d'un coup d'œil, en niveaux de gris aussi) ; si le plein domine trop, revoir l'épaisseur du carré plein
  (10 px) avant de changer de forme.
- **Octogone** : à 1x et en niveaux de gris, il doit se distinguer d'« anneau et point » (à recetter) et d'« anneau barré » (bloqué) ;
  sinon, chanfreins plus nets : `<path d='M6 1.8h4l4.2 4.2v4L10 14.2H6L1.8 10V6z' fill='none' stroke='black' stroke-width='1.75'
  stroke-linejoin='round'/><rect x='6' y='6' width='4' height='4' rx='1' fill='black'/>` (tracé relu : chanfreins de 4,2 px, carré central
  de 4 px à plus de 2 px du trait).
- Que les clamps de § 2.3 et les gabarits de § 2.4 tiennent au rendu à 248 px et 308 px (largeurs utiles, barre de défilement de 12 px comptée : `::-webkit-scrollbar` forcé, **à contrôler aussi là où la barre est en surimpression**, où la largeur utile est de 260 px), pire cas rempli aux plafonds, et que le plafond de la feuille reste `min(56vh, 480px)`.
- Hauteur réelle de la section de phase à 1440 et 390 px (mesure au rendu : 888 px et 614 px annoncés  § 2.3  repli fermé ; 1 306 px et 968 px repli ouvert).

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


## Mineurs fermés à l'exécution (2026-11-13)

Huit mineurs du juge de design du tour 6 (92/100), fermés par le craft d'exécution avant les plans d'interface 76-06 et 76-07
(P76-D-26). Aucune décision P76-D-NN rouverte, ni forme, ni données, ni navigation. Une passe, sans juge ici (un juge de design passe
sur captures à la fin de la phase).

| N | Mineur | Correction | § touché |
|---|--------|------------|----------|
| 1 | Niveau dit deux fois dans le nom accessible d'une ligne | Le nom complet (texte visible puis texte masqué) dit chaque niveau une fois : la mention visible de niveau, quand elle est la première, porte le niveau des maillons qu'elle nomme ; le texte masqué les écrit sans niveau | § 1.2, § 2.2 (nom accessible), § 14.6 |
| 2 | Une phrase d'empilement du § 5.1 qui disait « l'exigence a été empilée à son arrivée » | Remplacée par la règle unique : chaque panneau quitté est empilé une fois, par celui qui le quitte ; aucun appel à l'arrivée | § 5.1 (ouverture des voisins) |
| 3 | Hauteur réelle de `.vf-ref` dans le budget du repli de preuves | `.vf-ref` compté à 32 px (44 px feuille et tactile) ; ligne de preuve 60 / 72 px au lieu de 52 ; repli ouvert 418 / 354 px, section ouverte 1 306 / 968 px (1 414 px tactile) | § 2.3, § 15 |
| 4 | Surcharge `line-height` de `.tag` et écart de pagination | `.vf-trace .tag { line-height: 16px }` (pastille de 20 px) ; pagination : `row-gap` et `margin-top` de `--sp-8` déclarés, 72 = 32 + 8 + 32 | § Typography (surcharges, interlignes), § 2.4 |
| 5 | Gabarit des lignes du § 5.4 | Tableau fermé : titre clampé à 3 lignes, fiche en grille de deux colonnes, lien sortant (52 px), lien entrant (34 px), chemin absent (66 px, ligne 2 sous le chemin), pied de source | § 5.4 |
| 6 | Deux graisses pour `.vf-trace-plus` | Une seule : 500 (comme § 7) ; `.btn.soft` reste à 400 dans sa propre ligne du tableau | § Typography |
| 7 | Taille de « Lecture bornée » | Message entier de § 9 partout, 11,5 px/16, 400, `--text-3`, clamp 3, 8 px d'écart ; ligne ajoutée au tableau des gabarits | § 5.5, § 9, § 2.4, § Typography |
| 8 | Alignement des paires glyphe-mot sur deux lignes | `align-items: flex-start`, glyphe sur la première ligne (décalage optique de 1 px devant un mot de 18 px) ; paires de la légende en `nowrap` | § 1.1, § 14.8sexies |
