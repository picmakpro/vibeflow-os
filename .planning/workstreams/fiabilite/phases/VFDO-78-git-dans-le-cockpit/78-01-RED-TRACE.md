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

## Tâche 3 — attribution worktree des sous-agents (W22, GITC-14, P78-D-26)

Tête : `079c235f`. Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-who.sh` (bilan avant le code : `103 PASS / 2 FAIL`).

| Sonde | Assertion | Attendu | Obtenu |
|---|---|---|---|
| W22.1 | sous-agent lancé depuis l'arbre principal, un appel antérieur `cd <worktree a> && ls`, dernier appel `ls` : `treeBy\|tree\|branch` | `activité\|../lab22-a\|feat/a` | `cwd\|arbre principal\|principale` |
| M-DERNIERE.0 | l'ancre `dernierArbre(…)` du mutant existe dans who.mjs | `muté` | `ancre absente` (la fonction n'existe pas encore : le mutant n'est pas jouable avant le code) |

Verts de contrôle : W22.0 (sous-agent listé), W22.2 (le plus récent l'emporte, comportement déjà présent), W22.3 (aucun worktree cité : `cwd`), W22.4 (première version : vert à vide, car la ligne ajoutée citait elle-même le worktree et la lecture de la dernière ligne suffisait ; durcie ensuite : le transcript grossit de DEUX lignes, la dernière ne cite rien, donc seule la lecture de l'ensemble la voit).

### Vert après `byActivity` : `107 PASS / 0 FAIL` (who), `157 PASS / 0 FAIL` (equipe)

| Mutant | Ligne mutée | Sonde rougie | Valeur obtenue sur le mutant |
|---|---|---|---|
| M-DERNIERE | `\|\| (fichier ? dernierArbre(fichier, trees, cite) : null)` -> `\|\| null` | W22.1 | `cwd\|arbre principal\|principale` (attendu `activité\|../lab22-a\|feat/a`) |
| M-MEMO | `m.taille === st.size) return m.arbre;` -> `true) return m.arbre;` | W22.4 | `cwd\|arbre principal#cwd\|arbre principal` (attendu `…#activité\|../lab22-a`) |

Premier essai de M-MEMO : resté vert parce que le W22.4 d'alors se résolvait par la dernière ligne sans passer par le mémo ; la fixture a été corrigée (deux lignes ajoutées, la dernière sans chemin) avant de compter ce mutant.

## Correction audit (2026-11-06) — A1, A2, A7, A8 (point unique git, garde E6, classe d'affichage)

Mandat de correction CIBLÉE de `mgr78-reprise` après l'audit sécurité en lecture. Tête avant correction : `c70480f2` (archivée par `git archive` dans le scratchpad : chaque rouge « avant » est rejoué sur cette tête, avec la suite NOUVELLE copiée dans son arbre ; chaque vert « après » sur le worktree corrigé). Logs : `78-audit-fix-env-avant.log` (107 PASS / 16 FAIL) et `78-audit-fix-env-apres.log` (124 PASS / 0 FAIL) ; `test-cockpit-git-commandes.sh` : voir le tableau A8.

### A1 — aucun filtre déclaré exécuté, quel que soit leur nombre (`test-cockpit-git-env.sh`, E9)

Fixtures : dépôt à 70 filtres dont le 70e (`.gitattributes`) pose le marqueur `F9`, dépôt à 1 filtre, dépôt à 300 filtres, `f.txt` « stat-dirty » (`touch -t`, même contenu : status relit le fichier). Témoin positif E9.0 : `git status` brut sur le dépôt à 70 filtres pose `F9` (la sonde n'est pas aveugle) ; E9.0a : `filtresDeclares` rend 69 filtres de plus sur le dépôt à 70 que sur celui à 1 (la config de l'utilisateur, `lfs`, s'ajoute aux deux : la différence ne dépend pas du poste).

| Sonde | Assertion | Attendu | Obtenu AVANT (le rouge vient du plafond `.slice(0, 64)`, le dépôt à 1 filtre reste vert) |
|---|---|---|---|
| E9.1 | `lancerGit status`, 70 filtres : `marque F9\|ok` | `absent\|true` | `posé\|true` |
| E9.2 | `shBorne status`, 70 filtres | `absent` | `posé` |
| E9.3 | `lancerGitAsync status`, 70 filtres | `absent\|true` | `posé\|true` |
| E9.0a | filtres lus en plus sur le dépôt à 70 filtres par rapport à celui à 1 filtre | `69` | `62` (la liste est coupée à 64 : 64 − 2) |
| E9.5 | 300 filtres (> `MAX_FILTRES` 256) : `marque\|ok:refuse:sortie` en sync et async | `absent\|false:true:""\|false:true:""` | `posé\|true::""\|true::""` |
| E9.5a | `shBorne status`, 300 filtres | `absent\|vide` | `posé\|vide` |
| E9.6 | liste des filtres illisible (emballage : `git config --get-regexp` rend 2) : status refusé sync ET async | `absent\|false:true\|false:true` | `posé\|true:\|true:` (status lancé avec la liste vide) |
| E9.4 / E9.5b / E9.6a | 1 filtre ; `log` sur 300 filtres ; rev-parse sous l'emballage | verts avant ET après | témoins : le rouge vient du défaut, pas d'un module cassé |

Le défaut A1 avait une SECONDE forme que le mandat ne nommait pas : si `git config --get-regexp` échoue (délai, tronqué, code ≠ 0/1), la liste était vide et `status` partait sans aucun filtre vidé (E9.6). Corrigé dans la même classe : liste illisible = refus.

Mutants (copies des scripts, ancre présente, chacun rougit SA sonde) :

| Mutant | Mutation | Sonde rougie | Obtenu sur le mutant |
|---|---|---|---|
| M-PLAFOND | `.filter(Boolean))],` -> `.filter(Boolean))].slice(0, 64),` | E9.1, E9.2, E9.3 | `posé\|posé\|posé` ; témoin : à 1 filtre le mutant reste vert (`absent\|true`) |
| M-BORNE | `!fiable \|\| noms.length > MAX_FILTRES` -> `!fiable` | E9.5 | `true:\|true:` (status lancé à 300 filtres, plus de refus) |
| M-FIABLE | `!fiable \|\| …` -> `…` | E9.6 | `F9` posé (liste illisible, status lancé) |

### A2 — aucun `status` lancé par le cockpit ne déclenche un filtre, sous-modules compris (`test-cockpit-git-env.sh`, E9)

`OPTIONS_LECTURE` pose `--ignore-submodules=all` pour TOUT `status` et TOUT `diff` (point unique : `shBorne`, `lancerGit`, `lancerGitAsync` passent par `argsGit`). Fixture : super-dépôt + sous-module dont `.git/modules/sub/config` déclare un filtre posant `SUBCLEAN`. Témoin E9.7 : `status` BRUT du super-dépôt relance un status dans le sous-module et pose `SUBCLEAN` (git retire `GIT_CONFIG_COUNT` pour les processus de sous-module : les filtres vidés ne s'y appliquent pas).

| Sonde | Assertion | Attendu | Obtenu AVANT |
|---|---|---|---|
| E9.8 | `lancerGit status --porcelain=v2 --branch -z -unormal` (forme d'`etatWorktrees`) : `marque SUBCLEAN\|ok` | `absent\|true` | `posé\|true` |
| E9.9 | `shBorne status` | `absent` | `posé` |
| E9.10 | `lancerGitAsync status` | `absent\|true` | `posé\|true` |
| E9.11 | `lancerGit diff --stat` (git diff descend aussi dans les sous-modules : mesuré) | `absent` | `posé` |
| E9.12 | CLASSE : argv journalisé de 4 `status` (3 lanceurs, 2 dépôts) : nombre sans `--ignore-submodules=all` | `4\|0` | `4\|4` |

Mutant M-SOUS-MODULES (`status: [IGNORER_SOUS_MODULES] };` -> `status: [] };`) : rougit E9.8 (`SUBCLEAN` posé) ET E9.12 (2 `status` sur 2 sans option). Contrepartie assumée et notée au SUMMARY : l'état modifié d'un sous-module n'est plus compté (ignoré, jamais présenté « propre » : `lireStatusV2` ne le voit simplement pas).

### A7 — garde E6 : liste blanche des importeurs de `child_process`, balayage récursif (`test-cockpit-git-env.sh`, E6)

Avant : l'ancienne garde (`garde.mjs` de l'audit, rejouée sur les 11 plantés) ne signale que `i-temoin-direct.mjs:2` (1 sur 11). Après (E6.1 à E6.5 : 12 assertions, plus 12 pour les 6 mutants de la garde, ancre puis sonde) :

| Sonde | Assertion | Attendu | Obtenu |
|---|---|---|---|
| E6.1 | arbre réel de `plugin/cockpit`, balayage récursif, `--exact` | aucune ligne | vert (10 importeurs, tous en liste) |
| E6.1a | importeurs trouvés dans l'arbre réel | `10` | `10` |
| E6.2 | les 11 plantés (.mjs, .cjs, .js) sous `skills/cockpit-moteur/assets/ui/`, hors liste | 11 « hors liste blanche » | 11 |
| E6.2a | importeur hors liste SANS le mot git (`ps`) | signalé | signalé (règle 1 indépendante de la règle 2) |
| E6.3 | les 11 contenus sous le NOM d'un importeur de la liste (`scripts/vf-cockpit-live.mjs`) | `11111111111` | `11111111111` |
| E6.4 / E6.4a / E6.4b | négatifs (`emit('git')`, dossier `tests`, simple `Set`, `common.mjs` gardé) ; `common.mjs` sans garde ; exemption du socle | vides / signalé / signalé | conformes |
| E6.5b-d | copie de l'arbre réel : verte ; un `.js` planté hors `scripts/*.mjs` ; un `execFileSync('git')` ajouté à `live.mjs` | vide / 1 ligne / 1 ligne | conformes |

Mutants de la garde (chacun avec SA trace) : M-LISTE (`if (!nature) {` -> `if (false) {`) : `zz/sans-git.mjs` n'est plus signalé (0) ; M-RECURSIF (descente retirée) : 0 des 11 vus ; M-SUFFIXE (`/\.mjs$/`) : 9 des 11 ; M-ALIAS (`noms.add(m[1])`) : `11011111111` (l'alias d'import n'est plus suivi) ; M-IDENT (résolution de la déclaration retirée) : `11110111111` ; M-EXEMPTION (`common.mjs` exempté sur son seul nom) : `common.mjs` sans garde n'est plus signalé. Limite assumée de l'analyse textuelle (pas un AST) : nom de module construit (`'child_' + 'process'`), `import(...).then(({ execFile }) => …)`, `eval` : non suivis.

### A8 — tout caractère `Cf` est neutralisé (`test-cockpit-git-commandes.sh`, C1.9, C1.7, C3.4, C3.5)

`nettoie` (arbres.mjs), `AFFICHAGE_REFUSE` (commandes.mjs) et `ILLISIBLE` (details.mjs) : `\p{Cf}` avec le drapeau `u`, plus C0, DEL, C1, U+2028/2029. Avant (suite nouvelle sur la tête `c70480f2`, `78-audit-fix-commandes-avant.log` : 24 PASS / 11 FAIL) : C1.9 rouge sur les trois constructeurs (`obtenu: [[cmdCd:cf-null-attendu:…]…]` : U+200B à U+200F, U+2060, U+2061, U+FEFF en tête, U+061C, U+00AD n'ont pas de refus, une commande est rendue pour un nom à caractère invisible) et C1.6 rouge (l'oracle indépendant de l'échantillon généré refuse maintenant U+200B et U+FEFF : `attendu: [3] obtenu: [0]`) ; les autres rouges de ce log (C3.1, C3.2, C3.4.5-10, C3.5) sont des artefacts de la tête archivée (la sonde des mutants inclut C1.9, ou l'ancre `\p{Cf}` n'y existe pas). Après : vert, et les noms légitimes (café, Ünïcödé, ñandú, 日本語, e + combinant, feat/été, é🙂) gardent leur commande. Mutants : les 4 plages C0/C1/U+2028/9 (existants, inchangés) et 6 mutants sur `\p{Cf}` (retiré ; revenu à l'ancienne classe bidi ; sous-ensembles qui perdent U+2060/U+FEFF/U+061C, U+202A ou U+2066) rougissent C1.5 ou C1.9 seul ; M-NETTOIE (arbres.mjs revient à l'ancienne classe) rougit la parité C1.7 (écarts).
