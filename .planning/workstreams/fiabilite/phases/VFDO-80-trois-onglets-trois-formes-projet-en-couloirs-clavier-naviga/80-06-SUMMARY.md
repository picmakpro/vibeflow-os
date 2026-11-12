# 80-06 — Tiroir Git : pagination, volet bas, poignée, ouvrirSur — SUMMARY

Statut : fait, vert. Plan 80-06, vague 2 de la Phase 80 (FORM-13, P80-D-19, P80-D-39, P80-D-25).

## Livré
- `77-vf-git-rendu.js` : rangées par tranches (`PAGE = 100`, `SEUIL = 110`), bouton « Afficher 100 de plus » / « Afficher les N derniers » (« N restants »), pied
  « N commits affichés sur M » puis « Tous les M commits sont affichés », annonce polie, focus sur la première rangée ajoutée ; Worktrees repliée
  (« Worktrees · N » dans le nom du bouton) ; `VFGitRendu.motifSha`, définition unique du motif du sha.
- `77-vf-git-volet.js` (neuf, 61 lignes) : enveloppe du volet bas (`window.VFGitVolet`, `ouvrir`, `fermer`, `ouvert`, `sha`, `lier`, `brancher`), Échap au cran 4.
- `77-vf-git-vue-detail.js` : le détail passe au volet (contenu, cache et lecture inchangés, « Copier le sha » ajouté), le volet survit à la relecture et ne se ferme que si
  le commit a disparu de la lecture précédente (D9.2) ; texte du volet à 12,5 px.
- `77-vf-git-tiroir.js` : `VFGitTiroir.ouvrirSur(sha)` (contrat fourni à la Phase 74), largeur lue de `--vf-git-l` dans les bornes, pied et focus orphelin du bouton.
- `77-vf-git-poignee.js` (neuf, 77 lignes) : `role=separator`, ←/→ 16, Maj 64, Origine/Fin/Entrée, glisser, double clic, bornes [280, max(280, 100vw − panneau − 312)],
  clé `localStorage` `vf-git-largeur:<lab>`, absente sous 1000 px.
- `VENDORED.txt` : `AJOUT assets/ui/77-vf-git-poignee.js` et `AJOUT assets/ui/77-vf-git-volet.js`.
- Suite neuve `test-cockpit-git-pagination.sh` + pilote `chrome-git-pagination.mjs` (GP1 à GP5, huit mutants).

## Commits (ordre)
08c489a5 amendement A et B · c3f7d877 témoins rouges GP1 · 1c5feafd pagination · 73f69528 amendement C · 898c7814 suites (GP2 à GP5, D2.1, D7.1, D8.1, D9.1, mutants) ·
c69de03d amendement D · 3528db58 volet, ouvrirSur, poignée, VENDORED · ce SUMMARY.

## Vérifié
`test-cockpit-git-pagination.sh` 39 PASS, 0 FAIL (huit mutants « le mutant rougit ») · `test-cockpit-git-tiroir.sh` 194 PASS, 0 FAIL · `test-cockpit-surcouches.sh` 45 PASS ·
`test-cockpit-git-entete.sh` 81 PASS · `test-cockpit-vendor.sh` 138 PASS sur la tête plus les fichiers de ce plan (V6.1 rouge dans l'arbre partagé à cause de fichiers d'un voisin,
vert sans eux) · plafonds (`OK-PLAFONDS`, `OK-STATIQUE`) et gardes de la porte unique (0), du motif (0), de `.fit(` (0) verts. Trace du rouge : `80-06-RED-TRACE.md`.

## Pour la jointure avec la Phase 79
- `VENDORED.txt` : deux lignes `AJOUT` à reporter dans le fichier réécrit par 79-01 (poignee juste avant rendu ; volet entre tiroir et vue-detail).
- `test-cockpit-git-tiroir.sh` : lignes touchées = D2.1 (assertion), D7 (`dansVolet`, assertion D7.1), D8 (attente du volet, `volet3`, assertion D8.1), D9.1 (`voletSha`, assertion), un appel
  de dépliage de Worktrees dans D16 (2 scénarios) et D18, le mutant M-DETAIL-LISTE (cible `77-vf-git-volet.js`). En-tête, `build_serve`, lancement du terminal : intacts.
- `test-cockpit-git-pagination.sh` : à passer à `socle-serveur.sh` et à `cockpit_module_copie` (ses `mkmod` et `mutant` sont les copies de la base) ; ses crochets de page
  (`pre-mock.js`, `pre-reel.js`) tiennent la visite guidée pour vue en surchargeant `Storage.prototype.getItem` (clés `tour-seen:` et `vibeflow-cockpit:visite`).
- Les cinq fichiers `77-vf-git-*` : idiome A51 (`VF_COQUILLE.surOnglet`) à poser à la jointure ; `77-vf-git-poignee.js` pose un écouteur `resize` et un écouteur `vf-git:etat`.

## Écarts au plan
Amendements A à D du PLAN.md (constats : pastilles déjà neutres, plage de lecture ; hypothèses fausses : Worktrees repliée, mutants sur code retiré, tailles de police,
requête d'en-tête, découpage volet et vue détaillée, M-POUSSE). Un seul commit de code pour le volet, `ouvrirSur` et la poignée (ils partagent `77-vf-git-tiroir.js`).
Le mutant M-POUSSE écrit `--panel-w` au lieu d'appeler `fit`. Pas d'`estimate`/`actuals` mesurés : exécution inline, aucun nombre inventé.

## Ligne de CHANGELOG demandée à 80-18 (P80-D-24)
Tiroir Git : rangées paginées (« Afficher 100 de plus »), worktrees repliés, détail d'un commit dans un volet bas, largeur réglable au clavier (FORM-13), entrée publique
`VFGitTiroir.ouvrirSur(sha)` pour la Phase 74.
