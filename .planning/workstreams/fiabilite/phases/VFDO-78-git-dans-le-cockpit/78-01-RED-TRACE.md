# 78-01 — trace des rouges (témoin rouge joué AVANT le code)

Base : `3b81a670` (tête de `feat/phase-78-git-cockpit` à l'ouverture du plan). Git 2.50.1. Suite : `plugin/cockpit/scripts/tests/test-cockpit-git-env.sh`.
Commande : `cd <worktree> && bash plugin/cockpit/scripts/tests/test-cockpit-git-env.sh`

## Tâche 1 — tracer (E1.1, E2.1, E3.1)

Témoin positif E1.1 : `git --no-optional-locks -c core.fsmonitor=false -C <piégé> status --porcelain=v2` sur `f.txt` stat-dirty
(`touch -t` à -1 min, `filter.f.process` déclaré) pose le marqueur PROC. Résultat : PASS (la sonde n'est pas aveugle).

| Sonde | Assertion | Attendu | Obtenu (base) |
|---|---|---|---|
| E2.1 | `shBorne('git', [...GIT_SUR,'-C',P,'status','--porcelain','--','f.txt'])` ne lance pas `filter.f.process` | `absent` | `posé` |
| E3.1 | `collectWho` (status du DAG suivi stat-dirty, `*.dag.json filter=f`, vf-cockpit-who.mjs:116) ne lance pas le filtre | `absent` | `posé` |

Témoins verts sur la base : E0.1, E0.2, E1.1, E2.1b (sortie de status conforme), E3.0 (who lit bien le nœud `nx`, le chemin git est parcouru).
Bilan : `6 PASS / 2 FAIL` — les deux rouges attendus, pour la bonne raison (marqueur de filtre posé).

## Tâche 2 — variables héritées, options de lecture, sortie tronquée, mutants (suite complète E0 à E7)

Les variables GIT_*, les options de lecture et les filtres sont posés d'un seul tenant par `envGit`/`argsGit`/`shBorne` dès la tâche 1
(commit `9f8ae8ce`) : leur rouge ne peut donc pas se rejouer sur la tête. Il est joué sur la BASE, `git archive 3b81a670 plugin/cockpit/scripts`
extrait dans le scratchpad (`78-01-base/`), avec la suite complète copiée dedans. Commande :
`bash <scratchpad>/78-01-base/plugin/cockpit/scripts/tests/test-cockpit-git-env.sh` — bilan base : `37 PASS / 33 FAIL`.

| Sonde | Assertion | Attendu | Obtenu (base 3b81a670) |
|---|---|---|---|
| E2.2 | `GIT_DIR=<leurre>` hérité par node : sujet rendu par shBorne | `SUJET-REEL` | `LEURRE` |
| E2.3a | `GIT_WORK_TREE` hérité : `rev-parse --show-toplevel` | l'arbre piégé | l'arbre leurre |
| E2.3b | `GIT_CONFIG_PARAMETERS='core.abbrev=12'` hérité | 7 caractères | 12 |
| E2.3c | `GIT_CONFIG_COUNT/KEY_0/VALUE_0` (core.abbrev=12) hérités | 7 caractères | 12 |
| E2.3d | `GIT_INDEX_FILE` (index vide) hérité : status de `f.txt` | vide | `D  f.txt` / `?? f.txt` |
| E2.4 | `log -p -1` par shBorne : textconv lancé | `absent` | `posé` |
| E2.5c/d/e/f | emballage git : options de lecture après `log`, pas de GIT_DIR, `VF_COCKPIT_GIT_DURCI=1`, `GIT_OPTIONAL_LOCKS=0` | présents / absent | absents / `GIT_DIR` présent |
| E3.2 | `arbresGit` sous `GIT_DIR` leurre | arbre du dépôt piégé | arbre du leurre |
| E3.3 | `gitCommonDir` sous `GIT_DIR` leurre | `<piégé>/.git` | `<leurre>/.git` |
| E3.4 | tags de `readPlanning` sous `GIT_DIR` leurre | `v1.0.0` | le tag du leurre |

Témoins (E1.1 à E1.8, E3.4a) verts sur la base : le piège se déclenche git brut (filtre, textconv, `GIT_DIR`, `GIT_WORK_TREE`, `GIT_CONFIG_PARAMETERS`,
`GIT_CONFIG_COUNT`, `GIT_INDEX_FILE`, sortie gpg de `log.showSignature`). Aucune variante `core.worktree` par config : sondée, git l'ignore sans `GIT_DIR`
(E1.5/E1.6 mesurent donc `core.abbrev`, qui change réellement la sortie).

Rouge sur la TÊTE `76b5a426` (lancerGit absent) : E4.1 à E4.5, E5.1, E5.2a, E5.3, M-ENV (volet E5.2a), M-FILTRES (volet E5.1), M-LECTURE (volet E5.2), M-TRONQUE :
obtenu `illisible` (l'export `lancerGit` n'existe pas) ; bilan tête : `57 PASS / 13 FAIL`.
Note : E5.2 (textconv `absent`) est vert à vide quand `lancerGit` manque ; c'est E5.2a (sujet réel présent dans la sortie) qui rougit pour la même cause, d'où sa présence.

### Vert après `lancerGit` (commit `feat(78-01): lancerGit…`) : `70 PASS / 0 FAIL`, exit 0

Mutants (copies de `plugin/cockpit/scripts` dans le scratchpad, une ligne remplacée par `mutsub.mjs`, ancre vérifiée : « ancre absente » = FAIL). Chacun est rejoué avec la
valeur obtenue ASSERTÉE (pas seulement « différent ») : un mutant qui rougirait pour une autre raison ne passerait pas l'assertion.

| Mutant | Ligne mutée | Sonde rougie | Valeur obtenue sur le mutant (= le rouge assertée) |
|---|---|---|---|
| M-ENV | `if (!GIT_HERITE.test(k)) e[k] = v;` -> `e[k] = v;` | E2.2, E2.3a, E5.2a | sujet `LEURRE` ; toplevel = arbre leurre ; log lancerGit = `LEURRE` |
| M-FILTRES | `configFiltres` = `[] \|\| …` | E2.1, E5.1 | marqueur `PROC` posé (shBorne ET lancerGit) |
| M-LECTURE | `ins = OPTIONS_LECTURE[sous] \|\| [];` -> `ins = [];` | E2.4, E5.2, E2.4b | marqueur `TEXTCONV` posé (shBorne ET lancerGit) ; sortie `SORTIE-GPG-FACTICE` dans le hash |
| M-TRONQUE | `tronque: e.code === 'ENOBUFS'` -> `false && …` | E4.2 | `tronque=false` (attendu `true`) |

Voisines : `test-cockpit-retard.sh` 40 PASS / 0 FAIL, `test-cockpit-path-enfants.sh` 37 PASS / 0 FAIL, `test-cockpit-who.sh` 98 PASS / 0 FAIL.
