# 71-BRANCHEMENTS-MERGE — recensement des branchements de la Phase 71 pour le merge (P71-D-17)

Branche `feat/phase-71-terminal`, code figé à `227be6c5`, base `7370d604`. Le recensement ne recopie pas les SUMMARY : la liste des
fichiers existants touchés est **re-dérivée** de `git diff --name-status 7370d604..227be6c5 -- plugin/` (statut M, relevé via `rtk proxy`,
le 2026-11-03), puis rapprochée des sections « Branchements à recenser pour le merge » de 71-01, 71-07, 71-10, 71-11 et du plan 71-09.
Principe de la phase (P71-D-17, P71-D-20) : tout le code vit dans des fichiers neufs ; les points de branchement dans des fichiers
existants sont minimaux et listés ici.

## 1. Fichiers existants touchés sous `plugin/` (statut M)

Sept fichiers au diff `7370d604..227be6c5`, plus cinq posés par 71-09 (sa propre tâche 2) :

| # | Fichier existant | Plan | Changement | Conflit avec la 69 |
|---|------------------|------|------------|--------------------|
| B1 | `plugin/cockpit/scripts/vf-cockpit.mjs` | 71-10 | `--terminal` dans `lireArgs` et `AIDE`, import `node:crypto`, fonctions `ecrireAmorce`, `amorcer`, `ouvrir`, `ouvrirQ`, `attendreTerminal` insérées avant `assemblerLab`, `demarrer` (`--no-open` si `avecQ`, `--terminal`), bloc `open` de `main` | **faible** : la 69 ne touche pas ce fichier (mesuré sur `origin/feat/phase-69-suivi-travail`) ; si elle touche `main`, fusion à la main du bloc `open` |
| B2 | `plugin/cockpit/skills/cockpit-moteur/assets/serve.mjs`, `sendPage` | 71-01 | `pageCsp(html) + (TERM ? TERM.frameSrc() : '')` ; la ligne `const csp = ` de `pageCsp` est intacte | **possible** : la 69 touche `serve.mjs` (une ligne, la route `/equipe.html`) ; hunks distincts |
| B3 | idem, `const inject` | 71-01 | `let TERM = null` + import dynamique sous `has('terminal')` ; `+ (TERM ? TERM.injection() : '')` | **possible** : la 69 passe `inject` à sa page équipe ; le tiroir s'y retire de lui-même (chemin hors `/`, `/index.html`, `/project.html` : rien n'est créé, TU.12, P71-PL-15) |
| B4 | idem, garde d'inactivité | 71-01 | `&& !TERM?.occupe()` | faible |
| B5 | idem, routage `/api/` | 71-01 | `GET /api/vf/terminal` -> `TERM.routeP` avant `VF.route` | faible |
| B6 | idem, `listening` | 71-01 | `TERM?.demarrer(port)` après l'écriture de `server.json` | faible |
| B7a | `plugin/cockpit/amont/patches/assets__serve.mjs.diff` | 71-01 | diff amont régénéré pour le patch `vibeflow P25` | **certain** : la 69 régénère le même diff (patch `P24`) ; à refaire APRÈS la fusion de `serve.mjs` |
| B7b | `plugin/cockpit/skills/cockpit-moteur/VENDORED.txt` | 71-11 | ligne `PATCH assets/serve.mjs …,P20,P25` (description de P25 ajoutée), six `AJOUT assets/vendor/xterm/…`, `AJOUT terminal/vf-cockpit-pty.py`, `TAILLE assets/serve.mjs 614` (610 avant) | **certain** : la 69 ajoute `P24` et passe `TAILLE` à 611 ; fusion à la main |
| B9 | `plugin/cockpit/scripts/tests/test-cockpit-vendor.sh` | 71-11 | V2 « quatre composants » -> « six composants » ; section V9 (V9.1 à V9.4, mutant M-SHA) | faible |
| B10 | `plugin/cockpit/skills/cockpit-moteur/LICENCES-TIERCES.txt` | 71-11 | deux lignes (xterm, addon-fit) | faible |
| B12 | `plugin/cockpit/scripts/tests/test-cockpit-chaine-xss.sh` | 71-08 | **une ligne de commentaire d'en-tête** (numstat `1 0`) renvoyant à `test-cockpit-terminal-xss.sh`, assertions inchangées (22 PASS) | faible (la 69 ne touche pas cette suite) |
| B8a | `plugin/cockpit/README.md` | 71-09 | en-tête Version, usage `--terminal`, « Terminal intégré », « Confidentialité et réseau », « Limites connues » (ajouts seulement) | **certain** : la 69 modifie le même fichier ; ajouter, ne pas réécrire |
| B8b | `plugin/cockpit/CHANGELOG.md` | 71-09 | entrée v1.1.0 en tête | **certain** : la 69 écrit aussi une entrée v1.1.0 ; et `origin/main` porte v1.0.1 et v1.0.2 que la branche n'a pas (voir § 3) |
| B8c | `plugin/cockpit/VERSION`, `plugin/cockpit/module.json` | 71-09 | `v1.1.0` ; description de `module.json` (« Lecture seule, sauf le terminal intégré ouvert par --terminal… »), `requires: []` inchangé | **certain** : la 69 bumpe aussi en v1.1.0 ; `origin/main` est en v1.0.2 |
| B8d | `plugin/cockpit/skills/vf-cockpit/SKILL.md` | 71-09 | `--terminal` dans la liste des options (étape 2 de « Lancer »), corps seulement, frontmatter intact | **possible** : la 69 modifie ce fichier ; vérifier au merge |
| B11 | `README.md`, `README.fr.md` (racine) | 71-09 | le seul nombre de la phrase « N suites » (142 -> 152), une ligne par fichier | **certain** : la 69, la 70 et la 68 ajoutent aussi des suites ; recompter après la fusion |

Fichiers non touchés par la phase : `plugin/cockpit/scripts/vf-cockpit-server.mjs` (la 69 le modifie ; couplage de lecture ci-dessous),
`plugin/cockpit/scripts/vf-cockpit-build.mjs` (le build copie les nouveaux `vf-cockpit-terminal-*.mjs` par motif), `plugin/cockpit/amont/SYNCHRO.md`,
`plugin/cockpit/scripts/tests/chrome-session.mjs`, tout le dossier `assets/ui/` (rien n'y est ajouté : P71-D-20, la CSP de page reste octet pour octet).

Fichiers neufs (aucun conflit possible) : 24 sous `plugin/cockpit/scripts/` (modules `vf-cockpit-terminal*.mjs`, dix suites
`test-cockpit-terminal-*.sh`, `terminal-aux.mjs`, `temoins/hostile.py`, `temoins/plein-ecran.py`), six fichiers sous
`skills/cockpit-moteur/assets/vendor/xterm/`, `skills/cockpit-moteur/terminal/vf-cockpit-pty.py`.

## 2. Couplages de lecture avec le code de la 69 (aucun fichier à fusionner, à contrôler au merge)

- **`#ask`, `--pw`, `--hh`** : la feuille du tiroir (`scripts/vf-cockpit-terminal-tiroir-style.mjs`) cible `body.vf-term-ouvert #ask`,
  `right: max(16px, var(--pw))` et `top: calc(var(--hh) + 12px)`. Si la 69 renomme `#ask`, `#panel`, `--pw` ou `--hh`, cette feuille est
  le seul endroit à ajuster (71-07).
- **Page équipe de la 69 et `inject`** : si la 69 passe `inject` à `/equipe.html`, le tiroir ne s'y crée pas (assertion TU.12 de
  `test-cockpit-terminal-tiroir.sh`) ; le comportement attendu est conservé, la suite doit rester verte.
- **`VF?.ptoken`** : `serve.mjs` passe `jetons: () => [token, VF?.ptoken]` à `preparerTerminal` ; `ptoken` et `jetonValide` viennent de
  `vf-cockpit-server.mjs`, que la 69 modifie. Un renommage côté 69 casserait la liste des jetons à ne jamais laisser entrer dans le shell
  (P71-D-03, TERM-06).
- **`window.VF_COCKPIT_SERVER.token` et `x-vf-cockpit-token`** : le tiroir (71-07) lit ce jeton de page et pose cet en-tête ; noms de la sortie
  renommée, à garder.
- **`window.__vfFrTraduire` et l'inventaire français** : aucune chaîne du tiroir n'est ajoutée au dictionnaire (`78-vf-fr-dict-*`), le tiroir
  est servi à la volée ; si la 69 ou la 70 déplace l'inventaire (`test-cockpit-chrome-fr.sh`), contrôler que le texte du tiroir reste hors inventaire.

## 3. Procédure de fusion avec la 69 (T-71-45)

Ordre conseillé : fusionner la branche de la 69 d'abord (elle porte `P24`), puis celle de la 71 (elle porte `P25`), sans quoi chaque
régénération est à refaire. Dans tous les cas :

1. **`serve.mjs`** : les hunks P25 (B2 à B6) sont distincts de la ligne `/equipe.html` de la 69 ; fusionner les deux, ne jamais écraser l'un par l'autre.
2. **`VENDORED.txt`** : fusionner la ligne `PATCH assets/serve.mjs` en `…,P20,P24,P25` avec les **deux** descriptions (P24 et P25) ; garder les sept `AJOUT` de la 71 ;
   recompter `TAILLE assets/serve.mjs` **APRÈS** la fusion de `serve.mjs` (614 sur la 71, 611 sur la 69 : aucune des deux valeurs n'est la bonne, c'est `wc -l` qui tranche).
3. **Diff amont** : régénérer `amont/patches/assets__serve.mjs.diff` par `bash plugin/cockpit/amont/synchro.sh regenerer-patch assets/serve.mjs` APRÈS la fusion de `serve.mjs`.
   Constat de 71-01 (F2) : `regenerer-patch` sans clone amont échoue dès que `serve.mjs` a changé ; voie suivie : reconstruire l'amont en inversant le diff existant sur la version
   fusionnée (sha256 égal à `amont-92d6854.sha256`), le poser comme faux clone `skills/floorplan/assets/serve.mjs`, puis `regenerer-patch assets/serve.mjs <faux-clone>`.
   Terminer par `bash plugin/cockpit/amont/synchro.sh verifier` : il doit rendre « amont v0.6.0 @ 92d6854 retrouvé à l'octet ».
4. **README, CHANGELOG, VERSION, `module.json` du module** : ajouter sans réécrire. La version de la 71 est **recalculée** selon P71-PL-12 (mineure suivante du plus haut de la
   branche et de `origin/main` au moment de la fusion) : la 69 bumpe en v1.1.0 et `origin/main` est déjà en v1.0.2, donc fusionnée après la 69 la 71 devient v1.2.0 ; deux entrées de
   CHANGELOG à ordonner, et les entrées v1.0.1 et v1.0.2 de `origin/main` (absentes de la branche, qui est en v1.0.0) à reprendre. Aligner d'un geste `VERSION`, `module.json` et l'en-tête
   Version du README (`check-version-sync.sh`, points 6 et 8). La `VERSION` racine, les manifestes racine, le tag et la release restent un geste humain.
5. **README racine** : le nombre de suites est **recompté** après la fusion (`bash scripts/check-version-sync.sh`, ou `find plugin scripts -path '*/tests/test-*.sh' | wc -l`), jamais additionné à la
   main : la 69 ajoute quatre suites (`test-cockpit-avancement`, `-equipe`, `-forme-claude`, `-transcript`), la 70 et la 68 en ajouteront aussi ; la 71 en ajoute dix (142 -> 152 sur sa branche).
6. **Rejouer après fusion** : les dix suites `test-cockpit-terminal-*.sh`, `test-cockpit-chaine-xss.sh`, `test-cockpit-vendor.sh`, `test-cockpit-securite.sh`, `test-cockpit-serveur.sh`,
   `test-cockpit-reseau.sh`, `synchro.sh verifier`, `check-version-sync.sh`, `check-file-size.sh --all`.
7. **Recette humaine** : à jouer sur le code fusionné si la fusion touche `serve.mjs` ou `vf-cockpit.mjs` (la recette actuelle, `71-RECETTE-HUMAINE.md`, porte sur `227be6c5`).

## 4. Hors fichiers du dépôt

- **Manuel utilisateur** (`manual/fr/03-modules/catalogue.md`, `manual/fr/06-reference/skills.md` et leurs pages anglaises) : ils décrivent le cockpit « en lecture seule ». Aucun gate ne le
  compte ni ne le juge ; la mention de `--terminal` est à faire dans la passe de documentation qui suit les fusions des Phases 68 à 71.
- **`check-gate-touche` / `check-ajout-retrait`** : aucun trailer requis pour 71-09 (aucun fichier de la surface de `check-gate-touche.sh`, aucun `SKILL.md` ajouté).

## 5. Ajouts des tours de correction (manager, 2026-11-04)

Re-dérivé par `git diff --name-status 7370d604..c023f54a -- plugin/` (statut M) : 17 fichiers existants modifiés, contre 7 au recensement initial.
Les dix nouveaux viennent des correctifs F1, F6 (lanceur), N2 (binaires résolus en chemin absolu, P71-D-29), de la police (J3) et de la doc.

| Fichier existant | Touché par | Ce que la 71 y change | Conflit attendu avec la 69 |
|---|---|---|---|
| `plugin/cockpit/scripts/vf-cockpit-who.mjs` | N2 | `git`, `bash` en chemin absolu | **oui** : la 69 réécrit ce module (équipe au travail) — reporter la résolution absolue sur sa version |
| `plugin/cockpit/scripts/vf-cockpit-live.mjs` | N2 | `bash` en chemin absolu | **oui** : la 69 le modifie |
| `plugin/cockpit/scripts/vf-cockpit-planning.mjs` | N2 | `git` en chemin absolu | **oui** : la 69 le modifie (avancement) |
| `plugin/cockpit/scripts/vf-cockpit-paths.mjs` | N2 | `git` en chemin absolu | non prévu par la 69 |
| `plugin/cockpit/scripts/vf-cockpit-build.mjs` | N2 | `PATH` assaini pour les enfants du moteur | non prévu par la 69 |
| `plugin/cockpit/scripts/vf-cockpit.mjs` | 71-10, F1, F6, M6, N2 | `--terminal`, adresse de Q reconstruite, page de redirection 0600, `ps`/`open`/`xdg-open` absolus, `--no-open` toujours passé au serveur (le lanceur ouvre lui-même le navigateur, avec ou sans `--terminal`) | oui (bloc `open` de `main`) |
| `plugin/cockpit/skills/cockpit-moteur/LICENCES-TIERCES.txt`, `VENDORED.txt` | 71-11, J3 | xterm 6.0.0, addon-fit 0.11.0, JetBrains Mono 2.304 (OFL), P25, TAILLE 614 | oui (`PATCH` et `TAILLE`) |
| `plugin/cockpit/skills/vf-cockpit/SKILL.md` | 71-09, docs | `--terminal`, code 5 sur `server.json` planté | à vérifier |
| `plugin/cockpit/scripts/tests/test-cockpit-chaine-xss.sh` | 71-08 | une ligne d'en-tête (renvoi) | non |

Règle de fusion (inchangée) : recompter (`TAILLE`, nombre de suites des README racine), jamais additionner ; rejouer `synchro.sh verifier` et
toutes les suites `test-cockpit-*.sh` après la fusion de `serve.mjs`.

## 6. Après rebase sur main 19393cc3 (2026-11-04)

Branche `feat/phase-71-terminal` rebasée sur `origin/main` `19393cc3` (H-1, cockpit v1.1.2 ; la Phase 69 est déjà sur `main`). Tête de la branche à la rédaction : `2204a239`. Les
sections 1 à 5 décrivent la base `7370d604` : où elles disent `P25`, `TAILLE 614`, « fusionner la 69 d'abord » ou « v1.1.0 », c'est la présente section qui fait foi.

- **Patch du terminal : `P26`.** `P25` est celui de H-1 (ligne `process.env.PATH = assainirPath(…)` en tête de `serve.mjs`, `vibeflow P25`). Le terminal est renuméroté `P26` :
  `serve.mjs` (marqueurs `vibeflow P26`, lignes 172-174, 220, 500, 515, 604), `amont/patches/assets__serve.mjs.diff`, et la ligne `PATCH assets/serve.mjs …,P24,P25,P26` de
  `VENDORED.txt` (qui porte la description de chacun). Les phrases du README et du CHANGELOG qui disaient `P25` pour le terminal disent `P26`.
- **`TAILLE assets/serve.mjs 616`** (612 sur `origin/main`, 614 sur l'ancienne base de la 71), relevé par `wc -l` de `skills/cockpit-moteur/assets/serve.mjs` ; `synchro.sh verifier`
  doit rendre « amont v0.6.0 @ 92d6854 retrouvé à l'octet ». Si la PR #200 touche `serve.mjs` ou la ligne `TAILLE`, recompter par `wc -l`, jamais additionner.
- **Variantes N2 abandonnées au profit de H-1.** Les résolutions en chemin absolu que N2 avait posées dans `vf-cockpit-build.mjs` (PATH assaini du moteur), `vf-cockpit-live.mjs`
  (`bash`), `vf-cockpit-planning.mjs` (`git`) et `vf-cockpit-who.mjs` (`git`, `bash`) ne sont pas reprises : ces quatre modules sont ceux de `main`, qui passent `envEnfant`
  de `vf-cockpit-env.mjs` (import en tête de chacun). Ce que la 71 garde de N2 : le lanceur (`vf-cockpit.mjs` : `ps`, `open`, `xdg-open`, `python3` par `resoudreBinaire`) et
  `vf-cockpit-paths.mjs`, où `gitCommonDir` tient N2 et H-1 ensemble (`7bb14f15` : binaire cherché dans le `PATH` assaini de `envEnfant`, appelé par chemin absolu).
  Conséquence pour le moteur d'assemblage : repli `/usr/bin:/bin:/usr/sbin:/sbin` (`PATH_REPLI`) au lieu de `/usr/bin:/bin` (N8) ; `PATH_SYSTEME` ne sert plus qu'au repli de `resoudreBinaire`.
- **Transport du PATH d'origine.** Le lanceur pose `VF_COCKPIT_PATH_ORIGINE` (`vf-cockpit.mjs:180`) pour le serveur ; `envShell` le restitue en `PATH` du shell puis le retire
  (`vf-cockpit-terminal-env.mjs:24-25`). Le processus de Q (`envDuProcessusTerminal`, `vf-cockpit-terminal.mjs:25-26`) reçoit `envEnfant(lab, process.env)`, donc assaini ; le shell reçoit l'environnement
  d'origine par l'IPC (`envOrigine`). Limite à garder : un serveur lancé hors du lanceur donne au shell le `PATH` assaini. Test repointé : `87f63b7a` (M-PATH-VIDE sur `vf-cockpit-env.mjs`).
- **Sentinelle T7.5 en `vf-term-`** (`test-cockpit-terminal-activation.sh:101`, `f89b3a54`) : la sentinelle `vf-term` se confondait avec `vf-termines` (classe de la Phase 69 présente dans les pages servies) ;
  elle cherche `vf-term-` (avec le tiret) et `VibeFlow (71-`. Ne pas la raccourcir au merge.
- **Compteur de suites recompté : 160** (`find plugin scripts -path '*/tests/test-*.sh'` = 160 ; `origin/main` en compte 150, la 71 en ajoute dix). `README.md` et `README.fr.md` disent 160 ;
  `bash scripts/check-version-sync.sh` rend ✓ pour les deux. Ce compteur est à recompter, jamais à additionner, après tout merge de la #200 ou de la 68.
- **Version : v1.2.0**, après v1.1.2 de H-1 (`VERSION`, `module.json`, en-tête du README alignés ; `check-version-sync.sh` ✓). Sections W1 à W4 et rebase ajoutées au CHANGELOG, phrases du README mises à jour (Q dans son processus,
  arrêt et Python 3 absent dits, tiroir, PATH d'origine, H-1).
- **Si la PR #200 (Phase 70, brouillon ouvert à la rédaction) est mergée avant** : un dernier rebase léger, et rien d'autre. La #200 touche, côté cockpit (relevé `gh pr view 200 --json files`, 2026-11-04),
  `CHANGELOG.md`, `README.md`, `VERSION`, `module.json`, `VENDORED.txt` (nouveau patch sur `40-tour.js`, ligne `PATCH` de `assets/ui/40-tour.js`, et peut-être `TAILLE`), `vf-cockpit-build.mjs`, `vf-cockpit-who.mjs`
  et les fichiers de `assets/ui/`. À refaire alors : (1) CHANGELOG : ordonner les deux entrées, la 71 reste v1.2.0 sauf si la #200 prend déjà v1.2.0 (alors v1.3.0, P71-PL-12), aligner `VERSION`, `module.json`
  et l'en-tête du README (`check-version-sync.sh`) ; (2) `VENDORED.txt` : fusionner à la main, ne pas toucher à la ligne `PATCH assets/serve.mjs` (la #200 n'y touche pas), recompter `TAILLE` seulement si `serve.mjs` a bougé ;
  (3) README : ajouter, ne pas réécrire ; (4) `vf-cockpit-build.mjs` et `-who.mjs` : prendre la version de la #200 (la 71 n'y garde rien depuis le rebase) ; (5) recompter les suites (150 + celles de la #200 + 10) ;
  (6) rejouer les dix suites `test-cockpit-terminal-*.sh`, `test-cockpit-chrome-fr.sh`, `test-cockpit-responsive.sh`, `test-cockpit-projet.sh` et `synchro.sh verifier`. La #200 n'a aucun recoupement avec les fichiers
  `vf-cockpit-terminal*.mjs` (neufs), ni avec le lanceur `vf-cockpit.mjs`.
