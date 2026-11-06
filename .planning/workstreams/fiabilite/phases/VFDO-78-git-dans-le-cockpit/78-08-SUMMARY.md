---
phase: 78
plan: "08"
subsystem: cockpit
tags: [git, route-get, lecture-seule, detail-commit, worktrees]
requires: [78-01, 78-02, 78-03, 78-05]
provides: [plugin/cockpit/scripts/vf-cockpit-git-details.mjs]
affects: [78-06, 78-10]
key-files:
  created:
    - plugin/cockpit/scripts/vf-cockpit-git-details.mjs
    - plugin/cockpit/scripts/tests/test-cockpit-git-details.sh
    - .planning/workstreams/fiabilite/phases/VFDO-78-git-dans-le-cockpit/78-08-RED-TRACE.md
  modified:
    - plugin/cockpit/scripts/vf-cockpit-git.mjs
    - plugin/cockpit/scripts/vf-cockpit-interface.json
requirements-completed: [GITC-07, GITC-08, GITC-09]
---

# 78-08 — détail d'un commit et état des worktrees, à la demande (GITC-07, 08, 09)

Module `vf-cockpit-git-details.mjs` (129 lignes, plafond 220), deux routes GET de plus dans `routeGit` (`vf-cockpit-git.mjs`, 166 lignes), trois schémas touchés dans `vf-cockpit-interface.json`,
suite `test-cockpit-git-details.sh` (82 assertions, 0 échec, 7 mutants). Rouges et traces : `78-08-RED-TRACE.md`. Reprise après le crash : la suite laissée par le prédécesseur (X1 seulement) avait une fixture morte (lab sans `.planning`, le serveur ne démarrait pas), corrigée avant d'être rejouée.

## Ce que le serveur sert

**`GET /api/vf/git/commit?sha=<sha complet>`** -> code 200, 400 ou 404, corps `vibeflow/cockpit-git-commit@1`. Le sha est validé en deux temps : motif strict (`^[0-9a-f]{40}$`, `{64}` si `rev-parse --show-object-format` rend `sha256`), PUIS `rev-parse --verify --quiet --end-of-options <sha>^{commit}` qui doit rendre CE sha. Court, majuscules, `HEAD`, `v1`, `--all`, `-x`, sha suivi d'une espace, 41 caractères, paramètre vide ou absent : 400 `sha-invalide`. `0000…`, arbre, blob, tag annoté (le sha de l'objet tag n'est pas celui du commit pelé), sha bien formé inconnu : 404 `commit-inconnu`. Échec de lecture d'un commit reconnu : 200 `indisponible`.

```json
{ "schema": "vibeflow/cockpit-git-commit@1", "etat": "ok", "h": "<40>", "h7": "1ab200a", "p": ["<40>"],
  "auteur": "Alice", "date": "2023-11-14T23:15:00+00:00", "committer": "Alice", "dateCommit": "2023-11-14T23:15:00+00:00",
  "message": "sujet\n\ncorps ligne 2", "tronque": false,
  "fichiers": [{ "chemin": "a.txt", "ancien": null, "plus": 3, "moins": 1, "binaire": false }, { "chemin": "img.bin", "ancien": null, "plus": null, "moins": null, "binaire": true }, { "chemin": "renamed.txt", "ancien": "old.txt", "plus": 0, "moins": 0, "binaire": false }],
  "total": 3, "commandes": { "show": "git show --stat --end-of-options 1ab200a", "detacher": "git switch --detach --end-of-options 1ab200a" } }
```

- Message borné à 8 192 octets (`tronque: true`, coupe jamais au milieu d'un caractère), masqué des secrets, fins de ligne conservées (la classe de contrôles de `nettoie` moins `\n`). Aucun e-mail ni diff (`%ae`, `%ce`, `-p` absents du code, critère de la tâche 1).
- Fichiers : `diff-tree -r -z --numstat -M --no-commit-id`, **au plus 500** lus et `total` (le serveur ne retient pas 30 : la borne d'affichage « 30 fichiers puis et k autres » du mandat est une affaire d'écran, 78-06/10 lisent `fichiers.length` et `total` ; `fichiers` de plus de 30 sont servis exprès). Binaire : `binaire: true`, `plus`/`moins` `null`. Renommage : `ancien` et `chemin`. Racine : `--root`. Merge : `<sha>^1 <sha>` (premier parent seulement).

**`GET /api/vf/git/worktrees`** -> 200, `vibeflow/cockpit-git-worktrees@1`, calculé à la demande seulement (jamais dans `lireGit` ni le filet de 5 s).

```json
{ "schema": "vibeflow/cockpit-git-worktrees@1", "etat": "ok", "approximatif": false, "mention": null, "tronque": false,
  "worktrees": [{ "chemin": "/…/wt-sale", "nom": "wt-sale", "modifies": 3, "nonSuivis": 2, "plus": false, "propre": false,
    "avance": 0, "retard": 7, "avanceOrigin": 0, "retardOrigin": 5, "commande": "cd -- '/…/wt-sale'" }] }
```

- `modifies` inclut les conflits ; `nonSuivis` au sens `-unormal` (un dossier non suivi compte pour une entrée) ; borne de 200 entrées lues, `plus: true` au-delà (`nonSuivis` vaut alors 200). `propre` = tout à zéro ; `null` si le status a échoué (dossier disparu).
- `avance`/`retard` = commits du worktree absents de la base / de la base absents du worktree (`rev-list --left-right --count refs/heads/<base>...<oid>`, base locale sinon `origin/<base>`). `avanceOrigin`/`retardOrigin` : même calcul sur `origin/<base>`, **seulement quand elle diverge de la locale**, sinon `null`.
- `approximatif` vrai et `mention` « approximatif : filtres du dépôt non exécutés » quand `filtresDeclares` trouve un pilote. Ce dépôt-ci en déclare un (git-lfs côté utilisateur) : `approximatif: true` ici.
- Au plus 50 worktrees (`tronque`), échéance globale de 8 s. `commande` = `cd` cité, `null` si le chemin serait masqué à l'écran (P78-D-27).
- Un seul `lancerGit` par worktree pour le status ; deux ou trois `rev-parse`, un `worktree list`, un `rev-list` par worktree et par base.

## Complément : refs sans date (P78-D-31) dans `GET /api/vf/git`

`sansDate` (git.mjs) écarte, avant `lireRefs`, toute ligne de `for-each-ref` dont la date est vide (tag vers un blob ou un arbre, distante vers un blob) ; le nombre est servi dans **`refsIgnorees`** (champ ajouté à `requis` du schéma `cockpit-git@1`). Le reste du graphe est lu. Jusque-là un tel dépôt rendait `indisponible`.
Un tag vers un arbre fait aussi échouer `%(ahead-behind:)` : le repli `rev-list` de 78-05 se joue alors (50 branches comptées au plus), inchangé.

## Auteurs : ceux de la fenêtre

`auteurs` de `GET /api/vf/git` est agrégé sur les commits lus (500 de la base, 500 des non mergées), pas sur l'historique. Le dit : la `description` du schéma `cockpit-git@1` (X5.2c) ; fixture de 511 commits : `[["Recent", 500]]`, l'auteur du 511e en est absent, `bornes.tronque: true` (X5.2b). **78-10 ne doit pas écrire « tous les auteurs ».**

## Champs ajoutés à `vf-cockpit-interface.json` (lus par 78-06)

- `schemas["vibeflow/cockpit-git-commit@1"]` (neuf) : `requis`, `fichier.requis`, `etats`, `interdits`.
- `schemas["vibeflow/cockpit-git-worktrees@1"]` (neuf) : `requis`, `worktree.requis`, `etats`, `interdits`.
- `schemas["vibeflow/cockpit-git@1"]` : `refsIgnorees` dans `requis`, description complétée (auteurs, refsIgnorees). Aucun champ retiré.

## Durées (citées, non assertées)

Sur ce dépôt (10 worktrees, git 2.50.1) : `detailCommit` 178 ms ; `etatWorktrees` 1 189 ms, SYNCHRONE (`execFileSync`) : la boucle du serveur est bloquée ce temps-là à chaque ouverture du tiroir. À savoir pour 78-06/10 : n'appeler qu'à l'ouverture, pas en boucle.

## Écarts

1. **Ordre tests/code de la tâche 2** : `etatWorktrees` et son aiguillage sont entrés dans le commit de la tâche 1 (module rédigé d'un trait). Rouge de X2/X3 rejoué sur une copie sans la route ni le corps (voir la trace) ; le schéma worktrees, `refsIgnorees` et P78-D-31 ont, eux, leur rouge sur le code réel.
2. **Bornes à 500 fichiers côté serveur, pas 30** (voir plus haut) : le plan et ses `must_haves` disent 500, le mandat parle de 30 pour l'écran.
3. **Fixture** : lab GSD (`.planning`, `.vibeflow` dans `.git/info/exclude`) pour que le serveur démarre sans fausser les comptes de non suivis.
4. **X1.1d du prédécesseur** prenait le `@` du champ `schema` pour un e-mail : test corrigé, pas le code.
5. Pas de serveur sur le dépôt piégé : X3.1/X3.3 appellent les fonctions du module (`etatWorktrees`, `detailCommit`) que la route appelle telles quelles ; les trois témoins de route (405, Origin tierce, sans jeton) sont joués sur le serveur réel, pour chaque route neuve.
6. `vf-cockpit-git.mjs` : `SCHEMAS_ROUTES` pour que l'exception rende le bon schéma par route.

## Points ouverts

- `detailCommit` : pas de page de fichiers au-delà de 500 (`total` seul).
- `etatWorktrees` ne distingue pas un worktree verrouillé ou prunable (dossier absent : `modifies`/`propre` `null`).
- Sha256 : joué sur un dépôt réel `--object-format=sha256` (X1.7).

## Suites rejouées

`test-cockpit-git-details.sh` 82/0 · `git` 82/0 · `git-env` 70/0 · `serveur` 70/0 · `git-graphe` 50/0 · `forme-claude` 56/0 · `assemblage` 40/0 · `signal` 76/0 · `avancement` 62/0. `test-cockpit-git-commandes.sh` (78-03, ne lit aucun fichier de ce plan) : non rejouée en entier, interrompue à C2.1a (lente sous charge). `check-file-size.sh` : exit 0.

## Correction ciblée — P78-D-32 : FAITE (2026-11-06)

`GET /api/vf/git/worktrees` ne bloque plus la boucle. Périmètre élargi par le manager de reprise (message direct) à `vf-cockpit-git.mjs` (route) et `vf-cockpit-paths.mjs` (exécuteur).
- `vf-cockpit-paths.mjs` : `lancerAsync` (execFile, mêmes options, `timeout` = temps restant, même sémantique `{sortie, code, tronque, absent, echeance}`), `lancerGitAsync` et `filtresDeclaresAsync` à côté de `lancerGit` : même `envGit`, mêmes `argsGit`/`GIT_SUR`, mêmes filtres vidés. `FIN` (portée synchrone) ne survit pas à un `await` : l'appelant passe sa date butoir (`finDans(ms)` → `fin`).
- `etatWorktrees` est `async` (git séquentiels, un worktree après l'autre) ; `routeGit` attend la promesse (`.then`), repli `indisponible` sur rejet. `brancheBase` (2 lectures de refs, quelques ms) reste synchrone, hors des fichiers autorisés.
- Témoin X6.1 (test-cockpit-git-details.sh) : git emballé (`status` dort 0,4 s, 5 worktrees, lecture > 1,5 s), vrai `routeGit` dans un serveur en processus ; une requête légère émise 150 ms après est servie avant la fin de la lecture.
- Mutant M-SYNC (X6.2) : `lancerGitAsync` redevient `async (...a) => lancerGit(...a)` : rougit X6.1 pour la bonne raison (légère avant lourde = false, lecture ok, lente).
- Garde E6 : E6.5 (test-cockpit-git-env.sh) : `execFile(cmd` n'existe que dans `paths.mjs`, le vrai jeu de scripts passe la garde, un `execFile('git', …)` planté dans `git-details.mjs` la rougit à la bonne ligne. Limite connue : une forme `promisify(execFile)('git', …)` n'est pas vue par la regex (déjà vrai avant).
- Adaptations de la suite : `det.mjs` attend la promesse (`await`), ancre du mutant M-FILTRES-STATUS réécrite sur la forme asynchrone.

## Correction audit (2026-11-06) — A3, A4, A5, A6 : FAITE

Mandat de correction CIBLÉE de `mgr78-reprise` après l'audit sécurité en lecture. Traces : section « Correction audit » de `78-08-RED-TRACE.md`.
- **A3 / P78-D-38** : `worktreeVerifie(communReel, chemin)` (details.mjs, fs seul, aucun git) : un worktree n'est lu que si `<chemin>/.git` est le dépôt principal (un dossier, jamais un lien, dont le chemin réel est le dossier commun) ou un fichier `gitdir: X` dont X résolu est exactement `<commun>/worktrees/<id>` et dont le `gitdir` désigne en retour ce `.git`. **Champ nouveau `verifie` (boolean)** sur chaque entrée de `GET /api/vf/git/worktrees` ET de `worktrees[]` de `GET /api/vf/git` (documenté dans `vf-cockpit-interface.json`, `worktree.requis`). Valeur `false` = « non vérifié » : `status` jamais lancé, `modifies`, `nonSuivis`, `propre`, `avance`, `retard`, `avanceOrigin`, `retardOrigin` et `commande` valent `null`, `plus` vaut `false` ; dans le graphe la commande `cd` du worktree et celles des étiquettes de branche qui le portent sont `null`. **Rendu page à brancher** (hors périmètre : un autre worker modifie `assets/ui/77-vf-git-*.js`) : afficher « non vérifié » quand `verifie === false`, au lieu de comptes absents.
- **A4** : `detailCommit` est `async` (`lancerGitAsync`, échéance globale `BORNES_DETAILS.echeanceMs` = 8 s, sortie de `diff-tree` au plus `octetsNumstat` = 16 Mio) ; la route attend la promesse (repli `indisponible` sur rejet) ; un délai ne se lit plus « commit-inconnu » (404) mais `indisponible`. Détection de renommages bornée : `diff-tree -l<BORNES_DETAILS.renommages>` (400) : au-delà, git ne cherche plus de renommage inexact et les rend en ajout + suppression (les renommages exacts, détectés à bas coût, restent des renommages). Mesure à 120 000 renommages : avant boucle gelée 10 041 ms ; après 8 005 ms (échéance) minuteur de 50 ms sonné à 50 ms, détail `indisponible` (un commit de 240 000 entrées n'est plus servi, jamais une boucle gelée).
- **A5** : `signatureGit` est asynchrone (`lancerGitAsync`), échéance globale de tick `ECHEANCE_TICK_MS` (2 s), jamais deux ticks en vol, RETRAIT après un git muet (5 s, doublé à chaque échec, au plus 2 min ; un échec rapide, hors dépôt, ne déclenche pas de retrait). `live.mjs` : l'appel est `.then` ; le premier calcul sème `gitSig` sans événement. `lireGit` d'un git qui ne répond pas rend `indisponible`, jamais `absent` (`vf-cockpit-git-entete.mjs`, interdit, rend `absent` pour une sortie vide : `assembler` sonde alors `rev-parse --git-dir` et lit `delai`).
- **A6** : `--` ajouté à TOUTES les lectures qui passent une révision : `git.mjs` (`log` de la base, `log` des non mergées, `rev-list` de repli), `git-details.mjs` (`log -1`, `diff-tree`, `rev-list` de `compteLR`), `arbres.mjs` (`rev-list --count HEAD..<ref>`). `rev-parse --verify` n'a pas besoin de `--` (mesuré). Liste dérivée par grep, donnée au RED-TRACE.
- **Adaptations de suites** : `det.mjs` (details) attend `detailCommit` ; `temps_sig` (signature) attend `signatureGit` ; ancre de M-VERIFY réécrite sur la ligne qui porte désormais `v.delai || v.echeance` ; mutant M-SYNC (X6.2) remplace l'import `lancerGitAsync, ` par `lancerGit, ` (details n'importe plus `lancerGit`).
