# Workstreams — doctrine du compartiment de planning (GSDA-13 → GSDA-17)

> Voix unique du module sur les workstreams du moteur : quelle surface existe réellement, comment
> le compartiment actif se résout, quel canal le lab emploie, et à quels risques mesurés l'adoption
> l'expose. Chargée **on-demand** par `vf-dev-manager` et `vf-coder`, comme `mission-flow.md` et
> `GSD-PIPELINE.md` — coût contexte nul le reste du temps. La **décision** d'adopter, ses limites
> et leurs dates appartiennent à **ADR-069** : ce fichier ne la rejoue pas, il dit comment
> travailler avec. Toutes les mesures ci-dessous sont de première main sur `@opengsd/gsd-core`
> **1.9.1**, au **2026-08-04**.
>
> Le CHOIX de partitionner se pose au DÉMARRAGE d'un lab (Phase 41.2 de ce dépôt) — ce fichier
> décrit comment travailler UNE FOIS le choix fait, dans un sens comme dans l'autre.

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

**Procédure de bascule, et sa précondition.** Partitionner un dépôt qui ne l'est pas encore suit
trois gestes, dans cet ordre :

1. **Vérifier la précondition** — **aucune phase en vol**, la condition dure du §5 ci-dessous, lue
   sur un **champ du disque** et jamais présumée depuis la mémoire d'une session : dans le
   `STATE.md` visé, `status` différent de `executing` sur la phase courante, et aucun dossier de
   phase dont le `SUMMARY.md` manque encore. La règle n'est pas reformulée ici : c'est celle du
   §5, une seule écriture.
2. **`create <nom> --migrate-name <nom>`** pour le premier compartiment — c'est lui qui migre le
   contenu resté à la racine.
3. **`create <nom>`** pour chaque compartiment supplémentaire, créé vide.

Le **choix** de partitionner **au démarrage** d'un lab, avant toute phase, est le geste le moins
coûteux : la précondition du point 1 y est vraie sans rien avoir à attendre. L'ergonomie de ce
choix appartient à la Phase 41.2 de ce dépôt, pas à ce fichier.

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
`CLAUDE_CODE_SSE_PORT` — un numéro de port, donc **recyclable** : la clé observée avait la forme
`claude-code-sse-port-<port>`. **La valeur résolue n'est pas publiée** : ce fichier est distribué à
chaque installation depuis un dépôt public, et le threat model de ce lot n'accepte le risque qu'au
motif exprès qu'on y décrit la **forme** d'un chemin, **jamais sa valeur** relevée sur un poste.
C'est donc bien l'adaptateur `os.tmpdir()` qui est retenu ici, et le
canal fichier in-repo **n'est jamais lu** : le moteur rend `null` pendant que
`.planning/active-workstream` dit `dev` (table du §2). Un runtime sans clé de session, lui,
tomberait sur le canal in-repo et n'aurait pas ce problème — ne généralise pas notre mesure.

**Le silence est la vraie difficulté.** `getActiveWorkstream` auto-nettoie : nom invalide, ou
`.planning/workstreams/<nom>/` inexistant, et il efface le pointeur puis rend « aucun workstream »,
sans un mot. Le gate `check-workstream-pointer.sh` (module `conductor`) existe pour rendre cet
échec audible : il ne consulte que les **deux canaux composables** (`GSD_WORKSTREAM`, puis le
pointeur partagé in-repo) et échoue bruyamment quand aucun des deux ne résout sur un dépôt
partitionné. Sur un dépôt non partitionné il sort en 3 sans un mot — l'état nominal d'un **lab qui
installe VibeFlow**, où le non-partitionné reste le défaut (Phase 41.2, WSCH-01 : une question,
jamais imposé). **Ce dépôt lui-même (`vibeflow-os`) est partitionné depuis le 2026-09-23** (PR #94,
D-02) : l'affirmation antérieure de ce paragraphe (« l'état nominal de tous nos labs ») ne décrivait
plus l'état de ce dépôt-ci, et elle est corrigée ici pour ne plus confondre **ce** dépôt et les labs
qu'il distribue.

## 4. Les quatre risques mesurés, chacun avec son geste

Aucun des quatre n'est un avertissement décoratif : chacun se solde par un geste à faire.

**(a) La couverture amont est marginale.** Re-mesuré en `awk` + `comm` sur les **91 workflows
racine** de `gsd-core` 1.9.1, ce 2026-08-04 : **7 seulement savent résoudre un scope, soit 7,7 %** ;
**45 codent en dur** `.planning/ROADMAP.md`, `.planning/STATE.md` ou `.planning/phases`, dont
**42 sans aucune conscience** du sujet — `execute-phase`, `execute-plan`, `plan-phase`,
`discuss-phase`, `next`, `ship`, `pr-branch`, `quick`, `progress` et `complete-milestone` en font
partie.

**Un taux de couverture ne veut rien dire sans son critère d'inclusion nommé.** Trois critères
cohabitent sur ce corpus, et ils ne posent pas la même question :

| Critère | Ce qu'il compte | Conscients | Taux | En dur | Aveugles |
|---|---|---|---|---|---|
| K1 | le mot `workstream` seul — *le mot apparaît-il ?* | 5 | 5,5 % | 45 | 43 |
| **K2** | K1 **ou** l'option `--ws` — *le workflow sait-il résoudre un scope ?* | **7** | **7,7 %** | **45** | **42** |
| K3 | K2 **ou** la variable `GSD_WS` — *toute forme de surface* | 16 bruts / **15 réels** | 17,6 % / **16,5 %** | 45 | 35 |

La colonne **En dur** vaut 45 aux trois critères, et ce n'est pas une redondance : elle montre que
le dénominateur du problème ne bouge pas quand le critère bouge. Une table qui l'omettrait laisserait
croire qu'un critère plus large réduit la dette — il ne fait que compter autrement ceux qui la
portent.

**K3 porte une réserve, et elle est indissociable de son chiffre.** `reapply-patches.md:220` ne cite
`${GSD_WS}` que comme *exemple de dérive de variable* dans une doc de rapprochement de patchs : il
n'est workstream-aware en rien. K3 vaut donc **16 bruts / 15 réels**, soit **16,5 %**. C'est ce taux,
et non 17,6 %, qui réhabilite le « ~18 % » du ROADMAP — le citer sans sa réserve reproduirait un cran
plus bas l'erreur que ce tableau corrige : un nombre sans son critère.

**K2 est le critère de cette référence**, parce que c'est lui qui répond à la seule question qui
nous engage : le workflow sait-il sur quel compartiment il travaille. Les trois mesures qui ont
circulé se rangent alors sans contradiction — les **7 sur 91 / 42 aveugles** de l'arbitrage de la
phase 24 se reproduisent **exactement**, c'est K2 ; les **5 sur 91 / 43 aveugles** d'une re-mesure
ultérieure sont **exactement K1** ; et le **~18 %** du ROADMAP est **retrouvé** par K3 (17,6 %).
Aucune n'est fausse, aucune n'est irreproductible, et l'écart ne va **pas** « dans le sens du
pire » : il ne manquait qu'un critère déclaré. Corpus, définition des trois critères et **commande
rejouable** : **ADR-069, § Méthode** — ne les recopie pas ici, re-dérive-les là-bas.
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
Précision datée (ADR-069, amendement 2026-09-09) : `.planning/workstreams/<nom>/ROADMAP.md` n'est
**pas structurel au niveau commit non plus** — exclu silencieusement dans les deux modes de
`pr_strict`, pas seulement au niveau chemin (`$OTHER`) déjà couvert ci-dessus.

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
Complément mécanique (D-11/D-12, plan `39-01`) : `scripts/hooks/post-merge` + `check-divergence.sh`
détectent cette signature automatiquement — opt-in (`git config core.hooksPath scripts/hooks`) et
câblé sur le job CI `gates`, jamais armé par défaut. Le geste manuel ci-dessus reste le repli sur un
dépôt non armé.

## 5. La condition dure

> Règle : **aucune partition tant qu'une phase est en vol.**

Ce n'est pas une recommandation, c'est une interdiction. Sa raison est le risque (d) : une phase en
cours est exactement l'état où un dossier de phase existe des deux côtés de la partition, donc
exactement le cas où la divergence invisible frappe — sans que Git ait rien à en dire. On
partitionne entre deux phases, jamais pendant.

## 6. La définition unique de « compartiment conforme »

**Cette section est la source.** Tout gate, tout skill, toute phase qui a besoin de juger l'état
d'un compartiment classe selon la trichotomie ci-dessous, et ne la redéfinit jamais ailleurs. Elle
est recopiée **verbatim** de la décision D-02 du cadrage de la Phase 41.1 (`41.1-CONTEXT.md`, D-02
dans sa rédaction amendée du 2026-09-23) — le CONTEXT en est la trace de décision, ce fichier en
est le porteur **versionné et distribué**, parce qu'une définition dont le seul porteur est le
CONTEXT d'une phase close est inaccessible à qui devra l'appliquer.

> Un compartiment `.planning/workstreams/<nom>/` est **conforme** quand (1) `STATE.md` existe, est
> lisible, et son frontmatter porte au minimum `gsd_state_version`, `milestone`, `current_phase` et
> `status` renseignés (au-delà de la seule facture nominale `workstream create`) ; (2) aucune des
> divergences S2 (orphan)/S4 (roadmap-conflict)/S5 (rootonly) de `check-divergence.sh` n'y est
> détectée pour ce compartiment.
>
> Il est **non initialisé** quand le dossier existe, `vf_ws_path_nolink` le valide (pas un lien),
> et que son `STATE.md` ne porte QUE la facture nominale de `workstream create` — frontmatter
> réduit à `workstream:` + `created:`, sans `gsd_state_version`. Le critère porte sur le
> **frontmatter seul** : la présence ou l'absence de `ROADMAP.md`/`REQUIREMENTS.md`/`phases/` de
> contenu n'entre PAS dans la classification. C'est un compartiment créé, jamais travaillé côté
> état — verdict propre et visible, **jamais un échec**. `gouvernance/STATE.md` (frontmatter à
> 2 clés, rc=2 mesuré le 2026-09-23) relève de cette catégorie.
>
> **Verdict nommé d'ambiguïté (amendement du 2026-09-23, arbitrage Samuel, AskUserQuestion session
> principale — Q1 option b).** Quand un `STATE.md` au frontmatter nominal coexiste AVEC du contenu
> (`ROADMAP.md` non vide, `REQUIREMENTS.md` non vide, ou au moins un dossier sous `phases/`), le
> gate émet EN PLUS du verdict « non initialisé » une **notice nommée d'ambiguïté** — une notice,
> **jamais un échec**. Cette notice **nomme les DEUX lectures possibles et n'en choisit aucune** :
>
> - lecture (i) — compartiment **neuf alimenté par carve-out** : la partition a déplacé du contenu
>   dans un compartiment dont l'état n'a pas encore été initialisé (le cas de `gouvernance`) ;
> - lecture (ii) — compartiment **travaillé dont l'état a été tronqué** : un `STATE.md` amputé en
>   plein cycle d'écriture — le cas que le paragraphe « corrompu » ci-dessous nomme mot pour mot.
>
> Motif : les deux situations ont la **même signature sur disque**. Aucune règle locale ne peut les
> départager. Discriminer par l'historique git a été **explicitement écarté** (l'arbitrage nomme
> le motif : cela ferait dépendre le verdict d'un passé que rien ne garantit présent — un dépôt
> fraîchement cloné en shallow, un compartiment jamais commité). Le gate rend donc les deux
> lectures visibles plutôt que d'en exempter une en silence : `gouvernance` reste vert, et une
> troncature réelle **cesse d'être invisible**.
>
> Invariant : les deux verdicts — non-initialisé simple et non-initialisé + notice d'ambiguïté —
> sont des **non-échecs**. Le gate ne rougit sur aucun des deux.
>
> Il est **corrompu** dans tout autre cas : fichier illisible pour une raison qui n'est PAS « jamais
> initialisé » (permissions, frontmatter tronqué au milieu d'un cycle d'écriture, `current_phase`
> incohérent avec les dossiers de phase réellement présents, etc.) — c'est-à-dire tout état qui
> n'est NI le frontmatter minimal nominal du moteur NI structurellement sain selon (1)-(2)
> ci-dessus.
>
> **Frontière avec la notice d'ambiguïté :** une troncature qui laisse EXACTEMENT le frontmatter
> nominal à 2 clés est indiscernable d'une création — elle relève de « non initialisé » et déclenche
> la notice d'ambiguïté ci-dessus dès qu'il y a du contenu à côté. Une troncature qui laisse tout
> AUTRE chose (3 clés, une clé orpheline, un frontmatter non fermé, `gsd_state_version` présent mais
> `current_phase` manquant) relève de « corrompu » et reste un écart.

**HORS DÉFINITION — la présence de `ROADMAP.md` et `REQUIREMENTS.md` (correction C1-2, juge frais
tour 4).** La rédaction précédente faisait de « `ROADMAP.md` et `REQUIREMENTS.md` existent et sont
lisibles » une clause de la conformité. AUCUN gate du périmètre de cette phase ne l'établit —
MESURÉ le 2026-09-23 : `check-divergence.sh` traite un `ROADMAP.md` absent comme un NON-ÉCART
(`check_s4a`, l.194-197 : « S4 non applicable — pas de ROADMAP.md dans ce compartiment », puis
`return 0`), et `REQUIREMENTS.md` n'est lu par AUCUN script du périmètre (0 occurrence dans
`check-divergence.sh`, `check-state-integrity.sh` et `workstream-policy.sh`). La clause est donc
RETIRÉE de la définition, au lieu d'y rester écrite sans que rien ne la mesure : la Phase 41.2
(WSCH-02) ne doit pas hériter d'un critère qu'aucun gate ne sait appliquer, sinon WSCH-04 (« les
gates passent au vert sur chaque compartiment ») serait VRAI sur un compartiment que WSCH-02
déclarerait non conforme. Même motif pour l'exemple « `ROADMAP.md` absent alors que `STATE.md`
atteste d'un `current_phase` > 0 », retiré de la liste des formes corrompues : il n'est mesuré par
rien. Le besoin reste légitime et part au BACKLOG — le mesurer demande un gate neuf, hors périmètre
d'une phase déjà à neuf plans et trois tours de jugement.

Cette trichotomie est **indépendante** de la primitive d'énumération D-01 (qui ne fait que lister
des chemins) : elle est appliquée PAR CHAQUE GATE qui a besoin de juger un compartiment, pas par la
primitive elle-même — un gate consulte `vf_ws_enumerate`, puis classe chaque chemin retourné selon
cette définition.
