# Phase 9 — Mini-cadrage du volet swarm (ÉCRIT, NON IMPLÉMENTÉ)

**Date :** 2026-07-22
**Statut :** cadrage seul. **Aucune implémentation.** L'invariant tient : le swarm reste non implémenté tant que
des collisions ne sont **pas observées** sur les backups isolés (ADR-048/049). Ce document est prêt à décider
plus tard — il n'engage rien.
**Source :** note §2 (swarm jcode), §3.2 (transposition sans bus), §6.6 (custody no-mistakes qui converge).

---

## 1. Problème que le swarm résout dans VibeFlow

L'équipe `vf-dev-manager → vf-coder / vf-reviewer / vf-auditer / vf-test-orchestrator` est déjà l'analogue
fonctionnel du swarm jcode, mais en modèle **dispatch-and-join** (`Task`), pas acteurs concurrents. Le risque
réel n'est pas la communication temps réel (rejetée : pas de bus UDS dans Claude Code) mais la **collision de
pilotage** : deux missions/cycles qui pilotent la même étape en parallèle et se marchent dessus sur les backups
isolés. jcode **et** no-mistakes (custody) convergent sur la même réponse → signal fort : discipline de verrous,
pas magie de merge.

Trois patterns de sûreté à transposer, tous réalisables par **fichier d'état + discipline**, sans socket :

---

## 2. Pattern A — Lock de driver unique (RAII), avec récupération de claim périmé

**Transpose :** `try_claim_run_plan_driver` + `RunPlanClaimGuard` (RAII) de jcode ; conforté par la custody
`recover_custody` de no-mistakes (§6.6).

### Forme proposée (fichier de lock, non implémenté)
- Un fichier `.planning/DRIVER.lock` posé par `vf-dev-manager` **avant** de dispatcher une mission sur une étape.
- Contenu : `{ owner_session_id, pid_ou_task_id, étape_ciblée, acquired_at, heartbeat_at }`.
- **Check-and-insert atomique** : acquisition via `O_EXCL` (création exclusive) ou `mkdir` atomique — deux
  managers concurrents ne peuvent pas poser le lock tous les deux (le pendant du « single lock » de jcode).
- **RAII** : le lock est **relâché en fin de mission** (succès, échec OU abandon) — jamais laissé traîner sur un
  chemin nominal. Le release est le geste de sortie garanti, pas conditionnel.

### Récupération de claim périmé (point de vigilance explicite, note §4 + specifics CONTEXT)
Un `vf-dev-manager` qui **meurt** ne doit pas geler les missions par un lock mort. Règle de reprise :
- Le lock porte un `heartbeat_at` rafraîchi entre étapes.
- Un manager entrant qui trouve un lock dont le `heartbeat_at` dépasse un **TTL** (ex. > 2× la durée d'étape
  attendue) OU dont le `owner_session_id`/`task_id` n'est plus vivant → **élague** le lock périmé et ré-acquiert,
  en consignant la reprise (JOURNAL). C'est la transposition directe de « la map est par-process, les task ids
  morts sont élagués » (jcode) et de `recover_custody` (no-mistakes).
- **Livrer la récupération d'emblée** (pas en v2) : deux sources indépendantes le disent — sans elle, un crash =
  missions gelées.

---

## 3. Pattern B — DAG de tâches avec frontière `ready` / `blocked` + ré-entrée

**Transpose :** le DAG jcode (frontière `ready`/`blocked`, `swarm retry` re-queue, une complétion externe
débloque, le driver **ré-entre** dans la boucle de dispatch quand la frontière grossit).

### Forme proposée (état persistant, non implémenté)
- Le **plan de bataille** du manager cesse d'être une liste ordonnée : il devient un **graphe de nœuds** persistant
  (ex. `.planning/<mission>/DAG.json` ou section d'état), chaque nœud = `{ id, étape, étage, deps[], status }`
  avec `status ∈ {blocked, ready, running, done, failed}`.
- **Frontière `ready`** = nœuds dont toutes les `deps` sont `done`. Le manager dispatche uniquement la frontière.
- **Ré-entrée** : un correctif remonté par la revue/l'audit qui **rouvre** une étape repasse son nœud (et ses
  dépendants) de `done`/`blocked` à `ready` → le manager **ré-entre** dans le dispatch au lieu de dérouler
  linéairement. Robustifie la boucle `fix → re-revue` de `vf-coder` (aujourd'hui implicite).
- **Remap de collision d'id** (jcode `remap_conflicting_seed_nodes`) : deux nœuds au même id → renommage
  déterministe `id::scope` plutôt qu'échec. Utile si deux étapes insérées en cours de route collisionnent.

---

## 4. Pattern C — Rapports de worker typés (contrôle de flux déterministe)

**Transpose :** `plan_status` / `report` de jcode + taxonomie de findings de no-mistakes (§6.2).

- Les workers (`vf-coder`, `vf-reviewer`, `vf-auditer`) rendent déjà un rapport ; le **typer** :
  `{ statut ∈ {passed, gaps_found, human_needed, blocked}, findings[], nœuds_débloqués[] }`.
- Chaque finding porte une `action ∈ {auto-fix, no-op, ask-user}` (raffinement d'ADR-031, note §6.2) : le manager
  fait un **contrôle de flux déterministe** (débloque tel nœud, renvoie tel fix, escalade tel `ask-user`) au lieu
  d'interpréter de la prose. Croise le verdict d'étape déjà en place (`*-VERIFICATION.md`).

---

## 5. Ce qu'on NE transpose PAS (rappel des lignes rouges)

| Concept jcode/no-mistakes | Verdict | Raison |
|---|---|---|
| Bus UDS / channels / `dm` / `broadcast` temps réel | **REJETER** | Modèle `Task` = dispatch-and-join, pas acteurs concurrents persistants |
| Embeddings / RRF / sidecar de verify | **REJETER** | Pas de runtime intra-session Claude Code |
| Pipeline mémoire par-tour | **DIFFÉRER** | Pas de hook par-tour fiable → travail par passe consolidator |
| Proxy git en daemon (no-mistakes) | **REJETER** | VibeFlow est un plugin, pas un proxy git — on reprend **où** sont les gates, pas le runtime |

---

## 6. Condition de déclenchement (garde-fou de non-implémentation)

Ce cadrage ne devient une phase d'implémentation **que si** des collisions de pilotage sont **observées en
pratique** sur les backups isolés (ADR-048/049) — pas par anticipation. Ordre de livraison recommandé le jour où
ça se déclenche : **Pattern A (lock + recovery) d'abord** (adresse le risque le plus aigu), puis B (DAG), puis C
(rapports typés). Rien ne touche le socle `conductor` sans ADR.
