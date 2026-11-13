# 73-04 — modèle de la régie, sans DOM, et sa feuille (REGI-01, 02, 04, 05, 06, 07, 09, 10, 11, 14)

Trace du rouge : `73-04-RED-TRACE.md`. Base : 388c2856.

## Livré

- `ui/72-vf-regie-modele.js` (200 lignes, aucune ligne de plus de 160 points de code) : IIFE sans DOM ni réseau qui pose
  `window.__vfRegieModele = { modele, aVous, verrouBlanc, verrous, trierAVous, etatVivant }` ; lit `window.__vfEquipeRendu` à l'appel.
- `ui/72-vf-regie-style.js` (102 lignes) : feuille posée une fois par `document.head` ; masquage de `#stage`, `#zoom`, `#z-fit`, `#results`, `#crumbs` (« Vue d'ensemble »)
  sous `body.vf-tab-equipe.vf-regie-montee` seulement ; bloc de titre masqué sous `body.vf-regie-montee.vf-git-ouvert` ; jetons existants seuls ; aucun style de bouton
  (hauteur 44 px de `.btn` en `pointer: coarse`).
- `ui/71-vf-equipe-rendu.js` : `estOrphelin(w, parent)` (même expression que l'ancien garde, la ligne d'« orphe » l'appelle) ; exports ajoutés
  `GLYPHE_ETAT, MOT, estOrphelin, CALME_S, LONGUE_S, nommer`.
- `VENDORED.txt` : deux lignes `AJOUT` après `72-vf-equipe.js`. `tests/vm-regie.mjs`, `tests/regie-rg-modele.sh`.

## Forme du modèle (contrat pour 73-05, 73-06 et la Phase 74)

- `GLYPHE_ETAT` (Phase 74, P74-D-29) : export de `window.__vfEquipeRendu`, objet `{ actif: 'actif', 'en-attente': 'attente', 'au-repos': 'repos', attend: 'attend', termine: 'termine', bloque: 'bloque' }` ;
  le modèle ajoute `surveiller` et `orphelin` (clés de `GLYPHE` de 71, hors de cette table) : `attrs.etat` vaut toujours une de ces huit clés (une ligne de mission : `''`).
- `modele(who, lock, ctx)`, `ctx = { now, recuA (ms, comme Date.now), fenetre (secondes ou null ; absent : `who.fenetreStallS`), lus (null, tableau, Set ou objet dont les clés sont des identifiants),
  nonCommite ({ <branche>: n }, seulement pour une jointure établie), missions (noms, pour `titreEquipe`) }`. Rend
  `{ entete: { h1, sousTitre, verrouDepot: { texte, marques } | null }, sections: [4], etatPage }`.
- Section : `{ id ('a-vous', 'au-travail', 'a-relire', 'au-repos'), titre, aide, compte, vide, lignes, autres, autresTexte, relus, relusTitre, pied }`.
  `compte` compte les lignes d'agent et de phase, jamais les lignes de mission ; « Terminé, à relire » et « Au repos » : `compte` = total, `lignes` plafonnées à 8 et 6, `autres` le reste.
- Ligne : `cle (section:id), id, kind (session|subagent|phase|mission), nom, role, etat, mot, poids, detail, ligne2 (parties ordonnées), duree { prefixe, valeur }, action ('lire-rapport'|null),
  niveau (0 à 2), parent (id ou null), grise, noeud, lien, age, impact (n ou null), infobulle, attrs { agent, noeud, etat }` ; une ligne de mission porte en plus `marques [{ texte, glyphe, infobulle }]`.
- Classes que la feuille attend de 73-05 : `#vf-equipe`, `#vf-equipe-entete`, `.vf-rg-sec` (+ `.vf-rg-sec-avous`), `.vf-rg-tete`, `.vf-rg-compte`, `.vf-rg-aide`, `.vf-rg-corps`, `.vf-rg-vide`, `.vf-rg-pied`,
  `.vf-rg-lig` (+ `.vf-rg-n1`, `.vf-rg-n2`, `.vf-rg-grise`, `.vf-rg-sess`), `.vf-rg-row` (enfants directs : `svg.aw-g`, `.vf-rg-qui`, `.vf-rg-quoi`, `.vf-rg-dur`, `.vf-rg-act`), `.vf-rg-nom`, `.vf-rg-role`,
  `.vf-rg-l2`, `.vf-rg-det`, `.vf-rg-mot`, `.vf-rg-tog`, `.vf-rg-mission`, `.vf-rg-marque`, `.vf-rg-note`, `.vf-rg-source`, `.vf-rg-direct`, `.vf-rg-verrou`, `.vf-rg-sous` ; l'état se teinte par `data-vf-etat` sur la ligne.
- Règle A3 retenue : la ligne de mission et la ligne du verrou de dépôt disent « tenu depuis N min » (`leaseS`) puis « dernier signe il y a N min » (`ageS`) ; `leaseS` null : « dernier signe » seul.
  Le détenteur se nomme par la session collectée sauf si `sansSession` est vrai, sinon forme courte (8 premiers caractères d'un identifiant). La clé brute `lease_seconds` n'est lue que pour devenir `leaseS`.
- Les espaces insécables (avant « : », entre nombre et unité) sont dans le modèle ; les tests les lisent en espaces simples sauf RG9.8.

## Écarts

- Écart : `colonnes-baseline.txt` (hors `files_modified`) : 71-vf-equipe-rendu.js passe de 59 à 58 lignes longues (le garde d'orphelin de 178 colonnes devient un appel) ; baisse suivie, ligne seule.
- Écart : `test-cockpit-regie.sh` n'est pas dans la liste du plan mais joue les sections par le lanceur existant ; le témoin d'ordre RG0.10 construit un lab de fixture avec `vf-cockpit-build.mjs`, la sortie n'a que `index.html` et `project.html` (pas d'`equipe.html`).
- Écart : le garde d'orphelin de 71 couvre aussi un enfant dont la session parente se tait depuis plus de 30 min ; le détail « son parent est terminé » s'écrit alors pour ce cas aussi (même garde, P73-D-13).
- Écart : « attend ses agents » s'applique aux sessions ni `actif`, ni `termine`, ni `attend`, ni `bloque` (la collecte pose `en-attente` à ces sessions) ; elles figurent dans « Au travail », jamais dans « Au repos ».
- Écart : aucun mutant sur les règles de masquage et de bouton de la feuille (RG14.0 : témoin rouge seul, ce n'est pas une garde de non-fuite) ni sur le reste du modèle (régime allégé).
- Écart : T-73-16 (champs libres du verrou) : pas de recette complète de la classe « valeur à forme de chemin » (borne : début de chaîne, séparateur, lecteur ou partage) ; dit ici comme au plan.
- Écart : le modèle ne lit pas `dag` quand c'est un objet (plan publié) : seule une chaîne bornée à 200 passe ; l'impact vient de `retient` (serveur), jamais recalculé ici.
- Contrat voisin : `window.__vfEquipeRendu.transcript` reste exporté (P73-C2, retiré par la Phase 74) ; aucune route, aucun `vf-coquille: persistant` sur les deux fichiers neufs.
- Hors périmètre, constaté : `test-cockpit-vendor.sh` V4c.9a est rouge (HAUSSE de `vf-cockpit-arbres.mjs` 8 à 9, `vf-cockpit-server.mjs` 19 à 20, `vf-cockpit-gouvernance-lecture.mjs` 0 à 1, posées hors de ce plan) ;
  ce plan n'ajoute aucune ligne longue.

## Mutants (tous vus rouges puis retirés : copies jetables, le dépôt n'est jamais muté) et sonde saine

M-ORDRE-UI (RG0.10 : copie du module, modèle renommé `70a-…`), M-IMPACT-TRI, M-CALME, M-LONGUE-EGALE-STALL, M-STALL-INCONNU-MARQUE (marques de progrès et « suspect »), M-VERROU-ENTREE-BRUTE,
M-VERROU-SESSION-IDS, M-VERROU-CHEMIN, M-VERROU-OWNER-SANS-BORNE, M-CLE-ID-SEUL, M-ORPHELIN-ACTION, M-GLYPHE-COPIE. Sondes saines : les témoins RG0 à RG11 verts sur le code livré.

## Suites jouées (tête commitée, une fois)

- `test-cockpit-regie.sh` (sections du modèle) : 65 PASS / 0 FAIL, 34 témoins nommés au plan tous présents.
- `test-cockpit-equipe.sh` : 215 PASS / 0 FAIL. `test-cockpit-transcript.sh` : 103 PASS / 0 FAIL. `test-cockpit-chrome-fr.sh` : 141 PASS / 0 FAIL.
- `test-cockpit-vendor.sh` : 250 PASS / 2 FAIL, V4 (chrome-coin.mjs à 300 lignes, rouge de base) et V4c.9a (hausses ci-dessus, hors plan) ; V4 pour le reste : mes fichiers sous 300 lignes.
- `check-file-size.sh` (deux fichiers neufs, 71, `vm-regie.mjs`) : OK. `css-jetons.mjs` sur la feuille : 0. `check-machine-paths.sh` : OK.
- `check-version-sync.sh` : seul écart, la ligne « suites » (226 annoncées, 227 réelles : attendu).
- Inventaire FR (78-, 79-, 80-vf-fr*) : non joué, aucune chaîne anglaise ajoutée, libellés écrits en français dans les fichiers neufs ; F2 de `test-cockpit-chrome-fr.sh` vert.

rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale)
