# Phase 57: Verrou de driver par compartiment - Research

**Researched:** 2026-10-10
**Domain:** bash portable 3.2 (verrou à lien symbolique + hook PreToolUse bash/python) — pas de dépendance externe
**Confidence:** HIGH sur le code et les suites (tout est lu et rejoué sur disque) ; MEDIUM sur Linux/CI et Windows (non mesurables ici, voir Assumptions Log)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

(copiés verbatim de `57-CONTEXT.md` § Implementation Decisions ; P57-D-01 à P57-D-11 = arbitrage Samuel, AskUserQuestion session principale, 2026-10-10)

#### Portée et fichiers partagés
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

#### Résolution du compartiment
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

#### Worktrees et emplacement
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

#### Ce que le guard bloque
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
(copié verbatim)
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

### Deferred Ideas (OUT OF SCOPE)
(copié verbatim)
- **Labs plats sous `EnterWorktree`** : l'entrée BACKLOG reste ouverte pour eux (P57-D-08).
- **TTL du verrou** (1 800 s, plus court qu'un mandat de worker, constaté le 2026-08-02) : hors périmètre.
  À rouvrir sur incident.
- **Preuve d'usage concurrent réel, à deux humains** : Phase 61.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DLWS-01 | `acquire --ws=<sujet>` pose un verrou propre au compartiment ; 2 managers/2 compartiments OK, 2/même compartiment refusés | §Architecture : un seul point d'insertion (LOCK_DIR/META recalculés après le parse) ; prototype mesuré, 24×5 acquisitions concurrentes sur 2 compartiments = 1 gagnant chacun (§Mesures M4) |
| DLWS-02 | Verrou de dépôt distinct, court, jamais 2 gestes de dépôt en même temps | Même mécanique, second emplacement `repo/` ; `--depot` explicite ; le garde est coopératif (pas d'obligation de prendre le verrou) — §Pitfalls P8 |
| DLWS-03 | Lab plat inchangé au bit près ; suites existantes vertes sans modification | Témoin A/B octet pour octet mesuré (M5) et rendu rouge par un mutant (M5b) ; 19 suites rejouées vertes sur clone (§Mesures M6) ; les nouvelles preuves vont dans des FICHIERS NEUFS |
| DLWS-04 | `--ws` explicite, jamais d'env/pointeur ; sans `--ws` → `scope: depot` + raison | `vf_ws_resolve` interdit ; `vf_ws_name_valid` + `vf_ws_dir_resolve` pour valider (§Don't Hand-Roll) |
| DLWS-05 | Emplacement sous `git rev-parse --git-common-dir`, partagé entre worktrees ; hors git → repli relatif déclaré ; guard au même endroit | Sortie relative en checkout principal / absolue en worktree (M2) → canonicaliser ; précédents `check-method-budget.sh:common_dir()` et `vf-mission-budget.snap` ; repli `.planning/DRIVER.lock.d/…` déjà couvert par `.gitignore:67` (M3) |
| DLWS-06 | Guard par compartiment, commits jugés sur l'index fail-closed, checkout/switch toujours refusés, D-32-06 inchangé | `git diff --cached --no-renames --name-only -z` (M7 : renommage, non-ASCII, index corrompu rc=128) ; piège `python … 2>/dev/null \|\| exit 0` = fail-open sur crash (§Pitfalls P3) ; 4 questions ouvertes §Open Questions |
| DLWS-07 | ADR-053 amendé, head passe `--ws`+`GSD_SESSION_KEY`, consommateurs alignés chacun vérifié | Inventaire exhaustif classé (§Consumer Inventory : 37 fichiers plugin, 0 dans scripts/.github, 5 docs) |
| DLWS-08 | Preuve de mécanisme + QUAL-01 (3 issues + mutation rouge par comportement neuf) | Protocole 24×5 réutilisé (`test-driver-lock.sh` T13/T32) ; harnais de mutants modèle `test-check-planning-not-inflight.sh:308-350` ; aucune suite existante de driver-lock/guard n'a de harnais de mutants (grep 0) |
</phase_requirements>

## Summary

`driver-lock.sh` (838 lignes, 50 512 octets) est déjà **entièrement paramétré par une seule variable** : tout chemin dérivé (dossier parent, nom de base, générations `DRIVER.lock.gen.<epoch>.<pid>`, mutex `.rec.<gen>`, liens `.new.<pid>`, journal `.events.log`, registre `.children.jsonl`) se calcule depuis `LOCK_DIR` (l. 46) et `META` (l. 48). Le changement minimal est donc **un seul bloc inséré après la boucle de parse** qui réassigne `LOCK_DIR` et `META` quand le lab est partitionné ; aucune ligne de la mécanique d'acquisition (lien remplacé par `rename(2)`, mutex nommé d'après la génération) n'est réécrite. Un prototype de 21 lignes de diff, joué sous `/bin/bash` 3.2.57 sur un clone jetable, donne : un verrou par compartiment, un verrou de dépôt indépendant, partage entre worktrees, et **exactement 1 gagnant par compartiment sur 5 tours × 24 acquisitions concurrentes**. Le même prototype rend, sur un lab plat, une sortie **identique octet pour octet** à l'original (témoin A/B qui devient rouge sous un mutant d'un champ JSON).

Le vrai travail n'est pas `driver-lock.sh` : c'est (a) le **guard** — la décision actuelle repose sur `session_ids` d'un verrou unique, il faut cartographier chemin→compartiment et index→compartiments en restant fail-closed alors que tout le script python est enveloppé dans `2>/dev/null || exit 0` — et (b) **six consommateurs de code** qui lisent « le » verrou à un chemin fixe et deviendraient silencieusement aveugles dans un lab partitionné (`check-branch-claim.sh` rend SAIN, le watchdog Phase 33 ne voit plus de STALL/ABANDON, `dag.sh mark-progress` n'avance plus rien et fabrique de faux STALL, E1 ne voit plus aucun verrou). Trois points ne sont pas tranchés par le CONTEXT et pèsent sur le design : le sort des gestes Bash autres que `commit`/`checkout`/`switch` (`push`, `reset`, `rebase`, `gh pr`…), la lecture de « dans le même checkout » (P57-D-11) qui impose de comparer `meta.worktree`, et le fait que les managers d'une même session partagent `CLAUDE_CODE_SESSION_ID` (le guard ne peut donc pas les séparer ; il isole des **sessions**, pas des managers).

**Primary recommendation :** insérer un unique bloc de résolution dans `driver-lock.sh` (emplacement `<git-common-dir>/vf-driver/{ws/<sujet>,repo}/DRIVER.lock`, un dossier par verrou pour que les noms dérivés ne puissent jamais se télescoper), paramétrer chaque verbe par `--ws`/`--depot`, ajouter `status --all` pour les consommateurs, ne **jamais** modifier les suites `test-driver-lock.sh` / `test-guard-driver-lock.sh` (preuves neuves dans des fichiers neufs), garder les prompts d'agents à instructions constantes (baseline du budget : `vf-dev-manager.md` est à 250 lignes / 46 instructions) en déportant le protocole dans `mission-flow.md`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Mutex d'acquisition par compartiment / dépôt | Script kernel (`driver-lock.sh`) | — | Mécanique mesurée (lien + `rename(2)` + mutex de génération) : on la paramètre, on ne la touche pas |
| Détection « lab partitionné » + validation de `--ws` | Planning-core (`workstream-policy.sh`, sourcé) | `driver-lock.sh` (appelant) | Politique unique de nom (en-tête de `workstream-policy.sh` : quatre copies avaient déjà divergé) |
| Emplacement des verrous (clone) | Git (`--git-common-dir`) | `driver-lock.sh`, guard | État partagé entre worktrees ; précédents Phase 39/40 |
| Refus d'écriture/commit par compartiment | Hook PreToolUse (`guard-driver-lock.sh`, bash+python) | `driver-lock.sh` (écrit le meta lu) | Garde-fou anti-accident, pas anti-adversaire (clause de limite du guard) |
| Gestes de dépôt (release, BACKLOG, ADR) | Convention d'agent (acquire explicite du verrou de dépôt) | Guard (refuse seulement si tenu par autrui) | Aucun mécanisme n'oblige à prendre le verrou de dépôt avant d'écrire |
| Lecture d'état (watchdog, E1, claim de branche) | Scripts consommateurs (`check-*.sh`) | `driver-lock.sh status --all` | Un seul lecteur de JSON ; pas de parse du meta à la main ailleurs |
| Passage de `--ws` + `GSD_SESSION_KEY` aux managers | Head (`vibeflow-head`, dev-orchestrator) | Prompts managers / `mission-flow.md` | Le mandat porte déjà le sujet (`intent-routing.md`, CHANGELOG dev-orchestrator l. 11-12) |
| Doctrine de l'invariant | `docs/ADR.md` (ADR-053 amendé) | `head-governance.md`, `team-kernel.md`, `mission-cross-team.md` | Source de vérité + trois références qui répètent l'ancien invariant |

## Standard Stack

### Core
| Outil | Version mesurée | Purpose | Why Standard |
|-------|-----------------|---------|--------------|
| bash | 3.2.57 (`/bin/bash`, macOS) ; CI = bash 5 (ubuntu) | `driver-lock.sh`, prototype, suites | ADR-054 : bash portable 3.2. Prototype et A/B joués sous 3.2.57 [VERIFIED: `/bin/bash --version` → `GNU bash, version 3.2.57(1)-release`] |
| git | 2.50.1 (Apple Git-155) | `rev-parse --git-common-dir`, `diff --cached` | Seul moyen d'obtenir le dossier commun d'un clone ; précédents du dépôt |
| python3 | 3.14.6 | corps du guard (un seul spawn) | `vf_resolve_python --fast` déjà en place |
| jq | 1.7.1-apple | consommateurs (E1) | déjà requis par `check-mission-exit.sh` |

### Supporting
| Fichier | Purpose | When to Use |
|---------|---------|-------------|
| `plugin/planning-core/scripts/workstream-policy.sh` (375 l.) | `vf_ws_enumerate` (détection), `vf_ws_name_valid`, `vf_ws_dir_resolve` (validation) | SOURCÉ, jamais exécuté ; cascade `$(dirname "$0")/workstream-policy.sh` puis `$(dirname "$0")/../../planning-core/scripts/workstream-policy.sh` (comme `check-planning-not-inflight.sh:77-78`) |
| `plugin/_internal/lib/vf-portable.sh` | locator + `vf_guard_unavailable` du guard | bloc canonique l. 94-130 du guard, vérifié par somme de contrôle (`test-vf-portable.sh` T12) : ne pas le retaper |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Un dossier par verrou (`vf-driver/ws/<sujet>/DRIVER.lock`) | Verrous frères à noms préfixés (`ws.<sujet>`) dans un seul dossier | Les noms dérivés (`<base>.gen.*`, `<base>.rec.*`, `<base>.events.log`, `<base>.children.jsonl`) se télescopent si un sujet s'appelle `x.events.log` ou `y.gen.1.2` (`vf_ws_name_valid` autorise les points). Un dossier par verrou garde `LOCK_BASE=DRIVER.lock` partout |
| `vf_ws_enumerate` pour valider `--ws` | `vf_ws_name_valid` + `vf_ws_dir_resolve` | `vf_ws_enumerate` émet 1 chemin par ligne et BACKLOG.md l. 909-945 documente deux défauts ouverts (nom à saut de ligne invisible ; `found=1` même si `cd` échoue). On garde `vf_ws_enumerate` **pour la détection** (rc 0/2/3) seulement |

**Installation :** aucune. Aucun paquet externe n'est installé par cette phase.

## Package Legitimacy Audit

Aucun paquet externe installé (bash, git, python3, jq déjà requis par le dépôt). Section sans objet ; `gsd-tools query package-legitimacy` non lancé (rien à vérifier).

## Architecture Patterns

### System Architecture Diagram

```
 head (vibeflow-head) ── mandat : sujet X ──► manager (vf-*-manager)
                                              │  acquire --owner --step --ws=X     (verrou de compartiment)
                                              │  acquire --owner --step --depot    (geste de dépôt, court)
                                              ▼
                     driver-lock.sh  ── parse args ──► [BLOC NEUF : résolution]
                                              │            │
                       VF_DRIVER_LOCK posé ───┤            ├─ lab plat (vf_ws_enumerate rc=3) ─► LOCK_DIR=.planning/DRIVER.lock  (inchangé)
                       (fixtures, legacy forcé)│            ├─ rc=2 (illisible) ─► REFUS nommé (fail-closed)
                                              │            └─ rc=0 partitionné :
                                              │                 --ws=X valide ? (name_valid + dir_resolve) ─ non ─► REFUS unknown-ws
                                              │                 git rev-parse --git-common-dir ─ ok ─► <common>/vf-driver/ws/X/DRIVER.lock
                                              │                                              └ échec ─► repli .planning/DRIVER.lock.d/ws/X/…  (+ "location": "checkout")
                                              │                 sans --ws / --depot ─► <common>/vf-driver/repo/DRIVER.lock  (scope: depot)
                                              │                 .planning/DRIVER.lock vivant (legacy) ─► vaut verrou de dépôt (P57-D-14)
                                              ▼
                       mécanique INCHANGÉE : new_generation → ln_atomic → rename(2) → mutex .rec.<gen>
                                              │
        ┌─────────────────────────────────────┴──────────────────────────────────────────────┐
        ▼                                                                                    ▼
 guard-driver-lock.sh (PreToolUse Bash|Write|Edit)                       consommateurs (SessionStart / gates)
   sonde bash pure (lab plat : sortie 0 comme aujourd'hui)                 status --all ► check-guard-health (STALL/ABANDON)
   chemin .planning/workstreams/<A>/… ► verrou(A)                          status --ws  ► check-mission-exit E1 (+cur_lock_gen)
   chemin racine .planning/…          ► verrou de dépôt (+legacy)          locks/*      ► check-branch-claim (claim de branche)
   commit ► git diff --cached --no-renames --name-only -z  (fail-closed)   dag.json.ws  ► dag.sh mark-progress
   checkout/switch/arbre ► refus si verrou d'autrui, MÊME worktree
   décision : JSON permissionDecision:deny, exit 0 (sauf 17)
```

### Recommended Project Structure
```
<git-common-dir>/vf-driver/            # hors arbre : rien à ignorer, E2 reste propre
├── ws/<sujet>/DRIVER.lock             # lien → DRIVER.lock.gen.<epoch>.<pid>/  (meta)
│            /DRIVER.lock.gen.*/       # générations, mutex .rec.*, .events.log, .children.jsonl : frères du lien
└── repo/DRIVER.lock                   # verrou de dépôt (même structure)
.planning/DRIVER.lock.d/{ws/<sujet>,repo}/…   # REPLI hors git (couvert par .gitignore:67 `.planning/DRIVER.lock*`)
.planning/DRIVER.lock                  # lab plat (inchangé) ; en lab partitionné : verrou LEGACY = verrou de dépôt tenu (P57-D-14)
```
Le nom `vf-driver` est un **choix de planificateur** ; P57-D-07 marque l'emplacement « costly » à déplacer : à faire ratifier (Open Question Q11).

### Pattern 1 : un seul point d'insertion
**What :** après la boucle `for arg` (l. 53-71) et avant `LOCK_PARENT=` (l. 154), réassigner `LOCK_DIR` et `META`. Tout le reste (`LOCK_PARENT`, `LOCK_BASE`, `REG`, mutex, journal) se recalcule seul.
**Preuve :** `LOCK_DIR="${VF_DRIVER_LOCK:-.planning/DRIVER.lock}"` (l. 46) et `META="$LOCK_DIR/meta"` (l. 48) sont les deux seules assignations ; `LOCK_PARENT="$(dirname "$LOCK_DIR")"` (l. 154), `LOCK_BASE="$(basename "$LOCK_DIR")"` (l. 155), `REG="${VF_DRIVER_CHILDREN:-$LOCK_PARENT/${LOCK_BASE}.children.jsonl}"` (l. 361), `mutex="${LOCK_DIR}.rec.…"` (l. 553, 619, 731), `"${LOCK_DIR}.new.$$"` (l. 581, 587, 600), `log_path="$LOCK_PARENT/${LOCK_BASE}.events.log"` (l. 324), `gen="${LOCK_BASE}.gen.${ts}.$$"` (l. 235) en dérivent [VERIFIED: `rtk proxy grep -n` sur driver-lock.sh, sortie citée en §Mesures M1].
**Garde bit-exact :** ne sourcer `workstream-policy.sh` et n'appeler `git` **que si** `VF_DRIVER_LOCK` est vide ET `.planning/workstreams` existe ; un lab plat n'exécute pas une instruction de plus.

### Pattern 2 : `VF_DRIVER_LOCK` posé = mode « verrou unique » forcé (recommandé)
Toutes les suites existantes exportent `VF_DRIVER_LOCK="$WORK_DIR/DRIVER.lock"` (`test-driver-lock.sh` l. 46-48 de la suite : `export VF_DRIVER_LOCK="$WORK_DIR/DRIVER.lock"`, `test-guard-driver-lock.sh` : `export VF_DRIVER_LOCK="$LOCK"`) et font `cd "$(dirname "$0")/../.."` = `plugin/conductor` **à l'intérieur du vrai dépôt partitionné**. Sans la règle « `VF_DRIVER_LOCK` posé ⇒ comportement historique », la détection de partition par remontée git ferait basculer ces suites dans le nouveau régime. Conséquence : E1 de `check-mission-exit.sh` (qui exporte `VF_DRIVER_LOCK="$ROOT/.planning/DRIVER.lock"`, l. 240) doit **cesser** de l'exporter en lab partitionné (Q7).

### Pattern 3 : grammaire des verbes (`--ws`, `--depot`)

| Verbe | Verrou visé en lab partitionné | JSON (champs ajoutés **uniquement** en partitionné) |
|---|---|---|
| `acquire` | `--ws=X` → compartiment X ; `--depot` ou rien → dépôt (P57-D-05) ; refus si legacy vivant | `scope`, `ws`, `location` |
| `takeover`, `reclaim`, `heartbeat`, `mark-progress`, `release`, `recover` | même résolution que `acquire` ; sans `--ws` : dépôt, **puis** legacy si le dépôt est absent et le legacy présent (continuité d'un manager en vol, P57-D-14) | idem |
| `status` | `--ws=X` : ce verrou ; rien : dépôt (+ `legacy_lock`) ; **`--all`** : `{"present": <any>, "scope": "lab", "locks": [ … un objet status par verrou … ], "children_running": <somme>}` | idem |
| `register`, `close`, `orphans` | registre **frère du verrou résolu** (déjà le cas : `$LOCK_PARENT/${LOCK_BASE}.children.jsonl`). `VF_DRIVER_CHILDREN` (chemin unique) est incompatible avec N registres : l'honorer seulement avec `VF_DRIVER_LOCK` | idem |

Refus : raisons fermées proposées `unknown-ws`, `ws-invalid`, `legacy-lock-held`, `partition-unreadable`, `policy-missing`, chacune avec le champ `hint` portant la **commande exacte à rejouer** (CONTEXT § Specifics ; modèle : le `hint` de `stale-requires-takeover`, l. 530).

### Pattern 4 : sort d'un `.planning/DRIVER.lock` tenu à la mise à jour (P57-D-14)
**Mesuré :** `plugin/_internal/vibeflow-update.sh` ne contient **aucune** occurrence de `driver` (`rtk proxy grep -n -i 'driver\|\.planning'` : 0 ligne `driver`, seulement `.planning/config.json`). L'engine ne touche jamais un verrou : un verrou posé reste sur disque et les nouveaux scripts remplacent les anciens sous les pieds du manager en vol. Cas réel aujourd'hui : le dépôt est partitionné ET tient un verrou plat vivant (`driver-lock.sh status` → `"owner": "vf-dev-manager-plan57"`, lien `.planning/DRIVER.lock -> DRIVER.lock.gen.1791642955.29449`).
**Règle recommandée :** (1) en lab partitionné, tout `acquire` (compartiment ou dépôt) **refuse** `legacy-lock-held` tant que `.planning/DRIVER.lock` existe et n'est pas périmé, `hint` = `VF_DRIVER_LOCK=.planning/DRIVER.lock <script> release --owner=<owner>` (donc **aucun verbe neuf**) ; (2) périmé → `stale-requires-takeover` avec le `hint` correspondant, jamais de reprise silencieuse ; (3) les verbes `heartbeat/release/mark-progress/status` du détenteur, appelés sans `--ws`, retombent sur le legacy (sinon le manager en vol reçoit `no-lock` en pleine mission) ; (4) le guard traite le legacy vivant comme un verrou de dépôt ; (5) `status` expose `legacy_lock`.

### Anti-Patterns to Avoid
- **Réécrire l'acquisition** : l'en-tête (l. 15-17) dit « deux correctifs de fenetre ont ete mesures PIRES que l'original (8 et 6 gagnants) ». On paramètre, on ne retouche pas.
- **Déduire le sujet d'un export** : `vf_ws_resolve` est exclu (P57-D-04, amendement ADR-069 2026-09-23).
- **Copier la politique de nom dans le guard** : l'en-tête de `workstream-policy.sh` documente quatre copies qui ont divergé. Le guard ne valide pas un nom, il **cartographie** un segment de chemin et cherche le verrou homonyme ; segment hors politique → traité comme fichier racine (verrou de dépôt).
- **Modifier `test-driver-lock.sh` / `test-guard-driver-lock.sh`** : toute diff sur ces deux fichiers affaiblit le témoin de DLWS-03.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Atomicité d'acquisition par compartiment | un nouveau mutex / `flock` / `mkdir` | le lien + `rename(2)` + mutex de génération existants, sur un `LOCK_DIR` différent | mesuré : `mkdir` seul = jusqu'à 5 gagnants sur 24 ; deux correctifs de fenêtre = 8 et 6 |
| Validation d'un nom de sujet | regex locale | `vf_ws_name_valid` + `vf_ws_dir_resolve` (refuse les liens, ne suit jamais) | politique unique ; prototype : `--ws=../x` refusé |
| Détection « lab partitionné » | `[ -d .planning/workstreams ]` seul | `vf_ws_enumerate` rc 0/2/3 | le test nu ignore le lien symbolique et le fichier régulier (ADR-069 amendement : cas encore ouvert) |
| Dossier commun du clone | `dirname "$(git rev-parse --git-dir)"` | `git rev-parse --git-common-dir` canonicalisé par `cd … && pwd -P` | `--git-dir` d'un worktree = `.git/worktrees/<n>` (M2) |
| Liste des fichiers indexés | `git diff --cached --name-only` nu | `git diff --cached --no-renames --name-only -z` | M7 : sans `--no-renames` la source d'un renommage disparaît ; sans `-z` les noms non-ASCII sortent quotés (`"\303\251.txt"`) |
| Harnais de mutants | un nouveau format | le helper `mutant()` de `test-check-planning-not-inflight.sh:308-350` (ancre unique par `grep -c`, `cmp -s`, `bash -n`, ensemble attendu exact, témoin préalable, bilan codé en dur `-eq 9`) | convention QUAL-01 du dossier |
| Tests de concurrence | un nouveau protocole | T13 (`test-driver-lock.sh` l. 215-232) et T32 (l. 407-422) : N=24 × 5 tours | exigé par P57-D-12 |

**Key insight :** tout ce qui est difficile (atomicité, validation de nom, dossier commun, concurrence) existe déjà et est mesuré. La phase est de la **résolution de chemin + cartographie de décision**, pas de la concurrence neuve.

## Consumer Inventory (P57-D-15, DLWS-07)

Commande de départ (fait foi) : `rtk proxy grep -rln 'DRIVER\.lock\|driver-lock\.sh\|VF_DRIVER_LOCK' plugin scripts .github | sort` → **37 fichiers**, tous sous `plugin/` ; **0 sous `scripts/`**, **0 sous `.github/`** (la CI découvre les suites par `find plugin scripts -type f -path '*/tests/test-*.sh'`, `ci.yml:218` : une suite neuve est jouée sans toucher `ci.yml`). Séparément : `docs/` = 5 fichiers ; `.claude/` = 6 fichiers `agent-memory/` + 5 worktrees liés (copies périmées de `plugin/`, gitignorés `.gitignore:24`) ; `.gitignore:67` = `.planning/DRIVER.lock*`.

### Classe A — CODE à modifier (6)
| Fichier (hits) | Ce qui est câblé en dur | Changement | DLWS |
|---|---|---|---|
| `plugin/conductor/scripts/driver-lock.sh` (18) | l. 46/48 (voir Pattern 1) | bloc de résolution + `--ws`/`--depot`/`status --all` | 01,02,04,05 |
| `plugin/conductor/scripts/guard-driver-lock.sh` (9) | l. 79 `[ -e "${VF_DRIVER_LOCK:-.planning/DRIVER.lock}" ] \|\| exit 0` ; l. 464 `lock_raw = os.environ.get("VF_DRIVER_LOCK", ".planning/DRIVER.lock")` | sonde bash étendue, cartographie, jugement d'index | 05,06 |
| `plugin/conductor/scripts/check-branch-claim.sh` (4) | l. 45 `LOCK_DIR="${VF_DRIVER_LOCK:-.planning/DRIVER.lock}"`, l. 100 `if [ ! -d "$LOCK_DIR" ]; then` → « SAIN — aucun lock de driver actif » | parcourir les verrous du clone ; **sinon faux SAIN** en lab partitionné | 07 |
| `plugin/conductor/scripts/check-guard-health.sh` (11) | `check_driver_stall()` : `out="$("$DRIVER_LOCK_SH" status 2>/dev/null)"` nu (l. 208) ; contrat « au plus DEUX lignes au total » | `status --all`, une ligne par famille ; **sinon STALL/ABANDON de la Phase 33 muets** | 07 |
| `plugin/conductor/scripts/dag.sh` (4) | `record_progress()` (l. 189) : `[driver_lock_sh, "status"]` (l. 204) puis `"mark-progress", f"--owner={owner}"` (l. 214) | lier le DAG à un sujet (`ws` additif dans `<mission>.dag.json`, lecture tolérante P-02) ; **sinon `progress_epoch` n'avance plus et 33-03 fabrique de faux STALL** | 07 |
| `plugin/dev-orchestrator/scripts/check-mission-exit.sh` (11) | l. 240 `VF_DRIVER_LOCK="$ROOT/.planning/DRIVER.lock" … status` ; l. 193 `cur_lock_gen()` lit `$ROOT/.planning/DRIVER.lock` (identité de mission du snapshot E7) | `--ws` explicite (E1 **et** `cur_lock_gen`) ; absent en lab partitionné → `indet`, jamais un vert | 07 |

### Classe B — PROMPTS / RÉFÉRENCES porteurs de protocole (12)
| Fichier (hits) | État mesuré | Changement |
|---|---|---|
| `plugin/dev-orchestrator/agents/vf-dev-manager.md` (7) | **250 lignes / 46 instructions = baseline exacte** (`check-instruction-budget.sh`) ; l. 48 acquire, 51 register, 52 heartbeat, 250 release | `--ws` à **instructions constantes** (réécrire, pas ajouter) ; protocole dans `mission-flow.md` |
| `plugin/design-orchestrator/agents/vf-design-manager.md` (4) | 196 l. / 30 instr (baseline 192/30) | idem |
| `plugin/business-pilot-bundle/agents/vf-business-manager.md` (2) | 183 / 21 | idem |
| `plugin/content-bundle/agents/vf-content-manager.md` (2) | 151 / 14 | idem |
| `plugin/growth-bundle/agents/vf-growth-manager.md` (2) | 172 / 25 (baseline 167/25) | idem |
| `plugin/dev-orchestrator/agents/vf-coder.md` (1) | l. 85 `register` ; 146 l. / 22 instr (baseline 23) | le worker a `--ws` dans son mandat (`vf-dev-manager.md:122`) |
| `plugin/dev-orchestrator/agents/vf-reviewer.md` (1) | l. 37 `register` ; 87 l. | idem |
| `plugin/dev-orchestrator/references/mission-flow.md` (16) | 732 l. ; l. 44/53/70/80/91 verbes ; 538-617 registre | **lieu du protocole** `--ws`/`--depot`, `GSD_SESSION_KEY` |
| `plugin/conductor/references/team-kernel.md` (5) | l. 18 « une seule mission pilote à la fois » ; l. 252-262 « SEUL garant machine » ; §Jeton de fence l. 272-300 | invariant par compartiment ; fence = `status --ws=<X>` |
| `plugin/dev-orchestrator/references/head-governance.md` (2) | l. 93-107 « **Extension non livrée — un manager par workstream** » énumère exactement les 4 prérequis | réécrire : livrée (mécanisme) par la 57, usage réel = Phase 61 |
| `plugin/dev-orchestrator/references/mission-cross-team.md` (3) | l. 19, 86, 102 : « Un seul verrou de driver… garantie machine de dernier ressort de l'invariant « un seul manager actif » », chaîne `manager → worker → manager` fermée par le lock | **faux par compartiment** (voir Q6) |
| `plugin/conductor/references/workstream-planning-consumers.md` (1) | l. 88 : `guard-driver-lock.sh` classé **hp** (« deux commentaires d'exemple (l. 37 et 87) ») | ligne réécrite si le guard porte le littéral `.planning/workstreams` ; lignes neuves pour tout script que le lint détecte (voir Pitfall P7) |

### Classe C — documentation seule / historique (8 dans les 37 + 5 fichiers `docs/`)
READMEs (conductor 6, dev-orchestrator 3, business/content/growth 1 chacun) : mentions descriptives, à aligner à la livraison ; CHANGELOGs (conductor 18, dev-orchestrator 4, design-orchestrator 1) : entrées **neuves** seulement, jamais de réécriture ; `docs/ADR.md` (5 hits : ADR-053 amendé, autres inchangés), `docs/HOOKS-CONTRAT-SORTIE.md` (4 : entrée #27 inchangée, compte 31 inchangé — **hooks.json non modifié**), `docs/superpowers/specs/2026-09-15-vibeflow-head-design.md` (6 : §6 devient historique — note datée, le texte « vibeflow-os n'est pas partitionné » est déjà faux depuis la PR #94), deux autres specs (aucun changement).

### Classe D — aucune modification (2 des 37 + entrées hors périmètre de la commande)
`plugin/conductor/hooks/hooks.json` (l. 14 : la même entrée #27 `Bash|Write|Edit`, forme exec ADR-071 ; le script lit `tool_name`), `plugin/conductor/scripts/check-legacy.sh` (liste de noms de fichiers), `.claude/agent-memory/*` (mémoire d'agent), `.claude/worktrees/*` (copies de branches).

### Classe E — suites existantes (fixtures), à garder vertes SANS modification (9 fichiers)
`test-driver-lock.sh` (129 hits), `test-guard-driver-lock.sh` (18), `test-dag.sh` (43), `test-check-guard-health.sh` (70), `test-check-mission-exit.sh` (26), `test-check-legacy.sh` (1), `test-notify.sh` (1), `test-design-orchestrator.sh` (2 : cherche les mots `driver-lock.sh` et `release` dans le prompt du design-manager), `plugin/_internal/tests/test-vf-portable.sh` (4 : somme de contrôle du bloc locator du guard). **Compte :** A=6, B=12, C(plugin)=8 (5 README + 3 CHANGELOG), D(plugin)=2 (`hooks.json`, `check-legacy.sh`), E=9 → 6+12+8+2+9 = 37 ✓.

### Verbes et consommateurs vérifiés un par un
- **`status`** : JSON actuel (clés exactes, l. 469) `present, owner, step, age_seconds, ttl, stale, generation, session_ids, lease_seconds, guard_effective, progress_epoch, progress_age_seconds, children_running` ; branche absente : `{"present": false, "lock": "%s", "children_running": N}` (l. 448). Le lock absent ne porte pas `generation`.
- **Watchdog/heartbeat Phase 33** : `mark-progress` n'avance que `progress_epoch` (jamais `heartbeat_epoch`) ; `check-guard-health.sh` croise `ttl` de `status` avec `STALL_WINDOW` (900 s < 1800 s) : `status --all` doit **conserver `ttl` par verrou**.
- **`check-branch-claim.sh`** : sorties 0 (signal) / 3 (SAIN) / 4 (INDÉTERMINÉ) / 64 ; compare `meta.worktree` normalisé `pwd -P` ; en lab partitionné avec verrous au clone, il devient **plus utile** (claim d'un autre worktree) mais lit aujourd'hui `.planning/DRIVER.lock` du worktree courant → toujours « absent » → SAIN.
- **Managers qui appellent `acquire`** : vf-dev (l. 48), vf-design (l. 49), business (l. 59), content (l. 41), growth (l. 44). Les workers (`vf-coder`, `vf-reviewer`, `vf-auditer`, `vf-crafter`, `vf-design-judge`) n'acquièrent jamais ; seuls `register` (coder, reviewer) les concerne.
- **Head** : le mandat porte le sujet (`plugin/dev-orchestrator/CHANGELOG.md:11-12` : « Le sujet X est passé explicitement dans le mandat de l'équipe dispatchée (P412-D-10) ») ; ni `AGENT.md` (209 l./33 instr, baseline identique) ni `skills/vf-dev/SKILL.md` ne mentionnent `--ws`. Le texte du manager l. 121-123 porte déjà « `--ws <nom>` … `GSD_SESSION_KEY` distinct par mandat dès que ≥ 2 workers concurrents » pour les **workers**. Note : P412-D-10 est, dans `split-planning.sh:31,239,292`, la décision « sujet par défaut » ; la citation du CONTEXT renvoie en réalité à la ligne de CHANGELOG ci-dessus.

## Runtime State Inventory

(Phase de **migration partielle de l'emplacement d'un état runtime** : les cinq catégories sont répondues.)

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | Verrou plat vivant `.planning/DRIVER.lock` (lien → `DRIVER.lock.gen.1791642955.29449`), `DRIVER.lock.children.jsonl`, `DRIVER.lock.events.log` dans le vrai dépôt [VERIFIED : `ls -la .planning`] | Règle P57-D-14 (Pattern 4) ; **ne pas** migrer les données : le legacy se relâche à sa fin de vie ; aucun script de migration |
| Live service config | Aucune — pas de service externe | None — vérifié par grep de `driver-lock` dans `.github/` (0 hit) |
| OS-registered state | Aucune tâche planifiée référençant le verrou ; le hook est dans `hooks.json` du plugin (forme exec posée à l'install) | None — `hooks.json` inchangé, donc pas de réinstallation de hook |
| Secrets/env vars | `VF_DRIVER_LOCK`, `VF_DRIVER_TTL`, `VF_DRIVER_SESSION_MAX`, `VF_DRIVER_CHILDREN`, `VF_DRIVER_LOCK_OVERRIDE`, `VF_DRIVER_TEST_DIE_AFTER_MUTEX` | `VF_DRIVER_LOCK` : sémantique à fixer (Q7) ; `VF_DRIVER_CHILDREN` : incompatible N registres ; les autres inchangées |
| Build artifacts | Scripts copiés **à plat** dans `.claude/scripts/` par `copy_module_scripts` ; un manager en vol utilise le script remplacé à chaud | Documenter dans le CHANGELOG conductor ; c'est la raison du fallback legacy des verbes sans `--ws` |

## Common Pitfalls

### P1 : `grep -q` dans un pipeline sous `pipefail` = faux négatif (MESURÉ pendant cette recherche)
**What goes wrong :** mon premier prototype validait `--ws` par `vf_ws_enumerate | while … | grep -q ok` ; `grep -q` sort au premier succès, le producteur reçoit SIGPIPE, `pipefail` (le script déclare `set -uo pipefail`) fait échouer le pipeline : `fiabilite` (1ᵉʳ en ordre alphabétique) était refusé `unknown-ws` alors que `gouvernance` (dernier) passait. Un test qui n'essaie que le dernier compartiment serait vert.
**How to avoid :** capturer la liste dans une variable, boucler en shell (here-document), aucun pipe vers `grep -q`. **Test :** exercer le 1ᵉʳ ET le dernier compartiment (≥ 2).

### P2 : les suites existantes tournent DANS le vrai dépôt partitionné
`cd "$(dirname "$0")/../.."` = `plugin/conductor`, dépôt réel. Toute suite neuve qui oublie de `cd` dans sa fixture résoudrait le **vrai** `--git-common-dir` et écrirait dans `.git/vf-driver/` du dépôt (où un verrou vivant existe). **Garde :** préflight de chaque suite neuve — `git rev-parse --git-common-dir` du cwd doit être sous `$WORK_DIR`, sinon abandon avant toute écriture. Même risque pour `driver-lock.sh` lancé à la main depuis un sous-dossier.

### P3 : le guard est fail-open sur crash
Tout le python est lancé `printf '%s' "$INPUT" | vf_python -c '…' 2>/dev/null || exit 0` (l. 142 et 548). Un `NameError`/`subprocess.TimeoutExpired` dans le code neuf = **allow silencieux**, c'est-à-dire l'inverse de P57-D-10. Le jugement d'index doit être enveloppé dans son propre `try/except BaseException` qui **émet le deny** (`permissionDecision: deny`) et jamais ne laisse remonter. Test : rendre `git` introuvable / index corrompu (M7 : rc=128) et exiger le deny, **plus** un mutant « except → exit 0 » qui doit rougir.

### P4 : `--cached` ne voit pas tout ce qu'un commit embarque
M7 : `git commit -a` (ou `-am`, `--only`, `-i`, pathspec, `--amend` sans changement indexé) commite des fichiers **absents de l'index** au moment du hook (`index:[]  worktree-vs-index:[…A/STATE.md…]`). Un commit `-a` dans le compartiment A passerait sous un verrou d'A tenu par autrui. P57-D-10 est verrouillé sur `--cached` : l'extension (union avec `git diff --name-only` quand la commande porte `-a`/`--all`/pathspec) est compatible mais non arbitrée → Q4.

### P5 : les managers d'une même session partagent `CLAUDE_CODE_SESSION_ID`
Mesuré dans cette session : les verrous m1 (fiabilite), m2 (gouvernance), m4 (dépôt) du prototype portent tous `"session_ids": ["cfd39ff1-824b-4682-92d9-903f07df626e"]`. Le guard décide par `payload.session_id ∈ meta.session_ids` (règle 3, l. 523) et son en-tête le dit (l. 18-19 : les sous-agents « PARTAGENT le session_id de leur session parente ») ; `GSD_SESSION_KEY` est une variable d'environnement du moteur GSD (`workstream-flag.md:41`), invisible du payload du hook. Donc : **deux managers lancés par un même head ne s'isolent pas par le guard** (D-32-03(e) : « jamais qu'aucun autre acteur DE LA MÊME session »). Ce que P57-D-09 isole, ce sont des **sessions distinctes** (deux humains, deux terminaux). À écrire dans l'amendement d'ADR-053 (Q5).

### P6 : « même checkout » (P57-D-11) impose de comparer `meta.worktree`
Aujourd'hui le verrou est un fichier **du checkout** : « le même checkout » est implicite. Avec des verrous au clone, un verrou d'autrui tenu depuis le worktree W1 refuserait `checkout`/`switch`/`reset`/`rebase` dans W2 si la règle est « refus quel que soit le compartiment » sans condition de worktree : le parallélisme de deux worktrees (la raison d'être de la phase) serait tué par `git rebase main`. Le meta porte déjà `worktree=` (`new_generation`, l. 242) et `check-branch-claim.sh` compare déjà `pwd -P`. Lecture recommandée de « dans le même checkout » : refus si un verrou d'autrui a `meta.worktree` égal au `--show-toplevel` courant → Q2.

### P7 : le lint de recensement s'applique aux littéraux `.planning/workstreams`
`check-planning-consumers-registered.sh` (rc=0 aujourd'hui : « 122 .sh suivi(s) hors tests/ balayé(s), 23 consommateur(s) détecté(s), tous recensés ») rougit sur tout `.sh` hors `tests/` portant `.planning/workstreams` ou `.planning/{STATE,ROADMAP,REQUIREMENTS}.md` sur la même ligne — **commentaires inclus**. `driver-lock.sh` n'est pas recensé aujourd'hui (aucun littéral) ; le guard est recensé **hp** pour « deux commentaires d'exemple ». Dès que l'un écrit `.planning/workstreams` (même en commentaire) : ligne de recensement à ajouter/réécrire dans le même commit. Astuce honnête : composer le chemin (`".planning"` + `"workstreams"`) évite le littéral mais n'enlève pas le consommateur — préférer l'inscrire.

### P8 : le verrou de dépôt est coopératif
P57-D-09 : un fichier racine n'est refusé que « si le verrou de dépôt est tenu par autrui ». Personne n'est obligé de le prendre avant d'écrire. Et le guard Write/Edit ne regarde que `.planning/` (`re.search(r"(^|/)\.planning/", norm)` l. 449) : `docs/ADR.md`, `VERSION`, `plugin.json`… ne sont protégés **que par le jugement de commit** (D-10). La liste des « fichiers communs » hors `.planning/` n'est définie nulle part → Q3.

### P9 : trois dérives de nommage de sujet
`vf_ws_name_valid` autorise les points (`a.b`), `..` est refusé en sous-chaîne (M1 : `--ws=../x` → refusé, affiché `..x` après `tr -dc`). Un sujet nommé `depot`/`repo` ne collisionne pas (dossiers `ws/…` vs `repo/`). Mais deux `.planning/` dans un même clone (lab en sous-dossier) partageraient `vf-driver/ws/<même nom>` : faux « held » inter-labs (Q12, risque faible, atténuable par un préfixe `git rev-parse --show-prefix`).

### P10 : bit-exact ≠ « les tests passent »
`assert` des suites existantes sont des tests de **sous-chaîne** (`[[ "$2" == *"$3"* ]]`) : ajouter un champ JSON en lab plat les laisserait vertes. D'où le témoin A/B octet pour octet (M5) — obligatoire en plus des suites inchangées.

### P11 : sous Windows / Linux rien n'est mesuré ici
`--git-common-dir` rend un chemin `C:/…` côté git, `/c/…` après `pwd -P` côté MSYS ; le guard (python natif) et `driver-lock.sh` (bash MSYS) ne doivent **jamais comparer ces chaînes entre elles** (chacun résout par lui-même). Aucun runner Windows n'existe (`ci.yml:2207-2210`). `[ASSUMED]`.

### P12 : git durci pour le guard
Le guard va lancer `git diff --cached` dans un dépôt dont la config est du contenu non maîtrisé. Précédent du dépôt : `check-mission-exit.sh:154-156` → `git -C "$ROOT" -c core.fsmonitor= -c core.hooksPath=/dev/null --no-optional-locks "$@"`. Reprendre à l'identique. `GIT_OPTIONAL_LOCKS=0` est déjà exporté par ce gate (l. 151).

## Code Examples

### Bloc de résolution (prototype joué sous bash 3.2.57 ; diff = 21 lignes vs l'original)
```bash
# Source: prototype scratchpad r57/proto/driver-lock.proto.sh — après la boucle de parse, avant LOCK_PARENT=
. "$(dirname "$0")/workstream-policy.sh"          # À RENDRE PARESSEUX en livraison (lab plat : zéro source)
if [ -z "${VF_DRIVER_LOCK:-}" ] && vf_ws_enumerate ".planning" >/dev/null 2>&1; then
  _cd="$(git rev-parse --git-common-dir 2>/dev/null)" && _cd="$(cd "$_cd" 2>/dev/null && pwd -P)"
  [ -n "${_cd:-}" ] || { echo '{"acquired": false, "reason": "no-git-common-dir"}'; exit 1; }   # livraison : repli .planning/DRIVER.lock.d
  if [ -n "$WS" ]; then
    _ok=0; _list="$(vf_ws_enumerate ".planning" 2>/dev/null)"        # PAS de pipe vers grep -q (P1)
    if vf_ws_name_valid "$WS"; then
      while IFS= read -r d; do [ "$(basename "$d")" = "$WS" ] && _ok=1; done <<EOL
$_list
EOL
    fi
    [ "$_ok" = 1 ] || { printf '{"acquired": false, "reason": "unknown-ws", "ws": "%s"}\n' "$(printf '%s' "$WS" | tr -dc 'A-Za-z0-9._-')"; exit 1; }
    LOCK_DIR="$_cd/vf-driver/ws/$WS/DRIVER.lock"
  else
    LOCK_DIR="$_cd/vf-driver/repo/DRIVER.lock"
  fi
  META="$LOCK_DIR/meta"
fi
```
(En livraison : valider par `vf_ws_dir_resolve` plutôt que par parse d'énumération ; `vf_ws_enumerate` rc 2 → refus `partition-unreadable`.)

### Dossier commun canonicalisé (modèle du dépôt)
```bash
# Source: plugin/conductor/scripts/check-method-budget.sh:603-608 (common_dir)
d=$(git -C "$1" rev-parse --git-common-dir 2>/dev/null) || return 1
case "$d" in /*) ;; *) d="$1/$d" ;; esac
(cd "$d" 2>/dev/null && pwd -P)
```

### Liste des fichiers indexés, fail-closed (côté guard python)
```python
# git durci (check-mission-exit.sh:154-156) ; -z et --no-renames mesurés nécessaires (M7)
r = subprocess.run(["git","-C",cwd,"-c","core.fsmonitor=","-c","core.hooksPath=/dev/null",
                    "--no-optional-locks","diff","--cached","--no-renames","--name-only","-z"],
                   capture_output=True, timeout=2, check=False)
if r.returncode != 0: DENY("index illisible")        # M7 : rc=128 sur index corrompu
paths = [p for p in r.stdout.decode("utf-8","strict").split("\0") if p]   # UnicodeDecodeError => DENY
```
(Toute exception ici doit produire le **deny**, jamais remonter au `|| exit 0` du bash — P3.)

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Verrou unique `.planning/DRIVER.lock`, relatif au checkout | un verrou par compartiment + un de dépôt sous `<git-common-dir>/vf-driver/` | cette phase | un manager par compartiment ; locks partagés entre worktrees |
| `mkdir` atomique (texte d'ADR-053 § Décision 1) | lien symbolique → dossier de génération, remplacé par `rename(2)` | Phase 30 (en-tête de `driver-lock.sh`) | le texte d'ADR-053 est périmé sur ce point : l'amendement peut le dire |
| Dossier `.planning/` unique | `.planning/workstreams/{fiabilite,gouvernance}` | PR #94, 2026-09-23 | le spec head §6 (« vibeflow-os n'est pas partitionné ») est périmé |

**Deprecated/outdated :** `head-governance.md` § « Extension non livrée » (devient livrée côté mécanisme) ; `mission-cross-team.md` l. 86-104 (garantie « un seul manager actif » par le verrou).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Sous Linux (bash 5, GNU coreutils) le prototype se comporte comme sous macOS (`stat`, `mv -T`, `ln -sn` déjà gérés par le script existant) | Architecture | La CI rougirait ; le script existant gère les deux familles, seul le code neuf est en cause |
| A2 | `git rev-parse --git-common-dir` existe depuis git 2.5 ; `--path-format=absolute` depuis 2.31 (donc à éviter) | Standard Stack | Ancien git → repli hors-git ; l'approche `cd … && pwd -P` ne dépend d'aucun des deux |
| A3 | Windows Git Bash : `pwd -P` rend `/c/…`, git rend `C:/…` ; python natif et bash n'ont pas à comparer leurs chaînes | Pitfall P11 | Verrou non retrouvé par le guard sous Windows ; aucun runner pour le prouver |
| A4 | Un worktree sur une branche **sans** `.planning/workstreams` (branche d'avant la partition) bascule en régime plat (verrou non partagé) | Pitfalls (régime déterminé par le contenu de la branche) | Cohabitation de deux régimes dans un même clone ; non mesuré ici |
| A5 | Latence du guard : `git rev-parse` ≈ 8 ms et `git diff --cached` ≈ 9 ms nets (mesure sur ce poste : 10,1 et 11,1 ms contre 2,1 ms de `bash -c true`) acceptables car seulement sur chemin partitionné + verbe concerné | Architecture | Budget de latence « 6,7 ms » du profil rapide (en-tête du guard) dépassé sur chaque commit d'un lab partitionné |
| A6 | Un seul `.planning/` par clone (lab à la racine) | Pitfall P9 | Collision inter-labs sur monorepo |

## Open Questions (RESOLVED)

Toutes résolues au `57-CONTEXT.md` § Arbitrages de planification (2026-10-10) ; le texte des questions ci-dessous est
conservé tel que la recherche l'a posé. Une ligne par question :

- Q1 → RESOLVED : P57-D-16 (trois classes de gestes git), arbitrage Samuel, AskUserQuestion session principale, 2026-10-10.
- Q2 → RESOLVED : P57-D-17 (lecture (a), `meta.worktree` comparé au `--show-toplevel` courant), même canal, même date.
- Q3 → RESOLVED : P57-D-18 (liste codée en dur des fichiers de forme de release, aucun fichier de configuration neuf), même canal, même date.
- Q4 → RESOLVED : P57-D-19 (union des sources, fail-closed ; P57-D-10 prolongé, pas réécrit), même canal, même date.
- Q5 → RESOLVED : P57-D-20 (limite assumée écrite dans l'amendement d'ADR-053 : le guard isole des sessions), même canal, même date.
- Q6 → RESOLVED : P57-D-20 (chaîne manager → worker → manager tenue par les allowlists, aucun refus actif neuf), même canal, même date.
- Q7 → RESOLVED : P57-D-22 (`VF_DRIVER_LOCK` posé = mode verrou unique ; E1 cesse de l'exporter en partitionné), discrétion du planificateur, « Aucun veto », même canal, même date.
- Q8 → RESOLVED : P57-D-23 (champ additif `ws` du DAG, `mark-progress --ws`), discrétion, « Aucun veto ».
- Q9 → RESOLVED : P57-D-24 (verbes sans `--ws` → dépôt puis ancien verrou, `scope` dit ; `status --all` agrège), discrétion, « Aucun veto ».
- Q10 → RESOLVED : P57-D-25 (rc 2 → refus `partition-unreadable`, cas « fichier régulier » non figé au-delà), discrétion, « Aucun veto ».
- Q11 → RESOLVED : P57-D-21 (layout `vf-driver/{ws/<sujet>,repo}` et champs `scope`/`ws`/`location` ratifiés), arbitrage Samuel, même canal, même date.
- Q12 → RESOLVED : hors périmètre — P57-D-29 (deux `.planning/` dans un même clone partagent `vf-driver/`, limite écrite), discrétion, « Aucun veto ».
- Q13 → RESOLVED : P57-D-30 (aucune release dans la 57, geste humain après la phase, ADR-073), discrétion, « Aucun veto ».
- Divergences mineures → RESOLVED : (1) P57-D-27 (validation par `vf_ws_name_valid` + `vf_ws_dir_resolve`) ; (2) constat documentaire, aucune décision requise (la citation « P412-D-10 » renvoie à `plugin/dev-orchestrator/CHANGELOG.md:11-12`, § Classe B) ; (3) P57-D-28 (quatre issues pour le guard, trois pour `driver-lock.sh`).

1. **Q1 — Gestes Bash hors `commit`/`checkout`/`switch`.** `MUTATING_GIT_VERBS = {"commit", "checkout", "switch", "restore", "reset", "clean", "push", "tag", "branch"}`, `RESUMABLE_SUBVERBS = {"rebase", "merge", "cherry-pick", "revert", "stash"}` (guard l. 153-154), `gh pr|release`. P57-D-09..11 ne disent rien de `push`, `tag`, `branch`, `gh pr`, `reset`, `rebase`… sous un verrou d'**un autre compartiment**. Refuser tout sous n'importe quel verrou d'autrui (= statu quo) interdit à B de `git push`/`gh pr create` pendant que A est tenu : la parallélisation visée échoue au dernier geste. *Recommandation :* trois classes — (i) arbre/index du checkout (`checkout, switch, restore, reset, clean, merge, rebase, cherry-pick, revert, stash, worktree remove`) : refus si verrou d'autrui **du même worktree** (Q2) ; (ii) `commit` : jugé sur l'index ; (iii) `push, branch, gh pr` : permis sous verrou de compartiment d'autrui, refusés sous verrou de **dépôt** d'autrui ; `tag`, `gh release` = geste de release : exigent que le dépôt ne soit pas tenu par autrui. *À trancher avant le plan du guard.*
2. **Q2 — Lecture de « dans le même checkout » (P57-D-11).** Voir P6. Deux lectures : (a) condition `meta.worktree == toplevel courant` (recommandée) ; (b) sans condition → tue le parallélisme entre worktrees. À confirmer.
3. **Q3 — Liste des « fichiers communs » hors `.planning/`** (`VERSION`, `plugin/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `README.md`, `README.fr.md`, `CHANGELOG.md` racine, `docs/ADR.md`) : codée en dur dans le guard (spécifique à vibeflow-os, mais le guard est distribué à tous les labs) ou lue d'un fichier de config ? Le guard Write/Edit ne couvre que `.planning/` (l. 449).
4. **Q4 — `git commit -a` / pathspec / `--amend`.** Étendre le jugement d'index (union avec `git diff --name-only` pour `-a`, avec le pathspec, avec `HEAD` pour `--amend`) est compatible avec P57-D-10 mais n'est pas ce que P57-D-10 écrit (« lit `git diff --cached --name-only` »). Sinon trou documenté dans la clause de limite.
5. **Q5 — Isolation intra-session.** Les managers d'un même head partagent le `session_id` : le guard ne peut pas les séparer (P5). L'amendement d'ADR-053 doit-il l'écrire comme limite assumée ? (« `GSD_SESSION_KEY` distinct par manager » protège le pointeur GSD, pas le guard.)
6. **Q6 — Chaîne `manager → worker → manager`.** Aujourd'hui fermée « par construction » par le verrou unique (`mission-cross-team.md:100-104`, `team-kernel.md:252-259`). Par compartiment, un manager A qui dispatche un manager B (autre `--ws`) **acquiert** sans refus : seules les allowlists `Agent(...)` (lint, non runtime) restent. Accepter et l'écrire dans l'amendement ?
7. **Q7 — `VF_DRIVER_LOCK` en lab partitionné.** Recommandation : posé ⇒ mode verrou unique forcé, JSON inchangé (garde toutes les suites vertes) ; E1 cesse de l'exporter en partitionné. Alternative : ignoré en partitionné (casse les fixtures). Relève de la discrétion (P57-D-15) mais pèse sur E1.
8. **Q8 — Liaison DAG ↔ sujet.** `dag.json` reçoit un champ additif `ws` (`dag.sh init --ws=`) et `record_progress` passe `--ws` ; sinon watchdog aveugle (Classe A). Touche un contrat de schéma (additif, lecture tolérante).
9. **Q9 — Verbes autres qu'`acquire` sans `--ws`.** D-05 ne couvre qu'`acquire`. Recommandation : dépôt puis legacy (Pattern 3/4), `scope` dit dans le JSON ; alternative : refus `ws-required` (plus sûr pour `register`, qui peut sinon consigner dans le mauvais registre ; mitigé par `status --all` qui somme les registres).
10. **Q10 — `vf_ws_enumerate` rc 2** (dossier `workstreams` lien/fichier régulier/vide) : refus fail-closed (`partition-unreadable`, recommandé) ou repli plat ? L'amendement ADR-069 (2026-09-23) dit que le cas « fichier régulier » est **encore ouvert** : ne pas figer par inadvertance.
11. **Q11 — Layout `vf-driver/{ws/<sujet>,repo}`** : P57-D-07 le classe « costly » à déplacer ; ratifier le nom et la forme (un dossier par verrou) avant le plan, ainsi que les noms de champs JSON `scope`/`ws`/`location`.
12. **Q12 — Namespace par lab** (préfixe `--show-prefix`) pour un `.planning/` non racine : à décider ou à déclarer hors périmètre.
13. **Q13 — Release.** Changement fonctionnel (6 modules : conductor v1.48.1, dev-orchestrator, design-orchestrator, 3 bundles) ⇒ ADR-073 + discipline de tag ; geste toujours gaté humain. Hors du plan sauf préparation.

**Divergences mineures avec le CONTEXT (à ratifier) :** (1) le CONTEXT désigne `vf_ws_enumerate` comme validation de `--ws` ; on recommande `vf_ws_name_valid` + `vf_ws_dir_resolve` (les deux défauts BACKLOG de l'énumération) ; (2) la citation « P412-D-10 » : voir Classe B/Head ; (3) QUAL-01 est dit « trois issues » dans DLWS-08/P57-D-12, mais le guard déclare **quatre** issues (en-tête l. 64 : PASS / DENY / imparsable-silencieux / indisponible-bruyant, code 17) — appliquer quatre au guard.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `/bin/bash` 3.2 | prototype, A/B, suites | ✓ | 3.2.57 | — |
| git | rev-parse, worktree, diff | ✓ | 2.50.1 | repli hors-git déclaré |
| python3 | guard | ✓ | 3.14.6 | `vf_guard_unavailable` code 17 |
| jq | E1, suites | ✓ | 1.7.1-apple | — |
| Linux / bash 5 | CI | ✗ (non mesurable ici) | — | CI ubuntu au premier push |
| Windows Git Bash | ADR-054 | ✗ | — | `ci.yml` n'a aucun runner Windows (simulations CRLF seulement) |
| `timeout`/`gtimeout` | — | ✗ | — | boucles `python3 -c 'time.sleep'` |

**Missing dependencies with no fallback :** aucune bloquante. **With fallback :** Linux (CI), Windows (déclaré non prouvé).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | suites bash maison (`set -uo pipefail`, `assert`/`assert_exit`/`num_eq`, `mktemp -d` + `trap`, convention TESTING.md : pas de harnais partagé entre suites) |
| Config file | none — découverte CI `find plugin scripts -type f -path '*/tests/test-*.sh'` (`ci.yml:218`) |
| Quick run command | `bash plugin/conductor/scripts/tests/test-driver-lock-ws.sh && bash plugin/conductor/scripts/tests/test-guard-driver-lock-ws.sh && bash plugin/conductor/scripts/tests/test-driver-lock.sh && bash plugin/conductor/scripts/tests/test-guard-driver-lock.sh` (les deux suites existantes : < 20 s ensemble, mesuré) |
| Full suite command | boucle CI : `for t in $(find plugin scripts -type f -path '*/tests/test-*.sh' \| sort); do bash "$t"; done` + `bash plugin/conductor/scripts/check-planning-consumers-registered.sh` + `bash plugin/conductor/scripts/check-instruction-budget.sh` |

**Noms proposés (nouveaux fichiers, jamais d'ajout aux suites existantes — DLWS-03) :** `plugin/conductor/scripts/tests/test-driver-lock-ws.sh`, `…/test-guard-driver-lock-ws.sh`, `…/test-driver-lock-consumers-ws.sh` (branch-claim, guard-health, dag), `plugin/dev-orchestrator/scripts/tests/test-check-mission-exit-ws.sh` (E1). Les fichiers sous `plugin/conductor/scripts/tests/` sont dans la surface G-2 (classe 3) : trailer `Gate-Touche: <chemin> — <raison ≥ 10 caractères>` ; idem pour toute modification de `check-branch-claim.sh`, `check-guard-health.sh` (classe 1).

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DLWS-01 | 2 compartiments acquis, même compartiment refusé `held` ; **1ᵉʳ et dernier** compartiment (P1) | unit+intégration fixture | `bash …/test-driver-lock-ws.sh` (cas WS1…) | ❌ Wave 0 |
| DLWS-01 | 24×5 acquisitions concurrentes × 2 compartiments → 1 gagnant chacun ; takeover périmé 24×5 par compartiment → 1 gagnant | concurrence | idem (cas WS-CONC) — prototype déjà rouge/vert : 5 tours → 1/1 | ❌ Wave 0 |
| DLWS-02 | dépôt indépendant des compartiments ; 2 `--depot` concurrents → 1 gagnant | concurrence | idem (WS-DEPOT) | ❌ Wave 0 |
| DLWS-03 | lab plat : sortie identique à l'original `git show <base>:plugin/conductor/scripts/driver-lock.sh` (A/B octet pour octet, normalisation epoch/pid) + `test-driver-lock.sh` (243) et `test-guard-driver-lock.sh` (103) inchangés et verts + `git diff --stat` vide sur ces deux fichiers | non-régression | `bash …/test-driver-lock-ws.sh` (WS-AB) ; `bash …/test-driver-lock.sh` ; `bash …/test-guard-driver-lock.sh` | ❌ Wave 0 (AB) ; ✅ (les deux autres) |
| DLWS-04 | `--ws` inconnu/`../x`/lien → refus `unknown-ws`/`ws-invalid` ; env `GSD_WORKSTREAM`/`VF_WORKSTREAM` posés et **ignorés** (mutant : lire l'env → rouge) ; sans `--ws` → `scope: depot` + raison | unit | idem (WS-RES) | ❌ Wave 0 |
| DLWS-05 | partage entre worktrees (acquire depuis `git worktree add`) ; sortie relative vs absolue ; hors git → repli `.planning/DRIVER.lock.d/…` + `location` déclaré + `git check-ignore` ; guard résout au même endroit | intégration fixture | `…/test-driver-lock-ws.sh` (WS-LOC), `…/test-guard-driver-lock-ws.sh` (GW-LOC) | ❌ Wave 0 |
| DLWS-06 | écriture A refusée si A tenu par autrui, B permise, racine selon dépôt ; commit jugé sur index (rename, non-ASCII, `-z`), index corrompu → deny, crash python → deny, payload imparsable → silence, interprète absent → code 17 ; checkout/switch refusés (même worktree), exemptions D-32-06 | unit (4 issues) | `…/test-guard-driver-lock-ws.sh` | ❌ Wave 0 |
| DLWS-07 | `status --all`, E1 par `--ws`, `cur_lock_gen`, watchdog (STALL/ABANDON vus par compartiment), claim de branche entre worktrees, `dag.sh mark` avance `progress_epoch` du bon verrou ; legacy vivant refuse + hint ; lint `check-planning-consumers-registered.sh` rc=0 ; budget d'instructions rc=0 | intégration | `…/test-driver-lock-consumers-ws.sh`, `…/test-check-mission-exit-ws.sh`, lint, budget | ❌ Wave 0 |
| DLWS-07 | ADR-053 amendé (forme `### Amendement du 2026-10-DD — …`), citant P57-D-01..11 avec canal+date | revue / grep | `rtk proxy grep -n 'Amendement du 2026-10' docs/ADR.md` | ❌ Wave 0 (document) |
| DLWS-08 | mutants rouges du harnais (voir ci-dessous), bilan codé en dur | mutation | `…/test-driver-lock-ws.sh` (section « mutants »), idem guard | ❌ Wave 0 |

**Mutants minimaux à prévoir (une ligne-ancre chacun, ensemble attendu exact, témoin préalable) :**
driver-lock — (a) emplacement relatif au checkout au lieu du clone (**mesuré rouge** : deux détenteurs simultanés depuis wt2, §M4b) ; (b) `--ws` non validé ; (c) repli dépôt → refus (ou l'inverse) ; (d) legacy ignoré ; (e) lecture de `GSD_WORKSTREAM` ; (f) champ JSON ajouté en lab plat (**mesuré rouge** par l'A/B, §M5b) ; (g) mutex partagé entre compartiments. Guard — (h) `-z` retiré ; (i) `--no-renames` retiré ; (j) `except → exit 0` ; (k) exemption D-32-06 retirée ; (l) condition de worktree retirée (Q2) ; (m) verrou « tenu par soi » traité comme autrui. **Piège de harnais :** une copie mutée du guard doit emporter `vf-portable.sh` à côté (locator du guard), une copie de `driver-lock.sh` doit emporter `workstream-policy.sh` (`mutant()` modèle copie déjà `$POLICY`).

### Sampling Rate
- **Per task commit :** les 4 suites du Quick run (≈ 30-40 s attendus).
- **Per wave merge :** suites de la classe E + les 4 neuves + lint des consommateurs + budget d'instructions + `test-dev-orchestrator.sh` (279 cas, il assertit sur `mission-flow.md`/`head-governance.md`/`vf-dev-manager.md`).
- **Phase gate :** boucle CI complète verte avant `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `plugin/conductor/scripts/tests/test-driver-lock-ws.sh` — DLWS-01,02,03(A/B),04,05,08 ; porte son constructeur de clone partitionné jetable et le préflight anti-pollution du vrai `.git` (P2)
- [ ] `plugin/conductor/scripts/tests/test-guard-driver-lock-ws.sh` — DLWS-05(guard),06,08
- [ ] `plugin/conductor/scripts/tests/test-driver-lock-consumers-ws.sh` — DLWS-07 (branch-claim, guard-health, dag)
- [ ] `plugin/dev-orchestrator/scripts/tests/test-check-mission-exit-ws.sh` — DLWS-07 (E1)
- [ ] Aucun framework à installer.

### Mesures de référence (clone jetable de `c6606cd0`, suites rejouées, RC=0 partout)
| Suite | Résultat |
|---|---|
| test-driver-lock.sh | 243 PASS / 0 FAIL |
| test-guard-driver-lock.sh | 103 PASS / 0 FAIL |
| test-dag.sh | 161 PASS / 0 FAIL |
| test-check-guard-health.sh | 78 PASS / 0 FAIL |
| test-check-branch-claim.sh | 18 OK / 0 KO |
| test-check-mission-exit.sh | 135 ok / 0 ko |
| test-check-legacy.sh / test-notify.sh | 8 PASS / 59 PASS |
| test-design-orchestrator.sh / test-vf-portable.sh | 51 OK / 16 ok |
| test-hook-exit-parc.sh / test-hook-exit-contract.sh | 42 OK / 40 OK |
| test-check-planning-not-inflight.sh | 37 ok, mutants 9/9 tués |
| test-check-planning-consumers-registered.sh / lint direct | 7 ok ; lint rc=0 « 23 consommateur(s) détecté(s), tous recensés » |
| test-check-instruction-budget.sh / gate direct | 69 ok ; gate rc=0 |
| test-dev-orchestrator.sh / test-check-agents.sh | 279 OK / 200 OK |

## Security Domain

`security_enforcement` actif, `security_asvs_level: 1`, `windows_enforce: true` (`.planning/config.json`).

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — (le verrou n'authentifie pas ; `owner` est un texte libre assaini) |
| V3 Session Management | partiel | `session_ids` assaini par `sanitize_session_id` (allowlist `A-Za-z0-9._-`) ; limite P5 |
| V4 Access Control | oui (anti-accident) | guard PreToolUse ; **clause de limite** : « garde-fou ANTI-ACCIDENT… PAS une garde ANTI-ADVERSAIRE » (en-tête du guard) — ne pas la durcir en promesse |
| V5 Input Validation | oui | `--ws` : `vf_ws_name_valid` + `vf_ws_dir_resolve` ; `owner`/`step` : `sanitize_field` (retire `"` `\` `\n`) ; noms de fichiers d'index : `-z` + décodage strict |
| V12 Files/Resources | oui | refus des liens symboliques (`vf_ws_path_nolink`) ; le nom du sujet ne devient un segment de chemin qu'après validation |
| V6 Cryptography | no | — |

### Known Threat Patterns for bash + git hook
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| `--ws=../../x` / sujet piégé (traversée de chemin) | Tampering | validation de nom + résolution sans lien ; mesuré : `--ws=../x` → refus (M1) |
| `.planning/workstreams/<nom>` versionné en lien symbolique | Information disclosure / Tampering | `vf_ws_dir_resolve` rc 2, jamais suivi (Phases 24/41.1) |
| Config git hostile (`core.fsmonitor`, `core.hooksPath`) exécutée par `git diff` du guard | Elevation (RCE) | flags `-c core.fsmonitor= -c core.hooksPath=/dev/null --no-optional-locks` (P12) ; précédent RCE démontré : `scripts/hooks/post-merge` en-tête |
| Script/politique résolus depuis un worktree hostile | Elevation | rester sur la cascade de scripts frères du dépôt d'installation ; pour tout appel de hook git, ancrer sur `--git-common-dir` (précédent Phase 39) |
| JSON de sortie cassé par un nom (`"`, `\`, saut de ligne) | Tampering | `printf` JSON direct = seulement des champs assainis ; dans le guard, `json.dumps` |
| Crash du hook = allow silencieux | Elevation (contournement) | P3 : deny explicite sur toute exception du jugement d'index |
| Verrou périmé laissant un faux sentiment de protection | Repudiation | `stale` exposé ; `takeover` explicite, journal `.events.log` par verrou |

## Sources

### Primary (HIGH confidence) — lus ou exécutés cette session
- `/Users/samuel/Documents/dev/vibeflow-os/plugin/conductor/scripts/driver-lock.sh` (838 l.) — lu en entier ; l. 15-17, 46, 48, 154-155, 235, 324, 361, 553, 581, 619, 731 citées
- `…/guard-driver-lock.sh` (549 l.) — lu en entier ; l. 18-19, 64, 79, 142, 153-154, 449, 464, 523, 548
- `…/workstream-policy.sh` (375 l.) — lu en entier (`vf_ws_enumerate` codes 0/2/3, `vf_ws_dir_resolve`, `vf_ws_name_valid`)
- `…/check-branch-claim.sh`, `check-guard-health.sh` (l. 55-110, 175-300), `dag.sh` (l. 1-110, 185-260), `check-mission-exit.sh` (l. 30-60, 100-190, 185-290, 425-470), `check-method-budget.sh:603-608`, `check-planning-consumers-registered.sh` (en-tête), `check-planning-not-inflight.sh:60-110, 296-352`, `check-instruction-budget.sh` (en-tête, `count_instructions`), `check-gate-touche.sh` (en-tête)
- `scripts/hooks/post-merge` et `pre-push` (en-têtes : précédent `--git-common-dir`, RCE démontrée)
- `docs/ADR.md` : ADR-053 (l. 575-632), amendements ADR-069 2026-09-23 (l. 2255-2307), ADR-072 2026-09-23 (l. 2627) ; `docs/HOOKS-CONTRAT-SORTIE.md` (§3, §4) ; `docs/superpowers/specs/2026-09-15-vibeflow-head-design.md` §3.2, §6
- `plugin/conductor/references/workstream-planning-consumers.md`, `team-kernel.md`, `plugin/dev-orchestrator/references/head-governance.md`, `mission-cross-team.md`, agents `vf-dev-manager.md` (l. 24-56, 112-123)
- `.planning/BACKLOG.md` l. 900-945 ; `.planning/config.json` ; `.gitignore:55-70` ; `.github/workflows/ci.yml` (index des étapes, l. 215-245, 2206-2218)
- `~/.claude/gsd-core/references/workstream-flag.md:26-47` (GSD_SESSION_KEY en tête de l'ordre de résolution)
- Mesures scratchpad `…/scratchpad/r57/` : `probe1.sh` à `probe5.sh`, `proto/`, `runs/*.out`, `ab-orig.txt`

### Secondary (MEDIUM) — aucune source web : aucun appel `gsd-tools query research-plan` (toute la question est interne au dépôt ; rien à interroger chez un fournisseur de documentation)

### Tertiary (LOW) — voir Assumptions Log (Linux, Windows, git ancien)

## Mesures (commandes et sorties, rejouables)

**M1 — dérivations de `LOCK_DIR`** — `rtk proxy grep -n 'LOCK_DIR=\|^META=\|LOCK_PARENT=\|LOCK_BASE=\|^REG=\|\.rec\.\|\.new\.\$\$\|events\.log\|children\.jsonl\|gen="\${LOCK_BASE}\|VF_DRIVER_CHILDREN' plugin/conductor/scripts/driver-lock.sh` →
`46:LOCK_DIR="${VF_DRIVER_LOCK:-.planning/DRIVER.lock}"` · `48:META="$LOCK_DIR/meta"` · `154:LOCK_PARENT="$(dirname "$LOCK_DIR")"` · `155:LOCK_BASE="$(basename "$LOCK_DIR")"` · `235:  gen="${LOCK_BASE}.gen.${ts}.$$"` · `324:  local log_path="$LOCK_PARENT/${LOCK_BASE}.events.log"` · `361:REG="${VF_DRIVER_CHILDREN:-$LOCK_PARENT/${LOCK_BASE}.children.jsonl}"` · `553/619/731: mutex="${LOCK_DIR}.rec.$(printf '%s' "$observed_gen" | tr -c 'A-Za-z0-9._-' '_')"` · `581: ln_atomic "$gen" "${LOCK_DIR}.new.$$" && mv_link "${LOCK_DIR}.new.$$" "$LOCK_DIR"`.

**M2 — `git rev-parse --git-common-dir`** (script `probe.sh`, lancé par `/bin/bash` 3.2.57, git 2.50.1, dépôt jetable) :
```
main checkout, cwd=root        → .git                      (git-dir : .git)
main checkout, cwd=sub/deep    → ../../.git                (git-dir : absolu)
linked worktree, cwd=root      → /…/gcd/main/.git          (git-dir : /…/main/.git/worktrees/wt)
linked worktree, cwd=x/y       → /…/gcd/main/.git
--path-format=absolute (wt)    → /…/gcd/main/.git
hors git                       → fatal: not a git repository…   rc=128
```
Dépôt réel : main → `.git` ; worktree `.claude/worktrees/etude-qualite` → `/Users/samuel/Documents/dev/vibeflow-os/.git` ; `plugin/conductor` → `../../.git`. **Conclusion :** sortie tantôt relative (au cwd), tantôt absolue ⇒ canonicaliser par `cd "$d" && pwd -P` (jamais comparer la sortie brute).

**M3 — repli hors git couvert par `.gitignore`** — `git check-ignore -v .planning/DRIVER.lock.d/ws/A/DRIVER.lock` → `.gitignore:1:.planning/DRIVER.lock*` rc=0 ; `.planning/vf-driver/ws/A/DRIVER.lock` → rc=1 (non ignoré).

**M4 — prototype (clone jetable partitionné `fiabilite`/`gouvernance`)** : `acquire --ws=fiabilite` (m1) et `--ws=gouvernance` (m2) → `"acquired": true` tous deux ; `--ws=fiabilite` (m3) → `{"acquired": false, "reason": "held", "held_by": "m1", …}` ; sans `--ws` (m4) → dépôt acquis, indépendant ; `--ws=nope` et `--ws=../x` → `unknown-ws` rc=1 ; disposition : `.git/vf-driver/{repo,ws/fiabilite,ws/gouvernance}/DRIVER.lock` + `DRIVER.lock.gen.*/meta` ; aucun `.planning/DRIVER.lock*` créé. Depuis `git worktree add` (wt2) : `acquire --ws=fiabilite --owner=other` → `held_by: m1` (partage) et `ls .planning/DRIVER.lock` → absent. Concurrence 24 × 5 tours sur deux compartiments verrous libres : `round 1…5: gagnants fiabilite=1 gouvernance=1` ; « rounds hors contrat: 0 ». **M4b (mutation)** : emplacement `$PWD/.planning` à la place du clone → `acquire --owner=other` depuis wt2 rend `"acquired": true` alors que m1 tient le compartiment (deux détenteurs) ⇒ le test de partage devient rouge.

**M5 — A/B lab plat** (`probe5.sh`, séquence `acquire×2, status, heartbeat, mark-progress, register, orphans, release×2, status, bogus`, normalisation `[0-9]{10}`→EPOCH, pid, âges) : `cmp -s` → « A/B lab plat: IDENTIQUE octet pour octet » (34 lignes). **M5b** : mutant `{"present": true, "scope": "x", "owner"…` → `DIFF: 8c8` ⇒ le témoin peut rougir.

**M6 — suites** : voir tableau §Validation (RC=0 sur toutes).

**M7 — `git diff --cached`** (`probe4.sh`) : HEAD non né, rien d'indexé → sortie vide rc=0 ; renommage `A/STATE.md`→`B/STATE.md` : sans `--no-renames` → `.planning/workstreams/B/STATE.md` seul ; avec → A **et** B ; non-ASCII sans `-z` → `"\303\251.txt"` ; avec `-z` → `é.txt\0ü.txt\0` ; `git commit -a` : `index:[]  worktree-vs-index:[A/STATE.md, A/note with space.md, "\303\251.txt"]` ; index corrompu → `fatal: .git/index: index file smaller than expected` rc=128.

**M8 — latence** (50 itérations, `bash -c true` = 2,1 ms de plancher) : `git rev-parse --git-common-dir` 10,1 ms ; `git diff --cached --name-only` 11,1 ms.

**M9 — gate d'instructions** (clone) : `vf-dev-manager.md 250/250 lignes, 46/46 instr OK` ; `vf-design-manager.md 196 (bl 192) / 30` ; `AGENT.md 209/209, 33/33` ; `vf-coder.md 146 (bl 122), 22 (bl 23) MARGE`. Sentinelle `.planning/.instruction-budget-armed` présente (0 octet) ⇒ **armé** ; une hausse d'instructions rougit (rc=1) et une hausse de baseline exige une citation d'arbitrage (G-1).

## Recommended plan decomposition (waves, propriété de fichiers disjointe)

| Plan | Wave | Fichiers possédés (exclusifs) | Exigences | Dépend de |
|------|------|-------------------------------|-----------|-----------|
| 57-01 Noyau `driver-lock.sh` | 1 | `plugin/conductor/scripts/driver-lock.sh`, `…/tests/test-driver-lock-ws.sh` (neuf) | DLWS-01,02,03,04,05(script),08(concurrence+mutants) | — (Q7, Q9, Q10, Q11 tranchées) |
| 57-02 Guard | 2 | `…/guard-driver-lock.sh`, `…/tests/test-guard-driver-lock-ws.sh` (neuf) | DLWS-05(guard),06,08 | 57-01 (contrat de layout + JSON) ; Q1-Q4 tranchées |
| 57-03 Consommateurs conductor | 2 | `…/check-branch-claim.sh`, `…/check-guard-health.sh`, `…/dag.sh`, `…/tests/test-driver-lock-consumers-ws.sh` (neuf) | DLWS-07 | 57-01 ; Q8 |
| 57-04 Consommateur dev-orchestrator | 2 | `plugin/dev-orchestrator/scripts/check-mission-exit.sh`, `…/tests/test-check-mission-exit-ws.sh` (neuf) | DLWS-07 (E1, `cur_lock_gen`) | 57-01 |
| 57-05 Prompts et références | 3 | 5 agents managers, `vf-coder.md`, `vf-reviewer.md`, `mission-flow.md`, `team-kernel.md`, `mission-cross-team.md`, `head-governance.md`, `workstream-planning-consumers.md`, READMEs | DLWS-07 | 57-01..04 (CLI figée) ; **instructions constantes** (Pitfall budget) ; relancer `test-dev-orchestrator.sh` |
| 57-06 Doctrine | 3 | `docs/ADR.md` (amendement ADR-053), note datée dans le spec head §6, `docs/HOOKS-CONTRAT-SORTIE.md` (si besoin) | DLWS-07 (P57-D-13) | 57-01..04 (pour citer le mesuré) ; Q5, Q6 |
| 57-07 Clôture | 4 | entrée BACKLOG réécrite (pas supprimée, P57-D-08), ledger `ROADMAP`/`REQUIREMENTS`/`STATE` **à la main** (les verbes `state.*` sont destructifs sur ce dépôt), recette sur clone jetable partitionné, relance du lint + budget + boucle CI | DLWS-08 (rapport) | tous |

Disjonction vérifiée : aucun fichier n'apparaît dans deux plans ; 57-02/03/04 sont parallélisables (modules et fichiers distincts) une fois le contrat de 57-01 figé. L'écriture de `BACKLOG.md`, de `docs/ADR.md` et des fichiers racine `.planning/` en Wave 3-4 est **elle-même un geste de dépôt** : prendre `acquire --depot` (dogfooding, sans quoi l'amendement viole l'invariant qu'il pose). Les commits qui touchent `check-*.sh` ou les suites du conductor portent le trailer `Gate-Touche:` (G-2) ; tout commit qui cite une décision humaine nomme canal et date (CLAUDE.md) ; les identifiants neufs se préfixent `P57-D-16…` (ADR-075).

## Project Constraints (from CLAUDE.md)

- Langue : français pour la prose, messages de commit en français cohérents avec l'historique ; identifiants techniques tels quels.
- **Discipline de release** : toute version = un tag annoté ; une release ne se déclenche que pour une évolution **fonctionnelle** (ADR-073) — cette phase en est une, mais la release est un geste humain gaté, hors plan.
- **ADR-029** : agents ≤ 300 lignes (alerte dès 251, `vf-dev-manager.md` est déjà à 250), skills ≤ 500 ; ratchet d'instructions armé (`check-instruction-budget.sh`) ; hausse de baseline = citation d'arbitrage (G-1).
- **Jamais de fix sans validation humaine** (ADR-031) ; agents natifs machine-enforced (`check-agents.sh` : description + model + memory) — aucun agent créé ici.
- **Traçabilité des arbitrages** : canal + date, jamais « arbitrage Samuel » nu ; **préfixage des identifiants** de décision (`P57-D-NN`).
- **Gate-Touche** (G-2) sur tout commit touchant un gate, sa suite, `ci.yml` ou un hook ; **G-1** sur la baseline ; **G-3** alarme sur un commit sans PR.
- Mémoire du repo applicable : toujours `rtk proxy` pour mesurer (le proxy tronque et ment sur les sorties vides) ; verbes `state.*` de gsd-tools destructifs ; `driver-lock.sh status` avant tout checkout dans l'arbre principal (verrou vivant détenu par l'orchestrateur pendant cette recherche : aucune commande d'écriture n'a visé le vrai `.planning/`) ; aucun manager ne s'autorise `/gsd-ship`.

## Metadata

**Confidence breakdown:**
- Standard stack : HIGH — outils déjà présents, versions mesurées
- Architecture : HIGH — point d'insertion unique vérifié par grep et par prototype joué sous bash 3.2.57 (concurrence, worktree, A/B, deux mutants rouges)
- Guard : MEDIUM — algorithme spécifié et trous mesurés (M7), non implémenté ; 4 questions (Q1-Q4) conditionnent sa forme
- Pitfalls : HIGH — P1, P2, P3 et P4 sont des mesures, pas des opinions ; P11/A1/A3 non mesurables ici

**Research date :** 2026-10-10
**Valid until :** 2026-11-10 (code interne stable ; à refaire si `workstream-policy.sh`, `driver-lock.sh` ou le guard changent avant le plan — vérifier d'abord `git log --oneline -3 -- plugin/conductor/scripts/driver-lock.sh plugin/conductor/scripts/guard-driver-lock.sh plugin/planning-core/scripts/workstream-policy.sh`)
