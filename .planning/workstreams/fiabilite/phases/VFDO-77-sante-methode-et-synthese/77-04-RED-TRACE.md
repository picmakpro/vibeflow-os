AVANT faed809d83ed54114482da69875eea099155eba6

# 77-04 — trace des rouges

Suite : `plugin/cockpit/scripts/tests/test-cockpit-synthese.sh`, jouée sur la base, avant tout code des fichiers `ui/74-vf-synthese-*.js`.
Résultat à la base : 7 PASS / 43 FAIL (les 7 verts : les témoins SG0, SG2 et SV1 (sonde AJOUT, ordre alphabétique), H0 (hygiène), et SP3 ×2, vide faute de fichier, que SP1, SP2 et SP4 rougissent).

## Rouges avec assertion, attendu, obtenu

- SC0 — chargement du calcul sous `vm` (avec et sans `document`) :
  attendu : le fichier `ui/74-vf-synthese-calcul.js` se charge et pose `window.__vfSyntheseCalcul` aux douze exports ;
  obtenu : `exception ENOENT: no such file or directory, open '$W/plugin/cockpit/skills/cockpit-moteur/assets/ui/74-vf-synthese-calcul.js'`.
- SM1 — clé par lab : attendu `vibeflow-cockpit:derniere-visite:0123456789ab` ; obtenu : `exception Cannot read properties of null (reading 'cle')` (module absent).
- SG1 — `base.h` de `/api/vf/git` vu depuis le worktree d'une branche de fonction :
  attendu : le SHA de `refs/heads/main` (40 hex) ; obtenu : `null` (champ absent de l'objet `base`).
- SG2 (témoin positif) : `base.nom` vaut `main` — vert à la base, la fixture est donc lue ; SG0 : la tête de la branche de fonction diffère de `main`.

Les mutants M-* rougissent tous à la base pour « fichier visé absent de la copie » ou « ancre absente » : ils ne comptent comme verts qu'une fois le code posé.
