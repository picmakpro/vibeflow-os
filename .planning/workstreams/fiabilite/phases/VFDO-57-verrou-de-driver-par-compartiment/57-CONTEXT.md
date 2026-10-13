# Phase 57: Verrou de driver par compartiment - Context

**Gathered:** 2026-10-10
**Status:** Ready for planning

Cadrage `gsd-discuss-phase` en session principale, quatre zones, questions regroupées par zone (4 appels,
11 questions). **P57-D-01 à P57-D-11 : arbitrage Samuel, AskUserQuestion session principale, 2026-10-10**,
option recommandée retenue à chaque fois. P57-D-12 à P57-D-15 sont laissés à la discrétion du planificateur
(arbitrage Samuel, même canal, même date : « Écris le CONTEXT »).

**Exigences :** DLWS-01 à DLWS-08 (`REQUIREMENTS.md`), posées le 2026-10-10 à l'ouverture de la planification. Elles
reformulent P57-D-01 à P57-D-15 sans rien y ajouter ; aucun arbitrage neuf n'a été demandé.

<domain>
## Phase Boundary

`driver-lock.sh` devient compartiment-aware dans un lab **partitionné** : un verrou par compartiment, plus
un verrou de dépôt court pour les gestes qui touchent des fichiers communs. `guard-driver-lock.sh` est aligné
sur la même résolution. L'invariant d'ADR-053 devient « un manager **par compartiment** », par amendement daté.
Le head passe `--ws` et un `GSD_SESSION_KEY` distinct par manager (spec head §6, points 1 à 3).

Un lab **non partitionné** garde exactement le comportement d'aujourd'hui.

Hors de cette phase : la preuve d'usage concurrent réel, à deux humains (spec head §6, point 4), portée par
la Phase 61.

</domain>

<decisions>
## Implementation Decisions

### Portée et fichiers partagés
- **P57-D-01 (granularité)** : un manager prend le verrou de **son** compartiment. Les gestes qui touchent
  des fichiers communs prennent **en plus** un verrou de dépôt, court, tenu le temps du geste et pas de la
  mission. Deux missions sur deux compartiments avancent en parallèle ; deux gestes de dépôt, jamais.
- **P57-D-02 (gestes sous verrou de dépôt)** : les quatre suivants.
  - **La release** : bump de `VERSION`, `plugin.json`, `marketplace.json`, des README et du CHANGELOG
    racine, puis le tag.
  - **L'écriture de `.planning/BACKLOG.md` et de `docs/ADR.md`**, dont la numérotation des ADR.
  - **Les fichiers racine de `.planning/`**, qui n'appartiennent à aucun compartiment : `PROJECT.md`,
    `MILESTONES.md`, `config.json`, `active-workstream`, `archives/`, etc.
  - **La partition ou la bascule de compartiments** (`split-planning.sh`).
- **P57-D-03 (lab plat)** : un lab non partitionné ne voit **aucune différence, au bit près**.
  - Même chemin `.planning/DRIVER.lock`, même JSON, même comportement du guard.
  - Les suites existantes de `driver-lock.sh` et `guard-driver-lock.sh` passent **sans modification** :
    c'est le témoin de non-régression.
  - Le verrou de dépôt ne s'applique pas à un lab plat.
  - **Reversibility:** costly. Faire entrer plus tard les labs plats dans le nouveau régime changerait le
    comportement de tous les labs installés, et demanderait une migration annoncée.

### Résolution du compartiment
- **P57-D-04 (source)** : dans un lab partitionné, le compartiment vient d'un **`--ws=<sujet>` explicite**
  passé à `driver-lock.sh`. On ne le déduit jamais de `VF_WORKSTREAM`, de `GSD_WORKSTREAM` ni du pointeur
  `active-workstream`. C'est la règle des gates d'ADR-069 (amendement du 2026-09-23) : un export oublié ne
  doit pas verrouiller le mauvais sujet en silence. Le head porte déjà le sujet dans le mandat (P412-D-10,
  spec head §6, point 3).
- **P57-D-05 (rien de fourni)** : lab partitionné, `acquire` appelé sans `--ws`. La mission prend le
  **verrou de dépôt**, ce qui la sérialise comme aujourd'hui, et le JSON le dit (`scope: depot` et la
  raison). Aucune mission n'est bloquée, et l'oubli reste visible. *Précision du cadrage, non arbitrée et
  laissée au planificateur :* un `--ws` qui ne désigne aucun compartiment présent sur le disque serait
  plutôt un **refus** (`acquired:false`, raison nommée), puisque ce n'est pas un oubli mais une erreur.
- **P57-D-06 (multi-sujet)** : une mission porte sur **un seul** compartiment. Le travail transverse passe par
  le verrou de dépôt ou se découpe en deux missions. Jamais deux verrous de compartiment tenus par la même
  mission, donc aucun ordre d'acquisition à gérer.

### Worktrees et emplacement
- **P57-D-07 (emplacement)** : dans un lab partitionné, les verrous vivent **au niveau du clone**, sous
  `$(git rev-parse --git-common-dir)`, et sont partagés par tous les worktrees de ce clone.
  - Deux sessions sur le même compartiment se voient donc, même depuis deux worktrees.
  - Lab hors git : repli sur un chemin relatif au checkout, que le JSON déclare.
  - Lab plat : inchangé (P57-D-03).
  - **Reversibility:** costly. Déplacer ensuite l'emplacement obligerait à migrer les verrous tenus, et à
    réaligner le guard, `check-branch-claim.sh`, le watchdog et E1 de `check-mission-exit.sh`.
- **P57-D-08 (entrée BACKLOG absorbée)** : « `guard-driver-lock.sh` sous EnterWorktree vise le checkout
  principal ».
  - Pour les labs partitionnés, elle est **absorbée** par la 57 : le guard résout le verrou au même
    endroit que `driver-lock.sh` (P57-D-07).
  - Pour les labs plats, elle reste ouverte au BACKLOG, puisqu'on n'y touche pas (P57-D-03). La clôture
    de la phase réécrit l'entrée en ce sens, sans la supprimer.

### Ce que le guard bloque
- **P57-D-09 (écritures)** : Write/Edit sous `.planning/` n'est refusé que sur **ce qui est tenu par
  autrui**.
  - `workstreams/A/` : refusé si A est verrouillé par une autre session.
  - `workstreams/B/` : permis si B est libre ou tenu par la session courante.
  - Fichiers racine de `.planning/` : refusés seulement si le verrou de dépôt est tenu par autrui.
- **P57-D-10 (commits)** : le guard lit `git diff --cached --name-only`. Il refuse le commit si un fichier
  indexé touche un compartiment tenu par autrui, ou un fichier commun (P57-D-02) alors que le verrou de dépôt
  est tenu par autrui. Sinon il laisse passer. Un index illisible, ou une sortie non interprétable, donne un
  **refus**, jamais une ouverture. Le blocage passe toujours par la décision JSON
  (`permissionDecision: deny`), conformément au contrat des hooks.
- **P57-D-11 (branches)** : `checkout` et `switch` dans le même checkout restent **toujours refusés** sous
  un verrou d'autrui, quel que soit le compartiment, parce qu'ils changent l'arbre de tout le monde. Les
  exemptions D-32-06 sont inchangées : `git worktree add`, et les options `--abort`, `--continue`, `--skip`
  et `--quit`.

### Claude's Discretion
- **P57-D-12 (preuve)** : la phase prouve un **mécanisme**.
  - Concurrence sur clone jetable : deux sessions simulées, deux compartiments, acquisitions parallèles
    mesurées avec le même protocole que les « 24 acquisitions concurrentes » de l'en-tête de
    `driver-lock.sh`.
  - Partage entre worktrees.
  - Repli `scope: depot`.
  - Refus du guard selon les fichiers indexés.
  - L'usage concurrent réel n'est pas prouvé ici : il revient à la 61.
  - QUAL-01 s'applique de plein droit à `driver-lock.sh` et `guard-driver-lock.sh` (trois issues et
    mutation rouge prouvée pour chaque comportement neuf).
- **P57-D-13 (ADR-053)** : rédaction de l'amendement daté, dans la forme des amendements existants de
  `docs/ADR.md`. L'invariant devient « un manager par compartiment, un seul geste de dépôt à la fois ». Il
  cite P57-D-01 à P57-D-11.
- **P57-D-14 (verrou tenu pendant la mise à jour)** : décider du sort d'un `.planning/DRIVER.lock` tenu au
  moment où un lab partitionné reçoit la nouvelle version. Piste : il vaut verrou de dépôt jusqu'à son
  relâchement. Jamais de reprise silencieuse.
- **P57-D-15 (consommateurs)** : adapter tous les consommateurs recensés par
  `rtk proxy grep -rln 'DRIVER\.lock\|driver-lock\.sh\|VF_DRIVER_LOCK' plugin scripts .github`, chacun
  vérifié et pas supposé :
  - `status`, qui doit rendre l'état par compartiment ;
  - E1 de `check-mission-exit.sh` ;
  - le watchdog et le heartbeat de la Phase 33 ;
  - `check-branch-claim.sh` ;
  - `check-guard-health.sh` ;
  - `dag.sh` ;
  - les managers qui appellent `acquire` (`vf-dev-manager`, `vf-design-manager`, les managers de bundles)
    et `mission-flow.md` ;
  - le recensement `workstream-planning-consumers.md`.

### Arbitrages de planification (2026-10-10)

Questions ouvertes par `57-RESEARCH.md` (§ Open Questions) : la mission de planification les a fait remonter
à Samuel. **P57-D-16 à P57-D-21 : arbitrage Samuel, AskUserQuestion session principale, 2026-10-10**, en
deux appels groupés par zone, et l'option recommandée a été retenue à chaque fois. Ils **précisent**
P57-D-01 à D-11 et n'en réécrivent aucun.

- **P57-D-16 (autres gestes git, Q1)** : le guard répartit les gestes git en trois classes.
  - **Arbre ou index du checkout** : `restore`, `reset`, `clean`, `merge`, `rebase`, `cherry-pick`,
    `revert`, `stash`. Ils sont traités comme `checkout`/`switch` (P57-D-11, P57-D-17).
  - **`commit`** : il est jugé sur l'index (P57-D-10, P57-D-19).
  - **`push`, `branch`, `gh pr`** : permis sous le verrou de compartiment d'autrui, refusés sous son verrou
    de dépôt. `tag` et `gh release` sont des gestes de release : ils sont refusés quand autrui tient le
    verrou de dépôt.
- **P57-D-17 (« dans le même checkout », Q2)** : le refus de P57-D-11 et de la première classe de P57-D-16
  ne s'applique que si le verrou d'autrui a été pris **depuis le même worktree**. Le champ `worktree=` du
  meta fait foi, comparé au `--show-toplevel` courant.
- **P57-D-18 (fichiers communs hors `.planning/`, Q3)** : le guard porte une liste par défaut, codée en dur,
  des fichiers qui font partie de la forme de release VF : `VERSION`, `plugin/.claude-plugin/plugin.json`,
  `.claude-plugin/marketplace.json`, `README.md`, `README.fr.md`, `CHANGELOG.md` racine et `docs/ADR.md`.
  Un commit qui indexe l'un d'eux est jugé comme un geste de dépôt. Un lab qui n'a pas ces fichiers n'est
  pas concerné. Aucun fichier de configuration neuf.
- **P57-D-19 (`commit -a`, pathspec, `--amend`, Q4)** : le jugement d'un commit prend l'union de
  `git diff --cached --name-only` et de deux autres sources : `git diff --name-only` quand la commande porte
  `-a`/`--all` ou un pathspec, et les fichiers de `HEAD` quand elle porte `--amend`. Il reste
  **fail-closed** : une source illisible donne un refus. P57-D-10 est prolongé, pas réécrit.
- **P57-D-20 (limites de l'isolation, Q5+Q6)** : l'amendement d'ADR-053 écrit deux limites assumées.
  - Les managers d'une même session partagent le `session_id`. Le guard isole donc des **sessions**, pas
    des managers. `GSD_SESSION_KEY` protège le pointeur GSD, pas le guard.
  - Le verrou unique ne ferme plus « par construction » la chaîne manager → worker → manager. Elle
    reste tenue par les allowlists `Agent(...)`, qui sont un lint.
  - Aucun refus actif neuf dans la 57.
- **P57-D-21 (layout et champs JSON, Q11)** : la forme est ratifiée telle quelle.
  - Emplacements : `$(git rev-parse --git-common-dir)/vf-driver/ws/<sujet>` pour un compartiment et
    `$(git rev-parse --git-common-dir)/vf-driver/repo` pour le dépôt, avec un dossier par verrou.
  - Champs JSON, présents **uniquement** dans un lab partitionné : `scope` (`compartiment` | `depot`),
    `ws` et `location` (`git-common-dir` | `checkout`).
  - **Reversibility:** costly (P57-D-07).

**P57-D-22 à P57-D-30** relèvent de la discrétion du planificateur (P57-D-12 à D-15). Ils ont été soumis à
Samuel pour veto par le même canal, à la même date. Réponse : « Aucun veto ».

- **P57-D-22 (`VF_DRIVER_LOCK`)** : quand cette variable est posée, le script fonctionne dans l'ancien mode
  à verrou unique, même dans un lab partitionné. Le JSON reste inchangé et les suites existantes restent
  vertes. E1 de `check-mission-exit.sh` cesse de l'exporter dans un lab partitionné.
- **P57-D-23 (DAG ↔ sujet)** : `dag.json` reçoit un champ additif `ws` (`dag.sh init --ws=`), lu de façon
  tolérante. La progression (`mark-progress`) passe `--ws`, pour que le watchdog suive le bon verrou.
- **P57-D-24 (verbes sans `--ws`)** : dans un lab partitionné, `takeover`, `reclaim`, `heartbeat`,
  `mark-progress`, `release`, `recover` et `status` appelés sans `--ws` visent le verrou de dépôt. Si
  celui-ci est absent et qu'un ancien `.planning/DRIVER.lock` est présent, ils visent ce dernier. Le JSON
  dit toujours `scope`. `status --all` agrège tous les verrous.
- **P57-D-25 (partition illisible)** : un dossier `workstreams/` illisible (lien, fichier régulier, vide
  au sens de `vf_ws_enumerate` rc 2) donne un **refus** `partition-unreadable`, jamais un repli plat. Le
  cas « fichier régulier », encore ouvert dans l'amendement d'ADR-069 du 2026-09-23, n'est pas figé
  au-delà de ce refus.
- **P57-D-26 (ancien verrou tenu à la mise à jour, réalise P57-D-14)** : dans un lab partitionné, un
  `.planning/DRIVER.lock` vivant vaut verrou de dépôt.
  - Tout `acquire` refuse alors `legacy-lock-held`, avec en `hint` la commande de release exacte.
  - Un ancien verrou périmé donne `stale-requires-takeover`.
  - Le guard le traite comme un verrou de dépôt et `status` l'expose (`legacy_lock`).
  - Jamais de reprise silencieuse. Aucun verbe neuf.
- **P57-D-27 (validation de `--ws`)** : `--ws` est validé par `vf_ws_name_valid` et `vf_ws_dir_resolve`
  (`workstream-policy.sh`) plutôt que par `vf_ws_enumerate`. Les raisons de refus fermées sont
  `unknown-ws` et `ws-invalid`, chacune avec son `hint`. La liste des compartiments n'est jamais passée
  dans un pipeline vers `grep -q` (piège `pipefail`, mesuré).
- **P57-D-28 (QUAL-01 du guard)** : le guard prouve **quatre** issues : PASS, DENY, payload imparsable
  silencieux, interprète indisponible bruyant (code 17). Chaque comportement neuf a sa mutation rouge
  prouvée. `driver-lock.sh` garde trois issues.
- **P57-D-29 (lab en sous-dossier)** : quand deux `.planning/` vivent dans un même clone, ils partagent
  `vf-driver/`. Ce cas est **hors périmètre** et écrit comme limite.
- **P57-D-30 (release)** : aucune release dans la 57. La release reste un geste humain, après la phase
  (ADR-073).

### Décisions nées de la planification (2026-10-10)

Le planificateur a posé P57-D-31 à P57-D-37 en écrivant les plans. Trois d'entre elles touchent une
décision verrouillée, le périmètre ou la doctrine du head ; elles sont **remontées à Samuel** :
**P57-D-34, P57-D-36 et P57-D-37, arbitrage Samuel, AskUserQuestion session principale, 2026-10-10**.
Il a retenu à chaque fois l'option recommandée. Les quatre autres lui ont été soumises pour veto, par le même
canal à la même date : aucun veto. Le détail de chaque décision vit dans les plans qui la citent.

- **P57-D-31 (régime plat et forcé)** : dans un lab plat, ou quand `VF_DRIVER_LOCK` est posé, `--ws` et
  `--depot` sont acceptés sans effet. Dans ces deux cas, `status --all` rend exactement la sortie de
  `status`. `--all` n'est accepté que par `status`. `VF_DRIVER_CHILDREN` n'est honorée qu'en mode verrou
  unique.
- **P57-D-32 (forme JSON complémentaire)** : en lab partitionné, le JSON ajoute `scope_reason`
  (`ws-absent` | `legacy-fallback`) et `legacy_lock` à la forme ratifiée par P57-D-21. La forme de
  `status --all` est fixée par la table de contrat de 57-01 et implémentée par 57-03. Un `--ws` vide, ou `--ws` combiné à `--depot`, est refusé
  `ws-invalid`.
- **P57-D-33 (guard, cas limites)** :
  - `git worktree remove` reste refusé sous tout verrou d'autrui.
  - Une cible git incertaine (`-C`, `--git-dir`, `--work-tree`) reprend la règle d'avant la phase :
    refus sous tout verrou d'autrui.
  - Un `git add` placé dans la même commande que le commit entre dans le jugement.
  - Le nom de compartiment est comparé exactement, ou sans tenir compte de la casse.
  - Une erreur interne du chemin partitionné donne un refus.
- **P57-D-34 (le head sérialise ses managers)** : jusqu'à la preuve d'usage réel (Phase 61), un head
  sérialise toujours ses propres managers. Les mandats portent déjà `--ws` et
  `GSD_SESSION_KEY=vf-<sujet>-<owner>`. Motif : la limite P57-D-20 ; dans la 57, la parallélisation par
  compartiment ne vaut qu'entre sessions distinctes. *Ratifiée par Samuel.*
- **P57-D-35 (gate de sortie)** : `check-mission-exit.sh --ws` couvre E1, l'identité d'E7 et la surcharge
  d'E4. Sans `--ws`, dans un lab partitionné, E1 est indéterminé. Un verrou de dépôt tenu est signalé
  sur stderr, jamais compté comme un manque.
- **P57-D-36 (périmètre élargi)** : au-delà de l'inventaire de P57-D-15, la phase modifie aussi :
  - l'étape de release de `CLAUDE.md`, en réécrivant les items existants ;
  - le skill `vf-split-planning`, dont la partition passe sous verrou de dépôt ;
  - le manuel FR et EN ;
  - l'entrée n°27 de `docs/HOOKS-CONTRAT-SORTIE.md` ;
  - une note datée au § 6 du spec head.

  *Ratifiée par Samuel.*
- **P57-D-37 (exception `--help` à P57-D-03)** : la sortie de `driver-lock.sh --help` change aussi dans un
  lab plat, puisque l'en-tête documente les nouvelles options. Elle est exclue du témoin A/B, et cette
  exclusion est écrite dans le témoin. Tous les verbes restent identiques octet pour octet. *Ratifiée par
  Samuel ; P57-D-03 est précisée, pas réécrite.*

### Décisions nées après la planification (2026-10-11)

Deux résiduels de l'audit de sécurité (F-1 et F-2, voir `57-SECURITY.md`) ont été soumis à Samuel, qui a
retenu l'option (a) à chaque fois : **P57-D-38 et P57-D-39, arbitrage Samuel, AskUserQuestion session
principale, 2026-10-11**.

- **P57-D-38 (casse de `.planning` en lab partitionné, F-1, option a)** : en lab partitionné seulement, le
  guard Write/Edit compare le segment `.planning` sans tenir compte de la casse, dans le préfiltre C4 et dans
  la cartographie des chemins. `<lab>/.PLANNING/workstreams/<ws>/f` est donc refusé sous le verrou d'autrui,
  comme `.planning/Workstreams/FIABILITE/f`. Le lab plat reste identique au bit près (A/B contre la copie
  gelée IDENTIQUE, témoin DLWS-03 conservé). Complète P57-D-33 (casse du nom de compartiment).
- **P57-D-39 (position du lanceur, F-2, option a)** : `driver-lock.sh` refuse avec la raison nommée
  `not-at-lab-root` quand `--ws` ou `--depot` est passé depuis un dossier sans `.planning/` propre alors que
  la racine git (`git rev-parse --show-toplevel`) porte `.planning/workstreams` ; le hint dit de lancer depuis
  la racine du lab. Nom choisi dans la série des refus existants (`ws-invalid`, `unknown-ws`,
  `partition-unreadable`, `policy-missing`, noms kebab de l'objet du défaut) : ici le défaut est la position du
  lanceur, que le nom dit sans ambiguïté, et aucun des quatre autres ne la décrit. Le guard détecte la
  partition depuis la racine git, plus depuis le cwd : un commit ou une écriture lancé d'un sous-dossier est
  jugé comme en lab partitionné (même condition : pas de `.planning/` propre au cwd). Sans `--ws` ni `--depot`,
  rien ne change ; le lab plat non plus. P57-D-29 (deux `.planning/` dans un même clone) reste hors périmètre et
  intact.

### Décisions du manager de mission (2026-10-12)

Décisions du MANAGER DE MISSION (mission « dette avant PR Phase 57 »), pas des arbitrages de Samuel : elles sont
prises dans le cadre de l'arbitrage Samuel (AskUserQuestion, session principale, 2026-10-12) de solder la dette de
la Phase 57 avant sa PR.

- **P57-D-40 (rattachement aux versions non publiées)** : les corrections rejoignent conductor v1.49.0 et
  dev-orchestrator v2.28.0, non publiées (le dernier tag `v2.69.1` porte conductor v1.48.2 et dev-orchestrator
  v2.27.1), sans nouveau bump. Précédent : `e97a4196` (entrées complétées sans bump). Aucune release dans la
  Phase 57 (P57-D-30).
- **P57-D-41 (compteurs `progress` du STATE fiabilite)** : ils incluent la Phase 57 sous le même `milestone:`
  (commit `d0a2eb23`), parce que `equipe-produit-v1.0` est inscrit sans `gsd-new-milestone` (arbitrage Samuel,
  AskUserQuestion session principale, 2026-10-08).
- **P57-D-42 (F-3 en lab partitionné seulement)** : les globaux git sans argument et `exec` sont reconnus par le
  guard en lab partitionné seulement ; le lab plat reste inchangé pour tenir l'A/B au bit près contre la copie
  gelée. L'extension au lab plat est soumise à Samuel (CONCERNS, limite a).
- **P57-D-43 (périmètre de R-5)** : en lab partitionné seulement (lab plat inchangé, comme P57-D-42), un préfixe
  `GIT_DIR=`, `GIT_INDEX_FILE=` ou `GIT_WORK_TREE=` du même segment
  que le geste git rend la cible incertaine, y compris pour la décision « geste hors du lab ». Une affectation
  dans un AUTRE segment (`export GIT_INDEX_FILE=…; git commit`) reste non couverte : limite écrite dans CONCERNS
  (limite c).

### Arbitrages du 2026-10-13

Sauf mention contraire, chaque décision est un arbitrage Samuel, AskUserQuestion session principale, 2026-10-13.

- **P57-D-44 (STATE au jalon `equipe-produit-v1.0`)** : le STATE fiabilite passe au jalon `equipe-produit-v1.0` (6 phases,
  0 terminée, 16/16 plans), commit `a6745526` (réponse A (b)). REMPLACE P57-D-41.
- **P57-D-45 (progression du watchdog)** : la progression est le commit le plus récent (`%ct`) parmi les HEAD de tous les
  worktrees du dossier git commun ; un commit futur, un worktree prunable ou illisible sont ignorés ; le git est durci
  (Q1 (b) et D (b)). Commits `f162a9c3`, `070fe50d`, `6d63fb54`, `42d490b1`, `3aa399fc`. Limite acceptée : un commit sans
  rapport peut masquer un stall, le watchdog est consultatif.
- **P57-D-46 (archivage)** : les 17 dossiers de phase de fiabilite-v1.0 sont archivés sous
  `.planning/milestones/fiabilite-v1.0-phases/` (étape `archive_phases` de gsd-cleanup), puis `--archive roadmap` ;
  la ROADMAP fait 63 Ko (Q2 (a)). Commit `4a8535ee`.
- **P57-D-47 (F-3 en lab plat, référence A/B épinglée)** : F-3 vaut aussi en lab plat ; la référence A/B est la copie gelée
  `4d48e50c` plus une empreinte versionnée de la transcription attendue des 37 formes (verdict, code de sortie, message),
  avec `seen == GW_AB_ENUM_N` (Q4 + B (b)). Commits `719099dc`, `4fd77ed3`. REMPLACE P57-D-42.
- **P57-D-48 (contournements Q5)** : fermés dans les deux régimes, R-5 compris : globaux git à argument, wrappers à
  option-argument (`env -u/-C`, `nice -n`, `exec -a`, `sudo -u`, `xargs -n`…), `bash/sh/zsh -c` (récursion bornée à 3, refus
  grossier au-delà), `GIT_*` posé dans un segment précédent (Q5). Commits `719099dc`, `4fd77ed3`. PRÉCISE P57-D-43. Lecture
  du manager : ces contournements existaient dans les deux régimes ; Samuel a ratifié sur recommandation.
- **P57-D-49 (`takeover --ws`)** : applique la règle d'`acquire` devant un ancien verrou, vivant (`a038c8b6`) comme périmé
  (`6a43299e`, même `reason` et même `hint` `recover`) ; sur un refus de la re-sonde, le verrou de compartiment antérieur est
  restitué (AU2-04) (Q5 + C (a)).
- **P57-D-50 (G-2, classe 6)** : G-2 surveille une classe 6, les fixtures (`plugin/conductor/scripts/tests/fixtures/**`,
  `scripts/tests/fixtures/**`) ; lecture en `git diff -z`, noms spéciaux compris (Q6). Commits `f76de68b`, `3e426f02`,
  `42d490b1`, `46254135`. ADR-072 amendée le 2026-10-13.
- **P57-D-51 (managers et bumps)** : les managers content, business et growth nomment la commande à exécuter par le `hint`
  d'un refus de verrou périmé ; bumps patch (Q7). Commit `576ba249`.
- **P57-D-52 (`bash -c "cd <hors-lab> && git …"`)** : passe de deny à allow, verdict de sa forme canonique. Décision du
  MANAGER DE MISSION (pas de Samuel), constatée par l'audit sans contournement.
- **P57-D-53 (tri du BACKLOG)** : reporté après la release (Q3) ; la PR part avec 31/20.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Doctrine et cahier des charges
- `docs/superpowers/specs/2026-09-15-vibeflow-head-design.md` §6 — ce que la voie workstreams exige :
  points (1) verrou nommé par workstream et amendement d'ADR-053, (2) guard aligné, (3) `--ws` et
  `GSD_SESSION_KEY` par manager, (4) preuve d'usage réel, renvoyée à la 61.
- `docs/ADR.md` § ADR-053 — l'invariant à amender (Pattern A, verrou de driver unique).
- `docs/ADR.md` § ADR-069 et son amendement du 2026-09-23 — frontière gate/workflow : un gate ne dérive
  jamais sa cible d'un export (fonde P57-D-04).
- `docs/HOOKS-CONTRAT-SORTIE.md` — contrat de sortie des hooks : décision JSON, code de garde 17 ; ADR-071,
  forme exec.
- `.planning/seeds/SEED-001-equipe-produit-v1.md` — A-09 révisé : la 57 existe parce que D-02 ne l'a pas
  livré.
- `.planning/workstreams/fiabilite/ROADMAP.md` § Phase 57 et section du jalon `equipe-produit-v1.0`.

### Code
- `plugin/conductor/scripts/driver-lock.sh` — verrou en lien symbolique vers un dossier de génération,
  mutex de récupération par génération, heartbeat et TTL, `session_ids`, registre des agents dispatchés.
  L'en-tête explique pourquoi `mkdir` seul est faux (24 acquisitions concurrentes, 5 gagnants).
- `plugin/conductor/scripts/guard-driver-lock.sh` — hook PreToolUse(Bash, Write|Edit). Règle de décision
  D-32-03, exemptions D-32-06, règles de périmètre C6/C7 (v1.45.0), clause de limite (catégories A et C).
- `plugin/planning-core/scripts/workstream-policy.sh` — `vf_ws_resolve`, à ne pas utiliser pour la cible
  (P57-D-04), et `vf_ws_enumerate`, qui valide qu'un `--ws` désigne un compartiment présent.
- `plugin/conductor/references/team-kernel.md` et `plugin/dev-orchestrator/references/mission-flow.md` —
  protocole `acquire`, `heartbeat`, `release`, `takeover`, `reclaim` côté manager.
- `plugin/conductor/references/workstream-planning-consumers.md` — recensement des consommateurs de chemins
  de planning (gate `check-planning-consumers-registered.sh`).
- `.planning/BACKLOG.md` § « guard-driver-lock.sh sous EnterWorktree vise le checkout principal » — absorbée
  pour les labs partitionnés (P57-D-08).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Mécanique d'acquisition de `driver-lock.sh`** (lien remplacé par `rename(2)`, mutex nommé d'après la
  génération observée). À réutiliser telle quelle pour chaque verrou nommé, sans la réécrire : deux
  correctifs « de fenêtre » ont été mesurés pires que l'original.
- **`VF_DRIVER_LOCK`** : la variable surcharge déjà le chemin du verrou, le guard la lit, et les suites
  l'utilisent pour des fixtures jetables.
- **`vf_ws_enumerate`** (`workstream-policy.sh`) : codes 0/2/3, refus des liens symboliques. C'est la
  validation naturelle d'un `--ws`.
- **Le patron de `check-divergence.sh`** pour le hook ancré sur `--git-common-dir` (Phase 39, après une RCE
  démontrée) : un précédent d'état partagé au niveau du clone.

### Established Patterns
- **Sortie JSON d'une ligne** ; `exit 0` pour une action réussie, `exit 1` pour un refus. Le guard rend
  toujours 0, sauf avec le code de garde 17.
- **QUAL-01** : trois issues et mutation rouge pour tout gate. Les suites du conductor portent leurs mutants
  avec un bilan codé en dur, exemple `test-check-planning-not-inflight.sh`.
- **Bash portable 3.2 et Windows (ADR-054)**, hooks en forme exec (ADR-071).
- **Promesse bornée du guard** : « une seule mission pilotée par ce harness à la fois », un garde-fou
  anti-accident, pas une exclusion mutuelle système. La 57 la reformule par compartiment sans l'élargir.

### Integration Points
- Les managers appellent `acquire --owner --step` ; ils recevront aussi `--ws` depuis le mandat du head.
- `check-mission-exit.sh` E1 attend `present:false` ; à rendre compartiment-aware.
- `.gitignore` : `.planning/DRIVER.lock*` ; l'emplacement sous `git-common-dir` est hors arbre, donc rien à
  ignorer.
- Le dépôt est lui-même partitionné (`fiabilite`, `gouvernance`), ce qui en fait le premier terrain de
  dogfooding.

</code_context>

<specifics>
## Specific Ideas

- Le JSON de `status` et d'`acquire` dit toujours **quel** verrou est en jeu (`scope: compartiment | depot`,
  `ws: <sujet>`) et **d'où** vient l'emplacement (`git-common-dir` ou repli checkout). Un humain qui lit le
  refus sait quoi relancer.
- Un refus porte la commande exacte à rejouer, comme le fait déjà le guard avec `reclaim --owner=<owner>`.

</specifics>

<deferred>
## Deferred Ideas

- **Labs plats sous `EnterWorktree`** : l'entrée BACKLOG reste ouverte pour eux (P57-D-08).
- **TTL du verrou** (1 800 s, plus court qu'un mandat de worker, constaté le 2026-08-02) : hors périmètre.
  À rouvrir sur incident.
- **Preuve d'usage concurrent réel, à deux humains** : Phase 61.

</deferred>

---

*Phase: 57-verrou-de-driver-par-compartiment*
*Context gathered: 2026-10-10*
