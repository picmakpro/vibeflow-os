# Note d'architecture — Transposition jcode → VibeFlow (mémoire + swarm)

> **Date** : 2026-07-20
> **Source** : [1jehuang/jcode](https://github.com/1jehuang/jcode) @ `master` (harness d'agent Rust, MIT, ~9.4k ★)
> **Périmètre** : deux modules disséqués — `crates/jcode-base/src/memory/` (+ crate `jcode-memory-types`)
> et `crates/jcode-app-core/src/tool/communicate/` (swarm).
> **Objet** : ce qui est **transposable** dans VibeFlow, et à quel coût, compte tenu que VibeFlow
> **roule sur Claude Code** (pas de sidecar natif, pas de bus temps réel entre sous-agents).

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
