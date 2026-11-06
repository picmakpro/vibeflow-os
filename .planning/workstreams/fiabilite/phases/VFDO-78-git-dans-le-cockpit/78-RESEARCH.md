# Phase 78 : Git dans le cockpit — Recherche technique

**Recherche :** 2026-11-05 · **Domaine :** lecture git bornée (Node natif, `execFileSync`), graphe de commits en SVG, sûreté d'un dépôt hostile
**Confiance :** HAUTE pour l'extraction, la sûreté et les coûts (mesurés ou falsifiés sur ce poste) ; MOYENNE pour le placement des couloirs (prototype mesuré, rendu non écrit)
**Poste de mesure :** `git version 2.50.1 (Apple Git-155)`, `node v26.5.0`, dépôt `vibeflow-os` (4110 commits, 17 `refs/heads`, 96 `refs/remotes`, 111 `refs/tags`, 7 worktrees, pas de commit-graph : `objects/info/` ne contient que `packs`).
Toutes les mesures passent par `/usr/bin/git` en direct : le hook rtk réécrit `git` et fausse les sorties (mémoire « rtk fausse les vérifications d'état »).

<user_constraints>
## Contraintes utilisateur (copiées de 78-CONTEXT.md)

Le lanceur a présenté le cadrage comme non tranché, mais `78-CONTEXT.md` est apparu pendant la recherche (« Cadrée (2026-11-05) »). Ce sont donc ses décisions qui font foi, recopiées ci-dessous mot pour mot. Les identifiants `P78-D-xx` sont les siens.

### Décisions verrouillées — arbitrages de Samuel (AskUserQuestion, session principale, 2026-11-05)
- **P78-D-01** Le titre à droite du logo est le nom du dossier du dépôt principal (racine de `git rev-parse --git-common-dir`, et à défaut le dossier du lab), identique sur Code, Projet et Équipe. Dans un worktree, c'est « vibeflow-os », pas « phase-78 ».
- **P78-D-02** « Seconde ligne ». La branche et le worktree vont en petit sous le nom (pas de pastille). Le worktree n'apparaît que hors de l'arbre principal ; branche détachée lisible comme telle.
- **P78-D-03** À la racine, le bloc ne répète plus le nom du projet : surtitre = nom de l'onglet ; titre = ce que montre la vue (Projet : le jalon en cours ; Code : le dépôt et sa branche ; Équipe : la mission en cours, ou un libellé neutre s'il n'y en a pas) ; sous-titre = résumé court. Sous-vues inchangées.
- **P78-D-04** « un panneau/tiroire vertical a gauche vertical (je trouve que trois onglet sont suffisant et git peut ne pas etre installé dans le projet) ». Pas de 4ᵉ onglet : un tiroir vertical à gauche, qui coexiste avec le tiroir Terminal (en bas) et les boutons de zoom et la pastille Terminal (en bas à gauche). Git absent ou lab hors dépôt : dégradation propre, sans casser le reste.
- **P78-D-05** Branches locales, worktrees, branches distantes déjà présentes sur le disque (`refs/remotes/*`) ; jamais de `fetch` (CKPT-03) ; N derniers commits bornés, branches mergées repliées.
- **P78-D-06** Détail d'un commit (auteur, date, message complet, fichiers touchés avec +/−, sans diff) ; état de chaque worktree (modifiés, non suivis, avance/retard sur la base) ; tags ; liste des stash ; auteurs et activité récente par branche.
- **P78-D-07** Aucune route qui agit sur le dépôt. Les vues proposent la commande exacte, à copier ; l'utilisateur la lance lui-même. Audit de sécurité en lecture, recommandé et retenu.
- **P78-D-08** Worktrees, branches et travail non commité : Phase 78. La 73 garde verrous, arbitrages en attente, watchdog et serveurs orphelins ; la 75 garde hotspots et couplage.
- **P78-D-09** La liste « Repositories » de l'onglet Code (« branche @ head7 ») et les suffixes « — Projet » / « — Équipe » du titre sont retirés.
- **P78-D-10** La seconde ligne de l'en-tête ouvre le tiroir au clic, avec un aspect cliquable au survol ; la touche « g » l'ouvre et le ferme.

### Décisions du manager (techniques ; aucune ne vaut arbitrage humain)
- **P78-D-11** Git introuvable sur le PATH assaini, ou lab hors dépôt : la seconde ligne de l'en-tête et l'ouvreur du tiroir sont absents, aucune erreur dans le chrome, le reste du cockpit est identique à aujourd'hui (témoin). Une erreur ou un dépassement de borne d'une commande git rend un état « indisponible » local au tiroir, jamais une page cassée.
- **P78-D-12** Uniquement des variables CSS existantes, aucune valeur de couleur, d'espacement ou de rayon en dur ; aucune valeur de padding ou de marge existante modifiée.
- **P78-D-13** Routes neuves en GET seul sous `/api/vf/`, derrière les contrôles existants (Host, Origin, jeton). Aucune route POST, aucune écriture dans le dépôt ni dans `.git`. Commandes git par `shBorne` avec `GIT_SUR`, options de neutralisation des programmes externes (diff externe, textconv, pager) selon `78-RESEARCH.md`, arguments validés (SHA par motif strict puis `rev-parse --verify`, jamais d'argument commençant par `-`), sorties bornées en nombre et en taille.
- **P78-D-14** Toute commande proposée est construite côté serveur ou par une fonction unique, avec les noms de refs et les chemins cités pour le shell (guillemets simples, `'` échappé) […]. Copie par l'API presse-papiers de la page P seule (jamais dans le cadre du terminal, T-71). Rendu de tout texte venu de git en `textContent`.
- **P78-D-15** Le tiroir se rafraîchit par le flux existant (SSE) sur une signature bon marché (HEAD et refs de chaque worktree), jamais par un polling qui relance `git log` à chaque tick.
- **P78-D-16 à D-19** : étage design (`vf-crafter` puis `vf-design-judge`, seuil 70/100), témoin rouge par exigence et mutants sur les gardes, bump du module `cockpit` sans release, tenue en largeur mobile.

### Laissé à Claude
Algorithme de placement des couloirs, format d'échange serveur → page, découpage en fichiers sous `plugin/cockpit/`.

### Reporté (HORS PÉRIMÈTRE)
Actions Git exécutées par le cockpit (fetch, branche, worktree…) ; revue de diff complète.
</user_constraints>

## Contraintes du projet (CLAUDE.md)
- Jamais de fix sans validation humaine (ADR-031) ; commits en français ; un commit qui invoque un arbitrage nomme son canal et sa date ; identifiants de décision préfixés (`P78-D-xx`).
- Toute UI suit `DESIGN.md` « Graphite ». Une suite qui touche un gate, un hook ou une fixture surveillée porte le trailer `Gate-Touche:`. Les fixtures du cockpit ne sont pas sous les motifs surveillés, la suite neuve n'y est donc pas soumise.
- Les suites sont découvertes sans être inscrites : `discover() { find plugin scripts -type f -path '*/tests/test-*.sh' | LC_ALL=C so…` [VERIFIED: scripts/ci-shard-suites.sh:22]. Un `test-cockpit-git.sh` part donc en CI tout seul.

## 1. Extraction de la topologie

**Socle existant** [VERIFIED: plugin/cockpit/scripts/vf-cockpit-paths.mjs:125,136-140]
- `export const GIT_SUR = ['--no-optional-locks', '-c', 'core.fsmonitor=false'];` (ligne 125 ; le brief disait 126).
- `shBorne` : `Math.min(10000, FIN - Date.now())`, `stdio: ['ignore', 'pipe', 'ignore']`, `env: envEnfant(lab)`, `catch (e) { return e.stdout || ''; }`.
- `shBorne` ne fixe pas `maxBuffer`, qui vaut donc 1 Mio par défaut [ASSUMED : défaut Node]. Un dépassement lève `ENOBUFS`, et `e.stdout` porte alors une sortie **partielle**, rendue sans aucun signal. Sonde avec `maxBuffer:50` → `maxBuffer dépassé: code=ENOBUFS stdout.length=164`. Pour ne jamais lire une sortie tronquée comme complète, chaque appel passe un `-n` explicite et le parseur vérifie l'alignement.

**Format sûr** (vérifié par `od -c`) : `git log --topo-order -z --format=%H%x00%P%x00%at%x00%an%x00%s -n N <refs>`. Chaque commit donne exactement 5 champs terminés par NUL, et `-z` remplace le saut de ligne entre commits par un NUL [CITED: git-scm.com/docs/git-log, `-z`]. Parseur : `split('\0')` puis paquets de 5. On vérifie `/^[0-9a-f]{40}$/` (`--show-object-format` → `sha1` ici) en tête de chaque paquet, et on abandonne en « indisponible » au premier désalignement.

**Choix des refs.** Lister les refs en entier (`refs/heads/x`, `refs/remotes/o/x`), jamais un nom court, et jamais `--all`. Motifs :
- `--all` prend « all the refs in `refs/`, along with `HEAD` », et par défaut les HEAD de tous les worktrees [CITED: git-log `--all`, `--single-worktree`]. Il ramène donc `refs/original` (1 ref ici) et `refs/stash`.
- Un ref nommé `--all` ou `-x` existe bel et bien. Sonde : `update-ref refs/heads/--all HEAD` est accepté, puis `git log -1 -x` → `fatal: unrecognized argument: -x`, alors que `refs/heads/-x` et `--end-of-options -x` → `658a1f8 c2`.

**Mesures** (médiane de 5, `node` + `execFileSync('/usr/bin/git', [...GIT_SUR, ...])`) :

| Commande | Durée | Sortie |
|---|---|---|
| `log --topo-order -z <fmt5> -n 200 --branches --remotes --tags` | 40.1 ms | 42 035 o |
| idem `-n 500` / `-n 2000` / sans `-n` (4110 commits) | 41.1 / 40.5 / 43.7 ms | 107 250 / 426 864 / 829 529 o |
| `log` sans `--topo-order`, `-n 500` | 18.6 ms | — |
| `for-each-ref --format=… refs/heads refs/remotes refs/tags` (224 refs) | 11.4 ms | 22 215 o |
| `worktree list --porcelain -z` | 8.6 ms | 1 137 o |
| `for-each-ref --no-merged=origin/main refs/heads refs/remotes` | 39.9 ms | 34 refs (79 mergées) |
| `for-each-ref --format="%(objectname) %(ahead-behind:refs/remotes/origin/main) %(refname)"` (113 refs) | 89.3 ms | `a61236c… 84 2907 refs/heads/backup/phase-21-avant-merge-main` |

- Sans commit-graph, `--topo-order` parcourt tout l'historique : le coût reste à peu près constant quel que soit `-n` (~40 ms ici). Sur un dépôt de 100 000 commits, ce serait plutôt de l'ordre de la seconde [ASSUMED : extrapolation linéaire]. Écrire un commit-graph serait une écriture, que P78-D-13 interdit.
- La sortie complète approche 1 Mio (829 Ko) : un `-n` est **obligatoire**.

**Piège mesuré : une fenêtre `-n` seule cache les branches.** Avec `-n 500` sur les 34 refs non mergées plus `origin/main`, **29 pointes de branches sur 34 tombent hors de la fenêtre**. Les commits propres aux branches non mergées sont au nombre de 771 (`rev-list --count <refs> --not refs/remotes/origin/main`), et `log … --not origin/main` les lit en 40.4 ms. Extraction bornée recommandée :
1. `for-each-ref` en une passe : refs, cibles peelées (`%(*objectname)`), `%(ahead-behind:<base>)` [CITED: git-scm.com/docs/git-for-each-ref], `%00` comme séparateur.
2. La ligne de base : `log --topo-order -z <fmt> -n N <base> <HEAD des worktrees>`.
3. Les branches non mergées : `log --topo-order -z <fmt> -n M <refs non mergées> --not <base>`, avec M borné (500 par exemple). Une branche dont la pointe reste hors fenêtre s'affiche en pointe seule, avec son compte `ahead-behind`.
4. Les branches mergées (`--merged=<base>`) sont repliées : ce sont des étiquettes sur leur commit si celui-ci est dans la fenêtre, sinon une simple ligne de liste.
5. Les tags servent d'étiquettes aux commits de la fenêtre et ne sont jamais passés à `log` (111 tags) ; au-delà de la fenêtre, une liste bornée.

`%(ahead-behind:)` existe en 2.50 (sondé). Sa version minimale n'a pas été vérifiée [ASSUMED ≥ 2.41]. Repli : `rev-list --left-right --count`.

## 2. Placement en couloirs (gitgraph)

**Algorithme**, déterministe, en un seul passage sur l'ordre `--topo-order`, qui garantit « no parents before all of its children are shown » [CITED: git-log `--topo-order`] :
```
lanes = []                                   // lanes[k] = SHA attendu dans le couloir k, ou null
pour chaque commit c (enfants avant parents) :
  col = lanes.indexOf(c.h) ; si -1 : col = premier null, sinon on ajoute en fin
  les autres k où lanes[k] == c.h  -> arêtes entrantes (k → col), lanes[k] = null   // plusieurs enfants
  si c n'a aucun parent : lanes[col] = null                                          // racine
  sinon : lanes[col] = c.p[0] ; pour p dans c.p[1:] :                                // merge, octopus
            k = lanes.indexOf(p) ; si -1 : k = premier null, sinon en fin ; lanes[k] = p ; arête (col → k)
  retirer les null de queue ; ligne = { col, entrants, arêtes, largeur }
```
- Complexité O(n × L), L étant le nombre maximal de couloirs.
- Prototype joué sur ce dépôt : `{"commits":500,"couloirsMax":4,…,"placementMs":"0.57"}`, `2000 → couloirsMax 9, 1.32 ms`, historique entier `4105 commits, racinesVues 2, 2.76 ms`.
- Le dépôt a réellement 2 racines (`rev-list --max-parents=0 --all | wc -l` → `2`) et 0 octopus (`--min-parents=3` → `0`).

**Pièges**
- *Octopus* : la boucle sur `c.p[1:]` les couvre, mais il faut un témoin à trois parents.
- *Racines multiples* : le couloir se libère, il ne doit jamais rester une arête vers le vide.
- *Parent hors fenêtre* : un couloir reste ouvert en bas (`couloirsOuvertsEnBas: 2` à N=500). On le dessine en tronçon pointillé « … », jamais comme une racine.
- *Plusieurs refs sur un même commit* : les étiquettes se groupent par SHA, en ordre stable (HEAD, branches locales, distantes, tags) avec un plafond suivi de « +k ».
- *Couleurs* : un couloir change d'indice quand un commit arrive. On colore donc par empreinte du nom de la ref de tête, avec les variables CSS existantes (P78-D-12), pas par indice de couloir.
- Ne jamais lire `%D` : il joint les noms par « , », et la virgule est permise dans un nom de ref (les règles de check-ref-format ne l'interdisent pas [CITED: git-scm.com/docs/git-check-ref-format]).

**ELK ou maison ?** **Placement maison en SVG.** ELK (`vendor/elk.bundled.js`, 1.5 Mo, déjà embarqué) fait du placement en couches qui réordonne les nœuds pour réduire les croisements, alors qu'un gitgraph impose une ligne par commit dans l'ordre topologique. L'algorithme ci-dessus est d'ailleurs celui de `git log --graph`, gitk et GitKraken, en ~30 lignes et < 3 ms [ASSUMED pour l'équivalence avec ces outils].

## 3. Détail d'un commit sans diff

**Validation du SHA reçu** (route GET `?sha=`). Ordre recommandé :
1. Motif strict `/^[0-9a-f]{40}$/`, ou `{64}` si `--show-object-format` rend `sha256`.
2. `git rev-parse --verify --quiet --end-of-options <sha>^{commit}`.
3. Option : vérifier que le SHA fait partie du graphe servi.

Sonde jouée sur un dépôt jetable :
- `--all` → `(rc 1)` ; `0000…0000` → `(rc 1)` ;
- un SHA d'arbre → `expected commit type, but the object dereferences to tree type (rc 1)` ;
- un SHA court `658a1f886266` → **accepté** (d'où le motif strict de 40 caractères en premier) ;
- `HEAD` et `v1` acceptés eux aussi : le motif strict les exclut avant git.

`--end-of-options` sert à séparer options et révisions [CITED: git-scm.com/docs/gitcli].

**Métadonnées** : `log -1 -z --no-show-signature --format=%H%x00%P%x00%an%x00%ae%x00%aI%x00%cn%x00%cI%x00%B --end-of-options <sha>`. Sur un commit réel : 1 473 o, ~19 ms. `%B` (le message complet) est le dernier champ et se borne côté serveur (8 Kio par exemple).

**Fichiers +/−** : la plomberie, `diff-tree -r -z --numstat -M --no-commit-id --no-ext-diff --no-textconv <parent1> <sha>`, ou `--root <sha>` pour une racine. Sorties vérifiées :
- binaire → `-\t-\ta.bin\0` (« For binary files, outputs two `-` » [CITED: git-log `--numstat`]) ;
- renommage → `1\t0\t\0t.txt\0u.txt\0` : champ de chemin vide, puis l'ancien et le nouveau chemin ;
- racine → `2 0 .gitattributes|- - a.bin|20 0 t.txt`.

**Merges** : `diff-tree <merge>` seul rend `[]`. `-m --first-parent` rend les DEUX parents (`1 0 b|1 0 c`), car `diff-tree` n'honore pas `--first-parent`. Seule la forme explicite `<sha>^1 <sha>` rend `1 0 b`. Coût : 46 fichiers en ~37 ms, un merge en 27 ms (minuterie perl comprise).

Un commit énorme se gère par une borne du nombre de lignes lues (500 fichiers par exemple) avec un indicateur « tronqué », et par un `maxBuffer` explicite.

## 4. État par worktree

Mesures, une ligne par worktree (7 au total) :

| Mesure | Durée | Commande |
|---|---|---|
| `status --porcelain=v2 --branch -z` | 20.5–24.1 ms | `node mesure2.mjs` |
| la même avec `-uno` | 11.8–14.2 ms | idem |
| `rev-list --left-right --count main...HEAD` | 10.2–14.4 ms | idem |

- Exemple : `worktrees/jalon-v2-73-77 … -> 614 0`. La base compte : le `main` local et `origin/HEAD` diffèrent. Le socle prend déjà `origin/HEAD` puis `main` [VERIFIED: vf-cockpit-arbres.mjs:38].
- Format v2 : `# branch.oid`, `# branch.head <branch> | (detached)`, `# branch.ab +<ahead> -<behind>` (seulement si un upstream existe), puis des entrées `1 …`, `2 …` (renommage, chemins séparés par NUL avec `-z`), `u …` et `? <path>` [CITED: git-scm.com/docs/git-status].
- « Because it takes extra work to find untracked files … `no` to have `git status` return more quickly » [CITED: idem].
- Recommandation : `-unormal` (le défaut), qui compte un dossier non suivi pour une entrée, plus une borne sur le nombre d'entrées lues (200 par exemple, puis « +k »). Le `status` de chaque worktree se calcule **à la demande** quand le tiroir est ouvert, jamais dans le filet de 5 s : à 7 × 22 ms, ce serait ~150 ms de boucle **bloquée**, puisque `execFileSync` est synchrone.
- Pour lire les worktrees, du code neuf utilisera `worktree list --porcelain -z` : `arbresGit` découpe sur `'\n\n'` sans `-z` [VERIFIED: vf-cockpit-arbres.mjs:27], et un chemin qui contient un saut de ligne casse ce découpage, ce que `-z` est fait pour éviter [CITED: git-scm.com/docs/git-worktree].

## 5. Sûreté

**Falsification jouée** (`hostile.sh`, dans le scratchpad) sur un dépôt dont `.git/config` déclare `core.fsmonitor`, `core.pager`, `pager.<cmd>`, `diff.external`, `diff.bin.textconv`, `diff.bin.command`, `filter.f.{clean,smudge,process}` et `core.hooksPath` (7 hooks). Chaque programme pose un marqueur quand il est lancé. Résultats, programmes lancés par commande :

| Commande (avec `GIT_SUR`, stdin `/dev/null`) | Lancé |
|---|---|
| `log --topo-order -z …`, `for-each-ref`, `worktree list -z`, `rev-list --left-right --count`, `diff-tree --numstat`, `show --numstat` | rien |
| `show -p <c>` | **textconv** |
| `show -p --ext-diff <c>` | **diffcmd proc** |
| `diff-tree -p --textconv <c>` | **textconv** |
| `status --porcelain=v2` **sans** `GIT_SUR` | **fsmonitor hook** (hook post-index-change, à l'écriture de l'index) |
| `-c core.fsmonitor=false status …` sans `--no-optional-locks` | **hook** |
| `status` avec `GIT_SUR`, fichiers propres ou de taille changée | rien |
| `status` avec `GIT_SUR`, fichier « stat-dirty » (même contenu, `touch -t` sur la date) | **proc** (`filter.f.process`) |
| même cas avec `-c filter.f.process= -c filter.f.clean=` | rien |
| `diff --numstat HEAD` (arbre de travail), même avec `--no-ext-diff --no-textconv` | **proc** |
| `core.pager` / `pager.*` | jamais (stdout n'est pas un terminal) |

Conclusions :
- `GIT_SUR` neutralise fsmonitor et, par `--no-optional-locks`, les hooks liés à l'écriture de l'index.
- **Il ne neutralise pas les filtres de `.gitattributes`**. `status` lance `filter.<pilote>.process` dès qu'un fichier suivi est stat-dirty. Le nom du pilote vient du dépôt, donc il n'existe pas de `-c` générique.
- Parade sondée : énumérer `git config --name-only --get-regexp '^filter\..*\.(clean|smudge|process)$'` (sortie ici : `filter.lfs.smudge … filter.f.process`) et ajouter `-c filter.<x>.<k>=` pour chacun.
- Effet de bord : un fichier LFS stat-dirty paraîtra modifié [ASSUMED]. Sinon, le libellé « modifiés » n'est pas calculé et l'on ne garde que le compte d'index [à arbitrer].
- Ne **jamais** lancer `git diff` contre l'arbre de travail.
- Ajouter `--no-ext-diff --no-textconv` à `show`, `log` et `diff-tree`. C'est inutile pour `--numstat` dans la sonde, mais textconv est actif par défaut pour `git log` [CITED: git-log `--textconv`].
- `-c core.hooksPath=/dev/null` n'est **pas nécessaire** pour les lectures listées (aucun hook lancé avec `GIT_SUR`). Il ne coûte rien en défense en profondeur.
- Existant hors périmètre : `vf-cockpit-who.mjs:116` lance déjà `status --porcelain -- <f>.dag.json` avec ce même vecteur, ouvert seulement si `.gitattributes` vise `*.dag.json`.

**Environnement hérité.** `envEnfant` ne remplace que le PATH (`return { ...env, [cle]: assainirPath(env[cle], lab) };` [VERIFIED: vf-cockpit-env.mjs:26-28]). Sonde : `GIT_DIR=<hostile> git -C <merge> log -1` → `c2` au lieu de `Merge branch 'f'`. Une variable `GIT_DIR` héritée l'emporte donc sur `-C`. Recommandation : pour les enfants git, retirer `GIT_DIR`, `GIT_WORK_TREE`, `GIT_INDEX_FILE`, `GIT_COMMON_DIR`, `GIT_OBJECT_DIRECTORY`, `GIT_ALTERNATE_OBJECT_DIRECTORIES`, `GIT_EXTERNAL_DIFF`, `GIT_CONFIG_PARAMETERS`, `GIT_CONFIG_COUNT`/`KEY_*`/`VALUE_*` [liste ASSUMED d'après git(1) ; `GIT_DIR`, `GIT_WORK_TREE` et `GIT_INDEX_FILE` sont CITED: git-scm.com/docs/git].

**Noms de refs hostiles** (sondés avec `update-ref`) :
- acceptés : `a"b'c&d`, ``x;y|z`w` ``, U+202E (bidi), `é🙂`, `-x`, `--all`, `<svg/onload=alert(1)>`, le tag `<b>x</b>` ;
- refusés : espace (donc `$(touch pwn)` et `<img src=x …>`), `..`, ESC.

Mesures :
- rendu en `textContent` uniquement, plus `nettoie` (contrôles, bidi U+202A-202E et U+2066-2069 retirés, secrets masqués, borne) [VERIFIED: vf-cockpit-arbres.mjs:54] ;
- dans un attribut SVG (`data-ref`), passer par `setAttribute`, jamais par une concaténation ;
- un nom de 300 caractères échoue pour une ref non tassée (`File name too long`), mais `packed-refs` n'a pas de borne [ASSUMED] : borner à 200 caractères à l'affichage.

**Commandes à copier (P78-D-14).**
- Citation unique : `"'" + s.replace(/'/g, "'\\''") + "'"`.
- Un nom commençant par `-` reste une option même cité : `git switch '-x'` → `error: unknown switch 'x'` ; `git switch --end-of-options -x` → `Switched to branch '-x'` (sondé).
- Toute commande proposée insère donc `--end-of-options` avant ses refs.
- `worktree add --end-of-options ../wtx -x` a produit un HEAD **détaché**, pas la branche [VERIFIED par sonde] : pour les worktrees, proposer `git worktree add <chemin> refs/heads/<nom>`… à sonder dans la suite.

**Stash, auteurs.**
- `stash list -z --format=%gd%x00%H%x00%ct%x00%gs` → `stash@{0}|84a8…|1793903819|On main: deux|…` (17 ms sur ce dépôt, 0 stash). Le message `wip <b>hostile</b>` passe tel quel, d'où le `textContent`.
- **Piège :** `shortlog -sne` sans révision, stdin à `/dev/null` (ce que fait `shBorne`) → sortie **vide**, sans erreur. Il faut toujours une révision (`shortlog -sne HEAD` → `4\tt <t@t>`), ou mieux, agréger en JS sur `log -z --format=%an%x00%at -n 500` (53.5 ms).

**Surface serveur** [VERIFIED: vf-cockpit-server.mjs:70 ; serve.mjs:495,513-516]
- `if (req.method !== 'GET') { res.writeHead(405); res.end(); return true; }` ;
- CSP de page : `connect-src 'self'` ; jeton vérifié avant `VF.route` ;
- les réponses JSON sont en `'Cache-Control': 'no-store'` (ligne 66).
- La garde du flux refuse les clés `"interdits": ["doing", "mandat", "messages", "outils"]` [VERIFIED: vf-cockpit-interface.json:24 ; lue à vf-cockpit-server.mjs:29]. Un événement SSE Git ne doit donc porter aucune clé `messages` : utiliser `sujet` et `message`.

**ASVS L1** : V5 (validation d'entrée : SHA, bornes), V4 (contrôle d'accès : jeton, Host, Origin, existant), V12 et V14 (configuration : neutraliser les programmes du dépôt). V2, V3 et V6 ne s'appliquent pas.

## 6. Rafraîchissement

**Existant** [VERIFIED: vf-cockpit-live.mjs:19-20,133-144 ; 70-vf-live.js:215-234]
- `const POLL_MS = 2000, DEBOUNCE_MS = 300, HOLD_MS = 600, NET_MS = 5000;`
- Le watcher de `.planning` ignore `/(^|\/)\.git(\/|$)|\.tmp$|~$|\.swp$/`. Un filet `setInterval(…, NET_MS)` recalcule `who` et `lock` et n'émet que sur changement de signature (`whoSig`).
- La page écoute `hello`, `who`, `lock`, `patch` et `structural` sur `/api/vf/events`.

**Branchement recommandé** :
- Dans le même filet, une signature Git = empreinte de `for-each-ref --format=%(objectname) %(refname)` (11.4 ms) et de `worktree list --porcelain -z` (8.6 ms, qui porte le HEAD de chaque worktree). Soit ~20 ms toutes les 5 s, sans dépendre du format de stockage des refs (`files` ici ; reftable possible ailleurs [ASSUMED]).
- On peut y ajouter le `mtime` de l'`index` de chaque worktree (un `stat`) pour suivre ce qui est indexé.
- Un changement émet `git { seq, at, sig }`, sans charge utile. La page relit `GET /api/vf/git` seulement si le tiroir est ouvert.
- Les fichiers modifiés de l'arbre de travail ne laissent aucune trace bon marché dans `.git` : `status` ne se relance qu'à l'ouverture du tiroir et à chaque événement `git`. Si la recette l'exige, ajouter un bouton « actualiser » plutôt qu'un polling (P78-D-15).
- Un `stat` de `packed-refs` et `refs/**` serait plus économe, mais fragile : `refs/` n'a pas de `mtime` récursif, et reftable change tout.

## 7. Témoins de test

**Modèle** : `test-cockpit-retard.sh`, avec `export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null` et une identité fixe (l. 11-12), `mktemp -d` puis `trap rm`. On y trouve aussi un emballage `git` qui journalise l'argv (l. 66-71), le témoin positif d'un `fetch` délibéré (l. 154-155), le contrôle que chaque appel porte `core.fsmonitor=false` et `--no-optional-locks` (l. 156-157), et une sonde réseau `node --import sonde.mjs` avec témoin positif (l. 43-64, 158-164) [VERIFIED: plugin/cockpit/scripts/tests/test-cockpit-retard.sh].

**Fixture recommandée** : la suite `test-cockpit-git.sh` construit son dépôt (`init -b main`) avec :
- `c0`, une branche `f` avec `merge --no-ff`, un merge octopus (`merge f g`), une seconde racine (`checkout --orphan`) ;
- une ref distante locale (`update-ref refs/remotes/origin/main`), `symbolic-ref refs/remotes/origin/HEAD` ;
- un worktree sur une branche et un worktree détaché, un tag annoté et un tag léger, deux `stash push` ;
- les refs hostiles `refs/heads/-x`, `refs/heads/--all`, ``refs/heads/x;y|z`w` ``, `refs/heads/<svg/onload=alert(1)>` (via `update-ref`), et un binaire et un renommage pour `--numstat` ;
- le dépôt piégé du § 5 (marqueurs), avec un **témoin positif** : `show -p` sans les options pose bien le marqueur `textconv`, sinon la sonde est aveugle (mémoire « Un négatif aveugle ne prouve rien »).

**Côté serveur.** On démarre le serveur comme `test-cockpit-serveur.sh:84-91` : `vf-cockpit-build.mjs`, `serve.mjs --no-open --port $(libre)`, jeton lu dans la page.
- `GET /api/vf/git` → schéma, couloirs, étiquettes ;
- `GET /api/vf/git/commit?sha=` avec un SHA valide, court, `--all`, `HEAD`, l'arbre, absent → 400 ou 404 ;
- POST → 405 ; sans jeton → 403.

**Côté page (CDP).** On trouve Chrome comme `test-cockpit-projet.sh:358`, et la section est SAUTÉE sans navigateur, jamais comptée réussie. Puis `chrome-session.mjs` : `ouvrir(chrome, { csp: true })`, `naviguer`, `attendre`, `stable`, `violations`. On vérifie :
- le tiroir s'ouvre au clic sur la seconde ligne et à la touche `g` ;
- `document.querySelector('[data-ref]')` ne crée aucun élément `svg` ou `script` injecté depuis un nom de ref (`<svg/onload…>` rendu en texte) ;
- aucune violation CSP ;
- la dégradation : `PATH` sans git, ou lab hors dépôt → aucune seconde ligne et 0 erreur console.

Mutants : copies de la sortie, jamais du module (modèle `test-cockpit-chaine-xss.sh` : M-ESC, M-CSP). On retire tour à tour le motif SHA, `--end-of-options`, la citation shell, la borne `-n` et la neutralisation des filtres. Chaque mutant doit faire rougir sa sonde.

## Journal des hypothèses
| # | Hypothèse | § | Risque si fausse |
|---|---|---|---|
| A1 | `maxBuffer` de `execFileSync` = 1 Mio par défaut | 1 | troncature plus tôt ou plus tard ; contournée par un `maxBuffer` explicite |
| A2 | `%(ahead-behind:)` apparaît en git 2.41 ; la version de git du runner CI (Ubuntu 26.04) n'est pas vérifiée | 1 | CI rouge, repli `rev-list --count` |
| A3 | `--topo-order` ~linéaire sans commit-graph (≈1 s à 100 000 commits) | 1 | échéance de 10 s approchée sur un gros dépôt |
| A4 | Équivalence de l'algorithme avec `git log --graph`, gitk et GitKraken | 2 | aucun, l'algorithme est sondé à part |
| A5 | Fichier LFS stat-dirty vu « modifié » une fois les filtres vidés | 5 | faux positif d'affichage |
| A6 | Liste complète des variables `GIT_*` à retirer | 5 | une variable oubliée détourne le dépôt lu |
| A7 | `packed-refs` sans borne de longueur de nom | 5 | borne d'affichage seule |
| A8 | reftable possible sur d'autres labs | 6 | la signature par `stat` casserait ; celle par `for-each-ref` tient |

## Recommandations pour le planner
1. Un module `vf-cockpit-git.mjs` (lecture seule) au-dessus de `shBorne` et `GIT_SUR`, avec un préfixe `GIT_LECTURE = [...GIT_SUR, '--no-ext-diff', '--no-textconv']` pour log, show et diff-tree, des filtres vidés pour `status`, et un environnement git sans `GIT_DIR` et consorts.
2. Extraction en 3 appels : `for-each-ref` (ahead-behind et peel), `log` sur la base `-n N`, `log` des non mergées `--not <base> -n M`, en refs entièrement qualifiées ; parseur à paquets de 5 champs, vérifié par motif.
3. Placement des couloirs maison en JS pur, testable sous node, et rendu SVG maison ; ELK écarté.
4. Détail d'un commit : motif strict puis `rev-parse --verify --end-of-options <sha>^{commit}`, puis `log -1 -z` et `diff-tree <sha>^1 <sha>` (ou `--root`), avec bornes sur les fichiers et le message.
5. Le `status` de chaque worktree à la demande, jamais dans le filet ; `-unormal` avec une borne sur les entrées.
6. Une signature Git dans le filet de 5 s (`for-each-ref` et `worktree list -z`), un événement `git` sans charge, une relecture seulement quand le tiroir est ouvert.
7. Un schéma `vibeflow/cockpit-git@1` dans `vf-cockpit-interface.json`, aucune clé de `interdits`, toutes les chaînes passées par `nettoie`.
8. Des commandes à copier citées par une seule fonction, avec `--end-of-options` avant les refs ; worktree par `refs/heads/<nom>` après sonde.
9. Une suite `test-cockpit-git.sh` (dépôt jetable, refs hostiles, dépôt piégé avec témoin positif, CDP, mutants) ; elle est découverte par la CI sans être inscrite.
10. Les auteurs agrégés en JS sur `log --format=%an%x00%at`, jamais `shortlog` sans révision.

## Questions ouvertes
1. **Fichiers « modifiés » et filtres.** Vider les filtres (LFS faussement modifié) ou ne pas calculer « modifiés » quand un filtre est déclaré ? C'est un choix d'affichage (P78-D-06), à arbitrer.
2. **Valeurs de N, M et des bornes** (500 et 500 proposés) : à caler sur la recette visuelle et la largeur mobile (P78-D-19).
3. **Base du retard** quand `origin/HEAD` manque et que `main` local diverge d'`origin/main` (cas `614 0` mesuré) : faut-il montrer les deux, comme `retard()` le fait déjà ?
4. **Version de git sur le runner CI**, pour `%(ahead-behind:)` : à sonder au premier passage de la CI.
5. **Forme exacte de la commande worktree à copier** pour un nom en `-` : à sonder dans la suite.

## Sources
- **Code lu cette session :** `vf-cockpit-paths.mjs:100-175`, `vf-cockpit-arbres.mjs` (en entier), `vf-cockpit-env.mjs`, `vf-cockpit-live.mjs`, `vf-cockpit-server.mjs`, `vf-cockpit-signal.mjs:1-80`, `vf-cockpit-who.mjs:108-118`, `vf-cockpit-interface.json:1-30`, `serve.mjs:488-560`, `00-vibeflow.js:1-90`, `tests/test-cockpit-retard.sh`, `tests/chrome-session.mjs`, `tests/test-cockpit-serveur.sh:60-100`, `scripts/ci-shard-suites.sh:22`, `78-CONTEXT.md`.
- **Doc officielle git (CITED) :** git-scm.com/docs/git, git-log, git-status, git-for-each-ref, git-worktree, gitcli, git-check-ref-format.
- **Sondes (scratchpad) :** `mesure.mjs`, `mesure2.mjs`, `lanes.mjs`, `hostile.sh` sous `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/`.
- **Paquets :** aucun paquet externe installé (Node natif), donc audit de légitimité sans objet.

**Valide jusqu'au :** 2026-12-05 (git et Node stables ; refaire les mesures si la version de git du poste ou de la CI change).
