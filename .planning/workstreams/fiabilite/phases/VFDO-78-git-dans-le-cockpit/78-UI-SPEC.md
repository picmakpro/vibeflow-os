# Phase 78 : Git dans le cockpit — UI-SPEC (craft-git)

**Contrat de design** pour l'en-tête, le bloc de vue et le tiroir Git. Direction « Graphite » (`DESIGN.md`).
Sources lues : `78-CONTEXT.md` (P78-D-01..19), `viewer.html` (`:root` l. 33-64, thème clair, `#context` l. 145-152,
`#zoom` l. 241, `#panel` l. 315, media l. 481-545, clavier l. 2281-2297), `vf-cockpit-terminal-tiroir*.mjs`.
Aucune brique externe de craft consultée : dégradation sur les premiers principes (contraste WCAG, grille 2 px, hiérarchie).
Tout texte venu de git s'écrit en `textContent`. Libellés en français, espace insécable avant `: ; ! ?`, aucun tiret
cadratin dans le copy. Classes neuves en `vf-git-*`, dans un fichier `ui/*vf*` ou la feuille du module (jamais dans le moteur,
sauf les 3 points d'accroche listés §9, à tracer dans `VENDORED.txt`).

## 1. En-tête

**Structure.** `.brand` garde `.mark` (22 px) puis un bloc `.vf-nom` (colonne, `min-width:0`, `gap:0`) :
ligne 1 `#proj-name` (inchangé : 13,5 px, 600, `-.01em`, `--text`), ligne 2 `button.vf-git-ligne` (seconde ligne).
Hauteur : 18 + 16 px, tient dans les 64 px de l'en-tête ; `.hl` centre déjà verticalement, les onglets `.vf-tabs` restent alignés.
Le nom vaut le dossier du dépôt principal, identique sur Code, Projet, Équipe (P78-D-01).

**Seconde ligne.** Texte `branche · worktree nom-du-worktree`, le worktree seulement hors arbre principal.
- Typo : `--mono`, 11 px, 500 (échelle « Petit » 11-11,5 px), `--text-3`, interlettrage 0, pas de pastille ni d'icône.
- Boîte : `inline-flex`, `padding: 2px 6px` (6 px = `#crumbs`/`.vf-link`), `margin-left` négatif égal au padding (6 px) pour que le texte
  s'aligne sur le nom, `border-radius: 999px`, fond transparent, `border:0`, `cursor:pointer`.
- Troncature : `max-width: 220px` (valeur de `#crumbs button`). Deux `span` : branche (`flex: 0 1 auto`) et worktree (`flex: 0 2 auto`),
  `overflow:hidden; text-overflow:ellipsis; white-space:nowrap` : le worktree rétrécit d'abord. `title` = texte complet.
  `#proj-name` reçoit la même troncature (`max-width: 220px`, ellipsis), nom entier dans `title`.
- Branche détachée : `HEAD détaché · a1b2c3d` (sha court en mono), couleur `--warn-text`.
- Dépôt détecté mais lecture en échec : `Branche indisponible`, `--text-4`, l'ouvreur reste actif (l'erreur se lit dans le tiroir).

**États.**
| État | Rendu |
|---|---|
| repos | `--text-3`, fond transparent |
| survol | fond `rgba(var(--ink), .06)`, texte `--text`, `.kbd` « g » apparaît à droite (`opacity 0→1`, 150 ms `--ease`, `margin-left: 6px`) |
| focus clavier | `outline: 2px solid var(--ring); outline-offset: 2px`, `.kbd` visible |
| ouvert (`aria-expanded=true`) | fond `rgba(var(--ink), .1)`, texte `--text` |
| actif (clic) | pas d'échelle, fond `.1` |
| git absent ou hors dépôt | l'élément n'existe pas dans le DOM (pas masqué) ; `#proj-name` seul, l'en-tête est identique à aujourd'hui |

`aria-label` : « Historique Git, branche feat/phase-78. Ouvrir (g) », `aria-controls` = id du tiroir, `aria-expanded` tenu à jour.

## 2. Bloc de vue racine (`renderContext`)

Même gabarit qu'aujourd'hui, aucune règle CSS modifiée : `.k` (12,5 px, `--text-3`) = surtitre ; `h1` (24 px, 600, `-.025em`) = titre ;
`p` (14 px, `--text-2`) = sous-titre. Plus de nom de projet. Le titre se limite à deux lignes (`-webkit-line-clamp: 2`, classe neuve
sur le h1, `overflow-wrap:anywhere`). Sous-vues et réponses (`q:answer`) inchangées. Pas de pastille icône à la racine.

| Onglet | Surtitre | Titre | Sous-titre (exemples) |
|---|---|---|---|
| Code | Code | Le code, branche feat/phase-78 | 128 modules et 31 routes lus dans le dépôt. |
| Code sans git | Code | Le code du projet | 128 modules et 31 routes lus dans le dossier. |
| Projet | Projet | Jalon vibeflow-v2.0 | Phase 78 en cours, 4 phases faites sur 12. |
| Équipe | Équipe | Mission : Phase 78, Git dans le cockpit | 3 agents au travail, 1 en attente. |
| Équipe sans mission | Équipe | Aucune mission en cours | L'équipe est au repos. |

Le sous-titre est un résumé de ce que la vue montre (chiffres déjà connus du moteur), jamais une phrase d'accueil. Suffixes
« — Projet » / « — Équipe » et liste « Repositories » retirés (P78-D-09).

## 3. Tiroir Git

**Surface.** `<aside class="vf-git-tiroir glass" role="complementary" aria-label="Historique Git" id="vf-git-tiroir">`, `position: fixed`,
`left: 16px; top: calc(var(--hh, 64px) + 4px)` (mêmes décalages que `#panel`), `width: 360px` (dimension, pas jeton : `--panel-w`
est redimensionnable par l'utilisateur à droite, ne pas la lier), `border-radius: var(--r-panel)`, `z-index: 7`, `overflow: hidden`
(colonne flex : barre fixe puis corps `overflow-y: auto`). Il se pose au-dessus du plan sans le pousser (DESIGN §5).
`bottom` : voir §4.

**Ouverture / fermeture.** Ouvrir : clic sur la seconde ligne (ou l'icône mobile), touche `g`. Fermer : même clic, `g`, bouton ✕ de la
barre, Échap. Entrée : `animation: vf-git-entree 250ms var(--ease) both`, `translateX(-16px)` + opacité, sortie immédiate
(`hidden`), comme le tiroir Terminal ; variante `prefers-reduced-motion: reduce` sans animation. Ouvrir ajoute `body.vf-git-ouvert` :
`#context` passe à `opacity: 0` (même geste que `body.in-flow #context`, transition .3 s existante), car `#context` vit à
`left: 24px` sous le tiroir. Fermer le retire. L'état ouvert n'est pas mémorisé entre deux chargements.
`g` ignoré si : cible INPUT, TEXTAREA ou contenteditable, palette ouverte, modificateur (Ctrl, Alt, Meta) enfoncé, ouvreur absent.

**Barre du tiroir** (hauteur 36 px, `padding: 0 8px 0 14px`, fond `--raise`, filet bas `1px solid var(--hair)`, copie de `.vf-term-barre`) :
titre « Historique Git » (13 px, 500, `--text`), puis `margin-left:auto` bouton ✕ 28×28 (`.vf-term-bouton`, rayon 8, icône `svg.i`).
Sous la barre, une ligne d'aide : « Lecture seule. Chaque action est une commande à copier. » (12 px, `--text-3`, `padding: 8px 14px`).

**Corps** : `padding: 0 14px 16px`, sections séparées par `margin-top: 12px`. Titre de section = bouton pleine largeur
(`aria-expanded`), 11,5 px, 600, `.02em`, `--text-3`, compteur à droite dans une pilule `.meta` (existante) ; chevron `svg.i`
qui pivote (200 ms `--ease`). **Ordre** : 1 Worktrees (ouverte), 2 Graphe (ouverte), 3 Tags, 4 Stash, 5 Auteurs et activité
(fermées, compteur visible). Section sans donnée : masquée, sauf Graphe (état vide).

**Worktrees.** Une ligne par worktree, fond `--raise`, `--r-ctl`, `padding: 8px 10px`, `gap: 4px`.
Ligne 1 : nom du dossier (mono 12,5 px, 500, `--text`, ellipsis) ; pilule « ici » pour l'arbre courant (10,5 px, 600, `--on` / `--on-text`).
Ligne 2 : branche (mono 11,5 px, `--text-3`) puis pastilles d'état, pilule 11 px/500 `padding: 2px 8px` :
« 3 modifiés » `--warn-text` sur `--warn-bg` ; « 2 non suivis » `--text-2` sur `rgba(var(--ink), .06)` ; « ↑2 ↓1 » mono `--text-2`
(avance, retard sur la base) ; « propre » `--ok-text` sur `--ok-bg`. Jamais la couleur seule : le texte dit l'état.
Bouton de commande `cd -- '<chemin>'` sous la ligne 2 (§ commandes).

**Graphe** (rangée = un commit, `<ol role="listbox" aria-label="Commits">`, `<li role="option">`).
- Géométrie : colonne graphe en SVG `aria-hidden`, une rangée = 40 px (44 px en `pointer: coarse`, valeur de `header .btn` tactile),
  pas de couloir 16 px, nœud 8 px de diamètre (`r=4`, comme `.vf-term-etat-point`), trait 1,75 (comme `svg.i`), extrémités arrondies.
  Fourches et fusions : courbe en quart de cercle de rayon 16, jamais d'angle droit. 6 couloirs visibles au plus ; au-delà, les
  couloirs excédentaires se replient sur le dernier et un « +N » (mono 10,5 px, `--text-4`) clôt la colonne.
- Couleurs (stroke/fill du nœud et du trait, une couleur par couloir, attribuée à la branche et stable) : couloir de la branche
  par défaut `--text-3` ; couloirs suivants, par rang, `--k-http`, `--k-call`, `--k-data`, `--k-event`, `--k-queue` (cycle).
  Branche distante connue : même couleur que sa locale, trait en tirets (`stroke-dasharray`, géométrie). Commit courant (HEAD) : nœud
  plein `--text` avec anneau 1,5 px `--ring`. Commit de fusion : nœud creux (fond `--surface`, contour couleur). Le sens ne repose
  jamais sur la couleur seule : tirets pour distant, nœud creux pour fusion, étiquettes de texte pour les noms.
- Texte de la rangée : ligne 1 message (12,5 px, 400, `--text`, 1 ligne, ellipsis), étiquettes de refs avant le message sur le commit
  qui les porte ; ligne 2 `a1b2c3d · Prénom Nom · il y a 2 h` (11,5 px, `--text-3`, sha en mono). `title` = date complète.
- Étiquettes de refs (pilules 999 px, mono 11 px, 500, `padding: 2px 8px`, `max-width: 140px`, ellipsis) : branche locale
  `rgba(var(--ink), .06)` + `--text-2` ; courante `--on` + `--on-text` ; distante contour `1px solid var(--hair-2)` + `--text-3`
  (préfixe `origin/`) ; tag fond `--raise` + `--text-2` + glyphe « tag » 12×12 ; branche portée par un worktree : glyphe « dossier ».
  Plus de 2 étiquettes sur une rangée : les deux premières, puis « +3 » (pilule `.meta`) dont le `title` liste le reste.
- Repli des mergées : en pied de graphe, un bouton « 12 branches mergées » (`aria-expanded`, replié par défaut) ; déplié, une liste de
  noms (mono 11,5 px, `--text-3`) avec leur bouton de commande `git branch -d '<nom>'`. Leurs commits ne sont pas tracés.
- Bornes : « 60 derniers commits affichés. » (11,5 px, `--text-4`) en pied. Pas de pagination, pas de « voir plus ».
- Survol de rangée : fond `rgba(var(--ink), .06)` ; sélection : `box-shadow: inset 0 0 0 1.5px rgba(var(--ink), .5)`
  (forme de `.node.sel .card`) et fond `--surface-hover`. Rayon de rangée `--r-ctl`.

**Détail d'un commit.** Sélection (clic, Entrée, Espace) déplie le détail **sous la rangée**, dans la colonne (pas de panneau voisin,
pas de saut de mise en page : le défilement garde la rangée en haut). Bloc `--raise`, `--r-ctl`, `padding: 10px 12px`, `gap: 8px`.
Contenu : message complet (13 px, `--text`, `white-space: pre-wrap`, sujet en 600) ; auteur + date longue (« 5 nov. 2026, 14 h 32 »,
12 px, `--text-3`) ; sha complet (mono 11,5 px, sélectionnable) ; « Fichiers (7) » puis liste (mono 11,5 px, chemin en ellipsis à gauche
du compteur) avec `+12` en `--ok-text` et `−3` en `--err-text` (le signe est dans le texte, tabular-nums) ; bornée à 30 fichiers
puis « et 14 autres ». Pas de diff. Commandes : `git show --stat --end-of-options <sha>`, `git switch --detach --end-of-options <sha>` (texte exact : celui produit par `vf-cockpit-git-commandes.mjs`, 78-03). Un second clic ou Échap
(focus dans la rangée) replie ; un seul détail ouvert à la fois.

**Tags / Stash / Auteurs.** Lignes denses (`padding: 6px 10px`, rayon `--r-ctl`, survol `.06`) : tag = nom mono + sha court + date ;
stash = `stash@{0}` mono + message + branche d'origine + date, commande `git stash show --stat 'stash@{0}'` ; auteurs : nom,
nombre de commits, barre `.vf-bar` (6 px, piste `--raise-2`, remplissage `--text-3`) proportionnelle au plus actif, puis sous-liste
« Par branche — avance sur la base » (P78-D-40, plus de fenêtre de 30 jours) : nom mono, nombre de commits d'avance sur la base, dernier commit relatif. Pas d'e-mail affiché.

**Commandes à copier.** Rangée `.vf-git-cmd` : `--well` en fond, `--r-ctl`, `padding: 4px 4px 4px 10px`, `gap: 6px`, `min-height: 28px`
(44 px tactile). `<code>` mono 11,5 px `--text-2`, 1 ligne, ellipsis, `title` = commande complète, sélectionnable ; à droite un bouton
28×28 (`.vf-term-bouton`, rayon 8, icône copie, `aria-label` « Copier la commande : git switch --end-of-options 'feat/x' »). Retour : l'icône devient une
coche `--ok` pendant 1,6 s, la rangée affiche « Copiée » en place du bouton-texte (11,5 px, `--ok-text`), annonce
`aria-live="polite"` « Commande copiée ». Échec de l'API presse-papiers : le `<code>` est sélectionné et la rangée dit « Copie
impossible, commande sélectionnée » en `--warn-text`. Jamais d'exécution, jamais de lien actif, jamais de HTML injecté.

**États du tiroir.**
- Chargement (au-delà de 150 ms pour éviter le clignotement) : `aria-busy="true"`, trois blocs `--raise` de 40 px (rangées fantômes),
  sans animation de balayage, texte « Lecture du dépôt » (`--text-3`) pour lecteur d'écran et pour l'œil.
- Vide (dépôt sans commit) : titre 15 px/600 « Aucun commit pour l'instant », ligne 12,5 px `--text-3` « Le dépôt existe mais son
  historique est vide. », commande `git commit` en `.vf-git-cmd` (« git commit -m "premier commit" »).
- Indisponible (erreur ou borne dépassée) : carte `--warn-bg`, `--r-ctl`, `padding: 10px 12px`, titre « Git est indisponible »
  (13 px, 600, `--warn-text`), cause courte (12 px, `--text-2`) « La lecture du dépôt a échoué ou dépassé le délai. », bouton
  « Réessayer » (`.btn.soft`, GET de lecture) et commande de diagnostic `git status`. Une section isolée en échec dit
  « Indisponible » (`--text-3`) avec « Réessayer » ; le reste du tiroir continue.
- Rafraîchissement par le flux (signature HEAD et refs) : le contenu se remplace sans fondu, la sélection et le défilement sont
  conservés par sha ; sélection disparue, le détail se replie ; annonce `aria-live` « Historique mis à jour » (une fois par rafale).

## 4. Coexistence : Terminal, zoom, panneau de détails

```
+--------------------------------------------------------------+ z10
| [logo] vibeflow-os   [Code|Projet|Équipe]  [Recherche]  [..] |  header 64 px
|        feat/x                                                |
+------------+----------------------------------+--------------+
| TIROIR GIT |  plan (canevas, non poussé)      |  #panel      | z5
| z7, 360 px |  #context masqué tiroir ouvert   |  détails     |
| left 16    |                                  |  360 px      |
|            |                                  |              |
+------------+  bottom du tiroir = au-dessus de |              |
| [pastille] |  la pastille, du zoom et du      |              |
| [zoom   ]  |  tiroir Terminal                 |              |
+------------+----------------------------------+--------------+
| TIROIR TERMINAL (bas, left 16, right max(16, --pw)) z8       |
+--------------------------------------------------------------+
```
- Pile : en-tête 10, Terminal 8, Git 7, pastille/puce Terminal 6, `#panel` 5. Le Terminal en état « plein » recouvre le tiroir Git, qui
  réapparaît à la sortie du plein ; son ouvreur reste utilisable.
- `bottom` du tiroir Git : repli CSS `calc(var(--vf-term-reserve, 0px) + 16px)` (le Terminal ouvert réserve `h + 28`). Puis le même
  geste que P71-D-34 (`eviter`, `vf-cockpit-terminal-tiroir.mjs:47`) : un script mesure `#zoom` et la pastille/puce Terminal ; s'ils
  recouvrent le tiroir, `bottom = innerHeight − min(top) + 8` px ; recalcul au `resize`, à l'ouverture et à l'ouverture/fermeture du Terminal.
- Largeur : 360 px + 16 px de marge de chaque côté ; `#panel` (360 px à droite) laisse au moins 280 px de plan à 1 000 px de large.
- Zoom, `Échap`, `f`, `p`, `+`, `-` continuent de marcher tiroir ouvert. `#ask` reste en place sur bureau.

## 5. Mobile (< 1 000 px, ou tactile < 1 280 px)

- **Seconde ligne** : masquée avec `#proj-name` par la règle existante (`viewer.html:491`, P78-D-19). Elle n'est pas perdue :
  l'ouvreur devient un bouton **icône 44×44** (`.btn.icon`, glyphe branche `svg.i`) dans `.hr`, avant les autres, visible
  seulement sous cette requête (caché au-dessus). Il porte la branche dans son `aria-label` et `title`. Sans git : absent.
- **Tiroir** : `left: 8px; right: 8px; width: auto; bottom: 8px` (même schéma que le tiroir Terminal mobile) ; sous 700 px
  `top: calc(var(--hh, 56px) + 4px)`. Il recouvre la pastille Terminal et la barre `#ask` (masquée tiroir ouvert, comme
  `body.vf-term-ouvert #ask`) ; pas d'évitement du zoom (le zoom est en haut en mobile). Rangée de graphe 44 px, boutons 44×44,
  sections inchangées. Pas de touche `g` (inutile au tactile, tolérée au clavier externe).
- Détail du commit : sous la rangée, comme sur bureau ; le tiroir défile, jamais la page.
- Mise en page vérifiée à 375, 700, 768 et 1 000 px, sans défilement horizontal.

## 6. Accessibilité

- Contraste ≥ 4,5:1 pour tout texte dans les deux thèmes ; éléments graphiques du graphe ≥ 3:1 sur `--elev` (à mesurer pour
  `--k-*` et `--text-3`, §8). `--text-4` n'est réservé qu'à du texte non essentiel (compteurs « +N », bornes), avec doublon d'information
  dans `title` / texte lisible.
- Clavier : `Tab` atteint ouvreur, ✕, titres de section, rangée active du graphe (tabindex itinérant : une seule rangée dans l'ordre de
  tabulation), boutons de copie, « Réessayer ». Dans le graphe : ↑ ↓ déplacent, Début / Fin, Entrée ou Espace ouvre le détail,
  Échap le replie. Dans les sections : Entrée / Espace plient. Le focus visible : `outline: 2px solid var(--ring)`, `outline-offset: -2px`
  sur les éléments dans le tiroir, `2px` sur l'ouvreur.
- Échap : priorité aux surcouches (palette, menus, modales), puis le tiroir Git (focus dans le tiroir ou sur l'ouvreur), puis le
  comportement actuel (feuille, parcours, sélection, remonter). Ouvrir déplace le focus sur le titre du tiroir (`tabindex=-1`) ; fermer
  le rend à l'ouvreur (ou à l'icône mobile). Pas de piège à focus : le tiroir n'est pas une modale.
- Rôles : `complementary` + `aria-label` ; `listbox` / `option` + `aria-selected` pour les commits, `aria-label` de rangée
  « a1b2c3d, Message, branche feat/x, il y a 2 h » ; sections en `button aria-expanded` + `region` nommée ; `aria-busy` au chargement ;
  une région `aria-live="polite"` unique (hors tiroir fermé) pour copie et mise à jour. Le SVG du graphe est `aria-hidden`.
- Cibles tactiles ≥ 44 px (rangées, boutons, ouvreur mobile). Mouvement réduit : aucune animation d'entrée, pivot du chevron instantané.

## 7. Variables CSS utilisées (toutes existantes)

| Variable | Usage |
|---|---|
| `--sans`, `--mono` | texte ; branches, refs, sha, chemins, commandes |
| `--hh` | décalage haut du tiroir (avec repli 64 px) |
| `--vf-term-reserve` | réserve basse quand le Terminal est ouvert (variable du tiroir Terminal) |
| `--pw` | lecture seule, jamais modifiée |
| `--elev`, `--shadow-float` (via `.glass`) | fond et ombre du tiroir |
| `--r-panel`, `--r-ctl` | tiroir ; rangées, blocs, cartes d'état |
| `--raise`, `--raise-2`, `--well`, `--surface`, `--surface-hover` | barre, worktrees, détail ; piste des barres ; fond des commandes ; nœud creux ; rangée sélectionnée |
| `--hair`, `--hair-2`, `--ink` | filets ; contour des refs distantes ; teintes `rgba(var(--ink), α)` de survol et de sélection |
| `--text`, `--text-2`, `--text-3`, `--text-4` | hiérarchie du texte |
| `--on`, `--on-text` | branche courante, pilule « ici » |
| `--ring` | focus, anneau du commit courant |
| `--ok`, `--ok-bg`, `--ok-text` | « propre », « copiée », `+n` |
| `--warn-bg`, `--warn-text` | modifiés, HEAD détaché, indisponible, copie impossible |
| `--err-text` | `−n` des fichiers |
| `--k-http`, `--k-call`, `--k-data`, `--k-event`, `--k-queue` | couloirs du graphe (cycle) |
| `--ease` | entrée du tiroir, chevron, `.kbd` |

Valeurs d'espacement déjà présentes dans le fichier, seules autorisées sur les éléments neufs : 2 (`.vf-tabs` gap), 4 (`.hl` gap, `#zoom`
padding), 6 (`#crumbs` / `.vf-link` padding), 8 (`.vf-term-barre` gap, `.meta` padding), 10 (`.brand` gap), 12 (`header` gap),
14 (`.vf-term-barre` padding gauche), 16 (`#panel right`, `.vf-term-tiroir left`) ; tailles 22 (`.mark`), 28 (`.vf-term-bouton`), 36
(`.btn`, `.vf-term-barre`), 40 (`#search-btn`), 44 (tactile), 220 (`#crumbs button`), 360 (`--panel-w`, valeur reprise en dimension).
Rien d'existant n'est modifié, hors les trois accroches de §9.

## 8. Ce que le juge de design doit vérifier

1. Aucune valeur en dur de couleur, d'espacement, de rayon : `grep` de la feuille contre §7, deux thèmes ; `--text-1` absent.
2. Seconde ligne : lisible mais discrète, affordance de survol et de focus visible, aucune pastille, troncature correcte (branche très
   longue, worktree long, HEAD détaché), nom identique sur les 3 onglets, en-tête inchangé sans git (capture témoin).
3. Bloc de vue : plus aucune répétition du nom ; hiérarchie surtitre / titre / sous-titre ; cas sans mission ; sous-vues intactes.
4. Graphe : couloirs distincts sans dépendre de la couleur seule ; contraste des traits ≥ 3:1 en clair comme en sombre (`--k-*`,
   `--text-3`) ; HEAD, fusion, distante, mergées repliées reconnaissables ; pas de bruit visuel au-delà de 6 couloirs.
5. Tiroir : cohérent avec `#panel` et le tiroir Terminal (verre, rayon, ombre) ; ni chevauchement du zoom, de la pastille ni du
   Terminal (ouvert, plein, fermé) ; `#context` masqué proprement ; à 1 000 px, `#panel` ouvert, il reste du plan visible.
6. Commandes : le bouton de copie est évident, le retour « Copiée » se voit, une commande hostile s'affiche telle quelle (texte).
7. États : chargement, vide, indisponible (global et par section), rafraîchissement sans perte de sélection.
8. Clavier et lecteur d'écran : parcours complet sans souris, Échap et retour du focus, rôles, annonces.
9. Mobile (375, 700, 768) : ouvreur icône 44 px, tiroir sans défilement horizontal, rangées 44 px, `#ask` rangé.
10. Anti-slop : monochrome, aucune couleur de marque ni dégradé, pas de tiret cadratin dans le copy, aucune police neuve.

## 9. Points de décision et accroches

- **P78-D-10 (en attente)** : clic sur la seconde ligne + `g` ; `g` libre aujourd'hui dans `viewer.html:2283-2297`.
- **Mobile** : D-19 masque la seconde ligne ; ce document ajoute une icône 44 px comme seul ouvreur (sinon le tiroir est
  inaccessible au tactile). À confirmer par le juge, c'est le seul écart à D-19.
- **Couloirs en `--k-*`** : famille « types de liens » réemployée faute de palette catégorielle ; si la Phase 71.5 refond `--k-*`, les
  couloirs suivent seuls ; une famille `--git-*` ne se crée qu'après elle.
- **Largeur 360 px en dimension** (pas de jeton dédié) ; à rapprocher d'un jeton si la 71.5 en pose un.
- **Accroches dans le moteur (3, à tracer dans `VENDORED.txt`)** : (a) `renderContext` : surtitre, titre, sous-titre par onglet ;
  (b) `.brand` : bloc `.vf-nom` autour de `#proj-name` (`viewer.html:584`, `2198`, `2206`) ; (c) `keydown` : touche `g` et priorité d'Échap.
  Tout le reste vit dans des fichiers `vf-git-*` / `ui/*vf*`.

> **Note du manager (2026-11-05).** Le texte des commandes à copier fait foi tel que le produit `vf-cockpit-git-commandes.mjs` (78-03, P78-D-14 : `--end-of-options`, citation shell) ; les exemples ci-dessus y ont été alignés.
