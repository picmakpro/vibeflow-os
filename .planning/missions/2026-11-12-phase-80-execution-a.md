# Phase 80 — exécution, segment a (vagues 1 à 3) — 2026-11-11 → 2026-11-12

Mission : `vf-dev-manager` (mgr80a), mode autonome. Demande de Samuel, session principale Claude Code, 2026-11-11
(« Exécuter 79 et 80 en parallèle avec un manager de jointure, puis 73, 74, 75, 76, 77 »). Branche
`feat/phase-80-trois-formes`, base `integration/cockpit-audit` à `680364f1` (avance rapide, sha de départ `680364f1`).
Verrou `--ws=fiabilite --phase=80`.

## Résultat

Huit plans sur huit exécutés, revus par un relecteur frais et, pour les sept plans d'interface, jugés sur captures par
un juge de design frais : 80-01, 80-02, 80-03 (vague 1) · 80-04, 80-05, 80-06 (vague 2) · 80-07, 80-08 (vague 3).
Rien au-delà : 80-09 et suivants attendent la jointure avec la Phase 79.

| Plan | Livré | Suite propre (dernier rejeu) | Mutants | Design (dernier juge) |
|---|---|---|---|---|
| 80-01 | canevas au clavier : un arrêt de Tab, voisin spatial, rôles et noms, connecteurs nommés | clavier-canevas 32/0 | 5 | 90/100 |
| 80-02 | pile de surcouches, piège à Tab, inert à propriétaires comptés, visite modale, trois listes retirées | surcouches 45/0 | 15 | 78/100 |
| 80-03 | champs structurés de Projet (avancement, exigences, vague, recette), une règle de plans faits | projet-champs 21/0 | 9 | — (données) |
| 80-04 | Projet en couloirs par défaut, `?vue=graphe`, clavier, panneau par-dessus | couloirs 57/0 | 8 | 85/100 |
| 80-05 | coin bas-droit (minicarte, ligne d'état), repères « N cartes par là », zone basse | coin 37/0 | 5+ | 95/100 |
| 80-06 | tiroir Git paginé (Graphe, Tags, Stash, Auteurs), Worktrees repliés, volet bas, poignée, `ouvrirSur(sha)` | git-pagination 43/0, git-tiroir 194/0 | 8+ | 84/100 |
| 80-07 | forme Liste, intérieur de phase, touche v, mémoire par lab et largeur | projet-liste 46/0 | 8 | 83/100 |
| 80-08 | pile Retour du panneau (`VF_PANNEAU`) | panneau-retour 41/0 | 9 | 92/100 |

Exigences cochées au ledger (toutes leurs conditions livrées ici, aucun plan 80-09 à 80-21 ne les porte) : FORM-01,
FORM-05, FORM-06, FORM-07, FORM-09, FORM-12, FORM-13. Ouvertes (portées aussi ou seulement par un plan suivant) :
FORM-02, 03, 04, 08, 10, 11, 14, 15, 16, 17, 18. ROADMAP : huit cases cochées, longueur inchangée (62 440 octets).
STATE : ligne de la Phase 80 remplacée (8 059 octets).

## Plan de bataille (DAG)

check-w1, check-w2, check-w3 (revalidation par vérificateur frais, en parallèle) → vague 1 en parallèle (même arbre,
commits par pathspec) → revue + design de la vague 1 → re-vérification de la vague 2 contre le code livré → vague 2 →
80-08 lancé dès 80-04 fini (ses fichiers sont disjoints) → 80-07 après 80-04 et 80-05 → revues, juges, corrections
ciblées par reprise du même exécuteur → nœud de fin (suivi, job `gates`, vendor, dépôt public) → rapport, PR.

## Le correctif des pastilles « modifiés » (P73-Q-01)

Arbitrage Samuel, AskUserQuestion session principale, 2026-11-11, « Les neutraliser (Recommandé) ». La prémisse
était fausse à la base `680364f1`, ce que la session principale a confirmé à la source. `77-vf-git-vue-detail.js:28`
pose déjà `background: none; color: var(--text-2)`, et la classe `vf-git-p-warn` n'ajoute que le glyphe ◐. L'origine
est P78-D-33, qui a remplacé les fonds prévus par 78-10. Placé en amendement A daté de 80-06 : constat, aucun
changement de code. Preuve :
- `08c489a5` : l'amendement ;
- `898c7814` : le mutant M-PASTILLE (test-cockpit-git-pagination.sh) pose `background: var(--warn-bg)` sur une copie
  du module, et la mesure de D8.2 rougit ;
- `3528db58` puis `ef376223` : la suite rejouée verte sur le vrai module.

Deux juges frais ont mesuré aux pixels : le fond des pastilles est identique à celui de la carte, et le contraste du
texte est de 8,8:1 en clair, 9,2:1 en sombre. Les captures sont hors dépôt, transmises à la session principale.
`73-CONTEXT.md` et le BACKLOG ne sont pas touchés (la jointure s'en charge).

## Écarts au plan et amendements (tous datés dans les PLAN.md)

- **80-01.** L.237 : le mot d'état se lit sur la pastille `.vst`, car `STATE_WORD` n'est pas exposé. Après la revue :
  les cartes connecteur `x:in`/`x:out` restent navigables, nommées « Vers / Depuis <entité> » (décision du manager,
  spec ambiguë), et l'ombre de levée est retirée sous l'anneau.
- **80-02.** Noms source/servi, Tab dans le champ, bulles, mutants sur un lab copié. Deux suites existantes ont été
  touchées sur décision du manager, avec le trailer `Gate-Touche` :
  - `test-cockpit-responsive.sh` l.129 : `panneau` lit `textContent`, car P80-D-34 cache le panneau fermé ; c'est
    plus strict, et rien n'est retiré ;
  - `test-cockpit-git-tiroir.sh` : le mutant M-ECHAP-390 est reciblé sur la pile, puisque le retrait 4 supprime sa
    cible.
  Après la revue : inert jamais levé tant que la surcouche reste ouverte, propriétaires comptés, et Échap ferme le
  tiroir couvert (une régression par rapport à la base, introduite puis fermée). La visite ouverte par son bouton est
  modale.
- **80-03.** L.221 : `-F` ajouté. Une règle unique de plans faits (`856bf6fd`) : le pied d'une phase cochée avec un
  plan sans SUMMARY passe de 2/3 à 3/3. Écart assumé et écrit.
- **80-04.** Deux fichiers d'aide de test en plus (plafond de 299 lignes). La bascule et la barre de jalon sont à
  gauche, sinon le panneau ouvert les recouvre. Rayon de 8 px (`css-jetons`). CL1.3 porte sur la phase 3. Le panneau
  reste en colonne latérale de 701 à 999 px, alors que la spec demande une feuille à 800 px : écart d'origine, déclaré.
  **Décision du manager annulée.** Dans la correction de revue, j'avais fait poser les extrémités défilables dès 701 px,
  sur la foi d'une ligne de 80-UI-SPEC qui vise en fait 390 px. Or P80-D-50 b, qui prime sur les UI-SPEC, les limite aux
  largeurs de 1 000 px et plus, au pointeur fin. Le comportement a été rétabli en `1857a51d`, avec un amendement dans
  80-04 et 80-07.
- **80-05.** Le bloc est à 32 px du panneau, et le zoom était déjà à 44 px. Après la revue : la garde de forme rend
  minicarte et repères absents quand le canevas n'est pas affiché ; c'était la source de la « pastille fantôme » vue
  à 390 px. Les repères sont disjoints.
- **80-06.** Amendements A (pastilles), B (plage de lecture), C (trois assertions hors des quatre cas, chacune d'une
  ligne de dépliage de Worktrees, plus M-DETAIL-LISTE reciblé) et D (requête d'en-tête, découpage du volet).
  Amendement E : la pagination de Tags, Stash et Auteurs était un retranchement non déclaré ; elle est implémentée.
- **80-07.** Critère négatif « couvre » en mot entier, registre `__vfProjetRegistre` (ordre alphabétique de
  chargement), repli vers `41-vf-projet-formes.js` (la vue dépassait 299 lignes), forme propre à la phase.
- **80-08.** `69-vf-flux.js` est absent de la base. PR2.2 est aligné sur le plan (décision du manager : l'entrée
  défaillante est retirée sans être rouverte). Entrée et Espace sur Retour ne font plus plonger le moteur.

## Ce que la mission de jointure trouvera, fichier par fichier

- **`VENDORED.txt`** : 15 lignes `AJOUT` à reporter dans la forme de 79-01 :
  - `00-vf-surcouches.js` (avant `00-vibeflow.js`) ;
  - `02-vf-reperes.js`, `02-vf-coin.js`, `02-vf-ligne-etat.js` (entre `01-vf-responsive.js` et
    `02-vf-telephone.js`) ;
  - `04-vf-clavier-canevas.js` ;
  - `41-vf-projet-{clavier,formes,liste,modele,phase,rendu,vue}.js` (entre `39-vf-tour-placement.js` et
    `70-vf-live.js`) ;
  - `42-vf-panneau-retour.js` ;
  - `77-vf-git-poignee.js` (avant `-rendu`) et `77-vf-git-volet.js` (entre `-tiroir` et `-vue-detail`).
  Le tri des lignes `AJOUT` était déjà rompu à la base (une ligne `scripts/lib/vf-git-sortant.mjs` intercalée) : ce
  n'est pas notre fait.
- **`vf-cockpit-interface.json`** : une seule ancre. La ligne `"statuts"` du bloc `vibeflow/cockpit-project@1` est
  retouchée sur place, et `"optionnels"` est insérée juste derrière (80-03).
- **`chrome-accessibilite.mjs`** : une ligne, `ANNEAU` (lit la `.card` d'un `g.node` focalisé), distincte de la sonde
  M7 de la 79.
- **`chrome-session.mjs`** : quatre lignes avant `naviguer` (80-04).
- **`test-cockpit-git-tiroir.sh`** : D2.1, D7.1, D8.1, D9.1 réécrits ; hors de ces cas, une ligne de dépliage de
  Worktrees dans D16.3b, D18.1 et M-BULLE-ECHAP (l.~829, 865, 884), M-DETAIL-LISTE reciblé sur `77-vf-git-volet.js`,
  et M-ECHAP-390 reciblé sur la pile (l.~1069). En-tête, `build_serve` et lancement du terminal intacts.
- **`test-cockpit-responsive.sh`** : l.129, `panneau` en `textContent`.
- **README racine** : compteur de suites laissé à 213, la valeur de la base commune. Ce segment ajoute huit suites
  (221 sur la branche seule). Je l'avais porté à 221, mais `integration/cockpit-audit` l'avait passé à 214 entre-temps
  (ab8f3e64). La PR était donc en conflit, et une PR en conflit ne déclenche pas la CI. Comme il m'était demandé de ne
  pas fusionner la base, je l'ai remis à 213. La jointure posera la somme réelle (base, 79 et ces huit suites).
  check-version-sync est rouge sur la PR pour cette seule raison (classe c).
- **`colonnes-baseline.txt`** : `02-vf-telephone.js` passe de 56 à 55 lignes longues ; 73 et 77 sont inchangés.
- **`scripts/ci-shard-suites.sh`** : nos suites neuves sont absentes de la table des durées (7 s par défaut) ; elles
  sont découvertes d'office par le motif `tests/test-*.sh`.
- **Idiome A51, à poser** (aucun ne l'a, sauf `00-vf-surcouches.js`, qui en est exempté) : `04-vf-clavier-canevas.js`,
  les sept `41-vf-projet-*`, `42-vf-panneau-retour.js`, les trois `02-vf-*` (ils s'initialisent par
  `VF_COQUILLE.surOnglet` si la coquille existe, sinon par `ready`), et les cinq `77-vf-git-*` (écouteurs `window`,
  `<style>`, ouverture du volet non idempotente). Disposers des couloirs : ni le `<style>`, ni les classes `body`, ni
  `VF_PROJET` ne sont retirés.
- **Témoins en ATTENTE de la coquille de la 79** : SU6.1 et M-PERSISTANT (test-cockpit-surcouches.sh).
- **`39-vf-tour-placement.js`** : `obstacles()` ignore `#vf-coin`, donc la carte de visite peut recouvrir le coin. Ce
  fichier est hors des plans du segment.
- **Mutants à passer à `COCKPIT_MODULE="$(cockpit_module_copie)"`** (contrat de 79-06 amendé en `9ea86a3c`) et suites à
  passer à `socle-serveur.sh`. Tous nos mutants sont aujourd'hui sur une copie maison du module dans `$WORK` :
  - test-cockpit-clavier-canevas.sh (`04-vf-clavier-canevas.js`) : M-VOISIN-DOM, M-REPOSE, M-EQUIPE, M-REPLI-BODY,
    M-FOCUS-VOLE ;
  - test-cockpit-surcouches.sh (`00-vf-surcouches.js`, et page assemblée) : M-INERT-TOUT, M-PIEGE, M-PALETTE,
    M-ECHAP-VIDE, M-SANS-PREVENT, M-UNICITE, M-LEVEE, M-PROPRIO, M-TIROIR-COUVERT, M-FLUX, M-BULLE, M-RIEN, M-IDPANEL,
    M-RENDRE, M-TOUR ;
  - test-cockpit-couloirs.sh (`41-vf-projet-modele/rendu/vue.js`) : M-FOOT, M-XSS, M-XSS-ID, M-XSS-HIST, M-POUSSE,
    M-ORPHELIN, M-EXTREMITE, et le mutant de CL2.7a ;
  - test-cockpit-coin.sh (`02-vf-*.js` et `viewer.html`) : M-FREEAREA, M-COMPTE, M-TERMINAL, M-ORPHELIN, M-ONGLETS ;
  - test-cockpit-git-pagination.sh (`77-vf-git-*.js`) : M-TOUT, M-EPUISE, M-BORNE, M-POUSSE, M-PAGINE, M-MOTIF,
    M-VOLET-LIE, M-PASTILLE ;
  - test-cockpit-projet-liste.sh (`41-vf-projet-liste/phase/formes/vue.js`) : M-CLE, M-TRI, M-SAISIE, M-ORPHELIN-TRI,
    M-PORTE, M-XSS-LISTE, M-XSS-PLAN, M-PHASE ;
  - test-cockpit-panneau-retour.sh (`42-vf-panneau-retour.js`) : M-REEMPILE, M-HTML, M-BORNE, M-GLOBALE, M-ENTREE,
    M-VIDE, M-DEHORS, M-NULL, M-COUPE ;
  - test-cockpit-projet-champs.sh (modules node seuls, sans `cockpit_module_copie`) : M-VIE, M-STATUTS, M-AUTRE-LIGNE,
    M-PLANS, M-CORR, M-VERS, M-ETAT, M-EXIG, M-VAGUE.
- **Commits qui portent des lignes d'un autre plan** (ce n'est pas un débordement) :
  - `ef0e9ec9` (80-02) porte la ligne `04-vf-clavier-canevas.js` de 80-01 ;
  - `1d47a9dc` et `9e60d903` (80-05) portent les trois lignes `41-vf-projet-{modele,rendu,vue}` de 80-04.
  La règle de l'index temporaire a été appliquée après eux (80-08, 80-06, 80-07).

## Ce que la Phase 79 doit savoir

- Le cliquet de colonnes verra `02-vf-telephone.js` baisser de 1 ligne longue (80-02).
- `VF_SURCOUCHES` (`00-vf-surcouches.js`) : `couverte(el)`, `dessus`, `fermer`, Échap au cran 4 ; le registre de la
  visite modale passe par `MutationObserver` sur `body`. `VF_CANEVAS` : `nomDeCarte`, `carteItinerante`, `focaliser`,
  `champDeLecture`, `amenerDansLeChamp`, `deplacer({x,y})`, `voisin`. `VF_COIN.rectangle()` rend un DOMRect ou `null`.
  `VFGitTiroir.ouvrirSur(sha)` valide `/^[0-9a-f]{40}$/` avant tout effet ; `VFGitRendu.motifSha`.
- `vf-cockpit-project.mjs` : le nœud de phase porte `avancement` (mission réduite à `{nom, etat}`) et
  `exigences {faits,total}`. `ph.plans` vaut `[{id,fichier,vague}]`. `plansFaits` suit le prédicat du statut de
  l'élément de plan (`856bf6fd`).
- Au défaut, la forme de Projet est la liste à 700 px et moins, les couloirs au-delà. Les suites qui visent les
  couloirs chargent `?vue=couloirs`.

## À revalider pour les segments suivants

- PR2.9 (80-08) est vert avec le sélecteur `.vp-ligne[data-id^="n:ph-"]`, à tenir par 80-09.
- `41-vf-projet-vue.js` fait 287 lignes. Les ajouts de 80-09+ iront dans `41-vf-projet-formes.js` (P80-D-58 a).
- Hypothèse A1 non mesurée (Safari focalise-t-il un `g` SVG doté d'un `tabindex` ?), ainsi que l'effet d'`inert` sur
  l'iframe du terminal quand un terminal est vraiment chargé : à soumettre au juge humain.
- Mineurs de design laissés, au choix du craft :
  - 80-06 : sha du volet hors de la ligne 1 à 1024 px, curseur `ew-resize` au lieu de `col-resize`, libellés tronqués ;
  - 80-07 : alignement des comptes à 390 px, accord « 1 cochées », en-têtes inactifs sans marque de bouton ;
  - DESIGN.md §4 exige des jetons `--sp-*`, que le code n'emploie nulle part : écart DA/code, à arbitrer.

## Constats (non corrigés dans ce segment)

- **Disque.** Le disque du poste est passé par le plein vers 02 h 50 (391 Mio libres). Les suites laissent derrière
  elles leurs dossiers `mktemp` et les profils de Chrome. Sur ce poste, un `mktemp -d` nu ignore `TMPDIR`, donc la
  variable ne suffit pas à confiner les suites. La correction (gabarit complet sous une racine connue, nettoyage en
  sortie, dans l'aide commune des suites) relève du socle de test de la Phase 79. Ce qui avait tourné sous manque de
  place (A0, les mutants de 80-02) a été rejoué depuis un état propre, en vert.
- **Charge.** La charge du poste était vers 35 à 40. Les rouges vus sous charge et rejoués seuls, verts au rejeu
  isolé : R15.5, R15c.2, D2.6, T21.x, CC6.2, SU4.5b, H0. Aucune sonde n'a été affaiblie.

## Vérification

Job `gates` de `ci.yml` rejoué étape par étape sous `bash -e` (macOS) sur `5e994093` :
- étapes 1 à 5, 7 à 20 et 23 : rc=0 ;
- étape 6 (check-version-sync) : rc=1, à cause du compteur des README seulement. Il est rc=0 avec 221, mais le
  compteur est laissé à 213 pour la jointure (voir plus haut) ;
- étapes 21 et 24 (push vers `main`) : non jouées.

test-cockpit-vendor : 143/0. Dépôt public : 0 occurrence de chemin de poste ou d'identifiant de session dans les
lignes ajoutées par `git diff 680364f1..HEAD`. La CI de la PR fait foi pour la découverte complète.

## Budgets

31 agents dispatchés : 4 vérificateurs de plan, 9 exécuteurs, 7 relecteurs et 11 juges de design. 13 reprises
d'exécuteur par message (corrections ciblées, SUMMARY, captures, rejeu). Jetons de sous-agents, cumulés d'après les
rapports de fin :
- exécuteurs : environ 4,2 M ;
- relecteurs : environ 1,4 M ;
- vérificateurs : environ 0,6 M ;
- juges : environ 0,6 M.
Total : environ 6,8 M.

Durée : de 22 h 16 à environ 05 h 40 le lendemain, dont 15 minutes d'arrêt pour le disque plein.

## Moins cher la prochaine fois

- Donner dès le premier mandat la règle d'index temporaire pour les fichiers partagés, et `TMPDIR` dans le scratchpad.
- Faire juger le design avant la revue de code : trois corrections ont dû refaire leurs captures.
- Relire la portée d'une ligne de spec (largeur, forme) avant d'en tirer une décision : ma décision 701-999 px a coûté
  un aller-retour.
- Une vague parallèle dans un seul arbre fait rougir les suites temporisées : prévoir d'emblée le rejeu isolé.

## Preuves E6

```json
{"preuves":[
{"verdict":"80-01 clavier-canevas 32/0","commande":"bash plugin/cockpit/scripts/tests/test-cockpit-clavier-canevas.sh","exit_code":0,"sha":"342a8763"},
{"verdict":"80-02 surcouches 45/0 avec 15 mutants","commande":"bash plugin/cockpit/scripts/tests/test-cockpit-surcouches.sh","exit_code":0,"sha":"c6aca1f9"},
{"verdict":"80-03 projet-champs 21/0","commande":"bash plugin/cockpit/scripts/tests/test-cockpit-projet-champs.sh","exit_code":0,"sha":"856bf6fd"},
{"verdict":"80-04 couloirs 57/0","commande":"bash plugin/cockpit/scripts/tests/test-cockpit-couloirs.sh","exit_code":0,"sha":"1857a51d"},
{"verdict":"80-05 coin 37/0","commande":"bash plugin/cockpit/scripts/tests/test-cockpit-coin.sh","exit_code":0,"sha":"1d8ef5ef"},
{"verdict":"80-06 git-pagination 43/0","commande":"bash plugin/cockpit/scripts/tests/test-cockpit-git-pagination.sh","exit_code":0,"sha":"ef376223"},
{"verdict":"80-06 git-tiroir 194/0","commande":"bash plugin/cockpit/scripts/tests/test-cockpit-git-tiroir.sh","exit_code":0,"sha":"ef376223"},
{"verdict":"80-07 projet-liste 46/0","commande":"bash plugin/cockpit/scripts/tests/test-cockpit-projet-liste.sh","exit_code":0,"sha":"856bf6fd"},
{"verdict":"80-08 panneau-retour 41/0","commande":"bash plugin/cockpit/scripts/tests/test-cockpit-panneau-retour.sh","exit_code":0,"sha":"1857a51d"},
{"verdict":"responsive 378/0","commande":"bash plugin/cockpit/scripts/tests/test-cockpit-responsive.sh","exit_code":0,"sha":"1857a51d"},
{"verdict":"vendor 143/0","commande":"bash plugin/cockpit/scripts/tests/test-cockpit-vendor.sh","exit_code":0,"sha":"5e994093"},
{"verdict":"check-version-sync avec compteur 221 (compteur ensuite laissé à 213 pour la jointure, classe c)","commande":"bash scripts/check-version-sync.sh","exit_code":0,"sha":"e868ec93"},
{"verdict":"gates ci.yml étapes 1-5, 7-20, 23","commande":"bash -e <étape extraite de .github/workflows/ci.yml>","exit_code":0,"sha":"5e994093"}
]}
```

## Après l'ouverture de la PR #237 : CI Linux, fusion de la base, corrections, clôture (2026-11-12)

La première CI (tête 21f174cd) était rouge, de notre fait. Fusion de la base demandée par la session principale le
2026-11-12 : origin/integration/cockpit-audit (da64eb8c) fusionnée en `8abdad2e`, sans conflit, compteur des README
recompté à 222 (`231ebbd9`). Clôture reprise par un second manager (mgr80b) après l'arrêt du premier, sur ce qui était
écrit. Les commits 9411891e, b36fdd01 et e9b69b1a ont été faits et poussés par l'exécuteur de la correction de CI à la
demande de la session principale, après la relâche du verrou par le premier manager ; les décisions qu'ils citent
(« prise par la session principale le 2026-11-12 ») sont les siennes, par messages à cet exécuteur le 2026-11-12. Ce
n'est pas un écart de l'exécuteur.

### Rouges de CI, cause et correction

| Rouge | Cause établie | Correction | Sous Linux seulement ? |
|---|---|---|---|
| gates : check-version-sync | compteur des README à 213 (base à 214, 222 réels après fusion) | fusion `8abdad2e`, recompte `231ebbd9` | non |
| T7.5 terminal-activation | 8 littéraux « vf-term- » dans nos extensions | lecture par structure (`ba62bb17`) | non (suite non jouée) |
| couloirs CL3.x, coin CN2.x, panneau-retour PR1-2, projet-liste PL2.3/3.4 | le Chrome sans tête de Linux n'annonce aucun pointeur : `(pointer: fine)` faux | gardes en `(not (pointer: coarse))` (`4397aac2`, amendements `86e967bd`) ; témoins CL4 (`e9b69b1a`), CN5, PL4, CL4.4-5 (`94f90609`) | oui |
| T6.1 terminal-client | `naviguer()` (P80-D-37) ajoute `vue=graphe`, T6.1 compare l'adresse exacte | pilote en `{ brut: true }`, exception nommée à P80-D-37 (`9411891e`) | non |
| T27.B1 transcript | les liens `#r=` rechargeaient depuis `?vue=graphe` | le lien de la même page ne change que le fragment (`94c3547b`) | non |
| ailleurs L1.2/L2.3 | règle unique de plans faits (`856bf6fd`) | annulée (`4d6f6786`, amendement `b2012346`) | non |
| visite-retours T3.2 | visite ouverte par le bouton rendue modale (`c6aca1f9`, contrat P80-D-11/Q5) : le bouton devient inerte | T3.2 réécrite sur le contrat, T3.3 ajoutée (retour du focus, mutant) (`f2d45fba`) | non |
| visite-retours T9S ×2, T10 | `visibility: hidden` du panneau fermé (`ef0e9ec9`) le sortait des obstacles de la carte de visite | `obstacles()` compte le panneau fermé à 701 px et plus (`480c8494`, garde du null `94619edf`) | non |
| GP2.3 git-pagination | runner sans CLI `claude` : `#ask-warn` affiché à 1024 px, barre 40 → 115 px, zoom et tiroir remontent, liste 237 < 240 | faux claude donné au serveur (`c00858f5`, puis `--claude` explicite `937e87b6`), cas GP2.3b sans CLI, amendement de P80-D-19 (`00219daa`, texte corrigé `14b80257`) | oui |
| C5 test-ci-shard-suites | suites neuves absentes de la table des durées | durées inscrites (`7dc5039b`), remesurées sur runs verts (`9aec7ac7`) | — |
| lancer-bandeau LB.E12-14 | instable sous charge CI (vert dans deux autres runs, aucun fichier en cause modifié) | aucune ; pas de la branche | oui, instable |
| check-method-budget KC2 | course de trois passes simultanées (conductor, non touché) | aucune ; vert au run suivant | instable |

CI de la PR lue jusqu'au bout et verte : run 43206672595 sur `14b80257`, quatre jobs de gates et neuf shards verts.
Quatre runs intermédiaires ont été annulés par le push suivant (cancel-in-progress).

### Pourquoi seulement en CI, et ce que les exécuteurs jouent désormais

Deux causes propres à Linux : Chrome sans tête sans pointeur, et aucun CLI `claude` sur le runner (les postes de dev
en ont un). Les autres rouges n'étaient pas propres à Linux : les suites terminal-*, transcript, ailleurs et
visite-retours n'étaient dans la liste de non-régression d'aucun plan. Désormais, avant de déclarer un plan vert : la
découverte complète des suites du module cockpit, un passage sous Chrome sans pointeur, et, pour toute sonde qui dépend
de la barre de question, un serveur sans CLI (`--claude` vers un chemin absent).

### Revues et jugement de la clôture

- Revue fraîche des commits de correction (231ebbd9 … e9b69b1a, 4d6f6786, 1857a51d) : passed, aucun majeur. Mineurs :
  les exclusions de `94c3547b` (modificateurs, autre chemin, autre origine) n'ont pas de témoin et toute requête
  différente, pas seulement `vue=`, est avalée (aucun lien du produit n'en porte) ; quatre sites `matchMedia` sans
  mutant (fermé par `94f90609`) ; durées C5 sous-estimées (fermé par `9aec7ac7`).
- **Limite de `ba62bb17` (CL4.3) : acceptable jusqu'à la jointure**, selon la revue. Sur Projet, seul le module terminal
  pose un bouton fixe sous `body` ; un bouton fixe étranger ne ferait que relever la zone basse (+120 px au témoin),
  sans perte de donnée ni blocage. Témoins négatifs ajoutés (CL4.3b div fixe, CL4.3c bouton non fixe, mutants
  M-PASTILLE-DIV et M-PASTILLE-NONFIXE). CL4.3 devra être inversé à la jointure.
- Seconde revue (`94f90609` … `94619edf`) : passed ; troisième (`00219daa`, `937e87b6`) : un majeur de texte (la raison
  écrite « VF_COCKPIT_CLAUDE sans effet » était fausse : le serveur assemblé lit `--claude`, sinon `VF_COCKPIT_CLAUDE`),
  corrigé en `14b80257` ; le témoin GP2.3b exige `ask === 115` en égalité stricte (laissé, consigné).
- Juge de design sur le rendu tactile et sans pointeur : passed, 88/100. Tactile 390 px identique avant/après (0 px) ;
  sans pointeur = pointeur fin (le reste est du bruit de texte de la barre haute).

### Décisions de la clôture

Toutes « décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée » :
- visite-retours T9S/T10 : la régression vient de la Phase 80, fermée dans ce segment, `39-vf-tour-placement.js` ajouté
  à 80-02 par amendement daté (aucun plan de la Phase 79 ne le liste, vérifié) ;
- T3.2 réécrite sur le contrat de 80-02 ; acceptée par la session principale après lecture du diff ;
- GP2.3 : mesure de la classe puis amendement et GP2.3b, « prise par la session principale le 2026-11-12 ». Les deux
  correctifs produit proposés (masquer l'avertissement quand le tiroir est ouvert, le sortir de `--vf-ask-bas`) ont été
  refusés par la session principale (dire vrai ; ordre zoom/pastille/barre de PU-G-021, arbitrage Samuel,
  AskUserQuestion session principale, 2026-11-08).

Mesure de la classe (1024 × 768, panneau et volet ouverts) :

| CLI | terminal | tiroir | volet | liste | barre de question | bas du tiroir |
|---|---|---|---|---|---|---|
| présent | non | 580 | 203 | 295 | 40 | 120 |
| présent | oui | 546 | 192 | 272 | 40 | 154 |
| absent | non | 511 | 192 | 237 | 115 | 189 |
| absent | oui | 471 | 192 | 197 | 115 | 229 |

### Commits qui portent des lignes d'un autre plan

`ef0e9ec9` (80-02) porte la ligne VENDORED de `04-vf-clavier-canevas.js` (80-01) ; `1d47a9dc` et `9e60d903` (80-05)
portent les lignes `41-vf-projet-{modele,rendu,vue}` (80-04). `480c8494` (80-02) touche `39-vf-tour-placement.js`,
ajouté au plan par amendement.

### Pour la jointure

- CL4.3 à inverser quand le terminal posera un attribut neutre (contrat avec la Phase 79).
- Registre, mineur : sans CLI, la liste du tiroir Git tombe à 237 px (197 avec le terminal) sous le plancher de 240.
  Destination proposée : un plan responsive de la 80 (80-17 ou 80-20, propriétaires de `01-vf-responsive.js`). Question :
  l'avertissement doit-il être compact de 701 à 1 279 px ?
- Constat produit : `eviter()` (77-vf-git-tiroir.js) ne se rejoue pas à l'arrivée de la pastille du terminal (ajoutée à
  `body`, sans changement de classe ni de style) ; un tiroir ouvert avant elle la chevauche jusqu'au prochain
  redimensionnement.
- Tactile à 1 000 px et plus : le panneau recouvre la 3ᵉ colonne sans défilement possible (conforme à P80-D-50 b, la
  géométrie de la feuille à ce seuil n'est pas spécifiée) ; à trancher.
- Durées C5 : deux suites hors Phase 80 dépassent largement leur durée inscrite sur le run vert (terminal-tiroir 1 184 s
  pour 493, lancer-bandeau 608 pour 311) ; la charge réelle de quatre shards dépasse la borne calculée. Cause non établie.
- `39-vf-tour-placement.js` : la limite 701 px du correctif est couplée au `@media (min-width: 701px)` de
  `00-vf-surcouches.js`.

### Pour la Phase 79

- `39-vf-tour-placement.js` est désormais touché par la 80 (`480c8494`, `94619edf`) : `obstacles()` compte `#panel` même
  en `visibility: hidden` à 701 px et plus.
- La pastille et le tiroir du terminal sont reconnus par leur structure (`ba62bb17`) en attendant un attribut neutre.
- `eviter()` du tiroir Git devrait se rejouer à l'arrivée d'un enfant de `body` (pastille du terminal).

### Écarts

- La « règle unique de plans faits » est annulée (cassait ailleurs L1.2/L2.3).
- 80-02 : un fichier ajouté (`39-vf-tour-placement.js`) et l'assertion T3.2 réécrite, par amendement daté.
- 80-04 : exception nommée à P80-D-37 (terminal-client en `{ brut: true }`).
- 80-06 / P80-D-19 : l'arithmétique « tiroir de 684, liste ≈ 239 » supposait un tiroir sans obstacle ; le plancher de
  240 ne tient qu'avec le CLI, amendement daté avec la table.
