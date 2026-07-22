# Note d'architecture — Transpositions externes → VibeFlow

> **Date** : 2026-07-20
> **Objet** : ce qui est **transposable** dans VibeFlow depuis des harness/outils externes, et à quel coût,
> compte tenu que VibeFlow **roule sur Claude Code** (pas de sidecar natif, pas de bus temps réel entre
> sous-agents). Principe directeur : *on transpose le schéma de données et la discipline de cycle de vie,
> jamais le runtime.*
>
> **Sources disséquées :**
> - **§0–5 — [1jehuang/jcode](https://github.com/1jehuang/jcode)** @ `master` (harness d'agent Rust, MIT,
>   ~9.4k ★) : modules `crates/jcode-base/src/memory/` (+ crate `jcode-memory-types`) et
>   `crates/jcode-app-core/src/tool/communicate/` (swarm). → **mémoire + swarm**.
> - **§6 — [kunchenguid/no-mistakes](https://github.com/kunchenguid/no-mistakes)** @ `main` (proxy git de
>   qualité, Go, MIT, ~6.7k ★) : skill `/no-mistakes`, pipeline `.no-mistakes.yaml`. → **discipline de clôture
>   (review → ship)**.

---

## 0. Cadre & garde-fou honnête

jcode est un **harness concurrent** de Claude Code, pas une dépendance branchable. On n'installe rien.
La valeur est **architecturale** : jcode implémente **nativement, en Rust**, deux capacités que VibeFlow
**émule par-dessus** Claude Code :

1. une **mémoire à rappel sémantique automatique** (là où VibeFlow a `MEMORY.md` + skill `consolidator`
   + `planning-core`, chargés/consolidés manuellement) ;
2. une **collaboration multi-agents par messages** (là où VibeFlow a l'équipe
   `vf-dev-manager → vf-coder / vf-reviewer / vf-auditer / vf-test-orchestrator` dispatchée via `Task`).

**Ligne rouge** : Claude Code n'expose ni runtime d'embeddings intra-session, ni socket persistant entre
sous-agents. Donc on **ne copie pas le runtime** de jcode — on transpose son **schéma de données** et sa
**discipline de cycle de vie**. Tout le reste (MiniLM 384-dim, sidecar UDS JSON-RPC, threads de garden) est
hors d'atteinte tant que VibeFlow reste un plugin Claude Code. C'est le point qui rend cette note actionnable
plutôt qu'aspirationnelle.

---

## 1. Module mémoire jcode — ce qu'il y a dedans

### 1.1 Modèle de données (`jcode-memory-types::MemoryEntry`)

Chaque souvenir est un enregistrement riche, bien au-delà du « une ligne dans MEMORY.md » actuel :

| Champ | Rôle | Équivalent VibeFlow aujourd'hui |
|---|---|---|
| `category` | `Fact` / `Preference` / `Entity` / `Correction` / `Custom` | proche des types `user/feedback/project/reference` |
| `trust` | `High` (dit par l'user) / `Medium` (observé) / `Low` (inféré) | **absent** |
| `confidence` (0–1) | **décroît dans le temps**, remonte à l'usage | **absent** |
| `strength` + `reinforcements[]` | compteur + fil d'Ariane (session, index msg, ts) de chaque renforcement | **absent** |
| `active` + `superseded_by` | supersession explicite (souvenir remplacé, non supprimé) | suppression manuelle du fichier |
| `access_count` | boost de confiance à l'usage | **absent** |
| `embedding` + `embedding_model` | vecteur 384-dim + tag du modèle (cohabitation de plusieurs espaces vectoriels) | **hors périmètre** (pas de runtime) |
| `search_text` | texte normalisé pré-calculé (contenu + tags) pour BM25 | de facto le contenu brut |

**Décroissance par catégorie** (`effective_confidence`) — demi-vies calibrées par nature de l'info :

- `Correction` → **365 j** (les corrections user valent cher, on les garde longtemps)
- `Preference` → **90 j** (les préférences évoluent)
- `Entity` → **60 j**
- `Fact` → **30 j** (les faits de codebase périment vite)

Formule : `confidence × e^(−age/demi-vie × ln2) × (1 + 0,1·ln(access_count+1))`.
→ **Une correction jamais réutilisée s'efface lentement ; un fait de codebase touché souvent reste chaud.**

### 1.2 Graphe mémoire (`MemoryGraph`, `EdgeKind`)

Les souvenirs ne sont pas une liste plate mais un **graphe** : nœuds (`memories`), `tags`, `clusters`
(centroïde + membres), et arêtes typées avec un **poids de traversée** pour le scoring BFS :

- `Supersedes` (0,9) — remplace un ancien
- `HasTag` (0,8)
- `DerivedFrom` (0,7) — savoir procédural dérivé de faits
- `InCluster` (0,6)
- `RelatesTo{weight}` — lien sémantique pondéré
- **`Contradicts` (0,3) — info conflictuelle : les deux souvenirs sont GARDÉS et signalés**

Le point remarquable : **jcode ne tranche pas les contradictions, il les matérialise** comme arête, et laisse
le scoring les déprioriser. C'est l'inverse d'une consolidation destructive.

### 1.3 Pipeline par tour (`PipelineState`)

À **chaque tour** de conversation, un pipeline en **4 étapes** tourne en tâche de fond :

```
search → verify → inject → maintain
```

- **search** : embedding + lexical (BM25) fusionnés par RRF (Reciprocal Rank Fusion)
- **verify** : un « sidecar » (petit LLM) juge la **pertinence réelle** des candidats (anti-bruit)
- **inject** : n'injecte dans le contexte que ce qui a survécu au verify
- **maintain** (gardening de fond) : relie, ajuste les confiances (`boosted`/`decayed`), raffine les clusters,
  infère des tags partagés, détecte les **trous** (`MaintenanceGap`)

→ La mémoire est **entretenue en continu**, pas seulement écrite/lue.

---

## 2. Module swarm jcode — ce qu'il y a dedans

### 2.1 Substrat : bus de messages sur socket Unix

`communicate/transport.rs` : JSON-RPC ligne-à-ligne sur `socket_path()` (UDS). Le client **filtre** les
événements asynchrones (`swarm_status`, `swarm_plan_proposal`, `notification`, `memory_injected`…) et n'attend
que la **réponse terminale** de son `id`. → un vrai **bus d'événements** entre agents vivants.

### 2.2 Vocabulaire d'actions exposé à l'agent (`communicate.rs`)

Une seule API-outil, ~30 verbes, regroupables en 4 familles :

- **Messagerie** : `message`, `dm`, `broadcast`, `channel`, `read`, `subscribe_channel`,
  `list_channels`, `channel_members`
- **Planification collaborative** : `propose_plan` → `approve_plan` / `reject_plan`, `run_plan`,
  `expand_node`, `complete_node`, `inject_gap`, `resync_plan`, `plan_status`
- **Cycle de vie des workers** : `spawn`, `stop`, `cleanup`, `assign_role`, `assign_task`,
  `assign_next`, `fill_slots`, `list_models`
- **Coordination** : `status`, `report`, `summary`, `read_context`, `await_members`

### 2.3 Résolution de conflits (le cœur intéressant)

jcode n'a **pas** de magie de merge ; il a une **discipline de verrous** :

1. **Claim de driver unique** (`try_claim_run_plan_driver`, `RunPlanClaimGuard` RAII) : un seul `run_plan`
   pilote un plan à la fois pour une session. Check-and-insert sous **un seul verrou** → deux appels
   concurrents dans le même batch ne peuvent pas piloter tous les deux.
2. **Récupération de claim périmé** : un claim laissé par un process rechargé/crashé ne bloque pas
   éternellement (la map est par-process, les task ids morts sont élagués).
3. **DAG de tâches** avec frontière `ready` / `blocked` : un `swarm retry` re-queue les nœuds échoués,
   une complétion externe débloque, une gate injecte du travail → le driver **ré-entre** dans la boucle de
   dispatch quand la frontière grossit.
4. **Remap de collision d'id de nœud** (`remap_conflicting_seed_nodes`) : deux seeds au même id → renommage
   déterministe `id::scope` au lieu d'un échec.
5. Modes de concurrence : **light** (fan-out cheap, 4 workers) vs **deep** (`swarm_max_concurrent_agents`,
   avec garde RAM anti-spawn-récursif).

→ Le swarm est **sûr par construction** (claims + DAG + remap), pas par espoir.

---

## 3. Transposition vers VibeFlow

### 3.1 Mémoire — ce qui se transpose SANS runtime

Le `MemoryEntry` de jcode est un **cahier des charges de frontmatter** pour la mémoire fichier de VibeFlow.
On enrichit le format `memory/*.md` (aujourd'hui : `name`, `description`, `type`) avec des champs que le skill
`consolidator` sait déjà manipuler à la main :

```yaml
metadata:
  type: user | feedback | project | reference
  trust: high | medium | low          # NOUVEAU — qui l'affirme
  confidence: 0.0–1.0                  # NOUVEAU — dévalué par le consolidator au fil des passes
  created: 2026-07-20                  # demi-vie appliquée par catégorie (cf. §1.1)
  reinforced: [2026-07-20, ...]        # NOUVEAU — breadcrumbs (remplace `strength`)
  superseded_by: <slug>                # NOUVEAU — supersession non destructive
  status: active | superseded
```

- **Décroissance de confiance par catégorie** → devient une **règle du `consolidator`** (pilier Indexation) :
  à chaque passe, recalculer une confiance effective et **rétrograder/archiver** au lieu de supprimer. Les
  demi-vies de jcode (correction 365 j, préférence 90 j, fact 30 j) sont un point de départ crédible.
- **Supersession vs suppression** → aligne avec la doctrine VibeFlow « jamais de fix sans validation
  humaine » (ADR-031) : on **marque** `superseded_by`, on ne détruit pas l'historique.
- **Arête `Contradicts`** → le `consolidator` (pilier BLOCKERS/DECISIONS) matérialise les contradictions au
  lieu de les résoudre en douce : deux entrées liées par `[[slug]]` + `status: contradicts`, remontées à
  l'humain. **C'est exactement le geste que `consolidator` cherche à outiller.**
- **`DerivedFrom`** → trace un LEARNING dérivé d'un JOURNAL/DECISION : le graphe `[[...]]` de `MEMORY.md`
  supporte déjà les liens, il manque juste le **typage** de l'arête.

**Ce qu'on NE transpose PAS** : embeddings, RRF, sidecar de verify, gardening de fond. Pas de runtime pour ça
dans une session Claude Code. Le substitut réaliste du « verify sidecar » = le **jugement du consolidator**
au moment de la passe (batch, pas par-tour).

### 3.2 Swarm — ce qui se transpose SANS bus temps réel

L'équipe VibeFlow (`vf-dev-manager` & workers) est déjà l'analogue fonctionnel du swarm. jcode donne trois
**patterns de sûreté** à importer, tous réalisables via **fichier d'état + discipline**, sans socket :

1. **Claim de driver unique** → un **fichier de lock** (`.planning/…/DRIVER.lock` ou champ d'état) que
   `vf-dev-manager` pose avant de dispatcher une mission, pour empêcher deux missions concurrentes de piloter
   la même étape (le pendant du `RunPlanClaimGuard`). Adresse directement le risque des **backups isolés**
   (ADR-048/049) quand plusieurs cycles tournent.
2. **DAG de tâches avec frontière `ready`/`blocked`** → formaliser le plan de bataille du manager comme un
   **graphe de nœuds** (état persistant) plutôt qu'une liste ordonnée : un fix qui rouvre une étape
   « débloque » un nœud, le manager **ré-entre** dans le dispatch. Robustifie la boucle fix→re-revue de
   `vf-coder`.
3. **Rapports structurés + `await_members`** → les workers rendent déjà un rapport ; on **type** le rapport
   (statut, findings, nœuds débloqués) pour que le manager fasse du contrôle de flux déterministe, comme
   `plan_status` / `report` de jcode.

**Ce qu'on NE transpose PAS** : le bus UDS, les channels temps réel, `broadcast`/`dm` entre agents vivants.
Le modèle Claude Code est **dispatch-and-join** (`Task`), pas acteurs concurrents persistants.

### 3.3 Tableau de synthèse « adopter / différer / rejeter »

| Concept jcode | Verdict | Où dans VibeFlow |
|---|---|---|
| `trust` + `confidence` + décroissance par catégorie | **ADOPTER** | frontmatter mémoire + règle `consolidator` |
| Supersession non destructive (`superseded_by`) | **ADOPTER** | format mémoire + `consolidator` (aligné ADR-031) |
| Arêtes typées `Contradicts` / `DerivedFrom` | **ADOPTER** | liens `[[...]]` typés dans `MEMORY.md` / registres |
| Claim de driver unique (RAII lock) | **ADOPTER** | fichier de lock `vf-dev-manager` |
| DAG `ready`/`blocked` + ré-entrée | **ADOPTER** | plan de bataille du manager en graphe d'état |
| Rapports de worker typés | **ADOPTER** | contrat de sortie `vf-coder`/`vf-reviewer` |
| Pipeline mémoire 4-étapes **par tour** | **DIFFÉRER** | pas de hook par-tour fiable ; le faire **par passe** consolidator |
| Embeddings + RRF + sidecar verify | **REJETER** | pas de runtime intra-session Claude Code |
| Bus UDS / channels / dm temps réel | **REJETER** | modèle Task = dispatch-and-join, pas acteurs |
| Self-dev (rebuild/reload à chaud) | **REJETER (ici)** | pertinent pour `vf-update` mais hors périmètre de cette note |

---

## 4. Risques & questions ouvertes

- **Sur-ingénierie du frontmatter** : ajouter 5 champs à chaque `memory/*.md` a un coût de densité
  (ADR-029). Vérifier que `consolidator` peut les tenir à jour **automatiquement**, sinon ils pourrissent.
- **Demi-vies arbitraires** : les valeurs jcode (365/90/60/30 j) sont calibrées pour un usage code générique
  ; à re-calibrer pour l'usage VibeFlow (labs multi-métiers, pas que du dev).
- **Lock de driver et crash** : reproduire la **récupération de claim périmé** de jcode, sinon un manager qui
  meurt laisse un lock mort qui gèle les missions.
- **Périmètre** : cette note propose une **R&D**, pas une release. Rien ici ne doit toucher le socle
  `conductor` sans passer par un ADR.

---

## 5. Prochain pas proposé

Un **spike** ciblé (voir Phase 9 au ROADMAP) : prototyper les **3 gestes mémoire les moins chers**
(champs `trust`/`confidence`/`superseded_by` + règle de décroissance dans `consolidator`) sur **un lab
témoin**, mesurer l'effort de maintenance réel, décider go/no-go avant d'écrire un ADR et de toucher le
format mémoire officiel. Le volet swarm (lock de driver + DAG) est un **second spike** indépendant, à
prioriser seulement si les backups isolés (ADR-048/049) montrent des collisions en pratique.

---

## 6. Annexe — Transposition no-mistakes → VibeFlow (gate qualité au push)

> **Source** : [kunchenguid/no-mistakes](https://github.com/kunchenguid/no-mistakes) @ `main`
> (proxy git de qualité, Go, MIT, ~6.7k ★, v1.40.0). Disséqué : skill `/no-mistakes`
> (`skills/no-mistakes/SKILL.md`), pipeline `.no-mistakes.yaml`, `docs/.../reference/repo-config.md`.
> **Nature** : source **différente** de jcode — pas mémoire/swarm mais **discipline de clôture**
> (review → ship). Annexée ici car elle sert la même thèse : *on transpose le schéma et la discipline,
> pas le runtime.* Le runtime de no-mistakes (proxy git en daemon Go) est hors d'atteinte d'un plugin
> Claude Code ; ce qui se transpose, c'est **où** et **comment** il place ses gates.

### 6.1 Ce que fait no-mistakes

Un **proxy git**. Au lieu de `git push origin`, on pousse sur un remote `no-mistakes`, ce qui déclenche —
**dans un worktree jetable isolé, non-bloquant** — un pipeline ordonné :

```
rebase → review → test → document → lint → push → PR → CI
```

Rien n'atteint le vrai remote tant que tout n'est pas vert ; une **PR propre** est ouverte à la fin.
Trois points d'entrée : `git push no-mistakes`, un TUI, et une **skill `/no-mistakes`** pilotée par l'agent.
C'est le **même métier que l'équipe dev VibeFlow** (`vf-dev-manager → vf-coder / vf-reviewer / vf-auditer /
vf-test-orchestrator`), mais packagé selon 4 idées que VibeFlow n'a pas encore formalisées.

### 6.2 Taxonomie de findings à 3 niveaux (le cœur intéressant)

Chaque gate rend une table `findings` (`id`, `severity`, `file`, `description`, **`action`**) où l'`action`
tranche le traitement :

| `action` | Sens | Traitement |
|---|---|---|
| **`auto-fix`** | mécanique, faible risque | corrigé **automatiquement** (`respond --action fix`) |
| **`no-op`** | informatif seulement | ignoré |
| **`ask-user`** | **défie l'intention** ou le comportement produit | **escaladé à l'humain**, jamais tranché seul par l'agent |

Et un **budget d'auto-fix par étape**, machine-réglable dans `.no-mistakes.yaml` :

```yaml
auto_fix:
  lint: 5        # 5 tentatives auto avant pause
  test: 3
  document: 3
  review: 0      # 0 = désactivé → tout finding review passe en ask-user
```

→ C'est un **raffinement direct d'ADR-031** (« jamais de fix sans validation humaine ») : au lieu du binaire
actuel, un modèle **à deux étages** — *auto-fix mécanique autorisé + escalade obligatoire sur tout ce qui
touche l'intention/la logique/la sécurité* — avec un **cran de sûreté par étape** (`review: 0` force la revue
humaine). Transposable dans le contrat de la boucle `vf-coder` ↔ `vf-reviewer` : le reviewer **type** chaque
finding (`auto-fix`/`no-op`/`ask-user`), le coder n'applique seul que les `auto-fix`, borné par un budget.

### 6.3 L'`--intent` comme entrée de première classe de la revue

no-mistakes rend l'argument `--intent` **obligatoire** : « ce que l'utilisateur cherchait à accomplir », en ses
propres termes, décisions et compromis inclus. Il sert à **distinguer les choix délibérés des erreurs** pendant
la revue (un reviewer sans l'intention prend une décision assumée pour un bug). VibeFlow a cette donnée mais
**dispersée** (GSD `discuss-phase`, `--intent` implicite). Geste transposable : **passer un intent explicite à
`vf-reviewer`** pour qu'il juge le diff *contre l'objectif*, pas seulement dans l'absolu. Croise le champ
`intent` de la mémoire jcode (§1) — même intuition : l'intention est une donnée, pas un sous-entendu.

### 6.4 Gate au push, pas à l'intention

Chez VibeFlow la chaîne qualité est déclenchée par **commande/intent** (`/vf-ship`, `/vf-review`) → donc
**contournable** : on peut pousser sans y passer. no-mistakes rend le pipeline **non-bypassable** en
s'accrochant à la frontière du push. Or VibeFlow a **déjà l'infra** : `scripts/hooks` avec un `pre-push` qui
bloque les push vers `main` (aujourd'hui limité à la vérif de tag de release, cf. `check-release-tag.sh`).
Geste transposable : **étendre ce `pre-push` en vrai gate qualité** (au minimum : diff non revu → refus de
push sur `main`), en le câblant sur `vf-ship`. C'est le chaînon manquant entre `vf-ship` et la règle
non-négociable de release. Les états de sortie de no-mistakes cartographient proprement le besoin :
`checks-passed` (vert, PR prête, **non fusionnée**) vs `passed` (fusionnée) → **handoff propre à l'humain pour
le merge**, aligné ADR-031.

### 6.5 Sécurité : la config d'exécution vient de la branche de confiance

Détail crucial et directement pertinent pour VibeFlow : le daemon lit **toujours `commands` et `agent` depuis
la branche par défaut**, **jamais depuis la branche poussée** (opt-in `allow_repo_commands`, dev solo
uniquement) → un contributeur ne peut pas injecter de commande shell via sa branche en revue. C'est
**exactement la doctrine d'ADR-047** (allowlist MCP des agents exécutants dérivée du lab, v2.24.0) : *la config
d'exécution provient d'une source de confiance, jamais de l'artefact en cours de revue.* → **Renfort externe
d'ADR-047**, à citer comme précédent ; et garde-fou à vérifier partout où un agent exécutant VibeFlow tire une
commande d'un fichier de projet potentiellement modifié dans le cycle en cours.

### 6.6 Custody de branche ↔ claim de driver (croisement avec §3.2)

no-mistakes a un modèle de **custody** de branche (`sync` / `continue_active_run` / `recover_custody`) qui
répond à « qui pilote cette branche maintenant ? » et sait **récupérer une custody périmée** (course terminale
non publiée). C'est le **même problème** que le *claim de driver unique* + *récupération de claim périmé*
transposés de jcode en §3.2 / §4. Deux sources indépendantes convergent → **signal fort** que le lock de
driver `vf-dev-manager` doit livrer sa **récupération de lock mort** dès le premier jet (sinon manager crashé =
missions gelées).

### 6.7 Table de synthèse « adopter / différer / rejeter »

| Concept no-mistakes | Verdict | Où dans VibeFlow |
|---|---|---|
| Taxonomie `auto-fix` / `no-op` / `ask-user` | **ADOPTER** | contrat de findings `vf-reviewer` → boucle `vf-coder` (raffine ADR-031) |
| Budget d'auto-fix par étape (`review: 0`) | **ADOPTER** | cran de sûreté machine dans la boucle fix→re-revue |
| `--intent` obligatoire en entrée de revue | **ADOPTER** | passer l'intent explicite à `vf-reviewer` (croise GSD `discuss-phase`) |
| Gate au `pre-push` sur `main` | **ADOPTER** | étendre `scripts/hooks` + `check-release-tag.sh`, câblé sur `vf-ship` |
| Config d'exécution lue depuis branche de confiance | **ADOPTER (renfort)** | précédent externe d'ADR-047 ; à auditer partout où un exécutant lit une commande de projet |
| États `checks-passed` vs `passed` (PR prête ≠ mergée) | **ADOPTER** | contrat de sortie `vf-ship` : vert + PR, merge = geste humain |
| Custody de branche + récupération périmée | **ADOPTER** | conforte le lock de driver `vf-dev-manager` (§3.2) — livrer la recovery d'emblée |
| Worktree jetable **unique** pour tout le pipeline | **DIFFÉRER** | VibeFlow isole **par agent** (`isolation: worktree`) ; utile surtout pour `vf-auto` nocturne |
| Mode `--yes` (piloter tous les gates, y compris `ask-user`) | **DIFFÉRER** | pendant de `vf-auto` en autonomie, mais casse l'escalade → à borner |
| Le proxy git en daemon Go (remote `no-mistakes`) | **REJETER** | VibeFlow est un plugin Claude Code, pas un proxy git ; on reprend **où** sont les gates, pas le runtime |
| Fallback agent-agnostic (codex/cursor/copilot…) | **REJETER** | VibeFlow est Claude-Code-locké par design |

### 6.8 Prochain pas proposé (pour la phase)

**Spike indépendant du volet mémoire/swarm** — la brique la plus rentable est le couple **§6.2 (taxonomie de
fix à 3 niveaux + budget par étape)** et **§6.4 (gate au `pre-push`)**, car elles adressent le vrai manque de
VibeFlow : *l'enforcement au bon endroit* et *une granularité de fix plus fine qu'ADR-031*. Concrètement :

1. Prototyper le **typage des findings** (`auto-fix`/`no-op`/`ask-user`) dans le rapport de `vf-reviewer` et
   la règle d'application côté `vf-coder`, sur un lab témoin — mesurer combien de va-et-vient humain on
   économise sans affaiblir l'escalade.
2. Étendre le `pre-push` existant à un **gate qualité minimal sur `main`** (diff non revu → refus), câblé sur
   `vf-ship` ; garder `check-release-tag.sh` comme brique.
3. Le reste (§6.3 intent-en-entrée, §6.5 renfort ADR-047, §6.6 custody) sont des **durcissements** à verser
   dans les ADR concernés, pas un spike. §6.6 en particulier **conforte** le second spike swarm de §5.

Comme pour jcode : **rien ici ne touche le socle `conductor` sans ADR**. C'est une R&D, pas une release.
