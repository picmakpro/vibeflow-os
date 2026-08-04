# Workstreams — doctrine du compartiment de planning (GSDA-13 → GSDA-17)

> Voix unique du module sur les workstreams du moteur : quelle surface existe réellement, comment
> le compartiment actif se résout, quel canal le lab emploie, et à quels risques mesurés l'adoption
> l'expose. Chargée **on-demand** par `vf-dev-manager` et `vf-coder`, comme `mission-flow.md` et
> `GSD-PIPELINE.md` — coût contexte nul le reste du temps. La **décision** d'adopter, ses limites
> et leurs dates appartiennent à **ADR-069** : ce fichier ne la rejoue pas, il dit comment
> travailler avec. Toutes les mesures ci-dessous sont de première main sur `@opengsd/gsd-core`
> **1.9.1**, au **2026-08-04**.

---

## 1. La surface réelle du moteur — sept sous-commandes, une seule liste d'erreur

Sept sous-commandes de workstream existent, pas une de plus :

| Sous-commande | Ce qu'elle fait | Ce qu'il faut savoir |
|---|---|---|
| `create <nom>` | crée un compartiment | **migre par défaut** ; `--no-migrate` pour ne pas migrer, `--migrate-name <nom>` pour nommer la migration |
| `list` | liste les compartiments | |
| `status [nom]` | état du compartiment nommé, ou du compartiment actif si le nom est omis | |
| `complete <nom>` | clôt un compartiment | |
| `set <nom>` | **écrit** le pointeur | pointeur de session : §3 dit pourquoi ce n'est pas le canal du lab |
| `get` | **lit** le pointeur | même réserve |
| `progress` | avancement du compartiment | |

Toute autre valeur produit la liste d'erreur amont, à citer plutôt qu'à deviner :
`Unknown workstream subcommand. Available: create, list, status, complete, set, get, progress`.

La fonction de migration est **exportée sans sous-commande propre** : il n'existe pas de
`workstream migrate`. La partition d'un dépôt passe donc par `create <nom> --migrate-name <nom>`,
jamais par une commande de migration dédiée qu'on chercherait en vain.

## 2. La résolution du compartiment actif — trois niveaux court-circuitants

`resolveActiveWorkstream` (`active-workstream-store.cjs:252-277`) tranche dans un ordre strict ; le
premier niveau qui répond gagne, les suivants ne sont **jamais** consultés :

1. **`--ws <nom>`** ou **`--ws=<nom>`** en ligne de commande (`parseCliWorkstream:223-251`) → source
   `cli`. Le parseur **retire le drapeau ET sa valeur** des arguments avant de les passer plus
   loin, et **jette** si la valeur manque ou commence par un double tiret.
2. **`GSD_WORKSTREAM`** non vide dans l'environnement → source `env`.
3. **le pointeur de session** → source `store` ; à défaut, source `none`.

Le nom est validé aux trois niveaux (alphanumériques, tiret, souligné, point ; premier caractère
alphanumérique). Cette politique de nom a **une seule** écriture, `workstream-policy.sh` du module
`planning-core` — jamais recopiée, ici pas plus qu'ailleurs. Après résolution,
`applyResolvedWorkstreamEnv` (`:278-282`) **repose** `GSD_WORKSTREAM` dans l'environnement : ce qui
a été résolu par `--ws` se propage ensuite tout seul par la variable.

Vérifié en direct contre le moteur, ce 2026-08-04 :

| Ce qu'on passe | Ce que le moteur résout |
|---|---|
| rien | `null`, source `none` — **alors que `.planning/active-workstream` contient `dev`** |
| `GSD_WORKSTREAM=dev` | `dev`, source `env` |
| `--ws dev` | `dev`, source `cli`, et les arguments rendus ne portent plus le drapeau |

## 3. La règle du lab — dans un worktree, on EXPORTE `GSD_WORKSTREAM`

**La règle.** Sur un dépôt partitionné, chaque worktree **exporte `GSD_WORKSTREAM=<nom>`** pour la
durée de la mission, et toute invocation du moteur qui peut porter `--ws` le porte. On ne se fie
**jamais** au pointeur de session pour savoir sur quel compartiment on travaille.

**Pourquoi c'est le geste le moins coûteux.** `GSD_WORKSTREAM` est un canal de **premier rang** de
la résolution (§2, niveau 2) : il court-circuite le pointeur, donc il résout **sans jamais toucher
au fichier de `os.tmpdir()`**. C'est très exactement ce qui rend workstreams et worktrees
composables, là où le pointeur, lui, ne l'est pas.

**Ce que le pointeur a de particulier.** Dès qu'une clé de session est disponible, le pointeur ne
vit pas dans le dépôt : il vit dans un sous-dossier de `os.tmpdir()` indexé sur un condensat du
chemin absolu **réel** du `.planning` et sur cette clé. Il est donc effacé au redémarrage, distinct
par worktree et **jamais hérité** — non composable avec **ADR-064** (« un écrivain = un worktree »).

**Ce n'est pas générique, c'est mesuré.** L'adaptateur `os.tmpdir()` n'est retenu que si une clé de
session résout ; sinon le moteur retombe sur le pointeur **in-repo** `.planning/active-workstream`,
lui composable. Sous Claude Code, mesuré ce 2026-08-04, la clé effective est
`CLAUDE_CODE_SSE_PORT` — un numéro de port, donc **recyclable** : la clé observée valait
`claude-code-sse-port-25130`. C'est donc bien l'adaptateur `os.tmpdir()` qui est retenu ici, et le
canal fichier in-repo **n'est jamais lu** : le moteur rend `null` pendant que
`.planning/active-workstream` dit `dev` (table du §2). Un runtime sans clé de session, lui,
tomberait sur le canal in-repo et n'aurait pas ce problème — ne généralise pas notre mesure.

**Le silence est la vraie difficulté.** `getActiveWorkstream` auto-nettoie : nom invalide, ou
`.planning/workstreams/<nom>/` inexistant, et il efface le pointeur puis rend « aucun workstream »,
sans un mot. Le gate `check-workstream-pointer.sh` (module `conductor`) existe pour rendre cet
échec audible : il ne consulte que les **deux canaux composables** (`GSD_WORKSTREAM`, puis le
pointeur partagé in-repo) et échoue bruyamment quand aucun des deux ne résout sur un dépôt
partitionné. Sur un dépôt non partitionné il sort en 3 sans un mot : c'est l'état nominal de tous
nos labs à ce jour, pas un manque.

## 4. Les quatre risques mesurés, chacun avec son geste

Aucun des quatre n'est un avertissement décoratif : chacun se solde par un geste à faire.

**(a) La couverture amont est marginale.** Re-mesuré en `awk` + `comm` sur les **91 workflows
racine** de `gsd-core` 1.9.1, ce 2026-08-04 : **5 seulement connaissent les workstreams, soit
5,5 %** ; **45 codent en dur** `.planning/ROADMAP.md`, `.planning/STATE.md` ou `.planning/phases`,
dont **43 sans aucune conscience** du sujet — `execute-phase`, `execute-plan`, `plan-phase`,
`discuss-phase`, `next`, `ship`, `pr-branch`, `quick`, `progress` et `complete-milestone` en font
partie. *(L'arbitrage de la phase 24 annonçait 7 sur 91, soit 7,7 %, et 42 aveugles ; ces deux
valeurs ne se reproduisent pas sur 1.9.1, et l'écart va dans le sens du pire.)*
→ **Geste** : sur un dépôt partitionné, avant de faire confiance au verdict d'un de ces workflows,
vérifie **quel chemin il a effectivement lu**. Lui passer `--ws` ne le sauve pas : il ne sait pas
le lire, il écrira à la racine quoi qu'on lui ait passé.

**(b) Une PR ouverte depuis un compartiment perd ses commits de feuille de route.** Le workflow de
branche de PR classe les commits avec des regex **ancrées** à la racine — `pr-branch.md:235-236`,
vérifié à ces lignes exactes. `.planning/workstreams/<nom>/STATE.md` ne matche plus le motif
« structurel » : il retombe en transitoire, donc **exclu**. Les commits de feuille de route
disparaissent **silencieusement** de la branche de PR — silencieusement, c'est-à-dire sans
avertissement, sans compteur, sans trace.
→ **Geste** : avant d'ouvrir une PR depuis un compartiment, liste explicitement les commits de
feuille de route attendus et vérifie qu'ils y figurent ; rattache-les à la main sinon.

**(c) Le pointeur de session ne se compose pas avec ADR-064.** Il est indexé sur le chemin absolu
du `.planning`, donc chaque worktree ouvre sans compartiment résolu, et rien ne le dit.
→ **Geste** : la règle du §3 — exporter `GSD_WORKSTREAM`, passer `--ws` — plus
`check-workstream-pointer.sh` en garde. Rien d'autre ne referme ce risque.

**(d) La divergence post-partition est invisible pour Git.** L'outil de fusion à trois branches
sort en **succès** sur une branche post-partition portant un dossier de phase resté orphelin à la
racine, pendant que le `STATE.md` du compartiment déclare cette phase courante. **Git ne signale
rien** : il n'y a pas de conflit à signaler, il y a deux vérités qui ne se rencontrent jamais.
→ **Geste** : ne prends jamais le silence de Git pour une validation après une partition ; compare
à la main les dossiers de phase des deux côtés avant de fusionner.

## 5. La condition dure

> Règle : **aucune partition tant qu'une phase est en vol.**

Ce n'est pas une recommandation, c'est une interdiction. Sa raison est le risque (d) : une phase en
cours est exactement l'état où un dossier de phase existe des deux côtés de la partition, donc
exactement le cas où la divergence invisible frappe — sans que Git ait rien à en dire. On
partitionne entre deux phases, jamais pendant.
